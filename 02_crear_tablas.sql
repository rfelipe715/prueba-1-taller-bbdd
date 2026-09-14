-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 02_crear_tablas.sql
-- DDL: tablas, restricciones, secuencias e indices.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- MAESTROS
-- ----------------------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria      NUMBER(4)     PRIMARY KEY,
    nombre            VARCHAR2(50)  NOT NULL,
    margen_referencia NUMBER(5,2)   DEFAULT 0,
    activo            CHAR(1)       DEFAULT 'S',
    CONSTRAINT uq_categoria_nombre UNIQUE (nombre),
    CONSTRAINT ck_categoria_activo CHECK (activo IN ('S','N')),
    CONSTRAINT ck_categoria_margen CHECK (margen_referencia BETWEEN 0 AND 100)
);

CREATE TABLE proveedor (
    id_proveedor NUMBER(5)    PRIMARY KEY,
    rut          VARCHAR2(12) NOT NULL,
    nombre       VARCHAR2(80) NOT NULL,
    pais         VARCHAR2(40) DEFAULT 'Chile',
    email        VARCHAR2(80),
    CONSTRAINT uq_proveedor_rut UNIQUE (rut)
);

CREATE TABLE producto (
    id_producto    NUMBER(8)     PRIMARY KEY,
    sku            VARCHAR2(30)  NOT NULL,
    nombre         VARCHAR2(120) NOT NULL,
    id_categoria   NUMBER(4)     NOT NULL,
    id_proveedor   NUMBER(5)     NOT NULL,
    costo_unitario NUMBER(12,2)  NOT NULL,
    precio_venta   NUMBER(12,2)  NOT NULL,
    stock_actual   NUMBER(8)     DEFAULT 0,
    stock_critico  NUMBER(8)     DEFAULT 5,
    activo         CHAR(1)       DEFAULT 'S',
    CONSTRAINT uq_producto_sku   UNIQUE (sku),
    CONSTRAINT ck_producto_costo  CHECK (costo_unitario >= 0),
    CONSTRAINT ck_producto_precio CHECK (precio_venta   >= 0),
    CONSTRAINT ck_producto_stock  CHECK (stock_actual   >= 0),
    CONSTRAINT ck_producto_activo CHECK (activo IN ('S','N')),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria(id_categoria),
    CONSTRAINT fk_producto_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor(id_proveedor)
);

CREATE TABLE cliente (
    id_cliente     NUMBER(8)     PRIMARY KEY,
    rut            VARCHAR2(12)  NOT NULL,
    nombre         VARCHAR2(100) NOT NULL,
    email          VARCHAR2(80),
    tipo_cliente   VARCHAR2(12)  DEFAULT 'NORMAL',
    fecha_registro DATE          DEFAULT SYSDATE,
    CONSTRAINT uq_cliente_rut UNIQUE (rut),
    CONSTRAINT ck_cliente_tipo
        CHECK (tipo_cliente IN ('NORMAL','PREFERENTE','EMPRESA'))
);

CREATE TABLE sucursal (
    id_sucursal NUMBER(3)    PRIMARY KEY,
    nombre      VARCHAR2(50) NOT NULL,
    comuna      VARCHAR2(50)
);

-- ----------------------------------------------------------------------------
-- PARAMETRICAS
-- ----------------------------------------------------------------------------
CREATE TABLE meta_categoria (
    id_categoria NUMBER(4)    NOT NULL,
    anio         NUMBER(4)    NOT NULL,
    meta_q1      NUMBER(14,2) DEFAULT 0,
    meta_q2      NUMBER(14,2) DEFAULT 0,
    meta_q3      NUMBER(14,2) DEFAULT 0,
    meta_q4      NUMBER(14,2) DEFAULT 0,
    CONSTRAINT pk_meta_categoria PRIMARY KEY (id_categoria, anio),
    CONSTRAINT fk_meta_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria(id_categoria),
    CONSTRAINT ck_meta_anio CHECK (anio BETWEEN 2000 AND 2999)
);

-- ----------------------------------------------------------------------------
-- TRANSACCIONALES
-- ----------------------------------------------------------------------------
CREATE TABLE venta (
    id_venta    NUMBER(10)   PRIMARY KEY,
    id_cliente  NUMBER(8)    NOT NULL,
    id_sucursal NUMBER(3)    NOT NULL,
    fecha_venta DATE         DEFAULT SYSDATE NOT NULL,
    total_neto  NUMBER(14,2) DEFAULT 0,
    total_iva   NUMBER(14,2) DEFAULT 0,
    total_bruto NUMBER(14,2) DEFAULT 0,
    estado      VARCHAR2(10) DEFAULT 'BORRADOR',
    CONSTRAINT ck_venta_estado
        CHECK (estado IN ('BORRADOR','EMITIDA','ANULADA')),
    CONSTRAINT fk_venta_cliente  FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente),
    CONSTRAINT fk_venta_sucursal FOREIGN KEY (id_sucursal)
        REFERENCES sucursal(id_sucursal)
);

