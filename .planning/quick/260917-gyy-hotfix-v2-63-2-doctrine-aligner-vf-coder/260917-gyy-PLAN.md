---
phase: 260917-gyy
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugin/dev-orchestrator/agents/vf-coder.md
  - plugin/dev-orchestrator/agents/vf-dev-manager.md
  - plugin/dev-orchestrator/references/mission-contracts.md
  - plugin/conductor/references/team-kernel.md
  - .claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md
  - .claude/agent-memory/vf-dev-manager/MEMORY.md
autonomous: true
requirements: [SPAWN-01, SPAWN-02, SPAWN-03, SPAWN-04, SPAWN-05, SPAWN-06, SPAWN-07]

estimate:
  tokens: 120000
  raw_tokens: 120000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "vf-coder.md §Entrée prescrit, AVANT toute action, le contrôle de présence de l'outil Agent : présent → gsd-quick --validate obligatoire sur le chemin court (pipeline GSD sur un mandat d'étape), sans bridage par l'allowlist ; absent → arrêt sans coder à la main et retour « bloqué : profondeur », mandat intact (B2)."
    - "vf-coder.md §Garanties n'affirme plus qu'une allowlist change un nom inventé en refus : l'allowlist Agent(...) y est un contrat déclaré non appliqué à l'appel (mesure du 2026-09-17), le mur réel est l'absence de l'outil Agent à la profondeur 3 ; l'esprit « ne réimplémente pas / route vers le bon outil » est conservé."
    - "Le retour « bloqué : profondeur » est défini UNE fois, dans mission-contracts.md : statut blocked + champs frères cause: \"profondeur\" et mandat (recopié intact), sans cinquième statut ; vf-coder.md l'émet et vf-dev-manager.md le consomme en y renvoyant."
    - "vf-dev-manager.md prescrit sur ce retour : ni coder à la place, ni redispatcher vf-coder au même niveau, ni dispatcher les briques GSD en direct ; remonter le mandat intact (SendMessage(to: main), sinon son propre bloc typé blocked + cause + mandat) pour relance au bon niveau."
    - "team-kernel.md porte le constat mesuré du 2026-09-17 (allowlist non appliquée à l'exécution ; Agent/Task absents à la profondeur 3 ; limite non documentée par Anthropic, susceptible de changer) et B1, et ne présente plus la marge de deux niveaux comme un fait vrai."
    - "La note mémoire vf-dev-manager et son entrée d'index disent : profondeur 3 = outil absent (pas l'allowlist), allowlist non appliquée à l'exécution, Phase 40.1 = vf-coder poussé en profondeur 3."
    - "Budget d'instructions tenu : vf-coder.md ≤ 21 instructions, vf-dev-manager.md ≤ 46 instructions et ≤ 250 lignes ; check-instruction-budget rc=0 sans dépassement ; check-agents --strict vert ; suites dev-orchestrator, check-agents, check-overlaps, design-orchestrator au niveau de leur baseline ; aucun fichier hors files_modified touché."
  artifacts:
    - path: "plugin/dev-orchestrator/agents/vf-coder.md"
      provides: "Contrôle de profondeur en §Entrée (B2), allowlist corrigée en §Garanties, champs cause/mandat en §Retour"
      contains: "Contrôle de profondeur, avant toute action"
    - path: "plugin/dev-orchestrator/agents/vf-dev-manager.md"
      provides: "Conduite du manager sur un retour blocked + cause profondeur"
      contains: "cause: \"profondeur\""
    - path: "plugin/dev-orchestrator/references/mission-contracts.md"
      provides: "Contrat unique du retour « bloqué : profondeur » + B1/B2 + constat mesuré"
      contains: "## Retour « bloqué : profondeur »"
    - path: "plugin/conductor/references/team-kernel.md"
      provides: "Constat de profondeur de spawn corrigé (ligne P12 + §Marge de profondeur de dispatch + renvoi de parallélisme)"
      contains: "non documentée par Anthropic"
    - path: ".claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md"
      provides: "Note mémoire corrigée sur la profondeur 3"
      contains: "profondeur 3"
    - path: ".claude/agent-memory/vf-dev-manager/MEMORY.md"
      provides: "Entrée d'index réalignée (≤ 150 caractères)"
      contains: "project_vf-coder-ne-peut-pas-planifier.md"
  key_links:
    - from: "plugin/dev-orchestrator/agents/vf-coder.md"
      to: "plugin/dev-orchestrator/references/mission-contracts.md"
      via: "renvoi de contrat du paragraphe cause/mandat de §Retour"
      pattern: "§Retour « bloqué : profondeur »"
    - from: "plugin/dev-orchestrator/agents/vf-dev-manager.md"
      to: "plugin/dev-orchestrator/references/mission-contracts.md"
      via: "renvoi de contrat du bullet Worker blocked de §Contrôle de flux"
      pattern: "§Retour « bloqué : profondeur »"
    - from: "plugin/conductor/references/team-kernel.md"
      to: "plugin/dev-orchestrator/references/mission-contracts.md"
      via: "renvoi install-path depuis §Marge de profondeur de dispatch"
      pattern: "dev-orchestrator-references/mission-contracts.md` §Retour « bloqué : profondeur »"
    - from: ".claude/agent-memory/vf-dev-manager/MEMORY.md"
      to: ".claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md"
      via: "lien d'index (nom de fichier inchangé)"
      pattern: "project_vf-coder-ne-peut-pas-planifier.md"
---

<objective>
Hotfix doctrinal v2.63.2 : aligner cinq cibles (vf-coder.md, vf-dev-manager.md, mission-contracts.md,
team-kernel.md, note mémoire vf-dev-manager + son index) sur le constat MESURÉ de profondeur de spawn
et sur les arbitrages B1/B2 (arbitrage Samuel, AskUserQuestion session principale, 2026-09-17 —
relayés verbatim par le mandat de vf-dev-manager, attribution transmise, non re-vérifiée par ce plan).

- **B1 (D-B1)** — place du head : incarné dans la session principale (via `/vf-dev`), jamais dispatché
  comme sous-agent (`Task`). Profondeurs visées : manager 1, vf-coder 2, briques GSD 3.
- **B2 (D-B2)** — vf-coder vérifie d'abord la présence de l'outil `Agent`. Présent → `gsd-quick
  --validate` obligatoire sur le chemin court (pipeline GSD sur un mandat de phase), sans se brider
  à cause de son allowlist. Absent → arrêt sans coder à la main, statut « bloqué : profondeur »,
  mandat intact, pour relance au bon niveau par le dispatcheur.

Purpose : deux incidents (Phase 40.1 : head en Task (1) → vf-dev-manager (2) → vf-coder (3) sans
outil ; 2026-09-17 : vf-coder en profondeur 1 qui n'a pas tenté `gsd-quick --validate` en croyant son
allowlist bloquante) viennent d'une doctrine qui affirmait le contraire du runtime.

