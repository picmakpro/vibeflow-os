# Chargement silencieux d'un skill `disable-model-invocation` : VibeFlow est-il exposé ?

Lecture seule de `le dépôt `vibeflow-os`` (rien modifié), 10/10/2026. Les installations locales (`~/.claude/skills`, `~/.claude/plugins/cache`, `~/.claude/gsd-core`) ont aussi été vérifiées.

## Verdict

**Risque latent, aucun cas réel aujourd'hui.** Aucun skill de VibeFlow, de GSD ni de superpowers (6.4.1) chargé par un agent VibeFlow ne porte `disable-model-invocation: true`. Le gate POCK-07 interdit déjà qu'un skill `user` soit appelé par un agent qui a l'outil Skill. La faiblesse est ailleurs : la doctrine design **dégrade de mémoire** quand une brique manque, ce qui est l'exact inverse du remède « fail-closed ». Elle le signale dans le rapport final, ce qui est mieux que le silence constaté chez nicknisi et pstack, mais ce n'est pas un arrêt.

## 1. Qui porte le drapeau, qui porte `vf-invocation`

- **`disable-model-invocation: true` dans un SKILL.md de `plugin/`** : aucun. Le drapeau n'apparaît que dans les gates (`conductor/scripts/check-skills.sh:120, 716-735`, `check-agents.sh:1114`), leurs suites de tests, `skill-creator/.../quick_validate.py:49-51` et les CHANGELOG.
- **L'installeur ne le pose pas** : `plugin/_internal/vibeflow-update.sh` copie les SKILL.md tels quels (`:2290-2293` pour le Type 1, `:2296` et suivantes pour le Type 2). Il ne réécrit aucun frontmatter et ne contient ni `vf-invocation`, ni `disable-model-invocation`, ni `policy`.
- **`vf-invocation`** : les 26 SKILL.md de `plugin/` sont tous classés **`model`** (zéro `user`, zéro non classé) : vf-content, vf-business, planning-core, vf-dev, vf-auto, vf-growth, vf-sketch, vf-design, skill-creator-workflow, skill-creator, kpi-analyst, audit-architecture, infrastructure-audit, consolidator, software-architecture, mobile-test, installer, vf-calibrate, vf-split-planning, vf-new-lab, vf-update, vf-notify, ainsi que 4 gabarits sous `reference/content/methodology/templates/skills/`.
- **Côté externe** : aucun `disable-model-invocation` dans `~/.claude/skills` (72 skills gsd-*), dans `~/.claude/gsd-core`, ni dans les SKILL.md de superpowers 6.4.1. Seules les RELEASE-NOTES de superpowers en parlent : en v4.0.x, ils l'avaient posé sur les trois **commandes** `/brainstorm`, `/execute-plan` et `/write-plan`, et laissé les skills sous-jacents invocables. `impeccable` porte `user-invocable: true`, qui est la valeur par défaut et ne pose donc aucun problème.

## 2. Chargements demandés par un agent (cas `fichier:ligne`)

Aucun ne vise un skill marqué. Voici les cas, pour mémoire :

| Appel | Skill visé | Drapeau |
|---|---|---|
| `dev-orchestrator/agents/vf-coder.md:42` | `gsd-plan-phase` | aucun |
| `dev-orchestrator/agents/vf-coder.md:45` | `gsd-execute-phase` | aucun |
| `dev-orchestrator/agents/vf-coder.md:32` | `gsd-quick --validate` | aucun |
| `dev-orchestrator/agents/vf-dev-manager.md:195` | `gsd-debug`, invoqué par le worker | aucun |
| `validator/AGENT.md:7-10` (préchargement `skills:`) | consolidator, infrastructure-audit, audit-architecture | `model` |
| `design-orchestrator/agents/vf-crafter.md:4` (outil Skill) et `references/design-toolchain.md:15-17` | ui-ux-pro-max, frontend-design, impeccable | aucun |
| `design-orchestrator/references/design-toolchain.md`, `dev-orchestrator/references/intent-routing.md`, `skill-creator/AGENT.md` | superpowers : brainstorming, verification-before-completion, writing-skills | aucun (6.4.1) |
| Blueprints `content-bundle/content/agents/*.blueprint.md:22`, `business-pilot-bundle/.../business-pilot-finance.blueprint.md:20` | skills de lab à créer (clarity-feature, audit-architecture, invoice-prep…) | non encore créés, donc à surveiller |

**Garde machine déjà en place :**

- `check-skills.sh --callers-root=plugin` refuse un skill `user` appelé par une commande, par un préchargement `skills:` ou par un agent qui le cite **et** a l'outil Skill (P414-D-02). La règle est câblée en CI : `.github/workflows/ci.yml:334-356`.
- `check-agents.sh:1114-1115` refuse le préchargement d'un skill `disable-model-invocation: true`.

**Angles morts du gate :**

- Il ne voit que l'arbre `plugin/`. Un skill tiers (GSD, superpowers, impeccable…) qui ajouterait le drapeau à une mise à jour ne serait pas détecté.
- Une citation en prose depuis un agent **sans** outil Skill n'est pas une arête (choix assumé, `check-skills.sh` en-tête).
- Les skills créés dans un lab à partir des blueprints passent par `quick_validate.py`, qui **accepte** `vf-invocation: user` avec le drapeau. Rien ne vérifie, au niveau du lab, que l'agent qui les charge les atteindra, sauf si le hook de lab lance `--callers-root`.

