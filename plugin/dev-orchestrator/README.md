# dev-orchestrator — Orchestrateur de développement (VFDO)

> Module VibeFlow qui route les requêtes de développement en **langage naturel** vers les
> bons skills GSD/Superpowers installés — via **31 verbes `/vf-*`**, une **rule de préséance**,
> un **agent routeur** et un **index factuel auto-généré**. L'utilisateur ne parle que VibeFlow ;
> la plomberie GSD/Superpowers reste invisible.

**Version** : v1.8.0
**Type** : agent + multi-skills + scripts

> **Prérequis** — Claude Code **≥ v2.1.198** pour le mécanisme natif `.claude/rules/`, sans lequel
> la rule de préséance (`rules/vf-verb-precedence.md`) n'est pas chargée et le niveau 2 du routage
> reste inopérant. Le reste du module fonctionne sans elle, en mode dégradé.

---

## Vue d'ensemble

Dire « aide-moi à dev », « code ça », « on est où ? » ou « débugge ce crash » déclenche le
pipeline de développement complet **sans jamais connaître GSD ni Superpowers**. Le routage se joue
à **trois niveaux**, du moins cher au plus complet :

1. **Les descriptions des verbes** (`skills/vf-*/SKILL.md`) — c'est le cas courant. Chaque
   description porte les formulations réelles qui la déclenchent **et** les contre-exemples qui
   renvoient vers les voisins (`✘ pas pour … → /vf-…`). C'est ce qui départage deux gestes proches.
2. **La rule de préséance** (`rules/vf-verb-precedence.md`) — rule **globale**, chargée en
   permanence : une intention de dev entre dans la chaîne **par un verbe**, jamais par un skill
   interne appelé en direct (ce qui court-circuiterait cadrage, recette et reframe).
3. **L'agent `vibeflow-dev`** (`AGENT.md`) — le cerveau routeur, quand la demande est ambiguë ou
   composite. Il porte la table intention → verbe, l'ordre du pipeline et les garde-fous, et
   consulte `references/intent-routing.md` (doctrine exhaustive, **on-demand**) quand aucune
   intention connue ne colle. Il reformule toutes les sorties en vocabulaire VibeFlow.

S'y ajoutent :

- **31 verbes `/vf-*`** (`skills/vf-*/`) — points d'entrée explicites, inventaire ci-dessous.
  Chaque verbe délègue à sa cible interne et ne réimplémente jamais sa logique.
