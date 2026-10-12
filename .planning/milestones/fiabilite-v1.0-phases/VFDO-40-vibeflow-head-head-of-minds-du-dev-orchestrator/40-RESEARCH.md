# Phase 40: vibeflow-head — head of minds du dev-orchestrator - Research

**Researched:** 2026-09-15
**Domain:** Renommage d'agent + extension de rôle (allocation/séquencement/gouvernance de sortie/économie) dans un plugin Claude Code piloté par GSD — bash, markdown, frontmatter YAML, aucune dépendance externe neuve.
**Confidence:** HIGH — périmètre entièrement in-repo, chaque affirmation ci-dessous est sourcée par lecture directe des fichiers cités cette session (`Read`/`grep`), aucune recherche web n'était nécessaire ni pertinente pour ce domaine.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Seize arbitrages rendus par Samuel le 2026-09-15 (AskUserQuestion, session principale) : quatre à
la conception (spec d'entrée), douze au cadrage. **Verrouillés — ne pas les rouvrir.**

- **D-01 — Périmètre : head dev, dans `dev-orchestrator`.** Pas de tier cross-métier dans le
  conductor. `vibeflow-design` reste un pair invocable. Reversibility: reversible.
- **D-02 — Parallélisme inter-missions : sérialiser.** Un manager à la fois ; le parallélisme reste
  dans la frontière `ready` du manager. La voie workstreams est documentée comme extension dans
  `head-governance.md`, jamais livrée ici. Reversibility: reversible.
- **D-03 — Gate de sortie sur témoin machine, rejouer seulement l'absent.** Un vert du manager est
  accepté s'il porte une preuve machine ; le head ne rejoue qu'un gate dont la preuve manque,
  jamais un étage, jamais la revue.
- **D-04 — Nom : `vibeflow-head`.** Convention des front doors (`vibeflow-conductor`,
  `vibeflow-design`, `vibeflow-validator`). Reversibility: costly — 20 fichiers dans `plugin/` +
  2 README + gates (`check-overlaps.sh`, tests) portent le nom.
- **D-05 — Preuves E6 en bloc typé dans le rapport compact.** Chaque verdict du rapport de mission
  porte `{commande, exit_code, sha}`. Un verdict sans commande rejouable (hook moteur GSD relayé
  verbatim) est marqué `preuve: amont` et n'est jamais rejoué. Reversibility: costly.
- **D-06 — Contrôle sans source de vérité = indéterminé, mission non prouvée.** Pas de `gh`, pas de
  remote, lab racine non-git : le contrôle rend **4** et le verdict global est **4**.
- **D-07 — Contrôles du gate** (repris de la spec §3.3, confirmés) : E1 verrou relâché
  (`driver-lock.sh status` → `present:false`) ; E2 arbre propre hors artefacts gitignorés
  (`git status --porcelain`, mesuré en `rtk proxy`) ; E3 branche dédiée ≠ défaut + PR ouverte
  (ADR-059) ; E4 STATE/ROADMAP marqués pour les étapes de la mission ; E5 rapport détaillé présent
  sur disque ; E6 chaque verdict porte sa preuve. Codes : **3 sain**, **0 manque(s) nommé(s)**,
  **4 indéterminé**, **64 outillage illisible**. Le script naît avec sa suite de tests et sa
  **mutation rouge prouvée** (QUAL-01).
- **D-08 — Portée : missions d'équipe seulement.** Le gate ne tourne qu'après un manager — le lock
  et le rapport typé sont ses sources. `gsd-execute-phase` direct et `gsd-quick` gardent leurs
  vérifications GSD propres. Pas de mode dégradé du script.
- **D-09 — Déclenchement d'un manager : propose en conversation, lance d'office sous `vf-auto`.**
  Sur signal mission le head propose `Task(manager)` et attend le feu vert ; sous `vf-auto` ou
  signal de durée explicite il dispatche sans redemander. Heuristique 7 conservée, ADR-031 intact.
- **D-10 — Exécutant du gate : le head lui-même.** `check-mission-exit.sh` et un gate rejoué sont
  lancés par le head via Bash — une lecture, pas une production (P3 respecté).
- **D-11 — Lock encore tenu après le rapport (E1 rouge) : mandat de clôture au manager, puis
  `human_needed`.** Le head ne relâche ni ne reprend jamais un lock.
- **D-12 — Gate rejoué = la commande exacte que le verdict devait porter.** Le contrat E6 nomme,
  par type de verdict, la commande canonique. Le head rejoue celle-là, jamais une liste locale ni
  le job `gates` complet de `ci.yml`.
- **D-13 — Décompte de coût dans le rapport de mission existant.** Trois lignes ajoutées au
  gabarit (`mission-contracts.md` §Rapport de mission) et au rapport compact : minds dispatchés,
  tours consommés, gates rejoués. Aucun fichier neuf, aucune statistique agrégée.
- **D-14 — Preuves manquantes : 1 → rejouer ; ≥ 2 → source fautive, mandat de clôture.**
- **D-15 — Trois règles d'économie** (spec §3.4, confirmées) : ne jamais relire ce que le digest
  porte ; ne jamais rejuger un diff sans nouveau commit ; relayer verbatim, jamais recalculer.
  Bornes dures inchangées : `autonomous-guardrails.md`.
- **D-16 — Une seule PR, une release minor, après la Phase 34.** Bump minor du module
  `dev-orchestrator` et de la racine ; tag + release GitHub + `check-release-tag.sh --remote` ✓.
  Reversibility: one-way.
- **D-17 — Le skill `vf-dev` garde son nom** et incarne `vibeflow-head`. Pas d'alias `vf-head`.
- **D-18 — Multi-runtime : livré par construction, sans mesure neuve.**

### Claude's Discretion

- **Famille d'exigences** : `HEAD-01` (échelle d'allocation), `HEAD-02` (gate de sortie),
  `HEAD-03` (économie), `HEAD-04` (renommage sans alias) — préfixe vérifié libre au ledger le
  2026-09-15 [VERIFIED: .planning/REQUIREMENTS.md, grep exhaustif des 44 préfixes existants — voir
  §Vérification ci-dessous] ; à ledgeriser au plan avec la table de traçabilité `HEAD-xx → Phase 40`.
  QUAL-01 s'applique de plein droit (un gate naît).
