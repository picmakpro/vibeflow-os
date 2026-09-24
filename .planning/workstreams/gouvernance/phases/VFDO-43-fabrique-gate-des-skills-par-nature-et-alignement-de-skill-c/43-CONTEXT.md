Apply response_language to all user-facing prose — narration between tool calls, status updates, progress notes, and findings included; preserve code, paths, and identifiers.

# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

> **Mode de cadrage.** Premier temps (2026-09-24) : six zones grises structurantes présentées à
> Willy en format AskUserQuestion, options neutres, par `vf-coder` faute d'outil de question — le
> manager a relayé. Second temps (2026-09-24) : réponses de Willy (AskUserQuestion, session
> principale, 2026-09-24) rapportées par `vf-dev-manager`, plus quatre détails secondaires que
> Willy a explicitement délégués (même canal, même date), tranchés ici et marqués comme tels.
> **Q3 (unification MCP) reste ouverte** : Willy a demandé une comparaison argumentée avant de
> trancher ; un panel de recherche tourne. Elle est consignée en question ouverte, pas en décision —
> rien dans ce document ne la tranche implicitement.

<domain>
## Phase Boundary

Chaque skill déclare sa nature (`vf-nature: referentiel | outil | procedure`, défaut « outil ») ;
une procédure sans `ecrit:` ni rubrique de juge est refusée ; la dérive de forme procédurale non
déclarée est détectée (en avertissement pour cette phase — D-Q5) ; `skill-creator` demande la
nature, dans son moteur interne ET son workflow templaté (D-Q6) ; le budget des `SKILL.md` **et**
du bootstrap gagne un enforcement machine (D-Q4). **La fusion des deux conventions MCP
(`vf-mcp-consumer` / `vf-mcp-tools`) reste une question ouverte (Q3, non tranchée) — voir
`<open_questions>`.**

**Dans le périmètre** : fabrique §6 (gate des skills, `vf-nature`, détection de dérive), §7.2
(unification MCP — **suspendu à Q3**), B-03 ; `.planning/BACKLOG.md:450` (budget SKILL.md et
bootstrap) ; initialisation §C-15/§5.2 (les trois marqueurs de B-03, question factuelle, pas de
redéfinition de la nature).

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
  des deux without l'autre romprait la cohérence outil↔déclaration.

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
  dépôt (voir D-Q7bis) — l'avertissement est le choix assumé de Willy pour ce premier tour, pas une
  dérogation silencieuse à la doctrine.
  — **Reversibility:** reversible — passer de l'avertissement au refus est un changement de sévérité
  local dans le gate, pas une migration de format.

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

</decisions>

<open_questions>
## Question ouverte — non tranchée

### Q3 : unification des deux conventions MCP (§7.2 de la spec fabrique)
§7.2 de `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` demande que « les deux
conventions concurrentes fusionnent en une seule ». Le code réel porte deux champs :
`vf-mcp-consumer: true` (allowlist large dérivée du lab à l'install, agents exécutants —
`vf-coder`, `vf-test-runner`, `vf-app-fixer`, `vf-test-orchestrator`) et `vf-mcp-tools: <serveur>:<outils>`
(allowlist nommée étroite, `vf-reviewer` seul). `plugin/conductor/scripts/check-agents.sh:171-173`
documente explicitement leur coexistence comme voulue : « coexiste avec vf-mcp-consumer sans le
remplacer ». `docs/ADR.md` ADR-051 pose ce couple comme un choix délibéré de moindre privilège
différencié par rôle (l'exécutant produit un verdict de compilation, moindre privilège = large mais
dérivé ; le relecteur vérifie un verdict, moindre privilège = étroit et nommé).

**Willy a demandé une comparaison argumentée plutôt qu'un tranchage direct** (AskUserQuestion,
session principale, 2026-09-24) ; un panel de recherche est en cours au moment de ce cadrage.

Options neutres présentées (aucune consommée, aucune écartée) :
- **Oui, fusionner ces deux-là** — un seul mécanisme remplace les deux champs, quitte à revoir le
  moindre privilège différencié d'ADR-051.
- **Non, autre chevauchement visé** — `vf-mcp-consumer`/`vf-mcp-tools` restent tels quels (design
  ADR-051 intact) ; la fusion visée par §7.2 est ailleurs, p. ex. le champ officiel `mcpServers:`
  natif vs le mécanisme maison — déjà tranché en faveur du maison dans la même section.
- **Fusionner la mécanique, garder les rôles** — un seul script/format d'injection sous-jacent, mais
  deux façons de le déclarer (large vs nommé) subsistent en frontmatter.

**Ce qui en dépend, suspendu à Q3** : le volet MCP du goal de phase (« les deux conventions MCP
concurrentes n'en font plus qu'une ») ; toute tâche du futur plan qui toucherait
`check-agents.sh:171-173`, `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` ou le frontmatter
`vf-mcp-consumer`/`vf-mcp-tools` des cinq agents cités. `gsd-plan-phase` ne doit pas planifier ce
volet avant que Q3 soit tranchée — les cinq autres décisions (D-Q1, D-Q2, D-Q4, D-Q5, D-Q6) sont
indépendantes et peuvent être planifiées sans attendre.

</open_questions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Specs du chantier
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §6 (gate des skills,
  `vf-nature`, détection de dérive), §7.2 (unification MCP — **Q3 ouverte**), B-03.
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
  `--hook`) que `check-skills.sh` reprend ; lignes 171-173 pour la coexistence MCP (Q3).
- `plugin/conductor/scripts/check-instruction-budget.sh` — socle à étendre pour D-Q4 (lignes 14-15 :
  glob à un seul niveau, ne couvre pas `SKILL.md`, motif propre aux agents non transposable).

### skill-creator
- `plugin/skill-creator/skills/skill-creator/SKILL.md` — moteur interne, non templaté (D-Q6).
- `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md:52` — étape « nature du sujet »
  existante, distincte de `vf-nature` (D-Q2).

### Doctrine du dépôt
- `CLAUDE.md` — ADR-029 (densité, SKILL.md ≤ 500 lignes, bootstrap ≤ 2000 tokens), ADR-044 (agents
  natifs machine-enforced), G-2 (trailer `Gate-Touche:` si ce gate ou sa suite sont touchés).
- `docs/ADR.md` ADR-051 — allowlist MCP dérivée du lab, le design du couple mis en question par Q3.

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

- Mise en conformité du corpus de skills détecté en dérive (D-Q5) : backlog séparé, à poser par
  `vf-dev-manager` (hors périmètre de ce mandat de cadrage).
- Unification `vf-mcp-consumer` / `vf-mcp-tools` : **question ouverte Q3**, pas un différé — un
  panel de recherche est en cours, le tranchage reviendra dans une itération ultérieure du cadrage,
  pas dans une phase distincte.

</deferred>

---

*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator*
*Context gathered: 2026-09-24*
