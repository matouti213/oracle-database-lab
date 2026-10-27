# Lab 5 — Oracle DBA Workflow II

**Estudiante:** Amine · **GitHub:** matouti213 · **Trabajo individual**  
**Repositorio:** https://github.com/matouti213/oracle-database-lab  
**Issue:** #9 · **Rama:** `chore/5-oracle-dba-workflow-ii`  
**Ejecuciones:** 26–27 de octubre de 2026. Los nombres de evidencia usan UTC.

## Alcance y trazabilidad

Respuestas basadas en las salidas originales guardadas en `docs/bitacora/lab5/evidencia/`. Algunas salidas muestran `??` por codificación; se conservan sin alterar y aquí se normaliza la redacción. Los datos, planes y tiempos son los observados, no los valores de ejemplo del PDF. La verificación técnica final da TODO OK; la revisión de seguridad, el PR, su revisión y la etiqueta/copia final son pasos de cierre independientes.

## Preguntas de comprobación

### 1. Copias lab3-final y lab4-final

El manifiesto de la copia `20261026T174113Z_lab3-final`, asociado al commit `03f90cd`, registra `archivos_fuera_del_volumen=0`. La copia del Lab 4 también indica que el volumen contiene toda la base de datos y no necesita archivos externos.

Por tanto, en mis dos copias el número de archivos externos es cero. Esto confirma que los archivos inventariados estaban dentro del volumen en ambos puntos de respaldo. No demuestra una reubicación entre esas dos copias ni coincide con el ejemplo del enunciado que parte de archivos externos.

Evidencias: manifiesto de Lab 3 transcrito en `lab5/evidencia/config/lab3-final-manifiesto.txt` y salida `lab5/evidencia/script/20261026T230439Z_00-backup-lab4.script.log`.

### 2. Factor de bloqueo de TiendaSur

CLIENTE: 100.000 / 1.517 = **65,92**, aproximadamente **66 filas/bloque**, con 102 bytes por fila. PEDIDO: 1.000.000 / 5.320 = **187,97**, aproximadamente **188 filas/bloque**, con 32 bytes por fila. PEDIDO admite unas 2,85 veces más filas por bloque porque sus filas son más cortas. Son medias: cabeceras, espacio reservado y ocupación explican que no coincidan exactamente con dividir 8.192 por la longitud de fila.

Evidencia: [20261026T230903Z_01-perfil-tiendasur.script.log](lab5/evidencia/script/20261026T230903Z_01-perfil-tiendasur.script.log).

### 3. Dos ejecuciones por sentencia

La primera calienta la caché y absorbe trabajo inicial como análisis y limpieza diferida; se mide la segunda para comparar condiciones similares. Esto no reproduce necesariamente una carga en frío. En la búsqueda del pedido 4711 se midieron **4 Buffers** con acceso a tabla y **3** al solicitar solo la clave cubierta por el índice.

Evidencia: [20261026T231033Z_02-anatomia-indice.script.log](lab5/evidencia/script/20261026T231033Z_02-anatomia-indice.script.log).

### 4. Altura y ramificación

IX_PED_CLIENTE tiene **altura 3, 2.216 hojas y 6 bloques de rama**. La ramificación media calculada es (2216 + 6 − 1) / 6 ≈ **370**; la capacidad máxima estimada es **543**. Con mil millones de filas, el modelo del ejercicio estima unas 2.208.969 hojas y **altura 4**: unas cinco lecturas para buscar una fila incluyendo su bloque de tabla. Es una proyección, no una carga ejecutada de mil millones de filas.

Evidencia: [20261026T231033Z_02-anatomia-indice.script.log](lab5/evidencia/script/20261026T231033Z_02-anatomia-indice.script.log).

### 5. ROWID de una entrada de hoja

En PK_CLIENTE, `row#0` contiene `data:(6): 00 00 03 1b 00 00` y clave `c1 02`, que corresponde al cliente 1. Los primeros cuatro bytes representan el bloque hexadecimal **0x31B = 795**; los dos últimos, la **ranura 0**. Es la representación corta del ROWID en este índice sobre un tablespace BIGFILE: hay un único datafile por tablespace y no se necesita codificar aquí un número de archivo separado. La consulta DBMS_ROWID confirma bloque 795 y ranura 0.

