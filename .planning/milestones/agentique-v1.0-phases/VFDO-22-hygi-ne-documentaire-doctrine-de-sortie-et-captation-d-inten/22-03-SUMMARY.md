---
phase: 22-hygiene-documentaire
plan: 03
subsystem: doctrine
tags: [dev-orchestrator, design-orchestrator, release, check-version-sync, adr-057]

requires:
  - phase: 22-hygiene-documentaire (plan 01)
    provides: "docs-flow.md — la doctrine de sortie documentaire dont le CHANGELOG de ce plan rend compte"
  - phase: 22-hygiene-documentaire (plan 02)
    provides: "le câblage des deux managers (nœud docs agrégé) dont le CHANGELOG de ce plan rend compte"
provides:
  - "dev-orchestrator v2.9.0 — triade + CHANGELOG + README à jour (docs-flow.md, T22/T23, §Références)"
  - "design-orchestrator v1.4.0 — triade + CHANGELOG à jour (renvoi cross-module vers docs-flow.md)"
  - "check-version-sync.sh vert sur les 17 modules, compteur « N suites » racine inchangé (44)"
affects: ["release racine (VERSION, plugin.json, marketplace.json, README, README.fr — hors périmètre, voir ci-dessous)"]

actuals:
  tokens: 2800
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Triade de version par module en 2 formats non interchangeables : VERSION et en-tête README portent le préfixe v, module.json ne le porte jamais — c'est précisément ce que check-version-sync.sh vérifie triade par triade."

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/README.md
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/design-orchestrator/VERSION
    - plugin/design-orchestrator/module.json
    - plugin/design-orchestrator/README.md
    - plugin/design-orchestrator/CHANGELOG.md

key-decisions:
  - "Bump minor pour les deux modules (nouvelle capacité, pas un correctif) — règle de numérotation du CLAUDE.md racine."
  - "Aucune suite de test nouvelle créée : le compteur « N suites » des deux README racine reste à 44, T22/T23 étendent la suite existante de dev-orchestrator (patron D-14)."
  - "Release racine explicitement HORS périmètre — aucun des cinq fichiers de release racine touché (vérifié par `git diff --name-only` après chaque tâche ET en fin de plan)."

patterns-established:
  - "Le CHANGELOG d'un module cite explicitement ses non-modifications volontaires (check-doc-drift.sh côté dev, gate DESIGN.md + frontmatter côté design) — un lecteur du journal doit pouvoir le savoir sans lire le diff (patron déjà établi en 22-01/22-02)."

requirements-completed: [DOCF-07]

coverage:
  - id: D1
    description: "dev-orchestrator porte v2.9.0 dans ses trois emplacements (VERSION, module.json, en-tête README), avec les deux formats respectés"
    requirement: "DOCF-07"
    verification:
      - kind: unit
        ref: "scripts/check-version-sync.sh — triade par module + en-tête README des modules"
        status: pass
    human_judgment: false
  - id: D2
    description: "design-orchestrator porte v1.4.0 dans ses trois emplacements, ligne composite du README préservée (Type et Dépend de intouchés)"
    requirement: "DOCF-07"
    verification:
      - kind: unit
        ref: "scripts/check-version-sync.sh — triade par module + en-tête README des modules"
        status: pass
    human_judgment: false
  - id: D3
    description: "Les deux CHANGELOG décrivent la capacité livrée et les non-modifications volontaires"
    requirement: "DOCF-07"
    verification:
      - kind: manual
        ref: "grep ciblé sur la section de tête de chaque CHANGELOG (docs-flow.md, check-doc-drift.sh, DESIGN.md, frontmatter)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Aucun fichier de release racine n'a été modifié"
    requirement: "DOCF-07"
    verification:
      - kind: unit
        ref: "git diff --name-only HEAD~2 -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json README.md README.fr.md (vide)"
        status: pass
    human_judgment: false
  - id: D5
    description: "check-version-sync.sh et les deux suites de tests des modules restent vertes après le bump"
    requirement: "DOCF-07"
    verification:
      - kind: unit
        ref: "check-version-sync.sh (exit 0), test-dev-orchestrator.sh (77 OK / 0 KO), test-design-orchestrator.sh (12 OK / 0 KO)"
        status: pass
    human_judgment: false

duration: ~20min
completed: 2026-07-31
status: complete
---

# Phase 22 — Plan 03 Summary

**Les deux modules qui portent la doctrine de sortie documentaire de la Phase 22 sont désormais distribuables : `dev-orchestrator` v2.9.0, `design-orchestrator` v1.4.0, gate de synchronisation vert.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2 / 2
- **Files modified:** 8 (4 par module × 2 modules)

