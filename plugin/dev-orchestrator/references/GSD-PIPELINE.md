# Doctrine pipeline — GSD-PIPELINE.md (chargée on-demand)

> Référence interne de `vibeflow-dev` et `vf-dev-manager`. Chargée à la demande (règle 1%) —
> **jamais** dupliquée dans le corps des agents (charte densité, ≤250L). Source des noms de
> skills : `gsd-skills-index.md` (même dossier d'install :
> `.claude/agents/dev-orchestrator-references/`).
>
> **Vocabulaire** : les briques gsd-* sont l'interface directe (modèle agentique, spec
> 2026-07-25). Leur nom peut apparaître dans les échanges — la clarté prime sur la traduction ;
> rester pédagogue (« la recette » et `gsd-verify-work` peuvent coexister dans une phrase).

---

## 1. Ordre canonique du cycle

L'enchaînement de référence d'un cycle de feature/étape, en briques gsd réelles :

```
gsd-new-project → gsd-map-codebase → gsd-discuss-phase → gsd-plan-phase → gsd-execute-phase → gsd-verify-work → gsd-code-review → gsd-ship → milestones (gsd-new-milestone / gsd-complete-milestone)
```

| Étape | Brique gsd | Rôle | En clair |
|-------|-----------|------|----------|
| Amorçage projet | `gsd-new-project` | Initialise PROJECT.md (interactif) | démarrage de projet |
| Cartographie | `gsd-map-codebase` | Analyse parallèle → `.planning/codebase/` | cartographie du code |
| Cadrage étape | `gsd-discuss-phase` | Récolte le contexte par questions | cadrage |
| Planification | `gsd-plan-phase` | Produit PLAN.md + boucle de vérif | plan de sprint |
| Implémentation | `gsd-execute-phase` | Exécute les plans (waves parallèles) | sprint d'implémentation |
| Validation UAT | `gsd-verify-work` | Valide les features (UAT conversationnel) | recette |
| Revue de code | `gsd-code-review` | Relit les fichiers modifiés (bugs/sécu) | revue de code |
| Livraison | `gsd-ship` | Crée la PR + revue + préparation merge — **non emprunté chez VibeFlow**, l'ouverture de PR reste un geste VibeFlow tenu à la main par le manager de mission (ADR-059, ADR-064) | livraison |
| Clôture milestone | `gsd-new-milestone` / `gsd-complete-milestone` | Ouvre le cycle suivant / archive | jalons |

> **Pourquoi `gsd-ship` reste dans la table sans être emprunté (D-21).** C'est un outil réel du
> moteur, il garde sa place dans le cycle canonique — mais ADR-059 (une mission = une branche) et
> ADR-064 (un écrivain = un worktree, claim de driver) priment, et la brique amont ne connaît ni
> l'une ni l'autre. Le protocole d'isolation et d'ouverture de PR vit dans `mission-contracts.md`
> §Isolation de branche : il n'est jamais recopié ici.

**Règle d'or** : on ne saute pas `gsd-verify-work` ni `gsd-code-review` sur une feature
structurante. Le cadrage (`gsd-discuss-phase`) précède toujours la planification
(`gsd-plan-phase`).

---

## 2. Chemin autonome

`gsd-autonomous` enchaîne **seul** le cycle restant : pour chaque étape, il fait
`discuss → plan → execute` (+ tests) sans intervention humaine intermédiaire. Le skill
`vf-auto` est la porte d'entrée de ce mode : il applique le seuil d'équipe
(`SEUIL_EQUIPE`, cf. `mission-contracts.md`) pour choisir entre `gsd-autonomous` inline
et la délégation à l'équipe (`Task(vf-dev-manager)`).

**Quand l'employer** :
- L'utilisateur dit « fais tout », « en autonomie », « laisse tourner la nuit », « débrouille-toi ».
- Le périmètre est cadré (PROJECT.md + ROADMAP.md existent) et l'utilisateur accepte de ne pas
  valider chaque étape.

**Quand l'éviter** :
- Aucun cadrage initial (passer d'abord par `gsd-discuss-phase` / `gsd-plan-phase`).
- Décision structurante non tranchée (architecture, choix de lib) → clarifier avant (P4).

---

## 3. Escape hatches (court-circuiter le pipeline)

Pour le trivial, ne pas payer le coût du pipeline complet :

| Brique | Quand | Garanties |
|-------|-------|-----------|
| `gsd-quick` | Petite tâche bien définie | Commits atomiques + suivi d'état, sans agents optionnels |
| `gsd-fast` | Tâche triviale (typo, renommage) | Exécution inline, aucun subagent, zéro overhead de planification |

Heuristique : si la tâche tient en un commit et ne touche pas l'architecture → `gsd-fast`/`gsd-quick`.
Sinon → pipeline complet (au minimum `gsd-plan-phase → gsd-execute-phase → gsd-verify-work`).

---

## 4. Quand faire `/clear`

Repartir d'une fenêtre de contexte fraîche entre deux étapes lourdes pour éviter la pollution :

- Entre deux étapes d'implémentation distinctes (après `gsd-verify-work` / `gsd-ship`).
- Après une longue session de debug (`gsd-debug`) avant de reprendre l'implémentation.
- Quand le contexte dépasse ~50% et que l'étape suivante est indépendante.

Ne **pas** `/clear` au milieu d'une étape en cours (perte du fil d'exécution) — préférer
`gsd-pause-work` / `gsd-resume-work` pour un handoff propre si une pause est nécessaire.

