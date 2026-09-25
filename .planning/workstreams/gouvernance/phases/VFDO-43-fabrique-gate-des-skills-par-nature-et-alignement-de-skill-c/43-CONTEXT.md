Apply response_language to all user-facing prose — narration between tool calls, status updates, progress notes, and findings included; preserve code, paths, and identifiers.

# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

> **Mode de cadrage.** Premier temps (2026-09-24) : six zones grises structurantes présentées à
> Willy en format AskUserQuestion, options neutres, par `vf-coder` faute d'outil de question — le
> manager a relayé. Second temps (2026-09-24) : réponses de Willy (AskUserQuestion, session
> principale, 2026-09-24) rapportées par `vf-dev-manager`, plus quatre détails secondaires que
> Willy a explicitement délégués (même canal, même date), tranchés ici et marqués comme tels. Q3
> (unification MCP) restait ouverte à ce stade — un panel de recherche tournait.
> **Troisième temps (2026-09-24) : Q3 est tranchée.** Willy a répondu au panel (AskUserQuestion,
> session principale, 2026-09-24) : les deux déclarations (`vf-mcp-consumer` / `vf-mcp-tools`) sont
> conservées, aucune migration. Voir D-Q3. Plus aucune zone grise structurante n'est ouverte dans ce
> document.

<domain>
## Phase Boundary

Chaque skill déclare sa nature (`vf-nature: referentiel | outil | procedure`, défaut « outil ») ;
une procédure sans `ecrit:` ni rubrique de juge est refusée ; la dérive de forme procédurale non
déclarée est détectée (en avertissement pour cette phase — D-Q5) ; `skill-creator` demande la
nature, dans son moteur interne ET son workflow templaté (D-Q6) ; le budget des `SKILL.md` **et**
du bootstrap gagne un enforcement machine (D-Q4). **Les deux conventions MCP
(`vf-mcp-consumer` / `vf-mcp-tools`) sont conservées telles quelles — pas de fusion** ; la spec
fabrique est amendée pour corriger trois erreurs factuelles et acter la décision 1 d'ADR-051, et
trois durcissements ciblés sont posés côté gate et injecteur (D-Q3).

**Dans le périmètre** : fabrique §6 (gate des skills, `vf-nature`, détection de dérive), §7.2 et
§1.2 (amendement — D-Q3), B-03 ; `.planning/BACKLOG.md:450` (budget SKILL.md et bootstrap) ;
initialisation §C-15/§5.2 (les trois marqueurs de B-03, question factuelle, pas de redéfinition de
la nature).

**Hors périmètre** : §7.1 (blueprints, déjà livré ailleurs) ; §7.3 (nomenclature des prompts, pas
un gate) ; le hook central par rôle (Phase 45) ; la mise en conformité du corpus détecté par la
dérive (backlog séparé, D-Q5 — voir `entree_backlog_a_poser` du rapport de mission).

</domain>

<decisions>
## Implementation Decisions

### Détection de la dérive procédurale (Q1)
- **D-Q1 : détection en écart, jamais en tranchage unilatéral.** Le skill déclare en frontmatter
  s'il porte les marqueurs (gate bloquant / livrable remis à un tiers / couche de qualité) — champs
  factuels optionnels — **et** le gate cherche indépendamment des motifs connus dans la prose du
  corps. Le gate signale l'**écart** entre déclaration et contenu constaté ; il ne décide jamais
  seul qu'un skill est une procédure. Réponse de Willy (AskUserQuestion, session principale,
  2026-09-24) : « Les deux, en écart ».
  — **Reversibility:** costly — le format du frontmatter et le vocabulaire de motifs sont lus par le
  gate et par `skill-creator` (qui doit poser les mêmes questions factuelles, C-15) ; changer l'un
  des deux sans l'autre romprait la cohérence outil↔déclaration.

