# Changelog — conductor

## v1.0.0 — 2026-06-11

Release initiale. Agent méta orchestrateur central + gardien du framework, distribué dans chaque lab.
Comble 4 trous identifiés à l'audit du plugin (cf. README).

### Ajouté
- **Agent `vibeflow-conductor`** (AGENT.md, ≤250L) — porte d'entrée méta pour configurer/vérifier/
  mettre à jour/migrer un lab. Route et délègue (installeur, validator, planning-core, consolidator).
  4 rôles : configurateur / vérificateur / calibreur / gardien. N'est pas appelé en continu.
- **C2 — `vf-new-lab`** : bootstrap de lab **universel** (non-dev en première classe). Cadrage 5
  questions (ce que l'utilisateur sait déjà) → dérivation → scaffolding adapté au métier. Exemple
  « acquisition » de bout en bout. Ne présume jamais dev.
- **C3 — `vf-calibrate`** + `scripts/framework-version.sh` : propagation d'update façon GSD.
  Détection de drift framework ↔ lab (current/recorded/stamp/drift, sémver portable), migration sous
  validation humaine, surfaçage SessionStart **opt-in**. + tests (8/8 PASS).
- **C4 — `references/contracts.md`** : protocole d'escalade sous-agents → conductor (gardien central).
- Références on-demand : `conductor-pipeline.md`, `migration-playbook.md`, `bootstrap-method.md`.

### Notes
- `type: agent + skills + scripts + references`. `requires: [planning-core, validator]`.
- Respecte ADR-031 (détecter/proposer, jamais corriger/migrer sans validation humaine), ADR-029
  (densité), ADR-030 (skills natifs, déléguer sans réimplémenter).
- Ne fait JAMAIS le travail métier — il configure et garde le lab.
