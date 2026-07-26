#!/usr/bin/env bash
# test-dev-orchestrator.sh — Suite de vérification du module dev-orchestrator (VFDO)
#
# Couvre le modèle agentique (spec 2026-07-25-suppression-facade-vf-design.md) + les acquis :
#   T1  — build-gsd-index.sh génère un index NON VIDE depuis les skills GSD installés
#         (SKIP explicite si aucun skill gsd-* présent sur la machine).
#   T2  — ensure-deps.sh idempotent (2 runs en dry-run = no-op, exit 0 aux deux).
#   T2b — ensure-deps scopé (dry-run forcé, sans réseau) — SCOPE-03.
#   T3  — AGENT.md : ≤250L, table d'intentions fournie (≥11 lignes NL) et AUCUNE référence
#         à un verbe supprimé (la façade des 29 verbes est morte — elle ne ressuscite pas).
#   T4  — Chaque skill du module mappe vers une cible existante (aucun orphelin) :
#         gsd-X vérifié contre gsd-skills-index.md (fixture de secours si index vide).
#   T5  — Densité (VERIF-02) MESURÉE PAR wc -l UNIQUEMENT : AGENT.md ≤250L, skills ≤500L.
#         (NE PAS appeler le contrôleur de taille générique qui ignore les .md.)
#   T6  — Install end-to-end via vibeflow-update.sh (best-effort, SKIP si non réalisable).
#         Vérifie aussi que la façade n'est PAS réinstallée (ni rule de préséance, ni
#         vocabulary-map).
#   T7  — Garde-fou first-use présent dans AGENT.md : détection .planning + proposition de
#         cartographie + new-project encadré (régression FIRST-01/FIRST-02, BOOT-04).
#   T8/T8b — Équipe de mission : 4 agents conformes (frontmatter, densité, vf-internal —
#         Pattern 12).
#   T8c — check-agents.sh --strict (ADR-044) passe sur les agents d'équipe (SKIP si le
#         contrôleur du conductor est introuvable dans la disposition courante).
#   T9  — Contrats de mission : source unique (Brief + DIGEST + Rapport + SEUIL_EQUIPE)
#         + 3 renvois DRY.
#   T10 — Routage mission (AGENT.md) + aiguillage taille (vf-auto, SEUIL_EQUIPE).
#   T11 — Généricité : aucun renvoi vers un chemin absent d'un lab installé (DM5).
#   T12 — Les 2 skills survivants (vf-auto, vf-dev) ont une description valide.
#   T13 — La façade est morte : vocabulary-map.md et rules/vf-verb-precedence.md N'EXISTENT
#         PLUS, aucun dossier de verbe supprimé dans skills/, aucun verbe supprimé référencé
#         par un fichier du module.
#   T14 — Exhaustivité du routage : chaque skill de l'index factuel est routé par
#         intent-routing.md (carte intention → brique, sans colonne verbe).
#   T15 — Pipelining N/N+1 (audit 2026-07-25) : mission-flow.md modélise le DAG fin
#         (discuss/plan/execute par étape, règle de provisoire) et vf-dev-manager.md
#         y renvoie avec la consigne compacte.
#   T16 — Doctrine d'ingestion (phase 13, BRDG-01/BRDG-03) : ingestion-flow.md existe et
#         porte le script, les 3 exits, le schéma manifest et les 4 garde-fous ; AGENT.md
#         y renvoie en Références.
#   T17 — Câblage du routage d'ingestion : AGENT.md porte une ligne d'intention explicite
#         (table Amont & cadrage) et intent-routing.md conserve sa ligne enrichie.
#
# Historique de numérotation : T3/T12/T13/T14 ont changé de sémantique à la v2.0.0 (les
# anciens tests de collision de descriptions, de préséance et de synchro de la table vf-dev
# n'ont plus d'objet sans la façade). T1-T2b/T4-T11 sont les acquis, non renumérotés.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe
# (SKIP non bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test du repo.
#
# Référence : VERIF-01, VERIF-02, IDX-02, D4, D7, ADR-044, ADR-053, spec 2026-07-25.

set -uo pipefail

# Résolution du module (racine = dossier parent de scripts/tests/).
MOD="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="$(cd "$MOD/.." && pwd)"

# Détection de la disposition : source (dev-orchestrator/) vs lab installé (.claude/).
# - Source : AGENT.md + references/ à la racine du module.
# - Lab installé : agent à plat dans agents/dev-orchestrator.md, references sous
#   agents/dev-orchestrator-references/ (D7). skills/ et scripts/ sont identiques aux deux.
if [ -f "$MOD/AGENT.md" ]; then
  AGENT_FILE="$MOD/AGENT.md"
  REFS_DIR="$MOD/references"
elif [ -f "$MOD/agents/dev-orchestrator.md" ]; then
  AGENT_FILE="$MOD/agents/dev-orchestrator.md"
  REFS_DIR="$MOD/agents/dev-orchestrator-references"
else
  echo "  ✗ Impossible de localiser l'agent (ni source AGENT.md, ni lab agents/dev-orchestrator.md)"; exit 1
fi

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

# ---------------------------------------------------------------------------
# Périmètre : ce que le module POSSÈDE depuis la v2.0.0
# ---------------------------------------------------------------------------
# En lab installé, `.claude/skills/` est PLAT et PARTAGÉ par tous les modules (conductor —
# socle obligatoire —, validator, planning-core…). On n'audite que les 2 skills survivants
# de CE module — liste fermée depuis la suppression de la façade (spec 2026-07-25).
OWNED_SKILLS="vf-auto vf-dev"
owned_skill() { case " $OWNED_SKILLS " in *" $1 "*) return 0 ;; esac; return 1; }

# Les 29 verbes-façades SUPPRIMÉS (v2.0.0). Toute référence résiduelle est une régression :
# elle promettrait un skill qui n'existe plus. Frontière de mot obligatoire au grep —
# vf-test ≠ vf-test-orchestrator, vf-plan ≠ vf-planning, vf-review ≠ vf-reviewer,
# vf-dev ≠ vf-dev-manager.
DELETED_VERBS="vf-init vf-map vf-brainstorm vf-explore vf-spike vf-spec vf-decide vf-plan \
vf-execute vf-quick vf-ship vf-test vf-testgen vf-review vf-gaps vf-secure vf-debug \
vf-forensics vf-inbox vf-milestone vf-phase vf-undo vf-backlog vf-cleanup vf-progress \
vf-resume vf-pause vf-docs vf-learn"
# Alternation regex (une passe de grep par fichier, pas 29).
DELETED_RE="$(echo "$DELETED_VERBS" | tr -s ' ' '|' )"
DELETED_RE="(${DELETED_RE})([^a-z0-9-]|\$)"

