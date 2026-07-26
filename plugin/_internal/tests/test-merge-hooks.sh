#!/usr/bin/env bash
# test-merge-hooks.sh — Suite du câblage hooks ADR-043 (merge-hooks.sh + intégration engine).
#
# T1 — merge dans settings absent → créé, placeholder {{VF_SCRIPTS}} résolu
# T2 — merge avec settings préexistant → hooks tiers isolés dans un groupe propre distinct,
#      jamais co-localisés avec les hooks VF (contrat arbitré en Phase 11-04 : VF ne fusionne
#      plus jamais dans un groupe qu'il ne possède pas intégralement — protection contre les
#      outils tiers qui réécrivent/suppriment des GROUPES entiers, cas prouvé : le
#      cleanupOrphanedHooks de gsd-core et sa migration de scope). Anti-prolifération vérifiée :
#      un second merge n'ajoute pas de 3e groupe Read.
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

# ---------- T2 : settings préexistant préservé, hooks tiers isolés en groupe propre ----------
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
READ_GROUPS_AFTER_1="$(python3 -c "
import json
d = json.load(open('$S2'))
print(len([g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'Read']))
")"
# Second merge — vérifie l'anti-prolifération : aucun 3e groupe Read ne doit apparaître.
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
tiers_group = next((g for g in read_groups if any('tiers-read' in h['command'] for h in g['hooks'])), None)
own_group = next((g for g in read_groups if any('guard-read-registres.sh' in h['command'] for h in g['hooks'])), None)
assert tiers_group is not None, 'groupe tiers Read introuvable'
assert own_group is not None, 'groupe VF Read introuvable'
assert tiers_group is not own_group, 'VF a fusionné dans le groupe tiers au lieu de créer le sien'
assert all('guard-read-registres.sh' not in h['command'] for h in tiers_group['hooks']), 'groupe tiers pollué par un hook VF'
assert all('tiers-read' not in h['command'] for h in own_group['hooks']), 'groupe VF pollué par le hook tiers'
assert len(read_groups) == $READ_GROUPS_AFTER_1, f'prolifération de groupes Read au 2e merge : {len(read_groups)} vs $READ_GROUPS_AFTER_1'
" 2>/dev/null; then
  ok "T2 hooks tiers isolés en groupe propre distinct, aucune prolifération au 2e merge"
else
  ko "T2 isolation groupe tiers / anti-prolifération"
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

# ---------- T7 : changement de matcher entre versions du fragment → pas de doublon ----------
S7="$WORK/t7/settings.json"
mkdir -p "$WORK/t7"
FRAG_V1="$WORK/frag-v1.json"
FRAG_V2="$WORK/frag-v2.json"
cat > "$FRAG_V1" <<'EOF'
{ "hooks": { "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/post-edit-reindex.sh" } ] } ] } }
EOF
cat > "$FRAG_V2" <<'EOF'
{ "hooks": { "PostToolUse": [ { "matcher": "Edit|Write|Bash", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/post-edit-reindex.sh" } ] } ] } }
EOF
bash "$MERGER" merge "$FRAG_V1" --settings "$S7" --scripts-prefix "$PREFIX" 2>/dev/null
bash "$MERGER" merge "$FRAG_V2" --settings "$S7" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json, sys
d = json.load(open('$S7'))
groups = d['hooks']['PostToolUse']
cmds = [h['command'] for g in groups for h in g['hooks']]
assert sum(1 for c in cmds if 'post-edit-reindex.sh' in c) == 1, f'doublon cross-matcher : {cmds}'
assert [g['matcher'] for g in groups] == ['Edit|Write|Bash'], f'ancien groupe non purgé : {groups}'
" 2>/dev/null; then
  ok "T7 upgrade de matcher (Edit|Write → Edit|Write|Bash) → 1 seule entrée, ancien groupe purgé"
else
  ko "T7 dédup cross-matcher à l'upgrade"
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
