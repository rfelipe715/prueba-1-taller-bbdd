-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 05_packages.sql
-- Packages pkg_ventas y pkg_inventario (especificacion + cuerpo).
-- ============================================================================
SET DEFINE OFF

-- ############################################################################
-- PKG_VENTAS - ESPECIFICACION
-- ############################################################################
CREATE OR REPLACE PACKAGE pkg_ventas AS

    -- Constante publica: una sola definicion del IVA para todo el sistema
    c_iva CONSTANT NUMBER := 0.19;

    -- Tipo compuesto publico (RECORD)
    TYPE t_resumen_cat IS RECORD (
        id_categoria   NUMBER,
        nombre         VARCHAR2(50),
        unidades       NUMBER,
        venta_neta     NUMBER,
        costo_total    NUMBER,
        margen_pct     NUMBER,
        meta_trimestre NUMBER,
        cumplim_pct    NUMBER
    );

    -- Excepciones de negocio publicadas para que el cliente las capture
    -- por NOMBRE y no comparando el texto del mensaje de error.
    e_stock_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_stock_insuficiente, -20020);

    e_venta_sin_detalle EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_venta_sin_detalle, -20021);

    e_cliente_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_cliente_inexistente, -20022);

    -- Interfaz publica
    PROCEDURE sp_registrar_venta (p_id_cliente  IN  NUMBER,
                                  p_id_sucursal IN  NUMBER,
                                  p_id_venta    OUT NUMBER);

    PROCEDURE sp_agregar_linea   (p_id_venta    IN NUMBER,
                                  p_id_producto IN NUMBER,
                                  p_cantidad    IN NUMBER);

    PROCEDURE sp_cerrar_venta    (p_id_venta IN NUMBER);

    PROCEDURE sp_anular_venta    (p_id_venta IN NUMBER);

    FUNCTION  fn_total_venta     (p_id_venta IN NUMBER) RETURN NUMBER;

END pkg_ventas;
/

