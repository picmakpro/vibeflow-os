#!/usr/bin/env node
// chrome-synthese.mjs — banc navigateur commun des suites de la Synthèse (77-05 ; 77-06, 77-07 et 77-08 y ajoutent leurs outils et leurs mesures, sans le recréer).
// Outils (chacun a sa sonde positive dans test-cockpit-synthese-page.sh, section « B ») :
//   labFixture(dossier)            dépôt git fabriqué sous <dossier>/RACINE-MARQUEUR-77 ; STATE avec MARQUEUR-PROSE-77 et une puce de blocage piégée (balise posant window.__xss)
//   AMORCE_ECOUTEURS               addEventListener/removeEventListener instrumentés AVANT tout script de page : window.__nbEcout() = écouteurs vivants sur document et window
//   AMORCE_VISITE                  la visite guidée se lit « déjà vue » (deux clés) : elle ne s'ouvre pas, n'écrit rien, ne prend ni le focus ni Échap
//   ecrireStockageAvantChargement(s, cle, valeur)   script posé avant la page : la valeur est lue par la page
//   journalReseau(s)               journal CDP des requêtes { url, methode, type, jeton } (jeton = en-tête de jeton présent)
//   sondeStyle(s, selecteur, proprietes)   style calculé d'un élément
//   mesurerUneFoisPose(lire, opts)  attend la stabilité (jamais une pause fixe qui juge) ; { valeur, obtenue } : « mesure obtenue » non vide avant toute comparaison
//   sourceTemoin() / ecrireBlocTemoin(copie)  fichier ui/74-vf-synthese-temoin.js posé dans une COPIE du module (jamais dans le module livré) : des blocs au registre,
//                                  le fournisseur de la ligne-résumé (majResume), un rafraîchissement déclenché par la sonde
//   (77-08, chacun avec sa sonde positive dans test-cockpit-synthese-visite.sh, section « B »)
//   deuxiemeOnglet(s, url)         second onglet du MÊME Chrome (même origine, même stockage) : { send, ev, fermer } ; sonde : un `storage` écrit par le premier arrive au second
//   intercepter(s, motif, reponse) interception CDP (Fetch) des requêtes dont l'adresse porte `motif` : { arreter, vues } ; sonde : la réponse interceptée est vue par la page
//   stockageLu(s, cle)             relecture de localStorage (cle null : toutes les clés) ; sonde : une clé écrite par la page est lue
//   stockageAvant(s, cle, valeur)  valeur posée avant le prochain chargement (null : clé retirée) ; rend retirer(), à appeler avant le chargement suivant
//   labDeuxEtats(dossier)          lab fixture avant (un commit) et après (trois commits de plus) : { lab, avant, apres } ; sonde : le calcul de 77-04 y voit une différence
// CLI : lab <dossier> (imprime le chemin du lab) · lab2 <dossier> · temoin <copie du module> · scenario <chrome> <port> <nue|temoin> [<fichier d'export>] · visite <chrome> <port> <complet|xss>
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
import { stabiliser, pause } from './chrome-session.mjs';

export const MARQUEUR_RACINE = 'RACINE-MARQUEUR-77', MARQUEUR_PROSE = 'MARQUEUR-PROSE-77';
const git = (lab, ...a) => execFileSync('git', ['-C', lab, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore', env: { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' } });

export function labFixture(dossier) {
  const lab = path.join(dossier, MARQUEUR_RACINE), pl = path.join(lab, '.planning'), put = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
  put(path.join(lab, 'src/util.js'), 'export const u = () => 1;\n');
  put(path.join(pl, 'ROADMAP.md'), '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n');
  put(path.join(pl, 'STATE.md'), `---\nstatus: executing\ncurrent_phase: 2\nlast_activity_desc: ${MARQUEUR_PROSE}\n---\n\n# State\n\n### Blockers/Concerns\n\n- <img src=x onerror="window.__xss=1"> blocage piégé\n`);
  put(path.join(pl, 'phases/01-socle/01-01-PLAN.md'), '<objective>Faire le socle</objective>\n'); put(path.join(pl, 'phases/01-socle/01-01-SUMMARY.md'), 'ok\n');
  git(lab, 'init', '-q'); git(lab, 'add', '-A'); git(lab, 'commit', '-q', '-m', 'init');
  return lab;
}

