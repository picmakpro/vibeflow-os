#!/usr/bin/env bash
# test-cockpit-projet.sh — graphe Projet du cockpit sur tout lab GSD (CKPT-06) : plat au gabarit GSD (P1),
# partitionné (P2), sans liste de jalons avec missions (P3), contrat et absence de nom de compartiment (P4),
# identité d'une phase = (compartiment, numéro) (P5). Fixtures écrites par la suite dans mktemp.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'who') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir }))); }
else if (what === 'reveal') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.revealDoing(root, extra, { home, scriptsDir }))); }
else if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <schemaId> <sortie.json> — clés requises et typées, clés interdites à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id];
const out = JSON.parse(fs.readFileSync(outF, 'utf8'));
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
for (const w of out.workers || []) {
  for (const k of spec.travailleur.requis) if (!(k in w)) errs.push(`travailleur ${w.id} : clé ${k} absente`);
  if (!spec.kinds.includes(w.kind)) errs.push(`kind inconnu : ${w.kind}`);
}
for (const s of Object.values(out.sources || {})) if (!spec.etatsSource.includes(s.etat)) errs.push(`état de source inconnu : ${s.etat}`);
for (const n of out.nodes || []) for (const k of spec.noeud?.requis || []) if (!(k in n)) errs.push(`nœud ${n.id} : clé ${k} absente`);
for (const f of out.files || []) for (const k of spec.element?.requis || []) if (!(k in f)) errs.push(`élément ${f.p} : clé ${k} absente`);
for (const l of out.links || []) for (const k of spec.lien?.requis || []) if (!(k in l)) errs.push(`lien : clé ${k} absente`);
for (const k of spec.meta?.requis || []) if (!(k in (out.meta || {}))) errs.push(`meta.${k} absente`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }   # wr <fichier> < contenu
graph() { Q project "$1" > "$2"; }

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
assert_eq "P1.1 — ph-1 done, ph-2 active" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>/^ph-\d$/.test(n.id)).map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:active"
assert_eq "P1.2 — plan 01-01 done, 02-01 active" "$(G "$WORK/g1.json" 'j.files.filter(f=>/^0\d-01 /.test(f.name)).map(f=>f.name.slice(0,5)+":"+f.st).join(",")')" "01-01:done,02-01:active"
assert_eq "P1.3 — lien ph-1 vers ph-2 de type import" "$(G "$WORK/g1.json" 'j.links.filter(l=>l.a==="n:ph-1"&&l.b==="n:ph-2"&&l.k==="import").length')" "1"
assert_eq "P1.4 — exigence AUTH-01 sous ph-1.req" "$(G "$WORK/g1.json" 'j.files.filter(f=>f.n==="ph-1.req").map(f=>f.name).join(",")')" "AUTH-01"
assert_eq "P1.5 — jalon v1.0 MVP actif, pied 1/2" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>n.id==="ms-v1.0-mvp").map(n=>n.st+"|"+n.foot).join(",")')" "active|1/2 phases · 50 %"
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

# ---------- P4 — contrat, syntaxe, aucun nom de compartiment de ce dépôt ----------
echo "=== P4 — contrat et généralité ==="
for n in 1 2 3 5; do assert_eq "P4.$n — graphe $n conforme au contrat" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g$n.json")" "OK"; done
BAD=0; for f in "$SCRIPTS"/vf-cockpit-*.mjs; do node --check "$f" || BAD=$((BAD+1)); done
assert_eq "P4.6 — node --check passe sur chaque .mjs du socle" "$BAD" "0"
printf '%s\n' "const w = 'fiabilite';" > "$WORK/temoin.mjs"
assert_eq "P4.7 — témoin positif : le contrôle de noms voit un nom codé en dur" "$(cat "$WORK/temoin.mjs" | grep -cE 'fiabilite|gouvernance')" "1"
assert_eq "P4.8 — aucun nom de compartiment de ce dépôt dans les sources du socle" "$(cat "$SCRIPTS"/vf-cockpit-*.mjs | grep -cE 'fiabilite|gouvernance')" "0"

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
