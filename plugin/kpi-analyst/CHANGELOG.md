# CHANGELOG — kpi-analyst

## [v1.0.5] — 2026-08-30 (Phase 38 — description de frontmatter YAML strict, plan 38-08)

**Patch** :

- **Description de frontmatter passée en scalaire mono-ligne quoté** — la description est désormais un scalaire guillemets doubles mono-ligne (texte strictement inchangé), pour traverser sans perte un parseur YAML strict ET la logique d'extraction de gsd-core (`extractFrontmatterField`). 1 fichier du module concerné. Gate : `plugin/conductor/scripts/check-description-fidelity.sh` (Phase 38, plan 38-08, FIDE-01/FIDE-02).

## [v1.0.4] — 2026-08-04

### Modifié
- **`AGENT.md` (`vibeflow-kpi-analyst`) déclare `effort: medium`.** Motif : `check-agents.sh`
  **exige** désormais le champ (conductor v1.20.0) au lieu de le valider seulement quand il est
  présent. Ce module est **mono-agent** — son agent vit dans l'`AGENT.md` de la racine, pas sous
  `agents/` : c'est exactement la famille que le balayage par `plugin/*/agents/` ne voyait pas, et
  qui serait restée non conforme jusqu'au Gate C d'un lab frais. La CI balaye désormais aussi
  `plugin/*/AGENT.md`.

## [v1.0.3] — 2026-07-26

### Modifié
- README monté au standard de doc (installation, démarrer, usage, référence).

## [v1.0.2] — 2026-07-25

### Modifié
- Le « Hub » est défini comme dashboard central externe **optionnel** — le registre KPIS.md reste pleinement utilisable en standalone.

## [v1.0.1] — 2026-07-22 (portabilité Windows — ADR-054)

### Corrigé
- **`kpis-writer.sh` + `extractor-template.sh`** : wrapper `jqx` (`jq | tr -d '\r'`) sur les 12
  invocations — sous un jq Windows natif, un `\r` résiduel s'encodait DANS la donnée persistée
  (`"domain": "generic\r"` de KPIS.md, registre ingéré par le Hub) via `--arg`, et chaque ligne du
  bloc JSON/index héritait d'un CRLF. Guard `command -v jq` ajouté au gabarit extracteur.

## [v1.0.0] — 2026-06-17

### Initial release — Agent KPIs métier déduits (zone H / R5 du Hub, côté lab)

Premier module qui fait émerger les **vrais KPIs métier** d'un lab et les publie pour le dashboard du Hub.

**Agent natif Claude Code**
- `vibeflow-kpi-analyst` (sonnet, `memory: project`, skill `kpi-analyst` préchargé). ≤250L (charte ADR-029).
- Déclencheurs : activation du lab, hook `SessionEnd` (incrémental), invocation manuelle.

**Skill**
- `kpi-analyst` — méthode 4 temps (Comprendre → Structurer → Acquérir[Tier 2] → Publier). ≤500L.

**Scripts (enforcement déterministe)**
- `kpis-writer.sh` — assembleur idempotent de `KPIS.md` depuis `schema.json` + extracteurs.
- `extractor-template.sh` — gabarit d'extracteur déterministe (1 KPI, sortie JSON contractuelle).
- `tests/test-kpis-writer.sh` — 9 tests (schéma, agrégation, garde-fou source→low, robustesse, idempotence). 9/9 ✅.

**Références** : contrat de données (mappe les 2 tables Hub), barème confidence↔source + EVALS, KPIs par
domaine, Tier 2 acquisition human-gated, hook SessionEnd.

### Décisions de conception (vs brief initial `AGENT_KPI_METIER_BRIEF.md`)

- **Séparation schéma / valeurs** : schéma gelé+validé (`lab_kpi_configs`) vs valeurs time-series (`kpis`).
  Évite la dérive des `key` qui casserait la série temporelle du Hub.
- **Extraction machine-enforced** : l'agent écrit des extracteurs une fois, puis les exécute — pas de
  re-déduction LLM (idempotence réelle, doctrine « enforcement > prose »).
- **2 tiers** : Tier 1 (interne, zéro accès externe) livré ; Tier 2 (connecteurs externes) documenté,
  **human-gated**, non construit — de-risque la livraison et la sécurité.
- **`KPIS.md` = 6e registre canon** (`.claude/memory/`), cohérent avec DECISIONS/LEARNINGS/BLOCKERS/JOURNAL/EVALS.
- **Module unique partagé** paramétré par domaine (bundles), jamais dupliqué par lab.
- **Confidence ↔ source** : sans source vérifiable → `low` + grisé ; jamais de chiffre inventé.
