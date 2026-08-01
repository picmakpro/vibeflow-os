#!/usr/bin/env bash
# test-dev-orchestrator.sh — Suite de vérification du module dev-orchestrator (VFDO)
#
# Couvre le modèle agentique (spec 2026-07-25-suppression-facade-vf-design.md) + les acquis :
#   T1  — build-gsd-index.sh génère un index NON VIDE depuis les skills GSD installés
#         (SKIP explicite si aucun skill gsd-* présent sur la machine).
#   T2  — ensure-deps.sh idempotent (2 runs en dry-run = no-op, exit 0 aux deux).
#   T2b — ensure-deps scopé (dry-run forcé, sans réseau) — SCOPE-03.
#   T2g — --migrate-engine (VFDO-19-02, D-06) atteint le bloc d'install npx sur un état legacy ;
#         sans le flag, aucun appel npx et le skip historique n'apparaît plus (3 sous-cas).
#   T2h — Chaînage MCP de bout en bout (D-06/D-09) : --migrate-engine enchaîne install PUIS
#         patch_gsd_executor_mcp() dans le même run (SKIP si python3 absent).
#   T2i — npm_pkg_installed_globally() confirme installé → les 2 lignes uninstall apparaissent.
#   T2j — npm_pkg_installed_globally() confirme absent → aucune ligne uninstall, arborescence
#         vide + rm -rf restent (D-08.1/D-08.2).
#   T2k — piège de séquencement (D-08.3) : le VERSION legacy capturé AVANT l'install survit à sa
#         propre suppression par l'installeur amont — le message de nettoyage sort quand même.
#   T2l — robustesse VERSION legacy hostile post-revue (T-19-01-01) : sanitize_version() borne la
#         lecture et neutralise substitution de commande / octet de contrôle / longueur excessive
#         avant tout affichage (miroir du Cas 13 de test-check-gsd-engine.sh).
#   T2m — mandat n2-bis : --verify (ligne ~409 de patch_gsd_executor_mcp()) porte --force comme
#         l'injection (ligne ~394) — un écart réel (rc=1) est détecté et relayé fort dans le
#         chaînage RÉEL du bootstrap (jamais un appel manuel à inject-mcp-tools.sh --force --verify).
#   T2n — mandat n3 (mutation survivante Phase 19, autre moitié du contrat F13) : rc=3 (INDÉTERMINÉ,
#         rien à comparer — pas de .mcp.json) ne lève JAMAIS d'alarme ensure-deps, seulement un log
#         informatif — vérifié dans le même chaînage RÉEL que T2m, en discriminant le canal
#         ("[ensure-deps] ERROR:") du texte enfant cité (qui porte légitimement son propre "ERROR:").
#   T3  — AGENT.md : ≤250L, table d'intentions fournie (≥11 lignes NL) et AUCUNE référence
#         à un verbe supprimé (la façade des 29 verbes est morte — elle ne ressuscite pas).
#   T4  — Chaque skill du module mappe vers une cible existante (aucun orphelin) :
#         gsd-X vérifié contre gsd-skills-index.md (fixture de secours si index vide).
#   T4b — Non-régression : aucune occurrence vivante de gsd-sdk dans skills/ ou references/
#         (Phase 11, 11-02 — migré vers gsd-tools).
#   T4c — Renommage de la whitelist T4 effectif : gsd-tools référencé par vf-auto/SKILL.md
#         et accepté sans orphelin (pas un simple ajout à côté de l'ancien nom).
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
#         intent-routing.md (carte intention → brique, sans colonne verbe), sauf exemption
#         explicite (INTENTIONALLY_UNROUTED — canal 4, ADR-057).
#   T14b — (DISCRIMINANT) l'exemption INTENTIONALLY_UNROUTED est bornée aux 3 noms exacts
#         (gsd-next, gsd-mempalace-capture, gsd-mempalace-recall), pas un passe-droit générique.
#   T15 — Pipelining N/N+1 (audit 2026-07-25) : mission-flow.md modélise le DAG fin
#         (discuss/plan/execute par étape, règle de provisoire) et vf-dev-manager.md
#         y renvoie avec la consigne compacte.
#   T16 — Doctrine d'ingestion (phase 13, BRDG-01/BRDG-03) : ingestion-flow.md existe et
#         porte le script, les 3 exits, le schéma manifest et les 4 garde-fous ; AGENT.md
#         y renvoie en Références.
#   T17 — Câblage du routage d'ingestion : AGENT.md porte une ligne d'intention explicite
#         (table Amont & cadrage) et intent-routing.md conserve sa ligne enrichie.
#   T20 — Gate ADR-044 réellement falsifiable (VFDO-17-03, D-12) : check-agents.sh --file sur
#         AGENT.md, triple assertion (exit 0, compte de warnings == baseline 3, présence des 3
#         types connus) — jamais un simple exit 0 (invocation à nu = vert vide sur ce dépôt).
#   T21 — Invariants SC5 par grep structurel (VFDO-17-03, D-15) : check-dev-bootstrap.sh et
#         check-doc-drift.sh n'ont aucun exit 1, aucune écriture hors /dev/null|&N|*TMP*, aucune
#         commande d'écriture directe, et tout mktemp est apparié à un trap ... EXIT.
#   T22 — Doctrine de sortie documentaire (phase 22, DOCF-01 → DOCF-04) : docs-flow.md existe,
#         traite les quatre familles, porte la ligne rouge --force (jamais mission, jamais
#         autonome) et la frontière vibeflow-os, câble --verify-only/--force dans la carte
#         d'intention ; AGENT.md et intent-routing.md y renvoient.
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
# Nettoyage UNIQUE et CUMULATIF : un seul `trap ... EXIT` pour toute la suite. Deux traps EXIT
# successifs ne se cumulent pas — le second REMPLACE le premier —, ce qui fuiterait les
# temporaires des tests précédents et violerait l'invariant que T21d impose aux autres scripts.
# Tout mktemp ultérieur s'enregistre via vf_tmp_track au lieu de reposer un trap.
VF_TMPS=("$INDEX_TMP")
vf_tmp_track() { VF_TMPS+=("$1"); }
trap 'rm -rf "${VF_TMPS[@]}" 2>/dev/null' EXIT

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

# Stubs claude + npm + node en tête de PATH : T2b observe les commandes LOGUÉES en dry-run —
# il ne doit dépendre d'AUCUN outillage réel de l'hôte. Sans stub, sur une machine sans claude
# (runner CI) ou sans node/npm, ensure-deps bascule en « étape manuelle » sans jamais loguer
# les flags scopés → les 4 assertions échouaient à tort. Le stub node répond « 22 » à la sonde
# de version majeure (garde Node ≥ 22 de ensure_gsd) ; npx n'est jamais exécuté en dry-run.
T2B_STUB="$(mktemp -d)"
printf '#!/bin/sh\nexit 0\n' > "$T2B_STUB/claude"
printf '#!/bin/sh\nexit 0\n' > "$T2B_STUB/npm"
printf '#!/bin/sh\necho 22\n' > "$T2B_STUB/node"
chmod +x "$T2B_STUB/claude" "$T2B_STUB/npm" "$T2B_STUB/node"

# (user|project|local) → flags GSD + Superpowers attendus.
# user → --global / --scope user ; project → --local / --scope project ; local → --local / --scope local.
assert_scope() {
  local scope="$1" gsd_flag="$2" sp_flag="$3" out
  out=$(PATH="$T2B_STUB:$PATH" VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 VF_SCOPE="$scope" bash "$ENS" 2>&1)
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
out_default=$(PATH="$T2B_STUB:$PATH" VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 bash "$ENS" 2>&1)
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

# T2d — detect_gsd_legacy() : le nettoyage est LOGUÉ, jamais exécuté (ADR-031).
# Sémantique CHANGÉE par le plan VFDO-19-02 (D-08.1) : les 2 lignes `npm uninstall -g` ne sont
# désormais proposées QUE si npm_pkg_installed_globally() confirme le paquet réellement présent
# en global. Le stub npm de ce cas répond ÉCHEC à TOUTE invocation (y compris la requête en
# lecture seule `npm ls -g --depth=0 <pkg>`) : sous la nouvelle logique, les 2 lignes uninstall
# NE DOIVENT PLUS apparaître — avant ce plan, ce même stub produisait les 3 lignes (aucun
# conditionnement). La ligne `rm -rf` et la nouvelle ligne d'arborescence vide restent affichées
# inconditionnellement. L'assertion de non-exécution (trace sans « uninstall ») est conservée à
# l'identique : seule la REQUÊTE en lecture seule `npm ls -g` est désormais réellement exécutée
# (P-01) — le node stub, lui, n'est jamais atteint (retour avant la garde Node/npm).
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
if ! echo "$T2D_OUT" | "$GREP" -q "npm uninstall -g get-shit-done-cc" \
   && ! echo "$T2D_OUT" | "$GREP" -q "npm uninstall -g @gsd-build/sdk" \
   && echo "$T2D_OUT" | "$GREP" -q "rm -rf ~/.claude/get-shit-done" \
   && echo "$T2D_OUT" | "$GREP" -q -- "-type d -empty" \
   && { [ ! -s "$T2D_TRACE_FILE" ] || ! "$GREP" -q "uninstall" "$T2D_TRACE_FILE"; }; then
  ok "T2d legacy cleanup (sémantique changée, D-08.1) : npm ls -g répond échec → aucune ligne uninstall, rm -rf + arborescence vide présents, trace sans 'uninstall'"
else
  ko "T2d legacy cleanup : conditionnement des lignes uninstall ou non-exécution non prouvés"
fi
rm -rf "$T2D_HOME" "$T2D_BIN"; rm -f "$T2D_TRACE_FILE"

# ---------------------------------------------------------------------------
# T2i — npm_pkg_installed_globally() confirme les 2 paquets installés → les 2 lignes uninstall
# apparaissent (D-08.1).
# ---------------------------------------------------------------------------
T2I_HOME="$(mktemp -d)"
mkdir -p "$T2I_HOME/.claude/get-shit-done"
echo "1.42.3" > "$T2I_HOME/.claude/get-shit-done/VERSION"
T2I_BIN="$(mktemp -d)"
cat > "$T2I_BIN/npm" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "ls" ] && [ "$2" = "-g" ]; then
  exit 0
fi
exit 1
SH
chmod +x "$T2I_BIN/npm"
T2I_OUT=$(env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE HOME="$T2I_HOME" PATH="$T2I_BIN:/usr/bin:/bin" bash "$ENS" 2>&1)
if echo "$T2I_OUT" | "$GREP" -q "npm uninstall -g get-shit-done-cc" \
   && echo "$T2I_OUT" | "$GREP" -q "npm uninstall -g @gsd-build/sdk"; then
  ok "T2i legacy cleanup : npm ls -g confirme les 2 paquets installés → les 2 lignes uninstall apparaissent"
else
  ko "T2i legacy cleanup : npm ls -g confirme installé mais les lignes uninstall n'apparaissent pas"
fi
rm -rf "$T2I_HOME" "$T2I_BIN"

# ---------------------------------------------------------------------------
# T2j — npm_pkg_installed_globally() confirme absent → les 2 lignes uninstall n'apparaissent
# pas, mais l'en-tête et la ligne d'arborescence vide restent (D-08.1/D-08.2).
# ---------------------------------------------------------------------------
T2J_HOME="$(mktemp -d)"
mkdir -p "$T2J_HOME/.claude/get-shit-done"
echo "1.42.3" > "$T2J_HOME/.claude/get-shit-done/VERSION"
T2J_BIN="$(mktemp -d)"
cat > "$T2J_BIN/npm" <<'SH'
#!/usr/bin/env bash
exit 1
SH
chmod +x "$T2J_BIN/npm"
T2J_OUT=$(env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE HOME="$T2J_HOME" PATH="$T2J_BIN:/usr/bin:/bin" bash "$ENS" 2>&1)
if ! echo "$T2J_OUT" | "$GREP" -q "npm uninstall -g get-shit-done-cc" \
   && ! echo "$T2J_OUT" | "$GREP" -q "npm uninstall -g @gsd-build/sdk" \
   && echo "$T2J_OUT" | "$GREP" -q "rm -rf ~/.claude/get-shit-done" \
   && echo "$T2J_OUT" | "$GREP" -q -- "-type d -empty"; then
  ok "T2j legacy cleanup : npm ls -g confirme absent → aucune ligne uninstall, rm -rf + arborescence vide présents"
else
  ko "T2j legacy cleanup : lignes uninstall présentes à tort, ou rm -rf/arborescence vide absent"
fi
rm -rf "$T2J_HOME" "$T2J_BIN"

