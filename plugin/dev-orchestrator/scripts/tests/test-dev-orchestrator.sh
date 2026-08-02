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

# Le fichier REPLIÉ : tout saut de ligne devient un blanc, le reste est intact. À coupler
# SYSTÉMATIQUEMENT à des blancs élastiques ([[:space:]]+) dans le motif. Défini ICI, avant toute
# assertion, parce que ses appelants s'échelonnent de T7 à T27.
#
# POURQUOI (B6, revue du 2026-08-02). grep travaille LIGNE À LIGNE. Sur des fichiers de doctrine
# wrappés à 100 colonnes, un motif MULTI-MOTS à espace littéral n'est jamais vu dès qu'il tombe à
# cheval sur deux lignes — et rendre ses blancs élastiques n'y change RIEN tant que le fichier
# n'est pas replié, puisque le saut de ligne est le séparateur d'enregistrement, pas un blanc.
# Sur une garde NÉGATIVE (« aucun fichier ne reproduit … »), l'évasion est silencieuse : la garde
# reste VERTE sur exactement ce qu'elle interdit. Sur une assertion POSITIVE, elle produit un faux
# ROUGE sur un simple re-wrap. Les deux sont des défauts de sonde.
#
# md_blocks_matching règle le même problème DANS un bloc ; md_folded le règle à l'échelle du
# FICHIER, là où la propriété mesurée n'est bornée à aucun bloc. Contrepartie assumée : deux
# paragraphes voisins se retrouvent adjacents — un motif pourrait donc enjamber une frontière de
# paragraphe. C'est le sens fail-closed (faux rouge bruyant), jamais le faux vert silencieux ;
# quand la propriété EST bornée à un bloc, utiliser md_blocks_matching, pas ceci.
md_folded() { [ -f "$1" ] || return 0; tr '\n' ' ' < "$1"; }

# MUTATION tolérante au pli — même défaut B6, versant fabrication de mutants. `sed` est ligne à
# ligne : un motif de mutation MULTI-MOTS ne mord pas quand le wrap à 100 colonnes le coupe en
# deux, et le mutant redevient identique à l'original. Les gardes `cmp -s` le disent (fail-closed,
# jamais un faux vert) — mais c'est un faux ROUGE sur un re-wrap parfaitement légitime, et une
# suite qui rougit sur une réécriture correcte nuit autant qu'une suite aveugle.
#
# On replie donc le fichier sur un octet qui ne peut pas apparaître dans un .md (\001), on mute
# avec des blancs élastiques INCLUANT cet octet, puis on rétablit les sauts de ligne. Les blancs
# du motif s'écrivent $MDSP (« un ou plusieurs blancs, pli compris »). Seuls les blancs consommés
# PAR le motif disparaissent : le reste du wrap est intact, comme après toute mutation.
MD_FOLD_SEP=$'\001'
MDSP="[[:space:]${MD_FOLD_SEP}]+"
md_sed_folded() { # <expression sed -E, blancs écrits $MDSP> <fichier>
  tr '\n' "$MD_FOLD_SEP" < "$2" | sed -E "$1" | tr "$MD_FOLD_SEP" '\n'
}

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
#
# Défini ICI, avec md_folded/md_sed_folded, parce que ses appelants s'échelonnent désormais de T23
# à T27 — il vivait dans l'outillage T24/T25/T26, donc hors de portée de T23 qui s'exécute avant.
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
#
# Portée RÉELLE de ce trap (ne pas surdéclarer) : la grande majorité des ~40 `mktemp` de cette
# suite sont nettoyés INLINE par leur propre test (`rm -rf` en fin de bloc) et ne s'enregistrent
# pas ici. `vf_tmp_track` sert aux temporaires dont la durée de vie va jusqu'à la fin du script —
# les fixtures T24/T25/T26, relues après leur bloc — et au stub PATH de T2b, partagé par plusieurs
# assertions. Une phrase du type « tout mktemp s'enregistre via vf_tmp_track » serait fausse.
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
T2B_STUB="$(mktemp -d)"; vf_tmp_track "$T2B_STUB"   # partagé par toutes les assertions T2b
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
# « premier usage » est multi-mots : mesure sur le corps REPLIÉ, blancs élastiques (B6). Le
# comptage reste comparé à « ≥ 1 » — replier ramène le compte à 0 ou 1, jamais à une autre décision.
has_marker=$("$GREP" -v '^#' "$AGENT_FILE" | tr '\n' ' ' | "$GREP" -ciE 'first-use|premier[[:space:]]+usage')
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
  # Motifs multi-mots → fichier REPLIÉ + blancs élastiques (B6). Aujourd'hui ils sont portés par des
  # titres ATX, atomiques par construction ; demain la seule occurrence peut vivre en prose wrappée.
  if md_folded "$CONTRACTS" | "$GREP" -qiE "Brief[[:space:]]+de[[:space:]]+mission" \
     && md_folded "$CONTRACTS" | "$GREP" -qiE "Rapport[[:space:]]+de[[:space:]]+mission" \
     && "$GREP" -q "SEUIL_EQUIPE" "$CONTRACTS"; then
    ok "T9 contrats : mission-contracts.md présent (Brief + Rapport + SEUIL_EQUIPE)"
  else
    ko "T9 contrats : mission-contracts.md incomplet (Brief/Rapport/SEUIL_EQUIPE manquant)"
  fi
  # Digest de mission (manager → workers) : le contrat DIGEST doit être défini ici et
  # seulement ici (audit 2026-07-25 : sans lui, 100-200k tokens de relecture par étape).
  if "$GREP" -q "DIGEST" "$CONTRACTS" \
     && md_folded "$CONTRACTS" | "$GREP" -qiE "Digest[[:space:]]+de[[:space:]]+mission"; then
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
  # $desc est déjà REPLIÉE (tr ci-dessus) mais garde l'indentation YAML des lignes de continuation :
  # blancs élastiques obligatoires (B6), sinon un simple repli de la description ferait rougir.
  echo "$desc" | "$GREP" -qiE "Utiliser[[:space:]]+quand" || { ko "T12 skills : description de $sk sans déclencheur « Utiliser quand »"; t12_ok=0; }
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
# EXISTENCE → RELATION (revue du 2026-08-02). La forme précédente comptait séparément
# `gsd-ingest-docs` et `ingestion-flow` sur le fichier ENTIER, puis concluait « ligne enrichie ».
# Une « ligne enrichie » est pourtant une RELATION : la brique et sa doctrine sur la MÊME ligne
# physique — c'est ce qui fait qu'un lecteur de la carte trouve l'une par l'autre. Séparer les deux
# moitiés dans deux sections sans rapport laissait la sonde verte. Idiome de chaînage déjà employé
# par T22 (ligne rouge --force, frontière vibeflow-os) : trois greps sur le MÊME flux.
#
# Contrepartie assumée, identique à celle de T22 : la mesure porte sur la ligne PHYSIQUE, donc elle
# est sensible à un repli. C'est délibéré — replier le fichier (md_folded) rendrait « même ligne »
# trivialement vrai et détruirait la propriété mesurée. Les deux cibles sont aujourd'hui des lignes
# de tableau markdown, atomiques par construction.
t17_enriched_line() { # <file> <motif ERE A> <motif ERE B> — vrai si UNE ligne porte les deux
  "$GREP" -E -- "$2" "$1" 2>/dev/null | "$GREP" -qE -- "$3"
}

t17_ok=1
if t17_enriched_line "$AGENT_FILE" 'ingestion-flow' 'gsd-ingest-docs|gsd-import'; then
  :
else
  ko "T17 routage : AGENT.md sans ligne d'intention d'ingestion explicite (doctrine et brique doivent tenir sur la MÊME ligne de la table)"; t17_ok=0
fi
if [ -f "$ROUTING" ]; then
  t17_enriched_line "$ROUTING" 'gsd-ingest-docs' 'ingestion-flow' \
    || { ko "T17 routage : intent-routing.md sans ligne enrichie (gsd-ingest-docs + ingestion-flow sur la MÊME ligne)"; t17_ok=0; }
else
  ko "T17 routage : $ROUTING introuvable"; t17_ok=0
fi
[ "$t17_ok" -eq 1 ] && ok "T17 routage : AGENT.md + intent-routing.md câblent l'intention d'ingestion"

# ---------------------------------------------------------------------------
# T17b (DISCRIMINANT) — la « ligne enrichie » de T17 est mesurée en RELATION, pas en co-présence.
# ---------------------------------------------------------------------------
# Contrôle positif par SCISSION : sur chaque ligne portant les deux motifs, un retour à la ligne est
# inséré JUSTE AVANT le second. Aucun token n'est retiré — les deux moitiés restent dans le fichier,
# et c'est vérifié ici : c'est la partie qui prouve que la forme précédente (deux greps indépendants
# sur le fichier entier) serait restée VERTE sur ce mutant. L'ancre de la scission est le TOKEN
# mesuré lui-même, pas une tournure : une reformulation de la ligne de table ne la rend pas no-op,
# et si elle le devenait le garde `cmp -s` le dit.
T17B_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T17B_TMPDIR"
t17b_ko=""
t17b_split() { # <file src> <motif A> <motif B> <file dst> — coupe la ligne juste avant B
  # La coupe tombe devant le motif le PLUS À DROITE des deux, quel que soit leur ordre de
  # rédaction : couper devant le premier laisserait les deux moitiés du côté droit, et le mutant ne
  # séparerait rien. Coupe > 1 exigée pour la même raison ; sinon on ne coupe pas et le garde
  # `cmp -s` signale le no-op au lieu de le laisser passer pour vert.
  awk -v a="$2" -v b="$3" '
    {
      pa = match($0, a); pb = match($0, b)
      if (pa > 0 && pb > 0) {
        cut = (pa > pb) ? pa : pb
        if (cut > 1) { print substr($0, 1, cut - 1); print substr($0, cut); next }
      }
      print
    }
  ' "$1" > "$4"
}
t17b_case() { # <libellé> <file> <motif A> <motif B>
  local mut="$T17B_TMPDIR/$(basename "$2").split"
  t17b_split "$2" "$3" "$4" "$mut"
  if cmp -s "$2" "$mut"; then
    t17b_ko="$t17b_ko [$1 : mutant IDENTIQUE à l'original — aucune ligne ne portait les deux motifs, la scission n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de T17)]"
    return
  fi
  { "$GREP" -qE -- "$3" "$mut" && "$GREP" -qE -- "$4" "$mut"; } \
    || t17b_ko="$t17b_ko [$1 : un motif a disparu du mutant — ce n'est plus une scission, le cas ne prouve plus que la co-présence restait verte]"
  t17_enriched_line "$mut" "$3" "$4" \
    && t17b_ko="$t17b_ko [$1 : NON détecté — les deux moitiés séparées sur deux lignes passent encore pour une ligne enrichie]"
}
t17b_case "AGENT.md"         "$AGENT_FILE" 'ingestion-flow' 'gsd-ingest-docs'
[ -f "$ROUTING" ] && t17b_case "intent-routing.md" "$ROUTING" 'gsd-ingest-docs' 'ingestion-flow'
if [ -z "$t17b_ko" ]; then
  ok "T17b (DISCRIMINANT) : la ligne d'intention d'ingestion est mesurée en RELATION (doctrine et brique sur la MÊME ligne) — sur les 2 cibles, la scission de la ligne en deux, sans retirer un seul token, fait rougir T17"
else
  ko "T17b (DISCRIMINANT) : la « ligne enrichie » n'est qu'une co-présence —$t17b_ko"
fi

# ---------------------------------------------------------------------------
# Outillage commun T18/T19 — appartenance à une allowlist Agent(...), mesurée en RELATION
# ---------------------------------------------------------------------------
# Ces deux helpers étaient définis dans la section T19 et n'étaient donc utilisables que par elle.
# T18, qui s'exécute AVANT, en était réduit au `grep -qF` sur la ligne `tools:` entière — la forme
# que le commentaire de T19 qualifie lui-même de tautologique. Ils sont REMONTÉS ici, à l'identique,
# pour que les deux sections mesurent la même chose ; T19 les consomme toujours, inchangés.

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
  # TAUTOLOGIE FERMÉE (revue du 2026-08-02, famille « existence au lieu de relation »). La forme
  # précédente testait chaque nom par `grep -qF` sur la ligne `tools:` ENTIÈRE — le commentaire de
  # T19 qualifie lui-même cette forme de tautologique depuis Phase 16, et T19 s'en est débarrassé
  # côté workers ; T18, qui s'exécute avant, l'avait gardée. Ce qu'elle mesurait : « le nom apparaît
  # QUELQUE PART sur la ligne ». Ce que le libellé promet : « le nom est DANS l'allowlist Agent(...) ».
  # Un nom sorti des parenthèses et replacé ailleurs sur la même ligne (`Bash(<nom>)`) conserve tous
  # les tokens et restait vert — le cloisonnement était donc annoncé et non mesuré. On passe à
  # l'extraction BORNÉE aux parenthèses + égalité de token, comme T19 (T18c le prouve par mutation).
  #
  # La borne `)[[:space:]]*$` de la forme précédente est REMPLACÉE, pas retirée : elle ne prouvait
  # que « la ligne finit par ) » (un autre tool parenthésé — `Bash(git:*)` — la satisfaisait avec
  # une allowlist jamais refermée). Le comptage de profondeur ci-dessous prouve strictement plus,
  # donc le « parenthèse fermée » du libellé d'ok reste vrai.
  dmt_content="$(extract_agent_allowlist "$dmt")"; dmt_rc=$?
  if [ "$dmt_rc" -eq 2 ]; then
    ko "T18 cloisonnement : aucune allowlist Agent( ) extractible de la ligne tools: du manager"; t18_ok=0
  elif [ "$dmt_rc" -eq 1 ]; then
    ko "T18 cloisonnement : allowlist Agent(...) non refermée (parenthèses déséquilibrées, comptage de profondeur)"; t18_ok=0
  else
    # Chacun des 18 noms attendus, testé UN PAR UN (jamais un grep global satisfait par le premier),
    # et par ÉGALITÉ DE TOKEN dans le contenu des parenthèses (jamais une sous-chaîne de la ligne).
    for name in $T18_ALLOWED; do
      allowlist_has_name "$dmt_content" "$name" || { ko "T18 cloisonnement : « $name » absent de l'allowlist Agent(...) du manager (extraction bornée aux parenthèses)"; t18_ok=0; }
    done
    # Interdit structurel, versant TOKEN EXACT dans les parenthèses.
    allowlist_has_name "$dmt_content" "vf-design-manager" && { ko "T18 cloisonnement : vf-design-manager est un token de l'allowlist Agent(...) (imbrication manager→manager)"; t18_ok=0; }
  fi
  # Interdit structurel, versant LIGNE ENTIÈRE — CONSERVÉ en plus du test de token ci-dessus, et
  # jamais à sa place : un `vf-design-manager` glissé HORS des parenthèses (dans un `Bash(...)`, en
  # commentaire de fin de ligne) échapperait à l'extraction bornée. Fail-closed sur la ligne entière.
  # Piège : vf-design-judge contient la sous-chaîne « vf-design » — on teste le nom EXACT complet
  # « vf-design-manager », qui ne peut pas matcher « vf-design-judge » (suffixe différent).
  echo "$dmt" | "$GREP" -qF -- "vf-design-manager" && { ko "T18 cloisonnement : vf-design-manager présent dans l'allowlist (imbrication manager→manager)"; t18_ok=0; }
fi
[ "$t18_ok" -eq 1 ] && ok "T18 cloisonnement : allowlist Agent(...) complète (18 noms), vf-design-manager absent, parenthèse fermée"

# ---------------------------------------------------------------------------
# T18c (DISCRIMINANT) — la vérification de T18 mesure l'APPARTENANCE À L'ALLOWLIST, pas la présence
# d'un nom sur la ligne. Sans ce cas, rien ne distinguerait la forme bornée de la forme
# tautologique qu'elle remplace : les deux sont vertes sur le fichier réel.
#
# Deux contrôles positifs construits depuis la ligne `tools:` RÉELLE, ancrés sur des éléments
# STRUCTURELS (un token de la liste, les parenthèses) et non sur une tournure :
#   µ1 — un nom SORTI des parenthèses et replacé sur la même ligne dans `Bash(<nom>)`. AUCUN token
#        n'est retiré : le `grep -qF` historique reste vert (vérifié ici, c'est la moitié qui
#        prouve que la mutation est une RELOCALISATION et pas une suppression), l'extraction bornée
#        doit rougir.
#   µ2 — la parenthèse fermante de `Agent(` retirée, la ligne se terminant malgré tout par « ) »
#        grâce à un autre tool parenthésé (`Bash(git:*)`). L'ancienne borne `)[[:space:]]*$` reste
#        verte (vérifié), le comptage de profondeur doit rendre rc=1.
# Chaque mutant est prouvé DIFFÉRENT de l'original avant d'être mesuré — un mutant no-op ne prouve
# rien, et le dire vaut mieux que le laisser passer pour vert.
# ---------------------------------------------------------------------------
t18c_ko=""
T18C_VICTIM="gsd-roadmapper"
if [ -z "$dmt" ]; then
  t18c_ko="$t18c_ko [ligne tools: du manager introuvable — rien à muter]"
else
  # µ1 — relocalisation d'un nom hors des parenthèses Agent(...).
  t18c_mu1="$(printf '%s' "$dmt" | sed -e "s/,[[:space:]]*${T18C_VICTIM}\([,)]\)/\1/")"
  t18c_mu1="$t18c_mu1, Bash($T18C_VICTIM)"
  if [ "$t18c_mu1" = "$dmt" ]; then
    t18c_ko="$t18c_ko [µ1 : mutant IDENTIQUE à l'original — « $T18C_VICTIM » n'est plus dans la liste sous cette graphie, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de T18)]"
  else
    printf '%s' "$t18c_mu1" | "$GREP" -qF -- "$T18C_VICTIM" \
      || t18c_ko="$t18c_ko [µ1 : le nom a disparu de la ligne — ce n'est plus une relocalisation, le cas ne prouve plus que la forme tautologique restait verte]"
    if allowlist_has_name "$(extract_agent_allowlist "$t18c_mu1")" "$T18C_VICTIM"; then
      t18c_ko="$t18c_ko [µ1 : NON détecté — un nom sorti des parenthèses Agent(...) est encore compté comme cloisonné]"
    fi
  fi
  # µ2 — allowlist jamais refermée, mais ligne se terminant par « ) ».
  #
  # Le garde no-op porte sur le RÉSULTAT DU `sed` SEUL, jamais sur le mutant final. Comparer
  # « $dmt privé de sa parenthèse + `, Bash(git:*)` » à `$dmt` ne pouvait JAMAIS être vrai : la
  # concaténation garantit la différence. Le garde était donc mort, et un `sed` qui ne mord pas —
  # une ligne `tools:` qui ne se termine pas par « ) » — produisait un mutant ÉQUILIBRÉ, donc un
  # KO « µ2 : NON détecté … » qui accuse T18 alors que la mutation n'avait pas eu lieu. Même
  # défaut, même remède que le garde de µ1 juste au-dessus, dont c'est la forme exacte.
  t18c_mu2_stripped="$(printf '%s' "$dmt" | sed -e 's/)[[:space:]]*$//')"
  t18c_mu2="$t18c_mu2_stripped, Bash(git:*)"
  if [ "$t18c_mu2_stripped" = "$dmt" ]; then
    t18c_ko="$t18c_ko [µ2 : mutant IDENTIQUE à l'original — la ligne tools: ne se termine pas par « ) », la parenthèse fermante n'a donc pas été retirée et la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de T18)]"
  else
    printf '%s' "$t18c_mu2" | "$GREP" -qE '\)[[:space:]]*$' \
      || t18c_ko="$t18c_ko [µ2 : la ligne mutée ne finit plus par « ) » — le cas ne prouve plus que l'ancienne borne restait verte]"
    extract_agent_allowlist "$t18c_mu2" >/dev/null
    [ $? -eq 1 ] || t18c_ko="$t18c_ko [µ2 : NON détecté — une allowlist Agent(...) jamais refermée passe encore, dès qu'un autre tool parenthésé clôt la ligne]"
  fi
  # Contrôle NÉGATIF : la ligne RÉELLE, elle, doit rester verte sur les deux propriétés.
  allowlist_has_name "$(extract_agent_allowlist "$dmt")" "$T18C_VICTIM" \
    || t18c_ko="$t18c_ko [FAUX ROUGE : « $T18C_VICTIM » n'est pas reconnu dans l'allowlist RÉELLE du manager]"
fi
if [ -z "$t18c_ko" ]; then
  ok "T18c (DISCRIMINANT) : l'allowlist du manager est mesurée en APPARTENANCE (extraction bornée aux parenthèses + égalité de token) — un nom relocalisé hors des parenthèses sans perdre un seul token de la ligne, et une allowlist jamais refermée dont la ligne finit pourtant par « ) », font tous deux rougir T18 ; la ligne réelle reste verte"
else
  ko "T18c (DISCRIMINANT) : la vérification d'allowlist du manager ne discrimine pas —$t18c_ko"
fi

# T18b — Success Criteria 1 et 3 : doctrine étage design présente, routage vf-auto → design pur
t18b_ok=1
# Formules MULTI-MOTS sur des .md wrappés à 100 colonnes : mesure sur le fichier REPLIÉ + blancs
# élastiques (B6) — sinon un re-wrap légitime les ferait rougir à tort.
md_folded "$DEVMGR" | "$GREP" -qiE 'Étage[[:space:]]+design[[:space:]]+croisé' || { ko "T18b SC1 : doctrine étage design absente de vf-dev-manager.md"; t18b_ok=0; }
"$GREP" -q 'mission-cross-team' "$DEVMGR" || { ko "T18b SC1 : renvoi vers mission-cross-team.md absent de vf-dev-manager.md"; t18b_ok=0; }
AUTO_SKILL="$MOD/skills/vf-auto/SKILL.md"
if [ -f "$AUTO_SKILL" ]; then
  "$GREP" -q 'vf-design-manager' "$AUTO_SKILL" || { ko "T18b SC3 : vf-auto/SKILL.md ne route pas vers vf-design-manager"; t18b_ok=0; }
  md_folded "$AUTO_SKILL" | "$GREP" -qiE 'zéro[[:space:]]+feature' || { ko "T18b SC3 : signal « mission entièrement design (zéro feature) » absent de vf-auto"; t18b_ok=0; }
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

