## Parte B — Línea base de turno
El 25/11/2026 a las 17:46 UTC conté 2 mensajes con ORA- en las últimas 24 horas. En ese momento había 0 sesiones bloqueadas y 0 alertas pendientes.
## Parte C — Validación tras el arranque
ORA-00800: Oracle intentó aumentar la prioridad del proceso LGWR, encargado de escribir el redo, pero el sistema operativo del contenedor no lo permitió.
ORA-65019: FREEPDB1 ya estaba abierta en modo de solo lectura cuando el script intentó abrirla en READ WRITE. Para cambiar de modo había que cerrarla primero o usar FORCE.
## Preguntas de comprobación

## Preguntas de comprobación

### 1. Errores ORA- en las últimas 24 horas

En la lista de turno conté 2 mensajes con ORA- en las últimas 24 horas. Al consultar el alert log vi que ambos eran ORA-00800: a las 17:39:24 UTC falló el ajuste de prioridad del proceso VKTM y, un segundo después, el de LGWR. El recuento por sí solo no indica la gravedad. En ese turno, FREEPDB1 estaba abierta en READ WRITE y había 0 sesiones bloqueadas y 0 alertas pendientes.

Evidencia: `20261125T174644Z_01-turno.script.log`, apartados 2 a 7, y consulta posterior a `V$DIAG_ALERT_EXT`.

### 2. Ventana de mantenimiento del miércoles

En mi base, WEDNESDAY_WINDOW empieza el miércoles a las 22:00 y dura 4 horas, hasta las 02:00 del jueves. En la consulta de AutoTask aparecían habilitadas tres tareas: la recogida de estadísticas del optimizador, el asesor de espacio y el asesor de ajuste de SQL.

Evidencia: `20261125T174702Z_01-automatizacion.spool.log`, apartados 1 y 2.

### 3. Diferencia entre el SPFILE y la memoria

Después de cambiar db_files con SCOPE=SPFILE, V$SPPARAMETER mostraba 250 en el archivo de arranque y V$PARAMETER seguía mostrando 200 en memoria. La instancia continuó trabajando con 200. Si la hubiera reiniciado antes de deshacer el cambio, habría leído el nuevo valor de 250 del SPFILE.

Evidencia: log `02-parametros.script.log`, filas «SPFILE (archivo)» y «MEMORIA (en uso)».

### 4. Por qué utilicé RESET para db_files

Antes de la prueba, db_files aparecía «sin fijar», con ISSPECIFIED=FALSE. Al ejecutar RESET eliminé el valor de prueba y recuperé la configuración inicial. El caso de processes era distinto: la línea 31 de mi PFILE contiene `*.processes=200`. Si hubiera cambiado ese parámetro, para dejarlo como estaba tendría que haber vuelto a fijarlo en 200. Un RESET habría eliminado la configuración explícita que tenía al principio.

Evidencia: log `02-parametros.script.log` y `20261125T175409Z_02-init_desde_spfile.ora`, línea 31.

### 5. Reinicio sin estado guardado

Tras el reinicio, Oracle mostró «Database opened» porque la CDB se había abierto. Sin embargo, al consultar el estado de FREEPDB1 vi que seguía en MOUNTED y sin estado guardado. Por eso, cuando C##OPS_RO intentó conectarse por el servicio freepdb1, recibió `ORA-01109: database not open`. Después de abrir la PDB y ejecutar SAVE STATE, comprobé que en el segundo reinicio volvió a READ WRITE.

Evidencia: log `02-estados-pdb.script.log`, apartados 4 y 5.

### 6. Identificación de la sesión de la aplicación

La sesión de APP_ACADEMIA tenía SID 225, SERIAL# 45312 y SPID 3608. El SID identifica la sesión en Oracle y el SPID me permitió localizar su proceso de Linux dentro del contenedor. El evento era `PL/SQL lock timer` porque el script había ejecutado una pausa. Aunque el proceso aparecía como `sleeping`, la sesión mantenía una transacción abierta con 1 bloque de undo y 1 registro de undo.

USERNAME solo me indicaba que la conexión utilizaba la cuenta APP_ACADEMIA. Con MODULE pude identificar el módulo `matriculas`, con ACTION vi que la operación era `cierre-periodo` y con CLIENT_IDENTIFIER supe que la aplicación había identificado al cliente como `ana.garcia@ucam`.

Evidencia: `03-sesiones.script.log`, apartado 3.

