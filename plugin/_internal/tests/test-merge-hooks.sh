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
# T7 — changement de matcher entre versions du fragment → pas de doublon
#
# Forme exec (contrat PR #29 §5, D-01, plan 30-01) :
# T8  — substitution du jeton {{VF_SCRIPTS}} dans args, aucune accolade double résiduelle
# T9  — dédup cross-forme, sens shell → exec (le patron T7, transposé au changement de forme)
# T10 — dédup cross-forme, sens exec → shell (réciproque — compat descendante, rollback)
# T11 — remove d'un fragment 100% exec (preuve directe que frag_basenames() lit args)
# T12 — idempotence sur trois passes (forme exec)
# T13 — sonde de parc (spec §4) : settings réaliste, merge exec puis remove, zéro résidu VF,
#       entrées tierce/gsd-core intactes octet pour octet
# T14 — frontière de mot préservée sur args (régression lookaround, transposée depuis command)
#
# Routage borné --settings-local (contrat manque 1, correction exec-30-01) :
# T15 — entrée {{VF_BASH}} + --settings-local fournie → atterrit dans le fichier local, absente
#       du fichier projet (aucune clé hooks n'y apparaît pour cette entrée)
# T16 — entrée SANS {{VF_BASH}} (forme shell) + --settings-local fournie → reste dans le fichier
#       projet, fichier local non affecté par cette entrée
# T17 — --settings-local ABSENTE → comportement identique à avant (entrée {{VF_BASH}} atterrit
#       dans la cible --settings unique, preuve de compat descendante)
# T18 — remove avec --settings-local fournie sur un merge antérieur mixte (entrée locale + entrée
#       projet) → les deux disparaissent des deux fichiers respectivement, aucun résidu
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
BASH_ABS_TEST="$(command -v bash)"

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

# ---------- T8 : substitution du jeton {{VF_SCRIPTS}} dans args (forme exec) ----------
FRAG_EXEC="$WORK/frag-exec.json"
cat > "$FRAG_EXEC" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/exec-guard.sh", "--hook"] } ] } ] } }
EOF
S8="$WORK/t8/settings.json"
if VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC" --settings "$S8" --scripts-prefix "$PREFIX" 2>/dev/null \
   && python3 -c "
import json
d = json.load(open('$S8'))
h = d['hooks']['PreToolUse'][0]['hooks'][0]
assert h['command'] == '$BASH_ABS_TEST', h['command']
assert h['args'][0] == '$PREFIX/exec-guard.sh', h['args']
assert h['args'][1] == '--hook', h['args']
raw = open('$S8').read()
assert '{{' not in raw, 'accolade double residuelle : ' + raw
" 2>/dev/null; then
  ok "T8 substitution {{VF_SCRIPTS}} dans args (forme exec), aucune accolade double résiduelle"
else
  ko "T8 substitution dans args"
fi

# ---------- T9/T10 : dédup cross-forme (fragments partagés shell ↔ exec) ----------
FRAG_SHELL_DEDUP="$WORK/frag-shell-dedup.json"
cat > "$FRAG_SHELL_DEDUP" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/dedup-guard.sh || true" } ] } ] } }
EOF
FRAG_EXEC_DEDUP="$WORK/frag-exec-dedup.json"
cat > "$FRAG_EXEC_DEDUP" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/dedup-guard.sh"] } ] } ] } }
EOF

# ---------- T9 : dédup cross-forme, sens shell → exec ----------
S9="$WORK/t9/settings.json"
bash "$MERGER" merge "$FRAG_SHELL_DEDUP" --settings "$S9" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S9" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S9'))
entries = [h for g in d['hooks']['PreToolUse'] for h in g['hooks']]
matches = [h for h in entries if 'dedup-guard.sh' in h.get('command','') or any('dedup-guard.sh' in a for a in h.get('args',[]) if isinstance(a,str))]
assert len(matches) == 1, f'attendu 1 entree, trouve {len(matches)} : {matches}'
assert 'args' in matches[0], f'entree residuelle en forme shell, pas exec : {matches[0]}'
" 2>/dev/null; then
  ok "T9 dédup cross-forme shell→exec : 1 seule entrée, forme exec, ancienne entrée shell purgée"
