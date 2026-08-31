#!/usr/bin/env bash
# test-skill-doc-paths.sh — Garde-fou de convention : aucune commande documentée dans un
# SKILL.md de conductor ne doit référencer un chemin `plugin/*/scripts/` (chemin du dépôt de
# dev, jamais présent dans un lab installé — la convention posée est `.claude/scripts/<script>`,
# le chemin sous lequel l'installeur matérialise les scripts d'un module).
#
# Né d'une revue (Phase 38, lot 6) : la section « Migration de runtime » de
# plugin/conductor/skills/vf-calibrate/SKILL.md documentait 6 commandes inexécutables dans un
# vrai lab. Aucune suite existante ne pouvait le voir : elles exercent les scripts directement,
# jamais le texte des SKILL.md.
#
# Simple et générique par construction (grep de motif) — pas une analyse syntaxique des blocs de
# code : un garde-fou de convention, pas un parseur markdown.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONDUCTOR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATTERN='plugin/[a-zA-Z0-9_-]+/scripts/'

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# La fonction sous test : compte les occurrences du motif interdit dans un fichier donné.
count_forbidden_paths() { # <fichier> -> imprime le compte
  grep -Eco "$PATTERN" "$1" 2>/dev/null || true
}

echo "== test-skill-doc-paths =="

# === Cas 1 — rouge : fixture reproduisant le SKILL.md AVANT correctif (chemin de dépôt de dev) ===
FIXTURE_BAD="$TMP/skill-bad.md"
cat > "$FIXTURE_BAD" <<'EOF'
### 1. Détecter l'opportunité

```sh
plugin/conductor/scripts/runtime-registry.sh list-installed
```

### 4. Réversibilité

```sh
plugin/conductor/scripts/verify-runtime-reversibility.sh --target <cible>
```
EOF
# Garde anti-fixture-morte : le fichier existe et n'est pas vide avant qu'on en tire une mesure.
if [ -s "$FIXTURE_BAD" ]; then
  ok "1 fixture rouge non vide (anti-fixture-morte)"
else
  ko "1 fixture rouge non vide (anti-fixture-morte)" "fichier vide ou absent : $FIXTURE_BAD"
fi

got="$(count_forbidden_paths "$FIXTURE_BAD")"
if [ "$got" -eq 2 ]; then
  ok "2 rouge détecté sur fixture pré-correctif (attendu=2, obtenu=$got)"
else
  ko "2 rouge détecté sur fixture pré-correctif" "attendu=2 obtenu=$got"
fi

# === Cas 3 — vert : la même fixture réécrite avec la convention `.claude/scripts/` ================
FIXTURE_GOOD="$TMP/skill-good.md"
sed 's#plugin/conductor/scripts/#.claude/scripts/#g' "$FIXTURE_BAD" > "$FIXTURE_GOOD"
got="$(count_forbidden_paths "$FIXTURE_GOOD")"
if [ "$got" -eq 0 ]; then
  ok "3 vert sur réécriture licite en .claude/scripts/ (attendu=0, obtenu=$got)"
else
  ko "3 vert sur réécriture licite en .claude/scripts/" "attendu=0 obtenu=$got"
fi

# === Cas 4 — mutant confiné : une prose qui MENTIONNE le module sans chemin de scripts reste verte
FIXTURE_PROSE="$TMP/skill-prose.md"
printf 'Le module plugin/conductor porte ses scripts sous .claude/scripts/ une fois installé.\n' > "$FIXTURE_PROSE"
got="$(count_forbidden_paths "$FIXTURE_PROSE")"
if [ "$got" -eq 0 ]; then
  ok "4 prose citant le module sans /scripts/ reste verte (attendu=0, obtenu=$got)"
else
  ko "4 prose citant le module sans /scripts/ reste verte" "attendu=0 obtenu=$got"
fi

# === Cas 5 — régression réelle : tous les SKILL.md de conductor sont propres AUJOURD'HUI ==========
total=0
skill_files=$(find "$CONDUCTOR_DIR/skills" -name 'SKILL.md' 2>/dev/null)
if [ -z "$skill_files" ]; then
  ko "5 SKILL.md de conductor trouvés" "aucun fichier trouvé sous $CONDUCTOR_DIR/skills"
else
  ok "5 SKILL.md de conductor trouvés ($(echo "$skill_files" | wc -l | tr -d ' ') fichiers)"
fi

while IFS= read -r f; do
  [ -z "$f" ] && continue
  c="$(count_forbidden_paths "$f")"
  total=$((total + c))
  if [ "$c" -gt 0 ]; then
    echo "    ! $f : $c occurrence(s) de $PATTERN"
  fi
done <<< "$skill_files"

if [ "$total" -eq 0 ]; then
  ok "6 aucun SKILL.md de conductor ne référence plugin/*/scripts/ (obtenu=$total)"
else
  ko "6 aucun SKILL.md de conductor ne référence plugin/*/scripts/" "obtenu=$total occurrence(s), attendu=0"
fi

# === Cas 7 — vf-calibrate/SKILL.md précisément à 0 (le fichier corrigé par ce mandat) ==============
CALIBRATE="$CONDUCTOR_DIR/skills/vf-calibrate/SKILL.md"
got="$(count_forbidden_paths "$CALIBRATE")"
if [ "$got" -eq 0 ]; then
  ok "7 vf-calibrate/SKILL.md corrigé (attendu=0, obtenu=$got)"
else
  ko "7 vf-calibrate/SKILL.md corrigé" "attendu=0 obtenu=$got"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
