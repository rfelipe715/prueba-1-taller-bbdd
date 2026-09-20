-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- modelo_tecnoparts_datamodeler.sql
--
-- DDL preparado para IMPORTAR en Oracle SQL Developer Data Modeler.
--
-- Diferencias con el script de instalacion (02_crear_tablas.sql):
--   - Sin comandos SQL*Plus (SET, PROMPT, SPOOL): el importador de Data
--     Modeler los rechaza.
--   - Sin bloques PL/SQL.
--   - Todas las restricciones van con NOMBRE EXPLICITO y en ALTER TABLE
--     separado, para que Data Modeler dibuje las relaciones con ese nombre
--     y no con uno generado (SYS_C00xxxxx).
--   - Comentarios COMMENT ON: se importan como notas de tabla y columna,
--     y suben al modelo logico como definicion de la entidad/atributo.
--
-- Como importarlo:
--   File > Import > DDL File...  > agregar este archivo
--   > Oracle Database 12c (o 19c/21c) > OK
--   Queda el MODELO RELACIONAL. Luego:
--   Design > Engineer to Logical Model  -> genera el MODELO LOGICO (MER)
-- ============================================================================


-- ############################################################################
-- TABLAS MAESTRAS
-- ############################################################################

CREATE TABLE categoria (
    id_categoria      NUMBER(4)     NOT NULL,
    nombre            VARCHAR2(50)  NOT NULL,
    margen_referencia NUMBER(5,2)   DEFAULT 0,
    activo            CHAR(1)       DEFAULT 'S' NOT NULL
);

CREATE TABLE proveedor (
    id_proveedor NUMBER(5)    NOT NULL,
    rut          VARCHAR2(12) NOT NULL,
    nombre       VARCHAR2(80) NOT NULL,
    pais         VARCHAR2(40) DEFAULT 'Chile',
    email        VARCHAR2(80)
);

CREATE TABLE producto (
    id_producto    NUMBER(8)     NOT NULL,
    sku            VARCHAR2(30)  NOT NULL,
    nombre         VARCHAR2(120) NOT NULL,
    id_categoria   NUMBER(4)     NOT NULL,
    id_proveedor   NUMBER(5)     NOT NULL,
    costo_unitario NUMBER(12,2)  NOT NULL,
    precio_venta   NUMBER(12,2)  NOT NULL,
    stock_actual   NUMBER(8)     DEFAULT 0 NOT NULL,
    stock_critico  NUMBER(8)     DEFAULT 5 NOT NULL,
    activo         CHAR(1)       DEFAULT 'S' NOT NULL
);

CREATE TABLE cliente (
    id_cliente     NUMBER(8)     NOT NULL,
    rut            VARCHAR2(12)  NOT NULL,
    nombre         VARCHAR2(100) NOT NULL,
    email          VARCHAR2(80),
    tipo_cliente   VARCHAR2(12)  DEFAULT 'NORMAL' NOT NULL,
    fecha_registro DATE          DEFAULT SYSDATE
);

CREATE TABLE sucursal (
    id_sucursal NUMBER(3)    NOT NULL,
    nombre      VARCHAR2(50) NOT NULL,
    comuna      VARCHAR2(50)
);


-- ############################################################################
-- TABLA PARAMETRICA
-- ############################################################################

CREATE TABLE meta_categoria (
    id_categoria NUMBER(4)    NOT NULL,
    anio         NUMBER(4)    NOT NULL,
    meta_q1      NUMBER(14,2) DEFAULT 0,
    meta_q2      NUMBER(14,2) DEFAULT 0,
    meta_q3      NUMBER(14,2) DEFAULT 0,
    meta_q4      NUMBER(14,2) DEFAULT 0
);


-- ############################################################################
-- TABLAS TRANSACCIONALES
-- ############################################################################

CREATE TABLE venta (
    id_venta    NUMBER(10)   NOT NULL,
    id_cliente  NUMBER(8)    NOT NULL,
    id_sucursal NUMBER(3)    NOT NULL,
    fecha_venta DATE         DEFAULT SYSDATE NOT NULL,
    total_neto  NUMBER(14,2) DEFAULT 0,
    total_iva   NUMBER(14,2) DEFAULT 0,
    total_bruto NUMBER(14,2) DEFAULT 0,
    estado      VARCHAR2(10) DEFAULT 'BORRADOR' NOT NULL
);

