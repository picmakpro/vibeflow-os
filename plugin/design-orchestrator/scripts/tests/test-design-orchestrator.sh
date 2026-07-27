#!/usr/bin/env bash
# test-design-orchestrator.sh — Suite de vérification du module design-orchestrator (VFDO-design)
#
# Couvre l'équipe de mission design (v1.2.0 — première instanciation non-dev du team-kernel,
# conductor-references/team-kernel.md) + les acquis du module :
#   T1  — Les 3 agents d'équipe existent (vf-design-manager, vf-crafter, vf-design-judge),
#         frontmatter complet (description, model, memory) et densité ADR-029 (≤250L chacun).
#   T1b — Souveraineté modèle : manager = opus ; crafter et juge = sonnet.
#   T2  — vf-internal (Pattern 12) : présent sur crafter + juge, ABSENT du manager (exposé).
#   T3  — check-agents.sh --strict (ADR-044) vert sur agents/ du module (SKIP si le contrôleur
#         du conductor est introuvable dans la disposition courante).
#   T4  — Cloisonnement par tools (Pattern 12) : le juge SANS Write/Edit/Agent (il ne corrige
#         jamais) ; le crafter SANS Agent/Task (il ne dispatche personne) ; le manager AVEC
#         Agent (il dispatche la frontière).
#   T5  — Câblage team-kernel dans le manager : driver-lock.sh + dag.sh (résolution $S),
#         digest ≤30 lignes, rapports typés, seuil 70 et 3 tours max (anti-thrash), release
#         du lock à la clôture.
#   T5b — Rubric du juge : barème /100 explicite (conformité DA /40 + 6 dimensions /10),
#         verdict passed/gaps_found, seuil 70 par défaut.
#   T6  — Heuristique de proposition dans AGENT.md : signal mission design → PROPOSER
#         Task(vf-design-manager) (jamais d'office).
#   T7  — Densité du module (VERIF-02, wc -l uniquement) : AGENT.md ≤250L, skills ≤500L.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe (SKIP non
# bloquant), exit 1 si au moins un KO. Calqué sur test-dev-orchestrator.sh (pattern du repo).
#
# Référence : ADR-029, ADR-044, ADR-053, team-kernel.md (tableau Implémentations, ligne Design).

set -uo pipefail

# Résolution du module (racine = dossier parent de scripts/tests/).
MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

# Détection de la disposition : source (design-orchestrator/) vs lab installé (.claude/).
if [ -f "$MOD/AGENT.md" ]; then
  AGENT_FILE="$MOD/AGENT.md"
elif [ -f "$MOD/agents/design-orchestrator.md" ]; then
  AGENT_FILE="$MOD/agents/design-orchestrator.md"
else
  echo "  ✗ Impossible de localiser l'agent (ni source AGENT.md, ni lab agents/design-orchestrator.md)"; exit 1
fi

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

TEAM_AGENTS="vf-design-manager vf-crafter vf-design-judge"
WORKERS="vf-crafter vf-design-judge"
MANAGER="$MOD/agents/vf-design-manager.md"
CRAFTER="$MOD/agents/vf-crafter.md"
JUDGE="$MOD/agents/vf-design-judge.md"

# Extrait la ligne tools: du frontmatter d'un agent.
tools_line() { "$GREP" -m1 '^tools:' "$1" 2>/dev/null; }

echo "== test-design-orchestrator (module: $MOD) =="

# ---------------------------------------------------------------------------
# T1 — 3 agents présents, frontmatter complet, densité ≤250L (ADR-029/044)
# ---------------------------------------------------------------------------
t1_ok=1
for a in $TEAM_AGENTS; do
  f="$MOD/agents/$a.md"
  if [ ! -f "$f" ]; then ko "T1 agents : $a.md introuvable dans $MOD/agents/"; t1_ok=0; continue; fi
  for field in description model memory; do
    "$GREP" -q "^${field}:" "$f" || { ko "T1 agents : $a.md sans champ $field"; t1_ok=0; }
  done
  a_lines=$(wc -l < "$f" | tr -d ' ')
  [ "${a_lines:-999}" -le 250 ] || { ko "T1 agents : $a.md dépasse 250 lignes ($a_lines)"; t1_ok=0; }
done
[ "$t1_ok" -eq 1 ] && ok "T1 agents : 3 agents de l'équipe présents, frontmatter complet, ≤250L"

