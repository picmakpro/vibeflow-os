#!/usr/bin/env bash
# test-cockpit-who.sh — socle du cockpit : « au travail » et graphe Projet au contrat versionné
# vibeflow/cockpit-*@1 (P67-D-12, P67-D-14). Fixtures reconstruites dans mktemp à chaque appel.
#   W1 session fraîche listée (témoin positif) · W2 verrou via un driver-lock.sh de HOME
#   W3 graphe Projet d'un lab plat minimal · W4 validateur du contrat (et son refus de `doing`)
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; HOME_T="$WORK/home"; NOSCRIPTS="$WORK/noscripts"
mkdir -p "$AUX" "$HOME_T/.claude/scripts" "$NOSCRIPTS"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

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

# --- fixture : lab git jetable + session Claude Code fraîche ---
LAB="$WORK/lab"; mkdir -p "$LAB"; git -C "$LAB" init -q
SID="aaaa1111-2222-3333-4444-555566667777"
TRD="$HOME_T/.claude/projects/-lab"; mkdir -p "$TRD"
mk_session() { # $1 = fichier, $2 = clé du cwd, $3 = description du dernier appel
  printf '%s\n' "{\"type\":\"user\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"2026-11-01T10:00:00Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":\"salut\"}}" \
    "{\"type\":\"assistant\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"2026-11-01T10:00:05Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"description\":\"$3\"}}]}}" > "$1"
}
mk_session "$TRD/$SID.jsonl" cwd "MARQUEUR-DERNIERE-COMMANDE"

echo "=== W1 — session fraîche listée ==="
Q who "$LAB" "$HOME_T" "$NOSCRIPTS" > "$WORK/who.json"
assert_eq "W1.1 — schéma nommé VibeFlow" "$(G "$WORK/who.json" 'j.schema')" "vibeflow/cockpit-who@1"
assert_eq "W1.2 — la session fraîche est un travailleur kind=session" "$(G "$WORK/who.json" 'j.workers.filter(w=>w.kind==="session"&&w.id==="'$SID'").length')" "1"
assert_eq "W1.3 — source sessions lue" "$(G "$WORK/who.json" 'j.sources.sessions.etat')" "lue"

echo "=== W2 — verrou via le driver-lock.sh de HOME ==="
cat > "$HOME_T/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"locks":[{"present":true,"owner":"mgr-test","step":"exec","ws":"","scope":"repo","age_seconds":10,"stale":false,"children_running":0}]}' ;;
  orphans) echo '{"orphans":[]}' ;;
esac
SH
Q who "$LAB" "$HOME_T" "$NOSCRIPTS" > "$WORK/who2.json"
assert_eq "W2.1 — un travailleur kind=lock" "$(G "$WORK/who2.json" 'j.workers.filter(w=>w.kind==="lock").map(w=>w.id).join(",")')" "mgr-test"
assert_eq "W2.2 — source locks lue" "$(G "$WORK/who2.json" 'j.sources.locks.etat')" "lue"

echo "=== W3 — graphe Projet d'un lab plat minimal ==="
FLAT="$WORK/flat"; mkdir -p "$FLAT/.planning/phases/01-x"
cat > "$FLAT/.planning/ROADMAP.md" <<'MD'
# Roadmap
- [x] **Phase 1: Socle** - premier jet
MD
printf '%s\n' '<objective>Faire le socle</objective>' > "$FLAT/.planning/phases/01-x/01-01-PLAN.md"
printf '%s\n' 'ok' > "$FLAT/.planning/phases/01-x/01-01-SUMMARY.md"
Q project "$FLAT" > "$WORK/proj.json"
assert_eq "W3.1 — schéma Projet nommé VibeFlow" "$(G "$WORK/proj.json" 'j.schema')" "vibeflow/cockpit-project@1"
assert_eq "W3.2 — ph-1 est fait" "$(G "$WORK/proj.json" 'j.nodes.filter(n=>n.id==="ph-1").map(n=>n.st).join(",")')" "done"
assert_eq "W3.3 — le plan 01-01 est fait" "$(G "$WORK/proj.json" 'j.files.filter(f=>f.name==="01-01").map(f=>f.st).join(",")')" "done"

echo "=== W4 — validateur du contrat versionné ==="
assert_eq "W4.1 — sortie « au travail » conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@1 "$WORK/who2.json")" "OK"
assert_eq "W4.2 — graphe Projet conforme" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/proj.json")" "OK"
node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));j.workers[0].doing="x";fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$WORK/who2.json" "$WORK/who-doing.json"
R=$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-who@1 "$WORK/who-doing.json"); RC=$?
assert_has "W4.3 — témoin : un champ doing ajouté est refusé" "$R" "clé interdite présente : doing"
assert_eq "W4.4 — témoin : code de sortie non nul" "$RC" "1"

#--W5-W10--

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
