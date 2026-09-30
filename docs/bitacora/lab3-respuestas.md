# Lab 3 — Respuestas de comprobación

## 1. Diferencia entre imagen y contenedor

Una imagen es la plantilla con los archivos y programas necesarios. Un contenedor es una instancia creada a partir de ella. En G2 ejecuté un contenedor de hello-world; en G4 creé el contenedor prueba desde alpine:3.20 y entré en su terminal.

## 2. Por qué nota.txt desapareció en G5 y permaneció en G6

En G5 guardé el archivo dentro del contenedor prueba. Al eliminar ese contenedor, eliminé también su capa de escritura. El nuevo contenedor prueba2 no contenía el archivo. En G6 lo guardé en el volumen datos-prueba, montado en /datos: el volumen sobrevivió y otro contenedor pudo leerlo.

## 3. docker ps, docker ps -a y Exited (0)

docker ps muestra los contenedores en ejecución. docker ps -a también muestra los detenidos. Exited (0) indica que el proceso principal terminó sin errores, como ocurrió con hello-world.

## 4. Orden de los puertos

En -p 8181:8181, el primer número es el puerto del equipo anfitrión y el segundo es el del contenedor. En nginx usamos -p 8080:80. Con -p 80:8080 enviaríamos las peticiones al puerto 8080 del contenedor, donde nginx no estaba escuchando.

Publicar un puerto no crea un servicio. En nuestra imagen de Oracle no había ORDS en 8181; instalamos ORDS aparte en Ubuntu y utiliza el puerto 8080.

## 5. Por qué Oracle continúa y hello-world termina

Un contenedor permanece en ejecución mientras su proceso principal sigue activo. hello-world imprime un mensaje y termina. Oracle mantiene el proceso de la base de datos funcionando para atender conexiones.

## 6. Digest y etiqueta latest

El digest es un identificador calculado a partir del contenido de una imagen. La etiqueta latest puede apuntar a otra imagen en el futuro, por lo que registrar el digest permite identificar exactamente la que utilizamos.

En mi instalación:
sha256:f988b0c04c4c386cd306a2a914c0d7a9702d83acc31b064a28ad8eb6278a8fba

## 7. Qué borraría los datos de Oracle

El comando docker volume rm oralab-26ai-data eliminaría el volumen y sus datos cuando ningún contenedor lo estuviera utilizando. Docker rechaza eliminar un volumen en uso. No debo ejecutar ese comando sobre el volumen del curso.

docker rm oralab-26ai elimina el contenedor, pero conserva el volumen con nombre donde están los archivos de Oracle.

## 8. Por qué usamos el repositorio, un Issue, una rama y un PR

Así mantenemos el historial de los laboratorios y podemos revisar y reproducir los cambios. El Issue describe la tarea, la rama separa el trabajo de main y el Pull Request permite revisarlo antes de integrarlo. En mi caso usamos el Issue #5 y la rama chore/5-install-oracle-environment.

## 9. Diferencia entre source y bash

source ejecuta el archivo en la shell actual, dejando disponibles sus variables y funciones. bash lo ejecuta en un proceso hijo, cuyos cambios de entorno no pasan a la shell que lo lanzó. Usamos source para disponer de CONT_NAME, EVID y la función ts en los comandos posteriores.

## 10. Partes del nombre de una evidencia

En 20260915T091230Z_02-docker.script.log:
- 20260915 es la fecha: 15 de septiembre de 2026.
- T separa la fecha de la hora.
- 091230 es la hora: 09:12:30.
- Z indica UTC.
- 02 es el número del paso.
- docker describe la comprobación.
- .script.log indica una evidencia de terminal.

## 11. Función de .gitattributes

Define finales de línea LF para los archivos .sh, .sql y .md. Evita diferencias entre Windows y Linux y errores al ejecutar scripts con finales CRLF, como mensajes que contienen \r o indican que no se encuentra un comando.

## 12. Por qué Create a merge commit

Conserva los commits de cada parte y añade un commit de integración. Así se puede revisar cómo avanzó la práctica y relacionar cada cambio con su evidencia. Squash and merge reuniría los commits de la rama en uno y perderíamos ese detalle en main.

