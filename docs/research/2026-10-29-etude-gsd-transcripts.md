# Appels GSD réels dans les transcripts Claude Code — mesure du 2026-10-29

Étude en lecture seule, premier des deux chiffres qui conditionnent la poursuite de la sortie de GSD
au-delà de l'épinglage (le second, l'historique git/GitHub, est mesuré à part). Agrégats seulement :
aucun extrait de conversation, aucun contenu métier.

## 1. Périmètre et fenêtre

Dossiers inclus :

- `~/.claude/projects/<vibeflow-os>/` : 27 sessions racine + 448 transcripts de sous-agents ;
- `~/.claude/projects/<Scroll-Off>/` : 40 sessions racine + 399 transcripts de sous-agents.

Aucun dossier de projet séparé n'existe pour les worktrees : les sessions lancées dans
`.claude/worktrees/*` sont rangées sous le dossier du dépôt principal (5 sessions vibeflow-os et
6 Scroll-Off ont un `cwd` en worktree, déjà comptées). Exclus, car ce sont d'autres dépôts :
`vibeflow-video` (9 sessions) et `vibeflow-formation-m2` (vide).

| projet | premier événement | dernier événement | sessions | transcripts sous-agents |
| --- | --- | --- | --- | --- |
| vibeflow-os | 2026-09-24 21:42 UTC | 2026-10-29 13:29 UTC | 27 | 448 |
| Scroll-Off | 2026-09-27 00:56 UTC | 2026-10-28 12:03 UTC | 40 | 399 |
| total | 2026-09-24 | 2026-10-29 | 67 | 847 |

