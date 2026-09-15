#!/usr/bin/env bash
# check-instruction-budget.sh — mesure et publie, par fichier d'agent distribue, deux metriques
# (lignes du fichier entier, instructions du body) comparees a une baseline en ratchet
# (BUDG-01, BUDG-02, ADR-029).
#
# Role (ADR-031) : ce gate CONSTATE un depassement de baseline ou de plafond ; il ne reecrit,
# reformate ni allege JAMAIS un fichier d'agent, et il n'ecrit ni la sentinelle ni la baseline —
# les deux sont LUES seulement (D-04, meme mecanisme que check-requirements-survival.sh). Aucun
# marqueur d'exclusion par ligne n'est introduit : sur un ratchet non encore arme, une echappatoire
# par ligne ferait baisser un compte sans faire baisser la charge reelle.
#
# Decouverte (D-03) : glob a UN SEUL NIVEAU, plugin/*/agents/*.md + plugin/*/AGENT.md — jamais un
# find recursif, qui capturerait bien plus de fichiers que le corpus d'agents distribues.
#
# Reconciliation des codes de sortie : .planning/codebase/CONVENTIONS.md:56 normalise 2=erreur
# d'usage et 3=INDETERMINE, alors que les deux precedents DIRECTS de ce gate font l'inverse
# (check-divergence.sh : 2=non verifiable / 3=silence ; check-requirements-survival.sh :
# 3=non arme / 64=usage). Ce script suit ses deux precedents plutot que la convention generale du
# depot : 64 reste reserve a l'erreur d'usage, jamais 2.
#
# Usage:
#   check-instruction-budget.sh [--path <dir>]
#
# Exit codes (contrat interne, tous enumeres, aucun implicite — patron check-divergence.sh) :
#   0  = ARME et aucun depassement (conforme)
#   1  = ARME et au moins un depassement de baseline (lignes, instructions, ou plafond ADR-029)
#   2  = NON VERIFIABLE — decouverte vide, fichier imparsable, ou contrat de baseline incoherent ;
#        toujours bloquant, arme ou non
#   3  = NON ARME — rapport imprime integralement, jamais bloquant (D-04, avertissement audible,
#        anti-feature .planning/REQUIREMENTS.md:1096 : jamais de blocage CI dur immediat)
#   64 = erreur d'usage (argument inconnu, --path sans valeur, ou --path vers un chemin inexistant)
#
# Surcharges d'environnement — POUR LES FIXTURES DE TEST UNIQUEMENT ; toute invocation de
# production (CI, hook, humain) les laisse absentes :
#   VF_BUDGET_PLANNING_DIR   — redirige le dossier .planning (sentinelle + baseline)
#   VF_BUDGET_BASELINE_FILE  — redirige le chemin du fichier de baselines
set -uo pipefail

ROOT="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-instruction-budget] --path necessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-instruction-budget] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Un --path vers un repertoire inexistant est une erreur d'USAGE (64). Un --path vers un
# repertoire qui existe mais ne contient aucun plugin/ retombe sur la decouverte vide (2) plus
# bas — ce n'est pas la meme faute : l'un est mal appele, l'autre n'a simplement rien a montrer.
if [ ! -d "$ROOT" ]; then
  echo "[check-instruction-budget] --path introuvable : $ROOT" >&2
  exit 64
fi
ROOT="${ROOT%/}"
[ -n "$ROOT" ] || ROOT="/"

PLANNING_DIR="${VF_BUDGET_PLANNING_DIR:-$ROOT/.planning}"
SENTINEL="$PLANNING_DIR/.instruction-budget-armed"
BASELINE="${VF_BUDGET_BASELINE_FILE:-$PLANNING_DIR/instruction-budget-baselines.tsv}"

# Plafond ADR-029 (charte de densite : agents <= 250 lignes). Arme par la MEME sentinelle que la
# baseline (D-05) : la limite effective de lignes d'un fichier est le plus petit de sa baseline et
# de cette constante. Une baseline de lignes superieure a 250 ne peut jamais legaliser un
# depassement par simple mesure — voir verdict DEPASSEMENT-ADR029 plus bas, qui prime toujours sur
# la comparaison a la baseline.
VF_BUDGET_LINE_CAP=250