# ---------------------------------------------------------------------------
# T2k (piège de séquencement, D-08.3) — un stub npx qui supprime lui-même le VERSION legacy
# pendant son exécution — reproduisant l'effet de bord réel de l'installeur amont — ne doit pas
# empêcher le message de nettoyage de sortir après coup. Assertion complémentaire : le fichier a
# bien disparu (sinon le cas serait tautologique, passant même avec une re-détection post-install).
# ---------------------------------------------------------------------------
T2K_HOME="$(mktemp -d)"
mkdir -p "$T2K_HOME/.claude/get-shit-done"
echo "1.42.3" > "$T2K_HOME/.claude/get-shit-done/VERSION"
T2K_PROJ="$(mktemp -d)"
T2K_BIN="$(mktemp -d)"
cat > "$T2K_BIN/npm" <<'SH'
#!/usr/bin/env bash
exit 1
SH
cat > "$T2K_BIN/node" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "-e" ]; then echo "22"; elif [ "$1" = "--version" ]; then echo "v22.0.0"; fi
exit 0
SH
cat > "$T2K_BIN/npx" <<SH2
#!/usr/bin/env bash
rm -f "$T2K_HOME/.claude/get-shit-done/VERSION"
exit 0
SH2
chmod +x "$T2K_BIN/npm" "$T2K_BIN/node" "$T2K_BIN/npx"
T2K_OUT=$(cd "$T2K_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u CLAUDE_CONFIG_DIR \
  HOME="$T2K_HOME" PATH="$T2K_BIN:/usr/bin:/bin" bash "$ENS" --migrate-engine 2>&1)
T2K_RC=$?
if [ ! -f "$T2K_HOME/.claude/get-shit-done/VERSION" ] \
   && echo "$T2K_OUT" | "$GREP" -q "Artefacts legacy détectés" \
   && [ "$T2K_RC" -eq 0 ]; then
  ok "T2k (piège de séquencement) : le VERSION legacy a disparu pendant l'install, le message de nettoyage sort quand même, exit 0"
else
  ko "T2k (piège de séquencement) : re-détection post-install a rendu le message inatteignable, ou VERSION legacy encore présent (rc=$T2K_RC)"
fi
rm -rf "$T2K_HOME" "$T2K_PROJ" "$T2K_BIN"

# ---------------------------------------------------------------------------
# T2l — robustesse VERSION legacy hostile (substitution de commande, octet de contrôle, >80 car.),
# post-revue T-19-01-01 : miroir exact du Cas 13 de test-check-gsd-engine.sh, appliqué cette fois
# à ensure-deps.sh (capture GSD_LEGACY_VERSION en tête de ensure_gsd(), lignes ~193/266). Un
# VERSION legacy contenant `$(whoami)` + un octet de contrôle + une longueur excessive ne doit
# JAMAIS apparaître tel quel dans le message loggé (ni expansion observable de l'utilisateur
# courant, ni octet de contrôle brut, ni ligne de signal non bornée).
# ---------------------------------------------------------------------------
T2L_HOME="$(mktemp -d)"
mkdir -p "$T2L_HOME/.claude/get-shit-done"
HOSTILE_T2L="$(printf '$(whoami)\x01'; i=0; while [ "$i" -lt 90 ]; do printf 'A'; i=$((i+1)); done)"
printf '%s' "$HOSTILE_T2L" > "$T2L_HOME/.claude/get-shit-done/VERSION"
T2L_PROJ="$(mktemp -d)"
# Stub claude : état legacy sans --migrate-engine ne touche jamais npm/node (retour précoce dans
# ensure_gsd()), mais ensure_superpowers() enchaîne quand même juste après dans main() — sans
# stub, une tentative RÉELLE d'install réseau (claude plugin install) polluerait $T2L_OUT avec
# des lignes non bornées, faussant l'assertion de longueur (hors-sujet de ce cas).
T2L_BIN="$(mktemp -d)"
printf '#!/bin/sh\nexit 0\n' > "$T2L_BIN/claude"
chmod +x "$T2L_BIN/claude"
T2L_OUT=$(cd "$T2L_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u CLAUDE_CONFIG_DIR \
  HOME="$T2L_HOME" PATH="$T2L_BIN:/usr/bin:/bin" bash "$ENS" 2>&1)
T2L_RC=$?
CURRENT_USER_T2L="$(whoami)"
t2l_has_ctrl=0
case "$T2L_OUT" in *$'\x01'*) t2l_has_ctrl=1 ;; esac
t2l_long_line=$(printf '%s\n' "$T2L_OUT" | awk '{ print length }' | sort -rn | head -n1)
if [ "$T2L_RC" -eq 0 ] && ! printf '%s' "$T2L_OUT" | "$GREP" -qF "$CURRENT_USER_T2L" \
   && [ "$t2l_has_ctrl" -eq 0 ] && [ "${t2l_long_line:-0}" -le 200 ]; then
  ok "T2l robustesse VERSION legacy hostile : rc=0, aucune expansion, aucun octet de contrôle, ligne bornée"
else
  ko "T2l robustesse VERSION legacy hostile : rc=$T2L_RC, long_line=$t2l_long_line, has_ctrl=$t2l_has_ctrl"
fi
rm -rf "$T2L_HOME" "$T2L_PROJ" "$T2L_BIN"

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
# T2g — --migrate-engine atteint le bloc d'install (D-06, SC3) ; sans lui, aucun appel npx et le
# skip historique n'apparaît plus sur legacy — c'est le silence fautif identifié par le rapport
# d'audit. Fixture : HOME ne portant QUE le VERSION legacy (aucun nouveau layout), exécutée
# depuis un répertoire de projet temporaire — jamais la racine du dépôt (patch_gsd_executor_mcp
# écrirait dans un ./.claude/agents/ réel sinon).
# ---------------------------------------------------------------------------
T2G_HOME="$(mktemp -d)"
mkdir -p "$T2G_HOME/.claude/get-shit-done"
echo "1.42.3" > "$T2G_HOME/.claude/get-shit-done/VERSION"
T2G_PROJ="$(mktemp -d)"
T2G_BIN="$(mktemp -d)"
cat > "$T2G_BIN/npm" <<'SH'
#!/usr/bin/env bash
exit 1
SH
cat > "$T2G_BIN/node" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "-e" ]; then echo "22"; elif [ "$1" = "--version" ]; then echo "v22.0.0"; fi
exit 0
SH
cat > "$T2G_BIN/claude" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$T2G_BIN/npx" <<'SH'
#!/usr/bin/env bash
echo "npx $*" >> "$T2G_TRACE_FILE"
exit 0
SH
chmod +x "$T2G_BIN/npm" "$T2G_BIN/node" "$T2G_BIN/claude" "$T2G_BIN/npx"

