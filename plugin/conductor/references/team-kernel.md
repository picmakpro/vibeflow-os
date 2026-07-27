# Team-kernel — le socle d'orchestration d'équipe, transverse à tous les métiers

> **Rôle** : le noyau réutilisable qui fait tourner une équipe d'agents (manager → workers →
> juges) dans N'IMPORTE QUEL métier — dev, design, contenu, growth, dossier… Extrait du
> dev-orchestrator (ADR-053, éprouvé en mission) et hébergé par le conductor (socle mandatory)
> pour être disponible dans tout lab. Le dev-orchestrator est l'**implémentation de référence** ;
> l'équipe design est la première instanciation non-dev.
>
> Chargement on-demand. Chemin d'install : `.claude/agents/conductor-references/team-kernel.md`
> (les scripts, eux, vivent à plat dans `.claude/scripts/` comme tous les scripts de modules).

---

## Ce que le kernel fournit (invariant, quel que soit le métier)

| Brique | Script / contrat | Garantie |
|---|---|---|
| **Verrou de driver** | `driver-lock.sh` (acquire / heartbeat / release, TTL + recovery) | une seule mission pilote à la fois ; reprise propre d'un lock périmé |
| **Plan de bataille** | `dag.sh` (init / add --deps / ready / mark / reopen) | contrôle de flux déterministe ; la frontière `ready` est une **liste à dispatcher en parallèle** quand les périmètres sont disjoints |
| **Rapports typés** (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[{severity, action: auto-fix\|no-op\|ask-user, ref}], noeuds_debloques[] }` | fin de l'interprétation de prose ; escalade humaine impérative sur `ask-user` |
| **Halt conditions** | 5 codes (P11) : boucle sans progrès · action destructive · ressource manquante · budget épuisé · drift de scope | l'humain arbitre en 30 s sur un message structuré |
| **Digest de mission** | ≤ 30 lignes injectées dans chaque mandat (le disque fait foi) | amortit les relectures de contexte par étage |
| **Cloisonnement par tools** (P12) | juges sans Write/Edit ; workers sans Task ; allowlist `Agent(...)` ; `vf-internal: true` | anti-triche machine-enforced, linté par `check-agents.sh` |

## Ce que chaque métier paramètre (et RIEN d'autre)

1. **Les spécialistes** : un manager (opus, seul à voir large), des producteurs (sonnet), des
   juges frais read-only (sonnet). Templates : `templates/agents/` du module reference
   (orchestrator-template, lead/explorer/reviewer/tester) + `metier-orchestration`.
2. **La définition de « vert »** : dev = tests qui passent ; design = critique scorée contre la
   direction artistique ; contenu = gates de clarté + validation humaine ; etc. Le kernel ne
   connaît pas la nature de la preuve — il exige seulement qu'elle soit **machine-vérifiable ou
   scorée par un juge frais**, et rendue en rapport typé.
3. **Les gates métier** : quels étages tournent par étape (build/test/audit en dev ;
   craft/critique/recette en design…), et lesquels tournent **en parallèle** (tous les juges
   read-only le peuvent, par construction).
4. **Le vocabulaire du rapport** : libre — le bloc typé, lui, est invariant.

## Règles d'instanciation

- **Un manager ne produit jamais** (P3) : il lit, planifie (DAG), dispatche la frontière,
  synthétise. Toute production vit dans les workers.
- **Dispatch parallèle par défaut** : ≥ 2 nœuds `ready` à périmètres disjoints → un seul
  message, plusieurs Task. Périmètres douteux → séquentiel ou `isolation: worktree`.
- **Digest dans chaque mandat**, détail sur disque, bloc typé au retour — jamais de pilotage
  à la prose.
- **Proportionnalité** : en dessous du seuil d'équipe du métier (dev : `SEUIL_EQUIPE`,
  `mission-contracts.md`), pas de manager — la brique outillée directe suffit. Le kernel est
  fait pour les missions, pas pour le quotidien.
- **Escalades** : tout ce que la doctrine du lab réserve à l'humain (ADR-031) court-circuite
  l'autonomie, quel que soit le métier.

## Implémentations

| Équipe | Module | Manager | Workers | Juges | « Vert » |
|---|---|---|---|---|---|
| Dev (référence) | dev-orchestrator | `vf-dev-manager` | `vf-coder` (+ `vf-crafter` en étage design croisé) | `vf-reviewer`, `vf-auditer` (+ `vf-design-judge` en étage design croisé) | tests + revue PASS (+ critique ≥ seuil si étage design) |
| Mobile (boucle test) | mobile-test-team | `vf-test-orchestrator` | `vf-app-fixer`, `vf-test-runner` | (le test EST le juge) | flows Maestro verts |
| Design | design-orchestrator | `vf-design-manager` | `vf-crafter` (+ `vf-coder` en étage implémentation croisé) | `vf-design-judge` (+ `vf-reviewer` en étage implémentation croisé) | critique scorée ≥ seuil contre la DA (+ revue PASS si implémentation) |

Étages croisés (Phase 15) : chaque manager peut dispatcher des workers/juges de l'autre métier —
JAMAIS l'autre manager (Pattern A, prouvé bloquant par test T1). Cette interdiction devient
machine-enforced (allowlists `Agent(...)` + `check-agents.sh`) sur le nœud dédié D-07 de la
phase — pas encore livrée à cette étape. Le lock, le DAG et le rapport restent uniques, portés
par le seul manager de la mission.

Doctrine détaillée côté dev (le protocole complet de mission) :
`dev-orchestrator-references/mission-flow.md` — c'est la référence d'usage du kernel. Doctrine
des étages croisés (quand les insérer, forme DAG, budgets, invariants) :
`dev-orchestrator-references/mission-cross-team.md`.
