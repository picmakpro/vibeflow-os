#!/usr/bin/env bash
# test-gsd-cohabitation.sh — Cohabitation settings.json avec les hooks posés par
# l'installeur gsd-core (Phase 11-04). Complète test-merge-hooks.sh : ce fichier prouve
# spécifiquement les 2 correctifs préventifs (matching ancré + fin de la co-location de
# groupes mixtes) contre une fixture représentative d'un settings.json post-install
# gsd-core réel (plugin/_internal/tests/fixtures/gsd-core-settings.json).
#
# T1 — merge sans perte : tous les hooks gsd-* de la fixture survivent au merge VF ;
#      statusLine et permissions deep-equal à l'origine.
# T2 — remove restaurateur : après remove du fragment VF, deep-equal à la fixture d'origine.
# T3 — idempotence : double merge → aucun doublon.
# T4 — non-mixité post-correctif : un groupe déjà 100% GSD (PreToolUse/Read) n'est jamais
#      co-localisé avec un hook VF — un nouveau groupe distinct est créé à la place.
# T5 — anti-collision de suffixe : un hook VF `consolidator-archive.sh` ne doit jamais
#      capturer/détruire l'entrée tierce `gsd-archive.sh` de la fixture (preuve directe du
#      correctif de matching ancré).
#
# ISOLATION : tout sous mktemp. La fixture n'est jamais modifiée en place (copie de travail).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
MERGER="$INTERNAL_DIR/merge-hooks.sh"
FIXTURE="$TESTS_DIR/fixtures/gsd-core-settings.json"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-gsd-cohabitation (merger: $MERGER, fixture: $FIXTURE) =="

[ -f "$FIXTURE" ] || { echo "fixture introuvable : $FIXTURE" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PREFIX='"$CLAUDE_PROJECT_DIR"/.claude/scripts'

# Fragment VF T1-T4 : hooks bénins sur des matchers déjà présents dans la fixture
# (PreToolUse/Read en particulier, groupe 100% GSD — c'est le cas discriminant T4).
FRAG="$WORK/vf-frag.json"
cat > "$FRAG" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/guard-read-registres.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/consolidator-summary.sh" } ] }
    ]
  }
}
EOF

# Fragment VF T5 : hook portant un script qui PARTAGE LE SUFFIXE "archive.sh" avec l'entrée
# tierce `gsd-archive.sh` de la fixture (Stop). Sans matching ancré, `references()` matcherait
# `archive.sh` en sous-chaîne de `gsd-archive.sh` et la dédup cross-matcher/remove la détruirait.
FRAG_SUFFIX="$WORK/vf-frag-suffix.json"
cat > "$FRAG_SUFFIX" <<'EOF'
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/archive.sh --consolidator" } ] }
    ]
  }
}
EOF

fixture_gsd_pairs() {
  # Toutes les paires (event, command) dont la command contient "gsd-" dans un settings.json.
  python3 -c "
import json
d = json.load(open('$1'))
pairs = sorted((ev, h['command']) for ev, groups in d.get('hooks', {}).items() for g in groups for h in g.get('hooks', []) if 'gsd-' in h.get('command', ''))
for p in pairs:
    print(p)
"
}

# ---------- T1 : merge sans perte ----------
S1="$WORK/t1/settings.json"
mkdir -p "$WORK/t1"
cp "$FIXTURE" "$S1"
bash "$MERGER" merge "$FRAG" --settings "$S1" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json, sys
orig = json.load(open('$FIXTURE'))
merged = json.load(open('$S1'))
orig_pairs = set()
for ev, groups in orig.get('hooks', {}).items():
    for g in groups:
        for h in g.get('hooks', []):
            if 'gsd-' in h.get('command', ''):
                orig_pairs.add((ev, h['command']))
merged_pairs = set()
for ev, groups in merged.get('hooks', {}).items():
    for g in groups:
        for h in g.get('hooks', []):
            if 'gsd-' in h.get('command', ''):
                merged_pairs.add((ev, h['command']))
assert orig_pairs <= merged_pairs, f'hooks gsd-* perdus : {orig_pairs - merged_pairs}'
assert merged['statusLine'] == orig['statusLine'], 'statusLine altéré'
assert merged['permissions'] == orig['permissions'], 'permissions altérées'
assert any('guard-read-registres.sh' in h['command'] for g in merged['hooks']['PreToolUse'] for h in g['hooks']), 'hook VF absent'
" 2>&1; then
  ok "T1 merge sans perte (hooks gsd-* intacts, statusLine/permissions deep-equal)"
