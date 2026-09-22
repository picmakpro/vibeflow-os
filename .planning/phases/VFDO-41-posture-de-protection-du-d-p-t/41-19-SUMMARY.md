---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 19
subsystem: docs
tags: [ledger, preuves, cloture, security, gouvernance]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plans 41-14, 41-15, 41-16, 41-17, 41-18)
    provides: "les trois gardes livrées et vérifiées réelles (check-baseline-arbitrage.sh,
      check-gate-touche.sh, check-push-sans-pr.sh), l'outillage de preuve du périmètre
      (check-aucune-fermeture.sh, check-trace-arbitrage.sh), et la doctrine (ADR-072, CLAUDE.md,
      O-3 signalée et tracée)"
provides:
  - "41-PREUVES.md § 41-19 — rejeu final des deux jobs CI, mesure réelle des trois gardes,
    recensement et trace finaux, inventaire des SUMMARY, absence de bump, constat
    d'inatteignabilité de PROT-01 et des critères 1-3 du ROADMAP"
  - "REQUIREMENTS.md — famille PROT (5 IDs), QUAL-01 mis à jour, table de traçabilité"
affects: []

# Actuals
actuals:
  tokens: null
  tasks: 3
  commits: 3
  plan_head_before: 832b310

tech-stack:
  added: []
  patterns:
    - "Ledger coché sur pièce : chaque case cochée cite les clés du registre 41-PREUVES.md et le
      plan qui les a produites, jamais une déclaration nue"

key-files:
  created:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-19-SUMMARY.md
  modified:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Aucun arbitrage de fond nouveau : ce plan clôt le périmètre sans admin déjà arbitré par le
    manager le 2026-09-17 (option (a), bornes de G-1, création de PROT-05)."
  - "Deux écarts mécaniques de vérification découverts et documentés plutôt que contournés — voir
    § Zones grises. Aucun outil de recensement ni allowlist modifié."

requirements-completed: [PROT-02, PROT-03, PROT-04, PROT-05, QUAL-01]

coverage:
  - id: D1
    description: "Rejeu final des deux jobs CI sur la découverte complète"
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job gates : rc=0, 13 étapes rejouées, 3 sautées, 0 échec ;
          --job tests : rc=0, 1 étape rejouée (Découvrir et lancer toutes les suites), 5 sautées
          infra runner, 0 échec, bilan 82 suite(s) / 0 échec(s)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Les trois gardes répondent sur le dépôt réel / par fixture sans condition"
    requirement: PROT-05
    verification:
      - kind: other
        ref: "G1-REEL rc=0 CONFORME ; G2-REEL rc=0 chemins_surface=7 marqueurs_conformes=18 ;
          G3-FIXTURE bascules=4 ecarts=0 (mesure réelle inexerçable depuis une branche,
          conditionnelle main, nommée)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Recensement et contrôle de trace finaux verts, allowlist inchangée"
    requirement: PROT-04
    verification:
      - kind: unit
        ref: "check-aucune-fermeture.sh rc=0, 27 fichiers, allowlist 3 entrées/3 appliquées,
          0 candidat de co-occurrence réel ; check-trace-arbitrage.sh rc=0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Ledger PROT-01 à PROT-05 inscrit sur pièce, PROT-01 non coché et motivé, QUAL-01
      mis à jour avec le décompte mesuré"
    requirement: PROT-02
    verification:
      - kind: other
        ref: "verify automated Task 2 (deux blocs awk) — section=1 PROT01_non_coche=1
          PROT02345_coches=4 lignes_table=5 PROT01_hors_atteinte=1 QUAL01_phase41=2
          PROT05_origine=3 ; note_30IDs_intacte=1 note_PROT_ajoutee=1 BUDG_intacts=4 ;
          recensement=0 suite_survie_ledger=0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Constat d'inatteignabilité : PROT-01 et les critères 1, 2, 3 du ROADMAP hors
      d'atteinte sans accès admin"
    verification:
      - kind: other
        ref: "verify automated Task 3 — cles_constat=9 (attendu 8, écart documenté § Zones
          grises), criteres_inatteignables=3"
        status: pass
    human_judgment: true
status: complete
completed: 2026-09-18
---

# Phase VFDO-41 Plan 19: clôture du périmètre sans admin — ledger, rejeu final, constat Summary

