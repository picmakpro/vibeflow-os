# Pattern 04 — Skills

## Quoi

Un **skill** est une base de connaissances injectable dans un agent. Le skill apporte le **savoir** ; l'agent apporte l'**action**.

Format canonique : un dossier `skills/<nom>/SKILL.md` au format Anthropic Skills standard, avec frontmatter et description claire.

## Pourquoi

Un agent code en dur une expertise = duplication. Plusieurs agents font le meme travail de reflexion sur la securite, le pricing, le debugging. Si on met a jour la connaissance, il faut le faire 5 fois.

Un skill separe le savoir de l'acteur. **Une seule source de verite** (le skill `pricing-knowledge`), injectee dans tous les agents qui en ont besoin (commercial, devis, livreur, comptable). Quand le pricing change, on met a jour 1 fichier — propagation automatique.

## Comment

### Format SKILL.md

```markdown
---
name: pricing-knowledge
description: Expertise pricing du studio (offres, ranges, regles de remise)
---

# Skill : pricing-knowledge

## Quand l'utiliser

- Qualifier un prospect (verifier alignement budget)
- Construire un devis
- Negocier un montant
- Capitaliser un apprentissage commercial

## Connaissances

### Offres standard
- Audit identite : 1500-2500 EUR (3 a 5 jours)
- Direction artistique : 4000-7000 EUR (2 a 3 semaines)
- Suivi long : 800 EUR/mois (engagement 6 mois min)

### Regles de remise
- Aucune remise sur audit (prix d'entree, defendre la valeur)
- 10 % max sur DA si engagement suivi long signe en parallele
- 0 % sur suivi long (le prix flat est deja l'incentive)

### Cas piegeux
- Prospect qui dit "j'ai un budget de 2000 EUR pour une DA"
  → l'agent ne propose JAMAIS de baisser DA, mais propose un audit
- Prospect qui dit "je commence par un audit, j'aviserai pour la suite"
  → l'agent precise que la DA derriere est un engagement separe
```

### Comment injecter un skill dans un agent

Dans le frontmatter de l'agent :

```markdown
---
name: pricing-validator
skills: [pricing-knowledge, security]
---
```

Au demarrage de l'agent, les skills referentes sont chargees en contexte.

### Skills usuels

| Skill | Role |
|-------|------|
| `debugger` | Methode de debugging systematique 4 phases |
| `security` | Securite SaaS / mobile, checklists 3 tiers |
| `clarity-feature` | Clarification pre-implementation d'une feature |

Tu peux creer tous les skills metier dont tu as besoin : `seo-knowledge`, `legal-fr`, `accounting-fr`, `editorial-style`, etc.

## Exemple fictif

> **Maxime R., consultant solo en strategie, construit `consulting-pricing` :**

```markdown
---
name: consulting-pricing
description: Expertise pricing de mon activite consulting strategie
---

## Quand l'utiliser

A chaque qualification de prospect, devis, negociation.

## Connaissances

### Formats vendus
- Diagnostic : 2 a 3 semaines, 4500 EUR (forfait)
- Pilotage trimestriel : 12 semaines, 18 000 EUR (forfait)
- Atelier strategique 1 jour : 2500 EUR

### Hors-perimetre
- Pas de TJM (rejette au pricing forfait)
- Pas d'engagement >= 6 mois (devient salariat partiel)
- Pas de prospect < 30 EUR de CA annuel (pas la maturite)

### Cas piegeux
- "Combien pour 2 jours d'atelier ?" → reorienter vers diagnostic 2 semaines
- "Tu peux me faire un coaching ?" → refus mot "coaching" (LRN-003)
- "Et si on fait juste 1 mois de pilotage ?" → refus, pilotage = 3 mois min
```

Maxime injecte ce skill dans 2 agents :
- `prospect-qualifier` (verifie alignement budget en qualification)
- `devis-builder` (construit le devis selon le format)

Les 2 agents partagent **la meme** connaissance pricing. Si Maxime augmente ses tarifs, il modifie 1 fichier.

## Anti-patterns

- **Skill = wiki sans regles** : "voici tout ce qui existe sur le sujet" → trop volumineux, agent skip
- **Skill specifique a un agent** : si un seul agent l'utilise, ce n'est pas un skill, c'est une connaissance interne de l'agent
- **Skill qui contient des regles dures** : les regles dures vont dans la constitution + interdits, pas dans un skill
- **Skill qui change tout le temps** : si le contenu bouge tous les 3 jours, il manque un BDR pour stabiliser

## Quand creer un skill

- Au moins **2 agents** consomment la meme connaissance
- Le savoir est **stable** (changements rares, traces par BDR)
- Le savoir est **specialisable** (clairement borne, pas une encyclopedie)
- Le savoir est **operationnel** (on peut s'en servir pour decider)

## Architecture skills : 3 niveaux de chargement (v4.1)

VibeFlow v4.1 distingue 3 mecanismes de chargement d'un skill, du plus universel au plus contextuel :

| Niveau | Mecanisme | Quand le skill est charge | Exemple typique |
|--------|-----------|---------------------------|-----------------|
| **Meta-universel** | Liste dans `bootstrap.md` (SessionStart) | Au demarrage de chaque session, systematiquement | `verification-before-completion`, `dette-detector` |
| **Contextuel agent** | Frontmatter `skills:` de l'agent (flat list) | A l'invocation de l'agent | `pricing-knowledge` injecte dans `prospect-qualifier` |
| **On-demand** | `description` du skill matche la situation courante (1% Rule) | Au runtime, quand un signal contextuel le justifie | `debugger` charge des qu'un bug apparait |

### Bootstrap-skills vs On-demand skills

- **Bootstrap-skills** (prechargés) : ce sont les "reflexes innes" du systeme. Ils representent les disciplines transversales qui s'appliquent toujours (verification systematique, detection de dette, garde-fous cognitifs). Charges en debut de session, ils ne sont jamais sollicites explicitement  -  ils sont la d'office.

- **On-demand skills** (a la demande) : ce sont les "specialistes de la bibliotheque". Ils representent des expertises pointues (pricing, securite, debugging, accounting). Ils ne sont charges que quand le contexte les justifie, pour preserver la legerete du contexte.

### La 1% Rule (Anthropic)

Si une situation correspond **meme a 1%** au theme d'un skill, le skill doit etre invoque.

Pourquoi : mieux vaut sur-trigger un skill (cout faible : quelques tokens) que de l'ignorer quand il est pertinent (cout potentiellement eleve : decision prise sans l'expertise specialisee).

### Iron Law SKILL.md ≤ 500 lignes (Progressive Disclosure)

Un skill ne depasse pas **500 lignes** dans son `SKILL.md` principal. Au-dela, on segmente :
- Le `SKILL.md` reste un index synthetique (≤ 500 lignes)
- Les details vivent dans des sous-documents charges a la demande

Raison : Progressive Disclosure  -  on ne charge le savoir detaille que quand il est necessaire, pour preserver le contexte.

### Garde-fou meta (v4.1)

Avant d'inventer une convention de skill (nouveau champ frontmatter, mecanisme de chargement non standard, structure imbriquée), **verifier que le runtime cible la supporte effectivement**. Une convention plausible mais non supportee = convention fantome = illusion de structure. Voir `VIBEFLOW_CORE.md` section 6, circuit breaker 5.
