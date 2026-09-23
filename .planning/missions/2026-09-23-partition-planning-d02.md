# Mission — Partition réelle du planning (D-02), 2026-09-23

**Mandat** : exécuter le déclencheur de reprise D-02 laissé ouvert par la Phase 39 — partitionner
réellement `.planning/` de `vibeflow-os` pour que Samuel et Willy cessent d'éditer les mêmes
`ROADMAP.md`/`STATE.md`/`REQUIREMENTS.md`. Arbitrage Samuel, AskUserQuestion session principale,
2026-09-23 (« il faut absolument finir la phase 39 »).

**Branche** : `feat/partition-planning-d02`, PR ouverte vers `main`, **non mergée**.

## Diagnostic (checkpoint initial)

Le geste mécanique tient en une commande (`workstream create <nom> --migrate-name <nom>`,
`workstream.cjs:46-94`), prouvé sur clone en Phase 39. Mais la CI de ce dépôt traite la racine
réelle comme l'oracle vivant de sa propre non-partition dans plusieurs étapes de
`.github/workflows/ci.yml` — les repointer faisait partie du mandat dès le checkpoint, pas une
découverte a posteriori.

## Découpage retenu

- `fiabilite` — reçoit tout l'existant (phases 1-41, toutes les familles d'exigences), compartiment
  **par défaut** (pointeur committé `.planning/active-workstream` = `fiabilite`).
- `gouvernance` — reçoit le jalon `gouvernance-labs-v1.0` (section ROADMAP, `FABR-01..05`, dossier
  `VFDO-42-.../` déjà entièrement planifié) — extrait verbatim, rien réécrit.

## Séquence réelle (deux arrêts avant exécution)

