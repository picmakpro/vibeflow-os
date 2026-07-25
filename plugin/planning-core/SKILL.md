---
name: vf-planning
description: >
  Utiliser pour poser ou tenir à jour le socle de planning et de documentation d'un lab NON-DEV —
  contenu, vente, growth, design, montage de dossier, recherche : « structure la doc de ce lab »,
  « mets en place le suivi », « on perd le fil / le contexte », « pose le cadre du lab »,
  « initialise le .planning ». Utiliser aussi, sur TOUT lab y compris dev, pour l'altitude LAB :
  « fais l'index de mes projets », « quel compartiment suit quoi », « ce client mérite-t-il son
  propre plan », « remonte les décisions en mémoire », « qu'est-ce qui traîne sans plan ».
  ✘ PAS pour le planning d'un projet de code — la charte, la trajectoire, les exigences, l'état
  et les étapes d'un projet dev appartiennent au moteur de développement : démarrage →
  `/vf-init`, état et avancement → `/vf-progress`, cadrage d'une étape → `/vf-plan`, comprendre
  l'existant → `/vf-map`. Invocable par l'utilisateur ET par un agent en autonomie.
---

# vf-planning — Socle de planning & documentation universel

> **Mission** : poser et maintenir le **tronc commun `.planning/`** d'un lab — la couche qui répond
> à « où va-t-on, où en est-on, qu'a-t-on décidé » — **en l'adaptant à la logique métier du lab**.
>
> **Iron Law** : *« Le tronc est invariant ; tout le reste s'adapte au métier. On n'impose jamais
> une forme (dev ou autre) à un lab qui a une autre logique. »*

Skill **scaffoldeur thin, prose agent-driven** : il lit le contexte du lab, choisit le bon niveau
de rigueur, instancie les templates en les adaptant, et tient l'état à jour. Il ne force aucune
structure déterministe et ne duplique pas la mémoire existante.

---

## Le tronc commun (les 7 artefacts — toujours présents, jamais plus que nécessaire)

| Artefact | Répond à | Toujours là ? |
|---|---|---|
| `PROJECT.md` | Quoi, valeur cœur, contraintes, **décisions clés** | ✅ invariant |
| `STATE.md` ★ | **Où on en est MAINTENANT** (reconstruit chaque session) | ✅ **clé de voûte** |
| `ROADMAP.md` | Où on va : phases/jalons + **critères de succès** | ✅ invariant |
| `REQUIREMENTS.md` | Exigences à IDs + traçabilité | ⚖️ profil ≥ standard |
| `MILESTONES.md` + `milestones/` | Archive des jalons livrés | ⚖️ profil ≥ standard |
| `phases/NN/PLAN.md` + `SUMMARY.md` | Trace plan → exécution → bilan, par étape | ⚖️ profil ≥ standard |
| `config.json` | Profil de rigueur + options | ✅ invariant (léger) |

> **STATE.md est le seul fichier strictement obligatoire dans tous les cas.** C'est lui qui tue la
> perte de contexte : il se relit/reconstruit au démarrage de chaque session.

Le **détail des 3 profils de rigueur** (léger / standard / complet) et le **mapping métier → profil**
sont dans `references/PROFILES.md`. La **doctrine complète** (pourquoi, anti-biais, adaptation par
métier) est dans `references/GUIDE.md`. Charger on-demand.

---

## Lab mono-objectif vs lab à compartiments (v2)

Deux topologies. **Ne pas plaquer la mauvaise.**

- **Lab mono-objectif** (un seul fil de travail) → **un seul `.planning/`** à la racine. C'est le cas
  par défaut, comportement inchangé.
- **Lab à compartiments** (plusieurs projets internes / clients / process — ex. `projects/*`) →
  **steering au niveau lab + plan conditionnel par compartiment**. Règle :
  - Le **lab** porte `PROJECT.md` (identité) + `STATE.md` (focus transverse) + **`INDEX.md`**
    (tableau de bord qui POINTE vers les plans). **Jamais de `ROADMAP.md` global** (plan mort).
  - Un **compartiment** reçoit son propre socle `.planning/` **seulement s'il passe le seuil
    d'autonomie**, et **typé** :
    - **`deliverable`** (a une fin) → `STATE` + `ROADMAP` + phases/MILESTONES selon profil ;
    - **`continuous`** (se renouvelle) → `STATE` + **`BOARD.md`** (colonnes + WIP + cadence), **pas de
      roadmap**.
  - Sous le seuil, ou infra à suivi intrinsèque (`finance/`, `pipeline/`…) → **pas de plan**, juste une
    ligne dans `INDEX.md`.