---

## 5. Model profiles (rappel rapide)

Trois rôles, trois profils (configurables via `gsd-config` / `gsd-settings`) :

| Rôle | Profil typique | Usage |
|------|----------------|-------|
| **Planner** | modèle fort (opus) | `gsd-discuss-phase`, `gsd-plan-phase` — raisonnement, découpage |
| **Executor** | modèle équilibré (sonnet) | `gsd-execute-phase` — implémentation des tasks |
| **Checker** | modèle équilibré (sonnet) | `gsd-verify-work`, `gsd-code-review` — vérification |

Les agents `vibeflow-dev` et `vf-dev-manager` tournent en `opus` (détection d'intention +
pilotage) ; les workers d'équipe (`vf-coder`, `vf-reviewer`, `vf-auditer`) en `sonnet`.

---

## 6. Garde-fous

- **`gsd-new-project` est interactif** (BOOT-04) : il pose de nombreuses questions et écrit
  PROJECT.md. **Jamais lancé seul / en autonomie.** Le proposer uniquement sur confirmation
  explicite de l'utilisateur (« je veux démarrer un nouveau projet »).
- **Toujours déléguer** : les agents ne réimplémentent jamais la logique d'une brique — ils
  détectent l'intention et invoquent la brique outillée qui la porte.
- **Action structurante** : clarifier (P4) avant, vérifier (P5) après. Pas de raccourci sur
  `gsd-verify-work` / `gsd-code-review` pour une feature non triviale.
- **Fermer la boucle** : après chaque geste, proposer LE next step depuis `ROADMAP`/`STATE`
  (rôle actif des agents — pas un menu, une proposition ferme).
- **L'ouverture de PR est un geste VibeFlow** : jamais déléguée à `gsd-ship` tant qu'ADR-059 (une
  mission = une branche) et ADR-064 (un écrivain = un worktree) tiennent. Protocole :
  `mission-contracts.md` §Isolation de branche.

---

## 7. Briques connexes utiles (hors cycle canonique)

| Besoin ponctuel | Brique |
|-----------------|-------|
| Débugger un incident persistant (recherche doc d'abord — ADR-045) | `gsd-debug` |
| Brainstormer une idée en amont | superpowers `brainstorming` (plugin) |
| Savoir où on en est / la suite | `gsd-progress` |
| Reprendre une session interrompue | `gsd-resume-work` / `gsd-pause-work` |

> Pour la liste exhaustive et à jour des briques disponibles, consulter
> `.claude/agents/dev-orchestrator-references/gsd-skills-index.md` ; pour le routage
> intention → brique, `intent-routing.md` (seule source de routage).

> **Qui décide de ce qui s'exécute — la question du Constat 0.** La bonne question n'était pas
> « l'agent a-t-il accès aux étages du cycle », mais « qui les déclenche ». Réponse : aux points
> de hook du cycle, le moteur **insère lui-même** ses étages selon les toggles du lab. Un agent
> ne les « choisit » pas ; il ne peut qu'en activer la condition. La table point par point
> (capability, nature, toggle gouvernant, bloquant, conduite sur erreur) vit dans
> `.claude/agents/dev-orchestrator-references/gsd-capabilities-index.md`. Elle est
> **auto-générée** depuis le registre du moteur installé — ne jamais l'éditer à la main ; la
> régénérer avec `build-gsd-capabilities-index.sh`. Elle énumère ce que le moteur **déclare** à
> la version depuis laquelle elle a été produite, et jamais l'état effectif d'un lab : cet
> état-là se lit avec `gsd-tools loop render-hooks <point> --raw`, pas dans ce fichier.

---

## 8. Frontière : `model:` (agents vf-*) vs `model_profile` (sous-agents gsd-*)

Deux couches indépendantes, ne pas les confondre :
- Le frontmatter `model:` des agents `vf-*` (processus Claude Code — `vibeflow-dev`, `vf-coder`,
  `vf-dev-manager`…) fixe le modèle du **processus orchestrateur/worker**.
- `model_profile` (`.planning/config.json`, défaut `balanced`) fixe le modèle des **sous-agents
  gsd-*** invoqués par ce processus (`gsd-planner`, `gsd-executor`, `gsd-verifier`…).

La chaîne `vf-coder (sonnet) → gsd-plan-phase → gsd-planner (opus)` est le comportement **voulu**
— un worker sonnet peu coûteux qui délègue la planification à un sous-agent opus plus capable,
pas une incohérence à corriger.

---

## 9. Flags de cycle — allowlist stricte

**Fermeture par défaut (D-08).** Seuls les flags **nommés dans la table ci-dessous** sont
utilisables par un agent du module sur une brique de cycle : **tout flag non nommé est fermé par
défaut**, y compris ceux que `gsd-core` ajoutera dans une version ultérieure. Le corollaire est ce
qui a de la valeur ici — un flag nouveau arrive **fermé**, et il s'ouvre par une décision datée
inscrite dans cette table, jamais par omission. Une liste d'interdits seuls périmerait à la
première montée de version : elle laisserait gagner l'omission, exactement le pilotage que cette
doctrine referme.

| Brique de cycle | Flags autorisés | Flags fermés | Motif (fait + source vérifiable) |
|---|---|---|---|
| Cadrage — `gsd-discuss-phase` | `--auto` | `--chain`, et tout autre | **Transitoire — périme au plan 23-05.** `--auto` déclenche ici le pipeline entier (`chain.md:45-61`, étape 5), donc la règle 5 de `checkpoints.md:11` sur tout ce qui suit, bornée par la règle 6 (`checkpoints.md:12`). Ouvert faute d'`AskUserQuestion` chez `vf-coder` ; raisonnement complet et coût chiffré : note « `--auto` au cadrage » sous la table. `--chain` fermé pour le même fait, aggravé — il ouvre le mode interactif. |
| Plan — `gsd-plan-phase` | `--research`, `--skip-research` | `--auto`, `--chain`, et tout autre | La gradation de la recherche se décide **ici**, et nulle part ailleurs : `gsd-discuss-phase` n'en consomme aucun flag (sa table `progressive_disclosure` de `discuss-phase.md` n'en liste aucun). Sur une phase neuve et en l'absence des deux, le workflow **prompte** (`plan-phase.md` §5.1) et `vf-coder`, privé d'`AskUserQuestion`, y reste bloqué : le flag n'est donc jamais omis — borne de ce « jamais » en note sous la table. `--auto` et `--chain` fermés en invocation directe, même fait qu'au cadrage (`chain.md:45-61` + règle 5 de `checkpoints.md:11`, bornée par la règle 6 de `checkpoints.md:12`). |
| Exécution — `gsd-execute-phase` | *(aucun)* | `--auto`, `--chain`, et tout autre | Même fait qu'au cadrage (`chain.md:45-61` + règle 5 de `checkpoints.md:11`, bornée par la règle 6 de `checkpoints.md:12`). De surcroît, exécuter au-delà de la frontière du nœud contredirait le pipelining modélisé dans `mission-flow.md` : le manager tient le DAG, l'exécution ne le déborde pas. |

