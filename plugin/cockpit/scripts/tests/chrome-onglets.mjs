// chrome-onglets.mjs — onglets supplémentaires d'une même instance de Chrome (79-14, SOCL-18) : une connexion au protocole PAR onglet.
// Aucune dépendance (WebSocket et fetch de node). Exports : ouvrirOnglet(session, url, { amorce, echeance }) · AMORCE_FLUX.
//   ouvrirOnglet crée un onglet vide (point d'entrée HTTP du protocole), ouvre SA connexion, pose l'amorce avant les scripts de la page, navigue,
//   attend l'événement load (échéance bornée : erreur nommée) et rend { id, ev, attendre, fermer }.
//   AMORCE_FLUX : sous-classe d'EventSource qui garde les instances dans window.__es, les adresses complètes dans window.__fluxUrl, et __emit(nom, objet)
//   qui appelle les écouteurs du flux vivant avec { data: <JSON> } (même contrat que les enveloppes des autres suites).
import { ECHEANCE, pause } from './chrome-session.mjs';

export const AMORCE_FLUX = `(() => { window.__es = []; window.__fluxUrl = []; const O = window.EventSource; if (!O) return;
  window.EventSource = class extends O { constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); window.__fluxUrl.push(String(u)); }
    addEventListener(n, f, ...r) { (this.__l[n] = this.__l[n] || []).push(f); super.addEventListener(n, f, ...r); } };
  window.__emit = (nom, obj) => { for (const e of window.__es) { if (e.readyState === 2) continue; for (const f of (e.__l[nom] || [])) f({ data: JSON.stringify(obj) }); } }; })();`;

export async function ouvrirOnglet(session, url, { amorce = '', echeance = ECHEANCE } = {}) {
  const base = `http://127.0.0.1:${session.port}`;
  const cible = await (await fetch(`${base}/json/new?about:blank`, { method: 'PUT', signal: AbortSignal.timeout(echeance) })).json();
  const ws = new WebSocket(cible.webSocketDebuggerUrl); let id = 0; const pend = new Map(); const ecoutes = [];
  ws.onmessage = (e) => {
    const j = JSON.parse(e.data);
    if (j.id && pend.has(j.id)) { const p = pend.get(j.id); pend.delete(j.id); clearTimeout(p.t); p.ok(j.result); return; }
    for (const l of ecoutes) if (l.m === j.method) l.f(j.params);
  };
  ws.onclose = () => { for (const p of pend.values()) { clearTimeout(p.t); p.ko(new Error('connexion à l\'onglet perdue')); } pend.clear(); };
  await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('connexion à l\'onglet impossible')); setTimeout(() => ko(new Error('connexion à l\'onglet : échéance')), echeance); });
  const send = (method, params = {}, ms = echeance) => new Promise((ok, ko) => {
    const i = ++id; const t = setTimeout(() => { pend.delete(i); ko(new Error(`${method} : échéance (${ms} ms)`)); }, ms);
    pend.set(i, { ok, ko, t }); ws.send(JSON.stringify({ id: i, method, params }));
  });
  const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }))?.result?.value;
  const attendre = async (expr, nom, ms = echeance) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const fermer = async () => {
    try { ws.close(); } catch { /* déjà fermé */ }
    try { await fetch(`${base}/json/close/${cible.id}`, { signal: AbortSignal.timeout(3000) }); } catch { /* onglet déjà parti */ }
  };
  try {
    await send('Page.enable');
    if (amorce) await send('Page.addScriptToEvaluateOnNewDocument', { source: amorce });
    const charge = new Promise((ok) => ecoutes.push({ m: 'Page.loadEventFired', f: ok }));
    await send('Page.navigate', { url });
    let t; const delai = new Promise((ok, ko) => { t = setTimeout(() => ko(new Error(`chargement de ${url} : événement load absent en ${echeance} ms`)), echeance); });
    try { await Promise.race([charge, delai]); } finally { clearTimeout(t); }
  } catch (e) { await fermer(); throw e; }
  return { id: cible.id, ev, attendre, fermer };
}
