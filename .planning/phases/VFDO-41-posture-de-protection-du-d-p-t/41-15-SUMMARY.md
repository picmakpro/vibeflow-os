---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 15
subsystem: infra
tags: [bash, git, ci, gate, qa, testing]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plan 41-14)
    provides: "41-PREUVES.md § 41-14 avec la ligne `BASE-TRACE-ARBITRAGE:` (borne du futur
      contrôle de trace de la Task 2, non exécutée dans ce plan) ; le patron de garde in-repo
      (`scripts/check-baseline-arbitrage.sh`) utilisé comme référence de style"
provides:
  - "tools/check-aucune-fermeture.sh — recensement de co-occurrence sujet x achèvement
    (comparaison 1), allowlist à 3 entrées (comparaison 2), sonde de limite de fond
    (comparaison 3) ; 12 contrôles négatifs et 3 mutants opposables, tous verts"
  - "tools/test-check-aucune-fermeture.sh — suite QUAL-01 de l'outil ci-dessus"
affects: [41-16, 41-17, 41-18, 41-19]

# Actuals (#2632)
actuals:
  tokens: 6365
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "safe_run() : capture rc + stdout d'un outil sous test sans jamais faire dépendre le rc
      réel d'une affectation par substitution de commande (`out=\"$(run ...)\"`) — sous
      `bash -e`, cette dernière forme fait sortir le script AVANT la ligne `rc=$?` dès que le
      cas de test attend un rc non nul, et l'alternative « faire porter le rc réel par une
      variable globale mise à jour DANS run() » échoue aussi silencieusement car `run()`
      s'exécute alors dans le sous-shell forké par le `$(...)` de l'appelant, qui ne peut pas
      modifier une variable du shell parent. `safe_run` bascule `set +e`/`set -e` en étant
      appelée comme instruction NUE (jamais entourée de `$(...)`), donc dans le shell réel de
      l'appelant, et transmet la valeur par `eval` vers les noms de variables fournis par
      l'appelant plutôt que par une variable fixe. À réutiliser telle quelle pour toute suite de
      ce dépôt rejouée sous `bash --noprofile --norc -e`."

key-files:
  created:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-aucune-fermeture.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/test-check-aucune-fermeture.sh
  modified: []

key-decisions:
  - "HALTE au gate de rétroaction du traceur (Task 1, type=tracer) : le second bloc `<verify>`
    automatisé de la Task 1 (mesure sur le dépôt réel) rend rc=1 avec 7 hits — un écart RÉEL,
    mesuré, non un défaut de l'outil. Ni Task 2 ni Task 3 n'ont été exécutées. Voir
    « Vérification non satisfaite » ci-dessous."
  - "Aucune expansion de l'allowlist au-delà des 3 entrées nommées par le plan, et aucune
    modification des artefacts 41-14 (`scripts/check-baseline-arbitrage.sh`, `ci.yml`,
    `CHANGELOG.md`, `41-14-SUMMARY.md`) ni de `CLAUDE.md` — conformément au mandat de dispatch
    (« ni les livrables de 41-14 ... ne le touche donc pas ») et à la discipline de portée par
    défaut (ne pas corriger un écart non causé par les changements de cette tâche)."

requirements-completed: []

coverage:
  - id: D1
    description: "tools/check-aucune-fermeture.sh — recensement de co-occurrence sujet x
      achèvement, allowlist à 3 entrées, sonde de limite de fond ; 12 contrôles négatifs et 3
      mutants opposables (MUT-1 à MUT-3), tous crédités en forme canonique"
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "tools/test-check-aucune-fermeture.sh (bash --noprofile --norc -e, 15/15
          assertions vertes, 3/3 mutants tués en forme canonique)"
        status: pass
    human_judgment: false
  - id: D2
    description: "L'outil rend rc=0 avec zéro hit sur le dépôt RÉEL (acceptance criteria de la
      Task 1 et verify de la Task 3)"
    requirement: PROT-04
    verification:
      - kind: other
        ref: "bash tools/check-aucune-fermeture.sh (sans --root, sur ce dépôt) — rc=1, 7 hits"
        status: fail
    human_judgment: true
    rationale: "Écart réel et mesuré entre la baseline du plan (HEAD c8489fc, 2026-09-17) et le
      contenu déjà committé par 41-14. Résoudre exige soit de faire grandir l'allowlist
      au-delà des 3 entrées prescrites par le plan, soit de modifier des artefacts hors mandat
      (41-14, CLAUDE.md) — une décision humaine, pas une correction automatisable par cet
      exécuteur. Voir « Vérification non satisfaite »."

