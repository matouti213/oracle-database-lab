-- JUSTIFICACION CON EVIDENCIA PROPIA — Amine, Issue #9, 27/10/2026
-- Referencias: evidencia 03 (20261026T231104Z), 05 (20261026T231234Z), 06 (20261027T135525Z).
-- + UX_CLI_DNI: Q13, 1486 -> 3 lecturas; ORA-00001 demuestra unicidad (03).
-- + IX_PED_CLI_FEC_CUB: Q7, 15 -> 7 -> 3 lecturas, sin acceso a tabla (03).
-- - IX_PED_CLIENTE: prefijo cubierto por el nuevo indice; NO usado con la propuesta (06).
-- + IX_PED_PENDIENTES: 20000 entradas/54 hojas frente a 1000000/2933 de estado-fecha;
--   Q12, 239 frente a 246 lecturas (03). No se afirma que todo UPDATE sea mas barato.
-- + IX_PED_CP: Q3 devuelve 102 filas y pasa de 5232 a 106 lecturas con literal correcto (05);
--   usado en la carga observada (06).
-- - IX_PED_IMPORTE: NO usado en la ventana probada; Q2 conserva 318 lecturas al hacerlo
--   INVISIBLE (06). Una prueba corta no demuestra ausencia universal de uso.
-- Coste por fila con 4/9/5 indices en PEDIDO: INSERT 10.2/20.2/12.1 bloques;
-- UPDATE estado 2/6/8.1; UPDATE importe 6/6/6; DELETE 10.1/20.1/10.1 (06).
-- Se acepta el mayor coste de UPDATE estado a cambio del servicio de las consultas objetivo.
-- Frecuencias de consultas en el comentario original: supuestos del enunciado, no tasas medidas.
-- Esta edicion SOLO ANADE COMENTARIOS. V005 ya esta aplicada: NO volver a ejecutarla.
-- ============================================================================
-- database/migrations/V005__indices_tiendasur.sql
-- El diseño de índices de TiendaSur que sale del protocolo de cinco preguntas (Lab 5, Parte G; Actividad 3.2):
--   + ux_cli_dni          Q13 (500/s): busca por DNI y además GARANTIZA que no se repite (antes lo controlaba la aplicación)
--   + ix_ped_cli_fec_cub  Q7 (2000/s, la más frecuente): igualdad, rango y ORDER BY sin tocar la tabla. Empieza por id_cliente:
--                         sigue cubriendo la clave ajena, así que ix_ped_cliente sobra
--   - ix_ped_cliente      redundante: es prefijo de ix_ped_cli_fec_cub
--   + ix_ped_pendientes   Q12 (cada 30 s): índice parcial (solo el 2 % de filas en 'P') sobre una columna virtual
--   + ix_ped_cp           Q3 (50/s) una vez reescrita con '30001': 0,01 % de filas por código postal, muy por debajo del umbral
--   - ix_ped_importe      cero usos en la observación (MONITORING USAGE) y ya probado como INVISIBLE
--   = pk_pedido, ix_ped_fecha (Q2, Q8, Q9), pk_cliente, ux_cli_email (Q1 reescrita), ix_cli_pais_ciudad (Q6, skip scan aceptable)
-- Q1, Q2, Q3 y Q11 se arreglan REESCRIBIENDO la consulta (sargabilidad), no con índices. Q10 y Q11: el recorrido completo es lo correcto.
-- Idempotente: si ux_cli_dni ya existe, no hace nada.
SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;
WHENEVER SQLERROR EXIT SUCCESS
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'UX_CLI_DNI';
  IF n > 0 THEN RAISE_APPLICATION_ERROR(-20005, 'V005 ya aplicada: UX_CLI_DNI existe, no se hace nada'); END IF;
END;
/
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE UNIQUE INDEX tiendasur.ux_cli_dni ON tiendasur.cliente (dni) ONLINE;
CREATE INDEX tiendasur.ix_ped_cli_fec_cub ON tiendasur.pedido (id_cliente, fecha_pedido, importe, estado, id_pedido) ONLINE;
DROP INDEX tiendasur.ix_ped_cliente;
ALTER TABLE tiendasur.pedido ADD (fecha_pendiente AS (CASE WHEN estado = 'P' THEN fecha_pedido END));
CREATE INDEX tiendasur.ix_ped_pendientes ON tiendasur.pedido (fecha_pendiente) ONLINE;
CREATE INDEX tiendasur.ix_ped_cp ON tiendasur.pedido (codigo_postal) ONLINE;
DROP INDEX tiendasur.ix_ped_importe;
SET LINESIZE 150 PAGESIZE 50
COLUMN table_name FORMAT A8
COLUMN index_name FORMAT A20
SELECT table_name, index_name, uniqueness, visibility FROM dba_indexes WHERE owner = 'TIENDASUR' ORDER BY table_name, index_name;
EXIT
