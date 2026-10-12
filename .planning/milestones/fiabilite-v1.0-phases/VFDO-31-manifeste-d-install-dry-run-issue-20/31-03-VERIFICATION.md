---
phase: 31-manifeste-d-install-dry-run-issue-20
plan: 03
verified: 2026-08-16T15:55:00Z
status: gaps_found
score: 6/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
method: exécution réelle sur `git archive HEAD` (bcf1936), labs isolés `mktemp -d`, `HOME=$LAB/fakehome`, /bin/bash 3.2.57
gaps:
  - truth: "L'ensemble des lignes du manifeste est EXACTEMENT l'ensemble des fichiers réellement créés sous TARGET_ROOT, moins la liste close d'exclusions (D-31-03)"
    status: partial
    reason: >
      Mesuré par `comm` sur 6 modules × 3 scopes + `install --all` (17 modules) : ZÉRO mensonge
      (manifesté-mais-absent) dans tous les cas, mais 2 fichiers de fuite par module en scope
      project/local (settings.json, settings.local.json), 1 en scope user (settings.json), et 3
      sur --all (+ logs/archive.log). Ces chemins sont CRÉÉS sous TARGET_ROOT par la pose et ne
      figurent PAS dans la liste close de `vf_manifest_excluded`. Ils sont neutralisés uniquement
      par le filtre disque privé de T6 — donc la liste close existe en DEUX exemplaires
      divergents, en contradiction avec le commentaire « Point UNIQUE de définition » (l.157-158).
    artifacts:
      - path: "plugin/_internal/vibeflow-update.sh:159-169"
        issue: "vf_manifest_excluded ne couvre ni settings.json / settings.local.json ni logs/"
      - path: "plugin/_internal/tests/test-manifest.sh:164"
        issue: "le filtre disque de T6 ajoute ^settings\\.json$|^settings\\.local\\.json$ hors de la liste close — second point de définition"
    missing:
      - "Trancher : soit ajouter settings*.json (et logs/) à vf_manifest_excluded, soit amender l'énoncé de D-31-03 — dans les deux cas UN seul point de définition"
  - truth: "Le manifeste ne décrit jamais de fichiers absents du disque (classe « mensonge », celle que la convergence 31-05 utiliserait pour SUPPRIMER)"
    status: failed
    reason: >
      Après `uninstall <mod>`, le fichier `.claude/scripts/.vibeflow-manifest-<mod>` RESTE sur
      disque avec ses 13 lignes, dont 0 existe encore (comm -12 manifeste × disque = vide). Le
      manifeste devient un mensonge à 100 %. Aucun plan aval de la phase (31-05 / 31-07) ne prévoit
      son retrait ; or le commentaire de vf_manifest_reset (l.276-278) annonce que 31-05/31-07
      découvriront les manifestes PAR GLOB `.vibeflow-manifest-*` — ils découvriront donc un module
      fantôme.
    artifacts:
      - path: "plugin/_internal/vibeflow-update.sh:1172-1262"
        issue: "uninstall_module ne retire pas le manifeste du module désinstallé"
    missing:
      - "Décision humaine : retirer le manifeste dans uninstall_module, ou filtrer les consommateurs par le registre .vibeflow-installed"
deferred:
  - truth: "uninstall_module routé sur le socle manifeste"
    addressed_in: "Phase 31 / plan 31-07 (wave 5)"
    evidence: "31-07-PLAN.md must_haves : « uninstall_module retire ce que le MANIFESTE dit avoir été posé »"
  - truth: "sync_module_governance (update version inchangée) ne consigne rien"
    addressed_in: "Phase 31 / plan 31-05 (wave 4)"
    evidence: "31-05-PLAN.md must_haves : « sync_module_governance (version inchangée) ne touche JAMAIS au manifeste »"
---

# Phase 31 / plan 03 — Vérification par exécution réelle