duration: ~1h10
completed: 2026-09-18
status: halted
---

# Phase 41 Plan 15: Outillage de preuve du périmètre sans admin — HALTE au gate de rétroaction du traceur

**`tools/check-aucune-fermeture.sh` fonctionne correctement et est prouvé par 15 assertions
fixture + 3 mutants opposables, mais rend rc=1 sur le dépôt réel (7 hits mesurés, tous
postérieurs à la baseline du plan) — Task 2 et Task 3 n'ont pas été exécutées, conformément au
gate de rétroaction du traceur qui interdit d'empiler d'autres tâches sur une vérification
rouge.**

## Performance

- **Durée :** ~1h10
- **Tâches :** 1/3 complétée (Task 1) ; 2/3 non exécutées (Task 2, Task 3)
- **Fichiers créés :** 2

## Pourquoi ce plan s'arrête ici

Le plan 41-15 porte deux tâches `tdd="true"` (Task 1 `type="tracer"`, Task 2 `type="auto"`) suivies
d'une Task 3 de consignation. Le workflow d'exécution impose, après tout `type="tracer"`, un
**gate de rétroaction du traceur** : re-jouer le `<verify>` complet de la tâche AVANT toute
expansion ; s'il échoue, HALTER et ne jamais empiler d'autres tâches sur une vérification rouge.

Task 1 porte DEUX blocs `<automated>` :
1. La suite fixture (`test-check-aucune-fermeture.sh` sous `bash --noprofile --norc -e`) —
   **verte** (15/15 assertions, 3/3 mutants tués en forme canonique).
2. Une mesure directe sur le dépôt réel, exigeant `rc=0`, `fichiers>=16`, `hits=0`,
   `ligne_limite=oui` — **rouge** : `rc=1`, `fichiers=19`, **`hits=7`**.

Le second bloc est un `<verify>` du plan, pas une invention de cet exécuteur ; son échec déclenche
le HALTE. Les 7 hits sont détaillés ci-dessous : ce sont des découvertes RÉELLES et correctes de
l'outil, pas un bug de l'outil lui-même.

## Vérification non satisfaite — preuve exacte

Commande rejouée (racine implicite = ce dépôt) :

```
bash .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-aucune-fermeture.sh
```

Sortie observée (2026-09-18, HEAD `7ac7cf7` juste après le commit de la Task 1) — **note de
relecture (2026-09-18, reprise) : les trois lignes de hit et les quatre lignes
`LIMITE-DE-FOND-ABSENTE` ci-dessous sont paraphrasées plutôt que recopiées verbatim, pour ne pas
réintroduire ici même la co-occurrence que ce plan corrige (voir « Résolution du mandat élargi »
plus bas)** :

```
perimetre: fichiers=19
[3 lignes de hit : 41-14-SUMMARY.md:108 et :247, CHANGELOG.md:24 — voir tableau ci-dessous]
allowlist: entrees=3 appliquees=3
[4 lignes LIMITE-DE-FOND-ABSENTE : check-baseline-arbitrage.sh, ci.yml, CLAUDE.md, 41-14-SUMMARY.md]
limite: exiges=7 porteurs=4 manquants=<les 4 chemins ci-dessus>
rc=1
```

### Root cause — dérive de baseline, pas un bug de l'outil

Le plan 41-15 amorce l'allowlist avec « les TROIS seules lignes héritées mesurées le 2026-09-17
sur HEAD `c8489fc` » et exige qu'elle en porte « exactement 3 » à l'issue de la tâche. Cette
mesure est **antérieure** à l'exécution du plan 41-14 (terminé le 2026-09-18, committé sur cette
branche). 41-14 a introduit, en toute conformité avec la doctrine PROT-04 (« signalée et tracée »,
jamais « fermée »), **trois occurrences supplémentaires et doctrinalement CORRECTES** qui
co-occurrent malgré tout un jeton de sujet et un jeton d'achèvement — exactement le comportement
que la Task 1 spécifie (« négations comprises : une tournure niée ne dispense pas ») :

