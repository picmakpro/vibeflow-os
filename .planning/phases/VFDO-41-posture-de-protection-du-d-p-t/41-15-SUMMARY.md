---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 15
subsystem: infra
tags: [bash, git, ci, qa, testing]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plan 41-14)
    provides: "41-PREUVES.md § 41-14 avec la ligne `BASE-TRACE-ARBITRAGE:` (borne du contrôle de
      trace de la Task 2) ; le patron de style (`scripts/check-baseline-arbitrage.sh`)"
provides:
  - "tools/check-aucune-fermeture.sh — recensement de co-occurrence sujet x achèvement,
    allowlist à 3 entrées, sonde de limite de fond ; rc=0, zéro hit sur le dépôt réel"
  - "tools/check-trace-arbitrage.sh — contrôle de FORME et d'UNICITÉ de la citation d'arbitrage,
    resserré à SIX marqueurs d'invocation d'autorité humaine explicites et fermés (décision du
    manager, reprise 2026-09-18, option c) : la porte d'entrée ne rougit plus sur une mention
    informelle de « décision »/« arbitrage » hors invocation ; rc=0 sur le dépôt réel"
  - "tools/test-check-trace-arbitrage.sh — 14 contrôles (C0..C13) et SIX mutants opposables
    (MUT-1 à MUT-6, dont deux nouveaux sur la porte d'entrée), 20/20 assertions vertes"
  - "41-PREUVES.md § 41-15 — sept clés mesurées (RECENSEMENT-FERMETURE, RECENSEMENT-CONTROLES,
    TRACE-ARBITRAGE, TRACE-CONTROLES, OUTILS-PERIMETRE, LIMITE-DE-FOND, BORNE-TRACE)"
affects: [41-16, 41-17, 41-18, 41-19]

# Actuals (#2632)
actuals:
  tokens: 29697
  tasks: 3
  commits: 12
  plan_head_before: 8cb8d46d719a227121194aeb67140287c9c4775f

tech-stack:
  added: []
  patterns:
    - "Marqueurs d'invocation explicites vs mots-racines génériques : un détecteur qui rougit sur
      la simple PRÉSENCE d'un mot-racine (« décision », « arbitrage ») capte toute mention
      descriptive DU sujet, pas seulement une invocation d'autorité — c'est le mode de défaut
      exact que cette phase combat (une garde qui rougit pour la mauvaise raison), appliqué cette
      fois au détecteur lui-même. Resserré à une liste FERMÉE de marqueurs qui ne peuvent
      apparaître que dans une invocation réelle (un prénom accolé au mot, une préposition figée,
      une clé numérotée réservée, un motif générique de suffixe deux-points, un jeton dédié), la
      même garde devient silencieuse sur la prose qui PARLE du sujet sans l'invoquer, tout en
      restant stricte (citation canonique complète exigée) dès qu'un marqueur est reconnu."
    - "Mutant jugé sur le dépôt réel, pas une fixture jetable : un mutant qui prouve qu'un
      RESSERREMENT DE PORTÉE change effectivement le verdict ne peut être prouvé que contre
      l'historique réel — une fixture jetable ne contient par construction aucune des mentions
      informelles pré-existantes que le resserrement visait à exempter. Patron réutilisable pour
      tout futur mutant de type « porte d'entrée d'un détecteur sur du texte historique »."
    - "safe_run() et fenêtre de citation bornée à 80 caractères (patterns déjà établis par la
      Task 2 du tour précédent) : inchangés par ce tour, réutilisés tels quels."

key-files:
  created:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-trace-arbitrage.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/test-check-trace-arbitrage.sh
  modified:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-trace-arbitrage.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/test-check-trace-arbitrage.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-aucune-fermeture.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/test-check-aucune-fermeture.sh
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-14-SUMMARY.md
    - CHANGELOG.md
    - scripts/check-baseline-arbitrage.sh
    - .github/workflows/ci.yml
    - scripts/tests/test-check-baseline-arbitrage.sh