# `extract_agent_allowlist` et `allowlist_has_name` sont définis PLUS HAUT (outillage commun
# T18/T19) : T18 s'exécute avant cette section et doit mesurer la même relation. Ils sont utilisés
# ici tels quels.

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

t21d_total_mktemp=0
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
  # LIMITE ASSUMÉE, dite plutôt que masquée : ce que grep peut mesurer ici, c'est « il existe un
  # mktemp ⇒ il existe un trap », pas l'appariement un-à-un — un seul trap couvre légitimement
  # plusieurs mktemp, et rien dans le texte ne relie tel trap à tel mktemp. La branche « ou aucun
  # mktemp » est, elle, un VERT À VIDE : deux des trois scripts n'utilisent aucun mktemp, leur ok
  # ne verrouille donc rien. Il n'est pas retiré (l'invariant reste vrai pour eux, et le libellé le
  # déclare), mais il ne peut pas tenir lieu de garantie : le compteur d'atteinte ci-dessous exige
  # qu'AU MOINS UN des scripts balayés exerce réellement la règle.
  t21d_mktemp_count=$(echo "$T21_BODY" | "$GREP" -c 'mktemp')
  t21d_trap_count=$(echo "$T21_BODY" | "$GREP" -cE 'trap.*EXIT')
  t21d_total_mktemp=$((t21d_total_mktemp + t21d_mktemp_count))
  if [ "${t21d_mktemp_count:-0}" -gt 0 ] && [ "${t21d_trap_count:-0}" -eq 0 ]; then
    ko "T21d invariants SC5 : $T21_NAME — $t21d_mktemp_count mktemp sans trap ... EXIT"
  else
    ok "T21d invariants SC5 : $T21_NAME — mktemp ($t21d_mktemp_count) apparié à trap ... EXIT, ou aucun mktemp"
  fi
done

# T21d ATTEINTE — sans ce cas, la règle « mktemp ⇒ trap » pourrait être verte trois fois sur trois
# sans avoir jamais été exercée : les trois ok se contenteraient de leur branche « ou aucun mktemp ».
# C'est le vert à vide, décliné sur un balayage de scripts au lieu d'un balayage de doctrine.
if [ "$t21d_total_mktemp" -gt 0 ]; then
  ok "T21d atteinte : $t21d_total_mktemp mktemp effectivement vu(s) dans les 3 scripts balayés — la règle « mktemp ⇒ trap ... EXIT » est exercée au moins une fois, pas seulement satisfaite à vide"
else
  ko "T21d atteinte : AUCUN mktemp dans les 3 scripts balayés — les trois ok de T21d ne tiennent que par leur branche « ou aucun mktemp », la règle n'est exercée nulle part"
fi

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
  # Formulations MULTI-MOTS → fichier REPLIÉ + blancs élastiques (B6). Elles vivent aujourd'hui dans
  # des lignes de tableau, atomiques par construction ; rien ne garantit qu'elles y restent.
  md_folded "$ROUTING" | "$GREP" -qE "dit[[:space:]]+encore[[:space:]]+vrai" || { ko "T22 captation : la formulation d'audit « dit encore vrai » n'est pas captée"; t22_ok=0; }
  md_folded "$ROUTING" | "$GREP" -qE "refais[[:space:]]+toute[[:space:]]+la[[:space:]]+doc" || { ko "T22 captation : la formulation de régénération « refais toute la doc » n'est pas captée"; t22_ok=0; }
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

# Les QUATRE déclencheurs sont un ENSEMBLE : ils déclenchent le MÊME nœud, et c'est cet « au moins
# un des quatre » qui est la doctrine. Mesurés un par un sur le fichier ENTIER, ils ne mesuraient
# que quatre présences sans lien — « milestone » et « capacité » sont des mots courants de ces
# agents, et une énumération démantelée aux quatre coins du fichier restait verte (famille
# « existence au lieu de relation », revue du 2026-08-02). L'exigence de CO-LOCALISATION ci-dessous
# s'AJOUTE aux quatre présences, elle ne les remplace pas.
#
# Elle ne s'ancre sur AUCUNE tournure : ancre « . » (tous les blocs), et on demande qu'il en existe
# UN qui porte les quatre. Une réécriture de l'énumération — autres mots de liaison, autre ordre,
# autre intitulé — reste donc verte tant que les quatre déclencheurs restent énumérés ensemble.
t23_triggers_colocated() { # <file> — 0 si UN MÊME bloc porte les quatre déclencheurs
  md_blocks_matching "$1" '.' \
    | "$GREP" -F -- "doc-drift" \
    | "$GREP" -F -- "milestone" \
    | "$GREP" -F -- "surface publique" \
    | "$GREP" -qF -- "capacité"
}

# Côté dev — $DEVMGR est déjà résolu par T18 plus haut.
"$GREP" -q "docs-flow" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne renvoie pas vers docs-flow.md"; t23_ok=0; }
"$GREP" -q -- "--id=docs" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne pose pas le nœud --id=docs"; t23_ok=0; }
for motif in "doc-drift" "milestone" "surface publique" "capacité"; do
  "$GREP" -q -- "$motif" "$DEVMGR" || { ko "T23 managers : vf-dev-manager.md ne nomme pas le déclencheur « $motif »"; t23_ok=0; }
done
t23_triggers_colocated "$DEVMGR" \
  || { ko "T23 managers : les quatre déclencheurs de vf-dev-manager.md ne tiennent pas dans un MÊME bloc — dispersés, ils ne déclenchent plus rien de commun"; t23_ok=0; }

# Côté design — skip explicite si le module n'est pas dans le périmètre scanné (cf. T6/installeur).
if [ -n "$DESIGNMGR" ]; then
  "$GREP" -q "dev-orchestrator-references/docs-flow.md" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne renvoie pas vers dev-orchestrator-references/docs-flow.md"; t23_ok=0; }
  "$GREP" -q -- "--id=docs" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne pose pas le nœud --id=docs"; t23_ok=0; }
  for motif in "doc-drift" "milestone" "surface publique" "capacité"; do
    "$GREP" -q -- "$motif" "$DESIGNMGR" || { ko "T23 managers : vf-design-manager.md ne nomme pas le déclencheur « $motif »"; t23_ok=0; }
  done
  t23_triggers_colocated "$DESIGNMGR" \
    || { ko "T23 managers : les quatre déclencheurs de vf-design-manager.md ne tiennent pas dans un MÊME bloc — dispersés, ils ne déclenchent plus rien de commun"; t23_ok=0; }
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
# T23b (DISCRIMINANT) — les quatre déclencheurs sont mesurés ENSEMBLE, pas un par un.
# ---------------------------------------------------------------------------
# Contrôle positif par DISPERSION : un déclencheur est retiré de son énumération et réécrit dans un
# bloc à part, en fin de fichier. AUCUN token ne quitte le fichier — les quatre `grep -q` sur le
# fichier entier restent donc VERTS, ce qui est vérifié ici : c'est la moitié du cas qui prouve que
# la forme précédente ne mordait pas. Seule la co-localisation rompt.
#
# L'ancre de la mutation est le TOKEN mesuré (`capacité`), pas une tournure : une reformulation de
# l'énumération ne la rend pas no-op, et si elle le devenait le garde `cmp -s` le dit.
T23B_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T23B_TMPDIR"
t23b_ko=""
t23b_case() { # <libellé> <fichier>
  local mut="$T23B_TMPDIR/$(basename "$2").disperse"
  sed 's/capacité//g' "$2" > "$mut"
  printf '\n- **Note (bloc injecté)** : ce module expose une nouvelle capacité.\n' >> "$mut"
  if cmp -s "$2" "$mut"; then
    t23b_ko="$t23b_ko [$1 : mutant IDENTIQUE à l'original — la dispersion n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de T23)]"
    return
  fi
  "$GREP" -qF -- "capacité" "$mut" \
    || t23b_ko="$t23b_ko [$1 : le déclencheur a quitté le fichier — ce n'est plus une dispersion, le cas ne prouve plus que les quatre présences restaient vertes]"
  for t23b_m in "doc-drift" "milestone" "surface publique" "capacité"; do
    "$GREP" -q -- "$t23b_m" "$mut" \
      || t23b_ko="$t23b_ko [$1 : « $t23b_m » absent du mutant — la forme « quatre présences » aurait rougi, le cas ne discrimine plus rien]"
  done
  t23_triggers_colocated "$mut" \
    && t23b_ko="$t23b_ko [$1 : NON détecté — un déclencheur sorti de l'énumération et réécrit ailleurs passe encore]"
}
t23b_case "vf-dev-manager.md" "$DEVMGR"
[ -n "$DESIGNMGR" ] && t23b_case "vf-design-manager.md" "$DESIGNMGR"
# Contrôle NÉGATIF : les fichiers RÉELS, eux, doivent rester verts.
t23_triggers_colocated "$DEVMGR" || t23b_ko="$t23b_ko [FAUX ROUGE : vf-dev-manager.md RÉEL ne porte plus les quatre déclencheurs dans un même bloc]"
if [ -z "$t23b_ko" ]; then
  ok "T23b (DISCRIMINANT) : les quatre déclencheurs du nœud docs sont mesurés en CO-LOCALISATION (un même bloc), pas en quatre présences indépendantes — la dispersion de l'un d'eux hors de l'énumération, sans qu'un seul token quitte le fichier et avec les quatre présences restées vertes, fait rougir T23"
else
  ko "T23b (DISCRIMINANT) : les quatre déclencheurs ne sont que quatre présences —$t23b_ko"
fi

# ---------------------------------------------------------------------------
# Outillage commun T24/T25/T26 — assertions BORNÉES AU BLOC, jamais « la chaîne existe quelque
# part dans le fichier ». Un grep global ne relie rien à rien : il reste vert quand la sémantique
# du contrat est inversée (mapping D-01 retourné vers gaps_found, sous-champ renommé…).
# ---------------------------------------------------------------------------

# `md_blocks_matching` est défini TOUT EN HAUT, avec md_folded/md_sed_folded : ses appelants
# commencent désormais à T23, qui s'exécute avant cette section.

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
# T24 (tracer, D-01) — le mapping du checkpoint amont traverse mission-contracts → vf-coder →
# table de pilotage. La règle est UNE règle à DEUX motifs : gate="blocking-human" OU précondition
# amont non satisfaite ⇒ statut `human_needed`.
#
# DÉPLACEMENT DE CIBLE (A-4, déport). La cible C était le bloc « Verdict d'étape » de
# vf-dev-manager.md ; ce bloc vit désormais dans mission-flow.md §Pattern C (« Contrôle de flux du
# manager »), l'agent n'en garde qu'un renvoi. La sonde SUIT le bloc : une sonde restée sur
# l'ancienne cible mesurerait un fichier où la clause n'habite plus — verte et morte, le mode
# d'échec que cette phase a déjà produit. Le renvoi de l'agent est gaté à part (T27, volet renvoi).
#
# L'assertion mesure une RELATION, pas une co-présence. Exiger trois chaînes indépendantes dans un
# bloc ne verrouille rien dès que le bloc énumère PLUSIEURS statuts : celui de la table de pilotage
# couvre 4 verdicts — une doctrine disant l'INVERSE de D-01 (gate ⇒ gaps_found) y
# satisfait les trois sondes par des phrases sans rapport entre elles.
#
# Les trois cibles n'écrivent PAS la règle sous la même forme rhétorique. Une sonde unique ne
# mordait donc que sur UNE d'entre elles, les deux autres retombant en silence sur la co-présence —
# dont le fichier de RÉFÉRENCE, l'énoncé faisant autorité de D-01 : l'y inverser laissait la suite
# à 87 OK / 0 KO. Deux formes sont reconnues, et une cible doit être couverte par l'une OU l'autre :
#
#   F1 — ÉNUMÉRATION « étiquette → mapping » (mission-flow.md §Pattern C) : le statut OUVRE une entrée. On
#        isole le SEGMENT du bloc qui lui appartient et on exige les deux motifs DANS CE SEGMENT.
#   F2 — IMPLICATION « prémisse ⇒ conséquent » (mission-contracts.md, vf-coder.md) : le statut est
#        le CONSÉQUENT, les motifs sont AVANT lui — aucune entrée à isoler. On prend, pour CHAQUE
#        occurrence de motif, le PREMIER statut qui la suit : il doit être `human_needed`.
#        Élargir le compteur d'entrées de F1 à la graphie JSON (`statut: "…"`) ne suffit pas — ça
#        rougit sur la forme à contraste explicite (⇒ `statut: "human_needed"` — jamais
#        `statut: "gaps_found"`), rédaction licite et plus précise que l'actuelle.
#
# Une cible couvrable par NI F1 NI F2 est un KO explicite (« mapping non vérifiable »). Jamais de
# repli sur la co-présence : c'est lui qui rendait le vert de deux assertions sur trois indépendant
# de ce que la doctrine dit réellement.
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

# F2 — conséquents d'implication : pour CHAQUE occurrence d'un motif de la prémisse, le PREMIER
# statut qui la suit dans le bloc (un par ligne de sortie). Sortie vide = aucun motif n'est suivi
# d'un statut : le bloc n'exprime pas d'implication, F2 ne s'applique pas (et rien n'est conclu).
t24_implication_consequents() { # bloc(s) sur stdin
  awk -v st="$T24_STATUTS" -v m1='gate="blocking-human"' -v m2='[Pp]récondition' '
    function consequents(line, motif,   rest) {
      while (match(line, motif)) {
        rest = substr(line, RSTART + RLENGTH)
        if (match(rest, "(" st ")")) print substr(rest, RSTART, RLENGTH)
        line = rest
      }
    }
    { consequents($0, m1); consequents($0, m2) }
  '
}

# 0 = mapping tenu ($T24_FORME renseignée) · 1 = forme reconnue mais mapping rompu ($T24_WHY) ·
# 2 = bloc introuvable · 3 = ni F1 ni F2 reconnaissable — mapping NON VÉRIFIABLE, jamais un repli
# silencieux sur le bloc entier, qui rouvrirait exactement la faille de co-présence.
T24_WHY=""; T24_FORME=""
t24_maps_to_human_needed() { # <file> <ancre ERE>
  local blk seg cons bad
  T24_WHY=""; T24_FORME=""        # réinitialisation à l'ENTRÉE : pas de motif périmé d'un appel précédent
  blk="$(md_blocks_matching "$1" "$2")"
  [ -n "$blk" ] || return 2

  # F1 — le statut ouvre une entrée d'énumération : on mesure DANS son segment.
  seg="$(printf '%s\n' "$blk" | t24_segment_of 'human_needed')"
  if [ -n "$seg" ]; then
    T24_FORME="F1"
    printf '%s\n' "$seg" | "$GREP" -q 'gate="blocking-human"' \
      || { T24_WHY="segment (F1) du statut human_needed sans le motif gate=\"blocking-human\" — il est rattaché à un autre verdict"; return 1; }
    printf '%s\n' "$seg" | "$GREP" -qi 'précondition' \
      || { T24_WHY="segment (F1) du statut human_needed sans le motif de précondition amont — il est rattaché à un autre verdict"; return 1; }
    return 0
  fi

  # F2 — le statut est le conséquent : chaque motif doit impliquer human_needed, et lui seul.
  cons="$(printf '%s\n' "$blk" | t24_implication_consequents)"
  if [ -n "$cons" ]; then
    T24_FORME="F2"
    printf '%s\n' "$blk" | "$GREP" -q 'gate="blocking-human"' \
      || { T24_WHY="prémisse (F2) sans le motif gate=\"blocking-human\" — la règle n'a plus ses DEUX motifs"; return 1; }
    printf '%s\n' "$blk" | "$GREP" -qi 'précondition' \
      || { T24_WHY="prémisse (F2) sans le motif de précondition amont — la règle n'a plus ses DEUX motifs"; return 1; }
    bad="$(printf '%s\n' "$cons" | "$GREP" -vx 'human_needed' | LC_ALL=C sort -u | tr '\n' ' ')"
    [ -z "$bad" ] || { T24_WHY="un motif de la prémisse implique un AUTRE statut que human_needed — conséquent(s) mesuré(s) : $bad"; return 1; }
    return 0
  fi

  T24_WHY="ni entrée d'énumération (« \`human_needed\` — … », F1) ni implication (motif ⇒ statut, F2) — mapping non vérifiable"
  return 3
}

t24_formes=""
t24_assert() { # <libellé> <fichier> <ancre ERE>
  if [ ! -f "$2" ]; then ko "T24 $1 : fichier introuvable ($2)"; t24_ok=0; return; fi
  t24_maps_to_human_needed "$2" "$3"
  case $? in
    0) t24_formes="$t24_formes ${1%% *}=$T24_FORME" ;;
    2) ko "T24 $1 : bloc porteur de la règle de mapping introuvable dans $(basename "$2") (ancre /$3/)"; t24_ok=0 ;;
    3) ko "T24 $1 : dans $(basename "$2"), $T24_WHY — un KO explicite vaut mieux qu'un vert obtenu par co-présence"; t24_ok=0 ;;
    *) ko "T24 $1 : dans $(basename "$2"), $T24_WHY"; t24_ok=0 ;;
  esac
}

"$GREP" -q '^## Contrat de checkpoint amont' "$CONTRACTS_FILE" 2>/dev/null \
  || { ko "T24 A : section « Contrat de checkpoint amont » absente de mission-contracts.md"; t24_ok=0; }
# Ancres NOMMÉES : les mêmes servent aux assertions et aux mutants de D — un mutant mesuré sur une
# autre ancre que sa cible ne prouverait rien de cette cible.
# Blancs ÉLASTIQUES (B6) : l'ancre est confrontée au buffer RECOLLÉ de md_blocks_matching, où le
# pli du wrap à 100 colonnes laisse l'indentation de la ligne suivante. Une ancre à espace littéral
# ne rougirait pas franchement : elle rendrait rc=2 (« bloc introuvable ») sur un simple re-wrap.
T24_ANCHOR_A='[*][*]Règle[[:space:]]+unique[[:space:]]+de[[:space:]]+mapping[*][*]'
T24_ANCHOR_B='[*][*][`]gate[`][*][*]'
T24_ANCHOR_C='[*][*]Verdict[[:space:]]+d'
t24_assert "A (mission-contracts.md, §Règle unique de mapping)" "$CONTRACTS_FILE" "$T24_ANCHOR_A"
t24_assert "B (vf-coder.md, bloc du champ gate)"                "$CODER_FILE"     "$T24_ANCHOR_B"
t24_assert "C (mission-flow.md, bloc Verdict d'étape)"          "$MFLOW"          "$T24_ANCHOR_C"

# D (DISCRIMINANT) — cinq mutants + deux fixtures LICITES, couvrant les DEUX formes (F1 sur
# vf-dev-manager.md, F2 sur mission-contracts.md et vf-coder.md). Ce que chaque cas prouve, sans le
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
#   D5/D5' (mutation d'IMPLICATION — c'est elle qui mesure D-01 sous la forme F2, sur les deux
#   cibles où le statut est le CONSÉQUENT) : le conséquent devient `gaps_found` et l'ancien statut
#   est REMIS dans la phrase en contraste (« — jamais `statut: "human_needed"` »). Aucun token
#   n'est retiré du bloc : la co-présence reste satisfaite, seule la relation s'inverse. C'est
#   exactement l'état qui laissait la suite à 87 OK / 0 KO sur le fichier de RÉFÉRENCE.
#
#   D4/D6 (fixtures LICITES) : une rédaction correcte mais REFORMULÉE de la règle doit rester
#   VERTE. D4 la reformule en énumération (autre marqueur de mapping, autre ordre, autres mots de
#   liaison) ; D6 est le miroir exact de D5 — même contraste, ordre inverse (⇒ `human_needed` —
#   jamais `gaps_found`), donc rédaction PLUS précise que l'actuelle. Une sonde qui punit une
#   réécriture légitime nuit autant qu'une sonde aveugle.
T24_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T24_TMPDIR"
T24_MUT_STATUT="$T24_TMPDIR/mutant-statut.md"
T24_MUT_GATE="$T24_TMPDIR/mutant-gate.md"
T24_MUT_RELATION="$T24_TMPDIR/mutant-relation.md"
T24_MUT_IMPL_REF="$T24_TMPDIR/mutant-implication-reference.md"
T24_MUT_IMPL_CODER="$T24_TMPDIR/mutant-implication-coder.md"
T24_LICIT="$T24_TMPDIR/licite-reformulee.md"
T24_LICIT_CONTRASTE="$T24_TMPDIR/licite-contraste.md"
sed 's/human_needed/gaps_found/g'      "$MFLOW" > "$T24_MUT_STATUT"
sed 's/blocking-human/blocking-auto/g' "$MFLOW" > "$T24_MUT_GATE"
sed -e 's/`human_needed`/`@@VFSWAP@@`/g' -e 's/`gaps_found`/`human_needed`/g' \
    -e 's/`@@VFSWAP@@`/`gaps_found`/g' "$MFLOW" > "$T24_MUT_RELATION"
