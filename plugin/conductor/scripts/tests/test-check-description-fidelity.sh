#!/usr/bin/env bash
# test-check-description-fidelity.sh — Suite du gate de fidélité de la description: de
# frontmatter (Phase 38, prolongement FIDE-01/FIDE-02, plan 38-08).
#
# check-description-fidelity.sh :
#   T0  — gate présent et exécutable.
#   T1  — --inventory sur l'arbre RÉEL du dépôt découvre strictement plus qu'un seuil bas
#         explicite (non-vacuité : le gate REGARDE bien quelque chose).
#   T2  — le gate tourne en mode audit sur l'arbre RÉEL du dépôt et rend le verdict ATTENDU
#         (exit 0 — la propriété « aucun fichier non exempté ne viole les deux règles »,
#         jamais un compte figé, pour survivre à l'ajout d'un module). Tant que la Tâche 5 n'a
#         pas converti l'arbre, ce cas est un KO DOCUMENTÉ (le rouge de non-régression attendu,
#         capturé dans la trace pour le SUMMARY) — il passe au vert de lui-même après la
#         conversion, sans modification de ce test.
#   T3  — trois issues prouvées séparément sur fixtures isolées (mktemp -d, jamais l'arbre du
#         dépôt) : fixture conforme -> 0 ; fixture fautive -> 1 avec le chemin fautif dans le
#         rapport ; python3 absent -> 3 (nomme python3) ; node absent -> 3 (nomme node).
#   T4  — égalité, pas seulement validité : un frontmatter valide en YAML strict (scalaire
#         replié) mais dont la reproduction gsd-core diverge doit rougir — preuve que le gate
#         teste bien les DEUX chemins.
#   T5  — cliquet des exceptions (a) : une exception pointant un fichier ABSENT rend 1.
#   T6  — cliquet des exceptions (b) : une exception pointant un fichier qui satisferait
#         désormais les deux règles (périmée) rend 1.
#   T7  — les exceptions sont imprimées à chaque exécution (présence des lignes, jamais un
#         silence toléré).
#   T8  — --inventory n'écrit rien : empreinte de l'arbre de fixture avant/après invocation,
#         comparaison par comm sur listes triées de chemins ET par empreinte de contenu.
#   T9  — garde-fou : aucun répertoire temporaire du gate ne fuit hors de mktemp -d.
#   T10 — garde-fou : l'arbre du dépôt est resté byte-identique pendant toute la suite
#         (git diff --stat sur plugin/, fichiers suivis, vide après exécution).
#
# Tâche 4 — les DEUX mutants discriminants OBLIGATOIRES, sur une COPIE d'un fichier RÉEL du
# dépôt (jamais le fichier posé), ajoutés séparément de T0-T10 pour que leur preuve reste isolée
# et lisible d'un bloc dans le SUMMARY :
#   T11 — contrôle vert du mutant A (AVANT mutation, sur la copie pristine) -> exit 0.
#   T12 — Mutant A (scalaire replié) : le gate DOIT rendre 1, rapport nommant le fichier, le
#         texte attendu (A) et le littéral de repli seul obtenu (B) — le piège en ciseaux du
#         mandat (38-UPSTREAM-GSD-CORE-ISSUE.md §5).
#   T13 — contrôle vert du mutant B (AVANT mutation, sur une copie pristine séparée) -> exit 0.
#   T14 — Mutant B (plain, deux-points suivi d'espace) : le gate DOIT rendre 1, rapport portant
#         le message d'erreur du parseur strict (« mapping values are not allowed here »).
#   T15 — le fichier SOURCE réel du dépôt (utilisé comme source de copie des deux mutants) est
#         resté byte-identique avant/après (empreinte sha256 comparée) — la mutation ne touche
#         jamais l'arbre du dépôt, seulement les copies sous mktemp -d.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe, exit 1 dès un
# KO. Calqué sur le pattern de test-check-artifact-fidelity.sh.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$SCRIPTS_DIR/check-description-fidelity.sh"
REPO="$(cd "$SCRIPTS_DIR/../../.." && pwd)"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-check-description-fidelity (gate: $GATE) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ ! -f "$GATE" ]; then
  ko "T0 : gate introuvable à $GATE"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi
if [ ! -x "$GATE" ]; then
  ko "T0 : gate non exécutable ($GATE)"
else
  ok "T0 : gate présent et exécutable"
fi

# --- Helper : construit une fixture minimale sous $1 (répertoire), avec le frontmatter donné
# en $2 (déjà les lignes description: incluses) — jamais l'arbre du dépôt. ---
make_fixture_file() {
  # $1 = chemin du fichier, $2 = corps du frontmatter (une ou plusieurs lignes)
  mkdir -p "$(dirname "$1")"
  {
    echo "---"
    echo "name: fixture"
    printf '%s\n' "$2"
    echo "---"
    echo "Corps."
  } > "$1"
}

