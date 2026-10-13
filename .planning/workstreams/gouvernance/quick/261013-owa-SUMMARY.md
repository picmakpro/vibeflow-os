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
- Après : cas=196 declares=196 echecs=1 (reel-etat-temoin, préexistant, hors périmètre : modele-cycles.md l. 1056, écrit par 46.1-01).

## Empreinte

Regel posé (e1b5fc94) ; empreinte rend EMPREINTE-ECART gel-rouvert : le .sha256 a désormais deux commits, par conception. Décision du manager requise.

## Commits

54936dc9 (outil), e1b5fc94 (regel).
