# Architecture Research — fiabilite-v1.0 (intégration des features nouvelles)

**Domain:** Plugin Claude Code multi-modules + engine d'install bash (repo de distribution)
**Researched:** 2026-08-15
**Confidence:** HIGH (tout est lu sur pièce dans le repo : engine, gates, hooks, CI, spec Windows II, ROADMAP/BACKLOG)

> Milestone SUBSÉQUENT sur v2.52.0. Ce document ne redessine pas l'existant : il le cartographie
> comme substrat, puis dit **où chaque feature nouvelle se branche**, ce qui est **étendu** vs
> **créé**, et l'**ordre de construction** dicté par les dépendances fichier-par-fichier.

## 1. Substrat existant (cartographié, non renégociable)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ENGINE D'INSTALL (plugin/_internal/)                                     │
│  vibeflow-update.sh   install/update/uninstall/rollback/status           │
│    · registre versions : $TARGET_ROOT/scripts/.vibeflow-installed        │
│    · backups : $TARGET_ROOT/.backups/ · retired-modules.txt (en dur)     │
│    · resync gouvernance (version inchangée) : sync_module_governance()   │
│  merge-hooks.sh       SEUL écrivain de settings.json (clé hooks)         │
│    · dédup/remove par basename DANS la chaîne `command` (SCRIPT_RE)      │
│    · AVEUGLE à la forme exec (args) — cœur de la spec Windows II §1.3    │
│  resolve-deps.sh      fermeture transitive des module.json               │
├──────────────────────────────────────────────────────────────────────────┤
│ CONDUCTOR (team-kernel, socle gouvernance)                               │
│  driver-lock.sh       lock symlink-génération, meta owner/step/branch/   │
│                       worktree (ADR-064), heartbeat, TTL 1800 s          │
│  check-branch-claim.sh  ADVISORY SessionStart — constate, ne bloque pas  │
│  guard-agent-write.sh   PreToolUse(Write) — BLOQUANT (précédent)         │
│  check-agents.sh      charte ADR-044 + densité ADR-029 (lignes)          │
│  dag.sh               frontière ready inter-nœuds (stages, Phase 27)     │
│  references/team-kernel.md   protocole des managers                      │
├──────────────────────────────────────────────────────────────────────────┤
│ DEV-ORCHESTRATOR                                                         │
│  check-capability-activation.sh  règles 1-4 ; règle 4 = armement ↔       │
│    précondition (liste close : `isolation`, clés MCP) ; registre         │
│    vf-requires (frontmatter agents) / # vf-provides (scripts de preuve)  │
│  check-dev-bootstrap.sh (D-04 whitelist) · ensure-deps.sh (pose gsd-core)│
│  inject-mcp-tools.sh (variante B PYBIN — périmètre Windows II)           │
├──────────────────────────────────────────────────────────────────────────┤
│ HOOKS : 22 entrées / 6 modules, TOUTES en forme shell, 17 avec `|| true` │
│  (exit 3 = silence volontaire, contrat Phase 17 — traduit par `|| true`) │
├──────────────────────────────────────────────────────────────────────────┤
│ CI (.github/workflows/ci.yml)                                            │
│  tests (37 suites, découverte non vide) · gates strict · lab-frais       │
│  (install baseline + Gate C) · lab-frais-arme (as-installed testing :    │
│  installe la fermeture dans un lab temp, invoque le gate INSTALLÉ, ≥2    │
│  artefacts armés)                                                        │
└──────────────────────────────────────────────────────────────────────────┘
```

Deux invariants du substrat pèsent sur toutes les intégrations :
- **Un réglage settings ne voyage pas** (régression #38, ADR « armement sans précondition
  distribuée ») : toute feature dont l'activation dépend d'un état non distribué doit passer par
  la règle 4 (vf-requires/vf-provides) ou par un script posé par l'engine.
- **Advisory par défaut (ADR-031)** : un signal propose ; seuls les guards `PreToolUse` bloquent,
  et cela se déclare explicitement (exigence reprise par le contrat Windows II §3.4).

## 2. Intégration feature par feature — étendu vs créé

| Feature | Composants MODIFIÉS | Composants NOUVEAUX | Module hôte |
|---|---|---|---|
| Windows II lot HOOKS | `merge-hooks.sh` (apprend `args` : substitution, dédup cross-forme, remove, chemin absolu de bash) ; **tous** les scripts de hook (codes de sortie 0 = silence) ; les 6 `hooks.json` (forme exec, classement advisory/bloquant) | (option §3.3) lanceur `run-hook.sh` si la normalisation par script est écartée | `_internal` + 6 modules |
| Windows II lot PYBIN | 3 fichiers dev (`guard-file-size.sh`, `inject-mcp-tools.sh`, `test-dev-orchestrator.sh`) → cascade `vf_python` | `plugin/_internal/lib/vf-portable.sh` + `copy_engine_lib()` dans l'engine — **consommés**, produits par le tracer 01-01 de la polarité gouvernance (Willy) | `_internal`, `dev-orchestrator`, `software-architecture` |
| Manifeste + dry-run + nettoyage (issue #20) | `vibeflow-update.sh` : `install_module` écrit le manifeste ; `update_module` diffe ancien/nouveau et supprime les disparus (avec backup) ; flag `--dry-run` traversant install **et** merge de hooks ; `vf-calibrate` (skill) apprend `--dry-run` | Manifeste par module : `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>` (1 chemin/ligne, relatif à TARGET_ROOT) + suite `test-manifest.sh` dans `_internal/tests/` | `_internal` |
| Durcissement driver-lock | `driver-lock.sh` (politique TTL — mémoire : 1800 s < durée d'un mandat ; heartbeat) ; `conductor/hooks/hooks.json` (+1 entrée PreToolUse) | `guard-git-under-lock.sh` : guard `PreToolUse(Bash)` qui intercepte `git commit/checkout/switch` et consulte le meta du lock (branch+worktree déjà présents, ADR-064) | `conductor` |
| Notifications managers | `references/team-kernel.md` + protocoles `vf-dev-manager`, `vf-design-manager`, `vf-test-orchestrator` (geste de notification aux jalons) ; option : `update-banner.sh`/SessionStart pour le signal « mission stalled » (lock présent + heartbeat > seuil) | `notify.sh` (script posé par l'engine, best-effort : `osascript` macOS / `notify-send` Linux / no-op silencieux ailleurs) | `conductor` |
| Survie du ledger (Phase 18 héritée) | `dev-orchestrator/AGENT.md` (ligne de doctrine : archive = instantané) ; `dev-orchestrator/hooks/hooks.json` (+1 SessionStart) | `check-requirements-survival.sh` (modèle `check-doc-drift.sh`, détection d'ABSENCE uniquement) + sa suite ; **RFC upstream** `open-gsd/gsd-core` (suppression de REQUIREMENTS.md rendue optionnelle) — conditionne le GO, deadline 2026-10-26 | `dev-orchestrator` |
| Budget d'instructions (Phase 25 héritée) | `check-agents.sh` (siège naturel : il porte déjà densité ADR-029 et tourne en CI + SessionStart) ou gate frère dans `conductor/scripts/` ; G2 : chaîne discuss→plan dans `dev-orchestrator/AGENT.md` (étage outline) | métrique « charge d'instructions » (comptage de formes normatives) + seuil ; artefact outline (forme à trancher au plan : doc propre vs section de CONTEXT.md vs capability `plan:pre`) | `conductor` (G1), `dev-orchestrator` (G2) |
| Ré-armement worktree (suite Phase 28) | frontmatter des 13 agents (ré-poser `isolation: worktree` + `vf-requires: <id>`) ; `ensure-deps.sh` (c'est lui qui pose gsd-core : il peut PROUVER version > 1.10.0) | marqueur `# vf-provides: <id>` dans ensure-deps.sh (ou script de preuve dédié) — la règle 4 (liste close, ligne `isolation`) ne verdit que sur cette preuve ; `lab-frais-arme` valide as-installed | `dev-orchestrator` + tous modules porteurs d'agents armés |
| Skill-installer global | `/vibeflow-install` (UX toggles) + engine (les Types 1/2 skills existent déjà ; le neuf est le catalogue et la cible « skills disponibles pour tous les agents ») | catalogue de skills globaux + chemin d'install (module `installer` étendu ou module dédié) — **doit écrire son manifeste** (issue #20) dès le premier jour | `installer` / `_internal` |
| Gaps agency-agents | modules existants recevant de nouveaux agents ; chaque agent passe `check-agents.sh` (ADR-044), et la règle 4 s'il est armé | fichiers `plugin/*/agents/*.md` nouveaux | multiples |

