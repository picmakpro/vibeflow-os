#!/usr/bin/env node
// vf-cockpit-who — « qui est au travail ? » (socle du cockpit, P67-D-12, promu du spike 004). Lecture seule.
// Exports : collectWho(root, opts) -> schéma vibeflow/cockpit-who@2 (JAMAIS de champ `doing`, P67-D-14)
//           revealDoing(root, id, opts) -> schéma vibeflow/cockpit-doing@1 (dernière commande, à la demande)
//           revealTranscript(root, id, opts) -> schéma vibeflow/cockpit-transcript@2 (mandat d'agent, fil daté de messages et d'outils : jamais une sortie d'outil, P69-D-19)
//           agentsConnus(root, opts) -> sessions et sous-agents seuls (collecte allégée d'un clic, T-69-06) ; commandeAffichee(cmd)
// Quatre sources disque : sessions Claude Code (~/.claude/projects), sous-agents (meta.json), verrous et
// registre (driver-lock.sh, résolu hors de l'arbre observé : T-67-06), DAG de mission (nœuds running).
// Chaque source rend son état (lue, absente, erreur, forme-inconnue) : un « personne » n'est jamais aveugle.
// CLI : node vf-cockpit-who.mjs <root> [--fresh 180] [--json]
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { driverLockScript, gitCommonDir, resolveScriptsDir, planningLayout, GIT_SUR, shBorne } from './vf-cockpit-paths.mjs';
import { ls, mtime, readJson, cherche, masque, MAX_MASQUE, ID_RE, premiereLigne } from './vf-cockpit-lecture.mjs';
import { FENETRE, collecteAgents, indexDesNoeuds, rattacher } from './vf-cockpit-equipe.mjs';
import { lireDags, lireConfine } from './vf-cockpit-planning.mjs';
import { arbresGit } from './vf-cockpit-arbres.mjs';
import { lireRegistre, fusionnerRegistre } from './vf-cockpit-registre.mjs';
import { demander, lire } from './vf-cockpit-etat-officiel.mjs';
import { reduireTranscript } from './vf-cockpit-transcript.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sh = shBorne; // timeout, échéance globale de l'émetteur (F-06) et PATH assaini (H-1, 4e argument = le lab) : un git ou un bash bloqué ne gèle pas la boucle

// les listes de clés vérifiées sur Claude Code viennent du contrat versionné, pas du code
const IFACE = readJson(path.join(HERE, 'vf-cockpit-interface.json')) || {};
const CC = IFACE.claudeCode || {};
const REQ_TR = CC.transcript?.requis || ['cwd', 'type', 'message', 'timestamp', 'sessionId'];

// dernière ligne user/assistant d'un jsonl
const tail = (f) => cherche(f, (d) => (d.type === 'user' || d.type === 'assistant' ? d : null));
// forme typée (F3) : un cwd, un type, un horodatage ou un identifiant de session qui n'est pas une chaîne est une ligne hors forme
const formeOk = (d) => !!d && REQ_TR.every((k) => k in d) && ['cwd', 'type', 'timestamp', 'sessionId'].every((k) => typeof d[k] === 'string');

// dernier arbre cité par une ligne user/assistant d'un transcript (P78-D-26) : première lecture par `cherche` (fenêtres bornées), puis mémo par fichier ; un fichier qui a grossi ne relit que les octets
// ajoutés (8 Mio au plus). Seul un chemin d'arbre connu est retenu, jamais une ligne du transcript ; le mémo est borné (la plus ancienne entrée part) et invalidé si la liste des arbres change.
const MEMO_ARBRES = new Map(), MEMO_MAX = 512, AJOUT_MAX = 8 << 20;
function dernierArbre(fichier, trees, cite) {
  const sig = trees.join('\0'); let st; try { st = fs.statSync(fichier); } catch { return null; }
  if (!st.isFile()) return null; // un tube (FIFO) bloquerait l'ouverture
  const m = MEMO_ARBRES.get(fichier); let arbre;
  if (m && m.sig === sig && m.taille === st.size) return m.arbre;
  const accepte = (d) => (d.type === 'user' || d.type === 'assistant' ? cite(d) : null);
  if (m && m.sig === sig && st.size > m.taille && st.size - m.taille <= AJOUT_MAX) {
    arbre = m.arbre; let fd = null;
    try {
      fd = fs.openSync(fichier, 'r'); const len = st.size - m.taille, buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, m.taille);
      for (const l of buf.toString('utf8').split('\n')) { if (!l.trim()) continue; let d; try { d = JSON.parse(l); } catch { continue; } arbre = (d && accepte(d)) || arbre; }
    } catch { arbre = cherche(fichier, accepte); } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
  } else arbre = cherche(fichier, accepte);
  MEMO_ARBRES.delete(fichier); MEMO_ARBRES.set(fichier, { sig, taille: st.size, arbre: arbre || null });
  if (MEMO_ARBRES.size > MEMO_MAX) MEMO_ARBRES.delete(MEMO_ARBRES.keys().next().value);
  return arbre || null;
}

