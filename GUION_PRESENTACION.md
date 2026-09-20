# Guion de Presentación — TecnoParts SpA

**Asignatura:** BDY1103 — Taller de Base de Datos | **Duoc UC**
**Equipo:** Ignacio · Rodrigo · Bryan · Felipe
**Duración máxima:** 7 minutos

> La pauta evalúa 4 indicadores (15% cada uno = 60%): tipos compuestos, cursores, excepciones, y procedimientos/funciones/packages/triggers. Las slides de contexto (1-4) y cierre (13-14) **no son indicador evaluado** — se pasan rápido. El peso real está en las 4 partes técnicas.

---

## IGNACIO — Apertura + Tipos Compuestos *(≈ 1 min 50 seg)*

### Slides 1-4, todas juntas, sin detenerse *(20 seg)*

> Buenos días, somos el equipo de **TecnoParts SpA**. Hoy la lógica de negocio vive en planillas Excel: márgenes inconsistentes, sobreventa por falta de validación de stock, y reportes que demoran tres días. Centralizamos todo eso en un **motor PL/SQL** sobre este modelo — core transaccional, catálogo maestro y tablas de trazabilidad. Paso a mi parte: **tipos de datos compuestos**.

### Slide 5 — RECORD y VARRAY *(25 seg)*

> Usamos dos, y cada uno corresponde a un caso distinto. El **RECORD** agrupa datos heterogéneos en una fila de resultado que **no existe en ninguna tabla** — es un cálculo. El **VARRAY** es una colección **indexada de tamaño máximo fijo**, usada donde el negocio define una cardinalidad exacta.

### Slide 6 — Implementación *(65 seg)*

> `t_resumen_cat` es el **RECORD**: mezcla datos de categoría con métricas calculadas, **inicializadas en 0** para no arrastrar NULL. Tenemos dos **VARRAY**: `t_metas_trim` de tamaño **4**, porque las metas trimestrales son exactamente cuatro; `t_top_sku` de tamaño **5**, porque el negocio definió un top 5. Esto es lo que quiero **justificar**: el límite del VARRAY es una **regla de negocio que el motor obliga a cumplir** — Oracle rechaza una quinta meta. Y en eficiencia: cargar las cuatro metas en un solo VARRAY baja de **48 a 12 consultas** para 12 categorías.

*→ pasa a Rodrigo*

---

## RODRIGO — Cursores *(≈ 1 min 30 seg)*

### Slide 7 — Arquitectura Multinivel *(40 seg)*

> Gracias, Ignacio. Mi parte son los **cursores explícitos**, en tres niveles anidados. **Nivel 1**, `c_categorias`, sin parámetros. **Nivel 2**, `c_productos`, **parametrizado**: recibe el `id_categoria` del nivel 1 más un rango de fechas. **Nivel 3**, `c_movimientos`, recibe el `id_producto` del nivel 2. La razón de anidarlos: cada nivel **depende del contexto del anterior**.

### Slide 8 — Cursor Parametrizado *(50 seg)*

> Este cursor **justifica el uso de parámetros**: JOIN entre producto y detalle_venta, **agregado con `SUM` y `GROUP BY` en el motor**, no en PL/SQL. El **`LEFT JOIN`** conserva productos con **cero ventas**, porque la rotación nula también es información relevante. Y como ya viene ordenado por venta neta, el **top 5 sale sin una segunda consulta**. El motor agrupa 50 mil líneas en 600 productos antes de entrar al loop.

*→ pasa a Bryan*

---

## BRYAN — Excepciones *(≈ 1 min 30 seg)*

### Slide 9 — Tipos de Excepciones *(40 seg)*

> Gracias, Rodrigo. El criterio: **si el motor detecta la condición solo, es predefinida; si es una regla de negocio, la definimos nosotros**. Predefinidas: `NO_DATA_FOUND`, `ZERO_DIVIDE` al calcular margen sin ventas, `SUBSCRIPT_BEYOND_COUNT`. De usuario: `e_stock_insuficiente` (**-20020**) y precio bajo costo (**-20031**), levantadas con **`RAISE_APPLICATION_ERROR`**.

### Slide 10 — Alcance y Propagación *(50 seg)*

> Lo clave es **dónde se captura cada una**. A nivel de **operación**, `ZERO_DIVIDE` asigna NULL y la iteración sigue **inmediatamente** — sin esto, una categoría sin ventas cortaría todo el reporte. A nivel de **iteración**, si falta la meta, hacemos `CONTINUE` y saltamos solo esa categoría. A nivel **global**, `WHEN OTHERS` hace `ROLLBACK` y registra el error. Y `sp_registrar_log` usa **`PRAGMA AUTONOMOUS_TRANSACTION`**, así el **COMMIT del log sobrevive al ROLLBACK** — la evidencia nunca se pierde.

*→ pasa a Felipe*

---

## FELIPE — Objetos Almacenados + Conclusión *(≈ 1 min 35 seg)*

### Slide 11 — Objetos PL/SQL *(45 seg)*

> Gracias, Bryan. Cierro **evaluando** por qué cada tarea fue al objeto correcto. Los **procedimientos**, como `sp_registrar_venta`, **modifican el estado** de la base. Las **funciones**, como `fn_margen_pct`, hacen cálculo puro, invocable dentro de un `SELECT`. Los **packages** **encapsulan** la lógica privada — nadie fuera de `pkg_ventas` aplica el descuento de otra forma. Los **triggers** ejecutan integridad que **ninguna aplicación cliente puede evadir**.

### Slide 12 — Flujo de Interacción *(35 seg)*

> En una venta: el procedimiento orquestador invoca la función de descuento. Al insertar el detalle, `trg_valida_detalle` actúa como **barrera** — si no hay stock, `ROLLBACK` antes de que el dato entre. Si pasa, `trg_descuenta_stock` actualiza el inventario **automáticamente**, y el procedimiento cierra con `COMMIT`.

### Conclusión — slides 13-14 solo como apoyo visual mudo *(15 seg)*

> En resumen: centralizamos en PL/SQL lo que eran fórmulas distintas y reportes de tres días, con reglas que el sistema mismo hace cumplir. Muchas gracias.

---

## Resumen de tiempos

| Integrante | Slides | Tiempo |
|---|---|---|
| Ignacio | 1-6 | 1:50 |
| Rodrigo | 7-8 | 1:30 |
| Bryan | 9-10 | 1:30 |
| Felipe | 11-12 + cierre | 1:35 |
| **Total** | | **~6:55** |

**Si se pasan del tiempo:** el primer corte, sin tocar las 4 partes técnicas, es la frase final de Rodrigo sobre las 50 mil líneas — es ilustrativa, no evidencia obligatoria del indicador.
