#!/usr/bin/env bash
# check-dev-bootstrap.sh — Où en est le démarrage de CE projet ? (SIG-01)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne juge JAMAIS si un projet
# « mérite » un onboarding — c'est le jugement de l'agent. Il constate un continuum à 4 états,
# mutuellement exclusifs, évalués dans cet ordre (le premier qui matche gagne) :
#   0. ni code source ni .planning/                              → silence,             exit 3
#   1. code source présent, .planning/ absent                    → signal [onboard],    exit 0
#   2. .planning/PROJECT.md présent, ≥1 item de démarrage manquant→ signal [bootstrap],  exit 0
#   3. .planning/PROJECT.md présent, tous les items posés         → signal [gsd-engine],  exit 3
#
# L'état 3 est une ORIENTATION, pas une dette : il imprime UNE ligne (contre le risque qu'une
# demande de conception parte sur une chaîne générique alors que le projet est piloté par GSD)
# mais reste en exit 3 — rupture assumée de la convention « exit 3 ⇔ silence » que suivent les
# états 0 et les autres scripts de la phase (D-14). Sortie et code de sortie ne se déduisent
# jamais l'un de l'autre.
#
# Détection « code source présent » : au moins un fichier hors des dossiers vendorés/générés
# (.git, node_modules, .venv, vendor, dist, build, .next) et hors docs/, .planning/, .claude/
# (ces trois-là ne comptent pas comme du code, spec §3.1). find avec élagage -prune AVANT
# descente, jamais de filtre post — un node_modules réel gèlerait le SessionStart.
#
# Items de démarrage vérifiés à l'état 2, dans cet ORDRE DE RESTITUTION FIGÉ (D-03, produit par
# la séquence du code, jamais par un parcours de filesystem — deux exécutions sur la même
# fixture donnent un stdout identique octet pour octet) :
#   config   — .planning/config.json absent                                  → geste gsd-config
#   codebase — code présent ET .planning/codebase/ absent ou vide            → geste gsd-map-codebase
#   roadmap  — .planning/ROADMAP.md absent, ou sans aucune ligne d'en-tête de phase → geste gsd-plan-phase
#
# État 3 — lecture du frontmatter de .planning/STATE.md (milestone, current_phase, status) :
# SEUL endroit où du contenu de dépôt traverse vers le contexte de la session principale
# (frontière de confiance, cf. <threat_model> T-17-01). La lecture est bornée : la ligne 1 doit
# être EXACTEMENT le délimiteur de frontmatter, la lecture s'arrête au délimiteur fermant et au
# maximum aux 60 premières lignes (garde anti-gel). Chaque valeur extraite est démouillée de ses
# guillemets encadrants puis validée contre la liste blanche stricte ^[0-9A-Za-z._ /-]{1,80}$.
# Cette liste blanche est VOLONTAIREMENT STRICTE : son échec (caractère de contrôle, séquence
# d'échappement, accent, longueur excessive, clé absente, fichier absent, ligne 1 non conforme)
# est une SOUPAPE DE SÛRETÉ (D-04), pas un bug — le script retombe alors en silence total, jamais
# d'état inventé.
#
# Usage:
#   check-dev-bootstrap.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# --hook change UNIQUEMENT le format d'affichage (parité avec les deux autres scripts de la
# phase) ; les 4 exits restent identiques avec ou sans. --hook et --quiet ensemble → exit 64.
#
# Workstreams GSD (GSDA-13) — QUELS CHEMINS BOUGENT, LESQUELS NE BOUGENT PAS :
# Le moteur amont peut partitionner le planning en compartiments `.planning/workstreams/<nom>/`.
# Le workstream actif est résolu dans cet ordre COURT-CIRCUITANT : VF_BOOTSTRAP_WORKSTREAM, puis
# GSD_WORKSTREAM (canal de premier rang du moteur), puis la 1re ligne du pointeur PARTAGÉ in-repo
# `<planning>/active-workstream`. Le nom est validé contre la politique du moteur
# (workstream-name-policy.cjs : 1er caractère alphanumérique, puis alphanumériques, point,
# souligné, tiret ; ni séparateur de chemin, ni `.`/`..`, ni `..` en sous-chaîne) plus une borne
# locale de 80 caractères. Un nom hors politique est traité comme « aucun workstream » et n'est
# JAMAIS concaténé dans un chemin (T-24-04-01).
#
# FRONTIÈRE ASSUMÉE : le pointeur de SESSION en os.tmpdir() n'est PAS lu ici — il est indexé sur un
# condensat du chemin absolu ET sur une clé de session que bash ne peut pas reproduire fidèlement.
# Ce trou est l'objet d'un gate dédié, jamais d'une approximation à cet endroit.
#
# Seuls DEUX chemins suivent le compartiment actif : ROADMAP.md et STATE.md. config.json, codebase/
# et PROJECT.md restent à la RACINE du .planning/ — c'est le modèle de partition du moteur, pas un
# oubli. Un workstream résolu dont le dossier est ABSENT → ligne de signalement qui le nomme, PUIS
# repli sur la racine ; jamais un silence.
#
# Env (surcharge — testabilité, modèle VF_INGEST_* de discover-unintegrated-docs.sh):
#   VF_BOOTSTRAP_PLANNING_DIR (défaut <path>/.planning)
#   VF_BOOTSTRAP_WORKSTREAM   (workstream actif ; prime sur GSD_WORKSTREAM et sur le pointeur)
#   GSD_WORKSTREAM            (canal de premier rang du moteur GSD amont)
#
# Exit codes:
#   0  = signal [onboard] ou [bootstrap] émis (démarrage incomplet)
#   3  = rien à signaler (état 0), OU orientation [gsd-engine] (état 3, sortie non vide — D-14)
#   64 = argument inconnu, --path sans valeur, ou --hook + --quiet ensemble
set -uo pipefail
shopt -s nullglob

