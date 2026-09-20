-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 03_poblar_datos.sql
-- Poblacion de datos de prueba.
--
-- IMPORTANTE: este script se ejecuta ANTES de crear los triggers (script 06).
-- Asi la carga historica no dispara el descuento automatico de stock: los
-- movimientos de SALIDA y el stock final se derivan aqui de forma explicita.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- SUCURSALES
-- ----------------------------------------------------------------------------
INSERT INTO sucursal VALUES (1, 'TecnoParts Providencia', 'Providencia');
INSERT INTO sucursal VALUES (2, 'TecnoParts Maipu',       'Maipu');
INSERT INTO sucursal VALUES (3, 'TecnoParts Vina',        'Vina del Mar');
INSERT INTO sucursal VALUES (4, 'Canal Online',           'E-commerce');

-- ----------------------------------------------------------------------------
-- PROVEEDORES
-- ----------------------------------------------------------------------------
INSERT INTO proveedor VALUES (1, '76.123.456-7', 'Distribuidora Andes Tech',  'Chile',  'ventas@andestech.cl');
INSERT INTO proveedor VALUES (2, '77.234.567-8', 'ImportaPC Ltda',            'Chile',  'contacto@importapc.cl');
INSERT INTO proveedor VALUES (3, '78.345.678-9', 'Pacific Components SpA',    'Chile',  'ordenes@pacificcomp.cl');
INSERT INTO proveedor VALUES (4, '79.456.789-0', 'Global Hardware Import',    'China',  'sales@globalhw.com');
INSERT INTO proveedor VALUES (5, '80.567.890-1', 'Nortec Distribucion',       'Chile',  'nortec@nortec.cl');
INSERT INTO proveedor VALUES (6, '81.678.901-2', 'Silicon Supply Co',         'Taiwan', 'orders@siliconsupply.tw');

-- ----------------------------------------------------------------------------
-- CATEGORIAS
-- La categoria 9 (Refrigeracion) queda A PROPOSITO sin meta cargada, para
-- ejercitar la excepcion de usuario e_meta_no_definida en el reporte.
-- ----------------------------------------------------------------------------
INSERT INTO categoria VALUES (1, 'Procesadores',       30, 'S');
INSERT INTO categoria VALUES (2, 'Tarjetas Graficas',  22, 'S');
INSERT INTO categoria VALUES (3, 'Placas Madre',       28, 'S');
INSERT INTO categoria VALUES (4, 'Memorias RAM',       32, 'S');
INSERT INTO categoria VALUES (5, 'Almacenamiento',     35, 'S');
INSERT INTO categoria VALUES (6, 'Fuentes de Poder',   31, 'S');
INSERT INTO categoria VALUES (7, 'Gabinetes',          35, 'S');
INSERT INTO categoria VALUES (8, 'Perifericos',        45, 'S');
INSERT INTO categoria VALUES (9, 'Refrigeracion',      38, 'S');
INSERT INTO categoria VALUES (10,'Cables y Adaptadores', 55, 'N');  -- inactiva

