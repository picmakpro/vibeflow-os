#!/usr/bin/env bash
# check-mission-exit.sh — Gate de sortie de mission du head (HEAD-02, D-06, D-07, D-10, D-11).
#
# Rôle : ce script CONSTATE l'état de sept contrôles (E1 à E7) sur un dépôt de mission et un
# rapport détaillé écrit sur disque — il ne corrige rien, ne rejoue aucun étage, ne juge aucun
# contenu métier. Vérifier le témoin, jamais refaire le travail (D-03) : sur un manque ou une
# indétermination, la conduite (mandat de correction ciblée, escalade humaine) appartient au
# head et vit dans `references/head-governance.md` §3 — elle ne s'écrit jamais ici.
#
# Contrat de sortie — QUATRE codes, précédence explicite 64 > 4 > 0 > 3 :
#
#   3  = SAIN — le SEUL code qui signifie « vérifié, conforme ». Les sept contrôles ont été LUS
#        et aucun n'a rendu ni manque ni indétermination. Sortie standard vide.
#   0  = au moins un MANQUE NOMMÉ — une ligne de signal par manque sur la sortie standard, citant
#        le contrôle (E1 à E7) et le détail. Rendu même si un AUTRE contrôle est indéterminé : les
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
#   check-mission-exit.sh --budget-snapshot [--root <dir>]   # DÉBUT de mission, une fois (voir E7)
# Defaults : --root .   (pas de --report ni --step par défaut : leur absence est INDÉTERMINÉE,
#            jamais un vert — le gate n'a alors aucune source de vérité sur ce qu'il devait lire.)
#
# --hook ne change que le format d'affichage (parité d'interface avec les autres gates du dépôt) ;
# --quiet supprime les diagnostics informatifs sur la sortie d'erreur. Mutuellement exclusifs.
#
# Les sept contrôles :
#   E1 — le verrou de driver est relâché (lu via `driver-lock.sh status`, JAMAIS via une
#        sous-commande qui le modifie — D-11 : ce script LIT seulement, il n'invoque jamais un
#        verbe qui libère, reprend ou récupère quoi que ce soit). Même lecture pour le registre
#        des agents dispatchés (issue #82) : un verrou relâché avec `children_running` > 0 est
#        un manque (mission terminée mais pas inerte) ; champ absent = kernel antérieur, le
#        sous-contrôle est dit non applicable sur la sortie d'erreur.
#   E2 — l'arbre de travail est propre (`git status --porcelain` capturé en variable, JAMAIS
#        canalisé dans un compteur de lignes — une sortie vide y devient une ligne sous un hook
#        de proxy de commandes actif, piège déjà tracé de ce dépôt).
#   E3 — une branche dédiée existe, sa PR est ouverte et son corps porte un merge-danger call
#        conforme (POCK-06 : section « ## Merge-danger call », ligne « Porte : sens unique|double
#        sens », ligne « Rayon d'explosion : » d'au moins 10 caractères — forme au contrat
#        `references/mission-contracts.md` §Isolation de branche). Corps absent ou non chaîne :
#        INDÉTERMINÉ ; section absente ou incomplète : MANQUE nommé. Le corps de PR est une donnée
#        NON FIABLE : extrait par jq, analysé par awk sur stdin, comparé à une énumération fermée,
#        messages fixes — aucune interpolation, aucune évaluation dynamique de chaîne, aucun écho.
#   E4 — la feuille de route et le fichier d'état portent la marque du travail, pour chaque
#        étape déclarée en argument.
#   E5 — le rapport détaillé de mission est présent et lisible sur disque.
#   E6 — chaque verdict du rapport porte sa preuve (contrat `references/mission-contracts.md`
#        §Contrat de preuves E6, section `## Preuves E6` du rapport, un bloc ```json).
#   E7 — rien de rangeable n'est laissé PAR LA MISSION (SOBR-07, ADR-076). Sémantique DELTA : la référence est
#        le snapshot de DÉBUT de mission, posé par le manager juste après l'`acquire` du verrou de driver avec
#        `check-mission-exit.sh --budget-snapshot` (mission-flow.md §Budgets de méthode) ; il vit sous le
#        répertoire git commun (`<git-common-dir>/vf-mission-budget.snap`), jamais dans l'arbre (E2 reste
#        propre) ; il porte la DATE de sa pose et l'IDENTITÉ de la mission (nom de la génération du verrou de
#        driver courant) ; pris par `check-method-budget.sh --auto --dry-run` (même décision que E7, rien d'écrit :
#        un ARCHIVAGE REFUSÉ déjà là n'est pas imputé à la mission). Génération du snapshot ≠ verrou courant :
#        INDÉTERMINÉ ; snapshot sans identité (version antérieure) : INDÉTERMINÉ. LIMITES dites : verrou relâché
#        (cas ordinaire à la sortie), l'identité n'est plus recontrôlable, seule la date située (dite sur stderr)
#        la replace ; un snapshot posé TARD masque ce que la mission avait déjà créé avant lui. Sont des manques E7 les lignes RANGEABLE / ARCHIVABLE / ARCHIVAGE REFUSÉ APPARUES depuis ce
#        snapshot (`check-method-budget.sh --auto --no-remote --strict` a d'abord archivé SANS geste humain ce
#        qu'un budget dépassé désigne : déplacement tracé, réversible, jamais de commit ; « archivé, à
#        commiter » tant que l'arbre porte l'archivage). Ce qui existait au démarrage (branche d'un autre
#        mainteneur, worktree d'une autre mission) n'est jamais imputé à la mission. Snapshot absent,
#        ARCHIVAGE NON TENTÉ (dépôt partitionné, aucun compartiment résolu), script de budget introuvable
#        ou rc 2 : INDÉTERMINÉ, jamais sain. Un DÉPASSÉ seul est un constat, pas un manque du geste. Les
#        jetons de remote (À VALIDER) ne sont pas lus : le contrôle passe --no-remote, ils n'y arrivent pas.
#
# Résolution des scripts frères ($S) : cascade de `references/mission-flow.md` (§Résolution des
# scripts), sentinelle testée `dag.sh` — PAS `driver-lock.sh`, qui est cherché SEULEMENT une fois
# le dossier $S résolu, à une étape distincte. Divergence assumée et documentée en commentaire à
# l'endroit de la résolution : le premier candidat est relatif à --root, pas au répertoire courant
# du process — sans cette adaptation ce gate ne serait jamais testable sur une fixture jetable.
#
# Marqueurs `# >>> Ex` / `# <<< Ex` : chaque contrôle est entouré d'une paire de lignes de
# commentaire dédiées à l'outillage de test (suppression chirurgicale d'un bloc à la fois, sans
# rôle fonctionnel pour ce script). Les sept contrôles sont INDÉPENDANTS — la suppression du bloc
# d'un contrôle ne fait planter ni n'altère les six autres ; un contrôle dont le bloc est absent
# contribue silencieusement « sain » à l'agrégation (chaque variable d'état est initialisée à
# « sain » avant les six blocs, précisément pour que cette suppression reste sans danger).
#
# Lecture seule (D-10), à UNE exception nommée : E7 est le SEUL écrivain du gate, par le seul
# déplacement d'archive borné de `check-method-budget.sh --auto` (sources commitées, compartiment de la
# session, jamais de commit) ; les six autres contrôles ne modifient rien, aucune sous-commande d'écriture d'un autre
# outil n'est invoquée ; le mode `--budget-snapshot` (un autre appel, en début de mission) n'écrit qu'un fichier sous le répertoire git commun. E2 tourne avant E7 : l'arbre qu'E2 a jugé propre est celui d'avant l'archivage. D-18 : shell portable, aucune dépendance externe
# neuve — interpréteur, outil de requête JSON, git et client GitHub sont déjà des prérequis de ce
# dépôt.
set -uo pipefail

