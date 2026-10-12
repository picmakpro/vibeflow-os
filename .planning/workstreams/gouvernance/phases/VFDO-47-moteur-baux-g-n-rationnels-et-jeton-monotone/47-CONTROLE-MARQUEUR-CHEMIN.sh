#!/usr/bin/env bash
# 47-CONTROLE-MARQUEUR-CHEMIN.sh — contrôle PAR CHEMIN du marqueur `Gate-Touche:` (Phase 47, P47-D-16).
# Complète 45-CONTROLE-MARQUEUR.sh : celui-ci demande « au moins UN marqueur conforme par commit » ; un commit qui
# touche le hook ET une suite avec un seul trailer le satisfait alors qu'un des deux chemins reste sans marqueur.
# Ici, pour chaque commit non-merge de <base>..HEAD, CHAQUE fichier rendu par `git show --name-only` (renommages
# défaits : l'ancien et le nouveau chemin comptent) qui tombe sous une surface gardée doit être couvert par le MOTIF
# d'un trailer conforme DU MÊME COMMIT (comparaison `case`, jamais `eval` : un glob couvre ce qu'il apparie réellement,
# `plugin/planning-core/scripts/tests/` sans étoile ne couvre rien).
# Forme d'un trailer conforme : celle de scripts/check-gate-touche.sh — `Gate-Touche: <motif> — <raison>` (séparateur
# ` — ` ou ` - `), motif non vide et SANS virgule, raison de 10 codepoints non blancs au moins (octets de continuation
# UTF-8 écartés, locale C).
# Surfaces gardées (patterns `case`) : plugin/planning-core/scripts/* · plugin/_internal/tests/* ·
# plugin/conductor/scripts/tests/* · plugin/conductor/scripts/check-*.sh · scripts/check-*.sh · scripts/tests/* ·
# scripts/hooks/* · .github/workflows/ci.yml · plugin/planning-core/hooks/hooks.json.
# Usage : 47-CONTROLE-MARQUEUR-CHEMIN.sh --base=<ref>     |     47-CONTROLE-MARQUEUR-CHEMIN.sh --autotest
# Sortie : `CHEMIN-NON-COUVERT <sha> <fichier>` par fichier orphelin, `TRAILER-MAL-FORME <sha> <ligne>`, puis
# `MARQUEUR-CHEMIN-BILAN commits=<c> fichiers-gardes=<f> non-couverts=<n> mal-formes=<m>` ;
# `MARQUEUR-CHEMIN-AUCUN-FICHIER` (code 1) quand aucun fichier gardé n'est touché : jamais un vert à vide.
# Codes : 0 tout couvert ; 1 sinon ; 64 usage. Bash 3.2, sans `diff`, sans `timeout`.
set -uo pipefail