# « $1 (fichier) référence-t-il un verbe supprimé ? » → imprime les hits (vide sinon).
deleted_hits() { "$GREP" -oE "$DELETED_RE" "$1" 2>/dev/null | "$GREP" -oE 'vf-[a-z-]+' | sort -u | tr '\n' ' '; }

ROUTING="$REFS_DIR/intent-routing.md"

echo "== test-dev-orchestrator (module: $MOD) =="

# ---------------------------------------------------------------------------
# T1 — Index factuel non vide (ou SKIP si pas de GSD installé)
# ---------------------------------------------------------------------------
GSD_SKILLS_DIR="${VF_GSD_SKILLS_DIR:-$HOME/.claude/skills}"
gsd_installed=0
if "$GREP" -q . <(ls -d "$GSD_SKILLS_DIR"/gsd-*/SKILL.md 2>/dev/null); then
  gsd_installed=1
fi

INDEX_TMP="$(mktemp)"
trap 'rm -f "$INDEX_TMP"' EXIT

if VF_INDEX_OUT="$INDEX_TMP" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1; then
  if [ "$gsd_installed" -eq 1 ]; then
    distinct_skills=$("$GREP" -Eo 'gsd-[a-z0-9-]+' "$INDEX_TMP" | sort -u | wc -l | tr -d ' ')
    if [ "${distinct_skills:-0}" -ge 1 ]; then
      ok "T1 index : généré, non vide ($distinct_skills skill(s) gsd-* distinct(s))"
    else
      ko "T1 index : GSD présent mais aucun skill extrait de l'index"
    fi
  else
    skip "T1 index : GSD non installé — index vide attendu (pas un échec)"
  fi
else
  ko "T1 index : build-gsd-index.sh a échoué (exit non-zéro)"
fi

# ---------------------------------------------------------------------------
# T1b/T1c/T1d — dual-layout WORKFLOWS_DIR (D-01, 11-CONTEXT.md)
# ---------------------------------------------------------------------------
# T1b : $HOME redirigé, gsd-core/workflows/ peuplé (2 .md), pas de skills → section « source
# secondaire » présente avec les 2 noms. Puis même test en legacy get-shit-done/workflows/.
T1B_HOME="$(mktemp -d)"
mkdir -p "$T1B_HOME/.claude/gsd-core/workflows" "$T1B_HOME/empty-skills"
echo "# wf-a" > "$T1B_HOME/.claude/gsd-core/workflows/wf-a.md"
echo "# wf-b" > "$T1B_HOME/.claude/gsd-core/workflows/wf-b.md"
T1B_OUT="$(mktemp)"
if env -u VF_GSD_WORKFLOWS_DIR HOME="$T1B_HOME" VF_GSD_SKILLS_DIR="$T1B_HOME/empty-skills" VF_INDEX_OUT="$T1B_OUT" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1 \
  && "$GREP" -q "## Workflows GSD (source secondaire)" "$T1B_OUT" && "$GREP" -q "wf-a" "$T1B_OUT" && "$GREP" -q "wf-b" "$T1B_OUT"; then
  ok "T1b workflows : gsd-core/workflows/ sous \$HOME détecté (2 workflows listés)"
else
  ko "T1b workflows : gsd-core/workflows/ sous \$HOME non détecté"
fi
rm -rf "$T1B_HOME/.claude/gsd-core"
mkdir -p "$T1B_HOME/.claude/get-shit-done/workflows"
echo "# wf-legacy" > "$T1B_HOME/.claude/get-shit-done/workflows/wf-legacy.md"
T1B_OUT2="$(mktemp)"
if env -u VF_GSD_WORKFLOWS_DIR HOME="$T1B_HOME" VF_GSD_SKILLS_DIR="$T1B_HOME/empty-skills" VF_INDEX_OUT="$T1B_OUT2" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1 \
  && "$GREP" -q "## Workflows GSD (source secondaire)" "$T1B_OUT2" && "$GREP" -q "wf-legacy" "$T1B_OUT2"; then
  ok "T1b workflows : legacy get-shit-done/workflows/ sous \$HOME détecté (repli)"
else
  ko "T1b workflows : legacy get-shit-done/workflows/ sous \$HOME non détecté"
fi
rm -f "$T1B_OUT" "$T1B_OUT2"; rm -rf "$T1B_HOME"

# T1c (DISCRIMINANT — D1) : $HOME vide, payload projet-local (cwd) sous .claude/gsd-core/workflows/.
T1C_HOME="$(mktemp -d)"
T1C_PROJ="$(mktemp -d)"
mkdir -p "$T1C_PROJ/.claude/gsd-core/workflows" "$T1C_HOME/empty-skills"
echo "# wf-proj" > "$T1C_PROJ/.claude/gsd-core/workflows/wf-proj.md"
T1C_OUT="$(mktemp)"
if ( cd "$T1C_PROJ" && env -u VF_GSD_WORKFLOWS_DIR HOME="$T1C_HOME" VF_GSD_SKILLS_DIR="$T1C_HOME/empty-skills" VF_INDEX_OUT="$T1C_OUT" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1 ) \
  && "$GREP" -q "## Workflows GSD (source secondaire)" "$T1C_OUT" && "$GREP" -q "wf-proj" "$T1C_OUT"; then
  ok "T1c (DISCRIMINANT) workflows : gsd-core/workflows/ projet-local trouvé, \$HOME vide"
else
  ko "T1c (DISCRIMINANT) workflows : cascade projet-local KO — implémentation \$HOME-only ?"
fi
rm -f "$T1C_OUT"; rm -rf "$T1C_HOME" "$T1C_PROJ"

# T1d : CLAUDE_CONFIG_DIR distinct de $HOME/.claude, aucun payload projet-local → résolu via elle.
T1D_HOME="$(mktemp -d)"
T1D_CCD="$(mktemp -d)"
mkdir -p "$T1D_HOME/.claude" "$T1D_HOME/empty-skills" "$T1D_CCD/gsd-core/workflows"
echo "# wf-ccd" > "$T1D_CCD/gsd-core/workflows/wf-ccd.md"
T1D_OUT="$(mktemp)"
if env -u VF_GSD_WORKFLOWS_DIR HOME="$T1D_HOME" CLAUDE_CONFIG_DIR="$T1D_CCD" VF_GSD_SKILLS_DIR="$T1D_HOME/empty-skills" VF_INDEX_OUT="$T1D_OUT" bash "$MOD/scripts/build-gsd-index.sh" >/dev/null 2>&1 \
  && "$GREP" -q "## Workflows GSD (source secondaire)" "$T1D_OUT" && "$GREP" -q "wf-ccd" "$T1D_OUT"; then
  ok "T1d workflows : résolution via CLAUDE_CONFIG_DIR"