- **Forme du test anti-alias** : grep récursif sur `plugin/` excluant `CHANGELOG.md`, dans
  `test-dev-orchestrator.sh` (module propriétaire du nom) — et mutation rouge (réinjecter un
  alias, vérifier l'échec). Les six specs historiques sous `docs/superpowers/specs/` et
  `docs/ADR.md` sont des archives datées : non réécrites, hors périmètre du test.
- **Découpage de l'AGENT.md** : quelles lignes migrent vers `head-governance.md` pour tenir
  ≤ 250 lignes après ajout de la section « Gouvernance de sortie » (renvoi) — candidat naturel :
  la table « Carte d'intention » raccourcie au profit d'`intent-routing.md`, déjà source unique.
- **Ordre des lots dans le plan** : renommage (mécanique, vérifiable par le test anti-alias) puis
  contrat E6 côté manager, puis gate (qui consomme E6), puis référence + AGENT.md — ou l'inverse.
  Les quatre lots ont des périmètres de fichiers disjoints sauf `vf-dev-manager.md` (E6) et
  `mission-contracts.md` (E6 + décompte).
- **Note pour la Phase 34** (hors périmètre, à porter, pas à faire ici) : précision de rédaction du
  Pitfall 12 — pas une révision de D-03 de la 34.

### Deferred Ideas (OUT OF SCOPE)

- **Head cross-métier dans le conductor** — écarté (D-01) ; `head-governance.md` est écrit pour
  être déplaçable.
- **Un manager par workstream** (verrou nommé par compartiment, amendement d'ADR-053, guard
  aligné, `--ws` + `GSD_SESSION_KEY` par manager, preuve d'usage concurrent réel) — phase à part
  entière, déclencheur : partition effective d'un lab (elle-même gatée humain, D-02 de la 39).
- **Mesure d'incarnation de `vibeflow-head` sur Codex** — écartée (D-18) ; quota ChatGPT
  indisponible jusqu'au 2026-09-27.
- **Registre de coût inter-missions** (`COST-LEDGER.md`) — écarté (D-13).
- **Précision de rédaction du Pitfall 12 dans AGTS-01** — appartient à la Phase 34.

</user_constraints>

<phase_requirements>
## Phase Requirements

Aucun ID n'est encore gravé au ledger — CONTEXT.md laisse la famille `HEAD-xx` au « Claude's
Discretion » du planner, à ledgeriser au plan. Le préfixe est **confirmé libre** [VERIFIED:
.planning/REQUIREMENTS.md, `grep -oE '\*\*[A-Z]+-[0-9]+\*\*' .planning/REQUIREMENTS.md` — 44
préfixes existants, `HEAD` absent ; `grep -n "HEAD-" .planning/REQUIREMENTS.md` — 0 correspondance]
(voir §Vérification ci-dessous).

| ID candidat | Description | Research Support |
|----|-------------|------------------|
| HEAD-01 | Échelle d'allocation à sens unique (quick/debug/execute/manager), documentée dans `head-governance.md` §Règle d'échelle, sans dupliquer `intent-routing.md` | §Architecture Patterns, §Code Examples (table de proportionnalité extraite de la spec §3.1) |
| HEAD-02 | Gate de sortie `check-mission-exit.sh` (E1-E6, codes 3/0/4/64) + suite de tests + mutation rouge | §Code Examples (patron exact de `check-mission-invariants.sh`, format JSON `driver-lock.sh status`, cascade `$S`) |
| HEAD-03 | Économie : décompte par mission (minds/tours/gates rejoués) en 3 lignes du rapport, contrat E6 dans le bloc typé Pattern C | §Code Examples (contrat `estimate:`/`actuals:` comme patron direct, bloc Pattern C) |
| HEAD-04 | Renommage sans alias survivant — 20 fichiers `plugin/` (hors CHANGELOG) + 2 README, test anti-alias avec mutation rouge | §Runtime State Inventory (surface mesurée, ré-vérifiée), §Common Pitfalls |

</phase_requirements>

## Summary

Cette phase ne touche à aucune dépendance externe : c'est un renommage d'agent (`vibeflow-dev` →
`vibeflow-head`) accompagné d'une extension de rôle documentée dans une nouvelle référence
on-demand et d'un gate shell neuf. Toute la recherche utile consiste à **relire le code existant
que le nouveau gate doit imiter** (`check-mission-invariants.sh`, `driver-lock.sh status`,
cascade `$S` de `mission-flow.md`, bloc typé Pattern C, contrat `estimate:`/`actuals:`) et à
**re-mesurer la surface de renommage** annoncée par l'orchestrateur — les deux se confirment à
l'identique cette session, avec une correction : le fichier `plugin/planning-core/references/
gsd-handoff.md` (3 occurrences de `vibeflow-dev`) est bien touché par le renommage mais **absent**
de la section `<canonical_refs>` de `40-CONTEXT.md` (« Autres citations du nom ») — à ajouter
explicitement dans le plan pour ne pas laisser un alias résiduel après le lot de renommage.

**Primary recommendation:** Faire naître `check-mission-exit.sh` en copiant strictement le squelette
de `check-mission-invariants.sh` (mêmes conventions bash, mêmes codes 3/0/4/64, même style de
message `[nom-du-gate]`, même durcissement git `GIT_CONFIG_NOSYSTEM`/`GIT_TERMINAL_PROMPT`/
`GIT_OPTIONAL_LOCKS`), résoudre ses propres scripts frères via la cascade `$S` déjà documentée dans
`mission-flow.md` (jamais un chemin en dur), et traiter le renommage comme un lot strictement
mécanique borné par le test anti-alias — les 4 lots du plan ont des périmètres de fichiers
disjoints sauf `vf-dev-manager.md` et `mission-contracts.md`, qui portent tous deux le contrat E6.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Allocation d'équipe (quick/debug/execute/manager) | Agent routeur (`vibeflow-head`, front door conversationnelle) | Référence on-demand (`head-governance.md`) | L'agent détecte et décide en conversation (≤250L), la règle d'échelle détaillée vit dans la référence (ADR-030, une seule voix) |
| Séquencement des missions | Agent routeur (lecture `ROADMAP.md` `Depends on:`) | — | Fait de lecture, aucun mécanisme machine neuf ; le kernel (DAG) reste au niveau nœud, pas mission |
| Gouvernance de sortie (E1-E6) | Script shell (`check-mission-exit.sh`, exécuté par le head via Bash) | Sources de vérité : `driver-lock.sh status`, `git status --porcelain`, `gh pr view`, `ROADMAP.md`/`STATE.md`, rapport compact du manager | Contrôle déterministe et bon marché, jamais un rejugement de contenu — P3 (un orchestrateur ne produit pas) |
| Décompte de coût | Rapport de mission (gabarit `mission-contracts.md`) | Bloc typé Pattern C du manager (`vf-coder`/`vf-dev-manager`) | Relayé verbatim, jamais recalculé — même contrat que `estimate:`/`actuals:` |
| Dispatch de manager | Agent routeur → `Task(vf-dev-manager)` / `Task(vf-design-manager)` | Team-kernel (`team-kernel.md`, inchangé) | Le head décide QUAND et LEQUEL ; le kernel gère COMMENT une fois dispatché (lock, DAG, rapports typés) |
| Lock de driver | Team-kernel (`driver-lock.sh`, **non modifié**) | — | Hors périmètre de la phase (kernel intact, D-01/D-02 du cadrage) |

## Standard Stack

Aucune dépendance externe neuve. Stack déjà en place, réutilisée telle quelle :

### Core
| Outil | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | POSIX-compatible, testé macOS+Linux (Phase 30) | Le gate `check-mission-exit.sh` et sa suite de tests | Tous les gates du repo (`check-mission-invariants.sh`, `check-overlaps.sh`, `check-doc-drift.sh`…) sont en bash pur, portabilité déjà prouvée |
| jq | présent sur les runners CI (`.github/workflows/ci.yml` l.30 : `jq --version`) [VERIFIED: .github/workflows/ci.yml:27-30] | Lire les champs `present`/`generation`/`stale` du JSON de `driver-lock.sh status` | Convention explicite du repo — « lire par `jq`, jamais par découpage de texte » (40-CONTEXT.md canonical_refs) |
| git | — | E2 (arbre propre), E3 (branche dédiée) | Déjà l'outil de toutes les vérifications d'état du repo |
| gh (GitHub CLI) | optionnel | E3 (PR ouverte) — repli documenté si absent (D-07, D-06 : indéterminé → code 4) | Cohérent avec `mission-contracts.md` §Isolation de branche (repli déjà écrit pour « gh absent ou non authentifié ») |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Copier le squelette de `check-mission-invariants.sh` | Écrire le gate from scratch | Rejeté : le repo a une convention de codes de sortie éprouvée (3/0/4/64) et un style de message `[nom-du-gate]` — diverger romprait la cohérence inter-gates et le principe « une preuve doit pouvoir rendre rouge » déjà validé par mutation sur ce patron |

**Installation:** Aucune — tous les outils sont déjà des prérequis du repo (bash/jq/git/gh
documentés dans `.github/workflows/ci.yml` et `mission-contracts.md`).

**Version verification:** Sans objet — pas de package à installer, pas de registre à interroger.

## Package Legitimacy Audit

**Sans objet.** Cette phase n'installe aucun package externe (npm/PyPI/crates ou autre) — aucun
`require`, aucun `import` neuf, aucune entrée `requires[]` de `module.json` à ajouter. Le seul
artefact neuf est un script bash (`check-mission-exit.sh`) + une référence markdown
(`head-governance.md`), tous deux écrits en interne. Le protocole de légitimité de package ne
s'applique pas ; aucune ligne de ce tableau n'est produite.

## Architecture Patterns

### System Architecture Diagram

```
Utilisateur (langage naturel)
        │
        ▼
┌───────────────────────────────┐
│  vibeflow-head (AGENT.md)     │  ← renommé depuis vibeflow-dev (D-04)
│  - détecte l'intention        │
│  - lit ROADMAP.md Depends on: │  ← "séquencement" (§3.2 spec)
│  - choisit le niveau d'équipe │  ← "allocation" (§3.1 spec, échelle sens unique)
└───────────────┬───────────────┘
                │ décide QUOI lancer, dans quel ordre
                ▼
   ┌────────────┴─────────────┬──────────────┬───────────────┐
   ▼                          ▼              ▼               ▼
gsd-quick /            gsd-execute-phase   Task(          Task(
gsd-debug              (N=1, direct)       vf-dev-manager) vf-design-manager)
   │                          │              │               │
   │                          │              ▼               ▼
   │                          │        ┌─────────────────────────┐
   │                          │        │  team-kernel (INTACT)    │
   │                          │        │  - driver-lock.sh        │
   │                          │        │  - dag.sh (frontière     │
   │                          │        │    ready/blocked)        │
   │                          │        │  - Pattern C (rapport    │
   │                          │        │    typé worker)          │
   │                          │        └────────────┬─────────────┘
   │                          │                      │ rapport compact
   │                          │                      │ + preuves E6 (D-05)
   ▼                          ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Gouvernance de sortie — vibeflow-head exécute lui-même      │
│  (D-10, une lecture, pas une production — P3)                │
│                                                                │
│  check-mission-exit.sh  (résolu via cascade $S)               │
│  ├─ E1 driver-lock.sh status → present:false                  │
│  ├─ E2 git status --porcelain (hors gitignorés)                │
│  ├─ E3 branche dédiée + PR ouverte (gh pr view, repli si absent)│
│  ├─ E4 STATE/ROADMAP marqués                                   │
│  ├─ E5 rapport détaillé présent sur disque                     │
│  └─ E6 chaque verdict du rapport porte {commande, exit_code, sha}│
│        → E6 absent pour UN verdict = CE gate-là rejoué SEUL    │
│          (jamais toute la suite, jamais la revue — D-03/D-12)  │
└───────────────┬────────────────────────────────────────────────┘
                │ code de sortie
                ▼
   3 sain → enchaîne   0 manque(s) → mandat clôture ciblée au manager
   4 indéterminé → mission non annoncée verte   64 → human_needed
```

### Recommended Project Structure

Aucun nouveau dossier — extension d'un module existant :

```
plugin/dev-orchestrator/
├── AGENT.md                              # name: vibeflow-head (renommé), section "Gouvernance
│                                          #   de sortie" ajoutée en renvoi (≤250L après découpage)
├── module.json, README.md, CHANGELOG.md, VERSION   # bump minor (D-16)
├── agents/
│   └── vf-dev-manager.md                 # "Dispatché par l'agent vibeflow-head" ; rapport
│                                          #   compact enrichi des preuves E6
├── references/
│   ├── _index.md                         # + 1 ligne pour head-governance.md (10 → 11 entrées)
│   ├── head-governance.md                # NOUVEAU — règle d'échelle, séquencement, contrat de
│   │                                      #   sortie, économie (on-demand)
│   ├── intent-routing.md                 # inchangé dans son rôle de source unique — cité,
│   │                                      #   jamais dupliqué (mentions vibeflow-dev à renommer)
│   ├── mission-contracts.md              # §Rapport de mission enrichi (E6 + décompte 3 lignes)
│   ├── mission-flow.md                   # inchangé — Pattern C reste le foyer unique du bloc typé
│   ├── GSD-PIPELINE.md, docs-flow.md, ingestion-flow.md   # mentions à renommer
│   └── gsd-handoff.md                    # ⚠ vit en fait sous plugin/planning-core/references/,
│                                          #   PAS ici — voir §Common Pitfalls
├── scripts/
│   ├── check-mission-exit.sh             # NOUVEAU — gate de sortie E1-E6
│   ├── discover-unintegrated-docs.sh     # mention à renommer (l.6)
│   └── tests/
│       ├── test-dev-orchestrator.sh      # l.1298 cible d'incarnation à renommer + nouveau test
│       │                                 #   anti-alias (grep récursif plugin/, hors CHANGELOG.md)
│       └── test-check-mission-exit.sh    # NOUVEAU — suite du gate, mutation rouge (auto-découverte
│                                         #   CI, aucun câblage manuel requis)
└── skills/
    ├── vf-dev/SKILL.md                   # incarne vibeflow-head (D-17, nom du skill inchangé)
    └── vf-auto/SKILL.md                  # cite la règle d'échelle au lieu de la dupliquer

plugin/planning-core/
├── SKILL.md                              # l.3, l.81 — mention à renommer
└── references/gsd-handoff.md             # l.31, l.35, l.43 — mention à renommer (⚠ omis du
                                           #   40-CONTEXT.md canonical_refs, voir Pitfalls)

plugin/design-orchestrator/AGENT.md       # l.3 — mention à renommer
plugin/commands/vf-planning.md            # l.15, l.18 — mention à renommer
plugin/software-architecture/rules/doc-research-before-debug.md   # l.24, l.88 — mention à renommer
plugin/conductor/scripts/check-overlaps.sh                # l.67 — ligne "vibeflow-dev|gsd-next"
plugin/conductor/scripts/tests/test-check-overlaps.sh      # l.186-203 (T15/T16) — fixtures à renommer

README.md, README.fr.md                   # 1 occurrence chacun (l.46) — à renommer
```

### Pattern 1: Gate de sortie sur le patron `check-mission-invariants.sh`

**What:** Le script `check-mission-exit.sh` doit reproduire EXACTEMENT la structure d'un gate
existant du repo plutôt qu'inventer une nouvelle convention.

**When to use:** Toute création de gate shell dans ce repo (leçon transverse, pas spécifique à
cette phase).

**Squelette extrait tel quel de `check-mission-invariants.sh`** [VERIFIED:
plugin/conductor/scripts/check-mission-invariants.sh:57-118 — quote verbatim ci-dessous] :

```bash
# Source: plugin/conductor/scripts/check-mission-invariants.sh:57-118 (lu intégralement cette session)
set -uo pipefail
shopt -s nullglob

ROOT="."
# ... parsing d'arguments avec exit 64 sur toute forme malformée :
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-invariants] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    # ...
    *) echo "[check-mission-invariants] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[check-mission-invariants] $*" >&2; }

