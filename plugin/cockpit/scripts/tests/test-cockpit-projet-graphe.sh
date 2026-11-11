#!/usr/bin/env bash
# test-cockpit-projet-graphe.sh — graphe Projet du cockpit sur tout lab GSD (CKPT-06), côté moteur et parseurs, sans navigateur : plat au gabarit GSD (P1), partitionné (P2), sans liste de jalons avec missions (P3),
# contrat et absence de nom de compartiment (P4), identité d'une phase = (compartiment, numéro) (P5), dérive de format (P6, P7), visite propre à l'onglet Projet lue par la CLI (O6.1-O6.8), vérité des états (R1),
# panneau de phase et visite (R2), panneau « Format de la planification » côté données (R3.1-R3.12), mission abandonnée (P-VIE), parseurs tolérants (P8), corrections de revue (P9), croissance du code réel et mutants
# cr-paren, cr-backlog, cr-objectif (P10.1, P10.2, P10.4, P10.5).
# Découpe de l'ancien test-cockpit-projet.sh (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07) : la visite dans Chrome vit dans test-cockpit-projet-visite.sh, le mutant de la coupe de valeur (P10.3) dans
# test-cockpit-projet-croissance.sh ; le socle commun est projet-commun.sh. Fixtures écrites par la suite dans mktemp.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"

# ---------- P1 — lab plat au gabarit GSD ----------
L1="$WORK/p1"; B="$L1/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle
**Depends on**: Nothing (first phase)

### Phase 2: Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **AUTH-01**: se connecter

| AUTH-01 | Phase 1 | Complete |
MD
wr "$B/STATE.md" <<'MD'
---
status: executing
current_phase: 2
---
MD
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
graph "$L1" "$WORK/g1.json"
echo "=== P1 — lab plat au gabarit GSD ==="
assert_eq "P1.1 — ph-1 done, ph-2 todo (le STATE ne pilote plus le statut : aucun plan fait en phase 2, CKPT-18)" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>/^ph-\d$/.test(n.id)).map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:todo"
assert_eq "P1.2 — plan 01-01 done, 02-01 todo (aucun nœud running ne le désigne, CKPT-18)" "$(G "$WORK/g1.json" 'j.files.filter(f=>/^0\d-01 /.test(f.name)).map(f=>f.name.slice(0,5)+":"+f.st).join(",")')" "01-01:done,02-01:todo"
assert_eq "P1.3 — lien ph-1 vers ph-2 de type import" "$(G "$WORK/g1.json" 'j.links.filter(l=>l.a==="n:ph-1"&&l.b==="n:ph-2"&&l.k==="import").length')" "1"
assert_eq "P1.4 — exigence AUTH-01 sous ph-1.req" "$(G "$WORK/g1.json" 'j.files.filter(f=>f.n==="ph-1.req").map(f=>f.name).join(",")')" "AUTH-01"
assert_eq "P1.5 — jalon v1.0 MVP actif, pied « 1 clos · 0 à recetter · 1 à faire · 50 % » (CKPT-16)" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>n.id==="ms-v1.0-mvp").map(n=>n.st+"|"+n.foot).join(",")')" "active|1 clos · 0 à recetter · 1 à faire · 50 %"
assert_eq "P1.6 — meta.vf.phase = 2" "$(G "$WORK/g1.json" 'j.meta.vf.phase')" "2"

# ---------- P2 — lab partitionné, deux compartiments, numéros uniques ----------
L2="$WORK/p2"; B="$L2/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **alpha-v1** — Phases 10-11 (en cours)

## Phases

- [ ] Phase 10: Un
- [ ] Phase 11: Deux

### Phase 10: Un
**Goal:** le but
MD
wr "$B/workstreams/beta/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **beta-v1** — Phases 20 (en cours)

## Phases

- [ ] Phase 20: Trois
MD
echo alpha > "$B/active-workstream"
printf -- '---\nmilestone: alpha-v1\ncurrent_phase: 10\nstatus: executing\n---\n' | wr "$B/workstreams/alpha/STATE.md"
wr "$B/workstreams/alpha/phases/VFDO-10-x/10-01-PLAN.md" <<'MD'
<objective>Un plan</objective>
MD
graph "$L2" "$WORK/g2.json"
echo "=== P2 — lab partitionné ==="
assert_eq "P2.1 — les deux jalons sont présents" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.id).sort().join(",")')" "ms-alpha-v1,ms-beta-v1"
assert_eq "P2.2 — aucun lien d'enchaînement inter-compartiments" "$(G "$WORK/g2.json" 'j.links.filter(l=>l.k==="event").length')" "0"
assert_eq "P2.3 — meta.vf lu dans le STATE du compartiment actif" "$(G "$WORK/g2.json" 'j.meta.vf.milestone')" "alpha-v1"
assert_eq "P2.4 — identifiants de phase restent ph-10, ph-11, ph-20" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-10,ph-11,ph-20"
assert_eq "P2.5 — le plan du dossier préfixé est rattaché à ph-10" "$(G "$WORK/g2.json" 'j.files.filter(f=>f.n==="ph-10").length')" "1"

# ---------- P3 — lab plat sans jalons, avec missions ----------
L3="$WORK/p3"; B="$L3/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Seule** - une phase
MD
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"blocked"},{"id":"b","step":"s","deps":[],"status":"ready"},{"id":"c","step":"s","deps":[],"status":"running"},{"id":"d","step":"s","deps":[],"status":"done"},{"id":"e","step":"s","deps":[],"status":"failed"}]}
JSON
printf '{"nodes":[' | wr "$B/missions/TRONQUE.dag.json"
graph "$L3" "$WORK/g3.json"; RC3=$?
echo "=== P3 — sans liste de jalons, missions ==="
assert_eq "P3.1 — graphe rendu malgré le DAG tronqué" "$RC3" "0"
assert_eq "P3.2 — jalon synthétique ms-phases « Phases »" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="ms-phases").map(n=>n.label).join(",")')" "Phases"
assert_eq "P3.3 — statuts de DAG todo,todo,active,done,blocked" "$(G "$WORK/g3.json" 'j.files.filter(f=>f.n==="dag-MISSION-1").map(f=>f.st).join(",")')" "todo,todo,active,done,blocked"
assert_eq "P3.4 — le DAG tronqué est ignoré" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="dag-TRONQUE").length')" "0"

# ---------- P5 — invariant d'identité : deux compartiments à « Phase 1 » ----------
L5="$WORK/p5"; B="$L5/.planning/workstreams"
for w in un deux; do
  wr "$B/$w/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Premiere** - une phase
MD
done
echo ok > /dev/null
wr "$B/un/phases/01-a/01-01-PLAN.md" <<'MD'
<objective>Plan un</objective>
MD
wr "$B/deux/phases/01-b/01-01-PLAN.md" <<'MD'
<objective>Plan deux</objective>
MD
printf -- '- [ ] **UN-01**: exigence un\n\n| UN-01 | Phase 1 | Pending |\n' | wr "$B/un/REQUIREMENTS.md"
printf -- '- [ ] **DEUX-01**: exigence deux\n\n| DEUX-01 | Phase 1 | Pending |\n' | wr "$B/deux/REQUIREMENTS.md"
graph "$L5" "$WORK/g5.json"
echo "=== P5 — identité (compartiment, numéro) ==="
assert_eq "P5.1 — deux phases distinctes" "$(G "$WORK/g5.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-1@deux,ph-1@un"
assert_eq "P5.2 — chaque plan dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.endsWith("PLAN.md")).map(f=>f.n+"="+f.p.split("/")[2]).sort().join(",")')" "ph-1@deux=deux,ph-1@un=un"
assert_eq "P5.3 — chaque exigence dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.startsWith("req/")).map(f=>f.n+"="+f.name).sort().join(",")')" "ph-1@deux.req=DEUX-01,ph-1@un.req=UN-01"

# ---------- P6 — ROADMAP à la française : lu malgré la dérive, dérive détectée, correctif proposé ----------
# Cas réel (lab Scroll-Off, 2026-11-03) : « Phase N : » partout, aucune phase lue, carte vide sans explication.
L6="$WORK/p6"; B="$L6/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Phases

- [x] **Phase 1 : Socle** — premier jet
- [ ] **Phase 2 : Écran** — second jet

## Phase Details

### Phase 1 : Socle
**Goal**: Poser le socle
**Depends on**: rien · **Parallélisable avec**: Phase 2

### Phase 2 : Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/STATE.md" <<'MD'
---
milestone: v2.0
status: executing
---
MD
graph "$L6" "$WORK/g6.json"
echo "=== P6 — dérive de format ==="
assert_eq "P6.1 — « Phase N : » lu : deux phases, ph-1 done" "$(G "$WORK/g6.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:todo"
assert_eq "P6.2 — « rien · **Parallélisable avec**: Phase 2 » n'est pas une dépendance à 2" "$(G "$WORK/g6.json" 'j.links.filter(l=>l.k==="import").map(l=>l.a+">"+l.b).join(",")')" "n:ph-1>n:ph-2"
assert_eq "P6.3 — règles signalées dans meta.vf.drift" "$(G "$WORK/g6.json" 'j.meta.vf.drift.regles.map(r=>r.regle+":"+r.n).join(",")')" "phase-deux-points:4,depends-on:1,jalons-absents:1,phase-courante-absente:1"
assert_eq "P6.4 — témoin : le lab au gabarit GSD (P1) est conforme" "$(G "$WORK/g1.json" 'j.meta.vf.drift.regles.length')" "0"
git -C "$L6" init -q && git -C "$L6" add -A && git -C "$L6" -c user.email=t@t -c user.name=t commit -qm init
node "$DR" "$L6" --diff > "$WORK/p6.patch"
avant="$(cd "$L6" && git hash-object .planning/ROADMAP.md)"
assert_eq "P6.5 — le détecteur n'écrit rien sur disque" "$(cd "$L6" && git status --porcelain | wc -l | tr -d ' ')|$(cd "$L6" && git hash-object .planning/ROADMAP.md)" "0|$avant"
assert_eq "P6.6 — le correctif proposé s'applique (git apply --check)" "$(git -C "$L6" apply --check "$WORK/p6.patch" && echo ok)" "ok"
git -C "$L6" apply "$WORK/p6.patch"
graph "$L6" "$WORK/g6b.json"
assert_eq "P6.7 — après correctif : reste seulement la phase courante, non devinable" "$(G "$WORK/g6b.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "phase-courante-absente"
assert_eq "P6.8 — après correctif : jalon v2.0 réel, même lecture des phases" "$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.label).join(",")')|$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "v2.0|ph-1:done,ph-2:todo"
printf -- '- [ ] Phase 1 sans séparateur\n' | wr "$L6/x/.planning/ROADMAP.md"
assert_eq "P6.9 — phases citées mais illisibles : niveau bloquant" "$(node "$DR" "$L6/x" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).constats.filter(c=>c.niveau==="bloquant").map(c=>c.regle).join(",")))')" "phases-illisibles"

