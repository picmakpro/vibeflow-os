---
status: complete
---

# Quick 261013-owa — SUMMARY

## Recensement (contrôles ré-appliqués à tort par une copie détachée)

- suite : le refus detache-requis (cmd_suite, l. 711 avant) -> garde par DETACHE_INTERNE ou --detache-herite (l. 711-720 après).
- toutes : le refus detache-requis (cmd_toutes, l. 1405 avant) -> garde par DETACHE_INTERNE.
- imputer : le rejeu de suite lancé par imputer_rejeu (bash OUTIL suite, l. 2236 avant) tombait sur detache-requis -> --detache-herite=<dossier> transmis quand DETACHE_INTERNE est posé.
- Non concernés (vérifiés) : base-absente, base-rouge, borne (calculés par l appel externe uniquement, hors du chemin interne) ; --base-ajout/--detache (exclusion à l appel externe).

## Autotest

- Cas neufs : detache-suite-base-longue, detache-toutes-base-longue, imputer-detache-base-longue.
- Sur la logique d avant (1d1c9e8a, correctifs inversés) : 3 ko, echecs=3 (cas=188 declares=188, sans-reel).
- Final (après regel tracé et correction de la phrase (bp)) : AUTOTEST-BILAN cas=201 declares=201 echecs=0. reel-etat-temoin est reparu vert : etat-reference rend ecarts=0.

## Empreinte (décision 1 du manager, 2026-10-13 : regel TRACÉ)

Mon premier regel (e1b5fc94) rendait EMPREINTE-ECART gel-rouvert (deux commits sur le .sha256, par conception). Le manager l'a RETIRÉ de l'historique local (sauvegarde vf-backup/p461-fix-outil-avant-reecriture) et a décidé une voie déclarée : un commit sur le .sha256 après le gel est un regel valide s'il ne touche que le .sha256 et porte Regel-Outil: <id quick> — <raison>. Implémenté (b284c367) avec cinq cas d'autotest, prouvés par mutants (regex désarmée : declare et commit-apres-regel rouges ; sans trailer, touche-autre, id mal formé, tiret, calcul depuis le premier gel : chacun tué). Regel f108ef1b. empreinte : EMPREINTE-REGEL f108ef1b 261013-owa … puis EMPREINTE ok … regels=1.

## Phrase de la limite (bp) (décision 2)

modele-cycles.md l. 1056 : « qu'un G4 armé aurait refusées » lue par k4 comme G4 armé ; reformulé « que G4 aurait refusées s'il refusait » (1b5cba0e, 46.1-01, P461-D-01).

## Preuves de bout en bout (détache, base >= 480 s)

test-cloture-gates.sh : SUITE … rc=0 duree=102 ; DETACHE-FIN rc=0 duree=103. test-planning-gates.sh : SUITE … rc=0 duree=352 ; DETACHE-FIN rc=0 duree=352.

## Commits

54936dc9 (correction detache), b284c367 (regel tracé), 1b5cba0e (phrase (bp)), f108ef1b (regel).
