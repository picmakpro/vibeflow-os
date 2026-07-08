---
name: vf-dev
description: >
  Utiliser quand l'utilisateur exprime une demande de dev en langage naturel sans
  préciser l'étape — « code ça », « on s'occupe de la feature X », « occupe-toi de ce
  projet », « aide-moi à avancer » — ou quand l'intention est ambiguë et doit être
  routée. Point d'entrée générique de VibeFlow : analyse l'intention puis délègue au
  bon verbe. Invocable par l'utilisateur ET par l'agent en autonomie.
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
