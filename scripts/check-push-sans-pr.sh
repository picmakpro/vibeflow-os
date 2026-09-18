#!/usr/bin/env bash
# check-push-sans-pr.sh — G-3 (PROT-05). ALARME APRES COUP sur un commit arrive sur `main`
# SANS PR associee : demande a GitHub quelles PR referencent le sha juge et rougit si aucune
# association n'existe.
#
# (1) ALARME APRES COUP, JAMAIS UN VERROU, a lire en premier. Quand cette garde rougit, le
# commit est DEJA sur `main` — elle ne peut RIEN empecher, elle rend le fait visible et date.
# Precedent mesure : `892f89a` (2026-09-16, `docs(explore)`) est arrive sur `main` sans PR et son
# run CI est rouge, sans que rien ne l'arrete.
#
# (2) LIMITE DE FOND. Cette garde vit dans le depot, dans la surface qu'elle-meme designe comme
# gate (`scripts/check-*.sh`) : la PR — ou le push direct — qu'elle juge peut la modifier, elle,
# sa suite `scripts/tests/test-check-push-sans-pr.sh`, et l'etape CI qui l'invoque, et rester
# verte. Formule canonique (sonde de limite de fond, check-aucune-fermeture.sh, plan 41-15),
# reprise ici mot pour mot : cette garde peut etre modifiée par la PR qu'elle juge. Elle REND
# VISIBLE et TRACE une atteinte ; elle NE VERROUILLE RIEN.
#
# (3) AUCUNE REGLE SERVEUR. Faute d'acces admin sur ce depot (option (a), arbitrage Samuel,
# AskUserQuestion session principale, 2026-09-17), aucune regle cote GitHub n'existe pour imposer
# la PR : personne, dans ce perimetre, ne peut poser un ruleset. L'amendement d'ADR-059 sur la PR
# obligatoire est hors perimetre, puisqu'aucune regle serveur ne l'appliquerait.
#
# DEUX LECTURES EN CASCADE, jamais une seule.
#   1. `GET repos/<repo>/commits/<sha>/pulls` — les PR qui referencent directement le sha.
#   2. Si la premiere est vide : `GET repos/<repo>/pulls?state=closed&sort=updated&direction=desc`
#      et recherche d'une PR dont `merge_commit_sha` egale (insensible a la casse) le sha juge.
# RAISON DE LA SECONDE LECTURE, mesuree, pas supposee : ce depot merge AUSSI par rebase (PR #71
# `72259f4` et PR #72 `306e25d`), et le tag `v2.63.0` pointe sur le commit rebase `72259f4`. Pour
# un merge par rebase, le sha qui atterrit sur `main` n'est pas le sha de la PR d'origine — la
# premiere lecture ne garantit pas l'association. Sans cette cascade, la garde rougirait sur des
# merges parfaitement reguliers de ce depot.
#
# ECHEC D'API JAMAIS CONFONDU AVEC LISTE VIDE. `gh` absent, echec d'authentification, code non
# 2xx, ou JSON imparsable/non-tableau sur L'UNE OU L'AUTRE lecture -> rc 2 NON-VERIFIABLE,
# JAMAIS rc 1. Une alarme fondee sur une reponse qu'on n'a pas lue serait pire qu'une absence
# d'alarme (precedent nomme : le faux negatif d'auth de la v2.39.0 le 2026-07-26, ou un `gh`
# non authentifie avait ete lu comme « aucune release »).
#
# PREMIER COMMIT D'UNE BRANCHE NEUVE. Si `--before` est fourni et vaut une suite de zeros
# (longueur 40 ou 7 — creation de ref GitHub), il n'y a aucune base : rc 3 CREATION-DE-REF,
# jamais rc 1 (le premier commit d'une ref neuve n'est pas un push direct sur une ref existante).
# Si `--before` est absent (invocation a la main), le script tente, en best effort via le depot
# git local, de detecter que le sha juge n'a lui-meme aucun parent (meme verdict, meme raison) ;
# un sha non resoluble localement dans ce cas ne fait PAS echouer le script, il poursuit
# normalement vers la premiere lecture.
#
# BORNE ECRITE, PAS PRETENDUE COUVERTE. La garde juge le SOMMET du push (`--sha`, `github.sha`).
# Un push direct de plusieurs commits est signale par son seul sommet ; les commits sous un
# sommet regulierement associe a une PR ne sont pas re-interroges, puisqu'ils sont entres par
# cette PR.
#
# VERT A VIDE INTERDIT. rc 0 n'est rendu qu'apres une reponse d'API effectivement lue ET une
# association effectivement trouvee (`pr_associee` non vide). Ligne de decouverte imprimee sur
# toute issue rc 0 ou rc 1 :
#   decouverte: sha=<court> pulls_lues=<n> closed_examinees=<m> pr_associee=<numero|aucune> voie=<commits-pulls|merge-commit-sha|aucune>
#
# Usage:
#   check-push-sans-pr.sh [--repo O/R] [--sha SHA] [--before SHA]
#                          [--pulls-file F] [--closed-pulls-file F] [-h|--help]
#
#   --repo O/R              Depot cible (defaut : $GITHUB_REPOSITORY, sinon derive du remote
#                            `origin`, sinon rc 2). Doit contenir un unique `/` — sinon rc 2.
#   --sha SHA                Sha juge (defaut : $GITHUB_SHA, sinon `git rev-parse HEAD`, sinon rc 2).
#   --before SHA              Sha precedent du push (defaut : $GITHUB_EVENT_BEFORE, sinon absent).
#   --pulls-file F, --closed-pulls-file F
#                            RESERVES AUX FIXTURES — lisent un JSON depuis disque au lieu
#                            d'appeler `gh api`. Toute invocation de production les omet, la
#                            cascade de lecture reelle joue.
#
# Exit codes (contrat interne, tous enumeres) :
#   0  = PR-ASSOCIEE — au moins une des deux lectures associe le sha a une PR
#   1  = PUSH-SANS-PR — les deux lectures ont abouti a un JSON valide, aucune association trouvee
#   2  = NON-VERIFIABLE — `gh` absent, echec d'auth, code non 2xx, JSON imparsable/non-tableau sur
#        l'une des deux lectures, ou `--repo`/`--sha` non fournis et non derivables
#   3  = CREATION-DE-REF — `--before` entierement nul, ou sha juge sans parent detectable
#        localement (silence non bloquant, jamais un rc 1)
#   64 = erreur d'usage (argument inconnu, option sans valeur, `--pulls-file`/`--closed-pulls-file`
#        vers un fichier inexistant)
set -uo pipefail

