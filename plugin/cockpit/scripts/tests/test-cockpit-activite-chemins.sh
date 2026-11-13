#!/usr/bin/env bash
# test-cockpit-activite-chemins.sh — Phase 75, plan 75-03 tâche 1 (ACTV-08, ACTV-09, ACTV-10) : normalisation des chemins, sentinelle « hors du lab », jointure par
# (arbre, cible), garde de `files_modified`, preuve générative en N et 2N ; node seul, aucun processus laissé, aucune lecture hors des fixtures de la suite.
#   C0 forme livrée par 79-13 · C1 carte / hors-carte / hors-lab, préfixe du lab non redoublé · C2 formes hostiles (et lien résolu par la fonction LIVRÉE)
#   C3 linéarité en N et 2N · C4 degrés · C5 jointure par (arbre, cible) · C6 cibles coupées, listes tronquées · C7 nom de worktree ambigu ou absent (A46)
# Chaque garde a son mutant : une copie des modules, une retouche d'une ligne, la suite rejouée ; « MUTANT-ROUGE — <nom> » quand le témoin visé rougit.
# Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « BILAN : n PASS, m FAIL » ; sort avec un code non nul au premier FAIL.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/75-03-chemins.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/mut.mjs" <<'JS'
// mut.mjs <dossier> <fichier> <de> <vers> [<de> <vers> ...] : retouche chaque occurrence UNIQUE ; sort 2 si une chaîne manque ou n'est pas unique
import fs from 'node:fs';
const [, , dir, fichier, ...paires] = process.argv;
let t = fs.readFileSync(`${dir}/${fichier}`, 'utf8');
for (let i = 0; i < paires.length; i += 2) {
  if (t.split(paires[i]).length !== 2) { console.error(`introuvable ou multiple : ${paires[i]}`); process.exit(2); }
  t = t.replace(paires[i], () => paires[i + 1]);
}
fs.writeFileSync(`${dir}/${fichier}`, t);
JS

cat > "$WORK/h.mjs" <<'JS'
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , MOD, SCR] = process.argv;
const imp = (d, f) => import(pathToFileURL(path.join(d, f)).href);
const CH = await imp(MOD, 'vf-cockpit-activite-chemins.mjs');
const EM = await imp(MOD, 'vf-cockpit-activite-empreinte.mjs');
const CO = await imp(MOD, 'vf-cockpit-activite-collisions.mjs');
const FV = await imp(SCR, 'vf-cockpit-frise-voie.mjs');
const CI = await imp(SCR, 'vf-cockpit-cible.mjs');
const J = JSON.stringify;
const ok = (id, t) => console.log(`PASS — ${id} : ${t}`);
const ko = (id, t, att, obt) => { console.log(`❌ FAIL — ${id} : ${t}`); console.log(`     attendu: ${att}`); console.log(`     obtenu:  ${obt}`); };
const eq = (id, t, obt, att) => (J(obt) === J(att) ? ok(id, t) : ko(id, t, J(att), J(obt)));
const vrai = (id, t, c, obt = '') => (c ? ok(id, t) : ko(id, t, 'vrai', `faux ${obt}`));
async function cas(id, f) { try { await f(); } catch (e) { ko(id, 'exception', 'aucune', String((e && e.stack) || e).split('\n').slice(0, 3).join(' | ')); } }
const med = (f) => { f(); const t = []; for (let i = 0; i < 5; i++) { const s = performance.now(); f(); t.push(performance.now() - s); } t.sort((a, b) => a - b); return t[2]; };

// une voie construite par la projection LIVRÉE (79-13) : la fixture suit la forme livrée, jamais l'inverse
const ent = (arbre, cible, dernierMs = 0) => ({ arbre, cible, n: 1, dernierMs });
function voie(o) {
  const p = { id: o.id, kind: o.kind ?? 'subagent', session: o.session ?? 's1', parent: o.parent ?? null, depth: 1, role: o.role ?? 'vf-coder', background: false, debut: o.debut ?? 0,
    fin: o.fin ?? null, dispatchA: null, fini: o.etat === 'termine', arrete: false, modeles: [], compteurs: {}, jetons: {}, durees: {}, segments: [], evenements: [], enCours: null };
  return FV.projeterVoie(p, { arbre: o.arbre ?? null, etatOfficiel: o.etat ?? 'actif', rattachement: o.rat === undefined ? { dag: 'd', noeud: 'N1', source: 'registre' } : o.rat,
    cibles: { etat: o.etatC ?? 'ok', tronque: o.tronque === true, ecritures: o.e ?? [], lectures: o.l ?? [] } });
}
const HORS = CI.HORS;
const NFD = 'e\u0301.mjs', NFC = '\u00e9.mjs';
const ctx = (plus = {}) => ({ cartes: new Set(['plugin/x.mjs', 'sous/dossier/x.mjs', 'src/a.mjs', 'src/b.mjs', NFC, HORS]), worktreesVerifies: ['wt-a'], nomPrincipal: 'depot',
  prefixeLab: 'sous/dossier', maintenant: 1e12, ...plus });