-- ----------------------------------------------------------------------------
-- PRODUCTOS  (stock_actual = stock INICIAL; se descuenta al final del script)
-- ----------------------------------------------------------------------------
-- Procesadores
INSERT INTO producto VALUES (101,'CPU-R5-5600',    'AMD Ryzen 5 5600 6-Core',          1,1,  95000, 139990, 25,  5,'S');
INSERT INTO producto VALUES (102,'CPU-R7-5800X',   'AMD Ryzen 7 5800X 8-Core',         1,1, 155000, 219990, 12,  4,'S');
INSERT INTO producto VALUES (103,'CPU-I5-12400F',  'Intel Core i5-12400F',             1,2, 105000, 149990, 18,  5,'S');
INSERT INTO producto VALUES (104,'CPU-I7-13700K',  'Intel Core i7-13700K',             1,2, 290000, 399990,  6,  3,'S');
-- Tarjetas Graficas
INSERT INTO producto VALUES (201,'GPU-RTX4060',    'NVIDIA GeForce RTX 4060 8GB',      2,3, 320000, 429990, 10,  3,'S');
INSERT INTO producto VALUES (202,'GPU-RTX4070',    'NVIDIA GeForce RTX 4070 12GB',     2,3, 520000, 689990,  5,  2,'S');
INSERT INTO producto VALUES (203,'GPU-RX7600',     'AMD Radeon RX 7600 8GB',           2,4, 270000, 359990,  8,  3,'S');
INSERT INTO producto VALUES (204,'GPU-GTX1650',    'NVIDIA GeForce GTX 1650 4GB',      2,4, 150000, 199990, 14,  4,'S');
-- Placas Madre
INSERT INTO producto VALUES (301,'MB-B550M',       'Placa Madre B550M AM4',            3,1,  68000,  99990, 20,  5,'S');
INSERT INTO producto VALUES (302,'MB-B660M',       'Placa Madre B660M LGA1700',        3,2,  72000, 104990, 15,  5,'S');
INSERT INTO producto VALUES (303,'MB-X670E',       'Placa Madre X670E AM5 ATX',        3,1, 230000, 319990,  4,  2,'S');
-- Memorias RAM
INSERT INTO producto VALUES (401,'RAM-16GB-3200',  'Memoria DDR4 16GB 3200MHz',        4,5,  32000,  49990, 40, 10,'S');
INSERT INTO producto VALUES (402,'RAM-32GB-3600',  'Memoria DDR4 32GB 3600MHz Kit',    4,5,  68000,  99990, 22,  8,'S');
INSERT INTO producto VALUES (403,'RAM-8GB-2666',   'Memoria DDR4 8GB 2666MHz',         4,5,  17000,  27990, 35, 10,'S');
-- Almacenamiento
INSERT INTO producto VALUES (501,'SSD-NVME-1TB',   'SSD NVMe M.2 1TB Gen4',            5,6,  48000,  74990, 30,  8,'S');
INSERT INTO producto VALUES (502,'SSD-SATA-480',   'SSD SATA 2.5 480GB',               5,6,  21000,  32990, 45, 10,'S');
INSERT INTO producto VALUES (503,'HDD-2TB',        'Disco Duro 2TB 7200rpm',           5,4,  38000,  59990, 18,  6,'S');
INSERT INTO producto VALUES (504,'SSD-NVME-2TB',   'SSD NVMe M.2 2TB Gen4',            5,6,  95000, 139990,  9,  4,'S');
-- Fuentes de Poder
INSERT INTO producto VALUES (601,'PSU-600W-80B',   'Fuente 600W 80 Plus Bronze',       6,3,  34000,  52990, 26,  8,'S');
INSERT INTO producto VALUES (602,'PSU-750W-80G',   'Fuente 750W 80 Plus Gold',         6,3,  62000,  89990, 14,  5,'S');
INSERT INTO producto VALUES (603,'PSU-850W-80G',   'Fuente 850W 80 Plus Gold Modular', 6,3,  82000, 119990,  7,  3,'S');
-- Gabinetes
INSERT INTO producto VALUES (701,'CASE-ATX-RGB',   'Gabinete ATX RGB 4 ventiladores',  7,4,  29000,  45990, 20,  6,'S');
INSERT INTO producto VALUES (702,'CASE-MATX-BLK',  'Gabinete Micro-ATX Negro',         7,4,  19000,  29990, 25,  8,'S');
INSERT INTO producto VALUES (703,'CASE-ATX-VIDRIO','Gabinete ATX Vidrio Templado',     7,4,  42000,  64990, 10,  4,'S');
-- Perifericos
INSERT INTO producto VALUES (801,'TEC-MEC-RGB',    'Teclado Mecanico RGB Switch Red',  8,5,  22000,  36990, 30, 10,'S');
INSERT INTO producto VALUES (802,'MOUSE-GAMER',    'Mouse Gamer 12000 DPI',            8,5,   9000,  16990, 50, 15,'S');
INSERT INTO producto VALUES (803,'AUDIF-7.1',      'Audifonos Gamer 7.1 USB',          8,5,  18000,  29990, 28, 10,'S');
INSERT INTO producto VALUES (804,'MONITOR-24-144', 'Monitor 24 pulgadas 144Hz IPS',    8,2,  98000, 149990, 12,  4,'S');
INSERT INTO producto VALUES (805,'CABLE-HDMI-2M',  'Cable HDMI 2.1 de 2 metros',       8,5,   1800,   4990,120, 30,'S');
-- Refrigeracion (categoria sin meta cargada)
INSERT INTO producto VALUES (901,'COOLER-AIR-120', 'Cooler CPU Aire 120mm',            9,3,  18000,  29990, 18,  6,'S');
INSERT INTO producto VALUES (902,'AIO-240-RGB',    'Refrigeracion Liquida AIO 240 RGB',9,3,  62000,  94990,  8,  3,'S');

