#!/usr/bin/env bash
# test-verify-runtime-reversibility.sh — Suite de la preuve de réversibilité (Phase 38, MIGR-04).
#
# verify-runtime-reversibility.sh :
#   T1 — cycle install (setup, externe) -> bascule (--cache cache2, ajoute EXTRA.md DANS
#        skills/<mod>/, donc DANS le périmètre restauré par backup_module) -> retour (rollback) :
#        `comm -3` vide -> exit 0, message "réversibilité prouvée".
#   T2 — fixture volontairement cassée, engine RÉEL : le module bascule ajoute un fichier HORS du
#        périmètre que `backup_module`/`rollback_module` savent restaurer (`skills/<mod>` — un
#        second sous-dossier `skills/other-skill/` posé par le même module n'est PAS backuppé) :
#        après retour, ce fichier survit -> `comm -3` non vide -> exit 1, diff imprimée en clair.
#        Ce n'est jamais une fixture fabriquée pour tromper le gate : c'est un vrai trou mesuré du
#        couple backup/rollback (lot 3), exactement le genre de perte que MIGR-04 doit détecter.
#   T3 — usage : `--target` manquant -> exit 2.
#   T4 — cible sans registre installé (précondition non remplie) -> exit 3, aucune mesure.
#
# Convention : asserts numérotés, helpers ok()/ko(), exit 0 si tout passe, exit 1 sinon.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
GATE="$SCRIPTS_DIR/verify-runtime-reversibility.sh"
INSTALLER="$REPO/plugin/_internal/vibeflow-update.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-verify-runtime-reversibility (gate: $GATE) =="

if [ ! -f "$GATE" ] || [ ! -x "$GATE" ]; then
  ko "T0 : gate introuvable ou non exécutable ($GATE)"
  echo "== résultat : $pass OK / $fail KO =="
  exit 1
fi
ok "T0 : gate présent et exécutable"

if [ ! -f "$INSTALLER" ]; then
  ko "T0b : installer introuvable ($INSTALLER)"
  echo "== résultat : $pass OK / $fail KO =="
  exit 1
fi
ok "T0b : installer présent"

# Helper : construit une fixture de cible déjà installée (module "revtest", type SKILL.md racine)
# depuis cache1, prête à recevoir le cycle bascule->retour du gate.
setup_fixture() {
  local lab="$1"
  mkdir -p "$lab/cache1/revtest"
  cat > "$lab/cache1/revtest/module.json" <<'EOF'
{"name":"revtest","version":"v1.0.0","type":"skill"}
EOF
  echo "v1.0.0" > "$lab/cache1/revtest/VERSION"
  echo "# revtest skill" > "$lab/cache1/revtest/SKILL.md"
  VIBEFLOW_CACHE="$lab/cache1" bash "$INSTALLER" --target "$lab/target" install revtest >/dev/null 2>&1
}

# --- T1 : cycle vert (contenu ajouté DANS skills/<mod>, restauré par rollback) ---
LAB1="$(mktemp -d)"
setup_fixture "$LAB1"
cp -r "$LAB1/cache1" "$LAB1/cache2"
echo "extra content" > "$LAB1/cache2/revtest/EXTRA-NEVER-COPIED.md"   # hors du périmètre de pose (pas SKILL.md ni skills/), n'affecte rien.
mkdir -p "$LAB1/cache2/revtest/skills/revtest"
echo "# revtest skill (variante skills/<mod> nichée, backuppée)" > "$LAB1/cache2/revtest/skills/revtest/SKILL.md"

OUT1="$(bash "$GATE" --target "$LAB1/target" --cache "$LAB1/cache2" 2>&1)"
RC1=$?
if [ "$RC1" -eq 0 ] && printf '%s' "$OUT1" | grep -q 'réversibilité prouvée'; then
  ok "T1 : cycle install->bascule->retour -> comm -3 vide, exit 0, message 'réversibilité prouvée'"
else
  ko "T1 : attendu exit 0 + 'réversibilité prouvée', obtenu rc=$RC1, sortie : $(printf '%s' "$OUT1" | tail -3)"
fi
rm -rf "$LAB1"

# --- T2 : fixture cassée RÉELLE (fichier hors périmètre skills/<mod>, jamais restauré) ---
LAB2="$(mktemp -d)"
setup_fixture "$LAB2"
cp -r "$LAB2/cache1" "$LAB2/cache2"
mkdir -p "$LAB2/cache2/revtest/skills/other-skill"
echo "# autre skill (hors skills/revtest, backup_module ne le voit jamais)" \
  > "$LAB2/cache2/revtest/skills/other-skill/SKILL.md"

OUT2="$(bash "$GATE" --target "$LAB2/target" --cache "$LAB2/cache2" 2>&1)"
RC2=$?
if [ "$RC2" -eq 1 ] && printf '%s' "$OUT2" | grep -q 'other-skill/SKILL.md' && printf '%s' "$OUT2" | grep -q 'NON prouvée'; then
  ok "T2 : fixture cassée réelle -> comm -3 non vide, exit 1, diff imprimée (other-skill/SKILL.md)"
else
  ko "T2 : attendu exit 1 + diff visible, obtenu rc=$RC2, sortie : $(printf '%s' "$OUT2" | tail -5)"
fi
rm -rf "$LAB2"

# --- T3 : usage, --target manquant ---
bash "$GATE" --cache /tmp/does-not-matter >/dev/null 2>&1
RC3=$?
[ "$RC3" -eq 2 ] && ok "T3 : --target manquant -> exit 2" || ko "T3 : attendu exit 2, obtenu $RC3"

# --- T4 : cible sans registre installé ---
LAB4="$(mktemp -d)"
mkdir -p "$LAB4/target"
OUT4="$(bash "$GATE" --target "$LAB4/target" --cache "$LAB4" 2>&1)"
RC4=$?
if [ "$RC4" -eq 3 ] && printf '%s' "$OUT4" | grep -q 'précondition non remplie'; then
  ok "T4 : cible sans registre installé -> exit 3, aucune mesure"
else
  ko "T4 : attendu exit 3, obtenu rc=$RC4, sortie : $OUT4"
fi
rm -rf "$LAB4"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
