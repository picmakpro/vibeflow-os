# Mission — Phase 31 (manifeste d'install + dry-run, issue #20)

**Date** : 2026-08-16 · **Manager** : `vf-dev-manager` (locks `mission-31-reprise`, `-2`, `-3`)
**Branche** : `feat/phase-31-manifeste-dry-run` · **Base** : `2a2f0ef` (main)
**Statut de sortie** : **pause propre sur état vert** — vagues 1 et 2 livrées, revues, corrigées et
vérifiées. Reste `exec-04` → `exec-08`, puis `issue20-draft` et `docs`.

---

## 1. État des nœuds

| Nœud | État |
|---|---|
| `rech-moteur`, `discuss`, `plan`, `plancheck` | **done** |
| `exec-01` socle manifeste + suite + compteurs README | **done**, revu, corrigé, re-vérifié |
| `exec-02` mode `plan` de `merge-hooks.sh` | **done**, revu, corrigé, re-vérifié |
| `exec-03` migration des ~35 sites | **done**, revu, vérifié, corrigé, re-vérifié |
| `exec-04` (`--dry-run`) → `exec-08`, `issue20-draft`, `docs` | non démarrés |

**Mesuré par le manager sur l'arbre commité** (`git archive HEAD`, `/bin/bash` 3.2) :
`test-manifest.sh` **24/24** · `test-merge-hooks.sh` **32/32** · `test-vibeflow-update.sh` **19/19** ·
`check-machine-paths.sh` **0** · `check-version-sync.sh` **0** · **62 suites** · arbre propre.
**Injection de panne rejouée par le manager** : `install` avec un `rules/*.md` illisible → **rc=0**
(avant correctif : rc=1, install avortée).

## 2. Le fil rouge : aucun vert auto-déclaré n'a tenu, aucune preuve unique n'a suffi

| Étage | Auto-déclaré | Trouvé par un tiers |
|---|---|---|
| Plans (checker **interne** du pipeline) | `PASSED, 0 blocker` | **11 bloquants** (2 relectures externes) |
| 1re passe de correction | 11 corrigés | 9 fermés, **2 créés** |
| 2e passe | 2 fermés | **1 laissé** (mutant mort) |
| Vague 1 (2 workers) | 5/5 et 32/32 verts | **2 bloquants + 1 majeur** |
| Migration `31-03` | 15/15, 19/19, 32/32 verts | **4 bloquants + 4 majeurs** |

**Le fait le plus instructif de la mission** : sur `31-03`, la vérification a **prouvé** l'absence de
changement de comportement (égalité **md5 fichier à fichier**, 262 fichiers, 6 modules) pendant que
la revue **prouvait** une régression massive — dans le même lot. Les deux avaient raison : la preuve
md5 portait sur le **chemin nominal**, la régression vivait sur le **chemin dégradé**. *Deux preuves
solides du chemin heureux ne disent rien du chemin d'échec.*

## 3. Ce que les juges ont attrapé, et que rien d'autre n'aurait vu

- **`install --all` cassé en cascade** — quatre sites migrés avaient perdu leur tolérance sous
  `set -e` : dans `a && b && c`, seule la **dernière** commande déclenche `errexit`, et la migration
  a promu chaque helper en dernière position. Un fichier illisible dans **un** module faisait avorter
  l'install, et **tous les modules suivants de la boucle n'étaient jamais installés**. Les trois
  suites restaient vertes : elles ne testaient que « glob non satisfait », **jamais un échec réel**.
- **Crash macOS-only** — `parts=($path)` sur chaîne vide laisse `parts` **unbound** en bash 3.2.
  **CI Linux (bash ≥5) serait restée verte.**
- **Manifeste menteur relu pour supprimer** — consignation depuis la source alors que la copie est un
  glob suffixé `|| true`.
- **Quatre assertions incapables de rougir**, prouvées par mutation, dont une suite déclarée 5/5.
  `grep -qF` est un test de **sous-chaîne** : le chemin fautif **contient** le correct.
- **Trois critères de plan verts à vide** — ils scannaient des fonctions **pas encore écrites**.
- **Un second point de définition** de la liste close (via un filtre privé de test) : la maladie que
  la phase soigne — des énumérations parallèles à tenir à la main — **repoussait dans son remède**.

## 4. Prémisses fausses corrigées (dont trois à moi)

1. **Le compteur de suites EST gaté** (`check-version-sync.sh` §9) — la recherche avait énuméré les
   contrôles 1 à 8 et manqué le 9e. D-31-08 survit, son motif s'inverse, contrainte d'atomicité en plus.
2. **Mon premier commit a rendu `check-machine-paths.sh` ROUGE** — gate servant de critère
   d'acceptation à 8 tâches.
3. **Mon durcissement de `vf_record`** (`ERROR + return 1` hors cycle) aurait **avorté `update` et
   `uninstall` en production** une fois la migration faite. Rattrapé par le worker.
4. Trois valeurs de mes mandats étaient fausses (`split_fragment_hooks` 405→**404**, `show_status`
   902-920→**902-918**, un littéral `31-08` inexistant) : **les workers les ont corrigées parce que
   je leur demande de me corriger plutôt que de m'obéir. Garder cette formule.**

## 5. Arbitrages ajoutés en mission (D-31-11 → D-31-14)

