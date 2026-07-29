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
#
# Lint des allowlists Agent(...)/Task(...) (Phase 16, ADR-044) :
#   T25 — allowlist reelle mixte (natif+tiers+cross-module) --strict → exit 0 (anti-faux-positif)
#   T26 — parenthese non fermee → exit 1 (classe syntaxe, non affectee par --strict)
#   T27 — Agent() vide → exit 1
#   T28 — outil hors set connu (Reed) : warning en defaut, ERREUR en --strict ; Read reste vert
#   T29 — Agent(vf-codeur) (typo) reste VERT meme en --strict (non-regression faux positif)
#   T30 — meme mutant sous --resolve-agents=strict + registre → exit 1 (preuve discriminance)
#   T31 — flow list [Read, Agent(x, y), Bash(git:*)] : 0 finding fantome
#   T32 — prefixe tiers (gsd-planner sans model/memory) → ignore ; --no-third-party-prefix → exit 1
#   T33 — Task(...) alias legacy → reste vert
#   T34 — Agent nu (sans allowlist) → warning "dispatch non cloisonne", non bloquant
#
# Correctifs post-revue (2 juges independants, re-entree mission Phase 16) :
#   T35 — champ tools: ENTIEREMENT quote ('tools: "Read, Agent(x)"') → conforme (defaut 1)
#   T36 — ligne vide dans une liste bloc tools: ne perd plus les puces suivantes (defaut 2)
#   T37 — parenthese EN TROP 'Agent(a))' → exit 1 (pinne split_depth seul, defaut 3)
#   T38 — entree vide au niveau token (virgule orpheline 'Read,,Agent(x)') → exit 1
#   T39 — entree vide DANS une allowlist 'Agent(a,,b)' → exit 1
#   T40 — espace avant la parenthese 'Agent (x)' → exit 1
#   T41 — token hors charset au niveau bare (sans parenthese) → exit 1
#   T42 — name invalide (majuscules/espaces) → exit 1
#   T43 — permissionMode invalide → exit 1
#   T44 — isolation invalide → exit 1
#   T45 — background invalide → exit 1
#   T46 — maxTurns invalide → exit 1
#   T47 — skills absent → warning non bloquant
#   T48 — description < 30c → warning non bloquant
#   T49 — tools absent → warning non bloquant (herite tout)
#   T50 — name different du nom de fichier → warning non bloquant
#
# Gate final (3 ecarts en-tete <-> comportement, re-entree Phase 16 exec-lint) :
#   T51 — --resolve-agents=<valeur invalide> → exit 1 explicite (plus un skip muet)
#   T52 — --third-party-prefix ACCUMULE au-dessus du defaut gsd- (ne l'ecrase plus)
#   T53 — compteurs distincts : fichiers agent tiers non lintes != entrees d'allowlist resolues
#   T54 — nit : 'Agent(a))' (parenthese en trop) → libelle distinct de 'non fermee'

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

# ---------- Phase 16 : lint des allowlists Agent(...)/Task(...) ----------

good_agent "vf-coder"
good_agent "vf-reviewer"

# T25 — allowlist reelle mixte (natif + tiers + cross-module) reste VERTE en --strict
cat > "$AG/vf-mixte.md" <<'EOF'
---
name: vf-mixte
description: Agent de test avec allowlist mixte native, tierce et cross-module, mission 16.
model: sonnet
memory: project
tools: Read, Write, Agent(vf-coder, vf-reviewer, general-purpose, gsd-planner)
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T25 allowlist reelle mixte --strict → exit 0" || ko "T25 (rc=$RC) : $(run_check --strict 2>&1 | tail -5)"
rm -f "$AG/vf-mixte.md"

