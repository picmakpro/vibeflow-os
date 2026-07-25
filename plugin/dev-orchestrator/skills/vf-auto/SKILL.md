---
name: vf-auto
description: >
  Utiliser quand l'utilisateur délègue l'enchaînement complet **sans supervision** — « fais
  tout », « en autonomie », « la nuit », « débrouille-toi », « enchaîne les étapes », « va
  jusqu'au bout tout seul », « je reviens demain matin, avance ». Le périmètre est déjà
  cadré : la boucle enchaîne cadrage → plan → exécution étape après étape, avec garde-fous.
  ✘ pas pour exécuter une seule étape déjà planifiée → /vf-execute · ✘ pas pour une tâche
  triviale d'un seul commit → /vf-quick · ✘ pas pour **arrêter** en gardant le contexte
  avant de partir → /vf-pause · ✘ pas pour savoir où en est le projet → /vf-progress.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-auto — Mode autonome

## Étape 0 — Aiguillage : moteur direct ou équipe

Détermine N = étapes restantes ciblées (`gsd-sdk query roadmap.analyze` — étapes non complètes
dans le périmètre demandé). Applique le seuil canonique `SEUIL_EQUIPE` (défini dans
`references/mission-contracts.md`, installé sous
`.claude/agents/dev-orchestrator-references/mission-contracts.md`) :

- **N < SEUIL_EQUIPE ET aucun signal de durée** (« la nuit », « débrouille-toi jusqu'au bout »,
  longue absence) → **moteur direct** : poursuis ce skill ci-dessous (mission courte, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → **équipe** : dispatche l'agent `vf-dev-manager`
  (outil Task) avec le brief de mission du contrat, puis NE poursuis PAS ce skill — le manager
  tient la boucle et rend le rapport de mission. Le signal de durée GAGNE en cas d'ambiguïté.

Annonce le choix en une ligne, en vocabulaire VibeFlow (« mission courte, traitement direct » /
« mission longue, je déploie l'équipe »), sans nommer la plomberie.

## Moteur direct (mission courte)

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
