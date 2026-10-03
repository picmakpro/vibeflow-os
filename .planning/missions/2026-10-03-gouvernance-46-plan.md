# Mission 2026-10-03 — Phase 46 (gouvernance) : cadrage et planification

**Manager :** `vf-dev-manager-p46-cadrage`
**Verrou :** génération `DRIVER.lock.gen.1791010435.82284`, aucun orphelin à l'acquisition.
**Branche :** `gouvernance/phase-46-cadrage`, empilée sur `gouvernance/phase-45-execution` (PR #124,
non mergée).
**Compartiment :** `gouvernance` (`--ws gouvernance` à chaque appel GSD).
**Feu vert :** Willy, message en session principale, 2026-10-03 (« go lance le cadrage de 46 en
parallèle »).
**Périmètre :** cadrage et planification de la Phase 46. Pas d'exécution, pas de merge, pas de
release.

## Plan de bataille (DAG `2026-10-03-gouvernance-46-plan.dag.json`)

`recherche-hooks-46` ∥ `scouting-46` → `cadrage-46` → `plan-46` → `plancheck-46` → `suivi-46` →
`pr-46`

`plan-46` a été rouvert deux fois par `dag.sh reopen` (corrections ciblées après chaque tour de
plan-check).

## Déroulé

1. **Recherche (ADR-045) et état des lieux**, en parallèle :
   - `46-RECHERCHE-HOOKS.md` (Claude Code 2.1.288) ;
   - `46-SCOUTING.md`.

   Commit `82202ff8`. Fait structurant : `TaskCompleted` ne se déclenche que sur `TaskUpdate`, et
   les outils Task ne sont plus fournis par défaut sur les modèles récents depuis 2.1.268.
   L'événement prévu par la spec pour G3/G4 n'existe donc pas sur ce poste.

   La sonde `claude -p` du chercheur a été refusée par la garde d'isolation du worktree. Elle n'a
   pas été contournée.
2. **Cadrage.** C'est le geste du manager. Huit questions ont été remontées d'un bloc par
   `SendMessage(main)`, avec une recommandation pour chacune. Résultats :
   - `46-CONTEXT.md`, `46-DISCUSSION-LOG.md` ;
   - exigences CLOT-01..12 au ledger du compartiment.

   Commit `247194c7`.
3. **Planification** par `vf-coder` (`gsd-plan-phase 46 --ws gouvernance`) : recherche, carte des
   motifs, validation, puis 12 plans en 9 vagues. Le plan-checker interne a rendu 0 bloquant après
   une révision. Commit `8264591d`.
4. **Plan-check frais :**

   | Tour | Juge | Résultat |
   |---|---|---|
   | 1 | deux checkers (objectif et fidélité ; exécutabilité) | 0 bloquant, 2 + 3 avertissements |
   | 2 | un checker, angles combinés | **PASSED**, 0 bloquant, 2 avertissements |

   Révisions ciblées :
   - `a274cfbd` : Q9, mode dégradé, environ 67 commandes de vérification rendues capables de
     rougir, replis sûrs des checkpoints, sonde `n==37` dérivée, note de coupe de 46-05 ;
   - `201edc20` : formulation du checkpoint de rejeu, consigne d'exécution des vérifications en
     session isolée.

   La révision 2 (23 lignes de prose, sans changement de commande) a été vérifiée par le manager
   sur le diff, **pas par un troisième checker frais**.
5. **Q9 et refus du classifieur.** Le premier tour a révélé que le planificateur avait restreint
   G4′ aux agents qui ont Bash, ce qui touchait l'arbitrage Q2 : la question a été posée à Willy
   (Q9). Le même relais apportait une autorisation anticipée du rejeu réel de 46-11. Le commit qui
   gravait cette autorisation dans le CONTEXT a été **refusé par le classifieur auto** (« Instruction
   Poisoning »). Arrêt sans contournement, puis remontée.

   Consigne du head : retirer l'autorisation de tous les artefacts. Le checkpoint de 46-11 la
   redemandera à Willy au moment d'agir. Le reste a été commité (`dd9fb2b1`).