## 3. Réponses aux questions d'intégration

### 3.1 Le manifeste : où il vit, qui le lit

- **Emplacement** (proposition du BACKLOG, cohérente avec le registre existant) :
  `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>` — même dossier que `.vibeflow-installed`,
  donc déjà couvert par la mécanique de scope et (en scope local) par `gitignore_add_paths`.
- **Écrivain unique : l'engine** (`install_module` à chaque pose ; le skill-installer global
  passe par le même chemin). Personne d'autre n'écrit.
- **Lecteurs** :
  1. `update_module` — diff ancien manifeste vs nouveau → supprime les chemins disparus (backup
     avant suppression, patron `backup_module`). C'est la « convergence à l'update ».
  2. `uninstall_module` — aujourd'hui il lit le **cache** pour savoir quoi retirer ; le manifeste
     devient la vérité de **ce qui a été réellement posé** (couvre le cas module retiré du cache,
     aujourd'hui rattrapé par `retired-modules.txt` en dur — qui reste pour l'historique du parc,
     mais ne grossit plus).
  3. Le mode `--dry-run` — rend le plan d'actions (poses, suppressions, merge de hooks) sans
     écrire ; consommé par `/vibeflow-install` et `/vf-calibrate`.
  4. (Optionnel, plus tard) `validator`/`vf-audit` — détection de dérive installé ↔ manifeste.
