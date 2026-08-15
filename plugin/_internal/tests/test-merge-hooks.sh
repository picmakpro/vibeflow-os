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
# Purge cross-cible au merge (correction exec-30-01, second manque) : apply_merge() ne purgeait
# les doublons que dans la cible passée à CET appel — quand la destination d'une entrée change
# d'un merge au suivant (forme shell↔exec, ou --settings-local fourni puis pas), l'ancienne
# entrée survivait dans l'AUTRE fichier et le hook tournait 2x.
# T19 — Cas A (repro directe du manque) : merge forme shell SANS --settings-local, puis remerge
#       forme exec (même script) AVEC --settings-local → le fichier projet ne contient plus
#       AUCUNE entrée pour ce script, le fichier local en contient exactement UNE.
# T20 — Cas B, sens retour local→projet : merge forme exec AVEC --settings-local (entrée locale),
#       puis remerge forme shell — --settings-local TOUJOURS fournie sur ce 2e appel (voir note
#       ci-dessous) → le fichier projet contient exactement UNE entrée, le fichier local n'en
#       contient plus AUCUNE.
#       Note de fidélité au mandat : la formulation littérale de Cas B ("remerge SANS
#       --settings-local") demande que le 2e appel OMETTE le flag. C'est architecturalement
#       impossible à satisfaire pour la moitié "le fichier local n'en contient plus aucune" :
#       merge-hooks.sh est un script sans état persistant entre deux invocations — s'il ne reçoit
#       pas --settings-local au 2e appel, il n'a strictement aucun moyen de connaître le chemin du
#       fichier local à purger (il ne l'ouvre même pas). T20 reproduit donc le changement de
#       destination local→projet (le cœur du manque : Cas A à l'envers) en gardant le flag fourni
#       aux deux appels, ce qui est nécessaire et suffisant pour exercer la purge croisée ajoutée
#       par le correctif. T20b documente séparément et explicitement la frontière architecturale
#       de la lecture littérale (flag réellement omis au 2e appel) — état attendu, pas un défaut.
# T20b — lecture littérale de Cas B (flag OMIS au 2e appel) : le fichier projet est correct (1
#        entrée, dédup intra-cible déjà garantie), le fichier local n'est PAS rouvert par ce 2e
#        appel et conserve donc son entrée résiduelle — comportement attendu et documenté, pas
#        une régression du correctif (T19/T20 couvrent le cas où le flag reste fourni).
# T21 — matrice générique complète : produit cartésien {forme shell, forme exec} x {forme shell,
#       forme exec} x {--settings-local on/off au 1er appel} x {--settings-local on/off au 2e appel}
#       = 16 séquences (flag INDÉPENDANT par appel — corrige la version précédente qui figeait un
#       flagmode constant aux deux appels et ne couvrait donc que la diagonale flag1==flag2 : 6 des
#       8 séquences de cette diagonale n'exerçaient AUCUNE ligne du correctif, éprouvé par
#       mutation lors de la revue précédente).
#       2 des 16 séquences (form1=exec + flag1=on + flag2=off, form2 quelconque) restent hors de
#       portée architecturale — même frontière que T20b : le 2e appel n'ayant jamais reçu
#       --settings-local, il n'a structurellement aucun chemin vers le fichier local à purger.
#       Exclues du comptage strict « 1 entrée totale », vérifiées séparément (fichier projet
#       correct à 1 entrée, résidu local à 1 entrée attendu et documenté — pas une régression).
#       Les 14 séquences restantes finissent toutes avec exactement 1 entrée au total. Parmi
#       elles, 4 sont discriminantes pour la purge croisée (la destination change entre les deux
#       appels : #3 shell-on→exec-on, #7 shell-off→exec-on, #9 exec-on→shell-on, #15 exec-off→
#       exec-on — cette dernière est la transition minimale exigée par le mandat) — prouvées par
#       mutation (purge croisée désactivée dans apply_merge, même mutation que la revue) : ce
#       sont les 4 seules à passer de 1 à 2 entrées sous le code muté ; les 10 autres (contrôle,
#       même cible aux deux appels) et les 2 exclues restent inchangées sous la mutation.
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

