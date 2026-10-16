# Phase 32 — Reliquats de clôture (32-06)

Ce document consigne, par la mesure et non par l'appréciation, l'état réel à la clôture de la
Phase 32 (durcissement du driver-lock). Tout ce qui n'est pas adossé à une commande exécutée n'y
figure pas comme un fait acquis.

## 0. Sonde d'ordonnancement (BL-6)

`plugin/conductor/scripts/check-guard-health.sh` **existe** ET
`.planning/phases/VFDO-32-durcissement-du-driver-lock/32-05-SUMMARY.md` **existe** →
**le plan 32-05 a été LANCÉ ET LIVRÉ** (branche A pour QUAL-01, cf. §2).

## 1. Arbre suivi au moment du bilan

```
$ git status --porcelain --untracked-files=no
(vide)
```

Strictement vide — condition remplie. L'arbre porte des fichiers **étrangers** à cette phase en
non-suivi (`.gsd/`, `.planning/MISSION-*.dag.json`, un dossier `VFDO-36-…`) : ce ne sont **pas**
des artefacts de cette mission, ni commités ni supprimés, conformément au mandat.

## 2. Bilan du parc COMPLET — pattern CI exact, arbre commité

Pattern rejoué à l'identique de `.github/workflows/ci.yml:212` :
`find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Suites découvertes : 64** (> 62, valeur de référence avant-phase — la phase en a ajouté au
  moins une, `test-check-guard-health.sh`).
- **Suites exécutées : 64 / 64.**
- **Échecs : 0.**

Garde anti-vert-à-vide non déclenchée (64 ≠ 0).

## 3. Gates transverses du dépôt

| Gate | Commande | Résultat |
|---|---|---|
| Synchronisation versions/compteurs | `bash scripts/check-version-sync.sh` | **rc=0** — v2.54.0, 17 modules, 64 suites, tous les checks ✓ |
| Chemins machine | `bash scripts/check-machine-paths.sh` | **rc=0** — 1063 fichiers suivis balayés, aucun chemin absolu |
| Discipline de release | `bash scripts/check-release-tag.sh` | **rc=0** — VERSION=v2.54.0 ↔ tag v2.54.0, aucun bump racine non taggé |

Aucun fichier de version racine modifié par cette phase : `VERSION`, `plugin/.claude-plugin/plugin.json`
et `.claude-plugin/marketplace.json` sont absents de tous les diffs des commits de la phase (seul
`plugin/conductor/VERSION` a bougé, par la tâche 3 de ce plan).

## 4. Les cinq critères de succès de la Phase 32 — un par un, par exécution

| # | Critère (ROADMAP) | Commande de preuve | Verdict |
|---|---|---|---|
| 1 | Heartbeat séparé de la lease, TTL par défaut inchangé (LOCK-01) | `driver-lock.sh` expose `lease_seconds` (JSON `status`/`acquire`), jamais un facteur de péremption — `lock_age()`/TTL restent adossés au seul `heartbeat_epoch`. Preuve : `32-01-SUMMARY.md` T21.3/T23, 2 mutations rouges (lecture d'`acquired_epoch` au lieu de `heartbeat_epoch`) restaurées ; `bash plugin/conductor/scripts/tests/test-driver-lock.sh` → 132 PASS / 0 FAIL (mesuré dans le bilan §2) | **VERT** |
| 2 | Commit sous lock d'autrui bloqué à la source, entrée née de `merge-hooks`, armement prouvé (LOCK-02) | `guard-driver-lock.sh` posé en `PreToolUse(Bash\|Write\|Edit)`, forme exec, matcher combiné (contournement du bug d'idempotence cross-matcher §5). Preuve d'armement : lab jetable, `.claude/settings.local.json` porte l'entrée exec, dépôt courant NON armé (`git status --porcelain -- .claude/` vide). `bash plugin/conductor/scripts/tests/test-guard-driver-lock.sh` → 80 PASS / 0 FAIL (§2). Contournement réel rejoué comme cas de test (32-REJEU-contournements.md scénarios A/B) | **VERT** |
| 3 | Checkout de branche sous lock d'autrui détecté/bloqué (LOCK-03, D-32-A) | Amendé au cadrage : blocage porté par le MÊME guard `PreToolUse(Bash)` que le critère 2 (`checkout`/`switch` dans sa surface de commandes couvertes) — `reference-transaction` git écarté par le spike (`32-SPIKE-reference-transaction.md`, PAS SÛR : wedge rebase, casse worktree add, contournable). Preuve : même suite `test-guard-driver-lock.sh` (§2), cas B1-B4 (checkout tiers bloqué, détenteur passe) | **VERT** |
| 4 | Takeover explicite et tracé, jamais d'auto-steal (LOCK-04) | `acquire` refuse désormais en `stale-requires-takeover` (jamais de récupération implicite) ; verbes `takeover`/`reclaim` seuls à changer l'état, tous deux tracés dans le journal append-only avec identité du repreneur. Preuve : `32-02-SUMMARY.md`, `bash plugin/conductor/scripts/tests/test-driver-lock.sh` → 132 PASS / 0 FAIL (§2) | **VERT** |
| 5 | Jeton de fence en trailer, auditable (LOCK-05) | **SE-10, preuve triple, jamais le seul résultat de la sélection par trailer :** (a) section « Jeton de fence — quel commit sous quel mandat (LOCK-05) » existe dans `team-kernel.md` : `grep -c 'Jeton de fence' plugin/conductor/references/team-kernel.md` → **1**. (b) la recette d'audit s'exécute sans erreur : `git log --grep='^Fence: ' -E --format='%H %s' HEAD~30..HEAD` → **rc=0, résultat VIDE** (rejoué en direct au moment de ce bilan, cohérent avec 32-04-SUMMARY.md). (c) résiduel explicite : **aucun commit de cette phase — y compris ceux de CE plan — ne porte le trailer `Fence:` à ce jour** ; la convention est écrite et exécutable, elle entre en vigueur au **prochain mandat** qui commite sous cette doctrine. Ne PAS lire le résultat vide de (b) comme une preuve en soi — c'est (a)+(b)+(c) ensemble qui portent le critère | **VERT (convention posée, adoption non encore observée — voir §6)** |

## 5. État réel de QUAL-01 (D-32-QUAL)

**Fait machine (§0) : le plan 32-05 a été LIVRÉ → Branche A.**

Les quatre issues de QUAL-01 (D-32-QUAL, option B, tranchée par Samuel le 2026-08-16) :

| Issue | Couverture | Cas de test |
|---|---|---|
| 1. PASS (détenteur passe) | Couverte | `test-guard-driver-lock.sh`, cas détenteur (§2, 80 PASS) |
| 2. DENY (tiers bloqué) | Couverte | `test-guard-driver-lock.sh`, cas A/B (§2) |
| 3. Entrée imparsable → fail-open **silencieux** | Couverte | `test-guard-driver-lock.sh`, cas dédiés meta corrompu |
| 4. Garde indisponible → fail-open **BRUYANT** | Couverte **de bout en bout**, guard du verrou + reste du parc | `check-guard-health.sh` (neuf, `plugin/conductor/scripts/`), lecteur `SessionStart` générique des marqueurs `vf_guard_unavailable` (Phase 30). Boucle producteur → marqueur → lecteur prouvée avec les VRAIS scripts (D13 de `test-check-guard-health.sh`, 31 PASS / 0 FAIL — mesuré dans §2) |

Ce que la livraison change pour le RESTE du parc : `check-guard-health.sh` est **générique** — il
agrège les marqueurs de TOUS les gardes du parc (pas seulement `guard-driver-lock.sh`), c'était le
motif de l'extension de périmètre (D-32-QUAL, option B). Silence nominal mesuré tel qu'installé :
**0 octet** sur stdout quand aucun marqueur récent n'existe (`32-05-SUMMARY.md`).

**QUAL-01 est donc CLOS pour les quatre issues, sans dette résiduelle sur ce point précis.**

## 6. Ce qui reste ouvert — reliquats consignés honnêtement

### 6.1 Bug d'idempotence cross-matcher de `merge-hooks.sh` — NON CORRIGÉ, contourné

Deux entrées `hooks.json` référençant le **même script** sous le **même événement** (même si leurs
matchers diffèrent) se purgent l'une l'autre à l'installation — seule la **dernière traitée**
survit, **sans erreur ni avertissement**. Découvert empiriquement pendant le plan 32-03 (D-32-05
amendé) : la forme prescrite à deux entrées (`Bash` + `Write|Edit`) pour `guard-driver-lock.sh`
laissait disparaître l'entrée `Bash` du fragment installé.

**Contournement retenu, pas une correction** : une seule entrée `PreToolUse` à matcher combiné
`"Bash|Write|Edit"` — fonctionnellement équivalente puisque le script dispatche déjà sur
`tool_name` du payload. `merge-hooks.sh` lui-même (`plugin/_internal/`) n'a **pas été touché** —
hors périmètre de fichiers de la Phase 32.

**Trou de couverture** : `plugin/_internal/tests/test-merge-hooks.sh` ne couvre que le scénario
d'**upgrade en deux appels séparés** (une version du fragment puis une autre), jamais le
**même-run** — deux entrées neuves posées dans le **même** appel de merge sous le **même**
événement pour le **même** script, qui est le scénario qui a réellement mordu. Aucun autre module
n'est exposé aujourd'hui (vérifié : aucun autre fragment ne pose deux entrées pour un même script
sous un même événement). **Arbitrage humain en cours — dette assumée, pas corrigée par ce plan.**

### 6.2 Ce qui reste hors de portée du guard (catégorie C)

`guard-driver-lock.sh` est un **garde anti-accident, pas anti-adversaire** (vocabulaire déjà
assumé par `guard-agent-write.sh`). Restent structurellement hors de sa portée :

- une session **non armée** (lab non mis à jour, ou armement refusé au checkpoint) ;
- un **terminal humain** direct, hors Claude Code ;
- un **IDE ou client git tiers** (VS Code, GitHub Desktop, SourceTree…) ;
- un **processus en arrière-plan** ;
- un appel **MCP** ;
- une **autre machine** ;
- `bash -c` et `eval` — nommés explicitement comme passoires du matching par sous-chaîne de
  commande (`32-REJEU-contournements.md §6`), non couverts par construction.

### 6.3 Un lock né sans identité reste non opposable au guard pour toute sa vie

Si `session_ids` est vide à l'acquisition (lock créé par un chemin antérieur à la Phase 32, ou
rétrocompatibilité), **`heartbeat` ne le repeuple jamais** — seul `reclaim` le fait. Le guard ne
peut donc jamais comparer une identité de session inexistante : ce lock reste **non opposable**
pour toute sa durée de vie, jusqu'à un `reclaim` explicite. C'est désormais **observable** (le
champ existe et peut être lu vide), mais **pas rattrapable automatiquement**.

### 6.4 Aucun commit ne porte encore le trailer `Fence:`

Vérifié en direct au moment de ce bilan (§4, critère 5) : `git log --grep='^Fence: '` sur les 30
derniers commits rend un résultat **vide** — y compris les commits de CE plan de clôture. La
convention est écrite et exécutable dans `team-kernel.md` ; elle **entre en vigueur au prochain
mandat** qui commite sous cette doctrine. Le dire explicitement plutôt que de laisser croire que
LOCK-05 est déjà auditable sur l'historique existant.

### 6.5 `estimate:`/`actuals:` — tels que rapportés, sans recalcul

Seuls les plans 32-03 et 32-05 portent une section « Estimate / actuals » explicite dans leur
SUMMARY. Les autres SUMMARY (32-01, 32-02, 32-04, 32-07) ne rapportent pas ce champ sous cette
forme — il n'est donc pas inventé ici.

| Plan | Estimate (frontmatter PLAN) | Actuals (SUMMARY, verbatim) |
|---|---|---|
| 32-01 | tokens: 78000, tasks: 2, confidence: low | non rapporté sous forme `actuals:` explicite dans le SUMMARY |
| 32-02 | tokens: 105000, tasks: 3, confidence: low | non rapporté sous forme `actuals:` explicite dans le SUMMARY |
| 32-03 | tokens: 125000, tasks: 4, confidence: low | « 4 tâches sur 4 exécutées » (SUMMARY §Estimate/actuals) |
| 32-04 | tokens: 42000, tasks: 2, confidence: low | non rapporté sous forme `actuals:` explicite dans le SUMMARY |
| 32-05 | tokens: 85000, tasks: 3, confidence: low | « 3 tâches sur 3 exécutées (1 tracer + 2 auto), 3 commits, 0 tâche abandonnée malgré `abandonnable: true` » (SUMMARY §Estimate/actuals) |
| 32-07 | tokens: 58000, tasks: 2, confidence: low | non rapporté sous forme `actuals:` explicite dans le SUMMARY |
| 32-06 (ce plan) | tokens: 55000, tasks: 3, confidence: low | 3 tâches sur 3 exécutées, 3 commits (un par tâche) |

### 6.6 Checkpoint humain du plan 32-03 — NON répondu à ce jour

`<task type="checkpoint:human-verify" gate="blocking">` du plan 32-03 exige une décision humaine
explicite avant le geste d'armement réel (RELEASE du module `conductor`). **Toujours non répondu**
au moment de cette clôture. Ce qui reste à trancher par Samuel :
1. Le motif de refus complet du guard (nommant la commande de reprise) — déjà reproduit et vérifié.
2. La preuve d'armement en lab jetable — déjà reproduite et vérifiée.
3. Le fait que ce dépôt-ci n'a PAS été armé — déjà vérifié.
4. **La décision d'approuver l'armement** (à sens unique : les labs déjà mis à jour garderont
   l'entrée jusqu'à leur prochaine mise à jour), ou de faire évoluer le motif/l'échappatoire/le
   périmètre.
5. La déviation D-32-05 (une entrée `hooks.json` au lieu de deux, §6.1 ci-dessus) fait partie
   intégrante de ce qui est soumis à validation.

Ce checkpoint est la PREMIÈRE porte (avant PR et revue), pas la dernière ligne de défense : le
geste qui arme réellement « tous les labs qui installent `conductor` » est la RELEASE du module —
geste humain distinct, gaté séparément par `CLAUDE.md` §Discipline de release, hors périmètre de
cette phase.

## 7. Compteurs re-dérivés — `conductor`

Mesurés en direct, jamais recopiés :

| Compteur | README `conductor` (avant ce plan) | Réel mesuré | Statut |
|---|---|---|---|
| Scripts (hors tests) | « Scripts (15) » (titre) / « 14 scripts » (arborescence commentée) | **20** (`find plugin/conductor/scripts -maxdepth 1 -type f -name '*.sh' \| wc -l`) | **déjà faux AVANT la Phase 32** (mesuré à la re-validation externe du 2026-08-17 : 12 vs 17, puis 14 vs 18 selon la version) — la Phase 32 ajoute encore `guard-driver-lock.sh` et `check-guard-health.sh` à un compte déjà erroné |
| Suites de tests | « 12 suites » | **19** (`find plugin/conductor/scripts/tests -type f -name 'test-*.sh' \| wc -l`) | idem — écart PREEXISTANT, pas un simple incrément de cette phase |

**Ce n'est pas une régression causée par cette seule phase** : le README du module était déjà
désynchronisé de son contenu réel avant que la Phase 32 ne commence. La tâche 3 de ce plan corrige
l'écart PREEXISTANT en plus de l'incrément livré par la phase (2 scripts neufs, 2 suites neuves).

Compteurs racine (`README.md`/`README.fr.md`, gatés par `check-version-sync.sh`) : **déjà exacts**
à 64 suites — mis à jour au fil de l'eau par chaque plan qui a ajouté une suite (32-03, 32-05),
donc rien à corriger ici.
