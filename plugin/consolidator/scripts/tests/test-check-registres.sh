#!/usr/bin/env bash
# test-check-registres.sh — Suite du lint format registres (ADR-043).
#
# T1 — registre conforme (## Index + '---' + #Ligne + IDs cohérents) → exit 0
# T2 — registre sans '## Index' → exit 1
# T3 — index sans colonne #Ligne → exit 1
# T4 — entrée de body non indexée → exit 1
# T5 — ID dupliqué dans le body → exit 1
# T6 — --strict avec les 5 registres canon absents → exit 1 ; présents et conformes → exit 0
# T7 — --hook : exit 0 même non conforme, sortie compacte signalant le problème
# T8 (CSL-16) — registre conforme à gros préambule (150 lignes) → exit 0 (head -40/-60 le rejetait)
# T9 (CSL-01) — '## Index' sans ligne '---' de fermeture → exit 1 (reindex refuserait la réécriture)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK="$(cd "$TESTS_DIR/.." && pwd)/check-registres.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-check-registres (lint: $CHECK) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

conforming_register() {
  # $1 = fichier · $2 = préfixe ID (DEC, LRN...)
  # Format canonique v2 : le bloc index est REFERMÉ par '---' (CSL-01 — sans ce
  # terminateur, reindex --apply refuse la réécriture et check-registres signale).
  cat > "$1" <<EOF
# Registre

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| ${2}-001 | 2026-07-01 | Premiere entree | 12 | Resume court |

---

## ${2}-001 : Premiere entree

Contenu.
EOF
}

# T1 — conforme
M1="$WORK/t1"; mkdir -p "$M1"
conforming_register "$M1/DECISIONS.md" "DEC"
if bash "$CHECK" --memory-dir="$M1" >/dev/null 2>&1; then
  ok "T1 registre conforme → exit 0"
else
  ko "T1 registre conforme rejeté"
fi

# T2 — sans ## Index
M2="$WORK/t2"; mkdir -p "$M2"
printf '# Registre\n\n## DEC-001 : Entree\n\nContenu.\n' > "$M2/DECISIONS.md"
if bash "$CHECK" --memory-dir="$M2" >/dev/null 2>&1; then
  ko "T2 registre sans index accepté"
else
  ok "T2 registre sans '## Index' → exit 1"
fi

# T3 — index sans #Ligne
M3="$WORK/t3"; mkdir -p "$M3"
cat > "$M3/DECISIONS.md" <<'EOF'
# Registre

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| DEC-001 | 2026-07-01 | Entree | fait |

---

## DEC-001 : Entree

Contenu.
EOF
if bash "$CHECK" --memory-dir="$M3" >/dev/null 2>&1; then
  ko "T3 index sans #Ligne accepté (format v1 doit être rejeté)"
else
  ok "T3 index sans colonne #Ligne → exit 1"
fi

# T4 — body non indexé
M4="$WORK/t4"; mkdir -p "$M4"
conforming_register "$M4/DECISIONS.md" "DEC"
printf '\n## DEC-002 : Entree fantome\n\nJamais indexee.\n' >> "$M4/DECISIONS.md"
if bash "$CHECK" --memory-dir="$M4" >/dev/null 2>&1; then
  ko "T4 entrée non indexée acceptée"
else
  ok "T4 entrée de body non indexée → exit 1"
fi

# T5 — ID dupliqué
M5="$WORK/t5"; mkdir -p "$M5"
conforming_register "$M5/DECISIONS.md" "DEC"
printf '\n## DEC-001 : Doublon\n\nMeme ID.\n' >> "$M5/DECISIONS.md"
if bash "$CHECK" --memory-dir="$M5" >/dev/null 2>&1; then
  ko "T5 ID dupliqué accepté"
else
  ok "T5 ID dupliqué dans le body → exit 1"
fi

# T6 — strict
M6a="$WORK/t6a"; mkdir -p "$M6a"
conforming_register "$M6a/DECISIONS.md" "DEC"
if bash "$CHECK" --strict --memory-dir="$M6a" >/dev/null 2>&1; then
  ko "T6a strict avec 4 registres canon manquants accepté"