> Doctrine complète (seuil d'autonomie chiffré, cas hybride, non-cannibalisation, migration sans perte) :
> **`references/compartments.md`**. Charger dès qu'un lab a plusieurs projets/compartiments.

---

## Étape 0 — Qui tient le planning de ce lab ? (TOUJOURS en premier)

> **Iron Law du rescope (ADR-055)** : *« Un projet de code a un seul propriétaire de planning : le
> moteur de développement. VibeFlow tient l'altitude au-dessus (le lab) et la couche à côté
> (mémoire, enforcement) — jamais la même. »*

Avant toute autre chose, croiser **un fait** et **un jugement**.

1. **Le fait** — lancer `scripts/detect-gsd-engine.sh`. Il ne dit PAS si le lab est dev : il dit
   si un **moteur de planning de développement** est en place.

   Les exits sont listés dans l'**ordre où le script les évalue** — le premier qui matche gagne, un lab
   pouvant satisfaire plusieurs situations à la fois. Le marqueur lu est une clé du **frontmatter** de
   `STATE.md`, jamais une chaîne trouvée ailleurs dans le fichier.

   | Exit | Signification | Suite |
   |---|---|---|
   | `1` | chaîne de dev absente de la machine | → si le métier est dev, proposer l'amorçage via `/vf-init` ; **ne jamais** scaffolder un tronc dev à la main |
   | `0` | moteur de dev actif sur ce `.planning/` | → **Séquence B**, couche lab uniquement |
   | `2` | socle `planning-core` + code alentour | → juger le métier, puis protocole de migration (`references/gsd-handoff.md`) |
   | `3` | aucun moteur en place | → le jugement métier décide seul |

2. **Le jugement** — appliquer `references/domain-detection.md` (lire `CLAUDE.md`, les registres, le
   vocabulaire dominant). Le métier n'est **jamais** déduit d'un `package.json` seul.

3. **Brancher** :
   - **Lab non-dev** → **Séquence A** (socle universel) ci-dessous. Comportement historique intact.
   - **Lab dev** → **Séquence B** : appliquer **uniquement** la couche lab (`INDEX.md`, typage des
     compartiments, pont mémoire, surface de la dette) et **rediriger** toute demande portant sur un
     projet vers son verbe, selon la table de `references/gsd-handoff.md`. Ne pas générer la charte,
     la trajectoire, les exigences, l'état ni les étapes d'un projet de code.

**Sur un lab dev à compartiments** : le lab reçoit `INDEX.md` + `STATE.md` de steering (à nous) ;
chaque compartiment dev reçoit son `.planning/` **écrit par le moteur de dev**, depuis ce
compartiment. Les deux couches ne se croisent sur aucun fichier.

Charger `references/gsd-handoff.md` dès que l'exit vaut 0 ou 2, ou que le jugement conclut « dev » :
la table de redirection intention → verbe y vit, et ne se duplique pas ici.

---

## Séquence A — Socle universel, lab non-dev (`.planning/` absent)

1. **Lire le métier du lab AVANT de scaffolder.** Lire `CLAUDE.md`, le `docs/` existant, les
   registres `.claude/memory/`, et déduire : *quel métier ? quelle granularité de travail ?*
   Ne jamais présumer « dev ». Appliquer les heuristiques de `references/domain-detection.md`
   (jugement, pas détection figée). Si la logique métier n'est pas claire → **une question courte**.

2. **Choisir le profil de rigueur** (`references/PROFILES.md`) selon le métier détecté. Le
   **proposer** à l'utilisateur (pré-coché), ne pas l'imposer. Léger par défaut pour les métiers
   créatifs/ponctuels ; standard pour contenu/vente/ops ; complet pour dev/projets critiques.

3. **Instancier le tronc en l'ADAPTANT** depuis `references/templates/` :
   - Remplir `PROJECT.md` avec la vraie valeur métier du lab (pas un gabarit dev).
   - Créer `STATE.md` (clé de voûte) + `ROADMAP.md` + `config.json` (profil choisi).
   - Profil ≥ standard : ajouter `REQUIREMENTS.md`, `MILESTONES.md`, l'arbo `phases/`.
   - **Extension de domaine** : créer le sous-dossier propre au métier — `codebase/` (dev),
     `editorial/` (contenu), `pipeline/` (vente), `dossiers/` (montage de dossier), etc.
     **Le nom et le contenu suivent le métier, jamais l'inverse.** Aucune extension imposée.

3bis. **Si le lab est à compartiments** (plusieurs projets/clients/process — ex. `projects/*`) :
   poser le `.planning/` du **lab** en mode *steering + `INDEX.md`* (pas de ROADMAP global) ; puis pour
   chaque compartiment, appliquer le **seuil d'autonomie** et le **typer** `deliverable`/`continuous`
   avant de lui poser (ou non) son propre socle. Détail : `references/compartments.md`. Gabarits :
   `templates/INDEX.template.md` (lab) + `templates/BOARD.template.md` (compartiment continuous).

4. **Établir le pont mémoire** (`references/bridge-memory.md`) : `.planning/` = couche *avant/présent*
   (vivante) ; les registres `.claude/memory/` = couche *capitalisation* (figée). Définir où les
   décisions clés de `PROJECT.md` remontent en DECISIONS et où `STATE.md` alimente le JOURNAL —
   **sans dupliquer**.

5. **Récap** : montrer l'arbo posée, le profil, et la prochaine action en vocabulaire du lab.

## Séquence A (suite) — Maintenance du socle universel (`.planning/` déjà là)

- **Vérifier la fraîcheur** : `scripts/check-planning-state.sh` (advisory) signale un `STATE.md`
  périmé ou un `.planning/` absent — utilisable manuellement, au `/checkpoint`, ou en hook
  SessionStart opt-in (wiring dans `references/domain-detection.md`).
- **Détecter la dette de planning** (labs à compartiments) : `scripts/detect-planning-debt.sh`
  (advisory) liste les compartiments **actifs + sans plan + au-dessus du seuil d'autonomie**. Alerte,
  jamais bloquant. À lancer au `/checkpoint` ou via `vibeflow-validator`.
- **Mettre à jour `STATE.md`** en priorité (position courante, % d'avancement, focus, todos).
- À la clôture d'une étape : écrire son `SUMMARY.md` ; à l'ouverture : son `PLAN.md`.
- À la livraison d'un jalon : archiver dans `MILESTONES.md` + `milestones/`.
- Promouvoir les décisions structurantes de `PROJECT.md` vers la mémoire (pont).

> **Automatisation livrée (v2.2.0, ADR-050 ; durcie v2.3.0)** — la maintenance n'est plus seulement une
> discipline manuelle, elle est machine-enforced par 4 hooks :
> - **SessionStart** : `planning-context.sh` injecte un **digest index-first** (INDEX du lab, ou STATE
>   borné en mono) + `detect-planning-debt.sh` surface le 8e signal de dette + `planning-session-snapshot.sh`
>   photographie la **baseline de session** (epoch, HEAD de départ, porcelain hashé).
> - **UserPromptSubmit** : `planning-task-context.sh` injecte le `STATE.md` **du compartiment que vise la
>   tâche** (jamais tous — structuration du contexte).
> - **Stop** : `guard-planning-updated.sh` **bloque** si des livrables ont changé **pendant la session**
>   sans mise à jour du planning. L'attribution se fait contre la baseline (commits de la session via
>   `git log --since`, dirt nouveau ou au hash modifié) — le dirt préexistant n'est JAMAIS attribué, un
>   `STATE.md` mis à jour **puis committé** (flow GSD/dev-orchestrator) est bien reconnu, et le signal
>   mtime couvre un `.planning/` gitignoré. Au pire **un seul blocage par session** (marqueur `.blocked`
>   + anti-boucle `stop_hook_active`), échappatoire `.session-noop`, baseline absente/périmée → fail-open,
>   toggle `VF_PLANNING_STOP=block|warn|off`.

## Séquence B — Couche lab au-dessus du moteur de dev (lab dev)

1. **Ne générer aucun artefact de projet.** Le tronc d'un projet de code (charte, trajectoire,
   exigences, état, étapes) appartient au moteur de développement — jamais à ce skill.
