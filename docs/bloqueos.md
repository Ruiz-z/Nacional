# Bloqueos

Ninguno abierto.

## T-02 · godot-sqlite en Godot 4.7.2 (resuelto)

Se instaló `godot-sqlite` v4.9 en `godot/addons/godot-sqlite/` (solo binarios de
Linux y Windows, unos 14 MB; el paquete completo pesa 313 MB). La prueba de humo
`tests/prueba_plugin_sqlite.gd` abre la base, crea la tabla y lee el valor 42 con
código de salida 0 en Godot 4.7.2.

Para reinstalarlo: descargar `addons.zip` de
https://github.com/2shady4u/godot-sqlite/releases/tag/v4.9 y extraer en `godot/`
solo `addons/godot-sqlite/` con los binarios `*linux*` y `*windows*`; luego
`godot --headless --path godot --editor --import`.
