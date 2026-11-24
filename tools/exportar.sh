#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
mkdir -p build/linux build/windows

godot --headless --path godot --export-release Linux
cp -R contenido build/linux/

godot --headless --path godot --export-release Windows
cp -R contenido build/windows/
