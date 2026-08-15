# Phase 24 — Recherche ciblée

**Date :** 2026-08-04 · **Par :** `vf-coder` (mandat plan seul, reprise)
**Périmètre volontairement étroit.** `24-CONTEXT.md` (F-01→F-38), `24-ARBITRAGES.md` et le rapport
de mission `.planning/missions/2026-08-04-phase-24-activation-moteur-gsd.md` (§`research-web`, 4
points refermés) portent déjà l'essentiel. Deux questions seulement restaient ouvertes ; les deux
sont refermées ci-dessous **par mesure de première main**, sans accès web.

> ⚠️ **Deux faits mesurés ici contredisent une prémisse de l'arbitrage.** Ils sont signalés
> `TENSION` et remontés en `finding` — ils ne sont **pas** tranchés par ce plan.

---

## R-1 — Version cible de `@opengsd/gsd-core` (prérequis dur, zone 2 / GSDA-01)

**Question.** Quelle version publiée au-delà de `1.9.1` embarque le correctif de l'issue amont
#2893 (`windows append` détruit la prose sous le ledger et rapporte `ok: true`) ?

**Méthode.** Interrogation directe du registre npm (`npm view @opengsd/gsd-core versions|dist-tags|time`),
2026-08-04.

### Réponse — ❌ **AUCUNE. Il n'existe aucune version publiée au-delà de 1.9.1.**

| Fait | Valeur mesurée le 2026-08-04 |
|---|---|
| `dist-tags.latest` | **`1.9.1`** |
| Date de publication de `1.9.1` | **2026-07-31T13:11:48.066Z** |
| `dist-tags.next` | `1.7.0-rc.6` (2026-07-12) — **antérieur à `latest`**, canal dormant |
| Dernière version de la liste `versions` | `1.9.1` — aucune `1.9.2`, `1.10.x`, ni RC postérieure |
| PR corrective #2975 | mergée le **2026-08-01**, soit **≥ 11 h après** la publication de `1.9.1` |

**Conséquence directe — la clause de repli de `GSDA-01` s'applique telle qu'elle est écrite :**

> « Si aucune version publiée ne porte le correctif, la zone 2 est **explicitement différée** avec un
> **déclencheur de reprise objectif**, **jamais** activée sur une version vulnérable — et jamais
> silencieusement abandonnée. »

La zone 2 (`GSDA-04` `windows_enforce` + dérogation #3, `GSDA-05` `workflow_guard`) est donc
**différée**, pas exécutée, et son déclencheur de reprise est **objectif** : *publication sur npm
d'une version de `@opengsd/gsd-core` strictement supérieure à `1.9.1` dont les notes de version ou
le code de `bin/lib/broken-windows.cjs` portent le correctif #2893*. `GSDA-06` (refus de
`hooks.community` par ADR) **n'est pas gaté** : c'est un refus écrit, il ne touche pas au ledger.

### R-1b — La vulnérabilité atteint-elle `waive`, la commande exigée par `GSDA-04` ?

**Oui, à l'identique.** Mesuré dans `~/.claude/gsd-core/bin/lib/broken-windows.cjs` :

- `cmdWindowsWaive` (`:625-643`), `cmdWindowsAppend` (`:599-623`) et `cmdWindowsMarkFixed`
  (`:645-661`) appellent **tous les trois** le même `writeLedgerAtomic(cwd, ledger)` (`:558`).
- `writeLedgerAtomic` écrit `renderLedger(ledger)` (`:435-458`) — une **réécriture intégrale** du
  fichier : frontmatter + en-tête figé + table + bloc JSON, `join`és et rien d'autre. **Tout contenu
  du fichier absent de ces quatre blocs est détruit**, sans avertissement, avec `ok: true`.

Le gate posé par l'arbitrage était donc **fondé sur le mécanisme** : `waive` n'est pas une porte
dérobée, elle porte exactement la même destruction que `append`.

### R-1c — ⚠️ TENSION : notre `WINDOWS.md` ne porte **aucune** prose sous son ledger

L'arbitrage (zone 2) motive le prérequis dur par : « notre `.planning/WINDOWS.md` porte précisément
de la prose sous son ledger ». **Re-mesure du 2026-08-04 — la prémisse est fausse aujourd'hui :**

