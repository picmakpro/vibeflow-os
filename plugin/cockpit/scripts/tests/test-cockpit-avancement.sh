#!/usr/bin/env bash
# test-cockpit-avancement.sh — avancement des phases dans readPlanning et sur la carte Projet (CKPT-13 à CKPT-18 ;
# P69-D-01 à P69-D-09). Sections :
#   A0 contrôles positifs des fixtures (verts avant et après le code)
#   A1 témoin (a) : « 7/7 plans · 4 correctifs », jamais « 11/7 » (CKPT-14)
#   A2 témoin (b) : STATE ailleurs, plans faits -> a-recetter ; quatre états, clés exactes de l'objet (CKPT-13)
#   A3 témoin (c) : rattachement des missions, règles 1 à 3 et ordre (CKPT-15)
#   A4 témoin (d) : jalon 📋 en cours, pied « N clos · … · N % » strict (CKPT-16)
#   A5 étapes restantes lues sur fichiers (CKPT-17) · A6 aucune connexion sortante, avec témoin positif
#   A18 la règle STATE -> statut est retirée de phaseStatus, copie mutée détectée (CKPT-18)
#   A7 le bloc `avancement` du contrat égale les exports, copie mutée détectée · A8 indépendance du compartiment actif
# Fixtures écrites par la suite dans mktemp. Aucun serveur ni navigateur n'est lancé.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
else if (what === 'planning') {
  const m = await imp('vf-cockpit-planning.mjs'); const P = m.readPlanning(root);
  console.log(JSON.stringify({
    phases: [...P.phases.values()].map((p) => ({ key: p.key, n: p.n, done: p.done, avancement: p.avancement })),
    dags: P.dags.map((d) => ({ name: d.name, phaseKey: d.phaseKey, regle: d.regle })),
  }));
}
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# sonde de connexions sortantes : chaque appel est enregistré (une ligne), puis refusé — aucun réseau réel
cat > "$AUX/sonde.mjs" <<'JS'
import net from 'node:net';
import tls from 'node:tls';
import dns from 'node:dns';
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
const out = process.env.VF_SONDE_OUT;
fs.appendFileSync(out + '.charge', 'sonde chargée\n');
const rec = (genre, cible) => { fs.appendFileSync(out, `${genre} ${String(cible ?? '')}\n`); };
const refus = (genre) => (...a) => { rec(genre, typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : ' + genre); };
net.connect = refus('net'); net.createConnection = refus('net'); tls.connect = refus('tls');
net.Socket.prototype.connect = function (...a) { rec('net', typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : socket'); };
dns.lookup = refus('dns'); if (dns.promises) dns.promises.lookup = async (...a) => { rec('dns', a[0]); throw new Error('sonde : dns'); };
http.request = refus('http'); http.get = refus('http'); https.request = refus('https'); https.get = refus('https');
globalThis.fetch = (u) => { rec('fetch', typeof u === 'string' ? u : u?.url ?? String(u)); return Promise.reject(new Error('sonde : fetch')); };
JS
cat > "$AUX/temoin-sortant.mjs" <<'JS'
fetch('https://exemple.test/').catch(() => {});
import('node:net').then((m) => { try { (m.default || m).connect(443, 'exemple.test'); } catch {} });
setTimeout(() => process.exit(0), 300);
JS
cat > "$AUX/contrat.mjs" <<'JS'
// contrat.mjs <dossier de scripts> — le bloc `avancement` de l'interface égale les exports du module d'avancement
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const dir = process.argv[2];
let m; try { m = await import(pathToFileURL(path.join(dir, 'vf-cockpit-avancement.mjs')).href); } catch { console.log('module absent'); process.exit(0); }
const a = JSON.parse(fs.readFileSync(path.join(dir, 'vf-cockpit-interface.json'), 'utf8')).avancement;
if (!a) { console.log('clé avancement absente du contrat'); process.exit(0); }
const eq = (x, y) => JSON.stringify(x) === JSON.stringify(y);
const ecarts = [];
if (a.version !== 1) ecarts.push('version');
if (!eq(a.etats, m.ETATS)) ecarts.push('etats');
if (!eq(a.reste, m.RESTE)) ecarts.push('reste');
console.log(ecarts.length ? 'dérive : ' + ecarts.join(',') : 'ok');
JS
cat > "$AUX/mutate.mjs" <<'JS'
// mutate.mjs <phaseStatus|interface> <fichier> — réintroduit la règle STATE / retire un état du contrat, dans une COPIE
import fs from 'node:fs';
const [, , what, f] = process.argv;
if (what === 'phaseStatus') {
  const lines = fs.readFileSync(f, 'utf8').split('\n');
  const i = lines.findIndex((l) => l.startsWith('  const phaseStatus = '));
  if (i < 0) { console.log('ancre absente'); process.exit(1); }
  lines[i] = "  const phaseStatus = (ph) => ph.done ? 'done' : ph.n === curPhase ? 'active' : 'todo';";
  fs.writeFileSync(f, lines.join('\n'));
} else {
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  if (j.avancement) j.avancement.etats = j.avancement.etats.filter((e) => e !== 'a-recetter');
  fs.writeFileSync(f, JSON.stringify(j, null, 2));
}
console.log('muté');
JS
Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }   # wr <fichier> < contenu
graph() { Q project "$1" > "$2"; }
plan() { Q planning "$1" > "$2"; }
# plans <dossier> <préfixe> <nb de plans> <nb de sommes> : PLAN 01..n, SUMMARY pour les m premiers
plans() { local d="$1" p="$2" n="$3" m="$4" i id; for i in $(seq 1 "$n"); do id="$(printf '%s-%02d' "$p" "$i")"; printf '<objective>Plan %s</objective>\n' "$id" | wr "$d/$id-PLAN.md"; [ "$i" -le "$m" ] && echo ok > "$d/$id-SUMMARY.md"; done; return 0; }
initgit() { git -C "$1" init -q; }
# accesseurs sur les sorties
PHF() { G "$1" "(j.phases.find(p=>p.key===\"$2\")||{avancement:null}).avancement?.$3 ?? \"absent\""; }   # PHF <planning.json> <clé de phase> <champ>
NDF() { G "$1" "(j.nodes.find(n=>n.id===\"$2\")||{})$3 ?? \"absent\""; }                                  # NDF <graphe.json> <id> <.champ>

# ---------- fixtures ----------
# lab L : fixtures (a) à (d) — jalon 📋, 2 phases, STATE sur la phase 9, 7 PLAN + 7 SUMMARY + 4 correctifs, un DAG phase 1
L="$WORK/lab-l"; B="$L/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 📋 **v-test** - Phases 1-2

## Phases

- [ ] **Phase 1: Cockpit** - premier jet
- [ ] **Phase 2: Suite** - second jet

### Phase 1: Cockpit
**Goal**: Avancer le cockpit
**Depends on**: Nothing (first phase)

### Phase 2: Suite
**Goal**: La suite
**Depends on**: Phase 1
MD
printf -- '---\nstatus: executing\ncurrent_phase: 9\n---\n' | wr "$B/STATE.md"
plans "$B/phases/01-cockpit" 01 7 7
for x in A B C D; do echo ok > "$B/phases/01-cockpit/01-FIX-$x-SUMMARY.md"; done
mkdir -p "$B/phases/02-suite"
wr "$B/missions/2026-11-01-v-cockpit.dag.json" <<'JSON'
{"phase":"1","ws":null,"nodes":[{"id":"n1","step":"un","deps":[],"status":"done"},{"id":"n2","step":"deux","deps":["n1"],"status":"done"}]}
JSON
initgit "$L"

# lab L3 : règles de rattachement
L3="$WORK/lab-l3"; B="$L3/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Un** - a
- [ ] **Phase 2: Deux** - b
- [ ] **Phase 3: Trois** - c
- [ ] **Phase 4: Quatre** - d
MD
wr "$B/MISSION-2.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"ready"}]}
JSON
wr "$B/phases/03-x/03-mission.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"ready"}]}
JSON
wr "$B/missions/MISSION-4.dag.json" <<'JSON'
{"phase":"1","nodes":[{"id":"a","step":"s","deps":[],"status":"ready"}]}
JSON
wr "$B/missions/perdu.dag.json" <<'JSON'
{"phase":"99","nodes":[{"id":"a","step":"s","deps":[],"status":"ready"}]}
JSON
initgit "$L3"

# lab L4 : les cinq cas d'état et de « reste » (sans section Milestones : jalon synthétique)
L4="$WORK/lab-l4"; B="$L4/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Phases

- [x] **Phase 1: Un** - fait
- [ ] **Phase 2: Deux** - un plan sur deux
- [ ] **Phase 3: Trois** - mission en cours
- [ ] **Phase 4: Quatre** - recette en cours
- [ ] **Phase 5: Cinq** - recette faite
MD
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' | wr "$B/STATE.md"
plans "$B/phases/01-un" 01 1 1
plans "$B/phases/02-deux" 02 2 1
wr "$B/missions/MISSION-3.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}
JSON
plans "$B/phases/04-quatre" 04 2 2
printf '# Recette\n\n**Statut : EN COURS**\n' | wr "$B/phases/04-quatre/04-RECETTE-HUMAINE.md"
plans "$B/phases/05-cinq" 05 1 1
printf '# Recette\n\n**Statut : FAITE — close**\n' | wr "$B/phases/05-cinq/05-RECETTE-HUMAINE.md"
echo ok > "$B/phases/05-cinq/05-VERIFICATION.md"
initgit "$L4"

# lab L5 : mutation — phase 1 cochée, phase 2 avec un PLAN sans SUMMARY, STATE sur la phase 2
L5="$WORK/lab-l5"; B="$L5/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [x] **Phase 1: Un** - fait
- [ ] **Phase 2: Deux** - rien de fait
MD
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' | wr "$B/STATE.md"
plans "$B/phases/01-un" 01 1 1
plans "$B/phases/02-deux" 02 1 0
initgit "$L5"

# lab L6 : partitionné, pointeur actif sur beta ; la phase 1 d'alpha est à 2/2 plans faits
L6="$WORK/lab-l6"; B="$L6/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Un** - a
MD
wr "$B/workstreams/beta/ROADMAP.md" <<'MD'
- [ ] **Phase 2: Deux** - b
MD
echo beta > "$B/active-workstream"
printf -- '---\nstatus: executing\ncurrent_phase: 2\n---\n' | wr "$B/workstreams/beta/STATE.md"
plans "$B/workstreams/alpha/phases/01-un" 01 2 2
initgit "$L6"

graph "$L" "$WORK/gl.json"; plan "$L" "$WORK/pl.json"
graph "$L3" "$WORK/g3.json"
graph "$L4" "$WORK/g4.json"; plan "$L4" "$WORK/p4.json"
graph "$L5" "$WORK/g5.json"
plan "$L6" "$WORK/p6.json"

# ---------- A0 — contrôles positifs des fixtures (verts avant et après le code) ----------
echo "=== A0 — les fixtures sont bien formées ==="
D1="$L/.planning/phases/01-cockpit"
NP="$(ls "$D1" | grep -c -- '-PLAN\.md$')"; NS="$(ls "$D1" | grep -c -- '-SUMMARY\.md$')"; NF="$(ls "$D1" | grep -c -- 'FIX-.*-SUMMARY\.md$')"
assert_eq "A0.1 — fixture (a) : 7 PLAN et 11 SUMMARY dont 4 FIX" "$NP/$NS/$NF" "7/11/4"
assert_eq "A0.2 — le graphe se construit" "$(G "$WORK/gl.json" 'j.nodes.length>0')" "true"
assert_eq "A0.3 — le DAG de la fixture est lu" "$(NDF "$WORK/gl.json" dag-2026-11-01-v-cockpit .kind)" "mission"
assert_eq "A0.4 — le STATE de la fixture pointe la phase 9" "$(G "$WORK/gl.json" 'j.meta.vf.phase')" "9"

# ---------- A1 — témoin (a), CKPT-14 ----------
echo "=== A1 — plans faits et correctifs (témoin a) ==="
assert_has "A1.1 — le pied de ph-1 lit « 7/7 plans · 4 correctifs »" "$(NDF "$WORK/gl.json" ph-1 .foot)" "7/7 plans · 4 correctifs"
assert_not "A1.2 — le pied de ph-1 ne lit pas « 11/7 »" "$(NDF "$WORK/gl.json" ph-1 .foot)" "11/7"
assert_eq "A1.3 — avancement.plans et correctifs de la phase 1" "$(G "$WORK/pl.json" '(j.phases.find(p=>p.key==="|1").avancement ? JSON.stringify(j.phases.find(p=>p.key==="|1").avancement.plans)+"|"+j.phases.find(p=>p.key==="|1").avancement.correctifs : "absent")')" '{"faits":7,"total":7}|4'

# ---------- A2 — témoin (b), CKPT-13 ----------
echo "=== A2 — états d'avancement (témoin b) ==="
assert_eq "A2.1 — phase 1 (7/7 plans, STATE sur la phase 9) : a-recetter" "$(PHF "$WORK/pl.json" '|1' etat)" "a-recetter"
assert_eq "A2.2 — carte ph-1 : statut projeté et pied « à recetter »" "$(NDF "$WORK/gl.json" ph-1 .st)|$(G "$WORK/gl.json" 'j.nodes.find(n=>n.id==="ph-1").foot.includes("à recetter")')" "active|true"
assert_eq "A2.3 — lab L4 : états des phases 1 à 5" "$(G "$WORK/p4.json" 'j.phases.map(p=>p.avancement?.etat).join()')" "fait,en-cours,en-cours,a-recetter,a-recetter"
assert_eq "A2.4 — phase 2 du lab L (aucun plan) : a-faire" "$(PHF "$WORK/pl.json" '|2' etat)" "a-faire"
assert_eq "A2.5 — clés exactes de l'objet et version 1" "$(G "$WORK/pl.json" 'Object.keys(j.phases[0].avancement||{}).sort().join()+"|"+j.phases[0].avancement?.version')" "correctifs,etat,mission,plans,reste,version|1"
assert_eq "A2.6 — mission de la phase 1 : nom et état ; de la phase 2 : null" "$(G "$WORK/pl.json" 'JSON.stringify(j.phases[0].avancement?.mission)+"|"+JSON.stringify(j.phases[1].avancement?.mission)')" '{"nom":"2026-11-01-v-cockpit","etat":"done"}|null'

# ---------- A3 — témoin (c), CKPT-15 ----------
echo "=== A3 — rattachement des missions (témoin c) ==="
assert_eq "A3.1 — règle 1 : DAG « phase: 1 » rattaché à ph-1" "$(NDF "$WORK/gl.json" dag-2026-11-01-v-cockpit .parent)" "ph-1"
assert_eq "A3.2 — règle 2 (contrôle positif) : MISSION-2 rattaché à ph-2" "$(NDF "$WORK/g3.json" dag-MISSION-2 .parent)" "ph-2"
assert_eq "A3.3 — règle 3 : DAG du dossier de la phase 3 rattaché à ph-3" "$(NDF "$WORK/g3.json" dag-03-mission .parent)" "ph-3"
assert_eq "A3.4 — ordre : MISSION-4 portant « phase: 1 » va à ph-1" "$(NDF "$WORK/g3.json" dag-MISSION-4 .parent)" "ph-1"
assert_eq "A3.5 — « phase: 99 » inconnue : hors phase, jamais corrigé" "$(NDF "$WORK/g3.json" dag-perdu .parent)" "missions"

# ---------- A4 — témoin (d), CKPT-16 ----------
echo "=== A4 — jalon et pied (témoin d) ==="
assert_eq "A4.1 — jalon 📋 avec une phase à recetter : active" "$(NDF "$WORK/gl.json" ms-v-test .st)" "active"
assert_eq "A4.2 — pied du jalon v-test" "$(NDF "$WORK/gl.json" ms-v-test .foot)" "0 clos · 1 à recetter · 1 à faire · 0 %"
assert_eq "A4.3 — lab L4 : pied strict, 1 clos sur 5 = 20 %" "$(NDF "$WORK/g4.json" ms-phases .foot)" "1 clos · 2 en cours · 2 à recetter · 0 à faire · 20 %"

# ---------- A5 — CKPT-17 ----------
echo "=== A5 — étapes restantes lues sur fichiers ==="
for i in 1 2 3 4 5; do
  case $i in 1) e='[]';; 2|3) e='["verification","cloture"]';; 4) e='["recette","verification","cloture"]';; 5) e='["cloture"]';; esac
  assert_eq "A5.$i — reste de la phase $i du lab L4" "$(G "$WORK/p4.json" "JSON.stringify(j.phases[$((i-1))].avancement?.reste)")" "$e"
