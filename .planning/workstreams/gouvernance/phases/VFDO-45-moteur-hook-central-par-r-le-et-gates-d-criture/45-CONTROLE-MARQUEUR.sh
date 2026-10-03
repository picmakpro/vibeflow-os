#!/usr/bin/env bash
# 45-CONTROLE-MARQUEUR.sh — contrôle, pour la Phase 45, que chaque commit non-merge de <base>..HEAD qui
# touche les chemins donnés porte au moins un marqueur `Gate-Touche:` que scripts/check-gate-touche.sh
# reconnaîtrait (même lecture, ligne à ligne, que ses l.236-278 : ligne d'un message quelconque, blancs
# de tête retirés, préfixe `Gate-Touche:`, UN espace retiré, séparateur ` — ` puis ` - `, motif non vide
# et sans virgule, raison de 10 codepoints non blancs au moins, comptés octet par octet en locale C).
# Pourquoi pas `%(trailers:key=Gate-Touche)` : il rend une valeur vide quand le marqueur est dans un
# paragraphe séparé (mesuré sur 03861b9, que check-gate-touche.sh lit pourtant : il le juge seulement mal formé, motif à virgule).
# Usage : 45-CONTROLE-MARQUEUR.sh --base=<ref> -- <chemin> [<chemin>…]   |   45-CONTROLE-MARQUEUR.sh --autotest
# Sortie : une ligne `MARQUEUR <sha> conformes=<n> mal-formes=<m>` par commit, puis
# `MARQUEUR-BILAN commits=<c> sans-marqueur=<s>` ; `MARQUEUR-AUCUN-COMMIT` quand aucun commit ne touche
# les chemins (jamais un vert à vide). Codes : 0 tous couverts, 1 sinon, 64 usage.
set -uo pipefail

controle() {
  base=$1; shift
  git log --no-merges --format='@@COMMIT@@ %h%n%B' "$base..HEAD" -- "$@" | LC_ALL=C awk '
    function fin() {
      if (sha != "") { printf "MARQUEUR %s conformes=%d mal-formes=%d\n", sha, ok, mal; c++; if (ok == 0) s++ }
    }
    /^@@COMMIT@@ / { fin(); sha = substr($0, 12); ok = 0; mal = 0; next }
    {
      l = $0; sub(/^[[:space:]]+/, "", l)
      if (index(l, "Gate-Touche:") != 1) next
      v = substr(l, 13); if (substr(v, 1, 1) == " ") v = substr(v, 2)
      sep = ""
      if (index(v, " \342\200\224 ") > 0) sep = " \342\200\224 "
      else if (index(v, " - ") > 0) sep = " - "
      bad = (sep == "")
      if (!bad) {
        p = index(v, sep); motif = substr(v, 1, p - 1); reason = substr(v, p + length(sep))
        if (motif == "" || index(motif, ",") > 0) bad = 1
        else { t = reason; gsub(/[[:space:]]/, "", t); gsub(/[\200-\277]/, "", t); if (length(t) < 10) bad = 1 }
      }
      if (bad) { mal++; print "MARQUEUR-MAL-FORME: " l } else ok++
    }
    END { fin(); if (c == 0) { print "MARQUEUR-AUCUN-COMMIT"; exit 1 }
          printf "MARQUEUR-BILAN commits=%d sans-marqueur=%d\n", c, s + 0; exit (s > 0) }'
}

autotest() {
  racine=$(cd "$(dirname "$0")" && git rev-parse --show-toplevel) || exit 64
  gate="$racine/scripts/check-gate-touche.sh"; [ -f "$gate" ] || { echo "autotest : $gate introuvable"; exit 64; }
  moi=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
  ko=0; n=0
  cas() { # <nom> <attendu 0|1> <message>
    W=$(mktemp -d "${TMPDIR:-/tmp}/marqueur.XXXXXX") || exit 64
    ( cd "$W" && git init -q -b main . && git config user.name t && git config user.email t@t \
      && mkdir scripts && : > scripts/check-foo.sh && git add . && git commit -q -m base \
      && git checkout -q -b b && echo x > scripts/check-foo.sh && git add . && git commit -q -m "$3" ) >/dev/null 2>&1
    ( cd "$W" && bash "$gate" --root . --base-ref main ) >/dev/null 2>&1; rc_gate=$?
    ( cd "$W" && bash "$moi" --base=main -- scripts/check-foo.sh ) >/dev/null 2>&1; rc_moi=$?
    rm -rf "$W"; n=$((n + 1))
    if [ "$rc_gate" -eq "$2" ] && [ "$rc_moi" -eq "$2" ]; then echo "✓ AUTOTEST $1 (attendu $2, check-gate-touche $rc_gate, contrôle $rc_moi)"
    else echo "✗ AUTOTEST $1 : attendu $2, check-gate-touche $rc_gate, contrôle $rc_moi"; ko=$((ko + 1)); fi
  }
  R='raison assez longue pour passer'
  cas paragraphe-separe 0 "$(printf 'sujet\n\ncorps\n\nGate-Touche: scripts/check-foo.sh — %s' "$R")"
  cas tiret-simple 0 "$(printf 'sujet\n\nGate-Touche: scripts/check-foo.sh - %s' "$R")"
  cas blancs-de-tete 0 "$(printf 'sujet\n\n   Gate-Touche: scripts/check-foo.sh — %s' "$R")"
  cas raison-courte 1 "$(printf 'sujet\n\nGate-Touche: scripts/check-foo.sh — court')"
  cas motif-a-virgule 1 "$(printf 'sujet\n\nGate-Touche: scripts/check-foo.sh, scripts/check-bar.sh — %s' "$R")"
  cas raison-accentuee-6-caracteres 1 "$(printf 'sujet\n\nGate-Touche: scripts/check-foo.sh — éàçèùî')"
  cas aucun-marqueur 1 "sujet sans marqueur"
  echo "AUTOTEST cas=$n ko=$ko"
  [ "$ko" -eq 0 ]
}

case "${1:-}" in
  --autotest) autotest; exit $? ;;
  --base=*) base=${1#--base=}; shift
            [ "${1:-}" = "--" ] && [ "$#" -ge 2 ] && [ -n "$base" ] || { echo "usage : $0 --base=<ref> -- <chemin>…" >&2; exit 64; }
            shift; controle "$base" "$@"; exit $? ;;
  *) echo "usage : $0 --base=<ref> -- <chemin>…  |  $0 --autotest" >&2; exit 64 ;;
esac
