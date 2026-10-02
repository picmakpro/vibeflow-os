# Mission — rattrapage du manuel utilisateur jusqu'à v2.68.0 + Phase 41.2, check-manual en CI

- Date : 2026-10-02
- Pilote : vf-dev-manager, dispatché par vibeflow-head (session principale de Samuel)
- Arbitrage d'origine : Samuel, AskUserQuestion session principale, 2026-10-02 — « Oui, avec check-manual en CI »
- Branche : `docs/manuel-rattrapage-v2.68` (worktree `.claude/worktrees/manuel`, partie d'`origin/main` `0c14757b`)
- PR : https://github.com/picmakpro/vibeflow-os/pull/132 — ouverte, NON mergée (touche `.github/workflows/ci.yml` : revue @picmakpro requise, à ne pas contourner)
- Régime : PR de documentation et de CI, pas de release, pas de bump, pas de tag (ADR-073)

## Plan de bataille

DAG (`dag.sh`, fichier hors arbre) :

| Nœud | Étape | Dépendances | Worker | Statut |
|---|---|---|---|---|
| `inv` | inventaire revérifié + carte de placement, partition en deux lots disjoints | — | general-purpose (lecture seule) | done |
| `exec-corr` | lot A : 8 pages (verrou, presets, skills, gates, C5) | inv | vf-coder (worktree `manuel`) | done |
| `exec-ajouts` | lot B : 29 fichiers dont `toc.yml` et 4 pages neuves | inv | vf-coder (worktree `manuel-b`) | done |
| `exec-ci` | jointure `--no-ff`, liens croisés, étape CI, en-têtes | exec-corr, exec-ajouts | vf-coder | done |
| `revue-1` | exactitude contre le code, régime plein | exec-ci | vf-reviewer | done (correctifs requis) |
| `verif-gates` | rejeu des jobs `gates` et `tests` | exec-ci | general-purpose | done côté disque, worker resté muet |
| `fix-revue-1` | correction ciblée M1, M3, m1-m5 | revue-1 | vf-coder | done |
| `revue-2` | re-revue du comblement, régime plein | fix-revue-1 | vf-reviewer | done (PASS) |
| `livraison` | rejeu `gates` au HEAD, attribution d'un rouge, push, PR, suivi CI | revue-2, verif-gates | vf-coder | done |

Les lots A et B ont tourné en parallèle dans deux worktrees, sur des ensembles de fichiers disjoints. Seul le lot B touchait `toc.yml`. Le lot A n'avait le droit de poser aucun lien vers les pages neuves, pour que C3 reste vert quel que soit l'ordre de jointure.

## Ce qui est livré

Commits de la branche (base `0c14757b`) :
- `53b888ff` lot A : le verrou de driver est décrit comme appliqué, avec ses limites, son périmètre borné au lab (C6/C7), la reprise par `takeover`, le registre des agents et le champ `confiance`. Ajouts aussi : presets `dev`/`dev-mobile`/`dev-audite`, socle `conductor` + `consolidator`, 22 skills (`vf-notify`, `vf-split-planning`), huit commandes, quatre lignes de plus dans le tableau des gates. C5 est corrigé.
- `0949fabf` lot B : deux pages neuves, `sujets-en-parallele` / `parallel-topics` et `ranger-ce-qu-on-cree` / `tidying-up-after-yourself`. Le dépannage passe de six à neuf pannes. Mises à jour de `recalc-planning.sh` (opt-in, non câblé), du registre et des orphelins, de la section `## Budgets`, de `.worktreeinclude`, de `use_worktrees`, des conventions de contribution (`Gate-Touche:`, citation d'arbitrage, `Ajout-Retrait:`, `pre-push`/`post-merge`), de l'ADR-076 et du glossaire.
- `b162efef` jointure des deux lots.
- `fe1728de` liens croisés après jointure et presets dans `choisir-ses-modules`.
- `ed58f1c2` étape « check-manual » ajoutée au job `gates` de `ci.yml`. Les en-têtes de `check-manual.sh` et `build-nav.sh` sont mis à jour : la clause D-13 « jamais référencé dans ci.yml » est retirée. Trailers `Gate-Touche:` (ci.yml, check-manual.sh) et `Ajout-Retrait:`.
- `deef907a` corrections de la revue d'exactitude.

Le manuel passe de 45 à 47 pages par langue. 40 fichiers sont touchés : 39 sous `manual/`, plus `ci.yml`.

## Étages de vérification — verdicts

- Revue 1 (vf-reviewer, confiance 0,8) : correctifs requis, aucun bloquant, 3 majeurs et 5 mineurs.
  - M1 : `/vf-update` ne pose pas `use_worktrees=false` sur un module déjà à jour.
  - M2 : des fonctions de la 41.2 sont absentes du tag `v2.68.0`.
  - M3 : la trace de la dérogation au verrou n'est écrite que dans la mesure du possible.
  - m1 à m5 : portée de `.worktreeinclude`, sujet du verbe « commiter », liste non exhaustive des gestes refusés, chemin selon le scope, rôle du hook de fin de geste.
- Revue 2 (vf-reviewer, confiance 0,9) : PASS. Les 7 propriétés sont atteintes en FR et en EN. Restent 4 mineurs cosmétiques, classés `no-op`.
- Gates : rejeu local à `ed58f1c2` (18 étapes rejouées, 0 échec) puis à `deef907a` (18 rejouées, 3 sautées car réservées à un push sur `main`, 0 échec). Sur la CI GitHub de la PR, le run 37055801635 est vert sur les 4 jobs, et le log du job `gates` montre bien l'étape check-manual exécutée (`✓ C0` … `✓ check-manual: tous les contrôles passent.`).
- Tests (rejeu local macOS, `ed58f1c2`) : 98 suites, dont 7 rouges.
  - 6 sont rouges à l'identique sur la base `0c14757b`. Elles sont propres à macOS, la CI Linux est verte.
  - La 7ᵉ, `test-inject-mcp-tools.sh` (T22g, `echo: write error: Broken pipe`), est verte 3 fois sur 3 quand on la rejoue seule à `deef907a`. Le diff ne touche aucun fichier qu'elle lit : c'est un rouge intermittent (flaky), pas une régression.
  - Sur la CI GitHub, le job `tests` est vert.

## Décisions prises en autonomie

- **M2 (fonctions de la 41.2 absentes du dernier tag publié)** : le manuel décrit l'état de `main`, sans mention « disponible à la prochaine version ». Trois raisons :
  - une telle mention périme à la release suivante, et C5 ne peut pas la contrôler puisqu'elle ne porte aucun numéro ;
  - `commandes.md` documentait déjà `/vf-split-planning` sur `main` depuis la PR #130 ;
  - selon l'ADR-073, une PR de documentation part avec la prochaine release fonctionnelle, qui embarque forcément la 41.2.

  Tranché par le manager sans panel (coût faible, réversible avant le merge). Samuel ou le head peuvent le renverser dans la PR.
- **Partition en deux lots parallèles dans deux worktrees** plutôt qu'en séquence. Les ensembles de fichiers étaient disjoints et vérifiés, et la jointure s'est faite sans conflit.
- **Nœud de vérification resté muet** : le juge `verif-gates` a écrit ses journaux et ses codes de sortie sur disque, puis n'a plus répondu à deux réveils, et aucun processus ne tournait. Je ne l'ai pas remplacé par un juge concurrent : l'attribution du rouge restant et le rejeu final ont été confiés au nœud `livraison`, dans un ordre séquentiel. Son worktree jetable `base-wt` a été retiré par le manager.

## Points ouverts pour l'humain

1. **Revue @picmakpro sur la PR #132** (elle touche `.github/`) : le merge appartient à l'humain, jamais par contournement.
2. **CHANGELOG** : le `## Non releasé` du `CHANGELOG.md` racine dit « (vide) ». Pourtant la Phase 41.2 est sur `main` sans entrée et sans bump de module : `plugin/conductor/VERSION` vaut v1.46.0, comme au tag `v2.68.0`. Cette lacune est à combler avant la prochaine release, sinon ses notes passeront `vf-split-planning` sous silence. Je l'ai laissée hors périmètre.
3. Le hook de fin de geste n'agit que dans un dépôt armé, et aucun code ne pose la sentinelle `.planning/.fin-de-geste-armed`. Le manuel dit de l'armer à la main. Il faut décider si l'installeur doit la proposer.

## Budgets

`check-method-budget.sh --quiet` rend 0. Tous les dépassements signalés existaient avant la mission :
- `STATE` du sujet `gouvernance` : 21 Ko ;
- BACKLOG : 36 sujets ouverts ;
- ROADMAP `fiabilite` : 144 Ko ;
- worktrees actifs : 5 pour un budget de 3 ;
- branche `feat/phase-41-3-sobriete-methode` rangeable ;
- deux branches distantes à valider.

La mission a créé deux worktrees (`manuel-b`, `base-wt`) et une branche locale (`docs/manuel-rattrapage-v2.68-b`), tous retirés. Le worktree `manuel` reste en place tant que la PR n'est pas mergée : il ne peut pas encore être rangé.

## Décompte

- Agents dispatchés : 9 (inventaire, lot A, lot B, jointure/CI, revue 1, vérification des gates, correction ciblée, revue 2, livraison), comptés sur les mandats émis.
- Boucle de revue : 2 tours consommés.
- Les workers n'ont recueilli aucun `estimate:` ni `actuals:`.

## Next step

La revue @picmakpro de la PR #132, puis son merge. Ensuite, remplir le `## Non releasé` du CHANGELOG avec la Phase 41.2, pour que la prochaine release fonctionnelle embarque la 41.2 et ce manuel ensemble.

## Preuves E6

| Commande | Code de sortie | SHA |
|---|---|---|
| `bash plugin/conductor/scripts/check-mission-invariants.sh` (démarrage) | 3 (SAIN) | 0c14757b |
| `bash manual/.tools/check-manual.sh` (état de départ, C5 rouge) | 1 | 0c14757b |
| `bash manual/.tools/check-manual.sh` | 0 | deef907a |
| `replay-ci-jobs.sh --job gates` | 0 | deef907a |
| `HOME=$(mktemp -d) bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (×3) | 0 | deef907a |
| `gh pr checks 132` (run 37055801635, 4 jobs) | 0 | deef907a |
| mutation : `check-manual.sh <copie avec v9.9.9 en dur>` | 1 (C5 ✗) | ed58f1c2 |
| `bash scripts/check-gate-touche.sh` | 0 | ed58f1c2 |
| `bash plugin/conductor/scripts/check-ajout-retrait.sh --strict` | 0 | ed58f1c2 |
| `bash scripts/check-affirmation-non-mesuree.sh` (aucune occurrence dans `manual/`) | 0 | deef907a |

Ce bloc est lu par le gate de sortie (contrat `mission-contracts.md`, § Contrat de preuves E6). Les éléments `revue` sont relayés verbatim depuis les blocs typés des workers. Le commit qui porte ce rapport change le HEAD sans toucher au manuel ni à la CI, donc les verdicts restent valables pour l'arbre de `deef907a`.

```json
{
 "preuves": [
  {"verdict": "gate:check-mission-invariants", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "0c14757b8dcc6ba5e4b1d97e4bb12ca7c8eb1d4a"},
  {"verdict": "gate:check-manual", "commande": "bash manual/.tools/check-manual.sh", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "gate:replay-gates", "commande": "replay-ci-jobs.sh --job gates --root /Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/manuel", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "gate:inject-mcp-tools-isole", "commande": "HOME=$(mktemp -d) bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh (x3)", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "gate:ci-github", "commande": "gh pr checks 132", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "gate:mutation-C5", "commande": "bash manual/.tools/check-manual.sh <copie jetable avec v9.9.9 en dur>", "exit_code": 1, "sha": "ed58f1c2"},
  {"verdict": "gate:gate-touche", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "ed58f1c2"},
  {"verdict": "gate:ajout-retrait", "commande": "bash plugin/conductor/scripts/check-ajout-retrait.sh --strict", "exit_code": 0, "sha": "ed58f1c2"},
  {"verdict": "gate:affirmation-non-mesuree", "commande": "bash scripts/check-affirmation-non-mesuree.sh", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "revue", "commande": "bash manual/.tools/check-manual.sh (revue 2, vf-reviewer, PASS, confiance 0.9)", "exit_code": 0, "sha": "deef907a23e81f60ba38bc036968b8179baeefc6"},
  {"verdict": "recette", "preuve": "amont"}
 ]
}
```
