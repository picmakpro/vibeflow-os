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
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/locks"
# vie d'une mission (VFSG-06) : le planning lit le verrou de driver ; la suite fournit un faux verrou TENU dans un dossier de scripts explicite,
# hors de toute disposition …/cockpit/scripts (sinon le conductor voisin du dépôt serait trouvé, P68-D-29), et un HOME jetable.
export HOME="$WORK/home"
printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": true, \\"ws\\": \\"\\", \\"stale\\": false, \\"ttl\\": 1800, \\"progress_age_seconds\\": 30}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' > "$WORK/locks/driver-lock.sh"; chmod +x "$WORK/locks/driver-lock.sh"
export VF_COCKPIT_SCRIPTS_DIR="$WORK/locks"

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
if (a.version !== 2) ecarts.push('version');
if (!eq(a.etats, m.ETATS)) ecarts.push('etats');
if (!eq(a.reste, m.RESTE)) ecarts.push('reste');
const echantillon = m.avancement({ ph: { done: false }, fichiers: [], missions: [] });
if (!eq(Object.keys(a.requis || {}).sort(), Object.keys(echantillon).sort())) ecarts.push('requis');
const typeDe = (v) => (Array.isArray(v) ? 'array' : typeof v);
for (const [k, t] of Object.entries(a.requis || {})) if (t !== 'any' && k in echantillon && typeDe(echantillon[k]) !== t) ecarts.push('type:' + k);
const vocab = [...m.ETATS_MISSION].sort();
if (!eq(Object.keys(a.vie?.requis || {}).sort(), ['progressAgeS', 'stale', 'tenu', 'ttl'])) ecarts.push('vie');
if (!eq([...(a.missionEtats || [])].sort(), vocab)) ecarts.push('missionEtats');
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
} else if (what === 'requis' || what === 'missionEtats') {
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  if (what === 'requis') delete j.avancement.requis.reste; else j.avancement.missionEtats = ['running'];
  fs.writeFileSync(f, JSON.stringify(j, null, 2));
} else {
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  if (j.avancement) j.avancement.etats = j.avancement.etats.filter((e) => e !== 'a-recetter');
  fs.writeFileSync(f, JSON.stringify(j, null, 2));
}
console.log('muté');
JS
cat > "$AUX/mutsub.mjs" <<'JS'
// mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; "ancre absente" si $FROM n'y est pas
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
cat > "$AUX/unit.mjs" <<'JS'
// unit.mjs <dossier de scripts> choix|norm — appels directs du module d'avancement
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , dir, what] = process.argv;
const a = await import(pathToFileURL(path.join(dir, 'vf-cockpit-avancement.mjs')).href);
if (what === 'choix') {
  const ms = [{ nom: 'MISSION-3', regle: 2, nodes: [{ status: 'ready' }] }, { nom: 'zeta', regle: 1, nodes: [{ status: 'running' }] }];
  console.log(JSON.stringify(a.avancement({ ph: { done: false }, fichiers: [], missions: ms }).mission));
} else {
  const p = await import(pathToFileURL(path.join(dir, 'vf-cockpit-planning.mjs')).href);
  const ok = ['01', '1', '02.1', '2.10'].map((x) => { const ph = { n: p.normNum(x), ws: null }; return a.trouverPhase(new Map([['k', ph]]), x, null) === ph; });
  console.log(ok.join());
}
JS
# mut <nom> <fichier> <de> <vers> : copie fraîche des scripts dans $WORK/mut-<nom>, une substitution exacte ; rend « muté » ou « ancre absente »
mut() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
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
wr "$B/missions/MISSION-3.dag.json" <<'JSON'
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