# Marqueurs D-01, verses au gate tels quels, insensibles a la casse (tolower() cote awk).
MARKER_RE='jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire'
# Titres qui ROUVRENT le scope "puce imperative" — Claude's Discretion (D-01, forme mesuree).
RULES_TITLE_RE='r[eè]gles|garde-fous|iron law|anti-pattern|lignes rouges|discipline'

# --- Zone temporaire (fichiers de travail, jamais le depot) ------------------------------------
TMPD="$(mktemp -d)" || { echo "[check-instruction-budget] mktemp -d a echoue — non verifiable" >&2; exit 2; }
trap 'rm -rf "$TMPD"' EXIT

# --- Decouverte, glob a UN SEUL NIVEAU (D-03) ---------------------------------------------------
FILES_LIST="$TMPD/files"
: > "$FILES_LIST"
for f in "$ROOT"/plugin/*/agents/*.md; do
  [ -f "$f" ] || continue
  rel="${f#"$ROOT"/}"
  printf '%s\n' "$rel" >> "$FILES_LIST"
done
for f in "$ROOT"/plugin/*/AGENT.md; do
  [ -f "$f" ] || continue
  rel="${f#"$ROOT"/}"
  printf '%s\n' "$rel" >> "$FILES_LIST"
done
LC_ALL=C sort -u "$FILES_LIST" -o "$FILES_LIST"

FOUND=$(awk 'END{print NR}' "$FILES_LIST" 2>/dev/null || echo 0)
[ -n "$FOUND" ] || FOUND=0
if [ "$FOUND" -eq 0 ]; then
  echo "[check-instruction-budget] aucun fichier d'agent distribue decouvert — non verifiable" >&2
  exit 2
fi

ARMED=0
[ -f "$SENTINEL" ] && ARMED=1

# --- Baseline : LUE, jamais ecrite (D-04, meme mecanisme que check-requirements-survival.sh) ---
BASELINE_MISSING=1
BASELINE_ROWS=0
BASELINE_CLEAN="$TMPD/baseline-clean"
: > "$BASELINE_CLEAN"
if [ -f "$BASELINE" ]; then
  BASELINE_MISSING=0
  awk 'NF==0{next} /^#/{next} {print}' "$BASELINE" > "$BASELINE_CLEAN" 2>/dev/null || : > "$BASELINE_CLEAN"
  BASELINE_ROWS=$(awk 'END{print NR}' "$BASELINE_CLEAN" 2>/dev/null || echo 0)
  [ -n "$BASELINE_ROWS" ] || BASELINE_ROWS=0
fi

# --- Entrees orphelines : un chemin de baseline sans fichier decouvert correspondant ------------
ORPHAN_COUNT=0
ORPHANS="$TMPD/orphans"
: > "$ORPHANS"
if [ "$BASELINE_ROWS" -gt 0 ]; then
  BASELINE_PATHS="$TMPD/baseline-paths"
  awk -F'\t' '{print $1}' "$BASELINE_CLEAN" | LC_ALL=C sort -u > "$BASELINE_PATHS"
  comm -23 "$BASELINE_PATHS" "$FILES_LIST" > "$ORPHANS" 2>/dev/null || : > "$ORPHANS"
  ORPHAN_COUNT=$(awk 'END{print NR}' "$ORPHANS" 2>/dev/null || echo 0)
  [ -n "$ORPHAN_COUNT" ] || ORPHAN_COUNT=0
fi

frontmatter_state() { # <file> -> "open" | "closed" | "none"
  # F2 (revue vague 1) : le PREMIER '---' n'ouvre le frontmatter que s'il est a NR==1. Un fichier
  # SANS frontmatter reel (son body est le fichier entier) ne doit jamais voir deux '---' isoles
  # plus loin dans le corps etre pris pour une paire d'ouverture/fermeture — sinon le contenu entre
  # les deux disparait du comptage en silence.
  awk '
    NR==1 && /^---[[:space:]]*$/ { started=1; infm=1; next }
    infm && /^---[[:space:]]*$/ { infm=0; closed=1; next }
    END {
      if (!started) { print "none" }
      else if (closed) { print "closed" }
      else { print "open" }
    }
  ' "$1" 2>/dev/null
}

