-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 00_instalar_todo.sql
-- Script maestro. Ejecutar desde SQL*Plus o SQL Developer (F5) estando en el
-- directorio que contiene los demas scripts.
--
--   sqlplus usuario/clave@XEPDB1 @00_instalar_todo.sql
--
-- El orden NO es arbitrario:
--   03 (datos) va antes de 06 (triggers) para que la carga historica no
--   dispare el descuento automatico de stock.
--   04 (funciones) va antes de 05 (packages) porque estos las invocan.
-- ============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200
SPOOL instalacion.log

PROMPT ######## 1/6  Limpieza del esquema ########
@@01_eliminar_objetos.sql

PROMPT ######## 2/6  Creacion de tablas ########
@@02_crear_tablas.sql

PROMPT ######## 3/6  Poblacion de datos ########
@@03_poblar_datos.sql

PROMPT ######## 4/6  Funciones y procedimientos ########
@@04_funciones_procedimientos.sql

PROMPT ######## 5/6  Packages ########
@@05_packages.sql

PROMPT ######## 6/6  Triggers ########
@@06_triggers.sql

PROMPT ######## Verificacion final ########
SELECT object_type, COUNT(*) AS cantidad
  FROM user_objects
 GROUP BY object_type
 ORDER BY object_type;

SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID';

PROMPT ######## Instalacion completa ########
PROMPT Ejecute 07_bloque_anonimo_reporte.sql para generar el reporte.
PROMPT Ejecute 08_pruebas.sql para validar los objetos almacenados.

SPOOL OFF
