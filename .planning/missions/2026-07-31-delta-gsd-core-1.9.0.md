# Diagnostic — delta `@opengsd/gsd-core` 1.8.0 → 1.9.0 et surface de couplage VibeFlow

> **Origine** : mise à jour du moteur sur le poste de Samuel le 2026-07-31 (11:35), de 1.8.0 vers
> 1.9.0 (`latest` au npm). Question posée : qu'est-ce que ça impacte côté VibeFlow ?
>
> **Méthode** : `npm pack` des deux versions et diff intégral des tarballs, plus vérification de
> l'installation vivante (`~/.claude/gsd-core`, `~/.claude/agents`, `~/.claude/hooks`).
>
> **Statut** : diagnostic vérifié sur pièce, **aucun correctif appliqué** (ADR-031). Arbitrage
> Samuel du 2026-07-31 : **une phase dédiée unique**, périmètre exhaustif, rituel allégé,
> **après le merge de la Phase 20** — même règle que le diagnostic du 2026-07-29.

## Ce qui ne casse pas — vérifié

Le couplage de dispatch tient intégralement. Contrôles passés le 2026-07-31 :

- **Aucun frontmatter d'agent modifié** entre 1.8.0 et 1.9.0. Les 10 agents dont le fichier change
  (`gsd-executor`, `gsd-planner`, `gsd-plan-checker`, `gsd-phase-researcher`, `gsd-code-fixer`,
  `gsd-codebase-mapper`, `gsd-debug-session-manager`, `gsd-intel-updater`, `gsd-project-researcher`,
  `gsd-ui-auditor`) ne changent que dans le **corps** — `description:`, `tools:` et `model:` sont
  identiques. Rien à réaligner côté allowlists `Agent(...)` des managers.
- **71 skills en 1.8.0, 71 en 1.9.0**, aucun ajout ni suppression. Seul
  `gsd-plan-review-convergence` voit son `SKILL.md` et sa commande modifiés.
- **`_runtime-launcher.snippet.sh` identique** — le snippet cité verbatim par `mission-contracts.md`
  n'a pas bougé.
- **Les 43 suites de tests du repo passent** sans modification.
- **Aucun hook déclaré dans `settings.json` n'est manquant** après la réécriture 1.9.0.
- Le gate `check-gsd-engine.sh` sort `✓` (moteur `@opengsd/gsd-core` reconnu), `detect-gsd-engine.sh`
  aussi.

Conclusion : **la 1.9.0 n'introduit aucune régression bloquante**. Ce qui suit est de l'alignement
et de la dette, pas de la réparation d'urgence — à une exception près (injection MCP, § suivant).

## Volumétrie du delta

156 fichiers modifiés, 16 ajoutés, 2 supprimés. Par zone : `gsd-core/bin` (52),
`gsd-core/workflows` (41), `hooks/dist` (11), `gsd-core/references` (7), `gsd-core/templates` (3).

Ajouts notables :

```
gsd-core/bin/lib/phase-estimation.cjs         gsd-core/bin/lib/estimate-cli.cjs
gsd-core/bin/lib/review-lane-descriptor.cjs   gsd-core/bin/lib/review-lane-invocation.cjs
gsd-core/bin/lib/review-lane-runner.cjs       gsd-core/bin/lib/unusable-input.cjs
gsd-core/references/offer-next.md             gsd-core/references/runtime-aware-dispatch.md
gsd-core/workflows/execute-phase/steps/executor-isolation-dispatch.md
hooks/lib/cursor-workspace.js
```

## Les quatre nouveautés qui touchent le périmètre VibeFlow

### 1. Contrat `estimate:` / `actuals:` (ADR-2629, #2632) — le plus structurant

`gsd-planner` émet désormais dans le frontmatter du `PLAN.md` :

```yaml
estimate:
  tokens: 60000       # projection calibrée
  raw_tokens: 30000   # projection avant facteur
  tasks: 3
  confidence: low     # low | med | high — DÉRIVÉE du nombre d'échantillons, jamais auto-évaluée
```

et `gsd-executor` doit écrire en retour, dans le `SUMMARY`, quand le plan portait un `estimate` :

```yaml
actuals:
  tokens: 74000   # chars/4 sur les fichiers réellement changés — PAS un compteur du harness
  tasks: 5
  commits: 7
```

L'amont insiste sur deux points : la **même échelle** des deux côtés (sinon on mesure les méthodes
de mesure, pas l'écart), et **aucun arrondi flatteur** (« a flattering number corrupts every later
projection »).

**Impact VibeFlow** : `dev-orchestrator/references/mission-contracts.md` définit les contrats de
sortie typés de `vf-coder` et des workers. Il ignore ces deux champs. Conséquence : les missions
pilotées par `vf-dev-manager` traversent la chaîne sans jamais alimenter la boucle de calibration
amont. Perte fonctionnelle **silencieuse** — rien n'échoue, la donnée n'existe simplement pas.

### 2. Refonte du contrat des lanes de revue (ADR-2782 Phase 1, #2794 — clôt #2690)

`review-lane-descriptor.cjs` déclare **en données** le contrat des reviewers cross-AI, jusqu'ici
éclaté sur trois surfaces (roster, ~640 lignes de bash par CLI dans `workflows/review.md`, en-têtes
codés en dur dans `write_reviews`). Le module **déclare, il n'exécute pas** : `invoke_reviewers`
garde ses jambes écrites à la main jusqu'à la Phase 5b amont (#2799). L'apport est la parité
vérifiée (`checkReviewerLaneParity`) — une lane ne peut plus être ajoutée, retirée ou renommée sans
que la table et la section `REVIEWS.md` bougent ensemble.

