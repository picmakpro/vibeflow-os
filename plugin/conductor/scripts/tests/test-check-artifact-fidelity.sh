#!/usr/bin/env bash
# test-check-artifact-fidelity.sh — Suite du gate de fidélité de conversion (Phase 38, FIDE-01).
#
# check-artifact-fidelity.sh :
#   T1 — content-clarity-judge.md (fixture copiée, isolée) --target codex → les 4 pertes réelles
#        (model/memory/disallowedTools/vf-internal) + 1 dégradation (tools) mesurées par
#        exécution réelle de la conversion gsd-core.
#   T2 — gsd-core absent (HOME/CLAUDE_CONFIG_DIR de sonde sans gsd-core) → exit 3, stdout vide.
#   T3 — --json produit un JSON valide (node -e JSON.parse).
#   T4 — cible inconnue (--target opencode) → exit 3, message "non mesuré".
#   T5 — --target codex sans binaire `codex` sur un PATH de sonde restreint →
#        multi_agent_v2=non mesurable, jamais une valeur par défaut.
#   T6 — --target codex avec un CODEX_HOME de sonde sans bloc [projects."…"] pour la racine
#        testée → trust_level=absent (non trusted), et la ligne [fidelity-recette] précède la
#        ligne [fidelity] dans le flux capturé.
#   T7 — count_markers() compte des occurrences, pas des lignes (extraction fonction isolée).
#   T8 — role_confinement=inerte-par-role présent sur la ligne [fidelity-recette] (FIDE-03).
#   T9 — --check-judge-command <absent> → exit 3, stdout vide (F13 : commande non posée ≠ vert).
#   T10-T13 — mutation, une par élément retiré (sandbox_mode / approval_policy / skills /
#        project_doc_max_bytes) : rouge (exit 1) avec l'élément manquant seul, PUIS vert (exit 0)
#        une fois la commande complète rejouée — même fixture, même helper, seul l'élément
#        retiré change, pour prouver que chaque rouge vient bien de CET élément (pas d'un
#        fixture mort).
#   T14-T18 — MÊME famille de mutation, mais ancrée sur le FICHIER RÉEL POSÉ
#        (codex-judge-session-command.md), qui répète chaque flag en PROSE sous le bloc de
#        commande — une fixture idéalisée (T10-T13) ne peut PAS attraper le défaut mesuré en
#        revue (FIDE-03) : muter la ligne de commande réelle en laissant la prose intacte
#        laissait l'ancien gate à COMPLET. T14 = sonde (prose dupliquée présente) + contrôle
#        vert avant mutation. T15-T18 = les 4 mutations rejouées sur CE fichier, prose vérifiée
#        intacte à chaque fois, doivent rougir.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe (SKIP non
# bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test-vibeflow-update.sh.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$SCRIPTS_DIR/check-artifact-fidelity.sh"
REPO="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
FIXTURE_SRC="$REPO/plugin/content-bundle/agents/content-clarity-judge.md"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-check-artifact-fidelity (gate: $GATE) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Résout, comme le gate, le home gsd-core réellement présent sur ce poste — la suite ne
# recopie jamais son chemin en dur.
REAL_GSD_HOME=""
if [ -d "$REPO/.claude/gsd-core" ]; then
  REAL_GSD_HOME="$REPO/.claude/gsd-core"
elif [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/VERSION" ]; then
  REAL_GSD_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core"
fi

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

if [ -z "$REAL_GSD_HOME" ] || [ ! -f "$FIXTURE_SRC" ]; then
  skip "T1-T6 : gsd-core ou fixture introuvables sur ce poste (REAL_GSD_HOME='$REAL_GSD_HOME', fixture='$FIXTURE_SRC')"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  [ "$fail" -eq 0 ]
  exit $?
fi

# Fixture isolée : copie de content-clarity-judge.md dans le WORK (jamais l'artefact source
# du dépôt, pour rester en lecture seule sur le dépôt).
FIXTURE="$WORK/content-clarity-judge.md"
cp "$FIXTURE_SRC" "$FIXTURE"

# ---------------------------------------------------------------------------
# T1 — les 4 pertes réelles + 1 dégradation, mesurées (pas recopiées en dur avant exécution).
# ---------------------------------------------------------------------------
T1_OUT="$(cd "$REPO" && bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t1.err")"
T1_RC=$?

