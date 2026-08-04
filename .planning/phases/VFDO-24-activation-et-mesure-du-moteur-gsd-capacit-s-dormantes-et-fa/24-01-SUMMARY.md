---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 01
subsystem: infra
tags: [agents, frontmatter, effort, check-agents, team-kernel, dispatch-depth, ADR-044, ADR-029]

requires:
  - phase: 16-lint-des-allowlists
    provides: "check-agents.sh lintant le contenu de tools: + le mécanisme --third-party-prefix qui borne le lint aux agents VibeFlow"
  - phase: 23-couplage-explicite-au-moteur-gsd
    provides: "GSDC-05 — la voie unique d'invocation, borne posée sur ce que la marge de profondeur n'autorise PAS"
provides:
  - "Les 25 agents livrés (plugin/*/agents/*.md) déclarent un effort: choisi PAR RÔLE — 12 high, 12 medium, 1 low"
  - "check-agents.sh EXIGE effort: sur les agents locaux, sans déborder sur les agents tiers écartés par --third-party-prefix"
  - "team-kernel.md porte la marge de profondeur de dispatch : maxDepth 5, 3 consommés, 2 de marge, et ce que la marge autorise"
  - "4 cas de test neufs dont 1 discriminance par mutation sur l'arbre réel"
affects: [24-08, 24-12, tout ajout futur d'agent dans plugin/*/agents]

# Actuals — le PLAN.md de ce plan ne portait PAS de champ `estimate:` en frontmatter.
# Aucune paire de calibration n'existe donc ; les valeurs ci-dessous sont mesurées a posteriori
# sur le diff réalisé (chars/4 sur les 4 commits), jamais un compteur de tokens du harness.
actuals:
  tokens: 5735
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Barème effort: PAR RÔLE propagé depuis les 3 agents-templates qui le portaient déjà"
    - "Durcissement de gate borné par test de non-débordement, jamais par lecture du code"

key-files:
  created: []
  modified:
    - plugin/*/agents/*.md (les 25)
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - plugin/conductor/scripts/guard-agent-write.sh
    - plugin/conductor/scripts/tests/test-guard-agent-write.sh
    - plugin/conductor/references/team-kernel.md

key-decisions:
  - "Le barème effort: est PROPAGÉ depuis les 3 agents-templates, jamais inventé — 12 high (6 orchestrateurs + 6 juges/auditeurs), 12 medium (production spécialisée à jugement de domaine), 1 low (vf-test-runner, seul rôle mécanique du parc)"
  - "Le durcissement transpose littéralement le bloc model: qui le précède, donc hérite du MÊME périmètre : le skip par --third-party-prefix intervient en amont dans la boucle principale, aucun agent tiers ne traverse le bloc effort"
  - "La marge de profondeur vit dans team-kernel.md (conductor) et non dans un module métier — c'est un fait de runtime commun aux 6 équipes (ADR-057, une capacité une seule voix)"
  - "La marge est écrite comme une PERMISSION (un worker peut dispatcher un sous-worker), pas comme une observation — sinon la question du nesting se repose au prochain audit"
  - "DÉVIATION assumée : guard-agent-write.sh et sa suite, hors files_modified du plan, corrigés parce que le durcissement rendait leur message et leur fixture faux (détail plus bas)"

patterns-established:
  - "Exhaustivité prouvée par comm entre la liste des fichiers et celle des porteurs du champ, jamais par un grep pipé (tronqué sur ce runtime)"
  - "Un littéral gardé par assertion machine ne se met pas en gras à cheval sur un retour à la ligne — la garde T76 a attrapé exactement ce défaut au premier jet"

requirements-completed: [GSDA-20, GSDA-21, GSDA-22]

coverage:
  - id: D1
    description: "Les 25 agents livrés déclarent un effort: par rôle (12 high / 12 medium / 1 low), aucun laissé de côté"
    requirement: GSDA-20
    verification:
      - kind: automated
        ref: "comm -23 / -13 / -12 entre la liste des 25 fichiers et celle des porteurs d'effort: — les deux différences vides, intersection 25/25"
        status: pass
      - kind: automated
        ref: "git diff --numstat : 1 insertion / 0 suppression sur chacun des 25 (aucune ligne de corps touchée)"
        status: pass
      - kind: automated
        ref: "awk 'END{print NR}' sur les 25 — 0 agent > 250 lignes (ADR-029) ; vf-dev-manager 245 → 246, marge de 4 lignes intacte pour 24-08"
        status: pass
  - id: D2
    description: "check-agents.sh exige effort: sur les agents locaux et l'ignore pour les tiers, les deux prouvés par test"
    requirement: GSDA-21
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T73 — agent local sans effort → exit 1, message nommant effort + l'énumération"
        status: pass
      - kind: unit
        ref: "test-check-agents.sh#T74 — agent tiers (préfixe gsd- par défaut) sans effort → 0 erreur, 0 warning citant effort (borne T-24-01-01)"
        status: pass
      - kind: unit
        ref: "test-check-agents.sh#T75 — MUTATION sur l'arbre réel : ligne effort: retirée → gate rouge ; restaurée → gate vert ; mutation confirmée effective par cmp"
        status: pass
      - kind: unit
        ref: "test-check-agents.sh#T73b — le squelette de refus du guard énumère effort au lieu de l'annoncer optionnel"
        status: pass
      - kind: integration
        ref: "les 2 étapes CI rejouées localement — --strict par module 6/6 et monde fermé --resolve-agents=strict 6/6, 0 échec"
        status: pass
  - id: D3
    description: "La marge de profondeur de dispatch est écrite, datée, sourcée et gardée par une assertion"
    requirement: GSDA-22
    verification:
      - kind: unit
        ref: "test-check-agents.sh#T76 — 12 littéraux exigés dans team-kernel.md (3 faits + date 2026-08-04 + version 1.9.1 + 7 champs du descripteur)"
        status: pass
      - kind: unit
        ref: "discriminance T76 prouvée par mutation des 3 littéraux porteurs (maxDepth, deux niveaux de marge, sous-worker) — chacun retiré fait rougir T76 et lui seul ; restauration byte-identique par cmp, réécriture licite verte"
        status: pass
      - kind: automated
        ref: "git diff --numstat sur team-kernel.md : 27 insertions / 0 suppression — aucune ligne existante perdue"
        status: pass
---

# 24-01 — `effort:` par rôle, gate durci, marge de profondeur écrite

## Accomplishments

- **25/25 agents portent un `effort:` par rôle.** 12 `high` (les 6 orchestrateurs et les 6
  juges/auditeurs), 12 `medium` (production spécialisée exigeant un jugement de domaine), 1 `low`
  (`vf-test-runner`, seul rôle mécanique du parc : il rejoue une recette Maestro déjà écrite et ne
  décide de rien). Trois valeurs distinctes, jamais une répartition uniforme. Le champ est inséré
  entre `model:` et `memory:`, la position observée dans `business-agent-template.md`.
- **`check-agents.sh` exige le champ** au lieu de le valider s'il est présent. Deux branches, à
  l'exacte forme du bloc `model:` qui le précède.
- **La marge de profondeur de dispatch est écrite** dans `team-kernel.md` : le descripteur verbatim,
  les 3 niveaux consommés sur 5, les deux niveaux de marge, ce que la marge autorise — et sa borne.

## Ce que le plan n'avait pas prévu (déviations déclarées)

Le durcissement a fait tomber deux fichiers hors du `files_modified` du plan. Les deux sont des
conséquences directes du changement, aucun autre motif :

1. **`plugin/conductor/scripts/guard-agent-write.sh`** — son squelette canonique de refus annonçait
   `effort: <optionnel>`. Or le guard invoque `check-agents.sh --strict` : il refusait donc une
   écriture pour l'absence d'un champ que son propre message déclarait optionnel. Un refus qui
   désigne mal sa cause fait corriger tout SAUF elle. Corrigé en énumérant les valeurs, et gardé par
   un cas neuf (T73b) qui exige la présence de l'énumération ET l'absence du mot « optionnel ».
2. **`plugin/conductor/scripts/tests/test-guard-agent-write.sh`** — sa fixture `CONFORME` (T1,
   écriture licite → allow) n'avait pas d'`effort:` et partait en `deny`. Champ ajouté.

Par ailleurs, **49 fixtures** de `test-check-agents.sh` conformes au socle natif ont reçu
`effort: medium` : un agent de test censé être conforme doit l'être au sens du gate durci, sinon les
cas mesurent le mauvais objet. Les deux fixtures qui doivent rester dépourvues du champ (T73, T74)
en sont explicitement exclues.

## Compteurs

| Mesure | Avant | Après |
|---|---|---|
| Agents livrés portant `effort:` | 0 / 25 | **25 / 25** |
| Cas de `test-check-agents.sh` | 76 | **81** (T73, T73b, T74, T75, T76) |
| Suites conductor vertes | 15 | **15** |
| `check-agents.sh --strict` sur `plugin/*/agents` | 6/6 | **6/6** |
| `check-agents.sh --resolve-agents=strict` (monde fermé) | 6/6 | **6/6** |
| `team-kernel.md` | 81 lignes | **108** (+27, −0) |

## Point ouvert — hors périmètre de ce plan

`scripts/check-version-sync.sh` sort en échec sur `README.md`/`README.fr.md` : « 47 suites » ≠
réel 48. **Non imputable à ce plan** — je n'ai créé aucune suite, seulement ajouté des cas dans une
suite existante. La 48ᵉ suite est `test-check-workstream-pointer.sh`, ajoutée par le commit
`eb70dac` (plan 24-05). Le plan **24-12** porte déjà ce compteur (« 47→49 ») : c'est là qu'il se
referme, pas ici.

## Commits

| SHA | Nature |
|---|---|
| `378cedd` | `feat(24)` — effort par rôle sur les 25 agents livrés (GSDA-20) |
| `dd65f9c` | `test(24)` — cas rouges pour l'exigence d'`effort:` (T73/T74/T75) |
| `a29cd60` | `feat(24)` — `check-agents.sh` exige `effort:` (GSDA-21) + déviations déclarées |
| `6675964` | `docs(24)` — marge de profondeur de dispatch dans `team-kernel.md` (GSDA-22) |
