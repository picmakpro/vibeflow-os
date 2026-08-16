# Mission — Phase 31 (manifeste d'install + dry-run, issue #20)

**Date** : 2026-08-16 · **Manager** : `vf-dev-manager` (locks `mission-31-reprise`, puis `-2`)
**Branche** : `feat/phase-31-manifeste-dry-run` · **Base** : `2a2f0ef` (main)
**Statut de sortie** : **halt sur checkpoint bloquant** (`31-03` tâche 1) — vague 1 livrée, revue,
corrigée et re-vérifiée ; migration des ~35 sites en attente de ratification humaine.

---

## 1. État des nœuds

| Nœud | État |
|---|---|
| `rech-moteur`, `discuss`, `plan`, `plancheck` | **done** |
| `exec-01` (socle manifeste + suite + compteurs README) | **done**, revu, corrigé, re-vérifié |
| `exec-02` (mode `plan` de `merge-hooks.sh`) | **done**, revu, corrigé, re-vérifié |
| `exec-03` (migration ~35 sites) | **arrêté au checkpoint bloquant** — décision humaine |
| `exec-04..08`, `revue`, `verif`, `issue20-draft`, `docs` | bloqués |

**Suites sur l'arbre commité** (mesuré par le manager, bash 3.2 système) :
`test-manifest.sh` **8/8** · `test-merge-hooks.sh` **32/32** · `test-vibeflow-update.sh` **19/19**.
`check-machine-paths.sh` et `check-version-sync.sh` : **exit 0**. **62 suites** découvertes.

## 2. Le fil rouge de la mission : aucun vert auto-déclaré n'a tenu

| Étage | Auto-déclaré | Trouvé par un tiers |
|---|---|---|
| Plans (checker **interne** du pipeline) | `PASSED, 0 blocker` | **11 bloquants** (2 relectures externes) |
| 1re passe de correction | 11 corrigés | 9 fermés, **2 créés** |
| 2e passe | 2 fermés | **1 laissé** (mutant mort) |
| Vague 1 de code (2 workers) | suites vertes 5/5 et 32/32 | **2 bloquants + 1 majeur** (revue + vérif) |

Sans les étages de contrôle, la phase aurait migré ~35 sites d'écriture sur un socle dont **quatre
assertions ne pouvaient pas rougir**, avec un crash bash 3.2 dormant et un manifeste dont la
relativisation n'était protégée par rien.

## 3. Ce que les juges ont réellement attrapé

- **Install avortée pour presque tous les modules** — gardes `[ -f "$f" ]` retirées pendant que le
  helper propage le rc de `cp`, sous `set -euo pipefail`. Les globs `*.mjs`/`*.js`/`*.txt` ne
  matchent presque jamais et s'expandent en littéral.
- **Manifeste menteur relu pour supprimer** — `vf_place_tree` consignait depuis la source alors que
  la copie est un glob suffixé `|| true` : dotfiles écartés, échec partiel avalé. `31-05` s'en sert
  comme vérité pour **supprimer**.
- **Crash macOS-only** — `parts=($path)` sur chaîne vide laisse `parts` **unbound** en bash 3.2 ;
  `"${parts[@]}"` avorte tout. **CI Linux (bash ≥5) serait restée verte.**
- **Quatre assertions incapables de rougir**, prouvées par mutation : `sort -u` → `cat` (5 OK),
  liste d'exclusions neutralisée (manifeste inchangé au **byte** près), relativisation supprimée
  (manifeste **faux**, suite verte — `grep -qF` est un test de **sous-chaîne** et le chemin fautif
  **contient** le correct), diagnostic déplacé sur stdout (32 OK).
- **Trois critères de plan verts à vide** — ils scannaient des fonctions **pas encore écrites** :
  `0` se lit « conforme ». Ils passaient **avant** que le travail soit fait.

## 4. Prémisses fausses corrigées (dont deux à moi)

1. **Le compteur de suites EST gaté** (`check-version-sync.sh` §9). La recherche avait énuméré les
   contrôles 1 à 8 et manqué le 9e. D-31-08 survit, son motif s'inverse, et gagne une contrainte
   d'atomicité de commit.
2. **Le premier commit de cadrage a rendu `check-machine-paths.sh` ROUGE** — gate qui sert de
   critère d'acceptation à 8 tâches planifiées.
3. Deux valeurs de mes propres mandats étaient fausses (`split_fragment_hooks` 405→**404**,
   `show_status` 902-920→**902-918**) : les workers les ont corrigées parce que je leur avais
   demandé de me corriger plutôt que de m'obéir. **Garder cette formule.**

