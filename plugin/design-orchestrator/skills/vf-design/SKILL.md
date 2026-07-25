---
name: vf-design
description: >
  Utiliser dès que l'intention touche au design ou à l'UI/UX, sous toutes ses formulations —
  « améliore le design », « rends ça plus beau », « c'est moche », « modernise l'interface »,
  « refais cette page », « la typo / le spacing / le contraste / les couleurs ne vont pas »,
  « ajoute une animation », « c'est trop fade / trop chargé », « audite / critique cet écran »,
  « on part sur quel style », « définis l'identité visuelle / la direction artistique »,
  « extrais un design system », « responsive cassé ». Point d'entrée design de VibeFlow : détecte
  l'intention (définir la DA / modifier l'UI / critiquer / craft ciblé), détecte la stack, puis
  route. Générique multi-stack (web, mobile, desktop).
  ✘ pas pour une maquette jetable d'exploration (« montre-moi à quoi ça ressemblerait ») →
  /vf-sketch · ✘ pas pour un prototype de code jetable qui répond à une question technique →
  /vf-spike · ✘ pas pour construire l'écran une fois la direction validée → /vf-execute.
  Invocable par l'utilisateur ET par l'agent en autonomie ET par le routeur de développement sur
  une phase de design.
---

# vf-design — Point d'entrée design

Analyse l'intention design de la demande, **détecte la stack du projet**, puis **délègue à
l'agent `vibeflow-design`** (qui porte la table de routage canonique et la doctrine) :

- définir l'identité visuelle / la DA / from scratch → workflow **DA-INIT**
- modifier / refondre / améliorer l'UI → workflow **DESIGN-WORKFLOW** (routing complexité :
  QUICK FIX / PLAN MODE / FULL DESIGN)
- critique / audit / review d'un écran → **DESIGN-WORKFLOW** (intent CRITIQUE)
- explorer une direction / inspiration → **DESIGN-WORKFLOW** (intent INSPIRATION)
- craft ciblé (spacing, typo, couleur, motion, copy, responsive) → **DESIGN-WORKFLOW** (QUICK FIX)

Le **contrat UI** et la **revue UI** (`gsd-ui-phase`, `gsd-ui-review`) n'ont **pas de verbe
dédié** : l'agent les route en interne depuis ce verbe, qui est donc leur seule porte d'entrée.
Seule la maquette jetable a la sienne — `/vf-sketch`.

**Ne réimplémente jamais** la logique d'un outil design : route et délègue.
**Générique** : produit des specs + tokens adaptés à la stack, jamais du code framework-locké imposé.
**Reframe toute sortie en vocabulaire VibeFlow** (cf. `design-vocabulary-map.md`). Ne nomme jamais
les outils design internes bruts.
