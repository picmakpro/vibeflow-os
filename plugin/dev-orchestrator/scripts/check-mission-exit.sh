#!/usr/bin/env bash
# check-mission-exit.sh — Gate de sortie de mission du head (HEAD-02, D-06, D-07, D-10, D-11).
#
# Rôle : ce script CONSTATE l'état de six contrôles (E1 à E6) sur un dépôt de mission et un
# rapport détaillé écrit sur disque — il ne corrige rien, ne rejoue aucun étage, ne juge aucun
# contenu métier. Vérifier le témoin, jamais refaire le travail (D-03) : sur un manque ou une
# indétermination, la conduite (mandat de correction ciblée, escalade humaine) appartient au
# head et vit dans `references/head-governance.md` §3 — elle ne s'écrit jamais ici.
#
# Contrat de sortie — QUATRE codes, précédence explicite 64 > 4 > 0 > 3 :
#
#   3  = SAIN — le SEUL code qui signifie « vérifié, conforme ». Les six contrôles ont été LUS
#        et aucun n'a rendu ni manque ni indétermination. Sortie standard vide.
#   0  = au moins un MANQUE NOMMÉ — une ligne de signal par manque sur la sortie standard, citant
#        le contrôle (E1..E6) et le détail. Rendu même si un AUTRE contrôle est indéterminé : les
#        manques sont TOUS imprimés, rien n'est perdu — mais voir la règle de précédence ci-dessous.
#   4  = INDÉTERMINÉ — au moins un contrôle sans source de vérité (outillage absent, racine hors
#        d'un dépôt git, argument de contexte manquant…), un diagnostic par cause sur la sortie
#        d'erreur. Un exit 4 n'autorise JAMAIS à conclure que la mission est prouvée — même si,
#        par ailleurs, aucun manque n'a été détecté sur les autres contrôles.
#   64 = argument inconnu, valeur manquante, drapeaux mutuellement exclusifs ensemble, ou
#        outillage de base (l'outil de requête JSON) introuvable dans l'environnement.
#
# Précédence (D-06, « le contrôle rend 4 et le verdict global est 4 ») : 64 prime sur 4, qui
# prime sur 0, qui prime sur 3. Un contrôle indéterminé rend le VERDICT GLOBAL indéterminé même
# si d'autres contrôles ont trouvé des manques — ces manques restent imprimés (rien n'est perdu),
# mais aucun consommateur ne doit lire un 4 comme un 0 « propre » ni comme un 3. Jamais un 3 par
# défaut sur un échec inattendu d'un outil : c'est l'anti-pattern que QUAL-01 existe pour fermer.
#
# Usage :
#   check-mission-exit.sh [--root <dir>] [--report <path>] [--step <phase>]... [--hook|--quiet]
# Defaults : --root .   (pas de --report ni --step par défaut : leur absence est INDÉTERMINÉE,
#            jamais un vert — le gate n'a alors aucune source de vérité sur ce qu'il devait lire.)
#
# --hook ne change que le format d'affichage (parité d'interface avec les autres gates du dépôt) ;
# --quiet supprime les diagnostics informatifs sur la sortie d'erreur. Mutuellement exclusifs.
#
# Les six contrôles :
#   E1 — le verrou de driver est relâché (lu via `driver-lock.sh status`, JAMAIS via une
#        sous-commande qui le modifie — D-11 : ce script LIT seulement, il n'invoque jamais un
#        verbe qui libère, reprend ou récupère quoi que ce soit). Même lecture pour le registre
#        des agents dispatchés (issue #82) : un verrou relâché avec `children_running` > 0 est
#        un manque (mission terminée mais pas inerte) ; champ absent = kernel antérieur, le
#        sous-contrôle est dit non applicable sur la sortie d'erreur.
#   E2 — l'arbre de travail est propre (`git status --porcelain` capturé en variable, JAMAIS
#        canalisé dans un compteur de lignes — une sortie vide y devient une ligne sous un hook
#        de proxy de commandes actif, piège déjà tracé de ce dépôt).
#   E3 — une branche dédiée existe et sa PR est ouverte.
#   E4 — la feuille de route et le fichier d'état portent la marque du travail, pour chaque
#        étape déclarée en argument.
#   E5 — le rapport détaillé de mission est présent et lisible sur disque.
#   E6 — chaque verdict du rapport porte sa preuve (contrat `references/mission-contracts.md`
#        §Contrat de preuves E6, section `## Preuves E6` du rapport, un bloc ```json).
#
# Résolution des scripts frères ($S) : cascade de `references/mission-flow.md` (§Résolution des
# scripts), sentinelle testée `dag.sh` — PAS `driver-lock.sh`, qui est cherché SEULEMENT une fois
# le dossier $S résolu, à une étape distincte. Divergence assumée et documentée en commentaire à
# l'endroit de la résolution : le premier candidat est relatif à --root, pas au répertoire courant
# du process — sans cette adaptation ce gate ne serait jamais testable sur une fixture jetable.
#
# Marqueurs `# >>> Ex` / `# <<< Ex` : chaque contrôle est entouré d'une paire de lignes de
# commentaire dédiées à l'outillage de test (suppression chirurgicale d'un bloc à la fois, sans
# rôle fonctionnel pour ce script). Les six contrôles sont INDÉPENDANTS — la suppression du bloc
# d'un contrôle ne fait planter ni n'altère les cinq autres ; un contrôle dont le bloc est absent
# contribue silencieusement « sain » à l'agrégation (chaque variable d'état est initialisée à
# « sain » avant les six blocs, précisément pour que cette suppression reste sans danger).
#
# Lecture seule intégrale (D-10) : aucune écriture, aucune modification du dépôt inspecté, aucune
# sous-commande d'écriture d'aucun outil invoqué. D-18 : shell portable, aucune dépendance externe
# neuve — interpréteur, outil de requête JSON, git et client GitHub sont déjà des prérequis de ce
# dépôt.
set -uo pipefail

