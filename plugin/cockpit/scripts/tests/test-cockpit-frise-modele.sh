#!/usr/bin/env bash
# test-cockpit-frise-modele.sh — modèle pur de la frise (Phase 74, plan 74-01 ; TEMP-01 à TEMP-05 part calcul, TEMP-09, TEMP-10).
# Les deux modules `ui/74-vf-frise-calculs.js` puis `ui/74-vf-frise-modele.js` (ordre lexical) sont chargés sous node:vm, sans navigateur ni serveur ;
# fixtures SYNTHETIQUES de `frise-fabrique.mjs` (formes C3, A43, A45, A48 de la Phase 79 : A REVALIDER sur la forme réelle de 79-13).
#   F0  modules chargés ; contrôle positif : sur un dossier VIDE chaque section F1 à F15 et FMT rougit (« une sonde reste verte sans module » sinon)
#   F1  lire (schéma avant tout champ, genres inconnus, cibles/arbre nuls, tronque, voiesOmises)   F2  unités (secondes -> millisecondes)
#   F3  arbre (ordre, enfants, session sans segment) · F3b cycle et plafond   F4  fenêtres et voies tronquées   F5  repli des workers
#   F6  projection Horloge / Événements · F6b graduations au passage à l'heure d'hiver (TZ=Europe/Paris)   F7  etatA   F8  noeudsPortes
#   F9  agreger   F10 TEMP-10 (a : texte des modules ; b : contrat — NON vérifiée tant que 79-13 n'a pas posé le bloc)   F11 courbe
#   F12 dépôt (commitsParBranche, couverture)   F13 δ et voiesAutour   F14 fichiersA   F15 forme du code (A44)   FMT formats français
# Pas de mutants (régime allégé, consigne de la session principale, 2026-11-13) ; aucun serveur lancé, donc pas d'hygiène de processus.
# Exit 0 si tout passe, 1 sinon. Les `⊘` sont annoncés en fin de sortie, jamais comptés comme réussis.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
HERE_T="$(cd "$(dirname "$0")" && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; VIDE="$WORK/vide"; mkdir -p "$AUX" "$VIDE"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/sondes.mjs" <<'JS'
// sondes.mjs <dossierUI> <frise-fabrique.mjs> : joue toutes les sections sur les modules du dossier ; une ligne PASS/FAIL par assertion.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';

const [, , DIR, FAB] = process.argv;
const F = await import(pathToFileURL(FAB).href);
const { NOW, MIN, voie, entree, fabrique, quiMissions, quiPhases, element, rangee, tete, git } = F;
const FICHIERS = ['74-vf-frise-calculs.js', '74-vf-frise-modele.js'];
const NB = ' ';
let pass = 0, fail = 0, neutres = 0, sec = '';
const dire = (s) => console.log(s);
const j = (x) => JSON.stringify(x);
const ok = (cond, label, detail) => {
  if (cond) { pass++; dire(`  ✅ PASS — ${sec} : ${label}`); return; }
  fail++; dire(`  ❌ FAIL — ${sec} : ${label}`);
  if (detail !== undefined) dire(`     ${String(detail).slice(0, 500)}`);
};
const eq = (got, want, label) => ok(j(got) === j(want), label, `attendu ${j(want)} ; obtenu ${j(got)}`);
const neutre = (label) => { neutres++; dire(`  ⊘ NON vérifiée, non comptée comme réussie — ${sec} : ${label}`); };

function charger(dir, noms) {
  const ctx = vm.createContext({ window: {}, document: undefined });
  for (const n of noms) {
    const f = path.join(dir, n);
    if (!fs.existsSync(f)) return { absent: n };
    try { vm.runInContext(fs.readFileSync(f, 'utf8'), ctx, { filename: n }); } catch (e) { return { erreur: `${n} : ${e.message}` }; }
  }
  return { M: ctx.window.__vfFriseModele, C: ctx.window.__vfFriseCalculs };
}
const L = charger(DIR, FICHIERS);
const { M, C } = L;
const lire1 = (raws, extra = {}) => M.lire(fabrique({ voies: raws, ...extra })).frise;
const vs = (raws) => lire1(raws).voies;
const ids = (xs) => xs.map((x) => x.id);
const SECTIONS = [];
const section = (id, f) => SECTIONS.push([id, f]);

