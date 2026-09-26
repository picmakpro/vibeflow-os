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
# (43-01, Tâche 3 — parité de contrat avec check-agents.sh, TDD, T14 à T21, MUT-SD1/SD2) :
#   T14 — découverte récursive à trois profondeurs, README/notes voisins ignorés
#   T15 — exclusions *-references et dossiers cachés
#   T16 — SKILL.md en lien symbolique refusé sans lecture, jeton hors arbre jamais reflété
#   T17 — préfixe tiers (name: gsd-*) exclu du lint, compté à part ; --no-third-party-prefix relint
#   T18 — CIBLE-ABSENTE / F13 (cible vide, --strict, --allow-empty, --skills-dir= vide)
#   T19 — --hook : silence nominal, ligne compacte sur erreur/avertissement
#   T20 — --file : conforme / violation / introuvable
#   T21 — fraîcheur de champs_frontmatter_skills : périmée (avertissement), fraîche, absente
#   MUT-SD1/SD2 — élagages de découverte neutralisés ; gardes du harnais MUT-SYNTAXE, MUT-REFUS-COMPTE

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

# ================================ Tâche 3 : T14 à T21, MUT-SD1/SD2 =================================

# ---------- T14 — découverte récursive à trois profondeurs -----------------------------------------
T14_DIR="$WORK/t14"; mkdir -p "$T14_DIR/a" "$T14_DIR/mod/skills/b" "$T14_DIR/c/sub/deep"
cat > "$T14_DIR/SKILL.md" <<'EOF'
---
name: t14-racine
description: Fixture T14 a la racine de --skills-dir (temoin MUT-SD1 — reste visible meme si
  l'elagage des dossiers caches est neutralise, puisque le fichier de la racine n'exige aucune
  descente pour etre decouvert).
---
Corps.
EOF
cat > "$T14_DIR/a/SKILL.md" <<'EOF'
---
name: t14-a
description: Fixture T14 profondeur 1.
---
Corps.
EOF
cat > "$T14_DIR/mod/skills/b/SKILL.md" <<'EOF'
---
name: t14-b
description: Fixture T14 profondeur 2.
---
Corps.
EOF
cat > "$T14_DIR/c/sub/deep/SKILL.md" <<'EOF'
---
name: t14-c-deep
description: Fixture T14 profondeur 3, en violation.
vf-nature: procedure
---
Corps.
EOF
echo "notes voisines" > "$T14_DIR/README.md"
echo "notes voisines" > "$T14_DIR/c/sub/deep/notes.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T14_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "c/sub/deep/SKILL.md" && ! echo "$OUT" | grep -q "README.md" && ! echo "$OUT" | grep -q "notes.md"; then
  ok "T14 découverte à trois profondeurs, README/notes voisins ignorés, violation la plus profonde citée"
else
  ko "T14 (rc=$RC) : $OUT"
fi

# ---------- T15 — exclusions *-references et dossiers cachés ---------------------------------------
T15_DIR="$WORK/t15"; mkdir -p "$T15_DIR/lab-references/x" "$T15_DIR/.cache/y" "$T15_DIR/conforme"
cat > "$T15_DIR/lab-references/x/SKILL.md" <<'EOF'
---
name: t15-ref
description: Fixture T15, dans un dossier -references, en violation.
vf-nature: procedure
---
Corps.
EOF
cat > "$T15_DIR/.cache/y/SKILL.md" <<'EOF'
---
name: t15-cache
description: Fixture T15, dans un dossier cache, en violation.
vf-nature: procedure
---
Corps.
EOF
cat > "$T15_DIR/conforme/SKILL.md" <<'EOF'
---
name: t15-conforme
description: Fixture T15, skill conforme.
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T15_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "lab-references" && ! echo "$OUT" | grep -q "\.cache"; then
  ok "T15 exclusions *-references et dossiers cachés -> rc=0, aucun des deux cité"
else
  ko "T15 (rc=$RC) : $OUT"
fi