# Sous-cas A : --migrate-engine → trace npx non vide, paquet plafonné + --global.
T2GA_TRACE="$(mktemp)"; rm -f "$T2GA_TRACE"
T2GA_OUT=$(cd "$T2G_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u VF_ENSURE_MIGRATE_ENGINE -u CLAUDE_CONFIG_DIR \
  HOME="$T2G_HOME" PATH="$T2G_BIN:/usr/bin:/bin" T2G_TRACE_FILE="$T2GA_TRACE" bash "$ENS" --migrate-engine 2>&1)
if [ -s "$T2GA_TRACE" ] && "$GREP" -qF -- '@opengsd/gsd-core@^1' "$T2GA_TRACE" && "$GREP" -q -- '--global' "$T2GA_TRACE"; then
  ok "T2g sous-cas A : --migrate-engine atteint le bloc npx (paquet plafonné + --global)"
else
  ko "T2g sous-cas A : --migrate-engine n'a pas atteint le bloc npx attendu (trace=[$(cat "$T2GA_TRACE" 2>/dev/null)])"
fi
rm -f "$T2GA_TRACE"

# Sous-cas B : sans le flag → trace npx vide, pas de skip historique, message de migration explicite.
T2GB_TRACE="$(mktemp)"; rm -f "$T2GB_TRACE"
T2GB_OUT=$(cd "$T2G_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u VF_ENSURE_MIGRATE_ENGINE -u CLAUDE_CONFIG_DIR \
  HOME="$T2G_HOME" PATH="$T2G_BIN:/usr/bin:/bin" T2G_TRACE_FILE="$T2GB_TRACE" bash "$ENS" 2>&1)
if [ ! -s "$T2GB_TRACE" ] && ! echo "$T2GB_OUT" | "$GREP" -q "GSD déjà présent" \
   && echo "$T2GB_OUT" | "$GREP" -qi "migration disponible"; then
  ok "T2g sous-cas B : sans --migrate-engine, aucun appel npx, skip historique absent, migration annoncée"
else
  ko "T2g sous-cas B : le legacy sans flag a soit appelé npx, soit skippé silencieusement"
fi
rm -f "$T2GB_TRACE"

# Sous-cas C : VF_ENSURE_MIGRATE_ENGINE=1 (sans le flag) → même trace non vide que le sous-cas A.
T2GC_TRACE="$(mktemp)"; rm -f "$T2GC_TRACE"
T2GC_OUT=$(cd "$T2G_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE HOME="$T2G_HOME" \
  PATH="$T2G_BIN:/usr/bin:/bin" T2G_TRACE_FILE="$T2GC_TRACE" VF_ENSURE_MIGRATE_ENGINE=1 bash "$ENS" 2>&1)
if [ -s "$T2GC_TRACE" ] && "$GREP" -qF -- '@opengsd/gsd-core@^1' "$T2GC_TRACE"; then
  ok "T2g sous-cas C : VF_ENSURE_MIGRATE_ENGINE=1 équivalent au flag (trace npx non vide)"
else
  ko "T2g sous-cas C : VF_ENSURE_MIGRATE_ENGINE=1 n'a pas déclenché l'install"
fi
rm -f "$T2GC_TRACE"
rm -rf "$T2G_HOME" "$T2G_PROJ" "$T2G_BIN"

# ---------------------------------------------------------------------------
# T2h — Chaînage MCP de bout en bout (D-06/D-09, SC3) : --migrate-engine enchaîne install PUIS
# patch_gsd_executor_mcp() dans le MÊME run. SKIP explicite (jamais KO) si python3 absent —
# l'injecteur est best-effort par conception.
# ---------------------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  skip "T2h chaînage MCP : python3 absent — injecteur best-effort, cas non applicable"
else
  T2H_HOME="$(mktemp -d)"
  mkdir -p "$T2H_HOME/.claude/get-shit-done" "$T2H_HOME/.claude/agents"
  echo "1.42.3" > "$T2H_HOME/.claude/get-shit-done/VERSION"
  cat > "$T2H_HOME/.claude/agents/gsd-executor.md" <<'EOF'
---
name: gsd-executor
description: exécute les plans GSD avec commits atomiques
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*
model: opus
memory: project
---
corps
EOF
  T2H_PROJ="$(mktemp -d)"
  printf '%s\n' '{ "mcpServers": { "test-lab-mcp": {} } }' > "$T2H_PROJ/.mcp.json"
  T2H_BIN="$(mktemp -d)"
  cat > "$T2H_BIN/npm" <<'SH'
#!/usr/bin/env bash
exit 1
SH
  cat > "$T2H_BIN/node" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "-e" ]; then echo "22"; elif [ "$1" = "--version" ]; then echo "v22.0.0"; fi
exit 0
SH
  cat > "$T2H_BIN/claude" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat > "$T2H_BIN/npx" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$T2H_BIN/npm" "$T2H_BIN/node" "$T2H_BIN/claude" "$T2H_BIN/npx"

  (cd "$T2H_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u CLAUDE_CONFIG_DIR \
      HOME="$T2H_HOME" PATH="$T2H_BIN:/usr/bin:/bin" bash "$ENS" --migrate-engine >/dev/null 2>&1)

  if "$GREP" -m1 '^tools:' "$T2H_HOME/.claude/agents/gsd-executor.md" | "$GREP" -qF 'mcp__test-lab-mcp__*'; then
    ok "T2h chaînage MCP : --migrate-engine enchaîne install puis patch_gsd_executor_mcp dans le même run"
  else
    ko "T2h chaînage MCP : gsd-executor.md n'a pas reçu le serveur du lab après --migrate-engine"
  fi
  rm -rf "$T2H_HOME" "$T2H_PROJ" "$T2H_BIN"
fi

# ---------------------------------------------------------------------------
# T2m (mandat n2-bis, gap goal-backward Phase 19) — la vérification MCP (--verify, ligne ~409 de
# patch_gsd_executor_mcp()) doit porter --force comme l'injection (ligne ~394), sous peine de
# toujours écarter gsd-executor.md (pas de flag vf-mcp-consumer) et de rendre le garde-fou
# structurellement aveugle (rc=3 systématique, jamais 0 ni 1). Exercé dans le CHAÎNAGE RÉEL de
# patch_gsd_executor_mcp() — jamais par un appel manuel à inject-mcp-tools.sh --force --verify,
# qui ne prouverait rien sur le câblage de ensure-deps.sh.
#
# Pour produire un écart RÉEL (rc=1) de façon déterministe et portable (pas de dépendance à des
# bits de permission, contournés par root dans le conteneur Docker Linux du gate), le script
# d'injection est stubé : l'appel d'INJECTION (sans --verify) devient un no-op silencieux (simule
# une injection qui échoue sans lever d'alarme — le fichier agent reste inchangé), tandis que
# l'appel --verify exec le VRAI inject-mcp-tools.sh. Le seul code exercé côté ensure-deps.sh est
# donc bien le sien (patch_gsd_executor_mcp() réel), avec un verdict de vérification réel.
# ---------------------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  skip "T2m vérification réelle (--force sur --verify) : python3 absent — cas non applicable"
else
  T2M_HOME="$(mktemp -d)"
  mkdir -p "$T2M_HOME/.claude/agents"
  cat > "$T2M_HOME/.claude/agents/gsd-executor.md" <<'EOF'
---
name: gsd-executor
description: exécute les plans GSD avec commits atomiques
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*
model: opus
memory: project
---
corps
EOF

  T2M_PROJ="$(mktemp -d)"
  mkdir -p "$T2M_PROJ/.claude/gsd-core"
  echo "1.8.0" > "$T2M_PROJ/.claude/gsd-core/VERSION"
  printf '%s\n' '{ "mcpServers": { "test-lab-mcp": {} } }' > "$T2M_PROJ/.mcp.json"

  T2M_BIN="$(mktemp -d)"
  cat > "$T2M_BIN/claude" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "plugin" ] && [ "$2" = "list" ]; then echo superpowers; fi
exit 0
SH
  chmod +x "$T2M_BIN/claude"

  # Copie de ensure-deps.sh à côté d'un stub inject-mcp-tools.sh (résolution par dirname "$0") :
  # no-op silencieux hors --verify, VRAI injecteur en --verify.
  T2M_SCRIPTS="$(mktemp -d)"
  cp "$ENS" "$T2M_SCRIPTS/ensure-deps.sh"
  T2M_REAL_INJECTOR="$MOD/scripts/inject-mcp-tools.sh"
  cat > "$T2M_SCRIPTS/inject-mcp-tools.sh" <<EOF2
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = "--verify" ]; then exec bash "$T2M_REAL_INJECTOR" "\$@"; fi
done
exit 0
EOF2
  chmod +x "$T2M_SCRIPTS/inject-mcp-tools.sh"

  T2M_OUT=$(cd "$T2M_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u CLAUDE_CONFIG_DIR \
    HOME="$T2M_HOME" PATH="$T2M_BIN:/usr/bin:/bin" bash "$T2M_SCRIPTS/ensure-deps.sh" 2>&1)

  if echo "$T2M_OUT" | "$GREP" -qF "vérification MCP (--verify) signale un écart réel" \
     && echo "$T2M_OUT" | "$GREP" -qF "mcp__test-lab-mcp__*"; then
    ok "T2m vérification réelle : écart réel (injection silencieusement en échec) détecté et relayé fort dans le chaînage réel de patch_gsd_executor_mcp()"
  else
    ko "T2m vérification réelle : écart non détecté/relayé (verify pas atteint avec --force sur la même cible que l'injection ?) [out=$T2M_OUT]"
  fi
  rm -rf "$T2M_HOME" "$T2M_PROJ" "$T2M_BIN" "$T2M_SCRIPTS"
fi

# ---------------------------------------------------------------------------
# T2n (mandat n3, mutation survivante Phase 19) — l'AUTRE moitié du contrat F13 (ligne ~419 de
# patch_gsd_executor_mcp()) : rc=3 (INDÉTERMINÉ, rien à comparer) n'est PAS un écart — jamais
# d'ERROR pour une absence de cible, best-effort informatif seulement (log, jamais err). C'est le
# cas le plus courant en pratique (tout lab sans .mcp.json au bootstrap) : le défaut d'origine
# émettait un ERROR bruyant à chaque run sur exactement ce cas. Exercé dans le même CHAÎNAGE RÉEL
# que T2m (copie de ensure-deps.sh à côté du VRAI inject-mcp-tools.sh — aucun stub nécessaire ici,
# l'absence de .mcp.json produit nativement le rc=3 côté injecteur).
#
# Piège (identifié en revue, cf. mandat) : la ligne de détail relayée par ensure-deps cite verbatim
# la sortie enfant d'inject-mcp-tools.sh, laquelle porte légitimement SON PROPRE préfixe
# "[inject-mcp-tools] ERROR: ..." (l'injecteur qualifie son propre verdict INDÉTERMINÉ d'erreur
# lisible ; ce n'est pas la même chose qu'ensure-deps qui alarme). L'assertion doit donc discriminer
# la sévérité du CANAL ensure-deps ("[ensure-deps] ERROR:", jamais émis en rc=3) du texte enfant
# cité (présent, attendu, sans conséquence) — un simple grep sur le jeton nu "ERROR:" serait
# faux-rouge ici.
# ---------------------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  skip "T2n rc=3 non alarmant (contrat F13) : python3 absent — cas non applicable"
else
  T2N_HOME="$(mktemp -d)"
  mkdir -p "$T2N_HOME/.claude/agents"
  cat > "$T2N_HOME/.claude/agents/gsd-executor.md" <<'EOF'
---
name: gsd-executor
description: exécute les plans GSD avec commits atomiques
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*
model: opus
memory: project
---
corps
EOF

  T2N_PROJ="$(mktemp -d)"
  mkdir -p "$T2N_PROJ/.claude/gsd-core"
  echo "1.8.0" > "$T2N_PROJ/.claude/gsd-core/VERSION"
  # PAS de .mcp.json dans ce lab : exactement le cas « rien à comparer » (rc=3 côté injecteur).

  T2N_BIN="$(mktemp -d)"
  cat > "$T2N_BIN/claude" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "plugin" ] && [ "$2" = "list" ]; then echo superpowers; fi
exit 0
SH
  chmod +x "$T2N_BIN/claude"

  # Copie de ensure-deps.sh à côté du VRAI inject-mcp-tools.sh (résolution par dirname "$0") —
  # même protocole de chaînage réel que T2m, mais sans stub : le comportement natif de l'injecteur
  # sans .mcp.json produit déjà le rc=3 recherché.
  T2N_SCRIPTS="$(mktemp -d)"
  cp "$ENS" "$T2N_SCRIPTS/ensure-deps.sh"
  cp "$MOD/scripts/inject-mcp-tools.sh" "$T2N_SCRIPTS/inject-mcp-tools.sh"
  chmod +x "$T2N_SCRIPTS/inject-mcp-tools.sh"

  T2N_OUT=$(cd "$T2N_PROJ" && env -u VF_ENSURE_DRY_RUN -u VF_ENSURE_FORCE -u CLAUDE_CONFIG_DIR \
    HOME="$T2N_HOME" PATH="$T2N_BIN:/usr/bin:/bin" bash "$T2N_SCRIPTS/ensure-deps.sh" 2>&1)

  if echo "$T2N_OUT" | "$GREP" -qF "vérification MCP indéterminée" \
     && ! echo "$T2N_OUT" | "$GREP" -qF "[ensure-deps] ERROR:"; then
    ok "T2n rc=3 non alarmant : indéterminé (rien à comparer) relayé en log, jamais en alarme ensure-deps, dans le chaînage réel de patch_gsd_executor_mcp()"
  else
    ko "T2n rc=3 non alarmant : soit l'indéterminé n'a pas été atteint, soit une alarme ensure-deps a été émise à tort [out=$T2N_OUT]"
  fi
  rm -rf "$T2N_HOME" "$T2N_PROJ" "$T2N_BIN" "$T2N_SCRIPTS"
fi

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
auto_whitelist_hit=0   # T4c (ci-dessous) : preuve que le run réel de CETTE boucle a bien
                       # emprunté la branche whitelist pour gsd-tools — pas une réimplémentation.
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
      gsd-tools) auto_whitelist_hit=1 ;;  # CLI d'état GSD (gsd-core) — pas un skill (ex-gsd-sdk, Phase 11)
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
# T4b — Non-régression : aucune occurrence vivante de gsd-sdk (Phase 11, 11-02)
# ---------------------------------------------------------------------------
leftover=$("$GREP" -rln 'gsd-sdk' "$MOD/skills" "$MOD/references" 2>/dev/null || true)
if [ -z "$leftover" ]; then
  ok "T4b gsd-sdk : aucune occurrence vivante dans skills/ ou references/ (migré vers gsd-tools)"
else
  ko "T4b gsd-sdk : occurrence(s) résiduelle(s) — $leftover"
fi

# ---------------------------------------------------------------------------
# T4c — Renommage de la whitelist T4 effectif (dérivé du run RÉEL de la boucle T4
# ci-dessus, pas d'une réimplémentation indépendante qui accepterait gsd-tools par
# construction). Deux conditions cumulatives, chacune fait échouer si absente :
#   1. la boucle T4 a bien emprunté la branche whitelist pour gsd-tools
#      (auto_whitelist_hit, posé DANS le case réel, pas ici) ;
#   2. sans cette branche, gsd-tools ne serait PAS accepté par target_known() —
#      il n'est ni dans l'index disque ni dans la fixture. Sans ce 2e test, T4c
#      passerait même whitelist retirée, tant que l'index le connaîtrait par ailleurs.
# ---------------------------------------------------------------------------
if [ "$auto_whitelist_hit" -eq 1 ]; then
  if target_known "gsd-tools"; then
    ko "T4c whitelist : gsd-tools est connu via target_known (index/fixture) — le test ne peut plus discriminer la whitelist du renommage"
  else
    ok "T4c whitelist : gsd-tools vu dans le run T4 réel via la branche whitelist, et target_known() l'aurait rejeté sans elle (renommage effectif, pas tautologique)"
  fi
else
  ko "T4c whitelist : vf-auto/SKILL.md n'a pas déclenché la branche whitelist gsd-tools dans le run T4 (régression du plan 11-02)"
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
    for ref in GSD-PIPELINE.md gsd-skills-index.md intent-routing.md mission-contracts.md docs-flow.md; do
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
  # Une brique est « routée » SI ET SEULEMENT SI la carte la cite. Les deux replis historiques
  # (skill porteur du module, délégation design) ont été RETIRÉS le 2026-07-28 : mesurés sur les
  # 68 briques auditées, ils ne couvraient à eux deux AUCUNE brique que la carte ne couvrait déjà
  # (61 par la carte seule, 7 par la carte ET un SKILL.md, 0 par un repli seul). C'étaient des
  # gardes MORTES, et elles rendaient T14 insensible au retrait de l'une d'elles : un routage
  # supprimé de la carte restait vert tant qu'un SKILL.md citait le nom quelque part (dette
  # backlog ouverte en Phase 11). Leur suppression aligne le code sur la doctrine déjà écrite
  # ci-dessus — la carte est la SEULE source de routage. T14c verrouille le constat qui l'autorise.
  # Briques volontairement NON routées (canal 4, intent-routing.md) — sémantique différente de
  # DESIGN_DELEGATED : ces skills ne sont PAS considérés « routés », ils sont EXEMPTÉS de
  # l'obligation de routage. Toute nouvelle exception doit être écrite dans intent-routing.md
  # §Couverture ET ici (règle du fichier, canal 4).
  INTENTIONALLY_UNROUTED="gsd-next gsd-mempalace-capture gsd-mempalace-recall"
  is_intentionally_unrouted() {
    case " $INTENTIONALLY_UNROUTED " in *" $1 "*) return 0 ;; esac
    return 1
  }
  brick_routed() {
    local s="$1"
    "$GREP" -qE -- "${s}([^a-z0-9-]|$)" "$ROUTING"
  }
  if [ -z "$indexed" ]; then
    skip "T14 exhaustivité : index factuel vide — GSD non installé (pas un échec)"
  else
    missing_routed=""
    n_indexed=0
    for s in $indexed; do
      n_indexed=$((n_indexed+1))
      is_intentionally_unrouted "$s" && continue
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

  # -------------------------------------------------------------------------
  # T14b (DISCRIMINANT) — l'exemption INTENTIONALLY_UNROUTED est bornée aux 3 noms exacts,
  # pas un passe-droit générique. Fixture d'index injectée : gsd-next (exempté, canal 4) +
  # gsd-inconnu-xyz (ni exempté ni routé — doit être signalé manquant). Réutilise
  # is_intentionally_unrouted()/brick_routed() tels que définis et exécutés ci-dessus dans
  # CE run (pas une réimplémentation indépendante).
  # -------------------------------------------------------------------------
  fixture_indexed="gsd-next gsd-inconnu-xyz"
  fixture_missing=""
  for s in $fixture_indexed; do
    is_intentionally_unrouted "$s" && continue
    brick_routed "$s" || fixture_missing="$fixture_missing $s"
  done
  if echo "$fixture_missing" | "$GREP" -q 'gsd-inconnu-xyz' && ! echo "$fixture_missing" | "$GREP" -q 'gsd-next'; then
    ok "T14b (DISCRIMINANT) : gsd-next exempté (canal 4, non signalé) ; gsd-inconnu-xyz non exempté et non routé → signalé manquant"
  else
    ko "T14b (DISCRIMINANT) : exemption non bornée aux 3 noms exacts — missing=[$fixture_missing]"
  fi

  # -------------------------------------------------------------------------
  # T14c — Aucune brique ne dépend d'un repli disparu. Verrouille le constat qui a autorisé la
  # suppression des deux gardes mortes de brick_routed() : si une brique de l'index est citée
  # par un SKILL.md du module SANS l'être par la carte, la carte n'est plus la seule source de
  # routage et T14 vient de perdre un cas qu'il couvrait. Cet axe le dit AVANT que le trou ne
  # devienne un faux vert — c'est le filet qui remplace les replis, pas leur réintroduction.
  # -------------------------------------------------------------------------
  if [ -n "$indexed" ]; then
    orphan_fallback=""
    for s in $indexed; do
      is_intentionally_unrouted "$s" && continue
      brick_routed "$s" && continue
      for sk in $OWNED_SKILLS; do
        [ -f "$MOD/skills/$sk/SKILL.md" ] \
          && "$GREP" -qE -- "${s}([^a-z0-9-]|$)" "$MOD/skills/$sk/SKILL.md" \
          && { orphan_fallback="$orphan_fallback $s($sk)"; break; }
      done
    done
    if [ -n "$orphan_fallback" ]; then
      ko "T14c : brique(s) routée(s) par un SKILL.md mais ABSENTE(s) de la carte —$orphan_fallback (la carte doit rester la seule source)"
    else
      ok "T14c : aucune brique ne dépend d'un repli SKILL.md — la carte couvre tout ce qu'elle doit couvrir"
    fi
  fi
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
# T18 — Cloisonnement par tools (Pattern 12) : allowlist Agent(...) du manager (Phase 15, D-07)
# ---------------------------------------------------------------------------
# check-agents.sh NE LINTE PAS le contenu du champ tools: (vérifié empiriquement — une allowlist
# avec des noms inventés ou une parenthèse non fermée passe --strict en vert). Ces asserts sont
# donc la SEULE vérification machine du cloisonnement D-07 (Pattern A : imbrication
# manager→manager interdite) pour ce module.
DEVMGR="$MOD/agents/vf-dev-manager.md"
dev_tools_line() { "$GREP" -m1 '^tools:' "$1" 2>/dev/null; }
T18_ALLOWED="vf-coder vf-reviewer vf-auditer vf-test-orchestrator gsd-advisor-researcher \
general-purpose gsd-phase-researcher gsd-plan-checker gsd-planner gsd-pattern-mapper \
gsd-doc-verifier gsd-doc-writer gsd-doc-classifier gsd-doc-synthesizer gsd-roadmapper \
gsd-integration-checker vf-crafter vf-design-judge"