section('F1', () => {
  const r = M.lire(fabrique({}));
  ok(r.ok === true && r.frise.voies.length === 6, 'schéma @1 lu, six voies', j(r).slice(0, 200));
  let lu = false;
  const hostile = { schema: 'vibeflow/cockpit-frise@2', get voies() { lu = true; throw new Error('voies lu'); } };
  const r2 = M.lire(hostile);
  ok(r2.ok === false && r2.raison === 'schema' && lu === false, 'schéma @2 : refus avant tout champ, accesseur jamais appelé', j(r2));
  eq(M.lire(null).raison, 'schema', 'valeur nulle : refus par le schéma');
  eq(M.lire({ schema: 'vibeflow/cockpit-frise@1', voies: 'x' }).raison, 'forme', 'voies non tableau : raison forme');
  const fr = lire1([voie({ id: 'g1', segments: [[NOW - 300000, NOW - 100000, 'quantique'], [NOW - 600000, NOW - 300000, 'travail']],
    evenements: [[NOW - 200000, 'humain'], [NOW - 100000, 'bizarre']] })]);
  eq(fr.voies[0].segments.map((s) => s.genre), ['travail'], 'un genre de segment inconnu est écarté');
  eq(fr.voies[0].evenements.map((e) => e.genre), ['humain'], 'un genre d\'événement inconnu est écarté');
  eq(fr.ignores, 2, 'les écartés sont comptés dans ignores');
  const tri = vs([voie({ id: 't1', segments: [[NOW - 100, NOW - 50, 'repos'], [NOW - 300, NOW - 100, 'travail']] })])[0];
  eq(tri.segments.map((s) => s.genre), ['travail', 'repos'], 'segments triés par début');
  const nul = vs([voie({ id: 'c0', cibles: null, arbre: null })])[0];
  ok(nul.cibles === null, 'cibles nul reste nul (forme inconnue), jamais {} ni tableau vide', j(nul.cibles));
  ok(nul.arbre === null, 'arbre nul reste nul (arbre principal)');
  eq(vs([voie({ arbre: 'wt-a' })])[0].arbre, 'wt-a', 'arbre nommé conservé');
  const cb = vs([voie({ cibles: { etat: 'ok', tronque: true, ecritures: [entree('a.js', NOW)], lectures: [] } })])[0].cibles;
  ok(cb.tronque === true && cb.ecritures[0].cible === 'a.js' && cb.ecritures[0].arbre === null && cb.ecritures[0].dernierMs === NOW, 'cibles lues avec arbre');
  const t = M.lire(fabrique({ tronque: true, voiesOmises: 37 })).frise;
  ok(t.tronque === true && t.voiesOmises === 37, 'tronque et voiesOmises recopiés', j([t.tronque, t.voiesOmises]));
  eq(M.omises({ tronque: true, voiesOmises: 37 }), { tronque: true, n: 37 }, 'omises : 37 voies');
  eq(M.omises({ tronque: true }), { tronque: true, n: null }, 'omises : voiesOmises absent -> n nul, sans chiffre');
  eq(M.omises({ tronque: false, voiesOmises: 5 }), { tronque: false, n: 0 }, 'omises : tronque faux -> 0');
  const vide = vs([{ id: 'x', kind: 'session' }])[0];
  ok(vide.jetons.entree === null && vide.durees.travailS === null && vide.segments.length === 0 && vide.debut === null, 'champs absents -> null, jamais 0', j(vide).slice(0, 300));
});

section('F2', () => {
  const depuis = NOW - 5400000;
  const g = git({ rangees: [rangee('c1', [], depuis / 1000 + 1, [tete('locale', 'main')])] });
  eq(M.commitsParBranche(g).branches[0].commits[0].atMs, depuis + 1000, 'commit d\'at = depuis/1000 + 1 -> atMs = depuis + 1000 (pas d\'écart de 1 000)');
});

const base3 = [
  voie({ id: 'S1', kind: 'session', debut: NOW - 3000000, segments: [[NOW - 3000000, NOW - 2000000, 'travail']] }),
  voie({ id: 'W1', parent: 'S1', dispatchA: NOW - 2500000, debut: NOW - 2500000, segments: [[NOW - 2500000, NOW - 2000000, 'travail']] }),
  voie({ id: 'W2', parent: 'S1', dispatchA: NOW - 2800000, debut: NOW - 2800000, segments: [[NOW - 2800000, NOW - 2000000, 'travail']] }),
  voie({ id: 'S2', kind: 'session', arbre: 'wt-b', debut: NOW - 4000000, segments: [[NOW - 4000000, NOW - 3900000, 'travail']] }),
  voie({ id: 'S3', kind: 'session', debut: NOW - 100000, fin: NOW, segments: [] }),
];
section('F3', () => {
  const rangs = M.arbre(vs(base3), { workers: [{ id: 'S1' }] });
  eq(ids(rangs.map((r) => ({ id: r.id }))), ['S2', 'S1', 'W2', 'W1', 'S3'], 'ordre : heure du premier segment de l\'arbre ; enfants sous leur parent par dispatchA');
  eq(rangs.map((r) => r.niveau), [0, 0, 1, 1, 0], 'niveaux');
  eq(rangs.map((r) => r.parentId), [null, null, 'S1', 'S1', null], 'parentId');
  ok(rangs[1].travailleur && rangs[1].travailleur.id === 'S1' && rangs[0].travailleur === null, 'travailleur de la régie joint par id, nul pour une voie hors who');
  ok(rangs.some((r) => r.id === 'S3' && r.voie.segments.length === 0), 'session vivante sans segment : listée');
});
section('F3b', () => {
  const rc = M.arbre(vs([voie({ id: 'A', parent: 'B' }), voie({ id: 'B', parent: 'A' })]), null);
  eq(rc.map((r) => r.id).sort(), ['A', 'B'], 'cycle de parent : chaque voie rendue une fois, sans boucle');
  const gros = Array.from({ length: 600 }, (_, i) => voie({ id: `g${i}`, parent: null }));
  eq(M.arbre(gros, null).length, 500, 'plafond de 500 voies lues (A43)');
});

section('F4', () => {
  eq(Object.keys(M.FENETRES), ['1h30', '6h', '24h'], 'exactement trois fenêtres');
  eq(Object.values(M.FENETRES), [5400000, 21600000, 86400000], 'valeurs des fenêtres');
  const depuis = NOW - 5400000;
  const d = [-1000, -60000, -5, 0, 1].map((k, i) => voie({ id: `d${i}`, debut: depuis + k }));
  eq(M.voiesTronquees(vs(d), depuis), 3, 'voiesTronquees : 3 voies sur 5 commencent avant la fenêtre');
  eq(M.voiesTronquees(vs([voie({ debut: depuis })]), depuis), 0, 'debut égal à depuis : pas tronquée');
});

