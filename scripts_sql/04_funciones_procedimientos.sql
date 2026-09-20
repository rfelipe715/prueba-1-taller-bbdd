-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 04_funciones_procedimientos.sql
-- Subprogramas independientes (se crean antes que los packages porque estos
-- los invocan).
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTO: bitacora de errores
-- PRAGMA AUTONOMOUS_TRANSACTION permite que el COMMIT del log sobreviva al
-- ROLLBACK de la transaccion que fallo.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_log (
    p_origen  IN VARCHAR2,
    p_codigo  IN NUMBER,
    p_mensaje IN VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO log_error (id_log, origen, codigo_error, mensaje)
    VALUES (seq_log.NEXTVAL, p_origen, p_codigo, SUBSTR(p_mensaje, 1, 4000));
    COMMIT;
END sp_registrar_log;
/

-- ----------------------------------------------------------------------------
-- FUNCION: margen porcentual de un producto
-- DETERMINISTIC permite al motor cachear el resultado cuando se invoca dentro
-- de una sentencia SQL sobre muchas filas.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_margen_pct (
    p_id_producto IN NUMBER
) RETURN NUMBER DETERMINISTIC IS
    v_precio producto.precio_venta%TYPE;
    v_costo  producto.costo_unitario%TYPE;
BEGIN
    SELECT precio_venta, costo_unitario
      INTO v_precio, v_costo
      FROM producto
     WHERE id_producto = p_id_producto;

    IF NVL(v_precio, 0) = 0 THEN
        RETURN NULL;                      -- margen no calculable
    END IF;

    RETURN ROUND((v_precio - v_costo) / v_precio * 100, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN               -- excepcion predefinida de Oracle
        RAISE_APPLICATION_ERROR(-20010,
            'El producto ' || p_id_producto || ' no existe.');
END fn_margen_pct;
/

-- ----------------------------------------------------------------------------
-- FUNCION: precio final segun tipo de cliente
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_precio_final (
    p_id_producto  IN NUMBER,
    p_tipo_cliente IN VARCHAR2
) RETURN NUMBER IS
    v_precio   producto.precio_venta%TYPE;
    v_dcto_pct NUMBER;
BEGIN
    SELECT precio_venta INTO v_precio
      FROM producto
     WHERE id_producto = p_id_producto;

    v_dcto_pct := CASE p_tipo_cliente
                      WHEN 'PREFERENTE' THEN 5
                      WHEN 'EMPRESA'    THEN 12
                      ELSE 0
                  END;

    RETURN ROUND(v_precio * (1 - v_dcto_pct / 100));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011,
            'Producto inexistente al calcular precio final: ' || p_id_producto);
END fn_precio_final;
/

-- ----------------------------------------------------------------------------
-- FUNCION: dias de cobertura de stock segun venta promedio diaria
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_dias_cobertura (
    p_id_producto IN NUMBER,
    p_dias_base   IN NUMBER DEFAULT 90
) RETURN NUMBER IS
    v_stock    producto.stock_actual%TYPE;
    v_vendido  NUMBER;
    v_promedio NUMBER;
BEGIN
    SELECT stock_actual INTO v_stock
      FROM producto WHERE id_producto = p_id_producto;

    SELECT NVL(SUM(d.cantidad), 0) INTO v_vendido
      FROM detalle_venta d
      JOIN venta v ON v.id_venta = d.id_venta
     WHERE d.id_producto = p_id_producto
       AND v.estado      = 'EMITIDA'
       AND v.fecha_venta >= SYSDATE - p_dias_base;

    v_promedio := v_vendido / p_dias_base;

    RETURN ROUND(v_stock / v_promedio);
EXCEPTION
    WHEN ZERO_DIVIDE THEN                 -- producto sin ventas en el periodo
        RETURN NULL;
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20012,
            'Producto inexistente: ' || p_id_producto);
END fn_dias_cobertura;
/

PROMPT Funciones y procedimientos independientes creados.
SHOW ERRORS
