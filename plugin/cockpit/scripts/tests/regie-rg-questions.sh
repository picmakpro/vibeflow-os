# regie-rg-questions.sh — fragment du plan 73-11, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : les questions en attente des cadrages dans « À vous » (REGI-17, P73-D-37).
#   RG17_ordre (ordre de chargement, sortie assemblée) · RG17_lecture (lecture fermée par défaut, rangs, mots) · RG17_reel (sources, fixture F2, mutants de la lecture)
#   RG17_page (lignes, replis, bilan, absence, Échap, redessin, recherche : vm de la page) · RG17_reelpage (F2 dans le DOM, mutant HTML) · RG17_chrome (navigateur) · RG17_titre (titre et pastille).
# Mutants (régime allégé) : un par garde de forme ou de non-fuite (état exact, chemin absolu, lien forgé, balisage). Les harnais : vm-regie-questions.mjs, chrome-regie-questions.mjs.
# Fixtures : F1 (forme de C76-Q2, noms inventés, fichier relatif, chemin absolu sentinelle construit à l'exécution) et F2 (traduction à la main des sections « À Samuel » de 73-CONTEXT.md et
# de 76-CONTEXT.md lues le 2026-11-14 : elle n'est PAS produite par la lecture de la 76 ; à rejouer par lecture réelle quand 76-09 sera fusionné).

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }
NB="$(printf '\302\240')"

q_fixtures() {
  [ -f "$AUX/f1.json" ] && return 0
  cat > "$AUX/mkfix.mjs" <<'JS'
// mkfix.mjs <dossier> : écrit f1.json, f2.json et sentinelle.txt (textes hostiles et chemin absolu construits ici, jamais écrits en clair dans le fragment)
import fs from 'node:fs';
const d = process.argv[2], f = '.planning/workstreams/atelier/phases/VFDO-90-exemple/90-CONTEXT.md', SENT = '/' + 'Users/' + 'user/' + 'secret-sentinelle/' + 'x.md';
const H = '<' + 'img src=x onerror="window.__pwn=1">', opt = (a, b) => [{ cle: 'a', texte: a }, { cle: 'b', texte: b }];
const e = (id, etat, o = {}) => ({ id, phase: 'ph-90', ws: 'atelier', fichier: f, ligne: 10, titre: 'T ' + id, question: 'Q ' + id, options: opt('un', 'deux'), recommandation: 'a', bloque: [],
  etat, tranchee: null, appliquee: null, defauts: [], ...o });
const app = { canal: 'message session principale', date: '2026-11-08', option: 'a', decision: 'P90-D-03' };
const F1 = { liste: [
  e('P90-Q-01', 'en-attente', { titre: "Choix du format d'export", question: 'Quel format sortir ?', options: opt('CSV', 'JSON'), bloque: [{ type: 'plan', id: '90-02' }, { type: 'phase', n: '91' }] }),
  e('P90-Q-02', 'en-attente', { titre: H, question: H, options: [{ cle: 'a', texte: H }, { cle: 'b', texte: 'sobre' }], recommandation: null, bloque: [] }),
  e('P90-Q-03', 'appliquee', { titre: 'Garder le repli', question: 'Garder le repli fermé ?', options: opt('oui', 'non'), appliquee: app }),
  e('P90-Q-04', 'tranchee', { tranchee: { canal: 'AskUserQuestion session principale', date: '2026-11-11', option: 'b', citation: 'ok' } }),
  e('P90-Q-05', 'a-verifier', { question: 'Citation à revoir ?', defauts: ['citation-incoherente'] }),
  e('P90-Q-06', 'a-verifier', { question: 'Décision à retrouver ?', appliquee: app, defauts: ['decision-introuvable'] }),
  { id: 'P90-Q-07', etat: 'mal-formee', phase: 'ph-90', fichier: f, ligne: 88, defauts: ['champ-manquant', 'bloque-invalide'] },
  { id: 'P90-Q-09', etat: 'mal-formee', phase: 'ph-90', fichier: SENT, ligne: 5, defauts: ['etat-absent'] },
  e('P91-Q-01', 'en-attente', { phase: 'ph-91@atelier', titre: 'Choix de la liste', question: 'Quelle liste garder ?', recommandation: 'b', bloque: [{ type: 'phase', n: '92' }] }),
  e('P91-Q-02', 'zzz', { phase: 'ph-91@atelier' }),
  e('P91-Q-03', 'en-attente', { phase: 'ph-91@atelier', options: 'pas une liste' }),
], bilan: { enAttente: 3, appliquees: 1, tranchees: 1, aVerifier: 2, malFormees: 2, nonStructurees: 2, registresLus: 3 }, tronque: true };
// F2 : sections « À Samuel » réelles (lues le 2026-11-14) : aucune question n'y attend plus (P73-Q-01 tranchée « sans objet » le 2026-11-13)
const g = (id, ph, etat, o) => e(id, etat, { phase: ph, ws: 'fiabilite', ...o });
const ap = (dec) => ({ canal: 'message session principale', date: '2026-11-08', option: 'a', decision: dec }), tr = { canal: 'AskUserQuestion session principale', date: '2026-11-11', option: 'b', citation: 'ok' };
const F2 = { liste: [
  g('P73-Q-01', 'ph-73', 'tranchee', { tranchee: tr }), g('P73-Q-02', 'ph-73', 'appliquee', { appliquee: ap('P73-D-06'), titre: "Question de l'assistant restée sans réponse" }),
  g('P73-Q-03', 'ph-73', 'tranchee', { tranchee: tr }), g('P73-Q-04', 'ph-73', 'appliquee', { appliquee: ap('P73-D-15'), titre: 'Notification du système' }),
  g('P76-Q-01', 'ph-76', 'tranchee', { tranchee: tr }), g('P76-Q-02', 'ph-76', 'tranchee', { tranchee: tr }), g('P76-Q-03', 'ph-76', 'appliquee', { appliquee: ap('P76-D-31'), titre: 'Poids ajouté à la page Projet' }),
], bilan: { enAttente: 0, appliquees: 3, tranchees: 4, aVerifier: 0, malFormees: 0, nonStructurees: 0, registresLus: 2 }, tronque: false };
fs.writeFileSync(d + '/f1.json', JSON.stringify(F1)); fs.writeFileSync(d + '/f2.json', JSON.stringify(F2)); fs.writeFileSync(d + '/sentinelle.txt', SENT);
JS
  node "$AUX/mkfix.mjs" "$AUX"
  cat > "$AUX/mksc.mjs" <<'JS'
// mksc.mjs <f1> <f2> <sortie> <expression JS> : écrit le scénario JSON ; l'expression voit F1, F2, E (entrée), L (liste)
import fs from 'node:fs';
const [, , f1, f2, out, expr] = process.argv;
const F1 = JSON.parse(fs.readFileSync(f1, 'utf8')), F2 = JSON.parse(fs.readFileSync(f2, 'utf8'));
const E = (id, o = {}) => ({ id, phase: 'phase' in o ? o.phase : 'ph-' + /^P([0-9.]+)/.exec(id)[1], ws: 'atelier', fichier: '.planning/phases/x/x-CONTEXT.md', ligne: 3, titre: 'T ' + id, question: 'Q ' + id,
  options: [{ cle: 'a', texte: 'un' }, { cle: 'b', texte: 'deux' }], recommandation: 'a', bloque: [], etat: 'en-attente', tranchee: null, appliquee: null, defauts: [], ...o });
const L = (...es) => ({ liste: es, bilan: {}, tronque: false });
const F1PLUS = { ...F1, liste: [...F1.liste, E('P90-Q-08', { etat: 'appliquee', question: 'Q8', appliquee: { canal: 'c', date: '2026-11-08', option: 'a', decision: 'P90-D-08' } })] };
const F1SANS = { ...F1, liste: F1.liste.filter((x) => x.id !== 'P90-Q-01') };
fs.writeFileSync(out, JSON.stringify(new Function('F1', 'F2', 'E', 'L', 'F1PLUS', 'F1SANS', 'return (' + expr + ')')(F1, F2, E, L, F1PLUS, F1SANS)));
JS
}
# q_sc <expression> [dossier ui] : écrit le scénario, joue vm-regie-questions.mjs, rend le chemin de la sortie
q_sc() { local f="$WORK/q-$$-$RANDOM.sc.json" o; q_fixtures; o="${f%.sc.json}.out.json"
  node "$AUX/mksc.mjs" "$AUX/f1.json" "$AUX/f2.json" "$f" "$1" > "$o" 2>&1 || { printf '%s' "$o"; return; }
  node "$TESTS_DIR/vm-regie-questions.mjs" "${2:-$UI}" "$f" > "$o" 2>&1; printf '%s' "$o"; }