REPO=""
SHA=""
BEFORE=""
BEFORE_SET=0
PULLS_FILE=""
CLOSED_PULLS_FILE=""

usage() { grep '^# ' "$0" | sed 's/^# //'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || { echo "[check-push-sans-pr] --repo necessite une valeur" >&2; exit 64; }
      REPO="$2"; shift 2 ;;
    --sha)
      [ "$#" -ge 2 ] || { echo "[check-push-sans-pr] --sha necessite une valeur" >&2; exit 64; }
      SHA="$2"; shift 2 ;;
    --before)
      [ "$#" -ge 2 ] || { echo "[check-push-sans-pr] --before necessite une valeur" >&2; exit 64; }
      BEFORE="$2"; BEFORE_SET=1; shift 2 ;;
    --pulls-file)
      [ "$#" -ge 2 ] || { echo "[check-push-sans-pr] --pulls-file necessite une valeur" >&2; exit 64; }
      PULLS_FILE="$2"; shift 2 ;;
    --closed-pulls-file)
      # Message scinde sur deux lignes (jamais le nom du script et l'option --closed-pulls-file
      # sur la meme ligne) : cf. check-aucune-fermeture.sh, plan 41-15 — le sous-mot "closed" de
      # ce nom d'option coexisterait sinon avec le nom du script sur une seule ligne, un faux hit.
      if [ "$#" -lt 2 ]; then
        echo "[check-push-sans-pr] option incomplete —" >&2
        echo "l'option de fixture des PR --closed-pulls-file necessite une valeur" >&2
        exit 64
      fi
      CLOSED_PULLS_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[check-push-sans-pr] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ -n "$PULLS_FILE" ] && [ ! -f "$PULLS_FILE" ]; then
  echo "[check-push-sans-pr] --pulls-file introuvable : $PULLS_FILE" >&2
  exit 64
fi
if [ -n "$CLOSED_PULLS_FILE" ] && [ ! -f "$CLOSED_PULLS_FILE" ]; then
  echo "[check-push-sans-pr] fichier de fixture introuvable —" >&2
  echo "l'option --closed-pulls-file pointe : $CLOSED_PULLS_FILE" >&2
  exit 64
fi

