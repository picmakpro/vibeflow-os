---
name: vf-gaps
description: >
  Utiliser quand l'utilisateur veut savoir ce qui traîne sur le **produit** et le combler —
  « qu'est-ce qui traîne ? », « qu'est-ce qu'on a laissé en plan », « comble les trous »,
  « fais le tour de ce qui manque », « y a des étapes jamais validées », « on a de la dette
  où ? », « audite le projet ». Balaie les recettes en souffrance et les validations
  manquantes sur toutes les étapes, classe les manques, puis propose de les corriger.
  ✘ pas pour relire un diff → /vf-review · ✘ pas pour auditer la conformité du lab, ses
  agents ou sa densité → /vf-audit · ✘ pas pour un simple point d'avancement sur la feuille
  de route → /vf-progress · ✘ pas pour comprendre pourquoi un cycle a déraillé →
  /vf-forensics · ✘ pas pour les failles de sécurité → /vf-secure.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-gaps — Audit du produit & comblement des manques

Délègue, selon ce qui est demandé :

- `gsd-audit-uat` — balayage inter-étapes des **recettes en souffrance** et des vérifications
  jamais faites ;
- `gsd-validate-phase` — comblement des **validations manquantes** d'une étape déjà terminée ;
- `gsd-audit-fix` — chaîne **constat → classement → correctif** quand l'utilisateur veut aussi
  que ce soit réparé, pas seulement listé.

Reframe toute sortie en vocabulaire VibeFlow : « UAT » → **recette**, « phase » → **étape/sprint**,
« audit-uat / validate-phase / audit-fix » → **état des manques** (cf. `vocabulary-map.md`). Ne
nomme jamais GSD ni ces cibles à l'utilisateur.

## Frontière avec `/vf-audit` — chasse gardée

`/vf-gaps` audite le **produit** : recettes en souffrance, validations manquantes, dette d'étape.
`/vf-audit` (module `validator`) audite la **conformité méthodologique du lab** : agents, densité,
dette documentaire, doctrine. Deux altitudes différentes — ne jamais router l'une vers l'autre, et
ne jamais capter « audite le lab / la conformité / les agents » ici.

Enchaînement typique : `vf-progress` (on voit que ça flotte) → `vf-gaps` (on cadre les manques) →
`vf-plan` ou `vf-quick` (on les solde).