CREATE TABLE detalle_venta (
    id_venta        NUMBER(10)   NOT NULL,
    nro_linea       NUMBER(4)    NOT NULL,
    id_producto     NUMBER(8)    NOT NULL,
    cantidad        NUMBER(6)    NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    descuento_pct   NUMBER(5,2)  DEFAULT 0
);

CREATE TABLE movimiento_stock (
    id_movimiento   NUMBER(12)   NOT NULL,
    id_producto     NUMBER(8)    NOT NULL,
    tipo_movimiento VARCHAR2(10) NOT NULL,
    cantidad        NUMBER(8)    NOT NULL,
    fecha           DATE         DEFAULT SYSDATE NOT NULL,
    id_venta        NUMBER(10),
    observacion     VARCHAR2(200)
);


-- ############################################################################
-- TABLAS DE AUDITORIA Y BITACORA
-- ############################################################################

CREATE TABLE auditoria_precio (
    id_auditoria    NUMBER(12)   NOT NULL,
    id_producto     NUMBER(8)    NOT NULL,
    precio_anterior NUMBER(12,2),
    precio_nuevo    NUMBER(12,2),
    usuario_bd      VARCHAR2(40),
    fecha_cambio    TIMESTAMP    DEFAULT SYSTIMESTAMP
);

CREATE TABLE alerta_stock (
    id_alerta     NUMBER(12)   NOT NULL,
    id_producto   NUMBER(8)    NOT NULL,
    stock_actual  NUMBER(8),
    stock_critico NUMBER(8),
    fecha_alerta  DATE         DEFAULT SYSDATE,
    estado        VARCHAR2(10) DEFAULT 'PENDIENTE' NOT NULL
);

CREATE TABLE log_error (
    id_log       NUMBER(12)   NOT NULL,
    origen       VARCHAR2(60),
    codigo_error NUMBER,
    mensaje      VARCHAR2(4000),
    usuario_bd   VARCHAR2(40) DEFAULT USER,
    fecha        TIMESTAMP    DEFAULT SYSTIMESTAMP
);


-- ############################################################################
-- CLAVES PRIMARIAS
-- ############################################################################

ALTER TABLE categoria
    ADD CONSTRAINT pk_categoria PRIMARY KEY (id_categoria);

ALTER TABLE proveedor
    ADD CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor);

ALTER TABLE producto
    ADD CONSTRAINT pk_producto PRIMARY KEY (id_producto);

ALTER TABLE cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);

ALTER TABLE sucursal
    ADD CONSTRAINT pk_sucursal PRIMARY KEY (id_sucursal);

-- Clave primaria COMPUESTA: una categoria tiene una fila de metas por anio
ALTER TABLE meta_categoria
    ADD CONSTRAINT pk_meta_categoria PRIMARY KEY (id_categoria, anio);

ALTER TABLE venta
    ADD CONSTRAINT pk_venta PRIMARY KEY (id_venta);

-- Clave primaria COMPUESTA: entidad debil, la linea no existe sin su venta
ALTER TABLE detalle_venta
    ADD CONSTRAINT pk_detalle_venta PRIMARY KEY (id_venta, nro_linea);

ALTER TABLE movimiento_stock
    ADD CONSTRAINT pk_movimiento_stock PRIMARY KEY (id_movimiento);

ALTER TABLE auditoria_precio
    ADD CONSTRAINT pk_auditoria_precio PRIMARY KEY (id_auditoria);

ALTER TABLE alerta_stock
    ADD CONSTRAINT pk_alerta_stock PRIMARY KEY (id_alerta);

ALTER TABLE log_error
    ADD CONSTRAINT pk_log_error PRIMARY KEY (id_log);


-- ############################################################################
-- CLAVES UNICAS
-- ############################################################################

ALTER TABLE categoria
    ADD CONSTRAINT uq_categoria_nombre UNIQUE (nombre);

ALTER TABLE proveedor
    ADD CONSTRAINT uq_proveedor_rut UNIQUE (rut);

