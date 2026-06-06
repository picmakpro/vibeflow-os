# Pattern 03 — Agents

## Quoi

Un **agent** est un specialiste avec un mandat clair. Ce n'est pas un "couteau suisse" qui sait tout faire — c'est un acteur dedie a une mission precise.

Un agent VibeFlow est defini par 7 elements :

| Element | Role |
|---------|------|
| **Nom** | Identifiant unique (ex: `prospect-qualifier`) |
| **Role** | Mission en une phrase |
| **Input** | Ce qu'il recoit pour travailler |
| **Output** | Ce qu'il produit (format standard) |
| **Memory** | Memoire persistante cross-session |
| **Skills** | Expertise injectee au demarrage |
| **Contraintes** | Ce qu'il ne doit jamais faire |

## Pourquoi

Un agent generaliste produit des reponses moyennes. Un agent specialise produit des reponses operationnelles.

Quand un solopreneur invoque `prospect-qualifier`, il sait deja :
- Quelles regles l'agent va appliquer (ICP, format, pricing)
- Quel format de verdict il va recevoir (GO / NO-GO / QUESTIONS)
- Quelles registres l'agent consulte avant de decider

C'est l'inverse de "Claude, dis-moi si je dois prendre ce prospect" — qui produit une reponse generique, jamais alignee.

## Comment

### Les 6 roles canoniques

VibeFlow propose un set de roles d'agents standardises :

| Role | Mission |
|------|---------|
| **lead** | Orchestrateur central. Ne code/produit jamais. Delegue. |
| **explorer** | Analyse rapide, lecture seule, observations factuelles |
| **specialiste metier** | Producteur (commercial, livreur, editeur, comptable, etc.) |
| **reviewer** | Audit qualite, conformite |
| **reporter** | Production de rapports formels |
| **validator** | Audit de coherence interne du systeme |

Tu peux ajouter des roles **specifiques a ton domaine** (Pattern 07) — mais commencer par ces 6 couvre 90 % des besoins.

### Format de definition

```markdown
---
name: prospect-qualifier
role: Qualifie un prospect entrant selon ICP + format + pricing
model: sonnet
memory: project
skills: [security, pricing-knowledge]
---

# Agent prospect-qualifier

## Input
- Brief du prospect (CA, secteur, besoin exprime, budget)

## Output (format strict)

GO / NO-GO / QUESTIONS, justifie par reference a BDR-001 (ICP) +
BDR-003 (format mission) + LRN pertinents.

## Memoire

- Lit BDR.md et LEARNINGS.md a chaque invocation
- Capitalise un nouveau pattern observe en LRN si applicable

## Contraintes

- JAMAIS valider un prospect sans verifier ICP + format + pricing
- JAMAIS hallucinations sur le CA — demander la source si non fournie
- ESCALADER au humain si cas piegeux (secteur ambigu, CA non declare)
```

### Regles d'or

1. **Un agent = une mission**. Si tu hesites a creer un agent qui fait deux choses, cree deux agents.
2. **L'agent produit un format strict**. Pas de texte libre. Verdict structure.
3. **L'agent lit les registres avant de decider**. La constitution + BDR + LEARNINGS sont ses sources de verite.
4. **L'agent escalade quand il doute**. Mieux vaut une question au humain qu'une hallucination.

### Charte de densite (v4.1)

Un agent qui pese trop hallucine plus. Au-dela d'un certain seuil, le contexte injecte degrade la qualite du raisonnement  -  c'est le phenomene de **context rot** (preuve empirique Chroma 2025 : degradation mesurable au-dela de ~80K tokens, meme sur des modeles supposes 1M+).

Trois seuils universels s'appliquent :

| Composant | Plafond | Pourquoi |
|-----------|---------|----------|
| Body d'un agent (apres frontmatter) | **≤ 250 lignes** | Au-dela, l'agent perd la coherence de son mandat |
| Body d'un skill | **≤ 500 lignes** | Au-dela, on bascule en sous-documents charges a la demande |
| Bootstrap charge au SessionStart | **≤ 2000 tokens** | Au-dela, le contexte initial est deja trop lourd |