ROOT="."
REPORT=""
STEPS=""
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-exit] --root nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --report)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-exit] --report nécessite une valeur" >&2
        exit 64
      fi
      REPORT="$2"; shift 2 ;;
    --step)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-exit] --step nécessite une valeur" >&2
        exit 64
      fi
      STEPS="${STEPS}${2}"$'\n'; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-mission-exit] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique.
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-mission-exit] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-mission-exit] $*" >&2; }

# --- Outillage de base : sans l'outil de requête JSON, rien de ce gate n'est fiable (D-18) -------
if ! command -v jq >/dev/null 2>&1; then
  echo "[check-mission-exit] outil de requête JSON (jq) introuvable — outillage illisible" >&2
  exit 64
fi

# --- Durcissement git (même wrapper unique que check-mission-invariants.sh) -----------------------
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}

# --- Résolution des scripts frères ($S) — cascade de mission-flow.md, sentinelle dag.sh -----------
# Divergence assumée (40-04) : le PREMIER candidat est résolu RELATIVEMENT À --root, pas au
# répertoire courant du process — sans cette adaptation le gate mesurerait le lab de l'appelant au
# lieu de celui qu'on lui désigne, et ne serait jamais testable sur une fixture jetable. Les
# candidats suivants (scope utilisateur, puis les deux dossiers de scripts du plugin) restent
# inchangés ; le lab local prime toujours.
resolve_S() {
  local candidate
  for candidate in "$ROOT/.claude/scripts" "$HOME/.claude/scripts" \
                   "${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts" \
                   "${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts"; do
    [ -n "$candidate" ] && [ -f "$candidate/dag.sh" ] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

# --- États initiaux des six contrôles, HORS des marqueurs ------------------------------------------
# Initialisés à "sain" pour que la suppression chirurgicale d'un bloc (outillage de test, tâche 2)
# ne fasse jamais planter ce script sous `set -u` et retombe silencieusement sur "sain" — c'est la
# propriété d'isolation exigée par l'action de la tâche 1, jamais un chemin de production.
E1_STATUS="sain"; E1_MSG=""
E2_STATUS="sain"; E2_MSG=""
E3_STATUS="sain"; E3_MSG=""
E4_STATUS="sain"; E4_MSG=""
E5_STATUS="sain"; E5_MSG=""
E6_STATUS="sain"; E6_MSG=""

# >>> E1
# E1 — verrou de driver relâché. Lecture SEULE (D-11) : ce script n'invoque que le sous-verbe qui
# rend l'état courant, jamais un verbe qui modifierait le verrou.
E1_S_DIR="$(resolve_S || true)"
if [ -z "$E1_S_DIR" ]; then
  E1_STATUS="indet"
  E1_MSG="[E1] cascade non résolue : aucun candidat ne porte dag.sh"
elif [ ! -x "$E1_S_DIR/driver-lock.sh" ] && [ ! -f "$E1_S_DIR/driver-lock.sh" ]; then
  E1_STATUS="indet"
  E1_MSG="[E1] \$S résolu, driver-lock.sh absent (dossier : $E1_S_DIR)"
else
  E1_OUT="$(VF_DRIVER_LOCK="$ROOT/.planning/DRIVER.lock" "$E1_S_DIR/driver-lock.sh" status 2>/dev/null)"
  E1_RC=$?
  if [ "$E1_RC" -ne 0 ]; then
    E1_STATUS="indet"
    E1_MSG="[E1] driver-lock.sh status a rendu un code non nul ($E1_RC)"
  else
    E1_PRESENT="$(printf '%s' "$E1_OUT" | jq -r 'if has("present") then (.present | tostring) else "" end' 2>/dev/null)"
    # Registre des agents dispatchés (issue #82) : `status` porte `children_running` depuis
    # conductor v1.39.0, le nombre d'agents consignés encore `running`. Un manager qui a rendu
    # son rapport en laissant un enfant consigné ouvert est le cas « terminé mais pas inerte »
    # de l'issue : lu ici, jamais via le verbe `orphans` (D-11, un seul verbe, en lecture seule).
    # Champ absent (kernel antérieur) → sous-contrôle non applicable, dit sur la sortie
    # d'erreur, jamais un vert sur un manque non lu ; valeur non numérique → indéterminé.
    E1_CHILDREN="$(printf '%s' "$E1_OUT" | jq -r 'if has("children_running") then (.children_running | tostring) else "" end' 2>/dev/null)"
    case "$E1_CHILDREN" in
      "") say "[E1] registre des agents non exposé par driver-lock.sh status (kernel antérieur) : sous-contrôle des enfants non applicable" ;;
      *[!0-9]*) E1_STATUS="indet"; E1_MSG="[E1] champ children_running non numérique ($E1_CHILDREN)" ;;
    esac
    case "$E1_PRESENT" in
      "")
        E1_STATUS="indet"
        E1_MSG="[E1] JSON de driver-lock.sh status dépourvu du champ present"
        ;;
      false)
        if [ "$E1_STATUS" = "sain" ] && [ -n "$E1_CHILDREN" ] && [ "$E1_CHILDREN" -gt 0 ]; then
          E1_STATUS="manque"
          E1_MSG="[E1] verrou relâché mais $E1_CHILDREN agent(s) consigné(s) encore running dans le registre (driver-lock.sh orphans) : mission terminée, pas inerte"
        fi
        ;;
      true)
        E1_OWNER="$(printf '%s' "$E1_OUT" | jq -r '.owner // "?"' 2>/dev/null)"
        E1_STEP="$(printf '%s' "$E1_OUT" | jq -r '.step // "?"' 2>/dev/null)"
        E1_STATUS="manque"
        E1_MSG="[E1] verrou de driver présent — owner=$E1_OWNER step=$E1_STEP"
        if [ -n "$E1_CHILDREN" ] && [ "$E1_CHILDREN" -gt 0 ] 2>/dev/null; then
          E1_MSG="$E1_MSG children_running=$E1_CHILDREN"
        fi
        ;;
      *)
        E1_STATUS="indet"
        E1_MSG="[E1] champ present ni true ni false ($E1_PRESENT)"
        ;;
    esac
  fi