# T1b — souveraineté modèle : manager opus, workers sonnet
t1b_ok=1
"$GREP" -q '^model: opus' "$MANAGER" 2>/dev/null || { ko "T1b modèle : vf-design-manager doit être opus"; t1b_ok=0; }
for w in $WORKERS; do
  "$GREP" -q '^model: sonnet' "$MOD/agents/$w.md" 2>/dev/null || { ko "T1b modèle : $w doit être sonnet"; t1b_ok=0; }
done
[ "$t1b_ok" -eq 1 ] && ok "T1b modèle : manager=opus, crafter/juge=sonnet"

# ---------------------------------------------------------------------------
# T2 — vf-internal (Pattern 12) : workers marqués, manager exposé
# ---------------------------------------------------------------------------
t2_ok=1
for w in $WORKERS; do
  "$GREP" -q '^vf-internal: true' "$MOD/agents/$w.md" 2>/dev/null || { ko "T2 vf-internal manquant : $w"; t2_ok=0; }
done
if "$GREP" -q '^vf-internal:' "$MANAGER" 2>/dev/null; then
  ko "T2 : vf-design-manager déclaré vf-internal (doit rester exposé)"; t2_ok=0
fi
[ "$t2_ok" -eq 1 ] && ok "T2 vf-internal : crafter + juge internes, manager exposé"

# ---------------------------------------------------------------------------
# T3 — check-agents.sh --strict (ADR-044) : contrôleur machine du conductor
# ---------------------------------------------------------------------------
CHECK_AGENTS=""
for cand in "$REPO/conductor/scripts/check-agents.sh" "$MOD/scripts/check-agents.sh" "$HOME/.claude/scripts/check-agents.sh"; do
  [ -f "$cand" ] && { CHECK_AGENTS="$cand"; break; }
done
if [ -z "$CHECK_AGENTS" ]; then
  skip "T3 check-agents : contrôleur introuvable (conductor non présent dans cette disposition)"
elif [ ! -f "$MANAGER" ]; then
  skip "T3 check-agents : agents/ du module introuvables"
else
  if bash "$CHECK_AGENTS" --strict --agents-dir="$MOD/agents" >/dev/null 2>&1; then
    ok "T3 check-agents : --strict vert sur les agents d'équipe (ADR-044)"
  else
    ko "T3 check-agents : --strict en échec sur $MOD/agents"
  fi
fi

# ---------------------------------------------------------------------------
# T4 — Cloisonnement par tools (Pattern 12)
# ---------------------------------------------------------------------------
t4_ok=1
jt="$(tools_line "$JUDGE")"
if [ -z "$jt" ]; then
  ko "T4 cloisonnement : vf-design-judge sans ligne tools: (hériterait de TOUT — Write inclus)"; t4_ok=0
else
  echo "$jt" | "$GREP" -qE '(Write|Edit)' && { ko "T4 cloisonnement : le juge a Write/Edit (il ne doit JAMAIS corriger)"; t4_ok=0; }
  echo "$jt" | "$GREP" -qE '(Agent|Task)' && { ko "T4 cloisonnement : le juge a Agent/Task (il ne dispatche personne)"; t4_ok=0; }
fi
ct="$(tools_line "$CRAFTER")"
if [ -z "$ct" ]; then
  ko "T4 cloisonnement : vf-crafter sans ligne tools: (hériterait de Task)"; t4_ok=0
else
  echo "$ct" | "$GREP" -qE '(Agent|Task)' && { ko "T4 cloisonnement : le crafter a Agent/Task (worker sans dispatch)"; t4_ok=0; }
  echo "$ct" | "$GREP" -qE 'Write' || { ko "T4 cloisonnement : le crafter sans Write (il doit produire)"; t4_ok=0; }
fi
mt="$(tools_line "$MANAGER")"
# Durci Phase 15 (D-07) : un simple "Agent" nu passait ce test avant l'allowlist — désormais on
# exige l'allowlist Agent( ) elle-même (le contenu est vérifié en détail par T8 ci-dessous).
echo "$mt" | "$GREP" -qF 'Agent(' || { ko "T4 cloisonnement : le manager sans allowlist Agent( ) (il doit dispatcher la frontière, scopée)"; t4_ok=0; }
[ "$t4_ok" -eq 1 ] && ok "T4 cloisonnement : juge sans Write/Edit/Task, crafter sans Task, manager avec allowlist Agent( )"

