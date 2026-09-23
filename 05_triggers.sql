-- ============================================================================
-- TecnoParts SpA  |  05_triggers.sql
-- Un trigger se ejecuta solo cuando ocurre el evento indicado.
-- Se crean DESPUES de cargar los datos, para que la carga historica
-- no dispare el descuento automatico de stock.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- Valida la linea antes de insertarla.
-- Es una regla que una restriccion CHECK no puede expresar, porque
-- compara contra el stock, que esta en otra tabla.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_valida_detalle
BEFORE INSERT ON detalle_venta
FOR EACH ROW
DECLARE
    v_stock producto.stock_actual%TYPE;
BEGIN
    SELECT stock_actual
      INTO v_stock
      FROM producto
     WHERE id_producto = :NEW.id_producto;

    IF v_stock < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Stock insuficiente del producto ' || :NEW.id_producto ||
            '. Disponible: ' || v_stock);
    END IF;
END trg_valida_detalle;
/

-- ----------------------------------------------------------------------------
-- Descuenta el stock y registra el movimiento despues de insertar la linea.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_descuenta_stock
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto
       SET stock_actual = stock_actual - :NEW.cantidad
     WHERE id_producto = :NEW.id_producto;

    INSERT INTO movimiento_stock (id_movimiento, id_producto,
                                  tipo_movimiento, cantidad, id_venta)
    VALUES (seq_movimiento.NEXTVAL, :NEW.id_producto,
            'SALIDA', :NEW.cantidad, :NEW.id_venta);
END trg_descuenta_stock;
/

-- ----------------------------------------------------------------------------
-- Audita los cambios de precio y bloquea los precios bajo el costo.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audita_precio
BEFORE UPDATE ON producto
FOR EACH ROW
BEGIN
    IF :NEW.precio_venta <> :OLD.precio_venta THEN

        IF :NEW.precio_venta < :NEW.costo_unitario THEN
            RAISE_APPLICATION_ERROR(-20011,
                'El precio de venta no puede ser menor que el costo.');
        END IF;

        INSERT INTO auditoria_precio (id_auditoria, id_producto,
                    precio_anterior, precio_nuevo, usuario_bd)
        VALUES (seq_auditoria.NEXTVAL, :OLD.id_producto,
                :OLD.precio_venta, :NEW.precio_venta, USER);
    END IF;
END trg_audita_precio;
/

PROMPT Triggers creados.

SELECT trigger_name, triggering_event, table_name, status
  FROM user_triggers
 ORDER BY trigger_name;