export const AMORCE_ECOUTEURS = `(() => { const reg = []; const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener; const cap = (o) => !!(o === true || (o && o.capture));
  EventTarget.prototype.addEventListener = function (t, f, o) { if (f) reg.push([this, t, f, cap(o)]); return A.call(this, t, f, o); };
  EventTarget.prototype.removeEventListener = function (t, f, o) { const i = reg.findLastIndex((e) => e[0] === this && e[1] === t && e[2] === f && e[3] === cap(o)); if (i >= 0) reg.splice(i, 1); return R.call(this, t, f, o); };
  window.__nbEcout = () => ({ document: reg.filter((e) => e[0] === document).length, window: reg.filter((e) => e[0] === window).length }); })();`;
// la visite guidée se lit « déjà vue » (clés tour-seen:… et vibeflow-cockpit:visite:…), sans rien écrire : une visite qui s'ouvre vole le focus et prend Échap
export const AMORCE_VISITE = `(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) { return /tour-seen:|^vibeflow-cockpit:visite:/.test(String(k)) ? 'true' : g.call(this, k); }; })();`;
export const ecrireStockageAvantChargement = (s, cle, valeur) => s.send('Page.addScriptToEvaluateOnNewDocument', { source: `try { localStorage.setItem(${JSON.stringify(cle)}, ${JSON.stringify(valeur)}); } catch {}` });

export function labDeuxEtats(dossier) {
  const lab = labFixture(dossier); git(lab, 'branch', '-M', 'main'); // la base du cockpit est la branche `main` (arbres.mjs) : sans elle, le sommet de la base est inconnu
  const sha = () => execFileSync('git', ['-C', lab, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(), avant = sha();
  for (const i of [1, 2, 3]) { fs.writeFileSync(path.join(lab, `src/suite${i}.js`), `export const s${i} = ${i};\n`); git(lab, 'add', '-A'); git(lab, 'commit', '-q', '-m', `suite ${i}`); }
  return { lab, avant, apres: sha() };
}
export const stockageLu = (s, cle) => s.ev(cle === null ? `Object.fromEntries(Object.keys(localStorage).map((k) => [k, localStorage.getItem(k)]))` : `localStorage.getItem(${JSON.stringify(cle)})`);
export async function stockageAvant(s, cle, valeur) {
  const pose = valeur === null ? `localStorage.removeItem(${JSON.stringify(cle)})` : `localStorage.setItem(${JSON.stringify(cle)}, ${JSON.stringify(valeur)})`;
  const { identifier } = await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `try { ${pose}; } catch {}` });
  return () => s.send('Page.removeScriptToEvaluateOnNewDocument', { identifier });
}
export async function intercepter(s, motif, reponse) {
  let actif = true, n = 0; await s.send('Fetch.enable', { patterns: [{ urlPattern: `*${motif}*` }] });
  s.ecouter('Fetch.requestPaused', (p) => {
    if (!actif) return void s.send('Fetch.continueRequest', { requestId: p.requestId }).catch(() => {});
    n++; s.send('Fetch.fulfillRequest', { requestId: p.requestId, responseCode: reponse.statut, responseHeaders: [{ name: 'Content-Type', value: 'application/json' }],
      body: Buffer.from(reponse.corps || '{}').toString('base64') }).catch(() => {});
  });
  return { arreter: async () => { actif = false; await s.send('Fetch.disable'); }, vues: () => n };
}
export async function deuxiemeOnglet(s, url) {
  const cible = await (await fetch(`http://127.0.0.1:${s.port}/json/new?about:blank`, { method: 'PUT' })).json();
  const ws = new WebSocket(cible.webSocketDebuggerUrl), pend = new Map(); let id = 0;
  ws.onmessage = (e) => { const j = JSON.parse(e.data); if (j.id && pend.has(j.id)) { pend.get(j.id)(j.result); pend.delete(j.id); } };
  await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('second onglet : connexion impossible')); });
  const send = (method, params = {}) => new Promise((ok) => { const i = ++id; pend.set(i, ok); ws.send(JSON.stringify({ id: i, method, params })); });
  const ev = async (x) => (await send('Runtime.evaluate', { expression: x, returnByValue: true, awaitPromise: true }))?.result?.value;
  await send('Page.enable'); await send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_VISITE }); await send('Page.navigate', { url });
  for (let i = 0; i < 100 && (await ev(`document.documentElement.dataset.vfPret === 'oui'`)) !== true; i++) await pause(100);
  return { send, ev, fermer: async () => { ws.close(); await fetch(`http://127.0.0.1:${s.port}/json/close/${cible.id}`).catch(() => {}); } };
}