## 3. Consigne fail-closed ?

Il n'y a **pas de consigne générale** du type « si le chargement d'une ressource échoue, dis-le et arrête ». Le tableau est mixte :

- **Fermé ou quasi fermé :**
  - `vf-coder.md:71-73` : « Skill non invocable depuis ton contexte → dispatche l'équivalent parmi les agents de ton champ `tools:` ; aucun ne convient → remonte `blocked` au dispatcheur. » Pas de travail de mémoire, mais un repli vers un agent équivalent avant l'arrêt.
  - `vf-coder.md:33-35` : outil `Agent` absent → « arrête-toi sans coder à la main ».
  - Ressources de données (pas des skills) : `content-bundle/agents/vf-content-repurposer.md:38` (« Gabarit absent → `blocked`, pas d'improvisation »), `vf-content-writer.md:26`, `growth-bundle/agents/copywriter-sequences.md:27`, `kpi-analyst/AGENT.md:95` (« je n'invente pas »), `business-pilot-bundle/agents/quality-gate-client.md:61`.
- **Ouvert, explicitement :**
  - `design-orchestrator/agents/vf-crafter.md:39-41` : « Une brique absente → **ne bloque pas** : dégrade sur les premiers principes design […] et signale-le dans ton rapport, jamais à mi-course. »
  - `design-orchestrator/AGENT.md:146-147` dit la même chose.
  - `design-orchestrator/references/design-toolchain.md:76-95` : « Dégradation gracieuse (ne JAMAIS bloquer) », avec un repli manuel pour chaque brique, signalé dans le rapport final.

  C'est la classe exacte du constat externe (la grille remplacée par une paraphrase), mais **déclarée** et non silencieuse. Elle est aussi déclenchée par l'absence du plugin (`ensure-design-deps.sh`, qui ne dégrade jamais en silence, `:54-57`), pas spécifiquement par un refus de l'outil Skill.
- **Juges** : `vf-design-judge.md:61-64` lit sa grille et `DESIGN.md` par Read (pas par Skill), donc il n'est pas concerné par le drapeau. Il n'a pas non plus de consigne « grille illisible → arrêt ».

## 4. Canal `agent_skills` (`GSD-PIPELINE.md` §10)

- **Non concerné en l'état.** VibeFlow peuple `{"gsd-planner": ["global:software-architecture", "global:audit-architecture"]}` (`.planning/config.json`). Dans `~/.claude/gsd-core/bin/lib/init.cjs:3627-3742` (`buildAgentSkillsBlock`), un nom **non namespacé** devient une inclusion de fichier `@…/SKILL.md`, lue directement : l'outil Skill n'intervient pas, donc le drapeau n'a aucun effet. Les deux skills sont de toute façon `model`.
- **Concerné en théorie** : seule une entrée **namespacée** (`global:plugin:skill`) passe par une directive « Load the `x` skill via the Skill tool » (`init.cjs:3673-3678, 3737`). Celle-là serait refusée si le skill portait le drapeau.
- **Faille voisine, indépendante du drapeau** : un skill introuvable est **sauté** avec un simple avertissement sur stderr (`init.cjs:3693-3694, 3715-3717`). Si les deux manquent, le bloc est vide (`:3732-3734`) et `gsd-planner` planifie sans la doctrine, sans que l'agent le sache. C'est le même mode d'échec silencieux que le constat externe, par un autre chemin.

## 5. Doc officielle (code.claude.com/docs/en/skills, lue le 10/10/2026)

- `disable-model-invocation: true` : « Claude can't invoke the skill on its own. »
- Tableau du chargement en contexte : « Description not in context, full skill loads when invoked ». Le skill se charge seulement quand l'utilisateur l'invoque.
- « Also prevents the skill from being preloaded into subagents. »
- `user-invocable: false` est l'inverse : seul Claude peut l'invoquer.

Le constat externe est donc confirmé : un skill marqué est invisible et ne peut pas être invoqué par le modèle ni par un sous-agent, ni préchargé. La doc ne précise pas le message d'erreur renvoyé par l'outil Skill.

## Pistes (non appliquées, pour arbitrage)

1. Ajouter une clause fail-closed commune aux agents qui chargent une ressource normative (grille, rubric, skill de doctrine) : « chargement refusé ou vide → le dire et rendre `blocked`, jamais de travail de mémoire ». Réexaminer la « dégradation gracieuse » design pour les gestes de **jugement**, où la paraphrase coûte le plus.
2. Étendre `check-skills.sh --callers-root` aux skills tiers effectivement cités (GSD, superpowers, impeccable, ui-ux-pro-max) lus dans le cache installé, pour attraper un drapeau ajouté par une mise à jour en amont.
3. Pour `agent_skills` : vérifier dans `check-gsd-config.sh` que chaque entrée se résout à un SKILL.md existant, puisque le moteur saute en silence ce qui ne se résout pas.
