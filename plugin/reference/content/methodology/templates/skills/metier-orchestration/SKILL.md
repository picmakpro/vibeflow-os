---
name: metier-orchestration
description: Boucle de mission de l'orchestrateur MÉTIER d'un lab VibeFlow. À charger dès qu'une mission/objectif métier multi-étapes impliquant plusieurs agents spécialistes démarre. Déroule 8 phases — récupération de contexte → cartographie → clarification → planification → exécution (délégation) → vérification (adversariale) → navette exec↔vérif jusqu'à l'objectif → capitalisation + mise à jour du planning. L'orchestrateur PLANIFIE, DÉLÈGUE, RÉCONCILIE ; il ne produit JAMAIS le livrable métier.
---

# metier-orchestration — Boucle de mission de l'orchestrateur métier

> Skill **préchargé** de l'agent orchestrateur métier (posé par `vf-new-lab` dès qu'un lab a ≥2 agents
> spécialistes). Il encode le principe **P3** (un orchestrateur planifie/délègue/réconcilie, ne produit
> jamais) sous forme d'une boucle exécutable. Distinct du `conductor` (méta/gouvernance) et du
> `dev-orchestrator` (spécifique code) : celui-ci pilote le **travail métier quotidien** du lab.
>
> **Iron Law 1** : *« Je planifie, je délègue, je réconcilie — je ne produis JAMAIS le livrable métier
> moi-même. »* (P3)
> **Iron Law 2** : *« Aucune clôture sans objectif VÉRIFIÉ (adversarial) ET `.planning/` mis à jour. »*

---

## Boucle (8 phases)

```
0. CONTEXTE     → lire le planning (index-first) + index des registres → « ce qui a été fait / état »
1. CARTOGRAPHIE → existant vs objectif : fait / manquant / dépendances (déléguer explorer si scan)
2. CLARIFICATION→ trous ou zones d'ombre ? → élicitation (gate). Rien ne se planifie tant qu'un bloquant reste
3. PLANIFICATION→ plan de tâches atomiques (agent délégué + critère de succès + méthode de vérif par tâche)
4. EXÉCUTION    → déléguer aux agents spécialistes (Task, mandat écrit) — l'orchestrateur ne produit rien
5. VÉRIFICATION → agent FRAIS : vérif factuelle + ADVERSARIALE (red-team) contre les critères de succès
6. NAVETTE 4↔5  → objectif non atteint → corriger et re-vérifier (borné : 3 passes) ; au-delà → escalade
7. CAPITALISATION → objectif atteint → registres (index) + MISE À JOUR `.planning/STATE.md`
```

Détail des phases, formats de mandat et types de vérification : voir `references/` (on-demand).

---

## Phase 0 — Récupération de contexte (index-first, jamais saturant)

Avant toute action, reconstituer l'existant **sans saturer le contexte** :
1. **Planning** — lab **à compartiments** : lire `.planning/INDEX.md` d'abord, puis le `STATE.md` **du
   compartiment ciblé par la mission** (borné). Lab **mono** : lire `STATE.md` directement (borné).
   *(Les hooks planning-core injectent déjà ce digest au démarrage — s'y appuyer, ne pas tout relire.)*
2. **Registres** — lire l'**index** de DECISIONS / BLOCKERS / LEARNINGS (jamais le corps entier) pour
   savoir ce qui est déjà décidé/bloqué/appris. Charger une entrée précise uniquement si elle pèse sur la mission.
3. Formuler en une ligne : **« état actuel → objectif de la mission → écart à combler »**.

## Phase 1 — Cartographie

Cartographier l'existant face à l'objectif : ce qui est **fait**, ce qui **manque**, les **dépendances**
et risques. Si le terrain doit être scanné (codebase, corpus, dossiers) → **déléguer un `explorer`**
(read-only). Sortie : une carte fait/manquant/dépendances, base du plan.

## Phase 2 — Clarification (gate)

S'il reste des **trous ou zones d'ombre** qui changeraient le plan : élicitation ciblée (menu numéroté
sur les points critiques). **Aucune planification tant qu'une zone d'ombre bloquante subsiste** (P4).
Zones d'ombre non bloquantes → hypothèse explicite tracée, on avance.

## Phase 3 — Planification

Dériver un **plan de tâches atomiques** : pour chaque tâche → agent délégué pressenti, entrées/sorties,
**critère de succès** et **méthode de vérification**. Écrire/mettre à jour `.planning/` (roadmap/phases
ou BOARD selon la topologie du compartiment). **Plan structurant exécuté en autonomie → Adversarial
Plan-Review** (P3 v4.1 : 2 agents frais reviewent indépendamment avant exécution).

## Phase 4 — Exécution (délégation)

Spawner les **agents spécialistes** du lab via `Task` — **en parallèle** si indépendants, séquentiel si
dépendances. Chaque invocation reçoit un **mandat écrit** : objectif, entrées, sortie attendue, scope,
conditions d'escalade. **L'orchestrateur ne rédige/ne produit JAMAIS le livrable** — il coordonne et
réconcilie les retours. Format de mandat : `references/delegation-protocol.md`.

## Phase 5 — Vérification (adversariale)

**Déléguer la vérification à un agent FRAIS** (reviewer/validator/explorer) — **jamais l'orchestrateur
qui s'auto-juge** (anti-pattern juge-et-partie). Deux angles : (a) **factuel** — les critères de succès
sont-ils atteints, preuves à l'appui ; (b) **adversarial (red-team)** — « qu'est-ce qui casse, quel cas
n'est pas couvert, où l'objectif n'est-il PAS atteint ? ». Types détaillés : `references/verification-types.md`.

## Phase 6 — Navette Exécution ↔ Vérification

Objectif **non atteint** → boucler : corrections ciblées (Phase 4) puis re-vérification (Phase 5).
**Bornée à 3 passes** par défaut. Au-delà → **escalader à l'humain** (pas d'acharnement) en listant ce
qui bloque et les options. Objectif **atteint et vérifié** → Phase 7.

## Phase 7 — Capitalisation & mise à jour du planning

1. **Capitaliser** : DECISIONS (DEC-XXX) pour tout choix structurant, LEARNINGS pour un pattern
   réutilisable, BLOCKERS pour un obstacle rencontré — via l'index (jamais réécrire le registre entier).
2. **Mettre à jour `.planning/STATE.md`** du compartiment : état courant, ce qui vient d'être livré,
   prochaines étapes. **C'est la condition de clôture** — un `.planning/` non à jour = dette (le hook
   `Stop` de planning-core bloque la fin de session sinon).

---

## Garde-fous

- **Jamais produire le livrable métier** (P3) — déléguer, toujours. L'orchestrateur qui code/rédige à la
  place de ses spécialistes est un anti-pattern.
- **Jamais s'auto-vérifier** — la vérification passe par un agent frais (adversarial inclus).
- **Jamais planifier avec une zone d'ombre bloquante ouverte** (Phase 2 est un gate).
- **Jamais boucler indéfiniment** — navette bornée (3), puis escalade humaine.
- **Jamais clôturer sans mettre à jour `.planning/`** ni capitaliser ce qui doit l'être.
- **Escalade > devinette** : hors de son périmètre (sécurité, budget, décision business), l'orchestrateur
  escalade (protocole C4) plutôt que d'étendre silencieusement le scope.

## Références (on-demand)

- `references/mission-loop.md` — détail des 8 phases + exemple de bout en bout (métier neutre).
- `references/verification-types.md` — factuelle / adversariale (red-team) / Adversarial Plan-Review / gate métier.
- `references/delegation-protocol.md` — format de mandat sous-agent + réconciliation des retours.