// contexte de collecte des sessions et sous-agents : arbres git du lab, portée, étiquettes
function contexte(root, { fresh, now, home, officiel = false }) {
  root = path.resolve(root);
  const arbres = arbresGit(root); // l'analyse de la liste des arbres git vit dans vf-cockpit-arbres.mjs
  const branchOf = new Map(arbres.map((a) => [a.chemin, a.branche]));
  // la branche vient de la liste des arbres git pour TOUT arbre connu (cwd ou activité) ; le gitBranch du transcript est celui de l'arbre de LANCEMENT : repli seulement
  const branche = (t, ...transcript) => branchOf.get(t) || transcript.find(Boolean) || '';
  const trees = arbres.map((a) => a.chemin);
  const real = (p) => { try { return fs.realpathSync(p); } catch { return p; } };
  const inScope = (cwd) => { if (typeof cwd !== 'string' || !cwd) return null; const r = real(cwd); return trees.filter((t) => r === t || r.startsWith(t + path.sep)).sort((a, b) => b.length - a.length)[0] || null; };
  const label = (t) => (t === trees[0] ? 'arbre principal' : path.relative(trees[0], t) || t);
  // le cwd d'un transcript reste celui du lancement : on préfère l'arbre le plus profond cité par le dernier appel, sinon (P78-D-26) le dernier arbre cité sur l'ensemble du transcript
  const cite = (d) => {
    const txt = JSON.stringify(d?.message?.content || '');
    return trees.filter((t) => t !== trees[0] && txt.includes(t)).sort((a, b) => b.length - a.length)[0] || null;
  };
  const byActivity = (d, fallback, fichier) => {
    const hit = cite(d) || (fichier ? dernierArbre(fichier, trees, cite) : null);
    return hit ? { tree: hit, how: 'activité' } : { tree: fallback, how: 'cwd' };
  };

  const projects = path.join(home, '.claude', 'projects');
  return { root, trees, label, collecte: () => {
    if (officiel) demander({ home, cwd: root }); // asynchrone : la collecte ne l'attend jamais (AUDC-V8)
    return collecteAgents({ projects, now, fresh, fenetre: FENETRE, inScope, label, branche, byActivity, CC, tail, formeOk, root, officiel: officiel ? lire(home) : null });
  } };
}

// sessions et sous-agents seuls : pas de verrous, de registre ni de DAG (un clic ne rejoue pas toute la collecte)
export function agentsConnus(root, { fresh = 180, now = Date.now(), home = os.homedir() } = {}) {
  return contexte(root, { fresh, now, home }).collecte().workers;
}

const rolesDe = (ws) => new Map(ws.filter((w) => w.kind === 'subagent' && typeof w.role === 'string' && w.role).map((w) => [w.id, w.role]));

