-- ============================================================================
-- TecnoParts SpA  |  BDY1103 - Taller de Base de Datos
-- 07_bloque_anonimo_reporte.sql
--
-- Bloque PL/SQL anonimo que concentra la evidencia de los indicadores:
--   IE1.1.1 -> tipos de datos compuestos (RECORD y VARRAY)
--   IE1.2.1 -> cursores explicitos complejos con parametros y loops anidados
--   IE1.3.1 -> excepciones predefinidas por Oracle y definidas por el usuario
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET DEFINE OFF

DECLARE
    -- ======================= TIPOS COMPUESTOS =======================
    -- VARRAY: las metas son exactamente 4 (Q1..Q4). El limite declarado
    -- documenta y hace cumplir esa regla de negocio.
    TYPE t_metas_trim IS VARRAY(4) OF NUMBER;
    -- VARRAY: el negocio definio "top 5", no "top N".
    TYPE t_top_sku    IS VARRAY(5) OF VARCHAR2(30);

    -- RECORD: estructura que NO corresponde a ninguna tabla; mezcla datos
    -- maestros con metricas calculadas.
    TYPE t_resumen_cat IS RECORD (
        id_categoria   categoria.id_categoria%TYPE,
        nombre         categoria.nombre%TYPE,
        unidades       NUMBER := 0,
        venta_neta     NUMBER := 0,
        costo_total    NUMBER := 0,
        margen_pct     NUMBER := 0,
        meta_trimestre NUMBER := 0,
        cumplim_pct    NUMBER := 0
    );

    -- ======================= VARIABLES =======================
    v_resumen   t_resumen_cat;
    v_metas     t_metas_trim;
    v_top       t_top_sku := t_top_sku();
    v_anio      NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
    v_trimestre NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'Q'));
    v_desde     DATE   := TRUNC(SYSDATE, 'Q');
    v_hasta     DATE   := SYSDATE;
    v_q1 NUMBER; v_q2 NUMBER; v_q3 NUMBER; v_q4 NUMBER;
    v_entradas  NUMBER;
    v_salidas   NUMBER;
    v_lista_top VARCHAR2(300);
    v_cat_ok    NUMBER := 0;
    v_cat_error NUMBER := 0;
    v_total_gen NUMBER := 0;

    -- ======================= EXCEPCIONES DE USUARIO =======================
    e_meta_no_definida EXCEPTION;
    e_meta_en_cero     EXCEPTION;

    -- ======================= CURSORES =======================
    -- Cursor SIN parametros: nivel externo del recorrido.
    CURSOR c_categorias IS
        SELECT id_categoria, nombre
          FROM categoria
         WHERE activo = 'S'
         ORDER BY nombre;

    -- Cursor COMPLEJO CON parametros: JOIN de 3 tablas + agregacion.
    -- El LEFT JOIN conserva los productos sin ventas con metricas en 0:
    -- la rotacion nula es informacion que la gerencia necesita ver.
    CURSOR c_productos (p_id_categoria NUMBER, p_desde DATE, p_hasta DATE) IS
        SELECT p.id_producto,
               p.sku,
               p.nombre,
               p.costo_unitario,
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
         GROUP BY p.id_producto, p.sku, p.nombre, p.costo_unitario
         ORDER BY venta_neta DESC;

    -- Cursor CON parametros: tercer nivel del recorrido.
    CURSOR c_movimientos (p_id_producto NUMBER, p_desde DATE) IS
        SELECT tipo_movimiento, SUM(cantidad) AS total
          FROM movimiento_stock
         WHERE id_producto = p_id_producto
           AND fecha      >= p_desde
         GROUP BY tipo_movimiento;

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 96, '='));
    DBMS_OUTPUT.PUT_LINE(' TECNOPARTS SpA - RENTABILIDAD Y CUMPLIMIENTO POR CATEGORIA');
    DBMS_OUTPUT.PUT_LINE(' Periodo: ' || TO_CHAR(v_desde, 'DD/MM/YYYY') ||
                         ' al '       || TO_CHAR(v_hasta, 'DD/MM/YYYY') ||
                         '   (Q' || v_trimestre || ' ' || v_anio || ')');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 96, '='));

    -- ============ NIVEL 1: categorias activas ============
    FOR r_cat IN c_categorias LOOP
        BEGIN
            -- Reinicio de acumuladores del RECORD por cada categoria
            v_resumen.id_categoria   := r_cat.id_categoria;
            v_resumen.nombre         := r_cat.nombre;
            v_resumen.unidades       := 0;
            v_resumen.venta_neta     := 0;
            v_resumen.costo_total    := 0;
            v_resumen.margen_pct     := 0;
            v_resumen.cumplim_pct    := 0;
            v_top                    := t_top_sku();
            v_lista_top              := NULL;

            -- ---- Carga del VARRAY de metas ----
            -- Un tipo de coleccion declarado en PL/SQL no es visible para SQL,
            -- por eso se recuperan escalares y luego se construye el VARRAY.
            BEGIN
                SELECT meta_q1, meta_q2, meta_q3, meta_q4
                  INTO v_q1, v_q2, v_q3, v_q4
                  FROM meta_categoria
                 WHERE id_categoria = r_cat.id_categoria
                   AND anio         = v_anio;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN         -- predefinida -> de usuario
                    RAISE e_meta_no_definida;
            END;

            v_metas := t_metas_trim(v_q1, v_q2, v_q3, v_q4);

            IF v_trimestre > v_metas.COUNT THEN
                RAISE SUBSCRIPT_BEYOND_COUNT;
            END IF;

            -- El indice del VARRAY tiene significado de negocio: 1 = Q1
            v_resumen.meta_trimestre := NVL(v_metas(v_trimestre), 0);

            IF v_resumen.meta_trimestre = 0 THEN
                RAISE e_meta_en_cero;
            END IF;

            DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> CATEGORIA: ' || r_cat.nombre ||
                '   (meta Q' || v_trimestre || ': ' ||
                TO_CHAR(v_resumen.meta_trimestre, '999G999G999') || ')');
            DBMS_OUTPUT.PUT_LINE('   ' || RPAD('SKU', 16) || RPAD('PRODUCTO', 30) ||
                LPAD('UNID', 6) || LPAD('VENTA NETA', 14) || '   INVENTARIO');
            DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 80, '-'));

            -- ============ NIVEL 2: productos de la categoria ============
            FOR r_prod IN c_productos(r_cat.id_categoria, v_desde, v_hasta) LOOP

                v_resumen.unidades    := v_resumen.unidades    + r_prod.unidades;
                v_resumen.venta_neta  := v_resumen.venta_neta  + r_prod.venta_neta;
                v_resumen.costo_total := v_resumen.costo_total + r_prod.costo_total;

                -- Top 5: el cursor ya viene ordenado por venta neta
                IF r_prod.unidades > 0 AND v_top.COUNT < v_top.LIMIT THEN
                    v_top.EXTEND;
                    v_top(v_top.COUNT) := r_prod.sku;
                END IF;

                -- ============ NIVEL 3: movimientos del producto ============
                v_entradas := 0;
                v_salidas  := 0;
                FOR r_mov IN c_movimientos(r_prod.id_producto, v_desde) LOOP
                    CASE r_mov.tipo_movimiento
                        WHEN 'ENTRADA' THEN v_entradas := v_entradas + r_mov.total;
                        WHEN 'SALIDA'  THEN v_salidas  := v_salidas  + r_mov.total;
                        ELSE NULL;   -- AJUSTE no participa de este reporte
                    END CASE;
                END LOOP;

                DBMS_OUTPUT.PUT_LINE('   ' || RPAD(r_prod.sku, 16) ||
                    RPAD(SUBSTR(r_prod.nombre, 1, 28), 30) ||
                    LPAD(r_prod.unidades, 6) ||
                    LPAD(TO_CHAR(r_prod.venta_neta, '999G999G999'), 14) ||
                    '   E:' || v_entradas || ' / S:' || v_salidas);
            END LOOP;

            -- ---- Margen: bloque anidado minimo ----
            -- Si ZERO_DIVIDE se manejara solo en la seccion EXCEPTION del
            -- bloque principal, la primera categoria sin ventas cortaria
            -- el recorrido completo.
            BEGIN
                v_resumen.margen_pct :=
                    ROUND((v_resumen.venta_neta - v_resumen.costo_total)
                          / v_resumen.venta_neta * 100, 2);
            EXCEPTION
                WHEN ZERO_DIVIDE THEN
                    v_resumen.margen_pct := NULL;   -- "no aplicable", no 0%
            END;

            v_resumen.cumplim_pct := ROUND(v_resumen.venta_neta
                                           / v_resumen.meta_trimestre * 100, 2);

            -- ---- Recorrido del VARRAY para armar el top ----
            FOR i IN 1 .. v_top.COUNT LOOP
                v_lista_top := v_lista_top ||
                               CASE WHEN i > 1 THEN ', ' END || v_top(i);
            END LOOP;

            DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 80, '-'));
            DBMS_OUTPUT.PUT_LINE('   TOTAL: unid=' || v_resumen.unidades ||
                ' | neto=' || TO_CHAR(v_resumen.venta_neta, '999G999G999') ||
                ' | margen=' || NVL(TO_CHAR(v_resumen.margen_pct), 'N/A') || '%' ||
                ' | cumplimiento=' || v_resumen.cumplim_pct || '%');
            DBMS_OUTPUT.PUT_LINE('   TOP ' || v_top.COUNT || ': ' ||
                                 NVL(v_lista_top, '(sin ventas en el periodo)'));

            IF v_resumen.cumplim_pct < 60 THEN
                DBMS_OUTPUT.PUT_LINE('   [ALERTA] Cumplimiento bajo el 60% de la meta.');
            END IF;

            v_total_gen := v_total_gen + v_resumen.venta_neta;
            v_cat_ok    := v_cat_ok + 1;

        EXCEPTION
            -- ---- Manejadores de NIVEL ITERACION ----
            -- Registran, informan y dejan continuar con la siguiente categoria.
            WHEN e_meta_no_definida THEN
                v_cat_error := v_cat_error + 1;
                sp_registrar_log('REPORTE_CUMPLIMIENTO', -20050,
                    'Sin meta ' || v_anio || ' para la categoria ' || r_cat.nombre);
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': sin meta definida para ' || v_anio || '. Categoria omitida.');
            WHEN e_meta_en_cero THEN
                v_cat_error := v_cat_error + 1;
                sp_registrar_log('REPORTE_CUMPLIMIENTO', -20051,
                    'Meta en 0 para la categoria ' || r_cat.nombre);
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': meta del trimestre en 0, no es posible calcular cumplimiento.');
            WHEN TOO_MANY_ROWS THEN
                v_cat_error := v_cat_error + 1;
                sp_registrar_log('REPORTE_CUMPLIMIENTO', SQLCODE,
                    'Metas duplicadas en la categoria ' || r_cat.nombre);
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': metas duplicadas. Revisar META_CATEGORIA.');
            WHEN SUBSCRIPT_BEYOND_COUNT THEN
                v_cat_error := v_cat_error + 1;
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': VARRAY de metas incompleto para el trimestre ' || v_trimestre || '.');
            WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
                v_cat_error := v_cat_error + 1;
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': se excedio el limite declarado del VARRAY.');
            WHEN VALUE_ERROR THEN
                v_cat_error := v_cat_error + 1;
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '>> ' || r_cat.nombre ||
                    ': error de conversion o precision. ' || SQLERRM);
        END;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 96, '='));
    DBMS_OUTPUT.PUT_LINE(' Venta neta total del periodo: ' ||
                         TO_CHAR(v_total_gen, '999G999G999'));
    DBMS_OUTPUT.PUT_LINE(' Categorias procesadas: ' || v_cat_ok ||
                         '   |   omitidas por error: ' || v_cat_error);
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 96, '='));

EXCEPTION
    -- ---- Manejador de NIVEL BLOQUE: red de seguridad ----
    WHEN OTHERS THEN
        ROLLBACK;
        sp_registrar_log('REPORTE_CUMPLIMIENTO', SQLCODE,
            SQLERRM || ' | ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        DBMS_OUTPUT.PUT_LINE('ERROR NO PREVISTO [' || SQLCODE || ']: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/