# P6.10-14 — relecture adverse SOBR-04 de v2.75.1 : coupe au champ suivant, gras dans la valeur, « aucune » suivi d'un ordre,
# correctif sur un ROADMAP sans « ## Phases » et sans saut de ligne final, statut de jalon clos
L7="$WORK/p7"; B="$L7/.planning"; mkdir -p "$B"
printf '%s\n' '# Roadmap' '' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2: Deux** - b' '- [ ] **Phase 3: Trois** - c' '- [ ] **Phase 4: Quatre** - d' '- [ ] **Phase 5: Cinq** - e' '- [ ] **Phase 6: Six** - f' '- [ ] **Phase 10: Dix** - j' '' \
  '### Phase 3: Trois' '**Depends on**: Phase 1 · **Parallélisable avec**: Phase 2' '' \
  '### Phase 4: Quatre' '**Depends on**: Phase 1 **et Phase 2** (ordre)' '' \
  '### Phase 5: Cinq' '**Depends on**: aucune dépendance de code ; après 4' '' \
  '### Phase 6: Six' '**Depends on:** Phase 3 (la lib de lecture). La Phase 4 en dépend et consommera l objet avancement (P69-D-10).' '### Phase 10: Dix' '**Depends on**: Nothing' > "$B/ROADMAP.md"
printf -- '---\nstatus: milestone_complete\n---\n' > "$B/STATE.md"
graph "$L7" "$WORK/g7.json"
deps() { G "$WORK/g7.json" "j.links.filter(l=>l.k===\"import\"&&l.b===\"n:ph-$1\").map(l=>l.a.slice(5)).sort().join(\",\")"; }
assert_eq "P6.10 — « Phase 1 · **Parallélisable avec**: Phase 2 » : dépend de 1 seulement" "$(deps 3)" "1"
assert_eq "P6.11 — « Phase 1 **et Phase 2** » : le gras ne coupe pas la valeur" "$(deps 4)" "1,2"
assert_eq "P6.12 — « aucune dépendance de code ; après 4 » garde 4" "$(deps 5)" "4"
assert_eq "P6.12b — « Phase 3 (…). La Phase 4 en dépend (P69-D-10) » : dépend de 3 seulement, ni la dépendante 4 ni le 10 d'un identifiant de décision" "$(deps 6)" "3"
assert_eq "P6.13 — statut milestone_complete : pas de phase-courante-absente" "$(G "$WORK/g7.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "depends-on,jalons-absents"
printf '%s' "$(cat "$B/ROADMAP.md")" > "$B/ROADMAP.md"   # sans saut de ligne final
node "$DR" "$L7" --diff > "$WORK/p7.patch"
assert_eq "P6.14 — correctif sans « ## Phases » ni saut final : appliqué, puis conforme" "$( (cd "$L7" && git apply "$WORK/p7.patch") && node "$DR" "$L7" | head -1)" "Format de la planification conforme."

# ---------- P7 — la détection de dérive ne lit aucun fichier non régulier du lab (famille de read(), merge 69 / main v1.0.1) ----------
# Un ROADMAP en tube FIFO ou un STATE lié à /dev/zero ne doit ni bloquer buildProjectGraph ni remplir la mémoire. Enfant node borné par SIGKILL
# (harnais de A14 de test-cockpit-avancement.sh), tubes et liens supprimés dans tous les cas. Mutant : le `read` local non borné de main est rétabli dans une copie.
echo "=== P7 — drift : lecture bornée des fichiers du lab ==="
QB7() { node "$AUX/borne.mjs" 6000 "$AUX/q.mjs" "$1" project "$2" > "$WORK/qb7.json"; G "$WORK/qb7.json" "(j.timedOut?\"bloqué\":\"rendu\")+\"|\"+(()=>{try{return JSON.parse(j.out).meta.vf.counts.phases}catch{return \"illisible\"}})()"; }
L70="$WORK/lab-p70"; L71="$WORK/lab-p71"; L72="$WORK/lab-p72"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L70/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L70/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L70" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L71/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L71/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L71" init -q
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$L72/.planning/ROADMAP.md"; printf '<objective>Plan</objective>\n' | wr "$L72/.planning/phases/01-a/01-01-PLAN.md"; git -C "$L72" init -q
assert_eq "P7.0 — contrôle positif : sans fichier spécial, le graphe se rend (1 phase, enfant borné)" "$(QB7 "$SCRIPTS" "$L70")" "rendu|1"
mut7 driftlocal vf-cockpit-drift.mjs "import { readPlanning, fm, read } from './vf-cockpit-planning.mjs';" "import { readPlanning, fm } from './vf-cockpit-planning.mjs';
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };" > "$WORK/ancre-drift.txt"
rm -f "$L71/.planning/ROADMAP.md"; mkfifo "$L71/.planning/ROADMAP.md"
rm -f "$L72/.planning/STATE.md"; ln -s /dev/zero "$L72/.planning/STATE.md"
R71="$(QB7 "$SCRIPTS" "$L71")"; M71="$(QB7 "$WORK/mut-driftlocal" "$L71")"
R72="$(QB7 "$SCRIPTS" "$L72")"
rm -f "$L71/.planning/ROADMAP.md" "$L72/.planning/STATE.md"
assert_eq "P7.1 — un ROADMAP en tube FIFO ne bloque pas le graphe Projet (détection de dérive comprise)" "$R71" "rendu|0"
assert_eq "P7.2 — un STATE lié à /dev/zero ne bloque pas le graphe Projet (non-régression ; stateFile le refuse déjà : seul le tube FIFO du ROADMAP discrimine, P7.1 et P7.3)" "$R72" "rendu|1"
assert_eq "P7.3 — mutant (read local non borné rétabli, ancre présente) : le tube FIFO bloque, détecté" "$(cat "$WORK/ancre-drift.txt")|$M71" "muté|bloqué|illisible"
assert_eq "P7.5 — vf-cockpit-drift.mjs n'a plus de lecture à lui (read partagé de planning)" "$(grep -c 'const read = ' "$SCRIPTS/vf-cockpit-drift.mjs")" "0"

# ---------- P4 — contrat, syntaxe, aucun nom de compartiment de ce dépôt ----------
echo "=== P4 — contrat et généralité ==="
for n in 1 2 3 5 6; do assert_eq "P4.$n — graphe $n conforme au contrat" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g$n.json")" "OK"; done
BAD=0; for f in "$SCRIPTS"/vf-cockpit-*.mjs; do node --check "$f" || BAD=$((BAD+1)); done
assert_eq "P4.6 — node --check passe sur chaque .mjs du socle" "$BAD" "0"
printf '%s\n' "const w = 'fiabilite';" > "$WORK/temoin.mjs"
assert_eq "P4.7 — témoin positif : le contrôle de noms voit un nom codé en dur" "$(cat "$WORK/temoin.mjs" | grep -cE 'fiabilite|gouvernance')" "1"
assert_eq "P4.8 — aucun nom de compartiment de ce dépôt dans les sources du socle" "$(cat "$SCRIPTS"/vf-cockpit-*.mjs | grep -cE 'fiabilite|gouvernance')" "0"

# O6 (70-08, UIFN-05, P70-D-02 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; P70-D-13 : choix du manager) : l'onglet Projet a sa propre visite (champ `tour` du graphe) —
# le jalon, la phase en cours, les missions, au travail — au lieu du repli sur « La base de code ». O6.1 à O6.4 et O6.6 à O6.8 sans navigateur (graphe lu par la CLI) ; O6.5 dans Chrome (plus bas).
echo "=== O6 — la visite propre à l'onglet Projet : contenu du champ tour ==="
L8="$WORK/p8"; B="$L8/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle

### Phase 2: Écran
**Goal**: Poser l'écran
MD
printf -- '---\nstatus: executing\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
wr "$B/missions/MISSION-ECRAN.dag.json" <<'JSON'
{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"done"},{"id":"b","step":"s","deps":["a"],"status":"running"}]}
JSON
graph "$L8" "$WORK/g8.json"
L9="$WORK/p9"; mkdir -p "$L9/.planning"; graph "$L9" "$WORK/g9.json"
t8() { G "$WORK/g8.json" "$1"; }
assert_eq "O6.1 — un lab GSD complet : le graphe Projet porte une visite d'au moins deux étapes (jalon, phase en cours, missions, au travail)" "$(t8 'j.tour.length>=2')|$(t8 'j.tour.length')" "true|4"
assert_eq "O6.2 — chaque étape vise une carte du graphe (n:<id> existant) ou la racine avec une cible" "$(t8 'j.tour.filter((s)=>!((s.ref==="root"&&s.cible)||j.nodes.some((n)=>"n:"+n.id===s.ref))).map((s)=>s.title).join(",")')" ""
assert_eq "O6.3 — aucune étape ne parle de « La base de code » ni « dans le code »" "$(t8 'j.tour.filter((s)=>/base de code|dans le code|codebase/i.test([s.kicker,s.title,s.note].join(" "))).length')" "0"
assert_eq "O6.4 — sur un lab sans STATE.md, aucune étape avec « ? », « undefined », « null » ni champ vide" "$(G "$WORK/g3.json" 'j.tour.filter((s)=>[s.title,s.note].some((x)=>!x||/\?|undefined|null/.test(x))).length')|$(G "$WORK/g3.json" 'j.tour.length>=2')" "0|true"
assert_eq "O6.6 — les étapes dans l'ordre : le jalon en cours, la phase 2 (statut lisible), la mission, au travail (#vf-lock)" "$(t8 'j.tour.map((s)=>s.ref+(s.cible?"+"+s.cible:"")).join(" ")')" "n:ms-v1.0-mvp n:ph-2 n:dag-MISSION-ECRAN root+#vf-lock"
assert_eq "O6.7 — l'état de la phase est celui de sa CARTE (« en cours » : un plan non fait, une mission vivante ; PU-G-093, ce n'est plus le « en exécution » de STATE.md), sans « périmé » quand STATE.md s'accorde, le jalon dit les phases faites (« 1 sur 2 »), l'étape « au travail » nomme l'onglet Équipe" "$(t8 '[/en cours/.test(j.tour[1].note),!/périmé|en exécution/.test(j.tour[1].note),/1 sur 2/.test(j.tour[0].note),/Équipe/.test(j.tour[3].note)].join(",")')" "true,true,true,true"
assert_eq "O6.8 — un lab sans planning : visite vide (le repli de 70-07 s'applique, sans parler de code)" "$(G "$WORK/g9.json" 'j.tour.length')" "0"

