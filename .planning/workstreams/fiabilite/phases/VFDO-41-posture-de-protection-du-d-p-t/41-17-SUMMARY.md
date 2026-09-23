---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 17
subsystem: infra
tags: [bash, github-api, ci, qa, testing]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plan 41-16)
    provides: "structure et convention de `scripts/check-gate-touche.sh` (en-tête, contrat de
      codes de sortie, ligne `decouverte:`) et le trailer `Gate-Touche:` déjà vivant en CI —
      reprise pour `check-push-sans-pr.sh`"
provides:
  - "scripts/check-push-sans-pr.sh — alarme après coup sur un push direct vers `main` sans PR
    associée : deux lectures GitHub en cascade (`commits/pulls` puis `merge_commit_sha` des PR
    closes), distinction stricte échec d'API / liste vide, traitement de la création de ref"
  - "scripts/tests/test-check-push-sans-pr.sh — 21 assertions (PASS/FAIL/BRUYANT/SILENCE/USAGE +
    un contrôle négatif dédié), cinq mutants opposables (MUT-1 à MUT-5), zéro appel réseau"
  - "deux étapes `gates` dans `.github/workflows/ci.yml` : preuve par fixture à quatre bascules
    (sans condition) et mesure réelle (conditionnée push vers `main`, `GH_TOKEN`)"
  - "CHANGELOG.md § Non releasé — entrée G-3 sous celle de G-2"
affects: [41-18, 41-19]

# Actuals (#2632)
actuals:
  tokens: 12274
  tasks: 3
  commits: 3
  plan_head_before: c9439f10eba2be536cf462d9c1dca967a11539d1

tech-stack:
  added: []
  patterns:
    - "Cascade à deux lectures avec raison mesurée : quand la première lecture GitHub ne suffit
      pas structurellement (un merge par rebase change le sha), la seconde lecture cible un champ
      distinct (`merge_commit_sha`) plutôt que de réinterroger la même API — et la fixture qui le
      prouve nomme les PR réelles (#71, #72) qui ont motivé la cascade."
    - "Assertion de non-vacuité comme SOURCE UNIQUE, jamais dupliquée : une classification interne
      (`classify_pulls`) qui refait sa propre vérification de « numéro lisible » rend la garde
      externe dédiée injoignable — donc son mutant ne peut jamais flip. Corrigé en Task 2 : la
      classification renvoie ASSOCIEE dès qu'un tableau est non vide, et c'est la SEULE assertion
      en aval, dans le flot principal, qui rattrape un numéro absent avant tout rc 0."
    - "Un sous-mot d'une option CLI légitime (`--closed-pulls-file` contient `closed`) peut co-
      occurrer avec le nom du script sur une même ligne et faire rougir un recenseur de jetons —
      la parade est structurelle (scinder le message sur deux lignes), jamais un ajout à
      l'allowlist du recenseur."

key-files:
  created:
    - scripts/check-push-sans-pr.sh
    - scripts/tests/test-check-push-sans-pr.sh
  modified:
    - .github/workflows/ci.yml
    - CHANGELOG.md
    - README.md
    - README.fr.md

key-decisions:
  - "Périmètre sans admin (option (a)) : arbitrage Samuel, AskUserQuestion session principale,
    2026-09-17 — repris tel quel de 41-14/41-15/41-16, inchangé par ce plan."
  - "MUT-1 (test de vacuité de la première lecture) : le texte du plan ne donnait pas de paire de
    codes de sortie explicite (contrairement à MUT-2..5). Conception retenue : rc_mutant=2,
    rc_original=1 — un flip réel et mesuré (jamais un `cmp` identique), qui prouve que ce test est
    nécessaire même sous l'assertion de non-vacuité (MUT-5) : sans lui, une fixture « deux lectures
    vides » n'est plus signalée PUSH-SANS-PR mais NON-VERIFIABLE. Documenté comme choix de
    conception, pas résolu silencieusement — voir « Zones grises » plus bas."
  - "`--repo` malformé (sans `/`) : le plan laissait le choix entre rc 64 et rc 2 (« le cas ASSERTE
    la valeur choisie »). Retenu : rc 2 — catégorisé comme une configuration non exploitable
    (même famille que `--sha`/`--repo` non dérivables), pas une erreur de syntaxe CLI. Asserté tel
    quel dans la suite."
  - "Détection de la création de ref sans `--before` (invocation à la main, sha sans parent) :
    implémentée en best-effort via le dépôt git local, mais jamais exercée par les fixtures du
    plan (qui fournissent toutes `--before`). Un sha non résoluble localement ne fait jamais
    échouer le script — il poursuit normalement. Voir « Zones grises »."