else
  ko "T1d workflows : CLAUDE_CONFIG_DIR non honoré"
fi
rm -f "$T1D_OUT"; rm -rf "$T1D_HOME" "$T1D_CCD"

# ---------------------------------------------------------------------------
# T2 — ensure-deps.sh idempotent (dry-run, 2 runs, exit 0 aux deux)
# ---------------------------------------------------------------------------
VF_ENSURE_DRY_RUN=1 bash "$MOD/scripts/ensure-deps.sh" >/dev/null 2>&1
r1=$?
VF_ENSURE_DRY_RUN=1 bash "$MOD/scripts/ensure-deps.sh" >/dev/null 2>&1
r2=$?
if [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ]; then
  ok "T2 idempotence : ensure-deps dry-run run1=$r1 run2=$r2 (no-op stable)"
else
  ko "T2 idempotence : exit run1=$r1 run2=$r2 (attendu 0/0)"
fi

# ---------------------------------------------------------------------------
# T2b — ensure-deps scopé (dry-run FORCÉ, sans réseau) — SCOPE-03
# ---------------------------------------------------------------------------
# VF_ENSURE_FORCE=1 (en plus de VF_ENSURE_DRY_RUN=1) court-circuite l'early-return de détection :
# les commandes scopées sont donc LOGUÉES même si GSD/Superpowers sont déjà installés sur la machine
# (cas dev/CI courant — sans FORCE, l'early-return skip masquerait les flags → faux-négatif).
# FORCE ne fait que loguer via run_cmd : AUCUN appel réseau ni install (dry-run uniquement).
ENS="$MOD/scripts/ensure-deps.sh"

# (user|project|local) → flags GSD + Superpowers attendus.
# user → --global / --scope user ; project → --local / --scope project ; local → --local / --scope local.
assert_scope() {
  local scope="$1" gsd_flag="$2" sp_flag="$3" out
  out=$(VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 VF_SCOPE="$scope" bash "$ENS" 2>&1)
  if echo "$out" | "$GREP" -q -- "$gsd_flag" && echo "$out" | "$GREP" -q -- "$sp_flag"; then
    ok "T2b scope=$scope : GSD $gsd_flag + Superpowers $sp_flag logués (dry-run forcé)"
  else
    ko "T2b scope=$scope : flags attendus absents ($gsd_flag / $sp_flag)"
  fi
}

assert_scope user    "--global" "--scope user"
assert_scope project "--local"  "--scope project"
assert_scope local   "--local"  "--scope local"

# Rétro-compat : sans VF_SCOPE (dry-run forcé) → défaut LEGACY user (--global / --scope user).
out_default=$(VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 bash "$ENS" 2>&1)
if echo "$out_default" | "$GREP" -q -- "--global" && echo "$out_default" | "$GREP" -q -- "--scope user"; then
  ok "T2b rétro-compat : sans VF_SCOPE → --global + --scope user (défaut LEGACY)"
else
  ko "T2b rétro-compat : défaut LEGACY user attendu (--global / --scope user)"
fi

# Validation : scope invalide rejeté AVANT effet de bord (exit≠0). Pas besoin de FORCE (validation en tête).
VF_ENSURE_DRY_RUN=1 VF_SCOPE=bogus bash "$ENS" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  ok "T2b validation : VF_SCOPE=bogus rejeté (exit≠0 avant effet de bord)"
else
  ko "T2b validation : VF_SCOPE=bogus aurait dû être rejeté (exit≠0)"
fi

# ---------------------------------------------------------------------------
# T2c/T2d/T2e/T2f — piège n°1, nettoyage legacy (ADR-031), garde Node ≥ 22, dual-layout (D1)
# ---------------------------------------------------------------------------

# T2c — detect_gsd() ne contient plus AUCUN test PATH (piège n°1 neutralisé — preuve directe).
if [ "$("$GREP" -c 'command -v gsd' "$ENS")" -eq 0 ]; then
  ok "T2c piège n°1 : aucun 'command -v gsd' dans ensure-deps.sh"
else
  ko "T2c piège n°1 : 'command -v gsd' encore présent dans ensure-deps.sh"
fi

# T2d — detect_gsd_legacy() : les 3 commandes de nettoyage sont LOGUÉES, jamais exécutées (ADR-031).
T2D_HOME="$(mktemp -d)"
mkdir -p "$T2D_HOME/.claude/get-shit-done"
echo "1.42.3" > "$T2D_HOME/.claude/get-shit-done/VERSION"
T2D_BIN="$(mktemp -d)"
T2D_TRACE_FILE="$(mktemp)"
cat > "$T2D_BIN/npm" <<'SH'
#!/usr/bin/env bash
echo "npm $*" >> "$T2D_TRACE_FILE"
exit 1
SH
cat > "$T2D_BIN/node" <<'SH'
#!/usr/bin/env bash
echo "node $*" >> "$T2D_TRACE_FILE"
exit 1
SH
chmod +x "$T2D_BIN/npm" "$T2D_BIN/node"
T2D_OUT=$(env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE HOME="$T2D_HOME" PATH="$T2D_BIN:/usr/bin:/bin" T2D_TRACE_FILE="$T2D_TRACE_FILE" bash "$ENS" 2>&1)
if echo "$T2D_OUT" | "$GREP" -q "npm uninstall -g get-shit-done-cc" \
   && echo "$T2D_OUT" | "$GREP" -q "npm uninstall -g @gsd-build/sdk" \
   && echo "$T2D_OUT" | "$GREP" -q "rm -rf ~/.claude/get-shit-done" \
   && { [ ! -s "$T2D_TRACE_FILE" ] || ! "$GREP" -q "uninstall" "$T2D_TRACE_FILE"; }; then
  ok "T2d legacy cleanup : 3 commandes affichées (log), jamais exécutées (trace sans 'uninstall')"
else
  ko "T2d legacy cleanup : affichage ou non-exécution non prouvés"
fi
rm -rf "$T2D_HOME" "$T2D_BIN"; rm -f "$T2D_TRACE_FILE"