q_g() { local r; r="$(G "$1" 'j.erreur ? "ERR:" + j.erreur : (function(){ try { return ('"$2"'); } catch (e) { return "ERR:" + e.message; } })()' 2>/dev/null)"; printf '%s' "${r:-ERR:sortie vide}"; }
q_ok() { assert_eq "$1" "$(q_g "$2" "$3")" "$4"; }
Q_WHO='{"workers":[{"kind":"session","id":"s0000000-aaaa-bbbb-cccc-111111111111","etat":"attend","titre":"Atelier alpha","tree":".","branch":"feat/x","ageS":120,"dureeS":900}]}'
Q_AVOUS='section[data-vf-section=\"a-vous\"]'
# q_page <questions JS ou vide> <étapes JSON> [membres du scénario de page] [dossier ui] : la page Équipe en vm avec la valeur donnée pour meta.vf.questions
q_page() { local q="${1:-undefined}"; q_sc '{mode:"page", questions:'"$q"', page:{onglet:"equipe", source:"live", who:'"$Q_WHO"', lock:null'"${3:+,$3}"', etapes:'"$2"'}}' "${4:-$UI}"; }

rg_RG17_ordre() {
  cat > "$AUX/ordre-q.mjs" <<'JS'
// ordre-q.mjs <html> : « ok » si lecture, rendu et source des questions existent une fois chacun, dans cet ordre, après 72-vf-regie-pied.js et avant 72-vf-regie-rendu.js, 72-vf-regie-source.js et 90-vf-titre.js
import fs from 'node:fs';
let t; try { t = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('illisible'); process.exit(0); }
const m = (n) => `/* ui/${n} */`, n = (s) => t.split(s).length - 1, at = (s) => t.indexOf(s), pb = [];
const q = ['72-vf-regie-questions-lecture.js', '72-vf-regie-questions-rendu.js', '72-vf-regie-questions-source.js'];
for (const x of q) if (n(m(x)) !== 1) pb.push(`${x} ×${n(m(x))}`);
if (!(at(m(q[0])) < at(m(q[1])) && at(m(q[1])) < at(m(q[2])))) pb.push('ordre');
if (!(at(m('72-vf-regie-pied.js')) >= 0 && at(m(q[0])) > at(m('72-vf-regie-pied.js')))) pb.push('pas après le pied');
for (const x of ['72-vf-regie-rendu.js', '72-vf-regie-source.js', '90-vf-titre.js']) if (!(at(m(x)) > at(m(q[2])))) pb.push('pas avant ' + x);
console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
JS
  local L="$WORK/ordq-lab" r="" f; mkdir -p "$L/src" "$L/.planning"; printf 'x\n' > "$L/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L/.planning/ROADMAP.md"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/ordq-build.out" 2>&1
  for f in index.html project.html; do r="$r$f=$(node "$AUX/ordre-q.mjs" "$L/.vibeflow/cockpit/$f" 2>&1) "; done
  assert_eq "RG17.0 — lecture, rendu et source des questions : une fois chacun, dans cet ordre, après le pied, avant le rendu, la source et le titre de la régie" "$r" "index.html=ok project.html=ok "
}