# ---------- T16 — SKILL.md en lien symbolique refusé sans lecture ----------------------------------
T16_DIR="$WORK/t16"; mkdir -p "$T16_DIR/lien"
JETON_T16="JETON-HORS-ARBRE-T16-$RANDOM"
T16_HORS_ARBRE="$WORK/t16-hors-arbre.md"
printf -- '---\nname: t16-hors-arbre\ndescription: %s\n---\nCorps.\n' "$JETON_T16" > "$T16_HORS_ARBRE"
ln -s "$T16_HORS_ARBRE" "$T16_DIR/lien/SKILL.md"
OUT_STDOUT="$(bash "$CHECK" --strict --skills-dir="$T16_DIR" 2>/tmp/t16-stderr-$$.txt)"; RC=$?
OUT_STDERR="$(cat /tmp/t16-stderr-$$.txt)"; rm -f /tmp/t16-stderr-$$.txt
if [ "$RC" -eq 1 ] && echo "$OUT_STDOUT$OUT_STDERR" | grep -q "lien symbolique refuse" && ! echo "$OUT_STDOUT$OUT_STDERR" | grep -q "$JETON_T16"; then
  ok "T16 SKILL.md en lien symbolique -> rc=1 « lien symbolique refuse », jeton hors arbre jamais reflété"
else
  ko "T16 (rc=$RC) : $OUT_STDOUT$OUT_STDERR"
fi

# ---------- T17 — préfixe tiers exclu du lint, compté à part ---------------------------------------
T17_DIR="$WORK/t17"; mkdir -p "$T17_DIR"
cat > "$T17_DIR/SKILL.md" <<'EOF'
---
name: gsd-outil
description: Fixture T17, skill tiers avec vf-nature invalide (ne doit jamais etre linte).
vf-nature: bidon
---
Corps.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T17_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "1 skill(s) tiers non linte(s)"; then
  ok "T17 skill tiers (name: gsd-outil) -> rc=0, « 1 skill(s) tiers non linte(s) »"
else
  ko "T17 (rc=$RC) : $OUT"
fi
OUT="$(bash "$CHECK" --strict --skills-dir="$T17_DIR" --no-third-party-prefix 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && ok "T17 --no-third-party-prefix -> gsd-outil linté normalement -> rc=1" || ko "T17b (rc=$RC) : $OUT"

# ---------- T18 — CIBLE-ABSENTE / F13 ---------------------------------------------------------------
T18_ABSENT="$WORK/t18-absent-jamais-cree"
OUT="$(bash "$CHECK" --skills-dir="$T18_ABSENT" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && echo "$OUT" | grep -q "CIBLE-ABSENTE" && ok "T18 cible absente -> rc=3, CIBLE-ABSENTE" || ko "T18a (rc=$RC) : $OUT"

OUT="$(bash "$CHECK" --skills-dir="$T18_ABSENT" --hook 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && [ -z "$OUT" ] && ok "T18 cible absente + --hook -> rc=0, stdout vide" || ko "T18b (rc=$RC) : [$OUT]"

T18_VIDE="$WORK/t18-vide"; mkdir -p "$T18_VIDE"
OUT="$(bash "$CHECK" --skills-dir="$T18_VIDE" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T18 cible présente vide -> rc=0" || ko "T18c (rc=$RC) : $OUT"

OUT="$(bash "$CHECK" --strict --skills-dir="$T18_VIDE" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && ok "T18 cible vide + --strict -> rc=3" || ko "T18d (rc=$RC) : $OUT"

OUT="$(bash "$CHECK" --strict --allow-empty --skills-dir="$T18_VIDE" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T18 cible vide + --strict --allow-empty -> rc=0" || ko "T18e (rc=$RC) : $OUT"

RC=0; bash "$CHECK" "--skills-dir=" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T18 --skills-dir= vide -> rc=1" || ko "T18f (rc=$RC)"