# ---------- T19 : Cas A — shell SANS --settings-local, puis exec AVEC --settings-local ----------
FRAG_CASEA_SHELL="$WORK/frag-casea-shell.json"
cat > "$FRAG_CASEA_SHELL" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/case-a-guard.sh" } ] } ] } }
EOF
FRAG_CASEA_EXEC="$WORK/frag-casea-exec.json"
cat > "$FRAG_CASEA_EXEC" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/case-a-guard.sh"] } ] } ] } }
EOF
S19_PROJECT="$WORK/t19/settings.json"
S19_LOCAL="$WORK/t19/settings-local.json"
mkdir -p "$WORK/t19"
bash "$MERGER" merge "$FRAG_CASEA_SHELL" --settings "$S19_PROJECT" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_CASEA_EXEC" --settings "$S19_PROJECT" --settings-local "$S19_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
proj = json.load(open('$S19_PROJECT'))
proj_hits = [h for g in proj.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
             if 'case-a-guard.sh' in h.get('command','') or any('case-a-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert proj_hits == [], f'attendu 0 entree cote projet (ancienne forme shell residuelle), trouve {len(proj_hits)} : {proj_hits}'
loc = json.load(open('$S19_LOCAL'))
loc_hits = [h for g in loc.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
            if 'case-a-guard.sh' in h.get('command','') or any('case-a-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(loc_hits) == 1, f'attendu 1 entree cote local, trouve {len(loc_hits)} : {loc_hits}'
assert 'args' in loc_hits[0], f'entree locale pas en forme exec : {loc_hits[0]}'
" 2>/dev/null; then
  ok "T19 Cas A (shell sans flag → exec avec flag) : fichier projet 0 entrée résiduelle, fichier local 1 entrée"
else
  ko "T19 Cas A dédup cross-cible au changement de destination shell→local"
fi

# ---------- T20 : Cas B — exec AVEC --settings-local, puis shell (flag toujours fourni) ----------
# Voir note de fidélité au mandat en tête de fichier : le flag reste fourni aux deux appels pour
# que le 2e appel ait un chemin vers le fichier local à purger (T20b couvre la lecture littérale
# où le flag est omis).
FRAG_CASEB_EXEC="$WORK/frag-caseb-exec.json"
cat > "$FRAG_CASEB_EXEC" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/case-b-guard.sh"] } ] } ] } }
EOF
FRAG_CASEB_SHELL="$WORK/frag-caseb-shell.json"
cat > "$FRAG_CASEB_SHELL" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/case-b-guard.sh" } ] } ] } }
EOF
S20_PROJECT="$WORK/t20/settings.json"
S20_LOCAL="$WORK/t20/settings-local.json"
mkdir -p "$WORK/t20"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_CASEB_EXEC" --settings "$S20_PROJECT" --settings-local "$S20_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_CASEB_SHELL" --settings "$S20_PROJECT" --settings-local "$S20_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
proj = json.load(open('$S20_PROJECT'))
proj_hits = [h for g in proj.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
             if 'case-b-guard.sh' in h.get('command','') or any('case-b-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(proj_hits) == 1, f'attendu 1 entree cote projet, trouve {len(proj_hits)} : {proj_hits}'
assert 'args' not in proj_hits[0], f'entree projet pas en forme shell : {proj_hits[0]}'
loc = json.load(open('$S20_LOCAL'))
loc_hits = [h for g in loc.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
            if 'case-b-guard.sh' in h.get('command','') or any('case-b-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert loc_hits == [], f'attendu 0 entree cote local (ancienne forme exec residuelle), trouve {len(loc_hits)} : {loc_hits}'
" 2>/dev/null; then
  ok "T20 Cas B (exec local → shell projet, flag fourni aux deux appels) : fichier projet 1 entrée, fichier local 0 entrée"
else
  ko "T20 Cas B dédup cross-cible au changement de destination local→shell"
fi

# ---------- T20b : lecture littérale de Cas B — flag OMIS au 2e appel (frontière architecturale) ----------
S20B_PROJECT="$WORK/t20b/settings.json"
S20B_LOCAL="$WORK/t20b/settings-local.json"
mkdir -p "$WORK/t20b"
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_CASEB_EXEC" --settings "$S20B_PROJECT" --settings-local "$S20B_LOCAL" --scripts-prefix "$PREFIX" 2>/dev/null
# 2e appel SANS --settings-local : le script n'a strictement aucun chemin vers $S20B_LOCAL ici.
VF_BASH_BIN="$BASH_ABS_TEST" bash "$MERGER" merge "$FRAG_CASEB_SHELL" --settings "$S20B_PROJECT" --scripts-prefix "$PREFIX" 2>/dev/null
if python3 -c "
import json
proj = json.load(open('$S20B_PROJECT'))
proj_hits = [h for g in proj.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
             if 'case-b-guard.sh' in h.get('command','') or any('case-b-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(proj_hits) == 1, f'attendu 1 entree cote projet (dedup intra-cible, inchange), trouve {len(proj_hits)} : {proj_hits}'
loc = json.load(open('$S20B_LOCAL'))
loc_hits = [h for g in loc.get('hooks', {}).get('PreToolUse', []) for h in g['hooks']
            if 'case-b-guard.sh' in h.get('command','') or any('case-b-guard.sh' in a for a in h.get('args', []) if isinstance(a, str))]
assert len(loc_hits) == 1, f'frontiere architecturale rompue : le fichier local a change sans avoir ete rouvert : {loc_hits}'
" 2>/dev/null; then
  ok "T20b flag omis au 2e appel (lecture littérale) : fichier projet correct, fichier local jamais rouvert donc résidu attendu (frontière documentée, pas une régression)"
else
  ko "T20b frontière architecturale --settings-local omise"
fi

# ---------- T21 : matrice générique — {shell,exec} x {shell,exec} x {flag1 on/off} x {flag2 on/off} ----------
FRAG_MATRIX_SHELL="$WORK/frag-matrix-shell.json"
cat > "$FRAG_MATRIX_SHELL" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash {{VF_SCRIPTS}}/matrix-guard.sh" } ] } ] } }
EOF
FRAG_MATRIX_EXEC="$WORK/frag-matrix-exec.json"
cat > "$FRAG_MATRIX_EXEC" <<'EOF'
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/matrix-guard.sh"] } ] } ] } }
EOF

# run_matrix_seq <merger_bin> <workdir> <form1> <flag1> <form2> <flag2>
# Exécute la séquence à deux appels (merge form1 avec flag1, puis merge form2 avec flag2, MÊME
# script matrix-guard.sh) contre $mergerbin et imprime "<total> <compte_projet> <compte_local>".
run_matrix_seq() {
  local mergerbin="$1" mdir="$2" form1="$3" flag1="$4" form2="$5" flag2="$6"
  local mproject="$mdir/settings.json" mlocal="$mdir/settings-local.json"
  local f1 f2
  if [ "$form1" = shell ]; then f1="$FRAG_MATRIX_SHELL"; else f1="$FRAG_MATRIX_EXEC"; fi
  if [ "$form2" = shell ]; then f2="$FRAG_MATRIX_SHELL"; else f2="$FRAG_MATRIX_EXEC"; fi
  if [ "$flag1" = on ]; then
    VF_BASH_BIN="$BASH_ABS_TEST" bash "$mergerbin" merge "$f1" --settings "$mproject" --settings-local "$mlocal" --scripts-prefix "$PREFIX" 2>/dev/null
  else
    VF_BASH_BIN="$BASH_ABS_TEST" bash "$mergerbin" merge "$f1" --settings "$mproject" --scripts-prefix "$PREFIX" 2>/dev/null
  fi
  if [ "$flag2" = on ]; then
    VF_BASH_BIN="$BASH_ABS_TEST" bash "$mergerbin" merge "$f2" --settings "$mproject" --settings-local "$mlocal" --scripts-prefix "$PREFIX" 2>/dev/null
  else
    VF_BASH_BIN="$BASH_ABS_TEST" bash "$mergerbin" merge "$f2" --settings "$mproject" --scripts-prefix "$PREFIX" 2>/dev/null
  fi
  python3 -c "
import json, os
def count(p):
    if not os.path.exists(p):
        return 0
    d = json.load(open(p))
    n = 0
    for ev in d.get('hooks', {}).values():
        for g in ev:
            for h in g.get('hooks', []):
                s = [h.get('command','')] + [a for a in h.get('args', []) if isinstance(a, str)]
                n += sum(1 for x in s if 'matrix-guard.sh' in x)
    return n
p = count('$mproject')
l = count('$mlocal')
print(f'{p+l} {p} {l}')
"
}

# Génère les 16 séquences (form1,flag1,form2,flag2) dans l'ordre déterministe
# {shell,exec} x {on,off} x {shell,exec} x {on,off} — c'est cet ORDRE qui fixe la numérotation
# #1..#16 utilisée dans les traces ci-dessous et dans le commentaire d'en-tête.
# SEQ_EXCLUDED : hors de portée architecturale (form1=exec, flag1=on, flag2=off — même
# frontière que T20b). SEQ_DISCRIMINANT : la destination change entre les deux appels
# (landed1 != landed2) ET la séquence n'est pas exclue — ce sont les séquences que la purge
# croisée de la correction exec-30-01 exerce réellement.
declare -a SEQ_FORM1=() SEQ_FLAG1=() SEQ_FORM2=() SEQ_FLAG2=() SEQ_EXCLUDED=() SEQ_DISCRIMINANT=()
for form1 in shell exec; do
  for flag1 in on off; do
    for form2 in shell exec; do
      for flag2 in on off; do
        SEQ_FORM1+=("$form1"); SEQ_FLAG1+=("$flag1"); SEQ_FORM2+=("$form2"); SEQ_FLAG2+=("$flag2")
        excluded=0
        if [ "$form1" = exec ] && [ "$flag1" = on ] && [ "$flag2" = off ]; then excluded=1; fi
        SEQ_EXCLUDED+=("$excluded")
        landed1=project; if [ "$form1" = exec ] && [ "$flag1" = on ]; then landed1=local; fi
        landed2=project; if [ "$form2" = exec ] && [ "$flag2" = on ]; then landed2=local; fi
        discriminant=0
        if [ "$landed1" != "$landed2" ] && [ "$excluded" -eq 0 ]; then discriminant=1; fi
        SEQ_DISCRIMINANT+=("$discriminant")
      done
    done
  done
done

# ---------- T21a : code sain — les 14 séquences valides finissent à 1 entrée, les 2 exclues
#            respectent la frontière T20b (projet=1, résidu local=1, non compté en échec) ----------
matrix_fail=0
matrix_detail=""
seq_n=0
for i in "${!SEQ_FORM1[@]}"; do
  seq_n=$((seq_n+1))
  form1="${SEQ_FORM1[$i]}"; flag1="${SEQ_FLAG1[$i]}"
  form2="${SEQ_FORM2[$i]}"; flag2="${SEQ_FLAG2[$i]}"
  excluded="${SEQ_EXCLUDED[$i]}"
  MDIR="$WORK/t21-$seq_n"
  mkdir -p "$MDIR"
  RESULT="$(run_matrix_seq "$MERGER" "$MDIR" "$form1" "$flag1" "$form2" "$flag2")"
  TOTAL="$(echo "$RESULT" | awk '{print $1}')"
  PCOUNT="$(echo "$RESULT" | awk '{print $2}')"
  LCOUNT="$(echo "$RESULT" | awk '{print $3}')"
  if [ "$excluded" -eq 1 ]; then
    if [ "$PCOUNT" != "1" ] || [ "$LCOUNT" != "1" ]; then
      matrix_fail=$((matrix_fail+1))
      matrix_detail="${matrix_detail}    séquence #$seq_n EXCLUE (form1=$form1 flag1=$flag1 form2=$form2 flag2=$flag2, frontière T20b) : attendu projet=1/local=1(résidu), obtenu projet=$PCOUNT/local=$LCOUNT
"
    fi
  else
    if [ "$TOTAL" != "1" ]; then
      matrix_fail=$((matrix_fail+1))
      matrix_detail="${matrix_detail}    séquence #$seq_n (form1=$form1 flag1=$flag1 form2=$form2 flag2=$flag2) : attendu 1 entrée totale, obtenu $TOTAL (projet=$PCOUNT local=$LCOUNT)
"
    fi
  fi
done
if [ "$matrix_fail" -eq 0 ]; then
  ok "T21a matrice générique (16 séquences, code sain) : 14 séquences valides à 1 entrée totale, 2 séquences exclues conformes à la frontière T20b (projet=1, résidu local=1)"
else
  printf '%s' "$matrix_detail"
  ko "T21a matrice générique : $matrix_fail séquence(s) en défaut (détail ci-dessus)"
fi

# ---------- T21b : preuve par mutation — purge croisée désactivée dans apply_merge (même
#            mutation que la revue précédente) ----------
MERGER_PRISTINE_COPY="$WORK/merger-pristine.sh"
cp "$MERGER" "$MERGER_PRISTINE_COPY"
MERGER_MUTANT="$WORK/merger-mutant.sh"
cp "$MERGER" "$MERGER_MUTANT"
if ! python3 - "$MERGER_MUTANT" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    content = f.read()
# Deux blocs du fichier commencent par "if other_ev is not None:" — celui qui APPLIQUE la purge
# (suivi de "for eg in other_ev:", ligne ~329) et celui qui nettoie ensuite les groupes vidés
# (suivi de "other_ev[:] = ...", ligne ~337). Seul le premier doit être désarmé : le second est
# un no-op une fois le premier désactivé (rien n'est jamais retiré, donc rien à nettoyer).
pattern = re.compile(r'^([ \t]*)if other_ev is not None:\n\1[ \t]*for eg in other_ev:\n', re.MULTILINE)
matches = pattern.findall(content)
if len(matches) != 1:
    sys.exit(f"mutation impossible : motif trouve {len(matches)}x (attendu 1)")
content = pattern.sub(lambda m: f"{m.group(1)}if False and other_ev is not None:\n{m.group(1)}    for eg in other_ev:\n", content, count=1)
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
PYEOF
then
  ko "T21b mutation : patch d'injection du bug échoué (motif introuvable dans merge-hooks.sh)"
else
  mutant_fail=0
  mutant_detail=""
  seq_n=0
  for i in "${!SEQ_FORM1[@]}"; do
    seq_n=$((seq_n+1))
    form1="${SEQ_FORM1[$i]}"; flag1="${SEQ_FLAG1[$i]}"
    form2="${SEQ_FORM2[$i]}"; flag2="${SEQ_FLAG2[$i]}"
    excluded="${SEQ_EXCLUDED[$i]}"; discriminant="${SEQ_DISCRIMINANT[$i]}"
    MDIR="$WORK/t21-mut-$seq_n"
    mkdir -p "$MDIR"
    RESULT="$(run_matrix_seq "$MERGER_MUTANT" "$MDIR" "$form1" "$flag1" "$form2" "$flag2")"
    TOTAL="$(echo "$RESULT" | awk '{print $1}')"
    PCOUNT="$(echo "$RESULT" | awk '{print $2}')"
    LCOUNT="$(echo "$RESULT" | awk '{print $3}')"
    if [ "$excluded" -eq 1 ]; then
      expected_bite=0
      bit=0
      { [ "$PCOUNT" = "1" ] && [ "$LCOUNT" = "1" ]; } || bit=1
    elif [ "$discriminant" -eq 1 ]; then
      expected_bite=1
      bit=0
      [ "$TOTAL" = "2" ] && bit=1
      mutant_detail="${mutant_detail}    séquence #$seq_n MORD (discriminante, form1=$form1/flag1=$flag1 → form2=$form2/flag2=$flag2) : attendu total=1 (code sain, cf T21a), obtenu total=$TOTAL sous mutation (projet=$PCOUNT local=$LCOUNT)
"
    else
      expected_bite=0
      bit=0
      [ "$TOTAL" = "1" ] || bit=1
    fi
    if [ "$bit" -ne "$expected_bite" ]; then
      mutant_fail=$((mutant_fail+1))
      mutant_detail="${mutant_detail}    séquence #$seq_n MORSURE INATTENDUE (form1=$form1 flag1=$flag1 form2=$form2 flag2=$flag2, excluded=$excluded discriminant=$discriminant) : attendu bite=$expected_bite, obtenu bite=$bit (total=$TOTAL projet=$PCOUNT local=$LCOUNT)
"
    fi
  done
  if [ "$mutant_fail" -eq 0 ]; then
    printf '%s' "$mutant_detail"
    ok "T21b preuve par mutation : exactement les 4 séquences discriminantes (#3, #7, #9, #15) mordent (total 1→2), les 10 séquences de contrôle et les 2 exclues restent inchangées"
  else
    printf '%s' "$mutant_detail"
    ko "T21b preuve par mutation : $mutant_fail morsure(s) inattendue(s) (détail ci-dessus)"
  fi
fi

# ---------- T21c : restauration — merge-hooks.sh réel jamais touché (mutation appliquée à une
#            copie), reconfirmé par cmp ----------
if cmp -s "$MERGER" "$MERGER_PRISTINE_COPY"; then
  ok "T21c restauration : merge-hooks.sh identique à avant la manipulation de mutation (cmp)"
else
  ko "T21c restauration : merge-hooks.sh a été altéré par la manipulation de mutation"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