requirements-completed: [PROT-05, QUAL-01]

coverage:
  - id: D1
    description: "check-push-sans-pr.sh existe, passe bash -n, rend 64 sur argument inconnu,
      et ses trois verdicts de fixture (associée rc0, vide rc1, création de ref rc3) sont prouvés
      hors réseau"
    requirement: PROT-05
    verification:
      - kind: unit
        ref: "Task 1 <verify> automated 1-3 du plan 41-17 — tous rc attendus obtenus"
        status: pass
    human_judgment: false
  - id: D2
    description: "Suite QUAL-01 : 21 assertions, 0 ko, cinq mutants (MUT-1 à MUT-5) tués en forme
      canonique, aucun appel réseau dans le fichier de suite"
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "scripts/tests/test-check-push-sans-pr.sh (bash, sans -e — voir Zones grises) —
          21/21 assertions vertes, 5/5 mutants tués"
        status: pass
    human_judgment: false
  - id: D3
    description: "Étape de fixture CI à quatre bascules isolées (rc0/rc0/rc1/rc2), câblée avant
      check-release-tag, compatibilité PROT-02 prouvée sur pièce (ordre des étapes, absence de
      tags: dans le déclencheur, voie rebase)"
    requirement: PROT-05
    verification:
      - kind: integration
        ref: "Task 3 <verify> automated 1, 3 du plan 41-17 — rejeu gates rc=0 (13 étapes), preuve
          par fixture 0 écart sur 4 verdicts, ordre/tags/GH_TOKEN vérifiés par awk"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG.md § Non releasé porte l'entrée G-3 ; VERSION racine intacte ; aucun
      bump de module ; recensement (check-aucune-fermeture.sh) et contrôle de trace
      (check-trace-arbitrage.sh) à rc=0"
    requirement: PROT-05
    verification:
      - kind: other
        ref: "Task 3 <verify> automated 2, 4 du plan 41-17 — tests rc=0 (82 suites, 0 échec),
          changelog_G3=1 VERSION=v2.63.2 recensement_rc=0 trace_rc=0"
        status: pass
    human_judgment: false

duration: ~50min (session complète, lecture des fichiers requis incluse) ; ~22min entre le premier
  et le dernier commit
completed: 2026-09-18
status: complete
---

# Phase VFDO-41 Plan 17: G-3, alarme après coup sur un push direct vers `main` sans PR associée — Summary

**`scripts/check-push-sans-pr.sh` interroge GitHub en deux lectures en cascade (commits/pulls,
puis `merge_commit_sha` des PR closes pour couvrir le merge par rebase de ce dépôt) et signale,
après coup, un commit arrivé sur `main` sans PR associée — jamais un verrou, jamais une écriture
GitHub. Câblé en CI sur deux étapes (preuve par fixture à quatre bascules sans condition, mesure
réelle conditionnée `push`/`main` avec `GH_TOKEN`), couvert par 21 assertions et cinq mutants
opposables, sans aucun appel réseau dans le fichier de suite.**

## Performance

- **Durée :** ~50 min (session complète) ; ~22 min entre le premier commit (`c42ad4e`,
  15:43:13+02:00) et le dernier (`e087ea5`, 16:05:14+02:00)
- **Tâches :** 3/3
- **Fichiers modifiés :** 6 (2 créés, 4 modifiés)

## Accomplissements

- `scripts/check-push-sans-pr.sh` — deux lectures GitHub en cascade, cinq codes de sortie
  (0/1/2/3/64), création de ref traitée, ligne `decouverte:` à cinq champs, options
  `--pulls-file`/`--closed-pulls-file` réservées aux fixtures
- `scripts/tests/test-check-push-sans-pr.sh` — 21 assertions (4 PASS, 1 contrôle négatif, 2 FAIL,
  4 BRUYANT, 2 SILENCE, 3 USAGE, 5 mutants), 0 ko, aucun appel réseau