# Guillemets SIMPLES obligatoires : l'expression porte des backticks, qui seraient une substitution
# de commande entre guillemets doubles. L'expansion de "$T24_INVERT_SED" n'est, elle, pas réévaluée.
# `g` explicite : le fichier étant replié en UNE ligne, « la première occurrence de chaque ligne »
# (comportement d'origine, 2 lignes porteuses dans vf-coder.md) devient « la première du fichier ».
T24_INVERT_SED='s/`statut:'"$MDSP"'"human_needed"`/`statut: "gaps_found"` — jamais `statut: "human_needed"`/g'
md_sed_folded "$T24_INVERT_SED" "$CONTRACTS_FILE" > "$T24_MUT_IMPL_REF"
md_sed_folded "$T24_INVERT_SED" "$CODER_FILE"     > "$T24_MUT_IMPL_CODER"

cat > "$T24_LICIT" <<'T24LICIT'
## Contrôle de flux

- **Verdict d'étape (rapport typé, ADR-053)** : `passed` → nœud marqué fait, frontière suivante ·
  `human_needed` : tout refus d'auto-approbation venu de l'amont — un checkpoint
  `gate="blocking-human"` aussi bien qu'une précondition amont non satisfaite — remonte en
  escalade, jamais tranché seul · `gaps_found` → relance de comblement, puis arbitrage ·
  `blocked` → laisser le nœud en l'état et traiter la dépendance.
T24LICIT

cat > "$T24_LICIT_CONTRASTE" <<'T24L6'
## Contrat de checkpoint amont

**Règle unique de mapping** (une règle, deux motifs, ADR-030) : `gate="blocking-human"` **OU** une
précondition amont non satisfaite ⇒ `statut: "human_needed"` — jamais `statut: "gaps_found"`, qui
ne couvre que les manques constatés en revue.
T24L6

t24_mut_ko=""
# Preuve que D3 est bien une mutation de RELATION et pas un effacement : une fois les deux
# étiquettes ramenées au même jeton canonique, le multiset de tokens doit être IDENTIQUE de part et
# d'autre. (Le cas « mutant identique à l'original » est traité par le garde commun ci-dessous.)
t24_canon() { sed -e 's/human_needed/@VFST@/g' -e 's/gaps_found/@VFST@/g' "$1" | tr -cs '[:alnum:]_@' '\n' | LC_ALL=C sort; }
if [ "$(t24_canon "$MFLOW")" != "$(t24_canon "$T24_MUT_RELATION")" ]; then
  t24_mut_ko="$t24_mut_ko [mutant de relation : le multiset canonique de tokens a changé — ce n'est plus une mutation de relation pure]"
fi

# Garde commun à TOUS les mutants (symétrie avec T26 E) : un mutant identique à son original est une
# mutation qui n'a rien mordu — le motif visé n'existe plus dans la doctrine. Le dire explicitement,
# jamais le laisser passer pour vert, et ne jamais accuser la doctrine à la place de la sonde.
t24_assert_mutant_red() { # <libellé> <original> <mutant> <ancre ERE>
  if cmp -s "$2" "$3"; then
    t24_mut_ko="$t24_mut_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de l'assertion)]"
    return
  fi
  t24_maps_to_human_needed "$3" "$4"
  case $? in
    1) : ;;
    0) t24_mut_ko="$t24_mut_ko [$1 : NON détecté]" ;;
    2) t24_mut_ko="$t24_mut_ko [$1 : rc=2, ancre du bloc détruite — rien n'a été mesuré, ce n'est pas une détection]" ;;
    *) t24_mut_ko="$t24_mut_ko [$1 : rc=3, forme du mapping non reconnaissable — rien n'a été mesuré là où on prétend mesurer]" ;;
  esac
}

t24_assert_mutant_red "D1 VALEUR statut human_needed→gaps_found (F1)"          "$MFLOW"          "$T24_MUT_STATUT"     "$T24_ANCHOR_C"
t24_assert_mutant_red "D2 VALEUR gate blocking-human→blocking-auto (F1)"       "$MFLOW"          "$T24_MUT_GATE"       "$T24_ANCHOR_C"
t24_assert_mutant_red "D3 RELATION, aucun token retiré (F1)"                   "$MFLOW"          "$T24_MUT_RELATION"   "$T24_ANCHOR_C"
t24_assert_mutant_red "D5 IMPLICATION inversée dans la RÉFÉRENCE (F2)"         "$CONTRACTS_FILE" "$T24_MUT_IMPL_REF"   "$T24_ANCHOR_A"
t24_assert_mutant_red "D5' IMPLICATION inversée dans vf-coder.md (F2)"         "$CODER_FILE"     "$T24_MUT_IMPL_CODER" "$T24_ANCHOR_B"
t24_maps_to_human_needed "$T24_LICIT"           "$T24_ANCHOR_C" || t24_mut_ko="$t24_mut_ko [D4 FAUX ROUGE : une reformulation LICITE en énumération est rejetée (rc=$?, $T24_WHY)]"
t24_maps_to_human_needed "$T24_LICIT_CONTRASTE" "$T24_ANCHOR_A" || t24_mut_ko="$t24_mut_ko [D6 FAUX ROUGE : la forme à contraste explicite (⇒ human_needed — jamais gaps_found) est rejetée (rc=$?, $T24_WHY)]"
t24_maps_to_human_needed "$MFLOW"               "$T24_ANCHOR_C" || t24_mut_ko="$t24_mut_ko [le fichier réel ne tient plus l'assertion]"
if [ -n "$t24_mut_ko" ]; then
  ko "T24 D (DISCRIMINANT) : l'assertion de mapping ne discrimine pas —$t24_mut_ko"; t24_ok=0
else
  ok "T24 D (DISCRIMINANT) : 5 mutants font rougir l'assertion — 2 de VALEUR et 1 de RELATION sur la forme F1, 2 d'IMPLICATION (conséquent inversé, tous les tokens conservés) sur la forme F2, chacun prouvé différent de son original ; 2 reformulations LICITES (énumération, contraste explicite) restent vertes ; les fichiers réels la tiennent"
fi

[ "$t24_ok" -eq 1 ] && ok "T24 : le mapping D-01 (deux motifs ⇒ human_needed) est mesuré par sonde STRICTE sur les 3 cibles —$t24_formes (F1 = segment d'énumération, F2 = conséquent d'implication), aucune ne retombe sur la co-présence"

# ---------------------------------------------------------------------------
# T25 (D-02) — le flag d'enchaînement autonome (workflow._auto_chain_active) est désarmé au
# démarrage de mission ET fermé par gate : aucun fichier de doctrine du module ne peut le
# represcrire sur les briques de Plan ou d'Exécution. Périmètre du balayage : les .md de doctrine
# (agents de l'équipe + références résolues, cf. module_md_targets) — ce fichier de test, qui
# embarque la forme interdite dans ses fixtures, n'en fait pas partie puisqu'il n'est ni un agent
# de $TEAM_AGENTS ni une référence de $REFS_DIR.
# ---------------------------------------------------------------------------
t25_ok=1

# Forme interdite : un bloc de brique **Plan** / **Exécution** qui PRESCRIT le mode d'enchaînement
# (non-interactif / --auto / --chain). Co-occurrence exigée DANS LE BLOC et non sur la même ligne
# physique : le module wrap à 100 colonnes, donc un simple retour à la ligne suffisait à passer au
# travers — tout comme « **Plan (planification)** » (gras non fermé immédiatement après le mot),
# d'où l'ancre ouvrante seule.
#
# Deux corrections de FAUX ROUGES (le test punissait des rédactions légitimes) :
#
#  1. ANCRAGE EN DÉBUT DE BLOC + frontière de mot. L'ancre `[*][*](Plan|Exécution)` était matchée
#     n'importe où dans le bloc et sans fermeture : un bloc « **Planification amont** … `--auto` »
#     — prose parfaitement licite — était compté comme une brique Plan. On exige désormais que le
#     bloc DÉBUTE par l'intitulé (marqueur de liste optionnel) et que le mot soit suivi d'un
#     non-caractère de mot (`**`, espace, `(` ou `:`) : « **Plan** », « **Plan (planification)** »
#     et « **Exécution** » matchent, « **Planification** » non.
T25_BRICK_RE='^[[:space:]]*([0-9]+[.)][[:space:]]+|[-*+][[:space:]]+)?[*][*](Plan|Exécution)([*]|[ ]|[(]|:)'
T25_MODE_RE='(non-interactif|--auto([^a-z-]|$)|--chain([^a-z-]|$))'
# Blancs ÉLASTIQUES (B6) : cette liste est confrontée à des clauses RECOLLÉES depuis un bloc
# wrappé à 100 colonnes. Un « ne / pas » coupé au pli échappait à un motif à espace littéral —
# la négation devenait invisible, la clause repassait pour une prescription, et le gate rougissait
# sur un durcissement du texte. Les espaces FINAUX (« ni », « sans », « pas de ») sont des
# frontières de mot : élastiques aussi, mais toujours exigés — sans quoi « Sansonnet » désarmerait.
T25_NEG_RE='(JAMAIS|[Jj]amais|[Nn]e[[:space:]]+pas|[Nn]i[[:space:]]+|[Ss]ans[[:space:]]+|[Aa]ucun|[Ii]nterdit|[Pp]as[[:space:]]+de[[:space:]]+|opt-in)'

# PÉRIMÈTRE DE T25, ET POURQUOI LA BRIQUE **Cadrage** N'Y EST PAS (A-1bis, arbitrage humain du
# 2026-08-02, qui RETRANCHE A-1). Le commit e2b1bfe avait ajouté ici une seconde branche faisant de
# `--auto`/`--chain` sur une brique Cadrage une forme INTERDITE. Sa prémisse était fausse, vérifié
# contre `gsd-core@1.9.0` : `--assumptions` route vers `workflows/list-phase-assumptions.md`, qui
# n'écrit AUCUN `CONTEXT.md` (« No file output — purely conversational ») et porte une attente
# bloquante ; `vf-coder` n'ayant pas `AskUserQuestion`, la forme prétendue licite le faisait
# retomber dans le mode d'échec exact que `--auto` évitait, et `gsd-planner` planifiait à vide. Sur
# 1.9.0 il n'existe AUCUN drapeau à la fois non interactif, producteur de `CONTEXT.md`, et sans
# chain flag : le gate était donc anti-corrélé au risque, étiquette simplement retournée.
#
# La branche est RETIRÉE d'ici. Ce qui la remplace n'est pas une interdiction mais une exigence de
# RELATION, portée par T25b : `--auto` sur le Cadrage est licite, et c'est l'ABSENCE d'un
# désarmement ADJACENT de `workflow._auto_chain_active` juste après lui qui doit rougir. T25 garde
# donc son périmètre d'origine — les briques Plan/Exécution — et la fixture d (brique Cadrage,
# patron de la ligne réelle de vf-coder.md, `--auto` inclus) redevient ce qu'elle était : la preuve
# que ce balayage-ci laisse le Cadrage à T25b au lieu de le punir.
T25_CADRAGE_RE='^[[:space:]]*([0-9]+[.)][[:space:]]+|[-*+][[:space:]]+)?[*][*]Cadrage([*]|[ ]|[(]|:)'
T25_CHAINFLAG_RE='(--auto([^a-z-]|$)|--chain([^a-z-]|$))'

#  2. EXCLUSION DES NÉGATIONS. « JAMAIS en mode **non-interactif** » est un DURCISSEMENT du texte,
#     pas la forme fautive : le test rougissait sur l'interdiction qu'il est censé faire respecter.
#     La négation est bornée à la CLAUSE qui porte le motif (depuis le dernier séparateur ASCII
#     . ; : ! ?), JAMAIS au bloc entier — sinon un « jamais » n'importe où désarmerait la sonde
#     (fixture T25 c ci-dessous). Limite assumée et documentée : une prescription réelle rédigée
#     avec une négation dans la MÊME clause échappe à la sonde. L'écart est volontairement orienté
#     vers le faux vert : un gate qui punit une rédaction correcte coûte plus qu'un gate poreux.
t25_prescriptive_clauses() { # <motif ERE de la forme interdite> ; bloc(s) sur stdin
  awk -v mode="$1" -v neg="$T25_NEG_RE" '
    {
      line = $0
      while (match(line, mode)) {
        head = substr(line, 1, RSTART + RLENGTH - 1)
        n = 0
        for (i = length(head); i > 0; i--) {
          c = substr(head, i, 1)
          if (c == "." || c == ";" || c == ":" || c == "!" || c == "?") { n = i; break }
        }
        clause = substr(head, n + 1)
        if (clause !~ neg) print clause
        line = substr(line, RSTART + RLENGTH)
      }
    }
  '
}

t25_forbidden_chain_hits() { # <file>
  md_blocks_matching "$1" "$T25_BRICK_RE" | t25_prescriptive_clauses "$T25_MODE_RE"
}

# volet présence : les DEUX agents qui prescrivent `gsd_run` nomment la clé, l'appel qui la remet
# à faux, ET la conduite si l'outil ne se résout pas.
#
# POURQUOI LES DEUX (F3). Cette sonde ne gatait que $DEVMGR. A-1bis a depuis fait reposer la
# fermeture de la fenêtre armée sur un `gsd_run config-set` porté par vf-coder.md — introduit sans
# renvoi de résolution ni conduite d'indisponibilité, là où le manager portait les deux. Un
# désarmement qui échoue parce que l'outil n'est pas résoluble depuis le worker échoue EN SILENCE,
# et c'est exactement la garantie qu'A-1bis fait reposer sur lui. Gater un seul des deux agents
# laissait la moitié de la chaîne hors mesure.
#
# CE QUI EST MESURÉ : une RELATION, pas la présence de trois tokens dans un fichier. Le renvoi et
# la conduite doivent vivre DANS le bloc qui prescrit `gsd_run` — un « §Seuil de bascule » cité
# trois sections plus loin ne se suit pas depuis l'appel. Et la conduite doit vivre dans le bloc
# QUI PORTE LE RENVOI : les deux moitiés séparées ne composent aucune conduite.
#
# COMPTEUR D'ATTEINTE : le nombre d'agents où un bloc `gsd_run` a réellement été VU. Sans lui, un
# agent qui cesserait de prescrire `gsd_run` sortirait de la mesure sans qu'un seul KO ne le dise.
T25_RESOLUTION_RE='Seuil[[:space:]]+de[[:space:]]+bascule'
T25_UNAVAIL_RE='introuvable'
# L'ANCRE EST LE GESTE, PAS LE TOKEN (N2). La sélection portait sur `gsd_run` : md_blocks_matching
# rend alors la RÉUNION des blocs qui contiennent le token, quand le libellé d'ok promet, lui, que
# chacun porte le renvoi « DANS le bloc qui le prescrit ». Renvoi et conduite déportés dans une
# « ## Note d'outillage » arbitrairement loin du geste de cadrage restaient VERTS — le libellé
# sur-promettait une relation que la sonde ne mesurait pas. L'ancre est donc l'appel RÉEL qui
# désarme la fenêtre. Blancs ÉLASTIQUES : le wrap à 100 colonnes coupe `config-set` de sa clé dans
# les DEUX agents (md_blocks_matching recolle en gardant l'indentation du pli). Point entre
# CROCHETS et non échappé : cette ancre transite par `awk -v`, où `\.` est un échappement indéfini.
T25_GESTE_RE='config-set[[:space:]]+workflow[.]_auto_chain_active'
t25_presence_seen=0
for t25_pf in "$DEVMGR" "$CODER_FILE"; do
  t25_pn="$(basename "$t25_pf")"
  if [ ! -f "$t25_pf" ]; then
    ko "T25 présence : $t25_pn introuvable — rien n'a été mesuré sur cet agent"; t25_ok=0; continue
  fi
  "$GREP" -q '_auto_chain_active' "$t25_pf" || { ko "T25 présence : $t25_pn ne nomme pas workflow._auto_chain_active"; t25_ok=0; }
  "$GREP" -q 'config-set' "$t25_pf" || { ko "T25 présence : $t25_pn n'invoque pas config-set"; t25_ok=0; }
  if "$GREP" -q 'RUNTIME_DIR' "$t25_pf"; then
    ko "T25 présence : $t25_pn recopie la cascade de résolution (RUNTIME_DIR) au lieu d'y renvoyer — DRY rompu"; t25_ok=0
  fi
  t25_gblk="$(md_blocks_matching "$t25_pf" "$T25_GESTE_RE")"
  if [ -z "$t25_gblk" ]; then
    ko "T25 présence : $t25_pn ne porte aucun bloc où le désarmement (gsd_run config-set workflow._auto_chain_active) est réellement prescrit — le renvoi de résolution et la conduite d'indisponibilité n'ont aucun geste auquel se rattacher"; t25_ok=0; continue
  fi
  t25_presence_seen=$((t25_presence_seen + 1))
  t25_rblk="$(printf '%s\n' "$t25_gblk" | "$GREP" -E "$T25_RESOLUTION_RE")"
  if [ -z "$t25_rblk" ]; then
    ko "T25 présence : $t25_pn prescrit gsd_run sans renvoyer, DANS le bloc qui le prescrit, à son foyer de résolution (mission-contracts.md §Seuil de bascule) — l'appel peut échouer sans que rien ne dise où l'outil se résout"; t25_ok=0
  else
    printf '%s\n' "$t25_rblk" | "$GREP" -q 'mission-contracts.md' \
      || { ko "T25 présence : $t25_pn nomme la section de résolution sans nommer son fichier (mission-contracts.md) — un renvoi sans fichier ne se suit pas"; t25_ok=0; }
    printf '%s\n' "$t25_rblk" | "$GREP" -qE "$T25_UNAVAIL_RE" \
      || { ko "T25 présence : $t25_pn renvoie à la résolution de gsd_run mais ne dit pas la conduite quand l'outil est INTROUVABLE — le désarmement échouerait en silence"; t25_ok=0; }
  fi
done
if [ "$t25_presence_seen" -eq 2 ]; then
  ok "T25 présence (2 agents) : vf-dev-manager.md et vf-coder.md prescrivent tous deux gsd_run, et chacun porte DANS le bloc qui le prescrit le renvoi de résolution (mission-contracts.md §Seuil de bascule) et la conduite si l'outil est introuvable — cascade jamais recopiée (DRY)"
else
  ko "T25 présence : $t25_presence_seen agent(s) sur 2 portent réellement le geste de désarmement (gsd_run config-set workflow._auto_chain_active) — la sonde de renvoi et de conduite est verte à vide sur le ou les autres"; t25_ok=0
fi

# volet fermeture (le cœur) : balayage réel des .md de doctrine, via les cibles RÉSOLUES. Le
# compteur de fichiers vus est non négociable : sans lui, un glob qui n'expanse pas produit un
# vert qui prétend avoir balayé ce qu'il n'a jamais ouvert.
# Variables de boucle PRÉFIXÉES : les deux balayages (T25 fermeture, T26 D) sont au niveau du
# script — `local` y est illégal — et partageaient `f`/`h`, donc la valeur du premier survivait
# dans le second.
t25_real_hits=""; t25_scanned=0; t25_bricks=0
while IFS= read -r t25_f; do
  [ -n "$t25_f" ] || continue
  t25_scanned=$((t25_scanned + 1))
  # Compteur d'ATTEINTE (cf. T25 atteinte ci-dessous) : combien de briques Plan/Exécution l'ancre
  # voit-elle RÉELLEMENT ? Compter les fichiers ouverts ne dit rien de ce qui a été mesuré dedans.
  t25_bricks=$((t25_bricks + $(md_blocks_matching "$t25_f" "$T25_BRICK_RE" | "$GREP" -c .)))
  t25_h="$(t25_forbidden_chain_hits "$t25_f")"
  [ -n "$t25_h" ] && t25_real_hits="$t25_real_hits
$t25_f: $t25_h"
done < <(module_md_targets)
if [ "$t25_scanned" -eq 0 ]; then
  ko "T25 fermeture : ZÉRO fichier balayé (agents d'équipe + $REFS_DIR introuvables) — un vert à vide n'est pas une garantie"
  t25_ok=0
elif [ -n "$t25_real_hits" ]; then
  ko "T25 fermeture : forme interdite trouvée (mode d'enchaînement prescrit sur une brique Plan/Exécution) —$t25_real_hits"
  t25_ok=0
else
  # Le libellé ci-dessous décrit EXACTEMENT ce qui est balayé depuis A-1bis (les briques
  # Plan/Exécution, et elles seules — le Cadrage relève de T25b, qui y mesure une relation et non
  # une interdiction). Il n'est pas réécrit : mot pour mot, il est l'un des acquis dont la
  # stabilité sert de base de comparaison d'une exécution à l'autre.
  ok "T25 fermeture : $t25_scanned fichier(s) de doctrine balayé(s), aucun ne prescrit le mode d'enchaînement sur une brique Plan/Exécution"
fi

# T25 ATTEINTE — le volet fermeture est une garde NÉGATIVE : elle est verte quand aucun fichier ne
# prescrit le mode, ET quand l'ancre de brique ne voit RIEN. Le compteur de FICHIERS ne distingue
# pas les deux — il dit ce qui a été ouvert, jamais ce qui a été mesuré dedans. Une refonte future
# des intitulés de briques (« **Étape 2 — planification** » au lieu de « **Plan** ») rendrait la
# garde muette en silence, sur exactement le risque qu'elle prétend fermer. Même garde que celle
# posée pour les motifs d'A-4 en T27c, ici sur l'ancre de brique.
#
# Assertion SÉPARÉE, jamais fondue dans le libellé de fermeture : celui-ci est un acquis gelé, dont
# la stabilité mot pour mot sert de base de comparaison d'une exécution à l'autre.
if [ "$t25_bricks" -gt 0 ]; then
  ok "T25 atteinte : $t25_bricks brique(s) Plan/Exécution effectivement VUE(S) par l'ancre dans les $t25_scanned fichier(s) balayés — la garde de fermeture porte sur des cibles réelles, elle n'est pas verte à vide"
else
  ko "T25 atteinte : l'ancre de brique Plan/Exécution ne voit AUCUN bloc dans toute la doctrine du module ($t25_scanned fichier(s) ouverts) — la garde de fermeture est verte à vide, elle ne garantit rien"
  t25_ok=0