t18_ok=1
dmt="$(dev_tools_line "$DEVMGR")"
if [ -z "$dmt" ]; then
  ko "T18 cloisonnement : vf-dev-manager sans ligne tools: (hériterait de TOUT)"; t18_ok=0
else
  # Allowlist Agent(...) et non Agent nu : aucune occurrence de « Agent » qui ne soit pas
  # immédiatement suivie d'une parenthèse ouvrante (bare Agent = pas de cloisonnement).
  bare="$(echo "$dmt" | "$GREP" -oE 'Agent([^(]|$)')"
  [ -z "$bare" ] || { ko "T18 cloisonnement : vf-dev-manager a un Agent nu (pas d'allowlist)"; t18_ok=0; }
  echo "$dmt" | "$GREP" -qF 'Agent(' || { ko "T18 cloisonnement : aucune allowlist Agent( ) trouvée"; t18_ok=0; }
  # Chacun des 18 noms attendus, testé UN PAR UN (jamais un grep global satisfait par le premier).
  for name in $T18_ALLOWED; do
    echo "$dmt" | "$GREP" -qF -- "$name" || { ko "T18 cloisonnement : « $name » absent de l'allowlist du manager"; t18_ok=0; }
  done
  # Interdit structurel : vf-design-manager JAMAIS dans l'allowlist (imbrication manager→manager).
  # Piège : vf-design-judge contient la sous-chaîne « vf-design » — on teste le nom EXACT complet
  # « vf-design-manager », qui ne peut pas matcher « vf-design-judge » (suffixe différent).
  echo "$dmt" | "$GREP" -qF -- "vf-design-manager" && { ko "T18 cloisonnement : vf-design-manager présent dans l'allowlist (imbrication manager→manager)"; t18_ok=0; }
  # Parenthèse d'allowlist fermée en fin de ligne.
  echo "$dmt" | "$GREP" -qE '\)[[:space:]]*$' || { ko "T18 cloisonnement : allowlist non fermée (parenthèse manquante en fin de ligne)"; t18_ok=0; }
fi
[ "$t18_ok" -eq 1 ] && ok "T18 cloisonnement : allowlist Agent(...) complète (18 noms), vf-design-manager absent, parenthèse fermée"

# T18b — Success Criteria 1 et 3 : doctrine étage design présente, routage vf-auto → design pur
t18b_ok=1
"$GREP" -qi 'Étage design croisé' "$DEVMGR" || { ko "T18b SC1 : doctrine étage design absente de vf-dev-manager.md"; t18b_ok=0; }
"$GREP" -q 'mission-cross-team' "$DEVMGR" || { ko "T18b SC1 : renvoi vers mission-cross-team.md absent de vf-dev-manager.md"; t18b_ok=0; }
AUTO_SKILL="$MOD/skills/vf-auto/SKILL.md"
if [ -f "$AUTO_SKILL" ]; then
  "$GREP" -q 'vf-design-manager' "$AUTO_SKILL" || { ko "T18b SC3 : vf-auto/SKILL.md ne route pas vers vf-design-manager"; t18b_ok=0; }
  "$GREP" -qi 'zéro feature' "$AUTO_SKILL" || { ko "T18b SC3 : signal « mission entièrement design (zéro feature) » absent de vf-auto"; t18b_ok=0; }
else
  ko "T18b SC3 : $AUTO_SKILL introuvable"; t18b_ok=0
fi
[ "$t18b_ok" -eq 1 ] && ok "T18b doctrine : étage design (SC1, renvoi mission-cross-team) + routage vf-auto→design pur (SC3) présents"

# ---------------------------------------------------------------------------
# T19 — Cloisonnement des 3 workers (Pattern 12) : allowlist Agent(...) nom par nom (Phase 16)
# ---------------------------------------------------------------------------
# Miroir de T18 (manager) côté workers : ferme le chemin INDIRECT manager→worker→manager
# (mission-cross-team.md, Invariants). Chaque nom testé un par un — jamais un grep global qui
# passerait avec une liste tronquée.
#
# Correctif (ré-entrée après finding BLOQUANT d'un juge de mutation) : un `grep -qF` sur la
# ligne `tools:` ENTIÈRE est tautologique — il valide un nom présent N'IMPORTE OÙ sur la ligne
# (y compris hors des parenthèses, ex. déplacé en `Bash(nom)`), et `grep -qE ')[[:space:]]*$'`
# ne prouve que « la ligne finit par ) », pas que l'allowlist Agent( ) est refermée. Les deux
# helpers ci-dessous corrigent ça : extraction par COMPTAGE DE PROFONDEUR de parenthèses
# (jamais un grep sur la ligne entière), puis appartenance par ÉGALITÉ DE TOKEN exacte après
# split sur virgule (jamais une recherche de sous-chaîne — immunise contre un nom validé par un
# homonyme partiel, ex. « gsd-plan » ne doit jamais être « trouvé » parce que « gsd-planner »
# est dans la liste).

