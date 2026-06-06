# Pattern 09 — Meta-procedures (NOUVEAU v4.1)

## Quoi

Une **meta-procedure** est une sequence formelle de phases verifiables qui encapsule la rigueur methodologique. Plutot que de demander a un agent (ou a un humain) d'appliquer "les principes VibeFlow", on lui demande d'executer une procedure precise qui materialise ces principes pas a pas.

VibeFlow v4.1 introduit deux meta-procedures canoniques :

| Procedure | Portee | Usage typique |
|-----------|--------|---------------|
| `safe-execute` | Mono-tache complexe avec humain present | Refactor important, fusion documents, redaction meta-prompt |
| `god-execution` | Multi-sprints autonome sans humain dans la boucle | Marathon nocturne, livraison de plusieurs sprints en delegation totale |

## Pourquoi

Sans procedure, un agent (ou un humain presse) **saute des etapes**. Il commence par implementer avant de clarifier. Il declare la completion sans verifier. Il extend le scope silencieusement.

Resultat : derive, retouches, dette accumulee.

Avec une meta-procedure, chaque phase a une **sortie verifiable**. On ne passe pas a la phase suivante sans avoir produit la sortie de la phase courante. La rigueur n'est plus un effort de discipline  -  c'est une contrainte du processus.

C'est l'equivalent, pour le pilotage de projet, de la check-list d'avant decollage en aviation : chaque element est verifie explicitement, pas par habitude.

## Comment

### 1. `safe-execute`  -  5 phases mono-tache

**Quand l'utiliser** : tache complexe unitaire ou l'enjeu justifie une rigueur extreme.

| Phase | Question | Sortie attendue |
|-------|----------|-----------------|
| **1. Clarifier** | Le besoin est-il sans ambiguite ? | Liste des hypotheses + questions explicites |
| **2. Planifier** | Quelle decomposition en sous-taches ? | Plan ordonne avec criteres binaires |
| **3. Verifier le plan** | Le plan est-il correct AVANT execution ? | Validation explicite (humaine ou peer agent) |
| **4. Implementer** | Execution pas a pas. | Livrables incrementaux |
| **5. Verifier l'implementation** | Chaque livrable respecte-t-il le critere ? | Fresh evidence (exit code, output) |

**Iron Law** : aucune phase ne saute. Si la clarification revele une ambiguite, on n'avance pas. Si le plan ne tient pas, on replanifie.

### 2. `god-execution`  -  8 phases multi-sprints autonome

**Quand l'utiliser** : execution autonome sur plusieurs cycles sans humain dans la boucle a chaque etape. **Reserve aux taches dont l'echec est reversible**.

| Phase | Role |
|-------|------|
| **1. Investigation** | Lire les registres existants, inventorier les dependances |
| **2. Deep Research** | Recherche multi-sources sur les zones inconnues |
| **3. Plan** | Decomposition complete en sprints (DAG explicite + criteres binaires) |
| **4. Plan-Review (Adversarial)** | 2 agents distincts en sessions fraiches + Judge si divergence > 2 points (Pattern 10) |
| **5. Execution** | Sprint par sprint, atomic commits, context reset entre sprints |
| **6. Verification Code + Tests** | Exit code 0 sur les gates techniques |
| **7. Verification Visuelle** | Si livrable visible (UI, contenu) : snapshot + comparaison vs critere |
| **8. Commit + Loop** | Capitaliser puis boucler ou s'arreter selon halt conditions (Pattern 11) |

**Iron Law** : si une halt condition est declenchee, arret immediat et escalation humaine.

### Quand utiliser quoi

| Situation | Procedure |
|-----------|-----------|
| Tache complexe unique avec humain present | `safe-execute` |
| Tache repetitive simple avec humain present | Workflow standard (skip meta-procedure) |
| Execution autonome multi-sprints, enjeux reversibles | `god-execution` |
| Execution autonome avec enjeux irreversibles | INTERDIT  -  toujours garder humain dans la boucle |

### Iron Laws transversales aux 2 meta-procedures

1. **Pas de saut de phase**  -  chaque phase a une sortie verifiable. Sauter = creer une dette.
2. **Pas de claim sans fresh evidence**  -  aucune declaration de completion sans preuve produite dans la session courante.
3. **Pas d'auto-evaluation aveugle**  -  pour les decisions structurantes, le verificateur ne doit pas etre l'agent qui a produit (eviter l'echo chamber).
4. **Pas de scope creep**  -  le plan valide en phase de Verification est le contrat. Toute extension declenche une re-validation.

## Exemple fictif

> **Sophie K., professeure de musique freelance**, demande a son agent `course-planner` de preparer un programme pedagogique complet pour son nouvel eleve adulte qui veut apprendre le piano jazz en 6 mois. L'enjeu est important (perte de l'eleve si le programme est decevant) mais l'execution est mono-tache.

**Choix de procedure** : `safe-execute` (mono-tache complexe).

**Application** :

```markdown
## Phase 1  -  Clarifier
Hypotheses :
- L'eleve a 0 base en jazz mais sait lire le solfege (a confirmer)
- Le materiel disponible : piano acoustique chez lui
- Temps de pratique declare : 30 min/jour (a verifier)

Questions a l'eleve avant planification :
1. Niveau actuel en piano classique ?
2. Standards jazz prefere (Miles, Coltrane, autre) ?
3. Objectif a 6 mois mesurable (1 standard joue, 3 standards, jam session...) ?

## Phase 2  -  Planifier
Plan en 6 mensualites :
- M1 : Harmonie de base (II-V-I, accords 7emes) - critere : peut nommer les 7 accords 7emes de Do majeur
- M2 : Walking bass main gauche - critere : peut walking sur une grille blues en Sib
[...]

## Phase 3  -  Verifier le plan
Validation Sophie : OK, sauf M3 trop dense (deplacer 50% en M4).

## Phase 4  -  Implementer
Programme reecrit avec ajustement M3/M4.
Generation des 6 fiches mensuelles + supports audio + grille de standards.

## Phase 5  -  Verifier l'implementation
- [x] 6 fiches produites (verifier presence : ok, 6 fichiers MD)
- [x] Standards selectionnes coherents avec le niveau (cross-check avec base "piano-jazz-pedagogie")
- [x] Critere mesurable par mois explicite (lire chaque fiche : ok)
- [x] Pas de doublon entre mois (diff structure : ok)
```

Resultat : le programme est livre en une session, sans retouches. L'eleve recoit un parcours coherent et progressif.

## Anti-patterns

- **Sauter la phase Clarifier** : "je commence, on verra en route" → ambiguites decouvertes en phase 4, retouches majeures
- **Verifier le plan apres l'avoir execute** : la verification arrive trop tard, le scope a deja derive
- **Verifier soi-meme son propre plan** (en autonomie) : echo chamber, biais d'automatisation, pas d'angle critique
- **Declarer "fait" sans fresh evidence** : "il me semble que ca marche" → false memory + responsabilite floue
- **Utiliser `god-execution` sur des taches irreversibles** : suppression de fichiers production, deploiements, envois de masse

## Quand creer ta propre meta-procedure

Quand un workflow se repete au moins **3 fois** avec la meme structure et beneficierait d'une formalisation en phases verifiables, creer une meta-procedure dediee (par exemple : `client-onboarding`, `content-publishing`, `sprint-closing`).

Critere de mise sous procedure :
- La sequence est repetable (pas une exception)
- Sauter une phase produit observablement une perte de qualite
- Chaque phase a une sortie verifiable en termes binaires

Si la sequence est triviale (< 3 phases) ou rarement utilisee, ne pas formaliser  -  garder en workflow ad hoc.