### 7. Diferencia entre cancelar la llamada y terminar la sesión

Después de ejecutar CANCEL SQL sobre la sesión 225, la aplicación seguía teniendo 1 transacción abierta. Se había cancelado la llamada que estaba en espera, pero el UPDATE anterior seguía pendiente. Después de KILL SESSION quedaron 0 sesiones de APP_ACADEMIA. Oracle deshizo el cambio sin confirmar y comprobé que el estudiante 101 conservaba el estado ACTIVO.

Evidencia: `03-sesiones.script.log`, apartados 4 y 5.

### 8. Prefijo de las cuentas comunes

En mi instancia, `common_user_prefix` tenía el valor `C##`. Por tanto, al crear una cuenta común en la raíz de la CDB, su nombre debe comenzar por ese prefijo. Un ejemplo del laboratorio es `C##OPS_RO`. La cuenta `APP_ACADEMIA` se creó en FREEPDB1 como cuenta local, tal como confirma el valor `COMMON = NO`.

Evidencia: `03-cuenta-app.script.log`, consulta de `common_user_prefix` y fila de `APP_ACADEMIA`.

### 9. Comparación de las tres conexiones

| Conexión | ALL_TABLES de ADMIN_ACADEMIA | DBA_USERS | CDB_USERS por contenedor | V$DATAFILE |
|---|---:|---:|---|---:|
| C##OPS_RO en CDB$ROOT | 0 | 37 | 37 en CON_ID 1 y 47 en CON_ID 3 | 17 |
| C##OPS_RO en FREEPDB1 | 0 | 47 | 47 en CON_ID 3 | 10 |
| APP_ACADEMIA en FREEPDB1 | 1 | ORA-00942 | ORA-00942 | ORA-00942 |

Al conectar con C##OPS_RO desde la raíz pude ver usuarios de dos contenedores y 17 datafiles. Con la misma cuenta dentro de FREEPDB1 solo aparecieron los 47 usuarios de esa PDB y 10 datafiles. También observé el efecto de los permisos: APP_ACADEMIA podía ver ACA_ESTUDIANTES en ALL_TABLES porque tenía acceso a esa tabla, pero recibió ORA-00942 en las tres consultas de catálogo.

Evidencia: `04-tres-miradas.script.log`, miradas 1, 2 y 3.

### 10. Coste de los diez recorridos

Durante los diez recorridos se registraron 53.671 lecturas lógicas, unas 5.367 por recorrido. El tiempo de reloj fue de 0,52 segundos. En ese intervalo, el DB time aumentó 0,53 segundos y el DB CPU aumentó 0,47 segundos. La CPU representó aproximadamente el 89 % del DB time, así que la mayor parte del tiempo de base de datos medido se dedicó al procesamiento en CPU.

Evidencia: `04-deltas.script.log`, apartado 4.

### 11. ¿Cuánto espacio tenía TBS_ACADEMIA_HIST y qué medida usaría para alertar?

Antes de la carga, TBS_ACADEMIA_HIST tenía 10 MB asignados. Dentro de esos 10 MB quedaban 3,9 MB libres y el archivo podía crecer hasta un máximo de 40 MB. Para configurar las alertas usaría el porcentaje de ocupación sobre esos 40 MB, porque tiene en cuenta el margen de crecimiento del archivo. En mi medición inicial, la ocupación sobre el máximo era del 15,16 %. Los umbrales quedaron en el 80 % para aviso y el 95 % para alerta crítica.

Evidencia: `20261125T181603Z_05-almacenamiento.script.log`, apartados 2 y 7.

### 12. ¿Quién hizo el INSERT y a quién se le aplicó la cuota?

Ejecuté el INSERT como SYS sobre la tabla CARGA_HIST.REGISTRO. Al intentar reservar espacio para la tabla, Oracle comprobó la cuota de CARGA_HIST, propietario del segmento. El primer INSERT devolvió ORA-01950 porque ese usuario todavía no tenía cuota. Después le concedí 2 MB y la carga llegó a ese límite, lo que provocó ORA-01536. Aunque hubiera ampliado el tablespace, CARGA_HIST habría seguido limitado a 2 MB. Lo que había que ampliar era la cuota del propietario.

Evidencia: `20261125T181603Z_05-almacenamiento.script.log`, apartados 4 y 5. La consulta de cuotas mostró 2.097.152 bytes usados y el mismo valor como máximo.