-- ############################################################################
-- PKG_VENTAS - CUERPO
-- ############################################################################
CREATE OR REPLACE PACKAGE BODY pkg_ventas AS

    -- ------------------------------------------------------------------
    -- PRIVADA: la regla de descuento existe en un solo lugar y nadie
    -- fuera del package puede aplicarla de otra forma.
    -- ------------------------------------------------------------------
    FUNCTION fn_dcto_por_tipo (p_tipo IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN CASE p_tipo
                   WHEN 'PREFERENTE' THEN 5
                   WHEN 'EMPRESA'    THEN 12
                   ELSE 0
               END;
    END fn_dcto_por_tipo;

    -- ------------------------------------------------------------------
    PROCEDURE sp_registrar_venta (p_id_cliente  IN  NUMBER,
                                  p_id_sucursal IN  NUMBER,
                                  p_id_venta    OUT NUMBER) IS
        v_existe NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existe
          FROM cliente WHERE id_cliente = p_id_cliente;

        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20022,
                'Cliente inexistente: ' || p_id_cliente);
        END IF;

        p_id_venta := seq_venta.NEXTVAL;

        INSERT INTO venta (id_venta, id_cliente, id_sucursal, estado)
        VALUES (p_id_venta, p_id_cliente, p_id_sucursal, 'BORRADOR');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('pkg_ventas.sp_registrar_venta', SQLCODE,
                SQLERRM || ' | ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            RAISE;
    END sp_registrar_venta;

    -- ------------------------------------------------------------------
    PROCEDURE sp_agregar_linea (p_id_venta    IN NUMBER,
                                p_id_producto IN NUMBER,
                                p_cantidad    IN NUMBER) IS
        v_stock  producto.stock_actual%TYPE;
        v_precio producto.precio_venta%TYPE;
        v_tipo   cliente.tipo_cliente%TYPE;
        v_estado venta.estado%TYPE;
        v_linea  NUMBER;
    BEGIN
        SELECT estado INTO v_estado
          FROM venta WHERE id_venta = p_id_venta;

        IF v_estado <> 'BORRADOR' THEN
            RAISE_APPLICATION_ERROR(-20024,
                'Solo se pueden agregar lineas a una venta en BORRADOR.');
        END IF;

        -- FOR UPDATE bloquea la fila del producto: evita que dos ventas
        -- simultaneas validen contra el mismo stock y lo dejen negativo.
        SELECT stock_actual, precio_venta INTO v_stock, v_precio
          FROM producto
         WHERE id_producto = p_id_producto
           FOR UPDATE;

        IF v_stock < p_cantidad THEN
            RAISE_APPLICATION_ERROR(-20020,
                'Stock insuficiente para el producto ' || p_id_producto ||
                '. Disponible: ' || v_stock || ', solicitado: ' || p_cantidad);
        END IF;

        SELECT c.tipo_cliente INTO v_tipo
          FROM venta v
          JOIN cliente c ON c.id_cliente = v.id_cliente
         WHERE v.id_venta = p_id_venta;

        SELECT NVL(MAX(nro_linea), 0) + 1 INTO v_linea
          FROM detalle_venta WHERE id_venta = p_id_venta;

        INSERT INTO detalle_venta (id_venta, nro_linea, id_producto,
                                   cantidad, precio_unitario, descuento_pct)
        VALUES (p_id_venta, v_linea, p_id_producto,
                p_cantidad, v_precio, fn_dcto_por_tipo(v_tipo));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            sp_registrar_log('pkg_ventas.sp_agregar_linea', SQLCODE,
                'Venta o producto inexistente');
            RAISE_APPLICATION_ERROR(-20023,
                'Venta o producto inexistente.');
    END sp_agregar_linea;

    -- ------------------------------------------------------------------
    FUNCTION fn_total_venta (p_id_venta IN NUMBER) RETURN NUMBER IS
        v_neto NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(cantidad * precio_unitario * (1 - descuento_pct/100)), 0)
          INTO v_neto
          FROM detalle_venta
         WHERE id_venta = p_id_venta;

        RETURN ROUND(v_neto * (1 + c_iva));
    END fn_total_venta;

    -- ------------------------------------------------------------------
    PROCEDURE sp_cerrar_venta (p_id_venta IN NUMBER) IS
        v_lineas NUMBER;
        v_neto   NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_lineas
          FROM detalle_venta WHERE id_venta = p_id_venta;

        IF v_lineas = 0 THEN
            RAISE_APPLICATION_ERROR(-20021,
                'No se puede emitir una venta sin lineas de detalle.');
        END IF;

        SELECT NVL(SUM(cantidad * precio_unitario * (1 - descuento_pct/100)), 0)
          INTO v_neto
          FROM detalle_venta WHERE id_venta = p_id_venta;

        UPDATE venta
           SET total_neto  = ROUND(v_neto),
               total_iva   = ROUND(v_neto * c_iva),
               total_bruto = ROUND(v_neto * (1 + c_iva)),
               estado      = 'EMITIDA'
         WHERE id_venta = p_id_venta;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('pkg_ventas.sp_cerrar_venta', SQLCODE, SQLERRM);
            RAISE;
    END sp_cerrar_venta;

    -- ------------------------------------------------------------------
    PROCEDURE sp_anular_venta (p_id_venta IN NUMBER) IS
    BEGIN
        -- Devuelve el stock de cada linea antes de anular
        FOR r IN (SELECT id_producto, cantidad
                    FROM detalle_venta WHERE id_venta = p_id_venta) LOOP
            UPDATE producto
               SET stock_actual = stock_actual + r.cantidad
             WHERE id_producto = r.id_producto;

            INSERT INTO movimiento_stock (id_movimiento, id_producto,
                       tipo_movimiento, cantidad, id_venta, observacion)
            VALUES (seq_movimiento.NEXTVAL, r.id_producto, 'ENTRADA',
                    r.cantidad, p_id_venta, 'Devolucion por anulacion');
        END LOOP;

        UPDATE venta SET estado = 'ANULADA' WHERE id_venta = p_id_venta;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('pkg_ventas.sp_anular_venta', SQLCODE, SQLERRM);
            RAISE;
    END sp_anular_venta;

END pkg_ventas;
/

