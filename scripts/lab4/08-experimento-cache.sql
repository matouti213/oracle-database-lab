-- Experimento de cache: ejecutar solo en el entorno de laboratorio.
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 180 PAGESIZE 100 FEEDBACK OFF
COLUMN table_name FORMAT A20
COLUMN object_name FORMAT A20
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON

PROMPT ===== 1. Tamano de la tabla =====
SELECT table_name, num_rows, blocks, avg_row_len
FROM dba_tables
WHERE owner = 'ADMIN_ACADEMIA'
  AND table_name = 'ACA_ESTUDIANTES';

PROMPT ===== 2. Vaciar la cache del laboratorio =====
ALTER SYSTEM FLUSH BUFFER_CACHE;

PROMPT ===== 3. Ejecutar la misma consulta dos veces =====
DECLARE
  FUNCTION estad(p_nombre VARCHAR2) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT m.value INTO v
    FROM v$mystat m
    JOIN v$statname n ON n.statistic# = m.statistic#
    WHERE n.name = p_nombre;
    RETURN v;
  END;

  PROCEDURE ronda(p_titulo VARCHAR2) IS
    l0 NUMBER := estad('session logical reads');
    f0 NUMBER := estad('physical reads');
    n NUMBER;
  BEGIN
    SELECT /*+ FULL(e) */ COUNT(*) INTO n
    FROM admin_academia.aca_estudiantes e
    WHERE estado = 'ACTIVO';

    DBMS_OUTPUT.PUT_LINE(
      RPAD(p_titulo, 25) || ' filas ACTIVO=' || n
      || ' | lecturas logicas=' || (estad('session logical reads') - l0)
      || ' | lecturas fisicas=' || (estad('physical reads') - f0)
    );
  END;
BEGIN
  ronda('Ronda 1 (cache fria)');
  ronda('Ronda 2 (cache caliente)');
END;
/

PROMPT ===== 4. Bloques de la tabla en cache =====
SELECT o.object_name, COUNT(*) AS bloques_en_cache
FROM v$bh b
JOIN dba_objects o ON o.data_object_id = b.objd
WHERE o.owner = 'ADMIN_ACADEMIA'
  AND o.object_name = 'ACA_ESTUDIANTES'
  AND b.status <> 'free'
GROUP BY o.object_name;

EXIT