### 13. ¿Cuánto duró la suspensión y qué registró Oracle?

En la primera ejecución, la carga terminó con 20.000 filas. La comprobación final mostró que CARGA_HIST utilizaba 23 MB y tenía una cuota de 30 MB. Duración de la suspensión en esta ejecución: 13,892 segundos, desde las 18:17:14.904 UTC («was suspended») hasta las 18:17:28.796 UTC («was resumed»).

En la segunda ejecución, CDB_RESUMABLE mostró la carga `carga-historico` en estado SUSPENDED por ORA-01536 a las 18:18:54 UTC. Esta vez se agotó el plazo configurado de 180 segundos: la aplicación recibió ORA-30032 y el alert log registró «was timed out». Esos 180 segundos corresponden al segundo intento.

Evidencias: `20261125T181714Z_05-resumable.script.log` y `20261125T181854Z_05-resumable.script.log`.

### 14. ¿Qué cambió con DELETE y con SHRINK SPACE?

Antes del DELETE, la tabla tenía 20.000 filas y su segmento ocupaba 3.840 bloques, equivalentes a 30 MB. Borré el 90 % de las filas y quedaron 2.000, pero Oracle seguía mostrando los mismos 3.840 bloques y 30 MB. El borrado dejó huecos reutilizables dentro del segmento y mantuvo el espacio asignado.

Después de ejecutar SHRINK SPACE seguía habiendo 2.000 filas, pero el segmento ocupaba 304 bloques, unos 2,4 MB. La compactación permitió bajar la marca de agua alta y devolver 3.536 bloques al tablespace. Así disminuyó el espacio consumido por el segmento, mientras que el límite de cuota del usuario siguió siendo de 30 MB.

Evidencia: `20261125T182616Z_05-hwm-shrink.script.log`, filas «antes del DELETE», «tras el DELETE» y «tras SHRINK SPACE».

### 15. ¿Qué valores tenía DEFAULT y qué límites de PRF_PERSONAS resultan útiles?

En mi base, el perfil DEFAULT permitía 10 intentos de conexión fallidos y fijaba el bloqueo en 1 día. La contraseña tenía una vigencia de 180 días y un periodo de gracia de 7 días. El límite de inactividad era de 365 días. PASSWORD_REUSE_MAX y PASSWORD_REUSE_TIME figuraban como UNLIMITED, PASSWORD_ROLLOVER_TIME valía 0 y PASSWORD_VERIFY_FUNCTION aparecía como NULL.

Para una cuenta de secretaría destacaría dos reglas de PRF_PERSONAS. La primera limita a 3 los intentos fallidos consecutivos: en la prueba, ANA_GARCIA pasó a LOCKED(TIMED), lo que frena los intentos repetidos de adivinar su contraseña. La segunda exige una contraseña con una complejidad mínima. Lo comprobé al intentar crear PRUEBA_DEBIL: Oracle devolvió ORA-28003 y el detalle ORA-20000 indicó que la contraseña tenía menos de 8 caracteres.

Evidencias: `06-gobierno-acceso.script.log`, apartados 1 y 2, y `06-probar-acceso.script.log`, prueba de bloqueo de ANA_GARCIA.

### 16. ¿Por qué Ana pudo leer ACA_MATRICULAS y qué pasó al cambiar un nombre?

ANA_GARCIA tenía el rol ROL_SECRETARIA_ACADEMIA, que a su vez incluía ROL_LECTURA_ACADEMIA. Este último concedía SELECT ANY TABLE dentro del esquema ADMIN_ACADEMIA. Por esa cadena de permisos pudo consultar ACA_MATRICULAS aunque nadie le hubiera concedido SELECT directamente sobre esa tabla.

Para modificar ACA_ESTUDIANTES, su permiso de UPDATE estaba limitado a la columna ESTADO. Cuando intentó cambiar la columna NOMBRES del estudiante 105, Oracle devolvió ORA-41900: missing UPDATE privilege. Así comprobé que poder actualizar el estado de un alumno no le daba permiso para modificar todos sus datos.

Evidencias: `06-gobierno-acceso.script.log`, apartado 6, y `06-probar-acceso.script.log`, prueba de actualización de NOMBRES.

### 17. ¿Qué objetos se invalidaron al cambiar las columnas?

