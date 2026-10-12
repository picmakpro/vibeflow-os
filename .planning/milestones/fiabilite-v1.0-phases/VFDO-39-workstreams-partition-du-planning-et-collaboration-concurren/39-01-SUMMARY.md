---
phase: VFDO-39-workstreams-partition-du-planning-et-collaboration-concurren
plan: 01
subsystem: filet-de-divergence
tags: [part-04, s2-s4-s5, post-merge, adr-059, d-11, d-12, d-13, c17, t-39-01]
requires: []
provides: [check-divergence-gate, post-merge-hook, test-check-divergence, ci-gate-divergence]
affects: [plugin/conductor/scripts/check-divergence.sh, plugin/conductor/scripts/tests/test-check-divergence.sh, scripts/hooks/post-merge, .github/workflows/ci.yml, .planning/codebase/CONCERNS.md]
tech-stack:
  added: []
  patterns: ["gate sourçant workstream-policy.sh au lieu de recopier vf_ws_* (leçon de la 4e copie, déjà payée par les trois gates existants)", "branchement EXPLICITE du hook sur le code de sortie du gate (jamais un `||` nu sur le code brut)", "normalisation numérique en base 10 explicite `$((10#$int))` des deux côtés de chaque comparaison", "preuve par mutation à deux étages : mutation de FIXTURE (MUT-1) et mutation du SCRIPT (MUT-2), un mutant non opposable faisant échouer la suite", "résolution de l'exécutable d'un hook ancrée sur le dépôt principal (`git rev-parse --git-common-dir`), jamais sur le worktree courant"]
key-files:
  created:
    - plugin/conductor/scripts/check-divergence.sh
    - plugin/conductor/scripts/tests/test-check-divergence.sh
    - scripts/hooks/post-merge
  modified:
    - .github/workflows/ci.yml
    - .planning/codebase/CONCERNS.md
    - .planning/phases/VFDO-39-workstreams-partition-du-planning-et-collaboration-concurren/39-01-PLAN.md
key-decisions:
  - "Signature S2 + S4(a) + S4(b) + S5 implémentée telle que mesurée (research §8-9), S1/S3 jamais réintroduits. Cinq codes de sortie tous énumérés dans l'en-tête, aucun implicite : 0 conforme · 1 divergence · 2 non vérifiable · 3 SILENCE (dépôt non partitionné, l'état nominal de ce dépôt aujourd'hui) · 64 usage. La cardinalité BRUTE dossiers↔en-têtes a été REJETÉE, pas ajustée : mesurée faux-positive en permanence sur les propres nombres de ce dépôt — S4(a) fonctionne par appartenance ensembliste dans UNE direction seulement (un dossier sans en-tête = orphelin ; un en-tête sans dossier = normal, phase archivée ou pas encore démarrée)."
  - "Le hook `post-merge` est opt-in strict (`git config core.hooksPath scripts/hooks`, jamais armé par défaut — précédent #38) et branche EXPLICITEMENT sur le code de sortie : seul 1 crie la divergence, 0 et 3 sortent en silence, 2 et 64 impriment un advisory distinct qui ne bloque pas. Le `||` nu du squelette de 39-PATTERNS.md aurait crié « divergence » sur CHAQUE fusion ordinaire de ce dépôt (aujourd'hui exit 3) dès l'armement. Le hook ne peut de toute façon pas annuler la fusion — git ignore son code de sortie pour cela, à la différence de `pre-push` : son rôle est d'être bruyant, pas de bloquer."
  - "Câblage CI (arbitrage Samuel 2026-09-10, C17 revisité) : le hook local seul est MUET PAR CONSTRUCTION sur une PR fusionnée côté GitHub — la voie de fusion dominante de ce dépôt. Un gate correct qui ne se déclenche jamais sur le cas qui compte est exactement le mode d'échec « sûr mais inerte » d'ADR-059, déjà payé une fois avec `isolation: worktree` resté désarmé après la Phase 35 ; ce dépôt ne paie pas deux fois. L'étape CI ne se contente pas de constater la présence du gate : elle construit une fixture partitionnée SAINE (exit 0), la MUTE EN PLACE (second dossier partageant le préfixe `05`) et exige le flip 0 → 1 sur le MÊME arbre, puis vérifie la non-régression racine (exit 3). `check-divergence.sh` lui-même est inchangé par cette tâche — seule son exposition est neuve."
  - "T-39-01 (RCE par `git worktree` hostile) mitigé sur `post-merge` seul, mitigation NEUVE et non héritée : `check-divergence.sh` est résolu via `git rev-parse --git-common-dir` (ancré sur le dépôt principal) au lieu de `--show-toplevel`, qui suit le worktree que l'attaquant contrôle. `dirname \"$0\"` n'aurait rien réglé : sous `core.hooksPath` RELATIF, git résout le hook LUI-MÊME depuis le worktree courant. Le répertoire INSPECTÉ (`--path`) reste `--show-toplevel` — c'est bien lui qu'on veut auditer. `scripts/hooks/pre-push` porte le MÊME défaut, explicitement hors périmètre : dette ouverte assumée, consignée au registre."