**Clôt le périmètre sans admin de la Phase 41 par la preuve : rejeu complet des deux jobs CI sur
l'état final intégré, mesure réelle des trois gardes, recensement et contrôle de trace finaux,
inventaire des six SUMMARY, ledger `REQUIREMENTS.md` à jour (famille PROT en cinq entrées, QUAL-01
avec le décompte mesuré de mutants), et constat explicite de ce qui reste hors d'atteinte : PROT-01
et les critères de succès 1, 2 et 3 du ROADMAP. Aucune release, aucun bump, `ROADMAP.md` et
`STATE.md` non touchés.**

## Performance

- **Tâches :** 3/3 complétées
- **Fichiers modifiés :** 2 (`41-PREUVES.md`, `REQUIREMENTS.md`) + 1 créé (ce SUMMARY)
- **Commits :** 3

## Les quatre livrables du périmètre arbitré

| Garde | Artefact | Étape CI | Mutants tués | Bornes nommées |
|---|---|---|---|---|
| G-1 | `scripts/check-baseline-arbitrage.sh` | `check-baseline-arbitrage (G-1, PROT-04 — hausse de baseline sans arbitrage cité)` | 9 | seule la colonne des instructions bloque ; retrait de ligne en trois cas |
| G-2 | `scripts/check-gate-touche.sh` | `check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge)` | 6 | portée branche ; motif à virgule refusé (MUT-6, correction post-41-18) |
| G-3 | `scripts/check-push-sans-pr.sh` | `check-push-sans-pr` (deux étapes : fixture sans condition + mesure réelle conditionnelle `main`) | 5 | alarme après coup, jamais un verrou ; cascade `merge_commit_sha` pour les merges par rebase |
| G-4 | doctrine (`docs/ADR.md` ADR-072, `CLAUDE.md`, `.planning/BACKLOG.md`, `25-SECURITY.md`) | — (aucun script, aucune étape CI) | — | O-3 « signalée et tracée » ; amendement d'ADR-059 hors périmètre |

Plus les deux outils de phase, hors surface CI : `tools/check-aucune-fermeture.sh` (3 mutants
tués) et `tools/check-trace-arbitrage.sh` (6 mutants tués). **Total mesuré : 29 mutants tués**,
chacun crédité par la ligne canonique `✓ MUT-<n> TUE : rc_mutant=… attendu …, rc_original=…
attendu …`, rejoué rc=0 sur les cinq suites au moment de ce plan.

## La limite de fond, en toutes lettres

Une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle juge. Une même PR peut changer
le gate, sa suite et l'étape CI qui l'invoque, et rester verte — aucune règle côté serveur, sur ce
dépôt, ne l'en empêche (aucun accès admin, mesuré le 2026-09-17). Cette phase ne clôt rien : elle
rend visible et trace une atteinte, elle ne verrouille rien.

## Constat d'inatteignabilité

- **PROT-01** (rulesets de branche et de tag posés et prouvés par un refus réel) reste **NON
  COCHÉ** : hors d'atteinte sans accès admin — mesure `admin: false, maintain: false, push: true`
  sur le dépôt, 2026-09-17, deux lectures indépendantes ; le compte `picmakpro`, seul admin,
  appartient à un tiers. Déclencheur de reprise : un accès admin accordé, ou un transfert du
  dépôt. Renvoi : `BACKLOG.md` § « Protection de `main` côté GitHub — DIFFÉRÉ » et
  `41-CONTEXT.md` § Prémisse renversée.
- Les **critères de succès 1, 2 et 3 du ROADMAP** ne sont pas atteints et ne peuvent pas l'être
  sans accès admin, avec leur raison propre (clés `CRITERE-1-ROADMAP`/`CRITERE-2-ROADMAP`/
  `CRITERE-3-ROADMAP`, `41-PREUVES.md` § 41-19) : le critère 1 exige un ruleset actif sur `main`,
  le critère 2 le refus réel d'un merge (donc une règle côté serveur), le critère 3 le rejeu du
  flux de release SOUS la règle — la règle n'existe pas. Ce plan ne réécrit aucun des trois ; le
  `ROADMAP.md` n'est touché par aucun plan de la Phase 41.

## Statut d'O-3

**Signalée et tracée** : l'observation O-3 du `25-SECURITY.md` (une hausse de baseline du budget
d'instructions n'était gardée que par la relecture) est désormais signalée par G-1 et tracée par
G-2, sans règle côté serveur pour l'imposer — elle ne peut pas être davantage sans l'accès admin
qui manque à PROT-01. Objet distinct de la clôture des exigences PROT : aucune ligne de clôture
d'exigence, dans le ledger ou ici, n'associe O-3 à un mot d'achèvement.

## QUAL-01

