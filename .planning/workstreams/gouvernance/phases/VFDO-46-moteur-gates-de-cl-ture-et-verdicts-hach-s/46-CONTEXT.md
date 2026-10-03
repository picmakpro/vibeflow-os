# Phase 46: Moteur — gates de clôture et verdicts hachés - Context

**Gathered:** 2026-10-03
**Status:** Ready for planning
**Compartiment :** `gouvernance` — toute commande GSD de cette phase passe `--ws gouvernance` ;
`gsd-tools` s'appelle par `node ~/.claude/gsd-core/bin/gsd-tools.cjs` (1.14.0).
**Décisions humaines :** Q1 à Q8 tranchées par Willy, AskUserQuestion session principale,
2026-10-03, relayées par la session principale au manager de mission (repli D-09, pas d'outil de
question en sous-agent). Willy a suivi la recommandation du manager sur les huit questions (Q7 :
option (b)). Elles deviennent P46-D-01 à P46-D-08.
**Décisions du manager :** marquées « manager », annoncées à Willy avant l'écriture de ce fichier
(liste relayée par la session principale le 2026-10-03, « renversables »), et dérivées ici en
P46-D-09 à P46-D-19. Les sous-décisions `a`/`b` des décisions humaines sont aussi du manager.
**Faits de départ :** `46-RECHERCHE-HOOKS.md` (doc des hooks, Claude Code 2.1.288, ADR-045) et
`46-SCOUTING.md` (acquis des Phases 44 et 45, chemin:ligne). Le planificateur les lit avant tout.

<domain>
## Phase Boundary

La phase livre, dans `plugin/planning-core/`, **les gates de clôture du moteur** et ce qu'il faut
pour les croire :

1. **G3** : pas de marqueur de clôture (`CLOTURE.md`) quand un livrable déclaré est absent ou vide.
2. **G4** : pas de `SUMMARY.md` quand le verdict manque, est invalide, porte un constat en échec,
   ou ne correspond plus au plan ni aux livrables (verdict périmé).
3. **Deux empreintes dans `VERDICT.md`** (plan + livrables), un **plafond de tentatives**, et
   leur vérification à la clôture et au recalcul.
4. **Un neuvième état dérivé, `à clore`.**
5. **G4′** : pas de rapport de worker ou de producteur sans sortie de commande brute.
6. **D1** : toute écriture sur un fichier surveillé d'un lab adhérent est soit expliquée, soit
   tracée — en séance par `FileChanged`, entre les séances par une réconciliation par hash.
7. **Le canary de juge (C-16)** : contrat de la sortie piégée, vérificateur déterministe, signal
   « juge sans preuve ».

Chaque gate déclare son comportement fail-closed, se prouve en vie par un canary, mesure ses faux
refus dans les deux sens, et s'arme dans l'ordre (P46-D-11), comme en 45.

**Hors de cette phase :**
- `TaskCompleted` : non utilisé (P46-D-01). G2′ et les baux : Phase 47, qui re-décide son point
  d'accroche à la lumière de P46-D-01.
- Le dispatch automatique du juge sur sa sortie piégée : Phase 48 (orchestrateur générique). La
  fabrication des sorties piégées : Phase 50.
- Le seuil de juge dans `config.json` (spec §10) : Phase 50 (P46-D-13).
- Le retrait du socle v2 (`guard-planning-updated.sh`) : non retiré (P45-D-19 tient).
- Toute release : aucune avant la clôture de `fiabilite-v1.0` (garde-fou du jalon).

</domain>

<decisions>
## Implementation Decisions

### Point d'accroche de G3 et G4 (Q1)