if [ "$T1_RC" -eq 0 ]; then
  ok "T1.rc : exit 0 (mesure exécutée)"
else
  ko "T1.rc : attendu exit 0, obtenu $T1_RC (stderr: $(cat "$WORK/t1.err"))"
fi

FIDELITY_LINE="$(printf '%s\n' "$T1_OUT" | grep '^\[fidelity\]')"
if [ -n "$FIDELITY_LINE" ]; then
  ok "T1.ligne : [fidelity] présente"
else
  ko "T1.ligne : [fidelity] absente de la sortie ($T1_OUT)"
fi

for champ in model disallowedTools vf-internal; do
  if printf '%s\n' "$FIDELITY_LINE" | grep -q "LOST={[^}]*\b${champ}\b"; then
    ok "T1.LOST : $champ dans LOST="
  else
    ko "T1.LOST : $champ absent de LOST= (ligne: $FIDELITY_LINE)"
  fi
done
if printf '%s\n' "$FIDELITY_LINE" | grep -q "LOST={[^}]*\bmemory\b"; then
  ok "T1.LOST : memory dans LOST="
else
  ko "T1.LOST : memory absent de LOST= (ligne: $FIDELITY_LINE)"
fi

if printf '%s\n' "$FIDELITY_LINE" | grep -q "DEGRADED={[^}]*\btools\b"; then
  ok "T1.DEGRADED : tools dans DEGRADED="
else
  ko "T1.DEGRADED : tools absent de DEGRADED= (ligne: $FIDELITY_LINE)"
fi

if printf '%s\n' "$FIDELITY_LINE" | grep -q "PRESERVED={[^}]*\bname\b" \
  && printf '%s\n' "$FIDELITY_LINE" | grep -q "PRESERVED={[^}]*\bdescription\b"; then
  ok "T1.PRESERVED : name et description préservés (model étant LOST, sur la MÊME exécution)"
else
  ko "T1.PRESERVED : name/description absents de PRESERVED= (ligne: $FIDELITY_LINE)"
fi

# ---------------------------------------------------------------------------
# T2 — gsd-core absent : exit 3, stdout vide.
# ---------------------------------------------------------------------------
SONDE_HOME="$WORK/sonde-no-gsd-core"
mkdir -p "$SONDE_HOME"
T2_OUT="$(HOME="$SONDE_HOME" CLAUDE_CONFIG_DIR="$SONDE_HOME/.claude" bash "$GATE" --target codex "$FIXTURE" 2>/dev/null)"
T2_RC=$?
if [ "$T2_RC" -eq 3 ]; then
  ok "T2.rc : gsd-core absent → exit 3"
else
  ko "T2.rc : attendu exit 3, obtenu $T2_RC"
fi
if [ -z "$T2_OUT" ]; then
  ok "T2.stdout : vide"
else
  ko "T2.stdout : non vide ('$T2_OUT')"
fi

# ---------------------------------------------------------------------------
# T3 — --json produit un JSON valide.
# ---------------------------------------------------------------------------
if (cd "$REPO" && bash "$GATE" --target codex --json "$FIXTURE" 2>"$WORK/t3.err" \
    | node -e "JSON.parse(require('fs').readFileSync(0,'utf8'))" >/dev/null 2>&1); then
  ok "T3 : --json parse (node JSON.parse)"
else
  ko "T3 : --json ne parse pas (stderr gate: $(cat "$WORK/t3.err" 2>/dev/null))"
fi

# ---------------------------------------------------------------------------
# T4 — cible inconnue → exit 3, stdout VIDE (contrat de l'en-tête, l. 22-28), message
# "non mesuré" sur stderr (jamais stdout : un consommateur de stdout ne doit rien voir).
# ---------------------------------------------------------------------------
T4_OUT="$(cd "$REPO" && bash "$GATE" --target opencode "$FIXTURE" 2>"$WORK/t4.err")"
T4_RC=$?
T4_ERR="$(cat "$WORK/t4.err" 2>/dev/null)"
if [ "$T4_RC" -eq 3 ]; then
  ok "T4.rc : cible inconnue → exit 3"
else
  ko "T4.rc : attendu exit 3, obtenu $T4_RC"
fi
if [ -z "$T4_OUT" ]; then
  ok "T4.stdout : vide (contrat de l'en-tête)"
else
  ko "T4.stdout : non vide ('$T4_OUT')"
