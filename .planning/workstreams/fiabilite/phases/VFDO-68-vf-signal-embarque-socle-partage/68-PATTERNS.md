# Phase 68: vf-signal embarqué sur le socle partagé - Pattern Map

**Mapped:** 2026-11-03
**Code 69 lu à :** `.claude/worktrees/phase-69b`, HEAD `812630cc` (plans 69-01 et 69-03 lus pour l'écart)
**Files analyzed:** 9 groupes (≈ 30 fichiers)
**Analogs found:** 8 / 9 (groupe 3 : partiel, aucun `rev-list` dans le socle)

Les chemins `plugin/cockpit/scripts/...` ci-dessous sont lus dans `phase-69b` (la 68 n'a pas encore le code de la 69).
Tous sont des fichiers suivis. Aucun miroir gitignoré cité.

## Écarts entre le contrat 69 « planifié » et le code présent (à lire en premier)

| Point | Plan 69 | Code `phase-69b` | Conséquence 68 |
|---|---|---|---|
| Dossier des suites | prompt : `plugin/cockpit/tests/` | **`plugin/cockpit/scripts/tests/`** (`plugin/cockpit/tests/` n'existe pas) | Nouvelles suites : `plugin/cockpit/scripts/tests/test-cockpit-<x>.sh`. La découverte CI est `find plugin scripts -path '*/tests/test-*.sh'` (`scripts/ci-shard-suites.sh:20`). |
| Contrat `avancement` | clé `avancement`, `version: 1`, `requis`, `etats`, `reste` | idem **plus** `missionEtats: ["running","failed","done","ready"]` (`vf-cockpit-interface.json:4-11`), absent du plan (grep `missionEtats` : 0 dans 69-01/69-03) | La montée de version ajoute `abandonnee` et `inconnu` (P68-D-23) à `missionEtats` ; A7 compare ce vocabulaire à `etatMission` (`test-cockpit-avancement.sh:87-88`). |
| Exports `avancement.mjs` | `ETATS, RESTE, LIBELLES_ETAT, LIBELLES_RESTE, decompte, trouverPhase, rattacherMission, etatMission, reste, avancement` | identiques (`vf-cockpit-avancement.mjs:2`) | Aucun écart de noms. |
| Forme `mission` | `{ nom, etat }` | `{ nom, etat }` (`choisir`, l.78-83) ; `etatMission(nodes)` ne reçoit **que** des nœuds | La règle de vie (verrou) ne peut pas vivre dans `etatMission` sans changer sa signature. Le module est déclaré « pur : ne lit que ce qu'on lui passe » (l.4). Il faut donc passer l'état du verrou **dans** `missions[]` (champ `vie`), lu en amont. |
| `who` | `cockpit-who@2` | `schema: 'vibeflow/cockpit-who@2'` (`who.mjs:121`), champ `rattachement` et `etatsSource` déclarés | Contrat `who@2` réel : `requis {at, root, trees, fresh, fenetre, busy, workers, sources}`. Le `schema` n'est PAS dans `requis` de l'interface (alors qu'il l'est pour project/equipe) : à ne pas copier tel quel pour `signal@1`. |
| Consommateurs de `avancement.version` | — | grep `avancement.version/etat/mission` dans `scripts/*.mjs` : 0 consommateur hors tests ; `project.mjs` lit via `PROJECTION_ST` | La montée de version casse seulement les tests : `A2.5` (l.247), `A7` (l.78-82 `a.version !== 1`, l.293) et les mutations `mutate.mjs interface`. |

## File Classification

| Fichier nouveau / modifié | Rôle | Flux | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-signal.mjs` | utilitaire CLI + bibliothèque (émetteur JSON) | transform / lecture seule | `vf-cockpit-who.mjs` (export `collectWho` + CLI, l.1-13) | exact |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` (clé `schemas["vibeflow/cockpit-signal@1"]`) | config / contrat | — | blocs `vibeflow/cockpit-who@2`, `-equipe@1` (l.15-65) | exact |
| `vf-cockpit-avancement.mjs` (+ `planning.mjs` pour passer la vie) | utilitaire pur | transform | lui-même (l.50-94) ; discipline de version : `who@1` → `@2` (69-03, P69-PL-18) | exact |
| Lecture `driver-lock.sh status` | service (shell-out) | request-response | `who.mjs:15,23,100-110` (`sh()` + `driverLockScript`) | exact |
| Retard sur `main`, worktrees | utilitaire | transform (git local) | `who.mjs:34-48` (`worktree list --porcelain`) | partiel |
| `plugin/cockpit/signal/**` (mod) | composant / hooks de mod | event-driven + request-response | mod source `~/.claude/mods/vf-signal/` (hors dépôt, lecture seule) | exact (c'est la source) |
| `plugin/.claude-plugin/plugin.json` + `plugin/cockpit/signal/hooks/hooks.json` | config | — | `plugin.json` actuel (`"skills": "./installer"`) ; mod `hooks/hooks.json` | role-match |
| `plugin/cockpit/scripts/tests/test-cockpit-signal.sh`, `-vie.sh`, `-retard.sh` | test | — | `test-cockpit-who.sh`, `test-cockpit-avancement.sh` | exact |
| `plugin/cockpit/signal/hooks/vf-signal.test.tsx` | test (mod) | — | le test source (130 l.) | exact |
| `.github/workflows/ci.yml` | config CI | — | job `gates` (l.393+), `tests-shard` (l.85-330) | role-match |
| README module, CHANGELOGs, `VERSION`, README racine | doc / release | — | commit `aec75bba` (v2.75.0) | exact |

---

## Pattern Assignments

### 1. `vf-cockpit-signal.mjs` + déclaration dans `vf-cockpit-interface.json` (utilitaire, lecture seule)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-who.mjs` (phase-69b).

**En-tête, exports et CLI** (`who.mjs:1-13`) : commentaire de contrat (exports, sources, CLI `node vf-cockpit-who.mjs <root> [--fresh 180] [--json]`). Recopier ce format.

**Imports** (`who.mjs:9-19`) :
```js
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { driverLockScript, gitCommonDir, resolveScriptsDir, planningLayout } from './vf-cockpit-paths.mjs';
import { ls, mtime, readJson, cherche, masque, ... } from './vf-cockpit-lecture.mjs';
import { lireDags } from './vf-cockpit-planning.mjs';
```
**Shell-out borné** (`who.mjs:23`), à réutiliser tel quel (timeout 10 s, stderr muet) :
```js
const sh = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore','pipe','ignore'], timeout: 10000 }); } catch (e) { return e.stdout || ''; } };
```
**Contrat lu depuis le JSON, pas depuis le code** (`who.mjs:26-28`) : `const IFACE = readJson(path.join(HERE, 'vf-cockpit-interface.json')) || {};`

**Données à sérialiser** : `readPlanning(root, layout)` rend `{ phases: Map, phaseDirs, reqs: Map, milestones, ... }` (`planning.mjs:97-137`, chaque phase porte `avancement`) ; `lireDags(root, layout, phaseDirs)` rend un tableau (`planning.mjs:79-94`). Le Map ne se sérialise pas seul : `[...P.phases.values()]` comme `A2` (`test-cockpit-avancement.sh:46-52`, `q.mjs`). `collectWho(root, opts)` donne `who@2` tel quel : l'embarquer sans recalcul (P68-D-15).

**Schéma versionné** (`interface.json:15-25`, forme à suivre pour `vibeflow/cockpit-signal@1`) :
```json
"vibeflow/cockpit-who@2": {
  "requis": { "at": "string", "root": "string", "trees": "array", "...": "..." },
  "travailleur": { "requis": [...], "optionnels": [...] },
  "interdits": ["doing", "mandat", "messages", "outils"]
}
```
Bonne pratique : ajouter `"schema": "string"` dans `requis` (comme `project@1`/`equipe@1`, l.34, 46), ce que `who@2` n'a pas ; garder `interdits` pour `signal@1` (hérite de `who@2`, aucun `doing`/`mandat`).

**Pièges connus (lus)** :
- `who.mjs:112` sérialise `_registre` en interne, retiré par `collectWho` ; l'émetteur appelle `collectWho`, jamais `gather`.
- Masquage des chaînes écrites par d'autres (`masque`, `bornes`, `who.mjs:118-122`) : tout champ libre de `signal@1` (nom de branche, nom de worktree) passe par `masque` + borne.
- Aucun réseau (CKPT-03/28) : la suite `test-cockpit-avancement.sh` A6 charge une sonde (`sonde.mjs`, `VF_SONDE_OUT`, l.58-66) qui refuse `net/tls/dns/http/https` ; rejouer la sonde avec témoin positif sur l'émetteur.
- Le chemin d'`interface.json` est relatif à `import.meta.url` : l'émetteur doit rester dans `scripts/` (la pose engine est **plate**, voir groupe 5).

---

### 2. Règle de vie `abandonnee` (`vf-cockpit-avancement.mjs`, montée de version)

**Analogue :** `vf-cockpit-avancement.mjs` (phase-69b l.50-94) ; discipline de montée : 69-03 (`who@1` → `@2`, CKPT-28) + A7.

**Fonctions concernées** :
```js
export function etatMission(nodes) {            // l.50-56 : running > failed > done > ready
  const ns = Array.isArray(nodes) ? nodes : [];
  if (ns.some((x) => x?.status === 'running')) return 'running';
  ...
}
function choisir(missions) {                     // l.78-83 : running d'abord, puis règle, puis nom
  const l = missions.map((m) => ({ nom: m.nom, regle: m.regle ?? 9, etat: etatMission(m.nodes) }));
  ...
}
export function avancement({ ph, fichiers, missions, lire } = {}) {  // l.88-94
  const lance = ms.some((m) => etatMission(m.nodes) === 'running');
  return { version: 1, etat, plans: {faits,total}, correctifs, mission: choisir(ms), reste: reste(...) };
}
```
**À faire (forme)** : `missions[]` reçoit un champ `vie` (`{tenu, stale, progressAgeS, ttl}` ou `null`), calculé **hors** du module pur (lecteur de verrou, groupe suivant), sur le verrou **de la phase** de la mission (P68-D-22 : entrée `scope: phase` de `status --all`, mêmes `ws` et `phase` que la phase rattachée par `rattacherMission` ; repli sur l'entrée de compartiment sans verrou de phase, P68-D-26 ; `status --all` liste aussi les compartiments absents) ; `etatMission(nodes, vie)` rend `inconnu` si un nœud `running` existe et que `vie` vaut `null` (source illisible, P68-D-23), `abandonnee` si le verrou n'est pas tenu/est `stale` et que `progress_age_seconds` ≥ `ttl` (ou `null`), `running` sinon (et si `vie` est `undefined`). `lance` (l.89) ne doit plus compter une mission `abandonnee` ni `inconnu` : sinon la phase reste `en-cours`. Montée : `version: 2`, `missionEtats` + `abandonnee` + `inconnu` dans `interface.json`, `avancement.version` dans A2.5/A7.

**Pièges** :
- `who.mjs:116` (nœuds `running` + TTL 1800 déjà appliqué côté `who` via `age`, `stale`) vs `avancement` qui ne l'applique pas : même TTL, deux calculs. Réutiliser la valeur de TTL du JSON de `driver-lock.sh status` (`"ttl"`), pas un second littéral 1800.
- Jamais la date de modification d'un DAG (P68-D-16, mesuré égale après checkout).
- Un lock posé par l'ancien script rend `progress_epoch`/`progress_age_seconds` = `null` littéral (`driver-lock.sh:724-727`) : traiter `null` comme « pas de progrès récent » sans planter.
- Source illisible ≠ verrou absent (P68-D-23) : un script de verrous introuvable ou un JSON illisible rend `inconnu`, jamais `abandonnee` ; seul un verrou **lu** et absent (aucune entrée de phase dans `status --all`, qui ne liste un verrou de phase que s'il est présent) rend `abandonnee`.
- Le plan 69-01 fige « ajouts de champs seulement en version 1, renommage = version 2 » (69-01-PLAN l.139-140) : un état de mission **ajouté** à un vocabulaire fermé teste `missionEtats` (A7) : c'est la raison de la montée, à écrire dans le CHANGELOG.

**Test à copier** : A7 (`test-cockpit-avancement.sh:76-90, 291-296`) compare `interface.json` aux exports et détecte une copie mutée (`mut/`, l.285) : étendre `vocab` avec `etatMission(..., vieAbandonnee)`.

---

### 3. Lecture de `driver-lock.sh status`, retard sur `main`, worktrees (sans réseau)

**Analogue (verrou) :** `who.mjs:100-110` + `vf-cockpit-paths.mjs` (`driverLockScript(root, scriptsDir)`, déjà « résolu hors de l'arbre observé : T-67-06 », `who.mjs:6-7`). Test : `test-cockpit-who.sh` W2 (« verrou via un driver-lock.sh de HOME », `HOME_T/.claude/scripts`).

**Sortie à analyser** (`driver-lock.sh:712-731`) : JSON `{"present": true, "owner", "step", "age_seconds", "ttl", "stale", "generation", "session_ids", "lease_seconds", "guard_effective", "progress_epoch", "progress_age_seconds", "children_running", ...}`. `branch=`/`worktree=` du méta **ne sont pas exposés** (constat 68-CONTEXT). `status --all` n'agrège qu'en lab partitionné (l.1141) ; la version présente sur `main` est à relire à l'exécution (verrou par phase sur `feat/driver-lock-par-phase`, non mergée).

**Analogue (worktrees)** — `who.mjs:36-41` :
```js
const porcelain = sh('git', ['-C', root, 'worktree', 'list', '--porcelain'], root);
const branchOf = new Map(porcelain.split('\n\n').map((b) => [/^worktree (.*)$/m.exec(b)?.[1],
  /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '')]).filter(([t]) => t && fs.existsSync(t)).map(([t, br]) => [fs.realpathSync(t), br]));
```
Réutiliser, ne pas réécrire : exporter `contexte`/`branchOf` de `who.mjs` ou extraire dans `vf-cockpit-paths.mjs`.

**Phase active d'un worktree** : appeler `readPlanning(<worktree>, planningLayout(<worktree>))` (le planning est par arbre ; `readPlanning` ne lit que `<root>/.planning`, 68-CONTEXT). La phase active n'est plus `current_phase` (retirée par la 69, `A18`) : prendre la phase `en-cours` d'`avancement` (la première) ou la branche.

**Aucun analogue pour le retard** : aucun `rev-list`, `merge-base`, `origin/` dans `plugin/cockpit/scripts`. À écrire avec le même `sh()` :
```js
sh('git', ['-C', t, 'rev-list', '--count', 'HEAD..main'])        // retard sur main local
sh('git', ['-C', t, 'rev-list', '--count', 'HEAD..origin/main']) // retard sur origin/main local (dernier fetch)
fs.statSync(path.join(gitCommonDir(root), 'FETCH_HEAD')).mtimeMs  // âge du dernier fetch, sans réseau
```
`gitCommonDir` est déjà exporté par `paths.mjs` (importé `who.mjs:13`). **Pièges** : `FETCH_HEAD` absent (jamais de fetch) → âge `null`, jamais 0 ; `origin/main` absent → champ `null`, pas d'erreur ; `main` peut s'appeler autrement (lire `refs/remotes/origin/HEAD` avant de coder `main` en dur, sinon violation « aucun nom de lab codé en dur », `avancement.mjs:5`) ; worktree détaché → `(détachée)` ; `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null` dans les suites (`test-cockpit-avancement.sh:17`).

**Test (fixtures git)** : copier la construction de dépôts de `test-cockpit-who.sh` (mktemp + `git init`, `worktree add`) ; témoin rouge VFSG-05 : arbre en retard de 3 commits → badge `retard 3`, deux worktrees → deux lignes ; témoin réseau : sonde A6.

---

### 4. Import du mod sous `plugin/cockpit/signal/` (nom proposé : `plugin/cockpit/signal/`)

**Source (lecture seule, hors dépôt) :** `~/.claude/mods/vf-signal/` (la source fait foi, pas le cache `vf-mods/vf-signal/0.1.0`). Structure réelle : le code est sous **`hooks/`**, pas à la racine (le prompt disait « *.ts, *.tsx » à la racine) ; `hooks/hooks.json` = `{ "modules": ["./register.tsx"] }`. Le dossier `.claude-plugin/types/` (24 000 lignes de typings générés, `claude-code*/index.d.ts`) est un artefact d'outillage : **ne pas importer** (ADR-035 / SOBR : un ajout = un retrait) ; régénérer à la demande, `.gitignore` dedans.

| Fichier source (lignes) | Décision | Détail |
|---|---|---|
| `.claude-plugin/plugin.json` (8) | **retiré** | le mod n'est plus un plugin : déclaré par `plugin/.claude-plugin/plugin.json` (P68-D-11) |
| `.claude-plugin/types/*` (3 index.d.ts + tsconfig + .gitignore) | **retiré** | typings d'outillage, hors dépôt |
| `README.md` (54) | **réécrit** | fusionné dans `plugin/cockpit/README.md`, section « Pane terminal » |
| `tsconfig.json` (3) | gardé | garde `tsc` strict (constat : strict vert sur copie) |
| `types/index.d.ts` (146) | gardé, **adapté** | `interface PluginState` : `vf-signal.*` → `vibeflow.*` (P68-D-12) ; types `Disk`, `Macro`, `Loop` réécrits sur `signal@N` |
| `hooks/hooks.json` (1) | gardé | `{ "modules": ["./register.tsx"] }` ; **pas** sous `plugin/cockpit/hooks/` (P68-D-11) |
| `hooks/register.tsx` (186) | gardé, **réécrit** | ajouter le gating `cockpit=` (D-18), la détection de l'ancien mod (D-08), la commande `/vf-signal`, les atoms `{plugin:'vibeflow',...}` |
| `hooks/pane.tsx` (192) | gardé, **réécrit** | `l.73` : `$.process.run(argv, { cwd: await $.session.root(), timeoutMs: 15000 })` : base de l'appel `node` ; ajouter le bouton « Ouvrir le cockpit » (D-19) ; vue Équipe lit `who@2` |
| `hooks/refresh.ts` (76) | gardé, **réécrit** | `l.30` : `$.agent.list()` ne reste que pour les gestes « voir »/« demander l'arrêt » ; la source de l'arbre devient `signal@1.team` |
| `hooks/disk.ts` (226) | **retiré** | STATE, ROADMAP, MILESTONES, BACKLOG, scan DAG par date (`disk.ts:96,130,138`) remplacés par la sortie de l'émetteur (P68-D-17) |
| `hooks/ds.ts` (55) | **retiré** | couleurs « Signal » en dur ; remplacé par un fichier de tokens `tokens.ts` (seul lieu d'un nom de couleur), voir groupe 9. Garder `STAGE_LABEL`, `age`, glyphes `G` (déplacés dans `derive.ts`) |
| `hooks/derive.ts` (144) | gardé, **adapté** | `STAGE_OF` (regex d'agents), `attention(...)`, brief Markdown ; retirer ce qui lit `Disk` brut, `l.61-63` (premier nœud `running`) remplacé par `mission.etat` |
| `hooks/band.tsx` (41) | gardé, **adapté** | `l.11-16` atoms ; gating ; `C.human` (orange) → token statut |
| `hooks/views/mission.tsx` (131), `equipe.tsx` (94), `macro.tsx` (98), `common.tsx` (53) | gardés, **adaptés** | mission : `abandonnee` grisée + bouton d'élagage humain existant ; equipe : `who@2` ; macro : phases `avancement` ; plus aucun hex |
| `hooks/vf-signal.test.tsx` (130) | gardé, **réécrit** | `l.58` : `mock.env(on, { HOME: '/home/<user>' })` → chemin neutre (D-20, voir groupe 7) ; témoins rouges D-14 |

**Clés `$.state`** : la forme actuelle est `atom({ plugin: 'vf-signal', key: 'disk' } as const, null)` répétée dans band/pane/refresh/register (≥ 20 occurrences). Remplacer par un module unique `atoms.ts` exportant les atoms avec `plugin: 'vibeflow'` et supprimer les doublons : c'est le « retrait » qui compense l'ajout (SOBR-01). Piège mesuré : `plugin: 'vf-signal'` laissé quelque part ⇒ 10 erreurs de validation.

**Densité** : fichiers ≤ 226 lignes (ADR-035 tenu) : `disk.ts` supprimé, `register.tsx` ne doit pas dépasser son budget en ajoutant gating + détection + commande : extraire `gating.ts` (lecture de `.vibeflow-installed`) et `ancien-mod.ts`.

---

### 5. `plugin/.claude-plugin/plugin.json` et pose par l'engine

**Analogue :** `plugin/.claude-plugin/plugin.json` actuel : seule clé de composant `"skills": "./installer"` (version `2.75.0`, fichier géré par `bump.sh`). Ajouter une clé `hooks` pointant vers `./cockpit/signal/hooks/hooks.json` (un `../` interne est admis, une sortie du dossier du plugin refusée : mesuré, P68-D-11). Vérifier par `claude plugin validate plugin` avant d'écrire le plan.

**Pourquoi ce chemin** : `merge-hooks.sh:302` — `frag_hooks = fragment.get("hooks", {})` ; l'engine charge `"$CACHE_DIR/$mod/hooks/hooks.json"` (`vibeflow-update.sh:2837`) et `[ -f "$fragment" ] || return 0`. Donc tout `plugin/cockpit/hooks/hooks.json` serait fusionné dans les settings ; un fichier `{ "modules": [...] }` sans clé `hooks` fait mourir l'install (témoin rouge VFSG-01 : le poser et voir l'install échouer). **Piège** : `merge-hooks.sh` vit dans **`plugin/_internal/merge-hooks.sh`**, pas `plugin/conductor/scripts/` (le prompt le plaçait au conductor).

**Pose des fichiers par l'engine** (`vibeflow-update.sh:2984-3009`) : `copy_module_scripts` copie à plat `module/scripts/*.sh|*.mjs|*.js` vers `$TARGET_ROOT/scripts/` ; `scripts/tests/` et `plugin/cockpit/signal/` ne sont **pas** posés (c'est voulu, P68-D-13). Conséquence : `vf-cockpit-signal.mjs` ET toute nouvelle `.mjs` du socle doivent rester **plats** dans `plugin/cockpit/scripts/` (un sous-dossier ne serait pas posé), et l'émetteur importe ses voisins par `./vf-cockpit-*.mjs`.

**Registre** : `mark_installed()` (`vibeflow-update.sh:510`) écrit `"$mod=$version"` dans `scripts/.vibeflow-installed` (constante `VF_REGISTRY_RELPATH`, l.103) : ligne attendue `cockpit=v1.0.0` (format de `module.json.version`). Le gating du mod lit ce fichier dans `<root>/.claude/scripts/` puis `~/.claude/scripts/` (D-18) : parser `^cockpit=` ligne à ligne ; ne pas dépendre de la version.

**Piège** : `plugin.json` est bumpé par `scripts/bump.sh` (JSON `.version` seulement) : l'ajout de la clé `hooks` ne l'affecte pas, mais `check-version-sync.sh` compare aussi `plugin/.codex-plugin/plugin.json` : ne pas toucher ce manifeste Codex (le mod n'y a pas de sens).

---

### 6. Suites de test bash du cockpit (émetteur, vie, retard) et test du mod

**Analogues :** `plugin/cockpit/scripts/tests/test-cockpit-avancement.sh` (CKPT-13..18) et `test-cockpit-who.sh`.

**En-tête et helpers** (`test-cockpit-avancement.sh:1-27`, copier mot pour mot) :
```bash
#!/usr/bin/env bash
# test-cockpit-<x>.sh — <objet> (CKPT/VFSG-nn ; P68-D-nn). Sections : A0 contrôles positifs des fixtures ... ; Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { ... } assert_not() { ... }
```
`test-cockpit-who.sh:9-14` ajoute `. "$(dirname "$0")/hygiene.sh"; vf_hyg_init` et `trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT` : **à reprendre** pour toute suite qui lance un `node` ou un serveur (crash du 2026-11-02 : hygiène des processus).

**Outils node écrits par la suite** (jamais de long `node -e`) : `q.mjs` (import dynamique de `scripts/<f>.mjs` + `JSON.stringify`), `get.mjs` (extraction d'un chemin JSON), `validate.mjs` (clés requises + interdites à toute profondeur, `who.sh:38-`), `mutate.mjs` (copie mutée), `sonde.mjs` (réseau).

**Témoins rouges (discipline P67/P69)** : (a) copie mutée dans `$WORK/mut` (`cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" ...`, l.285) puis le test doit **rougir** sur la mutation ; (b) A0 : contrôles positifs des fixtures avant le code ; (c) sonde réseau avec témoin positif (`.charge` écrit ; `VF_SONDE_OUT`).

**Test du mod** : le test source (`hooks/vf-signal.test.tsx`, 130 l.) utilise `mock.env`, `on('agent.list', ...)`, `on('process.run', (_, e) => {...})` (l.58-76) ; sous `claude plugin test`, `process.run` n'atteint jamais la machine (D-14) : le test prouve l'argv construit (`['node', <plugin.root>/cockpit/scripts/vf-cockpit-signal.mjs, ...]`) et l'analyse du stdout, avec témoin rouge sur JSON invalide, rejet ENOENT simulé (« node introuvable dans le PATH ») et stdout tronqué. La chaîne réelle node + émetteur est couverte par la suite bash de l'émetteur (jouée en CI via la découverte `*/tests/test-*.sh`, `ci-shard-suites.sh:20`).

**Découverte des suites** : un nouveau `test-cockpit-*.sh` est joué automatiquement ; le job d'agrégation refuse une suite perdue ; aucune suite lourde à réserver (`HEAVY` ne liste que les deux `*-ws.sh` du conductor). Les suites du cockpit tournent toutes en shard (`SHARDS: "7"`, l.33).

---

### 7. CI : `.github/workflows/ci.yml`, `Gate-Touche`, `check-machine-paths.sh`

**Analogue :** `ci.yml` job `gates` (`name: Gates de qualité (mode strict)`, l.393+, étapes du type `- name: check-agents --strict sur chaque plugin/*/agents (découverte non vide)`, l.400) et `tests-shard` (l.85-330).

**Forme d'une étape à copier** (l.400-): `run: |` avec un `set -u`, une **assertion de découverte non vide** (« un shard vide est un échec, pas un vert », l.296-300), puis une boucle qui compte `ran` vs `count`. Pour le mod : étape `claude plugin validate plugin --strict` + `claude plugin test <dossier du mod>`.

**Pièges lus** :
- `claude` n'est **pas** installé en CI (aucune occurrence de `claude` en tant que CLI dans `ci.yml`, seulement des `~/.claude/gsd-core`, l.126-156) : l'étape doit installer le CLI (comme `npx -y "@opengsd/gsd-core@^1" --claude --global`, l.144) avant, ou être honnête : non prouvé sous Linux sans session authentifiée (point ouvert 68-CONTEXT). Premier geste du plan CI, avec **témoin rouge** (test cassé → job rouge) ; échec sous Linux ⇒ remontée à Samuel, pas de contournement.
- ubuntu-latest = 26.04 (coreutils uutils) depuis 2026-10-19 : lire l'image avant de suspecter la PR.
- gsd-core `^1` flottant : ne pas lier la nouvelle étape à `npm view` flottant.
- `HOME` : l'étape tourne sous `HOME` du runner ; le test du mod ne doit pas dépendre de `/home/<user>`.

**Garde-fous du dépôt** (CLAUDE.md) : toucher `.github/workflows/ci.yml` exige un trailer de commit `Gate-Touche: .github/workflows/ci.yml — <raison ≥ 10 caractères non blancs>` (`scripts/check-gate-touche.sh:46`), de portée branche (un commit ultérieur peut couvrir un chemin touché plus tôt), et la revue `@picmakpro` (CODEOWNERS, ruleset posé le 2026-09-23). Toucher une suite de gate ou une fixture surveillée (`plugin/conductor/scripts/tests/fixtures/**`, `scripts/tests/fixtures/**`) exige le même trailer ; les suites du cockpit (`plugin/cockpit/scripts/tests/`) n'en font pas partie.

**`check-machine-paths.sh`** : le gate rougit sur `/home/<login>/...` (`HOME: '/home/<user>'`, test source l.58). Ordre de préférence du script (en-tête, échappatoires 1 à 3) : (1) segment de compte = placeholder de la liste fermée (`user`, `username`, `utilisateur`, `you`, `me`, `moi`, `/home/runner`) ⇒ `HOME: '/home/user'` ; (2) segment non-identifiant `<user>` ; (3) marqueur `vf-allow-machine-path` sur la ligne, réservé au cas où le littéral EST le sujet. Retenir (1). Chercher aussi les autres chemins : `/Users/<user>` dans les commentaires copiés du mod.

---

### 8. Doc et release

**Analogue : le commit de bump `aec75bba` (release v2.75.0)** — 9 fichiers modifiés :
`.claude-plugin/marketplace.json`, `CHANGELOG.md` (racine, entrée en tête), `README.fr.md`, `README.md` (badges + historique, 3 lignes chacun), `VERSION`, `plugin/.claude-plugin/plugin.json`, `plugin/.codex-plugin/plugin.json`, `plugin/cockpit/CHANGELOG.md`, `plugin/conductor/CHANGELOG.md` (ligne « publiée dans VibeFlow vX.Y.Z »). Message : `release: vX.Y.Z — <résumé> (bump, sans tag)` + décision et canal/date (CLAUDE.md « traçabilité des arbitrages »).

**Geste** : `bash scripts/bump.sh <X.Y.Z>` (écrit les 6 sources de version + squelette CHANGELOG, idempotent, `--dry-run` disponible) ; verrou de dépôt avant (`driver-lock.sh acquire --depot --owner=<id> --step=release-bump`), relâché après le commit. Contrôle : `scripts/check-version-sync.sh` (compare les sources au canon) ; tag et release GitHub après merge : geste de Samuel (VFSG-13).

**Version du module `cockpit` (D-21)** : `plugin/cockpit/module.json` `"version": "v1.0.0"` et `plugin/cockpit/VERSION` `v1.0.0` ; 69 ne les monte pas en son état (grep `v1.0.0` ⇒ « publiée dans v2.75.0 »). Monter les deux d'une minor **après la valeur posée par la 69** : relire `plugin/cockpit/module.json` sur `main` rebasé avant de choisir `v1.1.0`/`v1.2.0`. `check-version-sync.sh` n'a aucun `cockpit` (grep : 0) ; compteurs de modules des README inchangés (pas de nouveau `module.json`).

**CHANGELOG du module** (`plugin/cockpit/CHANGELOG.md`, format l.1-12) : `## vX.Y.Z — <date>` puis `### Ajouté` / `### Modifié` ; la montée du schéma `avancement` (1 → 2, ou version retenue) va sous « Modifié » avec la raison (vocabulaire de mission élargi).

**README du module** (`plugin/cockpit/README.md`) : sections existantes l.16-19 (lanceur, `/vf-cockpit`), l.53-55 (inventaire FR), l.78 (« Schémas `vibeflow/cockpit-*@1`; contrat lisible dans `scripts/vf-cockpit-interface.json` »), l.92 (fenêtre mesurée). Ajouter : section « Pane terminal vf-signal », gating `cockpit=`, retrait de l'ancien mod (geste de Samuel).

**Piège** : l'en-tête de `vf-cockpit-interface.json` et le commentaire de `avancement.mjs` disent « lu par vf-signal (Phase 68) » : mettre à jour le texte avec la version montée.

---

### 9. DESIGN.md « Graphite » et tokens du mod

**Source :** `git show origin/docs/design-md:DESIGN.md` (PR #196, à merger avant l'exécution de tout plan de rendu, P68-D-09). Il nomme `vf-signal` (l.15, §1).

**Tokens de statut à relier** (tableau « Statuts de travail ») :

| Statut du mod | Token | Doit valoir |
|---|---|---|
| Fait / récent | `--st-done` | `var(--recent)` (`#4ade80` / `#157a3a`) |
| En cours, à recetter | `--st-active` | `var(--sev-medium)` (`#f0c36b` / `#946000`) ; « à recetter » écrit en toutes lettres |
| À faire | `--st-todo` | `var(--text-4)` (`#5c5c5c` / `#666666`) |
| Bloqué | `--st-blocked` | `var(--sev-high)` (`#f28b8b` / `#c94a4a`) |
| `abandonnee` (nouveau) | à nommer dans le plan | proposer `--st-todo` (grisée, D-05) + libellé « abandonnée, nœuds non refermés » |
| `inconnu` (nouveau, P68-D-23) | couleur de statut neutre | `--st-todo` (aucun token neuf) + libellé « état inconnu » |

Écart connu documenté dans DESIGN.md : `--st-active` vaut en dur `#f59e0b` et `--st-blocked` `#ef4444` dans `ui/00-vibeflow.js` (corrigé en Phase 70) : la pane doit déjà utiliser la colonne « Doit valoir », pas ces hex.

**Pas de CSS dans un TUI** : les couleurs de la pane passent par `<Text color=...>` avec des noms de thème de l'API des mods (voir skill `plugin-authoring`) : un fichier `tokens.ts` mappe `st-done|st-active|st-todo|st-blocked|text-2|text-3|text-4` vers les clés du thème (jamais un hex ; VFSG-07 : test qui rougit sur un hex `#[0-9a-f]{3,8}` dans les vues). Voir `band.tsx:11-41` pour l'usage actuel `C.human` (orange de marque : à supprimer), `C.fg`, `C.fg3`.

---

## Shared Patterns

### Module pur vs lecture
`vf-cockpit-avancement.mjs:4` « Module pur : ne lit que ce qu'on lui passe, aucune lecture réseau, aucun nom de lab codé en dur ». Tout nouveau code de calcul (vie de mission, retard) suit cette frontière : lecture disque/git dans un lecteur nommé, calcul en fonction pure testable.

### Shell-out borné
`who.mjs:23` (`execFileSync`, timeout 10 s, `stdio: ['ignore','pipe','ignore']`, `try/catch → e.stdout || ''`). À appliquer à `git`, `bash driver-lock.sh`, et côté mod : `$.process.run(argv, { cwd, timeoutMs: 15000 }).catch(() => undefined)` (`pane.tsx:73`).

### Contrat versionné
Un seul fichier (`vf-cockpit-interface.json`) ; le test compare le contrat aux exports (A7) et rougit sur copie mutée. Toute montée de version = test rouge d'abord (CKPT-28 : « test qui rougit si la sortie ne porte pas la nouvelle version »).

### Interdits de sortie
`"interdits": ["doing","mandat","messages","outils"]` (`interface.json`, `who@2` et `equipe@1`) : l'émetteur n'expose jamais ces clés, et `validate.mjs` vérifie à toute profondeur.

### Aucun réseau
Sonde `sonde.mjs` (A6 d'avancement ; `test-cockpit-reseau.sh`) : toute nouvelle sortie du socle la rejoue.

### Hygiène des suites
`hygiene.sh` (`vf_hyg_init` / `vf_hyg_fin`) dès qu'une suite lance un processus long.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Calcul du retard sur `main` (`rev-list`, âge de `FETCH_HEAD`) | utilitaire | git local | aucun `rev-list`/`merge-base`/`origin/` dans `plugin/cockpit/scripts` ; réutiliser `sh()` et `gitCommonDir` |
| Étape CI `claude plugin validate/test` | config CI | — | `claude` CLI absent de `ci.yml` ; aucune étape comparable à copier (seules les étapes `check-*` bash) |
| Gating par `scripts/.vibeflow-installed` côté mod TypeScript | utilitaire | lecture fichier | l'engine écrit le registre (bash), aucun lecteur TS existant ; le format `nom=version` vient de `mark_installed()` |
| Détection de l'ancien `~/.claude/mods/vf-signal` | utilitaire | lecture fichier | spécifique à la phase |

## Metadata

**Analog search scope:** `phase-69b/plugin/cockpit/scripts` (+ `tests/`), `phase-68/plugin/_internal`, `plugin/conductor/scripts/driver-lock.sh`, `.github/workflows/ci.yml`, `scripts/` (bump, check-version-sync, check-gate-touche, check-machine-paths, ci-shard-suites), `~/.claude/mods/vf-signal`, `origin/docs/design-md:DESIGN.md`.
**Files scanned:** ~45.
**Pattern extraction date:** 2026-11-03.
**Non fait, à prouver à l'exécution :** `claude plugin validate/test` sous Linux ; `cockpit/module.json` après le merge de la 69 ; sortie de `driver-lock.sh status` dans la version de `main` (verrou par phase).