**Objet** : la migration des ~35 sites d'écriture vers le socle manifeste (commits `b55c78f` +
`bcf1936`, branche `feat/phase-31-manifeste-dry-run`).
**Méthode** : arbre extrait par `git archive HEAD`, labs neufs `mktemp -d`, cache isolé,
`HOME="$LAB/fakehome"` — le vrai `$HOME` n'a jamais été écrit (`find "$HOME/.claude" -maxdepth 2
-newermt '-40 minutes' -type f | awk 'END{print NR+0}'` → `0`). Tout comptage par
`awk 'END{print NR+0}'` sur fichier matérialisé ; toute comparaison d'ensembles par `comm` ;
aucun `wc` piped, aucun `grep -c`, aucun `diff`. Shell : `/bin/bash` 3.2.57 (également le `bash`
du PATH, donc les suites tournent nativement en 3.2).

## 1. Exhaustivité module par module (`comm` disque × manifeste)

Commande : `TREE=<arbre> /bin/bash probe-exhaustivite.sh <module> <scope>`
(pose du module seul dans un lab neuf, puis
`find TARGET_ROOT -type f` moins la liste close D-31-03 UNIQUEMENT, `comm -23` / `comm -13`).

| module | profil | scope | disque brut | exclus D-31-03 | disque comparé | manifeste | **fuite** (posé, non manifesté) | **mensonge** (manifesté, absent) |
|---|---|---|---|---|---|---|---|---|
| software-architecture | SKILL.md + rules/ + references/ + scripts/ + scripts/tests/ + hooks/ | project | 17 | 3 | 14 | 12 | **2** — `settings.json`, `settings.local.json` | **0** |
| dev-orchestrator | AGENT.md + agents/ + skills/ + references/ + scripts d'index | project | 45 | 3 | 42 | 40 | **2** — idem | **0** |
| skill-creator | skills/ imbriqués (cp -r) + AGENT.md | project | 23 | 3 | 20 | 20 | **0** | **0** |
| reference | content/ seul (module doc pur) | project | 3 | 3 | 0 | 0 (présent, vide) | **0** | **0** |
| consolidator | SKILL.md + scripts + seed-registres (sème memory/) | project | 41 | 8 | 33 | 31 | **2** — idem | **0** |
| conductor | AGENT.md + skills/ + references/ + scripts/ + hooks/ | project | 62 | 3 | 59 | 57 | **2** — idem | **0** |
| software-architecture | — | **user** | 16 | 3 | 13 | 12 | **1** — `settings.json` | **0** |
| skill-creator | — | **user** | 23 | 3 | 20 | 20 | **0** | **0** |
| consolidator | — | **user** | 40 | 8 | 32 | 31 | **1** — `settings.json` | **0** |
| software-architecture | — | **local** | 17 | 3 | 14 | 12 | **2** | **0** |
| skill-creator | — | **local** | 23 | 3 | 20 | 20 | **0** | **0** |
| consolidator | — | **local** | 41 | 8 | 33 | 31 | **2** | **0** |

Dans les 12 poses : `lignes_repertoire=0`, `lignes_absolues=0` — y compris en scope `user`, le seul
où `TARGET_ROOT` est absolu. Le manifeste reste relatif dans les trois scopes.

**Asymétrie `docs/` (D-31-03)** — `reference` : `docs_disque=77`, `docs_au_manifeste=0`, manifeste
PRÉSENT et VIDE (0 octet, pas absent). Conforme.

### `install --all` (17 modules, un seul lab)

Commande : `/bin/bash probe-all.sh` (union de tous les `.vibeflow-manifest-*` vs disque).

```
passe 1 : manifestes=17  lignes cumulées=267  doublons inter-modules=0
          disque_brut=298  disque_hors_exclusions=270  union_uniq=267
          FUITE=3  (logs/archive.log, settings.json, settings.local.json)   MENSONGE=0
          résidus acc/tmp=0   lignes_repertoire=0   lignes_absolues=0
passe 2 : identique — manifestes identiques entre passes (cmp OUI),
          0 nouveau fichier disque hors .backups
