# 80-neutre — SUMMARY

## Livré
- Contrat : attribut neutre `data-vf-flottant`, valeurs `bouton` (pastille), `etat` (puce), `tiroir` (région). Posé par `ui/tiroir/tiroir-construire.js`.
- Lecteurs : `00-vf-surcouches.js` (`tiroir`), `02-vf-reperes.js` (tous les marqués), `41-vf-projet-vue.js` (`bouton`). Aucune lecture par la forme ne subsiste ;
  aucun littéral `vf-term-` ajouté (T7.5).
- `77-vf-git-tiroir.js` : l'observateur du corps (dans le rappel `surOnglet`, retiré avec lui) observe `childList` : `eviter()` se rejoue à l'arrivée d'un enfant.
- Tests : CL4.3 inversé, CL4.3d positif, mutants M-PASTILLE-FORME et M-PASTILLE-RIEN (couloirs) ; suite neuve `test-cockpit-neutre.sh` + `chrome-neutre.mjs`
  (NE1.1 à NE1.5, NE2.1, mutants M-FORME-PILE, M-FORME-REPERES, M-EVITER-REJEU). Trace : `80-neutre-RED-TRACE.md`.

## Écarts
- Écart : la pastille n'est pas dans `ui/terminal/vue.js` (bandeau Q) mais dans `ui/tiroir/tiroir-construire.js`.
- Écart : M-PASTILLE-DIV et M-PASTILLE-NONFIXE retirés (ils mutaient une reconnaissance par la forme qui n'existe plus) ; CL4.3b/c gardés.
- Le premier rouge du témoin 02 était faux (geste de relance fautif) : corrigé, voir la trace.
- Limite : 02 ne réévalue pas à l'arrivée d'une pastille (observe la classe du corps, pas ses enfants) ; non demandé, non touché.

## Suites (tête fb0dcfb8, avant la fusion 2cb3506a)
neutre 11/0 · couloirs 71/0 · surcouches 44/0 · coin 48/0 · git-tiroir 193/1 (M-SELECTION, mutant, hors jugement) ·
terminal-tiroir 129/9 (T21.7 connu de la 79 et 8 mutants de la famille T21.9-11, aucun lié aux fichiers touchés) ·
terminal-activation 53/1 (T7.5 : `ui/04-vf-canevas-champ.js`, 80-12 d'un voisin) · vendor 248/4 (V4c.9a : `41-vf-projet-panneau.js` d'un voisin ; V11.Q6/P5 : module introuvable).

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
CHANGELOG demandé par 80-18 : « Les extensions de la page lisent l'attribut neutre `data-vf-flottant` posé par le terminal, plus une forme ; le tiroir Git se replace à l'arrivée de la pastille. »

## Complément (correction ciblée du manager p80)
02-vf-reperes.js : l'observateur du corps observe aussi childList (arrivée tardive de la pastille). Témoin NE1.6 rouge (1 -> 1) puis vert (1 -> 0), mutant M-REPERES-REJEU. Suites : neutre 13/0, coin 44/0, couloirs voir bloc.
