# Mission — Phase 15 : Collaboration inter-équipes dev ↔ design

**Date** : 2026-07-27 · **Manager** : `vf-dev-manager` · **Owner du lock** : `mission-phase15`
**Commit de base** : `fce848d` · **HEAD à la clôture** : `a8eeebf` · **17 commits**, 18 fichiers, +406/−38
**Mode** : autonome (planification + exécution de bout en bout)

---

## Plan de bataille (DAG, 9 nœuds)

```
recon (research) ────┐
contracts (build) ───┴→ managers ─┬→ tests → gates ─┬→ release-meta
         └───────────→ routing ───┘                 │
                       managers ──→ verif-allowlist ┘
                       (+ portee, ajouté en cours après finding de revue)
```

Deux frontières dispatchées en parallèle (périmètres de fichiers disjoints, déclarés dans chaque
mandat) : `recon ∥ contracts`, puis `managers ∥ routing`. Une ré-entrée (`dag.sh reopen managers`)
déclenchée par l'audit d'allowlist. Un nœud ajouté en cours de mission (`portee`) sur finding
bloquant de la revue. Clôture : 9/9 `done`, worktree propre.

---

## Livré, étape par étape

### 1. `contracts` — contrats et doctrine croisée (PASS)
- `mission-contracts.md` §Brief : champs `design: auto|force|off` (défaut `auto`) et
  `livrable: specs|specs+implementation` (défaut `specs`). §Digest : variantes croisées (D-10) —
  mandat dev→crafter/judge embarque la DA en 3-5 lignes ; mandat design→coder/reviewer embarque les
  conventions code et pointe la spec du crafter comme source du cadrage.
- **Nouvelle référence** `plugin/dev-orchestrator/references/mission-cross-team.md` (88 l.) —
  la doctrine croisée, chargée on-demand. Ancres : `## Étage design (mission dev)`,
  `## Étage implémentation (mission design)`, `## Invariants non négociables`.
- `mission-flow.md` : « Pattern D » (9 l. de renvoi, aucune doctrine dupliquée).
- `team-kernel.md` : table « Implémentations » reflétant les étages croisés.

### 2. `managers` — étages croisés et allowlists (PASS après ré-entrée)
- `vf-dev-manager.md` (186/250) : étage design — `craft:<écran>` via `vf-crafter` avant l'exécution,
  `critique:<écran>` via `vf-design-judge` en parallèle de la revue ; jugement du manager au plan de
  bataille, brief prioritaire, granularité nouvel écran/refonte, seuil 70/100 bloquant avec reopen
  (3 tours), absence de `DESIGN.md` → étage sauté + DA-INIT proposé.
- `vf-design-manager.md` (155/250) : étage implémentation opt-in, `vf-coder` cadré sur la spec du
  crafter, double juge parallèle, budgets 3+3, recherche doc ADR-045 héritée.
- Allowlists `Agent(...)` : 18 noms (dev), 6 noms (design). Aucune ne contient l'autre manager.

### 3. `routing` — aiguillage et descriptions (PASS)
- `vf-auto/SKILL.md` : règle D-11 binaire (mission entièrement design → `Task(vf-design-manager)` ;
  toute mission mixte ou dev → `Task(vf-dev-manager)`). Répare un chemin de dispatch mort.
- Dispatch documenté élargi sur `vf-coder`, `vf-reviewer`, `vf-crafter`, `vf-design-judge`.
- Signaux de mission alignés dans les deux `AGENT.md`.

### 4. `tests` — axes croisés (PASS)
- T18/T18b (dev) : allowlist testée **nom par nom**, absence de `vf-design-manager`, parenthèse
  fermée, doctrine d'étage design, routage `vf-auto`.
- T8/T8b (design) + T4 **durci** (il acceptait un `Agent` nu).
- T12 (`test-dag.sh`) : DAG hétérogène cross-métier — nœud `craft:ecran-home` non remappé malgré
  le `:`, deux juges cross-métier dans la même frontière.
- Triage du scénario `test-collab-orchestrateurs.sh` : 5 de ses 7 tests étaient des doublons du
  harnais conductor ; seuls T3.2/T3.3 portaient du neuf.

