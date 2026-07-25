#!/usr/bin/env bash
# test-check-agents.sh — Suite du gate de conformité NATIVE des agents (ADR-044).
#
# check-agents.sh :
#   T1 — agent complet (name/description/model/memory/skills existants) → exit 0
#   T2 — agent sans frontmatter → exit 1
#   T3 — agent sans description / sans model / sans memory → exit 1 (3 erreurs)
#   T4 — enums invalides (model, memory, effort) → exit 1
#   T5 — champ inconnu (typo) → warning, non bloquant si socle OK
#   T6 — skill déclaré introuvable : warning en défaut, ERREUR en --strict
#   T7 — budget préchargement : skill > 200L → warning ; cumul > VF_PRELOAD_MAX → erreur
#   T8 — skill disable-model-invocation:true préchargé → erreur
#   T9 — --hook : exit 0 même non conforme, signalement compact
#   T10 — contracts.md/README.md ignorés (pas des agents)
#
# guard-agent-write.sh (PreToolUse Write) :
#   T11 — Write d'un agent non natif dans .claude/agents/ → DENY avec squelette
#   T12 — Write d'un agent conforme → allow
#   T13 — Write hors .claude/agents/ ou contracts.md → allow
#   T14 — stdin invalide → allow silencieux (fail-open)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CHECK="$SCRIPTS_DIR/check-agents.sh"
GUARD="$SCRIPTS_DIR/guard-agent-write.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-check-agents (gate: $CHECK) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AG="$WORK/agents"; SK="$WORK/skills"
mkdir -p "$AG" "$SK/petit-skill" "$SK/gros-skill" "$SK/forbidden-skill"

printf -- '---\nname: petit-skill\ndescription: petit skill de test\n---\ncontenu court\n' > "$SK/petit-skill/SKILL.md"
{ printf -- '---\nname: gros-skill\ndescription: gros skill de test\n---\n'; for i in $(seq 1 260); do echo "ligne $i"; done; } > "$SK/gros-skill/SKILL.md"
printf -- '---\nname: forbidden-skill\ndescription: user-only\ndisable-model-invocation: true\n---\ncontenu\n' > "$SK/forbidden-skill/SKILL.md"

good_agent() {
  cat > "$AG/$1.md" <<EOF
---
name: $1
description: Pilote les tests du lab de bout en bout. Use when une suite de tests doit etre lancee ou analysee.
model: sonnet
memory: project
skills:
  - petit-skill
---
Corps de l agent.
EOF
}

run_check() { bash "$CHECK" --agents-dir="$AG" --skills-dir="$SK" "$@"; }