- **Ce que le manifeste ne remplace pas** : `.vibeflow-installed` (registre de versions) et le
  fragment `hooks.json` (les entrées de settings.json ne sont pas des chemins — leur convergence
  reste le travail de `merge-hooks.sh`, d'où l'interaction avec Windows II, cf. §4).

### 3.2 Le durcissement du lock : où s'accroche l'enforcement

Les deux contournements constatés (commit et checkout concurrents sous lock) sont passés parce
que le claim n'est consulté **qu'au SessionStart** (`check-branch-claim.sh`, advisory) et par les
managers. Le point d'accrochage naturel est **`PreToolUse` matcher `Bash`** :

- Tout geste git d'un agent passe par le tool Bash → un guard `guard-git-under-lock.sh` qui
  parse la commande (commit/checkout/switch/rebase), lit `$LOCK/meta` (les champs `branch` et
  `worktree` existent déjà — ADR-064 les a ajoutés exactement pour répondre à « qui tient CETTE
  branche ? ») et **bloque** (exit 2) quand l'écriture vient d'un arbre tiers sur une branche
  revendiquée par un lock frais. Précédent de guard bloquant dans le même module :
  `guard-agent-write.sh` (PreToolUse Write). ADR-031 est respecté si le classement « bloquant »
  est explicite (exigence que Windows II §3.4 formalise de toute façon).
- **Pas de pre-commit git** : VibeFlow ne possède pas les hooks git des labs (`core.hooksPath`
  est un geste local optionnel du repo, pas distribué) — un hook git ne voyagerait pas, même
  leçon que #38. Le hook Claude Code, lui, est posé par `merge-hooks.sh` à l'install.
- **Limite assumée** : un humain qui commit hors session Claude n'est pas couvert — le guard
  couvre le vecteur mesuré (sessions concurrentes), pas tous les vecteurs.