fi
# <<< E1

# >>> E2
# E2 — arbre de travail propre. Capture en variable, JAMAIS canalisée dans un compteur de lignes
# (piège déjà tracé de ce dépôt : sous un hook de proxy de commandes actif, une sortie vide devient
# une ligne et le compte ment).
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  E2_STATUS="indet"
  E2_MSG="[E2] $ROOT hors d'un arbre de travail git"
else
  E2_PORCELAIN="$(git_safe status --porcelain)"
  if [ -n "$E2_PORCELAIN" ]; then
    E2_STATUS="manque"
    E2_FIRST5="$(printf '%s\n' "$E2_PORCELAIN" | head -5 | tr '\n' ' ')"
    E2_MSG="[E2] arbre de travail non propre : $E2_FIRST5"
  fi
fi
# <<< E2

# >>> E3
# E3 — branche dédiée et PR ouverte.
E3_CURRENT="$(git_safe symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [ -z "$E3_CURRENT" ]; then
  E3_STATUS="indet"
  E3_MSG="[E3] tête détachée : impossible de déterminer la branche courante"
else
  E3_DEFAULT="$(git_safe symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  if [ -z "$E3_DEFAULT" ]; then
    for E3_CAND in main master; do
      if git_safe show-ref --verify --quiet "refs/heads/$E3_CAND"; then E3_DEFAULT="$E3_CAND"; break; fi
    done
  fi
  if [ -z "$E3_DEFAULT" ]; then
    E3_STATUS="indet"
    E3_MSG="[E3] branche par défaut non résolue (ni tête symbolique distante, ni main/master local)"
  elif [ "$E3_CURRENT" = "$E3_DEFAULT" ]; then
    E3_STATUS="manque"
    E3_MSG="[E3] branche courante ($E3_CURRENT) égale à la branche par défaut — aucune branche dédiée"
  else
    if ! command -v gh >/dev/null 2>&1; then
      E3_STATUS="indet"
      E3_MSG="[E3] client GitHub (gh) absent de l'environnement — état de la PR invérifiable"
    elif [ -z "$(git_safe remote)" ]; then
      E3_STATUS="indet"
      E3_MSG="[E3] dépôt sans distant — état de la PR invérifiable"
    elif ! gh auth status >/dev/null 2>&1; then
      E3_STATUS="indet"
      E3_MSG="[E3] client GitHub non authentifié — état de la PR invérifiable"
    else
      E3_PR_JSON="$(cd "$ROOT" && gh pr view --json state 2>/dev/null)"
      E3_PR_RC=$?
      E3_PR_STATE="$(printf '%s' "$E3_PR_JSON" | jq -r '.state // empty' 2>/dev/null)"
      if [ "$E3_PR_RC" -ne 0 ] || [ -z "$E3_PR_STATE" ]; then
        E3_STATUS="indet"
        E3_MSG="[E3] aucune PR lisible pour la branche courante ($E3_CURRENT)"
      elif [ "$E3_PR_STATE" = "OPEN" ]; then
        E3_STATUS="sain"
      else
        E3_STATUS="manque"
        E3_MSG="[E3] PR de la branche courante en état $E3_PR_STATE (attendu OPEN)"
      fi
    fi
  fi