## Accomplishments

- **`dev-orchestrator` v2.8.0 → v2.9.0** — triade alignée (`VERSION`, `module.json`, en-tête
  README), CHANGELOG en tête décrivant `docs-flow.md`, les trois régimes de confirmation, la
  captation d'intention auditer/générer/régénérer, le nœud `docs` agrégé, et la non-modification
  volontaire de `check-doc-drift.sh` (D-13). README complété sur ses trois points : `docs-flow.md`
  dans l'arborescence `references/`, axes **T22**/**T23** dans la liste des tests, ligne de
  doctrine en §Références.
- **`design-orchestrator` v1.3.2 → v1.4.0** — triade alignée, y compris la ligne composite du
  README (`**Type**` et `**Dépend de**` préservés autour du seul segment `**Version**` modifié).
  CHANGELOG décrivant le renvoi cross-module vers `dev-orchestrator-references/docs-flow.md`
  (ADR-057, aucune copie locale) et les deux non-changements du plan : gate `DESIGN.md` distinct
  et inchangé, frontmatter de l'agent inchangé (`Skill` y était déjà).
- **`check-version-sync.sh` vert** sur les 17 modules, triades alignées, en-têtes README des
  modules alignés, compteur « N suites » des deux README racine toujours à **44** (aucune suite
  nouvelle créée par ce plan).
- **Les deux suites de tests des modules passent** : `test-dev-orchestrator.sh` 77 OK / 0 KO,
  `test-design-orchestrator.sh` 12 OK / 0 KO — non-régression confirmée après le bump.

## Task Commits

1. **Tâche 1 : triade + CHANGELOG de `dev-orchestrator`** — `5732e9c` (chore)
2. **Tâche 2 : triade + CHANGELOG de `design-orchestrator`** — `cb10306` (chore)

## Files Created/Modified

- `plugin/dev-orchestrator/VERSION` — `v2.8.0` → `v2.9.0`
- `plugin/dev-orchestrator/module.json` — `2.8.0` → `2.9.0`
- `plugin/dev-orchestrator/README.md` — en-tête version, arborescence `references/`, axes T22/T23, §Références
- `plugin/dev-orchestrator/CHANGELOG.md` — section `[v2.9.0]` en tête
- `plugin/design-orchestrator/VERSION` — `v1.3.2` → `v1.4.0`
- `plugin/design-orchestrator/module.json` — `1.3.2` → `1.4.0`
- `plugin/design-orchestrator/README.md` — segment version de la ligne composite (ligne 7)
- `plugin/design-orchestrator/CHANGELOG.md` — section `[v1.4.0]` en tête

## Decisions Made

