@scripts/ops/marca.sql
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._08-memoria.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A36
COLUMN component FORMAT A30
COLUMN pname FORMAT A8
COLUMN spid FORMAT A12
COLUMN unidad FORMAT A10
COLUMN display_value FORMAT A12

PROMPT == 1. Modelo de gestion de memoria ==
SELECT name, display_value FROM v$parameter
WHERE name IN (
  'memory_size', 'memory_target', 'sga_target', 'sga_max_size',
  'pga_aggregate_target', 'pga_aggregate_limit',
  'db_cache_size', 'shared_pool_size'
)
ORDER BY name;

PROMPT == 2. Resumen de la SGA ==
SELECT name, ROUND(value / 1048576, 1) AS mb FROM v$sga;

PROMPT == 3. Componentes de la SGA ==
SELECT name, ROUND(bytes / 1048576, 1) AS mb, resizeable
FROM v$sgainfo ORDER BY bytes DESC;

PROMPT == 4. Reparto dinamico de la SGA ==
SELECT component,
       ROUND(current_size / 1048576) AS actual_mb,
       ROUND(min_size / 1048576) AS min_mb,
       ROUND(user_specified_size / 1048576) AS fijado_mb,
       oper_count AS ajustes
FROM v$sga_dynamic_components
WHERE current_size > 0 ORDER BY current_size DESC;

PROMPT == 5. Asesor de SGA ==
SELECT sga_size AS sga_mb,
       sga_size_factor AS factor,
       estd_db_time_factor AS tiempo_bd_estimado,
       estd_physical_reads AS lecturas_fisicas_est
FROM v$sga_target_advice ORDER BY sga_size;

PROMPT == 6. Estadisticas de PGA ==
SELECT name,
       ROUND(CASE unit WHEN 'bytes' THEN value / 1048576
                       ELSE value END, 1) AS valor,
       CASE unit WHEN 'bytes' THEN 'MB' ELSE unit END AS unidad
FROM v$pgastat
WHERE name IN (
  'aggregate PGA target parameter', 'aggregate PGA auto target',
  'total PGA inuse', 'total PGA allocated', 'maximum PGA allocated',
  'over allocation count', 'cache hit percentage'
)
AND con_id = 0;

PROMPT == 7. Los ocho procesos con mas PGA asignada ==
SELECT * FROM (
  SELECT NVL(pname, 'servidor') AS pname, spid,
         ROUND(pga_used_mem / 1048576, 1) AS usada_mb,
         ROUND(pga_alloc_mem / 1048576, 1) AS asignada_mb,
         ROUND(pga_max_mem / 1048576, 1) AS maxima_mb
  FROM v$process ORDER BY pga_alloc_mem DESC
)
WHERE ROWNUM <= 8;

SPOOL OFF