Evidencia: [20261026T231033Z_02-anatomia-indice.script.log](lab5/evidencia/script/20261026T231033Z_02-anatomia-indice.script.log).

### 6. Tres comparaciones de tipos de índice

1. **DNI único:** Q13 pasa de **1.486 a 3 lecturas**; evita el recorrido completo y además impide duplicados (ORA-00001 observado).
2. **Historial cubierto:** Q7 pasa de **15** lecturas con IX_PED_CLIENTE a **7** con (cliente, fecha) y **3** con el índice cubriente: elimina la ordenación y finalmente el salto a la tabla.
3. **Sesiones:** heap + PK consume **4**, IOT **3** y clúster hash **1** lectura para igualdad de token. El hash no gana para cualquier consulta: la limpieza por caducidad requiere **2.770 lecturas** y recorrido completo.

Evidencia: [20261026T231104Z_03-tipos-indice.script.log](lab5/evidencia/script/20261026T231104Z_03-tipos-indice.script.log).

### 7. Clustering factor y REBUILD

IX_PED_FECHA tiene **CF 5.220**, próximo a los **5.320 bloques**; IX_PED_CLIENTE tiene **CF 999.041**, próximo al millón de filas. Los pedidos se cargaron ordenados por fecha, mientras los clientes se distribuyeron de forma pseudoaleatoria. El CF mide cambios de bloque al seguir el orden del índice, contando nuevas visitas, no solo bloques únicos. Reconstruir el índice no reordena las filas de la tabla y no corrige por sí solo ese agrupamiento.

Evidencia: [20261026T231033Z_02-anatomia-indice.script.log](lab5/evidencia/script/20261026T231033Z_02-anatomia-indice.script.log).

### 8. Punto de equilibrio medido

Con CF malo, a **0,5 %** se consumen **4.875** lecturas y a **1 %**, **9.920**, frente a **5.232** del recorrido completo: el cruce está entre esos puntos. La aproximación 1/188 ≈ **0,53 %** es coherente. Con CF bueno aún gana al **50 %** (3.938 lecturas), pero pierde al **100 %** (7.875): no se midió el cruce exacto entre ambos. El optimizador escoge FULL desde **0,2 %** para CF malo; su coste estimado no equivale solo al recuento de lecturas lógicas. Con relación de costes secuencial/aleatorio de 1/5, la aproximación teórica baja a **0,11 %**, no una medición adicional del disco.

Evidencia: [20261026T231145Z_04-agrupamiento-equilibrio.script.log](lab5/evidencia/script/20261026T231145Z_04-agrupamiento-equilibrio.script.log).

### 9. Gonz%: sargable no significa barato

Q4b devuelve **2.056 filas** mediante INDEX RANGE SCAN y consume **2.024 lecturas**: encontrar las claves es eficiente, pero recuperar filas dispersas de CLIENTE cuesta muchas visitas a bloques. En la evidencia, Q4a recorre toda CLIENTE con **1.523 lecturas**, aunque es otro predicado y devuelve otras filas; no es una comparación de tiempos equivalente para la misma consulta. Poder usar un índice no garantiza que minimice las lecturas.

Evidencia: [20261026T231234Z_05-sargabilidad.script.log](lab5/evidencia/script/20261026T231234Z_05-sargabilidad.script.log).

### 10. Coste de escritura y propuesta rechazada

INSERT modifica **10,2 / 20,2 / 12,1 bloques por fila** con 4 / 9 / 5 índices respectivamente. Se rechaza añadir indiscriminadamente los cinco índices: IX_PED_CANAL no se usó y tiene solo 3 valores; IX_PED_FEC_CLI no se usó y duplica el prefijo de fecha ya atendido; se prefiere el cubriente a mantener IX_PED_CLI_FEC y IX_PED_CLIENTE juntos. IX_PED_ESTADO se usó para pendientes, pero se sustituye por el parcial, y sí se conserva el índice de código postal. IX_PED_IMPORTE no se usó en la ventana probada; Q2 mantuvo **318 lecturas** al hacerlo invisible. No equivale a demostrar ausencia de uso en cualquier carga futura. V005 aumenta UPDATE estado de **2 a 8,1 bloques/fila**: las mejoras de lectura tienen un coste de mantenimiento explícito.