# --- Liste d'exceptions VIDE — la liste par défaut du gate (3 chemins réels du dépôt) ne
# résout à RIEN sous une racine de fixture isolée ; sans cet override, chaque appel sur fixture
# rendrait faussement « exception orpheline » (fichier absent). Tous les cas sur fixture qui ne
# testent pas spécifiquement le cliquet des exceptions (T5/T6/T7 posent leur propre override)
# utilisent cette liste vide. ---
EMPTY_EXC="$WORK/empty-exceptions.tsv"
: > "$EMPTY_EXC"

# =====================================================================================
# T1 — non-vacuité sur l'arbre réel.
# =====================================================================================
T1_OUT="$(bash "$GATE" --inventory 2>&1)"
T1_COUNT="$(printf '%s\n' "$T1_OUT" | grep -oE 'inventaire — [0-9]+ découvert' | grep -oE '[0-9]+' | head -1)"
T1_COUNT="${T1_COUNT:-0}"
if [ "$T1_COUNT" -gt 10 ]; then
  ok "T1 : non-vacuité — $T1_COUNT fichiers découverts sur l'arbre réel (> 10)"
else
  ko "T1 : découverte effondrée sur l'arbre réel ($T1_COUNT fichiers, attendu > 10)"
fi

# =====================================================================================
# T2 — gate en mode audit sur l'arbre réel : assertion sur la PROPRIÉTÉ (exit 0 attendu),
# jamais sur un compte figé. Documenté KO tant que la Tâche 5 n'a pas converti.
# =====================================================================================
bash "$GATE" > "$WORK/t2.out" 2>&1
T2_RC=$?
if [ "$T2_RC" -eq 0 ]; then
  ok "T2 : arbre réel conforme (exit 0) — aucun fichier non exempté ne viole les deux règles"
else
  ko "T2 : arbre réel NON conforme (exit $T2_RC) — ROUGE DE NON-RÉGRESSION ATTENDU avant Tâche 5 (conversion). Ce KO est documenté, pas un défaut de la suite ; il passera au vert de lui-même une fois la Tâche 5 exécutée, sans modification de ce test."
fi

# =====================================================================================
# T3 — trois issues, sur fixtures isolées.
# =====================================================================================
# T3a — fixture conforme -> 0
F_OK="$WORK/t3a/ok.md"
make_fixture_file "$F_OK" 'description: "Texte propre: avec un deux-points, sans souci."'
CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/t3a" > "$WORK/t3a.out" 2>&1
T3A_RC=$?
if [ "$T3A_RC" -eq 0 ]; then
  ok "T3a : fixture conforme -> exit 0"
else
  ko "T3a : fixture conforme aurait dû rendre 0, a rendu $T3A_RC ($(cat "$WORK/t3a.out"))"
fi

# T3b — fixture fautive (plain avec deux-points-espace, invalide en YAML strict) -> 1, chemin nommé
F_BAD="$WORK/t3b/bad.md"
make_fixture_file "$F_BAD" 'description: Texte casse: avec un deux-points, invalide en YAML strict.'
CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/t3b" > "$WORK/t3b.out" 2>&1
T3B_RC=$?
if [ "$T3B_RC" -eq 1 ] && grep -qF "$F_BAD" "$WORK/t3b.out"; then
  ok "T3b : fixture fautive -> exit 1, chemin fautif nommé dans le rapport"
else
  ko "T3b : attendu exit 1 + chemin nommé, obtenu exit $T3B_RC ($(cat "$WORK/t3b.out"))"
fi

# T3c — python3 absent -> 3, nomme python3
FAKEBIN_NOPY="$WORK/fakebin_nopy"
mkdir -p "$FAKEBIN_NOPY"
for t in awk sort comm find cut wc grep sed mktemp cat dirname basename tr rm mkdir env bash printf; do
  p="$(command -v "$t" 2>/dev/null)"
  [ -n "$p" ] && ln -sf "$p" "$FAKEBIN_NOPY/$t"
done
NODE_BIN="$(command -v node 2>/dev/null)"
[ -n "$NODE_BIN" ] && ln -sf "$NODE_BIN" "$FAKEBIN_NOPY/node"
F_INDET="$WORK/t3c/ok.md"
make_fixture_file "$F_INDET" 'description: "Texte propre."'
T3C_OUT="$(PATH="$FAKEBIN_NOPY" CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/t3c" 2>&1)"
T3C_RC=$?
if [ "$T3C_RC" -eq 3 ] && printf '%s' "$T3C_OUT" | grep -qi 'python3'; then
  ok "T3c : python3 absent -> exit 3, python3 nommé"
