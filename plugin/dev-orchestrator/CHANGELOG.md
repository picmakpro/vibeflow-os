# CHANGELOG — dev-orchestrator

## [v2.9.0] — 2026-07-31 (alignement gsd-core 1.9.0, Phase 21)

### Ajouté
- **`inject-mcp-tools.sh` découvre les serveurs MCP en UNION de deux scopes** : `./.mcp.json`
  (projet) **et** `~/.claude.json` clé top-level `mcpServers` (utilisateur/global, `--claude-json`
  ou `VF_CLAUDE_JSON`). Corrige le défaut actif ADR-051 sur tout poste sans `.mcp.json` — un
  serveur déclaré uniquement en scope global (ex. XcodeBuildMCP) était jusqu'ici invisible,
  `--verify` sortait en `3` INDÉTERMINÉ au lieu de signaler l'écart. Dégradation indépendante par
  source, précédence projet > global sur collision, `--strict` signale un nom de serveur cité mais
  inconnu de toutes les sources découvertes (WINDOWS #4 clos).
- **`vf-coder` et `vf-dev-manager` relaient verbatim le contrat `estimate:`/`actuals:` amont**
  (ADR-2629, #2632) : deux champs optionnels frères du bloc typé ADR-053, jamais une statistique
  agrégée du cru de l'agent, absents du rapport si absents en amont.
- **Purge de la dette de version 1.8.0 → 1.9.0** : `gsd-skills-index.md` régénéré,
  `mission-contracts.md`, `check-gsd-engine.sh`, `build-gsd-index.sh` citent désormais 1.9.0. Le
  piège de préservation (cas 8 de `test-check-gsd-engine.sh`, qui asserte la chaîne littérale de
  version dans l'en-tête) a été déplacé avec le texte qu'il vérifie, jamais neutralisé.
- **`team-kernel.md`** documente l'hypothèse datée du dispatch nommé (`hostIntegration.dispatch.namedDispatch`,
  amont 1.9.0) et le recoupement vérifié conforme avec `gsd-worktree-path-guard.js` (#1995, #2608).

Référence : `docs/ADR.md` ADR-061 (recouvrement lanes de revue amont vs étage 20-06), ADR-062
(hooks 1.9.0 non câblés), `.planning/phases/VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0/`.

## [v2.8.0] — 2026-07-31 (fluidité du flux de dev sans perte de qualité, Phase 20)

**Changement de contrat pour quiconque dispatche `vf-coder` : son cycle passe de 4 à 3 étapes,
il ne dispatche plus `vf-reviewer`.**

### Ajouté
- **Mode d'injection MCP nommé** dans `inject-mcp-tools.sh`, déclenché par la clé de frontmatter
  `vf-mcp-tools` (grammaire `<serveur>:<outil1>,<outil2>,…`) : injecte UNIQUEMENT les tokens
  nommés d'un serveur, jamais le joker `mcp__<serveur>__*` du mode existant — les deux modes
  coexistent par fichier (le nommé l'emporte, moindre privilège). `--verify` réutilise le même
  calcul et rend un 3e verdict INDÉTERMINÉ quand le serveur nommé n'est pas résolu.
- **`vf-reviewer` porte l'accès MCP nommé** (`XcodeBuildMCP:test_sim,build_sim,clean`) et son
  protocole de vérification outillée : nettoyage avant toute compilation de vérification,
  paramètres de projet explicites à chaque appel (le serveur maintient un état de session global
  partagé), honnêteté quand le serveur est absent. Coût assumé : ~90s et un slot de simulateur.
  Voir `docs/ADR.md` ADR-051 (révisée), qui documente ce mécanisme.
- **L'étage revue devient un nœud de plan de bataille de premier rang, posé systématiquement par
  le manager et dispatché en direct** (`mission-flow.md` §Pattern E, `docs/ADR.md` ADR-060) : la
  boucle de correction migre vers le manager (mandat ciblé) ; gradation sur 4 déclencheurs
  objectifs (jamais le volume) avec défaut sûr ; revue de jointure obligatoire déclenchée par la
  topologie du DAG ; garde-fou de comblement adossé au champ machine `review_regime` (`dag.sh
  reopen`). La règle `vf-dev-manager.md:108` (« Pas de double revue ») est réécrite en place, pas
  contournée par une exception.
- **`vf-coder` : cycle réduit à 3 étapes** (cadrage → plan → exécution), ne dispatche plus
  `vf-reviewer` et ne reçoit plus de verdict de revue en retour ; allowlist `tools:` inchangée
  caractère pour caractère.
- **`vf-dev-manager` lit `.planning/MISSION-INVARIANTS.md`** au même rang que l'état du projet, et
  porte le filet de repli sur `AskUserQuestion` absent au runtime en dispatch sous-agent (le
  besoin humain remonte dans le rapport typé, jamais auto-répondu en silence).

Référence : `docs/ADR.md` ADR-051 (révisée), ADR-060 (nouvelle),
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v2.7.1] — 2026-07-28 (isolation de branche des missions d'équipe, ADR-059)

**Une mission d'équipe ne commite plus jamais sur la branche par défaut.** Dès qu'un manager est
dispatché, il crée sa branche **avant son premier commit**, y tient tous ses commits, et termine par
une **PR laissée ouverte** — le merge appartient à l'utilisateur (ADR-031). Le travail
conversationnel direct (correctif, doc, cadrage mené dans le fil) reste hors de la règle.

**Origine** : constaté sur le dépôt VibeFlow le 2026-07-28 — la mission Phase 19 a produit **32
commits directement sur `main`**, poussés puis taggés. Aucun dégât, mais le recours en cas de mission
ratée était un `revert` en masse d'un historique déjà public. Sur une branche, le recours est de ne
pas merger. La PR fournit en prime le point de relecture groupée qu'un rapport de fin de mission — 
rédigé **par** l'agent qui a fait le travail, et lu trop tard — ne remplace pas.

**Cinq replis, pour qu'une mission n'échoue jamais faute d'appliquer la règle** : pas de dépôt git →
aucune branche, signalé ; pas de remote → branche sans PR ; `gh` absent → branche poussée et URL de
création de PR donnée ; **arbre sale au démarrage → halt condition**, jamais un `stash` décidé seul ;
`CLAUDE.md` du projet cible imposant un autre flux → le projet cible **prime**.

**Ne couvre pas** : l'isolation des vagues parallèles **à l'intérieur** d'une mission, qui partagent
le même arbre de travail — seul `isolation: worktree` le ferait. Décision distincte, laissée ouverte.

Fichiers : `references/mission-contracts.md` (§Isolation de branche — protocole, conventions de nom,
table des replis) · `agents/vf-dev-manager.md` §Garanties.

## [v2.7.0] — 2026-07-28 (migration du moteur GSD pilotée par /vf-update, Phase 19)

### Ajouté
- **`scripts/check-gsd-engine.sh`** (nouveau) : gate de constat à 3 états
  (absent/legacy/gsd-core), lecture seule, exits `0`/`2`/`3` — classement décidé exclusivement sur
  la présence des fichiers `VERSION` du poste, jamais sur leur numéro (le legacy `get-shit-done-cc`
  figé à `1.42.3` reste actionnable même face à un `@opengsd/gsd-core` `1.8.0`, malgré
  `1.8.0 < 1.42.3` en semver). Signal `[gsd-migrate]` pour l'état actionnable, `[gsd-leftover]`
  pour le cas dual gsd-core + reliquat legacy (rupture assumée de « exit 3 == silence »).
- **`scripts/tests/test-check-gsd-engine.sh`** (nouveau) : suite dédiée, 15 cas en boîte noire,
  verte macOS et Linux (`ubuntu:24.04`).
- **`ensure-deps.sh` : `detect_gsd()` cesse de skipper le legacy**. `detect_gsd_state()` rend un
  état à 3 valeurs ; un moteur legacy est désormais **signalé** (jamais migré sans autorisation) au
  lieu d'être silencieusement sauté. Nouveau chemin **`--migrate-engine`**
  (+ `VF_ENSURE_MIGRATE_ENGINE=1`) qui enchaîne, dans le même run, l'install `npx` existante
  (plafond `@opengsd/gsd-core@^1` intouché) puis `patch_gsd_executor_mcp()` — la ré-injection MCP
  ne peut donc plus être oubliée après une migration.
- **Message de nettoyage legacy corrigé** : l'état legacy est capturé **avant** toute install
  (l'installeur amont supprime lui-même son propre témoin `VERSION` à l'install réussie — le
  message survit désormais à cette suppression) ; les deux lignes `npm uninstall -g` ne sont
  proposées que si `npm ls -g` confirme réellement le paquet installé en global ; le retrait de
  l'arborescence vide laissée debout est ajouté à la proposition (toujours affiché, jamais exécuté
  — ADR-031).
- **`scripts/inject-mcp-tools.sh` : mode `--verify`** (nouveau) — relit le `tools:` final de la
  cible et le compare aux serveurs dérivés du `.mcp.json` du lab, exits `0`/`1`/`3` (jamais un faux
  vert si python3 est absent) ; dit fort un serveur manquant, ne répare jamais. Branché en
  best-effort dans `patch_gsd_executor_mcp()`, après l'injection, hors dry-run uniquement.

### Corrigé
- **`patch_gsd_executor_mcp()` : `--verify` portait sur une cible différente de l'injection.**
  L'appel d'injection (ligne ~394) passait `--force` (requis : `gsd-executor.md` ne porte pas le
  flag `vf-mcp-consumer`, fichier hors plugin) mais l'appel `--verify` (ligne ~409) en était
  dépourvu — `inject-mcp-tools.sh` écartait alors systématiquement la cible en mode fichier unique
  (`single and not force and not has_flag(text)`), rendant le verdict **toujours** `3`
  (INDÉTERMINÉ), jamais `0` (conforme) ni `1` (écart réel) : un garde-fou qui ne pouvait jamais
  rendre de verdict. `--force` ajouté sur l'appel `--verify`, même cible que l'injection.
- **Contrat de relais F13** : seul `rc=1` (écart réel, serveur manquant) est désormais relayé en
  `ERROR` sur stderr. `rc=3` (INDÉTERMINÉ — `.mcp.json` absent, aucun serveur déclaré, rien à
  comparer) n'est **plus** une alarme bruyante à chaque bootstrap ; il passe en `log` informatif.
  `rc=0` (conforme) ne logue plus rien. Preuve de létalité : suppression du bloc `--verify` →
  1 KO nouveau (`test-dev-orchestrator.sh` T2m) contre 0 KO avant, sur une mutation qui survivait
  jusqu'ici silencieusement (les cas T10/T11 de `test-inject-mcp-tools.sh` exerçaient
  `--force --verify` directement, une forme que la production n'émettait jamais).
- **`test-dev-orchestrator.sh` T2m (nouveau)** : exerce le chaînage réel de
  `patch_gsd_executor_mcp()` (jamais un appel manuel à `inject-mcp-tools.sh --force --verify`) —
  stub d'injection silencieusement no-op + vrai injecteur en `--verify`, pour produire un écart
  réel (`rc=1`) déterministe et portable (root Docker Linux contourne les permissions fichier,
  écarté comme moyen de test).
- **`test-dev-orchestrator.sh` T2n (nouveau)** : couvre l'autre moitié du contrat F13 — `rc=3`
  (rien à comparer) ne lève jamais d'alarme `[ensure-deps] ERROR:`, dans le même chaînage réel que
  T2m. Comblait une mutation survivante (`rc=3` re-alarmé, `log` → `err`) qui passait sur les trois
  suites du gate.

### Fait mesuré
- Audit externe du 2026-07-28 : sur un poste où le plugin VibeFlow était déjà à jour, le moteur GSD
  était resté sur `get-shit-done-cc` (paquet déprécié, figé à `1.42.3`) sans qu'aucun signal ne le
  dise — le chemin de mise à jour nominal (`/vf-update`) ne consultait jamais l'état du moteur.
- Vérification goal-backward Phase 19 (mandat n2-bis, 2026-07-28) : gap sur la 2e clause du
  critère de succès SC3 — voir « Corrigé » ci-dessus.

Référence : `docs/ADR.md` ADR-058, `.planning/phases/VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update/`.

## [v2.6.0] — 2026-07-27 (signaux de démarrage du moteur de dev, Phase 17)

### Ajouté
- **Premier fragment `hooks/hooks.json` du module** : `SessionStart:startup`, 3 commandes
  tolérantes à l'échec (`|| true`) — `dev-orchestrator` était le seul module structurant sans
  hooks, `discover-unintegrated-docs.sh` (livré Phase 13) n'était donc jamais appelé
  automatiquement.
- **`scripts/check-dev-bootstrap.sh`** (nouveau) : continuum à 4 états mutuellement exclusifs
  (silence / `[onboard]` / `[bootstrap]` / `[gsd-engine]`), premier qui matche gagne — brownfield
  non initialisé, bootstrap incomplet (items `config`/`codebase`/`roadmap` restitués en ordre
  figé), et orientation moteur GSD lue depuis le frontmatter assaini de `.planning/STATE.md`
  (liste blanche stricte, soupape de sûreté D-04). Contrat de sortie 0/3/64, lecture seule.
- **`scripts/check-doc-drift.sh`** (nouveau) : dérive documentaire — commits de code depuis le
  dernier commit ayant touché `docs/**` ou un `README*` racine, seuil réglable `--threshold`
  (défaut 20). Premier script du module à shell-out vers git, durci systématiquement
  (`core.fsmonitor=`, `core.hooksPath=/dev/null`, `--no-optional-locks`, variables
  `GIT_CONFIG_NOSYSTEM`/`GIT_TERMINAL_PROMPT`/`GIT_OPTIONAL_LOCKS`).
- **`scripts/discover-unintegrated-docs.sh --hook`** (extension additive) : ligne agrégée
  `[docs-ingest] N documents…` au lieu de la liste — le contrat historique (`grain<TAB>chemin`,
  exits 0/3/64, sans `--hook`) reste strictement inchangé, prouvé non-régressif octet pour octet.
- **3 nouvelles suites de test** : `test-check-dev-bootstrap.sh` (23 assertions),
  `test-check-doc-drift.sh` (21 assertions, fixtures git réelles), extension de
  `test-discover-unintegrated-docs.sh` (16 cas historiques + 6 cas `--hook`, 22 au total).
- **`AGENT.md`** : section « Signaux de démarrage » (4 lignes : `[bootstrap]`, `[onboard]`,
  `[gsd-engine]`, `[doc-drift]` → geste proposé, confirmation ADR-031) — `[docs-ingest]` reste
  couvert par la table « Amont & cadrage » existante, pas de doctrine parallèle.
- **`test-dev-orchestrator.sh` : axes T20/T21**, fermant le gate ADR-044 (T20, `check-agents.sh
  --file` sur `AGENT.md`, triple assertion exit/compte-warnings/types) et les invariants SC5
  (T21, grep structurel sur les 2 nouveaux scripts — aucun `exit 1`, aucune écriture hors
  `/dev/null`/descripteur/variable `*TMP*`, tout `mktemp` apparié à un `trap ... EXIT`). Suite
  portée à **60 axes** (0 KO), ramassés par la découverte générique de `ci.yml:32` sans édition.
- Portabilité prouvée en conteneur `ubuntu:24.04` (bash 5.2, git 2.43, python3 3.12) avant push,
  en plus de macOS.

Référence : `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`.

## [v2.5.0] — 2026-07-27 (allowlists `Agent(...)` sur les 3 workers internes, Phase 16)

### Ajouté
- **Allowlists `Agent(...)` posées sur les 3 workers internes**, fermant le chemin indirect
  manager → worker → manager : `vf-coder` (**22 noms**), `vf-reviewer` (**1** — `gsd-code-reviewer`),
  `vf-auditer` (**1** — `gsd-security-auditor`). Aucun manager (`vf-dev-manager`,
  `vf-design-manager`) ne figure dans aucune des trois listes. Recensement obtenu par **deux
  dérivations indépendantes** réconciliées : la couche décisive est celle des agents dispatchés
  par les **skills** que ces workers invoquent — aucune skill ne déclarant `context:`, ses
  `Task(...)` internes s'exécutent sous l'allowlist de l'agent appelant.
- `references/mission-cross-team.md` : les passages qui décrivaient ces workers comme gardant un
  `Agent` non scopé sont corrigés pour refléter le cloisonnement désormais posé.
- `agents/vf-coder.md` : l'échappatoire « dispatche l'agent équivalent via Task » devient
  « parmi les agents listés dans ton champ `tools:` ; sinon remonte `blocked` » — sans cette
  précision, une allowlist fermée transformait silencieusement une permission documentée en refus
  muet.

### Tests
- Axes **T19 → T19f** : allowlist nom par nom (extraction bornée à l'intérieur d'`Agent(...)`),
  absence de manager, aucun `Agent` nu, parenthèses correctement refermées (comptage de
  profondeur), `general-purpose` nommément testé (cadrage non-interactif de `vf-coder`), garde
  anti-homonyme (un nom préfixe littéral d'un autre ne le valide jamais). Suite **50 → 51 axes**.

## [v2.4.0] — 2026-07-27 (étages croisés dev ↔ design, Phase 15)

### Ajouté
- **Étage design croisé** : `vf-dev-manager` peut désormais dispatcher `vf-crafter` (nœuds
  `craft:<écran>`) avant l'exécution d'une étape à dominante UI, et `vf-design-judge` (nœuds
  `critique:<écran>`) en parallèle de la revue code — sans jamais dispatcher
  `vf-design-manager` (cloisonnement manager→manager porté par le verrou de driver). Nouvelle
  référence `references/mission-cross-team.md` (doctrine des étages croisés) et « Pattern D »
  documenté dans `mission-flow.md`.
- `references/mission-contracts.md` : deux nouveaux champs de brief — `design: auto|force|off`
  (défaut `auto`) et `livrable: specs|specs+implementation` (défaut `specs`) — et digest de
  mission enrichi pour les mandats croisés.
- `skills/vf-auto/SKILL.md` : aiguillage corrigé — une mission entièrement design part vers
  `Task(vf-design-manager)`, toute mission mixte ou dev vers `Task(vf-dev-manager)` (corrige un
  chemin de dispatch mort : la description publiée de `vf-design-manager` annonçait déjà ce
  routage).
- Allowlist `Agent(...)` de `vf-dev-manager` portée à 18 noms (cloisonnement Pattern 12) ;
  descriptions de `vf-coder`/`vf-reviewer` élargies au dispatch par les deux managers.
- Suite de tests : T18/T18b (cloisonnement par allowlist `Agent(...)`, doctrine d'étage design,
  routage `vf-auto`).

## [v2.3.2] — 2026-07-27

### Corrigé
- `tests/test-dev-orchestrator.sh` T2b : stub CLI `claude` posé en tête de PATH pour les invocations dry-run — le test observait les commandes loguées mais dépendait de l'outillage réel de l'hôte : sur une machine sans `claude` (runner CI), `ensure_superpowers` basculait en « étape manuelle » sans loguer `--scope <scope>` et les 4 assertions échouaient à tort. Reproduit sous ubuntu:24.04.

## [v2.3.1] — 2026-07-26

### Sécurité
- Plafond semver sur l'install GSD : `@opengsd/gsd-core@^1` au lieu de `@latest` (arbitrage
  post-audit Phase 11) — fraîcheur conservée dans la majeure 1.x, mais un saut de majeure
  (breaking ou compromission d'un fork jeune) ne s'installe jamais sans décision humaine.

## [v2.3.0] — 2026-07-26

### Ajouté
- **Bascule `@opengsd/gsd-core`** (Phase 11, intégration migration GSD) : `ensure-deps.sh`
  installe désormais le paquet npm `@opengsd/gsd-core` (dual-layout — `gsd-core` prioritaire,
  `get-shit-done` legacy en repli, jamais de test PATH pour la détection — piège n°1
  neutralisé), garde Node ≥ 22 (`@opengsd/gsd-core` cible Node 22+, message d'erreur explicite
  sinon), nettoyage des artefacts legacy **affiché mais jamais exécuté** (ADR-031) quand
  `~/.claude/get-shit-done/` est détecté au prochain run.
- Migration des références internes `gsd-sdk` → `gsd-tools` (cascade de résolution documentée
  dans `references/mission-contracts.md`, jamais un chemin en dur).
- Routage `gsd-onboard` sur brownfield (FIRST-02) avec fallback si l'engine n'est pas encore
  posé.
- Canal 4 de la carte d'intention : `gsd-next`, `gsd-mempalace-*` explicitement **non routés**
  (documentés pour mémoire, pas d'invocation directe depuis l'agent).
- Index factuel `gsd-skills` régénéré (gsd-core 1.8.0).

**Note de transition (labs existants)** : un lab encore sur l'ancien layout `get-shit-done`
verra `ensure-deps.sh` **afficher** (jamais exécuter) 3 commandes de nettoyage manuel au
prochain run — aucune action automatique sur les artefacts legacy, confirmation humaine requise.

**Note de veille (décision D5, amendement recherche documentaire vague 11-02)** : à chaque bump
de `gsd-core`, re-différer l'ordre de la cascade de résolution `gsd-tools` documentée dans
`mission-contracts.md` contre `gsd-core/workflows/_runtime-launcher.snippet.sh` amont — le
mapping peut évoluer entre versions du paquet.

## [v2.2.1] — 2026-07-26

### Corrigé
- Échappatoire ADR-031 fermée sur l'ingestion (finding de l'audit BRDG-03) : `vf-dev-manager`
  porte désormais une ligne **nominative** dans ses exceptions d'autonomie — l'ingestion d'un
  cadrage (`gsd-ingest-docs` / `gsd-import`, doctrine `ingestion-flow.md`) remonte TOUJOURS à
  l'utilisateur, jamais déclenchée depuis une mission sans confirmation humaine explicite.
  La protection n'était jusqu'ici ancrée textuellement qu'à `vibeflow-dev`.

## [v2.2.0] — 2026-07-26

### Ajouté
- Câblage de l'ingestion (BRDG-01/BRDG-03) dans `vibeflow-dev` — doctrine
  `references/ingestion-flow.md` (découverte via `discover-unintegrated-docs.sh` livré par la
  phase 13/plan 13-01, construction du manifest, délégation `gsd-ingest-docs --mode merge` /
  `gsd-import --from`, garde-fous BLOCKER/ADR-031/mode merge/cap 50), next step proposé en fin de
  cadrage (spec/plan écrit(e) non encore dans la feuille de route), axes de test T16/T17.

## [v2.1.1] — 2026-07-26

### Corrigé
- Recette dev en lab sandbox : cascade `$S` — le lab courant prime sur le scope user (divergence de version silencieuse) et les deux énoncés sont alignés ; doctrine `human_needed` en autonome tranchée (geler le nœud porteur, jamais « continuer ») ; fallback documenté si `gsd-sdk` absent ; les 3 exceptions de routage écrites dans la carte ; `requires` += `conductor` (team-kernel).

## [v2.1.0] — 2026-07-25

### Ajouté
- Pipelining N/N+1 : modélisation fine du DAG (discuss/plan/execute par étape), cadrage+plan de l'étape suivante pendant l'exécution de la courante, règle du plan provisoire re-validé par le plan-checker, garde-fou coût (≥ 2 étapes, jamais en mode superviser). dag.sh/driver-lock.sh consommés depuis le team-kernel du conductor (fallback conservé).

## [v2.0.0] — 2026-07-25

**BREAKING — bascule vers le modèle agentique** (spec
`2026-07-25-suppression-facade-vf-design.md`, arbitrage direct après l'audit croisé vague 2 :
la façade de verbes doublait un catalogue gsd-* qui reste exposé en session — la concurrence
de routage qu'elle prétendait résoudre était celle qu'elle créait).

### Supprimé
- **Les 29 verbes-façades `/vf-*`** (tout `skills/` sauf `vf-auto`, et `vf-dev` réduit à
  l'incarnation de l'agent) : les briques gsd-* redeviennent l'interface directe du quotidien,
  leurs descriptions déclenchent nativement, sans couche de synonymes.
- **La rule de préséance** (`rules/vf-verb-precedence.md`) et les matrices de renvois négatifs
  croisés entre descriptions — n'ont plus d'objet sans la façade.
- **Le reframe** (`vocabulary-map.md` et le boilerplate « Ne nomme jamais GSD » ×30) : le
  vocabulaire GSD peut apparaître, la clarté prime sur la traduction.
- Les tests de collision/préséance/synchro de table (anciens T3-verbes, T12, T13) — remplacés
  par les tests du modèle agentique (voir README §Tests).

### Ajouté / Modifié
- **Carte d'intention unique** : `references/intent-routing.md` refondu de « table des 31
  verbes » en « carte intention → brique gsd / équipe » — seule source de routage, consommée
  on-demand par les 2 agents.
- **Manager agentique** (`vf-dev-manager`) : détection d'intention (brief en langage naturel
  brut mappé via la carte), **next steps** proposés depuis ROADMAP/STATE en fin d'étape et de
  mission, **hygiène documentaire** à critères explicites (fin d'étape, décision structurante,
  drift détecté — jamais au fil de l'eau), **digest de mission** ≤ 30 lignes par mandat
  (amortit les relectures intégrales de `.planning/` par étage).
- **`AGENT.md` (vibeflow-dev)** refondu : intention → brique gsd directe, raccourcis dominants
  + carte exhaustive on-demand, garde-fou first-use conservé (FIRST-01/02, BOOT-04).
- **ADR-045 côté mobile en 1 saut** : les workers cloisonnés remontent
  `doc-research-required` directement à l'orchestrateur qui porte le web — plus de relais en
  cascade.
- **Rapports allégés** : les workers rendent le bloc typé + le strict nécessaire, le détail va
  sur disque (`.planning/missions/`) — le manager pilote sur le bloc typé seul.
- `module.json` / README / tests réécrits pour le modèle agentique (2 skills survivants,
  équipe de mission, carte unique).

## [v1.8.2] — 2026-07-25

### Modifié
- Audit 2026-07-25 vague 1 : workers et juges en sonnet (doctrine model-profiles), cadrage non-interactif explicite de vf-coder (`--auto`, plus de checkpoint mort), dispatch parallèle de la frontière DAG et des juges (revue ∥ audit, fusion des findings, un seul reopen), fin de la double revue ; exception panel en mission documentée (vf-decide).

## [v1.8.1] — 2026-07-25 (soldes de l'étape 12)

### Corrigé
- **Frontière d'altitude (ADR-055)** portée par les descriptions : `vf-milestone`, `vf-phase`,
  `vf-backlog`, `vf-resume` et `vf-pause` opèrent sur le `.planning/` d'un **projet de code** —
  ils renvoient désormais vers `/vf-planning` pour l'altitude **lab** et les labs non-dev.
  `/vf-plan`, `/vf-init`, `/vf-progress`, `/vf-docs`, `/vf-cleanup` et `/vf-dev` le faisaient
  déjà ; les cinq manquants fermaient mal la frontière que l'ADR-055 venait de poser.
- **T5 et T11 bornés au module.** Les deux axes balayaient tout `skills/` et `agents/`, plats et
  partagés entre modules en lab installé : un fichier d'un module voisin pouvait faire rougir la
  suite du `dev-orchestrator`. T5 réutilise `owned_verb()` ; T11 est borné à l'agent, ses
  references et ses quatre agents d'équipe.
- **T11 dé-nommé et recentré sur la cause réelle** : il traque un renvoi vers `.planning/research/`
  ou `docs/_mission/` — dossiers du dépôt de développement, jamais installés, donc liens morts en
  lab — au lieu du nom d'un projet tiers.
- **Résidu de projet tiers** retiré de `references/autonomous-guardrails.md` (le dépôt est public).

## [v1.8.0] — 2026-07-25 (routage fin : 31 verbes, préséance, doctrine exhaustive)

Le module ne couvrait que 14 intentions sur les ~65 gestes de la chaîne interne : tout le reste
n'avait pas de porte d'entrée et se jouait au hasard du matching sémantique. Cette version pose
les **trois niveaux de routage** de la spec `2026-07-25-routage-fin-verbes-vf-design.md`.

### Ajouté

- **17 verbes** neufs (le module en compte **31**), chacun un délégateur mince vers sa cible :
  - *amont & cadrage* — `/vf-explore` (idée floue), `/vf-spike` (code jetable), `/vf-spec` (le QUOI) ;
  - *qualité & audits* — `/vf-testgen`, `/vf-gaps` (dette et recettes en souffrance), `/vf-secure`,
    `/vf-forensics` (post-mortem de cycle), `/vf-inbox` (issues et PR entrantes) ;
  - *cycle de vie projet* — `/vf-milestone`, `/vf-phase`, `/vf-undo`, `/vf-backlog`, `/vf-cleanup` ;
  - *contexte & session* — `/vf-resume`, `/vf-pause`, `/vf-docs`, `/vf-learn`.
- **`rules/vf-verb-precedence.md`** — rule **globale (Tier 1)**, 40 L : une intention de dev entre
  dans la chaîne **par un verbe**, jamais par un skill interne appelé en direct. Échappatoire
  cadrée + pièges connus. Volontairement **sans `paths:`** (voir *Prérequis* ci-dessous).
- **`references/intent-routing.md`** — doctrine de routage exhaustive (intention → verbe → cible),
  couvrant **100 %** des skills de l'index factuel, y compris les gestes d'outillage sans verbe
  dédié. Chargée **on-demand** : coût contexte nul le reste du temps.
- **Tests** : `T12` anti-collision (réciprocité stricte sur les groupes de collision, chasse gardée
  de `/vf-audit`, les deux modules lus), `T13` préséance (rule conforme, référencée, table de
  routage sans cible interne), `T14` exhaustivité (index entièrement routé + toute cible promise
  par la doctrine est bien citée par le verbe qui la porte).

### Modifié

- **Descriptions des 14 verbes existants** réécrites sur un gabarit unique : formulations FR
  réelles, contre-exemples nommant les voisins (`✘ … → /vf-…`), portée d'invocation. C'est la
  description qui départage deux gestes proches — elle est le code du routeur, pas de la doc.
- **`AGENT.md` refondu** : la table de routage associe une intention à un **verbe**, plus jamais à
  une cible interne (218 L, groupée par famille). L'idée floue part désormais vers `/vf-explore` et
  non plus vers la conception d'une solution. Renvois ajoutés vers la rule de préséance et vers
  `intent-routing.md`.
- **`vf-dev`** (point d'entrée générique) : sa mini-table ne connaissait que les 14 anciens verbes ;
  elle aiguille désormais par famille vers les 31.
- **`T3`** compte maintenant les **verbes** distincts de la table de routage (seuil inchangé, ≥ 11).
  Il comptait des cibles `gsd-*` — ce que le nouveau contrat interdit précisément dans la table.
- **Fixture `FIXTURE_TARGETS` (T4)** étendue à **toutes** les cibles portées par un verbe. Sans
  cela, chaque verbe ajouté sortait « orphelin » sur un poste sans chaîne interne installée : le
  test passait en local et échouait en CI.

### Prérequis

- **Claude Code ≥ v2.1.198** — c'est la version qui apporte le mécanisme natif `.claude/rules/`,
  sans lequel le niveau 2 (préséance) n'est pas opérant.
- Une rule **sans** frontmatter `paths:` est chargée **inconditionnellement au lancement**, à la
  même priorité que `CLAUDE.md` ; une rule **avec** `paths:` n'est chargée qu'à la lecture d'un
  fichier correspondant. `vf-verb-precedence.md` doit donc rester **sans `paths:`** : une intention
  n'a pas de chemin de fichier, elle est inscopable par construction. (`paths` est le seul champ
  documenté — source : documentation officielle Claude Code, `memory.md`.)

### Non compris

- `/vf-ingest` (intégration de specs et de plans existants) arrive à l'**étape suivante** : sa
  place est réservée dans la doctrine et dans la fixture de test, son verbe n'est pas encore écrit.
- Aucun bump de la version racine ni tag : la release est portée par la clôture du jalon.

## [v1.7.0] — 2026-07-22 (ADR-053 — volet swarm : lock de driver + DAG + rapports typés)

### Ajouté
- **Pattern A — Lock de driver unique** : `scripts/driver-lock.sh` (acquisition atomique par `mkdir`,
  heartbeat, release, **récupération de claim périmé** via TTL). Empêche deux missions de piloter la même
  étape en parallèle (protège les backups isolés ADR-048/049). `vf-dev-manager` l'acquiert avant tout
  dispatch, rafraîchit le heartbeat entre étapes, le relâche à la clôture. 26 tests (dont concurrence réelle).
- **Pattern B — DAG de tâches** : `scripts/dag.sh` (nœuds `ready`/`blocked`, frontière dispatchable,
  `reopen` = ré-entrée avec reset transitif des dépendants, remap `id::stage` sur collision, commande
  `tree` = rendu arbre du plan de bataille avec passe orpheline pour composants cycliques). Le plan de
  bataille du manager devient un graphe persistant. 29 tests.
- **Pattern C — Rapports de worker typés** : `vf-coder`/`vf-reviewer`/`vf-auditer` (+ `vf-test-orchestrator`
  du module mobile-test-team) terminent par `{statut, findings[{action: auto-fix|no-op|ask-user}],
  noeuds_debloques}` → contrôle de flux déterministe côté manager (raffine ADR-031).
- `references/mission-flow.md` : protocole complet A/B/C (source de vérité).
- **Résolution de scripts scope-robuste** : le manager résout `$S` (cascade `$HOME/.claude/scripts` →
  `./.claude/scripts` → plugin root) au lieu de présumer `./.claude` — le swarm fonctionne quel que soit
  le scope d'install du lab (user OU projet, ID4). Sans ça, un lab en scope user ne trouvait pas les scripts.

### Note
- Pas de RAII machine (un agent LLM peut mourir sans release) → la récupération de claim périmé
  (heartbeat + TTL) est **obligatoire**, pas optionnelle. Réalisé par fichiers d'état, sans bus temps réel.

## [v1.6.0] — 2026-07-19 (ADR-051)

Allowlist MCP des agents exécutants dérivée du lab — les sous-agents voient enfin les serveurs MCP
du projet (XcodeBuildMCP, mobile-mcp, DB métier…).

### Ajouté
- **`scripts/inject-mcp-tools.sh`** : injecteur idempotent. Lit les serveurs du `./.mcp.json` du lab
  et injecte `mcp__<serveur>__*` dans le `tools:` des agents flaggés `vf-mcp-consumer: true` (ou d'un
  fichier `--force`). Aucun nom de serveur ni d'agent en dur ; best-effort (python3/`.mcp.json`
  absents → no-op) ; `--dry-run`. Le glob `mcp__*` étant **refusé** en allowlist `tools:` (seul
  `disallowedTools` l'accepte), l'injection par-serveur est la seule voie générique.
- **`scripts/tests/test-inject-mcp-tools.sh`** : 10 cas (dossier, idempotence, `--force`, refus sans
  flag, no-op sans `.mcp.json`, hérite-tout, `--servers`, tri déterministe) — tous verts.
- **`agents/vf-coder.md`** : flag `vf-mcp-consumer: true` (exécutant : build/test).
- **`scripts/ensure-deps.sh`** : `patch_gsd_executor_mcp` — après l'install GSD, injecte les serveurs
  du lab dans `~/.claude/agents/gsd-executor.md` (`--force`, hors plugin). Re-jouable → auto-réparateur
  après une réinstall GSD.

### Note
- Le `tools:` d'un agent est lu au **démarrage de session** : **redémarrer Claude Code** après
  (ré)install pour que la nouvelle allowlist prenne effet.

## [v1.5.0] — 2026-07-09

Équipe manager de mission (pattern généralisé — spec 2026-07-09, ADR-046).

- **4 agents natifs** (`agents/`) : `vf-dev-manager` (sommet — planifie, décide via panels,
  distribue, contrôle de flux entre étages) + workers internes `vf-coder` (cycle d'étape),
  `vf-reviewer` (revue sans écriture), `vf-auditer` (audit sécu/dette sans écriture).
  Conformes ADR-044 ; workers `vf-internal: true` (Pattern 12).
- **Contrats de mission** (`references/mission-contracts.md`) : brief main→manager, rapport
  manager→main, signaux « mission », seuil `SEUIL_EQUIPE` — source unique (DRY).
- **Router** : détection de mission + proposition de l'équipe (heuristique 7, jamais d'office).
- **vf-auto** : aiguillage taille — court → boucle autonome inline, long → équipe.
- **Tests** : T8-T11 (conformité agents, contrats, routage, généricité).

## [v1.4.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Recherche documentaire avant debug** (ADR-045), câblée dans trois briques :
  - `skills/vf-debug/SKILL.md` : **pré-étape obligatoire** avant la délégation à `gsd-debug` — si
    déclencheur (lib/framework/natif/version, ou fix déjà échoué), recherche context7 + issues
    GitHub d'abord, pistes priorisées et sourcées.
  - `AGENT.md` (`vibeflow-dev`) : la route « débugge » passe par le gate recherche-doc ; nouvelle
    heuristique de routage n°6 (le pilote a l'héritage web, il porte la recherche que les workers
    cloisonnés remontent via `doc-research-required`).
  - `references/autonomous-guardrails.md` : **6ᵉ garde-fou** « recherche doc avant debug empirique »
    + champ `maxResearchRoundsPerFlow` (défaut 2) au schéma `night-run.json` — la recherche précède
    les tentatives, ne consomme pas de slot `maxAttemptsPerFlow`, mais compte dans le budget global.
- Règle canonique référencée : `doc-research-before-debug` (module `software-architecture`).

## [v1.3.0] — 2026-07-08

### Ajouté
- **Routage des phases de design → `/vf-design`.** Nouvelle ligne dans la table de routage de
  `vibeflow-dev` (« design / UI / c'est moche / la DA / le style / refais l'écran / la typo /
  le spacing » → verbe `vf-design`, agent `vibeflow-design`) et dans le point d'entrée `vf-dev`.
  Un cycle de développement couvre désormais explicitement la phase de design sans quitter le
  vocabulaire VibeFlow.
- **Dépendance `design-orchestrator`** (`requires`) : le module design est **installé d'office**
  avec `dev-orchestrator`. Tout lab de développement dispose de `/vf-design` sans action
  supplémentaire (résolveur de deps transitif → `install --with-deps`).

## [v1.2.0] — 2026-07-07

### Ajouté
- **Verbe `/vf-decide`** — panel de décision pour trancher une zone grise technique (compare
  des options, produit un tableau comparatif sourcé + reco). Délègue au **mode advisor de
  `gsd-discuss-phase`** (qui orchestre le panel de recherche décisionnelle) — on route vers le
  skill canonique, jamais vers un agent en direct. Porte le total à **14 verbes `/vf-*`**. Ajouté
  à la table de routage de `vibeflow-dev` et à `vocabulary-map.md` (« advisor » → panel de décision).
- **Référence `references/autonomous-guardrails.md`** — doctrine des 5 garde-fous de boucle
  autonome (anti-thrash N=3, anti-régression revert, arrêt vert/plafond, séparation anti-triche,
  rapport de synthèse). Branchée sur `vf-auto` (section « Garde-fous (non supervisé) »). Extraite
  et généralisée depuis le track « équipe d'agents » (couche B).

### Note
- La séparation anti-triche s'appuie sur le **Pattern 12 — Cloisonnement par outils**
  (module `reference`).

## [v1.1.0] — 2026-06-04

### Ajouté
- **Verbe `/vf-map`** — cartographie d'un code existant (délègue à `gsd-map-codebase`),
  construit selon la discipline `writing-skills`. Complète `vf-init` (bootstrap + démarrage
  projet) pour couvrir explicitement le parcours « projet existant ». Porte le total à
  **13 verbes `/vf-*`**.
- README : section Usage enrichie — routage NL init/map, parcours types (premier contact,
  projet existant, tâche rapide, autonomie), verbe `vf-map`.

### Corrigé
- `test-dev-orchestrator.sh` portable : détecte la disposition source (`AGENT.md` + `references/`
  à la racine) vs lab installé (`agents/dev-orchestrator.md` + `agents/<mod>-references/`, D7).
  Le test shippé ne produit plus de faux échecs quand il est lancé depuis un lab.

## [v1.0.0] — 2026-06-04

### Module initial complet (5 plans, phase 01-dev-orchestrator)

**Squelette du module**
- Structure conforme aux modules vibeflow-os (`VERSION`, `CHANGELOG.md`, `README.md`, `references/`, `scripts/`)
- Type : agent + multi-skills + scripts (orchestrateur de développement)

**Index auto-généré (D4 — anti-hallucination)**
- Script `build-gsd-index.sh` qui génère `references/gsd-skills-index.md` à partir des skills GSD réellement installés (`~/.claude/skills/gsd-*`)
- Aucun nom de skill écrit en dur : extraction factuelle du frontmatter (`name` + `description`)
- Contrat de sortie `VF_INDEX_OUT` surchargeable (consommé par le hook post-install, D7)
- Idempotent : ré-exécution = régénération complète (IDX-02)

**Agent routeur (Plan 03)**
- `AGENT.md` (`vibeflow-dev`, ≤250L) : routage langage naturel → action, 14 cibles distinctes
- Doctrine pipeline déportée `references/GSD-PIPELINE.md` (chargée on-demand)
- Ne nomme jamais GSD/Superpowers ; reframe en vocabulaire VibeFlow

**Couche d'abstraction (Plan 04)**
- 12 verbes `/vf-*` thin delegators (construits via `writing-skills`)
- `references/vocabulary-map.md` (traduction GSD → VibeFlow)

**Bootstrap + intégration (Plan 02 & 05)**
- `ensure-deps.sh` : auto-install non-interactif idempotent de GSD + Superpowers, fallback manuel
- `vibeflow-update.sh` étendu : copie des references d'un module agent sous `.claude/agents/<mod>-references/` (D7) + hook post-install régénérant l'index (IDX-02)
- Suite `test-dev-orchestrator.sh` (4 axes VERIF-01 + densité `wc -l` VERIF-02)