const mk = (id, parent, d, o = {}) => voie({ id, parent, dispatchA: NOW - 3000000 + d, debut: NOW - 3000000 + d, segments: [[NOW - 3000000 + d, NOW - 1000000, 'travail']], ...o });
const equipe = (nM, nN) => [voie({ id: 'T', kind: 'session', depth: null }), mk('M', 'T', 1000), ...Array.from({ length: nM }, (_, i) => mk(`w${i}`, 'M', 2000 + i)),
  mk('N', 'T', 500), ...Array.from({ length: nN }, (_, i) => mk(`x${i}`, 'N', 3000 + i))];
section('F5', () => {
  const rangs = M.arbre(vs(equipe(12, 3)), null), rp = M.replier(rangs, {});
  eq(rangs.length, 18, 'fixture : 18 voies');
  ok(rp.visibles.length <= 12, 'au plus douze voies visibles', rp.visibles.length);
  ok(rp.replies.length >= 1 && rp.replies[0].managerId === 'M' && rp.replies[0].n === 12, 'le manager le plus peuplé est replié, avec son compte', j(rp.replies));
  eq(rp.visibles.length + rp.replies.reduce((a, r) => a + r.n, 0), rp.total, 'visibles + comptes repliés = total');
  eq(rp.nbReplies, rp.replies.reduce((a, r) => a + r.n, 0), 'nbReplies = somme des comptes');
  ok(rp.replies.every((r) => typeof r.auTravail === 'number'), 'auTravail est un nombre');
  const rp2 = M.replier(rangs, { deplies: new Set(['M']) });
  ok(rp2.replies.every((r) => r.managerId !== 'M') && rp2.visibles.some((r) => r.id === 'w0'), 'un manager déplié n\'est plus replié', j(rp2.replies));
  const deux = M.replier(M.arbre(vs(equipe(12, 13)), null), {});
  eq(deux.replies.map((r) => [r.managerId, r.n]), [['N', 13], ['M', 12]], 'plus peuplé d\'abord, tout ou rien');
  eq(deux.visibles.length + 25, deux.total, 'deux managers : visibles + 25 = total');
  const douze = M.replier(M.arbre(vs([voie({ id: 'T', kind: 'session', depth: null }), mk('M', 'T', 1), ...Array.from({ length: 10 }, (_, i) => mk(`w${i}`, 'M', 2 + i))]), null), {});
  ok(douze.replies.length === 0 && douze.visibles.length === 12, 'à douze voies exactement : aucun repli');
});

const D6 = NOW - 90 * MIN;
const proj = (voies, lecture) => M.projection({ depuis: D6, jusqua: NOW, largeur: 900, lecture, voies: vs(voies), largeurRepere: 40 });
const tr = (a, b) => [D6 + a * MIN, D6 + b * MIN, 'travail'];
section('F6', () => {
  const v = voie({ id: 'v', debut: D6, segments: [tr(0, 10), tr(13, 20), tr(60, 90)] });
  const h = proj([v], 'horloge');
  const r = [[0, 10], [13, 20], [60, 90]].map(([a, b]) => (h.x(D6 + b * MIN) - h.x(D6 + a * MIN)) / (b - a));
  ok(r.every((x) => Math.abs(x - r[0]) < 1e-9 && x > 0), 'Horloge : largeur / durée constante sur tous les segments', j(r));
  ok(Math.abs(h.x(D6)) < 1e-9 && Math.abs(h.x(NOW) - 900) < 1e-9 && h.reperes.length === 0, 'Horloge : de 0 à la largeur, aucun repère');
  const e = proj([v], 'evenements');
  eq(e.reperes.map((x) => x.dureeS), [180, 2400], 'Événements : silences de 3 min et de 40 min, durée vraie gardée');
  ok(e.reperes.every((x) => x.largeur === 40), 'Événements : même largeur fixe pour les deux', j(e.reperes));
  ok(Math.abs(e.x(NOW) - 900) < 1e-9 && e.x(D6 + 11 * MIN) > e.x(D6 + 10 * MIN) && e.x(D6 + 12 * MIN) <= e.x(D6 + 13 * MIN), 'Événements : x monotone, de 0 à la largeur');
  const w = (s) => proj([voie({ id: 'v', debut: D6, segments: [tr(0, 10), [D6 + 10 * MIN + s * 1000, D6 + 20 * MIN, 'travail'], tr(20, 90)] })], 'evenements').reperes.length;
  eq([w(119), w(121)], [0, 1], 'un silence de 119 s n\'est pas compressé, un de 121 s l\'est');
  const ev = voie({ id: 'v', debut: D6, segments: [tr(0, 10), tr(13, 90)], evenements: [[D6 + 11.5 * MIN, 'humain']] });
  eq(proj([ev], 'evenements').reperes.length, 0, 'un événement dans le silence le coupe : aucun repère');
  const autre = voie({ id: 'w', debut: D6, segments: [tr(9, 14)] });
  eq(proj([voie({ id: 'v', debut: D6, segments: [tr(0, 10), tr(13, 90)] }), autre], 'evenements').reperes.length, 0, 'une autre voie au travail : aucun silence');
});
section('F6b', () => {
  const depuis = Date.UTC(2026, 9, 24, 22, 30), jusqua = depuis + 6 * 3600000;
  const p = M.projection({ depuis, jusqua, largeur: 600, lecture: 'horloge', voies: [], largeurRepere: 40 });
  ok(new Date(Date.UTC(2026, 9, 25, 0, 30)).getHours() === 2, 'TZ=Europe/Paris effective (heure d\'été à 00:30 UTC)');
  eq(p.graduations.map((g) => g.libelle), ['01:00', '02:00', '02:00', '03:00', '04:00', '05:00'], 'une graduation 02:00 par passage, aucune décalée d\'une heure');
  eq(p.graduations.slice(1).map((g, i) => g.ms - p.graduations[i].ms), [3600000, 3600000, 3600000, 3600000, 3600000], 'pas fixe en millisecondes');
});