done

# ---------- A6 — aucune connexion sortante (T-69-11) ----------
echo "=== A6 — aucune connexion sortante ==="
export VF_SONDE_OUT="$WORK/sonde.out"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/temoin-sortant.mjs" >/dev/null 2>&1
assert_eq "A6.1 — témoin positif : la sonde enregistre un fetch et une connexion délibérés" "$(cut -d' ' -f1 "$VF_SONDE_OUT" | sort | tr '\n' ',')" "fetch,net,"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/q.mjs" "$SCRIPTS" project "$L4" > "$WORK/g4-sonde.json" 2>/dev/null
assert_eq "A6.2 — buildProjectGraph : sonde chargée, 0 appel enregistré" "$([ -s "$VF_SONDE_OUT.charge" ] && echo charge)|$(grep -c . "$VF_SONDE_OUT")|$(G "$WORK/g4-sonde.json" 'j.nodes.length>0')" "charge|0|true"

# ---------- A18 — CKPT-18 : la règle STATE -> statut est retirée ----------
echo "=== A18 — retrait de la règle STATE ==="
assert_eq "A18.1 — lab L5 : le STATE pointe la phase 2, aucun plan n'y est fait : ph-2 reste todo" "$(NDF "$WORK/g5.json" ph-2 .st)" "todo"
assert_eq "A18.0 — le source réel ne compare plus une phase au numéro courant" "$(grep -c '=== curPhase' "$SCRIPTS/vf-cockpit-project.mjs")" "0"
mkdir -p "$WORK/mut"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$WORK/mut/"
node "$AUX/mutate.mjs" phaseStatus "$WORK/mut/vf-cockpit-project.mjs" >/dev/null
node "$AUX/q.mjs" "$WORK/mut" project "$L5" > "$WORK/g5-mut.json" 2>/dev/null
assert_eq "A18.2 — contrôle de mutant : la copie compare au numéro courant et son graphe se construit" "$(grep -c 'ph.n === curPhase' "$WORK/mut/vf-cockpit-project.mjs")|$(G "$WORK/g5-mut.json" 'j.nodes.length>0')" "1|true"
assert_eq "A18.3 — la copie mutée rend ph-2 active : l'assertion A18.1 la voit" "$(NDF "$WORK/g5-mut.json" ph-2 .st)" "active"

# ---------- A7 — contrat versionné (P69-D-10) ----------
echo "=== A7 — contrat avancement@1 ==="
assert_eq "A7.1 — le bloc avancement du contrat égale ETATS et RESTE, version 1" "$(node "$AUX/contrat.mjs" "$SCRIPTS")" "ok"
node "$AUX/mutate.mjs" interface "$WORK/mut/vf-cockpit-interface.json" >/dev/null
assert_has "A7.2 — copie mutée du contrat (un état retiré) : la dérive est vue" "$(node "$AUX/contrat.mjs" "$WORK/mut")" "dérive"

# ---------- A8 — indépendance du compartiment actif ----------
echo "=== A8 — compartiment actif sans effet ==="
assert_eq "A8.1 — lab partitionné, pointeur sur beta : la phase 1 d'alpha est a-recetter" "$(PHF "$WORK/p6.json" 'alpha|1' etat)" "a-recetter"

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
