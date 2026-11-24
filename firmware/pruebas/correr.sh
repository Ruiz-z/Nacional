#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm "$tmp/prueba" "$tmp/leds" "$tmp/esperadas" "$tmp/generadas" 2>/dev/null || :; rmdir "$tmp"' EXIT

g++ -std=c++11 -Wall -Wextra -Werror -pedantic prueba_logica.cpp -o "$tmp/prueba"
protocolo=../../docs/protocolo-panel.md
sed -n '/^{"v":1,"led":/p' "$protocolo" > "$tmp/leds"
sed -n '/^{"v":1,"ctrl":/p' "$protocolo" > "$tmp/esperadas"
"$tmp/prueba" < "$tmp/leds" > "$tmp/generadas"
diff -u "$tmp/esperadas" "$tmp/generadas"
echo "Pruebas de lógica y ejemplos del protocolo correctos."
