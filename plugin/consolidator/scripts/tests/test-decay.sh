#!/usr/bin/env bash
# test-decay.sh — Suite de tests pour decay-pass.sh (pilier 5, mémoire vivante, ADR-052)
#
# Tests :
#   T1 — dry-run : compte entrées + effective_confidence calculée + needs_review, fichiers INTACTS
#   T2 — apply   : base confidence préservée, effective/last_decay_pass écrits, ordre canonique
#   T3 — idempotence : 2e passe à date égale = fichier identique, 0 archivage parasite
#   T4 — supersession non destructive : superseded -> archive/, contenu conservé, retiré de l'actif
#   T5 — hygiène : aucun trailing whitespace, backups isolés + .gitignore, no-op si dir absent
#
# Usage: ./test-decay.sh
# Exit code: 0 si tous tests passent, 1 si au moins 1 échec

set -uo pipefail

cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/decay-pass.sh"
TODAY="2026-07-22"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
KN="$WORK_DIR/knowledge"

PASS=0
FAIL=0

assert() {
  local name="$1" actual="$2" expected="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  ✅ PASS — $name"; PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL — $name"
    echo "     Expected substring: $expected"
    echo "     Actual:             $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_not() {
  local name="$1" actual="$2" needle="$3"
  if [[ "$actual" != *"$needle"* ]]; then
    echo "  ✅ PASS — $name"; PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL — $name (a trouvé « $needle »)"; FAIL=$((FAIL + 1))
  fi
}

field() { grep -m1 "^$2:" "$1" | sed "s/^$2:[[:space:]]*//"; }

seed() {
  rm -rf "$KN"; mkdir -p "$KN"
  cat > "$KN/user-samuel.md" <<'EOF'
---
name: user-samuel
description: "Samuel freelance multi-métiers"
metadata:
  node_type: memory
  type: user
trust: high
confidence: 0.9
created: 2026-01-22
status: active
superseded_by:
---

Corps user.
EOF
  cat > "$KN/deadline.md" <<'EOF'
---
name: deadline
description: "projet ship le 15"
metadata:
  node_type: memory
  type: project
trust: medium
confidence: 0.8
created: 2026-05-01
status: active
superseded_by:
---

Corps project volatil.
EOF
  cat > "$KN/vieux-remplace.md" <<'EOF'
---
name: vieux-remplace
description: "remplacé"
metadata:
  node_type: memory
  type: reference
trust: low
confidence: 0.7
created: 2026-03-01
status: active
superseded_by: nouveau
---

CORPS-A-CONSERVER-EN-ARCHIVE
EOF
}

echo "=== T1 — dry-run : calcul sans effet de bord ==="
seed
out=$(KNOWLEDGE_DIR="$KN" "$SCRIPT" --dry-run --today="$TODAY" 2>/dev/null)
assert "T1.1 — 3 entrées comptées"        "$out" '"entries_count": 3'
assert "T1.2 — 1 superseded détecté"      "$out" '"archived_count": 1'
assert "T1.3 — deadline flaggée review"   "$out" '"flagged_count": 1'
assert "T1.4 — effective user calculée"   "$out" '"effective_confidence": 0.4483'
assert "T1.5 — effective project calculée" "$out" '"effective_confidence": 0.1203'
# dry-run ne doit RIEN modifier
assert_not "T1.6 — fichier non réécrit"   "$(cat "$KN/deadline.md")" "effective_confidence"
[ ! -d "$KN/archive" ] && { echo "  ✅ PASS — T1.7 — pas d'archive/ en dry-run"; PASS=$((PASS+1)); } \
                        || { echo "  ❌ FAIL — T1.7 — archive/ créé en dry-run"; FAIL=$((FAIL+1)); }

echo ""
echo "=== T2 — apply : base préservée + champs dérivés ==="
seed
KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" >/dev/null 2>&1
assert "T2.1 — base confidence préservée (0.9)" "$(field "$KN/user-samuel.md" confidence)" "0.9"
assert "T2.2 — effective écrite"                "$(field "$KN/user-samuel.md" effective_confidence)" "0.4483"
assert "T2.3 — last_decay_pass horodaté"        "$(field "$KN/user-samuel.md" last_decay_pass)" "$TODAY"
assert "T2.4 — needs_review true sur deadline"  "$(field "$KN/deadline.md" needs_review)" "true"
assert "T2.5 — needs_review false sur user"     "$(field "$KN/user-samuel.md" needs_review)" "false"

