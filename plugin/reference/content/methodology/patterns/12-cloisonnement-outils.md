# Pattern 12 — Cloisonnement par outils

## Quoi

Le **cloisonnement par outils** consiste à restreindre ce qu'un agent *peut faire*
directement au niveau de son frontmatter `tools:`, et non seulement par des consignes dans
son corps. Le principe tient en deux règles :

- **Un juge n'écrit jamais.** Un agent de revue ou d'audit (reviewer, validator, auditer) a
  `Read, Bash, Glob, Grep, Task` — **jamais** `Write` ni `Edit`. Il constate, il ne modifie pas.
- **Un worker n'escalade jamais.** Un agent qui modifie du code (correcteur, exécutant) a
  `Read, Edit, Write, Bash, Glob, Grep` — **jamais** `Task`. Il agit dans son périmètre, il ne
  se délègue pas à lui-même de nouveaux sous-agents.

C'est un complément du Pattern 03 (Agents) : là où le Pattern 03 définit *le mandat*, le
Pattern 12 rend certaines transgressions **techniquement impossibles**, pas seulement
interdites en prose.

## Pourquoi

Une contrainte écrite dans le corps d'un agent (« ne touche jamais aux tests ») est une
**consigne**, pas une **garantie** : sous pression (boucle autonome, échec répété), un modèle
peut la contourner en se convainquant que « c'est le plus simple ». Retirer l'outil supprime
la tentation à la racine.

Deux risques concrets que ça neutralise :

1. **La triche** — un agent chargé de « rendre les tests verts » qui, faute de savoir corriger
   le code, **affaiblit l'assert**. Si l'agent n'a pas le droit d'écrire dans les tests, cette
   sortie est fermée. (C'est le support technique du garde-fou anti-triche des boucles
   autonomes — voir `dev-orchestrator/references/autonomous-guardrails.md`.)
2. **L'escalade incontrôlée** — un worker qui, au lieu de faire son travail, spawn en cascade
   des sous-agents et fait exploser le coût/contexte. Sans `Task`, il reste dans son couloir.

**Défense en profondeur** : le cloisonnement `tools:` est la première ligne, doublée par les
règles de domaine dans le corps. Le système de fichiers n'est pas une garantie dure (un agent
avec `Bash` peut techniquement écrire via `Bash`) — d'où la double barrière : outil **plus**
consigne.

## Comment

### Grille de référence

| Type d'agent | Rôle | `Write`/`Edit` | `Task` | Ensemble d'outils type |
|--------------|------|:--------------:|:------:|------------------------|
| **Juge** (reviewer, auditer, validator) | Constate, note, recommande | ❌ | ✅ | `Read, Bash, Glob, Grep, Task` |
| **Worker** (correcteur, exécutant) | Modifie un périmètre précis | ✅ | ❌ | `Read, Edit, Write, Bash, Glob, Grep` |
| **Lead / orchestrateur** | Planifie, décide, distribue | selon mandat | ✅ | outils hérités, ne produit pas lui-même |

### Règles d'or

1. **Choisis le type avant les outils.** Juge ou worker ? Le type dicte l'ensemble d'outils,
   pas l'inverse.
2. **Le minimum nécessaire.** Un agent ne reçoit que les outils que son mandat exige. En cas
   de doute, retire — on peut toujours ajouter plus tard.
3. **Deux périmètres d'écriture ≠ un agent.** Si deux workers doivent écrire dans deux zones
   qui ne doivent jamais se mélanger (ex. code applicatif vs tests), ce sont **deux agents**,
   chacun cloisonné sur sa zone. La distinction fine de chemins est portée par le corps.
4. **Double barrière.** Outil retiré **ET** consigne dans le corps. Jamais l'un sans l'autre.
5. **Allowlist de dispatch.** Un orchestrateur ne reçoit pas un droit de dispatch *générique* : il
   déclare **la liste exacte** des agents qu'il peut lancer, via `tools: …, Agent(worker-a, worker-b)`.
   Il ne peut alors spawner que ces workers-là, pas un agent arbitraire. C'est la forme forte du
   couloir : le lead ne convoque que son équipe.

> **Limite connue (Claude Code, 2026)** : il n'existe **pas** de champ frontmatter natif rendant un
> agent « interne seulement » (invocable par un autre agent mais jamais auto-délégué). `deny`
> bloquerait aussi le dispatch légitime. La parade documentée = **allowlist côté orchestrateur**
> (règle 5) **+ description dissuasive** du worker (« worker interne, dispatché uniquement par X »).
> C'est une heuristique robuste, pas une barrière dure — à garder en tête.

## Exemple fictif

> **Atelier Demo (micro-studio créatif fictif) automatise sa boucle de contrôle qualité.**

Deux agents, cloisonnés :

```markdown
---
name: qa-reviewer          # JUGE
tools: [Read, Bash, Glob, Grep, Task]
---
Relit les livrables, produit un verdict PASS / RETOUR. Ne modifie jamais un fichier.
```

```markdown
---
name: asset-fixer          # WORKER
tools: [Read, Edit, Write, Bash, Glob, Grep]
---
Corrige les assets signalés par le reviewer. Ne relit jamais, n'escalade jamais.
```

Résultat : `qa-reviewer` **ne peut pas** « corriger vite fait » ce qu'il devrait signaler
(il n'a pas `Write`), et `asset-fixer` **ne peut pas** lancer une cascade de sous-agents
(il n'a pas `Task`). La séparation producteur/juge du Pattern 03 devient structurelle.

## Anti-patterns

- **Le juge qui corrige** : un reviewer avec `Write` finit toujours par « corriger au passage »
  → il devient juge et partie, la revue perd sa valeur.
- **Le worker omnipotent** : un correcteur avec `Task` → cascades imprévues, coût qui dérape.
- **La consigne seule** : « ne touche jamais aux tests » sans retirer l'outil → tenue tant que
  c'est facile, contournée sous pression.
- **Un agent, deux zones sensibles** : le même agent qui écrit le code ET les tests → porte
  ouverte à la triche. Séparer.

## Quand appliquer

Systématiquement dès qu'un agent **écrit** ou **juge**, et **impérativement** dans toute
**boucle autonome** (le cloisonnement y est le support technique des garde-fous anti-triche —
voir Pattern 11 Halt conditions et la doctrine des boucles autonomes).

> **Note de statut** : ce pattern formalise une convention adoptée par VibeFlow. Sa
> promotion en décision numérotée (ADR) dépend du registre ADR canonique du lab —
> à confirmer lors de la prochaine consolidation mémoire.