else
  ko "T3c : attendu exit 3 + 'python3' nommé, obtenu exit $T3C_RC ($T3C_OUT)"
fi

# T3d — node absent -> 3, nomme node
FAKEBIN_NONODE="$WORK/fakebin_nonode"
mkdir -p "$FAKEBIN_NONODE"
for t in awk sort comm find cut wc grep sed mktemp cat dirname basename tr rm mkdir env bash printf python3; do
  p="$(command -v "$t" 2>/dev/null)"
  [ -n "$p" ] && ln -sf "$p" "$FAKEBIN_NONODE/$t"
done
T3D_OUT="$(PATH="$FAKEBIN_NONODE" CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/t3c" 2>&1)"
T3D_RC=$?
if [ "$T3D_RC" -eq 3 ] && printf '%s' "$T3D_OUT" | grep -qi 'node'; then
  ok "T3d : node absent -> exit 3, node nommé"
else
  ko "T3d : attendu exit 3 + 'node' nommé, obtenu exit $T3D_RC ($T3D_OUT)"
fi

# =====================================================================================
# T4 — égalité, pas seulement validité : scalaire replié valide en YAML mais divergent côté
# reproduction gsd-core.
# =====================================================================================
F_FOLD="$WORK/t4/fold.md"
mkdir -p "$WORK/t4"
{
  echo "---"
  echo "name: fixture"
  echo "description: >"
  echo "  Texte replie valide en YAML strict mais que la regex gsd-core ne capture pas."
  echo "---"
  echo "Corps."
} > "$F_FOLD"
CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/t4" > "$WORK/t4.out" 2>&1
T4_RC=$?
if [ "$T4_RC" -eq 1 ] && grep -qF "$F_FOLD" "$WORK/t4.out"; then
  ok "T4 : scalaire replié valide en YAML mais divergent côté gsd-core -> exit 1 (le gate teste bien les deux chemins)"
else
  ko "T4 : attendu exit 1 + fichier nommé, obtenu exit $T4_RC ($(cat "$WORK/t4.out"))"
fi

# =====================================================================================
# T5 — cliquet (a) : exception pointant un fichier absent -> 1.
# =====================================================================================
mkdir -p "$WORK/t5"
make_fixture_file "$WORK/t5/ok.md" 'description: "Texte propre."'
printf 'inexistant.md\traison bidon\n' > "$WORK/t5-exceptions.tsv"
CDF_EXCEPTIONS_FILE="$WORK/t5-exceptions.tsv" bash "$GATE" --root "$WORK/t5" > "$WORK/t5.out" 2>&1
T5_RC=$?
if [ "$T5_RC" -eq 1 ] && grep -qi 'orpheline' "$WORK/t5.out"; then
  ok "T5 : exception orpheline (fichier absent) -> exit 1, signalée 'orpheline'"
else
  ko "T5 : attendu exit 1 + 'orpheline', obtenu exit $T5_RC ($(cat "$WORK/t5.out"))"
fi

# =====================================================================================
# T6 — cliquet (b) : exception pointant un fichier qui satisferait désormais les deux règles
# (périmée) -> 1.
# =====================================================================================
mkdir -p "$WORK/t6"
make_fixture_file "$WORK/t6/conforme.md" 'description: "Texte propre, deja conforme."'
printf 'conforme.md\traison perimee\n' > "$WORK/t6-exceptions.tsv"
CDF_EXCEPTIONS_FILE="$WORK/t6-exceptions.tsv" bash "$GATE" --root "$WORK/t6" > "$WORK/t6.out" 2>&1
T6_RC=$?
if [ "$T6_RC" -eq 1 ] && grep -qi 'périmée' "$WORK/t6.out"; then
  ok "T6 : exception périmée (satisferait désormais les deux règles) -> exit 1, signalée 'périmée'"
else
  ko "T6 : attendu exit 1 + 'périmée', obtenu exit $T6_RC ($(cat "$WORK/t6.out"))"
fi