-- ----------------------------------------------------------------------------
-- CLIENTES
-- ----------------------------------------------------------------------------
INSERT INTO cliente VALUES ( 1,'11.111.111-1','Rodrigo Fuentes Silva',  'rfuentes@mail.cl',  'NORMAL',     SYSDATE-800);
INSERT INTO cliente VALUES ( 2,'12.222.222-2','Camila Rojas Perez',     'crojas@mail.cl',    'PREFERENTE', SYSDATE-720);
INSERT INTO cliente VALUES ( 3,'76.900.100-3','Soluciones TI SpA',      'compras@solti.cl',  'EMPRESA',    SYSDATE-650);
INSERT INTO cliente VALUES ( 4,'13.444.444-4','Matias Herrera Lopez',   'mherrera@mail.cl',  'NORMAL',     SYSDATE-600);
INSERT INTO cliente VALUES ( 5,'14.555.555-5','Valentina Munoz Diaz',   'vmunoz@mail.cl',    'NORMAL',     SYSDATE-540);
INSERT INTO cliente VALUES ( 6,'15.666.666-6','Ignacio Torres Vega',    'itorres@mail.cl',   'PREFERENTE', SYSDATE-480);
INSERT INTO cliente VALUES ( 7,'77.800.200-7','Colegio San Pedro',      'ti@sanpedro.cl',    'EMPRESA',    SYSDATE-420);
INSERT INTO cliente VALUES ( 8,'16.888.888-8','Francisca Soto Ramirez', 'fsoto@mail.cl',     'NORMAL',     SYSDATE-360);
INSERT INTO cliente VALUES ( 9,'17.999.999-9','Sebastian Castro Pino',  'scastro@mail.cl',   'PREFERENTE', SYSDATE-300);
INSERT INTO cliente VALUES (10,'18.101.010-0','Antonia Guzman Reyes',   'aguzman@mail.cl',   'NORMAL',     SYSDATE-240);
INSERT INTO cliente VALUES (11,'78.700.300-5','Estudio Contable Norte', 'admin@ecnorte.cl',  'EMPRESA',    SYSDATE-180);
INSERT INTO cliente VALUES (12,'19.121.212-1','Diego Alarcon Moya',     'dalarcon@mail.cl',  'NORMAL',     SYSDATE-90);

