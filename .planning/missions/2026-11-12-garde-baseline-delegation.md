# Mission hors phase — G-1 : une ligne de délégation ne vaut pas arbitrage (2026-11-12)

Mode autonome. Manager : vf-dev-manager. Branche `fix/garde-baseline-delegation`, base `ab8f3e64`
(`origin/integration/cockpit-audit`), PR vers `integration/cockpit-audit`. Verrou
`--ws=fiabilite --phase=72`.

Demande d'origine : Samuel, message session principale, 2026-11-12 : « oui tu as raison », en
réponse au constat que la garde de la baseline du budget d'instructions accepte la ligne de
délégation que portent presque tous les commits des agents. Lecture de la session principale : la
durcir avant la release (option recommandée ; décision déléguée par Samuel, message session
principale, 2026-11-08). Ce n'est pas un arbitrage détaillé de Samuel sur la règle elle-même.

## Résultat

Dans G-1 (`scripts/check-baseline-arbitrage.sh`), une ligne de message de commit qui porte le
radical « délégu » ou « delegu » (toute casse, accentuée ou non, NFC ou accent aigu combinant) ne
vaut plus citation d'arbitrage. La règle s'applique aux trois usages de la citation (hausse de la
colonne INSTRUCTIONS, retrait d'une ligne dont la cible existe encore, neutralisation d'une
sentinelle), parce qu'ils passent tous par un seul prédicat (`ligne_citation_ok`). Une citation
directe portée par une autre ligne du même message reste acceptée, et c'est elle qui est recopiée
dans `AVERTISSEMENT-LIGNE-RETIREE-ARBITREE`. Sur un refus, une ligne
`INFO-LIGNE-DELEGATION-ECARTEE` est imprimée avant le verdict (l'annotation CI lit la dernière
ligne, qui reste le verdict). Les lignes de verdict sont inchangées.

L'en-tête du gate garde le paragraphe « vérification de forme, jamais de véracité » et le complète
(règle, origine, date, limite). `docs/ADR.md` § ADR-072 reçoit un amendement daté du 2026-11-12.
`CLAUDE.md` n'est pas touché. Aucune valeur de la baseline du budget d'instructions ne monte
(`check-instruction-budget.sh` : sortie identique avant et après, comparée par `cmp`).

Commits (6) : `dcdbd5f4` témoins rouges, `7ec2f7b5` correctif, `ccdd1246` amendement ADR-072,
`bcca4aac`, `e3a20973`, `83b71457` passes de correction après revue. Tous les commits qui touchent
le gate ou sa suite portent `Gate-Touche`.

## Plan de bataille (DAG)

`build` (vf-coder) → `revue` (vf-reviewer frais) → `fix1` → `revue2` (checker frais) → `fix2` →
`revue3` (checker frais) → `fix3` → `revue4` (checker frais) → `rapport`. Chaque passe de
correction est repartie au même vf-coder par reprise de contexte, puis devant un checker neuf
scopé au diff de la passe.

## Vérification

- Témoin rouge sur le code d'avant : 13 cas DEL rouges contre le script de `ab8f3e64` (rejoué
  par le worker puis par le juge). Exemple : « DEL hausse, ligne de delegation seule », attendu
  rc 1 + `HAUSSE-SANS-ARBITRAGE`, obtenu rc 0 + `CONFORME`.
- Mutants tués dans la suite : MUT-10 (exclusion retirée, hausse), MUT-10b (sentinelle), MUT-11
  (radical réduit à « delegue »), MUT-12 (repli de U+0301 retiré, octets `cc81` vérifiés par
  `od`), MUT-13 (`ligne_ecartee` sans test de forme). Mutants de juge tués : exclusion cumulée
  au message, repli É/È retiré, `tolower` retiré, repli é/è retiré, `extract_citation_line` sans
  exclusion, INFO après verdict dans chacun des trois usages.
- Suite du gate jouée seule sur `83b71457` : `== bilan : 73 ok, 0 ko ==`, rc 0.
- Rejeu du job `gates` de `.github/workflows/ci.yml` (`replay-ci-jobs.sh --job gates`, étapes
  extraites du fichier) sur `e3a20973` : 21 rejouées, 4 sautées (conditionnelles main ou
  actions), 0 en échec. `83b71457` ne touche que la suite.