ROOT="."
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-dev-bootstrap] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-dev-bootstrap] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (D-05, même position que le gate --path).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-dev-bootstrap] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-dev-bootstrap] $*" >&2; }

PLANNING_DIR="${VF_BOOTSTRAP_PLANNING_DIR:-$ROOT/.planning}"

# --- Résolution du workstream actif (GSDA-13) -------------------------------------------------
# Politique de nom recopiée du moteur amont (workstream-name-policy.cjs) : la borne de longueur est
# une addition LOCALE, strictement plus sévère — elle ne peut donc jamais accepter un nom qu'amont
# refuserait. Le rejet est TOTAL : aucune concaténation, et la valeur brute n'est pas ré-imprimée
# (elle est non maîtrisée par construction — T-24-04-01).
ws_trim() { printf '%s' "$1" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

ws_name_valid() { # <nom>
  local n="$1"
  [ -n "$n" ] || return 1
  [ "${#n}" -le 80 ] || return 1
  case "$n" in */*|*\\*|.|..|*..*) return 1 ;; esac
  printf '%s' "$n" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'
}

# Imprime le nom résolu ET valide, ou RIEN. Sort en 2 (et n'imprime rien) quand un nom a bien été
# résolu mais qu'il est hors politique — l'appelant distingue ainsi « aucun workstream » de
# « workstream rejeté », sans jamais voir la valeur brute.
ws_resolve() {
  local n=""
  if [ -n "${VF_BOOTSTRAP_WORKSTREAM:-}" ]; then
    n="$VF_BOOTSTRAP_WORKSTREAM"
  elif [ -n "${GSD_WORKSTREAM:-}" ]; then
    n="$GSD_WORKSTREAM"
  elif [ -r "$PLANNING_DIR/active-workstream" ]; then
    n="$(head -n 1 "$PLANNING_DIR/active-workstream" 2>/dev/null)"
  fi
  n="$(ws_trim "$n")"
  [ -n "$n" ] || return 0
  ws_name_valid "$n" || return 2
  printf '%s' "$n"
}

WORKSTREAM="$(ws_resolve)"; ws_rc=$?
PLANNING_SCOPE="$PLANNING_DIR"
if [ "$ws_rc" -eq 2 ]; then
  say "nom de workstream hors politique — rejeté, aucun chemin construit, lecture sur la racine."
elif [ -n "$WORKSTREAM" ]; then
  if [ -d "$PLANNING_DIR/workstreams/$WORKSTREAM" ]; then
    PLANNING_SCOPE="$PLANNING_DIR/workstreams/$WORKSTREAM"
  else
    say "workstream « $WORKSTREAM » résolu mais $PLANNING_DIR/workstreams/$WORKSTREAM absent — lecture sur la racine."
  fi
fi

# --- find borné : élaguer les dossiers vendorés/générés ET les dossiers hors-code AVANT la
# descente (-prune, pas filtre post). POURQUOI : un node_modules réel gèlerait le SessionStart
# (hook tué au timeout). docs/, .planning/, .claude/ sont étendus au motif PRUNE_VENDOR de
# detect-planning-debt.sh:54 — spec §3.1 : ces trois dossiers ne comptent pas comme du code.
# Expansion NON quotée voulue aux sites d'appel (mots fixes sans espace, `(` passé à find).
PRUNE_VENDOR='( -type d ( -name .git -o -name node_modules -o -name .venv -o -name vendor -o -name dist -o -name build -o -name .next -o -name docs -o -name .planning -o -name .claude ) ) -prune'

# --- L'existence d'UN fichier hors élagage suffit — jamais de comptage exhaustif (perf SessionStart).
has_source() { # <dir>
  local dir="$1" f
  f=$(find "$dir" $PRUNE_VENDOR -o -type f -print 2>/dev/null | head -n 1)
  [ -n "$f" ]
}

config_missing() { [ ! -f "$PLANNING_DIR/config.json" ]; }

codebase_missing() {
  local dir="$PLANNING_DIR/codebase" any
  [ -d "$dir" ] || return 0
  any=$(find "$dir" -mindepth 1 -print 2>/dev/null | head -n 1)
  [ -z "$any" ]
}

# ROADMAP.md suit le compartiment actif (GSDA-13) — cf. docstring : config.json/codebase/PROJECT.md
# restent à la racine, seuls ROADMAP.md et STATE.md bougent.
roadmap_missing() {
  local f="$PLANNING_SCOPE/ROADMAP.md"
  [ -f "$f" ] || return 0
  if grep -qE '^#{1,6}[[:space:]]*Phase[[:space:]]+[0-9]+' "$f" 2>/dev/null; then
    return 1
  fi
  return 0
}

# --- Lecture bornée + assainissement du frontmatter de STATE.md (D-04, T-17-01) --------------
# Imprime "milestone<TAB>current_phase<TAB>status" (valeurs BRUTES, pas encore assainies) sur
# stdout et sort en 0 UNIQUEMENT si : ligne 1 == délimiteur exact, délimiteur fermant trouvé dans
# les 60 premières lignes, et les 3 clés sont présentes. Sinon, exit 1 sans rien imprimer.
extract_frontmatter() { # <file>
  local file="$1"
  [ -f "$file" ] || return 1
  awk '
    NR==1 {
      if ($0 != "---") { exit }
      next
    }
    NR > 60 { exit }
    /^---[[:space:]]*$/ { closed=1; exit }
    {
      if (match($0, /^milestone:[[:space:]]*/))           { m = substr($0, RSTART+RLENGTH); mset=1 }
      else if (match($0, /^current_phase:[[:space:]]*/))  { p = substr($0, RSTART+RLENGTH); pset=1 }
      else if (match($0, /^status:[[:space:]]*/))          { s = substr($0, RSTART+RLENGTH); sset=1 }
    }
    END {
      if (!closed || !mset || !pset || !sset) { exit 1 }
      printf "%s\t%s\t%s\n", m, p, s
    }
  ' "$file"
}

