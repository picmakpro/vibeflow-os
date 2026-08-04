# Design — Portabilité Windows II : résolution Python centralisée et hooks en forme exec

> **⏸ STATUT : EN ATTENTE — décision reportée après les Phases 23, 24 et 25 (arbitrage Samuel,
> 2026-08-02).** Cette spec ne doit **pas** être convertie en phase en l'état. Le doute porte sur le
> rapport bénéfice/complexité du **lot HOOKS** (§3.2, §3.4) : forme exec, chemin absolu figé,
> inversion des codes de sortie et réécriture de la dédup du moteur d'install, pour un bénéfice
> circonscrit aux chemins à espaces sous Windows. Le **lot PYBIN** côté dev (3 fichiers) reste peu
> coûteux et porte un défaut réel documenté au §1.1 (variante B). À réévaluer une fois le couplage
> au moteur GSD arrêté (Phase 23) et les capacités dormantes arbitrées (Phase 24) — deux chantiers
> qui peuvent déplacer la frontière de ce qui vaut la peine d'être outillé à la main.
>
> **Date** : 2026-08-02
> **Modules** : `_internal` (moteur d'install), `conductor`, `consolidator`, `dev-orchestrator`,
> `planning-core`, `software-architecture`, `infrastructure-audit`
> **Antécédent** : ADR-054 (2026-07-23) — portabilité Windows, premier temps : normalisation CRLF,
> préflight, gardes réellement actives, gate de synchro versions. Deux rapports terrain intégrés.
> **Origine externe** : Phase 1 de Willy (portabilité Windows côté ses modules), annoncée le
> 2026-08-02. Son exigence — « aucune résolution dupliquée ne subsiste » — est un **gate qui
> échoue**, pas une convention : il ne peut pas s'armer tant que les fichiers de ce périmètre n'ont
> pas bougé. Cette spec couvre **notre** côté de cette frontière.
> **Problème** : deux dettes de portabilité distinctes, l'une bénigne et dupliquée 15 fois, l'autre
> capable de rendre les modules non désinstallables sur le parc installé.

---

## 1. Problème

### 1.1 La résolution Python est dupliquée dans 17 fichiers — et a déjà divergé

Le bloc de résolution — `PYBIN=python3`, repli sur `python`, neutralisation du stub Microsoft Store
(`App Execution Alias` : `command -v` réussit mais l'exécution pend) — existe en **deux variantes**
sur **17 fichiers et 7 modules** :

**Variante A — bloc complet, avec neutralisation `WindowsApps` : 15 fichiers.**

| Module | Fichiers |
|---|---|
| `consolidator` | 6 (`guard-bash-registres`, `guard-read-registres`, `post-edit-reindex`, `probe-memory-guards`, `reindex`, `tests/test-windows-guards`) |
| `conductor` | 5 (`check-agents`, `check-debug-research`, `check-plugin-update`, `guard-agent-write`, `update-banner`) |
| `_internal` | 1 (`merge-hooks.sh:55-64` — le moteur d'install lui-même) |
| `installer` | 1 (`preflight.sh`) |
| `planning-core` | 1 (`planning-task-context.sh`) |
| `software-architecture` | 1 (`guard-file-size.sh:40-42`) |

**Variante B — résolution nue, `command -v python3` sans neutralisation `WindowsApps` : 2 fichiers**,
tous deux dans `dev-orchestrator` : `inject-mcp-tools.sh:145` et `tests/test-dev-orchestrator.sh`.

**La divergence n'est pas hypothétique, elle est déjà là.** Les fichiers de la variante B sont
exposés au stub Microsoft Store que les 15 autres neutralisent — c'est-à-dire au cas précis pour
lequel le bloc a été écrit. C'est l'argument le plus fort en faveur de la lib : le copier-coller a
déjà cessé d'être fidèle.

**`inject-mcp-tools.sh` est actif en production** — question posée par Willy, réponse vérifiée :
`plugin/_internal/vibeflow-update.sh:252-270` le résout sur trois candidats (arbre cible, cache,
voisin du script) et l'invoque à chaque install/update, en best-effort. Il entre donc dans le
périmètre, et il est du mauvais côté de la divergence.

**Périmètre réel de cette phase : 3 fichiers, pas 17.** Le contrat (§7, lu sur la PR #29) réserve à
la polarité gouvernance les 14 fichiers de `conductor`, `consolidator`, `planning-core`, `_internal`
et `installer`. Restent côté dev :

| Fichier | Variante | Statut au contrat |
|---|---|---|
| `software-architecture/scripts/guard-file-size.sh` | A | nommé au §7 |
| `dev-orchestrator/scripts/inject-mcp-tools.sh` | B | « à vérifier — s'il est actif en production » → **il l'est** |
| `dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | B | **non mentionné** — à signaler |

Le wrapper `jqx()`, second axe du contrat, est défini **5 fois en production** — `_internal/resolve-deps.sh`,
`kpi-analyst/scripts/extractor-template.sh`, `kpi-analyst/scripts/kpis-writer.sh`,
`installer/scripts/build-module-catalog.sh`, `conductor/scripts/framework-version.sh` — **aucune
dans le périmètre dev**. Rien à faire de ce côté.

**Gravité : basse.** Mécanique, testable, réversible. Aucun effet sur le parc installé.

### 1.2 La forme shell des hooks n'est pas portable, et la doc amont tranche

Nos 22 entrées de hook sont toutes en **forme shell** — `command` est une chaîne passée à `sh -c`
(ou Git Bash / PowerShell sous Windows). La documentation Claude Code décrit une seconde forme,
**exec** : quand `args` est présent, `command` est résolu comme exécutable et lancé directement avec
`args` comme vecteur d'arguments, **sans shell**. Elle la **recommande explicitement pour les
placeholders de chemin**, chaque élément d'`args` passant comme un argument unique sans re-parsing
— ce qui supprime les problèmes de quoting sur les chemins à espaces, cas nominal sous Windows
(`C:\Users\...\Documents and Settings`).

Le principe est donc juste et la migration souhaitable. Le reste de cette section dit à quelles
conditions.

### 1.3 Le moteur d'install est aveugle à la forme exec — et c'est la vraie irréversibilité

`plugin/_internal/merge-hooks.sh` construit **toute** sa logique par extraction du basename de
script **dans la chaîne `command`** (`SCRIPT_RE`, l.106). Trois conséquences mécaniques si un
`hooks.json` passe en forme exec avant le moteur :

1. **Substitution perdue.** `resolved["command"] = h.get("command","").replace("{{VF_SCRIPTS}}", prefix)`
   (l.167) ne substitue que dans `command`. En forme exec le chemin vit dans `args` → le placeholder
   `{{VF_SCRIPTS}}` est écrit **littéralement** dans le `settings.json` de l'utilisateur. Hook mort,
   silencieusement.

2. **Idempotence morte → hook doublé.** `frag_basenames()` (l.109-115) et `references()` (l.118-130)
   ne voient plus aucun script → set vide. L'ancienne entrée en forme shell n'est jamais retirée, la
   nouvelle s'ajoute : **le hook s'exécute deux fois**, et un groupe supplémentaire s'empile à chaque
   update. Le commentaire de l.170-174 dit explicitement que cette dédup existe pour éviter
   exactement ça lors d'un changement de matcher.

3. **Désinstallation impossible.** Mode `remove`, l.181-183 :
   `basenames = frag_basenames()` puis `if not basenames: die("fragment sans script référencé — rien
   à retirer")`. **Un module migré en forme exec ne peut plus être désinstallé.** C'est l'effet
   irréversible sur le parc installé — pas la forme écrite, mais l'aveuglement du moteur qui l'écrit.

**Gravité : haute.** Chaque lab ayant fait un `update` avec des `hooks.json` migrés avant le moteur
porte des hooks doublés et un module non retirable, sans message d'erreur.

### 1.4 `|| true` porte l'advisory, et il n'existe pas en forme exec

17 de nos 22 entrées se terminent par `|| true` — une construction **shell**, inexprimable en forme
exec par définition (pas de shell). Or ce `|| true` est ce qui rend les signaux *advisory* au sens
d'ADR-031 : un hook qui échoue ne doit jamais bloquer ni polluer la session.

Mesuré le 2026-08-02 sur les trois hooks `SessionStart` de `dev-orchestrator` :

| Script | `--hook`, cas nominal silencieux |
|---|---|
| `check-dev-bootstrap.sh` | **exit 3** |
| `discover-unintegrated-docs.sh` | **exit 3** |
| `check-doc-drift.sh` | **exit 3** |

Exit 3 est le code de **silence volontaire** du contrat de signaux (Phase 17). Sans `|| true`, il
remonte au harness **à chaque démarrage de session**, précisément dans le cas où le hook a décidé de
ne rien dire. Migrer la forme sans normaliser les codes de sortie transforme le mode nominal en
erreur affichée.

Les 19 autres entrées n'ont pas été mesurées — inventaire à faire au plan (certaines sont des gardes
`PreToolUse`/`PostToolUse` attendant du JSON sur stdin, à ne pas invoquer à l'aveugle).

---

## 2. Décision

**Un seul propriétaire, deux lots, un ordre imposé.**

1. **Lot PYBIN** — les **3 fichiers du périmètre dev** (§1.1) passent au bloc localisateur + à la
   cascade `vf_python`. La lib n'est pas écrite ici : elle est **consommée**, produite par le tracer
   `01-01` de la polarité gouvernance. C'est le gate de Willy qui définit la conformité, autant
   consommer son contrat plutôt que d'en réinventer un.

2. **Lot HOOKS** — migration en forme exec, dans cet ordre strict :
   **(a)** `merge-hooks.sh` apprend `args` (substitution, dédup, ownership, `remove`) ;
   **(b)** les codes de sortie des scripts de hook sont normalisés à 0 sur les cas silencieux ;
   **(c)** les six `hooks.json` passent en forme exec.

   **L'ordre n'est pas une préférence, c'est la condition de non-régression du parc** (§1.3). Livrer
   (c) avant (a) produit des labs avec hooks doublés et modules non désinstallables.

**Pourquoi un seul propriétaire plutôt qu'une co-livraison** : le lot HOOKS traverse
`plugin/_internal/`, c'est-à-dire le moteur d'install partagé, et engage le `settings.json` de tous
les labs installés. Une frontière de revue au milieu d'un changement irréversible multiplie les
chemins d'erreur sans rien acheter. Le lot PYBIN, lui, est mécanique et pourrait être co-livré —
mais il n'y a pas de raison de séparer les deux lots entre deux personnes.

**Pourquoi une phase distincte plutôt que dans 24 ou 25** : sujets et fichiers disjoints. Les Phases
24 et 25 éditent `plugin/*/agents/*.md` (M3 `effort:` par rôle, A2 `agent_skills`, G1 gate de
densité) ; ce travail touche `plugin/*/scripts/*.sh`, `plugin/*/hooks/hooks.json` et
`plugin/_internal/`. Aucune intersection, aucune dépendance — y compris aucune dépendance à la Phase
23, contrairement à 24 et 25. Vérifié : zéro occurrence de portabilité Windows, de forme de hook ou
de résolution Python dans les sections des Phases 24 et 25.

---

## 3. Composants

### 3.1 Lib de résolution Python

Contrat lu sur la **PR #29** (`docs/CONTRAT-PORTABILITE.md`, 173 lignes, figé le 2026-08-02). Ce
qu'il impose côté consommateur :

- **Lib** : `plugin/_internal/lib/vf-portable.sh`, possédée par l'**engine** et posée à l'install par
  `copy_engine_lib()` dans `vibeflow-update.sh`. Aucun module ne peut l'emporter en se désinstallant.
- **Cinq symboles** : `vf_resolve_python`, `vf_python`, `vf_py_probe`, `jqx`, `vf_guard_unavailable`.
  `IS_WINDOWS` est portée par la lib — **ne pas la redéfinir localement**, ça casse sous `set -u`.
- **`vf_python` est une fonction, pas une variable.** C'est ce qui fait de `py -3` un barreau de
  plein droit — un `PYBIN=` ne peut pas porter un lanceur à argument. **Conséquence sur notre côté :
  `"$PYBIN" -c '...'` devient un appel de fonction.** Ce n'est pas un `sed`, c'est une édition
  raisonnée par fichier.
- **Bloc localisateur à quatre candidats**, reproduit à l'identique entre les marqueurs
  `# >>> vf-portable:locator` / `# <<< vf-portable:locator`, seul le préfixe de message variant. Le
  gate extrait le bloc entre marqueurs, normalise et compare des sommes de contrôle : deux sommes =
  dérive. C'est ce qui rend le copier-coller interdit **par la machine** et non par consigne.

**Correction d'une hypothèse de la première rédaction de cette spec.** Elle posait le silence de
`guard-file-size.sh:42` (exit 0 sans Python) comme un cas limite à préserver. **Le contrat l'inverse
délibérément, et il a raison** : une garde qui sort 0 sans avoir pu tourner est une *protection
muette* — l'utilisateur croit que l'Iron Law 300L le couvre alors qu'elle est éteinte. §7 est
explicite pour ce fichier : « renverser le silence : `vf_guard_unavailable` + sortie non-zéro ». Le
précédent inter-outils invoqué est juste (ESLint : exit 2 config fatale ≠ exit 1 findings ; API
Checks GitHub : `neutral`/`startup_failure` ≠ `failure`).

**Une question reste ouverte et elle est décisive** : le contrat dit « sortir non-zéro » sans
préciser **lequel**. Sur un hook `PreToolUse`, l'écart est énorme — **exit 2 bloque l'appel d'outil**
(donc toute édition de fichier tant que Python manque), tout autre code non nul remonte une erreur
visible et laisse l'édition passer. « Dégradé mais utilisable » contre « plus aucune édition
possible ». À faire trancher au contrat avant implémentation.

**Dépendance dure vers la polarité gouvernance** : `vf_guard_unavailable` écrit dans
`$VF_GUARD_HEALTH_DIR`, et c'est le **hook doctor de `conductor`** qui agrège les marqueurs et
escalade en refus bloquant après 3 sessions (contrat §4). Aucune de ces briques n'existe aujourd'hui
— `copy_engine_lib` → 0 occurrence, `VF_GUARD_HEALTH_DIR` → 0, hook doctor → 0, `vf-portable.sh`
absent. `guard-file-size.sh` **ne peut donc pas être migré avant** que le tracer `01-01` et le volet
conductor de la polarité gouvernance ne soient livrés.

**Périmètre** : les 3 fichiers du §1.1. `_internal/merge-hooks.sh` et `installer/preflight.sh`
reviennent à la polarité gouvernance pour leur **volet Python** — mais pas pour le volet hooks, voir
§3.2.

### 3.2 `merge-hooks.sh` — apprendre `args`

> **⚠ Trou d'affectation dans le contrat — le point le plus important de cette spec.**
> Le contrat §5 impose la forme exec et précise que `command` doit porter un **chemin absolu vers
> `bash`, « résolu et vérifié à l'install »** (un nom nu reproduirait le bug qu'on corrige). C'est
> du travail de **moteur d'install**, pas de fragment. Or le §7 n'attribue à la polarité dev que les
> deux `hooks.json`, et le §8 (séquencement : `01-01` lib → `01-03` consommateurs gouvernance + gate
> → Phase 27) **n'attribue ce travail à personne**.
>
> Sans lui, migrer les `hooks.json` produit les trois effets du §1.3 : placeholder écrit
> littéralement, hook doublé, module non désinstallable. **À trancher avec Willy avant tout plan** —
> c'est la seule dépendance croisée réelle entre les deux polarités.

Cinq points, tous dans le bloc Python embarqué :

- **Résolution du chemin absolu de `bash`** à l'install, avec vérification, et écriture dans
  `command` — exigence du contrat §5, aujourd'hui inexistante. Effet de bord à instruire : le
  `settings.json` produit devient **spécifique à la machine**, ce qu'il n'était pas.

| Point | Aujourd'hui | Cible |
|---|---|---|
| Substitution | l.167, `command` seul | `command` **et** chaque élément d'`args` |
| `frag_basenames()` | l.109-115, lit `command` | lit `command` + `args` |
| `references()` | l.118-130, lit `command` | lit `command` + `args`, même frontière de mot |
| Mode `remove` | l.181-183, `die()` si set vide | trouve les scripts en forme exec |

La régression du lookaround (l.121-128, « `archive.sh` ne doit pas matcher `gsd-archive.sh` ») doit
être **conservée telle quelle** et étendue aux éléments d'`args`, pas réécrite.

**Compatibilité descendante non négociable** : le moteur doit continuer à lire, dédupliquer et
retirer les entrées en **forme shell** — c'est ce que porte le parc installé au moment de l'update.
Un moteur qui ne saurait plus retirer l'ancienne forme produirait exactement le hook doublé qu'on
cherche à éviter.

### 3.3 Codes de sortie des scripts de hook

Inventaire des 22 entrées, puis normalisation : **0 sur le cas silencieux**, code non nul réservé
aux vraies erreurs. Le contrat de signaux de la Phase 17 (exit 3 = silence) reste valide **en interne**
au script ; c'est sa **traduction vers le harness** qui change, puisque `|| true` disparaît.

À trancher au plan : normaliser dans chaque script, ou interposer un lanceur unique
(`run-hook.sh <script>`) qui absorbe le code de sortie — la seconde voie garde les scripts
inchangés et reste testable, mais réintroduit un niveau d'indirection sous Windows.

### 3.4 Les `hooks.json`

Recensement complet du dépôt — **22 entrées sur 6 modules, 17 portant `|| true`** :

| Module | Entrées | dont `|| true` | Événements | Polarité |
|---|---|---|---|---|
| `planning-core` | 6 | 5 | SessionStart, UserPromptSubmit, Stop | gouvernance |
| `consolidator` | 6 | 4 | PreToolUse, PostToolUse, SessionStart, SessionEnd | gouvernance |
| `conductor` | 5 | 4 | PreToolUse, SessionStart | gouvernance |
| **`dev-orchestrator`** | **3** | **3** | SessionStart | **dev (§7)** |
| `infrastructure-audit` | 1 | 1 | SessionStart | gouvernance |
| **`software-architecture`** | **1** | **0** | PreToolUse | **dev (§7)** |

**Périmètre de cette phase : 4 entrées sur 2 modules.** `software-architecture` est le cas le plus
simple — une entrée, pas de `|| true`, garde `PreToolUse` : **candidat naturel au tracer-first**.

Le contrat §7 ajoute une exigence que la forme exec ne porte pas d'elle-même : **classer chaque
entrée `advisory` ou `bloquante`, explicitement**. Pour les trois entrées `SessionStart` de
`dev-orchestrator`, c'est directement le §1.4 — elles sont advisory par ADR-031, et leur exit 3 doit
être traduit avant que `|| true` ne disparaisse.

**Les 18 entrées de la polarité gouvernance dépendent du même moteur.** Que le trou d'affectation du
§3.2 soit comblé ou non les concerne autant que nous : si `merge-hooks.sh` n'apprend pas `args`,
c'est tout le parc qui casse, pas seulement les labs ayant `software-architecture`.

---

## 4. Tests

Trois suites existent et doivent rester vertes, puis s'étendre :

- `plugin/_internal/tests/test-merge-hooks.sh` — à étendre : substitution dans `args`, dédup
  cross-forme (une entrée shell existante retirée par un fragment exec et réciproquement), `remove`
  d'un fragment exec, idempotence sur trois passes.
- `plugin/_internal/tests/test-windows-crlf.sh` — inchangée, garde d'ADR-054.
- `plugin/consolidator/scripts/tests/test-windows-guards.sh` — à recouper avec la lib PYBIN.

**Discrimination par mutation**, convention du repo : réintroduire la lecture de `command` seul dans
`references()` doit faire échouer le cas de dédup cross-forme ; laisser `{{VF_SCRIPTS}}` non substitué
dans `args` doit faire échouer un cas dédié. Un test qui reste vert sous mutation ne prouve rien.

**Sonde de parc** : un cas montant un `settings.json` réaliste (entrées VF en forme shell + entrées
tierces + entrées gsd-core), puis `merge` d'un fragment exec, puis `remove` — attendu : zéro entrée
VF résiduelle, zéro entrée tierce touchée.

---

## 5. Frontières et hors-scope

- **vs Phase 23 / 24 / 25.** Aucune dépendance, aucun fichier commun (§2). Exécutable en parallèle.
- **vs ADR-054.** Second temps de la même doctrine, pas une révision : CRLF, préflight et gate de
  synchro versions restent tels quels. Un ADR de suite est probablement justifié pour la forme exec,
  parce qu'elle change ce qui s'écrit chez l'utilisateur.
- **vs Phase 1 de Willy.** Sa lib et son contrat sont **consommés**, pas réimplémentés. Deux
  couplages, pas un :
  - **calendaire** — son gate ne s'arme qu'après le merge de cette phase (§7) ; et à l'inverse,
    `guard-file-size.sh` ne peut pas être migré avant que `vf-portable.sh` et le volet conductor
    (`vf_guard_unavailable`, `$VF_GUARD_HEALTH_DIR`, hook doctor) n'existent — soit après son tracer
    `01-01` **et** son plan conductor. La Phase 27 n'est pas exécutable tant que ces deux-là ne sont
    pas livrés.
  - **structurel et non attribué** — le volet `args` de `merge-hooks.sh` (§3.2). C'est le seul point
    du dossier qui n'appartient à personne aujourd'hui.
- **Hors-scope** : la partition `.planning` en workstreams (→ Phase 24, item A9), la remontée
  upstream des 37 workflows GSD workstream-aveugles (portée par Willy), et toute autre migration de
  forme de hook que celle décrite ici.

---

## 6. Critères de succès

0. **Le gate de Willy passe au vert sur ce dépôt** — critère externe, et le seul qui prouve que les
   deux polarités parlent du même contrat. Séquencement : voir §8.
1. Les **3 fichiers du périmètre dev** (§1.1) ont rejoint la cascade `vf_python` : plus aucune
   résolution locale, bloc localisateur reproduit entre marqueurs, somme de contrôle identique à
   celle des autres consommateurs du dépôt.
2. Les **4 entrées de hook du périmètre dev** sont en forme exec, chacune classée `advisory` ou
   `bloquante` explicitement, et **aucune** ne dépend d'une construction shell.
3. Un `install` puis un `update` puis un `remove` sur un `settings.json` portant l'**ancienne** forme
   laisse zéro entrée VF résiduelle et zéro entrée tierce modifiée — prouvé par la sonde de parc §4.
4. Aucun hook n'écrit `{{VF_SCRIPTS}}` littéral dans un `settings.json`.
5. Le démarrage de session reste **silencieux** dans le cas nominal (régression §1.4 tenue par un
   test, pas par relecture).
6. `guard-file-size.sh` sans interpréteur Python **ne sort plus 0** : marqueur écrit, motif en
   stderr préfixé, code de sortie conforme à ce que le contrat aura tranché (§3.1). Prouvé en
   montant un `PATH` sans Python, pas par lecture.
7. Les trois suites existantes passent, et les nouveaux cas échouent sous mutation.

---

## 7. Armement du gate — avertissement d'abord, blocage après le merge

Question posée par Willy : câbler son gate en CI après la Phase 27, ou en mode avertissement d'ici
là ? **Recommandation : avertissement jusqu'au merge de la Phase 27, blocage ensuite.**

Trois raisons, dont deux sont des précédents de ce dépôt :

1. **Un gate rouge pendant des semaines entraîne à ignorer la CI.** Le rouge cesse d'être un signal
   et devient du bruit ; le premier vrai échec passe inaperçu.
2. **C'est exactement le motif que le moteur amont applique déjà** — cf. Phase 24, item A1
   (`workflow.windows_enforce`) : « *When false (default), windows are still tracked […] but ship
   does not block — teams can adopt tracking before enforcement* ». On adopte le suivi avant
   l'application ; le lab est déjà dans ce schéma pour le ledger broken-windows.
3. **ADR-031 (advisory par défaut)** est la doctrine maison : un signal propose, il n'exécute pas.
   Un gate qui bloque avant que la remédiation ne soit livrable inverse ce rapport.

**Condition de bascule** : le gate passe en bloquant dans le même commit que le dernier lot de la
Phase 27, pas avant, pas dans une PR séparée — sinon la fenêtre rouge se rouvre.

---

## 8. Note de séquencement

Cette spec est écrite **avant** que la Phase 27 n'existe au ROADMAP, volontairement : la Phase 26 et
la Phase 23 tournent au moment de sa rédaction (la 23 en worktree), et le ROADMAP est sous verrou de
driver. Elle sera convertie en phase par le pont outillé de la Phase 13 —
`gsd-ingest-docs --mode merge`, `type: SPEC` — au retour de ces deux chantiers, et rattachée à un
jalon explicite : le ROADMAP porte déjà la trace de ce qui arrive aux phases inscrites sans
milestone. `gsd-alignement` (Phases 23-25) ne convient pas — sujet GSD, pas portabilité.