# R1 (lot 6 « Projet », étape PR1 « vérité des états », 2026-11-06 ; arbitrage Samuel, message direct en session principale, 2026-11-06 : toutes les propositions du panel) : PU-G-093, 097, 099, DG-10. Sans navigateur.
echo "=== R1 — vérité des états : une phase dit l'état de sa carte, jalon « Hors jalon », exigences non cochées, exigences sans doublon ==="
# PU-G-093 : STATE.md « ready_to_plan » alors que tous les plans de la phase 2 sont faits (carte « à recetter »)
LR="$WORK/r1"; B="$LR/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet
MD
printf -- '---\nmilestone: v1.0 MVP\nstatus: ready_to_plan\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Écran</objective>
MD
echo ok > "$B/phases/02-ecran/02-01-SUMMARY.md"
graph "$LR" "$WORK/gr1.json"
assert_eq "R1.1 — PU-G-093 : meta.vf.phaseEtat est l'état de la carte (a-recetter) et STATE.md est dit périmé (ready_to_plan contredit)" "$(G "$WORK/gr1.json" 'j.meta.vf.phaseEtat+"|"+j.meta.vf.stateStale+"|"+j.nodes.find(n=>n.id==="ph-2").st')" "a-recetter|true|recette"
assert_eq "R1.2 — PU-G-093 : la visite (étape 2) et le sous-titre disent « à recetter », jamais « prête à planifier » ; la visite signale STATE.md périmé" "$(G "$WORK/gr1.json" '[/à recetter/.test(j.tour[1].note),/STATE\.md semble périmé/.test(j.tour[1].note),/prête/.test(j.tour[1].note+j.project.summary),/phase 2 \(Écran\) · à recetter\./.test(j.project.summary)].join(",")')" "true,true,false,true"
# repli : phase courante introuvable -> le statut de STATE.md, sans accusation de péremption
printf -- '---\nmilestone: v1.0 MVP\nstatus: executing\ncurrent_phase: 9\n---\n' | wr "$B/STATE.md"
graph "$LR" "$WORK/gr1b.json"
assert_eq "R1.3 — PU-G-093 : phase courante introuvable : phaseEtat null, repli sur le statut de STATE.md (« en exécution »), jamais périmé" "$(G "$WORK/gr1b.json" '[j.meta.vf.phaseEtat,j.meta.vf.stateStale,/en exécution/.test(j.project.summary)].join(",")')" ",false,true"
printf -- '---\nmilestone: v1.0 MVP\nstatus: ready_to_plan\ncurrent_phase: 2\ncurrent_phase_name: Écran\n---\n' | wr "$B/STATE.md"
UIV="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "R1.4 — PU-G-093 / DG-13 : 00-vibeflow.js lit V.phaseEtat pour le bloc « Maintenant », dit STATE.md périmé, et écrit « Dans l'ordre de la feuille de route. » sous « Jalons »" "$(grep -c 'V\.phaseEtat' "$UIV" | awk '{print ($1>=2)?"ok":"ko"}')|$(grep -c 'STATE.md semble périmé' "$UIV")|$(grep -c "Dans l'ordre de la feuille de route\." "$UIV")" "ok|1|1"
# L3 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, consigné en § 10 du rapport GLOBAL de la recette (3da818fe)) : le message « périmé » dit quoi faire, dans le même bloc ; la phrase porte sur la phase (féminin), pas sur un jalon
assert_eq "R1.4b — L3 : « STATE.md semble périmé : il dit « … ». La carte fait foi ; mettez STATE.md à jour à la fin de la phase. » dans un seul message (une seule occurrence)" "$(grep -cF 'STATE.md semble périmé : il dit « ${h(statut(V.status))} ». La carte fait foi ; mettez STATE.md à jour à la fin de la phase.</div>' "$UIV")" "1"
# PU-G-099 : un vrai jalon (clos) et deux phases hors jalon, faites
LJ="$WORK/r1j"; B="$LJ/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- ✅ **v1.0 MVP** — Phase 1 (livré)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [x] **Phase 2: Annexe** - hors jalon
- [ ] **Phase 3: Suite** - hors jalon
MD
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
graph "$LJ" "$WORK/gj.json"
assert_eq "R1.5 — PU-G-099 : avec un vrai jalon, le groupe des phases sans jalon s'appelle « Hors jalon » (id ms-hors-jalon), plus « Phases »" "$(G "$WORK/gj.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.id+"="+n.label).sort().join(",")')" "ms-hors-jalon=Hors jalon,ms-v1.0-mvp=v1.0 MVP"
assert_eq "R1.6 — PU-G-099 : « Hors jalon » n'est ni dans meta.vf.milestones, ni dans « Historique » (1 jalon clos, 1 phase), ni jalon mis en avant, ni chaîne « puis »" "$(G "$WORK/gj.json" '[j.meta.vf.milestones.map(m=>m.key).join("+"),j.nodes.find(n=>n.id==="history").foot,j.nodes.find(n=>n.id==="ms-hors-jalon").parent,j.flows[0].title,j.links.filter(l=>l.k==="event"&&(l.a==="n:ms-hors-jalon"||l.b==="n:ms-hors-jalon")).length].join("|")')" "v1.0 MVP|1 jalons · 1 phases||Trajectoire de v1.0 MVP|0"
assert_eq "R1.7 — PU-G-099 : sans aucun jalon, le groupe garde « Phases » (lab P3)" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.label).join(",")')|$(G "$WORK/g3.json" 'j.meta.vf.milestones.map(m=>m.key).join(",")')" "Phases|Phases"
# PU-G-097 : phase faite dont des exigences ne sont pas cochées, et phase non faite (inchangée)
LX="$WORK/r1x"; B="$LX/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [x] **Phase 1: Faite** - a
- [ ] **Phase 2: Ouverte** - b
MD
printf -- '- [x] **A-01**: un\n- [ ] **A-02**: deux\n- [ ] **A-03**: trois\n- [x] **B-01**: un\n- [ ] **B-02**: deux\n\n| A-01 | Phase 1 | Complete |\n| A-02 | Phase 1 | Pending |\n| A-03 | Phase 1 | Pending |\n| B-01 | Phase 2 | Complete |\n| B-02 | Phase 2 | Pending |\n' | wr "$B/REQUIREMENTS.md"
graph "$LX" "$WORK/gx.json"
assert_eq "R1.8 — PU-G-097 : phase faite, 2 exigences sur 3 non cochées : « 2 exigences non cochées » (texte neutre), plus « 1/3 exigences » ; phase non faite : « 1/2 exigences » inchangé" "$(G "$WORK/gx.json" '["ph-1","ph-2"].map(i=>j.nodes.find(n=>n.id===i).foot).join("|")')" "2 exigences non cochées|1/2 exigences"
# DG-10 (PU-G-052) : même exigence dans le fichier vivant du compartiment ET dans l'archive de jalon, même phase par la traçabilité
LD="$WORK/r1d"; B="$LD/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
- [x] **Phase 1: Un** - a
- [ ] **Phase 2: Deux** - b
MD
echo alpha > "$B/active-workstream"
printf -- '- [x] **RND-02**: recherche\n- [ ] **NEW-01**: neuf\n\n| RND-02 | Phase 1 | Complete |\n| NEW-01 | Phase 2 | Pending |\n' | wr "$B/workstreams/alpha/REQUIREMENTS.md"
printf -- '- [x] **RND-02**: recherche\n- [x] **OLD-09**: autre phase\n\n| RND-02 | Phase 1 | Complete |\n| OLD-09 | Phase 5 | Complete |\n' | wr "$B/milestones/v0-REQUIREMENTS.md"
graph "$LD" "$WORK/gd.json"
assert_eq "R1.9 — DG-10 : RND-02 (vivant + archive, même phase) n'est lue qu'UNE fois (RND-02 sous ph-1, jamais en double) ; l'exigence propre à l'archive (OLD-09, phase 5 sans carte) reste comptée : 3 exigences dont 2 cochées" "$(G "$WORK/gd.json" 'j.files.filter(f=>f.p.startsWith("req/")).map(f=>f.name).sort().join(",")')|$(G "$WORK/gd.json" 'j.meta.vf.counts.reqs+"/"+j.meta.vf.counts.reqsDone')" "NEW-01,RND-02|3/2"

# R2 (lot 6 « Projet », étape PR2 « panneau de phase et visite », 2026-11-06 ; arbitrage Samuel, message direct en session principale, 2026-11-06 : toutes les propositions du panel) : PU-G-091, 092, 102, 103, 106, 107 (+ 104 côté moteur). Sans navigateur.
echo "=== R2 — panneau de phase et visite : visite expliquée, mission vivante du jalon, texte propre, aucune répétition, exigence lisible ==="
LK="$WORK/r2"; B="$LK/.planning"
GOAL_LONG="Depuis une carte de phase ou de mission, ou depuis le cockpit, lancer du travail dans une session Claude Code qui tourne sur le poste, avec le contexte du projet, en anticipant les dépendances manquantes et les impossibilités avant de lancer, puis garder la main sur chaque étape du lancement jusqu'à la fin de la session, sans jamais écrire ni exécuter à la place de l'utilisateur sans son accord explicite."
wr "$B/ROADMAP.md" <<MD
## Milestones

