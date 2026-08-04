---
phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-
plan: 08
subsystem: infra
tags: [governance, version-sync, changelog, requirements-ledger, release-discipline]

requires:
  - phase: 23-01 à 23-07
    provides: contrat de checkpoint, doctrine de flags de cycle, table de capabilities générée, voie unique, doctrine des doublons d'étage, check-gsd-config.sh, briques dormantes + budget partagé
provides:
  - dev-orchestrator v2.11.0 (triade + CHANGELOG écrit depuis les 7 SUMMARY)
  - compteur de suites des deux README racine remis d'équerre (46 → 47)
  - ledger .planning/REQUIREMENTS.md : GSDC-01..10 statués (9 Done, 1 Partiel)
  - tous les gates de sortie de la phase rejoués et consignés
affects: [release racine (geste humain restant), phases futures qui liront ce ledger]

actuals:
  tokens: 4137
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Compteur de suites gaté sur la seule mention vivante par README, relevé complet par awk plutôt que par le seul gate (angle mort de check-version-sync.sh : il ne lit que la 1re occurrence)"
    - "Ledger d'exigences : statut partiel `[~]` avec raison entre parenthèses, patron VERB-02 réutilisé pour GSDC-08"
    - "rc de suite capturé hors tube (jamais `| tail`), check-agents.sh en forme collée `--agents-dir=`, densité en forme argument `wc -l fichier` jamais `wc -l < fichier`"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/README.md
    - plugin/dev-orchestrator/CHANGELOG.md
    - README.md
    - README.fr.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "GSDC-08 reçoit [~] (couverture partielle) et non [x] : le basculer en Done aurait certifié D-22 conforme, ce qu'il n'est pas — gsd-debugger reste dans l'allowlist de vf-coder.md"
  - "Compteur de suites édité uniquement sur la puce Auditable (mention vivante) de chaque README, jamais sur les 3 lignes datées de l'historique de release par fichier"
  - "Aucun geste de release racine entamé : VERSION racine, plugin.json, marketplace.json, badges et historiques de README non touchés, aucun tag créé"

patterns-established:
  - "Rejeu de gate = exécution réelle avec rc capturé hors tube, jamais une relecture supposée verte du plan précédent"

requirements-completed: [GSDC-10]

coverage: []

duration: 7min
completed: 2026-08-04
status: complete
---

# Phase 23 Plan 08: Clôture de gouvernance — version du module, ledger d'exigences, rejeu des gates Summary

**`dev-orchestrator` bumpé v2.10.0 → v2.11.0 avec CHANGELOG écrit depuis les 7 SUMMARY, compteur de
suites des deux README racine remis d'équerre (46 → 47) sur la seule mention vivante, ledger
`GSDC-01..10` statué (9 Done, `GSDC-08` en couverture partielle explicite), et tous les gates de
sortie rejoués et consignés — la release racine n'a pas été entamée.**

## 🔲 Pour Samuel — gestes de release racine restant à faire à la main

Aucun de ces gestes n'a été entamé par ce plan (hors périmètre, T-23-08-01) :

- [ ] Bump de la triade racine : `VERSION`, `plugin/.claude-plugin/plugin.json`,
      `.claude-plugin/marketplace.json`
- [ ] Bump des deux badges de version des README (`README.md`, `README.fr.md`)
- [ ] Nouvelle entrée dans les deux tableaux d'historique de release (README.md, README.fr.md)
- [ ] `git tag -a vX.Y.Z -m "..."` puis `git push origin vX.Y.Z`
- [ ] `gh release create vX.Y.Z ...`
- [ ] `bash scripts/check-release-tag.sh --remote` → doit sortir ✓

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-04T05:30:36Z
- **Tasks:** 2/2
- **Files modified:** 7

## Table des gates — rejoués, étiquetés livraison / non-régression

Le seul gate rouge avant ce plan était `check-version-sync.sh` (rc=1, deux `ko` : compteur de
suites `46 ≠ 47` sur les deux README). Les neuf autres étaient déjà verts avant ce plan — leur rejeu
prouve l'absence de dégât, pas un travail livré.

