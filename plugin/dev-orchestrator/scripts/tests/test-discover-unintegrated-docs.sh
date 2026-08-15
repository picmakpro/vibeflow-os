#!/usr/bin/env bash
# test-discover-unintegrated-docs.sh — Suite de vérification de discover-unintegrated-docs.sh
#                                       (BRDG-02, plan 13-01 + fix-13-01 ; --hook, plan 17-02).
#
# Un cas par piège (22 assertions : 16 du contrat historique grain<TAB>chemin, 6 du mode --hook
# additif SIG-02). Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.
# Modèle de structure : plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh.
# Les cas 1 à 16 ne sont JAMAIS modifiés — leur passage inchangé EST la preuve de non-régression
# du contrat historique (D-06). Les cas 17+ continuent la numérotation, forme identique.
# Exception : le cas 7 a été durci (fixture rendue discriminante, forme et verdict inchangés —
# voir son commentaire) en réponse à un finding de revue portabilité, VFDO-17 comblement n2.

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
# Discriminant (D-15, VFDO-17 comblement n2) : la ligne de registre porte À LA FOIS le glob et le
# basename littéral du fichier. Filtre actif (script du dépôt) → la ligne entière est ignorée dès
# `index($0, "/*") > 0` avant même d'examiner le basename littéral qu'elle contient : le fichier
# reste non cité (spec\t..., rc=0). Filtre retiré (mutation) → la ligne est examinée normalement
# et son basename littéral matche : le fichier devient cité (silence, rc=3). Sans le basename
# littéral sur cette même ligne, le cas est vert par construction quel que soit le filtre —
# c'est le défaut que ce correctif élimine.
D="$(mk_root c7)"
echo '# spec' > "$D/docs/superpowers/specs/eta-design.md"
printf 'Critère de succès : docs/superpowers/specs/*.md — dont eta-design.md\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D")"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/eta-design.md')"
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

# === Cas 17 — --hook sur 3 documents non cités (2 spec, 1 plan) → ligne agrégée, exit 0 ==========
D="$(mk_root c17)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-17-un-design.md"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-17-deux-design.md"
echo '# plan' > "$D/docs/superpowers/plans/2026-01-17-un.md"
out="$(bash "$SCRIPT" --hook --path "$D")"; rc=$?
has_signal=0; case "$out" in *"[docs-ingest] 3 documents"*"2 spec"*"1 plan"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "17 --hook sur 3 documents non cités (2 spec, 1 plan) → ligne agrégée, exit 0"; else ko "17 --hook sur 3 documents non cités (2 spec, 1 plan) → ligne agrégée, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 18 — --hook sur un corpus entièrement cité → stdout vide, exit 0 (D-06 : silence interne
# 3 traduit en 0 SOUS --hook, seulement sous --hook — mêmes conditions que le cas 11 sans --hook) ==
D="$(mk_root c18)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-18-trois-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-18-trois-design.md\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --hook --path "$D")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "18 --hook sur corpus entièrement cité → stdout vide, exit 0 (D-06)"; else ko "18 --hook sur corpus entièrement cité → stdout vide, exit 0 (D-06)" "rc=$rc out=[$out]"; fi

# === Cas 19 — --hook avec .planning/ absent → stdout vide, exit 0 (D-06, mêmes conditions que 10) =
D="$TMP/c19"; mkdir -p "$D/docs/superpowers/specs"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-19-quatre-design.md"
out="$(bash "$SCRIPT" --hook --path "$D")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "19 --hook avec .planning/ absent → stdout vide, exit 0 (D-06)"; else ko "19 --hook avec .planning/ absent → stdout vide, exit 0 (D-06)" "rc=$rc out=[$out]"; fi

# === Cas 20 — --hook + --quiet → exit 64, stdout vide, message non vide sur stderr ================
errfile="$TMP/c20.err"
out="$(bash "$SCRIPT" --hook --quiet 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "20 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide"; else ko "20 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 21 — Non-régression : sur la MÊME fixture, sans --hook la sortie reste grain<TAB>chemin ==
D="$(mk_root c21)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-21-cinq-design.md"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-21-six-design.md"
echo '# plan' > "$D/docs/superpowers/plans/2026-01-21-cinq.md"
hook_out="$(bash "$SCRIPT" --hook --path "$D")"; hook_rc=$?
plain_out="$(bash "$SCRIPT" --path "$D")"; plain_rc=$?
plain_lines="$(printf '%s\n' "$plain_out" | grep -c '.' || true)"
plain_has_tab=0; case "$plain_out" in *"$(printf '\t')"*) plain_has_tab=1 ;; esac
plain_has_marker=0; case "$plain_out" in *"[docs-ingest]"*) plain_has_marker=1 ;; esac
hook_count="$(printf '%s' "$hook_out" | head -n 1 | awk '{print $2}')"
if [ "$plain_rc" -eq 0 ] && [ "$hook_rc" -eq 0 ] && [ "$plain_has_tab" -eq 1 ] && [ "$plain_has_marker" -eq 0 ] && [ "$plain_lines" = "$hook_count" ]; then
  ok "21 non-régression — sans --hook, grain<TAB>chemin trié, aucun marqueur, lignes == compte --hook"
else
  ko "21 non-régression — sans --hook, grain<TAB>chemin trié, aucun marqueur, lignes == compte --hook" "plain_rc=$plain_rc hook_rc=$hook_rc plain_lines=[$plain_lines] hook_count=[$hook_count] plain_out=[$plain_out] hook_out=[$hook_out]"
fi

# === Cas 22 — --hook n'émet jamais de ligne tabulée (aucune fuite du contrat historique) ==========
D="$(mk_root c22)"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-22-sept-design.md"
out="$(bash "$SCRIPT" --hook --path "$D")"
tabcount=0; case "$out" in *"$(printf '\t')"*) tabcount=1 ;; esac
if [ "$tabcount" -eq 0 ]; then ok "22 --hook n'émet jamais de ligne tabulée"; else ko "22 --hook n'émet jamais de ligne tabulée" "out=[$out]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