# ---------- T19 — --hook -----------------------------------------------------------------------------
OUT="$(bash "$CHECK" --hook --skills-dir="$T1_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && [ -z "$OUT" ] && ok "T19 --hook sur corpus conforme -> rc=0, stdout vide" || ko "T19a (rc=$RC) : [$OUT]"

OUT="$(bash "$CHECK" --hook --skills-dir="$T3_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && [ -n "$OUT" ] && ok "T19 --hook sur violation FABR-06 -> rc=0, ligne compacte d'erreur" || ko "T19b (rc=$RC) : [$OUT]"

OUT="$(bash "$CHECK" --hook --skills-dir="$T12A_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && echo "$OUT" | grep -q "⚠" && ok "T19 --hook sur champ inconnu seul -> rc=0, ligne compacte « ⚠ »" || ko "T19c (rc=$RC) : [$OUT]"

# ---------- T20 — --file --------------------------------------------------------------------------
OUT="$(bash "$CHECK" --file "$T1_DIR/SKILL.md" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T20 --file sur SKILL.md conforme -> rc=0" || ko "T20a (rc=$RC) : $OUT"

OUT="$(bash "$CHECK" --file "$T3_DIR/SKILL.md" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && ok "T20 --file sur SKILL.md en violation -> rc=1" || ko "T20b (rc=$RC) : $OUT"

OUT="$(bash "$CHECK" --file "$WORK/introuvable/SKILL.md" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "fichier introuvable" && ok "T20 --file sur chemin inexistant -> rc=1 « fichier introuvable »" || ko "T20c (rc=$RC) : $OUT"

# ---------- T21 — fraîcheur de champs_frontmatter_skills --------------------------------------------
T21_PERIME_DIR="$(mk_gate_dir "$WORK/t21-perime" 40)"
OUT="$(bash "$T21_PERIME_DIR/check-skills.sh" --strict --skills-dir="$T1_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && echo "$OUT" | grep -q "MANIFESTE-PERIME" && ok "T21 septième liste périmée (40j) -> rc=0, ⚠ MANIFESTE-PERIME" || ko "T21a (rc=$RC) : $OUT"

T21_FRAIS_DIR="$(mk_gate_dir "$WORK/t21-frais" 0)"
OUT="$(bash "$T21_FRAIS_DIR/check-skills.sh" --strict --skills-dir="$T1_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "MANIFESTE-PERIME" && ok "T21 septième liste datée du jour -> rc=0, aucune ligne MANIFESTE-PERIME" || ko "T21b (rc=$RC) : $OUT"

T21_ABSENT_DIR="$(mk_gate_dir "$WORK/t21-absent" 0 absent)"
OUT="$(bash "$T21_ABSENT_DIR/check-skills.sh" --strict --skills-dir="$T1_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 1 ] && echo "$OUT" | grep -q "MANIFESTE-ILLISIBLE" && ok "T21 manifeste absent -> rc=1, MANIFESTE-ILLISIBLE" || ko "T21c (rc=$RC) : $OUT"
OUT="$(bash "$T21_ABSENT_DIR/check-skills.sh" --strict --hook --skills-dir="$T1_DIR" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "T21 manifeste absent + --hook -> rc=0" || ko "T21d (rc=$RC) : $OUT"

# ---------- MUT-SD1 — élagage des dossiers cachés neutralisé (vide TOUS les sous-dossiers) ----------
if make_gate_mutant SD1 "dirnames[:] = [d for d in dirnames if not d.startswith('.')]" "dirnames[:] = []  # MUT-SD1"; then
  M="$MUT_DIR/check-skills.sh"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T14_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T14_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 1 ]; then
    okmut SD1 "$RC_MUT" 0 "$RC_ORIG" 1
  else
    komut SD1 "rc_mutant=0 (plus aucune descente), rc_original=1 (T14)" "rc_mutant=0, rc_original=1" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