- Non-régression avec la version finale du script (cascade CI : base = merge-base avec
  `origin/main` `de19669b`), worktrees détachés jetables, retirés ensuite :

  | Tête | commits non-merge | sortie | rc |
  |---|---|---|---|
  | `origin/release/v2.77.0` `08e3dba0` | 328 | CONFORME | 0 |
  | `origin/integration/cockpit-audit` `ab8f3e64` | 751 | CONFORME | 0 |
  | `origin/feat/phase-79-socle-cockpit` `91af2123` | 831 | CONFORME | 0 |
  | `origin/feat/phase-80-trois-formes` `342a8763` | 771 | CONFORME | 0 |

- Suites qui citent le gate ou `docs/ADR.md`, jouées sur `ccdd1246` puis `bcca4aac` :
  test-roles-e2e, test-check-ajout-retrait, test-dev-orchestrator, test-discover-unintegrated-docs,
  test-check-affirmation-non-mesuree, test-check-gate-touche, test-check-push-sans-pr : rc 0.
  `test-guard-driver-lock-ws` a été arrêté : il ne cite `docs/ADR.md` que dans sa propre fixture.

## Classe : autres gates qui exigent une citation par la forme

| Fichier | Ce qu'il garde | Accepte la délégation ? | Décision |
|---|---|---|---|
| `scripts/check-baseline-arbitrage.sh` (G-1) | hausse, retrait de ligne, neutralisation de sentinelle | oui avant (13 cas rouges) | corrigé |
| `scripts/check-gate-touche.sh` (G-2) | trailer déclaratif `Gate-Touche` | n'exige aucune citation (sonde : DECLARE rc 0) | non touché, hors classe |
| `plugin/conductor/scripts/check-ajout-retrait.sh` (SOBR-05) | trailer `Ajout-Retrait` | n'exige aucune citation (sonde : COUVERT rc 0) | non touché, hors classe |
| `scripts/check-push-sans-pr.sh` (G-3) | commit sur main sans PR | ne lit aucune citation (lecture) | non touché |
| `check-release-tag.sh`, `check-guard-health.sh`, `check-doc-drift.sh` | lisent `%ct`/`%H` seulement | aucun message lu (lecture) | non touchés |
| `check-affirmation-non-mesuree.sh`, `check-instruction-budget.sh`, `check-method-budget.sh`, `check-mission-invariants.sh`, `ci.yml` | « arbitrage » en commentaire seulement | ne s'applique pas | non touchés |

## Revue : une citation directe légitime peut-elle être refusée ?

Oui, quand la même ligne porte aussi le radical (mesuré de bout en bout par le juge) :
« arbitrage Samuel, AskUserQuestion session principale, 2026-11-12 : refuse de déléguer le
calcul », « … le délégué syndical valide », « … renomme delegue_handler ». Contournement : porter
la citation directe sur sa propre ligne (mesuré : rc 0). Le juge tient ce faux refus pour
acceptable sur une garde de traçabilité qui échoue fermée ; la ligne INFO le rend lisible.
Accepté sans radical : « délégation de paiement », « delegate() ».

## Écarts

- Question de règle, laissée ouverte et remontée : le radical ne couvre pas « délégation » ni
  « delegate ». « décision prise par délégation de X (…, 2026-11-08), option recommandée » reste
  CONFORME. C'est dit comme limite dans l'en-tête et l'ADR, la règle n'a pas été élargie.
- Attribution : le brief prescrivait un trailer `Co-Authored-By` précis ; les mandats ont demandé
  à chaque worker de poser celui de sa propre configuration. Les 6 commits portent
  `Claude Sonnet 5.5`.
- F6 (ligne INFO) : le mandat demandait d'y renoncer au-delà d'une quinzaine de lignes de
  restructuration ; le worker l'a faite en ~25. Le checker suivant l'a jugée justifiée.
- `dcdbd5f4` est volontairement rouge (témoins seuls).
- Mineurs antérieurs au diff, portés ici sans être traités : les trois conditions de forme
  (mot-clé, deux virgules, date) ne sont mordues par aucun mutant isolé (R2-1) ; dans une même
  exécution, un avertissement de retrait arbitré peut suivre un verdict de hausse et devenir la
  dernière ligne (R3-2) ; la branche « NON OPPOSABLE » des mutants est inatteignable sous `set -e`
  (F5) ; seul U+0301 est replié (NFD complet de « délègue » accepté, F3).
- `test-dev-orchestrator` a rendu 1 KO (T30-A) une fois sous la charge de 8 suites parallèles,
  puis 448 OK / 0 KO joué seul ; `plugin/` n'est pas touché par la branche.
