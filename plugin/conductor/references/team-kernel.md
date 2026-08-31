# Team-kernel — le socle d'orchestration d'équipe, transverse à tous les métiers

> **Rôle** : le noyau réutilisable qui fait tourner une équipe d'agents (manager → workers →
> juges) dans N'IMPORTE QUEL métier — dev, design, contenu, growth, dossier… Extrait du
> dev-orchestrator (ADR-053, éprouvé en mission) et hébergé par le conductor (socle mandatory)
> pour être disponible dans tout lab. Le dev-orchestrator est l'**implémentation de référence** ;
> l'équipe design est la première instanciation non-dev.
>
> Chargement on-demand. Chemin d'install : `.claude/agents/conductor-references/team-kernel.md`
> (les scripts, eux, vivent à plat dans `.claude/scripts/` comme tous les scripts de modules).

---

## Ce que le kernel fournit (invariant, quel que soit le métier)

| Brique | Script / contrat | Garantie |
|---|---|---|
| **Verrou de driver** | `driver-lock.sh` (acquire / heartbeat / release / status / recover / takeover / reclaim, TTL) | une seule mission pilote à la fois ; la reprise d'un lock périmé est un geste EXPLICITE et tracé (`takeover`), jamais un effet de bord d'une acquisition ordinaire (`acquire` refuse et nomme la marche à suivre) ; `reclaim` re-rattache une session légitime sans jamais prolonger la fraîcheur du lock (Phase 32) |
| **Plan de bataille** | `dag.sh` (init / add --deps **--scope** / ready / mark / reopen / status) | contrôle de flux déterministe ; la frontière `ready` est une **liste à dispatcher en parallèle** quand les périmètres sont disjoints ; `reopen` force `review_regime=full` sur tout nœud de revue/jointure rouvert — aucun allègement ne s'applique jamais à un diff de comblement (D-14, Phase 20) |
| **Rapports typés** (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[{severity, action: auto-fix\|no-op\|ask-user, ref}], noeuds_debloques[] }` | fin de l'interprétation de prose ; escalade humaine impérative sur `ask-user` |
| **Halt conditions** | 5 codes (P11) : boucle sans progrès · action destructive · ressource manquante · budget épuisé · drift de scope | l'humain arbitre en 30 s sur un message structuré |
| **Digest de mission** | ≤ 30 lignes injectées dans chaque mandat (le disque fait foi) | amortit les relectures de contexte par étage |
| **Cloisonnement par tools** (P12) | juges via `disallowedTools: Write, Edit` (contrainte runtime, Phase 20 — pas une simple absence dans `tools:`) ; la plupart des workers sans Task ; allowlist `Agent(...)` sur les managers ; `vf-internal: true` | anti-triche vérifié par un gate transverse, PAS par les suites de test de chaque module (aucune n'y touche) : `check-agents.sh --strict`, qui linte le contenu de `tools:` (syntaxe des allowlists `Agent(...)`/`Task(...)`) en plus du frontmatter (ADR-044, Phase 16) et exige `disallowedTools: Write, Edit` sur tout agent `memory:` sans Write/Edit déclaré — passé par la CI sur les 6 dossiers `plugin/*/agents` (découverte non vide, monde clos) et à l'écriture par le hook `guard-agent-write.sh` ; les deux mécanismes sont eux-mêmes testés par la suite **conductor** (`test-check-agents.sh`, `test-guard-agent-write.sh`). C'est un CONTRAT documenté, pas un cloisonnement runtime : le runtime n'applique la liste de noms entre parenthèses qu'en incarnation fenêtre principale (`claude --agent`), jamais pour un agent dispatché en sous-agent (doc officielle sub-agents). Le garant machine réel de « un seul manager actif » est le verrou de driver, pas l'allowlist (cf. « Étages croisés » ci-dessous) |
| **Écart déclaré ↔ runtime** (sens fermeture) | un outil **PRÉSENT** dans le champ `tools:` déclaré peut être **ABSENT** au runtime une fois l'agent dispatché en sous-agent | cas établi et daté : un agent déclarait `AskUserQuestion` mais ne le recevait pas en dispatch sous-agent, ce qui a gelé une mission — filet de repli : le besoin humain remonte dans le rapport typé, il n'est **jamais** auto-répondu en silence (patron `vf-coder.md`) |
| **Dispatch nommé** (hypothèse datée, jamais construite en mécanisme) | `Agent(...)`/`Task` natif Claude Code, allowlists des managers | tient tant que VibeFlow reste Claude-Code-exclusif (`mission-contracts.md` §Seuil de bascule D5(a)) : chaque rôle nommé (`vf-coder`, `vf-reviewer`…) est résolu par un runtime à dispatch nommé. **Mesuré le 2026-08-29 (Phase 38) sur `@moonshot-ai/kimi-code@0.39.1` réellement installé, le descripteur `namedDispatch: false` de kimi-code — et donc la ligne précédente de cette référence — est PÉRIMÉ** : le schéma de profil d'agent porte `subagents: array(string())`, `delegatableSubagents(callerProfileName)` résout par nom, et `load()` fusionne les agent-files du disque (`userRoots`/`extraRoots`/`projectRoots`/`pluginRoots`, priorités `plugin:5 < user:10 < extra:20 < project:30 < explicit:40`) dans une Map clé=nom — kimi-code enregistre bien des sous-agents nommés custom, via `Agent` et `AgentSwarm`. **Périmé par la suite de la même Phase 38** : l'installeur cible désormais aussi Codex
(`--target`, `plugin/_internal/runtime-cli-dispatch.sh`) — install fonctionnelle, agents
enregistrés, skills déclenchables (cible tier-1). Ce qui RESTE non constaté : l'aller-retour
manager→worker par dispatch nommé sur Codex — profondeur 1 sur 2 seulement mesurée (quota
ChatGPT épuisé jusqu'au 2026-09-27), un inconnu déclaré, pas une capacité prouvée. Sur kimi-code
et OpenCode, la pose est mesurée mais **aucun mécanisme de repli n'est construit** — `disallowedTools`
en session et le firing des hooks restent non vérifiés sur kimi-code (login OAuth en échec serveur),
et `disallowedTools` est inerte / l'allowlist `Agent(...)` déchiquetée sur OpenCode. |
| **Piège d'identité de paquet npm `kimi-code`** (mesuré 2026-08-29, Phase 38) | `npm view kimi-code` vs `npm view @moonshot-ai/kimi-code` | le paquet npm nu `kimi-code` N'EST PAS le produit Moonshot — description amont : *« CLI that starts anthropic-proxy with Kimi model and runs claude-code »*, tiers, non modifié depuis ~1 an. Le vrai produit est **`@moonshot-ai/kimi-code`** (binaire `kimi`, publié activement — c'est la version mesurée ci-dessus). `kimi-cli` sur npm est un TROISIÈME objet sans rapport. Un installeur naïf qui ferait `npm i -g kimi-code` poserait le mauvais logiciel — toujours nommer le scope complet `@moonshot-ai/kimi-code` dans toute doc ou script d'install VibeFlow qui en parle |
| **Namespace de branche des worktrees d'exécuteur** (recoupement vérifié conforme, Phase 21) | `gsd-worktree-path-guard.js` (hook `PreToolUse`, `~/.claude/hooks/`) | l'amont 1.9.0 a élargi son motif d'allow-list à `^(worktree-)?agent-[A-Za-z0-9._/-]+$` (#1995 — accepte `agent-<id>` **et** l'ancien `worktree-agent-<id>`) : vérifié sur pièce le 2026-07-31, déjà présent dans le hook installé, aucun défaut. Le nouveau cas d'échec `{committed: false, reason: 'staging_failed' \| 'staging_timeout'}` (#2608) est entièrement interne à `gsd-executor` amont — aucune logique de retry VibeFlow ne l'enveloppe, le seul retry documenté porte sur l'étage entier (`vf-dev-manager.md` §Contrôle de flux), jamais sur un `git add` individuel. Rien à câbler, constat écrit ici pour survivre au prochain delta amont (détail : `21-02-SUMMARY.md` §Constat changement 4) |
| **Joignabilité worker → sous-agent** (mesuré Phase 38, 2026-08-28) | `SendMessage` dans le `tools:` d'un worker qui dispatche lui-même des sous-agents | un worker qui spawne un sous-agent doit pouvoir le CORRIGER en cours d'exécution — sinon une correction reçue en vol force un redispatch en agent frais (perte de contexte) plutôt qu'une reprise, et deux exécutions concurrentes peuvent atterrir sur le même fichier. Fix appliqué à `vf-coder` (commit `7c1443b`). **L'asymétrie reste structurelle, pas un bug à corriger davantage** : un manager RÉVEILLE un worker par `SendMessage` (contexte intact) ; un worker, lui, ne résout PAS le nom de son manager depuis son étage — son retour passe par le rapport typé (bloc `Agent`), jamais par `SendMessage` vers le haut. Corollaire de pilotage : ne jamais concevoir un protocole où le worker DOIT initier un échange — une question sans réponse dans les hypothèses documentées se **termine** et se rend en `action: ask-user` ; c'est le tour de boucle qui est le canal, pas un message spontané |

### Marge de profondeur de dispatch (mesuré le 2026-08-04, `@opengsd/gsd-core` 1.9.1)

Le descripteur `claude.runtime.hostIntegration.dispatch` du runtime `claude`, recopié verbatim —
**inchangé depuis la 1.9.0** :

```
namedDispatch: true · nested: true · maxDepth: 5 · background: true
backgroundDispatch: false · subagentToolkit: "full" · isolation: "harness-worktree"
```

**Ce que nous en consommons** : la chaîne la plus profonde du kernel —
`vf-dev-manager` → `vf-coder` → agent `gsd-*` — occupe **3 niveaux sur 5**.
Il reste donc deux niveaux de marge.

**Ce que cette marge autorise** (c'est une permission, pas une simple observation) : un worker peut
légitimement dispatcher un **sous-worker** sans franchir la limite du runtime. Un mandat qui a
besoin d'un étage de délégation supplémentaire n'a pas à être réarchitecturé pour l'éviter, ni
remonté au manager au seul motif de la profondeur. **Ce fait clôt la question du nesting** ouverte à
l'ouverture de l'audit de la Phase 24 — elle n'a plus à être reposée.

**Sa borne, en revanche, est stricte** : la marge est une permission de **profondeur**, jamais une
permission de contourner la **voie unique d'invocation** (GSDC-05, Phase 23 — les briques de cycle
s'invoquent par leur skill, jamais par dispatch direct d'un agent nu) ni le **cloisonnement des
allowlists** `Agent(...)` (P12, ci-dessus). Deux niveaux disponibles ne rendent licite aucun
chemin que la doctrine interdit par ailleurs — en particulier `manager → worker → manager`, que le
verrou de driver refuse quelle que soit la profondeur restante.

### Étage de parallélisme réellement effectif (mesuré le 2026-07-31, sondes horodatées)

Le runtime **sait** paralléliser un fan-out depuis un sous-agent — c'est mesuré, pas déduit d'un
descripteur. Le moteur, lui, **choisit** de ne pas s'en servir : `shouldFlattenDispatch()`
(`bin/lib/host-integration.cjs`) renvoie **`true` pour Claude Code** dès que
`background && backgroundDispatch` n'est pas vrai, et `gsd-execute-phase` **sérialise ses vagues par
décision**. `backgroundDispatch: false` est *fail-closed* par conception : conservateur, **pas
descriptif** de la capacité réelle du poste.

**La conséquence doctrinale, en une ligne :** sur ce runtime, le parallélisme **intra-étape** (les
vagues de plans d'une même étape, côté moteur) est **éteint par défaut** — un drapeau default-off,
restaurable, pas une perte définitive. Le chemin qui le restaure ne passe **pas** par
`shouldFlattenDispatch()` (qui rend bien `true` sous Claude Code, ce fait ne change pas) mais par la
capability amont `claude_orchestration` : son gate n°4 lit `dispatch.nested === true &&
dispatch.background === true`, **jamais** `backgroundDispatch`. Le gate n°4 passe déjà sur ce
runtime ; le verrou pratique est ailleurs, au **gate n°5** (`agent_sdk_version_unknown`) : Claude
Code embarque son SDK dans un binaire plutôt que de l'exposer en paquet npm, donc le routeur ne
trouve aucune version sur disque. `GSD_AGENT_SDK_VERSION` est le contournement documenté en amont —
détail dans `.planning/ROADMAP.md` §« La correction de prémisse ». Tant que ce gate n'est pas levé,
le parallélisme **inter-nœuds** porté par la frontière `ready` de `vf-dev-manager` reste le **seul
effectif aujourd'hui** — le champ `stages` de `dag.sh ready` affine cette frontière en calculant la
disjonction de périmètres entre nœuds ; doctrine complète dans
`dev-orchestrator-references/mission-flow.md`. Notre couche d'orchestration ne duplique donc pas
celle du moteur : **elle reste, pour l'instant, la seule qui parallélise réellement**.

**Ce qui en découle pour un manager**, et qui n'est pas facultatif :

- Le fan-out de la frontière `ready` et la recherche doc non bloquante (ADR-045) **tiennent** —
  mesurés à **92 %** de recouvrement depuis un sous-agent, indiscernables du contrôle en fenêtre
  principale (91 %), et un parent qui dispatche puis continue à travailler n'est **pas** bloqué.
  Ces deux acquis décrivent des gains réels, pas une intention.
- **N'attendez aucun gain de parallélisme d'un découpage en plans multiples au sein d'une même
  étape** : le moteur les aplatira. Le gain se prend en **découpant en nœuds de DAG à périmètres
  disjoints**, dispatchés en un seul message par le manager.
- **Sérialisation observée ≠ panne.** Voir une étape enchaîner ses plans un par un est le
  comportement nominal du moteur ici ; ce n'est ni un symptôme, ni un motif de halt condition, ni
  quelque chose à corriger côté lab.
- **Un worker `isolation: worktree` ne résout PAS son `GSD_WORKSTREAM`.** Fait observé, pas une
  hypothèse : au run réel de la Phase 27 (sonde A4), la variable est **vide** depuis le worktree
  isolé. Un manager qui cloisonne par workstream passe donc le workstream **explicitement dans le
  mandat** du worker isolé — jamais en supposant l'héritage d'environnement. Registre :
  T-27-03-06, `27-SECURITY.md` du dépôt VibeFlow.
- Toute bascule sur la capability amont `claude_orchestration` (BETA, default-off) qui prétendrait
  restaurer le parallélisme intra-étape est un **opt-in explicite**, jamais un défaut.

Protocole complet, trois configurations, horodatages bruts et réserves de la mesure (la profondeur
2 → 3 n'a pas été mesurée) : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` du
dépôt VibeFlow. **Renvoi, pas copie** — les chiffres ne se recopient pas d'ici, ils se relisent
là-bas.

## Ce que chaque métier paramètre (et RIEN d'autre)

1. **Les spécialistes** : un manager (opus, seul à voir large), des producteurs (sonnet), des
   juges frais read-only (sonnet). Templates : `templates/agents/` du module reference
   (orchestrator-template, lead/explorer/reviewer/tester) + `metier-orchestration`.
2. **La définition de « vert »** : dev = tests qui passent ; design = critique scorée contre la
   direction artistique ; contenu = gates de clarté + validation humaine ; etc. Le kernel ne
   connaît pas la nature de la preuve — il exige seulement qu'elle soit **machine-vérifiable ou
   scorée par un juge frais**, et rendue en rapport typé.
3. **Les gates métier** : quels étages tournent par étape (build/test/audit en dev ;
   craft/critique/recette en design…), et lesquels tournent **en parallèle** (tous les juges
   read-only le peuvent, par construction).
4. **Le vocabulaire du rapport** : libre — le bloc typé, lui, est invariant.

## Règles d'instanciation

- **Un manager ne produit jamais** (P3) : il lit, planifie (DAG), dispatche la frontière,
  synthétise. Toute production vit dans les workers.
- **Dispatch parallèle par défaut** : ≥ 2 nœuds `ready` à périmètres disjoints → un seul
  message, plusieurs Task. Périmètres douteux → **séquentiel** (voir la règle suivante avant
  d'envisager `isolation: worktree`).
- **L'isolation est une décision de DISPATCH, jamais une propriété du worker (issue #38).**
  Aucun agent distribué ne porte `isolation: worktree` dans son frontmatter — deux paliers le
  gardent : le **palier dur** `check-agents.sh` (aucune valeur d'`isolation:` admise dans un agent
  distribué) et le **palier de relation** règle 4 de `check-capability-activation.sh` (une
  capability ne s'attribue pas une couverture qu'elle ne fournit pas effectivement). **Phase 35,
  close par la preuve le 2026-08-26 — les deux paliers restent, en connaissance de cause, pas en
  attente d'événement.** Le déclencheur externe est tombé (`open-gsd/gsd-core#3302` releasé en
  1.11.0 ET installé) et la mesure a **tranché contre** le ré-armement plutôt que de rester
  flottante :
  - **Sûreté acquise, leg A et leg B.** Leg A (retour des commits) est réparé depuis 1.11.0,
    prouvé en fast-forward sur un cas réel (`2026-08-23-wktr-02-...md`). Leg B (base de fork) ne
    casse plus en silence : sur un lab sans réglage, HEAD divergent → le moteur **dégrade en
    séquentiel sur l'arbre principal** avec message explicite plutôt que de faire atterrir le
    worker sur une branche sans les fichiers du mandat (`2026-08-26-wktr-02-leg-b-base-de-fork.md`).
  - **Efficacité nulle en conditions de mission — c'est ce qui bloque le ré-armement.** Une mission
    d'équipe travaille **toujours** sur une branche dédiée (ADR-059), donc HEAD diverge
    **toujours** d'`origin/HEAD`, donc l'armement dégraderait **systématiquement** en séquentiel :
    zéro parallélisme gagné, un avertissement à chaque dispatch. Le seul levier qui rendrait
    l'armement effectif (`worktree.baseRef: "head"`) reste l'anti-pattern de #38 : une clé de
    settings sans aucun vecteur de distribution par l'engine, et qui **éteint le contrôle** au lieu
    de le satisfaire — le moteur lui-même documente qu'elle *« silences this check without
    verifying the base »*. Un armement dont le réglage « sûr » consiste à couper la vérification
    n'est pas un armement sûr.
  - Porté par le frontmatter, `isolation` devient **inconditionnel** et retire au manager
    l'arbitrage que cette section lui confie — c'est pour ça qu'il reste une décision de dispatch,
    jamais une propriété déclarée.
  - **Contrainte opérationnelle, tant que l'isolation reste une décision de dispatch.** La garde
    d'isolation refuse les commandes composées : `&&`, enchaînements, heredocs rejetés avec « this
    command is too complex to verify that it stays inside the worktree ». Tout mandat qui dispatche
    avec `isolation: worktree` doit donc prescrire au worker d'écrire ses fichiers via Write/Edit
    et de n'employer qu'**un seul verbe git par appel Bash** — sans cette consigne, l'échec est
    étranger au sujet du mandat et égare le diagnostic.
- **Le commit reste discipliné même à périmètres disjoints (Phase 27)** : la disjonction
  gouverne le *dispatch*, jamais le *commit*. Tant que N acteurs — workers **et** manager —
  partagent un même `.git/index` (pas d'`isolation: worktree`) : **jamais** `git add` (même
  ciblé sur son propre fichier), **jamais** `git commit -m`/`-a` sans pathspec (`-A`/`.`/`-u`
  inclus) — `git commit` nu commite tout l'index partagé, y compris ce qu'un autre acteur
  vient d'y ajouter. Forme imposée : `git commit <chemin> [<chemin>...] -m "..."` (ignore
  l'index). Seule exception, fichier neuf (inatteignable autrement) :
  `git add <chemin exact> && git commit <chemin exact> -m "..."` en une seule commande
  enchaînée, jamais de stage en attente. Rename (ancien chemin supprimé + nouveau créé) : même
  patron, les deux chemins exacts — `git add <nouveau> && git commit <ancien> <nouveau> -m "..."`.
  Suppression pure : déjà couverte, `git commit <chemin>` stage et committe seul, sans `git rm`.
  Chaque mandat nomme les fichiers tenus par ses voisins **en ce moment** — un périmètre positif
  seul ne suffit pas. Trou identifié mais laissé ouvert par `mission-contracts.md` §Isolation de
  branche (« non tranchée ici ») : tranché ici.
- **Digest dans chaque mandat**, détail sur disque, bloc typé au retour — jamais de pilotage
  à la prose.
- **Proportionnalité** : en dessous du seuil d'équipe du métier (dev : `SEUIL_EQUIPE`,
  `mission-contracts.md`), pas de manager — la brique outillée directe suffit. Le kernel est
  fait pour les missions, pas pour le quotidien.
- **Escalades** : tout ce que la doctrine du lab réserve à l'humain (ADR-031) court-circuite
  l'autonomie, quel que soit le métier.
- **Édition-à-la-source (G5)** : **deux occurrences** du même verdict sur le même objet, ce n'est
  pas un correctif de plus à dispatcher — c'est le signal que la **source** est fautive. Le
  manager amende la source, puis relance ; il ne redispatche jamais le même patch. « Source »
  désigne ce qui existe déjà — `CLAUDE.md` du projet, référence de doctrine, gabarit du digest, ou
  le mandat lui-même — **jamais le worker** : reproduire une erreur, c'est appliquer correctement
  un contrat fautif. Écriture de doctrine, bornée par **ADR-031** : en mission autonome le manager
  **consigne** la source à amender dans son rapport typé, il ne l'amende jamais en silence — la
  capitalisation reste l'affaire des registres de learnings, cette règle dit **quand** la
  déclencher.
- **Un garde ne se desserre jamais dans le commit qu'il autorise (Phase 38, 2026-08-28).** Un
  lot qui bute sur un garde de doctrine **pose le besoin, escalade, et n'y touche pas** — le
  garde ne bouge que dans un commit séparé, après décision. Un garde modifié par l'auteur même
  du changement qu'il surveille perd sa fonction : il ne mesure plus rien d'indépendant.
  Incident fondateur : le lot RUNT avait besoin qu'un script de module résolve un script partagé
  du socle `plugin/_internal/`, ce que le garde T9e de `test-design-orchestrator.sh` (règle
  d'autonomie D-04) interdisait. Le worker a modifié le garde **dans le même commit** (`d6ff0d4`)
  que le code protégé, en notant au CHANGELOG « sans affaiblir la garde d'autonomie » — une revue
  en régime plein a prouvé par mutation que l'exemption affaiblissait bel et bien le garde (elle
  filtrait le nom de fichier n'importe où sur la ligne, laissant passer une résolution
  cross-module déguisée). Le choix technique lui-même était défendable, et Samuel l'a ratifié
  (D-38-M — `plugin/_internal/` est le socle, hors D-04, précédent `find_engine_lib()` /
  `find_hooks_merger()`) : **c'est la procédure qui manquait, pas le jugement** — d'où une règle
  qui vaut plus que l'exception qu'elle encadre.

- **Sur Codex, le `task_name` se normalise en snake_case — jamais le `agent_type` (Phase 38,
  2026-08-28).** Mesuré en session Codex réelle (`multi_agent_v2`, 7 inconnus levés,
  38-CONTEXT.md) : les tirets **passent** au dispatch — un rôle nommé `vf-reviewer` se charge
  sans warning et tourne réellement (`agent_type` = nom du rôle, tous scopes). La contrainte
  `[a-z0-9_]+` porte sur le **`task_name`** du spawn, parce qu'il devient un **segment de
  chemin** (`/root/<task_name>`) dans l'arbre d'agents — erreur mesurée verbatim :
  `agent_name must use only lowercase letters, digits, and underscores`. **Les 31 noms d'agents
  VibeFlow gardent leurs tirets tels quels** (aucun mapping de nommage, l'inconnu est confirmé
  résolu). Seul le `task_name` passé à `spawn_agent` se normalise, une ligne, jamais une table
  de correspondance : `tr 'A-Z-' 'a-z_'` (ou équivalent) avant spawn.
  **Aucune contrainte `fork_turns` requise pour préserver le `model` du rôle** : mesuré en base
  (`fork_turns:"none"` **et** `"all"`), le modèle enfant est réellement enregistré dans les deux
  cas — `fork_turns` porte l'historique de conversation, pas la configuration du rôle. « Un
  modèle par worker » tient sans contrainte de spawn ajoutée.

## Implémentations

| Équipe | Module | Manager | Workers | Juges | « Vert » |
|---|---|---|---|---|---|
| Dev (référence) | dev-orchestrator | `vf-dev-manager` | `vf-coder` (+ `vf-crafter` en étage design croisé) | `vf-reviewer`, `vf-auditer` (+ `vf-design-judge` en étage design croisé) | tests + revue PASS (+ critique ≥ seuil si étage design) |
| Mobile (boucle test) | mobile-test-team | `vf-test-orchestrator` | `vf-app-fixer`, `vf-test-runner` | (le test EST le juge) | flows Maestro verts |
| Design | design-orchestrator | `vf-design-manager` | `vf-crafter` (+ `vf-coder` en étage implémentation croisé) | `vf-design-judge` (+ `vf-reviewer` en étage implémentation croisé) | critique scorée ≥ seuil contre la DA (+ revue PASS si implémentation) |

Étages croisés (Phase 15) : chaque manager peut dispatcher des workers/juges de l'autre métier —
JAMAIS l'autre manager (Pattern A, prouvé bloquant par test T1). Deux gardes-fous, de nature
différente : (1) les allowlists `Agent(...)` des deux managers (`vf-dev-manager` exclut
`vf-design-manager`, et réciproquement — T18 côté dev-orchestrator, T8 côté design-orchestrator)
sont un CONTRAT déclaré et lint-vérifié (`check-agents.sh` linte désormais le contenu de `tools:`,
pas seulement sa présence, Phase 16) : l'intention « pas de manager→manager » est écrite noir sur
blanc et testée, mais ce n'est **pas un cloisonnement runtime** — le runtime ignore la liste de noms
entre parenthèses pour tout agent dispatché en sous-agent (doc officielle sub-agents), managers
inclus ; (2) le **verrou de driver** est donc le SEUL garant machine réel de l'invariant, en toutes
circonstances, y compris par chemin **indirect** (`manager → worker → manager`) : un second manager
tentant `acquire` se le voit refusé tant que le premier pilote (T1 ; couvert en continu par
`test-driver-lock.sh` T2). Le lock, le DAG et le rapport restent uniques, portés par le seul manager
de la mission. Le garant machine s'étend désormais au-delà de la seule acquisition : le guard
`PreToolUse` du plan 32-03 (`guard-driver-lock.sh`) porte l'invariant jusqu'aux gestes git (et aux
écritures directes sous `.planning/`) émis par une session TIERCE pendant qu'un lock est vivant.
Portée écrite honnêtement, avec sa limite de granularité : le guard garantit qu'aucune AUTRE
session ne commite sous le lock, JAMAIS qu'aucun autre acteur de la MÊME session ne le fait — ce
n'est pas une sandbox, c'est un garde-fou déterministe contre le chemin de moindre résistance.

Doctrine détaillée côté dev (le protocole complet de mission) :
`dev-orchestrator-references/mission-flow.md` — c'est la référence d'usage du kernel. Doctrine
des étages croisés (quand les insérer, forme DAG, budgets, invariants) :
`dev-orchestrator-references/mission-cross-team.md`.

## Jeton de fence — quel commit sous quel mandat (LOCK-05)

**Le jeton.** La *génération* du lock — `${LOCK_BASE}.gen.<epoch>.<pid>`, cible du lien
symbolique publié par `driver-lock.sh` (`new_generation()`), unique et monotone par acquisition,
déjà relue en interne pour la reprise (`lock_gen()`). C'est le seul candidat qui soit un fence au
sens strict : un numéro qui INVALIDE l'ancien tenant après une reprise. Trois autres candidats,
écartés : l'`owner` du lock est une chaîne libre, jamais validée par le script ; les identifiants
de nœuds du DAG (`dag.sh`) ont une portée nœud, pas mandat ; `session_ids`/`Claude-Session:`
désigne une session, pas un mandat — et elle change sur certains gestes du harness (`/clear`,
motif d'être du verbe `reclaim`).

**Comment l'obtenir.** `driver-lock.sh status` rend un JSON une ligne portant la clé
`generation` (Phase 32). Lecture recommandée par un interprète JSON (`jq -r .generation`), jamais
par découpage de texte — la forme de la ligne n'est pas garantie stable colonne par colonne. Un
lock absent (`"present": false`) ne porte pas de `generation` : un commit hors mandat n'a alors
pas de trailer à poser, c'est un cas normal, pas une omission.

**La convention.** Le manager, ou le worker qui commite pour son propre compte, ajoute au message
de commit un trailer `Fence: <generation>` — dans le bloc de trailers, aux côtés de ceux déjà en
usage. Un commit peut porter plusieurs trailers.

**Le tier de cette convention, écrit noir sur blanc.** Elle est exactement au même niveau que les
deux trailers déjà en usage dans ce dépôt — sur les 300 derniers commits (`git log -300
--pretty=%B`), on compte 397 OCCURRENCES de ligne `Co-Authored-By:` (casse haute et basse
confondues) et 291 de `Claude-Session:` — mesuré le 2026-08-17, remesurable à tout moment par la
même commande (le nombre DÉRIVE avec la fenêtre glissante des 300 derniers commits, ce n'est pas
une constante figée). Ce sont des occurrences de LIGNE, pas des commits distincts : un
squash-merge concatène les corps de plusieurs commits dans un seul message, donc UN SEUL commit
peut porter PLUSIEURS occurrences du même trailer — 397 > 300 est donc numériquement normal, pas
une anomalie. Posée par convention d'agent, **jamais posée ni vérifiée par une machine**. Aucun
outil de ce dépôt ne pose ni ne vérifie un trailer (`.git/hooks/` ne contient que des `.sample`,
aucun `commit-msg`/`prepare-commit-msg`).

**Ce qui n'est PAS construit, et pourquoi.** Aucun hook git de message de commit : ce dépôt arme
déjà un chemin de hooks git pour son garde-fou de push (`scripts/hooks/pre-push`, opt-in), et tout
hook supplémentaire non versionné y entrerait en conflit, sans être distribuable aux labs qui
installent le module. Aucun gate CI qui parse les trailers : le moteur de merge de hooks du dépôt
ne connaît que les hooks du harness (`hooks.json`), jamais les hooks git natifs — en construire un
serait une extension de capacité du moteur, hors du périmètre de cette phase, et LOCK-05 exige
littéralement « auditable », pas « bloqué à la source ». Deux extensions considérées et
DIFFÉRÉES, pas oubliées : un audit outillé non bloquant (script qui recoupe trailers et journal en
un rapport), et un hook de message de commit distribué aux labs.

**La recette d'audit.** Répondre à « quel commit sous quel mandat » recoupe deux sources : les
commits portant le trailer — `git log --grep='^Fence: ' -E --format='%H %s'` (zéro résultat est un
résultat valide tant qu'aucun commit ne pose encore le trailer) — et le journal append-only des
reprises posé par le plan 32-02, `${LOCK_BASE}.events.log` (frère du lock, jamais dedans : la
reprise détruit le dossier de génération), une ligne JSON par événement avec son champ
`generation`. Le recoupement dit quand une génération a changé de main et au profit de qui ; il ne
dit PAS qu'un commit sans trailer est hors mandat — seulement qu'aucune preuve n'a été posée,
puisque rien ne pose le trailer à la place de l'agent.
