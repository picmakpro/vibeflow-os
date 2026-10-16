# Phase 40: vibeflow-head — head of minds du dev-orchestrator - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

`vibeflow-dev` devient **`vibeflow-head`**, le head of minds du dev-orchestrator : un
renommage **et** une extension de rôle, **zéro agent neuf**, **kernel intact**. La phase livre :

1. **L'agent renommé** (`plugin/dev-orchestrator/AGENT.md`, `name: vibeflow-head`) avec son rôle
   de head : allocation du bon niveau d'équipe sur une échelle à sens unique, séquencement des
   missions selon la feuille de route, gouvernance de sortie sur témoin machine, économie.
2. **La référence de gouvernance** `plugin/dev-orchestrator/references/head-governance.md`
   (on-demand) qui porte la règle d'échelle, le séquencement, le contrat de sortie et l'économie
   — l'agent y **renvoie**, ne les recopie pas (ADR-029 ≤ 250 lignes, ADR-030 une seule voix).
3. **Le gate de sortie** `plugin/dev-orchestrator/scripts/check-mission-exit.sh` avec ses codes de
   sortie, sa suite de tests et sa mutation rouge prouvée (QUAL-01).
4. **Le contrat de preuves E6** dans le rapport de mission du manager (`mission-contracts.md`
   §Rapport de mission, `vf-dev-manager.md`) — **et ses émetteurs** : le manager ne peut relayer
   que ce qu'il reçoit (P3), donc le périmètre inclut aussi le câblage du champ `preuves` dans les
   trois workers qui rendent un verdict (`vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md`)
   — amendement D-19, lot `40-05`.
5. **Le renommage sans alias survivant** dans `plugin/` (hors CHANGELOG), les deux README, et un
   test qui **peut rendre rouge** si un alias `vibeflow-dev` réapparaît.

**Hors périmètre, explicitement** : head cross-métier au-dessus des cinq équipes (conductor) ;
verrou par workstream / un manager par compartiment (voie documentée comme extension, §6 de la
spec) ; renommage du module `dev-orchestrator` ou du skill `vf-dev` ; toute mesure Codex/Kimi
neuve ; toute modification de `team-kernel.md`, `driver-lock.sh`, `dag.sh`,
`guard-driver-lock.sh`, ADR-053, `SEUIL_EQUIPE`.

</domain>

<decisions>
## Implementation Decisions