Evidencia: [20261027T135525Z_06-indices.script.log](lab5/evidencia/script/20261027T135525Z_06-indices.script.log).

### 11. Divisiones y patrón cola

AZAR registra **595 divisiones, ninguna 90/10**, 596 hojas y **75,4 %** de ocupación viva: huecos repartidos por el árbol, compatibles con divisiones aproximadamente 50/50. CRECIENTE registra **398 divisiones 90/10**, 399 hojas y **99,9 %** de ocupación: hojas anteriores llenas y crecimiento por el extremo. REVERSE presenta 512 hojas, **77,9 %** de ocupación y pierde el acceso por rango (878 lecturas frente a 4 del normal). En la cola hay **433 hojas, 232 vacías, 72.238 entradas borradas y 46,2 % de ocupación viva**: el mapa muestra el extremo izquierdo vacío. No es el mismo patrón que huecos distribuidos.

Evidencia: [20261027T135647Z_07a-crecimiento.script.log](lab5/evidencia/script/20261027T135647Z_07a-crecimiento.script.log).

Gráficos de apoyo: [20261027T135647Z_07a-grafico-IX_AZAR.script.log](lab5/evidencia/script/20261027T135647Z_07a-grafico-IX_AZAR.script.log), [20261027T135647Z_07a-grafico-IX_CRECIENTE.script.log](lab5/evidencia/script/20261027T135647Z_07a-grafico-IX_CRECIENTE.script.log), [20261027T135647Z_07b-grafico-IX_COLA-antes.script.log](lab5/evidencia/script/20261027T135647Z_07b-grafico-IX_COLA-antes.script.log).

### 12. Remedio para la cola

Elegiría primero **COALESCE** para consolidar hojas y recuperar eficiencia durante el servicio: en la prueba pasa de **234 a 2 lecturas**, de 433 a 201 hojas y elimina las entradas borradas, manteniendo 4 MB asignados. Si también necesito devolver espacio, evaluaría SHRINK SPACE: deja **1,69 MB** y 2 lecturas. REBUILD ONLINE deja 2 MB, 223 hojas y las mismas 2 lecturas; aquí no añade beneficio de lectura respecto de COALESCE y exige más trabajo. Las operaciones online pueden necesitar bloqueos breves de metadatos; no deben presentarse como garantía absoluta de cero bloqueo. Como solución de diseño, evaluaría particiones temporales para retirar lotes completos.

Evidencia: [20261027T135647Z_07c-remedios.script.log](lab5/evidencia/script/20261027T135647Z_07c-remedios.script.log).

### 13. SCN y apertura

Se contrasta el SCN de checkpoint registrado para el datafile en el control file con el de su cabecera, además de otros metadatos de recuperación. Antes: **4.596.138** en ambos para SYSTEM, SYSAUX y ACADEMIA consultados. Después del checkpoint: **4.602.715**, con CURRENT_SCN **4.602.920**. PDB$SEED conserva **2.098.101** al ser de solo lectura. Que CURRENT_SCN supere al checkpoint es normal; la actividad continúa.

Evidencia: [20261027T135734Z_08-scn-checkpoint.script.log](lab5/evidencia/script/20261027T135734Z_08-scn-checkpoint.script.log).

### 14. Protección del control file

Hay **tres copias** en el mismo volumen. La multiplexación permite reparar la pérdida individual de control03.ctl copiando control01.ctl con la base sin montar; no protege contra perder el volumen completo. En producción se distribuyen las copias en dominios de fallo independientes y se mantienen backups. El simulacro B volvió a servicio en **5 s** desde el inicio de la parada.

Evidencia: [20261027T141255Z_14b-perdida-controlfile.script.log](lab5/evidencia/script/20261027T141255Z_14b-perdida-controlfile.script.log).

### 15. Estados del redo y corrección del kit