2. **Poser ou rafraîchir l'altitude lab** si le lab a plusieurs compartiments : `INDEX.md`, typage
   `deliverable`/`continuous`, seuil d'autonomie (`references/compartments.md`).
3. **Surface de la dette** : `scripts/detect-planning-debt.sh` (advisory).
4. **Pont mémoire** : promouvoir les décisions structurantes vers `.claude/memory/`
   (`references/bridge-memory.md`) — référencer, jamais recopier.
5. **Rediriger** ce qui concerne un projet vers son verbe (table de `references/gsd-handoff.md`),
   en vocabulaire VibeFlow, sans jamais nommer l'outillage sous-jacent.

---

## Garde-fous (anti-biais)

- **Ne jamais plaquer la forme dev** sur un lab non-dev. Pas de `codebase/`, pas de jargon de sprint
  de code si le métier n'est pas le code.
- **Ne jamais imposer le profil complet** par défaut. La rigueur suit le besoin réel du métier.
- **Ne jamais dupliquer la mémoire** : si une info vit déjà dans un registre `.claude/memory/`, on la
  référence, on ne la recopie pas dans `.planning/`.
- **Ne jamais sur-documenter** : le tronc minimal viable (`STATE` + `PROJECT` + `ROADMAP`) suffit pour
  un lab léger. On n'ajoute un artefact que s'il sert.