fi

# volet discriminance (DISCRIMINANT, par mutation) — six fixtures dans un mktemp -d, trois qui
# DOIVENT être détectées et trois qui DOIVENT rester vertes. Les secondes ne sont pas décoratives :
# chacune correspond à une rédaction légitime sur laquelle le test rougissait.
#   a  interdite  — brique Plan qui prescrit le mode.
#   b  interdite  — la même wrappée + gras non fermé (« **Plan (planification)** »), la faille que
#                   la co-occurrence sur ligne physique laissait passer.
#   c  interdite  — prescription SUIVIE d'une négation dans une AUTRE clause : prouve que
#                   l'exclusion des négations est bornée à la clause et non au bloc (sinon un seul
#                   « jamais » n'importe où suffirait à désarmer le gate).
#   d  LICITE     — brique Cadrage portant la forme RÉELLE retenue par A-1bis (`--auto` + son
#                   désarmement adjacent) : ce balayage-ci ne la voit pas, et c'est voulu — le
#                   Cadrage est mesuré par T25b, en RELATION. La fixture réimmortalise ainsi
#                   comme licite la rédaction que le gate d'A-1 faisait rougir.
#   e  LICITE     — INTERDICTION rédigée sur une brique Plan (« JAMAIS en mode non-interactif ») :
#                   un durcissement du texte, que le test punissait.
#   f  LICITE     — bloc « **Planification amont** » citant `--auto`/`--chain` : ce n'est pas une
#                   brique Plan, seulement un mot qui commence pareil.
T25_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T25_TMPDIR"
T25_FORBIDDEN="$T25_TMPDIR/a-forbidden-plan.md"
T25_WRAPPED="$T25_TMPDIR/b-forbidden-plan-wrappe.md"
T25_NEGOTHER="$T25_TMPDIR/c-forbidden-plan-negation-autre-clause.md"
T25_LICIT="$T25_TMPDIR/d-licit-cadrage.md"
T25_LICIT_NEG="$T25_TMPDIR/e-licit-interdiction.md"
T25_LICIT_PLANIF="$T25_TMPDIR/f-licit-planification-amont.md"
printf '2. **Plan** : invoque `gsd-plan-phase` en mode **non-interactif**.\n' > "$T25_FORBIDDEN"
printf '2. **Plan (planification)** : invoque `gsd-plan-phase`\n   en mode **non-interactif**.\n' > "$T25_WRAPPED"
printf '2. **Plan** : invoque `gsd-plan-phase` en mode **non-interactif**. JAMAIS de rendu au manager.\n' > "$T25_NEGOTHER"
printf '1. **Cadrage** : invoque le skill `gsd-discuss-phase` en mode **non-interactif** (`--auto`), puis\n   **immédiatement, dans le même geste**, `gsd_run config-set workflow._auto_chain_active false`.\n' > "$T25_LICIT"
printf '2. **Plan** : invoque `gsd-plan-phase` (ou dispatche `gsd-planner`).\n   JAMAIS en mode **non-interactif** : le plan se rend au manager.\n' > "$T25_LICIT_NEG"
printf '**Planification amont** — la revue cross-AI de plans reste opt-in : jamais de `--auto`\nimplicite, jamais de `--chain` posé par le DAG.\n' > "$T25_LICIT_PLANIF"

t25_disc_ko=""
for t25_fx in FORBIDDEN:1 WRAPPED:1 NEGOTHER:1 LICIT:0 LICIT_NEG:0 LICIT_PLANIF:0; do
  eval "t25_fxfile=\$T25_${t25_fx%%:*}"
  t25_fxhit="$(t25_forbidden_chain_hits "$t25_fxfile")"
  if [ "${t25_fx##*:}" = 1 ] && [ -z "$t25_fxhit" ]; then
    t25_disc_ko="$t25_disc_ko [$(basename "$t25_fxfile") : forme interdite NON détectée]"
  elif [ "${t25_fx##*:}" = 0 ] && [ -n "$t25_fxhit" ]; then
    t25_disc_ko="$t25_disc_ko [$(basename "$t25_fxfile") : FAUX ROUGE sur une rédaction licite — hit=[$t25_fxhit]]"
  fi
done
if [ -z "$t25_disc_ko" ]; then
  ok "T25 (DISCRIMINANT) : 3 formes interdites détectées (Plan, Plan wrappé, prescription + négation en autre clause), 3 rédactions LICITES épargnées (Cadrage, interdiction rédigée, « Planification amont »)"
else
  ko "T25 (DISCRIMINANT) : la sonde ne sépare pas prescription et rédaction licite —$t25_disc_ko"
  t25_ok=0
fi

[ "$t25_ok" -eq 1 ] && ok "T25 : flag d'enchaînement désarmé au démarrage + fermé par gate (Plan/Exécution interdits, Cadrage licite), discriminance prouvée par mutation"

# ---------------------------------------------------------------------------
# T25b (A-1bis, DISCRIMINANT) — sur la brique **Cadrage**, `--auto` est LICITE et c'est l'ABSENCE
# d'un désarmement ADJACENT qui doit rougir. Assertion CUMULATIVE : elle s'ajoute à T25, dont les
# six fixtures gardent leur verdict.
#
# CE QUI EST MESURÉ : une RELATION, jamais l'existence d'un token. C'est le défaut qui s'est
# reproduit quatre fois sur cette phase — et dans sa forme la plus coûteuse au commit e2b1bfe, où
# la sonde cherchait `--auto` et le déclarait fautif par sa seule présence. Chercher le mot
# « désarme » quelque part dans le fichier serait la même faute, symétrique : la garantie n'est pas
# que le désarmement EXISTE, c'est qu'il SUIVE IMMÉDIATEMENT l'appel qui arme. Un désarmement
# renvoyé à l'autre bout du fichier — ou à l'autre bout du même bloc — laisse exactement la fenêtre
# armée que A-1bis prétend fermer, sans qu'un seul token manque.
#
# La sonde apparie donc, DANS le bloc Cadrage aplati : chaque occurrence PRESCRIPTIVE d'un flag
# d'armement (`--auto`/`--chain`, hors clause négative — cf. $T25_NEG_RE, acquis anti-faux-rouge de
# T25) doit être suivie, dans une fenêtre bornée, du désarmement NOMMÉ. « Suivie » est
# load-bearing : un désarmement placé AVANT l'armement est précisément le geste 5 du manager, dont
# A-1bis établit qu'il ne suffit pas. Écart assumé et symétrique du choix de T25 : une rédaction
# qui poserait le désarmement avant l'armement rougit — sur cette relation-là, l'ordre EST la
# garantie.
#
# ≥1 appariement suffit (jamais « toutes les occurrences ») : une prose qui recite `--auto` plus
# loin pour l'expliquer serait sinon un faux rouge — la famille de faux rouges que cette phase a
# déjà payée trois fois.
#
# Fixtures et mutants — les quatre contrôles exigés par le mandat, plus deux :
#   g  ROUGE      — la forme d'AVANT A-1bis (`--auto` seul, aucun désarmement) : le cas nominal.
#   h  SANS OBJET — `--assumptions` seul. La fixture est CONSERVÉE mais sa portée a changé, et on
#                   le DIT plutôt que de la retirer en silence : A-1bis établit que cette forme
#                   n'écrit aucun `CONTEXT.md` et bloque sur une attente — elle n'est plus la
#                   rédaction retenue. Elle n'arme rien pour autant : la sonde n'a rien à apparier
#                   (rc=3), ce qui n'est ni un vert ni un rouge, et la fixture le fige.
#   i  SANS OBJET — l'INTERDICTION rédigée (« JAMAIS `--auto` »). Sa doctrine est périmée depuis
#                   A-1bis ; la PROPRIÉTÉ qu'elle garde ne l'est pas : une négation n'est pas une
#                   prescription, donc elle n'arme rien. Acquis anti-faux-rouge à ne pas reperdre.
#   j  ROUGE      — `--chain` sur une SOUS-PUCE imbriquée du Cadrage, sans désarmement : la faille
#                   de bloc que le splitter sensible à l'indentation ferme (acquis à ne pas
#                   reperdre — la sonde doit voir la sous-puce comme partie du bloc parent).
#   k  VERT       — reformulation LÉGITIME du couple (autres mots, même adjacence) : une sonde qui
#                   punit une réécriture licite nuit autant qu'une sonde aveugle.
#   M1 ROUGE      — vf-coder.md RÉEL, ligne de désarmement RETIRÉE.
#   M2 ROUGE      — le désarmement DÉPLACÉ hors du bloc, ailleurs dans le fichier : tous les tokens
#                   conservés, seule la relation rompue.
#   M3 ROUGE      — le désarmement DÉPLACÉ à la fin du même bloc Cadrage : c'est LUI qui sépare
#                   « adjacence » de « co-présence dans le bloc », et il est gardé contre le
#                   no-op (un M3 identique à M1 ne prouverait que le retrait).
#   M4 ROUGE      — armement et désarmement PERMUTÉS (désarmement AVANT) : permutation pure, le
#                   multiset canonique de tokens du fichier est vérifié identique, seul l'ordre
#                   change.
#   + le fichier RÉEL doit tenir l'assertion (rc=0), et AUCUN .md de doctrine du module ne doit
#     porter un Cadrage armé sans désarmement adjacent (balayage, mêmes cibles résolues que T25).
# ---------------------------------------------------------------------------
t25b_ok=1

# Désarmement NOMMÉ : la clé ET sa remise à faux, même graphie qu'au geste 5 du manager (T25c). Un
# « désarme le flag » sans la clé ne désarme rien de vérifiable — un flag qu'on ne nomme pas est un
# flag qu'on ne désarme pas.
T25B_DISARM_RE='workflow[.]_auto_chain_active[`]?[[:space:]]+false'

# Fenêtre d'ADJACENCE, en caractères du bloc APLATI, comptés depuis la fin du flag d'armement. 150
# ≈ une ligne et demie du repli à 100 colonnes du module : de quoi écrire « puis, dans le même
# geste, <appel> » dans plusieurs tournures, pas de quoi renvoyer le désarmement à l'autre bout du
# bloc (celui de vf-coder.md fait ~800 caractères, son appariement réel en fait ~75).
T25B_WINDOW=150

# rc=0 appariement armement→désarmement ADJACENT trouvé ($T25B_WHY porte la distance mesurée) ·
# rc=1 armement prescriptif SANS désarmement adjacent · rc=2 aucune brique Cadrage · rc=3 aucun
# armement prescriptif : la sonde est SANS OBJET sur ce fichier — ni un vert ni un rouge, et
# jamais un repli silencieux sur « le mot désarmement apparaît quelque part ».
T25B_WHY=""
t25b_cadrage_adjacent_disarm() { # <file>
  local blk res armed paired mind
  T25B_WHY=""
  blk="$(md_blocks_matching "$1" "$T25_CADRAGE_RE")"
  [ -n "$blk" ] || { T25B_WHY="aucune brique **Cadrage** dans ce fichier"; return 2; }
  # Sortie : "<armements prescriptifs> <appariements adjacents> <distance minimale, -1 si aucun
  # désarmement ne SUIT un armement>".
  res="$(printf '%s\n' "$blk" | awk -v arm="$T25_CHAINFLAG_RE" -v dis="$T25B_DISARM_RE" \
                                    -v neg="$T25_NEG_RE" -v win="$T25B_WINDOW" '
    BEGIN { armed = 0; paired = 0; mind = -1 }
    {
      block = $0; base = 0; line = block
      while (match(line, arm)) {
        rs = RSTART; rl = RLENGTH
        e = base + rs + rl - 1                  # index absolu de fin du flag dans le bloc
        head = substr(block, 1, e)
        # Negation bornee a la CLAUSE (depuis le dernier separateur ASCII), jamais au bloc : acquis
        # de T25 — un « jamais » place ailleurs ne doit pas desarmer la sonde.
        n = 0
        for (i = length(head); i > 0; i--) {
          c = substr(head, i, 1)
          if (c == "." || c == ";" || c == ":" || c == "!" || c == "?") { n = i; break }
        }
        if (substr(head, n + 1) !~ neg) {
          armed++
          tail = substr(block, e + 1)           # ce qui SUIT l armement, et lui seul
          if (match(tail, dis)) {
            d = RSTART - 1
            if (mind < 0 || d < mind) mind = d
            if (d <= win) paired++
          }
        }
        base = e
        line = substr(line, rs + rl)
      }
    }
    END { print armed, paired, mind }
  ')"
  armed="${res%% *}"; mind="${res##* }"; paired="$(printf '%s' "$res" | cut -d' ' -f2)"
  [ "${armed:-0}" -gt 0 ] || { T25B_WHY="aucun armement prescriptif (\`--auto\`/\`--chain\`) dans la brique Cadrage — rien à apparier"; return 3; }
  if [ "${paired:-0}" -gt 0 ]; then
    T25B_WHY="$armed armement(s) prescriptif(s), $paired apparié(s) à ≤ $T25B_WINDOW caractères (distance minimale mesurée : $mind)"
    return 0
  fi
  if [ "${mind:--1}" -lt 0 ]; then
    T25B_WHY="la brique Cadrage arme le chain flag ($armed occurrence(s) prescriptive(s)) et AUCUN désarmement nommé (\`workflow._auto_chain_active … false\`) ne le SUIT dans le bloc — la fenêtre reste ouverte pour toute la mission"
  else
    T25B_WHY="le désarmement suit bien l'armement, mais à $mind caractères (> $T25B_WINDOW) : il n'est PAS adjacent — la fenêtre armée court jusque-là, et une co-présence dans le bloc ne la referme pas"
  fi
  return 1
}

T25B_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T25B_TMPDIR"
T25B_ARMED="$T25B_TMPDIR/g-cadrage-arme-sans-desarmement.md"
T25B_ASSUMPTIONS="$T25B_TMPDIR/h-cadrage-assumptions-sans-objet.md"
T25B_NEG="$T25B_TMPDIR/i-cadrage-interdiction-sans-objet.md"
T25B_SUBBULLET="$T25B_TMPDIR/j-cadrage-souspuce-armee.md"
T25B_REFORM="$T25B_TMPDIR/k-cadrage-reformulation-legitime.md"
printf '1. **Cadrage** : invoque le skill `gsd-discuss-phase` en mode **non-interactif** (`--auto` /\n   mode assumptions).\n' > "$T25B_ARMED"
printf '1. **Cadrage** : invoque le skill `gsd-discuss-phase` en mode **non-interactif**, avec\n   `--assumptions`.\n' > "$T25B_ASSUMPTIONS"
printf '1. **Cadrage** : `gsd-discuss-phase` avec `--assumptions`, JAMAIS `--auto` — il poserait le\n   chain flag amont.\n' > "$T25B_NEG"
printf '1. **Cadrage** : invoque le skill `gsd-discuss-phase`\n   - en enchaînement automatique (`--chain`).\n' > "$T25B_SUBBULLET"
printf '1. **Cadrage** : lance `gsd-discuss-phase --auto`, et enchaîne aussitôt, dans le même geste,\n   sur `gsd_run config-set workflow._auto_chain_active false` — la fenêtre reste bornée là.\n' > "$T25B_REFORM"

t25b_ko=""
t25b_rc=0
t25b_assert_rc() { # <libellé> <fichier> <rc attendu>
  t25b_cadrage_adjacent_disarm "$2"
  t25b_rc=$?
  [ "$t25b_rc" = "$3" ] \
    || t25b_ko="$t25b_ko [$1 : rc=$t25b_rc, attendu $3 — $T25B_WHY]"
}
t25b_assert_rc "g Cadrage armé sans désarmement"                  "$T25B_ARMED"       1
t25b_assert_rc "h --assumptions seul (SANS OBJET depuis A-1bis)"  "$T25B_ASSUMPTIONS" 3
t25b_assert_rc "i interdiction rédigée (négation ≠ prescription)" "$T25B_NEG"         3
t25b_assert_rc "j --chain sur sous-puce imbriquée du Cadrage"     "$T25B_SUBBULLET"   1
t25b_assert_rc "k reformulation LÉGITIME du couple adjacent"      "$T25B_REFORM"      0

# --- Mutants tirés du fichier RÉEL : une fixture synthétique prouve la sonde, jamais la doctrine.
T25B_M1="$T25B_TMPDIR/M1-desarmement-retire.md"
T25B_M2="$T25B_TMPDIR/M2-desarmement-hors-bloc.md"
T25B_M3="$T25B_TMPDIR/M3-desarmement-fin-de-bloc.md"
T25B_M4="$T25B_TMPDIR/M4-armement-desarmement-permutes.md"
T25B_CALL='gsd_run config-set workflow._auto_chain_active false'
# Les quatre mutants s ancrent sur les TOKENS du couple (l appel de désarmement, le flag), jamais
# sur la prose qui les entoure ni sur leurs backticks : une reformulation légitime de la brique —
# le contrôle « k » du mandat, rejoué ci-dessous sur le fichier réel — ne doit pas transformer un
# mutant en no-op, ce qui ferait rougir la suite sur une réécriture correcte. M3 en particulier
# repère la fin du bloc STRUCTURELLEMENT (même règle de coupe que md_blocks_matching), pas par une
# phrase.
# M1 — l appel de désarmement retiré, purement et simplement.
md_sed_folded "s/gsd_run${MDSP}config-set${MDSP}workflow[.]_auto_chain_active${MDSP}false//g" "$CODER_FILE" > "$T25B_M1"
# M2 — le MÊME appel, replacé ailleurs dans le fichier : aucun token perdu, seule la relation.
{ cat "$T25B_M1"; printf '\nAprès le cadrage, `%s` reste requis.\n' "$T25B_CALL"; } > "$T25B_M2"
# M3 — replacé à la FIN du même bloc Cadrage : toujours dans le bloc, mais loin de l armement.
awk -v anchor="$T25_CADRAGE_RE" -v call="$T25B_CALL" '
  function indent(s,   t) { t = s; sub(/[^ \t].*$/, "", t); gsub(/\t/, "    ", t); return length(t) }
  function flush(  i) { buf[n] = buf[n] " — puis `" call "` —"; for (i = 1; i <= n; i++) print buf[i]; n = 0; ina = 0 }
  {
    if (!ina && $0 ~ anchor) { ina = 1; openind = indent($0); buf[++n] = $0; next }
    if (ina) {
      if (/^[[:space:]]*$/ || /^#/ || (/^[[:space:]]*([-*+][[:space:]]|[0-9]+\.[[:space:]])/ && indent($0) <= openind)) {
        flush(); print; next
      }
      buf[++n] = $0; next
    }
    print
  }
  END { if (ina) flush() }
' "$T25B_M1" > "$T25B_M3"
# M4 — permutation PURE des deux membres du couple : le désarmement passe AVANT l armement.
md_sed_folded "s/--auto/@@VFARM@@/;s/gsd_run${MDSP}config-set${MDSP}workflow[.]_auto_chain_active${MDSP}false/--auto/;s/@@VFARM@@/$T25B_CALL/" "$CODER_FILE" > "$T25B_M4"

# Gardes de MORSURE, avant toute mesure : un mutant qui n a rien changé (ou qui a changé autre
# chose que ce qu il prétend) ne prouve rien. M3 en particulier serait, s il n avait pas mordu, un
# simple doublon de M1 — il ne dirait plus rien de l adjacence, qui est tout son objet.
cmp -s "$T25B_M1" "$T25B_M3" \
  && t25b_ko="$t25b_ko [M3 : la réinsertion en fin de bloc n'a pas mordu (M3 identique à M1) — il ne prouverait que le retrait, pas la non-adjacence]"
cmp -s "$T25B_M1" "$T25B_M2" \
  && t25b_ko="$t25b_ko [M2 : le report hors bloc n'a pas mordu (M2 identique à M1) — il ne prouverait que le retrait]"
t25b_canon() { LC_ALL=C tr -cs '[:alnum:]_' '\n' < "$1" | LC_ALL=C sort; }
[ "$(t25b_canon "$CODER_FILE")" = "$(t25b_canon "$T25B_M4")" ] \
  || t25b_ko="$t25b_ko [M4 : le multiset canonique de tokens a changé — ce n'est plus une permutation pure, donc plus une mutation de RELATION]"

t25b_assert_mutant_red() { # <libellé> <mutant>
  if cmp -s "$CODER_FILE" "$2"; then
    t25b_ko="$t25b_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus dans vf-coder.md, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de l'assertion)]"
    return
  fi
  t25b_cadrage_adjacent_disarm "$2"
  case $? in
    1) : ;;
    0) t25b_ko="$t25b_ko [$1 : NON détecté — $T25B_WHY]" ;;
    2) t25b_ko="$t25b_ko [$1 : rc=2, brique Cadrage détruite — rien n'a été mesuré, ce n'est pas une détection]" ;;
    *) t25b_ko="$t25b_ko [$1 : rc=3, plus aucun armement prescriptif — rien n'a été mesuré là où on prétend mesurer]" ;;
  esac
}
t25b_assert_mutant_red "M1 désarmement RETIRÉ"                                "$T25B_M1"
t25b_assert_mutant_red "M2 désarmement déplacé HORS du bloc (tokens gardés)"  "$T25B_M2"
t25b_assert_mutant_red "M3 désarmement déplacé en FIN de bloc (non adjacent)" "$T25B_M3"
t25b_assert_mutant_red "M4 armement/désarmement PERMUTÉS (multiset inchangé)" "$T25B_M4"

# Le fichier RÉEL doit tenir l'assertion : `--auto` armé ET refermé dans le geste même.
t25b_cadrage_adjacent_disarm "$CODER_FILE" \
  || t25b_ko="$t25b_ko [vf-coder.md RÉEL ne tient pas l'assertion (rc=$?) — $T25B_WHY]"