CREATE TABLE detalle_venta (
    id_venta        NUMBER(10)   NOT NULL,
    nro_linea       NUMBER(4)    NOT NULL,
    id_producto     NUMBER(8)    NOT NULL,
    cantidad        NUMBER(6)    NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    descuento_pct   NUMBER(5,2)  DEFAULT 0,
    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_venta, nro_linea),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detalle_dcto     CHECK (descuento_pct BETWEEN 0 AND 100),
    CONSTRAINT fk_detalle_venta    FOREIGN KEY (id_venta)
        REFERENCES venta(id_venta),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
);

CREATE TABLE movimiento_stock (
    id_movimiento   NUMBER(12)   PRIMARY KEY,
    id_producto     NUMBER(8)    NOT NULL,
    tipo_movimiento VARCHAR2(10) NOT NULL,
    cantidad        NUMBER(8)    NOT NULL,
    fecha           DATE         DEFAULT SYSDATE,
    id_venta        NUMBER(10),
    observacion     VARCHAR2(200),
    CONSTRAINT ck_movimiento_tipo
        CHECK (tipo_movimiento IN ('ENTRADA','SALIDA','AJUSTE')),
    CONSTRAINT fk_movimiento_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
);

-- ----------------------------------------------------------------------------
-- AUDITORIA Y BITACORAS
-- ----------------------------------------------------------------------------
CREATE TABLE auditoria_precio (
    id_auditoria    NUMBER(12)   PRIMARY KEY,
    id_producto     NUMBER(8)    NOT NULL,
    precio_anterior NUMBER(12,2),
    precio_nuevo    NUMBER(12,2),
    usuario_bd      VARCHAR2(40),
    fecha_cambio    TIMESTAMP    DEFAULT SYSTIMESTAMP
);

CREATE TABLE alerta_stock (
    id_alerta     NUMBER(12)   PRIMARY KEY,
    id_producto   NUMBER(8)    NOT NULL,
    stock_actual  NUMBER(8),
    stock_critico NUMBER(8),
    fecha_alerta  DATE         DEFAULT SYSDATE,
    estado        VARCHAR2(10) DEFAULT 'PENDIENTE',
    CONSTRAINT ck_alerta_estado CHECK (estado IN ('PENDIENTE','GESTIONADA'))
);

CREATE TABLE log_error (
    id_log       NUMBER(12)    PRIMARY KEY,
    origen       VARCHAR2(60),
    codigo_error NUMBER,
    mensaje      VARCHAR2(4000),
    usuario_bd   VARCHAR2(40)  DEFAULT USER,
    fecha        TIMESTAMP     DEFAULT SYSTIMESTAMP
);

-- ----------------------------------------------------------------------------
-- SECUENCIAS
-- ----------------------------------------------------------------------------
CREATE SEQUENCE seq_venta      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_movimiento START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_auditoria  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_alerta     START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_log        START WITH 1 INCREMENT BY 1 NOCACHE;

-- ----------------------------------------------------------------------------
-- INDICES DE APOYO AL PROCESAMIENTO
-- (el cursor c_productos filtra por categoria y cruza detalle_venta y venta)
-- ----------------------------------------------------------------------------
CREATE INDEX ix_producto_categoria ON producto(id_categoria);
CREATE INDEX ix_detalle_producto   ON detalle_venta(id_producto);
CREATE INDEX ix_venta_fecha_estado ON venta(fecha_venta, estado);
CREATE INDEX ix_movimiento_prod    ON movimiento_stock(id_producto, fecha);

-- ----------------------------------------------------------------------------
-- COMENTARIOS
-- ----------------------------------------------------------------------------
COMMENT ON TABLE  meta_categoria           IS 'Metas de venta por categoria y anio, desglosadas en 4 trimestres (se cargan en un VARRAY(4))';
COMMENT ON COLUMN producto.stock_critico   IS 'Umbral bajo el cual se genera alerta de reposicion';
COMMENT ON COLUMN detalle_venta.descuento_pct IS 'Descuento aplicado segun tipo de cliente';

PROMPT Tablas, secuencias e indices creados.
