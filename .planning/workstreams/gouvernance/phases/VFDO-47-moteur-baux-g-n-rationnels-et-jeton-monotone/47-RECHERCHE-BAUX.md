# Phase 47 — Recherche documentaire (delta) : baux générationnels, jeton monotone, G2′

> Nœud `recherche-47`, mission `vf-dev-manager-p47-cadrage`, mandat ADR-045. Rien n'est codé ici.
> Consultation : **2026-10-12**. Version locale : `claude --version` → **`2.1.296 (Claude Code)`**.
> **Delta** de `../VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-RECHERCHE-HOOKS.md` (« R46 »,
> 2.1.288) et de `46.1-RECHERCHE-HOOKS.md` sur `origin/gouvernance/phase-46.1-cadrage` (« R461 »,
> 2.1.292). Ce qu'elles établissent n'est pas refait.

**Méthode.** Pages `.md` brutes par `curl` (même méthode que R46/R461) : **[H]** …/docs/en/hooks,
**[T]** …/tools-reference, **[SA]** …/sub-agents, **[EV]** …/env-vars, **[CL]** …/changelog (base
`https://code.claude.com/docs/en/`, lues le 2026-10-12). Issues `anthropics/claude-code` lues par
`gh issue view`, état au 2026-10-12. Normes : **[POSIX]** POSIX.1-2024
(`https://pubs.opengroup.org/onlinepubs/9799919799/`). Aucune sonde `claude -p`, aucun hook posé,
aucune expérience de fichier : les observations locales (**O**) sont des lectures (`command -v`,
`man`, `python3 -c 'import …'`).
**Niveaux.** **D** documenté · **O** observé localement · **C** constaté par une issue (non revérifié)
· **I** inféré · **NT** non trouvé / non documenté.

---

## R1 — Identité dans le fan-out

| # | Constat | Niveau | Source |
|---|---|---|---|
| 1.1 | Le `PreToolUse` d'un appel d'outil **d'un sous-agent** porte `agent_id` et `agent_type` : « When a subagent calls a tool, tool events such as `PreToolUse` and `PostToolUse` fire the same configured hooks […] and the input carries the `agent_id` and `agent_type` common input fields that identify the subagent. » | D | [H] § hook locations (l.269), § Common input fields |
| 1.2 | Introduits en **v2.1.69** (2026-03-05) : « Added `agent_id` (for subagents) and `agent_type` (for subagents and `--agent`) to hook events ». Sur `TaskCreated`/`TaskCompleted`/`TeammateIdle`, `agent_id` n'est garanti qu'à partir de **v2.1.290** (« May be absent »). | D | [CL] 2.1.69, 2.1.290 ; [H] § TaskCompleted input |
| 1.3 | Déjà mesuré dans ce dépôt sur 2.1.284 : présents en sous-agent, **absents au fil principal** ; un dispatch imbriqué porte l'`agent_type` de l'appelant. | O (antérieur) | `45-RESEARCH.md:261` ; `45-08-PLAN.md:88` |
| 1.4 | `session_id` d'un sous-agent = **celui du parent** : la doc ne le dit pas (elle dit seulement « Current session identifier »). Constaté par #76726 (OPEN, maj 2026-10-01, « N parallel subagents all present the same `session_id` and all pass the same mutex ») et mesuré octet pour octet sur 2.1.246 dans un commentaire de #84701 (`session_id` **et** `transcript_path` identiques, seules clés ajoutées : `agent_id`, `agent_type`). | NT (doc) / C | [H] ; #76726 ; #84701 |
| 1.5 | `CLAUDE_CODE_SESSION_ID` est exporté au Bash outil et aux hooks, égal au `session_id` du payload. **Aucune variable documentée n'expose `agent_id` à un sous-processus Bash** : un script lancé par un sous-agent ne connaît pas son `agent_id`. #76221 (OPEN) : environnement d'un sous-agent « byte-identical to the parent ». | D / NT / C | [EV] `CLAUDE_CODE_SESSION_ID` ; #76221 |
| 1.6 | Lien mandat → `agent_id` : `PreToolUse(Agent)` voit `tool_input.prompt` + `tool_use_id` ; `PostToolUse(Agent)` voit `tool_use_id` + `tool_response.agentId` — **au lancement** pour un sous-agent d'arrière-plan (`async_launched`), **à la fin seulement** pour un sous-agent au premier plan. `SubagentStart` porte `agent_id` mais ni prompt ni `tool_use_id` (demandes ouvertes #87411, #100198). | D / C | [H] § PostToolUse (Agent), § SubagentStart ; #87411 ; #100198 |
| 1.7 | Anomalies d'identité ouvertes : #90662 (2.1.251) `PreToolUse`/`PostToolUse` d'un sous-agent en cours parfois sous un **autre** `agent_id`, sans `SubagentStart` ni `agent_type` ; #89555 (SubagentStop) ; #84701/#88441 hooks présumés muets en sous-agent — **contestés** par des reproductions (2.1.233, 2.1.246). | C | issues citées |
| 1.8 | Un sous-agent repris (`SendMessage`) est adressé par son agent ID ; que le payload de hook d'un sous-agent repris garde le **même** `agent_id` : non documenté. | D / NT | [SA] § Resume subagents |

