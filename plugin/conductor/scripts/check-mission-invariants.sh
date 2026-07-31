#!/usr/bin/env bash
# check-mission-invariants.sh — Une zone de risque déclarée en glob a-t-elle disparu ? (SC5, D-15)
#
# Rôle (ADR-055 §3, même distinction FAIT/JUGEMENT que check-doc-drift.sh) : ce script CONSTATE
# qu'un glob de la première section de MISSION-INVARIANTS.md ne matche plus aucun fichier suivi du
# dépôt — jamais il ne décide de le retirer, ne réécrit le fichier, ni ne qualifie la zone
# d'« obsolète » ou de « dette » : ce jugement appartient à l'agent ou à l'humain qui lit le signal.
# Une zone "à corriger" ou "à supprimer" n'est jamais un verdict que ce script prononce lui-même.
#
# Source de vérité : la PREMIÈRE section « ## » du fichier d'invariants (par défaut
# .planning/MISSION-INVARIANTS.md relatif à --path), et elle seule — les sections suivantes
# (table des fichiers gelés, contrainte d'outillage éventuelle) ne sont jamais lues par ce script.
# Une entrée de liste retenue est une ligne de la forme `- \`<glob>\`` (backticks obligatoires),
# un commentaire de fin de ligne introduit par `#` est toléré et retiré. Une ligne de citation
# (`>`), un paragraphe de prose ou une ligne vide sont ignorés. Cette règle de découpage LIE le
# format du fichier et ce script : la changer d'un côté sans l'autre casserait le gate en silence.
#
# Méthode : confrontation de chaque glob à l'INDEX GIT du dépôt (`git ls-files --`), jamais un
# parcours du système de fichiers — pour ne jamais compter un fichier ignoré ou un artefact de
# build comme preuve de vie d'une zone de risque. Un compte nul est une zone morte.
#
# Contrat de sortie (révisé — correctif de revue, plan 20-05, D-15 §condition falsifiable) :
#
#   AVANT ce correctif, quatre situations distinctes tombaient dans le même code 3 : fichier absent,
#   hors dépôt git, aucun glob trouvé dans la §1, et tous les globs vivants — un consommateur
#   automatique ne pouvait pas distinguer « le gate a regardé et tout va bien » de « le gate n'avait
#   rien à regarder ». Le cas le plus grave (§1 vidée de ses globs, l'invariant périmé le plus
#   silencieux) était indistinguable du cas le plus sain (tous les globs vivants). Corrigé en
#   séparant le code en un état SAIN et un état INDÉTERMINÉ distincts — précédent suivi :
#   check-gsd-engine.sh (Phase 19), où exit 3 ≠ silence et où un état « rien de garanti » ne se
#   confond jamais avec un état « vérifié, conforme ».
#
#   0  = au moins une zone morte détectée — signal [mission-invariants] émis, une ligne par zone,
#        citant le glob VERBATIM (pour que le lecteur le retrouve dans le fichier).
#   3  = SAIN — le fichier a été LU et la première section contenait au moins un glob : tous les
#        globs matchent encore au moins un fichier suivi. C'est le SEUL code qui signifie
#        « vérifié, conforme ».
#   4  = INDÉTERMINÉ — rien n'a été vérifié, pour l'une de ces trois raisons (diagnostic sur stderr,
#        sauf --quiet, précisant laquelle) : fichier absent au chemin par défaut ; racine hors d'un
#        dépôt git ; ou première section du fichier sans aucun glob. Un exit 4 n'autorise JAMAIS à
#        conclure que les zones de risque sont à jour — seul un exit 3 le dit.
#   64 = argument inconnu, --path/--file sans valeur, --hook + --quiet ensemble, ou fichier
#        EXPLICITEMENT désigné par --file et illisible.
#
# Lecture seule intégrale : aucune écriture, aucune modification, aucune suppression — ni du
# fichier d'invariants, ni d'aucun autre fichier du dépôt inspecté. Prouvé par empreinte du dépôt
# avant/après dans la suite dédiée.
#
# Usage:
#   check-mission-invariants.sh [--path <dir>] [--file <path>] [--hook] [--quiet]
# Defaults: --path .  --file .planning/MISSION-INVARIANTS.md (relatif à --path)
#
# --hook change UNIQUEMENT le format d'affichage (parité avec les autres gates de la phase) ; ce
# script n'a qu'un seul gabarit de signal, donc --hook n'altère aucun rendu — il ne sert qu'à la
# cohérence d'interface et au gate de mutuelle exclusion avec --quiet. Les 3 exits restent
# identiques avec ou sans --hook.
set -uo pipefail
shopt -s nullglob