- **P46-D-01 :** G3 et G4 sont portés par le **hook central de la 45, en `PreToolUse`**, refus par
  `permissionDecision: "deny"` (P45-D-08 inchangé). **G3** refuse l'écriture par outil
  (`Write|Edit|NotebookEdit`) d'un `CLOTURE.md` d'unité quand un livrable déclaré par `ecrit:` du
  `PLAN.md` voisin est absent ou vide (P46-D-12). **G4** refuse l'écriture par outil d'un
  `SUMMARY.md` d'unité quand le `VERDICT.md` voisin est absent, invalide (R6), porte au moins un
  constat `échec`, ou quand l'une de ses deux empreintes ne correspond plus (P46-D-03). Le
  prédicat est réévalué à chaque écriture : retoucher un `SUMMARY.md` d'une unité close reste
  permis tant que le verdict tient. **`TaskCompleted` n'est pas utilisé** : il n'existe pas par
  défaut sur les modèles récents (46-RECHERCHE-HOOKS §0), ne refuse que par exit 2 et ne porte pas
  le lien vers le plan. La **table §5 de la spec moteur est amendée** (P46-D-18). Les écritures
  par Bash restent ouvertes (limite (g)) ; le recalcul les voit déjà (R4, R7) et D1 les trace. —
  Willy, AskUserQuestion session principale, 2026-10-03 (Q1 = a). **Reversibility:** costly
  (contrat de clôture des labs).

### G4′ — rapport de sous-agent sans sortie brute (Q2)