# --- Resolution --repo, --sha (cascade nommee) ---------------------------------------------------
if [ -z "$REPO" ]; then
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    REPO="$GITHUB_REPOSITORY"
  else
    origin_url="$(git remote get-url origin 2>/dev/null || true)"
    REPO="$(printf '%s' "$origin_url" | sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##')"
  fi
fi
if [ -z "$REPO" ]; then
  echo "[check-push-sans-pr] --repo non fourni, GITHUB_REPOSITORY absent, remote origin non derivable" >&2
  exit 2
fi
case "$REPO" in
  */*) : ;;
  *) echo "[check-push-sans-pr] --repo malforme (attendu owner/nom) : $REPO" >&2; exit 2 ;;
esac

if [ -z "$SHA" ]; then
  if [ -n "${GITHUB_SHA:-}" ]; then
    SHA="$GITHUB_SHA"
  else
    SHA="$(git rev-parse HEAD 2>/dev/null || true)"
  fi
fi
if [ -z "$SHA" ]; then
  echo "[check-push-sans-pr] --sha non fourni, GITHUB_SHA absent, HEAD non resoluble" >&2
  exit 2
fi
SHA_COURT="${SHA:0:7}"

if [ "$BEFORE_SET" -eq 0 ] && [ -n "${GITHUB_EVENT_BEFORE:-}" ]; then
  BEFORE="$GITHUB_EVENT_BEFORE"; BEFORE_SET=1
fi

# --- Comparaison 1 : creation de ref, jamais un rc 1 ----------------------------------------------
is_all_zero() {
  local v="$1"
  [[ "$v" =~ ^0+$ ]] || return 1
  local len=${#v}
  [ "$len" -eq 40 ] || [ "$len" -eq 7 ]
}

if [ "$BEFORE_SET" -eq 1 ]; then
  if is_all_zero "$BEFORE"; then
    echo "CREATION-DE-REF: --before entierement nul (${BEFORE}) — aucune base, rien a imputer"
    exit 3
  fi
else
  # Invocation a la main, sans --before : verification best-effort du parent du sha juge dans le
  # depot git local. Un sha non resoluble localement ne fait jamais echouer ce script — il
  # poursuit normalement vers la premiere lecture (le cas d'une fixture ou d'un clone superficiel).
  if git rev-parse --verify -q "${SHA}^{commit}" >/dev/null 2>&1; then
    if ! git rev-parse --verify -q "${SHA}~1" >/dev/null 2>&1; then
      echo "CREATION-DE-REF: le sha juge (${SHA_COURT}) n'a aucun parent — aucune base, rien a imputer"
      exit 3
    fi
  fi
fi

# --- Classification a trois etats, partagee par les deux lectures ---------------------------------
# classify_pulls <contenu> <rc_appel> -> imprime "ETAT<TAB>N<TAB>PREMIER_NUMERO"
# ETAT in {ASSOCIEE, VIDE, INDETERMINE}. Jamais VIDE si aucun des deux parseurs ne conclut.
classify_pulls() {
  local content="$1" call_rc="$2"
  if [ "$call_rc" -ne 0 ] || [ -z "$content" ]; then
    printf 'INDETERMINE\t0\t\n'; return
  fi
  if command -v jq >/dev/null 2>&1; then
    if ! printf '%s' "$content" | jq -e 'type == "array"' >/dev/null 2>&1; then
      printf 'INDETERMINE\t0\t\n'; return
    fi
    local n first
    n="$(printf '%s' "$content" | jq 'length' 2>/dev/null)"
    [ -n "$n" ] || { printf 'INDETERMINE\t0\t\n'; return; }
    if [ "$n" -eq 0 ]; then
      printf 'VIDE\t0\t\n'
    else
      # Source UNIQUE de la garantie de non-vacuite (MUT-5) : un tableau non vide dont le premier
      # element n'expose pas de "number" lisible EST TOUT DE MEME classe ASSOCIEE ici — c'est
      # l'assertion de non-vacuite du flot principal, plus bas, qui rattrape un pr_associee vide
      # avant tout rc 0, jamais une seconde garde locale redondante qui la rendrait invisible.
      first="$(printf '%s' "$content" | jq -r '.[0].number // empty' 2>/dev/null)"
      printf 'ASSOCIEE\t%s\t%s\n' "$n" "$first"
    fi
    return
  fi
  # Repli awk (jq indisponible) : heuristique sur le premier caractere non blanc du contenu.
  local trimmed
  trimmed="$(printf '%s' "$content" | awk '{ gsub(/^[ \t]+/,""); print; exit }')"
  case "$trimmed" in
    '['*)
      local compact
      compact="$(printf '%s' "$content" | tr -d '[:space:]')"
      if [ "$compact" = "[]" ]; then
        printf 'VIDE\t0\t\n'
      else
        local first
        first="$(printf '%s' "$content" | awk 'match($0, /"number"[ \t]*:[ \t]*[0-9]+/) { s=substr($0,RSTART,RLENGTH); gsub(/[^0-9]/,"",s); print s; exit }')"
        # Meme source unique qu'en tete de jq (MUT-5) : ASSOCIEE meme sans "number" extrait.
        printf 'ASSOCIEE\t1\t%s\n' "$first"
      fi
      ;;
    *) printf 'INDETERMINE\t0\t\n' ;;
  esac
}

# classify_closed_pulls <contenu> <rc_appel> <sha> -> imprime "ETAT<TAB>N<TAB>NUMERO_TROUVE"
# ETAT ASSOCIEE seulement si un merge_commit_sha correspond (insensible a la casse) au sha juge ;
# sinon VIDE (tableau parseable sans correspondance) ; INDETERMINE si imparsable/non-tableau.
classify_closed_pulls() {
  local content="$1" call_rc="$2" sha="$3"
  if [ "$call_rc" -ne 0 ] || [ -z "$content" ]; then
    printf 'INDETERMINE\t0\t\n'; return
  fi
  local sha_lc
  sha_lc="$(printf '%s' "$sha" | tr '[:upper:]' '[:lower:]')"
  if command -v jq >/dev/null 2>&1; then
    if ! printf '%s' "$content" | jq -e 'type == "array"' >/dev/null 2>&1; then
      printf 'INDETERMINE\t0\t\n'; return
    fi
    local n found
    n="$(printf '%s' "$content" | jq 'length' 2>/dev/null)"
    [ -n "$n" ] || { printf 'INDETERMINE\t0\t\n'; return; }
    found="$(printf '%s' "$content" | jq -r --arg sha "$sha_lc" '
      map(select(((.merge_commit_sha // "") | ascii_downcase) == $sha)) | (.[0].number // empty)
    ' 2>/dev/null)"
    if [ -n "$found" ]; then
      printf 'ASSOCIEE\t%s\t%s\n' "$n" "$found"
    else
      printf 'VIDE\t%s\t\n' "$n"
    fi
    return
  fi
  # Repli awk (jq indisponible) : appariement objet-par-objet borne aux tableaux compacts a un
  # niveau (forme GitHub reelle) ; toute forme non reconnue -> INDETERMINE, jamais VIDE par defaut.
  local trimmed
  trimmed="$(printf '%s' "$content" | awk '{ gsub(/^[ \t]+/,""); print; exit }')"
  case "$trimmed" in
    '['*)
      local result
      result="$(printf '%s' "$content" | awk -v target="$sha_lc" '
        BEGIN { depth = 0; obj = ""; count = 0; found_num = "" }
        {
          line = $0
          n = length(line)
          for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "{") { if (depth == 0) { obj = "" }; depth++ }
            if (depth > 0) obj = obj c
            if (c == "}") {
              depth--
              if (depth == 0) {
                count++
                lobj = tolower(obj)
                if (match(lobj, /"merge_commit_sha"[ \t]*:[ \t]*"[0-9a-f]+"/)) {
                  s = substr(lobj, RSTART, RLENGTH)
                  gsub(/.*"merge_commit_sha"[ \t]*:[ \t]*"/, "", s)
                  gsub(/".*/, "", s)
                  if (s == target && found_num == "") {
                    if (match(obj, /"number"[ \t]*:[ \t]*[0-9]+/)) {
                      ns = substr(obj, RSTART, RLENGTH)
                      gsub(/[^0-9]/, "", ns)
                      found_num = ns
                    }
                  }
                }
                obj = ""
              }
            }
          }
        }
        END { print count "\037" found_num }
      ' 2>/dev/null)"
      local cnt fnd
      cnt="${result%%$'\037'*}"
      fnd="${result#*$'\037'}"
      [ -n "$cnt" ] || { printf 'INDETERMINE\t0\t\n'; return; }
      if [ -n "$fnd" ]; then
        printf 'ASSOCIEE\t%s\t%s\n' "$cnt" "$fnd"
      else
        printf 'VIDE\t%s\t\n' "$cnt"
      fi
      ;;
    *) printf 'INDETERMINE\t0\t\n' ;;
  esac
}