fi
# <<< E3

# >>> E4
# E4 — feuille de route et état marqués pour chaque étape déclarée en argument.
if [ -z "$STEPS" ]; then
  E4_STATUS="indet"
  E4_MSG="[E4] aucune étape déclarée en argument — rien à vérifier"
else
  E4_ROADMAP="$ROOT/.planning/ROADMAP.md"
  if [ ! -r "$E4_ROADMAP" ]; then
    E4_STATUS="indet"
    E4_MSG="[E4] feuille de route absente : $E4_ROADMAP"
  else
    E4_LINES=""
    while IFS= read -r E4_STEP; do
      [ -n "$E4_STEP" ] || continue
      E4_SECTION="$(awk -v step="$E4_STEP" '
        $0 ~ ("^### Phase " step ":") { inside=1; next }
        inside && /^### / { exit }
        inside { print }
      ' "$E4_ROADMAP")"
      if [ -z "$E4_SECTION" ]; then
        E4_LINES="${E4_LINES}[E4] section introuvable pour l'étape ${E4_STEP}"$'\n'
        continue
      fi
      E4_UNCHECKED="$(printf '%s\n' "$E4_SECTION" | grep -cE '^[[:space:]]*- \[ \]')"
      case "$E4_UNCHECKED" in ''|*[!0-9]*) E4_UNCHECKED=0 ;; esac
      if [ "$E4_UNCHECKED" -gt 0 ]; then
        E4_LINES="${E4_LINES}[E4] étape ${E4_STEP} : ${E4_UNCHECKED} case(s) de plan non cochée(s)"$'\n'
      fi
    done <<EOF
