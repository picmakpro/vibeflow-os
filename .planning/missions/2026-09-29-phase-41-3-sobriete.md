# Mission Phase 41.3 — vague 1 « appliquer ici » (2026-09-29)

Branche `feat/phase-41-3-sobriete-methode`, base `6e7c40d7`. Plans 41.3-01..04 sur disque ; 01 et 02 exécutés, 03 et 04 (vague 2) non.
Arbitrages (Samuel, AskUserQuestion session principale, 2026-09-29) : STATE `gouvernance` laissé à Willy ; stash exporté puis dropé ; 4 worktrees non mergés intouchés.

## Fait
- SOBR-02 : STATE `fiabilite` 146 152 o → 2 961 o ; corps archivé (`archives/state/`), réversible (blob `0d6f225a` + `eb7fe2b9`, `cmp` rejoué par la revue).
- SOBR-01 : stash `cb4c8ed4` exporté (`archives/stash/`), `apply --check` vert sur sa base, puis dropé ; `check-method-budget.sh` constate branches, stash, mémoires, branches distantes de Samuel seulement (Willy jamais candidat) ; 0 mémoire hors git/index.
- SOBR-03 : `check-blueprints` n'élague que `.claude/worktrees` (9 blueprints comptés au lieu de 45) ; `.worktreeinclude` recopie `.claude/hooks/` et `.claude/scripts/`.

## Preuves E6
- Sonde worktree : témoin `.claude/hooks/` recopié avec la ligne, absent sans elle ; témoin positif `agent-memory` présent les deux fois ; témoin négatif `logs` absent. `.worktreeinclude` est lu dans l'arbre de travail du checkout principal.
- Revue : 3 tours (gaps → gaps → PASS). Suite `check-method-budget` à 248 assertions, 24 mutants MU + 3 MW tués ; GNU bash 5.2 vert.
- Non-régression, `6dd45fb8` : job `gates` rc 0 (16 étapes) ; `tests` : 93 suites, 4 rouges héritées de la base (même ensemble, `comm`), 0 introduite.
- Sobriété : `.planning` hors archives +714 / −1 578.

## Résiduels (revue finale, mineurs)
Prose inversée dans l'en-tête `check-method-budget.sh:41-43` ; libellé RO3 plus fort que la mesure (`cksum` agrégé) ; 5 règles d'enveloppe non opposables une à une ; troncature : `À VALIDER` émis quand même sur les PR visibles ; labs avec `upstream` → NON VÉRIFIABLE permanent (sûr) ; suite ×4 plus lente sous macOS (61 s).

## Reste
SOBR-04..08 (plans 41.3-03, 41.3-04 : 04 touche `ci.yml`, donc revue `@picmakpro`) ; pose du `.worktreeinclude` chez les labs (03) ; bump conductor et CHANGELOG à la prochaine release fonctionnelle.

## Vague 2 (2026-09-30) — feu vert de Samuel, session principale, 2026-09-30
- Plans 03 et 04 re-validés contre HEAD : un bloquant, l'archivage n'était qu'une option manuelle → `--auto`, déclenché par la clôture E7 et par le hook Stop.
- Livré : budgets BACKLOG, index mémoire et ROADMAP, avec archivage automatique tracé et réversible ; ADR-076 (précision d'ADR-031) ; relecture adverse avant le tag (`CLAUDE.md`) ; `check-ajout-retrait` ; garde de fin de geste, option (a) (AskUserQuestion session principale, 2026-09-30) ; E7 en delta.
- Revue : 3 tours ; le dernier rend PASS. Les résidus sont tracés au BACKLOG (entrée DIFFÉRÉ du 2026-09-30).
- 4 suites rouges en local : vertes en CI GitHub sur `main` (run 36621666163) et sur la PR (36636686789). Cause : sous HOME jetable, ni moteur GSD ni PyYAML.
- Non-régression à `4d701558` : `gates` rc 0 ; `tests` 95 suites, 4 rouges d'environnement, 0 introduite ; CI de la PR verte (run 36772566392).

## Test isolé (protocole et sorties : scratchpad `iso41b/RAPPORT.md`)
Protocole : HOME et TMPDIR jetables, clone frais à `4d701558`, lab `git init` avec un remote nu, installation `VIBEFLOW_CACHE=… vibeflow-update.sh --scope project install --with-deps conductor|dev-orchestrator` (rc 0).
- Empreintes avant = après : `~/.claude` (1825 fichiers, `c36226707db55b03`) ; dépôt (HEAD, status, stash, worktrees, refs).
- S1 `.worktreeinclude` posé, idempotent, sans doublon CRLF. S2 DÉPASSÉ ×4. S3 `--auto` ARCHIVÉ ×3, STATE de 15 372 à 314 o ; second archivage OK ; source sale → REFUSÉ ; verrou → refus en 0,19 s ; retour arrière `cmp` identique ×5.
- S4 garde : 2,2,2 puis coupe-circuit (JSON valide, même sans jq ni python3), préexistant jamais cité, non mergé jamais touché. S5 E7 : MANQUE, SAIN, INDÉTERMINÉ. S6 ajout-retrait : 1, refus, 0, 0. S7 : rien supprimé.
- Limites : aucun vrai `claude --worktree` (l'authentification vient du trousseau, hors du HOME jetable) ; en scope project, `.worktreeinclude` ne sert pas, car les scripts arrivent par git.

## Solde final
`.planning` hors archives : +821 / −2141 (net −1320). STATE `fiabilite` de 146 152 o à 2 762 o. BACKLOG de 88 381 o à 77 448 o (36 sujets ouverts pour un budget de 20). ROADMAP `fiabilite` de 168 463 o à 145 619 o (budget 64 Ko).
