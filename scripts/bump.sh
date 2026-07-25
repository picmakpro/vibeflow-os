#!/usr/bin/env bash
# bump.sh — Bump de la version racine du repo vibeflow-os, en un geste et sans oubli.
#
# Écrit le MÊME numéro dans toutes les sources de version racine (celles que
# check-version-sync.sh compare au canon), puis insère un squelette d'entrée en tête
# du CHANGELOG.md racine :
#   1. VERSION                               (canon, format vX.Y.Z)
#   2. plugin/.claude-plugin/plugin.json     .version
#   3. .claude-plugin/marketplace.json       .plugins[0].version (la FICHE d'install)
#   4. badge version README.md               (img.shields.io/badge/version-X.Y.Z-…)
#   5. badge version README.fr.md
#   6. CHANGELOG.md                          squelette « ## [vX.Y.Z] — <date> » en tête
#
# Ne crée PAS le tag git : c'est l'étape post-merge (cf. CLAUDE.md + check-release-tag.sh).
#
# Usage :
#   bump.sh <X.Y.Z | vX.Y.Z>       # applique le bump
#   bump.sh --dry-run <X.Y.Z>      # montre ce qui changerait, n'écrit rien
#   bump.sh --help
#
# Idempotent : relancer avec la même version ne change rien (et ne duplique pas
# l'entrée CHANGELOG). Échoue bruyamment si un fichier attendu manque.
# Codes de sortie : 0 = ok · 1 = fichier attendu manquant / écriture impossible · 2 = usage
set -euo pipefail

# Racine dérivée de l'emplacement du script (scripts/ vit à la racine) — PAS du cwd.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

DRY=false
NEW=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=true ;;
    -h|--help) awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; exit 0 ;;
    -*) echo "[bump] argument inconnu : $a" >&2; exit 2 ;;
    *)  [ -z "$NEW" ] || { echo "[bump] une seule version attendue (reçu '$NEW' puis '$a')" >&2; exit 2; }
        NEW="$a" ;;
  esac
done
[ -n "$NEW" ] || { echo "[bump] usage : bump.sh [--dry-run] <X.Y.Z>" >&2; exit 2; }

# Normalisation : on accepte X.Y.Z ou vX.Y.Z ; canon interne sans préfixe.
NEW="${NEW#v}"
echo "$NEW" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || { echo "[bump] version invalide : '$NEW' (attendu X.Y.Z, ex. 2.32.0)" >&2; exit 2; }
TAG="v$NEW"

# ── Préflight : tous les fichiers attendus doivent exister — sinon échec bruyant. ──────────
FILES=(
  "$ROOT/VERSION"
  "$ROOT/plugin/.claude-plugin/plugin.json"
  "$ROOT/.claude-plugin/marketplace.json"
  "$ROOT/README.md"
  "$ROOT/README.fr.md"
  "$ROOT/CHANGELOG.md"
)
MISSING=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || { echo "[bump] ✗ fichier attendu manquant : ${f#"$ROOT"/}" >&2; MISSING=1; }
done
[ "$MISSING" -eq 0 ] || { echo "[bump] abandon — rien n'a été modifié." >&2; exit 1; }

CUR="$(tr -d 'v[:space:]' < "$ROOT/VERSION")"
[ -n "$CUR" ] || { echo "[bump] VERSION vide" >&2; exit 1; }

changed=0
apply() { # apply <fichier-relatif> <ancien> <nouveau> — écrit sauf --dry-run, trace toujours
  local rel="$1" old="$2" new="$3"
  if [ "$old" = "$new" ]; then
    echo "[bump] = $rel déjà à $new"
    return 0
  fi
  changed=1
  if $DRY; then
    echo "[bump] ~ $rel : $old → $new (dry-run)"
  else
    echo "[bump] ✓ $rel : $old → $new"
  fi
}

json_version() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1; }
badge_version() { grep -o 'badge/version-[0-9][0-9.]*' "$1" | head -1 | sed 's|badge/version-||'; }

# sed -i portable (BSD/macOS vs GNU).
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

# ── 1. VERSION (canon, préfixe v conservé — c'est le format historique du fichier) ─────────
apply "VERSION" "v$CUR" "$TAG"
$DRY || printf '%s\n' "$TAG" > "$ROOT/VERSION"

