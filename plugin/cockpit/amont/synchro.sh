#!/usr/bin/env bash
# synchro.sh — reproductibilité de la copie vendorisée de floorplan (P67-D-11, plugin cockpit).
# L'arbre skills/cockpit-moteur = amont floorplan v0.6.0 @ 92d6854 + patchs (un diff par fichier amont
# touché, amont/patches/) + ajouts (lignes AJOUT de VENDORED.txt). Aucun verbe sauf `empreintes` et
# `regenerer-patch <chemin> <clone>` ne touche au réseau ni à un clone : tout se rejoue hors ligne.
#
#   reconstruire <clone> <sortie>        amont + patchs + ajouts -> <sortie> (dossier neuf)
#   empreintes <clone>                   manifeste sha256 de skills/floorplan + LICENSE de l'amont (stdout)
#   regenerer-patch <chemin> [<clone>]   réécrit le diff d'un fichier amont (version amont : clone, sinon
#                                        reconstruite par inversion du diff existant) ; supprime le diff si identique
#   verifier [<arbre>]                   retire les ajouts, inverse les diffs, compare au manifeste
# Codes : 0 ok / amont retrouvé · 1 écart nommé · 2 non vérifiable · 64 usage.
# Piège : `git apply` lancé sous un dépôt lit les chemins depuis la racine du dépôt et ignore en silence les
# autres ; toute application se fait donc dans un dossier jetable hors dépôt, sous GIT_CEILING_DIRECTORIES.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$HERE/patches"
MANIFEST="$HERE/amont-92d6854.sha256"
ARBRE="$HERE/../skills/cockpit-moteur"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null LC_ALL=C

TMPS=()
cleanup() { for d in ${TMPS[@]+"${TMPS[@]}"}; do rm -rf "$d"; done; }
trap cleanup EXIT
tmpdir() { local d; d="$(mktemp -d)" || exit 2; TMPS+=("$d"); printf '%s' "$d"; }
die() { echo "synchro: $*" >&2; exit "${2:-2}"; }
nom_patch() { local p="${1//\//__}"; printf '%s.diff' "$p"; }

