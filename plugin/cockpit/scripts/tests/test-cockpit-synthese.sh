#!/usr/bin/env bash
# test-cockpit-synthese.sh — « depuis votre dernière visite » : calcul pur, mémoire de visite, sommet de la base servi (77-04 ; SYNT-05, 06, 07 ; P77-D-07 à D-11, D-21, D-22)
#   SC calcul (sous vm) · SM mémoire (sous vm) · SG base.h de /api/vf/git (dépôt fabriqué) · SP pureté des deux fichiers · SV inventaire, plafonds, cliquet · M-* mutants (copie du module, A48)
# Les oracles (nombre de commits arrivés, condensats) sont écrits en dur : jamais recalculés par le module testé. Aucun serveur lancé. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$(cd "$SCRIPTS/.." && pwd)"
UI="$MODULE/skills/cockpit-moteur/assets/ui"
VEND="$MODULE/skills/cockpit-moteur/VENDORED.txt"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- le banc node : sc.mjs <dossier ui> [étiquettes…] rend « PASS|étiquette » ou « FAIL|étiquette|détail » ; les étiquettes filtrent par préfixe ---
cat > "$AUX/sc.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import vm from 'node:vm';
const [, , ui, ...filtre] = process.argv;
const rap = (l, ok, d) => { if (filtre.length && !filtre.some((f) => l.startsWith(f))) return; console.log((ok ? 'PASS|' : 'FAIL|') + l + (ok ? '' : '|' + String(d).replace(/\n/g, ' ').slice(0, 300))); };
const eq = (l, a, b) => { const x = JSON.stringify(a), y = JSON.stringify(b); rap(l, x === y, `attendu ${y} obtenu ${x}`); };
const ok = (l, c, d) => rap(l, !!c, d);
const essai = (l, f) => { try { f(); } catch (e) { rap(l, false, 'exception ' + e.message); } };
const charger = (fichier, ctx) => { const s = vm.createContext(ctx); vm.runInContext(fs.readFileSync(path.join(ui, fichier), 'utf8'), s); return { w: s.window, s }; };
const iso = (s) => new Date(s * 1000).toISOString();
const octets = (t) => Buffer.byteLength(t, 'utf8');
let C = null, M = null, MS = null;
const tri = (o) => Object.keys(o).sort();
essai('SC0 — chargement', () => {
  const a = charger('74-vf-synthese-calcul.js', { window: {}, document: {} }), b = charger('74-vf-synthese-calcul.js', { window: {} });
  C = a.w.__vfSyntheseCalcul;
  const exp = ['DEPUIS_ST', 'ETATS', 'FENETRE_S', 'blocagesPresents', 'commitsArrives', 'condensat', 'depuisGraphe', 'depuisSignal', 'difference', 'instantane', 'resume', 'sessionsFinies'].sort();
  eq('SC0 — le calcul se charge avec et sans document, exports exacts et gelés', [tri(C), tri(b.w.__vfSyntheseCalcul), Object.isFrozen(C)], [exp, exp, true]);
});
essai('SM0 — chargement', () => {
  const a = charger('74-vf-synthese-memoire.js', { window: {}, document: {} }), b = charger('74-vf-synthese-memoire.js', { window: {} });
  M = a.w.__vfSyntheseMemoire; MS = a.s;
  const exp = ['LAB_RE', 'PREFIXE', 'SEUIL_ROTATION_S', 'TAILLE_MAX', 'avecCourante', 'cle', 'ecrire', 'fusionner', 'lire', 'tourner', 'toutVu'].sort();
  eq('SM0 — la mémoire se charge avec et sans document, exports exacts et gelés', [tri(M), tri(b.w.__vfSyntheseMemoire), Object.isFrozen(M)], [exp, exp, true]);
});
const R = (h, p, at) => ({ h: String(h), p: p.map(String), at });
const inst = (vu, phases, tete = null, bl = []) => ({ vu, phases, tete, blocages: bl });
const val = (c, p) => ({ v: 1, precedente: p, courante: c });
const A40 = 'a'.repeat(40), B12 = 'b'.repeat(12);
// SC1 : phases avancées
essai('SC1', () => {
  const pre = C.instantane({ phases: { 'a|1': 'a-faire', 'a|2': 'en-cours' }, tete: null, blocages: [], vu: 1000 });
  const pres = C.instantane({ phases: { 'a|1': 'en-cours', 'a|2': 'en-cours', 'a|3': 'a-faire' }, tete: null, blocages: [], vu: 2000 });
  const d = C.difference(pre, pres, { rangees: [], sommet: null, gitLu: true, workers: [], maintenant: 2000 });
  eq('SC1 — phases : a|1 avancée, a|2 inchangée, a|3 apparue (de: null)', d.phases, [{ key: 'a|1', de: 'a-faire', vers: 'en-cours' }, { key: 'a|3', de: null, vers: 'a-faire' }]);
});
// SC2 : commits arrivés — base 1..10 (sommet 10), tete 5, B (101, 102 aux dates ANTÉRIEURES) fusionnée en 9, U (201, 202) jamais fusionnée
const rg = [];
for (let i = 1; i <= 10; i++) rg.push(R(i, i === 1 ? [] : i === 9 ? [8, 102] : [i - 1], 1000 + i * 10));
rg.push(R(101, [3], 1015), R(102, [101], 1016), R(201, [3], 1500), R(202, [201], 1510));
essai('SC2', () => {
  eq('SC2 — arrivés : 6..10 plus les deux commits de la branche fusionnée tard (7), jamais la branche longue non fusionnée', C.commitsArrives(rg, '5', '10'), { etat: 'ok', n: 7, plusDe500: false });
  eq('SC2 — la branche fusionnée tard est comptée même avec des dates anciennes (sommet 9 : 6, 7, 8, 9 et 101, 102 = 6)', C.commitsArrives(rg, '5', '9').n, 6);
});
essai('SC3', () => {
  eq('SC3 — tete absente des rangées : plus de 500', C.commitsArrives(rg, '999', '10'), { etat: 'ok', n: null, plusDe500: true });
  eq('SC3 — tete égale au sommet : 0', C.commitsArrives(rg, '10', '10'), { etat: 'ok', n: 0, plusDe500: false });
  eq('SC3 — tete nulle ou sommet absent : inconnu', [C.commitsArrives(rg, null, '10').etat, C.commitsArrives(rg, '5', null).etat, C.commitsArrives(rg, '5', '999').etat], ['inconnu', 'inconnu', 'inconnu']);
});
// SC4 : sessions finies
essai('SC4', () => {
  const w = [{ kind: 'session', id: 's1', etat: 'termine', lastAt: iso(1200) }, { kind: 'subagent', id: 'a1', etat: 'termine', finAt: iso(1300) },
    { kind: 'session', id: 's2', etat: 'termine', lastAt: iso(900) }, { kind: 'session', id: 's3', etat: 'actif', lastAt: iso(1400) }];
  eq('SC4 — une session et un sous-agent terminés après la visite (2), ni l\'ancien ni l\'actif, sans réserve', C.sessionsFinies(w, 1000, 1500), { n: 2, auMoins: false, reserve24h: false });
  eq('SC4 — visite de 25 h : « au moins » et réserve', C.sessionsFinies(w, 1000, 1000 + 90000), { n: 2, auMoins: true, reserve24h: true });
  eq('SC4 — visite de 25 h sans aucune session : 0 AVEC la réserve (jamais un 0 seul)', C.sessionsFinies([], 1000, 1000 + 90000), { n: 0, auMoins: true, reserve24h: true });
});
// SC5 : blocages
const F = (t) => { let h = 0xcbf29ce484222325n; for (let i = 0; i < t.length; i++) h = BigInt.asUintN(64, (h ^ BigInt(t.charCodeAt(i))) * 0x100000001b3n); return h.toString(16).padStart(16, '0').slice(0, 12); };
essai('SC5', () => {
  const kx = F('mission|MX'), ky = F('state|HY'), kz = F('mission|MZ');
  const pres = C.blocagesPresents({ missions: [{ nom: 'MZ', noeuds: [{ status: 'failed' }] }, { nom: 'MOK', noeuds: [{ status: 'done' }] }], workers: [], blocagesState: [{ h: 'HY', t: 'texte Y' }] });
  eq('SC5 — blocages présents : la mission échouée et l\'entrée du STATE, avec leurs clés', pres.map((b) => [b.cle, b.kind, b.texte]), [[kz, 'mission', 'MZ'], [ky, 'state', 'texte Y']]);
  const pre = C.instantane({ phases: {}, tete: null, blocages: [kx, ky], vu: 1000 }), now = C.instantane({ phases: {}, tete: null, blocages: pres.map((b) => b.cle), vu: 2000 });
  const d = C.difference(pre, now, { rangees: [], sommet: null, gitLu: true, workers: [], maintenant: 2000, blocages: pres });
  eq('SC5 — nouveau : z avec son texte présent ; un blocage levé est seulement compté (1)', [d.blocages.nouveaux, d.blocages.leves], [[{ cle: kz, kind: 'mission', texte: 'MZ' }], 1]);
  ok('SC5 — aucune clé ni texte d\'un blocage levé dans la sortie', !JSON.stringify(d).includes(kx) && !JSON.stringify(d).includes('MX'), JSON.stringify(d));
  const att = C.blocagesPresents({ missions: [], workers: [{ kind: 'session', id: 'se1', etat: 'attend' }, { kind: 'subagent', id: 'ag1', etat: 'attend', role: 'vf-coder' }, { kind: 'session', id: 'se2', etat: 'actif' }], blocagesState: [] });
  eq('SC5 — agents qui attendent : rôle, sinon « session » ou « sous-agent »', att.map((b) => b.texte), ['session', 'vf-coder']);
});
// SC6, SC7 : adaptateurs
const wk = [{ kind: 'session', id: 's1', etat: 'attend' }];
const ATT = { phases: [{ key: 'a|1', avancement: { etat: 'fait' } }, { key: 'a|2', avancement: { etat: 'a-recetter' } }, { key: 'a|3', avancement: { etat: 'en-cours' } }, { key: 'a|4', avancement: { etat: 'a-faire' } }, { key: '|6', avancement: { etat: 'fait' } }],
  missions: [{ nom: 'MISSION-X', noeuds: [{ status: 'failed' }] }, { nom: 'MISSION-Y', noeuds: [] }], equipe: { workers: wk } };
