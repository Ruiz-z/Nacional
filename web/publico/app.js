// Página de materiales: catálogo por modelo y nivel, panel de autor y visor.
"use strict";

const estado = {
  vista: "tecnico",
  catalogo: null,
  ia: false,
  autor: false,
  usuario: "", // cuenta con la que se entró desde la app; quien revisa queda registrado con ella
  formatoCrear: "tarjetas",
  niveles: [], // vacío = todos
  materiales: [],
};

const $ = (id) => document.getElementById(id);

async function api(ruta, opciones = {}) {
  const respuesta = await fetch(ruta, {
    ...opciones,
    headers: { "Content-Type": "application/json" },
    body: opciones.body ? JSON.stringify(opciones.body) : undefined,
  });
  const datos = await respuesta.json().catch(() => ({ error: "Respuesta no válida del servidor." }));
  if (!respuesta.ok) {
    const error = new Error(datos.error || "Error del servidor.");
    error.detalles = datos.detalles || [];
    throw error;
  }
  return datos;
}

const nombre = {
  modelo: (id) => estado.catalogo.modelos.find((m) => m.id === id)?.nombre || id,
  nivel: (id) => estado.catalogo.niveles.find((n) => n.id === id)?.nombre || id,
  competencia: (id) => estado.catalogo.competencias.find((c) => c.id === id)?.nombre || id,
  formato: (id) => estado.catalogo.formatos.find((f) => f.id === id)?.nombre || id,
};
// Un glifo por formato, trazo único de 1.75 px. El nombre del formato siempre va escrito al lado.
const GLIFOS = {
  tarjetas: ["rect:3,7,13,10,2", "rect:8,3,13,10,2"],
  presentacion: ["rect:3,4,18,12,2", "line:12,16,12,20", "line:8,20,16,20"],
  infografia: ["line:5,20,5,13", "line:12,20,12,5", "line:19,20,19,9"],
  quiz: ["circle:12,12,9", "poly:8,12.5,11,15.5,16,9"],
  pareo: ["circle:6,7,2.5", "circle:18,17,2.5", "poly:8.5,7,13,7,13,17,15.5,17"],
  secuencia: ["line:10,6,20,6", "line:10,12,20,12", "line:10,18,20,18", "circle:5,6,1", "circle:5,12,1", "circle:5,18,1"],
  ahorcado: ["line:4,21,13,21", "line:7,21,7,3", "line:7,3,16,3", "line:16,3,16,6", "circle:16,9,3", "line:16,12,16,17"],
  verdadero_falso: ["poly:3,8,6,11,11,5", "line:14,14,20,20", "line:20,14,14,20"],
  completar: ["line:3,8,11,8", "line:15,8,21,8", "line:3,16,7,16", "line:11,16,21,16"],
  clasificar: ["rect:3,4,7,16,1", "rect:14,4,7,16,1", "line:5,8,8,8", "line:16,8,19,8"],
  caso: ["rect:5,3,14,18,2", "circle:11,10,3", "line:13,12,16,15"],
};
const ESPACIO_SVG = "http://www.w3.org/2000/svg";