requirements-completed: [PART-04]
duration: "non tracé"
completed: "2026-09-10"
coverage:
  - deliverable: "check-divergence.sh — gate S2/S4(a)/S4(b)/S5, 5 codes de sortie, sourçant workstream-policy.sh"
    verification:
      - kind: "command"
        ref: "bash plugin/conductor/scripts/check-divergence.sh --path . → exit 3 (racine non partitionnée, sortie silencieuse) ; fixture orphan → exit 1 avec « S2 : … numéro de phase 5 dupliqué entre : VFDO-05-x, VFDO-05-y »"
        status: pass
    human_judgment: false
  - deliverable: "scripts/hooks/post-merge — opt-in, branchement explicite sur le code de sortie, exécutable ancré sur le dépôt principal"
    verification:
      - kind: "command"
        ref: "<verify> Tâche 1 rejouée : dépôt jetable, hook armé, `git merge --no-ff` réel qui atterrit VFDO-05-x-registered/VFDO-05-y-orphan → GATE_FIRED"
        status: pass
    human_judgment: false
  - deliverable: "test-check-divergence.sh — 8 cas fonctionnels + MUT-1 (fixture) + MUT-2 (script)"
    verification:
      - kind: "command"
        ref: "bash plugin/conductor/scripts/tests/test-check-divergence.sh → « 10 ok, 0 ko (10 cas) », RC=0, aucune ligne ✗"
        status: pass
    human_judgment: false
  - deliverable: ".github/workflows/ci.yml — étape check-divergence.sh dans le job `gates`, preuve par mutation"
    verification:
      - kind: "command"
        ref: "<verify> Tâche 3 rejouée : clean_rc=0 mutant_rc=1 → CI_MUTATION_PROOF_OK ; étape insérée lignes 622-683, entre le step « Gates workstream-aware… » et « check-release-tag » (l. 684), jamais fusionnée dans l'un ou l'autre"
        status: pass
    human_judgment: false
  - deliverable: "Aucune fuite de `.planning/workstreams/` dans l'arbre de travail réel (règle paradoxe de la Phase 39)"
    verification:
      - kind: "command"
        ref: "os.path.isdir('.planning/workstreams') → CLEAN (recoupé en Python, pas en `ls`)"
        status: pass
    human_judgment: false
