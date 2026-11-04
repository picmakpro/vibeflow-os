#!/usr/bin/env bash
# test-cockpit-vie.sh — vie d'une mission : verrou tenu ou progrès récent, sinon abandonnée, ou inconnue quand les verrous
# ne se lisent pas (VFSG-06 ; P68-D-05, P68-D-16, P68-D-22, P68-D-23, P68-D-26, P68-D-27, P68-D-29). Sections :
#   V0 contrôles positifs des fixtures (verts avant et après le code)
#   V1 témoin VFSG-06 : nœud running sans verrou -> abandonnee · V2 verrou tenu · V3 progrès récent · V4 verrou périmé
#   V5 source des verrous illisible -> inconnu (P68-D-23) ; témoin : sans dossier de scripts explicite le conductor voisin est trouvé (P68-D-29)
#   V6 la phase d'une mission abandonnée n'est pas en cours · V7 un script planté dans le lab n'est jamais exécuté
#   V8 copie mutée (âge pris de la date du DAG) · V9 deux DAG d'un même compartiment, verrou de leur phase (P68-D-22, P68-D-27)
#   V10 repli sur le verrou du compartiment (P68-D-26)
# Fixtures écrites par la suite dans mktemp ; chaque verrou est un faux driver-lock.sh posé dans un dossier de scripts explicite,
# hors de toute disposition …/cockpit/scripts (P68-D-29). Aucun serveur ni navigateur n'est lancé.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"   # la suite ne dépend jamais du driver-lock.sh du poste
unset VF_COCKPIT_SCRIPTS_DIR

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
cat > "$AUX/q.mjs" <<'JS'
// q.mjs <dossier de scripts> <lab> <dossier de scripts du verrou | -> : readPlanning -> DAG (name, etat, vie) et phases (key, avancement)
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, root, sd] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-planning.mjs')).href);
const P = m.readPlanning(root, undefined, sd && sd !== '-' ? { scriptsDir: sd } : {});
console.log(JSON.stringify({
  phases: [...P.phases.values()].map((p) => ({ key: p.key, avancement: p.avancement })),
  dags: P.dags.map((d) => ({ name: d.name, etat: d.etat, vie: d.vie })),
}));
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mutsub.mjs" <<'JS'
// mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; "ancre absente" si $FROM n'y est pas
import fs from 'node:fs';
const f = process.argv[2];
let t; try { t = fs.readFileSync(f, 'utf8'); } catch { console.log('ancre absente'); process.exit(1); }
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
# mut <nom> <fichier> <de> <vers> : copie fraîche des scripts dans $WORK/mut-<nom>, une substitution exacte ; rend « muté » ou « ancre absente »
mut() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
G() { node "$AUX/get.mjs" "$@"; }
# fake <dossier> : faux driver-lock.sh, répond à `status` par le contenu de status.json (stdin), à `orphans` par {"orphans":[]}
fake() { mkdir -p "$1"; cat > "$1/status.json"; printf '#!/usr/bin/env bash\ncase "$1" in status) cat "$(dirname "$0")/status.json";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$1/driver-lock.sh"; chmod +x "$1/driver-lock.sh"; }
# Q <dossier de scripts du socle> <lab> <dossier de scripts du verrou | -> <sortie>
Q() { node "$AUX/q.mjs" "$1" "$2" "$3" > "$4" 2>"$4.err"; }
DAGS() { G "$1" 'j.dags.map(d=>d.name+":"+(d.etat ?? "absent")).sort().join()'; }   # DAGS <sortie>
ONE() { G "$1" "(j.dags[0]||{})$2 ?? \"absent\""; }                     # ONE <sortie> <.champ>
NOEUD='{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}'

# ---------- fixtures ----------
# lab plat : ROADMAP à deux phases, MISSION-1 à nœud running
LF="$WORK/lab-flat"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' | wr "$LF/.planning/ROADMAP.md"
printf '%s\n' "$NOEUD" | wr "$LF/.planning/missions/MISSION-1.dag.json"
git -C "$LF" init -q
# lab partitionné (compartiment w) : phases 1 et 2, MISSION-1 et MISSION-2 à nœud running
LP="$WORK/lab-part"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' | wr "$LP/.planning/workstreams/w/ROADMAP.md"
printf '%s\n' "$NOEUD" | wr "$LP/.planning/workstreams/w/MISSION-1.dag.json"
printf '%s\n' "$NOEUD" | wr "$LP/.planning/workstreams/w/MISSION-2.dag.json"
echo w > "$LP/.planning/active-workstream"
git -C "$LP" init -q
# lab partitionné, phase 69 (normalisation de la phase du verrou)
L69="$WORK/lab-69"
printf -- '- [ ] **Phase 69: Soixante-neuf** - a\n' | wr "$L69/.planning/workstreams/w/ROADMAP.md"
printf '%s\n' "$NOEUD" | wr "$L69/.planning/workstreams/w/MISSION-69.dag.json"
echo w > "$L69/.planning/active-workstream"
git -C "$L69" init -q

# faux verrous — formes que driver-lock.sh émet vraiment (json_status et vf_dl_status_all de plugin/conductor/scripts/driver-lock.sh, lus sans les modifier) :
#   lab plat : l'objet d'UN verrou, ni scope ni ws ; absent : {"present": false, "lock": …, "children_running": …}
#   lab partitionné : {"present", "scope": "lab", "locks": [entrée depot, entrée compartiment…, entrée phase…]} ; une entrée porte scope (depot|compartiment|phase), ws ("" pour le dépôt) et phase
CORPS='"owner": "mgr", "step": "exec", "age_seconds": 40, "ttl": 1800'
SUITE='"generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null'
flat() { printf '{"present": true, %s, "stale": %s, %s, "progress_age_seconds": %s, "children_running": 0}' "$CORPS" "$1" "$SUITE" "$2"; }   # flat <stale> <progress_age_seconds>
J_ABS='{"present": false, "lock": ".planning/DRIVER.lock", "children_running": 0}'
J_TENU="$(flat false 30)"
J_PROG="$(flat true 60)"
J_PERIME="$(flat true null)"
J_PROGVIEUX="$(flat true 5000)"
ph() { printf '{"present": true, %s, "stale": %s, %s, "progress_age_seconds": %s, "children_running": 0, "scope": "phase", "ws": "%s", "phase": %s, "location": "git-common-dir"}' "$CORPS" "$2" "$SUITE" "$3" "${4:-w}" "$1"; }   # ph <phase JSON> <stale> <progress> [ws]
co() { printf '{"present": true, %s, "stale": %s, %s, "progress_age_seconds": %s, "children_running": 0, "scope": "compartiment", "ws": "%s", "location": "git-common-dir"}' "$CORPS" "$1" "$SUITE" "$2" "${3:-w}"; }   # co <stale> <progress> [ws]
COABS='{"present": false, "lock": "/lab/.git/vf-driver/ws/w/DRIVER.lock", "children_running": 0, "scope": "compartiment", "ws": "w", "location": "git-common-dir"}'
DEPOT='{"present": false, "lock": "/lab/.git/vf-driver/repo/DRIVER.lock", "children_running": 0, "scope": "depot", "ws": "", "location": "git-common-dir"}'
lab() { printf '{"present": true, "scope": "lab", "location": "git-common-dir", "legacy_lock": false, "locks": [%s, %s], "children_running": 0}' "$DEPOT" "$1"; }
printf '%s\n' "$J_ABS" | fake "$WORK/s-abs"
printf '%s\n' "$J_TENU" | fake "$WORK/s-tenu"
printf '%s\n' "$J_PROG" | fake "$WORK/s-prog"
printf '%s\n' "$J_PERIME" | fake "$WORK/s-perime"
printf '%s\n' "$J_PROGVIEUX" | fake "$WORK/s-progvieux"
printf 'ceci n est pas du json\n' | fake "$WORK/s-texte"
mkdir -p "$WORK/s-vide"   # dossier de scripts explicite VIDE : aucun driver-lock.sh
lab "$(ph '"1"' false 30)" | fake "$WORK/s-p1"
lab "$(ph '"1"' false 30 x)" | fake "$WORK/s-p1-x"
lab "$(co false 30 x)" | fake "$WORK/s-co-x"
lab "$(ph '"2"' false 30)" | fake "$WORK/s-p2"
lab "$(ph '"069"' false 30)" | fake "$WORK/s-069"
lab "$(ph 69 false 30)" | fake "$WORK/s-69num"
lab "$(ph '"069"' true null), $(ph '"69"' false 30)" | fake "$WORK/s-069-69"
lab "$(ph '"1"' true null), $(co false 30)" | fake "$WORK/s-p1peri-co"
lab "$(co false 30)" | fake "$WORK/s-co-tenu"
lab "$(co true null)" | fake "$WORK/s-co-peri"
lab "$COABS, $(ph '"1"' false 30)" | fake "$WORK/s-p1-coabs"

# ---------- V0 — contrôles positifs ----------
echo "=== V0 — les fixtures sont bien formées ==="
OKF=1
for d in s-abs s-tenu s-prog s-perime s-progvieux s-p1-x s-co-x s-p1 s-p2 s-069 s-69num s-069-69 s-p1peri-co s-co-tenu s-co-peri s-p1-coabs; do
  [ -x "$WORK/$d/driver-lock.sh" ] && node -e "JSON.parse(require('fs').readFileSync('$WORK/$d/status.json','utf8'))" 2>/dev/null && [ "$(bash "$WORK/$d/driver-lock.sh" status --all)" = "$(cat "$WORK/$d/status.json")" ] || OKF=0
done
for f in "$LF/.planning/missions/MISSION-1.dag.json" "$LP/.planning/workstreams/w/MISSION-1.dag.json" "$LP/.planning/workstreams/w/MISSION-2.dag.json" "$L69/.planning/workstreams/w/MISSION-69.dag.json"; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8')).nodes[0].status==='running'||process.exit(1)" 2>/dev/null || OKF=0
done
assert_eq "V0.1 — fixtures lisibles (faux verrous exécutables et JSON, DAG running lisibles)" "$OKF" "1"
assert_eq "V0.2 — le dossier de scripts explicite vide ne contient aucun driver-lock.sh" "$(ls "$WORK/s-vide" | wc -l | tr -d ' ')" "0"
Q "$SCRIPTS" "$LF" "$WORK/s-abs" "$WORK/v0.json"
assert_eq "V0.3 — readPlanning rend le DAG de MISSION-1 (lab plat) et deux phases" "$(G "$WORK/v0.json" 'j.dags.map(d=>d.name).join()+"|"+j.phases.length')" "MISSION-1|2"
Q "$SCRIPTS" "$LP" "$WORK/s-abs" "$WORK/v0p.json"
assert_eq "V0.4 — lab partitionné : deux DAG et les phases w|1 et w|2" "$(G "$WORK/v0p.json" 'j.dags.map(d=>d.name).sort().join()+"|"+j.phases.map(p=>p.key).sort().join()')" "MISSION-1,MISSION-2|w|1,w|2"

# ---------- V1 — témoin VFSG-06 ----------
echo "=== V1 — nœud running sans verrou ni progrès : abandonnee ==="
Q "$SCRIPTS" "$LF" "$WORK/s-abs" "$WORK/v1.json"
assert_eq "V1.1 — DAG à nœud running sans verrou : abandonnee" "$(ONE "$WORK/v1.json" .etat)" "abandonnee"
assert_eq "V1.2 — avancement.mission.etat de la phase 1 : abandonnee" "$(G "$WORK/v1.json" '(j.phases.find(p=>p.key==="|1").avancement.mission||{}).etat ?? "absent"')" "abandonnee"

# ---------- V2 à V4 ----------
echo "=== V2 à V4 — verrou tenu, progrès récent, verrou périmé ==="
Q "$SCRIPTS" "$LF" "$WORK/s-tenu" "$WORK/v2.json"
assert_eq "V2.1 — verrou tenu (lab plat, objet unique), stale false : running" "$(ONE "$WORK/v2.json" .etat)" "running"
Q "$SCRIPTS" "$LF" "$WORK/s-prog" "$WORK/v3.json"
assert_eq "V3.1 — verrou périmé mais progrès de 60 s sous un ttl de 1800 : running" "$(ONE "$WORK/v3.json" .etat)" "running"
Q "$SCRIPTS" "$LF" "$WORK/s-perime" "$WORK/v4.json"
assert_eq "V4.1 — verrou périmé, progress_age_seconds null : abandonnee" "$(ONE "$WORK/v4.json" .etat)" "abandonnee"

# ---------- V5 — source illisible (P68-D-23) ----------
echo "=== V5 — source des verrous illisible : inconnu ==="
Q "$SCRIPTS" "$LF" "$WORK/s-vide" "$WORK/v5a.json"
assert_eq "V5.1 — source des verrous introuvable : vie null, état inconnu" "$(G "$WORK/v5a.json" 'JSON.stringify(j.dags[0].vie)+"|"+j.dags[0].etat')" "null|inconnu"
Q "$SCRIPTS" "$LF" "$WORK/s-texte" "$WORK/v5b.json"
assert_eq "V5.2 — JSON illisible : vie null, état inconnu" "$(G "$WORK/v5b.json" 'JSON.stringify(j.dags[0].vie)+"|"+j.dags[0].etat')" "null|inconnu"
Q "$SCRIPTS" "$LF" "-" "$WORK/v5c.json"
assert_eq "V5.3 — témoin P68-D-29 : sans dossier de scripts explicite, le conductor voisin du dépôt est trouvé (vie non null)" "$(G "$WORK/v5c.json" 'j.dags[0].vie !== null && j.dags[0].vie !== undefined')" "true"

# ---------- V6 ----------
echo "=== V6 — la phase d'une mission abandonnée ==="
assert_eq "V6.1 — phase 1 (mission abandonnée, aucun plan fait) : a-faire" "$(G "$WORK/v1.json" 'j.phases.find(p=>p.key==="|1").avancement.etat')" "a-faire"

# ---------- V7 ----------
echo "=== V7 — un script planté dans le lab n'est jamais exécuté ==="
LV="$WORK/lab-plante"; cp -R "$LF" "$LV"
printf '#!/usr/bin/env bash\ntouch "%s/EXECUTE"\necho "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 1}"\n' "$LV" | wr "$LV/.claude/scripts/driver-lock.sh"; chmod +x "$LV/.claude/scripts/driver-lock.sh"
HOME="$LV" Q "$SCRIPTS" "$LV" "$WORK/s-vide" "$WORK/v7.json"
assert_eq "V7.1 — script planté dans le lab jamais exécuté" "$([ -e "$LV/EXECUTE" ] && echo exécuté || echo intact)" "intact"
assert_eq "V7.2 — la source plantée n'est pas lue : mission inconnu" "$(ONE "$WORK/v7.json" .etat)" "inconnu"

# ---------- V8 ----------
echo "=== V8 — copie mutée : âge pris de la date du DAG ==="
M8="$(mut date vf-cockpit-vie.mjs 'export function estVivante(vie) {' "import * as fsMut from 'node:fs'; export function estVivante(vie) { try { return Date.now() - fsMut.statSync(process.env.VF_DAG_FILE).mtimeMs < 1800000; } catch { return false; } }
function estVivanteOrig(vie) {" 2>&1)"
VF_DAG_FILE="$LF/.planning/missions/MISSION-1.dag.json" Q "$WORK/mut-date" "$LF" "$WORK/s-abs" "$WORK/v8.json"
assert_eq "V8.1 — copie mutée (âge pris de la date du DAG) détectée : le DAG récent rend la mission running sans verrou" "$M8|$(ONE "$WORK/v8.json" .etat)" "muté|running"

# ---------- V9 ----------
echo "=== V9 — deux DAG d'un même compartiment, verrou de leur phase (P68-D-22) ==="
Q "$SCRIPTS" "$LP" "$WORK/s-p1" "$WORK/v91.json"
assert_eq "V9.1 — deux DAG, phases différentes : seul celui sans verrou de phase est abandonnee" "$(DAGS "$WORK/v91.json")" "MISSION-1:running,MISSION-2:abandonnee"
Q "$SCRIPTS" "$LP" "$WORK/s-p2" "$WORK/v92.json"
assert_eq "V9.2 — verrou posé sur l'autre phase : verdicts inversés" "$(DAGS "$WORK/v92.json")" "MISSION-1:abandonnee,MISSION-2:running"
M93="$(mut parcomp vf-cockpit-vie.mjs " && ph !== null && normPhase(e.phase) === ph" "" 2>&1)"
Q "$WORK/mut-parcomp" "$LP" "$WORK/s-p1" "$WORK/v93.json"
assert_eq "V9.3 — copie mutée (verrou du compartiment) détectée : les deux DAG se disent vivants" "$M93|$(DAGS "$WORK/v93.json")" "muté|MISSION-1:running,MISSION-2:running"
Q "$SCRIPTS" "$L69" "$WORK/s-069" "$WORK/v94.json"
assert_eq "V9.4 — phase 069 (chaîne) et 69 : même phase" "$(DAGS "$WORK/v94.json")" "MISSION-69:running"
Q "$SCRIPTS" "$L69" "$WORK/s-69num" "$WORK/v94b.json"
assert_eq "V9.4b — forme défensive (le vrai script n'émet jamais la phase en nombre) : écartée" "$(DAGS "$WORK/v94b.json")" "MISSION-69:abandonnee"
M95="$(mut normid vf-cockpit-vie.mjs 'export function normPhase(v) {' "export function normPhase(v) { return typeof v === 'string' ? v : null; }
function normPhaseOrig(v) {" 2>&1)"
Q "$WORK/mut-normid" "$L69" "$WORK/s-069" "$WORK/v95.json"
assert_eq "V9.5 — copie mutée (normPhase identité) détectée : 069 ne désigne plus 69" "$M95|$(DAGS "$WORK/v95.json")" "muté|MISSION-69:abandonnee"
Q "$SCRIPTS" "$L69" "$WORK/s-069-69" "$WORK/v96.json"
assert_eq "V9.6 — 069 périmée (listée en premier) et 69 tenue : vivante" "$(DAGS "$WORK/v96.json")" "MISSION-69:running"
M97="$(mut premiere vf-cockpit-vie.mjs 'ePh.find(vive) || ePh[0]' 'ePh[0]' 2>&1)"
Q "$WORK/mut-premiere" "$L69" "$WORK/s-069-69" "$WORK/v97.json"
assert_eq "V9.7 — copie mutée (première entrée seule) détectée" "$M97|$(DAGS "$WORK/v97.json")" "muté|MISSION-69:abandonnee"
Q "$SCRIPTS" "$LP" "$WORK/s-p1peri-co" "$WORK/v98.json"
assert_eq "V9.8 — verrou de phase périmé et compartiment tenu : abandonnee (MISSION-1)" "$(G "$WORK/v98.json" 'j.dags.filter(d=>d.name==="MISSION-1").map(d=>d.etat ?? "absent").join()')" "abandonnee"
M99="$(mut replicomp vf-cockpit-vie.mjs 'if (ePh.length) return' 'if (ePh.some(vive)) return' 2>&1)"
Q "$WORK/mut-replicomp" "$LP" "$WORK/s-p1peri-co" "$WORK/v99.json"
assert_eq "V9.9 — copie mutée (repli compartiment prioritaire) détectée" "$M99|$(G "$WORK/v99.json" 'j.dags.filter(d=>d.name==="MISSION-1").map(d=>d.etat ?? "absent").join()')" "muté|running"

# ---------- V10 ----------
echo "=== V10 — repli sur le verrou du compartiment (P68-D-26) ==="
Q "$SCRIPTS" "$LP" "$WORK/s-co-tenu" "$WORK/v101.json"
assert_eq "V10.1 — compartiment seul tenu : running" "$(G "$WORK/v101.json" 'j.dags.filter(d=>d.name==="MISSION-1").map(d=>d.etat ?? "absent").join()')" "running"
Q "$SCRIPTS" "$LP" "$WORK/s-co-peri" "$WORK/v102.json"
assert_eq "V10.2 — compartiment périmé sans progrès : abandonnee" "$(G "$WORK/v102.json" 'j.dags.filter(d=>d.name==="MISSION-1").map(d=>d.etat ?? "absent").join()')" "abandonnee"
M103="$(mut sansrepli vf-cockpit-vie.mjs 'if (eCo) return' 'if (false) return' 2>&1)"
Q "$WORK/mut-sansrepli" "$LP" "$WORK/s-co-tenu" "$WORK/v103.json"
assert_eq "V10.3 — copie mutée (sans repli) détectée" "$M103|$(G "$WORK/v103.json" 'j.dags.filter(d=>d.name==="MISSION-1").map(d=>d.etat ?? "absent").join()')" "muté|abandonnee"
Q "$SCRIPTS" "$LP" "$WORK/s-p1-coabs" "$WORK/v104.json"
assert_eq "V10.4 — entrée de compartiment absente à côté : V9.1 inchangé" "$(DAGS "$WORK/v104.json")" "MISSION-1:running,MISSION-2:abandonnee"

# ---------- V11 — un driver-lock.sh antérieur à `--all` : la lecture refusée ne masque pas le verrou lisible par `status` (F-04) ----------
# Un script d'avant `--all` répond « Unknown arg: --all » (stderr, exit 1, stdout vide) ; en lab plat, `status` seul répond l'objet d'UN verrou.
echo "=== V11 — script d'avant --all : repli sur le verbe de base ==="
# fakeold <dossier> : refuse --all comme driver-lock.sh avant 32438005 ; status (sans --all) cat status.json
fakeold() { mkdir -p "$1"; cat > "$1/status.json"; printf '#!/usr/bin/env bash\nfor a in "$@"; do [ "$a" = "--all" ] && { echo "Unknown arg: $a" >&2; exit 1; }; done\ncase "$1" in status) cat "$(dirname "$0")/status.json";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$1/driver-lock.sh"; chmod +x "$1/driver-lock.sh"; }
printf '%s\n' '{"present": true, "owner": "mgr-ancien", "step": "exec", "age_seconds": 10, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": [], "lease_seconds": 5, "guard_effective": false, "progress_epoch": null, "progress_age_seconds": 30, "children_running": 0}' | fakeold "$WORK/s-old-tenu"
printf '%s\n' '{"present": false, "lock": ".planning/DRIVER.lock", "children_running": 0}' | fakeold "$WORK/s-old-abs"
printf '%s\n' '{"present": true, "owner": "mgr", "step": "exec", "age_seconds": 10, "ttl": 1800, "stale": false, "scope": "compartiment", "ws": "w", "location": "common", "children_running": 0}' | fakeold "$WORK/s-old-scope"
printf '#!/usr/bin/env bash\necho "Unknown arg: $1" >&2; exit 1\n' > "$WORK/s-old-tout-refuse.sh"; mkdir -p "$WORK/s-old-refuse"; mv "$WORK/s-old-tout-refuse.sh" "$WORK/s-old-refuse/driver-lock.sh"; chmod +x "$WORK/s-old-refuse/driver-lock.sh"
assert_eq "V11.0 — témoin : le faux script d'avant --all refuse bien --all (stdout vide, exit 1) et répond à status" "$(bash "$WORK/s-old-tenu/driver-lock.sh" status --all 2>/dev/null | wc -c | tr -d ' ')|$(bash "$WORK/s-old-tenu/driver-lock.sh" status --all >/dev/null 2>&1; echo $?)|$(bash "$WORK/s-old-tenu/driver-lock.sh" status | cut -c1-16)" "0|1|{\"present\": true"
Q "$SCRIPTS" "$LF" "$WORK/s-old-tenu" "$WORK/v111.json"
assert_eq "V11.1 — lab plat, script d'avant --all, verrou tenu : running (pas inconnu)" "$(ONE "$WORK/v111.json" .etat)" "running"
Q "$SCRIPTS" "$LF" "$WORK/s-old-abs" "$WORK/v112.json"
assert_eq "V11.2 — lab plat, script d'avant --all, verrou absent : abandonnee (lu et libre, pas inconnu)" "$(ONE "$WORK/v112.json" .etat)" "abandonnee"
Q "$SCRIPTS" "$LP" "$WORK/s-old-scope" "$WORK/v113.json"
assert_eq "V11.3 — lab partitionné, --all refusé et status au schéma de portée : jamais pris pour un verrou plat (inconnu)" "$(DAGS "$WORK/v113.json")" "MISSION-1:inconnu,MISSION-2:inconnu"
Q "$SCRIPTS" "$LF" "$WORK/s-old-refuse" "$WORK/v114.json"
assert_eq "V11.4 — script qui refuse tout verbe : inconnu" "$(ONE "$WORK/v114.json" .etat)" "inconnu"

# ---------- V12 — trois mutants de vf-cockpit-vie.mjs survivaient (F-07) : chacun a maintenant son témoin ----------
echo "=== V12 — copies mutées : le seuil de progrès, l'égalité de compartiment, l'égalité de compartiment du verrou de phase ==="
Q "$SCRIPTS" "$LF" "$WORK/s-progvieux" "$WORK/v121.json"
assert_eq "V12.1 — verrou périmé dont le dernier progrès (5000 s) dépasse le ttl (1800 s) : abandonnee" "$(ONE "$WORK/v121.json" .etat)" "abandonnee"
M122="$(mut seuil vf-cockpit-vie.mjs 'vie.progressAgeS < vie.ttl' 'vie.progressAgeS < 1e9' 2>&1)"
Q "$WORK/mut-seuil" "$LF" "$WORK/s-progvieux" "$WORK/v122.json"
assert_eq "V12.2 — copie mutée (progrès < 1e9 au lieu de < ttl) détectée : la mission redevient vivante" "$M122|$(ONE "$WORK/v122.json" .etat)" "muté|running"
Q "$SCRIPTS" "$LP" "$WORK/s-co-x" "$WORK/v123.json"
assert_eq "V12.3 — verrou de compartiment tenu pour un AUTRE compartiment (x) : les missions de w sont abandonnee" "$(DAGS "$WORK/v123.json")" "MISSION-1:abandonnee,MISSION-2:abandonnee"
M124="$(mut egco vf-cockpit-vie.mjs "e.scope === 'compartiment' && e.ws === ws" "e.scope === 'compartiment'" 2>&1)"
Q "$WORK/mut-egco" "$LP" "$WORK/s-co-x" "$WORK/v124.json"
assert_eq "V12.4 — copie mutée (égalité de compartiment retirée) détectée : le verrou de x fait vivre les missions de w" "$M124|$(DAGS "$WORK/v124.json")" "muté|MISSION-1:running,MISSION-2:running"
Q "$SCRIPTS" "$LP" "$WORK/s-p1-x" "$WORK/v125.json"
assert_eq "V12.5 — verrou de la phase 1 du compartiment x (même numéro que la phase 1 de w) : les missions de w sont abandonnee" "$(DAGS "$WORK/v125.json")" "MISSION-1:abandonnee,MISSION-2:abandonnee"
M126="$(mut egph vf-cockpit-vie.mjs "(e.ws || '') === (ws || '') && " "" 2>&1)"
Q "$WORK/mut-egph" "$LP" "$WORK/s-p1-x" "$WORK/v126.json"
assert_eq "V12.6 — copie mutée (égalité de compartiment retirée du verrou de phase) détectée : MISSION-1 vit du verrou de x" "$M126|$(DAGS "$WORK/v126.json")" "muté|MISSION-1:running,MISSION-2:abandonnee"

# ---------- V13 — le VRAI driver-lock.sh dans un lab jetable (F-07 ; P68-D-29) ----------
# Aucune forme supposée : le script du conductor de ce dépôt pose lui-même ses verrous (acquire --ws --phase) puis répond à status --all.
# HOME jetable, VF_DRIVER_LOCK retiré, dossier de scripts explicite passé à la lecture. Le cas « seul le verrou de dépôt est tenu » n'est pas joué ici (hors périmètre de F-07).
echo "=== V13 — le vrai driver-lock.sh : verrou de phase, de compartiment, lab plat ==="
CND="$(cd "$SCRIPTS/../../conductor/scripts" && pwd)"
unset VF_DRIVER_LOCK
DLR() { local lab="$1"; shift; ( cd "$lab" && bash "$CND/driver-lock.sh" "$@" ); }   # DLR <lab> <args…> : le vrai script, cwd = le lab
LR="$WORK/lab-reel"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' | wr "$LR/.planning/workstreams/w/ROADMAP.md"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$LR/.planning/workstreams/x/ROADMAP.md"
printf '%s\n' "$NOEUD" | wr "$LR/.planning/workstreams/w/MISSION-1.dag.json"
printf '%s\n' "$NOEUD" | wr "$LR/.planning/workstreams/w/MISSION-2.dag.json"
echo w > "$LR/.planning/active-workstream"
git -C "$LR" init -q
R() { rm -rf "$LR/.git/vf-driver"; }
R; DLR "$LR" acquire --owner=t --step=s --ws=w --phase=1 > "$WORK/acq1.json" 2>/dev/null
DLR "$LR" status --all > "$WORK/st1.json" 2>/dev/null
assert_eq "V13.0 — témoin : le vrai script a posé un verrou de phase 1 du compartiment w, tenu, lisible par status --all" "$(G "$WORK/acq1.json" 'j.acquired')|$(G "$WORK/st1.json" 'j.locks.filter(l=>l.present).map(l=>l.scope+":"+l.ws+":"+l.phase+":"+l.stale).join()')" "true|phase:w:1:false"
Q "$SCRIPTS" "$LR" "$CND" "$WORK/v131.json"
assert_eq "V13.1 — verrou de la phase 1 de w (vrai script) : MISSION-1 vivante, MISSION-2 abandonnee" "$(DAGS "$WORK/v131.json")" "MISSION-1:running,MISSION-2:abandonnee"
R; DLR "$LR" acquire --owner=t --step=s --ws=x --phase=1 >/dev/null 2>&1
Q "$SCRIPTS" "$LR" "$CND" "$WORK/v132.json"
assert_eq "V13.2 — verrou de la phase 1 du compartiment x (vrai script) : les missions de w restent abandonnee" "$(DAGS "$WORK/v132.json")" "MISSION-1:abandonnee,MISSION-2:abandonnee"
R; DLR "$LR" acquire --owner=t --step=s --ws=w >/dev/null 2>&1
Q "$SCRIPTS" "$LR" "$CND" "$WORK/v133.json"
assert_eq "V13.3 — verrou du compartiment w (vrai script) : repli, les deux missions vivent" "$(DAGS "$WORK/v133.json")" "MISSION-1:running,MISSION-2:running"
R; DLR "$LR" acquire --owner=t --step=s --ws=x >/dev/null 2>&1
Q "$SCRIPTS" "$LR" "$CND" "$WORK/v134.json"
assert_eq "V13.4 — verrou du compartiment x seulement (vrai script) : les missions de w restent abandonnee" "$(DAGS "$WORK/v134.json")" "MISSION-1:abandonnee,MISSION-2:abandonnee"
R; Q "$SCRIPTS" "$LR" "$CND" "$WORK/v135.json"
assert_eq "V13.5 — aucun verrou (vrai script) : lu et libre, abandonnee (pas inconnu)" "$(DAGS "$WORK/v135.json")" "MISSION-1:abandonnee,MISSION-2:abandonnee"
LRP="$WORK/lab-reel-plat"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$LRP/.planning/ROADMAP.md"
printf '%s\n' "$NOEUD" | wr "$LRP/.planning/missions/MISSION-1.dag.json"
git -C "$LRP" init -q
DLR "$LRP" acquire --owner=t --step=s > "$WORK/acqp.json" 2>/dev/null
DLR "$LRP" status --all > "$WORK/stp.json" 2>/dev/null
assert_eq "V13.6 — témoin lab plat : le vrai script rend l'objet d'UN verrou, sans scope ni ws" "$(G "$WORK/acqp.json" 'j.acquired')|$(G "$WORK/stp.json" 'j.present+":"+("scope" in j)+":"+("ws" in j)+":"+("locks" in j)')" "true|true:false:false:false"
Q "$SCRIPTS" "$LRP" "$CND" "$WORK/v136.json"
assert_eq "V13.7 — lab plat, vrai script, verrou tenu : running" "$(ONE "$WORK/v136.json" .etat)" "running"
rm -rf "$LRP/.planning/DRIVER.lock" "$LRP/.git/vf-driver"
Q "$SCRIPTS" "$LRP" "$CND" "$WORK/v137.json"
assert_eq "V13.8 — lab plat, vrai script, verrou absent : abandonnee" "$(ONE "$WORK/v137.json" .etat)" "abandonnee"

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
