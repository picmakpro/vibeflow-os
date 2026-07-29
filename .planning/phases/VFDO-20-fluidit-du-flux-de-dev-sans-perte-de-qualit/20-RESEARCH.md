# Phase 20: Fluidité du flux de dev sans perte de qualité - Research

**Researched:** 2026-07-29
**Domain:** Gouvernance d'agents Claude Code (frontmatter, gates bash, DAG de mission) — repo de
distribution VibeFlow, aucune app runtime externe
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

> **Note de provenance** : `20-CONTEXT.md` a été produit en mode `--auto` (assumptions), sans
> `AskUserQuestion`, le 2026-07-28. Cette recherche a **relu sur pièce, le 2026-07-29, chaque fichier
> cité** dans `<canonical_refs>` du CONTEXT et confirme : **aucune dérive constatée** — tous les
> chemins, numéros de ligne et citations exactes vérifiés ci-dessous (§Vérification sur pièce)
> correspondent encore à l'état du repo. Les décisions ci-dessous sont donc **copiées verbatim, non
> ré-instruites** — cette recherche informe le COMMENT exécuter, jamais le QUOI décider.

### Locked Decisions

#### Note de méthode — cadrage en `--auto`, sans re-décision des 4 arbitrages de Samuel (D-00)

- **D-00 [informationnel] :** Ce cadrage a été produit en mode `--auto` (assumptions), sans
  `AskUserQuestion` — l'agent `vf-coder` qui l'a rédigé n'a pas cet outil au runtime (cf. D-09 plus
  bas, qui documente précisément cette classe de problème). Les **4 décisions de doctrine (D1→D4 de
  la mission du 2026-07-28)** sont appliquées telles quelles, jamais rouvertes. Ce que ce document
  ajoute : les specs fichier-par-fichier, les gray areas d'implémentation qu'elles laissaient
  ouvertes, et la résolution — par choix recommandé par défaut, jamais par nouvelle question à
  l'utilisateur — de ces gray areas. **Deux points sont signalés comme nécessitant une attention du
  manager** malgré la résolution auto : D-05 (mécanisme d'injection MCP fine, matériellement
  sous-spécifié par la décision de Samuel) et D-16 (tension entre le texte littéral du critère 5 et
  le principe de réduction de D4). Voir aussi le rapport de `vf-coder` à `vf-dev-manager`.

---

#### Changement 1 — accès MCP fin de `vf-reviewer` + révision ADR-051 (D-01 → D-05)