# T26 — parenthese non fermee → exit 1 (classe syntaxe, jamais affectee par --strict)
cat > "$AG/nonferme.md" <<'EOF'
---
name: nonferme
description: Agent de test avec une allowlist Agent a parenthese non fermee.
model: sonnet
memory: project
tools: Read, Agent(vf-coder
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "parenthese non fermee"; then
  ok "T26 parenthese non fermee → exit 1 (citee dans le message)"
else
  ko "T26 (rc=$RC) : $OUT"
fi
rm -f "$AG/nonferme.md"

# T27 — Agent() vide → exit 1
cat > "$AG/vide.md" <<'EOF'
---
name: vide
description: Agent de test declarant une allowlist Agent totalement vide.
model: sonnet
memory: project
tools: Read, Agent()
---
corps
EOF
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T27 Agent() vide → exit 1" || ko "T27 (rc=$RC)"
rm -f "$AG/vide.md"

# T28 — outil hors set connu (Reed) : warning en defaut, ERREUR en --strict ; Read reste vert
cat > "$AG/reed.md" <<'EOF'
---
name: reed
description: Agent de test declarant l'outil Reed (typo) au lieu de Read.
model: sonnet
memory: project
tools: Reed, Agent(vf-coder)
---
corps
EOF
OUT_DEF="$(run_check 2>&1)"; RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
if [ "$RC_DEF" -eq 0 ] && echo "$OUT_DEF" | grep -qi "outil hors" && [ "$RC_STRICT" -eq 1 ]; then
  ok "T28 Reed : warning en defaut, ERREUR en --strict"
else
  ko "T28 (def=$RC_DEF strict=$RC_STRICT) : $OUT_DEF"
fi
rm -f "$AG/reed.md"
cat > "$AG/lu.md" <<'EOF'
---
name: lu
description: Agent de test avec l'outil Read correctement orthographie, non-regression.
model: sonnet
memory: project
tools: Read, Agent(vf-coder)
---
corps
EOF
RC_DEF=0; run_check >/dev/null 2>&1 || RC_DEF=$?
RC_STRICT=0; run_check --strict >/dev/null 2>&1 || RC_STRICT=$?
[ "$RC_DEF" -eq 0 ] && [ "$RC_STRICT" -eq 0 ] && ok "T28b Read (bien orthographie) reste vert (defaut+strict)" || ko "T28b (def=$RC_DEF strict=$RC_STRICT)"
rm -f "$AG/lu.md"

# T29 — Agent(vf-codeur) (typo de nom d'agent) reste VERT meme en --strict — non-regression
# faux positif : c'est le test le plus important de la serie (cf. digest de mission).
cat > "$AG/typo-nom.md" <<'EOF'
---
name: typo-nom
description: Agent de test declarant un nom d'agent mal orthographie dans son allowlist.
model: sonnet
memory: project
tools: Read, Agent(vf-codeur)
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -qi "nom d'agent non resolu"; then
  ok "T29 Agent(vf-codeur) (typo) reste VERT en --strict, avec warning"
else
  ko "T29 (rc=$RC) : $OUT"
fi

# T30 — le MEME mutant (vf-codeur) sous --resolve-agents=strict + registre → exit 1 ;
# vf-coder (nom correct, fichier present) reste vert sous la meme resolution stricte.
REG="$WORK/registry"; mkdir -p "$REG"
cp "$AG/vf-coder.md" "$REG/vf-coder.md"
RC=0; run_check --resolve-agents=strict --agent-registry-dir="$REG" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T30 vf-codeur (typo) sous --resolve-agents=strict → exit 1 (discriminance prouvee)" || ko "T30 (rc=$RC)"
rm -f "$AG/typo-nom.md"
cat > "$AG/nom-ok.md" <<'EOF'
---
name: nom-ok
description: Agent de test avec un nom d'agent correctement resolu via le registre.
model: sonnet
memory: project
tools: Read, Agent(vf-coder)
---
corps
EOF
RC=0; run_check --resolve-agents=strict --agent-registry-dir="$REG" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T30b vf-coder (resolu) reste vert sous --resolve-agents=strict" || ko "T30b (rc=$RC)"
rm -f "$AG/nom-ok.md"

# T31 — flow list YAML non dechiquetee : [Read, Agent(x, y), Bash(git:*)] → 0 finding fantome
cat > "$AG/flow.md" <<'EOF'
---
name: flow
description: Agent de test declarant son allowlist en flow list YAML entre crochets.
model: sonnet
memory: project
tools: [Read, Agent(x, y), Bash(git:*)]
---
corps
EOF
OUT="$(run_check --strict 2>&1)"; RC=$?
# Assertion forte (pas seulement l'absence d'un message precis) : avec un split naif (mutant
# teste manuellement), "Agent(x" et " y)" deviennent des tokens invalides (parenthese non
# fermee / token hors charset) -> exit 1 meme en mode defaut. Avec le tokenizer a profondeur
# de parentheses, exactement 3 tokens valides (Read, Agent(x,y), Bash(git:*)) -> --strict reste
# vert (x/y non resolus restent des WARNINGS, jamais des ERREURS sous --strict seul).
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -qE "hors charset|parenthese non fermee|hors du set connu 'Agent'"; then
  ok "T31 flow list [Read, Agent(x, y), Bash(git:*)] → --strict reste vert, aucun finding fantome"
else
  ko "T31 flow list dechiquetee (rc=$RC) : $OUT"
fi
rm -f "$AG/flow.md"

# T32 — prefixe tiers : un agent gsd-planner.md sans model/memory est ignore par defaut,
# et redevient linte (donc en erreur) des --no-third-party-prefix (solde CONCERNS.md:52-59).
cat > "$AG/gsd-planner.md" <<'EOF'
---
name: gsd-planner
description: Agent tiers GSD sans model ni memory, pour tester le skip par prefixe.
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "fichier(s) agent tiers non linte"; then
  ok "T32 gsd-planner (tiers, prefixe gsd- par defaut) → ignore, exit 0"
else
  ko "T32 (rc=$RC) : $OUT"
fi
RC=0; run_check --no-third-party-prefix >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T32b --no-third-party-prefix → gsd-planner linte normalement → exit 1" || ko "T32b (rc=$RC)"
rm -f "$AG/gsd-planner.md"

# T33 — Task(...) alias legacy (Claude Code v2.1.63) reste vert, traite comme Agent(...)
cat > "$AG/taskalias.md" <<'EOF'
---
name: taskalias
description: Agent de test utilisant l'alias legacy Task au lieu d'Agent dans tools.
model: sonnet
memory: project
tools: Read, Task(vf-coder)
---
corps
EOF
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T33 Task(vf-coder) (alias legacy) reste vert" || ko "T33 (rc=$RC) : $(run_check --strict 2>&1 | tail -5)"
rm -f "$AG/taskalias.md"

# T34 — Agent nu (sans allowlist parenthesee) → warning non bloquant "dispatch non cloisonne"
cat > "$AG/nu-agent.md" <<'EOF'
---
name: nu-agent
description: Agent de test declarant Agent sans aucune allowlist parenthesee.
model: sonnet
memory: project
tools: Read, Agent
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "dispatch non cloisonne"; then
  ok "T34 Agent nu → warning non bloquant"
else
  ko "T34 (rc=$RC) : $OUT"
fi
rm -f "$AG"/*.md

# ---------- Correctifs post-revue (re-entree Phase 16, 2 juges independants) ----------

good_agent "vf-coder"

# T35 — defaut 1 : champ tools: ENTIEREMENT quote (YAML valide) ne doit plus produire de
# faux BLOQUANT (charset / parenthese non fermee sur les guillemets eux-memes).
cat > "$AG/quote-tools.md" <<'EOF'
---
name: quote-tools
description: Agent de test avec un champ tools entierement quote entre guillemets.
model: sonnet
memory: project
tools: "Read, Write, Agent(vf-coder)"
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && ! echo "$OUT" | grep -qE "hors charset|parenthese non fermee"; then
  ok "T35 tools: entierement quote → conforme, aucun faux BLOQUANT (defaut 1)"
else
  ko "T35 (rc=$RC) : $OUT"
fi
rm -f "$AG/quote-tools.md"

# T36 — defaut 2 : ligne vide au milieu d'une liste bloc tools: ne doit plus faire perdre
# silencieusement les puces suivantes. Verifie via --resolve-agents=strict (discriminance
# forte : avant le correctif, exit 0 total silence ; apres, exit 1 sur l'entree recuperee).
cat > "$AG/blank-block.md" <<'EOF'
---
name: blank-block
description: Agent de test avec une ligne vide au milieu d'une liste bloc tools.
model: sonnet
memory: project
tools:
  - Read

  - Agent(vf-inexistant-improvise)
---
corps
EOF
OUT_DEF="$(run_check 2>&1)"; RC_DEF=$?
RC_STRICTRES=0; run_check --resolve-agents=strict >/dev/null 2>&1 || RC_STRICTRES=$?
if [ "$RC_DEF" -eq 0 ] && echo "$OUT_DEF" | grep -q "vf-inexistant-improvise" && [ "$RC_STRICTRES" -eq 1 ]; then
  ok "T36 ligne vide dans liste bloc → puce suivante recuperee (warning + erreur sous strict) (defaut 2)"
else
  ko "T36 (def=$RC_DEF strictres=$RC_STRICTRES) : $OUT_DEF"
fi
rm -f "$AG/blank-block.md"

# T37 — defaut 3 : parenthese EN TROP 'Agent(a))' → exit 1. Pinne SPECIFIQUEMENT split_depth
# (seul detecteur du depth < 0) : analyze_token ne catche pas ce cas (rest se termine bien
# par ')'), donc ce test tombe si on mute 'depth != 0' en 'depth > 0' dans split_depth.
cat > "$AG/extra-paren.md" <<'EOF'
---
name: extra-paren
description: Agent de test avec une parenthese fermante en trop dans une allowlist.
model: sonnet
memory: project
tools: Read, Agent(a))
---
corps
EOF
RC=0; run_check >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T37 parenthese en trop 'Agent(a))' → exit 1 (pinne split_depth, defaut 3)" || ko "T37 (rc=$RC)"
rm -f "$AG/extra-paren.md"

# T38 — entree vide au niveau token (virgule orpheline) → exit 1
cat > "$AG/orpheline.md" <<'EOF'
---
name: orpheline
description: Agent de test avec une virgule orpheline produisant une entree vide.
model: sonnet
memory: project
tools: Read,,Agent(x)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "entree d'allowlist vide"; then
  ok "T38 virgule orpheline 'Read,,Agent(x)' → exit 1"
else
  ko "T38 (rc=$RC) : $OUT"
fi
rm -f "$AG/orpheline.md"

# T39 — entree vide A L'INTERIEUR d'une allowlist → exit 1
cat > "$AG/interne-vide.md" <<'EOF'
---
name: interne-vide
description: Agent de test avec une entree vide a l'interieur d'une allowlist Agent.
model: sonnet
memory: project
tools: Agent(a,,b)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "entree vide dans l'allowlist"; then
  ok "T39 'Agent(a,,b)' (entree vide interne) → exit 1"
else
  ko "T39 (rc=$RC) : $OUT"
fi
rm -f "$AG/interne-vide.md"

# T40 — espace avant la parenthese → exit 1
cat > "$AG/espace-paren.md" <<'EOF'
---
name: espace-paren
description: Agent de test avec un espace entre le nom de l'outil et la parenthese.
model: sonnet
memory: project
tools: Read, Agent (vf-coder)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "espace avant la parenthese"; then
  ok "T40 'Agent (vf-coder)' (espace avant parenthese) → exit 1"
else
  ko "T40 (rc=$RC) : $OUT"
fi
rm -f "$AG/espace-paren.md"

# T41 — token hors charset au niveau bare (sans parenthese, ex. symbole non autorise)
cat > "$AG/bare-charset.md" <<'EOF'
---
name: bare-charset
description: Agent de test avec un token bare contenant un caractere hors charset.
model: sonnet
memory: project
tools: Read, Bash@2
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "token hors charset"; then
  ok "T41 token bare hors charset ('Bash@2') → exit 1"
else
  ko "T41 (rc=$RC) : $OUT"
fi
rm -f "$AG/bare-charset.md"

# T42 — name invalide (majuscules/espaces, hors [a-z0-9-])
cat > "$AG/nom-invalide.md" <<'EOF'
---
name: "Nom Invalide"
description: Agent de test dont le name contient des majuscules et un espace.
model: sonnet
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "name invalide"; then
  ok "T42 name invalide (majuscules/espaces) → exit 1"
else
  ko "T42 (rc=$RC) : $OUT"
fi
rm -f "$AG/nom-invalide.md"

# T43 — permissionMode invalide
cat > "$AG/permmode.md" <<'EOF'
---
name: permmode
description: Agent de test avec un permissionMode qui n'existe pas dans l'enum attendu.
model: sonnet
memory: project
permissionMode: yolo
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "permissionMode invalide"; then
  ok "T43 permissionMode invalide → exit 1"
else
  ko "T43 (rc=$RC) : $OUT"
fi
rm -f "$AG/permmode.md"

# T44 — isolation invalide (seul 'worktree' est admis)
cat > "$AG/isol.md" <<'EOF'
---
name: isol
description: Agent de test avec une valeur isolation qui n'est pas worktree.
model: sonnet
memory: project
isolation: sandbox
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "isolation invalide"; then
  ok "T44 isolation invalide → exit 1"
else
  ko "T44 (rc=$RC) : $OUT"
fi
rm -f "$AG/isol.md"

# T45 — background invalide (attendu true|false)
cat > "$AG/bg.md" <<'EOF'
---
name: bg
description: Agent de test avec un champ background qui n'est ni true ni false.
model: sonnet
memory: project
background: maybe
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "background invalide"; then
  ok "T45 background invalide → exit 1"
else
  ko "T45 (rc=$RC) : $OUT"
fi
rm -f "$AG/bg.md"

# T46 — maxTurns invalide (attendu un entier)
cat > "$AG/maxt.md" <<'EOF'
---
name: maxt
description: Agent de test avec un champ maxTurns qui n'est pas un entier valide.
model: sonnet
memory: project
maxTurns: beaucoup
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "maxTurns invalide"; then
  ok "T46 maxTurns invalide → exit 1"
else
  ko "T46 (rc=$RC) : $OUT"
fi
rm -f "$AG/maxt.md"

# T47 — skills absent → warning non bloquant (pas d'ERREUR meme en --strict, hors resolution)
cat > "$AG/sans-skill.md" <<'EOF'
---
name: sans-skill
description: Agent de test sans aucun champ skills declare, pour verifier le warning.
model: sonnet
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "aucun skill cable"; then
  ok "T47 skills absent → warning non bloquant"
else
  ko "T47 (rc=$RC) : $OUT"
fi
rm -f "$AG/sans-skill.md"

# T48 — description < 30 caracteres → warning non bloquant
cat > "$AG/desc-courte.md" <<'EOF'
---
name: desc-courte
description: trop court
model: sonnet
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "description trop courte"; then
  ok "T48 description < 30c → warning non bloquant"
else
  ko "T48 (rc=$RC) : $OUT"
fi
rm -f "$AG/desc-courte.md"

# T49 — tools absent → warning non bloquant (herite tout)
cat > "$AG/sans-tools.md" <<'EOF'
---
name: sans-tools
description: Agent de test sans champ tools declare, pour verifier le warning d'heritage.
model: sonnet
memory: project
skills:
  - petit-skill
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "tools absent"; then
  ok "T49 tools absent → warning non bloquant (herite tout)"
else
  ko "T49 (rc=$RC) : $OUT"
fi
rm -f "$AG/sans-tools.md"

# T50 — name different du nom de fichier → warning non bloquant
cat > "$AG/autre-fichier.md" <<'EOF'
---
name: nom-different
description: Agent de test dont le name ne correspond pas au nom du fichier sur disque.
model: sonnet
memory: project
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "different du nom de fichier"; then
  ok "T50 name ≠ nom de fichier → warning non bloquant"
else
  ko "T50 (rc=$RC) : $OUT"
fi
rm -f "$AG/autre-fichier.md" "$AG/vf-coder.md"

# ---------- Gate final (3 ecarts en-tete <-> comportement, re-entree Phase 16 exec-lint) ----------

# T51 — --resolve-agents=<valeur invalide> (typo type 'stricts') → exit 1 explicite. Avant le
# correctif, le code ne testait que '== "strict"' : toute autre valeur (y compris une typo CI)
# degradait SILENCIEUSEMENT en lenient, exit 0, aucun message — exactement le faux vert F13
# que ce script interdit deja pour la cible vide. Discriminance : ce test tombe (exit 0, pas
# de message) si on mute la validation en retirant le case lenient|strict.
RC=0; OUT="$(run_check --resolve-agents=stricts 2>&1)" || RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "resolve-agents invalide"; then
  ok "T51 --resolve-agents=stricts (typo) → exit 1 explicite (plus un skip muet)"
else
  ko "T51 (rc=$RC) : $OUT"
fi

# T52 — --third-party-prefix ACCUMULE au-dessus du defaut gsd- (ne l'ecrase plus). Avant le
# correctif, la premiere occurrence videait THIRD_PARTY_PREFIXES avant d'ajouter la valeur
# custom : gsd-planner.md redevenait linte (donc en erreur) des qu'un seul --third-party-prefix
# etait fourni, meme sans --no-third-party-prefix. Discriminance : ce test tombe (rc=1, ou
# 'prefixe(s) : acme-' sans 'gsd-') si on remet l'ecrasement au premier flag custom.
cat > "$AG/gsd-planner.md" <<'EOF'
---
name: gsd-planner
description: Agent tiers GSD sans model ni memory, pour tester l'accumulation de prefixe.
---
corps
EOF
RC=0; OUT="$(run_check --third-party-prefix=acme- 2>&1)" || RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "prefixe(s) : gsd-,acme-"; then
  ok "T52 --third-party-prefix=acme- ACCUMULE sur le defaut gsd- (gsd-planner toujours ignore)"
else
  ko "T52 (rc=$RC) : $OUT"
fi
rm -f "$AG/gsd-planner.md"

# T53 — compteurs DISTINCTS : fichiers agent tiers non lintes != entrees d'allowlist tierces
# resolues. Avant le correctif, un seul compteur amalgamait les deux populations sous le
# libelle trompeur 'N agent(s) tiers ignore(s)' (33 sur dev-orchestrator alors que 0 fichier
# gsd-*.md n'existait sur disque). Ici : 2 fichiers tiers + 1 entree d'allowlist tierce (jamais
# materialisee en fichier) doivent produire deux chiffres differents et correctement libelles.
cat > "$AG/gsd-other.md" <<'EOF'
---
name: gsd-other
description: Premier agent tiers GSD, pour peupler le compteur de fichiers non lintes.
---
corps
EOF
cat > "$AG/gsd-other2.md" <<'EOF'
---
name: gsd-other2
description: Second agent tiers GSD, pour peupler le compteur de fichiers non lintes.
---
corps
EOF
cat > "$AG/vf-mixte2.md" <<'EOF'
---
name: vf-mixte2
description: Agent de test dont l'allowlist reference un agent tiers jamais materialise sur disque.
model: sonnet
memory: project
tools: Read, Agent(gsd-jamais-cree)
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q "2 fichier(s) agent tiers non linte(s) · 1 entree(s) d'allowlist tierce(s) resolue(s)"; then
  ok "T53 compteurs distincts : 2 fichier(s) agent tiers != 1 entree(s) d'allowlist tierce(s)"
else
  ko "T53 (rc=$RC) : $OUT"
fi
rm -f "$AG/gsd-other.md" "$AG/gsd-other2.md" "$AG/vf-mixte2.md"

# T54 (nit) — 'Agent(a))' (parenthese fermante EN TROP, pas manquante) ne doit plus etre
# libelle 'non fermee' (message pointant vers l'oppose du vrai probleme). Discriminance :
# ce test tombe si on refusionne les deux branches de signe en un seul message 'non fermee'.
cat > "$AG/extra-mot.md" <<'EOF'
---
name: extra-mot
description: Agent de test pour verifier le libelle exact de la parenthese en trop.
model: sonnet
memory: project
tools: Read, Agent(a))
---
corps
EOF
OUT="$(run_check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q "fermante en trop" && ! echo "$OUT" | grep -q "parenthese non fermee"; then
  ok "T54 'Agent(a))' → libelle 'fermante en trop' distinct de 'non fermee' (nit)"
else
  ko "T54 (rc=$RC) : $OUT"
fi
rm -f "$AG/extra-mot.md"

# ---------- Chemin par DEFAUT des gates (D-24) — jamais exerce jusqu'ici ----------
# Aucun des 54 cas precedents n'invoque check-agents.sh SANS --agents-dir/--skills-dir : le helper
# d'invocation partage par tous les cas ci-dessus les injecte systematiquement en dur. C'est ce
# point aveugle qui a laisse un defaut de perimetre (AGENTS_DIR/SKILLS_DIR resolus depuis le cwd du
# hook, jamais celui du plugin) survivre a toute la Phase 16. Les 3 cas suivants invoquent
# bash "$CHECK" DIRECTEMENT, dans un sous-shell deplace vers un repertoire factice mktemp -d, sans
# jamais toucher au cwd de la suite elle-meme. Mutation tuee : alterer la valeur par defaut
# AGENTS_DIR (ou SKILLS_DIR) dans check-agents.sh fait echouer T57 — la sonde qui manquait
# (T55/T56 passeraient encore avec un defaut casse, T57 seul le prouve).

PWD_BEFORE="$(pwd)"

# T55 — cible absente, mode strict : exit 3 INDETERMINE, jamais un vert (contrat F13 / D-24)
DEFAULT_EMPTY="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY" && bash "$CHECK" --strict 2>&1)"; RC=$?
if [ "$RC" -eq 3 ] && echo "$OUT" | grep -q "INDETERMINE"; then
  ok "T55 chemin par defaut, cible absente, --strict → exit 3 INDÉTERMINÉ, jamais un vert (D-24)"
else
  ko "T55 (rc=$RC) : $OUT"
fi
rm -rf "$DEFAULT_EMPTY"

# T56 — cible absente, mode hook : exit 0, silence TOTAL (pin de l'exemption volontaire sur
# cible vide — une suppression inconditionnelle future de cette exemption ferait echouer ce cas)
DEFAULT_EMPTY2="$(mktemp -d)"
OUT="$(cd "$DEFAULT_EMPTY2" && bash "$CHECK" --hook 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T56 chemin par defaut, cible absente, --hook → exit 0, silence total (exemption pinnee)"
else
  ko "T56 (rc=$RC) : '$OUT'"
fi
rm -rf "$DEFAULT_EMPTY2"

# T57 — cible PRESENTE au chemin par defaut, cas DISCRIMINANT : seul ce cas prouve que la valeur
# par defaut resout une cible reelle — T55/T56 passeraient encore avec un defaut casse (pointant
# vers un repertoire qui n'existera jamais).
DEFAULT_PRESENT="$(mktemp -d)"
mkdir -p "$DEFAULT_PRESENT/.claude/agents"
printf 'Aucun frontmatter ici -- non conforme.\n' > "$DEFAULT_PRESENT/.claude/agents/casse.md"
RC=0; (cd "$DEFAULT_PRESENT" && bash "$CHECK") >/dev/null 2>&1 || RC=$?
if [ "$RC" -eq 1 ]; then
  ok "T57 chemin par defaut, cible presente non conforme, SANS flag → exit 1 (le defaut resout une cible reelle)"
else
  ko "T57 (rc=$RC) — le defaut AGENTS_DIR ne resout pas la cible reelle"
fi
rm -rf "$DEFAULT_PRESENT"

# T58 — le cwd de la suite est inchange : les 3 deplacements ci-dessus sont confines a des sous-shells
[ "$(pwd)" = "$PWD_BEFORE" ] && ok "T58 cwd de la suite inchange apres les cas chemin par defaut" || ko "T58 cwd altere : $(pwd) != $PWD_BEFORE"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
