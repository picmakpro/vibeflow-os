#!/usr/bin/env bash
# test-check-skills.sh — Suite du gate des skills par nature (B-03, FABR-06/09, Phase 43).
#
# check-skills.sh (43-01, Tâche 1 — tracer) :
#   T1 — SKILL.md avec name+description, sans vf-nature → rc=0, ligne « ✓ skills conformes »
#        citant 1 SKILL.md jugé
#   T2 — vf-nature: procedure + ecrit: + vf-rubrique-juge: → rc=0
#   T3 — vf-nature: procedure sans ecrit ni vf-rubrique-juge → rc=1, « FABR-06 » + chemin relatif
#   T4 — arbre réel : chaque plugin/*/ portant au moins un SKILL.md et non doc-only (module.json)
#        passe --strict, SKILL.md jugés = SKILL.md trouvés (find), exclus (doc-only) imprimés
#   T5 — manifeste sans la septième liste (champs_frontmatter_skills) → rc=1, MANIFESTE-ILLISIBLE
#
# Les tâches suivantes de 43-01 (validation stricte des valeurs T6-T13, parité de contrat
# T14-T21) étendent cette suite dans leurs propres commits.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
REAL_CHECK="$SCRIPTS_DIR/check-skills.sh"
REAL_MANIFEST="$SCRIPTS_DIR/check-agents-manifest.json"

