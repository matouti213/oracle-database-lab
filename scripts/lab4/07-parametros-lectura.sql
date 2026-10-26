@scripts/ops/marca.sql
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._07-parametros-lectura.spool.log

SET SQLFORMAT DEFAULT
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A30
COLUMN value FORMAT A70
COLUMN display_value FORMAT A14
COLUMN sid FORMAT A4

PROMPT == 1. SPFILE utilizado ==
SELECT name, value FROM v$parameter WHERE name = 'spfile';

PROMPT == 2. Valores efectivos y posibilidad de modificarlos ==
SELECT name, display_value, isdefault, ismodified,
       issys_modifiable AS sys_mod,
       isses_modifiable AS ses_mod,
       ispdb_modifiable AS pdb_mod
FROM v$parameter
WHERE name IN (
  'db_name', 'db_block_size', 'compatible', 'cpu_count',
  'memory_size', 'sga_target', 'pga_aggregate_target',
  'pga_aggregate_limit', 'processes', 'sessions',
  'open_cursors', 'db_files', 'undo_tablespace',
  'undo_retention', 'db_create_file_dest',
  'db_recovery_file_dest', 'db_recovery_file_dest_size',
  'vector_memory_size', 'inmemory_size',
  'enable_pluggable_database'
)
ORDER BY name;

PROMPT == 3. Parametros especificados en el SPFILE ==
SELECT sid, name, value
FROM v$spparameter
WHERE isspecified = 'TRUE'
  AND name NOT LIKE '\_%' ESCAPE '\'
ORDER BY name;

PROMPT == 4. Recuento de parametros ==
SELECT COUNT(*) AS documentados,
       SUM(CASE WHEN isdefault = 'FALSE' THEN 1 ELSE 0 END) AS no_por_defecto,
       SUM(CASE WHEN issys_modifiable = 'FALSE' THEN 1 ELSE 0 END) AS estaticos
FROM v$parameter;

SPOOL OFF
