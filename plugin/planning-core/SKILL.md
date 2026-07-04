---
name: vf-planning
description: >
  Utiliser pour mettre en place ou tenir à jour la gestion de planning, de documentation et de
  contexte d'un lab — quel que soit son métier (dev, contenu, vente, design, montage de dossier,
  recherche…). Se déclenche quand l'utilisateur dit « structure la doc du projet », « mets en
  place le suivi / le planning », « on perd le fil / le contexte », « où on en est ? », « fais-moi
  une feuille de route », « pose le cadre du projet », « initialise le .planning », ou quand un lab
  fraîchement installé n'a pas encore de socle de planning. NE PAS confondre avec le cadrage de
  sprint dev (`vf-plan` du dev-orchestrator) : ce skill pose la STRUCTURE documentaire universelle,
  pas l'exécution dev. Invocable par l'utilisateur ET par un agent en autonomie.
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

## Séquence — Mise en place (`.planning/` absent)

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

## Séquence — Maintenance (`.planning/` déjà là)

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

> L'**automatisation** de cette maintenance (hook SessionEnd, mise à jour auto de STATE) est un
> incrément ultérieur (« moteur »). Ce module v1 pose la **structure** et la **discipline manuelle**.

---

## Garde-fous (anti-biais)

- **Ne jamais plaquer la forme dev** sur un lab non-dev. Pas de `codebase/`, pas de jargon de sprint
  de code si le métier n'est pas le code.
- **Ne jamais imposer le profil complet** par défaut. La rigueur suit le besoin réel du métier.
- **Ne jamais dupliquer la mémoire** : si une info vit déjà dans un registre `.claude/memory/`, on la
  référence, on ne la recopie pas dans `.planning/`.
- **Ne jamais sur-documenter** : le tronc minimal viable (`STATE` + `PROJECT` + `ROADMAP`) suffit pour
  un lab léger. On n'ajoute un artefact que s'il sert.
- **Adapter le vocabulaire** au métier du lab (le projet est francophone — sortie en français).

## Anti-patterns

- ❌ Scaffolder un `.planning/` dev complet sur un lab de contenu « parce que c'est le template ».
- ❌ Créer `REQUIREMENTS.md` + `phases/` pour un lab où le travail n'est pas découpé en exigences.
- ❌ Recopier les entrées DECISIONS dans `PROJECT.md` (doublon mémoire).
- ❌ Démarrer le scaffolding sans avoir lu `CLAUDE.md` / le métier du lab.
- ❌ Laisser `STATE.md` se périmer (c'est la clé de voûte — toujours le rafraîchir).

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
- `scripts/detect-planning-debt.sh` — détection de compartiment actif sans plan au-dessus du seuil (advisory).
