extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Esquema = preload("res://logica/datos/esquema.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")

const ANTIGUA := """
CREATE TABLE tecnico (id INTEGER PRIMARY KEY, alias TEXT NOT NULL UNIQUE,
	demo INTEGER NOT NULL DEFAULT 0, creado TEXT NOT NULL DEFAULT '') STRICT;
CREATE TABLE intento (id INTEGER PRIMARY KEY, tecnico INTEGER NOT NULL, competencia TEXT NOT NULL,
	item TEXT NOT NULL, formato TEXT NOT NULL, dificultad TEXT NOT NULL, respuesta TEXT NOT NULL,
	valor REAL NOT NULL, peso REAL NOT NULL, resultado TEXT NOT NULL, tipo_error TEXT,
	tiempo_ms INTEGER NOT NULL, fuente_entrada TEXT NOT NULL, momento TEXT NOT NULL,
	reloj_sim TEXT NOT NULL, version_contenido TEXT NOT NULL) STRICT;
INSERT INTO tecnico (id, alias) VALUES (1, 'viejo');
INSERT INTO intento VALUES (1,1,'diagnostico-fallas','a','opcion-multiple','facil','x',50,1,'incorrecto',NULL,20,'teclado','pre','2026-01-01','1');
"""


static func ejecutar() -> bool:
	return migracion() and agrupacion() and Base.con_base(guardado)


static func migracion() -> bool:
	var carpeta := OS.get_temp_dir().path_join("nacional-mig-" + Crypto.new().generate_random_bytes(6).hex_encode())
	DirAccess.make_dir_absolute(carpeta)
	var base := carpeta.path_join("viejo.sqlite")
	var correcto: bool = Base.consultar(base, ANTIGUA) != null and Esquema.migrar(base, Base.consultar) \
		and Esquema.migrar(base, Base.consultar)
	if correcto:
		var filas: Variant = Base.consultar(base, "SELECT sesion_id, numero_intento, ayudas FROM intento;")
		correcto = filas != null and filas.size() == 1 and filas[0].sesion_id == "" \
			and filas[0].numero_intento == 0 and filas[0].ayudas == 0
	for archivo in DirAccess.get_files_at(carpeta):
		DirAccess.remove_absolute(carpeta.path_join(archivo))
	DirAccess.remove_absolute(carpeta)
	return correcto


static func intento(sesion: String, numero: int, momento := "practica") -> Dictionary:
	return {"competencia": "diagnostico-fallas", "item": "x", "formato": "escenario", "dificultad": "facil",
		"respuesta": "r", "valor": 100, "peso": 1, "resultado": "correcto", "tipo_error": null, "tiempo_ms": 0,
		"fuente_entrada": "", "momento": momento, "reloj_sim": "2026-01-0%d" % numero,
		"version_contenido": "1", "sesion_id": sesion, "caso": "modulo_auxiliar",
		"variante": "alimentacion", "numero_intento": numero}


static func agrupacion() -> bool:
	# Dos respuestas de una misma sesión con relojes distintos forman un solo punto.
	var sesiones := Vistas.sesiones([intento("s1", 1), intento("s1", 2), intento("s2", 3)])
	var antiguos := Vistas.sesiones([
		{"competencia": "a", "momento": "pre", "reloj_sim": "1", "valor": 50, "peso": 1, "resultado": "x", "tipo_error": null},
		{"competencia": "a", "momento": "pre", "reloj_sim": "1", "valor": 50, "peso": 1, "resultado": "x", "tipo_error": null}])
	return sesiones.size() == 2 and antiguos.size() == 1


static func guardado(base: String) -> bool:
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('nuevo');")
	var valores := Registro.preparar("nuevo", intento("s9", 4))
	if valores.is_empty() or valores.size() != 20:
		return false
	if Base.consultar(base, Registro.INSERTAR, valores) == null:
		return false
	var filas: Variant = Registro.leer(base, "nuevo", Base.consultar)
	return filas != null and filas.size() == 1 and filas[0].sesion_id == "s9" \
		and filas[0].caso == "modulo_auxiliar" and filas[0].variante == "alimentacion" \
		and filas[0].numero_intento == 4
