# Registre des Décisions d'Architecture (ADR) — vibeflow-os

> Registre versionné du repo (le template framework cible `.claude/memory/ADR.md`, mais ce
> chemin est gitignoré ici — le repo de distribution versionne ses ADR dans `docs/`).
> Gestion : lire l'index d'abord, charger le détail d'une ADR seulement si nécessaire.
> Les ADR antérieures à ce registre (ADR-001 → ADR-045) prédatent sa création : leur trace
> vit dans les CHANGELOG des modules, les rules et les specs (`docs/superpowers/specs/`).

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| ADR-046 | 2026-07-09 | Équipe manager de mission — arborescence à contexte minimal | Validée |
| ADR-047 | 2026-07-19 | Allowlist MCP des agents exécutants dérivée du lab (injection à l'install) | Validée |

---

## ADR-046 : Équipe manager de mission — arborescence à contexte minimal

**Date** : 2026-07-09
**Statut** : Validée
**Décideur** : Samuel (brainstorming + décisions DM1-DM6 verrouillées en session)
**Contexte** : release v2.23.0 — dev-orchestrator v1.5.0 (PR #12)

### Problème

Le pilotage dev de VibeFlow reposait sur un router (`vibeflow-dev`) qui invoque les skills GSD
dans le contexte courant. Sur une mission multi-étapes, ce contexte gonfle, se fait compacter,
et la conversation principale devient illisible ; `gsd-autonomous` (boucle inline) souffre du
même mal et n'embarque aucune doctrine VibeFlow (ADR-045, ADR-031, vocabulaire).

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Router = bras coder d'un manager | Zéro duplication du pilotage GSD | Couple le router à l'équipe |
| **Deux entrées parallèles (retenue)** | Router intact pour le quotidien ; équipe dédiée pour les missions | Léger doublon de pilotage GSD router↔coder (assumé, DM1) |
| Manager unique absorbant le router | Un seul sommet | Contredit le besoin de garder le router séparé |

### Raisonnement

> Pattern éprouvé sur le projet Reviz (`WillHosting/.claude/agents/`) : main → manager →
> workers spécialisés, chacun à contexte minimal scopé. Analyse comparative avec
> `gsd-autonomous` : même machinerie GSD par phase (qualité identique sur une phase), mais
> l'inline dégrade sur les runs longs (compaction) là où les contextes frais des workers
> restent stables. gsd-autonomous garde l'avantage coût sur 1-2 phases → bascule par taille
> plutôt que remplacement. Le manager reprend les acquis de contrôle de flux de
> gsd-autonomous (routing VERIFICATION, gap-closure 1 retry, handle_blocker, lifecycle)
> pour ne pas les perdre (DM6).

### Décision

1. **Topologie (DM1)** : deux entrées parallèles — router direct (inchangé) ET équipe manager
   (`vf-dev-manager` + workers dédiés `vf-coder`/`vf-reviewer`/`vf-auditer`, `vf-internal`).
2. **Bascule (DM2)** : `vf-auto` aiguille — N < `SEUIL_EQUIPE` (3) et pas de signal durée →
   `gsd-autonomous` inline ; sinon → équipe. Le signal durée gagne.
3. **Packaging (DM3)** : extension du module `dev-orchestrator` (pas de nouveau module).
4. **Invocation (DM4)** : le router détecte les signaux mission et PROPOSE l'équipe — jamais
   de dispatch d'office, pas de verbe nouveau.
5. **Généricité (DM5)** : zéro chemin/règle Reviz ; conventions `.planning/` de GSD ; les
   règles de livraison viennent du CLAUDE.md du projet cible.
6. **Contrôle de flux (DM6)** : le manager reprend les mécanismes éprouvés de gsd-autonomous.

### Conséquences

**Positives** : conversation principale légère (travail long possible sans saturation),
doctrine VibeFlow portée par le manager, arborescence de sessions lisible, workers isolés.
**Négatives** : doublon assumé de pilotage GSD (router↔coder, mitigé par renvois aux mêmes
références) ; deux moteurs autonomes à maintenir (inline + équipe, rendus explicites par le
seuil) ; ~10-30 % de tokens en plus sur une mission (rechargement de contexte par worker).

### Code Impacté

- `plugin/dev-orchestrator/agents/` — `vf-dev-manager.md`, `vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md`
- `plugin/dev-orchestrator/references/mission-contracts.md` — contrats (source unique)
- `plugin/dev-orchestrator/AGENT.md` — heuristique 7, ligne de table, anti-pattern
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` — Étape 0 (aiguillage)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — T8-T11
- Spec : `docs/superpowers/specs/2026-07-09-dev-manager-team-design.md` · Plan : `docs/superpowers/plans/2026-07-09-dev-manager-team.md`

### Rules Associées

- Aucune rule nouvelle (DM4 : détection côté agent, pas de gate machine). Les gates existants
  s'appliquent : `check-agents.sh` (ADR-044), densité (ADR-029).

---

## ADR-047 : Allowlist MCP des agents exécutants dérivée du lab (injection à l'install)

**Date** : 2026-07-19
**Statut** : Validée
**Décideur** : Samuel (brief de correction + choix « A+B complet » verrouillé en session)
**Contexte** : release v2.24.0 — dev-orchestrator v1.6.0, mobile-test-team v1.2.0, conductor v1.9.1

### Problème

Un sous-agent dispatché via l'outil `Task` **n'hérite pas** des serveurs MCP de la session : côté
MCP, il ne voit que ce que son `tools:` autorise explicitement. Les agents **exécutants** de VibeFlow
(`vf-coder`, `vf-app-fixer`, `vf-test-runner`, `vf-test-orchestrator`) portent une allowlist `tools:`
**fermée** sans entrée MCP. Conséquence : sur tout lab dont le projet s'appuie sur un serveur MCP
(XcodeBuildMCP pour l'iOS natif, mais aussi mobile-mcp, une DB, un navigateur, un cloud), l'agent qui
**compile/teste/corrige** ne voit pas l'outil `mcp__<serveur>__*`. Seule la fenêtre principale l'a —
ce qui casse la délégation autonome (`vf-auto`, `vf-dev-manager`). Symptôme réel observé : un lab iOS
Swift où `vf-coder` a rapporté à tort « XcodeBuildMCP absent, redémarrer Claude Code ».

Le même mal touche `gsd-executor`, mais **il n'appartient pas au plugin** (fourni par GSD, posé dans
`~/.claude/agents/`).

### Contrainte technique décisive

Le glob générique **`mcp__*` n'est PAS accepté dans `tools:`** (doc officielle Claude Code : il
n'existe qu'en `disallowedTools`). Seule la forme **par-serveur** `mcp__<serveur>__*` est admise en
allowlist (précédent : `mcp__context7__*`, déjà présent dans plusieurs agents GSD). Le correctif « une
ligne wildcard » du brief initial est donc **impossible** : il faut nommer chaque serveur — sans pour
autant clouer un serveur stack-spécifique (XcodeBuildMCP est Apple ; `dev-orchestrator` est
multi-stack) dans un agent générique.

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Hardcoder `mcp__XcodeBuildMCP__*` dans les agents | Immédiat | Couple les agents génériques à Apple ; ne couvre pas les MCP métier ; contredit le multi-stack |
| A seul — liste statique curatée de serveurs par défaut | Aucune logique d'install | Ne couvre pas un MCP custom non listé ; noms stack-spécifiques dans des agents génériques |
| **A+B — défaut minimal + injection dérivée du lab (retenue)** | Vraiment générique (n'importe quel serveur déclaré) ; moindre privilège par lab ; zéro nom en dur | Logique d'install à écrire + un flag agent |

### Décision

1. **Sélecteur data-driven** : les agents exécutants portent `vf-mcp-consumer: true` (analogue à
   `mandatory:` / `vf-internal:`). Les agents de planif/revue/audit (`vf-dev-manager`, `vf-reviewer`,
   `vf-auditer`) **restent inchangés** (moindre privilège — ils ne compilent jamais). Champ ajouté au
   `KNOWN` de `check-agents.sh`.
2. **Injecteur idempotent** `dev-orchestrator/scripts/inject-mcp-tools.sh` : lit les serveurs du
   `./.mcp.json` du lab et injecte `mcp__<serveur>__*` dans le `tools:` des fichiers flaggés (ou d'un
   fichier `--force` pour `gsd-executor`). Aucun nom de serveur ni d'agent en dur. Best-effort.
3. **Câblage** : hook post-install dans `vibeflow-update.sh` (à chaque pose d'agents) ; patch
   `gsd-executor` dans `ensure-deps.sh` après l'install GSD (re-jouable → auto-réparateur après une
   réinstall GSD) ; ré-affirmation dans `/vf-calibrate` quand le `.mcp.json` évolue sans bump.

### Conséquences

**Positives** : la délégation autonome fonctionne sur tout lab à MCP (iOS, mobile, métier) ; moindre
privilège réel (chaque lab n'obtient que ses serveurs déclarés) ; générique et sans dépendance Apple
imposée ; enforcement machine cohérent avec la philosophie « scope-aware ».
**Négatives** : le `tools:` est lu au **démarrage de session** → un **redémarrage de Claude Code** est
requis après (ré)install pour que l'allowlist prenne (documenté dans les CHANGELOGs) ; la source est
le `./.mcp.json` **projet** — un serveur configuré uniquement au niveau user n'est pas injecté (par
conception : moindre privilège, alignement sur le brief).

### Cloisonnement anti-triche (Pattern 12) — inchangé

La séparation `Read/Write/Edit` entre `vf-test-runner` (écrit les tests) et `vf-app-fixer` (écrit le
code) reste le garde-fou. On n'injecte que des serveurs de **build/test** déclarés par le lab, pas
d'accès web/doc : `vf-app-fixer` conserve son interdiction ADR-045 (pas de context7/web ; escalade
`doc-research-required`). Orthogonal, vérifié.

### Code Impacté

- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (nouveau) + `scripts/tests/test-inject-mcp-tools.sh` (nouveau, 10 cas)
- `plugin/dev-orchestrator/agents/vf-coder.md` — flag `vf-mcp-consumer: true`
- `plugin/mobile-test-team/agents/` — `vf-app-fixer.md`, `vf-test-runner.md`, `vf-test-orchestrator.md` — flag
- `plugin/conductor/scripts/check-agents.sh` — `KNOWN += vf-mcp-consumer`
- `plugin/_internal/vibeflow-update.sh` — `find_mcp_injector` + `inject_lab_mcp_into_agents` (hook post-install)
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` — `patch_gsd_executor_mcp` (post-install GSD)
- `plugin/conductor/skills/vf-calibrate/SKILL.md` — étape de ré-affirmation MCP

### Rules Associées

- Aucune rule nouvelle. Gate machine existant : `check-agents.sh` (ADR-044) accepte le flag ; le
  sélecteur `vf-mcp-consumer` EST le point d'enforcement (data-driven, aucun nom en dur).