# ---------- MUT-SD2 — élagage des dossiers *-references neutralisé (pass) ---------------------------
if make_gate_mutant SD2 "dirnames[:] = [d for d in dirnames if not d.endswith('-references')]" "pass  # MUT-SD2"; then
  M="$MUT_DIR/check-skills.sh"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T15_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T15_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_MUT" -eq 1 ] && [ "$RC_ORIG" -eq 0 ] \
     && echo "$OUT_MUT" | grep -q "lab-references/x/SKILL.md" && echo "$OUT_MUT" | grep -q "FABR-06" \
     && ! echo "$OUT_ORIG" | grep -q "lab-references/x/SKILL.md"; then
    okmut SD2 "$RC_MUT" 1 "$RC_ORIG" 0 "lab-references/x/SKILL.md en erreur FABR-06 sur le mutant, absent de l'original"
  else
    komut SD2 "rc_mutant=1 (lab-references/x/SKILL.md cité, FABR-06), rc_original=0 (T15)" "rc_mutant=1, rc_original=0" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

# ================================ 43-02 Tâche 1 : T22 à T29, MUT-DR1/DR2 ===========================
# Détection de dérive (D-Q1, D-Q5, FABR-07) — écart entre déclaration frontmatter des trois
# marqueurs B-03 et motifs constatés dans le corps, selon la règle Q-PORTEE (décision déléguée par
# Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26) : toujours un
# avertissement, jamais un refus.

# ---------- T22 — marqueur en titre, aucune déclaration -> derive ----------------------------------
T22_DIR="$WORK/t22"; mkdir -p "$T22_DIR"
cat > "$T22_DIR/SKILL.md" <<'EOF'
---
name: t22-titre-gate
description: Fixture T22, marqueur en titre sans declaration, Q-PORTEE.
---
## Gate de validation

Corps du skill, aucune autre ligne a marqueur.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T22_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "derive" && echo "$OUT" | grep -q "vf-gate-bloquant" && echo "$OUT" | grep -q "Gate de validation"; then
  ok "T22 titre « Gate de validation » sans déclaration -> rc=0, avertissement « derive » nommant vf-gate-bloquant et reprenant le titre"
else
  ko "T22 (rc=$RC) : $OUT"
fi

# ---------- T23 — même fixture + vf-gate-bloquant: true -> aucun avertissement pour ce marqueur ----
T23_DIR="$WORK/t23"; mkdir -p "$T23_DIR"
cat > "$T23_DIR/SKILL.md" <<'EOF'
---
name: t23-titre-gate-declare
description: Fixture T23, meme titre + vf-gate-bloquant declare true, Q-PORTEE.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: grilles/diagnostic.md
vf-gate-bloquant: true
---
## Gate de validation

Corps du skill, aucune autre ligne a marqueur.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T23_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T23 même fixture + vf-gate-bloquant: true -> rc=0, aucun avertissement « derive » pour ce marqueur"
else
  ko "T23 (rc=$RC) : $OUT"
fi

# ---------- T24 — vf-gate-bloquant: true sans aucun motif -> ecart ---------------------------------
T24_DIR="$WORK/t24"; mkdir -p "$T24_DIR"
cat > "$T24_DIR/SKILL.md" <<'EOF'
---
name: t24-declare-sans-motif
description: Fixture T24, vf-gate-bloquant declare true sans aucun motif dans le corps.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: grilles/diagnostic.md
vf-gate-bloquant: true
---
Corps simple sans motif du vocabulaire.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T24_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "ecart" && echo "$OUT" | grep -q "vf-gate-bloquant: true declare sans motif"; then
  ok "T24 vf-gate-bloquant: true sans aucun motif -> rc=0, avertissement « ecart — vf-gate-bloquant: true declare sans motif »"
else
  ko "T24 (rc=$RC) : $OUT"
fi

# ---------- T25 — vf-gate-bloquant: false + titre -> derive (déclaré false) ------------------------
T25_DIR="$WORK/t25"; mkdir -p "$T25_DIR"
cat > "$T25_DIR/SKILL.md" <<'EOF'
---
name: t25-declare-false
description: Fixture T25, vf-gate-bloquant false + titre a marqueur.
vf-gate-bloquant: false
---
### Verdict bloquant