**Seize arbitrages rendus par Samuel le 2026-09-15** (AskUserQuestion, session principale) : quatre
à la conception (spec d'entrée), douze au cadrage, en trois lots groupés par zone. Ils sont
**verrouillés** — ne pas les rouvrir.

### Conception (spec d'entrée, 2026-09-15)
- **D-01 — Périmètre : head dev, dans `dev-orchestrator`.** Pas de tier cross-métier dans le
  conductor. `vibeflow-design` reste un pair invocable. — **Reversibility:** reversible — un
  déplacement ultérieur vers le conductor est un geste de fichiers, la référence est écrite pour
  être déplaçable.
- **D-02 — Parallélisme inter-missions : sérialiser.** Un manager à la fois ; le parallélisme
  reste dans la frontière `ready` du manager. La voie workstreams (verrou par compartiment,
  amendement daté d'ADR-053, preuve d'usage concurrent réel) est **documentée comme extension**
  dans `head-governance.md`, jamais livrée ici. — **Reversibility:** reversible — aucun contrat
  distribué ne fige la sérialisation, c'est une conduite du head.
- **D-03 — Gate de sortie sur témoin machine, rejouer seulement l'absent.** Un vert du manager est
  accepté s'il porte une preuve machine ; le head ne rejoue qu'un gate dont la preuve manque,
  jamais un étage, jamais la revue.
- **D-04 — Nom : `vibeflow-head`.** Convention des front doors (`vibeflow-conductor`,
  `vibeflow-design`, `vibeflow-validator`). — **Reversibility:** costly — 20 fichiers dans
  `plugin/` + 2 README + gates (`check-overlaps.sh`, tests) portent le nom ; un second renommage
  rejoue toute la surface.

### Contrat de sortie — `check-mission-exit.sh` et preuves E6
- **D-05 — Preuves E6 en bloc typé dans le rapport compact.** Chaque verdict du rapport de mission
  (recette, revue, audit, gates techniques) porte `{commande, exit_code, sha}`. Un verdict sans
  commande rejouable (hook moteur GSD relayé verbatim) est marqué `preuve: amont` et **n'est jamais
  rejoué**. Le rapport détaillé sur disque reste inchangé. — **Reversibility:** costly — c'est un
  contrat de rapport entre `vf-dev-manager` et le head (`mission-contracts.md`), consommé par le
  gate ; le changer touche le manager, le gate et sa suite de tests.
- **D-06 — Contrôle sans source de vérité = indéterminé, mission non prouvée.** Pas de `gh`, pas
  de remote, lab racine non-git : le contrôle rend **4** et le verdict global est **4**. Le head
  n'annonce pas la mission verte et le dit au rapport. Rien n'est sauté en silence — même
  convention que `check-mission-invariants.sh`.
- **D-07 — Contrôles du gate** (repris de la spec §3.3, confirmés) : E1 verrou relâché
  (`driver-lock.sh status` → `present:false`) ; E2 arbre propre hors artefacts gitignorés
  (`git status --porcelain`, mesuré en `rtk proxy`) ; E3 branche dédiée ≠ défaut + PR ouverte
  (ADR-059) ; E4 STATE/ROADMAP marqués pour les étapes de la mission ; E5 rapport détaillé présent
  sur disque ; E6 chaque verdict porte sa preuve. Codes : **3 sain** (seul « vérifié, conforme »),
  **0 manque(s) nommé(s)**, **4 indéterminé**, **64 outillage illisible**. Le script naît avec sa
  suite de tests et sa **mutation rouge prouvée** (QUAL-01).
- **D-08 — Portée : missions d'équipe seulement.** Le gate ne tourne qu'après un manager — le lock
  et le rapport typé sont ses sources. `gsd-execute-phase` direct et `gsd-quick` gardent leurs
  vérifications GSD propres (gates techniques, `gsd-verify-work`). Pas de mode dégradé du script.

### Conduite du head
- **D-09 — Déclenchement d'un manager (ex-H-01) : propose en conversation, lance d'office sous
  `vf-auto`.** Sur signal mission le head propose `Task(manager)` et attend le feu vert ; sous
  `vf-auto` ou signal de durée explicite il dispatche sans redemander. Heuristique 7 conservée,
  ADR-031 intact.
- **D-10 — Exécutant du gate : le head lui-même.** `check-mission-exit.sh` et un gate rejoué sont
  lancés par le head via Bash — une lecture, pas une production (P3 respecté). Aucun juge
  dispatché pour ça.
- **D-11 — Lock encore tenu après le rapport (E1 rouge) : mandat de clôture au manager, puis
  `human_needed`.** Le head **ne relâche ni ne reprend jamais** un lock : il renvoie un mandat de
  clôture ciblée (`release`) ; si le lock reste tenu ou périmé, il remonte à l'humain avec la
  commande `takeover` à jouer. Le release reste le geste du tenant.
- **D-12 — Gate rejoué = la commande exacte que le verdict devait porter.** Le contrat E6 nomme,
  par type de verdict, la **commande canonique** (suite de tests du module, `check-agents.sh
  --strict`, etc.). Le head rejoue celle-là, **jamais une liste locale** ni le job `gates` complet
  de `ci.yml` (leçon « liste de gates ≠ référence »).

### Économie
- **D-13 — Décompte de coût dans le rapport de mission existant.** Trois lignes ajoutées au
  gabarit (`mission-contracts.md` §Rapport de mission) et au rapport compact : minds dispatchés,
  tours consommés, gates rejoués. **Aucun fichier neuf**, aucune statistique agrégée — relayé,
  jamais recalculé (même règle que `estimate`/`actuals`).
- **D-14 — Preuves manquantes : 1 → rejouer ; ≥ 2 → source fautive, mandat de clôture.** Un seul
  gate sans preuve se rejoue (D-12). Deux ou plus signalent que le manager n'a pas appliqué le
  contrat E6 : le head renvoie un mandat de clôture ciblée (compléter les preuves) et **consigne
  la source à amender** (G5 du kernel : édition-à-la-source, bornée par ADR-031 — consignée, jamais
  amendée en silence en autonome). Jamais une rafale de re-jeux.
- **D-15 — Trois règles d'économie** (spec §3.4, confirmées) : ne jamais relire ce que le digest
  porte ; ne jamais rejuger un diff sans nouveau commit (un `revue-N` PASS sur SHA `x` vaut tant
  que HEAD de la branche est `x`) ; relayer verbatim, jamais recalculer. Bornes dures inchangées :
  `autonomous-guardrails.md`.

### Livraison
- **D-16 — Une seule PR, une release minor, après la Phase 34 (ex-H-02).** Renommage +
  `head-governance.md` + gate de sortie dans une PR ; bump **minor** du module `dev-orchestrator`
  et de la racine ; tag + release GitHub + `check-release-tag.sh --remote` ✓. La Phase 25 se
  calibre ensuite sur le corpus **post-40** (dépendance amendée au ROADMAP le 2026-09-15).
  — **Reversibility:** one-way — une release taggée ne se retire pas ; un rollback est une
  release suivante.
- **D-17 — Le skill `vf-dev` garde son nom** et incarne `vibeflow-head`. Le nom du skill décrit le
  métier, pas le rôle de l'agent ; aucune commande utilisateur ne casse ; seule la cible
  d'incarnation change (test `test-dev-orchestrator.sh:1297-1298` à aligner). **Pas d'alias
  `vf-head`** — couche de synonymes interdite depuis v2.33.0.
- **D-18 — Multi-runtime : livré par construction, sans mesure neuve.** Le nom voyage via
  l'installeur `--target` (Phase 38), `check-mission-exit.sh` est du shell portable (mêmes
  contraintes que les scripts conductor : `bash`, `jq` pour lire `driver-lock.sh status`). Aucune
  mesure Codex/Kimi ajoutée ; la marge non constatée de la 38 (aller-retour manager→worker sur
  Codex) reste ce qu'elle est, documentée, pas revendiquée.