rg_RG17_lecture() {
  local o
  # garde verte : le modèle sans ctx.questions garde son comportement (RG1.3) ; prouve que le harnais tourne
  o="$(q_sc '{mode:"pur", etapes:[{nom:"m", mod:"modele", fn:"modele", args:[{workers:[]}, null, {now:1, missions:[]}]}]}')"
  q_ok "RG17.H1 — le modèle sans ctx.questions : quatre sections, « À vous » vide dit « Rien ne vous attend. »" "$o" \
    'j.out.m.sections.map((s) => s.id).join(",") + "|" + j.out.m.sections[0].vide + "|" + j.out.m.sections[0].compte' "a-vous,au-travail,a-relire,au-repos|Rien ne vous attend.|0"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"n", fn:"normaliser", args:[F1]}]}')"
  q_ok "RG17.1 — partition de F1 : en attente, appliquées, à vérifier, mal formées, ignorées, tranchées comptées, tronquée, lue" "$o" \
    '(() => { const n = j.out.n; return [n.source, n.enAttente.map((e) => e.id).join(","), n.appliquees.map((e) => e.id).join(","), n.aVerifier.map((e) => e.id).join(","), n.malFormees.map((e) => e.id).join(","), n.ignorees, n.bilan.tranchees, n.tronque].join("|"); })()' \
    "lue|P90-Q-01,P90-Q-02,P91-Q-01|P90-Q-03|P90-Q-05,P90-Q-06|P90-Q-07,P90-Q-09|2|1|true"
  o="$(q_sc '(() => { const ids = [["mal-formee"], ["a-verifier"], ["tranchee"], ["appliquee"], ["zzz"], [""], ["En-Attente"]];
    const mauvaises = [{ options: "x" }, { options: [{ cle: "a", texte: "seule" }] }, { options: [{ cle: "a", texte: "u" }, { cle: "c", texte: "v" }] }, { recommandation: "z" }, { question: "" }, { titre: "" }, { bloque: [{ type: "rien" }] }, { bloque: "x" }];
    const es = [E("P2-Q-01"), ...ids.map(([s], i) => E("P1-Q-0" + (i + 1), { etat: s })), ...mauvaises.map((m, i) => E("P3-Q-0" + (i + 1), m)), E("x-1", { phase: null })];
    return { mode: "pur", etapes: [{ nom: "n", fn: "normaliser", args: [L(...es)] }] }; })()')"
  q_ok "RG17.2 — fermé par défaut : seule l'entrée bien formée de la liste reste en attente (états autres à forme complète, formes défaillantes, identifiant hors forme)" "$o" \
    'j.out.n.enAttente.map((e) => e.id).join(",") + "|" + (j.out.n.enAttente.length === 1 ? "une" : "plusieurs")' "P2-Q-01|une"
  local WHO='{"workers":['"$(for i in 1 2 3 4; do printf '%s' '{"kind":"session","id":"s'$i'","etat":"attend","titre":"Atelier '$i'","tree":".","ageS":'$([ $i = 2 ] && echo 600 || echo 120)$([ $i = 1 ] && echo ',"retient":{"n":4,"portee":"noeuds"}' || true)$([ $i = 3 ] && echo ',"retient":{"n":0,"portee":"noeuds"}' || true)'}'; [ $i = 4 ] || printf ','; done)"']}'
  o="$(q_sc '{mode:"pur", etapes:[
    {nom:"a", mod:"modele", fn:"modele", args:['"$WHO"', null, {now:1, missions:[], questions:{$norm: F1}}]},
    {nom:"b", mod:"modele", fn:"modele", args:['"$WHO"', null, {now:1, missions:[]}]},
    {nom:"d", mod:"modele", fn:"modele", args:['"$WHO"', null, {now:1, missions:[], questions:{$norm: L(E("P91-Q-01",{bloque:[{type:"phase",n:"92"}]}), E("P90-Q-02"), E("P90-Q-01",{bloque:[{type:"phase",n:"91"}]}))}}]},
    {nom:"x", mod:"modele", fn:"modele", args:['"$WHO"', null, {now:1, missions:[], questions:{$norm: L(E("P72-Q-01",{bloque:[{type:"phase",n:"1"}]}), E("P10-Q-01",{bloque:[{type:"phase",n:"1"}]}), E("P71.5-Q-01",{bloque:[{type:"phase",n:"1"}]}), E("P9-Q-01",{bloque:[{type:"phase",n:"1"}]}), E("P71.10-Q-01",{bloque:[{type:"phase",n:"1"}]}), E("P71-Q-01",{bloque:[{type:"phase",n:"1"}]}))}}]}]}')"
  q_ok "RG17.3 — classement par rang puis ancienneté puis questions triées par la page ; compte, clés, sous-titre inchangé, reçues dans le désordre" "$o" \
    '(() => { const cles = (m) => m.sections[0].lignes.map((l) => l.cle.replace("a-vous:", "")).join(","); return [cles(j.out.a), j.out.a.sections[0].compte, j.out.a.entete.sousTitre === j.out.b.entete.sousTitre, cles(j.out.b), cles(j.out.d), cles(j.out.x)].join("|"); })()' \
    "s1,s2,s4,P90-Q-01,P91-Q-01,s3,P90-Q-02|7|true|s1,s2,s4,s3|s1,s2,s4,P90-Q-01,P91-Q-01,s3,P90-Q-02|s1,s2,s4,P9-Q-01,P10-Q-01,P71-Q-01,P71.5-Q-01,P71.10-Q-01,P72-Q-01,s3"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"f1", fn:"nEnAttente", args:[{$norm: F1}]}, {nom:"f2", fn:"nEnAttente", args:[{$norm: F2}]},
    {nom:"ap", fn:"nEnAttente", args:[{$norm: L(E("P1-Q-01",{etat:"appliquee", appliquee:{canal:"c", date:"d", option:"a", decision:"P1-D-01"}}))}]},
    {nom:"ab", fn:"nEnAttente", args:[{$norm: null}]}, {nom:"il", fn:"nEnAttente", args:[{$norm: "x"}]}]}')"
  q_ok "RG17.4 — le compte du titre : 3 sur F1, 0 sur F2, 0 avec des appliquées seules, 0 si la source est absente ou illisible" "$o" '[j.out.f1, j.out.f2, j.out.ap, j.out.ab, j.out.il].join(",")' "3,0,0,0,0"
  local D12="etat-absent etat-invalide options-invalides recommandation-hors-options bloque-invalide champ-repete champ-manquant phase-incoherente identifiant-double citation-incoherente appliquee-hors-recommandation decision-introuvable"
  o="$(q_sc '(() => { const ds = "'"$D12"'".split(" ").concat(["inconnu-x", "<" + "b>x"]); return { mode: "pur", etapes: ds.map((d, i) => ({ nom: "d" + i, fn: "normaliser", args: [L(E("P1-Q-01", { etat: "a-verifier", defauts: [d] }))] })) }; })()')"
  q_ok "RG17.5 — chacune des douze valeurs rend son libellé ; une valeur inconnue ou hostile rend « défaut non reconnu »" "$o" \
    '[0,1,2,3,4,5,6,7,8,9,10,11,12,13].map((i) => j.out["d" + i].aVerifier[0].defauts[0]).join("|")' \
    "ligne État absente|ligne État illisible|options mal écrites|recommandation hors des options|ligne Bloque illisible|un champ écrit deux fois|un champ manque|identifiant d'une autre phase que son dossier|identifiant déjà utilisé ailleurs|notée en attente alors qu'une décision la dit tranchée|option appliquée différente de la recommandée|décision citée introuvable dans le cadrage|défaut non reconnu|défaut non reconnu"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"m", mod:"modele", fn:"modele", args:[{workers:[], phasesHumaines:[{phase:"90", ws:"", ref:"n:ph-90"}, {phase:"91", ws:"atelier", ref:"n:ph-91@atelier"}]}, null, {now:1, missions:[]}]},
    {nom:"l1", fn:"lienPhase", args:["ph-90"]}, {nom:"l2", fn:"lienPhase", args:["ph-91@atelier"]}, {nom:"n", fn:"lienPhase", args:[null]}, {nom:"h1", fn:"lienPhase", args:["javascript:alert(1)"]},
    {nom:"h2", fn:"lienPhase", args:["ph-90\"x"]}, {nom:"h3", fn:"lienPhase", args:["ph-../x"]},
    {nom:"s", fn:"lignes", args:[{$norm: L(E("P90-Q-01",{phase:null}), E("P91-Q-01",{phase:"ph-91@atelier"}))}]}]}')"
  q_ok "RG17.6 — le lien de phase est celui de 73-04 pour une ligne de phase ; null et valeurs hors forme : aucun lien, « Phase 90, sans carte dans Projet »" "$o" \
    '[j.out.l1 === j.out.m.sections[0].lignes.find((l) => l.cle.includes("phase:::90") || l.cle.includes(":90")).lien, j.out.l2 === j.out.m.sections[0].lignes.find((l) => l.cle.includes("atelier")).lien, j.out.n, j.out.h1, j.out.h2, j.out.h3, j.out.s[0].lienTexte, j.out.s[1].lienTexte].join("|")' \
    "true|true|||||Phase 90, sans carte dans Projet|Voir la phase 91 dans Projet"
  o="$(q_sc '(() => { const x = "x".repeat(1000), op = Array.from({ length: 40 }, (_, i) => ({ cle: i < 26 ? String.fromCharCode(97 + i) : "z", texte: "o" + "y".repeat(300) }));
    const gros = Array.from({ length: 205 }, (_, i) => E("P1-Q-" + (100 + i)));
    const fich = ["/etc/x", "../x", "~/x", "a" + String.fromCharCode(92) + "b", ".planning/ok/x.md"].map((f, i) => ({ id: "P4-Q-0" + (i + 1), etat: "mal-formee", phase: "ph-4", fichier: f, ligne: 3, defauts: [] }));
    return { mode: "pur", etapes: [{ nom: "a", fn: "normaliser", args: [L(E("P5-Q-01", { titre: x, question: x, options: op }))] }, { nom: "g", fn: "normaliser", args: [L(...gros)] }, { nom: "f", fn: "normaliser", args: [L(...fich)] },
      { nom: "s1", fn: "normaliser", args: ["texte"] }, { nom: "s2", fn: "normaliser", args: [[]] }, { nom: "s3", fn: "normaliser", args: [5] }, { nom: "s4", fn: "normaliser", args: [{}] }, { nom: "s5", fn: "normaliser", args: [] },
      { nom: "s6", fn: "normaliser", args: [null] }, { nom: "s7", fn: "normaliser", args: [{ liste: [] }] }, { nom: "s8", fn: "lignes", args: [{ $norm: { liste: [] } }] }] }; })()')"
  q_ok "RG17.7 — bornes : 80, 240, 160, 26 options, 200 entrées ; fichier absolu, .., ~, \\ : null ; formes de champ et sources" "$o" \
    '(() => { const e = j.out.a.enAttente[0], f = j.out.f.malFormees.map((m) => m.fichier);
      return [e.titre.length, e.question.length, e.options[0].texte.length, e.options.length, j.out.g.enAttente.length, f.join(","), [1, 2, 3, 4, 5, 6].map((i) => j.out["s" + i].source).join(","), j.out.s7.source, j.out.s8.length].join("|"); })()' \
    "80|240|160|26|200|,,,,.planning/ok/x.md|illisible,illisible,illisible,illisible,absente,absente|lue|0"
}