-- ----------------------------------------------------------------------------
-- METAS POR CATEGORIA (anio en curso)
-- La categoria 9 no tiene fila  -> excepcion e_meta_no_definida
-- La categoria 7 tiene metas en 0 -> excepcion e_meta_en_cero
-- ----------------------------------------------------------------------------
INSERT INTO meta_categoria VALUES (1, EXTRACT(YEAR FROM SYSDATE), 2500000, 2500000, 2800000, 3200000);
INSERT INTO meta_categoria VALUES (2, EXTRACT(YEAR FROM SYSDATE), 4000000, 4000000, 4500000, 5000000);
INSERT INTO meta_categoria VALUES (3, EXTRACT(YEAR FROM SYSDATE), 1200000, 1200000, 1300000, 1500000);
INSERT INTO meta_categoria VALUES (4, EXTRACT(YEAR FROM SYSDATE),  900000,  900000, 1000000, 1200000);
INSERT INTO meta_categoria VALUES (5, EXTRACT(YEAR FROM SYSDATE), 1500000, 1500000, 1600000, 1900000);
INSERT INTO meta_categoria VALUES (6, EXTRACT(YEAR FROM SYSDATE),  700000,  700000,  750000,  900000);
INSERT INTO meta_categoria VALUES (7, EXTRACT(YEAR FROM SYSDATE),       0,       0,       0,       0);
INSERT INTO meta_categoria VALUES (8, EXTRACT(YEAR FROM SYSDATE),  800000,  800000,  850000, 1100000);

-- ----------------------------------------------------------------------------
-- VENTAS DEL TRIMESTRE EN CURSO
-- GREATEST(TRUNC(SYSDATE,'Q'), SYSDATE-n) garantiza que la fecha caiga dentro
-- del trimestre actual sin quedar en el futuro, sea cual sea el dia de ejecucion.
-- ----------------------------------------------------------------------------
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 1, 1,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-40),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 2, 2,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-35),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 3, 3,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-33),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 4, 4,2,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-30),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 5, 5,3,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-28),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 6, 6,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-25),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 7, 7,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-22),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 8, 8,2,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-20),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES ( 9, 9,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-18),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (10,10,3,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-15),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (11,11,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-12),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (12,12,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE-10),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (13, 1,2,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 8),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (14, 3,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 6),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (15, 5,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 5),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (16, 7,3,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 4),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (17, 9,4,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 3),'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (18, 2,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 1),'EMITIDA');
-- Trimestre anterior (no debe aparecer en el reporte del trimestre en curso)
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (19, 4,1,TRUNC(SYSDATE,'Q')-20,'EMITIDA');
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (20, 6,4,TRUNC(SYSDATE,'Q')-18,'EMITIDA');
-- Venta ANULADA (el cursor del reporte filtra estado = 'EMITIDA')
INSERT INTO venta (id_venta,id_cliente,id_sucursal,fecha_venta,estado) VALUES (21,10,1,GREATEST(TRUNC(SYSDATE,'Q'),SYSDATE- 2),'ANULADA');