CURRENT es el grupo que LGWR está usando; ACTIVE ya no es actual pero todavía puede necesitarse para recuperación de instancia; INACTIVE ya no es necesario para esa recuperación. En la evidencia, tras los cambios, grupo 1/secuencia 19 era CURRENT y los grupos 2/17 y 3/18 eran ACTIVE. El nuevo miembro redo02b quedó INVALID hasta otro ciclo de escritura; la verificación posterior lo confirmó válido.

**Corrección del enunciado:** no es correcto asegurar que los tres borrados del paso 4 siempre fallan. Borrar el grupo CURRENT no está permitido y hay restricciones al retirar miembros de grupos activos; pero con **tres grupos**, retirar un grupo INACTIVE elegible puede dejar **dos**, no uno, y ser válido. Se omitió el bloque de borrados y se documentó el motivo en el script. No se simula una evidencia de tres rechazos que no se ejecutaron.

Evidencia: [20261027T135926Z_10-redo.script.log](lab5/evidencia/script/20261027T135926Z_10-redo.script.log).

### 16. Cadena de la FRA llena

Se redujo el límite a **2 MB**. El alert log informó ORA-19815 al 100 % y ORA-19809; ARCHIVE LOG CURRENT devolvió ORA-16038 para la secuencia **22**. El grupo no podía archivarse. Si la carga sigue y se agotan grupos reutilizables, los switches y las sesiones pueden esperar por archivado. En mi ejecución se observó el fallo de archivado; no se afirma haber medido una parada general de todo DML. Al devolver **4.096 MB**, las secuencias **22 y 23** quedaron archivadas y el uso fue **8,2 MB**.

Evidencia: [20261027T140242Z_11-fra-llena.script.log](lab5/evidencia/script/20261027T140242Z_11-fra-llena.script.log).

### 17. Lectura consistente frente a bloqueos

A cambió la fila 101 a EGRESADO sin confirmar; B leyó **ACTIVO** mediante consistencia de lectura. A consumía **1 bloque y 1 registro de undo**, con TM modo 3 y TX modo 6. El SELECT ordinario no necesitó bloquear la fila, pero SELECT FOR UPDATE WAIT 3 sí solicitó un bloqueo y devolvió **ORA-00054/ORA-40097**. Tras COMMIT, B leyó EGRESADO; AS OF TIMESTAMP recuperó ACTIVO y la reparación dejó ACTIVO. La frase lectores no bloquean escritores se refiere a lecturas consistentes ordinarias, no a SELECT FOR UPDATE.

Evidencia: [20261027T140353Z_12-lectura-consistente.script.log](lab5/evidencia/script/20261027T140353Z_12-lectura-consistente.script.log).

### 18. Undo, redo y ROLLBACK

Para 10.000 filas, INSERT usó **141 bloques de undo** y 4.859 KB de redo; UPDATE, **71 bloques** y 1.258 KB; DELETE, **427 bloques** y 6.627 KB. DELETE necesita información para reponer filas y entradas de índices; INSERT necesita información para retirar lo añadido. UPDATE conserva los valores previos afectados. Los bloques de undo también deben poder rehacerse tras una caída, por eso sus cambios generan redo. Los ROLLBACK generaron **355, 751 y 4.701 KB** respectivamente: deshacer también aplica cambios persistentes. Los bloques asignados a undo y los bytes de vectores de cambio de undo son métricas distintas.

Evidencia: [20261027T140535Z_12-undo-y-redo.script.log](lab5/evidencia/script/20261027T140535Z_12-undo-y-redo.script.log).

### 19. Garantía tras COMMIT y checkpoint

Tras UPDATE + COMMIT se midieron **7.173 KB de redo, 10 escrituras LGWR, 1 commit, 0 bloques escritos por DBWn y 231 bloques sucios** de la tabla. La garantía estaba en el redo persistido, no en que las páginas modificadas estuvieran ya escritas. Tras el checkpoint: **562 bloques escritos por DBWn y 0 sucios** de esa tabla. Son contadores de toda la instancia; 562 no debe atribuirse íntegramente a ACA_ESTUDIANTES.

Evidencia: [20261027T140611Z_13-lgwr-dbwn.script.log](lab5/evidencia/script/20261027T140611Z_13-lgwr-dbwn.script.log).

