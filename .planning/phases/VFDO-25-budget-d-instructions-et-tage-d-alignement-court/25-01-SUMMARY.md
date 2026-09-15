---
phase: 25-budget-d-instructions-et-tage-d-alignement-court
plan: 01
subsystem: infra
tags: [bash, gate, ci, awk, ratchet]

requires: []
provides:
  - "plugin/conductor/scripts/check-instruction-budget.sh — gate machine mesurant deux métriques
    (lignes, instructions) par fichier d'agent distribué, comparées à une baseline en ratchet"
affects: [25-02, 25-03, 25-04]

actuals:
  tokens: 3435
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Sentinelle versionnée lue jamais écrite (ratchet BUDG-02), patron check-requirements-survival.sh"
    - "Codes de sortie tous énumérés en en-tête, aucun implicite, patron check-divergence.sh"
    - "Comptage de lignes robuste sans newline final (awk END{print NR}, jamais wc -l)"

key-files:
  created:
    - plugin/conductor/scripts/check-instruction-budget.sh
  modified:
    - "plugin/conductor/scripts/check-instruction-budget.sh — correction ciblée post-revue (F1/F2/F3,
      commit cca219b)"

key-decisions:
  - "D-01 bis appliqué : le comptage d'instructions porte sur le BODY seul (frontmatter exclu par
    awk à deux délimiteurs), jamais sur le fichier entier — écarte le chiffre 463 du cadrage."
  - "Marqueurs D-01 non scopés (s'appliquent à toute ligne de body), puce impérative scopée au
    titre de règles ouvert (D-01, Claude's Discretion, forme mesurée), dédoublonnage en union."
  - "Plafond ADR-029 (250 lignes) armé par la même sentinelle que la baseline et prime sur elle :
    une baseline > 250 ne légalise jamais un dépassement par simple mesure (D-05)."
  - "Aucune baseline ni sentinelle gravée dans ce plan (D-06 bis) — le gate tourne en avertissement
    (exit 3) sur le dépôt réel, sentinelle absente, sans rien écrire."

patterns-established:
  - "Isolation du body hors frontmatter par awk à deux délimiteurs '---', réutilisable pour tout
    futur gate qui doit ignorer le frontmatter YAML d'un fichier markdown."

requirements-completed: [BUDG-01, BUDG-02]

duration: n/a
completed: 2026-09-15
status: complete
---

# Phase 25 — Plan 01 : gate check-instruction-budget.sh

**Le gate mesure et publie deux métriques (lignes, instructions) pour les 31 fichiers d'agents
distribués, sort en avertissement (3) sur le dépôt réel sans rien écrire, et les cinq codes de
sortie sont chacun atteints sur fixture jetable.**

## Accomplissements

- Découverte à un seul niveau (`plugin/*/agents/*.md` + `plugin/*/AGENT.md`, D-03) : 31 fichiers
  sur le dépôt réel, zéro fichier → `exit 2` (non vérifiable, jamais un vert par absence).
- Deux métriques par fichier (D-05) : lignes du fichier entier (`awk 'END{print NR}'`, jamais
  `wc -l`) et instructions du body (D-01, body-only, marqueurs textuels + forme puce sous titre de
  règles, dédoublonnée en union).
- Ratchet lu, jamais écrit (D-04) : sentinelle `.planning/.instruction-budget-armed` et baseline
  `.planning/instruction-budget-baselines.tsv` lues seulement ; aucune des deux n'existe après
  exécution.
- Plafond ADR-029 (250 lignes) armé par la même sentinelle, prime sur toute baseline
  (`DEPASSEMENT-ADR029`).
- Cinq codes de sortie tous énumérés (`0`/`1`/`2`/`3`/`64`), chacun atteint par une fixture
  jetable dans `/tmp` (jamais dans le dépôt réel).

## Vérifications rejouées après le commit `ab5af42`

- `bash -n plugin/conductor/scripts/check-instruction-budget.sh` → exit 0.
- Tâche 1 (tranche verticale, corpus réel, sentinelle absente) → `TRACER-OK`, exit 0.
- Tâche 2 (formes normatives, fixtures `demo-a`/`demo-b`) → `FORMES-OK`, INSTR=4 et INSTR=2, exit 0.
- Tâche 3 (contrat de sortie complet, 10 cas fixture) → `== bilan contrat : 0 ecart(s) ==`, exit 0.
- `git status --short plugin` → seul `plugin/conductor/scripts/check-instruction-budget.sh` en
  untracked/staged, aucun autre fichier sous `plugin/` touché.

## Correction ciblée post-revue vague 1 (commit `cca219b`)

Trois défauts confirmés par exécution sur fixtures (revue) ont été corrigés en direct, sans
réouverture de cycle ni élargissement de périmètre :

- **F1 (bloquant)** : le côté BASELINE des comparaisons (`bl_lines`/`bl_instr`) n'était jamais
  passé au garde numérique `case ... *[!0-9]*)` déjà appliqué au côté courant — sous
  `set -uo pipefail` sans `-e`, une comparaison `[ … -gt … ]` sur donnée non numérique laissait
  `verdict` à son initialisation `"OK"` et le code de sortie à `0`. Prouvé rouge→vert sur 4
  vecteurs : valeur non numérique, colonne manquante, CRLF résiduel, clé de baseline dupliquée
  (ce dernier fermé en reprenant le garde-fou déjà existant de `check-divergence.sh` S2,
  `cnt[$1]++`, jamais réinventé).
- **F2 (majeur)** : `frontmatter_state()`/`body_only()` reconnaissaient une paire de `---`
  n'importe où dans le fichier — un fichier SANS frontmatter réel mais portant deux `---` isolés
  dans le corps voyait le contenu entre les deux exclu du comptage en silence. Fix : le premier
  `---` n'ouvre le frontmatter que s'il est à `NR==1`.
- **F3 (majeur)** : `SANS_BASELINE_COUNT` n'était incrémenté que sur le verdict affiché
  `SANS-BASELINE`, jamais sur `DEPASSEMENT-ADR029` — un fichier > 250 lignes sans entrée de
  baseline rendait `1` au lieu du `2` exigé par le contrat de baseline incomplet des `must_haves`.
  Fix : le compteur suit `has_baseline==0`, indépendamment du verdict affiché.

Chaque correction a été prouvée avec un témoin rouge (script d'origine, commit `393b022`, sur
fixture `mktemp -d`) puis un vert (script corrigé), avant rejeu sans régression des trois blocs
`<verify>` des tâches 1/2/3 (`TRACER-OK`, `FORMES-OK`, `0 ecart(s)`). Aucun garde desserré : les
trois corrections resserrent des angles morts, n'élargissent aucune tolérance.

Trois findings `no-op` de la revue et de l'audit portés hors de cette correction, vers le rapport
de mission : puce `+ ` non reconnue (hors périmètre littéral du plan), portabilité GNU non
exerçable sur ce poste (renvoyée à la CI Linux, plan 25-03), évasion de mesure par bloc de code
fenced (design assumé, à inscrire au BACKLOG en 25-03).

## Hors périmètre de ce plan (D-06 bis, différé)

`.planning/instruction-budget-baselines.tsv`, `.planning/.instruction-budget-armed`, la suite de
tests dédiée (`plugin/conductor/scripts/tests/`), le câblage CI, la documentation/catalogue — tous
relèvent des plans 25-02, 25-03, 25-04.