# extract_agent_allowlist LINE — imprime le contenu entre "Agent(" et sa ")" correspondante.
# Codes retour : 0 = trouvée et refermée (contenu sur stdout) ; 1 = "Agent(" trouvée mais la
# profondeur ne revient jamais à 0 avant la fin de la ligne (allowlist non refermée) ;
# 2 = aucune "Agent(" dans la ligne.
extract_agent_allowlist() {
  local line="$1"
  local after="${line#*Agent(}"
  [ "$after" = "$line" ] && return 2
  local depth=1 i ch content=""
  local len=${#after}
  for (( i=0; i<len; i++ )); do
    ch="${after:$i:1}"
    if [ "$ch" = "(" ]; then
      depth=$((depth+1))
    elif [ "$ch" = ")" ]; then
      depth=$((depth-1))
      if [ "$depth" -eq 0 ]; then
        printf '%s' "$content"
        return 0
      fi
    fi
    content+="$ch"
  done
  return 1
}

# allowlist_has_name CONTENT NAME — vrai si NAME est un token EXACT de CONTENT (liste séparée
# par virgules, espaces autour tolérés). Jamais une sous-chaîne : « gsd-plan » ne matche pas
# dans une liste qui ne contient que « gsd-planner » ou « gsd-plan-checker ».
allowlist_has_name() {
  local content="$1" name="$2" tok
  local prev_ifs="$IFS"
  IFS=','
  for tok in $content; do
    tok="$(printf '%s' "$tok" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [ "$tok" = "$name" ]; then IFS="$prev_ifs"; return 0; fi
  done
  IFS="$prev_ifs"
  return 1
}

CODER_FILE="$MOD/agents/vf-coder.md"
REVIEWER_FILE="$MOD/agents/vf-reviewer.md"
AUDITER_FILE="$MOD/agents/vf-auditer.md"

CODER_ALLOWED="vf-reviewer general-purpose gsd-assumptions-analyzer gsd-phase-researcher \
gsd-pattern-mapper gsd-planner gsd-plan-checker gsd-executor gsd-codebase-mapper gsd-verifier \
gsd-code-reviewer gsd-code-fixer gsd-debugger gsd-integration-checker gsd-nyquist-auditor \
gsd-ui-researcher gsd-ui-checker gsd-ui-auditor gsd-framework-selector gsd-ai-researcher \
gsd-domain-researcher gsd-eval-planner"
REVIEWER_ALLOWED="gsd-code-reviewer"
AUDITER_ALLOWED="gsd-security-auditor"

# Vérifie l'allowlist d'un worker nom par nom. Retourne l'échec via ko() (pas de return code
# consommé par l'appelant — cohérent avec le style pass/fail global du fichier).
check_worker_allowlist() {
  local file="$1" label="$2" names="$3" ok_all=1 line bare name content rc
  line="$(dev_tools_line "$file")"
  if [ -z "$line" ]; then
    ko "T19 cloisonnement : $label sans ligne tools: (hériterait de TOUT)"; return
  fi
  bare="$(echo "$line" | "$GREP" -oE 'Agent([^(]|$)')"
  [ -z "$bare" ] || { ko "T19 cloisonnement : $label a un Agent nu (pas d'allowlist)"; ok_all=0; }
  content="$(extract_agent_allowlist "$line")"; rc=$?
  if [ "$rc" -eq 2 ]; then
    ko "T19 cloisonnement : $label — aucune allowlist Agent( ) trouvée"; ok_all=0
  elif [ "$rc" -eq 1 ]; then
    ko "T19 cloisonnement : $label — allowlist Agent(...) non refermée (parenthèses déséquilibrées)"; ok_all=0
  else
    for name in $names; do
      allowlist_has_name "$content" "$name" || { ko "T19 cloisonnement : « $name » absent de l'allowlist de $label (extraction bornée aux parenthèses Agent(...))"; ok_all=0; }
    done
  fi
  [ "$ok_all" -eq 1 ] && ok "T19 cloisonnement : $label — allowlist Agent(...) complète, nom par nom (extraction bornée, jamais la ligne entière)"
}

check_worker_allowlist "$CODER_FILE" "vf-coder" "$CODER_ALLOWED"
check_worker_allowlist "$REVIEWER_FILE" "vf-reviewer" "$REVIEWER_ALLOWED"
check_worker_allowlist "$AUDITER_FILE" "vf-auditer" "$AUDITER_ALLOWED"

# T19b — aucun des 3 workers ne référence un manager (imbrication manager→manager interdite,
# même par chemin indirect worker→manager).
t19b_ok=1
for f in "$CODER_FILE" "$REVIEWER_FILE" "$AUDITER_FILE"; do
  line="$(dev_tools_line "$f")"
  echo "$line" | "$GREP" -qF -- "vf-dev-manager" && { ko "T19b cloisonnement : $(basename "$f") référence vf-dev-manager (imbrication interdite)"; t19b_ok=0; }
  echo "$line" | "$GREP" -qF -- "vf-design-manager" && { ko "T19b cloisonnement : $(basename "$f") référence vf-design-manager (imbrication interdite)"; t19b_ok=0; }
done
[ "$t19b_ok" -eq 1 ] && ok "T19b cloisonnement : aucun des 3 workers ne référence vf-dev-manager ni vf-design-manager"

# T19c — plus aucun agent du module ne déclare Agent NU (motif borné : Agent non suivi de « ( »,
# pas de faux positif sur Agent( ). Couvre les 2 managers + 3 workers (TEAM_AGENTS, défini en T8).
t19c_ok=1
for a in $TEAM_AGENTS; do
  f="$MOD/agents/$a.md"
  [ -f "$f" ] || continue
  line="$(dev_tools_line "$f")"
  [ -n "$line" ] || continue
  bare="$(echo "$line" | "$GREP" -oE 'Agent([^(]|$)')"
  [ -z "$bare" ] || { ko "T19c cloisonnement : $a.md déclare Agent nu dans tools:"; t19c_ok=0; }
done
[ "$t19c_ok" -eq 1 ] && ok "T19c cloisonnement : aucun agent du module ne déclare Agent nu"

# T19d — parenthèses de l'allowlist Agent(...) ÉQUILIBRÉES (comptage de profondeur), pas
# seulement « la ligne se termine par ) » (cette dernière passerait à tort sur une allowlist
# ouverte mais jamais refermée si un autre tool parenthésé — Bash(git:*) — clôt la ligne).
t19d_ok=1
for f in "$CODER_FILE" "$REVIEWER_FILE" "$AUDITER_FILE"; do
  line="$(dev_tools_line "$f")"
  extract_agent_allowlist "$line" >/dev/null; rc=$?
  [ "$rc" -eq 0 ] || { ko "T19d cloisonnement : $(basename "$f") — allowlist Agent(...) non refermée (parenthèses déséquilibrées, code=$rc)"; t19d_ok=0; }
done
[ "$t19d_ok" -eq 1 ] && ok "T19d cloisonnement : allowlist Agent(...) correctement refermée (comptage de profondeur) sur les 3 workers"

# T19e — « general-purpose » testé NOMMÉMENT dans vf-coder : c'est le nom le plus facile à perdre
# lors d'une future édition (introuvable par un inventaire des seuls fichiers d'agents — il n'est
# dispatché que par discuss-phase en mode advisor/assumptions). Vérifié par extraction bornée aux
# parenthèses (pas un grep sur la ligne entière) : « general-purpose » sorti des parenthèses par
# erreur doit faire échouer ce test, pas seulement T19.
coder_line="$(dev_tools_line "$CODER_FILE")"
coder_content="$(extract_agent_allowlist "$coder_line")"
if allowlist_has_name "$coder_content" "general-purpose"; then
  ok "T19e cloisonnement : « general-purpose » présent dans l'allowlist Agent(...) de vf-coder (cadrage non-interactif)"
else
  ko "T19e cloisonnement : « general-purpose » absent de l'allowlist Agent(...) de vf-coder — casserait discuss-phase --auto en silence"
fi

# ---------------------------------------------------------------------------
# T19f (anti-homonyme) — un nom ne peut jamais être validé par un préfixe/homonyme partiel d'un
# autre nom de la même liste. Fixtures synthétiques (pas les fichiers réels — on isole la
# fonction de matching) : une allowlist ne contenant QUE « gsd-ui-checker » ne doit jamais
# « valider » gsd-ui-researcher (et réciproquement) ; une allowlist ne contenant QUE
# « gsd-planner » ne doit jamais valider « gsd-plan » ni « gsd-plan-checker » — deux cas où l'un
# est un préfixe littéral de l'autre. Chaque fixture est aussi vérifiée positivement (elle doit
# valider son propre nom) pour prouver que le test n'est pas satisfait par construction.
t19f_ok=1
assert_no_homonym() {
  local fixture_line="$1" self_name="$2" foreign_name="$3" content
  content="$(extract_agent_allowlist "$fixture_line")"
  allowlist_has_name "$content" "$self_name" \
    || { ko "T19f anti-homonyme : fixture cassée — « $self_name » non trouvé dans sa propre liste (« $fixture_line »)"; t19f_ok=0; }
  allowlist_has_name "$content" "$foreign_name" \
    && { ko "T19f anti-homonyme : « $foreign_name » validé à tort par la liste ne contenant que « $self_name »"; t19f_ok=0; }
}
assert_no_homonym "tools: Read, Agent(gsd-ui-checker)"     "gsd-ui-checker"    "gsd-ui-researcher"
assert_no_homonym "tools: Read, Agent(gsd-ui-researcher)"  "gsd-ui-researcher" "gsd-ui-checker"
assert_no_homonym "tools: Read, Agent(gsd-code-reviewer)"  "gsd-code-reviewer" "gsd-code-fixer"
assert_no_homonym "tools: Read, Agent(gsd-code-fixer)"     "gsd-code-fixer"    "gsd-code-reviewer"
assert_no_homonym "tools: Read, Agent(gsd-planner)"        "gsd-planner"       "gsd-plan-checker"
assert_no_homonym "tools: Read, Agent(gsd-planner)"        "gsd-planner"       "gsd-plan"
[ "$t19f_ok" -eq 1 ] && ok "T19f anti-homonyme : aucun nom validé par un préfixe/homonyme partiel d'un autre (token exact, extraction bornée)"

# ---------------------------------------------------------------------------
# T20 — Gate ADR-044 réellement falsifiable sur AGENT.md (D-12, VFDO-17-03)
# ---------------------------------------------------------------------------
# check-agents.sh SANS argument sort exit 0 trivialement sur ce dépôt (.claude/agents absent —
# vert vide). AGENT.md est à la racine du module, hors de la boucle CI plugin/*/agents
# (ci.yml:76) : --file est donc la SEULE invocation qui vérifie réellement quelque chose ici.
# Triple assertion (jamais un simple exit 0) : exit code, COMPTE de warnings égal à la baseline
# (3), ET présence des 3 types connus — un 4e type de warning (dégradation) ou la disparition
# d'un type font échouer ce cas, ce qu'une simple assertion d'exit 0 ne verrait jamais (preuve
# de falsifiabilité par mutation : ajouter un champ frontmatter inconnu à une COPIE d'AGENT.md
# fait passer le compte à 4 — documenté dans le SUMMARY du plan VFDO-17-03).
# CHECK_AGENTS est résolu une seule fois par T8c ci-dessus — réutilisé ici (DRY).
if [ -z "$CHECK_AGENTS" ]; then
  skip "T20 gate ADR-044 : contrôleur check-agents.sh introuvable (conductor non présent dans cette disposition)"
else
  T20_OUT="$(bash "$CHECK_AGENTS" --file "$AGENT_FILE" 2>&1)"; T20_RC=$?
  T20_WARN_COUNT=$(echo "$T20_OUT" | "$GREP" -c '⚠')
  t20_ok=1
  [ "$T20_RC" -eq 0 ] || { ko "T20 gate ADR-044 : check-agents.sh --file sort en $T20_RC (attendu 0)"; t20_ok=0; }
  [ "${T20_WARN_COUNT:-0}" -eq 3 ] || { ko "T20 gate ADR-044 : $T20_WARN_COUNT warning(s) sur $(basename "$AGENT_FILE") (attendu exactement 3 — baseline VFDO-17-03)"; t20_ok=0; }
  echo "$T20_OUT" | "$GREP" -q 'different du nom de fichier' || { ko "T20 gate ADR-044 : warning « name différent du nom de fichier » absent"; t20_ok=0; }
  echo "$T20_OUT" | "$GREP" -q 'aucun skill cable' || { ko "T20 gate ADR-044 : warning « aucun skill câblé » absent"; t20_ok=0; }
  echo "$T20_OUT" | "$GREP" -q 'tools absent' || { ko "T20 gate ADR-044 : warning « tools absent » absent"; t20_ok=0; }
  [ "$t20_ok" -eq 1 ] && ok "T20 gate ADR-044 : check-agents.sh --file $(basename "$AGENT_FILE") — exit 0, exactement 3 warnings (les 3 types connus), --file obligatoire (invocation à nu = vert vide, D-12)"
fi

# ---------------------------------------------------------------------------
# T21 — Invariants SC5 par grep structurel sur les 2 nouveaux scripts (D-15, VFDO-17-03)
# ---------------------------------------------------------------------------
# Vérifie, sur le corps ANALYSABLE de check-dev-bootstrap.sh, check-doc-drift.sh et
# discover-unintegrated-docs.sh (lignes de commentaire entières retirées, bloc awk embarqué
# neutralisé — langage étranger avec sa propre sémantique d'exit/comparaison, jamais celle du
# script bash — et commentaires de fin de ligne retirés) : (a) aucun exit 1 littéral, (b) toute
# redirection d'écriture cible /dev/null, un descripteur (&N), ou une variable dont le nom
# contient TMP, (c) aucune commande d'écriture directe (mkdir/touch/tee/cp/mv/sed -i), (d) tout
# mktemp est apparié à un trap ... EXIT dans le même fichier. Chaque sous-vérification produit
# son propre ok/ko (l'invariant rompu et le fichier fautif sont désignés, jamais un booléen
# global).
# Déclencheur du neutraliseur de bloc awk élargi (D-15, VFDO-17 comblement n2) : la forme
# `awk[[:space:]]*'` ne reconnaît que `awk '` nu en fin de ligne. discover-unintegrated-docs.sh
# ouvre son bloc awk avec un paramètre (`awk -v base="$1" '`), forme légitime que l'ancien
# déclencheur laissait échapper — le corps de l'awk (comparateurs `>` de sa propre sémantique,
# ex. `index($0, "/*") > 0`) fuitait alors dans l'analyse bash et faisait échouer T21b par faux
# positif (aucune redirection bash réelle n'est en cause). `[^'"'"']*` accepte tout préfixe avant
# la citation ouvrante tant qu'il ne contient pas lui-même de guillemet simple, sans changer ce
# qui compte comme fin de bloc (`^[[:space:]]*'"'"'`) : l'invariant n'est pas affaibli, seule sa
# détection du périmètre awk est complétée pour couvrir une forme d'ouverture jusqu'ici absente
# des scripts testés.
t21_strip_awk_block() {
  awk '
    /awk[^'"'"']*'"'"'[[:space:]]*$/ { skip=1; next }
    skip && /^[[:space:]]*'"'"'/ { skip=0; next }
    skip { next }
    { print }
  '
}
t21_analyzable_body() { # <file>
  "$GREP" -vE '^[[:space:]]*#' "$1" | t21_strip_awk_block | sed -E 's/[[:space:]]+#.*$//'
}

for T21_FILE in "$MOD/scripts/check-dev-bootstrap.sh" "$MOD/scripts/check-doc-drift.sh" "$MOD/scripts/discover-unintegrated-docs.sh"; do
  T21_NAME="$(basename "$T21_FILE")"
  if [ ! -f "$T21_FILE" ]; then
    ko "T21 invariants SC5 : $T21_FILE introuvable"
    continue
  fi
  T21_BODY="$(t21_analyzable_body "$T21_FILE")"

  # (a) aucun exit 1 littéral (seuls 0/3/64 admis dans le contrat de sortie du script).
  t21a_hits="$(echo "$T21_BODY" | "$GREP" -nE 'exit[[:space:]]+1([^0-9]|$)')"
  if [ -z "$t21a_hits" ]; then
    ok "T21a invariants SC5 : $T21_NAME — aucun exit 1 (contrat 0/3/64 tenu)"
  else
    ko "T21a invariants SC5 : $T21_NAME — exit 1 littéral trouvé : $t21a_hits"
  fi

  # (b) toute redirection d'écriture cible /dev/null, un descripteur (&N), ou une variable *TMP*.
  t21b_hits="$(echo "$T21_BODY" | "$GREP" -nE '>' | "$GREP" -vE '>[[:space:]]*(&[0-9]|/dev/null|\"?\$\{?[A-Za-z_]*TMP[A-Za-z_]*\}?)')"
  if [ -z "$t21b_hits" ]; then
    ok "T21b invariants SC5 : $T21_NAME — toute redirection d'écriture cible /dev/null, &N ou une variable *TMP*"
  else
    ko "T21b invariants SC5 : $T21_NAME — redirection hors /dev/null|&N|*TMP* : $t21b_hits"
  fi

  # (c) aucune commande d'écriture directe.
  t21c_hits="$(echo "$T21_BODY" | "$GREP" -nE '\b(mkdir|touch|tee|cp|mv)\b|sed[[:space:]]+-i')"
  if [ -z "$t21c_hits" ]; then
    ok "T21c invariants SC5 : $T21_NAME — aucun mkdir/touch/tee/cp/mv/sed -i"
  else
    ko "T21c invariants SC5 : $T21_NAME — commande d'écriture trouvée : $t21c_hits"
  fi

  # (d) chaque mktemp est apparié à au moins un trap ... EXIT dans le même fichier.
  t21d_mktemp_count=$(echo "$T21_BODY" | "$GREP" -c 'mktemp')
  t21d_trap_count=$(echo "$T21_BODY" | "$GREP" -cE 'trap.*EXIT')
  if [ "${t21d_mktemp_count:-0}" -gt 0 ] && [ "${t21d_trap_count:-0}" -eq 0 ]; then
    ko "T21d invariants SC5 : $T21_NAME — $t21d_mktemp_count mktemp sans trap ... EXIT"
  else
    ok "T21d invariants SC5 : $T21_NAME — mktemp ($t21d_mktemp_count) apparié à trap ... EXIT, ou aucun mktemp"
  fi
done

# ---------------------------------------------------------------------------
# T22 — Doctrine de sortie documentaire (phase 22, DOCF-01 → DOCF-04)
# ---------------------------------------------------------------------------
# docs-flow.md doit exister, traiter la famille produit et le régime --verify-only, porter le
# garde-fou ADR-031 et fermer sur ## Interdits ; AGENT.md et intent-routing.md doivent y renvoyer.
DOCSFLOW="$REFS_DIR/docs-flow.md"
if [ ! -f "$DOCSFLOW" ]; then
  ko "T22 docs-flow : $DOCSFLOW introuvable"
else
  t22_ok=1
  "$GREP" -q "gsd-docs-update" "$DOCSFLOW" || { ko "T22 docs-flow : famille produit (gsd-docs-update) absente"; t22_ok=0; }
  "$GREP" -q -- "--verify-only" "$DOCSFLOW" || { ko "T22 docs-flow : régime --verify-only absent"; t22_ok=0; }
  "$GREP" -q "ADR-031" "$DOCSFLOW" || { ko "T22 docs-flow : garde-fou ADR-031 absent"; t22_ok=0; }
  "$GREP" -q "^## Interdits" "$DOCSFLOW" || { ko "T22 docs-flow : section ## Interdits absente"; t22_ok=0; }
  "$GREP" -q "docs-flow" "$AGENT_FILE" || { ko "T22 docs-flow : AGENT.md ne renvoie pas vers docs-flow.md"; t22_ok=0; }
  "$GREP" -q "docs-flow" "$ROUTING" || { ko "T22 docs-flow : intent-routing.md ne renvoie pas vers docs-flow.md"; t22_ok=0; }
  # Tâche 2 — familles code/savoir/entrée et fait outillé sous-jacent.
  "$GREP" -q "gsd-map-codebase" "$DOCSFLOW" || { ko "T22 docs-flow : famille code (gsd-map-codebase) absente"; t22_ok=0; }
  "$GREP" -q "gsd-extract-learnings" "$DOCSFLOW" || { ko "T22 docs-flow : famille savoir (gsd-extract-learnings) absente"; t22_ok=0; }
  "$GREP" -q "ingestion-flow" "$DOCSFLOW" || { ko "T22 docs-flow : renvoi vers ingestion-flow.md (famille entrée) absent"; t22_ok=0; }
  "$GREP" -q "check-doc-drift.sh" "$DOCSFLOW" || { ko "T22 docs-flow : fait outillé check-doc-drift.sh non cité"; t22_ok=0; }
  # Ligne rouge --force (D-06) : une SEULE ligne physique porte le flag ET la mission ET
  # l'autonome — chaînage de trois greps sur le même flux, jamais trois greps indépendants.
  if "$GREP" -F -- "--force" "$DOCSFLOW" | "$GREP" -F "mission" | "$GREP" -q "autonome"; then
    :
  else
    ko "T22 docs-flow : ligne rouge --force absente (une seule ligne doit porter --force + mission + autonome)"; t22_ok=0
  fi
  # Frontière vibeflow-os : une SEULE ligne physique porte gsd-docs-update ET vibeflow-os ET
  # check-version-sync.sh — même idiome de chaînage.
  if "$GREP" -F "gsd-docs-update" "$DOCSFLOW" | "$GREP" -F "vibeflow-os" | "$GREP" -q "check-version-sync.sh"; then
    :
  else
    ko "T22 docs-flow : frontière vibeflow-os absente (une seule ligne doit porter gsd-docs-update + vibeflow-os + check-version-sync.sh)"; t22_ok=0
  fi
  # Tâche 3 — captation d'intention : les deux régimes distincts sont ROUTÉS, pas seulement
  # documentés. C'est le (b) du but de la phase — sans ces lignes, la doctrine existe et reste
  # inatteignable en langage naturel.
  "$GREP" -q -- "--verify-only" "$ROUTING" || { ko "T22 captation : intent-routing.md ne route pas le régime d'audit (--verify-only)"; t22_ok=0; }
  "$GREP" -q -- "--force" "$ROUTING" || { ko "T22 captation : intent-routing.md ne route pas le régime de régénération (--force)"; t22_ok=0; }
  "$GREP" -q "dit encore vrai" "$ROUTING" || { ko "T22 captation : la formulation d'audit « dit encore vrai » n'est pas captée"; t22_ok=0; }
  "$GREP" -q "refais toute la doc" "$ROUTING" || { ko "T22 captation : la formulation de régénération « refais toute la doc » n'est pas captée"; t22_ok=0; }
  # Le protocole de désambiguïsation (D-10) : les quatre familles nommées au même endroit.
  "$GREP" -q "Désambiguïsation" "$ROUTING" || { ko "T22 captation : protocole de désambiguïsation absent d'intent-routing.md"; t22_ok=0; }
  # §Contexte & session doit porter ≥ 8 lignes de table (5 doc/contexte + les 3 existantes).
  ctx_rows=$(awk '/^## Contexte & session/,/^## Design/' "$ROUTING" | "$GREP" -c '^| ' || true)
  [ "${ctx_rows:-0}" -ge 8 ] || { ko "T22 captation : §Contexte & session porte $ctx_rows lignes de table, plancher 8"; t22_ok=0; }
  # Non-régression de densité (ADR-029) sur l'agent conversationnel.
  agent_lines=$(wc -l < "$AGENT_FILE" | tr -d ' ')
  [ "$agent_lines" -le 250 ] || { ko "T22 captation : AGENT.md à $agent_lines lignes, plafond ADR-029 = 250"; t22_ok=0; }
  [ "$t22_ok" -eq 1 ] && ok "T22 docs-flow : doctrine complète (4 familles, --verify-only, ADR-031, ligne rouge --force, frontière vibeflow-os, ## Interdits), captation des 2 régimes + désambiguïsation routées, AGENT.md ($agent_lines l.) et intent-routing.md ($ctx_rows lignes de table) y renvoient"
fi

# ---------------------------------------------------------------------------
# T23 — Câblage du geste documentaire dans les DEUX managers de mission
# ---------------------------------------------------------------------------
# Ce que T23 garantit : une PRÉSENCE TEXTUELLE de câblage — les deux managers nomment le nœud, les
# quatre déclencheurs, et renvoient à la doctrine plutôt que d'en héberger une copie.
# Ce que T23 NE garantit PAS : le COMPORTEMENT de l'agent à l'exécution — qu'il pose réellement le
# nœud au bon moment. Même réserve que celle inscrite pour BRDG-03 dans REQUIREMENTS.md.
# Précédent Phase 19 : un compte rendu qui prouve une présence n'est pas un comportement prouvé.
t23_ok=1

# Résolution de la cible design — seule zone du fichier qui sort de dev-orchestrator.
# Ordre imposé : en dépôt source, $MOD/agents/ est le dossier du manager DEV et ne contient pas
# le manager design ; la branche $REPO doit donc être testée en premier.
DESIGNMGR=""
DESIGN_SRC_LAYOUT=0
if [ -f "$REPO/design-orchestrator/agents/vf-design-manager.md" ]; then
  DESIGNMGR="$REPO/design-orchestrator/agents/vf-design-manager.md"; DESIGN_SRC_LAYOUT=1
elif [ -f "$MOD/agents/vf-design-manager.md" ]; then
  DESIGNMGR="$MOD/agents/vf-design-manager.md"
fi

# Côté dev — $DEVMGR est déjà résolu par T18 plus haut.
"$GREP" -q "docs-flow" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne renvoie pas vers docs-flow.md"; t23_ok=0; }
"$GREP" -q -- "--id=docs" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne pose pas le nœud --id=docs"; t23_ok=0; }
for motif in "doc-drift" "milestone" "surface publique" "capacité"; do
  "$GREP" -q -- "$motif" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne nomme pas le déclencheur « $motif »"; t23_ok=0; }
done

# Côté design — skip explicite si le module n'est pas dans le périmètre scanné (cf. T6/installeur).
if [ -n "$DESIGNMGR" ]; then
  "$GREP" -q "dev-orchestrator-references/docs-flow.md" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne renvoie pas vers dev-orchestrator-references/docs-flow.md"; t23_ok=0; }
  "$GREP" -q -- "--id=docs" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne pose pas le nœud --id=docs"; t23_ok=0; }
  for motif in "doc-drift" "milestone" "surface publique" "capacité"; do
    "$GREP" -q -- "$motif" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne nomme pas le déclencheur « $motif »"; t23_ok=0; }
  done
  # ADR-057 / D-01 : la doctrine vit dans UN SEUL module. En lab installé l'arborescence est
  # aplatie, donc l'assertion d'absence n'a de sens qu'en disposition dépôt source.
  if [ "$DESIGN_SRC_LAYOUT" -eq 1 ] && [ -f "$REPO/design-orchestrator/references/docs-flow.md" ]; then
    ko "T23 managers : copie locale de la doctrine dans design-orchestrator/references — ADR-057, une seule voix"; t23_ok=0
  fi
else
  skip "T23 managers : module design hors du périmètre scanné — volet design non vérifié"
fi

# D-13 : check-doc-drift.sh est CONSOMMÉ par la doctrine, jamais réimplémenté.
[ -f "$MOD/scripts/check-doc-drift.sh" ] || { ko "T23 managers : check-doc-drift.sh absent — la doctrine s'appuie sur un fait qui n'existe plus"; t23_ok=0; }
if [ -f "$REFS_DIR/docs-flow.md" ]; then
  "$GREP" -q "check-doc-drift.sh" "$REFS_DIR/docs-flow.md" || { ko "T23 managers : docs-flow.md n'interprète pas le fait check-doc-drift.sh"; t23_ok=0; }
fi
"$GREP" -q "check_doc_drift\s*()" "$DEVMGR" && { ko "T23 managers : vf-dev-manager.md réimplémente check-doc-drift au lieu de le consommer"; t23_ok=0; }

[ "$t23_ok" -eq 1 ] && ok "T23 managers : le geste documentaire est câblé des deux côtés (nœud docs, 4 déclencheurs, renvoi à la doctrine, aucune copie locale) — présence textuelle, pas comportement"

# ---------------------------------------------------------------------------
# Outillage commun T24/T25/T26 — assertions BORNÉES AU BLOC, jamais « la chaîne existe quelque
# part dans le fichier ». Un grep global ne relie rien à rien : il reste vert quand la sémantique
# du contrat est inversée (mapping D-01 retourné vers gaps_found, sous-champ renommé…).
# ---------------------------------------------------------------------------

# Imprime les blocs de <file> qui matchent <ancre ERE>, un bloc par ligne de sortie (les sauts de
# ligne internes sont aplatis en espaces) : la co-occurrence « dans le même bloc » devient une
# co-occurrence sur la ligne de sortie, insensible au wrap à 100 colonnes du module. Un bloc =
# paragraphe, item de liste, item numéroté ou titre. L'ancre est une ERE awk SANS backslash
# (écrire [*] et pas \*) : awk -v interprète les échappements de la valeur avant la regex.
#
# Un item de liste ne clôt le bloc que si son INDENTATION est ≤ celle de la ligne qui a ouvert le
# bloc. Flusher sur toute ligne commençant par un marqueur de puce coupait le bloc à la première
# sous-puce imbriquée : « 2. **Plan** : … » suivi de «    - en mode **non-interactif** » donnait
# deux blocs, et la forme interdite passait au travers de toute co-occurrence exigée DANS le bloc.
# Une sous-puce est une continuation de son item parent : elle appartient au même bloc.
md_blocks_matching() { # <file> <ancre ERE>
  [ -f "$1" ] || return 0
  awk -v anchor="$2" '
    function indent(s,   t) { t = s; sub(/[^ \t].*$/, "", t); gsub(/\t/, "    ", t); return length(t) }
    function flush() { if (buf != "" && buf ~ anchor) print buf; buf = "" }
    /^[[:space:]]*$/ { flush(); next }
    /^#/ { flush() }
    /^[[:space:]]*([-*+][[:space:]]|[0-9]+\.[[:space:]])/ {
      if (buf == "" || indent($0) <= openind) flush()
    }
    { if (buf == "") openind = indent($0); buf = (buf == "" ? $0 : buf " " $0) }
    END { flush() }
  ' "$1"
}

# Cibles de balayage du module : les agents de l'ÉQUIPE (liste fermée $TEAM_AGENTS) + les
# références RÉSOLUES ($REFS_DIR). Jamais "$MOD"/agents/*.md ni "$MOD"/references/*.md en dur :
# en lab installé agents/ est plat et PARTAGÉ (on capterait ~/.claude/agents/gsd-executor.md, qui
# porte légitimement les intitulés internes → faux rouge) et references/ n'existe pas sous ce nom
# (glob non expansé, avalé par [ -f ] || continue → zéro fichier scanné, vert à vide).
module_md_targets() {
  local a f
  for a in $TEAM_AGENTS; do [ -f "$MOD/agents/$a.md" ] && echo "$MOD/agents/$a.md"; done
  for f in "$REFS_DIR"/*.md; do [ -f "$f" ] && echo "$f"; done
  return 0
}

# ---------------------------------------------------------------------------
# T24 (tracer, D-01) — le mapping du checkpoint amont traverse référence → vf-coder →
# vf-dev-manager. La règle est UNE règle à DEUX motifs : gate="blocking-human" OU précondition
# amont non satisfaite ⇒ statut `human_needed`.
#
# L'assertion mesure une RELATION, pas une co-présence. Exiger trois chaînes indépendantes dans un
# bloc ne verrouille rien dès que le bloc énumère PLUSIEURS statuts : celui de vf-dev-manager fait
# 14 lignes et couvre 4 verdicts — une doctrine disant l'INVERSE de D-01 (gate ⇒ gaps_found) y
# satisfait les trois sondes par des phrases sans rapport entre elles. On isole donc le SEGMENT du
# bloc qui appartient à `human_needed` et on exige les deux motifs DANS CE SEGMENT.
# ---------------------------------------------------------------------------
t24_ok=1
CONTRACTS_FILE="$REFS_DIR/mission-contracts.md"   # $CODER_FILE et $DEVMGR : déjà résolus plus haut

# Statuts du contrat ADR-053. Dans une énumération de verdicts, une entrée s'OUVRE par le statut
# backtické suivi d'un marqueur de mapping (→ ⇒ — – :) ; une mention incidente en cours de phrase
# (« le laisser `blocked`/`failed` ») n'en porte pas et ne coupe donc pas le segment.
T24_STATUTS='passed|gaps_found|human_needed|blocked'

# Segment d'un bloc appartenant à un statut : de son entrée jusqu'à l'entrée du statut suivant.
# Vide si le statut n'ouvre aucune entrée.
t24_segment_of() { # <statut> ; bloc(s) sur stdin
  awk -v want="$1" -v st="$T24_STATUTS" '
    {
      entry = "`(" st ")`[ ]*(→|⇒|—|–|:)"
      line = $0; owner = ""; res = ""
      while (length(line) > 0 && match(line, entry)) {
        if (owner == want) res = res substr(line, 1, RSTART - 1)
        m = substr(line, RSTART, RLENGTH)
        split(m, a, "`"); owner = a[2]
        line = substr(line, RSTART + RLENGTH)
        if (owner == want) res = res m
      }
      if (owner == want) res = res line
      if (res != "") print res
    }
  '
}

# 0 = mapping tenu · 1 = segment trouvé mais mapping rompu · 2 = bloc introuvable ·
# 3 = bloc multi-statuts dont `human_needed` n'ouvre aucune entrée (rien de mesurable — jamais un
# repli silencieux sur le bloc entier, qui rouvrirait exactement la faille de co-présence).
t24_maps_to_human_needed() { # <file> <ancre ERE>
  local blk seg mentions
  blk="$(md_blocks_matching "$1" "$2")"
  [ -n "$blk" ] || return 2
  mentions="$(printf '%s\n' "$blk" | "$GREP" -oE "\`($T24_STATUTS)\`" | LC_ALL=C sort -u | "$GREP" -c . || true)"
  if [ "${mentions:-0}" -le 1 ]; then
    seg="$blk"          # bloc mono-statut : pas d'énumération, le bloc EST le segment
  else
    seg="$(printf '%s\n' "$blk" | t24_segment_of 'human_needed')"
    [ -n "$seg" ] || return 3
  fi
  printf '%s\n' "$seg" | "$GREP" -q 'gate="blocking-human"' || return 1
  printf '%s\n' "$seg" | "$GREP" -qi 'précondition'         || return 1
  printf '%s\n' "$seg" | "$GREP" -q 'human_needed'          || return 1
  return 0
}

t24_assert() { # <libellé> <fichier> <ancre ERE>
  if [ ! -f "$2" ]; then ko "T24 $1 : fichier introuvable ($2)"; t24_ok=0; return; fi
  t24_maps_to_human_needed "$2" "$3"
  case $? in
    0) : ;;
    2) ko "T24 $1 : bloc porteur de la règle de mapping introuvable dans $(basename "$2") (ancre /$3/)"; t24_ok=0 ;;
    3) ko "T24 $1 : dans $(basename "$2"), le bloc énumère plusieurs statuts mais human_needed n'y ouvre aucune entrée de mapping (« \`human_needed\` — … ») — segment non isolable, donc mapping non vérifiable"; t24_ok=0 ;;
    *) ko "T24 $1 : dans $(basename "$2"), le segment du statut human_needed ne porte pas les DEUX motifs (gate=\"blocking-human\" ET précondition non satisfaite) — ils sont rattachés à un autre verdict"; t24_ok=0 ;;
  esac
}

"$GREP" -q '^## Contrat de checkpoint amont' "$CONTRACTS_FILE" 2>/dev/null \
  || { ko "T24 A : section « Contrat de checkpoint amont » absente de mission-contracts.md"; t24_ok=0; }
t24_assert "A (mission-contracts.md, §Règle unique de mapping)" "$CONTRACTS_FILE" '[*][*]Règle unique de mapping[*][*]'
t24_assert "B (vf-coder.md, bloc du champ gate)"                "$CODER_FILE"     '[*][*][`]gate[`][*][*]'
t24_assert "C (vf-dev-manager.md, bloc Verdict d'étape)"        "$DEVMGR"         '[*][*]Verdict d'

# D (DISCRIMINANT) — trois mutants + une fixture LICITE. Ce que chaque cas prouve, sans le
# surdéclarer :
#
#   D1/D2 (mutations de VALEUR, `s///g` GLOBAUX) : elles effacent le token que l'assertion cherche
#   ensuite. Elles prouvent donc que la sonde lit le BON token (un renommage du statut cible ou de
#   la valeur du gate ne passe pas inaperçu) — elles ne prouvent RIEN sur la relation entre les
#   deux. Ne pas leur prêter plus : le commentaire précédent affirmait « on ne retire PAS la chaîne
#   qu'on cherche ensuite », c'était faux.
#
#   D3 (mutation de RELATION — c'est elle qui mesure D-01) : on ÉCHANGE les deux étiquettes de
#   statut `human_needed` ↔ `gaps_found`. Aucun mot n'est retiré : une fois les deux étiquettes
#   ramenées à un jeton canonique unique, le multiset de tokens du fichier est rigoureusement
#   IDENTIQUE avant et après — c'est ce que l'assertion vérifie avant de mesurer quoi que ce soit.
#   Seule la RELATION change : les deux motifs se retrouvent rattachés à `gaps_found`. Une doctrine
#   disant l'inverse exact de D-01 laissait la suite à 87 OK/0 KO ; c'est ce trou que D3 ferme.
#   Robuste à toute reformulation : la mutation ne s'ancre sur aucune phrase, seulement sur les
#   deux étiquettes que le contrat ADR-053 impose de toute façon.
#
#   D4 (fixture LICITE) : une rédaction correcte mais REFORMULÉE de la règle (autre marqueur de
#   mapping, autre ordre, autres mots de liaison) doit rester VERTE. Une sonde qui punit une
#   réécriture légitime nuit autant qu'une sonde aveugle.
T24_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T24_TMPDIR"
T24_MUT_STATUT="$T24_TMPDIR/mutant-statut.md"
T24_MUT_GATE="$T24_TMPDIR/mutant-gate.md"
T24_MUT_RELATION="$T24_TMPDIR/mutant-relation.md"
T24_LICIT="$T24_TMPDIR/licite-reformulee.md"
sed 's/human_needed/gaps_found/g'      "$DEVMGR" > "$T24_MUT_STATUT"
sed 's/blocking-human/blocking-auto/g' "$DEVMGR" > "$T24_MUT_GATE"
sed -e 's/`human_needed`/`@@VFSWAP@@`/g' -e 's/`gaps_found`/`human_needed`/g' \
    -e 's/`@@VFSWAP@@`/`gaps_found`/g' "$DEVMGR" > "$T24_MUT_RELATION"

cat > "$T24_LICIT" <<'T24LICIT'
## Contrôle de flux

- **Verdict d'étape (rapport typé, ADR-053)** : `passed` → nœud marqué fait, frontière suivante ·
  `human_needed` : tout refus d'auto-approbation venu de l'amont — un checkpoint
  `gate="blocking-human"` aussi bien qu'une précondition amont non satisfaite — remonte en
  escalade, jamais tranché seul · `gaps_found` → relance de comblement, puis arbitrage ·
  `blocked` → laisser le nœud en l'état et traiter la dépendance.
T24LICIT

t24_mut_ko=""
# Preuve que D3 est bien une mutation de RELATION et pas un effacement : une fois les deux
# étiquettes ramenées au même jeton canonique, le multiset de tokens doit être IDENTIQUE de part et
# d'autre. Et le mutant doit DIFFÉRER de l'original — sinon la doctrine ne porte plus les deux
# étiquettes, la mutation n'a rien mordu et il faut le dire, jamais laisser passer pour vert.
t24_canon() { sed -e 's/human_needed/@VFST@/g' -e 's/gaps_found/@VFST@/g' "$1" | tr -cs '[:alnum:]_@' '\n' | LC_ALL=C sort; }
if [ "$(t24_canon "$DEVMGR")" != "$(t24_canon "$T24_MUT_RELATION")" ]; then
  t24_mut_ko="$t24_mut_ko [mutant de relation : le multiset canonique de tokens a changé — ce n'est plus une mutation de relation pure]"
elif cmp -s "$DEVMGR" "$T24_MUT_RELATION"; then
  t24_mut_ko="$t24_mut_ko [mutant de relation IDENTIQUE à l'original — les deux étiquettes de statut ne sont plus toutes deux présentes, la mutation n'a rien mordu]"
fi

t24_maps_to_human_needed "$T24_MUT_STATUT"   '[*][*]Verdict d' && t24_mut_ko="$t24_mut_ko [D1 statut human_needed→gaps_found non détecté]"
t24_maps_to_human_needed "$T24_MUT_GATE"     '[*][*]Verdict d' && t24_mut_ko="$t24_mut_ko [D2 gate blocking-human→blocking-auto non détecté]"
t24_maps_to_human_needed "$T24_MUT_RELATION" '[*][*]Verdict d' && t24_mut_ko="$t24_mut_ko [D3 RELATION : les deux motifs rattachés à gaps_found, aucun token retiré — non détecté]"
t24_maps_to_human_needed "$T24_LICIT"        '[*][*]Verdict d' || t24_mut_ko="$t24_mut_ko [D4 FAUX ROUGE : une reformulation LICITE de la règle est rejetée (rc=$?)]"
t24_maps_to_human_needed "$DEVMGR"           '[*][*]Verdict d' || t24_mut_ko="$t24_mut_ko [le fichier réel ne tient plus l'assertion]"
if [ -n "$t24_mut_ko" ]; then
  ko "T24 D (DISCRIMINANT) : l'assertion de mapping ne discrimine pas —$t24_mut_ko"; t24_ok=0
else
  ok "T24 D (DISCRIMINANT) : 2 mutations de VALEUR + 1 mutation de RELATION (échange d'étiquettes, multiset de tokens inchangé) font rougir l'assertion ; une reformulation LICITE reste verte ; le fichier réel la tient"
fi

[ "$t24_ok" -eq 1 ] && ok "T24 : le mapping D-01 (deux motifs ⇒ human_needed) est porté dans le même bloc par référence, vf-coder et vf-dev-manager"

# ---------------------------------------------------------------------------
# T25 (D-02) — le flag d'enchaînement autonome (workflow._auto_chain_active) est désarmé au
# démarrage de mission ET fermé par gate : aucun fichier de doctrine du module ne peut le
# represcrire sur les briques de Plan ou d'Exécution. Périmètre du balayage : les .md de doctrine
# (agents de l'équipe + références résolues, cf. module_md_targets) — ce fichier de test, qui
# embarque la forme interdite dans ses fixtures, n'en fait pas partie puisqu'il n'est ni un agent
# de $TEAM_AGENTS ni une référence de $REFS_DIR.
# ---------------------------------------------------------------------------
t25_ok=1

# Forme interdite : un bloc de brique **Plan** / **Exécution** qui prescrit le mode
# d'enchaînement (non-interactif / --auto / --chain). Co-occurrence exigée DANS LE BLOC et non
# sur la même ligne physique : le module wrap à 100 colonnes, donc un simple retour à la ligne
# suffisait à passer au travers — tout comme « **Plan (planification)** » (gras non fermé
# immédiatement après le mot), d'où l'ancre ouvrante seule.
t25_forbidden_chain_hits() { # <file>
  md_blocks_matching "$1" '[*][*](Plan|Exécution)' | "$GREP" -E '(non-interactif|--auto\b|--chain\b)'
}

# volet présence : vf-dev-manager.md nomme la clé et l'appel qui la remet à faux.
"$GREP" -q '_auto_chain_active' "$DEVMGR" || { ko "T25 présence : vf-dev-manager.md ne nomme pas workflow._auto_chain_active"; t25_ok=0; }
"$GREP" -q 'config-set' "$DEVMGR" || { ko "T25 présence : vf-dev-manager.md n'invoque pas config-set"; t25_ok=0; }
"$GREP" -q 'gsd_run' "$DEVMGR" || { ko "T25 présence : vf-dev-manager.md ne résout pas gsd_run"; t25_ok=0; }
"$GREP" -q 'RUNTIME_DIR' "$DEVMGR" && { ko "T25 présence : vf-dev-manager.md recopie la cascade de résolution (RUNTIME_DIR) au lieu d'y renvoyer — DRY rompu"; t25_ok=0; }

# volet fermeture (le cœur) : balayage réel des .md de doctrine, via les cibles RÉSOLUES. Le
# compteur de fichiers vus est non négociable : sans lui, un glob qui n'expanse pas produit un
# vert qui prétend avoir balayé ce qu'il n'a jamais ouvert.
t25_real_hits=""; t25_scanned=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  t25_scanned=$((t25_scanned + 1))
  h="$(t25_forbidden_chain_hits "$f")"
  [ -n "$h" ] && t25_real_hits="$t25_real_hits
$f: $h"
done < <(module_md_targets)
if [ "$t25_scanned" -eq 0 ]; then
  ko "T25 fermeture : ZÉRO fichier balayé (agents d'équipe + $REFS_DIR introuvables) — un vert à vide n'est pas une garantie"
  t25_ok=0
elif [ -n "$t25_real_hits" ]; then
  ko "T25 fermeture : forme interdite (mode d'enchaînement sur brique Plan/Exécution) trouvée —$t25_real_hits"
  t25_ok=0
else
  ok "T25 fermeture : $t25_scanned fichier(s) de doctrine balayé(s), aucun ne prescrit le mode d'enchaînement sur une brique Plan/Exécution"
fi

# volet discriminance (DISCRIMINANT, par mutation) : trois fixtures dans un mktemp -d — une forme
# interdite (Plan), la même reformulée/wrappée (gras non fermé + retour à la ligne, la faille que
# la co-occurrence sur ligne physique laissait passer), et une forme licite (Cadrage, patron de la
# ligne 27 réelle de vf-coder.md). La détection doit remonter les deux premières et PAS la dernière.
T25_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T25_TMPDIR"
T25_FORBIDDEN="$T25_TMPDIR/forbidden-plan.md"
T25_WRAPPED="$T25_TMPDIR/forbidden-plan-wrappe.md"
T25_LICIT="$T25_TMPDIR/licit-cadrage.md"
printf '2. **Plan** : invoque `gsd-plan-phase` en mode **non-interactif**.\n' > "$T25_FORBIDDEN"
printf '2. **Plan (planification)** : invoque `gsd-plan-phase`\n   en mode **non-interactif**.\n' > "$T25_WRAPPED"
printf '1. **Cadrage** : invoque le skill `gsd-discuss-phase` en mode **non-interactif**.\n' > "$T25_LICIT"

t25_forbidden_hit="$(t25_forbidden_chain_hits "$T25_FORBIDDEN")"
t25_wrapped_hit="$(t25_forbidden_chain_hits "$T25_WRAPPED")"
t25_licit_hit="$(t25_forbidden_chain_hits "$T25_LICIT")"
if [ -n "$t25_forbidden_hit" ] && [ -n "$t25_wrapped_hit" ] && [ -z "$t25_licit_hit" ]; then
  ok "T25 (DISCRIMINANT) : fixture Plan détectée, variante reformulée/wrappée détectée aussi, fixture Cadrage (licite, ligne 27 réelle de vf-coder.md) épargnée"
else
  ko "T25 (DISCRIMINANT) : ne distingue pas les formes interdites (Plan, Plan wrappé — attendues détectées) de la licite (Cadrage — attendue épargnée) — forbidden=[$t25_forbidden_hit] wrapped=[$t25_wrapped_hit] licit=[$t25_licit_hit]"
  t25_ok=0
fi

[ "$t25_ok" -eq 1 ] && ok "T25 : flag d'enchaînement désarmé au démarrage + fermé par gate (Plan/Exécution interdits, Cadrage licite), discriminance prouvée par mutation"

# ---------------------------------------------------------------------------
# T26 (D-03, D-04, D-04bis) — minimum de reprise, halte de nœud, réponse par le manager. Garde
# anti-duplication ADR-030 (assertion D, NÉGATIVE) : aucun .md de doctrine du module ne reproduit
# les intitulés du contrat interne de l'exécuteur amont (Completed Tasks / Current Task /
# Checkpoint Details / Awaiting / CHECKPOINT REACHED — checkpoint_return_format, execute-plan.md).
# Périmètre = module_md_targets (agents de l'équipe + références résolues) : ni ce fichier de test
# (qui cite ces intitulés dans sa fixture E), ni les agents VOISINS d'un lab installé — en
# disposition lab, agents/ est plat et partagé, et gsd-executor.md y porte légitimement les quatre
# intitulés : les capter serait un faux rouge chez tout utilisateur ayant gsd-core au même scope.
# ---------------------------------------------------------------------------
t26_ok=1

# A — Minimum de reprise (D-03) : l'ensemble des sous-champs est MESURÉ sur l'énumération fermée
# du contrat, jamais comparé à une liste de noms figée dans le test (le nombre de sous-champs peut
# évoluer ; la propriété à verrouiller est la fermeture de l'ensemble). Les sous-champs sont
# repérés comme TOKENS BACKTICKÉS : un grep de mot nu sur tout le fichier ne verrouillait rien —
# « checkpoint » et « gate » avaient déjà un hit AVANT l'ajout du paragraphe (sondes mortes), et
# un renommage en `type_checkpoint` / `gate_amont` les satisfaisait tout autant.

# Identifiants backtickés d'un texte lu sur stdin, triés et dédupliqués.
t26_ids() { "$GREP" -oE '`[a-z][a-z0-9_]*`' | tr -d '`' | sort -u; }

# Intitulés du contrat INTERNE amont, en version « texte » (sans ancre de ligne) : sert à
# interdire qu'un sous-champ du minimum de reprise en reproduise un (ADR-030).
T26_INTERNAL_RE='Completed Tasks|Current Task|Checkpoint Details|Awaiting|CHECKPOINT REACHED'

# 0 = contrat clos et sain (T26_FIELDS/T26_N renseignés) · 1 = fermeture rompue ($T26_WHY) ·
# 2 = bloc introuvable.
T26_FIELDS=""; T26_N=0; T26_WHY=""
t26_reprise_closed() { # <fichier de contrat>
  local blk enum fields parent all
  blk="$(md_blocks_matching "$1" '[*][*]Minimum de reprise')"
  [ -n "$blk" ] || return 2
  printf '%s\n' "$blk" | "$GREP" -q 'sous-champs sont exactement' || { T26_WHY="énumération fermée (« sous-champs sont exactement ») absente"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -q "rien d'autre"                || { T26_WHY="borne « rien d'autre » absente"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -q 'ADR-030'                     || { T26_WHY="motif ADR-030 non cité"; return 1; }
  enum="$(printf '%s\n' "$blk" | sed -e 's/.*sous-champs sont exactement//' -e "s/[*][*]rien d'autre[*][*].*//")"
  printf '%s\n' "$enum" | "$GREP" -qE "$T26_INTERNAL_RE" && { T26_WHY="un sous-champ reproduit un intitulé du contrat interne amont (ADR-030)"; return 1; }
  fields="$(printf '%s\n' "$enum" | t26_ids)"
  [ -n "$fields" ] || { T26_WHY="aucun sous-champ backtické dans l'énumération"; return 1; }
  parent="$(printf '%s\n' "$blk" | sed -n 's/.*champ optionnel `\([a-z][a-z0-9_]*\)`.*/\1/p')"
  [ -n "$parent" ] || { T26_WHY="champ porteur (« un champ optionnel \`…\` ») non déclaré"; return 1; }
  all="$(printf '%s\n' "$blk" | t26_ids)"
  # égalité d'ensemble : ce que le bloc déclare == énumération ∪ champ porteur, ni plus ni moins.
  [ "$(printf '%s\n%s\n' "$fields" "$parent" | sort -u)" = "$all" ] || {
    T26_WHY="le bloc déclare des identifiants hors de l'énumération fermée [$(echo $all)]"; return 1; }
  T26_FIELDS="$fields"; T26_N="$(printf '%s\n' "$fields" | "$GREP" -c .)"
  return 0
}

t26_reprise_closed "$CONTRACTS_FILE"
case $? in
  0) ok "T26 A : minimum de reprise — ensemble MESURÉ de $T26_N sous-champs backtickés ($(printf "%s" "$T26_FIELDS" | tr "\n" " ")), énumération close (« exactement » / « rien d'autre » / ADR-030), aucun intitulé du contrat interne amont" ;;
  2) ko "T26 A : bloc « Minimum de reprise » introuvable dans mission-contracts.md"; t26_ok=0 ;;
  *) ko "T26 A : minimum de reprise — $T26_WHY"; t26_ok=0 ;;