# sondes des mutants de la lecture : fonction (dossier ui) -> sortie
q_sonde_etat() { q_g "$(q_sc '(() => { const es = ["mal-formee", "a-verifier", "tranchee", "appliquee", "zzz"].map((s, i) => E("P1-Q-0" + (i + 1), { etat: s })); return { mode: "pur", etapes: [{ nom: "n", fn: "normaliser", args: [L(E("P2-Q-01"), ...es)] }] }; })()' "$1")" 'j.out.n.enAttente.map((e) => e.id).join(",")'; }
q_sonde_fichier() { q_g "$(q_sc '{mode:"pur", etapes:[{nom:"n", fn:"normaliser", args:[L({id:"P4-Q-01", etat:"mal-formee", phase:"ph-4", fichier:"/etc/x", ligne:3, defauts:[]})]}]}' "$1")" 'j.out.n.malFormees[0].fichier'; }
q_sonde_lien() { q_g "$(q_sc '{mode:"pur", etapes:[{nom:"l", fn:"lienPhase", args:["javascript:alert(1)"]}]}' "$1")" 'j.out.l'; }

rg_RG17_reel() {
  local E='"equipe"' o
  # (A) champ dans l'enveloppe tenue par la page, aucune VF_ETAT
  o="$(q_sc '{mode:"pur", enveloppe:{meta:{vfTab:"equipe", vf:{questions:F1}}}, etapes:[{nom:"e", src:"etat"}, {nom:"c", src:"compte"}, {nom:"j", src:"journal"}]}')"
  q_ok "RG17.8A — le champ de l'enveloppe tenue par la page, sans VF_ETAT : lue, trois lignes, aucune requête" "$o" '[j.out.e.source, j.out.e.enAttente.length, j.out.c, j.out.j.requetes.length, j.out.j.fetchs, j.out.j.stockage].join("|")' "lue|3|3|0|0|0"
  # (B) champ absent de l'enveloppe, route par VF_ETAT.lireJson : lecture, puis lue ; une seule lecture en vol ; abonné à `planning` ; relue au changement
  o="$(q_sc '{mode:"pur", enveloppe:{meta:{vfTab:"equipe", vf:{}}}, etat:true, pilote:true, etapes:[{nom:"e0", src:"etat"}, {src:"relire"}, {nom:"j0", src:"journal"},
    {reponse:"resoudre", valeur:{meta:{vf:{questions:F1}}}}, {nom:"e1", src:"etat"}, {nom:"j1", src:"journal"},
    {abo:"planning"}, {reponse:"resoudre", valeur:{meta:{vf:{questions:{liste:[], bilan:{}, tronque:false}}}}}, {nom:"e2", src:"etat"}, {nom:"j2", src:"journal"}]}')"
  q_ok "RG17.8B — route : lecture puis lue, un seul GET en vol, chemin exact, abonné à planning, relue au changement avec UN événement de redessin" "$o" \
    '[j.out.e0.source, j.out.j0.requetes.length, j.out.e1.source, j.out.e1.enAttente.length, j.out.j1.requetes.join(","), j.out.j1.abonnements.join(","), j.out.e2.source, j.out.e2.enAttente.length, j.out.j2.requetes.length, j.out.j2.evts.length - j.out.j1.evts.length].join("|")' \
    "lecture|1|lue|3|/api/vf/graphe?onglet=projet|planning|lue|0|2|1"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"e", src:"etat"}]}')"
  q_ok "RG17.8C — ni enveloppe ni VF_ETAT : absente" "$o" 'j.out.e.source' "absente"
  o="$(q_sc '{mode:"pur", enveloppe:{meta:{vfTab:"equipe", vf:{}}}, etat:true, pilote:true, etapes:[{reponse:"rejeter"}, {nom:"e", src:"etat"}]}')"
  q_ok "RG17.8D — lireJson rejette : illisible" "$o" 'j.out.e.source' "illisible"
  o="$(q_sc '{mode:"pur", enveloppe:{meta:{vfTab:"project", vf:{}}}, etat:true, pilote:true, etapes:[{nom:"e", src:"etat"}, {nom:"j", src:"journal"}]}')"
  q_ok "RG17.8E — page Projet sans champ : absente, aucune requête (l'enveloppe fait foi)" "$o" 'j.out.e.source + "|" + j.out.j.requetes.length' "absente|0"
  o="$(q_sc '{mode:"pur", coquille:true, enveloppe:{meta:{vfTab:"equipe", vf:{}}}, etat:true, pilote:true, etapes:[{nom:"j0", src:"journal"}, {coq:"rappel"}, {nom:"j1", src:"journal"}, {coq:"nettoyer"}, {nom:"j2", src:"journal"}]}')"
  q_ok "RG17.8F — avec VF_COQUILLE : rien avant le rappel, le rappel relit (clé du fichier), le nettoyage retire l'abonnement" "$o" \
    '[j.out.j0.requetes.length, j.out.j1.requetes.length, j.final.inscrits.join(","), j.out.j1.abonnements.join(","), j.final.abonnes.planning].join("|")' "0|1|72-vf-regie-questions-source.js|planning|0"
  q_ok "RG17.8G — aucune écriture de stockage et aucune requête autre que le GET du graphe, sur le scénario B" "$(q_sc '{mode:"pur", enveloppe:{meta:{vfTab:"equipe", vf:{}}}, etat:true, etapes:[{src:"relire"}]}')" \
    '[j.final.stockage, j.final.fetchs, j.final.requetes.length > 0, j.final.requetes.every((r) => r === "/api/vf/graphe?onglet=projet")].join("|")' "0|0|true|true"
  # F2 : sections « À Samuel » réelles, traduites à la main
  o="$(q_sc '{mode:"pur", etapes:[{nom:"n", fn:"normaliser", args:[F2]}, {nom:"b", fn:"bloc", args:[{$norm: F2}]}, {nom:"c", fn:"nEnAttente", args:[{$norm: F2}]}]}')"
  q_ok "RG17.30 — F2 : aucune question en attente (les quatre sont tranchées ou appliquées), trois décisions appliquées dans l'ordre reçu, bilan « 4 tranchées »" "$o" \
    '[j.out.c, j.out.n.enAttente.length, j.out.n.appliquees.map((e) => e.id).join(","), j.out.b.bilan].join("|")' "0|0|P73-Q-02,P73-Q-04,P76-Q-03|Cadrages lus${NB}: 4 tranchées"
  # mutants de la lecture : un par garde de forme ou de non-fuite
  rg_mutant Q-MALFORMEE-EN-ATTENTE "une mal-formee à forme complète classée en attente" "$UI" 72-vf-regie-questions-lecture.js "const attend = st === 'en-attente';" "const attend = st === 'en-attente' || st === 'mal-formee';" q_sonde_etat "P2-Q-01"
  rg_mutant Q-AVERIFIER-EN-ATTENTE "une a-verifier à forme complète classée en attente" "$UI" 72-vf-regie-questions-lecture.js "const attend = st === 'en-attente';" "const attend = st === 'en-attente' || st === 'a-verifier';" q_sonde_etat "P2-Q-01"
  rg_mutant Q-ETAT-IGNORE "l'état n'est plus lu, seule la forme décide" "$UI" 72-vf-regie-questions-lecture.js "const attend = st === 'en-attente';" "const attend = true;" q_sonde_etat "P2-Q-01"
  rg_mutant Q-FICHIER-ABSOLU "fichier passé tel quel" "$UI" 72-vf-regie-questions-lecture.js "return s && !/(^[/~]|[~\\\\]|\\.\\.|^[A-Za-z]:)/.test(s) ? s : null;" "return s || null;" q_sonde_fichier "null"
  rg_mutant Q-LIEN-BRUT "lien construit sans contrôle de forme" "$UI" 72-vf-regie-questions-lecture.js "typeof phase === 'string' && PH.test(phase)" "typeof phase === 'string'" q_sonde_lien "null"
}

