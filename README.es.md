# Laboratorio de Valkey con Docker Compose: aprende un almacén clave-valor compatible con Redis, la caducidad, las listas, los hashes y los contadores

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml)

Un **laboratorio de Valkey** listo para usar en clase, de la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning), donde las escuelas y los centros dan a cada alumno sus propias bases de datos, contenedores y terminal en el navegador. Cada alumno recibe su propio **Valkey, el almacén clave-valor de código abierto que entiende los mismos comandos que Redis**, para aprender **SET y GET, claves que caducan, listas, hashes y contadores**, y para ver qué hace un almacén que guarda los datos en memoria cuando se detiene y se vuelve a iniciar. No se instala nada en el equipo del alumno y nada de lo que escriba puede afectar a nadie más.

Es un solo archivo `docker-compose`, `compose.yaml`, que funciona igual en tu propio equipo que en la plataforma, donde cada alumno tiene una copia privada sin salida a internet.

## Qué hay

| Servicio | Imagen | Memoria | Qué es |
| --- | --- | --- | --- |
| `valkey` | [`valkey/valkey:8.1.10-alpine`](https://hub.docker.com/r/valkey/valkey) | 64 MB | el almacén clave-valor, en el puerto 6379, con un archivo de solo añadir en un volumen con nombre |

Arranca sano en unos tres segundos y usa aproximadamente 4 MB en reposo. Se ejecuta con un usuario sin privilegios y lo máximo que guardará son 32 MB; pasado ese límite se rechaza una escritura en lugar de que se mate el servicio. No hay contraseña, porque nada de fuera de la copia puede llegar a él.

La imagen es un programa de terceros, ejecutado sin modificar desde la imagen pública del proyecto y fijado a una versión (nunca `latest`), de modo que el laboratorio no cambia a una clase de una lección a la siguiente. Aquí no se construye nada y nada de este repositorio se distribuye en ella.

**Por qué Valkey y no Redis.** Valkey es el fork de Redis 7.2 de la Linux Foundation con licencia BSD-3-Clause, y responde a los mismos comandos, así que lo que el alumno aprende aquí sirve en Redis y en la mayoría de los servicios que ofrecen un almacén compatible con Redis. Redis 8 y posteriores tienen otra licencia (AGPL o RSAL), por eso este laboratorio usa Valkey.

## Usarlo en la plataforma

La [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning) da a cada alumno su propia copia de un laboratorio, en el navegador, con una terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/es/container), busca este laboratorio en **Laboratorios de ejemplo** y pulsa Iniciar, y después **Abrir terminal**. No hace falta una cuenta para probar uno. El laboratorio no tiene página web, así que todo se escribe en la terminal.

**Para ponerlo como trabajo a una clase:**

