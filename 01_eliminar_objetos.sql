-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 01_eliminar_objetos.sql
-- Limpieza del esquema. Ejecutar SOLO si se quiere reinstalar desde cero.
-- Los bloques ignoran el error si el objeto no existe.
-- ============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF

BEGIN
    FOR t IN (SELECT table_name FROM user_tables
               WHERE table_name IN ('DETALLE_VENTA','VENTA','MOVIMIENTO_STOCK',
                                    'AUDITORIA_PRECIO','ALERTA_STOCK','LOG_ERROR',
                                    'META_CATEGORIA','PRODUCTO','CATEGORIA',
                                    'PROVEEDOR','CLIENTE','SUCURSAL'))
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Tabla eliminada: ' || t.table_name);
    END LOOP;
END;
/

BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences
               WHERE sequence_name LIKE 'SEQ\_%' ESCAPE '\')
    LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
        DBMS_OUTPUT.PUT_LINE('Secuencia eliminada: ' || s.sequence_name);
    END LOOP;
END;
/

BEGIN
    FOR o IN (SELECT object_name, object_type FROM user_objects
               WHERE object_type IN ('PROCEDURE','FUNCTION','PACKAGE'))
    LOOP
        EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
        DBMS_OUTPUT.PUT_LINE('Objeto eliminado: ' || o.object_type || ' ' || o.object_name);
    END LOOP;
END;
/

PROMPT Esquema limpio.