else
  ok "T6a --strict + registres canon manquants → exit 1"
fi
M6b="$WORK/t6b"; mkdir -p "$M6b"
conforming_register "$M6b/DECISIONS.md" "DEC"
conforming_register "$M6b/LEARNINGS.md" "LRN"
conforming_register "$M6b/BLOCKERS.md" "BLK"
conforming_register "$M6b/EVALS.md" "EVAL"
cat > "$M6b/JOURNAL.md" <<'EOF'
# Journal

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| Session 1 | 2026-07-01 | Init | 12 | Premiere session |

---

## Session 1 : Init

Contenu.
EOF
if bash "$CHECK" --strict --memory-dir="$M6b" >/dev/null 2>&1; then
  ok "T6b --strict + 5 registres canon conformes → exit 0"
else
  ko "T6b strict conforme rejeté"
fi

# T7 — hook mode
OUT="$(bash "$CHECK" --hook --memory-dir="$M2" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "non-conformité"; then
  ok "T7 --hook : exit 0 + signalement compact du problème"
else
  ko "T7 --hook (rc=$RC, out=${OUT:-<vide>})"
fi

# T8 (CSL-16) — gros préambule (150 lignes) avant un index conforme → exit 0
M8="$WORK/t8"; mkdir -p "$M8"
{
  echo "# Registre a gros preambule"
  i=1
  while [ "$i" -le 150 ]; do echo "> ligne de preambule $i"; i=$((i+1)); done
  cat <<'EOF'

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-001 | 2026-07-01 | Premiere entree | 160 | Resume court |

---

## DEC-001 : Premiere entree

Contenu.
EOF
} > "$M8/DECISIONS.md"
if bash "$CHECK" --memory-dir="$M8" >/dev/null 2>&1; then
  ok "T8 (CSL-16) préambule 150 lignes + index conforme → exit 0"
else
  ko "T8 (CSL-16) registre à gros préambule faussement déclaré non conforme"
fi

# T10 — gouvernance proportionnée : --strict + EVALS absent
#   a. profil léger (VF_LAB_PROFILE=leger) → warning, exit 0
#   b. profil standard → registre canon manquant, exit 1 (comportement historique)
M10="$WORK/t10"; mkdir -p "$M10"
conforming_register "$M10/DECISIONS.md" "DEC"
conforming_register "$M10/LEARNINGS.md" "LRN"
conforming_register "$M10/BLOCKERS.md" "BLK"
cat > "$M10/JOURNAL.md" <<'EOF'
# Journal

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| Session 1 | 2026-07-01 | Init | 12 | Premiere session |

---

## Session 1 : Init

Contenu.
EOF
OUT="$(VF_LAB_PROFILE=leger bash "$CHECK" --strict --memory-dir="$M10" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "profil léger"; then
  ok "T10a --strict + profil léger : EVALS absent → warning, exit 0"
else
  ko "T10a attendu exit 0 + warning profil léger (rc=$RC, out=${OUT:-<vide>})"
fi
if VF_LAB_PROFILE=standard bash "$CHECK" --strict --memory-dir="$M10" >/dev/null 2>&1; then
  ko "T10b profil standard, EVALS absent accepté (devrait rester exigé)"
else
  ok "T10b --strict + profil standard : EVALS absent → exit 1 (historique)"
fi

# T9 (CSL-01) — '## Index' présent mais jamais refermé par '---' → exit 1 + message dédié
M9="$WORK/t9"; mkdir -p "$M9"
cat > "$M9/DECISIONS.md" <<'EOF'
# Registre

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-001 | 2026-07-01 | Premiere entree | 10 | Resume court |

## DEC-001 : Premiere entree

Contenu.
EOF
OUT="$(bash "$CHECK" --memory-dir="$M9" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "sans ligne '---' de fermeture"; then
  ok "T9 (CSL-01) index sans terminateur '---' → exit 1 + signalement"
else
  ko "T9 (CSL-01) attendu exit 1 + message terminateur (rc=$RC, out=${OUT:-<vide>})"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
