# Pattern 01 — Constitution

## Quoi

La **constitution** est le fichier `CLAUDE.md` a la racine de ton systeme agentique. C'est le contrat racine qui dit : qui je suis, ce que je fais, ce que je ne fais pas, comment je travaille.

Tout agent et tout outil qui s'execute dans ton systeme la lit en premier.

## Pourquoi

Sans constitution :
- Les agents derivent (ils inventent leur propre cadre)
- Tu re-expliques le contexte a chaque session
- Les decisions deviennent incoherentes entre les sprints
- Le systeme n'a pas de "soi"

Avec constitution :
- Un seul fichier, lisible en 5 minutes, qui ancre tout le reste
- L'agent comprend ton perimetre des le premier message
- Les regles dures sont visibles (interdits explicites)
- Le systeme a une identite stable

## Comment

Une constitution efficace contient **4 sections obligatoires** :

1. **Contexte** — Qui tu es. Quel est le projet. Quel est l'enjeu.
2. **Regles de travail** — Comment tu operes. Perimetre. Cadences. Conventions.
3. **Taches types** — Ce que tu demandes le plus souvent (avec quel agent, quel input, quel livrable attendu).
4. **Interdits** — Ce que le systeme ne doit jamais faire. Liste explicite.

**Regle d'or** : moins de 150 lignes. Au-dela, la constitution n'est plus lue — elle est skimmee.

Si la constitution depasse 150 lignes, le contenu doit migrer vers :
- Des **regles auto-scopees** (Pattern 05) pour les conventions par contexte
- Des **registres** (Pattern 02) pour les decisions, apprentissages, blocages
- Des **fichiers de reference** (`docs/REFERENCE.md`) pour la source de verite stable

## Exemple fictif

> **Sophie K., professeure de musique freelance, gere son systeme `MusicianFlow` :**

```markdown
# CLAUDE.md — MusicianFlow (OS de Sophie K.)

## 1. Contexte

Sophie K., 34 ans, Lyon. Professeure de piano et solfege depuis 6 ans.
Elle gere ~25 eleves recurrents, 1 a 2 ateliers groupes par mois, et publie
2 a 3 contenus pedagogiques par semaine sur sa newsletter.

Avant cet OS, elle perdait entre deux trimestres les progressions
pedagogiques qui marchaient et les frictions recurrentes avec les parents.
Cet OS capitalise tout.

## 2. Regles de travail

- 5 jours d'enseignement par semaine, jamais le mercredi (jour creation contenu)
- Pas plus de 28 eleves recurrents (au-dela, qualite chute)
- Tous les contenus newsletter passent par l'agent `editor-music`
- Toute decision pedagogique structurante (changement de methode, refus
  d'eleve) est documentee en DEC AVANT execution

## 3. Taches types

- **Qualifier un nouvel eleve** : agent `student-qualifier` → verdict GO / NO-GO / QUESTIONS
- **Preparer une newsletter** : redaction + agent `editor-music` → VALIDE / AJUSTER / REFUSER
- **Capitaliser une lecon qui a marche** : ouvrir LEARNINGS.md, format LRN-XXX

## 4. Interdits

- INTERDIT : prendre un eleve adulte debutant sans diagnostic 30 min prealable
- INTERDIT : promettre une preparation concours en moins de 6 mois
- INTERDIT : publier un contenu newsletter qui mentionne un eleve nominalement
- INTERDIT : modifier le fichier `eleves/factures/` sans validation explicite
```

C'est tout. 30 lignes. Lisible en 2 minutes. **L'agent qualifie un nouvel eleve en respectant le cadre, sans avoir besoin de re-expliquer Sophie a chaque fois.**

## Anti-patterns courants

- **Constitution-essai** : 400 lignes de paragraphes lyriques sur "ma vision" → l'agent skip, ne lit que les premieres lignes
- **Constitution-checklist** : 80 regles listees sans hierarchie → l'agent ne sait plus laquelle prioriser
- **Constitution morte** : ecrite une fois, jamais mise a jour → derive entre la realite et le contrat
- **Constitution-CV** : decrit le passe et les diplomes au lieu du contrat operationnel actuel

## Quand la mettre a jour

- Quand une **decision structurante** change le perimetre (nouveau format, nouveau pricing, nouveau type de client/eleve)
- Quand un **interdit** doit etre ajoute (apres une derive observee)
- Quand une **tache type** devient recurrente et merite d'etre documentee

Toute mise a jour de la constitution doit pointer vers une **DEC** qui justifie le changement (Pattern 06).