# Balayage : AUCUN .md de doctrine du module ne peut porter un Cadrage armé sans désarmement
# adjacent. Mêmes cibles RÉSOLUES que T25 — jamais un glob en dur (en lab installé agents/ est plat
# et partagé, et references/ n'existe pas sous ce nom : un glob non expansé = vert à vide).
t25b_scanned=0
while IFS= read -r t25b_f; do
  [ -n "$t25b_f" ] || continue
  t25b_scanned=$((t25b_scanned + 1))
  t25b_cadrage_adjacent_disarm "$t25b_f"
  [ $? -eq 1 ] && t25b_ko="$t25b_ko [$t25b_f : $T25B_WHY]"
done < <(module_md_targets)
[ "$t25b_scanned" -gt 0 ] \
  || t25b_ko="$t25b_ko [balayage : ZÉRO fichier de doctrine ouvert — un vert à vide n'est pas une garantie]"

if [ -z "$t25b_ko" ]; then
  ok "T25b (A-1bis, DISCRIMINANT) : sur la brique Cadrage, \`--auto\` est LICITE et c'est l'ABSENCE de désarmement ADJACENT qui rougit — relation mesurée (armement → désarmement nommé, à ≤ $T25B_WINDOW caractères et APRÈS lui), 4 mutants du fichier RÉEL détectés (retrait, report hors bloc, report en fin de bloc, permutation à multiset inchangé), 2 fixtures SANS OBJET assumées (\`--assumptions\`, interdiction rédigée), 1 reformulation légitime verte, $t25b_scanned fichier(s) de doctrine balayé(s), et vf-coder.md tient l'appariement"
else
  ko "T25b (A-1bis, DISCRIMINANT) : l'adjacence armement↔désarmement n'est pas mesurée —$t25b_ko"; t25b_ok=0
fi

# ---------------------------------------------------------------------------
# T25c (A-2) — les DEUX déclencheurs amont d'auto-approbation sont désarmés dans le MÊME geste.
# `workflow._auto_chain_active` seul ne suffit pas : `workflow.auto_advance` est le second
# déclencheur de la règle 5 amont (gsd-core/references/checkpoints.md) et n'apparaissait nulle part
# dans plugin/ — un flag qu'on ne nomme pas est un flag qu'on ne désarme pas. Assertion BORNÉE AU
# BLOC : deux désarmements dans deux sections sans rapport ne sont pas « le même geste ».
# ---------------------------------------------------------------------------
t25c_ok=1
T25C_WHY=""
t25c_both_disarmed() { # <file>
  local blk
  T25C_WHY=""
  blk="$(md_blocks_matching "$1" 'workflow[.]_auto_chain_active')"
  [ -n "$blk" ] || { T25C_WHY="aucun bloc ne nomme workflow._auto_chain_active"; return 2; }
  printf '%s\n' "$blk" | "$GREP" -qE 'workflow[.]_auto_chain_active[`]?[[:space:]]+false' \
    || { T25C_WHY="workflow._auto_chain_active n'est pas mis à false dans ce bloc"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -qE 'workflow[.]auto_advance[`]?[[:space:]]+false' \
    || { T25C_WHY="workflow.auto_advance — second déclencheur de la règle 5 amont — n'est pas désarmé dans le même geste"; return 1; }
  return 0
}

t25c_both_disarmed "$DEVMGR"
case $? in
  0) : ;;
  2) ko "T25c (A-2) : vf-dev-manager.md — $T25C_WHY"; t25c_ok=0 ;;
  *) ko "T25c (A-2) : vf-dev-manager.md — $T25C_WHY"; t25c_ok=0 ;;
esac

# Discriminance par mutation : (1) le second flag remplacé par le premier — le geste désarme deux
# fois la même chose, exactement la régression que A-2 corrige, et AUCUN token de forme n'est
# retiré ; (2) le second flag armé à `true`.
T25C_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T25C_TMPDIR"
T25C_MUT_MEME="$T25C_TMPDIR/mutant-deux-fois-le-meme-flag.md"
T25C_MUT_TRUE="$T25C_TMPDIR/mutant-auto-advance-arme.md"
sed 's/workflow[.]auto_advance/workflow._auto_chain_active/g' "$DEVMGR" > "$T25C_MUT_MEME"
md_sed_folded "s/workflow[.]auto_advance${MDSP}false/workflow.auto_advance true/g" "$DEVMGR" > "$T25C_MUT_TRUE"
t25c_mut_ko=""
t25c_assert_mutant_red() { # <libellé> <mutant>
  if cmp -s "$DEVMGR" "$2"; then
    t25c_mut_ko="$t25c_mut_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de l'assertion)]"
    return
  fi
  t25c_both_disarmed "$2"
  case $? in
    1) : ;;
    0) t25c_mut_ko="$t25c_mut_ko [$1 : NON détecté]" ;;
    *) t25c_mut_ko="$t25c_mut_ko [$1 : rc=2, bloc introuvable — rien n'a été mesuré, ce n'est pas une détection]" ;;
  esac
}
t25c_assert_mutant_red "second flag remplacé par le premier (désarmement en double)" "$T25C_MUT_MEME"
t25c_assert_mutant_red "workflow.auto_advance armé à true"                           "$T25C_MUT_TRUE"
t25c_both_disarmed "$DEVMGR" || t25c_mut_ko="$t25c_mut_ko [le fichier réel ne tient plus l'assertion — $T25C_WHY]"
if [ -n "$t25c_mut_ko" ]; then
  ko "T25c (A-2, DISCRIMINANT) : le désarmement des deux flags n'est pas mesuré —$t25c_mut_ko"; t25c_ok=0
else
  ok "T25c (A-2, DISCRIMINANT) : le geste de démarrage désarme les DEUX déclencheurs amont (_auto_chain_active ET auto_advance) dans le même bloc — 2 mutants (désarmement en double, second flag armé) font rougir l'assertion"
fi

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

# A — Minimum de reprise (D-03). Trois propriétés CUMULÉES, pas alternatives (le faux dilemme
# « liste figée OU fermeture mesurée » a coûté une régression de couverture : l'ancrage nominal
# retiré, un renommage `plan_id`→`plan_ref` passait à 0 KO — l'ensemble reste clos, seulement il ne
# désigne plus la même chose) :
#   (a) FERMETURE MESURÉE : l'énumération est bornée des deux côtés, et la borne de fin est
#       réellement coupée — une coupe no-op est un défaut de sonde, jamais un succès ;
#   (b) ANCRAGE NOMINAL EN ÉGALITÉ D'ENSEMBLE : l'ensemble mesuré vaut EXACTEMENT celui de D-03 ;
#   (c) INTERDITS ADR-030 hors énumération : aucune graphie connue du contrat INTERNE de
#       l'exécuteur amont (la table des tâches déjà exécutées) ailleurs dans le bloc.
# Sans (c), l'assertion certifiait « énumération close » sur un contrat énumérant
# `taches_executees` et `hashes` — littéralement ce que le motif ADR-030 interdit de recopier.
# Et tant que (b) se contentait d'une présence doublée d'une liste NOIRE, l'ensemble n'était pas
# clos pour autant : ajouter `journal_des_taches_executees` — la table même que ADR-030 interdit de
# recopier, sous une graphie absente de la liste — laissait la suite à 87 OK / 0 KO. L'égalité
# d'ensemble ferme la question par la lecture littérale de D-03 (« exactement … rien d'autre »).

# Identifiants backtickés d'un texte lu sur stdin, triés et dédupliqués. Collationnement BYTE
# imposé : toute comparaison d'ensemble en aval (égalité de chaînes, comm) le suppose.
t26_ids() { "$GREP" -oE '`[a-z][a-z0-9_]*`' | tr -d '`' | LC_ALL=C sort -u; }

# Intitulés du contrat INTERNE amont, en version « texte » (sans ancre de ligne) : sert à
# interdire qu'un sous-champ du minimum de reprise en reproduise un (ADR-030).
#
# Blancs ÉLASTIQUES (B6) : ces motifs sont mesurés sur du contenu RECOLLÉ — blocs de
# md_blocks_matching, fichier replié par md_folded —, où le pli du wrap à 100 colonnes laisse
# l'indentation de la ligne suivante. Un espace littéral y rendrait la garde AVEUGLE, pas rouge.
T26_INTERNAL_MULTI_RE='Completed[[:space:]]+Tasks|Current[[:space:]]+Task|Checkpoint[[:space:]]+Details|CHECKPOINT[[:space:]]+REACHED'
T26_INTERNAL_RE="$T26_INTERNAL_MULTI_RE|Awaiting"

# CINQUIÈME intitulé, à parité avec les quatre autres. `Awaiting` est le seul du contrat interne
# amont (`execute-plan.md`: « 4) Awaiting (what's needed from user) ») qui tienne en UN mot — donc
# le seul que la garde ne pouvait pas mesurer comme les autres sans faire rougir toute prose
# anglaise. Elle se rabattait sur la ligne strictement nue `^Awaiting$` : quatre intitulés couverts
# sur cinq, pendant que le libellé d'ok en promet cinq. Recopier `**Awaiting** : …` dans une
# référence laissait la suite à 99 OK / 0 KO — la famille B6, restée ouverte sur ce motif.
#
# Ce qui est mesuré ici n'est donc PAS l'existence du token — c'est la POSITION DE RUBRIQUE : le
# mot suivi du séparateur qui introduit son contenu, ou porté par un marqueur d'intitulé markdown
# (titre `#`, gras). De la prose anglaise qui contient le mot reste verte (contrôle positif ET
# contrôle anti-faux-rouge en T26 D+). Aucun backtick dans le motif : il est déréférencé entre
# guillemets doubles au point d'appel.
#
# SÉPARATEURS (N3) : la classe ne tenait que `:` et `(` — les deux graphies de l'AMONT anglophone —
# et manquait le séparateur DOMINANT de ce dépôt, le tiret cadratin. « - Awaiting — ce que le
# moteur attend… » échappait donc à la garde, c'est-à-dire exactement la graphie sous laquelle une
# recopie s'écrirait ICI. Cadratin et demi-cadratin sont ajoutés en ALTERNATION, pas dans la classe
# entre crochets : ce sont des caractères multi-octets, et une classe de crochets les découperait en
# octets isolés. Le tiret ASCII est délibérément EXCLU : sans blanc obligatoire, il ferait rougir
# un composé anglais (« Awaiting-user »), donc un faux rouge sur le flanc que D+ protège.
T26_AWAITING_RE='Awaiting[*_]*[[:space:]]*([:(]|—|–)|#[[:space:]]*[*_]*Awaiting([^[:alnum:]]|$)|[*][*][[:space:]]*Awaiting[[:space:]]*[*][*]'

# Sous-champs FIXÉS par D-03, tenus comme un ENSEMBLE CLOS : D-03 dit « sont exactement … — rien
# d'autre », donc l'ensemble MESURÉ doit être ÉGAL à celui-ci, jamais seulement le contenir. Un
# renommage OU un ajout exige un amendement de D-03, pas un test qui suit.
#
# ÉLARGISSEMENT A-3 (arbitrage humain du 2026-08-02) : les quatre premiers décrivent tous *la
# question*. Un manager qui redispatche « avec l'attendu » redispatche la question qu'il vient de
# reposer — le worker neuf retombe sur le même checkpoint et rend `human_needed` : ping-pong sur un
# gate bloquant. Le contrat transporte donc en plus l'ÉTAT DE REPRISE (`reponse_humaine`,
# `taches_faites`). L'ensemble reste CLOS et l'assertion reste une ÉGALITÉ : seule la cible bouge,
# jamais la propriété.
T26_D03_FIELDS="plan_id checkpoint gate attendu reponse_humaine taches_faites"

# Noms de sous-champs INTERDITS (ADR-030) : la table des tâches déjà exécutées du contrat interne
# de l'exécuteur, sous ses graphies plausibles FR/EN. C'est une LISTE NOIRE, donc un filet à
# mailles finies : elle ne ferme rien à elle seule (`journal_des_taches_executees` n'y figure pas
# et passait à 0 KO). La fermeture de l'énumération est assurée par l'ÉGALITÉ D'ENSEMBLE avec
# $T26_D03_FIELDS ; cette liste ne sert plus qu'aux zones où aucun ensemble clos n'est définissable
# — le reste du bloc, hors énumération, et les blocs de vf-coder.md (T26 A').
T26_FORBIDDEN_FIELDS='^(taches_executees|taches_realisees|taches|completed_tasks|current_task|checkpoint_details|awaiting|hashes|hash|shas|commits|fichiers|files)$'