# --- Durcissement git (motif écrit une seule fois, réutilisé par tous les gates du repo) ---
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() {
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}
```

**Codes de sortie du modèle** [VERIFIED: plugin/conductor/scripts/check-mission-invariants.sh:33-43
— quote verbatim] :

```
#   0  = au moins une zone morte détectée — signal [mission-invariants] émis, une ligne par zone
#   3  = SAIN — ... C'est le SEUL code qui signifie « vérifié, conforme »
#   4  = INDÉTERMINÉ — rien n'a été vérifié ... précisant laquelle (diagnostic sur stderr)
#   64 = argument inconnu, --path/--file sans valeur, --hook + --quiet ensemble, ou fichier
#        EXPLICITEMENT désigné par --file et illisible
```

`check-mission-exit.sh` réutilise **exactement** ces 4 codes (3 sain / 0 manque(s) nommé(s) / 4
indéterminé / 64 outillage illisible — D-07 le confirme mot pour mot) et le style de message
`[nom-du-gate] …` sur stderr, avec le même durcissement git.

### Pattern 2: Résolution des scripts frères — cascade `$S`

**What:** Le gate ne doit jamais coder en dur un chemin vers `driver-lock.sh` ou tout autre script
frère — il réutilise la cascade déjà documentée pour tous les scripts de mission.

**Exact tel que lu** [VERIFIED: plugin/dev-orchestrator/references/mission-flow.md:14-19 — quote
verbatim] :

```bash
# Source: plugin/dev-orchestrator/references/mission-flow.md:17-18
S="$( for d in "./.claude/scripts" "$HOME/.claude/scripts" "${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts" "${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts"; do
        [ -f "$d/dag.sh" ] && { printf '%s' "$d"; break; }; done )"
```

Note : la cascade teste la présence de `dag.sh` comme sentinelle de dossier valide (pas
`driver-lock.sh` ni un autre fichier) — `check-mission-exit.sh` doit chercher la même sentinelle
pour rester cohérent avec toute invocation ultérieure dans le même mandat. Le lab courant PRIME
(`./.claude/scripts` d'abord) — sur une machine bi-scope, ne jamais préférer le scope user par
défaut [VERIFIED: mission-flow.md:21-24, quote verbatim : « Le lab courant PRIME […] sur une
machine bi-scope (user + projet), préférer le scope user ferait tourner la mission avec des
scripts d'une autre version que celle du lab, silencieusement »].

### Pattern 3: Format JSON de `driver-lock.sh status` (source d'E1)

**What:** E1 doit lire `present` (et `generation` si besoin) depuis le JSON une-ligne rendu par
`driver-lock.sh status`, jamais par découpage de texte (convention explicite du repo).

**Format exact** [VERIFIED: plugin/conductor/scripts/driver-lock.sh:322-347 — quote verbatim des
deux formats de sortie] :

```bash
# Source: plugin/conductor/scripts/driver-lock.sh:322-325 (lock absent)
json_status() {
  if [ "$1" = false ]; then
    printf '{"present": false, "lock": "%s"}\n' "$LOCK_DIR"; return
  fi
  # ...
```

```bash
# Source: plugin/conductor/scripts/driver-lock.sh:345-346 (lock présent — champ complet)
printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s, "generation": "%s", "session_ids": %s, "lease_seconds": %s, "guard_effective": %s, "progress_epoch": %s, "progress_age_seconds": %s}\n' \
    "$o" "$s" "$age" "$TTL" "$stale" "$gen" "$sids" "$lease" "$guard_eff" "$pe" "$page"
```

Lecture recommandée par `jq` :

```bash
present="$("$S"/driver-lock.sh status | jq -r '.present')"
# E1 sain ⟺ present == "false"
```

Le champ `generation` existe (`.generation`, chaîne) — utile si un lot ultérieur veut comparer un
jeton de fence, mais **hors du périmètre d'E1** qui ne teste que `present`.

### Pattern 4: Bloc typé Pattern C — où E6 s'insère

**What:** Le bloc E6 (`{commande, exit_code, sha}`) s'ajoute **par verdict** à l'intérieur du bloc
typé existant, il ne crée pas un second format.

**Format exact du contrat Pattern C actuel** [VERIFIED:
plugin/dev-orchestrator/references/mission-flow.md:220-228 — quote verbatim] :

```json
{
  "statut": "passed | gaps_found | human_needed | blocked",
  "findings": [
    { "severity": "bloquant | majeur | mineur", "action": "auto-fix | no-op | ask-user", "ref": "fichier:ligne" }
  ],
  "noeuds_debloques": ["<id de nœud DAG à passer done, s'il y a lieu>"]
}
```

Le contrat `estimate:`/`actuals:` (§Pattern 5 ci-dessous) est déjà venu s'ajouter à ce même bloc
comme deux champs **optionnels frères** de `statut`/`findings`/`noeuds_debloques` — c'est le patron
exact qu'E6 doit suivre : `"preuves": [{ "verdict": "recette|revue|audit|gate:<nom>", "commande":
"…", "exit_code": N, "sha": "…" }]` (ou équivalent), présent uniquement pour les verdicts qui
portent une commande rejouable ; absent/`"preuve": "amont"` pour un hook moteur GSD relayé verbatim
(D-05).

### Pattern 5: Contrat `estimate:`/`actuals:` — modèle direct pour E6 et le décompte

**What:** Le patron exact que HEAD-02 (E6) et HEAD-03 (décompte) doivent suivre existe déjà dans
`mission-contracts.md` pour un problème structurellement identique (relayer une preuve produite en
amont, jamais la recalculer).

**Texte exact** [VERIFIED: plugin/dev-orchestrator/references/mission-contracts.md:151-180 — quote
verbatim des passages clés] :

```
# Source: mission-contracts.md:154-158 — les 3 règles non négociables
- «confidence» est DÉRIVÉE du nombre d'échantillons, jamais auto-évaluée
- Même échelle des deux côtés : «actuals.tokens» se mesure en chars/4 sur les fichiers
  réellement changés, jamais un compteur du harness
- Aucun arrondi flatteur

# Source: mission-contracts.md:171-176 — la propagation retenue (deux champs optionnels)
"estimate": { "tokens": …, "raw_tokens": …, "tasks": …, "confidence": "low|med|high" },
"actuals":  { "tokens": …, "tasks": …, "commits": … }
```

Et le relais côté manager [VERIFIED: plugin/dev-orchestrator/agents/vf-dev-manager.md:243-247 —
quote verbatim] :

```
# Source: vf-dev-manager.md:243-247
Quand le bloc typé d'un vf-coder porte estimate/actuals, relaie-les VERBATIM dans la ligne
« Calibration » du gabarit — simple concaténation par sprint, jamais un recalcul ni une
statistique agrégée de ton cru. Même règle pour «verdicts» […] : concaténation par sprint,
jamais agrégés.
```

Et le gabarit « Rapport de mission » lui-même [VERIFIED:
plugin/dev-orchestrator/references/mission-contracts.md — section « Rapport de mission », quote
verbatim] :

```
RAPPORT DE MISSION
- Verdict global : ✅ | partiel | bloqué
- Par sprint : fait / verdicts (recette, revue, audit + hooks moteur relayés verbatim) / commits (SHA)
- Calibration (si portée) : estimate vs actuals par sprint — recopiés verbatim, jamais recalculés
- Décisions prises en autonomie (et par quel panel)
- Blocages & points nécessitant l'utilisateur
- Décompte (si bloqué) : tours consommés par boucle + findings non résolus — recopié verbatim, jamais recalculé
- Rapport détaillé : <chemin du fichier écrit sur disque>
```

**Recommandation directe pour HEAD-03** : ajouter trois lignes à ce même gabarit (« Décompte
(mission) : N minds dispatchés / N tours consommés / N gates rejoués (E6) »), au même niveau que la
ligne « Décompte (si bloqué) » déjà présente — jamais un fichier séparé (D-13 le dit explicitement,
« aucun fichier neuf »).

### Anti-Patterns to Avoid

- **Réinventer une convention de codes de sortie** : le repo a une convention 3/0/4/64 éprouvée sur
  plusieurs gates (`check-mission-invariants.sh`, `check-doc-drift.sh`, `check-gsd-engine.sh`) —
  s'en écarter casserait la lisibilité inter-gates que D-07 réclame explicitement.
- **Chemin en dur vers `driver-lock.sh`** : toujours passer par la cascade `$S` — un lab installé en
  scope `user` n'a pas de `./.claude/scripts`.
- **Rejouer tout un étage au lieu du seul gate sans preuve** : contredit D-03/D-12 au mot près
  (« jamais un étage, jamais la revue »).
- **Créer un second format de bloc typé pour E6** : Pattern C est le foyer unique — l'ajouter
  ailleurs romprait « ADR-030, une seule voix » citée explicitement pour ce contrat.
- **Un vérificateur qui ne peut jamais rendre rouge** : leçon nommée du repo (« une preuve doit
  pouvoir rendre rouge », incident Phase 39) — `check-mission-exit.sh` DOIT naître avec sa mutation
  rouge prouvée (QUAL-01), pas seulement des tests qui passent sur l'état sain.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lire l'état du lock de driver | Un parsing texte du fichier de lock | `driver-lock.sh status \| jq -r '.present'` | Format JSON déjà stable, testé, et la convention du repo l'exige explicitement (canonical_refs : « lire par jq, jamais par découpage de texte ») |
| Détecter une PR ouverte | Appeler l'API GitHub à la main | `gh pr view` avec repli documenté si `gh` absent | `mission-contracts.md` a déjà le patron de repli exact pour ce cas (§Isolation de branche) |
| Mesurer un arbre sale | `git status` brut piped dans `wc -l` | `git status --porcelain`, **mesuré en `rtk proxy`** | Leçon nommée du repo (mémoire `rtk-fausse-les-verifications-d-etat.md`, Phase 18, 2026-08-18) : une sortie vide de `rtk` rend 1 ligne, pas 0 — `wc -l` sous rtk ment |
| Router intention → brique | Une nouvelle table dans `head-governance.md` | `intent-routing.md` (source unique, citée, pas dupliquée) | ADR-030 (une seule voix) — le head y ajoute SEULEMENT la règle d'échelle, jamais la correspondance elle-même |
| Décompte de coût par mission | Un fichier `COST-LEDGER.md` agrégé | 3 lignes dans le gabarit de rapport existant (`mission-contracts.md` §Rapport de mission) | Explicitement écarté au cadrage (D-13, §Deferred Ideas) : « à rouvrir seulement si une comparaison entre missions devient un besoin prouvé » |

**Key insight:** Cette phase n'a structurellement rien à hand-roller de neuf — sa seule vraie
matière neuve (le gate `check-mission-exit.sh`) est un décalque volontaire d'un gate existant, et
son contrat de preuves (E6) est un décalque volontaire du contrat `estimate:`/`actuals:` déjà en
production. Le risque n'est pas l'invention, c'est la **divergence de convention** — un gate qui a
« l'air correct » mais utilise des codes de sortie différents casserait la lisibilité que le repo a
mis plusieurs phases à établir (QUAL-01 transverse depuis la Phase 30).

## Runtime State Inventory

> Déclenché : phase de renommage (`vibeflow-dev` → `vibeflow-head`, D-04).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Aucune base de données ni datastore ne stocke `vibeflow-dev` comme clé/ID [VERIFIED: grep exhaustif — voir Vérification]. Les seuls fichiers `.planning/*.dag.json` et `.planning/missions/*.md` qui citent la chaîne sont soit des archives datées (missions de la Phase 13/17, non réécrites, patron déjà établi pour les archives), soit un DAG de mission **éphémère et non versionné** (`MISSION-40.dag.json`, `??` au `git status` — session-local, hors périmètre). | Aucune migration de données requise. |
| Live service config | Aucun service externe (n8n, Datadog, Tailscale…) ne référence `vibeflow-dev` — ce repo n'a aucun service de ce type. | Sans objet. |
| OS-registered state | Aucun (pas de Task Scheduler, pas de pm2, pas de launchd/systemd portant ce nom). | Sans objet. |
| Secrets/env vars | Aucun secret ni variable d'environnement ne référence `vibeflow-dev` par nom. | Sans objet. |
| Build artifacts / installed packages | **Trouvé et significatif** : sur un poste déjà équipé de VibeFlow (ex. le poste de Samuel), le fichier **installé** `~/.claude/agents/dev-orchestrator.md` porte encore `name: vibeflow-dev` dans son frontmatter [VERIFIED: `cat ~/.claude/agents/dev-orchestrator.md \| head -5` exécuté cette session, sortie : `name: vibeflow-dev` / `description: Expert dev senior…`]. Le renommage du **source** (`plugin/dev-orchestrator/AGENT.md` dans ce repo) ne met PAS à jour ce fichier installé — c'est `vibeflow-update.sh` qui pose `AGENT.md` sous `$TARGET_ROOT/agents/<module>.md` à l'`install`/`update` [VERIFIED: plugin/_internal/vibeflow-update.sh:2233-2237, quote verbatim : « Type 3 — Agent module : AGENT.md → $TARGET_ROOT/agents/<mod>.md … vf_place_file "$module_dir/AGENT.md" "$TARGET_ROOT/agents/${mod}.md" »]. Le fichier installé reste nommé `dev-orchestrator.md` (aucun renommage de fichier), seul son **contenu** (`name:` du frontmatter) change — et seulement après un `/vf-update` réel sur le poste cible. **Zéro changement d'engine requis** — confirmé par lecture directe des lignes citées par 40-CONTEXT.md. | Documenter dans le PLAN (ou le rapport de release) que ce renommage n'atteint aucun poste déjà équipé sans un `/vf-update` explicite — patron déjà connu du repo (mémoire `remediation-perime-2026-07-26.md` : « get-shit-done-cc → @opengsd/gsd-core livrée en v2.39.0 n'atteint AUCUN poste déjà équipé »). Aucune action dans CE plan au-delà de la documentation — le geste `/vf-update` est un geste utilisateur séparé, hors périmètre (D-18 : « livré par construction »). |

**Nothing found in category** : Stored data / Live service config / OS-registered state / Secrets —
vérifiées explicitement ci-dessus, toutes vides pour ce repo.

## Common Pitfalls

### Pitfall 1: `plugin/planning-core/references/gsd-handoff.md` — absent de la liste canonique de 40-CONTEXT.md

**What goes wrong:** Le plan s'appuie sur la section `<canonical_refs>` §« Autres citations du
nom » de `40-CONTEXT.md` pour la liste exhaustive des fichiers à renommer, mais ce fichier précis
n'y figure PAS.

**Why it happens:** `40-CONTEXT.md` liste `plugin/planning-core/SKILL.md` (l.3, l.81) mais omet
`plugin/planning-core/references/gsd-handoff.md`, qui porte pourtant **3 occurrences** de
`vibeflow-dev` [VERIFIED: `grep -n "vibeflow-dev" plugin/planning-core/references/gsd-handoff.md`
exécuté cette session — sortie exacte : l.31 « … via l'agent \`vibeflow-dev\` qui détecte
l'intention). », l.35 « … `gsd-new-project` (garde-fou first-use de l'agent \`vibeflow-dev\`) | »,
l.43 « l'agent \`vibeflow-dev\` tranche via la carte canonique »]. Confirmé aussi côté brief de
l'orchestrateur (qui le signale explicitement comme « OMIS du 40-CONTEXT.md canonical_refs »).

**How to avoid:** Le lot de renommage doit inclure ce fichier explicitement dans sa liste de
cibles, au même titre que `planning-core/SKILL.md` — sinon le test anti-alias (grep récursif sur
`plugin/`, hors CHANGELOG.md) le détectera et fera échouer le gate, ce qui est le comportement
correct (le test protège contre exactement cet oubli) mais retardera le lot si l'omission n'est pas
anticipée au plan.

**Warning signs:** Le test anti-alias de `test-dev-orchestrator.sh` rend rouge après le lot de
renommage « terminé » — signe que la surface mesurée par le plan était incomplète.

### Pitfall 2: `_index.md` ne référence pas encore `head-governance.md`

**What goes wrong:** Le nouveau fichier `head-governance.md` est créé sous
`plugin/dev-orchestrator/references/` mais l'index qui liste les 10 fichiers de ce dossier
[VERIFIED: plugin/dev-orchestrator/references/_index.md:9-19, lu intégralement — 10 entrées de
table, aucune ligne `head-governance.md`] n'est pas mis à jour automatiquement.

**Why it happens:** `_index.md` est un fichier statique, maintenu à la main (« Cet index doit
rester cohérent avec le contenu du dossier », l.21).

**How to avoid:** Le lot qui crée `head-governance.md` ajoute aussi sa ligne dans `_index.md` (au
même gabarit que les 10 lignes existantes : `[head-governance.md](head-governance.md) | <résumé>`).

**Warning signs:** Aucun gate machine ne vérifie cette cohérence — le risque est silencieux, pas
un gate qui échouerait.

### Pitfall 3: Confondre le lock-release du manager avec un geste du head

**What goes wrong:** Un plan pourrait, par erreur, faire écrire au gate `check-mission-exit.sh` un
`driver-lock.sh release` si E1 est rouge — ce qui violerait D-11 au mot près (« Le head **ne
relâche ni ne reprend jamais** un lock »).

**Why it happens:** Le point de release existant est déjà dans `vf-dev-manager.md`, juste avant le
rapport [VERIFIED: plugin/dev-orchestrator/agents/vf-dev-manager.md:249, quote verbatim :
« **Avant de rendre le rapport, relâche le verrou de driver** » — puis l.250 : la commande
`"$S"/driver-lock.sh release --owner=<id>` (geste de clôture garanti…) »]. Un plan naïf pourrait
vouloir « compléter » cette logique côté gate.

**How to avoid:** `check-mission-exit.sh` ne fait que LIRE `driver-lock.sh status` (E1) — jamais
`release`, `takeover` ni `reclaim`. Sur E1 rouge, le comportement prescrit est D-11 : mandat de
clôture ciblée (`release`) renvoyé au manager, puis `human_needed` si le lock reste tenu.

**Warning signs:** Toute ligne du gate ou de `head-governance.md` qui invoque `driver-lock.sh
release`/`takeover`/`reclaim` directement depuis le head est un signal d'alarme immédiat (kernel
non intact, D-01/D-02 violés).

### Pitfall 4: Mesurer un arbre sale via `rtk` sans passer par `rtk proxy`

**What goes wrong:** E2 (« arbre propre ») compte les lignes de `git status --porcelain` — si cette
commande est exécutée à travers le hook `rtk` de Samuel sans `rtk proxy`, une sortie **vide** est
transformée en **1 ligne** de sortie (message de statut rtk), donc `| wc -l` rend 1 au lieu de 0.

**Why it happens:** Leçon déjà tracée dans le repo — mémoire `rtk-fausse-les-verifications-d-etat.md`
(Phase 18, 2026-08-18) et répétée explicitement dans `40-CONTEXT.md` D-07 (« mesuré en `rtk proxy`,
jamais via `\| wc -l` sous rtk »).

**How to avoid:** Le gate doit soit éviter tout hook rtk (invoquer `git status --porcelain`
directement, sans passer par le raccourci shell `git` qui pourrait être intercepté), soit
explicitement passer par `rtk proxy git status --porcelain` si le hook est actif dans
l'environnement d'exécution.

**Warning signs:** E2 rend faux-rouge (« arbre sale ») sur un arbre réellement propre — symptôme
caractéristique de ce piège déjà observé une fois dans ce repo.

## Code Examples

Voir §Architecture Patterns ci-dessus — tous les extraits de code sont déjà accompagnés de leur
source vérifiée et de leur citation verbatim (Pattern 1 à 5). Aucune duplication ici pour ne pas
diverger de la source unique.

## State of the Art

Sans objet pour cette phase — aucune technologie externe n'évolue ici, seule la convention interne
du repo est reconduite (patron déjà stable depuis la Phase 20/30).

**Déprécié/obsolète :** rien n'est déprécié par cette phase. Le nom `vibeflow-dev` devient un alias
interdit (comme `vf-head` l'est déjà par avance — D-17, « couche de synonymes interdite depuis
v2.33.0 ») mais ce n'est pas une dépréciation technologique, c'est une convention de nommage.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Aucun consommateur externe (hors ce repo et les postes déjà équipés de VibeFlow) ne dépend du nom littéral `vibeflow-dev` dans un contexte non couvert par la surface mesurée (ex. un dashboard tiers, un script d'automatisation externe non versionné dans ce repo) | §Runtime State Inventory | Faible — le repo est piloté par GSD et toute la surface de dispatch passe par les fichiers déjà audités ; un consommateur totalement externe et non documenté échapperait à toute recherche possible depuis ce repo |
| A2 | Le format proposé pour E6 (`{commande, exit_code, sha}` en champ `preuves[]` du bloc Pattern C) est compatible avec la façon dont `vf-coder`/`vf-reviewer`/`vf-auditer` produisent aujourd'hui leurs verdicts — aucun de ces workers n'a été inspecté ligne à ligne pour confirmer qu'ils PEUVENT déjà émettre `exit_code`+`sha` par verdict | §Code Examples Pattern 4 | Moyen — si un worker ne capture pas déjà le SHA du commit au moment du verdict, le planner devra ajouter ce geste au lot manager, pas seulement au gate ; à vérifier au plan en lisant `vf-coder.md`/`vf-reviewer.md` si le temps le permet |
| A3 | `gh pr view` sans argument, exécuté depuis le worktree de la mission, retourne un résultat exploitable pour E3 sans configuration supplémentaire (pas de flag `--json` requis pour distinguer "PR ouverte" de "pas de PR") | §Architecture Patterns Pattern 1/E3 | Faible-moyen — comportement standard de `gh pr view`, mais non testé en session ; un `gh pr view --json state` explicite serait plus robuste et devrait être confirmé/choisi au plan |

**Si cette table semblait vide** : elle ne l'est pas — 3 zones restent à confirmer au plan, aucune
n'est bloquante (toutes ont un repli déjà écrit dans le cadrage : D-06 traite l'indéterminé comme
un résultat de premier ordre, pas une erreur).

## Open Questions

1. **Forme exacte du champ `preuves` dans le bloc Pattern C (E6)**
   - What we know : le patron `estimate`/`actuals` (deux objets optionnels frères) est directement
     transposable ; D-05 précise le triplet `{commande, exit_code, sha}` et le cas `preuve: amont`.
   - What's unclear : nom exact du champ (`preuves`, `proofs`, `gates`?), et s'il est un objet par
     type de verdict (recette/revue/audit) ou un tableau plat avec un champ `verdict` discriminant.
   - Recommendation : trancher au plan en suivant strictement le gabarit `estimate`/`actuals` déjà
     en place (nommage cohérent, français comme le reste du contrat) — proposition : `"preuves": [
     { "verdict": "recette|revue|audit|gate:<nom>", "commande": "…", "exit_code": N, "sha": "…" } ]`,
     avec `"preuve": "amont"` en remplacement du triplet pour un hook moteur GSD relayé verbatim.

2. **`gh pr view` sans authentification vs sans remote — le gate distingue-t-il les deux causes de
   « indéterminé » ?**
   - What we know : D-06 dit que l'absence de source de vérité (pas de `gh`, pas de remote, lab
     racine non-git) rend le contrôle **4** globalement.
   - What's unclear : si E3 doit distinguer en message stderr « `gh` absent » de « remote absent »
     de « `gh` présent mais non authentifié » — les trois causes existent et ont des remèdes
     différents pour l'utilisateur.
   - Recommendation : suivre le patron de diagnostic déjà en place dans
     `check-mission-invariants.sh` (« diagnostic sur stderr, sauf --quiet, précisant laquelle ») —
     un message par cause, même code de sortie 4.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | `check-mission-exit.sh` + sa suite de tests | ✓ [VERIFIED: `.github/workflows/ci.yml:27` — `bash --version \| head -1` en CI] | POSIX-compatible, testé macOS+Linux | — |
| jq | Lecture du JSON `driver-lock.sh status` | ✓ [VERIFIED: `.github/workflows/ci.yml:28`] | — | — |
| git | E2, E3 | ✓ (prérequis universel du repo) | — | — |
| gh (GitHub CLI) | E3 (PR ouverte) | Non garanti sur tout poste | — | Repli documenté et déjà exigé par D-06/D-07 : absence → contrôle indéterminé (code 4), jamais un crash |

**Missing dependencies with no fallback :** aucune — `gh` a un repli explicitement prescrit par le
cadrage lui-même.

**Missing dependencies with fallback :** `gh` (voir ci-dessus).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Suites bash maison, gabarit `ok`/`ko` (pas de framework tiers — patron `test-check-overlaps.sh`, `test-dev-orchestrator.sh`) |
| Config file | Aucun — chaque suite est un script exécutable autonome |
| Quick run command | `bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` |
| Full suite command | Job CI `tests` : `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis exécution de chaque suite [VERIFIED: .github/workflows/ci.yml:218] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HEAD-02 | Gate de sortie E1-E6, codes 3/0/4/64, mutation rouge | unit (bash) | `bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` | ❌ Wave 0 — à créer avec le gate |
| HEAD-04 | Aucun alias `vibeflow-dev` ne survit dans `plugin/` hors CHANGELOG | unit (bash, grep + mutation) | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (nouveau cas, même fichier — hôte confirmé par 40-CONTEXT.md) | ⚠️ fichier existe déjà (1297 lignes), le nouveau cas de test est à ajouter dedans, pas un nouveau fichier |
| HEAD-01 / HEAD-03 | Règle d'échelle et décompte documentés dans `head-governance.md` | doc (pas de test machine — c'est de la prose de gouvernance, pas un comportement exécutable) | — (aucune commande — cohérent avec `intent-routing.md` qui n'a pas de suite dédiée non plus, seul `test-dev-orchestrator.sh` T14 vérifie son exhaustivité) | — |
| ADR-057 (check-overlaps) | Ligne `vibeflow-dev|gsd-next` renommée en `vibeflow-head|gsd-next` | unit (bash) | `bash plugin/conductor/scripts/tests/test-check-overlaps.sh` (T15/T16 existants, l.186-203, à adapter au nom) | ✓ existe (renommage de fixture, pas de nouveau cas) |

### Sampling Rate
- **Per task commit :** suite du module touché (`test-dev-orchestrator.sh` pour le renommage/AGENT,
  `test-check-mission-exit.sh` pour le gate, `test-check-overlaps.sh` pour la frontière ADR-057).
- **Per wave merge :** `find plugin scripts -type f -path '*/tests/test-*.sh' | sort` puis exécution
  intégrale — la découverte CI est **automatique**, aucun câblage manuel requis pour la nouvelle
  suite [VERIFIED: .github/workflows/ci.yml:218-223].
- **Phase gate :** Full suite (job `gates` de `ci.yml`) verte avant `/gsd-verify-work` — **rejouer
  les commandes réelles du job**, jamais une liste recopiée d'un rapport (leçon nommée du repo,
  « liste de gates ≠ référence », citée par D-12).

