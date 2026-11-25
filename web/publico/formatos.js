// Visores de cada formato de material. Todo el texto entra con textContent (nunca HTML).
"use strict";

function el(etiqueta, atributos, ...hijos) {
  const nodo = document.createElement(etiqueta);
  for (const [clave, valor] of Object.entries(atributos || {})) {
    if (valor === false || valor === null || valor === undefined) continue;
    if (clave === "clase") nodo.className = valor;
    else if (clave.startsWith("on")) nodo.addEventListener(clave.slice(2), valor);
    else nodo.setAttribute(clave, valor === true ? "" : valor);
  }
  for (const hijo of hijos.flat()) {
    if (hijo === null || hijo === undefined || hijo === false) continue;
    nodo.append(hijo instanceof Node ? hijo : document.createTextNode(String(hijo)));
  }
  return nodo;
}

function barajar(lista) {
  const copia = lista.slice();
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
}

// Barajar hasta que no quede en el orden original (si se puede).
function desordenar(lista) {
  if (lista.length < 2) return lista.slice();
  let copia;
  do { copia = barajar(lista); } while (copia.every((v, i) => v === lista[i]));
  return copia;
}

const APROBACION = 91; // Línea de aprobación de los cursos de Volvo (docs/fuentes-volvo.md).

function resultadoFinal(aciertos, total, alReiniciar, texto) {
  const porcentaje = total ? Math.round((aciertos / total) * 100) : 0;
  const aprobado = porcentaje >= APROBACION;
  return el("div", { clase: "resultado" },
    el("div", { clase: "grande" }, `${porcentaje}%`),
    el("div", { clase: "barra", role: "img", "aria-label": `${porcentaje} de 100, línea de aprobación ${APROBACION}` },
      el("span", { style: `width:${porcentaje}%;background:${aprobado ? "var(--exito)" : "var(--turquesa)"}` }),
      el("i", { style: `left:${APROBACION}%` })),
    el("p", {}, texto || `${aciertos} de ${total} correctas. ${aprobado
      ? "¡Superaste la línea de 91 de los cursos Volvo!"
      : `La línea de aprobación de los cursos Volvo es ${APROBACION}. Repasa y vuelve a intentarlo.`}`),
    el("button", { type: "button", clase: "boton", onclick: alReiniciar }, "Jugar otra vez"));
}