essai('SC6', () => {
  const g = { nodes: [{ kind: 'phase', ws: 'a', num: '1', st: 'done' }, { kind: 'phase', ws: 'a', num: '2', st: 'recette' }, { kind: 'phase', ws: 'a', num: '3', st: 'active' }, { kind: 'phase', ws: 'a', num: '4', st: 'todo' },
    { kind: 'phase', ws: 'a', num: '5', st: 'zzz' }, { kind: 'phase', ws: null, num: '6', st: 'done' }, { id: 'dag-MISSION-X', kind: 'mission', st: 'blocked' }, { id: 'dag-MISSION-Y', kind: 'mission', st: 'done' }, { id: 'f:x', kind: 'file' }] };
  eq('SC6 — graphe : quatre états, statut inconnu ignoré, mission bloquée = un nœud failed', C.depuisGraphe(g, { workers: wk }), ATT);
  eq('SC6 — sans graphe ni who : forme vide', C.depuisGraphe(null, null), { phases: [], missions: [], equipe: { workers: [] } });
});
essai('SC7', () => {
  const s = { phases: [...ATT.phases.map((p) => ({ ...p, n: 1, nom: 'x' })), { key: 'a|9', avancement: { etat: 'inconnu' } }], missions: [{ nom: 'MISSION-X', etat: 'running', noeuds: [{ id: 'n', status: 'failed' }] }, { nom: 'MISSION-Y', etat: 'done' }], equipe: { workers: wk } };
  eq('SC7 — depuisSignal rend la même forme que depuisGraphe pour des données équivalentes', C.depuisSignal(s), ATT);
});
essai('SC8', () => {
  eq('SC8 — condensat : trois littéraux FNV-1a 64 (douze premiers hex), unités UTF-16', [C.condensat('mission|MISSION-77'), C.condensat(''), C.condensat('é')], ['4008b1f50c4e', 'cbf29ce48422', 'af64644c8602']);
  eq('SC8 — hors plan multilingue de base : deux unités UTF-16', C.condensat('😀'), 'e5e45a0a241b');
});
essai('SC9', () => {
  const o = { rangees: rg, sommet: '10', gitLu: true, workers: [], maintenant: 1500 };
  const a = C.instantane({ phases: { 'a|1': 'fait' }, tete: '0'.repeat(40), blocages: [], vu: 1000 });
  eq('SC9 — première visite : premiere', C.difference(null, a, o), { premiere: true });
  const e = C.difference(a, a, { ...o, rangees: [R('x', [], 1)], sommet: 'x' }); // tete = 0…0 absente des rangées : plus de 500
  ok('SC9 — tete absente des rangées : « plus de 500 » n\'est pas vide', e.premiere === false && e.vide === false && e.commits.plusDe500 === true, JSON.stringify(e));
  const b = C.instantane({ phases: { 'a|1': 'fait' }, tete: null, blocages: [], vu: 1000 });
  const v = C.difference(b, b, { rangees: [], sommet: null, gitLu: true, workers: [], maintenant: 1500 });
  eq('SC9 — deux instantanés égaux : vide', [v.premiere, v.vide, v.phases], [false, true, []]);
  eq('SC9 — réserve des 24 h : pas vide', C.difference(b, b, { rangees: [], sommet: null, gitLu: true, workers: [], maintenant: 1000 + 90000 }).vide, false);
  eq('SC9 — commits non lus : pas vide, étiquette non-lus', (({ vide, commits }) => [vide, commits.etat])(C.difference(b, b, { rangees: [], sommet: null, gitLu: false, workers: [], maintenant: 1500 })), [false, 'non-lus']);
  eq('SC9 — résumé chiffré, sans texte', C.resume(C.difference(a, C.instantane({ phases: { 'a|1': 'fait', 'a|2': 'a-faire' }, tete: null, blocages: [], vu: 2000 }), { ...o, gitLu: false })), { phases: 1, commits: null, sessions: 0, nouveaux: 0, leves: 0 });
});
// SM1..SM8 : mémoire
const ph = (n) => { const o = {}; for (let i = 0; i < n; i++) o['|' + i] = 'fait'; return o; };
const require_inerte = () => vm.runInContext('Object.prototype.polluee === undefined', MS);
const bon = val(inst(1000, { 'a|1': 'fait', 'b|2.5': 'en-cours' }, A40, [B12]), inst(500, { 'a|1': 'a-faire' }, null, []));
essai('SM1', () => {
  eq('SM1 — clé par lab (littéral en dur)', M.cle('0123456789ab'), 'vibeflow-cockpit:derniere-visite:0123456789ab');
  eq('SM1 — aucun repli : lab vide, absent, majuscules, non hexadécimal, trop court ou long, retour à la ligne, non chaîne', ['', undefined, 'ABCDEF012345', 'zzzzzzzzzzzz', '0123456789a', '0123456789abc', '0123456789ab\n', 12].map((x) => M.cle(x)), Array(8).fill(null));
});
essai('SM2', () => {
  const t = JSON.stringify(bon), pad = (n) => ' '.repeat(n - octets(t)) + t;
  eq('SM2 — valeur valide : relue égale', JSON.stringify(M.lire(t)), t);
  eq('SM2 — non chaîne, texte corrompu, v: 2', [M.lire(undefined), M.lire(42), M.lire('{pas du json'), M.lire(t.replace('"v":1', '"v":2'))], [null, null, null, null]);
  eq('SM2 — clé en plus au premier niveau, dans un instantané, clé en moins', [M.lire(t.replace('{"v":1', '{"x":1,"v":1')), M.lire(t.replace('"vu":1000', '"vu":1000,"x":1')), M.lire(t.replace(',"tete":null', ''))], [null, null, null]);
  eq('SM2 — 8 192 octets valides : objet ; 8 193 : null', [M.lire(pad(8192)) !== null, M.lire(pad(8193))], [true, null]);
  const gros = {}; for (let i = 0; i < 70; i++) gros['é'.repeat(60) + String(i).padStart(4, '0') + '|1'] = 'fait';
  const tg = JSON.stringify(val(inst(1, gros), null));
  ok('SM2 — la borne compte des octets UTF-8, pas des caractères (moins de 8 192 caractères, plus d\'octets)', tg.length < 8192 && octets(tg) > 8192 && M.lire(tg) === null, tg.length + '/' + octets(tg));
  const pr = '{"v":1,"precedente":null,"courante":{"vu":5,"phases":{"__proto__":"fait"},"tete":null,"blocages":[]},"__proto__":{"polluee":1}}';
  ok('SM2 — __proto__ : refusé, aucune pollution (ni ici ni dans le contexte de la page)', M.lire(pr) === null && ({}).polluee === undefined && require_inerte(), '');
  const lp = JSON.stringify(val(inst(5, JSON.parse('{"__proto__":"fait"}')), null));
  ok('SM2 — une clé de phase __proto__ seule : refusée (forme de clé)', M.lire(lp) === null, lp);
  eq('SM2 — vu : 0, négatif, fractionnaire, chaîne', [0, -1, 1.5, '5'].map((x) => M.lire(JSON.stringify(val(inst(x, {}), null)))), [null, null, null, null]);
  eq('SM2 — clés de phase et états invalides', [{ 'a b|1': 'fait' }, { 'a|x': 'fait' }, { 'a|1.': 'fait' }, { 'a|1': 'zzz' }, { ['x'.repeat(65) + '|1']: 'fait' }].map((p) => M.lire(JSON.stringify(val(inst(5, p), null)))), Array(5).fill(null));
  eq('SM2 — 500 phases : objet ; 501 : null', [M.lire(JSON.stringify(val(inst(5, ph(500)), null))) !== null, M.lire(JSON.stringify(val(inst(5, ph(501)), null)))], [true, null]);
  eq('SM2 — tete hors 40 hex, blocage hors 12 hex, 65 blocages : null ; 64 : objet', [M.lire(JSON.stringify(val(inst(5, {}, 'abc'), null))), M.lire(JSON.stringify(val(inst(5, {}, null, ['XYZ']), null))),
    M.lire(JSON.stringify(val(inst(5, {}, null, Array(65).fill(B12)), null))), M.lire(JSON.stringify(val(inst(5, {}, null, Array(64).fill(B12)), null))) !== null], [null, null, null, true]);
});
essai('SM3', () => {
  const sig = { phases: [{ key: 'a|1', nom: 'MARQ-TITRE', avancement: { etat: 'en-cours' } }], missions: [{ nom: 'MARQ-SUJET', noeuds: [{ status: 'failed', step: 'MARQ-CMD' }] }],
    equipe: { workers: [{ kind: 'session', id: 'MARQ-SESSION', etat: 'attend', cwd: '/MARQ/chemin', titre: 'MARQ-TITRE', action: { commande: 'MARQ-CMD' } }] } };
  const d = C.depuisSignal(sig), bl = C.blocagesPresents({ missions: d.missions, workers: d.equipe.workers, blocagesState: [{ h: 'HZ', t: 'MARQ-BLOCAGE' }] });
  const i = C.instantane({ phases: Object.fromEntries(d.phases.map((p) => [p.key, p.avancement.etat])), tete: A40, blocages: bl.map((b) => b.cle), vu: 1000 });
  const t = M.ecrire(val(i, null));
  ok('SM3 — l\'instantané gardé ne porte ni titre, ni sujet, ni session, ni commande, ni chemin, ni texte de blocage', t && !/MARQ|chemin/.test(t) && bl.length === 3, t);
});
essai('SM4', () => {
  const v = val(inst(10000, {}), null);
  eq('SM4 — 1 799 s et 1 800 s : pas de rotation', [M.tourner(v, 11799).tourne, M.tourner(v, 11800).tourne, M.tourner(v, 11799).valeur.precedente], [false, false, null]);
  const r = M.tourner(v, 11801);
  eq('SM4 — 1 801 s : rotation, la courante devient la précédente', [r.tourne, r.valeur.precedente.vu, r.valeur.courante.vu], [true, 10000, 10000]);
  eq('SM4 — sans valeur : pas de rotation', M.tourner(null, 5), { valeur: null, tourne: false });
});
essai('SM5', () => {
  const nouveau = val(inst(5000, { 'a|1': 'fait' }), inst(4000, {})), ancien = val(inst(3000, {}), inst(2000, {}));
  const vu = (f) => [f.precedente.vu, f.courante.vu];
  eq('SM5 — une écriture plus ancienne arrivée en second ne recule aucun vu', vu(M.fusionner(nouveau, ancien)), [4000, 5000]);
  eq('SM5 — et dans l\'autre sens', vu(M.fusionner(ancien, nouveau)), [4000, 5000]);
  eq('SM5 — chaque instantané est comparé pour lui-même (null perd)', [M.fusionner(val(inst(5000, {}), null), val(inst(3000, {}), inst(4000, {}))), M.fusionner(null, null)].map((f) => f && [f.precedente && f.precedente.vu, f.courante.vu]), [[4000, 5000], null]);
  eq('SM5 — une valeur seule est reprise telle quelle', [M.fusionner(null, ancien), M.fusionner(ancien, null)].map((f) => vu(f)), [[2000, 3000], [2000, 3000]]);
});
essai('SM6', () => {
  const v = val(inst(5, {}), inst(3, {})), p = inst(9, { 'a|1': 'fait' });
  const t = M.toutVu(v, p), a = M.avecCourante(v, p);
  eq('SM6 — « Tout vu » : précédente et courante égales au présent ; avecCourante ne touche que la courante', [JSON.stringify(t.precedente) === JSON.stringify(p) && JSON.stringify(t.courante) === JSON.stringify(p), a.precedente.vu, a.courante.vu, M.toutVu(null, p).precedente.vu], [true, 3, 9, 9]);
});
essai('SM7', () => {
  const gros = {}; for (let i = 0; i < 150; i++) gros['x'.repeat(60) + String(i).padStart(4, '0') + '|1'] = 'fait';
  eq('SM7 — au-delà de 8 192 octets : null (la page retire la clé) ; valeur ordinaire : texte', [M.ecrire(val(inst(1, gros), null)), typeof M.ecrire(bon)], [null, 'string']);
});
essai('SM8', () => { const t = M.ecrire(bon); eq('SM8 — aller-retour lire(ecrire(v)) égal', [JSON.stringify(M.lire(t)), t], [JSON.stringify(bon), JSON.stringify(bon)]); });
JS

