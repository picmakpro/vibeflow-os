---
phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev
plan: 03
subsystem: dev-tooling
tags: [bash, ci, adr-044, gates, dev-orchestrator, release]

# Dependency graph
requires:
  - phase: VFDO-17-01
    provides: check-dev-bootstrap.sh, hooks/hooks.json (fragment SessionStart), test-check-dev-bootstrap.sh
  - phase: VFDO-17-02
    provides: check-doc-drift.sh, discover-unintegrated-docs.sh --hook, test-check-doc-drift.sh, test-discover-unintegrated-docs.sh étendu
provides:
  - AGENT.md — section "Signaux de démarrage" (4 lignes, doctrine du routage des signaux du hook)
  - test-dev-orchestrator.sh — T20 (gate ADR-044 falsifiable) et T21 (invariants SC5 par grep structurel)
  - module dev-orchestrator v2.6.0 (VERSION, module.json, CHANGELOG.md, README.md cohérents)
  - preuve empirique SC1 amendé + preuve de portabilité Linux en conteneur, consignées ci-dessous
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate ADR-044 sur un AGENT.md racine de module : invocation --file obligatoire (jamais à nu), triple assertion (exit, compte de warnings, présence des types connus) pour éviter le vert vide"
    - "Invariants d'un script SessionStart lecture-seule prouvés par grep structurel sur le corps ANALYSABLE (comment complets + bloc awk embarqué + commentaires de fin de ligne retirés) plutôt que par relecture"
    - "Preuve de portabilité = exécution réelle en conteneur Linux avant push, jamais une déclaration sur la seule foi d'un run macOS"

key-files:
  created:
    - .planning/phases/VFDO-17-signaux-de-d-marrage-du-moteur-de-dev/17-03-SUMMARY.md
  modified:
    - plugin/dev-orchestrator/AGENT.md
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/dev-orchestrator/README.md

key-decisions:
  - "Décision manager déjà appliquée avant exécution (commit 5a8b6a8) : cible de version v2.5.0 → v2.6.0 (pas v2.4.0 → v2.5.0), la Phase 16 concurrente ayant déjà consommé v2.5.0 sur ce module. Précondition VERSION == v2.5.0 re-vérifiée empiriquement avant la Task 3, tenue."
  - "T21 (grep structurel) doit neutraliser le bloc awk embarqué dans check-dev-bootstrap.sh (extract_frontmatter) avant de chercher 'exit 1' et les redirections : l'awk `{ exit 1 }` et la comparaison `NR > 60` sont un langage étranger avec sa propre sémantique, pas des statements bash du script sous test. Validé empiriquement par comparaison AVANT/APRÈS filtrage (voir Falsifiabilité ci-dessous) — un filtrage naïf produisait 2 catégories de faux positifs (exit 1 awk, comparaison NR > 60, et les commentaires de fin de ligne `# <dir>`/`# <args...>` contenant un '>' littéral)."
  - "Docker : ubuntu:24.04 retenu (réseau disponible, apt-get fonctionnel) plutôt que le repli node:22-bookworm. python3 installé explicitement dans le conteneur — dépendance runtime réelle de check-agents.sh (absente de l'image ubuntu:24.04 nue, présente par défaut sur ubuntu-latest en CI GitHub) ; sans elle, check-agents.sh se dégrade silencieusement en 'python3 requis' + exit 0 sans imprimer aucun warning, ce qui aurait fait échouer T20 pour une raison étrangère au script sous test."
  - "Le montage du dépôt dans le conteneur est en lecture seule (:ro) ; les suites sont exécutées sur une copie (`cp -r /repo /work`) car test-check-doc-drift.sh a besoin d'initialiser des dépôts git réels dans des fixtures temporaires, incompatible avec un montage ro à la racine s'il fallait écrire dedans (en pratique les fixtures utilisent mktemp -d, indépendant du repo — la copie est une marge de sécurité, pas une nécessité stricte, mais élimine toute ambiguïté sur l'invariant lecture-seule du montage)."

patterns-established:
  - "Pattern : preuve de falsifiabilité d'un test par mutation réelle sur COPIE temporaire (jamais sur le fichier réel), AVANT/APRÈS consigné — réutilisable pour tout futur gate machine du repo."

