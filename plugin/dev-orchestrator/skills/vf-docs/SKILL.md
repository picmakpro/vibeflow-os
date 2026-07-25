---
name: vf-docs
description: >
  Utiliser quand la documentation du projet doit être écrite ou remise à jour — « mets à
  jour la doc », « génère le README », « la doc est périmée », « le README raconte
  n'importe quoi », « documente ce qu'on vient de faire », « faut expliquer comment ça
  s'installe ». Produit ou rafraîchit la doc du projet, vérifiée contre le code réel et
  non contre ce qu'on croit avoir livré.
  ✘ pas pour comprendre un code existant → /vf-map · ✘ pas pour extraire les décisions et
  les apprentissages → /vf-learn · ✘ pas pour figer le périmètre d'une feature → /vf-spec.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-docs — Mise à jour de la documentation

Délègue à `gsd-docs-update` : génération ou mise à jour de la documentation du projet, avec
vérification des affirmations contre la base de code.

Reframe toute sortie en vocabulaire VibeFlow : « docs-update » → **mise à jour de la doc**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-docs-update` à
l'utilisateur.

Règle de fond : **la doc décrit ce qui existe**. Une affirmation non vérifiable dans le code est
signalée, jamais écrite au conditionnel.

Enchaînement typique : `vf-execute` → `vf-test` → `vf-docs` → `vf-ship`.