| Gate | Étiquette | Commande | rc avant | rc après |
|------|-----------|----------|----------|----------|
| `check-version-sync.sh` | **livraison** | `bash scripts/check-version-sync.sh` | 1 (ko sur les 2 README) | **0** |
| Triade `dev-orchestrator` (VERSION/module.json/README) | **livraison** | lecture directe des 3 fichiers | v2.10.0 partout | v2.11.0 partout |
| CHANGELOG en tête | **livraison** | `awk 'FNR<=3 && /v2\.11\.0/'` | absent | **présent, rc=0** |
| Ledger `GSDC-01..10` (10 puces) | **livraison** | `awk '/^- \[ \] \*\*GSDC-/{n++} END{if(n!=0) exit 1}'` | 10 puces vides | **0 puce vide, rc=0** |
| Traçabilité `GSDC-08/09/10` | **livraison** | `awk '/^\| GSDC-(08\|09\|10) \|/ && /Planned/{exit 1}'` | 3 en `Planned` | **0 en Planned, rc=0** |
| `test-dev-orchestrator.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (161 OK/0 KO/0 SKIP) |
| `test-check-gsd-config.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (37 ok/0 ko) |
| `test-check-doc-drift.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (21 ok/0 ko) |
| `test-check-dev-bootstrap.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (23 ok/0 ko) |
| `test-check-gsd-engine.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (15 ok/0 ko) |
| `test-discover-unintegrated-docs.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (22 ok/0 ko) |
| `test-inject-mcp-tools.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** (26 OK/0 KO) |
| `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict` (forme collée) | non-régression (vert d'avance) | rc hors tube | 0, 7 warnings | **0, 7 warnings** |
| `check-state-integrity.sh` | non-régression (vert d'avance) | rc hors tube | 0 | **0** |
| `check-gsd-config.sh --path .` | non-régression (vert d'avance) | rc hors tube | 3 (silence, aligné) | **3** (silence, aligné) |
| Densité ADR-029 `vf-dev-manager.md` | non-régression (vert d'avance) | `wc -l` forme argument + `awk FNR` | 245/250 | **245/250** |
| Densité ADR-029 `vf-coder.md` | non-régression (vert d'avance) | `wc -l` forme argument + `awk FNR` | 96/250 | **96/250** |
| Garde non-entame release racine (diff 3 temps) | non-régression (vert d'avance) | fichier intermédiaire → non-vacuité → correspondance exacte | 49 chemins, 0 interdit | **55 chemins, 0 interdit** |
| Aucun tag créé | non-régression (vert d'avance) | `git tag --points-at HEAD` | 0 tag | **0 tag** |

## Valeur constatée du compteur de suites

**Deux méthodes croisées, écart nul, mesuré le 2026-08-04 :**

```
find plugin scripts -path '*/tests/test-*.sh' | awk 'END{print "find="NR}'       → find=47
rtk proxy git ls-files | awk '/\/tests\/test-.*\.sh$/{n++} END{print "ls-files="n+0}' → ls-files=47
```

**Décompte `vivantes / datées` par README, avant / après :**

| Fichier | Avant | Après |
|---------|-------|-------|
| `README.md` | `vivantes_47=0 datees_46=4` | `vivantes_47=1 datees_46=3` |
| `README.fr.md` | `vivantes_47=0 datees_46=4` | `vivantes_47=1 datees_46=3` |

Seule la puce « Auditable » (mention vivante) de chaque fichier a été éditée. Les 3 mentions datées
par fichier (`| v2.46.0 |`, `| v2.45.0 |`, `| v2.44.0 |`, forme `**46 suites**`) sont restées
intactes — ce sont des constats datés, les réécrire aurait falsifié l'historique de release.

## Liste exacte des dix identifiants d'exigence et leur statut réel

| ID | Statut | Plan(s) |
|----|--------|---------|
| GSDC-01 | Done | 23-01 |
| GSDC-02 | Done | 23-01 |
| GSDC-03 | Done | 23-03 |
| GSDC-04 | Done | 23-04 |
| GSDC-05 | Done | 23-05 |
| GSDC-06 | Done | 23-06 |
| GSDC-07 | Done | 23-02 |
| **GSDC-08** | **Partiel `[~]`** — volet dispatch couvert, volet allowlist ouvert sur `D-22`, non tranché | 23-07 |
| GSDC-09 | Done | 23-07 |
| GSDC-10 | Done | 23-08 (ce plan) |

`GSDC-08` est le seul identifiant qui ne se ferme pas franchement : le plan 23-07 a livré et gaté le
volet dispatch (`T32-D`, aucun agent nu de debug offert en dispatch direct), mais le volet allowlist
— `gsd-debugger` toujours présent en ligne `tools:` de `vf-coder.md` — reste ouvert sur l'écart
`D-22`. Le basculer en `Done` aurait certifié `D-22` conforme, ce qu'il n'est pas.

## 🛑 Arbitrages ouverts, reportés

**Écart `D-22` — `gsd-debugger` reste dans l'allowlist de `vf-coder.md`, ni retiré ni légitimé.**

Fait mesuré, inchangé depuis le début de ce plan : `plugin/dev-orchestrator/agents/vf-coder.md`,
ligne `tools:`, porte l'entrée `gsd-debugger` — seule occurrence de ce nom dans
`plugin/dev-orchestrator/agents/`. `D-22` (tranché par Samuel : « aucun `gsd-debugger` en
allowlist, aucune exception ») contredit frontalement cet existant.

Cette même entrée est **simultanément exigée** par le gate machine `CODER_ALLOWED`
(`test-dev-orchestrator.sh`, bloc `T19`) — `check_worker_allowlist` KO chaque nom **absent** de
l'allowlist de l'agent, donc la retirer ferait tomber la suite. L'arbitrage est binaire et
appartient à Samuel :
1. retirer l'entrée de `vf-coder.md` **et** le gate qui l'exige, ou
2. amender `D-22` pour y inscrire l'exception et son motif.

Sous ADR-031, cet exécuteur n'a pas mandat de choisir : l'écart est écrit ici et n'est pas tranché.
Voir aussi la section dédiée du SUMMARY de 23-07 (« 🛑 Écart D-22 — ÉCART OUVERT, remonté à
l'arbitrage humain »).

**Dette de clôture de la Phase 22 — signalée, non touchée.**

Les sept puces `DOCF-01..07` de `.planning/REQUIREMENTS.md` sont restées `- [ ]` et leur
traçabilité `Planned`, alors que la Phase 22 est close. C'est une dette de clôture antérieure,
**hors périmètre de ce plan** — elle n'a été ni cochée ni retouchée. Elle ne remet pas en cause la
convention du fichier (63 puces `[x]` mesurées avant ce plan, dont VERB-02 en `[~]` avec sa raison) :
la convention est de cocher ce qui est livré, la Phase 22 est simplement restée en souffrance sur ce
point précis.

Aucun autre arbitrage non tranché n'a été rencontré en exécution.

## Task Commits

1. **Tâche 1 : triade de version du module, CHANGELOG, et compteur de suites remis d'équerre** —
   `26c40d3` (feat)
2. **Tâche 2 : ledger d'exigences, traçabilité, et rejeu de tous les gates de sortie** — `ea1845c`
   (docs)

## Files Created/Modified

- `plugin/dev-orchestrator/VERSION` — v2.10.0 → v2.11.0
- `plugin/dev-orchestrator/module.json` — champ `version` : 2.10.0 → 2.11.0
- `plugin/dev-orchestrator/README.md` — en-tête `**Version**` : v2.10.0 → v2.11.0
- `plugin/dev-orchestrator/CHANGELOG.md` — nouvelle entrée en tête (v2.11.0, 2026-08-04), écrite
  depuis les 7 SUMMARY : gate d'alignement de configuration, générateur de capabilities, doctrine
  de flags de cycle, doctrine de voie unique, table des briques dormantes, 4 champs optionnels du
  bloc typé, 10 blocs de test T24-T33 (+ 8 sous-blocs nommés) ; retrait `gsd-planner`/`gsd-executor`
  avec justification
- `README.md` / `README.fr.md` — puce « Auditable » : 46 → 47 suites (seule mention vivante éditée)
- `.planning/REQUIREMENTS.md` — 10 puces `GSDC-01..10` statuées (9 `[x]`, `GSDC-08` en `[~]`),
  traçabilité `GSDC-08/09/10` sortie de `Planned`

## Decisions Made

- `GSDC-08` reçoit `[~]` plutôt que `[x]` — un ledger qui coche par optimisme est pire qu'un ledger
  incomplet ; la couverture partielle est écrite avec sa raison plutôt que masquée.
- Le compteur de suites n'a été édité que sur la mention vivante (« Auditable ») de chaque README,
  jamais sur les lignes d'historique datées — patron du plan 21-05 (44 → 45).
- Aucun geste de release racine entamé, conformément au périmètre écrit dans le plan et vérifié
  machine (garde de diff en trois temps, aucun des trois fichiers de version racine touché, aucun
  tag créé).

## Deviations from Plan

Aucune — plan exécuté tel qu'écrit, y compris ses garde-fous de mesure (rc hors tube,
`check-agents.sh` en forme collée, densité en forme argument, garde de diff en trois temps avec
non-vacuité prouvée avant correspondance).

## Issues Encountered

Aucun. La commande `cat`/`head` via bash a semblé tronquer certains fichiers courts sur ce poste
(`module.json`, `CHANGELOG.md`) au premier essai — contournement immédiat par l'outil `Read`, qui a
rendu le contenu intégral et correct pour toutes les lectures suivantes. N'a affecté aucune écriture
ni aucun verdict.

## Next Phase Readiness

- La Phase 23 est close côté gouvernance de phase : les dix `GSDC-01..10` sont statués, le module
  porte sa version mineure suivante, tous les gates sont verts et rejoués.
- **Bloquant pour la clôture complète (hors périmètre GSD) : les six gestes de release racine
  listés en tête de ce SUMMARY restent à la main de Samuel.**
- L'écart `D-22` reste ouvert et devra être arbitré avant qu'aucun futur SUMMARY ne puisse affirmer
  une conformité totale à `D-22`.
- La dette de clôture Phase 22 (`DOCF-01..07`) reste en souffrance, à solder par ailleurs.

---
*Phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-*
*Completed: 2026-08-04*

## Self-Check: PASSED

- FOUND: `plugin/dev-orchestrator/VERSION`
- FOUND: `plugin/dev-orchestrator/module.json`
- FOUND: `plugin/dev-orchestrator/README.md`
- FOUND: `plugin/dev-orchestrator/CHANGELOG.md`
- FOUND: `README.md`
- FOUND: `README.fr.md`
- FOUND: `.planning/REQUIREMENTS.md`
- FOUND: commit `26c40d3`
- FOUND: commit `ea1845c`
