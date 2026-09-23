-- ============================================================================
-- TecnoParts SpA  |  03_funciones_procedimientos.sql
-- Funciones y procedimientos almacenados.
-- Se crean antes que los packages, porque estos los invocan.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- FUNCION: margen porcentual de un producto.
-- Una funcion SIEMPRE devuelve un valor con RETURN y no modifica datos,
-- por eso se puede invocar dentro de un SELECT.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_margen_pct (p_id_producto IN NUMBER)
RETURN NUMBER IS
    v_precio producto.precio_venta%TYPE;
    v_costo  producto.costo_unitario%TYPE;
BEGIN
    SELECT precio_venta, costo_unitario
      INTO v_precio, v_costo
      FROM producto
     WHERE id_producto = p_id_producto;

    IF v_precio = 0 THEN
        RETURN NULL;          -- sin precio no hay margen que calcular
    END IF;

    RETURN ROUND((v_precio - v_costo) / v_precio * 100, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- excepcion predefinida por Oracle
        RETURN NULL;
END fn_margen_pct;
/

-- ----------------------------------------------------------------------------
-- FUNCION: descuento que corresponde a cada tipo de cliente.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_descuento_cliente (p_tipo_cliente IN VARCHAR2)
RETURN NUMBER IS
    v_descuento NUMBER;
BEGIN
    IF p_tipo_cliente = 'PREFERENTE' THEN
        v_descuento := 5;
    ELSIF p_tipo_cliente = 'EMPRESA' THEN
        v_descuento := 12;
    ELSE
        v_descuento := 0;
    END IF;

    RETURN v_descuento;
END fn_descuento_cliente;
/

-- ----------------------------------------------------------------------------
-- FUNCION: total de una venta con IVA incluido.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_venta (p_id_venta IN NUMBER)
RETURN NUMBER IS
    v_neto NUMBER := 0;
BEGIN
    SELECT NVL(SUM(cantidad * precio_unitario * (1 - descuento_pct/100)), 0)
      INTO v_neto
      FROM detalle_venta
     WHERE id_venta = p_id_venta;

    RETURN ROUND(v_neto * 1.19);
END fn_total_venta;
/

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTO: registra un error en la bitacora.
-- Un procedimiento ejecuta acciones y no devuelve valor con RETURN.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_log (
    p_origen  IN VARCHAR2,
    p_codigo  IN NUMBER,
    p_mensaje IN VARCHAR2
) IS
BEGIN
    INSERT INTO log_error (id_log, origen, codigo_error, mensaje)
    VALUES (seq_log.NEXTVAL, p_origen, p_codigo, SUBSTR(p_mensaje, 1, 500));
END sp_registrar_log;
/

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTO: genera alertas de los productos bajo su stock critico.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_generar_alertas_stock IS
    CURSOR c_criticos IS
        SELECT id_producto, sku, stock_actual, stock_critico
          FROM producto
         WHERE activo = 'S'
           AND stock_actual <= stock_critico;

    v_generadas NUMBER := 0;
BEGIN
    FOR r_prod IN c_criticos LOOP
        INSERT INTO alerta_stock (id_alerta, id_producto,
                                  stock_actual, stock_critico)
        VALUES (seq_alerta.NEXTVAL, r_prod.id_producto,
                r_prod.stock_actual, r_prod.stock_critico);

        v_generadas := v_generadas + 1;
        DBMS_OUTPUT.PUT_LINE('Alerta: ' || r_prod.sku ||
            ' con stock ' || r_prod.stock_actual);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total de alertas generadas: ' || v_generadas);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        sp_registrar_log('sp_generar_alertas_stock', SQLCODE, SQLERRM);
        RAISE;
END sp_generar_alertas_stock;
/

PROMPT Funciones y procedimientos creados.
SHOW ERRORS