body_only() { # <file> -> body sur stdout, frontmatter exclu (derive de check-divergence.sh)
  # F2 : meme ancrage NR==1 que frontmatter_state() — les deux fonctions doivent s'accorder sur
  # ce qui compte comme frontmatter, sinon l'une exclut ce que l'autre inclut.
  awk '
    NR==1 && /^---[[:space:]]*$/ { infm=1; next }
    infm && /^---[[:space:]]*$/ { infm=0; next }
    infm { next }
    { print }
  ' "$1"
}

lines_count() { # <file> -> nombre de lignes du fichier ENTIER, jamais wc -l (sous-compte sans \n final)
  awk 'END { print NR }' "$1" 2>/dev/null || echo 0
}

count_instructions() { # <file> -> nombre de lignes-instruction du body
  body_only "$1" | awk -v marker_re="$MARKER_RE" -v title_re="$RULES_TITLE_RE" '
    BEGIN { under = 0; infence = 0; count = 0 }
    {
      trimmed = $0
      sub(/^[[:space:]]*/, "", trimmed)

      # Blocs de code fenced : bascule sur une ligne dont les trois premiers caracteres non
      # blancs sont des accents graves — du code cite, jamais une directive.
      if (trimmed ~ /^```/) { infence = !infence; next }
      if (infence) { next }

      # Titres markdown : ne comptent JAMAIS comme instruction (25 faux positifs mesures sur le
      # corpus), mais servent de SCOPE pour la forme "puce imperative sous un titre de regles".
      # Open Question 1 tranchee EN TOUTES LETTRES ici : un titre de tout niveau, quel qu il
      # soit, referme le scope, y compris un sous-titre imbrique sous un titre de regles — la
      # regle est de niveau PLAT, pas recursive, parce qu un scope qui traverse les sous-titres
      # compterait des exemples et des tableaux comme des regles. Une section de regles
      # structuree en sous-sections doit repeter un libelle de regles dans ses sous-titres pour
      # rester comptee ; choix conservateur assume (sous-compte plutot que sur-compte).
      if ($0 ~ /^[[:space:]]*#+[[:space:]]/) {
        label = $0
        sub(/^[[:space:]]*#+[[:space:]]*/, "", label)
        if (tolower(label) ~ title_re) { under = 1 } else { under = 0 }
        next
      }

      # Marqueurs textuels D-01 : appliques a toute ligne de body restante, SANS condition de
      # scope — cette forme de base de D-01 est independante de la regle de puce ci-dessous.
      is_marker = (tolower($0) ~ marker_re)

      # Puce imperative sous un titre de regles ouvert : compte MEME sans aucun marqueur textuel.
      is_bullet = 0
      if (under == 1) {
        if (trimmed ~ /^(- |\* |[0-9]+\. )/) { is_bullet = 1 }
        if (trimmed ~ /^❌/) { is_bullet = 1 }
      }

      # Dedoublonnage : union, jamais une somme — une ligne marqueur ET puce compte UNE fois.
      # Les lignes de TABLEAU markdown COMPTENT comme toute autre ligne : aucune exclusion —
      # les exclure ouvrirait une echappatoire (deplacer une regle dans un tableau la rendrait
      # invisible au gate).
      if (is_marker || is_bullet) { count++ }
    }
    END { print count + 0 }
  '
}

# --- F1 : cles de baseline dupliquees pour un meme chemin (garde-fou repris de check-divergence.sh
# --- S2, check-divergence.sh:178-187, cnt[$1]++ — jamais reinvente) --------------------------------
BASELINE_DUPKEYS="$TMPD/baseline-dupkeys"
: > "$BASELINE_DUPKEYS"
if [ "$BASELINE_ROWS" -gt 0 ]; then
  awk -F'\t' '{cnt[$1]++} END{for (k in cnt) if (cnt[k] > 1) print k}' "$BASELINE_CLEAN" \
    | LC_ALL=C sort -u > "$BASELINE_DUPKEYS"
fi

# --- Mesure + verdict, un fichier a la fois, dans l'ordre trie -----------------------------------
REPORT="$TMPD/report"
: > "$REPORT"

NONVERIF_COUNT=0
SANS_BASELINE_COUNT=0
OVERRUN_COUNT=0

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  f="$ROOT/$rel"

  if [ ! -r "$f" ]; then
    printf '%s | - | - | - | - | NON-VERIFIABLE\n' "$rel" >> "$REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — illisible" >&2
    NONVERIF_COUNT=$((NONVERIF_COUNT + 1))
    continue
  fi

  fm_state="$(frontmatter_state "$f")"
  if [ "$fm_state" = "open" ]; then
    printf '%s | - | - | - | - | NON-VERIFIABLE\n' "$rel" >> "$REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — frontmatter jamais referme" >&2
    NONVERIF_COUNT=$((NONVERIF_COUNT + 1))
    continue
  fi

  lines="$(lines_count "$f")"
  case "$lines" in
    ''|*[!0-9]*)
      printf '%s | - | - | - | - | NON-VERIFIABLE\n' "$rel" >> "$REPORT"
      echo "[check-instruction-budget] $rel : non verifiable — comptage de lignes illisible" >&2
      NONVERIF_COUNT=$((NONVERIF_COUNT + 1))
      continue
      ;;
  esac

  instr="$(count_instructions "$f")"
  case "$instr" in
    ''|*[!0-9]*) instr=0 ;;
  esac

  # F1 (revue vague 1) : le cote BASELINE doit passer le MEME garde numerique que le cote courant
  # (L232-239 plus haut) — sinon une baseline corrompue (non numerique, colonne manquante, CRLF
  # residuel) laisse "verdict" a son initialisation "OK" sous set -uo pipefail sans -e, et le gate
  # rend 0 sur donnee non verifiee. Une entree DUPLIQUEE pour le meme chemin est fermee par le MEME
  # garde-fou que check-divergence.sh S2 (check-divergence.sh:178-187, cnt[$1]++) : detectee une
  # fois pour tout le fichier de baseline, pas reinventee ici.
  bl_lines="-"; bl_instr="-"; has_baseline=0; baseline_bad=0
  if [ "$BASELINE_ROWS" -gt 0 ]; then
    if grep -Fxq "$rel" "$BASELINE_DUPKEYS" 2>/dev/null; then
      baseline_bad=1
    else
      entry="$(awk -F'\t' -v k="$rel" '$1==k{print $2"\t"$3; f=1} END{exit (f?0:1)}' "$BASELINE_CLEAN")"
      entry_rc=$?
      if [ "$entry_rc" -eq 0 ] && [ -n "$entry" ]; then
        bl_lines="${entry%%$'\t'*}"
        bl_instr="${entry#*$'\t'}"
        case "$bl_lines" in
          ''|*[!0-9]*) baseline_bad=1 ;;
        esac
        case "$bl_instr" in
          ''|*[!0-9]*) baseline_bad=1 ;;
        esac
        [ "$baseline_bad" -eq 0 ] && has_baseline=1
      fi
    fi
  fi

  if [ "$baseline_bad" -eq 1 ]; then
    printf '%s | - | - | - | - | NON-VERIFIABLE\n' "$rel" >> "$REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — entree de baseline corrompue (valeur non numerique ou cle dupliquee)" >&2
    NONVERIF_COUNT=$((NONVERIF_COUNT + 1))
    continue
  fi

  # Plafond absolu ADR-029 : prime sur TOUT le reste, y compris une baseline egale au courant —
  # une baseline de lignes > 250 ne legalise jamais le depassement par simple mesure (D-05).
  verdict="OK"
  if [ "$lines" -gt "$VF_BUDGET_LINE_CAP" ]; then
    verdict="DEPASSEMENT-ADR029"
  elif [ "$has_baseline" -eq 0 ]; then
    verdict="SANS-BASELINE"
  else
    line_over=0; instr_over=0
    [ "$lines" -gt "$bl_lines" ] && line_over=1
    [ "$instr" -gt "$bl_instr" ] && instr_over=1
    if [ "$line_over" -eq 1 ] && [ "$instr_over" -eq 1 ]; then
      verdict="DEPASSEMENT-LIGNES+INSTR"
    elif [ "$line_over" -eq 1 ]; then
      verdict="DEPASSEMENT-LIGNES"
    elif [ "$instr_over" -eq 1 ]; then
      verdict="DEPASSEMENT-INSTR"
    elif [ "$lines" -lt "$bl_lines" ] || [ "$instr" -lt "$bl_instr" ]; then
      verdict="MARGE"
    fi
  fi

  # F3 (revue vague 1) : SANS_BASELINE_COUNT s'incremente sur has_baseline==0 INDEPENDAMMENT du
  # verdict affiche — sinon un fichier > 250 lignes sans entree de baseline tombe dans la branche
  # DEPASSEMENT-ADR029 (prioritaire) et l'absence de couverture de baseline reste invisible au
  # bilan (le contrat de must_haves exige 2, pas 1, sur ce cas).
  if [ "$has_baseline" -eq 0 ]; then
    SANS_BASELINE_COUNT=$((SANS_BASELINE_COUNT + 1))
  fi
  case "$verdict" in
    DEPASSEMENT-*) OVERRUN_COUNT=$((OVERRUN_COUNT + 1)) ;;
  esac

  printf '%s | %s | %s | %s | %s | %s\n' "$rel" "$lines" "$bl_lines" "$instr" "$bl_instr" "$verdict" >> "$REPORT"
done < "$FILES_LIST"

if [ "$ORPHAN_COUNT" -gt 0 ]; then
  while IFS= read -r orphan_path; do
    [ -n "$orphan_path" ] || continue
    echo "[check-instruction-budget] entree de baseline orpheline : $orphan_path" >&2
  done < "$ORPHANS"
fi

# --- Contrat de baseline : armer sans contrat complet n'est pas un depassement, c'est une -------
# --- absence de verdict possible (rend 2, jamais un vert de complaisance) -----------------------
BASELINE_CONTRACT_BAD=0
if [ "$ARMED" -eq 1 ]; then
  if [ "$BASELINE_MISSING" -eq 1 ] || [ "$BASELINE_ROWS" -eq 0 ] \
     || [ "$SANS_BASELINE_COUNT" -gt 0 ] || [ "$ORPHAN_COUNT" -gt 0 ]; then
    BASELINE_CONTRACT_BAD=1
  fi
fi

RC=0
if [ "$NONVERIF_COUNT" -gt 0 ]; then
  RC=2
elif [ "$ARMED" -eq 1 ] && [ "$BASELINE_CONTRACT_BAD" -eq 1 ]; then
  RC=2
elif [ "$ARMED" -eq 1 ] && [ "$OVERRUN_COUNT" -gt 0 ]; then
  RC=1
elif [ "$ARMED" -eq 1 ]; then
  RC=0
else
  RC=3
fi

# --- Rapport, integralement sur stdout, AVANT tout exit (2bis) : un gate qui sort en erreur -----
# --- sans publier ce qu'il a vu oblige a relancer a la main pour savoir ce qui s'est passe. ------
sentinel_state="ABSENTE"; [ "$ARMED" -eq 1 ] && sentinel_state="PRESENTE"
baseline_state="ABSENT"; [ "$BASELINE_MISSING" -eq 0 ] && baseline_state="PRESENT"
armed_label="non"; [ "$ARMED" -eq 1 ] && armed_label="oui"

echo "[check-instruction-budget] corpus decouvert : $FOUND fichier(s) sous plugin/*/agents/*.md + plugin/*/AGENT.md"
echo "[check-instruction-budget] sentinelle : $SENTINEL ($sentinel_state)"
echo "[check-instruction-budget] baseline : $BASELINE ($baseline_state)"
printf 'FICHIER | LIGNES | BL-LIGNES | INSTR | BL-INSTR | VERDICT\n'
cat "$REPORT"
printf 'BILAN : %s fichier(s), %s depassement(s), %s non verifiable(s), arme=%s, code=%s\n' \
  "$FOUND" "$OVERRUN_COUNT" "$NONVERIF_COUNT" "$armed_label" "$RC"

exit "$RC"