### 20. Roll forward y roll back

La fila **102 quedó EGRESADO**, porque tenía COMMIT, y **103 ACTIVO**, porque el cambio a INACTIVO no estaba confirmado. El alert log muestra Beginning crash recovery, lectura de **1.563 KB de redo**, **228 bloques** que requieren recuperación, aplicación de **0,85 MB** y Completed crash recovery. Roll forward rehace los cambios necesarios, incluido undo; roll back deshace transacciones no confirmadas. La fila 102 se devolvió después a ACTIVO. El arranque hasta disponibilidad tardó **2 s**.

Evidencia: [20261027T141211Z_14a-caida-instancia.script.log](lab5/evidencia/script/20261027T141211Z_14a-caida-instancia.script.log).

### 21. Comparación de recuperación C y D

C restauró el volumen completo en **50 s**, recuperando **60.000 matrículas**. Su ventana calculada entre marca de copia y fallo fue **1 s**; es aproximada (la marca se toma después de terminar el backup) y no demuestra un número de filas perdidas. La restauración vuelve al estado de la copia sin aplicar aquí redo posterior. D restauró solo el datafile 16 y aplicó redo: **7 s de reparación, 8 s desde el fallo**, y la fila 104 seguía EGRESADO aunque se confirmó después del backup: **RPO observado 0**. En D FREEPDB1 estaba MOUNTED y se reabrió: quedó afectada toda la PDB, no únicamente ACADEMIA.

Evidencia: [20261027T141829Z_14d-perdida-datafile.script.log](lab5/evidencia/script/20261027T141829Z_14d-perdida-datafile.script.log).

### 22. Clasificación de errores del informe de salud

**Efectos del laboratorio:** ORA-00202 y el mensaje abreviado ORA-205 al montar corresponden a la pérdida de control03.ctl; ORA-01110 (archivo 16) y ORA-63999 corresponden al fallo de medio provocado. ORA-01113 menciona el archivo 25 (TiendaSur): no debe confundirse con el 16 ni asignarle una causa exacta sin más trazas. La comprobación SQL posterior aportada en el chat identificó ambos ONLINE, V$RECOVER_FILE vacío y cabeceras sin error ni RECOVER=YES: es un aviso histórico, no recuperación pendiente actual.

**Advertencias del entorno por revisar si reaparecen:** ORA-00800 con Set Priority Failed para LGWR/VKTM indica fallo al solicitar prioridad de proceso. No se demostró impacto funcional; se clasifica como advertencia del contenedor, no como corrupción ni como ruido que pueda ignorarse siempre. Se revisarán trazas/permisos si persiste; no se amplían privilegios del contenedor sin diagnóstico. **Incidente activo confirmado:** ninguno en las comprobaciones de recuperación y disponibilidad realizadas.

Evidencia: [20261027T142001Z_15-healthcheck.spool.log](lab5/evidencia/spool/20261027T142001Z_15-healthcheck.spool.log).

## Comparación RTO/RPO y retrospectivas

Los intervalos medidos tienen puntos de inicio distintos; no se comparan como si fueran el mismo cronómetro. RTO/RPO se usan aquí como medidas del ejercicio, no como objetivos de servicio contratados.

| Caso | Tiempo observado | Pérdida/ventana observada | Alcance |
|---|---|---|---|
| A: caída de instancia | 2 s desde inicio de arranque hasta disponible | 0 cambios confirmados perdidos en la prueba | Instancia |
| B: control file perdido | 5 s desde inicio de parada hasta disponible | Sin pérdida observada | Instancia |
| C: tabla con PURGE | 50 s de restauración | Regreso al backup; ventana aproximada impresa: 1 s | Volumen completo |
| D: datafile perdido | 7 s de reparación; 8 s desde fallo | RPO observado 0; fila 104 posterior al backup recuperada | Toda FREEPDB1, que se cerró |

### Retrospectiva A

Impacto: parada brusca de la instancia. Detección: SHUTDOWN ABORT y mensajes de crash recovery. Causa: fallo provocado. Recuperación: STARTUP, aplicación de redo y reversión de lo no confirmado. Resultado: 102 EGRESADO y 103 ACTIVO; 102 normalizada después. Mejora: medir también desde el instante exacto del fallo y comprobar una consulta de negocio, además de disponibilidad.