run_sc() { # <dossier ui> [étiquettes…] : affiche et compte ; rend le nombre de lignes lues dans N
  local ligne r; N=0
  while IFS= read -r ligne; do
    case "$ligne" in
      PASS\|*) echo "  ✅ PASS — ${ligne#PASS|}"; PASS=$((PASS+1)); N=$((N+1));;
      FAIL\|*) r="${ligne#FAIL|}"; echo "  ❌ FAIL — ${r%%|*}"; echo "     ${r#*|}"; FAIL=$((FAIL+1)); N=$((N+1));;
    esac
  done < <(node "$AUX/sc.mjs" "$@" 2>&1)
  [ "$N" -gt 0 ] || { echo "  ❌ FAIL — le banc node n'a rendu aucune ligne ($*)"; FAIL=$((FAIL+1)); }
}
echo "=== SC, SM — calcul et mémoire sous vm ==="
run_sc "$UI"

# --- SG : base.h de /api/vf/git (dépôt fabriqué : base main, worktree sur une branche de fonction) ---
cat > "$AUX/sg.mjs" <<'JS'
import path from 'node:path';
const [, , scripts, lab] = process.argv;
const { lireGit } = await import(path.join(scripts, 'vf-cockpit-git.mjs'));
const r = await lireGit(lab);
console.log(JSON.stringify({ etat: r.etat, nom: r.base?.nom ?? null, h: r.base?.h ?? null, rh: (r.rangees || []).map((x) => x.h) }));
JS
echo "=== SG — sommet de la base servi ==="
T=0; tick() { T=$((T+1)); export GIT_AUTHOR_DATE="@$((1700000000+T*60)) +0000" GIT_COMMITTER_DATE="@$((1700000000+T*60)) +0000"; }
GR="$WORK/gr"; mkdir -p "$GR"; G() { "$GIT_REEL" -C "$GR" "$@"; }
G init -q -b main; tick; G commit -q --allow-empty -m c0; tick; G commit -q --allow-empty -m c1
G worktree add -q "$WORK/gr-wt" -b feat; tick; "$GIT_REEL" -C "$WORK/gr-wt" commit -q --allow-empty -m f1; tick; "$GIT_REEL" -C "$WORK/gr-wt" commit -q --allow-empty -m f2
MAIN="$(G rev-parse refs/heads/main)"; FEAT="$("$GIT_REEL" -C "$WORK/gr-wt" rev-parse HEAD)"
assert_eq "SG0 — témoin : la branche de fonction est en avance sur main (sa tête n'est pas celle de la base)" "$([ "$MAIN" != "$FEAT" ] && echo oui)" "oui"
SGJ="$(node "$AUX/sg.mjs" "$SCRIPTS" "$WORK/gr-wt" 2>&1)"
sgv() { node -e 'const j=JSON.parse(process.argv[1]); console.log(process.argv[2]==="h"?j.h:process.argv[2]==="nom"?j.nom:String(j.rh.includes(j.h)))' "$1" "$2" 2>/dev/null; }
assert_eq "SG1 — base.h = refs/heads/main (40 hex), vu depuis le worktree de la branche de fonction" "$(sgv "$SGJ" h)" "$MAIN"
assert_eq "SG2 — sonde positive : base.nom vaut main" "$(sgv "$SGJ" nom)" "main"
assert_eq "SG3 — base.h est le h d'une rangée servie" "$(sgv "$SGJ" rh)" "true"

