// chrome-session.mjs — socle commun des suites navigateur du cockpit (aucune dépendance : WebSocket et fetch de node).
// Une seule instance de Chrome headless par exécution, fermée proprement (SIGKILL puis attente de sa sortie, profil jetable effacé), même sur
// signal ou sur échéance globale. Aucune attente à durée fixe pour décider d'un état : on interroge la page (attendre), avec une échéance bornée.
// Échéances (millisecondes, surchargeables) : VF_CDP_ECHEANCE_MS = par attente (défaut 90 000) · VF_CDP_GLOBAL_MS = par exécution (défaut 600 000).
// Une mesure indisponible lève une erreur NOMMÉE (« attente de <nom> dépassée ») : jamais un résultat vide silencieux.
// Le HOME réel est rendu à Chrome (REAL_HOME) : sous un HOME jetable il ne démarre pas sur macOS.
import { spawn } from 'node:child_process'; import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

export const ECHEANCE = Number(process.env.VF_CDP_ECHEANCE_MS) || 90000;
export const GLOBAL = Number(process.env.VF_CDP_GLOBAL_MS) || 600000;
export const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const ARGS = ['--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0'];

// ouvrir(chrome) -> session { send, ev, naviguer, attendre, stable, fermer, violations }
export async function ouvrir(chrome, { csp = false } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), `cdp-chrome-${process.env.VF_CDP_TAG ? process.env.VF_CDP_TAG + '-' : ''}`)); // VF_CDP_TAG : marque de la suite (hygiene.sh), pour retrouver ce Chrome-là et nul autre
  const ch = spawn(chrome, [...ARGS, `--user-data-dir=${dir}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, HOME: process.env.REAL_HOME || process.env.HOME } });
  let sorti = false; const sortie = new Promise((r) => ch.once('exit', () => { sorti = true; r(); }));
  const fermer = async () => { try { ch.kill('SIGKILL'); } catch {} if (!sorti) await Promise.race([sortie, pause(3000)]); try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };
  try {
    const port = await new Promise((ok, ko) => {
      let buf = ''; const t = setTimeout(() => ko(new Error(`Chrome n'a pas annoncé son port de débogage en ${ECHEANCE} ms`)), ECHEANCE);
      ch.stderr.on('data', (d) => { buf += d; const m = /ws:\/\/127\.0\.0\.1:(\d+)\//.exec(buf); if (m) { clearTimeout(t); ok(m[1]); } });
      ch.once('exit', (c) => { clearTimeout(t); ko(new Error(`Chrome s'est arrêté avant d'être prêt (code ${c})`)); });
    });
    const cible = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT', signal: AbortSignal.timeout(ECHEANCE) })).json();
    const ws = new WebSocket(cible.webSocketDebuggerUrl); let id = 0; const pend = new Map(); const ecoutes = []; const violations = [];
    ws.onmessage = (e) => { const j = JSON.parse(e.data);
      if (j.id && pend.has(j.id)) { const p = pend.get(j.id); pend.delete(j.id); clearTimeout(p.t); p.ok(j.result); return; }
      if (j.method === 'Log.entryAdded' && /Content Security Policy|Refused to/i.test(j.params.entry.text)) violations.push(j.params.entry.text.slice(0, 160));
      for (const l of ecoutes) if (l.m === j.method) l.f(j.params); };
    ws.onclose = () => { for (const p of pend.values()) { clearTimeout(p.t); p.ko(new Error('connexion au navigateur perdue')); } pend.clear(); };
    await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('connexion au navigateur impossible')); setTimeout(() => ko(new Error('connexion au navigateur : échéance')), ECHEANCE); });
    const send = (method, params = {}) => new Promise((ok, ko) => { const i = ++id; const t = setTimeout(() => { pend.delete(i); ko(new Error(`${method} : pas de réponse en ${ECHEANCE} ms`)); }, ECHEANCE); pend.set(i, { ok, ko, t }); ws.send(JSON.stringify({ id: i, method, params })); });
    const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }))?.result?.value;
    // naviguer : passe par about:blank (un changement de hash seul recharge ainsi quand même), rend la main à l'évènement load de la page
    const naviguer = async (url) => {
      violations.length = 0;
      await send('Page.navigate', { url: 'about:blank' });
      const charge = new Promise((ok) => ecoutes.push({ m: 'Page.loadEventFired', f: ok }));
      await send('Page.navigate', { url });
      await Promise.race([charge, pause(ECHEANCE).then(() => { throw new Error(`chargement de ${url} : événement load absent en ${ECHEANCE} ms`); })]);
      ecoutes.length = 0;
    };
    // attendre : sonde l'expression (booléenne) toutes les 100 ms jusqu'à ce qu'elle soit vraie ; échec nommé sinon
    const attendre = async (expr, nom, ms = ECHEANCE) => {
      const fin = Date.now() + ms; let v;
      do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
      throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
    };
    // stable : relève une valeur JSON jusqu'à ce que deux relevés espacés de 250 ms soient identiques (mise en page posée), puis la rend
    const stable = async (expr, nom, ms = ECHEANCE) => {
      const fin = Date.now() + ms; let prec = null;
      do { let c; try { c = await ev(`(async () => JSON.stringify(await (${expr})))()`); } catch { c = null; } if (c && c === prec) return JSON.parse(c); prec = c; await pause(250); } while (Date.now() < fin);
      throw new Error(`« ${nom} » ne s'est pas stabilisé (${ms} ms)`);
    };
    await send('Page.enable'); if (csp) await send('Log.enable');
    return { send, ev, naviguer, attendre, stable, fermer, violations };
  } catch (e) { await fermer(); throw e; }
}

// executer(chrome, corps, opts) : ouvre la session, joue corps(session), imprime UNE ligne JSON ({ erreur } sur échec nommé), ferme Chrome, sort 0.
export async function executer(chrome, corps, opts = {}) {
  let s = null, fini = false;
  const fin = async (o) => { if (fini) return; fini = true; if (s) await s.fermer(); console.log(JSON.stringify(o)); process.exit(0); };
  const g = setTimeout(() => fin({ erreur: `échéance globale dépassée (${GLOBAL} ms)` }), GLOBAL);
  for (const sig of ['SIGTERM', 'SIGINT']) process.on(sig, () => fin({ erreur: `interrompu (${sig})` }));
  try { s = await ouvrir(chrome, opts); const r = await corps(s); clearTimeout(g); await fin(r); } catch (e) { await fin({ erreur: String(e.message) }); }
}