**Tout ce qui précède le 2026-09-24 (vibeflow-os) et le 2026-09-27 (Scroll-Off) n'est pas mesuré** :
Claude Code purge par défaut les transcripts de plus de 30 jours. Les phases GSD antérieures (jalons
agentique-v1.0 et fiabilite-v1.0 pour l'essentiel, migrations gsd-core, incidents `state
record-session`) sont hors fenêtre.

## 2. Méthode

Scripts (Python, lancés en `python3 -I`, lecture en flux ligne à ligne) : `etude-gsd/mesure.py`
(extraction, sortie JSON d'agrégats) et `etude-gsd/agrege.py` (tableaux) — scripts de session, non versionnés.

- **Skills `gsd-*`** : blocs `tool_use` de l'outil `Skill` dont `input.skill` (préfixe de plugin
  retiré) commence par `gsd-` ; plus les commandes slash tapées (`<command-name>/gsd-…` dans un
  message utilisateur).
- **Agents `gsd-*`** : `tool_use` `Agent`/`Task` avec `subagent_type` `gsd-*`.
- **CLI** : `tool_use` `Bash` dont la commande contient `gsd-tools`, `gsd_run`, `gsd-run.sh` ou
  `gsd-sdk`, **et** où un verbe est extrait d'une forme d'invocation (`<lanceur> [query] <verbe>`,
  ou `node $VAR [query] <verbe>` quand la variable vise gsd-tools). Les verbes sont filtrés
  (forme pointée/tiretée ou famille connue : `state`, `roadmap`, `phase`, `check`, `loop`, …) pour
  écarter les mots de prose et les chemins (`gsd-run.sh plugin/…`). Les formes `a b` et `a.b` sont
  fusionnées. Exclus et comptés à part : **sondes de VibeFlow sur son propre lanceur**
  (`test-gsd-run.sh`, `gsd-run.sh ping`, PATH factice, `workstream bogus`) et **mentions sans
  invocation** (grep, cat, git add d'un fichier qui porte ces noms).
- Dédoublonnage par identifiant de `tool_use` (un même appel peut apparaître dans la session et
  dans le transcript du sous-agent).
- **Erreurs** : `tool_result` lié à un appel GSD avec `is_error: true`, ou (CLI seulement) sortie
  contenant `Error`/`ERROR` en tête de ligne, `Error:`, `Exit code` non nul, `command not found`,
  `Cannot find module`, `No such file`. Chaque erreur est ensuite classée sur sa sortie ; celles
  dont la cause est une **autre partie d'une commande composite** (traceback Python, `ls`/`grep`
  d'un chemin local, `git add`, check VibeFlow chaîné) sont marquées non attribuables et ne
  forment pas d'épisode.
- **Épisodes et temps** : par transcript, une erreur attribuable ouvre un épisode, fermé au
  prochain appel **du même type** (même catégorie skill/agent/CLI et au moins un verbe ou nom
  commun) qui réussit ; les erreurs du même type dans l'intervalle sont fusionnées. Durée =
  horodatage de l'appel en erreur → horodatage de l'appel réussi. **Ambigu** (non sommé) : pas de
  reprise réussie dans le transcript, ou reprise après plus de 60 min.
- **Tokens** : somme des champs `usage` des messages assistant (dédoublonnés par `message.id`) du
  même transcript dont l'horodatage tombe dans l'intervalle de l'épisode.

## 3. Appels GSD réels, comparés à VibeFlow et superpowers

| catégorie | vibeflow-os | Scroll-Off | total |
| --- | --- | --- | --- |
| Skills `gsd-*` (outil Skill) | 23 | 18 | 41 |
| `/gsd-*` tapés par l'utilisateur | 0 | 0 | 0 |
| Agents `gsd-*` dispatchés | 124 | 54 | 178 |
| Commandes Bash invoquant le CLI GSD | 307 | 90 | 397 |
| Verbes CLI GSD (une commande peut en porter plusieurs) | 437 | 134 | 571 |
| *exclus : sondes VF du lanceur* | 42 | 0 | 42 |
| *exclus : mentions sans invocation* | 288 | 18 | 306 |
| Skills `vf-*`/`vibeflow*` (outil Skill) | 6 | 3 | 9 |
| `/vf-*` tapés | 2 | 2 | 4 |
| Agents `vf-*`/`vibeflow*` dispatchés | 261 | 182 | 443 |
| Skills `superpowers:*` | 0 | 1 | 1 |
| Agents autres (general-purpose, Explore, …) | 77 | 162 | 239 |

Lecture : l'utilisateur n'a tapé **aucune** commande `/gsd-*` dans la fenêtre ; il entre par
`/vf-*` (et des skills hors VibeFlow). GSD est appelé **par les agents** : les skills `gsd-*` sont
invoqués par les workers `vf-*` (vf-coder surtout), les agents `gsd-*` sont dispatchés par eux, et
le CLI est appelé depuis les workflows GSD chargés et depuis les scripts VibeFlow.

### Skills `gsd-*` invoqués

- vibeflow-os : `gsd-execute-phase` 9, `gsd-plan-phase` 8, `gsd-discuss-phase` 2, `gsd-phase` 1,
  `gsd-sketch` 1, `gsd-quick` 1, `gsd-debug` 1.
- Scroll-Off : `gsd-quick` 16, `gsd-quick-batch` 2.

**Noyau : 8 skills distincts sur 72 installés (11 %)** ; 10 agents `gsd-*` distincts sur 35.

### Agents `gsd-*` dispatchés

- vibeflow-os : `gsd-executor` 56, `gsd-plan-checker` 19, `gsd-code-reviewer` 16, `gsd-planner` 9,
  `gsd-phase-researcher` 8, `gsd-verifier` 7, `gsd-pattern-mapper` 5, `gsd-security-auditor` 2,
  `gsd-advisor-researcher` 1, `gsd-doc-verifier` 1.
- Scroll-Off : `gsd-code-reviewer` 20, `gsd-planner` 17, `gsd-executor` 14,
  `gsd-phase-researcher` 2, `gsd-plan-checker` 1.

### Top 15 des verbes CLI

| verbe | vibeflow-os | Scroll-Off | total |
| --- | --- | --- | --- |
| `verify.plan-structure` | 56 | 29 | 85 |
| `dispatch-isolation` | 39 | 2 | 41 |
| `config-get` | 22 | 8 | 30 |
| `config-set` | 17 | 10 | 27 |
| `estimate-calibration` | 10 | 15 | 25 |
| `frontmatter.validate` | 1 | 19 | 20 |
| `init.quick` | 2 | 17 | 19 |
| `agent-skills` | 6 | 10 | 16 |
| `quick-tasks-append` | 0 | 16 | 16 |
| `init.plan-phase` | 15 | 0 | 15 |
| `check.verify-command-paths` | 11 | 1 | 12 |
| `estimate-check` | 10 | 0 | 10 |
| `check.verify-failure-directions` | 10 | 0 | 10 |
| `loop.render-hooks` | 8 | 1 | 9 |
| `verification.fingerprint` | 8 | 0 | 8 |

61 verbes distincts au total (vibeflow-os 58, Scroll-Off 14). Sur Scroll-Off, le CLI sert presque
entièrement au circuit `gsd-quick` (init, validation de plan, ajout à la table des quick tasks,
calibration).

## 4. Erreurs liées à GSD

| type | vibeflow-os | Scroll-Off | total |
| --- | --- | --- | --- |
| garde d'isolation : dispatch `gsd-executor` refusé (isolation résolue en `harness-worktree`) | 14 | 0 | 14 |
| usage CLI : commande, sous-commande ou argument inconnu | 8 | 0 | 8 |
| config de workstream absente (`No config.json` sous le workstream) | 6 | 0 | 6 |
| lanceur `gsd-tools`/`gsd_run` hors PATH (`command not found`) | 2 | 3 | 5 |
| refus d'une garde GSD (vérification incomplète, empreinte, section absente, chemin hors racine) | 3 | 1 | 4 |
| chemin legacy `get-shit-done` (module introuvable) | 1 | 0 | 1 |
| sonde volontaire (clé de config inventée) — exclue | 1 | 0 | 1 |
| composite : échec d'une autre partie de la commande — non attribuable, exclue | 15 | 6 | 21 |
| **attribuables à GSD** | **34** | **4** | **38** |

Pièges connus :

| piège | vibeflow-os | Scroll-Off | total |
| --- | --- | --- | --- |
| appels `phase.add` / `phase add` | 6 | 0 | 6 |
| commandes de sauvegarde/restauration de `STATE.md` (`cp … STATE.md`, `git checkout/restore … STATE.md`) | 8 | 0 | 8 |
| sortie d'un appel GSD signalant gsd-core ou le lanceur introuvable | 4 | 3 | 7 |
| appels `state record-session` | 0 | 0 | 0 |
| appels `state.planned-phase` | 0 | 0 | 0 |
| Node 24 / `EBADENGINE` dans la sortie d'un appel GSD | 0 | 0 | 0 |
| `T28-F` / index périmé dans la sortie d'un appel GSD | 0 | 0 | 0 |

Les pièges historiques les plus coûteux (`state record-session`, `state.planned-phase`, Node 24,
T28-F) **n'apparaissent pas dans la fenêtre** : soit ils sont contournés (sauvegardes de STATE.md
avant appel), soit ils datent d'avant le 2026-09-24. T28-F et l'index se manifestent en CI, donc
côté historique GitHub, pas dans les transcripts : non mesuré ici. La régression de STATE.md
elle-même (comparaison de contenu avant/après) : non mesurée.

## 5. Temps passé (épisodes d'erreur)

| | vibeflow-os | Scroll-Off | total |
| --- | --- | --- | --- |
| épisodes mesurés | 20 | 3 | 23 |
| somme | 35,7 min | 0,4 min | 36,1 min |
| somme hors épisode maximal | 7,0 min | 0,2 min | 7,2 min |
| min / médiane / max | 3 s / 10 s / 1 722 s | 5 s / 10 s / 10 s | 3 s / 10 s / 1 722 s |
| épisodes ambigus (non sommés) | 9 | 1 | 10 |

Par type (vibeflow-os) : garde d'isolation 8 épisodes, 4,5 min ; usage CLI 4 épisodes, 30,5 min
(dont l'épisode maximal de 28,7 min : la reprise réussie du même verbe arrive après d'autres
travaux, la durée est une **borne haute probablement surestimée**) ; config de workstream 3
épisodes, 0,3 min ; refus de garde 2 épisodes, 0,2 min ; lanceur hors PATH 2, 0,1 min ; chemin
legacy 1, 0,1 min. Scroll-Off : lanceur hors PATH 2 épisodes, 0,2 min ; refus de garde 1, 0,2 min.

Ambigus (pas de reprise réussie du même appel dans le transcript) : vibeflow-os 4 usage CLI,
3 config de workstream, 1 refus de garde, 1 garde d'isolation ; Scroll-Off 1 lanceur hors PATH.

**Fourchette retenue : entre ~7 min (hors épisode maximal) et ~36 min (tout compris) de temps
mur sur ~35 jours**, plus 10 épisodes non chiffrés. Ce temps est du temps d'agent, pas
nécessairement du temps humain.

## 6. Coût en tokens pendant les épisodes

Somme des `usage` des messages assistant dans les 23 épisodes mesurés : input 302, création de
cache 1,10 M, lecture de cache 35,8 M, sortie 78 k (dont l'épisode maximal : création 0,24 M,
lecture 18,1 M, sortie 16 k). Ces tokens sont **tout ce que le transcript a consommé pendant
l'intervalle**, pas le surcoût marginal dû à l'erreur (la lecture de cache rejoue le contexte à
chaque tour). Le surcoût marginal : non mesuré.

## 7. Limites

- **Fenêtre de ~35 jours seulement** ; tout le passé antérieur est non mesuré, et c'est là que
  se trouvent la plupart des incidents GSD documentés en mémoire.
- Appels CLI masqués : les commandes avec `2>/dev/null`, `|| true` ou `| head` cachent des
  échecs ; une erreur qui ne remonte ni `is_error` ni texte d'erreur n'est pas vue.
- Le CLI appelé **à l'intérieur** d'un script VibeFlow (`check-*.sh`, `ensure-deps.sh`, …) n'est
  pas visible dans la commande Bash : sous-compté.
- Les workflows GSD chargés par un skill émettent leurs appels CLI comme des commandes Bash de
  l'agent : ils sont comptés comme appels CLI, sans lien vers le skill parent.
- Classement des erreurs par motifs textuels sur la sortie ; une commande composite peut porter
  une erreur GSD réelle masquée par la classe « non attribuable ».
- Durée d'épisode = proxy (prochain appel réussi du même type) ; elle inclut tout travail
  intercalé et ignore le temps passé hors transcript (sessions parallèles, humain).
- Temps humain, temps de CI et coût marginal en tokens : non mesurés.
