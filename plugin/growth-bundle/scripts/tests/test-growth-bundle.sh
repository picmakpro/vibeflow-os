#!/usr/bin/env bash
# test-growth-bundle.sh — Suite de vérification du module growth-bundle (équipe growth
# sur le team-kernel, matérialisation 2026-07-25).
#
#   T1  — Les 5 agents de l'équipe existent, frontmatter complet (description/model/memory),
#         name = nom de fichier.
#   T2  — Densité ADR-029 mesurée par wc -l UNIQUEMENT : agents ≤250L, skill ≤500L.
#   T3  — check-agents.sh --strict (ADR-044) vert sur plugin/growth-bundle/agents
#         (SKIP si le contrôleur du conductor est introuvable dans la disposition courante).
#   T4  — Le juge est read-only : growth-quality-judge sans Write ni Edit dans tools,
#         vf-internal, et ne s'auto-attribue aucune écriture.
#   T5  — Cloisonnement Pattern 12 : workers vf-internal + tools sans Task/Agent/Skill ;
#         manager exposé (PAS vf-internal), opus, allowlist Agent(...) fermée sur l'équipe.
#   T6  — Le manager n'a pas de périmètre de production : pas d'Edit dans tools + la
#         consigne « ne produis JAMAIS » explicite.
#   T7  — Contrats du kernel : DIGEST présent dans le manager, bloc typé (statut
#         passed|gaps_found|human_needed|blocked) dans le manager ET chaque worker/juge.
#   T8  — Human-gate d'acquisition NON contournable : tout envoi réel HUMAN-GATED
#         (manager Iron Law + copywriter « n'envoie jamais » + analyst exige la preuve de
#         lancement + le skill porte l'invariant).
#   T9  — Skill vf-growth : description valide (déclencheur + portée) + aiguillage
#         geste simple vs mission (SEUIL_EQUIPE_GROWTH → vf-growth-manager).
#   T10 — module.json : proposable=true assumé, version ↔ VERSION, type agents+skill.
#   T11 — BUNDLE.md : encart de matérialisation présent (le doc reste trace de conception).
#   T12 — Rubric du juge : /100 explicite + seuil 80 + critères éliminatoires (claim non
#         sourcé, conformité consentement/RGPD).
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe
# (SKIP non bloquant), exit 1 si au moins un KO. Calqué sur test-content-bundle.sh.

set -uo pipefail

MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible aux alias (ugrep) : binaire système.
GREP="$(command -v grep)"

MANAGER="$MOD/agents/vf-growth-manager.md"
JUDGE="$MOD/agents/growth-quality-judge.md"
WORKERS="channel-strategist copywriter-sequences campaign-analyst"
TEAM="vf-growth-manager channel-strategist copywriter-sequences campaign-analyst growth-quality-judge"
SKILL="$MOD/skills/vf-growth/SKILL.md"

echo "== test-growth-bundle (module: $MOD) =="

# ---------------------------------------------------------------------------
# T1 — 5 agents présents, frontmatter complet, name = fichier
# ---------------------------------------------------------------------------
t1_ok=1
for a in $TEAM; do
  f="$MOD/agents/$a.md"
  if [ ! -f "$f" ]; then ko "T1 agents : $a.md introuvable"; t1_ok=0; continue; fi
  for field in description model memory; do
    "$GREP" -q "^${field}:" "$f" || { ko "T1 agents : $a.md sans champ $field"; t1_ok=0; }
  done
  "$GREP" -q "^name: $a\$" "$f" || { ko "T1 agents : $a.md — name ≠ nom de fichier"; t1_ok=0; }
done
[ "$t1_ok" -eq 1 ] && ok "T1 agents : 5 agents présents, frontmatter complet, name aligné"

# ---------------------------------------------------------------------------
# T2 — Densité ADR-029 par wc -l uniquement
# ---------------------------------------------------------------------------
t2_ok=1
for a in $TEAM; do
  f="$MOD/agents/$a.md"
  [ -f "$f" ] || continue
  n=$(wc -l < "$f" | tr -d ' ')
  [ "${n:-999}" -le 250 ] || { ko "T2 densité : $a.md = ${n}L (>250)"; t2_ok=0; }
