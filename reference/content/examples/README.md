# Exemples — VibeFlow en action

> Mini-systemes agentiques fictifs qui montrent la methodologie VibeFlow appliquee de bout en bout.
> A consulter pour s'inspirer. **JAMAIS a copier-coller** dans son propre systeme.

## Disponible dans cette version

- **PetitsCoursFlow** — Mini-systeme fictif d'une professeure de musique freelance (persona : Sophie K.)

## Comment lire un exemple

Chaque exemple contient :

```
NomFlow/
├── README.md              -- Presentation du persona + de l'usage du systeme
├── CLAUDE.md              -- Constitution du systeme
├── .claude/
│   ├── memory/            -- Registres (BDR, LRN, BLK, JOURNAL, EVALS)
│   ├── agents/            -- Definitions des agents
│   └── rules/             -- Regles auto-scopees
└── ... (sous-systemes specifiques)
```

Dans chaque fichier, tu retrouves les patterns du dossier `methodology/patterns/` appliques a un cas concret.

## Pourquoi un exemple fictif

Un exemple fictif a deux vertus :

1. **Aucune fuite de donnees** — Personne ne peut reconnaitre un client reel, un montant reel, un email reel
2. **Effet pedagogique pur** — Tu vois la methode sans etre distrait par les specificites d'un cas reel

## Comment utiliser cet exemple

### Bonne posture

> *"Tiens, regarde comme Sophie a structure son agent `student-qualifier`. Je peux m'inspirer de son format Input / Output pour mon agent a moi."*

### Mauvaise posture

> *"Je copie tout PetitsCoursFlow et je remplace les noms par les miens."*

L'exemple fictif est une **demonstration de methode**, pas un template pret a l'emploi. Les vrais templates vides sont dans `methodology/templates/`.