6. **Suivi.** ROADMAP et STATE du compartiment mis à jour à la main, plus la note P46-D-19 dans la
   Phase 47.

## Arbitrages humains

Tous ont pour canal : Willy, AskUserQuestion session principale, 2026-10-03, relayé par la
session principale.

- **Q1 à Q8** : recommandation suivie partout, Q7 = b. Elles deviennent P46-D-01..08.
- **Q9** : G4′ ne vise que les workers et producteurs qui ont Bash (P46-D-02b).

## Décisions du manager (renversables par Willy)

P46-D-02a, 03a, 03b, 06a, 07a, 09 à 19, et 10a (`SubagentStop` fail-open en mode dégradé : G4′ est
ouvert hors mode auto en mode dégradé, trou nommé).

## Points laissés à l'exécution

Deux checkpoints humains bornés, `rejeu-non` / `etape-6-non` par défaut :
- **46-11 T1** : autorisation du rejeu réel en lecture seule sur `~/jarvis-keystone` et
  `~/BusinessFlow-Lab`, étape 5 ;
- **46-12 T1** : porte de G4′, étape 6.

## Témoins

- **Invariants :** `check-mission-invariants.sh` rend 3 (SAIN).
- **Drapeaux d'enchaînement :** `_auto_chain_active` et `auto_advance` valent déjà `false`, lu dans
  `.planning/config.json`.
- **`check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md`** : ✓ conforme.
- **`check-machine-paths.sh`** : ✓, 1910 fichiers.
- **`check-dev-bootstrap.sh`** (`GSD_WORKSTREAM=gouvernance`) : rc=3, « frontmatter illisible —
  silence ». C'est le même résultat que celui relevé par la mission de la 45 ; non rejoué ici sur
  la HEAD de départ.
- **Frontmatter du STATE :** fermé à la ligne 27. `total_plans` passe de 28 à 40,
  `completed_plans` reste à 28.

## Coût (subagent_tokens relevés sur les notifications)

| Agent | Nœud | Jetons |
|---|---|---|
| general-purpose, recherche doc des hooks | recherche-hooks-46 | 159 097 |
| general-purpose, état des lieux | scouting-46 | 241 078 |
| vf-coder, `gsd-plan-phase` | plan-46 | 262 202 |
| gsd-plan-checker A, tour 1 | plancheck-46 | 88 573 |
| gsd-plan-checker B, tour 1 | plancheck-46 | 81 336 |
| vf-coder, révision 1 | plan-46 | 280 567 |
| gsd-plan-checker, tour 2 | plancheck-46 | 111 944 |
| vf-coder, révision 2 | plan-46 | 159 815 |
| **Total** | | **1 384 612** |

- **Mandats émis par le manager :** 8, soit 2 general-purpose, 3 vf-coder et 3 gsd-plan-checker.
  Les agents lancés par le workflow de `gsd-plan-phase` ne sont pas comptés ici : chercheur,
  cartographe, planificateur et 2 checkers internes.
- **Juges de plan frais :** 3 passes pour 2 tours.

## Preuves E6

Le seul bloc `preuves` émis par un `vf-coder` est `[{"verdict":"recette","preuve":"amont"}]`, émis
par le planificateur. C'est une mission de planification, sans exécution : il n'y a aucune preuve
d'exécution à relayer.

## Next step

Exécuter la Phase 46 : `gsd-execute-phase 46 --ws gouvernance`, vague 1 (46-01 ∥ 46-02), dans une
mission de dev qui applique l'ordre d'armement P46-D-11. L'autorisation du rejeu réel se demande à
Willy au checkpoint de 46-11, jamais avant. Aucune release avant la clôture de `fiabilite-v1.0`.
