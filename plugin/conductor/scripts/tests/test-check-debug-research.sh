#!/usr/bin/env bash
# test-check-debug-research.sh — Suite du gate « recherche documentaire avant debug » (ADR-045).
#
# check-debug-research.sh :
#   T1 — brique debug qui référence doc-research-before-debug → conforme (exit 0)
#   T2 — brique debug qui mentionne context7 → conforme (exit 0)
#   T3 — brique debug sans aucun marqueur recherche doc → exit 1 (erreur bloquante)
#   T4 — brique hors périmètre (pas de signature debug) → ignorée (exit 0)
#   T5 — wrapper mince qui délègue sans marqueur → warning (exit 0), ERREUR en --strict (exit 1)
#   T6 — --hook : exit 0 même non conforme, signalement compact
#   T7 — --file sur une brique conforme réelle (vf-debug) → exit 0
#   T8 — labels désambiguïsés : deux skills SKILL.md distincts identifiés par dossier parent
#   T9 — aucune brique → exit 0 (rien à vérifier)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CHECK="$SCRIPTS_DIR/check-debug-research.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-check-debug-research (gate: $CHECK) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AG="$WORK/agents"; SK="$WORK/skills"
mkdir -p "$AG"

skill() { # $1 = dossier · $2 = description · $3 = corps
  mkdir -p "$SK/$1"
  printf -- '---\nname: %s\ndescription: %s\n---\n%s\n' "$1" "$2" "$3" > "$SK/$1/SKILL.md"
}
run_check() { bash "$CHECK" --agents-dir="$AG" --skills-dir="$SK" "$@"; }
reset_sk() { rm -rf "$SK"; mkdir -p "$SK"; }

# T1 — référence la règle
reset_sk
skill "vf-debug-like" "Débugge un crash, stack trace, ça plante" "Pré-étape : voir doc-research-before-debug."
if run_check >/dev/null 2>&1; then ok "T1 référence doc-research-before-debug → conforme"; else ko "T1 rejeté à tort"; fi

# T2 — mentionne context7
reset_sk
skill "diag" "Diagnostique un bug, erreur" "D'abord context7 (resolve-library-id) puis on investigue."
if run_check >/dev/null 2>&1; then ok "T2 mention context7 → conforme"; else ko "T2 rejeté à tort"; fi

# T3 — aucun marqueur
reset_sk
skill "raw-debug" "Débugge un bug, erreur, crash" "Reproduis, hypothèse, teste, corrige."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "SANS phase recherche documentaire"; then
  ok "T3 brique debug sans recherche doc → erreur bloquante"
else
  ko "T3 (rc=$RC) : $OUT"
fi

# T4 — hors périmètre
reset_sk
skill "marketing-report" "Génère un rapport marketing" "Aucune notion de dépannage ici."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "aucune brique de dépannage"; then
  ok "T4 brique hors périmètre → ignorée"
else
  ko "T4 (rc=$RC) : $OUT"
fi

# T5 — wrapper qui délègue : warning en défaut, erreur en --strict
reset_sk
skill "thin-wrapper" "Diagnostique un problème, ça plante" "Invoque le skill gsd-debug."
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 1 ]; then
  ok "T5 wrapper qui délègue : warning en défaut, ERREUR en --strict"
else
  ko "T5 (défaut=$RC_DEF strict=$RC_STRICT)"
fi

# T6 — hook mode
reset_sk
skill "raw-debug" "Débugge un crash" "Reproduis et corrige."
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "sans recherche documentaire"; then
  ok "T6 --hook : exit 0 + signalement compact"
else
  ko "T6 (rc=$RC) : $OUT"
fi

# T7 — --file sur la brique réelle vf-debug
VF_DEBUG="$SCRIPTS_DIR/../../dev-orchestrator/skills/vf-debug/SKILL.md"
if [ -f "$VF_DEBUG" ]; then
  if bash "$CHECK" --file "$VF_DEBUG" >/dev/null 2>&1; then
    ok "T7 vf-debug réel → conforme (--file)"
  else
    ko "T7 vf-debug réel rejeté"
  fi
else
  ok "T7 vf-debug introuvable dans ce contexte — skip"
fi

# T8 — labels désambiguïsés
reset_sk
skill "alpha-debug" "Débugge un crash" "Reproduis."
skill "beta-debug" "Diagnostique un bug" "Corrige."
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "alpha-debug/SKILL.md" && echo "$OUT" | grep -q "beta-debug/SKILL.md"; then
  ok "T8 labels par dossier parent (deux SKILL.md distingués)"
else
  ko "T8 (rc=$RC) : $OUT"
fi

# T9 — aucune brique
reset_sk
if run_check >/dev/null 2>&1; then ok "T9 aucune brique → exit 0"; else ko "T9 exit non-0 sur répertoire vide"; fi

# ---------- durcissements audit S061 (CND-06) ----------

# T10 — 'crash-free' (KPI mobile) et 'Diagnostique la santé du funnel' ne sont PAS du dépannage
reset_sk
skill "perf-mobile" "Surveille le crash-free rate et les KPI de stabilite de l app" "Rapporte les metriques."
skill "funnel-sante" "Diagnostique la sante du funnel d acquisition et propose des optimisations" "Analyse le funnel."
if run_check >/dev/null 2>&1; then
  ok "T10 crash-free / diagnostic métier → hors périmètre (CND-06)"
