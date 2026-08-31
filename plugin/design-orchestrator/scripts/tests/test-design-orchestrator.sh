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
#   T8  — Cloisonnement par tools : allowlist Agent(...) du manager (6 noms), vf-dev-manager absent.
#   T8b — SC2 : doctrine étage implémentation croisée (opt-in, double juge, budgets 3+3).
#
# ensure-design-deps.sh (quick 260810-fh3, D-01..D-04) : présence ET activation de la chaîne
# design, câblage double engine + agent —
#   T9  — Idempotence : deux runs dry-run consécutifs, exit 0 aux deux, sorties identiques.
#   T9b — Scope : dry-run forcé VF_SCOPE=project → commandes scopées ; VF_SCOPE=bogus → exit 1.
#   T9c — LE CAS DE LA TÂCHE (D-02) : un `claude` stub JSON discrimine le plugin dont AU MOINS
#         une entrée du même nom est active (satisfait, aucun geste) du plugin dont la SEULE
#         entrée est inactive (`enable` scopé émis, jamais un `install` nu).
#   T9d — Dégradation : CLI `claude` absente → exit 0, les 4 étapes manuelles affichées.
#   T9e — Autonomie (D-04) : aucune dépendance d'exécution vers un autre module, `module.json`
#         déclare toujours exactement `conductor`.
#   T9f — Câblage double : hook nommé (double garde -f, branche else best-effort) dans
#         `vibeflow-update.sh` ; section Premier contact + garde-fou non-restitution dans AGENT.md.
#   T9g — NON-SILENCE (le défaut d'origine, une couche plus haut) : `--quiet` est muet quand les 4
#         plugins sont actifs, mais laisse TOUJOURS passer les anomalies ; et le hook de l'engine
#         appelle bien `--quiet` SANS rediriger stderr — sinon les étapes manuelles disparaissent
#         et l'install redevient silencieuse, exactement ce que cette tâche ferme.
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
# T9..T9f — ensure-design-deps.sh (quick 260810-fh3, D-01..D-04)
# ---------------------------------------------------------------------------
EDD="$MOD/scripts/ensure-design-deps.sh"
if [ ! -f "$EDD" ]; then
  skip "T9..T9f : ensure-design-deps.sh introuvable dans $MOD/scripts/"
else
  # T9 — IDEMPOTENCE : deux runs dry-run consécutifs, exit 0 aux deux, sorties identiques.
  T9_OUT1="$(mktemp)"; T9_OUT2="$(mktemp)"
  VF_DESIGN_ENSURE_DRY_RUN=1 bash "$EDD" >/dev/null 2>"$T9_OUT1"; t9_r1=$?
  VF_DESIGN_ENSURE_DRY_RUN=1 bash "$EDD" >/dev/null 2>"$T9_OUT2"; t9_r2=$?
  if [ "$t9_r1" -eq 0 ] && [ "$t9_r2" -eq 0 ] && diff -q "$T9_OUT1" "$T9_OUT2" >/dev/null 2>&1; then
    ok "T9 idempotence : deux runs dry-run identiques, exit 0/0, no-op stable"
  else
    ko "T9 idempotence : run1=$t9_r1 run2=$t9_r2, sorties identiques=$(diff -q "$T9_OUT1" "$T9_OUT2" >/dev/null 2>&1 && echo oui || echo non)"
  fi
  rm -f "$T9_OUT1" "$T9_OUT2"

  # ---------------------------------------------------------------------------
  # T9b — SCOPE : dry-run forcé VF_SCOPE=project → chaque commande porte --scope project ;
  # VF_SCOPE=bogus → exit 1 avec message de validation. Deux assertions distinctes (jamais un
  # `&&` qu'un seul côté satisferait).
  # ---------------------------------------------------------------------------
  # Stub `claude` OBLIGATOIRE ici : sans lui, le script part en état « indéterminé » (aucune source
  # de vérification) et n'émet AUCUNE commande — le test passait sur un poste de dev équipé et
  # échouait sur un runner CI nu, en mesurant la machine plutôt que le script. Le stub n'a pas
  # besoin de fixture : FORCE bascule de toute façon les 4 plugins sur la branche « absent ».
  T9B_BIN="$(mktemp -d)"
  cat >"$T9B_BIN/claude" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "plugin" ] && [ "$2" = "list" ] && [ "$3" = "--json" ]; then
  echo '[]'
  exit 0
