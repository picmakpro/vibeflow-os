# Phase 19: Migration du moteur GSD pilotée par /vf-update - Context

**Gathered:** 2026-07-28 (mode interactif, 6 arbitrages tranchés par Samuel)
**Status:** Ready for planning

<domain>
## Phase Boundary

Sources : `.planning/ROADMAP.md` §Phase 19 (7 critères de succès) + le rapport d'audit externe
`.planning/missions/2026-07-28-audit-externe-migration-opengsd.md` (250 lignes, lu intégralement,
**5 constats recoupés ligne à ligne dans ce repo** avant ouverture de la phase).

La phase fait que **le chemin de mise à jour nominal voie l'état du moteur GSD et propose la
bascule** `get-shit-done-cc` → `@opengsd/gsd-core`, sans jamais l'imposer, et sans casser le repli
legacy des postes non migrés.

**Livre :**

1. `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` (**créé**) — gate de détection à 3 états.
2. `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` (**créé**) — suite dédiée.
3. `plugin/dev-orchestrator/scripts/ensure-deps.sh` (**modifié**) — `detect_gsd()` cesse de skipper
   le legacy, nouveau chemin `--migrate-engine`, message de nettoyage corrigé.
4. `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (**modifié**) — mode `--verify`.
5. `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (**étendu**) — cas `--verify`.
6. `plugin/conductor/skills/vf-update/SKILL.md` (**modifié**) — diagnostic à deux volets, ligne
   moteur dans la confirmation, §Garde-fous réécrit.
7. Release-meta des **deux** modules touchés (`dev-orchestrator`, `conductor`) : `VERSION`,
   `module.json`, `CHANGELOG.md`, `README.md`.
8. `docs/ADR.md` — **nouvel ADR** actant que le moteur GSD entre dans le périmètre de `/vf-update`.

**Ne produit PAS** (hors périmètre explicite, arbitré avec Samuel) :

- **Aucun hook `SessionStart` supplémentaire** sur l'état du moteur — décision de l'utilisateur.
  Le signal passe par `/vf-update`, pas par une ligne de plus au démarrage de chaque session.
- **Aucune modification du plafond `@^1`** (arbitrage post-audit Phase 11, explicitement
  non-négociable dans le rapport).
- **Aucune suppression du repli legacy** de `detect-gsd-engine.sh` / `build-gsd-index.sh` : la
  cascade à 4 niveaux continue de servir les postes non migrés. C'est le **skip** qu'on corrige,
  pas le repli.
- **Aucun bump de la `VERSION` racine, aucun tag, aucune release GitHub** dans le plan — reste-à-
  faire post-exécution réservé à validation humaine (même patron que Phases 13 et 17).
- **Aucune sauvegarde `tar` automatique** avant migration (option explicitement écartée, D-06).
- **Aucune exécution de `rm -rf`** ni de `npm uninstall` par VibeFlow (D-08, ADR-031).
</domain>

<decisions>
## Implementation Decisions

### Le fait structurant qui commande tout le reste (D-00)

- **D-00 [informational, vérifié] :** `plugin/dev-orchestrator/module.json` déclare
  `requires: ["conductor", "design-orchestrator"]` ; `plugin/conductor/module.json` déclare
  `requires: ["planning-core", "validator", "skill-creator"]` et est le **seul module
  `mandatory: true`**. Donc **`dev-orchestrator` dépend de `conductor`, jamais l'inverse** — or
  `ensure-deps.sh` vit dans `dev-orchestrator` tandis que `/vf-update` est un skill de `conductor`.
  Un lab non-dev (content, growth, business) installe conductor **sans** dev-orchestrator : il n'a
  ni moteur GSD, ni `ensure-deps.sh`. Toute la conception ci-dessous découle de cette contrainte :
  la détection traverse la dépendance **par sonde de présence de fichier**, jamais par une
  dépendance déclarée. Fait facilitant : à l'install, l'engine matérialise les scripts de **tous**
  les modules à plat dans le même `.claude/scripts/` — le rapport le confirme en citant
  `~/.claude/scripts/ensure-deps.sh`. La sonde est donc un simple test d'existence dans `<S>`.

### Détecteur de moteur — `check-gsd-engine.sh` (D-01 → D-05)