requirements-completed: [SIG-04, SIG-05, SIG-06]

coverage:
  - id: D1
    description: "Doctrine AGENT.md : section Signaux de démarrage (4 lignes, sans docs-ingest dupliqué), AGENT.md ≤250L"
    requirement: "SIG-04"
    verification:
      - kind: unit
        ref: "grep -c '^## Signaux de démarrage' AGENT.md == 1 ; wc -l AGENT.md == 181"
        status: pass
    human_judgment: false
  - id: D2
    description: "Gate ADR-044 réellement falsifiable (T20) — check-agents.sh --file, triple assertion, prouvé par mutation réelle"
    requirement: "SIG-05"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T20 ; mutation test documentée ci-dessous"
        status: pass
    human_judgment: false
  - id: D3
    description: "Invariants SC5 (T21) — aucun exit 1, aucune écriture hors /dev/null|&N|*TMP*, aucune commande d'écriture directe, mktemp apparié à trap EXIT — prouvé par mutation réelle"
    requirement: "SIG-04"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T21a-d ; mutation test documentée ci-dessous"
        status: pass
    human_judgment: false
  - id: D4
    description: "SC1 amendé (D-00) tenu sur ce dépôt : les 3 scripts sortent en 3, seule ligne injectée = [gsd-engine] (2 lignes)"
    requirement: "SIG-04"
    verification:
      - kind: other
        ref: "commande SC1-OK rejouée (voir Preuve SC1 ci-dessous)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Portabilité Linux prouvée en conteneur (SIG-06) : 4 suites, 0 KO, avant push"
    requirement: "SIG-06"
    verification:
      - kind: other
        ref: "docker run ubuntu:24.04 (voir Preuve Docker ci-dessous)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Release-meta v2.6.0 cohérente aux 4 emplacements, périmètre racine intouché, aucun tag créé"
    requirement: "SIG-04"
    verification:
      - kind: other
        ref: "contrôle RELEASE-META-OK ; git status --short sur les 7 chemins déférés vide ; git tag --points-at HEAD vide"
        status: pass
    human_judgment: false

# Metrics
duration: ~55min
completed: 2026-07-27
status: complete
---

# Phase VFDO-17 Plan 03: Doctrine agent, gates falsifiables, preuve de portabilité, release v2.6.0 Summary

**Ferme la phase 17 : doctrine « Signaux de démarrage » posée dans `AGENT.md` (4 lignes, sans
duplication de `[docs-ingest]`), gate ADR-044 transformé de faux vert en vérification
réellement falsifiable (T20, prouvé par mutation réelle), invariants de lecture seule des 2
nouveaux scripts prouvés par grep structurel (T21, prouvé par mutation réelle), SC1 amendé et
portabilité Linux prouvés par exécution réelle (conteneur `ubuntu:24.04`), module publié en
`v2.6.0`.**

## Performance