# Retire un unique jeu de guillemets encadrants (simples OU doubles), puis valide contre la
# liste blanche stricte ^[0-9A-Za-z._ /-]{1,80}$. Imprime la valeur assainie et sort en 0 si
# valide ; sinon exit 1 sans rien imprimer — SOUPAPE DE SÛRETÉ (D-04), jamais un bug.
sanitize_value() { # <raw>
  local v="$1"
  case "$v" in
    \"*) [ "${v%\"}" != "$v" ] && { v="${v#\"}"; v="${v%\"}"; } ;;
    \'*) [ "${v%\'}" != "$v" ] && { v="${v#\'}"; v="${v%\'}"; } ;;
  esac
  if printf '%s' "$v" | grep -Eq '^[0-9A-Za-z._ /-]{1,80}$'; then
    printf '%s' "$v"
    return 0
  fi
  return 1
}

# Construit et imprime le signal [gsd-engine] (2 lignes) si et seulement si le frontmatter est
# lisible et assaini avec succès. Exit 1 sans rien imprimer sinon — l'appelant reste en exit 3.
state3_signal() { # <state-md-path>
  local file="$1" fm m_raw p_raw s_raw m p s status_human
  fm="$(extract_frontmatter "$file")" || return 1
  IFS="$(printf '\t')" read -r m_raw p_raw s_raw <<STATE3EOF
$fm
STATE3EOF
  m="$(sanitize_value "$m_raw")" || return 1
  p="$(sanitize_value "$p_raw")" || return 1
  s="$(sanitize_value "$s_raw")" || return 1
  case "$s" in
    shipped) status_human="shippée" ;;
    in_progress|in-progress) status_human="en cours" ;;
    planned|not_started) status_human="non démarrée" ;;
    *) status_human="$s" ;;
  esac
  printf '[gsd-engine] Projet piloté par GSD — milestone %s, phase %s %s.\n' "$m" "$p" "$status_human"
  printf '            → cadrage : gsd-discuss-phase · plan : gsd-plan-phase · état : gsd-progress.\n'
}