const B = NOW - 3600000;
section('F7', () => {
  const v = vs([voie({ id: 'e', debut: B, fin: B + 30 * MIN, segments: [[B, B + 10 * MIN, 'travail'], [B + 10 * MIN, B + 20 * MIN, 'silence'], [B + 20 * MIN, B + 30 * MIN, 'travail']] })])[0];
  const E = (t) => M.etatA(v, t);
  eq([E(B - 1), E(B), E(B + 10 * MIN - 1), E(B + 10 * MIN), E(B + 15 * MIN), E(B + 20 * MIN), E(B + 30 * MIN - 1)],
    ['pas-lance', 'travail', 'travail', 'silence', 'silence', 'travail', 'travail'], 'bornes : début inclus, fin exclue, silence, avant le début');
  const f = vs([voie({ id: 'f', debut: B, fin: B + 30 * MIN, fini: true, segments: [[B, B + 30 * MIN, 'travail']] })])[0];
  eq([M.etatA(f, B + 30 * MIN), M.etatA(f, B + 40 * MIN)], ['termine', 'termine'], 'voie finie : terminé à partir de fin');
  eq(M.etatA(vs([voie({ id: 'r', debut: B, segments: [] })])[0], B + 5 * MIN), 'repos', 'sans segment mais vivante : repos');
  const p = vs([voie({ id: 'p', debut: B, fin: B + 30 * MIN, segments: [[B, B + 30 * MIN, 'travail']], attend: true, jusqua: NOW })])[0];
  eq([M.etatA(p, B + 30 * MIN - 1), M.etatA(p, B + 30 * MIN), M.etatA(p, B + 40 * MIN)], ['travail', 'attend-humain', 'attend-humain'],
    'queue attend-humain (A43) : jamais travail ni repos, à fin exact attend-humain');
  eq(p.segments.map((s) => s.genre), ['travail', 'attend-humain'], 'le dernier segment persisté n\'est pas retypé');
});

section('F8', () => {
  const t = NOW - 30 * MIN;
  const pv = (id, noeud, segs, o = {}) => voie({ id, rattachement: { dag: 'm1.md', noeud, source: 'registre' }, debut: t - 20 * MIN, fin: t + 20 * MIN, segments: segs, ...o });
  const tout = [[t - 20 * MIN, t + 20 * MIN, 'travail']];
  const voies = vs([pv('p1', 'n1', tout), pv('p2', 'n2', [[t - 20 * MIN, t - 5 * MIN, 'travail'], [t - 5 * MIN, t + 20 * MIN, 'repos']]),
    pv('p3', 'n3', [[t - 20 * MIN, t - 5 * MIN, 'travail'], [t - 5 * MIN, NOW, 'attend-humain']], { fin: t - 5 * MIN }), pv('p4', 'n4', [[t - 20 * MIN, t + 20 * MIN, 'attend-agents']]),
    voie({ id: 'mg', rattachement: { dag: 'm1.md', noeud: null, source: 'enfants' }, debut: t - 20 * MIN, segments: tout }),
    pv('pl', 'n5', tout, { debut: t + 10 * MIN }), pv('te', 'n6', [[t - 30 * MIN, t - 10 * MIN, 'travail']], { debut: t - 30 * MIN, fin: t - 10 * MIN, fini: true }),
    pv('si', 'n7', [[t - 20 * MIN, t + 20 * MIN, 'silence']])]);
  const r = M.noeudsPortes(voies, t, quiMissions());
  eq(r.portes.map((p) => [p.noeud, p.etat, p.agentId, p.dag]), [['n1', 'travail', 'p1', 'm1.md'], ['n2', 'repos', 'p2', 'm1.md'], ['n3', 'attend-humain', 'p3', 'm1.md'],
    ['n4', 'attend-agents', 'p4', 'm1.md']], 'état de la voie porteuse : travail, repos, vous attend, attend ses agents ; manager enfants, pas-lancé, terminé, silence : aucune ligne');
  ok(r.portes.every((p) => ['travail', 'attend-humain', 'attend-agents', 'repos'].includes(p.etat) && !/ready|blocked|porte-/.test(p.etat)), 'jamais ready, blocked ni porte-*');
  const deux = M.noeudsPortes(voies.filter((v) => v.id === 'p1' || v.id === 'p2'), t, quiMissions());
  eq(deux.sansAgent, 6, 'huit nœuds dont deux portés -> 6 sans agent');
  eq(M.noeudsPortes(voies, t, [quiMissions()[1]]).sansAgent, null, 'noeuds absent de la mission -> null, jamais 0');
  eq(M.noeudsPortes(voies, t, undefined).sansAgent, null, 'aucune mission -> null');
});

const brut9 = (id, o) => voie({ id, ...o, jetons: { entree: o.e, sortie: o.s, cacheLu: o.cl, cacheCree: o.cc, contexteMax: 0, contexteDernier: 0 },
  durees: { travailS: o.tr, attenteHumainS: o.ah, attenteAgentsS: 0, reposS: 0, silenceS: 0 } });