else
  ko "T9 dédup cross-forme shell→exec"
fi

# ---------- T10 : dédup cross-forme, sens exec → shell (réciproque, rollback) ----------
S10="$WORK/t10/settings.json"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S10" --scripts-prefix "$PREFIX" 2>/dev/null
bash "$MERGER" merge "$FRAG_SHELL_DEDUP" --settings "$S10" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S10'))
entries = [h for g in d['hooks']['PreToolUse'] for h in g['hooks']]
matches = [h for h in entries if 'dedup-guard.sh' in h.get('command','') or any('dedup-guard.sh' in a for a in h.get('args',[]) if isinstance(a,str))]
assert len(matches) == 1, f'attendu 1 entree, trouve {len(matches)} : {matches}'
assert 'args' not in matches[0], f'entree residuelle en forme exec, pas shell : {matches[0]}'
" 2>/dev/null; then
  ok "T10 dédup cross-forme exec→shell : 1 seule entrée, forme shell, ancienne entrée exec purgée"
else
  ko "T10 dédup cross-forme exec→shell (rollback de fragment)"
fi

# ---------- T11 : remove d'un fragment 100% exec ----------
S11="$WORK/t11/settings.json"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S11" --scripts-prefix "$PREFIX" 2>/dev/null
if bash "$MERGER" remove "$FRAG_EXEC_DEDUP" --settings "$S11" 2>/dev/null \
   && python3 -c "
import json
d = json.load(open('$S11'))
all_cmds_args = []
for ev in d.get('hooks', {}).values():
    for g in ev:
        for h in g['hooks']:
            all_cmds_args.append(h.get('command',''))
            all_cmds_args.extend(a for a in h.get('args', []) if isinstance(a, str))
assert not any('dedup-guard.sh' in c for c in all_cmds_args), 'entree exec non retiree'
" 2>/dev/null; then
  ok "T11 remove d'un fragment 100% exec — frag_basenames() lit args, désinstallation possible"
else
  ko "T11 remove d'un fragment 100% exec"
fi

# ---------- T12 : idempotence sur trois passes (forme exec) ----------
S12="$WORK/t12/settings.json"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S12" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S12" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_EXEC_DEDUP" --settings "$S12" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S12'))
groups = [g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'Bash']
entries = [h for g in groups for h in g['hooks'] if 'dedup-guard.sh' in ' '.join(a for a in h.get('args', []) if isinstance(a, str))]
assert len(groups) == 1, f'plusieurs groupes Bash : {groups}'
assert len(entries) == 1, f'plusieurs entrees exec : {entries}'
" 2>/dev/null; then
  ok "T12 trois merges du même fragment exec → 1 seule entrée, 1 seul groupe"
else
  ko "T12 idempotence 3 passes (forme exec)"
fi