**Impact VibeFlow** : recouvrement à instruire avec l'**étage de revue de premier rang** livré en
20-06 (`vf-reviewer` → `gsd-code-reviewer`). Ce sont deux objets différents — revue **cross-AI de
plans** en amont, revue de **diff de code** chez nous — mais la question « qui revoit quoi, et
est-ce qu'on double » mérite d'être tranchée explicitement plutôt que par omission.

### 3. `runtime-aware-dispatch.md` (epic #2505 Phase 4 / #2508)

Distingue les runtimes à **dispatch nommé** (Claude Code, OpenCode, Cursor, Cline — tout runtime
dont le descripteur déclare `hostIntegration.dispatch.namedDispatch: true`) des runtimes
**built-in-only** (kimi-code : `coder`, `explore`, `plan` seulement, pas d'enregistrement custom),
où un nom de rôle GSD est inconnu et doit tomber sur le built-in le plus proche.

**Impact VibeFlow** : nos managers dispatchent des agents nommés en dur. `~/.claude/gsd-core/.gsd-runtime`
vaut `claude` ici, donc aucun effet immédiat — mais l'hypothèse « le dispatch nommé marche toujours »
est désormais fausse en général, et n'est écrite nulle part chez nous.

### 4. Isolation de l'exécuteur — `executor-isolation-dispatch.md` + namespace de branche élargi

`gsd-executor` acceptait `worktree-agent-<id>` ; il accepte maintenant `agent-<id>` **ou**
`worktree-agent-<id>` (#1995) :

```bash
grep -Eq '^(worktree-)?agent-[A-Za-z0-9._/-]+$'
```

Nouveau cas d'échec de commit également remonté : `{committed: false, reason: 'staging_failed' |
'staging_timeout', file, error}` quand `git add` échoue (#2608) — à ne pas retenter.

**Impact VibeFlow** : à recouper avec `gsd-worktree-path-guard` (câblé dans `settings.json`) et avec
la façon dont nos workers isolent leur travail.

## Le seul défaut actif : l'injection MCP (ADR-051) est structurellement inopérante

La mise à jour a réécrit `~/.claude/agents/gsd-executor.md` (mtime 2026-07-31 11:35, identique à
celui de `gsd-core/VERSION`) et, ce faisant, **effacé `mcp__XcodeBuildMCP__*` de son `tools:`** —
comportement connu, documenté au README v2.43.0 : l'installeur amont classe l'injection en
« local patch ».

État constaté :

```
tools: Read, Write, Edit, Bash, Grep, Glob, Skill,
       mcp__context7__*, mcp__plugin_context7_context7__*
```

Mais la remédiation prévue **ne peut pas fonctionner sur ce poste** : `inject-mcp-tools.sh` dérive
les serveurs de `./.mcp.json` (option `--mcp-json`, défaut `./.mcp.json`), or **aucun lab de
`~/Documents/dev` ne possède de `.mcp.json`** — `XcodeBuildMCP` est déclaré en **scope global** dans
`~/.claude.json`. Le mode `--verify` sort donc en `3 / INDÉTERMINÉ` au lieu de signaler le manque, et
`ensure-deps.sh --migrate-engine` ne rattrape rien.

Conséquence concrète : sur un projet iOS (RoastMyRoom, FreelanceMoneyCalc), `gsd-executor` dispatché
par `vf-coder` est **aveugle à XcodeBuildMCP** — un sous-agent n'hérite pas des serveurs MCP de la
session. Le `CLAUDE.md` de RoastMyRoom impose pourtant XcodeBuildMCP plutôt que `xcodebuild` brut.

C'est le **seul point où 1.9.0 dégrade réellement le fonctionnement**, et sa cause n'est pas la
1.9.0 : c'est une lacune de scope dans notre propre script, révélée à chaque update du moteur.

## Dette de version dans le repo — références figées sur 1.8.0

| Fichier | Nature |
|---|---|
| `plugin/dev-orchestrator/references/gsd-skills-index.md` | **Auto-généré** — en-tête « depuis @opengsd/gsd-core@1.8.0 », daté 2026-07-26. À regénérer via `build-gsd-index.sh` |
| `plugin/dev-orchestrator/references/mission-contracts.md` | Cite « gsd-core 1.8.0 » (:148) et « tag stable = 1.8.0 » (:172) |
| `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` | En-tête (:25) cite « 1.8.0 aujourd'hui » pour illustrer le piège semver |
| `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` | **Cas 8 asserte la présence littérale de la chaîne `1.8.0`** dans l'en-tête ci-dessus — toute mise à jour du texte doit bouger le test avec |
| `plugin/planning-core/scripts/detect-gsd-engine.sh` | Commentaire (:30) « scope --local de gsd-core 1.8.0 » |

⚠️ Le piège semver reste vrai et doit être **préservé** dans la réécriture : le fork repart de zéro,
donc `1.9.0 < 1.42.3` en semver. La migration se décide sur le **nom du paquet et le layout**, jamais
sur la comparaison des numéros.

## Observation annexe — hooks 1.9.0 non câblés

1.9.0 pose des hooks absents de `settings.json` : `gsd-ensure-canonical-path.js` et
`gsd-update-banner.js` (les variantes `gsd-cursor-*` / `gsd-windsurf-*` sont normalement dormantes
hors de leur runtime, `gsd-check-update-worker.js` est un interne appelé par son parent). Rien n'est
cassé, mais une fonctionnalité amont est peut-être inactive faute de câblage. À instruire — sujet
`gsd-core`, pas VibeFlow, sauf si `merge-hooks.sh` doit en tenir compte.

## Pièces

Tarballs comparés : `@opengsd/gsd-core@1.8.0` et `@opengsd/gsd-core@1.9.0` (npm, `latest` = 1.9.0
au 2026-07-31). Dépôt amont : `github.com/open-gsd/gsd-core`.