// collecte interne : les travailleurs gardent `_tr` (chemin du transcript) hors de la sortie publique
function gather(root, { fresh = 180, ttl = Number(process.env.VF_DRIVER_TTL) || 1800, now = Date.now(), home = os.homedir(), scriptsDir, verrous, officiel = false } = {}) { // AUDC-H2 : `verrous` = le statut déjà lu par l'appelant (un seul appel au verrou par cycle) ; AUDC-D1 : `officiel` = la vue du cockpit lit les seules sources officielles
  const cx = contexte(root, { fresh, now, home, officiel }); root = cx.root;
  const { trees, label } = cx; const sources = {}; const workers = [];
  // 1 + 2 — sessions et sous-agents, en arbre (vf-cockpit-equipe.mjs : fenêtre de 24 h, forme Claude Code lue du contrat)
  const eq = cx.collecte();
  workers.push(...eq.workers); sources.sessions = eq.source;
  // « écrit à <rôle> » (Q2a) : le destinataire brut (`_to`) est résolu en rôle par la collecte ; inconnu -> « un agent » ; jamais un identifiant, et `_to` ne sort pas
  const roles = rolesDe(eq.workers);
  for (const w of eq.workers) if (w.action && '_to' in w.action) { w.action.cible = roles.get(w.action._to) || 'un agent'; delete w.action._to; }
  const presents = new Set(eq.workers.filter((w) => w.kind === 'subagent').map((w) => w.id)); const registre = new Map(); // carte privée, jamais dans la sortie publique

  // 3 — verrous et registre (script résolu hors de l'arbre observé)
  const dl = driverLockScript({ scriptsDir: scriptsDir || resolveScriptsDir(HERE), labRoot: root, home });
  const common = gitCommonDir(root) || '';
  if (dl.etat === 'absent') sources.locks = { etat: 'absente' };
  else {
    const DL = dl.chemin; let st = {};
    if (verrous && typeof verrous === 'object' && !verrous.error && verrous.available !== false) st = verrous; // lu une fois par le direct : jamais relu ici
    else if (verrous && verrous.error) sources.locks = { etat: 'erreur' };
    else try { st = JSON.parse(sh('bash', [DL, 'status', '--all'], root, root)); } catch { sources.locks = { etat: 'erreur' }; }
    st = { ...st, locks: Array.isArray(st?.locks) ? st.locks : st?.present ? [st] : [] }; // lab plat : `status --all` rend l'objet d'UN verrou, sans `locks`
    // ws et phase partent en argument d'un script : grammaire EXACTE de driver-lock.sh, sinon la cible est écartée (champs libres masqués et bornés par collectWho).
    // ws = vf_ws_name_valid (alphanumérique en tête, puis alphanumérique . _ -, jamais `..`) ; phase = vf_dl_phase_valid (chiffres séparés par des points : 69, 41.1, 1.2.3)
    const WS_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/, PH_RE = /^[0-9]+(\.[0-9]+)*$/, ok = (ws, ph) => (ws === '' || WS_RE.test(ws) && !ws.includes('..')) && (ph === '' || PH_RE.test(ph));
    for (const l of (st.locks || []).filter((x) => x.present)) workers.push({ kind: 'lock', id: l.owner, task: l.step, tree: l.ws ? `compartiment ${l.ws}${l.phase && PH_RE.test(String(l.phase)) ? ` phase ${l.phase}` : ''}` : l.scope, ageS: l.age_seconds, stale: !!l.stale, children: l.children_running, source: 'driver-lock' });
    // cibles du registre : dépôt, chaque compartiment, et chaque verrou de PHASE présent (registre frère du verrou de phase)
    const cibles = [{ ws: '', ph: '' }, ...ls(path.join(common, 'vf-driver', 'ws')).map((w) => ({ ws: w, ph: '' })), ...(st.locks || []).filter((x) => x.present && x.phase && typeof x.ws === 'string').map((x) => ({ ws: x.ws, ph: String(x.phase) }))].filter((c) => ok(c.ws, c.ph));
    let reg = 0;
    for (const { ws, ph } of cibles) {
      let o = {}; try { o = JSON.parse(sh('bash', [DL, 'orphans', ...(ws ? [`--ws=${ws}`] : []), ...(ph ? [`--phase=${ph}`] : [])], root, root)); } catch {}
      const held = (st.locks || []).some((l) => l.present && !l.stale && (l.ws || '') === ws && String(l.phase || '') === ph);
      for (const a of Array.isArray(o.orphans) ? o.orphans : []) { if (typeof a?.agent_id !== 'string' || !ID_RE.test(a.agent_id)) continue; reg++; if (presents.has(a.agent_id)) { registre.set(a.agent_id, { noeud: a.node || '', role: a.role, ws }); continue; } workers.push({ kind: 'registered', id: a.agent_id, role: a.role, task: a.node || '', parent: a.parent || '', depth: a.depth ?? null, tree: ws ? `compartiment ${ws}${ph ? ` phase ${ph}` : ''}` : 'dépôt', ageS: a.age_seconds, stale: !held, orphan: !held, source: 'registre' }); }
    }
    // D5 : un agent clos, verrou relâché, reste rattaché à son nœud (registre courant et archive de 24 h)
    if (presents.size) fusionnerRegistre(registre, presents, lireRegistre({ chemin: DL, racine: root }));
    sources.locks ||= { etat: 'lue', held: (st.locks || []).filter((x) => x.present).length, registered: reg };
  }

  // rattachement des sous-agents aux nœuds de mission (P69-D-15) : une seule découverte de DAG (lireDags), partagée avec le source 4
  let dags = [];
  try { dags = lireConfine(root, () => lireDags(root, planningLayout(root))); } catch {} // AUDC-A-02 : un DAG lié hors du lab n'est pas lu
  const trDe = new Map(workers.filter((w) => w.kind === 'subagent' && w._tr).map((w) => [w.id, w._tr]));
  rattacher(workers, { index: indexDesNoeuds(dags), registre, mandatDe: (id) => { const c = trDe.has(id) ? premiereLigne(trDe.get(id))?.message?.content : ''; return typeof c === 'string' ? c : ''; } });

  // 4 — DAG : nœuds running, dans les DAG du lab (lireDags : .planning, compartiments, missions, phases) et dans le dossier commun des verrous
  const fichiers = dags.map((g) => { const fp = path.join(root, g.file); return { d: path.dirname(fp), f: path.basename(fp), nodes: g.nodes }; });
  for (const d of [...ls(path.join(common, 'vf-driver', 'ws')).map((w) => path.join(common, 'vf-driver', 'ws', w)), path.join(common, 'vf-driver', 'repo')])
    for (const f of ls(d).filter((x) => x.endsWith('.dag.json'))) { const j = readJson(path.join(d, f)); if (j) fichiers.push({ d, f, nodes: Array.isArray(j.nodes) ? j.nodes : [] }); }
  let nDags = 0, running = 0, staleNodes = 0;
  for (const { d, f, nodes: brut } of fichiers) {
    nDags++;
    const nodes = (Array.isArray(brut) ? brut : []).filter((x) => x && typeof x === 'object' && !Array.isArray(x)); // F-9 : un nœud nul ou scalaire est ignoré, le DAG reste lu
    const fp = path.join(d, f);
    let age = Math.round((now - mtime(fp)) / 1000);
    if (age <= ttl && nodes.some((x) => x.status === 'running')) {
      const tracked = sh('git', [...GIT_SUR, '-C', d, 'ls-files', '--error-unmatch', '--', f], d, root).trim(), dirty = sh('git', [...GIT_SUR, '-C', d, 'status', '--porcelain', '--', f], d, root).trim();
      const ct = Number(sh('git', [...GIT_SUR, '-C', d, 'log', '-1', '--format=%ct', '--', f], d, root).trim());
      if (tracked && !dirty && ct) age = Math.round(now / 1000 - ct); // contenu identique au commit : écrit au plus tard à cette date
    }
    const stale = age > ttl;
    for (const n of nodes.filter((x) => x.status === 'running')) { running++; if (stale) staleNodes++; workers.push({ kind: 'dag-node', id: n.id, role: n.stage || '', task: String(n.step || ''), tree: path.relative(root, d) || d, dag: f, ageS: age, stale, source: 'dag' }); }
  }
  sources.dags = { etat: 'lue', files: nDags, running, stale: staleNodes };
  return { at: new Date(now).toISOString(), root, trees: trees.map(label), fresh, fenetre: FENETRE, workers, sources, sortisSilence: eq.sortisSilence, _registre: registre };
}