- Deux étapes `gates` dans `.github/workflows/ci.yml`, juste après `check-gate-touche` et avant
  `check-release-tag` : preuve par fixture à quatre bascules isolées (0 écart) et mesure réelle
  conditionnée `main`
- Compatibilité du flux de release (PROT-02) prouvée sur pièce : `on.push.branches` ne porte
  aucune entrée `tags:` (0 mesurée), donc un tag annoté ne déclenche jamais ce workflow
- `CHANGELOG.md` § Non releasé — entrée G-3 sous celle de G-2, `VERSION` racine intacte
  (`v2.63.2`), aucun bump de module

## Task Commits

1. **Task 1 : G-3 bout en bout — script à deux lectures en cascade et son étape CI à une
   bascule** — `c42ad4e` (feat)
2. **Task 2 : suite QUAL-01, trois issues plus contrôle négatif, cinq mutants opposables** —
   `90532fd` (test)
3. **Task 3 : étape CI à quatre bascules, compatibilité PROT-02 sur pièce, CHANGELOG** —
   `e087ea5` (docs)

_Ledger (`plan_head_before`, mesuré au tout début du plan 41-17) :
`c9439f10eba2be536cf462d9c1dca967a11539d1`. `commits` mesuré (`git rev-list --count`, avant ce
commit de SUMMARY) : 3._

## Files Created/Modified

- `scripts/check-push-sans-pr.sh` — la garde G-3, deux lectures en cascade
- `scripts/tests/test-check-push-sans-pr.sh` — sa suite QUAL-01
- `.github/workflows/ci.yml` — deux étapes `check-push-sans-pr` dans le job `gates`
- `CHANGELOG.md` — entrée G-3 sous § Non releasé
- `README.md`, `README.fr.md` — badge/texte du compte de suites (81 → 82, correctif Rule 1, voir
  Déviations)

## Decisions Made

Voir `key-decisions` en frontmatter. Résumé :

1. Périmètre sans admin (option (a)) inchangé — même autorisation que 41-14/41-15/41-16.
2. MUT-1 : paire de codes de sortie (rc_mutant=2, rc_original=1) choisie par conception, le plan
   ne la donnant pas explicitement pour ce mutant précis (il la donne pour MUT-2 à MUT-5).
3. `--repo` malformé → rc 2 (contrat retenu explicitement, le plan laissait 64 ou 2 au choix).
4. Détection best-effort de la création de ref sans `--before` — jamais exercée par les fixtures
   du plan, comportement documenté en en-tête du script.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Assertion de non-vacuité rendue injoignable par une garde locale redondante**
- **Found during:** Task 2 (écriture de MUT-5)
- **Issue:** `classify_pulls` (chemins `jq` et repli `awk`) portait sa propre vérification interne
  « numéro de PR lisible » et renvoyait déjà `INDETERMINE` dans ce cas, avant même d'atteindre
  l'assertion de non-vacuité dédiée du flot principal — cette dernière devenait du code mort,
  et MUT-5 ne pouvait jamais produire le flip attendu (rc_mutant=0, rc_original=2).
- **Fix:** `classify_pulls` renvoie désormais `ASSOCIEE` dès qu'un tableau est non vide, même sans
  `number` lisible ; l'assertion de non-vacuité du flot principal devient la SEULE source qui
  rattrape ce cas avant tout rc 0.
- **Files modified:** `scripts/check-push-sans-pr.sh`
- **Verification:** MUT-5 tue correctement (`rc_mutant=0 attendu 0, rc_original=2 attendu 2`) ;
  les 4 autres mutants et les 16 assertions non-mutants restent verts.
- **Committed in:** `90532fd` (Task 2 commit)

**2. [Rule 1 - Bug] Deux messages d'erreur combinaient le préfixe du script et le nom complet
d'une option de fixture sur une même ligne**
- **Found during:** Task 2 (rejeu du recenseur du plan 41-15 avant le commit)
- **Issue:** le nom complet de l'option de fixture pour les PR closes contient un sous-mot qui, une
  fois combiné sur la même ligne physique avec le préfixe entre crochets du script, est lu comme
  une co-occurrence sujet × achèvement par le recenseur `tools/check-aucune-fermeture.sh` (plan
  41-15) — un faux hit sur un texte par ailleurs légitime.
