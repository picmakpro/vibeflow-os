# Plan d'intégration — « équipe d'agents » (projet source) → VibeFlow-os

> Compagnon de `agent-team-spec.md` (la ressource source) et de l'évaluation associée.
> Date : 2026-07-07. Statut : **IMPLÉMENTÉ (2026-07-07)** — les 4 briques sont posées et vérifiées
> (voir § État de réalisation en fin de document). Le module `mobile-test` reste **expérimental**
> jusqu'à un run réel vert dans un contexte VibeFlow.
> Périmètre validé par Samuel : les 4 briques ci-dessous. Rejeté : hiérarchie 7-agents, parité `.agent/`, contraintes de livraison du client.

## ⚠️ Révision 2026-07-07 — une 5e brique manquait

L'analyse du **code réel** de projet source (et non du seul spec) a révélé que ce plan avait **raté la
capacité centrale** : la **couche d'orchestration autonome** (le rôle `manager` + boucle
test+fix), sans laquelle « fais la phase X en auto » ne va **pas** jusqu'au bout. Deux arguments
de l'évaluation initiale étaient erronés (densité, doublon). Voir le cadrage dédié :
**`brique5-orchestration-CADRAGE.md`**. Les briques 1–4 ci-dessous restent valides — elles sont
les pièces que la brique 5 composera.

## 0. Principe directeur

On **n'importe pas** l'archi du projet source. On **extrait 4 capacités** et on les recâble selon les conventions VibeFlow (router-jamais-réimplémenter, ADR-029 densité, installeur scope-aware, modules toggables). Tout ce qui est spécifique au projet source (bundle id, `.agent/`, `docs/_mission/`, `.dev`, livraison client) devient **config ou disparaît**.

Ordre de valeur : **A (module mobile-test) > B (garde-fous) > cloisonnement > vf-decide.**

---

## Brique 1 — Module `mobile-test` 🥇

### Objectif utilisateur
Tester **réellement** une app mobile (iOS simulateur / Android émulateur) : détecter la cible, builder si absente, jouer une régression Maestro, produire un rapport horodaté + artefacts, et diagnostiquer visuellement les échecs. Capacité aujourd'hui **totalement absente** de VibeFlow.

### Nature
Nouveau **module optionnel**, `type: "skill + script + config"`, `requires: []`. **Domain-detected** : dormant tant qu'aucun projet mobile (RN/Expo/iOS) n'est détecté — même logique que `feature-dev-gates` qui reste dormant hors web.

### Fichiers à créer — `plugin/mobile-test/`
```
plugin/mobile-test/
├── module.json                       # name, version v1.0.0, type, description, requires:[]
├── VERSION                           # v1.0.0
├── README.md                         # doc utilisateur (voir §Docs)
├── CHANGELOG.md
├── SKILL.md                          # skill `vf-mobile-test` (porté de mobile-test-pipeline)
├── scripts/
│   └── mobile-test-run.mjs           # porté de projet source, dé-spécifié
├── config/
│   └── mobile-test.example.json      # template de config (placeholders, pas de valeurs projet source)
└── references/
    └── portability-notes.md          # les apprentissages durs (maestro/PATH, JAVA_HOME, expo run détaché…)
```

### Tâches de portage (le vrai travail — pas un copier-coller)
1. **Dé-hardcoder le chemin de config.** Le script fait `CONFIG_PATH = join(ROOT, '.agent', 'config', 'mobile-test.json')`. VibeFlow n'a pas de `.agent/`. → Résolution en cascade : `--config <path>` > `$VF_MOBILE_TEST_CONFIG` > `./.vibeflow/mobile-test.json` > `./mobile-test.json`. Le script échoue avec un message clair + pointe vers `mobile-test.example.json` si rien trouvé.
2. **Paramétrer toutes les valeurs projet.** `bundleIdBase`, `debugSuffix`, `android.avdName`, `ios.preferredSimulator`, `maestroFlowsDir`, `maestroBin`, `reportsDir` → tous dans la config, aucune valeur en dur. (Déjà le cas côté config projet source ; à garantir côté code.)
3. **Corriger la dette `.dev`.** Le SKILL.md projet source dit « la cible réelle est `...projet source.dev` » alors que le spec conclut `debugSuffix: ""` (README `.maestro` faux). → La doc portée ne mentionne le suffixe **que** comme concept piloté par `debugSuffix`, sans valeur en dur, sans exemple trompeur.
4. **Neutraliser les chemins projet source** dans le SKILL.md : `docs/_mission/test-runs` → `reportsDir` (config), `.agent/scripts/...` → `${module}/scripts/...` ou chemin résolu, retirer les noms de flows projet source (`login_smoke`…) → exemples génériques.
5. **Retirer la section « Portabilité (livrable client) »** du SKILL (référence à la parité `.agent/`, hors périmètre) et la remplacer par un pointeur vers `references/portability-notes.md`.
6. **Renommer le skill** `mobile-test-pipeline` → `vf-mobile-test` (cohérence des verbes `vf-*`), description en français, mention « Invocable par l'utilisateur ET par l'agent en autonomie », reframe vocabulaire.

