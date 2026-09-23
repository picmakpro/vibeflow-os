#!/usr/bin/env bash
# replay-ci-jobs.sh — Phase 40.1. Rejoue localement les jobs `tests` et `gates` de
# .github/workflows/ci.yml, en extrayant leurs étapes DEPUIS le fichier lui-même (aucune liste
# recopiée). Parsing en awk uniquement (aucun grep). Fidèle au shell du runner : chaque étape est
# lancée en `bash --noprofile --norc -e`, jamais `-o pipefail` (aucun `shell:` déclaré dans ce
# ci.yml, donc le défaut du runner GitHub s'applique : bash -e, sans pipefail).
#
# Usage : replay-ci-jobs.sh --job tests|gates [--root DIR] [--ci-file F] [--step PREFIXE] [--list]
#
# Codes de sortie : 0 = toutes les étapes rejouées sont vertes ; 1 = au moins une en échec ;
# 2 = fichier CI illisible, job absent, ou ZÉRO étape rejouée (une sélection vide n'est jamais un
# vert, F13).
set -u

JOB=""
ROOT=""
CI_FILE=""
STEP_FILTER=""
LIST_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --job) JOB="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    --ci-file) CI_FILE="$2"; shift 2 ;;
    --step) STEP_FILTER="$2"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    *) echo "ERREUR: option inconnue: $1" >&2; exit 2 ;;
  esac
done

if [ "$JOB" != "tests" ] && [ "$JOB" != "gates" ]; then
  echo "ERREUR: --job tests|gates requis" >&2
  exit 2
fi

if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
fi
if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  echo "ERREUR: racine introuvable" >&2
  exit 2
fi

if [ -z "$CI_FILE" ]; then
  CI_FILE="$ROOT/.github/workflows/ci.yml"
fi
if [ ! -f "$CI_FILE" ] || [ ! -r "$CI_FILE" ]; then
  echo "ERREUR: fichier CI illisible: $CI_FILE" >&2
  exit 2
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# Journal par étape : dossier CONSERVÉ (pas de trap), imprimé, pour que la clôture puisse relire
# les bilans internes des étapes après coup.
LOGDIR="$(mktemp -d)"
if [ "$LIST_ONLY" -ne 1 ]; then
  echo "journal des etapes : $LOGDIR"
fi

AWKFILE="$WORKDIR/parse.awk"
cat > "$AWKFILE" <<'AWKEOF'
BEGIN {
  injob = 0
  stepidx = 0
  in_step = 0
  collecting_run = 0
  run_first_indent = -1
}

function flush_step(   metafile, runfile, i) {
  if (!in_step) return
  metafile = OUTDIR "/step_" stepidx ".meta"
  runfile = OUTDIR "/step_" stepidx ".run"
  print cur_name "\037" has_if "\037" cur_if "\037" has_uses "\037" run_mode > metafile
  close(metafile)
  printf "" > runfile
  for (i = 1; i <= run_lines_count; i++) {
    print run_lines[i] >> runfile
  }
  close(runfile)
  in_step = 0
}

function start_step() {
  flush_step()
  stepidx++
  in_step = 1
  collecting_run = 0
  run_first_indent = -1
  cur_name = ""
  cur_if = ""
  has_if = 0
  has_uses = 0
  run_mode = "none"
  run_lines_count = 0
  delete run_lines
}

function process_field(text) {
  if (match(text, /^name:[ \t]*/)) { cur_name = substr(text, RLENGTH + 1); return }
  if (match(text, /^if:[ \t]*/)) { has_if = 1; cur_if = substr(text, RLENGTH + 1); return }
  if (match(text, /^uses:[ \t]*/)) { has_uses = 1; return }
  if (match(text, /^run:[ \t]*\|[ \t]*$/)) { run_mode = "block"; collecting_run = 1; run_first_indent = -1; return }
  if (match(text, /^run:[ \t]*/)) { run_mode = "line"; run_lines_count = 1; run_lines[1] = substr(text, RLENGTH + 1); return }
}

{
  line = $0
  match(line, /^ */)
  indent = RLENGTH
  rest = substr(line, indent + 1)

  if (indent == 2 && match(rest, /^[A-Za-z0-9_-]+:[ \t]*$/)) {
    keyname = rest
    sub(/:[ \t]*$/, "", keyname)
    if (injob) { flush_step(); injob = 0 }
    if (keyname == JOB) { injob = 1 }
    next
  }

  if (!injob) next

  if (collecting_run) {
    if (line ~ /^[ \t]*$/) {
      if (run_first_indent >= 0) { run_lines_count++; run_lines[run_lines_count] = "" }
      next
    }
    if (run_first_indent == -1) { run_first_indent = indent }
    if (indent >= run_first_indent) {
      run_lines_count++
      run_lines[run_lines_count] = substr(line, run_first_indent + 1)
      next
    }
    collecting_run = 0
  }

  if (line ~ /^[ \t]*$/) next

  if (indent == 6 && rest ~ /^- /) {
    start_step()
    process_field(substr(rest, 3))
    next
  }

  if (!in_step) next

  if (indent == 8) {
    process_field(rest)
    next
  }
  next
}

