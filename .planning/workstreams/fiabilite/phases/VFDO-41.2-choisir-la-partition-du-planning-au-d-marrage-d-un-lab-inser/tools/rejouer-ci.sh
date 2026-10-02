#!/usr/bin/env bash
# rejouer-ci.sh — outil de RECETTE de la Phase 41.2 (hors distribution, jamais appelé par la CI).
# Rejoue les étapes `run:` d'un job de .github/workflows/ci.yml dans un clone jetable du dépôt et,
# sous --compare, compare deux textes de ci.yml (avant/après) étape par étape.
#
# USAGE
#   rejouer-ci.sh --job <job> [--step <préfixe de nom d'étape>] [--ci-ref <ref>] [--lib <fichier>]
#                 [--compare <ref-a> <ref-b>] [--out <dir>] [-h]
#   --job      job de ci.yml à rejouer (obligatoire)
#   --step     ne rejoue que les étapes dont le nom commence par ce préfixe
#   --ci-ref   ref dont on lit ci.yml (git show <ref>:.github/workflows/ci.yml), défaut HEAD
#   --lib      fichier copié sur plugin/conductor/scripts/fanout-state-integrity.sh DANS LE CLONE seulement
#   --compare  rejoue l'étape filtrée une fois par texte de ci.yml, chacun dans son clone neuf
#   --out      dossier de sortie (défaut : mktemp -d)
#
# EXÉCUTION
#   Clone `git clone -q --no-hardlinks` de la racine du dépôt (HEAD commité, jamais l'arbre de
#   travail ; aucune commande git d'écriture sur le dépôt). Étapes extraites par python3 + yaml.
#   `uses:` ignorées (le clone tient lieu de checkout). `if:` => ETAPE-SAUTEE. `run:` contenant
#   sudo, apt-get, npx ou --global => ETAPE-REFUSEE (jamais d'installation sur le poste). Chaque
#   `run:` est exécuté par `bash --noprofile --norc -e` à la racine du clone, sous
#   `env -u GSD_WORKSTREAM`, HOME jetable, GITHUB_WORKSPACE = racine du clone, GITHUB_ENV émulé
#   (lignes CLE=valeur exportées avant chaque étape suivante).
#
# CONTRAT DE SORTIE (fixé ; consommé tel quel par 41.2-02 tâche 2 et par la clôture 41.2-06)
#   Disposition déterministe sous <out> : clone à <out>/clone (sous --compare : <out>/a/clone et
#   <out>/b/clone, journaux sous <out>/a/ et <out>/b/). Pour chaque étape EXÉCUTÉE : journal brut
#   <out>/<job>/<NN>-<slug>.log et journal normalisé <out>/<job>/<NN>-<slug>.norm (sous --compare,
#   <out>/a/<job>/… et <out>/b/<job>/…). <NN> = rang de l'étape dans `steps:` du job (deux
#   chiffres, à partir de 01, étapes `uses:` comprises) ; <slug> = nom en minuscules, toute suite
#   hors [a-z0-9] remplacée par `-`, tronqué à 60 caractères.
#   stdout, dans l'ordre : une ligne par étape retenue — `ETAPE rc=<n> <nom>` (exécutée),
#   `ETAPE-SAUTEE <nom>` (if: ou uses:), `ETAPE-REFUSEE <nom>` (installation) ; puis, une par étape
#   exécutée, `JOURNAL <chemin .log>` et `NORMALISE <chemin .norm>` ; sous --compare, les lignes de
#   a puis de b, et une dernière ligne `COMPARE identique` ou `COMPARE ecart <NN>`.
#   Normalisation : chemins issus de mktemp => <TMP>, racine du clone => <CLONE>, empreintes git de
#   40 hexadécimaux => <SHA>, horodatages ISO => <TS>. Ne jamais élargir la normalisation pour
#   effacer un écart réel : un écart résiduel est un changement de comportement à remonter.
#   Un rouge ENVIRONNEMENTAL (réseau, npx, durée, outil absent du poste) est rendu tel quel
#   (rc != 0, journal conservé) : aucune catégorie « toléré », aucun consommateur ne le requalifie.
#
# CODES : 0 = au moins une étape exécutée et toutes à rc 0 (sous --compare : mêmes rc et cmp -s des
#   journaux normalisés) ; 1 = une étape rc != 0 ou un écart ; 2 = aucune étape exécutée, job ou
#   ref introuvable, YAML illisible ; 64 = usage.

