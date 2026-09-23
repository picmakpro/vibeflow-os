---
name: collaboration-sam
description: Willy et Sam se partagent le plugin VibeFlow en deux polarités — qui possède quels modules, et où sont les vraies zones de collision git
metadata:
  type: project
---

Le repo `vibeflow-os` est développé à deux, sur deux polarités disjointes :

- **Willy** (`picmakpro`, aussi `Le_Gouverneur_Ai`) — polarité **gouvernance & labs métier (non-dev)** :
  `conductor`, `planning-core`, `installer`, `consolidator`, `skill-creator`,
  `infrastructure-audit`, `audit-architecture`, `validator`, et les bundles métier
  (`business-pilot-bundle`, `content-bundle`, `growth-bundle`, `kpi-analyst`).
- **Sam** (`Samuel Neveu`) — polarité **dev** : `dev-orchestrator`, `mobile-test`,
  `mobile-test-team`, `software-architecture`. Contributeur majoritaire en volume.

**Zones réellement disputées** (constaté sur l'historique, pas supposé) :
1. Les trois fichiers de version — `VERSION`, `plugin/.claude-plugin/plugin.json`,
   `.claude-plugin/marketplace.json` — que toute release touche (CLAUDE.md impose le bump
   des trois + les deux README). C'est la source n°1 de conflits.
2. `.planning/STATE.md` : fichier **mono-position**, incapable de décrire deux chantiers
   parallèles. `.planning/` est versionné (79 fichiers) ; `.claude/` est gitignoré.
3. Secondairement : `plugin/_internal/`, `plugin/reference/`, `plugin/conductor/`.

**Why:** Willy a demandé comment éviter que les deux polarités se marchent dessus. Son
intuition initiale était de dé-versionner `.planning/` ; l'analyse montre que le conflit
vient de la *forme* des fichiers (mono-position, bump partagé), pas du partage.

**How to apply:** Ne jamais proposer de dé-versionner `.planning/` (ce serait renier le
dogfood planning-as-code et perdre les snapshots de milestones). Proposer à la place :
bump de version réservé à un commit de release dédié sur `main` par une seule main ;
`merge=union` dans `.gitattributes` sur les fichiers append-only ; `gsd-pr-branch` pour des PR
filtrées de `.planning/` (exige de ne jamais mélanger `plugin/` et `.planning/` dans un même
commit). Voir [[willy-perimetre-gouvernance]].

⛔ **Ne PLUS proposer `gsd-workstreams` pour partitionner l'état** — tenté le 2026-08-02 (PR #27),
**fermé** sur revue de Sam. Trois motifs, tous vérifiés et non spéculatifs :
1. Le pointeur de workstream est indexé sur le chemin absolu réel
   (`active-workstream-store.cjs:93`, `realpathSync.native`) → chaque worktree repart sans
   workstream résolu. **Incompatible avec l'ADR-064** (isolation multi-session par worktree,
   tranchée le 2026-08-01) : deux réponses au même problème, qui ne se composent pas.
2. Couverture amont à 18 % — 16 workflows gsd-core 1.9.0 sur 91 connaissent les workstreams, 37
   codent en dur `.planning/ROADMAP.md` / `STATE.md` / `phases/`.
3. Outillage du lab non aligné : hook de démarrage qui repasse en « feuille de route absente »,
   `init.phase-op` sensible à la forme d'argument, `state.record-session` qui écrase
   `total_phases` et laisse des lignes orphelines, aucun agent `vf-*` ne passe `--ws`.

**Le sujet appartient désormais à Sam (Phase 27).** Le diagnostic d'origine reste juste —
`ROADMAP.md` et `STATE.md` sont mono-position — mais la solution ne se décide plus côté
gouvernance. En attendant : un **jalon distinct dans la ROADMAP partagée** suffit, la vraie
collision portant sur `STATE.md`.

⚠️ **Piège vérifié, à ne pas réintroduire** : une fusion partition ↔ branche de phase peut produire
**zéro conflit git** tout en laissant une phase orpheline à la racine pendant que le STATE la
déclare en cours (5 484 lignes divergentes, silencieuses). Voir
[[verifier-fraicheur-avant-audit]] — l'absence de conflit git n'est pas une preuve d'intégrité.
