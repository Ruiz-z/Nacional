// Recorrido de extremo a extremo del juego exportado a web, con Playwright.
// Uso: node recorrido.mjs [carpeta del build web] [carpeta de capturas]
// Antes: tools/exportar_web.sh. El juego es un canvas, así que se maneja por coordenadas,
// igual que un técnico con teclado y ratón. Falla (código 1) si hay errores de página o
// si no aparece el arranque del motor y de la base SQLite.
import { chromium } from 'playwright';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';

const web = path.resolve(process.argv[2] ?? '../../build/web');
const salida = path.resolve(process.argv[3] ?? 'capturas');
fs.mkdirSync(salida, { recursive: true });

const TIPOS = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
const servidor = http.createServer((req, res) => {
  const archivo = path.join(web, decodeURIComponent(req.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  if (!archivo.startsWith(web) || !fs.existsSync(archivo)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': TIPOS[path.extname(archivo)] ?? 'application/octet-stream' });
  fs.createReadStream(archivo).pipe(res);
});
await new Promise((ok) => servidor.listen(0, ok));
const url = `http://localhost:${servidor.address().port}/index.html`;

const navegador = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROMIUM || undefined,
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--ignore-gpu-blocklist', '--enable-webgl'],
});
const pagina = await navegador.newPage({ viewport: { width: 1280, height: 720 } });
const consola = [];
const errores = [];
pagina.on('console', (m) => consola.push(`[${m.type()}] ${m.text()}`));
pagina.on('pageerror', (e) => errores.push(e.message));

let paso = 0;
async function captura(nombre) {
  paso += 1;
  const ruta = path.join(salida, `${String(paso).padStart(2, '0')}-${nombre}.png`);
  await pagina.screenshot({ path: ruta });
  console.log('captura', ruta);
}
const clic = async (x, y, espera = 1200) => { await pagina.mouse.click(x, y); await pagina.waitForTimeout(espera); };
// Con el ratón capturado un clic real no desplaza el puntero: se pulsa y suelta sin moverlo.
const pulsar = async (espera = 1500) => { await pagina.mouse.down(); await pagina.mouse.up(); await pagina.waitForTimeout(espera); };

await pagina.goto(url);
await pagina.waitForTimeout(25000);              // descarga del motor y arranque
await captura('inicio');

await clic(640, 318);                            // campo de alias
await pagina.keyboard.type('T-0001', { delay: 60 });
await clic(640, 438, 2500);                      // Registrar alias
await captura('alias-registrado');
await clic(880, 529, 2500);                      // Escenario: práctica libre disponible desde el alias
await captura('catalogo-ordenes');
await clic(60, 40, 2000);                        // Volver al menú
await captura('menu-tras-catalogo');
await clic(640, 649, 3000);                      // Abrir modo demo
await captura('modo-demo');
await clic(640, 253, 3000);                      // Practicar en la demo: abre el catálogo de órdenes
await captura('catalogo-desde-demo');
await clic(636, 213, 4000);                      // Pérdida de aislamiento
await captura('practica-aislamiento');
await pulsar();                                  // clic sobre la compuerta apuntada
await captura('menu-compuerta');
await pagina.keyboard.press('1');                // 1 · Inspeccionar (inmediata)
await pagina.waitForTimeout(1500);
await captura('compuerta-abierta');

fs.writeFileSync(path.join(salida, 'consola.txt'), consola.join('\n'));
await navegador.close();
servidor.close();

const texto = consola.join('\n');
const fallos = [];
if (!texto.includes('Godot Engine v4')) fallos.push('no arrancó el motor');
if (!texto.includes('Opened database successfully')) fallos.push('no abrió la base SQLite');
fallos.push(...errores.map((e) => `error de página: ${e}`));
if (fallos.length) { console.error('FALLO:\n- ' + fallos.join('\n- ')); process.exit(1); }
console.log('OK: recorrido completo sin errores');