done
if [ -f "$SKILL" ]; then
  n=$(wc -l < "$SKILL" | tr -d ' ')
  [ "${n:-999}" -le 500 ] || { ko "T2 densité : vf-growth/SKILL.md = ${n}L (>500)"; t2_ok=0; }
else
  ko "T2 densité : $SKILL introuvable"; t2_ok=0
fi
[ "$t2_ok" -eq 1 ] && ok "T2 densité : agents ≤250L, skill ≤500L (ADR-029)"

# ---------------------------------------------------------------------------
# T3 — check-agents.sh --strict (ADR-044)
# ---------------------------------------------------------------------------
CHECK_AGENTS=""
for cand in "$REPO/conductor/scripts/check-agents.sh" "$HOME/.claude/scripts/check-agents.sh"; do
  [ -f "$cand" ] && { CHECK_AGENTS="$cand"; break; }
done
if [ -z "$CHECK_AGENTS" ]; then
  skip "T3 check-agents : contrôleur introuvable (conductor absent de cette disposition)"
else
  if bash "$CHECK_AGENTS" --strict --agents-dir="$MOD/agents" >/dev/null 2>&1; then
    ok "T3 check-agents : --strict vert sur les agents de l'équipe growth (ADR-044)"
  else
    ko "T3 check-agents : --strict en échec sur $MOD/agents"
  fi
fi

# ---------------------------------------------------------------------------
# T4 — Juge read-only : pas de Write/Edit, vf-internal
# ---------------------------------------------------------------------------
t4_ok=1
if [ -f "$JUDGE" ]; then
  jtools=$("$GREP" '^tools:' "$JUDGE")
  echo "$jtools" | "$GREP" -qw 'Write' && { ko "T4 juge : Write présent dans tools"; t4_ok=0; }
  echo "$jtools" | "$GREP" -qw 'Edit'  && { ko "T4 juge : Edit présent dans tools"; t4_ok=0; }
  echo "$jtools" | "$GREP" -qE 'Task|Agent' && { ko "T4 juge : Task/Agent présent dans tools"; t4_ok=0; }
  "$GREP" -q '^vf-internal: true' "$JUDGE" || { ko "T4 juge : vf-internal manquant"; t4_ok=0; }
  "$GREP" -qi 'ne modifie' "$JUDGE" || { ko "T4 juge : consigne read-only absente du corps"; t4_ok=0; }
else
  ko "T4 juge : $JUDGE introuvable"; t4_ok=0
fi
[ "$t4_ok" -eq 1 ] && ok "T4 juge : read-only machine-enforced (tools sans Write/Edit/Task) + vf-internal"

# ---------------------------------------------------------------------------
# T5 — Cloisonnement Pattern 12 : workers internes sans Task ; manager exposé
# ---------------------------------------------------------------------------
t5_ok=1
for w in $WORKERS; do
  f="$MOD/agents/$w.md"
  [ -f "$f" ] || { ko "T5 workers : $w.md introuvable"; t5_ok=0; continue; }
  "$GREP" -q '^vf-internal: true' "$f" || { ko "T5 workers : vf-internal manquant sur $w"; t5_ok=0; }
  wtools=$("$GREP" '^tools:' "$f")
  echo "$wtools" | "$GREP" -qE 'Task|Agent|Skill' && { ko "T5 workers : $w a Task/Agent/Skill dans tools (doit rester cloisonné)"; t5_ok=0; }
done
if [ -f "$MANAGER" ]; then
  "$GREP" -q '^vf-internal:' "$MANAGER" && { ko "T5 manager : déclaré vf-internal (doit rester exposé)"; t5_ok=0; }
  "$GREP" -q '^model: opus' "$MANAGER" || { ko "T5 manager : model ≠ opus"; t5_ok=0; }
  "$GREP" '^tools:' "$MANAGER" | "$GREP" -q 'Agent(' || { ko "T5 manager : allowlist Agent(...) absente"; t5_ok=0; }
  for m in $WORKERS growth-quality-judge; do
    "$GREP" '^tools:' "$MANAGER" | "$GREP" -q "$m" || { ko "T5 manager : $m absent de l'allowlist Agent(...)"; t5_ok=0; }
  done
else
  ko "T5 manager : $MANAGER introuvable"; t5_ok=0
