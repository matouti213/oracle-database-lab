Laboratorio 1 - Git Fundamentals
Nombre: AMINE TOUTI

Preguntas de comprobacion



1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de un archivo pasando por las tres.

El Working Directory es donde tengo los archivos del proyecto y los puedo modificar normalmente.

La Staging Area es una zona intermedia donde pongo los archivos que quiero guardar en el siguiente commit usando git add.

El Local Repository es donde Git guarda los commits que ya he hecho.

Por ejemplo, cuando modifiqué README.md, primero estaba en el Working Directory. Después hice:

git add README.md

y pasó a la Staging Area. Finalmente hice:

git commit

y el cambio se guardó en el repositorio local.




2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica por qué.

No. Si modifico un archivo pero no hago git add, el cambio no entra en el siguiente commit.

Esto pasa porque git commit solo guarda lo que está preparado en la Staging Area.

Lo comprobé cuando creamos docs/customer-schema.md e intentamos hacer un commit sin haber hecho primero git add. Git no hizo el commit.




3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?

Porque Git no guarda carpetas vacías, solamente guarda archivos.

Para solucionarlo pusimos archivos llamados .gitkeep dentro de las carpetas vacías. Así Git ya tenía un archivo que podía guardar y las carpetas podían aparecer después en GitHub.




4. Explica con tus palabras qué es HEAD.

HEAD es como un puntero que me indica dónde estoy actualmente dentro del historial de Git.

Normalmente apunta a la branch en la que estoy trabajando y, por tanto, al último commit de esa branch.

Por ejemplo, cuando estaba en:

feature/customer-search

HEAD apuntaba a esa branch.




5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?

mkdir crea una carpeta física en el disco.

En cambio:

git switch -c nombre

crea una nueva branch de Git y cambia a ella. Una branch no es una carpeta.

Lo comprobamos haciendo ls -la después de crear feature/customer-search y vimos que no apareció ninguna carpeta llamada feature.

También vimos que customer-search.md desaparecía al volver a main y reaparecía cuando regresábamos a la branch.




6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?

Entre:

<<<<<<< HEAD

y:

=======

estaba la versión que tenía la branch actual, que en nuestro caso era main.

Entre:

=======

y:

>>>>>>> fix/readme-subtitle

estaba la versión que venía de la otra branch que estábamos intentando fusionar.

Git puso esos marcadores porque no sabía automáticamente cuál de las dos versiones debía quedarse.





7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?

Porque git commit --amend modifica el último commit y crea uno nuevo con otro hash.

Si ese commit ya se ha subido a GitHub, cambiarlo puede hacer que el historial local y el historial remoto sean diferentes y provocar problemas, sobre todo si otras personas ya tienen ese commit.

Por eso lo usamos en la práctica antes de hacer ningún push.




8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?

Si borro .git, pierdo la información que Git utiliza para controlar el repositorio, como el historial de commits, las branches y la configuración del repositorio.

Los archivos normales del proyecto que están en el disco no se borran.

Por ejemplo, README.md seguiría existiendo, pero la carpeta dejaría de funcionar como un repositorio Git con su historial anterior.





9. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".

Git es el programa que tengo instalado en mi ordenador y que sirve para controlar versiones, hacer commits, crear branches, hacer merges, etc.

GitHub es una plataforma web donde puedo guardar un repositorio Git en un servidor y compartirlo o trabajar con otras personas.

Git puede funcionar sin Internet para muchas operaciones, mientras que para usar GitHub sí necesito conexión.




10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?

Porque un .env puede contener contraseñas, claves o tokens que son información sensible.

Aunque el repositorio sea privado, no es buena idea guardar secretos en Git porque podrían acabar siendo vistos por otras personas con acceso o quedarse guardados en el historial.

Por eso las contraseñas reales no deben subirse al repositorio.




11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con non-fast-forward". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?

Probablemente en GitHub hay commits nuevos que el compañero todavía no tiene en su repositorio local.

Por ejemplo, alguien pudo modificar un archivo desde GitHub mientras él seguía trabajando en su ordenador.

Lo primero que ejecutaría sería:

git pull

para traer los cambios que faltan. Después resolvería algún conflicto si aparece y finalmente haría otra vez:

git push




12. ¿Qué tipo de Conventional Commit usarías para añadir un índice de rendimiento a una tabla, corregir una restricción mal definida y actualizar el README?

Para añadir un índice para mejorar el rendimiento usaría:

perf

Por ejemplo:

perf(db): add customer index

Para corregir una restricción mal definida usaría:

fix

Por ejemplo:

fix(db): correct customer constraint

Y para actualizar el README usaría:

docs

Por ejemplo:

docs: update README