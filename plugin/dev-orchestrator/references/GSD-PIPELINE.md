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
| Livraison | `gsd-ship` | Crée la PR + revue + préparation merge | livraison |
| Clôture milestone | `gsd-new-milestone` / `gsd-complete-milestone` | Ouvre le cycle suivant / archive | jalons |

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