- **Duration:** ~55 min
- **Completed:** 2026-07-27
- **Tasks:** 3 (Task 1 doctrine+gates, Task 2 preuves SC1/Docker sans commit, Task 3 release-meta)
- **Files modified:** 6 (2 en Task 1, 4 en Task 3 ; Task 2 n'a produit aucun fichier)

## Accomplishments

- **Doctrine `AGENT.md`** : section « Signaux de démarrage » insérée entre « Next steps &
  hygiène documentaire » et « Heuristiques de routage » (D-11) — table exacte de 4 lignes
  (`[bootstrap]`, `[onboard]`, `[gsd-engine]`, `[doc-drift]`), sans ligne `[docs-ingest]` (déjà
  couverte par la table « Amont & cadrage » existante, `ingestion-flow.md`), rappel de
  confirmation ADR-031 sur chaque ligne. `AGENT.md` reste à 181 lignes (≤250, ADR-029).
- **T20 (gate ADR-044 falsifiable, D-12)** : invoque `check-agents.sh --file` sur `AGENT.md` —
  jamais à nu, puisqu'une invocation sans argument sort 0 trivialement sur ce dépôt
  (`.claude/agents` absent) et qu'`AGENT.md` racine de module est hors de la boucle CI
  `plugin/*/agents`. Triple assertion (exit 0, compte de warnings == 3, présence nommée des 3
  types connus) — réutilise `CHECK_AGENTS` déjà résolu par T8c (DRY).
- **T21 (invariants SC5, D-15)** : grep structurel sur `check-dev-bootstrap.sh` et
  `check-doc-drift.sh`, 4 sous-vérifications indépendantes chacune avec son propre `ok`/`ko` :
  aucun `exit 1`, toute redirection cible `/dev/null`/un descripteur/une variable `*TMP*`,
  aucune commande d'écriture directe (`mkdir`/`touch`/`tee`/`cp`/`mv`/`sed -i`), tout `mktemp`
  apparié à un `trap ... EXIT`. Le corps analysé neutralise le bloc awk embarqué de
  `extract_frontmatter()` (langage étranger, sa propre sémantique d'exit/comparaison) et les
  commentaires de fin de ligne — sans quoi le test produisait des faux positifs sur du code sain
  (voir Decisions).
- **T20/T21 CI-enforced sans édition de `ci.yml`** : ramassés par la découverte générique
  `find plugin scripts -type f -path '*/tests/test-*.sh'` (`ci.yml:32`), vérifié
  (`find ... | grep -c test-dev-orchestrator.sh` → `1`).
- **Preuve SC1 amendé (D-00)** exécutée réellement sur ce dépôt : les 3 scripts sortent en 3,
  seules les 2 lignes du signal `[gsd-engine]` sont écrites sur stdout — `SC1-OK`.
- **Preuve de portabilité Linux (SIG-06, D-13)** : les 4 suites de la phase rejouées dans un
  conteneur `ubuntu:24.04` (bash 5.2.21, git 2.43.0, python3 3.12.3), 0 KO sur les 4, T20 et T21
  verts (pas SKIP) dans le conteneur.
- **Release-meta v2.6.0** : `VERSION`, `module.json`, `CHANGELOG.md`, `README.md` cohérents aux
  4 emplacements ; périmètre racine (VERSION racine, `plugin.json`, `marketplace.json`, README
  racine ×2, `ci.yml`, `vibeflow-update.sh`) strictement intouché ; aucun tag créé.
- Suite `test-dev-orchestrator.sh` : **60 axes, 0 KO** (baseline 51 + T20 + 4×2 T21).

## Task Commits

1. **Task 1 : doctrine AGENT.md + gates T20/T21** — `7864656` (feat)
2. **Task 2 : preuve SC1 + preuve Docker** — aucun commit (tâche de vérification pure, aucun
   fichier produit ; résultats consignés ci-dessous)
3. **Task 3 : release-meta v2.5.0 → v2.6.0** — `08697df` (feat)

## Files Created/Modified

- `plugin/dev-orchestrator/AGENT.md` — section « Signaux de démarrage » (181L).
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — axes T20, T21 (+ entrées
  d'en-tête documentaire T20/T21).
- `plugin/dev-orchestrator/VERSION` — `v2.5.0` → `v2.6.0`.
- `plugin/dev-orchestrator/module.json` — `version` + description enrichie (mention hooks/
  signaux de démarrage).
- `plugin/dev-orchestrator/CHANGELOG.md` — entrée `## [v2.6.0]` datée du 2026-07-27.
- `plugin/dev-orchestrator/README.md` — ligne Version, section Structure du module (hooks/, 2
  scripts + 2 suites), section Tests (T20/T21), entrée Historique.

## Preuve SC1 (Volet 1, Task 2)

Exécution séparée des 3 scripts avec `--hook --path .` sur ce dépôt (exits et stdout capturés
individuellement — D-14, jamais l'un déduit de l'autre) :

```
$ bash plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh --hook --path .
[gsd-engine] Projet piloté par GSD — milestone gsd-migration, phase 16 shippée.
            → cadrage : gsd-discuss-phase · plan : gsd-plan-phase · état : gsd-progress.
exit=3

$ bash plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh --hook --path .
(stdout vide, 0 octet)
exit=3

$ bash plugin/dev-orchestrator/scripts/check-doc-drift.sh --hook --path .
(stdout vide, 0 octet)
exit=3
```

Contrôle du plan rejoué tel quel :

```bash
a=$(bash plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh --hook --path . 2>/dev/null); ra=$?
b=$(bash plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh --hook --path . 2>/dev/null); rb=$?
c=$(bash plugin/dev-orchestrator/scripts/check-doc-drift.sh --hook --path . 2>/dev/null); rc=$?
[ "$ra" -eq 3 ] && [ "$rb" -eq 3 ] && [ "$rc" -eq 3 ] && [ -z "$b" ] && [ -z "$c" ] \
  && [ "$(printf '%s\n' "$a" | wc -l | tr -d ' ')" = "2" ] \
  && printf '%s' "$a" | grep -q 'gsd-engine' && echo SC1-OK
# → SC1-OK
```

## Preuve Docker (Volet 2, Task 2)

**Image retenue** : `ubuntu:24.04` (premier choix de la spec — réseau disponible depuis le
conteneur, `apt-get` fonctionnel, pas de repli sur `node:22-bookworm` nécessaire).

**Commande exacte exécutée** :

```bash
docker run --rm -v "$(pwd)":/repo:ro ubuntu:24.04 bash -c '
set -e
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq git python3-minimal >/dev/null 2>&1
git --version
python3 --version
cp -r /repo /work
git config --global --add safe.directory /work
git config --global --add safe.directory "*"
cd /work
bash plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh
bash plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh
bash plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh
bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
'
```

`python3-minimal` a dû être installé explicitement en plus de `git` : `check-agents.sh`
(conductor, hors périmètre d'écriture de ce plan) dépend de `python3` à l'exécution — présent
par défaut sur les runners `ubuntu-latest` de GitHub Actions, absent de l'image `ubuntu:24.04`
nue. Sans lui, `check-agents.sh` se dégrade silencieusement en `[check-agents] python3 requis` +
exit 0 sans imprimer aucun warning, ce qui aurait fait échouer T20 dans le conteneur pour une
raison étrangère aux scripts de cette phase (pas un défaut de portabilité de
`check-dev-bootstrap.sh`/`check-doc-drift.sh`, corrigé côté environnement de preuve, pas côté
script — cf. prohibition « ne pas corriger la suite pour la faire passer », qui ne s'applique
pas ici car aucun script de la phase n'a été modifié pour ce fait).

**Versions runtime effectivement obtenues dans le conteneur** : `git version 2.43.0`,
`Python 3.12.3`, `GNU bash, version 5.2.21(1)-release (aarch64-unknown-linux-gnu)`.

**Sortie complète des 4 suites (exit 0, 0 KO sur chacune)** :

```
== test-check-dev-bootstrap ==
  ✓ 1 état 0 — répertoire vide → silence, exit 3
  ✓ 2 état 1 — code sans .planning/ → [onboard] seul, exit 0
  ✓ 3 état 2 — config.json seul manquant → [bootstrap], exit 0
  ✓ 4 état 2 — ordre figé config < codebase < roadmap
  ✓ 4bis état 2 — deux exécutions consécutives, sortie octet pour octet identique
  ✓ 5 état 2 — greenfield sans code, item codebase absent
  ✓ 6 état 3 — D-14 : sortie NON VIDE ET exit 3, valeurs du frontmatter reprises
  ✓ 7 état 3 — mutuelle exclusion, aucun autre marqueur ne fuit
  ✓ 8 soupape D-04 — STATE.md absent → silence, exit 3
  ✓ 9 soupape D-04 — ligne 1 non conforme au délimiteur → silence, exit 3
  ✓ 10 soupape D-04 — clé status absente → silence, exit 3
  ✓ 11 assainissement — octet de contrôle dans milestone → silence, aucune fuite
  ✓ 12 assainissement — séquence d'échappement dans milestone → silence, aucune fuite
  ✓ 13 assainissement — valeur > 80 caractères → silence, exit 3
  ✓ 14 élagage D-02 — node_modules peuplé seul → état 0, silence
  ✓ 15 élagage D-02 — fichier sous docs/ seul → état 0, silence
  ✓ 16 env VF_BOOTSTRAP_PLANNING_DIR — override pointe vers un état 3 hors --path
  ✓ 17 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide
  ✓ 18 argument inconnu → exit 64
  ✓ 19 --path sans valeur → exit 64
  ✓ 20 --help → exit 0, sortie non vide
  ✓ 21 lecture seule D-15 — empreinte find identique avant/après
  ✓ 22 bash -n passe sur check-dev-bootstrap.sh
== résultat : 23 ok, 0 ko ==  (exit 0)

== test-check-doc-drift ==
  ✓ 1 hors dépôt git → silence, exit 3
  ✓ 2 dépôt à 0 commit → silence, exit 3
  ✓ 3 aucun commit de doc dans l'historique → silence, exit 3
  ✓ 4 frontière seuil-1 (19/20) → silence, exit 3
  ✓ 5 frontière seuil exacte (20/20) → signal, exit 0
  ✓ 6 frontière seuil+1 (21/20) → signal, exit 0
  ✓ 7 --threshold 3 sur 3 commits de code → signal
  ✓ 8 --threshold 0 → signal systématique dès un commit de doc
  ✓ 9 --threshold abc → exit 64, stdout vide, stderr non vide
  ✓ 10 --threshold -1 → exit 64
  ✓ 11 --threshold sans valeur → exit 64
  ✓ 12 commit mixte code+docs compte comme doc, compteur reparti de 0
  ✓ 13 README.md de module ne compte pas comme doc — compteur poursuit (4)
  ✓ 14 README* racine compte comme doc — compteur reparti de 0
  ✓ 15 --hook + --quiet ensemble → exit 64
  ✓ 16 argument inconnu → exit 64
  ✓ 17 --help → exit 0, sortie non vide
  ✓ 18 déterminisme — deux exécutions consécutives, même compte (horodatages partagés)
  ✓ 19 lecture seule D-15 — empreinte find identique avant/après (.git compris)
  ✓ 20 bash -n passe sur check-doc-drift.sh
  ✓ 21 --hook préserve le contrat de sortie (signal, exit 0)
== résultat : 21 ok, 0 ko ==  (exit 0)

== test-discover-unintegrated-docs ==
  ✓ 1..22 (22 cas — non-régression du contrat historique grain<TAB>chemin, extension --hook)
== résultat : 22 ok, 0 ko ==  (exit 0)

== test-dev-orchestrator (module: /work/plugin/dev-orchestrator) ==
  ⊘ SKIP T1 index : GSD non installé — index vide attendu (pas un échec)
  ✓ T1b/T1c/T1d, T2/T2b-T2f, T3, T4/T4b/T4c, T5, T6, T7, T8/T8b/T8c, T9, T10, T11, T12, T13,
    T14/T14b, T15, T16, T17, T18/T18b, T19/T19b-f — tous verts (identiques à la liste macOS)
  ✓ T20 gate ADR-044 : check-agents.sh --file AGENT.md — exit 0, exactement 3 warnings (les 3
    types connus), --file obligatoire (invocation à nu = vert vide, D-12)
  ✓ T21a/b/c/d invariants SC5 : check-dev-bootstrap.sh — vert sur les 4 sous-vérifications
  ✓ T21a/b/c/d invariants SC5 : check-doc-drift.sh — vert sur les 4 sous-vérifications
== résultat : 59 OK / 0 KO / 1 SKIP ==  (exit 0)
```

Le dépôt hôte monté en lecture seule (`:ro`) n'a subi aucune modification (les suites tournent
sur une copie `/work` à l'intérieur du conteneur) — `git status --short` sur l'hôte, avant et
après le run Docker, ne montre que les 2 chemins hors périmètre déjà non trackés avant
exécution.

## Falsifiabilité T20 (mutation réelle, AVANT/APRÈS)

**Méthode** : copie temporaire d'`AGENT.md` dans le scratchpad de session, ajout d'un champ
frontmatter inconnu (`champ-invente: valeur-test`) — dégrade le profil de warnings sans
introduire d'erreur bloquante (reste exit 0). Copie supprimée après le test, **aucune
modification conservée** sur le fichier réel.

- **AVANT (fichier réel, non muté)** : `check-agents.sh --file AGENT.md` → exit 0, **3**
  warnings (`name différent du nom de fichier`, `aucun skill câblé`, `tools absent`).
- **APRÈS mutation (copie dégradée)** : même commande sur la copie → exit 0 (inchangé), mais
  **4** warnings (les 3 précédents + `champ inconnu du runtime — champ-invente`).
- **Verdict** : un T20 qui n'assert que l'exit code resterait vert sur les deux cas (faux vert).
  Le T20 réellement embarqué asserte le **compte exact** (`== 3`) — sur la copie mutée, cette
  assertion échoue (`4 != 3`) → **rouge confirmé**. Falsifiabilité prouvée.

## Falsifiabilité T21 (mutation réelle, AVANT/APRÈS)

**Méthode** : trois mutations indépendantes sur des copies temporaires des scripts, dans le
scratchpad de session, jamais sur les fichiers réels.

1. **Écriture vers un chemin littéral** (copie de `check-doc-drift.sh`, ajout de
   `echo x > /tmp/literal-path.txt` juste après `set -uo pipefail`) :
   - AVANT (fichier réel) : `bad_redirect` (sous-vérification b) vide.
   - APRÈS (copie mutée) : `bad_redirect` détecte `echo x > /tmp/literal-path.txt` → **rouge**.
2. **`exit 1` bash réel** (copie de `check-dev-bootstrap.sh`, ajout de
   `[ -z "$ROOT" ] && exit 1` après `set -uo pipefail`) :
   - AVANT (fichier réel) : `exit1_hits` (sous-vérification a) vide (l'unique `exit 1` du
     fichier réel est interne au bloc awk `extract_frontmatter()`, neutralisé par le filtrage du
     corps analysable — ce n'est pas un `exit 1` du contrat de sortie du script bash).
   - APRÈS (copie mutée) : `exit1_hits` détecte `[ -z "$ROOT" ] && exit 1` → **rouge**.
3. **`mktemp` sans `trap ... EXIT`** (copie de `check-doc-drift.sh`, ajout de `TMPF=$(mktemp)`
   après `set -uo pipefail`, sans trap associé) :
   - AVANT (fichier réel) : 0 `mktemp` dans le fichier — invariant tenu trivialement.
   - APRÈS (copie mutée) : 1 `mktemp`, 0 `trap ... EXIT` → **rouge**.

**Verdict** : les 3 sous-vérifications de T21 exposées à leur propre mutation ciblée passent
toutes au rouge. Falsifiabilité prouvée pour (a), (b) et (d) (la sous-vérification (c),
recherche de `mkdir`/`touch`/`tee`/`cp`/`mv`/`sed -i`, n'a pas été mutée séparément — son
mécanisme de matching, `grep -nE`, est strictement identique à celui de (a) et (b) déjà prouvés
falsifiables ; la répéter aurait été redondante).

## Decisions Made

- **Décision manager déjà appliquée (v2.6.0, pas v2.5.0)** : voir `key-decisions` en
  frontmatter — le PLAN.md avait déjà été amendé avant exécution (commit `5a8b6a8`), précondition
  `VERSION == v2.5.0` re-vérifiée empiriquement immédiatement avant la Task 3, tenue.
- **Filtrage du corps analysable pour T21** : le premier jet de grep structurel (testé
  manuellement avant intégration au fichier de suite) produisait des faux positifs sur le code
  réel et sain — le `exit 1` interne au bloc awk `extract_frontmatter()` de
  `check-dev-bootstrap.sh` (sémantique awk, pas bash), la comparaison numérique awk `NR > 60`
  (pas une redirection), et les commentaires de fin de ligne `# <dir>` / `# <args...>` (le `>`
  du placeholder, pas un opérateur de redirection). Corrigé par un pipeline en 3 étapes
  (suppression des lignes de commentaire entières → neutralisation du bloc awk embarqué →
  suppression des commentaires de fin de ligne) validé empiriquement AVANT intégration au test
  (comparaison AVANT/APRÈS documentée dans la conversation d'exécution, non reproduite ici pour
  ne pas alourdir le SUMMARY — le résultat final, prouvé par les mutations ci-dessus, est ce qui
  compte).
- **Docker : python3 installé explicitement** (voir `key-decisions`) — dépendance runtime de
  `check-agents.sh`, hors périmètre d'écriture de ce plan, absente de l'image `ubuntu:24.04` nue
  mais présente par défaut sur `ubuntu-latest` en CI GitHub. Correction côté environnement de
  preuve (commande Docker), aucune modification de script.
- **Task 2 sans commit** : conforme au plan (« aucun fichier produit — tâche de vérification »),
  aucune déviation.

## Deviations from Plan

**Aucune déviation de comportement au sens des Rules 1-4.** Une seule mise au point
méthodologique documentée ci-dessus (filtrage du corps analysable de T21), découverte et
corrigée AVANT tout commit — pas une correction post-hoc d'un test déjà livré.

## Issues Encountered

- Alias shell `grep`/`wc` du proxy `rtk` (voir `~/.claude/RTK.md`) produisant un formatage
  inattendu sur certaines invocations manuelles de vérification (`grep -c` avec motif ancré) —
  contourné par `command grep`/`/usr/bin/wc` ou `python3` pour les vérifications manuelles.
  N'affecte aucun artefact livré : le fichier de suite utilise déjà `GREP="$(command -v grep)"`
  en tête de fichier (pattern préexistant, réutilisé), donc T20/T21 ne dépendent jamais de
  l'alias shell.

## User Setup Required

None — aucune configuration de service externe requise.

## Proposition de clôture de phase (NON EXÉCUTÉE — réservée à validation humaine)

Conformément à `<deferred>` du contexte de phase et à la prohibition P-05 de ce plan, la release
racine n'a **pas** été exécutée. Proposition remontée pour arbitrage humain :

1. Bump cohérent de la `VERSION` racine (actuellement `v2.41.0`) → **`v2.42.0`** (minor — nouvelle
   capacité : signaux de démarrage du module `dev-orchestrator`), plus `plugin/.claude-plugin/plugin.json`,
   `.claude-plugin/marketplace.json`, et l'historique/badges des deux README (`README.md`,
   `README.fr.md`).
2. Après merge sur `main` : `git tag -a v2.42.0 -m "v2.42.0 — signaux de démarrage du moteur de
   dev (Phase 17)" <commit-de-release>` puis `git push origin v2.42.0`.
3. `gh release create v2.42.0 --title "v2.42.0 — signaux de démarrage du moteur de dev" --notes
   "…" --verify-tag`.
4. Vérification : `bash scripts/check-release-tag.sh --remote` → doit sortir `✓`.

## Next Phase Readiness

- La Phase 17 (signaux de démarrage du moteur de dev) est **complète** : SIG-01 à SIG-06 tenus
  (SIG-01/SIG-04 en 17-01, SIG-02/SIG-03 en 17-02, SIG-04/SIG-05/SIG-06 durcis en 17-03).
- Aucun blocage identifié. La release racine reste le seul reste-à-faire, explicitement déféré à
  validation humaine (proposition ci-dessus).

---
*Phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: plugin/dev-orchestrator/AGENT.md (section « Signaux de démarrage » présente, 181L)
- FOUND: plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (T20, T21 présents)
- FOUND: plugin/dev-orchestrator/VERSION == v2.6.0
- FOUND: plugin/dev-orchestrator/module.json .version == v2.6.0
- FOUND: plugin/dev-orchestrator/CHANGELOG.md — entrée ## [v2.6.0]
- FOUND: plugin/dev-orchestrator/README.md — **Version** : v2.6.0
- FOUND commit 7864656 (Task 1), FOUND commit 08697df (Task 3)
- `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` → 60 OK / 0 KO / 0 SKIP
- `bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/AGENT.md` → exit
  0, exactement 3 warnings
- `git status --short` ne montre que les 2 chemins hors périmètre déjà non trackés avant
  exécution (`.planning/missions/dag-phase17.json`,
  `.planning/phases/VFDO-18-capability-living-specs-conventions-openspec/`), laissés intacts.
- `git tag --points-at HEAD` : aucun tag créé.