Corps du skill.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T25_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "derive"; then
  ok "T25 vf-gate-bloquant: false + titre « Verdict bloquant » -> rc=0, avertissement « derive » (déclaré false)"
else
  ko "T25 (rc=$RC) : $OUT"
fi

# ---------- T26a — mots du vocabulaire hors portée (description: + bloc de code) -> aucun avert. ---
T26A_DIR="$WORK/t26a"; mkdir -p "$T26A_DIR"
cat > "$T26A_DIR/SKILL.md" <<'EOF'
---
name: t26a-hors-portee
description: Fixture T26a, le mot gate figure ici dans description mais est hors portee.
---
Corps du skill.

```
## Gate en bloc de code, jamais lu
```
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26A_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T26a mot du vocabulaire dans description: et dans un titre en bloc de code délimité -> aucun avertissement"
else
  ko "T26a (rc=$RC) : $OUT"
fi

# ---------- T26b — un seul marqueur en prose (règle Q-PORTEE) -> aucun avertissement ---------------
T26B_DIR="$WORK/t26b"; mkdir -p "$T26B_DIR"
cat > "$T26B_DIR/SKILL.md" <<'EOF'
---
name: t26b-un-marqueur-prose
description: Fixture T26b, un seul marqueur en prose, regle Q-PORTEE.
---
Ce skill passe un gate avant envoi.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26B_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T26b un seul marqueur en prose (« Ce skill passe un gate avant envoi ») -> rc=0, AUCUN avertissement"
else
  ko "T26b (rc=$RC) : $OUT"
fi

# ---------- T26c — deux marqueurs DISTINCTS en prose -> deux avertissements « derive » -------------
T26C_DIR="$WORK/t26c"; mkdir -p "$T26C_DIR"
cat > "$T26C_DIR/SKILL.md" <<'EOF'
---
name: t26c-deux-marqueurs-prose
description: Fixture T26c, deux marqueurs distincts en prose, regle Q-PORTEE.
---
Ce skill passe un gate avant envoi.
Le livrable est remis au client.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26C_DIR" 2>&1)"; RC=$?
N_DERIVE="$(echo "$OUT" | grep -c "derive")"
if [ "$RC" -eq 0 ] && [ "$N_DERIVE" -eq 2 ] && echo "$OUT" | grep -q "vf-gate-bloquant" && echo "$OUT" | grep -q "vf-livrable-tiers"; then
  ok "T26c deux marqueurs distincts en prose -> rc=0, deux avertissements « derive » (vf-gate-bloquant, vf-livrable-tiers)"
else
  ko "T26c (rc=$RC, n_derive=$N_DERIVE) : $OUT"
fi

# ---------- T26d — un marqueur en TITRE (jumeau de T26b) -> un avertissement « derive » ------------
T26D_DIR="$WORK/t26d"; mkdir -p "$T26D_DIR"
cat > "$T26D_DIR/SKILL.md" <<'EOF'
---
name: t26d-un-marqueur-titre
description: Fixture T26d, un marqueur en titre, jumeau de T26b.
---
## Passage du gate avant envoi

Corps sans autre ligne a marqueur.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26D_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "derive" && echo "$OUT" | grep -q "vf-gate-bloquant"; then
  ok "T26d un marqueur en titre (« Passage du gate avant envoi ») -> rc=0, un avertissement « derive » nommant vf-gate-bloquant"
else
  ko "T26d (rc=$RC) : $OUT"
fi

# ---------- T26e — deux occurrences du MÊME marqueur en prose -> aucun avertissement ----------------
T26E_DIR="$WORK/t26e"; mkdir -p "$T26E_DIR"
cat > "$T26E_DIR/SKILL.md" <<'EOF'
---
name: t26e-meme-marqueur-repete
description: Fixture T26e, deux occurrences du meme marqueur en prose.
---
Ce skill passe un gate avant envoi.
Le gate reste bloquant.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26E_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T26e deux occurrences du même marqueur en prose -> rc=0, AUCUN avertissement (un seul marqueur distinct)"
else
  ko "T26e (rc=$RC) : $OUT"