- ✅ **v0 Ancien** - Phase 1 (livré)
- 🚧 **v1.0 MVP** - Phases 2-3 — **inscrit 2026-11-01** — le cockpit avec \`vf-signal\` <!-- vf-archive: .planning/archives/roadmap/x.md --> fin du jalon <!-- jamais fermé

## Phases

- [x] **Phase 1: Socle** - a
- [ ] **Phase 2: Écran** - b
- [ ] **Phase 3: Suite** - c

### Phase 1: Socle
**Goal**: Poser le socle

### Phase 2: Écran
**Goal**: Poser **l'écran** avec \`vf-signal\`

### Phase 3: Suite
**Goal**: $GOAL_LONG
MD
printf -- '---\nmilestone: v1.0 MVP\nstatus: executing\ncurrent_phase: 3\n---\n' | wr "$B/STATE.md"
printf -- '- [ ] **UIFN-01**: À 700 px, l'"'"'en-tête tient sur une rangée.\n- [ ] **UIFN-02**: Le panneau garde une aide.\n\n| UIFN-01 | Phase 2 | Pending |\n| UIFN-02 | Phase 2 | Pending |\n' | wr "$B/REQUIREMENTS.md"
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/03-suite/03-01-PLAN.md" <<'MD'
<objective>Suite</objective>
MD
# trois missions : une abandonnée d'un jalon CLOS (phase 1, la première du dossier), une terminée du jalon en cours (phase 2), une vivante du jalon en cours (phase 3)
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"phase":"1","nodes":[{"id":"a","step":"s","deps":[],"status":"done"},{"id":"b","step":"s","deps":["a"],"status":"running"}]}
JSON
wr "$B/missions/MISSION-2.dag.json" <<'JSON'
{"phase":"2","nodes":[{"id":"a","step":"s","deps":[],"status":"done"}]}
JSON
wr "$B/missions/MISSION-3.dag.json" <<'JSON'
{"phase":"3","nodes":[{"id":"a","step":"s","deps":[],"status":"done"},{"id":"b","step":"s","deps":["a"],"status":"ready"},{"id":"c","step":"s","deps":["b"],"status":"ready"}]}
JSON
VF_PIN="$WORK/locks-abs" graph "$LK" "$WORK/gk.json"
assert_eq "R2.1 — PU-G-091 : l'étape 1 de la visite dit ce que fait VibeFlow, puis « Jalon = … ; phase = … ; mission = … », et garde « Phases faites » (jalon en cours)" "$(G "$WORK/gk.json" '[/VibeFlow fait avancer/.test(j.tour[0].note),/Jalon = [^;]+ ; phase = [^;]+ ; mission = /.test(j.tour[0].note),/Phases faites : \d+ sur \d+/.test(j.tour[0].note)].join(",")')" "true,true,true"
assert_eq "R2.2 — PU-G-092 : l'étape « missions » montre la mission VIVANTE du jalon en cours (MISSION-3), pas l'abandonnée d'un jalon clos (MISSION-1, la première du dossier)" "$(G "$WORK/gk.json" 'j.tour.find(s=>s.kicker==="Les missions").ref')" "n:dag-MISSION-3"
assert_eq "R2.3 — PU-G-092 : les comptes sont ceux du jalon (2 missions : MISSION-2 et MISSION-3, pas les 3 du lab), le mot est « étapes » et jamais « nœuds »" "$(G "$WORK/gk.json" 'j.tour.find(s=>s.kicker==="Les missions").note')" "Ce jalon compte 2 missions ; celle-ci a 1 étape faite sur 3."
# aucune mission vivante dans le jalon en cours : on retire MISSION-2 et MISSION-3, il ne reste que l'abandonnée du jalon clos
cp -R "$LK" "$WORK/r2b"; rm -f "$WORK/r2b/.planning/missions/MISSION-2.dag.json" "$WORK/r2b/.planning/missions/MISSION-3.dag.json"
VF_PIN="$WORK/locks-abs" graph "$WORK/r2b" "$WORK/gk2.json"
assert_eq "R2.4 — PU-G-092 : aucune mission vivante dans le jalon en cours -> l'étape « missions » est omise (jamais l'abandonnée d'un jalon clos montrée) ; témoin : MISSION-1 est bien dans le graphe, abandonnée" "$(G "$WORK/gk2.json" 'j.tour.filter(s=>s.kicker==="Les missions").length+"|"+j.nodes.find(n=>n.id==="dag-MISSION-1").foot.includes("abandonnée")')" "0|true"
# PU-G-102 : le jalon et la phase sans balisage brut ni commentaire d'archive
assert_eq "R2.5 — PU-G-102 : le texte du jalon (résumé et détail) ne porte ni « ** », ni accent grave, ni « <!-- », ni « vf-archive » ; le sens reste (« inscrit 2026-11-01 », « fin du jalon »)" "$(G "$WORK/gk.json" '(()=>{const m=j.nodes.find(n=>n.id==="ms-v1.0-mvp");return [/\*\*|`|<!--|vf-archive/.test(m.summary+m.details),m.details.includes("inscrit 2026-11-01"),m.details.includes("fin du jalon")].join(",")})()')" "false,true,true"
assert_eq "R2.6 — PU-G-102 : le but d'une phase est rendu sans gras ni accents graves, et aucune carte du graphe (résumé, détail) ne montre de balisage brut" "$(G "$WORK/gk.json" '[j.nodes.find(n=>n.id==="ph-2").summary,j.nodes.filter(n=>/\*\*|`|<!--/.test(n.summary+n.details)).length].join("|")')" "Poser l'écran avec vf-signal|0"
# PU-G-103 : le résumé et le détail ne disent pas deux fois la même chose
assert_eq "R2.7 — PU-G-103 : but court (tient dans le résumé) : le détail ne le reprend pas ; il garde « Reste : … » en tête" "$(G "$WORK/gk.json" '(()=>{const n=j.nodes.find(n=>n.id==="ph-2");return [n.details.includes("avec"),n.summary.includes("avec")].join(",")})()')" "false,true"
assert_eq "R2.8 — PU-G-103 : but long (> 400 signes) : le résumé en porte le début, le détail la SUITE seulement ; mis bout à bout ils redisent le but une fois (ni répétition du début, ni perte)" "$(GOAL="$GOAL_LONG" node -e "
const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')), n=j.nodes.find(x=>x.id==='ph-3'), d=n.details.split('\\n\\n')[0];
const a=n.summary.replace(/…\$/,''), b=d.replace(/^…/,''), g=process.env.GOAL.replace(/\\s+/g,' ').trim();
console.log([n.summary.length<=401, b.length>0, (a+' '+b).replace(/\\s+/g,' ').trim()===g||(a+b).replace(/\\s+/g,' ').trim()===g, !d.startsWith(a.slice(0,40))].join(','))" "$WORK/gk.json")" "true,true,true,true"
# PU-G-106 : l'exigence se lit sur sa carte
assert_eq "R2.9 — PU-G-106 : le pied d'une carte d'exigence est la phrase de l'exigence, plus « REQUIREMENTS.md »" "$(G "$WORK/gk.json" 'j.files.filter(f=>f.n==="ph-2.req").map(f=>f.foot).join("|")')" "À 700 px, l'en-tête tient sur une rangée.|Le panneau garde une aide."
UIK="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "R2.10 — PU-G-107 / PU-G-104 / PU-G-106 : 00-vibeflow.js pose l'aide de navigation AVANT « Maintenant », construit le repli « Détails techniques » à l'ouverture du panneau et marque les cartes dont le pied répète la description" "$(node -e "
const s=require('fs').readFileSync(process.argv[1],'utf8');
const aide=s.indexOf('Double-clic sur une carte pour plonger'), now=s.indexOf('\${now}');
console.log([aide>0&&aide<now,(s.match(/Double-clic sur une carte pour plonger/g)||[]).length===1,/SC\.on\('panel'/.test(s)&&/Détails techniques/.test(s),/vf-meme/.test(s)].join(','))" "$UIK")" "true,true,true,true"

echo "=== R3 — panneau « Format de la planification » : écarts comptés et situés, commande rejouable, mots du cockpit, hors jalon (PU-G-153, 155, 156, 158, 160 ; DG-15) ==="
# lab de dérive : 1 toléré (« Phase 2 : » ligne 11), 3 lignes non lues au ROADMAP et 1 aux exigences ; la phase 3 ne figure dans aucun jalon
L3="$WORK/r3"; B="$L3/.planning"; mk_r3 "$L3"
graph "$L3" "$WORK/g-r3.json"
assert_eq "R3.1 — PU-G-155 : le compte de chaque niveau est dans la donnée (5 écarts : 1 toléré, 4 non lus) et la liste des lignes non lues a 4 entrées" "$(G "$WORK/g-r3.json" 'j.meta.vf.drift.ecartsN+"|"+JSON.stringify(j.meta.vf.drift.parNiveau)+"|"+j.meta.vf.drift.nonComprises.length')" '5|{"bloquant":0,"tolere":1,"info":0,"ignore":4}|4'
assert_eq "R3.2 — PU-G-156 : la répartition par fichier des lignes non lues est la vraie (3 au ROADMAP, 1 aux exigences : le champ historique « fichier » ne dit que le premier constat), la règle tolérée donne son fichier:ligne" "$(G "$WORK/g-r3.json" '(()=>{const r=j.meta.vf.drift.regles;const i=r.find(x=>x.regle==="ligne-non-comprise"),t=r.find(x=>x.regle==="phase-deux-points");return i.fichiers.map(f=>f.fichier.split("/").pop()+":"+f.n).join(",")+"|"+i.fichier.split("/").pop()+"|"+t.emplacements.map(e=>e.fichier+":"+e.ligne).join(",")})()')" "ROADMAP.md:3,REQUIREMENTS.md:1|ROADMAP.md|.planning/ROADMAP.md:16"
assert_eq "R3.3 — PU-G-156 : le correctif dit ce qu'il couvre (1 écart sur 5 : seule la ligne tolérée porte une réécriture)" "$(G "$WORK/g-r3.json" 'j.meta.vf.drift.couvertsN+"|"+j.meta.vf.drift.regles.filter(r=>r.corrigeable).map(r=>r.regle).join(",")')" "1|phase-deux-points"
assert_eq "R3.4 — PU-G-160 : un lab dont une phase ne figure dans aucun jalon porte meta.vf.horsJalon ; un lab sans ce groupe, null (témoin : P1, au gabarit)" "$(G "$WORK/g-r3.json" 'JSON.stringify(j.meta.vf.horsJalon)')|$(G "$WORK/g1.json" 'JSON.stringify(j.meta.vf.horsJalon)')" '{"n":1,"id":"n:ms-hors-jalon"}|null'
assert_eq "R3.5 — PU-G-160 : lab conforme -> aucun écart, aucune commande (la section existe quand même côté page, R3.20)" "$(G "$WORK/g1.json" 'j.meta.vf.drift.ecartsN+"|"+JSON.stringify(j.meta.vf.drift.commande)+"|"+j.meta.vf.drift.erreur')" '0|""|false'
# PU-G-153 : la commande affichée est rejouée TELLE QUELLE depuis un autre dossier que le lab ; témoin rouge : l'ancienne forme (script relatif, chemin du lab réel) échoue depuis ce même dossier
CMD3="$(G "$WORK/g-r3.json" 'j.meta.vf.drift.commande')"
mkdir -p "$WORK/ailleurs-r3"; cp -R "$L3" "$WORK/r3-copie-a"; cp -R "$L3" "$WORK/r3-copie-b"
OLD3="node vf-cockpit-drift.mjs '$WORK/r3-copie-a' --diff > drift.patch && git -C '$WORK/r3-copie-a' apply drift.patch"
OLDRC="$(cd "$WORK/ailleurs-r3" && bash -c "$OLD3" >/dev/null 2>&1; echo $?)"
assert_eq "R3.6 — PU-G-153, témoin rouge : l'ancienne commande (script relatif) échoue depuis un autre dossier que le lab (code de sortie non nul)" "$([ "$OLDRC" != 0 ] && echo echec)" "echec"
CMDB="$(printf '%s' "$CMD3" | sed "s#$L3#$WORK/r3-copie-b#g")"
assert_eq "R3.7 — PU-G-153 : la commande de la donnée est complète (aucun « <lab> », chemins absolus du script et du lab) ; rejouée telle quelle depuis un autre dossier sur une copie jetable : code 0, le toléré est corrigé et les 4 lignes non lues restent" "$(printf '%s' "$CMD3" | grep -c '<lab>')|$(printf '%s' "$CMD3" | grep -c "^node '/.*vf-cockpit-drift.mjs' '$L3' --diff | git -C '$L3' apply -\$")|$(cd "$WORK/ailleurs-r3" && bash -c "$CMDB" >/dev/null 2>&1; echo $?)|$(node "$DR" "$WORK/r3-copie-b" | head -1)" "0|1|0|4 écart(s) de format : 0 bloquant(s), 0 toléré(s), 0 info, 4 ligne(s) non comprise(s)."
# un lab dont le chemin porte une espace et une apostrophe, puis un lab qui n'est qu'un sous-dossier d'un dépôt git : la même forme tient
LQ="$WORK/lab d'essai r3"; cp -R "$L3" "$LQ"; node "$AUX/q.mjs" "$SCRIPTS" project "$LQ" > "$WORK/g-r3q.json"
CMDQ="$(G "$WORK/g-r3q.json" 'j.meta.vf.drift.commande')"
assert_eq "R3.8 — PU-G-153 : chemin du lab avec espace et apostrophe, la commande (entre apostrophes, « '\\'' ») s'exécute telle quelle : code 0, toléré corrigé" "$(cd "$WORK/ailleurs-r3" && bash -c "$CMDQ" >/dev/null 2>&1; echo $?)|$(node "$DR" "$LQ" | head -1 | grep -c ' 0 toléré')" "0|1"
mkdir -p "$WORK/depot-r3"; cp -R "$L3" "$WORK/depot-r3/sous"; rm -rf "$WORK/depot-r3/sous/.git"; git -C "$WORK/depot-r3" init -q && git -C "$WORK/depot-r3" add -A && git -C "$WORK/depot-r3" -c user.email=t@t -c user.name=t commit -qm init
node "$AUX/q.mjs" "$SCRIPTS" project "$WORK/depot-r3/sous" > "$WORK/g-r3s.json"
assert_eq "R3.9 — PU-G-153 : lab en sous-dossier d'un dépôt git : la commande s'applique (code 0, toléré corrigé)" "$(cd "$WORK/ailleurs-r3" && bash -c "$(G "$WORK/g-r3s.json" 'j.meta.vf.drift.commande')" >/dev/null 2>&1; echo $?)|$(node "$DR" "$WORK/depot-r3/sous" | head -1 | grep -c ' 0 toléré')" "0|1"
assert_eq "R3.10 — PU-G-153 : la commande imprimée par le détecteur en ligne de commande est la même que celle de la page (une seule source)" "$(node "$DR" "$L3" | grep -c -F "$CMD3")" "1"
# PU-G-158 : les mots du cockpit dans les messages des règles (ni « gabarit GSD », ni « Goal », ni « Depends on », ni « ignorée ») ; « current_phase » n'y reste que comme ligne à écrire
printf '%s\n' '# Roadmap' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2 : Deux** - b' '### Phase 1: Un' '**Depends on**: Nothing · **Parallélisable avec**: Phase 2' '**Goal** — g' > "$WORK/r3m.md"
L3M="$WORK/r3m"; wr "$L3M/.planning/ROADMAP.md" < "$WORK/r3m.md"; printf -- '---\nstatus: executing\n---\n' | wr "$L3M/.planning/STATE.md"; git -C "$L3M" init -q
MSG3="$(node "$DR" "$L3M" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const c=JSON.parse(s).constats;console.log([...new Set(c.map(x=>x.regle))].sort().join(",")+"|"+c.map(x=>x.message).join(" / "))})')"
assert_eq "R3.11 — PU-G-158 : les cinq règles sont sorties (témoin : toutes présentes) et leurs messages n'emploient ni « gabarit GSD », ni « Goal », ni « Depends on », ni « ignoré/ignorée »" "${MSG3%%|*}|$(printf '%s' "${MSG3#*|}" | grep -c -E 'gabarit GSD|Goal|Depends on|ignor')" "depends-on,jalons-absents,ligne-non-comprise,phase-courante-absente,phase-deux-points|0"
# DG-15 : la cause (le bloc « Santé » de 20-health.js lit graph.health, que le graphe Projet ne porte pas) est levée côté page : le bloc est masqué avec le bouton, dans l'onglet Projet
assert_eq "R3.12 — DG-15 : le graphe Projet ne porte aucune clé health (c'est la cause : 20-health.js en conclut « aucun problème trouvé ») ; l'onglet Projet masque le bloc Santé du panneau" "$(G "$WORK/g-r3.json" 'Object.keys(j).includes("health")||Object.keys(j.meta).includes("health")')|$(grep "TAB === 'project'" "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js" | grep -c "#panel .sec:has(> .list > a\[data-hc-open\]) { display: none; }")" "false|1"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null   # environnement d'origine : posé par le bloc Chrome de l'ancienne suite unique, il valait pour les sections suivantes (en CI, Chrome présent) ; ni config git système ni globale du poste
# ---------- P-VIE — la mission abandonnée ou inconnue sur la carte Projet (VFSG-06 ; P68-D-05, P68-D-23) ----------
LV="$WORK/pvie"; B="$LV/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Seule** - une phase
MD
wr "$B/phases/01-a/01-01-PLAN.md" <<'MD'
<objective>Plan un</objective>
MD
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"01-01","step":"s","deps":[],"status":"running"},{"id":"b","step":"s","deps":[],"status":"ready"}]}
JSON
git -C "$LV" init -q
VF_PIN="$WORK/locks-abs" graph "$LV" "$WORK/gv-abs.json"
VF_PIN="$WORK/locks-vide" graph "$LV" "$WORK/gv-vide.json"
graph "$LV" "$WORK/gv-tenu.json"
echo "=== P-VIE — mission abandonnée ou inconnue ==="
assert_eq "P-VIE.0 — témoin positif : verrou tenu, la mission reste active et son plan désigné aussi" "$(G "$WORK/gv-tenu.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.files.find(f=>/^01-01 /.test(f.name)).st')" "active|active"
assert_eq "P-VIE.1 — sans verrou : la carte dag-MISSION-1 est todo et son pied dit « abandonnée, nœuds non refermés »" "$(G "$WORK/gv-abs.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.nodes.find(n=>n.id==="dag-MISSION-1").foot.includes("abandonnée, nœuds non refermés")')" "todo|true"
assert_eq "P-VIE.2 — un plan désigné par un nœud running d'une mission abandonnée reste todo" "$(G "$WORK/gv-abs.json" 'j.files.find(f=>/^01-01 /.test(f.name)).st')" "todo"
assert_eq "P-VIE.3 — les détails de la phase disent « Mission : MISSION-1 (abandonnée, nœuds non refermés) »" "$(G "$WORK/gv-abs.json" 'j.nodes.find(n=>n.id==="ph-1").details.includes("Mission : MISSION-1 (abandonnée, nœuds non refermés)")')" "true"
assert_eq "P-VIE.4 — verrous illisibles (aucun script) : la carte est todo et son pied dit « état inconnu »" "$(G "$WORK/gv-vide.json" 'j.nodes.find(n=>n.id==="dag-MISSION-1").st+"|"+j.nodes.find(n=>n.id==="dag-MISSION-1").foot.includes("état inconnu")')" "todo|true"

