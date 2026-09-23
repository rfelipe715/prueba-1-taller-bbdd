-- ============================================================================
-- TecnoParts SpA  |  04_packages.sql
-- Un package agrupa procedimientos, funciones y excepciones relacionadas.
-- La especificacion declara lo que se puede usar desde fuera;
-- el cuerpo contiene la implementacion.
-- ============================================================================
SET DEFINE OFF

-- ############################################################################
-- ESPECIFICACION
-- ############################################################################
CREATE OR REPLACE PACKAGE pkg_ventas AS

    -- Constante publica: el IVA se define una sola vez para todo el sistema
    c_iva CONSTANT NUMBER := 0.19;

    -- Excepciones de negocio declaradas por el usuario
    e_stock_insuficiente  EXCEPTION;
    e_venta_sin_detalle   EXCEPTION;
    e_cliente_inexistente EXCEPTION;

    PROCEDURE sp_registrar_venta (p_id_cliente  IN  NUMBER,
                                  p_id_sucursal IN  NUMBER,
                                  p_id_venta    OUT NUMBER);

    PROCEDURE sp_agregar_linea   (p_id_venta    IN NUMBER,
                                  p_id_producto IN NUMBER,
                                  p_cantidad    IN NUMBER);

    PROCEDURE sp_cerrar_venta    (p_id_venta IN NUMBER);

END pkg_ventas;
/

-- ############################################################################
-- CUERPO
-- ############################################################################
CREATE OR REPLACE PACKAGE BODY pkg_ventas AS

    -- ------------------------------------------------------------------
    PROCEDURE sp_registrar_venta (p_id_cliente  IN  NUMBER,
                                  p_id_sucursal IN  NUMBER,
                                  p_id_venta    OUT NUMBER) IS
        v_existe NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existe
          FROM cliente
         WHERE id_cliente = p_id_cliente;

        IF v_existe = 0 THEN
            RAISE e_cliente_inexistente;
        END IF;

        p_id_venta := seq_venta.NEXTVAL;

        INSERT INTO venta (id_venta, id_cliente, id_sucursal, estado)
        VALUES (p_id_venta, p_id_cliente, p_id_sucursal, 'BORRADOR');
    EXCEPTION
        WHEN e_cliente_inexistente THEN
            sp_registrar_log('sp_registrar_venta', -20001,
                'Cliente inexistente: ' || p_id_cliente);
            RAISE_APPLICATION_ERROR(-20001,
                'El cliente ' || p_id_cliente || ' no existe.');
    END sp_registrar_venta;

    -- ------------------------------------------------------------------
    PROCEDURE sp_agregar_linea (p_id_venta    IN NUMBER,
                                p_id_producto IN NUMBER,
                                p_cantidad    IN NUMBER) IS
        v_stock     producto.stock_actual%TYPE;
        v_precio    producto.precio_venta%TYPE;
        v_tipo      cliente.tipo_cliente%TYPE;
        v_descuento NUMBER;
        v_linea     NUMBER;
    BEGIN
        SELECT stock_actual, precio_venta
          INTO v_stock, v_precio
          FROM producto
         WHERE id_producto = p_id_producto;

        IF v_stock < p_cantidad THEN
            RAISE e_stock_insuficiente;
        END IF;

        SELECT c.tipo_cliente
          INTO v_tipo
          FROM venta v
          JOIN cliente c ON c.id_cliente = v.id_cliente
         WHERE v.id_venta = p_id_venta;

        v_descuento := fn_descuento_cliente(v_tipo);

        SELECT NVL(MAX(nro_linea), 0) + 1
          INTO v_linea
          FROM detalle_venta
         WHERE id_venta = p_id_venta;

        INSERT INTO detalle_venta (id_venta, nro_linea, id_producto,
                                   cantidad, precio_unitario, descuento_pct)
        VALUES (p_id_venta, v_linea, p_id_producto,
                p_cantidad, v_precio, v_descuento);
    EXCEPTION
        WHEN e_stock_insuficiente THEN
            sp_registrar_log('sp_agregar_linea', -20002,
                'Stock insuficiente del producto ' || p_id_producto);
            RAISE_APPLICATION_ERROR(-20002,
                'Stock insuficiente. Disponible: ' || v_stock ||
                ', solicitado: ' || p_cantidad);
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003,
                'La venta o el producto indicado no existe.');
    END sp_agregar_linea;

    -- ------------------------------------------------------------------
    PROCEDURE sp_cerrar_venta (p_id_venta IN NUMBER) IS
        v_lineas NUMBER;
        v_neto   NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_lineas
          FROM detalle_venta
         WHERE id_venta = p_id_venta;

        IF v_lineas = 0 THEN
            RAISE e_venta_sin_detalle;
        END IF;

        SELECT NVL(SUM(cantidad * precio_unitario
                       * (1 - descuento_pct/100)), 0)
          INTO v_neto
          FROM detalle_venta
         WHERE id_venta = p_id_venta;

        UPDATE venta
           SET total_neto  = ROUND(v_neto),
               total_iva   = ROUND(v_neto * c_iva),
               total_bruto = ROUND(v_neto * (1 + c_iva)),
               estado      = 'EMITIDA'
         WHERE id_venta = p_id_venta;

        COMMIT;
    EXCEPTION
        WHEN e_venta_sin_detalle THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004,
                'No se puede emitir una venta sin lineas de detalle.');
        WHEN OTHERS THEN
            ROLLBACK;
            sp_registrar_log('sp_cerrar_venta', SQLCODE, SQLERRM);
            RAISE;
    END sp_cerrar_venta;

END pkg_ventas;
/

PROMPT Package pkg_ventas creado.
SHOW ERRORS
