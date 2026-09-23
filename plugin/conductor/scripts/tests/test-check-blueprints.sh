#!/usr/bin/env bash
# test-check-blueprints.sh — banc de check-blueprints.sh.
# Un contrôle à trois codes de sortie porte un témoin PAR CODE, un témoin de portée (il mesure bien
# l'arbre réel), et un jumeau négatif (une mutation du réel le fait rougir). Sans le jumeau, un banc
# vert ne prouve que l'absence de faux positifs.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-blueprints.sh"
REPO="$(cd "$(dirname "$0")/../../../.." && pwd)"
PASS=0; FAIL=0

assert() { # assert "label" "obtenu" "attendu"
  if printf '%s' "$2" | grep -qF "$3"; then echo "  ✅ $1"; PASS=$((PASS+1))
  else echo "  ❌ $1"; echo "     attendu: $3"; echo "     obtenu : $2"; FAIL=$((FAIL+1)); fi
}
assert_code() { # assert_code "label" <obtenu> <attendu>
  if [ "$2" = "$3" ]; then echo "  ✅ $1 (exit $2)"; PASS=$((PASS+1))
  else echo "  ❌ $1 — attendu exit $3, obtenu $2"; FAIL=$((FAIL+1)); fi
}

# fabrique une racine jetable portant un blueprint
mkbp() { # mkbp <yaml|noyaml> [ligne effort]
  local mode="$1" root; root="$(mktemp -d)"
  mkdir -p "$root/content/agents"
  local f="$root/content/agents/fixture.blueprint.md"
  if [ "$mode" = "noyaml" ]; then
    printf '# BLUEPRINT sans frontmatter cible\n\nRien à instancier.\n' > "$f"
  else
    {
      printf '# BLUEPRINT — fixture\n\n## Frontmatter cible\n\n```yaml\n---\n'
      printf 'name: fixture\n'
      printf 'description: Agent de fixture pour le banc de check-blueprints, description assez longue.\n'
      printf 'tools: Read, Write, Glob, Grep\n'
      printf 'model: sonnet\n'
      [ "${2:-avec}" = "avec" ] && printf 'effort: medium\n'
      printf 'memory: project\n'
      printf -- '---\n```\n'
    } > "$f"
  fi
  printf '%s' "$root"
}

echo "=== T1 — le corpus RÉEL du dépôt est conforme (témoin de portée) ==="
out=$(bash "$SCRIPT" --blueprints-dir="$REPO" 2>&1); code=$?
assert_code "T1.1 — exit 0 sur l'arbre réel" "$code" "0"
assert "T1.2 — compte les blueprints trouvés" "$out" "blueprint(s) : frontmatter cible conforme"
assert "T1.3 — la portée n'est pas vide"      "$out" "9 blueprint(s)"

echo "=== T2 — blueprint sans effort → refus (témoin du code 1) ==="
R=$(mkbp yaml sans)
out=$(bash "$SCRIPT" --blueprints-dir="$R" 2>&1); code=$?
assert_code "T2.1 — exit 1" "$code" "1"
assert "T2.2 — motif exact remonté du gate" "$out" "effort absent"
assert "T2.3 — dit la conséquence réelle"   "$out" "guard-agent-write.sh"
rm -rf "$R"

echo "=== T3 — blueprint sans bloc yaml → refus dédié ==="
R=$(mkbp noyaml)
out=$(bash "$SCRIPT" --blueprints-dir="$R" 2>&1); code=$?
assert_code "T3.1 — exit 1" "$code" "1"
assert "T3.2 — motif distinct de T2" "$out" "ne dit pas quoi instancier"
rm -rf "$R"

echo "=== T4 — cible vide → INDÉTERMINÉ, jamais un vert (témoin du code 3) ==="
R="$(mktemp -d)"
out=$(bash "$SCRIPT" --blueprints-dir="$R" 2>&1); code=$?
assert_code "T4.1 — exit 3" "$code" "3"
assert "T4.2 — nomme le trou" "$out" "aucun blueprint trouvé"
echo "=== T5 — cible vide tolérée explicitement → 0 ==="
out=$(bash "$SCRIPT" --blueprints-dir="$R" --allow-empty 2>&1); code=$?
assert_code "T5.1 — exit 0" "$code" "0"
assert "T5.2 — le dit quand même" "$out" "cible vide tolérée"
rm -rf "$R"

echo "=== T6 — --hook : silence de CODE, jamais silence de MESSAGE ==="
R=$(mkbp yaml sans)
out=$(bash "$SCRIPT" --blueprints-dir="$R" --hook 2>&1); code=$?
assert_code "T6.1 — exit 0 sous --hook" "$code" "0"
assert "T6.2 — le refus reste imprimé" "$out" "effort absent"
rm -rf "$R"

echo "=== T7 — --file sur un blueprint conforme ==="
R=$(mkbp yaml avec)
out=$(bash "$SCRIPT" --file "$R/content/agents/fixture.blueprint.md" 2>&1); code=$?
assert_code "T7.1 — exit 0" "$code" "0"
assert "T7.2 — portée à un seul" "$out" "1 blueprint(s)"
rm -rf "$R"

echo "=== T8 — JUMEAU NÉGATIF : muter un blueprint RÉEL doit faire rougir ==="
R="$(mktemp -d)"; mkdir -p "$R/content/agents"
REAL="$(find "$REPO/plugin" -name '*.blueprint.md' | head -1)"
if [ -n "$REAL" ]; then
  # copie fidèle, puis on retire la SEULE ligne effort — rien d'autre ne change
  sed '/^effort:/d' "$REAL" > "$R/content/agents/mute.blueprint.md"
  if cmp -s "$REAL" "$R/content/agents/mute.blueprint.md"; then
    echo "  ❌ T8.0 — la mutation n'a rien changé, le témoin ne prouve rien"; FAIL=$((FAIL+1))
  else
    echo "  ✅ T8.0 — la mutation a bien modifié le fichier"; PASS=$((PASS+1))
  fi
  out=$(bash "$SCRIPT" --blueprints-dir="$R" 2>&1); code=$?
  assert_code "T8.1 — le gate rougit sur le réel muté" "$code" "1"
  assert "T8.2 — pour le bon motif" "$out" "effort absent"
else
  echo "  ❌ T8 — aucun blueprint réel trouvé, témoin impossible"; FAIL=$((FAIL+1))
fi
rm -rf "$R"

echo "=== T9 — argument inconnu → refus, jamais un skip muet ==="
out=$(bash "$SCRIPT" --nawak 2>&1); code=$?
assert_code "T9.1 — exit 1" "$code" "1"
assert "T9.2 — nomme l'argument" "$out" "nawak"

echo
echo "=== RÉSULTAT : $PASS OK · $FAIL KO ==="
[ "$FAIL" -eq 0 ] || exit 1
