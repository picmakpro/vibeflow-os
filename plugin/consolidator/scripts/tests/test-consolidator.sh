#!/usr/bin/env bash
# test-consolidator.sh — Suite de tests pour les 4 scripts du package Consolidator
#
# Tests :
#   T1 — reindex.sh --audit détecte gaps index <-> body
#   T2 — reindex.sh --dry-run extrait Date + Resume sans TBD
#   T3 — reindex.sh --apply préserve orphelins (LRN-106 / BLK-005 regression)
#   T4 — archive.sh --dry-run détecte BLK RÉSOLU + skip ACTIF
#   T5 — detect-duplicates.sh détecte collisions IDs
#   T6 — detect-promotions.sh sort candidats operational + cluster
#   T7 — reindex.sh --apply : backups isolés + rotation + gitignore (ADR-049)
#
# Fiabilisation CSL :
#   T-CSL01 — reindex --apply refuse un '## Index' sans terminateur '---' (body préservé)
#   T-CSL08 — après append + apply, chaque #Ligne de l'index == position réelle du body
#   T-CSL09 — verrou mkdir : apply concurrent skippé, verrou périmé cassé puis libéré
#   T-CSL02 — archive --apply idempotent (pas de doublons dans l'archive)
#   T-CSL03 — archive --async se détache (exit immédiat + travail fait en arrière-plan)
#   T-CSL10 — C3 lit aussi JOURNAL.md (réf récente → skip archivage)
#   T-CSL14 — lock archive : actif → skip, périmé → cassé, libéré en sortie
#   T-CSL15 — compteur exact, pas de « 0 » parasite, aucune création hors lab, rotation log
#   T-CSL11 — hooks.json : `|| true` sur le PostToolUse uniquement
#
# Frictions UAT vf-new-lab (2026-07) :
#   T-F1 — templates de registres embarqués (references/templates-memoire/, 5 fichiers, index v2)
#   T-F7 — reindex sur registre à 0 entrée : compteurs propres (pas de « 0\n0 », JSON valide)
#   T-F8 — strays legacy *.bak-reindex-* à côté des registres rapatriés dans .backups/
#
# Usage: ./test-consolidator.sh
# Exit code: 0 si tous tests passent, 1 si au moins 1 échec

set -uo pipefail

cd "$(dirname "$0")/../.."

FIXTURES_DIR="scripts/tests/fixtures"
WORK_DIR="$(mktemp -d)"
trap "rm -rf $WORK_DIR" EXIT

# Setup : copy fixtures into isolated memory dir
mkdir -p "$WORK_DIR/.claude/memory"
cp "$FIXTURES_DIR/LEARNINGS-mini.md" "$WORK_DIR/.claude/memory/LEARNINGS.md"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$WORK_DIR/.claude/memory/BLOCKERS.md"

# Symlink scripts dir
ln -s "$(pwd)/scripts" "$WORK_DIR/.claude/scripts"

PASS=0
FAIL=0
TESTS=()

assert() {
  local name="$1"
  local actual="$2"
  local expected="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  ✅ PASS — $name"
    PASS=$((PASS + 1))
    TESTS+=("PASS|$name")
  else
    echo "  ❌ FAIL — $name"
    echo "     Expected: $expected"
    echo "     Actual:   $actual"
    FAIL=$((FAIL + 1))
    TESTS+=("FAIL|$name")
  fi
}

echo "=== T1 — reindex.sh --audit détecte gaps ==="
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/reindex.sh" --register=LEARNINGS --audit 2>&1)
assert "T1.1 — LEARNINGS index_count" "$output" '"index_count": 4'
assert "T1.2 — LEARNINGS body_count" "$output" '"body_count": 3'
assert "T1.3 — LEARNINGS orphans détectés (LRN-003)" "$output" '"orphans_index_no_body": 1'

echo ""
echo "=== T2 — reindex.sh --dry-run extrait Date + Resume ==="
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/reindex.sh" --register=LEARNINGS --dry-run 2>&1)
assert "T2.1 — date LRN-001 extraite (2026-01-01)" "$output" '"date":"2026-01-01"'
assert "T2.2 — title LRN-001 extrait" "$output" '"title":"Premier learning fixture"'
assert "T2.3 — pas de TBD dans output" "$(echo "$output" | grep -c TBD || true)" "0"

