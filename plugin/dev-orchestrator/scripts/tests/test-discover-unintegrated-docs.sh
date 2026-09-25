#!/usr/bin/env bash
# test-discover-unintegrated-docs.sh — Suite de vérification de discover-unintegrated-docs.sh
#                                       (BRDG-02, plan 13-01 + fix-13-01 ; --hook, plan 17-02).
#
# Un cas par piège (26 assertions : 16 du contrat historique grain<TAB>chemin, 6 du mode --hook
# additif SIG-02, 4 du registre par compartiment — phase 41.1 / D-04, cas 23 à 26 dont MUT-1 et
# DEGRAD-2). Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.
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

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# Phase 41.1 / D-04 — registre de citation élargi à CHAQUE compartiment de workstream.
# Avant ce plan, les registres n'étaient lus qu'à la RACINE de .planning/ — absents sous le layout
# partitionné, donc le hook signalait « non intégré » des documents pourtant cités (4 faux positifs
# sur 5 mesurés le 2026-09-23).
# ═══════════════════════════════════════════════════════════════════════════════════════════════

# === Cas 23 — Document cité UNIQUEMENT dans le ROADMAP d'un compartiment → intégré ==============
# C'EST le cas discriminant du plan : MESURÉ ROUGE sur le script d'avant (rc=0, la spec ressortait
# « non intégré »), vert après. Le cas 24 ci-dessous, lui, est vert des deux côtés — il ne garde
# que la non-régression, pas la propriété neuve.
D="$(mk_root c23)"
mkdir -p "$D/.planning/workstreams/dev"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-23-ws-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-23-ws-design.md\n' > "$D/.planning/workstreams/dev/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "23 cité dans le ROADMAP d'un compartiment seul → intégré"; else ko "23 cité dans le ROADMAP d'un compartiment seul → intégré" "rc=$rc out=[$out]"; fi

# === Cas 24 — Document cité NULLE PART, compartiment présent → reste signalé ====================
# VERT PAR CONSTRUCTION DES DEUX CÔTÉS (avant comme après le plan 41.1-04) : il ne garde AUCUNE
# propriété neuve, seulement la non-régression du comportement historique — la propriété neuve est
# gardée par le cas 23 et son mutant MUT-1.
D="$(mk_root c24)"
mkdir -p "$D/.planning/workstreams/dev"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-24-orpheline.md"
printf 'Rien a voir.\n' > "$D/.planning/workstreams/dev/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
expected="$(printf 'spec\tdocs/superpowers/specs/2026-01-24-orpheline.md')"
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then ok "24 non cité nulle part malgré un compartiment → reste signalé (non-régression, vert des deux côtés)"; else ko "24 non cité nulle part malgré un compartiment → reste signalé" "rc=$rc out=[$out] attendu=[$expected]"; fi

# === Cas 25 (MUT-1) — mutant : la boucle sur les compartiments neutralisée doit RÉTABLIR le faux
# positif. Le script est copié dans un répertoire PLAT avec workstream-policy.sh à côté (premier
# candidat de la recherche de sourcing, le layout d'install réel) — donc le TÉMOIN non muté et le
# MUTANT ne diffèrent QUE par la mutation, jamais par la résolution du sourcing. ================
MUTDIR="$TMP/mut25"; mkdir -p "$MUTDIR"
cp "$SCRIPT" "$MUTDIR/discover-unintegrated-docs.sh"
POLICY_SRC="$(cd "$(dirname "$SCRIPT")/../../planning-core/scripts" && pwd)/workstream-policy.sh"
cp "$POLICY_SRC" "$MUTDIR/workstream-policy.sh"
D="$(mk_root c25)"
mkdir -p "$D/.planning/workstreams/dev"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-25-mutant-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-25-mutant-design.md\n' > "$D/.planning/workstreams/dev/ROADMAP.md"
# Témoin : la copie NON mutée doit se comporter comme l'original (intégré, rc=3).
temoin_out="$(bash "$MUTDIR/discover-unintegrated-docs.sh" --path "$D" 2>/dev/null)"; temoin_rc=$?
# Mutation : la boucle de lecture des compartiments ne s'exécute plus jamais.
sed 's|^        while IFS= read -r _wsdir; do|        false \&\& while IFS= read -r _wsdir; do|' \
  "$MUTDIR/discover-unintegrated-docs.sh" > "$MUTDIR/muté.sh"