### Collision de nom `vf-nature` / « nature du sujet » (Q2)
- **D-Q2 : deux questions distinctes, sans fusion.** `vf-nature` (referentiel/outil/procedure, B-03)
  et l'étape existante « Evaluer la nature du sujet » (méthodologique/agnostique/zone grise,
  `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md:52`) coexistent sous des noms
  différents dans le workflow de `skill-creator`, sans redéfinition ni fusion conceptuelle de
  l'une par l'autre. Réponse de Willy (AskUserQuestion, session principale, 2026-09-24) : « Deux
  questions distinctes ».
  — **Reversibility:** reversible — c'est une question de plus dans un workflow existant, pas un
  changement de contrat de sortie.

### Budget des SKILL.md et du bootstrap (Q4)
- **D-Q4 : les deux budgets sont couverts, la réserve du BACKLOG est levée.** La phase étend
  `check-instruction-budget.sh` (socle repris, pas de réécriture — `.planning/BACKLOG.md:461-462`)
  au corpus `SKILL.md`, **et** couvre aussi le budget du bootstrap (2000 tokens, ADR-029). La
  réserve posée par `.planning/BACKLOG.md:464-466` (« Écarté, et non différé : la métrique en tokens
  estimés pour le budget du bootstrap... à ne rouvrir que sur un incident lié à la taille ») est
  **levée par cette réponse** — Willy, AskUserQuestion, session principale, 2026-09-24, réponse
  « SKILL.md + bootstrap ».
  — **Reversibility:** one-way — la réserve écrite au BACKLOG le 2026-09-15 (« à ne rouvrir que sur
  incident ») est explicitement contredite ici sur décision de Willy ; un retour en arrière devrait
  rouvrir cette même réserve, pas simplement dépriorer une tâche.

