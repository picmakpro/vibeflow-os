#!/usr/bin/env bash
# check-registres.sh — Lint machine du format canonique des registres mémoire (ADR-043).
# Détecte ce qui passait silencieusement : registre sans index, index sans colonne #Ligne,
# entrées non indexées, IDs dupliqués, registre canonique manquant après init.
#
# Usage:
#   check-registres.sh                       # lint les registres présents · exit 1 si non conforme
#   check-registres.sh --strict              # GATE init : exige AUSSI l'existence des 5 registres canon
#   check-registres.sh --strict --allow-empty  # Gate C lab frais : AUCUN registre → exit 3 (INDÉTERMINÉ)
#   check-registres.sh --hook                # SessionStart : informatif, sortie compacte, exit 0 toujours
#   check-registres.sh --memory-dir=PATH     # défaut .claude/memory
#
# Checks par registre :
#   C1 — header `## Index` présent (200 premières lignes — CSL-16 : head -40 déclarait
#        à tort « sans index » les registres à gros préambule)
#   C1bis — bloc '## Index' refermé par une ligne '---' (CSL-01 : sans terminateur,
#        reindex --apply refuse la réécriture pour ne pas avaler le body)
#   C2 — tableau d'index avec colonne `#Ligne` (format canonique v2, cf. consolidator/indexation)
#   C3 — cohérence IDs index <-> body (via reindex.sh --audit : 0 orphelin exigé)
#   C4 — aucun ID dupliqué dans le body
#
# Canon : DECISIONS LEARNINGS BLOCKERS JOURNAL EVALS · Legacy lus : ADR BDR ITERATION_LOG
# (en --strict, un legacy présent compte comme substitut de son canon, avec avertissement).
#
# Gouvernance proportionnée (audit 2026-07-25) : en --strict, si le profil du lab est "leger"
# (env VF_LAB_PROFILE, sinon clé "profile" de .planning/config.json), un EVALS.md ABSENT est un
# avertissement — le registre est créé à la première éval réelle, pas à l'init. Tous les autres
# registres canon restent exigés ; profil absent/illisible → comportement historique (EVALS requis).
#
# Codes de sortie : 0 = conforme · 1 = non conforme (ou registre canon manquant en --strict)
#                 · 3 = lab vierge sous --strict --allow-empty (verdict INDÉTERMINÉ ≠ vert, doctrine F13)
#
# --hook (D-06/D-07, Portabilité Windows II) arme la TRADUCTION du code de silence interne (3)
# vers 0 à la frontière du harness, via hook_exit() — SEUL ce code est traduit ; 1 reste inchangé.
# Correctif au passage (30-06) : le chemin `--strict --allow-empty` sur cible vide sortait
# INCONDITIONNELLEMENT en 3 avec un message sur STDOUT, même sous --hook — un vrai défaut de FLUX
# (le même type que celui corrigé au plan 30-04), pas seulement de code : ce chemin n'était encore
# jamais passé par la garde `--hook` du tout. Il l'est désormais.

set -uo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"
STRICT=false
HOOK_MODE=false
ALLOW_EMPTY=false

for arg in "$@"; do
  case "$arg" in
    --strict)        STRICT=true ;;
    --allow-empty)   ALLOW_EMPTY=true ;;
    --hook)          HOOK_MODE=true ;;
    --memory-dir=*)  MEMORY_DIR="${arg#*=}" ;;
    -h|--help)       grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)               echo "[check-registres] arg inconnu : $arg" >&2; exit 1 ;;
  esac
done

REINDEX="$(dirname "$0")/reindex.sh"
PROBLEMS=()
WARNINGS=()

# --- Traduction du silence interne vers le harness (D-06/D-07, uniquement sous --hook) ----------
# hook_exit <code> : sous --hook, le SEUL code de silence interne (3 = lab vierge, INDETERMINE)
# devient 0 à la frontière du harness. 1 n'est jamais traduit. Sans --hook (CLI, suites de tests),
# le code recu ressort inchange. Voir docs/HOOKS-CONTRAT-SORTIE.md §2.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK_MODE" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

