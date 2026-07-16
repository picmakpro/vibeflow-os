# CHANGELOG — growth-bundle

## [v1.1.0] — 2026-07-16 (ADR-048 — orchestrateur métier)

### Modifié
- Contradiction levée : `channel-strategist` est déclaré explicitement comme l'**orchestrateur métier** du
  bundle (instance du pattern ADR-048, câblé au skill `metier-orchestration`) — plus de « aucun orchestrateur
  re-codé » qui contredisait son rôle. Le `conductor` reste méta.

## [v1.0.1] — 2026-07-05 (ADR-044)

### Corrigé
- BUNDLE.md : l'énumération d'instanciation inclut `description` (idem content-bundle).

Toutes les évolutions notables de ce bundle métier sont consignées ici.
Format : [SemVer]. Dates : YYYY-MM-DD.

---

## v1.0.0 — 2026-06-11

### Ajouté

- **Manifeste de bundle** (`content/BUNDLE.md`) : métier growth/acquisition (GrowthFlow), profil de
  rigueur planning **standard**, extension de domaine **`growth/` organisée PAR CANAL D'ACQUISITION**,
  vocabulaire métier (canal / séquence / ICP / offre / expérience / CAC / ROAS), liste des 3 agents,
  modules recommandés, et le **flux d'instanciation** consommé par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`) prêts à instancier en agents natifs ≤250L (ADR-029) :
  - `channel-strategist.blueprint.md` (opus) — orchestrateur growth, décide activation/kill de canal,
    alloue budget, priorise les expériences. NE RÉDIGE NI N'ANALYSE lui-même.
  - `copywriter-sequences.blueprint.md` (sonnet) — rédige/itère séquences & créatives PAR CANAL.
  - `campaign-analyst.blueprint.md` (sonnet) — renseigne METRICS, calcule CAC/ROAS, tient EXPERIMENTS.
- **Spécification d'extension de domaine** (`content/domain/extension-spec.md`) : structure exacte de
  `growth/` (niveau global + niveau canal à 5 fichiers identiques + `channels/_TEMPLATE/`).
- **Spécification des registres** (`content/registres.md`) : 5 registres canon (DECISIONS / LEARNINGS /
  BLOCKERS / JOURNAL / EVALS), convention d'IDs, répartition par agent, pont planning↔mémoire.
- **Garde-fous métier** : RGPD prospects (interdits CLAUDE.md), seuils CAC/ROAS CIBLE vs ALERTE
  rouge(kill)/orange(itérer) par canal, tag-canal obligatoire en LEARNINGS, gate `audit-architecture`
  (verdict bloquant anti-slop avant lancement de campagne), nommage kebab-case.

### Châssis doctrine ré-embarqué

- Principes Core P1/P3/P4/P5/P7/P8/P9 référencés (jamais redupliqués).
- Wiring `planning-core` (socle `.planning/` + profil standard + extension nommée selon le métier).
- Wiring `conductor` (orchestration méta déléguée — le bundle ne re-code aucun orchestrateur).
- Auditeurs câblés : agent `vibeflow-validator` + skill `audit-architecture`.
- Pont planning↔mémoire à propriétaire unique (D-NN en `PROJECT.md` → promotion DECISIONS).