fi
exit 0
SH
  chmod +x "$T9B_BIN/claude"
  T9B_OUT="$(PATH="$T9B_BIN:$PATH" VF_DESIGN_ENSURE_DRY_RUN=1 VF_DESIGN_ENSURE_FORCE=1 VF_SCOPE=project bash "$EDD" 2>&1)"
  rm -rf "$T9B_BIN"
  t9b_cmd_n=$(echo "$T9B_OUT" | "$GREP" -c '^\[ensure-design-deps\] (dry-run)')
  t9b_scoped_n=$(echo "$T9B_OUT" | "$GREP" -c -- '^\[ensure-design-deps\] (dry-run).*--scope project')
  if [ "$t9b_cmd_n" -ge 4 ] && [ "$t9b_cmd_n" = "$t9b_scoped_n" ]; then
    ok "T9b scope : $t9b_cmd_n commandes loguées, toutes porteuses de --scope project"
  else
    ko "T9b scope : $t9b_cmd_n commandes loguées dont seulement $t9b_scoped_n scopées --scope project"
  fi
  VF_DESIGN_ENSURE_DRY_RUN=1 VF_SCOPE=bogus bash "$EDD" >"$T9_OUT1" 2>&1; t9b_bogus_rc=$?
  if [ "$t9b_bogus_rc" -eq 1 ] && "$GREP" -qi 'VF_SCOPE invalide' "$T9_OUT1"; then
    ok "T9b validation : VF_SCOPE=bogus rejeté (exit 1) avec message de validation"
  else
    ko "T9b validation : VF_SCOPE=bogus non rejeté correctement (rc=$t9b_bogus_rc)"
  fi
  rm -f "$T9_OUT1"

  # ---------------------------------------------------------------------------
  # T9c — LE CAS DE LA TÂCHE (D-02), en deux sous-cas, avec un `claude` stub sur PATH qui répond
  # à `plugin list --json` par une fixture. Pourquoi ce cas existe : c'est exactement ce qu'un
  # `plugin list` filtré par simple grep de nom ne peut pas voir (les deux entrées matchent le
  # nom, seul le champ enabled/disabled distingue le sous-cas 1 du sous-cas 2).
  # ---------------------------------------------------------------------------
  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    skip "T9c (D-02) : python3/python introuvables — parsing JSON impossible dans cette disposition"
  else
    T9C_BIN="$(mktemp -d)"; T9C_FIX="$(mktemp -d)"

    # Sous-cas 1 : frontend-design@claude-code-plugins INACTIF ET
    # frontend-design@claude-plugins-official ACTIF → SATISFAIT, aucune commande émise.
    cat >"$T9C_FIX/fixture1.json" <<'JSON'
[
  {"id": "frontend-design@claude-code-plugins", "enabled": false, "version": "1.0.0"},
  {"id": "frontend-design@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "superpowers@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "ui-ux-pro-max@ui-ux-pro-max-skill", "enabled": true, "version": "1.0.0"},
  {"id": "impeccable@impeccable", "enabled": true, "version": "1.0.0"}
]
JSON
    cat >"$T9C_BIN/claude" <<SH
#!/usr/bin/env bash
if [ "\$1" = "plugin" ] && [ "\$2" = "list" ] && [ "\$3" = "--json" ]; then
  cat "$T9C_FIX/fixture1.json"
  exit 0
fi
exit 1
SH
    chmod +x "$T9C_BIN/claude"
    T9C_OUT1="$(PATH="$T9C_BIN:$PATH" bash "$EDD" 2>&1)"
    if echo "$T9C_OUT1" | "$GREP" -q 'frontend-design : déjà actif' \
      && ! echo "$T9C_OUT1" | "$GREP" -qE 'plugin (enable|install) frontend-design'; then
      ok "T9c sous-cas 1 (D-02) : entrée active sur un second marketplace → SATISFAIT, aucune commande"
    else
      ko "T9c sous-cas 1 (D-02) : frontend-design aurait dû être satisfait sans geste (règle « au moins une entrée active »)"
    fi

    # Sous-cas 2 : la SEULE entrée frontend-design est inactive → `enable` scopé émis, JAMAIS un
    # `install` nu pour ce plugin.
    cat >"$T9C_FIX/fixture2.json" <<'JSON'