**Conséquence (I).** Le hook ne lit pas « le mandat » : il lit une **identité d'appelant**. Le seul
couple vérifiable est **`agent_id` s'il est présent, sinon `session_id`** (fil principal). Le jeton
« porté par le mandat » (§6.1 bis) doit donc être **traduit en une entrée de registre** (`gen-<n>/meta`
: détenteur = `agent_id` ou `session_id`, chemins couverts) que le hook confronte au payload. Le lien
« ce nœud du DAG = cet `agent_id` » n'est disponible qu'au lancement d'un sous-agent d'arrière-plan ; au
premier plan, la prise doit être faite **par le sous-agent lui-même** (sa première écriture ou un geste
`prendre` par Bash), pas par le parent avant dispatch. Deux frères qui prennent le même fichier se
dépassent l'un l'autre : la seconde prise rend la première périmée — c'est le comportement voulu
(conflit rendu visible), au prix d'un ping-pong entre écrivains légitimes. #90662 est le risque
résiduel : un `agent_id` changé fait passer un détenteur légitime pour un tiers (faux refus).

---

## R2 — Présenter un jeton au moment d'une écriture

| Voie | Ce que le hook voit | Limite principale | Niveau |
|---|---|---|---|
| **a. Jeton dans le contenu** (frontmatter `bail: 7`) | `Write` : tout `tool_input.content` ; `Edit` : `old_string`/`new_string` seulement ; `Bash` : rien | **Forgeable** : l'agent lit le fichier et recopie le dernier jeton ; une session revenue qui relit le fichier se « met à jour » toute seule. Contraire à §5.2 règle 1. | D (champs) / I |
| **b. Registre de bail lu par le hook, lié à l'identité** (`.planning/baux/…/gen-*/meta` ↔ `agent_id`/`session_id`) | Payload + registre | Pas de jeton à présenter, donc rien à recopier. Mais le registre vit dans un dossier **écrivable par Bash** : `Write`/`Edit` y sont gardables (G6), `Bash` non — D1 + réconciliation au `SessionStart` le tracent. | I |
| **c. Variable d'environnement** | Rien (le hook hérite de l'environnement de Claude Code) | Un `export` dans Bash n'atteint pas Claude Code (R461 § 2.5). `CLAUDE_ENV_FILE` (SessionStart) vaut pour toute la session, sous-agents compris (#76221) : ne distingue pas deux frères. Utile **seulement** pour un cron (variable dans le plist launchd), et jamais comme frontière. | D / C |
| **d. `updatedInput`** (le hook réécrit l'appel `Bash` : préfixe `VF_AGENT_ID=<id> VF_BAIL=<n>`) | Le hook est l'auteur du jeton | Exige `permissionDecision` `allow` (saute l'invite) ou `ask` (invite l'humain) ; les règles de permission sont réévaluées sur l'entrée réécrite (2.1.290). Les hooks concordants tournent **en parallèle** : l'ordre de deux `updatedInput` concurrents n'est pas documenté. Une commande composée (`a; VF_AGENT_ID=x b`) garde une usurpation possible. Sur `Write`, réécrire le contenu altère le livrable. | D / NT / I |
| **e. Argument explicite** (`dag.sh mark --bail=7`) | `tool_input.command` | Forgeable comme (a) ; utile seulement si le hook le **recoupe** avec le registre pour l'`agent_id` du payload. | I |

**Littérature.** Kleppmann, « How to do distributed locking » (2016-02-08,
`https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html`) : le jeton est
« a number that increases (e.g. incremented by the lock service) every time a client acquires the
lock », et « requires the storage server to take an active role in checking tokens, and rejecting
any writes on which the token has gone backwards ». Réponse d'antirez, « Is Redlock safe? »
(`http://antirez.com/news/101`) : un stockage qui n'accepte l'écriture que si le jeton dépasse tous
les précédents est **linéarisable**, donc capable d'un check-and-set. **Application aux fichiers
locaux (I)** : le système de fichiers ne vérifie rien. Le « stockage qui vérifie » est le hook (pour
les outils de Claude Code) et le script écrivain (pour tout le reste). Aucun des deux ne rend la
vérification **atomique avec l'écriture** (R3). Les deux postulats de Kleppmann tombent ici : le
client n'est pas de bonne foi (l'agent peut recopier un jeton), et le stockage ne fait pas de
compare-and-swap. D'où (b) plutôt que (a)/(e). Aucune source trouvée qui applique les fencing tokens
à des fichiers locaux écrits par des outils tiers (NT).

