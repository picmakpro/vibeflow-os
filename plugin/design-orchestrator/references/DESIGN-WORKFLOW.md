# DESIGN-WORKFLOW — Workflow design au quotidien (générique multi-stack)

> Référence chargée on-demand par l'agent `vibeflow-design`. Améliorer l'expérience visuelle
> **sans casser les features**. Chaque modification est une **amélioration mesurable**.
>
> **Généricité** : ce workflow produit des **specs + tokens**, pas du code framework-locké. Il
> vaut pour web (React/Next/Vue/Svelte/vanilla), mobile (SwiftUI/React Native/Flutter) et desktop.
> Détecter la stack **avant** d'agir et adapter l'incarnation (cf. table de généricité de `AGENT.md`).

---

## Étape 0 — Chaîne d'outils (AVANT TOUT)

Ce workflow s'appuie sur la **chaîne d'outils design interne**. Vérifier sa présence et
**dégrader gracieusement** si un outil manque : voir `design-toolchain.md` (noms réels des outils,
commande de vérification, dégradation). **Ne jamais bloquer** : à défaut d'outil, on route sur les
premiers principes design (référentiel UX + jugement) et on le signale dans le rapport final.

> **Reframe** : à l'utilisateur, on ne nomme jamais un outil brut. On parle de *revue design*,
> *direction artistique*, *passe de finition* (cf. `design-vocabulary-map.md`).

---

## Routing par intent

```
Tâche design reçue
   ├── INSPIRATION / RÉFLEXION  (explore, brainstorme, je cherche une direction)
   │      → exploration structurée → référentiel UX → direction créative (web)
   ├── CRITIQUE / AUDIT  (review, qu'est-ce qui cloche, c'est pro ?)
   │      → revue heuristique scorée → audit a11y/perf/responsive → référentiel UX (règles)
   └── ACTION / IMPLÉMENTATION  (fix, refonte, ajoute)
          → routing par complexité ci-dessous
```

### Cheatsheet intent → geste

| Le user dit… | Intent | Premier geste |
|---|---|---|
| « explore / je cherche une direction / brainstorme » | INSPIRATION | exploration → référentiel UX → direction créative |
| « qu'est-ce qui cloche / audit / review » | CRITIQUE | revue heuristique → audit technique |
| « le contraste est faible / la hiérarchie manque / le rythme est mou » | CRITIQUE → ACTION | audit → routing complexité |
| « ajoute / modifie / refonte / fix » | ACTION | routing complexité |
| « trop fade / pas assez audacieux » | ACTION (amplifier) | geste « amplifier » |
| « trop agressif / trop chargé » | ACTION (calmer) | geste « calmer » |
| « ajoute du motion / une transition » | ACTION (motion) | geste « animer » |
| « améliore la typo / le rythme typo » | ACTION (typo) | geste « typographie » |
| « le spacing est cassé / pas de rythme » | ACTION (layout) | geste « layout » |
| « passe en revue avant livraison » | ACTION (finition) | geste « finition » |
| « le copy est mou / labels confus » | ACTION (copy) | geste « clarté copy » |
| « responsive cassé / mobile à revoir » | ACTION (adapt) | geste « adapter » |
| « design system / tokens à extraire » | ACTION (build) | geste « extraire système » |
| « first-run / empty state / activation » | ACTION (finition) | geste « états vides / onboarding » |

---

## Routing par complexité (mode ACTION)

```
Action design
   ├── Refonte de PAGE/ÉCRAN entier ou changement de système de design ?
   │      → OUI → FULL DESIGN
   └── NON → Multi-fichiers (>2) / refonte de section-composant / nouveau pattern ?
          → OUI → PLAN MODE
          → NON → QUICK FIX
```

> **Désambiguïsation « refonte »** : « refonte de page/écran entier » → FULL DESIGN. « refonte
> d'une section / d'un composant / du header » → PLAN MODE. En cas de doute, **monter d'un cran**.

### QUICK FIX — fix ciblé (≤2 fichiers)

Fix CSS/style, déplacement d'un élément, ajustement spacing, une couleur, une transition.
1. Valider le choix contre le **référentiel UX**.
2. Charger le **geste de craft** le plus proche du diagnostic (layout / typo / couleur / clarté / motion / finition).
3. Lire `DESIGN.md` (la DA), implémenter selon les tokens, build/rendu, done.

