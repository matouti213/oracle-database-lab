@scripts/ops/marca.sql
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._09-procesos.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
COLUMN pname FORMAT A6
COLUMN spid FORMAT A8
COLUMN description FORMAT A48
COLUMN program FORMAT A34
COLUMN tipo FORMAT A11
COLUMN username FORMAT A12
COLUMN machine FORMAT A20

PROMPT == 1. Procesos Oracle y procesos Linux ==
SELECT CASE WHEN background = '1' THEN 'background'
            ELSE 'servidor' END AS tipo,
       COUNT(*) AS procesos_oracle,
       COUNT(DISTINCT spid) AS procesos_linux
FROM v$process
WHERE spid IS NOT NULL
GROUP BY CASE WHEN background = '1' THEN 'background'
              ELSE 'servidor' END;

PROMPT == 2. Procesos principales y su SPID ==
SELECT b.name AS pname, p.spid, b.description
FROM v$bgprocess b
JOIN v$process p ON p.addr = b.paddr
WHERE b.name IN (
  'PMON', 'LREG', 'SMON', 'DBW0', 'LGWR', 'CKPT',
  'MMON', 'MMNL', 'RECO', 'CJQ0', 'DIAG', 'DIA0',
  'VKTM', 'PMAN', 'CLMN', 'PSP0', 'MMAN', 'ARC0'
)
ORDER BY CASE b.name
  WHEN 'PMON' THEN 1 WHEN 'LREG' THEN 2
  WHEN 'SMON' THEN 3 WHEN 'DBW0' THEN 4
  WHEN 'LGWR' THEN 5 WHEN 'CKPT' THEN 6
  WHEN 'MMON' THEN 7 WHEN 'MMNL' THEN 8
  WHEN 'RECO' THEN 9 ELSE 10 END, b.name;

PROMPT == 3. Archivadores activos y modo de la base ==
SELECT log_mode FROM v$database;
SELECT COUNT(*) AS procesos_arcn
FROM v$bgprocess b
JOIN v$process p ON p.addr = b.paddr
WHERE b.name LIKE 'ARC%';

PROMPT == 4. Mi sesion y su proceso servidor ==
SELECT s.sid, s.serial#, s.username, s.machine, s.program, p.spid
FROM v$session s
JOIN v$process p ON p.addr = s.paddr
WHERE s.sid = SYS_CONTEXT('USERENV', 'SID');

PROMPT == 5. Sesiones de usuario ==
SELECT s.sid, s.username, s.status, s.machine, s.program, p.spid
FROM v$session s
JOIN v$process p ON p.addr = s.paddr
WHERE s.type = 'USER'
ORDER BY s.sid;

SPOOL OFF