### Retrospectiva B

Impacto: arranque detenido antes de MOUNT. Causa: control03.ctl eliminado tras parada limpia. Diagnóstico: ORA-00205 y alert log identificando control03.ctl. Recuperación: copiar control01.ctl sano y ejecutar MOUNT/OPEN. Mejora: separar las copias por dominios de fallo en un entorno real; tres archivos en un mismo volumen no protegen de perderlo.

### Retrospectiva C

Impacto: ACA_MATRICULAS desaparece; la restauración completa interrumpe toda la base. Primero FLASHBACK TABLE recuperó 60.000 filas tras DROP sin PURGE. Después, DROP PURGE hizo necesario el camino de backup usado en el ejercicio. Recuperación: copia en frío completa y verificación de 60.000 matrículas. Mejora: restringir PURGE y evaluar recuperación selectiva/PITR antes de retroceder toda la base. No se afirma que un backup en frío sea la única alternativa posible a PURGE.

### Retrospectiva D

Impacto: archivo 16 inaccesible y cierre de FREEPDB1 por protección. Detección: ORA-01116/01110/27041, estado MOUNTED y fallo de medio. Recuperación: RMAN RESTORE y RECOVER del archivo, ONLINE y apertura de la PDB. Resultado: 20.000 estudiantes y fila 104 EGRESADO posterior a la copia; al final 104 ACTIVO. Mejora: validar regularmente las copias y conservar redo necesario; monitorizar cambios de estado de la PDB, no asumir que el fallo queda limitado al tablespace.

### Retrospectiva de mi FRA llena (Parte L.2)

Impacto observado: fallo de archivado de la secuencia 22. Causa: reducción deliberada de la cuota a 2 MB. Detección: ORA-19815/19809 y ORA-16038. Mitigación: restituir 4 GB y volver a archivar; secuencias 22/23 archivadas, 8,2 MB usados. Mejora: alertar por porcentaje de uso y ritmo de crecimiento antes de repetir cargas. No fue necesario borrar archivados.

### Análisis del caso narrado por el profesor (Parte L.3)

Es un caso del enunciado, no otro incidente medido en mi equipo: repetir cargas con ARCHIVELOG puede llenar la FRA y provocar esperas por archivado. La mejora es monitorizar ocupación y política de retención/copia. El borrado indiscriminado de archivados no debe extrapolarse a producción ni usarse si rompe la cadena necesaria para recuperar.

## Simulacro S1–S26

Respuestas razonadas al enunciado. La columna «Parte» indica dónde se estudió el concepto; cuando no hubo una ejecución específica se indica expresamente, sin inventar evidencia.

