-- ============================================================================
-- TecnoParts SpA  |  06_bloque_anonimo.sql
--
-- Reporte de ventas y cumplimiento de metas por categoria.
-- Reune los cuatro contenidos evaluados:
--   RECORD y VARRAY        tipos de datos compuestos
--   c_categorias           cursor explicito sin parametros
--   c_productos            cursor explicito con parametros
--   c_movimientos          cursor explicito con parametros
--   tres loops anidados    categoria -> producto -> movimiento
--   excepciones            predefinidas por Oracle y definidas por el usuario
-- ============================================================================
SET SERVEROUTPUT ON
SET LINESIZE 200

DECLARE
    -- ===================== TIPOS DE DATOS COMPUESTOS =====================

    -- RECORD: agrupa en una sola variable el resumen de la categoria.
    -- No corresponde a ninguna tabla, porque mezcla datos con calculos.
    TYPE t_resumen IS RECORD (
        nombre       categoria.nombre%TYPE,
        unidades     NUMBER,
        venta_neta   NUMBER,
        costo_total  NUMBER,
        margen       NUMBER,
        meta         NUMBER,
        cumplimiento NUMBER
    );

    -- VARRAY de 4: las metas del anio son siempre cuatro, una por trimestre.
    TYPE t_metas IS VARRAY(4) OF NUMBER;

    -- VARRAY de 5: el negocio pidio un top 5 de productos.
    TYPE t_top IS VARRAY(5) OF VARCHAR2(30);

    v_resumen t_resumen;
    v_metas   t_metas;
    v_top     t_top;

    -- ===================== VARIABLES =====================
    v_anio      NUMBER := 2026;
    v_trimestre NUMBER := 3;
    v_desde     DATE   := TO_DATE('01/07/2026','DD/MM/YYYY');
    v_hasta     DATE   := TO_DATE('20/09/2026','DD/MM/YYYY');

    v_q1 NUMBER;
    v_q2 NUMBER;
    v_q3 NUMBER;
    v_q4 NUMBER;

    v_entradas  NUMBER;
    v_salidas   NUMBER;
    v_lista_top VARCHAR2(200);
    v_procesadas NUMBER := 0;
    v_omitidas   NUMBER := 0;

    -- ===================== EXCEPCIONES DE USUARIO =====================
    e_meta_no_definida EXCEPTION;
    e_meta_en_cero     EXCEPTION;

    -- ===================== CURSORES =====================

    -- Cursor SIN parametros: recorre las categorias activas.
    CURSOR c_categorias IS
        SELECT id_categoria, nombre
          FROM categoria
         WHERE activo = 'S'
         ORDER BY id_categoria;

    -- Cursor CON parametros: productos de una categoria y sus ventas
    -- dentro del periodo. El LEFT JOIN mantiene los productos sin ventas.
    CURSOR c_productos (p_id_categoria NUMBER, p_desde DATE, p_hasta DATE) IS
        SELECT p.id_producto,
               p.sku,
               p.nombre,
               NVL(SUM(d.cantidad), 0) AS unidades,
               NVL(SUM(d.cantidad * d.precio_unitario
                       * (1 - d.descuento_pct/100)), 0) AS venta_neta,
               NVL(SUM(d.cantidad * p.costo_unitario), 0) AS costo_total
          FROM producto p
          LEFT JOIN detalle_venta d ON d.id_producto = p.id_producto
          LEFT JOIN venta v         ON v.id_venta    = d.id_venta
                                   AND v.estado      = 'EMITIDA'
                                   AND v.fecha_venta BETWEEN p_desde AND p_hasta
         WHERE p.id_categoria = p_id_categoria
           AND p.activo       = 'S'
         GROUP BY p.id_producto, p.sku, p.nombre
         ORDER BY venta_neta DESC;

    -- Cursor CON parametros: movimientos de inventario de un producto.
    CURSOR c_movimientos (p_id_producto NUMBER, p_desde DATE) IS
        SELECT tipo_movimiento, SUM(cantidad) AS total
          FROM movimiento_stock
         WHERE id_producto = p_id_producto
           AND fecha      >= p_desde
         GROUP BY tipo_movimiento;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE(' TECNOPARTS SpA - VENTAS POR CATEGORIA');
    DBMS_OUTPUT.PUT_LINE(' Periodo: ' || TO_CHAR(v_desde,'DD/MM/YYYY') ||
                         ' al ' || TO_CHAR(v_hasta,'DD/MM/YYYY') ||
                         '  (trimestre ' || v_trimestre || ' de ' || v_anio || ')');
    DBMS_OUTPUT.PUT_LINE('=========================================================');

    -- ================== NIVEL 1: categorias ==================
    FOR r_cat IN c_categorias LOOP

        BEGIN
            v_resumen.nombre      := r_cat.nombre;
            v_resumen.unidades    := 0;
            v_resumen.venta_neta  := 0;
            v_resumen.costo_total := 0;
            v_top                 := t_top();
            v_lista_top           := NULL;

            -- Carga de las cuatro metas del anio en el VARRAY.
            -- Se leen primero en variables y despues se arma la coleccion.
            SELECT meta_q1, meta_q2, meta_q3, meta_q4
              INTO v_q1, v_q2, v_q3, v_q4
              FROM meta_categoria
             WHERE id_categoria = r_cat.id_categoria
               AND anio         = v_anio;

            v_metas := t_metas(v_q1, v_q2, v_q3, v_q4);

            -- La posicion del VARRAY es el numero del trimestre
            v_resumen.meta := v_metas(v_trimestre);

            IF v_resumen.meta = 0 THEN
                RAISE e_meta_en_cero;
            END IF;

            DBMS_OUTPUT.PUT_LINE(' ');
            DBMS_OUTPUT.PUT_LINE('CATEGORIA: ' || r_cat.nombre ||
                '   (meta del trimestre: ' ||
                TO_CHAR(v_resumen.meta, '999G999G999') || ')');
            DBMS_OUTPUT.PUT_LINE('   ' || RPAD('SKU',15) || RPAD('PRODUCTO',28) ||
                LPAD('UNID',6) || LPAD('VENTA NETA',14) || '   INVENTARIO');

            -- ================== NIVEL 2: productos ==================
            FOR r_prod IN c_productos(r_cat.id_categoria, v_desde, v_hasta) LOOP

                v_resumen.unidades    := v_resumen.unidades    + r_prod.unidades;
                v_resumen.venta_neta  := v_resumen.venta_neta  + r_prod.venta_neta;
                v_resumen.costo_total := v_resumen.costo_total + r_prod.costo_total;

                -- Top 5: el cursor ya viene ordenado por venta neta
                IF r_prod.unidades > 0 AND v_top.COUNT < 5 THEN
                    v_top.EXTEND;
                    v_top(v_top.COUNT) := r_prod.sku;
                END IF;

                -- ================== NIVEL 3: movimientos ==================
                v_entradas := 0;
                v_salidas  := 0;

                FOR r_mov IN c_movimientos(r_prod.id_producto, v_desde) LOOP
                    IF r_mov.tipo_movimiento = 'ENTRADA' THEN
                        v_entradas := v_entradas + r_mov.total;
                    ELSIF r_mov.tipo_movimiento = 'SALIDA' THEN
                        v_salidas := v_salidas + r_mov.total;
                    END IF;
                END LOOP;

                DBMS_OUTPUT.PUT_LINE('   ' || RPAD(r_prod.sku,15) ||
                    RPAD(SUBSTR(r_prod.nombre,1,26),28) ||
                    LPAD(r_prod.unidades,6) ||
                    LPAD(TO_CHAR(r_prod.venta_neta,'999G999G999'),14) ||
                    '   E:' || v_entradas || ' S:' || v_salidas);
            END LOOP;

            -- Margen: se calcula en su propio bloque para que una categoria
            -- sin ventas no corte el reporte completo.
            BEGIN
                v_resumen.margen := ROUND(
                    (v_resumen.venta_neta - v_resumen.costo_total)
                    / v_resumen.venta_neta * 100, 2);
            EXCEPTION
                WHEN ZERO_DIVIDE THEN     -- excepcion predefinida por Oracle
                    v_resumen.margen := NULL;
            END;

            v_resumen.cumplimiento :=
                ROUND(v_resumen.venta_neta / v_resumen.meta * 100, 2);

            -- Recorrido del VARRAY para armar el texto del top
            FOR i IN 1 .. v_top.COUNT LOOP
                IF i = 1 THEN
                    v_lista_top := v_top(i);
                ELSE
                    v_lista_top := v_lista_top || ', ' || v_top(i);
                END IF;
            END LOOP;

            DBMS_OUTPUT.PUT_LINE('   TOTAL: unidades=' || v_resumen.unidades ||
                '  neto=' || TO_CHAR(v_resumen.venta_neta,'999G999G999') ||
                '  margen=' || NVL(TO_CHAR(v_resumen.margen),'no calculable') ||
                '%  cumplimiento=' || v_resumen.cumplimiento || '%');
            DBMS_OUTPUT.PUT_LINE('   TOP: ' ||
                NVL(v_lista_top, 'sin ventas en el periodo'));

            v_procesadas := v_procesadas + 1;

        EXCEPTION
            -- Excepcion predefinida: no existe la fila de metas
            WHEN NO_DATA_FOUND THEN
                v_omitidas := v_omitidas + 1;
                DBMS_OUTPUT.PUT_LINE(' ');
                DBMS_OUTPUT.PUT_LINE('CATEGORIA: ' || r_cat.nombre ||
                    ' -> no tiene metas cargadas para ' || v_anio ||
                    '. No se calcula cumplimiento.');

            -- Excepcion predefinida: hay mas de una fila de metas
            WHEN TOO_MANY_ROWS THEN
                v_omitidas := v_omitidas + 1;
                DBMS_OUTPUT.PUT_LINE('CATEGORIA: ' || r_cat.nombre ||
                    ' -> tiene metas duplicadas. Revisar META_CATEGORIA.');

            -- Excepcion definida por el usuario
            WHEN e_meta_en_cero THEN
                v_omitidas := v_omitidas + 1;
                DBMS_OUTPUT.PUT_LINE(' ');
                DBMS_OUTPUT.PUT_LINE('CATEGORIA: ' || r_cat.nombre ||
                    ' -> la meta del trimestre es cero. ' ||
                    'No se puede calcular el porcentaje de cumplimiento.');
        END;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE(' Categorias procesadas: ' || v_procesadas ||
                         '   omitidas: ' || v_omitidas);
    DBMS_OUTPUT.PUT_LINE('=========================================================');

EXCEPTION
    -- Ultimo resguardo: cualquier error no previsto queda registrado
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error no previsto: ' || SQLCODE || ' - ' || SQLERRM);
        sp_registrar_log('reporte_categorias', SQLCODE, SQLERRM);
        COMMIT;
END;
/