esac

# A' — ce que l'AGENT déclare ne peut pas sortir de l'ensemble du contrat : tout identifiant
# backtické des blocs `gate`/`reprise` de vf-coder.md doit appartenir à l'ensemble déclaré par
# mission-contracts.md (aucun champ inventé côté worker, ADR-030 : une seule voix).
t26_coder_ids="$(md_blocks_matching "$CODER_FILE" '[*][*][`](gate|reprise)[`][*][*]' | t26_ids)"
t26_contract_ids="$(md_blocks_matching "$CONTRACTS_FILE" '[*][*]Minimum de reprise' | t26_ids)"
t26_invented="$(comm -23 <(printf '%s\n' "$t26_coder_ids" | "$GREP" -v '^$') <(printf '%s\n' "$t26_contract_ids" | "$GREP" -v '^$') 2>/dev/null)"
if [ -z "$t26_coder_ids" ]; then
  ko "T26 A' : vf-coder.md ne déclare aucun champ backtické de checkpoint (blocs gate/reprise introuvables)"; t26_ok=0
elif [ -n "$t26_invented" ]; then
  ko "T26 A' : vf-coder.md déclare un champ absent du contrat — $(echo $t26_invented)"; t26_ok=0
else
  ok "T26 A' : les champs déclarés par vf-coder.md ($(echo $t26_coder_ids)) sont tous dans l'ensemble du contrat — aucun champ inventé côté worker"