# =====================================================================================
# T7 — les exceptions sont imprimées à chaque exécution (régime nominal, PASS global).
#
# Fixture : YAML VALIDE (passe A réussit) mais DIVERGENTE de la reproduction gsd-core (scalaire
# replié, même motif que T4) — une exception légitime au sens du gate ("le quotage/la forme
# actuelle empêche l'égalité, mais le frontmatter reste un YAML strict valide"). Volontairement
# PAS une fixture au frontmatter invalide (ex. ': ' non quoté) : depuis la correction ciblée
# post-mesure-kimi (38-MESURE-KIMI.md), une exception dispense du quotage, JAMAIS de la validité
# YAML stricte — ce cas-là rougit désormais (couvert séparément par T16-T19), il ne peut plus
# servir de fixture « excusée » ici sans contredire le contrat que ce lot vient de durcir.
# =====================================================================================
mkdir -p "$WORK/t7"
{
  echo "---"
  echo "name: fixture"
  echo "description: >"
  echo "  Texte replie valide en YAML strict mais que la regex gsd-core ne capture pas."
  echo "---"
  echo "Corps."
} > "$WORK/t7/exempt.md"
printf 'exempt.md\traison de test (divergence A/B legitime, YAML valide, excusee par cette exception)\n' > "$WORK/t7-exceptions.tsv"
CDF_EXCEPTIONS_FILE="$WORK/t7-exceptions.tsv" bash "$GATE" --root "$WORK/t7" > "$WORK/t7.out" 2>&1
T7_RC=$?
if [ "$T7_RC" -eq 0 ] && grep -qi 'exception :' "$WORK/t7.out"; then
  ok "T7 : violation (YAML valide, divergente) excusée par exception -> exit 0, ligne d'exception imprimée quand même"
else
  ko "T7 : attendu exit 0 + ligne d'exception imprimée, obtenu exit $T7_RC ($(cat "$WORK/t7.out"))"
fi

# =====================================================================================
# T8 — --inventory n'écrit rien : empreinte avant/après par comm sur chemin+contenu.
# =====================================================================================
mkdir -p "$WORK/t8"
make_fixture_file "$WORK/t8/a.md" 'description: "Un texte."'
make_fixture_file "$WORK/t8/b.md" 'description: Texte plain simple sans deux points.'
snapshot_tree() {
  # $1 = racine. TSV trié chemin<TAB>sha256, portable (node, pas shasum/sha256sum qui divergent
  # macOS/Linux).
  find "$1" -type f | LC_ALL=C sort | while IFS= read -r f; do
    h="$(node -e "const c=require('crypto');const fs=require('fs');process.stdout.write(c.createHash('sha256').update(fs.readFileSync(process.argv[1])).digest('hex'))" "$f")"
    printf '%s\t%s\n' "$f" "$h"
  done
}
snapshot_tree "$WORK/t8" > "$WORK/t8-before.tsv"
bash "$GATE" --inventory --root "$WORK/t8" > /dev/null 2>&1
snapshot_tree "$WORK/t8" > "$WORK/t8-after.tsv"
T8_DIFF="$(comm -3 "$WORK/t8-before.tsv" "$WORK/t8-after.tsv")"
if [ -z "$T8_DIFF" ]; then
  ok "T8 : --inventory n'a rien écrit (empreinte chemin+contenu identique avant/après)"
else
  ko "T8 : --inventory a modifié l'arbre de fixture : $T8_DIFF"
fi

# =====================================================================================
# T9 — garde-fou : aucun répertoire temporaire du gate ne fuit hors de mktemp -d.
# =====================================================================================
TMP_PARENT="$(dirname "$(mktemp -u)")"
T9_BEFORE="$(find "$TMP_PARENT" -maxdepth 1 -type d 2>/dev/null | LC_ALL=C sort)"
bash "$GATE" --root "$WORK/t8" > /dev/null 2>&1
bash "$GATE" --inventory --root "$WORK/t8" > /dev/null 2>&1
T9_AFTER="$(find "$TMP_PARENT" -maxdepth 1 -type d 2>/dev/null | LC_ALL=C sort)"
T9_LEAK="$(comm -13 <(printf '%s\n' "$T9_BEFORE") <(printf '%s\n' "$T9_AFTER"))"
if [ -z "$T9_LEAK" ]; then
  ok "T9 : aucun répertoire temporaire du gate n'a fui hors de mktemp -d"
else
  ko "T9 : répertoire(s) temporaire(s) résiduel(s) détecté(s) : $T9_LEAK"
fi

# =====================================================================================
# T10 — garde-fou : l'arbre du dépôt est resté byte-identique pendant les cas sur fixtures.
# `git diff` (fichiers SUIVIS uniquement) — jamais `git status`, qui listerait aussi ce fichier
# de suite lui-même (encore non suivi au moment où il s'exécute la première fois) comme un faux
# positif ; la garde porte sur une MODIFICATION d'un fichier existant, pas sur un ajout légitime.
# =====================================================================================
T10_SELF="plugin/conductor/scripts/tests/test-check-description-fidelity.sh"
T10_STATUS="$(cd "$REPO" && git diff --stat -- plugin ":(exclude)$T10_SELF" 2>/dev/null)"
if [ -z "$T10_STATUS" ]; then
  ok "T10 : arbre du dépôt (plugin/, fichiers suivis) resté byte-identique pendant la suite"
