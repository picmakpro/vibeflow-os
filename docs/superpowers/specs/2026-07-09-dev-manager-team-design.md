# Spec — Équipe manager de dev (arborescence à contexte minimal)

> Date : 2026-07-09
> Statut : design validé (brainstorming)
> Repo : vibeflow-os
> Origine : pattern d'orchestration éprouvé sur le projet Reviz (`WillHosting/.claude/agents/` :
> manager / coder / reviewer / auditer / test-orchestrator)

## 1. Vision

Aujourd'hui, VibeFlow pilote le dev via un **router** (`vibeflow-dev`) qui invoque les skills GSD
dans le contexte courant. Sur une mission multi-étapes, ce contexte gonfle, se fait compacter, et
la conversation principale devient illisible.

Cible : reproduire l'arborescence Reviz — **une seule conversation main** (tout le contexte
utilisateur), un **manager** dispatché en sous-agent qui planifie/décide/distribue, et des
**workers spécialisés** à contexte minimal qui font le travail :

```
main (l'utilisateur, seule conversation, contexte complet)
│
├─ tâche simple/directe → vibeflow-dev route GSD direct (inchangé)
│
├─ mission détectée → vibeflow-dev PROPOSE le manager → sur OK :
│  └─ vf-dev-manager                    « Manager Phase N »
│      ├─ vf-coder                      cycle GSD discuss→plan→execute
│      │   └─ vf-reviewer               review du diff
│      │       └─ gsd-code-reviewer     (machinerie GSD native)
│      ├─ vf-auditer (si pertinent)     → gsd-security-auditor
│      └─ vf-test-orchestrator          (si projet mobile — module existant)
│
└─ /vf-auto → bascule taille : court → gsd-autonomous · long → manager
```

La valeur : **isolation de contexte** (main reste léger, on travaille longtemps), **doctrine
VibeFlow embarquée** (ADR-045, ADR-031, vocabulaire) là où `gsd-autonomous` est générique, et
**arborescence lisible** (chaque sous-agent visible avec son rôle).

## 2. Analyse préalable (base factuelle)

| Fait | Preuve |
|---|---|
| `gsd-autonomous` tourne inline — tout s'accumule dans le contexte invoquant | `~/.claude/get-shit-done/workflows/autonomous.md` (Skill() flat invocations) |
| Son contrôle de flux est éprouvé : routing VERIFICATION, gap-closure 1 retry, handle_blocker, lifecycle | `autonomous.md` steps 3d, 4, 5, 6 |
| Le `coder` Reviz invoque les mêmes skills GSD — qualité par phase identique | `WillHosting/.claude/agents/coder.md:12-21` |
| Les agents Reviz sont spécifiques (chemins `docs/_mission/`, règles client revizapp) | `manager.md:10`, `coder.md:35` |
| La test-team mobile existe déjà, portage exact de la boucle test Reviz | `plugin/mobile-test-team/agents/` |
| `dev-orchestrator` n'a pas de dossier `agents/` aujourd'hui | arborescence du module |

**Positionnement** : le manager remplace la **boucle externe** de `gsd-autonomous` (itération des
phases, décisions, lifecycle) avec la doctrine VibeFlow ; ses workers réutilisent le **cycle
interne** GSD tel quel. Les deux moteurs coexistent (bascule selon la taille, §5).

## 3. Décisions structurantes (verrouillées)

| # | Décision | Choix |
|---|----------|-------|
| DM1 | Topologie | **Deux entrées parallèles** : `vibeflow-dev` (route directe, inchangé) ET manager (orchestration). Le manager a ses workers dédiés (`vf-coder` neuf, distinct du router). Léger doublon de pilotage GSD router↔coder assumé, limité par référence partagée. |
| DM2 | Moteur autonome | **Bascule selon la taille** dans `vf-auto` : 1-2 phases → `gsd-autonomous` (inline, moins cher) ; ≥ 3 phases OU signal durée (« la nuit ») → manager. Seuil = constante nommée, ajustable. |
| DM3 | Packaging | **Extension de `dev-orchestrator`** (pas de nouveau module) : `agents/` + `references/mission-contracts.md` dans le module existant. Un seul module « cerveau dev ». |
| DM4 | Invocation | **Le router détecte et propose** — pas de verbe neuf. `vibeflow-dev` repère les signaux « mission » et propose le manager (AskUserQuestion) ; jamais de dispatch d'office. |
| DM5 | Généricité | Zéro chemin ni règle Reviz en dur : conventions `.planning/` de GSD ; les règles de livraison viennent du CLAUDE.md du projet cible. |
| DM6 | Contrôle de flux | Le manager **reprend** les acquis de `gsd-autonomous` : routing sur VERIFICATION.md (passed / gaps_found / human_needed), gap-closure limité à 1 retry, handle_blocker 3 options (retry / skip / stop), re-lecture ROADMAP entre phases, lifecycle audit→complete→cleanup. |