**Claude Code n'a pas de compare-and-swap propre (D).** Depuis 2.1.208, `Edit` s'applique à un
fichier modifié depuis sa lecture si `old_string` correspond encore. Depuis 2.1.228, `Write` peut
écraser un fichier jamais lu, sur les modèles récents. Rien n'empêche donc un `Write` d'écraser une
écriture concurrente ([T] § Edit tool behavior, § Write tool behavior). La doc ne dit pas non plus si
`Write` écrit par fichier temporaire puis rename (NT).

---

## R3 — Primitives d'atomicité, macOS (APFS) et Linux (ext4)

| # | Primitive | Garantie | Piège | Niveau / source |
|---|---|---|---|---|
| 3.1 | `mkdir d` | échoue `EEXIST` si le nom existe : création exclusive | ne publie qu'un dossier **vide** : le `meta` arrive après, et un lecteur peut voir le dossier sans lui | D [POSIX] mkdir ; I |
| 3.2 | `rename(2)` / `mv` sur le même volume | remplacement atomique : « a directory entry named new shall remain visible […] and refer either to the file referred to by new or old » | `EXDEV` entre deux volumes (`mv` copie puis efface : non atomique) ; **un dossier renommé sur un dossier vide existant le remplace sans erreur** (Python `os.replace` : « If dst is an empty directory, it will be silently replaced ») ; `mv` sans `-h` (BSD) / `-T` (GNU) **suit** un lien vers un dossier | D [POSIX] rename ; docs.python.org/3/library/os.html ; `driver-lock.sh:157-161` |
| 3.3 | `open(O_CREAT\|O_EXCL)` / Python `os.open` | « The check for the existence of the file and the creation […] shall be atomic » | — | D [POSIX] open |
| 3.4 | `link(2)` / `ln` (lien dur) / `os.link` | `EEXIST` si la cible existe : publie de façon **exclusive** un contenu **déjà complet** (motif Maildir : écrire dans `tmp/`, puis lier ou renommer) | `ln A B` dépose `B/A` si `B` est un dossier, ou un lien vers un dossier | D [POSIX] link ; `https://cr.yp.to/proto/maildir.html` |
| 3.5 | `ln -s` + `-h`/`-n` (`ln_atomic`) | création exclusive d'un lien | sous uutils, `-h` vaudrait `--help` et rendrait 0 sans rien créer (corpus, spec §6.1). La doc uutils de `ln` ne liste pas `-h` (NT). `ln_atomic` tente `ln -sh` **en premier** (`driver-lock.sh:170-171`), et la voie `acquire` ne relit pas le disque (`driver-lock.sh:495-504`) | C (corpus) / O (code) / I |
| 3.6 | `set -C` (noclobber) | POSIX.1-2024 impose une création atomique « as is done by `open()` […] O_CREAT and O_EXCL » | conformité de bash 3.2 (`/bin/sh` macOS) et de dash (`/bin/sh` Ubuntu) **non vérifiée** ici | D [POSIX] §2.7.2 ; NT |
| 3.7 | `flock(1)` | verrou consultatif, libéré par le noyau à la mort du processus | **absent de macOS** (`command -v flock` → rien, O) ; présent sous Linux (util-linux) | O |
| 3.8 | `lockf(1)` macOS | `flock(2)` en ligne de commande, `-t 0` = non bloquant | sans `-k`, **supprime** le fichier de verrou à la sortie (le man recommande `-k`) ; absent de Linux par défaut ; `shlock` est marqué « deprecated » | O (`man lockf`, macOS 26.5) |
| 3.9 | Python `fcntl.flock` | même sémantique **sur les deux OS** ; `python3` 3.14.5 sur le poste ; déjà requis par `dag.sh` et le hook | **consultatif** : `Write`/`Edit` de Claude Code, `sed -i` et `cat >` l'ignorent | O ; I |
| 3.10 | Durabilité | rename = atomique pour la **visibilité**, pas après une coupure de courant | macOS : `fsync` ne vide pas le disque, il faut `F_FULLFSYNC` (`man 2 fsync`) ; macOS `renamex_np(RENAME_EXCL)` / Linux `renameat2(RENAME_NOREPLACE)` n'existent pas en shell ni dans la stdlib Python | O ; NT |