en_surface() { # <chemin> -> 0 si le chemin tombe sous une surface gardée
  case "$1" in
    plugin/planning-core/scripts/*|plugin/_internal/tests/*|plugin/conductor/scripts/tests/*) return 0 ;;
    plugin/conductor/scripts/check-*.sh|scripts/check-*.sh|scripts/tests/*|scripts/hooks/*) return 0 ;;
    .github/workflows/ci.yml|plugin/planning-core/hooks/hooks.json) return 0 ;;
  esac
  return 1
}

# Trailers d'un message : `OK<TAB>motif` ou `MAL<TAB>ligne`
trailers_de() { # <sha>
  git log -1 --format=%B "$1" | LC_ALL=C awk '
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
      if (bad) print "MAL\t" l; else print "OK\t" motif
    }'
}

controle() { # <base>
  base=$1
  commits=$(git log --no-merges --format=%H "$base..HEAD") || { echo "base illisible : $base" >&2; return 64; }
  nc=0; nf=0; nn=0; nm=0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    nc=$((nc + 1))
    court=$(printf '%s' "$c" | cut -c1-8)
    motifs=$(trailers_de "$c")
    while IFS= read -r t; do
      case "$t" in MAL"$(printf '\t')"*) nm=$((nm + 1)); echo "TRAILER-MAL-FORME $court ${t#MAL	}" ;; esac
    done <<EOF_T
$motifs
EOF_T
    while IFS= read -r -d '' f; do
      en_surface "$f" || continue
      nf=$((nf + 1))
      couvert=0
      while IFS= read -r t; do
        case "$t" in
          OK"$(printf '\t')"*)
            m=${t#OK	}
            case "$f" in ($m) couvert=1 ;; esac  # chemin-par-motif
            ;;
        esac
      done <<EOF_M
$motifs
EOF_M
      if [ "$couvert" -eq 0 ]; then nn=$((nn + 1)); echo "CHEMIN-NON-COUVERT $court $f"; fi
    done < <(git show --no-renames --name-only -z --format= "$c")
  done <<EOF_C
$commits
EOF_C
  echo "MARQUEUR-CHEMIN-BILAN commits=$nc fichiers-gardes=$nf non-couverts=$nn mal-formes=$nm"
  if [ "$nf" -eq 0 ]; then echo "MARQUEUR-CHEMIN-AUCUN-FICHIER"; return 1; fi
  [ "$nn" -eq 0 ]
}

autotest() {
  moi=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
  ko=0; n=0
  R='raison assez longue pour passer'
  H=plugin/planning-core/scripts/planning-hook.sh
  T=plugin/planning-core/scripts/tests/test-a.sh
  cas() { # <script> <nom> <attendu> <fonction de scénario>
    W=$(mktemp -d "${TMPDIR:-/tmp}/marqueur-chemin.XXXXXX") || exit 64
    ( cd "$W" && git init -q -b main . && git config user.name t && git config user.email t@t \
      && mkdir -p plugin/planning-core/scripts/tests && : > "$H" && : > "$T" && : > README.md && git add . \
      && git commit -q -m base && git checkout -q -b b && "$4" ) >/dev/null 2>&1
    ( cd "$W" && bash "$1" --base=main ) >/dev/null 2>&1; rc=$?
    rm -rf "$W"; n=$((n + 1))
    if [ "$rc" -eq "$3" ]; then echo "✓ AUTOTEST $2 (attendu $3, obtenu $rc)"
    else echo "✗ AUTOTEST $2 : attendu $3, obtenu $rc"; ko=$((ko + 1)); fi
  }
  touche() { echo "$1" >> "$H"; echo "$1" >> "$T"; git add -A; }
  s_deux_exacts() { touche x; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s — %s\nGate-Touche: %s — %s' "$H" "$R" "$T" "$R")"; }
  s_un_seul() { touche x; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s — %s' "$H" "$R")"; }
  s_glob() { touche x; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s — %s\nGate-Touche: plugin/planning-core/scripts/tests/test-*.sh — %s' "$H" "$R" "$R")"; }
  s_repertoire() { touche x; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s — %s\nGate-Touche: plugin/planning-core/scripts/tests/ — %s' "$H" "$R" "$R")"; }
  s_virgule() { touche x; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s, %s — %s' "$H" "$T" "$R")"; }
  s_hors_surface() { echo x >> README.md; git add -A; git commit -q -m "sujet sans surface"; }
  s_autre_commit() { echo x >> "$H"; git add -A; git commit -q -m "$(printf 'sujet\n\nGate-Touche: %s — %s' "$H" "$R")"; echo y >> "$T"; git add -A; git commit -q -m "sujet sans trailer"; }
  s_renommage_sortant() { mkdir -p docs; git mv "$T" docs/test-a.sh; git commit -q -m "sujet renommage"; }
  s_suppression() { git rm -q "$T"; git commit -q -m "sujet suppression"; }
  for m in "" mutant; do
    script=$moi
    if [ -n "$m" ]; then
      script=$(mktemp "${TMPDIR:-/tmp}/marqueur-chemin-mutant.XXXXXX") || exit 64
      # MUTANT-TOUT-TRAILER : un fichier est couvert dès qu'un trailer conforme existe, quel que soit son motif
      awk '{ if (index($0, "# chemin-par-motif") > 0) print "            couvert=1"; else print }' "$moi" > "$script"
    fi
    if [ -z "$m" ]; then
      cas "$script" deux-trailers-exacts 0 s_deux_exacts
      cas "$script" un-trailer-pour-deux-fichiers 1 s_un_seul
      cas "$script" glob-de-suites-qui-couvre 0 s_glob
      cas "$script" repertoire-sans-etoile-ne-couvre-pas 1 s_repertoire
      cas "$script" motif-a-virgule 1 s_virgule
      cas "$script" aucun-fichier-garde 1 s_hors_surface
      cas "$script" trailer-dans-un-autre-commit 1 s_autre_commit
      cas "$script" renommage-sortant-de-la-surface 1 s_renommage_sortant
      cas "$script" suppression-sans-trailer 1 s_suppression
    else
      # le mutant doit faire VIRER au moins un cas attendu rouge : il est alors tué
      avant=$ko
      cas "$script" MUTANT-un-trailer-pour-deux-fichiers 0 s_un_seul   # attendu 0 SOUS LE MUTANT (l'original rend 1)
      cas "$script" MUTANT-repertoire-sans-etoile 0 s_repertoire
      if [ "$ko" -eq "$avant" ]; then echo "✓ AUTOTEST MUTANT-TOUT-TRAILER tué (le mutant accepte les deux cas que l'original refuse)"
      else echo "✗ AUTOTEST MUTANT-TOUT-TRAILER non tué"; fi
      rm -f "$script"
    fi
  done
  echo "AUTOTEST cas=$n ko=$ko"
  [ "$ko" -eq 0 ]
}

case "${1:-}" in
  --autotest) autotest; exit $? ;;
  --base=*) base=${1#--base=}; [ -n "$base" ] || { echo "usage : $0 --base=<ref>" >&2; exit 64; }
            controle "$base"; exit $? ;;
  *) echo "usage : $0 --base=<ref>  |  $0 --autotest" >&2; exit 64 ;;
esac