## 4. Les 4 agents (`plugin/dev-orchestrator/agents/`)

Tous conformes ADR-044 (frontmatter `description` + `model` + `memory`, validés
`check-agents.sh`) et ADR-029 (≤ 250 lignes ; les originaux Reviz font 25-56 lignes).

| Agent | Rôle | `vf-internal` | Hérite de |
|---|---|---|---|
| `vf-dev-manager` | Sommet. Lit ROADMAP/STATE/PROJECT, **planifie toujours d'abord** (plan de bataille), décide via panels `gsd-advisor-researcher`, distribue (Task), synthétise. Ne code, ne teste, n'audite jamais. | non — orchestrateur exposé, avec commande d'incarnation | `manager.md` |
| `vf-coder` | Pilote le cycle GSD d'une phase (discuss→plan→execute→review). Route, ne réimplémente jamais. Dispatche `vf-reviewer` en sous-phase review, boucle fix→re-review jusqu'au PASS ou budget. | oui | `coder.md` |
| `vf-reviewer` | Revue du diff via `gsd-code-reviewer` (Task) ou skill `gsd-code-review`. **Ni Write ni Edit** — rapport de findings classés par sévérité, verdict PASS / correctifs requis. | oui | `reviewer.md` |
| `vf-auditer` | Audit sécu/dette d'une phase via `gsd-security-auditor`. Recoupe avec `.planning/codebase/CONCERNS.md`. **Ni Write ni Edit.** | oui | `auditer.md` |