export function collectWho(root, opts = {}) {
  const g = gather(root, opts);
  // tout champ libre vient d'un fichier que d'autres écrivent : chaîne masquée et bornée, sinon absent (F2) ; les nombres sont finis ou absents ; un identifiant hors forme exclut le travailleur
  const bornes = (v, n) => masque(v).slice(0, n);
  const LIBRES = { titre: 80, task: 160, cwd: 200, role: 80, branch: 200, tree: 200, lastAt: 40, parent: 128, dag: 200, treeBy: 20 }, NOMBRES = ['ageS', 'depth', 'dureeS', 'children'];
  const IDS = new Set(['session', 'subagent', 'registered']);
  const workers = g.workers.filter((w) => typeof w.id === 'string' && (!IDS.has(w.kind) || ID_RE.test(w.id))).map(({ _tr, ...w }) => {
    w.id = bornes(w.id, 128);
    for (const [k, n] of Object.entries(LIBRES)) if (k in w) { if (typeof w[k] === 'string') w[k] = bornes(w[k], k === 'task' && w.kind === 'dag-node' ? 100 : n); else delete w[k]; }
    for (const k of NOMBRES) if (k in w && !(Number.isFinite(w[k]) || (k === 'depth' && w[k] === null))) delete w[k];
    const sous = (o, bornesDe) => { const r = {}; for (const [k, n] of Object.entries(bornesDe)) if (typeof o?.[k] === 'string') r[k] = bornes(o[k], n); return r; }; // objets imbriqués : mêmes règles
    if (w.rattachement) w.rattachement = sous(w.rattachement, { etat: 20, source: 20, raison: 20, dag: 200, noeud: 128 });
    if (w.action) w.action = sous(w.action, { verbe: 80, cible: 120 });
    return w;
  });
  const sources = { ...g.sources };
  if (typeof sources.sessions?.path === 'string') sources.sessions = { ...sources.sessions, path: sources.sessions.path.replace(opts.home || os.homedir(), '~') };
  return { schema: 'vibeflow/cockpit-who@2', at: g.at, root: g.root, trees: g.trees.map((t) => bornes(t, 200)), fresh: g.fresh, fenetre: g.fenetre, busy: workers.some((w) => !w.stale && w.etat !== 'termine' && w.etat !== 'au-repos' && w.etat !== 'attend'), workers, sources, sortisSilence: Number.isInteger(g.sortisSilence) ? g.sortisSilence : 0 };
}