| Mesure sur `.planning/WINDOWS.md` | Valeur |
|---|---|
| Total | **87 lignes** |
| Fence JSON ouvrante / fermante | ligne **24** (` ````json `) / ligne **87** (` ```` `) |
| Contenu **après** la fence fermante | **vide — le fichier s'arrête sur la fence** |
| Contenu entre l'en-tête et la table | lignes 10-23 = **exactement** l'en-tête que `renderLedger` régénère mot pour mot (`# Broken Windows Ledger` + 3 lignes `>`) |
| Fences | **4 backticks**, conformes à `JSON_FENCE_OPEN = '````json'` (`:286-287`) — le fichier est bien canonique, `parseLedger` le lit sans erreur |

**Autrement dit : sur le fichier tel qu'il est aujourd'hui, un `waive` ne détruirait rien** — le
rendu canonique reproduit l'intégralité du contenu existant.

**Ce que ce fait NE fait PAS :** il ne lève pas le prérequis. Le verdict de Samuel est un **gate de
version**, pas un gate de contenu, et `GSDA-01` interdit d'activer « sur une version vulnérable »
sans condition de contenu. Le fichier peut aussi regagner de la prose entre-temps.

**Ce que ce fait fait :** il ouvre une question qui **appartient à Samuel, pas à ce plan** — le gate
peut-il être relâché pour la zone 2 au motif que la destruction est aujourd'hui sans objet sur notre
fichier ? → remonté en `finding` `action: ask-user`. **Le plan est écrit sur le verdict en vigueur :
zone 2 différée.**

---

## R-2 — API réelle des workstreams (dimensionnement de la zone 5)

**Question.** Quelle est la surface exacte à câbler pour `GSDA-13` → `GSDA-17` ?

**Méthode.** Lecture directe de `~/.claude/gsd-core/bin/lib/{workstream.cjs,
active-workstream-store.cjs}` et du routeur `bin/gsd-tools.cjs`, 2026-08-04.

### R-2a — Surface CLI : 7 sous-commandes, une seule liste d'erreur

`routeWorkstream({ args, cwd, raw, error })` dans `gsd-tools.cjs` (~`:1911-1933`) :

| Sous-commande | Signature réelle | Notes |
|---|---|---|
| `create <nom>` | `cmdWorkstreamCreate(cwd, args[2], { migrate, migrateName }, raw)` | flags `--no-migrate`, `--migrate-name <nom>` ; **migre par défaut** (`migrate: !noMigrate`) |
| `list` | `cmdWorkstreamList(cwd, raw)` | |
| `status [nom]` | `cmdWorkstreamStatus(cwd, args[2], raw)` | |
| `complete <nom>` | `cmdWorkstreamComplete(cwd, args[2], {}, raw)` | |
| `set <nom>` | `cmdWorkstreamSet(cwd, args[2], raw)` | écrit le pointeur |
| `get` | `cmdWorkstreamGet(cwd, raw)` | lit le pointeur |
| `progress` | `cmdWorkstreamProgress(cwd, raw)` | |

Toute autre valeur → `Unknown workstream subcommand. Available: create, list, status, complete, set,
get, progress`. **`migrateToWorkstreams` est exporté mais n'a pas de sous-commande propre** : la
partition passe par `create --migrate-name`.

### R-2b — Résolution du workstream actif : **3 niveaux de précédence**, pas un

`resolveActiveWorkstream(cwd, args, env, deps)` (`active-workstream-store.cjs:252-277`) — l'ordre
est strict et court-circuitant :

1. **`--ws <nom>` / `--ws=<nom>`** en CLI (`parseCliWorkstream:223-251`) → `source: 'cli'`.
   Le parseur **retire** le flag et sa valeur de `args` (les deux formes) et **jette** si la valeur
   manque ou commence par `--`.
2. **`env.GSD_WORKSTREAM`** non vide → `source: 'env'`.
3. **le pointeur de session** (`getActiveWorkstream`) → `source: 'store'`, sinon `source: 'none'`.

`applyResolvedWorkstreamEnv(resolution, env)` (`:278-282`) **repose** `env.GSD_WORKSTREAM = ws`.
Nom validé par `validateWorkstreamName` aux trois niveaux (alphanum, `-`, `_`, `.`).