await cas('C0', () => {
  eq('C0', 'les clés d\'une voie livrée sont les 23 champs de C3', Object.keys(voie({ id: 'a' })).sort(), [...FV.CHAMPS_VOIE].sort());
  eq('C0', 'le libellé « hors du lab » du module est celui que 79-13 livre', CH.HORS_LAB, HORS);
});

await cas('C1', () => {
  const c = ctx();
  eq('C1', 'cible connue : carte', CH.normaliser({ arbre: null, cible: 'plugin/x.mjs' }, c), { etat: 'carte', chemin: 'plugin/x.mjs' });
  eq('C1', 'cible sans carte : hors-carte', CH.normaliser({ arbre: null, cible: 'plugin/y.mjs' }, c), { etat: 'hors-carte', chemin: 'plugin/y.mjs' });
  eq('C1', '« un fichier hors du lab » est une sentinelle, même si une carte porte ce texte', CH.normaliser({ arbre: null, cible: HORS }, c).etat, 'hors-lab');
  eq('C1', 'lab sous-dossier du dépôt : le préfixe n\'est pas retiré une seconde fois (A33)', CH.normaliser({ arbre: null, cible: 'sous/dossier/x.mjs' }, c), { etat: 'carte', chemin: 'sous/dossier/x.mjs' });
  eq('C1', 'worktree vérifié : la même cible se retrouve sur la carte', CH.normaliser({ arbre: 'wt-a', cible: 'src/a.mjs' }, c).etat, 'carte');
});

await cas('C2', () => {
  const c = ctx(), hostiles = [['..', '..'], ['../x', '../x'], ['a/../../b', 'a/../../b'], ['absolu', '/etc/passwd'], ['NUL', 'a\0b'], ['retour ligne', 'a\nb'], ['U+2028', 'a\u2028b'],
    ['U+2029', 'a\u2029b'], ['tabulation', 'a\tb'], ['contrôle', 'a\u0007b'], ['DEL', 'a\u007fb'], ['4 097 octets', 'x'.repeat(4097)], ['4 098 octets (é)', '\u00e9'.repeat(2049)],
    ['lecteur', 'C:\\x'], ['UNC', '\\\\srv\\x'], ['vide', ''], ['non texte', 42]];
  for (const [nom, cible] of hostiles) {
    eq('C2', `${nom} : rejeté`, CH.normaliser({ arbre: null, cible }, c), { etat: 'rejete', chemin: null });
    eq('C2', `${nom} : gardeFilesModified refuse`, CH.gardeFilesModified(cible), false);
  }
  eq('C2', '4 096 octets exactement : accepté', CH.normaliser({ arbre: null, cible: 'x'.repeat(4096) }, c).etat, 'hors-carte');
  eq('C2', 'a/../b : accepté, comparé BRUT (jamais réécrit en b)', CH.normaliser({ arbre: null, cible: 'a/../b' }, c), { etat: 'hors-carte', chemin: 'a/../b' });
  eq('C2', 'NFD contre NFC : comparé tel quel, jamais corrigé en silence', [CH.normaliser({ arbre: null, cible: NFD }, c).etat, CH.normaliser({ arbre: null, cible: NFC }, c).etat], ['hors-carte', 'carte']);
  eq('C2', 'majuscules : comparées telles quelles', CH.normaliser({ arbre: null, cible: 'PLUGIN/x.mjs' }, c).etat, 'hors-carte');
  eq('C2', 'gardeFilesModified accepte un chemin relatif ordinaire', [CH.gardeFilesModified('plugin/x.mjs'), CH.gardeFilesModified('a/./b')], [true, true]);
  // la fonction LIVRÉE (79-07 via 79-13) : un lien résolu hors du lab arrive en « hors du lab » ; le témoin passe par elle, pas par une réécriture
  const t = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), '75-03-lab.')));
  try {
    fs.mkdirSync(`${t}/lab/plugin`, { recursive: true }); fs.mkdirSync(`${t}/dehors`);
    fs.writeFileSync(`${t}/lab/plugin/x.mjs`, ''); fs.writeFileSync(`${t}/dehors/secret.mjs`, '');
    fs.symlinkSync(`${t}/dehors`, `${t}/lab/sortie`);
    const table = CI.racinesDeComparaison(`${t}/lab`, [{ chemin: `${t}/lab`, principal: true }]), defaut = table[0];
    const via = (v) => { const r = CI.reduireCible(v, table, defaut); return CH.normaliser(r, c).etat; };
    eq('C2', 'lien sortant résolu par la fonction livrée : hors-lab', via(`${t}/lab/sortie/secret.mjs`), 'hors-lab');
    eq('C2', 'chemin relatif réduit par la fonction livrée : carte', via('plugin/x.mjs'), 'carte');
  } finally { fs.rmSync(t, { recursive: true, force: true }); }
});