### Corpus détecté par la dérive (Q5)
- **D-Q5 : avertissement dans cette phase, mise en conformité en backlog séparé.** Le gate signale
  les skills à forme procédurale non déclarée sans les bloquer ; la correction du corpus part dans
  une entrée de backlog distincte (nommée par `vf-coder`, posée par `vf-dev-manager` — hors
  périmètre de ce mandat). Réponse de Willy (AskUserQuestion, session principale, 2026-09-24) :
  « Avertissement dans cette phase ».
  **Écart assumé par rapport au précédent de la Phase 42 (D-11 : « pas de période d'avertissement,
  corpus corrigé dans cette phase, la CI passe déjà `--strict` »).** Ce n'est pas une incohérence :
  Phase 42 armait un invariant déjà mesuré et borné (corpus nommé skill par skill, I3/I5/I6, D-11) sur un gate
  existant renforcé ; Phase 43 pose un **nouveau** gate sur un corpus non encore mesuré dans ce
  dépôt (mesure du corpus, Claude's Discretion ci-dessous) — l'avertissement est le choix assumé de
  Willy pour ce premier tour, pas une dérogation silencieuse à la doctrine.
  — **Reversibility:** reversible — passer de l'avertissement au refus est un changement de sévérité
  local dans le gate, pas une migration de format.

### Unification MCP — tranchée (Q3)
- **D-Q3 : les deux déclarations `vf-mcp-consumer` / `vf-mcp-tools` sont conservées, aucune
  migration.** L'option « une clé, deux formes de valeur » (fusion mécanique en gardant les rôles)
  est écartée. Réponse de Willy (AskUserQuestion, session principale, 2026-09-24), après un panel
  de recherche : « garder les deux déclarations ».
  **La spec est amendée**, pas le code : `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`
  §1.2 et §7.2 prennent acte que `vf-mcp-consumer` (produire un verdict de compilation, moindre
  privilège large et dérivé) et `vf-mcp-tools` (vérifier un verdict, moindre privilège étroit et
  nommé) répondent à deux besoins distincts — décision 1 d'ADR-051, pas « un même besoin ». Trois
  erreurs factuelles de §1.2 sont corrigées dans le même geste :
  - `vf-mcp-consumer: true` porte sur **4** agents, pas 3 : `vf-coder`, `vf-test-runner`,
    `vf-test-orchestrator`, `vf-app-fixer` (mesuré : `grep -rl "vf-mcp-consumer: true" plugin/*/agents/*.md`) ;
  - `vf-reviewer` **est** un consommateur Xcode (`plugin/dev-orchestrator/agents/vf-reviewer.md:10` —
    `vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean`), pas un cas générique isolé ;
  - la formule « deux conventions concurrentes pour un même besoin » contredit la décision 1
    d'ADR-051 elle-même et doit être reformulée en « deux besoins distincts, deux déclarations ».
  **Trois durcissements sont posés dans cette phase**, sur le mécanisme conservé :
  - (a) `check-skills.sh` (et/ou `check-agents.sh`, à trancher au plan) valide la **grammaire** de
    `vf-mcp-tools` — aujourd'hui une valeur malformée passe le gate silencieusement et ne produit
    rien à l'install (`plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:549-551`, no-op sur
    grammaire malformée, couvert par le cas T22 de `test-inject-mcp-tools.sh`) ;
  - (b) l'injecteur **signale** un serveur nommé absent au lieu d'un no-op muet
    (`inject-mcp-tools.sh:554`, cas T16 de la même suite) — motif réel mesuré : `getsentry/XcodeBuildMCP`
    redirige désormais vers `MobileBuildMCP`, un nom couramment obsolète dans les `.mcp.json` de labs ;
  - (c) les textes qui ne nomment que `vf-mcp-consumer` sans mentionner `vf-mcp-tools` sont corrigés :
    `plugin/_internal/vibeflow-update.sh:1276,1308,2413`, `plugin/conductor/skills/vf-calibrate/SKILL.md:92`.
  **Hors périmètre de cette phase** : l'union des scopes projet et global du mode large
  (`vf-mcp-consumer` chez `vf-app-fixer` ne résout que `./.mcp.json` projet, pas `~/.claude.json`
  global — contrairement à `vf-calibrate` qui union les deux depuis Phase 21, ADR-051-B, absent de
  la spec fabrique). Finding pour Samuel, consigné au BACKLOG par `vf-dev-manager` (commit
  `f4cc09b`), sans correctif dans cette phase.
  **Erratum (vf-dev-manager, 2026-09-25) — le paragraphe ci-dessus inverse le fait.** Le mode large
  UNIT déjà les deux scopes : `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` l.26-31 et
  l.222 (« UNION scope projet + scope global, ADR-051-B »), prouvé par le dry-run consigné au
  `.planning/BACKLOG.md` (commit `f4cc09b` : `vf-app-fixer` recevrait `mcp__context7__*`,
  `mcp__xpoz-mcp__*` depuis `~/.claude.json`). Le finding pour Samuel porte sur cette union, pas
  sur son absence. Conséquence pour le plan : le durcissement (b) « serveur nommé absent » se
  juge contre l'**union** des deux scopes, jamais contre le seul `./.mcp.json`. Décision D-Q3
  inchangée ; hors périmètre inchangé.
  — **Reversibility:** reversible — aucun changement de contrat de frontmatter existant ; les
  durcissements (a)(b) ajoutent des diagnostics sur des chemins aujourd'hui silencieux, (c) est
  une correction de prose.