# T2e — Garde Node ≥ 22 : Node 18 détecté → npx jamais tenté, message Node ≥ 22 logué.
T2E_HOME="$(mktemp -d)"
T2E_BIN="$(mktemp -d)"
T2E_NPX_TRACE="$(mktemp)"
cat > "$T2E_BIN/npm" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$T2E_BIN/node" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "-e" ]; then echo "18"; elif [ "$1" = "--version" ]; then echo "v18.0.0"; fi
exit 0
SH
cat > "$T2E_BIN/npx" <<'SH'
#!/usr/bin/env bash
echo "npx-invoked $*" >> "$T2E_NPX_TRACE"
exit 0
SH
chmod +x "$T2E_BIN/npm" "$T2E_BIN/node" "$T2E_BIN/npx"
T2E_OUT=$(env -u VF_ENSURE_FORCE HOME="$T2E_HOME" PATH="$T2E_BIN:/usr/bin:/bin" T2E_NPX_TRACE="$T2E_NPX_TRACE" VF_ENSURE_DRY_RUN=1 bash "$ENS" 2>&1)
if echo "$T2E_OUT" | "$GREP" -q "Node ≥ 22" && [ ! -s "$T2E_NPX_TRACE" ]; then
  ok "T2e garde Node : Node 18 détecté → npx jamais invoqué, message Node ≥ 22 logué"
else
  ko "T2e garde Node : garde absente ou npx invoqué malgré Node <22"
fi
rm -rf "$T2E_HOME" "$T2E_BIN"; rm -f "$T2E_NPX_TRACE"

# T2f (DISCRIMINANT — D1) : $HOME vide, payload gsd-core posé à l'échelle PROJET (cwd) →
# detect_gsd() doit renvoyer vrai (pas de tentative de réinstall). Doit échouer avec une
# implémentation qui ne teste que $HOME/.claude/gsd-core/VERSION.
T2F_HOME="$(mktemp -d)"
T2F_PROJ="$(mktemp -d)"
mkdir -p "$T2F_PROJ/.claude/gsd-core"
echo "1.8.0" > "$T2F_PROJ/.claude/gsd-core/VERSION"
T2F_OUT=$(cd "$T2F_PROJ" && env -u VF_ENSURE_FORCE HOME="$T2F_HOME" VF_ENSURE_DRY_RUN=1 bash "$ENS" 2>&1)
if echo "$T2F_OUT" | "$GREP" -q "GSD déjà présent" && ! echo "$T2F_OUT" | "$GREP" -q "GSD absent — installation"; then
  ok "T2f (DISCRIMINANT) : gsd-core projet-local détecté, \$HOME vide — pas de tentative de réinstall"
else
  ko "T2f (DISCRIMINANT) : détection projet-local KO — implémentation \$HOME-only ?"
fi
rm -rf "$T2F_HOME" "$T2F_PROJ"

# ---------------------------------------------------------------------------
# T3 — AGENT.md : ≤250L, table d'intentions fournie, zéro verbe supprimé
# ---------------------------------------------------------------------------
# v2.0.0 : la table de l'agent route une intention vers une BRIQUE gsd directe (plus de
# colonne verbe). La couverture se mesure sur les lignes d'intentions NL ; la régression
# à guetter est la résurrection d'un verbe supprimé.
agent_lines=$(wc -l < "$AGENT_FILE" | tr -d ' ')
intent_lines=$("$GREP" -E '^\|' "$AGENT_FILE" \
  | "$GREP" -v -E '^\|[[:space:]]*-{2,}' \
  | "$GREP" -v -iE '^\|[[:space:]]*Intention' \
  | "$GREP" -c '|')
agent_deleted="$(deleted_hits "$AGENT_FILE")"

t3_ok=1
[ "$agent_lines" -le 250 ] || { ko "T3 agent : AGENT.md = ${agent_lines}L (>250)"; t3_ok=0; }
[ "${intent_lines:-0}" -ge 11 ] || { ko "T3 agent : $intent_lines ligne(s) d'intentions NL (<11)"; t3_ok=0; }
[ -z "$agent_deleted" ] || { ko "T3 agent : AGENT.md référence un verbe supprimé — $agent_deleted"; t3_ok=0; }
[ "$t3_ok" -eq 1 ] && ok "T3 agent : ${agent_lines}L (≤250), $intent_lines intentions NL (≥11), aucun verbe supprimé"

# ---------------------------------------------------------------------------
# T4 — Mapping des skills non orphelin (robuste à un index vide via fixture)
# ---------------------------------------------------------------------------
# Index de référence des cibles gsd-* : index disque s'il contient des skills,
# sinon fixture embarquée pour ne jamais produire de faux négatif.
INDEX_DISK="$REFS_DIR/gsd-skills-index.md"
index_has_skills=0
if [ -f "$INDEX_DISK" ] && "$GREP" -Eq 'gsd-[a-z0-9-]+' "$INDEX_DISK"; then
  index_has_skills=1
fi
# Fixture canonique : les cibles portées par les skills du module (vf-auto) + le pipeline
# canonique. Elle sert quand l'index disque est absent (CI, poste sans GSD) ET quand l'index
# versionné est en retard sur la chaîne réelle — sans elle, la suite passe en local et échoue
# en CI (piège n° 1).
FIXTURE_TARGETS="gsd-discuss-phase gsd-plan-phase gsd-execute-phase gsd-quick gsd-fast \
gsd-verify-work gsd-code-review gsd-debug gsd-autonomous gsd-ship gsd-progress \
gsd-map-codebase gsd-new-project gsd-pause-work gsd-resume-work gsd-new-milestone \
gsd-complete-milestone gsd-docs-update"

# Vérifie qu'une cible gsd-X est connue (index disque ou fixture).
# Comparaison à frontière de mot : sans elle, « gsd-review » serait déclaré connu par la seule
# présence de « gsd-review-backlog » dans l'index.
target_known() {
  local t="$1"
  if [ "$index_has_skills" -eq 1 ]; then
    "$GREP" -qE -- "${t}([^a-z0-9-]|$)" "$INDEX_DISK" && return 0
  fi
  case " $FIXTURE_TARGETS " in *" $t "*) return 0 ;; esac
  return 1
}