# P-VIE.5 — couplage socle/UI (68, passe 2) : 00-vibeflow.js réécrit la pastille d'une carte dont le pied dit « abandonnée » (const ABANDON). Le pied vient du socle (LIBELLES_MISSION) :
# si son libellé change, la pastille retomberait sur « À faire » sans bruit. On confronte l'expression de l'UI au pied RÉEL de la sortie du socle, et aux pieds qui ne doivent PAS la déclencher.
cat > "$AUX/abandon.mjs" <<'JS'
// abandon.mjs <00-vibeflow.js> <graphe.json> [<libellé de remplacement du mot « abandonnée »>] : « reconnu|inconnu-ignoré|mutant-ignoré » ou « regex absente »
import fs from 'node:fs';
const [, , ui, g, mut] = process.argv;
const m = /const ABANDON = (\/.*\/);/.exec(fs.readFileSync(ui, 'utf8')); if (!m) { console.log('regex absente'); process.exit(0); }
const re = new Function('return ' + m[1])();
const foot = JSON.parse(fs.readFileSync(g, 'utf8')).nodes.find((n) => n.id === 'dag-MISSION-1').foot;
const f2 = mut ? foot.replace('abandonnée', mut) : foot;
console.log(mut ? String(re.test(f2)) : [re.test(foot), !re.test('1/2 nœuds · état inconnu'), !re.test('1/2 nœuds · en cours'), !re.test('1/2 nœuds')].join('|'));
JS
UI68="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "P-VIE.5 — l'expression ABANDON de 00-vibeflow.js reconnaît le pied RÉEL d'une mission abandonnée du socle et ignore « état inconnu », « en cours » et le pied nu" "$(node "$AUX/abandon.mjs" "$UI68" "$WORK/gv-abs.json")" "true|true|true|true"
assert_eq "P-VIE.5b — témoin : un libellé du socle changé (« délaissée ») ne serait PAS reconnu : la mesure rougirait" "$(node "$AUX/abandon.mjs" "$UI68" "$WORK/gv-abs.json" délaissée)" "false"

