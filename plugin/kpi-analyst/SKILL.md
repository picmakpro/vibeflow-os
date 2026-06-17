---
name: kpi-analyst
description: >
  Méthode pour déduire, calculer et publier les VRAIS KPIs métier d'un lab. Charger quand on parle de
  KPIs / indicateurs / CA / leads / MRR / vues / engagement / « mets à jour les chiffres » / « configure
  les indicateurs », ou à l'activation d'un lab. Couvre : déduction du schéma depuis le brief, séparation
  schéma stable vs valeurs, écriture d'extracteurs déterministes (anti-dérive LLM), publication du
  registre KPIS.md lu par le Hub, niveaux de confiance, et la frontière Tier 1 (interne) / Tier 2
  (acquisition externe human-gated). Iron Law : aucune valeur inventée, chaque KPI porte sa source.
---

# kpi-analyst — Des KPIs métier réels, reproductibles, sourcés

> **Iron Law** : *« AUCUN CHIFFRE INVENTÉ. Chaque KPI est extrait/calculé depuis une source citée par un
> extracteur déterministe, ou marqué `low` et grisé. Le schéma est gelé+validé ; les valeurs viennent du
> script, pas du raisonnement. »*

Ce skill outille un principe simple : **on ne pilote pas un business sur des compteurs méta**
(`decisions_count`, `sessions_count`). On le pilote sur **CA, leads, taux de closing, MRR, vues,
engagement** — des chiffres *réels*, *tenus à jour*, et *traçables*.

La difficulté : **la donnée structurée n'existe pas toujours**. La valeur d'un KPI est souvent dérivable
de données **éparses** dans le lab (factures, pipeline, contrats, docs). Le travail principal à l'init est
donc de la **structurer**, pas seulement de la lire.

---

## Principe directeur : déterminisme machine-enforced

Un LLM qui « déduit le CA depuis les factures » à chaque run **dérive** (chiffres légèrement différents,
non reproductibles). C'est inacceptable pour des KPIs.

**Règle** : à l'init, l'agent *raisonne une fois* et **écrit un extracteur** (script). Aux runs suivants,
il **exécute** l'extracteur. Le calcul vit dans le code, reproductible ; l'intelligence de l'agent sert à
*déduire le bon schéma* et à *écrire le bon extracteur*, pas à recalculer.

```
INIT  : brief → déduire KPIs → [VALIDATION HUMAINE] → écrire extracteurs → 1ère publication
RUN N : exécuter extracteurs (sources changées) → ré-assembler KPIS.md   (idempotent, $0, headless)
```

---

## Les deux objets — ne JAMAIS les confondre

Le Hub a **deux tables** ; on écrit donc **deux choses distinctes** dans `KPIS.md`.

### 1. Le SCHÉMA (rare, gelé, humain-validé) → `lab_kpi_configs`

La **liste des indicateurs** du lab : `key`, `label`, `unit`, `target` (optionnel), `domain`, `sortOrder`.
- Déduit **une fois** à l'activation, **validé par l'humain**, puis **gelé**.
- Les `key` sont **stables à vie**. Renommer une `key` **casse la série temporelle** du Hub.
- Évolution = événement explicite (ajout/retrait d'un KPI), jamais un effet de bord d'un refresh.

### 2. Les VALEURS (fréquent, déterministe) → `kpis`

Un **point de mesure** par KPI : `value`, `measuredAt`, + garde-fous `source`, `confidence`, `trend`.
- Rafraîchies en fin de session et sur demande.
- Produites **uniquement** par extraction/calcul, jamais saisies.

> Mémo : *le schéma dit « quels indicateurs », les valeurs disent « combien, maintenant, d'où ».*

---

## Méthode — les 4 temps

### Temps 1 — Comprendre le métier → proposer le schéma

1. Lire l'objectif du lab : `.planning/PROJECT.md` / `STATE.md`, `docs/REFERENCE.md`, `CLAUDE.md`, et
   l'**indice de domaine du bundle** s'il existe (`business-pilot` / `content` / `growth` posent des KPIs
   par défaut — voir `references/domain-defaults.md`).
2. En **déduire 3 à 6 KPIs pertinents** (pas génériques). Exemples par domaine :
   - **business** : `mrr`, `ca_realise`, `leads_actifs`, `taux_closing`, `panier_moyen`.
   - **content** : `contenus_publies`, `vues`, `taux_engagement`, `abonnes`.
   - **growth** : `cac`, `leads_par_canal`, `taux_conversion`, `roas`.
3. **Présenter le schéma à l'humain pour validation** (AskUserQuestion / récap). On ne gèle rien sans go.
   → Persister le schéma validé dans `.claude/kpi/schema.json` (contrat §`references/contrat-kpis.md`).

### Temps 2 — Structurer l'épars (Tier 1, interne, déterministe)

Pour chaque KPI du schéma, **localiser la source dans le lab** et **écrire un extracteur** :

- Copier `scripts/extractor-template.sh` → `.claude/kpi/extractors/<key>.sh`.
- L'extracteur lit la/les source(s) (ex. parcourt `business/pipeline/clients/*.md`, somme les montants)
  et émet **une ligne JSON** sur stdout :
  ```json
  {"key":"ca_realise","value":42000,"source":"business/pipeline/clients/","confidence":"high"}
  ```
- **Déterministe** : même entrée → même sortie. Pas d'appel LLM dans l'extracteur.
- `confidence`:
  - `high` = somme/comptage exact depuis des fichiers structurés du lab ;
  - `medium` = dérivation avec hypothèse documentée (ex. statut « envoyée » = comptée) ;
  - `low` = donnée absente/ambiguë → valeur `null` ou estimation **grisée**, à confirmer.

> Tier 1 = **zéro accès externe**. Lecture des fichiers du lab uniquement. Sûr, idempotent, gratuit.

### Temps 3 — Acquérir le manquant (Tier 2, externe, HUMAN-GATED)

Si un KPI dépend d'une source **hors du lab** (ex. abonnés Instagram temps réel) :

- **NE PAS** ouvrir un navigateur ni appeler une API en autonomie sur des chiffres sensibles.
- **Proposer un connecteur** (procédure réutilisable) et le faire **valider** avant activation.
- Le périmètre d'accès (quels MCP, quel niveau d'automatisation navigateur, quelles API) est
  **explicitement autorisé** par l'humain, jamais élargi seul.