### Amendement post-cadrage (2026-09-15, plan-check du lot L2)
- **D-19 — Un cinquième lot, `40-05` `exec-workers`, câble les ÉMETTEURS du contrat E6.** Le
  cadrage initial (§Phase Boundary) énumérait « le manager, le gate et sa suite de tests » comme
  périmètre du contrat de preuves — c'était incomplet, et ce périmètre le dit maintenant
  explicitement. Constat qui a déclenché l'amendement : `grep -ic exit_code` rend **0** sur
  `vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md` **et** `vf-dev-manager.md` — aucun émetteur
  n'existait avant `40-02`, et `40-02` lui-même ne pose que le CONTRAT (le format, dans
  `mission-contracts.md`), pas son câblage dans les trois workers. Le manager ne peut pas
  fabriquer une preuve qu'il n'a jamais reçue (P3 du kernel : un manager ne produit jamais, il
  relaie) — livré tel quel, `check-mission-exit.sh` (lot L3) aurait reçu un contrat
  structurellement vide et aurait rendu **indéterminé** sur toute mission, jamais conforme.
  Décision de Samuel (AskUserQuestion session principale, 2026-09-15) : **option (b)** — un lot
  dédié `40-05` `exec-workers`, `wave: 3`, `depends_on: ["40-02"]` (le contrat doit exister avant
  qu'on l'émette), en parallèle du lot `40-04` `exec-gate` (périmètres de fichiers disjoints :
  `40-05` ne touche à aucun fichier de `40-04`, et réciproquement). `40-05` câble `preuves` dans
  `vf-coder.md` (verdict `recette`, marqué `preuve: amont` par défaut — hérité d'un hook moteur
  GSD non rejouable, D-05), `vf-reviewer.md` (verdict `revue`) et `vf-auditer.md` (verdict
  `audit`), **au format exactement défini par `40-02`**, sans en réinventer un second (ADR-030).
  Zéro agent neuf (D-04 reste tenu — ce sont les trois workers existants qui sont amendés), kernel
  intact. — **Reversibility:** reversible — un émetteur qui manque encore après `40-05` se rattrape
  par un mandat de correction ciblée, sans toucher au contrat lui-même.

### Claude's Discretion
- **Famille d'exigences** : `HEAD-01` (échelle d'allocation), `HEAD-02` (gate de sortie),
  `HEAD-03` (économie), `HEAD-04` (renommage sans alias) — préfixe vérifié libre au ledger le
  2026-09-15 ; à ledgeriser au plan avec la table de traçabilité `HEAD-xx → Phase 40`.
  QUAL-01 s'applique de plein droit (un gate naît).