-- ----------------------------------------------------------------------------
-- DETALLE DE VENTAS
-- descuento_pct: NORMAL 0 | PREFERENTE 5 | EMPRESA 12
-- ----------------------------------------------------------------------------
INSERT INTO detalle_venta VALUES ( 1,1,101,1,139990, 0);
INSERT INTO detalle_venta VALUES ( 1,2,301,1, 99990, 0);
INSERT INTO detalle_venta VALUES ( 1,3,401,2, 49990, 0);
INSERT INTO detalle_venta VALUES ( 2,1,201,1,429990, 5);
INSERT INTO detalle_venta VALUES ( 2,2,602,1, 89990, 5);
INSERT INTO detalle_venta VALUES ( 3,1,103,3,149990,12);
INSERT INTO detalle_venta VALUES ( 3,2,302,3,104990,12);
INSERT INTO detalle_venta VALUES ( 3,3,501,3, 74990,12);
INSERT INTO detalle_venta VALUES ( 4,1,802,2, 16990, 0);
INSERT INTO detalle_venta VALUES ( 4,2,801,1, 36990, 0);
INSERT INTO detalle_venta VALUES ( 4,3,805,3,  4990, 0);
INSERT INTO detalle_venta VALUES ( 5,1,204,1,199990, 0);
INSERT INTO detalle_venta VALUES ( 5,2,601,1, 52990, 0);
INSERT INTO detalle_venta VALUES ( 6,1,202,1,689990, 5);
INSERT INTO detalle_venta VALUES ( 6,2,303,1,319990, 5);
INSERT INTO detalle_venta VALUES ( 6,3,402,2, 99990, 5);
INSERT INTO detalle_venta VALUES ( 7,1,502,5, 32990,12);
INSERT INTO detalle_venta VALUES ( 7,2,503,2, 59990,12);
INSERT INTO detalle_venta VALUES ( 8,1,701,1, 45990, 0);
INSERT INTO detalle_venta VALUES ( 8,2,601,1, 52990, 0);
INSERT INTO detalle_venta VALUES ( 8,3,403,2, 27990, 0);
INSERT INTO detalle_venta VALUES ( 9,1,104,1,399990, 5);
INSERT INTO detalle_venta VALUES ( 9,2,603,1,119990, 5);
INSERT INTO detalle_venta VALUES (10,1,804,1,149990, 0);
INSERT INTO detalle_venta VALUES (10,2,803,1, 29990, 0);
INSERT INTO detalle_venta VALUES (11,1,501,4, 74990,12);
INSERT INTO detalle_venta VALUES (11,2,401,6, 49990,12);
INSERT INTO detalle_venta VALUES (11,3,805,10, 4990,12);
INSERT INTO detalle_venta VALUES (12,1,203,1,359990, 0);
INSERT INTO detalle_venta VALUES (12,2,702,1, 29990, 0);
INSERT INTO detalle_venta VALUES (13,1,102,1,219990, 0);
INSERT INTO detalle_venta VALUES (13,2,402,1, 99990, 0);
INSERT INTO detalle_venta VALUES (14,1,302,2,104990,12);
INSERT INTO detalle_venta VALUES (14,2,103,2,149990,12);
INSERT INTO detalle_venta VALUES (15,1,504,1,139990, 0);
INSERT INTO detalle_venta VALUES (15,2,703,1, 64990, 0);
INSERT INTO detalle_venta VALUES (16,1,801,4, 36990,12);
INSERT INTO detalle_venta VALUES (16,2,802,4, 16990,12);
INSERT INTO detalle_venta VALUES (17,1,201,1,429990, 5);
INSERT INTO detalle_venta VALUES (17,2,602,1, 89990, 5);
INSERT INTO detalle_venta VALUES (17,3,701,1, 45990, 5);
INSERT INTO detalle_venta VALUES (18,1,901,1, 29990, 5);
INSERT INTO detalle_venta VALUES (18,2,902,1, 94990, 5);
-- Trimestre anterior
INSERT INTO detalle_venta VALUES (19,1,101,1,139990, 0);
INSERT INTO detalle_venta VALUES (19,2,201,1,429990, 0);
INSERT INTO detalle_venta VALUES (20,1,501,2, 74990, 5);
-- Venta anulada
INSERT INTO detalle_venta VALUES (21,1,202,1,689990, 0);

-- ----------------------------------------------------------------------------
-- TOTALES DE CABECERA (neto, IVA 19% y bruto) calculados desde el detalle
-- ----------------------------------------------------------------------------
UPDATE venta v
   SET total_neto  = (SELECT ROUND(NVL(SUM(d.cantidad * d.precio_unitario
                                    * (1 - d.descuento_pct/100)),0))
                        FROM detalle_venta d WHERE d.id_venta = v.id_venta),
       total_iva   = (SELECT ROUND(NVL(SUM(d.cantidad * d.precio_unitario
                                    * (1 - d.descuento_pct/100)),0) * 0.19)
                        FROM detalle_venta d WHERE d.id_venta = v.id_venta),
       total_bruto = (SELECT ROUND(NVL(SUM(d.cantidad * d.precio_unitario
                                    * (1 - d.descuento_pct/100)),0) * 1.19)
                        FROM detalle_venta d WHERE d.id_venta = v.id_venta);

-- ----------------------------------------------------------------------------
-- MOVIMIENTOS DE STOCK
-- 1) ENTRADA inicial: la compra que dejo el stock inicial de cada producto
-- ----------------------------------------------------------------------------
INSERT INTO movimiento_stock (id_movimiento, id_producto, tipo_movimiento,
                              cantidad, fecha, id_venta, observacion)