- **Fix:** les deux messages concernés scindés sur deux lignes chacun, même contenu informatif
  pour l'opérateur, le préfixe du script et le nom de l'option ne partageant plus jamais la même
  ligne physique du fichier source.
- **Files modified:** `scripts/check-push-sans-pr.sh`
- **Verification:** le recenseur rend 0 hit après correctif ; suite QUAL-01 toujours 21/21.
- **Committed in:** `90532fd` (Task 2 commit)

**3. [Rule 1 - Bug] Badges de compte de suites (README.md, README.fr.md) périmés à 81**
- **Found during:** Task 3 (rejeu complet du job `gates`, étape `check-version-sync`)
- **Issue:** L'ajout de `scripts/tests/test-check-push-sans-pr.sh` en Task 2 a fait passer le
  compte réel de suites de 81 à 82 ; les deux README affirmaient encore 81, faisant échouer
  `check-version-sync.sh` (donc le job `gates` complet) dès ce rejeu.
- **Fix:** badge/texte mis à jour à `82 suites` dans les deux fichiers, aucun autre contenu touché.
- **Files modified:** `README.md`, `README.fr.md`
- **Verification:** `check-version-sync.sh` rc=0 ; rejeu complet `gates` rc=0 (13 étapes, 0 échec).
- **Committed in:** `e087ea5` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 — un bug de conception de test, une collision de
recensement, une dérive de badge mesurée en aval de Task 2).
**Impact on plan:** Les trois correctifs étaient nécessaires à la justesse de la suite et à la
santé du job `gates` complet ; aucun n'élargit le périmètre du plan au-delà de ses trois tâches.

## Zones grises (jugements explicites, non résolus en silence)