### 5. `portee` — portée réelle du cloisonnement (PASS)
Correction de trois affirmations trop larges + `conductor/README.md`. Dette consignée dans
`.planning/codebase/CONCERNS.md`.

### 6. `release-meta` — bumps par module (PASS)
`conductor` v1.14.5 → **v1.14.6** (patch : doctrine + test, aucun script kernel touché) ·
`design-orchestrator` v1.2.2 → **v1.3.0** (minor) · `dev-orchestrator` v2.3.2 → **v2.4.0** (minor).
`VERSION` racine, `marketplace.json`, `plugin.json`, README racine : **intouchés**.

---

## Étages de vérification — verdicts

| Étage | Verdict | Effet |
|---|---|---|
| `recon` (recensement) | `gaps_found` | A détruit la prémisse de D-07 : le lint n'existe pas |
| `verif-allowlist` (audit indépendant) | `gaps_found` | **4 manques** dans l'allowlist dev → `reopen managers` |
| `gates` (revue `vf-reviewer` du diff complet) | `gaps_found` (bloquant) | Chemin indirect manager→worker→manager → nœud `portee` |
| Suites finales | vertes | 43 dev · 12 design · 36 dag · 26 driver-lock · 0 KO |
| `check-agents.sh --strict` | exit 0 | sur les deux dossiers `agents/` |

### Ce que l'audit indépendant a rattrapé
Le premier recensement avait livré 14 noms ; l'audit, interdit de lire le premier, en a trouvé 18.
Les 4 manquants — `gsd-integration-checker`, `gsd-doc-classifier`, `gsd-doc-synthesizer`,
`gsd-pattern-mapper` — auraient cassé, **silencieusement**, la fin de milestone, l'ingestion de
cadrage (deux étapes sur trois) et la re-validation de plan provisoire. Preuve que c'était une
omission et non un choix : `gsd-roadmapper` figurait bien dans la liste, or il n'est atteignable
que par `gsd-ingest-docs` — le workflow avait donc été ouvert, et seul le 3ᵉ de ses 3 agents retenu.

---

## Laissé de côté, et pourquoi

1. **Écrire le lint `Agent(...)` dans `check-agents.sh`** — extension de périmètre sur un script de
   gate partagé par tous les modules (bump minor sur `conductor`, pas patch). Piège de régression
   identifié : `general-purpose` est un type natif sans fichier `.md`, les agents `gsd-*` viennent de
   `@opengsd/gsd-core` et sont absents d'un lab sans GSD — un lint naïf rendrait rouges des allowlists
   correctes chez les utilisateurs. **Escaladé, non exécuté.**
2. **Scoper l'accès `Agent` de `vf-coder`/`vf-reviewer`/`vf-auditer`** — au-delà de la lettre de D-07
   (« sur les DEUX managers »), et porteur du profil de risque qui a déjà produit 4 omissions : chacun
   de ces workers invoque des skills dont il faudrait recenser exhaustivement les agents. Dette
   consignée. **Escaladé, non exécuté** (ADR-031).
3. **Release racine + tag + release GitHub** — réservé à la validation humaine par le brief.
4. **Intégration « Claude Design »** — différée par le cadrage, backlog roadmap.

---

## Divergence d'environnement notée

`$HOME/.claude/scripts/driver-lock.sh` (6.7K) est **en retard** sur la source du repo (7.8K) : il lui
manque le correctif H1-ABA (double « recovered » observé en CI, T13.1). `dag.sh` est identique.
Attendu tant que la version n'est pas publiée, mais à garder en tête : une mission pilotée depuis le
scope user tournerait sur un verrou moins durci.

---

## Next step proposé

**Publier la release racine.** Les trois modules sont bumpés et cohérents, les 4 suites sont vertes,
`check-release-tag.sh` sort ✓ sur l'état actuel. Il reste à trancher le numéro racine (v2.39.0 →
**v2.40.0**, nouvelle capacité), puis à appliquer la discipline du `CLAUDE.md` : bump des trois
fichiers + historique des deux README, tag annoté `vX.Y.Z`, release GitHub, et
`check-release-tag.sh --remote` → ✓.

À arbitrer avant ou après, au choix : les deux reliquats de cloisonnement (lint `check-agents.sh` et
allowlists des workers), qui feraient une phase courte et cohérente à eux deux.