# ---------------------------------------------------------------------------
# T5 — Câblage team-kernel dans le manager (lock + DAG + digest + vert design)
# ---------------------------------------------------------------------------
t5_ok=1
for needle in "driver-lock.sh" "dag.sh" "team-kernel" "digest" "release"; do
  "$GREP" -qi -- "$needle" "$MANAGER" || { ko "T5 kernel : « $needle » absent du manager"; t5_ok=0; }
done
# Résolution $S scope-robuste (jamais présumer ./.claude) — même mécanisme que mission-flow.
"$GREP" -q 'Résolution' "$MANAGER" || { ko "T5 kernel : résolution \$S (mission-flow §Résolution) non citée"; t5_ok=0; }
# Le « vert » design : seuil 70 + 3 tours max (anti-thrash).
"$GREP" -q '70/100' "$MANAGER" || { ko "T5 vert design : seuil par défaut 70/100 absent du manager"; t5_ok=0; }
"$GREP" -qE '3 tours' "$MANAGER" || { ko "T5 vert design : limite 3 tours craft→re-critique absente"; t5_ok=0; }
# Rapports typés (Pattern C) : statuts pilotables.
"$GREP" -q 'gaps_found' "$MANAGER" || { ko "T5 kernel : contrôle de flux typé (gaps_found) absent"; t5_ok=0; }
# Le manager ne produit jamais : l'interdiction doit être écrite.
"$GREP" -qi 'JAMAIS de design' "$MANAGER" || { ko "T5 kernel : interdiction de produire absente du manager"; t5_ok=0; }
[ "$t5_ok" -eq 1 ] && ok "T5 kernel : lock + DAG + \$S + digest + seuil 70 + 3 tours + rapports typés câblés"

# T5b — Rubric du juge : /100 explicite, DA /40 + 6 dimensions, verdict typé
t5b_ok=1
"$GREP" -q '/40' "$JUDGE" || { ko "T5b rubric : conformité DA /40 absente du juge"; t5b_ok=0; }
"$GREP" -q '6 dimensions' "$JUDGE" || { ko "T5b rubric : les 6 dimensions qualité absentes du juge"; t5b_ok=0; }
for dim in Copy Hiérarchie Couleur Typographie Spacing Accessibilité; do
  "$GREP" -q "$dim" "$JUDGE" || { ko "T5b rubric : dimension « $dim » absente"; t5b_ok=0; }
done
"$GREP" -q '70/100' "$JUDGE" || { ko "T5b rubric : seuil par défaut 70/100 absent"; t5b_ok=0; }
"$GREP" -q 'gaps_found' "$JUDGE" || { ko "T5b rubric : verdict typé gaps_found absent"; t5b_ok=0; }
"$GREP" -qi 'ne corrige' "$JUDGE" || { ko "T5b rubric : « ne corrige jamais » absent du juge"; t5b_ok=0; }
[ "$t5b_ok" -eq 1 ] && ok "T5b rubric : /100 (DA /40 + 6 dimensions /10), seuil 70, verdict typé, juge non-correcteur"

# ---------------------------------------------------------------------------
# T6 — Heuristique de proposition (AGENT.md) : signal mission → équipe
# ---------------------------------------------------------------------------
t6_ok=1
"$GREP" -q 'vf-design-manager' "$AGENT_FILE" || { ko "T6 routage : AGENT.md ne mentionne pas vf-design-manager"; t6_ok=0; }
"$GREP" -qiE 'mission design' "$AGENT_FILE" || { ko "T6 routage : signal « mission design » absent d'AGENT.md"; t6_ok=0; }
"$GREP" -qiE 'PROPOSE' "$AGENT_FILE" || { ko "T6 routage : la proposition (jamais d'office) absente d'AGENT.md"; t6_ok=0; }
[ "$t6_ok" -eq 1 ] && ok "T6 routage : heuristique mission design → PROPOSER Task(vf-design-manager) présente"

# ---------------------------------------------------------------------------
# T7 — Densité du module (VERIF-02, wc -l uniquement)
# ---------------------------------------------------------------------------
agent_lines=$(wc -l < "$AGENT_FILE" | tr -d ' ')
if [ "$agent_lines" -le 250 ]; then
  ok "T7 densité agent : AGENT.md = ${agent_lines}L (≤250)"