echo ""
echo "=== T3 — reindex.sh --apply préserve orphelins (régression LRN-106) ==="
cp "$WORK_DIR/.claude/memory/LEARNINGS.md" "$WORK_DIR/LEARNINGS.before"
(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/reindex.sh" --register=LEARNINGS --apply >/dev/null 2>&1)
post_count=$(grep -cE "^\| LRN-" "$WORK_DIR/.claude/memory/LEARNINGS.md" || echo 0)
# Note : la fixture a 4 sections body (LRN-001 x2 collision + LRN-002 + LRN-004) + 1 orphelin LRN-003 = 5 lignes
assert "T3.1 — total IDs préservés (5 = 4 body + 1 orphelin, LRN-001 en double inclus)" "$post_count" "5"
orphan_line=$(grep "^| LRN-003" "$WORK_DIR/.claude/memory/LEARNINGS.md" | head -1)
assert "T3.2 — LRN-003 (orphelin) toujours dans index" "$orphan_line" "LRN-003"
assert "T3.3 — LRN-003 marqué body non rédigé" "$orphan_line" "[body non redige"

echo ""
echo "=== T4 — archive.sh détecte BLK RÉSOLU + skip ACTIF ==="
# Set threshold very low (1 day) since fixtures are dated 2026-01 (now is 2026-05+)
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/archive.sh" --dry-run --threshold-days=1 2>&1)
assert "T4.1 — BLK-001 (RÉSOLU) marqué ARCHIVABLE" "$output" "BLK-001: C1=ok"
# BLK-002 ACTIF doit être skip car C1 fail (statut pas archivable)
blk002_archivable=$(echo "$output" | grep -c "BLK-002: C1=ok" || echo 0)
assert "T4.2 — BLK-002 (ACTIF) PAS marqué archivable" "$blk002_archivable" "0"

echo ""
echo "=== T5 — detect-duplicates.sh détecte collisions IDs ==="
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/detect-duplicates.sh" --register=LEARNINGS 2>&1)
assert "T5.1 — collision LRN-001 détectée" "$output" '"id": "LRN-001"'
assert "T5.2 — occurrences 2" "$output" '"occurrences": 2'

echo ""
echo "=== T6 — detect-promotions.sh sort candidats ==="
output=$(cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/detect-promotions.sh" 2>&1)
# LRN-002 contient "toujours" → operational_single
assert "T6.1 — LRN-002 candidate operational" "$output" '"lrn_id": "LRN-002"'

echo ""
echo "=== T7 — reindex.sh --apply : backups isolés + rotation + gitignore (ADR-049) ==="
# 4 applies successifs → doit garder 3 backups max, dans .backups/, jamais à la racine memory/.
for _n in 1 2 3 4; do
  (cd "$WORK_DIR" && MEMORY_DIR=".claude/memory" "$WORK_DIR/.claude/scripts/reindex.sh" --register=LEARNINGS --apply >/dev/null 2>&1)
  sleep 1.1
done
root_baks=$(ls -1 "$WORK_DIR/.claude/memory/"*.bak-reindex-* 2>/dev/null | wc -l | tr -d ' ')
assert "T7.1 — AUCUN backup à la racine memory/ (isolation)" "$root_baks" "0"
kept=$(ls -1 "$WORK_DIR/.claude/memory/.backups/"*.bak-reindex-* 2>/dev/null | wc -l | tr -d ' ')
assert "T7.2 — rotation garde 3 backups max dans .backups/" "$kept" "3"
gi=$(cat "$WORK_DIR/.claude/memory/.backups/.gitignore" 2>/dev/null | tr -d '\n')
assert "T7.3 — .gitignore auto-suffisant dans .backups/" "$gi" "*!.gitignore"

SCRIPTS="$WORK_DIR/.claude/scripts"

# Fixture registre DECISIONS canonique v2 (index + '---' + body)
mk_dec() {
  cat > "$1" <<'EOF'
# Decisions

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-001 | 2026-07-01 | Premiere | 11 | Premiere entree. |

---

## DEC-001 : Premiere

**Date** : 2026-07-01

### Contexte

Premiere entree.
EOF
}

echo ""
echo "=== T-CSL01 — reindex --apply refuse un '## Index' sans terminateur '---' ==="
R1="$WORK_DIR/csl01"; mkdir -p "$R1/.claude/memory"
cat > "$R1/.claude/memory/DECISIONS.md" <<'EOF'
# Decisions

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-001 | 2026-07-01 | Premiere | 10 | Premiere entree. |

## DEC-001 : Premiere

**Date** : 2026-07-01

Contenu precieux du body.
EOF
cp "$R1/.claude/memory/DECISIONS.md" "$R1/avant.md"
output=$(cd "$R1" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=DECISIONS --apply 2>&1)
assert "T-CSL01.1 — réécriture annulée (raison signalée)" "$output" "index_sans_terminateur"
same=$(cmp -s "$R1/avant.md" "$R1/.claude/memory/DECISIONS.md" && echo identique || echo different)
assert "T-CSL01.2 — fichier strictement intact (body préservé)" "$same" "identique"

echo ""
echo "=== T-CSL08 — #Ligne == position réelle après append + apply ==="
R8="$WORK_DIR/csl08"; mkdir -p "$R8/.claude/memory"
mk_dec "$R8/.claude/memory/DECISIONS.md"
cat >> "$R8/.claude/memory/DECISIONS.md" <<'EOF'

## DEC-002 : Deuxieme

**Date** : 2026-07-02

### Contexte

Deuxieme entree.
EOF
(cd "$R8" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=DECISIONS --apply >/dev/null 2>&1)
rows=$(grep -c "^| DEC-" "$R8/.claude/memory/DECISIONS.md" || echo 0)
assert "T-CSL08.1 — 2 entrées indexées" "$rows" "2"
bad=0
while IFS='|' read -r _ f_id _fd _ft f_line _fr; do
  cid=$(echo "$f_id" | tr -d ' ')
  cline=$(echo "$f_line" | tr -d ' ')
  [ -n "$cid" ] || continue
  actual=$(grep -n "^## $cid " "$R8/.claude/memory/DECISIONS.md" | head -1 | cut -d: -f1)
  if [ "$actual" != "$cline" ]; then
    bad=$((bad + 1))
    echo "     (écart $cid : index=$cline réel=$actual)"
  fi
done < <(grep "^| DEC-" "$R8/.claude/memory/DECISIONS.md")
assert "T-CSL08.2 — chaque #Ligne de l'index == position grep -n du body" "$bad" "0"

echo ""
echo "=== T-CSL09 — verrou reindex : concurrent skippé, périmé cassé ==="
R9="$WORK_DIR/csl09"; mkdir -p "$R9/.claude/memory"
mk_dec "$R9/.claude/memory/DECISIONS.md"
mkdir "$R9/.claude/memory/DECISIONS.md.lock.d"
cp "$R9/.claude/memory/DECISIONS.md" "$R9/avant.md"
output=$(cd "$R9" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=DECISIONS --apply 2>&1)
assert "T-CSL09.1 — verrou actif → skip signalé" "$output" "lock occupe"
same=$(cmp -s "$R9/avant.md" "$R9/.claude/memory/DECISIONS.md" && echo identique || echo different)
assert "T-CSL09.2 — fichier non réécrit sous verrou" "$same" "identique"
touch -t 202001010000 "$R9/.claude/memory/DECISIONS.md.lock.d"
output=$(cd "$R9" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=DECISIONS --apply 2>&1)
assert "T-CSL09.3 — verrou périmé cassé → apply passe" "$output" '"mode":"applied"'
lock_left=$([ -d "$R9/.claude/memory/DECISIONS.md.lock.d" ] && echo present || echo absent)
assert "T-CSL09.4 — verrou libéré après apply" "$lock_left" "absent"

echo ""
echo "=== T-CSL02 — archive --apply idempotent (pas de doublons) ==="
A2="$WORK_DIR/csl02"; mkdir -p "$A2/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A2/.claude/memory/BLOCKERS.md"
(cd "$A2" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --apply --threshold-days=1 >/dev/null 2>&1)
(cd "$A2" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --apply --threshold-days=1 >/dev/null 2>&1)
occ=$(grep -c "^## BLK-001" "$A2/.claude/memory/archive/BLOCKERS-archive.md" 2>/dev/null || echo 0)
assert "T-CSL02.1 — BLK-001 présent UNE seule fois après 2 applies" "$occ" "1"

echo ""
echo "=== T-CSL03 — archive --async : détaché réel + garde anti-refork ==="
A3="$WORK_DIR/csl03"; mkdir -p "$A3/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A3/.claude/memory/BLOCKERS.md"
(cd "$A3" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --async --apply --threshold-days=1 >/dev/null 2>&1)
rc=$?
assert "T-CSL03.1 — le hook rend la main immédiatement (exit 0)" "$rc" "0"
found=non
for _i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  if grep -q "^## BLK-001" "$A3/.claude/memory/archive/BLOCKERS-archive.md" 2>/dev/null; then found=oui; break; fi
  sleep 0.5
done
assert "T-CSL03.2 — l'archivage s'exécute en arrière-plan" "$found" "oui"
A3b="$WORK_DIR/csl03b"; mkdir -p "$A3b/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A3b/.claude/memory/BLOCKERS.md"
(cd "$A3b" && VF_ARCHIVE_BG=1 MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --async --apply --threshold-days=1 >/dev/null 2>&1)
sync_done=$(grep -q "^## BLK-001" "$A3b/.claude/memory/archive/BLOCKERS-archive.md" 2>/dev/null && echo oui || echo non)
assert "T-CSL03.3 — garde VF_ARCHIVE_BG : l'enfant travaille en synchrone (pas de re-fork)" "$sync_done" "oui"

echo ""
echo "=== T-CSL10 — C3 lit aussi JOURNAL.md (labs canon) ==="
A10="$WORK_DIR/csl10"; mkdir -p "$A10/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A10/.claude/memory/BLOCKERS.md"
printf '# Journal\n\n## Session 1\n\nTravail en cours sur BLK-001 (toujours actif).\n' > "$A10/.claude/memory/JOURNAL.md"
output=$(cd "$A10" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --dry-run --threshold-days=1 2>&1)
assert "T-CSL10.1 — réf dans JOURNAL.md → skip" "$output" "BLK-001: 1 refs recentes, skip"
blk001_arch=$(echo "$output" | grep -c "BLK-001: C1=ok" || echo 0)
assert "T-CSL10.2 — BLK-001 PAS archivable malgré C1/C2 ok" "$blk001_arch" "0"

echo ""
echo "=== T-CSL14 — lock archive : actif → skip, périmé → cassé + libéré ==="
A14="$WORK_DIR/csl14"; mkdir -p "$A14/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A14/.claude/memory/BLOCKERS.md"
mkdir "$A14/.claude/memory/.archive.lock.d"
output=$(cd "$A14" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --dry-run --threshold-days=1 2>&1)
assert "T-CSL14.1 — lock frais → skip" "$output" "lock actif"
touch -t 202001010000 "$A14/.claude/memory/.archive.lock.d"
output=$(cd "$A14" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --dry-run --threshold-days=1 2>&1)
assert "T-CSL14.2 — lock périmé cassé → scan effectué" "$output" "BLK-001: C1=ok"
lock_left=$([ -d "$A14/.claude/memory/.archive.lock.d" ] && echo present || echo absent)
assert "T-CSL14.3 — lock libéré en sortie (trap)" "$lock_left" "absent"

echo ""
echo "=== T-CSL15 — compteur, stdout propre, non-pollution, rotation log ==="
A15="$WORK_DIR/csl15"; mkdir -p "$A15/.claude/memory"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A15/.claude/memory/BLOCKERS.md"
output=$(cd "$A15" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --apply --threshold-days=1 2>&1)
assert "T-CSL15.1 — compteur exact dans le bilan" "$output" "done (1 entree(s) archivee(s))"
stray=$(echo "$output" | grep -cx "0" || true)
assert "T-CSL15.2 — aucun « 0 » parasite sur stdout" "$stray" "0"
A15b="$WORK_DIR/csl15b"; mkdir -p "$A15b"
(cd "$A15b" && "$SCRIPTS/archive.sh" --apply >/dev/null 2>&1)
polluted=$([ -d "$A15b/.claude" ] && echo oui || echo non)
assert "T-CSL15.3 — répertoire non initialisé : AUCUNE création" "$polluted" "non"
A15c="$WORK_DIR/csl15c"; mkdir -p "$A15c/.claude/memory" "$A15c/.claude/logs"
cp "$FIXTURES_DIR/BLOCKERS-mini.md" "$A15c/.claude/memory/BLOCKERS.md"
i=1; while [ "$i" -le 600 ]; do echo "vieille ligne $i"; i=$((i+1)); done > "$A15c/.claude/logs/archive.log"
(cd "$A15c" && MEMORY_DIR=".claude/memory" "$SCRIPTS/archive.sh" --dry-run --threshold-days=1 >/dev/null 2>&1)
log_lines=$(wc -l < "$A15c/.claude/logs/archive.log" | tr -d ' ')
rot_ok=$([ "$log_lines" -le 300 ] && echo oui || echo "non ($log_lines lignes)")
assert "T-CSL15.4 — rotation log (600 → ≤ 300 lignes)" "$rot_ok" "oui"

echo ""
echo "=== T-CSL11 — hooks.json : || true sur le PostToolUse uniquement ==="
HJ="hooks/hooks.json"
post_ok=$(grep -c 'post-edit-reindex.sh || true' "$HJ" || echo 0)
assert "T-CSL11.1 — PostToolUse tolère une install cassée (|| true)" "$post_ok" "1"
pre_bad=$(grep -E 'guard-(read|bash)-registres\.sh \|\| true' "$HJ" | wc -l | tr -d ' ')
assert "T-CSL11.2 — les 2 PreToolUse bloquants restent SANS || true" "$pre_bad" "0"

echo ""
echo "=== T-F1 — templates de registres embarqués (references/templates-memoire, UAT F1) ==="
TPL="references/templates-memoire"
missing=""
for t in decisions learnings blockers journal evals; do
  [ -f "$TPL/$t-template.md" ] || missing="$missing $t"
done
assert "T-F1.1 — les 5 templates présents (decisions learnings blockers journal evals)" "${missing:-aucun}" "aucun"
noligne=$(grep -L '#Ligne' "$TPL"/*-template.md 2>/dev/null | wc -l | tr -d ' ')
assert "T-F1.2 — chaque template porte un index canonique v2 (colonne #Ligne)" "$noligne" "0"
nocible=$(grep -L 'Fichier cible : `.claude/memory/' "$TPL"/*-template.md 2>/dev/null | wc -l | tr -d ' ')
assert "T-F1.3 — chaque template déclare sa cible sous .claude/memory/ (F6)" "$nocible" "0"

echo ""
echo "=== T-F7 — reindex sur registre à 0 entrée : compteurs propres (UAT F7) ==="
F7="$WORK_DIR/f7"; mkdir -p "$F7/.claude/memory"
cat > "$F7/.claude/memory/LEARNINGS.md" <<'EOF'
# Learnings

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|

---
EOF
output=$(cd "$F7" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=LEARNINGS --apply 2>&1)
assert "T-F7.1 — JSON valide sur registre vide (entries_count:0 d'un seul tenant)" "$output" '"entries_count":0,'
assert "T-F7.2 — log « 0 entrees » sur UNE seule ligne" "$output" "LEARNINGS: 0 entrees body detectees"
stray0=$(echo "$output" | grep -cx "0" || true)
assert "T-F7.3 — aucun « 0 » parasite seul sur sa ligne" "$stray0" "0"
audit=$(cd "$F7" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=LEARNINGS --audit 2>&1)
assert "T-F7.4 — audit registre vide : index_count entier propre" "$audit" '"index_count": 0,'
assert "T-F7.5 — audit registre vide : body_count entier propre" "$audit" '"body_count": 0,'

echo ""
echo "=== T-F8 — strays legacy *.bak-reindex-* rapatriés dans .backups/ (UAT F8) ==="
F8D="$WORK_DIR/f8"; mkdir -p "$F8D/.claude/memory"
mk_dec "$F8D/.claude/memory/DECISIONS.md"
printf 'vieux backup legacy (engine <= v2.23)\n' > "$F8D/.claude/memory/DECISIONS.md.bak-reindex-20250101-000000"
(cd "$F8D" && MEMORY_DIR=".claude/memory" "$SCRIPTS/reindex.sh" --register=DECISIONS --apply >/dev/null 2>&1)
left=$(ls -1 "$F8D/.claude/memory/"*.bak-reindex-* 2>/dev/null | wc -l | tr -d ' ')
assert "T-F8.1 — plus AUCUN stray à côté des registres après --apply" "$left" "0"
migrated=$([ -f "$F8D/.claude/memory/.backups/DECISIONS.md.bak-reindex-20250101-000000" ] && echo oui || echo non)
assert "T-F8.2 — le stray legacy est rapatrié (pas détruit) dans .backups/" "$migrated" "oui"

echo ""
echo "================================"
echo "BILAN : $PASS PASS / $FAIL FAIL / $((PASS + FAIL)) tests"
echo "================================"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
