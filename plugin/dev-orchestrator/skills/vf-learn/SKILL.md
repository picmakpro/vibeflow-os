---
name: vf-learn
description: >
  Utiliser quand on veut capitaliser sur ce qui vient d'être fait — « qu'est-ce qu'on a
  appris ? », « extrais les décisions », « pourquoi on avait décidé ça déjà ? », « garde
  les leçons de ce sprint », « construis le graphe de connaissance », « qu'est-ce qui nous
  a surpris ». Remonte décisions, leçons, patterns et surprises d'un cycle, et les relie
  dans le graphe de connaissance du projet.
  ✘ pas pour cartographier le code existant → /vf-map · ✘ pas pour disséquer un cycle qui
  a échoué → /vf-forensics · ✘ pas pour mettre à jour la doc du projet → /vf-docs.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-learn — Apprentissages & graphe de connaissance

Délègue, selon la demande :

- `gsd-extract-learnings` — extraire **décisions, leçons, patterns et surprises** d'une étape ou
  d'un jalon terminé ;
- `gsd-graphify` — **construire, interroger et inspecter** le graphe de connaissance du projet
  (« pourquoi cette décision ? », « qu'est-ce qui dépend de quoi ? »).

Reframe toute sortie en vocabulaire VibeFlow : « learnings » → **apprentissages**, « knowledge
graph » → **graphe de connaissance**, « phase » → **étape/sprint**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni ces cibles à l'utilisateur.

Frontière avec `/vf-map` : là-bas on lit **le code** pour comprendre le système ; ici on lit
**l'historique des décisions** pour comprendre pourquoi il est comme ça.

Enchaînement typique : `vf-milestone` (bilan de jalon) → `vf-learn` (capitaliser) → `vf-plan` (le
jalon suivant part mieux informé).
