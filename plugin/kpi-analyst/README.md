# kpi-analyst — KPIs métier réels, reproductibles, sourcés

> Un dashboard de lab qui affiche `decisions_count` ne dit rien du métier : ce module fait émerger
> les **vrais indicateurs** (CA, leads, MRR, vues, engagement) et les tient à jour de façon
> **déterministe** — jamais un chiffre inventé, chaque KPI porte sa source.

**Type** : agent + skill + scripts + references · **Version** : v1.0.5 · **Dépend de** : `planning-core`, `consolidator`

---

## Quoi

Module optionnel pour tout lab qui veut **piloter sur des chiffres réels** alors que la donnée est
éparse (factures, pipeline, contrats, docs). Il fournit :

1. **L'agent `vibeflow-kpi-analyst`** (sonnet, skill préchargé) — déduit les KPIs pertinents
   depuis le brief du lab, structure l'épars, publie et explique (« pourquoi ce chiffre »).
2. **Le skill `kpi-analyst`** — la méthode en 4 temps : Comprendre (schéma **validé par
   l'humain**) → Structurer (extracteurs déterministes) → Acquérir (Tier 2, human-gated, non
   construit en v1) → Publier (`.claude/memory/KPIS.md`).
3. **Les scripts** — `kpis-writer.sh` (assembleur idempotent du registre) et
   `extractor-template.sh` (gabarit d'extracteur, 1 KPI = 1 script).

**Principe directeur — déterminisme machine-enforced** : un LLM qui « recalcule le CA » à chaque
run dérive. Ici l'agent *raisonne une fois* (quels KPIs, depuis quelles sources) et **écrit des
extracteurs** ; aux runs suivants il les **exécute**. Deux objets jamais confondus :

| Objet | Fréquence | Validation |
|---|---|---|
| **Schéma** (`key`/`label`/`unit`/`target`/`domain`) | rare — init + évolution explicite | **humaine, obligatoire** ; `key` gelées à vie |
| **Valeurs** (point time-series + `source`/`confidence`/`trend`) | fréquente — fin de session | automatique si extraction déterministe |

`KPIS.md` rejoint les registres canon de `.claude/memory/` (DECISIONS, LEARNINGS, BLOCKERS,
JOURNAL, EVALS) : index en tête + bloc JSON source-de-vérité. Il est pleinement utilisable en
**standalone** ; un « Hub » (dashboard central externe, **optionnel**) peut l'ingérer dans ses
tables `lab_kpi_configs` (schéma) et `kpis` (valeurs).

---

## Installation

Via l'installeur (`/vibeflow-install`, cocher « kpi-analyst » — résolution des dépendances
assurée) ou l'engine directement :

```bash
bash plugin/_internal/vibeflow-update.sh [--scope user|project|local] install --with-deps kpi-analyst
```

⚠️ En **install nu** (sans `--with-deps`), la résolution des `requires` n'est pas automatique :
installer dans l'ordre —

```bash
bash plugin/_internal/vibeflow-update.sh install planning-core
bash plugin/_internal/vibeflow-update.sh install consolidator
bash plugin/_internal/vibeflow-update.sh install kpi-analyst
```

Prérequis outillage : `jq` (les scripts l'exigent — wrapper `jqx` intégré pour la portabilité
Windows, ADR-054).

---

## Démarrer — le schéma de KPIs en 5 minutes

Dans un lab avec le module installé (idéalement avec un brief posé dans `.planning/`), dis :

> « Configure les indicateurs du lab »

Ce qui se passe :

1. **Temps 1** — l'agent lit l'objectif du lab (`.planning/PROJECT.md`, `docs/REFERENCE.md`,
   `CLAUDE.md`, indice de domaine du bundle) et **propose 3 à 6 KPIs** pertinents — pas
   génériques (ex. business : `mrr`, `ca_realise`, `leads_actifs`, `taux_closing`).
