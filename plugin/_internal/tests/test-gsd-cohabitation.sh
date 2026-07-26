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
# T6 — durcissement de la frontière de `references()` (harden-11-04) : les métacaractères
#      shell collés à un nom de script (`;`, `)`, `|`, `&`, fin de chaîne) sont bien reconnus
#      comme une frontière valide, ET le contre-exemple `gsd-archive.sh` face au motif
#      `archive.sh` reste négatif même avec un métacaractère collé — preuve que l'élargissement
#      n'a pas réintroduit un comportement de sous-chaîne. Complète par un cas de bout en bout
#      sur la possession de groupe : un groupe dont l'unique hook VF a une command terminée par
#      `;` doit être reconnu comme possédé par VF et réutilisé (pas dupliqué).
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

# ---------- T6 : durcissement de la frontière de references() (harden-11-04) ----------

# T6a/T6b — bout en bout via `remove` : un unique basename "archive.sh", des commandes
# positives (métacaractère collé) qui DOIVENT être retirées, et des commandes
# "gsd-archive.sh" (préfixées) qui ne doivent JAMAIS l'être — même avec un métacaractère collé.
S6="$WORK/t6/settings.json"
mkdir -p "$WORK/t6"
cat > "$S6" <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash /x/archive.sh; echo ok" },
          { "type": "command", "command": "(bash /x/archive.sh)" },
          { "type": "command", "command": "bash /x/archive.sh|tee log" },
          { "type": "command", "command": "bash /x/archive.sh&&echo ok" },
          { "type": "command", "command": "bash /x/archive.sh" },
          { "type": "command", "command": "bash /x/gsd-archive.sh; echo ok" },
          { "type": "command", "command": "bash /x/gsd-archive.sh" }
        ]
      }
    ]
  }
}
EOF
FRAG_ARCHIVE="$WORK/vf-frag-archive.json"
cat > "$FRAG_ARCHIVE" <<'EOF'
{ "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/archive.sh" } ] } ] } }
EOF
bash "$MERGER" remove "$FRAG_ARCHIVE" --settings "$S6" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S6'))
cmds = [h['command'] for g in d['hooks']['Stop'] for h in g['hooks']]
# positifs : doivent avoir disparu (frontière élargie reconnaît le métacaractère collé)
for suffix in [';', ')', '|', '&', '']:
    assert not any(c.startswith('bash /x/archive.sh' + suffix) or c == '(bash /x/archive.sh)' for c in cmds if 'gsd-' not in c), f'archive.sh (suffixe {suffix!r}) non retiré'
assert len(cmds) == 2, f'attendu 2 survivants (gsd-archive.sh x2), trouvé {len(cmds)} : {cmds}'
# contre-exemple : gsd-archive.sh doit survivre, y compris avec métacaractère collé
assert any(c == 'bash /x/gsd-archive.sh; echo ok' for c in cmds), 'contre-exemple gsd-archive.sh; détruit (retour à un matching de sous-chaîne)'
assert any(c == 'bash /x/gsd-archive.sh' for c in cmds), 'contre-exemple gsd-archive.sh (baseline) détruit'
" 2>&1; then
  ok "T6a/T6b frontière élargie : métacaractères reconnus (;)|&& et fin de chaîne, gsd-archive.sh jamais capturé"
else
  ko "T6a/T6b frontière élargie de references()"
fi

# T6c — bout en bout sur la possession de groupe : un groupe dont l'unique hook VF a une
# command terminée par ";" doit être reconnu comme possédé par VF → réutilisé (1 seul
# groupe pour le matcher après merge), pas dupliqué. Avec l'ancienne regex, la frontière
# droite refusait ";" → le groupe était jugé "non entièrement possédé" → un second groupe
# aurait été créé (prolifération, cf. mandat harden-11-04).
S6C="$WORK/t6c/settings.json"
mkdir -p "$WORK/t6c"
cat > "$S6C" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "T6Group", "hooks": [ { "type": "command", "command": "bash /x/archive.sh;" } ] } ] } }
EOF
FRAG_GROUP="$WORK/vf-frag-group.json"
cat > "$FRAG_GROUP" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "T6Group", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/archive.sh" } ] } ] } }
EOF
bash "$MERGER" merge "$FRAG_GROUP" --settings "$S6C" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S6C'))
groups = [g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'T6Group']
assert len(groups) == 1, f'attendu 1 seul groupe T6Group (réutilisé), trouvé {len(groups)} — prolifération de groupes'
assert len(groups[0]['hooks']) == 1, f'attendu 1 hook dédupliqué dans le groupe réutilisé, trouvé {len(groups[0][\"hooks\"])}'
" 2>&1; then
  ok "T6c possession de groupe : hook \"archive.sh;\" reconnu → groupe réutilisé, pas dupliqué"
else
  ko "T6c possession de groupe (prolifération)"
fi

# T6d — preuve de discrimination directe (ancienne regex vs nouvelle) sur chaque cas positif :
# rouge avant le correctif, vert après. Documente pourquoi T6a-c échoueraient sans le durcissement.
if python3 -c "
import re
OLD = lambda b: r\"(?:^|[\s'\\\"/])\" + re.escape(b) + r\"(?:\$|[\s'\\\"])\"
NEW = lambda b: r'(?<![A-Za-z0-9._-])' + re.escape(b) + r'(?![A-Za-z0-9._-])'
positifs = [
    'bash /x/archive.sh; echo ok',
    '(bash /x/archive.sh)',
    'bash /x/archive.sh|tee log',
    'bash /x/archive.sh&&echo ok',
]
contre_exemples = ['bash /x/gsd-archive.sh; echo ok', 'bash /x/gsd-archive.sh']
for cmd in positifs:
    old_ok = bool(re.search(OLD('archive.sh'), cmd))
    new_ok = bool(re.search(NEW('archive.sh'), cmd))
    assert old_ok is False, f'ancienne regex matchait déjà {cmd!r} — cas non discriminant'
    assert new_ok is True, f'nouvelle regex ne matche pas {cmd!r}'
for cmd in contre_exemples:
    assert not re.search(OLD('archive.sh'), cmd), f'contre-exemple {cmd!r} matché par ancienne regex (déjà cassé)'
    assert not re.search(NEW('archive.sh'), cmd), f'contre-exemple {cmd!r} matché par nouvelle regex (régression sous-chaîne)'
" 2>&1; then
  ok "T6d preuve de discrimination (rouge avant / vert après, contre-exemples stables)"
else
  ko "T6d preuve de discrimination"
fi

echo ""
echo "== résultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