key-decisions:
  - "Décision du manager de mission (reprise 2026-09-18, option c) appliquée intégralement sur
    le mur mesuré à la Task 2 : ni déplacement de `BASE-TRACE-ARBITRAGE`, ni exemption par date
    de commit — c'est le DÉTECTEUR de `tools/check-trace-arbitrage.sh` qui était trop large. Il
    ne rougit désormais que sur l'un de six marqueurs d'invocation d'autorité humaine, listés en
    toutes lettres en en-tête du script (deux formulations centrées sur le prénom de
    l'utilisateur principal, une formulation au datif, des clés courtes à deux chiffres
    réservées aux dix décisions numérotées, un motif générique de suffixe deux-points, et le
    jeton dédié à la levée d'une règle de protection de branche). Motif et fait mesuré (4
    commits rougissaient sans invoquer aucune autorisation, avant ce resserrement) écrits en
    en-tête, avec la citation canonique complète (nom, canal, date ISO) toujours exigée une fois
    un marqueur reconnu — seule la porte d'entrée a changé, jamais l'exigence de forme."
  - "« décision du manager » — le libellé qui attribue explicitement CE geste-ci au manager de
    mission, et que chaque commit de cette reprise porte par convention de dispatch — n'est
    volontairement PAS un marqueur d'invocation (ce n'est pas une autorité humaine ; l'ajouter
    aurait fait rougir le détecteur sur sa propre reformulation)."
  - "Décompte de mutants réellement mesuré pour `check-trace-arbitrage.sh` : 6 (pas 4). MUT-5
    élargit la porte d'entrée au mot-racine et est jugé sur la plage RÉELLE du dépôt (seul
    mutant de la suite à sortir du régime fixture-jetable) — c'est le seul moyen de prouver
    qu'un resserrement de portée change effectivement le verdict sur l'historique réel. MUT-6
    retire un marqueur de la liste et réutilise le scénario de fixture de C1."
  - "Point 5 de la décision du manager vérifié vert du premier coup : après le resserrement,
    `bash tools/check-trace-arbitrage.sh` (sans `--base-ref`) rend rc=0 sur le dépôt réel — aucun
    commit de la plage n'invoque une autorité humaine sans citation conforme. Aucune échappatoire
    n'a été nécessaire, et aucune n'a été ajoutée."
  - "Périmètre global (option (a), sans admin) : arbitrage Samuel, AskUserQuestion session
    principale, 2026-09-17 — déjà cité par 41-14 et par ce plan, inchangé par ce tour."

requirements-completed: []

coverage:
  - id: D1
    description: "Les 5 points du mandat élargi du tour précédent (reformulations, fragment
      canonique, CLAUDE.md hors liste, correctif safe_run, recensement rejoué) restent appliqués
      et vérifiés"
    requirement: PROT-04
    verification:
      - kind: other
        ref: "bash tools/check-aucune-fermeture.sh (sans --root, sur ce dépôt) — rc=0, 0 hit,
          fichiers=20, allowlist entrees=3 appliquees=3, limite exiges=7 porteurs=4 manquants=aucun"
        status: pass
    human_judgment: false
  - id: D2
    description: "tools/check-trace-arbitrage.sh resserré + sa suite QUAL-01 — 14 contrôles
      négatifs (C0..C13) et SIX mutants opposables (MUT-1 à MUT-6), tous crédités en forme
      canonique"
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "tools/test-check-trace-arbitrage.sh (bash --noprofile --norc -e, via wrapper
          d'invocation) — 20/20 assertions vertes"
        status: pass
    human_judgment: false
  - id: D3
    description: "L'outil rend rc=0 sur la plage réelle de la branche après resserrement
      (acceptance criteria de la Task 2 et precondition de la Task 3) — RÉSOLU ce tour, contraste
      avec l'échec mesuré au tour précédent"
    requirement: QUAL-01
    verification:
      - kind: other
        ref: "bash tools/check-trace-arbitrage.sh (sans --base-ref, sur ce dépôt) — rc=0,
          17..18 commits jugés (le compte croît d'une unité par commit ajouté), 2 citants,
          tous conformes"
        status: pass
    human_judgment: false
  - id: D4
    description: "Task 3 exécutée telle qu'écrite : 41-PREUVES.md § 41-15 avec ses sept clés
      mesurées, rejeu complet des jobs gates et tests de ci.yml"
    requirement: PROT-04
    verification:
      - kind: unit
        ref: "gates : rc=0, 11 étapes rejouées, 2 sautées (action checkout implicite,
          check-release-tag conditionnel main), 0 en échec"
        status: pass
      - kind: unit
        ref: "tests : rc=0, 1 étape rejouée (Découvrir et lancer toutes les suites), 5 sautées
          (installation/infra du runner), bilan 80 suite(s) 0 échec(s)"
        status: pass
    human_judgment: false