await cas('C3', () => {
  const formes = [['a/..', (n) => 'a/'.repeat(n) + '..', false], ['../', (n) => '../'.repeat(n), true], ['espaces', (n) => ' '.repeat(n), false], ['x', (n) => 'x'.repeat(n), false],
    ['NUL', (n) => '\0'.repeat(n), false], ['U+2028', (n) => '\u2028'.repeat(n), false]];
  for (const [nom, f, remonte] of formes) {
    eq('C3', `${nom} (N = 20 000) : parcourir juste`, CH.parcourir(f(20000)), remonte);
    vrai('C3', `${nom} (N = 20 000) : rejeté par la borne de taille avant toute passe`, CH.raisonRejet(f(20000)) !== null && CH.normaliser({ arbre: null, cible: f(20000) }, ctx()).etat === 'rejete');
  }
  eq('C3', 'a/ x 1 000 puis .. (2 002 octets) : accepté et compté hors-carte', CH.normaliser({ arbre: null, cible: 'a/'.repeat(1000) + '..' }, ctx()).etat, 'hors-carte');
  eq('C3', '../ x 1 000 (3 000 octets) : rejeté', CH.normaliser({ arbre: null, cible: '../'.repeat(1000) }, ctx()).etat, 'rejete');
  const t1 = med(() => CH.parcourir('a/'.repeat(20000) + '..')), t2 = med(() => CH.parcourir('a/'.repeat(40000) + '..'));
  console.log(`  mesure a/..  N = 20000 : ${t1.toFixed(2)} ms ; 2N = 40000 : ${t2.toFixed(2)} ms ; seuil ${(2.5 * t1 + 2).toFixed(2)} ms`);
  vrai('C3', 't(2N) <= 2,5 x t(N) + 2 ms sur a/ répété puis ..', t2 <= 2.5 * t1 + 2, `t1=${t1.toFixed(2)} t2=${t2.toFixed(2)}`);
  const c = ctx({ worktreesVerifies: ['__proto__'], cartes: new Set(['__proto__']) });
  const r = CH.rassembler([{ arbre: '__proto__', cible: '__proto__', ref: 1 }], c);
  eq('C3', 'aucune clé d\'objet n\'est construite d\'un chemin ni d\'un arbre', [Object.keys(r), Object.keys(r.groupes[0]), Object.keys(r.compte), r.groupes[0].chemin], [['groupes', 'compte', 'etats'], ['arbre', 'chemin', 'carte', 'refs'], ['carte', 'horsCarte', 'horsLab', 'coupees', 'rejetes'], '__proto__']);
});

await cas('C4', () => {
  const v = voie({ id: 'v1', etat: 'actif', e: [ent(null, 'src/a.mjs', 100), ent(null, 'src/b.mjs', 200)] });
  eq('C4', 'voie active : dernière écriture en-cours, autres modifié', EM.empreinte([v], ctx()).marques.map((m) => [m[0], m[1]]), [['src/a.mjs', 'modifie'], ['src/b.mjs', 'en-cours']]);
});

await cas('C5', () => {
  const c = ctx(), r = CH.rassembler([{ arbre: null, cible: 'src/a.mjs', ref: 'p' }, { arbre: 'wt-a', cible: 'src/a.mjs', ref: 'w' }], c);
  eq('C5', 'la même cible dans deux arbres vérifiés : deux groupes distincts', r.groupes.map((g) => [g.arbre, g.chemin, g.carte, g.refs]), [[null, 'src/a.mjs', true, ['p']], ['wt-a', 'src/a.mjs', true, ['w']]]);
  eq('C5', 'un worktree vérifié est vu et jamais compté hors du lab', r.compte.horsLab, 0);
  eq('C5', 'le worktree vérifié se joint à la carte par la cible seule', EM.empreinte([voie({ id: 'w', arbre: 'wt-a', e: [ent('wt-a', 'src/b.mjs', 5)] })], c).marques.map((m) => m[0]), ['src/b.mjs']);
});

