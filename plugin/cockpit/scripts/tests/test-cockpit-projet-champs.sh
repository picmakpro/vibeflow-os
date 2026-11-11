#!/usr/bin/env bash
# test-cockpit-projet-champs.sh — champs structurés du graphe Projet (Phase 80, plan 80-03, FORM-06, FORM-07 part données), node seul, sans navigateur :
# avancement et exigences sur la phase (PC1), vague sur le plan (PC2), contrat cockpit-project@1 (PC3), backlog sans statut au pied (PC4),
# mutants M-VIE, M-STATUTS, M-AUTRE-LIGNE.
# Fixtures écrites dans mktemp ; socle commun : projet-commun.sh. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"
REL=plugin/cockpit/scripts/vf-cockpit-interface.json

# ---------- PC1 — avancement et exigences d'une phase ----------
L1="$WORK/pc1"; B="$L1/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v1.0 MVP** - Phases 1-3 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet
- [ ] **Phase 3: Liens** - troisième jet
- [ ] **Phase 4: Reprise** - quatrième jet
MD
wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **FORM-01**: premier
- [x] **FORM-02**: second
- [ ] **FORM-03**: troisième

| FORM-01 | Phase 1 | Complete |
| FORM-02 | Phase 1 | Complete |
| FORM-03 | Phase 1 | Pending |
MD
wr "$B/STATE.md" <<'MD'
---
status: executing
current_phase: 3
---
MD
for n in 01 02; do printf '<objective>Plan %s</objective>\n' "$n" | wr "$B/phases/01-socle/01-$n-PLAN.md"; echo ok > "$B/phases/01-socle/01-$n-SUMMARY.md"; done
printf '<objective>Plan liens</objective>\n' | wr "$B/phases/03-liens/03-01-PLAN.md"
wr "$B/missions/MISSION-LIENS.dag.json" <<'JSON'
{"phase":"3","nodes":[{"id":"a","step":"s","deps":[],"status":"done"},{"id":"b","step":"s","deps":["a"],"status":"running"}]}
JSON
for n in 01 02 03; do printf '<objective>Reprise %s</objective>\n' "$n" | wr "$B/phases/04-reprise/04-$n-PLAN.md"; done
echo ok > "$B/phases/04-reprise/04-01-SUMMARY.md"; echo ok > "$B/phases/04-reprise/04-99-SUMMARY.md"   # 1 plan sur 3, un correctif
graph "$L1" "$WORK/c1.json"
echo "=== PC1 — avancement et exigences structurés sur la phase ==="
c1() { G "$WORK/c1.json" "$1"; }
nd() { c1 "(n=>$2)(j.nodes.find(x=>x.id==='$1'))"; }   # nd <id> <expression sur n>
AV1='[n.avancement?.etat,JSON.stringify(n.avancement?.plans),JSON.stringify(n.exigences)].join("|")'
assert_eq "PC1.1 — ph-1 : etat fait, plans 2/2, exigences 2 sur 3 (compte asymétrique)" "$(nd ph-1 "$AV1")" \
  'fait|{"faits":2,"total":2}|{"faits":2,"total":3}'
assert_eq "PC1.2 — témoin d'invariance : pied et statut de ph-1 inchangés" "$(nd ph-1 'n.foot+"|"+n.st')" "2/2 plans · 1 exigence non cochée|done"
AV3='[n.avancement?.plans?.total,n.avancement?.reste?.includes("cadrage"),JSON.stringify(n.exigences)].join("|")'
assert_eq "PC1.3 — ph-2 sans dossier : plans 0, reste « cadrage », exigences 0 sur 0" "$(nd ph-2 "$AV3")" '0|true|{"faits":0,"total":0}'
AV5='[n.avancement?.version,n.avancement?.etat,JSON.stringify(n.avancement?.plans),n.avancement?.correctifs].join("|")'
assert_eq "PC1.5 — ph-4 asymétrique : version 2, en-cours, plans 1 sur 3, un correctif" "$(nd ph-4 "$AV5")" '2|en-cours|{"faits":1,"total":3}|1'
CLES='/"(vie|tenu|stale|ttl|owner|progressAgeS)":/.test(JSON.stringify(j))'
MI='{"nom":"MISSION-LIENS","etat":"running"}'
assert_eq "PC1.4 — mission d'une phase vivante = {nom, etat}, aucune clé de verrou dans le graphe" \
  "$(nd ph-3 'JSON.stringify(n.avancement?.mission)')|$(c1 "$CLES")" "$MI|false"

