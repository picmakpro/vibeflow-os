---
name: vf-auto
description: >
  Utiliser quand l'utilisateur délègue l'enchaînement complet sans supervision — « fais
  tout », « en autonomie », « la nuit », « débrouille-toi », « enchaîne les étapes »,
  « va jusqu'au bout tout seul ». Le périmètre est déjà cadré. Invocable par l'utilisateur
  ET par l'agent en autonomie.
---

# vf-auto — Mode autonome

Invoque le skill **`gsd-autonomous`** (enchaîne cadrage → plan → exécution par étape pour
toutes les étapes restantes).

Reframe toute sortie en vocabulaire VibeFlow : « autonomous » → **mode autonome**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Pré-requis : périmètre déjà cadré. Sinon passer par **`vf-plan`** d'abord.

## Garde-fous (non supervisé)

En mode autonome **non supervisé** (« la nuit », « débrouille-toi »), applique la doctrine
des cinq garde-fous — anti-thrash, anti-régression, critère d'arrêt vert/plafond,
séparation anti-triche, rapport de synthèse au réveil. Détail chargé on-demand depuis
`references/autonomous-guardrails.md`. En clair : la boucle **ne triche jamais** (aucun test
affaibli), **ne casse jamais un test vert**, **abandonne un point bloqué après 3 essais**, et
remonte un **rapport de synthèse** à la fin.

## Vérification réelle (projets mobiles)

Le mode autonome enchaîne cadrage → plan → exécution et vérifie les **gates techniques** (lint,
types, tests unitaires). Sur un projet **mobile (Expo/React Native)**, ça ne suffit pas : un écran
peut compiler et crasher au runtime. Avant de marquer une phase mobile *done*, dispatche l'agent
**`vf-test-orchestrator`** (module `mobile-test-team`) pour la **boucle de vérification réelle +
correction** (Maestro sur cible → fix cloisonné → re-test jusqu'au vert / plafond). C'est ce qui
transforme « le code est écrit » en « l'app marche vraiment ». Absent ce module, reste sur les
gates techniques et signale la limite.