Output : 6 fichiers édités (5 cibles du mandat, dont l'index mémoire), 3 commits atomiques, un
SUMMARY portant les mesures avant/après et les findings `action: no-op` hors périmètre.

**Fidélité au mandat** : le contenu est déjà spécifié par le mandat. Les textes cibles ci-dessous
(`<target_texts>`) le mettent en forme et ont été **pré-mesurés** au moment du plan sur une copie
du dépôt (gate de budget + check-agents --strict + suites dev-orchestrator, check-agents,
design-orchestrator : tous verts, T76 compris). L'exécuteur les applique VERBATIM ; il ne réinvente
pas la doctrine.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@plugin/dev-orchestrator/agents/vf-coder.md
@plugin/dev-orchestrator/agents/vf-dev-manager.md
@plugin/dev-orchestrator/references/mission-contracts.md
@plugin/conductor/references/team-kernel.md
@.claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md
@.claude/agent-memory/vf-dev-manager/MEMORY.md
@plugin/conductor/scripts/check-instruction-budget.sh
</context>

<budget_contract>
## Ce que le gate compte (plugin/conductor/scripts/check-instruction-budget.sh, lu au plan)

Unité = LIGNE du body (frontmatter exclu, blocs de code clôturés exclus, titres `#` jamais comptés).
Une ligne compte **une** instruction si, en minuscules, elle contient l'un des marqueurs
`jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire`, OU si c'est un item de liste
sous un titre dont le libellé contient `règles|garde-fous|iron law|anti-pattern|lignes rouges|discipline`
(dans vf-dev-manager.md, tout item numéroté de §Discipline de pilotage compte). Plusieurs marqueurs
sur une ligne = 1.

**Piège mesuré au plan** : le motif `ne .* pas` mord sur TOUT mot finissant par « ne » suivi d'une
espace (« une », « chaîne », « aucune », « ligne », « donne »…) dès qu'un « pas »/« passe » suit sur
la même ligne. Une tournure « … de la chaîne …, pas le worker » a fait passer vf-dev-manager.md de 46
à 47 au plan. Toute retouche de libellé = re-mesure.

## Mesures de référence (plan, 2026-09-17, cette arborescence)

| Fichier | Lignes | INSTR | BL-INSTR | Cible après édition |
|---|---|---|---|---|
| vf-coder.md | 122 | 21 | 23 | INSTR ≤ 21 (mandat : ne pas augmenter), lignes libres (pré-mesuré : 138) |
| vf-dev-manager.md | 250 | 46 | 46 | INSTR ≤ 46, lignes ≤ 250 (pré-mesuré : 250) ; 251-300 = avertissement, > 300 interdit |

Attention : pour vf-coder.md le gate resterait vert jusqu'à 23 (baseline) — le vert du gate NE
SUFFIT PAS, la colonne INSTR doit être ≤ 21.

## Comment la place est faite (fusions sémantiques, déjà dans les textes cibles)

- vf-coder.md : +1 ligne-instruction en §Entrée (la ligne « obligatoire … ne te bride pas »),
  −1 en §Garanties (les deux interdits du même principe, « ne réimplémente pas » et « n'improvise
  pas », fusionnés dans l'accroche du bullet réécrit). Net 0.
- vf-dev-manager.md : +1 (bullet `Worker blocked`, un seul « jamais »), −1 et −2 lignes en fermant le
  paragraphe « Entre les étages » : la phrase sur le nœud `revue-N` « désormais posé et piloté en
  direct » y redoublait le point 2 de la même section ; sa trace (D-10/D-11) est reportée dans le
  point 2, et « jamais un cycle complet, jamais corrigés par toi » devient « jamais un cycle complet
  ni corrigés par toi » (même interdit, une ligne). Net 0 instruction, 0 ligne.

## Interdits de méthode (le ratchet ne se contourne pas)

1. Jamais toucher `.planning/instruction-budget-baselines.tsv` ni la sentinelle `.planning/.instruction-budget-armed`.
2. Jamais recoller sur une seule ligne une phrase existante NON réécrite par les textes cibles dans
   le seul but de fusionner deux lignes-marqueurs : cela baisse le compte sans baisser la charge
   (cf. en-tête du script, ADR-031).
3. Jamais remplacer un marqueur par un synonyme dans une phrase existante hors des passages que les
   textes cibles réécrivent.
4. Si, textes cibles appliqués, INSTR dépasse la cible (fichier modifié depuis le plan, par exemple) :
   HALTE, ne rien forcer, rendre `human_needed` avec le chiffre exact avant/après par fichier — le
   mandat exige un `ask-user` chiffré plutôt qu'un forçage.
</budget_contract>

<known_traps>
Gardes existantes qui lisent ces fichiers (mesurées au plan) — si l'une rougit, c'est le TEXTE qui se
corrige, jamais le test (mandat) :

- `test-dev-orchestrator.sh` T29-A/E/B : ni vf-coder.md ni vf-dev-manager.md ne doivent contenir le
  nom des agents nus de planification ou d'exécution du moteur (ni celui de l'agent nu de debug en
  corps de prompt) — les textes cibles de ces deux fichiers disent « briques GSD ».
- T37 (c) : la `description:` de vf-coder.md doit continuer à nommer `vibeflow-head` — frontmatter
  intouché.
- T27 / T27b : dans vf-dev-manager.md et mission-contracts.md, aucune clause (segment borné par « ; »
  ou « · ») ne doit parler de gel/halte de nœud ou de réponse à une attente humaine sans
  qualificatif de mode ; le bloc « **Table de pilotage** » reste intact (ses citations « … »
  doivent exister comme titres de mission-flow.md).
- T25_BRICK_RE / T33 : aucun nouveau paragraphe ne s'ouvre sur `**Plan`, `**Exécution` ou
  `**Cadrage` ; aucune tournure « tout … est interdit/fermé par défaut ».
- T26 D : aucun intitulé du contrat interne de l'exécuteur amont (intitulés anglais de rapport).
- T31-D : la formule « son propre budget » reste absente de vf-dev-manager.md.
- `test-check-agents.sh` T76 : team-kernel.md doit garder les littéraux `maxDepth`,
  `deux niveaux de marge`, `sous-worker`, `2026-08-04`, `1.9.1` et les 7 champs du descripteur
  verbatim. Les textes cibles les conservent en CITATION DATÉE de la lecture périmée — ce qui rend la
  garde verte sans affirmer un fait faux. Le réalignement de T76 lui-même est un finding no-op (F3),
  hors de ce commit.
- `check-machine-paths.sh` : aucun chemin absolu de machine dans les fichiers édités (la note mémoire
  réécrite n'en contient plus aucun).
- Outils proxifiés (rtk) : `grep`, `find`, `ls`, `diff`, `git diff` peuvent tronquer ou mentir sur ce
  poste — les sondes de ce plan comptent en `awk` ; pour l'état git, préférer `git status --porcelain`
  (préfixé `rtk proxy` si le proxy est actif).
- Garde d'isolation de worktree (mesurée au plan) : elle refuse les commandes composées (`&&`,
  heredoc, `cd … &&`), les commandes où `git` n'est pas le premier verbe, et les programmes `awk`
  mêlant `|` et `"`. Les sondes de ce plan sont écrites pour passer ; si l'une est refusée, la
  découper en commandes simples lancées depuis la racine du worktree — jamais la contourner en
  changeant de répertoire.
</known_traps>

<target_texts>
Textes à appliquer VERBATIM (Edit ciblé, jamais Write du fichier entier). Les ancres « avant » citent
le texte existant à repérer.

### T1-A — vf-coder.md §Entrée : paragraphe inséré (D-B2, D-B1)

Ancre : juste après la ligne qui se termine par « sans revue séparée. » (fin du paragraphe « Mandat
tâche courte »), une ligne vide puis :

```markdown
**Contrôle de profondeur, avant toute action** (arbitrage Samuel B2, AskUserQuestion session
principale, 2026-09-17) : vérifie d'abord que l'outil `Agent` figure parmi tes outils de session.
Profondeurs visées (B1) : le head est incarné en session principale, tu es à 1 sous lui et à 2 sous
un manager ; les briques GSD que tes skills lancent occupent le niveau suivant.
Présent → `gsd-quick --validate` est obligatoire sur le chemin court, le pipeline GSD (§Le cycle) sur un mandat d'étape, et ton allowlist ne te bride pas.
Absent (constaté à la profondeur 3, `Task` compris — sonde `ToolSearch` `select:Agent,Task` :
« No matching deferred tools found. ») → arrête-toi sans coder à la main et rends le retour
« bloqué : profondeur » (§Retour), mandat intact, pour que ton dispatcheur relance au bon niveau.
Limite observée, non documentée par Anthropic : elle peut changer avec une version de Claude Code.
```

La mention existante « dispatché par `vibeflow-head` » (description, §Entrée, §Retour) reste en place.

### T1-B — vf-coder.md §Garanties : premier bullet remplacé (D-B2)

Ancre « avant » : le premier bullet de §Garanties, 4 lignes, qui commence par
« - **Ne réimplémente pas** : tu es un routeur. » et se termine par la parenthèse sur la boucle
invisible. Remplacer ces 4 lignes par :

```markdown
- **Ne réimplémente pas, n'improvise pas** : tu es un routeur. Skill non invocable depuis ton
  contexte → dispatche l'équivalent parmi les agents de ton champ `tools:` ; aucun ne convient →
  remonte `blocked` au dispatcheur. Ce champ est un contrat déclaré, pas un mur d'exécution
  (mesuré le 2026-09-17 : l'allowlist `Agent(...)` n'est pas appliquée à l'appel) ; le seul mur
  constaté est l'absence de l'outil `Agent` à la profondeur 3 (§Entrée).
```

### T1-C — vf-coder.md §Retour : paragraphe inséré (D-B2)

Ancre : juste après la ligne « Un point qui défie l'intention/la logique/la sécurité → `action:
ask-user` (escalade, jamais tranché seul). », une ligne vide puis (avant « **Calibration ») :

```markdown
**`cause`/`mandat`** (contrat détaillé : `mission-contracts.md` §Retour « bloqué : profondeur ») :
outil `Agent` absent au contrôle d'entrée → `"statut": "blocked"` plus deux champs frères,
`"cause": "profondeur"` et `"mandat"` (le mandat reçu, recopié intact) ; aucun cinquième statut,
aucune ligne produite à la main — ton dispatcheur relance au bon niveau.
```

La ligne du bloc typé (`"statut": "passed|gaps_found|human_needed|blocked"`) reste INCHANGÉE.

### T1-D — vf-dev-manager.md §Orchestration par étape : deux retouches (fusion de place)

1. Point 2 (**Revue**) : dans la ligne « `revue-N` (deps=build) posé **systématiquement**, sans
   condition. Protocole complet (boucle de », remplacer « sans condition. » par
   « sans condition (D-10/D-11). » — même ligne, aucune ligne ajoutée.
2. Paragraphe de clôture de la section (5 lignes, commence par « Entre les étages : un compte rendu
   qui révèle une décision → panel. Le nœud `revue-N` est ») remplacé par :

```markdown
Entre les étages : un compte rendu qui révèle une décision → panel. Des correctifs remontés par la
revue ou l'audit → renvoyés à `vf-coder` en mandat de **correction CIBLÉE**, jamais un cycle
complet ni corrigés par toi.
```

### T1-E — vf-dev-manager.md §Contrôle de flux : bullet inséré (D-B1, D-B2)

Ancre : juste après le bullet « **Worker coupé** » (2 lignes, finit par « §Pattern G, ne pas
reformuler ici. »), avant le bullet « **Entre les étapes** ». Deux lignes, sans ligne vide :

```markdown
- **Worker `blocked` + `cause: "profondeur"`** (`vf-coder` sans outil `Agent` ; contrat : `mission-contracts.md` §Retour « bloqué : profondeur ») : ni codé par toi, ni redispatché au même niveau — c'est le niveau de dispatch qui est en cause, pas le worker (arbitrage Samuel B1, AskUserQuestion session principale, 2026-09-17 : manager 1, `vf-coder` 2, briques GSD 3).
  Remonte le mandat intact pour relance au bon niveau — `SendMessage(to: "main")`, sinon ton bloc typé `blocked` + `cause` + `mandat` ; jamais de brique GSD dispatchée en direct à sa place (voie unique, `GSD-PIPELINE.md` §9 ; P3).
```

Choix de voie consigné (mandat : « la voie la plus conforme à la doctrine déjà en place ») :
REMONTER, pas dispatcher les briques en direct. Motifs, tous déjà écrits dans le dépôt :
(a) voie unique — `GSD-PIPELINE.md` §9 ferme le dispatch direct des agents nus de planification et
d'exécution, et vf-dev-manager.md l'applique déjà à lui-même (« aucune exception à la voie unique,
tu gagnes un moment, pas un outil ») ; (b) P3 — un manager ne produit jamais ; (c) Pattern C —
`blocked` = dépendance non satisfaite, « traiter la dépendance » : la dépendance est ici le niveau
de dispatch, que le manager ne peut pas changer depuis son propre niveau (B1) ; (d) canal —
`SendMessage(to: "main")` est déjà l'escalade vivante du filet D-09 et du relais Pattern H.
Ni B1 ni B2 ne sont contournés : ce choix en DÉCOULE, il ne tranche aucune question de fond
nouvelle. Le seul trou restant — la conduite du head qui reçoit ce retour — vit dans
head-governance.md, hors périmètre : finding F6.

### T1-F — mission-contracts.md : section insérée (D-B1, D-B2, contrat)

Ancre : juste après la section « ## Décompte de budget épuisé (D-26, D-27, D-28, plan 23-07) »
(dont le paragraphe finit par « ne pas la reformuler ici (ADR-030). »), une ligne vide puis, AVANT
« ## Étage revue — deux objets disjoints » :

~~~~markdown
## Retour « bloqué : profondeur » (arbitrages B1/B2, 2026-09-17)

**Constat mesuré** (sonde en session principale, 2026-09-17). Aux profondeurs 1 et 2, l'outil
`Agent` est visible et un lancement est accepté. À la profondeur 3, `Agent` et `Task` sont
**absents**, quel que soit le type d'agent : `ToolSearch` `select:Agent,Task` rend « No matching
deferred tools found. ». L'allowlist `Agent(type, …)` du frontmatter n'est **pas appliquée à
l'appel** : `vf-coder` a lancé `gsd-executor` et `gsd-planner`, absents de sa liste ; `gsd-executor`
lancé avec `isolation: "worktree"` démarre. Limite **observée, non documentée par Anthropic** :
elle peut changer avec une version de Claude Code — une nouvelle sonde la re-mesure.

**Incidents fondateurs.** Phase 40.1 : head dispatché en `Task` (1) → `vf-dev-manager` (2) →
`vf-coder` (3), sans outil de lancement. 2026-09-17 : un `vf-coder` à la profondeur 1 n'a pas tenté
`gsd-quick --validate`, croyant à tort que son allowlist l'en empêchait.

**B1 — place du head** (arbitrage Samuel, AskUserQuestion session principale, 2026-09-17) : le head
est incarné dans la session principale (via `/vf-dev`), jamais dispatché comme sous-agent (`Task`).
Profondeurs visées : manager 1, `vf-coder` 2, briques GSD 3.

**B2 — `vf-coder` sans l'outil `Agent`** (arbitrage Samuel, AskUserQuestion session principale,
2026-09-17) : `vf-coder` vérifie d'abord la présence de l'outil `Agent`. Présent →
`gsd-quick --validate` obligatoire sur le chemin court, le pipeline GSD sur un mandat d'étape — son
allowlist ne le bride pas. Absent → il s'arrête sans coder à la main et rend « bloqué : profondeur »,
mandat intact, pour que son dispatcheur relance au bon niveau.

**Le contrat.** Le bloc typé (Pattern C, `mission-flow.md`) garde ses quatre statuts : **aucun
cinquième**. Le retour porte `"statut": "blocked"` plus deux champs **optionnels** frères de
`statut`/`findings`/`noeuds_debloques` :

```
"cause": "profondeur",
"mandat": "<le mandat reçu, recopié intact>"
```

Présents **uniquement** sur ce retour — absents de tout autre `blocked`. `mandat` est recopié
verbatim (même règle que les champs frères : jamais résumé, jamais reformulé) ; aucun commit n'a été
produit, puisque rien n'a été codé.

**La conduite du dispatcheur.** Relancer le mandat au bon niveau — jamais le coder à la place, jamais
le redispatcher au même niveau, qui reproduirait la même profondeur. Côté manager : `vf-dev-manager.md`
§Contrôle de flux (remonter le mandat intact). Côté head : relance depuis la session principale (B1).
~~~~

### T2-A — team-kernel.md, ligne du tableau « Cloisonnement par tools (P12) » (≈ l. 23)

Dans la cellule, remplacer le fragment
« jamais pour un agent dispatché en sous-agent (doc officielle sub-agents). Le garant machine réel »
par :

```markdown
jamais pour un agent dispatché en sous-agent (doc officielle sub-agents ; **confirmé par mesure le 2026-09-17** : `vf-coder` a lancé des agents absents de sa liste). La vraie limite d'exécution est ailleurs : les outils `Agent` et `Task` sont **absents à la profondeur 3** — limite observée, non documentée par Anthropic, qui peut changer avec une version de Claude Code (§Marge de profondeur de dispatch ci-dessous). Le garant machine réel
```

(Tout reste sur la MÊME ligne de tableau : aucun retour à la ligne, sinon le tableau casse.)

### T2-B — team-kernel.md, titre de §Marge de profondeur de dispatch

Remplacer
« ### Marge de profondeur de dispatch (mesuré le 2026-08-04, `@opengsd/gsd-core` 1.9.1) »
par :

```markdown
### Marge de profondeur de dispatch (descripteur lu le 2026-08-04, `@opengsd/gsd-core` 1.9.1 — mesure du 2026-09-17)
```

Le préambule « Le descripteur … recopié verbatim — inchangé depuis la 1.9.0 » et le bloc clôturé du
descripteur (7 champs) restent INTACTS.

### T2-C — team-kernel.md, §Marge : trois paragraphes remplacés

Ancre « avant » : les trois paragraphes qui suivent le bloc du descripteur — celui qui commence par
« **Ce que nous en consommons** », celui qui commence par « **Ce que cette marge autorise** » et celui
qui commence par « **Sa borne, en revanche, est stricte** » (jusqu'à « quelle que soit la profondeur
restante. » inclus). Remplacer ces trois paragraphes par :

```markdown
**Lecture du 2026-08-04 — PÉRIMÉE par la mesure du 2026-09-17.** Sur la foi de `maxDepth: 5`, on
écrivait que la chaîne la plus profonde du kernel — `vf-dev-manager` → `vf-coder` → agent `gsd-*` —
occupait 3 niveaux sur 5 et laissait « deux niveaux de marge », donc qu'un worker pouvait
dispatcher un **sous-worker** à n'importe quel étage. Un descripteur n'est pas une preuve.

**Ce que la sonde mesure** (session principale, 2026-09-17) : aux profondeurs 1 et 2, l'outil
`Agent` est visible et un lancement est accepté ; à la profondeur 3, `Agent` et `Task` sont
**absents**, quel que soit le type d'agent (`ToolSearch` `select:Agent,Task` → « No matching
deferred tools found. »). Un agent de profondeur 3 ne lance donc rien : la marge réelle au-delà de
la chaîne ci-dessus est **nulle**. Limite **observée, non documentée par Anthropic** — elle peut
changer avec une version de Claude Code ; une nouvelle sonde la re-mesure, jamais une relecture du
descripteur. Incident fondateur : Phase 40.1, head dispatché en `Task` (1) → `vf-dev-manager` (2) →
`vf-coder` (3), sans outil de lancement.