## 5. Arbitrages ajoutés en cours de mission

- **D-31-11** — ferme la couture `vf_place_tree` après **cinq** défauts d'affilée : le plan **prédit
  depuis la source** (sémantique du glob), le manifeste **consigne la destination**, la divergence
  est journalisée sans faire échouer la pose. Quatre point-fixes n'avaient pas fermé la classe ;
  c'était une **ambiguïté du cadrage**, pas une maladresse des plans.
- **D-31-11.4** (tranché par Samuel, option A) — **un seul émetteur, au grain fichier**. Deux
  émetteurs + dédup rendaient la mutation contournable. **Complément** : l'option A avait ouvert un
  **trou de silence** (source illisible ⇒ zéro paire ⇒ rien n'est dit) ; comblé par capture de rc.
- **D-31-12** — **une garde s'arme au grain unité** dès que le bout-en-bout ne l'exerce pas. Le
  moment le moins cher pour armer un filet est celui où le code est prouvé bon ; la vague suivante
  multiplie les sites par ~35. Corollaire : tout critère scannant une fonction absente porte une
  **garde d'existence** et se déclare **non évaluable**, jamais vert.

## 6. Décision en attente (bloquante)

**Ratifier la couture d'écriture avant de la router sur les ~35 sites ?** Options `ratifier` /
`ajuster` / `reduire`. **Recommandation : ratifier** — la forme est *mesurée*, pas supposée
(exécution réelle aux trois scopes, chemin à espace, chemin profond, destination peuplée, 3 poses
idempotentes) ; `reduire` produirait un manifeste **faux** (`copy_module_scripts` pose des scripts
qu'`uninstall` doit retrouver) et `ajuster` rouvrirait la dérive plan/pose que D-31-01 ferme.

## 7. Remontées non bloquantes

1. `--dry-run` sur `uninstall` — le verbe le plus dangereux est celui où une prévisualisation
   vaudrait le plus. Hors périmètre v1.
2. `docs/<module>/` écrit relativement au **cwd**, pas au scope : en scope user, la doc atterrit où
   l'utilisateur se trouvait.
3. **Dotfiles d'un sous-dossier de module jamais copiés** (le glob les écarte) — **gelé par test**,
   pas corrigé.
4. **Manifeste non gitignoré en scope local** — même famille que `.vibeflow-installed`, préexistant.
   La phase qui *introduit* le fichier est le bon moment pour l'ajouter.

## 8. Pièges d'outillage mesurés (à porter en mémoire d'équipe)

- **`grep` proxifié tronque silencieusement** : 31 lignes rendues sur 102. Tout décompte passe par
  `awk 'END{print NR}'`.
- **`wc` piped a rendu des valeurs fausses** : `wc -c < M` → `0` sur un fichier de 38 octets
  (`od -c` et `stat -f %z` concordants). Non reproductible à la demande, même classe que `grep`.
- **`gsd-execute-phase` filtre par vague, jamais par plan** : deux workers sur une même vague n'ont
  aucun support natif — l'un redispatcherait le plan de l'autre. Exécution **inline** via
  `execute-plan.md`, au prix des `SUMMARY` et des `verdicts` (à autoriser nommément).

## 9. Next step

Trancher §6. Sur `ratifier` : reprise à la tâche 2 de `31-03`, puis revue + vérif de la migration
(c'est le lot le plus risqué de la phase), puis `exec-04`. **`exec-08` doit dépendre de TOUS les
autres nœuds d'exécution** — ses must-haves exigent la suite verte sur l'arbre commité et des
compteurs README alignés sur la mesure finale.

## 10. Gates humains — aucun consommé

PR, merge, release racine : **non touchés**. Réponse et close de l'issue #20 : **draft disque
uniquement**, jamais posté (vérifié sur les 8 plans : les seules occurrences de `gh issue` sont les
interdictions elles-mêmes). Branche de phase créée avant le premier commit. Untracked étrangers
(`.gsd/`, `MISSION-30.dag.json`, `VFDO-36…`, `DRIVER.lock*`) jamais commités.

## 11. Calibration

`estimate` par plan (relayés verbatim) : 31-01 55000/3→2 · 31-02 40000/2 · 31-03 70000/3 ·
31-04 75000/3 · 31-05 70000/3 · 31-06 35000/2 · 31-07 45000/2 · 31-08 35000/2, tous `confidence: low`.
**Aucun `actuals`** : l'exécution inline (§8) court-circuite `state.record-metric`. Aucun `verdicts`
non plus — les hooks `execute:post` n'ont jamais tourné. Rien de fabriqué pour combler.