# ---------- T13 : sonde de parc (spec §4) — settings réaliste, merge exec puis remove ----------
S13="$WORK/t13/settings.json"
mkdir -p "$WORK/t13"
cat > "$S13" <<'EOF'
{
  "permissions": { "allow": ["Bash(npm test:*)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read", "hooks": [ { "type": "command", "command": "bash /lab/.claude/scripts/sonde-script-a.sh" } ] },
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo tiers-sonde" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "bash /lab/.claude/scripts/sonde-script-b.sh || true" } ] },
      { "hooks": [ { "type": "command", "command": "node /lab/.claude/gsd-core/hooks/gsd-context-warning.js" } ] }
    ]
  }
}
EOF
FRAG_T13="$WORK/frag-t13.json"
cat > "$FRAG_T13" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Read", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/sonde-script-a.sh"] } ] } ], "PostToolUse": [ { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/sonde-script-b.sh"] } ] } ] } }
EOF
TIERS_BEFORE="$WORK/t13-tiers-before.json"
GSD_BEFORE="$WORK/t13-gsd-before.json"
python3 -c "
import json
d = json.load(open('$S13'))
g = next(g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'Bash')
json.dump(g, open('$TIERS_BEFORE','w'), sort_keys=True)
"
python3 -c "
import json
d = json.load(open('$S13'))
g = next(g for g in d['hooks']['PostToolUse'] if 'matcher' not in g)
json.dump(g, open('$GSD_BEFORE','w'), sort_keys=True)
"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_T13" --settings "$S13" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" remove "$FRAG_T13" --settings "$S13" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S13'))
all_cmds_args = []
for ev in d.get('hooks', {}).values():
    for g in ev:
        for h in g['hooks']:
            all_cmds_args.append(h.get('command',''))
            all_cmds_args.extend(a for a in h.get('args', []) if isinstance(a, str))
assert not any('sonde-script-a.sh' in c for c in all_cmds_args), 'entree VF a residuelle'
assert not any('sonde-script-b.sh' in c for c in all_cmds_args), 'entree VF b residuelle'
tiers_after = next(g for g in d['hooks']['PreToolUse'] if g.get('matcher') == 'Bash')
tiers_before = json.load(open('$TIERS_BEFORE'))
assert tiers_after == tiers_before, f'entree tierce alteree : {tiers_after}'
gsd_after = next(g for g in d['hooks']['PostToolUse'] if 'matcher' not in g)
gsd_before = json.load(open('$GSD_BEFORE'))
assert gsd_after == gsd_before, f'entree gsd-core alteree : {gsd_after}'
assert d['permissions']['allow'] == ['Bash(npm test:*)'], 'permissions perdues'
" 2>/dev/null; then
  ok "T13 sonde de parc : zéro entrée VF résiduelle, entrées tierce/gsd-core intactes octet pour octet"
else
  ko "T13 sonde de parc"
fi

# ---------- T14 : frontière de mot préservée sur args (régression lookaround, transposée) ----------
S14="$WORK/t14/settings.json"
mkdir -p "$WORK/t14"
cat > "$S14" <<'EOF'
{ "hooks": { "SessionEnd": [ { "hooks": [ { "type": "command", "command": "/bin/bash", "args": ["/lab/.claude/scripts/gsd-archive.sh", "--async"] } ] } ] } }
EOF
FRAG_ARCHIVE="$WORK/frag-archive.json"
cat > "$FRAG_ARCHIVE" <<'EOF'
{ "hooks": { "SessionEnd": [ { "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/archive.sh --async --apply || true" } ] } ] } }
EOF
if bash "$MERGER" remove "$FRAG_ARCHIVE" --settings "$S14" 2>/dev/null \
   && python3 -c "
import json
d = json.load(open('$S14'))
args = d['hooks']['SessionEnd'][0]['hooks'][0]['args']
assert any('gsd-archive.sh' in a for a in args), f'gsd-archive.sh purgé à tort par archive.sh : {args}'
" 2>/dev/null; then
  ok "T14 frontière de mot sur args : gsd-archive.sh (exec) non purgé par un fragment archive.sh"
else
  ko "T14 frontière de mot sur args (régression lookaround transposée)"
fi

