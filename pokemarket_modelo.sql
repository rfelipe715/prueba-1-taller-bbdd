/* ============================================================
   PokeMarket - Modelo de datos y desarrollo PL/SQL
   BDY1103 - Taller de Base de Datos - Evaluacion Parcial N1
   ============================================================ */


/* ------------------------------------------------------------
   1. MODELO DE DATOS (DDL)
   ------------------------------------------------------------ */

CREATE TABLE roles (
  id_rol      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre_rol  VARCHAR2(30) NOT NULL
);

CREATE TABLE usuarios (
  id_usuario      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre          VARCHAR2(100) NOT NULL,
  email           VARCHAR2(100) UNIQUE NOT NULL,
  id_rol          NUMBER NOT NULL,
  fecha_registro  DATE DEFAULT SYSDATE,
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
);

CREATE TABLE colecciones (
  id_coleccion      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre            VARCHAR2(60) NOT NULL,
  anio_lanzamiento  NUMBER(4)
);

CREATE TABLE cartas (
  id_carta      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre        VARCHAR2(100) NOT NULL,
  id_coleccion  NUMBER NOT NULL,
  rareza        VARCHAR2(30),
  tipo_pokemon  VARCHAR2(30),
  precio        NUMBER(10,2) NOT NULL,
  stock         NUMBER DEFAULT 0,
  CONSTRAINT fk_carta_coleccion FOREIGN KEY (id_coleccion) REFERENCES colecciones(id_coleccion)
);

CREATE TABLE pedidos (
  id_pedido     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario    NUMBER NOT NULL,
  fecha_pedido  DATE DEFAULT SYSDATE,
  estado        VARCHAR2(20) DEFAULT 'PENDIENTE',
  total         NUMBER(10,2) DEFAULT 0,
  CONSTRAINT fk_pedido_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE detalle_pedido (
  id_detalle       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_pedido        NUMBER NOT NULL,
  id_carta         NUMBER NOT NULL,
  cantidad         NUMBER NOT NULL,
  precio_unitario  NUMBER(10,2) NOT NULL,
  CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
  CONSTRAINT fk_detalle_carta  FOREIGN KEY (id_carta)  REFERENCES cartas(id_carta)
);

CREATE TABLE auditoria_precios (
  id_auditoria     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_carta         NUMBER,
  precio_anterior  NUMBER(10,2),
  precio_nuevo     NUMBER(10,2),
  fecha_cambio     DATE DEFAULT SYSDATE,
  usuario_bd       VARCHAR2(30)
);


/* ------------------------------------------------------------
   2. DATOS DE PRUEBA
   ------------------------------------------------------------ */

INSERT INTO roles (nombre_rol) VALUES ('Administrador');
INSERT INTO roles (nombre_rol) VALUES ('Vendedor');
INSERT INTO roles (nombre_rol) VALUES ('Cliente');

INSERT INTO usuarios (nombre, email, id_rol) VALUES ('Ana Reyes', 'ana@pokemarket.cl', 1);
INSERT INTO usuarios (nombre, email, id_rol) VALUES ('Bruno Soto', 'bruno@pokemarket.cl', 2);
INSERT INTO usuarios (nombre, email, id_rol) VALUES ('Camila Diaz', 'camila@pokemarket.cl', 3);
INSERT INTO usuarios (nombre, email, id_rol) VALUES ('Diego Paz', 'diego@pokemarket.cl', 3);

INSERT INTO colecciones (nombre, anio_lanzamiento) VALUES ('Base Set', 1999);
INSERT INTO colecciones (nombre, anio_lanzamiento) VALUES ('Jungla', 1999);
INSERT INTO colecciones (nombre, anio_lanzamiento) VALUES ('Escarlata y Purpura', 2023);

INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Charizard', 1, 'Rara Holo', 'Fuego', 150000, 3);
INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Blastoise', 1, 'Rara Holo', 'Agua', 90000, 5);
INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Pikachu', 1, 'Comun', 'Electrico', 8000, 40);
INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Vileplume', 2, 'Rara', 'Planta', 25000, 10);
INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Scyther', 2, 'Rara', 'Bicho', 30000, 8);
INSERT INTO cartas (nombre, id_coleccion, rareza, tipo_pokemon, precio, stock) VALUES ('Koraidon', 3, 'Ultra Rara', 'Dragon', 45000, 12);

COMMIT;


/* ============================================================
   3. BLOQUES PL/SQL ANONIMOS
   (letras c, d, e del encargo: RECORD/VARRAY, cursores y
   loops anidados, manejo de excepciones)
   ============================================================ */

/* --- Bloque 1: RECORD + VARRAY + cursor con parametro ------- */
SET SERVEROUTPUT ON;

DECLARE
  -- RECORD personalizado para representar la info relevante de una carta
  TYPE carta_info_rec IS RECORD (
    nombre  cartas.nombre%TYPE,
    precio  cartas.precio%TYPE,
    stock   cartas.stock%TYPE
  );
  v_carta carta_info_rec;

  -- VARRAY de tamano fijo: simula un "carrito" con hasta 5 cartas
  TYPE t_carrito IS VARRAY(5) OF cartas.id_carta%TYPE;
  v_carrito t_carrito := t_carrito(1, 3, 6, 99); -- 99 no existe, a proposito

  CURSOR c_carta(p_id_carta NUMBER) IS
    SELECT nombre, precio, stock FROM cartas WHERE id_carta = p_id_carta;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Revision de carrito ---');
  FOR i IN 1 .. v_carrito.COUNT LOOP
    OPEN c_carta(v_carrito(i));
    FETCH c_carta INTO v_carta;
    IF c_carta%FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Carta: ' || v_carta.nombre ||
                            ' | Precio: ' || v_carta.precio ||
                            ' | Stock: ' || v_carta.stock);
    ELSE
      DBMS_OUTPUT.PUT_LINE('Aviso: la carta con ID ' || v_carrito(i) || ' no existe.');
    END IF;
    CLOSE c_carta;
  END LOOP;
