# Doctrine pipeline — GSD-PIPELINE.md (chargée on-demand)

> Référence interne de `vibeflow-dev`. Chargée à la demande (règle 1%) — **jamais** dupliquée dans
> le corps de l'agent (charte densité, ≤250L). Source des noms de skills : `gsd-skills-index.md`
> (même dossier d'install : `.claude/agents/dev-orchestrator-references/`).
>
> **Rappel persona** : ce détail est interne. L'utilisateur ne voit jamais « GSD » ni les noms
> bruts de skills — toujours reformuler en vocabulaire VibeFlow (sprint, feuille de route, etc.).

---

## 1. Ordre canonique du pipeline

L'enchaînement de référence d'un cycle de feature/phase :

```
new-project → map-codebase → discuss-phase → plan-phase → execute-phase → verify-work → code-review → ship → complete-milestone
```

| Étape | Skill réel | Rôle | Vocabulaire VibeFlow |
|-------|-----------|------|----------------------|
| Amorçage projet | `gsd-new-project` | Initialise PROJECT.md (interactif) | « démarrage de projet » |
| Cartographie | `gsd-map-codebase` | Analyse parallèle → `.planning/codebase/` | « cartographie du code » |
| Cadrage phase | `gsd-discuss-phase` | Récolte le contexte par questions | « cadrage » |
| Planification | `gsd-plan-phase` | Produit PLAN.md + boucle de vérif | « plan de sprint » |
| Implémentation | `gsd-execute-phase` | Exécute les plans (waves parallèles) | « sprint d'implémentation » |
| Validation UAT | `gsd-verify-work` | Valide les features (UAT conversationnel) | « recette » |
| Revue de code | `gsd-code-review` | Relit les fichiers modifiés (bugs/sécu) | « revue de code » |
| Livraison | `gsd-ship` | Crée la PR + revue + préparation merge | « livraison » |
| Clôture milestone | `gsd-complete-milestone` | Archive et prépare la version suivante | « clôture de jalon » |

**Règle d'or** : on ne saute pas `verify-work` ni `code-review` sur une feature structurante.
Le cadrage (`discuss-phase`) précède toujours la planification (`plan-phase`).

---

## 2. Chemin autonome

`gsd-autonomous` enchaîne **seul** le cycle restant : pour chaque phase, il fait
`discuss → plan → execute` (+ tests) sans intervention humaine intermédiaire.

**Quand l'employer** :
- L'utilisateur dit « fais tout », « en autonomie », « laisse tourner la nuit », « débrouille-toi ».
- Le périmètre est cadré (PROJECT.md + ROADMAP.md existent) et l'utilisateur accepte de ne pas
  valider chaque phase.

**Quand l'éviter** :
- Aucun cadrage initial (passer d'abord par `discuss-phase` / `plan-phase`).
- Décision structurante non tranchée (architecture, choix de lib) → clarifier avant (P4).

---

## 3. Escape hatches (court-circuiter le pipeline)

Pour le trivial, ne pas payer le coût du pipeline complet :

| Skill | Quand | Garanties |
|-------|-------|-----------|
| `gsd-quick` | Petite tâche bien définie | Commits atomiques + suivi d'état, sans agents optionnels |
| `gsd-fast` | Tâche triviale (typo, renommage) | Exécution inline, aucun subagent, zéro overhead de planification |

Heuristique : si la tâche tient en un commit et ne touche pas l'architecture → `gsd-fast`/`gsd-quick`.
Sinon → pipeline complet (au minimum `plan-phase → execute-phase → verify-work`).

---

## 4. Quand faire `/clear`

Repartir d'une fenêtre de contexte fraîche entre deux étapes lourdes pour éviter la pollution :

- Entre deux phases d'implémentation distinctes (après `verify-work` / `ship`).
- Après une longue session de debug (`gsd-debug`) avant de reprendre l'implémentation.
- Quand le contexte dépasse ~50% et que l'étape suivante est indépendante.

Ne **pas** `/clear` au milieu d'une phase en cours (perte du fil d'exécution) — préférer
`gsd-pause-work` / `gsd-resume-work` pour un handoff propre si une pause est nécessaire.

---

## 5. Model profiles (rappel rapide)

Trois rôles, trois profils (configurables via `gsd-config` / `gsd-settings`) :

| Rôle | Profil typique | Usage |
|------|----------------|-------|
| **Planner** | modèle fort (opus) | `discuss-phase`, `plan-phase` — raisonnement, découpage |
| **Executor** | modèle équilibré (sonnet) | `execute-phase` — implémentation des tasks |
| **Checker** | modèle équilibré (sonnet) | `verify-work`, `code-review` — vérification |

L'agent `vibeflow-dev` lui-même tourne en `opus` (routage + raisonnement NL).

---

## 6. Garde-fous

- **`gsd-new-project` est interactif** (BOOT-04) : il pose de nombreuses questions et écrit
  PROJECT.md. **Jamais lancé seul / en autonomie.** Le proposer uniquement sur confirmation
  explicite de l'utilisateur (« je veux démarrer un nouveau projet »).
- **Toujours déléguer** : `vibeflow-dev` ne réimplémente jamais la logique d'un skill — il route.
- **Action structurante** : clarifier (P4) avant, vérifier (P5) après. Pas de raccourci sur
  `verify-work` / `code-review` pour une feature non triviale.
- **Vocabulaire** : aucune fuite de « GSD » / « Superpowers » ni de noms de skills bruts vers
  l'utilisateur — toujours reformuler en termes VibeFlow.

---

## 7. Skills connexes utiles (hors cycle canonique)

| Besoin ponctuel | Skill |
|-----------------|-------|
| Débugger un incident persistant | `gsd-debug` |
| Brainstormer une idée en amont | superpowers `brainstorming` (plugin) |
| Savoir où on en est / la suite | `gsd-progress` |
| Reprendre une session interrompue | `gsd-resume-work` / `gsd-pause-work` |

> Pour la liste exhaustive et à jour des skills disponibles, consulter
> `.claude/agents/dev-orchestrator-references/gsd-skills-index.md`.