fi

# ---------- T26f — marqueurs dans des blocs de code délimités -> jamais détectés ni comptés ---------
T26F_DIR="$WORK/t26f"; mkdir -p "$T26F_DIR"
cat > "$T26F_DIR/SKILL.md" <<'EOF'
---
name: t26f-blocs-delimites
description: Fixture T26f, marqueurs dans des blocs de code delimites, jamais comptes.
---
Ce skill passe un gate avant envoi.

```
Le livrable est remis au client.
## Checklist qualite
```

~~~
couche de jugement
~~~
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26F_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T26f marqueurs dans des blocs délimités (accents graves et tildes) -> rc=0, AUCUN avertissement (comptés, deux marqueurs distincts porteraient la prose au seuil)"
else
  ko "T26f (rc=$RC) : $OUT"
fi

# ---------- T26g — sens frontmatter -> corps, un mot isolé en prose n'est pas un motif --------------
T26G_DIR="$WORK/t26g"; mkdir -p "$T26G_DIR"
cat > "$T26G_DIR/SKILL.md" <<'EOF'
---
name: t26g-frontmatter-vers-corps
description: Fixture T26g, vf-gate-bloquant declare true, un seul marqueur isole en prose.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: grilles/diagnostic.md
vf-gate-bloquant: true
---
Ce skill passe un gate avant envoi.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26G_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "ecart" && echo "$OUT" | grep -q "vf-gate-bloquant" && ! echo "$OUT" | grep -q "derive"; then
  ok "T26g sens frontmatter -> corps, un mot isolé en prose n'est pas un motif -> rc=0, « ecart » nommant vf-gate-bloquant, aucune « derive »"
else
  ko "T26g (rc=$RC) : $OUT"
fi

# ---------- T26h — sens frontmatter -> corps, deux marqueurs distincts en prose, tous deux déclarés -
T26H_DIR="$WORK/t26h"; mkdir -p "$T26H_DIR"
cat > "$T26H_DIR/SKILL.md" <<'EOF'
---
name: t26h-frontmatter-vers-corps-deux
description: Fixture T26h, deux marqueurs declares true, deux marqueurs distincts en prose.
vf-nature: procedure
ecrit: clients/x/
vf-rubrique-juge: grilles/diagnostic.md
vf-gate-bloquant: true
vf-livrable-tiers: true
---
Ce skill passe un gate avant envoi.
Le livrable est remis au client.
EOF
OUT="$(bash "$CHECK" --strict --skills-dir="$T26H_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive" && ! echo "$OUT" | grep -q "ecart"; then
  ok "T26h sens frontmatter -> corps, deux marqueurs distincts en prose tous deux déclarés -> rc=0, aucun avertissement « derive » ni « ecart »"
else
  ko "T26h (rc=$RC) : $OUT"
fi

# ---------- T27 — qualificatif de « grille », titres livrable/qualité/jugement ----------------------
T27A_DIR="$WORK/t27a"; mkdir -p "$T27A_DIR"
printf -- '---\nname: t27a-livrable\ndescription: Fixture T27a, titre Livrable remis au client.\n---\n## Livrable remis au client\n\nCorps.\n' > "$T27A_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T27A_DIR" 2>&1)"; RC=$?
T27_OK=1
if [ "$RC" -ne 0 ] || ! echo "$OUT" | grep -q "vf-livrable-tiers"; then T27_OK=0; echo "    [T27a] $OUT"; fi

T27B_DIR="$WORK/t27b"; mkdir -p "$T27B_DIR"
printf -- '---\nname: t27b-checklist\ndescription: Fixture T27b, titre Checklist qualite.\n---\n### Checklist qualite\n\nCorps.\n' > "$T27B_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T27B_DIR" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] || ! echo "$OUT" | grep -q "vf-couche-qualite"; then T27_OK=0; echo "    [T27b] $OUT"; fi