# Profil de rigueur du lab : VF_LAB_PROFILE prime, sinon .planning/config.json (clé "profile").
LAB_PROFILE="${VF_LAB_PROFILE:-}"
if [ -z "$LAB_PROFILE" ] && [ -f ".planning/config.json" ]; then
  LAB_PROFILE="$(sed -n 's/.*"profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .planning/config.json 2>/dev/null | head -1)"
fi

id_pattern_for() {
  case "$1" in
    DECISIONS)             echo '(DEC|ADR)-[0-9]+' ;;
    ADR)                   echo '(ADR|DEC)-[0-9]+' ;;
    BDR)                   echo 'BDR-[0-9]+' ;;
    LEARNINGS)             echo 'LRN-[0-9]+' ;;
    BLOCKERS)              echo 'BLK-[0-9]+' ;;
    EVALS)                 echo 'EVAL-[0-9]+' ;;
    JOURNAL|ITERATION_LOG) echo 'Session [0-9]+' ;;
    *)                     echo '[A-Z]+-[0-9]+' ;;
  esac
}

check_register() {
  local name="$1" file="$2"
  local pat; pat="$(id_pattern_for "$name")"

  # C1 — header ## Index (borne 200 — CSL-16 : head -40 était trop court pour les
  # registres à gros préambule, faussement déclarés « sans index »)
  local idx_ln
  idx_ln="$(awk 'NR<=200 && /^## Index/ {print NR; exit}' "$file")"
  if [ -z "$idx_ln" ]; then
    PROBLEMS+=("$name : pas de header '## Index' (format canonique v2 requis)")
    return
  fi

  # C1bis — terminateur '---' après '## Index' (CSL-01) : sans lui, l'awk de
  # réécriture de reindex avalerait tout le body — reindex refuse donc d'appliquer.
  if [ -z "$(awk -v s="$idx_ln" 'NR>s && /^---$/ {print "ok"; exit}' "$file")" ]; then
    PROBLEMS+=("$name : bloc '## Index' sans ligne '---' de fermeture (reindex refusera la réécriture)")
  fi

  # C2 — colonne #Ligne dans le tableau d'index (cherché APRÈS '## Index', borne
  # 200 lignes — CSL-16 : head -60 depuis le début du fichier ratait l'index)
  if ! awk -v s="$idx_ln" 'NR>=s && NR<=s+200 && /^\|/ {c++; if (index($0, "#Ligne")) found=1; if (c>=5) exit} END {exit found ? 0 : 1}' "$file"; then
    PROBLEMS+=("$name : index sans colonne '#Ligne' (lecture ciblée impossible — regénérer : reindex.sh --register=$name --apply)")
  fi

  # C3 — cohérence IDs index <-> body (reindex --audit)
  if [ -f "$REINDEX" ]; then
    local audit orph_idx orph_body
    audit="$(MEMORY_DIR="$MEMORY_DIR" bash "$REINDEX" "--register=$name" --audit 2>/dev/null)" || audit=""
    if [ -n "$audit" ]; then
      orph_idx="$(echo "$audit" | sed -n 's/.*"orphans_index_no_body": \([0-9]*\).*/\1/p' | head -1)"
      orph_body="$(echo "$audit" | sed -n 's/.*"orphans_body_no_index": \([0-9]*\).*/\1/p' | head -1)"
      [ "${orph_idx:-0}" -gt 0 ] 2>/dev/null && PROBLEMS+=("$name : $orph_idx entrée(s) d'index sans body")
      [ "${orph_body:-0}" -gt 0 ] 2>/dev/null && PROBLEMS+=("$name : $orph_body entrée(s) de body non indexée(s) (reindex.sh --register=$name --apply)")
    fi
  fi

  # C4 — IDs dupliqués dans le body
  local dups
  dups="$(grep -oE "^## ($pat)" "$file" 2>/dev/null | sed 's/^## //' | sort | uniq -d | tr '\n' ' ')"
  [ -n "${dups// /}" ] && PROBLEMS+=("$name : ID(s) dupliqué(s) dans le body : $dups")
}