notes: >
  Réserve explicite sur la moitié « en CI » de PART-04 : l'étape existe, elle est insérée au bon
  endroit et sa discriminance a été prouvée LOCALEMENT (étape extraite verbatim du YAML : verte sur
  le script réel, rouge — exit 1, deux écarts notés — rejouée contre un `check-divergence.sh` mutant
  qui retourne toujours 0). Aucun run GitHub Actions réel n'a été observé : rien n'a été poussé
  depuis ce lot. Le vert distant reste à constater au moment de la PR, et cette ligne existe pour
  qu'il ne soit pas supposé. Aucune commande `gsd-tools state.*` invoquée, aucun `gsd-execute-phase`,
  aucun push. `.planning/REQUIREMENTS.md`, `.planning/STATE.md` et `.planning/ROADMAP.md` ne sont
  pas touchés par ce SUMMARY (un second worker travaillait en parallèle sur STATE/ROADMAP). Toutes
  les mesures citées ici ont été re-jouées le 2026-09-10 avant rédaction, `rtk proxy` en préfixe et
  recoupement Python sur les lectures dont dépend une affirmation.
---

# 39-01 — Filet de détection de divergence de workstream : gate S2/S4/S5, hook post-merge, suite de mutation, câblage CI

Trois tâches exécutées **inline** (pas de `gsd-execute-phase` : un autre worker travaillait en
parallèle sur 39-02/39-03), puis rattrapées par une passe de correction sur findings de juges.
Ce SUMMARY est produit **a posteriori** — l'exécution inline n'a pas fait tourner la machinerie
qui le génère.

