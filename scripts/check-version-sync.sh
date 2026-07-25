#!/usr/bin/env bash
# check-version-sync.sh — Gate de cohérence des sources de version/compteur du repo (ADR-054).
#
# La fiche marketplace vue par l'utilisateur (marketplace.json) et les badges README avaient
# dérivé de 2 releases par rapport à VERSION/plugin.json (vécu terrain 2026-07 : fiche 2.26.0,
# installé 2.27.1, badge README 2.26.0/16 modules pour 17 réels). Ce gate rend la synchro
# machine-enforced — appelé par check-release-tag.sh (pre-push).
#
# Sources comparées au canon VERSION (racine) :
#   1. plugin/.claude-plugin/plugin.json   .version
#   2. .claude-plugin/marketplace.json     .plugins[0].version   (la FICHE d'install)
#   3. badge version README.md             (img.shields.io/badge/version-X.Y.Z-…)
#   4. badge version README.fr.md
#   5. compteur de modules : badges + texte des 2 README vs nombre réel de plugin/*/module.json
#
# Parsing grep/sed VOLONTAIREMENT (pas de jq : ce gate doit tourner même sans jq installé).
# Codes de sortie : 0 = synchro · 1 = dérive détectée · 2 = erreur d'usage
set -uo pipefail

# Racine dérivée de l'emplacement du script (scripts/ vit à la racine) — PAS du cwd :
# `git rev-parse` depuis un autre repo résoudrait la mauvaise racine (piège vécu au premier run).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
ok() { echo "[check-version-sync] ✓ $*"; }
ko() { echo "[check-version-sync] ✗ $*" >&2; FAIL=1; }

canon="$(tr -d 'v[:space:]' < "$ROOT/VERSION")"
[ -n "$canon" ] || { echo "[check-version-sync] VERSION vide" >&2; exit 2; }

json_version()  { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1; }
badge_version() { grep -o 'badge/version-[0-9][0-9.]*' "$1" | head -1 | sed 's|badge/version-||'; }
badge_modules() { grep -o 'badge/modules-[0-9][0-9]*' "$1" | head -1 | sed 's|badge/modules-||'; }

v="$(json_version "$ROOT/plugin/.claude-plugin/plugin.json")"
if [ "$v" = "$canon" ]; then ok "plugin.json $v"; else ko "plugin/.claude-plugin/plugin.json version='$v' ≠ VERSION='$canon'"; fi

v="$(json_version "$ROOT/.claude-plugin/marketplace.json")"
if [ "$v" = "$canon" ]; then ok "marketplace.json $v"; else ko ".claude-plugin/marketplace.json version='$v' ≠ VERSION='$canon' (c'est la FICHE vue à l'install)"; fi

for f in README.md README.fr.md; do
  v="$(badge_version "$ROOT/$f")"
  if [ "$v" = "$canon" ]; then ok "$f badge version $v"; else ko "$f badge version='$v' ≠ VERSION='$canon'"; fi
done

real=$(ls -d "$ROOT"/plugin/*/module.json 2>/dev/null | grep -c .)
for f in README.md README.fr.md; do
  b="$(badge_modules "$ROOT/$f")"
  if [ "$b" = "$real" ]; then ok "$f badge modules $b"; else ko "$f badge modules='$b' ≠ réel=$real (plugin/*/module.json)"; fi
done
t="$(grep -o '[0-9][0-9]* modules total' "$ROOT/README.md" | head -1 | grep -o '^[0-9]*')"
if [ -n "$t" ] && [ "$t" != "$real" ]; then ko "README.md texte '$t modules total' ≠ réel=$real"; fi
t="$(grep -o '[0-9][0-9]* modules au total' "$ROOT/README.fr.md" | head -1 | grep -o '^[0-9]*')"
if [ -n "$t" ] && [ "$t" != "$real" ]; then ko "README.fr.md texte '$t modules au total' ≠ réel=$real"; fi

if [ "$FAIL" -eq 1 ]; then
  echo "[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine)." >&2
  exit 1
fi
echo "[check-version-sync] ✓ sources synchronisées (v$canon, $real modules)"
exit 0