// P67-D-14 : la dernière commande ne sort que par cette révélation ponctuelle (T-67-05), réduite au programme et à son premier argument (décision de Samuel, AskUserQuestion session principale, 2026-11-02).
const BORNE_COMMANDE = 80;
// réduit une commande au programme et à son premier argument (« git push … ») ; limite acceptée : un secret passé en premier argument positionnel (`ls Secret99`) reste visible.
// Liste blanche, aucune lecture des guillemets : un mot est « simple » s'il ne contient que des lettres ASCII, des chiffres et `_ . / : @ % + , ~ -` (donc jamais de guillemet, `$`, backtick, `\`,
// parenthèse, `;`, `|`, `&`, `<`, `>`, `*`, `?`, `[`, `]`, `{`, `}`, `!`, `#`, `=`). Les affectations de tête ne sont sautées que si le mot entier vaut `NOM=<mot simple ou vide>` ; tout autre mot de tête
// (valeur citée, `$(…)`, tableau, espace échappé) arrête la lecture et le programme, non simple, donne « … ». Le programme n'est affiché que s'il est simple et ne commence pas par « - » ;
// un retour à la ligne compte comme `;` (non simple) ; le premier argument que s'il est simple, ne commence pas par « - » et ne contient pas « = » (`DB_PASS=…` en est exclu par la liste blanche). « … » s'il reste des mots non affichés.
const SIMPLE = /^[A-Za-z0-9_.\/:@%+,~-]+$/;
const AFFECTATION = /^[A-Za-z_][A-Za-z0-9_]*=[A-Za-z0-9_.\/:@%+,~-]*$/;
const resume = (cmd) => {
  // le shell ne sépare les mots que sur espace, tabulation et retour à la ligne : `\r`, `\f`, `\v` restent DANS le mot (non simple, donc « … »). Un retour à la ligne (`\r\n` compris, `\s` couvre `\r`) est un séparateur de commandes : il devient un mot non simple (comme `;`), jamais un simple espace, sinon le mot de la ligne suivante serait pris pour un argument
  let mots = cmd.trim().replace(/\s*\n\s*/g, ' \n ').split(/[ \t]+/).filter(Boolean); let i = 0;
  // `cd <chemin> && …` / `cd <chemin>; …` (recette 3, O1) : forme la plus fréquente. Un cd SIMPLE (un seul mot simple, sans « - » initial, suivi de `&&` ou `;` comme mot séparé, ou collé à la fin du chemin : `cd x;`, `cd x&&`)
  // s'efface, la règle ci-dessous s'applique UNE fois à la commande qui suit ; pas de récursion (un second `cd` rend « … »). Le chemin du cd n'est jamais affiché, et tout `cd` qui n'est pas de cette forme (`||`, chemin cité, option, rien après) rend « … ».
  if (mots[0] === 'cd') {
    let chemin = mots[1], reste = null; const coll = chemin !== undefined ? /^(.+?)(;|&&)$/.exec(chemin) : null;
    if (coll) { chemin = coll[1]; reste = mots.slice(2); } else if (mots[2] === '&&' || mots[2] === ';') reste = mots.slice(3);
    if (reste === null || !SIMPLE.test(chemin) || chemin.startsWith('-')) return '…';
    mots = reste;
  }
  while (i < mots.length && AFFECTATION.test(mots[i])) i++;
  const prog = mots[i]; if (prog === undefined || prog === 'cd' || !SIMPLE.test(prog) || prog.startsWith('-')) return '…';
  const arg = mots[i + 1]; const montre = arg !== undefined && SIMPLE.test(arg) && !arg.startsWith('-');
  return [prog, ...(montre ? [arg] : []), ...(mots.length > i + (montre ? 2 : 1) ? ['…'] : [])].join(' ');
};
// D3 (recette 2026-11-02) : « la dernière commande » est la dernière commande de l'outil Bash (tool_use name=Bash, input.command) de la session.
// Un message texte de l'assistant n'est jamais rendu, même en repli : sans appel Bash lisible, `lastDoing` rend null (erreur « sans-action »).
// forme affichée d'une commande : réduction, masque PUIS borne (exportée pour la preuve générative, qui ne peut pas passer par une session disque par commande)
export const commandeAffichee = (cmd) => masque(resume(String(cmd).slice(0, MAX_MASQUE))).slice(0, BORNE_COMMANDE);
const lastCommand = (d) => {
  const c = d?.message?.content; if (!Array.isArray(c)) return '';
  for (const x of [...c].reverse()) if (x?.type === 'tool_use' && x.name === 'Bash' && typeof x.input?.command === 'string' && x.input.command.trim()) return commandeAffichee(x.input.command);
  return '';
};
// E-5 : la dernière ligne d'une session active est presque toujours un résultat d'outil (message user sans texte) ou une réflexion : on remonte
// jusqu'au dernier appel Bash de l'assistant.
const lastDoing = (f) => cherche(f, (d) => (d.type === 'assistant' ? lastCommand(d) : null));