### Wave 0 Gaps
- [ ] `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` — n'existe pas encore,
  naît avec le gate (QUAL-01 : mutation rouge prouvée dès la première vague).
- [ ] Cas de test anti-alias dans `test-dev-orchestrator.sh` (fichier existant, nouveau bloc à
  ajouter) — grep récursif `plugin/` hors `CHANGELOG.md`, mutation = réinjecter un alias
  `vibeflow-dev` quelque part et vérifier que le test échoue.
- [ ] Aucun framework à installer — tout l'outillage (bash, `ok`/`ko`) est déjà en place.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | pas d'authentification en jeu |
| V3 Session Management | non | — |
| V4 Access Control | non | — |
| V5 Input Validation | **oui, limité** | `check-mission-exit.sh` doit valider ses arguments CLI (`--path`, options éventuelles) avec `exit 64` sur toute forme malformée — patron déjà appliqué par `check-mission-invariants.sh` (§Code Examples Pattern 1) |
| V6 Cryptography | non | aucune donnée sensible manipulée |

### Known Threat Patterns for ce domaine

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injection via un argument shell non validé (ex. `--path` contenant une expansion malveillante) | Tampering | Le patron `check-mission-invariants.sh` traite chaque argument par `case` explicite, jamais un `eval`, et durcit toutes les invocations git via `git_safe()` (`GIT_CONFIG_NOSYSTEM`, `GIT_TERMINAL_PROMPT=0`, `GIT_OPTIONAL_LOCKS=0`, `-c core.hooksPath=/dev/null`) — à reproduire à l'identique dans `check-mission-exit.sh` puisqu'il invoque git lui-même pour E2/E3 |
| Un gate qui accepte silencieusement une sortie inattendue (jq échoue, JSON malformé de `driver-lock.sh status`) et rend un vert par défaut | Repudiation / faux positif de sécurité opérationnelle | Le contrat de codes de sortie (D-07) prévoit explicitement `4` (indéterminé) et `64` (outillage illisible) pour ces cas — jamais un `3` par défaut ; c'est directement l'axiome « une preuve doit pouvoir rendre rouge » appliqué à la lecture de sortie d'un outil tiers (`jq`) |

