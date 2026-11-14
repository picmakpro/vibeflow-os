// magasin-chrome.mjs — le magasin d'état dans un vrai Chromium headless (79-17, SOCL-21). Usage : node magasin-chrome.mjs <chrome> <port> <lab> <mode>
//   tracer : (K0, K1) le magasin est chargé sans violation de CSP, un `who` livré atteint le magasin puis la pastille, un changement de planning du lab
//            avance la clé `planning`, l'état est lu par la route, la lecture JSON refuse une adresse hors de l'API sans requête → une ligne JSON
//   onglets: (C1 à C5) six changements d'onglet : aucune inscription ne survit à son onglet, la pastille d'un onglet neuf dit l'état courant sans nouvel
//            événement, le magasin n'est pas ré-exécuté, une perte de connexion pose `perdu` puis le retour `ouvert` → une ligne JSON
// Une page de la coquille : la fenêtre est posée AVANT la navigation. Enveloppe d'EventSource (chrome-onglets.mjs) : __emit(nom, objet) livre aux écouteurs réels.
import fs from 'node:fs';
import path from 'node:path';
import { executer } from './chrome-session.mjs';
import { AMORCE_FLUX } from './chrome-onglets.mjs';

const [, , chrome, port, lab, mode] = process.argv;
const base = `http://127.0.0.1:${port}`;
const AMORCE = AMORCE_FLUX + `;window.__erreurs = []; addEventListener('error', (e) => window.__erreurs.push(String(e.message)));`;
const WHO = `{ seq: 9000, at: Date.now(), who: { workers: [{ kind: 'subagent', id: 'a-magasin', etat: 'actif', role: 'vf-coder', tree: '.', task: 't' }], sources: {} } }`;
const BADGE = "(document.querySelector('#vf-lock .bl') || {}).textContent || ''";