[
  {"id": "frontend-design@claude-plugins-official", "enabled": false, "version": "1.0.0"},
  {"id": "superpowers@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "ui-ux-pro-max@ui-ux-pro-max-skill", "enabled": true, "version": "1.0.0"},
  {"id": "impeccable@impeccable", "enabled": true, "version": "1.0.0"}
]
JSON
    cat >"$T9C_BIN/claude" <<SH
#!/usr/bin/env bash
if [ "\$1" = "plugin" ] && [ "\$2" = "list" ] && [ "\$3" = "--json" ]; then
  cat "$T9C_FIX/fixture2.json"
  exit 0
fi
if [ "\$1" = "plugin" ] && [ "\$2" = "enable" ]; then
  echo "ENABLE_CALLED: \$*"
  exit 0
fi
exit 1
SH
    chmod +x "$T9C_BIN/claude"
    T9C_OUT2="$(PATH="$T9C_BIN:$PATH" bash "$EDD" 2>&1)"
    if echo "$T9C_OUT2" | "$GREP" -q 'ENABLE_CALLED: plugin enable frontend-design@claude-plugins-official --scope' \
      && ! echo "$T9C_OUT2" | "$GREP" -q 'plugin install frontend-design'; then
      ok "T9c sous-cas 2 (D-02) : seule entrée inactive → enable scopé, jamais un install nu"
    else
      ko "T9c sous-cas 2 (D-02) : enable scopé attendu pour frontend-design, jamais install nu"
    fi
    rm -rf "$T9C_BIN" "$T9C_FIX"
  fi

  # ---------------------------------------------------------------------------
  # T9d — DÉGRADATION : PATH restreint SANS `claude` → exit 0, aucune trace d'exception, les 4
  # étapes manuelles affichées, dont la ligne à deux temps d'`impeccable`.
  # ---------------------------------------------------------------------------
  T9D_BIN="$(mktemp -d)"
  T9D_OUT="$(PATH="$T9D_BIN:/usr/bin:/bin" bash "$EDD" 2>&1)"
  T9D_RC=$?
  if [ "$T9D_RC" -eq 0 ] \
    && echo "$T9D_OUT" | "$GREP" -q 'superpowers' \
    && echo "$T9D_OUT" | "$GREP" -q 'ui-ux-pro-max' \
    && echo "$T9D_OUT" | "$GREP" -q 'frontend-design' \
    && echo "$T9D_OUT" | "$GREP" -qi 'deux temps' \
    && echo "$T9D_OUT" | "$GREP" -q 'marketplace add pbakaus/impeccable' \
    && echo "$T9D_OUT" | "$GREP" -q 'plugin install impeccable@impeccable'; then
    ok "T9d dégradation : CLI claude absente → exit 0, 4 étapes manuelles (dont la ligne à deux temps d'impeccable)"
  else
    ko "T9d dégradation : rc=$T9D_RC ou étapes manuelles incomplètes"
  fi
  rm -rf "$T9D_BIN"

  # ---------------------------------------------------------------------------
  # T9e — AUTONOMIE (D-04) : aucune dépendance d'EXÉCUTION vers un autre MODULE (mentions en
  # commentaire tolérées — la garde vise les APPELS, pas les mentions), et module.json ne déclare
  # que `conductor`.
  #
  # Exception SANCTIONNÉE (RUNT-01, 38-02) : la résolution $(dirname "$0")/runtime-cli-dispatch.sh
  # cible un artefact PARTAGÉ de l'engine (plugin/_internal/, cascade EXACTE de
  # find_hooks_merger()) — ce n'est PAS « un autre module » au sens où D-04 l'entend (dev-
  # orchestrator, conductor, planning-core, validator, skill-creator, consolidator — la même liste
  # que le garde-fou bash ci-dessous). La garde reste pleine pour TOUTE AUTRE résolution
  # $(dirname "$0")/… : seule l'OCCURRENCE dont la substring EXACTE est
  # `$(dirname "$0")/runtime-cli-dispatch.sh` est exemptée.
  #
  # Durcissement (revue lot 3, 38-04) : le filtre raisonne désormais à l'OCCURRENCE, jamais à la
  # LIGNE PHYSIQUE. Deux trous successifs sur la même garde :
  #   1. filtre sur la substring `runtime-cli-dispatch.sh` n'importe où sur la ligne → une
  #      résolution cross-module déguisée sous le même basename passait (fixtures mutant_a/b
  #      ci-dessous) ;
  #   2. resserré à la ligne exacte via `grep -F … | grep -vF '<ligne exacte>'` → mais ce filtre
  #      opère sur la LIGNE ENTIÈRE : une ligne portant À LA FOIS la résolution légitime ET une
  #      illégitime (ex. `c="$(dirname "$0")/runtime-cli-dispatch.sh"; d="$(dirname "$0")/../foo"`)
  #      contient la substring légitime quelque part → toute la ligne est retirée par `-vF`, y
  #      compris l'occurrence illégitime qu'elle porte aussi. Zéro hit, silencieusement.
  # Le correctif extrait chaque résolution `$(dirname "$0")/…` sur sa PROPRE ligne de sortie
  # (`grep -oE`), puis filtre CHAQUE occurrence individuellement contre l'exemption : une ligne à
  # N résolutions produit N décisions indépendantes, plus aucune ne peut en couvrir une autre.
  # ---------------------------------------------------------------------------
  T9E_LEGIT='$(dirname "$0")/runtime-cli-dispatch.sh'
  # t9e_dirname_hits_new : logique EN VIGUEUR pour la garde réelle ci-dessous ET pour la preuve
  # générative — raisonnement à l'occurrence (grep -oE isole chaque résolution sur sa propre
  # ligne avant le filtre d'exemption).
  t9e_dirname_hits_new() {
    "$GREP" -oE '\$\(dirname "\$0"\)/[^"[:space:];]*' | "$GREP" -vF "$T9E_LEGIT" || true
  }
  # t9e_dirname_hits_old : ancienne logique (trou #2 ci-dessus) — décision à la LIGNE PHYSIQUE
  # entière. Conservée UNIQUEMENT pour la comparaison avant/après de la preuve générative
  # (T9e-gen), jamais utilisée par la garde réelle.
  t9e_dirname_hits_old() {
    "$GREP" -F '$(dirname "$0")' | "$GREP" -vF "$T9E_LEGIT" || true
  }
  # t9e_count_lines : nombre de lignes non vides sur stdin (0 si vide), sans faire échouer le set -o
  # pipefail du script quand le compte est 0 (grep -c retourne rc=1 dans ce cas).
  t9e_count_lines() {
    local _n
    _n="$("$GREP" -c '.' 2>/dev/null || true)"
    printf '%s' "${_n:-0}"
  }

  t9e_ok=1
  EDD_STRIPPED="$("$GREP" -v '^[[:space:]]*#' "$EDD")"
  echo "$EDD_STRIPPED" | "$GREP" -qE '(^|[^A-Za-z0-9_])source[[:space:]]' && { ko "T9e autonomie : 'source' détecté (appel, pas une mention) dans ensure-design-deps.sh"; t9e_ok=0; }
  echo "$EDD_STRIPPED" | "$GREP" -qE '^[[:space:]]*\.[[:space:]]' && { ko "T9e autonomie : dot-source ('. ') détecté dans ensure-design-deps.sh"; t9e_ok=0; }
  echo "$EDD_STRIPPED" | "$GREP" -qE 'bash[[:space:]]+.*(dev-orchestrator|conductor|planning-core|validator|skill-creator|consolidator)/' && { ko "T9e autonomie : invocation bash d'un script d'un autre module détectée"; t9e_ok=0; }
  DIRNAME_HITS="$(echo "$EDD_STRIPPED" | t9e_dirname_hits_new)"
  [ -n "$DIRNAME_HITS" ] \
    && { ko "T9e autonomie : résolution \$(dirname \"\$0\")/ détectée hors de l'exception runtime-cli-dispatch.sh (motif croisé du bootstrap de dev)"; t9e_ok=0; }

  # --- Cas de mutation en régression (RUNT-01, revue lot 2) — preuve que le garde T9e ci-dessus
  # attrape (a) une résolution cross-module déguisée sous le même nom de fichier invoquée sans
  # bash/source, (b) une résolution $(dirname "$0")/… non liée à runtime-cli-dispatch.sh, et
  # laisse passer (c) la ligne légitime exemptée. Fixtures isolées, n'affectent pas EDD réel.
  T9E_MUT_DIR="$(mktemp -d)"
  printf '%s\n' 'c="$(dirname "$0")/../conductor/scripts/runtime-cli-dispatch.sh"; "$c" "$@"' > "$T9E_MUT_DIR/mutant_a.sh"
  printf '%s\n' 'x="$(dirname "$0")/../other-module/foo.sh"' > "$T9E_MUT_DIR/mutant_b.sh"
  printf '%s\n' 'c="$(dirname "$0")/runtime-cli-dispatch.sh"; [ -f "$c" ] && { echo "$c"; return 0; }' > "$T9E_MUT_DIR/legit.sh"
  t9e_mut_ok=1
  for _t9e_case in mutant_a mutant_b legit; do
    _t9e_stripped="$("$GREP" -v '^[[:space:]]*#' "$T9E_MUT_DIR/$_t9e_case.sh")"
    _t9e_hits="$(echo "$_t9e_stripped" | t9e_dirname_hits_new)"
    case "$_t9e_case" in
      mutant_a|mutant_b)
        [ -z "$_t9e_hits" ] && { ko "T9e mutation $_t9e_case : devait être détecté (hit attendu), ne l'a pas été"; t9e_mut_ok=0; }
        ;;
      legit)
        [ -n "$_t9e_hits" ] && { ko "T9e mutation legit : ligne exemptée détectée à tort comme hit"; t9e_mut_ok=0; }
        ;;
    esac
  done
  rm -rf "$T9E_MUT_DIR"
  [ "$t9e_mut_ok" -eq 1 ] && ok "T9e mutation : cross-module déguisé + dirname non lié détectés, ligne légitime exemptée reste verte"

  # ---------------------------------------------------------------------------
  # T9e-gen — PREUVE GÉNÉRATIVE (revue lot 3, 38-04) : les 3 mutants ci-dessus ferment chacun EXACTEMENT
  # le cas nommé par une revue précédente et laissent vivre son voisin immédiat — c'est le motif du
  # point-fix. Cette preuve ne nomme aucun cas : elle construit le PRODUIT CARTÉSIEN des axes de
  # variation identifiés (nature légitime/illégitime, nombre d'occurrences par ligne physique et leur
  # ordre, mot-clé d'invocation avec/sans, occurrences sur la même ligne vs des lignes distinctes,
  # présence de commentaires) et vérifie que t9e_dirname_hits_new retombe EXACTEMENT sur le compte
  # d'occurrences illégitimes attendu — pour CHAQUE combinaison, sans exception nommée.
  #
  # Groupe 1 — une occurrence par ligne : nature(2) × forme d'invocation(5) × commentaire(2) = 20.
  # Groupe 2 — deux occurrences sur la MÊME ligne, les deux ordres : paire de natures(4) × paire de
  #            formes(2×2) × commentaire(2) = 32. C'est ce groupe qui reproduit le trou #2 : sous
  #            l'ancienne logique (t9e_dirname_hits_old), une ligne "légitime ; illégitime" ou
  #            "illégitime ; légitime" est retirée EN ENTIER parce qu'elle contient la substring
  #            légitime quelque part — l'occurrence illégitime qu'elle porte aussi disparaît avec.
  # Groupe 3 — les deux occurrences sur des lignes DISTINCTES (contrôle : aucune divergence attendue
  #            entre ancienne et nouvelle logique) : paire de natures(4) × bruit de commentaire
  #            interposé(2) = 8.
  # Total = 60 combinaisons générées.
  # ---------------------------------------------------------------------------
  T9E_GEN_LEGIT_TOK="$T9E_LEGIT"
  T9E_GEN_ILLEGIT_TOK='$(dirname "$0")/../conductor/scripts/runtime-cli-dispatch.sh'

  t9e_gen_render() {
    # $1=forme, $2=token de résolution $(dirname "$0")/...
    case "$1" in
      bare_quoted)   printf 'c="%s"' "$2" ;;
      bare_unquoted) printf 'c=%s' "$2" ;;
      bash)          printf 'bash %s "$@"' "$2" ;;
      source)        printf 'source %s' "$2" ;;
      direct_quote)  printf '"%s"' "$2" ;;
    esac
  }

  t9e_gen_total=0
  t9e_gen_red_before=0
  t9e_gen_red_after=0

  # $1=texte brut (une ou plusieurs lignes, AVANT filtrage des commentaires) $2=occurrences illégitimes attendues
  t9e_gen_run_case() {
    t9e_gen_total=$((t9e_gen_total + 1))
    local _raw="$1" _expected="$2" _stripped _new_n _old_n _should_flag _old_flag
    _stripped="$("$GREP" -v '^[[:space:]]*#' <<EOF2 || true
$_raw
EOF2
)"
    _new_n="$(printf '%s\n' "$_stripped" | t9e_dirname_hits_new | t9e_count_lines)"
    _old_n="$(printf '%s\n' "$_stripped" | t9e_dirname_hits_old | t9e_count_lines)"
    if [ "$_new_n" -ne "$_expected" ]; then
      t9e_gen_red_after=$((t9e_gen_red_after + 1))
      ko "T9e-gen cas #$t9e_gen_total : occurrences attendues=$_expected, obtenues=$_new_n (logique CORRIGÉE) — texte: $_raw"
    fi
    _should_flag=0; [ "$_expected" -gt 0 ] && _should_flag=1
    _old_flag=0; [ "$_old_n" -gt 0 ] && _old_flag=1
    [ "$_should_flag" -eq 1 ] && [ "$_old_flag" -eq 0 ] && t9e_gen_red_before=$((t9e_gen_red_before + 1))
  }

  # --- Groupe 1 : une occurrence par ligne ---
  for _t9e_kind in legit illegit; do
    if [ "$_t9e_kind" = legit ]; then _t9e_tok="$T9E_GEN_LEGIT_TOK"; _t9e_exp1=0; else _t9e_tok="$T9E_GEN_ILLEGIT_TOK"; _t9e_exp1=1; fi
    for _t9e_form in bare_quoted bare_unquoted bash source direct_quote; do
      _t9e_line="$(t9e_gen_render "$_t9e_form" "$_t9e_tok")"
      for _t9e_comment in no yes; do
        if [ "$_t9e_comment" = yes ]; then
          t9e_gen_run_case "# $_t9e_line" 0
        else
          t9e_gen_run_case "$_t9e_line" "$_t9e_exp1"
        fi
      done
    done
  done

  # --- Groupe 2 : deux occurrences sur la même ligne, les deux ordres ---
  for _t9e_k1 in legit illegit; do
    for _t9e_k2 in legit illegit; do
      if [ "$_t9e_k1" = legit ]; then _t9e_tok1="$T9E_GEN_LEGIT_TOK"; _t9e_e1=0; else _t9e_tok1="$T9E_GEN_ILLEGIT_TOK"; _t9e_e1=1; fi
      if [ "$_t9e_k2" = legit ]; then _t9e_tok2="$T9E_GEN_LEGIT_TOK"; _t9e_e2=0; else _t9e_tok2="$T9E_GEN_ILLEGIT_TOK"; _t9e_e2=1; fi
      _t9e_exp2=$((_t9e_e1 + _t9e_e2))
      for _t9e_form1 in bare_quoted bash; do
        for _t9e_form2 in bare_quoted bash; do
          _t9e_seg1="$(t9e_gen_render "$_t9e_form1" "$_t9e_tok1")"
          _t9e_seg2="$(t9e_gen_render "$_t9e_form2" "$_t9e_tok2")"
          _t9e_line="$_t9e_seg1; $_t9e_seg2"
          for _t9e_comment in no yes; do
            if [ "$_t9e_comment" = yes ]; then
              t9e_gen_run_case "# $_t9e_line" 0
            else
              t9e_gen_run_case "$_t9e_line" "$_t9e_exp2"
            fi
          done
        done
      done
    done
  done

  # --- Groupe 3 : occurrences sur deux lignes distinctes (contrôle, pas de divergence attendue) ---
  for _t9e_k1 in legit illegit; do
    for _t9e_k2 in legit illegit; do
      if [ "$_t9e_k1" = legit ]; then _t9e_tok1="$T9E_GEN_LEGIT_TOK"; _t9e_e1=0; else _t9e_tok1="$T9E_GEN_ILLEGIT_TOK"; _t9e_e1=1; fi
      if [ "$_t9e_k2" = legit ]; then _t9e_tok2="$T9E_GEN_LEGIT_TOK"; _t9e_e2=0; else _t9e_tok2="$T9E_GEN_ILLEGIT_TOK"; _t9e_e2=1; fi
      _t9e_exp3=$((_t9e_e1 + _t9e_e2))
      _t9e_line1="$(t9e_gen_render bare_quoted "$_t9e_tok1")"
      _t9e_line2="$(t9e_gen_render bare_quoted "$_t9e_tok2")"
      for _t9e_comment in no yes; do
        if [ "$_t9e_comment" = yes ]; then
          _t9e_block="$_t9e_line1"$'\n''# bruit '"$T9E_GEN_ILLEGIT_TOK"$'\n'"$_t9e_line2"
        else
          _t9e_block="$_t9e_line1"$'\n'"$_t9e_line2"
        fi
        t9e_gen_run_case "$_t9e_block" "$_t9e_exp3"
      done
    done
  done

  if [ "$t9e_gen_red_after" -eq 0 ]; then
    ok "T9e-gen preuve générative : $t9e_gen_total combinaisons (produit cartésien nature×occurrences×ordre×invocation×lignes×commentaires), $t9e_gen_red_before rouge(s) sous l'ancienne logique ligne-à-ligne, 0 rouge sous la logique corrigée occurrence-à-occurrence"
  else
    ko "T9e-gen preuve générative : $t9e_gen_red_after/$t9e_gen_total combinaison(s) encore rouge(s) sous la logique corrigée"
  fi

  unset -f t9e_dirname_hits_new t9e_dirname_hits_old t9e_count_lines t9e_gen_render t9e_gen_run_case

  MJ="$MOD/module.json"
  req_list="$(sed -n '/"requires"/,/\]/p' "$MJ" 2>/dev/null | "$GREP" -o '"[A-Za-z0-9_-]*"' | "$GREP" -v '"requires"' | tr -d '"')"
  [ "$req_list" = "conductor" ] || { ko "T9e module.json : requires attendu ['conductor'] seul, obtenu: ${req_list:-<vide>}"; t9e_ok=0; }
  [ "$t9e_ok" -eq 1 ] && ok "T9e autonomie (D-04) : aucune dépendance d'exécution vers un autre module, module.json requires=['conductor']"

  # ---------------------------------------------------------------------------
  # T9f — CÂBLAGE DOUBLE : hook nommé (double garde -f, branche else best-effort) dans
  # vibeflow-update.sh ; section Premier contact + garde-fou non-restitution dans AGENT.md.
  # SKIP explicite en disposition lab (le fichier d'engine n'y existe pas).
  # ---------------------------------------------------------------------------
  VU="$REPO/_internal/vibeflow-update.sh"
  if [ ! -f "$VU" ]; then
    skip "T9f câblage (engine) : vibeflow-update.sh introuvable (disposition lab)"
  else
    t9f_ok=1
    "$GREP" -qF '$module_dir/scripts/ensure-design-deps.sh' "$VU" || { ko "T9f câblage : garde -f source (\$module_dir) absente"; t9f_ok=0; }
    "$GREP" -qF '$TARGET_ROOT/scripts/ensure-design-deps.sh' "$VU" || { ko "T9f câblage : garde -f cible (\$TARGET_ROOT) absente"; t9f_ok=0; }
    # Extraction structurelle du bloc du hook (de son "if" d'amorce jusqu'au "fi" qui le referme,
    # profondeur comptée par mots — pas de \b/\< portable en awk BSD), plutôt qu'une fenêtre
    # positionnelle fixe (`grep -A8`) : toute insertion de ligne DANS le bloc (ex: 31-04, branche
    # `elif vf_dry_run`) ne doit jamais repousser le `else` hors de portée de la sonde.
    hook_start_line="$("$GREP" -n -m1 -F '$module_dir/scripts/ensure-design-deps.sh' "$VU" | cut -d: -f1)"
    if [ -z "$hook_start_line" ]; then
      ko "T9f câblage : ligne d'amorce du hook introuvable pour l'extraction du bloc"; t9f_ok=0
    else
      hook_block="$(awk -v start="$hook_start_line" '
        NR < start { next }
        {
          n = split($0, words, /[^A-Za-z_]+/)
          for (i = 1; i <= n; i++) {
            if (words[i] == "if") depth++
            else if (words[i] == "fi") depth--
          }
          print
          if (depth <= 0) exit
        }' "$VU")"
      echo "$hook_block" | "$GREP" -q 'else' || { ko "T9f câblage : branche else best-effort absente du bloc du hook"; t9f_ok=0; }
    fi
    [ "$t9f_ok" -eq 1 ] && ok "T9f câblage double (engine) : hook nommé, double garde -f (source+cible), branche else best-effort"
  fi

  t9f2_ok=1
  "$GREP" -qi 'Premier contact' "$AGENT_FILE" || { ko "T9f câblage : section « Premier contact » absente d'AGENT.md"; t9f2_ok=0; }
  "$GREP" -q 'ensure-design-deps.sh' "$AGENT_FILE" || { ko "T9f câblage : ensure-design-deps.sh non cité dans AGENT.md"; t9f2_ok=0; }
  "$GREP" -qi 'ne la restitue JAMAIS' "$AGENT_FILE" || { ko "T9f câblage : garde-fou de non-restitution brute absent d'AGENT.md"; t9f2_ok=0; }
  [ "$t9f2_ok" -eq 1 ] && ok "T9f câblage double (agent) : section Premier contact + garde-fou non-restitution présents"

  # ---------------------------------------------------------------------------
  # T9g — NON-SILENCE. Le trou d'origine (chaîne design qui dégrade sans le dire) se rejoue à
  # l'identique si le hook d'install avale la sortie du script. Trois asserts, du plus bas au plus
  # haut : (1) `--quiet` muet quand tout est actif — sinon le hook devient inutilisable et
  # quelqu'un le fera taire avec `2>&1` ; (2) `--quiet` NON muet sur anomalie — c'est la propriété
  # qui porte toute la valeur ; (3) le hook de l'engine appelle `--quiet` et ne redirige PAS stderr.
  # ---------------------------------------------------------------------------
  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    skip "T9g non-silence : python3/python introuvables — stub JSON impossible dans cette disposition"
  else
    T9G_BIN="$(mktemp -d)"; T9G_FIX="$(mktemp -d)"

    # (1) Les 4 actifs → --quiet doit produire ZÉRO ligne.
    cat >"$T9G_FIX/all-enabled.json" <<'JSON'
