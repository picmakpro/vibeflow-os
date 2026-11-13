#!/usr/bin/env bash
# test-cockpit-burnup.sh — burn-up du jalon mis en avant et retrait de la prose du STATE (Phase 77, plan 77-02 ; P77-D-12, P77-D-13, P77-D-14, SYNT-08, SYNT-09).
# BU0-BU8 : module pur vf-cockpit-burnup.mjs (dates de la ligne de checklist du ROADMAP, série en escalier, phases sans date) ; BU9 : branchement dans le graphe
# Projet (meta.vf.burnup, pourcentage = celui du pied du jalon) ; BU10 : pureté ; BU11 : atteint instantane().projet (conditionné à la collecte 79-09) ;
# RT1-RT3 : la prose last_activity_desc n'est plus servie (retrait, un ajout un retrait).
# Les 16 lignes de checklist du jalon sont figées ici (copiées du ROADMAP de la planification, tronquées après la date de clôture) : oracle indépendant du module.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"

BU="$SCRIPTS/vf-cockpit-burnup.mjs"
cat > "$AUX/bu.mjs" <<'JS'
// bu.mjs <module> <mode> [arg] : exports | lignes <fichier> | dates <ligne> | burnup <entree.json>
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const [, , mod, mode, arg] = process.argv;
let m; try { m = await import(pathToFileURL(mod).href); } catch (e) { console.log('MODULE-ABSENT'); process.exit(0); }
if (mode === 'exports') console.log(Object.keys(m).sort().join(','));
else if (mode === 'lignes') {
  for (const l of fs.readFileSync(arg, 'utf8').split('\n').filter(Boolean)) {
    const n = /Phase ([\d.]+):/.exec(l)[1], d = m.dates(l);
    console.log([n, d.inscription ?? '-', d.cloture ?? '-'].join('|'));
  }
} else if (mode === 'dates') console.log(JSON.stringify(m.dates(arg)));
else if (mode === 'burnup') {
  const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);
  console.log(JSON.stringify(m.burnup({ ...JSON.parse(fs.readFileSync(arg, 'utf8')), pct })));
}
JS
b() { node "$AUX/bu.mjs" "$BU" "$@"; }
cat > "$AUX/lignes16.txt" <<'MD'
- [x] Phase 67: Cockpit floorplan sur socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-03
- [x] Phase 68: Embarquer vf-signal sur le socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-04
- [x] Phase 69: Suivi du travail en cours dans le cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04
- [x] Phase 70: Finitions UI du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04 : PR mergée le 2026-11-04T21:02:38Z, cochées le 2026-11-05 et le 2026-11-11
- [x] Phase 71: Terminal intégré au cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-05
- [x] Phase 71.5: Réexamen du design system du cockpit — couleurs d'abord, puis icônes, espacements, hiérarchie des vues (INSERTED, inscrite 2026-11-05, élargie le même jour, jalon vibeflow-v2.0) — complete 2026-11-06
- [x] Phase 72: Lancer du travail depuis les cartes du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-06
- [ ] Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 74: L'équipe dans le temps — swim-lanes, coût, replay (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [x] Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git (inscrite 2026-11-05, jalon vibeflow-v2.0) — complete 2026-11-06
- [ ] Phase 79: Socle du cockpit — une collecte, un flux, une route d'état (inscrite 2026-11-11, jalon vibeflow-v2.0)
- [ ] Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation (inscrite 2026-11-11, jalon vibeflow-v2.0)
- [ ] Phase 81: Agir sur une session depuis le cockpit (inscrite 2026-11-11, jalon vibeflow-v2.0, reportée
MD

# ---------- BU0 — exports exacts ----------
assert_eq "BU0 — le module se charge et exporte exactement CLOTURE, INSCRIPTION, burnup, dates" "$(b exports)" "CLOTURE,INSCRIPTION,burnup,dates"

# ---------- BU1 — les 16 lignes figées : 8 clôtures datées, 16 inscriptions datées, dates attendues écrites en dur ----------
ATTENDU16='67|2026-11-01|2026-11-03
68|2026-11-01|2026-11-04
69|2026-11-03|2026-11-04
70|2026-11-03|2026-11-04
71|2026-11-03|2026-11-05
71.5|2026-11-05|2026-11-06
72|2026-11-03|2026-11-06
73|2026-11-03|-
74|2026-11-03|-
75|2026-11-03|-
76|2026-11-03|-
77|2026-11-03|-
78|2026-11-05|2026-11-06
79|2026-11-11|-
80|2026-11-11|-
81|2026-11-11|-'
OBT16="$(b lignes "$AUX/lignes16.txt")"
assert_eq "BU1 — les 16 lignes du jalon : 16 inscriptions et 8 clôtures datées, aux dates attendues (oracle en dur)" "$OBT16" "$ATTENDU16"

# ---------- BU2 — première occurrence ancrée sur le mot-clé ----------
assert_eq "BU2 — Phase 70 (d'autres dates plus loin dans la ligne) : la clôture est la première, pas une date de fin de ligne" "$(b dates "$(sed -n 4p "$AUX/lignes16.txt")")" '{"cloture":"2026-11-04","inscription":"2026-11-03"}'
assert_eq "BU2 — Phase 71.5 (« INSERTED, inscrite … ) — complete … ») : inscription et clôture lues sur leur mot-clé" "$(b dates "$(sed -n 6p "$AUX/lignes16.txt")")" '{"cloture":"2026-11-06","inscription":"2026-11-05"}'
assert_eq "BU2 — deux occurrences de chaque mot-clé : la première l'emporte (inscription ET clôture)" "$(b dates '- [x] Phase 9: x (inscrite 2026-01-01) — complete 2026-03-03 puis (inscrite 2026-02-02) (completed 2026-04-04')" '{"cloture":"2026-03-03","inscription":"2026-01-01"}'

# ---------- BU3 — les cinq formes de clôture ; date invalide ----------
FORMES="$(for f in '— complete 2026-01-01' '(completed 2026-01-02' '(complete 2026-01-03' '— close 2026-01-04' '(close 2026-01-05'; do b dates "- [x] Phase 1: x $f" | node "$AUX/get.mjs" /dev/stdin 'j.cloture'; done | paste -sd, -)"
assert_eq "BU3 — les cinq formes de clôture sont reconnues (— complete, (completed, (complete, — close, (close)" "$FORMES" "2026-01-01,2026-01-02,2026-01-03,2026-01-04,2026-01-05"
assert_eq "BU3 — une date de calendrier invalide donne null (mois 13, 30 février), le 29 février d'une année bissextile reste valide" "$(b dates '- [x] Phase 1: x (inscrite 2026-02-30) — complete 2026-13-40') $(b dates '- [x] Phase 1: x (inscrite 2024-02-29)')" '{"cloture":null,"inscription":null} {"cloture":null,"inscription":"2024-02-29"}'

# ---------- BU4..BU8 — le burn-up lui-même ----------
mkin() { printf '%s' "$2" > "$AUX/in-$1.json"; b burnup "$AUX/in-$1.json"; }
S4="$(mkin 4 '{"jalon":"J","phases":[{"n":"1","nom":"A","line":"x (inscrite 2026-01-01) — complete 2026-01-05","etat":"fait"},{"n":"2","nom":"B","line":"x (inscrite 2026-01-02) — complete 2026-01-09","etat":"a-recetter"}]}')"
printf '%s' "$S4" > "$WORK/s4.json"
assert_eq "BU4 — clos compte l'état fait, jamais la case cochée : une phase à recetter n'est pas close et sa date de clôture est ignorée" "$(G "$WORK/s4.json" '[j.clos, j.total, j.pct, j.serie.map((p) => p.closes.join("+") + "@" + p.d).join(",")].join("|")')" "1|2|50|@2026-01-01,@2026-01-02,1@2026-01-05"
S5='{"jalon":"J","phases":[{"n":"1","nom":"Un","line":"x (inscrite 2026-01-01) — complete 2026-01-03","etat":"fait"},{"n":"2","nom":"Deux","line":"x (inscrite 2026-01-01) — complete 2026-01-05","etat":"fait"},{"n":"3","nom":"Trois","line":"x (inscrite 2026-01-04)","etat":"en-cours"},{"n":"4","nom":"Quatre","line":"y","etat":"a-faire"},{"n":"5","nom":"Cinq","line":"x (inscrite 2026-01-02)","etat":"fait"}]}'
mkin 5 "$S5" > "$WORK/s5.json"
assert_eq "BU5 — phase fait sans date de clôture : dans clos, absente de toute marche, nommée dans closesSansDate" "$(G "$WORK/s5.json" '[j.clos, JSON.stringify(j.closesSansDate), j.serie.some((p) => p.closes.includes("5"))].join("|")')" '3|[{"n":"5","nom":"Cinq"}]|false'
assert_eq "BU6 — phase sans inscription : entre au périmètre à ouverture, nommée dans inscritesSansDate" "$(G "$WORK/s5.json" '[j.ouverture, JSON.stringify(j.inscritesSansDate), j.serie[0].d + ":" + j.serie[0].perimetre].join("|")')" '2026-01-01|[{"n":"4","nom":"Quatre"}]|2026-01-01:3'
assert_eq "BU7 — série croissante, cumulée, premier point à ouverture, dernier périmètre = total, pourcentage = celui de la fonction injectée" "$(G "$WORK/s5.json" 'JSON.stringify([j.pct, j.total, j.serie])')" '[60,5,[{"d":"2026-01-01","perimetre":3,"clos":0,"closes":[]},{"d":"2026-01-02","perimetre":4,"clos":0,"closes":[]},{"d":"2026-01-03","perimetre":4,"clos":1,"closes":["1"]},{"d":"2026-01-04","perimetre":5,"clos":1,"closes":[]},{"d":"2026-01-05","perimetre":5,"clos":2,"closes":["2"]}]]'
mkin 7 '{"jalon":"J","phases":[{"n":"1","nom":"A","line":"sans date","etat":"fait"},{"n":"2","nom":"B","line":"rien","etat":"a-faire"}]}' > "$WORK/s7.json"
assert_eq "BU7 — jalon sans aucune date : ouverture null, série vide, rien d'estimé (la phase fait est dans clos et dans closesSansDate)" "$(G "$WORK/s7.json" 'JSON.stringify([j.ouverture, j.serie, j.clos, j.closesSansDate.length, j.inscritesSansDate.length])')" '[null,[],1,1,2]'
printf '{"jalon":null,"phases":[{"n":"1","nom":"A","line":"x","etat":"fait"}]}' > "$AUX/in-n1.json"; printf '{"jalon":"J","phases":[]}' > "$AUX/in-n2.json"
assert_eq "BU7 — sans jalon, ou sans phase : null" "$(b burnup "$AUX/in-n1.json") $(b burnup "$AUX/in-n2.json")" "null null"
mkin 8 '{"jalon":"J","phases":[{"n":"1","nom":"A","line":"x (inscrite 2026-01-10) — complete 2026-01-05","etat":"fait"},{"n":"2","nom":"B","line":"x (inscrite 2026-01-08)","etat":"a-faire"}]}' > "$WORK/s8.json"
assert_eq "BU8 — clôture antérieure à l'inscription : la phase entre au périmètre à sa date de clôture, jamais clos > périmètre" "$(G "$WORK/s8.json" 'JSON.stringify([j.ouverture, j.serie.map((p) => p.d + ":" + p.perimetre + ":" + p.clos), j.serie.every((p) => p.clos <= p.perimetre)])')" '["2026-01-05",["2026-01-05:1:1","2026-01-08:2:1"],true]'

# ---------- BU9 — branchement dans le graphe Projet ----------
mk_bu() { local L="$1" B="$1/.planning"; mkdir -p "$B"
printf '%s\n' '# Roadmap' '' '## Milestones' '' '- 🚧 **v1.0 Démo** - Phases 1-3 (in progress)' '' '## Phases' '' \
  '- [x] Phase 1: Socle (inscrite 2026-01-02, jalon v1.0 Démo) — complete 2026-01-05' '- [x] Phase 2: Écran (inscrite 2026-01-03, jalon v1.0 Démo) — complete 2026-01-08' '- [ ] Phase 3: Reste (inscrite 2026-01-04, jalon v1.0 Démo)' > "$B/ROADMAP.md"
printf -- '---\nstatus: executing\ncurrent_phase: 3\ncurrent_phase_name: MARQUEUR-NOM-77\nmilestone: v1.0 Démo\nlast_activity_desc: MARQUEUR-PROSE-77 une prose recopiée\n---\n' > "$B/STATE.md"
for n in 01-socle/01-01 02-ecran/02-01; do printf '<objective>Faire</objective>\n' | wr "$B/phases/$n-PLAN.md"; echo ok > "$B/phases/$n-SUMMARY.md"; done
git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -qm init; }
LB="$WORK/lab-bu"; mk_bu "$LB"; graph "$LB" "$WORK/g-bu.json"
assert_eq "BU9 — meta.vf.burnup.jalon est la clé du jalon mis en avant, clos 2 sur 3" "$(G "$WORK/g-bu.json" '[j.meta.vf.burnup?.jalon, j.meta.vf.burnup?.clos, j.meta.vf.burnup?.total].join("|")')" "v1.0 Démo|2|3"
assert_eq "BU9 — meta.vf.burnup.pct est égal au nombre suivi de « % » du pied du nœud du jalon (même fonction pct), et vaut 67" "$(G "$WORK/g-bu.json" '(() => { const f = j.nodes.find((n) => n.kind === "jalon").foot; const m = /(\d+) %$/.exec(f); return [m && Number(m[1]) === j.meta.vf.burnup?.pct, j.meta.vf.burnup?.pct].join("|"); })()')" "true|67"
assert_eq "BU9 — la série du graphe porte les dates du ROADMAP (ouverture, deux clôtures)" "$(G "$WORK/g-bu.json" 'JSON.stringify([j.meta.vf.burnup?.ouverture, (j.meta.vf.burnup?.serie || []).filter((p) => p.closes.length).map((p) => p.d)])')" '["2026-01-02",["2026-01-05","2026-01-08"]]'
LS0="$WORK/lab-bu-sans"; mkdir -p "$LS0/.planning"; printf -- '---\nstatus: executing\n---\n' > "$LS0/.planning/STATE.md"; graph "$LS0" "$WORK/g-bu0.json"
assert_eq "BU9 — lab sans jalon ni phase : le champ burnup est absent" "$(G "$WORK/g-bu0.json" '"burnup" in j.meta.vf')" "false"
assert_eq "BU9 — le graphe valide cockpit-project@1 (validate.mjs)" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g-bu.json")" "OK"

# ---------- BU10 — pureté du module ----------
if [ -f "$BU" ]; then
  CODE="$(awk '!/^[[:space:]]*\/\//' "$BU")"
  PURETE="$(printf '%s\n' "$CODE" | /usr/bin/grep -cE '(^|[^A-Za-z_])(import|process|Date|fs|child_process)([^A-Za-z_]|$)|Math\.random|Math\.round' || true)"
  LIGNES="$(awk 'END{print NR}' "$BU")"
else PURETE="module-absent"; LIGNES=9999; fi
assert_eq "BU10 — aucun import, process, Date, Math.random, Math.round, fs ni child_process dans le code du module (commentaires de ligne exclus)" "$PURETE" "0"
assert_eq "BU10 — le module tient sous 150 lignes" "$([ "$LIGNES" -lt 150 ] && echo oui || echo "non ($LIGNES)")" "oui"

# ---------- BU11 — atteint instantane().projet (79-09) ----------
cat > "$AUX/bu11.mjs" <<'JS'
// bu11.mjs <scripts> <lab> : la pose de etapePlanning dans l'instantané porte les deux champs, égaux à buildProjectGraph
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { etapePlanning } = await imp('vf-cockpit-collecte-etapes.mjs'), { poser, instantane } = await imp('vf-cockpit-instantane.mjs'), { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const canon = (v) => JSON.stringify(v, (k, x) => (x && typeof x === 'object' && !Array.isArray(x) ? Object.fromEntries(Object.entries(x).sort(([a], [b]) => (a < b ? -1 : 1))) : x));
poser({ seq: 1, at: 0, git: null, projet: etapePlanning({ racine: lab }) });
const i = instantane(), ref = buildProjectGraph(lab);
console.log(JSON.stringify({ burnup: !!i.projet.meta.vf.burnup, blocages: Array.isArray(i.projet.meta.vf.blocagesState), egalBurnup: canon(i.projet.meta.vf.burnup) === canon(ref.meta.vf.burnup), egalBlocages: canon(i.projet.meta.vf.blocagesState) === canon(ref.meta.vf.blocagesState) }));
JS
if /usr/bin/git -C "$SCRIPTS" cat-file -e HEAD:plugin/cockpit/scripts/vf-cockpit-instantane.mjs 2>/dev/null; then
  node "$AUX/bu11.mjs" "$SCRIPTS" "$LB" > "$WORK/bu11.json" 2>&1
  assert_eq "BU11 — instantane().projet.meta.vf.burnup est égal, en JSON canonique, à celui de buildProjectGraph sur le même lab (non vide)" "$(G "$WORK/bu11.json" 'j.burnup && j.egalBurnup')" "true"
else echo "  BU11 — non applicable : 79-09 absent (ne compte pas comme PASS)"; fi

# ---------- RT1..RT3 — la prose du STATE n'est plus servie ----------
GJ="$(cat "$WORK/g-bu.json")"
assert_eq "RT1 — sonde positive : un marqueur posé dans current_phase_name du STATE apparaît dans le graphe sérialisé" "$(printf '%s' "$GJ" | grep -c 'MARQUEUR-NOM-77' | awk '{print ($1>0)?"oui":"non"}')" "oui"
assert_eq "RT2 — le marqueur posé dans last_activity_desc est absent du graphe sérialisé" "$(printf '%s' "$GJ" | grep -c 'MARQUEUR-PROSE-77' | awk '{print ($1>0)?"present":"absent"}')" "absent"
assert_eq "RT3 — meta.vf ne porte plus la clé de la prose" "$(G "$WORK/g-bu.json" '"lastDesc" in j.meta.vf')" "false"

bilan