# --- SP : pureté des deux fichiers ---
echo "=== SP — pureté ==="
INTERDIT='document|localStorage|sessionStorage|fetch|XMLHttpRequest|WebSocket|Date\.now|new Date|Math\.random|performance|crypto|Floorplan|addEventListener|setTimeout|setInterval'
for f in calcul memoire; do
  F="$UI/74-vf-synthese-$f.js"; CODE="$(awk '{ sub(/\/\/.*$/, ""); print }' "$F" 2>/dev/null)"
  assert_eq "SP1 — $f : première ligne non vide « // VibeFlow ( »" "$(awk 'NF{print substr($0,1,13); exit}' "$F" 2>/dev/null)" "// VibeFlow ("
  assert_eq "SP2 — $f : moins de 300 lignes" "$([ "$(awk 'END{print NR}' "$F" 2>/dev/null)" -le 299 ] 2>/dev/null && echo oui)" "oui"
  assert_eq "SP3 — $f : ni DOM, ni stockage, ni réseau, ni horloge, ni hasard, ni objet du moteur, ni écouteur (hors commentaires)" "$(printf '%s\n' "$CODE" | /usr/bin/grep -cE "$INTERDIT")" "0"
  assert_eq "SP4 — $f : un seul accès à window (la pose de l'export)" "$(printf '%s\n' "$CODE" | /usr/bin/grep -o 'window' | wc -l | tr -d ' ')" "1"