# ADR-054 : meme resolution PYBIN que le gate (stub Microsoft Store, repli python).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[test-check-skills] python3 requis" >&2; exit 1; fi ;;
esac

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------- Manifeste daté : harnais à manifeste du jour (même patron que test-check-agents.sh) --
# La suite juge la LOGIQUE du gate contre un manifeste daté DU JOUR — jamais le manifeste VERSIONNE
# tel quel (sa fraîcheur est jugée par la CI, jamais ici). Toutes les listes sont datées
# d'aujourd'hui par défaut ; seule champs_frontmatter_skills reçoit l'âge demandé — les six autres
# listes sont hors périmètre de ce gate (jugées par check-agents.sh).
mk_manifest() { # <destination> <age_jours_skills> [operation]
  local dest="$1" age="$2" op="${3:-}"
  "$PYBIN" - "$REAL_MANIFEST" "$dest" "$age" "$op" <<'PYEOF'
import json, sys
from datetime import date, timedelta

real_path, dest, age_s, op = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
age = int(age_s)
with open(real_path, encoding="utf-8") as fh:
    m = json.load(fh)
today = date.today()
for liste in m["listes"].values():
    liste["verifie_le"] = today.isoformat()
verifie_le_skills = (today - timedelta(days=age)).isoformat()
m["listes"]["champs_frontmatter_skills"]["verifie_le"] = verifie_le_skills

if op == "tronque":
    text = json.dumps(m, indent=2, ensure_ascii=False)
    text = text[: len(text) // 2]
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(text)
    sys.exit(0)
elif op == "":
    pass
elif op == "sans-septieme":
    del m["listes"]["champs_frontmatter_skills"]
elif op == "date-future":
    m["listes"]["champs_frontmatter_skills"]["verifie_le"] = (today + timedelta(days=10)).isoformat()
else:
    print(f"mk_manifest: operation inconnue '{op}'", file=sys.stderr)
    sys.exit(2)

with open(dest, "w", encoding="utf-8") as fh:
    json.dump(m, fh, indent=2, ensure_ascii=False)
PYEOF
}

mk_gate_dir() { # <dossier> <age_jours_skills> [operation] -> imprime le chemin du dossier
  local dir="$1" age="$2" op="${3:-}"
  mkdir -p "$dir"
  cp "$REAL_CHECK" "$dir/check-skills.sh"
  if [ "$op" != "absent" ]; then
    mk_manifest "$dir/check-agents-manifest.json" "$age" "$op"
  fi
  printf '%s' "$dir"
}

# GATE_DIR : copie de check-skills.sh + manifeste daté du jour (age=0, aucune peremption) — le
# CHECK par defaut de la plupart des cas fonctionnels.
GATE_DIR="$(mk_gate_dir "$WORK/gate" 0)"
CHECK="$GATE_DIR/check-skills.sh"

# ================================ Tâche 1 (tracer) : T1 à T5 =====================================

# ---------- T1 — SKILL.md sans vf-nature -> rc=0 ---------------------------------------------
T1_DIR="$WORK/t1"; mkdir -p "$T1_DIR"
cat > "$T1_DIR/SKILL.md" <<'EOF'
---
name: t1-simple
description: Skill simple sans vf-nature declaree, fixture T1.
---
Corps du skill.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T1_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "✓ skills conformes" && echo "$OUT" | grep -q "1 SKILL.md juge"; then
  ok "T1 SKILL.md sans vf-nature -> rc=0, ✓ skills conformes, 1 SKILL.md jugé"
else
  ko "T1 (rc=$RC) : $OUT"
fi

# ---------- T2 — procedure + ecrit + vf-rubrique-juge -> rc=0 ---------------------------------
T2_DIR="$WORK/t2"; mkdir -p "$T2_DIR"
cat > "$T2_DIR/SKILL.md" <<'EOF'
---
name: t2-procedure-complete
description: Procedure avec ecrit et vf-rubrique-juge, fixture T2.
vf-nature: procedure
ecrit: clients/<nom>/diagnostics/
vf-rubrique-juge: grilles/diagnostic.md
---
Corps du skill.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T2_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then
  ok "T2 procedure + ecrit + vf-rubrique-juge -> rc=0"
else
  ko "T2 (rc=$RC) : $OUT"
fi

# ---------- T3 — procedure sans ecrit ni vf-rubrique-juge -> rc=1 -----------------------------
T3_DIR="$WORK/t3"; mkdir -p "$T3_DIR"
cat > "$T3_DIR/SKILL.md" <<'EOF'
---
name: t3-procedure-nue
description: Procedure sans ecrit ni vf-rubrique-juge, fixture T3.
vf-nature: procedure
---
Corps du skill.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T3_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "FABR-06" && echo "$OUT" | grep -q "SKILL.md"; then
  ok "T3 procedure sans ecrit ni vf-rubrique-juge -> rc=1, FABR-06, chemin relatif"
else
  ko "T3 (rc=$RC) : $OUT"
fi

# ---------- T4 — arbre réel : chaque plugin/*/ non doc-only passe --strict --------------------
T4_TOTAL_JUDGED=0
T4_TOTAL_FOUND=0
T4_EXCLUDED_DOC_ONLY=0
T4_FAIL=0
T4_MODS=0
for d in "$REPO_ROOT"/plugin/*/; do
  mod="$(basename "$d")"
  has_skill="$(find "$d" -name SKILL.md -type f -print -quit)"
  [ -n "$has_skill" ] || continue
  n_find="$(find "$d" -name SKILL.md -type f | wc -l | tr -d ' ')"
  if [ -f "${d}module.json" ]; then
    mtype="$("$PYBIN" -c "import json,sys
try:
    print(json.load(open(sys.argv[1])).get('type',''))
except Exception:
    print('')" "${d}module.json" 2>/dev/null)"
  else
    mtype=""
  fi
  if [ "$mtype" = "doc-only" ]; then
    T4_EXCLUDED_DOC_ONLY=$((T4_EXCLUDED_DOC_ONLY + n_find))
    continue
  fi
  T4_MODS=$((T4_MODS+1))
  OUT="$(bash "$REAL_CHECK" --strict --skills-dir="$d" 2>&1)"; RC=$?
  n_judge="$(echo "$OUT" | grep -oE '[0-9]+ SKILL\.md juge' | grep -oE '^[0-9]+' || true)"
  [ -n "$n_judge" ] || n_judge=0
  if [ "$RC" -ne 0 ]; then
    T4_FAIL=$((T4_FAIL+1))
    echo "    [T4] ECHEC sur $mod (rc=$RC) : $OUT"
  fi
  T4_TOTAL_JUDGED=$((T4_TOTAL_JUDGED + n_judge))
  T4_TOTAL_FOUND=$((T4_TOTAL_FOUND + n_find))
done
echo "  [T4] modules jugés=$T4_MODS · SKILL.md jugés=$T4_TOTAL_JUDGED · trouvés=$T4_TOTAL_FOUND · exclus (doc-only)=$T4_EXCLUDED_DOC_ONLY"
if [ "$T4_FAIL" -eq 0 ] && [ "$T4_TOTAL_JUDGED" -eq "$T4_TOTAL_FOUND" ] && [ "$T4_TOTAL_JUDGED" -gt 0 ] && [ "$T4_MODS" -gt 0 ]; then
  ok "T4 arbre réel : $T4_MODS module(s) non doc-only passent --strict, SKILL.md jugés = trouvés ($T4_TOTAL_JUDGED), $T4_EXCLUDED_DOC_ONLY exclus (doc-only)"
else
  ko "T4 (modules=$T4_MODS jugés=$T4_TOTAL_JUDGED trouvés=$T4_TOTAL_FOUND échecs=$T4_FAIL)"
fi

# ---------- T5 — manifeste sans la septième liste -> rc=1, MANIFESTE-ILLISIBLE ----------------
T5_GATE_DIR="$(mk_gate_dir "$WORK/t5-gate" 0 "sans-septieme")"
OUT="$(bash "$T5_GATE_DIR/check-skills.sh" --strict --skills-dir="$T1_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE"; then
  ok "T5 manifeste sans la septième liste (champs_frontmatter_skills) -> rc=1, MANIFESTE-ILLISIBLE"
else
  ko "T5 (rc=$RC) : $OUT"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