else
  ko "T10 : l'arbre du dépôt a été modifié pendant la suite : $T10_STATUS"
fi

# =====================================================================================
# Tâche 4 — les DEUX mutants discriminants OBLIGATOIRES (T11-T15). Copie d'un fichier RÉEL du
# dépôt actuellement CONFORME (plugin/validator/AGENT.md — audit=0 mesuré au cadrage de cette
# tâche), jamais le fichier posé. Chaque assertion imprime CE QUI EST ASSERTÉ, CE QUI EST
# ATTENDU, CE QUI EST OBTENU (code de sortie + extrait de rapport).
# =====================================================================================
sha256_file() {
  node -e "const c=require('crypto');const fs=require('fs');process.stdout.write(c.createHash('sha256').update(fs.readFileSync(process.argv[1])).digest('hex'))" "$1"
}
mutate_description() {
  # $1 = fichier, $2 = mode (fold|plain), $3 = nouveau texte.
  node -e '
const fs = require("fs");
const [, filePath, mode, newText] = process.argv;
const content = fs.readFileSync(filePath, "utf8");
const lines = content.split("\n");
const idx = lines.findIndex((l) => /^description:/.test(l));
if (idx === -1) { console.error("description: line not found"); process.exit(1); }
const replacement = mode === "fold" ? [`description: >`, `  ${newText}`] : [`description: ${newText}`];
lines.splice(idx, 1, ...replacement);
fs.writeFileSync(filePath, lines.join("\n"));
' "$1" "$2" "$3"
}

SRC_REAL="$REPO/plugin/validator/AGENT.md"
SRC_SHA_BEFORE="$(sha256_file "$SRC_REAL")"

MUT_A_TEXT="Texte de test avec: un deux-points, pour le mutant scalaire replie."
MUT_B_TEXT="Texte de test: contient un deux-points suivi d'espace, invalide en YAML strict."

# --- Mutant A (scalaire replié) : T11 contrôle vert AVANT mutation, T12 mutation rouge. ---
mkdir -p "$WORK/mutA"
cp "$SRC_REAL" "$WORK/mutA/target.md"
T11_OUT="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/mutA" 2>&1)"
T11_RC=$?
echo "  [T11] asserté : contrôle vert AVANT mutation (copie pristine) — attendu : exit 0 — obtenu : exit $T11_RC"
if [ "$T11_RC" -eq 0 ]; then
  ok "T11 : contrôle vert du mutant A (avant mutation) -> exit 0"
else
  ko "T11 : contrôle vert du mutant A aurait dû rendre 0, a rendu $T11_RC ($T11_OUT)"
fi

mutate_description "$WORK/mutA/target.md" fold "$MUT_A_TEXT"
T12_OUT="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/mutA" 2>&1)"
T12_RC=$?
echo "  [T12] asserté : mutant A (scalaire replié) — attendu : exit 1, rapport nommant \"$MUT_A_TEXT\" (A) et \">\" seul (B) — obtenu : exit $T12_RC : $T12_OUT"
if [ "$T12_RC" -eq 1 ] && printf '%s' "$T12_OUT" | grep -qF "$MUT_A_TEXT" && printf '%s' "$T12_OUT" | grep -qF 'obtenu(B)=">"'; then
  ok "T12 : mutant A (scalaire replié) rougit — piège en ciseaux capturé (attendu=texte complet, obtenu=littéral > seul)"
else
  ko "T12 : mutant A attendu exit 1 + attendu/obtenu nommés, obtenu exit $T12_RC ($T12_OUT)"
fi

# --- Mutant B (plain, deux-points-espace) : T13 contrôle vert AVANT mutation, T14 mutation rouge. ---
mkdir -p "$WORK/mutB"
cp "$SRC_REAL" "$WORK/mutB/target.md"
T13_OUT="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/mutB" 2>&1)"
T13_RC=$?
echo "  [T13] asserté : contrôle vert AVANT mutation (copie pristine) — attendu : exit 0 — obtenu : exit $T13_RC"
if [ "$T13_RC" -eq 0 ]; then
  ok "T13 : contrôle vert du mutant B (avant mutation) -> exit 0"
else
  ko "T13 : contrôle vert du mutant B aurait dû rendre 0, a rendu $T13_RC ($T13_OUT)"
fi

mutate_description "$WORK/mutB/target.md" plain "$MUT_B_TEXT"
T14_OUT="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$WORK/mutB" 2>&1)"
T14_RC=$?
echo "  [T14] asserté : mutant B (plain, deux-points-espace) — attendu : exit 1, rapport portant le message du parseur strict — obtenu : exit $T14_RC : $T14_OUT"
if [ "$T14_RC" -eq 1 ] && printf '%s' "$T14_OUT" | grep -qi 'mapping values are not allowed here'; then
  ok "T14 : mutant B (plain, deux-points-espace) rougit — message du parseur strict présent (mapping values are not allowed here)"