ALTER TABLE producto
    ADD CONSTRAINT uq_producto_sku UNIQUE (sku);

ALTER TABLE cliente
    ADD CONSTRAINT uq_cliente_rut UNIQUE (rut);


-- ############################################################################
-- CLAVES FORANEAS  (definen las relaciones del modelo)
-- ############################################################################

-- CATEGORIA 1 --- N PRODUCTO
ALTER TABLE producto
    ADD CONSTRAINT fk_producto_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria);

-- PROVEEDOR 1 --- N PRODUCTO
ALTER TABLE producto
    ADD CONSTRAINT fk_producto_proveedor
    FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor);

-- CATEGORIA 1 --- N META_CATEGORIA (identificadora: la FK es parte de la PK)
ALTER TABLE meta_categoria
    ADD CONSTRAINT fk_meta_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria);

-- CLIENTE 1 --- N VENTA
ALTER TABLE venta
    ADD CONSTRAINT fk_venta_cliente
    FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente);

-- SUCURSAL 1 --- N VENTA
ALTER TABLE venta
    ADD CONSTRAINT fk_venta_sucursal
    FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal);

-- VENTA 1 --- N DETALLE_VENTA (identificadora: la FK es parte de la PK)
ALTER TABLE detalle_venta
    ADD CONSTRAINT fk_detalle_venta
    FOREIGN KEY (id_venta) REFERENCES venta (id_venta);

-- PRODUCTO 1 --- N DETALLE_VENTA
-- DETALLE_VENTA resuelve la relacion N:M entre VENTA y PRODUCTO
ALTER TABLE detalle_venta
    ADD CONSTRAINT fk_detalle_producto
    FOREIGN KEY (id_producto) REFERENCES producto (id_producto);

-- PRODUCTO 1 --- N MOVIMIENTO_STOCK
ALTER TABLE movimiento_stock
    ADD CONSTRAINT fk_movimiento_producto
    FOREIGN KEY (id_producto) REFERENCES producto (id_producto);

-- VENTA 1 --- N MOVIMIENTO_STOCK (opcional: los ajustes no tienen venta)
ALTER TABLE movimiento_stock
    ADD CONSTRAINT fk_movimiento_venta
    FOREIGN KEY (id_venta) REFERENCES venta (id_venta);

-- PRODUCTO 1 --- N AUDITORIA_PRECIO
ALTER TABLE auditoria_precio
    ADD CONSTRAINT fk_auditoria_producto
    FOREIGN KEY (id_producto) REFERENCES producto (id_producto);

-- PRODUCTO 1 --- N ALERTA_STOCK
ALTER TABLE alerta_stock
    ADD CONSTRAINT fk_alerta_producto
    FOREIGN KEY (id_producto) REFERENCES producto (id_producto);

-- LOG_ERROR no tiene FK: es una bitacora tecnica independiente del modelo.


-- ############################################################################
-- RESTRICCIONES DE VALIDACION (CHECK)
-- ############################################################################

ALTER TABLE categoria
    ADD CONSTRAINT ck_categoria_activo CHECK (activo IN ('S','N'));

ALTER TABLE categoria
    ADD CONSTRAINT ck_categoria_margen CHECK (margen_referencia BETWEEN 0 AND 100);

ALTER TABLE producto
    ADD CONSTRAINT ck_producto_costo CHECK (costo_unitario >= 0);

ALTER TABLE producto
    ADD CONSTRAINT ck_producto_precio CHECK (precio_venta >= 0);

ALTER TABLE producto
    ADD CONSTRAINT ck_producto_stock CHECK (stock_actual >= 0);

ALTER TABLE producto
    ADD CONSTRAINT ck_producto_activo CHECK (activo IN ('S','N'));

ALTER TABLE cliente
    ADD CONSTRAINT ck_cliente_tipo
    CHECK (tipo_cliente IN ('NORMAL','PREFERENTE','EMPRESA'));

ALTER TABLE meta_categoria
    ADD CONSTRAINT ck_meta_anio CHECK (anio BETWEEN 2000 AND 2999);

ALTER TABLE venta
    ADD CONSTRAINT ck_venta_estado
    CHECK (estado IN ('BORRADOR','EMITIDA','ANULADA'));

