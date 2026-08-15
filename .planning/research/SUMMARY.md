# Project Research Summary

**Project:** vibeflow-os — milestone fiabilite-v1.0
**Domain:** Plugin Claude Code distribué (17 modules, engine d'install scopé bash portable, parc installé chez des tiers, Windows inclus)
**Researched:** 2026-08-15
**Confidence:** HIGH

## Executive Summary

Ce milestone est un milestone de **fiabilité/gouvernance sur substrat existant**, pas de construction neuve : les 9 features (Windows II, manifeste+dry-run #20, durcissement driver-lock, watchdog managers, survie du ledger, budget d'instructions, ré-armement worktree, skill-installer, gaps agency-agents) se branchent toutes sur un moteur déjà durci (55 suites, gates machine, CI as-installed). La recherche converge sur une décision de stack sans appel : **zéro nouvelle dépendance runtime** — tout tient dans bash 3.2-compatible, la cascade `vf_python` d'ADR-054, `jqx`, et les mécanismes natifs du harness Claude Code (forme exec des hooks, hook `Notification`, notifications OS natives). Le « stack » du milestone est un stack de **techniques**, pas de paquets.

L'approche recommandée est dictée par les **fichiers, pas par les priorités** : Windows II (demande client, prioritaire) réécrit le contrat de sortie de tous les scripts de hook et apprend la forme exec à `merge-hooks.sh` — le substrat que trois autres features écrivent ensuite. Le manifeste (#20) travaille les mêmes fichiers `_internal/` : **F1 et F6 se séquencent, jamais en parallèle** (conflit garanti sur `merge-hooks.sh`/`vibeflow-update.sh`). ARCHITECTURE.md en tire un ordre de construction en 9 étapes, avec deux latences externes à démarrer **dès le jour 1** (RFC upstream gsd-core pour la survie du ledger, deadline 2026-10-26 ; veille release gsd-core > 1.10.0 pour le ré-armement worktree — vérifié sur npm le 2026-08-15 : latest = 1.10.0, la précondition n'est PAS satisfaite aujourd'hui).

Le risque dominant est celui de l'historique du repo : le **faux-vert** et l'**écart repo ↔ parc installé** (leçon #38 : un réglage settings local ne voyage pas). Les mitigations sont systématiques : ordre moteur→codes→fragments imposé par la machine pour Windows II, manifeste as-installed comme unique autorité de suppression, dry-run sur le même chemin de code que l'apply (modèle terraform plan), armement via règle 4 vf-requires/vf-provides. Critère de succès transverse à écrire dans le ROADMAP : **chaque nouveau gate est livré avec sa mutation rouge et une troisième issue distincte et bruyante pour l'imparsable** (imparsable ≠ conforme ≠ non-conforme).

## Key Findings

### Recommended Stack

Aucun paquet nouveau. Le milestone consomme l'existant et le harness : bash 3.2-safe (macOS système — `declare -A`/`mapfile` interdits), `vf_python` en **fonction** (seule forme qui porte `py -3`), `jqx()` (jq nu interdit — CRLF Windows), forme exec des hooks (`command` = chemin absolu de bash résolu à l'install, `args` = script+options). Voir STACK.md pour les techniques par feature.

**Choix techniques structurants :**
- **Manifeste d'install** : texte plat LF trié, un chemin relatif par ligne, diff par `comm -23` — format dpkg `.list`, zéro jq sur le chemin critique. Pas de checksums en v1 (surdimensionné vs le besoin #20).
- **Lock** : `flock(1)` INTERDIT (absent macOS ET Git Bash) ; le cœur symlink-génération de `driver-lock.sh` est mesuré et ne se rouvre pas — le durcissement porte sur l'**enforcement** (guard `PreToolUse(Bash)` exit 2, seul étage qui voyage avec le plugin), pas sur l'acquisition.
- **Notifications** : trio fichier de progression + notification OS native (`osascript`/`notify-send`/`powershell.exe`) via `notify.sh` posé par l'engine, fail-open silencieux. Aucun service externe (contrainte explicite). **Question ouverte : le canal de notification sur Windows** (`powershell.exe` proposé par STACK.md, à valider au cadrage — le milestone est Windows-first, pas d'`osascript` en dur).
- **Exit codes** : normalisation exit 3 interne → exit 0 à la frontière harness (`|| true` inexprimable en forme exec ; 3 hooks SessionStart sortent 3 en nominal aujourd'hui).

### Expected Features

**Must have (table stakes) :**
- F1 Windows II — lot PYBIN (3 fichiers → lib `vf-portable.sh`, contrat PR #29 consommé) + lot HOOKS en ordre strict (a) `merge-hooks.sh` apprend `args` → (b) codes de sortie → (c) fragments exec — **l'ordre est le contrat** (§1.3 : sinon hooks doublés + modules non désinstallables sur le parc)
- F6 Manifeste + dry-run même-chemin-de-code + nettoyage à l'update avec backup (issue #20 ; corrige le bug réel des verbes v1.x survivants ; fondation de F8)
- F4 Driver-lock : heartbeat ≠ lease (TTL par défaut inchangé), enforcement commit/checkout via guard PreToolUse, takeover explicite avec ID tracé
- F5 Battement par nœud DAG + **watchdog par absence de signal** (le stall 18 h : un manager bloqué ne notifie rien — le watchdog est LA feature)
- F2 Roll-over outillé du ledger + gate de non-disparition (dérive constatée 2×, le gate est un **lecteur/diff, jamais un régénérateur**)
- F3 Budget d'instructions mesuré + gate CI en ratchet (avertissement d'abord, blocage après — précédent §7)
- F7 Version gate machine gsd-core > 1.10.0 **installé** (close ≠ releasé ≠ installé), comparateur semver testé sur 1.9/1.10

**Should have (différenciateurs) :** hash conffile-style par fichier du manifeste, jeton de fence en trailer de commit, trace `carried-from:` par exigence, skills rendus disponibles à tous les agents (F8), `web-test-team` (seule piste F9 alignée fiabilité).

**Defer / anti-features :** import du catalogue agency-agents (couche de synonymes interdite charte), marketplace de skills maison (duplique `/plugin` natif), auto-steal du lock au TTL, notification par tick, dry-run en second chemin de code, armement via settings local (#38 rejoué).

### Architecture Approach

Tout s'intègre au substrat existant sans le renégocier : `_internal/` (engine + merge-hooks, écrivain unique de settings.json), `conductor` (driver-lock, guards, notify.sh nouveau), `dev-orchestrator` (règle 4 armement↔précondition, ensure-deps.sh porteur naturel du `vf-provides` gsd-core). Le manifeste vit en `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`, écrit par le seul engine, lu par update/uninstall/dry-run. L'enforcement du lock s'accroche en `PreToolUse(Bash)` (précédent `guard-agent-write.sh`) — **pas de hook git distribué** (ne voyagerait pas, leçon #38) ; limite assumée : l'humain hors session Claude n'est pas couvert.

**Composants majeurs :**
1. `merge-hooks.sh` étendu (forme exec, dédup cross-forme, chemin bash absolu) — précède tout fragment exec
2. Manifeste + `--dry-run` traversant dans `vibeflow-update.sh` — précède nettoyage, skill-installer
3. `guard-git-under-lock.sh` (conductor, PreToolUse Bash) + politique heartbeat/TTL
4. `notify.sh` + gestes de protocole dans team-kernel + signal stall SessionStart
5. Gates lecteurs : `check-requirements-survival.sh`, budget d'instructions dans/à côté de `check-agents.sh`

### Critical Pitfalls

1. **Fragments exec avant le moteur** — placeholder littéral, hooks doublés, modules non désinstallables, sans erreur ; imposer l'ordre par vagues dépendantes du plan et par un test de dédup cross-forme.
2. **Supprimer `|| true` sans traduire les exit 3** — chaque démarrage de session devient bruyant (pire : exit 2 involontaire bloque les outils) ; inventaire mesuré des 22 entrées, classement advisory/bloquant explicite.
3. **Nettoyage à l'update sans manifeste** — supprime des fichiers utilisateur ; jamais de diff disque↔catalogue, manifeste as-installed = unique autorité, test « fichier tiers intact ».
4. **Dry-run en chemin séparé** — annonce X, fait Y (précédent interne : blocker « faux-négatif dry-run » install-ux-v1.0) ; test dry-run == diff disque réel, sous mutation.
5. **Gate fail-open sur imparsable** — l'ennemi n°1 du repo (incident D-04) ; troisième issue distincte + mutation rouge livrée avec chaque gate + as-installed via `lab-frais-arme`.

## Implications for Roadmap

Ordre dicté par les dépendances fichier-niveau (ARCHITECTURE.md §4) :

### Phase 0 (jour 1, async) : Latences externes
**Rationale :** deux gates événementiels hors de notre contrôle — les démarrer avant tout code.
**Delivers :** RFC upstream open-gsd/gsd-core (suppression de REQUIREMENTS.md optionnelle, deadline 2026-10-26) + veille release gsd-core > 1.10.0 (`npm view @opengsd/gsd-core version`, pas le dist-tag `next` qui est périmé).

### Phase 1 : Windows II
**Rationale :** réécrit le substrat (contrat de sortie des 22 hooks, forme exec) que les phases 3, 4 et 6 écrivent — toute entrée de hook créée avant serait à re-migrer.
**Delivers :** lot PYBIN + lot HOOKS ordre strict (a)→(b)→(c).
**Avoids :** pitfalls 1-4.
**Pré-requis de cadrage bloquant :** trancher avec Willy le **trou d'affectation §3.2** (résolution du chemin absolu de bash à l'install) — la phase n'est pas planifiable avant. Question ouverte au contrat : exit code de `vf_guard_unavailable` sur PreToolUse (2 = bloque, autre = advisory). `guard-file-size.sh` gaté séparément si `vf-portable.sh` (tracer 01-01 Willy, non livré) tarde.

### Phase 2 : Manifeste + dry-run + nettoyage (issue #20)
**Rationale :** mêmes fichiers `_internal/` que le lot HOOKS — **séquencer après, jamais paralléliser** ; le dry-run s'écrit une fois, contre le moteur final ; fondation dure de F8 et du nettoyage.
**Delivers :** manifeste par module (vague 1), nettoyage avec backup (vague 2), `--dry-run` traversant y compris merge de hooks.
**Avoids :** pitfalls 5-6 (test « fichier tiers intact », test dry-run == diff disque).

### Phase 3 : Durcissement driver-lock
**Rationale :** son entrée de hook naît en forme exec sur le moteur de la phase 1 ; ne touche que conductor.
**Delivers :** guard PreToolUse git-sous-lock (bloquant agents, contournable humain, fail-open bruyant si lock illisible), politique heartbeat (TTL défaut inchangé), takeover avec ID.
**Avoids :** pitfall 7 — rejouer les 2 contournements réels comme cas de test AVANT de choisir le mécanisme.

### Phase 4 : Notifications managers + watchdog
**Rationale :** réutilise le heartbeat de la phase 3 (même battement, deux consommateurs).
**Delivers :** notify.sh (portable Windows dès v1), gestes de protocole aux jalons DAG, signal stall par absence de **marqueurs de progrès** (pas de liveness — cas « vivant mais bouclant » testé).
**Avoids :** pitfall 8.

### Phase 5 : Ré-armement worktree (flottante/conditionnelle)
**Rationale :** gatée par la release externe gsd-core > 1.10.0 installée — se déclenche quand la précondition tombe, ne bloque rien.
**Delivers :** `vf-requires`/`vf-provides` via ensure-deps.sh, ré-armement des 13 agents, validation `lab-frais-arme`. La Phase 28 existante porte le gate, **jamais le ré-armement** (mémoire projet).
**Avoids :** pitfall 11 (as-installed, comparateur semver testé).

### Phase 6 : Survie du ledger
**Rationale :** attend la réponse RFC (ou s'arme en avertissement) ; son hook SessionStart naît en forme exec.
**Delivers :** gate lecteur `check-requirements-survival.sh` (diff, jamais régénération), rejoué sur la clôture réelle d'agentique-v1.0. **Dur avant la clôture de CE milestone** (sinon 3e dérive).
**Avoids :** pitfalls 9-10.

### Phase 7 : Gaps agency-agents (web-test-team en priorité)
**Rationale :** fait grossir le corpus d'agents — doit précéder la calibration du budget. Requiert la sortie du statut expérimental de mobile-test (moule prouvé).

### Phase 8 : Budget d'instructions + étage outline
**Rationale :** ne pas calibrer un seuil sur un corpus qui bouge — après tous les ajouts d'agents. Ratchet, jamais de gate rouge durable.

### Phase 9 : Skill-installer global
**Rationale :** seule « nouvelle capacité » pure (minor bump de fin de milestone) ; hérite du manifeste (phase 2) dès le premier jour. Périmètre : câblage, pas catalogue ; collision de nom = refus.

### Phase Ordering Rationale

- **Le conflit fichier F1 ⟂ F6 sur `_internal/` est la seule vraie contrainte interne** : séquence stricte, un seul propriétaire du moteur à la fois.
- Windows II d'abord parce qu'il change le contrat que 3 features aval consomment (hooks du lock, du ledger, du stall) — zéro churn.
- F4/F5 partagent le battement : concevoir ensemble, livrer séparément.
- F7 est événementielle : aucune date maîtrisée, jamais bloquante.
- Mesure (F3) après croissance du corpus (F9 web-test-team).

### Research Flags

Phases nécessitant un `/gsd-plan-phase --research-phase` ou un spike :
- **Phase 3 (driver-lock) :** `reference-transaction` git (confiance MEDIUM, couverture checkout incertaine) — spike avant d'en dépendre ; sinon s'en tenir à PreToolUse.
- **Phase 4 (watchdog) :** hooks async + `asyncRewake` (feature jeune) — spike avant engagement ; définition de « progrès » = décision de cadrage n°1 ; canal Windows à valider.
- **Phase 1 (Windows II) :** pas de recherche mais un **cadrage externe bloquant** (affectation §3.2, exit code `vf_guard_unavailable` — avec Willy).

Phases à patterns établis (pas de recherche) : Phase 2 (dpkg/terraform, résolu partout), Phase 6 (gate lecteur, précédent `check-doc-drift.sh`), Phase 8 (précédent ADR-029/check-agents), Phase 5 (mécanique règle 4 existante).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Repo + docs officielles Claude Code + npm vérifiés le 2026-08-15 |
| Features | HIGH systèmes / MEDIUM écosystème | Patterns locks/manifestes/heartbeats multi-sources ; écosystème plugins Claude Code mouvant |
| Architecture | HIGH | Tout lu sur pièce (engine, gates, hooks, CI, spec, ROADMAP/BACKLOG) |
| Pitfalls | HIGH | Ancrés sur incidents documentés du repo ; MEDIUM sur pièges Windows généraux |

**Overall confidence:** HIGH

### Gaps to Address

- **Affectation §3.2 (chemin bash à l'install)** : trou entre les deux polarités — à trancher par écrit avec Willy AVANT le plan de la phase Windows II.
- **Exit code de `vf_guard_unavailable` sur PreToolUse** (2 bloque tout, autre dégrade) : question ouverte au contrat PR #29, décisive pour le lot HOOKS.
- **Canal de notification sur Windows** : `powershell.exe -Command` proposé, non prouvé terrain — le milestone est Windows-first ; à valider au cadrage de la phase 4.
- **`vf-portable.sh` non livré** (tracer 01-01 Willy) : dépendance calendaire du lot PYBIN pour `guard-file-size.sh` — gater ce fichier séparément si la lib tarde.
- **gsd-core > 1.10.0 non publié** au 2026-08-15 : phase 5 sans date, sonde `npm view` à câbler dès la phase 0.

## Sources

### Primary (HIGH confidence)
- `/websites/code_claude` (docs officielles Claude Code) — forme exec, hook Notification, statusLine, hooks async
- `npm view @opengsd/gsd-core` (2026-08-15) — latest 1.10.0
- Repo première main : spec Windows II 2026-08-02, ADR-054, `driver-lock.sh`, `merge-hooks.sh`, `vibeflow-update.sh`, CI, ROADMAP/BACKLOG/MILESTONES, mémoire projet
- Issue GitHub #20 (via `gh`)

### Secondary (MEDIUM confidence)
- Locks/leases : Lease Pattern, Fencing Gap, DynamoDB Lock Client — heartbeat ≠ lease
- Stall detection : Airflow zombie tasks, Step Functions HeartbeatSeconds
- Précédents package managers (dpkg `.list`, Homebrew INSTALL_RECEIPT, terraform plan)
- Écosystème plugins/marketplace Claude Code (sources communautaires)

### Tertiary (LOW confidence)
- Aucune — les points non re-sourcés (MSYS winsymlinks, MAX_PATH, noms réservés) sont classés MEDIUM et instruits au plan Windows II

---
*Research completed: 2026-08-15*
*Ready for roadmap: yes*
