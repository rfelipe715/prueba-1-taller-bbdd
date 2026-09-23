-- ============================================================================
-- TecnoParts SpA  |  07_pruebas.sql
-- Pruebas de las funciones, los procedimientos, el package y los triggers.
-- ============================================================================
SET SERVEROUTPUT ON
SET LINESIZE 200

PROMPT ===== PRUEBA 1: funciones invocadas desde un SELECT =====
SELECT sku,
       precio_venta,
       fn_margen_pct(id_producto) AS margen_pct
  FROM producto
 WHERE id_categoria = 1
 ORDER BY sku;

PROMPT ===== PRUEBA 2: funcion de descuento por tipo de cliente =====
SELECT fn_descuento_cliente('NORMAL')     AS normal,
       fn_descuento_cliente('PREFERENTE') AS preferente,
       fn_descuento_cliente('EMPRESA')    AS empresa
  FROM dual;

PROMPT ===== PRUEBA 3: venta completa con el package =====
DECLARE
    v_id_venta  NUMBER;
    v_stock_ini NUMBER;
    v_stock_fin NUMBER;
BEGIN
    SELECT stock_actual INTO v_stock_ini
      FROM producto WHERE id_producto = 101;

    -- cliente 3 es EMPRESA, corresponde 12% de descuento
    pkg_ventas.sp_registrar_venta(3, 1, v_id_venta);
    pkg_ventas.sp_agregar_linea(v_id_venta, 101, 2);
    pkg_ventas.sp_agregar_linea(v_id_venta, 401, 4);
    pkg_ventas.sp_cerrar_venta(v_id_venta);

    SELECT stock_actual INTO v_stock_fin
      FROM producto WHERE id_producto = 101;

    DBMS_OUTPUT.PUT_LINE('Venta creada con id: ' || v_id_venta);
    DBMS_OUTPUT.PUT_LINE('Total con IVA: ' || fn_total_venta(v_id_venta));
    DBMS_OUTPUT.PUT_LINE('Stock del producto 101: ' || v_stock_ini ||
                         ' -> ' || v_stock_fin ||
                         ' (lo descuenta el trigger)');
END;
/

PROMPT ===== PRUEBA 4: excepcion de usuario, stock insuficiente =====
DECLARE
    v_id_venta NUMBER;
BEGIN
    pkg_ventas.sp_registrar_venta(1, 1, v_id_venta);
    pkg_ventas.sp_agregar_linea(v_id_venta, 303, 9999);
    DBMS_OUTPUT.PUT_LINE('ERROR: la linea no debio insertarse.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Capturado correctamente: ' || SQLERRM);
END;
/

PROMPT ===== PRUEBA 5: excepcion de usuario, venta sin detalle =====
DECLARE
    v_id_venta NUMBER;
BEGIN
    pkg_ventas.sp_registrar_venta(5, 2, v_id_venta);
    pkg_ventas.sp_cerrar_venta(v_id_venta);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Capturado correctamente: ' || SQLERRM);
END;
/

PROMPT ===== PRUEBA 6: trigger de auditoria de precio =====
UPDATE producto SET precio_venta = 144990 WHERE id_producto = 101;
COMMIT;

SELECT p.sku, a.precio_anterior, a.precio_nuevo, a.usuario_bd,
       TO_CHAR(a.fecha_cambio,'DD/MM/YYYY HH24:MI') AS fecha
  FROM auditoria_precio a
  JOIN producto p ON p.id_producto = a.id_producto
 ORDER BY a.id_auditoria;

PROMPT ===== PRUEBA 7: el trigger impide vender bajo el costo =====
BEGIN
    UPDATE producto SET precio_venta = 1000 WHERE id_producto = 101;
    DBMS_OUTPUT.PUT_LINE('ERROR: el UPDATE no debio ejecutarse.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Capturado correctamente: ' || SQLERRM);
END;
/

PROMPT ===== PRUEBA 8: procedimiento de alertas de stock =====
BEGIN
    sp_generar_alertas_stock;
END;
/

SELECT a.id_alerta, p.sku, a.stock_actual, a.stock_critico
  FROM alerta_stock a
  JOIN producto p ON p.id_producto = a.id_producto
 ORDER BY a.id_alerta;

PROMPT ===== PRUEBA 9: bitacora de errores =====
SELECT id_log, origen, codigo_error, SUBSTR(mensaje,1,60) AS mensaje
  FROM log_error
 ORDER BY id_log;

PROMPT ===== PRUEBA 10: objetos invalidos (debe devolver 0 filas) =====
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID';
