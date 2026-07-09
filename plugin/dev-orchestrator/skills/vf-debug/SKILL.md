---
name: vf-debug
description: >
  Utiliser quand quelque chose est cassé et qu'il faut diagnostiquer la cause racine —
  « débugge », « ça plante », « j'ai un bug », « erreur », « ça marche pas », « crash »,
  « stack trace ». Débogage systématique avec état persistant à travers les resets de
  contexte. Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-debug — Dépannage

## Pré-étape obligatoire — recherche documentaire (ADR-045)

**Avant** de partir en dépannage empirique, applique la règle **doc-research-before-debug** dès que
l'un de ces déclencheurs est présent :

- le bug implique une **lib / un framework / du code natif / une version d'OS-SDK**, OU
- un **correctif a déjà échoué** sur le même symptôme.

Dans ce cas : d'abord **context7** (`resolve-library-id` + `query-docs`) sur les libs concernées +
**WebSearch/WebFetch** (issues GitHub, versions affectées/corrigées, release notes) pour trouver une
**cause connue / un fix documenté**. Livre des pistes **priorisées et sourcées** (du fix robuste au
hack fragile — tout hack s'arbitre avant application, ADR-031). On ne passe au dépannage empirique
que si la recherche ne donne rien ; elle **précède** les tentatives sans consommer leur budget
(cf. `.claude/rules/doc-research-before-debug.md` + `autonomous-guardrails.md` garde-fou 6).

## Dépannage

Invoque ensuite le skill **`gsd-debug`** (débogage systématique, état persistant).

Reframe toute sortie en vocabulaire VibeFlow : « debug » → **dépannage**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.