- **Bump minor pour les deux modules** — les deux plans amont (22-01, 22-02) livrent une capacité
  nouvelle (doctrine de sortie documentaire + captation d'intention + câblage des deux managers),
  pas un correctif. Numérotation conforme au `CLAUDE.md` racine.
- **Aucune suite de test nouvelle.** Le compteur « N suites » des deux README racine (44) ne
  bouge pas — les axes T22/T23 étendent la suite existante `test-dev-orchestrator.sh` (patron
  D-14 déjà établi en 22-01/22-02).
- **Release racine strictement hors périmètre** — voir section dédiée ci-dessous.

## Deviations from Plan

Aucune déviation de contenu — le plan a été exécuté comme écrit, tâche par tâche, avec les
`<verify>` et critères d'acceptation de chaque tâche confirmés avant chaque commit.

**Une correction factuelle au constat du plan, à signaler explicitement** : le plan (§Frontière
de release) et la passation du plan 22-02 affirmaient que « l'arbre porte un `VERSION` racine à
`v2.44.0` **non taggé** hérité de la Phase 20 ». Vérification faite pendant ce plan
(`bash scripts/check-release-tag.sh --remote`) : **ce constat est aujourd'hui périmé**. Le tag
annoté `v2.44.0` existe, pointe sur le commit de merge `d549b2d` (PR #21), est **poussé sur
origin**, et une **release GitHub `v2.44.0`** existe déjà (« La revue devient un étage de premier
rang (ADR-060) »). `check-release-tag.sh --remote` sort en exit 0. La release `v2.44.0` de la
Phase 20 a donc été finalisée par un humain entre la rédaction du plan 22-03 et son exécution —
elle n'est plus « en attente », elle est close. Ce qui **reste** vrai et reste hors périmètre de
ce plan : les 17 commits qui ont atterri sur `v2.44.0` depuis ce tag — dont les huit fichiers de
ce plan — n'ont **pas** été portés dans une nouvelle release racine. Voir « Reste à faire »
ci-dessous, corrigé en conséquence.

## Verification Gates — résultats

| Gate | Commande | Résultat |
|---|---|---|
| Synchronisation de version | `bash scripts/check-version-sync.sh` | ✓ exit 0 — 17 modules, triades alignées, compteur suites 44 |
| Suite `dev-orchestrator` | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✓ exit 0 — 77 OK / 0 KO / 0 SKIP |
| Suite `design-orchestrator` | `bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` | ✓ exit 0 — 12 OK / 0 KO / 0 SKIP |
| Frontière release (5 fichiers racine) | `git diff --name-only HEAD~2 -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json README.md README.fr.md` | ✓ vide — aucun fichier racine touché |
| Discipline de tag (informatif, hors critère de ce plan) | `bash scripts/check-release-tag.sh --remote` | ✓ exit 0 — `v2.44.0` taggé, poussé, release GitHub publiée (voir Deviations) |

## Reste à faire — release racine

Ce plan n'a délibérément touché à **aucun** des cinq fichiers de release racine, patron déjà
appliqué aux Phases 13, 17 et 19 (« réservée à validation humaine — non faite en mission ») :

1. **`VERSION`** (racine) — porte actuellement `v2.44.0`.
2. **`plugin/.claude-plugin/plugin.json`** — champ `version`, non touché.
3. **`.claude-plugin/marketplace.json`** — fiche d'install, non touchée.
4. **`README.md`** — badge de version, compteur de modules, historique des dernières entrées, non touchés.
5. **`README.fr.md`** — idem, non touché.

**État réel constaté pendant ce plan (corrige le constat du plan et de la passation 22-02)** :
`VERSION` racine porte `v2.44.0`, et ce tag **est déjà annoté, poussé sur `origin`, et publié en
release GitHub** (`gh release view v2.44.0` — « La revue devient un étage de premier rang
(ADR-060) »). Il n'y a donc **pas** de rattrapage de tag/release à faire pour `v2.44.0` lui-même.

**Ce qui reste réellement à faire, réservé à validation humaine** : la Phase 22 (doctrine de
sortie documentaire + captation d'intention, plans 22-01/22-02/22-03, ce plan inclus) vit dans des
commits **postérieurs** au tag `v2.44.0` — aucune nouvelle release racine n'a encore été coupée
pour l'inclure. Reste à faire, après merge sur `main` et validation humaine :

- Bumper `VERSION` racine (minor probable — nouvelle doctrine documentaire, à trancher par
  l'humain au moment de la release), `plugin/.claude-plugin/plugin.json`, et
  `.claude-plugin/marketplace.json` sur la même valeur.
- Rafraîchir l'historique des deux README racine (`README.md`, `README.fr.md`), badges inclus.
- Créer et pousser le tag annoté correspondant : `git tag -a vX.Y.Z -m "vX.Y.Z — <résumé>" <commit>
  && git push origin vX.Y.Z`.
- Créer la release GitHub sur ce tag (`gh release create vX.Y.Z ...`).
- Vérifier avec `bash scripts/check-release-tag.sh --remote` → doit sortir `✓`.

## User Setup Required

Aucune — aucun service externe, aucune dépendance nouvelle.

## Next Phase Readiness

**La Phase 22 (hygiène documentaire) est complète côté modules** : les trois plans (22-01, 22-02,
22-03) sont exécutés et vérifiés, SUMMARY sur disque pour les trois. `dev-orchestrator` v2.9.0 et
`design-orchestrator` v1.4.0 sont prêts à être distribués dès la prochaine release racine.

**Ce que le prochain intervenant doit savoir** :
- la release racine reste entièrement à faire (voir section ci-dessus) — décision humaine sur le
  numéro de version et le moment de la coupe ;
- `.planning/STATE.md` et `.planning/ROADMAP.md` n'ont **pas** été touchés par ce plan (consigne
  explicite de mission — propriété d'une autre session à ce moment) ; leur mise à jour (position,
  progression, `DOCF-07` côché) reste à faire par le propriétaire de ces fichiers ;
- aucun `gsd-tools state ...` n'a été invoqué pendant ce plan, sur consigne explicite (frontmatter
  `STATE.md` connu comme corrompu par un incident antérieur, non traité par cette phase).

---
*Phase: 22-hygiene-documentaire, plan 03*
*Completed: 2026-07-31*