1. **Checkpoint découpage** — options A/B/C proposées (exécuter maintenant avec exception ADR-069
   datée / attendre le merge d'une PR en vol sur ROADMAP/REQUIREMENTS / partition coquille vide).
   Samuel a tranché B, noms `fiabilite`/`gouvernance`, chantier CI inclus.
2. **PR bloquante trouvée en cours de route** — `feat/phase-41-volet-admin` (PR #90) éditait
   `ROADMAP.md`/`REQUIREMENTS.md`/`STATE.md` en direct au moment du dispatch (volet admin de la
   Phase 41 repris le jour même, D-02bis arbitrage Willy). Signalé par SendMessage avant tout
   dispatch de migration. Débloqué après merge de la PR #90 (14h41) : rebase sur `main` (`e70b22b`)
   avant toute mesure.

## Exécution

Plan de bataille en DAG (`.planning/missions/dag-2026-09-23-partition-planning-d02.json`) : deux
nœuds de frontière à périmètres disjoints (`.planning/**` vs `.github/workflows/ci.yml` + 3 scripts),
dispatchés en parallèle **dans le même worktree** — erreur de process signalée et corrigée en cours
de mission (cf. § Incidents).

**Commits** (10, `e70b22b..39acd36`) :

1. `777e4f2` — migration mécanique (`workstream create gouvernance --migrate-name fiabilite`).
2. `5ef4b37` — carve-out ROADMAP.md (jalon gouvernance-labs-v1.0).
3. `1d7870b` — carve-out REQUIREMENTS.md (`FABR-01..05`).
4. `20f8daf` — déplacement du dossier `VFDO-42-.../`.
5. `6002c2f` — CI : `check-state-integrity`, BLOC 2a/2b (fixture flat + conformité racine réelle),
   `check-divergence.sh` attend `rc=0` sur la racine.
6. `2f4d388` — `check-requirements-survival.sh`/`restore-requirements-ledger.sh`/
   `requirements-survival-detect.sh` rendus workstream-aware (LEDG-01/02).
7. `f9ea535` — comble un gap **pré-existant** (Phase 36, dossier orphelin `.gitkeep` volontaire,
   commit `306e25d` du 2026-09-16) révélé — pas causé — par l'activation du gate.
8. `12cbae2` — DAG de mission committé (convention `dag-*.json` déjà en usage).
9. `466bce6` — merge `origin/main` (PR #92, séquence rulesets/PROT-01 corrigée) — 1 conflit résolu
   sur `fiabilite/ROADMAP.md` (ligne Phase 41), sans réintroduire les lignes 42-50 déjà chez
   `gouvernance`.
10. `f688e2b` + `ced7577` — correctifs de revue (voir § Revue).
11. `39acd36` — hygiène documentaire finale (STATE à la main, note Willy).

## Revue (`vf-reviewer`)

Un tour, deux findings réels sur 302 fichiers / 568+/288- (base `e70b22b`, avant merge de PR #92) :

- **Bloquant** — `.github/workflows/ci.yml:350` restait câblé sur `.planning/STATE.md` (absent
  après migration). Corrigé (`f688e2b`) → `.planning/workstreams/fiabilite/STATE.md`, revérifié
  `rc=0`.
- **Majeur** — `check-mission-exit.sh` (E4) codait en dur `.planning/ROADMAP.md`/`STATE.md`, non
  câblé en CI mais utilisé par tout manager en fin de mission. Corrigé (`ced7577`), même patron que
  le correctif LEDG-01/02, suite de tests rejouée (28/28), aucune régression.
- Tout le reste PASS : fidélité verbatim du carve-out (diff octet pour octet contre l'original),
  `Gate-Touche` conforme, aucun fichier hors périmètre, traçabilité des arbitrages conforme.

## Incidents

- **Worktree partagé entre deux workers parallèles** (garde-fou « un seul agent par copie de
  travail » enfreint). Signalé dès qu'un worker a rapporté un diff `ci.yml` inattendu en cours de
  mandat. Vérifié après coup : aucune perte — les deux workers committaient par pathspecs explicites
  (`git add <chemins>`, jamais `-A`), ce qui a évité toute collision réelle. Règle reprécisée pour
  la suite de la mission : un worktree par worker, même à périmètres de fichiers disjoints.
- **Dossier Phase 36 pris à tort pour un débris** — proposition initiale de le supprimer pour faire
  passer `check-divergence.sh` au vert, rejetée par Samuel (le `.gitkeep` est un arbitrage
  délibéré du 2026-09-16, `306e25d`). Corrigé : option (c), documentation de l'état réel au lieu
  d'une suppression. Leçon retenue : vérifier `git log --all -- <chemin>` avant de qualifier un
  fichier de débris.

## Preuves rejouées (post-merge PR #92, HEAD `39acd36` au moment de la rédaction)

- `check-divergence.sh --path .` → `rc=0`, conforme, aucun signal S2/S4/S5.
- `check-workstream-pointer.sh --path .` (sans `GSD_WORKSTREAM`) → `rc=0`, canal `store-partagé`,
  résout `fiabilite`.
- Les 3 étapes CI critiques (`check-state-integrity`, « Gates workstream-aware… », `check-divergence
  en CI ») extraites et rejouées en `bash -e` sans pipefail après le merge de PR #92 : les trois
  `EXIT=0`.
- `check-blueprints.sh` : défaut connu, sans rapport (blueprints sous `.claude/worktrees/`), signalé
  non corrigé, conforme à la consigne de mission.

## Ce qui reste ouvert

- Le job `tests` complet (découverte + exécution de toutes les suites du dépôt) n'a **pas** été
  rejoué séquentiellement en local jusqu'au bout — sur consigne explicite du dispatcheur (« n'attends
  pas le rejeu local du job tests, pousse et ouvre la PR, la CI GitHub parallélise »). Le verdict
  réel viendra du run GitHub Actions sur la PR.
- `gouvernance/STATE.md` (gabarit frais posé par le moteur) échoue `check-state-integrity.sh` (pas
  de ligne `^Phase:`, pas de champ `milestone:`) — défaut du gabarit du moteur lui-même, pré-existant
  à cette mission, jamais invoqué par la CI sur ce chemin, se résorbera au premier travail réel de
  Willy. Consigné, non corrigé.
- Aucune release (ADR-073 : planning et gates, rien de fonctionnel distribué).

## Consigne pour Willy

Voir `.planning/workstreams/gouvernance/STATE.md` § « Note pour Willy » — résumé : le compartiment
`gouvernance` reçoit les Phases 42-50, le pointeur par défaut committé pointe sur `fiabilite` (donc
`--ws gouvernance` ou `GSD_WORKSTREAM=gouvernance` explicite est nécessaire pour travailler dans son
compartiment), le contenu déjà planifié de la Phase 42 est intact, et l'exécution du jalon reste
gatée par la clôture de `fiabilite-v1.0` (inchangé par cette partition).
