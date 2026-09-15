# OpositoraGumy

App web para preparar oposiciones a base de test: creas tus temas, metes preguntas de opción múltiple o verdadero/falso, y generas exámenes aleatorios para ponerte a prueba — de un tema o de todos a la vez. Sin cuenta, sin servidor: todo vive en el navegador de quien la usa (misma filosofía que CheckList y BalanceMensualWeb, hermanas suyas en este mismo repo).

Documento de diseño original (Artifact, con la conversación completa de decisiones): [OpositoraGumy — spec v1](https://claude.ai/artifact/NM8heQUJounujMUFnsydE2). Este `CLAUDE.md` es el resumen de referencia que se mantiene al día conforme avanza el código — si alguna vez difieren, este archivo manda porque refleja el estado real, pero el Artifact es el histórico de cómo se llegó a cada decisión.

## Jerarquía de datos

Tres niveles, uno dentro de otro:

- **Examen general** (p. ej. "Auxiliar Administrativo 2026") — puede haber varios en paralelo, cada uno independiente, como las listas de CheckList.
- **Tema** (p. ej. "Tema 3 — La Constitución Española") — pertenece a un único examen general.
- **Pregunta** — pertenece a un único tema. Tiene un enunciado, un **tipo** (`opcionMultiple` o `verdaderoFalso`) y cuál es la respuesta correcta:
  - `opcionMultiple`: enunciado + 4 respuestas (A/B/C/D) + cuál de las cuatro es la correcta.
  - `verdaderoFalso`: enunciado + cuál de las dos (Verdadero/Falso) es la correcta — sin texto de respuestas que escribir, son fijas.

## Mapa de pantallas

```
Inicio (exámenes generales)
  ├─ ＋ Añadir examen general
  └─ abrir uno → Examen general (temas)
                   ├─ ＋ Añadir tema
                   ├─ Examen general → Configurar examen (todos los temas mezclados)
                   └─ abrir uno → Tema (preguntas)
                                    ├─ ＋ Añadir pregunta → Formulario de pregunta
                                    ├─ Examen del tema → Configurar examen (solo este tema)
                                    └─ tocar una pregunta → Formulario de pregunta (edición)

Configurar examen (¿cuántas preguntas? 5 / 10 / 20 / otro)
  └─ Empezar → Examen en curso (una pregunta a la vez, sin volver atrás)
                 └─ última pregunta → Resultado (nota + repaso completo)
```

Cada pantalla tiene su flecha de "volver atrás" al nivel anterior (navegación estándar, sin perder nada) — no forma parte de las reglas de negocio, es implícita en toda la app.

## Pantallas, botón a botón

1. **Inicio** — lista de exámenes generales (o estado vacío la primera vez). "＋ Añadir examen general" pide un nombre. Icono de borrar por fila: borra el examen general **y todo lo que tiene dentro** (sus temas y preguntas).
2. **Examen general** — lista de los temas de ese examen. "＋ Añadir tema" pide un nombre. Botón "Examen general" arriba: abre Configurar examen cogiendo preguntas de **todos** los temas de este examen, mezcladas entre sí.
3. **Tema** — lista de las preguntas de ese tema. **Aquí es donde se revisan**: cada fila muestra el enunciado y un resumen de cuál es la correcta, para repasar de un vistazo si algo está mal escrito sin abrir cada una. "＋ Añadir pregunta" abre el formulario. Botón "Examen del tema": Configurar examen solo con las preguntas de este tema. Tocar una pregunta abre el formulario ya relleno para revisarla o corregirla; icono de borrar para quitarla.
4. **Formulario de pregunta** — se abre desde "＋ Añadir pregunta" o al tocar una existente. Primero se elige el tipo, y el formulario se adapta:
   - Opción múltiple: enunciado + 4 campos A/B/C/D + selector de cuál es la correcta.
   - Verdadero/Falso: enunciado + selector de dos opciones, sin texto de respuestas.
   Los dos tipos conviven sin problema dentro del mismo tema y del mismo examen.
5. **Configurar examen** — único paso antes de empezar: botones rápidos 5/10/20 + campo para otro número. Si se piden más preguntas de las que hay guardadas, se avisa y se ajusta al máximo disponible. "Empezar examen" sortea las preguntas (y dentro de cada una, el orden de sus respuestas) y arranca el examen.
6. **Examen en curso** — una pregunta a la vez, con sus opciones ya barajadas. Al elegir una respuesta se pasa a la siguiente — **no se puede volver atrás a media prueba** (como un examen real). Al responder la última se corrige todo de golpe.
7. **Resultado** — nota (p. ej. "8/10") **+ repaso completo**: cada pregunta con tu respuesta y, si fallaste, cuál era la correcta.

## Mecánica del examen

- **Selección de preguntas**: al generar un examen, se cogen N preguntas al azar del montón disponible (de un tema, o de todos los temas de un examen general). Si N es mayor que las preguntas disponibles, se usan todas las que haya y se avisa — no bloquea.
- **Barajado de respuestas**: cada vez que una pregunta sale en un examen, sus opciones se muestran en un orden aleatorio distinto — la app siempre sabe internamente cuál es la correcta, aunque cambie de sitio en pantalla. Aplica igual a opción múltiple (4 posiciones) y a verdadero/falso (2 posiciones). Los dos tipos se sortean del mismo montón sin distinción.

## Copia de seguridad: exportar e importar

Sin cuenta ni servidor, así que las preguntas viven solo en el navegador de cada persona. Para no perderlas si se borran los datos o se cambia de dispositivo:

- **Exportar**: genera un archivo `.json` con todo (exámenes generales, temas y preguntas) para guardarlo donde el usuario quiera.
- **Importar**: lee ese archivo y recupera todo tal cual estaba.

Se decidió explícitamente NO conectar con Google Drive/OneDrive por ahora (exigiría pedir una cuenta real, rompiendo la filosofía de esta app) — queda anotado como posible mejora futura si el uso real lo pide.

## Decisiones tomadas explícitamente durante el diseño

- **Alta de pregunta**: un único formulario con las respuestas a la vez (no "primero la correcta, luego las demás") — más simple y sin líos de orden.
- **Editar y borrar**: se puede editar y borrar exámenes generales, temas y preguntas después de creados, aunque no se pidió explícitamente — necesario para corregir errores al escribir.
- **Durante el examen**: no se puede volver atrás a cambiar una respuesta ya dada — se corrige todo junto al final.
- **Pocas preguntas**: si se piden más de las disponibles, el examen se hace con las que haya, sin bloquear.
- **Sin historial** (decidido antes del Artifact): cada examen es independiente, no se guarda un histórico de notas por fecha — se puede añadir después si hace falta.

## Fuera de esta primera versión

- Historial de exámenes anteriores (notas por fecha, evolución en el tiempo).
- Cuenta o sincronización automática (Google Drive/OneDrive) — de momento solo exportar/importar a mano.
- Otros tipos de pregunta más allá de opción múltiple y verdadero/falso (p. ej. respuesta múltiple con varias correctas).
- Cronómetro o límite de tiempo por examen.

## Notas técnicas

- **Stack**: Flutter Web, sin backend — mismo patrón que CheckList y BalanceMensualWeb.
- **Almacenamiento**: Hive (como CheckList), local en IndexedDB — el modelo de datos es jerárquico simple (listas dentro de listas), no relacional, así que no hace falta la complejidad de `sqflite_common_ffi_web` que sí necesitó BalanceMensualWeb.
- **Origen compartido**: al publicarse en `adriavb.github.io` junto a CheckList y BalanceMensualWeb, comparte "origen" de navegador con ellas (mismo dominio) — no hay colisión real porque cada app usa nombres de caja/tabla Hive distintos, pero es un matiz a tener en cuenta si se renombra algo.
- **Publicación**: GitHub Pages, sirviendo `flutter build web --base-href /Apps_Web/opositoragumy/`.