done
assert_eq "SP5 — la clé de la visite guidée n'est jamais produite ni lue" "$(/usr/bin/grep -c 'vibeflow-cockpit:visite:' "$UI/74-vf-synthese-calcul.js" "$UI/74-vf-synthese-memoire.js" 2>/dev/null | tr '\n' ' ')" "$UI/74-vf-synthese-calcul.js:0 $UI/74-vf-synthese-memoire.js:0 "

# --- SV : inventaire du plafond, plafonds de taille, cliquet de colonnes ---
echo "=== SV — inventaire et plafonds ==="
assert_eq "SV1 — sonde positive : une ligne AJOUT existante se lit par la même recette" "$(/usr/bin/grep -c '^AJOUT assets/ui/71-vf-equipe-rendu.js$' "$VEND")" "1"
for f in calcul memoire; do assert_eq "SV1 — $f : sa ligne AJOUT à deux champs dans VENDORED.txt" "$(/usr/bin/grep -c "^AJOUT assets/ui/74-vf-synthese-$f.js\$" "$VEND")" "1"; done
assert_eq "SV1 — les lignes AJOUT restent en ordre alphabétique (A52)" "$(/usr/bin/grep '^AJOUT ' "$VEND" | LC_ALL=C sort -c >/dev/null 2>&1; echo $?)" "0"
cat > "$AUX/plafond.mjs" <<'JS'
import fs from 'node:fs';
let mal = 0;
for (const f of process.argv.slice(2)) { const l = fs.readFileSync(f, 'utf8').split('\n'); if (l.length - 1 > 299 || l.some((x) => [...x.replace(/\r$/, '')].length > 160)) mal++; }
console.log(mal);
JS
assert_eq "SV3 — au plus 299 lignes et aucune ligne de plus de 160 points de code (mesure node)" "$(node "$AUX/plafond.mjs" "$UI/74-vf-synthese-calcul.js" "$UI/74-vf-synthese-memoire.js" 2>&1)" "0"
# SV4 : le cliquet sur une mini-racine hermétique (les deux fichiers seuls, baseline vide) ; sonde positive : une ligne de 161 points de code le fait rougir
MR="$WORK/mini"; mkdir -p "$MR/scripts" "$MR/skills/cockpit-moteur/assets/ui"; : > "$WORK/baseline-vide.txt"
for f in calcul memoire; do cp "$UI/74-vf-synthese-$f.js" "$MR/skills/cockpit-moteur/assets/ui/" 2>/dev/null; printf 'AJOUT assets/ui/74-vf-synthese-%s.js\n' "$f" >> "$MR/skills/cockpit-moteur/VENDORED.txt"; done
node "$SCRIPTS/tests/colonnes-cliquet.mjs" verifier "$MR" "$WORK/baseline-vide.txt" >/dev/null 2>&1; assert_eq "SV4 — le cliquet de colonnes rend vert avec les deux fichiers" "$?" "0"
printf '// %s\n' "$(printf 'x%.0s' $(seq 1 158))" >> "$MR/skills/cockpit-moteur/assets/ui/74-vf-synthese-memoire.js"
node "$SCRIPTS/tests/colonnes-cliquet.mjs" verifier "$MR" "$WORK/baseline-vide.txt" >/dev/null 2>&1; assert_eq "SV4 — sonde positive : une ligne de 161 points de code le rend rouge (code 1)" "$?" "1"