- **P46-D-02 :** G4′ est porté par **`PreToolUse` sur `SubagentHandback`** (le rapport est dans
  `tool_input.message` depuis 2.1.271), refus par deny. **Repli hors mode auto** : `SubagentStop`,
  refus par `{"decision":"block","reason":…}` (plafond natif de 8 relances). **Périmètre** : les
  sous-agents de rôle **worker** ou **producteur** d'un lab adhérent, rôle dérivé comme en 45
  (P45-D-05, I5/I6, `vf-internal`). **Exclus** : les juges (trois sur quatre n'ont pas Bash), le
  fil principal, l'agent inconnu, et les `agent_type` vides (agents internes du harnais). Coût hors
  adhésion : celui du pré-filtre, **mesuré** (P46-D-16). — Willy, AskUserQuestion session
  principale, 2026-10-03 (Q2 = a).
- **P46-D-02a (manager) :** « sortie de commande brute » = prédicat **structurel et
  déterministe** : le rapport contient au moins un bloc de code délimité dont la première ligne non
  vide est une ligne de commande (`$ <commande>`) suivie d'au moins une ligne non vide de sortie.
  Il « bloque le silence, pas la falsification » (spec §5) : une sortie inventée passe, limite
  déclarée. La grammaire exacte est écrite dans `modele-cycles.md` et prouvée par jumeaux négatifs
  ; le planificateur peut l'affiner sans la rendre plus permissive.

### Empreintes du verdict (Q3)

- **P46-D-03 :** `VERDICT.md` porte **deux empreintes** : `hash` (sha256 du `PLAN.md`, A3,
  conservé) et un nouveau champ d'empreinte **composée des livrables `ecrit:`**. `poser-verdict.sh`
  calcule les deux à la pose ; **G4 les vérifie toutes deux** à l'écriture de `SUMMARY.md` ; un
  écart refuse avec « verdict périmé : re-juger (tentative n+1) ». Il n'y a aucun `VERDICT.md` sur
  les labs réels (spec §11.3) : le changement de format ne migre rien. — Willy, AskUserQuestion
  session principale, 2026-10-03 (Q3 = a). **Reversibility:** costly (format sur disque).
- **P46-D-03a (manager) :** composition de l'empreinte des livrables, **une seule implémentation**
  partagée par `poser-verdict.sh`, le hook et `recalc-planning.sh` (preuve croisée par test) :
  entrées de `ecrit:` normalisées et triées ; pour un fichier, chemin relatif + sha256 du contenu ;
  pour un dossier, la liste triée de ses fichiers réguliers (chemin relatif + sha256) ; **aucun lien
  suivi** ; parcours **borné** (nombre de fichiers et octets) : un dépassement est un refus explicite,
  jamais une empreinte partielle. Les bornes sont au planificateur, mesurées.
- **P46-D-03b (manager) :** le **recalcul vérifie aussi** les deux empreintes : écart avant
  `SUMMARY.md` → `à juger` (motif `verdict-perime`) ; écart avec `SUMMARY.md` présent →
  `indéterminé` (motif `livrable-modifie-apres-cloture`). Un `VERDICT.md` sans l'empreinte des
  livrables est traité comme périmé.

### État « à clore » (Q4)

- **P46-D-04 :** un **neuvième état dérivé, `à clore`** : constats tous `passé`, empreintes
  conformes, `SUMMARY.md` absent. **Non terminal.** Il remplace `indéterminé`
  (`verdict-passe-sans-SUMMARY.md`) pour ce cas précis : P44-D-08 est levée sur ce point. La spec
  §3.1 est amendée (« neuf états dérivés », P46-D-18). — Willy, AskUserQuestion session principale,
  2026-10-03 (Q4 = a).

### Plafond de tentatives (Q5)

- **P46-D-05 :** **plafond de 3 tentatives**, constante dans le code livré (jamais dans un fichier
  du lab). `poser-verdict.sh` refuse une tentative au-delà de 3, avec un message distinct, **sauf
  dérogation nominative** couvrant l'unité (journal de la 45, P45-D-13). Le budget de tours vit
  sur le disque et survit à un compact (spec §10). — Willy, AskUserQuestion session principale,
  2026-10-03 (Q5 = a).

### Canary de juge, C-16 (Q6)

- **P46-D-06 :** la 46 livre **le contrat et le vérificateur**, pas le dispatch : (1) format et
  emplacement d'une sortie piégée par juge, avec le critère qu'elle viole ; (2) un vérificateur
  **déterministe** : le verdict posé sur la sortie piégée doit porter le critère visé en `échec`,
  sinon le juge est **signalé** (juge laxiste) ; (3) un juge du lab **sans** sortie piégée ou sans
  verdict de canary est signalé **« juge sans preuve »**, jamais vert ; (4) le premier passage du
  juge sur sa sortie piégée est une **étape écrite du premier cycle**, portée par le manager
  jusqu'à ce que l'orchestrateur générique de la Phase 48 l'automatise ; (5) fixtures de test
  (sortie piégée, juge prouvé, juge laxiste, juge sans preuve). Le signal sort au `SessionStart`
  d'un lab adhérent, sans bloquer. — Willy, AskUserQuestion session principale, 2026-10-03
  (Q6 = a).
- **P46-D-06a (manager) :** la sortie piégée et le verdict de canary vivent **sous `.planning/` du
  lab** (un dossier par juge) : le verdict de canary est posé par `poser-verdict.sh` et protégé
  par G5 comme tout verdict. Noms exacts au planificateur.

### D1 — détection des écritures (Q7)

- **P46-D-07 :** D1 = **`FileChanged` + réconciliation par hash au `SessionStart`**. En séance :
  le `SessionStart` et le `CwdChanged` d'un lab adhérent renvoient des `watchPaths` absolus,
  **fichier par fichier** (jamais un dossier, #91634), bornés en nombre ; hors adhésion, rien
  n'est renvoyé et le watcher ne démarre pas (coût nul). Entre les séances : au `SessionStart`, les
  empreintes des fichiers surveillés sont comparées au dernier état connu. Les écritures du moteur
  (commandes et écritures par outil laissées passer par le hook) sont **journalisées** ; un
  changement que rien n'explique est **tracé comme contournement** et signalé. D1 ne refuse
  jamais. — Willy, AskUserQuestion session principale, 2026-10-03 (Q7 = b).
- **P46-D-07a (manager) :** liste surveillée minimale : `STATE.md`, `INDEX.md`, `cloture.log`, le
  journal de dérogation, `config.json` du lab, et les `PLAN.md`, `CLOTURE.md`, `VERDICT.md`,
  `SUMMARY.md` des unités non closes. Les journaux de D1 sont append-only et protégés par G6.
  Limites déclarées : #95440 (sourd après un `cd`, rattrapé par la réconciliation), pas d'auteur
  dans le payload, `watchPaths` remplace la liste dynamique (un autre hook qui en renvoie la
  remplace aussi).

### Sonde non jouée (Q8)

- **P46-D-08 :** aucune sonde en direct : la garde d'isolation du worktree a refusé `claude -p`
  (non contourné). La 46 s'appuie sur la documentation et sur ses canaries ; les points non
  mesurés deviennent des **limites déclarées** dans `modele-cycles.md` : déclenchement de
  `FileChanged` sous `settings.json` en 2.1.288 (sa défaillance est rattrapée par la
  réconciliation), actualité de #95440, et #60490 (rendu sans objet par P46-D-10 : aucun exit 2).
  Les deux points sur `TaskCompleted` sont sans objet (P46-D-01). — Willy, AskUserQuestion session
  principale, 2026-10-03 (Q8 = a).

### Décisions du manager (renversables par Willy)

- **P46-D-09 :** **un seul script, un mode par événement** (prolonge P45-D-15). Le hook central lit
  `hook_event_name` et traite `PreToolUse` (G1…G7, rôle, G3, G4, G4′), `SubagentStop` (repli G4′),
  `SessionStart`/`CwdChanged` (`watchPaths` et réconciliation de D1) et `FileChanged` (trace de
  D1). La commande enregistrée reste la seule porte d'entrée, avec son pré-filtre et son repli
  shell, déclinés par événement.
- **P46-D-10 :** **contrat de sortie par événement.** `PreToolUse` : deny JSON, exit 0 (P45-D-08).
  `SubagentStop` : `decision: "block"` JSON, exit 0, **jamais exit 2**. `SessionStart`,
  `CwdChanged`, `FileChanged` : ne refusent jamais. Aucun message ne contient de chemin absolu hors
  du lab, ni les chaînes `no such file` / `can't open` (#60490). **Fail-closed** dans le périmètre
  adhérent pour G3, G4 (empreintes comprises) et G4′ (erreur interne → refus) ; en mode dégradé
  (script ou `python3` absent), le repli refuse aussi `SubagentHandback`, sans dériver le rôle.
  **Fail-open** déclaré pour D1 : une trace perdue en séance est rattrapée par la réconciliation.
- **P46-D-11 :** **ordre d'armement prolongé** après la 45 : (G3 + G4, empreintes comprises) →
  G4′. Chaque étape exige le canary vert et **0 faux refus / 0 faux accept**, sur le banc en CI
  puis sur le rejeu en lecture seule (protocole P45-D-03, P45-D-03b, P45-D-21). Constantes
  d'armement dans le code livré (P45-D-03a), `ORDRE_ETAPES` étendu. **D1 n'est jamais armé** :
  c'est une détection, qui a pourtant son canary (rejeu d'un payload synthétique, trace exigée).
- **P46-D-12 :** **« vide »** : fichier régulier de 0 octet, ou dossier sans aucun fichier régulier
  non vide (parcours borné). **Un lien n'est jamais suivi** : un livrable déclaré qui est un lien
  compte comme absent. Un seul prédicat « livrable présent », partagé par G3 et par R4 du recalcul
  (qui passe de « absent » à « absent ou vide »), preuve croisée par test.
- **P46-D-13 :** le **seuil de juge dans `config.json`** (spec §10) est **hors périmètre**, renvoyé
  à la Phase 50 : le score n'est pas bloquant (D-02 amendée) et les seuils vivent aujourd'hui dans
  les prompts des juges.
- **P46-D-14 :** `planning-core` reçoit un **bump mineur** (v2.9.0 → v2.10.0), **sans release**.
- **P46-D-15 :** famille d'exigences **`CLOT`**, vérifiée libre le 2026-10-03 (`git grep -E
  '\b(CLOT|VERD|CLOS)-[0-9]{2}\b'` sur tout le dépôt : 0 correspondance, rc=1).
- **P46-D-16 :** **zéro régression sur les labs dev et coût hors adhésion mesuré.** Sur un lab dev
  fixture et sur ce dépôt, chaque nouvel événement et chaque nouveau matcher rendent un octet vide et
  0 ; la mutation « ignorer l'adhésion » rend la preuve rouge (prolonge GATE-10). Le coût du
  pré-filtre sur `SubagentHandback`, `SubagentStop`, `SessionStart`/`CwdChanged` est mesuré au
  protocole des quick 261002-brz et 261003-1le (médianes, rejeux) et écrit dans
  `modele-cycles.md` ; `FileChanged` hors adhésion : nul par construction (aucun `watchPaths`),
  prouvé par un test.
- **P46-D-17 :** **marqueur `Gate-Touche:`** sur tout commit qui touche le hook, sa commande
  enregistrée ou une suite de gate (discipline de la 45, hors surface de `check-gate-touche.sh`).
  `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire `n==33`) et `scripts/tests/test-hook-exit-parc.sh`
  suivent le nouveau parc de hooks.
- **P46-D-18 :** **amendements de spec** portés par la 46, datés et attribués comme P45-D-14a :
  table §5 (G3/G4 en `PreToolUse` sur `CLOTURE.md`/`SUMMARY.md`, G4′ en
  `PreToolUse(SubagentHandback)` + repli `SubagentStop`), §5.1-1 (contrat par événement,
  P46-D-10), §3.1 (neuf états, `à clore`), §10 (deux empreintes, plafond de 3).
- **P46-D-19 :** la **ROADMAP de la Phase 47** reçoit une note : G2′ « se branche sur le même
  `TaskCompleted` que G3/G4 » n'est plus vrai ; son point d'accroche se re-décide au cadrage de la
  47, à la lumière de P46-D-01.

### Claude's Discretion

Laissés au planificateur :
- noms des fichiers, champs et commandes nouveaux (empreinte des livrables, dossier des sorties
  piégées, journaux de D1, vérificateur de canary de juge) ;
- structure interne du Python et partage du code d'empreinte (sous P46-D-03a) ;
- bornes chiffrées (fichiers, octets, nombre de `watchPaths`), à mesurer ;
- grammaire exacte de la sortie brute, sans la rendre plus permissive (P46-D-02a) ;
- découpage en plans et vagues, dans l'ordre d'armement de P46-D-11 ; le modèle (état `à clore`,
  empreintes, prédicat « livrable présent ») avant les gates qui le lisent.

</decisions>

<requirements_proposed>
## Exigences proposées (famille CLOT)

Chaque exigence dérive d'une décision ci-dessus et n'en pose aucune nouvelle.

- **CLOT-01** : G3 refuse par deny l'écriture par outil d'un `CLOTURE.md` d'unité d'un lab adhérent
  quand un livrable `ecrit:` du `PLAN.md` voisin est absent, vide ou un lien ; le même prédicat
  « livrable présent » sert à R4 du recalcul (P46-D-01, P46-D-12).
- **CLOT-02** : G4 refuse par deny l'écriture par outil d'un `SUMMARY.md` d'unité quand le
  `VERDICT.md` voisin est absent, invalide, porte un constat `échec` ou une empreinte périmée ; le
  prédicat est réévalué à chaque écriture (P46-D-01, P46-D-03).
- **CLOT-03** : `poser-verdict.sh` pose deux empreintes (plan, livrables composés, une seule
  implémentation, aucun lien suivi, parcours borné, dépassement = refus) ; G4 et le recalcul les
  vérifient (`à juger` motif `verdict-perime` avant clôture, `indéterminé` après) (P46-D-03,
  P46-D-03a, P46-D-03b).
- **CLOT-04** : le recalcul dérive un neuvième état non terminal, `à clore` (constats passés,
  empreintes conformes, `SUMMARY.md` absent), à la place d'`indéterminé` pour ce cas (P46-D-04).
- **CLOT-05** : `poser-verdict.sh` refuse une quatrième tentative, avec un message distinct, sauf
  dérogation nominative couvrant l'unité ; le plafond est une constante du code (P46-D-05).
- **CLOT-06** : G4′ refuse le rapport d'un worker ou d'un producteur d'un lab adhérent sans sortie
  de commande brute, par deny sur `PreToolUse(SubagentHandback)` et par `decision: "block"` sur
  `SubagentStop` en repli ; juges, fil principal, agent inconnu et `agent_type` vide exclus
  (P46-D-02, P46-D-02a).
- **CLOT-07** : D1 trace toute écriture non expliquée d'un fichier surveillé d'un lab adhérent, en
  séance (`FileChanged`, `watchPaths` fichier par fichier depuis `SessionStart`/`CwdChanged`) et
  entre les séances (réconciliation par hash au `SessionStart`) ; il ne refuse jamais ; hors
  adhésion, aucun `watchPaths` (P46-D-07, P46-D-07a).
- **CLOT-08** : un vérificateur déterministe signale au `SessionStart` d'un lab adhérent chaque juge
  laxiste (verdict de canary sans `échec` sur le critère visé) et chaque « juge sans preuve » ; le
  contrat de la sortie piégée, l'étape écrite du premier cycle et les fixtures sont livrés
  (P46-D-06, P46-D-06a).
- **CLOT-09** : le hook central traite chaque événement par son mode, avec le contrat de sortie de
  P46-D-10 (jamais exit 2) ; G3, G4 et G4′ sont fail-closed, D1 fail-open déclaré ; le canary
  couvre chaque nouveau gate, le mode dégradé et D1 (P46-D-09, P46-D-10).
- **CLOT-10** : l'armement suit (G3 + G4) → G4′, chaque étape à 0 faux refus et 0 faux accept sur
  le banc puis sur le rejeu en lecture seule ; constantes dans le code livré (P46-D-11).
- **CLOT-11** : zéro régression sur les labs dev (octet vide et 0 pour chaque nouvel événement,
  mutation « ignorer l'adhésion » rouge) et coût du pré-filtre mesuré par nouvel événement, écrit
  dans la référence ; `FileChanged` hors adhésion prouvé nul (P46-D-16).
- **CLOT-12** : la spec moteur est amendée (§3.1, §5, §5.1, §10) avec date et canal ;
  `modele-cycles.md` porte les nouveaux gates, l'état `à clore`, les empreintes et les limites
  déclarées (P46-D-08) ; les suites tournent en CI Linux avec une mutation rouge tracée par garde ;
  `planning-core` passe en v2.10.0 sans release ; `HOOKS-CONTRAT-SORTIE.md` et l'inventaire des
  hooks suivent (P46-D-08, P46-D-14, P46-D-17, P46-D-18).

</requirements_proposed>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Faits de départ
- `46-RECHERCHE-HOOKS.md` (ce dossier) : `TaskCompleted`, `SubagentStop`, `FileChanged`,
  `SubagentHandback`, contrats de refus, échecs fail-open, issues amont (#60490, #95440, #91634,
  #63148/#16288, #92716).
- `46-SCOUTING.md` (ce dossier) : câblage du hook, armement, pré-filtre et ses coûts,
  `poser-verdict.sh`, R4/R6/R7/R8, canary, limites (a)…(an) concernées, suites et durées.

### Spec source
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` : §3 et §3.1 (états), §5
  (table, G3, G4, G4′, D1), §5.1, §5.2, §10, D-02 (le juge ne bloque que sur ses constats).
- `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` : C-16, §10 (préparer la
  preuve sans l'exécuter).
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` : B-01, §4 (I5/I6), §5.

### Planning du compartiment
- `.planning/workstreams/gouvernance/ROADMAP.md` § Phase 46 et en-tête du jalon (pas de release,
  gates rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md`).
- `.planning/workstreams/gouvernance/REQUIREMENTS.md`, famille `CLOT`.
- `.planning/workstreams/gouvernance/STATE.md` : tenu à la main, jamais par `state.*`,
  frontmatter fermé avant la ligne 60.
- Phase 45 : `45-CONTEXT.md` (P45-D-03, 03a, 03b, 05, 06, 08, 09, 13, 15, 20, 21), `45-04-PLAN.md`
  (A3, l.170-204), `45-VERIFICATION.md`. Phase 44 : `44-CONTEXT.md` (P44-D-03, D-08, D-09).

### Module cible et voisins
- `plugin/planning-core/` : `hooks/hooks.json`, `scripts/planning-hook.sh`, `scripts/poser-verdict.sh`,
  `scripts/recalc-planning.sh`, `scripts/check-gates-alive.sh`, `scripts/deroger-gate.sh`,
  `scripts/rejeu-gates.sh`, `scripts/rejeu-reel.sh`, `scripts/tests/`,
  `references/modele-cycles.md`, `references/templates/cycles/VERDICT.template.md`, `VERSION`,
  `CHANGELOG.md`, `README.md`.
- `plugin/_internal/merge-hooks.sh`, `plugin/_internal/vibeflow-update.sh` : les hooks de module
  sont fusionnés dans `settings.json` (pas déclarés par le plugin).
- `plugin/audit-architecture/references/rubric-design.md` l.58-62, 79-84 : test de discrimination
  « rejette un mauvais output connu », notion voisine de la sortie piégée.
- `docs/HOOKS-CONTRAT-SORTIE.md`, `scripts/tests/test-hook-exit-parc.sh`.
- `CLAUDE.md` racine : traçabilité des arbitrages, préfixage `P46-D-NN`, trailers `Gate-Touche:`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `planning-hook.sh` : cœur Python embarqué, `verifier_adhesion`, dérivation du rôle, `evaluer_g5`,
  sorties de refus (à décliner par événement : `hookEventName` y est codé en dur, l.799-811).
- `poser-verdict.sh` : écriture atomique sans traverser de lien, verrou `flock`, contrôle de
  tentative (l.349-355, 427-437), relecture par le parseur.
- `recalc-planning.sh` : règles R2/R4/R6/R7/R8, `ETATS_TOUS`, `LIBELLES`, lecture du verdict
  (l.1020-1033).
- `check-gates-alive.sh` : `CANARIS`, `GATES`, `COMMANDE_REFERENCE`, agents synthétiques
  `canary-juge`/`canary-worker`.

### Established Patterns
- Suites `test-*.sh` découvertes par la CI Linux ; jumeaux négatifs ; mutation rouge par garde,
  avec la trace du rouge (assertion, attendu, obtenu).
- Le Bash tool du poste tourne sous `/bin/zsh`, la CI sous `bash -e {0}` : rejouer les deux.
- Armement par commit qui change une constante, après canary vert et mesure à 0/0.

### Integration Points
- `hooks.json` : élargir le matcher `PreToolUse` à `SubagentHandback`, ajouter `SubagentStop`,
  `CwdChanged`, `FileChanged`, et la sortie `watchPaths` au `SessionStart`. Chaque nouvelle entrée
  change `COMMANDE_REFERENCE`, le canary, l'inventaire des hooks et les suites qui les comparent.
- Les compteurs des README racine changent si une suite est ajoutée (`scripts/check-version-sync.sh`).

</code_context>

<specifics>
## Specific Ideas

- Règle de Samuel : un hook ne paie son coût que là où il a un effet. D'où P46-D-16 : `FileChanged`
  nul hors adhésion par construction, les autres mesurés.
- « Un verdict qui n'est pas écrit sera refait » (spec §10) : le plafond et les empreintes vivent
  sur le disque.
- Un juge qui laisse tout passer est le mode d'échec le plus coûteux d'un système multi-agents
  (spec d'initialisation §10) : « juge sans preuve » n'est jamais vert.

</specifics>

<deferred>
## Deferred Ideas

- `TaskCompleted` en complément (Q1 option b) : écarté pour la 46 ; à reconsidérer si un lab
  métier adopte les équipes d'agents.
- Dispatch automatique du juge sur sa sortie piégée : Phase 48. Fabrication des sorties piégées :
  Phase 50.
- Seuil de juge dans `config.json` : Phase 50 (P46-D-13).
- G2′ et son point d'accroche : Phase 47 (P46-D-19).
- Sonde en direct de 2.1.288 (`FileChanged` sous `settings.json`, #95440) : possible hors
  worktree, par Willy ; non requise (P46-D-08).

</deferred>

---

*Phase: 46-moteur-gates-de-cloture-et-verdicts-haches*
*Context gathered: 2026-10-03*