Si un agent depasse 250 lignes : probablement 2 agents melanges, ou du savoir qui devrait etre dans un skill, ou des conventions qui devraient etre dans des regles. **Re-decouper, pas allonger**.

### Frontmatter natif et architecture skills (v4.1)

Le frontmatter d'un agent declare ses skills via une **liste flat** simple :

```markdown
---
name: prospect-qualifier
skills: [pricing-knowledge, security, debugger]
---
```

Ne pas inventer une structure imbriquée que le runtime ne supporte pas (voir garde-fou meta dans `VIBEFLOW_CORE.md` section 6).

Distinction pedagogique cle :

- **Bootstrap-skills** (prechargés) : reflexes innes de tout agent du systeme, charges automatiquement au SessionStart via `bootstrap.md`. Exemples : `verification-before-completion`, `dette-detector`.
- **On-demand skills** : bibliotheque de specialistes qu'un agent appelle au besoin via son frontmatter (chargement a l'invocation) ou via match de description (chargement runtime selon contexte). Exemples : `debugger`, `pricing-knowledge`, `security`.

La regle **1% Rule** (Anthropic) : si une situation correspond meme a 1% a la description d'un skill, l'invoquer. Mieux vaut sur-trigger que d'ignorer.

## Exemple fictif

> **Atelier Demo (micro-studio creatif fictif) construit son agent `brief-validator` :**

```markdown
---
name: brief-validator
role: Valide qu'un brief client est suffisamment defini pour entrer en production
model: sonnet
memory: project
---

## Input
- Brief client recu (texte ou doc)

## Output (format strict)

| Critere | Statut | Commentaire |
|---------|--------|-------------|
| Objectif business clair | OK / KO / QUESTIONS | ... |
| Audience cible identifiee | OK / KO / QUESTIONS | ... |
| Ton de voix specifie | OK / KO / QUESTIONS | ... |
| Contraintes visuelles connues | OK / KO / QUESTIONS | ... |
| Deadline realiste | OK / KO / QUESTIONS | ... |
| Budget aligne | OK / KO / QUESTIONS | ... |

Verdict global : PROD-READY / RETOUR-CLIENT / REFUS

Si RETOUR-CLIENT : liste des 3-5 questions a poser au client.

## Memoire

- Lit BDR-002 (ICP studio : startups SaaS B2B uniquement)
- Lit BDR-005 (briefs sous 800 EUR refuses systematiquement)
- Capitalise les patterns de briefs flous en LRN

## Contraintes

- JAMAIS valider PROD-READY si plus de 2 criteres sont QUESTIONS
- JAMAIS proposer une remise pour faire passer un brief sous le seuil de 800 EUR
- ESCALADER au humain si le client est un retour avec un brief flou (cas politique)
```

Resultat : quand le studio recoit un brief, l'agent produit un tableau structure en 30 secondes. Le studio decide en 2 minutes au lieu d'1 heure de relecture.

## Anti-patterns

- **L'agent generaliste** : "tu fais tout pour mon business" → derive systemique
- **L'agent sans format** : produit du texte libre → impossibilite de comparer entre invocations
- **L'agent sans contraintes** : "fais au mieux" → hallucinations sur les cas piegeux
- **L'agent qui produit ET valide** : juge et partie. Toujours separer producteur et reviewer.

## Quand creer un nouvel agent

Quand une **tache type recurrente** apparait dans la constitution (Pattern 01) ET qu'elle merite un format de sortie standardise.

Si la tache n'est faite qu'une fois par mois, ne cree pas d'agent — tu fais a la main, ou tu invoques Claude directement.

Regle de pouce : un agent vit s'il est invoque au moins **2 fois par semaine** sur la duree.
