#!/usr/bin/env bash
# check-instruction-budget.sh — mesure et publie, par fichier d'agent distribue, deux metriques
# (lignes du fichier entier, instructions du body). Seules les instructions sont comparees a une
# baseline en ratchet par fichier ; les lignes sont bornees par le plafond ADR-029 (avertissement
# des le seuil bas, blocage au-dela du plafond), la colonne lignes de la baseline restant
# informative, jamais comparee (BUDG-01, BUDG-02, ADR-029).
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
#   0  = ARME et aucun depassement (peut porter un verdict AVERTISSEMENT-ADR029 non bloquant,
#        des 251 lignes, ou LIGNES-EN-HAUSSE informatif)
#   1  = ARME et au moins un depassement (instruction au-dessus de sa baseline par fichier,
#        ou plafond ADR-029 a 300 lignes)
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
#
# SKILL.md (Phase 43, FABR-09, D-Q4). Seconde decouverte, INDEPENDANTE de celle des agents (D-03
# inchangee) : recursive sous chaque module de plugin/*/, sauf un module ENTIEREMENT exclu quand
# son module.json declare "type": "doc-only" (ses SKILL.md sont comptes dans une ligne d'exclusion,
# jamais mesures) ; dossiers caches et *-references elagues (meme critere de pruning que
# decouvrir_agents, check-agents.sh:291-316), aucun lien symbolique de DOSSIER suivi. Un SKILL.md
# en lien symbolique n'est PAS exclu par la decouverte : il est retenu, puis rendu NON-VERIFIABLE a
# la mesure (jamais ignore en silence, meme garde-fou que le frontmatter jamais referme). Plafond
# ADR-029 : 500 lignes (fichier entier, meme mesure que les agents), lu depuis VF_SKILL_LINE_CAP —
# jamais partage avec VF_BUDGET_LINE_CAP (300), les deux plafonds ont des sources et des valeurs
# distinctes dans la charte. Aucun seuil d'avertissement pour les skills : ADR-029 n'en definit pas
# (43-RESEARCH.md, Assumption A4) — un seuil invente introduirait une valeur non tracee. Aucun
# ratchet d'instructions sur les SKILL.md : FABR-09 exige le refus au-dela de 500 lignes, pas une
# baseline par fichier ; ajouter 21 lignes de baseline serait une hausse sans exigence (decision de
# plan, 43-04-PLAN.md).
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

# Plafond ADR-029 revise en Phase 40.1 (arbitrages Samuel D-01/D-05, AskUserQuestion session
# principale, relais SendMessage, 2026-09-16) : avertissement des VF_BUDGET_LINE_WARN_FROM lignes
# (non bloquant), blocage au-dela de VF_BUDGET_LINE_CAP lignes — toujours le FICHIER ENTIER (D-06).
# La limite n'est plus "le plus petit de la baseline et du plafond" : c'est desormais le plafond
# seul qui bloque ; la colonne lignes de la baseline est LUE et PUBLIEE dans le rapport mais n'est
# plus JAMAIS comparee pour decider du code de sortie (D-02, D-H6 — seul le ratchet d'instructions
# reste comparatif, voir plus bas). Une baseline de lignes superieure au plafond ne peut jamais
# legaliser un depassement — voir verdict DEPASSEMENT-ADR029 plus bas, qui prime toujours sur tout
# le reste, y compris l'avertissement.
VF_BUDGET_LINE_CAP=300
VF_BUDGET_LINE_WARN_FROM=251

# Plafond SKILL.md (Phase 43, FABR-09, D-Q4, ADR-029) : bloque au-dela de 500 lignes (fichier
# entier), jamais compare a VF_BUDGET_LINE_CAP — deux corpus, deux plafonds.
VF_SKILL_LINE_CAP=500

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