await cas('C6', () => {
  const X = 'd/' + 'f'.repeat(117), coupee = X + '\u2026', cartes = new Set([X, X + 'zzzz', 'src/a.mjs']);
  eq('C6', 'la cible coupée mesure 120 unités et finit par …', [coupee.length, CI.fin(X + 'zzzz' + 'q'.repeat(50)).endsWith('\u2026')], [120, true]);
  const c = ctx({ cartes });
  eq('C6', 'une cible coupée n\'est jamais jointe à une carte, même de même préfixe', CH.normaliser({ arbre: null, cible: coupee }, c), { etat: 'coupee', chemin: null });
  const A = voie({ id: 'a', e: [ent(null, coupee, 9)] }), B = voie({ id: 'b', role: 'vf-reviewer', e: [ent(null, X, 9)] });
  const col = CO.collisionsAgents([A, B], c);
  eq('C6', 'coupée contre sa jumelle entière : aucune collision, comptée coupees, jamais hors carte', [col.collisions, col.coupees, col.horsCarte], [[], 1, 0]);
  eq('C6', 'le radar dit qu\'il ne peut pas conclure : incomplet, raison cibles-coupees', [col.incomplet, col.raisons], [true, ['cibles-coupees']]);
  const em = EM.empreinte([A, B], c);
  eq('C6', 'l\'empreinte porte la limite cibles-coupees', [em.limite.includes('cibles-coupees'), em.coupees], [true, 1]);
  eq('C6', '120 unités sans … : cible entière (carte)', CH.normaliser({ arbre: null, cible: 'y'.repeat(120) }, ctx({ cartes: new Set(['y'.repeat(120)]) })).etat, 'carte');
  const T = voie({ id: 't', tronque: true, e: [ent(null, 'src/a.mjs', 1)] }), U = voie({ id: 'u', role: 'vf-reviewer', e: [ent(null, 'src/a.mjs', 2)] });
  const ct = CO.collisionsAgents([T, U], c);
  eq('C6', 'voie à liste coupée : ses cibles entières se joignent (collision rendue)', ct.collisions.map((x) => [x[0], x[1]]), [['src/a.mjs', 'agents']]);
  eq('C6', 'voie à liste coupée : incomplet, raison cibles-coupees, jamais « aucune »', [ct.incomplet, ct.raisons], [true, ['cibles-coupees']]);
  const nul = { ...voie({ id: 'n' }), cibles: null }, cn = CO.collisionsAgents([nul], c);
  eq('C6', 'cibles null : voie ignorée et comptée', [cn.ignorees, cn.collisions], [1, []]);
});

await cas('C7', () => {
  const e = (a) => voie({ id: a + Math.random(), arbre: a, e: [ent(a, 'src/a.mjs', 5)] });
  const dup = ctx({ worktreesVerifies: ['dup', 'dup'] });
  eq('C7', 'nom porté par deux worktrees vérifiés : sentinelle', CH.normaliser({ arbre: 'dup', cible: 'src/a.mjs' }, dup).etat, 'hors-lab');
  const col = CO.collisionsAgents([e('dup'), voie({ id: 'x2', arbre: 'dup', role: 'vf-reviewer', e: [ent('dup', 'src/a.mjs', 5)] })], dup);
  eq('C7', 'deux arbres homonymes ne fusionnent jamais : aucune collision, deux écritures comptées hors du lab', [col.collisions, col.horsLab], [[], 2]);
  eq('C7', 'le nom de base de l\'arbre principal compte : un worktree de ce nom n\'est pas admis', CH.normaliser({ arbre: 'depot', cible: 'src/a.mjs' }, ctx({ worktreesVerifies: ['depot'] })).etat, 'hors-lab');
  eq('C7', 'un nom unique reste admis', CH.normaliser({ arbre: 'wt-a', cible: 'src/a.mjs' }, ctx()).etat, 'carte');
  eq('C7', 'fermé par défaut : aucune liste d\'arbres vérifiés, un worktree n\'est pas admis', CH.normaliser({ arbre: 'wt-a', cible: 'src/a.mjs' }, { cartes: new Set(['src/a.mjs']) }).etat, 'hors-lab');
});
JS

# --- la suite sur le code livré ---
OUT="$WORK/reel.out"
node "$WORK/h.mjs" "$SCRIPTS" "$SCRIPTS" > "$OUT" 2>&1
cat "$OUT"
NB=$(grep -c '^PASS — ' "$OUT"); NF=$(grep -c '^❌ FAIL — ' "$OUT")
if [ "$NF" -gt 0 ] || [ "$NB" -eq 0 ]; then echo "BILAN : $NB PASS, $((NF > 0 ? NF : 1)) FAIL"; exit 1; fi

