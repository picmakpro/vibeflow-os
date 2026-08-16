# Mission — Phase 31 (manifeste d'install + dry-run, issue #20)

**Date** : 2026-08-16 · **Manager** : `vf-dev-manager` (locks `mission-31-reprise` → `-4`)
**Branche** : `feat/phase-31-manifeste-dry-run` · **Base** : `2a2f0ef` (main)
**Statut de sortie** : **phase livrée** — 8 plans exécutés, revus, vérifiés, corrigés. Aucun gate
humain consommé hors les trois arbitrages explicitement demandés à Samuel.

---

## 1. État final

| Nœud | État |
|---|---|
| `rech-moteur`, `discuss`, `plan`, `plancheck` | done |
| `exec-01` … `exec-08` | **done**, chacun revu **et** vérifié, corrigé, re-mesuré |
| `issue20-draft` | **done** — `31-ISSUE-20-REPLY.md`, 146 lignes, **DRAFT sur disque, jamais posté** |
| `docs` | done — STATE/ROADMAP/REQUIREMENTS réalignés, compteurs README constatés justes |

**Découverte COMPLÈTE des suites** (pattern CI) : **62 suites, 0 échec**.
`test-manifest.sh` **62 assertions** (créée par cette phase, 5 → 62) · `test-merge-hooks.sh` 34 ·
`test-vibeflow-update.sh` 19 · `test-design-orchestrator.sh` 24. Gates lancés **nus** : 0 / 0.

## 2. Ce que la phase livre

- **Manifeste par module** — `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`, LF, trié `LC_ALL=C`,
  relatif à TARGET_ROOT, **grain fichier**, écrit à chaque pose. Exhaustivité vérifiée sur **6
  profils de modules × 3 scopes** : **0 mensonge** (rien de manifesté qui ne soit sur disque).
- **`--dry-run`** sur `install`/`update`, **refus explicite `rc=1`** sur `uninstall`/`rollback`/
  `status`/`sync`. Prouvé n'écrire **rien** au grain **contenu** (shasum de 3849 fichiers identique)
  et n'appeler **aucun** des sous-processus écrivains (contrôle positif à 26 invocations en réel).
- **Mode `plan`** de `merge-hooks.sh`, relayé tel quel par le moteur (jamais réimplémenté).
- **Convergence à l'update** — sauvegarde **puis** suppression, liste rendue, **résolution physique**
  du chemin interdisant toute suppression hors racine résolue.
- **`uninstall` lit le manifeste**, avec repli cache, et **ne désenregistre jamais ce qu'il n'a pas
  su retirer**.
- **Skills consommateurs** câblés en **11 lignes** au total, sans nouveau point de décision.

## 3. Le fil rouge : aucun vert auto-déclaré n'a tenu

| Étage | Auto-déclaré | Trouvé par un tiers |
|---|---|---|
| Plans (checker **interne** du pipeline) | `PASSED, 0 blocker` | **11 bloquants** |
| 1re passe de correction | 11 corrigés | 9 fermés, **2 créés** |
| Vague 1 (2 workers) | suites vertes | **2 bloquants + 1 majeur** |
| Migration `31-03` | 15/15, 19/19, 32/32 | **4 bloquants + 4 majeurs** |
| `--dry-run` `31-04` | suites vertes | **1 bloquant + 2 majeurs** |
| Convergence `31-05` | 46/46 | **suppression HORS racine reproduite** |

**Le fait le plus instructif** : sur `31-03`, la vérification a **prouvé** l'absence de changement de
comportement (égalité **md5 fichier à fichier**, 262 fichiers) pendant que la revue **prouvait** une
régression massive — dans le même lot. Les deux avaient raison : la preuve md5 portait sur le
**chemin nominal**, la régression vivait sur le **chemin d'échec**. *Le désaccord des juges portait
plus d'information que leurs verdicts.*

## 4. Les défauts qui auraient coûté le plus cher

- **Suppression hors `TARGET_ROOT`** — un répertoire **ancêtre** symlinké contournait les deux gardes,
  qui normalisaient **textuellement** sans jamais toucher le disque. **Reproduit**, puis fermé par
  D-31-15 (résolution physique par builtins POSIX).
- **`install --all` cassé en cascade** — quatre sites avaient perdu leur tolérance sous `set -e` : un
  fichier illisible dans **un** module et **tous les suivants** n'étaient jamais installés.
- **Manifeste illisible traité comme vide** — un `cat` dont l'échec était **avalé** rendait tout le
  module supprimable : **12 chemins retirés** mesurés sans le correctif.
- **Désinstallation irrécupérable** — fichiers laissés sur disque **et** module désenregistré :
  l'utilisateur ne pouvait plus rien retirer. Fermé par D-31-16.
- **Octet NUL dans le manifeste** — validé comme conforme, et **supprimait le mauvais fichier**.
- **Crash macOS-only** (`parts=($path)` sur chaîne vide, bash 3.2) : **CI Linux serait restée verte**.

## 5. Six arbitrages ajoutés en mission

- **D-31-11** — ferme la couture `vf_place_tree` après **cinq** défauts d'affilée : c'était une
  **ambiguïté du cadrage**, pas une maladresse des plans.
- **D-31-11.4** *(Samuel)* — un seul émetteur, grain fichier ; puis le **trou de silence** que
  l'option A avait ouvert, comblé.
- **D-31-12** — **une garde s'arme au grain unité** dès que le bout-en-bout ne l'exerce pas.
- **D-31-13** — **déplacer un appel change sa sémantique d'échec** ; la tolérance se restaure
  explicitement et se prouve par **injection de panne**.
