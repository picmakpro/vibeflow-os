#!/usr/bin/env bash
# test-cockpit-projet-champs.sh — champs structurés du graphe Projet (Phase 80, plan 80-03, FORM-06, FORM-07 part données), node seul, sans navigateur :
# avancement et exigences sur la phase (PC1), vague sur le plan (PC2), contrat cockpit-project@1 (PC3), backlog sans statut au pied (PC4), mutants M-VIE, M-STATUTS, M-AUTRE-LIGNE.
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
MD
wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **FORM-01**: premier
- [ ] **FORM-02**: second

| FORM-01 | Phase 1 | Complete |
| FORM-02 | Phase 1 | Pending |
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
graph "$L1" "$WORK/c1.json"
echo "=== PC1 — avancement et exigences structurés sur la phase ==="
c1() { G "$WORK/c1.json" "$1"; }
nd() { c1 "(n=>$2)(j.nodes.find(x=>x.id==='$1'))"; }   # nd <id> <expression sur n>
assert_eq "PC1.1 — ph-1 : etat fait, plans 2/2, exigences 1 sur 2" "$(nd ph-1 '[n.avancement?.etat,JSON.stringify(n.avancement?.plans),JSON.stringify(n.exigences)].join("|")')" 'fait|{"faits":2,"total":2}|{"faits":1,"total":2}'
assert_eq "PC1.2 — témoin d'invariance : pied et statut de ph-1 inchangés" "$(nd ph-1 'n.foot+"|"+n.st')" "2/2 plans · 1 exigence non cochée|done"
assert_eq "PC1.3 — ph-2 sans dossier : plans 0, reste « cadrage », exigences 0 sur 0" "$(nd ph-2 '[n.avancement?.plans?.total,n.avancement?.reste?.includes("cadrage"),JSON.stringify(n.exigences)].join("|")')" '0|true|{"faits":0,"total":0}'
CLES='/"(vie|tenu|stale|ttl|owner|progressAgeS)":/.test(JSON.stringify(j))'
assert_eq "PC1.4 — la mission d'une phase vivante est {nom, etat}, aucune clé de verrou dans le graphe" "$(nd ph-3 'JSON.stringify(n.avancement?.mission)')|$(c1 "$CLES")" '{"nom":"MISSION-LIENS","etat":"running"}|false'

bilan