# ---------- la page en vm ----------
rg_RG17_page() {
  local o L1='li[data-vf-cle=\"a-vous:P90-Q-01\"]' L2='li[data-vf-cle=\"a-vous:P90-Q-02\"]' L3='li[data-vf-cle=\"a-vous:P91-Q-01\"]' REPLI_D='details[data-vf-repli=\"decisions\"]' REPLI_V='details[data-vf-repli=\"a-verifier\"]'
  o="$(q_page 'F1' '[{"nom":"cles","obs":{"mode":"attr","sel":"'"$Q_AVOUS"' li[data-vf-question]","attr":"data-vf-cle"}},
    {"nom":"t1","obs":{"mode":"textes","sel":"'"$L1"'"}},{"nom":"t2","obs":{"mode":"textes","sel":"'"$L2"'"}},{"nom":"t3","obs":{"mode":"textes","sel":"'"$L3"'"}},
    {"nom":"o1","obs":{"mode":"textes","sel":"'"$L1"' .vf-rg-q-opt"}},{"nom":"o2","obs":{"mode":"textes","sel":"'"$L2"' .vf-rg-q-opt"}},
    {"nom":"etats","obs":{"mode":"attr","sel":"li[data-vf-question]","attr":"data-vf-etat"}},{"nom":"qs","obs":{"mode":"attr","sel":"li[data-vf-question]","attr":"data-vf-question"}},
    {"nom":"ag","obs":{"mode":"sansAttr","sel":"li[data-vf-question]","attr":"data-vf-agent"}},{"nom":"lien","obs":{"mode":"attr","sel":"'"$L1"' a","attr":"href"}},
    {"nom":"lien3","obs":{"mode":"attr","sel":"'"$L3"' a","attr":"href"}}]')"
  q_ok "RG17.10 — trois lignes de question dans « À vous » : clé, identifiant, titre, question, options, recommandée une fois, aucune recommandation, bloque, lien, attributs, aucun data-vf-agent" "$o" \
    '(() => { const a = j.out; return [a.cles.join(","), a.t1[0].includes("P90-Q-01") && a.t1[0].includes("Choix du format d\x27export") && a.t1[0].includes("Quel format sortir ?"), a.o1.join("/"), a.o2[0].includes("recommandée") + "," + a.o2[1].includes("recommandée"),
      a.t2[0].includes("Aucune recommandation."), a.t1[0].includes("bloque : 90-02, Phase 91"), a.t3[0].includes("bloque : Phase 92"), a.t2[0].includes("bloque"), a.lien.join(","), a.lien3.join(","), a.etats.join(","), a.qs.join(","), a.ag].join("|"); })()' \
    "a-vous:P90-Q-01,a-vous:P91-Q-01,a-vous:P90-Q-02|true|(a) CSV recommandée/(b) JSON|false,false|true|true|true|false|project.html#r=n%3Aph-90|project.html#r=n%3Aph-91%40atelier|attend,attend,attend|P90-Q-01,P91-Q-01,P90-Q-02|3"
  o="$(q_page 'F1' '[{"nom":"compte","obs":{"mode":"textes","sel":"'"$Q_AVOUS"' .vf-rg-compte"}},{"nom":"decisions","obs":{"mode":"compte","sel":"'"$REPLI_D"'"}},{"nom":"hors","obs":{"mode":"compte","sel":"'"$Q_AVOUS"' ul.vf-rg-corps details"}},
    {"nom":"ouvert","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},{"nom":"sm","obs":{"mode":"textes","sel":"'"$REPLI_D"' summary"}},{"nom":"t","obs":{"mode":"textes","sel":"'"$REPLI_D"' li"}},
    {"nom":"applique","obs":{"mode":"compte","sel":"li[data-vf-cle=\"a-vous:P90-Q-03\"]"}},{"nom":"liens","obs":{"mode":"attr","sel":"'"$REPLI_D"' a","attr":"href"}}]')"
  q_ok "RG17.11 — décisions appliquées : aucune ligne a-vous, compteur = lignes, un repli fermé hors de la liste avec question, option appliquée, décision, lien" "$o" \
    '(() => { const a = j.out, t = a.t[0] || ""; return [a.compte, a.decisions, a.hors, a.ouvert[0] === null, a.sm[0], t.includes("Garder le repli fermé ?"), t.includes("Option appliquée : (a) oui"), t.includes("Décision : P90-D-03"), a.liens.join(","), a.applique].join("|"); })()' \
    "4|1|0|true|Décisions prises pour vous, contestables (1)|true|true|true|project.html#r=n%3Aph-90|0"
  o="$(q_page '{liste:[], bilan:{enAttente:0, appliquees:0, tranchees:0, aVerifier:0, malFormees:0, nonStructurees:0, registresLus:1}, tronque:false}' '[{"nom":"r","obs":{"mode":"compte","sel":"details[data-vf-repli]"}},{"nom":"z","obs":{"mode":"compte","sel":"[data-vf-qpied]"}}]')"
  q_ok "RG17.11 — N = 0 : aucun repli (le pied des questions existe)" "$o" '[j.out.r, j.out.z].join("|")' "0|1"
  o="$(q_page 'F1' '[{"nom":"sm","obs":{"mode":"textes","sel":"'"$REPLI_V"' summary"}},{"nom":"ouvert","obs":{"mode":"attr","sel":"'"$REPLI_V"'","attr":"open"}},{"nom":"t","obs":{"mode":"textes","sel":"'"$REPLI_V"' li"}},
    {"nom":"avous","obs":{"mode":"compte","sel":"li[data-vf-cle=\"a-vous:P90-Q-05\"], li[data-vf-cle=\"a-vous:P90-Q-06\"]"}},{"nom":"sg","obs":{"mode":"textes","sel":".vf-rg-qsig"}},{"nom":"tout","obs":{"mode":"textes","sel":"#vf-equipe"}}]')"
  q_ok "RG17.12 — à vérifier (2) fermé avec question et défauts en mots ; deux signalements de mal formées ; le fichier relatif est affiché AVANT de constater que la sentinelle de chemin absolu est absente" "$o" \
    '(() => { const a = j.out, sent = '"$(node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(process.argv[1],"utf8")))' "$AUX/sentinelle.txt")"'; return [a.sm[0], a.ouvert[0] === null, a.t[0].includes("Citation à revoir ?") && a.t[0].includes("notée en attente alors qu\x27une décision la dit tranchée"),
      a.t[1].includes("décision citée introuvable dans le cadrage"), a.avous, a.sg[0], a.sg[1], a.tout[0].includes(".planning/workstreams/atelier/phases/VFDO-90-exemple/90-CONTEXT.md"), a.tout[0].includes(sent)].join("|"); })()' \
    "À vérifier (2)|true|true|true|0|Entrée mal formée${NB}: P90-Q-07, .planning/workstreams/atelier/phases/VFDO-90-exemple/90-CONTEXT.md, ligne 88${NB}: un champ manque, ligne Bloque illisible|Entrée mal formée${NB}: P90-Q-09, emplacement non affiché${NB}: ligne État absente|true|false"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"f1", fn:"bloc", args:[{$norm: F1}]}, {nom:"sg", fn:"bloc", args:[{$norm: L(E("P1-Q-01",{etat:"tranchee"}), E("P1-Q-02",{etat:"a-verifier"}), E("P1-Q-03",{etat:"mal-formee"}), E("P1-Q-04",{etat:"zzz"}))}]},
    {nom:"zero", fn:"bloc", args:[{$norm: {liste:[], bilan:{}, tronque:false}}]}, {nom:"cinq", fn:"bloc", args:[{$norm: L(...Array.from({length:7}, (_, i) => E("P2-Q-0" + (i + 1), {etat:"mal-formee"})))}]}]}')"
  q_ok "RG17.13 — le bilan (pluriels, singuliers, aucune ligne à zéro), la troncature, au plus cinq signalements puis « et N autres »" "$o" \
    '[j.out.f1.bilan, j.out.sg.bilan, j.out.zero.bilan === "", j.out.f1.tronque, j.out.zero.tronque === "", j.out.cinq.signalements.length, j.out.cinq.signalements[5]].join("|")' \
    "Cadrages lus${NB}: 1 tranchée · 2 à vérifier · 2 mal formées · 2 questions écrites dans un autre format, non lues · 2 entrées de forme inattendue, ignorées|Cadrages lus${NB}: 1 tranchée · 1 à vérifier · 1 mal formée · 1 entrée de forme inattendue, ignorée|true|Liste tronquée à 11 questions${NB}: les suivantes ne sont pas lues.|true|6|et 2 autres"
  o="$(q_sc '{mode:"pur", etapes:[{nom:"a", fn:"bloc", args:[{$norm: undefined}]}, {nom:"va", fn:"vide", args:[{$norm: undefined}]}, {nom:"l", fn:"bloc", args:[{source:"lecture"}]}, {nom:"vl", fn:"vide", args:[{source:"lecture"}]},
    {nom:"i", fn:"bloc", args:[{$norm: "x"}]}, {nom:"vi", fn:"vide", args:[{$norm: "x"}]}, {nom:"u", fn:"vide", args:[]}, {nom:"vv", fn:"vide", args:[{$norm: {liste:[], bilan:{}, tronque:false}}]}]}')"
  q_ok "RG17.14 — absence dite, lecture, illisibilité ; « Rien ne vous attend. » seulement champ lu ou sans contexte de questions" "$o" \
    '[j.out.a.message, j.out.va === "", j.out.l.message, j.out.vl === "", j.out.i.message, j.out.vi === "", j.out.u, j.out.vv].join("|")' \
    "Lecture des questions des cadrages pas encore livrée (Phase 76)|true|Lecture des questions des cadrages…|true|Questions des cadrages illisibles${NB}: forme inattendue, relue à la prochaine mise à jour.|true|Rien ne vous attend.|Rien ne vous attend."
  o="$(q_page 'undefined' '[{"nom":"msg","obs":{"mode":"textes","sel":".vf-rg-qmsg"}},{"nom":"lignes","obs":{"mode":"compte","sel":"'"$Q_AVOUS"' ul.vf-rg-corps li"}},{"nom":"vide","obs":{"mode":"visibles","sel":"'"$Q_AVOUS"' .vf-rg-vide"}}]')"
  q_ok "RG17.14 — champ absent, un agent qui attend : sa ligne ET le message d'absence ; pas « Rien ne vous attend. » pour une seule lecture absente" "$o" '[j.out.msg[0], j.out.lignes, j.out.vide.length].join("|")' "Lecture des questions des cadrages pas encore livrée (Phase 76)|1|0"
  o="$(q_page '{liste:[], bilan:{enAttente:0, appliquees:0, tranchees:0, aVerifier:0, malFormees:0, nonStructurees:0, registresLus:1}, tronque:false}' '[{"nom":"msg","obs":{"mode":"visibles","sel":".vf-rg-qmsg"}},{"nom":"vide","obs":{"mode":"visibles","sel":"'"$Q_AVOUS"' .vf-rg-vide"}},{"nom":"zone","obs":{"mode":"compte","sel":"[data-vf-qpied]"}}]' '"who":{"workers":[]}')"
  q_ok "RG17.14 — champ présent mais vide, aucun agent : « Rien ne vous attend. » et aucun message d'absence" "$o" '[j.out.msg.length, j.out.vide.join(","), j.out.zone].join("|")' "0|Rien ne vous attend.|1"
  o="$(q_page 'undefined' '[{"nom":"msg","obs":{"mode":"visibles","sel":".vf-rg-qmsg"}},{"nom":"vide","obs":{"mode":"visibles","sel":"'"$Q_AVOUS"' .vf-rg-vide"}}]' '"who":{"workers":[]}')"
  q_ok "RG17.14 — champ absent, aucune autre ligne : le message d'absence, jamais « Rien ne vous attend. »" "$o" '[j.out.msg.join(","), j.out.vide.length].join("|")' "Lecture des questions des cadrages pas encore livrée (Phase 76)|0"
  o="$(q_page 'F1' '[{"nom":"v0","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},{"appel":"__ouvrir","args":["'"$REPLI_D"'",true]},{"focus":"'"$REPLI_D"' summary"},{"nom":"o1","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},
    {"touche":"Escape","nom":"t1"},{"nom":"c1","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},{"nom":"f1","obs":{"mode":"focus"}},
    {"appel":"__ouvrir","args":["'"$REPLI_D"'",true]},{"appel":"__ouvrir","args":["'"$REPLI_V"'",true]},{"focus":"'"$REPLI_V"' summary"},{"touche":"Escape"},
    {"nom":"d2","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},{"nom":"v2","obs":{"mode":"attr","sel":"'"$REPLI_V"'","attr":"open"}},{"touche":"Escape","nom":"t3"},{"nom":"d3","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},
    {"focus":"'"$L1"' a"},{"touche":"Escape","nom":"t4"},{"nom":"f4","obs":{"mode":"focus"}}]')"
  q_ok "RG17.16 — Échap replie le repli le plus récent, rend le focus à son résumé, prend l'appui ; deux replis un par un ; aucun repli ouvert : ni appui pris ni focus déplacé" "$o" \
    '(() => { const a = j.out, p = (v) => (v[0] === null ? "ferme" : "ouvert"); return [p(a.v0), p(a.o1), a.t1.prevenu, p(a.c1), a.f1.tag, p(a.d2), p(a.v2), a.t3.prevenu, p(a.d3), a.t4.prevenu, a.f4.tag].join("|"); })()' "ferme|ouvert|true|ferme|SUMMARY|ouvert|ferme|true|ferme|false|A"
  o="$(q_page 'F1' '[{"appel":"__ouvrir","args":["'"$REPLI_D"'",true]},{"focus":"'"$REPLI_D"' summary"},{"touche":"Escape","prevenu":true,"nom":"t"},{"nom":"d","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},
    {"touche":"Escape","sur":"#search","nom":"h"},{"nom":"d2","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},
    {"focus":"button.vf-rg-tog"},{"clic":"button.vf-rg-tog"},{"nom":"exp","obs":{"mode":"attr","sel":"button.vf-rg-tog","attr":"aria-expanded"}},{"focus":"button.vf-rg-tog"},{"touche":"Escape"},
    {"nom":"exp2","obs":{"mode":"attr","sel":"button.vf-rg-tog","attr":"aria-expanded"}},{"nom":"d3","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}}]')"
  q_ok "RG17.16 — appui déjà pris : le repli reste ouvert ; cible hors de la régie : rien ; détail en flux ouvert : il se referme, le repli reste ouvert" "$o" \
    '(() => { const a = j.out, p = (v) => (v.length === 0 ? "absent" : v[0] === null ? "ferme" : "ouvert"); return [p(a.d), p(a.d2), a.exp[0], a.exp2[0], p(a.d3)].join("|"); })()' "ouvert|ouvert|true|false|ouvert"
  assert_eq "RG17.16 — l'écouteur d'Échap des replis est posé sur document, en remontée, jamais en capture ni sur window" \
    "$(grep -c "D.addEventListener('keydown', surEchap)" "$UI/72-vf-regie-questions-rendu.js" 2>/dev/null)|$(grep -cE "window\.addEventListener\('keydown'|addEventListener\('keydown', [a-zA-Z]+, (true|\{ *capture)" "$UI/72-vf-regie-questions-rendu.js" 2>/dev/null)" "1|0"
  local base mont
  base="$(q_page 'F1' '[{"nom":"b","obs":{}}]' '"coquille":{"onglet0":"code"}')"
  mont="$(q_page 'F1' '[{"onglet":"equipe"},{"nom":"m","obs":{}},{"nom":"md","obs":{"mode":"compte","sel":"[data-vf-question]"}},{"onglet":"code"},{"nom":"z","obs":{}},{"nom":"dom","obs":{"mode":"compte","sel":"[data-vf-question], [data-vf-repli], #vf-equipe"}}]' '"coquille":{"onglet0":"code"}')"
  assert_eq "RG17.17 — après le nettoyage : écouteurs, minuteries et abonnements au compte de départ, aucun DOM de questions ; aucune minuterie de plus que sans questions" \
    "$(q_g "$mont" '[j.out.z.ecouteurs, j.out.z.minuteries, JSON.stringify(j.out.z.abonnes), j.out.dom, j.out.md].join("|")')|$(q_g "$mont" 'j.out.m.minuteries')" \
    "$(q_g "$base" '[j.out.b.ecouteurs, j.out.b.minuteries, JSON.stringify(j.out.b.abonnes), 0, 3].join("|")')|$(q_g "$(q_page 'undefined' '[{"onglet":"equipe"},{"nom":"m","obs":{}}]' '"coquille":{"onglet0":"code"}')" 'j.out.m.minuteries')"
  o="$(q_page 'F1' '[{"marquer":"li[data-vf-question]"},{"nom":"m0","obs":{"mode":"marques","sel":"li[data-vf-question]"}},{"poser":{"who":'"$Q_WHO"'}},{"nom":"m1","obs":{"mode":"marques","sel":"li[data-vf-question]"}},
    {"appel":"__poserQuestions","args":[{"liste":[],"bilan":{},"tronque":false}]},{"nom":"m2","obs":{"mode":"compte","sel":"li[data-vf-question]"}},
    {"nom":"k","obs":{"mode":"attr","sel":"[data-vf-repli] li","attr":"data-vf-cle"}}]')"
  q_ok "RG17.18 — deux poussées identiques gardent chaque li de question ; une question retirée disparaît ; clés exactes des replis" "$o" '[j.out.m0, j.out.m1, j.out.m2, j.out.k.join(",")].join("|")' "3|3|0|"
  o="$(q_page 'F1' '[{"appel":"__ouvrir","args":["'"$REPLI_D"'",true]},{"appel":"__poserQuestions","args":[F1PLUS]},{"nom":"sm","obs":{"mode":"textes","sel":"'"$REPLI_D"' summary"}},{"nom":"op","obs":{"mode":"attr","sel":"'"$REPLI_D"'","attr":"open"}},
    {"nom":"k","obs":{"mode":"attr","sel":"[data-vf-repli] li","attr":"data-vf-cle"}},{"focus":"'"$L1"' a"},{"appel":"__poserQuestions","args":[F1PLUS]},{"nom":"f1","obs":{"mode":"focus"}},
    {"appel":"__poserQuestions","args":[F1SANS]},{"nom":"f2","obs":{"mode":"focus"}},{"nom":"txt","obs":{"mode":"textes","sel":"'"$L3"' .vf-rg-nom"}}]')"
  q_ok "RG17.18 — repli ouvert à travers un redessin (N changé), focus gardé sur un lien, puis rendu au titre de « À vous » si la ligne disparaît" "$o" \
    '(() => { const a = j.out; return [a.sm[0], a.op[0] !== null, a.k.join(","), a.f1.cle, a.f1.tag, a.f2.tag, a.f2.section].join("|"); })()' \
    "Décisions prises pour vous, contestables (2)|true|decisions-prises:P90-Q-03,decisions-prises:P90-Q-08,a-verifier:P90-Q-05,a-verifier:P90-Q-06|a-vous:P90-Q-01|A|H2|a-vous"
  o="$(q_page 'F1' '[{"saisie":"#search","valeur":"format"},{"nom":"v","obs":{"mode":"visiblesAttr","sel":"'"$Q_AVOUS"' li[data-vf-question]","attr":"data-vf-cle"}},{"saisie":"#search","valeur":""},{"nom":"t","obs":{"mode":"visiblesAttr","sel":"'"$Q_AVOUS"' li[data-vf-question]","attr":"data-vf-cle"}}]')"
  q_ok "RG17.19 — recherche d'un mot du titre : seule la ligne qui le porte reste ; champ vidé : tout revient" "$o" '[j.out.v.join(","), j.out.t.length].join("|")' "a-vous:P90-Q-01|3"
  o="$(q_page 'F1' '[{"nom":"b","obs":{"mode":"compte","sel":"'"$Q_AVOUS"' li[data-vf-question] button, '"$Q_AVOUS"' [data-vf-repli] button, '"$Q_AVOUS"' [data-vf-repli] .btn, li[data-vf-question] .btn, li[data-vf-question] [role=button], [data-vf-repli] input, li[data-vf-question] input"}},
    {"nom":"a","obs":{"mode":"compte","sel":"li[data-vf-question] a.vf-link"}},{"nom":"titre","obs":{"mode":"trouve","sel":"'"$L1"'","contient":"Choix du format d'"'"'export"}}]')"
  q_ok "RG17.20 — aucune action : ni bouton, ni .btn, ni champ ; des liens ; le titre d'une question écrit une seule fois (ni attribut ni élément en double)" "$o" '[j.out.b, j.out.a > 0, j.out.titre.textes, j.out.titre.attrs].join("|")' "0|true|1|0"
  o="$(q_page 'F1' '[{"nom":"r1","obs":{"mode":"textes","sel":"'"$L1"' .rp, '"$L1"' .mono"}},{"nom":"r2","obs":{"mode":"textes","sel":"'"$L2"' .rp, '"$L2"' .mono"}},{"nom":"rd","obs":{"mode":"textes","sel":"'"$REPLI_D"' .rp, '"$REPLI_D"' .mono"}},
    {"nom":"rv","obs":{"mode":"textes","sel":"'"$REPLI_V"' .rp, '"$REPLI_V"' .mono"}}]')"
  q_ok "RG17.21 — le texte du disque (identifiant, titre, question, option, décision, fichier) est porté par un élément de classe exclue de la traduction (.rp ou .mono)" "$o" \
    '(() => { const a = j.out, h = "<" + "img src=x onerror=\"window.__pwn=1\">"; return [["P90-Q-01", "Quel format sortir ?", "(a) CSV", "(b) JSON"].every((s) => a.r1.some((t) => t.includes(s))), a.r2.some((t) => t === h), a.r2.some((t) => t.includes(h)),
      a.rd.some((t) => t.includes("P90-D-03")), a.rd.some((t) => t.includes("oui")), a.rv.some((t) => t.includes("Citation à revoir ?")), a.rv.some((t) => t.includes(".planning/workstreams/atelier/phases/VFDO-90-exemple/90-CONTEXT.md"))].join(","); })()' \
    "true,true,true,true,true,true,true"
}

