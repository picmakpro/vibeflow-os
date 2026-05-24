# Patterns architecturaux VibeFlow

> Les **11 patterns universels** de la methodologie, illustres par des exemples fictifs.
> Ce dossier explique COMMENT VibeFlow s'incarne. Pas COPIER : INSPIRER.
> Edition Mai 2026 (v4.1)  -  patterns 09, 10, 11 ajoutes.

## Comment lire ces patterns

Chaque pattern repond a 4 questions :

1. **Quoi** : definition courte
2. **Pourquoi** : le probleme que ca resout
3. **Comment** : la regle d'implementation
4. **Exemple fictif** : un cas illustratif (jamais un cas reel)

Les exemples fictifs s'appuient sur des personas inventes : *Sophie K., professeure de musique freelance*, *Atelier Demo, micro-studio creatif*, *Maxime R., consultant solo en strategie*. Aucun chiffre, aucun client, aucun secret reel.

## Les 11 patterns

| # | Pattern | Fichier | Resume | Version |
|---|---------|---------|--------|---------|
| 1 | Constitution | `01-constitution.md` | Le CLAUDE.md comme contrat racine du systeme | v4.0 |
| 2 | Registres | `02-registres.md` | Decisions / Apprentissages / Blocages / Journal / Evaluations | v4.0 |
| 3 | Agents | `03-agents.md` | Specialistes a mandat clair, jamais "couteau suisse" (+ charte densite v4.1) | v4.0 + v4.1 |
| 4 | Skills | `04-skills.md` | Savoir injectable (+ architecture 3 niveaux v4.1) | v4.0 + v4.1 |
| 5 | Regles auto-scopees | `05-regles.md` | Conventions qui se chargent selon le contexte de travail | v4.0 |
| 6 | Capitalisation | `06-capitalisation.md` | Rien ne se perd (+ Iron Law fresh-evidence + 7 anti-drift v4.1) | v4.0 + v4.1 |
| 7 | Transposition | `07-transposition.md` | Comment forker la methodologie pour son domaine (Principe 7) | v4.0 |
| 8 | Evaluer | `08-evaluer.md` | Mesure en continu de la qualite cognitive des outputs IA (Principe 8) | v4.0 |
| **9** | **Meta-procedures** | **`09-meta-procedures.md`** | **`safe-execute` (5 phases mono-tache) + `god-execution` (8 phases autonome)** | **v4.1 NOUVEAU** |
| **10** | **Adversarial Plan-Review** | **`10-plan-review-adversarial.md`** | **Anti-echo-chamber : 2 agents reviewers + Judge si divergence** | **v4.1 NOUVEAU** |
| **11** | **Halt conditions** | **`11-halt-conditions.md`** | **5 codes universels d'arret immediat en execution autonome** | **v4.1 NOUVEAU** |

## Carte de lecture par usage

- **Decouvrir VibeFlow** : lire 1 → 2 → 6 → 3 dans cet ordre.
- **Mettre en place une instance** : 1 → 2 → 3 → 4 → 5 → 6.
- **Construire un fork (nouveau domaine)** : 7 + 8.
- **Operer en autonomie rigoureuse** (v4.1) : 9 + 10 + 11 (a lire ensemble).
- **Auditer un projet existant** : 2 + 6 + 8 + 10.

## Avertissement

Ces patterns sont des **manieres de faire eprouvees**, pas des recettes a suivre a la lettre. Adapte chaque pattern a ton contexte. Si un pattern entre en collision avec une realite specifique de ton activite, c'est un signal : creer une decision (BDR/ADR) qui documente l'ecart.