- `a61378e` — Tâche 1 : `check-divergence.sh` (318 l. à la création, 334 aujourd'hui) + `scripts/hooks/post-merge`
- `4b37e45` — Tâche 2 : `test-check-divergence.sh` (199 l. à la création, 203 aujourd'hui) + correctif d'un bug réel de `local`
- `ce348e3` — Tâche 3 : étape CI dans le job `gates` (62 lignes, `.github/workflows/ci.yml:622-683`)
- `c96ad98` — passe de correction post-revue (G1-G7 + H1-H3), à cheval sur 39-01 et 39-02 ; pour ce
  lot : G2 (mutation MUT-2 rendue réellement atteignante), G3 (échec de `mktemp -d` gardé), G6
  (commentaire du script remis d'aplomb sur ce qu'il garantit vraiment), H1-H3 (mitigation RCE du
  hook + registre `CONCERNS.md` + modèle de menace T-39-01 du plan mis à jour)

## Déviation assumée — le critère d'acceptation « la sortie ne contient pas le mot *divergence* » est insatisfaisable

Le plan exigeait, sur le chemin conforme, que « la sortie ne contienne pas le mot *divergence* ».
C'est **impossible par construction** : le préfixe de log est `[check-divergence]`, il contient ce
mot sur **chaque** ligne, conforme comprise. Mesuré le 2026-09-10 sur les deux chemins :

- conforme (exit 0) → `[check-divergence] conforme — compartiment(s) inspecté(s), aucun signal S2/S4/S5` — le mot `divergence` y apparaît **1 fois**
- signalé (exit 1) → `[check-divergence] S2 : compartiment « alpha » — numéro de phase 5 dupliqué entre : VFDO-05-x, VFDO-05-y` — le mot `divergence` y apparaît **1 fois** aussi

Le critère ne discrimine donc **rien**. Ce qui distingue réellement conforme de signalé, ce sont le
**code de sortie** (0 vs 1) et les **étiquettes de signaux employées AFFIRMATIVEMENT** en tête de
message : `S2 : `, `S4(a) : `, `S4(b) : `, `S5 : `. Nuance mesurée qui va plus loin que le
commentaire gravé dans le script (`check-divergence.sh:323-329`, lequel parle d'« absence des
étiquettes ») : la ligne conforme **nomme** bien `S2/S4/S5`, mais dans une **négation** (« aucun
signal S2/S4/S5 »). Une assertion de test ne doit donc pas chercher la sous-chaîne `S2` nue, mais
sa forme affirmative en tête de message — c'est ce que fait la suite.

Déviation **assumée**, pas contournée : le critère d'origine n'a pas été satisfait, il a été jugé
faux et remplacé par un critère qui discrimine. Elle est consignée dans le script **et** ici.

## Ce que le lot a trouvé en chemin

Ces quatre trouvailles sont la valeur réelle du lot — aucune n'était prévue au plan.

**1. Un bug réel de `local`, découvert en écrivant le PREMIER test.** `check-divergence.sh` (commit
`a61378e`) écrivait `local raw="$1" int="$raw" ...` : bash **étend tous les mots avant** d'exécuter
`local`, donc `$raw` référait la variable de la portée englobante — non liée — et non la valeur
qu'on croyait fixer sur la même ligne. Résultat sous `set -u` : `raw: unbound variable` sur
**chaque** appel de `normalize_num`, cassant la normalisation partout et faisant basculer plusieurs
cas en faux positif S2. Trouvé par le cas 1 (nominal, dossiers paddés vs en-têtes non paddés) qui
aurait dû rester vert. Corrigé en `4b37e45` : `int` affecté en instruction séparée, avec le
raisonnement gravé en commentaire (`check-divergence.sh:135-147`).

**2. Une preuve de mutation d'abord VIDE.** MUT-2 mutait le script mais ne prouvait rien, sur trois
couches à la fois : (a) le mutant tournait **isolé**, sans sa dépendance sœur
`workstream-policy.sh` — `check-divergence.sh` la résout relativement à `$(dirname "$0")` et sort
en **2** (non vérifiable) sans elle : le mutant échouait pour la **mauvaise raison** et n'atteignait
jamais le signal qu'il prétendait neutraliser ; (b) la mutation visait la **valeur de retour** de
`check_s2`, que l'appelant jette via `|| true` — muter cela ne mute rien d'observable ; (c)
l'assertion était trop permissive (« le code a changé »), au lieu d'exiger le vert à tort. Corrigé
en `c96ad98` (G2) : dépendance copiée à côté du mutant, mutation ciblant l'**awk de comptage de
doublons**, assertion resserrée sur `rc_mut -eq 0` **et** `rc_orig -eq 1`. Un mutant non opposable
fait désormais **échouer la suite** — jamais « mutant satisfait ».

**3. Un gate qui pouvait rendre « conforme » à tort sur un dépôt réellement divergé.** Si
`mktemp -d` échouait, le script poursuivait et pouvait sortir **0** — le pire des verdicts : un vert
de complaisance sur un arbre en split-brain. Corrigé en `c96ad98` (G3) : échec de `mktemp -d`, ou
dossier introuvable après coup, → **exit 2** (non vérifiable). Même posture que partout ailleurs
dans ce gate : jamais un 0 par défaut d'information.

**4. Une RCE démontrée sur le hook.** Un `git worktree add` sur une branche hostile fait pointer
`git rev-parse --show-toplevel` sur un arbre entièrement contrôlé par l'attaquant : une copie
malveillante de `check-divergence.sh` posée là **s'exécutait au premier merge** (mesuré par
exécution réelle, pas déduit). `dirname "$0"` n'aurait pas suffi — sous `core.hooksPath` **relatif**,
git résout aussi le **hook lui-même** depuis le worktree courant (également vérifié par exécution).
Mitigé en `c96ad98` (H1-H3) en ancrant la résolution de l'exécutable sur le **dépôt principal**
(`git rev-parse --git-common-dir`), stable à travers `git worktree add` ; le répertoire **inspecté**
reste le worktree courant, c'est bien lui qu'on veut auditer. Arbitrage Samuel (AskUserQuestion,
session principale, 2026-09-10) : mitiger le hook **neuf** plutôt que déclarer une dette héritée —
le vecteur est connu au moment où la ligne est écrite, rien ne force du code neuf à le reproduire.
`scripts/hooks/pre-push` porte le même défaut et reste **explicitement hors périmètre** : les deux
occurrences sont consignées dans `.planning/codebase/CONCERNS.md` (ouvert sur `pre-push`, mitigé
sur `post-merge`), et le modèle de menace T-39-01 de `39-01-PLAN.md` a été mis à jour en
conséquence. Effet net : la surface d'attaque ne **croît pas** avec cette phase, au lieu de doubler.

## État vérifié à la fin

Toutes ces mesures ont été rejouées le 2026-09-10 au moment de rédiger ce SUMMARY, pas recopiées
des messages de commit :

- **Suite 10/10, mutants compris** : `bash plugin/conductor/scripts/tests/test-check-divergence.sh`
  → `== résultat : 10 ok, 0 ko (10 cas) ==`, `RC=0`, aucune ligne `✗`. Les 8 cas fonctionnels
  couvrent nominal (garde de régression sur le décalage de padding), non partitionné, orphan nue,
  orphan `VFDO-NN-slug`, rootonly, S4(a), S4(b) greater-than et S4(b) less-than ; MUT-1 prouve le
  flip 1 → 0 par empreinte **de contenu** (`cksum` par fichier — une liste de chemins ne bougerait
  pas pour l'édition d'un fichier existant), MUT-2 prouve la discriminance du script.
- **Non-régression sur le dépôt réel non partitionné** :
  `bash plugin/conductor/scripts/check-divergence.sh --path .` → **exit 3**, silence. Et
  `.planning/workstreams/` n'existe **pas** dans l'arbre de travail (recoupé en Python) — la règle
  paradoxe de la Phase 39 tient.
- **Étape CI prouvée par bascule de mutation** : fixture saine → **exit 0**, même arbre muté en
  place → **exit 1** ; `CI_MUTATION_PROOF_OK`. L'étape occupe `.github/workflows/ci.yml:622-683`,
  entre le step « Gates workstream-aware… » et `check-release-tag` (l. 684), sans `|| true` sur
  aucune des trois invocations.
- **Bout-en-bout réel** : dans un dépôt jetable, hook armé par `core.hooksPath`, un vrai
  `git merge --no-ff` qui atterrit une duplication de numéro de phase → `GATE_FIRED`.

## Exigences — ce qui est déclaré, et ce qui ne l'est pas

**Accomplie par ce plan : `PART-04` seule.** Chacun de ses termes a un acte correspondant ici : le
filet existe (`check-divergence.sh`), il porte la signature **S2 + S4 + S5**, il est branché
**post-merge** (jamais `SessionStart`, D-12), **opt-in** (`core.hooksPath`, jamais armé par défaut),
**et câblé sur le job CI `gates`** (C17) ; la **mutation rouge** (D-13) est prouvée sur les trois
variantes de la recherche §8 et sur le script lui-même, localement — avec la réserve du frontmatter
sur le run GitHub Actions non encore observé.

**Volontairement exclues**, bien que ce lot les frôle :

- `PART-03` — exige que les gates (dont `check-divergence.sh`) soient verts **dans le clone
  partitionné** et que tous les agents `vf-*` passent `--ws` dans un run de preuve : preuve **par
  exécution** due au plan `39-03`, jamais faite ici. La non-régression racine mesurée ci-dessus
  n'est que **la moitié** de la clause, et une moitié ne clôt pas une exigence.
- `PART-07` — clone jetable hors de l'arbre, détruit en fin de mission, nuance « preuve de
  mécanisme » : appartient au run de preuve du `39-03`.
- `PART-09` — `--ws` explicite **observé par exécution** avec deux workers concurrents : plan
  `39-03`. C'est exactement l'exigence sur-déclarée par le SUMMARY voisin puis retirée par `c96ad98`
  (G1) ; elle n'est pas réintroduite ici par une autre porte.
- `PART-01`, `PART-02`, `PART-05`, `PART-06` — portées et livrées par le plan `39-02` (marquées
  `Planned — plan 39-02` au ledger), sans rapport avec ce lot.
- `PART-08` — geste séparé, gaté humain, postérieur à la clôture de la phase.

Aucune de ces exigences n'a été cochée dans `.planning/REQUIREMENTS.md` par ce SUMMARY : ce fichier
n'a pas été touché.