else
  ko "T7 densité agent : AGENT.md = ${agent_lines}L (>250)"
fi
skills_over=0; skills_total=0
for sk in vf-design vf-sketch; do
  f="$MOD/skills/$sk/SKILL.md"
  [ -f "$f" ] || continue
  skills_total=$((skills_total+1))
  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -gt 500 ]; then
    ko "T7 densité skill : $sk/SKILL.md = ${n}L (>500)"
    skills_over=$((skills_over+1))
  fi
done
if [ "$skills_over" -eq 0 ] && [ "$skills_total" -ge 1 ]; then
  ok "T7 densité skills : $skills_total skill(s) du module tous ≤500L"
elif [ "$skills_total" -eq 0 ]; then
  skip "T7 densité skills : aucun skill du module trouvé dans cette disposition"
fi

# ---------------------------------------------------------------------------
# T8 — Cloisonnement par tools (Pattern 12) : allowlist Agent(...) du manager (Phase 15, D-07)
# ---------------------------------------------------------------------------
# check-agents.sh NE LINTE PAS le contenu du champ tools: (vérifié empiriquement — une allowlist
# avec des noms inventés ou une parenthèse non fermée passe --strict en vert). Ces asserts sont
# donc la SEULE vérification machine du cloisonnement D-07 (Pattern A : imbrication
# manager→manager interdite) pour ce module.
T8_ALLOWED="vf-crafter vf-design-judge vf-coder vf-reviewer general-purpose gsd-phase-researcher"
t8_ok=1
dmt="$(tools_line "$MANAGER")"
if [ -z "$dmt" ]; then
  ko "T8 cloisonnement : vf-design-manager sans ligne tools: (hériterait de TOUT)"; t8_ok=0
else
  # Allowlist Agent(...) et non Agent nu.
  bare="$(echo "$dmt" | "$GREP" -oE 'Agent([^(]|$)')"
  [ -z "$bare" ] || { ko "T8 cloisonnement : vf-design-manager a un Agent nu (pas d'allowlist)"; t8_ok=0; }
  echo "$dmt" | "$GREP" -qF 'Agent(' || { ko "T8 cloisonnement : aucune allowlist Agent( ) trouvée"; t8_ok=0; }
  # Chacun des 6 noms attendus, testé UN PAR UN (jamais un grep global satisfait par le premier).
  for name in $T8_ALLOWED; do
    echo "$dmt" | "$GREP" -qF -- "$name" || { ko "T8 cloisonnement : « $name » absent de l'allowlist du manager design"; t8_ok=0; }
  done
  # Interdit structurel : vf-dev-manager JAMAIS dans l'allowlist (imbrication manager→manager).
  echo "$dmt" | "$GREP" -qF -- "vf-dev-manager" && { ko "T8 cloisonnement : vf-dev-manager présent dans l'allowlist (imbrication manager→manager)"; t8_ok=0; }
  # Parenthèse d'allowlist fermée en fin de ligne.
  echo "$dmt" | "$GREP" -qE '\)[[:space:]]*$' || { ko "T8 cloisonnement : allowlist non fermée (parenthèse manquante en fin de ligne)"; t8_ok=0; }
fi
[ "$t8_ok" -eq 1 ] && ok "T8 cloisonnement : allowlist Agent(...) complète (6 noms), vf-dev-manager absent, parenthèse fermée"

# T8b — Success Criterion 2 : doctrine étage implémentation croisée (opt-in, double juge, 3+3)
t8b_ok=1
"$GREP" -qi 'Étage implémentation croisée' "$MANAGER" || { ko "T8b SC2 : doctrine étage implémentation absente de vf-design-manager.md"; t8b_ok=0; }
"$GREP" -q 'specs+implementation' "$MANAGER" || { ko "T8b SC2 : opt-in livrable specs+implementation absent"; t8b_ok=0; }
"$GREP" -qi 'double juge' "$MANAGER" || { ko "T8b SC2 : double juge parallèle absent"; t8b_ok=0; }
"$GREP" -q '3+3' "$MANAGER" || { ko "T8b SC2 : budgets 3+3 absents"; t8b_ok=0; }
[ "$t8b_ok" -eq 1 ] && ok "T8b doctrine : étage implémentation croisée (SC2 — opt-in, double juge, budgets 3+3) présente"

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