Al añadir TELEFONO a ACA_EST_LAB6, las dos vistas y la función siguieron siendo válidas. Ninguna dependía de esa columna nueva. Al ampliar EMAIL_INSTITUCIONAL, la vista que dependía directamente de ella era V_CONTACTO_LAB6. En ese paso figuraban como INVALID: solo V_CONTACTO_LAB6.

Al ampliar NOMBRES, el cambio afectó a V_ACTIVOS_LAB6 y, a través de esa vista, a F_TOTAL_ACTIVOS_LAB6. En ese momento figuraban como INVALID: F_TOTAL_ACTIVOS_LAB6, V_ACTIVOS_LAB6 y V_CONTACTO_LAB6. Esta última ya estaba inválida desde el paso anterior. Para interpretar el resultado comparé ambos pasos, porque un objeto que ya estaba inválido podía seguir apareciendo así tras el siguiente cambio.

Evidencia: `20261125T182819Z_07-objetos.script.log`, apartados 2, 3 y 4.

### 18. ¿Mejoraría el rendimiento al aumentar la memoria?

Con la carga observada, el asesor estimó el mismo resultado para una SGA de 1.536 MB y para otra de 3.072 MB: el factor de DB time se mantuvo en 1 y las lecturas físicas estimadas fueron 37.953 en ambos casos. Por tanto, duplicar la SGA no ofrecía una mejora estimada para esa carga.

En la PGA, 384 MB fue el menor tamaño evaluado con 0 sobreasignaciones y un porcentaje de aciertos del 100 %. Al bajar a 256 MB aparecían 3 sobreasignaciones y el porcentaje de aciertos descendía al 72 %. Con 128 MB se repetía ese resultado.

Evidencia: `20261125T182912Z_07-memoria.script.log`, apartado 5.

### 19. ¿Cuántas lecturas lógicas hizo la consulta de la aplicación?

La consulta hizo 247 lecturas lógicas. Lo comprobé en la línea FETCH de la traza, donde aparece `cr=247`, y en el informe de TKPROF, que muestra `query=247` y `disk=0`. El campo `rows=1` corresponde a la única fila devuelta por COUNT(*). El valor de esa fila fue 17.600 estudiantes activos.

Evidencia: `20261125T182952Z_07-adr-trazas.script.log`, extracto de la traza e informe de TKPROF.

### 20. Diagnóstico, intervención y validación de los tres incidentes

- INC-601. La sesión 61 de ANA_GARCIA esperaba un bloqueo TX que retenía la sesión 207 de APP_ACADEMIA. Desde SYS se terminó la sesión bloqueadora. El alert log registra `KILL SESSION for sid=(207, 22478)` y el motivo `alter system kill session`. Al validar quedaban 0 sesiones de Ana bloqueadas y el estudiante 101 estaba ACTIVO.
- INC-602. El diagnóstico mostró `academia_app` con `ARRANCADO = NO`, mientras el listener seguía anunciando `freepdb1`. Arranqué el servicio y guardé el estado de la PDB. Después el listener mostró `READY` y confirmé que APP_ACADEMIA podía conectarse a FREEPDB1 por `academia_app`.
- INC-603. Antes de intervenir, APP_ACADEMIA figuraba como LOCKED a las 18:34, con el perfil DEFAULT y un límite de 10 intentos. SYS ejecutó `ALTER USER app_academia ACCOUNT UNLOCK` a las 18:34:13 UTC, según la auditoría de FREEPDB1. Para validar abrí una conexión nueva y comprobé los tres valores: usuario APP_ACADEMIA, PDB FREEPDB1 y servicio `academia_app`.

Evidencias: logs de diagnóstico `08` de cada incidente y `lab6-guardia.md`.

## Simulacro de examen 1Z0-182

- S1. B — Partes B.2 y F.1
- S2. C — Parte C.1
- S3. B — Parte C.1
- S4. B y C — Parte C.2
- S5. C — Partes C.2 y C.3
- S6. B — Parte C.2
- S7. A — Parte D.1
- S8. B — Parte D.3
- S9. C — Parte D.3
- S10. C — Parte D.3
- S11. B — Parte E.3
- S12. A y C — Parte E.3
- S13. B — Parte F.1
- S14. A y C — Parte F.1
- S15. A y C — Parte F.2
- S16. B — Parte F.3
- S17. B — Partes G.1 y G.2
- S18. B — Parte G.3
- S19. A y B — Parte H.1
- S20. B — Parte H.4
- S21. C — Parte H.4
- S22. C — Parte I.2
