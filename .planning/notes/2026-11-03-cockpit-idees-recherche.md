# Cockpit — idées au-delà des Phases 67 à 72 (recherche du 2026-11-03)

**Statut :** inscrites au jalon `vibeflow-v2.0` en Phases 73 à 77 (arbitrage Samuel, AskUserQuestion session
principale, 2026-11-03 : « toutes les propositions sont bien, intègre-les au jalon », découpage « 5 phases
thématiques (Recommandé) », ordre « Gouvernance tôt, reste après 72 (Recommandé) »). Aucune n'est cadrée.

**Complément du 2026-11-11 :** l'audit du cockpit du 2026-11-10 (`.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2) donne
une entrée de cadrage à chacune de ces phases. Il corrige deux points de la table ci-dessous pour l'idée 1 : les horodatages sont dans
les transcripts, `meta.json` n'en porte aucun ; et « colorée par nœud de DAG » (but de la Phase 74) contredit `DESIGN.md` § 9, le nœud
s'écrit sur la voie, la couleur reste aux états.

## Contraintes communes (reprises du cockpit livré)

- Traces locales seulement, aucune lecture réseau (suite de CKPT-03 ; CI, PR, merge hors carte comme en 69).
- Lecture seule sur `.planning/` ; calcul dans le socle, schéma versionné.
- Un ajout = un retrait (SOBR-01..08) : chaque phase nomme son retrait au cadrage.
- Libellés en français ; rendu en texte, CSP inchangée.

## Ce que montrent les outils comparables

- Tableaux de bord d'agents Claude Code (agents-observe, disler/claude-code-hooks-multi-agent-observability,
  skill agent-observability) : hiérarchie parent / sous-agent, swim-lanes d'agents parallèles, replay de session,
  jetons par modèle ; tous alimentés par les hooks (PreToolUse, PostToolUse, SubagentStop).
- Observabilité LLM (Langfuse, W&B Weave) : waterfall de spans imbriqués avec latence et coût, « traces les plus chères »,
  coût moyen par type d'agent.
- Analyse de code par l'historique (CodeScene) : hotspots (fréquence de changement × complexité), couplage de changement,
  îlots de connaissance.
- Tableaux de bord d'ingénierie (Cortex, LinearB, Metabase, Jellyfish) : cycle découpé par étape, burn-up, travail en cours,
  métriques lues en tendance plutôt qu'en classement.

## Les 16 idées et leur phase

| # | Idée | Phase | Source locale envisagée |
|---|------|-------|-------------------------|
| 9 | File des arbitrages en attente (décisions qui attendent Samuel, reliées à leur phase et à ce qu'elles bloquent) | 73 | `*-CONTEXT.md` (décisions préfixées `P<n>-D-xx`), DAG de mission |
| 13 | Worktrees, branches et verrous (qui tient `driver-lock`, worktrees et leur travail non commité, serveurs orphelins) | 73 | `git worktree list`, registre `driver-lock.sh`, `.vibeflow/cockpit/.cache/` |
| 4 | Alerte du watchdog sur le nœud concerné | 73 | sortie de `mission-watchdog` |
| 1 | Swim-lanes des agents (une ligne par agent sur un axe de temps) | 74 | `meta.json` des sous-agents (horodatages) |
| 2 | Coût par mission, phase et agent (jetons, durée) | 74 | champ `usage` des transcripts `.jsonl` |
| 3 | Replay d'une mission (curseur temporel sur le DAG) | 74 | transitions des DAG de mission, historique git |
| 5 | Hotspots sur la carte Code (fréquence de changement × taille) | 75 | `git log` local |
| 6 | Couplage de changement (fichiers qui changent ensemble) | 75 | `git log` local |
| 7 | Carte des gardes (fichiers couverts par quel gate ou suite, zones sans témoin) | 75 | `ci.yml`, motifs de `check-gate-touche.sh` |
| 8 | Empreinte des agents (fichiers lus ou modifiés par la mission en cours) | 75 | transcripts (nom d'outil et cible, jamais le contenu) |
| 10 | Traçabilité exigence → plan → SUMMARY → VERIFICATION → recette, trous en rouge | 76 | `REQUIREMENTS.md`, dossiers de phase |
| 11 | Graphe des décisions (ADR ↔ arbitrages ↔ commits qui les citent) | 76 | `docs/ADR.md`, `*-CONTEXT.md`, `git log` |
| 14 | Graphe de la mémoire (liens `[[...]]`, mémoires orphelines ou périmées) | 76 | mémoires d'agents du lab |
| 12 | Santé de la méthode (jauges : densité agents, skills, ROADMAP, BACKLOG, baseline d'instructions) | 77 | `check-*.sh`, baseline du budget d'instructions |
| 15 | « Depuis ta dernière visite » (ce qui a changé) | 77 | état précédent mémorisé côté navigateur ou socle |
| 16 | Burn-up du jalon (phases closes dans le temps, pourcentage strict) | 77 | dates git, cases du ROADMAP |

## Sources

- https://awesome.ecosyste.ms/projects/github.com%2Fsimple10%2Fagents-observe
- https://docsearch.algolia.com/mcp/docs/repo/disler/claude-code-hooks-multi-agent-observability
- https://www.pulse.bot/ai/news/show-hn-real-time-dashboard-for-claude-code-agent-teams-298d7a5e-8671-43f1-b26a-dd21730d9a63
- https://skillsmp.com/ar/creators/zpankz/mcp-skillset/agent-observability
- https://blog.elest.io/self-host-langfuse-to-trace-your-ai-agents/
- https://research.aimultiple.com/agentic-monitoring
- https://thectoclub.com/fr/tools/avis-codescene/
- https://docs.cortex.io/eng-intelligence/dora-dashboard
- https://www.metabase.com/dashboards/engineering-teams
- https://jellyfish.co/library/developer-productivity/dashboard/