const rat = (dag, noeud, source = 'registre') => ({ dag, noeud, source });
const raw9 = () => [
  brut9('S1', { kind: 'session', role: null, depth: null, e: 100, s: 10, cl: 1000, cc: 50, tr: 300, ah: 60 }),
  brut9('Mg', { parent: 'S1', depth: 1, rattachement: rat('m1.md', null, 'enfants'), e: 200, s: 20, cl: 2000, cc: 100, tr: 100, ah: 10 }),
  brut9('W1', { parent: 'Mg', depth: 2, rattachement: rat('m1.md', 'n1'), e: 300, s: 30, cl: 3000, cc: 150, tr: 200, ah: 5 }),
  brut9('W2', { parent: 'Mg', depth: 2, rattachement: rat('m1.md', 'n2'), e: 400, s: 40, cl: 4000, cc: 200, tr: 50, ah: 0 }),
  brut9('W3', { parent: 'S1', depth: 1, rattachement: rat('m2.md', 'x'), e: 500, s: 50, cl: 5000, cc: 250, tr: 70, ah: 20 }),
  brut9('W4', { parent: 'S1', depth: 1, e: 600, s: 60, cl: 6000, cc: 300, tr: 80, ah: 30 }),
];
section('F9', () => {
  const raw = raw9(), voies = vs(raw);
  const COL = { travailS: (v) => v.durees.travailS, attenteHumainS: (v) => v.durees.attenteHumainS, entree: (v) => v.jetons.entree, sortie: (v) => v.jetons.sortie,
    cacheLu: (v) => v.jetons.cacheLu, cacheCree: (v) => v.jetons.cacheCree };
  const cols = Object.keys(COL), tot = Object.fromEntries(cols.map((k) => [k, raw.reduce((a, v) => a + COL[k](v), 0)]));
  const opt = { missions: quiMissions(), phases: quiPhases(), fenetreLibelle: 'dernières 6 h', tronque: false };
  const R = {};
  for (const par of ['agent', 'mission', 'etage']) {
    const r = R[par] = M.agreger(voies, par, opt);
    const bon = cols.every((k) => r.lignes.reduce((a, l) => a + l[k], 0) + (par === 'mission' ? r.horsMission[k] : 0) === tot[k] && r.total[k] === tot[k]);
    ok(bon, `${par} : somme des six colonnes (lignes${par === 'mission' ? ' + hors mission' : ''}) = total = somme des voies`, j(r.total));
  }
  const m1 = R.mission.lignes.find((l) => l.cle === 'm1.md'), m2 = R.mission.lignes.find((l) => l.cle === 'm2.md');
  ok(m1 && m1.travailS === 350, 'le manager enfants est compté dans sa mission (100 + 200 + 50)', j(m1));
  ok(m1.phases.length === 1 && m1.phases[0].cle === '74' && m1.phases[0].travailS === 350, 'phase de la mission jointe par phaseKey', j(m1.phases));
  ok(m2 && m2.travailS === 70 && m2.phases.length === 0, 'phaseKey nul : mission comptée, sans ligne de phase', j(m2));
  eq(R.mission.horsMission.travailS, 380, 'hors mission à part (tête + agent non rattaché), jamais répartie');
  const et = R.etage.lignes;
  eq(et.map((l) => [l.cle, l.travailS]), [['tete', 300], ['manager', 100], ['worker', 400]], 'étages : tête, manager, worker');
  const E = M.etages(voies);
  eq(['S1', 'Mg', 'W1', 'W3'].map((i) => E.get(i)), ['tete', 'manager', 'worker', 'worker'], 'étage par les enfants, jamais par la profondeur (Mg et W3 à la même profondeur)');
  const wA = R.agent.lignes.find((l) => l.cle === 'Mg');
  eq(wA.enfants, ['W1', 'W2'], 'une ligne d\'agent de manager porte ses enfants');
  ok(R.agent.fenetreDurees === 'dernières 6 h' && R.agent.fenetreJetons === 'dernières 24 h' && R.agent.fenetreDurees !== R.agent.fenetreJetons, 'deux libellés de fenêtre distincts', j([R.agent.fenetreDurees, R.agent.fenetreJetons]));
  ok(R.agent.incomplet === false && M.agreger(voies, 'agent', { ...opt, tronque: true }).incomplet === true, 'incomplet recopié de tronque');
  eq(M.agreger(voies, 'agent', { ...opt, tronque: true }).total, R.agent.total, 'tronque ne change aucun nombre');
  eq(R.agent.lignes.reduce((a, l) => a + l.travailS, 0), tot.travailS, 'aucune durée recoupée : somme des durees.travailS des voies');
  const inc = M.agreger(vs([raw[0], voie({ id: 'zz', jetons: null })]), 'agent', opt);
  ok(inc.inconnus === 1 && inc.lignes.find((l) => l.cle === 'zz').entree === null && inc.total.entree === 100, 'champ absent : ligne nulle, exclue du total, comptée dans inconnus', j([inc.inconnus, inc.total]));
});

section('F10', () => {
  const INTERDITS = [[/usage/, 'usage'], [/fetch/, 'fetch'], [/EventSource/, 'EventSource'], [/XMLHttpRequest/, 'XMLHttpRequest'], [/\/api\/vf\/transcript/, '/api/vf/transcript'],
    [/€/, '€'], [/\$\s?\d|\d\s?\$/, '$ monétaire'], [/tarif/i, 'tarif'], [/ready|blocked/, 'ready|blocked']];
  for (const n of FICHIERS) {
    const f = path.join(DIR, n);
    const t = fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : null;
    ok(t !== null, `${n} présent`);
    if (t !== null) for (const [re, nom] of INTERDITS) ok(!re.test(t), `a) ${n} : aucune occurrence de ${nom}`);
  }
  ok(Array.isArray(M.CHAMPS_LUS) && ['id', 'segments', 'cibles.tronque', 'jetons.entree', 'rattachement.source', 'durees.travailS'].every((c) => M.CHAMPS_LUS.includes(c)), 'CHAMPS_LUS : chemins de champs lus');
  neutre('b) CHAMPS_LUS ⊆ champs déclarés par le bloc vibeflow/cockpit-frise@1 de vf-cockpit-interface.json : bloc posé par 79-13, comparaison à écrire à la reprise');
});