# T1 — conforme
good_agent "agent-test"
if OUT="$(run_check 2>&1)"; then ok "T1 agent complet → exit 0"; else ko "T1 rejeté : $OUT"; fi
rm -f "$AG"/*.md

# T2 — sans frontmatter
printf 'Juste du texte sans frontmatter.\n' > "$AG/nu.md"
if run_check >/dev/null 2>&1; then ko "T2 agent sans frontmatter accepté"; else ok "T2 sans frontmatter → exit 1"; fi
rm -f "$AG"/*.md

# T3 — socle manquant
printf -- '---\nname: incomplet\n---\ncorps\n' > "$AG/incomplet.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "description" && echo "$OUT" | grep -q "model" && echo "$OUT" | grep -q "memory"; then
  ok "T3 description/model/memory manquants → 3 erreurs bloquantes"
else
  ko "T3 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T4 — enums invalides
printf -- '---\nname: enums\ndescription: agent aux enums invalides pour le test de validation\nmodel: gpt-4\nmemory: global\neffort: extreme\n---\ncorps\n' > "$AG/enums.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "model invalide" && echo "$OUT" | grep -q "memory invalide" && echo "$OUT" | grep -q "effort invalide"; then
  ok "T4 enums invalides (model/memory/effort) → erreurs"
else
  ko "T4 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T5 — champ inconnu = warning seulement
good_agent "typo-agent"
printf -- '---\nname: typo-agent\ndescription: Agent valide avec un champ au nom errone pour tester la detection. Use when test.\nmodle: sonnet\nmodel: sonnet\nmemory: project\n---\ncorps\n' > "$AG/typo-agent.md"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "champ inconnu du runtime — modle"; then
  ok "T5 champ inconnu (typo) → warning non bloquant"
else
  ko "T5 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T6 — skill introuvable : warning en défaut, erreur en strict
cat > "$AG/halluc.md" <<'EOF'
---
name: halluc
description: Agent qui declare un skill jamais cree, pour tester le gate anti-hallucination.
model: sonnet
memory: project
skills:
  - skill-fantome
---
corps
EOF
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 1 ]; then
  ok "T6 skill introuvable : warning en défaut, ERREUR en --strict"
else
  ko "T6 (défaut=$RC_DEF strict=$RC_STRICT)"
fi
rm -f "$AG"/*.md

# T7 — budget préchargement
cat > "$AG/lourd.md" <<'EOF'
---
name: lourd
description: Agent qui precharge un gros skill, pour tester le budget de prechargement.
model: sonnet
memory: project
skills:
  - gros-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
COND1=$([ $RC -eq 0 ] && echo yes || echo no)
COND2=$(echo "$OUT" | grep -q "candidat on-demand" && echo yes || echo no)
OUT_MAX="$(VF_PRELOAD_MAX=100 run_check 2>&1)"; RC_MAX=$?
if [ "$COND1" = "yes" ] && [ "$COND2" = "yes" ] && [ $RC_MAX -eq 1 ] && echo "$OUT_MAX" | grep -q "budget de prechargement depasse"; then
  ok "T7 gros skill préchargé → warning ; cumul > VF_PRELOAD_MAX → erreur"
else
  ko "T7 (rc=$RC/$RC_MAX) : $OUT_MAX"
fi
rm -f "$AG"/*.md

# T8 — skill non préchargeable
cat > "$AG/interdit.md" <<'EOF'
---
name: interdit
description: Agent qui precharge un skill user-only, pour tester la restriction runtime.
model: sonnet
memory: project
skills:
  - forbidden-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 1 ] && echo "$OUT" | grep -q "disable-model-invocation"; then
  ok "T8 skill disable-model-invocation préchargé → erreur"
else
  ko "T8 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T9 — hook mode
printf 'sans frontmatter\n' > "$AG/casse.md"
OUT="$(run_check --hook 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "non conforme"; then
  ok "T9 --hook : exit 0 + signalement compact"
else
  ko "T9 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# T10 — contracts.md / README.md ignorés
printf 'pas un agent\n' > "$AG/contracts.md"
printf 'pas un agent\n' > "$AG/README.md"
good_agent "vrai-agent"
if run_check >/dev/null 2>&1; then ok "T10 contracts.md/README.md ignorés"; else ko "T10 fichiers non-agents lintés à tort"; fi
rm -f "$AG"/*.md

# ---------- guard-agent-write ----------
# Le guard ne s'applique qu'au LAB COURANT (CND-05) : les payloads ciblent $WORK/lab et le
# guard est exécuté avec cwd = $WORK/lab (comme le hook réel, cwd = racine du projet).
mkdir -p "$WORK/lab/.claude/agents"
payload_write() {
  # $1 = file_path · $2 = fichier contenant le content
  python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':sys.argv[1],'content':open(sys.argv[2]).read()}}))" "$1" "$2"
}
run_guard() { # $1 payload sur stdin — exécute le guard depuis le lab
  ( cd "$WORK/lab" && bash "$GUARD" 2>/dev/null )
}

BAD="$WORK/bad-content.md"
printf -- '---\nname: nouvel-agent\ndescription: court\n---\ncorps\n' > "$BAD"
GOOD="$WORK/good-content.md"
cat > "$GOOD" <<'EOF'
---
name: nouvel-agent
description: Analyse les ventes du lab et prepare les relances. Use when un cycle de vente demarre.
model: sonnet
memory: project
---
corps
EOF

OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$BAD" | run_guard)"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "Squelette canonique"; then
  ok "T11 Write agent non natif → deny avec squelette"
else
  ko "T11 deny attendu : ${OUT:-<vide>}"
fi

OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$GOOD" | run_guard)"
[ -z "$OUT" ] && ok "T12 Write agent conforme → allow" || ko "T12 allow attendu : $OUT"

OUT1="$(payload_write "$WORK/lab/docs/note.md" "$BAD" | run_guard)"
OUT2="$(payload_write "$WORK/lab/.claude/agents/contracts.md" "$BAD" | run_guard)"
{ [ -z "$OUT1" ] && [ -z "$OUT2" ]; } && ok "T13 hors agents/ + contracts.md → allow" || ko "T13 allow attendu"

OUT="$(echo 'pas du json' | run_guard)"; RC=$?
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } && ok "T14 stdin invalide → fail-open" || ko "T14 fail-open (rc=$RC)"

# ---------- durcissements audit S061 (CND-01..05, CND-10) ----------

# T15 — CND-01 : frontmatter YAML quoté (parfaitement valide) → conforme
cat > "$AG/quoted.md" <<'EOF'
---
name: "quoted"
description: "Use when: un cycle de vente demarre et il faut analyser les relances du lab."
model: 'sonnet'
memory: "project"
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T15 scalaires YAML quotés → conforme (CND-01)"; else ko "T15 faux positif sur quotes : $(run_check 2>&1 | tail -3)"; fi
rm -f "$AG"/*.md

# T16 — CND-02 : description en plain scalar multi-ligne → conforme
cat > "$AG/multiline.md" <<'EOF'
---
name: multiline
description:
  Analyse les ventes du lab et prepare les relances commerciales.
  Use when un cycle de vente demarre ou quand un prospect relance.
model: sonnet
memory: project
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T16 description multi-ligne (plain scalar) → conforme (CND-02)"; else ko "T16 faux positif multi-ligne : $(run_check 2>&1 | tail -3)"; fi
rm -f "$AG"/*.md

# T17 — CND-03 : skills en chaîne plate ne contourne plus le gate --strict
cat > "$AG/chaine.md" <<'EOF'
---
name: chaine
description: Agent declarant ses skills en chaine plate, pour tester le contournement du gate.
model: sonnet
memory: project
skills: skill-fantome, petit-skill
---
corps
EOF
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
[ "$RC_STRICT" -eq 1 ] && ok "T17 skills: en chaîne + --strict → gate actif (CND-03)" || ko "T17 gate contourné (rc=$RC_STRICT)"
rm -f "$AG"/*.md

# T18 — CND-10 : BOM UTF-8 devant le frontmatter → conforme
printf '\xef\xbb\xbf' > "$AG/bom.md"
cat >> "$AG/bom.md" <<'EOF'
---
name: bom
description: Agent avec BOM UTF-8 d origine externe, pour tester la tolerance d encodage.
model: sonnet
memory: project
---
corps
EOF
if run_check >/dev/null 2>&1; then ok "T18 BOM UTF-8 toléré (CND-10)"; else ko "T18 faux positif BOM"; fi
rm -f "$AG"/*.md

# T19 — CND-04 : crash interne du checker → ALLOW (anti-trappe), pas un deny générique
OUT="$(payload_write "$WORK/lab/.claude/agents/nouvel-agent.md" "$GOOD" | ( cd "$WORK/lab" && VF_PRELOAD_WARN=abc bash "$GUARD" 2>/dev/null ))"
[ -z "$OUT" ] && ok "T19 checker cassé (env corrompu) → fail-open (CND-04)" || ko "T19 deny aveugle : $OUT"

# T20 — CND-05 : agent HORS du lab courant (perso user-level, autre projet) → allow
OUT="$(payload_write "$WORK/ailleurs/.claude/agents/perso.md" "$BAD" | run_guard)"
[ -z "$OUT" ] && ok "T20 agent hors lab courant → allow (CND-05)" || ko "T20 doctrine imposée hors lab : $OUT"

# T21 — F13 (vacuous green) : --strict sur cible vide → exit 3 (INDÉTERMINÉ, pas un vert)
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "T21 --strict + aucun agent → exit 3 INDÉTERMINÉ (F13)" || ko "T21 cible vide devrait sortir 3, obtenu rc=$RC"

# T22 — F13 : --strict --allow-empty sur cible vide → exit 0 (opt-in explicite)
RC=0; run_check --strict --allow-empty >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T22 --strict --allow-empty + aucun agent → exit 0 (opt-in)" || ko "T22 --allow-empty devrait sortir 0, obtenu rc=$RC"

# T23 — compat : mode défaut (sans --strict) sur cible vide → exit 0 inchangé (labs sans agents)
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T23 défaut + aucun agent → exit 0 (compat labs)" || ko "T23 défaut devrait rester 0, obtenu rc=$RC"

# T24 — UAT F2 : skill déclaré par son frontmatter name: (≠ nom de dossier) → résolu en --strict
# (ex. réel : module planning-core installé sous .claude/skills/planning-core/ avec name: vf-planning)
mkdir -p "$SK/planning-core"
printf -- '---\nname: vf-planning\ndescription: socle planning du lab, name different du dossier\n---\ncontenu court\n' > "$SK/planning-core/SKILL.md"
cat > "$AG/routeur.md" <<'EOF'
---
name: routeur
description: Agent declarant un skill par son name frontmatter et non par son dossier, pour tester la resolution.
model: sonnet
memory: project
skills:
  - vf-planning
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T24 skill résolu par frontmatter name: (vf-planning → planning-core/) en --strict" || ko "T24 résolution par name: échouée (rc=$RC) : $(run_check --strict 2>&1 | tail -3)"

# T24b — un skill réellement absent (ni dossier ni name:) reste une ERREUR en --strict
cat > "$AG/routeur.md" <<'EOF'
---
name: routeur
description: Agent declarant un skill totalement inexistant, pour verifier que le gate reste actif.
model: sonnet
memory: project
skills:
  - skill-vraiment-fantome
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T24b skill inexistant (ni dossier ni name:) → toujours ERREUR en --strict" || ko "T24b gate affaibli (rc=$RC)"
rm -f "$AG"/*.md; rm -rf "$SK/planning-core"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