# lab L7 (PU-G-098) : phases sans plan ni mission vivante — rien commencé : « cadrage, plan, exécution » précèdent le reste ; un CONTEXT retire « cadrage » ; une mission vivante ou un plan les retire
L7="$WORK/lab-l7"; B="$L7/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Vide** - rien
- [ ] **Phase 2: Cadrée** - un CONTEXT
- [ ] **Phase 3: Vivante** - mission en cours, aucun plan
- [ ] **Phase 4: Planifiée** - un plan
MD
mkdir -p "$B/phases/01-vide"
echo ctx | wr "$B/phases/02-cadree/02-CONTEXT.md"
wr "$B/missions/MISSION-3.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}
JSON
plans "$B/phases/04-planifiee" 04 1 0
initgit "$L7"

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
graph "$L7" "$WORK/g7.json"; plan "$L7" "$WORK/p7.json"
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
assert_eq "A2.2 — carte ph-1 : statut « recette » (teinte « en cours », glyphe et mot « À recetter », P71.5-D-20) et pied « à recetter »" "$(NDF "$WORK/gl.json" ph-1 .st)|$(G "$WORK/gl.json" 'j.nodes.find(n=>n.id==="ph-1").foot.includes("à recetter")')" "recette|true"
r="$(mut recette-actif "vf-cockpit-project.mjs" "'a-recetter': 'recette'" "'a-recetter': 'active'")"; node "$AUX/q.mjs" "$WORK/mut-recette-actif" project "$L" > "$WORK/gl-recette.json" 2>/dev/null
assert_eq "A2.2m — témoin rouge : l'ancienne projection (« à recetter » -> active, mot « En cours » sur la carte) fait lire autre chose que A2.2 veut" "$r|$(NDF "$WORK/gl-recette.json" ph-1 .st)" "muté|active"
VIEWER="$SCRIPTS/../skills/cockpit-moteur/assets/viewer.html"; UIV="$SCRIPTS/../skills/cockpit-moteur/assets/ui/00-vibeflow.js"
assert_eq "A2.2b — le viewer écrit « À recetter » pour le statut recette, et la carte recette garde la teinte de la carte en cours" "$(grep -c "recette: 'À recetter'" "$VIEWER")|$(grep -c '\.card\.st-recette' "$UIV" | awk '{print ($1>=3)?"ok":"ko"}')" "1|ok"
assert_eq "A2.3 — lab L4 : états des phases 1 à 5" "$(G "$WORK/p4.json" 'j.phases.map(p=>p.avancement?.etat).join()')" "fait,en-cours,en-cours,a-recetter,a-recetter"
assert_eq "A2.4 — phase 2 du lab L (aucun plan) : a-faire" "$(PHF "$WORK/pl.json" '|2' etat)" "a-faire"
assert_eq "A2.5 — clés exactes de l'objet et version 2" "$(G "$WORK/pl.json" 'Object.keys(j.phases[0].avancement||{}).sort().join()+"|"+j.phases[0].avancement?.version')" "correctifs,etat,mission,plans,reste,version|2"
assert_eq "A2.6 — mission de la phase 1 : nom, état et vie ; de la phase 2 : null" "$(G "$WORK/pl.json" 'JSON.stringify(j.phases[0].avancement?.mission)+"|"+JSON.stringify(j.phases[1].avancement?.mission)')" '{"nom":"2026-11-01-v-cockpit","etat":"done","vie":null}|null'

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

# PU-G-098 : une phase sans plan ni mission vivante dit ce qui reste depuis le début
for i in 1 2 3 4; do
  case $i in 1) e='["cadrage","plan","execution","verification","cloture"]';; 2) e='["plan","execution","verification","cloture"]';; 3|4) e='["verification","cloture"]';; esac
  assert_eq "A5.1$i — reste de la phase $i du lab L7 (PU-G-098)" "$(G "$WORK/p7.json" "JSON.stringify(j.phases[$((i-1))].avancement?.reste)")" "$e"