**`--auto` au cadrage — pourquoi il reste ouvert, et jusqu'à quand (D-06)** : sur cette brique,
`--auto` ne pose pas seulement un état, il déclenche le pipeline entier — cadrage → plan →
exécution dans le même appel (`chain.md:45-61`, étape 5). La **règle 5** de `checkpoints.md:11` joue
donc sur tout le plan et toute l'exécution qui suivent : vérification humaine **auto-approuvée**,
décision **auto-sélectionnée sur la première option**. Portée **bornée**, à ne pas surestimer : la
**règle 6** (`checkpoints.md:12`) protège les gates `gate="blocking-human"`, jamais auto-approuvés,
même en auto-mode. Reste ouvert aujourd'hui parce que `vf-coder` n'a pas `AskUserQuestion` : le
fermer maintenant le mettrait en impasse, constatée et chiffrée en `23-ARBITRAGES-OUVERTS.md` §O-8
(voie 2). Autorisation **assumée par écrit**, coût nommé, plutôt qu'accordée en silence. Correctif
structurel instruit au **plan 23-05** (le manager porte le cadrage, il a `AskUserQuestion`) : le
jour où 23-05 passe, cette ligne devient fermée.

**Gradation de la recherche (D-05) — sur un FAIT constatable, jamais sur un ressenti (ADR-055 §3)** :

- `--research` quand l'étape touche une **lib, un framework, du natif ou une version**, ou un
  domaine que `.planning/codebase/` ne cartographie pas.
- `--skip-research` quand l'étape prolonge un périmètre **déjà couvert** par un `RESEARCH.md` ou un
  `CONTEXT.md` récent du même dossier de phase.

Borne du « le flag n'est jamais omis » de la ligne Plan : la branche de prompt de `plan-phase.md`
§5.1 est gardée par « **RESEARCH.md missing** » (`plan-phase.md:329-331`). Un `RESEARCH.md` déjà
présent est réutilisé **sans prompt**, flag ou pas — le garde-fou ne joue donc que sur une phase
neuve, cas opératoire de `vf-coder`. Sur une phase reprise, c'est à toi de trancher explicitement.

**Toggle ≠ flag** — la confusion la plus probable à la lecture, nommée ici plutôt que laissée au
lecteur : le toggle `workflow.research` du `config.json` active la **capability** de recherche sur
le point de hook de pré-plan (le moteur spawne lui-même son chercheur) ; le flag, lui, répond au
**prompt**. Toggle à vrai ⇒ la recherche a lieu de toute façon, le flag décide seulement si le
worker se fait interroger. Deux couches distinctes, pas interchangeables.

**Flags documentaires** : leur doctrine est `docs-flow.md`, jamais recopiée ici (ADR-057).
Elle fait autorité sur sa famille — une capacité, une seule voix.