[
  {"id": "superpowers@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "ui-ux-pro-max@ui-ux-pro-max-skill", "enabled": true, "version": "1.0.0"},
  {"id": "frontend-design@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "impeccable@impeccable", "enabled": true, "version": "1.0.0"}
]
JSON
    cat >"$T9G_BIN/claude" <<SH
#!/usr/bin/env bash
if [ "\$1" = "plugin" ] && [ "\$2" = "list" ] && [ "\$3" = "--json" ]; then
  cat "$T9G_FIX/all-enabled.json"
  exit 0
fi
exit 1
SH
    chmod +x "$T9G_BIN/claude"
    T9G_QUIET="$(PATH="$T9G_BIN:$PATH" bash "$EDD" --quiet 2>&1)"
    T9G_LINES="$(printf '%s' "$T9G_QUIET" | "$GREP" -c . || true)"
    if [ "${T9G_LINES:-0}" -eq 0 ]; then
      ok "T9g non-silence (1/3) : --quiet muet quand les 4 plugins sont actifs (0 ligne)"
    else
      ko "T9g non-silence (1/3) : --quiet a émis ${T9G_LINES} ligne(s) sur un état tout-vert"
    fi

    # (2) Un plugin désactivé → --quiet doit PARLER quand même (geste + résumé).
    cat >"$T9G_FIX/one-disabled.json" <<'JSON'
[
  {"id": "superpowers@claude-plugins-official", "enabled": true, "version": "1.0.0"},
  {"id": "ui-ux-pro-max@ui-ux-pro-max-skill", "enabled": true, "version": "1.0.0"},
  {"id": "frontend-design@claude-plugins-official", "enabled": false, "version": "1.0.0"},
  {"id": "impeccable@impeccable", "enabled": true, "version": "1.0.0"}
]
JSON
    cat >"$T9G_BIN/claude" <<SH
#!/usr/bin/env bash
if [ "\$1" = "plugin" ] && [ "\$2" = "list" ] && [ "\$3" = "--json" ]; then
  cat "$T9G_FIX/one-disabled.json"
  exit 0
fi
if [ "\$1" = "plugin" ] && [ "\$2" = "enable" ]; then
  exit 0
fi
exit 1
SH
    chmod +x "$T9G_BIN/claude"
    T9G_ANOM="$(PATH="$T9G_BIN:$PATH" bash "$EDD" --quiet 2>&1)"
    if echo "$T9G_ANOM" | "$GREP" -qi 'DÉSACTIVÉ' && echo "$T9G_ANOM" | "$GREP" -q 'Résumé'; then
      ok "T9g non-silence (2/3) : --quiet laisse passer l'anomalie (plugin désactivé + résumé)"
    else
      ko "T9g non-silence (2/3) : --quiet a étouffé l'anomalie — la dégradation redevient silencieuse"
    fi
    rm -rf "$T9G_BIN" "$T9G_FIX"

    # (3) Le hook de l'engine : `--quiet` présent ET pas de `2>&1` sur la ligne d'appel.
    if [ ! -f "$REPO/_internal/vibeflow-update.sh" ]; then
      skip "T9g non-silence (3/3) : vibeflow-update.sh introuvable (disposition lab)"
    else
      T9G_CALL="$("$GREP" -m1 'bash "$TARGET_ROOT/scripts/ensure-design-deps.sh"' "$REPO/_internal/vibeflow-update.sh" || true)"
      if echo "$T9G_CALL" | "$GREP" -q -- '--quiet' && ! echo "$T9G_CALL" | "$GREP" -qF '2>&1'; then
        ok "T9g non-silence (3/3) : le hook engine appelle --quiet sans avaler stderr"
      else
        ko "T9g non-silence (3/3) : le hook engine doit passer --quiet et NE PAS rediriger stderr (ligne: ${T9G_CALL:-<absente>})"
      fi
    fi
  fi

  # ---------------------------------------------------------------------------
  # T9h — DISPATCH RÉEL, PAR EXÉCUTION (RUNT-01, revue lot 2, 38-02-PLAN.md tâche 2 acceptance
  # criterion) : T9..T9g ci-dessus invoquent TOUJOURS `$EDD` à sa position réelle dans le module —
  # `runtime-cli-dispatch.sh` n'y est JAMAIS à côté (il vit dans plugin/_internal/), donc
  # `find_runtime_cli_dispatch()` (dirname "$0") ne le trouve jamais et seule la branche de repli
  # `claude` figée est exercée, quel que soit VF_RUNTIME. Ce test copie les DEUX fichiers côte à
  # côte (disposition réelle post-install, cf. copy_module_scripts()) pour prouver, par exécution
  # réelle et non par lecture de code, que VF_RUNTIME=claude ET VF_RUNTIME=codex traversent
  # detect_all()/process_plugin() jusqu'au sous-processus runtime RÉEL.
  # ---------------------------------------------------------------------------
  RCD="$REPO/_internal/runtime-cli-dispatch.sh"
  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    skip "T9h dispatch réel : python3/python introuvables — parsing JSON impossible dans cette disposition"
  elif [ ! -f "$RCD" ]; then
    skip "T9h dispatch réel : runtime-cli-dispatch.sh introuvable dans $REPO/_internal/"
  else
    T9H_DIR="$(mktemp -d)"
    cp "$EDD" "$T9H_DIR/ensure-design-deps.sh"
    cp "$RCD" "$T9H_DIR/runtime-cli-dispatch.sh"
    T9H_BIN="$(mktemp -d)"
    T9H_JOURNAL="$(mktemp)"
    for _t9h_rt in claude codex; do
      cat >"$T9H_BIN/$_t9h_rt" <<SH
#!/usr/bin/env bash
if [ "\$1" = "plugin" ] && [ "\$2" = "list" ] && [ "\$3" = "--json" ]; then
  echo "[]"
  exit 0
fi
echo "$_t9h_rt \$*" >> "$T9H_JOURNAL"
exit 0
SH
      chmod +x "$T9H_BIN/$_t9h_rt"
    done

    for _t9h_rt in claude codex; do
      : >"$T9H_JOURNAL"
      PATH="$T9H_BIN:/usr/bin:/bin" VF_RUNTIME="$_t9h_rt" bash "$T9H_DIR/ensure-design-deps.sh" >/dev/null 2>&1
      if "$GREP" -qF "$_t9h_rt plugin install superpowers@claude-plugins-official --scope user" "$T9H_JOURNAL"; then
        ok "T9h dispatch réel : VF_RUNTIME=$_t9h_rt -> \`$_t9h_rt plugin install superpowers@claude-plugins-official --scope user\` capturé depuis une exécution réelle"
      else
        ko "T9h dispatch réel : VF_RUNTIME=$_t9h_rt attendu dans le journal, obtenu : $(cat "$T9H_JOURNAL")"
      fi
    done

    # Non-régression du test lui-même : SANS runtime-cli-dispatch.sh à côté, le chemin dispatch ne
    # doit PLUS être exercé — VF_RUNTIME=codex doit retomber sur la branche de repli `claude`
    # figée (ADR historique de ce script), jamais sur `codex`. Si ce cas échoue, T9h ci-dessus
    # n'exerçait rien de plus que T9..T9g et le trou du finding 3 est toujours ouvert.
    rm -f "$T9H_DIR/runtime-cli-dispatch.sh"
    : >"$T9H_JOURNAL"
    PATH="$T9H_BIN:/usr/bin:/bin" VF_RUNTIME=codex bash "$T9H_DIR/ensure-design-deps.sh" >/dev/null 2>&1
    if "$GREP" -qF "codex plugin install" "$T9H_JOURNAL"; then
      ko "T9h non-régression : sans runtime-cli-dispatch.sh à côté, 'codex' a quand même été invoqué — le test ne prouve plus le chemin dispatch"
    else
      ok "T9h non-régression : sans runtime-cli-dispatch.sh à côté, repli sur la branche 'claude' figée (le chemin dispatch n'est PAS exercé par erreur)"
    fi

    rm -rf "$T9H_DIR" "$T9H_BIN"
    rm -f "$T9H_JOURNAL"
  fi
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