# --- les mutants : une copie des modules, une retouche, la suite rejouée ; le témoin visé doit rougir ---
MU=0
mutant() { # mutant <nom> <témoin attendu rouge> <fichier> <de> <vers> [<de> <vers>]
  local nom="$1" id="$2" f="$3"; shift 3
  local d="$WORK/m-$MU"; MU=$((MU+1)); mkdir -p "$d"
  cp "$SCRIPTS"/vf-cockpit-activite-chemins.mjs "$SCRIPTS"/vf-cockpit-activite-empreinte.mjs "$SCRIPTS"/vf-cockpit-activite-collisions.mjs "$d/"
  if ! node "$WORK/mut.mjs" "$d" "$f" "$@" 2> "$d/err"; then echo "❌ FAIL — MUT : $nom : retouche impossible ($(cat "$d/err"))"; echo "BILAN : $NB PASS, 1 FAIL"; exit 1; fi
  node "$WORK/h.mjs" "$d" "$SCRIPTS" > "$d/out" 2>&1
  if grep -q "^❌ FAIL — $id " "$d/out"; then echo "MUTANT-ROUGE — $nom ($id rouge)"; else echo "❌ FAIL — MUT : $nom : le témoin $id reste vert"; echo "BILAN : $NB PASS, 1 FAIL"; exit 1; fi
}
CH=vf-cockpit-activite-chemins.mjs; EMP=vf-cockpit-activite-empreinte.mjs

mutant 'pile-recopiee' C3 $CH 'const pile = [];' 'let pile = [];' 'pile.push(s)' 'pile = [...pile, s]'
mutant 'prefixe-du-lab-redouble' C1 $CH "const cible = entree && entree.cible;" "const cible0 = entree && entree.cible; const cible = typeof cible0 === 'string' && typeof contexte.prefixeLab === 'string' && cible0.startsWith(contexte.prefixeLab + '/') ? cible0.slice(contexte.prefixeLab.length + 1) : cible0;"
mutant 'hors-lab-traite-comme-carte' C1 $CH "if (cible === (contexte.libelleHorsLab ?? HORS_LAB)) return { etat: 'hors-lab', chemin: null };" ''
mutant 'comparaison-apres-nettoie' C2 $CH "const cible = entree && entree.cible;" "const cible = entree && typeof entree.cible === 'string' ? entree.cible.replace(/\\s+/g, ' ').trim() : undefined;"
mutant 'rejet-du-NUL-retire' C2 $CH '/[\u0000-\u001f' '/[\u0001-\u001f'
mutant 'arbre-ignore-dans-la-jointure' C5 $CH 'const cle = e.arbre ?? null;' 'const cle = null;'
mutant 'cible-coupee-jointe-par-prefixe' C6 $CH "if (cible.endsWith(COUPEE)) return { etat: 'coupee', chemin: null };" "if (cible.endsWith(COUPEE)) { const pre = cible.slice(0, -1); const x = contexte.cartes ? [...contexte.cartes].find((y) => y.startsWith(pre)) : undefined; return x ? { etat: 'carte', chemin: x } : { etat: 'hors-carte', chemin: pre }; }"
mutant 'nom-de-worktree-ambigu-admis' C7 $CH 'return n === 1;' 'return n >= 1;'
mutant 'cibles-d-une-voie-tronquee-jamais-jointes' C6 $EMP 'if (v.cibles.tronque === true) r.cibleTronquee = true;' 'if (v.cibles.tronque === true) { r.cibleTronquee = true; continue; }'
mutant 'garde-remonte-retiree' C2 $CH "if (parcourir(chemin)) return 'remonte';" ''
mutant 'garde-absolu-retiree' C2 $CH "if (ABSOLU.test(chemin)) return 'absolu';" ''
mutant 'garde-taille-retiree' C2 $CH "if (chemin.length > MAX_OCTETS || Buffer.byteLength(chemin, 'utf8') > MAX_OCTETS) return 'taille';" ''
mutant 'garde-controle-retiree' C2 $CH "if (CTRL.test(chemin)) return 'controle';" ''
mutant 'gardeFilesModified-toujours-vraie' C2 $CH 'export const gardeFilesModified = (chemin) => raisonRejet(chemin) === null;' 'export const gardeFilesModified = () => true;'
mutant 'coupee-traitee-comme-entiere' C6 $CH "if (cible.endsWith(COUPEE)) return { etat: 'coupee', chemin: null };" ''

echo "BILAN : $NB PASS, 0 FAIL"