**Cible CI.** `ubuntu-latest` = **Ubuntu 24.04**, GNU coreutils
(`actions/runner-images` README, lu le 2026-10-12). L'image 26.04 existe déjà et liste
`coreutils 9.5-1ubuntu2+0.0.0~ubuntu25`. Ce suffixe *ressemble* au paquet de transition vers uutils,
mais ce n'est **pas vérifié**. Il faudra le mesurer avant la bascule de `-latest`, puisque le piège
3.5 en dépend.

**« Écrire dans un fichier temporaire puis renommer » ne règle pas le lost update (I).** Le motif
supprime la lecture déchirée. Mais deux lecture-modification-écriture concurrentes donnent toujours
« le dernier gagne ». Pour s'en défaire, il faut soit l'exclusion mutuelle autour de
lecture→vérification→rename, soit un compare-and-swap. Or POSIX n'a pas de rename conditionnel au
contenu.

**Compare-and-swap de génération sans `flock` (I, à partir de 3.1–3.4).**
1. **Prendre** : `n` = plus haute génération visible. Puis `mkdir gen-<n+1>` : un `EEXIST` signifie
   « perdu », on relit et on recommence. Puis écrire le `meta` dans le dossier. Un lecteur traite un
   `meta` absent comme une prise en cours, comme le correctif H2 de `driver-lock.sh`. **Ne jamais**
   publier par `rename` d'un dossier préparé (3.2). Variante qui publie un contenu complet :
   `os.link(tmp, gen-<n+1>)` sur un **fichier**, avec `EEXIST` comme refus.
2. **Relire le disque** et exiger que la plus haute génération soit la nôtre, jamais le seul code de
   sortie (spec §6.1). Une génération plus haute arrivée entre-temps signifie que l'on est déjà
   dépassé, et c'est correct.