rg_RG17_reelpage() {
  local o
  o="$(q_page 'F2' '[{"nom":"lignes","obs":{"mode":"compte","sel":"'"$Q_AVOUS"' li[data-vf-question]"}},{"nom":"sm","obs":{"mode":"textes","sel":"details[data-vf-repli=\"decisions\"] summary"}},{"nom":"k","obs":{"mode":"attr","sel":"details[data-vf-repli=\"decisions\"] li","attr":"data-vf-cle"}},
    {"nom":"avous","obs":{"mode":"compte","sel":"li[data-vf-cle=\"a-vous:P73-Q-03\"], li[data-vf-cle=\"a-vous:P73-Q-02\"], li[data-vf-cle=\"a-vous:P76-Q-01\"]"}},{"nom":"bilan","obs":{"mode":"textes","sel":".vf-rg-qbilan"}}]')"
  q_ok "RG17.31 — F2 dans le DOM : aucune ligne de question, repli « Décisions prises pour vous, contestables (3) » avec les trois appliquées, aucune ligne pour une tranchée ou une appliquée" "$o" \
    '[j.out.lignes, j.out.sm[0], j.out.k.join(","), j.out.avous, j.out.bilan[0]].join("|")' "0|Décisions prises pour vous, contestables (3)|decisions-prises:P73-Q-02,decisions-prises:P73-Q-04,decisions-prises:P76-Q-03|0|Cadrages lus${NB}: 4 tranchées"
  # mutant de non-fuite : un balisage inséré à la place de texte est vu par le DOM réduit (violations)
  q_sonde_html() { q_g "$(q_page 'F1' '[{"nom":"x","obs":{"mode":"compte","sel":"li[data-vf-question]"}}]' '' "$1")" 'j.out.x + "|" + j.final.violations.length'; }
  assert_eq "RG17.40 — hors navigateur : trois lignes de question rendues, aucun balisage construit (innerHTML, insertAdjacentHTML)" "$(q_sonde_html "$UI")" "3|0"
  rg_mutant Q-HTML "balisage inséré à la place de texte" "$UI" 72-vf-regie-questions-rendu.js "{ if (e.textContent !== t) e.textContent = t; }" "{ e.innerHTML = t; }" q_sonde_html "3|0"
}