duration: ~1h10 (ce tour ; ~1h10 tour précédent d'écriture ; ~2h20 tour de mandat élargi ;
  ~1h10 tour initial)
completed: 2026-09-18
status: complete
---

# Phase 41 Plan 15: Outillage de preuve du périmètre sans admin — resserrement du détecteur, Task 3 close

**`tools/check-trace-arbitrage.sh` est resserré à une liste FERMÉE de six marqueurs d'invocation
d'autorité humaine (décision du manager, reprise 2026-09-18, option c) : il ne rougit plus sur
une mention informelle de « décision »/« arbitrage », seulement sur une invocation reconnue —
citation canonique complète toujours exigée dans ce cas. `bash tools/check-trace-arbitrage.sh`
rend rc=0 sur le dépôt réel dès la première mesure après ce resserrement. Décompte de mutants
réellement mesuré : 6 (pas 4), dont un jugé sur la plage réelle du dépôt. Task 3 exécutée telle
qu'écrite : `41-PREUVES.md` § 41-15 porte ses sept clés mesurées, et le rejeu complet des jobs
`gates` (11 étapes, 0 échec) et `tests` (80 suites, 0 échec) de `ci.yml` est vert. Le plan est
clos.**

## Limite de fond

`tools/check-aucune-fermeture.sh` et `tools/check-trace-arbitrage.sh` vivent dans ce dépôt, comme
toute garde de cette phase : chacune peut être modifiée par la PR qu'elle juge — la même PR peut
changer l'outil, sa suite et l'étape CI qui l'invoque et rester verte. Elles rendent visible et
tracent une co-occurrence sujet x achèvement ou une invocation d'autorité humaine sans citation
conforme ; elles ne verrouillent rien. Aucun droit admin n'existe dans ce périmètre pour poser une
règle côté GitHub qui empêcherait cette même PR de neutraliser l'un ou l'autre outil.

## Performance

- **Durée :** ~1h10 ce tour (resserrement du détecteur + Task 3 + rejeu CI complet, deux fois)
- **Tâches :** Task 1 (mandat élargi, tour précédent) et Task 2 (écriture initiale, tour
  précédent) restent closes ; ce tour resserre `check-trace-arbitrage.sh` (mandat de reprise) et
  exécute Task 3 dans son intégralité
- **Fichiers modifiés ce tour :** 3 (`check-trace-arbitrage.sh`, `test-check-trace-arbitrage.sh`,
  `41-PREUVES.md`)

## Accomplissements

**Resserrement du détecteur de trace (décision du manager, reprise 2026-09-18, option c) :**