# ---------- P8 — parseurs tolérants (matrice générée) et diagnostic « lignes non comprises » ----------
# Une seule planification porte une phase par variante (produit : gras × deux-points dedans/dehors × espace normal/U+00A0/U+202F/aucune × noms FR/EN/synonymes × casse × puce).
# Preuves : la matrice est rouge sur un mutant qui rétablit l'ancienne regex (et sur le code de 57e7957f) ; le diagnostic est muet sur le gabarit GSD et rouge sur un mutant qui le coupe.
echo "=== P8 — parseurs tolérants et diagnostic ==="
cat > "$AUX/matrice.mjs" <<'JS'
// matrice.mjs <scripts> <travail> : écrit UNE planification plate (une phase par variante), la lit par readPlanning, rend { total, echecs, traces } en JSON
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, work] = process.argv;
const { readPlanning } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-planning.mjs')).href);
const NBSP = ' ', NNBSP = ' ';
const ESPACES = ['', ' ', NBSP, NNBSP];
const CASSES = [(s) => s, (s) => s.toUpperCase(), (s) => s.toLowerCase()];
const FORMES = [(nom, sp) => `**${nom}${sp}:**`, (nom, sp) => `**${nom}**${sp}:`, (nom, sp) => `${nom}${sp}:`];
const PUCES = ['', '- '];
const road = ['# Roadmap', '', '### Phase 1: Racine', '**Goal**: racine', '**Depends on**: Nothing', ''];
const attendus = []; // { id, ok(phases) -> [attendu, obtenu] }
let i = 0;
const ajoute = (id, bloc, verif) => { road.push(...bloc, ''); attendus.push({ id, verif }); };
// dépendances : 3 formes × 4 espaces × 6 noms × 3 casses × 2 puces = 432
for (const nom of ['Depends on', 'Dépend de', 'Dépendances', 'Dépendance', 'Dependencies', 'Depends']) for (const c of CASSES) for (const f of FORMES) for (const sp of ESPACES) for (const p of PUCES) {
  const n = 100 + i++, tete = `${p}${f(c(nom), sp)}`;
  ajoute(`dep ${JSON.stringify(tete)}`, [`### Phase ${n}: Dep${n}`, `${tete} Phase 01 (contexte).`], (ph) => [['1'], ph.get(`|${n}`)?.depends]);
}
// titres : 3 niveaux × 3 formes de numéro × 9 séparateurs × gras ou non = 162
for (const lvl of ['##', '###', '####']) for (const fmt of ['plain', 'pad', 'dec']) for (const sep of [': ', ' : ', ' :', `${NBSP}: `, `${NNBSP}: `, ' — ', ' – ', '—', ' - ']) for (const g of ['', '**']) {
  const n = 1000 + i++, num = fmt === 'plain' ? String(n) : fmt === 'pad' ? String(n).padStart(6, '0') : `${n}.5`, cle = fmt === 'dec' ? `${n}.5` : String(n);
  const ligne = `${lvl} ${g}Phase ${num}${sep}Titre${n}${g}`;
  ajoute(`titre ${JSON.stringify(ligne)}`, [ligne, `**Goal**: but${n}`], (ph) => [`Titre${n}|but${n}`, ph.has(`|${cle}`) ? `${ph.get(`|${cle}`).name}|${ph.get(`|${cle}`).goal}` : 'phase absente']);
}
// Goal / Objectif : 3 noms × 3 formes × 4 espaces × 3 casses × 2 puces = 216
for (const nom of ['Goal', 'Objectif', 'Objective']) for (const c of CASSES) for (const f of FORMES) for (const sp of ESPACES) for (const p of PUCES) {
  const n = 3000 + i++, tete = `${p}${f(c(nom), sp)}`;
  ajoute(`goal ${JSON.stringify(tete)}`, [`### Phase ${n}: But${n}`, `${tete} Livrer ${n}`], (ph) => [`Livrer ${n}`, ph.get(`|${n}`)?.goal]);
}
// cases de phase : 3 cases × 3 puces × gras ou non × 4 espaces × 2 numéros = 144 (le roadmap ci-dessus est écrit dans une section distincte pour ne pas mêler titres et cases)
const cases = [];
for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*', '+']) for (const g of ['', '**']) for (const sp of ESPACES) for (const z of ['', '0']) {
  const n = 5000 + i++, ligne = `${b} ${box} ${g}Phase ${z}${n}${sp}: Case${n}${g} - description`;
  cases.push(ligne); attendus.push({ id: `case ${JSON.stringify(ligne)}`, verif: (ph) => [`Case${n}|${box !== '[ ]'}`, ph.has(`|${n}`) ? `${ph.get(`|${n}`).name}|${ph.get(`|${n}`).done}` : 'phase absente'] });
}
for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*', '+']) for (const g of ['', '**']) for (const sep of [' — ', ' – ', ' - ', '—']) {
  const n = 7000 + i++, ligne = `${b} ${box} ${g}Phase ${n}${sep}Tiret${n}${g} - description`;
  cases.push(ligne); attendus.push({ id: `case-tiret ${JSON.stringify(ligne)}`, verif: (ph) => [`Tiret${n}|${box !== '[ ]'}`, ph.has(`|${n}`) ? `${ph.get(`|${n}`).name}|${ph.get(`|${n}`).done}` : 'phase absente'] });
}
const dir = path.join(work, '.planning'); fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'ROADMAP.md'), ['# Roadmap', '', '## Phases', ...cases, '', ...road.slice(2)].join('\n') + '\n');
// exigences : 4 formes × 3 cases × 2 puces = 24
const reqs = ['# Exigences', '']; let r = 0;
for (const [forme, nom] of [[(id) => `**${id}**:`, 'gras-puis-deux-points'], [(id) => `**${id}:**`, 'deux-points-dans-le-gras'], [(id) => `${id}:`, 'nu'], [(id) => `${id} :`, 'nu-espace']]) for (const box of ['[ ]', '[x]', '[X]']) for (const b of ['-', '*']) {
  const id = `TST-${++r}`; reqs.push(`${b} ${box} ${forme(id)} texte ${id}`);
  attendus.push({ id: `req ${nom} ${box} ${b}`, verif: (ph, rq) => [`texte ${id}|${box !== '[ ]'}`, rq.has(`|${id}`) ? `${rq.get(`|${id}`).text}|${rq.get(`|${id}`).done}` : 'exigence absente'] });
}
fs.writeFileSync(path.join(dir, 'REQUIREMENTS.md'), reqs.join('\n') + '\n');
// statut et phase courante : valeurs entre guillemets, casse, tirets
fs.writeFileSync(path.join(dir, 'STATE.md'), '---\nstatus: "In Progress"\ncurrent_phase: "02"\n---\n');
const P = readPlanning(work, undefined, { sansTags: true });
attendus.push({ id: 'statut « In Progress »', verif: (ph, rq, st) => ['in_progress', st.status] });
attendus.push({ id: 'current_phase « "02" »', verif: (ph, rq, st) => ['02', st.current_phase] });
const echecs = []; for (const a of attendus) { const [att, obt] = a.verif(P.phases, P.reqs, P.state); if (JSON.stringify(att) !== JSON.stringify(obt)) echecs.push(`${a.id} : attendu ${JSON.stringify(att)}, obtenu ${JSON.stringify(obt)}`); }
console.log(JSON.stringify({ total: attendus.length, echecs: echecs.length, traces: echecs.slice(0, 4) }));
JS
node "$AUX/matrice.mjs" "$SCRIPTS" "$WORK/p8m" > "$WORK/mat.json"
assert_eq "P8.1 — matrice : 1052 variantes de dépendances, titres, Goal, cases, exigences, statut (anti-vert-à-vide)" "$(G "$WORK/mat.json" 'j.total')" "1052"
assert_eq "P8.2 — matrice : toutes lues comme attendu ($(G "$WORK/mat.json" 'j.traces.join(" ; ")'))" "$(G "$WORK/mat.json" 'j.echecs')" "0"
mut7 anciennedep vf-cockpit-formats.mjs "const m = DEP_RE.exec(corps); if (!m) return [];" "const m = /\\*\\*(?:Depends on|Dépend de)(?::\\*\\*|\\*\\*\\s*:)\\s*(.*)/.exec(corps); if (!m) return [];" > "$WORK/ancre-dep.txt"
node "$AUX/matrice.mjs" "$WORK/mut-anciennedep" "$WORK/p8mut" > "$WORK/mat-mut.json"
assert_eq "P8.3 — mutant (ancienne regex « Depends on » rétablie, ancre présente) : la matrice rougit sur les dépendances seules" "$(cat "$WORK/ancre-dep.txt")|$(G "$WORK/mat-mut.json" 'j.echecs>0&&j.echecs<=432&&j.traces.every(t=>t.startsWith("dep "))')" "muté|true"