- **D-01 :** Le détecteur est un **script dédié** `plugin/dev-orchestrator/scripts/check-gsd-engine.sh`,
  pas une fonction élargie d'`ensure-deps.sh`. Motif : `ensure-deps.sh` (324 lignes) est un script à
  effets de bord ; un gate séparé est testable en boîte noire comme `check-doc-drift.sh` et
  `check-dev-bootstrap.sh`. — **Reversibility:** reversible — un script neuf, aucun appelant
  existant à défaire.
- **D-02 (contrat de sortie, convention F13 du repo) :** exits normalisés
  `0` = **legacy détecté, migration à proposer** (le cas actionnable) · `1` non utilisé ·
  `2` erreur d'usage · **`3` = INDÉTERMINÉ / rien à signaler** (moteur absent, ou déjà `gsd-core`).
  Le planner **doit** asserter séparément (a) le code de sortie, (b) le contenu exact de stdout,
  (c) stderr — piège D-14 de la Phase 17, où l'état 3 imprime une ligne **et** sort en 3.
- **D-03 (les 3 états, décidés sur le layout — JAMAIS sur les numéros) :** la fonction rend
  `absent` / `legacy` / `gsd-core`, en réutilisant **la cascade de dérivation existante** de
  `ensure-deps.sh:60-72` (`default_gsd_home_new()` — projet-local `<root>/.claude/gsd-core` d'abord,
  puis `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core`), jamais un `$HOME` figé : un chemin figé
  raterait le scope `--local` de gsd-core 1.8.0. La détection reste **par fichier `VERSION`
  uniquement**, jamais par `command -v` — piège n°1 déjà neutralisé et documenté en
  `ensure-deps.sh:116-118` (un shim legacy sur le PATH ferait toujours renvoyer vrai).
- **D-04 (cas dual — les deux layouts présents) :** état = **`gsd-core`** (exit 3, pas de
  proposition de migration), **plus** un signal distinct de reliquat legacy à nettoyer. Motif : la
  migration a eu lieu ; reproposer une install serait un no-op bruyant. Le nettoyage relève de D-08.