$STEPS
EOF
    E4_STATE="$ROOT/.planning/STATE.md"
    if [ ! -r "$E4_STATE" ]; then
      E4_LINES="${E4_LINES}[E4] fichier d'état absent : ${E4_STATE}"$'\n'
    else
      E4_SA_LINE="$(grep -n '^stopped_at:' "$E4_STATE" | head -1)"
      E4_SA_EMPTY=1
      if [ -n "$E4_SA_LINE" ]; then
        E4_SA_NO="${E4_SA_LINE%%:*}"
        E4_SA_VAL="$(sed -n "${E4_SA_NO}p" "$E4_STATE" | sed 's/^stopped_at:[[:space:]]*//')"
        case "$E4_SA_VAL" in
          ''|'>-'|'|'|'|-')
            E4_SA_NEXT_NO=$((E4_SA_NO + 1))
            E4_SA_NEXT="$(sed -n "${E4_SA_NEXT_NO}p" "$E4_STATE" | sed 's/^[[:space:]]*//')"
            [ -n "$E4_SA_NEXT" ] && E4_SA_EMPTY=0
            ;;
          *) E4_SA_EMPTY=0 ;;
        esac
      fi
      if [ "$E4_SA_EMPTY" -eq 1 ]; then
        E4_LINES="${E4_LINES}[E4] clé de dernier arrêt absente ou vide dans ${E4_STATE}"$'\n'
      fi
    fi
    if [ -n "$E4_LINES" ]; then
      E4_STATUS="manque"
      E4_MSG="$E4_LINES"
    fi
  fi
fi
# <<< E4

# >>> E5
# E5 — rapport détaillé présent sur disque.
if [ -z "$REPORT" ]; then
  E5_STATUS="indet"
  E5_MSG="[E5] aucun chemin de rapport déclaré en argument"
