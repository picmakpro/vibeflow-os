// vf-cockpit-live — le direct du cockpit, sans serveur HTTP propre (67-04, P67-D-13, P67-D-16 ; promu du spike 003).
// Surveille <root>/.planning et le dossier des verrous (<git-common-dir>/vf-driver), reconstruit le graphe Projet en
// processus, pousse le diff de statuts à `onEvent`, et réécrit <sortie>/project.html par fichier temporaire puis
// rename quand la structure change. Lecture seule sur le dépôt observé.
// Export : startLive({ root, sortie, onEvent, log, mode }) -> { etat(), snapshot(), stop() }.
//   mode : 'auto' (fs.watch récursif, repli par scrutation des mtimes si l'appel lève ou si le watcher échoue),
//          'poll' (scrutation d'emblée) ; défaut = VF_COCKPIT_WATCH. etat().mode vaut 'watch' ou 'poll'.
// Événements : patch { seq, at, patch, vf? } · structural { seq, at } · who { seq, at, who } · lock { seq, at, lock } · git { seq, at, sig } (78-09 : signal sans contenu, la page relit ses routes).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { envEnfant } from './vf-cockpit-env.mjs';
import { buildProjectGraph } from './vf-cockpit-project.mjs';
import { collectWho } from './vf-cockpit-who.mjs';
import { driverLockScript, gitCommonDir, resolveScriptsDir, confiner } from './vf-cockpit-paths.mjs';
import { extraireGraphe, insererGraphe } from './vf-cockpit-embed.mjs';
import { signatureGit } from './vf-cockpit-git-signature.mjs';

const IGNORE = /(^|\/)\.git(\/|$)|\.tmp$|~$|\.swp$/;
const POLL_MS = 2000, DEBOUNCE_MS = 300, HOLD_MS = 600, NET_MS = 5000;

const index = (g) => {
  const m = new Map();
  for (const n of g.nodes) m.set('n:' + n.id, { st: n.st || '', foot: n.foot || '', sum: n.summary || '' }); // sum : le résumé d'une mission (« 2 nœuds, 1 fait ») suit le direct comme son pied
  for (const f of g.files) m.set('f:' + f.p, { st: f.st || '', foot: f.foot || '' });
  return m;
};
const diff = (a, b) => {
  const patch = []; let added = 0, removed = 0;
  for (const [ref, v] of b) { const o = a.get(ref); if (!o) { added++; continue; } if (o.st !== v.st || o.foot !== v.foot || o.sum !== v.sum) patch.push({ ref, ...v }); }
  for (const ref of a.keys()) if (!b.has(ref)) removed++;
  return { patch, structural: added + removed > 0, retrait: removed > 0, removed }; // retrait : même avec un ajout, une lecture tronquée en fait partie
};
// scrutation : « chemin -> mtime:taille » de tout fichier sous dir (hors chemins ignorés)
const empreinte = (dir) => {
  const out = new Map();
  const walk = (d, rel) => {
    let ents = []; try { ents = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of ents) {
      const r = rel ? rel + '/' + e.name : e.name; if (IGNORE.test(r)) continue;
      if (e.isDirectory()) walk(path.join(d, e.name), r);
      else { try { const s = fs.statSync(path.join(d, e.name)); out.set(r, `${s.mtimeMs}:${s.size}`); } catch {} }
    }
  };
  walk(dir, ''); return out;
};
const changes = (a, b) => [...new Set([...a.keys(), ...b.keys()])].filter((k) => a.get(k) !== b.get(k));

// signature de la liste « qui » (PU-G-162 : testable seule, déplacée hors de startLive sans changer son corps) : poussée seulement quand la liste change, pas à chaque seconde d'âge qui passe
export const whoSig = (w) => JSON.stringify((w.workers || []).map((x) => [x.kind, x.id, x.tree, x.branch || '', !!x.stale, x.titre || '', x.task || '', x.parent || '', x.etat || '', x.action ? `${x.action.verbe} ${x.action.cible}` : '', x.rattachement ? [x.rattachement.etat, x.rattachement.dag, x.rattachement.noeud, x.rattachement.raison].join('|') : '']));