section('F11', () => {
  const v = (id, a, b) => voie({ id, debut: D6 + a * MIN, segments: [[D6 + a * MIN, D6 + b * MIN, 'travail']] });
  const c = M.courbe(vs([v('a', 0, 20), v('b', 10, 30), v('c', 40, 50)]), D6, D6 + 60 * MIN);
  ok(c.pic === 2 && c.echelle === 4, 'deux voies qui se chevauchent : pic 2, échelle 4', j([c.pic, c.echelle]));
  const cont = c.pas.every((p, i) => (i === 0 ? p.debut === D6 : p.debut === c.pas[i - 1].fin)) && c.pas[c.pas.length - 1].fin === D6 + 60 * MIN;
  ok(cont, 'escalier sans trou ni recouvrement', j(c.pas));
  ok(c.pas.every((p, i) => i === 0 || p.n !== c.pas[i - 1].n), 'pas voisins de hauteurs différentes');
  eq(c.pas.map((p) => p.n), [1, 2, 1, 0, 1, 0], 'hauteurs de l\'escalier');
  const cinq = M.courbe(vs(['a', 'b', 'c', 'd', 'e'].map((i) => v(i, 5, 25))), D6, D6 + 60 * MIN);
  ok(cinq.pic === 5 && cinq.echelle === 5, 'cinq au travail : échelle 5', j([cinq.pic, cinq.echelle]));
});

section('F12', () => {
  const depuis = NOW - 5400000, s = (ms) => ms / 1000;
  const L1 = (tronque, rangees) => git({ rangees, tronque });
  const g = git({ rangees: [
    rangee('m3', ['m2'], s(NOW) - 600, [tete('locale', 'main')]), rangee('f3', ['f2'], s(NOW) - 650, [tete('distante', 'origin/feat')]),
    rangee('f2', ['f1'], s(NOW) - 700, [tete('locale', 'feat')]), rangee('m2', ['m1'], s(NOW) - 900, [tete('locale', 'dup')]),
    rangee('f1', ['m2'], s(NOW) - 1000), rangee('m1', [], s(NOW) - 1200), rangee('o1', ['zz'], s(NOW) - 1300)] });
  const r = M.commitsParBranche(g);
  eq(r.branches.map((b) => [b.nom, b.commits.map((c) => c.h)]), [['main', ['m3', 'm2', 'm1']], ['feat', ['f2', 'f1']], ['origin/feat', ['f3']]],
    'a) la chaîne de la base d\'abord (dup n\'a rien), puis les locales, puis les distantes ; commun locale/distante -> locale');
  eq([r.autres.n, r.autres.commits.map((c) => c.h)], [1, ['o1']], 'b) commit atteint par aucune marche -> autres, avec son compte');
  eq(M.commitsParBranche(L1(false, [rangee('a', [], s(NOW), [tete('locale', 'main')])])).autres.n, 0, 'b) autres.n vaut 0 quand rien');
  const c1 = (tronque, plusAncien) => M.couverture(L1(tronque, [rangee('a', ['b'], s(depuis) + 1200, [tete('locale', 'main')]), rangee('b', [], s(depuis) + plusAncien)]), depuis);
  eq(c1(true, 600), { incomplet: true, depuisMs: depuis + 600000 }, 'c) tronque et plus ancien dans la fenêtre : incomplet, depuisMs = cet instant');
  eq(c1(false, 600).incomplet, false, 'c) tronque faux : complet');
  eq(c1(true, -600).incomplet, false, 'c) tronque mais plus ancien avant la fenêtre, aucun parent non lu : complet');
  const trou = (extra) => M.couverture(L1(true, [rangee('old', [], s(depuis) - 3600), rangee('a', ['old'], s(depuis) + 100, [tete('locale', 'main')]), rangee('c', ['absent'], s(depuis) + 900), ...extra]), depuis);
  eq(trou([]), { incomplet: true, depuisMs: depuis + 900000 }, 'd) trou topologique : plus ancien avant la fenêtre mais une rangée à parent non lu -> incomplet');
  eq(trou([rangee('c2', ['absent2'], s(depuis) + 1500)]).depuisMs, depuis + 1500000, 'd) deux rangées à parent non lu : la frontière est la plus récente');
  eq(M.couverture(L1(true, []), depuis), { incomplet: false, depuisMs: null }, 'aucune rangée : complet, sans instant');
});

section('F13', () => {
  eq([M.delta(5400000), M.delta(86400000), M.delta(21600000)], [120000, 480000, 120000], 'δ = max(2 min, fenêtre / 180)');
  const t = NOW - 30 * MIN, d = 120000, seg = (a, b, g = 'travail') => [[a, b, g]];
  const voies = vs([voie({ id: 'vA', segments: seg(t - d - 10 * MIN, t - d) }), voie({ id: 'vB', segments: seg(t + d, t + d + MIN) }),
    voie({ id: 'vC', segments: seg(t - 5 * MIN, t + 5 * MIN, 'repos') }), voie({ id: 'vD', segments: seg(t - MIN, t + MIN) })]);
  eq(ids(M.voiesAutour(voies, t, d)), ['vB', 'vD'], 'fin exclue à t - δ, début inclus à t + δ, repos seul exclu, ordre de l\'entrée');
  const e = vs([voie({ id: 'vE', segments: seg(t - 20 * MIN, t - 6 * MIN) })]);
  eq([M.voiesAutour(e, t, M.delta(86400000)).length, M.voiesAutour(e, t, M.delta(21600000)).length], [1, 0], 'sur 24 h la plage est ± 8 min (pas ± 2)');
});