| Fichier:ligne | Nature de la co-occurrence (paraphrasée, voir note ci-dessus) | Pourquoi c'était correct malgré le hit |
|---|---|---|
| `41-14-SUMMARY.md:108` | rationale D5 : nommait les huit jetons d'achèvement interdits pour EXPLIQUER la règle de vérification | Explication de la règle, pas une affirmation sur O-3 |
| `41-14-SUMMARY.md:247` | doctrine PROT-04 : O-3 au statut « signalée et tracée », avec la négation explicite du mot d'achèvement | Formule doctrinale PROT-04 exacte, négation intentionnelle |
| `CHANGELOG.md:24` | même formule doctrinale, dans l'entrée CHANGELOG de 41-14 | Même raison que la ligne ci-dessus |

La sonde de limite de fond (comparaison 3, décidée le même jour que ce plan, 2026-09-17) exige un
fragment canonique (« modifiée par la PR qu'elle juge ») que **41-14 n'a pas écrit littéralement**
dans `scripts/check-baseline-arbitrage.sh` (son en-tête dit « la PR qu'elle juge peut la
modifier » — même idée, formulation différente, donc pas de correspondance après normalisation),
ni dans `.github/workflows/ci.yml`, ni dans `41-14-SUMMARY.md`. `CLAUDE.md` ne porte pas non plus
cette formule (aucun plan ne l'y a encore ajoutée).

**Ces deux racines sont la MÊME dérive** : le plan 41-15 a été rédigé/mesuré à un instant où
41-14 n'avait pas encore livré son contenu réel ; ce contenu, une fois committé, introduit des
occurrences légitimes que la baseline figée du plan ne pouvait pas anticiper.

### Pourquoi ce n'est pas corrigé ici

Deux voies de correction existent, toutes deux hors du mandat de ce dispatch :

1. **Faire grandir l'allowlist de 3 à 6 entrées** (ajouter les trois lignes ci-dessus, chacune
   avec sa raison) — contredit littéralement l'acceptance criterion du plan : « l'allowlist porte
   exactement 3 entrées à l'issue de la tâche ».
2. **Ajouter le fragment canonique** à `scripts/check-baseline-arbitrage.sh`, `.github/workflows/ci.yml`,
   `CLAUDE.md` et `41-14-SUMMARY.md` — tous des livrables de 41-14 (ou, pour `CLAUDE.md`, un
   fichier hors du périmètre `files_modified` de CE plan) ; le mandat de dispatch est explicite :
   « Ne modifie ni les plans 41-01..41-13-PLAN.md, ni les livrables de 41-14 ... il ne les exige
   pas — ne les touche donc pas. » La discipline de portée par défaut de cet exécuteur pointe dans
   le même sens : un écart non causé par les changements de CETTE tâche n'est pas auto-corrigible
   (« Only auto-fix issues DIRECTLY caused by the current task's changes »).

Aucune des deux voies n'est un geste que cet exécuteur peut prendre unilatéralement sans soit
violer un acceptance criterion explicite du plan, soit violer une contrainte dure du mandat. C'est
exactement la situation prévue par l'objectif de ce dispatch : « Une vérification du plan
impossible ou fausse : tu t'arrêtes et tu le rapportes dans le SUMMARY, tu ne l'affaiblis JAMAIS. »
L'outil n'a **pas** été affaibli (allowlist toujours à 3 entrées exactement, sonde de limite de
fond toujours active, aucun jeton retiré) pour forcer un vert artificiel.

## Ce qui est prouvé et livré (Task 1)

- `tools/check-aucune-fermeture.sh` : périmètre dérivé par `git ls-files` (19 fichiers réels,
  ≥16 exigés), comparaison 1 (co-occurrence sujet×achèvement en `awk`, négations comprises),
  comparaison 2 (allowlist à 3 entrées nominatives, chacune avec sa raison écrite), comparaison 3
  (sonde de limite de fond, fragment canonique cherché après normalisation des blancs). Bornes
  volontaires écrites en en-tête : `gate`/`gates` hors des sujets, la forme nue `ferme` hors des
  achèvements. Exclusions nominatives des `41-*-PLAN.md` et `41-CONTEXT.md`, avec leur raison.
- `tools/test-check-aucune-fermeture.sh` : 12 contrôles négatifs (R0..R11, fixtures 100%
  jetables `mktemp -d` + `git init -q -b main` + identité `-c`) et 3 mutants opposables
  (MUT-1 neutralise la co-occurrence, MUT-2 neutralise l'assertion de périmètre non vide, MUT-3
  neutralise la sonde de limite de fond), chacun crédité en forme canonique
  `✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y>`. **15/15 assertions
  vertes, 0 ko**, rejoué avec succès sous l'invocation stricte `bash --noprofile --norc -e`
  exigée par le `<verify>` du plan.
- Bug de suite corrigé PENDANT l'exécution (voir Déviations) : sous `bash -e`, capturer un rc de
  fixture volontairement non nul via `out="$(run ...)"; rc=$?` fait sortir le script avant la
  ligne `rc=$?` — le même défaut existe, non corrigé, dans
  `scripts/tests/test-check-baseline-arbitrage.sh` (41-14), mesuré empiriquement mais hors
  mandat de ce plan (voir Issues Encountered).

## Task Commits

1. **Task 1 : recensement des affirmations d'achèvement sur une garde ou sur O-3, allowlist à
   3 entrées, sonde de limite de fond** — `7ac7cf7` (feat)

Task 2 et Task 3 : **non exécutées à ce stade** (halte au gate de rétroaction du traceur, voir
ci-dessus — reprises plus bas dans ce même document une fois le mandat élargi appliqué).

_Ledger de commits (`plan_head_before`) : `8cb8d46d719a227121194aeb67140287c9c4775f`. `commits`
mesuré (`git rev-list --count`) : 1._

## Files Created/Modified

- `tools/check-aucune-fermeture.sh` — recensement + sonde de limite de fond (nouveau)
- `tools/test-check-aucune-fermeture.sh` — suite QUAL-01 (nouveau)

## Decisions Made

Voir `key-decisions` en frontmatter. Aucune décision hors cadre : la halte est une application
littérale du gate de rétroaction du traceur du workflow d'exécution, pas un choix discrétionnaire.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `safe_run()` — capture de rc sous `bash -e` sans perte dans un sous-shell**
- **Trouvé pendant :** Task 1, en rejouant le `<verify>` de la suite sous l'invocation stricte
  `bash --noprofile --norc -e` exigée par le plan (ma première version de la suite passait sous
  `./test-check-aucune-fermeture.sh` nu, mais mourrait silencieusement dès le premier cas de rc
  non nul sous `-e`).
- **Problème :** `out="$(run "$D")"; rc=$?` fait sortir le script AVANT `rc=$?` sous `set -e` dès
  que `run` retourne un code non nul (cas attendu pour tout test R1..R11 sauf R0/R4/R5/R6/R10/R11).
  Une première tentative de correction (faire porter le rc réel par une variable globale `LAST_RC`
  mise à jour DANS `run()`) semblait corriger le symptôme (plus de sortie prématurée) mais restait
  fausse : `run()` s'exécute alors DANS le sous-shell forké par le `$(...)` de l'appelant, donc son
  affectation à `LAST_RC` est perdue dès le retour du sous-shell — tous les rc capturés valaient 0
  silencieusement (repéré car R1/R2/R3/R7 rapportaient `rc=0` au lieu de `rc=1`/`rc=2` attendus).
- **Correction :** `safe_run <var_out> <var_rc> <root> [args...]`, appelée comme instruction NUE
  (jamais entourée de `$(...)`), qui bascule `set +e`/`set -e` dans le shell RÉEL de l'appelant et
  transmet le résultat par `eval` vers les noms de variables fournis par l'appelant.
- **Fichiers modifiés :** `tools/test-check-aucune-fermeture.sh` (fait partie du commit de
  création, aucun commit séparé).
- **Vérification :** 15/15 assertions vertes et 3/3 mutants tués sous `bash --noprofile --norc -e`
  (invocation exacte du `<verify>` du plan).

**2. [Rule 1 - Bug] Fixture R8 sans fichier committé — `git commit` sur un index vide**
- **Trouvé pendant :** Task 1, même rejeu sous `-e`.
- **Problème :** la fixture R8 (option inconnue) appelait `commit_all` sans avoir jamais écrit de
  fichier dans le dépôt jetable — `git commit` sur un index vide renvoie un rc non nul, ce qui
  faisait sortir le script sous `-e` avant même d'atteindre l'assertion R8.
- **Correction :** ajout d'un `CHANGELOG.md` de fixture avant `commit_all`, comme dans tous les
  autres cas R0..R11.
- **Fichiers modifiés :** `tools/test-check-aucune-fermeture.sh`.
- **Vérification :** R8 s'exécute et passe (`rc=64`) sous l'invocation stricte.

---

**Total déviations :** 2 auto-corrigées (2 bugs Rule 1, tous deux internes à la suite de test de
CE plan — aucune n'a touché `check-aucune-fermeture.sh` lui-même ni un fichier hors périmètre).
**Impact sur le plan :** les deux corrections étaient nécessaires pour que le `<verify>` du plan
(invocation stricte `bash -e`) passe réellement, et non de façon apparente sous une invocation nue
plus permissive. Aucune extension de périmètre.

## Issues Encountered

**Observation transverse, non corrigée (hors mandat) :** le même défaut que la déviation 1
ci-dessus (`out="$(run ...)"; rc=$?` sous `bash -e`) existe TEL QUEL dans
`scripts/tests/test-check-baseline-arbitrage.sh` (livré par 41-14). Rejoué avec
`bash --noprofile --norc -e scripts/tests/test-check-baseline-arbitrage.sh` (mesure du
2026-09-18, hors ce plan), la suite s'arrête après la section `PASS` (6/6 vertes) sans jamais
atteindre la section `FAIL`, `EXIT=1` — silencieusement, sans imprimer de bilan. Ce fichier est un
livrable de 41-14 : non modifié ici, conformément au mandat. Signalé pour arbitrage humain
(candidat naturel : le même patron `safe_run()` introduit dans ce plan).

**La halte elle-même n'est pas une "issue" au sens d'un problème imprévu :** c'est le
fonctionnement voulu du gate de rétroaction du traceur face à un `<verify>` réellement rouge.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness — ce qui reste à trancher avant de reprendre ce plan

Ce plan **n'est pas terminé**. Task 2 (`check-trace-arbitrage.sh`) et Task 3 (registre de
preuves + rejeu CI) n'ont pas été commencées — aucun fichier créé, aucune ligne écrite dans
`41-PREUVES.md`.

Avant de reprendre :

1. **Décision humaine requise** sur la dérive de baseline (voir « Vérification non satisfaite ») :
   soit autoriser une allowlist à 6 entrées (amender l'acceptance criterion « exactement 3 » du
   plan 41-15), soit autoriser l'ajout du fragment canonique aux 4 artefacts identifiés (élargir
   le mandat au-delà de 41-14/CLAUDE.md), soit une troisième option arbitrée par Samuel.
2. Une fois la décision prise et appliquée (par un plan dédié ou un mandat élargi), rejouer
   `bash tools/check-aucune-fermeture.sh` sur le dépôt réel : rc=0, hits=0 attendu avant de
   considérer la Task 1 de ce plan comme pleinement close.
3. Task 2 et Task 3 restent alors à exécuter telles que le plan 41-15 les décrit — rien dans leur
   contenu propre n'est remis en cause par cette halte.
4. `41-PREUVES.md` n'a reçu AUCUNE écriture de ce plan : la section `## 41-15` reste à créer.

**Aucun blocage sur le contenu du script `check-trace-arbitrage.sh` lui-même** (Task 2) : son
design ne dépend pas de la dérive constatée ici, il pourra être exécuté sans changement une fois
la décision ci-dessus tranchée.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 15*
*Completed: 2026-09-18 (partiel — halte au gate de rétroaction du traceur)*

## Self-Check: PASSED (Task 1 uniquement)