- **D-31-11** — ferme la couture `vf_place_tree` après **cinq** défauts d'affilée : plan **prédit
  depuis la source** (sémantique du glob), manifeste **consigné depuis la destination**, divergence
  journalisée sans faire échouer la pose. Quatre point-fixes n'avaient pas fermé la classe : c'était
  une **ambiguïté du cadrage**.
- **D-31-11.4** (tranché par Samuel, option A) — **un seul émetteur, au grain fichier**. Puis le
  **trou de silence** que l'option A avait ouvert (source illisible ⇒ zéro paire ⇒ rien n'est dit),
  comblé par capture de rc.
- **D-31-12** — **une garde s'arme au grain unité** dès que le bout-en-bout ne l'exerce pas. Corollaire :
  tout critère scannant une fonction absente porte une **garde d'existence**, jamais un vert par défaut.
- **D-31-13** — **déplacer un appel change sa sémantique d'échec** ; la tolérance se restaure
  **explicitement** et se prouve par **injection de panne**. Une suite qui n'exerce que le chemin
  heureux ne peut pas voir une régression de tolérance.
- **D-31-14** — le no-op hors cycle de `sync_module_governance` est **sûr** (`flush` **écrase** au lieu
  de fusionner et `sync` n'ouvre jamais de cycle ⇒ le fichier dérivé est absent des **deux** côtés du
  diff, jamais candidat à suppression ; ouvrir un cycle **tronquerait** le manifeste). **Une ligne de
  compte rendu par module**, jamais par chemin.

## 6. À porter en entrée de `31-05` — important

Le manifeste **n'est pas garanti à jour** après un `update` à version **inchangée** : un fichier gagné
sans bump est posé et jamais consigné. La fenêtre est **bornée et auto-cicatrisante** (le prochain vrai
bump le recapture), mais `31-05` ne doit **pas** supposer le manifeste exhaustif au sortir d'un `update`.

## 7. Remontées non bloquantes

1. `--dry-run` sur `uninstall` — le verbe le plus dangereux est celui où une prévisualisation vaudrait
   le plus. Hors périmètre v1.
2. `docs/<module>/` écrit relativement au **cwd**, pas au scope : en scope user, la doc atterrit où
   l'utilisateur se trouvait.
3. **Dotfiles d'un sous-dossier de module jamais copiés** — **gelé par test**, pas corrigé.
4. **Manifeste non gitignoré en scope local** — même famille que `.vibeflow-installed`, préexistant.
5. **Symlink vers un répertoire** : `cp -r` déréférence sur BSD/macOS, `find -type f` ne descend pas —
   divergence manifeste/disque **silencieuse**. Risque **latent** (aucune fixture n'en contient).
6. `logs/archive.log` créé à l'install via `ensure-design-deps.sh` → CLI `claude` → hook SessionStart
   de `consolidator`. Visible seulement sur `--all`.

## 8. Pièges d'outillage mesurés

- **`grep` proxifié tronque silencieusement** (31 lignes sur 102).
- **`wc` piped a rendu `0`** sur un fichier de 38 octets (`od -c` et `stat -f %z` concordants).
- **Mode d'échec commun** : une commande de comptage cassée rend `0`, **indiscernable de « la
  propriété est vraie »**. Un critère de comptage doit prouver qu'il **peut rougir** avant de certifier.
- **`gsd-execute-phase` filtre par vague, jamais par plan** : deux workers sur une même vague n'ont
  aucun support natif. Exécution **inline** via `execute-plan.md`, au prix des `SUMMARY`/`verdicts`.

## 9. Next step

`exec-04` (`--dry-run`, dépend de `exec-02` + `exec-03`), puis `exec-05` (convergence MANI-03), puis
la vague 5 (`exec-06` skills + `exec-07` uninstall, **fichiers disjoints, parallélisables**), enfin
`exec-08`. **`exec-08` doit dépendre de TOUS les autres nœuds d'exécution** — ses must-haves exigent
la suite verte sur l'arbre commité et des compteurs README alignés sur la mesure **finale**.
Chaque lot : `vf-reviewer` EN DIRECT + `gsd-verifier`, **en parallèle**, findings **fusionnés en un
seul reopen**. Sur ce moteur, aucun lot n'est passé sans findings.

## 10. Gates humains — aucun consommé

PR, merge, release racine : **non touchés**. Réponse et close de l'issue #20 : **draft disque
uniquement**, jamais posté. Branche de phase créée avant le premier commit. Untracked étrangers
(`.gsd/`, `MISSION-30.dag.json`, `VFDO-36…`, `DRIVER.lock*`) jamais commités.
**Un seul geste humain consommé** : l'arbitrage D-31-11.4 (option A) et la ratification du checkpoint
bloquant de `31-03`, tous deux demandés et obtenus explicitement.

## 11. Calibration

`estimate` par plan (verbatim) : 31-01 55000/3→2 · 31-02 40000/2 · 31-03 70000/3 · 31-04 75000/3 ·
31-05 70000/3 · 31-06 35000/2 · 31-07 45000/2 · 31-08 35000/2 — tous `confidence: low`.
**Aucun `actuals`, aucun `verdicts`** : l'exécution inline (§8) court-circuite `state.record-metric`
et les hooks `execute:post`. Rien de fabriqué pour combler.