- Portabilité : seul l'awk BSD du poste est mesuré ; mawk et gawk sont jugés par lecture. La CI
  Linux de la PR le tranche.

## Suite : radical élargi à « deleg » (décision de la session principale, 2026-11-12)

La question de règle laissée ouverte ci-dessus est tranchée par la session principale (message
du 2026-11-12, en réponse à ce rapport) : le radical devient « deleg » après repli des accents et
de la casse. Motif donné : « décision prise par délégation de X (…, 2026-11-08), option
recommandée » dit la même chose que « décision déléguée » et passait encore. Ce n'est pas un
arbitrage détaillé de Samuel. L'écart « délégation / delegate non couverts » ci-dessus est donc
fermé.

- Commits : `9cb68a98` (témoins rouges seuls), `e25e675f` (correctif + en-tête + précision datée
  dans l'amendement d'ADR-072, sans second amendement ; les phrases devenues fausses sont
  retirées).
- Rouge sur `a0aad37d` : 10 cas DEL2 (hausse × « délégation », « delegation », « delegate »,
  « DÉLÉGATION » ; retrait seul × 2 ; retrait délégation + directe × 2, la ligne recopiée étant la
  délégation ; sentinelle × 2). Exemple : attendu rc 1 + `HAUSSE-SANS-ARBITRAGE` + INFO, obtenu
  rc 0 `CONFORME`. Rejoué par le checker frais : même rouge.
- Mutant MUT-14 (radical remis à « delegu ») tué dans la suite ; MUT-11 adapté (sa ligne cible
  seule) et toujours tué. Mutants du checker tués : radical appliqué avant le repli des accents
  (28 ko), radical sur le message entier (19 ko), repli de « É » retiré (4 ko). Libellés de cas
  comparés par `comm` : 95 avant, 103 après, aucun retiré.
- Faux refus assumés, nommés avec leur remède dans l'en-tête et l'ADR : « délégation de
  paiement », « delegate() », « délégué syndical » sur la même ligne qu'une citation directe →
  porter la citation sur sa propre ligne. Limite qui demeure : une paraphrase sans le radical
  (« confiée ») ou une citation directe fabriquée passe toujours.
- Suite seule sur `e25e675f` : `== bilan : 90 ok, 0 ko ==`. Rejeu du job `gates` sur `e25e675f` :
  21 rejouées, 4 sautées, 0 en échec. Budget d'instructions : sortie identique (`cmp`), aucune
  hausse.
- Non-régression, version `e25e675f`, cascade CI (base = merge-base avec `origin/main`
  `de19669b`) :

  | Tête | commits non-merge | sortie | rc |
  |---|---|---|---|
  | `origin/release/v2.77.0` `08e3dba0` | 328 | CONFORME | 0 |
  | `origin/integration/cockpit-audit` `ab8f3e64` | 751 | CONFORME | 0 |
  | `origin/feat/phase-79-socle-cockpit` `244ab998` | 839 | CONFORME | 0 |
  | `origin/feat/phase-80-trois-formes` `342a8763` | 771 | CONFORME | 0 |

- Checker frais (revue5) : `passed`. Mineur hors périmètre : sous `set -e`, un mutant non
  opposable fait quitter la suite sans bilan (patron de tous les blocs MUT, reconduit par MUT-14).
- Environnement : le disque du poste était presque plein pendant la revue (le checker a vu « No
  space left on device » et a rejoué avec un `TMPDIR` au scratchpad). Les journaux de rejeu de la
  mission pèsent quelques centaines de Ko : la saturation ne vient pas d'elle.

## Budgets

Relevé des blocs reçus, sans recalcul : vf-coder 212 045 (build), 235 015 (fix1), 246 443 (fix2),
253 914 (fix3) tokens cumulés de contexte ; vf-reviewer 118 298 (revue), 103 031 (revue2),
75 793 (revue3), 63 088 (revue4 : `passed`, mutants retrait et sentinelle tués, 72 ok / 1 ko
chacun). `estimate`/`actuals` : `absent` (aucun PLAN.md exécuté).
Suite « deleg » : vf-coder 274 624 (repris), vf-reviewer 98 332 (revue5).
Minds dispatchés : 6 (1 vf-coder repris 4 fois, 5 vf-reviewer frais). Tours de correction : 3,
plus un mandat de règle élargie.

## Moins cher la prochaine fois