- **Forme du test anti-alias** : grep récursif sur `plugin/` excluant `CHANGELOG.md`, dans
  `test-dev-orchestrator.sh` (module propriétaire du nom) — et mutation rouge (réinjecter un alias,
  vérifier l'échec). Les six specs historiques sous `docs/superpowers/specs/` et `docs/ADR.md`
  sont des **archives datées** : non réécrites, hors périmètre du test.
- **Découpage de l'AGENT.md** : quelles lignes migrent vers `head-governance.md` pour tenir
  ≤ 250 lignes après ajout de la section « Gouvernance de sortie » (renvoi) — candidat naturel :
  la table « Carte d'intention » raccourcie au profit d'`intent-routing.md`, déjà source unique.
- **Ordre des lots dans le plan** : renommage (mécanique, vérifiable par le test anti-alias) puis
  contrat E6 côté manager, puis gate (qui consomme E6), puis référence + AGENT.md — ou l'inverse
  si le planner préfère poser la doctrine d'abord ; les quatre lots ont des périmètres de fichiers
  disjoints sauf `vf-dev-manager.md` (E6) et `mission-contracts.md` (E6 + décompte).
- **Note pour la Phase 34** (hors périmètre, à porter, pas à faire ici) : le livrable AGTS-01
  écrit la phrase complète du Pitfall 12 — « plus de 2-3 agents **ajoutés au catalogue** dans une
  PR » — et nomme que le fan-out d'exécution n'est borné que par la disjonction des périmètres et
  le budget. Précision de rédaction dans la marge « Claude's Discretion » de la 34, **pas** une
  révision de D-03 de la 34.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spec d'entrée et décisions
- `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` — la conception complète : diagnostic,
  4 compétences (§3), surface de changement fichier par fichier (§4), contraintes (§5), voie
  workstreams écartée et ce qu'elle exigerait (§6), lecture du Pitfall 12 (§7).
- `.planning/ROADMAP.md` § `### Phase 40` — Goal, Depends on (Phase 34), 5 Success Criteria ; et
  § `### Phase 25` — dépendance amendée « Phase 34 **et Phase 40** ».
- `.planning/STATE.md` § `### Roadmap Evolution` — entrée du 2026-09-15 (inscription, arbitrages,
  deux évaluations : workstreams, Pitfall 12).

### L'agent et le module à transformer
- `plugin/dev-orchestrator/AGENT.md` — l'agent actuel (205 lignes) : persona, garde-fou first-use,
  carte d'intention raccourcie, heuristiques 1-7, Iron Laws, anti-patterns, références D7.
- `plugin/dev-orchestrator/references/intent-routing.md` — **source unique** de la correspondance
  intention → brique ; le head ne la duplique pas, il y ajoute la règle d'échelle dans sa
  propre référence.
- `plugin/dev-orchestrator/references/mission-contracts.md` §Rapport de mission (l.300),
  §Signaux « mission » (l.315), §Seuil de bascule `SEUIL_EQUIPE = 3` (l.326), §Contrat
  `estimate:`/`actuals:` (l.151) — le rapport à enrichir (E6, décompte) et le seuil **inchangé**.
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — §Rapport de mission (« Dispatché par l'agent
  vibeflow-dev » à renommer ; bloc typé à enrichir des preuves E6 ; release du lock = dernière
  action avant le rapport, D-11 s'y adosse).
- `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` et `skills/vf-auto/SKILL.md` — cible
  d'incarnation (D-17) ; l'aiguillage seuil de `vf-auto` cite la règle d'échelle de
  `head-governance.md` au lieu de la dupliquer.
- `plugin/dev-orchestrator/module.json`, `README.md`, `CHANGELOG.md`, `VERSION` — description,
  bump minor (D-16).

### Le kernel (à lire, à NE PAS modifier)
- `plugin/conductor/references/team-kernel.md` — §Règles d'instanciation (P3 un manager ne produit
  jamais ; dispatch parallèle par défaut ; **édition-à-la-source G5** ; « un garde ne se desserre
  jamais dans le commit qu'il autorise ») ; §Étage de parallélisme réellement effectif (frontière
  `ready` = seul parallélisme mesuré) ; §Étages croisés (verrou de driver = seul garant machine
  de « un seul manager »).
- `plugin/dev-orchestrator/references/mission-flow.md` — §Résolution des scripts `$S`
  (scope-robuste, à réutiliser par le gate) ; §Pattern A (lock) ; §Pattern C table de pilotage
  (foyer unique des 4 verdicts, `human_needed`) ; §Pattern G (réveiller avant de redispatcher).
- `plugin/conductor/scripts/driver-lock.sh` — `status` rend un JSON avec `present` et
  `generation` (lire par `jq`, jamais par découpage de texte) ; `LOCK_DIR` relatif au checkout
  (`.planning/DRIVER.lock`, gitignoré) ; `takeover`/`reclaim` = gestes du tenant ou de l'humain.
- `plugin/conductor/scripts/check-mission-invariants.sh` — **modèle des codes de sortie** du gate
  (3 sain / 0 / 4 indéterminé / 64) et de la conduite par code (`vf-dev-manager.md` §Discipline
  de pilotage, point 4).
- `plugin/dev-orchestrator/references/autonomous-guardrails.md` — les plafonds (temps, tokens,
  3 essais, anti-triche) : bornes dures de l'économie, inchangées.
- `plugin/dev-orchestrator/references/workstreams.md` §5 La condition dure ; `docs/ADR.md`
  §ADR-069 ; `.planning/phases/VFDO-39-*/39-CONTEXT.md` D-01/D-02/D-10 — pourquoi la voie
  workstreams n'est pas livrée (D-02), à citer dans `head-governance.md`.

### Doctrine et gates transverses
- `docs/ADR.md` §ADR-029 (densité ≤ 250 lignes), §ADR-030 (une seule voix), §ADR-031 (jamais de
  fix sans validation humaine), §ADR-044 (`check-agents.sh --strict`), §ADR-045 (recherche doc
  avant debug — le head porte la recherche, les workers n'ont pas le web), §ADR-053 (lock + DAG +
  rapports typés — **intact**), §ADR-057 (une seule front door : `check-overlaps.sh` ligne
  `vibeflow-dev|gsd-next` à renommer), §ADR-059 (branche dédiée + PR — source d'E3).
- `plugin/conductor/scripts/check-overlaps.sh` l.67 et `tests/test-check-overlaps.sh` l.186-203 —
  la ligne de frontière et ses tests, à renommer ensemble.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` l.1297-1298 — test
  d'incarnation (`vibeflow-dev|vf-dev-manager` → `vibeflow-head|vf-dev-manager`) ; hôte naturel du
  test anti-alias.
- `plugin/_internal/vibeflow-update.sh` l.2233-2237 — l'engine pose `AGENT.md` sous
  `$TARGET_ROOT/agents/<module>.md` : le fichier installé reste `dev-orchestrator.md`, seul le
  `name:` du frontmatter change. **Aucun changement d'engine.**
- `.planning/REQUIREMENTS.md` l.900-915 — règle de preuve du milestone et QUAL-01 transverse
  (« un gate naît avec ses trois issues et sa mutation rouge prouvée »).
- `.planning/research/PITFALLS.md` §Pitfall 12 (l.377-408) — verbatim « une PR **ajoutant** plus
  de 2-3 agents d'un coup » : catalogue, pas runtime.
- `.planning/phases/VFDO-34-*/34-CONTEXT.md` D-03 — la phrase à préciser dans le livrable AGTS-01
  (note hors périmètre, §Claude's Discretion).

### Autres citations du nom (surface de renommage, mesurée le 2026-09-15)
- `plugin/dev-orchestrator/references/GSD-PIPELINE.md`, `_index.md`, `docs-flow.md`,
  `ingestion-flow.md` ; `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` l.6 ;
  `plugin/design-orchestrator/AGENT.md` l.3 ; `plugin/planning-core/SKILL.md` l.3, l.81 ;
  `plugin/commands/vf-planning.md` l.15, l.18 ;
  `plugin/software-architecture/rules/doc-research-before-debug.md` l.24, l.88 ; `README.md`,
  `README.fr.md`. Les CHANGELOG et `docs/superpowers/specs/*` antérieurs sont des archives :
  non réécrits.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Cascade `$S`** (`mission-flow.md` §Résolution) : `./.claude/scripts` → `$HOME/.claude/scripts`
  → `${CLAUDE_PLUGIN_ROOT}/conductor/scripts` → `…/dev-orchestrator/scripts` — le gate se résout
  par la même cascade, jamais par un chemin en dur.
- **`driver-lock.sh status`** : JSON une ligne (`present`, `generation`) — source d'E1.
- **`check-mission-invariants.sh`** : convention de codes 3/0/4/64 et style de message
  `[nom-du-gate]` — modèle direct du gate de sortie.
- **Bloc typé Pattern C** `{statut, findings[{severity, action, ref}], noeuds_debloques}` : le
  bloc E6 s'y ajoute par verdict, il ne crée pas un second format.
- **Suites de tests des modules** (`plugin/*/scripts/tests/test-*.sh`, découvertes par la CI) :
  gabarit pour `test-check-mission-exit.sh` et pour le test anti-alias, mutants inclus.
- **`bump.sh`** pour la racine, bump de module à la main ; `scripts/check-release-tag.sh --remote`.

### Established Patterns
- **Renvoi, pas copie** (ADR-030) : l'agent renvoie à `head-governance.md` comme `vf-dev-manager`
  renvoie à `mission-flow.md` §Pattern C — jamais de reformulation locale.
- **Un garde ne se desserre jamais dans le commit qu'il autorise** (Phase 38) : si un lot bute sur
  un test existant (incarnation, overlaps), il pose le besoin, jamais ne modifie le garde dans le
  même commit.
- **Une preuve doit pouvoir rendre rouge** (Phase 39) : mutation prouvée pour le gate ET pour le
  test anti-alias.
- **Commit discipliné à index partagé** (`team-kernel.md` Phase 27) : `git commit <chemin> -m` —
  si la phase est exécutée en mission d'équipe, chaque lot nomme ses fichiers.
- **Traçabilité des arbitrages** dans les commits : « arbitrage Samuel, AskUserQuestion session
  principale, 2026-09-15 ».

### Integration Points
- `vf-dev-manager.md` §Rapport de mission ↔ `mission-contracts.md` §Rapport de mission ↔
  `check-mission-exit.sh` E6 : **un seul contrat**, trois consommateurs.
- `AGENT.md` heuristique 7 ↔ `vf-auto` §Étape 0 ↔ `head-governance.md` §Règle d'échelle : la
  règle vit dans la référence, les deux autres la citent.
- `check-overlaps.sh` ↔ `test-check-overlaps.sh` : renommer les deux dans le même lot.
- CI : job `gates` (rejouer les commandes de `ci.yml`, jamais une liste) — la nouvelle suite est
  découverte automatiquement (compteur de suites des README à re-dériver, jamais recopié).

</code_context>

<specifics>
## Specific Ideas

- Verbatim Samuel (demande initiale, 2026-09-15) : le head « lance les managers sur les choses à
  faire, a des compétences qui lui permettent de connaître ce qui peut être parallélisé ou non,
  utilise des managers aux bons moments ou juste des quick, fix, debug, manager design ou TOUT
  autre agent spécialisé de VF. Il a la charge de la bonne tenue du repo […] sans over-check si
  les managers l'ont déjà fait. Il a quand même une idée d'économie dans sa réflexion et ne va
  pas refaire ce que ses équipes ont déjà fait. »
- Verbatim Samuel (cadrage) sur le fan-out : « + de 3 agents peuvent se lancer et très bien
  gérer. Même beaucoup plus en soi si c'est correctement orchestré. » — porté dans
  `head-governance.md` §Séquencement : le fan-out n'est borné par aucun nombre.
- Principe directeur du gate : **« vérifier le témoin, pas refaire le travail »**.

</specifics>

<deferred>
## Deferred Ideas

- **Head cross-métier dans le conductor** (au-dessus de dev, design, contenu, growth, business) —
  écarté au cadrage (D-01) ; `head-governance.md` est écrit pour être déplaçable.
- **Un manager par workstream** (verrou nommé par compartiment, amendement d'ADR-053, guard aligné,
  `--ws` + `GSD_SESSION_KEY` par manager, preuve d'usage concurrent réel) — phase à part entière,
  déclencheur : **partition effective d'un lab** (elle-même gatée humain, D-02 de la 39).
- **Mesure d'incarnation de `vibeflow-head` sur Codex** — écartée (D-18) ; quota ChatGPT
  indisponible jusqu'au 2026-09-27.
- **Registre de coût inter-missions** (`COST-LEDGER.md`) — écarté (D-13) ; à rouvrir seulement si
  une comparaison entre missions devient un besoin prouvé (règle de preuve du milestone).
- **Précision de rédaction du Pitfall 12 dans AGTS-01** — appartient à la Phase 34, notée ici pour
  ne pas se perdre (§Claude's Discretion).

</deferred>

---

*Phase: 40-vibeflow-head-head-of-minds-du-dev-orchestrator*
*Context gathered: 2026-09-15*