2. **Tu valides** — rien n'est gelé sans ton go. Le schéma validé est persisté dans
   `.claude/kpi/schema.json` ; les `key` sont désormais stables à vie.
3. **Temps 2** — pour chaque KPI, l'agent localise la source dans le lab et **écrit un
   extracteur** (`.claude/kpi/extractors/<key>.sh`) qui émet `{key, value, source, confidence}`.
   Zéro accès externe, zéro appel LLM dans le script.
4. **Temps 4** — `kpis-writer.sh` assemble la première publication : `.claude/memory/KPIS.md`.

Résultat : un registre versionnable avec chaque chiffre traçable jusqu'à son fichier source.

---

## Usage

| Tu dis… | Ce qui se passe |
|---|---|
| « quels sont mes KPIs / mon CA / mes leads / mon MRR » | lecture du registre, réponse sourcée |
| « mets à jour les KPIs » | refresh complet : tous les extracteurs → ré-assemblage |
| « pourquoi ce chiffre » | l'agent ouvre le `source` du KPI dans l'index et l'explique |
| « ajoute/retire un KPI » | **évolution de schéma explicite** (re-validation) — jamais un effet de bord d'un refresh |
| *(fin de session)* | hook `SessionEnd` optionnel : refresh **incrémental** — seulement les extracteurs dont la source a changé (`references/hook-sessionend.md`) |

Niveaux de confiance affichés avec chaque valeur : `high` (comptage exact depuis fichiers
structurés) · `medium` (dérivation avec hypothèse documentée) · `low` (source absente/ambiguë →
grisé, « à confirmer »). Sans source, l'agent **préfère ne rien afficher** qu'un faux chiffre.

Vérifier l'assembleur :

```sh
bash scripts/tests/test-kpis-writer.sh    # 9 tests — contrat, agrégation, garde-fou source→low, idempotence
```

---

## Référence

| Fichier | Rôle |
|---|---|
| `AGENT.md` | Agent `vibeflow-kpi-analyst` (sonnet, memory project, skill préchargé) — persona, garde-fous, délégation |
| `SKILL.md` | Méthode 4 temps, séparation schéma/valeurs, cycle de vie, Iron Law |
| `scripts/kpis-writer.sh` | Assembleur déterministe de `KPIS.md` (frontmatter + index + bloc JSON) depuis `schema.json` + sorties d'extracteurs |
| `scripts/extractor-template.sh` | Gabarit d'extracteur (1 KPI → 1 ligne JSON contractuelle) |
| `scripts/tests/test-kpis-writer.sh` | 9 tests : contrat, idempotence, garde-fous |
| `references/contrat-kpis.md` | Format exact de `schema.json`, des extracteurs et de `KPIS.md` (mappe les 2 tables Hub) |
| `references/confidence-sources.md` | Mapping confidence ↔ type de source + lien registre EVALS (P8) |
| `references/domain-defaults.md` | KPIs par défaut par domaine (business / content / growth) via bundles |
| `references/tier2-acquisition.md` | Connecteurs externes human-gated : périmètre d'accès, garde-fous sécu |
| `references/hook-sessionend.md` | Snippet hook `SessionEnd` — refresh incrémental de fin de session |

---

## Limites

- **Tier 2 non construit en v1** : l'acquisition externe (MCP, navigateur, API — ex. abonnés
  Instagram) est documentée mais volontairement non livrée. Chaque connecteur futur sera
  human-gated, périmètre explicite, jamais élargi en autonomie.
- **La qualité suit les sources internes** : un lab sans données structurées (pas de factures ni
  pipeline en fichiers) produira surtout du `low` grisé. Le module structure l'épars, il ne
  comble pas l'absent — détecter ≠ inventer.
- **Schéma gelé par construction** : renommer une `key` casse la série temporelle du Hub ; toute
  évolution passe par une re-validation humaine explicite.
- **Le côté Hub est hors module** : parser de `KPIS.md`, tables et dashboard (`/labs/[slug]`)
  vivent côté Hub (R5). Le registre reste pleinement utilisable sans.