else
  ko "T10 faux positif : $(run_check 2>&1 | tail -2)"
fi

# T11 — 'diagnostic' + contexte bug/erreur reste bien capturé
reset_sk
skill "vrai-depannage" "Diagnostique les erreurs de build et remonte la cause racine" "Corrige direct."
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T11 diagnostic + erreur → toujours capturé" || ko "T11 faux négatif (rc=$RC)"

# T12 — dogfood : les briques debug-adjacentes LIVRÉES passent le linter livré
reset_sk
DOGFOOD_FAIL=""
for f in "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-test-runner.md" \
         "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-app-fixer.md" \
         "$SCRIPTS_DIR/../../mobile-test-team/agents/vf-test-orchestrator.md"; do
  [ -f "$f" ] || continue
  bash "$CHECK" --file "$f" >/dev/null 2>&1 || DOGFOOD_FAIL="$DOGFOOD_FAIL $(basename "$f")"
done
[ -z "$DOGFOOD_FAIL" ] && ok "T12 dogfood : briques mobile-test-team conformes au linter livré" || ko "T12 briques livrées flaguées :$DOGFOOD_FAIL"

# T13 — F13 (vacuous green) : --strict sur cible vide → exit 3 (INDÉTERMINÉ, pas un vert)
reset_sk
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "T13 --strict + aucune brique → exit 3 INDÉTERMINÉ (F13)" || ko "T13 cible vide devrait sortir 3, obtenu rc=$RC"

# T14 — F13 : --strict --allow-empty sur cible vide → exit 0 (opt-in explicite)
RC=0; run_check --strict --allow-empty >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T14 --strict --allow-empty + aucune brique → exit 0 (opt-in)" || ko "T14 --allow-empty devrait sortir 0, obtenu rc=$RC"

# ---------- Chemin par DEFAUT du gate (D-24) — jamais exerce jusqu'ici ----------
# Aucun des 14 cas precedents n'invoque check-debug-research.sh SANS --agents-dir/--skills-dir : le
# helper d'invocation partage par tous les cas ci-dessus les injecte systematiquement en dur. Les 3
# cas suivants invoquent bash "$CHECK" DIRECTEMENT, dans un sous-shell deplace vers un repertoire
# factice mktemp -d, sans jamais toucher au cwd de la suite. Mutation tuee : alterer la valeur par
# defaut AGENTS_DIR/SKILLS_DIR dans check-debug-research.sh fait echouer T17 (T15/T16 passeraient
# encore avec un defaut casse).

PWD_BEFORE="$(pwd)"

# T15 — cible absente, mode strict : exit 3 INDETERMINE, jamais un vert (contrat F13 / D-24)
DEFAULT_EMPTY="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY" && bash "$CHECK" --strict 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "INDETERMINE"; then
  ok "T15 chemin par defaut, cible absente, --strict → exit 3 INDÉTERMINÉ, jamais un vert (D-24)"
else
  ko "T15 (rc=$RC) : $OUT"
fi
rm -rf "$DEFAULT_EMPTY"

# T16 — cible absente, mode hook : exit 0, silence TOTAL (pin de l'exemption volontaire)
DEFAULT_EMPTY2="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY2" && bash "$CHECK" --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T16 chemin par defaut, cible absente, --hook → exit 0, silence total (exemption pinnee)"
else
  ko "T16 (rc=$RC) : '$OUT'"
fi
rm -rf "$DEFAULT_EMPTY2"

# T17 — cible PRESENTE au chemin par defaut, cas DISCRIMINANT : seul ce cas prouve que la valeur
# par defaut resout une cible reelle — un SKILL.md de depannage sans marqueur de recherche doc.
DEFAULT_PRESENT="$(mktemp -d)"
mkdir -p "$DEFAULT_PRESENT/.claude/skills/raw-debug-defaut"
printf -- '---\nname: raw-debug-defaut\ndescription: Débugge un crash, stack trace\n---\nReproduis, corrige.\n' > "$DEFAULT_PRESENT/.claude/skills/raw-debug-defaut/SKILL.md"
RC=0; (cd "$DEFAULT_PRESENT" && bash "$CHECK") >/dev/null 2>&1 || RC=$?
if [ "$RC" -eq 1 ]; then
  ok "T17 chemin par defaut, cible presente non conforme, SANS flag → exit 1 (le defaut resout une cible reelle)"
else
  ko "T17 (rc=$RC) — le defaut AGENTS_DIR/SKILLS_DIR ne resout pas la cible reelle"
fi
rm -rf "$DEFAULT_PRESENT"

# T18 — le cwd de la suite est inchange : les 3 deplacements ci-dessus sont confines a des sous-shells
[ "$(pwd)" = "$PWD_BEFORE" ] && ok "T18 cwd de la suite inchange apres les cas chemin par defaut" || ko "T18 cwd altere : $(pwd) != $PWD_BEFORE"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
