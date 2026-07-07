# Spec consolidée : équipe d'agents autonome (test + dev) et intégration dans vibeflow-os

> **[RESSOURCE IMPORTÉE — vibeflow-os]** Copie de référence du track « Équipe d'agents autonome »
> conçu et implémenté sur le projet client **revizapp**. Importé le 2026-07-07 depuis
> `WillHosting/.planning/test-tooling/VIBEFLOW-OS-INTEGRATION.md`.
> Ce document est une **entrée de recherche** : la source de vérité pour ce qui est réellement
> retenu et intégré dans vibeflow-os est l'évaluation associée, pas ce fichier.
> Ne pas exécuter tel quel — plusieurs décisions sont spécifiques à revizapp (voir évaluation).

> Source de vérité unique du track « Équipe d'agents autonome ». Consolide SPEC-fondation-A.md, SPEC-B.md, SPEC-C.md.
> Date : 2026-07-06. Auteur : Samuel.
> **Objectif de ce document** : décrire exactement l'architecture définie et implémentée sur revizapp, pour (1) l'ajouter à **vibeflow-os** en tant que module « équipe d'agents » (avec l'agent `manager` au sommet), et (2) améliorer l'existant vibeflow là où il recoupe cette archi.

---

## 1. Vue d'ensemble

Une équipe d'agents Claude Code qui fait avancer une mission de dev en autonomie, en **déléguant** au workflow GSD et en **testant réellement** l'app mobile (iOS/Android). Point d'entrée unique : l'agent `manager`. Tout part de lui.

Quatre couches :

1. **Fondation** : parité `.agent/` <-> `.claude/` par symlink, portabilité, enforcement husky.
2. **Pipeline de test mobile (A)** : script `detect`/`run` (Maestro + diagnostic mobile-mcp) + skill `mobile-test-pipeline`.
3. **Équipe de test (B)** : `test-orchestrator` -> `test-runner` + `app-fixer`, boucle mode nuit.
4. **Couche manager (C)** : `manager` -> `coder` / `reviewer` / `auditer` + `test-orchestrator`, délégation GSD.

Hiérarchie :

```
manager  (lit ROADMAP + dette + scope ; planifie ; décide via panel ; distribue)
├── (décision zone grise) gsd-advisor-researcher x3  ->  synthèse
├── coder      -> gsd-discuss-phase -> gsd-plan-phase -> gsd-execute-phase -> review
│                 └── reviewer  (gsd-code-review / gsd-code-reviewer sur le diff)
├── reviewer   (mobilisable directement par le manager)
├── auditer    (gsd-security-auditor + CONCERNS + audit mission)
└── test-orchestrator   (boucle mode nuit)
        ├── test-runner  (possède les flows Maestro, exécute le pipeline A)
        └── app-fixer    (corrige le code app, commit atomique)
```

---

## 2. Décisions verrouillées (brainstorming 2026-07-06)

### Transverses
- **Livraison différée** : le remote `origin` est le repo du client (`github.com/aversag/revizapp`). Aucun `git push` avant le paiement final. Commits locaux uniquement, **sans aucune mention d'IA/Claude** (pas de trailer Co-Authored-By), sans référence à `.planning`.
- **Parité `.agent/` <-> `.claude/`** : tout skill/agent existe dans `.agent/` (canonique livrable) ET dans `.claude/` (miroir exécutable), via symlink. Enforcé par script + husky.
- **Portabilité** : aucune valeur machine-dépendante en dur ; tout en config versionnée.

### Pipeline de test (A)
| Sujet | Décision |
|-------|----------|
| Plateforme | Cible détectée au lancement ; ambigu (0 ou >1) -> l'agent demande. |
| Build | Build/install auto si l'app est absente. |
| Rapport | Markdown horodaté + artefacts (screenshots, logs). |
| Structure | Script d'orchestration (mécanique) + skill (jugement). |

### Équipe de test (B)
| Sujet | Décision |
|-------|----------|
| Autonomie | Boucle autonome complète (mode nuit). |
| app-fixer | Code app SEUL ; tests intouchables (anti-triche). |
| test-runner | Possède l'authoring des tests : écrit les flows manquants, n'affaiblit jamais un assert. |
| Garde-fous | Vert / plafond temps-tokens ; anti-thrash (abandon après N=3) ; anti-régression (revert d'un fix qui casse un flow vert). |
| Commits | Auto-commit atomique par fix (sans push) ET rapport de réveil avec diff global. |

### Couche manager (C)
| Sujet | Décision |
|-------|----------|
| Réutilisation | Orchestrateurs FINS qui délèguent aux skills/agents GSD. Zéro réimplémentation. |
| Autonomie manager | Flexible ; planifie TOUJOURS d'abord ; mode précisé par Samuel ou demandé. |
| Décisions | Panel `gsd-advisor-researcher` ; gate seulement si Samuel l'exige. |
| Flux intra-phase | Séquence complète, étages choisis par phase (coder -> test-orchestrator -> auditer). |
| reviewer / auditer | reviewer = revue du diff ; auditer = audit sécu/dette niveau phase. |

---

## 3. Les 7 agents (fichiers + cloisonnement)

Tous dans `.agent/agents/<nom>.md` (canonique) avec symlink miroir `.claude/agents/<nom>.md`.

Cloisonnement **par ensemble d'outils** (frontmatter `tools:`), doublé par les règles de domaine dans le corps (défense en profondeur ; le FS n'est pas une garantie dure) :