-- ############################################################################
-- PKG_INVENTARIO - ESPECIFICACION
-- ############################################################################
CREATE OR REPLACE PACKAGE pkg_inventario AS

    FUNCTION  fn_stock_disponible   (p_id_producto IN NUMBER) RETURN NUMBER;

    PROCEDURE sp_registrar_movimiento (p_id_producto IN NUMBER,
                                       p_tipo        IN VARCHAR2,
                                       p_cantidad    IN NUMBER,
                                       p_observacion IN VARCHAR2 DEFAULT NULL);

    PROCEDURE sp_ajustar_stock      (p_id_producto IN NUMBER,
                                     p_cantidad    IN NUMBER,
                                     p_motivo      IN VARCHAR2);

    PROCEDURE sp_generar_alertas_stock;

END pkg_inventario;
/

-- ############################################################################
-- PKG_INVENTARIO - CUERPO
-- ############################################################################
CREATE OR REPLACE PACKAGE BODY pkg_inventario AS

    FUNCTION fn_stock_disponible (p_id_producto IN NUMBER) RETURN NUMBER IS
        v_stock NUMBER;
    BEGIN
        SELECT stock_actual INTO v_stock
          FROM producto WHERE id_producto = p_id_producto;
        RETURN v_stock;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_stock_disponible;

    -- ------------------------------------------------------------------
    PROCEDURE sp_registrar_movimiento (p_id_producto IN NUMBER,
                                       p_tipo        IN VARCHAR2,
                                       p_cantidad    IN NUMBER,
                                       p_observacion IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        IF p_tipo NOT IN ('ENTRADA','SALIDA','AJUSTE') THEN
            RAISE_APPLICATION_ERROR(-20040,
                'Tipo de movimiento invalido: ' || p_tipo);
        END IF;

        INSERT INTO movimiento_stock (id_movimiento, id_producto,
                   tipo_movimiento, cantidad, observacion)
        VALUES (seq_movimiento.NEXTVAL, p_id_producto,
                p_tipo, p_cantidad, p_observacion);
    END sp_registrar_movimiento;

    -- ------------------------------------------------------------------
    PROCEDURE sp_ajustar_stock (p_id_producto IN NUMBER,
                                p_cantidad    IN NUMBER,
                                p_motivo      IN VARCHAR2) IS
        v_stock NUMBER;
    BEGIN
        SELECT stock_actual INTO v_stock
          FROM producto WHERE id_producto = p_id_producto FOR UPDATE;

        IF v_stock + p_cantidad < 0 THEN
            RAISE_APPLICATION_ERROR(-20041,
                'El ajuste dejaria el stock negativo. Stock actual: ' || v_stock);
        END IF;

        UPDATE producto
           SET stock_actual = stock_actual + p_cantidad
         WHERE id_producto = p_id_producto;

        sp_registrar_movimiento(p_id_producto,
            CASE WHEN p_cantidad >= 0 THEN 'ENTRADA' ELSE 'AJUSTE' END,
            ABS(p_cantidad), p_motivo);

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20042,
                'Producto inexistente: ' || p_id_producto);
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('pkg_inventario.sp_ajustar_stock', SQLCODE, SQLERRM);
            RAISE;
    END sp_ajustar_stock;

    -- ------------------------------------------------------------------
    -- Recorre los productos bajo stock critico y genera la alerta si no
    -- existe una pendiente. Candidato a ejecutarse por DBMS_SCHEDULER.
    -- ------------------------------------------------------------------
    PROCEDURE sp_generar_alertas_stock IS
        CURSOR c_criticos IS
            SELECT id_producto, sku, stock_actual, stock_critico
              FROM producto
             WHERE activo = 'S'
               AND stock_actual <= stock_critico;

        v_pendientes NUMBER;
        v_generadas  NUMBER := 0;
    BEGIN
        FOR r IN c_criticos LOOP
            SELECT COUNT(*) INTO v_pendientes
              FROM alerta_stock
             WHERE id_producto = r.id_producto
               AND estado      = 'PENDIENTE';

            IF v_pendientes = 0 THEN
                INSERT INTO alerta_stock (id_alerta, id_producto,
                           stock_actual, stock_critico)
                VALUES (seq_alerta.NEXTVAL, r.id_producto,
                        r.stock_actual, r.stock_critico);
                v_generadas := v_generadas + 1;
            END IF;
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Alertas de stock generadas: ' || v_generadas);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('pkg_inventario.sp_generar_alertas_stock',
                             SQLCODE, SQLERRM);
            RAISE;
    END sp_generar_alertas_stock;

END pkg_inventario;
/

PROMPT Packages creados.
SHOW ERRORS