1. `MARKER_REGEX` remplace l'ancienne liste de mots-racines (`arbitrage`, `décision`, leurs
   variantes) par SIX marqueurs d'invocation explicites et fermés : deux formulations centrées
   sur le prénom de l'utilisateur principal, une formulation au datif, des clés courtes à deux
   chiffres réservées aux dix décisions numérotées, un motif générique de suffixe deux-points, et
   le jeton dédié à la levée d'une règle de protection de branche. `kw_present()` teste désormais
   ce motif via `[[ =~ ]]` bash, au lieu d'un balayage de mots-racines par `case`.
2. En-tête du script : nouvelle section « PORTEE DE LA DETECTION » documentant le choix, son
   motif (« une garde qui rougit sur de la prose descriptive apprend au lecteur à l'ignorer, et
   une garde qu'on apprend à ignorer ne garde plus rien »), et le fait mesuré qui l'a motivé (4
   commits rougissaient sans invoquer aucune autorisation, avant ce resserrement). Le libellé qui
   attribue ce geste-ci au manager n'est explicitement pas un marqueur.
3. Les comparaisons 1/2/3 (forme canonique, unicité, arbitrage du périmètre) et les fonctions
   `normalize()`, `scan_strip()`, la résolution de `BASE_SHA` restent INCHANGÉES — seule la porte
   d'entrée du détecteur a changé, jamais l'exigence de forme une fois un marqueur reconnu.
4. Mesure sur le dépôt réel après resserrement : **rc=0** du premier coup, sans itération —
   aucun commit de la plage n'invoque une autorité humaine sans citation conforme.

**Suite QUAL-01 étendue à SIX mutants (décompte réellement mesuré, pas supposé) :**

- MUT-1 à MUT-4 (comparaisons de forme, d'unicité, de résolution de borne, de normalisation)
  inchangés dans leur code cible — toujours tués en forme canonique.
- MUT-5 (nouveau) élargit la porte d'entrée à la simple occurrence du mot-racine — **seul mutant
  de la suite jugé sur la plage RÉELLE du dépôt**, jamais une fixture jetable : le mutant rend
  rouge (rc=1) l'historique réel (mentions informelles pré-existantes redevenues visibles),
  l'original reste vert (rc=0).
- MUT-6 (nouveau) retire le marqueur centré sur le prénom de l'utilisateur principal, sur une
  fixture jetable reprenant le scénario de C1 (citation sans canal ni date) : le mutant rend vert
  (marqueur disparu, plus rien à juger), l'original reste rouge (marqueur toujours reconnu,
  citation incomplète).
- **20/20 assertions vertes** (14 contrôles C0..C13 inchangés + 6 mutants), rejouées sous
  l'invocation stricte `bash --noprofile --norc -e` exigée par le `<verify>` du plan.

**Task 3 : mesures consignées au registre de preuves (précondition désormais remplie).**

`41-PREUVES.md` § 41-15 ajoutée avec ses sept clés, chacune à sa valeur mesurée :

- `RECENSEMENT-FERMETURE: rc=0 fichiers=20 hits=0 allowlist_entrees=3 allowlist_appliquees=3`
- `RECENSEMENT-CONTROLES: R0..R11=0,1,1,1,0,0,0,2,64,1,0,0 mutants_tues=3`
- `TRACE-ARBITRAGE: rc=0 commits=17 citants=2 base=f1d6589`
- `TRACE-CONTROLES: C0..C13=0,1,1,0,1,0,0,3,2,64,0,0,2,2 mutants_tues=6`
- `OUTILS-PERIMETRE: distribues=non etapes_ci=0 decouverts_par_le_job_tests=non`
- `LIMITE-DE-FOND: exiges=7 porteurs=4 manquants=aucun`
- `BORNE-TRACE: sha=f1d6589 source=41-PREUVES.md commits_juges=17 commits_hors_borne=1255`

Rejoué APRÈS écriture (le registre est lui-même dans le périmètre du recensement) : recensement
rc=0 (0 hit, aucune nouvelle entrée d'allowlist), les deux suites 0/0 échec, section `## 41-01`
et sa ligne `CONTEXTES-CHECKS` intactes (`cles=7 section=1 contextes_checks_intact=1`).

**Rejeu CI complet (gates + tests), découverte non recopiée :**

- `gates` : rc=0, **11 étapes rejouées**, 2 sautées (action `checkout` implicite ; `check-release-
  tag` conditionnel sur `push`/`main`), 0 en échec.
- `tests` : rc=0, 1 étape rejouée (« Découvrir et lancer toutes les suites »), 5 sautées
  (installation/infra du runner : Dépendances, Installer le moteur GSD, Canari de forme du
  moteur GSD, et deux étapes implicites), bilan **80 suite(s), 0 échec(s)**.
- Rejoué une seconde fois pour la mesure formelle du `<verify>` du plan : `gates rc=0 etapes=11
  tests rc=0 bilan(N M)=80 0` — seuils du plan (≥11 étapes, ≥80 suites, 0 échec) tous satisfaits.
- Périmètre non rejoué par cet outil (jobs distincts, jamais invoqués par `--job tests|gates`) :
  `lab-frais` et `lab-frais-arme`.

## Task Commits

Tours précédents (avant cette reprise, voir historique complet dans les commits Git) :

1. Task 1 : recensement, allowlist, sonde de limite de fond — `7ac7cf7` (feat)
2. Halte — `b64766d` (docs)
3–7. Mandat élargi (points 1 à 4) — `db5d15c`, `7e829a8`, `b8cd0e5`, `9776bd9`, `0ba95ba`
8. Task 2 : `check-trace-arbitrage.sh` initial, borne lue, 4 mutants — `4481888` (feat)
9. Halte avant Task 3 (SUMMARY) — `774b7f6` (docs)

Ce tour (reprise, décision du manager option c) :

10. **Resserrement de `check-trace-arbitrage.sh` à six marqueurs d'invocation explicites** —
    `e24a3e7` (fix)
11. **Deux mutants supplémentaires (MUT-5, MUT-6) sur la porte d'entrée** — `2f7e4e6` (feat)
12. **Task 3 : sept clés mesurées au registre de preuves** — `2a6bd66` (docs)

_Ledger de commits (`plan_head_before`, mesuré depuis le tout début du plan 41-15, tous tours
inclus) : `8cb8d46d719a227121194aeb67140287c9c4775f`. `commits` mesuré (`git rev-list --count`,
avant ce commit de SUMMARY) : 12._

## Files Created/Modified

- `tools/check-trace-arbitrage.sh` — porte d'entrée resserrée à six marqueurs d'invocation, en-
  tête « PORTEE DE LA DETECTION » ajoutée
- `tools/test-check-trace-arbitrage.sh` — MUT-5 (plage réelle) et MUT-6 (fixture, marqueur
  retiré) ajoutés, en-tête mis à jour (6 mutants)
- `41-PREUVES.md` — section `## 41-15` ajoutée avec ses sept clés mesurées

(Fichiers hérités des tours précédents, inchangés ce tour : `tools/check-aucune-fermeture.sh`,
`tools/test-check-aucune-fermeture.sh`, `41-14-SUMMARY.md`, `CHANGELOG.md`,
`scripts/check-baseline-arbitrage.sh`, `.github/workflows/ci.yml`,
`scripts/tests/test-check-baseline-arbitrage.sh`.)

## Decisions Made

Voir `key-decisions` en frontmatter. Le resserrement du détecteur est une décision explicite du
manager de mission (reprise 2026-09-18, option c), citée comme telle dans chaque message de
commit de ce tour — jamais la forme canonique d'arbitrage humain (le manager a été explicite :
ce n'est pas une autorité humaine). Le périmètre global (option (a), sans admin) reste
l'arbitrage Samuel du 2026-09-17 déjà cité par 41-14 et par ce plan, inchangé par ce tour.

## Deviations from Plan

Aucune — ce tour applique fidèlement la décision du manager (option c) puis exécute la Task 3
telle qu'écrite dans le plan. Aucun bug, aucune fonctionnalité manquante, aucun blocage
technique n'a nécessité de correction Rule 1/2/3 ce tour : le seul geste était le resserrement
explicitement commandité, et il a fonctionné du premier coup (rc=0 sans itération).

### Correctif mécanique post-clôture (2026-09-18)

Une re-vérification indépendante a mesuré `bash tools/check-aucune-fermeture.sh` à rc=1 sur ce
même SUMMARY, alors que ce fichier affirmait déjà `manquants=aucun` : la réécriture finale du
SUMMARY (commit `05b856f`) est intervenue APRÈS le dernier rejeu du recensement par la Task 3, et
n'a pas reporté le fragment canonique de la limite de fond dans son propre corps — `41-15-
SUMMARY.md` est lui-même l'un des quatre porteurs exigés par la sonde (glob `41-1*-SUMMARY.md`).
Rule 3 (blocage mécanique, pas une décision) : section « Limite de fond » ajoutée ci-dessus,
portant le fragment `modifiée par la PR qu'elle juge` dans un énoncé qui a un sens réel pour ce
plan. Rejeu après correctif : `check-aucune-fermeture.sh` rc=0 (fichiers=20, hits=0, limite
exiges=7 porteurs=4 manquants=aucun) ; `check-trace-arbitrage.sh` rc=0 (commits=19, citants=2,
croissance attendue depuis la mesure `commits=17` de `41-PREUVES.md`, déjà documentée comme
propriété normale de cette clé) ; les deux suites (`test-check-aucune-fermeture.sh` 15/15,
`test-check-trace-arbitrage.sh` 20/20) toujours vertes, aucune régression. `41-PREUVES.md` § 41-15
n'a pas eu besoin d'être retouché : ses valeurs `RECENSEMENT-FERMETURE` et `LIMITE-DE-FOND`
déjà écrites correspondent exactement à l'état mesuré après ce correctif. Aucune autre décision de
ce plan n'a été rouverte (allowlist à 3, six marqueurs fermés du détecteur de trace inchangés).

## Issues Encountered

Aucune. Le mur mesuré au tour précédent (rc=1, trois puis quatre commits pré-existants mentionnant
« décision »/« arbitrage » de façon informelle) est résolu par le resserrement du détecteur —
décision du manager, option c, appliquée intégralement. Aucune échappatoire (allowlist, exception
par sha, déplacement de borne) n'a été ajoutée : le détecteur reste capable de rougir (prouvé par
les six mutants, dont un sur la plage réelle du dépôt) et rend rc=0 pour une raison structurelle
(porte d'entrée resserrée à une liste fermée), pas par affaiblissement ad hoc.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

**Ce plan est CLOS.** Les trois tâches sont pleinement exécutées et vérifiées :

1. Task 1 (mandat élargi) — close depuis le tour précédent, toujours verte.
2. Task 2 (`check-trace-arbitrage.sh`) — close ce tour : détecteur resserré, rc=0 sur le dépôt
   réel, 20/20 assertions vertes (6 mutants).
3. Task 3 (registre de preuves + rejeu CI) — close ce tour : sept clés mesurées, `gates` et
   `tests` verts après rejeu complet.

Rien ne bloque la suite de la phase (`41-16` : garde G-2, dépend de ce plan pour son style et sa
convention `Gate-Touche:`, introduite ici en documentation mais pas encore appliquée en garde
machine — c'est l'objet du plan 41-16 lui-même).

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 15*
*Completed: 2026-09-18*

## Self-Check: PASSED

Fichiers vérifiés présents : `tools/check-trace-arbitrage.sh`, `tools/test-check-trace-
arbitrage.sh`, `41-PREUVES.md`. Commits vérifiés présents dans l'historique : `e24a3e7`,
`2f7e4e6`, `2a6bd66`.