# --- Decouverte SKILL.md, SECONDE et INDEPENDANTE (D-Q4, FABR-09) : recursive sous chaque ---------
# --- plugin/*/, sauf un module ENTIEREMENT exclu (module.json "type": "doc-only", ses SKILL.md ----
# --- comptes dans SKILL_EXCLUDED, jamais mesures) ; dossiers caches et *-references elagues, aucun -
# --- lien symbolique de DOSSIER suivi (find sans -L). Un SKILL.md en lien symbolique n'est PAS ----
# --- exclu ici : il est retenu, puis rendu NON-VERIFIABLE a la mesure plus bas. ---------------------
SKILL_FILES_LIST="$TMPD/skill-files"
: > "$SKILL_FILES_LIST"
SKILL_EXCLUDED=0
for d in "$ROOT"/plugin/*/; do
  [ -d "$d" ] || continue
  if [ -f "${d}module.json" ] && grep -Eq '"type"[[:space:]]*:[[:space:]]*"doc-only"' "${d}module.json" 2>/dev/null; then
    n="$(find "$d" -name SKILL.md 2>/dev/null | awk 'END{print NR}')"
    [ -n "$n" ] || n=0
    SKILL_EXCLUDED=$((SKILL_EXCLUDED + n))
    continue
  fi
  find "$d" '(' -type d -name '.*' -prune ')' -o '(' -type d -name '*-references' -prune ')' -o '(' -type f -name SKILL.md -print ')' -o '(' -type l -name SKILL.md -print ')' 2>/dev/null | while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$ROOT"/}"
    printf '%s\n' "$rel" >> "$SKILL_FILES_LIST"
  done
done
LC_ALL=C sort -u "$SKILL_FILES_LIST" -o "$SKILL_FILES_LIST"
SKILL_FOUND=$(awk 'END{print NR}' "$SKILL_FILES_LIST" 2>/dev/null || echo 0)
[ -n "$SKILL_FOUND" ] || SKILL_FOUND=0

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
WARN_COUNT=0

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
  # une baseline de lignes superieure au plafond ne legalise jamais le depassement par simple
  # mesure (D-05). Le ratchet ne compare plus JAMAIS la colonne lignes pour decider du rc (D-02,
  # D-H6) : elle reste lue et publiee dans le rapport, informative seulement (LIGNES-EN-HAUSSE).
  verdict="OK"
  if [ "$lines" -gt "$VF_BUDGET_LINE_CAP" ]; then
    verdict="DEPASSEMENT-ADR029"
  elif [ "$has_baseline" -eq 0 ]; then
    verdict="SANS-BASELINE"
  else
    instr_over=0
    [ "$instr" -gt "$bl_instr" ] && instr_over=1
    if [ "$instr_over" -eq 1 ]; then
      verdict="DEPASSEMENT-INSTR"
    elif [ "$instr" -lt "$bl_instr" ]; then
      verdict="MARGE"
    fi
    # Ligne informative UNIQUE (ancre de MUT-2) : la hausse de lignes ne bloque jamais, elle
    # s'affiche seulement en suffixe du verdict deja pose ci-dessus (D-02/D-H6).
    [ "$lines" -gt "$bl_lines" ] && verdict="${verdict}+LIGNES-EN-HAUSSE"
  fi

  # Avertissement ADR-029 (D-05, non bloquant) : zone haute avant le plafond, hors le cas ou le
  # plafond est deja depasse (DEPASSEMENT-ADR029 prime toujours et n'accumule pas d'avertissement).
  if [ "$verdict" != "DEPASSEMENT-ADR029" ] && [ "$lines" -ge "$VF_BUDGET_LINE_WARN_FROM" ] && [ "$lines" -le "$VF_BUDGET_LINE_CAP" ]; then
    verdict="${verdict}+AVERTISSEMENT-ADR029"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # F3 (revue vague 1) : SANS_BASELINE_COUNT s'incremente sur has_baseline==0 INDEPENDAMMENT du
  # verdict affiche — sinon un fichier au-dela du plafond sans entree de baseline tombe dans la branche
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

# --- Mesure + verdict des SKILL.md, meme ordre trie, plafond ADR-029 (500 lignes, D-Q4) : aucune ---
# --- baseline requise pour les skills — FABR-09 exige le refus au-dela du plafond, pas un ratchet --
# --- d'instructions par fichier (decision de plan). --------------------------------------------
SKILL_REPORT="$TMPD/skill-report"
: > "$SKILL_REPORT"

SKILL_OVERRUN_COUNT=0
SKILL_NONVERIF_COUNT=0

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  f="$ROOT/$rel"

  if [ -L "$f" ]; then
    printf '%s | - | %s | NON-VERIFIABLE\n' "$rel" "$VF_SKILL_LINE_CAP" >> "$SKILL_REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — lien symbolique" >&2
    SKILL_NONVERIF_COUNT=$((SKILL_NONVERIF_COUNT + 1))
    continue
  fi

  if [ ! -r "$f" ]; then
    printf '%s | - | %s | NON-VERIFIABLE\n' "$rel" "$VF_SKILL_LINE_CAP" >> "$SKILL_REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — illisible" >&2
    SKILL_NONVERIF_COUNT=$((SKILL_NONVERIF_COUNT + 1))
    continue
  fi

  fm_state="$(frontmatter_state "$f")"
  if [ "$fm_state" = "open" ]; then
    printf '%s | - | %s | NON-VERIFIABLE\n' "$rel" "$VF_SKILL_LINE_CAP" >> "$SKILL_REPORT"
    echo "[check-instruction-budget] $rel : non verifiable — frontmatter jamais referme" >&2
    SKILL_NONVERIF_COUNT=$((SKILL_NONVERIF_COUNT + 1))
    continue
  fi

  lines="$(lines_count "$f")"
  case "$lines" in
    ''|*[!0-9]*)
      printf '%s | - | %s | NON-VERIFIABLE\n' "$rel" "$VF_SKILL_LINE_CAP" >> "$SKILL_REPORT"
      echo "[check-instruction-budget] $rel : non verifiable — comptage de lignes illisible" >&2
      SKILL_NONVERIF_COUNT=$((SKILL_NONVERIF_COUNT + 1))
      continue
      ;;
  esac

  verdict="OK"
  if [ "$lines" -gt "$VF_SKILL_LINE_CAP" ]; then
    verdict="DEPASSEMENT-SKILL-ADR029"
    SKILL_OVERRUN_COUNT=$((SKILL_OVERRUN_COUNT + 1))
  fi

  printf '%s | %s | %s | %s\n' "$rel" "$lines" "$VF_SKILL_LINE_CAP" "$verdict" >> "$SKILL_REPORT"
done < "$SKILL_FILES_LIST"

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

# --- SKILL_NONVERIF_COUNT rejoint la branche NON-VERIFIABLE (rc 2), SKILL_OVERRUN_COUNT rejoint ---
# --- la branche depassement (rc 1 si arme) : aucun nouveau code de sortie (D-Q4, FABR-09). --------
NONVERIF_ANY=0
[ "$NONVERIF_COUNT" -gt 0 ] && NONVERIF_ANY=1
[ "$SKILL_NONVERIF_COUNT" -gt 0 ] && NONVERIF_ANY=1

OVERRUN_ANY=0
[ "$OVERRUN_COUNT" -gt 0 ] && OVERRUN_ANY=1
[ "$SKILL_OVERRUN_COUNT" -gt 0 ] && OVERRUN_ANY=1

RC=0
if [ "$NONVERIF_ANY" -eq 1 ]; then
  RC=2
elif [ "$ARMED" -eq 1 ] && [ "$BASELINE_CONTRACT_BAD" -eq 1 ]; then
  RC=2
elif [ "$ARMED" -eq 1 ] && [ "$OVERRUN_ANY" -eq 1 ]; then
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
printf 'BILAN : %s fichier(s), %s depassement(s), %s avertissement(s) ADR-029, %s non verifiable(s), arme=%s, code=%s\n' \
  "$FOUND" "$OVERRUN_COUNT" "$WARN_COUNT" "$NONVERIF_COUNT" "$armed_label" "$RC"

echo "[check-instruction-budget] corpus skills decouvert : $SKILL_FOUND SKILL.md (+ $SKILL_EXCLUDED exclu(s) sous un module doc-only)"
printf 'SKILL | LIGNES | PLAFOND | VERDICT\n'
cat "$SKILL_REPORT"
printf 'BILAN-SKILLS : %s SKILL.md, %s depassement(s) du plafond %s, %s non verifiable(s), %s exclu(s)\n' \
  "$SKILL_FOUND" "$SKILL_OVERRUN_COUNT" "$VF_SKILL_LINE_CAP" "$SKILL_NONVERIF_COUNT" "$SKILL_EXCLUDED"

exit "$RC"
