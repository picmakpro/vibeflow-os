#!/usr/bin/env bash
# test-merge-hooks.sh — Suite du câblage hooks ADR-043 (merge-hooks.sh + intégration engine).
#
# T1 — merge dans settings absent → créé, placeholder {{VF_SCRIPTS}} résolu
# T2 — merge avec settings préexistant → hooks tiers ET clés étrangères préservés
# T3 — idempotence : double merge → aucun doublon
# T4 — remove → entrées du module retirées, tiers conservés, groupes vides nettoyés
# T5 — intégration engine : install consolidator → hooks présents ; uninstall → retirés
# T6 — settings corrompu → merge échoue proprement (exit ≠ 0), fichier non écrasé
#
# ISOLATION : tout sous mktemp. Le vrai ~/.claude n'est jamais touché.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
MERGER="$INTERNAL_DIR/merge-hooks.sh"
ENGINE="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-merge-hooks (merger: $MERGER) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FRAG="$WORK/frag.json"
cat > "$FRAG" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/guard-read-registres.sh" } ] }
    ],
    "SessionEnd": [
      { "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/archive.sh --async --apply || true" } ] }
    ]
  }
}
EOF
PREFIX='"$CLAUDE_PROJECT_DIR"/.claude/scripts'

# ---------- T1 : merge dans settings absent ----------
S1="$WORK/t1/settings.json"
if bash "$MERGER" merge "$FRAG" --settings "$S1" --scripts-prefix "$PREFIX" 2>/dev/null \
   && python3 -c "import json,sys; d=json.load(open('$S1')); cmds=[h['command'] for g in d['hooks']['PreToolUse'] for h in g['hooks']]; sys.exit(0 if any('guard-read-registres.sh' in c and '\$CLAUDE_PROJECT_DIR' in c for c in cmds) else 1)"; then
  ok "T1 merge crée settings.json avec placeholder résolu"
else
  ko "T1 merge dans settings absent"
fi

# ---------- T2 : settings préexistant préservé ----------
S2="$WORK/t2/settings.json"
mkdir -p "$WORK/t2"
cat > "$S2" <<'EOF'
{
  "permissions": { "allow": ["Bash(npm test:*)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read", "hooks": [ { "type": "command", "command": "echo tiers-read" } ] },
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo tiers-bash" } ] }
    ]
  }
}
EOF
bash "$MERGER" merge "$FRAG" --settings "$S2" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json, sys
d = json.load(open('$S2'))
assert d['permissions']['allow'] == ['Bash(npm test:*)'], 'permissions perdues'
all_cmds = [h['command'] for ev in d['hooks'].values() for g in ev for h in g['hooks']]
assert any('tiers-read' in c for c in all_cmds), 'hook tiers Read perdu'
assert any('tiers-bash' in c for c in all_cmds), 'hook tiers Bash perdu'
assert any('guard-read-registres.sh' in c for c in all_cmds), 'hook module absent'
read_groups = [g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'Read']
assert len(read_groups) == 1, 'groupe Read dupliqué au lieu de fusionné'
" 2>/dev/null; then
  ok "T2 hooks tiers + clés étrangères préservés, groupe Read fusionné"
else
  ko "T2 préservation du settings préexistant"
fi

# ---------- T3 : idempotence ----------
bash "$MERGER" merge "$FRAG" --settings "$S2" --scripts-prefix "$PREFIX" 2>/dev/null
COUNT="$(python3 -c "
import json
d = json.load(open('$S2'))
cmds = [h['command'] for ev in d['hooks'].values() for g in ev for h in g['hooks']]
print(sum(1 for c in cmds if 'guard-read-registres.sh' in c))
")"
if [ "$COUNT" = "1" ]; then
  ok "T3 double merge = 1 seule entrée guard (idempotent)"
else
  ko "T3 idempotence (guard présent ${COUNT}x)"
fi

# ---------- T4 : remove chirurgical ----------
bash "$MERGER" remove "$FRAG" --settings "$S2" 2>/dev/null
if python3 -c "
import json, sys
d = json.load(open('$S2'))
all_cmds = [h['command'] for ev in d.get('hooks', {}).values() for g in ev for h in g['hooks']]
assert not any('guard-read-registres.sh' in c for c in all_cmds), 'hook module non retiré'
assert not any('archive.sh' in c for c in all_cmds), 'hook SessionEnd non retiré'
assert any('tiers-read' in c for c in all_cmds), 'hook tiers Read perdu au remove'
assert 'SessionEnd' not in d.get('hooks', {}), 'événement vide non nettoyé'
assert d['permissions']['allow'] == ['Bash(npm test:*)'], 'permissions perdues au remove'
" 2>/dev/null; then
  ok "T4 remove retire le module, préserve les tiers, nettoie les événements vides"
else
  ko "T4 remove chirurgical"
fi

# ---------- T5 : intégration engine (install/uninstall consolidator) ----------
LAB="$WORK/t5-lab"
CACHE="$WORK/t5-cache"
mkdir -p "$LAB" "$CACHE/_internal"
cp -r "$REPO/consolidator" "$CACHE/consolidator"
cp "$MERGER" "$CACHE/_internal/merge-hooks.sh"
if (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" VF_SCOPE=project bash "$ENGINE" install consolidator >/dev/null 2>&1) \
   && python3 -c "
import json, sys
d = json.load(open('$LAB/.claude/settings.json'))
cmds = [h['command'] for ev in d['hooks'].values() for g in ev for h in g['hooks']]
assert any('guard-read-registres.sh' in c for c in cmds)
assert any('post-edit-reindex.sh' in c for c in cmds)
assert any('check-registres.sh' in c for c in cmds)
assert any('archive.sh' in c for c in cmds)
" 2>/dev/null; then
  ok "T5a install consolidator → 4 hooks de gouvernance câblés dans settings.json"
else
  ko "T5a install → hooks câblés"
fi
if (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" VF_SCOPE=project bash "$ENGINE" uninstall consolidator >/dev/null 2>&1) \
   && python3 -c "
import json, sys
d = json.load(open('$LAB/.claude/settings.json'))
cmds = [h['command'] for ev in d.get('hooks', {}).values() for g in ev for h in g['hooks']]
assert not any('guard-read-registres.sh' in c for c in cmds)
" 2>/dev/null; then
  ok "T5b uninstall consolidator → hooks retirés"
else
  ko "T5b uninstall → hooks retirés"
fi

# ---------- T6 : settings corrompu → échec propre ----------
S6="$WORK/t6/settings.json"
mkdir -p "$WORK/t6"
echo '{ json cassé' > "$S6"
if bash "$MERGER" merge "$FRAG" --settings "$S6" --scripts-prefix "$PREFIX" 2>/dev/null; then
  ko "T6 merge sur settings corrompu aurait dû échouer"
else
  if grep -q 'json cassé' "$S6"; then
    ok "T6 settings corrompu → exit ≠ 0 et fichier non écrasé"
  else
    ko "T6 fichier corrompu écrasé malgré l'échec"
  fi
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