SELECT seq_movimiento.NEXTVAL, p.id_producto, 'ENTRADA', p.stock_actual,
       TRUNC(SYSDATE,'Q') - 30, NULL, 'Compra inicial a proveedor'
  FROM producto p
 WHERE p.stock_actual > 0;

-- 2) SALIDA: derivada del detalle de las ventas EMITIDAS
INSERT INTO movimiento_stock (id_movimiento, id_producto, tipo_movimiento,
                              cantidad, fecha, id_venta, observacion)
SELECT seq_movimiento.NEXTVAL, d.id_producto, 'SALIDA', d.cantidad,
       v.fecha_venta, v.id_venta, 'Venta linea ' || d.nro_linea
  FROM detalle_venta d
  JOIN venta v ON v.id_venta = d.id_venta
 WHERE v.estado = 'EMITIDA';

-- 3) AJUSTE por merma (dos casos, para que el nivel 3 del reporte tenga variedad)
INSERT INTO movimiento_stock (id_movimiento, id_producto, tipo_movimiento,
                              cantidad, fecha, id_venta, observacion)
VALUES (seq_movimiento.NEXTVAL, 805, 'AJUSTE', 2,
        GREATEST(TRUNC(SYSDATE,'Q'), SYSDATE-7), NULL, 'Merma por dano en bodega');
INSERT INTO movimiento_stock (id_movimiento, id_producto, tipo_movimiento,
                              cantidad, fecha, id_venta, observacion)
VALUES (seq_movimiento.NEXTVAL, 502, 'AJUSTE', 1,
        GREATEST(TRUNC(SYSDATE,'Q'), SYSDATE-9), NULL, 'Unidad fallada devuelta a proveedor');

-- ----------------------------------------------------------------------------
-- STOCK FINAL: se descuenta lo vendido del stock inicial
-- (los triggers aun no existen, por eso se hace de forma explicita aqui)
-- ----------------------------------------------------------------------------
UPDATE producto p
   SET p.stock_actual = p.stock_actual -
       NVL((SELECT SUM(d.cantidad)
              FROM detalle_venta d
              JOIN venta v ON v.id_venta = d.id_venta
             WHERE d.id_producto = p.id_producto
               AND v.estado = 'EMITIDA'), 0);

-- ----------------------------------------------------------------------------
-- SINCRONIZACION DE SECUENCIAS con los IDs cargados manualmente
-- ----------------------------------------------------------------------------
DECLARE
    v_next NUMBER;
BEGIN
    SELECT NVL(MAX(id_venta),0) + 1 INTO v_next FROM venta;
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_venta';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_venta START WITH ' || v_next ||
                      ' INCREMENT BY 1 NOCACHE';
END;
/

COMMIT;

-- ----------------------------------------------------------------------------
-- VERIFICACION RAPIDA
-- ----------------------------------------------------------------------------
PROMPT ==== Resumen de la carga ====
SELECT 'categoria'     AS tabla, COUNT(*) AS filas FROM categoria
UNION ALL SELECT 'proveedor',        COUNT(*) FROM proveedor
UNION ALL SELECT 'producto',         COUNT(*) FROM producto
UNION ALL SELECT 'cliente',          COUNT(*) FROM cliente
UNION ALL SELECT 'sucursal',         COUNT(*) FROM sucursal
UNION ALL SELECT 'meta_categoria',   COUNT(*) FROM meta_categoria
UNION ALL SELECT 'venta',            COUNT(*) FROM venta
UNION ALL SELECT 'detalle_venta',    COUNT(*) FROM detalle_venta
UNION ALL SELECT 'movimiento_stock', COUNT(*) FROM movimiento_stock;

PROMPT ==== Productos bajo stock critico ====
SELECT sku, nombre, stock_actual, stock_critico
  FROM producto
 WHERE stock_actual <= stock_critico
 ORDER BY sku;