else
  ko "T1 merge sans perte"
fi

# ---------- T2 : remove restaurateur ----------
S2="$WORK/t2/settings.json"
mkdir -p "$WORK/t2"
cp "$FIXTURE" "$S2"
bash "$MERGER" merge "$FRAG" --settings "$S2" --scripts-prefix "$PREFIX" 2>/dev/null
bash "$MERGER" remove "$FRAG" --settings "$S2" 2>/dev/null
if python3 -c "
import json
orig = json.load(open('$FIXTURE'))
restored = json.load(open('$S2'))
assert restored == orig, 'settings post-remove différent de la fixture d\'origine'
" 2>&1; then
  ok "T2 remove restaurateur (deep-equal à la fixture d'origine)"
else
  ko "T2 remove restaurateur"
fi

# ---------- T3 : idempotence ----------
S3="$WORK/t3/settings.json"
mkdir -p "$WORK/t3"
cp "$FIXTURE" "$S3"
bash "$MERGER" merge "$FRAG" --settings "$S3" --scripts-prefix "$PREFIX" 2>/dev/null
FIRST="$WORK/t3/after-first.json"
cp "$S3" "$FIRST"
bash "$MERGER" merge "$FRAG" --settings "$S3" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
first = json.load(open('$FIRST'))
second = json.load(open('$S3'))
assert first == second, 'second merge != first merge (doublon)'
" 2>&1; then
  ok "T3 idempotence (double merge → résultat identique, aucun doublon)"
else
  ko "T3 idempotence"
fi

# ---------- T4 : non-mixité post-correctif ----------
S4="$WORK/t4/settings.json"
mkdir -p "$WORK/t4"
cp "$FIXTURE" "$S4"
bash "$MERGER" merge "$FRAG" --settings "$S4" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
orig = json.load(open('$FIXTURE'))
merged = json.load(open('$S4'))
orig_read_group = next(g for g in orig['hooks']['PreToolUse'] if g.get('matcher') == 'Read')
read_groups = [g for g in merged['hooks']['PreToolUse'] if g.get('matcher') == 'Read']
assert len(read_groups) == 2, f'attendu 2 groupes PreToolUse/Read distincts (GSD intact + nouveau VF), trouvé {len(read_groups)}'
gsd_group = next((g for g in read_groups if g['hooks'] == orig_read_group['hooks']), None)
assert gsd_group is not None, 'le groupe GSD Read d\'origine a été altéré (co-location détectée)'
vf_group = next((g for g in read_groups if g is not gsd_group), None)
assert vf_group is not None and any('guard-read-registres.sh' in h['command'] for h in vf_group['hooks']), 'nouveau groupe VF Read introuvable'
assert not any('guard-read-registres.sh' in h['command'] for h in gsd_group['hooks']), 'hook VF mélangé dans le groupe GSD'
" 2>&1; then
  ok "T4 non-mixité (groupe GSD PreToolUse/Read intact + nouveau groupe VF distinct)"
else
  ko "T4 non-mixité post-correctif"
fi

# ---------- T5 : anti-collision de suffixe ----------
S5="$WORK/t5/settings.json"
mkdir -p "$WORK/t5"
cp "$FIXTURE" "$S5"
bash "$MERGER" merge "$FRAG_SUFFIX" --settings "$S5" --scripts-prefix "$PREFIX" 2>/dev/null
AFTER_MERGE_OK=0
if python3 -c "
import json
d = json.load(open('$S5'))
cmds = [h['command'] for g in d['hooks']['Stop'] for h in g['hooks']]
assert any('gsd-archive.sh' in c for c in cmds), 'gsd-archive.sh détruit au merge (collision de suffixe)'
" 2>&1; then
  AFTER_MERGE_OK=1
fi
bash "$MERGER" remove "$FRAG_SUFFIX" --settings "$S5" 2>/dev/null
if [ "$AFTER_MERGE_OK" = "1" ] && python3 -c "
import json
d = json.load(open('$S5'))
cmds = [h['command'] for g in d['hooks']['Stop'] for h in g['hooks']]
assert any('gsd-archive.sh' in c for c in cmds), 'gsd-archive.sh détruit au remove (collision de suffixe)'
assert not any(c.strip().endswith('archive.sh --consolidator') for c in cmds), 'fragment VF suffixe non retiré'
" 2>&1; then
  ok "T5 anti-collision de suffixe (gsd-archive.sh survit au merge ET au remove d'un fragment archive.sh)"
else
  ko "T5 anti-collision de suffixe"
fi

echo ""
echo "== résultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