## 13. Las cuatro capas de la estrategia de contraseñas

Primero configuramos .gitignore para excluir config/.env. Después creamos config/.env.example con valores ficticios. En tercer lugar creamos config/.env con los valores reales y comprobamos que Git lo ignora. Finalmente cargamos las contraseñas mediante variables de entorno.

Si omitimos la primera capa, podríamos añadir accidentalmente el archivo privado a un commit y exponerlo en el historial.

## 14. Por qué no escribir la contraseña en docker run

El comando escrito puede quedar guardado en el historial de la terminal, aunque el script no se publique. Usamos variables cargadas desde config/.env para evitar escribir el valor literal en los comandos. Esto no sustituye los controles de acceso al equipo ni al motor Docker.

## 15. Contraseña publicada en un commit

Borrarla en un commit nuevo no basta: sigue presente en el historial. Hay que cambiar o revocar inmediatamente la credencial expuesta, actualizar los servicios que la utilizan y avisar al docente para coordinar la limpieza del historial. La contraseña antigua debe considerarse comprometida.

## 16. SQL*Plus dentro del contenedor: SPOOL y @archivo.sql

SPOOL escribiría dentro del contenedor y @archivo.sql buscaría allí el archivo SQL. Nuestros scripts y evidencias están en el repositorio de Ubuntu. Por eso enviamos el SQL con la redirección < y guardamos la salida con tee desde Ubuntu. Con SQLcl instalado en Ubuntu sí usamos SPOOL directamente.

## 17. Función de WHENEVER SQLERROR EXIT SQL.SQLCODE

Hace que SQL*Plus termine con un código de error cuando falla una sentencia SQL o PL/SQL. El script de migraciones detecta ese fallo y se detiene. Sin esta instrucción podría seguir ejecutando sentencias sobre una instalación incompleta.

No deshace automáticamente el DDL que ya se haya aplicado; por eso revisamos el estado antes de repetir una migración fallida.

## 18. Qué es una migración y por qué no editarla después

Es un archivo SQL numerado y versionado que modifica la estructura de la base de datos. V000 creó los tablespaces y usuarios; V001 creó las tablas e índices. Editarlas después de aplicarlas haría que el archivo dejara de representar lo ejecutado. Las modificaciones posteriores deben registrarse en una migración nueva.

## 19. Por qué usamos FREEPDB1

FREEPDB1 es el servicio de la base de datos conectable donde están nuestros usuarios y tablas. FREE corresponde al servicio del contenedor raíz. Un SID identifica la instancia y no selecciona por sí mismo la PDB de trabajo. Por eso configuramos Nombre del servicio = FREEPDB1.

## 20. SQLcl frente a SQL*Plus

SQLcl ofrece funciones modernas como autocompletado, formatos de salida, conexiones guardadas e integración con Liquibase. En la práctica usé ansiconsole y guardé la conexión oralab26-system sin contraseña.

SQL*Plus es una herramienta clásica muy habitual en servidores y estaba disponible dentro del contenedor. Conviene dominar ambas para trabajar tanto en el entorno diario como en tareas de administración y diagnóstico.

## 21. Por qué pasamos de Git Bash a Ubuntu en WSL 2

Ubuntu ofrece un entorno Linux con herramientas similares a las de un servidor. Evita problemas de Git Bash como errores de terminal interactiva al utilizar docker run -it y la conversión automática de rutas Linux a rutas de Windows al pasar argumentos a Docker.

También permite instalar y utilizar de forma coherente herramientas como tmux, shellcheck y ORDS.

## 22. Por qué trabajar en /home y utilizar Bash

Clonamos el repositorio en ~/oracle-database-lab, dentro del sistema de archivos Linux, para tener permisos, enlaces y rendimiento adecuados para sus herramientas. /mnt/c permite acceder a Windows y lo usamos para copiar las capturas, pero no como ubicación principal del proyecto.

Bash coincide con el intérprete y los ejemplos del curso. Zsh tiene diferencias de comportamiento, por ejemplo al expandir patrones. Usar Bash reduce incompatibilidades y permite reproducir los mismos comandos.
