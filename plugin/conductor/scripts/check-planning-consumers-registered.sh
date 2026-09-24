#!/usr/bin/env bash
# check-planning-consumers-registered.sh — Lint anti-oubli : tout script qui référence un chemin
# d'artefact de planning est RECENSÉ dans `references/workstream-planning-consumers.md`.
#
# CE QUE CE GATE EXISTE POUR ARRÊTER (D-03, WSAW-02, WSAW-04).
#
# Les plans 41.1-02/03/04 ferment le cas d'un compartiment NEUF apparaissant sur le disque : les
# gates l'énumèrent par `vf_ws_enumerate` au lieu de câbler un nom. Ce lint ferme le cas
# SYMÉTRIQUE, que rien ne gardait : un CONSOMMATEUR NEUF, écrit six mois plus tard, qui recode
# `.planning/workstreams/<nom>` ou `.planning/STATE.md` en dur sans que personne ne le voie. La
# forme du défaut est toujours la même — un script correct le jour de son écriture, faux le jour
# où le dépôt se partitionne, et muet entre les deux.
#
# CE QU'IL N'EST PAS. Il ne juge JAMAIS si l'adoption de `vf_ws_enumerate` est CORRECTE : il juge
# si le consommateur est SU. Un chemin présent au recensement avec le statut `exempté` passe le
# lint — c'est délibéré, l'exemption est une décision écrite et relisible, pas un contournement.
# T-41.1-09, disposition `accept` : un consommateur neuf ajouté AVEC sa ligne de recensement dans
# la MÊME PR passe, même si le statut déclaré est faux. Le lint vérifie la PRÉSENCE, jamais la
# véracité du statut — même limite de fond que les gardes G-1/G-2/G-3 (ADR-072) : il rend visible
# et trace, il ne verrouille rien.
#
# DEUX VOLETS, un seul verdict.
#   1. Balayage `.sh` — tout fichier `*.sh` SUIVI par git (`git ls-files`), HORS tout chemin dont
#      un segment est `tests` (une suite a le droit de fabriquer des chemins fautifs, c'est son
#      rôle), qui porte le littéral `.planning/workstreams`, ou `.planning/` suivi sur la MÊME
#      ligne de `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md`. Les lignes de COMMENTAIRE ne sont
#      PAS exclues : un renvoi documentaire est un consommateur potentiel le jour où quelqu'un le
#      transforme en code, et l'exempter demanderait au lint de deviner la nature d'une ligne.
#   2. Balayage `.github/workflows/ci.yml` — le volet 1 ne voit PAS ce fichier, qui est
#      précisément là où vivait l'angle mort d'origine (deux appels de gate câblés sur
#      `workstreams/fiabilite`). Ce volet asserte l'ABSENCE de tout littéral `workstreams/<nom>`
#      pour chaque `<nom>` réellement énuméré par `vf_ws_enumerate` SUR LE DISQUE — les noms ne
#      sont JAMAIS codés en dur ici, même discipline WSAW-01 appliquée récursivement à ce lint.
#
# ÉCHAPPATOIRES, nommées et greppables.
#   - Volet 1, portée LIGNE : le marqueur `vf-allow-unregistered-planning-path` sur la ligne.
#     Réservé au cas où le littéral EST le sujet.
#   - Volet 2, portée RÉGION : la paire `vf-allow-unregistered-planning-path:begin` /
#     `:end`. La granularité est la RÉGION et JAMAIS l'étape : dans `ci.yml`, une fixture jetable
#     qui nomme un compartiment (`mkdir -p "$FIX/.planning/workstreams/dev"`) cohabite avec un
#     bloc qui mesure la RACINE RÉELLE — exempter l'étape entière désarmerait le lint sur l'angle
#     mort qu'il sert. Mesuré le 2026-09-23 avec un compartiment `dev` légitime sur le disque :
#     8 hits dont 6 de fixture, rc=1 — le gate rougissait sur un état légitime, l'inverse exact de
#     WSAW-04. Deux gardes indépendantes bornent l'échappatoire : l'ÉQUILIBRE `begin`/`end`
#     (fail-closed rc=2 sur un marqueur non refermé — sans elle, un `end` retiré fait DISPARAÎTRE
#     le vrai câblage du verdict) et le PLAFOND de lignes exemptées (< 25 % du fichier).
#
# SURCHARGE DE FIXTURE : `VF_CONSUMERS_FILE` désigne un autre fichier de recensement (motif
# `VF_GSD_CORE_LIB` déjà en usage dans le parc). Elle existe pour la preuve par MUTATION — retirer
# une ligne d'une COPIE du recensement et vérifier que le lint rougit. Jamais pour désarmer.
#
# PAS DE `grep` : le `grep` de certains runtimes de dev est proxifié et TRONQUE silencieusement
# (mesuré sur ce poste : 1 ligne rendue sur 91). Tout le balayage passe par `awk`, qui ouvre les
# fichiers lui-même. `LC_ALL=C` rend la lecture bytewise.
#
# Codes de sortie (énumération FERMÉE, aucun implicite) :
#   0 = tout consommateur détecté est recensé, et `ci.yml` ne recode aucun nom de compartiment.
#       Un balayage qui ne trouve AUCUNE référence est un 0 VALIDE : rien à recenser n'est pas un
#       silence, c'est une conformité vide — la garde anti-vert-à-vide porte sur l'UNIVERS, pas
#       sur le nombre de hits.
#   1 = au moins un consommateur non recensé, ou un nom de compartiment recodé en dur dans ci.yml
#   2 = NON VÉRIFIABLE — pas un dépôt git, univers vide, recensement illisible, primitive
#       introuvable, marqueurs déséquilibrés. Jamais un vert : un gate qui n'a pas pu regarder ne
#       se replie pas sur « rien trouvé ».
#   64 = erreur d'usage
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Le recensement est le COMPAGNON DU SCRIPT, jamais un fichier de la cible : sous `--path <fixture>`
# c'est bien le recensement de CE dépôt qui juge la fixture (c'est ce qui rend la bascule de
# fixture possible).
CONSUMERS_DEFAULT="$(cd "$(dirname "$0")/../references" 2>/dev/null && pwd)/workstream-planning-consumers.md"
CONSUMERS="${VF_CONSUMERS_FILE:-$CONSUMERS_DEFAULT}"