fi

# B — vf-coder.md porte la règle « attente humaine ⇒ escalade, jamais auto-répondue ».
"$GREP" -q 'reprise' "$CODER_FILE" || { ko "T26 B : vf-coder.md ne nomme pas le champ reprise"; t26_ok=0; }
"$GREP" -qi 'jamais une réponse' "$CODER_FILE" || { ko "T26 B : vf-coder.md ne porte pas la règle « jamais une réponse de ta part »"; t26_ok=0; }

# C — vf-dev-manager.md porte le halt DE NŒUD et la réponse par le manager.
"$GREP" -q 'halte de nœud' "$DEVMGR" || { ko "T26 C : vf-dev-manager.md ne nomme pas le halt de nœud"; t26_ok=0; }
"$GREP" -q 'réponds aux attentes humaines' "$DEVMGR" || { ko "T26 C : vf-dev-manager.md ne nomme pas le manager comme répondant aux attentes humaines"; t26_ok=0; }

# D (NÉGATIVE) — aucun .md de doctrine du module (module_md_targets : agents de l'équipe +
# références résolues) ne reproduit les intitulés du contrat interne de l'exécuteur amont. Le
# compteur de fichiers vus est non négociable : sans lui, un glob qui n'expanse pas rendrait un
# vert prétendant avoir balayé ce qu'il n'a jamais ouvert.
t26_internal_titles() { # <file>
  "$GREP" -lE 'Completed Tasks|Current Task|Checkpoint Details|^Awaiting$|CHECKPOINT REACHED' "$1" 2>/dev/null
}
t26_dup_hits=""; t26_scanned=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  t26_scanned=$((t26_scanned + 1))
  h="$(t26_internal_titles "$f")"
  [ -n "$h" ] && t26_dup_hits="$t26_dup_hits $f"