export async function journalReseau(s) {
  const j = []; await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => j.push({ url: p.request.url, methode: p.request.method, type: p.type, jeton: Object.keys(p.request.headers).some((k) => k.toLowerCase() === 'x-vf-cockpit-token') }));
  return j;
}
export const sondeStyle = (s, selecteur, proprietes) => s.ev(`(() => { const e = document.querySelector(${JSON.stringify(selecteur)}); if (!e) return null; const c = getComputedStyle(e); return Object.fromEntries(${JSON.stringify(proprietes)}.map((p) => [p, c.getPropertyValue(p)])); })()`);
export async function mesurerUneFoisPose(lire, opts = {}) { const valeur = await stabiliser(lire, opts); return { valeur, obtenue: valeur !== undefined && valeur !== null && valeur !== '' }; }

export const sourceTemoin = () => `// témoin du banc 77-05 : posé dans une COPIE du module (jamais dans le module livré), ré-exécuté à chaque onglet comme tout script par onglet
(() => {
  const R = (window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || []); window.__vfTemoinRef = R; // inscrit AVANT la coquille (ordre alphabétique : « - » précède « . »)
  const etat = { texte: 'TEMOIN-RESUME-77', titre: 'TEMOIN-TITRE-77' }; let ctx0 = null, nbInstall = 0, nbRendu = 0;
  const bloc = (id, fournisseur) => Object.freeze({ id, titre: 'Titre ' + id,
    installer: (ctx) => { ctx0 = ctx; nbInstall++; if (fournisseur) ctx.majResume(etat); return () => { ctx0 = null; }; },
    present: () => true,
    rendre: (c) => { nbRendu++; c.textContent = ''; const p = document.createElement('p'); p.dataset.temoin = id; p.textContent = 'T-' + id; c.appendChild(p);
      if (id === 'visite') { const b = document.createElement('button'); b.type = 'button'; b.dataset.temoinBouton = '1'; b.textContent = 'Bouton témoin'; c.appendChild(b);
        for (let i = 0; i < 80; i++) { const l = document.createElement('p'); l.textContent = 'Ligne de remplissage ' + i; c.appendChild(l); } } },
    ouvrir: () => {} });
  for (const id of ['burnup', 'visite', 'inconnu', 'methode']) R.push(bloc(id, id === 'visite'));
  window.__vfTemoinRafraichir = () => { etat.texte += '-bis'; etat.titre += '-bis'; if (ctx0) ctx0.majResume({ texte: etat.texte, titre: etat.titre });
    const p = document.querySelector('[data-temoin="visite"]'); if (p) p.textContent = 'T-visite-bis'; };
  window.__vfTemoinCompte = () => ({ nbInstall, nbRendu });
})();
`;
export const ecrireBlocTemoin = (copie) => fs.writeFileSync(path.join(copie, 'skills/cockpit-moteur/assets/ui/74-vf-synthese-temoin.js'), sourceTemoin());

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  const [, , mode, ...a] = process.argv;
  if (mode === 'lab') console.log(labFixture(a[0]));
  else if (mode === 'lab2') console.log(labDeuxEtats(a[0]).lab);
  else if (mode === 'visite') import('./chrome-synthese-visite.mjs').then(({ jouer }) => jouer(...a));
  else if (mode === 'temoin') ecrireBlocTemoin(a[0]);
  else if (mode === 'scenario') import('./chrome-synthese-scenarios.mjs').then(({ jouer }) => jouer(...a)); // sans attente de tête : le module des scénarios importe celui-ci
  else { console.error('usage : lab <dossier> | lab2 <dossier> | visite <chrome> <port> <complet|xss> | temoin <copie> | scenario <chrome> <port> <nue|temoin> [<export>]'); process.exit(2); }
}
