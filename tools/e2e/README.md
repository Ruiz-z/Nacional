# Pruebas de extremo a extremo con Playwright

Prueban el juego **exportado a web** como lo usaría un técnico: arranque, alias, modo demo, práctica, clic sobre una pieza, menú y acción. El juego es un canvas, así que se maneja por coordenadas y se revisan las capturas.

```bash
tools/exportar_web.sh                 # exporta a build/web (usa el plugin SQLite web sin hilos)
cd tools/e2e && npm install && npx playwright install chromium
node recorrido.mjs                    # capturas en tools/e2e/capturas/
```

Si ya hay un Chromium instalado: `CHROMIUM=/ruta/a/chrome node recorrido.mjs`. El comando falla (código 1) si el motor o la base SQLite no arrancan o si la página lanza errores.

Notas: la versión web no usa el panel físico ni el puerto serial. Los pasos del recorrido dependen de las posiciones de los botones del menú a 1280x720; si cambia el diseño, hay que ajustarlas.
