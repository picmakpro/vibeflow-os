---
name: vf-decide
description: >
  Utiliser quand l'utilisateur doit trancher une zone grise technique et veut un avis
  argumenté plutôt qu'un choix arbitraire — « quelle option ? », « on part sur quoi ? »,
  « compare ces approches », « aide-moi à choisir », « bibliothèque X ou Y ? »,
  « c'est mieux de faire A ou B ? ». Produit un tableau comparatif sourcé + une reco.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-decide — Panel de décision

Convoque un **panel de décision** : plusieurs recherches indépendantes sur la zone grise,
puis une **synthèse comparative** avec recommandation motivée.

En coulisse, délègue au **mode advisor de `gsd-discuss-phase`** — c'est lui qui orchestre le
panel de recherche décisionnelle (plusieurs advisors indépendants selon l'enjeu) et en
consolide les résultats. On route vers le skill canonique, jamais vers un agent en direct.

## Sortie attendue

1. **Tableau comparatif** des options (critères : effort, risque, maintenabilité, adéquation
   au projet, réversibilité).
2. **Recommandation** claire avec le raisonnement (pourquoi cette option gagne, ce qu'on perd).
3. Les **hypothèses** et sources qui sous-tendent la reco (traçabilité).

## Règles

- **Reframe le vocabulaire** : « advisor / researcher » → **panel de décision** ; « phase » →
  **étape/sprint** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni Superpowers.
- **Ne tranche pas à la place de l'utilisateur** sur un choix qui l'engage : recommande, puis
  laisse-le décider (cf. ADR-031 — matérialisation = acte humain).
- **N'invente pas de sources** : une option non vérifiable est signalée comme telle.

## Quand l'utiliser vs autre chose

- Choix **technique isolé** (lib, pattern, approche) → `vf-decide`.
- Cadrage **complet d'un sprint** (plusieurs décisions + périmètre) → `vf-plan`.