# cas réel du portfolio (« **Depends on :** Phase 02 (…) ») et « Phase 01 » = « Phase 1 » pour les liens
L8="$WORK/p8-portfolio"; mkdir -p "$L8/.planning"
printf '%s\n' '# Roadmap' '' '- [x] **Phase 01: Fondations** - a' '- [x] **Phase 02: Contenu** - b' '- [ ] **Phase 03: Credibilite** - c' '' \
  '### Phase 01: Fondations' '**Goal :** corriger les findings' '' '### Phase 02: Contenu' '**Goal :** rendre le portfolio utilisable en mobile' '**Depends on :** Phase 1' '' \
  '### Phase 03: Credibilite' '**Goal :** éliminer les placeholders' '**Depends on :** Phase 02 (mobile UX fixes complète).' > "$L8/.planning/ROADMAP.md"
git -C "$L8" init -q; graph "$L8" "$WORK/g8.json"
assert_eq "P8.4 — portfolio : « **Depends on :** Phase 02 (…) » et « Phase 1 » donnent les liens 1>2 et 2>3 (clé de phase et cible concordent)" "$(G "$WORK/g8.json" 'j.links.filter(l=>l.k==="import").map(l=>l.a+">"+l.b).sort().join(",")')" "n:ph-1>n:ph-2,n:ph-2>n:ph-3"
assert_eq "P8.5 — portfolio : ids de phase normalisés ph-1, ph-2, ph-3 (01 = 1)" "$(G "$WORK/g8.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-1,ph-2,ph-3"

# diagnostic : gabarit GSD riche = zéro ligne non comprise ; fixture illisible = lignes nommées fichier:ligne
L9="$WORK/p8-gsd"; B9="$L9/.planning"; mkdir -p "$B9"
printf '%s\n' '# Roadmap: Demo' '' '## Milestones' '' '- 🚧 **v1.0 MVP** - Phases 1-2 (en cours)' '' '## Phases' '' '- [ ] **Phase 1: Fondations** - socle' '- [ ] **Phase 1.1: Urgent (INSERTED)** - correctif' '- [ ] **Phase 2: Contenu** - pages' '' '## Phase Details' '' \
  '### Phase 1: Fondations' '**Goal**: Poser le socle. La Phase 2 en dépend.' '**Depends on**: Nothing' '**Requirements**: AUTH-01, AUTH-02' '**Success Criteria** (what must be TRUE):' '  1. Un utilisateur peut se connecter' '  2. Le build passe' '**Plans**: 2 plans' '' 'Plans:' '- [ ] 01-01-PLAN.md — socle' '- [ ] 01-02-PLAN.md — tests' '' \
  '### Phase 1.1: Urgent (INSERTED)' '**Goal**: Corriger' '**Depends on**: Phase 1' '' '### Phase 2: Contenu' '**Goal**: Pages' '**Depends on**: Phase 1 · **Parallélisable avec**: Phase 1.1' '' '## Progress' '' '| Phase | Plans Complete | Status | Completed |' '|-------|----------------|--------|-----------|' '| 1. Fondations | 0/2 | Not started | - |' > "$B9/ROADMAP.md"
printf '%s\n' '# Requirements' '' '## v1 Requirements' '' '- [ ] **AUTH-01**: Connexion' '- [x] **AUTH-02**: Déconnexion' '' '## v2 Requirements' '' '- [ ] **PERF-01**: Cache' '- [ ] Idée libre à trier 2 fois' '' '## Traceability' '' '| Requirement | Phase | Status |' '|---|---|---|' '| AUTH-01 | Phase 1 | Pending |' > "$B9/REQUIREMENTS.md"
printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0\n---\n\nPhase: 1 of 2\n' > "$B9/STATE.md"
git -C "$L9" init -q; graph "$L9" "$WORK/g9.json"
assert_eq "P8.6 — gabarit GSD riche (jalons, décimale, critères, plans, table, exigences) : zéro ligne non comprise (pas de faux positif)" "$(G "$WORK/g9.json" 'j.meta.vf.drift.nonComprisesN+"|"+j.meta.vf.drift.regles.filter(r=>r.regle==="ligne-non-comprise").length')" "0|0"
LA="$WORK/p8-illisible"; BA="$LA/.planning"; mkdir -p "$BA"
printf '%s\n' '# Roadmap' '' '## Phases' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2 Deux** - b' '' '### Phase 1: Un' '**Goal**: g1' '**Depends on**: Nothing' '' '### Phase 2: Deux' '**Goal** — g2' 'Dépends sur : Phase 1' '' '##### Phase 3: Trois' 'Phase 3 est la plus grosse, voir Goal: aucun.' '' '```' '### Phase 9: dans un bloc de code' '- [ ] **Phase 8 Huit** - illisible hors du bloc' '```' > "$BA/ROADMAP.md"
printf '%s\n' '# R' '- [ ] **AUTH-01**: ok' '- [ ] **Req_02** illisible' '- [ ] Faire un truc 2 fois' > "$BA/REQUIREMENTS.md"
printf -- '---\nstatus: executing\ncurrent_phase: deux\n---\n' > "$BA/STATE.md"
git -C "$LA" init -q; graph "$LA" "$WORK/gA.json"
assert_eq "P8.7 — fixture illisible : 6 lignes non comprises, nommées fichier:ligne (prose, tableau et bloc de code jamais signalés)" "$(G "$WORK/gA.json" 'j.meta.vf.drift.nonComprisesN+"|"+j.meta.vf.drift.nonComprises.map(x=>x.fichier+":"+x.ligne).join(",")')" "6|.planning/ROADMAP.md:5,.planning/ROADMAP.md:12,.planning/ROADMAP.md:13,.planning/ROADMAP.md:15,.planning/REQUIREMENTS.md:3,.planning/STATE.md:3"
assert_eq "P8.8 — la règle ligne-non-comprise est dans les règles du panneau (niveau ignoré) et le résumé le dit" "$(G "$WORK/gA.json" 'j.meta.vf.drift.regles.filter(r=>r.regle==="ligne-non-comprise").map(r=>r.niveau+":"+r.n).join(",")+"|"+/6 ligne\(s\) non comprise\(s\)/.test(j.meta.vf.drift.resume)')" "ignoré:6|true"
DRA="$(node "$DR" "$LA")"
assert_eq "P8.9 — CLI du détecteur : une ligne par ligne non comprise avec fichier:ligne" "$(printf '%s\n' "$DRA" | grep -c '\[ignoré\] \.planning/ROADMAP\.md:12 ')" "1"
AVANT="$(find "$BA" -type f -exec cksum {} + | sort)"; node "$DR" "$LA" --json > "$WORK/dra.json"; node "$DR" "$LA" --diff > /dev/null
assert_eq "P8.10 — le détecteur n'écrit rien dans .planning (cksum avant/après) et ne propose aucun correctif (« apres ») pour une ligne non comprise" "$([ "$AVANT" = "$(find "$BA" -type f -exec cksum {} + | sort)" ] && echo identique)|$(G "$WORK/dra.json" '(l=>l.length===6&&l.every(c=>c.apres===undefined))(j.constats.filter(c=>c.regle==="ligne-non-comprise"))')" "identique|true"
mut7 sansdiag vf-cockpit-drift.mjs "for (const x of lignesNonComprises(txt, 'roadmap')) constats.push(nonComprise(fichier, x));" "" > "$WORK/ancre-diag.txt"
node "$AUX/q.mjs" "$WORK/mut-sansdiag" project "$LA" > "$WORK/gA-mut.json"
assert_eq "P8.11 — mutant (diagnostic du ROADMAP coupé, ancre présente) : le test P8.7 rougit (2 lignes du ROADMAP en moins : 2 restent, exigences et STATE)" "$(cat "$WORK/ancre-diag.txt")|$(G "$WORK/gA-mut.json" 'j.meta.vf.drift.nonComprisesN')" "muté|2"
assert_eq "P8.12 — l'interface porte le panneau (« Lignes non comprises », échappé par h, jeton --text-3, aucun px brut ajouté)" "$(grep -c 'const nonComprises = ' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js")|$(grep -c 'derive(V.drift)}${nonComprises(V.drift)}' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js")|$(grep -A3 'const nonComprises = ' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js" | grep -c 'px')" "1|1|0"

