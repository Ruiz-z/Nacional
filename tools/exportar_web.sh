#!/usr/bin/env bash
# Exporta el juego a web en build/web para probarlo con Playwright (tools/e2e).
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
rm -rf godot/contenido && cp -R contenido godot/contenido   # en web el contenido va dentro del paquete
mkdir -p build/web
godot --headless --path godot --import >/dev/null 2>&1 || true
godot --headless --path godot --export-debug Web
rm -rf godot/contenido
echo "Listo: build/web/index.html"