echo ""
echo "=== T3 — idempotence ==="
cp "$KN/deadline.md" "$WORK_DIR/deadline.before"
out2=$(KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" 2>/dev/null)
assert "T3.1 — 0 archivage parasite en passe 2" "$out2" '"archived_count": 0'
if diff -q "$WORK_DIR/deadline.before" "$KN/deadline.md" >/dev/null; then
  echo "  ✅ PASS — T3.2 — fichier identique (idempotent)"; PASS=$((PASS+1))
else
  echo "  ❌ FAIL — T3.2 — fichier modifié en 2e passe"; FAIL=$((FAIL+1))
fi

echo ""
echo "=== T4 — supersession non destructive ==="
seed
KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" >/dev/null 2>&1
[ -f "$KN/archive/vieux-remplace.md" ] && { echo "  ✅ PASS — T4.1 — déplacé vers archive/"; PASS=$((PASS+1)); } \
                                        || { echo "  ❌ FAIL — T4.1 — pas dans archive/"; FAIL=$((FAIL+1)); }
[ ! -f "$KN/vieux-remplace.md" ] && { echo "  ✅ PASS — T4.2 — retiré de l'actif"; PASS=$((PASS+1)); } \
                                  || { echo "  ❌ FAIL — T4.2 — toujours actif"; FAIL=$((FAIL+1)); }
assert "T4.3 — contenu conservé"        "$(cat "$KN/archive/vieux-remplace.md" 2>/dev/null)" "CORPS-A-CONSERVER-EN-ARCHIVE"
assert "T4.4 — status superseded"       "$(field "$KN/archive/vieux-remplace.md" status)" "superseded"

echo ""
echo "=== T5 — hygiène ==="
seed
KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" >/dev/null 2>&1
if grep -rlE ' +$' "$KN"/*.md >/dev/null 2>&1; then
  echo "  ❌ FAIL — T5.1 — trailing whitespace détecté"; FAIL=$((FAIL+1))
else
  echo "  ✅ PASS — T5.1 — aucun trailing whitespace"; PASS=$((PASS+1))
fi
[ -f "$KN/.backups/.gitignore" ] && { echo "  ✅ PASS — T5.2 — backups isolés + .gitignore"; PASS=$((PASS+1)); } \
                                  || { echo "  ❌ FAIL — T5.2 — .backups/.gitignore absent"; FAIL=$((FAIL+1)); }
out3=$(KNOWLEDGE_DIR="$WORK_DIR/inexistant" "$SCRIPT" --dry-run 2>/dev/null)
assert "T5.3 — no-op si dir absent" "$out3" '"present": false'

echo ""
echo "=== T6 — préservation d'une liste YAML inconnue (régression H2) ==="
rm -rf "$KN"; mkdir -p "$KN"
printf -- '---\nname: t\ndescription: "x"\nmetadata:\n  node_type: memory\n  type: user\ntags:\n  - rust\n  - swift\ntrust: high\nconfidence: 0.9\ncreated: 2026-01-22\nstatus: active\nsuperseded_by:\n---\n\nbody\n' > "$KN/t.md"
KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" >/dev/null 2>&1
if grep -qE '^  - rust$' "$KN/t.md" && grep -qE '^  - swift$' "$KN/t.md"; then
  echo "  ✅ PASS — T6.1 — liste 'tags' préservée verbatim"; PASS=$((PASS+1))
else
  echo "  ❌ FAIL — T6.1 — liste corrompue"; FAIL=$((FAIL+1))
fi
if grep -rlE ' +$' "$KN"/*.md >/dev/null 2>&1; then
  echo "  ❌ FAIL — T6.2 — trailing whitespace introduit"; FAIL=$((FAIL+1))
else
  echo "  ✅ PASS — T6.2 — aucun trailing whitespace"; PASS=$((PASS+1))
fi

echo ""
echo "=== T7 — archive homonyme JAMAIS écrasée (régression H1, ADR-031) ==="
rm -rf "$KN"; mkdir -p "$KN/archive"
printf 'CONTENU-DEJA-ARCHIVE\n' > "$KN/archive/dup.md"
printf -- '---\nname: dup\ndescription: "x"\nmetadata:\n  type: reference\ntrust: low\nconfidence: 0.7\ncreated: 2026-03-01\nstatus: active\nsuperseded_by: neo\n---\n\nNOUVEAU\n' > "$KN/dup.md"
KNOWLEDGE_DIR="$KN" "$SCRIPT" --apply --today="$TODAY" >/dev/null 2>&1
assert "T7.1 — ancienne archive intacte" "$(cat "$KN/archive/dup.md")" "CONTENU-DEJA-ARCHIVE"
n_arch=$(ls "$KN/archive/" | grep -c '^dup' || true)
[ "$n_arch" -eq 2 ] && { echo "  ✅ PASS — T7.2 — nouvelle archive suffixée (2 fichiers)"; PASS=$((PASS+1)); } \
                     || { echo "  ❌ FAIL — T7.2 — collision non gérée ($n_arch fichier(s))"; FAIL=$((FAIL+1)); }

echo ""
echo "=== T8 — date future bornée (régression M1) ==="
rm -rf "$KN"; mkdir -p "$KN"
printf -- '---\nname: f\ndescription: "x"\nmetadata:\n  type: user\ntrust: high\nconfidence: 0.9\ncreated: 2027-01-01\nstatus: active\nsuperseded_by:\n---\n\nbody\n' > "$KN/f.md"
outf=$(KNOWLEDGE_DIR="$KN" "$SCRIPT" --dry-run --today="$TODAY" 2>/dev/null)
assert "T8.1 — effective bornée ≤ base (pas de gonflement)" "$outf" '"effective_confidence": 0.9'
assert "T8.2 — age borné à 0" "$outf" '"age_days": 0'

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
