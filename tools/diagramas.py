import html, sys
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "diagramas") + os.sep
FONT = "Poppins, Calibri, Arial, sans-serif"
INK, PET, TUR, FOND, CLARO, GRIS = "#0E1A22", "#11507D", "#1AA7A6", "#ECFAFA", "#D4F2F1", "#5B6B75"

def esc(t): return html.escape(t, quote=False)

class Lienzo:
    def __init__(s, w, h, titulo, sub):
        s.w, s.h, s.p = w, h, []
        s.p.append(f'<rect width="{w}" height="{h}" fill="#FFFFFF"/>')
        s.p.append(f'<rect width="{w}" height="86" fill="{INK}"/>')
        s.texto(40, 42, titulo, 28, "#FFFFFF", "700")
        s.texto(40, 70, sub, 15, "#9ADCDC")
    def texto(s, x, y, t, tam=15, color=INK, peso="400", anc="start", it=False):
        s.p.append(f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{tam}" fill="{color}" font-weight="{peso}" text-anchor="{anc}"{" font-style=\"italic\"" if it else ""}>{esc(t)}</text>')
    def caja(s, x, y, w, h, titulo, lineas=(), num=None, fondo=FOND, borde=PET, tc=INK, tam=14):
        s.p.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{fondo}" stroke="{borde}" stroke-width="2"/>')
        ox = x + 16
        if num is not None:
            s.p.append(f'<circle cx="{x+30}" cy="{y+28}" r="15" fill="{TUR}"/>')
            s.texto(x+30, y+34, str(num), 16, "#FFFFFF", "700", "middle")
            ox = x + 54
        s.texto(ox, y + 34, titulo, 17, tc, "700")
        yy = y + 62
        for l in lineas:
            s.texto(x + 18, yy, l, tam, tc if tc != INK else "#26343C")
            yy += tam + 7
    def flecha(s, pts, color=PET, punteada=False, etiqueta=None, ex=0, ey=0, anc="middle"):
        d = "M" + " L".join(f"{x},{y}" for x, y in pts)
        da = ' stroke-dasharray="8 6"' if punteada else ""
        s.p.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="2.5"{da} marker-end="url(#pta)"/>')
        if etiqueta:
            mx = sum(x for x, _ in pts) / len(pts) + ex; my = sum(y for _, y in pts) / len(pts) + ey
            s.texto(mx, my, etiqueta, 13, color, "600", anc)
    def linea(s, pts, color=INK, ancho=2.5, punteada=False):
        d = "M" + " L".join(f"{x},{y}" for x, y in pts)
        da = ' stroke-dasharray="6 5"' if punteada else ""
        s.p.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{ancho}" stroke-linejoin="round"{da}/>')
    def punto(s, x, y, r=5, color=INK): s.p.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>')
    def borne(s, x, y, nombre):
        s.p.append(f'<circle cx="{x}" cy="{y}" r="9" fill="#fff" stroke="{INK}" stroke-width="2.5"/>')
        s.texto(x + 16, y + 5, nombre, 15, INK, "700")
    def resistencia(s, x, y, nombre, valor, vertical=False):
        if vertical:
            s.p.append(f'<rect x="{x-11}" y="{y}" width="22" height="56" fill="#fff" stroke="{INK}" stroke-width="2.5"/>')
            s.texto(x + 20, y + 25, nombre, 14, INK, "700"); s.texto(x + 20, y + 42, valor, 13, GRIS)
        else:
            s.p.append(f'<rect x="{x}" y="{y-11}" width="60" height="22" fill="#fff" stroke="{INK}" stroke-width="2.5"/>')
            s.texto(x + 30, y - 18, nombre + " · " + valor, 13, INK, "700", "middle")
    def interruptor(s, x, y, nombre, desc):
        s.punto(x, y, 6); s.punto(x + 70, y, 6)
        s.linea([(x + 4, y - 3), (x + 62, y - 30)], INK, 3)
        s.texto(x + 35, y - 46, nombre, 15, INK, "700", "middle"); s.texto(x + 35, y + 28, desc, 13, GRIS, "400", "middle")
    def guardar(s, nombre):
        defs = f'<defs><marker id="pta" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" refX="12" refY="7" orient="auto"><path d="M0,0 L14,7 L0,14 z" fill="context-stroke"/></marker></defs>'
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{s.w}" height="{s.h}" viewBox="0 0 {s.w} {s.h}">{defs}' + "".join(s.p) + "</svg>"
        svg = svg.replace('fill="context-stroke"', f'fill="{PET}"')
        open(OUT + nombre + ".svg", "w").write(svg)