else
  case "$REPORT" in
    /*) E5_PATH="$REPORT" ;;
    *)  E5_PATH="$ROOT/$REPORT" ;;
  esac
  if [ ! -r "$E5_PATH" ] || [ ! -s "$E5_PATH" ]; then
    E5_STATUS="manque"
    E5_MSG="[E5] rapport détaillé illisible ou vide : $E5_PATH"
  fi
fi
# <<< E5

# >>> E6
# E6 — chaque verdict du rapport porte sa preuve (mission-contracts.md §Contrat de preuves E6).
# Résolution du chemin de rapport DUPLIQUÉE (et non partagée avec E5) : les six contrôles sont
# indépendants, la suppression du bloc E5 ne doit jamais priver E6 de sa propre résolution.
if [ -z "$REPORT" ]; then
  E6_STATUS="indet"
  E6_MSG="[E6] aucun chemin de rapport déclaré en argument"
else
  case "$REPORT" in
    /*) E6_PATH="$REPORT" ;;
    *)  E6_PATH="$ROOT/$REPORT" ;;
  esac
  if [ ! -r "$E6_PATH" ]; then
    E6_STATUS="indet"
    E6_MSG="[E6] rapport illisible : $E6_PATH"
  else
    E6_SECTION="$(awk '
      /^## Preuves E6/ { n=1; next }
      n==1 && /^## / { exit }
      n==1 { print }
    ' "$E6_PATH")"
    if [ -z "$E6_SECTION" ]; then
      E6_STATUS="indet"
      E6_MSG="[E6] section « ## Preuves E6 » absente du rapport"
    else
      E6_JSON="$(printf '%s\n' "$E6_SECTION" | awk '
        /^```json/ { capture=1; next }
        capture && /^```/ { exit }
        capture { print }
      ')"
      if [ -z "$E6_JSON" ]; then
        E6_STATUS="indet"
        E6_MSG="[E6] aucun bloc json clôturé trouvé dans la section Preuves E6"
      elif ! printf '%s' "$E6_JSON" | jq -e . >/dev/null 2>&1; then
        E6_STATUS="indet"
        E6_MSG="[E6] bloc JSON illisible dans la section Preuves E6"
      else
        E6_HAS_KEY="$(printf '%s' "$E6_JSON" | jq -r 'if has("preuves") then "true" else "false" end' 2>/dev/null)"
        if [ "$E6_HAS_KEY" != "true" ]; then
          E6_STATUS="indet"
          E6_MSG="[E6] racine du JSON sans clé preuves"
        else
          E6_IS_ARRAY="$(printf '%s' "$E6_JSON" | jq -r 'if (.preuves | type) == "array" then "true" else "false" end' 2>/dev/null)"
          if [ "$E6_IS_ARRAY" != "true" ]; then
            E6_STATUS="indet"
            E6_MSG="[E6] clé preuves n'est pas un tableau"
          else
            E6_LEN="$(printf '%s' "$E6_JSON" | jq -r '.preuves | length' 2>/dev/null)"
            case "$E6_LEN" in ''|*[!0-9]*) E6_LEN=0 ;; esac
            if [ "$E6_LEN" -eq 0 ]; then
              E6_STATUS="indet"
              E6_MSG="[E6] tableau de preuves VIDE — un tableau vide n'est jamais un vert"
            else
              E6_BAD=""
              E6_IDX=0
              while [ "$E6_IDX" -lt "$E6_LEN" ]; do
                E6_ITEM="$(printf '%s' "$E6_JSON" | jq -c ".preuves[$E6_IDX]" 2>/dev/null)"
                E6_VERDICT="$(printf '%s' "$E6_ITEM" | jq -r '.verdict // empty' 2>/dev/null)"
                E6_PREUVE="$(printf '%s' "$E6_ITEM" | jq -r '.preuve // empty' 2>/dev/null)"
                E6_CMD="$(printf '%s' "$E6_ITEM" | jq -r '.commande // empty' 2>/dev/null)"
                E6_EC="$(printf '%s' "$E6_ITEM" | jq -r 'if (.exit_code | type) == "number" then "num" else "" end' 2>/dev/null)"
                E6_SHA="$(printf '%s' "$E6_ITEM" | jq -r '.sha // empty' 2>/dev/null)"
                E6_OK=0
                if [ -n "$E6_VERDICT" ]; then
                  if [ "$E6_PREUVE" = "amont" ]; then
                    E6_OK=1
                  elif [ -n "$E6_CMD" ] && [ "$E6_EC" = "num" ] && [ -n "$E6_SHA" ]; then
                    E6_OK=1
                  fi
                fi
                if [ "$E6_OK" -eq 0 ]; then
                  if [ -n "$E6_VERDICT" ]; then
                    E6_BAD="${E6_BAD}[E6] preuve non conforme pour le verdict « $E6_VERDICT »"$'\n'
                  else
                    E6_BAD="${E6_BAD}[E6] preuve non conforme à l'index $E6_IDX (verdict manquant)"$'\n'
                  fi
                fi
                E6_IDX=$((E6_IDX + 1))
              done
              if [ -n "$E6_BAD" ]; then
                E6_STATUS="manque"
                E6_MSG="$E6_BAD"
              fi
            fi
          fi
        fi
      fi
    fi
  fi
fi
# <<< E6

# --- Agrégation finale — précédence 64 > 4 > 0 > 3 (D-06) -----------------------------------------
HAS_INDET=0
HAS_MANQUE=0
for id in E1 E2 E3 E4 E5 E6; do
  svar="${id}_STATUS"
  mvar="${id}_MSG"
  s="${!svar}"
  m="${!mvar}"
  case "$s" in
    indet)
      HAS_INDET=1
      [ -n "$m" ] && printf '%s\n' "$m" >&2
      ;;
    manque)
      HAS_MANQUE=1
      [ -n "$m" ] && printf '%s\n' "$m"
      ;;
  esac
done

if [ "$HAS_INDET" -eq 1 ]; then
  say "verdict global INDÉTERMINÉ — au moins un contrôle sans source de vérité (voir ci-dessus)."
  exit 4
fi

if [ "$HAS_MANQUE" -eq 1 ]; then
  exit 0
fi

say "SAIN — les six contrôles E1 à E6 ont été vérifiés et sont conformes."
exit 3