- **D-05 (le piège semver, à écrire noir sur blanc dans l'en-tête du script) :** `get-shit-done-cc`
  est figé à **1.42.3** (déprécié sur npm) et `@opengsd/gsd-core` vit à **1.8.0** — donc
  **1.8.0 < 1.42.3 en semver**. Aucune comparaison de numéros n'entre dans le classement : ni
  `sort -V`, ni test d'infériorité, ni réutilisation du comparateur du plugin. **Nuance vérifiée,
  contre le rapport** : `check-plugin-update.sh` ne compare que les **tags GitHub du plugin
  VibeFlow** (`:66-73`) — aucun comparateur n'est en défaut aujourd'hui, le piège concerne
  uniquement le code neuf de cette phase. Un cas de test dédié fixe le couple exact
  `1.42.3 → 1.8.0 ⇒ à migrer`. — **Reversibility:** one-way — une fois le classement câblé sur les
  numéros et publié, un poste legacy est classé « à jour » à perpétuité et le trou se rouvre sans
  aucun signal ; c'est exactement le défaut que la phase corrige.

### Correction de l'early-return (D-06)

- **D-06 :** `ensure-deps.sh:119-120` — le `||` de `detect_gsd()` (écrit pour la tolérance
  dual-layout, D-01/D3 Phase 10) est remplacé par un état à trois valeurs, et le `skip` de `:133`
  ne s'applique **plus** au cas `legacy`. La migration s'exécute via un **nouveau chemin
  `--migrate-engine`** : `ensure-deps.sh` reste le point de vérité unique (il dérive déjà
  `GSD_SCOPE_FLAG` `--global`/`--local` depuis `VF_SCOPE`, `:98-102`), et **enchaîne dans le même
  run** sur `patch_gsd_executor_mcp` (`:248`) — la ré-injection MCP ne peut donc pas être oubliée
  (D-09). **Pas de sauvegarde `tar` préalable** : option présentée et écartée par Samuel — un
  fichier de plus à gérer et à nettoyer, alors que l'installeur amont met déjà de côté les patchs
  locaux dans `~/.claude/gsd-local-patches/`. Le plan ne doit pas la réintroduire.

### Branchement sur `/vf-update` (D-07)

- **D-07 (le point qui décide si la phase corrige quoi que ce soit) :** sur le poste audité, le
  plugin était **déjà à jour** (2.42.0) — or l'étape 1 du skill s'arrête net sur
  `update_available = false` (« annonce *VibeFlow est à jour* et **stop** »). La détection du
  moteur ne serait **jamais atteinte**. L'étape 1 devient donc un **diagnostic à deux volets** :
  version du plugin **ET** état du moteur, la détection moteur s'exécutant **avant** tout stop. Le
  message « VibeFlow est à jour (v2.42.0) » ne peut plus sortir seul quand le moteur est legacy —
  il devient « plugin à jour (v2.42.0), **moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` à
  migrer** », et le flux continue vers la confirmation.
  - **Sonde best-effort (conséquence directe de D-00) :** le skill cherche `check-gsd-engine.sh`
    dans le même `<S>` que ses autres scripts (`$HOME/.claude/scripts/` → `./.claude/scripts/` →
    `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`). **Absent → silence total**, aucun message, aucune
    dégradation : un lab content/growth ne doit rien voir. Même patron best-effort que
    `patch_gsd_executor_mcp` face à un injecteur absent (`ensure-deps.sh:251-254`).
  - **Confirmation ADR-031 :** la migration est **une ligne de plus** dans l'`AskUserQuestion`
    existante de l'étape 3, acceptable ou refusable indépendamment du plugin et des modules. Refus
    → aucun effet de bord, aucune insistance. **Aucune migration silencieuse** — non négociable.
  - **Flags existants (tranché par cohérence de nommage, pas de flag neuf — densité ADR-029) :**
    `--check` affiche l'état du moteur comme le reste du diagnostic et **ne demande rien** ;
    `--modules-only` **ne propose pas** la migration du moteur (son nom borne son périmètre aux
    modules). Aucun `--engine-only` n'est créé.
  - **§Garde-fous du SKILL.md :** la phrase « La chaîne d'outils interne (GSD/Superpowers) a sa
    propre mise à jour (`gsd-update`) — hors périmètre de ce skill » devient **fausse** et doit être
    réécrite. C'est un **changement de doctrine**, pas un correctif de configuration → ADR (D-10).
    Superpowers, lui, reste hors périmètre : la phase ne touche qu'au moteur GSD.
    — **Reversibility:** costly — le message et le contrat d'arrêt du skill sont ce que les
    utilisateurs lisent ; revenir en arrière après publication recréerait l'écart « exact et
    trompeur à la fois » que le rapport décrit.

### Vérification de la ré-injection MCP (D-09)

- **D-09 :** `inject-mcp-tools.sh` gagne un mode **`--verify`** : il relit le `tools:` final de la
  cible et le compare aux serveurs dérivés du `.mcp.json` du lab ; un serveur manquant est **dit
  fort** (sortie bruyante), jamais avalé. Le flag s'insère dans le `case` de parsing existant
  (`:53-62`, à côté de `--force` et `--dry-run`). Motif du choix contre un simple `grep` inline :
  la capacité devient réutilisable hors migration et **testable** dans
  `test-inject-mcp-tools.sh`, qui existe déjà. Le fait couvert : l'installeur amont `gsd-core`
  réécrit `agents/gsd-executor.md`, classe l'injection ADR-051 en « local patch » et **efface
  `mcp__XcodeBuildMCP__*`** — sur un lab dont le `CLAUDE.md` interdit `xcodebuild` en shell,
  l'exécutant ne peut alors plus builder du tout, ou le fait par le chemin interdit.
  `_internal/vibeflow-update.sh:268` ne couvre pas ce cas (il n'injecte que dans les agents flaggés
  `vf-mcp-consumer`, flag que `gsd-executor` ne porte pas — commentaire `ensure-deps.sh:268`).

### Nettoyage du legacy (D-08)

- **D-08 :** **Proposer, jamais exécuter** (ADR-031 strict). Le message reste un affichage, mais il
  devient **atteignable** (via le récapitulatif `/vf-update`, plus seulement via `/vf-init` et
  `/vf-calibrate`) et **exact**. Trois corrections mesurées sur le poste audité :
  1. `npm uninstall -g get-shit-done-cc` et `npm uninstall -g @gsd-build/sdk`
     (`ensure-deps.sh:187-188`) ne sont proposés **que si `npm ls -g` les confirme réellement
     installés** — sur le poste audité, **aucun des deux** ne l'était (install faite en `npx`), donc
     deux lignes sur trois étaient des no-op.
  2. Le retrait de l'**arborescence vide** est inclus : l'installeur amont vide les 200+ fichiers
     mais **laisse les dossiers debout**.
  3. **Piège de séquencement à traiter** : après une install `gsd-core` réussie, l'installeur amont
     **supprime lui-même le `VERSION` legacy** → `detect_gsd_legacy()` (`:126-127`) devient faux
     immédiatement et le message **ne peut plus jamais sortir après coup**. L'état legacy doit donc
     être **capturé avant l'install** et le message rendu **à partir de cet état capturé**, pas
     d'une re-détection post-install.

### Tests (D-11)

- **D-11 :** **Suite dédiée** `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh`, sur
  le modèle de `test-check-doc-drift.sh` : `HOME` factice en `mktemp -d` + `trap … EXIT`, scripts
  appelés en **boîte noire** (subprocess réel), verdicts sur exit code **et** stdout. Cas
  obligatoires : les 3 états, le cas dual (D-04), le couple `1.42.3 → 1.8.0 ⇒ à migrer` (D-05), et
  le **scénario réel du rapport** — poste legacy déjà installé **+** plugin à jour ⇒ migration
  **détectée**. Ramassée automatiquement par la CI (`find plugin scripts -type f -path
  '*/tests/test-*.sh'`, `ci.yml:32`) — **aucune édition de `ci.yml`**.
  `_internal/tests/test-gsd-cohabitation.sh` **n'est pas étendu** : il porte le merger
  `settings.json` de l'engine (son en-tête ligne 2 le dit), pas un gate de `dev-orchestrator`.
  C'est précisément parce qu'il ne testait que le merger que le trou n'a pas été vu en v2.39.0.
- **Portabilité :** prouver sur **Linux avant push**, pas seulement macOS — conteneur local (Docker
  disponible sur cette machine) ou CI post-push. Idiomes portables imposés par ADR-054 :
  `set -uo pipefail` sans `-e`, pas de `mapfile`, pas de `sed -i` nu, pas de `grep -P`, `jqx()` pour
  tout appel jq. Rappel : 6 fixes de portabilité macOS→Linux ont été nécessaires le 2026-07-27.

### Release-meta (D-10)

- **D-10 :** **Deux modules** sont touchés — cas nouveau par rapport aux Phases 13/17 qui n'en
  bumpaient qu'un. `dev-orchestrator` (nouveau script + nouveau mode + nouveau chemin) →
  **mineur** ; `conductor` (le skill `vf-update` change de contrat) → **mineur** également, car
  c'est une capacité nouvelle du skill, pas un correctif. Le gate `scripts/check-version-sync.sh`
  vérifie la **triade par module** (`plugin/<mod>/VERSION` ↔ `module.json .version` ↔ en-tête
  Version du README) : les deux triades doivent rester cohérentes. **ADR à créer** dans
  `docs/ADR.md` : « le moteur GSD est une dépendance gouvernée par VibeFlow (`@^1` décidé en
  `ensure-deps.sh:166`), donc son état entre dans le périmètre de `/vf-update` — détecté et
  proposé, jamais installé sans accord ». Numéro libre à prendre à la suite des ADR existants.

### Claude's Discretion

- Découpage exact en 1, 2 ou 3 fichiers `19-NN-PLAN.md` (suggestion non contraignante : un plan
  gate + tests, un plan branchement skill + ADR + release-meta).
- Nom exact du flag interne et forme des messages (sous contrainte : français, `[nom-script] ✗
  message` sur stderr, `✓`/`✗`).
- Image Docker concrète pour la preuve Linux.
- Numéro d'ADR à attribuer.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit source (fait foi sur les constats)
- `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md` — les 5 trous, le déroulé de
  migration manuelle reproductible (annexe, ~4 min) et le tableau de résultats mesurés.
- `.planning/ROADMAP.md` §Phase 19 — 7 critères de succès, hors-périmètre, doctrine à réviser.

### Code à modifier
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` (324 lignes) — `:60-72` cascade de dérivation
  du layout · `:98-102` dérivation `GSD_SCOPE_FLAG` · `:116-121` `detect_gsd()` + piège `command -v`
  · `:126-128` `detect_gsd_legacy()` · `:130-178` `ensure_gsd()` et son skip · `:166` plafond `@^1`
  (intouchable) · `:184-191` `log_legacy_cleanup_if_needed()` · `:248+` `patch_gsd_executor_mcp()`.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (216 lignes) — en-tête ADR-051, `:53-62`
  parsing des options (point d'insertion de `--verify`), `:165-168` garde `--force`.
- `plugin/conductor/skills/vf-update/SKILL.md` — étape 1 (le stop de D-07), étape 3 (confirmation
  ADR-031), étape 4b, §Garde-fous (phrase à réécrire).
- `plugin/conductor/scripts/check-plugin-update.sh` — `:66-73` : ne compare que des tags GitHub du
  plugin ; **à ne pas confondre** avec une comparaison de moteur (D-05).
- `plugin/conductor/scripts/vf-update-run.sh` — couche modules, `sort -V` sur le cache plugin.
- `plugin/_internal/vibeflow-update.sh` — `:247-270` injection MCP limitée aux agents flaggés
  `vf-mcp-consumer` (l'autre moitié du trou 5).

### Modèles à copier (ne rien inventer)
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — gabarit exact du gate advisory
  (flags `--path/--hook/--quiet`, contrat d'exits, silence hors dépôt git).
- `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` — gabarit de suite
  (`HOME`/`mktemp` factice, `ok()`/`ko()`, cas numérotés).
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` — à étendre pour `--verify`.
- `.planning/phases/VFDO-17-signaux-de-d-marrage-du-moteur-de-dev/17-CONTEXT.md` — D-13 (preuve
  Linux) et D-14 (asserter sortie ET exit séparément) s'appliquent **tels quels** ici.

### Doctrine et gates
- `docs/ADR.md` — ADR-029 (densité), **ADR-031 (jamais d'action sans validation humaine)**,
  ADR-044 (agents natifs), ADR-051 (injection MCP), ADR-054 (portabilité bash).
- `.planning/codebase/CONVENTIONS.md` — portabilité bash, codes de sortie F13, discipline de
  release, structure d'un module.
- `.planning/codebase/TESTING.md` — pattern canonique de suite, isolation `mktemp`, découverte CI.
- `CLAUDE.md` racine — discipline de release (toute VERSION = un tag), numérotation minor/patch.
- `plugin/conductor/AGENT.md:114` — Iron Law 2 « Router, jamais réimplémenter » : la phase pilote
  l'installeur amont, elle ne réimplémente jamais sa logique d'install.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `default_gsd_home_new()` (`ensure-deps.sh:60-69`) — la cascade de dérivation du layout existe
  déjà et gère le scope `--local` de gsd-core 1.8.0. **Le nouveau gate la réutilise**, il ne la
  réécrit pas.
- `patch_gsd_executor_mcp()` (`ensure-deps.sh:248+`) — déjà idempotent, `--force`, best-effort et
  re-jouable ; il a effectivement restauré la ligne MCP lors de la migration manuelle du 28/07.
  Il ne manque que son **enchaînement** automatique et sa **vérification**.
- Résolution de scripts `<S>` en cascade (`$HOME/.claude/scripts/` → `./.claude/scripts/` →
  `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`), déjà écrite en tête de `vf-update/SKILL.md` — la
  sonde de D-07 s'y branche sans nouvelle mécanique.
- Harnais de test maison (`ok()`/`ko()`, `mktemp -d` + `trap … EXIT`, cas `# === Cas N ===`).

### Established Patterns
- **Contrat F13** : cible absente/vide ⇒ exit **3 INDÉTERMINÉ**, jamais un vert par absence de
  cible. Le gate neuf s'y conforme (D-02).
- **Best-effort sans dégradation** : un outil absent ne casse jamais le flux, il le rend silencieux
  (`ensure-deps.sh:251-254`, `:263-266`). C'est le patron de la sonde cross-module (D-00, D-07).
- **FAIT vs JUGEMENT** (ADR-055 §3) : le script **constate** l'état du moteur, l'agent **juge** et
  propose. Le gate ne doit jamais lancer d'install lui-même.
- Français partout : docs, commentaires, messages d'erreur, commits `type(scope): résumé`.

### Integration Points
- **Le point de couture délicat** : `vf-update` (conductor, mandatory) appelle un script de
  `dev-orchestrator` (non mandatory). Sonde de présence uniquement, jamais de `requires` ajouté au
  `module.json` de conductor — inverser la dépendance casserait la baseline d'un lab non-dev
  (`plugin/_internal/resolve-deps.sh` calcule la fermeture transitive depuis `mandatory: true`).
- L'installeur amont `@opengsd/gsd-core` est un **tiers** : la phase l'invoque (`npx -y
  "@opengsd/gsd-core@^1" --claude <scope>`), ne le patche pas, et absorbe ses deux avertissements
  connus et bénins (« Skipping statusline (already configured) », détection de « local patch »).
- Migration mesurée sans casse sur le poste audité : 67→**71** skills, 33→**34** agents, 6 hooks
  ajoutés, **0 hook VibeFlow supprimé**, dépôt du projet inchangé.
</code_context>

<specifics>
## Specific Ideas

- **Le déroulé manuel du 28/07 est la référence d'automatisation** (annexe du rapport, ~4 minutes,
  reproductible) : install `npx -y "@opengsd/gsd-core@^1" --claude --global` → `VF_SCOPE=user bash
  ~/.claude/scripts/ensure-deps.sh` (ré-affirme l'injection MCP) → `rm -rf ~/.claude/get-shit-done`.
  Les étapes 1 et 2 sont ce que `--migrate-engine` doit enchaîner ; l'étape 3 reste **proposée**
  (D-08).
- **Formulation attendue de la ligne moteur**, telle que Samuel l'a écrite dans le rapport :
  « moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` 1.8.0 » — un état, deux noms de paquets, et une
  action acceptable ou refusable.
</specifics>

<deferred>
## Deferred Ideas

- **Hook `SessionStart` sur l'état du moteur** — proposé en option, **écarté** par Samuel : le
  signal passe par `/vf-update`. Peut être rouvert si des postes restent legacy malgré la phase.
- **Sauvegarde `tar` avant migration** — proposée, écartée (D-06). Rouvrable si une migration
  automatique casse un poste en production.
- **Le hook `gsd-check-update` du moteur legacy** — le rapport soupçonne qu'il interrogeait
  `get-shit-done-cc` (paquet déprécié et figé) et annonçait donc « à jour » à perpétuité, sans
  pouvoir le prouver (le hook legacy a été écrasé par la migration). C'est du **code amont**, hors
  périmètre VibeFlow — à remonter en RFC/issue `open-gsd/gsd-core` si le comportement se confirme
  sur un autre poste legacy.
- **Passe transverse « qui appelle ce script en régime nominal ? »** — l'annexe du rapport la
  suggère : pour chaque script de `scripts/`, ceux dont la réponse est « personne, sauf `/vf-init` »
  sont des garde-fous décoratifs. Motif déjà rencontré deux fois (`ensure-deps.sh` ici,
  `check-agents.sh --hook` dans le second rapport). **Sa propre phase**, pas celle-ci.
- **Le second rapport d'audit** (`.planning/missions/2026-07-28-audit-externe-fluidite.md`) —
  4 changements : révision d'ADR-051 pour donner XcodeBuildMCP au relecteur, gradation de la revue
  par risque plutôt que par taille, `MISSION-INVARIANTS.md`, option `--exclude` sur
  `check-agents.sh`. **Non instruit**, à arbitrer après cette phase. Le point 4 (scope des hooks
  `check-agents.sh --hook` / `check-debug-research.sh --hook` cherchant `.claude/agents` en relatif
  au cwd) est le même motif structurel que cette phase.
- **Reliquat constaté au passage, hors périmètre** : `gsd-tools` émet à chaque appel
  `warning: unknown config key(s) in .planning/config.json: gates, safety — these will be ignored`
  — deux clés héritées du moteur legacy que `gsd-core` 1.8.0 ne connaît plus. Bruit inoffensif,
  mais c'est une trace de migration à nettoyer un jour.
</deferred>

---

*Phase: 19-Migration du moteur GSD pilotée par /vf-update*
*Context gathered: 2026-07-28*
