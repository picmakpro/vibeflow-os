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
# Phrase « N modules » du corps des README. Vécu 2026-07-26 : l'ancien grep ('N modules total')
# ne matchait plus la formulation issue de la refonte v2.36.1 et le contrôle était SAUTÉ EN
# SILENCE (garde [ -n "$t" ]) — un gate qui ne trouve pas sa cible doit le dire, pas se taire.
t="$(grep -o '[0-9][0-9]* modules, each versioned' "$ROOT/README.md" | head -1 | grep -o '^[0-9]*')"
if [ -z "$t" ]; then ko "README.md : phrase « N modules, each versioned » introuvable (reformulée ? réaligner ce grep)"
elif [ "$t" != "$real" ]; then ko "README.md texte '$t modules' ≠ réel=$real"
else ok "README.md texte $t modules"; fi
t="$(grep -o '[0-9][0-9]* modules, chacun versionné' "$ROOT/README.fr.md" | head -1 | grep -o '^[0-9]*')"
if [ -z "$t" ]; then ko "README.fr.md : phrase « N modules, chacun versionné » introuvable (reformulée ? réaligner ce grep)"
elif [ "$t" != "$real" ]; then ko "README.fr.md texte '$t modules' ≠ réel=$real"
else ok "README.fr.md texte $t modules"; fi

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

# 8. En-tête « **Version** » des README de modules ↔ VERSION du module. Vécu 2026-07-26 :
#    seule zone de version du repo qu'aucun gate ne regardait — dérive constatée sur 14/14
#    modules qui en déclarent une (conductor affichait v1.0.0 pour v1.14.1). Un README sans
#    ligne « **Version** » n'est pas fautif (les bundles n'en déclarent pas) — on ne vérifie
#    que ce qui est déclaré.
hdr_fail=0; hdr_n=0
for mj in "$ROOT"/plugin/*/module.json; do
  mod_dir="$(dirname "$mj")"; mod="$(basename "$mod_dir")"
  [ -f "$mod_dir/README.md" ] && [ -f "$mod_dir/VERSION" ] || continue
  hline="$(grep '\*\*Version\*\*' "$mod_dir/README.md" | head -1)"
  [ -n "$hline" ] || continue
  hdr_n=$((hdr_n+1))
  mv_ver="$(tr -d 'v[:space:]' < "$mod_dir/VERSION")"
  h_ver="$(echo "$hline" | grep -o 'v[0-9][0-9.]*' | head -1 | tr -d 'v')"
  if [ "$h_ver" != "$mv_ver" ]; then
    ko "plugin/$mod/README.md : en-tête Version v$h_ver ≠ VERSION v$mv_ver"; hdr_fail=1
  fi
done
[ "$hdr_fail" -eq 0 ] && ok "en-tête Version des README de modules : $hdr_n déclarés, tous alignés"

# 9. Compte de suites de tests cité par les README racine ↔ suites réellement découvertes par
#    la CI (même commande de découverte que .github/workflows/ci.yml). Même famille que le
#    point précédent : « 36 suites » affiché pour 37 réelles, chiffre jamais gaté.
suites_real="$(find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh' 2>/dev/null | grep -c .)"
for r in README.md README.fr.md; do
  s="$(grep -o '[0-9][0-9]* suites' "$ROOT/$r" | head -1 | grep -o '^[0-9]*')"
  if [ -z "$s" ]; then ko "$r : aucune mention « N suites » trouvée (reformulée ? réaligner ce grep)"
  elif [ "$s" != "$suites_real" ]; then ko "$r : '$s suites' ≠ réel=$suites_real (find */tests/test-*.sh)"
  else ok "$r suites $s"; fi
done

if [ "$FAIL" -eq 1 ]; then
  echo "[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine)." >&2
  exit 1
fi
echo "[check-version-sync] ✓ sources synchronisées (v$canon, $real modules)"
exit 0