const gel = (o) => { if (o && typeof o === 'object' && !Object.isFrozen(o)) { Object.freeze(o); for (const k of Object.keys(o)) gel(o[k]); } return o; };
section('F14', () => {
  const t = NOW - 30 * MIN, d = 120000, lo = t - d, hi = t + d, trav = [[t - 10 * MIN, t + 10 * MIN, 'travail']];
  const W = (id, ecr, o = {}) => voie({ id, debut: t - 10 * MIN, fin: t + 10 * MIN, segments: trav, cibles: { etat: 'ok', tronque: false, ecritures: ecr, lectures: [] }, ...o });
  const FA = (voies, fils = new Map()) => M.fichiersA(t, d, vs(voies), fils);
  const cibles = (r) => r.ecrits.map((x) => [x.arbre, x.cible]);
  const a1 = FA([W('A', [entree('in.js', t), entree('lo.js', lo), entree('hi.js', hi), entree('old.js', lo - 1)])]);
  eq([cibles(a1), a1.aLire, a1.nonLues, a1.partiel, a1.plus], [[[null, 'in.js'], [null, 'lo.js'], [null, 'hi.js']], [], [], false, false], 'a) dernierMs dans [t - δ, t + δ] : écrit certain ; avant : non écrit certain, aucun fil demandé');
  eq([FA([W('B', [entree('new.js', hi + 1)])]).ecrits, FA([W('B', [entree('new.js', hi + 1)])]).aLire], [[], ['B']], 'a) dernierMs après t + δ : incertain, la voie est à lire');
  const X = voie({ id: 'X', debut: t - 10 * MIN, fin: t + 10 * MIN, segments: trav, cibles: null });
  const fx = (elements, tronque = false) => new Map([['X', { fil: elements, tronque }]]);
  const b1 = FA([X], fx([element(t - 600000, { n: 3 }), { t: t + 600000, genre: 'message' }]));
  eq([cibles(b1), b1.aLire, b1.nonLues], [[[null, 'a.js']], [], []], 'b) entrée regroupée : couvre de son t jusqu\'à l\'élément suivant, couvre t');
  eq(cibles(FA([X], fx([element(t - 600000, { n: 3 }), { t: t - 500000, genre: 'message' }]))), [], 'b) élément suivant avant t - δ : absent');
  eq(cibles(FA([X], fx([element(t - 600000, { n: 1 }), { t: t + 600000, genre: 'message' }]))), [], 'b) une entrée simple n\'est qu\'un instant');
  const c1 = FA([X], fx([element(lo + 1000, { cible: 'z.js' })], true)), c2 = FA([X], fx([element(lo + 1000, { cible: 'z.js' })], false));
  eq([c1.nonLues, c1.partiel, cibles(c1)], [['X'], true, [[null, 'z.js']]], 'c) fil trop court (premier élément après t - δ, tronque) : nonLues, partiel, jamais une liste muette');
  eq([c2.nonLues, c2.partiel], [[], false], 'c) même fil sans tronque : pas nonLues');
  const dY = FA([W('Y', [], { cibles: { etat: 'ok', tronque: true, ecritures: [], lectures: [] } })]), dZ = FA([X]);
  eq([dY.aLire, dY.plus, dZ.aLire, dZ.plus], [['Y'], true, ['X'], false], 'd) cibles.tronque : à lire et plus ; cibles nul : à lire, sans plus');
  const e1 = FA([W('E', [entree('a.js', t), entree('a.js', t, { arbre: 'wt-1' }), entree('un fichier hors du lab', t)]), W('F', [entree('a.js', t)])]);
  eq(cibles(e1), [[null, 'a.js'], ['wt-1', 'a.js']], 'e) couple (arbre, cible) : deux entrées, arbre nul rendu tel quel, « hors du lab » exclu, dédoublonné entre voies');
  const suf = FA([X], fx([element(t, { cible: 'b.js (worktree wt-9)' })]));
  eq(cibles(suf), [['wt-9', 'b.js']], 'e) cible du fil « chemin (worktree nom) » : arbre = nom');
  const entrees = gel([W('G', [entree('in.js', t), entree('new.js', hi + 5)])].map((v) => vs([v])[0])), fils = gel(fx([element(t, { cible: 'q.js' })]));
  const avant = j([entrees, [...fils]]);
  let leve = null; try { M.fichiersA(t, d, entrees, fils); } catch (e) { leve = e.message; }
  ok(leve === null && j([entrees, [...fils]]) === avant, 'f) fonction pure : entrées gelées, rien de modifié', leve);
});

