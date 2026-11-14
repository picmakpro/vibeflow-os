// chrome-session.mjs — socle commun des suites navigateur du cockpit (aucune dépendance : WebSocket et fetch de node).
// Une seule instance de Chrome headless par exécution, fermée proprement (SIGKILL puis attente de sa sortie, profil jetable effacé), même sur
// signal ou sur échéance globale. Aucune attente à durée fixe pour décider d'un état : on interroge la page (attendre), avec une échéance bornée.
// Échéances (millisecondes, surchargeables) : VF_CDP_ECHEANCE_MS = par attente (défaut 90 000) · VF_CDP_GLOBAL_MS = par exécution (défaut 600 000).
// Amorçage (VF_CDP_AMORCE_MS, défaut = l'échéance globale ; export AMORCE) : annonce du port, /json/new, connexion WebSocket, Page.enable, PREMIER chargement (naviguer) — bornés par
//   AMORCE (max(ECHEANCE, AMORCE) pour le premier naviguer), jamais par ECHEANCE : une suite qui abaisse VF_CDP_ECHEANCE_MS à 20 s borne ses attentes, pas le démarrage de Chrome. Les attentes ordinaires restent à ECHEANCE.
// Une mesure indisponible lève une erreur NOMMÉE (« attente de <nom> dépassée ») : jamais un résultat vide silencieux.
// Le HOME du compte est rendu à Chrome (chromeHome) : sous un HOME jetable il ne démarre pas sur macOS.
//
// AIDES « MESURER UNE FOIS POSÉ » (exports, aucune session requise) — règle : on mesure une fois posé, jamais dans la foulée du geste.
//   stabiliser(lire, { pas = 250, max = 10000 } = {})            relit `await lire()` jusqu'à deux lectures CONSÉCUTIVES identiques (JSON.stringify) ; rend cette valeur
//   attendreValeur(lire, predicat, { pas = 100, max = 10000 } = {}) relit jusqu'à `predicat(valeur)` vrai ; rend cette valeur
//   attendreEtStabiliser(lire, predicat, opts)                   attendreValeur, puis stabiliser : condition vraie PUIS valeur stable
//   positionPosee(ev, expr, { pas = 120, max = 3000 } = {})      `ev` = toute fonction ev(expression) -> Promise<valeur> (s.ev, ou l'ev d'une façade d'iframe) ; `expr` = expression JS
//                                                                rendant l'élément (l'aide construit l'expression du rect) ; rend { x, y, l, h, cx, cy } (rect + centre) une fois deux
//                                                                lectures égales, null si l'élément est absent
// Trois familles de défaut qu'elles corrigent : G géométrie lue avant que l'élément cesse de bouger (geste visé sur un rect périmé) ·
//   R état lu avant le rendu (dans la foulée d'un évènement, d'un postMessage, d'une navigation, d'un redimensionnement) · F pause fixe trop courte suivie d'une lecture qui JUGE.
// Différence avec s.stable(expr, nom) : s.stable évalue dans la page principale et LÈVE une erreur nommée si rien ne se pose ; ces aides prennent n'importe quel lecteur
//   (iframe comprise) et ne lèvent jamais : à l'échéance elles rendent la DERNIÈRE lecture (undefined si toutes les lectures ont levé) — l'assertion juge, la stabilisation ne décide jamais d'un verdict.
// Une lecture qui lève, ou qui rend undefined (s.ev rend undefined sur une exception de la page), est une NON-LECTURE : jamais stable (deux échecs de suite ne font pas une valeur stable), jamais
//   acceptée par attendreValeur, même si le prédicat l'accepterait ; rendue seulement comme dernière lecture à l'échéance (undefined). Un prédicat qui lève vaut faux.
// Attendre ce qui S'ÉCOULE, pas seulement ce qui APPARAÎT : une pause fixe qui précède une lecture laissait peut-être aussi FINIR un flux (réponses en transit, octets en vol dans un PTY ou un tube).
//   Alors l'attente qui la remplace doit attendre la FIN du flux — compte exact ou sentinelle passée par le même chemin —, pas son premier signe : une stabilisation conclut à tort sur une machine lente.
//   Cas réel : R1.2 (terminal-xterm) attendait le premier octet au lieu de pause(1200) ; les 131 072 octets de queue des réponses arrivaient après la mesure, R1.3 a rougi en CI.
// Une pause fixe reste juste pour PROUVER UNE ABSENCE (« rien n'est arrivé en N ms » ne s'attend que par une durée) ou quand la durée est l'objet testé (débounce, cadence de répétition).
import { spawn } from 'node:child_process'; import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