1. En tu módulo, crea una tarea de tipo **Laboratorio** y elige **En un repositorio de GitHub**.
2. Indica `https://github.com/mitsurutech/lab-valkey` con la rama `main`. El archivo compose es el predeterminado, `compose.yaml`. Haz antes un fork del repositorio si quieres cambiar el archivo.
3. Publica. La copia de cada alumno parte del commit que publicaste, así que un cambio posterior aquí no altera un laboratorio ya asignado.
4. Di en la tarea qué hay que entregar (consulta [Para profesores](#para-profesores)) y asígnala como cualquier otra tarea.

La [página de este laboratorio](https://mitsurutech.co.uk/es/help/lab-valkey) del manual y su [guía de laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) cubren el resto: qué puede decir un archivo compose, cuánta memoria recibe una copia y cómo abre, vigila y califica un profesor la copia de un alumno. También hay una lección básica gratuita, **Valkey Basics**, que se trabaja en este laboratorio. ¿Aún no tienes una cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/es/pricing) hasta 50 alumnos, y [registrarse](https://mitsurutech.co.uk/es/signup) solo pide una dirección de correo electrónico.

## La terminal no tiene valkey-cli

La terminal de la plataforma incluye `psql`, `mariadb`, `curl`, `git` y `nc`, pero no un cliente de Valkey. No es un obstáculo, porque Valkey acepta un comando como una línea de texto plano. Esta línea crea una función llamada `v` que envía sus palabras al almacén e imprime la respuesta:

```bash
v() ( printf '%s\r\n' "$*" | nc -w 1 valkey 6379 )
```

Después:

```text
$ v SET greeting hello
+OK
$ v GET greeting
$5
hello
$ v GET missing
$-1
```

Las respuestas son el protocolo real, **RESP**: `+` es una palabra corta de éxito, `$5` indica que la línea siguiente es un texto de cinco bytes, `$-1` significa «no hay nada», `:3` es un número y `*3` indica que siguen tres elementos. También puedes ejecutar `nc valkey 6379` y escribir comandos directamente al servidor, uno por línea. En tu propio equipo puedes usar `valkey-cli` o `redis-cli` en su lugar, mira más abajo.

## Ejecutarlo en tu propio equipo

Necesitas Docker con el plugin Compose. El primer arranque descarga la imagen.

```bash
docker compose -f compose.yaml -f local.yaml up
```

`local.yaml` publica el puerto 6379 solo en `127.0.0.1`, así que el laboratorio es accesible desde tu propio ordenador y desde ningún otro sitio. Conéctate con `valkey-cli -p 6379` o `redis-cli -p 6379`, o con `nc` como arriba. Páralo con `Ctrl-C` y elimínalo, datos incluidos, con `docker compose -f compose.yaml -f local.yaml down -v`.

## Paso a paso

1. **Guardar y recuperar.** `v SET greeting hello`, y luego `v GET greeting`.
2. **Hacer que una clave caduque.** `v SET code 1234 EX 5` la guarda durante cinco segundos. `v TTL code` cuenta hacia atrás y, pasados los cinco segundos, `v GET code` responde `$-1`.
3. **Una lista.** `v RPUSH tasks wake eat code` responde `:3`, y `v LRANGE tasks 0 -1` lee los tres elementos en orden.
4. **Un hash.** `v HSET user:1 name Ada born 1815` responde `:2`, y `v HGETALL user:1` imprime los nombres de los campos y los valores.
5. **Un contador.** `v INCR visits` responde `:1`, y otra vez `:2`. La suma la hace el almacén, así que dos clientes a la vez nunca pierden una cuenta.
6. **Ver qué dura.** Detén el laboratorio y vuelve a iniciarlo: `v GET greeting` sigue siendo `hello`. El almacén lo guarda todo en memoria, por eso es rápido, y registra cada escritura en un archivo de solo añadir en un volumen con nombre, que es como reconstruye su memoria al arrancar. `v CONFIG GET appendonly` responde `yes`. La clave caducada no ha vuelto.

## Para profesores

Nada en este laboratorio se califica automáticamente. El alumno entrega pruebas y tú las calificas, como cualquier otro laboratorio.

**Pide las respuestas de una breve sesión suya:** una clave con caducidad y `TTL` contando hacia atrás, una lista, un hash y un contador, con una frase sobre lo que hizo la caducidad y otra sobre lo que seguía allí después de detener y volver a iniciar el laboratorio, y por qué. La última muestra si ha entendido la diferencia entre la memoria y un archivo en disco.

**Dónde encaja en un curso.** Es adecuado para una introducción a las bases de datos y los almacenes de datos, donde un almacén clave-valor es el más simple de los tipos no relacionales, y para el desarrollo web, donde las sesiones, las cachés y los contadores son los usos de un almacén así. Consulta la unidad de tu propio organismo de certificación para ver la redacción exacta; aquí no se cita ninguna.

**Quién ve qué.** Una copia es privada del alumno que la inició. Un miembro del personal que da el módulo puede abrirla para ver lo que ha hecho el alumno, y abrir el trabajo de un alumno queda anotado en el registro de accesos, que el alumno puede leer.

## Lo que no funciona en un laboratorio

El laboratorio no tiene salida a internet, ni contraseña en el almacén (nada más puede llegar a él), ni página web. Otras funciones de Valkey, como la replicación a un segundo servidor, necesitan más de un servicio y no forman parte de este laboratorio. El almacén tiene 64 MB y rechaza escrituras a partir de 32 MB de datos.

## Solución de problemas

- **Un comando no imprime nada.** Define primero la función `v`, en la misma terminal. Si el almacén no ha arrancado, espera a que el laboratorio diga que está en marcha.
- **Una respuesta se parece a `$5`.** Es la longitud de la línea siguiente, no un error: lee la línea que viene después.
- **En tu propio equipo, el puerto 6379 ya está en uso.** Cambia el número de la izquierda en `local.yaml`, por ejemplo `127.0.0.1:6380:6379`.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como lo hace el ejecutor de la plataforma con cada servicio (todas las capacidades retiradas, `no-new-privileges`, un límite de procesos, límites de memoria y sin salida a internet) y luego comprueba desde dentro de su red lo que promete esta página: los comandos de arriba responden como se muestra, una caducidad se cumple y una clave escrita antes de una parada sigue ahí después del arranque. Necesita Docker y se ejecuta en cada push, que es la insignia de la parte superior.

```bash
test/check.sh
```

## Versiones y licencias

[Valkey](https://valkey.io) tiene licencia BSD-3-Clause. La imagen es `valkey/valkey:8.1.10-alpine`, ejecutada sin modificar y no distribuida por nosotros.

La aplicación que contiene tiene la licencia de su propio proyecto, enlazada arriba.

## Licencia

Esta obra está bajo licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Puedes compartirla y adaptarla para aprender y enseñar, si citas a Mitsuru Technologies Ltd, no la usas comercialmente y compartes lo que hagas con ella bajo la misma licencia. El texto completo está en el archivo `LICENSE`.

## Acerca de

Hecho por [Mitsuru Technologies](https://mitsurutech.co.uk) para la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning): Python, Java, Go, Node, SQL y Linux en el navegador para escuelas y centros, con laboratorios de contenedores, aplicaciones web desplegadas desde GitHub y cuestionarios que se califican solos. Prueba código sin cuenta en el [entorno de pruebas](https://mitsurutech.co.uk/es/playground). Todos los laboratorios están listados en el [manual](https://mitsurutech.co.uk/es/help/labs).

Más laboratorios del mismo sitio: [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa) y [lab-sample](https://github.com/mitsurutech/lab-sample).
