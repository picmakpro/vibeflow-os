# Changelog — product-team-bundle

## [v1.0.0] — 2026-10-27 (naissance du bundle produit)

- Composition : manager `vf-product-manager`, workers internes `vf-product-analyst` (BRIEF) et `vf-product-pm` (PRD), juge interne `prd-gate` (rubric /100, seuil 80), gate déterministe `scripts/check-prd.sh`.
- Visibilité : `roles: ["product"]` — visible aux postes `product` et `solo`, invisible au poste `dev`.
- `proposable: false` jusqu'à un run réel complet sur un lab désigné par Samuel (P59-D-11).
- Aucune release racine.
