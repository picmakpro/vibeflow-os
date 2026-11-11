#!/usr/bin/env bash
# test-cockpit-lancer-suivi.sh — registre des lancements, états de carte, ligne de détail de l'onglet Équipe
# (LANC-10 ; P72-D-06, P72-D-16, P72-D-18 ; plan 72-07). Modules purs joués par Node : ni navigateur ni port.
#   LS1 noter : forme refusée, contexte hostile, session déjà notée, borne de 200 entrées
#   LS2 une seule source de la récence (cibles), heure de P (jamais le champ `at` du message)
#   LS3 états : attendue / vue / terminee par l'identifiant de session SEUL, oubli à ATTENTE_MAX_MS et TTL_MS
#   LS4 sorties : clés exactes, aucune clé interdite, module sans import ni écriture, constantes
#   LE  carte Équipe : paramètre optionnel `lancees` ; sortie d'avant identique octet pour octet sans lui (copie figée, sha256)
#   M-… onze mutants, un par garde (marqueur `// garde:<nom>` du module visé)
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"
mkdir -p "$AUX/base"
PIDS=()

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# sha256 de la copie figée ci-dessous. Elle a été rafraîchie à la jointure du panel utilisateurs (2026-11-07) : c'était le module d'AVANT 72-07 (HEAD b93fb088, sha cd40e07b…) ;
# c'est maintenant le module courant SANS la fonction 72-07 (les trois lignes `garde:lancees`, `garde:ligne-valide`, `garde:ligne-insert` neutralisées), parce que PU-G-134/162/163/164/165 (titre, description, état, identifiant)
# ont changé la sortie de toute carte sans rapport avec les lancements. Rafraîchie une seconde fois le 2026-11-08 (lot B2, 3f972a6b, PU-G-163 : repli de description et résumé du groupe « Terminés »), même soustraction. Rafraîchie une troisième fois à la jointure du lot 0 de l'audit (2026-11-11, AUDC-D2/D4 : états « au repos » / « vous attend », orphelins), même soustraction. Constante figée : elle ne se met plus à jour qu'en refaisant cette même soustraction.
BASE_EQUIPE_CARTE_SHA256="7679d717cdd55992fb347b91d1f61ff6aab9fd3e8f6224cd58490a9cd7006433"

# --- copie figée de vf-cockpit-equipe-carte.mjs sans la fonction du plan 72-07 (octet pour octet ; elle importe vf-cockpit-lecture.mjs, copié à côté avant usage) ---
cat > "$AUX/base/vf-cockpit-equipe-carte.mjs" <<'BASE_EQUIPE_CARTE_FIGEE'
// vf-cockpit-equipe-carte — le graphe de l'onglet Équipe (69-05, P69-D-17), au format du viewer.
// Export : buildEquipeGraph(who, { nom, racine, logos, git, missions, lancees }) -> graphe vibeflow/cockpit-equipe@1 ; missionsEnCours(gp) -> libellés des missions actives (78-04).
// `lancees` (optionnel) : Map session -> { phase, ws, verbe } produite par le registre de vf-cockpit-lancer-suivi.mjs (72-07) ; elle ajoute
// la ligne « Lancée depuis la carte : … » sur la carte de SESSION concernée, valeurs revalidées. Absente ou invalide : sortie inchangée.
// Titre d'une carte de SESSION (PU-G-162, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : `w.titre`, le `custom-title` du transcript (nom donné avec /rename, lu, nettoyé,
// masqué et borné à 80 caractères par la collecte `who`), sinon « Session principale · <branche> ». L'`ai-title` (texte du modèle), le dernier prompt et le premier message ne sont jamais lus ;
// l'identifiant de session passe dans le détail. Amendement de la liste blanche P69-D-19/P69-D-23 pour ce seul champ.
// Module pur (aucun fichier lu, aucun transcript ouvert) ; schéma vibeflow/cockpit-equipe@1 : seuls les champs de la collecte `who`
// (le titre de session et le reste, déjà nettoyés, bornés et masqués par collectWho) entrent dans une carte ; la branche repasse par `retireAffichage`. Les sortes de carte (session, agent, terminés) n'ont
// ni pictogramme ni couleur : le viewer prend son repli. Aucun fichier (`files` vide), aucun lien.
import { retireAffichage, nettoieTitre } from './vf-cockpit-lecture.mjs';
const SORTES = new Set(['session', 'subagent']);
const clip = (s, n) => { const t = String(s ?? '').replace(/\s+/g, ' ').trim(); if (t.length <= n) return t; const c = t.charCodeAt(n - 2); return t.slice(0, c >= 0xd800 && c <= 0xdbff ? n - 2 : n - 1) + '…'; }; // jamais une moitié de paire de substitution
// PU-G-165 : un seul état par carte — « en attente » n'a pas de pastille (le pied le dit), il n'est jamais projeté sur « En cours » ; ui/71 (`st`) tient la même table
const ST = { actif: 'active', 'en-attente': undefined, 'au-repos': undefined, attend: undefined, termine: 'done', bloque: 'blocked' }; // « au repos » et « vous attend » (AUDC-D2) : un mot au pied, pas de pastille « En cours »
const GENERIQUE = 'lance une commande'; // l'action de presque tous : elle n'informe pas (même seuil que ui/71)
const ETAT = { actif: 'actif', 'en-attente': 'en attente', 'au-repos': 'au repos', attend: 'vous attend', termine: 'terminé' };

