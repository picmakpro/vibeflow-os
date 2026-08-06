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
| **Verrou de driver** | `driver-lock.sh` (acquire / heartbeat / release, TTL + recovery) | une seule mission pilote à la fois ; reprise propre d'un lock périmé |
| **Plan de bataille** | `dag.sh` (init / add --deps **--scope** / ready / mark / reopen / status) | contrôle de flux déterministe ; la frontière `ready` est une **liste à dispatcher en parallèle** quand les périmètres sont disjoints ; `reopen` force `review_regime=full` sur tout nœud de revue/jointure rouvert — aucun allègement ne s'applique jamais à un diff de comblement (D-14, Phase 20) |
| **Rapports typés** (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[{severity, action: auto-fix\|no-op\|ask-user, ref}], noeuds_debloques[] }` | fin de l'interprétation de prose ; escalade humaine impérative sur `ask-user` |
| **Halt conditions** | 5 codes (P11) : boucle sans progrès · action destructive · ressource manquante · budget épuisé · drift de scope | l'humain arbitre en 30 s sur un message structuré |
| **Digest de mission** | ≤ 30 lignes injectées dans chaque mandat (le disque fait foi) | amortit les relectures de contexte par étage |
| **Cloisonnement par tools** (P12) | juges via `disallowedTools: Write, Edit` (contrainte runtime, Phase 20 — pas une simple absence dans `tools:`) ; la plupart des workers sans Task ; allowlist `Agent(...)` sur les managers ; `vf-internal: true` | anti-triche vérifié par un gate transverse, PAS par les suites de test de chaque module (aucune n'y touche) : `check-agents.sh --strict`, qui linte le contenu de `tools:` (syntaxe des allowlists `Agent(...)`/`Task(...)`) en plus du frontmatter (ADR-044, Phase 16) et exige `disallowedTools: Write, Edit` sur tout agent `memory:` sans Write/Edit déclaré — passé par la CI sur les 6 dossiers `plugin/*/agents` (découverte non vide, monde clos) et à l'écriture par le hook `guard-agent-write.sh` ; les deux mécanismes sont eux-mêmes testés par la suite **conductor** (`test-check-agents.sh`, `test-guard-agent-write.sh`). C'est un CONTRAT documenté, pas un cloisonnement runtime : le runtime n'applique la liste de noms entre parenthèses qu'en incarnation fenêtre principale (`claude --agent`), jamais pour un agent dispatché en sous-agent (doc officielle sub-agents). Le garant machine réel de « un seul manager actif » est le verrou de driver, pas l'allowlist (cf. « Étages croisés » ci-dessous) |
| **Écart déclaré ↔ runtime** (sens fermeture) | un outil **PRÉSENT** dans le champ `tools:` déclaré peut être **ABSENT** au runtime une fois l'agent dispatché en sous-agent | cas établi et daté : un agent déclarait `AskUserQuestion` mais ne le recevait pas en dispatch sous-agent, ce qui a gelé une mission — filet de repli : le besoin humain remonte dans le rapport typé, il n'est **jamais** auto-répondu en silence (patron `vf-coder.md`) |
| **Dispatch nommé** (hypothèse datée, jamais construite en mécanisme) | `Agent(...)`/`Task` natif Claude Code, allowlists des managers | tient tant que VibeFlow reste Claude-Code-exclusif (`mission-contracts.md` §Seuil de bascule D5(a)) : chaque rôle nommé (`vf-coder`, `vf-reviewer`…) est résolu par un runtime à dispatch nommé. L'amont (`gsd-core/references/runtime-aware-dispatch.md`, 1.9.0) distingue désormais ces runtimes (Claude Code, OpenCode, Cursor, Cline — `hostIntegration.dispatch.namedDispatch: true`) des runtimes **built-in-only** (kimi-code : `coder`/`explore`/`plan` seulement, aucun enregistrement custom), où un nom de rôle est INCONNU et retombe sur le built-in le plus proche. Vérifié 2026-07-31 : `~/.claude/gsd-core/.gsd-runtime` = `claude` sur les postes actuels. **Aucun mécanisme de repli construit** — VibeFlow ne cible qu'un runtime à ce jour, en bâtir un pour un runtime non ciblé serait de la sur-ingénierie ; le jour où un lab tourne sous un runtime built-in-only, cette ligne est le premier endroit à vérifier |
| **Namespace de branche des worktrees d'exécuteur** (recoupement vérifié conforme, Phase 21) | `gsd-worktree-path-guard.js` (hook `PreToolUse`, `~/.claude/hooks/`) | l'amont 1.9.0 a élargi son motif d'allow-list à `^(worktree-)?agent-[A-Za-z0-9._/-]+$` (#1995 — accepte `agent-<id>` **et** l'ancien `worktree-agent-<id>`) : vérifié sur pièce le 2026-07-31, déjà présent dans le hook installé, aucun défaut. Le nouveau cas d'échec `{committed: false, reason: 'staging_failed' \| 'staging_timeout'}` (#2608) est entièrement interne à `gsd-executor` amont — aucune logique de retry VibeFlow ne l'enveloppe, le seul retry documenté porte sur l'étage entier (`vf-dev-manager.md` §Contrôle de flux), jamais sur un `git add` individuel. Rien à câbler, constat écrit ici pour survivre au prochain delta amont (détail : `21-02-SUMMARY.md` §Constat changement 4) |

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
  message, plusieurs Task. Périmètres douteux → séquentiel ou `isolation: worktree`.
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
de la mission.

Doctrine détaillée côté dev (le protocole complet de mission) :
`dev-orchestrator-references/mission-flow.md` — c'est la référence d'usage du kernel. Doctrine
des étages croisés (quand les insérer, forme DAG, budgets, invariants) :
`dev-orchestrator-references/mission-cross-team.md`.