# 0 = contrat clos et sain (T26_FIELDS/T26_N renseignés) · 1 = fermeture rompue ($T26_WHY) ·
# 2 = bloc introuvable.
T26_FIELDS=""; T26_N=0; T26_WHY=""
t26_reprise_closed() { # <fichier de contrat>
  local blk head enum fields parent bad id miss extra expected
  # Réinitialisation à l'ENTRÉE : sans elle, un $T26_WHY périmé survivait à un retour 2 et
  # l'appelant affichait le motif de l'appel précédent.
  T26_FIELDS=""; T26_N=0; T26_WHY=""
  blk="$(md_blocks_matching "$1" '[*][*]Minimum[[:space:]]+de[[:space:]]+reprise')"
  [ -n "$blk" ] || return 2
  # Blancs ÉLASTIQUES partout (B6) : le bloc est RECOLLÉ, donc une formule coupée par le wrap à
  # 100 colonnes s'y retrouve avec l'indentation de la ligne suivante au pli. Garde ET coupe
  # portent le MÊME motif élastique — les désaligner rendrait la coupe no-op sous un garde vert.
  printf '%s\n' "$blk" | "$GREP" -qE 'sous-champs[[:space:]]+sont[[:space:]]+exactement' || { T26_WHY="énumération fermée (« sous-champs sont exactement ») absente"; return 1; }
  # Le garde porte le motif EXACT de la coupe. Un garde plus laxiste (« rien d'autre » sans gras)
  # restait vert quand le gras disparaissait, tandis que la coupe devenait un no-op SILENCIEUX :
  # l'énumération s'étendait jusqu'à la fin du bloc et la fermeture devenait trivialement vraie.
  printf '%s\n' "$blk" | "$GREP" -qE "[*][*]rien[[:space:]]+d'autre[*][*]" || { T26_WHY="borne fermante « **rien d'autre** » (en gras — motif EXACT de la coupe) absente"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -q 'ADR-030'                     || { T26_WHY="motif ADR-030 non cité"; return 1; }

  # (a) fermeture MESURÉE : les deux coupes doivent avoir mordu.
  head="$(printf '%s\n' "$blk" | sed -E 's/.*sous-champs[[:space:]]+sont[[:space:]]+exactement//')"
  [ "$head" != "$blk" ] || { T26_WHY="ouverture d'énumération non coupée — coupe no-op, sonde en défaut"; return 1; }
  enum="$(printf '%s\n' "$head" | sed -E "s/[*][*]rien[[:space:]]+d'autre[*][*].*//")"
  [ "$enum" != "$head" ] || { T26_WHY="borne fermante non coupée — une coupe no-op est un défaut de sonde, jamais un succès"; return 1; }

  printf '%s\n' "$enum" | "$GREP" -qE "$T26_INTERNAL_RE" && { T26_WHY="un sous-champ reproduit un intitulé du contrat interne amont (ADR-030)"; return 1; }
  fields="$(printf '%s\n' "$enum" | t26_ids)"
  [ -n "$fields" ] || { T26_WHY="aucun sous-champ backtické dans l'énumération"; return 1; }

  # (b) ancrage nominal D-03, en ÉGALITÉ D'ENSEMBLE — cumulé à (a), jamais à sa place. L'égalité
  # couvre d'un seul geste le nom MANQUANT (renommage : l'ensemble reste clos mais ne désigne plus
  # la même chose) et le nom EN TROP, y compris une graphie qu'aucune liste noire n'aurait
  # anticipée : c'est la lecture littérale de « sont exactement … — rien d'autre ».
  expected="$(printf '%s\n' $T26_D03_FIELDS | LC_ALL=C sort -u)"   # non quoté : découpage voulu
  if [ "$fields" != "$expected" ]; then
    miss="$(LC_ALL=C comm -13 <(printf '%s\n' "$fields") <(printf '%s\n' "$expected") | tr '\n' ' ')"
    extra="$(LC_ALL=C comm -23 <(printf '%s\n' "$fields") <(printf '%s\n' "$expected") | tr '\n' ' ')"
    T26_WHY="l'ensemble mesuré des sous-champs n'est pas EXACTEMENT celui de D-03 — en trop : ${extra:-(rien)} · manquant(s) : ${miss:-(rien)} (un renommage comme un ajout exige un amendement de D-03, pas un test qui suit)"
    return 1
  fi

  # (c) interdits ADR-030 hors énumération : DANS l'énumération, (b) les exclut déjà par
  # construction — tout nom absent de D-03 y est refusé, interdit connu ou non. Ailleurs dans le
  # bloc, aucun ensemble clos n'est définissable (la prose y nomme légitimement d'autres champs) :
  # on retombe sur la liste noire, en le disant. Un champ « ajouté » après la borne fermante serait
  # la même violation, contournée d'un pas.
  #
  # A-3 : un nom que l'ensemble clos SANCTIONNE ne peut pas être, dans le même souffle, une
  # violation ADR-030 — depuis A-3 le contrat transporte légitimement l'état de reprise. La liste
  # noire ne s'applique donc qu'à ce que $T26_D03_FIELDS ne couvre pas. Ce n'est PAS un repli : la
  # fermeture réelle reste (b), qui refuse tout nom absent de D-03, interdit connu ou non — élargir
  # $T26_D03_FIELDS exige d'amender D-03, un acte explicite, jamais un test qui suit.
  bad=""
  for id in $(printf '%s\n' "$blk" | t26_ids | "$GREP" -E "$T26_FORBIDDEN_FIELDS"); do
    case " $T26_D03_FIELDS " in *" $id "*) continue ;; esac
    bad="$bad $id"
  done
  [ -z "$bad" ] || { T26_WHY="le bloc déclare, hors énumération, une graphie connue de la table du contrat interne amont (ADR-030) —$bad"; return 1; }

  parent="$(printf '%s\n' "$blk" | sed -nE "s/.*champ[[:space:]]+optionnel[[:space:]]+\`([a-z][a-z0-9_]*)\`.*/\1/p")"
  [ -n "$parent" ] || { T26_WHY="champ porteur (« un champ optionnel \`…\` ») non déclaré"; return 1; }
  T26_FIELDS="$fields"; T26_N="$(printf '%s\n' "$fields" | "$GREP" -c .)"
  return 0
}

t26_reprise_closed "$CONTRACTS_FILE"
case $? in
  0) ok "T26 A : minimum de reprise — énumération bornée et coupée pour de bon, dont l'ensemble MESURÉ des $T26_N sous-champs ($(printf "%s" "$T26_FIELDS" | tr "\n" " ")) vaut EXACTEMENT celui de D-03 (égalité d'ensemble : rien de manquant, rien en trop) ; hors énumération, aucune des graphies connues de la table du contrat interne amont (ADR-030)" ;;
  2) ko "T26 A : bloc « Minimum de reprise » introuvable dans mission-contracts.md"; t26_ok=0 ;;
  *) ko "T26 A : minimum de reprise — $T26_WHY"; t26_ok=0 ;;
esac

# A' — une seule voix (ADR-030) : ce que l'AGENT écrit sur le checkpoint ne REDÉFINIT pas le
# contrat, il y RENVOIE.
#
# CE QUI A ÉTÉ DÉCLASSÉ ICI, ET POURQUOI. La forme précédente — « tout identifiant backtické des
# blocs gate/reprise de vf-coder.md appartient à l'ensemble du contrat » — n'est pas gateable :
# t26_ids capte TOUT token backtické minuscule, pas des noms de champ. Écrire `statut` dans le
# bloc `gate`, ou `human_needed` dans le bloc du contrat — deux rédactions PLUS précises que
# l'actuelle — faisaient rougir la suite avec un message accusant la doctrine. Une sonde qui punit
# une édition correcte nuit plus qu'elle ne protège, a fortiori sur des fichiers qu'on s'apprête à
# réécrire. On la remplace par deux propriétés étroites mais vraies : le RENVOI (DRY) et les noms
# INTERDITS (ADR-030) — la partie « champ inventé » reste un contrôle documenté, non gaté.
t26_ap_ko=""
for n in gate reprise; do
  t26_blk="$(md_blocks_matching "$CODER_FILE" "[*][*][\`]$n[\`][*][*]")"
  if [ -z "$t26_blk" ]; then
    t26_ap_ko="$t26_ap_ko [bloc \`$n\` introuvable dans vf-coder.md]"; continue
  fi
  printf '%s\n' "$t26_blk" | "$GREP" -q 'mission-contracts.md' \
    || t26_ap_ko="$t26_ap_ko [bloc \`$n\` : aucun renvoi à mission-contracts.md — le worker porterait une seconde définition du contrat]"
  t26_bad="$(printf '%s\n' "$t26_blk" | t26_ids | "$GREP" -E "$T26_FORBIDDEN_FIELDS" | tr '\n' ' ')"
  [ -z "$t26_bad" ] \
    && printf '%s\n' "$t26_blk" | "$GREP" -qE "$T26_INTERNAL_RE" && t26_bad="(intitulé littéral du contrat interne)"
  [ -z "$t26_bad" ] || t26_ap_ko="$t26_ap_ko [bloc \`$n\` : nomme un champ du contrat INTERNE amont (ADR-030) — $t26_bad]"
done
if [ -z "$t26_ap_ko" ]; then
  ok "T26 A' : les blocs \`gate\` et \`reprise\` de vf-coder.md renvoient tous deux à mission-contracts.md et ne nomment aucun champ du contrat interne amont (une seule voix, ADR-030)"
else
  ko "T26 A' : vf-coder.md ne tient pas la voix unique —$t26_ap_ko"; t26_ok=0
fi

# B — vf-coder.md porte la règle « attente humaine ⇒ escalade, jamais auto-répondue ».
# La formule est multi-mots et la propriété n'est bornée à aucun bloc : mesure sur le fichier
# REPLIÉ, blancs élastiques (B6) — sinon un simple re-wrap la ferait rougir à tort.
"$GREP" -q 'reprise' "$CODER_FILE" || { ko "T26 B : vf-coder.md ne nomme pas le champ reprise"; t26_ok=0; }
md_folded "$CODER_FILE" | "$GREP" -qiE 'jamais[[:space:]]+une[[:space:]]+réponse' || { ko "T26 B : vf-coder.md ne porte pas la règle « jamais une réponse de ta part »"; t26_ok=0; }

# C — la table de pilotage porte le halt DE NŒUD et la réponse par le manager. Cible SUIVIE :
# depuis le déport A-4, les deux formules vivent dans mission-flow.md §Pattern C, plus dans
# l'agent qui n'en garde qu'un renvoi — grepper encore vf-dev-manager.md serait une sonde morte.
#
# Deux durcissements par rapport à la forme précédente, aucun relâchement :
#  1. la mesure porte sur le BLOC « Verdict d'étape » (lignes rejointes par md_blocks_matching),
#     plus sur le fichier entier — les deux formules doivent être là où la doctrine les emploie.
#     Un grep ligne à ligne était de surcroît à la merci du repli à 100 colonnes : la référence
#     coupe « répond aux / attentes humaines » en deux lignes, ce qu'aucune sonde de doctrine ne
#     doit pouvoir sanctionner. Les blancs INTERNES des formules sont donc élastiques
#     ([[:space:]]+) : md_blocks_matching recolle les lignes SANS retirer leur indentation, une
#     formule à cheval sur deux lignes se retrouve avec trois espaces au pli.
#  2. la personne du verbe est tolérée (« répond » à la 3e dans la référence, « réponds » à la 2e
#     dans une rédaction adressée au manager) : c'est la FORMULE qui est gatée, pas sa voix.
#  3. le NOMBRE de l'attente est toléré, comme en T27. Ce motif n'acceptait que le pluriel alors
#     que $T27_ASK_RE, ajouté par le MÊME lot, reconnaît explicitement les deux nombres (« attente
#     au singulier introduite par « à l' » ») — un désalignement mécanique entre deux sondes de la
#     même doctrine. Coût mesuré : une réécriture licite d'A-4 au singulier produisait ici un KO
#     disant « le bloc ne nomme pas le manager comme répondant aux attentes humaines », c'est-à-dire
#     accusant une doctrine qui dit exactement cela. Le motif n'est PAS remplacé par $T27_ASK_RE :
#     celui-ci accepte en plus « pose la question », qui satisferait C sans que le bloc ne nomme
#     jamais la réponse aux attentes — ce serait un relâchement, pas un alignement.
#
# L'INFINITIF EST EXCLU, et c'est la borne de la tolérance de personne (N1). Une passe précédente
# avait écrit `répond(s|re)?` en croyant élargir la même tolérance : elle a retourné l'assertion.
# L'infinitif est la forme dans laquelle s'écrivent les INTERDICTIONS en français — « le manager
# n'a jamais à répondre aux attentes humaines » satisfaisait alors une garde qui exige que le bloc
# nomme le manager comme y RÉPONDANT. Une prohibition passait pour l'affirmation qu'elle nie, et
# c'était le dernier motif de la suite qui refusait encore cette silhouette. Les personnes
# conjuguées (« répond », « réponds ») portent l'affirmation ; l'infinitif nu ne la porte pas. Le
# faux rouge que la passe précédente fermait tenait au NOMBRE et à « à l' » — jamais à l'infinitif :
# retirer `|re` ne le rouvre pas (contre-épreuve : la réécriture licite au singulier reste verte).
# L'infinitif est donc refusé DANS LES DEUX SENS, y compris une tournure affirmative (« c'est au
# manager de répondre aux… ») : une forme dont la garde ne peut pas lire la polarité se refuse,
# elle ne s'accepte pas au bénéfice du doute — un gate qui ne sait pas conclure rougit.
T26_HALT_RE='halte[[:space:]]+de[[:space:]]+nœud'
T26_ANSWER_RE="répond(s)?[[:space:]]+(aux[[:space:]]+|à[[:space:]]+l['’][[:space:]]*)attentes?[[:space:]]+humaines?"
t26_c_blk="$(md_blocks_matching "$MFLOW" "$T24_ANCHOR_C")"
if [ -z "$t26_c_blk" ]; then
  ko "T26 C : bloc « Verdict d'étape » introuvable dans mission-flow.md — rien n'a été mesuré"; t26_ok=0
else
  printf '%s\n' "$t26_c_blk" | "$GREP" -qE "$T26_HALT_RE" \
    || { ko "T26 C : le bloc « Verdict d'étape » de mission-flow.md ne nomme pas le halt de nœud"; t26_ok=0; }
  printf '%s\n' "$t26_c_blk" | "$GREP" -qE "$T26_ANSWER_RE" \
    || { ko "T26 C : le bloc « Verdict d'étape » de mission-flow.md ne nomme pas le manager comme répondant aux attentes humaines"; t26_ok=0; }
fi

# D (NÉGATIVE) — aucun .md de doctrine du module (module_md_targets : agents de l'équipe +
# références résolues) ne reproduit les intitulés du contrat interne de l'exécuteur amont. Le
# compteur de fichiers vus est non négociable : sans lui, un glob qui n'expanse pas rendrait un
# vert prétendant avoir balayé ce qu'il n'a jamais ouvert.
#
# B6 — ÉVASION PAR RETOUR À LA LIGNE, fermée ici. Les intitulés visés sont MULTI-MOTS et les
# fichiers balayés sont wrappés à 100 colonnes : un « Completed / Tasks » coupé au pli échappait à
# un motif à espace littéral et la garde restait VERTE sur la duplication qu'elle interdit
# (contrôle positif à l'appui). Deux passes COMPLÉMENTAIRES, jamais l'une à la place de l'autre :
#   1. LIGNE À LIGNE pour l'intitulé ANCRÉ `^Awaiting$` — l'ancre de ligne n'a plus de sens sur un
#      fichier replié, et la dégrader en `Awaiting` nu ferait rougir toute prose anglaise ;
#   2. FICHIER REPLIÉ (md_folded) + blancs ÉLASTIQUES pour les intitulés multi-mots, ET pour
#      `Awaiting` en POSITION DE RUBRIQUE ($T26_AWAITING_RE) — la passe 1 seule ne couvrait que
#      la ligne strictement nue, donc aucune des graphies markdown sous lesquelles une recopie
#      s'écrit réellement. La passe 1 est CONSERVÉE (elle capte la ligne nue, que la 2 ne voit
#      pas) : les deux sont complémentaires, jamais l'une à la place de l'autre.
# Urgence : A-3 vient d'élargir le minimum de reprise à la table des tâches faites — c'est-à-dire
# de rouvrir la porte exacte que cette garde surveille.
t26_internal_titles() { # <file> — imprime le fichier s'il reproduit un intitulé interne
  "$GREP" -lE '^Awaiting$' "$1" 2>/dev/null && return 0
  md_folded "$1" | "$GREP" -qE "$T26_INTERNAL_MULTI_RE|$T26_AWAITING_RE" && printf '%s\n' "$1"
  return 0
}
t26_dup_hits=""; t26_scanned=0
while IFS= read -r t26_f; do            # variables préfixées : cf. note du balayage T25
  [ -n "$t26_f" ] || continue
  t26_scanned=$((t26_scanned + 1))
  t26_h="$(t26_internal_titles "$t26_f")"
  [ -n "$t26_h" ] && t26_dup_hits="$t26_dup_hits $t26_f"
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

# E (DISCRIMINANT, par mutation) — une fixture pour D et TROIS mutants du contrat pour A, chacun
# ancré sur un motif que les gardes de A exigent déjà (donc jamais un no-op invisible), chacun
# VÉRIFIÉ différent de l'original avant d'être mesuré, chacun jugé sur TROIS branches :
#   rc=1 → détecté (seul succès) · rc=0 → mutation non détectée · rc=2 → l'ancre du bloc a été
#   détruite : la mutation n'a RIEN mesuré, ce n'est pas une détection. L'ancienne forme
#   (`t26_reprise_closed "$MUT" && …`) confondait rc=2 avec un succès, et son sed visait une phrase
#   littérale du contrat — une reformulation anodine le rendait no-op, et E rougissait alors avec
#   un message accusant A alors que la mutation n'avait pas mordu.
T26_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T26_TMPDIR"
T26_FIXTURE="$T26_TMPDIR/duplicated-contract.md"
T26_MUT_INTERDIT="$T26_TMPDIR/mutant-champ-interdit.md"
T26_MUT_RENAME="$T26_TMPDIR/mutant-rename-plan-id.md"
T26_MUT_BORNE="$T26_TMPDIR/mutant-borne-sans-gras.md"
printf '## Rapport de reprise\n\n**Completed Tasks** table (hashes + files)\n' > "$T26_FIXTURE"
# 1. un champ INTERDIT ajouté DANS l'énumération close (la table que ADR-030 interdit de recopier).
md_sed_folded "s/[*][*]rien${MDSP}d'autre[*][*]/, \`taches_executees\` — **rien d'autre**/" "$CONTRACTS_FILE" > "$T26_MUT_INTERDIT"
# 2. un sous-champ fixé par D-03 RENOMMÉ : l'ensemble reste clos, il ne désigne plus la même chose.
sed 's/`plan_id`/`plan_ref`/g' "$CONTRACTS_FILE" > "$T26_MUT_RENAME"
# 3. la borne fermante dégrassée : garde et coupe doivent parler du MÊME motif.
md_sed_folded "s/[*][*]rien${MDSP}d'autre[*][*]/rien d'autre/" "$CONTRACTS_FILE" > "$T26_MUT_BORNE"

t26_e_ko=""
t26_assert_mutant_red() { # <libellé> <fichier mutant>
  if cmp -s "$CONTRACTS_FILE" "$2"; then
    t26_e_ko="$t26_e_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus dans le contrat, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de A)]"
    return
  fi
  t26_reprise_closed "$2"
  case $? in
    1) : ;;
    0) t26_e_ko="$t26_e_ko [$1 : NON détecté par A]" ;;
    *) t26_e_ko="$t26_e_ko [$1 : rc=2, ancre du bloc détruite — rien n'a été mesuré, ce n'est pas une détection]" ;;
  esac
}
[ -n "$(t26_internal_titles "$T26_FIXTURE")" ] || t26_e_ko="$t26_e_ko [fixture d'intitulé interne non détectée par D]"
t26_assert_mutant_red "champ interdit dans l'énumération (taches_executees)" "$T26_MUT_INTERDIT"
t26_assert_mutant_red "renommage d'un sous-champ de D-03 (plan_id→plan_ref)" "$T26_MUT_RENAME"
t26_assert_mutant_red "borne fermante dégrassée (garde vs coupe désalignés)" "$T26_MUT_BORNE"
# Dernier appel sur le contrat RÉEL : il revalide A et restaure $T26_FIELDS/$T26_N pour le bilan.
t26_reprise_closed "$CONTRACTS_FILE"
case $? in
  0) : ;;
  2) t26_e_ko="$t26_e_ko [le contrat réel : bloc « Minimum de reprise » introuvable (rc=2)]" ;;
  *) t26_e_ko="$t26_e_ko [le contrat réel ne tient plus l'assertion A — $T26_WHY]" ;;
esac
if [ -n "$t26_e_ko" ]; then
  ko "T26 E (DISCRIMINANT) : une assertion ne rougit pas sur mutation —$t26_e_ko"; t26_ok=0
else
  ok "T26 E (DISCRIMINANT) : intitulé interne détecté par D ; 3 mutants du contrat (champ interdit, renommage D-03, borne dégrassée) détectés par A, chacun prouvé différent de l'original ; contrat réel tenu"
fi

# D+ (CONTRÔLE POSITIF de la branche `Awaiting`) — la garde D est NÉGATIVE : elle est verte quand
# aucun fichier ne reproduit d'intitulé, ET quand une de ses branches ne peut rien voir. Les quatre
# intitulés multi-mots ont leur contrôle positif ($T26_FIXTURE, exercé par E) ; la branche
# `Awaiting` n'en avait AUCUN — elle a donc pu rester des mois à ne couvrir que la ligne nue sans
# qu'une seule exécution ne le dise. Trois fixtures, dans les deux sens :
#   · deux RECOPIES qui doivent être vues — la graphie réellement produite par une duplication
#     (`**Awaiting** : …`, coupée au pli pour rejouer B6) et la graphie titre (`### Awaiting`) ;
#   · une PROSE ANGLAISE licite qui doit rester verte — c'est la justification écrite en tête de D
#     (ne pas dégrader en `Awaiting` nu), désormais VÉRIFIÉE au lieu d'être seulement affirmée.
T26_FIXTURE_AWAITING="$T26_TMPDIR/awaiting-rubrique-gras.md"
T26_FIXTURE_AWAITING_TITRE="$T26_TMPDIR/awaiting-rubrique-titre.md"
T26_LICIT_AWAITING="$T26_TMPDIR/awaiting-prose-anglaise.md"
printf '## Rapport de reprise\n\n**Awaiting** : la rubrique du contrat interne amont, recopiée\ntelle quelle ici.\n' > "$T26_FIXTURE_AWAITING"
printf '### Awaiting\n\nCe que le moteur attend de l'"'"'utilisateur.\n' > "$T26_FIXTURE_AWAITING_TITRE"
printf 'Le nœud reste en attente. Awaiting the human answer, le manager ne tranche jamais seul.\n' > "$T26_LICIT_AWAITING"
t26_aw_ko=""
[ -n "$(t26_internal_titles "$T26_FIXTURE_AWAITING")" ] \
  || t26_aw_ko="$t26_aw_ko [recopie sous graphie gras (« **Awaiting** : … ») NON détectée — la branche ne couvre toujours que la ligne nue]"
[ -n "$(t26_internal_titles "$T26_FIXTURE_AWAITING_TITRE")" ] \
  || t26_aw_ko="$t26_aw_ko [recopie sous graphie titre (« ### Awaiting ») NON détectée]"
[ -z "$(t26_internal_titles "$T26_LICIT_AWAITING")" ] \
  || t26_aw_ko="$t26_aw_ko [FAUX ROUGE : de la prose anglaise contenant le mot « Awaiting » est comptée comme une recopie de rubrique]"
if [ -z "$t26_aw_ko" ]; then
  ok "T26 D+ (CONTRÔLE POSITIF, branche Awaiting) : le 5e intitulé du contrat interne est mesuré à parité avec les 4 multi-mots — recopie vue sous graphie gras et sous graphie titre, prose anglaise épargnée"
else
  ko "T26 D+ (CONTRÔLE POSITIF, branche Awaiting) : la branche « Awaiting » de la garde D ne mesure pas ce que D annonce —$t26_aw_ko"; t26_ok=0
fi

[ "$t26_ok" -eq 1 ] && ok "T26 : minimum de reprise (ensemble mesuré = exactement les $T26_N noms de D-03), halte de nœud, réponse par le manager, garde anti-duplication discriminante par mutation"

# ---------------------------------------------------------------------------
# T26 F (A-3) — le DISTINGUO ADR-030 est ÉCRIT, pas sous-entendu. Le contrat interdisait
# explicitement la table des tâches faites ; A-3 lève cette interdiction pour ce seul cas. Sans la
# phrase qui sépare les deux objets, la garde repart en faux rouge à la première relecture : rien
# ne distinguerait plus « recopier de la DOCTRINE amont » (interdit — elle se relit à sa source) de
# « transporter un ÉTAT de reprise » (nécessaire — un état mesuré n'est nulle part ailleurs et se
# perd si personne ne le transporte). L'assertion mesure la présence des DEUX termes du distinguo
# dans le MÊME bloc, avec son motif ADR-030 : une moitié de distinguo ne distingue rien.
# ---------------------------------------------------------------------------
t26f_ok=1
T26F_WHY=""
t26_distinguo_written() { # <file>
  local blk
  T26F_WHY=""
  # Blancs élastiques (B6) : ancre comme motifs sont mesurés sur le bloc RECOLLÉ.
  blk="$(md_blocks_matching "$1" '[*][*]Distinguo[[:space:]]+à[[:space:]]+ne[[:space:]]+jamais[[:space:]]+réduire[*][*]')"
  [ -n "$blk" ] || { T26F_WHY="aucun bloc ne porte le distinguo (« **Distinguo à ne jamais réduire**  »)"; return 2; }
  printf '%s\n' "$blk" | "$GREP" -q 'ADR-030' \
    || { T26F_WHY="le distinguo ne cite pas ADR-030 — il ne se rattache à aucune garde"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -qiE 'doctrine[[:space:]]+amont' \
    || { T26F_WHY="le distinguo ne nomme pas ce qui reste INTERDIT (la recopie de doctrine amont)"; return 1; }
  printf '%s\n' "$blk" | "$GREP" -qiE 'état[[:space:]]+de[[:space:]]+reprise' \
    || { T26F_WHY="le distinguo ne nomme pas ce qui devient LICITE (le transport d'un état de reprise)"; return 1; }
  return 0
}

T26F_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T26F_TMPDIR"
T26F_MUT_MOITIE="$T26F_TMPDIR/mutant-distinguo-a-moitie.md"
T26F_MUT_INTERDIT="$T26F_TMPDIR/mutant-distinguo-sans-l-interdit.md"
T26F_MUT_ORPHELIN="$T26F_TMPDIR/mutant-distinguo-sans-garde.md"
# Les trois mutants gardent l'ANCRE du bloc : chacun est donc mesuré là où on prétend mesurer, et
# jugé sur rc=1 (fermeture rompue) — jamais sur rc=2, qui signerait une ancre détruite, c'est-à-dire
# rien de mesuré du tout.
# 1. la moitié LICITE du distinguo effacée : il ne reste que l'interdit, donc plus de distinction.
md_sed_folded "s/état${MDSP}de${MDSP}reprise/objet/g" "$CONTRACTS_FILE" > "$T26F_MUT_MOITIE"
# 2. la moitié INTERDITE effacée : symétrique — un distinguo sans son interdit n'interdit plus rien.
md_sed_folded "s/doctrine${MDSP}amont/matière amont/g" "$CONTRACTS_FILE" > "$T26F_MUT_INTERDIT"
# 3. le distinguo détaché de sa garde : il ne cite plus ADR-030, donc il n'amende plus rien.
sed 's/ADR-030/la garde/g' "$CONTRACTS_FILE" > "$T26F_MUT_ORPHELIN"

t26f_ko=""
t26f_assert_mutant_red() { # <libellé> <mutant>
  if cmp -s "$CONTRACTS_FILE" "$2"; then
    t26f_ko="$t26f_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de l'assertion)]"
    return
  fi
  t26_distinguo_written "$2"
  case $? in
    1) : ;;
    0) t26f_ko="$t26f_ko [$1 : NON détecté]" ;;
    *) t26f_ko="$t26f_ko [$1 : rc=2, ancre du bloc détruite — rien n'a été mesuré, ce n'est pas une détection]" ;;
  esac
}
t26f_assert_mutant_red "moitié LICITE du distinguo effacée (état de reprise)"    "$T26F_MUT_MOITIE"
t26f_assert_mutant_red "moitié INTERDITE du distinguo effacée (doctrine amont)"  "$T26F_MUT_INTERDIT"
t26f_assert_mutant_red "distinguo détaché de sa garde (ADR-030 non cité)"        "$T26F_MUT_ORPHELIN"
t26_distinguo_written "$CONTRACTS_FILE" || t26f_ko="$t26f_ko [le contrat réel : $T26F_WHY]"
if [ -z "$t26f_ko" ]; then
  ok "T26 F (A-3, DISCRIMINANT) : le distinguo ADR-030 est écrit dans mission-contracts.md — recopie de DOCTRINE amont (interdite) vs transport d'un ÉTAT de reprise (licite) — et 3 mutants (chaque moitié effacée, garde décitée) font rougir l'assertion, tous mesurés sur l'ancre intacte"
else
  ko "T26 F (A-3) : le distinguo ADR-030 n'est pas gardé —$t26f_ko"; t26f_ok=0
fi

# ---------------------------------------------------------------------------
# T26 E' (A-3, DISCRIMINANT) — l'égalité d'ensemble recalibrée reste DISCRIMINANTE sur les DEUX
# noms ajoutés. Élargir une cible sans réarmer la sonde, c'est livrer un gate qui suit la doctrine
# au lieu de la tenir : un renommage silencieux de `reponse_humaine` casserait la reprise
# exactement comme un renommage de `plan_id`. E' s'AJOUTE à E, qui garde ses 3 mutants.
# ---------------------------------------------------------------------------
T26EP_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T26EP_TMPDIR"
T26EP_MUT_REPONSE="$T26EP_TMPDIR/mutant-rename-reponse-humaine.md"
T26EP_MUT_TACHES="$T26EP_TMPDIR/mutant-rename-taches-faites.md"
T26EP_MUT_HORS="$T26EP_TMPDIR/mutant-champ-hors-ensemble.md"
sed 's/`reponse_humaine`/`reponse_user`/g' "$CONTRACTS_FILE" > "$T26EP_MUT_REPONSE"
sed 's/`taches_faites`/`taches_executees`/g' "$CONTRACTS_FILE" > "$T26EP_MUT_TACHES"
# Champ ajouté dont AUCUNE liste noire ne contient la graphie : c'est l'égalité d'ensemble, et elle
# seule, qui doit le refuser. Sans elle, un `journal_de_bord` passait à 87 OK / 0 KO.
md_sed_folded "s/[*][*]rien${MDSP}d'autre[*][*]/, \`journal_de_bord\` — **rien d'autre**/" "$CONTRACTS_FILE" > "$T26EP_MUT_HORS"