section('F15', () => {
  for (const n of FICHIERS) {
    const t = fs.readFileSync(path.join(DIR, n), 'utf8'), lignes = t.split('\n'), nb = t.endsWith('\n') ? lignes.length - 1 : lignes.length;
    ok(nb <= 299, `${n} : ${nb} lignes (au plus 299)`);
    ok(lignes.filter((l) => [...l.replace(/\r$/, '')].length > 160).length === 0, `${n} : aucune ligne de plus de 160 colonnes`);
    ok(t.startsWith('// VibeFlow ('), `${n} : en-tête « // VibeFlow ( »`);
  }
  const PROPRES = ['SCHEMA', 'CHAMPS_LUS', 'FENETRES', 'SEUIL_REPLI', 'SILENCE_MS', 'lire', 'omises', 'arbre', 'replier', 'projection', 'coalescer', 'courbe', 'voiesTronquees'];
  const CALCULS = ['etatA', 'noeudsPortes', 'etages', 'agreger', 'delta', 'voiesAutour', 'fichiersA', 'commitsParBranche', 'couverture', 'fmtJetons', 'fmtDuree', 'fmtHeure', 'fmtNombre'];
  eq(Object.keys(M).sort(), [...PROPRES, ...CALCULS].sort(), 'exports du modèle : exactement les noms promis (propres + calculs)');
  eq(Object.keys(C).sort(), [...CALCULS].sort(), 'exports des calculs : exactement les noms promis');
  const seul = charger(DIR, [FICHIERS[0]]);
  ok(seul.C && !seul.erreur && seul.M === undefined && seul.C.lire === undefined, 'calculs chargé seul : ne lève pas, n\'expose pas lire');
  const co = M.coalescer(vs([voie({ id: 'k', segments: [[0, 1000, 'travail'], [1010, 2000, 'travail'], [5000, 6000, 'travail'], [6005, 7000, 'repos']] })])[0].segments, 100);
  eq(co.map((s) => [s.debut, s.fin, s.genre]), [[0, 2000, 'travail'], [5000, 6000, 'travail'], [6005, 7000, 'repos']], 'coalescer : fusionne les voisins de même genre à moins d\'un pixel');
});

section('FMT', () => {
  eq([M.fmtJetons(842), M.fmtJetons(12400), M.fmtJetons(168000), M.fmtJetons(1800000)], ['842', `12,4${NB}k`, `168${NB}k`, `1,8${NB}M`], 'fmtJetons');
  eq([M.fmtDuree(45), M.fmtDuree(720), M.fmtDuree(7500), M.fmtDuree(8040)], [`45${NB}s`, `12${NB}min`, `2${NB}h 05`, `2${NB}h 14`], 'fmtDuree');
  eq(M.fmtNombre(1204), `1${NB}204`, 'fmtNombre : milliers en espace insécable');
  eq([M.fmtJetons(null), M.fmtDuree(null), M.fmtNombre(undefined), M.fmtHeure(null)], [null, null, null, null], 'valeur absente -> null');
  const t = new Date(2026, 10, 13, 14, 32, 10).getTime();
  eq([M.fmtHeure(t), M.fmtHeure(t, { secondes: true }), M.fmtHeure(t, { phrase: true })], ['14:32', '14:32:10', `14${NB}h 32`], 'fmtHeure : axe, fil, phrase');
});

const absent = L.absent || L.erreur || !M || !C;
sec = 'F0';
ok(!absent, absent ? `modules chargés : module absent ou illisible (${L.absent || L.erreur || 'export manquant'})` : 'modules chargés dans l\'ordre lexical (calculs puis modèle)');
for (const [id, f] of SECTIONS) { // jouées aussi sans module : chaque sonde doit rougir d'elle-même (contrôle positif de F0)
  sec = id; const avant = pass + fail;
  try { f(); } catch (e) { ok(false, absent ? 'module absent : exception levée' : 'exception levée', String(e && e.message || e)); }
  if (pass + fail === avant) ok(false, 'aucune assertion exécutée');
}
dire(`SONDES pass=${pass} fail=${fail} neutres=${neutres}`);
process.exit(fail ? 1 : 0);
JS

SECTIONS="F1 F2 F3 F3b F4 F5 F6 F6b F7 F8 F9 F10 F11 F12 F13 F14 F15 FMT"

# --- F0 : contrôle positif, dossier VIDE : chaque section doit rougir (sinon une sonde reste verte sans module) ---
TZ=Europe/Paris node "$AUX/sondes.mjs" "$VIDE" "$HERE_T/frise-fabrique.mjs" > "$WORK/vide.out" 2>&1
VERTES=""
for s in $SECTIONS; do
  f=$(grep -cF "❌ FAIL — $s :" "$WORK/vide.out"); p=$(grep -cF "✅ PASS — $s :" "$WORK/vide.out")
  { [ "$f" -ge 1 ] && [ "$p" -eq 0 ]; } || VERTES="$VERTES $s"
done
assert_eq "F0 : sans module, chaque section F1 à F15 et FMT rougit (une sonde reste verte sans module :${VERTES:- aucune})" "$VERTES" ""

# --- sections sur les modules du dépôt ---
TZ=Europe/Paris node "$AUX/sondes.mjs" "$UI" "$HERE_T/frise-fabrique.mjs" > "$WORK/reel.out" 2>&1
grep -v '^SONDES ' "$WORK/reel.out"
PASS=$((PASS + $(grep -c '✅ PASS' "$WORK/reel.out")))
FAIL=$((FAIL + $(grep -c '❌ FAIL' "$WORK/reel.out")))
NEUTRES=$(grep -c '⊘ NON vérifiée' "$WORK/reel.out")
[ -s "$WORK/reel.out" ] || { echo "  ❌ FAIL — F0 : aucune sortie des sondes"; FAIL=$((FAIL+1)); }

echo
echo "=== $PASS PASS, $FAIL FAIL ==="
[ "$NEUTRES" -gt 0 ] && echo "⊘ $NEUTRES sonde(s) NON vérifiée(s), non comptée(s) comme réussie(s) : F10 b) (bloc cockpit-frise@1 du contrat, 79-13)"
[ "$FAIL" -eq 0 ]