# ── 2+3. Manifestes JSON (première clé "version" de chaque fichier) ────────────────────────
# Lecture sed (même contrainte no-jq que check-version-sync.sh) ; écriture python3
# (prérequis du repo, cf. INSTALL.md) — l'adresse sed `0,/re/` n'existe pas en sed BSD.
for rel in "plugin/.claude-plugin/plugin.json" ".claude-plugin/marketplace.json"; do
  f="$ROOT/$rel"
  old="$(json_version "$f")"
  [ -n "$old" ] || { echo "[bump] ✗ aucune clé \"version\" trouvée dans $rel" >&2; exit 1; }
  apply "$rel" "$old" "$NEW"
  [ "$old" = "$NEW" ] && continue
  $DRY || python3 - "$f" "$old" "$NEW" <<'PY'
import re, sys
path, old, new = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
s2 = re.sub(r'("version"\s*:\s*")' + re.escape(old) + r'(")', r'\g<1>' + new + r'\g<2>', s, count=1)
if s == s2:
    sys.exit(f"[bump] ✗ substitution version impossible dans {path}")
open(path, "w", encoding="utf-8").write(s2)
PY
done

# ── 4+5. Badges des README ─────────────────────────────────────────────────────────────────
for rel in "README.md" "README.fr.md"; do
  f="$ROOT/$rel"
  old="$(badge_version "$f")"
  [ -n "$old" ] || { echo "[bump] ✗ aucun badge version (img.shields.io/badge/version-…) dans $rel" >&2; exit 1; }
  apply "$rel (badge)" "$old" "$NEW"
  $DRY || sed_i "s|badge/version-$old|badge/version-$NEW|g" "$f"
done

# ── 6. Squelette d'entrée en tête du CHANGELOG racine (idempotent) ─────────────────────────
CHANGELOG="$ROOT/CHANGELOG.md"
if grep -q "^## \[$TAG\]" "$CHANGELOG"; then
  echo "[bump] = CHANGELOG.md a déjà une entrée $TAG"
else
  changed=1
  if $DRY; then
    echo "[bump] ~ CHANGELOG.md : insertion du squelette « ## [$TAG] — $(date +%F) » (dry-run)"
  else
    python3 - "$CHANGELOG" "$TAG" "$(date +%F)" <<'PY'
import sys
path, tag, date = sys.argv[1:4]
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
skeleton = f"## [{tag}] — {date}\n\n<!-- TODO: résumé de la release {tag} -->\n\n"
# Insertion juste avant la première entrée existante ; sinon en fin de fichier.
for i, l in enumerate(lines):
    if l.startswith("## ["):
        lines.insert(i, skeleton)
        break
else:
    lines.append("\n" + skeleton)
open(path, "w", encoding="utf-8").write("".join(lines))
PY
    echo "[bump] ✓ CHANGELOG.md : squelette « ## [$TAG] — $(date +%F) » inséré (TODO à remplir)"
  fi
fi

# ── Bilan ──────────────────────────────────────────────────────────────────────────────────
if $DRY; then
  if [ "$changed" -eq 0 ]; then echo "[bump] ✓ dry-run : tout est déjà à $TAG, rien à faire"
  else echo "[bump] dry-run terminé — relancer sans --dry-run pour appliquer"; fi
  exit 0
fi

if [ "$changed" -eq 0 ]; then
  echo "[bump] ✓ tout était déjà à $TAG (idempotent, rien réécrit)"
else
  SYNC="$ROOT/scripts/check-version-sync.sh"
  if [ -f "$SYNC" ]; then
    bash "$SYNC" || { echo "[bump] ✗ check-version-sync.sh échoue après bump — vérifier ci-dessus" >&2; exit 1; }
  fi
  echo "[bump] ✓ bump $CUR → $NEW appliqué."
  echo "  Reste à faire : remplir l'entrée CHANGELOG, commit, merge sur main, puis :"
  echo "    git tag -a $TAG -m \"$TAG — <résumé>\" <commit-de-release> && git push origin $TAG"
  echo "    bash scripts/check-release-tag.sh --remote"
fi
exit 0