| Agent | Outils | Peut écrire ? | Peut dispatcher ? | Domaine |
|-------|--------|---------------|-------------------|---------|
| `manager` | tous (hérités) | suivi GSD + rapport | oui | Sommet : planifie, décide, distribue. Ne code/teste/audite jamais. |
| `coder` | tous (hérités) | via gsd-executor | oui | Cycle GSD discuss->plan->execute->review. Route vers GSD. |
| `test-orchestrator` | tous (hérités) | rapport + git (revert) | oui | Boucle test+fix mode nuit, garde-fous. |
| `reviewer` | Read, Bash, Glob, Grep, Task | NON (pas de Write/Edit) | oui | Revue de diff (délègue gsd-code-review). Pur juge. |
| `auditer` | Read, Bash, Glob, Grep, Task | NON (pas de Write/Edit) | oui | Audit sécu/dette (délègue gsd-security-auditor). Pur juge. |
| `app-fixer` | Read, Edit, Write, Bash, Glob, Grep | code app seul | NON (pas de Task) | Corrige le code app, commit atomique. Ne peut pas escalader. |
| `test-runner` | Read, Edit, Write, Bash, Glob, Grep | `.maestro/**` seul | NON (pas de Task) | Écrit/joue les flows. Ne touche pas le code app. |

Cloisonnement effectif au niveau outil : les workers qui écrivent (`app-fixer`, `test-runner`) n'ont pas Task (pas d'escalade) ; les juges (`reviewer`, `auditer`) n'ont pas Write/Edit (revue pure). La distinction fine de chemins (app-fixer=code vs test-runner=flows) est portée par le corps de l'agent.

Résumé du rôle de chaque agent : voir SPEC-B.md et SPEC-C.md (les corps des agents en `.agent/agents/*.md` sont la spec opérationnelle exécutable).

---

## 4. Pipeline de test mobile (couche A, implémenté et validé)