done
assert_eq "A5.15 — la carte de la phase 1 du lab L7 écrit « Reste : cadrage, plan, exécution, vérification, clôture. », celle de la phase 2 « plan, exécution, vérification, clôture »" "$(NDF "$WORK/g7.json" ph-1 .details | grep -c 'Reste : cadrage, plan, exécution, vérification, clôture\.')|$(NDF "$WORK/g7.json" ph-2 .details | grep -c 'Reste : plan, exécution, vérification, clôture\.')|$(NDF "$WORK/g7.json" ph-4 .details | grep -c 'Reste : vérification, clôture\.')" "1|1|1"

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
echo "=== A7 — contrat avancement@2 ==="
assert_eq "A7.1 — le bloc avancement du contrat égale ETATS, RESTE et ETATS_MISSION, version 2" "$(node "$AUX/contrat.mjs" "$SCRIPTS")" "ok"
node "$AUX/mutate.mjs" interface "$WORK/mut/vf-cockpit-interface.json" >/dev/null
assert_has "A7.2 — copie mutée du contrat (un état retiré) : la dérive est vue" "$(node "$AUX/contrat.mjs" "$WORK/mut")" "dérive"

# ---------- A8 — indépendance du compartiment actif ----------
echo "=== A8 — compartiment actif sans effet ==="
assert_eq "A8.1 — lab partitionné, pointeur sur beta : la phase 1 d'alpha est a-recetter" "$(PHF "$WORK/p6.json" 'alpha|1' etat)" "a-recetter"

# ---------- A9 à A12 — correction de revue : chaque mutant doit rougir ----------
P_="vf-cockpit-project.mjs"; V_="vf-cockpit-avancement.mjs"
# L7 : statut d'un plan non fait (P69-PL-04) — un nœud running le désigne par id (01-01) ou par chemin dans scope (01-02) ; 01-03 n'est pas désigné
L7="$WORK/lab-l7"; B="$L7/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$B/ROADMAP.md"
plans "$B/phases/01-a" 01 3 0
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"01-01","step":"s","deps":[],"status":"running"},{"id":"zz","step":"s","deps":[],"status":"running","scope":[".planning/phases/01-a/01-02-PLAN.md"]}]}
JSON
initgit "$L7"
# L8 : décimal, mission running sur une phase à 100 % de plans faits
L8="$WORK/lab-l8"; B="$L8/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n- [ ] **Phase 2: Deux** - b\n' | wr "$B/ROADMAP.md"
plans "$B/phases/01-a" 01 1 1; printf '<objective>Correctif décimal</objective>\n' | wr "$B/phases/01-a/01-01.1-PLAN.md"
plans "$B/phases/02-b" 02 2 2
wr "$B/missions/MISSION-2.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"running"}]}
JSON
initgit "$L8"
FILES7='j.files.filter(f=>f.p.endsWith("-PLAN.md")).map(f=>f.name.slice(0,5)+":"+f.st).join()'
P1='JSON.stringify(j.phases[0].avancement?.plans)+"|"+j.phases[0].avancement?.etat'
echo "=== A9 — statut d'un plan non fait (P69-PL-04) ==="
graph "$L7" "$WORK/g7.json"
assert_eq "A9.1 — nœud désignant par id (01-01) et par scope (01-02) : actifs ; 01-03 voisin non désigné : todo" "$(G "$WORK/g7.json" "$FILES7")" "01-01:active,01-02:active,01-03:todo"
i=2
for m in "faux~enCours.some((x) => x.id === pid || (Array.isArray(x.scope) && x.scope.includes(p))) ? 'active'~false ? 'active'~01-01:todo,01-02:todo,01-03:todo" \
         "phase-active~enCours.some((x) => x.id === pid || (Array.isArray(x.scope) && x.scope.includes(p))) ? 'active'~st === 'active' ? 'active'~01-01:active,01-02:active,01-03:active" \
         "sans-id~x.id === pid || (Array~false || (Array~01-01:todo,01-02:active,01-03:todo" \
         "sans-scope~(Array.isArray(x.scope) && x.scope.includes(p))~false~01-01:active,01-02:todo,01-03:todo"; do
  IFS='~' read -r nom de vers attendu <<<"$m"
  r="$(mut "pl04-$nom" "$P_" "$de" "$vers")"; node "$AUX/q.mjs" "$WORK/mut-pl04-$nom" project "$L7" > "$WORK/g7-$nom.json" 2>/dev/null
  assert_eq "A9.$i — mutant « $nom » : l'assertion A9.1 le voit" "$r|$(G "$WORK/g7-$nom.json" "$FILES7")" "muté|$attendu"; i=$((i+1))
