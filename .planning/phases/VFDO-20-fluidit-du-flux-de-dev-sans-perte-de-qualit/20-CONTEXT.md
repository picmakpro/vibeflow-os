# Phase 20: Fluidité du flux de dev sans perte de qualité - Context

**Gathered:** 2026-07-28 (mode `--auto`, sans `AskUserQuestion` — cf. Note de méthode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Sources : `.planning/ROADMAP.md` §Phase 20 (7 critères de succès, 4 changements) + le rapport
d'audit externe `.planning/missions/2026-07-28-audit-externe-fluidite.md` + le dossier d'instruction
préalable `.planning/missions/2026-07-28-phase-20-instruction-prealable.md` (4 décisions de doctrine
déjà tranchées par Samuel, non renégociables — voir Note de méthode).

La phase livre **4 changements indépendants** qui rendent le flux de dev **plus sûr** (1, 2, 3) et
**plus fluide/observable** (2 en partie, 4), sans jamais réduire le nombre de tests ni alléger la
revue sur le chemin critique produit :

1. **`vf-reviewer` gagne l'accès MCP fin** (`test_sim`, `build_sim`, `clean` de XcodeBuildMCP, à lui
   seul) + révision ciblée d'**ADR-051**.
2. **La revue devient un étage de premier rang piloté par `vf-dev-manager`**, sortie du cycle interne
   de `vf-coder`, graduée par risque (critères objectifs a-d), avec revue de jointure obligatoire sur
   toute fusion de lots parallèles. **Critère de succès n°2 associé** : l'écart `tools:` déclaré /
   runtime est traité dans les deux sens (ouverture ET fermeture) — `disallowedTools: Write, Edit`
   sur 4 juges, et le constat que `AskUserQuestion` déclaré peut être absent en sous-agent.
3. **`dag.sh` gagne un `--scope`** (fichiers/globs par nœud), condition du critère (b) du changement 2
   et de la table des fichiers gelés.
4. **`.planning/MISSION-INVARIANTS.md`** créé, réduit aux éléments **gatés** (falsifiables).
5. **Correction du scope des deux hooks de conformité** (`check-agents.sh --hook`,
   `check-debug-research.sh --hook`) + levée de l'exemption du mode hook sur le contrat
   anti-vert-à-vide + correctif du charset MCP qui contredit l'injecteur ADR-051.

**Ne produit PAS** (hors périmètre, tranché) :

- Aucun seuil de tests dans `MISSION-INVARIANTS.md` (invérifiable sans exécution — D4).
- Aucune option `--exclude=GLOB` redondante sur `check-agents.sh` (`--third-party-prefix` existe déjà,
  défaut `gsd-`, livré Phase 16/v2.41.0 — constat daté de la Phase 19).
- Aucun allègement de la revue sur le chemin critique produit, et **aucun allègement sur un diff de
  comblement** (une re-revue après correctif reste toujours pleine, quelle que soit la nature du lot
  d'origine — garde-fou non négociable de la phase).
- Aucune réduction du nombre de tests (garde-fou non négociable — les tests pèsent ~1s sur 90s de
  `test_sim`, le levier de vitesse est nul de ce côté).

</domain>

<decisions>
## Implementation Decisions

### Note de méthode — cadrage en `--auto`, sans re-décision des 4 arbitrages de Samuel (D-00)

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

### Changement 1 — accès MCP fin de `vf-reviewer` + révision ADR-051 (D-01 → D-05)

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

### Critère de succès n°2 — écart `tools:`/runtime, les deux sens (D-06 → D-09)

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

### Changement 2 — la revue devient un étage de premier rang (D-10 → D-14)

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

### Changement 3 — `.planning/MISSION-INVARIANTS.md` (D-15 → D-17)

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

### Changement 5 (ROADMAP Changement 4) — scope des hooks + bug de charset (D-18 → D-23)

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

### Le piège de mesure — obligatoire pour TOUS les fixes de scope (D-24)

- **D-24 [tranché, Samuel — non négociable] :** Aucun des **58 + 14** cas actuels de
  `test-check-agents.sh`/`test-check-debug-research.sh` n'exerce le **chemin par défaut** (sans
  `--agents-dir`/`--skills-dir` explicite) — `run_check()` les passe toujours en dur. C'est
  précisément pour cette raison que le bug de scope a survécu à une Phase 16 entière dédiée au
  script. **Tout plan qui touche D-18/D-19/D-20 DOIT ajouter un cas « défaut, cwd sans
  `.claude/agents` »** — sinon la correction elle-même resterait non couverte, répétant l'erreur.
  Portabilité macOS + Linux **prouvée par exécution**, jamais par lecture (patron établi Phases 16,
  17, 19).

