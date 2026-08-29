#!/usr/bin/env bash
# test-runtime-registry.sh — Suite du registre de runtime (Phase 38, MIGR-01/MIGR-03).
#
# runtime-registry.sh :
#   T1 — fixture SANS clé `runtime` (cas absent, forme réelle de CE dépôt) : get-active -> claude.
#   T2 — même fixture : list-installed -> claude (seul).
#   T3 — fixture `"runtime":"codex"` (cas scalaire) : get-active -> codex.
#   T4 — même fixture : list-installed -> codex (seul, rétro-compat).
#   T5 — fixture `vf_runtimes:{installed:[claude,codex],active:codex}` + `runtime:"codex"`
#        (cas objet) : get-active -> codex.
#   T6 — même fixture : list-installed -> claude ET codex (les 2).
#   T7 — set-active --dry-run : sha256 du fichier identique avant/après (aucune écriture).
#   T8 — set-active sans --confirmed ni --dry-run : exit non-zéro, sha256 identique.
#   T9 — set-active --confirmed : `runtime` racine reste une chaîne JSON valide (contrat
#        gsd-core, T-38-16).
#   T10 — set-active --confirmed : vf_runtimes.installed contient l'ANCIEN ET le NOUVEAU
#         runtime (coexistence, pas remplacement).
#   T11 — verbe inconnu : exit non-zéro.
#   T12 — config.json introuvable : exit 2.
#
# Convention : asserts numérotés, helpers ok()/ko(), exit 0 si tout passe, exit 1 sinon.
# Calqué sur le pattern de test-check-artifact-fidelity.sh.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REG="$SCRIPTS_DIR/runtime-registry.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-runtime-registry (script: $REG) =="

if [ ! -f "$REG" ] || [ ! -x "$REG" ]; then
  ko "T0 : script introuvable ou non exécutable ($REG)"
  echo "== résultat : $pass OK / $fail KO =="
  exit 1
fi
ok "T0 : script présent et exécutable"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/absent.json" <<'EOF'
{
  "mode": "interactive"
}
EOF

cat > "$WORK/scalar.json" <<'EOF'
{
  "runtime": "codex"
}
EOF

cat > "$WORK/obj.json" <<'EOF'
{
  "runtime": "codex",
  "vf_runtimes": {
    "installed": ["claude", "codex"],
    "active": "codex"
  }
}
EOF

# --- T1/T2 : cas absent ---
OUT="$(bash "$REG" get-active --config "$WORK/absent.json")"
[ "$OUT" = "claude" ] && ok "T1 : cas absent -> get-active=claude" || ko "T1 : attendu claude, obtenu '$OUT'"

OUT="$(bash "$REG" list-installed --config "$WORK/absent.json")"
[ "$OUT" = "claude" ] && ok "T2 : cas absent -> list-installed=claude" || ko "T2 : attendu 'claude', obtenu '$OUT'"

# --- T3/T4 : cas scalaire ---
OUT="$(bash "$REG" get-active --config "$WORK/scalar.json")"
[ "$OUT" = "codex" ] && ok "T3 : cas scalaire -> get-active=codex" || ko "T3 : attendu codex, obtenu '$OUT'"

OUT="$(bash "$REG" list-installed --config "$WORK/scalar.json")"
[ "$OUT" = "codex" ] && ok "T4 : cas scalaire -> list-installed=codex (seul)" || ko "T4 : attendu 'codex', obtenu '$OUT'"

# --- T5/T6 : cas objet ---
OUT="$(bash "$REG" get-active --config "$WORK/obj.json")"
[ "$OUT" = "codex" ] && ok "T5 : cas objet -> get-active=codex" || ko "T5 : attendu codex, obtenu '$OUT'"

OUT="$(bash "$REG" list-installed --config "$WORK/obj.json")"
if printf '%s' "$OUT" | grep -qw claude && printf '%s' "$OUT" | grep -qw codex; then
  ok "T6 : cas objet -> list-installed contient claude ET codex"
else
  ko "T6 : attendu les 2 runtimes, obtenu '$OUT'"
fi

# --- T7 : --dry-run n'écrit rien ---
cp "$WORK/scalar.json" "$WORK/scalar-dryrun.json"
SHA_BEFORE="$(shasum "$WORK/scalar-dryrun.json" | awk '{print $1}')"
bash "$REG" set-active opencode --config "$WORK/scalar-dryrun.json" --dry-run >/dev/null
SHA_AFTER="$(shasum "$WORK/scalar-dryrun.json" | awk '{print $1}')"
[ "$SHA_BEFORE" = "$SHA_AFTER" ] && ok "T7 : --dry-run n'écrit rien (sha256 identique)" || ko "T7 : le fichier a été modifié par --dry-run"

# --- T8 : sans --confirmed ni --dry-run -> refus d'écrire ---
cp "$WORK/scalar.json" "$WORK/scalar-noconfirm.json"
SHA_BEFORE="$(shasum "$WORK/scalar-noconfirm.json" | awk '{print $1}')"
bash "$REG" set-active opencode --config "$WORK/scalar-noconfirm.json" >/dev/null 2>&1
RC=$?
SHA_AFTER="$(shasum "$WORK/scalar-noconfirm.json" | awk '{print $1}')"
if [ "$RC" -ne 0 ] && [ "$SHA_BEFORE" = "$SHA_AFTER" ]; then
  ok "T8 : sans --confirmed -> exit non-zéro, aucune écriture"
else
  ko "T8 : attendu refus (rc!=0, hash identique), obtenu rc=$RC"
fi

# --- T9/T10 : --confirmed écrit correctement ---
cp "$WORK/scalar.json" "$WORK/scalar-confirmed.json"
bash "$REG" set-active opencode --config "$WORK/scalar-confirmed.json" --confirmed >/dev/null
RUNTIME_TYPE="$(node -e "console.log(typeof JSON.parse(require('fs').readFileSync('$WORK/scalar-confirmed.json','utf8')).runtime)")"
[ "$RUNTIME_TYPE" = "string" ] && ok "T9 : --confirmed -> 'runtime' racine reste une chaîne (T-38-16)" || ko "T9 : 'runtime' n'est pas une chaîne (type=$RUNTIME_TYPE)"

INSTALLED_JSON="$(node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync('$WORK/scalar-confirmed.json','utf8')).vf_runtimes.installed))")"
if printf '%s' "$INSTALLED_JSON" | grep -q '"codex"' && printf '%s' "$INSTALLED_JSON" | grep -q '"opencode"'; then
  ok "T10 : --confirmed -> vf_runtimes.installed contient l'ancien ET le nouveau (coexistence)"
else
  ko "T10 : attendu codex+opencode dans installed, obtenu '$INSTALLED_JSON'"
fi

# --- T11 : verbe inconnu ---
bash "$REG" nope --config "$WORK/scalar.json" >/dev/null 2>&1
[ "$?" -ne 0 ] && ok "T11 : verbe inconnu -> exit non-zéro" || ko "T11 : verbe inconnu accepté à tort"

# --- T12 : config introuvable ---
bash "$REG" get-active --config "$WORK/does-not-exist.json" >/dev/null 2>&1
RC=$?
[ "$RC" -eq 2 ] && ok "T12 : config introuvable -> exit 2" || ko "T12 : attendu exit 2, obtenu $RC"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