END {
  flush_step()
  print stepidx > (OUTDIR "/count")
  close(OUTDIR "/count")
}
AWKEOF

OUTDIR="$WORKDIR/steps"
mkdir -p "$OUTDIR"
awk -v JOB="$JOB" -v OUTDIR="$OUTDIR" -f "$AWKFILE" "$CI_FILE"

COUNT_FILE="$OUTDIR/count"
if [ ! -f "$COUNT_FILE" ]; then
  echo "ERREUR: extraction impossible (parsing awk en echec)" >&2
  exit 2
fi
NSTEPS=$(awk 'NR==1{print $1+0}' "$COUNT_FILE")

REJOUEE=0
SAUTEE=0
ECHEC=0
i=1
while [ "$i" -le "$NSTEPS" ]; do
  META="$OUTDIR/step_${i}.meta"
  RUNFILE="$OUTDIR/step_${i}.run"
  NAME=""
  HAS_IF=0
  IF_EXPR=""
  HAS_USES=0
  RUN_MODE="none"
  if [ -f "$META" ]; then
    IFS=$'\x1f' read -r NAME HAS_IF IF_EXPR HAS_USES RUN_MODE < "$META"
  fi

  DISPOSITION=""
  REASON=""
  if [ "$JOB" = "tests" ]; then
    if [ "$NAME" = "Découvrir et lancer toutes les suites" ]; then
      DISPOSITION="REJOUEE"
    else
      DISPOSITION="SAUTEE"
      REASON="SAUTEE (installation/infra du runner)"
    fi
  else
    if [ "$HAS_USES" -eq 1 ]; then
      DISPOSITION="SAUTEE"
      REASON="SAUTEE (action)"
    elif [ "$HAS_IF" -eq 1 ]; then
      DISPOSITION="SAUTEE"
      REASON="SAUTEE (conditionnelle : $IF_EXPR)"
    elif [ "$RUN_MODE" != "none" ]; then
      DISPOSITION="REJOUEE"
    else
      DISPOSITION="SAUTEE"
      REASON="SAUTEE (aucune commande run)"
    fi
  fi

  if [ -n "$STEP_FILTER" ]; then
    case "$NAME" in
      "$STEP_FILTER"*) : ;;
      *)
        DISPOSITION="SAUTEE"
        REASON="SAUTEE (hors filtre --step)"
        ;;
    esac
  fi

  if [ "$LIST_ONLY" -eq 1 ]; then
    if [ "$DISPOSITION" = "REJOUEE" ]; then
      echo "REJOUERA | $NAME"
    else
      echo "$REASON | $NAME"
    fi
    i=$((i + 1))
    continue
  fi

  if [ "$DISPOSITION" != "REJOUEE" ]; then
    echo "$REASON | $NAME"
    SAUTEE=$((SAUTEE + 1))
    i=$((i + 1))
    continue
  fi

  STEPFILE="$WORKDIR/run_${i}.sh"
  if [ -f "$RUNFILE" ]; then
    cp "$RUNFILE" "$STEPFILE"
  else
    printf '' > "$STEPFILE"
  fi
  LOGFILE="$LOGDIR/step_${i}.log"

  echo "--- debut $NAME ---"
  RC=0
  (cd "$ROOT" && bash --noprofile --norc -e "$STEPFILE") > "$LOGFILE" 2>&1
  RC=$?
  cat "$LOGFILE"
  echo "--- fin $NAME ---"
  echo "REJEU $JOB | $i | rc=$RC | $NAME"
  echo "(journal : $LOGFILE)"

  REJOUEE=$((REJOUEE + 1))
  if [ "$RC" -ne 0 ]; then
    ECHEC=$((ECHEC + 1))
  fi

  i=$((i + 1))
done

if [ "$LIST_ONLY" -eq 1 ]; then
  exit 0
fi

echo "BILAN REJEU $JOB : $REJOUEE rejouee(s), $SAUTEE sautee(s), $ECHEC en echec"

if [ "$REJOUEE" -eq 0 ]; then
  exit 2
fi
if [ "$ECHEC" -gt 0 ]; then
  exit 1
fi
exit 0
