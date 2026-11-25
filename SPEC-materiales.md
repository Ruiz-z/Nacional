# Spec 009 — materiales

## Contexto y objetivo
Página web donde un autor genera, con el agente de Azure AI Foundry y su búsqueda en los manuales de Volvo (RAG), materiales de estudio en varios formatos: tarjetas, presentación, infografía y cuatro juegos (quiz, pareo, ordenar pasos y ahorcado). Cada material se cataloga por **modelo de autobús**, **nivel** y **competencia**, y el enfoque por defecto son los **básicos** (Novato y Básico). El técnico solo ve los materiales que una persona revisó.

Complementa a `competencias`: los materiales **no** son ítems del banco de evaluación y no cambian dominio ni ruta.

## Usuarios / actores
- Autor (instructor o equipo): genera, actualiza, edita y revisa materiales.
- Técnico: estudia y juega con los materiales revisados de su modelo y nivel.
- Agente de Foundry (`Faro` o el que se configure): propone el contenido con fuentes de los manuales.

## Historias de usuario
- H1: Como técnico quiero material corto y visual de mi modelo de autobús y de mi nivel para aprender lo básico antes del taller.
- H2: Como autor quiero generar un material en el formato que elija, con fuentes citadas, sin escribirlo desde cero.
- H3: Como autor quiero actualizar un material cuando cambie el manual o cuando quiera otro enfoque, sin perder su identidad ni su historial.
- H4: Como jurado quiero ver la fuente de cada material y quién lo revisó.

## Catálogo
- `contenido/catalogo-materiales.json`: modelos de autobús (id, nombre, tipo, PDF relacionados), niveles, formatos y el enfoque por defecto (`basicos`: Novato y Básico).
- Las competencias se leen de `contenido/banco.json` (una sola fuente de verdad).
- Modelo `general` para lo que aplica a todos los autobuses (por ejemplo, LOTO o EPP).

## Formatos
| Formato | Contenido |
|---|---|
| `tarjetas` | 4 a 12 tarjetas con frente (pregunta o término) y reverso (respuesta corta). |
| `presentacion` | 3 a 8 diapositivas con título, 1 a 5 puntos y nota opcional. |
| `infografia` | Título, idea central, 3 a 6 bloques (dato clave y explicación) y un aviso de seguridad opcional. |
| `quiz` | Juego de 3 a 10 preguntas con 3 o 4 opciones, una correcta y explicación. |
| `pareo` | Juego de 4 a 8 pares término–definición. |
| `secuencia` | Juego de ordenar 3 a 8 pasos de un procedimiento, con explicación. |
| `ahorcado` | Juego de adivinar 4 a 10 términos técnicos (1 a 3 palabras, solo letras, hasta 24 caracteres) con pista y explicación; 6 errores por término, sin distinguir acentos. |

Campos comunes de un material: `id`, `formato`, `titulo`, `modelo`, `nivel`, `competencia`, `tema`, `contenido`, `fuentes` (nombres de PDF o referencias), `origen` (`ia` | `banco` | `manual`), `estado` (`borrador` | `revisado`), `revisado_por`, `version`, `creado`, `actualizado`, `historial` (versiones anteriores con su motivo).

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA sirve una página web local con una vista de **técnico** (catálogo y estudio) y una vista de **autor** (generar, actualizar, editar, revisar).
- RF-2: EL SISTEMA cataloga cada material por modelo de autobús, nivel y competencia, y permite filtrar además por formato y estado.
- RF-3: AL abrir el catálogo, EL SISTEMA filtra por los niveles básicos (Novato y Básico) y los muestra primero.
- RF-4: CUANDO el autor pide generar un material con formato, modelo, nivel, competencia y tema, EL SISTEMA consulta al agente de Foundry con el esquema del formato, una guía de nivel y los PDF sugeridos del modelo.
- RF-5: EL SISTEMA acepta la respuesta solo si cumple el esquema del formato y los límites de longitud; si no, no guarda nada y explica por qué.
- RF-6: EL SISTEMA acepta una fuente de la IA solo si es uno de los PDF que la base de conocimiento devolvió en esa misma respuesta; un material sin ninguna fuente válida se rechaza.
- RF-7: EL SISTEMA guarda cada material generado como `borrador`, con `origen=ia`, en `contenido/materiales/<id>.json`.
- RF-8: CUANDO el autor pide actualizar un material con una indicación, EL SISTEMA envía el contenido actual y la indicación al agente, conserva el `id`, sube la `version`, guarda la versión anterior en `historial` y regresa el material a `borrador`.
- RF-9: CUANDO el autor edita el contenido a mano, EL SISTEMA lo valida con el mismo esquema, sube la versión y lo deja en `borrador`.
- RF-10: CUANDO el autor marca un material como revisado con su alias, EL SISTEMA guarda `estado=revisado`, `revisado_por` y la fecha.
- RF-11: EL SISTEMA muestra al técnico solo materiales `revisado`; el autor ve todos, con el estado visible.
- RF-12: SI Foundry no está configurado o falla, ENTONCES EL SISTEMA genera `tarjetas`, `quiz` y `secuencia` a partir del banco (`origen=banco`, con la fuente de cada ítem) y lo rotula "Generado sin IA".
- RF-13: EL SISTEMA muestra en cada material sus fuentes, su origen, su estado y quién lo revisó.
- RF-14: Un material de `seguridad-alto-voltaje` generado por IA muestra "Requiere revisión de ambos subequipos" mientras sea borrador (constitución 4).
- RF-15: EL SISTEMA no envía al agente alias, nombres ni datos de técnicos; solo los datos del material pedido.

## Requisitos no funcionales
- Sin dependencias nuevas: servidor con la biblioteca estándar de Python 3 y página en HTML, CSS y JavaScript sin compilación.
- Funciona sin internet con los materiales guardados y la generación desde el banco.
- Escucha solo en `127.0.0.1` por defecto.
- Español claro, misma paleta y tipografía que el juego (`docs/diseno-ui.md`).

## Casos límite
- JSON del agente con vallas de código: se limpian antes de validar.
- Modelo, nivel, competencia o formato inexistente: error 400 con el campo.
- Banco sin ítems de la competencia pedida para el respaldo sin IA: error claro, no se guarda nada.
- Id con caracteres fuera de `[a-z0-9-]`: se rechaza (evita escribir fuera de `contenido/materiales/`).

## Fuera de alcance
- Que la IA cree ítems del banco de evaluación o cambie dominio o ruta.
- Cuentas de usuario y permisos reales (el alias del revisor es declarativo).
- Publicar la página en internet.

## Criterios de finalización
- Pruebas automáticas de formatos, validación, fuentes, almacén, respaldo sin IA y API en verde (`python -m unittest discover web/pruebas`).
- Revisión humana de una generación real con `az login` (T-190).

## Decisiones
- Nuevo agente recomendado `materiales` con la misma base de conocimiento que Faro (`foundry/agente-materiales.yaml`); si no existe, se usa `NACIONAL_FOUNDRY_AGENTE`.
- Los materiales son JSON en git, como el resto del contenido, para que el historial y la revisión queden trazables.