# --- mutants (A48) : copie du module, substitution sed sur le fichier DE LA COPIE, le banc lit la copie ; le module d'origine est inchangé (sommes) ; un mutant sans effet est un FAIL ---
echo "=== M — mutants ==="
mut() { # <nom> <fichier relatif au module> <expression sed> <étiquette de la sonde> [banc : sc|sg]
  local nom="$1" fic="$2" expr="$3" sonde="$4" banc="${5:-sc}" copie cible av ap sortie rouge
  av="$(cksum < "$MODULE/$fic" 2>/dev/null)"
  copie="$(cockpit_module_copie "$WORK/mod-$nom")" || { assert_eq "$nom — copie du module" "échec" "ok"; return; }
  cible="$copie/$fic"
  [ -f "$cible" ] || { assert_eq "$nom — fichier visé présent dans la copie" "absent" "présent"; return; }
  cp "$cible" "$cible.avant" && sed "$expr" "$cible.avant" > "$cible";
  if cmp -s "$cible.avant" "$cible"; then assert_eq "$nom — le mutant change le fichier (ancre présente)" "sans effet" "effet"; return; fi
  rm -f "$cible.avant"
  if [ "$banc" = sg ]; then
    sortie="$(node "$AUX/sg.mjs" "$copie/scripts" "$WORK/gr-wt" 2>&1)"; rouge="$([ "$(sgv "$sortie" h)" != "$MAIN" ] && echo oui || echo non)"
  else
    sortie="$(COCKPIT_MODULE="$copie" node "$AUX/sc.mjs" "$copie/skills/cockpit-moteur/assets/ui" "$sonde" 2>&1)"; rouge="$(printf '%s\n' "$sortie" | /usr/bin/grep -c '^FAIL|' | awk '{print ($1>0)?"oui":"non"}')"
  fi
  ap="$(cksum < "$MODULE/$fic" 2>/dev/null)"
  assert_eq "$nom — la sonde $sonde rougit sur la copie mutée, le module d'origine est intact" "$rouge/$([ "$av" = "$ap" ] && echo intact)" "oui/intact"
}
CAL=skills/cockpit-moteur/assets/ui/74-vf-synthese-calcul.js; MEM=skills/cockpit-moteur/assets/ui/74-vf-synthese-memoire.js
mut M-DATE "$CAL" 's/if (!anc\.has(h)) n++;/if (!anc.has(h) \&\& (par.get(h).at | 0) > 1050) n++;/' SC2
mut M-NONFUS "$CAL" 's/for (const h of ancetres(sommet))/for (const h of par.keys())/' SC2
mut M-RESERVE "$CAL" 's/const longue = maintenant - vu > FENETRE_S;/const longue = false;/' SC4
mut M-LEVE "$CAL" 's/const leves = precedente\.blocages\.filter((c) => !presents\.has(c))\.length;/const leves = precedente.blocages.filter((c) => !presents.has(c)).map((c) => ({ cle: c }));/' SC5
mut M-BASEH scripts/vf-cockpit-git.mjs 's/h: refBase ? shaRef(refBase) : null/h: ici ? ici.head : null/' SG1 sg
mut M-CLE-VISITE "$MEM" 's/vibeflow-cockpit:derniere-visite:/vibeflow-cockpit:visite:/' SM1
mut M-ORIGINE "$MEM" 's/? PREFIXE + lab : null/? PREFIXE + lab : PREFIXE + "origine"/' SM1
mut M-SEUIL "$MEM" 's/SEUIL_ROTATION_S = 1800/SEUIL_ROTATION_S = 1/' SM4
mut M-FUSION "$MEM" 's/b\.vu > a\.vu ? b : a/b/' SM5
mut M-LISTE "$MEM" 's/Object\.keys(o)\.length === cles\.length/Object.keys(o).length >= cles.length/' SM2

vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