- **D-01 [tranché, Samuel] :** `vf-reviewer` — et lui SEUL, ni `vf-auditer` ni `vf-dev-manager` —
  reçoit exactement `mcp__XcodeBuildMCP__test_sim`, `mcp__XcodeBuildMCP__build_sim`,
  `mcp__XcodeBuildMCP__clean`. `clean` est inclus par choix explicite : un `build_sim` en cache
  annonce « 0 warning » sans rien compiler (piège d'outillage constaté sur le lab `ExploreSomfy`),
  un relecteur sans `clean` reproduit le défaut qu'il est censé corriger.
  État actuel vérifié : `plugin/dev-orchestrator/agents/vf-reviewer.md:4` —
  `tools: Read, Bash, Glob, Grep, Agent(gsd-code-reviewer)`, aucune entrée MCP. `vf-auditer.md:4` et
  `vf-dev-manager.md:4` n'en ont pas non plus (confirmé, à ne pas toucher).

- **D-02 [tranché, Samuel] :** ADR-051 (`docs/ADR.md:356-437`) est révisée sur ce seul point. La
  phrase exacte à amender, ligne 396-399 : « Les agents de planif/revue/audit (`vf-dev-manager`,
  `vf-reviewer`, `vf-auditer`) restent inchangés (moindre privilège — ils ne compilent jamais). »
  Nouvelle formulation : `vf-dev-manager` et `vf-auditer` restent inchangés ; `vf-reviewer` reçoit
  l'allowlist fine ci-dessus, avec l'argument explicite « un relecteur ne PRODUIT pas de verdict de
  compilation, il en VÉRIFIE un » — et le coût écrit noir sur blanc : **+90s par revue, un slot de
  simulateur consommé**. La section « Code Impacté » (lignes 424-432) gagne une entrée
  `plugin/dev-orchestrator/agents/vf-reviewer.md` + `inject-mcp-tools.sh` (mode named-tool, D-05).
  — **Reversibility:** reversible — une ligne d'ADR, un mécanisme d'injection additif.

- **D-03 [assumption, Confident, auto-confirmée] :** La granularité fine (nommée) est retenue contre
  le wildcard par serveur, **prouvé par test réel** le 2026-07-28 (sonde A/B/C, 3 process `claude -p`
  frais) : une allowlist `mcp__<serveur>__<outil>` restreint réellement (l'outil voisin non listé
  échoue, `ToolSearch` ne le contourne pas). **Non prouvé** : que XcodeBuildMCP nomme réellement ses
  outils `test_sim`/`build_sim`/`clean` — la sonde a utilisé ces noms par cohérence avec la doc du
  serveur, jamais vérifié contre un serveur vivant (ce repo n'a pas de `.mcp.json`). **Recette
  humaine à prévoir sur un lab iOS avec XcodeBuildMCP réellement connecté** — hors périmètre
  d'exécution de cette phase, à consigner en reste-à-faire comme le SC2 de la Phase 19.

- **D-04 [assumption, Confident] :** Le bug de conformité `check-agents.sh:355` (`re.fullmatch(
  r"[A-Za-z0-9_-]+", tok)`, qui rejette tout `*`) contredit `inject-mcp-tools.sh:10` (qui injecte
  `mcp__<serveur>__*` pour `vf-coder` et les 3 agents `mobile-test-team`, tous `vf-mcp-consumer:
  true`). **La forme fine de D-01 contourne ce bug POUR `vf-reviewer`** (aucun `*` dans
  `test_sim`/`build_sim`/`clean` → passe déjà le charset actuel) — mais le bug reste latent et réel
  pour `vf-coder` et les 3 agents mobile-test sur tout lab avec `.mcp.json` : leur injection en
  wildcard-serveur ferait échouer `check-agents.sh --strict` et `guard-agent-write.sh` refuserait de
  réécrire l'agent. **Rattaché au Changement 5** (D-22) plutôt que traité ici, périmètre naturel
  identifié par la mission du matin — voir D-22 pour la correction du regex.

- **D-05 [assumption, Likely, RECOMMANDÉ PAR DÉFAUT — point d'attention manager] :** Le mécanisme
  `vf-mcp-consumer: true` existant (porté par `vf-coder.md:8` et les 3 agents mobile-test) injecte
  le **wildcard serveur entier** pour **chaque serveur présent** dans le `.mcp.json` du lab — il ne
  sait pas restreindre à 3 outils nommés d'UN SEUL serveur. L'appliquer tel quel à `vf-reviewer`
  violerait D-01 (accès à tout serveur configuré, pas seulement XcodeBuildMCP nommé finement).
  **Décision retenue (par défaut, pas re-questionnée à l'utilisateur) :** `inject-mcp-tools.sh` gagne
  un second mode, spécifique à `vf-reviewer`, qui n'injecte QUE les 3 tokens nommés d'un serveur
  identifié comme XcodeBuildMCP dans le `.mcp.json` du lab (best-effort : absent → aucune injection,
  silence, comme le reste du mécanisme ADR-051), et jamais le wildcard. Le fichier SOURCE
  `vf-reviewer.md` de ce repo **ne change pas** son `tools:` littéral (même patron que `vf-coder.md`,
  qui ne porte pas non plus de `mcp__` en dur — vérifié, 0 occurrence dans tout `plugin/*/agents/*.md`)
  ; seul un marqueur de frontmatter (nom à trancher par le planner, ex. `vf-mcp-consumer:
  xcodebuildmcp-review-only` ou une liste dédiée dans le script) déclenche le nouveau mode. **Pourquoi
  signalé au manager plutôt que simplement tranché** : c'est un choix d'architecture sur un script
  d'install partagé (`inject-mcp-tools.sh`, déjà modifié 2 fois cette semaine en Phase 19), pas un
  point de doctrine — mais le mécanisme exact (nom du marqueur, matching du nom de serveur) reste un
  vrai degré de liberté d'implémentation que Samuel n'a pas tranché explicitement. — **Reversibility:**
  costly — script d'install partagé, tout futur agent nécessitant un sous-ensemble nommé d'un serveur
  MCP répliquerait ce patron ou le généraliserait.

#### Critère de succès n°2 — écart `tools:`/runtime, les deux sens (D-06 → D-09)

- **D-06 [tranché, Samuel — portée réelle confirmée] :** `disallowedTools: Write, Edit` (prouvé par
  sonde à 3 variables `nomem`/`mem`/`deny`, gagne contre l'auto-enable de `memory:`) s'applique aux
  **4 juges**, fichiers exacts vérifiés :
  - `plugin/design-orchestrator/agents/vf-design-judge.md:4` (`tools: Read, Bash, Glob, Grep` —
    porte `Bash`)
  - `plugin/business-pilot-bundle/agents/quality-gate-client.md:4` (`tools: Read, Glob, Grep` —
    pas de `Bash`)
  - `plugin/content-bundle/agents/content-clarity-judge.md:4` (`tools: Read, Glob, Grep` — pas de
    `Bash`)
  - `plugin/growth-bundle/agents/growth-quality-judge.md:4` (`tools: Read, Glob, Grep` — pas de
    `Bash`)
  Aucun des 4 ne porte `disallowedTools` aujourd'hui. `check-agents.sh:156` connaît déjà le champ
  (`KNOWN` inclut `disallowedTools`) — aucun changement de gate nécessaire pour l'accepter.

- **D-07 [assumption, Confident] :** L'angle mort `Bash` touche **seulement `vf-design-judge`**
  parmi les 4 (seul à porter `Bash`) — pour lui, `disallowedTools` ne rend PAS le read-only complet
  (`echo > fichier` reste ouvert). Pour les 3 juges de bundle, la barrière est complète. **Décision
  retenue (recommandée) :** cesser d'écrire « read-only » sans qualification pour `vf-design-judge`
  dans sa description et dans la doctrine (team-kernel/README) — documenter « sans Write/Edit
  directs ; `Bash` reste accessible, l'absence d'écriture est un contrat de prompt sur ce canal, pas
  une barrière runtime » — plutôt que retirer `Bash` (retrait non demandé par Samuel, et `Bash` sert
  probablement à `vf-design-judge` pour des captures d'écran/inspection — à confirmer par le planner
  en lisant le corps de l'agent, hors scope de cette analyse). `vf-reviewer` et `vf-auditer` gardent
  aussi `Bash` mais **ne sont pas dans le périmètre du Changement 2** (D-06 ne les touche pas).

- **D-08 [tranché, Samuel — correction ciblée] :** Doctrine à corriger :
  - `plugin/conductor/references/team-kernel.md:23` (tableau) — contient littéralement « juges sans
    Write/Edit » — devient « juges sans Write/Edit (`disallowedTools`) » ou équivalent factuel.
  - `plugin/conductor/README.md:44` — même formule exacte, confirmée identique — même correction.
  - **Divergence avec la mission du matin, à noter** : `team-kernel.md:36` ne contient PAS la formule
    « Write/Edit » (contrairement à ce que rapportait `.planning/missions/2026-07-28-phase-20-
    instruction-prealable.md` §3.3) — son texte réel dit « tous les juges read-only le peuvent, par
    construction » (parlant du parallélisme). Proche par le sens mais pas la formule exacte. Le
    planner doit vérifier sur pièce avant d'éditer — ne pas se fier au rapport du matin pour cette
    ligne précise.
  - **Effet de bord à documenter explicitement** (dans ADR-051 révisée ou une note dédiée) : un juge
    sous `disallowedTools: Write, Edit` ne peut plus écrire son `MEMORY.md` (il continue de le lire)
    — cohérent avec l'intention de regard frais, mais ADR-044 impose `memory:` : c'est un choix
    assumé, pas un oubli.
  - `team-kernel.md:23` affirme aussi « anti-triche vérifié par les suites de test de chaque module »
    — **affirmation non re-vérifiée dans cette analyse** (hors périmètre du grep ciblé). Si le
    planner la recroise et la trouve fausse (comme un précédent similaire en Phase 15, cf. STATE.md
    2026-07-27 "Le cloisonnement Agent(...) n'est PAS linté"), la corriger dans le même geste —
    signalé pour vigilance, pas confirmé faux ici.

- **D-09 [tranché, Samuel — le sens FERMETURE de l'écart, nouveau constat à documenter] :** Le sens
  ouverture (`memory:` rouvre Write/Edit) est couvert par D-06. Le sens **fermeture** — un outil
  déclaré dans `tools:` mais absent au runtime — est un fait distinct, **jamais documenté nulle
  part actuellement** (`grep -n "AskUserQuestion" plugin/conductor/references/team-kernel.md` → 0
  résultat). Fait établi par la mission elle-même : `vf-dev-manager.md:4` déclare `AskUserQuestion`
  dans son `tools:`, mais quand `vf-dev-manager` est dispatché **en sous-agent** (jamais en
  incarnation fenêtre principale), le runtime ne la fournit pas — c'est précisément ce qui a gelé la
  mission d'instruction préalable du 2026-07-28 au nœud `checkpoint-doctrine`.
  **Décision retenue** : documenter cette classe de problème dans `team-kernel.md` (à côté de la
  ligne 23, qui documente déjà la restriction analogue sur l'allowlist `Agent(...)` en parenthèses —
  même famille de constat, patron à réutiliser), et ajouter au corps de `vf-dev-manager.md` (près de
  ses 2 usages actuels d'`AskUserQuestion`, lignes 21 et 141) le filet de repli : si l'outil est
  indisponible au runtime malgré sa présence en `tools:`, remonter `human_needed` dans le rapport
  typé plutôt que d'appeler un outil absent. **Patron déjà écrit, à copier tel quel** : le propre
  fichier `plugin/dev-orchestrator/agents/vf-coder.md` (Cadrage, §1) porte déjà cette phrase :
  « Tu n'as pas `AskUserQuestion` : une question de cadrage que les assumptions documentées ne
  couvrent pas → statut `human_needed` remonté au manager, JAMAIS auto-répondue en silence. » —
  c'est exactement le filet que `vf-dev-manager.md` doit gagner pour son propre cas (dispatché en
  sous-agent par `vibeflow-dev` ou par un contexte parent). — **Reversibility:** reversible — ajout
  de doctrine documentaire, aucun changement de comportement machine requis (le fallback existe déjà
  comme pattern ailleurs dans le repo).

#### Changement 2 — la revue devient un étage de premier rang (D-10 → D-14)

- **D-10 [tranché, Samuel — F1 de la mission du matin] :** `plugin/dev-orchestrator/agents/
  vf-dev-manager.md:108-110`, citation exacte actuelle : « **Pas de double revue** : si le rapport
  typé de `vf-coder` est `passed` avec verdict revue PASS, ne re-dispatche pas de revue de code sur
  la même étape — seuls Test/Audit s'ajoutent. » **Cette phrase est réécrite**, pas contournée : la
  revue devient un nœud DAG `revue-N` (deps=`exec-N`) posé **systématiquement** par le manager pour
  chaque étape, dispatchant `vf-reviewer` **directement** (plus via `vf-coder`). Motif retenu contre
  « faut-il sortir la revue ? » : le cas existe déjà — `mission-cross-team.md:44` pose littéralement
  `` "$S"/dag.sh add --file="$DAG" --id=revue-N --step="revue code étape N" --deps=exec-N `` et
  ligne 74 : « **« Vert » complet** = `critique-rendu` ≥ seuil ET revue PASS — les deux, jamais l'un
  ou l'autre seul. » Il s'agit donc de **généraliser** ce cas déjà écrit pour l'étage design croisé, à
  toute mission dev, pas de l'inventer.

- **D-11 [tranché, Samuel — sort du cycle interne de `vf-coder`] :** Corollaire direct de D-10 :
  `plugin/dev-orchestrator/agents/vf-coder.md` §« Le cycle (délégation) » perd son étape 4 « Revue »
  (actuellement : « dispatche l'agent `vf-reviewer`… boucle fix → re-revue jusqu'au PASS ou budget
  (3 tours max) »). Le cycle de `vf-coder` devient **3 étapes** : Cadrage → Plan → Exécution. La
  boucle fix→re-revue (budget 3 tours, au-delà remonte au manager) migre **vers le manager**, qui
  l'exécute lui-même autour du nœud `revue-N` : dispatch `vf-reviewer` → si bloquants, dispatch
  `vf-coder` en mandat **fix ciblé uniquement** (pas un cycle complet) → re-dispatch `vf-reviewer` →
  jusqu'au PASS ou budget. **Point à signaler explicitement au manager** : ce changement modifie le
  fichier `vf-coder.md` — c'est-à-dire l'agent qui a produit ce cadrage lui-même. Aucune contradiction
  logique (le cadrage n'exécute rien), mais le planner et l'exécuteur doivent le savoir en éditant ce
  fichier. — **Reversibility:** costly — contrat de worker que plusieurs missions ont déjà consommé
  (Phases 15, 17, 19 toutes dispatchent `vf-coder` avec ce cycle à 4 étapes documenté) ; revenir en
  arrière après publication recréerait la confusion sur qui pilote la revue.

- **D-12 [tranché, Samuel — critère 4, déclencheurs objectifs] :** La gradation n'est **jamais** un
  jugement au feeling — critères objectifs (a) adaptateur d'infra non couvert par les tests,
  (b) fichier partagé avec une mission parallèle en vol (nécessite D-13/`--scope`), (c) code non
  couvert par la mutation, (d) geste utilisateur/géométrie de vue → revue **pleine** non négociable.
  **Revue de jointure obligatoire, nœud séparé**, dès que deux lots parallèles fusionnent — déclenchée
  sur la **topologie du DAG** (toute paire de nœuds `exec` incomparables partage un descendant
  `join`), **jamais** sur l'intersection des périmètres de fichiers (vide par construction en
  parallélisation nominale — on parallélise précisément quand les périmètres sont disjoints). Le
  nœud `join` lit **l'union** des deux diffs. Revue **allégée** réservée au Domain pur à mutation
  verte, à la doc et aux catalogues sans ajout de clé. **En cas de doute → revue pleine** (le
  classement du lot est un point de décision donc un point d'erreur ; le défaut par défaut doit être
  le sûr).

- **D-13 [tranché, Samuel — dépendance 2↔3 explicite] :** `dag.sh` (`plugin/conductor/scripts/
  dag.sh`) gagne un `--scope=<liste-de-chemins-ou-globs>` sur `dag.sh add`. Vérifié : aucun flag
  `--scope`/`--files` n'existe aujourd'hui (`grep -n "scope\|files" dag.sh` → 0), et le schéma du
  nœud (ligne 103, `node = {"id":…, "step":…, "stage":…, "deps":…, "status":…}`) n'a aucun champ
  périmètre — `vf-dev-manager.md:75-77` (référence à vérifier par le planner) impose pourtant de
  déclarer le périmètre au moment du `dag.sh add`, instruction que l'outil ne sait pas exécuter
  aujourd'hui. **Le critère (b) de D-12 et la table des fichiers gelés (Changement 3) dépendent
  directement de ce champ.** — **Reversibility:** reversible — champ additif dans le schéma JSON,
  rétro-compatible (nœuds sans `scope` = tableau vide, comportement inchangé).

- **D-14 [tranché, Samuel — `reopen` force le régime plein] :** `dag.sh reopen` (lignes 127-149,
  fonction `dependents()` 131-138, `recompute()` ligne 145) rouvre le nœud ciblé et tous ses
  dépendants transitifs. **Décision retenue** : tout nœud `revue-*`/`join` rouvert par `reopen` voit
  son régime forcé à **plein**, jamais allégé — enforcé machine (un champ `review_regime: "full"`
  écrit par `reopen` lui-même sur les nœuds de revue qu'il réactive), pas par consigne de prompt.
  Motif : meilleur rapport garantie/coût, et c'est exactement le garde-fou non négociable de la
  phase (« aucun allègement sur un diff de comblement ») rendu machine-enforced plutôt que déclaratif.

#### Changement 3 — `.planning/MISSION-INVARIANTS.md` (D-15 → D-17)

- **D-15 [tranché, Samuel — contenu réduit aux éléments gatés] :** Fichier **absent** aujourd'hui
  (`test -f .planning/MISSION-INVARIANTS.md` → faux ; aucun template similaire ailleurs dans le
  repo). Contenu retenu, **2 sections seulement** :
  1. **Zones de risque en globs** — forme falsifiable de ce que le ROADMAP nomme « motifs de risque
     récurrents du projet » : au lieu d'une prose narrative («la neuvième occurrence du motif»), une
     liste de globs (patron CODEOWNERS) que le planner amorce avec les catégories déjà mesurées par
     l'audit source (adaptateur matériel non injectable, contrôleur partagé entre features, chemin
     BLE partagé...) — **falsifiable machine** : un glob qui ne matche plus aucun fichier du repo est
     une « zone morte » détectable par un script dédié (à créer, périmètre du planner — probablement
     une extension légère existante ou un nouveau `check-mission-invariants.sh` sur le modèle
     `check-doc-drift.sh`).
  2. **Table des fichiers gelés** — **non recopiée statiquement** dans le `.md` (risque de péremption
     explicitement écarté par Samuel : « s'il ment, il est pire que rien », précédent réel cité —
     un `CLAUDE.md` affirmant encore une contrainte matérielle obsolète). Le fichier documente la
     **convention** : cette table se lit **à la demande**, dérivée du `--scope` (D-13) des nœuds
     actuellement `blocked`/en cours dans le(s) DAG(s) de mission actif(s)
     (`.planning/missions/dag-*.json`) — jamais une copie figée. Un lecteur (manager ou script) qui
     veut savoir « quels fichiers sont gelés maintenant » interroge le DAG vivant, pas ce fichier.
  **N'entre PAS** : le seuil de tests (invérifiable sans exécution, mouvant 177→331 en une journée
  sur l'audit source — explicitement exclu par Samuel).

- **D-16 [assumption, Likely — point d'attention manager, tension avec le texte littéral du critère
  5] :** Le critère de succès n°5 du ROADMAP dit littéralement « `MISSION-INVARIANTS.md` porte les
  **3 invariants** + **la contrainte d'outillage du moment** ». Les « 3 invariants » nommés dans le
  paragraphe Changement 3 sont {seuil de tests, table des fichiers gelés, motifs de risque récurrents}
  — D-15 n'en retient que 2, sous forme transformée pour l'un (motifs récurrents → zones de risque en
  globs, rendu falsifiable) et exclut explicitement le 3e (seuil de tests). **La « contrainte
  d'outillage du moment »** (ex. : profils de session XcodeBuildMCP désactivés, chaque appel de build
  doit porter `projectPath`/`scheme`/`simulatorId` — déjà appliqué côté lab `ExploreSomfy`, cf. fin de
  §Phase 20 du ROADMAP) n'est **pas falsifiable par une simple règle** — ni glob, ni requête DAG.
  **Décision retenue (auto, recommandée)** : l'inclure quand même, mais dans une 3e section
  explicitement étiquetée **« non gaté — fait documenté, à revérifier manuellement à chaque
  mission »**, pour ne jamais prétendre à une garantie qu'elle n'a pas — cohérent avec l'esprit de D4
  (« tout champ dont le mécanisme n'est pas gaté saute [de la garantie machine], pas du fichier »).
  **Signalé au manager** : c'est une lecture qui concilie le texte littéral du critère 5 (4 items) et
  le principe de D4 (réduction aux éléments gatés), mais ce n'est pas ce que D4 dit mot pour mot — à
  valider ou corriger explicitement, pas une évidence.

- **D-17 [assumption, Confident] :** Le brief de mission (`mission-contracts.md`, section « Brief de
  mission (main → manager) », lignes 10-23) et le digest (section « Digest de mission (manager →
  workers) », lignes 49-60, notamment ligne 59 « Périmètre de fichiers du nœud : `<déclaré au dag
  add>` ») **restent inchangés dans leur format** — `MISSION-INVARIANTS.md` est lu par le manager au
  même titre que `STATE.md` (déjà la doctrine actuelle pour les conventions projet, `vf-dev-manager.md
  :29`), pas dupliqué dans le brief. Aucune nouvelle section de brief à créer.

#### Changement 5 (ROADMAP Changement 4) — scope des hooks + bug de charset (D-18 → D-23)

- **D-18 [tranché, Samuel — le fix minimal, prouvé exécutable] :** `plugin/conductor/scripts/
  check-agents.sh:78-79` (`AGENTS_DIR=".claude/agents"`, `SKILLS_DIR=".claude/skills"`, relatifs au
  cwd) et `plugin/conductor/scripts/check-debug-research.sh:35-36` (même défaut) — le hook
  `SessionStart` (`plugin/conductor/hooks/hooks.json`, contenu intégral vérifié : 2 commandes
  `check-agents.sh --hook || true` et `check-debug-research.sh --hook || true`, sans
  `--agents-dir`/`--skills-dir`) tombe donc sur ces défauts relatifs à un cwd qui n'est pas
  nécessairement la racine du lab. **Fix retenu, prouvé par exécution le 2026-07-28** : `hooks.json`
  passe explicitement `--agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills`
  sur les 2 commandes — `merge-hooks.sh:167` fait déjà un `.replace()` **global** Python de
  `{{VF_SCRIPTS}}` sur toute la ligne de commande (confirmé), donc la substitution existante suffit
  sans nouveau code, dans les 3 scopes d'install. **4 lignes dans `hooks.json`, zéro script modifié**
  pour ce point précis. Options écartées (déjà instruites) : union projet+user (conflit
  `guard-agent-write.sh:62-72`/CND-05-T20) ; défaut conditionnel (non-déterminisme machine).

- **D-19 [tranché, Samuel — piège 1, ne pas oublier `skills`] :** Corriger `AGENTS_DIR` sans
  `SKILLS_DIR` perd des findings sur les 2 scripts — le fix de D-18 couvre déjà les deux
  simultanément pour `check-agents.sh` (`--agents-dir` + `--skills-dir`) ; s'assurer que le fix pour
  `check-debug-research.sh` fait de même (mêmes 2 flags disponibles, lignes 48-49 du script,
  confirmés).

- **D-20 [tranché, Samuel — piège 2, `--third-party-prefix` sur `check-debug-research.sh`] :**
  `check-debug-research.sh` n'a **aucun** flag `--third-party-prefix` aujourd'hui (`grep -n
  "third-party-prefix\|third_party" check-debug-research.sh` → 0 résultat, confirmé — contrairement à
  `check-agents.sh` qui l'a, référencé lignes 580-584). Corriger son scope sans lui porter ce
  mécanisme injecterait 5 faux positifs tiers (`gsd-debug`, `gsd-ns-review`,
  `gsd-debug-session-manager`, `seo-audit`, `diagnose`) à chaque session. **Fix retenu : porter le
  mécanisme EXISTANT de `check-agents.sh`** (même flag, même défaut `gsd-`) vers
  `check-debug-research.sh` — ce n'est **pas** l'option d'exclusion redondante que le critère 6
  interdit (celui-ci interdit d'en inventer un **second mécanisme différent**, pas de réutiliser
  celui qui existe déjà pour un script qui ne l'a pas encore).

- **D-21 [tranché, Samuel — critère 6 amendé, lever l'exemption `--hook`] :** Corriger le scope seul
  ne suffit pas : `check-agents.sh:568` (`if strict and not allow_empty and not hook:`) et `:571`
  (`if not hook:`) exemptent le mode `--hook` du contrat anti-vert-à-vide — combiné au commentaire
  ligne 64 confirmé (« `--hook` n'imprime QUE les erreurs, jamais les warnings ») cela produirait,
  après le seul fix D-18, **27 warnings réels pour 0 ligne affichée** : un faux vert. **Décision
  retenue** : le mode `--hook` doit imprimer les warnings **quand il y en a**, tout en restant
  silencieux **quand il n'y en a pas** — concilier « silencieux en régime nominal » et « utile sur les
  dérives » en conditionnant l'affichage au compte réel (`if warning_count > 0: print(...)`), pas en
  supprimant l'exemption de façon inconditionnelle (qui romprait le silence nominal voulu par
  conception). **Patron de contrat de sortie à copier** (déjà identifié dans la mission du matin, non
  contredit par l'analyse) : `update-banner.sh` — silence total en nominal, `systemMessage` JSON
  quand il a quelque chose à dire ; aucun `exit` d'un hook `SessionStart` ne bloque la session
  (doc officielle) — le `|| true` de `hooks.json` reste sans effet réel sur le comportement (aucun
  `exit 1` ne bloquerait de toute façon) mais n'est pas retiré ici (hors périmètre strict du critère
  6, à noter en discrétion).

- **D-22 [tranché, Samuel — bug de conformité, intégré au périmètre du Changement 5] :**
  `check-agents.sh:355` (`re.fullmatch(r"[A-Za-z0-9_-]+", tok)`) rejette tout token contenant `*`,
  alors qu'`inject-mcp-tools.sh:10` (en-tête, citation exacte confirmée : « Le glob générique `mcp__*`
  N'EST PAS accepté en allowlist `tools:` […] : on injecte donc, par serveur, la forme sûre
  `mcp__<serveur>__*` ») produit précisément cette forme pour `vf-coder` et les 3 agents
  `mobile-test-team` (tous `vf-mcp-consumer: true`). **Intégré à cette phase** (périmètre naturel des
  Changements 1 et 5, comme demandé) plutôt que justifié en exclusion — **fix retenu** : élargir le
  regex pour accepter un `*` final littéral après le double-underscore de séparation serveur/outil
  (ex. `re.fullmatch(r"[A-Za-z0-9_-]+", tok) or re.fullmatch(r"mcp__[A-Za-z0-9_-]+__\*", tok)`, forme
  exacte laissée au planner), **sans** ouvrir `*` n'importe où dans le token (garder le rejet pour un
  `*` en milieu de chaîne). **Corollaire explicitement mis en Claude's Discretion** : le gate ne
  valide toujours pas la *forme* `mcp__<serveur>__<outil>` d'un token MCP (un `mcp__typo__foo` passe
  en silence) — resserrer cette validation est une amélioration **optionnelle**, non requise par les
  7 critères de succès ; ne pas laisser le scope déborder dessus.

- **D-23 [informationnel] :** Aucun agent du repo ne porte aujourd'hui de token `mcp__` littéral dans
  son `tools:` source (`grep -rn "mcp__" plugin/*/agents/*.md` → 0 hors CHANGELOG/README) — le bug
  D-22 est **latent** dans ce repo (pas de `.mcp.json` ici) mais réel dès qu'un lab avec un serveur
  MCP installe VibeFlow. Le planner ne doit pas chercher à le reproduire localement pour le prouver ;
  un test unitaire du regex (nouveaux cas dans `plugin/conductor/scripts/tests/test-check-agents.sh`)
  suffit — **et doit exercer le chemin par défaut sans `--agents-dir` explicite**, cf. D-18/le piège
  de mesure ci-dessous.

#### Le piège de mesure — obligatoire pour TOUS les fixes de scope (D-24)

- **D-24 [tranché, Samuel — non négociable] :** Aucun des **58 + 14** cas actuels de
  `test-check-agents.sh`/`test-check-debug-research.sh` n'exerce le **chemin par défaut** (sans
  `--agents-dir`/`--skills-dir` explicite) — `run_check()` les passe toujours en dur. C'est
  précisément pour cette raison que le bug de scope a survécu à une Phase 16 entière dédiée au
  script. **Tout plan qui touche D-18/D-19/D-20 DOIT ajouter un cas « défaut, cwd sans
  `.claude/agents` »** — sinon la correction elle-même resterait non couverte, répétant l'erreur.
  Portabilité macOS + Linux **prouvée par exécution**, jamais par lecture (patron établi Phases 16,
  17, 19).

#### Governance & release (D-25 → D-26)

- **D-25 [tranché] :** **6 modules bumpés** (versions courantes vérifiées au 2026-07-28) :
  `conductor` v1.16.0 (check-agents.sh, check-debug-research.sh, dag.sh, hooks.json, team-kernel.md,
  README.md), `dev-orchestrator` v2.7.1 (vf-reviewer.md, vf-dev-manager.md, vf-coder.md,
  mission-cross-team.md, mission-contracts.md, inject-mcp-tools.sh), `design-orchestrator` v1.3.1
  (vf-design-judge.md), `business-pilot-bundle` v2.0.2 (quality-gate-client.md), `content-bundle`
  v2.0.2 (content-clarity-judge.md), `growth-bundle` v2.0.2 (growth-quality-judge.md). Tous en
  **minor** (nouvelle capacité — accès MCP, `disallowedTools`, nœud DAG, `--scope`) sauf les purs
  correctifs de bug/scope qui pourraient rester en **patch** au cas par cas — arbitrage exact laissé
  au planner par fichier, cohérent avec la règle CONVENTIONS.md (nouvelle capacité → minor, correctif
  → patch). `docs/ADR.md` (révision ADR-051 + nouvel **ADR-060**) et `.planning/MISSION-INVARIANTS.md`
  sont hors triade module (gouvernance repo / planning projet).

- **D-26 [tranché] :** **ADR-060** est le numéro libre (dernier posé : ADR-059, `docs/ADR.md:930`).
  Sujet : le nœud de revue devient un étage de premier rang piloté par le manager (Changement 2/3) —
  ADR-051 reçoit une révision ciblée (Changement 1), pas un nouvel ADR. Le planner tranche si
  Changement 5 (scope hooks) mérite son propre ADR ou reste un simple CHANGELOG — **recommandé :
  CHANGELOG seul**, c'est une correction de configuration, pas un changement de doctrine (distinction
  explicitement demandée par le livrable de cadrage du ROADMAP).

### Claude's Discretion

- Découpage exact en N fichiers `20-NN-PLAN.md` (suggestion non contraignante, 6 modules + 1 doc
  gouvernance + 1 fichier planning ⇒ probablement 4-6 plans, groupés par changement avec Changement 2
  scindé en sous-plans vu sa taille — « il vaut à lui seul plus que les 3 autres réunis », réserve du
  ROADMAP).
- Nom exact du marqueur de frontmatter pour D-05 (mode d'injection nommé pour `vf-reviewer`).
- Forme exacte du regex de D-22.
- Emplacement exact du script de détection de « zone morte » de D-15 (nouveau script vs extension
  d'un gate existant).
- Étendue de la revue de `team-kernel.md:23`/`conductor/README.md:44` (D-08) — corriger uniquement la
  phrase citée, ou toute occurrence voisine du même motif si le planner en trouve d'autres en
  relisant les deux fichiers en entier.
- Si Changement 5 mérite un ADR dédié (D-26).

### Deferred Ideas (OUT OF SCOPE)

- **Recette humaine sur lab iOS avec XcodeBuildMCP réellement connecté** (D-03) — valider que
  `test_sim`/`build_sim`/`clean` sont les noms d'outils exacts. Hors périmètre d'exécution de cette
  phase (comme SC2 de la Phase 19), à consigner en reste-à-faire post-exécution.
- **Resserrer la validation de forme des tokens MCP** (`mcp__typo__foo` passe en silence, D-22
  corollaire) — amélioration optionnelle explicitement exclue du périmètre requis par les 7 critères,
  à ne pas laisser gonfler le scope de Changement 5.
- **Vérifier l'affirmation « anti-triche vérifié par les suites de test de chaque module »**
  (`team-kernel.md:23`, D-08) — non re-vérifiée dans ce cadrage, signalée pour vigilance seulement.
  Motif similaire déjà rencontré et corrigé en Phase 15 (STATE.md, 2026-07-27).
- **Retrait de `Bash` sur `vf-design-judge`** — écarté au profit d'une documentation honnête de
  l'angle mort (D-07) ; rouvrable si un futur audit montre que `Bash` n'est en réalité pas utilisé
  par cet agent.
- **`|| true` sur les 2 hooks `--hook`** — noté comme sans effet réel (aucun `exit` d'un hook
  SessionStart ne bloque), mais son retrait n'est pas dans le périmètre du critère 6 — laissé tel
  quel (D-21).

</user_constraints>

<phase_requirements>
## Phase Requirements

Aucun ID de requirement formel n'existe encore dans `.planning/REQUIREMENTS.md` pour la Phase 20
(`Requirements: TBD (à dériver au cadrage)` dans le ROADMAP). Le ROADMAP §Phase 20 pose **7 critères
de succès numérotés** — utilisés ci-dessous comme IDs provisoires `SC1`..`SC7`. Le planner devrait
soit conserver cette numérotation SCn dans REQUIREMENTS.md, soit lui substituer un préfixe cohérent
avec le reste du projet (ex. `FLUX-01..07`) — les deux sont compatibles avec la table de traçabilité
existante.

| ID | Description (ROADMAP §Phase 20) | Research Support |
|----|-------------|------------------|
| SC1 | ADR-051 révisé (argument « vérifie, ne produit pas »), `vf-reviewer` seul reçoit l'accès MCP fin, granularité tranchée par test réel | §Architecture Patterns Pattern 1 ; §Code Examples Ex.1 ; D-01..D-05 verbatim ci-dessus |
| SC2 | Écart `tools:` déclaré/runtime traité (pas seulement constaté) dans les deux sens (ouverture ET fermeture) | §Architecture Patterns Pattern 2 ; §Code Examples Ex.2/Ex.6 ; D-06..D-09 |
| SC3 | La revue devient un étage de premier rang piloté par le manager ; « pas de double revue » réécrite | §Architecture Patterns Pattern 3 ; §Code Examples Ex.3 ; D-10, D-11 |
| SC4 | Critères de déclenchement objectifs (a-d) ; revue de jointure obligatoire sur topologie DAG ; `--scope` sur `dag.sh` | §Architecture Patterns Pattern 3/4 ; §Code Examples Ex.4 ; D-12, D-13, D-14 |
| SC5 | `MISSION-INVARIANTS.md` créé (2 sections gatées + 1 non gatée), mécanisme de mise à jour spécifié | §Architecture Patterns Pattern 5 ; §Code Examples Ex.7 ; D-15..D-17 |
| SC6 | Scope des 2 hooks corrigé, silencieux en nominal / utile sur dérive, sans `--exclude` redondant | §Architecture Patterns Pattern 6 ; §Code Examples Ex.5/Ex.8 ; §Common Pitfalls Pitfall 1 ; D-18..D-23 |
| SC7 | Gouvernance tenue : `check-agents.sh` vert, densité ADR-029, portabilité macOS+Linux prouvée, modules bumpés, release taggée | §Validation Architecture ; D-25, D-26 |

</phase_requirements>

## Summary

Cette phase ne touche **aucune dépendance externe** : c'est une phase de gouvernance interne sur le
propre outillage bash/Python/frontmatter-YAML du repo VibeFlow (agents Claude Code, gates de
conformité, DAG de mission). Il n'y a ni package npm à auditer, ni framework à choisir : le travail
consiste à **modifier 5 changements indépendants** dans des fichiers déjà écrits, en suivant des
patrons **déjà présents ailleurs dans le repo** — c'est le fil rouge de toute cette recherche : chaque
changement a un précédent exact à répliquer, jamais à inventer.

**Vérification sur pièce (2026-07-29)** : les 15 fichiers listés dans `<canonical_refs>` de
`20-CONTEXT.md` ont été relus intégralement. **Zéro dérive** entre le CONTEXT (daté du 2026-07-28) et
l'état actuel du repo — tous les numéros de ligne, citations exactes et constats tiennent encore.
Cette recherche ajoute donc uniquement : (1) la confirmation empirique de chaque référence, (2) les
patrons de code à répliquer pour chacun des 5 changements, (3) le contrat de test/validation attendu
par le repo, (4) une mise en garde sur le seul point non vérifiable sans exécution réelle (le nommage
des outils XcodeBuildMCP, hors périmètre).

**Primary recommendation :** traiter chaque changement comme une **extension additive d'un mécanisme
existant** — jamais une réécriture. Changement 1 étend `inject-mcp-tools.sh` (nouveau mode, pas de
nouveau script). Changement 2 généralise le nœud `revue-N` déjà posé dans
`mission-cross-team.md:44`. Changement 3 ajoute un champ `--scope` rétro-compatible au schéma JSON de
`dag.sh` déjà stable depuis ADR-053. Changement 3bis (`MISSION-INVARIANTS.md`) recycle le gabarit de
`check-doc-drift.sh` (advisory, `--path`/`--hook`/`--quiet`, exits 0/3/64). Changement 5 réutilise
`--third-party-prefix` déjà livré en Phase 16 plutôt que d'en inventer un second. Le seul geste
vraiment nouveau est le test « chemin par défaut sans `--agents-dir` » (D-24) — car c'est
précisément l'angle mort qui a laissé le bug de scope survivre à toute la Phase 16.

## Architectural Responsibility Map

Ce repo n'a pas de tiers Browser/SSR/API/DB classiques — c'est un plugin Claude Code qui pose des
agents, des gates bash et un fragment de hooks dans le `.claude/` d'un lab cible. La carte
d'architecture pertinente ici est **la couche d'exécution Claude Code** :

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Accès MCP fin de `vf-reviewer` | Frontmatter agent (`tools:`) + script d'install (`inject-mcp-tools.sh`) | Doctrine (ADR-051) | Le runtime Claude Code lit le `tools:` au démarrage de session ; le script d'install le pose, l'ADR documente le pourquoi |
| Écart `tools:`/runtime (les deux sens) | Frontmatter agent (`disallowedTools:`) | Doctrine (`team-kernel.md`, `README.md`) | `disallowedTools` est une vraie barrière runtime (contrairement à l'allowlist `Agent(...)`) ; la doctrine doit décrire ce que le runtime fait réellement, pas ce qu'on souhaiterait |
| Revue en étage de premier rang | Orchestration (`dag.sh` + `vf-dev-manager.md`) | Contrat worker (`vf-coder.md`, `vf-reviewer.md`) | Le DAG pilote le contrôle de flux ; les agents ne décrivent que leur propre cycle |
| `--scope` sur `dag.sh` | Kernel transverse (`plugin/conductor/scripts/dag.sh`) | Consommateur (`vf-dev-manager.md`, `mission-cross-team.md`) | `dag.sh` est mandatory et partagé par tous les métiers (team-kernel) — le champ doit être générique, le consommateur dev-orchestrator l'utilise |
| `MISSION-INVARIANTS.md` | Planning du lab (`.planning/`) | Lecture manager (`vf-dev-manager.md`) | Fichier de planning, pas de code — lu au même titre que `STATE.md` |
| Scope des 2 hooks + charset MCP | Gates machine (`check-agents.sh`, `check-debug-research.sh`) | Câblage (`hooks.json`, `merge-hooks.sh`) | Les gates portent la logique ; `hooks.json` ne fait que passer les bons flags via un placeholder déjà résolu ailleurs |

**Aucune capability de cette phase ne franchit une frontière réseau ou une base de données** — tout
vit dans des fichiers `.md`/`.json`/`.sh` du repo, lus/écrits par le CLI Claude Code lui-même ou par
git/CI. C'est pourquoi le §Environment Availability et le §Package Legitimacy Audit ci-dessous sont
volontairement minces.

## Project Constraints (from CLAUDE.md)

**Racine `~/Documents/dev/CLAUDE.md`** : n'a pas d'effet direct ici (ce sous-projet a son propre
CLAUDE.md qui prime). Note transverse pertinente : commits en français, cohérents avec l'historique.

**`vibeflow-os/CLAUDE.md`** — directives contraignantes pour tout plan de cette phase :

1. **Discipline de release non négociable** : toute release = un tag. Bump cohérent dans `VERSION`,
   `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, badges/historique des 2
   README (EN+FR). Tag annoté `vX.Y.Z` créé et poussé **après** le merge sur `main`. Release GitHub
   créée avec `--verify-tag`. Vérification finale : `bash scripts/check-release-tag.sh --remote` → `✓`.
2. **Numérotation** : nouveau module/capacité → **minor** ; correctif/doc/durcissement → **patch**
   (cohérent avec D-25, qui laisse l'arbitrage patch/minor au planner par fichier).
3. **Densité (ADR-029)** : agents ≤ 250 lignes, skills ≤ 500 lignes, bootstrap ≤ 2000 tokens. Les
   fichiers `vf-dev-manager.md` (192 lignes actuelles) et `vf-coder.md` (66 lignes) ont de la marge
   pour les ajouts prévus (D-09, D-11) ; `vf-reviewer.md` (41 lignes) idem.
4. **ADR-031** : jamais de fix sans validation humaine — s'applique à toute correction du charset MCP
   (D-22) ou de scope de hook (D-18) : le planner doit prévoir un `checkpoint:human-verify` avant
   fusion, cohérent avec les gates de plan-checker habituels du repo.
5. **ADR-044** : agents natifs machine-enforced — tout agent posé (y compris `vf-reviewer.md` modifié)
   DOIT repasser `check-agents.sh --strict` avant toute release.
6. **Commits en français**, cohérents avec l'historique du repo (`type(scope): résumé`).

## Standard Stack

Ce repo n'utilise **aucune bibliothèque runtime tierce** pour cette phase — tout est bash 3.2+
portable et Python 3 inline (`python3 -c "..."` heredocs), déjà en place. Il n'y a **aucune nouvelle
dépendance à installer**.

### Core (déjà en place, aucune nouvelle capacité)

| Outil | Version | Rôle dans cette phase | Statut |
|-------|---------|------------------------|--------|
| bash | 3.2+ (macOS) / 5.x (Linux CI) | Tous les scripts modifiés (`dag.sh`, `check-agents.sh`, `check-debug-research.sh`, `hooks.json`) | [VERIFIED: exécution locale — patrons déjà utilisés dans tout `plugin/`] |
| python3 | 3.x, résolu par chemin (ADR-054, rejet stub WindowsApps) | Cœur de parsing frontmatter/JSON dans `check-agents.sh`, `dag.sh`, `inject-mcp-tools.sh` | [VERIFIED: `command -v python3` déjà utilisé dans les 3 scripts touchés] |
| git | toute version récente | `check-doc-drift.sh` (patron de référence pour le script de zone morte, D-15) | [VERIFIED: `git_safe()` wrapper déjà en place, durcissement `-c core.fsmonitor=` etc.] |

### Supporting

Aucune bibliothèque supplémentaire n'est requise. Le seul « nouveau service » évoqué dans le cadrage
(serveur MCP `XcodeBuildMCP`) est **hors périmètre d'exécution** de cette phase (D-03, deferred) : le
repo lui-même n'a pas de `.mcp.json`, donc rien à installer ici — seule l'écriture du mécanisme
d'injection (best-effort, silence si absent) est dans le périmètre.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extension additive de `inject-mcp-tools.sh` (D-05) | Nouveau script dédié `inject-mcp-tools-reviewer.sh` | Rejeté — dupliquerait la logique de parsing frontmatter déjà écrite (tokenisation, idempotence, `--verify`), violerait DRY pour un besoin qui est un cas particulier du même problème |
| Champ `review_regime` écrit par `dag.sh reopen` (D-14) | Consigne de prompt seule dans `vf-dev-manager.md` | Rejeté par Samuel — "meilleur rapport garantie/coût" ; le repo a une préférence documentée pour l'enforcement machine plutôt que la doctrine seule quand c'est possible (`software-architecture` axiome "enforcement > prose") |
| `--scope` additif sur `dag.sh add` (D-13) | Fichier séparé de mapping nœud→périmètre | Rejeté implicitement — casserait le patron actuel où `dag.sh` porte tout l'état du nœud dans un seul objet JSON |

**Installation :** rien à installer — tous les fichiers modifiés existent déjà sur disque.

**Version verification :** N/A — aucun package registry concerné.

## Package Legitimacy Audit

**Non applicable.** Cette phase n'installe aucun package externe (npm/pip/cargo). Tous les fichiers
touchés sont internes au repo `vibeflow-os` (agents `.md`, scripts `.sh` avec Python inline, JSON de
config). Le seul nom de service tiers mentionné (`XcodeBuildMCP`) est un serveur MCP configuré par
l'utilisateur final dans son propre lab — VibeFlow ne l'installe ni ne le référence en dur (principe
générique de l'ADR-051, réaffirmé par D-01/D-05) : aucune vérification de légitimité de package n'a
donc de sens ici.

**Packages removed due to [SLOP] verdict :** aucun (aucun package concerné).
**Packages flagged as suspicious [SUS] :** aucun.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│  SessionStart (hooks.json)                                              │
│    ├─ guard-agent-write.sh   (PreToolUse:Write, bloquant si non conf.)  │
│    ├─ check-agents.sh --hook --agents-dir=X --skills-dir=Y  (D-18)      │
│    ├─ check-debug-research.sh --hook --agents-dir=X --skills-dir=Y      │
│    └─ update-banner.sh                                                  │
└─────────────────────────────────────────────────────────────────────────┘
                       │ (résolution {{VF_SCRIPTS}} par merge-hooks.sh:167)
                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Mission d'équipe (vf-dev-manager, pilote unique)                       │
│                                                                           │
│   dag.sh init → dag.sh add --scope=<globs> (D-13) → dag.sh ready        │
│                       │                                                  │
│         ┌─────────────┴─────────────┐                                   │
│         ▼                           ▼                                   │
│    exec-N (vf-coder :             ┌─────────────────────────┐          │
│    Cadrage→Plan→Exécution,        │  revue-N (D-10, D-11)    │          │
│    PLUS de revue interne)  ──────▶│  vf-reviewer DIRECT      │          │
│                                    │  (+ mcp__XcodeBuildMCP__ │          │
│                                    │   test_sim/build_sim/    │          │
│                                    │   clean, D-01)           │          │
│                                    └───────────┬───────────────┘        │
│                                                 │ gaps_found            │
│                                                 ▼                       │
│                                    fix ciblé (vf-coder) → re-revue      │
│                                    (3 tours max, budget → escalade)     │
│                                                 │ passed                │
│                                                 ▼                       │
│                          dag.sh reopen (D-14 : review_regime="full"     │
│                          forcé sur tout revue-*/join rouvert)           │
│                                                                           │
│   Jointure de lots parallèles (D-12) :                                  │
│   exec-A ╲                                                              │
│           ╲──▶ join (lit l'union des 2 diffs) ──▶ revue PLEINE          │
│   exec-B ╱      (déclenché par topologie DAG, jamais intersection      │
│                   de fichiers)                                          │
└─────────────────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  .planning/MISSION-INVARIANTS.md (D-15)                                 │
│    §1 Zones de risque (globs, falsifiable par script "zone morte")      │
│    §2 Table des fichiers gelés — PAS recopiée, dérivée à la demande     │
│        du --scope des nœuds blocked/en cours dans dag-*.json            │
│    §3 [non gaté] contrainte d'outillage du moment (D-16)                │
└─────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

Aucun nouveau dossier — tous les fichiers modifiés existent déjà à leur emplacement canonique :

```
plugin/
├── conductor/
│   ├── scripts/
│   │   ├── dag.sh                        # + --scope, review_regime sur reopen
│   │   ├── check-agents.sh               # + charset regex D-22, --hook warnings D-21
│   │   ├── check-debug-research.sh       # + --agents-dir/--skills-dir défaut via hooks.json,
│   │   │                                 #   + --third-party-prefix (porté de check-agents.sh)
│   │   └── tests/
│   │       ├── test-check-agents.sh      # + cas "défaut sans --agents-dir" (D-24)
│   │       ├── test-check-debug-research.sh  # idem
│   │       └── test-dag.sh               # + cas --scope, reopen review_regime
│   ├── hooks/hooks.json                  # + --agents-dir/--skills-dir explicites (D-18)
│   └── references/team-kernel.md         # doctrine corrigée (D-08, D-09)
├── dev-orchestrator/
│   ├── agents/
│   │   ├── vf-reviewer.md                # + accès MCP fin (D-05, via inject-mcp-tools.sh)
│   │   ├── vf-dev-manager.md             # + nœud revue-N systématique, AskUserQuestion fallback
│   │   └── vf-coder.md                   # cycle 4→3 étapes (retrait Revue)
│   ├── references/
│   │   ├── mission-cross-team.md         # patron revue-N déjà posé, généralisé (pas modifié)
│   │   └── mission-contracts.md          # inchangé dans son format (D-17)
│   └── scripts/inject-mcp-tools.sh       # + mode nommé pour vf-reviewer (D-05)
├── design-orchestrator/agents/vf-design-judge.md      # + disallowedTools: Write, Edit
├── business-pilot-bundle/agents/quality-gate-client.md # + disallowedTools: Write, Edit
├── content-bundle/agents/content-clarity-judge.md      # + disallowedTools: Write, Edit
└── growth-bundle/agents/growth-quality-judge.md        # + disallowedTools: Write, Edit

docs/ADR.md              # révision ADR-051 (Changement 1) + nouvel ADR-060 (Changement 2)
.planning/MISSION-INVARIANTS.md   # NOUVEAU fichier (Changement 3)
```

### Pattern 1 : Extension additive d'un script d'install existant (Changement 1, D-05)

**What :** ajouter un mode « named-tool, single-server » à `inject-mcp-tools.sh` sans toucher au mode
existant (wildcard-serveur, utilisé par `vf-coder` et mobile-test-team).
**When to use :** un agent a besoin d'un sous-ensemble nommé d'UN serveur MCP précis, alors que le
mécanisme existant injecte tout serveur déclaré en wildcard.
**Example (squelette, D-05 laisse le nom du marqueur au planner) :**

```bash
# Source: plugin/dev-orchestrator/scripts/inject-mcp-tools.sh (existant, lignes 149-166)
# Nouveau sélecteur, analogue à FLAG_RE existant :
NAMED_FLAG_RE = re.compile(r"^vf-mcp-consumer:\s*xcodebuildmcp-review-only\s*$", re.M)
NAMED_TOKENS = ["mcp__XcodeBuildMCP__test_sim", "mcp__XcodeBuildMCP__build_sim",
                "mcp__XcodeBuildMCP__clean"]

def has_named_flag(text):
    span, lines = frontmatter_block(text)
    if span is None:
        return False
    fm = "\n".join(lines[span[0]:span[1]])
    return bool(NAMED_FLAG_RE.search(fm))

# Dans la boucle de découverte des fichiers cibles (mode dossier), un fichier avec le marqueur
# nommé reçoit NAMED_TOKENS au lieu de want_tokens (wildcard) — SEULEMENT si le serveur détecté
# dans .mcp.json s'appelle "XcodeBuildMCP" (matching insensible ou exact — à trancher par le
# planner). Absent du .mcp.json → no-op silencieux, comme le reste du mécanisme (best-effort).
```

Ceci respecte exactement la garantie D-05 : `vf-reviewer.md` source ne change jamais son `tools:`
littéral ; seul le frontmatter porte un marqueur qui bascule le comportement du script d'install.

### Pattern 2 : `disallowedTools` pour fermer l'écart `tools:`/runtime (Changement Critère 2, D-06)

**What :** ajouter `disallowedTools: Write, Edit` au frontmatter des 4 juges — le champ est déjà
connu du gate (`check-agents.sh` KNOWN, ligne 154-156), aucun changement de gate requis.
**When to use :** un agent doit rester read-only malgré `memory: project` qui rouvrirait Write/Edit
au runtime.
**Example :**

```yaml
# Source: plugin/design-orchestrator/agents/vf-design-judge.md (frontmatter actuel, ligne 4-6)
---
name: vf-design-judge
description: ...
tools: Read, Bash, Glob, Grep
disallowedTools: Write, Edit
model: sonnet
memory: project
vf-internal: true
---
```

Même patron pour `quality-gate-client.md`, `content-clarity-judge.md`, `growth-quality-judge.md`
(ces 3 n'ont même pas `Bash`, donc `disallowedTools: Write, Edit` ferme leur read-only *complètement*
— contrairement à `vf-design-judge` qui garde `Bash`, cf. D-07).

### Pattern 3 : Généraliser un nœud DAG déjà posé pour un autre métier (Changement 2, D-10)

**What :** le patron `revue-N` (dep=`exec-N`, dispatch direct de `vf-reviewer`) existe déjà dans
`mission-cross-team.md:36-45` pour l'étage design croisé. Ce changement le rend **systématique** pour
toute mission dev, plutôt que conditionnel à un étage design.
**When to use :** chaque fois que le manager pose un nœud d'exécution `exec-N`, il pose désormais
*aussi* `revue-N` en dépendance directe — retiré de `vf-coder.md` §Le cycle.
**Example :**

```bash
# Source: plugin/dev-orchestrator/references/mission-cross-team.md:44 (déjà écrit, à généraliser)
"$S"/dag.sh add --file="$DAG" --id=exec-N   --step="exécution étape N" --deps=plan-N --scope="src/module-x/**"
"$S"/dag.sh add --file="$DAG" --id=revue-N  --step="revue code étape N" --deps=exec-N
# Dispatch : vf-reviewer DIRECTEMENT (jamais via vf-coder) sur le nœud revue-N.
# Sur gaps_found : dispatch vf-coder en mandat FIX CIBLÉ (pas un cycle complet), puis
# dag.sh reopen --id=revue-N → re-dispatch vf-reviewer, jusqu'à 3 tours.
```

### Pattern 4 : Champ `--scope` additif et rétro-compatible sur `dag.sh` (Changement 3, D-13/D-14)

**What :** ajouter un cinquième champ (`scope: []`) au schéma de nœud, suivant exactement le patron
déjà utilisé pour `--deps` (parsing `arg` en boucle, split sur `,`).
**Example (squelette d'implémentation, forme exacte au planner) :**

```bash
# Source: plugin/conductor/scripts/dag.sh — patron actuel pour --deps (lignes 26-39, 99)
# Ajouter au parsing d'arguments (ligne ~26-38) :
    --scope=*)  SCOPE="${arg#*=}" ;;
# Ajouter au sys.argv du bloc python3 (ligne 44) et à la signature (ligne 47) :
#   action, file, nid, step, stage, deps_raw, status, scope_raw = sys.argv[1:9]
# Dans le bloc "add" (ligne 88-108), après le calcul de `deps` :
    scope = [s.strip() for s in scope_raw.split(",") if s.strip()]
    node = {"id": final, "step": step, "stage": stage, "deps": deps, "scope": scope, "status": "blocked"}
# Rétro-compatibilité : un nœud EXISTANT sans "scope" dans le JSON doit être lu comme [] partout
# où le champ est consommé (ex. node.get("scope", [])), jamais un KeyError.

# Pour D-14 (reopen force review_regime="full") — dans le bloc "reopen" (lignes 127-149) :
    for d in affected:
        idx[d]["status"] = "blocked"
        if idx[d]["id"].startswith(("revue-", "join")):  # forme exacte du sélecteur au planner
            idx[d]["review_regime"] = "full"
    if idx[nid]["id"].startswith(("revue-", "join")):
        idx[nid]["review_regime"] = "full"
```

### Pattern 5 : Gate advisory sur le modèle `check-doc-drift.sh` (D-15, script de « zone morte »)

**What :** `check-doc-drift.sh` est le patron canonique de script advisory de ce repo : lecture seule,
`--path`/`--hook`/`--quiet`, exits `0` (signal) / `3` (rien à signaler) / `64` (argument invalide),
jamais de jugement (« FAIT vs JUGEMENT », ADR-055 §3). Le script de « zone morte » pour
`MISSION-INVARIANTS.md` doit suivre exactement ce contrat : il **constate** qu'un glob ne matche plus
aucun fichier (`find`/`git ls-files` + comparaison), il ne **décide** jamais de le retirer.
**Example de squelette (chemin exact au planner — extension `dag.sh`-adjacent ou nouveau script) :**

```bash
# Squelette calqué sur check-doc-drift.sh (structure, pas contenu — glob check au lieu de git log)
# Usage: check-mission-invariants.sh [--path <dir>] [--hook] [--quiet]
# Pour chaque glob de la §1 "Zones de risque" de MISSION-INVARIANTS.md :
#   git ls-files -- '<glob>' | wc -l   # 0 = zone morte
# Exit 0 = au moins une zone morte détectée (signal [mission-invariants-drift])
# Exit 3 = tous les globs matchent encore au moins un fichier (rien à signaler)
# Exit 64 = argument invalide / fichier MISSION-INVARIANTS.md absent ou illisible
```

### Pattern 6 : Réutiliser `--third-party-prefix` plutôt qu'en inventer un second (Changement 5, D-20)

**What :** `check-agents.sh` porte déjà `--third-party-prefix` (défaut `gsd-`, accumulatif, Phase 16).
`check-debug-research.sh` ne l'a pas. Le fix est de **porter le même mécanisme**, pas d'en écrire un
nouveau — critère 6 du ROADMAP interdit explicitement un second mécanisme d'exclusion.
**Example :** répliquer dans `check-debug-research.sh` la logique de `check-agents.sh:84,96-100,580-
586` (variable `THIRD_PARTY_PREFIXES`, parsing `--third-party-prefix=*`/`--no-third-party-prefix`,
filtrage par `dname.startswith(pfx)` avant `check_file()`).

### Anti-Patterns to Avoid

- **Réinventer un script d'injection MCP dédié pour `vf-reviewer`** (au lieu d'étendre
  `inject-mcp-tools.sh`) — dupliquerait toute la mécanique de parsing frontmatter/idempotence déjà
  écrite et testée (10 cas dans `test-inject-mcp-tools.sh`).
- **Retirer `Bash` de `vf-design-judge`** pour "vraiment" le rendre read-only — explicitement écarté
  par D-07 (retrait non demandé, `Bash` probablement utile pour captures d'écran/inspection).
- **Un second flag d'exclusion différent sur `check-debug-research.sh`** (ex. `--exclude-prefix`) —
  interdit par le critère 6 du ROADMAP et par D-20.
- **Copier statiquement la table des fichiers gelés dans `MISSION-INVARIANTS.md`** — Samuel l'a
  explicitement écarté (D-15) : « s'il ment, il est pire que rien ». Le fichier documente une
  convention de lecture dynamique, jamais un instantané figé.
- **Un `review_regime` décidé par consigne de prompt seule** — D-14 exige l'enforcement machine
  (champ écrit par `dag.sh reopen` lui-même), cohérent avec l'axiome du repo « enforcement > prose ».

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Restreindre les outils MCP d'un agent | Un patch manuel du frontmatter à l'install | `inject-mcp-tools.sh` étendu (nouveau mode) | Idempotence, best-effort, `--verify` déjà écrits ; dupliquer casserait la garantie « un seul point de vérité pour l'injection MCP » |
| Empêcher un juge d'écrire | Une convention de prompt seule (« ne modifie jamais ») | `disallowedTools: Write, Edit` (barrière runtime réelle, prouvée par sonde A/B/C) | Le repo a déjà mesuré que `memory: project` rouvre Write/Edit malgré l'absence de `Write`/`Edit` dans `tools:` — la doctrine seule ne suffit pas |
| Filtrer les agents/skills tiers d'un lint | Un nouveau flag `--exclude`/`--ignore-pattern` | `--third-party-prefix` existant, porté à `check-debug-research.sh` | Deux mécanismes concurrents pour le même problème = dette immédiate ; le critère 6 du ROADMAP l'interdit explicitement |
| Détecter une doc périmée | Une heuristique de contenu (comparaison sémantique) | Le patron `check-doc-drift.sh` (compte de commits depuis le dernier commit de doc, jamais un jugement de véracité) | ADR-055 §3 « FAIT vs JUGEMENT » : un script constate, il ne juge jamais qu'une doc est fausse |
| Garantir « pas de revue allégée après reopen » | Une note dans `mission-flow.md` seule | Champ `review_regime` écrit par `dag.sh reopen` | Cohérent avec la préférence documentée du repo pour l'enforcement machine sur les invariants non négociables de la phase |

**Key insight :** dans ce repo, **chaque geste de gouvernance a déjà un précédent exact** posé lors
d'une phase antérieure (Phase 15 pour le DAG mixte cross-métier, Phase 16 pour le lint des allowlists
et `--third-party-prefix`, Phase 17 pour le patron `check-doc-drift.sh`, Phase 19 pour l'injection MCP
best-effort). Le risque principal de cette phase n'est pas technique — c'est de **réinventer** un
mécanisme déjà écrit plutôt que de l'étendre, ce qui romprait la cohérence inter-modules que ces
phases ont patiemment construite.

## Common Pitfalls

### Pitfall 1 : Le piège de mesure — corriger le scope sans tester le chemin par défaut (D-24)

**What goes wrong :** un fix de `AGENTS_DIR`/`SKILLS_DIR` (D-18/D-19) semble correct en lecture, mais
la suite de tests ne l'exerce jamais réellement — `run_check()` dans les deux suites
(`test-check-agents.sh:94`, `test-check-debug-research.sh:36`) passe TOUJOURS `--agents-dir="$AG"
--skills-dir="$SK"` en dur. Un bug de scope peut donc survivre indéfiniment à une suite 100% verte.
**Why it happens :** les tests ont été écrits pour isoler l'environnement de test (`mktemp -d`), ce
qui est la bonne pratique générale — mais personne n'a ajouté un cas qui teste explicitement
l'ABSENCE de ces flags (le vrai comportement en usage réel via `hooks.json`).
**How to avoid :** tout plan qui touche D-18/D-19/D-20 DOIT ajouter un cas dédié : `cd` dans un
répertoire de test sans `.claude/agents`, invoquer `check-agents.sh` **sans** `--agents-dir` ni
`--skills-dir`, et vérifier que le comportement par défaut est celui attendu (silence propre, ou
détection réelle si un `.claude/agents` existe au bon endroit relatif).
**Warning signs :** une revue qui ne relit que le diff de `check-agents.sh`/`check-debug-research.sh`
sans relire aussi `run_check()` dans les fichiers de test — c'est exactement l'angle mort qui a
laissé le bug survivre à toute la Phase 16 (constaté par l'audit source de cette phase).

### Pitfall 2 : Faux vert du mode `--hook` après le seul fix de scope (D-21)

**What goes wrong :** corriger UNIQUEMENT le scope (D-18) sans lever l'exemption `--hook` sur le
contrat anti-vert-à-vide produit un résultat pire que l'état actuel : le hook trouve maintenant 21-27
warnings réels, mais `check-agents.sh:568,571` (`if not hook: ...`) les masque tous — 0 ligne imprimée
malgré un signal réel présent.
**Why it happens :** le mode `--hook` a été conçu à l'origine pour être bruit-minimal (voulu), à une
époque où le scope cassé garantissait de toute façon 0 finding — les deux défauts se compensaient
silencieusement.
**How to avoid :** implémenter le fix D-21 dans le MÊME commit que D-18 (jamais l'un sans l'autre) —
conditionner l'affichage des warnings en mode `--hook` au compte réel (`if warning_count > 0:
print(...)`), sur le modèle du contrat de sortie de `update-banner.sh` (silence nominal,
`systemMessage` seulement s'il y a quelque chose à dire).
**Warning signs :** un plan qui découpe D-18 et D-21 en deux tâches/commits séparés sans dépendance
explicite entre eux — le premier commit isolé produirait un régime transitoire de faux vert.

### Pitfall 3 : `build_sim` en cache masque une compilation qui n'a pas eu lieu

**What goes wrong :** le serveur XcodeBuildMCP peut répondre « 0 warning » sur un `build_sim` qui n'a
en réalité rien compilé (cache chaud, aucune tâche `SwiftCompile`) — un verdict de revue basé sur ce
seul appel est structurellement invérifiable.
**Why it happens :** le mécanisme de cache de build est transparent à l'appelant — rien ne distingue
« zéro warning parce que tout est propre » de « zéro warning parce que rien n'a tourné ».
**How to avoid :** c'est précisément pourquoi D-01 inclut `clean` dans l'allowlist de `vf-reviewer` —
le protocole de revue attendu (à documenter dans ADR-051 révisée, D-02) doit imposer un `clean` avant
tout `build_sim`/`test_sim` de vérification. Ce protocole vit dans le corps de `vf-reviewer.md`
(prompt), pas dans le mécanisme d'injection.
**Warning signs :** un ADR-051 révisé qui documente l'accès aux 3 outils sans jamais préciser l'ORDRE
d'appel attendu (`clean` puis `build_sim`/`test_sim`) laisserait la faille ouverte malgré l'accès.

### Pitfall 4 : `XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS` — un `SessionStore` global partagé

**What goes wrong :** sans ce flag, XcodeBuildMCP n'a qu'un seul `SessionStore` partagé par la fenêtre
principale ET tous les sous-agents — un `build_sim`/`test_sim` sans paramètres explicites de projet
peut s'exécuter sur le code d'un AUTRE worktree que celui attendu (déjà observé sur le lab
`ExploreSomfy`, cf. ROADMAP §Phase 20 fin de section).
**Why it happens :** le serveur MCP maintient un état de session global côté serveur, invisible du
prompt de l'agent qui l'appelle.
**How to avoid :** documenter dans ADR-051 révisée (ou une note dédiée) que **chaque appel de build
doit porter `projectPath`/`scheme`/`simulatorId`/`deviceId` explicitement** — ne jamais compter sur
un défaut de session. Ce point est **déjà appliqué côté lab** (2026-07-28) mais n'est pas encore
documenté côté VibeFlow (référencé au ROADMAP comme "à ne pas refaire côté lab, à propager côté
doctrine").
**Warning signs :** un plan qui ajoute l'accès MCP à `vf-reviewer` sans mentionner cette exigence de
paramètres explicites dans le corps de l'agent ou la révision d'ADR-051.

### Pitfall 5 : Confondre l'allowlist `Agent(...)` (contrat lint) et une vraie barrière runtime

**What goes wrong :** le runtime Claude Code **ignore** la liste de noms entre parenthèses d'une
allowlist `Agent(x, y)` pour tout agent dispatché en sous-agent (confirmé par la doc officielle,
citée verbatim dans l'en-tête de `check-agents.sh:8-18`) — ce n'est un vrai bac à sable que pour un
agent incarné en thread principal (`claude --agent`). Un plan qui présenterait cette allowlist comme
une garantie runtime pour `vf-dev-manager`/`vf-coder` (dispatchés en sous-agents) serait trompeur.
**Why it happens :** l'intuition naturelle est qu'une syntaxe de restriction déclarée = une
restriction appliquée — ce n'est vrai qu'à moitié ici (contrat + lint, pas sandbox).
**How to avoid :** ne présenter l'allowlist `Agent(...)` que comme ce qu'elle est — un contrat
documenté et lint-vérifié — et rappeler que le **verrou de driver** (`driver-lock.sh`) reste le seul
garant machine réel de "un seul manager actif" (déjà la doctrine de `team-kernel.md:23,67-71`).
Pertinent ici car D-11 modifie `vf-coder.md`, un des 3 workers dont l'allowlist ferme le chemin
indirect manager→worker→manager (Phase 16) — le planner ne doit pas casser cette allowlist en
modifiant le cycle.

## Code Examples

### Ex.1 — Frontmatter cible de `vf-reviewer.md` après injection (runtime, PAS le fichier source)

```yaml
# Source: plugin/dev-orchestrator/agents/vf-reviewer.md (fichier SOURCE, INCHANGÉ, D-05)
# Après injection best-effort par inject-mcp-tools.sh (RUNTIME uniquement, jamais commité) :
tools: Read, Bash, Glob, Grep, Agent(gsd-code-reviewer), mcp__XcodeBuildMCP__test_sim, mcp__XcodeBuildMCP__build_sim, mcp__XcodeBuildMCP__clean
```

### Ex.2 — Frontmatter cible des 4 juges (D-06, fichier SOURCE modifié cette fois)

```yaml
# Source: plugin/design-orchestrator/agents/vf-design-judge.md — AVANT (ligne 4)
tools: Read, Bash, Glob, Grep
# APRÈS (D-06) :
tools: Read, Bash, Glob, Grep
disallowedTools: Write, Edit
```

### Ex.3 — Retrait de l'étape 4 dans `vf-coder.md` (D-11)

```markdown
# Source: plugin/dev-orchestrator/agents/vf-coder.md — AVANT (lignes 23-39)
## Le cycle (délégation)
Enchaîne les sous-phases en déléguant à la machinerie existante :
1. **Cadrage** : ...
2. **Plan** : ...
3. **Exécution** : ...
4. **Revue** : dispatche l'agent `vf-reviewer` (outil Agent) sur le diff de l'étape. S'il
   remonte des correctifs bloquants, boucle : fix ciblé (via la machinerie d'exécution) puis
   re-revue, jusqu'au PASS ou budget (3 tours max — au-delà, remonte au manager).

# APRÈS (D-11) :
## Le cycle (délégation)
Enchaîne les sous-phases en déléguant à la machinerie existante :
1. **Cadrage** : ...
2. **Plan** : ...
3. **Exécution** : ... (dernier appel du cycle — la revue n'est plus dispatchée par vf-coder,
   elle vit désormais comme nœud DAG `revue-N` piloté directement par vf-dev-manager)
```

Note : le retrait du texte de l'étape 4 réduit `vf-coder.md`, l'allowlist `Agent(vf-reviewer, ...)`
reste inchangée dans le `tools:` du frontmatter (elle sert encore, ex. remontée d'un besoin de
recherche) — ne pas la retirer par erreur en supprimant le texte du cycle.

### Ex.4 — Réécriture de « pas de double revue » dans `vf-dev-manager.md` (D-10)

```markdown
# Source: plugin/dev-orchestrator/agents/vf-dev-manager.md — AVANT (lignes 107-110)
Entre les étages : un compte rendu qui révèle une décision → panel. Des correctifs remontés par
la revue ou l'audit → renvoyés à `vf-coder` (jamais corrigés par toi). **Pas de double revue** :
si le rapport typé de `vf-coder` est `passed` avec verdict revue PASS, ne re-dispatche pas de
revue de code sur la même étape — seuls Test/Audit s'ajoutent.

# APRÈS (D-10, D-11 — forme exacte laissée au planner, esprit à préserver) :
Entre les étages : un compte rendu qui révèle une décision → panel. Des correctifs remontés par
la revue ou l'audit → renvoyés à `vf-coder` (jamais corrigés par toi). **La revue est un nœud DAG
`revue-N` systématique** (deps=`exec-N`), dispatchée directement (jamais via `vf-coder`) : sur
`gaps_found`, `dag.sh reopen --id=revue-N` puis dispatch `vf-coder` en mandat FIX CIBLÉ uniquement
(pas un cycle complet), jusqu'au PASS ou budget (3 tours max — au-delà, escalade).
```

### Ex.5 — `hooks.json` avec scope explicite (D-18)

```json
// Source: plugin/conductor/hooks/hooks.json — AVANT
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-agents.sh --hook || true" },
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-debug-research.sh --hook || true" },

// APRÈS (D-18, D-19 — chemin relatif au dossier scripts, {{VF_SCRIPTS}} déjà résolu par merge-hooks.sh:167)
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-agents.sh --hook --agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills || true" },
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-debug-research.sh --hook --agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills || true" },
```

### Ex.6 — Warning conditionnel en mode `--hook` (D-21)

```python
# Source: plugin/conductor/scripts/check-agents.sh — bloc hook actuel (lignes ~590-596)
# AVANT :
if hook:
    if n_err:
        print(f"[check-agents] ✗ {n_err} agent(s) non conforme(s) :")
        for e in errors:
            print(f"  - {e}")
        print("  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh")
    sys.exit(0)

# APRÈS (D-21, ajoute le cas warnings > 0, silence si 0) :
if hook:
    if n_err:
        print(f"[check-agents] ✗ {n_err} agent(s) non conforme(s) :")
        for e in errors:
            print(f"  - {e}")
        print("  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh")
    elif n_warn:
        print(f"[check-agents] ⚠ {n_warn} avertissement(s) (voir bash .claude/scripts/check-agents.sh)")
    sys.exit(0)
```

### Ex.7 — Squelette de `.planning/MISSION-INVARIANTS.md` (D-15/D-16)

```markdown
# Mission Invariants

## Zones de risque (globs, falsifiable machine)

> Un glob qui ne matche plus aucun fichier du repo est une "zone morte" — détecté par
> check-mission-invariants.sh (patron check-doc-drift.sh). Amorcé par le planner avec les
> catégories déjà mesurées par l'audit source du 2026-07-28.

- `plugin/*/scripts/*-adapter.sh`     # adaptateur d'infra non injectable
- ...

## Table des fichiers gelés — lue À LA DEMANDE, jamais recopiée

Cette table N'EST PAS statique. Pour connaître les fichiers actuellement gelés, interroger le
--scope des nœuds `blocked`/en cours des DAG de mission actifs :
  dag.sh status --file=.planning/missions/dag-<mission-active>.json

## [NON GATÉ] Contrainte d'outillage du moment — à revérifier manuellement à chaque mission

> Fait documenté, pas de mécanisme falsifiable pour cette section (D-16).

- XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true requis — SessionStore global partagé sinon.
- Chaque appel build_sim/test_sim DOIT porter projectPath/scheme/simulatorId explicitement.
```

### Ex.8 — Extension du regex charset MCP dans `check-agents.sh` (D-22)

```python
# Source: plugin/conductor/scripts/check-agents.sh:355 (fonction analyze_token) — AVANT
if not re.fullmatch(r"[A-Za-z0-9_-]+", tok):
    errors.append(f"{base} : {field} — token hors charset attendu '{tok}'")
    return None, None

# APRÈS (D-22 — forme exacte laissée au planner, contrainte : accepter UNIQUEMENT un `*` FINAL
# après mcp__<serveur>__, jamais un `*` en milieu de chaîne) :
if not (re.fullmatch(r"[A-Za-z0-9_-]+", tok) or re.fullmatch(r"mcp__[A-Za-z0-9_-]+__\*", tok)):
    errors.append(f"{base} : {field} — token hors charset attendu '{tok}'")
    return None, None
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Revue dans le cycle interne de `vf-coder` (étape 4/4) | Revue = nœud DAG `revue-N` piloté par le manager | Cette phase (D-10/D-11) | Le manager peut graduer la revue par risque (D-12) ; jointures parallèles couvertes systématiquement |
| Wildcard serveur MCP par agent (`mcp__<serveur>__*`) | Allowlist nommée par outil pour `vf-reviewer` (`mcp__XcodeBuildMCP__test_sim` etc.) | Cette phase (D-01/D-03) | Moindre privilège réel, prouvé par sonde A/B/C (l'outil non listé échoue vraiment) |
| Barrière read-only affirmée en prose seule (« Ne corrige JAMAIS rien ») | `disallowedTools: Write, Edit` en frontmatter (barrière runtime réelle) | Cette phase (D-06), suite à la sonde nomem/mem/deny du 2026-07-28 | Ferme l'écart constaté : `memory: project` rouvrait Write/Edit malgré l'absence dans `tools:` |
| `MISSION-INVARIANTS.md` inexistant | Fichier créé, réduit aux éléments falsifiables machine | Cette phase (D-15) | Les 3 invariants nommés au ROADMAP ne survivent que sous forme gatée ou explicitement non gatée (D-16) |
| Scope des hooks `--hook` relatif au cwd (silencieux par accident) | Scope explicite passé par `hooks.json` + warnings affichés si présents | Cette phase (D-18/D-21) | Le hook redevient réellement utile (21+ warnings réels détectés) au lieu d'un faux vert systématique |

**Déprécié/obsolète :**
- L'affirmation « `vf-design-judge` est read-only » sans qualification — devient « sans Write/Edit
  directs ; `Bash` reste accessible » (D-07). L'ancienne formulation était trompeuse depuis que la
  sonde du 2026-07-28 a démontré l'écart `tools:`/runtime.
- La recopie statique d'une contrainte d'invariants dans un `.md` du lab — pattern explicitement
  rejeté par Samuel (précédent d'un `CLAUDE.md` mensonger cité en exemple).

## Assumptions Log

Reprend les deux assumptions déjà signalées « point d'attention manager » dans `20-CONTEXT.md`,
inchangées par cette recherche (aucune nouvelle information disponible pour les trancher sans
exécution réelle ou nouvel arbitrage humain) :

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Le nom du marqueur de frontmatter pour le mode d'injection nommé de `vf-reviewer` (ex. `vf-mcp-consumer: xcodebuildmcp-review-only`) n'est pas tranché — proposition du CONTEXT à valider par le planner (D-05) | Pattern 1, Ex.1 | Faible — c'est un choix de nommage interne, réversible sans casser de contrat externe ; le seul coût d'un mauvais choix est un renommage ultérieur |
| A2 | Les noms d'outils exacts `test_sim`/`build_sim`/`clean` de XcodeBuildMCP n'ont jamais été vérifiés contre un serveur MCP vivant (ce repo n'a pas de `.mcp.json`) — utilisés par cohérence avec la doc du serveur (D-03) | Pattern 1, Common Pitfalls 3/4 | Moyen — si les noms réels diffèrent, l'injection nommée serait un no-op silencieux (best-effort) plutôt qu'une erreur bruyante ; recette humaine déjà planifiée en `<deferred>` |
| A3 | La forme exacte du regex de D-22 (`mcp__[A-Za-z0-9_-]+__\*`) est une proposition, pas une décision verrouillée — le planner peut affiner sans reconsulter Samuel | Ex.8 | Faible — le contrat (rejeter `*` en milieu de token, accepter `*` final après `mcp__<serveur>__`) est verrouillé ; seule la forme regex précise reste discrétionnaire |

**Aucune nouvelle assumption introduite par cette recherche** — chaque claim vérifiable a été confirmé
sur pièce (§Vérification sur pièce, ci-dessus, et toutes les citations exactes de `<user_constraints>`
recoupées avec le code réel le 2026-07-29).

## Open Questions

1. **D-05 — nom exact du marqueur de frontmatter et mécanisme de matching du serveur**
   - What we know : le mécanisme doit être additif à `inject-mcp-tools.sh`, ne jamais toucher le
     `tools:` source de `vf-reviewer.md`, et ne s'activer que si un serveur nommé (ou détecté comme)
     "XcodeBuildMCP" existe dans le `.mcp.json` du lab.
   - What's unclear : le nom exact du marqueur (`vf-mcp-consumer: xcodebuildmcp-review-only` vs une
     liste séparée dans le script, ex. `NAMED_MODE_AGENTS = {"vf-reviewer": [...]}`) et si le matching
     du nom de serveur doit être exact, insensible à la casse, ou par motif.
   - Recommendation : le planner tranche au moment d'écrire le PLAN (pas besoin de re-questionner
     Samuel — signalé « point d'attention manager » mais résolution laissée à l'implémentation, pas à
     une nouvelle décision de doctrine). Privilégier un marqueur en liste séparée dans le script
     (moins de risque de collision de frontmatter que de réutiliser `vf-mcp-consumer:` avec une valeur
     non-booléenne, qui casserait la sémantique actuelle `vf-mcp-consumer: true`).

2. **D-16 — la 3e section non gatée de `MISSION-INVARIANTS.md` concilie-t-elle vraiment le critère 5
   littéral et le principe de D4 ?**
   - What we know : le critère 5 du ROADMAP nomme 4 items (3 invariants + contrainte d'outillage) ;
     D4 (doctrine amont) dit que « tout champ dont le mécanisme n'est pas gaté saute [de la garantie
     machine], pas du fichier ».
   - What's unclear : est-ce que Samuel validerait la lecture "on garde les 4 items mais 1 seul en
     mode non gaté explicite" comme fidèle à D4, ou faudrait-il purement et simplement omettre la
     contrainte d'outillage (comme le seuil de tests) ?
   - Recommendation : suivre D-16 tel quel (inclure en section 3 étiquetée non gatée) — c'est déjà la
     résolution "auto, recommandée" documentée dans le CONTEXT, et elle est cohérente avec la
     transparence exigée par Samuel ailleurs dans la phase (« s'il ment, il est pire que rien »). Si le
     planner ou l'utilisateur veut trancher différemment, c'est un geste d'une ligne (retirer la
     section 3) — ne pas bloquer le plan dessus.

## Environment Availability

Cette phase n'a **aucune dépendance externe nouvelle**. Les 3 outils déjà utilisés par tous les
scripts touchés sont universellement présents dans l'environnement de dev/CI de ce repo :

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | tous les scripts modifiés | ✓ | 3.2.57 (macOS) / 5.2.x (CI Linux) | — (déjà la contrainte de portabilité du repo, ADR-054) |
| python3 | `check-agents.sh`, `dag.sh`, `inject-mcp-tools.sh`, `check-debug-research.sh` | ✓ | résolu par chemin, rejet stub WindowsApps | repli `python` (déjà géré, ADR-054) |
| git | patron `check-doc-drift.sh` pour le script de zone morte | ✓ | toute version récente | — |
| Serveur MCP `XcodeBuildMCP` | accès fin de `vf-reviewer` (D-01) | ✗ dans ce repo (pas de `.mcp.json`) | — | Best-effort : absence → no-op silencieux (D-05) ; recette humaine hors périmètre de cette phase (D-03, `<deferred>`) |

**Missing dependencies with no fallback :** aucune — le seul "manquant" (XcodeBuildMCP) a un fallback
déjà conçu dans le mécanisme (best-effort, silence).

**Missing dependencies with fallback :** XcodeBuildMCP (voir ci-dessus).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash pur, zéro dépendance — helpers `ok()`/`ko()` maison |
| Config file | Aucun (chaque `test-*.sh` est un exécutable autonome) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-dag.sh` (ou la suite ciblée par le changement) |
| Full suite command | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while IFS= read -r t; do bash "$t"; done` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SC1 | `vf-reviewer` reçoit l'accès MCP fin sans polluer `vf-coder`/mobile-test | unit (nouveau mode `inject-mcp-tools.sh`) | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | ✅ suite existante (10 cas) — étendre avec le mode nommé |
| SC1 | Regex charset accepte `mcp__X__*` mais rejette `mcp__X__*Y` | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant — ajouter cas D-22 |
| SC2 | `disallowedTools: Write, Edit` accepté par le gate sans changement | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant (KNOWN déjà couvert), pas de nouveau cas requis |
| SC3/SC4 | `dag.sh add --scope=...` accepté, rétro-compat sur nœuds sans scope | unit | `bash plugin/conductor/scripts/tests/test-dag.sh` | ❌ Wave 0 — ajouter cas `--scope` |
| SC4 | `dag.sh reopen` force `review_regime: full` sur nœuds `revue-*`/`join` | unit | `bash plugin/conductor/scripts/tests/test-dag.sh` | ❌ Wave 0 — ajouter cas reopen+regime |
| SC5 | Script de zone morte détecte un glob qui ne matche plus rien | unit (nouveau script) | `bash plugin/<module>/scripts/tests/test-check-mission-invariants.sh` | ❌ Wave 0 — nouveau fichier, patron `test-check-doc-drift.sh` |
| SC6 | Scope par défaut (sans `--agents-dir`) exercé et vert | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` + `test-check-debug-research.sh` | ❌ Wave 0 — cas manquant (D-24, obligatoire) |
| SC6 | `--hook` silencieux à 0 warning, imprime si > 0 | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ❌ Wave 0 — cas D-21 manquant |
| SC6 | `--third-party-prefix` sur `check-debug-research.sh` filtre correctement | unit | `bash plugin/conductor/scripts/tests/test-check-debug-research.sh` | ❌ Wave 0 — cas manquant (mécanisme n'existe pas encore sur ce script) |
| SC7 | `check-agents.sh --strict` vert sur les 6 dossiers d'agents après tous les changements | gate CI | `check-agents.sh --strict --agents-dir=<d>` (job `gates`, déjà câblé) | ✅ CI existante |
| SC7 | Portabilité macOS + Linux prouvée par exécution | CI | job `tests` (`ubuntu-latest`) + exécution locale macOS | ✅ CI existante — aucune nouveauté requise |

### Sampling Rate

- **Per task commit :** la suite ciblée par le fichier touché (ex. `test-dag.sh` après un edit de
  `dag.sh`).
- **Per wave merge :** `find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t"; done`
  (la boucle exacte de la CI, 37+ suites — le compteur exact doit être resynchronisé si de nouveaux
  fichiers de test sont ajoutés, cf. `check-version-sync.sh` qui vérifie le compteur affiché dans les
  2 README).
- **Phase gate :** full suite verte + `check-agents.sh --strict` sur les 6 dossiers d'agents +
  `check-version-sync.sh` + `check-release-tag.sh --remote` avant `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `plugin/conductor/scripts/tests/test-check-agents.sh` — cas « défaut sans `--agents-dir` »
      (D-24, non négociable) + cas regex `*` final (D-22) + cas warnings conditionnels en `--hook`
      (D-21).
- [ ] `plugin/conductor/scripts/tests/test-check-debug-research.sh` — même cas « défaut sans
      `--agents-dir` » (D-24) + cas `--third-party-prefix` (mécanisme nouveau sur ce script, D-20).
- [ ] `plugin/conductor/scripts/tests/test-dag.sh` — cas `--scope` (D-13) + cas `reopen` avec
      `review_regime: full` forcé (D-14).
- [ ] Nouveau fichier `test-check-mission-invariants.sh` (ou extension de suite existante selon le
      choix d'emplacement du planner, D-15) — cas glob mort détecté / glob vivant silencieux, sur le
      patron exact de `test-check-doc-drift.sh`.
- [ ] Framework install : aucun — bash pur déjà en place, aucune installation de dépendance requise.

*(Gaps réels — aucune infrastructure de test manquante au sens framework, seulement des cas absents
dans des suites déjà robustes)*

## Security Domain

### Applicable ASVS Categories

Ce repo n'est pas une application web/API classique — les catégories ASVS s'appliquent ici par
analogie au modèle de contrôle d'accès entre agents (moindre privilège, séparation des rôles), pas à
une frontière réseau utilisateur.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | N/A — pas d'authentification utilisateur dans le périmètre de cette phase |
| V3 Session Management | oui (analogie) | Le `driver-lock.sh` (verrou de mission, TTL + recovery) est l'équivalent le plus proche d'une session — inchangé par cette phase, mais D-11/D-10 en dépendent implicitement (le manager reste seul pilote) |
| V4 Access Control | **oui — cœur de la phase** | Frontmatter `tools:`/`disallowedTools:` + gate `check-agents.sh` (contrôle statique, ADR-044) ; allowlist MCP nommée par outil (D-01) = principe de moindre privilège appliqué à un agent de vérification |
| V5 Input Validation | oui | Le regex charset MCP (D-22) EST une validation d'entrée sur un token de configuration déclaratif — le resserrer à la forme exacte `mcp__<serveur>__<outil>` reste explicitement hors périmètre requis (D-22 corollaire, Claude's Discretion) |
| V6 Cryptography | non | N/A |

### Known Threat Patterns for {stack de gouvernance d'agents}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Élévation de privilège d'un agent de vérification (le juge devient producteur) | Elevation of Privilege | `disallowedTools: Write, Edit` (D-06) — barrière runtime réelle, pas seulement une consigne de prompt ; déjà le patron du repo pour tous les juges |
| Écart entre le contrat déclaré (`tools:`) et le comportement runtime réel | Tampering (de la confiance dans le contrat) | Documenter explicitement les deux sens de l'écart (D-06 ouverture via `memory:`, D-09 fermeture via absence runtime d'un outil déclaré) plutôt que de laisser le lecteur du frontmatter présumer une garantie qui n'existe pas |
| Un token MCP malformé (`mcp__typo__foo`) passe le lint en silence | Tampering / Spoofing (nom de serveur) | Hors périmètre requis de cette phase (D-22 corollaire) — noté comme dette acceptée, pas une régression introduite ici |
| Un hook `SessionStart` mal scopé masque un vrai signal de non-conformité (faux vert) | Repudiation (le signal de non-conformité n'atteint jamais l'opérateur) | Fix D-18 (scope explicite) + D-21 (warnings affichés si présents en mode `--hook`) — élimine le faux vert plutôt que de le masquer davantage |
| Une allowlist `Agent(...)` perçue comme sandbox runtime alors qu'elle ne l'est pas pour un sous-agent | Tampering (confiance mal placée dans un contrôle inexistant au runtime) | Doctrine déjà écrite dans `check-agents.sh` (en-tête) et `team-kernel.md:23` — cette phase ne doit pas la contredire en présentant l'allowlist comme une barrière runtime dans un nouveau texte (D-11 touche `vf-coder.md`, dont l'allowlist `Agent(vf-reviewer, ...)` reste un contrat lint, pas un sandbox) |

## Sources

### Primary (HIGH confidence — lecture directe du code source du repo, 2026-07-29)
- `plugin/dev-orchestrator/agents/vf-reviewer.md`, `vf-dev-manager.md`, `vf-coder.md`, `vf-auditer.md`
  — frontmatter et corps intégral lus, tous les numéros de ligne cités confirmés.
- `plugin/dev-orchestrator/references/mission-cross-team.md`, `mission-contracts.md` — lus intégralement.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` — lu intégralement (305 lignes).
- `plugin/conductor/scripts/dag.sh`, `check-agents.sh`, `check-debug-research.sh` — lus intégralement.
- `plugin/conductor/hooks/hooks.json`, `plugin/_internal/merge-hooks.sh` — lus intégralement.
- `plugin/conductor/references/team-kernel.md`, `README.md` — lus intégralement.
- `plugin/design-orchestrator/agents/vf-design-judge.md`, `plugin/business-pilot-bundle/agents/
  quality-gate-client.md`, `plugin/content-bundle/agents/content-clarity-judge.md`,
  `plugin/growth-bundle/agents/growth-quality-judge.md` — lus intégralement, aucun ne porte
  `disallowedTools`.
- `docs/ADR.md:356-436` (ADR-051) et liste des index ADR (dernier : ADR-059, ligne 930) — lus.
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — lu intégralement (patron de référence).
- `plugin/conductor/scripts/tests/test-check-agents.sh`, `test-check-debug-research.sh` — en-têtes et
  `run_check()` confirmés (le piège de mesure D-24 est réel, ligne 94 et ligne 36 respectivement).
- `.planning/codebase/CONVENTIONS.md`, `TESTING.md` — lus intégralement (patrons de test, release,
  portabilité).
- `.planning/ROADMAP.md` §Phase 20 (lignes 759-926) — 7 critères de succès lus intégralement.
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — lus pour confirmer l'absence d'IDs formels et
  l'état de la phase précédente (Phase 19 shippée v2.43.0).
- `plugin/*/VERSION` et `module.json` des 6 modules — versions courantes confirmées identiques à
  celles citées dans D-25.

### Secondary (MEDIUM confidence)
- Aucune — cette recherche n'a nécessité aucune source web externe (phase 100% interne au repo).

### Tertiary (LOW confidence)
- Le nommage exact des outils XcodeBuildMCP (`test_sim`/`build_sim`/`clean`) reste non vérifié contre
  un serveur MCP vivant — signalé comme tel dans `<user_constraints>` D-03 (deferred, hors périmètre
  d'exécution de cette phase) et dans §Assumptions Log A2.

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — aucune dépendance externe, bash/python3 déjà en place et documentés.
- Architecture : HIGH — tous les patrons cités existent déjà dans le repo et ont été relus intégralement.
- Pitfalls : HIGH pour D-24/D-21 (constatés sur pièce, `run_check()` et logique `--hook` lues
  directement) ; MEDIUM pour les pièges XcodeBuildMCP (Pitfall 3/4, documentés au ROADMAP mais non
  reproductibles dans ce repo sans `.mcp.json`).

**Research date :** 2026-07-29
**Valid until :** 30 jours (changements internes stables, pas de dépendance à un package externe
susceptible de driver) — mais **re-vérifier avant exécution** si `20-CONTEXT.md` ou l'état du repo a
changé depuis (ex. une autre phase concurrente touchant les mêmes fichiers).

---

*Phase: 20-Fluidité du flux de dev sans perte de qualité*
*Research completed: 2026-07-29*