T27C_DIR="$WORK/t27c"; mkdir -p "$T27C_DIR"
printf -- '---\nname: t27c-couche\ndescription: Fixture T27c, titre Couche jugement.\n---\n## Couche jugement\n\nCorps.\n' > "$T27C_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T27C_DIR" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] || ! echo "$OUT" | grep -q "vf-couche-qualite"; then T27_OK=0; echo "    [T27c] $OUT"; fi

T27D_DIR="$WORK/t27d"; mkdir -p "$T27D_DIR"
printf -- '---\nname: t27d-grille\ndescription: Fixture T27d, titre Grille tarifaire, non qualifiee.\n---\n## Grille tarifaire\n\nCorps.\n' > "$T27D_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T27D_DIR" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] || echo "$OUT" | grep -q "derive"; then T27_OK=0; echo "    [T27d] $OUT"; fi

if [ "$T27_OK" -eq 1 ]; then
  ok "T27 titres Livrable/Checklist qualité/Couche jugement -> avertissements nommés ; Grille tarifaire (non qualifiée) -> aucun"
else
  ko "T27 (au moins une des quatre fixtures n'a pas rendu le verdict attendu)"
fi

# ---------- T28 — --strict jamais 1, --hook ligne compacte -----------------------------------------
OUT="$(bash "$CHECK" --strict --skills-dir="$T22_DIR" 2>&1)"; RC=$?
T28_OK=1
[ "$RC" -eq 0 ] || { T28_OK=0; echo "    [T28-strict] rc=$RC"; }
OUT_HOOK="$(bash "$CHECK" --hook --skills-dir="$T22_DIR" 2>&1)"; RC_HOOK=$?
if [ "$RC_HOOK" -ne 0 ] || [ "$(echo "$OUT_HOOK" | wc -l | tr -d ' ')" -ne 1 ] || ! echo "$OUT_HOOK" | grep -q "⚠"; then
  T28_OK=0; echo "    [T28-hook] rc=$RC_HOOK out=[$OUT_HOOK]"
fi
if [ "$T28_OK" -eq 1 ]; then
  ok "T28 fixture T22 sous --strict -> rc=0 (jamais 1) ; sous --hook -> rc=0, une seule ligne compacte « ⚠ »"
else
  ko "T28 (voir détails ci-dessus)"
fi

# ---------- T29 — frontière de mot (HUMAN-GATED) ----------------------------------------------------
T29_DIR="$WORK/t29"; mkdir -p "$T29_DIR"
printf -- '---\nname: t29-human-gated\ndescription: Fixture T29, frontiere de mot, HUMAN-GATED.\n---\n## Deploiement HUMAN-GATED\n\nCorps.\n' > "$T29_DIR/SKILL.md"
OUT="$(bash "$CHECK" --strict --skills-dir="$T29_DIR" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -q "derive"; then
  ok "T29 titre « Déploiement HUMAN-GATED » -> rc=0, aucun avertissement (frontière de mot)"
else
  ko "T29 (rc=$RC) : $OUT"
fi

# ---------- MUT-DR1 — appel detecter_derive neutralisé (pass) --------------------------------------
if make_gate_mutant DR1 "warnings.extend(detecter_derive(" "pass  # MUT-DR1"; then
  M="$MUT_DIR/check-skills.sh"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T22_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T22_DIR" 2>&1)"; RC_ORIG=$?
  N_MUT="$(echo "$OUT_MUT" | grep -c "derive")"
  N_ORIG="$(echo "$OUT_ORIG" | grep -c "derive")"
  if [ "$RC_MUT" -eq 0 ] && [ "$RC_ORIG" -eq 0 ] && [ "$N_ORIG" -ge 1 ] && [ "$N_MUT" -eq 0 ]; then
    okmut DR1 "$N_MUT" 0 "$N_ORIG" ">=1"
  else
    komut DR1 "compte « derive » >=1 sur l'original, 0 sur le mutant (T22)" "n_mut=0, n_orig>=1" "n_mut=$N_MUT, n_orig=$N_ORIG"
  fi