### PLAN MODE — ajout composant / refonte section / multi-fichiers

1. **Référentiel UX** + **direction créative** (web) + **revue** de la cible (diagnostic d'abord).
2. Lire `DESIGN.md` + la section design du `CLAUDE.md` projet.
3. **Plan** (entrer en plan mode) → validation → implémentation → **passe de finition** → build/rendu.

### FULL DESIGN — refonte de page/écran / nouveau pattern / changement de système

1. **Exploration** + **référentiel UX** + **direction créative** (web).
2. Structurer le brief (UX avant le code). Recherche web (benchmarks, tendances) si pertinent.
3. **Plan détaillé** → implémentation par étapes → **audit** (a11y/perf/responsive) + **finition** → gate de sortie.

---

## Checklist AVANT toute action (par mode)

| # | Étape | QUICK FIX | PLAN MODE | FULL DESIGN |
|---|-------|:--:|:--:|:--:|
| 1 | Détecter la stack + vérifier la chaîne d'outils (`design-toolchain.md`) | ✅ | ✅ | ✅ |
| 2 | Valider via le **référentiel UX** | ✅ | ✅ | ✅ |
| 3 | Lire `DESIGN.md` (la DA) | ✅ | ✅ | ✅ |
| 4 | Lire la section design du `CLAUDE.md` | si applicable | ✅ | ✅ |
| 5 | Capture AVANT (si modif visuelle et rendu disponible) | ✅ | ✅ | ✅ |
| 6 | **Direction créative** (web) | ❌ | ✅ | ✅ |
| 7 | **Revue / critique** de la cible (diagnostic) | si CRITIQUE | ✅ | ✅ |
| 8 | **Exploration** (idéation) | ❌ | ❌ | ✅ |
| 9 | Brief structuré (UX avant code) | ❌ | ❌ | ✅ |

> **Règle de vie** : toujours **diagnostic + plan AVANT d'implémenter** (sauf QUICK FIX <2 fichiers).
> Pas de refonte à l'aveugle en PLAN MODE / FULL DESIGN.

---

## Règles absolues

- **Ne JAMAIS modifier** la logique métier (API, auth, jobs, tests).
- **Ne JAMAIS supprimer** un composant fonctionnel pour un gain visuel.
- **Toujours passer par les tokens** du système de design (pas de valeurs en dur) quand il existe.
- **Toujours vérifier le build / le rendu** avant de déclarer terminé.
- **Anti-AI-slop** : pas de police générique par défaut (Inter/Roboto/Arial), pas de gradients
  clichés, pas de layouts copiés-collés, pas de glassmorphism décoratif gratuit, pas d'em-dash (—)
  décoratif dans le copy UI.
- **Accessibilité** : contraste ≥ 4.5:1, focus visibles, cibles tactiles ≥ 44px, labels d'accessibilité.
- **Couleurs sémantiques** définies dans `DESIGN.md` — les respecter.

---

## Parallélisation (subagents)

Pour une refonte multi-pages/écrans :
- un subagent par page/écran indépendant ;
- un subagent recherche (benchmarks web) pendant que tu planifies ;
- un subagent revue/critique par page pour un audit parallèle ;
- **vérification obligatoire avant tout claim de complétion**.

---

## Gate de sortie (OBLIGATOIRE)

```
AVANT de dire « c'est fait » :
1. Build / rendu → PASS
2. Capture APRÈS (si visuel et rendu disponible)
3. Features intactes (interactions, données chargées)
4. Responsive / multi-écrans non cassé (si layout modifié)
5. DESIGN.md mis à jour (si nouvelle convention introduite)
6. Checklist référentiel UX validée (a11y, interactions, contraste)
7. PLAN MODE / FULL DESIGN : passe de finition lancée
8. PLAN MODE / FULL DESIGN : audit a11y/perf/responsive → 0 finding bloquant
```

**Sauter une étape = le travail n'est pas terminé.** Reframer le rapport final en vocabulaire
VibeFlow (revue design / passe de finition / direction artistique) — ne jamais nommer les outils bruts.