ROOT="."
FILE_REL=".planning/MISSION-INVARIANTS.md"
FILE_EXPLICIT=0
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-invariants] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --file)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-invariants] --file nécessite une valeur" >&2
        exit 64
      fi
      FILE_REL="$2"; FILE_EXPLICIT=1; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-mission-invariants] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que le gate --path).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-mission-invariants] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-mission-invariants] $*" >&2; }

# --- Durcissement git (même wrapper unique que check-doc-drift.sh, motif écrit une seule fois) ---
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}

# --- Résolution du chemin du fichier d'invariants (relatif à --path si non absolu) ---------------
case "$FILE_REL" in
  /*) FILE_PATH="$FILE_REL" ;;
  *)  FILE_PATH="$ROOT/$FILE_REL" ;;
esac

# --- Fichier illisible : distinction explicite/défaut (comportement différent, D-15) --------------
if [ ! -r "$FILE_PATH" ]; then
  if [ "$FILE_EXPLICIT" -eq 1 ]; then
    echo "[check-mission-invariants] fichier introuvable ou illisible : $FILE_PATH" >&2
    exit 64
  fi
  say "$FILE_PATH absent (chemin par défaut) — INDÉTERMINÉ, rien n'a été vérifié."
  exit 4
fi

# --- Silence hors dépôt git ------------------------------------------------------------------------
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say "$ROOT hors d'un arbre de travail git — INDÉTERMINÉ, rien n'a été vérifié."
  exit 4
fi

# --- Extraction de la PREMIÈRE section « ## » du fichier, et elle seule ---------------------------
# n passe à 1 sur le premier en-tête « ## » rencontré (la ligne d'en-tête elle-même n'est jamais
# imprimée) ; n passe à 2 sur le second en-tête, ce qui arrête la lecture immédiatement — les
# sections suivantes ne sont jamais vues par ce script (D-15 §2 : la table des fichiers gelés
# n'est jamais lue ici, elle est dérivée par dag.sh status, pas par ce gate).
SECTION="$(awk '
  /^## / { n++; if (n==1) { next }; if (n==2) { exit } }
  n==1 { print }
' "$FILE_PATH")"

# --- Entrées de liste retenues : "- `<glob>`" (backticks obligatoires), commentaire de fin ignoré -
extract_globs() { # écrit un glob par ligne sur stdout, jamais de tableau bash (compat 3.2)
  printf '%s\n' "$SECTION" | grep -E '^- `[^`]+`' | sed -E 's/^- `([^`]+)`.*/\1/'
}
GLOBS="$(extract_globs)"

if [ -z "$GLOBS" ]; then
  say "aucun glob trouvé dans la première section de $FILE_PATH — INDÉTERMINÉ, rien n'a été vérifié."
  exit 4
fi

# --- Détection : pour chaque glob, l'index git le connaît-il encore ? ------------------------------
DEAD=""
while IFS= read -r glob; do
  [ -n "$glob" ] || continue
  COUNT="$(git_safe ls-files -- "$glob" | wc -l | tr -d '[:space:]')"
  case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
  if [ "$COUNT" -eq 0 ]; then
    DEAD="${DEAD}${glob}"$'\n'
  fi
done <<EOF
$GLOBS
EOF

if [ -z "$DEAD" ]; then
  say "SAIN — tous les globs de $FILE_PATH matchent encore au moins un fichier suivi."
  exit 3
fi

say "au moins une zone de risque ne matche plus aucun fichier suivi."
while IFS= read -r glob; do
  [ -n "$glob" ] || continue
  printf '[mission-invariants] zone morte (glob sans correspondance) : %s\n' "$glob"
done <<EOF
$DEAD
EOF
exit 0