### Dépendances runtime (à documenter, pas à bundler)
Node, `maestro` (CLI), `xcrun simctl`/`adb`, un JDK (JAVA_HOME), Expo/RN côté projet, MCP `mobile-mcp` (diagnostic visuel, déjà dans l'environnement de Samuel). Le README liste ces pré-requis ; le script dégrade proprement si absents (message explicite).

### Vérification (avant de dire « intégré »)
Le spec le signale : la boucle n'est validée que sur projet source. → **Run réel** sur un projet mobile test (idéalement projet source lui-même en pointant la config dessus) : `detect` → `run --platform ios` build-from-zero → rapport généré. Tant que ce run n'est pas vert, le module reste en statut « expérimental » dans le README.

---

## Brique 2 — Doctrine de garde-fous autonomes 🥈

### Objectif
Rendre **toute** boucle autonome VibeFlow (`vf-auto`, et la boucle test du module mobile) sûre et non-tricheuse. Généralise la couche B de projet source sans importer ses 3 agents.

### Nature
Une **référence** chargée on-demand + branchements légers. Pas de nouvel agent.

### Fichiers
- **Créer** `plugin/dev-orchestrator/references/autonomous-guardrails.md` — les 5 garde-fous, formalisés :
  1. **Anti-thrash** : abandon après N tentatives sur le même échec (N config, défaut 3).
  2. **Anti-régression** : revert auto d'un changement qui casse un test précédemment vert (monotonie garantie).
  3. **Critère d'arrêt** : tout vert **ou** plafond temps/tokens atteint.
  4. **Séparation anti-triche** : qui écrit/modifie les tests ≠ qui corrige le code ; **jamais** affaiblir un assert pour « passer ». (Matérialisé par le cloisonnement d'outils — brique 3.)
  5. **Traçabilité** : commit atomique par correctif + rapport de synthèse (diff global) en fin de boucle.
- **Modifier** `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` — ajouter un renvoi : « En mode autonome non supervisé, applique `autonomous-guardrails.md`. » (le skill reste thin).
- **Config** : réutiliser la forme de `night-run.json` de projet source comme **schéma documenté** dans la référence (`maxWallClockMinutes`, `maxTokens`, `maxAttemptsPerFlow`, `revertOnRegression`) — le module mobile-test lira un `night-run.json` optionnel du projet.
- **Bump** `dev-orchestrator` v1.1.0 → v1.2.0.

---

## Brique 3 — Convention de cloisonnement par outils 🥉

### Objectif
Codifier le pattern de sécurité de projet source comme **convention d'archi VibeFlow**, réutilisable pour tout futur agent, et support technique de l'anti-triche (brique 2).

### Règle
- **Un juge n'écrit jamais** : un agent de revue/audit a `Read, Bash, Glob, Grep, Task` — **pas** de `Write`/`Edit`. (cf. `vibeflow-validator` qui est déjà un juge.)
- **Un worker n'escalade jamais** : un agent qui modifie du code a `Read, Edit, Write, Bash, Glob, Grep` — **pas** de `Task` (pas de sous-délégation incontrôlée).
- Défense en profondeur : le cloisonnement `tools:` est doublé par les règles de domaine dans le corps (le FS n'est pas une garantie dure).

### Nature — documentation, pas de code
- **Où** : ajouter une section « Cloisonnement par outils » dans la doc de conventions d'archi. Candidat : une référence dans `plugin/reference/content/methodology/` (là où vivent les conventions/ADR templates), OU un nouvel **ADR** (ex. ADR-038) si Samuel tient un registre ADR canonique hors-repo (les ADR ne sont pas définis dans ce repo, seulement référencés — à clarifier).
- **Appliquer rétroactivement** : vérifier que `vibeflow-validator` (juge) n'a effectivement pas Write/Edit dans son usage réel, et documenter la conformité.

> ⚠️ Décision ouverte : où vit la définition canonique des ADR ? Ce repo ne contient qu'un *template* ADR, pas les définitions. Il faut trancher avant d'écrire « ADR-038 ».

---

## Brique 4 — Panel de décision `vf-decide` (bonus)

### Objectif
Exposer, en vocabulaire VibeFlow, le mécanisme de décision de zone grise : `gsd-advisor-researcher` ×3 → synthèse comparative. Aujourd'hui disponible côté GSD mais non exposé comme verbe VibeFlow.

### Nature
Un **skill thin** de plus, strictement dans le moule des autres `vf-*`.

### Fichiers
- **Créer** `plugin/dev-orchestrator/skills/vf-decide/SKILL.md` — délègue à `gsd-advisor-researcher` (panel), reframe « advisor/researcher » → **panel de décision**, restitue un tableau comparatif + reco. Description FR, « invocable utilisateur ET agent ».
- **Vérifier** que `gsd-advisor-researcher` est bien invocable comme cible (il est listé dans l'environnement). Si l'invocation directe n'est pas fiable depuis un skill, router via `gsd-discuss-phase` en mode advisor.
- Mentionner `vf-decide` dans la table de routage de `vibeflow-dev` (`AGENT.md`) et dans `vocabulary-map.md`.

---

## Documentation utilisateur (transverse — exigence explicite de Samuel)

Chaque brique livrée doit être **expliquée pour l'utilisateur**, en français, sans jargon GSD :
1. **README du module `mobile-test`** : à quoi ça sert, pré-requis, `mobile-test.json` commenté, exemples de commandes, quoi faire sur échec, statut expérimental.
2. **Section « Modes autonomes & garde-fous »** dans le README de `dev-orchestrator` : ce que garantit une boucle autonome (pas de triche, pas de régression, arrêt propre).
3. **Entrée README racine / INSTALL** : le nouveau module `mobile-test` dans la liste des modules toggables + comment l'activer via `/vibeflow-install`.
4. **CHANGELOG** de chaque module touché.
5. **Mise à jour de l'installeur** : `build-module-catalog.sh` doit voir le nouveau `module.json` (vérifier qu'il est bien pické automatiquement depuis le disque — a priori oui).

---

## Séquencement proposé (par le pipeline VibeFlow lui-même)

1. **Cadrage + plan de sprint** de ce périmètre (brancher sur le vrai flux `vf-plan`).
2. **Sprint 1 — Brique 3 + 4** (doc + skill thin, faible risque, rapide). Valide le moule.
3. **Sprint 2 — Brique 2** (garde-fous : référence + branchement vf-auto).
4. **Sprint 3 — Brique 1** (module mobile-test : portage + dé-dé-spécification + README). Le plus gros.
5. **Vérification** : run réel du pipeline mobile ; recette conversationnelle ; audit `vibeflow-validator` (densité ADR-029, dette doc).
6. **Bump versions** + CHANGELOG + éventuelle nouvelle milestone.

## État de réalisation (2026-07-07)

| Brique | État | Fichiers |
|--------|------|----------|
| 1 — Module `mobile-test` | ✅ posé, install e2e validée (sandbox), script exécuté (`detect` OK). **Expérimental** (run réel à faire). | `plugin/mobile-test/**` |
| 2 — Garde-fous autonomes | ✅ posé | `dev-orchestrator/references/autonomous-guardrails.md` + branchement `vf-auto` |
| 3 — Cloisonnement outils | ✅ posé | `reference/.../patterns/12-cloisonnement-outils.md` + README patterns |
| 4 — `vf-decide` | ✅ posé, test T4 vert | `dev-orchestrator/skills/vf-decide/SKILL.md` |

**Modifs d'engine (découvertes en cours d'exécution, hors plan initial)** : `_internal/vibeflow-update.sh`
étendu pour copier/désinstaller les scripts `.mjs`/`.js` (pas seulement `.sh`) et le dossier `config/`
d'un module single-skill — sinon `mobile-test` ne s'installait pas. Validé par install+uninstall sandbox.

**Vérifications passées** : suite `test-dev-orchestrator.sh` 13/13 ; install/uninstall e2e du module ;
JSON valides ; densités ADR-029 OK (tous < plafonds) ; catalogue d'install liste `mobile-test`.

**Décision tranchée en exécution** : `vf-decide` route vers `gsd-discuss-phase` (mode advisor), **pas**
vers l'agent `gsd-advisor-researcher` en direct (un skill route vers un skill canonique). Le test T4 a
attrapé la version initiale erronée.

**Bumps de version** : `dev-orchestrator` v1.2.0, `reference` v2.1.2, `mobile-test` v1.0.0 (nouveau).
README racine mis à jour (14 modules). **Version plugin globale non bumpée** — décision de release à part.

## Risques & décisions ouvertes
- **[BLOQUANT LÉGER]** Où vivent les ADR canoniques ? (impacte brique 3). → trancher avant de nommer un ADR.
- **[TECHNIQUE]** Fiabilité de l'invocation `gsd-advisor-researcher` depuis un skill (brique 4). → tester tôt.
- **[TECHNIQUE]** La délégation skill-vs-agent GSD depuis un sous-agent dépend des outils exposés — à re-valider dans l'env VibeFlow, pas juste supposer (avertissement du spec).
- **[PÉRIMÈTRE]** Le module mobile-test n'est « intégré » qu'après un run réel vert ; sinon statut expérimental assumé.