t26ep_ko=""
t26ep_assert_mutant_red() { # <libellé> <mutant>
  if cmp -s "$CONTRACTS_FILE" "$2"; then
    t26ep_ko="$t26ep_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus dans le contrat, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de A)]"
    return
  fi
  t26_reprise_closed "$2"
  case $? in
    1) : ;;
    0) t26ep_ko="$t26ep_ko [$1 : NON détecté par A]" ;;
    *) t26ep_ko="$t26ep_ko [$1 : rc=2, ancre du bloc détruite — rien n'a été mesuré, ce n'est pas une détection]" ;;
  esac
}
t26ep_assert_mutant_red "renommage de reponse_humaine (→ reponse_user)"          "$T26EP_MUT_REPONSE"
t26ep_assert_mutant_red "renommage de taches_faites (→ taches_executees)"        "$T26EP_MUT_TACHES"
t26ep_assert_mutant_red "champ hors ensemble clos, absent de toute liste noire"  "$T26EP_MUT_HORS"
# Dernier appel sur le contrat RÉEL : revalide A et restaure $T26_FIELDS/$T26_N.
t26_reprise_closed "$CONTRACTS_FILE" || t26ep_ko="$t26ep_ko [le contrat réel ne tient plus l'assertion A — $T26_WHY]"
if [ -z "$t26ep_ko" ]; then
  ok "T26 E' (A-3, DISCRIMINANT) : l'ensemble clos ÉLARGI reste mesuré en égalité — renommage de l'un ou l'autre des 2 noms ajoutés (reponse_humaine, taches_faites) et champ hors ensemble absent de toute liste noire font tous trois rougir A"
else
  ko "T26 E' (A-3, DISCRIMINANT) : l'ensemble élargi n'est plus discriminant —$t26ep_ko"; t26_ok=0
fi

# ---------------------------------------------------------------------------
# T27 (A-4, DISCRIMINANT) — le contrôle de flux DÉPARTAGE gel et question par le MODE.
#
# Ce que ce gate ferme. Deux clauses CONSÉCUTIVES se contredisaient : la première qualifiait ses
# branches (« mode superviser : checkpoint ; mode autonome : GELER le nœud »), la seconde — « c'est
# toi qui réponds aux attentes humaines … tu poses la question puis redispatches » — n'en portait
# AUCUNE. En mode autonome l'utilisateur est absent par définition : un agent pouvait résoudre la
# tension dans le mauvais sens, en répondant lui-même à une attente humaine (violation directe
# d'ADR-031). L'absence de qualificatif était le défaut, pas une imprécision de style.
#
# CIBLE SUIVIE (déport A-4). La clause vivait dans vf-dev-manager.md ; elle a été déportée dans
# mission-flow.md §Pattern C (« Contrôle de flux du manager ») pour rendre au plafond ADR-029 la
# marge que l'agent n'avait plus (249/250). La sonde SUIT le bloc — la laisser sur l'agent en
# ferait une sonde verte qui ne mesure plus rien. Le volet « renvoi » ci-dessous ferme l'autre
# moitié du risque : que l'agent perde le pointeur vers le foyer.
#
# Ce qui est mesuré, DANS le segment du statut `human_needed` (même isolation que T24 F1 — un
# qualificatif de mode posé sur un AUTRE verdict ne qualifie pas celui-ci) :
#   (a) aucune clause disposant d'une attente humaine n'est MUETTE sur le mode ;
#   (b) chaque disposition est rattachée au BON mode — poser la question ⇒ superviser, geler le
#       nœud ⇒ autonome. Sans (b), échanger les deux modes passerait inaperçu alors que c'est
#       exactement l'inversion qui rouvre ADR-031.
#   (c) et à LUI SEUL. (a) et (b) mesurent chacune une EXISTENCE — « il existe une clause de
#       question qualifiée superviser » — jamais une exclusion. Une SECONDE clause, AJOUTÉE à côté
#       de la bonne et rattachée au mauvais mode, les satisfait toutes les deux. Ce n'est pas une
#       hypothèse : au déport A-4, injecter « en mode **autonome**, c'est le manager qui répond
#       aux attentes humaines » dans le segment — l'inverse exact d'ADR-031, sans retirer un seul
#       token — laissait la suite à 92 OK / 0 KO. (c) ferme ce trou : aucune clause de QUESTION ne
#       peut porter « mode autonome », aucune clause de GEL ne peut porter « mode superviser ».
#       Écart assumé : une clause qui nommerait les DEUX modes pour une même disposition rougit.
#       Elle le doit — sur ces deux dispositions-là, « superviser comme autonome » EST la faute.
# La clause est bornée par « ; » et « · », les séparateurs de branche du bloc — jamais par « : »,
# qui sépare l'annonce de sa disposition à l'INTÉRIEUR d'une même branche.
#
# Les deux personnes du verbe sont reconnues : la référence rédige à la 3e (« il pose la
# question », « le manager répond aux attentes humaines »), une rédaction adressée au manager à la
# 2e (« tu poses », « tu réponds »). Punir l'une des deux serait un faux rouge sur une rédaction
# licite — la fixture L, qui est écrite à la 2e personne, le prouve à chaque exécution.
#
# ÉLASTICITÉ DE GRAPHIE (B5, 2026-08-02). Un motif qui ne reconnaît QUE la graphie du foyer est
# aveugle partout ailleurs, et son aveuglement est silencieux : la doctrine peut dire l'inverse
# d'ADR-031 sans qu'un seul KO ne sorte. C'est ce qui s'est produit une TROISIÈME fois — après les
# deux foyers fermés par B4 — sur le renvoi de vf-dev-manager.md, qui paraphrase A-4 dans ses
# propres graphies : « superviser : tu réponds à l'attente humaine ; autonome : gel du nœud ».
# Trois écarts, trois angles morts cumulés :
#   · l'attente au SINGULIER, introduite par « à l' » et non par « aux » ;
#   · le gel au NOMINAL (« gel du nœud ») et non au verbal (« GELER », « geler le nœud ») ;
#   · le mode annoncé en TÊTE DE BRANCHE (« superviser : … ») et non en incise (« en mode
#     **superviser**, … ») — la forme même que le §clause décrit plus haut, où « : » sépare
#     l'annonce de sa disposition À L'INTÉRIEUR d'une branche.
# Échanger les deux modes dans cette paraphrase — l'inversion exacte qui rouvre ADR-031 — laissait
# la suite à 93 OK / 0 KO. Les trois motifs couvrent donc désormais les deux nombres, les deux
# formes (nominale et verbale) et les deux positions du qualificatif de mode. Le balayage des 13
# cibles a été refait motif par motif : l'élargissement ne capture que les 2 clauses de cette
# paraphrase, toutes deux correctement qualifiées — aucun faux rouge (T27c le rejoue).
#
# Tous les blancs INTERNES des motifs sont élastiques ([[:space:]]+) : md_blocks_matching recolle
# les lignes du bloc en conservant leur indentation, donc une formule coupée par le repli à 100
# colonnes se retrouve avec plusieurs espaces au pli. Un motif à espace littéral ne rougirait pas
# — il deviendrait AVEUGLE, ce qui est pire : la clause pourrait disparaître sans un seul KO.
# ---------------------------------------------------------------------------
t27_ok=1
# QUALIFICATIF DE MODE — deux positions licites, une par mode. En INCISE (« en mode
# **superviser**, … ») : la graphie du foyer. En TÊTE DE BRANCHE (« superviser : … ») : la graphie
# du renvoi. Ces deux motifs sont nommés séparément parce que (b) et (c) mesurent une RELATION —
# quel mode qualifie quelle disposition — et non la présence d'un mot : les confondre dans une
# alternance unique rendrait l'inversion des deux modes indétectable.
T27_MODE_SUP_RE='mode[[:space:]]+[*]*superviser|[*]*superviser[*]*[[:space:]]*:'
T27_MODE_AUTO_RE='mode[[:space:]]+[*]*autonome|[*]*autonome[*]*[[:space:]]*:'
T27_MODE_RE="$T27_MODE_SUP_RE|$T27_MODE_AUTO_RE"
# Disposition de QUESTION : « répond / réponds / répondre », « aux attentes humaines » comme « à
# l'attente humaine » (les deux nombres, les deux apostrophes — droite et typographique).
T27_ASK_RE="répond(s|re)?[[:space:]]+(aux[[:space:]]+|à[[:space:]]+l['’][[:space:]]*)attentes?[[:space:]]+humaines?|pose(s|r)?[[:space:]]+la[[:space:]]+question"
# Disposition de GEL : forme verbale (« GELER », « gèle/geler/gelez le nœud ») ET forme nominale
# (« gel du nœud », « halte de nœud »). Le participe seul (« a gelé une mission », « fichiers
# gelés ») reste HORS motif : il raconte un fait passé, il ne dispose de rien.
T27_FREEZE_RE='GELER|halte[[:space:]]+de[[:space:]]+nœud|gel[[:space:]]+d(u|e)[[:space:]]+nœud|g(è|e)l(e|es|er|ez)[[:space:]]+le[[:space:]]+nœud'
T27_WHY=""

t27_clauses() { awk '{ gsub(/;|·/, "\n"); print }'; }

t27_flow_modes() { # <file>
  local seg unqual crossed
  T27_WHY=""
  seg="$(md_blocks_matching "$1" "$T24_ANCHOR_C" | t24_segment_of 'human_needed')"
  [ -n "$seg" ] || { T27_WHY="segment du statut human_needed introuvable dans le bloc « Verdict d'étape » — rien n'a été mesuré"; return 2; }

  # (a) — une clause qui dispose d'une attente humaine SANS nommer le mode est le défaut d'origine.
  unqual="$(printf '%s\n' "$seg" | t27_clauses \
            | "$GREP" -E "$T27_ASK_RE|$T27_FREEZE_RE" | "$GREP" -vE "$T27_MODE_RE" \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$unqual" ] || { T27_WHY="clause de contrôle de flux SANS qualificatif de mode — « $unqual »"; return 1; }

  # (b) — le rattachement, pas seulement la co-présence des deux mots « superviser » et « autonome ».
  printf '%s\n' "$seg" | t27_clauses | "$GREP" -E "$T27_ASK_RE" | "$GREP" -qE "$T27_MODE_SUP_RE" \
    || { T27_WHY="répondre à l'attente humaine (poser la question) n'est pas rattaché au mode SUPERVISER — en mode autonome, y répondre viole ADR-031"; return 1; }
  printf '%s\n' "$seg" | t27_clauses | "$GREP" -E "$T27_FREEZE_RE" | "$GREP" -qE "$T27_MODE_AUTO_RE" \
    || { T27_WHY="le GEL du nœud n'est pas rattaché au mode AUTONOME — « toujours geler » interromprait aussi les sessions supervisées"; return 1; }

  # (c) — EXCLUSIVITÉ : aucune clause de QUESTION sous le mode autonome, aucune clause de GEL sous
  # le mode superviser. Sans elle, (a) et (b) restent satisfaites par la BONNE clause pendant
  # qu'une clause contradictoire vit juste à côté.
  crossed="$(printf '%s\n' "$seg" | t27_clauses | "$GREP" -E "$T27_ASK_RE" | "$GREP" -E "$T27_MODE_AUTO_RE" \
             | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$crossed" ] || { T27_WHY="une clause rattache la RÉPONSE à l'attente humaine au mode AUTONOME — l'utilisateur y est absent par définition, y répondre viole ADR-031 : « $crossed »"; return 1; }
  crossed="$(printf '%s\n' "$seg" | t27_clauses | "$GREP" -E "$T27_FREEZE_RE" | "$GREP" -E "$T27_MODE_SUP_RE" \
             | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$crossed" ] || { T27_WHY="une clause rattache le GEL du nœud au mode SUPERVISER — le checkpoint humain y est disponible, geler priverait la session de sa réponse : « $crossed »"; return 1; }
  return 0
}

t27_flow_modes "$MFLOW"
case $? in
  0) : ;;
  2) ko "T27 (A-4) : mission-flow.md — $T27_WHY"; t27_ok=0 ;;
  *) ko "T27 (A-4) : mission-flow.md — $T27_WHY"; t27_ok=0 ;;
esac

# Volet RENVOI (corollaire du déport) — l'agent ne porte plus la clause, il doit donc porter le
# POINTEUR, et un pointeur qui ne nomme pas son foyer ne se suit pas. Deux exigences dans le MÊME
# bloc du §Contrôle de flux : le fichier foyer et la section. Sans ce volet, un futur plan pourrait
# supprimer le renvoi sans qu'aucune sonde ne bronche : la clause serait introuvable depuis l'agent
# alors même que T27 resterait vert sur la référence.
t27_renvoi_blk="$(md_blocks_matching "$DEVMGR" '[*][*]Table[[:space:]]+de[[:space:]]+pilotage')"
if [ -z "$t27_renvoi_blk" ]; then
  ko "T27 (A-4, renvoi) : vf-dev-manager.md ne porte aucun bloc de renvoi vers la table de pilotage — la clause déportée est devenue injoignable depuis l'agent"; t27_ok=0
else
  printf '%s\n' "$t27_renvoi_blk" | "$GREP" -q 'mission-flow.md' \
    || { ko "T27 (A-4, renvoi) : le bloc de renvoi de vf-dev-manager.md ne nomme pas mission-flow.md"; t27_ok=0; }
  printf '%s\n' "$t27_renvoi_blk" | "$GREP" -qE 'Pattern[[:space:]]+C' \
    || { ko "T27 (A-4, renvoi) : le bloc de renvoi de vf-dev-manager.md ne nomme pas la section (§Pattern C) — un renvoi au fichier entier n'est pas un renvoi"; t27_ok=0; }

  # CITATION NON PENDANTE. Le renvoi cite en outre un SOUS-TITRE entre guillemets français
  # (« Contrôle de flux du manager »). Rien ne vérifiait que ce titre existe côté foyer : le
  # renommer laissait la suite à 99 OK / 0 KO — le renvoi pointait vers un titre disparu et aucune
  # sonde ne bronchait. Famille connue de ce dépôt (renommage de section → citation pendante).
  #
  # CE QUI EST MESURÉ : une RELATION — « la chaîne citée par l'agent existe comme TITRE dans le
  # foyer » —, jamais la présence du mot « Contrôle » quelque part dans le fichier. La citation est
  # EXTRAITE du bloc de renvoi, jamais réencodée en dur ici : une sonde en dur resterait verte le
  # jour où l'agent citerait autre chose, c'est-à-dire exactement quand la citation devient
  # pendante. Elle est ensuite convertie en ERE à blancs ÉLASTIQUES — une citation coupée par le
  # repli à 100 colonnes arrive du bloc recollé avec l'indentation de la ligne suivante.
  #
  # COMPTEUR D'ATTEINTE : zéro citation extraite ⇒ KO. Un renvoi qui perdrait ses guillemets
  # éteindrait sinon la sonde en silence, sur exactement le risque qu'elle ferme.
  t27_cit_n=0; t27_cit_ko=""
  while IFS= read -r t27_cit; do
    [ -n "$t27_cit" ] || continue
    t27_cit_n=$((t27_cit_n + 1))
    t27_cit_re="$(printf '%s' "$t27_cit" \
                  | sed -e 's/[][\.*^$(){}?+|]/\\&/g' -e 's/[[:space:]][[:space:]]*/[[:space:]]+/g')"
    "$GREP" -E '^#{1,6}[[:space:]]' "$MFLOW" | "$GREP" -qE "$t27_cit_re" \
      || t27_cit_ko="$t27_cit_ko [« $t27_cit » : citée par le renvoi, absente des TITRES de mission-flow.md]"
  done < <(printf '%s\n' "$t27_renvoi_blk" | "$GREP" -oE '«[^»]*»' \
           | sed -e 's/^«[[:space:]]*//' -e 's/[[:space:]]*»$//')
  if [ "$t27_cit_n" -eq 0 ]; then
    ko "T27 (A-4, renvoi) : le bloc de renvoi de vf-dev-manager.md ne cite AUCUN titre entre guillemets — la sonde de citation pendante n'a rien à mesurer, elle serait verte à vide"; t27_ok=0
  elif [ -n "$t27_cit_ko" ]; then
    ko "T27 (A-4, renvoi) : citation PENDANTE — le renvoi cite un titre qui n'existe pas dans le foyer :$t27_cit_ko"; t27_ok=0
  else
    ok "T27 (A-4, renvoi, citation non pendante) : le ou les $t27_cit_n titre(s) cités entre guillemets par le renvoi de vf-dev-manager.md existent comme TITRE dans mission-flow.md — un renommage du sous-titre du foyer fait rougir"
  fi
fi

# Cinq mutants + une fixture LICITE. (Le libellé d'ok ci-dessous n'en annonce que trois : il est
# GELÉ depuis A-4 et sous-déclare volontairement — un libellé qui sous-déclare ne ment pas, alors
# que le réécrire ferait disparaître une entrée de l'ensemble des libellés, seul invariant sur
# lequel se compare une recette d'une version à l'autre. Les messages de KO, eux, sont exacts.)
#   M1 (RELATION, aucun token retiré) : les deux qualificatifs de mode sont ÉCHANGÉS. (a) reste
#      satisfaite — les deux branches restent qualifiées —, seule (b) mord : c'est précisément
#      l'inversion qui autorise un agent à répondre en autonomie.
#   M2 : le qualificatif retiré de la branche de GEL — la forme littérale du défaut d'origine.
#   M3 : le qualificatif retiré de la branche de QUESTION — le défaut d'origine, exactement.
#   M4/M5 (AJOUT, aucun token retiré — ce que (c) ferme) : une clause contradictoire est INSÉRÉE
#      à côté de la bonne, avant l'entrée `gaps_found` qui borne le segment. M4 rattache la
#      réponse à l'attente humaine au mode autonome (l'inverse d'ADR-031), M5 le gel du nœud au
#      mode superviser. (a) et (b) restent vertes sur les DEUX : elles mesurent une existence, pas
#      une exclusion. L'ancre d'insertion est STRUCTURELLE (l'entrée `gaps_found` → `dag.sh
#      reopen`, imposée par le contrat ADR-053) et non une phrase — une reformulation de la
#      doctrine ne la rend pas no-op ; si elle le devenait, le garde cmp -s le dit.
#   L  : une reformulation LICITE (modes en clair, sans gras, branches en ordre inverse) reste
#      VERTE — un gate qui punit une rédaction correcte nuit autant qu'un gate aveugle.
T27_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T27_TMPDIR"
T27_MUT_SWAP="$T27_TMPDIR/mutant-modes-echanges.md"
T27_MUT_GEL="$T27_TMPDIR/mutant-gel-sans-mode.md"
T27_MUT_QUESTION="$T27_TMPDIR/mutant-question-sans-mode.md"
T27_MUT_ADD_ASK="$T27_TMPDIR/mutant-ajout-question-en-autonome.md"
T27_MUT_ADD_GEL="$T27_TMPDIR/mutant-ajout-gel-en-superviser.md"
T27_LICIT="$T27_TMPDIR/licite-modes-en-clair.md"
# M1 est fabriqué DANS le segment mesuré, sur les MÊMES ancres structurelles que celles qui le
# bornent — jamais sur une graphie de prose. La forme précédente (`s/mode **superviser**/…/g` sur
# tout le fichier) était ancrée sur la graphie EN INCISE du foyer : dès qu'une réécriture licite
# déplace le qualificatif en TÊTE DE BRANCHE (« superviser : … », la graphie du renvoi, que T27c
# déclare pourtant reconnaître), le `sed` ne mord plus rien dans le segment mais mord encore
# AILLEURS (le bullet « Blocage », plus bas). Le fichier diffère donc le garde `cmp -s` passe, le
# garde de multiset canonique passe, et l'assertion rend « M1 NON détecté » — un faux rouge chiffré
# qui accuse l'assertion là où la mutation n'a rien mordu DANS le périmètre mesuré.
#
# COROLLAIRE À NE PAS REPERDRE : `cmp -s` est un garde au niveau du FICHIER. Il ne distingue pas
# « mutation hors du périmètre mesuré » de « mutation non détectée ». Il ne redevient exact que
# parce que la mutation est désormais CONFINÉE au segment : « fichier identique » y équivaut à
# « rien à muter dans le segment », et le message de KO dit alors la bonne chose.
#
# Bornes STRUCTURELLES, imposées par le contrat ADR-053 et déjà gatées ailleurs : le bloc
# « **Verdict d'…** » ($T24_ANCHOR_C, l'ancre de T24), puis les entrées de statut `human_needed`
# (ouverture) et `gaps_found` (fermeture) — celles-là mêmes que t24_segment_of découpe. La mutation
# échange les deux qualificatifs de mode QUELLE QUE SOIT leur graphie : elle suit la rédaction au
# lieu de la figer.
t27_swap_modes_in_segment() { # <file> — échange superviser ↔ autonome DANS le segment mesuré
  awk -v anchor="$T24_ANCHOR_C" '
    function swap(s) {
      gsub(/superviser/, "@VFSWAP@", s); gsub(/autonome/, "superviser", s)
      gsub(/@VFSWAP@/, "autonome", s); return s
    }
    state == 0 { if ($0 ~ anchor) state = 1 }
    state == 1 && match($0, /`human_needed`/) {
      print substr($0, 1, RSTART + RLENGTH - 1) swap(substr($0, RSTART + RLENGTH)); state = 2; next
    }
    state == 2 && match($0, /`gaps_found`/) {
      print swap(substr($0, 1, RSTART - 1)) substr($0, RSTART); state = 3; next
    }
    state == 2 { print swap($0); next }
    { print }
  ' "$1"
}
t27_swap_modes_in_segment "$MFLOW" > "$T27_MUT_SWAP"
md_sed_folded "s/en${MDSP}mode${MDSP}[*][*]autonome[*][*],${MDSP}il${MDSP}n/il n/" "$MFLOW" > "$T27_MUT_GEL"
md_sed_folded "s/en${MDSP}mode${MDSP}[*][*]superviser[*][*],${MDSP}c/c/"           "$MFLOW" > "$T27_MUT_QUESTION"
# Guillemets SIMPLES : les motifs portent des backticks (substitution de commande entre guillemets
# doubles). L'ancre `· `gaps_found` → `dag.sh reopen`` borne la fin du segment human_needed :
# insérer JUSTE avant, c'est insérer dans le segment mesuré, sans toucher au reste du bloc.
T27_ADD_ANCHOR="·${MDSP}\`gaps_found\`${MDSP}→${MDSP}\`dag.sh${MDSP}reopen\`"
md_sed_folded "s/$T27_ADD_ANCHOR/; en mode **autonome**, c’est le manager qui **répond aux attentes humaines** et il pose la question · \`gaps_found\` → \`dag.sh reopen\`/" "$MFLOW" > "$T27_MUT_ADD_ASK"
md_sed_folded "s/$T27_ADD_ANCHOR/; en mode **superviser**, GELER le nœud porteur (halte de nœud) · \`gaps_found\` → \`dag.sh reopen\`/" "$MFLOW" > "$T27_MUT_ADD_GEL"
cat > "$T27_LICIT" <<'T27L'
- **Verdict d'étape (rapport typé, ADR-053)** : `passed` → frontière suivante ·
  `human_needed` — déclenché par `gate="blocking-human"` amont OU par une précondition amont non
  satisfaite — → escalade : en mode autonome, GELER le nœud porteur (halte de nœud, jamais de
  mission), poursuivre les branches indépendantes et consigner la question au rapport ; en mode
  superviser, c'est toi qui réponds aux attentes humaines du moteur et tu poses la question ·
  `gaps_found` → relance de comblement.
