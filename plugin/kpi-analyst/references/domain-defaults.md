# KPIs par défaut par domaine (indices, pas des règles)

> Au Temps 1, l'agent **propose** un schéma. S'il existe un bundle métier installé (`business-pilot`,
> `content`, `growth`), il lit l'indice de domaine ci-dessous comme **point de départ** — puis l'adapte
> au brief réel du lab. Ces listes ne sont JAMAIS imposées : le métier du lab prime (P7).

---

## business (bundle `business-pilot`)

| key | label | unit | source probable dans le lab |
|---|---|---|---|
| `mrr` | MRR | € | contrats récurrents / abonnements |
| `ca_realise` | CA réalisé | € | `business/pipeline/clients/` + `completed/` (factures envoyées) |
| `leads_actifs` | Leads actifs | nb | `business/pipeline/leads/` + `prospects/` |
| `taux_closing` | Taux de closing | % | ratio `clients/` ÷ (`prospects/` + `clients/`) |
| `panier_moyen` | Panier moyen | € | CA ÷ nb clients gagnés |

## content (bundle `content`)

| key | label | unit | source probable |
|---|---|---|---|
| `contenus_publies` | Contenus publiés | nb | journal éditorial / livrables distribués |
| `vues` | Vues | nb | **Tier 2** (plateformes) — connecteur validé |
| `taux_engagement` | Taux d'engagement | % | **Tier 2** (plateformes) |
| `abonnes` | Abonnés | nb | **Tier 2** (plateformes) |

## growth (bundle `growth`)

| key | label | unit | source probable |
|---|---|---|---|
| `cac` | Coût d'acquisition | € | dépenses canal ÷ leads acquis |
| `leads_par_canal` | Leads / canal | nb | extension PAR CANAL du bundle growth |
| `taux_conversion` | Taux de conversion | % | leads → clients par canal |
| `roas` | ROAS | x | revenu attribué ÷ dépense |

---

> **Lecture de l'indice** : beaucoup de KPIs content/growth sont **externes** (plateformes) → `Tier 2`,
> donc `confidence: low` tant qu'aucun connecteur validé n'existe. Les KPIs business sont majoritairement
> **internes au lab** (pipeline, factures) → `Tier 1`, `high` dès l'init. C'est pourquoi business est le
> meilleur premier terrain du module.
