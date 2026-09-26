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
# (43-01, Tâche 2 — validation stricte des valeurs, TDD, T6 à T13, MUT-S1 à MUT-S3) :
#   T6 — vf-nature: Procedure|procédure|outils|vide → rc=1 « vf-nature invalide » (4 fixtures)
#   T7 — procedure avec ecrit seul → rc=1 « sans vf-rubrique-juge » ; vf-rubrique-juge seul →
#        rc=1 « sans ecrit: »
#   T8 — ecrit: sans valeur ni puce / ecrit: [] / vf-rubrique-juge: "" → rc=1 (valeur vide = absente)
#   T9 — entrées ecrit refusées (/abs/x, ../x, a/../b, ~/x, a;b, $(id), a b) vs acceptées
#        (clients/<nom>/diagnostics/, liste flow, puces bloc, référentiels/2026/ accentué)
#   T10 — vf-rubrique-juge en liste → rc=1 ; ../grille.md → rc=1 ; scalaire propre → rc=0
#   T11 — vf-gate-bloquant: oui / vf-livrable-tiers: True → rc=1 « attendu true|false » ;
#         vf-couche-qualite: false → rc=0
#   T12 — champ inconnu (vf-natur) → avertissement ; champs natifs connus → aucun avertissement
#   T13 — frontmatter jamais refermé → rc=1 « frontmatter jamais referme » ; octet ESC dans une
#         valeur → rc=1, aucun octet ESC brut dans la sortie
#   MUT-S1/S2/S3 — invariant_procedure / valider_nature / valider_ecrit neutralisés → rc bascule
#
# La tâche suivante de 43-01 (parité de contrat T14-T21) étend cette suite dans son propre commit.

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
okmut() {  # <id> <rc_mutant> <attendu_mut> <rc_original> <attendu_orig> [trace]
  if [ -n "${6:-}" ]; then
    echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5 · trace : $6"
  else
    echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"
  fi
  pass=$((pass+1))
}
komut() {  # <id> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUE : $2"
  echo "    assertion : MUT-$1 $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

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

# make_gate_mutant <id> <motif> <remplacement> : mute UNE ligne de $REAL_CHECK (motif fixe unique,
# indentation preservee) dans une copie fraiche sous $WORK/mut-<id>/check-skills.sh (+ manifeste du
# jour). Rend 0 (mutant opposable, chemin dans la variable globale MUT_DIR) ou 1 (refuse, deja
# comptabilise via komut). JAMAIS appele en substitution de commande (I1, cf. 43-CONTEXT.md/
# 43-RESEARCH.md) : dans un sous-shell, l'increment de `fail` par komut serait perdu au retour —
# seul un appel DIRECT dans le shell de la suite garde le refus visible dans le decompte final.
# Le mutant doit rester syntaxiquement valide en DEUX temps : bash -n (l'enveloppe) PUIS
# compilation du corps Python extrait du here-document quote (bash -n ne voit rien d'un
# here-document quote — un Python tronque y passerait sans jamais etre detecte).
MUT_DIR=""
make_gate_mutant() { # <id> <motif> <remplacement>
  local id="$1" motif="$2" remplacement="$3"
  local dir orig n tmp
  dir="$WORK/mut-$id"
  MUT_DIR="$dir"
  mkdir -p "$dir"
  mk_manifest "$dir/check-agents-manifest.json" 0
  cp "$REAL_CHECK" "$dir/check-skills.sh"
  orig="$dir/check-skills.sh"
  n="$(grep -Fc -- "$motif" "$orig")"
  if [ "$n" -ne 1 ]; then
    komut "$id" "motif fixe unique dans check-skills.sh" "exactement 1 occurrence" "MOTIF AMBIGU OU ABSENT (n=$n)"
    return 1
  fi
  tmp="$orig.mut"
  MUT_MOTIF_ENV="$motif" MUT_REPL_ENV="$remplacement" awk '
    index($0, ENVIRON["MUT_MOTIF_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) ENVIRON["MUT_REPL_ENV"]
      next
    }
    { print }
  ' "$orig" > "$tmp"
  if cmp -s "$tmp" "$orig"; then
    komut "$id" "mutation produit un fichier different de l'original" "fichiers distincts" "NON OPPOSABLE (identique)"
    rm -f "$tmp"
    return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    komut "$id" "mutant syntaxiquement valide (bash -n)" "bash -n reussit" "bash -n ECHOUE"
    rm -f "$tmp"
    return 1
  fi
  local pybody pyerr pyrc
  pybody="$dir/mutant-body.py"
  awk '/^"\$PYBIN" - <<.PY_CHECK_SKILLS_EOF.$/{f=1;next} /^PY_CHECK_SKILLS_EOF$/{f=0} f' "$tmp" > "$pybody"
  pyerr="$("$PYBIN" -c "
import sys
f = sys.argv[1]
compile(open(f, encoding='utf-8').read(), f, 'exec')
" "$pybody" 2>&1)"
  pyrc=$?
  if [ "$pyrc" -ne 0 ]; then
    komut "$id" "mutant Python valide (compilation du corps du here-document)" "compilation reussit" "SyntaxError : $pyerr"
    rm -f "$tmp" "$pybody"
    return 1
  fi
  rm -f "$pybody"
  mv "$tmp" "$orig"
  return 0
}

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

# ================================ Tâche 2 : T6 à T13, MUT-S1 à MUT-S3 =============================

# ---------- T6 — vf-nature invalide (4 fixtures) -----------------------------------------------
T6_OK=1
for spec in "Procedure" "procédure" "outils" ""; do
  T6_DIR="$WORK/t6-$(echo "$spec" | tr -dc 'a-zA-Zé' )$RANDOM"; mkdir -p "$T6_DIR"
  {
    echo "---"
    echo "name: t6-fixture"
    echo "description: Fixture T6 vf-nature invalide, valeur '$spec'."
    echo "vf-nature: $spec"
    echo "---"
    echo "Corps."
  } > "$T6_DIR/SKILL.md"
  OUT="$(bash "$CHECK" --strict --skills-dir="$T6_DIR" 2>&1)"; RC=$?
  if [ "$RC" -ne 1 ] || ! echo "$OUT" | grep -q "vf-nature invalide"; then
    T6_OK=0
    echo "    [T6] echec sur valeur '$spec' (rc=$RC) : $OUT"
  fi
done
if [ "$T6_OK" -eq 1 ]; then
  ok "T6 vf-nature invalide (Procedure, procédure, outils, vide) -> rc=1 « vf-nature invalide » (4/4)"
else
  ko "T6 (au moins une fixture n'a pas rendu rc=1 avec « vf-nature invalide »)"
fi

# ---------- T7 — procedure avec un seul des deux champs -----------------------------------------
T7A_DIR="$WORK/t7a"; mkdir -p "$T7A_DIR"
cat > "$T7A_DIR/SKILL.md" <<'EOF'
---
name: t7a-ecrit-seul
description: Procedure avec ecrit seul, fixture T7a.
vf-nature: procedure
ecrit: clients/x/
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T7A_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "sans vf-rubrique-juge"; then
  ok "T7a procedure avec ecrit seul -> rc=1 « sans vf-rubrique-juge »"
else
  ko "T7a (rc=$RC) : $OUT"
fi
T7B_DIR="$WORK/t7b"; mkdir -p "$T7B_DIR"
cat > "$T7B_DIR/SKILL.md" <<'EOF'
---
name: t7b-juge-seul
description: Procedure avec vf-rubrique-juge seul, fixture T7b.
vf-nature: procedure
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T7B_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "sans ecrit:"; then
  ok "T7b procedure avec vf-rubrique-juge seul -> rc=1 « sans ecrit: »"
else
  ko "T7b (rc=$RC) : $OUT"
fi

# ---------- T8 — valeurs vides = absentes --------------------------------------------------------
T8A_DIR="$WORK/t8a"; mkdir -p "$T8A_DIR"
cat > "$T8A_DIR/SKILL.md" <<'EOF'
---
name: t8a-ecrit-vide
description: Procedure avec ecrit sans valeur ni puce, fixture T8a.
vf-nature: procedure
ecrit:
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T8A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "FABR-06" && ok "T8a ecrit: sans valeur ni puce -> rc=1 (valeur vide = absente)" || ko "T8a (rc=$RC) : $OUT"

T8B_DIR="$WORK/t8b"; mkdir -p "$T8B_DIR"
cat > "$T8B_DIR/SKILL.md" <<'EOF'
---
name: t8b-ecrit-liste-vide
description: Procedure avec ecrit liste vide, fixture T8b.
vf-nature: procedure
ecrit: []
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T8B_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "FABR-06" && ok "T8b ecrit: [] -> rc=1 (valeur vide = absente)" || ko "T8b (rc=$RC) : $OUT"

T8C_DIR="$WORK/t8c"; mkdir -p "$T8C_DIR"
cat > "$T8C_DIR/SKILL.md" <<'EOF'
---
name: t8c-juge-vide
description: Procedure avec vf-rubrique-juge vide, fixture T8c.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: ""
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T8C_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "FABR-06" && ok 'T8c vf-rubrique-juge: "" -> rc=1 (valeur vide = absente)' || ko "T8c (rc=$RC) : $OUT"

# ---------- T9 — entrées ecrit refusées / acceptées ----------------------------------------------
T9_REJECTED_OK=1
i=0
for entry in "/abs/x" "../x" "a/../b" "~/x" "a;b" '$(id)' "a b"; do
  i=$((i+1))
  T9_DIR="$WORK/t9-rej-$i"; mkdir -p "$T9_DIR"
  {
    echo "---"
    echo "name: t9-rej-$i"
    echo "description: Fixture T9 entree ecrit refusee $i."
    echo "vf-nature: procedure"
    echo "ecrit: \"$entry\""
    echo "vf-rubrique-juge: grilles/diagnostic.md"
    echo "---"
    echo "Corps."
  } > "$T9_DIR/SKILL.md"
  OUT="$(bash "$CHECK" --strict --skills-dir="$T9_DIR" 2>&1)"; RC=$?
  if [ "$RC" -ne 1 ] || ! echo "$OUT" | grep -q "ecrit: entree malformee"; then
    T9_REJECTED_OK=0
    echo "    [T9] entree '$entry' non refusee (rc=$RC) : $OUT"
  fi
done
if [ "$T9_REJECTED_OK" -eq 1 ]; then
  ok "T9 entrées ecrit refusées (/abs/x, ../x, a/../b, ~/x, a;b, \$(id), a b) -> rc=1 « ecrit: entree malformee » (7/7)"
else
  ko "T9 (au moins une entrée refusable n'a pas été refusée)"
fi

T9_ACCEPTED_DIR="$WORK/t9-acc"; mkdir -p "$T9_ACCEPTED_DIR"
cat > "$T9_ACCEPTED_DIR/SKILL.md" <<'EOF'
---
name: t9-accepte-flow
description: Fixture T9 entrees ecrit acceptees (liste flow), forme 1.
vf-nature: procedure
ecrit: [livrables/, clients/<nom>/]
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T9_ACCEPTED_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T9 entrée acceptée : liste flow [livrables/, clients/<nom>/] -> rc=0" || ko "T9 (flow, rc=$RC) : $OUT"

T9_ACCEPTED2_DIR="$WORK/t9-acc2"; mkdir -p "$T9_ACCEPTED2_DIR"
cat > "$T9_ACCEPTED2_DIR/SKILL.md" <<'EOF'
---
name: t9-accepte-bloc
description: Fixture T9 entrees ecrit acceptees, deux puces en bloc + accent.
vf-nature: procedure
ecrit:
  - clients/<nom>/diagnostics/
  - référentiels/2026/
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T9_ACCEPTED2_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T9 entrées acceptées : deux puces en bloc, référentiels/2026/ accentué -> rc=0" || ko "T9 (bloc, rc=$RC) : $OUT"

# ---------- T10 — vf-rubrique-juge : forme --------------------------------------------------------
T10A_DIR="$WORK/t10a"; mkdir -p "$T10A_DIR"
cat > "$T10A_DIR/SKILL.md" <<'EOF'
---
name: t10a-liste
description: vf-rubrique-juge en liste, fixture T10a.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge:
  - grilles/diagnostic.md
  - autre.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T10A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && ok "T10a vf-rubrique-juge en liste -> rc=1" || ko "T10a (rc=$RC) : $OUT"

T10B_DIR="$WORK/t10b"; mkdir -p "$T10B_DIR"
cat > "$T10B_DIR/SKILL.md" <<'EOF'
---
name: t10b-parent
description: vf-rubrique-juge remontant hors arbre, fixture T10b.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: ../grille.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T10B_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && ok "T10b vf-rubrique-juge: ../grille.md -> rc=1" || ko "T10b (rc=$RC) : $OUT"

T10C_DIR="$WORK/t10c"; mkdir -p "$T10C_DIR"
cat > "$T10C_DIR/SKILL.md" <<'EOF'
---
name: t10c-agent
description: vf-rubrique-juge nom d'agent, fixture T10c.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: vf-design-judge
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T10C_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T10c vf-rubrique-juge: vf-design-judge (nom d'agent) -> rc=0" || ko "T10c (rc=$RC) : $OUT"

T10D_DIR="$WORK/t10d"; mkdir -p "$T10D_DIR"
cat > "$T10D_DIR/SKILL.md" <<'EOF'
---
name: t10d-chemin
description: vf-rubrique-juge chemin relatif propre, fixture T10d.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: grilles/diagnostic.md
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T10D_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T10d vf-rubrique-juge: grilles/diagnostic.md -> rc=0" || ko "T10d (rc=$RC) : $OUT"

# ---------- T11 — marqueurs true|false stricts -----------------------------------------------------
T11A_DIR="$WORK/t11a"; mkdir -p "$T11A_DIR"
cat > "$T11A_DIR/SKILL.md" <<'EOF'
---
name: t11a-oui
description: vf-gate-bloquant: oui, fixture T11a.
vf-gate-bloquant: oui
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T11A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "attendu true|false" && ok "T11a vf-gate-bloquant: oui -> rc=1 « attendu true|false »" || ko "T11a (rc=$RC) : $OUT"

T11B_DIR="$WORK/t11b"; mkdir -p "$T11B_DIR"
cat > "$T11B_DIR/SKILL.md" <<'EOF'
---
name: t11b-true-maj
description: vf-livrable-tiers: True, fixture T11b.
vf-livrable-tiers: True
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T11B_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "attendu true|false" && ok "T11b vf-livrable-tiers: True -> rc=1 « attendu true|false »" || ko "T11b (rc=$RC) : $OUT"

T11C_DIR="$WORK/t11c"; mkdir -p "$T11C_DIR"
cat > "$T11C_DIR/SKILL.md" <<'EOF'
---
name: t11c-false
description: vf-couche-qualite: false, fixture T11c.
vf-couche-qualite: false
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T11C_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T11c vf-couche-qualite: false -> rc=0" || ko "T11c (rc=$RC) : $OUT"

# ---------- T12 — champ inconnu vs champs natifs connus --------------------------------------------
T12A_DIR="$WORK/t12a"; mkdir -p "$T12A_DIR"
cat > "$T12A_DIR/SKILL.md" <<'EOF'
---
name: t12a-typo
description: Champ inconnu (typo vf-natur), fixture T12a.
vf-natur: outil
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T12A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && echo "$OUT" | grep -q "champ inconnu" && ok "T12a vf-natur (typo) -> rc=0 + avertissement « champ inconnu »" || ko "T12a (rc=$RC) : $OUT"

T12B_DIR="$WORK/t12b"; mkdir -p "$T12B_DIR"
cat > "$T12B_DIR/SKILL.md" <<'EOF'
---
name: t12b-natifs
description: Champs natifs connus, fixture T12b.
allowed-tools: Read
when_to_use: quand on a besoin de cette fixture
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T12B_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "champ inconnu" && ok "T12b allowed-tools + when_to_use -> rc=0, aucun avertissement" || ko "T12b (rc=$RC) : $OUT"

# ---------- T13 — frontmatter adverse ------------------------------------------------------------
T13A_DIR="$WORK/t13a"; mkdir -p "$T13A_DIR"
printf -- '---\nname: t13a-jamais-ferme\ndescription: Frontmatter jamais referme, fixture T13a.\n' > "$T13A_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T13A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "frontmatter jamais referme" && ok "T13a frontmatter jamais refermé -> rc=1 « frontmatter jamais referme »" || ko "T13a (rc=$RC) : $OUT"

T13B_DIR="$WORK/t13b"; mkdir -p "$T13B_DIR"
"$PYBIN" - "$T13B_DIR/SKILL.md" <<'PYEOF'
import sys
p = sys.argv[1]
with open(p, "w", encoding="utf-8") as fh:
    fh.write("---\nname: t13b-esc\ndescription: Fixture T13b octet ESC.\nvf-nature: procedure\necrit: clients/x\x1b/\nvf-rubrique-juge: grilles/diagnostic.md\n---\nCorps.\n")
PYEOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T13B_DIR" 2>&1)"; RC=$?
ESC_COUNT="$(printf '%s' "$OUT" | od -An -tx1 | tr ' ' '\n' | grep -c '^1b$' || true)"
if [ "$RC" -eq 1 ] && [ "${ESC_COUNT:-0}" -eq 0 ]; then
  ok "T13b octet ESC dans une valeur -> rc=1, aucun octet ESC brut dans la sortie"
else
  ko "T13b (rc=$RC, octets ESC=$ESC_COUNT)"
fi

# ---------- MUT-S1 — invariant_procedure neutralise -----------------------------------------------
if make_gate_mutant S1 "errors.extend(invariant_procedure(rel, fm))" "pass  # MUT-S1"; then
  M="$MUT_DIR/check-skills.sh"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T3_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T3_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 1 ]; then
    okmut S1 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut S1 "rc_mutant=0 (silence), rc_original=1 (T3)" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

# ---------- MUT-S2 — valider_nature neutralise ------------------------------------------------------
if make_gate_mutant S2 "errors.extend(valider_nature(rel, fm))" "pass  # MUT-S2"; then
  M="$MUT_DIR/check-skills.sh"
  T6_PROCMAJ_DIR="$WORK/t6-procedure-maj"; mkdir -p "$T6_PROCMAJ_DIR"
  {
    echo "---"
    echo "name: t6-procedure-maj"
    echo "description: Fixture MUT-S2, vf-nature: Procedure."
    echo "vf-nature: Procedure"
    echo "---"
    echo "Corps."
  } > "$T6_PROCMAJ_DIR/SKILL.md"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T6_PROCMAJ_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T6_PROCMAJ_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 1 ]; then
    okmut S2 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut S2 "rc_mutant=0 (silence), rc_original=1 (T6 Procedure)" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

# ---------- MUT-S3 — validation de forme de ecrit neutralisee ---------------------------------------
if make_gate_mutant S3 "errors.extend(valider_ecrit(rel, fm.get(\"ecrit\")))" "pass  # MUT-S3"; then
  M="$MUT_DIR/check-skills.sh"
  T9_DOTDOT_DIR="$WORK/t9-rej-2"  # ../x, cree plus haut dans la boucle T9
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T9_DOTDOT_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T9_DOTDOT_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 1 ]; then
    okmut S3 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut S3 "rc_mutant=0 (silence), rc_original=1 (T9 ../x)" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