# ---------- Lint des registres présents ----------
ALL_KNOWN="DECISIONS LEARNINGS BLOCKERS JOURNAL EVALS ADR BDR ITERATION_LOG"
found_any=false
for name in $ALL_KNOWN; do
  file="$MEMORY_DIR/$name.md"
  [ -f "$file" ] || continue
  found_any=true
  check_register "$name" "$file"
done

# ---------- Strict : les 5 registres canon doivent exister ----------
# --allow-empty (Gate C lab frais) : AUCUN registre = lab jamais initialisé → verdict
# INDÉTERMINÉ (exit 3), pas une non-conformité. Présence PARTIELLE = vrai lab incomplet → 1.
if [ "$STRICT" = true ] && [ "$ALLOW_EMPTY" = true ] && [ "$found_any" = false ]; then
  [ "$HOOK_MODE" = true ] || echo "[check-registres] ∅ aucun registre dans $MEMORY_DIR — lab vierge, verdict indéterminé (--allow-empty)"
  hook_exit 3
fi
if [ "$STRICT" = true ]; then
  declare_missing() { PROBLEMS+=("registre canon manquant : $MEMORY_DIR/$1.md"); }
  [ -f "$MEMORY_DIR/DECISIONS.md" ] || { { [ -f "$MEMORY_DIR/ADR.md" ] || [ -f "$MEMORY_DIR/BDR.md" ]; } && WARNINGS+=("DECISIONS.md absent — legacy ADR/BDR présent (migration conseillée : /vf-calibrate)") || declare_missing "DECISIONS"; }
  [ -f "$MEMORY_DIR/JOURNAL.md" ]   || { [ -f "$MEMORY_DIR/ITERATION_LOG.md" ] && WARNINGS+=("JOURNAL.md absent — legacy ITERATION_LOG présent (migration conseillée : /vf-calibrate)") || declare_missing "JOURNAL"; }
  for name in LEARNINGS BLOCKERS; do
    [ -f "$MEMORY_DIR/$name.md" ] || declare_missing "$name"
  done
  if [ ! -f "$MEMORY_DIR/EVALS.md" ]; then
    if [ "$LAB_PROFILE" = "leger" ]; then
      WARNINGS+=("EVALS.md absent — profil léger : registre optionnel à l'init, créé à la première éval réelle")
    else
      declare_missing "EVALS"
    fi
  fi
elif [ "$found_any" = false ]; then
  # Hors strict, un lab sans aucun registre n'est pas une erreur (lab non initialisé).
  [ "$HOOK_MODE" = true ] || echo "[check-registres] aucun registre dans $MEMORY_DIR — rien à vérifier"
  exit 0
fi

# ---------- Rapport ----------
n="${#PROBLEMS[@]}"
if [ "$HOOK_MODE" = true ]; then
  # SessionStart : compact, seulement si problème (injecté en contexte de session).
  if [ "$n" -gt 0 ]; then
    echo "[check-registres] ⚠ $n non-conformité(s) registres :"
    for p in "${PROBLEMS[@]}"; do echo "  - $p"; done
    echo "  Corriger : bash .claude/scripts/reindex.sh --all --apply · détail : check-registres.sh"
  fi
  exit 0
fi

for w in "${WARNINGS[@]+"${WARNINGS[@]}"}"; do echo "[check-registres] ⚠ $w"; done
if [ "$n" -gt 0 ]; then
  echo "[check-registres] ✗ $n non-conformité(s) :"
  for p in "${PROBLEMS[@]}"; do echo "  - $p"; done
  exit 1
fi
echo "[check-registres] ✓ registres conformes (format canonique v2)"
exit 0