ALTER TABLE detalle_venta
    ADD CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0);

ALTER TABLE detalle_venta
    ADD CONSTRAINT ck_detalle_precio CHECK (precio_unitario >= 0);

ALTER TABLE detalle_venta
    ADD CONSTRAINT ck_detalle_dcto CHECK (descuento_pct BETWEEN 0 AND 100);

ALTER TABLE movimiento_stock
    ADD CONSTRAINT ck_movimiento_tipo
    CHECK (tipo_movimiento IN ('ENTRADA','SALIDA','AJUSTE'));

ALTER TABLE alerta_stock
    ADD CONSTRAINT ck_alerta_estado
    CHECK (estado IN ('PENDIENTE','GESTIONADA'));


-- ############################################################################
-- INDICES DE APOYO AL PROCESAMIENTO PL/SQL
-- (el cursor c_productos filtra por categoria y cruza detalle_venta y venta)
-- ############################################################################

CREATE INDEX ix_producto_categoria ON producto (id_categoria);

CREATE INDEX ix_detalle_producto ON detalle_venta (id_producto);

CREATE INDEX ix_venta_fecha_estado ON venta (fecha_venta, estado);

CREATE INDEX ix_movimiento_prod ON movimiento_stock (id_producto, fecha);


-- ############################################################################
-- SECUENCIAS
-- ############################################################################

CREATE SEQUENCE seq_venta      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_movimiento START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_auditoria  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_alerta     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_log        START WITH 1 INCREMENT BY 1 NOCACHE;


-- ############################################################################
-- DOCUMENTACION DEL MODELO
-- Data Modeler importa estos textos como "Comentarios en RDBMS" y los sube
-- al modelo logico como definicion de la entidad y del atributo.
-- ############################################################################

COMMENT ON TABLE categoria         IS 'Clasificacion de productos (CPU, GPU, RAM). Nivel externo del recorrido del reporte.';
COMMENT ON TABLE proveedor         IS 'Origen de abastecimiento de cada producto.';
COMMENT ON TABLE producto          IS 'Catalogo de componentes y equipos, con costo, precio y niveles de stock.';
COMMENT ON TABLE cliente           IS 'Cliente final. El tipo determina el porcentaje de descuento aplicado.';
COMMENT ON TABLE sucursal          IS 'Punto de venta fisico o canal online.';
COMMENT ON TABLE meta_categoria    IS 'Metas de venta por categoria y anio, desglosadas en 4 trimestres. Se cargan en un VARRAY(4) en PL/SQL.';
COMMENT ON TABLE venta             IS 'Cabecera de la venta con totales y estado del documento.';
COMMENT ON TABLE detalle_venta     IS 'Lineas de la venta. Resuelve la relacion N:M entre VENTA y PRODUCTO.';
COMMENT ON TABLE movimiento_stock  IS 'Bitacora de entradas, salidas y ajustes de inventario.';
COMMENT ON TABLE auditoria_precio  IS 'Registro automatico de cambios de precio, alimentado por trigger.';
COMMENT ON TABLE alerta_stock      IS 'Alertas de reposicion generadas al cruzar el stock critico.';
COMMENT ON TABLE log_error         IS 'Bitacora de errores capturados por los manejadores de excepciones.';

COMMENT ON COLUMN producto.costo_unitario     IS 'Costo de adquisicion. Base del calculo de margen.';
COMMENT ON COLUMN producto.stock_actual       IS 'Dato derivado: lo mantienen sincronizado los triggers de movimiento.';
COMMENT ON COLUMN producto.stock_critico      IS 'Umbral bajo el cual se genera alerta de reposicion.';
COMMENT ON COLUMN cliente.tipo_cliente        IS 'NORMAL 0%, PREFERENTE 5%, EMPRESA 12% de descuento.';
COMMENT ON COLUMN venta.estado                IS 'BORRADOR en construccion, EMITIDA valida para reportes, ANULADA revierte stock.';
COMMENT ON COLUMN detalle_venta.descuento_pct IS 'Descuento de la linea segun el tipo de cliente al momento de la venta.';
COMMENT ON COLUMN movimiento_stock.id_venta   IS 'Nulo en entradas por compra y en ajustes de inventario.';
