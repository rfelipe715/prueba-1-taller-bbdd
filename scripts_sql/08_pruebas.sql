-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 08_pruebas.sql
-- Pruebas de los objetos almacenados y de los caminos de excepcion.
-- Cada prueba imprime el resultado esperado para poder contrastarlo.
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET DEFINE OFF

PROMPT ========== PRUEBA 1: funciones almacenadas ==========
SELECT p.sku,
       p.precio_venta,
       fn_margen_pct(p.id_producto)               AS margen_pct,
       fn_precio_final(p.id_producto,'EMPRESA')   AS precio_empresa,
       fn_dias_cobertura(p.id_producto)           AS dias_cobertura
  FROM producto p
 WHERE p.id_categoria = 1
 ORDER BY p.sku;

PROMPT ========== PRUEBA 2: funcion dentro de un WHERE (productos de bajo margen) ==========
SELECT sku, nombre, fn_margen_pct(id_producto) AS margen
  FROM producto
 WHERE fn_margen_pct(id_producto) < 28
 ORDER BY margen;

PROMPT ========== PRUEBA 3: venta completa OK (procedimientos + triggers) ==========
DECLARE
    v_id_venta NUMBER;
    v_stock_antes NUMBER;
    v_stock_despues NUMBER;
BEGIN
    SELECT stock_actual INTO v_stock_antes FROM producto WHERE id_producto = 101;

    pkg_ventas.sp_registrar_venta(p_id_cliente  => 3,      -- cliente EMPRESA
                                  p_id_sucursal => 1,
                                  p_id_venta    => v_id_venta);

    pkg_ventas.sp_agregar_linea(v_id_venta, 101, 2);       -- CPU Ryzen 5
    pkg_ventas.sp_agregar_linea(v_id_venta, 401, 4);       -- RAM 16GB
    pkg_ventas.sp_cerrar_venta(v_id_venta);

    SELECT stock_actual INTO v_stock_despues FROM producto WHERE id_producto = 101;

    DBMS_OUTPUT.PUT_LINE('Venta creada: ' || v_id_venta);
    DBMS_OUTPUT.PUT_LINE('Total con IVA: ' || pkg_ventas.fn_total_venta(v_id_venta));
    DBMS_OUTPUT.PUT_LINE('Stock producto 101: ' || v_stock_antes ||
                         ' -> ' || v_stock_despues ||
                         '  (el trigger descuenta 2 unidades)');
    DBMS_OUTPUT.PUT_LINE('Descuento aplicado: 12% por ser cliente EMPRESA');
END;
/

PROMPT ========== PRUEBA 4: excepcion de usuario - stock insuficiente (-20020) ==========
DECLARE
    v_id_venta NUMBER;
BEGIN
    pkg_ventas.sp_registrar_venta(1, 1, v_id_venta);
    pkg_ventas.sp_agregar_linea(v_id_venta, 303, 9999);    -- muy sobre el stock
    DBMS_OUTPUT.PUT_LINE('ERROR: la venta no debio completarse.');
EXCEPTION
    WHEN pkg_ventas.e_stock_insuficiente THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK - capturada por NOMBRE: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Otro error [' || SQLCODE || ']: ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 5: excepcion de usuario - venta sin detalle (-20021) ==========
DECLARE
    v_id_venta NUMBER;
BEGIN
    pkg_ventas.sp_registrar_venta(5, 2, v_id_venta);
    pkg_ventas.sp_cerrar_venta(v_id_venta);                -- sin lineas
EXCEPTION
    WHEN pkg_ventas.e_venta_sin_detalle THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK - ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 6: trigger de auditoria de precio ==========
UPDATE producto SET precio_venta = 144990 WHERE id_producto = 101;
COMMIT;

SELECT a.id_producto, p.sku, a.precio_anterior, a.precio_nuevo,
       a.usuario_bd, TO_CHAR(a.fecha_cambio,'DD/MM/YYYY HH24:MI:SS') AS fecha
  FROM auditoria_precio a
  JOIN producto p ON p.id_producto = a.id_producto
 ORDER BY a.id_auditoria;

PROMPT ========== PRUEBA 7: trigger bloquea precio bajo el costo (-20031) ==========
BEGIN
    UPDATE producto SET precio_venta = 1000 WHERE id_producto = 101;
    DBMS_OUTPUT.PUT_LINE('ERROR: el UPDATE no debio ejecutarse.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK - ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 8: trigger protege una venta EMITIDA (-20035) ==========
BEGIN
    UPDATE detalle_venta SET cantidad = 99
     WHERE id_venta = 1 AND nro_linea = 1;
    DBMS_OUTPUT.PUT_LINE('ERROR: el UPDATE no debio ejecutarse.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK - ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 9: excepcion predefinida NO_DATA_FOUND (-20010) ==========
DECLARE
    v NUMBER;
BEGIN
    v := fn_margen_pct(999999);          -- producto inexistente
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK - ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 10: alertas de stock critico ==========
BEGIN
    pkg_inventario.sp_generar_alertas_stock;
END;
/

SELECT a.id_alerta, p.sku, a.stock_actual, a.stock_critico, a.estado
  FROM alerta_stock a
  JOIN producto p ON p.id_producto = a.id_producto
 ORDER BY a.id_alerta;

PROMPT ========== PRUEBA 11: ajuste de stock y validacion de negativo (-20041) ==========
BEGIN
    pkg_inventario.sp_ajustar_stock(501, 10, 'Reposicion de proveedor');
    DBMS_OUTPUT.PUT_LINE('Stock 501 tras reposicion: ' ||
                         pkg_inventario.fn_stock_disponible(501));

    pkg_inventario.sp_ajustar_stock(501, -99999, 'Ajuste invalido de prueba');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK - ' || SQLERRM);
END;
/

PROMPT ========== PRUEBA 12: anulacion de venta y devolucion de stock ==========
DECLARE
    v_id_venta NUMBER;
    v_stock_antes NUMBER;
    v_stock_medio NUMBER;
    v_stock_final NUMBER;
BEGIN
    SELECT stock_actual INTO v_stock_antes FROM producto WHERE id_producto = 802;

    pkg_ventas.sp_registrar_venta(10, 4, v_id_venta);
    pkg_ventas.sp_agregar_linea(v_id_venta, 802, 3);
    pkg_ventas.sp_cerrar_venta(v_id_venta);
    SELECT stock_actual INTO v_stock_medio FROM producto WHERE id_producto = 802;

    pkg_ventas.sp_anular_venta(v_id_venta);
    SELECT stock_actual INTO v_stock_final FROM producto WHERE id_producto = 802;

    DBMS_OUTPUT.PUT_LINE('Stock 802: ' || v_stock_antes || ' -> ' ||
        v_stock_medio || ' (venta) -> ' || v_stock_final || ' (anulacion)');
END;
/

PROMPT ========== PRUEBA 13: bitacora de errores ==========
SELECT id_log, origen, codigo_error, SUBSTR(mensaje,1,70) AS mensaje,
       TO_CHAR(fecha,'DD/MM HH24:MI:SS') AS fecha
  FROM log_error
 ORDER BY id_log;

PROMPT ========== PRUEBA 14: objetos invalidos (debe devolver 0 filas) ==========
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID';