const Formatos = {
  tarjetas(contenido) {
    const vistas = new Set();
    const progreso = el("div", { clase: "progreso" });
    const pintar = () => { progreso.textContent = `Volteaste ${vistas.size} de ${contenido.tarjetas.length} tarjetas. Haz clic en una tarjeta para ver la respuesta.`; };
    pintar();
    const mazo = el("div", { clase: "mazo" }, contenido.tarjetas.map((t, i) => {
      const carta = el("button", { type: "button", clase: "carta", "aria-label": `Tarjeta ${i + 1}: ${t.frente}` },
        el("div", { clase: "carta-interior" },
          el("div", { clase: "cara frente" }, t.frente),
          el("div", { clase: "cara reverso" }, t.reverso)));
      carta.addEventListener("click", () => {
        carta.classList.toggle("volteada");
        vistas.add(i); pintar();
      });
      return carta;
    }));
    return el("div", {}, progreso, mazo);
  },

  presentacion(contenido) {
    const total = contenido.diapositivas.length;
    let actual = 0;
    const marco = el("div", {});
    const contador = el("span", {});
    const anterior = el("button", { type: "button", clase: "boton secundario chico", onclick: () => ir(-1) }, "← Anterior");
    const siguiente = el("button", { type: "button", clase: "boton chico", onclick: () => ir(1) }, "Siguiente →");
    function pintar() {
      const d = contenido.diapositivas[actual];
      marco.replaceChildren(...[
        el("div", { clase: "diapositiva" },
          el("div", { clase: "numero" }, `${actual + 1} / ${total}`),
          el("h3", {}, d.titulo),
          el("ul", {}, d.puntos.map((p) => el("li", {}, p)))),
        d.nota ? el("p", { clase: "nota" }, d.nota) : null,
      ].filter(Boolean));
      contador.textContent = `${actual + 1} de ${total}`;
      anterior.disabled = actual === 0;
      siguiente.disabled = actual === total - 1;
    }
    function ir(paso) { actual = Math.max(0, Math.min(total - 1, actual + paso)); pintar(); }
    const raiz = el("div", { tabindex: "0", "aria-label": "Presentación; usa las flechas para avanzar" },
      marco, el("div", { clase: "controles" }, anterior, contador, siguiente));
    raiz.addEventListener("keydown", (e) => {
      if (e.key === "ArrowRight") ir(1);
      if (e.key === "ArrowLeft") ir(-1);
    });
    pintar();
    return raiz;
  },

  infografia(contenido) {
    return el("div", {},
      el("div", { clase: "info-cabecera" }, el("small", {}, "Idea central"), contenido.idea_central),
      el("div", { clase: "info-bloques" }, contenido.bloques.map((b, i) =>
        el("div", { clase: "bloque" },
          el("span", { clase: "paso" }, String(i + 1)),
          el("div", { clase: "dato" }, b.dato),
          el("h4", {}, b.titulo),
          el("p", {}, b.explicacion)))),
      contenido.aviso_seguridad ? el("div", { clase: "aviso-seguridad" }, "⚠ ", contenido.aviso_seguridad) : null);
  },

  quiz(contenido) {
    const raiz = el("div", {});
    let orden, indice, aciertos;
    function iniciar() { orden = barajar(contenido.preguntas); indice = 0; aciertos = 0; pintar(); }
    function pintar() {
      if (indice >= orden.length) {
        raiz.replaceChildren(resultadoFinal(aciertos, orden.length, iniciar));
        return;
      }
      const p = orden[indice];
      const opciones = barajar(p.opciones.map((texto, i) => ({ texto, correcta: i === p.correcta })));
      const retro = el("div", { clase: "retro oculto", role: "status" });
      const botones = opciones.map((o) => el("button", { type: "button", clase: "opcion", onclick: () => responder(o, botones, retro) }, o.texto));
      raiz.replaceChildren(
        el("div", { clase: "marcador" }, el("span", {}, `Pregunta ${indice + 1} de ${orden.length}`), el("span", {}, `Aciertos: ${aciertos}`)),
        el("div", { clase: "pregunta" }, p.pregunta),
        el("div", { clase: "opciones" }, botones),
        retro);
      botones[0].focus();
      function responder(opcion) {
        botones.forEach((b, i) => {
          b.disabled = true;
          if (opciones[i].correcta) b.classList.add("correcta");
          else if (opciones[i] === opcion) b.classList.add("incorrecta");
        });
        if (opcion.correcta) aciertos++;
        retro.replaceChildren(el("strong", {}, opcion.correcta ? "¡Correcto! " : "No es correcta. "), p.explicacion,
          el("div", { style: "margin-top:10px" },
            el("button", { type: "button", clase: "boton chico", onclick: () => { indice++; pintar(); } },
              indice + 1 < orden.length ? "Siguiente pregunta" : "Ver resultado")));
        retro.classList.remove("oculto");
        retro.querySelector("button").focus();
      }
    }
    iniciar();
    return raiz;
  },

  pareo(contenido) {
    const raiz = el("div", {});
    function iniciar() {
      let elegido = null;
      let hechos = 0;
      let fallos = 0;
      const marcador = el("div", { clase: "marcador" });
      const pintarMarcador = () => {
        marcador.replaceChildren(el("span", {}, `Une cada término con su definición: ${hechos} de ${contenido.pares.length}`),
          el("span", {}, `Errores: ${fallos}`));
      };
      const terminos = barajar(contenido.pares).map((par) => {
        const boton = el("button", { type: "button", clase: "ficha-pareo termino", "aria-pressed": "false" }, par.termino);
        boton.addEventListener("click", () => {
          if (boton.classList.contains("hecho")) return;
          terminos.forEach((t) => t.boton.setAttribute("aria-pressed", "false"));
          boton.setAttribute("aria-pressed", "true");
          elegido = { par, boton };
        });
        return { par, boton };
      });
      const definiciones = barajar(contenido.pares).map((par) => {
        const boton = el("button", { type: "button", clase: "ficha-pareo" }, par.definicion);
        boton.addEventListener("click", () => {
          if (!elegido || boton.classList.contains("hecho")) return;
          if (elegido.par === par) {
            elegido.boton.classList.add("hecho"); boton.classList.add("hecho");
            elegido.boton.setAttribute("aria-pressed", "false");
            elegido.boton.disabled = true; boton.disabled = true;
            elegido = null; hechos++;
          } else {
            fallos++;
            boton.classList.remove("fallo"); void boton.offsetWidth; boton.classList.add("fallo");
          }
          pintarMarcador();
          if (hechos === contenido.pares.length) {
            const aciertos = Math.max(0, contenido.pares.length - fallos);
            raiz.append(resultadoFinal(aciertos, contenido.pares.length, iniciar,
              `Uniste los ${hechos} pares con ${fallos} ${fallos === 1 ? "error" : "errores"}.`));
          }
        });
        return boton;
      });
      pintarMarcador();
      raiz.replaceChildren(marcador, el("div", { clase: "pareo" },
        el("div", { clase: "columna" }, terminos.map((t) => t.boton)),
        el("div", { clase: "columna" }, definiciones)));
    }
    iniciar();
    return raiz;
  },

  secuencia(contenido) {
    const raiz = el("div", {});
    function iniciar() {
      let pasos = desordenar(contenido.pasos);
      let intentos = 0;
      const lista = el("ol", { clase: "secuencia", "aria-label": "Pasos en desorden" });
      const retro = el("div", { clase: "retro oculto", role: "status" });
      let arrastrado = null;
      function mover(desde, hacia) {
        if (hacia < 0 || hacia >= pasos.length) return;
        const [paso] = pasos.splice(desde, 1);
        pasos.splice(hacia, 0, paso);
        pintar(hacia);
      }
      function pintar(foco) {
        lista.replaceChildren(...pasos.map((paso, i) => {
          const item = el("li", { draggable: "true" },
            el("span", {}, paso),
            el("button", { type: "button", clase: "mover", "aria-label": `Subir: ${paso}`, onclick: () => mover(i, i - 1), disabled: i === 0 }, "↑"),
            el("button", { type: "button", clase: "mover", "aria-label": `Bajar: ${paso}`, onclick: () => mover(i, i + 1), disabled: i === pasos.length - 1 }, "↓"));
          item.addEventListener("dragstart", () => { arrastrado = i; item.classList.add("arrastrando"); });
          item.addEventListener("dragend", () => item.classList.remove("arrastrando"));
          item.addEventListener("dragover", (e) => e.preventDefault());
          item.addEventListener("drop", (e) => { e.preventDefault(); if (arrastrado !== null) mover(arrastrado, i); arrastrado = null; });
          return item;
        }));
        if (foco !== undefined) lista.children[foco]?.querySelector(".mover:not(:disabled)")?.focus();
      }
      function comprobar() {
        intentos++;
        let bien = 0;
        [...lista.children].forEach((item, i) => {
          const ok = pasos[i] === contenido.pasos[i];
          item.classList.toggle("bien", ok); item.classList.toggle("mal", !ok);
          if (ok) bien++;
        });
        if (bien === pasos.length) {
          retro.replaceChildren(el("strong", {}, `¡Orden correcto en ${intentos} ${intentos === 1 ? "intento" : "intentos"}! `), contenido.explicacion,
            el("div", { style: "margin-top:10px" }, el("button", { type: "button", clase: "boton chico", onclick: iniciar }, "Jugar otra vez")));
        } else {
          retro.replaceChildren(`${bien} de ${pasos.length} pasos están en su lugar. Los marcados en rojo van en otra posición.`);
        }
        retro.classList.remove("oculto");
      }
      pintar();
      raiz.replaceChildren(
        el("p", { clase: "pregunta" }, `Procedimiento: ${contenido.procedimiento}`),
        el("p", { clase: "progreso" }, "Arrastra los pasos o usa las flechas para ponerlos en orden y pulsa Comprobar."),
        lista,
        el("div", { clase: "controles" }, el("button", { type: "button", clase: "boton", onclick: comprobar }, "Comprobar")),
        retro);
    }
    iniciar();
    return raiz;
  },
};