export const ECHEANCE = Number(process.env.VF_CDP_ECHEANCE_MS) || 90000;
export const GLOBAL = Number(process.env.VF_CDP_GLOBAL_MS) || 600000;
export const AMORCE = Number(process.env.VF_CDP_AMORCE_MS) || GLOBAL; // amorçage de Chrome/CDP : borné par l'échéance GLOBALE (un runner à froid démarre Chrome en plus de 20 s), jamais par ECHEANCE
export const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const ARGS = ['--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0'];

// HOME de Chrome : celui du compte (base des comptes, jamais l'environnement : un rejeu sous HOME=$(mktemp -d), ou une suite qui fait
// REAL_HOME=$HOME après l'avoir remplacé, donnerait à Chrome un HOME vide et il ne répondrait plus) ; REAL_HOME puis HOME en repli.
const chromeHome = () => { try { return os.userInfo().homedir; } catch { return process.env.REAL_HOME || process.env.HOME; } };
// ouvrir(chrome) -> session { send, ev, naviguer, attendre, stable, fermer, violations }
export async function ouvrir(chrome, { csp = false } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), `cdp-chrome-${process.env.VF_CDP_TAG ? process.env.VF_CDP_TAG + '-' : ''}`)); // VF_CDP_TAG : marque de la suite (hygiene.sh), pour retrouver ce Chrome-là et nul autre
  const ch = spawn(chrome, [...ARGS, `--user-data-dir=${dir}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, HOME: chromeHome() } });
  let sorti = false; const sortie = new Promise((r) => ch.once('exit', () => { sorti = true; r(); }));
  const fermer = async () => { try { ch.kill('SIGKILL'); } catch {} if (!sorti) await Promise.race([sortie, pause(3000)]); try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };
  try {
    const port = await new Promise((ok, ko) => {
      let buf = ''; const t = setTimeout(() => ko(new Error(`Chrome n'a pas annoncé son port de débogage en ${AMORCE} ms`)), AMORCE);
      ch.stderr.on('data', (d) => { buf += d; const m = /ws:\/\/127\.0\.0\.1:(\d+)\//.exec(buf); if (m) { clearTimeout(t); ok(m[1]); } });
      ch.once('exit', (c) => { clearTimeout(t); ko(new Error(`Chrome s'est arrêté avant d'être prêt (code ${c})`)); });
    });
    const cible = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT', signal: AbortSignal.timeout(AMORCE) })).json();
    const ws = new WebSocket(cible.webSocketDebuggerUrl); let id = 0; const pend = new Map(); const ecoutes = []; const permanentes = []; const violations = [];
    ws.onmessage = (e) => { const j = JSON.parse(e.data);
      if (j.id && pend.has(j.id)) { const p = pend.get(j.id); pend.delete(j.id); clearTimeout(p.t); p.ok(j.result); return; }
      if (j.method === 'Log.entryAdded' && /Content Security Policy|Refused to/i.test(j.params.entry.text)) violations.push(j.params.entry.text.slice(0, 160));
      for (const l of ecoutes) if (l.m === j.method) l.f(j.params);
      for (const l of permanentes) if (l.m === j.method) l.f(j.params); };
    ws.onclose = () => { for (const p of pend.values()) { clearTimeout(p.t); p.ko(new Error('connexion au navigateur perdue')); } pend.clear(); };
    await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('connexion au navigateur impossible')); setTimeout(() => ko(new Error(`connexion au navigateur : échéance (${AMORCE} ms)`)), AMORCE); });
    const send = (method, params = {}, ms = ECHEANCE) => new Promise((ok, ko) => { const i = ++id; const t = setTimeout(() => { pend.delete(i); ko(new Error(`${method} : pas de réponse en ${ms} ms`)); }, ms); pend.set(i, { ok, ko, t }); ws.send(JSON.stringify({ id: i, method, params })); });
    const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }))?.result?.value;
    // naviguer : passe par about:blank (un changement de hash seul recharge ainsi quand même), rend la main à l'évènement load de la page
    let premier = true; // le premier chargement d'une session paie l'amorçage de la page (Chrome à froid) : borné par max(ECHEANCE, AMORCE)
    // P80-D-37 : toute adresse `…/project.html` sans `vue=` reçoit `vue=graphe` (requête, avant le fragment) : les suites écrites pour le canevas de Projet y restent ; { brut: true } charge l'adresse telle quelle
    const sansVue = (u) => { const [base, ...fr] = u.split('#'); return /\/project\.html(\?|$)/.test(base) && !/[?&]vue=/.test(base) ? [base + (base.includes('?') ? '&' : '?') + 'vue=graphe', ...fr].join('#') : u; };
    // 80-13 : la mémoire de session des tiroirs (vf-tiroirs:*) rouvre un tiroir au chargement suivant ; elle ne passe pas d'une page à l'autre d'une suite
    // (le tiroir ouvert d'un scénario ferait basculer le clic du suivant), sauf { garderTiroirs: true } (test-cockpit-lien-vue.sh la mesure)
    const OUBLIER = "Object.keys(sessionStorage).filter((k) => k.startsWith('vf-tiroirs:')).forEach((k) => sessionStorage.removeItem(k))";
    const naviguer = async (url, { brut = false, echec = false, garderTiroirs = false } = {}) => {
      if (!brut) url = sansVue(url);
      if (!garderTiroirs) await ev(OUBLIER);
      violations.length = 0; const ms = premier ? Math.max(ECHEANCE, AMORCE) : ECHEANCE; premier = false;
      await send('Page.navigate', { url: 'about:blank' }, ms);
      const charge = new Promise((ok) => ecoutes.push({ m: 'Page.loadEventFired', f: ok }));
      await send('Page.navigate', { url }, ms);
      await Promise.race([charge, pause(ms).then(() => { throw new Error(`chargement de ${url} : événement load absent en ${ms} ms`); })]);
      ecoutes.length = 0;
      // 79-16 R9 : une page de la coquille se dit prête par `data-vf-pret = oui` (ou, avec { echec: true }, par un premier chargement en échec) ; une page sans coquille n'attend rien
      await attendre(`location.href !== 'about:blank' && document.readyState === 'complete'`, 'page chargée (hors about:blank)', ms); // l'évènement load d'about:blank peut arriver après l'enregistrement de l'écoute
      if (await ev('!!window.VF_COQUILLE')) await attendre(echec ? `window.VF_COQUILLE.etat().phase === 'echec'` : `document.documentElement.dataset.vfPret === 'oui'`, echec ? 'coquille en échec' : 'coquille prête', ms);
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
    await send('Page.enable', {}, AMORCE); if (csp) await send('Log.enable', {}, AMORCE);
    const ecouter = (m, f) => { permanentes.push({ m, f }); }; // écoute permanente d'un évènement du protocole (relevé réseau, 79-16)
    return { send, ev, naviguer, attendre, stable, fermer, violations, port, ecouter };
  } catch (e) { await fermer(); throw e; }
}