Trois gates neufs (G-1, G-2, G-3), chacun avec ses trois issues (PASS / FAIL / imparsable
BRUYANT), mutants tués mesurés : G-1 neuf, G-2 six, G-3 cinq — vingt sur les trois gardes CI.
Plus les deux outils de phase (recensement trois, contrôle de trace six) — total mesuré
vingt-neuf. La trace du rouge (assertion, attendu, obtenu) est référencée dans les SUMMARY de
plan 41-14/41-16/41-17/41-15 ; aucun mutant tué par un plantage ou une plage vide n'est compté ici
(seule la ligne canonique `✓ MUT-<n> TUE` crédite).

## Absence de bump de module

Aucun bump n'est dû : les trois gardes et les deux outils de phase vivent sous `scripts/` et
`.planning/phases/.../tools/`, l'outillage du dépôt et non un module distribué (précédent écrit
dans l'en-tête de `scripts/tests/test-hook-exit-parc.sh`). Vérifié par machine : `rtk proxy git
diff --name-only main...HEAD -- plugin/` rend 0 ligne — aucun fichier sous `plugin/` n'est touché
par la branche. `VERSION` racine intacte à `v2.63.2`. La trace de version, s'il devait y en avoir
une, passerait par la section `## Non releasé` du `CHANGELOG.md` racine.

## Task Commits

1. **Task 1 : rejeu final, recensements, inventaire des SUMMARY** — `ed5f186` (docs)
2. **Task 2 : ledger REQUIREMENTS — famille PROT, PROT-01 hors d'atteinte, QUAL-01** — `42828a1` (docs)
3. **Task 3 : constat d'inatteignabilité, reliquats nommés, ce SUMMARY** — `f1efc4c` (docs, registre
   et SUMMARY dans le même commit)

_Base (`plan_head_before`) : `832b310` (dernier commit avant ce plan, correction ciblée
post-revue). `commits` mesuré (`git rev-list --count 832b310..HEAD`) : 3._

## Files Modified

- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` — section `## 41-19`
  (9 clés de mesure + 8 clés de constat)
- `.planning/REQUIREMENTS.md` — sous-section PROT (5 entrées), table de traçabilité (5 lignes),
  QUAL-01 (liste + table), note de décompte datée
- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-19-SUMMARY.md` — ce fichier

## Decisions Made

Aucune décision de fond nouvelle : ce plan documente et clôt l'état déjà arbitré par le manager le
2026-09-17 (périmètre sans admin option (a), bornes de G-1, création de PROT-05, reformulation de
son énoncé). Voir `key-decisions` en frontmatter.

## Deviations from Plan

Aucune déviation de fond. Deux écarts mécaniques de vérification, documentés ci-dessous plutôt que
contournés (aucun outil de recensement, allowlist, ou registre antérieur modifié).

## Zones grises (jugements explicites, non résolus en silence)

1. **Task 1, 4ᵉ bloc `<automated>` : le compte `hits` inclut à tort la ligne `limite: …`.** Le
   bloc de vérification embarqué dans ce plan exclut du décompte `h` uniquement les lignes
   `^perimetre: ` et `^allowlist: `, sans exclure `^limite: ` — à la différence du bloc analogue
   du plan 41-15 (`!/^perimetre: |^allowlist: |^limite: /`, `41-15-PLAN.md` ligne 208), qui exclut
   les trois. Rejoué tel quel sur l'état final, ce bloc de 41-19 compte `h=1` en comptant la ligne
   `limite: exiges=10 porteurs=10 manquants=aucun` (imprimée systématiquement par
   `check-aucune-fermeture.sh` depuis l'ajout de sa sonde de limite de fond, plan 41-15,
   avertissement 7) — aucune ligne au format `chemin:ligne:contenu` n'est présente, donc zéro
   co-occurrence réelle. La clé `RECENSEMENT-FINAL: rc=0 fichiers=27 hits=0 allowlist_entrees=3`
   écrite dans `41-PREUVES.md` porte la valeur RÉELLE (0), documentée avec preuve brute juste
   au-dessus. Ni l'outil ni son allowlist n'ont été modifiés (interdit par la discipline de ce
   plan) — je n'ai pas non plus retouché le texte `<verify>` du plan lui-même (hors de mon mandat
   d'exécution). À classer par le manager : correction suggérée, aligner le bloc de 41-19 sur le
   patron déjà correct de 41-15.
2. **Task 3, 1er bloc `<automated>` : le compte `cles_constat` rend 9 au lieu de 8, car la clé
   `LIMITE-DE-FOND:` existe déjà une fois dans `§ 41-15`** (`LIMITE-DE-FOND: exiges=7 porteurs=4
   manquants=aucun`, mesure historique de l'état du dépôt au moment de 41-15, volontairement non
   réécrite — même règle d'immutabilité que `BASE-TRACE-ARBITRAGE`). Le texte de la Task 3 de ce
   plan demande explicitement une seconde ligne `LIMITE-DE-FOND: exiges=<n> porteurs=<n>
   manquants=<…>` dans `§ 41-19`, portant la mesure COURANTE (`exiges=10 porteurs=10
   manquants=aucun`, différente de la mesure historique de 41-15 puisque le périmètre de porteurs
   a grandi entre-temps — cinq SUMMARY de plan supplémentaires). La collision de nom entre les deux
   sections n'est pas scopée par le bloc `<automated>`, qui compte sur tout le fichier. Les HUIT
   TYPES de clé de constat sont bien tous présents et mesurés dans `§ 41-19` (aucun contenu
   manquant) ; l'écart est purement un artefact de comptage global sur un nom de clé réutilisé
   entre deux sections d'un même registre append-only. Remonté au manager plutôt que résolu en
   silence : reprendre soit la valeur historique de 41-15 (fausse pour l'état final, à exclure),
   soit renommer la clé de 41-19 (`LIMITE-DE-FOND-FINALE` par exemple, cohérent avec
   `RECENSEMENT-FERMETURE`→`RECENSEMENT-FINAL` et `TRACE-ARBITRAGE`→`TRACE-FINALE`, déjà
   différenciés ailleurs dans ce même plan).

## Issues Encountered

Aucune non documentée ci-dessus.

## User Setup Required

None.

## Reliquats nommés — traités par le manager, hors du périmètre de cette phase (décision du 2026-09-17)

- **`.planning/ROADMAP.md`** : réécriture des critères de succès 1, 2 et 3 sur le périmètre
  arbitré (sans admin) — aucun plan de la Phase 41 ne l'a touché, y compris celui-ci.
- **`.planning/STATE.md`** : mise à jour de l'état de phase — même règle, non touché.
- **La PR de la Phase 41 et son merge** — geste humain (ADR-031).
- **La décision de release ou non** — geste humain, `VERSION` intentionnellement intacte à
  `v2.63.2` dans ce plan.

## Périmètre non rejoué, nommé (recopié de `41-PREUVES.md` § 41-19)

Job `tests` : étapes `Dépendances (bash, jq, python3)`, `actions/setup-node` (action, nom vide en
sortie de l'outil de rejeu), `Installer le moteur GSD (@opengsd/gsd-core@^1)`, `Canari de forme du
moteur GSD (lecture de texte — check-gsd-config.sh)` — toutes SAUTEE (installation/infra du
runner), 5 sautee(s) au bilan, 1 seule étape (« Découvrir et lancer toutes les suites ») rejouée.
Jobs `lab-frais` et `lab-frais-arme` : non sélectionnés par `--job tests`/`--job gates`. Étape
`check-release-tag` : conditionnelle `main`, SAUTEE. Étape de mesure réelle de G-3
(`check-push-sans-pr (G-3, PROT-05 — mesure réelle sur un push vers main)`) : conditionnelle
`main`, SAUTEE — son étape de fixture sans condition, elle, est rejouée et verte
(`G3-FIXTURE: bascules=4 ecarts=0`). Job `gates` : 1 étape action sautée en tête (checkout, nom
vide en sortie de l'outil), 3 sautee(s) au bilan au total.

## Next Phase Readiness

- Le périmètre sans admin de la Phase 41 est clos par la preuve : rejeu final vert, ledger sur
  pièce, constat d'inatteignabilité explicite pour PROT-01 et les critères 1-3 du ROADMAP.
- Deux écarts mécaniques de vérification (§ Zones grises) remontés au manager, sans impact sur la
  réalité de l'état livré (mesurée directement, preuve brute jointe).
- Reliquats nommés ci-dessus, tous des gestes hors du périmètre de cette phase.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 19*
*Completed: 2026-09-18*

## Self-Check: PASSED

Fichiers vérifiés modifiés : `41-PREUVES.md`, `REQUIREMENTS.md`. Commits vérifiés présents dans
l'historique : `ed5f186`, `42828a1`, `f1efc4c` (ce dernier ajoute aussi ce SUMMARY lui-même — sha
antérieur à l'amendement de cette phrase, non recalculé après coup, cf. la même remarque pour
`BASE-TRACE-ARBITRAGE` en `41-PREUVES.md` § 41-14).

Cette garde peut être modifiée par la PR qu'elle juge.