// 78-04 : libellés des missions en cours (nœuds `mission` d'état `active` du graphe Projet), au plus 10, sans contrôle ni préfixe « Mission »
export function missionsEnCours(gp) {
  const out = [];
  for (const n of Array.isArray(gp?.nodes) ? gp.nodes : []) {
    if (out.length >= 10) break;
    if (n && n.kind === 'mission' && n.st === 'active' && typeof n.label === 'string') {
      // S6 (revue 2026-11-06) : même classe que `nettoie` (A8) — tout caractère de catégorie Cf, pas la seule plage bidi ; parité testée sur les quatre copies (test-cockpit-git-commandes.sh, R4.1)
      const l = clip(n.label.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/gu, '').replace(/^Mission\s+/, ''), 120);
      if (l) out.push(l);
    }
  }
  return out;
}

export function buildEquipeGraph(who, { nom = 'Projet', racine, logos, git, missions, lancees } = {}) {
  const travailleurs = (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && SORTES.has(w.kind) && typeof w.id === 'string');
  const idCarte = (w) => (w.kind === 'session' ? 'se-' : 'ag-') + w.id;
  const parDe = new Map(travailleurs.map((w) => [w.id, w])); // pour remonter au-dessus d'un parent terminé (AUDC-D4)
  const parId = new Map(); // identifiant de travailleur -> carte (Map : jamais un objet indexé par une valeur lue sur disque, T-69-09)
  for (const w of travailleurs) if (!parId.has(w.id)) parId.set(w.id, idCarte(w));
  const compte = { actif: 0, enAttente: 0, auRepos: 0, attend: 0, termine: 0 };
  const nodes = [];
  const termines = new Map(); // carte parente -> nombre d'enfants terminés
  const base = { tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] } };

  for (const w of travailleurs) {
    if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else if (w.etat === 'au-repos') compte.auRepos++; else if (w.etat === 'attend') compte.attend++; else compte.actif++;
    const sous = w.kind === 'subagent';
    // un orphelin (vivant, parent terminé) se rattache au premier ancêtre non terminé : jamais sous le bloc « Terminés » (AUDC-D4)
    let pid = w.parent; for (let i = 0; sous && w.orphan === true && i < 8 && parDe.get(pid)?.etat === 'termine'; i++) pid = parDe.get(pid).parent;
    const parent = sous ? parId.get(pid) ?? null : null;
    const fini = w.etat === 'termine';
    if (fini && parent) termines.set(parent, (termines.get(parent) || 0) + 1);
    const branche = retireAffichage(w.branch); // S6 : la branche passe par la même classe d'affichage que le titre (contrôles, Cf, bidi)
    const lignes = [];
    if (w.role) lignes.push(`Rôle : ${w.role}`);
    lignes.push(`État : ${ETAT[w.etat] || 'actif'}`);
    if (sous && w.orphan === true) lignes.push('Orphelin : son parent est terminé, cet agent travaille encore.');
    if (!sous) lignes.push(`Identifiant : ${w.id.slice(0, 8)}`);
    const l = undefined; // copie figée : sans la ligne de lancement (72-07)
    const t = '';
    if (branche) lignes.push(`Branche : ${branche}`);
    if (w.tree) lignes.push(`Arbre : ${w.tree}`);
    if (w.rattachement?.etat === 'rattache') lignes.push(`Nœud de mission : ${w.rattachement.noeud} (${w.rattachement.dag})`);
    // PU-G-134/163/164 : la description d'une carte n'est plus vide — étiquette de lancement, tâche (à défaut la dernière action si elle informe), puis branche et arbre d'une session
    const a = w.action || {}, act = a.verbe && a.verbe !== GENERIQUE ? [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' ') : '';
    const arbre = !sous && w.tree ? (w.tree === 'arbre principal' ? w.tree : `arbre ${String(w.tree).replace(/^\.claude\/worktrees\//, '')}`) : '';
    const lieu = !sous ? [branche ? `Branche ${branche}` : '', arbre].filter(Boolean).join(' · ') : '';
    // PU-G-163 (recette du 2026-11-08) : un agent ou une session sans rien à dire ne montre plus « Pas encore de description » — le repli dit ce qui est connu (nature, état)
    const resume = [sous && w.orphan === true ? 'Orphelin' : '', t ? `Depuis Phase ${l.phase}` : '', w.task || act, lieu].filter(Boolean).join(' · ') || `${sous ? 'Agent sans tâche annoncée' : 'Session sans tâche annoncée'} · ${ETAT[w.etat] || 'actif'}`;
    nodes.push({ ...base, id: idCarte(w), parent: fini && parent ? `${parent}~termines` : parent, kind: sous ? 'agent' : 'session',
      label: sous ? clip([w.role, w.task].filter(Boolean).join(' · ') || 'Agent', 80) : clip(typeof w.titre === 'string' && w.titre.trim() ? w.titre : ['Session principale', nettoieTitre(branche)].filter(Boolean).join(' · '), 80),
      summary: clip(resume, 200), details: lignes.join('\n\n'), st: Object.hasOwn(ST, w.etat) ? ST[w.etat] : 'active', foot: '' });
  }
  for (const [carte, n] of termines) {
    nodes.push({ ...base, id: `${carte}~termines`, parent: carte, kind: 'terminés', label: `Terminés depuis moins de 24 h (${n})`, summary: `${n} agent${n > 1 ? 's' : ''} de cette session, terminé${n > 1 ? 's' : ''} depuis moins de 24 h.`, details: '', st: 'done', foot: '' });
  }
  const etatSource = (s) => ({ etat: s?.etat === 'lue' || s?.etat === 'absente' || s?.etat === 'erreur' || s?.etat === 'forme-inconnue' ? s.etat : 'absente' });
  const sources = {};
  for (const k of Object.keys(who?.sources || {})) sources[k] = etatSource(who.sources[k]);
  return {
    schema: 'vibeflow/cockpit-equipe@1',
    meta: { generatedAt: new Date().toISOString(), rootName: nom, root: racine, vfLogos: logos, audience: 'everyone', agent: 'claude', repos: [], counts: { files: 0, loc: 0 }, vfTab: 'equipe',
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { compte, fenetre: who?.fenetre ?? null, sources, missions: Array.isArray(missions) ? missions : [] }, ...(git ? { vfGit: git } : {}) },
    project: { name: `${nom} — Équipe`, summary: `${compte.actif} actifs · ${compte.enAttente} en attente${compte.attend ? ` · ${compte.attend} vous attendent` : ''}${compte.auRepos ? ` · ${compte.auRepos} au repos` : ''} · ${compte.termine} terminés depuis moins de 24 h.` },
    nodes, files: [], links: [], flows: [], routes: [], tour: [],
  };
}
BASE_EQUIPE_CARTE_FIGEE
cp "$SCRIPTS/vf-cockpit-lecture.mjs" "$AUX/base/vf-cockpit-lecture.mjs" # dépendance partagée (retireAffichage, nettoieTitre) : la même des deux côtés de la comparaison A/B

