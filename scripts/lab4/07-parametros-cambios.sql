SET LINESIZE 180 PAGESIZE 100 FEEDBACK ON
COLUMN name FORMAT A20
COLUMN en_memoria FORMAT A12
COLUMN en_spfile FORMAT A20
COLUMN update_comment FORMAT A40
WHENEVER SQLERROR EXIT FAILURE

PROMPT ===== 1. SCOPE=MEMORY =====
ALTER SYSTEM SET open_cursors = 400 SCOPE = MEMORY;

SELECT p.name, p.value AS en_memoria, s.value AS en_spfile
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'open_cursors' AND s.sid = '*';

PROMPT ===== 2. SCOPE=BOTH =====
ALTER SYSTEM SET open_cursors = 500
  COMMENT = 'Lab4: prueba SCOPE=BOTH' SCOPE = BOTH;

SELECT p.name, p.value AS en_memoria, s.value AS en_spfile,
       p.update_comment
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'open_cursors' AND s.sid = '*';

PROMPT -- Restaurar open_cursors a 300:
ALTER SYSTEM SET open_cursors = 300 COMMENT = '' SCOPE = BOTH;

PROMPT ===== 3. Parametro estatico: ORA-02095 esperado =====
WHENEVER SQLERROR CONTINUE
ALTER SYSTEM SET db_files = 300 SCOPE = MEMORY;
WHENEVER SQLERROR EXIT FAILURE

PROMPT -- Cambiar solo el SPFILE:
ALTER SYSTEM SET db_files = 300 SCOPE = SPFILE;

SELECT p.name, p.value AS en_memoria, s.value AS en_spfile
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'db_files' AND s.sid = '*';

PROMPT -- Eliminar el cambio pendiente:
ALTER SYSTEM RESET db_files SCOPE = SPFILE SID = '*';

PROMPT ===== Verificacion final =====
SELECT name, value AS en_memoria
FROM v$parameter WHERE name IN ('open_cursors', 'db_files');

SELECT sid, name, value AS en_spfile, isspecified
FROM v$spparameter
WHERE name IN ('open_cursors', 'db_files');


PROMPT ===== 4. Cambios no permitidos en memoria =====
WHENEVER SQLERROR CONTINUE
PROMPT -- PROCESSES: se espera rechazo del cambio:
ALTER SYSTEM SET processes = 250 SCOPE = MEMORY;

PROMPT -- MEMORY_SIZE: se espera ORA-62352:
ALTER SYSTEM SET memory_size = 1600M SCOPE = MEMORY;
WHENEVER SQLERROR EXIT FAILURE

PROMPT ===== 5. Parametros por PDB =====
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SYSTEM SET open_cursors = 350 SCOPE = MEMORY;

COLUMN contenedor FORMAT A12
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS contenedor,
       name, value AS en_memoria
FROM v$parameter WHERE name = 'open_cursors';

PROMPT -- PROCESSES desde la PDB: ORA-65040 esperado:
WHENEVER SQLERROR CONTINUE
ALTER SYSTEM SET processes = 300 SCOPE = SPFILE;
WHENEVER SQLERROR EXIT FAILURE

PROMPT -- Restaurar la herencia del CDB:
ALTER SYSTEM RESET open_cursors SCOPE = MEMORY;

SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS contenedor,
       name, value AS en_memoria
FROM v$parameter WHERE name = 'open_cursors';

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== 6. Parametro de sesion =====
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
SELECT SYSDATE AS ahora_con_formato_de_sesion FROM dual;

PROMPT ===== 7. Exportar configuracion a PFILE =====
CREATE PFILE = '/tmp/initFREE_lab4.ora' FROM SPFILE;
CREATE PFILE = '/tmp/initFREE_lab4_memoria.ora' FROM MEMORY;

PROMPT ===== Comprobacion final en CDB$ROOT =====
SELECT name, value AS en_memoria
FROM v$parameter
WHERE name IN ('open_cursors', 'db_files', 'processes', 'memory_size')
ORDER BY name;

EXIT
