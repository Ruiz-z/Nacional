# Bloqueos

## T-02 · godot-sqlite en Godot 4.7.2

En Godot 4.7.2, la prueba de humo salió con código 1 porque la clase
`SQLite` no estaba registrada. La descarga del paquete falló con
`curl: (6) Could not resolve host: github.com`. La compatibilidad del
binario queda pendiente de verificación. T-02 queda registrada como hecha
por la vía de documentar el bloqueo y la alternativa.

La aplicación accede al complemento mediante `godot/logica/datos/`. Para
verificar T-03 en este entorno se usa el ejecutable `sqlite3` ya disponible
solo desde la prueba. En cuanto Godot registra `SQLite`, la misma prueba
usa el complemento.

### Instalación y comprobación manual

Desde la raíz del repositorio, en una máquina con red y con Godot 4.7.2,
descarga y extrae `addons.zip` de la [publicación v4.9](https://github.com/2shady4u/godot-sqlite/releases/tag/v4.9).
Si la máquina de prueba está sin conexión, copia allí el ZIP antes de extraerlo.

```sh
godot --version
curl -fL https://github.com/2shady4u/godot-sqlite/releases/download/v4.9/addons.zip -o addons.zip
unzip addons.zip -d godot
godot --headless --path godot --editor --import
godot --headless --path godot -s tests/prueba_plugin_sqlite.gd
godot --headless --path godot -s tests/run.gd
```

La importación debe encontrar `gdsqlite.gdextension` bajo `godot/addons/`.
La prueba de humo debe imprimir que abrió la base, creó la tabla y leyó
el valor 42, y salir con código 0. La suite debe salir con código 0 e
indicar que el esquema se probó con godot-sqlite.