3. **Écrire un fichier protégé** : vérifier « ma génération est la plus haute », puis faire le
   rename. Entre les deux, une fenêtre TOCTOU reste ouverte. Pour les écrivains **qui coopèrent**
   (scripts, `dag.sh`, le hook lui-même), on la ferme par `fcntl.flock` sur un fichier voisin tenu
   le temps de la vérification et du rename. Le verrou est libéré par le noyau si l'écrivain meurt,
   donc il n'y a jamais de verrou périmé à récupérer. Pour `Write`/`Edit`, le hook ne peut pas tenir
   un verrou jusqu'à l'écriture, puisque son processus se termine avant l'outil. La fenêtre
   `PreToolUse` → écriture reste ouverte : la détection après coup passe par `PostToolUse` et D1
   (I).
4. **Sans aucun verrou** : chaque écriture produit un fichier de version neuf, `<f>.gen-<n+1>`, créé
   par `link` (création exclusive d'un contenu complet). La valeur courante est la plus haute version
   complète, et le chemin fixe n'est qu'une vue qui peut retarder. Il n'y a plus de lost update,
   mais il y a un coût : les consommateurs doivent résoudre « max(version) » (I).

**`dag.sh` (« à embarquer »).** `save()` (`plugin/conductor/scripts/dag.sh:117-121`) fait
`open(file, "w")` puis `json.dump`. Cela produit, en plus du lost update, une **lecture déchirée** :
un `load()` concurrent peut lire un JSON tronqué (I, sémantique de `O_TRUNC`). Le jeton monotone
**ne couvre pas** ce cas tel quel. Les écrivains du DAG (le manager, les `mark` pendant les vagues)
tiennent **le même** mandat, donc le même jeton, et le fencing ne rejette que les détenteurs
**périmés** : il ne sérialise pas deux détenteurs courants. Deux remèdes sont possibles (I) : un
`flock` autour de load→save avec temp + `os.replace` dans le même dossier ; ou un jeton **par
écriture**, c'est-à-dire un contrôle de concurrence optimiste où chaque `mark` prend `gen+1` et se
relance sur `EEXIST`. La référence de la ROADMAP est périmée : elle cite `.planning/BACKLOG.md:74`,
alors que l'entrée est à **`.planning/BACKLOG.md:169`** (O).

---

## R4 — Point d'accroche de G2′ sur 2.1.296

| Candidat | Bloque ? | Ce qu'il voit | Trous |
|---|---|---|---|
| **`PreToolUse` sur l'écriture du marqueur de clôture** (`Write`/`Edit`/`NotebookEdit` de `CLOTURE.md` ou `SUMMARY.md`, comme G3/G4) | **Oui** : `deny` en exit 0 (R46). **Nouveau en 2.1.295** : `onFailure: "block"` transforme un script absent, un exit ≠ 0/2, un timeout ou un JSON invalide en blocage | `file_path`, contenu, `agent_id`/`session_id`, `cwd` | clôture écrite par `Bash` non vue (`cat > CLOTURE.md`) ; anomalies `agent_id` (#90662) ; `onFailure` sans effet sur un hook `async` | D [H] § Block the action when a hook fails ; [CL] 2.1.295 |
| `Stop` / `SubagentStop` | « Bloque » = **relance** l'agent, pas de refus d'écriture ; plafond 8 remis à zéro par chaque outil (R461 § 3.4) ; **`onFailure` sans effet** sur ces événements | pas de chemin ; `last_assistant_message` | ne fait que retarder une clôture déjà écrite ; boucle | D [H] ; R461 |
| `TaskCompleted` | Exit 2 seulement ; `onFailure` sans effet | `task_id`, `task_subject`, `agent_id` (≥ 2.1.290, « May be absent ») | **toujours absent par défaut** sur les modèles récents : la section « Task tool availability » est inchangée. Aucune entrée Task* dans [CL] 2.1.293–2.1.296 | D [T] § Task tool availability ; [CL] |
| `PostToolBatch` | Oui : « Stops the agentic loop before the next model call » | lot d'appels résolus | n'est pas lié à la clôture ; arrive après l'écriture | D [H] (tableau exit 2) |
| Hook git `pre-commit` (hors Claude Code) | Oui, sur le commit | diff réel, quel qu'en soit l'auteur (Bash, cron) | `--no-verify` ; ne voit que ce qui est commité ; hors du hook central | I |

**« Ce qui a bougé ».** Trois sources, aucune complète seule (I) :

- **Empreintes** (sha256) des fichiers du lab prises **à la prise du bail**, puis comparées au moment
  de la clôture. C'est la seule source qui voie `Bash` et un cron, mais elle ne voit que l'ensemble
  énuméré. Elle s'aligne sur la réconciliation par hash au `SessionStart` (P46-D-07).
- **`git diff --name-only <base>` + `git status --porcelain`** depuis un commit de base noté dans le
  `meta`. Cette source rate les fichiers ignorés par git, et la fusion `merge=union` lisse les
  collisions (spec §6.1 bis).
- **Journal D1 `FileChanged`.** Il donne une attribution indicative, mais pas d'auteur, il est sourd
  après un `cd` (#95440, toujours OPEN, maj 2026-10-09) et peut-être muet quand il est déclaré par
  plugin (#16288 OPEN).

Ensuite, « hors bail » = (empreintes ∪ diff) − chemins couverts par les générations détenues − ajouts
append-only (§6.2) − amendements.

---

## R5 — Écrivains hors session (cron, launchd)

- **Aucun hook ne voit un cron** (spec §6.3, D). Le motif qui reste est « l'écrivain vérifie »
  (I, combinaison de 3.1–3.9) :
  1. Le script prend une génération à son nom (`mkdir gen-<n+1>`, détenteur `cron:<label>`) ou lit
     la plus haute génération fraîche.
  2. Il prend `fcntl.flock` (ou `lockf -k -t 0` sur macOS, `flock -n` sous Linux) sur le fichier de
     verrou voisin.
  3. Il revérifie que sa génération est la plus haute, écrit dans un temporaire du même dossier,
     fait `os.replace`, puis relâche le verrou.
  4. Si sa génération est dépassée, il **se replie** : il n'écrit pas, journalise et sort avec un
     code ≠ 0.

  Le jeton rejette le process réveillé en retard (§6.1 bis) seulement si le script **relit** l'état
  au moment d'écrire, et non au réveil.
- launchd et cron n'apportent aucune sémantique de verrou. `lockf(1)` (macOS) et `flock(1)` (Linux)
  sont les seuls enveloppeurs natifs, et ils diffèrent d'un OS à l'autre (O, 3.7–3.8). Aucune source
  documentée sur la vérification d'un jeton de bail par un job launchd (NT).
- **`FileChanged` (rappel, non refait)** : il voit une écriture extérieure **si une session est
  ouverte** et que le chemin est dans la liste surveillée. Il ne peut rien bloquer, ne nomme pas
  l'auteur, et devient sourd après un `cd` (R46 § 3.1, 3.3, 3.6, 3.8). Un cron qui tourne à 05:44
  sans session n'existe que pour la réconciliation par hash au `SessionStart` (P46-D-07).

---

## Ce qui change par rapport à 46/46.1

| Point | 46 / 46.1 | 2.1.296 (2026-10-12) | Source |
|---|---|---|---|
| Fail-open d'un `PreToolUse` (exit 1, 127, timeout, JSON invalide) | « sans réglage possible » (spec §5.1-2) | **Réglable** : `onFailure: "block"` (≥ 2.1.295) sur un hook `command`/`http`. Sans effet sur `Stop`, `SubagentStop`, `TaskCompleted`, `TeammateIdle` et sur les hooks `async` | [H] ; [CL] 2.1.295 |
| `agent_id` sur `TaskCreated`/`TaskCompleted`/`TeammateIdle` | champ commun | garanti **≥ 2.1.290**, « May be absent » | [H] |
| `TaskCompleted` par défaut | absent sur les modèles récents | **inchangé** | [T] |
| `session_id` d'un sous-agent = celui du parent | cité par la spec (#76726) | toujours non documenté ; #76726 OPEN ; mesuré sur 2.1.246 (#84701) | issues |
| Identité d'agent incohérente | #89555 (SubagentStop) | **+ #90662** (`PreToolUse` sous un autre `agent_id`) | #90662 |
| `FileChanged`, `SubagentStop`, `SubagentHandback` | — | aucune entrée de changelog de 2.1.293 à 2.1.296 ; #95440 et #99171 OPEN | [CL] ; issues |
| Diagnostic | — | 2.1.296 : `--debug` journalise commande, plugin, issue et durée des hooks, utile pour le canary | [CL] 2.1.296 |
| Compare-and-swap natif de `Write`/`Edit` | non étudié | **aucun** (règles assouplies en 2.1.208 et 2.1.228) | [T] |

---

**Bloc typé**

```
{statut: passed,
 findings: [
  {id: F1, constat: "agent_id/agent_type présents dans le PreToolUse d'un sous-agent depuis 2.1.69 ; session_id = parent (non documenté, #76726/#84701) ; aucune variable n'expose agent_id à Bash. Le bail se lie à agent_id, sinon session_id, via un registre lu par le hook ; la prise se fait par le sous-agent lui-même.", source: "[H] § Common input fields ; [CL] 2.1.69 ; #76726 ; #84701 ; [EV]", action: ask-user},
  {id: F2, constat: "Un jeton présenté par l'agent (contenu, argument) est forgeable par recopie ; seule la voie registre ↔ identité tient ; updatedInput permet d'injecter l'identité dans Bash mais impose allow/ask.", source: "Kleppmann 2016-02-08 ; antirez/101 ; [H] § PreToolUse decision control", action: ask-user},
  {id: F3, constat: "Le jeton monotone ne couvre pas le lost update de dag.sh (même mandat, même jeton) ; il faut flock + os.replace, ou un jeton par écriture ; save() produit aussi une lecture déchirée.", source: "plugin/conductor/scripts/dag.sh:117-121", action: ask-user},
  {id: F4, constat: "G2′ : seul PreToolUse sur l'écriture du marqueur de clôture refuse réellement ; onFailure:block (2.1.295) le rend fail-closed ; TaskCompleted inchangé (absent par défaut) ; Stop/SubagentStop ne refusent pas une écriture.", source: "[H] § Block the action when a hook fails ; [CL] 2.1.295 ; [T]", action: ask-user},
  {id: F5, constat: "onFailure:block contredit la spec §5.1-2 (« sans réglage possible ») pour PreToolUse : à intégrer aux gates G1/G3/G4/G5/G6 (hors périmètre 47).", source: "[CL] 2.1.295 ; spec l.397-405", action: ask-user},
  {id: F6, constat: "ROADMAP gouvernance l.308 cite .planning/BACKLOG.md:74 ; l'entrée dag.sh est en l.169.", source: ".planning/workstreams/gouvernance/ROADMAP.md:308 ; .planning/BACKLOG.md:169", action: no-op},
  {id: F7, constat: "ln_atomic tente `ln -sh` en premier et acquire ne relit pas le disque ; sous uutils (-h = help, corpus) le verrou serait annoncé sans exister. CI actuelle sur 24.04 GNU ; image 26.04 à mesurer.", source: "driver-lock.sh:170-171, 495-504 ; spec §6.1 ; actions/runner-images README", action: ask-user},
  {id: F8, constat: "Pas de flock(1) sur macOS ; lockf(1) présent (macOS 26.5) ; python3 fcntl.flock est la seule primitive commune ; noclobber atomique selon POSIX.1-2024, non vérifié pour bash 3.2 et dash.", source: "O (command -v, man lockf) ; [POSIX] §2.7.2", action: no-op}
 ],
 noeuds_debloques: ["cadrage-47"]}
```