// identifiant au format strict ET présent dans une collecte fraîche : aucun chemin construit depuis l'entrée (T-67-07)
export function revealDoing(root, id, opts = {}) {
  if (typeof id !== 'string' || !ID_RE.test(id)) return { schema: 'vibeflow/cockpit-doing@1', id: String(id), doing: null, erreur: 'id-invalide' };
  const w = gather(root, opts).workers.find((x) => (x.kind === 'session' || x.kind === 'subagent') && x.id === id && x._tr);
  if (!w) return { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'inconnu' };
  const doing = lastDoing(w._tr);
  return doing ? { schema: 'vibeflow/cockpit-doing@1', id, doing } : { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'sans-action' };
}

// P69-D-19 : le transcript d'un agent connu, réduit à son mandat (agent) et à son fil daté de messages et d'outils (liste blanche, vf-cockpit-transcript.mjs) ; le chemin vient de la collecte, jamais de l'entrée (T-69-02)
export function revealTranscript(root, id, opts = {}) {
  const S = 'vibeflow/cockpit-transcript@2';
  if (typeof id !== 'string' || !ID_RE.test(id)) return { schema: S, id: String(id).slice(0, 128), erreur: 'id-invalide' };
  try { return reveler(root, id, opts, S); } catch { return { schema: S, id, erreur: 'inconnu' }; } // aucune exception ne remonte à l'appelant (F3)
}
function reveler(root, id, opts, S) {
  const connus = new Map(agentsConnus(root, opts).filter((x) => (x.kind === 'session' || x.kind === 'subagent') && x._tr).map((x) => [x.id, x]));
  const w = connus.get(id);
  return w ? { schema: S, id, ...reduireTranscript(w._tr, { root: path.resolve(root), roles: rolesDe([...connus.values()]), kind: w.kind }) } : { schema: S, id, erreur: 'inconnu' };
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const root = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : '.';
  const fresh = Number(process.argv[process.argv.indexOf('--fresh') + 1]) || 180;
  const r = collectWho(root, { fresh });
  if (process.argv.includes('--json')) { console.log(JSON.stringify(r, null, 1)); process.exit(0); }
  console.log(`${r.busy ? 'Au travail' : 'Personne au travail'} — ${r.workers.length} signal(aux) · arbres : ${r.trees.join(', ')}`);
  for (const w of r.workers) console.log(`  ${w.kind.padEnd(10)} ${String(w.role || '').padEnd(16)} ${String(w.tree).padEnd(34)} ${w.ageS != null ? String(w.ageS).padStart(8) + ' s' : '          '}${w.orphan ? ' ORPHELIN' : w.stale ? ' PÉRIMÉ' : ''}  ${w.task || ''}`.slice(0, 180));
  console.log('sources :', JSON.stringify(r.sources));
}
