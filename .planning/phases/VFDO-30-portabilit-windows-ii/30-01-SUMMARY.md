---
phase: 30-portabilit-windows-ii
plan: 01
subsystem: install-engine
tags: [merge-hooks, forme-exec, port-02, port-04, adr-070, contrat-pr-29]
requires: []
provides:
  - "resolve_bash_abs() dans merge-hooks.sh (chemin absolu de bash résolu et vérifié à l'install)"
  - "merge-hooks.sh apprend la forme exec (substitution args, frag_basenames, references, dédup, remove)"
  - "software-architecture/hooks/hooks.json migré en forme exec, entrée classée bloquante"
  - "T8..T14 de test-merge-hooks.sh (substitution args, dédup cross-forme bidirectionnel, remove exec, idempotence, sonde de parc, frontière de mot)"
affects: [plans 30-04 à 30-08 (mêmes fichiers _internal, forme exec des 4 entrées restantes), gate de Willy (contrat PR #29 §5)]
tech-stack:
  added: []
  patterns:
    - "cascade de résolution autoritaire : une surcharge explicite (VF_BASH_BIN) qui échoue ne retombe jamais sur le candidat suivant — elle die() nommant le candidat rejeté"
    - "die() avant écriture : tout placeholder non substitué (accolade double résiduelle) bloque l'écriture du settings.json au lieu de l'écrire silencieusement mort"
    - "extension symétrique command+args : chaque fonction qui lisait command seul (frag_basenames, references, frag_names, own) lit désormais les deux, jamais l'un sans l'autre"
key-files:
  created: []
  modified:
    - plugin/_internal/merge-hooks.sh
    - plugin/software-architecture/hooks/hooks.json
    - plugin/_internal/tests/test-merge-hooks.sh

# Actuals (#2632) — chars/4 sur le diff réalisé des 3 fichiers modifiés (19931 chars).
actuals:
  tokens: 4983
  tasks: 2
  commits: 2

key-decisions:
  - "Checkpoint bloquant de la Tâche 1 (settings.json devient spécifique à la machine) déjà tranché par Samuel le 2026-08-15 avant ce mandat — D-01 de 30-CONTEXT.md, réponse « go ». Non rouvert, exécution directe des Tâches 2 et 3."
  - "resolve_bash_abs() : VF_BASH_BIN est une surcharge AUTORITAIRE — si posée et invalide (relative, absente, non exécutable), échec dur immédiat nommant le candidat, sans repli sur $BASH ni command -v bash. Le repli en cascade ne s'applique qu'en l'absence de surcharge explicite (ADR-070 : borner le vecteur qu'on couvre, jamais deviner une intention de repli sur une surcharge de test explicitement invalide)."
  - "Jeton {{VF_BASH}} choisi avec la même grammaire double-accolade que {{VF_SCRIPTS}} — substitué uniquement dans command (jamais dans args, où seul {{VF_SCRIPTS}} a un sens)."

requirements-completed: [PORT-02, PORT-04]

duration: "~55 min"
completed: "2026-08-15"
status: complete

coverage:
  - id: D1
    description: "merge-hooks.sh apprend la forme exec de bout en bout : substitution dans args, frag_basenames()/references() lisant command+args, dédup cross-forme bidirectionnelle, remove d'un fragment 100% exec, refus d'écrire un placeholder non substitué."
    requirement: PORT-02
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-merge-hooks.sh (T8, T9, T10, T11, T12, T14)"
        status: pass
    human_judgment: false
  - id: D2
    description: "resolve_bash_abs() : chemin absolu de bash résolu et vérifié à l'install (cascade VF_BASH_BIN → $BASH → command -v bash), candidat relatif rejeté sans repli déguisé, échec dur avant toute écriture."
    requirement: PORT-04
    verification:
      - kind: unit
        ref: "preuve manuelle bout-en-bout (mktemp) : VF_BASH_BIN=/bin/bash → command==/bin/bash ; VF_BASH_BIN=bash (relatif) → échec, rien écrit — voir §Preuve bout-en-bout ci-dessous"
        status: pass
    human_judgment: false
  - id: D3
    description: "plugin/software-architecture/hooks/hooks.json migré en forme exec (command={{VF_BASH}}, args=[script]), description mise à jour classant l'entrée bloquante."
    requirement: PORT-02
    verification:
      - kind: unit
        ref: "python3 -m json.tool plugin/software-architecture/hooks/hooks.json"
        status: pass
    human_judgment: false
  - id: D4
    description: "Sonde de parc (spec §4) : settings réaliste avec entrées VF shell + tierce + gsd-core-like, merge exec puis remove → zéro résidu VF, entrées tierce/gsd-core intactes par égalité structurelle."
    requirement: PORT-02
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-merge-hooks.sh#T13"
        status: pass
    human_judgment: false
  - id: D5
    description: "Discrimination par mutation des trois mécanismes livrés (m1 references(), m2 substitution args, m3 frag_basenames()) — trace du rouge consignée ci-dessous."
    verification:
      - kind: other
        ref: "mutations appliquées puis restaurées manuellement, diff post-restauration vérifié identique — voir §Preuve par mutation"
        status: pass
    human_judgment: false
---

# Phase 30 Plan 01: Tracer forme exec — merge-hooks.sh + software-architecture Summary

**`merge-hooks.sh` apprend la forme exec de bout en bout (substitution dans `args`, dédup
cross-forme bidirectionnelle, `remove` d'un fragment 100% exec, résolution vérifiée du chemin
absolu de `bash`) ; l'unique entrée `PreToolUse` de `software-architecture` migre en forme exec et
la suite de tests passe de 8 à 15 cas verts, avec trace de rouge sous 3 mutations.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-15T19:56:00Z (lecture des fichiers de contexte)
- **Completed:** 2026-08-15T20:52:06Z
- **Tasks:** 2 exécutées (Tâche 2 : tracer moteur+fragment ; Tâche 3 : suite de tests) — Tâche 1
  (checkpoint bloquant) déjà résolue en amont, voir ci-dessous
- **Files modified:** 3 (`plugin/_internal/merge-hooks.sh`,
  `plugin/software-architecture/hooks/hooks.json`, `plugin/_internal/tests/test-merge-hooks.sh`)

## Checkpoint Tâche 1 — déjà résolu en amont

Le plan porte une Tâche 1 `type="checkpoint:decision" gate="blocking"` (« le settings.json produit
devient spécifique à la machine — one-way »). Ce checkpoint **n'a pas été rouvert dans ce mandat** :
il a été tranché par Samuel le **2026-08-15**, avant l'exécution, réponse **`go`**. Trace :
`.planning/phases/VFDO-30-portabilit-windows-ii/30-CONTEXT.md` D-01 (« TRANCHÉ par Samuel le
2026-08-15, sans Willy ») et encart « ✅ TRANCHÉ le 2026-08-15 » au §3.2 de
`docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`. L'exécution est donc passée
directement aux Tâches 2 et 3.

## Accomplishments

- `resolve_bash_abs()` : chemin absolu de `bash` résolu et vérifié à l'install (cascade
  `VF_BASH_BIN` → `$BASH` → `command -v bash`), candidat relatif rejeté sans repli déguisé,
  export `BASH_ABS` vers le bloc Python.
- Substitution étendue : jeton `{{VF_SCRIPTS}}` remplacé dans `command` **et** chaque élément
  chaîne d'`args` ; jeton `{{VF_BASH}}` remplacé dans `command` seul ; refus d'écrire (`die()`) si
  une accolade double subsiste, ou si `{{VF_BASH}}` est présent sans bash résolu.
- `frag_basenames()`, `references()`, calcul de `frag_names` (réutilisation de groupe) et calcul
  d'`own` (dédup) : les quatre lisent désormais `command` **et** `args`, avec le même lookaround
  négatif appliqué chaîne par chaîne (jamais concaténé).
- `plugin/software-architecture/hooks/hooks.json` : unique entrée `PreToolUse`/`Edit|Write` migrée
  en forme exec (`command={{VF_BASH}}`, `args=["{{VF_SCRIPTS}}/guard-file-size.sh"]`), description
  mise à jour pour nommer l'entrée bloquante (`permissionDecision: deny`, pas son code de sortie).
- Suite de tests étendue de 8 à 15 cas (T8..T14), tous les cas historiques restant verts.

## Task Commits

Chaque tâche a été committée atomiquement, avec pathspec explicite (index git partagé avec
d'autres workers de la même phase) :

1. **Tâche 2 : tranche verticale — moteur apprend `args` + chemin absolu de bash, une entrée
   migre** - `b290aee` (feat)
2. **Tâche 3 : suite de tests apprend la forme exec** - `7c55632` (test)

Le SUMMARY est écrit puis committé séparément (voir en-tête d'exécution — STATE.md/ROADMAP.md
volontairement non touchés dans ce mandat, mise à jour réservée à l'orchestrateur amont).

## Files Created/Modified

- `plugin/_internal/merge-hooks.sh` — `resolve_bash_abs()`, substitution `command`+`args`,
  `frag_basenames()`/`references()`/`frag_names`/`own` étendus à `args`.
- `plugin/software-architecture/hooks/hooks.json` — entrée `PreToolUse` migrée en forme exec.
- `plugin/_internal/tests/test-merge-hooks.sh` — T8..T14 ajoutés, inventaire d'en-tête complété.

## Preuve bout-en-bout (Tâche 2, exécutée manuellement dans `mktemp -d`)

```
$ VF_BASH_BIN=/bin/bash bash merge-hooks.sh merge software-architecture/hooks/hooks.json \
    --settings settings.json --scripts-prefix '"$CLAUDE_PROJECT_DIR"/.claude/scripts'
[merge-hooks] merge OK → .../settings.json
```
Résultat vérifié par script Python : `command == "/bin/bash"`, `len(args) == 1`,
`"guard-file-size.sh"` et `"$CLAUDE_PROJECT_DIR"` présents dans `args[0]`, aucune accolade double
dans le fichier produit.

```
$ bash merge-hooks.sh remove software-architecture/hooks/hooks.json --settings settings.json
[merge-hooks] remove OK → .../settings.json
```
Résultat : `{}` — la clé `hooks` a intégralement disparu.

```
$ VF_BASH_BIN=bash bash merge-hooks.sh merge software-architecture/hooks/hooks.json \
    --settings settings.json --scripts-prefix '"$CLAUDE_PROJECT_DIR"/.claude/scripts'
[merge-hooks] ERROR: VF_BASH_BIN rejeté (chemin non absolu, inexistant, ou non exécutable) : bash
```
Exit ≠ 0, `settings.json` non créé (candidat relatif nommé, rejeté sans repli).

## Preuve par mutation (QUAL-01, Tâche 3)

Chaque mutation a été appliquée sur `merge-hooks.sh`, la suite complète rejouée, puis le fichier
restauré (diff post-restauration vérifié identique à l'état post-Tâche-2 avant chaque nouvelle
mutation).

**m1 — réintroduire la lecture de `command` seul dans `references()`** (retrait de la lecture
d'`args`) :

```
✗ T10 dédup cross-forme exec→shell (rollback de fragment)
✗ T11 remove d'un fragment 100% exec
✗ T12 idempotence 3 passes (forme exec)
✗ T13 sonde de parc
== Résultat : 11 OK · 4 KO ==
```
T9 (sens shell→exec) reste vert sous cette mutation : l'ancienne entrée qu'il purge est en forme
shell, donc son script est déjà visible dans `command` seul — la mutation n'affecte que le sens où
l'ancienne entrée est en forme exec (script dans `args`), c'est-à-dire T10, et collatéralement T11
(remove utilise aussi `references()`), T12 (dédup lors du 2e/3e merge) et T13 (remove final de la
sonde). Discrimination confirmée pour le mécanisme visé, avec explication du cas non affecté.

**m2 — retirer la substitution du jeton `{{VF_SCRIPTS}}` dans `args`** :

```
✗ T8 substitution dans args
== Résultat : 14 OK · 1 KO ==
```
Exactement le cas prévu par la spec, seul T8 rougit — `args[0]` reste littéralement
`"{{VF_SCRIPTS}}/exec-guard.sh"` au lieu du chemin résolu.

**m3 — retirer la lecture d'`args` dans `frag_basenames()`** :

```
✗ T11 remove d'un fragment 100% exec
✗ T13 sonde de parc
== Résultat : 13 OK · 2 KO ==
```
T11 rouge comme requis par la spec. T13 rouge en collatéral attendu : son étape finale appelle
aussi `remove` sur un fragment entièrement exec (même chemin `frag_basenames()` → `references()`
que T11).

## Decisions Made

- Checkpoint Tâche 1 non rouvert — déjà répondu `go` par Samuel le 2026-08-15 (D-01 de
  30-CONTEXT.md). Voir section dédiée ci-dessus.
- `VF_BASH_BIN` traité comme surcharge **autoritaire** : posée et invalide ⇒ échec dur nommant le
  candidat, jamais de repli silencieux vers `$BASH`/`command -v bash`. Cohérent avec la sémantique
  d'une surcharge de test explicite (si l'utilisateur force une valeur, une valeur invalide est un
  bug à signaler, pas un signal à ignorer).
- Jeton `{{VF_BASH}}` substitué uniquement dans `command`, jamais dans `args` — `{{VF_SCRIPTS}}`
  reste le seul jeton valide dans `args`, cohérent avec le contrat PR #29 §5 (le chemin de script
  vit dans `args`, le binaire dans `command`).

## Deviations from Plan

None — plan exécuté exactement comme écrit pour les Tâches 2 et 3. Le seul écart de périmètre par
rapport au texte du plan est intentionnel et documenté dans le mandat d'exécution : `.planning/ROADMAP.md`
(critère LOCK-02) n'a volontairement pas été touché ici — il appartient à un autre nœud du DAG de
la même phase.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None — les cinq mitigations du registre STRIDE de la Tâche 2 (T-30-01 à T-30-05) sont couvertes
par les cas de test livrés (T8/T14 pour la substitution/frontière, T9/T10/T11/T12/T13 pour la
dédup et le remove) ; aucune surface de sécurité nouvelle non anticipée par le `<threat_model>` du
plan n'a été introduite.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- Le moteur `merge-hooks.sh` est prêt pour les plans 30-04 à 30-08, qui migrent les 4 entrées de
  hook restantes (`dev-orchestrator` ×3, polarité gouvernance) : la lecture `command`+`args` est
  désormais symétrique partout où elle était lue.
- `resolve_bash_abs()` est réutilisable tel quel par tout futur consommateur de la forme exec dans
  ce dépôt.
- Aucun blocage identifié pour les plans suivants de la phase.

## Self-Check: PASSED

- FOUND: `plugin/_internal/merge-hooks.sh`
- FOUND: `plugin/software-architecture/hooks/hooks.json`
- FOUND: `plugin/_internal/tests/test-merge-hooks.sh`
- FOUND: commit `b290aee`
- FOUND: commit `7c55632`
- Suites rejouées à l'instant du self-check : `test-merge-hooks.sh` 15 OK · 0 KO,
  `test-windows-crlf.sh` 10 ok · 0 ko, `test-vibeflow-update.sh` 11 OK / 0 KO / 0 SKIP.

---

## Correction ciblée exec-30-01 (post-livraison, 2026-08-15)

Mandat de correction sur le nœud DAG `exec-30-01` : le travail « forme exec » ci-dessus
(commits `b290aee`, `7c55632`, `26b98c4`) n'a pas été remis en cause — deux manques précis,
vérifiés sur disque, ont été comblés en complément, sur la branche
`feat/phase-30-portabilite-windows-ii`, en exécution séquentielle sur l'arbre principal (pas de
worktree isolé, index git partagé avec d'autres workers de la phase).

### Manque 1 — routage borné `{{VF_BASH}}` vers une cible `--settings-local` optionnelle

**Problème :** `merge-hooks.sh` n'avait qu'une seule cible (`--settings`). Le jeton `{{VF_BASH}}`
introduit par le tracer 30-01 fait atterrir un chemin absolu machine-spécifique dans ce fichier
unique — potentiellement un `settings.json` de PROJET, committé et voyageant via git. C'est le
risque que la mitigation de Samuel devait fermer ; en l'état ça l'aggravait.

**Comblé :** `merge-hooks.sh` apprend une seconde cible optionnelle `--settings-local <path>`
(et `--settings-local=<path>`), pour `merge` et `remove`. Règle de répartition bornée : seule
une entrée dont le `command` BRUT porte `{{VF_BASH}}` est routée vers `--settings-local`, si
fournie — toute autre entrée (forme shell, ou forme exec sans `{{VF_BASH}}`) continue d'aller
dans `--settings` comme avant. Implémentation par scission du fragment en deux vues
(`project_view`/`local_view`) rejouant l'algorithme de merge/remove EXISTANT, séparément et sans
aucune autre bascule de comportement — aucun changement à `references()`, `frag_basenames()`,
`SCRIPT_RE`. `--settings-local` absent ⇒ comportement identique à avant, **prouvé** : les 15 cas
de test historiques (T1-T14) restent verts sans une seule ligne modifiée. `remove` balaie les
deux cibles quand `--settings-local` est fournie (sinon une désinstallation deviendrait
partielle et laisserait des hooks orphelins dans le settings local). Écriture atomique
indépendante par fichier (tempfile + `os.replace`, chacun son die() avant écriture).

`plugin/_internal/tests/test-merge-hooks.sh` étend la suite de 15 à 19 cas (T15-T18) :
- **T15** — entrée `{{VF_BASH}}` + `--settings-local` fournie ⇒ atterrit dans le fichier local,
  absente du fichier projet.
- **T16** — entrée sans `{{VF_BASH}}` (forme shell) + `--settings-local` fournie ⇒ reste dans le
  fichier projet, fichier local non affecté par cette entrée.
- **T17** — `--settings-local` absente ⇒ les deux entrées d'un fragment mixte atterrissent dans
  la cible `--settings` unique (compat descendante).
- **T18** — `remove` avec `--settings-local` fournie sur un merge antérieur mixte (une entrée
  locale + une entrée projet) ⇒ les deux disparaissent des deux fichiers respectivement, aucun
  résidu.

**Discrimination par mutation (QUAL-01), appliquée puis restaurée** (fichier revérifié identique
octet pour octet après chaque restauration, diff vide) :

**m1 — retirer la condition `{{VF_BASH}}` dans `is_local_entry()`** (route toute entrée vers
local dès que `--settings-local` est fournie, sans regarder son `command`) :
```
✗ T16 non-routage de l'entrée shell classique
== Résultat : 18 OK · 1 KO ==
```
T16 rougit exactement comme prévu : `shell-guard.sh` migre à tort vers le fichier local sous
cette mutation. T18 reste vert sous cette mutation — explication : la vérification de `remove`
est agnostique du fichier d'atterrissage (elle retire les basenames de partout, où qu'ils
soient, et vérifie juste l'absence de résidu global) ; ce n'est pas le mécanisme de routage que
T18 discrimine, mais le balayage des deux cibles au remove. T15 et T17 restent verts aussi (non
concernés par la présence/absence de la condition `{{VF_BASH}}` dans leurs propres scénarios).

**m2 — `is_local_entry()` retourne toujours `False`** (tout route vers `--settings` même quand
`--settings-local` est fournie) :
```
✗ T15 routage vers --settings-local
== Résultat : 18 OK · 1 KO ==
```
T15 rougit exactement comme prévu : `local-guard.sh` n'atterrit jamais dans le fichier local
(la lecture de `d['hooks']['PreToolUse']` échoue par `KeyError`, le fichier local ne contenant
que `{"hooks": {}}`). T16 reste vert (comportement correct par accident sous cette mutation, la
règle testée par T16 — « rester en projet » — reste vraie même quand TOUT reste en projet). T18
reste vert pour la même raison qu'en m1 (agnostique du fichier d'atterrissage).

Suite complète rejouée verte (19 OK · 0 KO) après restauration de chaque mutation.

### Manque 2 — LOCK-02 (`.planning/ROADMAP.md`, critère de succès n°2)

**Problème :** le critère de succès n°2 de LOCK-02 (lignes ~643-645) disait « jamais un settings
local ni un hook git non distribué » — formulation contredite littéralement par le routage du
Manque 1 : une commande locale existe désormais légitimement.

**Comblé :** reformulation du critère n°2 SEUL (aucune autre partie du ROADMAP touchée), avec la
trace datée de l'arbitrage de Samuel du 2026-08-15 : *« un chemin machine ne doit jamais
voyager ; les gardes restent distribuées (leur entrée naît toujours de `merge-hooks`), c'est
leur COMMANDE qui est locale »*. Le critère continue d'interdire un guard non distribué (entrée
posée à la main dans un settings, ou hook git hors du mécanisme distribué) sans plus interdire
une commande locale posée par `merge-hooks` lui-même dans une cible `--settings-local`.