# ---------- navigateur ----------
q_chrome() { # <scénario> <fichier de sortie> : serveur frais du lab jetable, harnais, arrêt
  local L="$WORK/lab-q" out
  [ -d "$L" ] || rg_lab "$L"
  rg_serveur "$L"
  out="$(REAL_HOME="${REAL_HOME:-$HOME}" VF_UI="$UI" VF_FIXTURES="$AUX" node "$TESTS_DIR/chrome-regie-questions.mjs" "$CHROME" "http://127.0.0.1:$RG_PORT/" "$1" 2>&1)"
  rg_arreter
  printf '%s\n' "$out" > "$2"
}
rg_RG17_chrome() {
  rg_chrome || return 0
  q_fixtures
  local o="$WORK/q-chrome-rendu.json"
  q_chrome rendu "$o"
  q_ok "RG17.40 — navigateur : les trois lignes sont affichées avec leur texte, puis le texte hostile reste inerte (aucun img ni script, window.__pwn indéfini), la traduction ne réécrit pas un titre égal à une clé du dictionnaire" "$o" \
    '[j.lignes, j.hostile, j.img, j.pwn, j.cle !== "", j.cleIntacte].join("|")' "3|true|0|undefined|true|true"
  q_ok "RG17.43 — navigateur : aucun défilement horizontal à 375 et à 1 000 px avec titre, question et option longs ; le fichier relatif est affiché, puis la sentinelle absente de tout le HTML" "$o" \
    '[j.debord375, j.debord1000, j.fichierAffiche, j.sentinelle].join("|")' "false|false|true|false"
  q_chrome echap "$o"
  q_ok "RG17.42 — navigateur : clic sur le résumé d'un repli puis Échap réel : le repli est fermé et le focus est son résumé ; un second Échap sans repli ouvert ne change rien" "$o" \
    '[j.ouvert, j.ferme, j.focusResume, j.secondFocus, j.secondOuvert].join("|")' "true|true|true|true|false"
}
rg_RG17_titre() {
  rg_chrome || return 0
  q_fixtures
  local o="$WORK/q-chrome-titre.json"
  q_chrome titre "$o"
  q_ok "RG17.41 — navigateur : « (4) vous attendent » avec un agent et les trois questions, icône en data:image/svg+xml ; « (1) vous attend » avec les seules décisions appliquées et le même agent ; sans agent : aucun préfixe, icône d'origine ; focus non déplacé" "$o" \
    '[/^\(4\) vous attendent · /.test(j.quatre), j.icone4.startsWith("data:image/svg+xml"), /^\(1\) vous attend · /.test(j.un), !/^\(/.test(j.zero), j.hrefZero === j.hrefOrigine, j.focus].join("|")' "true|true|true|true|true|vf-t-focus"
}

