# Scripts SQL — TecnoParts SpA (BDY1103)

Base de datos Oracle para la tienda de computadores y componentes del caso semestral.

## Orden de ejecución

| # | Archivo | Qué hace |
|---|---|---|
| 00 | `00_instalar_todo.sql` | Script maestro: ejecuta del 01 al 06 y genera `instalacion.log` |
| 01 | `01_eliminar_objetos.sql` | Limpia el esquema (solo para reinstalar desde cero) |
| 02 | `02_crear_tablas.sql` | 12 tablas, restricciones, 5 secuencias y 4 índices |
| 03 | `03_poblar_datos.sql` | Datos de prueba: 10 categorías, 31 productos, 12 clientes, 21 ventas |
| 04 | `04_funciones_procedimientos.sql` | `sp_registrar_log`, `fn_margen_pct`, `fn_precio_final`, `fn_dias_cobertura` |
| 05 | `05_packages.sql` | `pkg_ventas` y `pkg_inventario` (especificación + cuerpo) |
| 06 | `06_triggers.sql` | 5 triggers de validación, auditoría y automatización |
| 07 | `07_bloque_anonimo_reporte.sql` | Bloque anónimo del reporte (RECORD, VARRAY, cursores anidados, excepciones) |
| 08 | `08_pruebas.sql` | 14 pruebas de los objetos y de los caminos de excepción |

Desde SQL*Plus, parado en la carpeta de los scripts:

```
sqlplus usuario/clave@XEPDB1 @00_instalar_todo.sql
```

Luego, por separado:

```
@07_bloque_anonimo_reporte.sql
@08_pruebas.sql
```

En SQL Developer: abrir cada archivo y ejecutar con F5 (Run Script), no con Ctrl+Enter.

## Dos detalles de orden que importan

1. **Los datos se cargan antes que los triggers.** Si los triggers existieran durante la carga histórica, `trg_descuenta_stock` descontaría el stock dos veces (una por el trigger y otra por el `UPDATE` final del script 03). Por eso el script 03 calcula el stock final y los movimientos de SALIDA de forma explícita.
2. **Las funciones van antes que los packages,** porque `pkg_ventas` y `pkg_inventario` invocan `sp_registrar_log`.

## Casos preparados a propósito para la demostración

| Caso | Dónde | Qué demuestra |
|---|---|---|
| Categoría 9 (Refrigeración) sin fila en `META_CATEGORIA` | script 03 | Excepción de usuario `e_meta_no_definida` |
| Categoría 7 (Gabinetes) con metas en 0 | script 03 | Excepción de usuario `e_meta_en_cero` |
| Categoría 10 inactiva | script 03 | El cursor `c_categorias` filtra `activo = 'S'` |
| Venta 21 en estado ANULADA | script 03 | El cursor del reporte filtra `estado = 'EMITIDA'` |
| Ventas 19 y 20 del trimestre anterior | script 03 | El filtro por rango de fechas del cursor parametrizado |
| Productos sin ventas en el período | script 03 | El `LEFT JOIN` los conserva con métricas en 0 |
| Producto 303 con stock bajo el crítico | scripts 03 y 08 | Trigger `trg_alerta_stock_critico` |

Las fechas de las ventas usan `GREATEST(TRUNC(SYSDATE,'Q'), SYSDATE - n)`, así siempre caen dentro del trimestre en curso sin quedar en el futuro, independientemente del día en que se ejecute el script.

## Mapeo con los indicadores de la evaluación

| Indicador | Evidencia |
|---|---|
| IE1.1.1 — RECORD y VARRAY | Script 07: `t_resumen_cat`, `t_metas_trim` (VARRAY(4)), `t_top_sku` (VARRAY(5)) |
| IE1.2.1 — Cursores explícitos complejos con parámetros y loops anidados | Script 07: `c_categorias`, `c_productos(3 parámetros)`, `c_movimientos(2 parámetros)` en tres niveles |
| IE1.3.1 — Excepciones Oracle y de usuario | Script 07 (tres niveles de manejo) y script 08 (pruebas 4, 5, 7, 8, 9, 11) |
| IE1.4.1 — Procedimientos, funciones, packages y triggers | Scripts 04, 05 y 06 |

## Verificación rápida tras instalar

```sql
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID';   -- debe devolver 0 filas
```

Si algún objeto queda inválido, `SHOW ERRORS` después del `CREATE` muestra la línea exacta.
