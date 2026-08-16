# 31-02 — SUMMARY (mode `plan` de `merge-hooks.sh`)

> **Provenance de ce document.** Il a été **reconstruit par le manager** (`vf-dev-manager`) le
> 2026-08-16 à partir du **rapport d'exécution du worker** et des **commits réels**, parce que le
> worker de `31-02` n'avait pas écrit son SUMMARY : mon mandat lui interdisait alors toute écriture
> sous `.planning/` (interdiction posée pour éviter les collisions entre deux workers parallèles, et
> assouplie seulement aux lots suivants). **Le manque vient de mon mandat, pas de son exécution.**
> Rien ici n'est inféré : chaque chiffre provient du rapport du worker ou d'une mesure vérifiable.

**Plan** : `31-02-PLAN.md` · **Vague** : 1 (en parallèle de `31-01`, périmètres disjoints)
**Exigences** : MANI-02, QUAL-01 · **Statut** : livré, revu, corrigé, re-vérifié

## Commits

| SHA | Objet | Fichier |
|---|---|---|
| `e33c836` | `feat(31-02): mode plan dans merge-hooks.sh (D-31-04 régime B)` | `plugin/_internal/merge-hooks.sh` |
| `d7896ff` | `test(31-02): cas de suite Tp1..Tp5 du mode plan` | `plugin/_internal/tests/test-merge-hooks.sh` |

Corrections ultérieures portant sur ce lot : `c6475a2` (assertion de canal stdout/stderr,
`Tp1`/`Tp2`), `c7c2e1d` (verbe `+` vs `~` selon l'existence réelle de la cible, `Tp6`/`Tp7`).

## Ce que le lot livre

Un **troisième mode** positionnel de `merge-hooks.sh`, à côté de `merge` et `remove` : `plan`.

- Il **réutilise `split_fragment_hooks`** — la même fonction que la branche `merge`, appelée depuis
  la branche `plan` elle-même. **Aucune seconde implémentation** de la répartition project/local :
  D-31-04 régime B l'interdit nommément, c'est le « chemin de code séparé » proscrit au ledger.
- Il **n'écrit rien** : `write_json` n'est jamais atteint (`sys.exit(0)` inconditionnel en fin de
  branche, aucun chemin d'exception ne le contourne).
- Il annonce `settings.local.json` **dès que `--settings-local` est fourni**, parce qu'un `merge`
  réel l'écrit inconditionnellement dans ce cas.
- **Canal** : la ligne de plan sur **stdout**, les diagnostics sur **stderr** avec le préfixe
  `[merge-hooks] ` — c'est ce qui rend la sortie capturable par le moteur, qui la **relaie telle
  quelle** dans son propre plan `--dry-run`.

## Lignes re-mesurées avant édition (sur pièce)

`split_fragment_hooks` définie **240** · appelée **405**, à l'intérieur de `if mode == "merge":`
(**404**). Le mandat citait 405 pour la branche englobante — **le worker a corrigé cette valeur**,
c'était la ligne d'affectation, pas celle du `if`.

## Suites, sur l'arbre tel que commité (`git archive HEAD`)

| Étape | `test-merge-hooks.sh` |
|---|---|
| Baseline (avant le lot) | 27 OK / 0 KO |
| Après `e33c836` (mode `plan` seul) | 27 OK / 0 KO |
| Après `d7896ff` (arbre final du lot) | **32 OK / 0 KO** |

Non-régression consommateur : `test-vibeflow-update.sh` **19 OK / 0 KO**.
*(État en fin de phase, après les corrections ultérieures : **34 OK / 0 KO**.)*

## Mutation rouge (QUAL-01)

Neutralisation de la garde `--scripts-prefix` du mode `plan` (retrait de `|| [ "$MODE" = "plan" ]`) :

- **Assertion** : `[ "$TP4_EXIT" -ne 0 ] && printf '%s' "$TP4_ERR" | grep -q -- '--scripts-prefix'`
- **Attendu** : exit ≠ 0, message d'exigence `--scripts-prefix` sur stderr
- **Obtenu sous mutation** : `exit=0`, stderr = `[merge-hooks] plan OK → …/tp4/settings.json`
  (le plan a tourné avec des chemins non résolus)
- **Résultat** : **31 OK / 1 KO** — `Tp4` seul rougit, les 31 autres cas y sont insensibles
- **Restauration** vérifiée par `cmp` (identique octet pour octet à l'original commité) **avant tout
  commit** : le mutant n'a jamais été commité ; suite rejouée à 32/32 après restauration.

## Arbitrage pris par le worker, et son motif

Le mandat prescrivait d'invoquer le skill `gsd-execute-phase`. Le worker a constaté que son moteur
de découverte **ne discrimine qu'au niveau VAGUE, jamais au niveau plan** (aucun flag `--plan`) :
l'invoquer aurait **redispatché une exécution de `31-01` en parallèle du worker qui le faisait
déjà**, en violation directe de l'interdiction de son propre mandat. Il a donc suivi
`execute-plan.md` — le document que le PLAN référence dans son `<execution_context>` — en exécutant
**inline**, avec commits atomiques par pathspec.

**Conséquence assumée** : pas de `SUMMARY` écrit par la machinerie (d'où ce document), pas de
`verdicts` rendus par les hooks `execute:post`, pas d'`actuals` mesurés par `state.record-metric`.
Le worker a **refusé de fabriquer** une valeur `absent` pour trois sous-champs jamais évalués.

## Écart de plan signalé

La tâche 2 du plan qualifiait `plugin/software-architecture/hooks/hooks.json` de « forme shell » ;
le fragment réel est en **forme exec** (`command: "{{VF_BASH}}"`, `args: [...]`). Le chemin cité
étant sans ambiguïté, il a été suivi tel quel — et la forme exec **exerce en prime** le routage
project/local (`Tp2` obtient 1 ligne `(aucune entrée)` côté projet + 1 ligne peuplée côté local),
donc une couverture au moins équivalente à celle visée par le texte du plan.

## Calibration

`estimate` du frontmatter : `tokens: 40000, tasks: 2, confidence: low`. **Aucun `actuals`** — le
mode d'exécution inline court-circuite `state.record-metric`. Rien de fabriqué pour combler.