HAS_SOURCE=0
has_source "$ROOT" && HAS_SOURCE=1

HAS_PLANNING=0
[ -d "$PLANNING_DIR" ] && HAS_PLANNING=1

# --- État 0 — ni code source ni .planning/ : silence total, exit 3 ---------------------------
if [ "$HAS_SOURCE" -eq 0 ] && [ "$HAS_PLANNING" -eq 0 ]; then
  say "ni code source ni $PLANNING_DIR — rien à signaler."
  exit 3
fi

# --- État 1 — code source présent, .planning/ absent : signal [onboard], exit 0 --------------
if [ "$HAS_SOURCE" -eq 1 ] && [ "$HAS_PLANNING" -eq 0 ]; then
  say "code source présent, $PLANNING_DIR absent — projet non cadré."
  printf '%s\n' "[onboard]   Code présent, aucun .planning/ — projet non cadré."
  printf '%s\n' "            → propose gsd-onboard (confirmation requise)."
  exit 0
fi

# --- États 2/3 — .planning/PROJECT.md présent : items de démarrage, ordre figé (D-03) --------
if [ -f "$PLANNING_DIR/PROJECT.md" ]; then
  ITEMS_CONSTAT=""
  ITEMS_GESTE=""

  if config_missing; then
    ITEMS_CONSTAT="${ITEMS_CONSTAT:+${ITEMS_CONSTAT}, }config.json absent"
    ITEMS_GESTE="${ITEMS_GESTE:+${ITEMS_GESTE} puis }gsd-config"
  fi

  if [ "$HAS_SOURCE" -eq 1 ] && codebase_missing; then
    ITEMS_CONSTAT="${ITEMS_CONSTAT:+${ITEMS_CONSTAT}, }codebase non cartographié"
    ITEMS_GESTE="${ITEMS_GESTE:+${ITEMS_GESTE} puis }gsd-map-codebase"
  fi

  if roadmap_missing; then
    ITEMS_CONSTAT="${ITEMS_CONSTAT:+${ITEMS_CONSTAT}, }feuille de route absente"
    ITEMS_GESTE="${ITEMS_GESTE:+${ITEMS_GESTE} puis }gsd-plan-phase"
  fi

  if [ -n "$ITEMS_CONSTAT" ]; then
    say "démarrage inachevé : ${ITEMS_CONSTAT}."
    printf '%s\n' "[bootstrap] Projet initialisé, démarrage inachevé : ${ITEMS_CONSTAT}."
    printf '%s\n' "            → propose ${ITEMS_GESTE} (confirmation requise)."
    exit 0
  fi

  # --- État 3 — tous les items posés : orientation [gsd-engine], exit 3 (D-01, D-14) ---------
  if OUT="$(state3_signal "$PLANNING_SCOPE/STATE.md")"; then
    say "projet complètement cadré — orientation gsd-engine."
    printf '%s\n' "$OUT"
    exit 3
  fi
  say "frontmatter de $PLANNING_SCOPE/STATE.md illisible ou invalide — silence (D-04)."
  exit 3
fi

# --- .planning/ présent sans PROJECT.md : aucun des 4 états ne matche, rien à inventer -------
say "$PLANNING_DIR présent sans PROJECT.md — aucun état connu, rien à signaler."
exit 3
