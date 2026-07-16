# mission-loop — détail des 8 phases + exemple de bout en bout

> Référence on-demand du skill `metier-orchestration`. Chargée quand l'orchestrateur a besoin du détail
> d'une phase ou d'un exemple. Métier neutre (transposer au vocabulaire du lab).

---

## Principe directeur

La boucle est un **cycle**, pas une cascade : on peut revenir en arrière (une vérification qui échoue
renvoie à l'exécution ; un trou découvert en planification renvoie à la clarification). Ce qui ne bouge
jamais : **l'orchestrateur ne produit pas le livrable**, et **la clôture exige un objectif vérifié + un
planning à jour**.

## Phase 0 — Récupération de contexte (le plus sous-estimé)

Objectif : ne jamais repartir de zéro. L'orchestrateur reconstitue « où on en est » AVANT de décider.
- **Index-first** : sur un lab à compartiments, lire `.planning/INDEX.md` (liste des compartiments +
  statut 1 ligne), puis **seulement** le `STATE.md` du compartiment concerné par la mission. Ne jamais
  charger tous les compartiments — c'est de la saturation.
- Les hooks planning-core (SessionStart + UserPromptSubmit) injectent déjà ce digest ; l'orchestrateur
  **s'appuie dessus** et ne relit que ce qui manque.
- Lire l'**index** des registres (DECISIONS/BLOCKERS/LEARNINGS) : y a-t-il une décision qui contraint la
  mission ? un blocage déjà connu ? un learning applicable ? Charger le corps d'une entrée uniquement si
  elle pèse sur la décision courante.
- Livrable de la phase : une phrase « état → objectif → écart ».

## Phase 1 — Cartographie

- Poser côte à côte : l'**objectif** (issu de la demande/brief) et l'**existant** (issu de la phase 0 +
  d'un scan si nécessaire).
- Terrain à explorer (code, corpus documentaire, dossiers clients, historique de campagnes) → déléguer
  un `explorer` read-only avec un mandat précis. Ne pas explorer soi-même en profondeur.
- Sortie : carte **fait / manquant / dépendances / risques**.

## Phase 2 — Clarification

- Ne déclencher que sur les **zones d'ombre qui changeraient le plan**. Pas d'interrogatoire.
- Mécanique : menu numéroté sur les points critiques (pattern BMAD), l'utilisateur choisit un angle,
  l'orchestrateur creuse, met à jour, ré-affiche jusqu'à clôture.
- **Gate** : aucune planification tant qu'une zone d'ombre **bloquante** subsiste. Une zone non
  bloquante → hypothèse explicite tracée (dans le plan), on avance.

## Phase 3 — Planification

- Décomposer en **tâches atomiques**. Pour chacune : agent délégué pressenti, entrées, sortie attendue,
  **critère de succès mesurable**, **méthode de vérification** (comment on saura que c'est atteint).
- Séquencer : indépendantes en parallèle, dépendantes en série. Identifier le chemin critique.
- Écrire/mettre à jour `.planning/` (phases si `deliverable`, `BOARD.md` si `continuous`).
- **Plan structurant en autonomie** → Adversarial Plan-Review (voir `verification-types.md`) AVANT
  d'exécuter.

## Phase 4 — Exécution (délégation)

- Un **mandat écrit** par agent (format : `delegation-protocol.md`). Spawn via `Task`.
- Parallélisme : plusieurs tool-uses `Task` dans un seul message pour les tâches indépendantes.
- L'orchestrateur **surveille et réconcilie** — il ne rédige pas, ne code pas, ne produit pas. S'il est
  tenté de « juste écrire un petit bout », c'est le signal qu'il manque un agent : le créer (via
  skill-creator si besoin d'un skill), pas se substituer.

## Phase 5 — Vérification

- **Toujours un agent frais** (jamais l'orchestrateur juge-et-partie).
- Deux angles obligatoires : **factuel** (critères atteints, preuves) et **adversarial** (red-team : ce
  qui casse / n'est pas couvert). Détail : `verification-types.md`.
- Sortie : verdict **ATTEINT / NON ATTEINT** + liste précise des écarts si non atteint.

## Phase 6 — Navette

- NON ATTEINT → corrections **ciblées** sur les écarts (re-déléguer Phase 4), puis re-vérifier (Phase 5).
- **Borne : 3 passes.** Compter les passes. À la 3e sans convergence → **escalade humaine** avec : ce qui
  est atteint, ce qui bloque, 2-3 options. Ne jamais s'acharner en silence.

## Phase 7 — Capitalisation & planning

- Capitaliser via l'**index** des registres (jamais réécrire un registre entier) : DEC-XXX (choix
  structurant), LEARNING (pattern), BLOCKER (obstacle + hypothèses éliminées).
- **Mettre à jour `.planning/STATE.md`** : état courant, livré, prochaines étapes. C'est la condition de
  clôture (le hook `Stop` de planning-core la vérifie).

---

## Exemple de bout en bout (lab « acquisition », métier neutre)

Mission : « lancer une nouvelle séquence cold email pour la cible CTO ».
0. **Contexte** : INDEX → compartiment `acquisition/` STATE = « 2 séquences actives, RDV 4 % ». DECISIONS
   index → DEC-012 « ton direct, pas de pièce jointe ».
1. **Cartographie** : objectif = 1 séquence CTO ; existant = templates + ICP présents ; manquant = angle
   + copy + plan d'envoi. Dépend de l'offre validée.
2. **Clarification** : offre à mettre en avant ? → menu → réponse « audit gratuit ». Zone d'ombre levée.
3. **Planification** : T1 angle (→ copywriter), T2 copy 4 emails (→ copywriter, dépend T1), T3 plan
   d'envoi + métriques cibles (→ analyste-campagnes, //). Critère : séquence prête + RDV cible ≥ 5 %.
4. **Exécution** : Task(copywriter, mandat T1+T2) ; Task(analyste, mandat T3) en //.
5. **Vérification** : Task(reviewer frais) — factuel (4 emails, ton DEC-012 respecté ?) + adversarial
   (« un CTO répondrait-il ? où est le spam-trigger ? »). Verdict : NON ATTEINT (email 3 trop long).
6. **Navette** : re-Task(copywriter) sur email 3 → re-vérif → ATTEINT (passe 2/3).
7. **Capitalisation** : LEARNING « angle audit > angle démo sur CTO » ; STATE `acquisition/` mis à jour
   (« 3 séquences, nouvelle CTO en test »). Clôture.
