-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 06_triggers.sql
-- Triggers de validacion, auditoria y automatizacion.
-- Se crean DESPUES de la carga historica (script 03) a proposito.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- 1) AUDITORIA DE PRECIOS + regla "no vender bajo costo"
--    La clausula WHEN evita que el trigger se ejecute si el precio no cambio.
--    En WHEN se usa OLD/NEW sin dos puntos; en el cuerpo, con :OLD / :NEW.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audita_precio
BEFORE UPDATE OF precio_venta ON producto
FOR EACH ROW
WHEN (NVL(OLD.precio_venta, -1) <> NVL(NEW.precio_venta, -1))
BEGIN
    IF :NEW.precio_venta < :NEW.costo_unitario THEN
        RAISE_APPLICATION_ERROR(-20031,
            'El precio de venta (' || :NEW.precio_venta ||
            ') no puede ser inferior al costo (' || :NEW.costo_unitario || ').');
    END IF;

    INSERT INTO auditoria_precio (id_auditoria, id_producto,
               precio_anterior, precio_nuevo, usuario_bd)
    VALUES (seq_auditoria.NEXTVAL, :OLD.id_producto,
            :OLD.precio_venta, :NEW.precio_venta, USER);
END trg_audita_precio;
/

-- ----------------------------------------------------------------------------
-- 2) VALIDACION DE LA LINEA DE VENTA (antes de insertar)
--    Regla que una constraint CHECK no puede expresar: compara contra el
--    stock, que vive en otra tabla.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_valida_detalle
BEFORE INSERT ON detalle_venta
FOR EACH ROW
DECLARE
    v_stock  producto.stock_actual%TYPE;
    v_activo producto.activo%TYPE;
BEGIN
    IF :NEW.cantidad <= 0 THEN
        RAISE_APPLICATION_ERROR(-20032,
            'La cantidad debe ser mayor que cero.');
    END IF;

    SELECT stock_actual, activo INTO v_stock, v_activo
      FROM producto WHERE id_producto = :NEW.id_producto;

    IF v_activo = 'N' THEN
        RAISE_APPLICATION_ERROR(-20034,
            'El producto ' || :NEW.id_producto || ' esta descontinuado.');
    END IF;

    IF v_stock < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20020,
            'Stock insuficiente para el producto ' || :NEW.id_producto ||
            '. Disponible: ' || v_stock || ', solicitado: ' || :NEW.cantidad);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20033,
            'Producto inexistente: ' || :NEW.id_producto);
END trg_valida_detalle;
/

-- ----------------------------------------------------------------------------
-- 3) DESCUENTO AUTOMATICO DE STOCK Y REGISTRO DEL MOVIMIENTO
--    Mantiene sincronizado producto.stock_actual, que es un dato derivado.
--    Este UPDATE es el que dispara, a su vez, el trigger de alerta (punto 4).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_descuenta_stock
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto
       SET stock_actual = stock_actual - :NEW.cantidad
     WHERE id_producto = :NEW.id_producto;

    INSERT INTO movimiento_stock (id_movimiento, id_producto, tipo_movimiento,
               cantidad, id_venta, observacion)
    VALUES (seq_movimiento.NEXTVAL, :NEW.id_producto, 'SALIDA',
            :NEW.cantidad, :NEW.id_venta, 'Venta linea ' || :NEW.nro_linea);
END trg_descuenta_stock;
/

-- ----------------------------------------------------------------------------
-- 4) ALERTA DE STOCK CRITICO
--    La condicion del WHEN solo se cumple cuando el stock CRUZA el umbral,
--    para no generar una alerta duplicada en cada venta posterior.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_alerta_stock_critico
AFTER UPDATE OF stock_actual ON producto
FOR EACH ROW
WHEN (NEW.stock_actual <= NEW.stock_critico
      AND OLD.stock_actual >  OLD.stock_critico)
BEGIN
    INSERT INTO alerta_stock (id_alerta, id_producto,
               stock_actual, stock_critico)
    VALUES (seq_alerta.NEXTVAL, :NEW.id_producto,
            :NEW.stock_actual, :NEW.stock_critico);
END trg_alerta_stock_critico;
/

-- ----------------------------------------------------------------------------
-- 5) PROTECCION DE VENTAS EMITIDAS
--    Impide modificar el detalle de una venta ya emitida.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_protege_venta_emitida
BEFORE UPDATE OR DELETE ON detalle_venta
FOR EACH ROW
DECLARE
    v_estado venta.estado%TYPE;
BEGIN
    SELECT estado INTO v_estado
      FROM venta WHERE id_venta = :OLD.id_venta;

    IF v_estado = 'EMITIDA' THEN
        RAISE_APPLICATION_ERROR(-20035,
            'No se puede modificar el detalle de una venta EMITIDA. ' ||
            'Use pkg_ventas.sp_anular_venta.');
    END IF;
END trg_protege_venta_emitida;
/

PROMPT Triggers creados.

SELECT trigger_name, trigger_type, triggering_event, table_name, status
  FROM user_triggers
 ORDER BY trigger_name;
