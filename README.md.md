# PokeMarket — Propuesta de proyecto
### BDY1103, Taller de Base de Datos — Evaluación Parcial N°1

## 1. Contexto de negocio

**PokeMarket** es una tienda en línea de compra y venta de cartas Pokémon coleccionables. Tres tipos de usuario interactúan con la plataforma:

- **Administrador**: gestiona el catálogo (cartas, colecciones, precios) y supervisa la operación.
- **Vendedor**: publica y actualiza cartas disponibles para la venta.
- **Cliente**: navega el catálogo y realiza pedidos.

El objetivo del desarrollo en PL/SQL es automatizar y asegurar la integridad de tres procesos críticos del negocio: la consulta de catálogo por colección/rareza, el registro de pedidos con control de stock en tiempo real, y la auditoría de cambios de precio.

## 2. Modelo de datos

| Tabla | Descripción |
|---|---|
| `roles` | Catálogo de roles (Administrador, Vendedor, Cliente) |
| `usuarios` | Usuarios de la plataforma, cada uno con un rol |
| `colecciones` | Sets/colecciones de cartas (ej. Base Set, Jungla) |
| `cartas` | Catálogo de cartas: nombre, colección, rareza, tipo, precio, stock |
| `pedidos` | Cabecera de cada pedido: usuario, fecha, estado, total |
| `detalle_pedido` | Líneas de un pedido: qué carta, cuántas unidades, a qué precio |
| `auditoria_precios` | Registro histórico de cambios de precio (alimentada por trigger) |

Con este modelo alcanza para cubrir con solidez los cinco indicadores de la pauta, sin sobrecargar el proyecto. El DDL completo, los datos de prueba y todo el código PL/SQL están en `pokemarket_modelo.sql`.

## 3. Tipos de datos compuestos (RECORD y VARRAY)

- **RECORD** (`carta_info_rec`): agrupa nombre, precio y stock de una carta al recuperarla desde un cursor, evitando declarar tres variables sueltas.
- **VARRAY** (`t_carrito`): arreglo de tamaño fijo (máx. 5) que simula el carrito de compra de un cliente, guardando los IDs de las cartas seleccionadas.

Ambos se combinan en el **Bloque anónimo 1** del script: se recorre el VARRAY, y por cada ID se abre un cursor parametrizado que llena el RECORD con los datos de esa carta. Esto justifica el uso conjunto: el VARRAY define *qué* cartas revisar, el RECORD define *cómo* se transporta la información de cada una.

## 4. Cursores explícitos complejos

- **Cursor sin parámetros** (`c_colecciones`): recorre todas las colecciones existentes.
- **Cursor con parámetros** (`c_cartas_coleccion(p_id_coleccion)`): recorre las cartas de una colección específica.
- **Loops anidados**: por cada colección (loop externo), se recorren sus cartas (loop interno) para calcular el valor total del inventario por colección — un reporte que ninguna consulta SQL plana entrega directamente de forma tan legible con acumuladores por grupo.

Esto está en el **Bloque anónimo 2**. El mismo patrón (cursor externo + cursor parametrizado interno) se puede reutilizar para un reporte de ventas por cliente (pedidos → detalle_pedido) si quieren mostrar una segunda aplicación en la presentación.

## 5. Control de excepciones

- **Predefinida de Oracle**: `NO_DATA_FOUND`, capturada cuando se busca una carta que no existe.
- **Definida por el usuario**: `stock_insuficiente`, asociada al código de error `-20001` vía `PRAGMA EXCEPTION_INIT` y lanzada con `RAISE_APPLICATION_ERROR` cuando la cantidad pedida supera el stock disponible.
- **`WHEN OTHERS`**: red de seguridad final que captura cualquier error no anticipado y lo reporta con `SQLERRM`.

Criterio para justificar en el informe/presentación: se usan excepciones predefinidas cuando el error es genérico y ya cubierto por Oracle (dato no encontrado, división por cero, etc.), y excepciones propias cuando la regla de negocio es específica de PokeMarket (no se puede vender más stock del disponible) y Oracle no tiene un código para eso.

## 6. Procedimientos, funciones, package y triggers

- **Función `calcular_total_pedido`**: suma cantidad × precio_unitario de todas las líneas de un pedido.
- **Función `precio_con_descuento`**: aplica 10% de descuento si la cantidad comprada es ≥ 5 unidades.
- **Procedimiento `registrar_pedido`**: valida stock con bloqueo (`FOR UPDATE`), crea el pedido y su detalle, y delega en el trigger la actualización del stock.
- **Package `pkg_ventas`**: agrupa las dos funciones y el procedimiento anteriores bajo una sola interfaz, ocultando la implementación interna (encapsulamiento) y facilitando el mantenimiento.
- **Trigger `trg_actualiza_stock`** (`AFTER INSERT` en `detalle_pedido`): descuenta automáticamente el stock cada vez que se agrega una línea a un pedido, sin depender de que la aplicación cliente lo haga bien.
- **Trigger `trg_auditoria_precio`** (`BEFORE UPDATE OF precio` en `cartas`): registra en `auditoria_precios` cada cambio de precio, con valor anterior, nuevo y usuario — ejemplo directo de auditoría automática, uno de los usos de triggers que pide explicar la pauta.

Puntos a discutir en el informe (la pauta lo pide explícitamente): el trigger de stock introduce un efecto colateral implícito — cualquiera que revise `detalle_pedido` sin conocer el trigger puede no entender por qué cambia el stock; por eso deben documentarlo bien. Y el package centraliza la lógica de negocio en la base de datos, lo que facilita reutilización pero acopla la aplicación a Oracle específicamente.

## 7. Mapeo a la pauta de evaluación

| Indicador | Peso | Evidencia en el proyecto |
|---|---|---|
| IE1.1.1 / IE1.1.2 — RECORD y VARRAY | 5% / 15% | Bloque anónimo 1 |
| IE1.2.1 / IE1.2.2 — Cursores complejos + loops anidados | 10% / 15% | Bloque anónimo 2 |
| IE1.3.1 / IE1.3.2 — Excepciones | 10% / 15% | Bloque anónimo 3 |
| IE1.4.1 / IE1.4.2 — Procedimientos, funciones, package, triggers | 15% / 15% | `pkg_ventas`, `trg_actualiza_stock`, `trg_auditoria_precio` |

(El primer porcentaje de cada fila es el peso en el informe; el segundo, en la presentación individual.)

## 8. Cómo usar esto para armar el informe

El informe debe seguir literalmente esta estructura (ya está en el orden de la pauta): Introducción → Tipos de datos compuestos → Desarrollo con cursores → Control de excepciones → Evaluación de procedimientos/funciones/packages/triggers → Conclusión → Anexos (código completo + diagramas). Las secciones 3 a 6 de este documento son casi el borrador directo de esas mismas secciones del informe — solo falta expandir la redacción y agregar el diagrama entidad-relación del modelo.

## 9. Próximos pasos

1. Correr `pokemarket_modelo.sql` en Oracle (SQL Developer, Live SQL, o el motor que usen en el taller) y revisar que todo compile y los bloques anónimos impriman lo esperado.
2. Ajustar nombres/datos si el equipo quiere afinar el caso (por ejemplo, agregar condición de la carta: Mint, Near Mint, etc.).
3. Dibujar el diagrama entidad-relación del modelo para el informe.
4. Redactar el informe usando este documento como base.
5. Preparar el guión de la presentación individual (puntos a–g), en tono de justificación más que de descripción técnica pura.