done < <(module_md_targets)
if [ "$t26_scanned" -eq 0 ]; then
  ko "T26 D (NÉGATIVE) : ZÉRO fichier balayé (agents d'équipe + $REFS_DIR introuvables) — un vert à vide n'est pas une garantie"
  t26_ok=0
elif [ -n "$t26_dup_hits" ]; then
  ko "T26 D (NÉGATIVE) : intitulé du contrat interne de l'exécuteur reproduit dans —$t26_dup_hits"
  t26_ok=0
else
  ok "T26 D (NÉGATIVE) : $t26_scanned fichier(s) de doctrine balayé(s), aucun ne reproduit les intitulés du contrat interne de l'exécuteur amont"
fi

# E (DISCRIMINANT, par mutation) — deux fixtures temporaires : l'une portant un intitulé du
# contrat interne doit faire échouer l'assertion D ; l'autre, un contrat de reprise dont
# l'énumération n'est plus close (sous-champ supplémentaire hors liste), doit faire échouer A.
T26_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T26_TMPDIR"
T26_FIXTURE="$T26_TMPDIR/duplicated-contract.md"
T26_MUT_CONTRACT="$T26_TMPDIR/contrat-non-clos.md"
printf '## Rapport de reprise\n\n**Completed Tasks** table (hashes + files)\n' > "$T26_FIXTURE"
sed 's/et en particulier \*\*pas\*\* la table/plus `taches_executees`, et en particulier **pas** la table/' \
  "$CONTRACTS_FILE" > "$T26_MUT_CONTRACT"
t26_e_ko=""
[ -n "$(t26_internal_titles "$T26_FIXTURE")" ] || t26_e_ko="$t26_e_ko [fixture d'intitulé interne non détectée par D]"
t26_reprise_closed "$T26_MUT_CONTRACT" && t26_e_ko="$t26_e_ko [sous-champ hors énumération non détecté par A]"
t26_reprise_closed "$CONTRACTS_FILE"   || t26_e_ko="$t26_e_ko [le contrat réel ne tient plus l'assertion A]"
if [ -n "$t26_e_ko" ]; then
  ko "T26 E (DISCRIMINANT) : une assertion ne rougit pas sur mutation —$t26_e_ko"; t26_ok=0
else
  ok "T26 E (DISCRIMINANT) : intitulé du contrat interne détecté par D, sous-champ hors énumération détecté par A, contrat réel tenu"
fi

[ "$t26_ok" -eq 1 ] && ok "T26 : minimum de reprise ($T26_N sous-champs mesurés), halte de nœud, réponse par le manager, garde anti-duplication ADR-030 discriminante par mutation"

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