fi

# ---------- MUT-DR2 — warnings.extend(detecter_derive(...)) devient errors.extend(...) -------------
DR2_MOTIF="warnings.extend(detecter_derive("
DR2_LIGNE_ORIG="$(grep -F "$DR2_MOTIF" "$REAL_CHECK" | sed 's/^[[:space:]]*//')"
DR2_REMPLACEMENT="$(printf '%s' "$DR2_LIGNE_ORIG" | sed 's/^warnings/errors/')"
if make_gate_mutant DR2 "$DR2_MOTIF" "$DR2_REMPLACEMENT"; then
  M="$MUT_DIR/check-skills.sh"
  OUT_MUT="$(bash "$M" --strict --skills-dir="$T22_DIR" 2>&1)"; RC_MUT=$?
  OUT_ORIG="$(bash "$CHECK" --strict --skills-dir="$T22_DIR" 2>&1)"; RC_ORIG=$?
  if [ "$RC_ORIG" -eq 0 ] && [ "$RC_MUT" -eq 1 ] \
     && echo "$OUT_ORIG" | grep -qE '^  ⚠ .*derive' \
     && ! echo "$OUT_ORIG" | grep -qE '^  ✗ .*derive' \
     && echo "$OUT_MUT" | grep -qE '^  ✗ .*derive'; then
    okmut DR2 "$RC_MUT" 1 "$RC_ORIG" 0 "derive en avertissement sur l'original, en erreur bloquante sur le mutant"
  else
    komut DR2 "derive en avertissement (⚠) sur l'original, en erreur bloquante (✗) sur le mutant (T22)" "rc_mutant=1, rc_original=0, trace deplacee" "rc_mutant=$RC_MUT, rc_original=$RC_ORIG"
  fi
fi

# ---------- MUT-SYNTAXE (garde du helper) : mutant Python invalide (parenthese non refermee) --------
MUT_SYNTAXE_FILE="$WORK/mut-syntaxe-out.txt"
( make_gate_mutant SYNTAXE "errors.extend(invariant_procedure(rel, fm))" "errors.extend(invariant_procedure(rel, fm"; echo "RC-HELPER=$?" ) > "$MUT_SYNTAXE_FILE" 2>&1
if grep -q "^RC-HELPER=1$" "$MUT_SYNTAXE_FILE" && grep -q "NON TUE" "$MUT_SYNTAXE_FILE"; then
  ok "MUT-SYNTAXE refuse : mutant Python invalide rejete par le helper"
else
  ko "MUT-SYNTAXE : le helper n'a pas refuse le mutant tronque"
fi

# ---------- MUT-REFUS-COMPTE (garde du harnais, I1) : un refus du helper compte KO --------------------
MUT_REFUS_FILE="$WORK/mut-refus-compte-out.txt"
(
  BEFORE=$fail
  make_gate_mutant REFUS "motif-absent-du-fichier-check-skills-XYZZY-jamais-present" "quelquechose"
  RC=$?
  AFTER=$fail
  echo "DELTA-FAIL=$((AFTER - BEFORE))"
  echo "RC-HELPER=$RC"
) > "$MUT_REFUS_FILE" 2>&1
if grep -q "^DELTA-FAIL=1$" "$MUT_REFUS_FILE" && grep -q "^RC-HELPER=1$" "$MUT_REFUS_FILE" && grep -q "NON TUE" "$MUT_REFUS_FILE"; then
  ok "MUT-REFUS-COMPTE : refus du helper compte KO dans le shell appelant"
else
  ko "MUT-REFUS-COMPTE : $(cat "$MUT_REFUS_FILE" | tr '\n' ' ')"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