else
  ko "T14 : mutant B attendu exit 1 + message parseur strict, obtenu exit $T14_RC ($T14_OUT)"
fi

# --- T15 : le fichier SOURCE réel du dépôt reste byte-identique. ---
SRC_SHA_AFTER="$(sha256_file "$SRC_REAL")"
if [ "$SRC_SHA_BEFORE" = "$SRC_SHA_AFTER" ]; then
  ok "T15 : fichier source réel ($SRC_REAL) byte-identique avant/après (sha256 $SRC_SHA_BEFORE)"
else
  ko "T15 : fichier source réel MODIFIÉ par la mutation — avant=$SRC_SHA_BEFORE après=$SRC_SHA_AFTER"
fi

# =====================================================================================
# T16-T19 — cliquet (c), correction ciblée post-mesure-kimi (38-MESURE-KIMI.md I-1) : une
# exception dispense du QUOTAGE, jamais de la validité YAML STRICTE. Défaut mesuré : avant cette
# correction, un fichier déclaré en exception dont le frontmatter ne parsait MÊME PAS (passe A en
# échec) passait le cliquet en silence — c'est exactement ce qui a laissé design-orchestrator/
# AGENT.md invalide et injoignable sur kimi (11/31 agents, cf. rapport) pendant que le gate
# affichait PASS. Fixture : COPIE de plugin/consolidator/SKILL.md (une des deux exceptions
# légitimes restantes — YAML valide aujourd'hui, jamais l'arbre du dépôt).
# =====================================================================================
SRC_EXC_REAL="$REPO/plugin/consolidator/SKILL.md"
SRC_EXC_SHA_BEFORE="$(sha256_file "$SRC_EXC_REAL")"

# --- T16 : contrôle vert AVANT mutation — copie pristine déclarée exception -> exit 0. ---
mkdir -p "$WORK/t16/consolidator"
cp "$SRC_EXC_REAL" "$WORK/t16/consolidator/SKILL.md"
printf 'consolidator/SKILL.md\traison de test (exception legitime, copie pristine)\n' > "$WORK/t16-exceptions.tsv"
T16_OUT="$(CDF_EXCEPTIONS_FILE="$WORK/t16-exceptions.tsv" bash "$GATE" --root "$WORK/t16" 2>&1)"
T16_RC=$?
echo "  [T16] asserté : contrôle vert AVANT mutation (exception légitime, copie pristine) — attendu : exit 0 — obtenu : exit $T16_RC"
if [ "$T16_RC" -eq 0 ]; then
  ok "T16 : contrôle vert de l'exception (avant mutation) -> exit 0"
else
  ko "T16 : contrôle vert de l'exception aurait dû rendre 0, a rendu $T16_RC ($T16_OUT)"
fi

# --- T17 : mutant — injection d'un ' : ' non quoté dans la description du fichier EXEMPTÉ.
# Le fichier reste déclaré exception (MÊME TSV), seul son contenu change -> le cliquet doit
# rougir sur LA VALIDITÉ, pas sur la présence/péremption de l'exception (déjà couvertes par T5/T6).
# Injection en TÊTE de la valeur (juste après "description:"), jamais en queue : la description
# source contient un "#" précédé d'espace plus loin dans le texte (comment YAML implicite en
# scalaire plain — piège distinct, hors périmètre de cette correction), qui aurait sinon absorbé
# tout texte ajouté après lui et rendu le mutant inerte (constaté en sonde : append silencieux,
# aucune erreur levée).
# ---
node -e '
const fs = require("fs");
const [, filePath] = process.argv;
const content = fs.readFileSync(filePath, "utf8");
const lines = content.split("\n");
const idx = lines.findIndex((l) => /^description:/.test(l));
if (idx === -1) { console.error("description: line not found"); process.exit(1); }
lines[idx] = lines[idx].replace(/^description:\s*/, "description: Note : marqueur de mutation, deux-points non quote en tete. ");
fs.writeFileSync(filePath, lines.join("\n"));
' "$WORK/t16/consolidator/SKILL.md"
T17_OUT="$(CDF_EXCEPTIONS_FILE="$WORK/t16-exceptions.tsv" bash "$GATE" --root "$WORK/t16" 2>&1)"
T17_RC=$?
echo "  [T17] asserté : exception dont le frontmatter ne parse plus (': ' non quoté injecté) — attendu : exit 1, message 'exception au frontmatter YAML invalide' + erreur du parseur strict — obtenu : exit $T17_RC : $T17_OUT"
if [ "$T17_RC" -eq 1 ] \
  && printf '%s' "$T17_OUT" | grep -qF 'exception au frontmatter YAML invalide' \
  && printf '%s' "$T17_OUT" | grep -qi 'mapping values are not allowed here'; then
  ok "T17 : exception au YAML invalide (': ' non quoté injecté) rougit — une exception dispense du quotage, jamais de la validité YAML stricte"