- Volet `driver-lock.sh` lui-même : politique TTL (mémoire projet : un TTL de 1800 s est plus
  court qu'un mandat de worker → périmé ≠ mort) et discipline heartbeat des managers — édition
  du script + de `team-kernel.md`, sans changer la forme du lock (le protocole
  symlink-génération est mesuré et ne doit pas être rouvert).

### 3.3 Les notifications : sur quoi elles roulent

Le BACKLOG tranche presque : la notification est **émise par le manager lui-même** aux moments
choisis (fin de mission, fin de nœud DAG, verdict de juge, halt) — l'inverse du hook Stop de
`stop-notify`. Intégration minimale et distribuable :

- **Vecteur = script posé par l'engine** (`conductor/scripts/notify.sh`), pas une entrée
  settings : un réglage settings ne voyage pas (#38), un script posé par `copy_module_scripts`
  voyage. Best-effort strict : `osascript` (macOS) → `notify-send` (Linux) → no-op, jamais
  d'échec propagé.
- **Déclenchement = geste de protocole** dans `team-kernel.md` + les 3 managers, aux frontières
  déjà existantes du plan de bataille (les nœuds `dag.sh ready` et les checkpoints sont les
  jalons naturels — aucun nouveau concept).
- **Le stall de 18 h** (le cas d'origine) n'est pas couvert par une notification émise par un
  manager mort. Deuxième volet : un **signal SessionStart** (ou une extension de
  `driver-lock.sh status`) « lock présent, heartbeat vieux de N heures » — même famille que
  `check-branch-claim.sh`, advisory. Pas de statusline dans ce repo : ne pas en inventer une.
- **Granularité configurable** : si un réglage est exposé, il vit dans `.planning/config.json`
  du lab (lu par le script), pas dans settings.json — même raison de distribution.

### 3.4 Le ré-armement worktree : comment il passe le gate de la Phase 28

Le chemin est entièrement tracé par l'existant : la règle 4 de
`check-capability-activation.sh` porte `isolation` dans sa **liste close** ; un agent ré-armé
doit déclarer `vf-requires: <id>` et un script du corpus de preuve doit porter
`# vf-provides: <id>` avec un cas de suite prouvant sa discriminance. Le porteur naturel de la
preuve est **`ensure-deps.sh`** : c'est lui qui installe/updater gsd-core, donc lui seul peut
attester « gsd-core > 1.10.0 installé » (fix #3302 releasé ET posé). `lab-frais-arme` rejoue
ensuite le tout as-installed. **Précondition externe dure** : tant que gsd-core > 1.10.0 n'est
pas publié, cette feature n'a pas de date — elle se planifie en flottant.

## 4. Ordre de construction — dicté par les fichiers, pas par les priorités

### Le nœud du problème : Windows II réécrit le substrat que les autres phases écrivent

- Le lot HOOKS change **le contrat de sortie de tous les scripts de hook** (0 = silence, plus
  d'`|| true`) et **la forme des 22 entrées** ; `merge-hooks.sh` apprend `args`.
- Or 3 features du milestone **ajoutent des entrées de hook** : le guard git du lock
  (PreToolUse), le gate de survie du ledger (SessionStart), et potentiellement le signal de
  stall. Chaque entrée écrite en forme shell **avant** la migration devra être re-migrée, avec
  son code de sortie re-normalisé et sa suite re-testée. Écrite **après**, elle naît en forme
  exec, classée advisory/bloquante, avec le bon contrat de sortie — zéro churn.
- Le `--dry-run` de l'issue #20 doit couvrir le merge de hooks : l'écrire contre l'ancien
  `merge-hooks.sh` puis le réécrire après l'apprentissage d'`args` serait le même travail deux
  fois.

**Verdict : Windows II d'abord** — et c'est cohérent avec PROJECT.md (« prioritaire, demande
client »). Le contre-argument du statut ⏸ de la spec (bénéfice/complexité du lot HOOKS) est
levé par l'arbitrage du milestone, mais **deux dépendances internes à la phase restent** :
1. le trou d'affectation §3.2 (chemin absolu de bash à l'install — travail de moteur non
   attribué entre les deux polarités) : **à trancher avec Willy avant tout plan** ;
2. `guard-file-size.sh` (lot PYBIN) ne peut pas migrer avant `vf-portable.sh` + le volet
   conductor (`vf_guard_unavailable`, `$VF_GUARD_HEALTH_DIR`, hook doctor) — livrer le lot
   HOOKS + les 2 autres fichiers PYBIN, et gater ce fichier-là séparément si la lib tarde.

### Séquence recommandée

| # | Phase | Rationale d'ordonnancement (fichier-niveau) |
|---|---|---|
| 0 (jour 1, async) | **Déposer la RFC upstream** (survie du ledger) + **poser la veille gsd-core > 1.10.0** | Deux latences externes (deadline RFC 2026-10-26 ; release tierce) — les démarrer avant tout code, elles ne coûtent rien et gatent les phases 5 et 6 |
| 1 | **Windows II** — ordre interne strict (a) merge-hooks apprend `args` → (b) codes de sortie → (c) hooks.json en exec | Substrat de tout le reste ; livrer (c) avant (a) casse le parc (§1.3 de la spec : placeholder littéral, hook doublé, module non désinstallable) |
| 2 | **Issue #20** — manifeste + `--dry-run` + nettoyage à l'update | Travaille `vibeflow-update.sh` (fichier disjoint de merge-hooks) mais le dry-run s'écrit UNE fois, contre le moteur final ; le manifeste doit exister avant le skill-installer (phase 8) pour que celui-ci trace ses poses dès le premier jour |
| 3 | **Durcissement driver-lock** (guard PreToolUse + TTL/heartbeat) | Son entrée de hook naît en forme exec sur le moteur de la phase 1 ; ne touche que `conductor` |
| 4 | **Notifications managers** (notify.sh + protocole + signal stall) | Petit, sans hook obligatoire (geste manager) ; profite du volet heartbeat de la phase 3 (le seuil de stall se lit sur le même meta) |
| 5 | **Ré-armement worktree** | Flottant : se déclenche quand gsd-core > 1.10.0 est installé — indépendant des phases 1-4, mais son `vf-provides` dans ensure-deps.sh et le passage de `lab-frais-arme` sont plus simples une fois le parc de hooks stabilisé |
| 6 | **Survie du ledger** (gate + doctrine) | Attend la réponse RFC (ou s'arme en mode avertissement, précédent §7 de la spec Windows II : suivi avant application) ; son hook SessionStart naît en forme exec |
| 7 | **Gaps agency-agents** | Fait grossir le corpus `plugin/*/agents/*.md` — doit précéder la mesure de la phase 8 |
| 8 | **Budget d'instructions + étage outline** | Même motif que « Phase 25 après Phase 24 » au milestone précédent : ne pas calibrer un seuil sur un corpus qui bouge — donc APRÈS agency-agents et après tous les ajouts d'agents des phases 3-5 |
| 9 | **Skill-installer global** | Indépendant, mais après le manifeste (phase 2) pour hériter du traçage, et en dernier parce qu'il est le seul item « nouvelle capacité » pur (les 8 autres sont de la fiabilité) — minor bump naturel de fin de milestone |

### Anti-patterns à ne pas commettre (leçons du repo, applicables ici)

- **Ne jamais livrer les hooks.json en exec avant merge-hooks** (spec §2 : hooks doublés +
  modules non désinstallables sur tout le parc — irréversible chez l'utilisateur).
- **Ne pas mettre l'activation d'une feature dans settings.json** (#38) : script posé par
  l'engine ou `.planning/config.json`, jamais un réglage local non distribué.
- **Pas de gate rouge durable** : tout nouveau gate (ledger, budget) suit le patron
  « avertissement d'abord, blocage au commit qui livre la remédiation » (spec Windows II §7,
  précédent `workflow.windows_enforce`).
- **Pas de « vert à vide »** : chaque nouveau gate asserte sa découverte non vide (contrat F13
  de la CI) et se prouve par mutation (convention des suites du repo).
- **Ne pas rouvrir le protocole du lock** : la forme symlink-génération est mesurée (24
  acquisitions concurrentes, correctifs de fenêtre mesurés PIRES) ; le durcissement s'ajoute
  autour (guard, TTL, heartbeat), il ne réécrit pas l'acquisition.

## 5. Changements de flux de données (résumé)

| Flux | Avant | Après |
|---|---|---|
| Install d'un module | pose fichiers + registre versions | + écrit `.vibeflow-manifest-<module>` ; `--dry-run` rend le plan sans écrire |
| Update version N→N+1 | re-pose, ne supprime jamais | diff manifeste → supprime les chemins disparus (backup) |
| settings.json | entrées shell `command` + `\|\| true` | entrées exec `command`+`args`, chemin bash absolu, codes de sortie normalisés, classement advisory/bloquant |
| Commit/checkout sous lock | invisible hors SessionStart | intercepté PreToolUse(Bash) → refus si arbre tiers sur branche revendiquée |
| Fin de nœud DAG / fin de mission | silencieux | `notify.sh` (best-effort, OS-natif) déclenché par le manager |
| Clôture de jalon | `git rm REQUIREMENTS.md` (amont, inconditionnel) | RFC → suppression optionnelle ; gate d'absence côté lab |
| Armement `isolation: worktree` | retiré (#39) | ré-armé sous preuve `vf-requires`/`vf-provides` (gsd-core > 1.10.0), validé `lab-frais-arme` |

## Sources

- `plugin/_internal/vibeflow-update.sh`, `plugin/_internal/merge-hooks.sh` (lecture intégrale)
- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` (spec, lecture intégrale)
- `plugin/conductor/scripts/driver-lock.sh`, `check-branch-claim.sh`, `plugin/conductor/hooks/hooks.json`
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` (en-tête + règle 4), `hooks/hooks.json`
- `.github/workflows/ci.yml` (jobs tests/gates/lab-frais/lab-frais-arme)
- `.planning/PROJECT.md`, `.planning/ROADMAP.md` (Phases 18 et 25 héritées, in extenso), `.planning/BACKLOG.md` (notifications, manifeste, skill-installer, agency-agents)
- `.planning/research/2026-08-10-agents-paralleles-etat-de-l-art.md` §Implications 3 (ré-armement)