# ---------- correctifs de revue du point de fusion 2 (source de la régie, 73-05) ----------
rg_RG17_revue() {
  local o SID=s0000000-aaaa-bbbb-cccc-111111111111
  # R1 : une ancre n:se-<id> reçue avant le who est tenue, puis consommée au premier rendu où la ligne existe (défilement et focus), jamais un toast
  o="$(q_sc '{mode:"page", page:{onglet:"equipe", source:"live", who:null, lock:null, etapes:[{"nom":"a","appel":"__vfRegie.arriver","args":["n:se-'$SID'"]},
    {"nom":"autre","appel":"__vfRegie.arriver","args":["n:xx-1"]},{"poser":{"who":'"$Q_WHO"'}},{"nom":"f","obs":{"mode":"focus"}},{"nom":"d","obs":{"mode":"compte","sel":"li[data-vf-cle]"}}]}}')"
  q_ok "RG17.R1 — ancre à froid : arriver rend true avant le montage des lignes, la ligne reçoit le focus quand le who arrive ; une ancre d'une autre forme rend false" "$o" \
    '[j.out.a, j.out.autre, j.out.f.cle, j.out.d > 0].join("|")' "true|false|a-vous:$SID|true"
  # R2 : le bouton « Tout marquer comme relu » qui porte le focus quitte la page : le focus va au titre de « Terminé, à relire »
  # R3 : il marque tous les rapports à relire, pas les seuls huit affichés
  local W12='{workers:[{kind:"session",id:"'$SID'",etat:"actif",titre:"Atelier",tree:".",ageS:5,dureeS:900}, ...Array.from({length:12},(_, i) => ({kind:"subagent",id:"a" + String(i).padStart(11,"0"),etat:"termine",parent:"'$SID'",role:"vf-reviewer",task:"Relire " + i,ageS:600 + i,dureeS:90,tree:"."}))]}'
  o="$(q_sc '{mode:"page", lu:true, page:{onglet:"equipe", source:"live", who:'"$W12"', lock:null, etapes:[{"nom":"b0","obs":{"mode":"compte","sel":"[data-vf-tout]"}},
    {"focus":"[data-vf-tout]"},{"clic":"[data-vf-tout]"},{"nom":"n","appel":"__tmCompte","args":[]},{"nom":"b1","obs":{"mode":"compte","sel":"[data-vf-tout]"}},{"nom":"f","obs":{"mode":"focus"}}]}}')"
  q_ok "RG17.R2 — le bouton « Tout marquer comme relu » retiré alors qu'il porte le focus : le focus va au titre de la section « Terminé, à relire », jamais à body" "$o" '[j.out.b0, j.out.b1, j.out.f.tag, j.out.f.section].join("|")' "1|0|H2|a-relire"
  q_ok "RG17.R3 — « Tout marquer comme relu » marque les douze rapports à relire, pas les huit affichés" "$o" 'j.out.n' "12"
}