> **Fait de dimensionnement décisif pour `GSDA-15`/`GSDA-16` :** `GSD_WORKSTREAM` est un **canal de
> premier rang**, indépendant du pointeur de session. Un worktree qui exporte `GSD_WORKSTREAM`
> résout son workstream **sans jamais toucher au fichier de `os.tmpdir()`**. C'est la voie de
> mitigation la moins coûteuse du risque (c) — et elle n'existait pas dans l'inventaire de risques
> de l'arbitrage.

### R-2c — Le pointeur : **deux** adaptateurs, pas un

`pickActiveWorkstreamAdapter(cwd, opts)` (`:170-185`) choisit :

| Condition | Adaptateur | Emplacement |
|---|---|---|
| `getWorkstreamSessionKey()` rend une clé | **session-scoped** (`:128-155`) | `os.tmpdir()/gsd-workstream-sessions/<sha1(realpath(.planning)) tronqué 16>/<clé>` |
| sinon | **shared** (`:110-127`) | **`<cwd>/.planning/active-workstream`** — dans le dépôt, donc naturellement par worktree |

`getWorkstreamSessionKey()` (`:78-86`) rend la première clé trouvée parmi
`WORKSTREAM_SESSION_ENV_KEYS` = `GSD_SESSION_KEY`, `CODEX_THREAD_ID`, `CLAUDE_SESSION_ID`,
**`CLAUDE_CODE_SSE_PORT`**, `OPENCODE_SESSION_ID`, `GEMINI_SESSION_ID`, `CURSOR_SESSION_ID`,
`WINDSURF_SESSION_ID`, `TERM_SESSION_ID` — à défaut le TTY de contrôle (`TTY`/`SSH_TTY` puis
`probeTty()`).

**Mesuré dans ce runtime (2026-08-04) : `CLAUDE_CODE_SSE_PORT` est PRÉSENT** (les autres sondées
sont absentes). **Donc sous Claude Code, c'est bien l'adaptateur `tmpdir` qui est retenu** — le
risque (c) de l'arbitrage est **CONFIRMÉ pour notre runtime**, et il n'est pas générique : un
runtime sans clé de session tomberait sur le pointeur in-repo, composable.

`getActiveWorkstream` (`:186-201`) **auto-nettoie** : nom invalide **ou**
`.planning/workstreams/<nom>/` inexistant → `adapter.clear()` puis `null`. C'est la sonde exacte que
`GSDA-16` doit rendre bruyante : aujourd'hui elle échoue **en silence**, en rendant `null`.

### R-2d — ⚠️ TENSION : `GSDA-14` nomme un fichier au mauvais endroit

`GSDA-14` et le ROADMAP (`:1563`) citent `planning-context.sh` dans la même énumération que
`check-dev-bootstrap.sh` et `check-state-integrity.sh`. Mesure : le fichier **n'existe pas** dans
`plugin/conductor/scripts/` — il vit dans **`plugin/planning-core/scripts/planning-context.sh`**
(4580 o., exécutable). C'est un module **différent**, avec son propre `VERSION`, `module.json` et
`CHANGELOG.md` : le rendre workstream-aware **touche le module `planning-core`**, pas
`dev-orchestrator` ni `conductor`. Périmètre et bump de version en conséquence. *(Simple correction
d'emplacement — aucun arbitrage rouvert.)*

---

## Ce que la recherche n'a PAS ré-ouvert

Conformément au mandat : `gsd-pattern-mapper` n'a pas été relancé (`24-PATTERNS.md`, 400 l., commité).
Les 4 points web (PR #27, broken windows, `context_profile`, canal de remontée amont) restent
refermés par le nœud `research-web` de la mission — **non re-sondés**, aucun accès web dans ce mandat.

## Sources

Toutes de première main, 2026-08-04 :
`npm view @opengsd/gsd-core {versions,dist-tags,time}` ·
`~/.claude/gsd-core/bin/lib/{broken-windows.cjs, active-workstream-store.cjs, workstream.cjs}` ·
`~/.claude/gsd-core/bin/gsd-tools.cjs` ·
`.planning/WINDOWS.md`, `.planning/config.json` ·
`plugin/conductor/{AGENT.md, scripts/check-agents.sh, scripts/check-state-integrity.sh}` ·
`plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` ·
`plugin/planning-core/scripts/planning-context.sh` · `printenv` sur les 4 clés de session sondées.
