---
name: vf-auto
description: "Utiliser quand l'utilisateur délègue l'enchaînement complet **sans supervision** — « fais tout », « en autonomie », « la nuit », « débrouille-toi », « enchaîne les étapes », « va jusqu'au bout tout seul », « je reviens demain matin, avance ». Le périmètre est déjà cadré : la boucle enchaîne cadrage → plan → exécution étape après étape, avec garde-fous. ✘ pas pour exécuter une seule étape déjà planifiée → gsd-execute-phase · ✘ pas pour une tâche triviale d'un seul commit → gsd-quick · ✘ pas pour **arrêter** en gardant le contexte → gsd-pause-work · ✘ pas pour savoir où en est le projet → gsd-progress. Invocable par l'utilisateur ET par l'agent en autonomie."
---

# vf-auto — Mode autonome

## Étape 0 — Aiguillage : quel pilote, puis moteur direct ou équipe

### Pilote unique (D-11) — AVANT tout calcul de taille

Un seul manager pilote une mission — jamais deux, jamais un calcul de dominante :

- Mission **entièrement** design (refonte multi-écrans, harmonisation visuelle, **zéro feature**)
  → `Task(vf-design-manager)` directement avec le brief de mission (champ `livrable:` s'il est
  fourni), puis NE poursuis PAS ce skill : c'est lui qui pilote sa propre équipe (`vf-crafter`,
  `vf-design-judge`).
- **Toute** mission mixte ou dev (même avec un volet UI dedans) → continue ci-dessous vers le
  moteur direct ou `vf-dev-manager` — c'est **lui** qui insère les étages design où il faut, en
  jugeant au plan de bataille (jamais un comptage de lignes/écrans côté design vs dev ici).

Ni score, ni pourcentage, ni heuristique pondérée : une seule question, binaire — « est-ce que
cette mission contient ne serait-ce qu'une feature/un fix dev ? » Oui → dev. Non → design.

### Taille (mission dev/mixte) — moteur direct ou équipe

Détermine N = étapes restantes ciblées (`gsd-tools roadmap analyze` — étapes non complètes
dans le périmètre demandé). Applique le seuil canonique `SEUIL_EQUIPE` (défini dans
`references/mission-contracts.md`, installé sous
`.claude/agents/dev-orchestrator-references/mission-contracts.md`) :

- **N < SEUIL_EQUIPE ET aucun signal de durée** (« la nuit », « débrouille-toi jusqu'au bout »,
  longue absence) → **moteur direct** : poursuis ce skill ci-dessous (mission courte, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → **équipe** : dispatche l'agent `vf-dev-manager`
  (outil Task) avec le brief de mission du contrat, puis NE poursuis PAS ce skill — le manager
  tient la boucle et rend le rapport de mission. Le signal de durée GAGNE en cas d'ambiguïté.

Annonce le choix en une ligne (« mission courte, traitement direct » / « mission longue,
je déploie l'équipe »).

## Moteur direct (mission courte)

Invoque le skill **`gsd-autonomous`** (enchaîne cadrage → plan → exécution par étape pour
toutes les étapes restantes).

Pré-requis : périmètre déjà cadré. Sinon passer par `gsd-discuss-phase` + `gsd-plan-phase`
d'abord.

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