T27L

t27_mut_ko=""
# Preuve que M1 est une mutation de RELATION et non un effacement : une fois les deux qualificatifs
# ramenés à un jeton canonique, le multiset de tokens doit être IDENTIQUE de part et d'autre.
t27_canon() { sed -e 's/superviser/@VFMD@/g' -e 's/autonome/@VFMD@/g' "$1" | tr -cs '[:alnum:]_@' '\n' | LC_ALL=C sort; }
[ "$(t27_canon "$MFLOW")" = "$(t27_canon "$T27_MUT_SWAP")" ] \
  || t27_mut_ko="$t27_mut_ko [M1 : le multiset canonique de tokens a changé — ce n'est plus une mutation de relation pure]"

t27_assert_mutant_red() { # <libellé> <mutant>
  if cmp -s "$MFLOW" "$2"; then
    t27_mut_ko="$t27_mut_ko [$1 : mutant IDENTIQUE à l'original — le motif visé n'existe plus, la mutation n'a rien mordu (sonde à réancrer, ce n'est PAS un défaut de l'assertion)]"
    return
  fi
  t27_flow_modes "$2"
  case $? in
    1) : ;;
    0) t27_mut_ko="$t27_mut_ko [$1 : NON détecté]" ;;
    *) t27_mut_ko="$t27_mut_ko [$1 : rc=2, segment du statut détruit — rien n'a été mesuré, ce n'est pas une détection]" ;;
  esac
}
t27_assert_mutant_red "M1 RELATION : qualificatifs de mode ÉCHANGÉS, aucun token retiré" "$T27_MUT_SWAP"
t27_assert_mutant_red "M2 : branche de GEL sans qualificatif de mode"                     "$T27_MUT_GEL"
t27_assert_mutant_red "M3 : branche de QUESTION sans qualificatif de mode"                "$T27_MUT_QUESTION"
t27_assert_mutant_red "M4 AJOUT : clause de QUESTION rattachée au mode autonome"          "$T27_MUT_ADD_ASK"
t27_assert_mutant_red "M5 AJOUT : clause de GEL rattachée au mode superviser"             "$T27_MUT_ADD_GEL"
t27_flow_modes "$T27_LICIT" || t27_mut_ko="$t27_mut_ko [FAUX ROUGE : une reformulation LICITE (modes en clair, ordre inverse) est rejetée (rc=$?, $T27_WHY)]"
t27_flow_modes "$MFLOW"     || t27_mut_ko="$t27_mut_ko [le fichier réel ne tient plus l'assertion — $T27_WHY]"
if [ -n "$t27_mut_ko" ]; then
  ko "T27 (A-4, DISCRIMINANT) : le départage gel/question par le mode n'est pas mesuré —$t27_mut_ko"; t27_ok=0
else
  ok "T27 (A-4, DISCRIMINANT) : les deux branches de l'escalade human_needed portent un qualificatif de mode EXPLICITE et le bon (question ⇒ superviser, gel du nœud ⇒ autonome) — 3 mutants font rougir l'assertion (modes échangés sans retirer un token, puis chaque branche démuselée de son mode), 1 reformulation LICITE reste verte"
fi

# ---------------------------------------------------------------------------
# T27b (B4, DISCRIMINANT) — l'exigence d'A-4 tient sur les TROIS cibles de doctrine, pas sur le
# seul foyer.
#
# CE QUE CE GATE FERME. T27 mesure (a) (b) (c) DANS le segment `human_needed` du bloc « Verdict
# d'étape » de mission-flow.md. Une clause contredisant A-4 DE FACE — « en mode **autonome**,
# c'est le manager qui **répond aux attentes humaines** », ou une branche de gel qualifiée
# « superviser » — écrite dans mission-contracts.md laissait la suite à 92 OK / 0 KO. La sonde
# stricte existait ; elle n'était simplement pas ATTEINTE sur 2 cibles sur 3. Même défaut et même
# remède que T24 a fini par recevoir pour D-01.
#
# RÉPARTITION, et pourquoi elle n'est pas arbitraire. (a-présence) et (b) sont des exigences de
# PRÉSENCE : la règle doit être écrite quelque part, et une seule fois (ADR-030, une seule voix) —
# les exiger de chaque fichier ferait rougir toute la doctrine pour n'avoir pas répété le foyer.
# Elles restent donc ancrées sur mission-flow.md §Pattern C, dans T27. L'EXCLUSION, elle, ne se
# satisfait d'aucun foyer : une clause qui contredit A-4 ne devient pas licite parce qu'elle est
# écrite ailleurs. C'est elle — plus l'interdiction de la clause MUETTE sur le mode, qui est le
# défaut d'origine littéral d'A-4 — qui balaie toute la doctrine du module ici.
#
# CIBLES : module_md_targets (agents d'équipe + références résolues), jamais un glob en dur. Les
# trois cibles nommées par A-4 sont en outre vérifiées PRÉSENTES dans l'ensemble balayé : sans
# cela, un déport futur — il y en a déjà eu un sur cette phase — sortirait une cible du balayage
# sans qu'un seul KO ne le dise.
# ---------------------------------------------------------------------------
t27b_ok=1
T27B_WHY=""
t27_no_crossed_clause() { # <file> — 0 = rien à redire · 1 = clause fautive ($T27B_WHY)
  local clauses hits
  T27B_WHY=""
  # Clause = segment borné par « ; » et « · » DANS UN BLOC markdown (ancre « . » = tous les
  # blocs) — jamais le fichier d'un bout à l'autre, qui rattacherait le mode d'une section à la
  # disposition d'une autre.
  clauses="$(md_blocks_matching "$1" '.' | t27_clauses)"
  hits="$(printf '%s\n' "$clauses" | "$GREP" -E "$T27_ASK_RE" | "$GREP" -E "$T27_MODE_AUTO_RE" \
          | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$hits" ] || { T27B_WHY="une clause rattache la RÉPONSE à l'attente humaine au mode AUTONOME — l'utilisateur y est absent par définition, y répondre viole ADR-031 : « $hits »"; return 1; }
  hits="$(printf '%s\n' "$clauses" | "$GREP" -E "$T27_FREEZE_RE" | "$GREP" -E "$T27_MODE_SUP_RE" \
          | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$hits" ] || { T27B_WHY="une clause rattache le GEL du nœud au mode SUPERVISER — le checkpoint humain y est disponible, geler priverait la session de sa réponse : « $hits »"; return 1; }
  hits="$(printf '%s\n' "$clauses" | "$GREP" -E "$T27_ASK_RE|$T27_FREEZE_RE" | "$GREP" -vE "$T27_MODE_RE" \
          | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' '|')"
  [ -z "$hits" ] || { T27B_WHY="une clause dispose d'une attente humaine SANS qualificatif de mode — le défaut d'origine d'A-4, littéralement : « $hits »"; return 1; }
  return 0
}

t27b_ko=""
t27b_scanned=0; t27b_seen_flow=0; t27b_seen_contracts=0; t27b_seen_devmgr=0
while IFS= read -r t27b_f; do
  [ -n "$t27b_f" ] || continue
  t27b_scanned=$((t27b_scanned + 1))
  case "$t27b_f" in
    "$MFLOW")          t27b_seen_flow=1 ;;
    "$CONTRACTS_FILE") t27b_seen_contracts=1 ;;
    "$DEVMGR")         t27b_seen_devmgr=1 ;;
  esac
  t27_no_crossed_clause "$t27b_f" || t27b_ko="$t27b_ko [$(basename "$t27b_f") : $T27B_WHY]"
done < <(module_md_targets)
[ "$t27b_scanned" -gt 0 ] \
  || t27b_ko="$t27b_ko [balayage : ZÉRO fichier de doctrine ouvert — un vert à vide n'est pas une garantie]"
[ "$t27b_seen_flow" -eq 1 ] \
  || t27b_ko="$t27b_ko [mission-flow.md HORS du balayage — la cible FOYER d'A-4 n'est pas mesurée]"
[ "$t27b_seen_contracts" -eq 1 ] \
  || t27b_ko="$t27b_ko [mission-contracts.md HORS du balayage — c'est LA cible sur laquelle une clause contredisant A-4 passait verte (B4)]"
[ "$t27b_seen_devmgr" -eq 1 ] \
  || t27b_ko="$t27b_ko [vf-dev-manager.md HORS du balayage — la cible qui porte le renvoi vers le foyer]"

# CONTRÔLE POSITIF, CIBLE PAR CIBLE. La clause est AJOUTÉE en fin de fichier — aucun token n'est
# retiré, aucune ancre existante n'est touchée, donc le mutant ne peut pas « détruire ce qu'il
# prétend mesurer ». Une cible qui resterait verte est un échec du nœud, pas un détail : c'est le
# mode d'échec exact que B4 décrit.
T27B_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T27B_TMPDIR"
T27B_ASK_AUTO="- **Contrôle de flux (clause injectée)** : en mode **autonome**, c'est le manager qui **répond aux attentes humaines** du moteur et il pose la question."
T27B_GEL_SUP="- **Contrôle de flux (clause injectée)** : en mode **superviser**, GELER le nœud porteur (halte de nœud, jamais de mission)."
T27B_MUETTE="- **Contrôle de flux (clause injectée)** : le manager **répond aux attentes humaines** du moteur et il pose la question."
# Rédaction CORRECTE de la même disposition : elle doit rester VERTE. Un gate qui punit une
# clause bien qualifiée ferait taire la doctrine au lieu de la tenir.
T27B_LICITE="- **Contrôle de flux (clause injectée)** : en mode **superviser**, le manager **répond aux attentes humaines** du moteur et il pose la question ; en mode **autonome**, GELER le nœud porteur (halte de nœud, jamais de mission)."

t27b_mut_n=0
t27b_assert_mutant_red() { # <libellé> <fichier cible> <clause injectée>
  local mut
  t27b_mut_n=$((t27b_mut_n + 1))
  mut="$T27B_TMPDIR/mutant-$t27b_mut_n.md"
  { cat "$2"; printf '\n%s\n' "$3"; } > "$mut"
  if cmp -s "$2" "$mut"; then
    t27b_ko="$t27b_ko [$1 : mutant IDENTIQUE à l'original — la clause n'a pas été injectée, rien n'a été mesuré]"
    return
  fi
  t27_no_crossed_clause "$mut" \
    && t27b_ko="$t27b_ko [$1 : NON détecté — une clause qui contredit A-4 DE FACE reste verte sur cette cible]"
}
for t27b_pair in "mission-flow.md:$MFLOW" "mission-contracts.md:$CONTRACTS_FILE" "vf-dev-manager.md:$DEVMGR"; do
  t27b_name="${t27b_pair%%:*}"; t27b_path="${t27b_pair#*:}"
  if [ ! -f "$t27b_path" ]; then
    t27b_ko="$t27b_ko [$t27b_name introuvable — cible d'A-4 non mesurable]"; continue
  fi
  t27b_assert_mutant_red "$t27b_name : QUESTION rattachée au mode autonome"  "$t27b_path" "$T27B_ASK_AUTO"
  t27b_assert_mutant_red "$t27b_name : GEL rattaché au mode superviser"      "$t27b_path" "$T27B_GEL_SUP"
  t27b_assert_mutant_red "$t27b_name : clause MUETTE sur le mode"            "$t27b_path" "$T27B_MUETTE"
done
T27B_LICIT_FILE="$T27B_TMPDIR/licite-clause-bien-qualifiee.md"
{ cat "$MFLOW"; printf '\n%s\n' "$T27B_LICITE"; } > "$T27B_LICIT_FILE"
t27_no_crossed_clause "$T27B_LICIT_FILE" \
  || t27b_ko="$t27b_ko [FAUX ROUGE : une clause CORRECTEMENT qualifiée (question ⇒ superviser, gel ⇒ autonome) est rejetée — $T27B_WHY]"

if [ -n "$t27b_ko" ]; then
  ko "T27b (B4, DISCRIMINANT) : l'exigence d'A-4 n'est pas tenue sur les trois cibles —$t27b_ko"; t27b_ok=0
else
  ok "T27b (B4, DISCRIMINANT) : l'EXCLUSIVITÉ A-4 est mesurée sur les $t27b_scanned .md de doctrine du module — les TROIS cibles nommées (mission-flow.md, mission-contracts.md, vf-dev-manager.md) vérifiées PRÉSENTES dans le balayage —, 9 mutants font rougir l'assertion (question⇒autonome, gel⇒superviser, clause muette, injectés dans CHACUNE des trois), 1 clause correctement qualifiée reste verte"
fi

# ---------------------------------------------------------------------------
# T27c (B5, DISCRIMINANT) — l'exigence d'A-4 mord sur les GRAPHIES de la doctrine, pas sur la seule
# graphie du foyer.
#
# CE QUE CE GATE FERME. B4 a étendu la PORTÉE (3 cibles au lieu d'1). Restait l'autre moitié : la
# RECONNAISSANCE. Les motifs ne connaissaient que la rédaction du foyer — attente au pluriel
# introduite par « aux », gel au verbal (« GELER »), mode en incise (« en mode **autonome**, … »).
# Le renvoi de vf-dev-manager.md, lui, paraphrase A-4 dans ses propres graphies : « superviser : tu
# réponds à l'attente humaine ; autonome : gel du nœud ». AUCUN des trois motifs ne la voyait.
# Échanger ses deux modes — l'inversion exacte qui fait dire à l'agent, en autonomie, l'inverse
# d'ADR-031 — laissait la suite à 93 OK / 0 KO. Troisième foyer, même mode d'échec que B4.
#
# CE QUI EST MESURÉ, et pourquoi par FIXTURES et non sur le fichier réel. La paraphrase elle-même
# est balayée par T27b (elle vit dans une cible du sweep) : si elle s'inverse, T27b rougit. Ici on
# mesure la propriété de l'OUTIL — que les motifs SACHENT lire ces graphies —, et cela doit rester
# vrai quelle que soit l'issue de l'arbitrage ouvert sur ce renvoi (O-1 : paraphrase conservée ou
# réduite à un pointeur nu). Une sonde ancrée sur la paraphrase réelle deviendrait no-op le jour où
# le pointeur nu l'emporte ; une sonde par fixtures reste fondée dans les deux issues, et interdit
# la réintroduction d'une paraphrase inversée.
#
# GARDE « VERT À VIDE ». t27_no_crossed_clause est une garde NÉGATIVE : elle est verte quand la
# doctrine est saine ET quand les motifs ne voient rien. Le compteur ci-dessous distingue les deux —
# sans lui, un motif cassé par une refonte future rendrait TOUT le paragraphe A-4 muet en silence.
# ---------------------------------------------------------------------------
t27c_ok=1
t27c_ko=""

# Compteur d'ATTEINTE : combien de clauses de doctrine les motifs voient-ils réellement ?
t27c_ask_seen=0; t27c_freeze_seen=0
while IFS= read -r t27c_f; do
  [ -n "$t27c_f" ] || continue
  t27c_cl="$(md_blocks_matching "$t27c_f" '.' | t27_clauses)"
  t27c_ask_seen=$((t27c_ask_seen + $(printf '%s\n' "$t27c_cl" | "$GREP" -cE "$T27_ASK_RE")))
  t27c_freeze_seen=$((t27c_freeze_seen + $(printf '%s\n' "$t27c_cl" | "$GREP" -cE "$T27_FREEZE_RE")))
done < <(module_md_targets)
[ "$t27c_ask_seen" -gt 0 ] \
  || t27c_ko="$t27c_ko [ATTEINTE : le motif de QUESTION ne voit AUCUNE clause dans toute la doctrine du module — la garde d'exclusion est verte à vide, elle ne garantit rien]"
[ "$t27c_freeze_seen" -gt 0 ] \
  || t27c_ko="$t27c_ko [ATTEINTE : le motif de GEL ne voit AUCUNE clause dans toute la doctrine du module — la garde d'exclusion est verte à vide, elle ne garantit rien]"

# Fixtures écrites dans la graphie du RENVOI (mode en tête de branche, attente au singulier, gel au
# nominal) — celle qui échappait aux motifs. Injection en FIN de fichier : aucun token retiré,
# aucune ancre existante touchée.
T27C_TMPDIR="$(mktemp -d)"; vf_tmp_track "$T27C_TMPDIR"
T27C_ASK_AUTO="- **Renvoi (clause injectée)** : escalade human_needed départagée par le mode (autonome : tu réponds à l'attente humaine)."
T27C_GEL_SUP="- **Renvoi (clause injectée)** : escalade human_needed départagée par le mode (superviser : gel du nœud, ADR-031)."
T27C_MUETTE="- **Renvoi (clause injectée)** : escalade human_needed — tu réponds à l'attente humaine, puis gel du nœud."
# La paraphrase CORRECTE, dans sa graphie native : elle doit rester VERTE. C'est la contrepartie du
# fil rouge — élargir les motifs sans punir une rédaction licite.
T27C_LICITE="- **Renvoi (clause injectée)** : escalade human_needed départagée par le mode (superviser : tu réponds à l'attente humaine ; autonome : gel du nœud, ADR-031)."

t27c_mut_n=0
t27c_assert_mutant_red() { # <libellé> <fichier cible> <clause injectée>
  local mut
  t27c_mut_n=$((t27c_mut_n + 1))
  mut="$T27C_TMPDIR/mutant-$t27c_mut_n.md"
  { cat "$2"; printf '\n%s\n' "$3"; } > "$mut"
  if cmp -s "$2" "$mut"; then
    t27c_ko="$t27c_ko [$1 : mutant IDENTIQUE à l'original — la clause n'a pas été injectée, rien n'a été mesuré]"
    return
  fi
  t27_no_crossed_clause "$mut" \
    && t27c_ko="$t27c_ko [$1 : NON détecté — la graphie du renvoi échappe encore aux motifs sur cette cible]"
}
for t27c_pair in "mission-flow.md:$MFLOW" "mission-contracts.md:$CONTRACTS_FILE" "vf-dev-manager.md:$DEVMGR"; do
  t27c_name="${t27c_pair%%:*}"; t27c_path="${t27c_pair#*:}"
  if [ ! -f "$t27c_path" ]; then
    t27c_ko="$t27c_ko [$t27c_name introuvable — cible d'A-4 non mesurable]"; continue
  fi
  t27c_assert_mutant_red "$t27c_name : QUESTION en tête de branche « autonome : … »"   "$t27c_path" "$T27C_ASK_AUTO"
  t27c_assert_mutant_red "$t27c_name : GEL NOMINAL en tête de branche « superviser : … »" "$t27c_path" "$T27C_GEL_SUP"
  t27c_assert_mutant_red "$t27c_name : paraphrase MUETTE sur le mode"                   "$t27c_path" "$T27C_MUETTE"
done
T27C_LICIT_FILE="$T27C_TMPDIR/licite-graphie-du-renvoi.md"
{ cat "$MFLOW"; printf '\n%s\n' "$T27C_LICITE"; } > "$T27C_LICIT_FILE"
t27_no_crossed_clause "$T27C_LICIT_FILE" \
  || t27c_ko="$t27c_ko [FAUX ROUGE : la paraphrase CORRECTEMENT qualifiée dans la graphie du renvoi (superviser : question ; autonome : gel) est rejetée — $T27B_WHY]"

if [ -n "$t27c_ko" ]; then
  ko "T27c (B5, DISCRIMINANT) : les motifs d'A-4 restent aveugles aux graphies de la doctrine —$t27c_ko"; t27c_ok=0
else
  ok "T27c (B5, DISCRIMINANT) : les motifs d'A-4 lisent les GRAPHIES du renvoi autant que celles du foyer (attente au singulier introduite par « à l' », gel NOMINAL « gel du nœud », mode annoncé en TÊTE DE BRANCHE « superviser : … ») — $t27c_ask_seen clause(s) de question et $t27c_freeze_seen clause(s) de gel effectivement ATTEINTES dans la doctrine (pas de vert à vide), 9 mutants dans cette graphie font rougir l'assertion sur CHACUNE des trois cibles, 1 paraphrase correctement qualifiée reste verte"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