### Governance & release (D-25 → D-26)

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Sources de mission (font foi sur les constats et les 4 décisions de doctrine)
- `.planning/missions/2026-07-28-phase-20-instruction-prealable.md` — les 4 décisions D1-D4, le
  panel de recherche, les preuves expérimentales (sondes MCP A/B/C, sondes `disallowedTools`
  nomem/mem/deny), les 3 avertissements de cadrage imposés.
- `.planning/missions/2026-07-28-audit-externe-fluidite.md` — le rapport source, le rendement mesuré
  par nature de lot (table bloquants trouvés).
- `.planning/ROADMAP.md` §Phase 20 — 7 critères de succès, le livrable de cadrage exigé (fichier par
  fichier, gain/coût/risque/réversibilité/ADR par changement, distinction config vs doctrine).

### Code à modifier (chemins et lignes vérifiés le 2026-07-28)
- `plugin/dev-orchestrator/agents/vf-reviewer.md:4,7` — `tools:`, `vf-internal: true`.
- `plugin/dev-orchestrator/agents/vf-dev-manager.md:4,21,75-77(à vérifier),108-110,141` — `tools:`
  (`AskUserQuestion`), règle de double revue, périmètre de fichier au `dag add`.
- `plugin/dev-orchestrator/agents/vf-coder.md` — §« Le cycle (délégation) », étape 4 Revue à retirer.
- `plugin/dev-orchestrator/agents/vf-auditer.md:4` — référence de contrôle (ne doit PAS changer).
- `plugin/dev-orchestrator/references/mission-cross-team.md:36-45,61-74` — nœud `revue-N` déjà posé
  (cas cross-team), formule « vert complet ».