JOB="" STEP="" CIREF="HEAD" LIB="" OUT="" CMPA="" CMPB="" COMPARE=0

usage() { sed -n '2,/^# CODES/p' "$0" | sed 's/^# \{0,1\}//' >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --job) [ $# -ge 2 ] || { usage; exit 64; }; JOB="$2"; shift 2 ;;
    --step) [ $# -ge 2 ] || { usage; exit 64; }; STEP="$2"; shift 2 ;;
    --ci-ref) [ $# -ge 2 ] || { usage; exit 64; }; CIREF="$2"; shift 2 ;;
    --lib) [ $# -ge 2 ] || { usage; exit 64; }; LIB="$2"; shift 2 ;;
    --compare) [ $# -ge 3 ] || { usage; exit 64; }; COMPARE=1; CMPA="$2"; CMPB="$3"; shift 3 ;;
    --out) [ $# -ge 2 ] || { usage; exit 64; }; OUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "option inconnue : $1" >&2; usage; exit 64 ;;
  esac
done
[ -n "$JOB" ] || { echo "--job est obligatoire" >&2; usage; exit 64; }
if [ -n "$LIB" ] && [ ! -f "$LIB" ]; then echo "--lib : fichier introuvable : $LIB" >&2; exit 2; fi
[ -z "$LIB" ] || LIB="$(cd "$(dirname "$LIB")" && pwd -P)/$(basename "$LIB")"

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "hors d'un dépôt git" >&2; exit 2; }
[ -n "$OUT" ] || OUT="$(mktemp -d)"
mkdir -p "$OUT" || exit 2
OUT="$(cd "$OUT" && pwd -P)"

# run_side <ref ci.yml> <dossier de côté> -> écrit stdout (lignes), pose SIDE_RC et SIDE_STEPS
run_side() {
  local ref="$1" side="$2" yml stepdir i n nn slug name run rc line f
  local envfile logd cloneroot
  mkdir -p "$side" || return 2
  yml="$side/ci.yml"
  git -C "$REPO" show "$ref:.github/workflows/ci.yml" > "$yml" 2>/dev/null || { echo "ref ou ci.yml introuvable : $ref" >&2; return 2; }
  stepdir="$side/_steps"; rm -rf "$stepdir"; mkdir -p "$stepdir"
  CI_YML="$yml" CI_JOB="$JOB" CI_STEP="$STEP" CI_DIR="$stepdir" python3 - <<'PY' || { echo "YAML illisible ou job introuvable : $JOB" >&2; return 2; }
import os, re, sys, yaml
d = yaml.safe_load(open(os.environ["CI_YML"], encoding="utf-8"))
job = d["jobs"][os.environ["CI_JOB"]]
pref = os.environ.get("CI_STEP", "")
out = os.environ["CI_DIR"]
steps = job.get("steps") or []
for i, s in enumerate(steps, 1):
    name = s.get("name") or (s.get("uses") or (s.get("run") or "").strip().split("\n")[0])
    if pref and not str(name).startswith(pref):
        continue
    nn = "%02d" % i
    slug = re.sub(r"[^a-z0-9]+", "-", str(name).lower())[:60]
    def w(ext, txt):
        open(os.path.join(out, nn + "." + ext), "w", encoding="utf-8").write(txt)
    w("name", str(name)); w("slug", slug)
    if "if" in s: w("if", "1")
    if "uses" in s and "run" not in s: w("uses", "1")
    if "run" in s: w("run", s["run"])
PY
  cloneroot="$side/clone"
  rm -rf "$cloneroot"
  git clone -q --no-hardlinks "$REPO" "$cloneroot" || { echo "clone impossible" >&2; return 2; }
  cloneroot="$(cd "$cloneroot" && pwd -P)"
  if [ -n "$LIB" ]; then cp "$LIB" "$cloneroot/plugin/conductor/scripts/fanout-state-integrity.sh" || return 2; fi
  envfile="$side/github_env"; : > "$envfile"
  logd="$side/$JOB"; mkdir -p "$logd"
  mkdir -p "$side/home"
  SIDE_RC=0; SIDE_STEPS=0; SIDE_LIST=""
  local reportlines="" journals=""
  for f in $(ls "$stepdir" | grep '\.name$' | sort); do
    nn="${f%.name}"
    name="$(cat "$stepdir/$nn.name")"; slug="$(cat "$stepdir/$nn.slug")"
    if [ -f "$stepdir/$nn.if" ] || [ -f "$stepdir/$nn.uses" ] || [ ! -f "$stepdir/$nn.run" ]; then
      reportlines="${reportlines}ETAPE-SAUTEE $name
"; continue
    fi
    if grep -Eq 'sudo|apt-get|npx|--global' "$stepdir/$nn.run"; then
      reportlines="${reportlines}ETAPE-REFUSEE $name
"; continue
    fi
    local -a xenv=()
    while IFS= read -r line; do
      case "$line" in *=*) xenv+=("$line") ;; esac
    done < "$envfile"
    ( cd "$cloneroot" && env -u GSD_WORKSTREAM HOME="$side/home" GITHUB_WORKSPACE="$cloneroot" \
        GITHUB_ENV="$envfile" ${xenv[@]+"${xenv[@]}"} bash --noprofile --norc -e "$stepdir/$nn.run" ) \
      > "$logd/$nn-$slug.log" 2>&1
    rc=$?
    sed -E \
      -e "s#$(printf '%s' "$cloneroot" | sed 's/[.[\*^$#]/\\&/g')#<CLONE>#g" \
      -e "s#$(printf '%s' "$side" | sed 's/[.[\*^$#]/\\&/g')#<TMP>#g" \
      -e "s#(/private)?/var/folders/[0-9A-Za-z_]+/[0-9A-Za-z_]+/T/(tmp\\.)?[0-9A-Za-z]+#<TMP>#g" \
      -e "s#(/private)?/tmp/(tmp\\.)?[0-9A-Za-z]+#<TMP>#g" \
      -e 's#[0-9a-f]{40}#<SHA>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}([.,][0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?#<TS>#g' \
      "$logd/$nn-$slug.log" > "$logd/$nn-$slug.norm"
    reportlines="${reportlines}ETAPE rc=$rc $name
