# Diagramas de diseño

Tres figuras para el entregable de diagramas de diseño. Cada una está en SVG (editable, para la presentación) y en PNG.

| Figura | Archivo | Qué muestra |
|---|---|---|
| Flujo del aprendizaje adaptativo | `flujo-aprendizaje-adaptativo` | De la cuenta al tablero: diagnóstico, dominio por competencia, ruta con Faro, estudio asignado, práctica por niveles, evaluación y retest, con el ciclo que reordena la ruta. |
| Diseño electrónico del banco de arnés | `diseno-electronico-banco-arnes` | Esquema del Arduino Uno con S1, S2, R1 a R4 y los bornes TP0, TP1 y TP2, y la tabla de lecturas esperadas por avería. |
| Arquitectura del módulo físico | `arquitectura-modulo-fisico` | Panel físico, banco con Uno y banco con ESP32, los dos puentes (USB serie y Wi-Fi) y el simulador, con el protocolo JSON v1 y el respaldo virtual. |

Las cifras salen de `docs/banco-arnes.md`, `docs/protocolo-panel.md` y `firmware/`. Los valores de la maqueta son didácticos. Para regenerar las imágenes después de cambiar algo, edita `tools/diagramas.py` y ejecuta, desde la raíz:

```sh
python3 tools/diagramas.py
for f in docs/diagramas/*.svg; do rsvg-convert -w 1700 "$f" -o "${f%.svg}.png"; done
```