else
  ko "T17 : attendu exit 1 + 'exception au frontmatter YAML invalide' + erreur parseur strict, obtenu exit $T17_RC ($T17_OUT)"
fi

# --- T18 : contre-épreuve — même TSV d'exception, copie FRAÎCHE (non mutée) -> redevient vert.
# Preuve que le rouge de T17 vient bien de LA MUTATION, pas d'un fixture mort ou d'un défaut de
# résolution du TSV/racine (feedback_mutation-test-discriminating-cases).
# ---
rm -rf "$WORK/t18"
mkdir -p "$WORK/t18/consolidator"
cp "$SRC_EXC_REAL" "$WORK/t18/consolidator/SKILL.md"
T18_OUT="$(CDF_EXCEPTIONS_FILE="$WORK/t16-exceptions.tsv" bash "$GATE" --root "$WORK/t18" 2>&1)"
T18_RC=$?
echo "  [T18] asserté : contre-épreuve, copie fraîche non mutée, même déclaration d'exception — attendu : exit 0 — obtenu : exit $T18_RC"
if [ "$T18_RC" -eq 0 ]; then
  ok "T18 : contre-épreuve (copie fraîche, non mutée) redevient verte — le rouge de T17 est bien attribuable à la mutation"
else
  ko "T18 : contre-épreuve attendue verte, obtenu exit $T18_RC ($T18_OUT) — T17 non probant (peut-être un fixture mort)"
fi

# --- T19 : le fichier SOURCE réel du dépôt (consolidator/SKILL.md) reste byte-identique. ---
SRC_EXC_SHA_AFTER="$(sha256_file "$SRC_EXC_REAL")"
if [ "$SRC_EXC_SHA_BEFORE" = "$SRC_EXC_SHA_AFTER" ]; then
  ok "T19 : fichier source réel de l'exception ($SRC_EXC_REAL) byte-identique avant/après (sha256 $SRC_EXC_SHA_BEFORE)"
else
  ko "T19 : fichier source réel de l'exception MODIFIÉ par la mutation — avant=$SRC_EXC_SHA_BEFORE après=$SRC_EXC_SHA_AFTER"
fi

# =====================================================================================
# T20-T25 — couverture de la CLASSE « description en clair contenant à la fois un guillemet
# double ET une apostrophe, actuellement YAML valide, jamais déclarée en exception » (correction
# ciblée post-mesure-kimi, 38-MESURE-KIMI.md). Recensée sur l'arbre réel via --inventory : 4
# fichiers dans la catégorie "conservé tel quel" ("plain deja conforme aux deux regles, non
# requotable sans perte") — plugin/audit-architecture/SKILL.md, plugin/dev-orchestrator/AGENT.md
# (nommé au mandat), plugin/reference/.../templates/skills/agent-density-auditor/SKILL.md,
# plugin/reference/.../templates/skills/debugger/SKILL.md. AUCUN des 4 n'est dans EXCEPTIONS_REL
# — le mandat demande explicitement de NE PAS les y ajouter. Preuve requise : le gate les couvre
# DÉJÀ par construction (le mode audit par défaut checke TOUT fichier découvert non exempté) —
# une injection de ' : ' non quoté sur une COPIE de CHACUN doit rougir, jamais rester muette.
# =====================================================================================
CLASS_FILES=(
  "plugin/audit-architecture/SKILL.md"
  "plugin/dev-orchestrator/AGENT.md"
  "plugin/reference/content/methodology/templates/skills/agent-density-auditor/SKILL.md"
  "plugin/reference/content/methodology/templates/skills/debugger/SKILL.md"
)

# --- T20 : aucun des 4 n'est présent dans EXCEPTIONS_REL du gate réel (mandat : "ne l'ajoute pas
# comme exception"). Lu directement dans le SOURCE du gate, jamais recopié à la main. ---
T20_LEAK=0
for cf in "${CLASS_FILES[@]}"; do
  rel="${cf#plugin/}"
  if sed -n '/^EXCEPTIONS_REL=(/,/^)/p' "$GATE" | grep -qF "\"$rel\""; then
    T20_LEAK=1
    echo "  [T20] $rel est présent dans EXCEPTIONS_REL — ne devrait pas l'être (mandat)"
  fi