ROOT="."
REPORT=""
STEPS=""
HOOK=0
QUIET=0
BUDGET_SNAPSHOT=0

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
    --budget-snapshot) BUDGET_SNAPSHOT=1; shift ;;
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

# --- Script de budget et snapshot de début de mission (E7) — HORS des marqueurs ---------------------
# Script frère (lab installé, scripts à plat), sinon le module conductor voisin du dépôt source.
resolve_budget() {
  local b; b="$(dirname "$0")/check-method-budget.sh"
  [ -f "$b" ] || b="$(dirname "$0")/../../conductor/scripts/check-method-budget.sh"
  [ -f "$b" ] && { printf '%s' "$b"; return 0; }
  return 1
}
budget_snap_path() { # chemin absolu du snapshot, sous le répertoire git commun ; échec si ROOT n'est pas un dépôt
  local g; g="$(git_safe rev-parse --git-common-dir 2>/dev/null)" || return 1
  [ -n "$g" ] || return 1
  case "$g" in /*) ;; *) g="$ROOT/$g" ;; esac
  printf '%s/vf-mission-budget.snap' "$g"
}
BUDGET_TOK='RANGEABLE|ARCHIVABLE|ARCHIVAGE REFUSÉ'
budget_lines() { { grep -E "$BUDGET_TOK" || true; } | sed 's/^\[budget\] *//' | LC_ALL=C sort -u; }
# Identité de la mission : le NOM de la génération du verrou de driver courant (lien DRIVER.lock → DRIVER.lock.gen.<epoch>.<pid>),
# « - » sans verrou. Même chemin que E1 (le verrou du dépôt jugé), jamais une variable d'environnement.
cur_lock_gen() {
  local l="$ROOT/.planning/DRIVER.lock" t
  if [ -L "$l" ]; then t="$(readlink "$l" 2>/dev/null)"; printf '%s' "${t##*/}"
  elif [ -e "$l" ]; then printf 'legacy'
  else printf -- '-'; fi
}

if [ "$BUDGET_SNAPSHOT" -eq 1 ]; then
  # Geste du manager, UNE fois, au démarrage de la mission : photographie SANS ÉCRITURE (--auto --dry-run : la
  # décision d'archivage est prise, rien n'est écrit) de ce qui est déjà rangeable ; écrit hors de l'arbre de travail.
  SNAP_BUDGET="$(resolve_budget)" || { echo "[check-mission-exit] --budget-snapshot : check-method-budget.sh introuvable" >&2; exit 4; }
  SNAP_PATH="$(budget_snap_path)" || { echo "[check-mission-exit] --budget-snapshot : $ROOT n'est pas un dépôt git" >&2; exit 4; }
  # --auto --dry-run : la MÊME décision que celle d'E7, rien d'écrit ; un ARCHIVAGE REFUSÉ déjà là au démarrage
  # (source non commitée…) est donc dans la référence et n'est pas imputé à la mission.
  SNAP_OUT="$(bash "$SNAP_BUDGET" --root "$ROOT" --no-remote --quiet --auto --dry-run 2>/dev/null)"; SNAP_RC=$?
  if [ "$SNAP_RC" -ge 2 ]; then
    echo "[check-mission-exit] --budget-snapshot : check-method-budget.sh a rendu $SNAP_RC, snapshot non posé" >&2
    exit 4
  fi
  { printf '#date=%s\n#gen=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(cur_lock_gen)"; printf '%s\n' "$SNAP_OUT" | budget_lines; } > "$SNAP_PATH.tmp.$$" 2>/dev/null && mv -f "$SNAP_PATH.tmp.$$" "$SNAP_PATH" 2>/dev/null \
    || { rm -f "$SNAP_PATH.tmp.$$" 2>/dev/null; echo "[check-mission-exit] --budget-snapshot : écriture impossible ($SNAP_PATH)" >&2; exit 4; }
  say "snapshot de début de mission posé : $SNAP_PATH (génération du verrou : $(cur_lock_gen))"
  exit 0
fi

# --- États initiaux des sept contrôles, HORS des marqueurs ------------------------------------------
# Initialisés à "sain" pour que la suppression chirurgicale d'un bloc (outillage de test, tâche 2)
# ne fasse jamais planter ce script sous `set -u` et retombe silencieusement sur "sain" — c'est la
# propriété d'isolation exigée par l'action de la tâche 1, jamais un chemin de production.
E1_STATUS="sain"; E1_MSG=""
E2_STATUS="sain"; E2_MSG=""
E3_STATUS="sain"; E3_MSG=""
E4_STATUS="sain"; E4_MSG=""
E5_STATUS="sain"; E5_MSG=""
E6_STATUS="sain"; E6_MSG=""
E7_STATUS="sain"; E7_MSG=""

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

# e3_merge_danger — analyse du corps de PR LU SUR L'ENTRÉE STANDARD (POCK-06). Rend 0 structure
# conforme (alors IMPRIME, une par ligne, la valeur de chaque ligne « Rayon d'explosion : » de la
# section — jamais réémise, seulement mesurée par e3_charcount) · 11 section « ## Merge-danger call »
# absente · 12 section répétée, ligne « Porte : » absente, hors énumération fermée (sens unique |
# double sens), répétée ou contradictoire. Codes de CONTENU réservés (11, 12) : une erreur d'awk sort
# en 2 et ne se confond jamais avec un verdict de contenu (branche « indéterminé » de l'appelant).
# Section = du titre exact (blancs de fin tolérés) au titre « ## » suivant ou à la fin du corps ; ce
# qui n'est pas rendu à la relecture humaine n'existe pas : un bloc de code (``` ou ~~~, indenté de
# 0 à 3 espaces, retirés par strip3 : jamais de quantificateur « ? » répété ni d'intervalle {n,m}, que
# mawk 1.3.4 n'applique pas comme BWK awk) et un commentaire HTML (<!-- -->) sont ignorés. Un bloc ne se ferme que par une fence
# du MÊME caractère et de longueur au moins égale ; un « <!-- » dans un bloc de code ou entre accents
# graves (code inline) ne masque rien. L'apostrophe droite s'écrit en octal (\047) : le programme
# awk vit entre apostrophes ; l'apostrophe typographique est admise en alternative.
e3_merge_danger() {
  awk '
    function mask(s,   o, p) {
      o = ""
      while (match(s, /`[^`]*`/)) { p = sprintf("%" RLENGTH "s", ""); gsub(/ /, "x", p); o = o substr(s, 1, RSTART - 1) p; s = substr(s, RSTART + RLENGTH) }
      return o s
    }
    function strip3(s,   k) {
      k = 0
      while (k < 3 && substr(s, k + 1, 1) == " ") k++
      return substr(s, k + 1)
    }
    BEGIN { ntit = 0; insec = 0; infence = 0; incom = 0; ptot = 0; pval = 0; fch = ""; flen = 0 }
    { l = $0 }
    infence { m = strip3(l); n = 0; while (substr(m, n + 1, 1) == fch) n++; if (n >= flen && substr(m, n + 1) ~ /^[ \t]*$/) infence = 0; next }
    incom { k = index(l, "-->"); if (k == 0) next; l = substr(l, k + 3); incom = 0 }
    { while ((i = index(mask(l), "<!--")) > 0) { j = index(substr(l, i + 4), "-->"); if (j == 0) { l = substr(l, 1, i - 1); incom = 1; break }; l = substr(l, 1, i - 1) substr(l, i + j + 6) } }
    (m = strip3(l)) ~ /^(```|~~~)/ { fch = substr(m, 1, 1); flen = 0; while (substr(m, flen + 1, 1) == fch) flen++; infence = 1; next }
    l ~ /^## / { if (l ~ /^## Merge-danger call[ \t]*$/) { ntit++; insec = (ntit == 1) } else { insec = 0 }; next }
    insec && l ~ /^Porte ?:/ { ptot++; if (l ~ /^Porte ?:[ \t]*(sens unique|double sens)[ \t]*$/) pval++ }
    insec && l ~ /^Rayon d(\047|’)explosion ?:/ { v = l; sub(/^[^:]*:/, "", v); print v }
    END {
      if (ntit == 0) exit 11
      if (ntit > 1) exit 12
      if (ptot != 1 || pval != 1) exit 12
      exit 0
    }
  '
}

# e3_charcount — longueur d'une valeur en CARACTÈRES (codepoints UTF-8, jamais d'octets, sans dépendre
# d'aucune locale), hors blancs : espaces, tabulations, espace insécable U+00A0, espaces U+2000-200B,
# U+202F et U+3000. Même règle que `charcount` de check-ajout-retrait.sh.
E3_BLANCS_SED="s/$(printf '\302\240')//g;s/$(printf '\342\200')[$(printf '\200-\213\257')]//g;s/$(printf '\343\200\200')//g"
e3_charcount() {
  printf '%s' "$1" \
    | LC_ALL=C sed -e "$E3_BLANCS_SED" \
    | LC_ALL=C tr -d '[:space:]' \
    | od -v -An -tu1 | tr -s ' \n' '\n' \
    | awk 'NF && ($1 < 128 || $1 >= 192) { n++ } END { print n + 0 }'
}

# >>> E3
# E3 — branche dédiée, PR ouverte et merge-danger call conforme (POCK-06).
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
      E3_PR_JSON="$(cd "$ROOT" && gh pr view --json state,body 2>/dev/null)"
      E3_PR_RC=$?
      E3_PR_STATE="$(printf '%s' "$E3_PR_JSON" | jq -r '.state // empty' 2>/dev/null)"
      if [ "$E3_PR_RC" -ne 0 ] || [ -z "$E3_PR_STATE" ]; then
        E3_STATUS="indet"
        E3_MSG="[E3] aucune PR lisible pour la branche courante ($E3_CURRENT)"
      elif [ "$E3_PR_STATE" = "OPEN" ]; then
        # Merge-danger call (POCK-06). Corps = donnée NON FIABLE : type testé (jamais un vert par défaut
        # sur une clé absente), extraction par jq, analyse sur stdin, énumération fermée, messages fixes.
        E3_BODY_TYPE="$(printf '%s' "$E3_PR_JSON" | jq -r '.body | type' 2>/dev/null)"
        if [ "$E3_BODY_TYPE" != "string" ]; then
          E3_STATUS="indet"
          E3_MSG="[E3] corps de PR illisible (clé body absente ou non chaîne) — merge-danger call invérifiable"
        else
          E3_BODY="$(printf '%s' "$E3_PR_JSON" | jq -r '.body' 2>/dev/null | tr -d '\r')"
          E3_RAYONS="$(printf '%s\n' "$E3_BODY" | e3_merge_danger)"; E3_MD_RC=$?
          case "$E3_MD_RC" in
            0)
              E3_STATUS="manque"; E3_MSG="[E3] PR ouverte sans merge-danger call conforme (POCK-06) : rayon d'explosion de moins de 10 caractères"
              while IFS= read -r E3_V; do
                if [ "$(e3_charcount "$E3_V")" -ge 10 ]; then E3_STATUS="sain"; E3_MSG=""; fi
              done <<EOF_RAYONS
$E3_RAYONS
EOF_RAYONS
              ;;
            11) E3_STATUS="manque"; E3_MSG="[E3] PR ouverte sans merge-danger call conforme (POCK-06) : section « ## Merge-danger call » absente" ;;
            12) E3_STATUS="manque"; E3_MSG="[E3] PR ouverte sans merge-danger call conforme (POCK-06) : section répétée, ligne « Porte : sens unique|double sens » absente, invalide ou répétée" ;;
            *) E3_STATUS="indet"; E3_MSG="[E3] analyse du merge-danger call impossible (outil d'analyse en échec) — invérifiable" ;;
          esac
        fi
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
  # --- Résolution du compartiment ACTIF (partition D-02, 2026-09-23) -----------------------------
  # Même politique et même best-effort fail-open que check-requirements-survival.sh/
  # restore-requirements-ledger.sh (voir leur en-tête) : ROADMAP.md et STATE.md VIVANTS lus par E4
  # sont ceux du compartiment ACTIF (`.planning/workstreams/<nom>/`), résolus via
  # workstream-policy.sh — GSD_WORKSTREAM en canal nominal, puis le pointeur partagé
  # .planning/active-workstream. Politique introuvable, nom rejeté ou compartiment refusé replient
  # silencieusement sur le comportement historique (`$ROOT/.planning/{ROADMAP,STATE}.md`, labs non
  # partitionnés). Codes de sortie et sémantique E4 inchangés.
  E4_PLANNING_DIR="$ROOT/.planning"
  _SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
  for _wscand in "$_SCRIPT_DIR/../../planning-core/scripts/workstream-policy.sh" \
                 "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
    if [ -n "$_wscand" ] && [ -r "$_wscand" ]; then
      # shellcheck source=/dev/null
      . "$_wscand"
      break
    fi
  done
  E4_ROADMAP="$E4_PLANNING_DIR/ROADMAP.md"
  E4_STATE_OVERRIDE=""
  if command -v vf_ws_resolve >/dev/null 2>&1; then
    vf_ws_resolve "$E4_PLANNING_DIR"
    if [ -n "${VF_WS_NAME:-}" ] && command -v vf_ws_dir_resolve >/dev/null 2>&1; then
      vf_ws_dir_resolve "$E4_PLANNING_DIR" "$VF_WS_NAME"
      if [ -n "${VF_WS_DIR:-}" ]; then
        E4_ROADMAP="$VF_WS_DIR/ROADMAP.md"
        E4_STATE_OVERRIDE="$VF_WS_DIR/STATE.md"
      fi
    fi
  fi
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
    E4_STATE="${E4_STATE_OVERRIDE:-$E4_PLANNING_DIR/STATE.md}"
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
# Résolution du chemin de rapport DUPLIQUÉE (et non partagée avec E5) : les sept contrôles sont
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