- **D-31-14** — le no-op hors cycle est **sûr** (démontré), et se dit **par module**, jamais par chemin.
- **D-31-15** *(Samuel)* — le chemin de suppression **résout physiquement**. ADR-054 interdit le
  **binaire** `realpath`, pas la résolution physique : `cd -P`/`pwd -P` sont des builtins POSIX.
- **D-31-16** — **ne jamais désenregistrer ce qu'on n'a pas su retirer** ; l'abstention doit rester
  **réversible**, sinon elle est une autre forme de dommage.

## 6. Mes propres erreurs, consignées

1. **Filet de non-régression trop étroit** — j'ai fait vérifier **3 suites** sur **62** pendant toute
   la mission. Une régression dans `plugin/design-orchestrator/` (une suite qui **sonde le texte
   source** de l'engine via `grep -A8`) a traversé **six revues et quatre vérifications**. Trouvée
   parce qu'un worker a élargi la découverte **de sa propre initiative**. Corrigée, et la sonde
   rendue **structurelle** (extraction du bloc `if…fi`), avec preuve de survie à une insertion.
2. **Gate lu à travers un pipe** — `bash gate.sh | awk …` puis `$?` rend le code d'`awk`. J'ai
   conclu « vert » sur un `check-machine-paths` **rouge**, en cherchant précisément cette classe de
   défaut.
3. **Prémisse fausse propagée** — j'ai repris le raisonnement « conditions (e)/(f) structurellement
   inatteignables » de la revue ; la vérification a **mesuré** (f) tuable. *Une mesure prime un
   raisonnement.*
4. **Durcissement dangereux** — mon `ERROR + return 1` hors cycle aurait **avorté `update` et
   `uninstall` en production** une fois la migration faite. Rattrapé par un worker.
5. **Trois valeurs de mandat fausses** (`split_fragment_hooks` 405→404, `show_status` 902-920→902-918,
   un littéral `31-08` inexistant), plus un finding **mal qualifié** (« abort » au lieu d'« échec
   avalé », plus grave). **Toutes corrigées par les workers, parce que je leur demande de me
   corriger plutôt que de m'obéir. Garder cette formule.**

## 7. Remontées ouvertes (§7 du cadrage)

1. `--dry-run` sur `uninstall` — le verbe le plus dangereux est celui où une prévisualisation
   vaudrait le plus. Hors périmètre v1.
2. `docs/<module>/` écrit relativement au **cwd**, pas au scope.
3. **Dotfiles** d'un sous-dossier de module jamais copiés — **gelé par test**, pas corrigé.
4. **Manifeste non gitignoré** en scope local (pré-existant).
5. **Le `cp -r` de la POSE suit encore les symlinks** — D-31-15 ne protège que le chemin destructif.
6. **Symlink dans un arbre `vf_place_tree`** : `cp -r` déréférence, `find -type f` non — divergence
   silencieuse. Risque **latent**, aucune fixture n'en contient.

## 8. Outillage — pièges mesurés

- **`grep` proxifié tronque** (31 lignes sur 102) · **`wc` piped a rendu `0`** sur 38 octets ·
  **`$?` après un pipe** rend le code du dernier maillon. *Une commande de contrôle cassée rend `0`,
  indiscernable de « la propriété est vraie ».*
- **`git archive` rend l'ARBRE commité, pas le DÉPÔT** : une suite qui interroge git y échoue à tort
  (constaté sur `test-check-machine-paths.sh`, **19/19 dans le vrai dépôt**). Trois cas à distinguer,
  jamais deux : régression / pré-existant / **artefact de mesure**.
- **Découverte de suites** : le pattern CI rend **62** ; un `find` plus large rend **124** en
  ramassant `.claude/worktrees/` (**second checkout du même dépôt**) et `.planning/milestones/`.
- **`gsd-execute-phase` filtre par vague, jamais par plan** — deux workers sur une même vague n'ont
  aucun support natif ; exécution **inline** via `execute-plan.md`, au prix des `SUMMARY`/`verdicts`.
- **Le heartbeat de lock est fragile** : le processus d'arrière-plan a été tué **4 fois**. Ce qui a
  tenu, c'est le `driver-lock.sh status` à chaque notification. *Matière pour LOCK-01 (Phase 32).*

## 9. Gates humains

**Aucun consommé** : pas de PR, pas de merge, pas de release, **rien de posté sur l'issue #20** —
zéro mot-clé de fermeture GitHub dans les ~55 commits de la phase (vérifié). Branche de phase créée
avant le premier commit. Untracked étrangers jamais commités.
**Trois arbitrages demandés et obtenus** : D-31-11.4 (option A), la ratification du checkpoint
bloquant de `31-03`, et D-31-15 (résolution physique).

## 10. Next step

**Décision de Samuel attendue** : publier ou non la réponse à l'issue #20 (`31-ISSUE-20-REPLY.md`),
puis PR / merge / release — tous gatés.
Le **push de la branche pour preuve CI est autorisé** et non fait à ce stade : c'est le geste
suivant le plus utile, la CI Linux étant le seul environnement où certains défauts de portabilité se
révèlent (et où d'autres, macOS-only, resteraient invisibles).

## 11. Calibration

`estimate` par plan (verbatim) : 31-01 55000/3→2 · 31-02 40000/2 · 31-03 70000/3 · 31-04 75000/3 ·
31-05 70000/3 · 31-06 35000/2 · 31-07 45000/2 · 31-08 35000/2 — tous `confidence: low`.
**Aucun `actuals`, aucun `verdicts`** : l'exécution inline court-circuite `state.record-metric` et
les hooks `execute:post`. Rien fabriqué pour combler.