"
    journals="${journals}JOURNAL $logd/$nn-$slug.log
NORMALISE $logd/$nn-$slug.norm
"
    SIDE_STEPS=$((SIDE_STEPS + 1))
    SIDE_LIST="$SIDE_LIST $nn:$rc"
    [ "$rc" -eq 0 ] || SIDE_RC=1
  done
  printf '%s' "$reportlines"
  printf '%s' "$journals"
  return 0
}

if [ "$COMPARE" -eq 0 ]; then
  run_side "$CIREF" "$OUT" || exit 2
  [ "$SIDE_STEPS" -ge 1 ] || { echo "aucune étape exécutée" >&2; exit 2; }
  exit "$SIDE_RC"
fi

run_side "$CMPA" "$OUT/a" || exit 2
A_RC=$SIDE_RC; A_N=$SIDE_STEPS; A_LIST="$SIDE_LIST"
run_side "$CMPB" "$OUT/b" || exit 2
B_RC=$SIDE_RC; B_N=$SIDE_STEPS; B_LIST="$SIDE_LIST"
[ "$A_N" -ge 1 ] && [ "$B_N" -ge 1 ] || { echo "aucune étape exécutée" >&2; exit 2; }
ECART=""
if [ "$A_LIST" != "$B_LIST" ]; then
  ECART="$(printf '%s\n' $A_LIST | head -1 | cut -d: -f1)"; [ -n "$ECART" ] || ECART="00"
else
  for pair in $A_LIST; do
    nn="${pair%%:*}"
    na="$(ls "$OUT/a/$JOB/$nn-"*.norm 2>/dev/null | head -1)"
    nb="$(ls "$OUT/b/$JOB/$nn-"*.norm 2>/dev/null | head -1)"
    if [ -z "$na" ] || [ -z "$nb" ] || ! cmp -s "$na" "$nb"; then ECART="$nn"; break; fi
  done
fi
if [ -z "$ECART" ]; then
  echo "COMPARE identique"
  [ "$A_RC" -eq 0 ] && [ "$B_RC" -eq 0 ] && exit 0
  exit 1
fi
echo "COMPARE ecart $ECART"
exit 1
