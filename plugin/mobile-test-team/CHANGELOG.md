# Changelog — mobile-test-team

## v1.4.1 — 2026-07-26

### Modifié
- README monté au standard de doc : installation avec dépendance explicite (`mobile-test`
  installé d'abord, ou `--with-deps` — pas de résolution auto en install nu), premier run guidé,
  tableau des agents avec leur cloisonnement par `tools:` (Pattern 12), config `night-run.json`,
  limites avec condition de sortie du statut expérimental (run réel vert de bout en bout).

## v1.4.0 — 2026-07-25

### Ajouté
- ADR-045 en 1 saut : vf-test-orchestrator gagne WebSearch/WebFetch et porte lui-même la recherche documentaire (context7 + issues GitHub) — fin de l'escalade à 3 étages en pleine boucle de nuit. Le cloisonnement anti-triche (code/tests) est inchangé.

## v1.3.1 — 2026-07-25

### Corrigé
- Agents de la boucle en sonnet ; globs de `mobile-verify-gate.md` resserrés sur des marqueurs discriminants mobile (`app/**/_layout.tsx`, `src/screens/**`, `.maestro/**`) — la rule ne se charge plus sur les projets Next.js.

## v1.3.0 — 2026-07-22 (ADR-053 — rapport de worker typé)

### Ajouté
- `vf-test-orchestrator` termine désormais son rapport par le **bloc typé** du contrat de rapport de worker
  (ADR-053) : `{statut, findings[{action}], noeuds_debloques}` — mapping vert=`passed`, partiel=`gaps_found`,
  bloqué=`blocked`. Permet à `vf-dev-manager` un contrôle de flux déterministe sur la boucle de test mobile.

## v1.2.1 — 2026-07-20 (conformité ADR-045)

### Corrigé
- `agents/vf-test-runner.md` : renvoi explicite à la règle `doc-research-before-debug` (ADR-045)
  avant tout diagnostic empirique d'un échec suspect d'être un bug d'outillage (Maestro, Expo,
  simulateur, natif). La brique passait sous le filet resserré du linter (conductor v1.11.3),
  le renvoi la rend conforme par contenu, pas seulement par exclusion de signature — et c'est
  doctrinalement juste : une cause connue documentée se cherche avant de creuser à la main.

## v1.2.0 — 2026-07-19 (ADR-051)

### Ajouté
- **Allowlist MCP dérivée du lab** sur les 3 agents de la boucle : `vf-test-orchestrator`,
  `vf-test-runner`, `vf-app-fixer` portent `vf-mcp-consumer: true`. À l'install (hook
  `vibeflow-update.sh`) ou à `/vf-calibrate`, les serveurs MCP déclarés dans le `./.mcp.json` du lab
  (ex. `mobile-mcp` pour le diagnostic visuel) sont injectés dans leur `tools:` — ces workers voyaient
  jusqu'ici une allowlist fermée et étaient aveugles au MCP du projet. Mécanique dans dev-orchestrator
  v1.6.0 (`inject-mcp-tools.sh`), aucun serveur en dur.

### Inchangé (vérifié)
- **Cloisonnement anti-triche (Pattern 12)** intact : la séparation `Read/Write/Edit` entre
  `vf-test-runner` (tests) et `vf-app-fixer` (code) reste le garde-fou ; on n'injecte que des serveurs
  de build/test, pas d'accès web/doc — `vf-app-fixer` garde son interdiction ADR-045 (pas de context7).

### Note
- Le `tools:` étant lu au démarrage de session, **redémarrer Claude Code** après (ré)install.

## v1.1.0 — 2026-07-08 (ADR-045)