# ---------- outils node de la suite ----------
cat > "$AUX/pl.mjs" <<'JS'
// pl.mjs <dossier de modules> <racine du lab> : ph.plans de chaque phase lue par readPlanning
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-planning.mjs')).href);
console.log(JSON.stringify([...m.readPlanning(process.argv[3]).phases.values()].map((ph) => ph.plans)));
JS
cat > "$AUX/qm.mjs" <<'JS'
// qm.mjs <dossier de modules> <racine du lab> : graphe Projet construit par la COPIE des modules (mutants)
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-project.mjs')).href);
console.log(JSON.stringify(m.buildProjectGraph(process.argv[3])));
JS
cat > "$AUX/stok.mjs" <<'JS'
// stok.mjs <contrat> <graphe> : `recette` est-il dans statuts de cockpit-project@1, le graphe en émet-il, et quels `st` émis n'y figurent pas
import fs from 'node:fs';
const ok = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).schemas['vibeflow/cockpit-project@1'].statuts;
const g = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const emis = new Set([...g.nodes, ...g.files].map((x) => x.st).filter(Boolean));
console.log(`${ok.includes('recette')}|${emis.has('recette')}|${[...emis].filter((s) => !ok.includes(s)).join(',')}`);
JS
cat > "$AUX/ifc.mjs" <<'JS'
// ifc.mjs <contrat> : forme du bloc cockpit-project@1 (clés facultatives, ordre, requis inchangés, version du fichier)
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); const b = j.schemas['vibeflow/cockpit-project@1']; const k = Object.keys(b);
console.log([JSON.stringify(b.optionnels), k.indexOf('optionnels') - k.indexOf('statuts'), JSON.stringify(b.noeud),
  JSON.stringify(b.element), JSON.stringify(b.meta), j.version].join('|'));
JS
cat > "$AUX/ecart.mjs" <<'JS'
// ecart.mjs <avant> <apres> : diff de lignes par préfixe et suffixe communs ; « <retirées>-|<ajoutées>+|<classe> »
import fs from 'node:fs';
const A = fs.readFileSync(process.argv[2], 'utf8').split('\n'), Bl = fs.readFileSync(process.argv[3], 'utf8').split('\n');
let p = 0; while (p < A.length && p < Bl.length && A[p] === Bl[p]) p++;
let q = 0; while (q < A.length - p && q < Bl.length - p && A[A.length - 1 - q] === Bl[Bl.length - 1 - q]) q++;
const r = A.slice(p, A.length - q), a = Bl.slice(p, Bl.length - q);
const s = A.findIndex((l) => l.trim() === '"vibeflow/cockpit-project@1": {');
let e = A.findIndex((l, i) => i > s && /^ {4}"[^"]+": [{[]/.test(l)); if (e < 0) e = A.length;
let json = true; try { JSON.parse(Bl.join('\n')); } catch { json = false; }
let c = 'hors-ancre';
if (!r.length && !a.length) c = 'aucun-changement';
else if (json && s >= 0 && r.length === 1 && a.length === 2 && p > s && p < e && /^\s*"statuts":/.test(r[0])
  && /^\s*"statuts":/.test(a[0]) && a[0].includes('"recette"') && /^\s*"optionnels":/.test(a[1])
  && a[1].includes('"noeud"') && a[1].includes('"element"')) c = 'ancre-statuts';
