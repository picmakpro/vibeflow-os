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
# Sources comparées par MODULE (VG-2 : le gate comptait les fichiers module.json sans jamais
# lire les versions — « sources synchronisées » affirmait plus large que ce qui était vérifié) :
#   6. plugin/<mod>/VERSION ↔ plugin/<mod>/module.json .version (triade par module)
#
# Parsing grep/sed VOLONTAIREMENT (pas de jq : ce gate doit tourner même sans jq installé).
# Codes de sortie : 0 = synchro · 1 = dérive détectée · 2 = erreur d'usage ·
#   3 = INDÉTERMINÉ (aucun plugin/*/module.json découvert : cible absente, aucun verdict — F13)
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
# Contrat de découverte (F13) : zéro module découvert = zéro verdict. Un « ✓ synchronisées »
# rendu sans avoir rien compté serait un faux vert (exit 3 = INDÉTERMINÉ, distinct de 0).
if [ "$real" -eq 0 ]; then
  echo "[check-version-sync] ✗ INDÉTERMINÉ : aucun plugin/*/module.json découvert sous $ROOT — cible absente, aucun verdict rendu" >&2
  exit 3
fi
for f in README.md README.fr.md; do
  b="$(badge_modules "$ROOT/$f")"
  if [ "$b" = "$real" ]; then ok "$f badge modules $b"; else ko "$f badge modules='$b' ≠ réel=$real (plugin/*/module.json)"; fi
done
t="$(grep -o '[0-9][0-9]* modules total' "$ROOT/README.md" | head -1 | grep -o '^[0-9]*')"
if [ -n "$t" ] && [ "$t" != "$real" ]; then ko "README.md texte '$t modules total' ≠ réel=$real"; fi
t="$(grep -o '[0-9][0-9]* modules au total' "$ROOT/README.fr.md" | head -1 | grep -o '^[0-9]*')"
if [ -n "$t" ] && [ "$t" != "$real" ]; then ko "README.fr.md texte '$t modules au total' ≠ réel=$real"; fi

# 6. Triade par module (VG-2) : plugin/<mod>/VERSION ↔ module.json .version. C'est la dérive
# qui a fait mentir le tableau README sur 13 modules (F1) sans qu'aucun gate ne la voie.
mod_fail=0
for mj in "$ROOT"/plugin/*/module.json; do
  mod_dir="$(dirname "$mj")"; mod="$(basename "$mod_dir")"
  vfile="$mod_dir/VERSION"
  if [ ! -f "$vfile" ]; then ko "plugin/$mod : fichier VERSION absent (module.json présent)"; mod_fail=1; continue; fi
  mv_ver="$(tr -d 'v[:space:]' < "$vfile")"
  mj_ver="$(json_version "$mj" | tr -d 'v[:space:]')"
  if [ -z "$mv_ver" ] || [ -z "$mj_ver" ]; then ko "plugin/$mod : version illisible (VERSION='$mv_ver', module.json='$mj_ver')"; mod_fail=1
  elif [ "$mv_ver" != "$mj_ver" ]; then ko "plugin/$mod : VERSION=$mv_ver ≠ module.json=$mj_ver"; mod_fail=1
  fi
done
[ "$mod_fail" -eq 0 ] && ok "triade par module : $real modules VERSION ↔ module.json alignés"

# 7. Historique des README : la première entrée citée doit être la VERSION courante.
#    Vécu terrain 2026-07-26 : les « 3 dernières entrées » des README étaient restées figées
#    5 releases en arrière (v2.31.1 affichée en tête pour un repo en v2.36.0) — aucun gate
#    ne regardait cette section, seule zone de version des README non couverte.
for r in README.md README.fr.md; do
  top_hist="$(grep -o '| `v[0-9][0-9.]*`' "$ROOT/$r" | head -1 | tr -d '|` v')"
  if [ -z "$top_hist" ]; then
    ko "$r : aucune entrée d'historique détectée (section « dernières entrées » attendue)"
  elif [ "$top_hist" != "$canon" ]; then
    ko "$r : historique en tête = v$top_hist ≠ VERSION v$canon (rafraîchir les 3 dernières entrées)"
  else
    ok "$r historique en tête v$top_hist"
  fi
done

if [ "$FAIL" -eq 1 ]; then
  echo "[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine)." >&2
  exit 1
fi
echo "[check-version-sync] ✓ sources synchronisées (v$canon, $real modules)"
exit 0