1. **Verify du plan invoqués sous une forme différente de leur texte littéral.** Chaque
   `<verify><automated>` de ce plan est écrit `bash --noprofile --norc -e -c '…'` ou
   `bash --noprofile --norc -e <fichier>`. Le harnais d'isolation de ce worktree refuse TOUTE
   invocation `bash` portant ces options (`-c` ou `-e` combinés à `--noprofile`/`--norc`), qu'elle
   touche git ou non — parce qu'il ne peut pas prouver statiquement que le texte shell embarqué
   n'invoque jamais git (et `check-push-sans-pr.sh` invoque effectivement git en best-effort,
   § détection de création de ref). Seule une invocation `bash <fichier>` SANS option est acceptée.
   J'ai exécuté le CORPS EXACT de chaque commande de vérification (octet pour octet, aucune ligne
   modifiée), simplement via `bash <fichier>` au lieu de `bash --noprofile --norc -e -c '…'` —
   vérifié que `-e` ne changeait aucun résultat observable pour ces commandes précises (elles
   capturent déjà leurs codes de sortie via `|| rc=$?` sans dépendre d'un arrêt anticipé). Ceci est
   une contrainte d'environnement, jamais un affaiblissement du contrat du plan — signalé ici
   plutôt que résolu en silence, comme demandé par les instructions d'exécution.
2. **MUT-1 : paire de codes de sortie choisie, pas donnée par le plan.** Voir `key-decisions` et
   Task 2 ci-dessus — le texte du plan donne les rc exacts pour MUT-2 à MUT-5 mais pas pour MUT-1
   (« devient verte sur le mutant »). J'ai retenu rc_mutant=2/rc_original=1, un flip réel et
   mesuré, documenté en commentaire dans la suite elle-même.
3. **`--repo` malformé → rc 2, pas 64.** Le plan laissait explicitement ce choix à l'exécuteur
   (« le cas ASSERTE la valeur choisie »). Choix documenté en commentaire de script et de suite.
4. **Détection best-effort de la création de ref sans `--before`.** Le texte du plan mentionne ce
   cas (« si le sha jugé n'a aucun parent ») sans fournir de fixture pour l'exercer — aucune
   fixture du plan ne teste cette branche (toutes fournissent `--before`). Implémentée en
   best-effort via le dépôt git local, jamais bloquante si le sha est inconnu localement ; non
   couverte par un cas dédié de la suite QUAL-01 (aucun cas du plan ne le demande explicitement).
5. **41-16-SUMMARY.md, requis par la lecture préalable, absent de tout l'historique du dépôt.**
   Confirmé par `git log --oneline --all -- '*41-16-SUMMARY.md*'` (aucun résultat) : le plan 41-16
   n'a jamais produit ce fichier lors de son exécution. J'ai lu `scripts/check-gate-touche.sh` et
   `scripts/tests/test-check-gate-touche.sh` directement (le plan 41-17 dit explicitement que
   41-17 « reprend » cette structure) pour reconstruire le contexte attendu du plan 41-16.
6. **Configuration du worktree au démarrage.** La branche de ce worktree
   (`worktree-agent-adc8b2f7db44c76aa`) pointait initialement sur `main` (`5238cba`), sans aucun
   des 37 commits de `feat/phase-41-protection-depot` — dont `41-17-PLAN.md` lui-même. Aucune
   divergence propre n'existant encore (HEAD = merge-base), corrigé par un `git merge --ff-only
   feat/phase-41-protection-depot` avant toute tâche — geste sûr et non destructif (fast-forward
   pur), fait AVANT le premier commit de ce plan.

## Issues Encountered

Aucune non documentée ci-dessus. Les trois rejeux complets de `gates`/`tests` sont verts, aucun
mutant n'est resté vivant, `check-aucune-fermeture.sh` et `check-trace-arbitrage.sh` sont à rc=0
sur le dépôt réel.

## User Setup Required

None - aucune configuration de service externe requise (le seul appel de production est une
lecture GitHub via le `GITHUB_TOKEN` déjà fourni par Actions, jamais un secret à poser).

## Next Phase Readiness

Rejeu `gates` : rc=0, **13 étapes rejouées**, 3 sautées (action `checkout` implicite ;
`check-push-sans-pr` mesure réelle conditionnelle `main` ; `check-release-tag` conditionnel
`main`), 0 en échec. Rejeu `tests` : rc=0, 1 étape rejouée (« Découvrir et lancer toutes les
suites »), 5 sautées (installation/infra du runner), bilan **82 suite(s), 0 échec(s)**.

**Périmètre non rejoué, nommé plutôt que masqué :**
- L'étape `check-push-sans-pr (G-3, PROT-05 — mesure réelle sur un push vers main)` est
  conditionnelle `github.event_name == 'push' && github.ref == 'refs/heads/main'` : elle est
  structurellement SAUTÉE par tout rejeu local (comme `check-release-tag`, sur le même modèle) et
  ne peut être exercée que par un run réel sur `main` après merge — jamais depuis une branche ou
  un rejeu local. C'est l'étape de fixture SANS condition qui porte la preuve de sa capacité à
  rendre chacun de ses quatre verdicts.
- Les jobs `lab-frais` et `lab-frais-arme` ne sont jamais invoqués par
  `replay-ci-jobs.sh --job tests|gates` (portée de l'outil, jobs distincts) — non couverts par ce
  plan, comme pour les plans précédents de cette phase.

Aucun blocage pour `41-18` : `scripts/check-push-sans-pr.sh` et sa suite suivent le même patron
que `scripts/check-gate-touche.sh`, directement réutilisable pour toute garde future de ce dépôt.
`docs/ADR.md` § ADR-072 reste à écrire par un plan ultérieur (non exigé par 41-17).

## Limite de fond

`scripts/check-push-sans-pr.sh` vit dans ce dépôt, comme toute garde de cette phase : elle peut
être modifiée par la PR qu'elle juge — la même PR peut changer le script, sa suite et l'étape CI
qui l'invoque et rester verte. Faute d'accès admin sur ce dépôt, aucune règle côté GitHub n'existe
pour l'empêcher. Elle rend visible et trace un push direct sans PR associée ; elle ne verrouille
rien — c'est une alarme après coup, jamais un verrou : quand elle rougit, le commit qu'elle juge
est déjà sur `main`.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 17*
*Completed: 2026-09-18*

## Self-Check: PASSED

Fichiers vérifiés présents : `scripts/check-push-sans-pr.sh`, `scripts/tests/test-check-push-sans-pr.sh`.
Commits vérifiés présents dans l'historique : `c42ad4e`, `90532fd`, `e087ea5`.