### Task Commits (correction)

1. **Manque 1, code** — `ced85ee` (feat) : `merge-hooks.sh` apprend `--settings-local`.
2. **Manque 1, tests** — `dbe9fac` (test) : T15-T18 + trace de mutation dans ce SUMMARY.
3. **Manque 2** — `5c95cb0` (docs) : LOCK-02 critère n°2 reformulé, trace d'arbitrage.

### Périmètre respecté

Fichiers touchés, strictement les trois autorisés : `plugin/_internal/merge-hooks.sh`,
`plugin/_internal/tests/test-merge-hooks.sh`, `.planning/ROADMAP.md`. Aucun fichier interdit
(`vibeflow-update.sh`, `lib/`, `test-vibeflow-update.sh`, `dev-orchestrator/`, `conductor/`,
`scripts/`, `STATE.md`, `REQUIREMENTS.md`, `.github/`, `README.md`, `README.fr.md`) n'a été lu en
écriture. `git status --short` en fin de mandat ne montre que ces trois fichiers modifiés.

### Actuals de la correction (#2632, chars/4)

- **tokens (chars/4 sur le diff réalisé des 3 commits)** : 21387 chars / 4 ≈ **5347**
- **tasks** : 3 (manque 1 code, manque 1 tests, manque 2 ROADMAP)
- **commits** : 3

### Self-Check correction : PASSED

- FOUND: `plugin/_internal/merge-hooks.sh` (routage `--settings-local`)
- FOUND: `plugin/_internal/tests/test-merge-hooks.sh` (T15-T18)
- FOUND: commit `ced85ee`
- FOUND: commit `dbe9fac`
- FOUND: commit `5c95cb0`
- `bash plugin/_internal/tests/test-merge-hooks.sh` rejoué à l'instant du self-check : **19 OK ·
  0 KO**.
- `.planning/ROADMAP.md` : diff vérifié (`rtk proxy git diff`) ne touche QUE le critère de succès
  n°2 de LOCK-02 (lignes ~643-650).

---
*Phase: 30-portabilit-windows-ii*
*Completed: 2026-08-15*