- Écrire dans le premier mandat les témoins que les juges ont demandés ensuite : fixtures NFD
  committées sans renormalisation (`core.precomposeunicode=false` sous macOS), une forme du radical
  qui n'est pas suivie de « e », et l'assertion « dernière ligne » dans chaque usage. Trois des
  quatre passes de correction venaient de là.
- Ne pas proposer d'ajout optionnel (la ligne INFO) dans une passe de correction : il a coûté deux
  passes de plus pour son propre ordre d'impression et ses témoins.
- Ne lancer que les suites qui lisent vraiment les fichiers touchés : un `grep` du nom de fichier
  a ramené une suite de mutation longue qui ne lisait que sa fixture.

## Preuves E6

```json
{"preuves":[
{"verdict":"suite du gate G-1","commande":"bash scripts/tests/test-check-baseline-arbitrage.sh","exit_code":0,"sha":"83b714571764c5ca1aaeb8acf27d1b83af149c86"},
{"verdict":"check-gate-touche","commande":"bash scripts/check-gate-touche.sh --base-ref origin/integration/cockpit-audit","exit_code":0,"sha":"e3a20973c14353a087d11a812c98cbce2c91e7bd"},
{"verdict":"check-gate-touche (worker)","commande":"bash scripts/check-gate-touche.sh --base-ref ab8f3e64","exit_code":0,"sha":"83b714571764c5ca1aaeb8acf27d1b83af149c86"},
{"verdict":"check-machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"83b714571764c5ca1aaeb8acf27d1b83af149c86"},
{"verdict":"G-1 sur la branche","commande":"bash scripts/check-baseline-arbitrage.sh --base-ref origin/integration/cockpit-audit","exit_code":0,"sha":"e3a20973c14353a087d11a812c98cbce2c91e7bd"},
{"verdict":"rejeu du job gates de ci.yml","commande":"bash replay-ci-jobs.sh --job gates --root <wt>","exit_code":0,"sha":"e3a20973c14353a087d11a812c98cbce2c91e7bd"},
{"verdict":"rejeu de l'étape G-1 de ci.yml (worker)","commande":"bash replay-ci-jobs.sh --job gates --root <wt> --step check-baseline-arbitrage","exit_code":0,"sha":"e3a20973c14353a087d11a812c98cbce2c91e7bd"},
{"verdict":"non-régression G-1 sur release/v2.77.0, integration/cockpit-audit, phase-79, phase-80","commande":"bash scripts/check-baseline-arbitrage.sh --root <worktree détaché> (cascade CI)","exit_code":0,"sha":"e3a20973c14353a087d11a812c98cbce2c91e7bd"},
{"verdict":"témoin rouge sur le code d'avant (revue)","commande":"suite neuve contre check-baseline-arbitrage.sh de ab8f3e64","exit_code":1,"sha":"ccdd1246725af6e6d43d5f8d37e84857b32a8c96"},
{"verdict":"budget d'instructions inchangé","commande":"bash plugin/conductor/scripts/check-instruction-budget.sh (avant/après, cmp)","exit_code":0,"sha":"ccdd1246725af6e6d43d5f8d37e84857b32a8c96"},
{"verdict":"suite du gate G-1 (radical deleg)","commande":"bash scripts/tests/test-check-baseline-arbitrage.sh","exit_code":0,"sha":"e25e675f2095a4a18f82f319d0e18d293e64bc48"},
{"verdict":"témoin rouge deleg sur le code d'avant (revue5)","commande":"suite neuve contre check-baseline-arbitrage.sh de a0aad37d","exit_code":1,"sha":"e25e675f2095a4a18f82f319d0e18d293e64bc48"},
{"verdict":"rejeu du job gates de ci.yml (radical deleg)","commande":"bash replay-ci-jobs.sh --job gates --root <wt>","exit_code":0,"sha":"e25e675f2095a4a18f82f319d0e18d293e64bc48"},
{"verdict":"non-régression G-1 deleg sur les quatre têtes","commande":"bash scripts/check-baseline-arbitrage.sh --root <worktree détaché> (cascade CI)","exit_code":0,"sha":"e25e675f2095a4a18f82f319d0e18d293e64bc48"},
{"verdict":"check-gate-touche (worker, deleg)","commande":"bash scripts/check-gate-touche.sh --base-ref ab8f3e64","exit_code":0,"sha":"e25e675f2095a4a18f82f319d0e18d293e64bc48"},
{"verdict":"recette","preuve":"amont"}
]}
```
