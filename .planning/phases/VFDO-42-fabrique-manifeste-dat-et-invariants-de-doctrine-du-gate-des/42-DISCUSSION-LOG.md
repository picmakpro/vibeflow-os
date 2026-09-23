# Phase 42 — Discussion Log

> Trace humaine du cadrage. Non consommée par les agents aval — la source est `42-CONTEXT.md`.

**Date :** 2026-09-23 · **Mode :** default (interactif) · **Canal :** AskUserQuestion, session principale

## Zones grises présentées

| Zone | Question posée |
|---|---|
| Péremption du manifeste | durée de validité ; effet d'un INDÉTERMINÉ chez l'utilisateur |
| Agents de Sam qui rougissent | corriger dans la phase ou armer en avertissement |
| Monde fermé I2/I3 | managers dérivés des allowlists ou registre écrit |
| Ordre avec la PR #85 | attendre son merge ou empiler |

**Réponse de Willy** (première tentative vide, relancée une fois comme le prévoit le workflow) :
« tranche tout tu as de quoi ».

## Décisions prises par Claude, et les mesures qui les fondent

- Péremption → D-02 (30 j), D-04, D-05. Mesure : `guard-agent-write.sh` refuse sur tout diagnostic `✗` ;
  un INDÉTERMINÉ par défaut bloquerait l'écriture d'agents dans tout lab installé depuis plus de 30 jours.
- Corpus → D-11, D-12. Mesure (script jetable sur les 31 agents) : I3 ×1, I5 ×4 (après D-08), I6 ×4-5
  (après D-07), I1/I2/I4/I7 ×0.
- Définitions → D-07 et D-08, qui s'écartent de la spec : définies à la lettre, I6 et I5 visaient
  `vf-reviewer` et `vf-auditer`, des workers internes relecteurs.
- Monde fermé → D-09 (réutilise `--resolve-agents=strict`).
- PR #85 → D-14 (planifier maintenant, exécuter après son merge) ; cause de sa CI rouge mesurée :
  trailer `Gate-Touche:` absent (G-2).

## Idées différées
Voir `42-CONTEXT.md` § Deferred Ideas.