fi
if printf '%s' "$T4_ERR" | grep -q "non mesuré"; then
  ok "T4.stderr : 'non mesuré' présent sur stderr"
else
  ko "T4.stderr : 'non mesuré' absent ('$T4_ERR')"
fi

# ---------------------------------------------------------------------------
# T5 — PATH de sonde sans `codex` → multi_agent_v2=non mesurable.
# ---------------------------------------------------------------------------
NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  skip "T5 : node introuvable sur le PATH courant, impossible de construire un PATH de sonde"
else
  SONDE_BIN="$WORK/sonde-bin"
  mkdir -p "$SONDE_BIN"
  ln -sf "$NODE_BIN" "$SONDE_BIN/node"
  T5_OUT="$(cd "$REPO" && env -i PATH="$SONDE_BIN:/usr/bin:/bin" HOME="$HOME" \
    CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}" bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t5.err")"
  T5_RC=$?
  if [ "$T5_RC" -eq 0 ] && printf '%s' "$T5_OUT" | grep -q "multi_agent_v2=non mesurable"; then
    ok "T5 : codex absent du PATH → multi_agent_v2=non mesurable (jamais une valeur par défaut)"
  else
    ko "T5 : attendu 'multi_agent_v2=non mesurable', obtenu rc=$T5_RC sortie='$T5_OUT' (stderr: $(cat "$WORK/t5.err" 2>/dev/null))"
  fi
fi

# ---------------------------------------------------------------------------
# T6 — CODEX_HOME de sonde sans bloc [projects."…"] → trust_level=absent (non trusted),
# et [fidelity-recette] précède [fidelity] dans le flux capturé.
# ---------------------------------------------------------------------------
SONDE_CODEX_HOME="$WORK/sonde-codex-home"
mkdir -p "$SONDE_CODEX_HOME"
{
  echo '[projects."/some/other/repo/never/matches"]'
  echo 'trust_level = "trusted"'
} > "$SONDE_CODEX_HOME/config.toml"

T6_OUT="$(cd "$REPO" && CODEX_HOME="$SONDE_CODEX_HOME" bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t6.err")"
T6_RC=$?
if [ "$T6_RC" -eq 0 ] && printf '%s' "$T6_OUT" | grep -q "trust_level=absent (non trusted)"; then
  ok "T6.trust_level : bloc [projects.…] non concordant → absent (non trusted)"
else
  ko "T6.trust_level : attendu 'trust_level=absent (non trusted)', obtenu rc=$T6_RC sortie='$T6_OUT' (stderr: $(cat "$WORK/t6.err" 2>/dev/null))"
fi

RECETTE_LINE_NO="$(printf '%s\n' "$T6_OUT" | grep -n '^\[fidelity-recette\]' | head -1 | cut -d: -f1)"
FIDELITY_LINE_NO="$(printf '%s\n' "$T6_OUT" | grep -n '^\[fidelity\]' | head -1 | cut -d: -f1)"
if [ -n "$RECETTE_LINE_NO" ] && [ -n "$FIDELITY_LINE_NO" ] && [ "$RECETTE_LINE_NO" -lt "$FIDELITY_LINE_NO" ]; then
  ok "T6.ordre : [fidelity-recette] précède [fidelity] dans le flux capturé"
else
  ko "T6.ordre : ordre inattendu (recette=$RECETTE_LINE_NO, fidelity=$FIDELITY_LINE_NO, sortie='$T6_OUT')"
fi

# ---------------------------------------------------------------------------
# T8 — role_confinement (FIDE-03, D-38-O) : 3e fait de recette, MÊME rang que multi_agent_v2/
# trust_level, sur la MÊME ligne [fidelity-recette] déjà relayée verbatim à l'install (FIDE-02).
# ---------------------------------------------------------------------------
if printf '%s\n' "$T6_OUT" | grep -q '^\[fidelity-recette\].*role_confinement=inerte-par-role'; then
  ok "T8 : role_confinement=inerte-par-role présent sur [fidelity-recette] (au même rang)"
else
  ko "T8 : role_confinement absent ou mal formé sur [fidelity-recette] (sortie: $T6_OUT)"
fi