- **Scripts** (`scripts/`) — bootstrap et indexation :
   - `ensure-deps.sh` : auto-install non-interactif et **idempotent** de GSD + Superpowers
     (fallback manuel si Node/npm ou CLI `claude` manquent — jamais d'échec silencieux).
   - `build-gsd-index.sh` : génère un **index factuel** des skills GSD installés
     (100 % auto-généré depuis le frontmatter sur disque — D4, anti-hallucination).

---

## Structure du module

```
dev-orchestrator/
├── AGENT.md                       # agent vibeflow-dev (≤250L, dense)
├── agents/                        # équipe manager de mission (v1.5.0)
│   ├── vf-dev-manager.md          # manager de mission — exposé
│   ├── vf-coder.md                # worker interne (vf-internal: true)
│   ├── vf-reviewer.md             # worker interne (vf-internal: true)
│   └── vf-auditer.md              # worker interne (vf-internal: true)
├── skills/vf-*/SKILL.md           # 31 verbes utilisateur /vf-* (≤500L chacun)
├── rules/
│   └── vf-verb-precedence.md      # rule GLOBALE (sans paths:, ≤40L) — préséance des verbes
├── scripts/
│   ├── ensure-deps.sh             # bootstrap deps (idempotent, dry-run testable)
│   ├── build-gsd-index.sh         # index factuel (VF_INDEX_OUT surchargeable)
│   └── tests/test-dev-orchestrator.sh  # suite de vérification (4 axes + densité + routage)
└── references/                    # doctrine + index chargés on-demand par l'agent
    ├── intent-routing.md           # doctrine de routage exhaustive (intention → verbe → cible)
    ├── GSD-PIPELINE.md
    ├── gsd-skills-index.md         # auto-généré (NE PAS ÉDITER)
    ├── vocabulary-map.md
    ├── mission-contracts.md        # contrats Brief/Rapport de mission + SEUIL_EQUIPE
    └── autonomous-guardrails.md    # garde-fous du mode autonome
```

> **`intent-routing.md` vs `gsd-skills-index.md`** — l'index est un **inventaire factuel**
> auto-généré (« ce skill est-il installé ici ? ») et ne s'édite jamais ; `intent-routing.md` est la
> **doctrine** écrite à la main (« quelle intention mène où, par quel verbe ? »). Quand l'index
> évolue, c'est la doctrine qui s'aligne sur lui — jamais l'inverse.

---

## Installation (via vibeflow-update.sh)

```bash
# depuis votre lab
.claude/scripts/vibeflow-update.sh install dev-orchestrator
```

L'installeur pose, de bout en bout :

- l'agent → `.claude/agents/dev-orchestrator.md`
- les verbes `/vf-*` → `.claude/skills/vf-*/`
- la rule de préséance → `.claude/rules/vf-verb-precedence.md` (**Claude Code ≥ v2.1.198**)
- les scripts → `.claude/scripts/` (+ tests)
- les références (**D7**) → `.claude/agents/dev-orchestrator-references/`
  (`intent-routing.md`, `GSD-PIPELINE.md`, `gsd-skills-index.md`, `vocabulary-map.md`)
- un **index frais** : à l'install, `build-gsd-index.sh` est ré-exécuté avec
  `VF_INDEX_OUT=.claude/agents/dev-orchestrator-references/gsd-skills-index.md` (IDX-02).
  Best-effort : si GSD est absent, l'install n'échoue pas — l'index sera régénéré plus tard.

> **Note D7** — les références d'un module agent sont installées sous
> `.claude/agents/<mod>-references/`, pas sous `.claude/skills/`. L'agent les charge
> on-demand (densité préservée : l'`AGENT.md` n'embarque que l'ordre du pipeline).

---

## Usage

### Langage naturel (recommandé)

L'utilisateur parle normalement ; l'agent `vibeflow-dev` route :

| Vous dites… | Verbe déclenché | Coulisse (invisible) |
|---|---|---|
| « initialise », « démarre VibeFlow », « amorce le projet » | `/vf-init` | bootstrap des dépendances + proposition d'init |
| « cartographie le code », « c'est quoi ce repo ? », « explique l'archi » | `/vf-map` | cartographie du code |
| « réfléchis à… », « et si on… », « on part sur quelle solution » | `/vf-brainstorm` | conception d'une solution |
| « je sais pas encore ce que je veux », « creuse le sujet » | `/vf-explore` | exploration socratique |
| « planifie », « cadre cette feature » | `/vf-plan` | cadrage puis plan de travail |
| « code ça », « implémente la feature X » | `/vf-execute` | exécution du plan |
| « teste », « ça marche ? » | `/vf-test` | recette |
| « relis », « regarde ce diff » | `/vf-review` | revue de code |
| « qu'est-ce qui traîne », « la dette », « comble les trous » | `/vf-gaps` | audits et validations en souffrance |
| « ça plante », « débugge » | `/vf-debug` | dépannage (recherche doc d'abord) |
| « fais tout en autonomie » | `/vf-auto` | mode autonome |
| « livre », « crée une PR » | `/vf-ship` | livraison |
| « on est où ? », « la suite » | `/vf-progress` | point d'avancement |

### Les 31 verbes, par famille

- **Amont & cadrage** — `vf-brainstorm` (concevoir une solution sur une idée déjà formulée) ·
  `vf-explore` (idée encore floue) · `vf-spike` (code jetable pour trancher une question technique) ·
  `vf-spec` (figer le QUOI) · `vf-decide` (choisir entre options) · `vf-plan` (cadrer et découper) ·
  `vf-init` (amorcer le projet).
- **Construction** — `vf-execute` · `vf-quick` (petite tâche) · `vf-auto` (tout enchaîner) ·
  `vf-ship` (PR / livraison) · `vf-dev` (aiguilleur générique, dernier recours).
- **Qualité & audits** — `vf-test` (recette) · `vf-testgen` (écrire les tests manquants) ·
  `vf-review` (relire un diff) · `vf-gaps` (dette et validations en souffrance) · `vf-secure`
  (failles, threat model) · `vf-debug` (bug en cours) · `vf-forensics` (post-mortem de cycle) ·
  `vf-inbox` (issues et PR entrantes).
- **Cycle de vie projet** — `vf-milestone` (jalons) · `vf-phase` (éditer la feuille de route) ·
  `vf-undo` (revenir en arrière) · `vf-backlog` (idées en attente) · `vf-cleanup` (ménage).
- **Contexte & session** — `vf-progress` · `vf-resume` (recharger une session) · `vf-pause`
  (handoff propre) · `vf-map` (comprendre le code) · `vf-docs` (doc du projet) · `vf-learn`
  (décisions et enseignements).

Le module `design-orchestrator`, installé d'office avec celui-ci, ajoute `/vf-design` et
`/vf-sketch`. Deux intentions voisines appartiennent à d'autres modules et ne sont **jamais**
captées ici : `/vf-audit` (conformité du lab, module `validator`) et `/vf-planning` (socle de
planning du lab, module `planning-core`).

### Parcours types

- **Premier contact (dossier vierge)** : `vf-init` → amorce les dépendances, puis propose
  de démarrer un projet (sur confirmation).
- **Projet existant** : `vf-map` (comprendre l'existant) → `vf-plan` → `vf-execute` → `vf-test`.
- **Tâche unique rapide** : `vf-quick` (ou dites simplement « corrige ce typo »).
- **En autonomie totale** : `vf-auto` enchaîne plan → exécution → recette tout seul.

### Équipe manager de mission (v1.5.0)

Pour les missions multi-étapes, le router propose de déléguer à `vf-dev-manager` : la
conversation principale reste légère, le manager planifie/décide/distribue, et les workers
(`vf-coder`, `vf-reviewer`, `vf-auditer`) travaillent chacun dans un contexte minimal isolé.
`vf-auto` bascule automatiquement vers l'équipe au-delà de `SEUIL_EQUIPE` étapes restantes ou
sur signal de durée (« la nuit »). Contrats et seuil : `references/mission-contracts.md`.

### Bootstrap des dépendances

`vf-init` (ou l'agent au premier contact) lance `ensure-deps.sh` : auto-install
non-interactif de GSD + Superpowers, idempotent. `gsd-new-project` n'est **jamais** lancé
seul — uniquement proposé sur confirmation explicite (BOOT-04).

---

## Tests

```bash
bash dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
```

Couvre 4 axes (VERIF-01) — index non vide, idempotence `ensure-deps`, ≥11 intentions routées
vers des verbes distincts, aucun mapping `/vf-*` orphelin — plus les gates de densité
(VERIF-02 : agent ≤250L, skills ≤500L, mesurés par `wc -l`). S'y ajoutent, pour l'équipe
manager de mission (v1.5.0), T8/T8b (conformité des 4 agents natifs : frontmatter, densité,
`vf-internal` sur les 3 workers / absent du manager exposé — Pattern 12), T9 (contrats de
mission : source unique `mission-contracts.md` + 3 renvois DRY), T10 (routage mission dans
`AGENT.md` + aiguillage taille dans `vf-auto` sur `SEUIL_EQUIPE`) et T11 (généricité : aucun
résidu spécifique à un lab dans `agents/`).

Le routage fin (v1.8.0) ajoute trois axes :

- **T12 — anti-collision** : sur chaque groupe de verbes à recouvrement lexical avéré, la
  démarcation est **croisée** (si A repousse vers B, B repousse vers A) et chaque verbe repousse au
  moins un voisin. Les deux modules sont lus (la frontière `vf-sketch` / `vf-design` / `vf-spike`
  les traverse). Vérifie aussi la **chasse gardée** : aucun verbe de dev ne capte l'audit de
  conformité du lab, réservé à `/vf-audit`.
- **T13 — préséance** : la rule existe, ne déclare **pas** de `paths:` (sinon elle ne serait
  chargée qu'à la lecture d'un fichier correspondant), tient en ≤ 40 L, est référencée par
  l'agent — et la table de routage de l'agent ne cite **aucune** cible interne.
- **T14 — exhaustivité** : chaque skill de l'index factuel est routé par `intent-routing.md`
  (SKIP si l'index est vide, c'est-à-dire sans chaîne interne installée), et toute cible promise
  par la doctrine est réellement citée dans le corps du verbe qui la porte.

Au total T1-T14. Exit 0 si tout passe (les SKIP, ex. GSD absent, ne font pas échouer la suite).
La suite doit rester verte **aussi sans chaîne interne sur la machine** : `FIXTURE_TARGETS`
(T4) embarque pour ça toutes les cibles portées par un verbe — sans elle, le test passe en local
et échoue en CI.

---

## Références

- ADR / spec : `docs/superpowers/specs/2026-06-04-dev-orchestrator-design.md`
- Routage fin des verbes (v1.8.0) : `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`
- Rules natives (`.claude/rules/`, priorité et chargement) : documentation Claude Code `memory.md`
  — mécanisme disponible à partir de **v2.1.198**
- D3 : auto-install des deps, init sur confirmation seulement
- D4 : index 100 % auto-généré (anti-hallucination)
- D7 : références d'un module agent sous `.claude/agents/<mod>-references/`
- IDX-02 : index régénéré à l'install via `VF_INDEX_OUT`
