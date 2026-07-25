---
name: vf-dev
description: >
  Utiliser **en dernier recours**, quand la demande de dev ne désigne aucun geste précis —
  « aide-moi à avancer », « pilote-moi ça », « je sais pas quel geste il faut », « fais ce
  qu'il faut », « occupe-toi de ce projet », « débrouille cette histoire ». Point d'entrée
  générique : analyse l'intention, puis délègue au verbe qui la porte réellement.
  ✘ pas quand le geste est identifiable — passer directement par le verbe : /vf-plan,
  /vf-execute, /vf-debug, /vf-test… · ✘ pas pour enchaîner tout le reste sans supervision →
  /vf-auto · ✘ pas pour un simple point d'avancement → /vf-progress.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-dev — Point d'entrée générique

Analyse l'intention de la demande, puis **délègue à l'agent `vibeflow-dev`** (qui porte
la table de routage canonique) ou directement au verbe `/vf-*` adéquat :

- réfléchir / explorer → `vf-brainstorm`
- planifier / cadrer → `vf-plan`
- coder une feature structurante → `vf-execute` (ou `vf-quick` si trivial)
- tester / valider → `vf-test` ; relire → `vf-review` ; débugger → `vf-debug`
- design / UI / DA / « c'est moche » / refonte visuelle → `vf-design`
- tout faire en autonomie → `vf-auto` ; livrer → `vf-ship` ; où on en est → `vf-progress`
- amorcer l'environnement / nouveau projet → `vf-init`

**Ne réimplémente jamais** la logique d'un outil : route et délègue.
**Reframe toute sortie en vocabulaire VibeFlow** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni Superpowers.