**Doctrine embarquée dans le manager** (ce que GSD n'a pas) :
- **ADR-045** : recherche doc obligatoire (context7 + issues GitHub / release notes) avant tout
  debug empirique sur bug lib/framework/natif/version — imposée aux étages, jamais de tâtonnement.
- **ADR-031** : jamais de fix sans validation humaine là où la doctrine l'exige ; en autonomie,
  les zones grises passent par panels advisor, les décisions engageantes (périmètre, suppression)
  remontent à main.
- **Vocabulaire VibeFlow** dans tous les rapports (sprint, feuille de route, recette) — zéro fuite
  « GSD »/« Superpowers » (Iron Law du router, étendue à l'équipe).
- **Étages par phase** : le manager choisit les étages pertinents (une phase UI saute l'audit
  sécu ; une phase sécu le garde). Étage test = `vf-test-orchestrator` si module installé ET
  projet mobile, sinon `gsd-verify-work` (dépendance douce, §7).

## 5. Détection de mission & bascule

### 5a. Router `vibeflow-dev` (AGENT.md)

Signaux « mission » (≥ 1 déclenche la **proposition**, jamais le dispatch d'office) :
- multi-phases explicite (« phases 3 à 5 », « toute la milestone ») ;
- durée/absence (« la nuit », « pendant que je suis pas là ») ;
- étages multiples combinés (« code ça, teste et fais la revue ») ;
- estimation > 1 phase de roadmap.

Proposition type : « C'est une mission multi-étapes — je la confie à l'équipe (manager +
spécialistes) pour garder cette conversation légère, ou je la traite en direct ici ? »
OK → `Task(vf-dev-manager)` avec brief de mission (§6). Refus → routage direct classique.
Tâche simple sans signal → routage direct **sans question** (zéro friction).

Anti-pattern ajouté : ❌ dérouler une mission multi-phases inline dans main alors que le manager
existe.

### 5b. Skill `vf-auto` (aiguillage en tête)

```
N = phases restantes ciblées (gsd-sdk query roadmap.analyze)
├─ N ≤ 2  ET  pas de signal durée  → gsd-autonomous (inline)
└─ N ≥ 3  OU  signal durée         → Task(vf-dev-manager)
```

Le signal durée **gagne** en cas d'ambiguïté. Le choix est annoncé en une ligne, en vocabulaire
VibeFlow (« mission courte, traitement direct » / « mission longue, je déploie l'équipe »).

## 6. Contrats de mission (`references/mission-contracts.md` — source unique, DRY)

**Brief main → manager** (le disque reste la source de vérité ; le brief ne porte que ce qui
n'y est pas) :
- Périmètre : phases ciblées (numéros) ou objectif libre.
- Mode : superviser (checkpoints humains) / autonome (panels tranchent).
- Contraintes session : décisions déjà prises dans main qui engagent la mission (2-3 lignes max).
- Budget : optionnel (temps / tentatives), sinon défauts du manager.

**Rapport manager → main** (compact, vocabulaire VibeFlow ; le détail vit sur disque) :
- Verdict global : ✅ / partiel / bloqué.
- Par sprint : fait, verdicts (recette/revue/audit), commits (SHA).
- Décisions prises en autonomie (et par quel panel).
- Blocages & points nécessitant l'utilisateur.
- Chemin du rapport détaillé (`.planning/` ou docs du projet).

## 7. Fichiers & conformité

**Nouveaux** (dans `plugin/dev-orchestrator/`) :
```
agents/vf-dev-manager.md · vf-coder.md · vf-reviewer.md · vf-auditer.md
references/mission-contracts.md
```

**Modifiés** :
- `AGENT.md` — ligne de routage mission + heuristique + anti-pattern.
- `skills/vf-auto/SKILL.md` — aiguillage taille (seuil N=2 nommé, signaux durée).
- `scripts/tests/test-dev-orchestrator.sh` — cas étendus (§9).

**À vérifier au plan** : l'engine d'install (`plugin/_internal/vibeflow-update.sh`) déploie bien
`agents/` pour `dev-orchestrator` (il le fait pour `mobile-test-team` ; à confirmer).

**Dépendance douce** vers `mobile-test-team` : dispatch de `vf-test-orchestrator` seulement si
module installé ET projet mobile ; sinon `gsd-verify-work`. Aucune dépendance dure entre modules.

## 8. Versioning & release

1. Module `dev-orchestrator` : bump **minor** — `VERSION`, `module.json` (description élargie),
   `CHANGELOG.md`, `README.md`.
2. Racine : bump **minor** synchronisé (`VERSION`, `plugin/.claude-plugin/plugin.json`,
   `.claude-plugin/marketplace.json`) + historiques des 2 README (badges inclus).
3. **Tag obligatoire** après merge sur `main` : `git tag -a vX.Y.Z` + push +
   `bash scripts/check-release-tag.sh --remote` → `✓` (règle non négociable du repo).
4. Doctrine : nouvel **ADR** (numéro suivant disponible) actant l'architecture manager —
   topologie, critère de bascule, contrats de mission.

## 9. Critères de succès (machine-vérifiables)

1. `check-agents.sh` passe sur les 4 nouveaux agents (description + model + memory).
2. `vf-internal: true` présent sur `vf-coder`, `vf-reviewer`, `vf-auditer` ; absent de
   `vf-dev-manager` (qui a sa commande d'incarnation — Pattern 12).
3. `wc -l` ≤ 250 par agent (ADR-029).
4. `references/mission-contracts.md` existe ; `AGENT.md`, `vf-auto/SKILL.md` et
   `vf-dev-manager.md` y **renvoient** (pas de duplication des contrats).
5. `grep` de l'aiguillage taille dans `vf-auto/SKILL.md` (seuil nommé + signal durée).
6. `grep` de la ligne de routage mission dans `AGENT.md` du router.
7. `test-dev-orchestrator.sh` vert avec les nouveaux cas.
8. Aucun chemin Reviz (`docs/_mission`, revizapp) dans les agents livrés.

## 10. Risques

- **Doublon de pilotage GSD router↔coder** (DM1 assumé) — mitigation : le cycle par phase est
  décrit une fois (référence partagée), les deux agents y renvoient.
- **Sur-proposition du manager** — un router trop zélé qui propose l'équipe à chaque demande
  casserait le quotidien. Mitigation : signaux stricts (§5a), tâche simple = routage direct sans
  question.
- **Perte des acquis gsd-autonomous** — réimplémenter la boucle externe sans ses garde-fous.
  Mitigation : DM6 liste explicitement les mécanismes à reprendre ; critère de succès au plan.
- **Divergence future gsd-autonomous ↔ manager** — deux moteurs qui évoluent séparément.
  Assumé par DM2 ; le seuil de bascule rend l'usage de chacun explicite et révisable.
