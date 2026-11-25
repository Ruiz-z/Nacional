// Página de materiales: catálogo por modelo y nivel, panel de autor y visor.
"use strict";

const estado = {
  vista: "tecnico",
  catalogo: null,
  ia: false,
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
const ORIGEN = { ia: "Generado con IA", banco: "Generado sin IA (banco)", manual: "Editado a mano" };

function opciones(select, lista, todos) {
  select.replaceChildren(
    ...(todos ? [el("option", { value: "" }, todos)] : []),
    ...lista.map((o) => el("option", { value: o.id }, o.nombre)));
}

function mostrarMensaje(caja, tipo, texto, detalles = []) {
  caja.className = `mensaje ${tipo}`;
  caja.replaceChildren(texto, detalles.length ? el("ul", {}, detalles.slice(0, 8).map((d) => el("li", {}, d))) : "");
}

// --- Filtros ---

function pintarFiltroNivel() {
  const basicos = estado.catalogo.enfoques.basicos;
  const opcionesNivel = [
    { etiqueta: "Básicos (Novato y Básico)", niveles: basicos },
    { etiqueta: "Todos", niveles: [] },
    ...estado.catalogo.niveles.map((n) => ({ etiqueta: n.nombre, niveles: [n.id] })),
  ];
  $("filtro-nivel").replaceChildren(...opcionesNivel.map((o) => {
    const activo = o.niveles.join() === estado.niveles.join();
    return el("button", {
      type: "button", clase: "chip-filtro", "aria-pressed": String(activo),
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

function tarjetaMaterial(m) {
  return el("button", { type: "button", clase: "material", onclick: () => abrir(m.id) },
    el("div", { clase: "chips" },
      el("span", { clase: "chip formato-c" }, nombre.formato(m.formato)),
      el("span", { clase: `chip nivel-${m.nivel}` }, nombre.nivel(m.nivel)),
      estado.vista === "autor" ? el("span", { clase: `chip ${m.estado}` }, m.estado === "revisado" ? "Revisado" : "Borrador") : null,
      m.muestra ? el("span", { clase: "chip muestra" }, "Ejemplo didáctico") : null),
    el("h3", {}, m.titulo),
    el("p", { clase: "tema" }, `${nombre.competencia(m.competencia)} · ${m.tema}`));
}

function pintarCatalogo() {
  const raiz = $("catalogo");
  if (!estado.materiales.length) {
    raiz.replaceChildren(el("div", { clase: "vacio" }, estado.vista === "autor"
      ? "No hay materiales con estos filtros. Crea uno arriba."
      : "Todavía no hay materiales revisados con estos filtros. Prueba con «Todos» o pide a tu instructor que publique uno."));
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
  $("formatos").replaceChildren(...estado.catalogo.formatos.map((f) => el("button", {
    type: "button", clase: "formato", "aria-pressed": String(f.id === estado.formatoCrear),
    onclick: () => { estado.formatoCrear = f.id; pintarFormatosCrear(); },
  }, el("span", { clase: "tipo" }, f.tipo), el("strong", {}, f.nombre), el("small", {}, f.descripcion))));
  const formato = estado.catalogo.formatos.find((f) => f.id === estado.formatoCrear);
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
    el("div", { clase: "chips" },
      el("span", { clase: "chip formato-c" }, nombre.formato(m.formato)),
      el("span", { clase: `chip nivel-${m.nivel}` }, nombre.nivel(m.nivel)),
      el("span", { clase: "chip" }, nombre.modelo(m.modelo)),
      el("span", { clase: "chip" }, nombre.competencia(m.competencia)),
      el("span", { clase: `chip ${m.estado}` }, m.estado === "revisado" ? "Revisado" : "Borrador"),
      m.muestra ? el("span", { clase: "chip muestra" }, "Ejemplo didáctico") : null),
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
      el("label", { clase: "campo" }, "Revisión humana", revisor),
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
    : "Elige tu modelo de autobús y tu nivel. Empieza por los básicos: tarjetas, presentaciones, infografías y juegos cortos, con la fuente de cada uno.";
  cargarMateriales();
}

async function iniciar() {
  try {
    const [catalogo, estadoIa] = await Promise.all([api("/api/catalogo"), api("/api/estado")]);
    estado.catalogo = catalogo;
    estado.ia = estadoIa.ia;
  } catch (error) {
    $("catalogo").replaceChildren(el("div", { clase: "vacio" }, `No se pudo cargar el catálogo: ${error.message}`));
    return;
  }
  const c = estado.catalogo;
  estado.niveles = c.enfoques[c.enfoque_por_defecto];
  $("estado-ia").textContent = estado.ia ? "IA conectada (Foundry)" : "Sin IA: respaldo desde el banco";
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
  $("generar").addEventListener("click", generar);
  $("visor-fondo").addEventListener("click", (e) => { if (e.target === $("visor-fondo")) cerrarVisor(); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !$("visor-fondo").classList.contains("oculto")) cerrarVisor(); });
  cargarMateriales();
}

iniciar();