# --- Comparaison 2 : premiere lecture --------------------------------------------------------------
if [ -n "$PULLS_FILE" ]; then
  PULLS_RAW="$(cat "$PULLS_FILE" 2>/dev/null)"; PULLS_CALL_RC=$?
else
  if ! command -v gh >/dev/null 2>&1; then
    PULLS_RAW=""; PULLS_CALL_RC=127
  else
    PULLS_RAW="$(gh api "repos/${REPO}/commits/${SHA}/pulls" 2>&1)"; PULLS_CALL_RC=$?
  fi
fi

CLASSIFY1="$(classify_pulls "$PULLS_RAW" "$PULLS_CALL_RC")"
IFS=$'\t' read -r ETAT1 N1 NUM1 <<< "$CLASSIFY1"
PULLS_LUES="${N1:-0}"

if [ "$ETAT1" = "INDETERMINE" ]; then
  echo "NON-VERIFIABLE: premiere lecture indeterminee (rc appel=${PULLS_CALL_RC})" >&2
  printf '%s\n' "$PULLS_RAW" | head -5 >&2
  exit 2
fi

if [ "$ETAT1" = "ASSOCIEE" ]; then
  PR_ASSOCIEE="$NUM1"
  # Assertion de non-vacuite (MUT-5) : jamais de rc 0 sans pr_associee effectivement renseignee.
  if [ -z "$PR_ASSOCIEE" ]; then
    echo "NON-VERIFIABLE: premiere lecture ASSOCIEE mais aucun numero de PR lisible" >&2
    exit 2
  fi
  echo "decouverte: sha=${SHA_COURT} pulls_lues=${PULLS_LUES} closed_examinees=0 pr_associee=${PR_ASSOCIEE} voie=commits-pulls"
  echo "PR-ASSOCIEE: sha=${SHA_COURT} associe a la PR #${PR_ASSOCIEE} (premiere lecture)"
  exit 0