usage() {
  cat <<'USAGE'
check-planning-consumers-registered.sh [--path <dir>]

  --path <dir>   Racine à balayer (défaut : la racine du dépôt qui contient ce script).
  -h, --help     Cette aide.

Sortie : 0 = tout consommateur recensé · 1 = consommateur non recensé ou nom de compartiment
recodé en dur dans ci.yml · 2 = non vérifiable · 64 = usage.
Échappatoire volet .sh (portée ligne) : marqueur `vf-allow-unregistered-planning-path`.
Échappatoire volet ci.yml (portée région) : paire `:begin` / `:end` du même marqueur.
Surcharge de fixture : VF_CONSUMERS_FILE=<autre recensement>.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --path) shift; [ $# -gt 0 ] || { echo "[check-planning-consumers-registered] --path attend une valeur" >&2; exit 64; }
            ROOT="$1" ;;
    --path=*) ROOT="${1#--path=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[check-planning-consumers-registered] argument inconnu : $1" >&2; usage >&2; exit 64 ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "[check-planning-consumers-registered] racine introuvable : $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

HATCH="vf-allow-unregistered-planning-path"

[ -r "$CONSUMERS" ] || {
  echo "[check-planning-consumers-registered] recensement illisible : $CONSUMERS — aucune référence de comparaison, NON VÉRIFIABLE" >&2
  exit 2
}

# --- Sourcing de la politique de workstream (plan 41.1-01) — OBLIGATOIRE, fail-closed ----------
# Le volet 2 appelle `vf_ws_enumerate`. Sans ce sourcing la fonction est `command not found`,
# l'univers des noms est vide et le volet anti-câblage-en-dur — qui EST l'angle mort d'origine —
# ne tournerait jamais. Recherche à DEUX candidats, patron `check-divergence.sh`.
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
[ -n "$WS_POLICY" ] \
  || { echo "[check-planning-consumers-registered] workstream-policy.sh introuvable — second balayage ci.yml non exécutable, NON VÉRIFIABLE" >&2; exit 2; }
# shellcheck source=/dev/null
. "$WS_POLICY"

