-- ============================================================================
-- TecnoParts SpA  |  00_instalar.sql
-- Script maestro. Ejecutar desde la carpeta que contiene los demas scripts.
--
-- El orden importa:
--   02 (datos) va antes de 05 (triggers), para que la carga historica
--      no dispare el descuento automatico de stock.
--   03 (funciones) va antes de 04 (package), porque el package las usa.
-- ============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF
SET LINESIZE 200

PROMPT ### 1/5 Creando tablas ###
@@01_crear_tablas.sql

PROMPT ### 2/5 Cargando datos ###
@@02_poblar_datos.sql

PROMPT ### 3/5 Creando funciones y procedimientos ###
@@03_funciones_procedimientos.sql

PROMPT ### 4/5 Creando package ###
@@04_packages.sql

PROMPT ### 5/5 Creando triggers ###
@@05_triggers.sql

PROMPT ### Verificacion ###
SELECT object_type, COUNT(*) AS cantidad
  FROM user_objects
 GROUP BY object_type
 ORDER BY object_type;

PROMPT Instalacion terminada.
PROMPT Ejecute 06_bloque_anonimo.sql para generar el reporte.
PROMPT Ejecute 07_pruebas.sql para probar los objetos almacenados.
