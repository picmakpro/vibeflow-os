# Questions de recherche ouvertes

Fichier alimenté par `/gsd-explore` (Step 4, « Research question »). Une question fermée est
déplacée vers le rapport ou l'ADR qui l'a tranchée, jamais supprimée sans renvoi.

## 2026-09-16 — équipe produit VibeFlow (session /gsd-explore, graine SEED-001)

Restent ouvertes après la session ; aucune ne bloque la graine, toutes conditionnent le cadrage.

- **RQ-EP-01 — Migration d'un renommage de front door dans un lab installé.** La Phase 40 a renommé
  `vibeflow-dev` → `vibeflow-head` : qu'est-ce que `/vf-calibrate` et `/vf-update` ont dû faire dans un
  lab réel (agents posés, mémoire per-projet `.claude/agent-memory/`, hooks, index GSD) ? Mesurer sur
  un lab avant de promettre N renommages BMAD.
- **RQ-EP-02 — Contexte par rôle en SessionStart.** Le rapport ICM du 2026-08-15
  (`reports/research/2026-08-15-icm-deep-search.md`, G2 « CONTEXT.md par compartiment ») donne-t-il un
  format réutilisable pour un `CONTEXT.md` par rôle, et le relais SessionStart existant (mémoire
  per-projet en scope user) peut-il le porter sans nouveau hook ?
- **RQ-EP-03 — Profil planning-core « product ».** Les 3 profils de rigueur de `planning-core`
  (`references/PROFILES.md`) sont des curseurs de rigueur, pas de vocabulaire : un profil « product »
  qui change le gabarit de `PROJECT.md`/`REQUIREMENTS.md` est-il un 4e profil ou une dimension
  orthogonale (rigueur × rôle) ?
- **RQ-EP-04 — Gate architecture, existant à assembler.** Samuel désigne `software-architecture`
  (expertise senior, gates de feature) + GSD (`gsd-map-codebase`, `gsd-graphify`) pour la
  connaissance du système de fichiers. Quel script existant rend rouge quand une phase proposée
  suppose une décision structurante absente de `docs/ADR.md` ? S'il n'existe pas, le gate est à
  écrire, pas à réutiliser.
- **RQ-EP-05 — Marqueur de validation de phase.** Où porter « proposée par / validée par » sur une
  phase : frontmatter d'un fichier de phase, ligne de `ROADMAP.md`, ou `state.json` ? Contrainte :
  `check-state-integrity.sh` et `gsd-phase` (CRUD amont) ne doivent pas le perdre à la réécriture.
- **RQ-EP-06 — Interception d'un skill par hook.** Un hook `PreToolUse` sur `Skill` est-il
  supporté par Claude Code ET par les runtimes Codex/Kimi (Phase 38) ? Non retenu pour le premier
  jalon (advisory choisi), à garder pour un durcissement ultérieur.