function glifo(formato) {
  const svg = document.createElementNS(ESPACIO_SVG, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("class", "glifo");
  for (const trazo of GLIFOS[formato] || []) {
    const [tipo, datos] = trazo.split(":");
    const n = datos.split(",").map(Number);
    let nodo;
    if (tipo === "rect") { nodo = document.createElementNS(ESPACIO_SVG, "rect"); [["x", n[0]], ["y", n[1]], ["width", n[2]], ["height", n[3]], ["rx", n[4]]].forEach(([k, v]) => nodo.setAttribute(k, v)); }
    else if (tipo === "circle") { nodo = document.createElementNS(ESPACIO_SVG, "circle"); [["cx", n[0]], ["cy", n[1]], ["r", n[2]]].forEach(([k, v]) => nodo.setAttribute(k, v)); }
    else if (tipo === "line") { nodo = document.createElementNS(ESPACIO_SVG, "line"); [["x1", n[0]], ["y1", n[1]], ["x2", n[2]], ["y2", n[3]]].forEach(([k, v]) => nodo.setAttribute(k, v)); }
    else { nodo = document.createElementNS(ESPACIO_SVG, "polyline"); nodo.setAttribute("points", n.reduce((p, v, i) => p + (i % 2 ? "," : " ") + v, "").trim()); }
    svg.append(nodo);
  }
  return svg;
}

// Cuánto contiene el material, para decidirlo de un vistazo: «8 preguntas».
function contenidoDe(m) {
  const c = m.contenido || {};
  const por = { tarjetas: ["tarjetas", "tarjeta", "tarjetas"], presentacion: ["diapositivas", "diapositiva", "diapositivas"],
    infografia: ["bloques", "bloque", "bloques"], quiz: ["preguntas", "pregunta", "preguntas"],
    pareo: ["pares", "par", "pares"], secuencia: ["pasos", "paso", "pasos"],
    ahorcado: ["palabras", "término", "términos"],
    verdadero_falso: ["afirmaciones", "afirmación", "afirmaciones"], completar: ["frases", "frase", "frases"],
    clasificar: ["elementos", "elemento", "elementos"], caso: ["pasos", "paso", "pasos"] }[m.formato];
  if (!por || !Array.isArray(c[por[0]])) return "";
  const n = c[por[0]].length;
  return `${n} ${n === 1 ? por[1] : por[2]}`;
}

const ORIGEN = { ia: "Generado con IA", banco: "Generado sin IA (banco)", manual: "Editado a mano" };

function opciones(select, lista, todos) {
  select.replaceChildren(
    ...(todos ? [el("option", { value: "" }, todos)] : []),
    ...lista.map((o) => el("option", { value: o.id }, o.nombre)));
}

function mostrarMensaje(caja, tipo, texto, detalles = []) {
  caja.className = `mensaje ${tipo}`;
  caja.replaceChildren(el("strong", {}, tipo === "error" ? "No se pudo: " : ""), texto,
    detalles.length ? el("ul", {}, detalles.slice(0, 8).map((d) => el("li", {}, d))) : "");
}

// --- Filtros ---

function pintarFiltroNivel() {
  const basicos = estado.catalogo.enfoques.basicos;
  const opcionesNivel = [
    { etiqueta: "Básicos", niveles: basicos },
    { etiqueta: "Todos", niveles: [] },
    ...estado.catalogo.niveles.map((n) => ({ etiqueta: n.nombre, niveles: [n.id] })),
  ];
  $("filtro-nivel").replaceChildren(...opcionesNivel.map((o) => {
    const activo = o.niveles.join() === estado.niveles.join();
    return el("button", {
      type: "button", "aria-pressed": String(activo),
      onclick: () => { estado.niveles = o.niveles; pintarFiltroNivel(); cargarMateriales(); },
    }, o.etiqueta);
  }));
}

function consulta() {
  const params = new URLSearchParams({ vista: estado.vista });
  for (const campo of ["modelo", "competencia", "formato", "estado"]) {
    const valor = $(`filtro-${campo}`).value;
    if (valor && (campo !== "estado" || estado.vista === "autor")) params.set(campo, valor);
  }
  if (estado.niveles.length) params.set("niveles", estado.niveles.join(","));
  return params.toString();
}

async function cargarMateriales() {
  try {
    estado.materiales = (await api(`/api/materiales?${consulta()}`)).materiales;
    pintarCatalogo();
  } catch (error) {
    $("catalogo").replaceChildren(el("div", { clase: "vacio" }, error.message));
  }
}

// --- Catálogo: agrupado por modelo de autobús ---

function marcaEstado(m) {
  return el("span", { clase: `estado-material ${m.estado}` }, el("i", { "aria-hidden": "true" }), m.estado === "revisado" ? "Revisado" : "Borrador");
}

function tarjetaMaterial(m) {
  const cuanto = contenidoDe(m);
  return el("button", { type: "button", clase: `material tipo-${m.formato}`, onclick: () => abrir(m.id) },
    el("span", { clase: "material-formato" }, glifo(m.formato), nombre.formato(m.formato)),
    el("h3", {}, m.titulo),
    el("p", { clase: "tema" }, nombre.competencia(m.competencia)),
    el("span", { clase: "material-pie" },
      el("span", {}, [`Nivel ${nombre.nivel(m.nivel).toLowerCase()}`, cuanto].filter(Boolean).join(" · ")),
      estado.vista === "autor" ? marcaEstado(m) : null,
      m.muestra ? el("span", { clase: "muestra" }, "Ejemplo") : null));
}

function pintarCatalogo() {
  const raiz = $("catalogo");
  const total = estado.materiales.length;
  $("cuenta").textContent = total ? `${total} ${total === 1 ? "material" : "materiales"}` : "";
  if (!total) {
    raiz.replaceChildren(el("div", { clase: "vacio" },
      el("strong", {}, estado.vista === "autor" ? "No hay materiales con estos filtros." : "Aún no hay materiales revisados con estos filtros."),
      el("span", {}, estado.vista === "autor"
        ? "Crea uno arriba, o quita algún filtro."
        : "Prueba con el nivel «Todos» o pide a tu instructor que publique uno.")));
    return;
  }
  const grupos = new Map();
  for (const m of estado.materiales) {
    if (!grupos.has(m.modelo)) grupos.set(m.modelo, []);
    grupos.get(m.modelo).push(m);
  }
  const orden = estado.catalogo.modelos.map((m) => m.id);
  raiz.replaceChildren(...[...grupos.entries()]
    .sort(([a], [b]) => orden.indexOf(a) - orden.indexOf(b))
    .map(([modelo, lista]) => el("section", { clase: "grupo" },
      el("h2", {}, nombre.modelo(modelo), el("small", {}, `${lista.length} ${lista.length === 1 ? "material" : "materiales"}`)),
      el("div", { clase: "tarjetas-catalogo" }, lista.map(tarjetaMaterial)))));
}

// --- Panel de autor ---

function pintarFormatosCrear() {
  const grupos = [["Para estudiar", "estudio"], ["Juegos", "juego"]];
  $("formatos").replaceChildren(...grupos.map(([titulo, tipo]) => el("div", { clase: "formatos-grupo", role: "presentation" },
    el("span", { clase: "formatos-titulo" }, titulo),
    el("div", { clase: "segmentos" }, estado.catalogo.formatos.filter((f) => f.tipo === tipo).map((f) => el("button", {
      type: "button", role: "radio", "aria-checked": String(f.id === estado.formatoCrear),
      "aria-pressed": String(f.id === estado.formatoCrear),
      onclick: () => { estado.formatoCrear = f.id; pintarFormatosCrear(); },
    }, glifo(f.id), f.nombre))))));
  const formato = estado.catalogo.formatos.find((f) => f.id === estado.formatoCrear);
  $("descripcion-formato").textContent = formato.descripcion;
  $("generar").textContent = estado.ia ? "Generar con IA" : "Generar desde el banco";
  $("aviso-generar").textContent = estado.ia
    ? "La IA consulta los manuales (unos 10 a 40 s). El material queda como borrador hasta que alguien lo revise."
    : formato.sin_ia
      ? "Foundry no está configurado: el material se arma con las preguntas del banco y su fuente."
      : "Este formato necesita la IA. Configura Foundry (docs/materiales.md) o elige Tarjetas, Quiz u Ordena los pasos.";
  $("generar").disabled = !estado.ia && !formato.sin_ia;
}

async function generar() {
  const boton = $("generar");
  const caja = $("mensaje-crear");
  const tema = $("crear-tema").value.trim();
  if (!tema) { mostrarMensaje(caja, "error", "Escribe el tema del material."); $("crear-tema").focus(); return; }
  boton.disabled = true;
  boton.setAttribute("aria-busy", "true");
  const texto = boton.textContent;
  boton.textContent = estado.ia ? "Consultando los manuales…" : "Armando…";
  mostrarMensaje(caja, "ok", estado.ia ? "Consultando los manuales de Volvo…" : "Armando el material con el banco…");
  try {
    const material = await api("/api/materiales", {
      method: "POST",
      body: { formato: estado.formatoCrear, modelo: $("crear-modelo").value, nivel: $("crear-nivel").value,
              competencia: $("crear-competencia").value, tema },
    });
    mostrarMensaje(caja, "ok", `Listo: «${material.titulo}» quedó como borrador.`);
    await cargarMateriales();
    abrir(material.id);
  } catch (error) {
    mostrarMensaje(caja, "error", error.message, error.detalles);
  } finally {
    boton.removeAttribute("aria-busy");
    boton.textContent = texto;
    pintarFormatosCrear();
  }
}

// --- Visor ---

function cerrarVisor() {
  $("visor-fondo").classList.add("oculto");
  $("visor").replaceChildren();
}

async function abrir(id) {
  let m;
  try { m = await api(`/api/materiales/${encodeURIComponent(id)}`); }
  catch (error) { alert(error.message); return; }
  const visor = $("visor");
  const visorDe = Formatos[m.formato];
  visor.replaceChildren(...[
    el("button", { type: "button", clase: "boton secundario chico cerrar", onclick: cerrarVisor }, "Cerrar"),
    el("p", { clase: "visor-meta" },
      el("span", { clase: "material-formato" }, glifo(m.formato), nombre.formato(m.formato)),
      el("span", {}, `${nombre.modelo(m.modelo)} · ${nombre.competencia(m.competencia)} · Nivel ${nombre.nivel(m.nivel).toLowerCase()}`),
      marcaEstado(m),
      m.muestra ? el("span", { clase: "muestra" }, "Ejemplo didáctico") : null),
    el("h2", { id: "visor-titulo" }, m.titulo),
    m.doble_revision ? el("div", { clase: "aviso-seguridad" }, "Requiere revisión de ambos subequipos: es contenido de alto voltaje generado con IA.") : null,
    el("div", { clase: "escenario" }, visorDe ? visorDe(m.contenido) : "Formato desconocido."),
    el("div", { clase: "ficha" },
      el("section", {}, el("h3", {}, "Fuentes"), el("ul", {}, m.fuentes.map((f) => el("li", {}, f)))),
      el("section", {}, el("h3", {}, "Ficha"),
        el("ul", {},
          el("li", {}, ORIGEN[m.origen] || m.origen),
          el("li", {}, `Versión ${m.version} · actualizado ${new Date(m.actualizado).toLocaleString("es-MX")}`),
          el("li", {}, m.estado === "revisado" ? `Revisado por ${m.revisado_por}` : "Pendiente de revisión"),
          el("li", {}, `Tema: ${m.tema}`)))),
    estado.vista === "autor" ? accionesAutor(m) : null,
  ].filter(Boolean));
  $("visor-fondo").classList.remove("oculto");
  visor.querySelector(".cerrar").focus();
}

function accionesAutor(m) {
  const caja = el("div", { clase: "mensaje oculto", role: "status" });
  const revisor = el("input", { maxlength: "40", placeholder: "Alias de quien revisó" });
  const indicacion = el("input", { maxlength: "300", placeholder: "Ej.: más sencillo para novatos, agrega el paso de verificar ausencia de tensión" });
  const editor = el("textarea", { spellcheck: "false" });
  editor.value = JSON.stringify({ titulo: m.titulo, contenido: m.contenido }, null, 2);
  const zonaEditor = el("div", { clase: "oculto" }, editor,
    el("div", { clase: "controles" }, el("button", { type: "button", clase: "boton", onclick: guardarEdicion }, "Guardar cambios")));

  async function ejecutar(boton, textoEspera, accion) {
    const original = boton.textContent;
    boton.disabled = true; boton.textContent = textoEspera;
    try {
      const actualizado = await accion();
      await cargarMateriales();
      if (actualizado) await abrir(actualizado.id); else cerrarVisor();
    } catch (error) {
      mostrarMensaje(caja, "error", error.message, error.detalles);
      boton.disabled = false; boton.textContent = original;
    }
  }
  function guardarEdicion(evento) {
    let datos;
    try { datos = JSON.parse(editor.value); }
    catch { mostrarMensaje(caja, "error", "El texto no es JSON válido."); return; }
    ejecutar(evento.currentTarget, "Guardando…", () => api(`/api/materiales/${m.id}`, { method: "PUT", body: datos }));
  }
  const ruta = `/api/materiales/${encodeURIComponent(m.id)}`;
  return el("div", { clase: "acciones-autor" },
    m.estado !== "revisado" ? el("div", { clase: "fila" },
      estado.usuario
        ? el("p", { clase: "revisor-cuenta" }, `Revisarás como ${estado.usuario}. Marca el material como revisado solo después de leerlo completo.`)
        : el("label", { clase: "campo" }, "Revisión humana", revisor),
      el("button", { type: "button", clase: "boton", onclick: (e) => ejecutar(e.currentTarget, "Guardando…",
        () => api(`${ruta}/revisar`, { method: "POST", body: { revisor: revisor.value } })) },
        "Marcar como revisado")) : null,
    el("div", { clase: "fila" },
      el("label", { clase: "campo" }, "Actualizar con IA (nueva versión)", indicacion),
      el("button", { type: "button", clase: "boton secundario", disabled: !estado.ia,
        title: estado.ia ? "" : "Necesita Foundry configurado",
        onclick: (e) => ejecutar(e.currentTarget, "Consultando los manuales…",
          () => api(`${ruta}/actualizar`, { method: "POST", body: { indicacion: indicacion.value } })) },
        "Actualizar")),
    el("div", { clase: "fila" },
      el("button", { type: "button", clase: "boton secundario", onclick: () => zonaEditor.classList.toggle("oculto") }, "Editar a mano (JSON)"),
      el("button", { type: "button", clase: "boton peligro", onclick: (e) => {
        if (confirm(`¿Eliminar «${m.titulo}»? Esta acción no se puede deshacer desde la página.`)) {
          ejecutar(e.currentTarget, "Eliminando…", async () => { await api(ruta, { method: "DELETE" }); return null; });
        }
      } }, "Eliminar")),
    zonaEditor,
    m.historial?.length ? el("details", {}, el("summary", {}, `Historial (${m.historial.length} versiones anteriores)`),
      el("ul", {}, m.historial.map((h) => el("li", {}, `v${h.version} · ${new Date(h.actualizado).toLocaleString("es-MX")} · ${h.motivo_cambio}`)))) : null,
    caja);
}

// --- Vista técnico / autor ---

function cambiarVista(vista) {
  estado.vista = vista;
  document.querySelectorAll("[data-vista]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.vista === vista)));
  $("panel-autor").classList.toggle("oculto", vista !== "autor");
  $("campo-estado").classList.toggle("oculto", vista !== "autor");
  $("intro").textContent = vista === "autor"
    ? "Genera materiales con la base de manuales, revísalos y publícalos. El técnico solo ve los revisados."
    : "Elige tu modelo de autobús y tu nivel. Empieza por los básicos, con la fuente de cada material.";
  cargarMateriales();
}

async function iniciar() {
  try {
    const [catalogo, estadoIa] = await Promise.all([api("/api/catalogo"), api("/api/estado")]);
    estado.catalogo = catalogo;
    estado.ia = estadoIa.ia;
    estado.autor = estadoIa.autor !== false;
    estado.usuario = estadoIa.usuario || "";
  } catch (error) {
    $("catalogo").replaceChildren(el("div", { clase: "vacio" }, `No se pudo cargar el catálogo: ${error.message}`));
    return;
  }
  const c = estado.catalogo;
  estado.niveles = c.enfoques[c.enfoque_por_defecto];
  $("estado-ia").querySelector("span").textContent = estado.ia ? "IA conectada (Foundry)" : "Sin IA: respaldo desde el banco";
  $("estado-ia").classList.toggle("si", estado.ia);
  opciones($("filtro-modelo"), c.modelos, "Todos los modelos");
  opciones($("filtro-competencia"), c.competencias, "Todas");
  opciones($("filtro-formato"), c.formatos, "Todos");
  opciones($("crear-modelo"), c.modelos);
  opciones($("crear-nivel"), c.niveles);
  opciones($("crear-competencia"), c.competencias);
  $("crear-nivel").value = "basico";
  pintarFiltroNivel();
  pintarFormatosCrear();
  for (const campo of ["modelo", "competencia", "formato", "estado"]) $(`filtro-${campo}`).addEventListener("change", cargarMateriales);
  document.querySelectorAll("[data-vista]").forEach((b) => b.addEventListener("click", () => cambiarVista(b.dataset.vista)));
  // La vista de autor solo existe con el permiso que entrega la app a jefe directo y admin.
  if (!estado.autor) document.querySelector(".vista").classList.add("oculto");
  $("generar").addEventListener("click", generar);
  $("visor-fondo").addEventListener("click", (e) => { if (e.target === $("visor-fondo")) cerrarVisor(); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !$("visor-fondo").classList.contains("oculto")) cerrarVisor(); });
  cargarMateriales();
}

iniciar();