- Détail, garde-fous sécu et format de procédure : `references/tier2-acquisition.md`.

> Tier 2 est **documenté mais volontairement non-construit en v1** : on livre la valeur (Tier 1) sans
> ouvrir la surface de risque. Construire Tier 2 plus tard, par connecteur, sous validation.

### Temps 4 — Publier le registre

Exécuter l'assembleur déterministe :

```sh
scripts/kpis-writer.sh --lab <slug> --domain <domaine> \
  --schema .claude/kpi/schema.json \
  --extractors .claude/kpi/extractors \
  --out .claude/memory/KPIS.md
```

Il produit `.claude/memory/KPIS.md` : **frontmatter** + **index** (lecture par défaut, convention
`consolidator`) + **bloc JSON source-de-vérité** (schéma + valeurs) que le Hub ingère. Contrat exact :
`references/contrat-kpis.md`.

---

## KPIS.md — 6e registre canon

`KPIS.md` rejoint les registres mémoire standards dans `.claude/memory/` :

| Registre | Répond à |
|---|---|
| DECISIONS / LEARNINGS / BLOCKERS / JOURNAL / EVALS | doctrine, mémoire, dette, journal, qualité cognitive |
| **KPIS** *(ce module)* | **où en est le métier, en chiffres réels et sourcés ?** |

Comme les autres, il **commence par un index** (lecture de l'index par défaut). Le bloc JSON suit.

---

## Confiance & EVALS (P8)

Le niveau de `confidence` n'est pas cosmétique : il conditionne l'affichage Hub (un `low` est grisé / « à
confirmer »). Mapping confidence ↔ type de source et lien avec le registre EVALS :
`references/confidence-sources.md`.

---

## Cycle de vie & déclenchement

| Moment | Action | Mécanisme |
|---|---|---|
| Activation du lab | Schéma + extracteurs + 1ère publication | install module → agent une fois |
| Fin de session | Refresh **incrémental** (sources changées) | hook `SessionEnd` (`references/hook-sessionend.md`) |
| Quotidien (option) | Refresh complet | cron du lab/Hub |
| Manuel | Refresh complet | « mets à jour les KPIs » |

---

## Garde-fous (rappel Iron Law)

1. **Aucune valeur inventée** — `source` obligatoire, sinon `low` + grisé.
2. **Extraire/calculer, jamais saisir.**
3. **Idempotence** — le calcul est dans l'extracteur, pas dans le LLM.
4. **Schéma gelé+validé** — `key` stables à vie ; évolution explicite seulement.
5. **Tier 2 human-gated** — accès externe autorisé explicitement, jamais en autonomie sur du financier.
6. **Détecter ≠ inventer** — source absente → on le dit, on ne comble pas.

---

## Références

- `references/contrat-kpis.md` — format exact de `schema.json`, des extracteurs, et de `KPIS.md` (mappe les 2 tables Hub).
- `references/confidence-sources.md` — confidence ↔ source + lien EVALS (P8).
- `references/domain-defaults.md` — KPIs par défaut par domaine (business/content/growth) via bundles.
- `references/tier2-acquisition.md` — connecteurs externes, périmètre d'accès, garde-fous sécu.
- `references/hook-sessionend.md` — snippet hook refresh incrémental.
