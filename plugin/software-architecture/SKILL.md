---
name: software-architecture
description: Architecture logicielle AI-safe. Invoquer dès qu'on crée/édite du code, qu'un fichier grossit, qu'on planifie un refactor/restructuration, ou qu'on sent une dette structurelle (god file, couplage, frontières floues). Applique SOLID/SRP/SoC, le seuil de taille 300L, et des garde-fous machine-enforced.
---

# Architecture Logicielle AI-Safe

> Spécialise le principe Core **P9 — Modulariser pour la cognition** pour le code de production.
> Origine : diagnostic terrain (un projet de code où l'IA « cassait du code ailleurs » à chaque
> modification — cause racine : god files + filet de tests non fonctionnel + gates non câblés).

## Iron Law

**AUCUN FICHIER DE CODE > 300 LIGNES SANS PLAN DE DÉCOUPE. UNE RESPONSABILITÉ PAR UNITÉ. LES FRONTIÈRES SONT ENFORCED PAR LA MACHINE, PAS PAR LA PROSE.**

Corollaire : un garde-fou qui n'est pas exécuté par la machine (CI, hook, lint, gate) n'existe pas. Une règle écrite que le développeur (ou l'IA) peut ignorer N'EST PAS un garde-fou.

## Pourquoi (le lien avec l'IA qui « casse du code »)

Au-delà de ~300 lignes, un fichier agglomère plusieurs responsabilités. L'IA qui le modifie
doit charger tout le fichier en contexte, perd le fil de l'intention, touche une zone en pensant
en réparer une autre → **régression silencieuse**. Plus l'unité est petite et mono-responsabilité,
plus le « blast radius » d'une modification est petit, plus l'IA est fiable. La taille de fichier
n'est pas une préférence de style : c'est un **facteur causal** de la qualité en dev assisté par IA.

## Red Flags — contrer les rationalisations

| Ce qu'on se dit | Réalité |
|---|---|
| « Juste une petite chose de plus dans ce fichier » | Découpe. Mets-la dans son module. |
| « On refactorera plus tard » | Plus tard = jamais. Découpe maintenant ou crée un marqueur de dette tracé. |
| « Tout le monde fait comme ça » | SOLID n'est pas optionnel. La fondation détermine la suite. |
| « La perf exige le couplage » | Profile d'abord. Découple. Optimise le cache, pas l'architecture. |
| « C'est documenté dans le CLAUDE.md / le README » | La prose n'est pas un gate. Câble un check machine. |
| « Le test est rouge mais le code marche » | Un filet de tests non fonctionnel = pas de filet. Répare le filet AVANT de continuer. |

## Validation en 3 tiers

### Tier 1 — Gate local (à chaque édition / pre-commit)
- **Taille** : `check-file-size.sh` — avertissement à 250L, **blocage à 300L** sans marqueur de découpe.
- **Cycles d'import** : détection (madge / dependency-cruiser). Cycle = interdit.
- **Frontières** : eslint-plugin-boundaries (ce qui peut importer quoi). Mode `warn` → `error`.
- **Vérification 3 couches avant tout « done »** : (1) syntaxe (compile/lint vert) → (2) intention (la modif reflète la spec) → (3) régression (tests + typecheck verts). Cf. skill `verification-before-completion`.

### Tier 2 — Audit de patterns (checkpoint de sprint)
- Checklist SOLID (voir `references/solid-soc.md`).
- Zones de séparation des préoccupations (domaine / application / infrastructure) non mélangées.
- Détection des anti-patterns (voir `references/anti-patterns.md`) : god file, god class, feature envy, couplage circulaire.

### Tier 3 — Revue d'architecture (gate de release)
- Composition globale du système, couplage inter-domaines.
- Tout marqueur de dette `[DEBT]` doit être soit fermé, soit converti en ADR + règle.

## Quand m'invoquer (1% Rule)

Si une situation correspond MÊME à 1% à l'un de ces cas, invoquer ce skill :
- Création ou édition d'un fichier de code.
- Un fichier dépasse (ou s'approche de) 250-300 lignes.
- Planification d'un refactor, d'une migration ou d'une restructuration.
- Sensation de dette : « ça devient dur à modifier », « je touche X et Y casse ».
- Mise en place d'un nouveau projet (poser la fondation) ou reprise d'un projet existant.

## Deux modes d'emploi

1. **Base solide sur un projet neuf** → poser : structure Feature-Sliced, rule
   `production-code-architecture` (path-scopée), gate `check-file-size.sh`, doc `ARCHITECTURE.md`.
2. **Restructuration d'un projet existant (brownfield)** → suivre le playbook 6 vagues :
   `references/restructuration-playbook.md` (stabiliser le filet de tests AVANT toute migration).

## Références (chargement à la demande)

- `references/solid-soc.md` — SOLID + séparation des préoccupations + structure de dossiers.
- `references/anti-patterns.md` — Catalogue d'anti-patterns + signaux + remède.
- `references/restructuration-playbook.md` — Playbook brownfield 6 vagues (généralisé).
- `references/universal-vs-dev.md` — Ce qui est universel (transposable non-dev) vs dev-spécifique. Spécialise P9.

## Garde-fou universel (projets non-dev)

P9 ne concerne pas que le code. Pour tout projet : pas d'unité trop grosse (un document, une
section, une tâche), une responsabilité par unité, des frontières claires, et un contrôle
**automatique** plutôt qu'une consigne écrite. Voir `references/universal-vs-dev.md` pour la transposition.