mut_applied=0
if ! cmp -s "$MUTDIR/discover-unintegrated-docs.sh" "$MUTDIR/muté.sh"; then mut_applied=1; fi
mut_out="$(bash "$MUTDIR/muté.sh" --path "$D" 2>/dev/null)"; mut_rc=$?
mut_expected="$(printf 'spec\tdocs/superpowers/specs/2026-01-25-mutant-design.md')"
if [ "$mut_applied" -eq 1 ] && [ "$temoin_rc" -eq 3 ] && [ -z "$temoin_out" ] \
   && [ "$mut_rc" -eq 0 ] && [ "$mut_out" = "$mut_expected" ]; then
  ok "25 MUT-1 TUE — boucle sur les compartiments neutralisée → le faux positif D-04 réapparaît (témoin non muté vert)"
else
  ko "25 MUT-1 TUE — boucle sur les compartiments neutralisée → le faux positif D-04 réapparaît" "mut_applied=$mut_applied temoin_rc=$temoin_rc temoin_out=[$temoin_out] mut_rc=$mut_rc mut_out=[$mut_out]"
fi

# === Cas 26 (DEGRAD-2) — rc=2 de vf_ws_enumerate ANNONCÉ sur stderr, muet sur la fixture nominale ==
# Correction C-06 : aucune dégradation silencieuse. `.planning/workstreams` détourné en LIEN
# SYMBOLIQUE → vf_ws_enumerate rend 2, stdout vide — indistinguable d'un dépôt non partitionné si
# le rc est jeté. Ce cas est la SEULE garde machine du fait que ce rc reste audible : sans lui, un
# futur `2>/dev/null` rétabli passerait vert.
# Contre-épreuve dans la MÊME exécution : fixture au contenu IDENTIQUE, `workstreams` en répertoire
# RÉEL — aucune de ces lignes ne doit paraître (sinon l'assertion est existentielle et ne
# discrimine rien). Le code de sortie reste NORMAL des deux côtés (contrat 0/3/64 inchangé).
D="$(mk_root c26lien)"
mkdir -p "$D/ws-reel/dev"
echo '# spec' > "$D/docs/superpowers/specs/2026-01-26-degrad-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-26-degrad-design.md\n' > "$D/ws-reel/dev/ROADMAP.md"
ln -s "$D/ws-reel" "$D/.planning/workstreams"
lien_err="$TMP/c26lien.err"
lien_out="$(bash "$SCRIPT" --path "$D" 2>"$lien_err")"; lien_rc=$?
lien_stderr="$(cat "$lien_err")"
lien_annonce=0
case "$lien_stderr" in *"NON VÉRIFIABLE"*) case "$lien_stderr" in *"repli racine"*) lien_annonce=1 ;; esac ;; esac
lien_signale=0; case "$lien_out" in *"2026-01-26-degrad-design.md"*) lien_signale=1 ;; esac

D2="$(mk_root c26reel)"
mkdir -p "$D2/.planning/workstreams/dev"
echo '# spec' > "$D2/docs/superpowers/specs/2026-01-26-degrad-design.md"
printf 'Spec : docs/superpowers/specs/2026-01-26-degrad-design.md\n' > "$D2/.planning/workstreams/dev/ROADMAP.md"
reel_err="$TMP/c26reel.err"
reel_out="$(bash "$SCRIPT" --path "$D2" 2>"$reel_err")"; reel_rc=$?
reel_stderr="$(cat "$reel_err")"
reel_annonce=0
case "$reel_stderr" in *"NON VÉRIFIABLE"*) reel_annonce=1 ;; esac
case "$reel_stderr" in *"repli racine"*) reel_annonce=1 ;; esac

if [ "$lien_annonce" -eq 1 ] && [ "$lien_rc" -eq 0 ] && [ "$lien_signale" -eq 1 ] \
   && [ "$reel_annonce" -eq 0 ] && [ "$reel_rc" -eq 3 ] && [ -z "$reel_out" ]; then
  ok "26 DEGRAD-2 : annonce de dégradation présente sur stderr (lien symbolique), absente sur la fixture nominale — code de sortie normal des deux côtés"
else
  ko "26 DEGRAD-2 : annonce de dégradation présente sur stderr" "lien_annonce=$lien_annonce lien_rc=$lien_rc lien_signale=$lien_signale lien_out=[$lien_out] lien_stderr=[$lien_stderr] reel_annonce=$reel_annonce reel_rc=$reel_rc reel_out=[$reel_out] reel_stderr=[$reel_stderr]"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
