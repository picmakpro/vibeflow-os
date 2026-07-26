# kpi-analyst — KPIs métier réels, reproductibles, sourcés

> Module VibeFlow OS (optionnel, toggable) qui fait émerger les **vrais indicateurs métier** d'un lab —
> CA, leads, MRR, vues, engagement — au lieu de compteurs méta, et les tient à jour de façon
> **déterministe** pour le dashboard du Hub.

**Version** : v1.0.2
**Type** : `agent + skill + scripts + references`
**Dépendances** : `planning-core`, `consolidator`
**Iron Law** : *« Aucun chiffre inventé. Chaque KPI porte sa source. Le schéma est gelé+validé ; les valeurs viennent d'un extracteur déterministe, pas du raisonnement LLM. »*

---

## Pourquoi

Un dashboard de lab qui affiche `decisions_count` / `sessions_count` ne dit **rien du métier**. On veut
piloter sur du réel : *combien de CA, combien de leads, quel MRR*. Mais la donnée structurée n'existe pas
toujours — elle est **éparse** (factures, pipeline, contrats). Ce module :

1. **Déduit** les KPIs pertinents depuis le brief du lab (Temps 1) — schéma **validé par l'humain**.
2. **Structure l'épars** (Temps 2) — écrit des **extracteurs déterministes** (factures → CA).
3. **Acquiert le manquant** (Temps 3, Tier 2, human-gated) — connecteurs externes, **non construit en v1**.
4. **Publie** (Temps 4) — registre `.claude/memory/KPIS.md` ingéré par le Hub.

## Ce que ça résout (vs le brief initial)

| Risque | Réponse du module |
|---|---|
| Dérive LLM sur des chiffres | extraction **machine-enforced** (scripts testés), pas de re-déduction par run |
| Clés instables → série temporelle Hub cassée | **schéma gelé** (≠ valeurs), `key` stables à vie |
| Agent qui ouvre Chrome / appelle des API en autonomie | **Tier 2 human-gated**, lecture seule, périmètre explicite |
| Chiffre inventé | `source` obligatoire ; sans source → `low` + grisé |

## Architecture (2 côtés)

- **Côté lab (ce module)** : agent `vibeflow-kpi-analyst` + skill `kpi-analyst` + `kpis-writer.sh`.
- **Côté Hub (R5, hors module)** : parser de `KPIS.md` → tables `lab_kpi_configs` (schéma) + `kpis`
  (valeurs time-series) → dashboard contextuel `/labs/[slug]`.

## Contenu

```
kpi-analyst/
├── AGENT.md                      # vibeflow-kpi-analyst (sonnet, ≤250L)
├── SKILL.md                      # méthode 4 temps (≤500L)
├── scripts/
│   ├── kpis-writer.sh            # assembleur déterministe de KPIS.md
│   ├── extractor-template.sh     # gabarit d'extracteur (1 KPI)
│   └── tests/test-kpis-writer.sh # 9 tests (contrat + idempotence + garde-fous)
└── references/
    ├── contrat-kpis.md           # schema.json / extracteurs / KPIS.md ↔ tables Hub
    ├── confidence-sources.md     # confidence ↔ source + EVALS (P8)
    ├── domain-defaults.md        # KPIs par défaut business/content/growth
    ├── tier2-acquisition.md      # connecteurs externes human-gated
    └── hook-sessionend.md        # refresh incrémental fin de session
```

## Installation

Via l'installeur VibeFlow (toggle multi-select) :

```
/vibeflow-install     → cocher « kpi-analyst »
```

`planning-core` et `consolidator` sont tirés automatiquement (résolution des `requires`).

## Tests

```sh
bash scripts/tests/test-kpis-writer.sh    # 9 ok / 0 ko
```