# >>> E7
# E7 — rien de rangeable n'est laissé par la mission (SOBR-07). Delta contre le snapshot de début de mission.
E7_BUDGET="$(resolve_budget || true)"
E7_SNAP="$(budget_snap_path || true)"
if [ -z "$E7_BUDGET" ]; then
  E7_STATUS="indet"
  E7_MSG="[E7] check-method-budget.sh introuvable (ni à côté de ce script, ni sous ../../conductor/scripts)"
elif [ -z "$E7_SNAP" ] || [ ! -f "$E7_SNAP" ]; then
  E7_STATUS="indet"
  E7_MSG="[E7] snapshot de début de mission absent : impossible de distinguer ce que la mission a créé de ce qui existait. Le manager le pose au démarrage, après l'acquire : check-mission-exit.sh --budget-snapshot"
else
  E7_SGEN="$(sed -n 's/^#gen=//p' "$E7_SNAP" 2>/dev/null | head -1)"
  E7_SDATE="$(sed -n 's/^#date=//p' "$E7_SNAP" 2>/dev/null | head -1)"
  E7_CGEN="$(cur_lock_gen)"
  if [ -z "$E7_SGEN" ]; then
    E7_STATUS="indet"
    E7_MSG="[E7] snapshot de début de mission sans identité ni date (posé par une version antérieure) : impossible de savoir à quelle mission il appartient. Le reposer au démarrage : check-mission-exit.sh --budget-snapshot"
  elif [ "$E7_CGEN" != "-" ] && [ "$E7_CGEN" != "$E7_SGEN" ]; then
    E7_STATUS="indet"
    E7_MSG="[E7] snapshot d'une autre mission : posé le ${E7_SDATE:-?} sous la génération « $E7_SGEN » du verrou, le verrou courant est « $E7_CGEN ». Ce qu'il masque n'est pas ce qui existait au démarrage de CETTE mission : le reposer"
  else
  if [ "$E7_SGEN" = "-" ]; then say "[E7] snapshot posé le ${E7_SDATE:-?} SANS verrou de driver : aucune identité de mission, seule la date le situe"
  else say "[E7] snapshot posé le ${E7_SDATE:-?}, génération du verrou « $E7_SGEN » (verrou courant : $E7_CGEN ; relâché, l'identité n'est plus recontrôlable : seule la date la situe)"; fi
  E7_OUT="$(bash "$E7_BUDGET" --root "$ROOT" --no-remote --quiet --strict --auto 2>/dev/null)"; E7_RC=$?
  E7_ARCHIVE="$({ printf '%s\n' "$E7_OUT" | grep 'ARCHIVÉ' || true; } | sed 's/^\[budget\] *//')"
  E7_NONTENTE="$({ printf '%s\n' "$E7_OUT" | grep 'ARCHIVAGE NON TENTÉ' || true; } | sed 's/^\[budget\] *//')"
  E7_NOW="$(mktemp "${TMPDIR:-/tmp}/vf-e7.XXXXXX")"
  printf '%s\n' "$E7_OUT" | budget_lines > "$E7_NOW"
  E7_LIGNES="$(LC_ALL=C comm -23 "$E7_NOW" "$E7_SNAP")"
  rm -f "$E7_NOW"
  if [ -n "$E7_NONTENTE" ]; then
    E7_STATUS="indet"
    E7_MSG="[E7] $E7_NONTENTE : rien n'a été archivé, l'état du geste de fin n'est pas vérifiable"
  elif [ "$E7_RC" -ge 2 ]; then
    E7_STATUS="indet"
    E7_MSG="[E7] check-method-budget.sh a rendu $E7_RC (non vérifiable ou usage) : rien de sûr sur ce qui reste rangeable"
    [ -n "$E7_ARCHIVE" ] && E7_MSG="$E7_MSG"$'\n'"[E7] archivé avant l'échec, à commiter : $E7_ARCHIVE"
  else
    E7_MANQUES=""
    while IFS= read -r E7_L; do
      [ -n "$E7_L" ] && E7_MANQUES="${E7_MANQUES}[E7] $E7_L"$'\n'
    done <<EOF_E7
$E7_LIGNES
EOF_E7
    [ -n "$E7_ARCHIVE" ] && E7_MANQUES="${E7_MANQUES}[E7] archivé, à commiter : $E7_ARCHIVE"$'\n'
    if [ -n "$E7_MANQUES" ]; then
      E7_STATUS="manque"
      E7_MSG="${E7_MANQUES%$'\n'}"
    fi
  fi
  fi
fi
# <<< E7

# --- Agrégation finale — précédence 64 > 4 > 0 > 3 (D-06) -----------------------------------------
HAS_INDET=0
HAS_MANQUE=0
for id in E1 E2 E3 E4 E5 E6 E7; do
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

say "SAIN — les sept contrôles E1 à E7 ont été vérifiés et sont conformes."
exit 3