if ! command -v git >/dev/null 2>&1; then
  echo "[check-planning-consumers-registered] git introuvable — univers des fichiers suivis inconnu, NON VÉRIFIABLE" >&2
  exit 2
fi
if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-planning-consumers-registered] $ROOT n'est pas un dépôt git — univers inconnu, NON VÉRIFIABLE" >&2
  exit 2
fi

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
: > "$TMPD/ci_hardcode_hits"

# --- Univers, compté AVANT tout verdict --------------------------------------------------------
# Un `ls-files` vide (dépôt fraîchement initialisé, sous-arbre sans fichier suivi) rendrait
# « 0 violation » et ce serait un vert à vide. Le décompte passe par `tr` et NON par
# `awk -v RS="\0"` : le awk de macOS ne prend pas un NUL comme séparateur d'enregistrement et
# rendrait 1 là où l'univers en compte des centaines.
git -C "$ROOT" ls-files -z -- '*.sh' > "$TMPD/all_z" 2>/dev/null || true
LC_ALL=C tr '\0' '\n' < "$TMPD/all_z" > "$TMPD/all_nl"
N_ALL="$(LC_ALL=C awk 'END { print NR+0 }' "$TMPD/all_nl")"
# Exclusion par SEGMENT, jamais par sous-chaîne : un module nommé `xtests` n'est pas une suite.
LC_ALL=C awk '{ n = split($0, s, "/"); keep = 1; for (i = 1; i <= n; i++) if (s[i] == "tests") keep = 0; if (keep && $0 != "") print }' \
  "$TMPD/all_nl" > "$TMPD/univ_nl"
UNIVERS="$(LC_ALL=C awk 'END { print NR+0 }' "$TMPD/univ_nl")"
if [ "${UNIVERS:-0}" -eq 0 ]; then
  echo "[check-planning-consumers-registered] aucun fichier .sh suivi hors tests/ sous $ROOT ($N_ALL .sh suivi(s) au total) — cible vide, NON VÉRIFIABLE (jamais un vert)" >&2
  exit 2
fi

