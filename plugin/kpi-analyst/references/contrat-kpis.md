# Contrat de données — schema.json, extracteurs, KPIS.md

> Source de vérité du format. Le Hub (R5.1) parse `KPIS.md` ; ce contrat garantit que ce que l'agent
> écrit colle **1:1 aux deux tables Hub** (`lab_kpi_configs` = schéma, `kpis` = valeurs).

---

## 1. `.claude/kpi/schema.json` — le SCHÉMA (stable, humain-validé)

Posé par l'agent **après validation humaine** au Temps 1. Les `key` sont **gelées à vie**.

```json
{
  "domain": "business",
  "kpis": [
    { "key": "mrr",          "label": "MRR",            "unit": "€",  "target": 20000, "domain": "business", "sortOrder": 0 },
    { "key": "ca_realise",   "label": "CA réalisé",     "unit": "€",  "target": 50000, "domain": "business", "sortOrder": 1 },
    { "key": "leads_actifs", "label": "Leads actifs",   "unit": "nb",                  "domain": "business", "sortOrder": 2 },
    { "key": "taux_closing", "label": "Taux de closing","unit": "%",  "target": 30,    "domain": "business", "sortOrder": 3 }
  ]
}
```

| Champ | Obligatoire | Mappe vers `lab_kpi_configs` |
|---|---|---|
| `key` | ✅ (stable, `snake_case`) | `metric_key` |
| `label` | ✅ | `label` |
| `unit` | — (`€`/`%`/`nb`/null) | `unit` |
| `target` | — | `target` |
| `domain` | — | `domain` |
| `sortOrder` | — | `sort_order` |

> **Règle d'or** : ne JAMAIS renommer une `key` (casse la série temporelle). Ajout/retrait d'un KPI =
> évolution de schéma **explicite et validée**, jamais un effet de bord d'un refresh.

---

## 2. Extracteur — sortie attendue (UNE ligne JSON sur stdout)

Chaque `.claude/kpi/extractors/<key>.sh` émet exactement :

```json
{"key":"ca_realise","value":42000,"source":"business/pipeline/clients/","confidence":"high"}
```

| Champ | Obligatoire | Notes |
|---|---|---|
| `key` | ✅ | doit exister dans `schema.json` |
| `value` | ✅ | `number` ou `null` (donnée absente) |
| `source` | recommandé | chemin/section justifiant le chiffre ; **absent → forcé `low`** |
| `confidence` | — | `high`/`medium`/`low` (défaut dérivé de la présence de `source`) |
| `trend` | — | `{ "direction":"up|down|flat", "delta":<n>, "period":"mois" }` |

Le writer **ignore** toute sortie sans `key`/`value` (robustesse) et **force `low`** si `source` vide.

---

## 3. `.claude/memory/KPIS.md` — le registre publié

Structure (produite par `kpis-writer.sh`, ne pas éditer à la main) :

```markdown
---
registre: KPIS
labSlug: businessflow
domain: business
schemaVersion: 1
generatedAt: 2026-06-17T09:00:00Z
generatedBy: kpi-analyst
---

# KPIS — businessflow

## Index
| key | label | value | unit | confidence | source |
| ... lignes lisibles ... |

## Données (source de vérité machine — ingérée par le Hub)
```json
{
  "schemaVersion": 1,
  "labSlug": "businessflow",
  "domain": "business",
  "generatedAt": "2026-06-17T09:00:00Z",
  "generatedBy": "kpi-analyst",
  "schema": [ /* = lab_kpi_configs */ ],
  "values": [ /* = kpis (time-series) */ ]
}
```
```

### Mapping Hub (R5.1, côté Hub)

| Bloc JSON | Table Hub | Opération |
|---|---|---|
| `schema[]` | `lab_kpi_configs` | **upsert** sur `(labSlug, key)` — clés stables |
| `values[]` | `kpis` | **insert** point time-series (`metric_value`, `measured_at`) |
| `values[].source` / `.confidence` | (extension R5.1) | persistés pour l'affichage garde-fou |

> Le parser Hub lit **le bloc JSON** comme source de vérité ; l'index Markdown est un miroir humain.
> Le watcher chokidar route `KPIS.md` → parser dédié (à ajouter R5.1). Convention de nom : `KPIS.MD`.