fi
[ "$t5_ok" -eq 1 ] && ok "T5 cloisonnement : workers vf-internal sans Task, manager exposé (opus, allowlist fermée)"

# ---------------------------------------------------------------------------
# T6 — Manager sans périmètre de production
# ---------------------------------------------------------------------------
t6_ok=1
if [ -f "$MANAGER" ]; then
  "$GREP" '^tools:' "$MANAGER" | "$GREP" -qw 'Edit' && { ko "T6 manager : Edit présent dans tools"; t6_ok=0; }
  "$GREP" -q 'ne produis JAMAIS' "$MANAGER" || { ko "T6 manager : consigne « ne produis JAMAIS » absente"; t6_ok=0; }
else
  ko "T6 manager : $MANAGER introuvable"; t6_ok=0
fi
[ "$t6_ok" -eq 1 ] && ok "T6 manager : aucun périmètre de production (pas d'Edit, consigne explicite)"

# ---------------------------------------------------------------------------
# T7 — Contrats kernel : DIGEST + bloc typé partout
# ---------------------------------------------------------------------------
t7_ok=1
"$GREP" -q 'DIGEST' "$MANAGER" 2>/dev/null || { ko "T7 contrats : DIGEST absent du manager"; t7_ok=0; }
for a in $TEAM; do
  f="$MOD/agents/$a.md"
  [ -f "$f" ] || continue
  "$GREP" -q 'human_needed' "$f" || { ko "T7 contrats : bloc typé (human_needed) absent de $a"; t7_ok=0; }
  "$GREP" -qE 'passed.*gaps_found|gaps_found.*passed' "$f" || { ko "T7 contrats : statuts typés absents de $a"; t7_ok=0; }
done
[ "$t7_ok" -eq 1 ] && ok "T7 contrats : DIGEST (manager) + rapport typé (5/5 agents)"

# ---------------------------------------------------------------------------
# T8 — Human-gate d'acquisition NON contournable (ADR-031, Iron Law growth)
# ---------------------------------------------------------------------------
t8_ok=1
if [ -f "$MANAGER" ]; then
  "$GREP" -q 'human_needed' "$MANAGER" || { ko "T8 humain : human_needed absent du manager"; t8_ok=0; }
  "$GREP" -qi 'jamais' "$MANAGER" || { ko "T8 humain : « jamais » absent du manager"; t8_ok=0; }
  "$GREP" -qi 'validation humaine' "$MANAGER" || { ko "T8 humain : « validation humaine » absente du manager"; t8_ok=0; }
  "$GREP" -qi 'HUMAN-GATED' "$MANAGER" || { ko "T8 humain : Iron Law HUMAN-GATED absente du manager"; t8_ok=0; }
  "$GREP" -qi 'dépense' "$MANAGER" || { ko "T8 humain : la dépense publicitaire n'est pas couverte par le gate du manager"; t8_ok=0; }
fi
CW="$MOD/agents/copywriter-sequences.md"
if [ -f "$CW" ]; then
  "$GREP" -qi 'ENVOIE JAMAIS' "$CW" || { ko "T8 humain : le copywriter n'exclut pas explicitement l'envoi"; t8_ok=0; }
  "$GREP" -qi 'HUMAN-GATED' "$CW" || { ko "T8 humain : HUMAN-GATED absent du copywriter"; t8_ok=0; }
fi
AN="$MOD/agents/campaign-analyst.md"
if [ -f "$AN" ]; then
  "$GREP" -qi 'REFUSE' "$AN" || { ko "T8 humain : l'analyst ne refuse pas explicitement une campagne non lancée"; t8_ok=0; }
  "$GREP" -qi 'lancement humain' "$AN" || { ko "T8 humain : preuve de lancement humain absente de l'analyst"; t8_ok=0; }
fi
if [ -f "$SKILL" ]; then
  "$GREP" -qi 'jamais' "$SKILL" && "$GREP" -qi 'validation humaine' "$SKILL" \
    || { ko "T8 humain : invariant validation humaine absent du skill"; t8_ok=0; }
  "$GREP" -qi 'HUMAN-GATED' "$SKILL" || { ko "T8 humain : HUMAN-GATED absent du skill"; t8_ok=0; }
fi
[ "$t8_ok" -eq 1 ] && ok "T8 humain : envoi réel human-gated non contournable (manager + copywriter + analyst + skill)"