# ---------- P9 — corrections de la revue (cout linéaire, puces après une ligne vide, CRLF, « Depends on Phase 3 », mot-clé collé, cases à tiret) ----------
echo "=== P9 — corrections de la revue du parseur tolérant ==="
cat > "$AUX/lin.mjs" <<'JS'
// lin.mjs <scripts> : 100 000 espaces dans six formes de ligne ; readPlanning ET detectDrift doivent rester sous 1 s chacun (quadratique : plusieurs secondes). « ok » ou les formes lentes.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs');
const N = ' '.repeat(100000), lentes = [];
const FORMES = { titre: '##' + N, case: '- [ ]' + N, 'case-gras': '- [ ] **' + N, dep: '### Phase 1: A\n**Depends on:** Phase 2' + N + 'x', 'dep-gras': '### Phase 1: A\n**' + N + 'Depends on:** 2', 'nom-case': '- [ ] **Phase 1: A' + N + 'x** - d', 'nom-suffixe': '- [x] Phase 1: A' + N + '(complete', 'dep-point': '### Phase 1: A\n**Depends on:** 2' + N + ' · x', nu: '### Phase 1: A\n' + N + 'Depends on' + N + '9' };
for (const [nom, l] of Object.entries(FORMES)) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'lin-')); fs.mkdirSync(path.join(d, '.planning')); fs.writeFileSync(path.join(d, '.planning/ROADMAP.md'), '# R\n\n' + l + '\n');
  const a = Date.now(); readPlanning(d, undefined, { sansTags: true }); const b = Date.now(); detectDrift(d); const c = Date.now();
  if (b - a > 1000) lentes.push(`${nom} lecture ${b - a} ms`); if (c - b > 1000) lentes.push(`${nom} diagnostic ${c - b} ms`);
  fs.rmSync(d, { recursive: true, force: true });
}
console.log(lentes.length ? lentes.join(' ; ') : 'ok');
JS
assert_eq "P9.1 (C1) — coût linéaire : 100 000 espaces dans six formes de ligne, lecture et diagnostic sous 1 s chacun" "$(node "$AUX/lin.mjs" "$SCRIPTS")" "ok"
cat > "$AUX/c.mjs" <<'JS'
// c.mjs <scripts> <cas> : sondes unitaires de P9 sur une planification jetable ; une ligne de sortie
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, cas] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs'); const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const mk = (road, state) => { const d = fs.mkdtempSync(path.join(os.tmpdir(), 'c-')); fs.mkdirSync(path.join(d, '.planning')); fs.writeFileSync(path.join(d, '.planning/ROADMAP.md'), road); if (state) fs.writeFileSync(path.join(d, '.planning/STATE.md'), state); return d; };
const deps = (road) => [...readPlanning(mk(road), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}:${p.depends}`).join(' ');
const nc = (road) => detectDrift(mk(road)).constats.filter((c) => c.regle === 'ligne-non-comprise').map((c) => c.ligne).join(',');
if (cas === 'puces') { const f = (sep) => deps(`### Phase 1: A\n### Phase 2: B\n**Depends on:**${sep}- Phase 1\n- Phase 1\n`); console.log([f('\n'), f('\n\n'), f('\n \n\n')].join('|')); }
else if (cas === 'crlf') { const f = (nl, bom) => (detectDrift(mk('- [ ] **Phase 1: A** - x\n### Phase 1: A\n', `${bom}---${nl}milestone: v9.9${nl}status: executing${nl}current_phase: 1${nl}---${nl}`)).constats.find((c) => c.regle === 'jalons-absents')?.apres.match(/\*\*([^*]+)\*\*/)?.[1]); console.log([f('\n', ''), f('\r\n', ''), f('\r\n', '﻿')].join('|')); }
else if (cas === 'dep-sans-deux-points') console.log(nc('### Phase 1: A\nDepends on Phase 3\n- Depends on Phase 3\n**Depends on** Phase 3\n**Depends on**: Phase 3\nLa Phase 2 en dépend.\nDependencies are documented below.\n'));
else if (cas === 'case-vide') console.log([deps('- [ ] Phase 1:\n- [ ] Phase 2: B\n'), deps('- [ ] Phase 1 —\n- [ ] Phase 2 — B\n')].map(() => '').join('') + [...readPlanning(mk('- [ ] Phase 1:\n- [ ] Phase 2: B\n'), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}=${p.name}`).join(',') + '|' + [...readPlanning(mk('- [x] Phase 1 —\n- [ ] Phase 2 — B\n'), undefined, { sansTags: true }).phases.values()].map((p) => `${p.n}=${p.name}${p.done ? '+' : ''}`).join(','));
else if (cas === 'backlog-crlf') { const f = (nl) => { const d = mk('- [ ] **Phase 1: A** - x\n### Phase 1: A\n'); fs.writeFileSync(path.join(d, '.planning/BACKLOG.md'), ['## Un — INVESTIGUÉ', 'texte un', '## Deux', 'texte deux', ''].join(nl)); return buildProjectGraph(d).files.filter((x) => x.p.startsWith('.planning/BACKLOG.md#')).length; }; console.log(f('\n') + '|' + f('\r\n')); }
else if (cas === 'colle') console.log(nc("### Phase 1: A\n- goal-backward : valider d'abord\nObjectif-cible : x\nGoal-driven : y\n**Goal** — non lu\n"));
JS
assert_eq "P9.2 (C2) — puces après un en-tête vide : lues pareil avec 0, 1 ou 2 lignes vides intercalées" "$(node "$AUX/c.mjs" "$SCRIPTS" puces)" "1: 2:1|1: 2:1|1: 2:1"
assert_eq "P9.3 (C4) — jalons-absents propose le jalon du STATE (v9.9) en LF, en CRLF et en CRLF avec BOM" "$(node "$AUX/c.mjs" "$SCRIPTS" crlf)" "v9.9|v9.9|v9.9"
assert_eq "P9.4 (C5) — « Depends on Phase 3 » sans deux-points (nu, puce, gras) est SIGNALÉE (lignes 2,3,4), pas lue ; la forme correcte, la prose « en dépend » et « Dependencies are documented » ne le sont pas" "$(node "$AUX/c.mjs" "$SCRIPTS" dep-sans-deux-points)" "2,3,4"
assert_eq "P9.10 (R4) — un nom de case vide reste vide : « Phase 1: » puis « Phase 2: B » donnent deux phases, avec deux-points ET avec tiret (la ligne suivante est lue pour elle-même)" "$(node "$AUX/c.mjs" "$SCRIPTS" case-vide)" "1=,2=B|1=+,2=B"
assert_eq "P9.11 (R5) — BACKLOG.md en CRLF : même nombre d'entrées qu'en LF (2)" "$(node "$AUX/c.mjs" "$SCRIPTS" backlog-crlf)" "2|2"
assert_eq "P9.5 (C6) — mot-clé collé à un trait d'union (goal-backward, Objectif-cible, Goal-driven) : jamais signalé ; « **Goal** — » l'est toujours" "$(node "$AUX/c.mjs" "$SCRIPTS" colle)" "5"
mut7 fence vf-cockpit-formats.mjs "    if (code) return;
" "" > "$WORK/ancre-fence.txt"
node "$AUX/q.mjs" "$WORK/mut-fence" project "$LA" > "$WORK/gA-fence.json"
assert_eq "P9.6 (C3) — mutant (gestion des blocs de code retirée) : la ligne illisible DANS le bloc est signalée, P8.7 rougirait (7 au lieu de 6)" "$(cat "$WORK/ancre-fence.txt")|$(G "$WORK/gA-fence.json" 'j.meta.vf.drift.nonComprisesN')" "muté|7"
printf -- '- [ ] Phase 1 sans séparateur\n' | wr "$WORK/p9-ill/.planning/ROADMAP.md"
mut7 sansillisible vf-cockpit-drift.mjs "if (!nb && /(^|\\n)" "if (false && /(^|\\n)" > "$WORK/ancre-illis.txt"
assert_eq "P9.7 (C10) — P6.9 garde son sens : sur « Phase 1 sans séparateur » le détecteur dit bloquant ; mutant (règle phases-illisibles coupée) : plus rien" "$(cat "$WORK/ancre-illis.txt")|$(node "$DR" "$WORK/p9-ill" --json | G /dev/stdin 'j.constats.filter(c=>c.niveau==="bloquant").length')|$(node "$WORK/mut-sansillisible/vf-cockpit-drift.mjs" "$WORK/p9-ill" --json | G /dev/stdin 'j.constats.filter(c=>c.niveau==="bloquant").length')" "muté|1|0"
UIP="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "P9.8 (C7, reprise PU-G-152) — le chemin:ligne du panneau ne se coupe jamais DANS son dernier segment : coupures permises après « / » seulement (<wbr>), word-break:normal et jamais overflow-wrap:anywhere sur son <code>, aucun px (le « white-space:nowrap » d'origine donnait des lignes écrasées à 1-3 signes avec défilement horizontal ; la mesure en navigateur est R3.17)" "$(grep -cF "replace(/\\//g, '/<wbr>')" "$UIP")|$(grep -c '\.vf-ref code { .*word-break: normal' "$UIP")|$(grep '\.vf-ref code { ' "$UIP" | grep -c 'overflow-wrap: anywhere')|$(grep -A3 'const nonComprises = ' "$UIP" | grep -c 'px')" "1|1|0|0"
assert_eq "P9.9 (C8) — le commentaire de avancement.mjs dit où vit normNum (formats, ré-exporté par planning)" "$(grep -c 'normNum de vf-cockpit-formats, ré-exporté par vf-cockpit-planning' "$SCRIPTS/vf-cockpit-avancement.mjs")" "1"

# ---------- P10 — croissance : aucune regex lue sur le planning n'est plus que linéaire (classe fermée, pas une forme à la fois) ----------
# Inventaire des regex appliquées au texte du planning (formats.mjs : tous les motifs de champ, de titre, d'exigence, de coupe et du diagnostic ; planning.mjs : nom de case, suffixe de statut,
# jalons, frontmatter ; drift.mjs : espace avant « : », coupe « · », phases illisibles, jalons ; project.mjs : objectif de plan, intertitres de BACKLOG ; avancement.mjs : statut de recette).
# Le test fabrique pour chaque forme lue et chaque caractère pathologique une ligne à N puis 2N, lue par readPlanning ET detectDrift ; il juge le RAPPORT des temps, pas un temps absolu seul.
CR="$(node "$CROISSANCE" "$SCRIPTS")"
assert_eq "P10.1 — croissance : 2712 cas (44 formes x 21 caractères dont U+2028/U+2029 x 3 fins de ligne), lecture, diagnostic et graphe Projet (BACKLOG, plans), ratio 2N/N sous 2,8" "$CR" "ok 2712"
mut7 cr-paren vf-cockpit-formats.mjs ".replace(PARENTHESES, ' ')" ".replace(/\\([^)]*\\)/g, ' ')" > "$WORK/ancre-cr1.txt"
mut7 cr-backlog vf-cockpit-project.mjs "(?<!\\s)\\s+—\\s+" "\\s+—\\s+" > "$WORK/ancre-cr3.txt"
mut7 cr-objectif vf-cockpit-project.mjs "objectif(txt) ||" "/<objective>\\s*([\\s\\S]*?)<\\/objective>/.exec(txt)?.[1] ||" > "$WORK/ancre-cr4.txt"
assert_eq "P10.4 (R2) — mutant (ancienne coupe de l'intertitre de BACKLOG rétablie) : le test de croissance rougit, par buildProjectGraph" "$(cat "$WORK/ancre-cr3.txt")|$(CROISSANCE_FORME='## T◇— x' node "$CROISSANCE" "$WORK/mut-cr-backlog" | grep -c 'échec(s) sur')" "muté|1"
assert_eq "P10.5 (R2) — mutant (ancienne regex de <objective> rétablie) : le test de croissance rougit, par buildProjectGraph" "$(cat "$WORK/ancre-cr4.txt")|$(CROISSANCE_FORME='※' node "$CROISSANCE" "$WORK/mut-cr-objectif" | grep -c 'échec(s) sur')" "muté|1"
assert_eq "P10.2 — mutant (ancienne regex des parenthèses rétablie, ancre présente) : le test de croissance rougit" "$(cat "$WORK/ancre-cr1.txt")|$(CROISSANCE_FORME='Depends on:** (' node "$CROISSANCE" "$WORK/mut-cr-paren" | grep -c 'échec(s) sur')" "muté|1"

bilan