**Ce qui en découle** (arbitrages Samuel B1/B2, AskUserQuestion session principale, 2026-09-17) :
le head est incarné dans la session principale (via `/vf-dev`), jamais dispatché en `Task` —
profondeurs visées : manager 1, `vf-coder` 2, briques GSD 3. Un **sous-worker** reste licite
depuis la profondeur 2 au plus. Un worker qui constate l'outil `Agent` absent rend `blocked` +
`cause: "profondeur"`, mandat intact, sans rien produire à la main :
`dev-orchestrator-references/mission-contracts.md` §Retour « bloqué : profondeur ». La question du
nesting, close en Phase 24 sur la foi du descripteur, est rouverte et tranchée par ces arbitrages.

**Sa borne reste stricte** : la profondeur disponible ne rend licite aucun contournement de la
**voie unique d'invocation** (GSDC-05, Phase 23 — les briques de cycle s'invoquent par leur skill,
jamais par dispatch direct d'un agent nu), ni du **contrat déclaré des allowlists** `Agent(...)`
(P12, ci-dessus — un contrat lint-vérifié, pas un mur d'exécution). Aucun chemin que la doctrine
interdit par ailleurs ne devient licite — en particulier `manager → worker → manager`, que le
verrou de driver refuse quelle que soit la profondeur.
```

### T2-D — team-kernel.md, §Étage de parallélisme : renvoi de mesure

Remplacer
« (la profondeur\n2 → 3 n'a pas été mesurée) » (le « 2 → 3 » ouvre la ligne suivante)
par :

```markdown
(la profondeur
2 → 3 n'y a pas été mesurée — elle l'a été le 2026-09-17, §Marge de profondeur de dispatch)
```

Le paragraphe « Étages croisés » (« le runtime ignore la liste de noms entre parenthèses pour tout
agent dispatché en sous-agent ») est déjà conforme au constat : NE PAS le toucher.

### T3-A — note mémoire, contenu intégral (remplace le fichier, nom de fichier inchangé)

Fichier : `.claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md`. Le titre
« vf-coder ne peut pas planifier » devient faux (vf-coder planifie aux profondeurs 1 et 2) : `name` et
`description` sont ajustés ; le NOM DE FICHIER ne change pas (lien d'index, aucun `[[lien]]` entrant
vers l'ancien `name` — vérifié au plan). `description` guillemetée (aucun « : » nu en scalaire YAML).

```markdown
---
name: profondeur-3-sans-outil-agent
description: "À la profondeur 3, aucun agent n'a Agent ni Task (limite runtime mesurée, pas l'allowlist, jamais appliquée à l'appel) ; Phase 40.1 = vf-coder poussé en profondeur 3 ; B1/B2"
metadata:
  type: project
---

À la profondeur 3, un agent n'a ni `Agent` ni `Task` — c'est une limite du runtime, pas son allowlist. Sonde en session principale, 2026-09-17 : aux profondeurs 1 et 2, `Agent` est visible et un lancement est accepté ; à la profondeur 3, `Agent` et `Task` sont absents quel que soit le type d'agent (`ToolSearch` `select:Agent,Task` → « No matching deferred tools found. »). L'allowlist `Agent(...)` du frontmatter n'est pas appliquée à l'exécution : `vf-coder` a lancé `gsd-executor` et `gsd-planner`, absents de sa liste. Limite observée, non documentée par Anthropic : elle peut changer avec une version de Claude Code.

Incident Phase 40.1 (2026-09-16, ~160k jetons perdus) : head dispatché en `Task` (1) → `vf-dev-manager` (2) → `vf-coder` (3). Sans outil de lancement à cette profondeur, `gsd-plan-phase` s'est arrêté net à l'étape « Spawn gsd-planner » et a rendu `blocked` sans rien écrire. Second incident, 2026-09-17 : un `vf-coder` à la profondeur 1 n'a pas tenté `gsd-quick --validate`, croyant à tort que son allowlist l'en empêchait.

**Why:** la profondeur de lancement est bornée par le runtime (outil absent à la profondeur 3), jamais par les allowlists ; et le skill interdit d'absorber le rôle du planificateur en ligne.

**How to apply:** arbitrages Samuel B1/B2 (AskUserQuestion session principale, 2026-09-17). B1 : le head est incarné en session principale via `/vf-dev`, jamais dispatché en `Task` — manager 1, `vf-coder` 2, briques GSD 3. B2 : `vf-coder` vérifie la présence de l'outil `Agent` avant toute action ; absent, il rend `blocked` + `cause: "profondeur"` + mandat intact. Sur ce retour, suivre `vf-dev-manager.md` §Contrôle de flux : remonter pour relance au bon niveau, ni coder ni dispatcher les briques en direct. Le contournement de la Phase 40.1 (un `general-purpose` qui suit la définition du planificateur, puis un `gsd-plan-checker` frais, dispatchés en direct) est antérieur à B1/B2 et contourne la voie unique : ne pas le reproduire. Voir aussi [[dispatches-via-skills-non-forkees]]. Un checker peut citer un fait de tag faux (« v2.63.0 contient a7f414a ») : exiger la commande exacte, et la rejouer avant de relayer ([[descripteur-gsd-core-non-probant]]).
```

### T3-B — MEMORY.md, ligne 70 remplacée (147 caractères, mesuré au plan)

Ancre « avant » : la ligne unique qui contient `project_vf-coder-ne-peut-pas-planifier.md`. Remplacer
la ligne entière par :

```markdown
- [Profondeur 3 sans outil Agent](project_vf-coder-ne-peut-pas-planifier.md) — limite runtime, pas l'allowlist ; head en session principale (B1/B2)
```

Aucune autre ligne de l'index ne bouge (71 entrées avant, 71 après).
</target_texts>

<tasks>

<task type="tracer">
  <name>Tâche 1 (tracer) : contrat « bloqué : profondeur » de bout en bout — source mission-contracts.md → émetteur vf-coder.md → consommateur vf-dev-manager.md</name>
  <files>plugin/dev-orchestrator/references/mission-contracts.md, plugin/dev-orchestrator/agents/vf-coder.md, plugin/dev-orchestrator/agents/vf-dev-manager.md</files>
  <precondition>Avant toute édition, `bash plugin/conductor/scripts/check-instruction-budget.sh` rend rc=0 et publie vf-coder.md à 122 lignes / 21 INSTR et vf-dev-manager.md à 250 lignes / 46 INSTR — sinon ces fichiers ont bougé depuis le plan : HALTE, rendre human_needed avec les chiffres lus.</precondition>
  <read_first>
    - plugin/conductor/scripts/check-instruction-budget.sh (fonction count_instructions, MARKER_RE, RULES_TITLE_RE)
    - plugin/dev-orchestrator/agents/vf-coder.md (intégral, 122 lignes)
    - plugin/dev-orchestrator/agents/vf-dev-manager.md (§Orchestration par étape et §Contrôle de flux)
    - plugin/dev-orchestrator/references/mission-contracts.md (§Décompte de budget épuisé et §Étage revue, pour l'ancre)
    - ce plan : blocs budget_contract, known_traps, target_texts T1-A à T1-F
  </read_first>
  <action>
Mesure d'abord la référence (précondition) et relève, pour le SUMMARY, lignes et INSTR des deux agents
depuis le rapport du gate, plus le résultat de base des suites dev-orchestrator (attendu :
« 207 OK / 0 KO / 0 SKIP ») et `check-agents.sh --strict` sur `plugin/dev-orchestrator/agents`.

Puis applique, par Edit ciblé et dans cet ordre, les textes cibles VERBATIM :
1. T1-F dans mission-contracts.md — la section de contrat unique du retour « bloqué : profondeur »
   (constat mesuré, incidents, B1 per D-B1, B2 per D-B2, contrat `statut: blocked` + `cause` +
   `mandat` sans cinquième statut, conduite du dispatcheur). C'est la source : les deux agents y
   renvoient par le titre exact « §Retour « bloqué : profondeur » ».
2. T1-A dans vf-coder.md §Entrée — contrôle de présence de l'outil Agent avant toute action (D-B2),
   profondeurs visées (D-B1), mention « limite observée, non documentée par Anthropic ».
3. T1-B dans vf-coder.md §Garanties — remplace le premier bullet : l'allowlist devient un contrat
   déclaré non appliqué à l'appel, le mur réel est l'outil absent à la profondeur 3 ; la parenthèse
   finale de l'ancien bullet (sur le nom inventé et la boucle invisible) disparaît entièrement ;
   l'esprit « ne réimplémente pas / route vers le bon outil » reste (D-B2).
4. T1-C dans vf-coder.md §Retour — champs frères `cause`/`mandat` du bloc typé ADR-053 ; la ligne
   d'énumération des quatre statuts reste identique au caractère près.
5. T1-D puis T1-E dans vf-dev-manager.md — fusion de place (report D-10/D-11 dans le point 2,
   paragraphe « Entre les étages » ramené à 3 lignes), puis bullet `Worker blocked + cause
   profondeur` (D-B1, D-B2 : ni coder, ni redispatcher au même niveau, ni briques en direct ;
   remonter le mandat intact par SendMessage(to: "main"), sinon bloc typé). La voie « remonter » est
   le choix consigné dans T1-E, motivé par la doctrine existante — ne pas la remplacer par un
   dispatch direct des briques.

Ne touche NI le frontmatter de vf-coder.md ni celui de vf-dev-manager.md (T37 (c), T18/T29 allowlists),
ni le bloc « **Table de pilotage** ». Aucun autre passage de ces trois fichiers ne change : pas de
retouche de style, pas de ré-emballage de lignes existantes (budget_contract, interdit 2).

Re-mesure après CHAQUE fichier d'agent édité. Si INSTR dépasse la cible (vf-coder ≤ 21,
vf-dev-manager ≤ 46) ou si vf-dev-manager dépasse 250 lignes : relis la ligne fautive avec la règle
du budget_contract (piège des mots finissant par « ne » suivis de « pas »), corrige UNIQUEMENT dans le
texte que tu viens d'insérer, re-mesure ; si l'écart persiste : HALTE et human_needed chiffré
(budget_contract, interdit 4).

Si une suite rougit, lis la trace (assertion, attendu, obtenu) : c'est le texte inséré qui se
corrige, jamais `test-dev-orchestrator.sh` (hors périmètre).

Commit atomique (un seul verbe git par appel Bash, pas de heredoc, pas de `&&`) :
`git commit plugin/dev-orchestrator/references/mission-contracts.md plugin/dev-orchestrator/agents/vf-coder.md plugin/dev-orchestrator/agents/vf-dev-manager.md`
avec message en français, via plusieurs `-m` : titre
« fix(dev-orchestrator): contrat « bloqué : profondeur » — vf-coder contrôle l'outil Agent avant d'agir, vf-dev-manager remonte au bon niveau »,
corps citant « arbitrages Samuel B1/B2, AskUserQuestion session principale, 2026-09-17 (relayés par le
mandat vf-dev-manager) » et les mesures INSTR avant/après, puis les trailers d'attribution prescrits
par TA configuration de session (à défaut : `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` et
`Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC`). Pas de push, pas de PR,
pas de bump de version (hors périmètre).
  </action>
  <verify>
    <automated>bash plugin/conductor/scripts/check-instruction-budget.sh</automated>
    <automated>bash plugin/conductor/scripts/check-instruction-budget.sh | awk -F' [|] ' '$1 ~ /agents\/vf-(coder|dev-manager)[.]md$/ {print $1, "LIGNES=" $2, "INSTR=" $4}'</automated>
    <automated>bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents</automated>
    <automated>bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh</automated>
    <automated>awk '/^## Retour « bloqué : profondeur »/{n++} END{print "titre-contrat=" n+0}' plugin/dev-orchestrator/references/mission-contracts.md</automated>
    <automated>awk '/§Retour « bloqué : profondeur »/{n++} END{print "renvoi=" n+0}' plugin/dev-orchestrator/agents/vf-coder.md plugin/dev-orchestrator/agents/vf-dev-manager.md</automated>
    <automated>awk '/refus muet/{n++} END{print "ancienne-affirmation-allowlist=" n+0}' plugin/dev-orchestrator/agents/vf-coder.md</automated>
    <automated>awk '/passed.gaps_found.human_needed.blocked./{n++} /cause.: .profondeur/{c++} /Contrôle de profondeur, avant toute action/{e++} END{print "enum4=" n+0, "cause=" c+0, "entree=" e+0}' plugin/dev-orchestrator/agents/vf-coder.md</automated>
  </verify>
  <acceptance_criteria>
    - Gate de budget : rc=0, « 0 depassement(s) » ; vf-coder.md INSTR ≤ 21 ; vf-dev-manager.md INSTR ≤ 46 et LIGNES ≤ 250.
    - check-agents --strict : rc=0, « agents conformes ».
    - test-dev-orchestrator.sh : « 207 OK / 0 KO / 0 SKIP » (ou le total de base relevé en précondition, 0 KO).
    - titre-contrat=1 dans mission-contracts.md ; renvoi ≥ 2 (au moins un par agent — le vérifier fichier par fichier si la somme est ambiguë).
    - ancienne-affirmation-allowlist=0 dans vf-coder.md.
    - vf-coder.md : enum4=1 (énumération des quatre statuts intacte), cause ≥ 1, entree=1.
    - Un seul commit, portant exactement les 3 fichiers de la tâche.
  </acceptance_criteria>
  <done>Le contrat « bloqué : profondeur » existe une fois (mission-contracts.md), vf-coder.md l'émet après contrôle de l'outil Agent (B2) et ne prétend plus que l'allowlist bloque un dispatch, vf-dev-manager.md le consomme en remontant au bon niveau (B1) ; budgets d'instructions tenus ; suites vertes ; commit posé.</done>
</task>

<task type="auto">
  <name>Tâche 2 : team-kernel.md — allowlist non appliquée à l'appel, outils absents à la profondeur 3, marge de deux niveaux déclarée périmée</name>
  <files>plugin/conductor/references/team-kernel.md</files>
  <read_first>
    - plugin/conductor/references/team-kernel.md (l. 14-62 : tableau du kernel et §Marge de profondeur de dispatch ; l. 105-112 : renvoi de mesure du parallélisme ; l. 235-252 : Étages croisés, à NE PAS toucher)
    - plugin/conductor/scripts/tests/test-check-agents.sh (bloc T76, ≈ l. 1391-1417 : littéraux gardés)
    - ce plan : known_traps (T76), target_texts T2-A à T2-D
  </read_first>
  <action>
Relève d'abord la base de `bash plugin/conductor/scripts/tests/test-check-agents.sh` (attendu :
« 81 OK · 0 KO ») pour le SUMMARY.

Applique VERBATIM, par Edit ciblé :
1. T2-A — dans la cellule de la ligne de tableau « Cloisonnement par tools (P12) » : confirmation
   par la mesure du 2026-09-17 que l'allowlist `Agent(...)` n'est pas appliquée à l'exécution, et la
   vraie limite (outils `Agent`/`Task` absents à la profondeur 3, observée, non documentée par
   Anthropic, susceptible de changer avec une version de Claude Code). La cellule reste sur UNE ligne.
2. T2-B — parenthèse du titre de §Marge de profondeur de dispatch (le libellé « Marge de profondeur
   de dispatch », la date 2026-08-04 et la version 1.9.1 restent).
3. T2-C — remplace les trois paragraphes qui suivent le bloc du descripteur : la lecture du
   2026-08-04 devient une citation datée et PÉRIMÉE (elle garde les littéraux gardés par T76 en
   citation), le constat de la sonde du 2026-09-17 est écrit, B1 et B2 en découlent (D-B1, D-B2), la
   borne de voie unique est conservée et l'allowlist y devient un contrat déclaré, pas un mur
   d'exécution. Les phrases qui affirmaient qu'il restait deux niveaux disponibles et que la
   question du nesting était close disparaissent de l'affirmation.
4. T2-D — le renvoi de réserve de mesure du §Étage de parallélisme pointe la mesure du 2026-09-17.

Le bloc clôturé du descripteur (7 champs) et le paragraphe « Étages croisés » ne changent pas. Aucun
autre passage du fichier ne bouge. `test-check-agents.sh` est hors périmètre : si T76 rougit, c'est
le texte qui se corrige (il doit garder les littéraux listés dans known_traps), jamais la garde — et
le réalignement de T76 reste le finding F3, pas un geste de cette tâche (« un garde ne se desserre
jamais dans le commit qu'il autorise »).

Commit atomique (un verbe git par appel, pas de heredoc) :
`git commit plugin/conductor/references/team-kernel.md`, message en français via `-m` : titre
« docs(conductor): team-kernel — allowlist non appliquée à l'appel, outils Agent/Task absents à la profondeur 3 »,
corps citant la sonde du 2026-09-17 et « arbitrages Samuel B1/B2, AskUserQuestion session principale,
2026-09-17 (relayés par le mandat vf-dev-manager) », trailers d'attribution comme en Tâche 1.
  </action>
  <verify>
    <automated>bash plugin/conductor/scripts/tests/test-check-agents.sh</automated>
    <automated>bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh</automated>
    <automated>awk '/Il reste donc deux niveaux de marge/{a++} /clôt la question du nesting/{b++} END{print "marge-affirmee=" a+0, "nesting-clos=" b+0}' plugin/conductor/references/team-kernel.md</automated>
    <automated>awk '/2026-09-17/{d++} /non documentée par Anthropic/{u++} /absents à la profondeur 3/{p++} /Retour « bloqué : profondeur »/{r++} /PÉRIMÉE par la mesure du 2026-09-17/{x++} END{print "date=" d+0, "non-doc=" u+0, "p3-ligne23=" p+0, "renvoi=" r+0, "perime=" x+0}' plugin/conductor/references/team-kernel.md</automated>
    <automated>awk '/maxDepth: 5/{m++} /deux niveaux de marge/{g++} /sous-worker/{s++} END{print "maxDepth5=" m+0, "litteral-marge=" g+0, "sous-worker=" s+0}' plugin/conductor/references/team-kernel.md</automated>
  </verify>
  <acceptance_criteria>
    - test-check-agents.sh : « 81 OK · 0 KO » (T76 vert).
    - test-design-orchestrator.sh : « 29 OK / 0 KO / 0 SKIP ».
    - marge-affirmee=0 et nesting-clos=0.
    - date ≥ 4, non-doc ≥ 2, p3-ligne23=1, renvoi ≥ 1, perime=1.
    - maxDepth5 ≥ 1, litteral-marge ≥ 1, sous-worker ≥ 1 (littéraux T76 conservés, en citation datée).
    - Un seul commit, portant uniquement team-kernel.md.
  </acceptance_criteria>
  <done>team-kernel.md dit le fait mesuré (allowlist non appliquée à l'exécution ; Agent/Task absents à la profondeur 3 ; limite non documentée, révisable) et B1/B2, sans plus présenter la marge de deux niveaux comme vraie ; T76 et la suite design restent verts ; commit posé.</done>
</task>

<task type="auto">
  <name>Tâche 3 : note mémoire vf-dev-manager et son index réalignés sur le constat, findings no-op consignés au SUMMARY</name>
  <files>.claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md, .claude/agent-memory/vf-dev-manager/MEMORY.md</files>
  <read_first>
    - .claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md (intégral, 12 lignes)
    - .claude/agent-memory/vf-dev-manager/MEMORY.md (ligne 70)
    - ce plan : target_texts T3-A et T3-B, bloc findings_no_op
  </read_first>
  <action>
1. T3-A : remplace le contenu intégral de la note (Read puis Write du même chemin — le nom de fichier
   ne change pas). Le fait mesuré remplace les deux affirmations fausses de l'ancienne version
   (l'absence d'outil attribuée à l'allowlist, et l'impossibilité générale pour un sous-agent imbriqué
   de lancer) : profondeur 3 = outil absent, allowlist non appliquée à l'exécution, Phase 40.1 =
   vf-coder poussé en profondeur 3 (D-B1, D-B2). `name` et `description` sont ajustés parce que le
   titre d'origine devient faux. Aucun chemin absolu de machine dans le texte.
2. T3-B : remplace la ligne d'index correspondante dans MEMORY.md par Edit ciblé ; aucune autre ligne.
3. Re-vérifie sur l'arbre courant chaque référence `fichier:ligne` du bloc findings_no_op (le contenu
   cité y est-il toujours, à cette ligne ?) et recopie la liste, lignes corrigées si elles ont glissé,
   dans le SUMMARY et dans le bloc typé final (`action: no-op`). Aucun de ces fichiers n'est édité.

Commit atomique (un verbe git par appel, pas de heredoc) :
`git commit .claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md .claude/agent-memory/vf-dev-manager/MEMORY.md`,
message en français via `-m` : titre
« chore(memoire): corrige la note vf-dev-manager sur la profondeur de spawn (constat du 2026-09-17) »,
corps citant « arbitrages Samuel B1/B2, AskUserQuestion session principale, 2026-09-17 (relayés par le
mandat vf-dev-manager) », trailers d'attribution comme en Tâche 1.
  </action>
  <verify>
    <automated>python3 -c "import yaml;t=open('.claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md',encoding='utf-8').read();fm=yaml.safe_load(t.split('---',2)[1]);print('name=',fm['name']);print('type=',fm['metadata']['type'])"</automated>
    <automated>python3 -c "[print('len=',len(l.rstrip('\n'))) for l in open('.claude/agent-memory/vf-dev-manager/MEMORY.md',encoding='utf-8') if 'project_vf-coder-ne-peut-pas-planifier.md' in l]"</automated>
    <automated>awk '/malgré son allowlist/{a++} /sous-agents imbriqués/{b++} /profondeur 3/{p++} /2026-09-17/{d++} /Phase 40.1/{f++} END{print "faux1=" a+0, "faux2=" b+0, "p3=" p+0, "date=" d+0, "incident=" f+0}' .claude/agent-memory/vf-dev-manager/project_vf-coder-ne-peut-pas-planifier.md</automated>
    <automated>awk '/^- \[/{n++} END{print "entrees=" n+0}' .claude/agent-memory/vf-dev-manager/MEMORY.md</automated>
    <automated>bash scripts/check-machine-paths.sh</automated>
  </verify>
  <acceptance_criteria>
    - YAML de la note valide : name=profondeur-3-sans-outil-agent, type=project.
    - Ligne d'index : len ≤ 150, une seule ligne correspondante.
    - faux1=0, faux2=0, p3 ≥ 1, date ≥ 1, incident ≥ 1.
    - entrees=71 (aucune entrée ajoutée ni perdue).
    - check-machine-paths.sh : rc=0.
    - Un seul commit, portant exactement les 2 fichiers mémoire.
  </acceptance_criteria>
  <done>La note mémoire et son entrée d'index disent le fait mesuré (profondeur 3 = outil absent, allowlist non appliquée, Phase 40.1 = vf-coder en profondeur 3) avec B1/B2 ; les findings no-op sont re-vérifiés et consignés ; commit posé.</done>
</task>

</tasks>

<findings_no_op>
Prescriptions HORS PÉRIMÈTRE contraires (ou aveugles) à B1/B2 ou au constat mesuré — relevées au plan
le 2026-09-17, à NE PAS éditer ici, à re-router. À recopier (lignes re-vérifiées) dans le SUMMARY et
dans le bloc typé final, `action: "no-op"`.

| ID | severity | ref | Constat |
|---|---|---|---|
| F1 | majeur | plugin/dev-orchestrator/skills/vf-dev/SKILL.md:8 | « Incarne (ou dispatche via Task) l'agent `vibeflow-head` » — la branche « dispatche via Task » contredit B1. |
| F2 | majeur | plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md:60-63 | Règle 5 : l'allowlist `Agent(...)` restreindrait le spawn aux workers listés — contraire au constat (non appliquée à l'appel) ; c'est la croyance qui a bridé vf-coder (B2). |
| F3 | majeur | plugin/conductor/scripts/tests/test-check-agents.sh:1391-1417 (T76) | La garde tient la marge « deux niveaux » et la permission « sous-worker » pour doctrine vivante ; verte ici par citation datée, mais son intention et son libellé `ok` sont périmés — réalignement dans un commit séparé (règle team-kernel : un garde ne se desserre jamais dans le commit qu'il autorise). |
| F4 | mineur | .claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md:10 et :19-21 | « sous SON allowlist » et dispatch « refusé sans erreur visible » pour un agent hors allowlist — contraire au constat. |
| F5 | mineur | .claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md:12-13 | « l'outil `Agent` d'un worker est borné par un allowlist de `subagent_type` fixe » — à re-mesurer : vise peut-être le registre de session, pas l'allowlist du frontmatter. |
| F6 | majeur | plugin/dev-orchestrator/references/head-governance.md (§1 l. 22-31, §3) | Aucune conduite du head sur un retour `blocked` + `cause: "profondeur"` (relance depuis la session principale, B1) — trou, pas contradiction. |
| F7 | mineur | plugin/dev-orchestrator/references/mission-flow.md:230-231 et :259-260 (Pattern C) | `blocked` = « dépendance non satisfaite », sans champ `cause` — compatible, mais le foyer unique de la table de pilotage ignore le nouveau champ. |
| F8 | mineur | .planning/REQUIREMENTS.md:469 (GSDA-20) | Exigence cochée qui écrit la marge de profondeur comme doctrine — ledger historique, à annoter si la doctrine du ledger l'exige. |
</findings_no_op>

<source_audit>
| Source (mandat) | Item | Couvert par |
|---|---|---|
| Arbitrage B1 | head incarné en session principale ; profondeurs 1/2/3 | T1 (T1-A, T1-E, T1-F), T2 (T2-C), T3 (T3-A) |
| Arbitrage B2 | contrôle de l'outil Agent ; présent → gsd-quick --validate obligatoire sans bridage ; absent → arrêt + « bloqué : profondeur » | T1 (T1-A, T1-C, T1-F) |
| Fichier 1 | vf-coder §Entrée / §Garanties / §Retour ; mention vibeflow-head conservée ; INSTR ≤ 21 | T1 (T1-A, T1-B, T1-C) |
| Fichier 2 | vf-dev-manager : conduite sur « bloqué : profondeur », voie consignée, INSTR ≤ 46, lignes ≤ 250 | T1 (T1-D, T1-E) |
| Fichier 3 | mission-contracts : contrat documenté ; alignement B1 (aucune prescription `Task(vibeflow-head)` présente au plan — vérifié) | T1 (T1-F) |
| Fichier 4 | team-kernel : note allowlist l. 23 + mentions de profondeur de spawn | T2 (T2-A à T2-D) |
| Fichier 5 | note mémoire + name/description + ligne d'index ≤ 150 | T3 (T3-A, T3-B) |
| Constat | « limite observée, non documentée par Anthropic, peut changer » dans la doctrine | T1-A, T1-F, T2-A, T2-C, T3-A |
| Hors périmètre | prescriptions contraires ailleurs → finding no-op fichier:ligne | bloc findings_no_op, recopié par T3 |
| Vérifications | budget rc=0 ; check-agents --strict ; suites non modifiées | verify de T1, T2, T3 + verification |

Aucun item manquant. Aucune question de fond non couverte par B1/B2 n'a été tranchée (voir le choix
consigné en T1-E) ; le trou côté head est F6.
</source_audit>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| doctrine → agents dispatchés | Le texte des agents et références est chargé comme prompt : une prescription fausse change le comportement réel des workers (cas d'origine de ce hotfix). |
| mandat relayé → commit | Les arbitrages B1/B2 arrivent par le mandat de vf-dev-manager, pas de Samuel en direct : le commit les cite, il ne les vérifie pas. |
| garde de test → texte gardé | T76 et les gardes T27/T29 lisent ce que la tâche écrit. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-SPAWN-01 | Elevation of Privilege | vf-coder.md §Garanties/§Entrée (« l'allowlist ne te bride pas ») | medium | mitigate | La phrase ne libère que le chemin skill (`gsd-quick --validate`, pipeline GSD) ; le bullet « Voie unique » reste intact et T29-A/B (aucun dispatch direct d'agent nu) est rejoué en verify de T1. |
| T-SPAWN-02 | Repudiation | messages de commit et textes citant B1/B2 | medium | mitigate | Canal et date nommés partout, plus la mention « relayés par le mandat vf-dev-manager » : la provenance est dite, l'attribution n'est pas présentée comme vérifiée par l'exécuteur. |
| T-SPAWN-03 | Denial of Service | boucle manager → vf-coder à la même profondeur | medium | mitigate | T1-E interdit le redispatch au même niveau et impose la remontée ; T1-F le répète côté contrat. |
| T-SPAWN-04 | Tampering | gardes de test (T76, suites dev-orchestrator) | high | mitigate | Aucun fichier de test dans files_modified ; un rouge se corrige dans le texte ; réalignement de T76 renvoyé en F3 (commit séparé). |
| T-SPAWN-05 | Tampering | ratchet de budget d'instructions | medium | mitigate | Baselines et sentinelle interdites ; interdits de méthode 2-3 ; cible vf-coder ≤ 21 plus stricte que le gate (≤ 23) vérifiée par la colonne INSTR. |
| T-SPAWN-06 | Information Disclosure | note mémoire versionnée | low | mitigate | `check-machine-paths.sh` en verify de T3 ; le texte cible ne contient aucun chemin absolu. |
</threat_model>

<verification>
Après les 3 commits, depuis la racine du dépôt :

1. `bash plugin/conductor/scripts/check-instruction-budget.sh` → rc=0, « 0 depassement(s) », vf-coder.md INSTR ≤ 21, vf-dev-manager.md INSTR ≤ 46 et LIGNES ≤ 250.
2. `bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents` → rc=0.
3. `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` → 0 KO, total égal à la base (207 OK au plan).
4. `bash plugin/conductor/scripts/tests/test-check-agents.sh` → « 81 OK · 0 KO ».
5. `bash plugin/conductor/scripts/tests/test-check-overlaps.sh` → « 16 OK · 0 KO ».
6. `bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` → « 29 OK / 0 KO / 0 SKIP ».
7. `bash scripts/check-machine-paths.sh` → rc=0.
8. Périmètre : `git log --name-only` sur les 3 commits de la tâche ne montre QUE les 6 chemins de files_modified ; `git status --porcelain` (en `rtk proxy` si le proxy est actif) ne montre aucun fichier modifié hors `.planning/quick/260917-gyy-…/`.

Non-régression sur la découverte COMPLÈTE des suites (`find plugin scripts -path '*/tests/test-*.sh'`) : geste du manager dispatcheur, pas de cet exécuteur.
</verification>

<success_criteria>
- Les 7 truths de must_haves sont vraies, chacune adossée à une sonde de verify.
- vf-coder.md : 21 instructions au plus (138 lignes pré-mesurées) ; vf-dev-manager.md : 46 instructions au plus, 250 lignes au plus.
- Gate de budget rc=0 ; check-agents --strict vert ; les 4 suites au niveau de leur base.
- 3 commits atomiques en français, arbitrages cités avec canal et date, aucun fichier hors périmètre, aucun test ni baseline modifié.
- Les 8 findings `action: no-op` (re-vérifiés) figurent au SUMMARY et au bloc typé final.
</success_criteria>

<output>
Créer `.planning/quick/260917-gyy-hotfix-v2-63-2-doctrine-aligner-vf-coder/260917-gyy-SUMMARY.md` avec :
- mesures avant/après (lignes et INSTR des deux agents, sortie BILAN du gate) ;
- résultats de base et finaux des suites et gates de la section verification ;
- SHA des 3 commits et fichiers par commit ;
- provenance des arbitrages : « B1/B2, AskUserQuestion session principale, 2026-09-17, relayés par le mandat vf-dev-manager » ;
- la table findings_no_op re-vérifiée ;
- le bloc typé ADR-053 final : `{ "statut": "passed|gaps_found|human_needed|blocked", "findings": [ … F1-F8 en action "no-op" … ], "noeuds_debloques": [] }`, plus `preuves` selon `mission-contracts.md` §Contrat de preuves E6 (commandes canoniques rejouées, exit codes, SHA de HEAD au moment du verdict).
</output>