## Sources

### Primary (HIGH confidence — lecture directe de fichiers du repo, cette session)
- `plugin/conductor/scripts/check-mission-invariants.sh` (619 lignes lues intégralement) — patron
  exact du gate de sortie.
- `plugin/conductor/scripts/driver-lock.sh` (lignes 300-380 lues) — format JSON de `status`.
- `plugin/dev-orchestrator/references/mission-flow.md` (lignes 1-35, 210-268 lues) — cascade `$S`,
  Pattern C, table de pilotage.
- `plugin/dev-orchestrator/references/mission-contracts.md` (lignes 130-180, 280-335 lues) —
  contrat `estimate:`/`actuals:`, gabarit Rapport de mission, signaux, seuil.
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` (lignes 195-250 lues) — release du lock avant
  rapport, ligne « Dispatché par l'agent vibeflow-dev ».
- `plugin/dev-orchestrator/AGENT.md` (206 lignes lues intégralement) — structure actuelle.
- `plugin/dev-orchestrator/references/_index.md` (21 lignes lues intégralement).
- `plugin/conductor/scripts/check-overlaps.sh` (ligne 67), `plugin/conductor/scripts/tests/
  test-check-overlaps.sh` (lignes 180-210) — ligne et fixtures ADR-057.
- `plugin/_internal/vibeflow-update.sh` (lignes 2220-2245) — pose d'`AGENT.md` sous
  `$TARGET_ROOT/agents/<mod>.md`.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (ligne 1298 confirmée par grep
  — `40-CONTEXT.md` citait « l.1297-1298 », la ligne exacte du grep est 1298).
- `.github/workflows/ci.yml` (lignes 1-60, ligne 218) — découverte automatique des suites, pin
  Node 24.
- `.planning/REQUIREMENTS.md` (lu intégralement, 2 pages) — 44 préfixes existants, `HEAD` absent.
- `.planning/ROADMAP.md` §Phase 40, §Phase 41 (lignes 1420-1514) — Goal, Depends on, Success
  Criteria.
- `.planning/STATE.md` (lignes 1-548) — état courant, roadmap evolution.
- `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` (227 lignes lues intégralement) —
  conception complète.
- `.planning/phases/VFDO-40-.../40-CONTEXT.md` (315 lignes lues intégralement) — décisions
  verrouillées.
- `~/.claude/agents/dev-orchestrator.md` (5 premières lignes lues) — confirmation de l'état
  installé sur le poste courant.
- `.planning/config.json` — `nyquist_validation: true`, `security_enforcement: true`.

### Secondary (MEDIUM confidence)
— aucune (tout a été vérifié directement en primaire pour cette phase).

### Tertiary (LOW confidence)
— aucune (aucune recherche web n'était nécessaire, domaine entièrement in-repo).

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — aucune dépendance externe, tout l'outillage déjà en place et vérifié en CI.
- Architecture : HIGH — chaque pattern cité est une lecture directe et une citation verbatim de code
  existant à reproduire.
- Pitfalls : HIGH pour les 4 pitfalls listés (tous vérifiés par grep/lecture directe cette session) ;
  MEDIUM pour la complétude de la liste (un 21ᵉ fichier oublié ailleurs resterait possible malgré le
  grep exhaustif, mais le test anti-alias du plan est justement le filet qui le détecterait).

**Research date :** 2026-09-15
**Valid until :** cadrage in-repo stable — pas de péremption courte (pas de dépendance à un
registre externe qui publie) ; à re-vérifier seulement si `40-CONTEXT.md` est amendé ou si un
nouveau fichier citant `vibeflow-dev` apparaît dans `plugin/` avant l'exécution du plan.