END;
/


/* --- Bloque 2: cursores complejos + loops anidados ----------- */
DECLARE
  CURSOR c_colecciones IS
    SELECT id_coleccion, nombre FROM colecciones;

  CURSOR c_cartas_coleccion(p_id_coleccion NUMBER) IS
    SELECT nombre, precio, stock FROM cartas WHERE id_coleccion = p_id_coleccion;

  v_valor_inventario NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Reporte de inventario por coleccion ---');
  FOR col IN c_colecciones LOOP
    v_valor_inventario := 0;
    DBMS_OUTPUT.PUT_LINE('Coleccion: ' || col.nombre);

    FOR carta IN c_cartas_coleccion(col.id_coleccion) LOOP
      DBMS_OUTPUT.PUT_LINE('   ' || carta.nombre || ' - $' || carta.precio ||
                            ' (stock: ' || carta.stock || ')');
      v_valor_inventario := v_valor_inventario + (carta.precio * carta.stock);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('   Valor total en inventario: $' || v_valor_inventario);
  END LOOP;
END;
/


/* --- Bloque 3: excepciones predefinidas y de usuario ---------- */
DECLARE
  v_stock_disponible    cartas.stock%TYPE;
  v_cantidad_solicitada NUMBER := 15;
  v_id_carta            NUMBER := 500; -- no existe

  stock_insuficiente EXCEPTION;
  PRAGMA EXCEPTION_INIT(stock_insuficiente, -20001);
BEGIN
  BEGIN
    SELECT stock INTO v_stock_disponible FROM cartas WHERE id_carta = v_id_carta;

    IF v_stock_disponible < v_cantidad_solicitada THEN
      RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente para completar la venta.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Venta posible, stock suficiente.');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Error: la carta con ID ' || v_id_carta || ' no existe.');
    WHEN stock_insuficiente THEN
      DBMS_OUTPUT.PUT_LINE('Error: no hay stock suficiente para esa cantidad.');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
  END;
END;
/


/* ============================================================
   4. PACKAGE: procedimientos y funciones almacenadas
   (letra f del encargo)
   ============================================================ */

