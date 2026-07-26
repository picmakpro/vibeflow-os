#!/usr/bin/env bash
# test-discover-unintegrated-docs.sh — Suite de vérification de discover-unintegrated-docs.sh
#                                       (BRDG-02, plan 13-01 + fix-13-01).
#
# Un cas par piège (16 assertions). Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.
# Modèle de structure : plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/discover-unintegrated-docs.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Prépare un socle minimal (specs/, plans/, .planning/, .planning/milestones/) sous $TMP/<name>.
mk_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d/docs/superpowers/specs" "$d/docs/superpowers/plans" "$d/.planning/milestones"
  printf '%s' "$d"
}

echo "== test-discover-unintegrated-docs =="

# === Cas 1 — Citation dans .planning/REQUIREMENTS.md seulement → intégré ======================
D="$(mk_root c1)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-01-alpha-design.md"
printf '> Spec : docs/superpowers/specs/2026-01-01-alpha-design.md\n' > "$D/.planning/REQUIREMENTS.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 cité REQUIREMENTS.md seul → intégré"; else ko "1 cité REQUIREMENTS.md seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 2 — Citation dans .planning/MILESTONES.md seulement → intégré ========================
D="$(mk_root c2)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-02-beta-design.md"
printf '**Spec :** docs/superpowers/specs/2026-01-02-beta-design.md\n' > "$D/.planning/MILESTONES.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "2 cité MILESTONES.md seul → intégré"; else ko "2 cité MILESTONES.md seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 3 — Citation dans .planning/PROJECT.md seulement → intégré ===========================
D="$(mk_root c3)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-03-gamma-design.md"
printf 'Charte liée : docs/superpowers/specs/2026-01-03-gamma-design.md\n' > "$D/.planning/PROJECT.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 cité PROJECT.md seul → intégré"; else ko "3 cité PROJECT.md seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 4 — Citation dans .planning/milestones/<x>.md seulement (jalon archivé) → intégré ====
D="$(mk_root c4)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-04-delta-design.md"
printf 'Archive : docs/superpowers/specs/2026-01-04-delta-design.md\n' > "$D/.planning/milestones/v1-ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "4 cité milestones/<x>.md seul → intégré"; else ko "4 cité milestones/<x>.md seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 5 — Citation dans docs/ADR.md seulement (livré hors chaîne GSD) → intégré ============
D="$(mk_root c5)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-05-epsilon-design.md"
printf -- '- Spec : docs/superpowers/specs/2026-01-05-epsilon-design.md\n' > "$D/docs/ADR.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "5 cité docs/ADR.md seul → intégré"; else ko "5 cité docs/ADR.md seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 6 — Collision de préfixe : seule <stem>-design.md est citée → <stem>.md non intégré ===
D="$(mk_root c6)"
echo '# plan' > "$D/docs/superpowers/plans/2026-01-06-zeta.md"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-06-zeta-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-06-zeta-design.md\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'plan\tdocs/superpowers/plans/2026-01-06-zeta.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "6 collision de préfixe — le plan reste non intégré"; else ko "6 collision de préfixe — le plan reste non intégré" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 7 — Auto-sabotage : un registre contient littéralement le glob → rien n'est cité =====
D="$(mk_root c7)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-07-eta-design.md"
printf 'Critère de succès : docs/superpowers/specs/*.md\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/2026-01-07-eta-design.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "7 auto-sabotage par glob — aucun fichier marqué cité"; else ko "7 auto-sabotage par glob — aucun fichier marqué cité" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 8 — Fichier sous specs/ → grain spec ==================================================
D="$(mk_root c8)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-08-theta-design.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/2026-01-08-theta-design.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "8 fichier sous specs/ → grain spec"; else ko "8 fichier sous specs/ → grain spec" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 9 — Fichier sous plans/ → grain plan ===================================================
D="$(mk_root c9)"
echo '# plan' > "$D/docs/superpowers/plans/2026-01-09-iota.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'plan\tdocs/superpowers/plans/2026-01-09-iota.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "9 fichier sous plans/ → grain plan"; else ko "9 fichier sous plans/ → grain plan" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 10 — .planning/ absent → exit 3 ========================================================
D="$TMP/c10"; mkdir -p "$D/docs/superpowers/specs"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-10-kappa-design.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "10 .planning/ absent → exit 3"; else ko "10 .planning/ absent → exit 3" "rc=$rc out=[$out]"; fi

# === Cas 11 — Corpus entièrement cité → exit 3 ==================================================
D="$(mk_root c11)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-11-lambda-design.md"
echo '# plan' > "$D/docs/superpowers/plans/2026-01-11-lambda.md"
{
  printf 'Spec : docs/superpowers/specs/2026-01-11-lambda-design.md\n'
  printf 'Plan : docs/superpowers/plans/2026-01-11-lambda.md\n'
} > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "11 corpus entièrement cité → exit 3"; else ko "11 corpus entièrement cité → exit 3" "rc=$rc out=[$out]"; fi

# === Cas 12 — Argument inconnu → exit 64 ========================================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "12 argument inconnu → exit 64"; else ko "12 argument inconnu → exit 64" "rc=$rc"; fi

# === Cas 13 — Suffixe strict : design.md non cité, un registre citant redesign.md → non intégré ===
D="$(mk_root c13)"
echo '# spec' > "$D/docs/superpowers/specs/design.md"
printf 'Voir docs/redesign.md pour contexte\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/design.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "13 suffixe strict — design.md non cité malgré redesign.md dans un registre"; else ko "13 suffixe strict — design.md non cité malgré redesign.md dans un registre" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 14 — Borne droite : alpha.md non cité, un registre contenant alpha.mdx → non intégré ====
D="$(mk_root c14)"
echo '# spec' > "$D/docs/superpowers/specs/alpha.md"
printf 'Voir docs/alpha.mdx pour contexte\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/alpha.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "14 borne droite — alpha.md non cité malgré alpha.mdx dans un registre"; else ko "14 borne droite — alpha.md non cité malgré alpha.mdx dans un registre" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 15 — Métacaractère ERE dans le basename → pas de match parasite (pattern non corrompu) ===
D="$(mk_root c15)"
echo '# spec' > "$D/docs/superpowers/specs/notes[draft.md"
printf 'Voir les notes.pdf du projet.\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/notes[draft.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "15 métacaractère dans le basename — pas de match parasite"; else ko "15 métacaractère dans le basename — pas de match parasite" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 16 — --quiet silencieux sur stdout ET stderr, exit conforme ===========================
D="$(mk_root c16)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-16-quiet-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-16-quiet-design.md\n' > "$D/.planning/ROADMAP.md"
errfile="$TMP/c16.err"
out="$(bash "$SCRIPT" --path "$D" --quiet 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ -z "$err" ]; then ok "16 --quiet silencieux sur stdout et stderr (exit 3)"; else ko "16 --quiet silencieux sur stdout et stderr (exit 3)" "rc=$rc out=[$out] err=[$err]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