# --- harnais du suivi : ls.mjs <module> <scénario> [<equipe.mjs>] — une ligne de sortie, « ABSENT » si l'import échoue ---
cat > "$AUX/ls.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , modPath, sc, extra] = process.argv;
let m;
try { m = await import(pathToFileURL(modPath).href); } catch { console.log('ABSENT'); process.exit(0); }
let t = 1_000_000;
const maintenant = () => t;
const A = '11111111-1111-4111-8111-111111111111', B = '22222222-2222-4222-8222-222222222222';
const C = 'ph-72@alpha';
const msg = (session, o = {}) => ({ t: 'lancee', cible: C, verbe: 'planifier', session, at: 1, ...o });
const sess = (id, etat, o = {}) => ({ kind: 'session', id, etat, tree: 't', source: 'transcript', ...o });
const wh = (...w) => ({ workers: w, sources: {} });
const ctx = { phase: '72', ws: 'alpha' };
const S = () => m.creerSuivi({ maintenant });
const et = (s, who) => s.etats(who).get(C)?.etat ?? 'aucun';
const INTERDITS = ['doing', 'mandat', 'messages', 'outils'];
const interdit = (o) => {
  if (!o || typeof o !== 'object') return false;
  if (o instanceof Map) { for (const [k, v] of o) if (INTERDITS.includes(k) || interdit(v)) return true; return false; }
  for (const [k, v] of Object.entries(o)) if (INTERDITS.includes(k) || interdit(v)) return true;
  return false;
};
const ks = (o) => Object.keys(o).sort().join(',');
const u = (i) => 'aaaaaaaa-aaaa-4aaa-8aaa-' + String(i).padStart(12, '0');
const SC = {
  ls11: () => { const s = S(); const r = s.noter(msg(A), ctx); return `${JSON.stringify(r)}|${s.taille()}`; },
  ls12: () => {
    const s = S();
    const mauvais = [msg(A, { cible: '72;touch M' }), msg(A, { cible: 'ph 72' }), msg(A, { verbe: 'exe cuter' }), msg(A, { verbe: 'inconnu' }),
      msg(A, { session: 'pas-un-uuid' }), msg(A, { session: '11111111-1111-1111-8111-111111111111' }), null, 'x'];
    return mauvais.map((x) => { const r = s.noter(x, ctx); return r.ok ? 'accepte' : r.motif; }).join(',') + '|' + s.taille();
  },
  ls12b: () => { const s = S(); const r = s.noter(msg(A), { phase: '$(id)', ws: 'A$B' }); return JSON.stringify([r.ok, s.lancees().get(A)]); },
  ls13: () => {
    const s = S(); s.noter(msg(A), ctx); const t0 = t; t += 1000;
    const r = s.noter(msg(A, { verbe: 'executer' }), ctx);
    return `${JSON.stringify(r)}|${s.taille()}|${s.lancements()[0].at === t0}|${s.lancements()[0].verbe}`;
  },
  ls14: () => {
    const s = S();
    for (let i = 0; i < 205; i++) { s.noter(msg(u(i)), ctx); t += 1; }
    const l = s.lancees();
    return s.taille() + '|' + [0, 4, 5, 204].map((i) => l.has(u(i))).join(',');
  },
  ls21: () => [typeof m.RECENCE_MS, typeof S().recent, Object.keys(S()).join(',')].join('|'), // la fenêtre de récence n'a qu'une source (cibles) : ce module ne l'exporte ni ne la juge

  ls22: () => {
    const s = S(); s.noter(msg(A, { at: 5 }), ctx); s.noter(msg(B, { at: 0, cible: 'ph-72@beta' }), ctx);
    return s.lancements().map((x) => x.at === t).join('/');
  },
  ls31: () => { const s = S(); s.noter(msg(A), ctx); return [wh(), null, {}, { workers: 'x' }, undefined].map((w) => et(s, w)).join(','); },
  ls32: () => { const s = S(); s.noter(msg(A), ctx); return et(s, wh(sess(A, 'actif'))) + ',' + et(s, wh(sess(A, 'en-attente'))); },
  ls33: () => { const s = S(); s.noter(msg(A), ctx); return et(s, wh(sess(A, 'termine'))); },
  ls34: () => {
    const s = S(); s.noter(msg(A), ctx);
    const imposteur = sess(B, 'actif', { task: 'vf-phase-72-alpha', role: 'vf-phase-72-alpha', tree: 'vf-phase-72-alpha' });
    const a = et(s, wh(imposteur));
    const b = et(s, wh({ kind: 'subagent', id: A, parent: B, etat: 'actif', task: 'x' }));
    t += 1000; s.noter(msg(B), ctx);
    const c = et(s, wh(sess(A, 'actif')));
    const d = et(s, wh(sess(A, 'actif'), sess(B, 'actif')));
    return [a, b, c, d].join(',');
  },
  ls35: () => {
    const s = S(); s.noter(msg(A), ctx); t += m.ATTENTE_MAX_MS;
    const r = [s.etats(wh()).size, s.lancements().length, s.lancees().size];
    const s2 = S(); s2.noter(msg(B), ctx);
    const v1 = et(s2, wh(sess(B, 'actif'))); t += 1000; const v2 = et(s2, wh()); const v3 = et(s2, wh(sess(B, 'actif')));
    return r.join(',') + '|' + [v1, v2, v3].join(',');
  },
  ls36: () => {
    const s = S(); s.noter(msg(A), ctx); s.etats(wh(sess(A, 'actif'))); const t0 = t;
    t = t0 + m.TTL_MS - 1; const a = s.taille(); t = t0 + m.TTL_MS; const b = s.taille();
    return a + ',' + b + ',' + s.etats(wh(sess(A, 'actif'))).size;
  },
  ls37: async () => { const eq = await import(pathToFileURL(extra).href); return `${m.TTL_MS}|${eq.FENETRE * 1000}|${m.TTL_MS === eq.FENETRE * 1000}`; },
  ls41: () => {
    const s = S(); s.noter(msg(A), ctx); t += 10; s.noter(msg(B, { cible: 'ph-72@beta', verbe: 'executer' }), ctx);
    const e = s.etats(wh(sess(A, 'actif'))); const l = s.lancees(); const ln = s.lancements();
    return [[...e.values()].map(ks).join('/'), l instanceof Map, [...l.values()].map(ks).join('/'), ln.map(ks).join('/'), ln.length,
      ln.map((x) => x.at).join('/') === (t - 10) + '/' + t].join('|');
  },
  ls42: () => {
    const s = S(); const r0 = s.noter({ ...msg(A), doing: 'x', mandat: 'y', messages: [1], outils: ['z'] }, ctx);
    const rendus = [r0, [...s.etats(wh(sess(A, 'actif'))).entries()], s.etats(wh(sess(A, 'actif'))), s.lancees(), s.lancements()];
    const temoin = [interdit({ a: { b: [{ doing: 1 }] } }), interdit(new Map([['x', { mandat: 1 }]])), interdit(new Map([['outils', 1]]))];
    return rendus.map(interdit).join(',') + '|' + temoin.join(',');
  },
  ls44: () => [m.ATTENTE_MAX_MS, m.TTL_MS, m.MAX_ENTREES, Object.keys(m.LIBELLES_VERBES).join(','),
    Object.values(m.LIBELLES_VERBES).join(','), Object.isFrozen(m.LIBELLES_VERBES)].join('|'),
};
const r = await SC[sc]();
console.log(typeof r === 'string' ? r : JSON.stringify(r));
JS
cat > "$AUX/statique.mjs" <<'JS'
// statique.mjs <module.mjs> : le module n'importe rien, n'écrit rien, ne journalise rien (LS4.3)
import fs from 'node:fs';
const f = process.argv[2];
if (!fs.existsSync(f)) { console.log('ABSENT'); process.exit(0); }
const src = fs.readFileSync(f, 'utf8');
console.log(JSON.stringify({
  imports: /(^|\n)\s*import[\s({]/.test(src) || /\bimport\s*\(/.test(src) || /\bfrom\s*['"]/.test(src) || /\brequire\s*\(/.test(src),
  console: /console\./.test(src), env: /process\.env/.test(src),
  fs: /\bfs\b|node:fs|writeFile|appendFile|createWriteStream/.test(src), live: /vf-cockpit-live|vf-cockpit-server/.test(src),
}));
JS

# --- harnais de la carte : carte.mjs <dossier-neuf> <dossier-copie-figée> <scénario> ---
cat > "$AUX/carte.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , dNew, dBase, sc] = process.argv;
const imp = (d) => import(pathToFileURL(path.join(d, 'vf-cockpit-equipe-carte.mjs')).href);
const N = (await imp(dNew)).buildEquipeGraph, Bz = (await imp(dBase)).buildEquipeGraph;
const OPT = { nom: 'Lab', racine: '/x', logos: {} };
const norm = (g) => { const c = JSON.parse(JSON.stringify(g)); c.meta.generatedAt = 'X'; return c; };
// Phase 78 : buildEquipeGraph émet désormais meta.vf.missions = [] même sans option (vfGit reste absent sans option). La copie figée d'avant 72-07
// ne connaît pas ce champ : on le réconcilie côté BASE seulement, en dernier dans meta.vf (même ordre que le module), et rien d'autre.
const normBase = (g) => { const c = norm(g); if (!('missions' in c.meta.vf)) c.meta.vf.missions = []; return c; };
const U = (n) => `${String(n).repeat(8)}-${String(n).repeat(4)}-4${String(n).repeat(3)}-8${String(n).repeat(3)}-${String(n).repeat(12)}`;
const S1 = U(1), S2 = U(2), S3 = U(3);
const sess = (id, o = {}) => ({ kind: 'session', id, etat: 'actif', tree: 'arbre', source: 'transcript', ...o });
const ag = (id, o = {}) => ({ kind: 'subagent', id, parent: S1, etat: 'actif', role: 'worker', task: 'faire', source: 'transcript', ...o });
const V = (phase, ws, verbe) => ({ phase, ws, verbe });
const JEUX = {
  complete: { workers: [sess(S1, { role: 'manager', branch: 'feat/x', tree: 'wt', task: 't', rattachement: { etat: 'rattache', noeud: 'n1', dag: 'd.json' } }), sess(S2, { etat: 'en-attente' })], fenetre: 86400, sources: { sessions: { etat: 'lue' } } },
  agents: { workers: [sess(S1), ag('a1'), ag('a2', { etat: 'termine' }), ag('a3', { etat: 'termine', parent: 'inconnu' }), ag('a4', { etat: 'en-attente' })], sources: {} },
  nonrattache: { workers: [sess(S1, { rattachement: { etat: 'inconnu' } }), sess(S3, { etat: 'termine', rattachement: { etat: 'rattache', noeud: 'n2', dag: 'd2.json' } })], sources: {} },
  vide: { workers: [], sources: {} },
  nul: null,
  sources: { workers: [sess(S1)], fenetre: 86400, sources: { sessions: { etat: 'lue' }, locks: { etat: 'erreur' }, dags: { etat: 'forme-inconnue' }, x: { etat: 'autre' } } },
  nonTableau: { workers: 'x' },
};
const VARS = [['absent', OPT], ['undefined', { ...OPT, lancees: undefined }], ['map-vide', { ...OPT, lancees: new Map() }],
  ['map-sans', { ...OPT, lancees: new Map([['zzz', V('72', 'alpha', 'planifier')]]) }], ['objet', { ...OPT, lancees: {} }], ['tableau', { ...OPT, lancees: [] }],
  ['chaine', { ...OPT, lancees: 'x' }], ['null', { ...OPT, lancees: null }], ['nombre', { ...OPT, lancees: 42 }]];
const noeud = (g, id) => g.nodes.find((n) => n.id === id);
const essai = (who, lancees, id, L) => { // la ligne L juste après « État : », aucun autre champ du graphe ne change
  const base = normBase(Bz(who, OPT)); const g = norm(N(who, { ...OPT, lancees }));
  const nb = noeud(base, id), ng = noeud(g, id); const lg = nb.details.split('\n\n'); let i = lg.findIndex((l) => l.startsWith('État : ')); if (lg[i + 1] && lg[i + 1].startsWith('Identifiant : ')) i++; // PU-G-162 : la ligne « Identifiant : » (sessions) suit « État : », la ligne de lancement vient juste après
  const attendu = [...lg.slice(0, i + 1), L, ...lg.slice(i + 1)].join('\n\n');
  // depuis c7d96740 (PU-G-134/163), la description d'une carte de session lancée s'ouvre sur « Depuis Phase N » ; le reste de la description est celui de la copie figée
  const R = (/Phase (\d+)/.exec(L) || [])[1];
  const attenduResume = nb.summary ? `Depuis Phase ${R} · ${nb.summary}` : `Depuis Phase ${R}`;
  const reste = JSON.stringify({ ...g, nodes: g.nodes.map((n) => (n.id === id ? { ...n, details: nb.details, summary: nb.summary } : n)) }) === JSON.stringify(base);
  return `details:${ng.details === attendu ? 'ok' : 'ko'}|resume:${ng.summary === attenduResume ? 'ok' : 'ko'}|reste:${reste ? 'ok' : 'ko'}`;
};
const W2 = { workers: [sess(S1, { role: 'manager' }), sess(S2)], sources: {} };
const SC = {
  identique: () => {
    let n = 0; const diffs = [];
    for (const [jn, who] of Object.entries(JEUX)) {
      const base = JSON.stringify(normBase(Bz(who, OPT)));
      for (const [vn, o] of VARS) { n++; let got; try { got = JSON.stringify(norm(N(who, o))); } catch (e) { got = 'EXC ' + e.message; } if (got !== base) diffs.push(jn + '/' + vn); }
    }
    return n + '|' + diffs.length + (diffs.length ? '|' + diffs.slice(0, 5).join(',') : '');
  },
  ligne: () => essai(W2, new Map([[S1, V('72', 'alpha', 'planifier')]]), 'se-' + S1, 'Lancée depuis la carte : Phase 72 · alpha · Planifier'),
  'sans-ws': () => essai(W2, new Map([[S1, V('72', null, 'planifier')]]), 'se-' + S1, 'Lancée depuis la carte : Phase 72 · Planifier'),
  hostile: () => {
    const T = () => ({ toString() { throw new Error('piege'); } });
    const H = [V('$(touch M)', 'alpha', 'planifier'), V('72;x', 'alpha', 'planifier'), V('72', 'a$(id)', 'planifier'), V('72', 'Alpha', 'planifier'), V('72', 'alpha\nx', 'planifier'),
      V('72', 'alpha', '<img src=x onerror=1>'), V('72', 'alpha', 'executer '), V('72', 'alpha', T()), V(72, 'alpha', 'planifier'), V('72', 'alpha', 'constructor'),
      V(T(), 'alpha', 'planifier'), null, 'x', 42];
    const ids = H.map((_, i) => 'aaaaaaaa-aaaa-4aaa-8aaa-' + String(i).padStart(12, '0'));
    const who = { workers: [...ids.map((id) => sess(id)), sess(S2)], sources: {} };
    const map = new Map(ids.map((id, i) => [id, H[i]])); map.set(S2, V('72', 'alpha', 'verifier'));
    let exc = 0, g; try { g = norm(N(who, { ...OPT, lancees: map })); } catch { exc = 1; return `exc:1`; }
    const base = normBase(Bz(who, OPT)); const nb = noeud(base, 'se-' + S2), ng = noeud(g, 'se-' + S2);
    const reste = JSON.stringify({ ...g, nodes: g.nodes.map((n) => (n.id === ng.id ? { ...n, details: nb.details, summary: nb.summary } : n)) }) === JSON.stringify(base);
    const hostile = /\$\(|touch M|onerror|72;x|piege|constructor|alpha\\n/.test(JSON.stringify(g));
    return `exc:${exc}|reste:${reste ? 'ok' : 'ko'}|temoin:${ng.details.includes('Lancée depuis la carte : Phase 72 · alpha · Vérifier') ? 'ok' : 'ko'}|hostile:${hostile ? 'presente' : 'aucune'}`;
  },
  'hors-session': () => {
    const who = { workers: [sess(S1), sess(S2), ag('agent-1')], sources: {} };
    const map = new Map([['agent-1', V('72', 'alpha', 'executer')], ['absent-id', V('72', 'alpha', 'executer')], [S2, V('72', 'alpha', 'executer')]]);
    const base = normBase(Bz(who, OPT)), g = norm(N(who, { ...OPT, lancees: map }));
    const diff = g.nodes.filter((n) => JSON.stringify(n) !== JSON.stringify(noeud(base, n.id))).map((n) => n.id);
    return `diff:${diff.join(',')}|noeuds:${g.nodes.length === base.nodes.length}|ligne:${noeud(g, 'se-' + S2).details.includes('Lancée depuis la carte : Phase 72 · alpha · Exécuter') ? 'ok' : 'ko'}`;
  },
  noms: () => {
    const P = '<img src=x onerror=1>';
    const who = { workers: [sess(S1, { name: P, nom: P, title: P, customTitle: P })], sources: {} };
    const a = JSON.stringify(norm(N(who, { ...OPT, lancees: new Map([[S1, V('72', 'alpha', 'planifier')]]) })));
    const b = norm(N(who, OPT));
    return `absent:${/onerror|<img/.test(a + JSON.stringify(b)) ? 'non' : 'oui'}|label:${noeud(b, 'se-' + S1).label === 'Session principale' ? 'ok' : 'ko'}`;
  },
};
console.log(SC[sc]());
JS

# --- mutants : copie des deux modules dans $WORK/mut-<nom>/, sed ; code 1 si la cible manque ou reste inchangée ---
MUT_DIR=""
mutant() { # mutant <nom> <fichier> <expression-sed>
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"
  for f in vf-cockpit-lancer-suivi.mjs vf-cockpit-equipe-carte.mjs vf-cockpit-lecture.mjs; do [ -f "$SCRIPTS/$f" ] && cp "$SCRIPTS/$f" "$d/$f"; done
  MUT_DIR="$d"; f="$d/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
LSM() { node "$AUX/ls.mjs" "$SCRIPTS/vf-cockpit-lancer-suivi.mjs" "$@" 2>&1; }
mut_ls() { # mut_ls <nom> <expression-sed> <scénario> <valeur saine> <sonde>
  if mutant "$1" vf-cockpit-lancer-suivi.mjs "$2"; then
    local got v=vert; got="$(node "$AUX/ls.mjs" "$MUT_DIR/vf-cockpit-lancer-suivi.mjs" "$3" 2>&1)"
    if [ -n "$got" ] && [ "$got" != "ABSENT" ] && [ "$got" != "$4" ]; then v=rouge; fi
    assert_eq "$1 — le mutant rougit $5 : le relevé [${got:0:60}] n'est plus la valeur saine (témoin : le scénario s'exécute)" "$v" "rouge"
  else sans_effet "$1"; fi
}
mut_le() { # mut_le <nom> <expression-sed> <scénario> <valeur saine> <sonde>
  if mutant "$1" vf-cockpit-equipe-carte.mjs "$2"; then
    local got v=vert; got="$(node "$AUX/carte.mjs" "$MUT_DIR" "$AUX/base" "$3" 2>&1)"
    if [ -n "$got" ] && [ "$got" != "$4" ]; then v=rouge; fi
    assert_eq "$1 — le mutant rougit $5 : le relevé [${got:0:60}] n'est plus la valeur saine (témoin : le scénario s'exécute)" "$v" "rouge"
  else sans_effet "$1"; fi
}

SAIN_LS12="forme,forme,forme,forme,forme,forme,forme,forme|0"
SAIN_LS22="true/true"
SAIN_LS21="undefined|undefined|noter,lancements,etats,lancees,taille"
SAIN_LS14="200|false,false,true,true"
SAIN_LS34="attendue,attendue,attendue,vue"
SAIN_LS33="terminee"
SAIN_LS35="0,0,0|vue,terminee,vue"
SAIN_LS36="1,0,0"
SAIN_LE1="63|0"
SAIN_LE2="details:ok|resume:ok|reste:ok"
SAIN_LE4="exc:0|reste:ok|temoin:ok|hostile:aucune"
SAIN_LE5="diff:se-22222222-2222-4222-8222-222222222222|noeuds:true|ligne:ok"

echo "== LS1 noter =="
assert_eq "LS1.1 — un message valide : {ok:true}, une entrée" "$(LSM ls11)" '{"ok":true}|1'
assert_eq "LS1.2 — cible, verbe, session hors forme et message non objet : tous refusés « forme », rien n'entre" "$(LSM ls12)" "$SAIN_LS12"
assert_eq "LS1.2 — phase et compartiment hostiles du contexte : entrée acceptée, phase et ws nuls" "$(LSM ls12b)" '[true,{"phase":null,"ws":null,"verbe":"planifier"}]'
assert_eq "LS1.3 — même session deux fois : deja:true, une entrée, at d'origine conservé, verbe d'origine" "$(LSM ls13)" '{"ok":true,"deja":true}|1|true|planifier'
assert_eq "LS1.4 — 205 notes : 200 entrées, les cinq plus anciennes sont sorties" "$(LSM ls14)" "$SAIN_LS14"

echo "== LS2 récence =="
assert_eq "LS2.1 — une seule source de la fenêtre de récence : ce module n'exporte ni RECENCE_MS ni recent() ; seul vf-cockpit-lancer-cibles.mjs la définit parmi les modules lancer" "$(LSM ls21) $(for f in "$SCRIPTS"/vf-cockpit-lancer*.mjs; do grep -l '^export const RECENCE_MS' "$f" 2>/dev/null; done | xargs -n1 basename | tr '\n' ,)" "$SAIN_LS21 vf-cockpit-lancer-cibles.mjs,"
assert_eq "LS2.2 — un message portant at:5 ou at:0 : l'entrée a l'heure de P" "$(LSM ls22)" "$SAIN_LS22"

echo "== LS3 états =="
assert_eq "LS3.1 — attendue quand who ne contient pas la session, et who null, {}, workers non tableau, indéfini" "$(LSM ls31)" "attendue,attendue,attendue,attendue,attendue"
assert_eq "LS3.2 — session actif puis en-attente : vue" "$(LSM ls32)" "vue,vue"
assert_eq "LS3.3 — session termine : terminee" "$(LSM ls33)" "$SAIN_LS33"
assert_eq "LS3.4 — rattachement par identifiant seul : même nom en task, role, tree sous un autre id = attendue ; sous-agent de même id ignoré ; le plus récent décide" "$(LSM ls34)" "$SAIN_LS34"
assert_eq "LS3.5 — jamais vue après ATTENTE_MAX_MS : rien ; vue puis absente : terminee, non collante" "$(LSM ls35)" "$SAIN_LS35"
assert_eq "LS3.6 — TTL_MS : l'entrée vue sort à TTL_MS, pas à TTL_MS-1" "$(LSM ls36)" "$SAIN_LS36"
assert_eq "LS3.7 — TTL_MS = FENETRE × 1000 (FENETRE de vf-cockpit-equipe.mjs)" "$(LSM ls37 "$SCRIPTS/vf-cockpit-equipe.mjs")" "86400000|86400000|true"

echo "== LS4 sorties =="
assert_eq "LS4.1 — clés exactes : etats {etat,verbe}, lancees Map {phase,verbe,ws}, lancements {at,cible,verbe}, at = horloge de P" "$(LSM ls41)" "etat,verbe/etat,verbe|true|phase,verbe,ws/phase,verbe,ws|at,cible,verbe/at,cible,verbe|2|true"
assert_eq "LS4.2 — aucune clé doing, mandat, messages, outils dans ce que rendent noter, etats, lancees, lancements (témoin : le détecteur voit les clés plantées)" "$(LSM ls42)" "false,false,false,false,false|true,true,true"
assert_eq "LS4.3 — le module n'importe rien, n'écrit rien, ne journalise rien, ne lit pas l'environnement" "$(node "$AUX/statique.mjs" "$SCRIPTS/vf-cockpit-lancer-suivi.mjs")" '{"imports":false,"console":false,"env":false,"fs":false,"live":false}'
assert_eq "LS4.4 — constantes et libellés des cinq verbes" "$(LSM ls44)" "600000|86400000|200|cadrer,planifier,executer,verifier,reprendre|Cadrer,Planifier,Exécuter,Vérifier,Reprendre|true"

echo "== LE carte Équipe =="
assert_eq "LE.0 — la copie figée est figée : son sha256 est celui de la constante (module courant moins la fonction 72-07, rafraîchi le 2026-11-07)" "$(shasum -a 256 "$AUX/base/vf-cockpit-equipe-carte.mjs" | cut -d' ' -f1)" "$BASE_EQUIPE_CARTE_SHA256"
# LE.0b : la copie ne diffère du module courant QUE par l'import 72-07 et les trois lignes garde:lancees / garde:ligne-valide / garde:ligne-insert (neutralisées en `const l = undefined;` et `const t = '';`) ;
# sans cela un rafraîchissement silencieux de la copie rendrait la comparaison A/B tautologique (la copie suivrait le module, LE.1 à LE.5 ne verraient plus rien)
cat > "$AUX/copie.mjs" <<'JS'
import fs from 'node:fs';
const [, , courant, copie] = process.argv;
const att = fs.readFileSync(courant, 'utf8').split('\n').flatMap((l) => l.startsWith('import { LIBELLES_VERBES, entreeLanceeValide }') || l.includes('// garde:ligne-insert') ? [] : l.includes('// garde:lancees') ? ['    const l = undefined; // copie figée : sans la ligne de lancement (72-07)'] : l.includes('// garde:ligne-valide') ? ["    const t = '';"] : [l]);
const obt = fs.readFileSync(copie, 'utf8').split('\n');
const trim = (a) => { while (a.length && a[a.length - 1] === '') a.pop(); return a; };
const A = trim(att), O = trim(obt);
const i = A.findIndex((l, k) => l !== O[k]);
console.log(i < 0 && A.length === O.length ? 'identique' : 'écart ligne ' + ((i < 0 ? Math.min(A.length, O.length) : i) + 1) + ' : attendu [' + (A[i] ?? '').slice(0, 80) + '] obtenu [' + (O[i] ?? '').slice(0, 80) + ']');
JS
assert_eq "LE.0b — la copie figée ne diffère du module courant que par l'import 72-07 et les trois lignes garde:lancees / garde:ligne-valide / garde:ligne-insert" "$(node "$AUX/copie.mjs" "$SCRIPTS/vf-cockpit-equipe-carte.mjs" "$AUX/base/vf-cockpit-equipe-carte.mjs")" "identique"
sed '/^const ST = /s/done/fini/' "$AUX/base/vf-cockpit-equipe-carte.mjs" > "$AUX/base-mutee.mjs"
cmp -s "$AUX/base-mutee.mjs" "$AUX/base/vf-cockpit-equipe-carte.mjs" && assert_eq "LE.0c — mutant sans effet (cible de sed absente)" "sans effet" "effet"
assert_eq "LE.0c — mutant : une quatrième différence dans la copie (état « done » renommé) rougit LE.0b" "$(node "$AUX/copie.mjs" "$SCRIPTS/vf-cockpit-equipe-carte.mjs" "$AUX/base-mutee.mjs" | cut -c1-12)" "écart ligne "
assert_eq "LE.1 — sept jeux who × neuf valeurs de paramètre : sortie identique octet pour octet à la copie figée (generatedAt neutralisé)" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" identique 2>&1)" "$SAIN_LE1"
assert_eq "LE.2 — la ligne « Lancée depuis la carte : Phase 72 · alpha · Planifier » juste après « État : » (et de « Identifiant : » qui le suit sur une session, PU-G-162), la description s'ouvre sur « Depuis Phase 72 » (c7d96740), aucun autre champ ne change" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" ligne 2>&1)" "$SAIN_LE2"
assert_eq "LE.3 — sans compartiment : « Lancée depuis la carte : Phase 72 · Planifier »" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" sans-ws 2>&1)" "$SAIN_LE2"
assert_eq "LE.4 — valeurs hostiles : aucune ligne, aucune exception, rien d'hostile dans le JSON ; le témoin positif de la même Map donne sa ligne" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" hostile 2>&1)" "$SAIN_LE4"
assert_eq "LE.5 — un sous-agent clé de la Map et une clé absente de who : rien ; seule la session valide de la même Map change" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" hors-session 2>&1)" "$SAIN_LE5"
assert_eq "LE.6 — name, nom, title, customTitle hostiles : absents de la sortie, libellé « Session principale » (sans titre ni branche, PU-G-162)" "$(node "$AUX/carte.mjs" "$SCRIPTS" "$AUX/base" noms 2>&1)" "absent:oui|label:ok"

echo "== Mutants =="
mut_ls M-FORME-LIBRE '/garde:forme/d' ls12 "$SAIN_LS12" LS1.2
mut_ls M-AT-DU-MESSAGE '/garde:at-de-p/s#maintenant()#Number(msg.at) || maintenant()#' ls22 "$SAIN_LS22" LS2.2
mut_ls M-SANS-BORNE '/garde:max/d' ls14 "$SAIN_LS14" LS1.4
mut_ls M-RECENCE-RETABLIE 's#^export const MAX_ENTREES = 200;#export const MAX_ENTREES = 200; export const RECENCE_MS = 900000;#' ls21 "$SAIN_LS21" LS2.1
mut_ls M-ATTENTE-ILLIMITEE '/garde:attente-max/d' ls35 "$SAIN_LS35" LS3.5
mut_ls M-TTL-IGNORE '/garde:ttl/d' ls36 "$SAIN_LS36" LS3.6
mut_ls M-RATTACHE-PAR-NOM "/garde:session-id/s#w\\.id === e\\.session#(w.id === e.session || w.task === 'vf-phase-' + String(e.phase).replace('.', '-') + '-' + e.ws)#" ls34 "$SAIN_LS34" LS3.4
mut_ls M-TERMINEE-PERDUE "/garde:termine/s#w.etat === 'termine'#false#" ls33 "$SAIN_LS33" LS3.3
mut_le M-LANCEES-HORS-SESSION "/garde:lancees/s# && w\\.kind === 'session'##" hors-session "$SAIN_LE5" LE.5
mut_le M-LIGNE-SANS-VALIDATION '/garde:ligne-valide/s#l && entreeLanceeValide(l)#l#' hostile "$SAIN_LE4" LE.4
mut_le M-LIGNE-VIDE-TOUJOURS "/garde:ligne-insert/s#.*#      lignes.push(t || ''); // garde:ligne-insert#" identique "$SAIN_LE1" LE.1

vf_hyg_assert

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