CREATE OR REPLACE PACKAGE pkg_ventas AS

  FUNCTION calcular_total_pedido(p_id_pedido NUMBER) RETURN NUMBER;

  FUNCTION precio_con_descuento(p_id_carta NUMBER, p_cantidad NUMBER) RETURN NUMBER;

  PROCEDURE registrar_pedido(
    p_id_usuario  NUMBER,
    p_id_carta    NUMBER,
    p_cantidad    NUMBER,
    p_id_pedido   OUT NUMBER
  );

END pkg_ventas;
/

CREATE OR REPLACE PACKAGE BODY pkg_ventas AS

  FUNCTION calcular_total_pedido(p_id_pedido NUMBER) RETURN NUMBER IS
    v_total NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(cantidad * precio_unitario), 0)
      INTO v_total
      FROM detalle_pedido
     WHERE id_pedido = p_id_pedido;

    RETURN v_total;
  END calcular_total_pedido;


  FUNCTION precio_con_descuento(p_id_carta NUMBER, p_cantidad NUMBER) RETURN NUMBER IS
    v_precio cartas.precio%TYPE;
  BEGIN
    SELECT precio INTO v_precio FROM cartas WHERE id_carta = p_id_carta;

    IF p_cantidad >= 5 THEN
      RETURN v_precio * p_cantidad * 0.9;  -- 10% de descuento por volumen
    ELSE
      RETURN v_precio * p_cantidad;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'La carta indicada no existe.');
  END precio_con_descuento;


  PROCEDURE registrar_pedido(
    p_id_usuario  NUMBER,
    p_id_carta    NUMBER,
    p_cantidad    NUMBER,
    p_id_pedido   OUT NUMBER
  ) IS
    v_stock  cartas.stock%TYPE;
    v_precio cartas.precio%TYPE;

    stock_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(stock_insuficiente, -20001);
  BEGIN
    SELECT stock, precio INTO v_stock, v_precio
      FROM cartas
     WHERE id_carta = p_id_carta
       FOR UPDATE;

    IF v_stock < p_cantidad THEN
      RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente.');
    END IF;

    INSERT INTO pedidos (id_usuario, estado, total)
    VALUES (p_id_usuario, 'CONFIRMADO', 0)
    RETURNING id_pedido INTO p_id_pedido;

    INSERT INTO detalle_pedido (id_pedido, id_carta, cantidad, precio_unitario)
    VALUES (p_id_pedido, p_id_carta, p_cantidad, v_precio);

    -- el trigger trg_actualiza_stock descuenta el stock automaticamente

    UPDATE pedidos
       SET total = calcular_total_pedido(p_id_pedido)
     WHERE id_pedido = p_id_pedido;

    COMMIT;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20002, 'La carta indicada no existe.');
    WHEN stock_insuficiente THEN
      ROLLBACK;
      RAISE;
  END registrar_pedido;

END pkg_ventas;
/


/* ============================================================
   5. TRIGGERS
   (letra f del encargo)
   ============================================================ */

CREATE OR REPLACE TRIGGER trg_actualiza_stock
AFTER INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
  UPDATE cartas
     SET stock = stock - :NEW.cantidad
   WHERE id_carta = :NEW.id_carta;
END;
/

CREATE OR REPLACE TRIGGER trg_auditoria_precio
BEFORE UPDATE OF precio ON cartas
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_precios (id_carta, precio_anterior, precio_nuevo, usuario_bd)
  VALUES (:OLD.id_carta, :OLD.precio, :NEW.precio, USER);
END;
/


/* ============================================================
   6. PRUEBA RAPIDA DEL PACKAGE Y LOS TRIGGERS
   ============================================================ */

DECLARE
  v_id_pedido NUMBER;
BEGIN
  pkg_ventas.registrar_pedido(
    p_id_usuario => 3,
    p_id_carta   => 3,
    p_cantidad   => 2,
    p_id_pedido  => v_id_pedido
  );
  DBMS_OUTPUT.PUT_LINE('Pedido creado con ID: ' || v_id_pedido);
  DBMS_OUTPUT.PUT_LINE('Total del pedido: ' || pkg_ventas.calcular_total_pedido(v_id_pedido));
END;
/

-- Esto deberia disparar trg_auditoria_precio:
UPDATE cartas SET precio = 160000 WHERE id_carta = 1;
COMMIT;

SELECT * FROM auditoria_precios;