orphans=0
checked=0
for skill_md in "$MOD"/skills/vf-*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  vfname="$(basename "$(dirname "$skill_md")")"
  # En lab, skills/ est partagé : on n'audite que les skills de ce module (OWNED_SKILLS).
  owned_skill "$vfname" || continue
  # Extrait toutes les cibles référencées dans le corps : gsd-X, agents d'équipe.
  targets=$("$GREP" -Eo 'gsd-[a-z0-9-]+' "$skill_md" | sort -u)
  if [ -z "$targets" ]; then
    # vf-dev = incarnation de l'agent vibeflow-dev → cible agent acceptée.
    if "$GREP" -Eq 'vibeflow-dev|vf-dev-manager' "$skill_md"; then
      checked=$((checked+1))
      continue
    fi
    ko "T4 mapping : $vfname ne référence aucune cible (orphelin)"
    orphans=$((orphans+1))
    continue
  fi
  for t in $targets; do
    case "$t" in
      gsd-sdk) : ;;                  # CLI d'état GSD — pas un skill
      gsd-*)
        if ! target_known "$t"; then
          ko "T4 mapping : $vfname → cible orpheline « $t » (absente de l'index/fixture)"
          orphans=$((orphans+1))
        fi
        ;;
    esac
  done
  checked=$((checked+1))
done

if [ "$orphans" -eq 0 ] && [ "$checked" -ge 2 ]; then
  src=$([ "$index_has_skills" -eq 1 ] && echo "index disque" || echo "fixture canonique")
  ok "T4 mapping : $checked skill(s) du module — aucun orphelin (source: $src)"
elif [ "$orphans" -eq 0 ]; then
  ko "T4 mapping : $checked skill(s) audités (<2 — vf-auto ou vf-dev manquant ?)"
fi

# ---------------------------------------------------------------------------
# T5 — Densité par wc -l UNIQUEMENT (jamais le contrôleur de taille générique sur .md)
# ---------------------------------------------------------------------------
if [ "$agent_lines" -le 250 ]; then
  ok "T5 densité agent : AGENT.md = ${agent_lines}L (≤250)"
else
  ko "T5 densité agent : AGENT.md = ${agent_lines}L (>250)"
fi

skills_over=0
skills_total=0
for f in "$MOD"/skills/vf-*/SKILL.md; do
  [ -f "$f" ] || continue
  # En lab, skills/ est partagé entre modules : on n'audite que nos skills (OWNED_SKILLS).
  owned_skill "$(basename "$(dirname "$f")")" || continue
  skills_total=$((skills_total+1))
  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -gt 500 ]; then
    ko "T5 densité skill : $(basename "$(dirname "$f")")/SKILL.md = ${n}L (>500)"
    skills_over=$((skills_over+1))
  fi
done
if [ "$skills_over" -eq 0 ]; then
  ok "T5 densité skills : $skills_total skill(s) du module tous ≤500L"
fi

# ---------------------------------------------------------------------------
# T6 — Install end-to-end via vibeflow-update.sh (best-effort, SKIP sinon)
# ---------------------------------------------------------------------------
INSTALLER="$REPO/_internal/vibeflow-update.sh"
if [ ! -f "$INSTALLER" ]; then
  skip "T6 install e2e : installeur introuvable ($INSTALLER)"
elif ! "$GREP" -q -- '-references' "$INSTALLER"; then
  skip "T6 install e2e : installeur ne câble pas encore la copie references agent (D7)"
else
  LAB="$(mktemp -d)"
  CACHE="$LAB/.vibeflow-cache"
  mkdir -p "$CACHE/dev-orchestrator"
  cp -r "$MOD/." "$CACHE/dev-orchestrator/" 2>/dev/null || true
  # Lance l'install dans le lab temporaire (VIBEFLOW_CACHE pointe sur le faux cache).
  if (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1); then
    miss=0
    [ -f "$LAB/.claude/agents/dev-orchestrator.md" ] || { ko "T6 install : .claude/agents/dev-orchestrator.md manquant"; miss=1; }
    for ref in GSD-PIPELINE.md gsd-skills-index.md intent-routing.md mission-contracts.md; do
      [ -f "$LAB/.claude/agents/dev-orchestrator-references/$ref" ] || { ko "T6 install : references/$ref manquant"; miss=1; }
    done
    for sk in vf-auto vf-dev; do
      [ -f "$LAB/.claude/skills/$sk/SKILL.md" ] || { ko "T6 install : .claude/skills/$sk/SKILL.md manquant"; miss=1; }
    done
    # La façade ne doit PAS être réinstallée : ni rule de préséance, ni vocabulary-map.
    [ ! -f "$LAB/.claude/rules/vf-verb-precedence.md" ] || { ko "T6 install : rules/vf-verb-precedence.md réinstallé (façade supprimée v2.0.0)"; miss=1; }
    [ ! -f "$LAB/.claude/agents/dev-orchestrator-references/vocabulary-map.md" ] || { ko "T6 install : vocabulary-map.md réinstallé (reframe supprimé v2.0.0)"; miss=1; }
    if [ "$miss" -eq 0 ]; then
      ok "T6 install e2e : agent + references + 2 skills présents, aucun artefact de façade"
    fi
  else
    skip "T6 install e2e : install non réalisable dans l'environnement (best-effort)"
  fi
  rm -rf "$LAB"
fi

# ---------------------------------------------------------------------------
# T7 — Garde-fou first-use présent dans AGENT.md (régression FIRST-01/FIRST-02)
# ---------------------------------------------------------------------------
# Présence du garde-fou sur fichier FILTRÉ des commentaires (hygiène grep-gate : un simple
# commentaire ne doit pas suffire). Pas de check densité ici (T3/T5 le font via wc -l).
has_marker=$("$GREP" -v '^#' "$AGENT_FILE" | "$GREP" -ci 'first-use\|premier usage')
has_detect=0; "$GREP" -q -- '.planning' "$AGENT_FILE" && has_detect=1
has_mapcb=0;  "$GREP" -q -- 'gsd-map-codebase' "$AGENT_FILE" && has_mapcb=1
has_noauto=$("$GREP" -v '^#' "$AGENT_FILE" | "$GREP" -ci 'new-project')

if [ "${has_marker:-0}" -ge 1 ] && [ "$has_detect" -eq 1 ] && [ "$has_mapcb" -eq 1 ] && [ "${has_noauto:-0}" -ge 1 ]; then
  ok "T7 first-use : garde-fou présent (détection .planning + cartographie proposée + new-project encadré)"
else
  ko "T7 first-use : garde-fou incomplet dans AGENT.md (marker=$has_marker detect=$has_detect map=$has_mapcb noauto=$has_noauto)"
fi

