# PetitsCoursFlow - l'OS de Sophie K. (exemple fictif)

> **Personnage fictif. Aucune ressemblance avec une personne reelle n'est intentionnelle.**

## Qui est Sophie K.

Sophie K., 34 ans, Lyon. Professeure de piano et solfege depuis 6 ans. Diplome du CRR de Lyon, ancienne pianiste accompagnatrice en chorale amateur.

Elle gere environ 25 eleves recurrents (enfants de 7 ans + ados + 4 adultes), donne 1 a 2 ateliers groupes par mois (decouverte solfege ludique, atelier 4 mains), et publie une newsletter pedagogique a 850 abonnes (2 a 3 contenus par semaine sur les progressions, repertoires, anecdotes pedagogiques).

## A quoi sert cet OS

Avant PetitsCoursFlow, Sophie perdait entre deux trimestres :
- Les progressions pedagogiques qui marchaient sur certains profils
- Les frictions recurrentes avec certains parents (tarifs, exigences, assiduite)
- Les sujets de newsletter qui avaient fait bondir l'engagement
- Les decisions qu'elle avait prises sur le format de cours (collectif vs individuel, ages, niveaux)

Depuis PetitsCoursFlow, chaque decision pedagogique structurante devient une PDR (Pedagogical Decision Record), chaque pattern observe sur 2+ eleves devient un LRN, chaque friction qui a coute du temps devient un BLK.

## Arborescence

```
PetitsCoursFlow/
├── CLAUDE.md              -- Constitution
├── README.md              -- Ce fichier
├── .claude/
│   ├── memory/            -- 5 registres canoniques (PDR + LRN + BLK + JOURNAL + EVALS)
│   ├── agents/            -- 2 agents (student-qualifier + editor-music)
│   └── rules/             -- Regles auto-scopees (eleves-confidentialite)
├── content/               -- Sous-systeme editorial (newsletter, calendrier)
└── eleves/                -- Sous-systeme pedagogique (progressions, factures)
```

## Les deux sous-systemes relies par une memoire commune

- **Sous-systeme content** : ce que Sophie publie, les patterns qui font de l'engagement, les progressions racontees
- **Sous-systeme eleves** : les eleves recurrents, leurs progressions, la facturation

Les deux partagent UNE constitution, UN jeu de registres, et des regles auto-scopees qui protegent les zones sensibles (la confidentialite des eleves dans le contenu, la facturation hors automation).

## Reference pedagogique

PetitsCoursFlow est un **exemple fictif demonstratif**. Il existe pour montrer comment les 7 patterns VibeFlow s'incarnent dans un metier non-technique (pedagogie + creation de contenu + gestion d'eleves).

Si tu es professeur, formateur ou therapeute, tu peux t'inspirer de la structure - mais tu construis le tien selon ta realite.