# --- Volet 1 : balayage des `.sh` --------------------------------------------------------------
LC_ALL=C tr '\n' '\0' < "$TMPD/univ_nl" > "$TMPD/univ_z"
( cd "$ROOT" && xargs -0 awk -v HATCH="$HATCH" '
  index($0, HATCH) > 0 { next }
  FILENAME in seen { next }
  {
    if (index($0, ".planning/workstreams") > 0) { seen[FILENAME] = 1; printf "%s\t%d\n", FILENAME, FNR; next }
    p = index($0, ".planning/")
    if (p > 0) {
      r = substr($0, p)
      if (index(r, "STATE.md") > 0 || index(r, "ROADMAP.md") > 0 || index(r, "REQUIREMENTS.md") > 0) {
        seen[FILENAME] = 1; printf "%s\t%d\n", FILENAME, FNR
      }
    }
  }
' ) < "$TMPD/univ_z" > "$TMPD/hits_raw" 2>/dev/null
LC_ALL=C sort -u "$TMPD/hits_raw" > "$TMPD/hits"
N_HITS="$(LC_ALL=C awk 'END { print NR+0 }' "$TMPD/hits")"

# Ensemble RECENSÉ : première colonne de la table markdown, chemin complet ET basename. Les
# entrées de la table sont des chemins relatifs à la racine ; comparer AUSSI par basename rend le
# recensement robuste à un déplacement de fichier. RISQUE NOTÉ, non traité ici : un futur homonyme
# de basename entre deux scripts distincts masquerait un oubli réel — 0 basename dupliqué mesuré
# sur les 198 `.sh` suivis au 2026-09-24.
# La ligne doit être une VRAIE ligne de la table de recensement : au moins 5 champs (le `|` de
# tête et de queue en produisent deux vides), et une première cellule qui RESSEMBLE à un chemin —
# aucune espace. Sans ces deux filtres, une ligne de table VOISINE (la table des catégories) et
# toute ligne de bloc de code commençant par `|` (une continuation de pipeline) entrent dans
# l'ensemble « recensé » : mesuré le 2026-09-24, 23 entrées au lieu de 21, dont un fragment de
# programme awk. Inoffensif ce jour-là, mais un ensemble de référence pollué peut masquer un oubli.
LC_ALL=C awk -F'|' '
  /^[[:space:]]*\|/ && NF >= 5 {
    c = $2
    gsub(/`/, "", c)
    gsub(/^[ \t]+/, "", c); gsub(/[ \t]+$/, "", c)
    if (c == "" || c == "Chemin") next
    if (c ~ /^-+$/) next
    if (c ~ /[[:space:]]/) next
    print c
    n = split(c, s, "/"); if (n > 1) print s[n]
  }
' "$CONSUMERS" | LC_ALL=C sort -u > "$TMPD/registered"
N_REG="$(LC_ALL=C awk 'END { print NR+0 }' "$TMPD/registered")"
if [ "$N_REG" -eq 0 ]; then
  echo "[check-planning-consumers-registered] $CONSUMERS ne porte AUCUNE ligne de table exploitable — référence vide, NON VÉRIFIABLE" >&2
  exit 2
fi

LC_ALL=C awk -F'\t' '
  NR == FNR { reg[$0] = 1; next }
  {
    path = $1
    n = split(path, s, "/"); base = s[n]
    if (!(path in reg) && !(base in reg)) printf "%s:%s\n", path, $2
  }
' "$TMPD/registered" "$TMPD/hits" > "$TMPD/sh_missing"
N_MISSING="$(LC_ALL=C awk 'END { print NR+0 }' "$TMPD/sh_missing")"

rc_final=0

# --- Volet 2 : ci.yml ne doit jamais recoder un nom de compartiment en dur ---------------------
# Les noms viennent du DISQUE (`vf_ws_enumerate` sur CE dépôt), jamais codés en dur ici. Les deux
# volets sont ancrés sur `$ROOT` — sinon, sous `--path <fixture>`, le volet 1 jugerait la fixture
# pendant que le volet 2 jugerait le dépôt réel, et un rc=1 ne serait imputable à aucun des deux.
CI_FILE="$ROOT/.github/workflows/ci.yml"
CI_REL=".github/workflows/ci.yml"
CI_SCANNED="non (absent)"
if [ -f "$CI_FILE" ]; then
  CI_SCANNED="oui"
  ws_enum_rc=0
  # La primitive est appelée HORS pipeline et redirigée vers un fichier : dans
  # `x="$(prim | while …)"` le rc capturé est celui du `while` (toujours 0 sans `pipefail` actif
  # sur la substitution), jamais celui de la primitive.
  vf_ws_enumerate "$ROOT/.planning" > "$TMPD/ws_dirs" 2>"$TMPD/ws_err" || ws_enum_rc=$?
  : > "$TMPD/ws_names"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    basename "$d" >> "$TMPD/ws_names"
  done < "$TMPD/ws_dirs"
  N_WS_NAMES="$(LC_ALL=C awk 'NF' "$TMPD/ws_names" | LC_ALL=C awk 'END { print NR+0 }')"
  if [ "$N_WS_NAMES" -eq 0 ]; then
    echo "[check-planning-consumers-registered] volet ci.yml : vf_ws_enumerate $ROOT/.planning n'a rendu AUCUN nom (rc=$ws_enum_rc) — univers vide, volet NON VÉRIFIABLE, jamais un 0 silencieux" >&2
    LC_ALL=C awk '{ print "  " $0 }' "$TMPD/ws_err" >&2
    echo "NON-VERIFIABLE:univers-vide" >> "$TMPD/ci_hardcode_hits"
    rc_final=2
  else
    ws_fixt_bal=0
    LC_ALL=C awk -v H="$HATCH" '
      index($0, H ":begin") > 0 { if (open) { bad++ } open = 1; next }
      index($0, H ":end") > 0 { if (!open) { bad++ } open = 0; next }
      END { if (open || bad) exit 1 }
    ' "$CI_FILE" || ws_fixt_bal=$?
    if [ "$ws_fixt_bal" -ne 0 ]; then
      echo "[check-planning-consumers-registered] volet ci.yml : marqueurs de fixture jetable DÉSÉQUILIBRÉS (begin/end) — l'échappatoire exempterait une région non bornée, NON VÉRIFIABLE" >&2
      echo "NON-VERIFIABLE:marqueurs-desequilibres" >> "$TMPD/ci_hardcode_hits"
      rc_final=2
    else
      N_CI_TOT="$(LC_ALL=C awk 'END { print NR+0 }' "$CI_FILE")"
      N_CI_EX="$(LC_ALL=C awk -v H="$HATCH" '
        index($0, H ":begin") > 0 { fixt = 1; next }
        index($0, H ":end") > 0 { fixt = 0; next }
        fixt { c++ } END { print c+0 }
      ' "$CI_FILE")"
      # Plafond exprimé en MULTIPLICATION, jamais en division entière : `N_CI_EX >= N_CI_TOT / 4`
      # rend `>= 0` dès que le fichier fait moins de 4 lignes, donc VRAI toujours — une fixture de
      # quelques lignes sortirait en 2 alors qu'elle est conforme. `4 * exemptées >= total` dit la
      # même chose sans jamais arrondir.
      if [ "$N_CI_TOT" -gt 0 ] && [ $((N_CI_EX * 4)) -ge "$N_CI_TOT" ]; then
        echo "[check-planning-consumers-registered] volet ci.yml : $N_CI_EX ligne(s) exemptée(s) sur $N_CI_TOT — l'échappatoire avale plus du quart du fichier, NON VÉRIFIABLE" >&2
        echo "NON-VERIFIABLE:plafond-exemption" >> "$TMPD/ci_hardcode_hits"
        rc_final=2
      else
        while IFS= read -r name; do
          [ -n "$name" ] || continue
          LC_ALL=C awk -v n="$name" -v f="$CI_REL" -v H="$HATCH" '
            index($0, H ":begin") > 0 { fixt = 1; next }
            index($0, H ":end") > 0 { fixt = 0; next }
            fixt { next }
            $0 ~ /^[[:space:]]*#/ { next }
            index($0, "workstreams/" n) > 0 { print f ":" NR ":" n }
          ' "$CI_FILE" >> "$TMPD/ci_hardcode_hits" || true
        done < "$TMPD/ws_names"
      fi
    fi
  fi
fi

if [ -s "$TMPD/ci_hardcode_hits" ] && [ "$rc_final" -ne 2 ]; then
  echo "[check-planning-consumers-registered] ✗ $CI_REL recode un nom de compartiment en dur (hors commentaire, hors région de fixture) :" >&2
  LC_ALL=C awk '{ print "  " $0 }' "$TMPD/ci_hardcode_hits" >&2
  rc_final=1
fi

if [ "$N_MISSING" -gt 0 ]; then
  echo "[check-planning-consumers-registered] ✗ $N_MISSING script(s) référencent un chemin d'artefact de planning SANS figurer au recensement :" >&2
  LC_ALL=C awk '{ print "  " $0 }' "$TMPD/sh_missing" >&2
  [ "$rc_final" -ne 2 ] && rc_final=1
fi

if [ "$rc_final" -eq 0 ]; then
  echo "[check-planning-consumers-registered] ✓ $UNIVERS .sh suivi(s) hors tests/ balayé(s) ($N_ALL au total), $N_HITS consommateur(s) détecté(s), tous recensés ; volet ci.yml : $CI_SCANNED"
  exit 0
fi

cat >&2 <<USAGE_KO

Univers balayé : $UNIVERS fichier(s) .sh suivi(s) hors tests/ sous $ROOT.
Recensement : $CONSUMERS ($N_REG entrée(s) exploitable(s)).
Corriger, dans cet ordre de préférence :
  1. faire consommer \`vf_ws_enumerate\` au script (plan 41.1-01) et l'inscrire au recensement
     avec la catégorie a1 et le statut \`via-primitive\` ;
  2. si le script résout délibérément le compartiment ACTIF (outil d'agent, jamais un gate CI
     multi-compartiments), l'inscrire \`exempté\` avec ce motif ;
  3. si le littéral EST le sujet (fixture, message cité), poser le marqueur \`$HATCH\` sur la
     ligne — explicite et greppable ;
  4. dans $CI_REL, borner la région de FIXTURE JETABLE par la paire \`$HATCH:begin\` /
     \`$HATCH:end\` — la région, JAMAIS l'étape.
USAGE_KO
exit "$rc_final"