### `skill-creator` — quel(s) fichier(s) s'alignent (Q6)
- **D-Q6 : les deux fichiers demandent la nature, même défaut « outil ».** `plugin/skill-creator/skills/skill-creator/SKILL.md`
  (moteur interne non templaté, utilisé par ce dépôt pour ses propres skills) **et**
  `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (workflow templaté propagé aux
  labs installés, marqueurs `[NOM_LAB]`) posent chacun la question `vf-nature` à son étage propre,
  avec la même valeur par défaut « outil ». Réponse de Willy (AskUserQuestion, session principale,
  2026-09-24) : « Les deux ».
  — **Reversibility:** reversible.

### Claude's Discretion
Quatre détails délégués par Willy (AskUserQuestion, session principale, 2026-09-24) — tranchés par
Claude, 2026-09-24 :
- **Manifeste** : le nouveau gate des skills lit le **même** manifeste daté que la Phase 42 (une
  seule vérité, D-01 de `42-CONTEXT.md`), étendu avec les listes propres aux skills (champs de
  frontmatter connus : `vf-nature`, `ecrit:`, rubrique de juge), plutôt qu'un second fichier.
- **Découverte** : réutilise la machinerie récursive posée en Phase 42 (D-10 de `42-CONTEXT.md`),
  scopée à `plugin/*/skills/**/SKILL.md` — les skills vivent à deux niveaux de profondeur, le glob à
  un seul niveau de `check-instruction-budget.sh` (D-03 de ce script, motif propre aux agents) ne
  s'y transpose pas.
- **Script** : `plugin/conductor/scripts/check-skills.sh`, miroir de `check-agents.sh` — aucun
  script de ce nom n'existe aujourd'hui (`ls plugin/conductor/scripts/` ne remonte aucun
  `check-skill*`). Contrat de sortie 0/1/3 identique à `check-agents.sh` (silence de code sous
  `--hook`, jamais silence de message, F13) : l'avertissement de dérive (D-Q5) s'exprime en exit 0
  avec diagnostic imprimé — même patron que la rétrogradation D-05 de `42-CONTEXT.md` (manifeste
  périmé → avertissement, jamais un régime d'exit code séparé).
- **Mesure du corpus** : le nombre réel de skills à forme procédurale non déclarée dans ce dépôt (25
  `SKILL.md` sous `plugin/`, `find plugin -name SKILL.md | wc -l`) se mesure avant l'écriture des
  cas de test — le chiffre 9/142 conformes et 32/142 en dérive de la spec fabrique §6 vient d'un
  autre corpus que ce dépôt de distribution.

### Exigences proposées (à graver au ledger par le planificateur)
- **FABR-06** gate des skills — `vf-nature` (défaut « outil »), procédure sans `ecrit:` ni rubrique
  de juge refusée (D-Q1, D-Q2).
- **FABR-07** détection de dérive procédurale en écart déclaration/prose, avertissement (pas refus)
  cette phase, corpus non corrigé ici (D-Q1, D-Q5).
- **FABR-08** `skill-creator` (moteur interne ET workflow templaté) pose `vf-nature`, même défaut
  (D-Q6).
- **FABR-09** budget des `SKILL.md` et du bootstrap étendus via `check-instruction-budget.sh`
  (socle repris) (D-Q4).
- **FABR-10** amendement de la spec fabrique §1.2/§7.2 (deux besoins d'ADR-051, trois corrections
  factuelles) ; durcissements (a) grammaire `vf-mcp-tools` validée, (b) serveur nommé absent
  signalé, (c) textes à une seule clé corrigés (D-Q3).

</decisions>

<open_questions>
## Questions ouvertes

**Aucune.** Q3 (unification MCP), seule zone grise structurante restée ouverte au second temps de
ce cadrage, a été tranchée au troisième temps (2026-09-24) — voir D-Q3 dans `<decisions>` et
`43-DISCUSSION-LOG.md`. Plus rien n'est marqué « suspendu à Q3 » dans ce document : le volet MCP du
goal de phase est planifiable au même titre que les cinq autres décisions.

</open_questions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Specs du chantier
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §6 (gate des skills,
  `vf-nature`, détection de dérive), §1.2 et §7.2 (MCP — **à amender**, D-Q3, trois erreurs
  factuelles listées dans D-Q3), B-03.
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §2, §9 — D-07 du moteur,
  dont le gate des skills est le contrôle machine manquant.
- `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` C-15, §5.2 — les trois marqueurs
  de B-03 posés en questions factuelles par l'initialisation, sans redéfinir la nature.
- `.planning/BACKLOG.md:450-469` — budget des SKILL.md et du bootstrap, réserve levée par D-Q4.

### Le gate des agents (précédent direct, Phase 42)
- `.planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-CONTEXT.md` —
  D-01 (manifeste unique, une seule vérité), D-10 (découverte récursive testée), D-11 (invariants
  armés en erreur, corpus corrigé dans la même phase — écart assumé par D-Q5 de cette phase).
- `plugin/conductor/scripts/check-agents.sh` — contrat de sortie (0/1/3, F13, silence de code sous
  `--hook`) que `check-skills.sh` reprend ; lignes 171-173 pour la coexistence MCP voulue (D-Q3).
- `plugin/conductor/scripts/check-instruction-budget.sh` — socle à étendre pour D-Q4 (lignes 14-15 :
  glob à un seul niveau, ne couvre pas `SKILL.md`, motif propre aux agents non transposable).

### MCP — durcissements (D-Q3)
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:549-551` — no-op silencieux sur `vf-mcp-tools`
  malformée (durcissement a, cas T22 de `tests/test-inject-mcp-tools.sh`).
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:554` — no-op silencieux sur serveur nommé
  absent (durcissement b, cas T16 de la même suite).
- `plugin/_internal/vibeflow-update.sh:1276,1308,2413` et
  `plugin/conductor/skills/vf-calibrate/SKILL.md:92` — textes ne nommant que `vf-mcp-consumer`
  (durcissement c).
- `docs/ADR.md` ADR-051 §Décision point 1 — la distinction produire/vérifier que la spec doit
  désormais citer explicitement.

### skill-creator
- `plugin/skill-creator/skills/skill-creator/SKILL.md` — moteur interne, non templaté (D-Q6).
- `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md:52` — étape « nature du sujet »
  existante, distincte de `vf-nature` (D-Q2).

### Doctrine du dépôt
- `CLAUDE.md` — ADR-029 (densité, SKILL.md ≤ 500 lignes, bootstrap ≤ 2000 tokens), ADR-044 (agents
  natifs machine-enforced), G-2 (trailer `Gate-Touche:` si ce gate ou sa suite sont touchés).
- `docs/ADR.md` ADR-051 — allowlist MCP dérivée du lab, le design du couple confirmé par D-Q3
  (décision 1 : produire ≠ vérifier).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Le manifeste daté de Phase 42 et sa découverte récursive (D-01, D-10) : réutilisables tels quels
  pour le gate des skills (Claude's Discretion, ci-dessus).
- Le contrat de sortie 0/1/3 de `check-agents.sh` (F13) : vocabulaire déjà éprouvé pour un gate qui
  doit distinguer refus, avertissement et silence sous `--hook`.

### Established Patterns
- Chaque gate a sa suite `*/tests/test-*.sh`, découverte par le balayage CI, un jumeau négatif par
  règle, mutation prouvée par `cmp` — patron transposé du gate des agents.
- Rétrogradation en avertissement plutôt qu'un second régime d'exit code (D-05 de `42-CONTEXT.md`,
  repris par D-Q5 de cette phase).

### Integration Points
- 25 `SKILL.md` sous `plugin/` (mesuré 2026-09-24) — corpus réel du nouveau gate et de l'extension
  du budget, distinct du corpus de la spec (142 skills, autre dépôt).
- `plugin/skill-creator/skills/skill-creator/SKILL.md` et `skill-creator-workflow/SKILL.md` : deux
  points d'intégration distincts pour la question de nature (D-Q6), pas un seul.

</code_context>

<specifics>
## Specific Ideas

- Le gate signale l'écart entre déclaration et prose (D-Q1) plutôt que de choisir un des deux
  signaux comme source de vérité unique — c'est le point précis sur lequel Willy a tranché.

</specifics>

<deferred>
## Deferred Ideas

- Mise en conformité du corpus de skills détecté en dérive (D-Q5) : backlog séparé, posé par
  `vf-dev-manager` (`.planning/BACKLOG.md`, commit `e36e6f2`) — hors périmètre de ce mandat de
  cadrage.
- Union des scopes projet/global du mode large MCP (`vf-mcp-consumer` chez `vf-app-fixer` ne
  résout que `./.mcp.json`, contrairement à `vf-calibrate` qui union projet + global depuis
  ADR-051-B) : finding pour Samuel, sans correctif dans cette phase (D-Q3) — posé au BACKLOG par
  `vf-dev-manager`, commit `f4cc09b`. **Même erratum qu'en D-Q3 (2026-09-25)** : le mode large
  unit déjà projet et global ; le finding porte sur cette union.

</deferred>

---

*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator*
*Context gathered: 2026-09-24*