# ---------------------------------------------------------------------------
# T8 — Équipe de mission : 4 agents natifs conformes (spec 2026-07-09, ADR-044/029)
# ---------------------------------------------------------------------------
TEAM_AGENTS="vf-dev-manager vf-coder vf-reviewer vf-auditer"
WORKERS="vf-coder vf-reviewer vf-auditer"
t8_ok=1
for a in $TEAM_AGENTS; do
  f="$MOD/agents/$a.md"
  if [ ! -f "$f" ]; then ko "T8 agents : $a.md introuvable dans $MOD/agents/"; t8_ok=0; continue; fi
  for field in description model memory; do
    "$GREP" -q "^${field}:" "$f" || { ko "T8 agents : $a.md sans champ $field"; t8_ok=0; }
  done
  a_lines=$(wc -l < "$f" | tr -d ' ')
  [ "${a_lines:-999}" -le 250 ] || { ko "T8 agents : $a.md dépasse 250 lignes ($a_lines)"; t8_ok=0; }
done
[ "$t8_ok" -eq 1 ] && ok "T8 agents : 4 agents de l'équipe présents, frontmatter complet, ≤250L"

# T8b — vf-internal : présent sur les 3 workers, absent du manager (Pattern 12)
t8b_ok=1
for w in $WORKERS; do
  "$GREP" -q "^vf-internal: true" "$MOD/agents/$w.md" 2>/dev/null || { ko "T8b vf-internal manquant : $w"; t8b_ok=0; }
done
if "$GREP" -q "^vf-internal:" "$MOD/agents/vf-dev-manager.md" 2>/dev/null; then
  ko "T8b : vf-dev-manager déclaré vf-internal (doit rester exposé)"; t8b_ok=0
fi
[ "$t8b_ok" -eq 1 ] && ok "T8b vf-internal : workers internes marqués, manager exposé"

# T8c — check-agents.sh --strict (ADR-044) : contrôleur machine du conductor.
# Localisation best-effort : repo source (plugin/conductor/scripts/), puis lab installé
# (.claude/scripts/). Introuvable → SKIP (le module ne livre pas ce contrôleur).
CHECK_AGENTS=""
for cand in "$REPO/conductor/scripts/check-agents.sh" "$MOD/scripts/check-agents.sh" "$HOME/.claude/scripts/check-agents.sh"; do
  [ -f "$cand" ] && { CHECK_AGENTS="$cand"; break; }
done
if [ -z "$CHECK_AGENTS" ]; then
  skip "T8c check-agents : contrôleur introuvable (conductor non présent dans cette disposition)"
elif [ ! -d "$MOD/agents" ] || [ ! -f "$MOD/agents/vf-dev-manager.md" ]; then
  skip "T8c check-agents : agents/ du module introuvables"
else
  if bash "$CHECK_AGENTS" --strict --agents-dir="$MOD/agents" >/dev/null 2>&1; then
    ok "T8c check-agents : --strict vert sur les agents d'équipe (ADR-044)"
  else
    ko "T8c check-agents : --strict en échec sur $MOD/agents"
  fi
fi

# ---------------------------------------------------------------------------
# T9 — Contrats de mission : source unique + renvois (DRY) + digest
# ---------------------------------------------------------------------------
CONTRACTS="$REFS_DIR/mission-contracts.md"
if [ -f "$CONTRACTS" ]; then
  if "$GREP" -qi "Brief de mission" "$CONTRACTS" && "$GREP" -qi "Rapport de mission" "$CONTRACTS" \
     && "$GREP" -q "SEUIL_EQUIPE" "$CONTRACTS"; then
    ok "T9 contrats : mission-contracts.md présent (Brief + Rapport + SEUIL_EQUIPE)"
  else
    ko "T9 contrats : mission-contracts.md incomplet (Brief/Rapport/SEUIL_EQUIPE manquant)"
  fi
  # Digest de mission (manager → workers) : le contrat DIGEST doit être défini ici et
  # seulement ici (audit 2026-07-25 : sans lui, 100-200k tokens de relecture par étape).
  if "$GREP" -q "DIGEST" "$CONTRACTS" && "$GREP" -qi "Digest de mission" "$CONTRACTS"; then
    ok "T9 digest : contrat DIGEST défini dans mission-contracts.md"
  else
    ko "T9 digest : contrat DIGEST absent de mission-contracts.md"
  fi
  renvois=0
  "$GREP" -q "mission-contracts" "$AGENT_FILE" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/skills/vf-auto/SKILL.md" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/agents/vf-dev-manager.md" && renvois=$((renvois+1))
  if [ "$renvois" -eq 3 ]; then
    ok "T9 renvois : agent + vf-auto + manager renvoient aux contrats (3/3)"
  else
    ko "T9 renvois : $renvois/3 renvois vers mission-contracts.md"
  fi
else
  ko "T9 contrats : $CONTRACTS introuvable"
fi

# ---------------------------------------------------------------------------
# T10 — Détection mission (agent) + aiguillage taille (vf-auto)
# ---------------------------------------------------------------------------
if "$GREP" -q "vf-dev-manager" "$AGENT_FILE"; then
  ok "T10 agent : AGENT.md route les missions vers vf-dev-manager"
else
  ko "T10 agent : aucune mention de vf-dev-manager dans AGENT.md"
fi
if "$GREP" -q "SEUIL_EQUIPE" "$MOD/skills/vf-auto/SKILL.md" \
   && "$GREP" -q "vf-dev-manager" "$MOD/skills/vf-auto/SKILL.md"; then
  ok "T10 vf-auto : aiguillage taille présent (SEUIL_EQUIPE → vf-dev-manager)"
else
  ko "T10 vf-auto : aiguillage taille absent de vf-auto/SKILL.md"
fi

# ---------------------------------------------------------------------------
# T11 — Généricité : aucun renvoi vers un chemin absent d'un lab installé (DM5)
# ---------------------------------------------------------------------------
# Le module est distribué : ce qu'il livre ne doit référencer QUE des chemins qui existent
# chez l'utilisateur. Un renvoi vers `.planning/research/` ou `docs/_mission/` (dossiers du
# dépôt de développement, jamais installés) est un lien mort en lab — c'est le défaut réel,
# indépendamment du nom du projet qui l'a introduit.
#
# Périmètre BORNÉ au module : en lab, agents/ est partagé entre tous les modules installés.
# On n'audite que ce que ce module possède — son agent, ses references, ses 4 agents d'équipe.
t11_targets="$AGENT_FILE"
[ -d "$REFS_DIR" ] && t11_targets="$t11_targets $REFS_DIR"
for a in vf-dev-manager vf-coder vf-reviewer vf-auditer; do
  [ -f "$MOD/agents/$a.md" ] && t11_targets="$t11_targets $MOD/agents/$a.md"
done
# shellcheck disable=SC2086
if "$GREP" -rqE '\.planning/research/|docs/_mission' $t11_targets 2>/dev/null; then
  # shellcheck disable=SC2086
  hit=$("$GREP" -rlE '\.planning/research/|docs/_mission' $t11_targets 2>/dev/null | head -3 | tr '\n' ' ')
  ko "T11 généricité : renvoi vers un chemin non installé en lab — $hit"