// --- Ahorcado ---

const MAX_FALLOS = 6;
const TECLADO = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".split("");

// Mayúsculas sin acentos, conservando la Ñ (igual que letras_ahorcado en el servidor).
function normalizarLetra(texto) {
  return texto.toUpperCase().replace(/Ñ/g, "\u0000").normalize("NFD")
    .replace(/[̀-ͯ]/g, "").replace(/\u0000/g, "Ñ");
}

function dibujoAhorcado(fallos) {
  const ns = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(ns, "svg");
  svg.setAttribute("viewBox", "0 0 120 140");
  svg.setAttribute("class", "horca");
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", `${fallos} de ${MAX_FALLOS} errores`);
  const trazo = (tipo, attrs, visible = true) => {
    const nodo = document.createElementNS(ns, tipo);
    for (const [k, v] of Object.entries(attrs)) nodo.setAttribute(k, v);
    nodo.setAttribute("class", visible ? "trazo" : "trazo pendiente");
    svg.append(nodo);
  };
  // Estructura fija.
  trazo("line", { x1: 10, y1: 132, x2: 80, y2: 132 });
  trazo("line", { x1: 30, y1: 132, x2: 30, y2: 10 });
  trazo("line", { x1: 30, y1: 10, x2: 85, y2: 10 });
  trazo("line", { x1: 85, y1: 10, x2: 85, y2: 24 });
  // Partes que aparecen con cada error.
  const partes = [
    ["circle", { cx: 85, cy: 34, r: 10 }],
    ["line", { x1: 85, y1: 44, x2: 85, y2: 80 }],
    ["line", { x1: 85, y1: 54, x2: 70, y2: 68 }],
    ["line", { x1: 85, y1: 54, x2: 100, y2: 68 }],
    ["line", { x1: 85, y1: 80, x2: 72, y2: 102 }],
    ["line", { x1: 85, y1: 80, x2: 98, y2: 102 }],
  ];
  partes.forEach(([tipo, attrs], i) => trazo(tipo, attrs, i < fallos));
  return svg;
}