# ---------------------------------------------------------------------------
# T9 — Skill vf-growth : description + aiguillage
# ---------------------------------------------------------------------------
t9_ok=1
if [ -f "$SKILL" ]; then
  desc=$(awk '/^description:/{f=1;print;next} f&&/^[A-Za-z_-]+:/{exit} f&&/^---[[:space:]]*$/{exit} f{print}' "$SKILL" | tr '\n' ' ')
  dlen=$(echo "$desc" | wc -c | tr -d ' ')
  [ "${dlen:-0}" -ge 120 ] || { ko "T9 skill : description trop courte (${dlen}c)"; t9_ok=0; }
  echo "$desc" | "$GREP" -qi 'Utiliser quand' || { ko "T9 skill : pas de déclencheur « Utiliser quand »"; t9_ok=0; }
  echo "$desc" | "$GREP" -qi 'Invocable' || { ko "T9 skill : pas de portée d'invocation"; t9_ok=0; }
  "$GREP" -q 'SEUIL_EQUIPE_GROWTH' "$SKILL" || { ko "T9 skill : seuil d'aiguillage absent"; t9_ok=0; }
  "$GREP" -q 'vf-growth-manager' "$SKILL" || { ko "T9 skill : route mission → vf-growth-manager absente"; t9_ok=0; }
else
  ko "T9 skill : $SKILL introuvable"; t9_ok=0
fi
[ "$t9_ok" -eq 1 ] && ok "T9 skill : description valide + aiguillage geste simple vs mission"

# ---------------------------------------------------------------------------
# T10 — module.json : proposable assumé, versions alignées, type réel
# ---------------------------------------------------------------------------
t10_ok=1
MJ="$MOD/module.json"
if [ -f "$MJ" ]; then
  "$GREP" -q '"proposable": true' "$MJ" || { ko "T10 module : proposable ≠ true (module vendu comme fini ?)"; t10_ok=0; }
  "$GREP" -q 'doc-only' "$MJ" && { ko "T10 module : type encore doc-only"; t10_ok=0; }
  mj_ver=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MJ" | head -1)
  v_file=$(tr -d '[:space:]' < "$MOD/VERSION")
  [ "$mj_ver" = "$v_file" ] || { ko "T10 module : module.json=$mj_ver ≠ VERSION=$v_file"; t10_ok=0; }
else
  ko "T10 module : module.json introuvable"; t10_ok=0
fi
[ "$t10_ok" -eq 1 ] && ok "T10 module : proposable=true, type réel, VERSION ↔ module.json ($mj_ver)"

# ---------------------------------------------------------------------------
# T11 — BUNDLE.md : encart de matérialisation
# ---------------------------------------------------------------------------
if "$GREP" -q 'Matérialisé le 2026-07-25' "$MOD/content/BUNDLE.md" 2>/dev/null; then
  ok "T11 bundle : encart de matérialisation présent (BUNDLE.md = trace de conception)"
else
  ko "T11 bundle : encart « Matérialisé le 2026-07-25 » absent de content/BUNDLE.md"
fi

# ---------------------------------------------------------------------------
# T12 — Rubric du juge : /100, seuil 80, critères éliminatoires
# ---------------------------------------------------------------------------
t12_ok=1
if [ -f "$JUDGE" ]; then
  "$GREP" -q '/100' "$JUDGE" || { ko "T12 rubric : /100 absent du juge"; t12_ok=0; }
  "$GREP" -q '80' "$JUDGE" || { ko "T12 rubric : seuil 80 absent du juge"; t12_ok=0; }
  "$GREP" -qi 'éliminatoire' "$JUDGE" || { ko "T12 rubric : critère éliminatoire absent du juge"; t12_ok=0; }
  "$GREP" -qi 'sourc' "$JUDGE" || { ko "T12 rubric : critère de sourcing absent du juge"; t12_ok=0; }
  "$GREP" -qiE 'consentement|RGPD' "$JUDGE" || { ko "T12 rubric : critère consentement/RGPD absent du juge"; t12_ok=0; }
fi
[ "$t12_ok" -eq 1 ] && ok "T12 rubric : /100 + seuil 80 + éliminatoires (claims sourcés, consentement/RGPD) dans le juge"

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