# ---------- T15/T16/T17 : routage borné --settings-local ----------
# Fragment mixte : une entrée exec {{VF_BASH}} (candidate au routage local) + une entrée shell
# classique (jamais routée, quelle que soit la présence de --settings-local).
FRAG_MIXED="$WORK/frag-mixed.json"
cat > "$FRAG_MIXED" <<'EOF'
{ "hooks": { "PreToolUse": [
  { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/local-guard.sh"] } ] },
  { "matcher": "Read", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/shell-guard.sh" } ] }
] } }
EOF

# ---------- T15 : entrée {{VF_BASH}} + --settings-local fournie → atterrit dans le fichier local ----------
S15_PROJECT="$WORK/t15/settings.json"
S15_LOCAL="$WORK/t15/settings-local.json"
mkdir -p "$WORK/t15"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_MIXED" --settings "$S15_PROJECT" --settings-local "$S15_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
if [ -f "$S15_LOCAL" ] && python3 -c "
import json
d = json.load(open('$S15_LOCAL'))
entries = [h for g in d['hooks']['PreToolUse'] for h in g['hooks']]
assert any(h.get('command') == '$BASH_ABS_TEST' and any('local-guard.sh' in a for a in h.get('args', [])) for h in entries), f'entree local-guard.sh absente du fichier local : {entries}'
proj = json.load(open('$S15_PROJECT'))
proj_cmds_args = []
for ev in proj.get('hooks', {}).values():
    for g in ev:
        for h in g['hooks']:
            proj_cmds_args.append(h.get('command',''))
            proj_cmds_args.extend(a for a in h.get('args', []) if isinstance(a, str))
assert not any('local-guard.sh' in c for c in proj_cmds_args), f'entree local-guard.sh fuite dans le fichier projet : {proj_cmds_args}'
" 2>/dev/null; then
  ok "T15 entrée {{VF_BASH}} + --settings-local fournie → atterrit dans le fichier local, absente du fichier projet"
else
  ko "T15 routage vers --settings-local"
fi

# ---------- T16 : entrée SANS {{VF_BASH}} (forme shell) + --settings-local fournie → reste projet ----------
if python3 -c "
import json
proj = json.load(open('$S15_PROJECT'))
proj_cmds = [h.get('command','') for g in proj['hooks']['PreToolUse'] for h in g['hooks']]
assert any('shell-guard.sh' in c for c in proj_cmds), f'entree shell-guard.sh absente du fichier projet : {proj_cmds}'
local_ = json.load(open('$S15_LOCAL'))
local_cmds_args = []
for ev in local_.get('hooks', {}).values():
    for g in ev:
        for h in g['hooks']:
            local_cmds_args.append(h.get('command',''))
            local_cmds_args.extend(a for a in h.get('args', []) if isinstance(a, str))
assert not any('shell-guard.sh' in c for c in local_cmds_args), f'entree shell-guard.sh fuite dans le fichier local : {local_cmds_args}'
" 2>/dev/null; then
  ok "T16 entrée sans {{VF_BASH}} (forme shell) + --settings-local fournie → reste dans le fichier projet, fichier local non affecté"
else
  ko "T16 non-routage de l'entrée shell classique"
fi

# ---------- T17 : --settings-local ABSENTE → comportement identique à avant ----------
S17="$WORK/t17/settings.json"
mkdir -p "$WORK/t17"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_MIXED" --settings "$S17" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
d = json.load(open('$S17'))
entries = [h for g in d['hooks']['PreToolUse'] for h in g['hooks']]
assert any(h.get('command') == '$BASH_ABS_TEST' and any('local-guard.sh' in a for a in h.get('args', [])) for h in entries), f'entree local-guard.sh absente de la cible unique --settings : {entries}'
assert any('shell-guard.sh' in h.get('command','') for h in entries), f'entree shell-guard.sh absente de la cible unique --settings : {entries}'
" 2>/dev/null; then
  ok "T17 --settings-local absente → les deux entrées atterrissent dans la cible --settings unique (compat descendante)"
else
  ko "T17 compat descendante sans --settings-local"
fi

# ---------- T18 : remove avec --settings-local fournie sur un merge antérieur mixte ----------
S18_PROJECT="$WORK/t18/settings.json"
S18_LOCAL="$WORK/t18/settings-local.json"
mkdir -p "$WORK/t18"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_MIXED" --settings "$S18_PROJECT" --settings-local "$S18_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
if bash "$MERGER" remove "$FRAG_MIXED" --settings "$S18_PROJECT" --settings-local "$S18_LOCAL" 2>/dev/null \
   && python3 -c "
import json
proj = json.load(open('$S18_PROJECT'))
local_ = json.load(open('$S18_LOCAL'))
all_cmds_args = []
for d in (proj, local_):
    for ev in d.get('hooks', {}).values():
        for g in ev:
            for h in g['hooks']:
                all_cmds_args.append(h.get('command',''))
                all_cmds_args.extend(a for a in h.get('args', []) if isinstance(a, str))
assert not any('local-guard.sh' in c for c in all_cmds_args), f'entree locale residuelle : {all_cmds_args}'
assert not any('shell-guard.sh' in c for c in all_cmds_args), f'entree projet residuelle : {all_cmds_args}'
assert 'hooks' not in proj, f'clé hooks residuelle cote projet : {proj}'
assert 'hooks' not in local_, f'clé hooks residuelle cote local : {local_}'
" 2>/dev/null; then
  ok "T18 remove avec --settings-local fournie : les deux entrées d'un merge mixte antérieur disparaissent, aucun résidu"
else
  ko "T18 remove balaie les deux cibles"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
