# Spec 001 — competencias

## Contexto y objetivo
Define el mapa de competencias y el banco de contenido (preguntas, casos de diagnóstico y acciones de panel) que consumen `aprendizaje`, `simulador` y `tablero`. Todo el contenido cita una fuente confiable y, hasta recibir material de Volvo, se marca `[MUESTRA]`.

## Usuarios / actores
- Técnico: responde ítems y ejecuta casos.
- Equipo (autor de contenido): redacta y verifica los ítems.
- Módulos consumidores: `aprendizaje`, `simulador`, `tablero`.

## Historias de usuario
- H1: Como técnico quiero ítems de mi nivel en cada competencia para practicar lo que me falta.
- H2: Como autor quiero un formato de contenido único para sustituir el material de muestra por el de Volvo sin cambiar el código.
- H3: Como jurado quiero ver la fuente de cada ítem para confiar en el contenido.

## Competencias
1. `seguridad-alto-voltaje` — bloqueo, etiquetado, EPP.
2. `sistema-electrico-bateria` — sistema eléctrico y batería del bus eléctrico.
3. `diagnostico-fallas` — lectura de códigos y síntomas; recorrido por pasos.
4. `electronica-conectividad` — sensores, redes del vehículo.
Futuro (fuera de esta iteración): `motor-diesel-mecanica`.

## Formatos de ítem
- `opcion-multiple`: pregunta con opciones y una correcta.
- `caso-diagnostico`: síntomas, código de falla, causa correcta, pasos posibles con resultado, ruta ideal, tipos de error asociados.
- `accion-panel`: instrucción que se valida contra el estado del panel (secuencia esperada de eventos).

Dificultad: `facil` | `media` | `dificil`. Un valor técnico sin fuente pública puede usar la fuente "[MUESTRA] valor de ejemplo, sin fuente oficial" con `muestra=true`; nunca un ítem de seguridad.

Campos comunes: `id`, `competencia`, `formato`, `dificultad`, `criticidad` (`normal`|`leve`|`critica`), `fuente`, `muestra` (bool), `version`.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA define las 4 competencias con id estable y nombre en español.
- RF-2: EL SISTEMA almacena el banco en un archivo JSON local con los campos comunes de cada ítem.
- RF-3: CUANDO se carga el banco, EL SISTEMA valida que cada ítem tenga competencia existente, formato válido, fuente y versión.
- RF-4: SI un ítem carece de fuente o la fuente no pertenece a la lista permitida, ENTONCES EL SISTEMA lo rechaza y reporta su id.
- RF-5: EL SISTEMA marca `muestra=true` en todo ítem que no provenga de material oficial de la empresa.
- RF-6: EL SISTEMA clasifica cada acción insegura como `critica` o `leve`.
- RF-7: CUANDO el jugador ejecuta una acción `critica`, EL SISTEMA detiene el escenario, muestra la explicación y registra la falta.
- RF-8: CUANDO el jugador ejecuta una acción `leve`, EL SISTEMA resta puntos, avisa y continúa.
- RF-9: EL SISTEMA incluye al menos 8 ítems `opcion-multiple` por competencia (4 competencias, 32 en total), para cubrir diagnóstico, post-test y retest sin repetir.
- RF-10: EL SISTEMA incluye al menos 2 `caso-diagnostico` (competencia 3) y 3 `accion-panel` (competencia 1).
- RF-11: EL SISTEMA etiqueta cada paso de un `caso-diagnostico` con el tipo de error que produce si se elige mal: `causa-equivocada`, `paso-omitido`, `orden-incorrecto`, `accion-insegura`, `paso-innecesario`, `herramienta-equivocada` (error leve en el taller), `valor-fuera-de-rango` (por ejemplo, torque excesivo).
- RF-12: CUANDO un consumidor solicita ítems por competencia y dificultad, EL SISTEMA devuelve solo ítems válidos de esa competencia.
- RF-13: EL SISTEMA expone la fuente (título, sección o página, URL o referencia) de cada ítem para mostrarla en pantalla.
- RF-14: EL SISTEMA no genera ni modifica ítems del banco de evaluación con IA; el banco solo cambia editando el JSON. Los materiales de estudio generados con IA viven aparte (`SPEC-materiales.md`), requieren revisión humana y no cuentan para el dominio.

## Fuentes permitidas
Documentación pública de fabricantes (Volvo Buses); NFPA 70E, NOM-029-STPS, NOM-001-SEDE, ISO 6469; material oficial entregado por la empresa (prioridad máxima). Un ítem fuera de esta lista no entra.

## Requisitos no funcionales
- Offline: el banco se lee de disco sin red.
- Solo español.
- Reemplazar contenido de muestra por el oficial no requiere cambios de código.

## Casos límite
- Banco vacío o competencia sin ítems suficientes: el sistema avisa y no arranca el diagnóstico de esa competencia.
- Ítem con id duplicado: se rechaza.
- JSON corrupto: error claro con archivo y línea; no se carga parcialmente.
- Caso de diagnóstico sin ruta ideal: se rechaza.

## Fuera de alcance
- Selección de ítems, cálculo de dominio y ruta (`aprendizaje`).
- Escena 3D y árbol interactivo (`simulador`); aquí solo se definen los datos del caso.
- Editor de contenido y generación con IA.
- Otros idiomas.
- Competencia `motor-diesel-mecanica` y escenario diésel (futuro).

## Criterios de finalización
- Todos los RF con prueba (script de validación del JSON o checklist manual) en verde.
- Banco mínimo cargado y validado sin errores.
- Un integrante verificó cada ítem de seguridad contra su fuente.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Material oficial de Volvo: aún no se sabe si se entregará ni en qué formato.

## Decisiones
- Competencia diésel queda para el futuro (4 competencias en esta iteración).
- Los ítems de seguridad los verifican ambos subequipos (electrónica y software) contra su fuente.