| Pregunta | Respuesta | Justificación | Parte / comprobación |
|---|---|---|---|
| S1 | B | CF próximo a filas implica muchas visitas a bloques al seguir el índice. | E: CF 999.041 |
| S2 | A y C | Índice funcional sobre UPPER o normalizar el parámetro si los datos están en minúsculas. | D/F: 1.486 a 4 lecturas |
| S3 | B | La conversión implícita aplica TO_NUMBER a la columna de texto. | F: predicado mostrado |
| S4 | B | Bitmap encaja en filtros de baja cardinalidad con poca concurrencia de escritura. | D: 4.073 a 528 lecturas |
| S5 | B | Puede utilizar INDEX SKIP SCAN sin filtrar la primera columna. | D: Q6 solo ciudad, 144 lecturas |
| S6 | B | INVISIBLE permite evaluar su retirada y volver a VISIBLE rápidamente. | G: IX_PED_IMPORTE |
| S7 | A y C | COALESCE consolida hojas; SHRINK SPACE también puede devolver espacio. Online no implica ausencia absoluta de bloqueos breves. | H: 234 a 2 lecturas |
| S8 | B | REVERSE distribuye claves secuenciales, pero pierde el orden útil para rangos. | H: 4 frente a 878 lecturas |
| S9 | C | Un UPDATE de columna no indexada no mantiene las entradas de los índices que no dependen de ella. | G/M: caso de columna no indexada |
| S10 | B | La ramificación condiciona el crecimiento logarítmico de la altura. | C: fan-out 370/543 |
| S11 | A y C | La IOT guarda los datos en el índice primario y evita un salto a heap. | D: 4 frente a 3 lecturas |
| S12 | B | Se contrastan los checkpoints del control file y la cabecera. | I |
| S13 | C | CKPT registra información de checkpoint; DBWn escribe bloques. | I/N; función conceptual de CKPT |
| S14 | B y E | En NOMOUNT hay instancia y parámetros, pero aún no control file montado/diccionario abierto. | O-B: instancia STARTED; consultas completas son teóricas |
| S15 | B | El cambio de modo se hace en MOUNT, seguido de OPEN. | L: secuencia del kit; mi base ya estaba ARCHIVELOG |
| S16 | B | CLEAR LOGFILE puede recrear ese grupo INACTIVE ya archivado; hay que confirmar requisitos y disponibilidad del archivo/destino. | K, respuesta teórica: no se provocó este fallo |
| S17 | A y C | Undo permite lectura consistente y Flashback Query. | M: 101 ACTIVO histórico |
| S18 | B | Tras una caída hay que rehacer también undo antes de deshacer transacciones pendientes. | M: vectores undo y redo medidos |
| S19 | A | Con el COMMIT síncrono del ejercicio, el redo está persistido en el redo online. | N: 0 escrituras DBWn y 231 bloques sucios tras COMMIT |
| S20 | A | Un objetivo MTTR menor aumenta el esfuerzo de checkpoint para reducir recuperación; no garantiza un tiempo exacto. | I: conceptual, no se modificó a 30 |
| S21 | B | Si ARCn no puede archivar, pueden agotarse los grupos reutilizables. | L: FRA llena |
| S22 | B | Si la base/PDB sigue abierta, aislar el datafile de aplicación permite reparar manteniendo el resto del servicio. | O-D: en mi caso Oracle cerró la PDB; se reparó montada |
| S23 | B | SYSTEM exige recuperación con la base montada; no se trata como un datafile de aplicación cualquiera. | O, caso teórico: no se dañó SYSTEM |
| S24 | B | Entre las opciones del test, restaurar copia consistente y perder lo posterior es la respuesta prevista sin cadena de archivados. No es una regla absoluta sobre todos los escenarios posibles con redo aún disponible. | O-C y contraste conceptual con NOARCHIVELOG |
| S25 | B y D | Más capacidad/retención de undo y, si procede, RETENTION GUARANTEE protegen la lectura histórica; la garantía puede hacer fallar escrituras si falta espacio. | M/P: no se provocó ORA-01555 |
| S26 | A | V$RECOVERY_AREA_USAGE desglosa ocupación por tipo de archivo. | L/P |

## Ajustes y límites del trabajo

- Trabajo realizado individualmente. Una segunda cuenta del mismo autor no equivale a revisión independiente; la adaptación debe quedar explícita en el PR y ajustarse a lo admitido por el profesor.
- El script K omite las pruebas de borrado cuya premisa era incorrecta con tres grupos. Fue necesario un tercer cambio de log para inicializar redo02b.
- Se completaron ejercicios adicionales del kit v3 del Lab 4 antes de TiendaSur; la etiqueta antigua lab4-final no se ha movido automáticamente.
- Los contadores de instancia incluyen actividad de fondo. Los tiempos breves y la caché del SO no son una medida de latencia física pura del disco.
- La comprobación adicional del estado de archivos 16 y 25 se aportó por terminal en la conversación; conviene guardarla también como evidencia antes del PR.

## Estado del cierre

La evidencia 16 acredita TODO OK técnico: 100.000/1.000.000 filas, MEDIR válido, V005, tres control files, redo multiplexado, FRA persistente de 4 GB, RMAN completado, filas 101/102/104 ACTIVO y 60.000 matrículas. Quedan por realizar y verificar fuera de este documento: revisión de secretos e historial, PR, revisión, merge commit, publicación de lab5-final y copia final íntegra. No se declaran realizados antes de ejecutarlos.
