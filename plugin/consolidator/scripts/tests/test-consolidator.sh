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

echo ""
echo "================================"
echo "BILAN : $PASS PASS / $FAIL FAIL / $((PASS + FAIL)) tests"
echo "================================"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