async function preparer(s) {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
  await s.naviguer(base + '/');
  await s.attendre("!!window.__es && window.__es.some((e) => String(e.url).includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et pastille');
}

async function tracer(s) {
  const R = {};
  R.k02 = await s.ev("!!window.VibeFlow && !!window.VibeFlow.state && document.documentElement.dataset.vfPret === 'oui'");
  R.k03 = await s.ev("window.__es.some((e) => String(e.url).includes('/api/vf/events'))");
  R.k04 = await s.ev("(() => { const M = window.VibeFlow; return [Object.isFrozen(M), ['VF_ETAT', 'lire', 'abonner', 'jeton', 'lireJson'].some((k) => k in M)]; })()");
  R.k05 = await s.ev(`(async () => { const r = await fetch('/_vf/ui/70-vf-etat.js'); const m = document.getElementById('vf-coquille-manifeste').textContent;
    return { statut: r.status, etag: !!r.headers.get('etag'), manifeste: m.includes('70-vf-etat.js'), enLigne: [...document.scripts].some((x) => !x.src && x.textContent.includes('VF_ETAT')) }; })()`);
  R.k05.violations = s.violations.length;
  R.k11 = await s.ev("(() => { const E = window.VF_ETAT; return E ? [typeof E, Object.isFrozen(E), ['lire', 'abonner', 'jeton', 'lireJson', 'abonnes', 'CLES'].every((k) => k in E), E.CLES && E.CLES.length] : null; })()");
  R.k12 = await s.ev('window.VF_ETAT && window.VF_ETAT.jeton() === window.VF_COCKPIT_SERVER.token');
  await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert' && !!window.VF_ETAT.lire('etat')", 'connexion ouverte et état lu').catch(() => {});
  R.k13 = await s.ev(`(() => { const E = window.VF_ETAT; const e = E && E.lire('etat'); return E ? [E.lire('connexion'), e && e.schema, e && typeof e.seq,
    performance.getEntriesByType('resource').some((r) => r.name.endsWith('/api/vf/state'))] : null; })()`);
  await s.ev(`window.__n = 0; window.__w = null; window.VF_ETAT.abonner('who', (w) => { window.__n++; window.__w = w; }); window.__emit('who', ${WHO})`).catch(() => {});
  await s.attendre(`${BADGE}.includes('1 au travail')`, 'pastille « 1 au travail »').catch(() => {});
  R.k14 = await s.ev(`(() => { const E = window.VF_ETAT; return E ? [JSON.stringify(E.lire('who')) === JSON.stringify(window.__w), ${BADGE}, window.__n] : null; })()`);
  const avant = await s.ev("window.VF_ETAT && (window.VF_ETAT.lire('planning') || { seq: 0 }).seq");
  await s.ev("window.__p = []; window.VF_ETAT.abonner('planning', (p) => window.__p.push(p))").catch(() => {});
  fs.mkdirSync(path.join(lab, '.planning/phases/02-suite'), { recursive: true });
  fs.writeFileSync(path.join(lab, '.planning/phases/02-suite/02-01-PLAN.md'), '<objective>Faire la suite</objective>\n');
  fs.appendFileSync(path.join(lab, '.planning/ROADMAP.md'), '- [ ] **Phase 2: Suite** - second jet\n');
  await s.attendre('window.__p && window.__p.length > 0', 'changement de planning', 40000).catch(() => {});
  R.k15 = await s.ev(`(() => { const E = window.VF_ETAT; const p = E && E.lire('planning'); return E ? [p && p.seq > ${Number(avant) || 0}, p && typeof p.at, window.__p.length > 0 && Object.keys(window.__p[0]).sort().join()] : null; })()`);
  R.k16 = await s.ev(`(async () => { const E = window.VF_ETAT; if (!E) return null; const vus = []; const f = window.fetch; window.fetch = (u, o) => { vus.push(String(u)); return f.call(window, u, o); };
    let ok = null, refus = null; try { const j = await E.lireJson('/api/vf/state'); ok = j && j.schema; } catch { ok = 'rejete'; }
    try { await E.lireJson('/api/export'); refus = 'accepte'; } catch (e) { refus = e.statut; } window.fetch = f;
    return [ok, refus, vus.some((u) => u.includes('/api/export')), window.__erreurs.length]; })()`);
  return R;
}

async function onglets(s) {
  const R = { exc: [] };
  await s.send('Runtime.enable');
  s.ecouter('Runtime.exceptionThrown', (p) => R.exc.push(String((p.exceptionDetails.exception || {}).description || p.exceptionDetails.text).slice(0, 300)));
  s.ecouter('Runtime.consoleAPICalled', (p) => { if (p.type === 'error') R.exc.push('console: ' + p.args.map((x) => x.value || x.description).join(' ').slice(0, 300)); });
  // l'onglet Équipe recharge la page quand les agents du who diffèrent de ses cartes (au plus une fois par 15 s, clé de sessionStorage) : le who d'essai
  // est inconnu de la fixture, la clé est donc posée dans l'avenir pour que le rechargement n'ait pas lieu pendant la mesure (comportement de 72, non testé ici)
  await s.ev("sessionStorage.setItem('vf-equipe-rechargement', String(Date.now() + 3600000))");
  await s.ev(`window.__emit('who', ${WHO}); window.__t0 = performance.timeOrigin`);
  R.t0 = await s.ev('performance.timeOrigin'); // un rechargement de page change l'origine des temps : la portée d'un onglet retire les propriétés posées sur window
  await s.attendre(`${BADGE}.includes('1 au travail')`, 'pastille « 1 au travail »');
  await s.attendre("window.VF_ETAT.lire('connexion') === 'ouvert'", 'connexion ouverte');
  R.n0 = await s.ev('JSON.stringify(window.VF_ETAT.abonnes())');
  R.pas = []; const froid = {};
  for (const o of ['code', 'equipe', 'projet', 'projet', 'code', 'equipe']) {
    await s.ev(`window.VF_COQUILLE.chargerOnglet('${o}')`);
    // référence d'un chargement à froid : Code n'inscrit rien (n0) ; Projet porte les abonnés de la Synthèse (77) et Équipe ceux de la régie (73-08), constants à chaque visite
    // 76-07 : la section Traçabilité du panneau d'un projet (74-vf-trace.js) s'abonne à `planning` tant que l'onglet Projet est affiché, une seule fois par affichage :
    // le premier chargement à froid de Projet compte donc un abonné `planning` de plus que le départ (PLUS1), jamais davantage
    const n = await s.ev('JSON.stringify(window.VF_ETAT.abonnes())'); if (o !== 'code' && froid[o] === undefined) froid[o] = n;
    const plus1 = o !== 'projet' || (JSON.parse(froid[o]).planning === JSON.parse(R.n0).planning + 1 + (R.syn || 0));
    R.pas.push([o, n === (o === 'code' ? R.n0 : froid[o]) && plus1 && (await s.ev('performance.timeOrigin')) === R.t0]); // jamais un rechargement de page
  }
  R.badge = await s.ev(BADGE);
  R.memeObjet = await s.ev(`performance.timeOrigin === ${R.t0} && window.VF_ETAT.lire('who') !== null`);
  await s.ev("(() => { const e = window.__es.filter((x) => x.readyState !== 2).pop(); if (e && e.onerror) e.onerror({ type: 'error' }); })()");
  await s.attendre("window.VF_ETAT.lire('connexion') === 'perdu'", 'connexion perdue');
  R.perdu = await s.ev(BADGE);
  await s.attendre("window.VF_ETAT.lire('connexion') === 'ouvert'", 'connexion rétablie', 30000).catch(() => {});
  await s.attendre(`${BADGE}.includes('au travail')`, 'pastille rétablie', 10000).catch(() => {});
  R.retour = [await s.ev("window.VF_ETAT.lire('connexion')"), await s.ev(BADGE)];
  return R;
}

await executer(chrome, async (s) => {
  await preparer(s);
  if (mode === 'tracer') return tracer(s);
  if (mode === 'onglets') return onglets(s);
  return { erreur: 'mode inconnu : ' + mode };
}, { csp: true });