done
echo "=== A10 — un champ « phase » inconnu ne se corrige jamais (P69-PL-06) ==="
assert_eq "A10.1 — MISSION-3 portant « phase: 99 » : hors phase" "$(NDF "$WORK/g3.json" dag-MISSION-3 .parent)" "missions"
r="$(mut repli-regle2 "$V_" "return p ? { cle: p.key, regle: 1 } : null; }" "if (p) return { cle: p.key, regle: 1 }; }")"; node "$AUX/q.mjs" "$WORK/mut-repli-regle2" project "$L3" > "$WORK/g3-mut.json" 2>/dev/null
assert_eq "A10.2 — mutant « repli sur la règle 2 » : MISSION-3 irait à ph-3, A10.1 le voit" "$r|$(NDF "$WORK/g3-mut.json" dag-MISSION-3 .parent)" "muté|ph-3"
echo "=== A11 — décompte, état et choix de la mission ==="
plan "$L8" "$WORK/p8.json"
assert_eq "A11.1 — 01-01.1-PLAN.md sans SUMMARY est un plan à part : 1 fait sur 2, en-cours" "$(G "$WORK/p8.json" "$P1")" '{"faits":1,"total":2}|en-cours'
r="$(mut sans-decimal "$V_" "plans.add(f.slice(0, -'-PLAN.md'.length))" "plans.add(f.slice(0, -'-PLAN.md'.length).replace(/\\.\\d+$/, ''))")"; node "$AUX/q.mjs" "$WORK/mut-sans-decimal" planning "$L8" > "$WORK/p8-m1.json" 2>/dev/null
assert_eq "A11.2 — mutant « suffixe décimal retiré » : A11.1 le voit" "$r|$(G "$WORK/p8-m1.json" "$P1")" 'muté|{"faits":1,"total":1}|a-recetter'
assert_eq "A11.3 — phase 2 à 2/2 plans faits avec une mission running : a-recetter" "$(G "$WORK/p8.json" 'j.phases[1].avancement?.etat')" "a-recetter"
r="$(mut sans-lance "$V_" "faits === total ? 'a-recetter'" "faits === total && !lance ? 'a-recetter'")"; node "$AUX/q.mjs" "$WORK/mut-sans-lance" planning "$L8" > "$WORK/p8-m2.json" 2>/dev/null
assert_eq "A11.4 — mutant « && !lance » : A11.3 le voit" "$r|$(G "$WORK/p8-m2.json" 'j.phases[1].avancement?.etat')" "muté|en-cours"
assert_eq "A11.5 — deux missions rattachées dont une running : mission désigne la running" "$(node "$AUX/unit.mjs" "$SCRIPTS" choix)" '{"nom":"zeta","etat":"running"}'
r="$(mut sans-tri "$V_" "  l.sort(" "  l.slice(")"
assert_eq "A11.6 — mutant « tri supprimé » : A11.5 le voit" "$r|$(node "$AUX/unit.mjs" "$WORK/mut-sans-tri" choix)" 'muté|{"nom":"MISSION-3","etat":"ready"}'
echo "=== A12 — le contrat suit l'objet rendu et le vocabulaire des missions ==="
for k in requis missionEtats; do
  rm -rf "$WORK/mut-c-$k"; mkdir -p "$WORK/mut-c-$k"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$WORK/mut-c-$k/"
  node "$AUX/mutate.mjs" "$k" "$WORK/mut-c-$k/vf-cockpit-interface.json" >/dev/null
  assert_eq "A12 — copie du contrat sans « $k » conforme : la dérive est nommée" "$(node "$AUX/contrat.mjs" "$WORK/mut-c-$k")" "dérive : $k"
done
assert_eq "A12.3 — normalisation des numéros : 01, 1, 02.1, 2.10 se résolvent comme normNum" "$(node "$AUX/unit.mjs" "$SCRIPTS" norm)" "true,true,true,true"

# ---------- A13 — le jalon en cours est celui du STATE (CKPT-16) ----------
# L9 : deux jalons ouverts, le premier du ROADMAP (alpha) n'est pas celui que nomme le STATE (beta). Le STATE ne décide pas de l'état des PHASES (P69-D-08) : il choisit seulement quel jalon la vue « en cours » met en avant.
L9="$WORK/lab-l9"; B="$L9/.planning"
wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **alpha** - Phases 1
- 🚧 **beta** - Phases 2

## Phases

- [ ] **Phase 1: Un** - a
- [ ] **Phase 2: Deux** - b
MD
printf -- '---\nmilestone: beta\nstatus: executing\ncurrent_phase: 1\n---\n' | wr "$B/STATE.md"
plans "$B/phases/01-a" 01 2 1; plans "$B/phases/02-b" 02 2 1
initgit "$L9"
graph "$L9" "$WORK/g9.json"
FLUX='j.flows.map(f=>f.title).join()+"|"+j.meta.vf.next.map(n=>n.id).join()'
echo "=== A13 — jalon en cours = jalon du STATE ==="
assert_eq "A13.0 — contrôle positif : les deux jalons sont ouverts (le premier du ROADMAP l'est aussi)" "$(NDF "$WORK/g9.json" ms-alpha .st)|$(NDF "$WORK/g9.json" ms-beta .st)" "active|active"
assert_eq "A13.1 — le STATE nomme beta : la trajectoire et les prochaines phases sont celles de beta" "$(G "$WORK/g9.json" "$FLUX")" "Trajectoire de beta|n:ph-2"
r="$(mut sans-state "$P_" "msList.find((m) => state.milestone && m.key === state.milestone && m.ws === (layout.actif || null) && m.st !== 'done') || " "")"; node "$AUX/q.mjs" "$WORK/mut-sans-state" project "$L9" > "$WORK/g9-mut.json" 2>/dev/null
assert_eq "A13.2 — mutant « le STATE n'est plus lu » : la trajectoire redevient celle d'alpha, A13.1 le voit" "$r|$(G "$WORK/g9-mut.json" "$FLUX")" "muté|Trajectoire d'alpha|n:ph-1"
assert_eq "A13.3 — élision à la source (P70-D-04) : un jalon dont la clé commence par une voyelle donne « Trajectoire d'alpha », jamais « de alpha »" "$(G "$WORK/g9-mut.json" 'j.flows[0].title')" "Trajectoire d'alpha"

# ---------- A14 — aucune lecture du graphe Projet n'ouvre un fichier non régulier (famille de read(), 69-01) ----------
# Un PLAN lié à /dev/zero ou un pointeur active-workstream lié à /dev/zero (git versionne les liens symboliques) ne doit ni bloquer ni remplir la mémoire.
# Enfant borné par SIGKILL (harnais de E31 de test-cockpit-equipe.sh) ; liens supprimés dans tous les cas.
cat > "$AUX/borne.mjs" <<'JS'
// borne.mjs <ms> <commande node et arguments...> : enfant node borné par une limite de temps (SIGKILL, sans tube) ; une ligne JSON { timedOut, status, out }
import { spawnSync } from 'node:child_process';
const [, , ms, ...args] = process.argv;
const r = spawnSync(process.execPath, args, { timeout: Number(ms), killSignal: 'SIGKILL', encoding: 'utf8', maxBuffer: 64 << 20 });
console.log(JSON.stringify({ timedOut: r.error?.code === 'ETIMEDOUT', status: r.status, out: r.stdout || '' }));
JS
L10="$WORK/lab-l10"; B="$L10/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$B/ROADMAP.md"
plans "$B/phases/01-a" 01 1 0
initgit "$L10"
L11="$WORK/lab-l11"; B11="$L11/.planning"
printf -- '- [ ] **Phase 1: Un** - a\n' | wr "$B11/workstreams/alpha/ROADMAP.md"
plans "$B11/workstreams/alpha/phases/01-a" 01 1 0
initgit "$L11"
# QB <dossier de scripts> <lab> <expression sur le graphe> : « rendu|<valeur> » ou « bloqué|illisible »
QB() { node "$AUX/borne.mjs" 6000 "$AUX/q.mjs" "$1" project "$2" > "$WORK/qb.json"; G "$WORK/qb.json" "(j.timedOut?\"bloqué\":\"rendu\")+\"|\"+(()=>{try{const g=JSON.parse(j.out);return $3}catch{return \"illisible\"}})()"; }
NPLANS='g.files.filter(f=>f.p.endsWith("-PLAN.md")).length'; NNODES='g.nodes.length>0'
echo "=== A14 — lecture bornée des fichiers du dépôt ==="
assert_eq "A14.0 — contrôle positif : sans lien spécial, le graphe se rend (1 plan, enfant borné)" "$(QB "$SCRIPTS" "$L10" "$NPLANS")" "rendu|1"
assert_eq "A14.1 — contrôle positif : lab partitionné sans lien, le graphe se rend" "$(QB "$SCRIPTS" "$L11" "$NNODES")" "rendu|true"
assert_eq "A14.2 — le source de project.mjs n'a plus de lecture à lui (read partagé de planning)" "$(grep -c 'const read = ' "$SCRIPTS/vf-cockpit-project.mjs")" "0"
# AUDC-A-02 : le PLAN et le pointeur sont des liens vers un fichier spécial (tube) DANS le lab — le confinement à la racine réelle ne les coupe pas, seule la garde de type le fait (un lien sortant est écarté avant : test-cockpit-confinement.sh, familles A et N)
mkfifo "$B/phases/01-a/tube-cible"; ln -s tube-cible "$B/phases/01-a/01-02-PLAN.md"; mkfifo "$B11/tube-pointeur"; ln -s tube-pointeur "$B11/active-workstream"
mut gardeplan vf-cockpit-planning.mjs "return st.isFile() && st.size <= MAX_LECTURE ? fs.readFileSync(f, 'utf8') : '';" "return fs.readFileSync(f, 'utf8');" >/dev/null
mut gardepointeur vf-cockpit-paths.mjs "st.isFile() && st.size <= 4096 ? fs.readFileSync(pf, 'utf8').trim() : ''" "fs.readFileSync(pf, 'utf8').trim()" > "$WORK/ancre-pointeur.txt"
R1="$(QB "$SCRIPTS" "$L10" "$NPLANS")"; M1="$(QB "$WORK/mut-gardeplan" "$L10" "$NPLANS")"
R2="$(QB "$SCRIPTS" "$L11" "$NNODES")"; M2="$(QB "$WORK/mut-gardepointeur" "$L11" "$NNODES")"
rm -f "$B/phases/01-a/01-02-PLAN.md" "$B/phases/01-a/tube-cible" "$B11/active-workstream" "$B11/tube-pointeur"
assert_eq "A14.3 — un PLAN lié à un tube du lab ne bloque pas le graphe Projet (les deux plans sont listés)" "$R1" "rendu|2"
assert_eq "A14.4 — mutant : lecture sans contrôle du type -> le graphe est bloqué (SIGKILL), détecté" "$M1" "bloqué|illisible"
assert_eq "A14.5 — un pointeur active-workstream lié à un tube du lab ne bloque pas la résolution du compartiment" "$R2" "rendu|true"
assert_eq "A14.6 — mutant : pointeur lu sans contrôle (ancre présente) -> bloqué, détecté" "$(cat "$WORK/ancre-pointeur.txt")|$M2" "muté|bloqué|illisible"

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