else
  ok "T11 généricité : aucun renvoi vers un chemin absent d'un lab (périmètre borné au module)"
fi

# ---------------------------------------------------------------------------
# T12 — Les 2 skills survivants ont une description valide
# ---------------------------------------------------------------------------
# La description est le déclencheur natif du skill : elle doit exister, être substantielle
# (formulations réelles) et déclarer la portée d'invocation. Plus de contre-exemples croisés
# à vérifier — la façade qui les rendait nécessaires est morte.
t12_ok=1
for sk in $OWNED_SKILLS; do
  f="$MOD/skills/$sk/SKILL.md"
  if [ ! -f "$f" ]; then ko "T12 skills : $sk/SKILL.md introuvable"; t12_ok=0; continue; fi
  desc=$(awk '/^description:/{f=1;print;next} f&&/^[A-Za-z_-]+:/{exit} f&&/^---[[:space:]]*$/{exit} f{print}' "$f" | tr '\n' ' ')
  dlen=$(echo "$desc" | wc -c | tr -d ' ')
  [ "${dlen:-0}" -ge 120 ] || { ko "T12 skills : description de $sk trop courte (${dlen} car. — pas de formulations réelles ?)"; t12_ok=0; }
  echo "$desc" | "$GREP" -qi "Utiliser quand" || { ko "T12 skills : description de $sk sans déclencheur « Utiliser quand »"; t12_ok=0; }
  echo "$desc" | "$GREP" -qi "Invocable" || { ko "T12 skills : description de $sk sans portée d'invocation"; t12_ok=0; }
done
[ "$t12_ok" -eq 1 ] && ok "T12 skills : vf-auto et vf-dev — descriptions valides (déclencheur + portée)"

# ---------------------------------------------------------------------------
# T13 — La façade est morte (tests d'absence, v2.0.0)
# ---------------------------------------------------------------------------
t13_ok=1
# (a) Les artefacts de la façade n'existent plus.
[ ! -f "$REFS_DIR/vocabulary-map.md" ] || { ko "T13 façade : vocabulary-map.md existe encore ($REFS_DIR)"; t13_ok=0; }
[ ! -f "$MOD/rules/vf-verb-precedence.md" ] || { ko "T13 façade : rules/vf-verb-precedence.md existe encore"; t13_ok=0; }
# (b) Aucun dossier de verbe supprimé dans skills/ (source comme lab — un résidu d'upgrade
#     y serait une régression : le skill se re-déclencherait).
for v in $DELETED_VERBS; do
  [ ! -d "$MOD/skills/$v" ] || { ko "T13 façade : skills/$v/ existe encore (verbe supprimé)"; t13_ok=0; }
