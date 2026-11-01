#!/usr/bin/env bash
# test-cockpit-onglet-code.sh — onglet Code conditionnel, sans modèle (CKPT-06, volet Code ; P67-D-17).
#   C1 lab à modules : extracteur VibeFlow (dispatch, source, plus de liens que le même lab en brut)
#   C2 lab neutre : architecture brute · C3 aucun assemblage n'appelle `claude` (faux binaire consignant tout appel)
# Labs jetables dans mktemp, isolation git, HOME jetable. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; mkdir -p "$WORK/aux" "$WORK/home" "$WORK/fake"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"
trap '[ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_gt() { if [ "${2:-0}" -gt "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 > $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 ≤ $3)"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/donnees.mjs" <<'JS'
// donnees.mjs <sortie> <page> <expression sur j> : lit la zone de données par vf-cockpit-embed.mjs
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extraireGraphe } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-embed.mjs')).href);
const j = extraireGraphe(fs.readFileSync(process.argv[3], 'utf8'));
const v = new Function('j', 'return (' + process.argv[4] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# faux claude : consigne tout appel
NODE="$(command -v node)"; printf '#!%s\nrequire("fs").appendFileSync(process.env.VF_FAKE_LOG, process.argv.slice(2).join(" ") + "\\n");\n' "$NODE" > "$WORK/fake/claude"; chmod +x "$WORK/fake/claude"
export VF_FAKE_LOG="$WORK/appels.log"

mklab() { # mklab <dossier> modules|neutre
  local L="$1"; mkdir -p "$L/.planning/phases/01-x" "$L/src"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  if [ "$2" = modules ]; then
    mkdir -p "$L/plugin/a/agents" "$L/plugin/a/scripts" "$L/plugin/a/skills/k" "$L/plugin/b/agents"
    printf '{"name":"a","version":"1.0.0","type":"agent + skills + scripts","description":"Module A de test."}\n' > "$L/plugin/a/module.json"
    printf '{"name":"b","version":"1.0.0","type":"doc-only","description":"Module B de test."}\n' > "$L/plugin/b/module.json"
    printf -- '---\nname: x\ndescription: agent x\ntools: Read, Agent(y)\n---\nCorps de x.\n' > "$L/plugin/a/agents/x.md"
    printf -- '---\nname: y\ndescription: agent y\ntools: Read\n---\nCorps de y.\n' > "$L/plugin/b/agents/y.md"
    printf '#!/usr/bin/env bash\nsource ./s2.sh\necho s1\n' > "$L/plugin/a/scripts/s1.sh"
    printf '#!/usr/bin/env bash\necho s2\n' > "$L/plugin/a/scripts/s2.sh"
    printf -- '---\nname: k\ndescription: skill k\n---\nLancer `s1.sh` pour la preuve.\n' > "$L/plugin/a/skills/k/SKILL.md"
  fi
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
assembler() { PATH="$WORK/fake:$PATH" node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1; echo $?; }
donnee() { node "$AUX/donnees.mjs" "$1/.vibeflow/cockpit" "$1/.vibeflow/cockpit/index.html" "$2"; }

echo "=== C1 — lab à modules : extracteur VibeFlow ==="
LM="$WORK/modules"; mklab "$LM" modules
assert_eq "C1.1 — l'assemblage rend 0" "$(assembler "$LM")" "0"
assert_eq "C1.2 — meta.vfCodeExtractor = vibeflow" "$(donnee "$LM" 'j.meta.vfCodeExtractor')" "vibeflow"
assert_eq "C1.3 — un lien call de x vers y (dispatch Agent)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="call"&&l.a==="f:plugin/a/agents/x.md"&&l.b==="f:plugin/b/agents/y.md").length')" "1"
assert_eq "C1.4 — un lien import de s1 vers s2 (source)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="import"&&l.a==="f:plugin/a/scripts/s1.sh"&&l.b==="f:plugin/a/scripts/s2.sh").length')" "1"
assert_eq "C1.5 — un lien call du skill vers s1 (mention de script)" "$(donnee "$LM" 'j.links.filter(l=>l.k==="call"&&l.a==="f:plugin/a/skills/k/SKILL.md"&&l.b==="f:plugin/a/scripts/s1.sh").length')" "1"
assert_eq "C1.6 — la nature d'un module est lue dans son module.json (a : agents, b : doc-only)" "$(donnee "$LM" 'j.nodes.filter(n=>n.id==="m-a"||n.id==="m-b").map(n=>n.kind).join(",")')" "service,config"
NV=$(donnee "$LM" 'j.links.length')
# témoin : le même lab dont les module.json sont renommés -> architecture brute
LB="$WORK/brut"; mklab "$LB" modules; for m in a b; do git -C "$LB" mv "plugin/$m/module.json" "plugin/$m/module.json.off"; done; git -C "$LB" -c user.email=t@t -c user.name=t commit -q -m off
assert_eq "C1.7 — témoin : sans module.json le même lab est assemblé en brut" "$(assembler "$LB")$(donnee "$LB" 'j.meta.vfCodeExtractor')" "0brut"
assert_gt "C1.8 — l'extracteur VibeFlow produit strictement plus de liens que le brut sur le même lab" "$NV" "$(donnee "$LB" 'j.links.length')"

echo "=== C2 — lab neutre : architecture brute ==="
LN="$WORK/neutre"; mklab "$LN" neutre
assert_eq "C2.1 — l'assemblage rend 0" "$(assembler "$LN")" "0"
assert_eq "C2.2 — meta.vfCodeExtractor = brut" "$(donnee "$LN" 'j.meta.vfCodeExtractor')" "brut"

echo "=== C3 — aucun appel à claude pendant l'assemblage ==="
assert_eq "C3.1 — le faux claude n'a été appelé par aucun assemblage (C1, C2 et le témoin)" "$([ -s "$VF_FAKE_LOG" ] && wc -l < "$VF_FAKE_LOG" | tr -d ' ' || echo 0)" "0"
PATH="$WORK/fake:$PATH" claude --version
assert_eq "C3.2 — témoin : le même faux binaire appelé directement consigne bien un appel" "$([ -s "$VF_FAKE_LOG" ] && wc -l < "$VF_FAKE_LOG" | tr -d ' ' || echo 0)" "1"

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