- **Script** `.agent/scripts/mobile-test-run.mjs` :
  - `detect` : imprime en JSON les cibles bootées (simulateurs iOS via `simctl`, émulateurs Android via `adb`).
  - `run --platform <ios|android> [--target] [--stamp] [--skip-build] [--keep-metro]` : résout le bundle id, boote la cible, build/install si absent (`expo run` en **détaché** + polling d'install), assure Metro, joue `maestro test`, parse le JUnit, scaffolde le rapport, nettoie les process démarrés. Imprime `{ platform, target, results[], artifactDir, reportPath }`.
- **Config** `.agent/config/mobile-test.json` : `bundleIdBase`, `debugSuffix` (""), `android.avdName`, `ios.preferredSimulator`, `maestroFlowsDir`, `maestroBin`, `reportsDir`. Aucune valeur machine en dur dans le code.
- **Skill** `mobile-test-pipeline` : documente le flux + la couche jugement (diagnostic mobile-mcp sur échec, rédaction du rapport).

### Apprentissages de portabilité (durs, validés en live)
- `maestro` n'est pas dans le PATH d'un shell non interactif -> résolution via `config.maestroBin` puis `~/.maestro/bin/maestro`.
- `JAVA_HOME` absent -> détection (`/usr/libexec/java_home`, openjdk@17 homebrew), passé en env à Maestro.
- `expo run:ios/android` **ne rend jamais la main** (garde Metro attaché) -> lancement détaché + polling d'install + nettoyage du groupe de process.
- Bundle id réel : `com.guillaumeaversa.revizapp` (PAS de suffixe `.dev` ; le README `.maestro` était faux). Corrigé dans les flows.
- `assertVisible`/`tapOn` n'acceptent pas `timeout:` (seul `extendedWaitUntil`). Corrigé.

---

## 5. Fondation parité et portabilité (implémentée)

- **Source canonique** `.agent/` ; **miroir** `.claude/` par symlink relatif. Le format `SKILL.md`/agent est identique, donc un fichier physique unique sert les deux mondes.
- `.agent/scripts/check-agent-claude-parity.mjs` : échoue si une entrée de `.agent/skills` ou `.agent/agents` n'a pas son symlink résolu côté `.claude/` (exclusion des legacy `*_expert`, `skill-creator`). Branché sur `.husky/pre-commit`.
- **Contraintes vérifiées empiriquement dans Claude Code** :
  - Un **skill** symlinké est découvert (hot-reload). Prouvé.
  - Un **agent** symlinké est découvert (hot-reload, léger délai). Prouvé.
  - Un **sous-agent peut lancer des sous-agents imbriqués** (Task/Agent). Prouvé (NESTING_OK). C'est ce qui rend la hiérarchie manager -> ... viable en sous-agents.

---

## 6. Intégration dans vibeflow-os

### Ce qu'on AJOUTE à vibeflow-os
- Le module **« équipe d'agents »** : les 7 agents (`manager`, `coder`, `reviewer`, `auditer`, `test-orchestrator`, `test-runner`, `app-fixer`).
- Le **pipeline de test mobile** (script `mobile-test-run.mjs` + skill `mobile-test-pipeline` + config).
- La **fondation de parité** `.agent/` <-> `.claude/` (script + hook) comme convention de packaging livrable.
- Deux configs : `mobile-test.json`, `night-run.json`.

### Ce qu'on RÉUTILISE (ne pas réimplémenter)
- Le workflow GSD : skills `gsd-discuss-phase`, `gsd-plan-phase`, `gsd-execute-phase`, `gsd-code-review` et agents `gsd-planner`, `gsd-executor`, `gsd-code-reviewer`, `gsd-security-auditor`.
- `gsd-advisor-researcher` comme moteur de décision (panel du manager).
- Le suivi GSD (`.planning/` : PROJECT, ROADMAP, phases, STATE, codebase/CONCERNS, review).

### Ce qu'on AMÉLIORE dans l'existant vibeflow
- **`vibeflow-dev`** (agent de routage GSD/Superpowers actuel) recoupe partiellement `manager` + `coder`. Reco : faire du `manager` le nouveau sommet, et soit absorber `vibeflow-dev` dans `coder` (le routage dev pur), soit faire déléguer `coder` à `vibeflow-dev`. Éviter deux routeurs concurrents.
- **`vibeflow-validator`** recoupe `reviewer` + `auditer`. Reco : `reviewer`/`auditer` délèguent à `vibeflow-validator`/`gsd-*` plutôt que de dupliquer sa logique d'audit multi-couches.
- **Duplication legacy** : `.agent/skills/*_expert` vs `.claude/commands/*-expert.md` (personas en double formats). À rationaliser lors de l'intégration (choisir un format canonique, appliquer la parité).
- **Généraliser la parité** : la convention symlink `.agent/` <-> `.claude/` + le check husky devraient devenir le mécanisme de packaging standard de vibeflow-os (un seul contenu, deux runners).

### Points de vigilance pour le portage
- Les chemins/valeurs propres à revizapp (bundle id, AVD, sources `docs/_mission/`, `.planning/`) doivent devenir des **paramètres** dans vibeflow-os (config par projet), pas des constantes.
- La délégation exacte skill-vs-agent GSD depuis un sous-agent est à re-valider dans l'environnement vibeflow-os (elle dépend des outils exposés aux sous-agents).
- La contrainte « pas de mention d'IA dans les commits » est spécifique au repo client ; dans vibeflow-os, en faire une **option de projet**.

---

## 7. État d'implémentation (2026-07-06)

| Couche | État |
|--------|------|
| Fondation parité | Implémentée, prouvée (skill + agent + nesting). |
| A : pipeline test mobile | Implémenté, validé live iOS (build-from-zero inclus). |
| B : 7 -> 3 agents test + config | **Agents écrits + symlinkés + parité verte.** Boucle à valider en run réel. |
| C : 4 agents manager/dev + config | **Agents écrits + symlinkés + parité verte.** Délégation GSD à valider en run réel. |
| Découverte des 7 agents par Claude Code | Attendue (hot-reload) ; à reconfirmer au 1er lancement du manager. |

Fichiers produits : `.agent/agents/{manager,coder,reviewer,auditer,test-orchestrator,test-runner,app-fixer}.md` (+ symlinks `.claude/agents/`), `.agent/scripts/{mobile-test-run,check-agent-claude-parity}.mjs`, `.agent/skills/mobile-test-pipeline/SKILL.md` (+ symlink), `.agent/config/{mobile-test,night-run}.json`, hook `.husky/pre-commit`.

### Prochaine validation
Lancer le `manager` sur une phase à faible enjeu (mode « une phase »), confirmer : découverte des agents, planification systématique, délégation GSD, boucle test, mise à jour du suivi, rapport. Puis durcir les garde-fous de B et la délégation de C sur cas réels.