# ---------- 1. Flujo del aprendizaje adaptativo ----------
L = Lienzo(1700, 960, "Flujo del aprendizaje adaptativo", "Técnicos del Mañana · cada decisión se apoya en el dominio que muestra el técnico por competencia")
cw, ch, gx = 360, 215, 40
cols = [40 + i * (cw + gx) for i in range(4)]
r1, r2, r3 = 120, 410, 700
L.caja(cols[0], r1, cw, ch, "Ingreso con cuenta", ["Usuario y contraseña con rol:", "técnico, jefe directo o admin.", "El técnico empieza solo con el", "diagnóstico abierto."], 1)
L.caja(cols[1], r1, cw, ch, "Diagnóstico", ["10 reactivos del banco, distintos", "para cada técnico.", "Si falla la pregunta media de una", "competencia, la siguiente baja a fácil."], 2)
L.caja(cols[2], r1, cw, ch, "Dominio por competencia", ["4 competencias, últimos 10 intentos.", "Peso: fácil 1, media 2, difícil 3;", "la práctica pesa el doble.", "Novato <40 · Básico <70 ·", "Competente <90 · Experto"], 3)
L.caja(cols[3], r1, cw, ch, "Ruta de aprendizaje", ["Orden: falta crítica, brechas y", "dominio; seguridad pesa doble.", "Faro propone y explica con los", "manuales; la app valida y cita.", "Sin internet: orden calculado local."], 4, fondo="#E3F3FA")
L.caja(cols[3], r2, cw, ch, "Estudio asignado", ["Materiales publicados por un jefe", "directo, según la ruta y el nivel:", "el del técnico y el siguiente.", "Tarjetas, quiz y juegos."], 5)
L.caja(cols[2], r2, cw, ch, "Práctica en el taller", ["Primero el EPP de la tarea.", "Órdenes por nivel y competencia:", "Fácil siempre · Media desde 50 ·", "Difícil desde 75 de dominio.", "Se registran errores por tipo."], 6)
L.caja(cols[1], r2, cw, ch, "Se actualiza el dominio", ["Cada orden resuelta o fallida suma", "intentos y mueve el dominio.", "La ruta se recalcula y abre o", "cierra niveles de las órdenes."], 7, fondo="#E3F3FA")
L.caja(cols[1], r3, cw, ch, "Evaluación (post-test)", ["Mismas competencias con preguntas", "distintas a las del diagnóstico.", "Mide la ganancia frente al inicio."], 8)
L.caja(cols[2], r3, cw, ch, "Retest diferido", ["Se repite a los 7 días simulados.", "Repetición espaciada (Leitner)", "para medir cuánto se retiene."], 9)
L.caja(cols[3], r3, cw, ch, "Tablero y decisión", ["Ganancia, retención y errores", "recurrentes, con evidencia.", "Es una recomendación: el jefe", "directo decide el avance de nivel."], 10, fondo=PET, borde=PET, tc="#FFFFFF")
mid = lambda y: y + ch // 2
L.flecha([(cols[0] + cw, mid(r1)), (cols[1], mid(r1))])
L.flecha([(cols[1] + cw, mid(r1)), (cols[2], mid(r1))])
L.flecha([(cols[2] + cw, mid(r1)), (cols[3], mid(r1))])
L.flecha([(cols[3] + cw // 2, r1 + ch), (cols[3] + cw // 2, r2)])
L.flecha([(cols[3], mid(r2)), (cols[2] + cw, mid(r2))])
L.flecha([(cols[2], mid(r2)), (cols[1] + cw, mid(r2))])
L.flecha([(cols[1] + cw // 2, r2 + ch), (cols[1] + cw // 2, r3)])
L.flecha([(cols[1] + cw, mid(r3)), (cols[2], mid(r3))])
L.flecha([(cols[2] + cw, mid(r3)), (cols[3], mid(r3))])
# bucle de adaptación
L.flecha([(cols[1] + cw - 60, r2), (cols[1] + cw - 60, r2 - 36), (cols[2] + 90, r2 - 36), (cols[2] + 90, r1 + ch)], TUR, True)
L.texto(cols[2] + 70, r1 + ch + 20, "Ciclo adaptativo: cada práctica cambia el dominio y reordena la ruta", 14, TUR, "700", "end")
# nota lateral
L.p.append(f'<rect x="{cols[0]}" y="{r2}" width="{cw}" height="{ch + r3 - r2}" rx="12" fill="#FFFFFF" stroke="{CLARO}" stroke-width="2" stroke-dasharray="6 5"/>')
L.texto(cols[0] + 18, r2 + 34, "Qué adapta el sistema", 17, INK, "700")
for i, t in enumerate(["• La dificultad de las preguntas del diagnóstico.",
                       "• El orden de la ruta, por competencia.",
                       "• Los materiales que recibe cada técnico.",
                       "• Las órdenes que se abren en el taller.",
                       "• El equipo de EPP que exige cada tarea.",
                       "• Qué repasar: cada tipo de error tiene",
                       "   su práctica de refuerzo."]):
    L.texto(cols[0] + 18, r2 + 68 + i * 27, t, 14, "#26343C")
L.texto(cols[0] + 18, r3 + 190, "Faro (IA) ayuda con la ruta y los materiales; sin", 13, GRIS, "400", "start", True)
L.texto(cols[0] + 18, r3 + 209, "internet el flujo sigue con un respaldo local.", 13, GRIS, "400", "start", True)
L.guardar("flujo-aprendizaje-adaptativo")

# ---------- 2. Esquema electrónico del banco de arnés ----------
E = Lienzo(1500, 900, "Diseño electrónico · Banco de arnés", "Maqueta didáctica de 5 V por USB con Arduino Uno R3 · dos averías con el mismo síntoma")
# Uno
E.p.append(f'<rect x="60" y="130" width="250" height="520" rx="14" fill="{INK}"/>')
E.texto(185, 166, "Arduino Uno R3", 20, "#FFFFFF", "700", "middle")
E.texto(185, 188, "alimentado por USB", 13, "#9ADCDC", "400", "middle")
for y, n in [(240, "A1"), (310, "5V"), (560, "A2"), (610, "GND")]:
    E.p.append(f'<rect x="296" y="{y-10}" width="28" height="20" fill="{TUR}"/>')
    E.texto(280, y + 5, n, 16, "#FFFFFF", "700", "end")
ROJO = "#C0392B"
def tierra(x, y):
    E.linea([(x, y), (x, y + 12)]); 
    for k, a in enumerate([22, 14, 6]): E.linea([(x - a, y + 12 + k * 8), (x + a, y + 12 + k * 8)], INK, 3)
# riel de 5 V
E.linea([(324, 310), (480, 310)], ROJO, 3); E.texto(338, 294, "+5 V", 14, ROJO, "700")
E.punto(430, 310, 6, ROJO); E.linea([(430, 310), (430, 470), (480, 470)], ROJO, 3); E.punto(430, 470, 6, ROJO)
# rama S1: 5V -> S1 -> P
E.interruptor(480, 310, "S1", "alimentación")
E.linea([(550, 310), (1060, 310)]); E.resistencia(900, 310, "R3", "1 kΩ")
E.borne(1060, 310, "TP1")
E.punto(660, 310, 7); E.texto(646, 302, "P", 18, INK, "700", "end")
E.linea([(660, 310), (660, 240), (324, 240)], PET, 2.5); E.texto(480, 230, "P → A1", 13, PET, "700")
E.linea([(660, 310), (660, 346)]); E.resistencia(660, 346, "R1", "10 kΩ", True)
E.linea([(660, 402), (660, 412)]); tierra(660, 412)
# rama S2: 5V -> S2 -> Q
E.interruptor(480, 470, "S2", "señal de prueba")
E.linea([(550, 470), (1060, 470)]); E.resistencia(900, 470, "R4", "1 kΩ")
E.borne(1060, 470, "TP2")
E.punto(780, 470, 7); E.texto(800, 458, "Q", 18, INK, "700")
E.punto(740, 470, 5, PET); E.linea([(740, 470), (740, 560), (324, 560)], PET, 2.5); E.texto(480, 550, "Q → A2", 13, PET, "700")
E.linea([(780, 470), (780, 520)]); E.resistencia(780, 520, "R2", "10 kΩ", True)
E.linea([(780, 576), (780, 610)]); E.punto(780, 610, 6)
# GND común hacia TP0
E.linea([(324, 610), (1060, 610)], INK, 3); E.borne(1060, 610, "TP0")
E.texto(400, 636, "GND común (todas las tierras unidas)", 14, GRIS, "700")
# panel de pruebas
E.texto(60, 700, "Comprobación con el multímetro (punta negra en TP0, roja en TP1 o TP2)", 17, INK, "700")
cab = ["Estado", "S1", "S2", "TP1", "TP2", "nodo_p", "nodo_q"]
filas = [["Sano", "Cerrado", "Cerrado", "≈5 V", "≈5 V", "1", "1"],
         ["Falla de alimentación", "Abierto", "Cerrado", "≈0 V", "≈5 V", "0", "1"],
         ["Falla de señal", "Cerrado", "Abierto", "≈5 V", "≈0 V", "1", "0"]]
xs = [60, 330, 460, 590, 700, 810, 920]
E.p.append(f'<rect x="60" y="716" width="990" height="34" fill="{PET}"/>')
for x, c in zip(xs, cab): E.texto(x + 10, 739, c, 15, "#FFFFFF", "700")
for i, f in enumerate(filas):
    y = 750 + i * 36
    E.p.append(f'<rect x="60" y="{y}" width="990" height="36" fill="{FOND if i % 2 == 0 else "#FFFFFF"}" stroke="{CLARO}"/>')
    for x, c in zip(xs, f): E.texto(x + 10, y + 24, c, 15, INK, "700" if x == 60 else "400")
E.texto(60, 880, "TP1 y TP2 quedan después de los interruptores. Con 3,3 V (ESP32) las lecturas serían ≈3,3 V: los GPIO no aceptan 5 V directos.", 13, GRIS, "400", "start", True)
# leyenda lateral
E.p.append(f'<rect x="1130" y="150" width="320" height="350" rx="12" fill="{FOND}" stroke="{PET}" stroke-width="2"/>')
E.texto(1148, 184, "Componentes", 17, INK, "700")
for i, t in enumerate(["Arduino Uno R3 dedicado al banco",
                       "S1, S2: interruptores simples",
                       "R1, R2: 10 kΩ a GND (referencia)",
                       "R3, R4: 1 kΩ en serie a los bornes",
                       "TP0, TP1, TP2: bornes de prueba",
                       "Cables, base de montaje, cable USB",
                       "Multímetro con puntas negra y roja"]):
    E.texto(1148, 218 + i * 32, "• " + t, 14, "#26343C")
E.p.append(f'<rect x="1130" y="520" width="320" height="130" rx="12" fill="#FFF6E5" stroke="#E5A936" stroke-width="2"/>')
E.texto(1148, 552, "Seguridad", 16, "#684800", "700")
for i, t in enumerate(["Solo 5 V por USB, separado de", "cualquier sistema real del autobús.", "Conecta con el USB desconectado."]):
    E.texto(1148, 580 + i * 22, t, 13.5, "#684800")
E.guardar("diseno-electronico-banco-arnes")

# ---------- 3. Arquitectura del módulo físico ----------
A = Lienzo(1700, 940, "Arquitectura del módulo físico", "Del hardware al simulador · protocolo JSON v1, un mensaje por línea · todo con respaldo virtual")
A.caja(40, 130, 420, 230, "Panel físico", ["ESP32 Dev Module o Arduino Uno", "Interruptores: bloqueo y etiquetado", "Botones: confirmar y cancelar", "Perilla de torque (0 a 100)", "3 LED: energizado, bloqueado, falla"], None)
A.caja(40, 400, 420, 210, "Banco de arnés (Arduino Uno)", ["S1 y S2 con puntos de prueba", "TP0, TP1 y TP2, 5 V por USB", "Lee los nodos P y Q (A1 y A2)", "Reporta nodo_p y nodo_q"], None)
A.caja(40, 650, 420, 240, "Banco con ESP32 (Wi-Fi, 3,3 V)", ["Crea su propia red Wi-Fi", "Espera INICIO por UDP 4210", "Reporta {\"tp1\":0,\"tp2\":1}", "cada 250 ms", "Los GPIO solo aceptan 3,3 V"], None)
A.caja(620, 400, 440, 210, "puente_banco.py", ["Lee el USB serie a 115200 baudios", "y reenvía cada línea por UDP", "a 127.0.0.1:11521"], None, fondo="#FFFFFF")
A.caja(620, 650, 440, 240, "puente_esp32.py", ["Recibe los bits del ESP32 por Wi-Fi", "y los traduce al protocolo del", "simulador. Envía latido mientras", "la placa responde"], None, fondo="#FFFFFF")
A.caja(1220, 130, 440, 760, "Simulador (Godot)", [], None, fondo=PET, borde=PET, tc="#FFFFFF")
sim = ["Recibe: v, ctrl, valor, n, t", "", "Filtro de entrada:", "• descarta secuencias repetidas", "• antirrebote de 50 ms por control", "• el orden de llegada se conserva", "", "Latido cada 1 s del dispositivo", "Si faltan 3 s: pausa, avisa y pasa", "al panel virtual o a la falla virtual", "", "Envía a los LED:", "{\"v\":1,\"led\":\"falla\",\"valor\":1}", "", "Registra la fuente de cada acción:", "panel, virtual, teclado, control, banco"]
for i, t in enumerate(sim): A.texto(1240, 204 + i * 30, t, 15, "#FFFFFF", "700" if t.endswith(":") else "400")
A.flecha([(460, 245), (1220, 245)], PET, False, "USB serie 115200 · JSON v1", 0, -10)
A.flecha([(460, 505), (620, 505)]); A.flecha([(1060, 505), (1220, 505)], PET, False, "UDP local", 0, -10)
A.flecha([(460, 770), (620, 770)], PET, False, "Wi-Fi", 0, -10); A.flecha([(1060, 770), (1220, 770)], PET, False, "JSON v1", 0, -10)
A.flecha([(1220, 330), (460, 330)], TUR, True, "LED", -10, -10)
A.texto(40, 112, "Cada módulo es opcional: sin hardware el panel y el multímetro virtuales dan la misma práctica.", 14, "#26343C", "600")
A.guardar("arquitectura-modulo-fisico")