# ---------------------------------------------------------------------------
# T7 — count_markers() compte des OCCURRENCES, pas des lignes : une ligne portant DEUX
# marqueurs (deux `.claude/`) doit valoir 2, pas 1 (défaut : `grep -c` compterait la ligne
# une seule fois). Fonction extraite du gate lui-même (jamais recopiée à la main) et exécutée
# isolément — la sonde décisive est la ligne à deux occurrences.
# ---------------------------------------------------------------------------
COUNT_MARKERS_SRC="$(sed -n '/^count_markers() {/,/^}/p' "$GATE")"
if [ -z "$COUNT_MARKERS_SRC" ]; then
  ko "T7 : count_markers() introuvable dans $GATE (extraction vide)"
else
  T7_RESULT="$(bash -c "$COUNT_MARKERS_SRC"'
count_markers "Voir .claude/agents/foo.md et aussi .claude/skills/bar pour Task( details"')"
  if [ "$T7_RESULT" -eq 3 ]; then
    ok "T7 : ligne à 2x '.claude/' + 1x 'Task(' → 3 occurrences (pas 2 lignes)"
  else
    ko "T7 : attendu 3 occurrences sur la ligne à marqueurs multiples, obtenu '$T7_RESULT'"
  fi
fi

# ---------------------------------------------------------------------------
# T9 — --check-judge-command <fichier absent> → exit 3, stdout VIDE. Le lot 5 (pose des rôles
# Codex) n'a pas encore livré la commande sur ce poste : « pas encore posée » et « posée et
# conforme » ne doivent JAMAIS produire la même sortie (contrat F13 appliqué à ce gate lui-même).
# ---------------------------------------------------------------------------
ABSENT_JUDGE_CMD="$WORK/judge-cmd-absent.sh"
T9_OUT="$(bash "$GATE" --check-judge-command "$ABSENT_JUDGE_CMD" 2>"$WORK/t9.err")"
T9_RC=$?
if [ "$T9_RC" -eq 3 ]; then
  ok "T9.rc : commande de juge non posée → exit 3"
else
  ko "T9.rc : attendu exit 3, obtenu $T9_RC"
fi
if [ -z "$T9_OUT" ]; then
  ok "T9.stdout : vide (F13 : indéterminé ≠ vert)"
else
  ko "T9.stdout : non vide ('$T9_OUT')"
fi

# ---------------------------------------------------------------------------
# T10-T13 — mutation ciblée, un élément retiré à la fois. Rouge (exit 1) avec l'élément
# manquant SEUL comme absent, PUIS vert (exit 0) en rejouant la commande complète — même
# fichier de départ, pour prouver que chaque rouge vient bien de l'élément retiré et pas d'un
# fixture mort (leçon feedback_mutation-test-discriminating-cases).
# ---------------------------------------------------------------------------
COMPLETE_JUDGE_CMD="$WORK/judge-cmd-complete.sh"
cat > "$COMPLETE_JUDGE_CMD" <<'CMDEOF'
```bash
codex exec -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false \
  -c project_doc_max_bytes=0 \
  --output-schema schema.json "mandat, chemins absolus"
```
CMDEOF

# Contrôle : la commande complète doit être VERTE avant tout mutant (sinon un rouge ci-dessous
# ne prouverait rien — fixture potentiellement déjà cassée).
T_COMPLETE_OUT="$(bash "$GATE" --check-judge-command "$COMPLETE_JUDGE_CMD" 2>"$WORK/tcomplete.err")"
T_COMPLETE_RC=$?
if [ "$T_COMPLETE_RC" -eq 0 ] && printf '%s' "$T_COMPLETE_OUT" | grep -q '^\[fidelity-judge-command\].*COMPLET'; then
  ok "T10-13.contrôle : commande complète (4/4) → exit 0 COMPLET avant toute mutation"
else
  ko "T10-13.contrôle : commande complète attendue verte, obtenu rc=$T_COMPLETE_RC sortie='$T_COMPLETE_OUT'"
fi

