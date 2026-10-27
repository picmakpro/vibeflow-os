# Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date :** 2026-10-26 (questions) / 2026-10-27 (réponses)
**Phase :** 59-bundle-produit
**Zones discutées :** Composition du bundle · BRIEF, PRD, juge · Head et visibilité · Exposition et sobriété

**Canal :** `vf-dev-manager` a escaladé les questions par SendMessage vers la session principale le 2026-10-26. Samuel y a répondu par AskUserQuestion en session principale le 2026-10-27 :
- Q1 à Q4 posées le 2026-10-26, réponse reçue à la reprise de session ;
- réponses relayées au manager telles quelles le 2026-10-27 ;
- recommandation retenue partout.

---

## Composition du bundle

| Q | Options | Selected |
|---|---------|----------|
| Q1 composition | front door + manager + analyst + pm + prd-gate, architect en 60 · front door + juge seuls · avec l'architect dès la 59 | « Bundle complet (Recommandé) » ✓ |
| Q2 noms | `product-team-bundle` + `/vf-product` · `product-bundle` + `/vf-product` | « product-team-bundle (Recommandé) » ✓ |

## BRIEF, PRD, juge

| Q | Options | Selected |
|---|---------|----------|
| Q3 gabarit `product` | dans planning-core (dimension « poste ») · dans le bundle | « planning-core (Recommandé) » ✓ |
| Q4 BRIEF | `.planning/BRIEF.md` · racine du lab | « .planning/BRIEF.md (Recommandé) » ✓ |
| Q5 seuil | 80/100 + 2 éliminatoires · 70/100 + 1 éliminatoire | « 80/100 + 2 élimin. (Recommandé) » ✓ |
| Q6 vérification | LLM + `check-prd.sh` (QUAL-01) · LLM seul | « LLM + check-prd.sh (Recommandé) » ✓ |
| Q7 sous le seuil | halte vers l'humain · refus côté head | « Halte vers l'humain (Recommandé) » ✓ |

## Head et visibilité

| Q | Options | Selected |
|---|---------|----------|
| Q8 head au poste product | redirige + override explicite · redirection stricte · propose seulement | « Redirige, override (Recommandé) » ✓ |
| Q9 baseline head | jusqu'à +3 (33 → 36), objectif 0 · aucune hausse | « Jusqu'à +3 (Recommandé) » ✓ |
| Q10 visibilité | `roles:["product"]` · `roles` absent | « roles:["product"] (Recommandé) » ✓ |

## Exposition et sobriété

| Q | Options | Selected |
|---|---------|----------|
| Q11 Q-09 | false jusqu'à preuve + Ajout-Retrait « aucun » · true dès la 59 · false + retrait nommé | « false jusqu'à preuve (Recommandé) » ✓ |
| Hypothèses | 250 l./agent, bumps de modules sans racine ni release, pas de preset produit, PROJECT.md et Coverage en dette | « Je valide (Recommandé) » ✓ |

## Faits établis avant le tour (non demandés à l'humain)

- Noms BMAD courants : v6.12.4, lue le 2026-10-26 (P59-D-13).
- Invariant I2 de `check-agents.sh` : un juge interne doit être dispatché par une allowlist de `plugin/*/agents`.
- L'engine ignore `proposable`.
- `vibeflow-head` ne lit pas le poste.
- `planning-core` n'a pas de gabarit `product`.

## Note de canal

Le 2026-10-27, la session principale a d'abord indiqué que Willy n'était pas prévenu et que Samuel s'en chargeait. Samuel a ensuite précisé, par un message en session principale le même jour : « pas besoin de prévenir Willy + on attend pas sa phase pour merge et release » (P59-D-23). Il n'y a donc ni coordination ni rebase sur la Phase 45.