- **Ne jamais poser le tronc d'un projet de code** (ADR-055). Sur un lab dev, la charte, la
  trajectoire, les exigences, l'état et les étapes appartiennent au moteur de développement — on
  redirige vers le verbe, on ne génère pas.
- **Adapter le vocabulaire** au métier du lab (le projet est francophone — sortie en français).

## Anti-patterns

- ❌ Scaffolder un `.planning/` dev complet sur un lab de contenu « parce que c'est le template ».
- ❌ Créer `REQUIREMENTS.md` + `phases/` pour un lab où le travail n'est pas découpé en exigences.
- ❌ Recopier les entrées DECISIONS dans `PROJECT.md` (doublon mémoire).
- ❌ Démarrer le scaffolding sans avoir lu `CLAUDE.md` / le métier du lab.
- ❌ Laisser `STATE.md` se périmer (c'est la clé de voûte — toujours le rafraîchir).
- ❌ Écrire un `STATE.md` au format `planning_version:` dans un `.planning/` que l'outillage de dev
  pilote (les deux frontmatters sont incompatibles — le premier qui écrit rend l'autre aveugle).
- ❌ Réécrire ou convertir un `.planning/` existant pour « aligner le format » (ADR-031 : on avertit
  et on propose, l'utilisateur décide).
- ❌ Répondre soi-même à une demande d'état ou d'avancement sur un lab dev, au lieu de rediriger
  vers `/vf-progress`.

---

## Références (chargées on-demand)

- `references/GUIDE.md` — doctrine : tronc commun, anti-biais, adaptation par logique métier, pont mémoire.
- `references/PROFILES.md` — les 3 profils de rigueur + mapping métier → profil.
- `references/bridge-memory.md` — articulation `.planning/` (forward) ↔ registres `.claude/memory/` (capitalisation).
- `references/domain-detection.md` — heuristiques métier → profil + extension, et auto-infusion à l'install.
- `references/example-lab-contenu.md` — exemple complet d'un socle adapté à un lab NON-dev (preuve d'universalité).
- `references/compartments.md` — planning hiérarchique : steering lab + INDEX + plan conditionnel typé (deliverable/continuous), seuil d'autonomie, non-cannibalisation, migration sans perte (v2).
- `references/templates/` — les gabarits universels à instancier (à adapter, jamais à copier tel quel), dont `INDEX.template.md` (lab) + `BOARD.template.md` (compartiment continuous).
- `scripts/check-planning-state.sh` — garde-fou de fraîcheur de la clé de voûte (advisory, exit codes pour hook).
- `references/gsd-handoff.md` — frontière d'altitude avec le moteur de dev : test unique, table de
  redirection intention → verbe, périmètre résiduel sur lab dev, protocole de migration (ADR-055).
- `scripts/detect-planning-debt.sh` — détection de compartiment actif sans plan au-dessus du seuil (advisory).
- `scripts/detect-gsd-engine.sh` — fait vérifiable « un moteur de planning est-il en place » (advisory).