run_mutation_case() {
  # $1 = numéro de test, $2 = fichier muté (élément retiré), $3 = fragment attendu dans manque=
  local n="$1" mutated="$2" expect_missing="$3"
  local mout mrc
  mout="$(bash "$GATE" --check-judge-command "$mutated" 2>"$WORK/mut-$n.err")"
  mrc=$?
  if [ "$mrc" -eq 1 ]; then
    ok "T$n.rouge : élément '$expect_missing' retiré → exit 1"
  else
    ko "T$n.rouge : attendu exit 1, obtenu $mrc (sortie: '$mout')"
  fi
  if printf '%s' "$mout" | grep -qF "$expect_missing"; then
    ok "T$n.diagnostic : manque= cite '$expect_missing' (rouge attribuable à CET élément)"
  else
    ko "T$n.diagnostic : 'manque=' ne cite pas '$expect_missing' (sortie: '$mout')"
  fi
  # Contre-épreuve : réinjecter l'élément complet redevient vert — le mutant est bien la cause
  # du rouge, pas un fixture mort qui resterait rouge quoi qu'on fasse.
  local vout vrc
  vout="$(bash "$GATE" --check-judge-command "$COMPLETE_JUDGE_CMD" 2>/dev/null)"
  vrc=$?
  if [ "$vrc" -eq 0 ]; then
    ok "T$n.vert : la commande complète (non mutée) reste verte — mutant confiné au fichier muté"
  else
    ko "T$n.vert : la commande complète est repassée rouge (rc=$vrc) — mutant a fui hors de sa fixture"
  fi
}

# T10 — retire "-s read-only".
MUT_SANDBOX="$WORK/mut-sandbox.sh"
sed 's/-s read-only //' "$COMPLETE_JUDGE_CMD" > "$MUT_SANDBOX"
run_mutation_case 10 "$MUT_SANDBOX" "sandbox_mode"

# T11 — retire "-c approval_policy='\"never\"'".
MUT_APPROVAL="$WORK/mut-approval.sh"
sed "s/-c approval_policy='\"never\"' //" "$COMPLETE_JUDGE_CMD" > "$MUT_APPROVAL"
run_mutation_case 11 "$MUT_APPROVAL" "approval_policy=never"

# T12 — retire "-c skills.include_instructions=false".
MUT_SKILLS="$WORK/mut-skills.sh"
sed '/skills\.include_instructions=false/d' "$COMPLETE_JUDGE_CMD" > "$MUT_SKILLS"
run_mutation_case 12 "$MUT_SKILLS" "skills.include_instructions=false"

# T13 — retire "-c project_doc_max_bytes=0".
MUT_DOCBYTES="$WORK/mut-docbytes.sh"
sed '/project_doc_max_bytes=0/d' "$COMPLETE_JUDGE_CMD" > "$MUT_DOCBYTES"
run_mutation_case 13 "$MUT_DOCBYTES" "project_doc_max_bytes=0"

# ---------------------------------------------------------------------------
# T14-T18 — même famille de mutation, mais sur le FICHIER RÉEL POSÉ
# (codex-judge-session-command.md), pas sur COMPLETE_JUDGE_CMD (fixture synthétique qui ne
# contient QUE la ligne de commande, sans la prose dupliquée du fichier réel). Défaut mesuré
# (revue Phase 38, FIDE-03) : ce fichier répète chaque flag en PROSE sous le bloc de commande
# (titre, liste explicative « 1. `-s read-only` — … ») — jusqu'à 3 fois pour `read-only` et
# `skills.include_instructions=false`. L'ancien gate aplatissait le fichier ENTIER et cherchait
# les 4 motifs n'importe où : muter UNIQUEMENT la ligne de commande réelle en laissant la prose
# intacte le laissait à COMPLET, les 4 fois — une fixture idéalisée NE PEUT PAS attraper ce
# défaut par construction (c'est précisément lui qui rendait test-check-artifact-fidelity.sh
# vert malgré le trou). D'où T14 : un test ancré sur le fichier réel, PUIS T15-T18 : les 4
# mutations rejouées dessus, chacune retirant l'élément UNIQUEMENT du bloc de commande (jamais
# de la prose), qui doit rougir.
# ---------------------------------------------------------------------------
REAL_JUDGE_CMD_FILE="$REPO/plugin/_internal/runtime-adapter/codex-judge-session-command.md"

if [ ! -f "$REAL_JUDGE_CMD_FILE" ]; then
  skip "T14-T18 : fichier réel introuvable ($REAL_JUDGE_CMD_FILE)"