done
# (c) Aucun fichier du module ne référence un verbe supprimé ni vocabulary-map.
#     Périmètre borné au module (en lab, skills/ et agents/ sont partagés).
t13_files="$AGENT_FILE"
for a in $TEAM_AGENTS; do [ -f "$MOD/agents/$a.md" ] && t13_files="$t13_files $MOD/agents/$a.md"; done
for sk in $OWNED_SKILLS; do [ -f "$MOD/skills/$sk/SKILL.md" ] && t13_files="$t13_files $MOD/skills/$sk/SKILL.md"; done
for r in "$REFS_DIR"/*.md; do [ -f "$r" ] && t13_files="$t13_files $r"; done
# Source uniquement (jamais installés) : README + module.json.
[ -f "$MOD/README.md" ] && [ -f "$MOD/AGENT.md" ] && t13_files="$t13_files $MOD/README.md"
[ -f "$MOD/module.json" ] && t13_files="$t13_files $MOD/module.json"
for f in $t13_files; do
  hits="$(deleted_hits "$f")"
  [ -z "$hits" ] || { ko "T13 façade : $(basename "$f") référence un verbe supprimé — $hits"; t13_ok=0; }
  "$GREP" -q "vocabulary-map" "$f" 2>/dev/null && { ko "T13 façade : $(basename "$f") référence vocabulary-map"; t13_ok=0; }
done
[ "$t13_ok" -eq 1 ] && ok "T13 façade morte : artefacts absents, aucun dossier ni référence de verbe supprimé"

# ---------------------------------------------------------------------------
# T14 — Exhaustivité du routage (carte intention → brique)
# ---------------------------------------------------------------------------
# Chaque skill gsd-* de l'index factuel est routé par intent-routing.md — la carte est la
# SEULE source de routage (spec 2026-07-25) et n'a plus de colonne verbe : la vérification
# porte sur la présence de la brique dans la carte, à frontière de mot.
t14_fail=0
if [ ! -f "$ROUTING" ]; then
  ko "T14 exhaustivité : $ROUTING introuvable"; t14_fail=$((t14_fail+1))
else
  # Plancher anti-test-vacant : une carte qui ne route presque rien = parsing mort ou carte
  # vidée, pas « tout va bien ».
  routed_count=$("$GREP" -Eo 'gsd-[a-z0-9-]+' "$ROUTING" | sort -u | wc -l | tr -d ' ')
  if [ "${routed_count:-0}" -lt 30 ]; then
    ko "T14 exhaustivité : la carte ne route que $routed_count brique(s) gsd-* (<30 — carte vidée ?)"
    t14_fail=$((t14_fail+1))
  fi
  # Comparaison sur les lignes « | gsd-… | » de l'index (évite les faux positifs gsd-index/gsd-sdk).
  if [ -f "$INDEX_DISK" ]; then
    indexed=$("$GREP" -Eo '^\|[[:space:]]*`?gsd-[a-z0-9-]+' "$INDEX_DISK" | "$GREP" -Eo 'gsd-[a-z0-9-]+' | sort -u)
  else
    indexed=""
  fi
  # Une brique est « routée » si la carte la cite — OU si un skill survivant du module la
  # porte lui-même (vf-auto → gsd-autonomous : la carte route « fais tout » vers le skill,
  # qui invoque la brique) — OU si elle est déléguée au module design (la carte route
  # l'intention design vers vf-design/vibeflow-design, qui pilote gsd-ui-phase/gsd-ui-review
  # en interne ; les auditer ici ferait rougir la suite pour un routage qui existe ailleurs).
  DESIGN_DELEGATED="gsd-ui-phase gsd-ui-review"
  brick_routed() {
    local s="$1"
    "$GREP" -qE -- "${s}([^a-z0-9-]|$)" "$ROUTING" && return 0
    for sk in $OWNED_SKILLS; do
      [ -f "$MOD/skills/$sk/SKILL.md" ] && "$GREP" -qE -- "${s}([^a-z0-9-]|$)" "$MOD/skills/$sk/SKILL.md" && return 0
    done
    case " $DESIGN_DELEGATED " in *" $s "*) return 0 ;; esac
    return 1
  }
  if [ -z "$indexed" ]; then
    skip "T14 exhaustivité : index factuel vide — GSD non installé (pas un échec)"
  else
    missing_routed=""
    n_indexed=0
    for s in $indexed; do
      n_indexed=$((n_indexed+1))
      # Frontière de mot : « gsd-review » ne doit pas être déclaré routé par « gsd-review-backlog ».
      brick_routed "$s" || missing_routed="$missing_routed $s"
    done
    if [ -n "$missing_routed" ]; then
      ko "T14 exhaustivité : skill(s) de l'index non routé(s) par intent-routing.md —$missing_routed"
      t14_fail=$((t14_fail+1))
    else
      ok "T14 exhaustivité : $n_indexed skill(s) de l'index tous routés par intent-routing.md"
    fi
  fi
  [ "$t14_fail" -eq 0 ] && [ "${routed_count:-0}" -ge 30 ] && ok "T14 plancher : $routed_count briques gsd-* distinctes routées (≥30)"
fi

# ---------------------------------------------------------------------------
# T15 — Pipelining N/N+1 : modélisation fine du DAG (audit 2026-07-25)
# ---------------------------------------------------------------------------
# mission-flow.md doit porter la modélisation 3-nœuds-par-étape (discuss/plan/execute) avec la
# règle de provisoire ; vf-dev-manager.md doit porter la consigne compacte et y renvoyer.
MFLOW="$REFS_DIR/mission-flow.md"
if [ -f "$MFLOW" ]; then
  if "$GREP" -qi 'provisoire' "$MFLOW" && "$GREP" -qE 'discuss\(N\+1\)' "$MFLOW"; then
    ok "T15 pipelining : mission-flow.md modélise N/N+1 (discuss(N+1) + règle de provisoire)"
  else
    ko "T15 pipelining : modélisation N/N+1 absente de mission-flow.md (provisoire / discuss(N+1))"
  fi
  MGR="$MOD/agents/vf-dev-manager.md"
  if [ -f "$MGR" ] && "$GREP" -qi 'pipelining' "$MGR" && "$GREP" -qi 'provisoire' "$MGR" \
     && "$GREP" -q 'mission-flow' "$MGR"; then
    ok "T15 pipelining : vf-dev-manager.md porte la consigne et renvoie à mission-flow.md"
  else
    ko "T15 pipelining : consigne pipelining/provisoire ou renvoi mission-flow absent de vf-dev-manager.md"
  fi
else
  ko "T15 pipelining : $MFLOW introuvable"
fi

# ---------------------------------------------------------------------------
# T16 — Doctrine d'ingestion (phase 13, BRDG-01/BRDG-03)
# ---------------------------------------------------------------------------
# ingestion-flow.md doit porter le script, ses 3 exits, le schéma manifest et les 4 garde-fous
# textuellement ; AGENT.md doit y renvoyer en Références (gabarit exact de T15/T9).
IFLOW="$REFS_DIR/ingestion-flow.md"
if [ ! -f "$IFLOW" ]; then
  ko "T16 ingestion : $IFLOW introuvable"
else
  t16_ok=1
  "$GREP" -q "discover-unintegrated-docs.sh" "$IFLOW" || { ko "T16 ingestion : script non nommé dans ingestion-flow.md"; t16_ok=0; }
  "$GREP" -q "exit 0" "$IFLOW" || { ko "T16 ingestion : exit 0 non documenté"; t16_ok=0; }
  "$GREP" -q "exit 3" "$IFLOW" || { ko "T16 ingestion : exit 3 non documenté"; t16_ok=0; }
  "$GREP" -q "exit 64" "$IFLOW" || { ko "T16 ingestion : exit 64 non documenté"; t16_ok=0; }
  "$GREP" -q "type: SPEC" "$IFLOW" || { ko "T16 ingestion : schéma manifest (type: SPEC) absent"; t16_ok=0; }
  "$GREP" -q "BLOCKER" "$IFLOW" || { ko "T16 ingestion : garde-fou BLOCKER absent"; t16_ok=0; }
  "$GREP" -q "ADR-031" "$IFLOW" || { ko "T16 ingestion : garde-fou ADR-031 absent"; t16_ok=0; }
  "$GREP" -q -e "--mode merge" "$IFLOW" || { ko "T16 ingestion : garde-fou --mode merge absent"; t16_ok=0; }
  "$GREP" -qE "cap 50|50 doc" "$IFLOW" || { ko "T16 ingestion : garde-fou cap 50 absent"; t16_ok=0; }
  "$GREP" -q "ingestion-flow" "$AGENT_FILE" || { ko "T16 ingestion : AGENT.md ne renvoie pas vers ingestion-flow.md"; t16_ok=0; }
  [ "$t16_ok" -eq 1 ] && ok "T16 ingestion : ingestion-flow.md complet (script, 3 exits, manifest, 4 garde-fous), AGENT.md y renvoie"
fi

# ---------------------------------------------------------------------------
# T17 — Câblage du routage d'ingestion (AGENT.md + intent-routing.md)
# ---------------------------------------------------------------------------
t17_ok=1
if "$GREP" -q "ingestion-flow" "$AGENT_FILE" \
   && ("$GREP" -q "gsd-ingest-docs" "$AGENT_FILE" || "$GREP" -q "gsd-import" "$AGENT_FILE"); then
  :
else
  ko "T17 routage : AGENT.md sans ligne d'intention d'ingestion explicite"; t17_ok=0
fi
if [ -f "$ROUTING" ]; then
  routing_gsd=$("$GREP" -c "gsd-ingest-docs" "$ROUTING")
  routing_iflow=$("$GREP" -c "ingestion-flow" "$ROUTING")
  { [ "${routing_gsd:-0}" -ge 1 ] && [ "${routing_iflow:-0}" -ge 1 ]; } || { ko "T17 routage : intent-routing.md sans ligne enrichie (gsd-ingest-docs + ingestion-flow)"; t17_ok=0; }
else
  ko "T17 routage : $ROUTING introuvable"; t17_ok=0
fi
[ "$t17_ok" -eq 1 ] && ok "T17 routage : AGENT.md + intent-routing.md câblent l'intention d'ingestion"

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