Formatos.ahorcado = function (contenido) {
  const raiz = el("div", { clase: "ahorcado", tabindex: "0", "aria-label": "Ahorcado; puedes escribir las letras con el teclado" });
  let orden, indice, ganadas, alTeclear = null;

  function iniciar() { orden = barajar(contenido.palabras); indice = 0; ganadas = 0; jugar(); }

  function jugar() {
    if (indice >= orden.length) {
      alTeclear = null;
      raiz.replaceChildren(resultadoFinal(ganadas, orden.length, iniciar,
        `Adivinaste ${ganadas} de ${orden.length} términos.`));
      return;
    }
    const actual = orden[indice];
    const objetivo = [...actual.palabra].map((c) => ({ visible: c, letra: normalizarLetra(c) }));
    const usadas = new Set();
    let fallos = 0;
    let terminado = false;

    const marcador = el("div", { clase: "marcador" });
    const dibujo = el("div", { clase: "dibujo" });
    const palabra = el("div", { clase: "palabra-oculta", "aria-live": "polite" });
    const retro = el("div", { clase: "retro oculto", role: "status" });
    const teclas = new Map();
    const teclado = el("div", { clase: "teclado" }, TECLADO.map((letra) => {
      const boton = el("button", { type: "button", clase: "tecla", onclick: () => probar(letra) }, letra);
      teclas.set(letra, boton);
      return boton;
    }));

    function pintar() {
      marcador.replaceChildren(el("span", {}, `Término ${indice + 1} de ${orden.length}`),
        el("span", {}, `Errores: ${fallos} de ${MAX_FALLOS}`));
      dibujo.replaceChildren(dibujoAhorcado(fallos));
      // Cada palabra va en un bloque que no se parte entre renglones.
      const bloques = [[]];
      for (const o of objetivo) {
        if (o.visible === " ") bloques.push([]);
        else bloques[bloques.length - 1].push(o);
      }
      palabra.replaceChildren(...bloques.map((bloque) => el("span", { clase: "bloque-palabra" }, bloque.map(({ visible, letra }) => {
        if (!/[A-ZÑ]/.test(letra)) return el("span", { clase: "hueco espacio" }, visible);
        const descubierta = usadas.has(letra) || terminado;
        return el("span", { clase: `hueco${descubierta ? " visto" : ""}${terminado && !usadas.has(letra) ? " faltó" : ""}` },
          descubierta ? visible.toUpperCase() : " ");
      }))));
    }

    function probar(letra) {
      if (terminado || usadas.has(letra)) return;
      usadas.add(letra);
      const acierto = objetivo.some((o) => o.letra === letra);
      if (!acierto) fallos++;
      const boton = teclas.get(letra);
      boton.disabled = true;
      boton.classList.add(acierto ? "bien" : "mal");
      const completa = objetivo.every((o) => !/[A-ZÑ]/.test(o.letra) || usadas.has(o.letra));
      if (completa || fallos >= MAX_FALLOS) terminar(completa);
      pintar();
    }

    function terminar(gano) {
      terminado = true;
      if (gano) ganadas++;
      teclas.forEach((b) => { b.disabled = true; });
      retro.replaceChildren(
        el("strong", {}, gano ? "¡Lo adivinaste! " : `Era «${actual.palabra}». `), actual.explicacion,
        el("div", { style: "margin-top:10px" },
          el("button", { type: "button", clase: "boton chico", onclick: () => { indice++; jugar(); } },
            indice + 1 < orden.length ? "Siguiente término" : "Ver resultado")));
      retro.classList.remove("oculto");
      setTimeout(() => retro.querySelector("button")?.focus(), 0);
    }

    alTeclear = (e) => {
      if (e.ctrlKey || e.altKey || e.metaKey || e.key.length !== 1) return;
      const letra = normalizarLetra(e.key);
      if (TECLADO.includes(letra)) { e.preventDefault(); probar(letra); }
    };

    pintar();
    raiz.replaceChildren(marcador,
      el("div", { clase: "tablero-ahorcado" }, dibujo,
        el("div", { clase: "zona-palabra" },
          el("p", { clase: "pista" }, el("strong", {}, "Pista: "), actual.pista),
          palabra, teclado)),
      retro);
    raiz.focus();
  }

  // Teclado físico: escucha en la página mientras el juego está a la vista; se quita al cerrarlo.
  const escuchar = (e) => {
    if (!raiz.isConnected) { document.removeEventListener("keydown", escuchar); return; }
    if (e.target.closest?.("input, textarea, select")) return;
    alTeclear?.(e);
  };
  document.addEventListener("keydown", escuchar);
  iniciar();
  return raiz;
};

window.Formatos = Formatos;
window.el = el;
