-- Los errores ORA-01507 y ORA-01219 son esperados.
WHENEVER SQLERROR CONTINUE
SET LINESIZE 180 PAGESIZE 100 FEEDBACK OFF ECHO OFF
COLUMN instance_name FORMAT A12
COLUMN name FORMAT A40
COLUMN value FORMAT A90

PROMPT ===== 0. Punto de partida =====
SELECT instance_name, status, database_status FROM v$instance;

PROMPT ===== 1. SHUTDOWN IMMEDIATE =====
SHUTDOWN IMMEDIATE

PROMPT ===== 2. STARTUP NOMOUNT =====
STARTUP NOMOUNT
SELECT instance_name, status FROM v$instance;

PROMPT -- Los parametros ya se pueden consultar:
SELECT name, value FROM v$parameter
WHERE name IN ('control_files', 'db_name', 'spfile');

PROMPT -- Consulta con ORA-01507 esperado:
SELECT name, open_mode FROM v$database;

PROMPT ===== 3. MOUNT =====
ALTER DATABASE MOUNT;
SELECT instance_name, status FROM v$instance;
SELECT name, open_mode, log_mode FROM v$database;
SELECT name FROM v$controlfile;
SELECT COUNT(*) AS datafiles_conocidos FROM v$datafile;

PROMPT -- Consulta con ORA-01219 esperado:
SELECT COUNT(*) FROM dba_tables;

PROMPT ===== 4. OPEN =====
ALTER DATABASE OPEN;
SELECT instance_name, status, database_status FROM v$instance;
SELECT name, open_mode FROM v$database;
SELECT con_id, name, open_mode, restricted
FROM v$pdbs ORDER BY con_id;

COLUMN con_name FORMAT A12
COLUMN state FORMAT A8
SELECT con_name, instance_name, state FROM dba_pdb_saved_states;

PROMPT ===== 5. Rutas de diagnostico =====
SELECT name, value FROM v$diag_info
WHERE name IN ('ADR Home', 'Diag Trace', 'Default Trace File');
EXIT
