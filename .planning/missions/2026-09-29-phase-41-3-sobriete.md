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
