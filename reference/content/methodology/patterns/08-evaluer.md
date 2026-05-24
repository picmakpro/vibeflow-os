# Pattern 08 — Evaluer (Principe 8)

## Quoi

L'**evaluation** (P-Evaluer, principe 8) est la discipline qui mesure en continu la qualite cognitive des outputs produits par l'IA et les agents : hallucinations, biais d'ancrage, derives silencieuses, pertinence dans le temps.

C'est le **principe 8 de VibeFlow**, ajoute en v4.0 du Core. Il s'incarne dans un nouveau registre : **EVALS.md**.

## Pourquoi

Les 7 premiers principes structurent le travail (constituer, capitaliser, transposer...). P-Evaluer repond a une question differente : *"le raisonnement produit par mon systeme est-il toujours le bon, ou est-ce que je l'utilise par habitude ?"*

L'hallucination n'est pas un bug. C'est une propriete statistique des LLMs : la capacite a produire un raisonnement assure et faux est leur mode de fonctionnement, pas un defaut.

Sans evaluation systematique :
- Une BDR signee machinalement apres 30 secondes (biais d'automatisation)
- Un template cree il y a 6 mois qui reflete des prix, des regles, un contexte obsoletes
- Un agent qui produit des outputs "bons selon sa rubrique interne" mais la rubrique a derive
- Une analyse acceptee sans verifier les chiffres ou les sources citees

Avec evaluation :
- Chaque output critique est cross-checke (LLM-as-Judge, second humain, ou confrontation a la realite)
- Les derives sont detectees tot, pas decouvertes 6 mois plus tard
- Les criteres de qualite sont revisites au lieu de figer
- Les hallucinations laissent une trace (EVAL-XXX) au lieu de passer inapercues

### Pourquoi P8 n'est pas P5 (Verifier)

| Principe | Question repondue |
|----------|-------------------|
| **P5 Verifier** | Le livrable respecte-t-il les regles formelles ? (tests passent, syntaxe valide, faits existent, coherence interne) |
| **P8 Evaluer** | Le raisonnement produit est-il le bon ? (pas hallucine, pas biaise par le framing, toujours pertinent dans le temps) |

Un output peut passer P5 (techniquement correct) et echouer P8 (contenu hallucine ou desuet). Les deux principes sont complementaires, pas redondants.

## Comment

### Les 3 types de derive a detecter

| Type de derive | Exemple concret | Detection |
|----------------|-----------------|-----------|
| **Hallucination factuelle** | Un agent cite une API qui n'existe pas, invente un chiffre, imagine une reference legale | Cross-check avec la source (recherche web, second LLM, MCP officiel) |
| **Biais d'ancrage ou framing** | L'output reflete plus le prompt que la realite ("tu penses que c'est bien, non ?" genere une validation) | Re-formuler la question sans biais, comparer les outputs |
| **Derive silencieuse dans le temps** | Un template cree il y a 6 mois reflete des conditions obsoletes (prix changes, regles legales evoluees) | Revue trimestrielle avec relecture critique |

### Les 3 methodes d'evaluation (du plus simple au plus rigoureux)

**Methode 1 : LLM-as-Judge (automatise)**

Un second LLM evalue la sortie d'un premier selon une rubrique.

Exemple : un agent Sonnet produit une proposition commerciale. Un appel Opus evalue la proposition selon 5 criteres (clarte, conformite au positionnement, absence de promesses non fondees, ton, coherence prix). Score 4/5 minimum pour validation.

Cout : faible (~1 token par output). Limite : le second LLM peut aussi halluciner sur les memes biais.

**Methode 2 : Cross-check humain sur echantillon**

Sur tous les outputs d'une categorie, en relire 1 sur 10 avec oeil critique.

Exemple : sur 10 scripts de lecon produits, en relire 1 completement pour detecter les derives stylistiques ou pedagogiques.

Cout : temps humain. Limite : l'echantillonnage peut rater une derive isolee.

**Methode 3 : Confrontation a la realite (post-hoc)**

30 jours apres une decision structurante, confronter la prediction a la realite observee.

Exemple : une BDR prevoit 50 ventes beta en 6 semaines. A J+42, que dit la realite ? Si l'ecart est > 30%, une entree EVAL documente la derive et ajuste la methodologie.

Cout : discipline (c'est le plus dur a maintenir). Limite : retrospectif, pas preventif.

### Frequence recommandee

| Type d'output | Frequence P-Evaluer |
|---------------|---------------------|
| Decision structurante (BDR) | Confrontation realite a J+30 |
| Prediction quantitative (KPI, plan) | J+30, J+60, J+90 |
| Template ou contenu produit | Trimestriel |
| Script agentique (agent, skill) | A chaque update majeur |
| Output cumulatif (docs, contrats) | Semestriel |
| Output critique (production publique) | Mensuel minimum |

### Format d'une entree EVALS.md

```markdown
## EVAL-XXX : [Titre court]

**Date** : YYYY-MM-DD
**Output evalue** : [path du fichier OU description : "BDR-017 prevision 50 ventes beta"]
**Contexte** : [quand l'output a ete produit]
**Methode eval** : LLM-as-Judge | Cross-check humain | Confrontation realite | Manuelle structuree
**Score qualitatif** : [rubrique + score]

### Anomalies detectees
- [liste des derives, hallucinations, biais reperes]

### Cause probable
[pourquoi la derive s'est produite : prompt biaise, contexte desuet, hallucination LLM, etc.]

### Action
[ ] Keep : l'output reste valide
[ ] Correct : corriger l'output (lien vers correction)
[ ] Deprecate : marquer l'output comme obsolete, remplacer
[ ] Escalation : decision structurante requise (creer BDR)

### Learning associe
[LRN-XXX si l'evaluation genere un pattern reutilisable]
```

### Regle d'or

**Ne jamais evaluer un LLM en boucle fermee avec lui-meme.** Si l'evaluateur partage les memes biais que l'evalue, le cross-check est cosmetique. Au moins une des methodes doit faire intervenir une seconde nature : second LLM (modele different), second humain, ou confrontation a la realite mesurable.

## Exemple fictif

> **Maxime R., consultant solo en strategie, utilise un agent `proposal-writer` pour produire ses propositions commerciales. Il decide d'instaurer une evaluation systematique pour eviter de signer des promesses que l'agent invente.**

### Mise en place

Maxime configure 2 methodes d'evaluation :

1. **LLM-as-Judge a chaque proposition** : un second agent (`proposal-reviewer`, modele different) note la proposition sur 5 criteres : (1) absence de promesses chiffrees non fondees, (2) coherence avec le pricing officiel, (3) ton, (4) clarte du scope, (5) absence d'engagements legaux non valides. Score 4/5 minimum sinon refus.

2. **Confrontation realite a J+30** sur les 5 dernieres propositions signees : est-ce que ce qu'il avait promis correspond a ce qu'il a livre ?

### Premier mois : 8 propositions evaluees

**EVAL-001** : proposition pour un prospect e-commerce. Score 3/5. Anomalie detectee : l'agent a promis "audit de 12 process en 2 semaines" alors que le pricing officiel limite a 6 process. Correction : reduire le scope avant envoi. Action : Correct.

**EVAL-002** : proposition pour une PME industrielle. Score 5/5. Action : Keep.

**EVAL-003** : proposition pour un coach. Score 2/5. Anomalie : l'agent a invente une reference client ("notre methodologie deployee chez plus de 50 cabinets") qui n'existe pas. Action : Deprecate cette tournure dans le prompt de base de l'agent. Escalation BDR.

### Capitalisation au bout de 3 mois

Pattern detecte sur 3 EVALS : l'agent invente des references clients quand le brief est flou. Maxime extrait un LRN :

```markdown
## LRN-022 : Agents inventent des references clients sur briefs flous

**Date** : 2026-04-30
**Sources** : EVAL-003, EVAL-007, EVAL-011

### Observation

3 propositions sur 8 ont contenu des references clients fictives. Common denominator : le brief d'entree de l'agent etait imprecis sur le segment cible.

### Regle generalisable

**Tout agent qui peut citer des references doit avoir une liste blanche explicite injectee.** Sinon, interdire la citation par regle dure dans le prompt ("ne jamais citer de reference client").

S'applique a : tous les agents customer-facing (proposition, sales, content marketing).
```

### Resultat

3 mois plus tard, l'agent ne hallucine plus de references. Maxime a evite au moins 2 situations de prospect deçu (qui auraient appele pour parler avec une "reference" inexistante). Le registre EVALS.md compte 12 entrees, dont 4 ont produit des LRN reutilisables.

## Anti-patterns

- **Evaluer avec le meme LLM en boucle fermee** : Sonnet evalue Sonnet sur ses propres outputs : meme biais, validation cosmetique
- **Evaluation differree systematique** : "je le ferai trimestre prochain" : la derive devient invisible
- **Score sans rubrique** : noter "ca semble bon" sans criteres testables : pas d'evaluation, juste une impression
- **EVAL sans action** : detecter une hallucination et ne pas corriger l'agent ni le prompt : la derive persiste
- **Sur-evaluer** : evaluer chaque output trivial : les EVALS deviennent illisibles, le pattern critique se noie

## Quand evaluer

- **Toujours** pour les decisions structurantes (BDR) : confrontation realite a J+30
- **A chaque update** d'un agent ou d'un skill : verifier que la nouvelle version ne degrade pas
- **Trimestriel** pour les templates et contenus produits il y a > 90 jours
- **Mensuel** pour tout output public (formation, produit, contrat) : la derive cote ici est lue par des tiers

## Quand NE PAS evaluer

- **Output trivial** (un mail de relance standardise, une note interne) : sur-evaluer dilue le signal
- **Pattern observe une seule fois** : pas encore une derive, peut etre du bruit. Attendre la 2e occurrence.
- **Avant le premier mois d'usage** d'un agent : laisser le temps de produire une matiere statistiquement evaluable

L'evaluation est un cout. Elle se justifie sur les outputs **qui engagent** (decision, promesse client, production publique). Pas sur tout.