else
  # T14 — contrôle : le fichier réel, non muté, doit être vert AVANT toute mutation (sinon un
  # rouge ci-dessous ne prouverait rien) — ET ce fichier porte bien la prose dupliquée mesurée
  # (sinon T15-T18 ne discrimineraient rien : sonde décisive avant le test décisif lui-même).
  REAL_READONLY_COUNT="$(grep -c 'read-only' "$REAL_JUDGE_CMD_FILE")"
  if [ "$REAL_READONLY_COUNT" -ge 2 ]; then
    ok "T14.sonde : le fichier réel répète 'read-only' hors du bloc de commande ($REAL_READONLY_COUNT occurrences) — la prose dupliquée mesurée est bien présente"
  else
    ko "T14.sonde : le fichier réel ne répète plus 'read-only' en dehors du bloc de commande ($REAL_READONLY_COUNT occurrence) — T15-T18 ne discrimineraient plus rien, à revoir"
  fi

  T14_OUT="$(bash "$GATE" --check-judge-command "$REAL_JUDGE_CMD_FILE" 2>"$WORK/t14.err")"
  T14_RC=$?
  if [ "$T14_RC" -eq 0 ] && printf '%s' "$T14_OUT" | grep -q '^\[fidelity-judge-command\].*COMPLET'; then
    ok "T14.contrôle : fichier réel posé, non muté → exit 0 COMPLET avant toute mutation"
  else
    ko "T14.contrôle : fichier réel attendu vert, obtenu rc=$T14_RC sortie='$T14_OUT'"
  fi

  run_real_mutation_case() {
    # $1 = numéro de test, $2 = ligne(s) du BLOC DE COMMANDE (14-19) à muter via sed, $3 =
    # fragment attendu dans manque=, $4 = description de la mutation, $5 = fragment de PROSE
    # invariant attendu toujours présent après mutation (ancre par CONTENU, jamais par numéro de
    # ligne : une suppression de ligne dans le bloc de commande décale tout ce qui suit —
    # comparer des plages de lignes absolues donnerait un faux « prose touchée »).
    local n="$1" sed_expr="$2" expect_missing="$3" desc="$4" prose_anchor="$5"
    local mutated="$WORK/real-mut-$n.md"
    sed "$sed_expr" "$REAL_JUDGE_CMD_FILE" > "$mutated"

    # Sonde : la prose doit toujours porter ce fragment invariant — la mutation ne doit toucher
    # QUE le bloc de commande, jamais la prose qui répète le même motif juste en dessous (sinon
    # le test ne reproduirait pas le défaut réel : « éditeur qui touche la commande sans toucher
    # la prose »).
    if grep -qF "$prose_anchor" "$mutated"; then
      ok "T$n.confinement : prose intacte ('$prose_anchor' toujours présent) — seul le bloc de commande a été muté"
    else
      ko "T$n.confinement : la prose a été touchée par la mutation ($desc) — le test ne reproduit plus le défaut réel"
    fi

    local mout mrc
    mout="$(bash "$GATE" --check-judge-command "$mutated" 2>"$WORK/real-mut-$n.err")"
    mrc=$?
    if [ "$mrc" -eq 1 ]; then
      ok "T$n.rouge : $desc retiré du bloc de commande SEUL (prose intacte) → exit 1"
    else
      ko "T$n.rouge : attendu exit 1 ($desc, fichier réel, prose intacte), obtenu $mrc (sortie: '$mout')"
    fi
    if printf '%s' "$mout" | grep -qF "$expect_missing"; then
      ok "T$n.diagnostic : manque= cite '$expect_missing' sur le fichier réel"
    else
      ko "T$n.diagnostic : 'manque=' ne cite pas '$expect_missing' sur le fichier réel (sortie: '$mout')"
    fi
  }

  # T15 — retire "-s read-only " de la ligne 15 (commande) uniquement ; la prose l.1 et l.21
  # continue de porter "read-only".
  run_real_mutation_case 15 '15s/-s read-only //' "sandbox_mode" "sandbox_mode (-s read-only)" \
    "confinement d'écriture réel"

  # T16 — retire "-c approval_policy='\"never\"' " de la ligne 15 uniquement.
  run_real_mutation_case 16 "15s/-c approval_policy='\"never\"' //" "approval_policy=never" "approval_policy=never" \
    "aucune invite d'escalade côté juge"

  # T17 — supprime la ligne 16 (skills.include_instructions=false) du bloc de commande
  # uniquement ; la prose l.10 et l.24 continue de le citer.
  run_real_mutation_case 17 '16d' "skills.include_instructions=false" "skills.include_instructions=false" \
    "ferme le bloc"

  # T18 — supprime la ligne 17 (project_doc_max_bytes=0) du bloc de commande uniquement.
  run_real_mutation_case 18 '17d' "project_doc_max_bytes=0" "project_doc_max_bytes=0" \
    "ferme le canal"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