- `plugin/dev-orchestrator/references/mission-contracts.md:10-23,49-60,145` — brief/digest, `SEUIL_
  EQUIPE = 3`.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:10` — en-tête ADR-051, nouveau mode nommé D-05.
- `plugin/design-orchestrator/agents/vf-design-judge.md:4` — `tools:` (porte `Bash`).
- `plugin/business-pilot-bundle/agents/quality-gate-client.md:4` — `tools:`.
- `plugin/content-bundle/agents/content-clarity-judge.md:4` — `tools:`.
- `plugin/growth-bundle/agents/growth-quality-judge.md:4` — `tools:`.
- `plugin/conductor/references/team-kernel.md:23,36` — doctrine juges + doctrine Agent(...) sous-agent.
- `plugin/conductor/README.md:44` — même doctrine, vitrine.
- `plugin/conductor/scripts/dag.sh:103(schéma node),127-149(reopen/dependents/recompute)` — `--scope`,
  régime de revue forcé.
- `plugin/conductor/scripts/check-agents.sh:78-79,153-156(KNOWN),355,568,571` — scope, charset MCP,
  exemption `--hook`.
- `plugin/conductor/scripts/check-debug-research.sh:35-36,48-49` — scope, flags disponibles.
- `plugin/conductor/hooks/hooks.json` — 2 commandes `--hook`, contenu intégral déjà lu.
- `plugin/_internal/merge-hooks.sh:167` — `.replace()` global (à ne pas modifier, juste s'appuyer
  dessus).
- `docs/ADR.md:356-437(ADR-051),424-432(Code Impacté),930(dernier ADR, ADR-059)` — révision + ADR-060.

### Doctrine et gates
- `.planning/codebase/CONVENTIONS.md` — structure de module, triade version, numérotation
  minor/patch, discipline de release, portabilité bash.
- `.planning/codebase/TESTING.md` — patron de suite (`ok()`/`ko()`, `mktemp` factice, découverte CI).
- `CLAUDE.md` racine — discipline de release (toute VERSION = un tag).
- `plugin/conductor/AGENT.md:114` — Iron Law 2 « Router, jamais réimplémenter ».
- `docs/ADR.md` — ADR-029 (densité), ADR-031 (jamais de fix sans validation humaine), ADR-044 (agents
  natifs machine-enforced), ADR-053 (DAG ready/blocked, rapports typés), ADR-057 (frontières tierces).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Le patron `human_needed` de repli sur outil absent existe **déjà** dans `vf-coder.md` (§Cadrage) —
  D-09 le copie tel quel pour `vf-dev-manager.md`, ne le réinvente pas.
- `merge-hooks.sh:167` fait déjà le `.replace()` global de `{{VF_SCRIPTS}}` — D-18 s'appuie dessus
  sans nouveau code de substitution.
- `--third-party-prefix` de `check-agents.sh` (défaut `gsd-`, Phase 16) — D-20 le porte tel quel vers
  `check-debug-research.sh`, ne réinvente pas de second mécanisme.
- `update-banner.sh` — patron de contrat de sortie « silence nominal, `systemMessage` JSON sinon » —
  modèle pour D-21.
- Le nœud `revue-N` de `mission-cross-team.md:44` — patron exact de `dag.sh add` à généraliser (D-10),
  pas à réinventer.
- `check-doc-drift.sh` — gabarit de gate advisory (`--path`/`--hook`/`--quiet`) éventuellement
  réutilisable pour le script de « zone morte » de D-15.

### Established Patterns
- Contrat de sortie F13 (0/1/2/3, `3` = INDÉTERMINÉ jamais un vert par absence de cible) — s'applique
  à tout nouveau script/mode créé par cette phase.
- Best-effort sans dégradation : un mécanisme absent (serveur MCP non configuré, DAG absent) rend le
  flux silencieux, jamais cassé — patron réutilisé par D-05, D-15.
- FAIT vs JUGEMENT (ADR-055 §3) : les scripts constatent, les agents jugent et proposent — s'applique
  au futur script de « zone morte » (D-15) : il liste les globs morts, il ne décide pas de les
  retirer.

### Integration Points
- Le point de couture délicat de cette phase : `dag.sh` (`conductor`, mandatory) gagne un champ
  consommé par `vf-dev-manager.md` (`dev-orchestrator`, non mandatory) — même famille de couture
  cross-module que la Phase 19 (sonde de présence, jamais de `requires` inversé).
- `inject-mcp-tools.sh` est un point d'intégration déjà chargé (2 modifications en Phase 19 la même
  semaine) — D-05 y ajoute un 3e mode, à documenter clairement pour ne pas complexifier le script
  au-delà de sa densité raisonnable.

</code_context>

<specifics>
## Specific Ideas

- **Formulation exacte attendue pour l'argument central d'ADR-051 révisée** (D-02), reprise mot pour
  mot de la mission : « un relecteur ne PRODUIT pas de verdict de compilation, il en VÉRIFIE un ».
- **Coût à écrire noir sur blanc** (D-02) : +90s par revue, un slot de simulateur consommé — ne pas
  omettre ce chiffre dans la révision d'ADR-051.
- **Formulation attendue pour le garde-fou de comblement** (déjà dans le ROADMAP, à préserver
  intacte dans tout plan touchant Changement 2/D-14) : « Aucun allègement ne s'applique jamais à un
  diff de comblement […] Une re-revue reste pleine, quelle que soit la nature du lot d'origine. »

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 20-Fluidité du flux de dev sans perte de qualité*
*Context gathered: 2026-07-28*