# hash_tree <dossier> : « <sha256>  <chemin relatif> » par fichier, triées (node : portable macOS / Linux)
hash_tree() {
  node - "$1" <<'JS'
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const root = process.argv[2], out = [];
const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else if (e.isFile()) out.push([path.relative(root, p).split(path.sep).join('/'), crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')]); } };
walk(root);
out.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
process.stdout.write(out.map(([p, h]) => `${h}  ${p}\n`).join(''));
JS
}

# appliquer <dossier> [-R] : chaque diff de patches/, sous plafond git, chacun doit dire « Applied patch »
appliquer() {
  local dir="$1" rev="${2:-}" p out ceiling
  ceiling="$(dirname "$dir")"
  for p in "$PATCHES"/*.diff; do
    [ -e "$p" ] || continue
    out="$(cd "$dir" && GIT_CEILING_DIRECTORIES="$ceiling" git apply -p1 --verbose $rev "$p" 2>&1)" || { echo "$out" >&2; die "patch non applicable : $(basename "$p")" 1; }
    case "$out" in *"Applied patch"*"cleanly"*) : ;; *) die "patch sans effet : $(basename "$p")" 1 ;; esac
  done
  find "$dir" -type d -empty -delete 2>/dev/null || true
}

ajouts() { # chemins des lignes AJOUT de VENDORED.txt de <arbre>
  [ -f "$1/VENDORED.txt" ] || die "VENDORED.txt introuvable dans $1"
  sed -n 's/^AJOUT \(.*\)$/\1/p' "$1/VENDORED.txt"
}

cmd_empreintes() {
  local clone="${1:-}"; [ -d "$clone/skills/floorplan" ] || die "clone amont introuvable : $clone" 64
  local t; t="$(tmpdir)"; cp -R "$clone/skills/floorplan/." "$t/" && cp "$clone/LICENSE" "$t/LICENSE" || die "copie impossible"
  hash_tree "$t"
}

cmd_reconstruire() {
  local clone="${1:-}" sortie="${2:-}"; { [ -d "$clone/skills/floorplan" ] && [ -n "$sortie" ]; } || die "usage : reconstruire <clone> <sortie>" 64
  local t a; t="$(tmpdir)"
  cp -R "$clone/skills/floorplan/." "$t/" && cp "$clone/LICENSE" "$t/LICENSE" || die "copie impossible"
  appliquer "$t"
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    mkdir -p "$t/$(dirname "$a")" && cp "$ARBRE/$a" "$t/$a" || die "ajout introuvable : $a" 1
  done < <(ajouts "$ARBRE")
  mkdir -p "$sortie" && cp -R "$t/." "$sortie/" || die "écriture impossible : $sortie"
}

cmd_regenerer() {
  local rel="${1:-}" clone="${2:-}"; [ -n "$rel" ] || die "usage : regenerer-patch <chemin> [<clone>]" 64
  local t up; t="$(tmpdir)"; mkdir -p "$t/a/$(dirname "$rel")" "$t/b/$(dirname "$rel")"
  local pf="$PATCHES/$(nom_patch "$rel")"
  if [ -n "$clone" ]; then
    local src="$clone/skills/floorplan/$rel"; [ "$rel" = LICENSE ] && src="$clone/LICENSE"
    [ -f "$src" ] || die "fichier absent de l'amont : $rel" 1
    cp "$src" "$t/a/$rel"
  else
    [ -f "$pf" ] || die "ni clone ni diff existant pour $rel" 1
    [ -f "$ARBRE/$rel" ] && cp "$ARBRE/$rel" "$t/a/$rel"
    (cd "$t/a" && GIT_CEILING_DIRECTORIES="$t" git apply -p1 -R "$pf") || die "inversion impossible : $rel" 1
  fi
  [ -f "$ARBRE/$rel" ] && cp "$ARBRE/$rel" "$t/b/$rel"
  local bsrc="$t/b/$rel"; [ -f "$bsrc" ] || bsrc=/dev/null
  mkdir -p "$PATCHES"
  local d; d="$(cd "$t" && git diff --no-index --no-prefix "a/$rel" "${bsrc/#$t\//}")"
  if [ -z "$d" ]; then rm -f "$pf"; echo "identique à l'amont : diff supprimé ($rel)"; return 0; fi
  printf '%s\n' "$d" | sed '/^diff --git /d;/^index /d;/^deleted file mode /d' > "$pf"
  echo "diff écrit : $(basename "$pf")"
}

cmd_verifier() {
  local arbre="${1:-$ARBRE}"; [ -d "$arbre" ] || die "arbre introuvable : $arbre"
  [ -f "$MANIFEST" ] || die "manifeste introuvable : $MANIFEST"
  [ -d "$PATCHES" ] || die "dossier de diffs introuvable : $PATCHES"
  local t a; t="$(tmpdir)"; cp -R "$arbre/." "$t/" || die "copie impossible"
  while IFS= read -r a; do [ -n "$a" ] && rm -f "$t/$a"; done < <(ajouts "$arbre")
  appliquer "$t" -R
  local mine; mine="$(tmpdir)/h.txt"; hash_tree "$t" > "$mine"
  if cmp -s "$mine" "$MANIFEST"; then echo "synchro : amont v0.6.0 @ 92d6854 retrouvé à l'octet ($(wc -l < "$MANIFEST" | tr -d ' ') fichiers)"; return 0; fi
  echo "synchro : écart avec l'amont :" >&2
  comm -3 "$MANIFEST" "$mine" | sed 's/^/  /' >&2
  return 1
}

verbe="${1:-}"; [ $# -gt 0 ] && shift
case "$verbe" in
  reconstruire) cmd_reconstruire "$@" ;;
  empreintes) cmd_empreintes "$@" ;;
  regenerer-patch) cmd_regenerer "$@" ;;
  verifier) cmd_verifier "$@" ;;
  *) echo "usage : synchro.sh {reconstruire <clone> <sortie>|empreintes <clone>|regenerer-patch <chemin> [<clone>]|verifier [<arbre>]}" >&2; exit 64 ;;
esac