### Ajouté
- **Gate recherche documentaire dans la boucle test+fix** (ADR-045) :
  - `vf-test-orchestrator` : avant de (re)dispatcher `vf-app-fixer` sur un flow **déjà tenté**, ou
    dès réception d'un `doc-research-required`, ou sur un échec lib/framework/natif/version →
    suspend le fix aveugle, fait porter la recherche (context7 + issues GitHub) par le niveau qui a
    le web, puis redispatche avec des pistes. HALT léger analogue à HALT-4. Config
    `maxResearchRoundsPerFlow` (défaut 2).
  - `vf-app-fixer` : **3ᵉ état de remontée `doc-research-required`** — worker cloisonné sans web,
    il ne bricole plus un contournement à l'aveugle sur un bug documentable ; il remonte la question
    précise et s'arrête (miroir de « rien committé, explique »).
  - `references/test-loop-protocol.md` : ligne HALT-4 (léger) + invariant anti-thrash mis à jour.
  - `rules/mobile-verify-gate.md` : section « Recherche documentaire avant fix intensif », renvoi à
    la règle `doc-research-before-debug`.

## v1.0.1 — 2026-07-07

### Corrigé
- `vf-test-runner` et `vf-app-fixer` marqués **`vf-internal: true`** : ces workers ne reçoivent plus
  de commande d'incarnation `/vf-test-runner` / `/vf-app-fixer` lors du sweep `vf-new-lab`. Ils
  restent dispatchés uniquement par `vf-test-orchestrator` (cohérent avec l'allowlist `Agent(...)`
  et leur description). L'orchestrateur, lui, reste invocable en direct. Requiert conductor v1.7.0.

## v1.0.0 — 2026-07-07

Création du module (brique 5b + 5c). Équipe de test mobile autonome, extraite et généralisée
depuis le track « équipe d'agents », câblée sur la doctrine VibeFlow existante.

- **3 agents cloisonnés** (Pattern 12) : `vf-test-orchestrator` (boucle + garde-fous + halt),
  `vf-test-runner` (tests seuls, pas de `Task`), `vf-app-fixer` (code seul, pas de `Task`).
- **Rule path-scopée** `mobile-verify-gate.md` : invoque la doctrine de vérification réelle
  **automatiquement** dès qu'on touche du code mobile (extension mobile du Gate Nyquist, ADR-037).
  Répond au besoin « la doctrine doit être invoquée naturellement lors du dev ».
- **Référence** `test-loop-protocol.md` : protocole de boucle + mapping halt conditions, insertion
  dans le flux `god-execution`/`vf-auto`.

### Généralisation vs source d'origine

- Retrait des constantes projet (bundle id, i18n, THEME, dossiers `.agent/`/`docs/_mission/`).
- « jamais de push » et « pas de mention d'IA dans les commits » → **options de projet** lues dans
  le `CLAUDE.md`/rules du projet cible, plus des constantes.
- Préfixe `vf-`, descriptions FR, invocables utilisateur ET agent.

### Dépendance engine

Nécessite le support **multi-agents** de l'installeur (`agents/*.md` → `.claude/agents/<name>.md`),
ajouté à `_internal/vibeflow-update.sh` dans la même livraison.

### Modèle d'installation (validé via doc Claude Code officielle)

Conçu pour un **install global (scope user)** avec **activation par projet** : la rule est
path-scopée (évaluée sur le projet courant → dormante hors mobile), le script lit sa config par
projet, et l'orchestrateur décline si le projet n'est pas mobile. Documenté dans le README.

### Cloisonnement des workers (allowlist)

`vf-test-orchestrator` déclare `tools: …, Agent(vf-test-runner, vf-app-fixer)` : il ne peut spawner
**que** ces deux workers (Pattern 12, règle 5). **Limite connue** : Claude Code n'offre pas de champ
« agent interne seulement » — les workers restent techniquement auto-délégables ; la parade est
l'allowlist côté orchestrateur + leurs descriptions dissuasives. Heuristique robuste, pas barrière dure.

### Statut

Expérimental jusqu'au premier run réel vert (nesting de sous-agents à prouver en conditions réelles).