```

`logs/archive.log` : tracé jusqu'à sa source — `design-orchestrator/scripts/ensure-design-deps.sh`
invoque le vrai CLI `claude`, dont la session déclenche le hook SessionStart de `consolidator`
(`archive.sh`), qui écrit `.claude/logs/archive.log`. Chemin créé sous TARGET_ROOT, hors liste
close, hors filtre de T6.

## 2. Les trois scopes

Isolation : chaque lab est un `mktemp -d` avec `HOME="$LAB/fakehome"` et `VIBEFLOW_CACHE="$LAB/cache"` ;
scope `project`/`local` → `cd "$LAB"` (TARGET_ROOT `./.claude`), scope `user` → `$FAKEHOME/.claude`.
Résultat : voir le tableau ci-dessus — exactitude et relativité identiques dans les trois scopes,
seule différence attendue en scope `user` (pas de `settings.local.json`, cohérent avec le routage
`--settings-local` réservé à project/local).

## 3. Chemins autres qu'`install` — le trou signalé par l'exécutant

Commande : `/bin/bash probe-cycles.sh software-architecture`.

| chemin | mesure | verdict |
|---|---|---|
| 2ᵉ `install` (idempotence) | manifeste 12 → 12, `comm` nouveaux=0 perdus=0, doublons=0, 0 nouveau fichier disque hors `.backups`, résidus `.tmp`/`.vibeflow-acc-*`=0 | conforme |
| `update` version INCHANGÉE | manifeste **non modifié** (`cmp -s` identique) | conforme au contrat 31-05 |
| module GAGNE un fichier, PAS de bump, puis `update` | `scripts/nouveau-31.sh` **sur disque = OUI**, **au manifeste = NON** | **fuite mesurée** — consignation silencieusement no-op (`vf_record` l.258 : `[ -n "$VF_MANIFEST_TMP" ] \|\| return 0`) |
| même gain, mais `install` explicite (version inchangée) | **au manifeste = OUI** (12 → 13) | la fuite est spécifique au chemin `update`/`sync_module_governance` |
| `update` version CHANGÉE | manifeste réécrit 12 → 13, `nouveau-31.sh` **entre au manifeste**, tri/dédup OK | conforme — la fuite se résorbe au bump suivant |
| `uninstall` | rc=0 ; reste sur disque hors `.backups` : `scripts/.vibeflow-installed`, **`scripts/.vibeflow-manifest-software-architecture`**, `scripts/vf-portable.sh`, `settings.json`, `settings.local.json` ; `comm -12` manifeste × disque = **vide** (13 lignes, 0 existante) | **le manifeste N'EST PAS retiré** → manifeste orphelin, mensonge à 100 % |

## 4. Chemin d'abandon (D-31-07)

Commande : `/bin/bash probe-abandon2.sh` — cibles `rules/*.md` supprimées puis `chmod 500` sur le
répertoire, bump de version pour forcer une re-pose complète.

```
install 2 rc=1  →  cp: ./.claude/rules/doc-research-before-debug.md: Permission denied
manifeste (témoin ZZZ ajouté avant) intact ? OUI   md5 avant=5fc0d02… après=5fc0d02…
version au registre : v1.6.0  (mark_installed jamais atteint — le registre ne ment pas)
scripts/.vibeflow-acc-software-architecture.79784   ← résidu d'accumulateur
captures par le glob .vibeflow-manifest-* : 1  (le seul vrai manifeste)
résidus .vibeflow-acc-* : 1
```

D-31-07 tient : l'ancien manifeste est **byte-identique**, le résidu est **hors** du motif
`.vibeflow-manifest-*`. Complément mesuré : une **ré-install réussie ensuite NE nettoie PAS** le
résidu (nouveau PID → nouveau fichier ; l'ancien reste), il n'est jamais consigné au manifeste et
n'est pas dans la liste close → orphelin permanent sous `scripts/`, un par abandon.

Une première tentative d'abandon (`chmod 500` sans supprimer les cibles) **n'a PAS interrompu la
pose** (rc=0) : réécrire un fichier existant ne demande pas le droit d'écriture sur son répertoire.
Ce faux négatif est signalé — la mesure retenue est celle de `probe-abandon2.sh`.

## 5. La suite peut-elle rougir ? — 8 mutations du code de production

Protocole : mutation appliquée sur l'arbre archivé (le vrai dépôt n'est jamais touché),
suite rejouée, puis restauration prouvée par `cmp -s` contre une copie pristine.
Référence : **15 OK / 0 KO / 0 SKIP** (aucun fixture mort — aucun SKIP dans aucun run).

| # | mutation (site de production) | assertion qui casse | attendu | obtenu | suite | restauré (`cmp`) |
|---|---|---|---|---|---|---|
| M1 | `copy_module_scripts` boucle `*.sh` : `vf_place_file … exec` → `cp` brut | **T6** | égalité manifeste × disque | `✗ T6 : manquants du manifeste=[scripts/check-file-size.sh,scripts/guard-file-size.sh] en trop=[]` | 14/1 | OUI |
| M2 | `vf_place_tree` passe 2 : `vf_declare_write + "$dest_file"` → `"$dest_dir/"` | **T7** (+ T6, T9b) | grain fichier, aucune ligne répertoire | `✗ T7 : grain fichier non respecté pour skill-creator` ; T6 : `en trop=[skills/software-architecture/references]` | 12/3 | OUI |
| M3 | `vf_place_tree` : `cp -r "$src"/*` → `cp -r "$src"/.` | **T7b** | dotfile ni posé ni consigné | `✗ T7b : dotfile … posé et/ou consigné à tort (disque présent=oui)` | 14/1 | OUI |
| M4 | `vf_record` : retrait du filtre `vf_rel_to_target` | **T8** (+ T1, T3b, T4b, T6, T7, T9b) | 0 ligne `docs/` | `✗ T8 : asymétrie docs/ non respectée (docs sur disque=77, manifeste a des lignes docs/=1)` | 8/7 | OUI |
| M5 | `vf_manifest_excluded` neutralisée (`return 1`) | **T5 + T9** (+ T5b, T6) | aucune entrée de la liste close | `✗ T5 / ✗ T9 : le manifeste contient une entrée de la liste close` ; T6 : `en trop=[scripts/vf-portable.sh]` | 11/4 | OUI |
| M6 | retrait de l'appel `vf_note_degraded_copy "$dest_file"` | **T9b** (seul) | message de divergence sur stderr | `✗ T9b : copie dégradée non conforme (rc=0)` | 14/1 | OUI |
| M7 | retrait du garde du trou de silence (`if [ -n "$cp_rc" ] …`) | **T9c** (seul) | compte rendu malgré énumération vide | `✗ T9c : trou de silence NON rattrapé (rc=0)` | 14/1 | OUI |
| M8 | `vf_manifest_flush` : `LC_ALL=C sort -u` → `cat` | **T4** (+ T4b) | manifeste trié, dédupliqué | `✗ T4 : manifeste NON trié ou avec doublon(s)` | 13/2 | OUI |

8 mutations / 8 discriminantes. Les 4 traces revendiquées par le SUMMARY (T6, T8, T9b, T9c) sont
reproduites **à l'identique**, y compris les listes de chemins et les cascades annoncées.

### Verdict T4 / T5 — « vacants en vague 1, devenus discriminants »

Vérifié des DEUX côtés, par exécution :

- **Vague 1** (`git archive 1a3d471`, suite T1-T5b, 8 OK/0 KO) : M8 → `✓ T4` reste VERT (seul T4b
  rougit) ; M5 → `✓ T5` reste VERT (seul T5b rougit). Restauration `cmp` OUI dans les deux cas.
- **HEAD** (manifeste passé de 1 à 12 lignes) : M8 → `✗ T4` ; M5 → `✗ T5`.

La promesse est **exacte**.

## 6. Non-régression et prohibitions (arbre TEL QUE COMMITÉ)

| contrôle | commande | résultat |
|---|---|---|
| suite manifeste | `/bin/bash tree/plugin/_internal/tests/test-manifest.sh` | **15 OK / 0 KO / 0 SKIP** |
| non-régression engine | `test-vibeflow-update.sh` | **19 OK / 0 KO / 0 SKIP** |
| non-régression hooks | `test-merge-hooks.sh` | **32 OK · 0 KO** |
| cohabitation GSD | `test-gsd-cohabitation.sh` | **8 ok, 0 ko** |
| chemins machine | `scripts/check-machine-paths.sh` | `✓ 1033 fichier(s) balayé(s), aucun chemin absolu` |
| C1 — `cp` bruts dans `install_module` + `copy_module_scripts` | `awk` sur plages 750-790 / 901-1117, commentaires filtrés | **0** |
| émetteurs `vf_note_degraded_copy` | `awk` hors commentaires | **1 définition + 1 site d'appel** |
| `\|\| true` dans la couture | `awk` hors commentaires | **0** dans `vf_place_file`/`vf_place_tree`/`vf_declare_write`/`vf_record` (les 6 occurrences du fichier sont préexistantes : `mark_installed`, `mark_uninstalled`, `copy_engine_lib` tmp, 3 `rmdir` d'`uninstall`) |
| `rollback_module` / `uninstall_module` non migrés | `awk` plages 1146-1262 | motif « non migré » présent ×2 ; **0** appel aux helpers du socle |
| Pitfall 1 — aucune fonction d'énumération du cache | `comm` des fonctions définies v1 × HEAD | ajoutées : `vf_declare_write`, `vf_note_degraded_copy`, `vf_place_tree` — **3, aucune d'énumération** ; retirées : aucune |
| marqueurs de dette | `awk /TODO\|FIXME\|XXX\|TBD\|HACK\|PLACEHOLDER/` sur les 2 fichiers modifiés | **0** |

### Comportement observable inchangé (D-31-01) — prouvé, pas supposé

`probe-equivalence.sh` : même module posé par le moteur de la **vague 1** (`1a3d471`) puis par le
moteur **HEAD**, comparaison `comm` sur `chemin<TAB>md5` de tous les fichiers de `.claude/` + `docs/`
(manifeste exclu, c'est le seul artefact censé changer) :

```
software-architecture 16/16 · skill-creator 22/22 · dev-orchestrator 44/44
reference 79/79 · consolidator 40/40 · conductor 61/61     → 0 ligne divergente
```

Un écart apparent sur `dev-orchestrator/gsd-skills-index.md` a été **disqualifié par un témoin** :
deux poses successives avec le MÊME moteur HEAD divergent aussi sur ce seul fichier — l'index
généré est non déterministe, pas un changement de comportement.

Bash 3.2 : `uninstall --all` sur registre vide, `install --with-deps` sans résolveur, `update --all`
— aucun `unbound variable`, aucun abort.

## 7. Écarts retenus

| # | constat | gravité | direction |
|---|---|---|---|
| G-1 | `settings.json` / `settings.local.json` créés sous TARGET_ROOT, jamais manifestés, **absents de la liste close** `vf_manifest_excluded` — neutralisés seulement par le filtre disque privé de T6 (second point de définition, l.164) | moyenne | fuite (sûre) |
| G-2 | Manifeste **orphelin après `uninstall`** : 13 lignes, 0 existante. Aucun plan aval ne le retire, alors que 31-05/31-07 doivent découvrir les manifestes **par glob** | **haute** | mensonge |
| G-3 | Fichier gagné par un module **sans bump** : posé par `update`, jamais manifesté jusqu'au bump suivant | moyenne | fuite (assumée par 31-05) |
| G-4 | Résidu `.vibeflow-acc-<mod>.<pid>` d'une pose avortée : jamais nettoyé, même par une pose ultérieure réussie ; hors liste close | basse | fuite |
| G-5 | `logs/archive.log` créé à l'install (`ensure-design-deps.sh` → CLI `claude` → hook SessionStart de `consolidator`), hors liste close et hors filtre T6 | basse | fuite |
| G-6 | Commentaire de production `uninstall_module` (l.1173-1175) et SUMMARY l.46 : « dernière vague EXPLICITEMENT ABANDONNABLE (**31-08**) ». Mesuré : la migration d'`uninstall` est **31-07** (wave 5) ; **31-08** (wave 6) est la réponse à l'issue #20 | basse | doc |

---

_Vérifié : 2026-08-16 · sondes conservées dans le scratchpad de session (probe-exhaustivite.sh,
probe-cycles.sh, probe-abandon2.sh, probe-all.sh, probe-equivalence.sh, mutate.py, run-mutation.sh)_