fi

# ETAT1 == VIDE -> cascade seconde lecture, JAMAIS executee si la premiere a deja associe.
if [ -n "$CLOSED_PULLS_FILE" ]; then
  CLOSED_RAW="$(cat "$CLOSED_PULLS_FILE" 2>/dev/null)"; CLOSED_CALL_RC=$?
else
  if ! command -v gh >/dev/null 2>&1; then
    CLOSED_RAW=""; CLOSED_CALL_RC=127
  else
    CLOSED_RAW="$(gh api "repos/${REPO}/pulls?state=closed&sort=updated&direction=desc&per_page=30" 2>&1)"; CLOSED_CALL_RC=$?
  fi
fi

CLASSIFY2="$(classify_closed_pulls "$CLOSED_RAW" "$CLOSED_CALL_RC" "$SHA")"
IFS=$'\t' read -r ETAT2 N2 NUM2 <<< "$CLASSIFY2"
CLOSED_EXAMINEES="${N2:-0}"

if [ "$ETAT2" = "INDETERMINE" ]; then
  echo "NON-VERIFIABLE: seconde lecture indeterminee (rc appel=${CLOSED_CALL_RC})" >&2
  printf '%s\n' "$CLOSED_RAW" | head -5 >&2
  exit 2
fi

if [ "$ETAT2" = "ASSOCIEE" ]; then
  PR_ASSOCIEE="$NUM2"
  if [ -z "$PR_ASSOCIEE" ]; then
    echo "NON-VERIFIABLE: seconde lecture ASSOCIEE mais aucun numero de PR lisible" >&2
    exit 2
  fi
  echo "decouverte: sha=${SHA_COURT} pulls_lues=${PULLS_LUES} closed_examinees=${CLOSED_EXAMINEES} pr_associee=${PR_ASSOCIEE} voie=merge-commit-sha"
  echo "PR-ASSOCIEE: sha=${SHA_COURT} associe a la PR #${PR_ASSOCIEE} (seconde lecture, merge_commit_sha — merge par rebase)"
  exit 0
fi

# ETAT2 == VIDE -> les deux lectures ont abouti a un JSON valide, aucune association.
echo "decouverte: sha=${SHA_COURT} pulls_lues=${PULLS_LUES} closed_examinees=${CLOSED_EXAMINEES} pr_associee=aucune voie=aucune"
echo "PUSH-SANS-PR: sha=${SHA_COURT} pulls_lues=${PULLS_LUES} closed_examinees=${CLOSED_EXAMINEES} — aucune PR associee (deux lectures abouties, jamais un rouge par vacuite non lue)"
exit 1