done
if [ "$T20_LEAK" -eq 0 ]; then
  ok "T20 : aucun des 4 fichiers de la classe n'est déclaré en exception (couverture par le mode audit par défaut, pas par dispense)"
else
  ko "T20 : au moins un fichier de la classe est déclaré en exception à tort"
fi

# --- T21-T24 : par fichier, contrôle vert (copie pristine dans une racine isolée reproduisant le
# chemin relatif réel, EXCEPTIONS_REL réel du gate — pas un override vide, pour prouver que
# l'absence d'exception est bien ce qui les couvre) PUIS mutant rouge (injection ' : ' en tête de
# description) PUIS contre-épreuve verte (copie fraîche). ---
CLASS_IDX=0
for cf in "${CLASS_FILES[@]}"; do
  CLASS_IDX=$((CLASS_IDX + 1))
  n="2$CLASS_IDX"
  src_real="$REPO/$cf"
  if [ ! -f "$src_real" ]; then
    skip "T$n : fichier de classe introuvable sur ce poste ('$src_real')"
    continue
  fi
  rel="${cf#plugin/}"
  fixroot="$WORK/class$CLASS_IDX/plugin"
  mkdir -p "$(dirname "$fixroot/$rel")"
  cp "$src_real" "$fixroot/$rel"
  src_sha_before="$(sha256_file "$src_real")"

  # Contrôle vert (copie pristine, EXCEPTIONS_REL réel — le gate résout ROOT="$fixroot", les
  # chemins d'exceptions réels ne matchent RIEN sous cette racine isolée : c'est voulu, seul le
  # fichier de classe existe sous $fixroot).
  ctrl_out="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$fixroot" 2>&1)"
  ctrl_rc=$?
  echo "  [T$n.contrôle] $rel — attendu : exit 0 — obtenu : exit $ctrl_rc"
  if [ "$ctrl_rc" -ne 0 ]; then
    ko "T$n.contrôle : $rel aurait dû être vert avant mutation, obtenu exit $ctrl_rc ($ctrl_out)"
    continue
  fi
  ok "T$n.contrôle : $rel vert avant mutation (couverture confirmée, non exempté)"

  # Mutant : injection ' : ' en TÊTE de la valeur de description (jamais en queue — un '#' précédé
  # d'espace plus loin dans certaines de ces descriptions absorberait le texte ajouté en commentaire
  # YAML implicite, cf. piège rencontré et documenté à T16-T19 ci-dessus).
  node -e '
const fs = require("fs");
const [, filePath] = process.argv;
const content = fs.readFileSync(filePath, "utf8");
const lines = content.split("\n");
const idx = lines.findIndex((l) => /^description:/.test(l));
if (idx === -1) { console.error("description: line not found"); process.exit(1); }
lines[idx] = lines[idx].replace(/^description:\s*/, "description: Note : marqueur de mutation, deux-points non quote en tete. ");
fs.writeFileSync(filePath, lines.join("\n"));
' "$fixroot/$rel"
  mut_out="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$fixroot" 2>&1)"
  mut_rc=$?
  echo "  [T$n.mutant] $rel (': ' injecté en tête) — attendu : exit 1, $rel nommé dans le rapport — obtenu : exit $mut_rc : $mut_out"
  if [ "$mut_rc" -eq 1 ] && printf '%s' "$mut_out" | grep -qF "$rel"; then
    ok "T$n.mutant : $rel rougit dès l'injection d'un ' : ' non quoté — la classe est bien surveillée par défaut"
  else
    ko "T$n.mutant : attendu exit 1 + '$rel' nommé, obtenu exit $mut_rc ($mut_out)"
  fi

  # Contre-épreuve : copie fraîche (non mutée) -> redevient verte.
  rm -f "$fixroot/$rel"
  cp "$src_real" "$fixroot/$rel"
  recheck_out="$(CDF_EXCEPTIONS_FILE="$EMPTY_EXC" bash "$GATE" --root "$fixroot" 2>&1)"
  recheck_rc=$?
  if [ "$recheck_rc" -eq 0 ]; then
    ok "T$n.contre-épreuve : $rel redevient vert (copie fraîche) — le rouge venait bien de la mutation"
  else
    ko "T$n.contre-épreuve : attendu exit 0, obtenu exit $recheck_rc ($recheck_out) — mutant potentiellement non confiné"
  fi

  src_sha_after="$(sha256_file "$src_real")"
  if [ "$src_sha_before" = "$src_sha_after" ]; then
    ok "T$n.byte-identique : fichier source réel ($rel) inchangé (sha256 $src_sha_before)"
  else
    ko "T$n.byte-identique : fichier source réel ($rel) MODIFIÉ par la mutation — avant=$src_sha_before après=$src_sha_after"
  fi
done

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