console.log(`${r.length}-|${a.length}+|${c}`);
JS
cat > "$AUX/mutlien.mjs" <<'JS'
// mutlien.mjs <entrée> <sortie> : sur une copie, la ligne "lien" du bloc cockpit-project@1 (par sa position) devient un autre JSON valide
import fs from 'node:fs';
const L = fs.readFileSync(process.argv[2], 'utf8').split('\n'); const s = L.findIndex((l) => l.trim() === '"vibeflow/cockpit-project@1": {');
const i = L.findIndex((l, k) => k > s && l.trim().startsWith('"lien":'));
if (s < 0 || i < 0) { console.log('ancre absente'); process.exit(1); }
L[i] = '      "lien": { "requis": ["a", "b"] },'; fs.writeFileSync(process.argv[3], L.join('\n')); console.log('muté');
JS
cat > "$AUX/ancre.mjs" <<'JS'
// ancre.mjs <entrée> <sortie> : sur une copie, retire `recette` de la ligne "statuts" du bloc cockpit-project@1 (mutant M-STATUTS)
import fs from 'node:fs';
const t = fs.readFileSync(process.argv[2], 'utf8'); const de = '["done", "active", "recette", "todo", "blocked"]';
if (!t.includes(de)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(process.argv[3], t.replace(de, '["done", "active", "todo", "blocked"]')); console.log('muté');
JS

# ---------- PC2 — vague du plan, posée par readPlanning ----------
L2="$WORK/pc2"; B="$L2/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - premier jet
MD
printf -- '---\nwave: 1\n---\n<objective>Un</objective>\n' | wr "$B/phases/01-socle/01-01-PLAN.md"
printf -- '---\nwave: 2\n---\n<objective>Deux</objective>\n' | wr "$B/phases/01-socle/01-02-PLAN.md"
printf -- '<objective>Trois</objective>\n' | wr "$B/phases/01-socle/01-03-PLAN.md"
graph "$L2" "$WORK/c2.json"
echo "=== PC2 — vague du plan ==="
PL="$(node "$AUX/pl.mjs" "$SCRIPTS" "$L2")"
PF='j.files.filter(f=>/-PLAN\.md$/.test(f.p))'
VG="$(G "$WORK/c2.json" "$PF.map(f=>f.vague)")|$(G "$WORK/c2.json" "$PF.map(f=>f.foot).join(',')")"
assert_eq "PC2.1 — ph.plans trié (vague 1, 2, null), même vague sur l'élément du graphe, pied du plan inchangé" "$PL|$VG" \
  '[[{"id":"01-01","fichier":"01-01-PLAN.md","vague":1},{"id":"01-02","fichier":"01-02-PLAN.md","vague":2},'\
'{"id":"01-03","fichier":"01-03-PLAN.md","vague":null}]]|[1,2,null]|vague 1,vague 2,vague ?'

L5="$WORK/pc2b"; B="$L5/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - premier jet
MD
i=0; for w in 0x10 1e1 0 3; do i=$((i+1)); printf -- '---\nwave: %s\n---\n<objective>P</objective>\n' "$w" | wr "$B/phases/01-socle/01-0$i-PLAN.md"; done
VAG='JSON.stringify(m[0].map((x)=>x.vague))'
assert_eq "PC2.2 — wave 0x10, 1e1 et 0 donnent null, 3 donne 3 (chiffres décimaux seuls, T-80-06)" \
  "$(node "$AUX/pl.mjs" "$SCRIPTS" "$L5" | node -e "const m=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log($VAG)")" "[null,null,null,3]"

# ---------- PC3 — contrat cockpit-project@1 ----------
L3="$WORK/pc3"; B="$L3/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - premier jet
MD
printf -- '<objective>Un</objective>\n' | wr "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
printf '**Statut :** À FAIRE\n' | wr "$B/phases/01-socle/01-RECETTE-HUMAINE.md"
graph "$L3" "$WORK/c3.json"
echo "=== PC3 — contrat ==="
assert_eq "PC3.1 — « recette » dans statuts, émis par le lab à recetter, tout st émis y figure" \
  "$(node "$AUX/stok.mjs" "$IFACE" "$WORK/c3.json")" "true|true|"
assert_eq "PC3.2 — optionnels juste après statuts ; requis, meta et version inchangés" "$(node "$AUX/ifc.mjs" "$IFACE")" \
  '{"noeud":["avancement","exigences"],"element":["vague"]}|1|{"requis":["id","label","kind"]}|{"requis":["p","n","name"]}'\
'|{"requis":["vfTab","vf","kindLabels"]}|1'
# base du diff : le commit du plan lui-même (L non vide) ou, avant lui, HEAD et l'arbre ; tout échec git = HISTORIQUE-ABSENT, jamais sauté
base_contrat() { # écrit $WORK/avant.json et $WORK/apres.json
  local top l o n; top="$(git -C "$SCRIPTS" rev-parse --show-toplevel 2>/dev/null)" || return 1
  l="$(git -C "$SCRIPTS" log --full-history -F --grep='(80-03)' --format=%H -- "$top/$REL" 2>/dev/null)" || return 1
  if [ -n "$l" ]; then o="$(printf '%s\n' "$l" | tail -n 1)"; n="$(printf '%s\n' "$l" | head -n 1)"
    git -C "$top" show "$o^:$REL" > "$WORK/avant.json" 2>/dev/null && git -C "$top" show "$n:$REL" > "$WORK/apres.json" 2>/dev/null
  else git -C "$top" show "HEAD:$REL" > "$WORK/avant.json" 2>/dev/null && cp "$top/$REL" "$WORK/apres.json"; fi
}
ecart_contrat() { node "$AUX/ecart.mjs" "$1" "$2"; }
if base_contrat && [ -s "$WORK/avant.json" ] && [ -s "$WORK/apres.json" ]; then
  ECART="$(ecart_contrat "$WORK/avant.json" "$WORK/apres.json")"; else ECART=HISTORIQUE-ABSENT; fi
assert_eq "PC3.3 — le contrat ne change que sur les lignes \"statuts\" et \"optionnels\" de cockpit-project@1 (diff contre la base)" \
  "$ECART" "1-|2+|ancre-statuts"

# ---------- PC4 — le backlog ne répète plus son statut au pied ----------
L4="$WORK/pc4"; B="$L4/.planning"
wr "$B/BACKLOG.md" <<'MD'
## Un — DIFFÉRÉ

Premier texte.

## Deux — INVESTIGUÉ

Second texte.
MD
graph "$L4" "$WORK/c4.json"
echo "=== PC4 — backlog ==="
BK='j.files.filter(f=>f.n==="backlog").map(f=>"["+f.foot+"]"+f.st).join(",")'
assert_eq "PC4.1 — pied vide et statut inchangé : DIFFÉRÉ todo, INVESTIGUÉ done" "$(G "$WORK/c4.json" "$BK")" "[]todo,[]done"

# ---------- mutants (copies dans $WORK, jamais le module) ----------
echo "=== Mutants ==="
if mut7 vie vf-cockpit-project.mjs 'mission: av.mission ? { nom: av.mission.nom, etat: av.mission.etat } : null' 'mission: av.mission' > /dev/null; then
  VF_COCKPIT_SCRIPTS_DIR="$WORK/locks" node "$AUX/qm.mjs" "$WORK/mut-vie" "$L1" > "$WORK/mv.json" 2>/dev/null
  MV="$(G "$WORK/mv.json" "$CLES")|$(G "$WORK/mv.json" 'j.nodes.find(x=>x.id==="ph-3")?.avancement?.mission?.nom')"
else MV=ancre-absente; fi
assert_eq "M-VIE — le mutant rougit PC1.4 : la mission projetée entière fait sortir une clé de verrou" "$MV" "true|MISSION-LIENS"
mkdir -p "$WORK/mut-st"
if node "$AUX/ancre.mjs" "$IFACE" "$WORK/mut-st/iface.json" > /dev/null; then
  MS="$(node "$AUX/stok.mjs" "$WORK/mut-st/iface.json" "$WORK/c3.json")"; else MS=ancre-absente; fi
assert_eq "M-STATUTS — le mutant rougit PC3.1 : « recette » retiré de statuts, le graphe en émet encore" "$MS" "false|true|recette"
if [ -s "$WORK/avant.json" ] && node "$AUX/mutlien.mjs" "$WORK/apres.json" "$WORK/mut-lien.json" > /dev/null; then
  ML="$(ecart_contrat "$WORK/avant.json" "$WORK/mut-lien.json")"; else ML=HISTORIQUE-ABSENT; fi
assert_eq "M-AUTRE-LIGNE — le mutant rougit PC3.3 : la ligne \"lien\" du bloc cockpit-project@1 modifiée (valeur exacte)" "$ML" "2-|3+|hors-ancre"

# mutants des champs : copie de vf-cockpit-project.mjs, une ligne mutée ; le mutant rougit si la valeur épinglée diffère de l'attendu (graphe non vide exigé)
mutchamp() { # nom ancre remplacement id expression attendu
  local got; mut7 "$1" vf-cockpit-project.mjs "$2" "$3" > /dev/null || { echo ancre-absente; return; }
  VF_COCKPIT_SCRIPTS_DIR="$WORK/locks" node "$AUX/qm.mjs" "$WORK/mut-$1" "$L1" > "$WORK/m-$1.json" 2>/dev/null
  got="$(G "$WORK/m-$1.json" "(n=>$5)(j.nodes.find(x=>x.id==='$4'))")"
  if [ -z "$got" ] || [ "$got" = "|||" ]; then echo vide; elif [ "$got" = "$6" ]; then echo non-rouge; else echo rougit; fi
}
A5='2|en-cours|{"faits":1,"total":3}|1'
assert_eq "M-PLANS — le mutant rougit PC1.5 : plans { faits: total, total }" \
  "$(mutchamp plans 'plans: { ...av.plans }' 'plans: { faits: av.plans.total, total: av.plans.total }' ph-4 "$AV5" "$A5")" rougit
assert_eq "M-CORR — le mutant rougit PC1.5 : correctifs figé à 0" "$(mutchamp corr 'correctifs: av.correctifs,' 'correctifs: 0,' ph-4 "$AV5" "$A5")" rougit
assert_eq "M-VERS — le mutant rougit PC1.5 : version null" "$(mutchamp vers 'version: av.version' 'version: null' ph-4 "$AV5" "$A5")" rougit
assert_eq "M-ETAT — le mutant rougit PC1.5 : etat figé à fait" "$(mutchamp etat 'etat: av.etat, plans' 'etat: "fait", plans' ph-4 "$AV5" "$A5")" rougit
assert_eq "M-EXIG — le mutant rougit PC1.1 : compte des cochées inversé (!r.done)" \
  "$(mutchamp exig 'faits: reqs.filter((r) => r.done).length' 'faits: reqs.filter((r) => !r.done).length' \
  ph-1 "$AV1" 'fait|{"faits":2,"total":2}|{"faits":2,"total":3}')" rougit
if mut7 vague vf-cockpit-planning.mjs "/^\\d+\$/.test(w ?? '') ? Number(w) : 0" 'Number(w)' > /dev/null; then
  MG="$(node "$AUX/pl.mjs" "$WORK/mut-vague" "$L5" | node -e "const m=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log($VAG)")"
else MG=ancre-absente; fi
assert_eq "M-VAGUE — le mutant rougit PC2.2 : Number(wave) laisse passer 0x10 et 1e1" "$MG" "[16,10,null,3]"

bilan