// aClient : y a-t-il un onglet connecté au flux ? (AUDC-H2) Sans onglet, le filet ne collecte rien ; `reveil()` rattrape à la connexion. Défaut : toujours vrai (comportement d'avant).
export function startLive({ root, sortie, onEvent = () => {}, log = () => {}, mode = process.env.VF_COCKPIT_WATCH || 'auto', aClient = () => true }) {
  root = path.resolve(root);
  const common = gitCommonDir(root);
  const driverDir = process.env.VF_DRIVER_DIR || (common && path.join(common, 'vf-driver'));
  const scriptsDir = resolveScriptsDir(sortie);
  const state = { mode: mode === 'poll' ? 'poll' : 'watch', seq: 0, derniereMaj: null };
  const timers = new Set(), watchers = new Map();
  let stopped = false;

  const lockStatus = () => {
    const dl = driverLockScript({ scriptsDir, labRoot: root, home: os.homedir() });
    if (dl.etat === 'absent') return { available: false };
    try { return JSON.parse(execFileSync('bash', [dl.chemin, 'status', '--all'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 10000, env: envEnfant(root) })); }
    catch (e) { try { return JSON.parse(e.stdout); } catch { return { error: String(e.message).slice(0, 200) }; } }
  };
  const whoNow = (verrous) => { try { return collectWho(root, { scriptsDir, verrous, officiel: true }); } catch (e) { return { workers: [], sources: {}, error: e.message }; } };
  // « qui » : poussé seulement quand la liste change (pas à chaque seconde d'âge qui passe)

  let graph = buildProjectGraph(root), idx = index(graph), lock = lockStatus(), who = whoNow(lock), gitSig = null, gitSemee = false; // 78-09
  // A5 : la signature Git est asynchrone ; le premier calcul SEME gitSig sans événement (comme avant), les suivants (filet) n'émettent qu'au changement, et seulement une fois la graine posée
  signatureGit(root, { commun: common }).then((gs) => { if (!stopped && !gitSemee) { gitSemee = true; gitSig = gs; } }, () => {});
  const snapshot = () => ({ seq: state.seq, lock, who });
  const emit = (nom, data) => { try { onEvent(nom, data); } catch (e) { log('error', `onEvent(${nom}) : ${e.message}`); } };

  // project.html : le gabarit est la page courante de la sortie ; meta.root et meta.vfLogos viennent de l'assemblage
  const ecrirePage = (g) => {
    const f = path.join(sortie, 'project.html');
    confiner(root, f); confiner(root, f + '.tmp'); // aucun lien symbolique dans la sortie : ni lu, ni écrasé
    const html = fs.readFileSync(f, 'utf8');
    try { const old = extraireGraphe(html); g.meta.root = old.meta?.root; g.meta.vfLogos = old.meta?.vfLogos; g.meta.vfGit = old.meta?.vfGit; /* 78-04 */ } catch {}
    fs.writeFileSync(f + '.tmp', insererGraphe(html, g));
    fs.renameSync(f + '.tmp', f); // jamais de page à moitié écrite
  };

  const refresh = (reasons) => { try { refreshSur(reasons); } catch (e) { log('error', `refresh : ${e.message}`); } };
  const refreshSur = (reasons) => {
    if (stopped) return;
    let g;
    try { g = buildProjectGraph(root); } catch (e) { log('error', `graphe illisible, état précédent gardé : ${String(e.message).slice(0, 200)}`); return; }
    const nidx = index(g);
    const { patch, structural, retrait, removed } = diff(idx, nidx);
    // dag.sh save() peut laisser un fichier tronqué : tout retrait (seul ou avec un ajout) n'est cru qu'à la seconde lecture, 600 ms plus tard
    if (retrait && !reasons.includes('confirm')) {
      log('hold', `${removed} carte(s) disparue(s) : seconde lecture avant de croire`);
      const t = setTimeout(() => { timers.delete(t); refresh(['confirm', ...reasons]); }, HOLD_MS); timers.add(t);
      return;
    }
    const nlock = aClient() ? lockStatus() : lock; // AUDC-H2 : sans onglet, le verrou n'est pas interrogé (la connexion suivante le relit)
    const lockChanged = JSON.stringify(nlock) !== JSON.stringify(lock);
    const vfChanged = JSON.stringify(g.meta?.vf) !== JSON.stringify(graph.meta?.vf);
    graph = g; idx = nidx; lock = nlock; state.seq++; state.derniereMaj = new Date().toISOString();
    // la page sur disque suit TOUT changement (F5, nouvel onglet, réponses locales et vf-cockpit-query lisent project.html) : avant l'événement
    if (structural || patch.length || vfChanged) { try { ecrirePage(g); } catch (e) { log('error', `project.html non réécrit : ${e.message}`); } }
    log('refresh', `${patch.length} patch(s)${structural ? ', structure' : ''}${lockChanged ? ', verrou' : ''}`);
    const at = Date.now();
    if (structural) emit('structural', { seq: state.seq, at });
    else if (patch.length || vfChanged) emit('patch', { seq: state.seq, at, patch, ...(vfChanged ? { vf: g.meta.vf } : {}) });
    if (lockChanged) emit('lock', { seq: state.seq, at, lock });
  };

  // anti-rebond : une seule régénération par rafale
  let debounce = null, pending = [];
  const poke = (src, file) => {
    if (file && src === 'planning' && IGNORE.test(String(file).replace(/\\/g, '/'))) return;
    pending.push(`${src}:${file || '?'}`);
    clearTimeout(debounce);
    debounce = setTimeout(() => { const r = pending; pending = []; refresh(r); }, DEBOUNCE_MS);
  };

  const scruter = (src, dir) => {
    let prev = empreinte(dir);
    const t = setInterval(() => { try { const cur = empreinte(dir); const ch = changes(prev, cur); prev = cur; if (ch.length) poke(src, ch[0]); } catch (e) { log('error', `scrutation ${src} : ${e.message}`); } }, POLL_MS);
    t.unref?.(); timers.add(t);
    watchers.set(src, { close: () => clearInterval(t) });
    log('watch', `scrutation de ${src} (${POLL_MS} ms)`);
  };
  const surveiller = (src, dir) => {
    if (watchers.has(src) || !dir || !fs.existsSync(dir)) return;
    if (state.mode === 'poll') return scruter(src, dir);
    try {
      const w = fs.watch(dir, { recursive: true }, (_, f) => poke(src, f));
      w.on('error', () => { try { w.close(); } catch {} watchers.delete(src); state.mode = 'poll'; log('watch', `watcher perdu : ${src}, repli`); surveiller(src, dir); });
      watchers.set(src, w); log('watch', `surveille ${src}`);
    } catch (e) { state.mode = 'poll'; log('watch', `récursif refusé (${e.message}), repli`); scruter(src, dir); }
  };
  surveiller('planning', path.join(root, '.planning'));
  surveiller('driver', driverDir);

  // filet toutes les 5 s : l'âge d'un verrou avance sans écriture, et vf-driver/ peut naître après le démarrage.
  // AUDC-H2 : UN seul appel au verrou par tour (partagé avec « qui »), et aucune collecte tant qu'aucun onglet n'écoute.
  let dernierTour = Date.now();
  const tour = () => {
    dernierTour = Date.now();
    const n = lockStatus();
    const nw = whoNow(n);
    if (whoSig(nw) !== whoSig(who)) { who = nw; emit('who', { seq: ++state.seq, at: Date.now(), who }); }
    if (JSON.stringify(n) !== JSON.stringify(lock)) { lock = n; emit('lock', { seq: ++state.seq, at: Date.now(), lock }); }
    signatureGit(root, { commun: common }).then((gs) => { // 78-09 : refs, worktrees, index ; un événement sans charge au seul changement. A5 : asynchrone, un git muet ne gèle plus la boucle
      if (stopped || !gitSemee) return;
      if (gs && gs !== gitSig) { gitSig = gs; emit('git', { seq: ++state.seq, at: Date.now(), sig: gs.slice(0, 16) }); }
    }, () => {});
  };
  const filet = setInterval(() => { try {
    surveiller('driver', driverDir);
    if (aClient()) tour();
  } catch (e) { log('error', `filet : ${e.message}`); } }, NET_MS);
  filet.unref?.(); timers.add(filet);

  return {
    etat: () => ({ mode: state.mode, seq: state.seq, derniereMaj: state.derniereMaj }),
    snapshot,
    // à la connexion d'un onglet : l'instantané n'a pas bougé depuis un moment (aucune collecte sans onglet), un tour le remet à jour avant d'être servi ; au plus un tour par période du filet
    reveil() { if (!stopped && Date.now() - dernierTour >= NET_MS) { try { tour(); } catch (e) { log('error', `réveil : ${e.message}`); } } },
    stop() { stopped = true; clearTimeout(debounce); for (const t of timers) { clearTimeout(t); clearInterval(t); } for (const w of watchers.values()) { try { w.close(); } catch {} } },
  };
}
