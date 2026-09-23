# 📦 TECNOPARTS SpA — Sistema de Gestión de Ventas e Inventarios

<div align="center">

![Oracle](https://img.shields.io/badge/Oracle-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![PL/SQL](https://img.shields.io/badge/PL%2FSQL-336791?style=for-the-badge&logo=oracle&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-DD6B20?style=for-the-badge&logo=databricks&logoColor=white)
![SQL Developer](https://img.shields.io/badge/SQL%20Developer-4479A1?style=for-the-badge&logo=oracle&logoColor=white)

![Status](https://img.shields.io/badge/Estado-Producción%20Docente-success?style=flat-square)
![DB](https://img.shields.io/badge/Base%20de%20Datos-Oracle%20RDBMS-red?style=flat-square)
![Curso](https://img.shields.io/badge/Curso-BDY1103%20%7C%20Taller%20de%20BD-informational?style=flat-square)
![Scripts](https://img.shields.io/badge/Scripts-8%20módulos%20SQL-blueviolet?style=flat-square)

</div>

---

## 🧭 Índice de Archivos

> **Orden de ejecución obligatorio.** Cada módulo del proyecto está numerado y encadenado: la instalación es reproducible de punta a punta con un solo script maestro.

| N° | Archivo | Rol en el sistema | Referencia |
|:--:|---------|-------------------|:----------:|
| 0️⃣ | `00_instalar.sql` | Script maestro de instalación | [Ver sección](#0️⃣-00_instalarsql--script-maestro-de-instalación) |
| 1️⃣ | `01_crear_tablas.sql` | Esquema DDL: tablas, secuencias e índices | [Ver sección](#1️⃣-01_crear_tablassql--esquema-de-la-base-de-datos) |
| 2️⃣ | `02_poblar_datos.sql` | Carga de datos de demostración | [Ver sección](#2️⃣-02_poblar_datassql--carga-de-datos-de-demostración) |
| 3️⃣ | `03_funciones_procedimientos.sql` | Rutinas almacenadas (funciones + SP) | [Ver sección](#3️⃣-03_funciones_procedimentossql--funciones-y-procedimientos-almacenados) |
| 4️⃣ | `04_packages.sql` | Package `pkg_ventas` (especificación + cuerpo) | [Ver sección](#4️⃣-04_packagessql--package-pkg_ventas) |
| 5️⃣ | `05_triggers.sql` | Triggers de validación, stock y auditoría | [Ver sección](#5️⃣-05_triggerssql--disparadores-triggers) |
| 6️⃣ | `06_bloque_anonimo.sql` | Reporte PL/SQL con cursors, RECORD y VARRAY | [Ver sección](#6️⃣-06_bloque_anonimosql--reporte-con-bloque-anónimo) |
| 7️⃣ | `07_pruebas.sql` | Plan de pruebas (10 casos de test) | [Ver sección](#7️⃣-07_pruebassql--plan-de-pruebas) |

---

## 🛠️ Stack Tecnológico

| Tecnología | Icono | Rol en el proyecto |
|------------|:-----:|--------------------|
| **Oracle RDBMS** | 🔴 | Motor de base de datos relacional donde reside el esquema completo |
| **PL/SQL** | 🟦 | Lenguaje procedural: funciones, procedimientos, packages, triggers y bloque anónimo |
| **SQL (DDL/DML)** | 🟠 | Creación de objetos, restricciones, consultas y carga de datos |
| **SQL*Plus / SQL Developer** | 🔷 | Consola de ejecución (`SET SERVEROUTPUT`, `@@` para encadenar scripts) |
| **Cursors explícitos** | 🖱️ | Recorridos fila a fila con y sin parámetros |
| **Colecciones (VARRAY / RECORD)** | 🧱 | Tipos de datos compuestos para el reporte ejecutivo |
| **Auditoría y bitácora** | 🛡️ | Trazabilidad de precios, stock y errores en tablas de soporte |

---

# 📄 Detalle de los Archivos

---

## 0️⃣ `00_instalar.sql` — Script Maestro de Instalación

> ⚡ **El punto de partida de todo el sistema.** Este script orquesta la instalación completa en 5 pasos encadenados mediante `@@`, garantizando el orden correcto de dependencias: primero los datos, después la lógica. Su diseño evita el error clásico de crear triggers antes de la carga histórica — lo que dispararía descuentos de stock fantasma — y compila el package solo cuando sus funciones ya existen.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Instalar el esquema completo en un solo paso, con verificación final |
| 🔗 **Encadena** | `01 → 02 → 03 → 04 → 05` (en ese orden exacto) |
| ⚙️ **Configura** | `SERVEROUTPUT ON`, `DEFINE OFF`, `LINESIZE 200` |
| ✅ **Verifica** | Conteo de objetos por tipo en `user_objects` al finalizar |
| 📌 **Nota clave** | `02` (datos) corre **antes** de `05` (triggers) y `03` (funciones) corre **antes** de `04` (package que las usa) |

---

## 1️⃣ `01_crear_tablas.sql` — Esquema de la Base de Datos

> 🏗️ **Los cimientos del modelo relacional.** Aquí nacen las **10 tablas** del negocio: catálogos (`categoria`, `proveedor`, `cliente`, `sucursal`), el corazón operativo (`producto`, `venta`, `detalle_venta`), las metas trimestrales (`meta_categoria`) y las tablas de soporte (`movimiento_stock`, `auditoria_precio`, `alerta_stock`, `log_error`). Cada tabla incorpora integridad declarativa: claves primarias, foráneas, checks de negocio y valores por defecto.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Crear el DDL completo: tablas + secuencias + índices |
| 🗂️ **Tablas (10)** | `categoria`, `proveedor`, `producto`, `cliente`, `sucursal`, `meta_categoria`, `venta`, `detalle_venta`, `movimiento_stock` + 3 tablas de soporte/auditoría |
| 🔢 **Secuencias (5)** | `seq_venta`, `seq_movimiento`, `seq_auditoria`, `seq_alerta`, `seq_log` — parten en **100** para no chocar con los IDs fijos del script 02 |
| 🔒 **Integridad** | CHECKs de negocio (precios ≥ 0, estados válidos, descuentos 0–100 %), FKs referenciadas y PKs compuestas (`meta_categoria`, `detalle_venta`) |
| 🚀 **Índices (3)** | `ix_producto_categoria`, `ix_detalle_producto`, `ix_venta_fecha` para acelerar las consultas del reporte |
| 🌟 **Diseño destacado** | `meta_categoria` guarda las metas **una columna por trimestre**, pensada para cargarse en un `VARRAY(4)` en el reporte |

---

## 2️⃣ `02_poblar_datos.sql` — Carga de Datos de Demostración

> 📊 **Un dataset realista y reproducible.** Puebla el esquema con **32 productos** de hardware (CPUs, GPUs, RAM, SSDs, periféricos), **12 clientes** con sus tres tipos (NORMAL / PREFERENTE / EMPRESA), **4 sucursales** (incluido el canal e-commerce) y un trimestre completo de ventas de 2026. Las fechas son fijas a propósito: el reporte del script 06 entrega **siempre el mismo resultado**, comparable con la tabla del informe.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Cargar datos históricos coherentes para ejecutar reportes y pruebas |
| 📦 **Volumen** | 10 categorías · 5 proveedores · 32 productos · 12 clientes · 8 metas anuales · 21 ventas · 47 líneas de detalle · movimientos de inventario |
| 🧮 **Cálculos** | Totales de cabecera recalculados desde el detalle con **IVA 19 %** (`UPDATE` masivo sobre `venta`) |
| 📦 **Inventario** | Genera ENTRADA inicial por producto, SALIDA por cada línea vendida y 2 AJUSTES por merma — todo con `seq_movimiento.NEXTVAL` |
| 🌟 **Casos de borde** | Categoría 9 **sin metas** y categoría 7 **con metas en cero**: ejercitan las excepciones del bloque anónimo; ventas del trimestre anterior (19, 20) y una venta **ANULADA** (21) que el reporte debe ignorar |
| ⚠️ **Orden crítico** | Corre **antes** de crear los triggers, para que la carga histórica no descuento stock automáticamente |

---

## 3️⃣ `03_funciones_procedimientos.sql` — Funciones y Procedimientos Almacenados

> 🧠 **La lógica de negocio encapsulada en el motor.** Tres funciones puras —que devuelven un valor con `RETURN` y no modifican datos, por eso pueden invocarse dentro de un `SELECT`— y dos procedimientos orientados a acción. Incluye manejo de excepciones predefinidas de Oracle (`NO_DATA_FOUND`) y el patrón de bitácora: ante cualquier fallo, se registra en `log_error` y se relanza la excepción.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Rutinas reutilizables de cálculo y operación |
| 🔢 **Funciones (3)** | `fn_margen_pct` → margen % de un producto · `fn_descuento_cliente` → 0 / 5 / 12 % según tipo · `fn_total_venta` → total con IVA 19 % |
| ⚙️ **Procedimientos (2)** | `sp_registrar_log` → bitácora de errores · `sp_generar_alertas_stock` → cursor que recorre productos bajo stock crítico e inserta alertas |
| 🌟 **Patrón destacado** | `sp_generar_alertas_stock` usa cursor explícito + `FOR` loop + `COMMIT` final + `WHEN OTHERS → ROLLBACK → log → RAISE` |
| 🔗 **Dependencia** | Debe compilarse **antes** del package (script 04), porque `pkg_ventas` invoca `fn_descuento_cliente` y `sp_registrar_log` |

---

## 4️⃣ `04_packages.sql` — Package `pkg_ventas`

> 🏛️ **La API transaccional del sistema.** Un package agrupa lo relacionado bajo un mismo contrato: la **especificación** declara qué es visible desde fuera (constante, excepciones y 3 procedimientos) y el **cuerpo** contiene la implementación. Aquí vive el ciclo completo de una venta: registrar → agregar líneas → cerrar, con validación de stock, cálculo automático de descuentos por tipo de cliente y errores de negocio con `RAISE_APPLICATION_ERROR` en el rango −20001 a −20004.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Encapsular el flujo transaccional de ventas con reglas de negocio |
| 📐 **Estructura** | `c_iva CONSTANT 0.19` · 3 excepciones de usuario (`e_stock_insuficiente`, `e_venta_sin_detalle`, `e_cliente_inexistente`) · 3 procedimientos |
| ⚙️ **API pública** | `sp_registrar_venta` (crea venta en `BORRADOR`, devuelve `OUT` el ID) · `sp_agregar_linea` (valida stock, calcula descuento, numera líneas) · `sp_cerrar_venta` (calcula totales, emite la venta, `COMMIT`) |
| 🚨 **Errores de negocio** | −20001 cliente inexistente · −20002 stock insuficiente · −20003 venta/producto no existe · −20004 venta sin detalle |
| 🌟 **Integración** | Reutiliza `fn_descuento_cliente` y `sp_registrar_log` del script 03 — el package **no duplica lógica** |
| 🔁 **Transaccionalidad** | `ROLLBACK` + registro en bitácora ante cualquier error no previsto (`WHEN OTHERS → RAISE`) |

---

## 5️⃣ `05_triggers.sql` — Disparadores (Triggers)

> 🛡️ **La última línea de defensa a nivel de datos.** Tres triggers por fila (`FOR EACH ROW`) que actúan solos, sin depender de la aplicación: uno valida **antes** de insertar que haya stock suficiente — regla que un `CHECK` no puede expresar porque compara contra otra tabla —, otro descuenta stock y registra el movimiento **después** de la inserción, y el tercero audita cada cambio de precio bloqueando ventas bajo costo. Se crean al final para no interferir con la carga histórica.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Automatizar validación, inventario y auditoría en tiempo de ejecución |
| 🔒 `trg_valida_detalle` | `BEFORE INSERT` sobre `detalle_venta`: rechaza con error **−20010** si la cantidad supera el `stock_actual` |
| 📉 `trg_descuenta_stock` | `AFTER INSERT` sobre `detalle_venta`: descuenta stock del producto + inserta el movimiento `SALIDA` con su `id_venta` |
| 🧾 `trg_audita_precio` | `BEFORE UPDATE` sobre `producto`: bloquea precios < costo (**−20011**) y guarda el histórico en `auditoria_precio` con usuario y fecha |
| ⚠️ **Orden crítico** | Se crean **después** del script 02, para que la carga histórica no dispare el descuento automático de stock |
| ✅ **Verificación** | Consulta final a `user_triggers` mostrando evento, tabla y estado de cada uno |

---

## 6️⃣ `06_bloque_anonimo.sql` — Reporte con Bloque Anónimo

> 📈 **La pieza maestra que integra todo el lenguaje PL/SQL.** Este bloque anónimo genera el reporte ejecutivo de *ventas y cumplimiento de metas por categoría*, con un recorrido de **tres loops anidados** (categoría → producto → movimiento) alimentado por tres cursores explícitos. Reúne los cuatro contenidos evaluados del taller: tipos compuestos (`RECORD` + dos `VARRAY`), cursores con y sin parámetros, bucles anidados y manejo completo de excepciones.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Reporte de ventas, margen, inventario y cumplimiento de metas por trimestre |
| 🧱 **Tipos compuestos** | `t_resumen` (RECORD con 7 campos) · `t_metas` VARRAY(4) — una meta por trimestre, indexado por N° de trimestre · `t_top` VARRAY(5) — top 5 de SKUs |
| 🖱️ **Cursores (3)** | `c_categorias` → **sin parámetros**, categorías activas · `c_productos(id_categoria, desde, hasta)` → **con parámetros**, ventas por producto con `LEFT JOIN` (mantiene productos sin ventas) · `c_movimientos(id_producto, desde)` → **con parámetros**, entradas/salidas de inventario |
| 🔀 **Excepciones cubiertas** | `NO_DATA_FOUND` (categoría sin metas) · `TOO_MANY_ROWS` (metas duplicadas) · `e_meta_en_cero` (definida por el usuario) · `ZERO_DIVIDE` (margen no calculable, capturado en sub-bloque para no cortar el reporte) · `WHEN OTHERS` global → bitácora |
| 🖨️ **Salida** | Formateo con `DBMS_OUTPUT`: tabla por categoría con SKU, unidades, venta neta, inventario E/S, total, margen, cumplimiento % y TOP 5 |
| 🌟 **Robustez** | Cada categoría se procesa en su propio sub-bloque: un error puntual **omite la categoría** sin abortar el reporte completo, y al final muestra contadores de procesadas/omitidas |

---

## 7️⃣ `07_pruebas.sql` — Plan de Pruebas

> 🧪 **10 casos de test que demuestran que todo funciona.** Este script ejercita cada capa del sistema: funciones desde `SELECT`, el flujo completo de una venta vía package, la captura de excepciones de negocio, la auditoría de precios, el bloqueo de ventas bajo costo y las alertas de stock. Cierra con una verificación de integridad estructural: la consulta de **objetos inválidos debe devolver 0 filas**.

| Aspecto | Detalle |
|---------|---------|
| 🎯 **Propósito** | Validar funciones, procedimientos, package y triggers de forma sistemática |
| ✅ **Casos (10)** | **1** margen % desde SELECT · **2** descuentos por tipo de cliente · **3** venta completa con package (verifica stock antes → después vía trigger) · **4** excepción stock insuficiente (−20002) · **5** excepción venta sin detalle (−20004) · **6** auditoría de cambio de precio · **7** bloqueo de precio bajo costo (−20011) · **8** generación de alertas de stock · **9** bitácora de errores · **10** objetos inválidos = 0 |
| 🔍 **Verificación** | Cada caso positivo confirma datos escritos; cada caso negativo confirma que la excepción se captura con `SQLERRM` |
| 🌟 **Criterio de éxito** | Todas las excepciones lanzadas deben ser **capturadas correctamente** y el esquema debe quedar sin objetos en estado `INVALID` |

---

# 🚀 Guía de Ejecución

```sql
-- 1. Conectarse a un esquema de práctica vacío en Oracle (SQL*Plus o SQL Developer)
-- 2. Ejecutar el script maestro desde la carpeta que contiene los demás scripts:
@@00_instalar.sql

-- 3. Generar el reporte ejecutivo:
@@06_bloque_anonimo.sql

-- 4. Ejecutar el plan de pruebas:
@@07_pruebas.sql
```

---

## 🔗 Cadena de Dependencias

```text
00_instalar.sql
 ├──▶ 01_crear_tablas.sql      (tablas + secuencias + índices)
 ├──▶ 02_poblar_datos.sql      (dataset histórico)          ⚠ antes de triggers
 ├──▶ 03_funciones_procedimientos.sql  (rutinas base)       ⚠ antes del package
 ├──▶ 04_packages.sql          (pkg_ventas: usa 03)
 └──▶ 05_triggers.sql          (validación + stock + auditoría)
        ▼
 06_bloque_anonimo.sql         (reporte ejecutivo)
 07_pruebas.sql                (10 casos de prueba)
```

---

<div align="center">

**TecnoParts SpA** · BDY1103 — Taller de Base de Datos 🗄️

*Esquema documentado · Lógica almacenada · Integridad garantizada*

</div>