// ---- aides « mesurer une fois posé » (voir l'en-tête) ----
const identiques = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const lireSur = async (lire) => { try { const v = await lire(); return { v, ok: v !== undefined }; } catch { return { v: undefined, ok: false }; } }; // undefined (s.ev d'une exception de page, ou rien à rendre) = non-lecture
const vrai = (predicat, v) => { try { return !!predicat(v); } catch { return false; } };
export async function stabiliser(lire, { pas = 250, max = 10000 } = {}) {
  const fin = Date.now() + max; let prec = null, der;
  do { const c = await lireSur(lire); der = c.v; if (c.ok && prec && identiques(prec.v, c.v)) return c.v; prec = c.ok ? c : null; await pause(pas); } while (Date.now() < fin);
  return der;
}
export async function attendreValeur(lire, predicat, { pas = 100, max = 10000 } = {}) {
  const fin = Date.now() + max; let der;
  do { const c = await lireSur(lire); der = c.v; if (c.ok && vrai(predicat, c.v)) return c.v; await pause(pas); } while (Date.now() < fin);
  return der;
}
export async function attendreEtStabiliser(lire, predicat, opts = {}) {
  await attendreValeur(lire, predicat, opts);
  return stabiliser(lire, opts);
}
export function positionPosee(ev, expr, { pas = 120, max = 3000 } = {}) {
  const lire = () => ev(`(() => { try { const e = (${expr}); if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.x, y: r.y, l: r.width, h: r.height, cx: r.x + r.width / 2, cy: r.y + r.height / 2 }; } catch { return null; } })()`);
  return stabiliser(lire, { pas, max });
}

// executer(chrome, corps, opts) : ouvre la session, joue corps(session), imprime UNE ligne JSON ({ erreur } sur échec nommé), ferme Chrome, sort 0.
export async function executer(chrome, corps, opts = {}) {
  let s = null, fini = false;
  const fin = async (o) => { if (fini) return; fini = true; if (s) await s.fermer(); console.log(JSON.stringify(o)); process.exit(0); };
  const g = setTimeout(() => fin({ erreur: `échéance globale dépassée (${GLOBAL} ms)` }), GLOBAL);
  for (const sig of ['SIGTERM', 'SIGINT']) process.on(sig, () => fin({ erreur: `interrompu (${sig})` }));
  try { s = await ouvrir(chrome, opts); const r = await corps(s); clearTimeout(g); await fin(r); } catch (e) { await fin({ erreur: String(e.message) }); }
}
