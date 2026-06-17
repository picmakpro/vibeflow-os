# Niveaux de confiance ↔ type de source (et lien EVALS / P8)

> Le `confidence` d'un KPI n'est pas cosmétique : il **conditionne l'affichage Hub** et protège contre
> le pilotage sur un faux chiffre. Règle : la confiance se déduit du **type de source**, pas du ressenti.

---

## Barème

| confidence | Quand l'attribuer | Source typique | Affichage Hub |
|---|---|---|---|
| **high** | Calcul/comptage **exact** depuis des fichiers structurés du lab, reproductible | somme des factures, comptage du pipeline, dernier MRR contractuel | valeur pleine |
| **medium** | Dérivation avec **hypothèse documentée**, ou connecteur externe validé | « facture statut=envoyée comptée comme CA », API tierce validée | valeur + repère « hypothèse » |
| **low** | Donnée **absente / ambiguë / estimée** par jugement | pas de source fiable, estimation à vue | **grisé / « à confirmer »**, exclu des totaux |

> Défaut machine (writer) : `source` vide → `low`. Une `source` présente sans `confidence` explicite → `medium`.

---

## Anti-hallucination (Iron Law)

- Une valeur **sans source vérifiable** ne peut **jamais** être `high`.
- En cas de doute entre deux niveaux, **descendre** d'un cran (prudence sur les chiffres).
- `value: null` est **préférable** à un nombre inventé. Le dashboard sait afficher « à configurer ».

---

## Pont avec EVALS (P8 — Évaluer)

Le registre `EVALS.md` du lab juge la **qualité cognitive** des outputs IA. Les KPIs y sont un cas
particulier : *« la valeur publiée était-elle juste ? »*

- Quand un KPI `high` se révèle faux (source mal lue), ouvrir un `EVAL-XXX` : noter l'écart, corriger
  l'extracteur (pas la valeur à la main), et **baisser la confiance** tant que l'extracteur n'est pas fiabilisé.
- Un KPI durablement `low` faute de source signale soit un connecteur Tier 2 à construire, soit une
  donnée que le métier ne produit pas encore — à remonter dans `JOURNAL`/`BLOCKERS`.

> Principe : la **confiance baisse vite, remonte lentement** — on ne re-passe `high` qu'après preuve de
> reproductibilité (extracteur testé sur données réelles).
