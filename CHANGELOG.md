# Changelog — vibeflow-os

Historique des versions du **repo** (canon unique — les deux README n'en affichent qu'un
extrait récent et pointent ici). Chaque module a par ailleurs son propre `CHANGELOG.md`
sous `plugin/<module>/`. Rappel : toute release = un tag git annoté `vX.Y.Z`
(`scripts/check-release-tag.sh`).

## [v2.57.1] — 2026-08-27

**Le ré-armement de l'isolation worktree a été mesuré, puis refusé en connaissance de cause — la
Phase 35 se clôt en démontrant qu'il ne faut pas faire ce pour quoi elle avait été ouverte.**
Modules `conductor` v1.28.0 → v1.28.1 et `dev-orchestrator` v2.19.0 → v2.19.1. Aucun comportement
machine ne change : cette release distribue une doctrine et répare deux gardes.

- **Prémisse renversée.** La phase était flottante en attente d'un fix amont ; il est arrivé
  (`open-gsd/gsd-core#3302`, releasé en 1.11.0 et installé). La mesure a tranché **contre** le
  ré-armement plutôt que de le déclencher mécaniquement sur la retombée de la précondition.
- **Sûreté acquise, efficacité nulle.** Le moteur ne casse plus en silence : sur un lab sans
  réglage, un HEAD divergent fait **dégrader en séquentiel** avec message explicite, au lieu de
  faire atterrir le worker sur une branche sans les fichiers de son mandat. Mais une mission
  d'équipe travaille **toujours** sur une branche dédiée (ADR-059), donc HEAD diverge **toujours**,
  donc l'armement dégraderait **systématiquement** : zéro parallélisme gagné, un avertissement par
  dispatch. Le seul levier qui le rendrait effectif (`worktree.baseRef: "head"`) est l'anti-pattern
  de la régression #38 — le moteur lui-même le documente comme *« silences this check without
  verifying the base »*.
- **Conséquence doctrinale** (`conductor/references/team-kernel.md`) : `isolation` reste une
  **décision de dispatch** du manager, jamais une propriété de frontmatter — déclarée, elle devient
  inconditionnelle et retire l'arbitrage au seul agent qui a le contexte pour le rendre. Les deux
  paliers de garde restent en place, désormais avec leur justification écrite.
- **Contrainte opérationnelle nouvellement consignée** : la garde d'isolation refuse les commandes
  composées (`&&`, heredocs) — *« too complex to verify that it stays inside the worktree »*. Tout
  mandat dispatché en worktree doit prescrire Write/Edit et **un seul verbe git par appel Bash**,
  faute de quoi l'échec sera imputé à tort au fix amont.
- **Ledger** : WKTR-01 requalifié `[~]` — son énoncé n'était pas satisfiable honnêtement
  (`ensure-deps.sh` ne peut pas attester une clé de settings qu'il ne doit pas écrire) ; l'attester
  quand même aurait produit une couverture déclarée sans couverture effective. WKTR-02 acquis.

**Deux gardes rouges sur `main` réparées au passage** : `check-machine-paths` (un chemin absolu de
machine introduit dans un document de recherche par `f170ee0`) et `test-dev-orchestrator` T28-F
(l'index de capabilities versionné avait dérivé du moteur depuis la montée en 1.11.0).

**Défaut trouvé dans la preuve censée autoriser le ré-armement** : la mesure du 2026-08-23 était
**dégénérée sur son point décisif** — branche jetable et `main` au même SHA, rendant « fork depuis
HEAD » et « fork depuis la branche par défaut » indistinguables, alors que la base de fork est la
cause immédiate de #38. Le document a été amendé plutôt que laissé passer pour valide. Le vert
obtenu localement était par ailleurs **contaminé** par un `worktree.baseRef: "head"` présent dans
le `settings.local.json` de ce dépôt — retiré depuis : il faisait mentir tout test d'isolation joué
ici.

## [v2.57.0] — 2026-08-23

**Les exigences survivent désormais à la clôture d'un jalon : le ledger n'est plus effacé puis
régénéré de zéro, et une exigence ne peut plus disparaître sans trace.** Phase 18 (3 plans),
PR #51, module `dev-orchestrator` v2.18.0 → v2.19.0.

- **LEDG-01** — `restore-requirements-ledger.sh` : post-traitement pur, lecture seule stricte sur
  l'archive, n'écrit que sous `--write`, refuse d'écraser un ledger vivant sauf `--overwrite-live`
  (avec sauvegarde `.bak-<jalon>` préalable). Rejeu sur la clôture réelle d'`agentique-v1.0` :
  136 IDs → 93 garanties + 42 reportées + 1 caduque = 136/136, corps verbatim à l'octet (D-18-13).
- **LEDG-02** — `check-requirements-survival.sh` : lecteur/diff en détection d'absence, jamais un
  régénérateur. Quatre signaux `[ledger-*]`, trois issues QUAL-01 dont l'imparsable bruyant.
- **D-18-14** — doctrine dans `plugin/dev-orchestrator/AGENT.md` : les archives
  `milestones/*-REQUIREMENTS.md` sont des instantanés, `.planning/REQUIREMENTS.md` la seule source
  vivante. Zéro objet neuf dans le socle.

**Défauts trouvés par la vérification, aucun par les tests de son auteur** : 86 exigences sur 136
perdues en silence (vocabulaire `Complete|Pending` face à une archive sans aucun `Pending`) ; une
correction par case à cocher écartée sur mesure (sur un jalon clos tout est coché, le signal ne
discrimine rien) ; trois défauts de sécurité prouvés par exécution puis 7 vecteurs adversariaux
sans contournement ; portabilité CRLF falsifiée dans les deux sens ; deux verts vides (un
`exit 0` sur répertoire inexistant, 13 suites mesurées sur 68 masquant une CI rouge).

**68 suites** vertes en local et en CI.

## [v2.56.0] — 2026-08-17

**Un stall de mission ne survit plus au prochain geste d'une session vivante — et les
notifications, désormais éteintes par défaut, ne partent que quand elles comptent : fin de phase
et fin de milestone, sur l'app Claude.** Phase 33 (5 plans) + son annexe notifications (2 plans),
PR #49 et #50. `conductor` v1.28.0, `dev-orchestrator` v2.18.0.

### Le watchdog (WTCH-01..04)

- **Deux horloges sur le même battement** (D-33-A) : le meta du lock porte `heartbeat_epoch`
  (vivacité) ET `progress_epoch`, écrit par `dag.sh mark`. Un seul mécanisme, un seul fichier,
  deux consommateurs — jamais un second canal.
- **Stall par ABSENCE de battement** : vivant mais progrès figé au-delà de `STALL_WINDOW`
  (900 s, strictement sous le TTL de 1800 s — D-33-E) = STALL ; deux horloges mortes = abandon.
  La preuve du cas « vivant mais bouclant » est la boucle RÉELLE (D25 : `heartbeat` répété sans
  `mark`, verdict constaté sans toucher au meta). Et elle s'est validée toute seule : **le
  watchdog a détecté en production le stall de sa propre mission** pendant l'intégration
  (heartbeat frais à 135 s, progrès figé à 1303 s) — signature observée, non forgée. Le watchdog
  signale et suggère, **ne tue jamais** (ADR-031).
- **Point de contrôle au geste `mark`** (D-33-F) : lecture + signal stderr best-effort, jamais
  bloquant — une session ouverte 8 h voit le stall sans redémarrer. Ce signal **n'est jamais
  gaté** par le toggle de notifications : couper le confort, jamais l'alerte.
- **Armement gaté** : hooks et notify passent par le gate armement↔précondition (PORT-05 en CI),
  jamais un settings local (leçon #38). Doctrine amendée : cadence de heartbeat indépendante des
  transitions de nœud (`mission-flow.md`, `vf-dev-manager.md`).
- Le goal a été **amendé sur mesure** : les hooks Claude Code sont strictement événementiels
  (`asyncRewake` ne réveille qu'une session déjà active, aucune horloge plateforme) — « un stall
  ne survit pas au prochain geste d'une session VF vivante », limite assumée par écrit (machine
  sans session = silence possible). Zéro démon système, sur un milestone Windows-first.

### Les notifications (WTCH-03 amendé, D-33-H)

- **Défaut OFF** : aucune notification tant qu'elle n'est pas activée. Préférence par
  **fichier-sentinelle** (patron `stop-notify`) sous `XDG_CONFIG_HOME`, scope **machine** — zéro
  JSON, zéro hook neuf, donc zéro exposition au bug d'idempotence de `merge-hooks`.
- **Skill `/vf-notify`** (`on` / `off` / `status` / `test`), installé avec `conductor`.
- **Jalons via l'app Claude** — `Pattern H` : `PushNotification` **n'est pas fourni aux
  sous-agents** (mesuré par appel réel, pas lu : managers et workers ne peuvent structurellement
  pas pousser — décalque du précédent `AskUserQuestion`). Les jalons remontent donc par relais
  `SendMessage(main)`, la session principale émettant le push. Couvre **les deux** jalons (fin de
  phase ET fin de milestone), seul vecteur symétrique : `ship:post` dispatche lui-même un
  sous-agent et `gsd-complete-milestone` n'offre aucun point d'extension amont.
- **Fins de nœud de DAG** → toast OS via `notify.sh` quand activé, jamais sur `running` — le
  geste le plus fréquent. Le harness ne sert d'ailleurs rien quand l'utilisateur est présent
  (`user_present`) : comportement assumé et documenté plutôt que dupliqué.
- `notify.sh` reste best-effort fail-open silencieux ; Windows dès la v1 : WinRT sous
  `powershell.exe` 5.1 — jamais `pwsh` (pas d'assemblies WinRT dans Core), jamais `osascript` en
  dur (il sort 0 en jetant la notification quand la permission manque — un `exit 0` n'est jamais
  une preuve de délivrance). Chaîne testée par shims d'argv en CI ; recette humaine Win10/11 en
  condition de clôture.

### La méthode

**Quatre prémisses de brief invalidées par la mesure**, dont deux structurantes :
`PushNotification` absent des sous-agents, et `VF_NOTIFY_FORCE_CHANNEL=none` qui **n'était pas un
kill-switch** (il silenciait par accident de la branche `*)`, sans aucun test). Deux tours de
plancheck externe sur le watchdog (23 puis 10 bloquants là où le checker interne rendait 0 —
quatrième phase d'affilée), deux défauts **reproduits par exécution** (`mark-progress` effaçait
`step` ; le sous-contrôle de stall, placé après trois sorties anticipées, ne tournait jamais sur
machine saine — vert-à-vide par fixtures `mkdir -p`), et deux bloquants trouvés **par mesure et
pas par les tests** : `notify.sh` puis `check-guard-health.sh` commités en 644, leur échec avalé
par un `try/except` — le mode de défaillance exact que la phase combat. Sur l'annexe : un module
non bumpé aurait laissé la doctrine **n'atteindre jamais un lab**, deux bloquants ont été
**introduits par les corrections elles-mêmes**, un `$HOME` non gardé sous `set -u` **falsifiait
la garantie de fail-open** qu'on venait d'introduire, et le cas N17 — celui qui prouve le défaut
OFF — était **aveugle 17 % du temps** (25/30 → 30/30 après durcissement). Note de terrain versée
au dossier : **huit workers arrêtés en silence pendant la mission même** — l'argument empirique
du watchdog. Reliquats tracés au BACKLOG : `save()` de `dag.sh` sans verrou ni écriture atomique,
gate d'observance de la doctrine.

**Suites** : `dag.sh` 99 → 156 cas, `driver-lock` 183, `notify.sh` né, `check-guard-health` 78,
`vf-notify` né — **66 suites** vertes en local **et** CI verte.

## [v2.55.1] — 2026-08-17

**Hotfix : sous Windows, l'engine écrivait des hooks à chemin mort — et `|| true` avalait
l'erreur, donc les gardes ne tournaient plus sans que rien ne le dise.** Signalé par un testeur
Windows le 2026-08-17, mesure faite sur le même `.claude/settings.json` avant et après update :
26 entrées en forme shell / 0 chemin corrompu → 21 entrées / **20 corrompues**.

### La cause

Le préfixe de scripts transitait vers Python par **variable d'environnement**. Sous Git Bash, le
runtime MSYS2 réécrit les variables dont la valeur ressemble à un chemin POSIX quand la cible est
un binaire Windows **natif** — précisément le Python que notre propre message d'erreur recommande
d'installer depuis python.org. Le séparateur était remplacé par la racine MSYS :

```
"$CLAUDE_PROJECT_DIR"/.claude/scripts  →  "$CLAUDE_PROJECT_DIR"C:/Program Files/Git/.claude/scripts
```

Ce chemin partait tel quel dans `settings.json`. Les entrées finissant par `|| true`, `bash`
signalait l'erreur et `|| true` l'avalait : garde muet — le mode de panne que la doctrine de ce
repo nomme depuis LOCK/QUAL-01, un garde-fou en panne étant pire qu'un garde-fou absent.

Ce n'est **pas** une régression de v2.55.0 : la ligne fautive date de v2.14.0. Ce que les Phases
30→32 ont changé, c'est le nombre d'entrées qui empruntent ce chemin.

### Livré

- **Transport par fichier** (`WIN-PATHCONV`) : le préfixe passe par un fichier temporaire, dont le
  contenu n'est jamais réécrit par le runtime — seuls `argv` et l'environnement le sont.
  `FRAGMENT`, `SETTINGS`, `SETTINGS_LOCAL` et `BASH_ABS` restent **délibérément** des variables :
  ce sont de vrais chemins à ouvrir ou à exécuter, la conversion y est utile. `PREFIX` était le
  seul passager à n'être pas un chemin mais un littéral à injecter dans du JSON.
- **Garde-fou** : un préfixe portant la marque d'une conversion — littéral shell-quoté suivi
  d'autre chose que `/`, ou lettre de lecteur greffée en milieu de chaîne — arrête le merge avec
  un diagnostic nommant MSYS2, et **rien n'est écrit**. Écrire vingt hooks morts en silence n'est
  plus un comportement atteignable.
- **`docs/WINDOWS-HOOKS-PATHCONV.md`** : protocole opératoire adressé à l'assistant de la machine
  touchée — mesure avant toute écriture, marqueur `WIN-PATHCONV` pour situer sa version,
  réparation locale (simulation par défaut, `APPLY=1` pour écrire, sauvegarde), vérification par
  exécution réelle, escalade en issue GitHub sinon.

### Ce qui n'est PAS prouvé

La cause racine est **inférée**, pas constatée : aucune machine Windows n'était disponible, ici
comme pendant la Phase 33. Le motif du screen la recoupe exactement, racine MSYS comprise, mais la
confirmation tient à une mesure que seul le testeur peut produire (`sys.executable` pointant un
Python hors MSYS — étape 1 du doc). Le correctif est sûr indépendamment de ce verdict : le
transport par fichier ferme le vecteur, le garde-fou couvre les variantes non identifiées.

### Le chiffre de la méthode

**Deux faux verts, tous deux dans le travail de ce hotfix, tous deux attrapés en exerçant ce qu'on
venait d'écrire plutôt qu'en le relisant.** Le premier T25 polluait la variable `PREFIX` depuis
l'appelant et passait — sans le correctif aussi : `merge-hooks.sh` réinitialise cette variable en
interne, le test n'exerçait rien. Refait avec un shim `python3` qui réécrit l'environnement à la
manière de MSYS2, la seule couche où le bug vit. Le second était dans le doc de réparation : ses
deux motifs ignoraient l'échappement JSON (`\"$HOME\"C:`) et rendaient un « 0 à réparer »
faussement rassurant — rattrapé en rejouant le protocole entier sur un `settings.json` corrompu
reproduit, comptage et `APPLY=1` compris.

Tests de régression T24 (garde-fou : refus, exit 1, aucune écriture) et T25 (transport par
fichier). Matrice de mutation : garde-fou neutralisé → T24 mord ; transport annulé → T25 mord ;
les deux ensemble — le cas réel du testeur — les deux mordent. Suites : 36/36 `merge-hooks`,
19/19 `vibeflow-update`, 8/8 `gsd-cohabitation`.

## [v2.55.0] — 2026-08-17

**Le driver-lock cesse d'être déclaratif : les contournements constatés pendant agentique-v1.0
(commit et checkout concurrents sous lock) sont désormais bloqués à la source, et un lock
périmé ne se vole plus jamais en silence.** Phase 32 (7 plans), PR #46. `conductor` v1.26.0 +
5 bumps doctrine (dev-orchestrator, design-orchestrator, content-bundle, business-pilot-bundle,
growth-bundle).

### Livré

- **LOCK-01 — heartbeat séparé de la lease** : un manager vivant renouvelle son battement sans
  que le TTL monte ; `session_ids` et `generation` exposés, `lease_seconds` observable — un
  lock périmé ≠ une mission morte (constat du 2026-08-02, enfin fermé).
- **LOCK-02/03 — `guard-driver-lock.sh`** (neuf, 80 cas) sur `PreToolUse` matcher
  `"Bash|Write|Edit"` : commit ET checkout/switch de branche sous le lock d'autrui refusés
  AVANT que git ne tourne ; la voie `Write|Edit` bornée à `.planning/` (l'incident I2 réel
  passait par les outils natifs, pas par Bash) ; le motif de refus est rendu au modèle mot
  pour mot avec la commande exacte de reprise (`reclaim`/`takeover`) et les échappatoires
  nommées (worktree, marqueur d'override explicite) ; le détenteur passe toujours. Résistant
  au chaînage par saut de ligne, aux heredocs suivis d'une commande, aux options globales
  `git -C`/`-c`, au quoting — chaque garde prouvée rouge sous mutation. L'entrée naît de
  `merge-hooks`, la commande vit en `--settings-local` : un chemin machine ne voyage jamais.
- **LOCK-04 — takeover explicite** : `acquire` ne récupère plus jamais un lock périmé — refus
  `stale-requires-takeover` avec hint in-band ; verbes `takeover`/`reclaim` distincts, journal
  append-only, mutex sous `trap` ; le trou legacy du double-détenteur (nominal sur Git Bash
  Windows sans privilège symlink) fermé par garde d'existence, T12 assertant l'owner
  **effectif** sur disque et non le JSON rendu.
- **LOCK-05 — trailer `Fence:`** sur les commits de mission — « quel commit sous quel mandat »
  auditable ; convention écrite dans `mission-flow.md`, le chemin que les managers lisent
  réellement.
- **QUAL-01 — hook doctor `SessionStart` générique** (extension de périmètre assumée, arbitrée) :
  les 26+ entrées du parc écrivaient des marqueurs de santé qu'AUCUN consommateur ne lisait —
  le « bruyant non bloquant » n'existait pas. Le doctor lit les marqueurs de tout le parc,
  silence nominal 0 octet, signal injecté en contexte de session — mesuré réellement bruyant.
- **Doctrine resynchronisée** (arbitrage Samuel : synchronisation complète, pas seulement le
  hint) : 7 fichiers dans 4 modules tiers — aucun agent manager ne documente plus l'ancien
  contrat d'acquisition.

### La recherche avant le plan

Les deux research flags du roadmap ont contredit deux prémisses écrites, consigné sur disque
(`32-SPIKE-reference-transaction.md`, `32-REJEU-contournements.md`) : le hook git
`reference-transaction` est **inutilisable pour bloquer** (aveugle avant git 2.46, wedge
`rebase` en refusant son propre `--abort`, casse `worktree add` — l'échappatoire prescrite —,
contournement `hooksPath` que quatre de nos propres scripts utilisent) — le blocage est porté
par le guard PreToolUse à la place ; et il n'y avait pas 2 contournements mais **4 incidents
réels sur 3 gestes**, dont un passé par Write/Edit — tous rejoués en cas de test rouges sous
mutation dans les deux sens.

### La méthode

Troisième phase d'affilée : deux vérificateurs internes ont rendu « PASSED, 0 blocker », les
juges frais ont trouvé **9 bloquants au plan** puis **1 au code** (le guard tronquait au
premier `<<` — un heredoc suivi d'un `git commit` passait en silence : l'incident I4 rouvert
avec tous les tests verts). Dette tracée plutôt que corrigée à chaud : idempotence
cross-matcher de `merge-hooks.sh` (`CONCERNS.md`, deux entrées même script/même événement se
purgent l'une l'autre — contourné par le matcher combiné, précédent existant). Checkpoint
humain 32-03 validé sur pièces ; **ce dépôt n'est pas armé — l'armement réel des labs passe
par la release du module `conductor` posée par `/vf-update`.**

**Suites** : `test-driver-lock.sh` 151 assertions, `test-guard-driver-lock.sh` né (80 cas),
`test-check-guard-health.sh` né (le doctor) — **64 suites** vertes en local **et** CI verte
(`71b6cfd`).

## [v2.54.0] — 2026-08-16

**L'engine d'install devient prévisible : chaque pose est tracée fichier par fichier dans un
manifeste, et `--dry-run` montre exactement ce qui sera écrit avant d'écrire quoi que ce soit.**
Phase 31 (8 plans, issue #20), PR #45.

### Livré

- **Manifeste de pose** : chaque install réelle écrit `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`
  (un chemin par ligne, relatif à la racine du scope, trié). `uninstall` et la convergence
  d'update lisent ce manifeste au lieu de reconstruire la liste depuis le cache — le trou
  historique que `retired-modules.txt` rattrapait en dur est fermé à la source (MANI-01/03).
- **`--dry-run`** sur `install` et `update` : plan fichier-par-fichier sur `stdout`
  (`[plan] + / ~ / -`, le format proposé par l'auteur de l'issue #20, repris tel quel),
  diagnostics sur `stderr`, **zéro écriture disque** — prouvé au grain du contenu disque (T10).
  Le plan et la pose sortent du **même chemin de code** : la dérive plan/pose est
  structurellement impossible, pas seulement testée après coup. Refus **bruyant** (`exit 1`)
  sur `uninstall`/`rollback`/`status`/`sync` — jamais un flag avalé en silence (T14).
- **`merge-hooks.sh` mode `plan`** : la prévisualisation du merge de hooks est rendue par le
  code du merge réel — pas de second chemin capable de dire autre chose que ce que la fusion
  fera (Tp1–Tp7, dont Tp3 : cible bit-à-bit inchangée après un `plan`).
- **Convergence d'update** : les fichiers disparus d'une nouvelle version sont retirés **avec
  sauvegarde préalable** et liste affichée (T17–T22) ; abstention totale et bruyante sur
  manifeste douteux (ligne vide, chemin absolu, `..`, illisible — T19) ; garde **physique**
  (`cd -P`/`pwd -P`, builtins POSIX — ADR-054 interdit le binaire `realpath`, pas la
  résolution physique, D-31-15) contre toute suppression résolvant hors de la racine du scope,
  y compris via un répertoire ancêtre symlinké (T18, testée sous mutation). `uninstall`
  applique les mêmes garde-fous et **ne désenregistre jamais un module dont il n'a pas su
  retirer les fichiers** (D-31-16, T29–T35).
- **Câblage skills** : `/vibeflow-install` (étape 5) et `/vf-calibrate` (étape 4) montrent le
  plan `--dry-run` avant le feu vert de pose — la demande exacte de l'issue #20.
- **Limites nommées** : trois sous-processus écrivains annoncent leur effet sans énumérer un
  contenu qui dépend de l'état vivant du lab (T12/T13) ; `docs/<module>/` apparaît au plan
  mais n'entre pas au manifeste (incohérence cwd pré-existante, figée par un cas de suite) ;
  dotfiles de sous-dossiers jamais copiés (comportement pré-existant gelé, pas corrigé).

### La méthode

Aucun vert auto-déclaré n'a tenu de toute la mission : le plan-checker interne rendait
« 0 bloquant » où deux relectures externes en trouvaient 11 ; la vérification md5 (262 fichiers
identiques) prouvait le chemin nominal pendant que la revue prouvait 4 régressions du chemin
d'échec — sous `set -e`, déplacer un appel en fin de `a && b` change sa sémantique d'échec
(D-31-13 : la tolérance se restaure explicitement et se prouve par injection de panne). Le
filet de non-régression est passé des 3 suites touchées à la découverte **complète** (le
pattern CI fait foi : 62 suites ; un `find` plus large comptait double via
`.claude/worktrees/`). 6 décisions consignées (D-31-11 → D-31-16), rapport de mission :
`.planning/missions/2026-08-16-phase-31-manifeste-dry-run.md`.

**Suites** : `test-manifest.sh` né (62 cas), `test-merge-hooks.sh` 34/34, `test-vibeflow-update.sh`
19/19 — **62 suites** vertes en local (bash 3.2 macOS) **et** CI verte (Linux/bash ≥5).

## [v2.53.1] — 2026-08-16

**Hotfix : les hooks en forme exec livrés en v2.53.0 étaient morts sur toute install en scope
user — `"$HOME"` littéral dans `args`, jamais expansé puisque la forme exec s'exécute sans
shell.** Signalé sur pièce dès la première session post-update : 6 `SessionStart:startup hook
error … No such file or directory` (les 5 signaux dev-orchestrator), plus l'entrée PreToolUse
`guard-file-size.sh` de software-architecture — la porte Iron Law 300L — morte **silencieusement**
de la même cause.

### Cause racine

`scripts_prefix_for_scope()` (vibeflow-update.sh) émet des préfixes shell-quotés (`"$HOME"`,
`"$CLAUDE_PROJECT_DIR"`) conçus pour la forme shell, où le shell qui exécute la commande les
expanse. La forme exec (`command` + `args`, contrat PR #29 §5) s'exécute **sans shell** : le
harness ne substitue dans `args` que ses propres placeholders (`${CLAUDE_PROJECT_DIR}`,
`${CLAUDE_PLUGIN_*}` — doc hooks officielle, vérifiée avant le correctif), et `$HOME` n'en fait
pas partie — le littéral restait donc tel quel dans le chemin passé à bash. Le trou de
couverture qui l'a laissé passer : toutes les suites exerçaient la forme exec en scope
**projet** (settings.local.json, T10-T12 de test-vibeflow-update.sh), jamais en scope user avec
`"$HOME"`.

### Livré

- **`merge-hooks.sh`** : dérivation d'un préfixe exec-safe pour `args` (`exec_safe_prefix`) —
  `"$HOME"` → chemin absolu résolu à l'install (légitime : la cible user `~/.claude` est
  par-machine, aucune fuite via git possible) ; `"$CLAUDE_PROJECT_DIR"` → placeholder harness
  `${CLAUDE_PROJECT_DIR}` (l'unique mécanisme de substitution que le harness applique aux args,
  portable et committable). La forme shell garde le préfixe tel quel.
- **Garde-fou** : un littéral shell-quoté résiduel (`"$HOME"` ou `"$CLAUDE_PROJECT_DIR"`) dans
  des `args` fait désormais échouer le merge — le bug ne peut plus se reproduire en silence.
- **Tests** : T22 (scope user → chemin absolu, aucun littéral résiduel) et T23 (scope projet →
  placeholder harness dans args, forme shell inchangée sur fragment mixte) ; T8 mis à jour.
  `test-merge-hooks.sh` 27/27, `test-vibeflow-update.sh` 19/19.

### Réparation du parc

Relancer `/vf-update` avec cette version re-merge les fragments et **remplace** les entrées
mortes (dédup par basename) — aucune intervention manuelle dans les settings.

## [v2.53.0] — 2026-08-16

*(Entrée rétro-remplie le 2026-08-16 avec la release v2.53.1 : la v2.53.0 était sortie avec les
deux README à jour mais sans son entrée dans ce canon.)*

**Une install VibeFlow sous Windows pose désormais des hooks qui fonctionnent — le substrat des
hooks est réécrit une fois pour toutes, et les deux latences externes du milestone sont parties
au jour 1.** Phase 30 (9 plans, 4 vagues + chirurgie), PR #43. **Livré** : `merge-hooks.sh`
apprend la **forme exec** (`args`) — substitution, dédup cross-forme ET cross-cible, `remove`
balayant les deux cibles, compat descendante intégrale avec la forme shell que porte le parc
installé ; **routage borné par scope** : seules les entrées portant un chemin machine
(`{{VF_BASH}}`) vont dans `settings.local.json` ; lib partagée `plugin/_internal/lib/vf-portable.sh`
conforme au contrat d'interface de la PR #29 ; codes de sortie normalisés sur tout le parc
(12 scripts, 0 = silence à la frontière harness, traduction conditionnée à `--hook`), 26 entrées
de hooks inventoriées et classées advisory/bloquante (`docs/HOOKS-CONTRAT-SORTIE.md`) ; les 5
entrées de la polarité dev migrées en forme exec (ADR-071) ; `check-hook-paths.sh` en `bash` nu,
tolérant au BOM ; le scope local gitignore `.claude/settings*.json`. **Gestes jour 1** : RFC
upstream `open-gsd/gsd-core#3556` et veille de release gsd-core >1.10.0 active. Aussi :
`vf-dev-manager` v2.17.2 — les gates humains escaladent en vivant vers la session principale
(`SendMessage`). Modules : 7 bumpés. **61 suites** vertes. Détail complet : ligne `v2.53.0` des
deux README et rapport de mission Phase 30.

## [v2.52.0] — 2026-08-15

**La mémoire du framework cesse de tourner à vide : les registres sont instanciés, cloisonnés
par projet, et couverts par la promesse de chaque scope.** Diagnostic remonté du terrain (« ma
logique mémoire n'est pas là depuis que j'ai installé le module dev »), mesuré sur pièce en dépôt
vierge : `consolidator` s'installait entier — hooks câblés, guards en place, 5 gabarits déposés —
mais **aucun script ne les instanciait** : `.claude/memory/` n'existait pas, le lab échouait son
propre gate, et la CI le masquait (`--allow-empty` convertissait rc=1 en rc=3 « indéterminé »,
puis acceptait rc=3).

### Livré

- **`seed-registres.sh`** (consolidator v1.9.0) : instancie les registres canon manquants depuis
  les gabarits. Appelé par un 4ᵉ hook post-install nommé **et** par `sync_module_governance` —
  ce second point d'appel rend le correctif transparent à l'`update`, y compris quand la version
  du module n'a pas bougé (le chemin « déjà à jour » ne repasse jamais par `install_module`).
  **Un utilisateur touché reçoit donc sa mémoire au prochain `/vf-update`, sans aucun geste** —
  prouvé par rejeu du scénario complet : lab v1.8.1 sans registres, contenu utilisateur ajouté à
  la main, `update --all` → 4 registres manquants créés, le fichier du client **intact** (vérifié
  par empreinte), le nouveau hook mergé dans son `settings.json` existant.
- **Contrat non destructif sans exception** : le seeder ne sait que créer ce qui manque — les
  registres sont append-only et portent l'historique réel du lab. Vérifié par empreinte, pas par
  présence de fichier. Data-driven (`*-template.md` → `<NOM>.md`, aucun nom en dur). Validé sous
  bash 3.2 (macOS), y compris le cas « gabarits vides + `set -u` ».
- **Scope `user` : chaque projet a SA mémoire.** Trou structurel : les scripts y vivent dans
  `~/.claude/`, donc le seed d'install remplissait la mémoire du compte pendant que le lint et
  les guards résolvent `.claude/memory` **relativement au cwd** — home rempli, tous les projets
  vides. Une install ne peut pas connaître les projets à l'avance ; l'ouverture de session, si :
  mode `--project` + hook `SessionStart`, garde de lab (`.planning/` ou `.claude/` requis — un
  dépôt git nu n'est jamais semé), échappatoire `VF_NO_AUTO_SEED`, cloisonnement prouvé (deux
  labs, deux mémoires, zéro fuite).
- **Scope `local` : SCOPE-04 tenu jusqu'aux registres.** L'engine gitignorait ses propres
  artefacts mais laissait les registres semés apparaître en untracked — la promesse « rien ne
  sera committé » s'arrêtait aux fichiers qu'il copiait lui-même. `gitignore_add_paths` couvre
  désormais `.claude/memory/` (sélecteur = présence du seeder, data-driven), cas T3b.
- **`consolidator` passe `mandatory`** : il n'arrivait que par l'arête indirecte
  `conductor → validator` — retirer `validator` emportait silencieusement la mémoire.
  `ensure_mandatory_baseline` rattrape les labs où il manque.
- **`memory_bridge.enabled` → `true`** (planning-core v2.6.1) — déclaratif, dit sans détour :
  aucun script ne lit cette clé, le pont est appliqué par le SKILL.
- **MemPalace : refusé par écrit, avec la mesure.** Ni CLI ni MCP disponibles ; l'activer
  insérerait 7 étages qui échouent à chaque phase. Apport propre (recall sémantique)
  complémentaire, déclencheur de reprise consigné dans le CHANGELOG du module.
- **CI** : baseline du job « lab frais » dérivée des `role=mandatory` du catalogue (elle codait
  `conductor` en dur), `--allow-empty` retiré, `seed-registres.sh --check` ajouté.

Modules : `consolidator` v1.9.0, `planning-core` v2.6.1. **55 suites** vertes
(`test-seed-registres.sh` : 19 cas ; `test-vibeflow-update.sh` : 11, T3b).

## [v2.51.0] — 2026-08-15

**Les gains de la deep-search ICM sont distillés dans l'outillage — les mécanismes, jamais le
label — et le socle `dag.sh --scope` traverse la phase sans qu'une seule de ses lignes bouge.**

Phase 29 (5 plans, 13 tâches, 12 exigences `ICMD-01..12`), PR #41 — plus les plans 01-02 de la
Phase 28 portés par la même branche. Origine : le rapport
`reports/research/2026-08-15-icm-deep-search.md` (4 agents de recherche parallèles sur le papier
arXiv 2603.16021, ses implémentations et son écosystème), dont le verdict — « rien à adopter tel
quel, 5 mécanismes à distiller » — devient la phase. **La contrainte de cadrage D-03, ratée
one-way, est tenue par construction** : l'investigation préalable a rétabli l'historique réel du
mécanisme (`--scope` déclaré en **Phase 20** — D-13 de `20-CONTEXT.md`, commit `d549b2d` — la
Phase 27 n'ajoutant que la partition `stages` et la fermeture RCE), recensé ses consommateurs et
conclu que le « négatif du périmètre » réclamé par G1 se compose entièrement depuis les champs
déjà émis — `dag.sh` et `test-dag.sh` sont absents du diff de toute la branche, la suite du socle
(99 cas) rejouée verte à chaque étage. **Livré** : **G3**, `check-map-drift.sh` (conductor) — le
gate anti-drift carte↔disque qui manquait structurellement (les gates existants détectent
l'immobilité, jamais l'incohérence : compteurs faux de la Phase 22, folder maps qui mentent,
skills fantômes), lint-only par ADR-031, grammaire 0/3/64 avec plancher `NON VÉRIFIABLE` sur
cible vide, deux paires v1 (carte de dossiers d'un `CLAUDE.md` ↔ disque, index de dossier ↔
contenu), bornes implémentées **comme classes et jamais comme filtres de sortie** après verdict
humain sur exécution réelle (13 → 3 findings : une ligne de commande n'est pas un chemin déclaré,
l'exemple pédagogique `examples/` est hors balayage — les 3 findings restants sont le signal
assumé, cartes jamais retouchées) ; **G1**, la bullet « NE charge PAS » dans le digest de mission
(`mission-contracts.md`), rédigée par le manager depuis le `scope[]` du nœud — l'anti-chargement
devient une instruction de premier ordre ; **G5**, l'Edit-Source Principle dans `team-kernel.md`
(une correction récurrente au même endroit est une information de debugging : on amende la source
— contrat, skill, digest — on ne redispatche jamais le même fix), consigner-puis-proposer sous
ADR-031 ; **G2**, `scaffold-docs.sh` gagne le pattern `_index.md` (dossiers de références > 10
fichiers) et la contrainte ≤ 80 lignes sur les index — et sa **première suite de tests**, qui
couvre aussi son comportement d'hier. **Le défaut de méthode qui compte** : 6 passes de juge sur
`check-map-drift.sh`, 6 défauts réels, **aucun trouvé par la suite du worker** — chaque correctif
fermait le cas nommé et laissait vivre son voisin, jusqu'au changement de méthode (preuve
générative : 45 combinaisons, 10 rouges avant / 0 après, au lieu d'une liste de cas) ; et un cas
de test qui s'attestait contre `git show HEAD:` — mutable — donc structurellement incapable de
rougir une fois le correctif commité : rouge permanent corrigé en figeant le SHA. Les deux leçons
sont consignées en mémoire d'agent. **Aussi** : `parallelization.skip_checkpoints` repasse à
`false` (troisième vecteur d'auto-approbation de checkpoint neutralisé — l'arrêt du checkpoint
humain de cette phase n'avait tenu que par la borne du mandat), G4 (lab-starters clonables) et
les gains secondaires du rapport explicitement différés au backlog. **Phase 28, plans 01-02** (le
plan 03 *as-installed testing* reste ouvert) : `check-capability-activation.sh` gagne les règles
4 et 4bis — un artefact qui arme `isolation:` ou un serveur MCP sans que sa précondition soit
distribuée sort en écart, planchers anti-vert-à-vide, porteurs `# vf-provides:` opposables par
exécution (41/41 cas) — la généralisation structurelle de l'incident #38. Modules : 4 bumpés
(`conductor` v1.22.0, `dev-orchestrator` v2.14.0, `validator` v1.3.3, `reference` v2.5.3).
**54 suites** vertes (52 → 54 : `test-check-map-drift.sh`, `test-scaffold-docs.sh`), compteur
re-dérivé jamais recopié.

## [v2.50.1] — 2026-08-10

**Correctif : `isolation: worktree` retiré des 13 agents écrivains — la ligne livrée en v2.49.0
rendait les workers d'équipe inutilisables dès qu'un manager mandatait une branche.**

Issue #38, PR #39. Signalé sur `vf-coder` et `vf-crafter`, corrigé sur les **13 agents des
6 modules** : la cause est identique partout, n'en réparer que deux aurait laissé 11 workers
cassés.

### Le symptôme, et pourquoi il était invisible

Le worktree du harness fork depuis la **branche par défaut**, jamais depuis le HEAD courant. Quand
un manager avait préparé une branche pour la mission, deux règles se croisaient : git interdit de
checkout la même branche dans deux worktrees, et l'agent isolé n'a pas accès au checkout partagé.
Le worker atterrissait donc sur une branche technique repartant de la branche par défaut, **sans
aucun fichier du mandat**, sans chemin de sortie — il se déclarait bloqué en deux minutes sans
produire, et le manager se rabattait sur un agent générique dépourvu de sa doctrine, de ses
allowlists et de la chaîne d'outils qu'il sait dispatcher. Du point de vue de l'utilisateur, la
mission avançait : simplement pas avec l'agent prévu.

### La cause n'est pas la ligne, c'est ce qui ne l'accompagnait pas

La précondition qui corrige le fork — `worktree.baseRef: "head"` — vit dans le settings du
**poste**. La Phase 27 l'a posée dans le settings local de **ce** repo, sous checkpoint humain,
avant d'armer les 13 agents ; mais l'engine ne la pose **nulle part** chez l'utilisateur. Vérifié :
zéro occurrence de `baseRef` dans `vibeflow-update.sh`, `merge-hooks.sh` et l'installeur. Les
agents ont donc été distribués **armés sans leur précondition** — l'armement voyage, la garantie
reste à la maison.

Et même distribuée, elle n'aurait pas suffi : rien ne ramène les commits du worker vers la branche
de mission. Le merge affirmé n'est implémenté nulle part en amont (`open-gsd/gsd-core#3302`) —
c'était **déjà** le motif du refus écrit de `claude_orchestration`, dans cette même Phase 27. La
preuve du refus et la cause de cette régression sont le même fait, consigné puis non reporté sur
l'autre chemin.

### Correctif

- **`isolation: worktree` retiré du frontmatter des 13 agents** — `vf-coder`, `vf-crafter`,
  `vf-test-runner`, `vf-app-fixer`, et les 9 agents des bundles business, content et growth.
- **Garde-fou machine** — `check-agents.sh` validait la *forme* de la clé (« seul `worktree` est
  admis ») sans jamais interroger sa *légitimité* : c'est ce qui a laissé passer l'armement. Il
  refuse désormais tout `isolation:` dans un agent distribué, avec le motif et la **condition de
  levée** écrits sur place — distribuer la précondition **et** prouver le retour des commits, pas
  supprimer le gate. Discriminance vérifiée : la ligne remise fait sortir le lint en 1.
- **Doctrine** — `team-kernel.md` §Règles d'instanciation porte la règle en clair : l'isolation est
  une **décision de dispatch du manager**, jamais une propriété du worker. C'est ce que la doctrine
  disait déjà (« périmètres douteux → séquentiel ou `isolation: worktree` », une décision **par
  dispatch**) ; le frontmatter la contredisait en la rendant inconditionnelle et retirait au
  manager l'arbitrage que sa propre doctrine lui confie.

### Aussi

La phrase « les deux README n'affichent que les 3 dernières entrées » disparaît des deux README et
de l'en-tête de ce fichier : ils en affichaient **13**. Remplacée par une formulation **sans
chiffre** — un compte gravé dans une prose que personne ne re-dérive redevient faux à la release
suivante.

Modules : 7 bumpés (`conductor` v1.21.1, `dev-orchestrator` v2.13.1, `design-orchestrator` v1.5.1,
`mobile-test-team` v1.4.4, les 3 bundles v2.0.6). **52 suites** vertes.

## [v2.50.0] — 2026-08-10

**La chaîne d'outils design ne dégrade plus en silence — et la détection qui la surveillait était
aveugle à la moitié du problème.**

Quick task `260810-fh3`, 3 tâches + 2 correctifs, PR #36. Le module `design-orchestrator` dépend de
4 plugins externes (`ui-ux-pro-max`, `frontend-design`, `impeccable`, `superpowers`) : si l'un
manquait, rien ne bloquait et rien n'alertait — l'absence n'était mentionnée qu'en **rapport final**,
une fois le travail déjà mené sur premiers principes.

**Le trou était plus large que « il ne vérifie rien ».** La seule détection outillée du repo —
`claude plugin list | grep <nom>`, héritée de `dev-orchestrator/scripts/ensure-deps.sh` — matche sur
le nom seul : un plugin installé puis **désactivé** passait pour présent. Le cas n'est pas théorique,
il a été mesuré sur le poste de dev : `frontend-design@claude-code-plugins` désactivé coexiste avec
`frontend-design@claude-plugins-official` actif. Second constat de cadrage : `design-orchestrator` ne
déclare que `"requires": ["conductor"]` — un lab qui l'installe seul n'hérite d'**aucun** bootstrap
du module de dev, donc rien n'était empruntable.

### Livré

- **`plugin/design-orchestrator/scripts/ensure-design-deps.sh`** — bootstrap **autonome** (D-04 :
  aucun `source`, aucun appel vers un autre module ; la parenté de forme avec `ensure-deps.sh` est
  une duplication **délibérée**, documentée en en-tête, du même ordre que celle déjà assumée entre
  `ensure-deps.sh` et `check-gsd-engine.sh`). Vérifie **présence ET activation** des 4 plugins et
  corrige en non-interactif.
- **Cascade de détection, jamais un verdict sans preuve** : source primaire `claude plugin list
  --json` (structurée : `id`, `enabled`, `scope`), parsée via `python3` avec la garde ADR-054 du stub
  Microsoft Store ; repli `awk` en machine à états sur la sortie décorée, qui discrimine sur les
  **mots** `enabled`/`disabled` et **jamais sur les glyphes** — une décoration mutilée par la locale
  ne doit pas retourner le verdict en silence ; aucune source exploitable → état **indéterminé** et
  4 étapes manuelles affichées, jamais un « présent » par défaut.
- **`installed_plugins.json` écarté explicitement** : il ne porte aucun champ `enabled`. C'est
  l'origine même du trou fermé ici, et le commentaire du script le dit sur place.
- **Règle « au moins une entrée du même nom active suffit »** pour les plugins présents sur plusieurs
  marketplaces ; un plugin **désactivé** reçoit un `claude plugin enable <id> --scope`, **jamais** un
  `install` nu qui n'aurait rien réactivé. Tout `id` issu d'une sortie de commande est validé (forme
  stricte `<nom>@<marketplace>` **et** appartenance aux 4 littéraux de la table) avant de toucher une
  ligne de commande — la table des 4 plugins est littérale, jamais dérivée de l'environnement.
- **Câblage double** : hook post-install **nommé** dans `plugin/_internal/vibeflow-update.sh`,
  strictement symétrique de ses deux jumeaux (`build-gsd-index.sh`,
  `build-gsd-capabilities-index.sh`) — déclenché à l'install **et** à chaque update, double garde
  `-f`, best-effort : il ne peut jamais amputer l'install d'un module ; et section « Premier
  contact » dans `AGENT.md` (193 L, sous le budget ADR-029), une fois par session avant
  DA-INIT/DESIGN-WORKFLOW, sous garde-fou d'Iron Law — l'agent lit la sortie pour lui et ne restitue
  **jamais** les noms de plugins bruts.

### Le défaut trouvé en revue — sur le résultat livré, pas sur le plan

Le hook appelait le script avec `>/dev/null 2>&1` alors que **tout** sort sur stderr. Une install où
les 4 plugins manquent et où l'auto-install échoue (CLI `claude` absente, réseau, marketplace
injoignable) n'aurait produit **aucune ligne** — la dégradation silencieuse que ce module vient
fermer, rejouée un cran plus haut. Correction en trois points : `log()` (routine, supprimée par
`--quiet`) séparée de `notice()` (anomalie, traverse toujours) ; drapeau `ANOMALY` armé dès qu'un
plugin n'était pas déjà actif — **y compris quand le geste réussit**, parce qu'une install qui pose
des plugins dans le dos de l'utilisateur doit rester visible — qui décide si le résumé traverse
`--quiet` ; hook en `--quiet` **sans** `2>&1`, motif écrit sur place pour qu'une future main ne
« nettoie » pas la sortie en réintroduisant la redirection.

### Deux rouges CI, une seule racine

Du **contexte de la machine qui fuit dans le livrable**. (1) 3 `cd /Users/<user>/…` dans le PLAN,
recopiés depuis les `files_to_read` passés au planner — `check-machine-paths.sh` les refuse, à juste
titre ; remplacés par `cd "$(git rev-parse --show-toplevel)"`. (2) `T9b` **mesurait la machine
plutôt que le script** : il compte les commandes du dry-run forcé, mais sans CLI `claude` sur le
`PATH` le script part en état « indéterminé » et n'en émet aucune — vert sur un poste équipé, rouge
par construction sur un runner nu. Ses voisins `T9c` et `T9g` stubbaient déjà `claude` ; lui avait
été oublié. Suite re-vérifiée sous `PATH=/usr/bin:/bin`, la condition du runner.

### Hors périmètre assumé

**Aucun contrôle de version/fraîcheur** des 4 plugins : la moitié porte `version: "unknown"`, un
contrôle serait du bruit. `design-toolchain.md` §Vérification de présence porte le contrat en
4 points et reste **jumelle** de la table littérale du script — les faire diverger est le défaut
nommé sur place, des deux côtés.

Suite du module 12 → **24 cas** (T9..T9g), discriminance prouvée par mutation sur trois propriétés
distinctes (règle enabled/disabled, non-silence du script, non-silence du hook), puis restauration et
re-confirmation du vert. Aucun nouveau fichier de suite — compteur racine inchangé. Module : 1 bumpé
(`design-orchestrator` v1.5.0). **52 suites** vertes, CI verte sur le runner Linux.

## [v2.49.0] — 2026-08-10

**La parallélisation d'exécution devient granulaire et sûre par construction — et la voie « moteur »
qui promettait plus est essayée pour de vrai, puis refusée par écrit.**

Phase 27, 6 plans en 4 vagues, PR #35. Prémisse renversée dès le cadrage : le parallélisme
intra-étape n'était pas « perdu », il est **éteint par défaut** — la doctrine le dit désormais, et
nomme le vrai chemin (gate n°4 `nested && background`, verrou pratique gate n°5
`GSD_AGENT_SDK_VERSION`).

### Livré

- **`dag.sh ready` porte `stages`** : partition machine de la frontière en étages sans recouvrement
  de `scope[]`, câblée sur `partitionStages()` amont en sous-processus (ADR-069, jamais
  réimplémentée), additive pour les 5 consommateurs, repli fail-closed `stages: null` prouvé en
  exécution. Cas T25-T33, suite 99 PASS.
- **Isolation worktree cadrée puis armée** : `.worktreeinclude` en allow-list énumérée (1 entrée,
  `.claude/agent-memory/`), exclusion motivée des 6 managers (groupe B), `worktree.baseRef: "head"`
  posé sous checkpoint humain AVANT l'armement des **13 agents écrivains** (groupe A) — l'ordre est
  une précondition mécanique, pas une convention.
- **Baseline d'horloge capturée avant toute activation** (D-10, précondition vérifiée : 0 occurrence
  de la capability dans la config au moment de la capture) ; le plafond 3,00× reste écrit comme une
  compression d'étages, jamais comme un gain d'horloge ; le 1,8-2,5× reste étiqueté estimé (D-13).

### Refusé par écrit, avec la preuve

- **`claude_orchestration` (backend Workflow)** : SDK réel 0.3.223, persistance tranchée par
  arbitrage humain (option 3, installation réelle dans `~/.claude` — seule option sans valeur
  épinglée), échelle des 7 gates franchie **sans drapeau manuel** sur le chemin réel de
  production… et pourtant **REFUS** : le run Workflow réel diverge du chemin inline au sens exact du
  critère FAIL n°2 — aucun commit de worker, aucun SUMMARY, aucun merge, worktrees résiduels.
  Sous-expérience Décision A sûre (question remontée en rapport, rien d'écrit). Repli fail-closed
  re-testé après manipulation de config, byte-identique à aujourd'hui. L'audit du design amont
  confirme par analyse statique que le merge affirmé n'est implémenté nulle part ; le namespace a
  été réglé en amont (gsd-core 1.10.0, #3021), le reliquat — manifeste de merge jamais peuplé — est
  rapporté en **open-gsd/gsd-core#3302**, qui devient le déclencheur objectif de reprise.
- **Boucle de mesure fermée sans blanc** : `STATUT-BLOC-3: NON-MESURABLE`, motif et déclencheur
  recopiés de la décision, protocole A/B conservé intact pour la reprise.

### Sécurité

- **RCE fermée et propagée** (ADR-070) : `dag.sh` n'exécute plus de `gsd-tools.cjs` résolu
  relativement au CWD ; la variante `toplevel` est propagée à `mission-contracts.md`.
- **`27-SECURITY.md`** : 37 menaces au registre plan-time, 35 fermées sur preuve citée (gates
  re-exécutés), 2 ouvertes non-bloquantes consignées telles quelles — dont T-27-03-06, hypothèse
  **infirmée par le run réel** (`GSD_WORKSTREAM` vide sous worktree) et propagée en doctrine
  `team-kernel.md` : un manager passe le workstream explicitement dans le mandat d'un worker isolé.
  `threats_open: 0`.

Modules : 7 bumpés (conductor v1.21.0, dev-orchestrator v2.13.0, business-pilot-bundle /
content-bundle / growth-bundle v2.0.5, design-orchestrator v1.4.2, mobile-test-team v1.4.3).
**52 suites** vertes, CI verte.

## [v2.48.0] — 2026-08-05

**Les capacités dormantes du moteur GSD sont activées, mesurées ou refusées par écrit — et quatre
gardes qui rendaient vert ne faisaient rien.**

Phase 24, 12 plans, 6 arbitrages humains, PR #34.

### Activé

- **Slot `agent_skills` PLANNER** — la doctrine de dev du lab atteint enfin `gsd-planner`, l'agent
  qui décide de la découpe. Le slot EXECUTOR est écarté pour un motif **factuel** et non de
  conformité interne : son injection ne vit que dans le prompt de dispatch d'`execute-phase.md`, et
  notre chemin réel tombe sur le repli inline qui n'injecte rien.
- **`intel`** — notre propre `docs-flow.md` publiait `gsd-map-codebase --query` comme l'un des deux
  modes normaux alors que la capacité était éteinte : une commande documentée qui ne faisait rien.
- **`windows_enforce` et `workflow_guard`** — le préalable « monter `gsd-core` » s'est révélé
  **inexécutable** (aucune version publiée au-delà de 1.9.1 ; le correctif de l'issue amont #2893
  lui est postérieur), et le risque qu'il protégeait **absent de ce dépôt** (`WINDOWS.md` ne porte
  aucune prose sous son ledger). Gate relâché par ADR-066 ; le `waive` a été répété sur une copie
  jetable avant application, fichier commité avant, intégrité vérifiée après.

### Refusé par écrit, avec la mesure

- **`hooks.community`** (ADR-067) — 23 commits sur 109 échouent sur le type, 68 % des sujets
  dépassent 72 caractères. Recomptés **en caractères et non en octets** : un décompte en octets
  gonfle les sujets français accentués et aurait fabriqué un faux motif.
- **Profils de contexte** (ADR-068) — la clé est validée et documentée en amont, mais la recherche
  exhaustive ne rend que des occurrences auto-déclaratives : **aucun consommateur ne la lit**. Le
  fait s'est inversé pendant le cadrage et a tranché la question seul.
- **`graphify` et `profile-pipeline`** — aucun lecteur prescrit dans le module.

### Workstreams adoptés — ADR-069

Tranché par Samuel **contre la recommandation du cadrage**, sous la doctrine « coller au max à ce
que fait GSD ». Livré : quatre gates rendus workstream-aware et **exercés en CI sur un arbre
réellement partitionné**, `GSD_WORKSTREAM` adopté comme canal nominal (**ADR-064 amendée** — le
pointeur de session vit dans `os.tmpdir()` indexé sur le chemin absolu réel, donc il ne compose
jamais avec les worktrees, et sous Claude Code il n'est **jamais lu**), et **Iron Law 2 révisée**
plutôt que contournée en silence. Limites datées gravées dans l'ADR avec leur critère et leur
commande rejouable.

### Sécurité — quatrième passage du motif symlink, celui-là vivant

`.planning/workstreams/dev` en lien symbolique hors du lab faisait **injecter le `STATE.md` de la
cible dans le contexte de session**, à exit 0, sans aucune action de la victime au-delà de
l'ouverture de session. Le nom était validé, le pointeur-fichier refusait les liens — **le
répertoire n'était contraint par rien**, et `[ -d ]` suit le lien. **Les quatre** gates
workstream-aware portaient le trou, dont celui qui bénissait la partition « conforme » et sur lequel
les trois autres s'appuyaient.

Le vrai livrable est le diagnostic du **pourquoi il repasse** : **6 implémentations du même besoin
en 3 langages**, une primitive sûre déjà existante mais **déguisée en règle métier**, et un contrôle
anti-duplication qui **itère sur des chemins écrits en dur** — un script neuf n'est donc dans aucun
roster. `build-gsd-capabilities-index.sh` a pu ré-inventer le confinement en écrivant dans son
propre commentaire « c'est le troisième passage, il se ferme ici ». Dette nommée dans `CONCERNS.md`.

**Menaces** : 56 portées par les 12 plans, **0 verdict enregistré** dans les 11 résumés — l'écart
découvert en écrivant `24-SECURITY.md`. 18 ouvertes, fermées une par une **sur preuve citée**
(commits vérifiés en `--numstat`, canaris et suites réellement rejoués), jamais sur la foi d'un
résumé.

### Quatre gardes vertes qui ne faisaient rien

- **Borne de longueur du canal nominal, inerte sur Linux.** `vf_ws_trim` forkait `awk` ; pendant
  l'appel `GSD_WORKSTREAM` reste exportée, `execve()` en hérite, et le noyau Linux borne **chaque
  chaîne** d'`argv`/`envp` à `MAX_ARG_STRLEN` (128 KiO) — limite indépendante d'`ARG_MAX`, **absente
  sur macOS/BSD**. Le fork échouait en `E2BIG`, la valeur revenait vide, et une entrée de 200 000
  octets passait. Réécrite en bash pur, sans `execve()`.
- **Assertion anti-régression comparant deux sorties vides.** `R1` fusionnait stdout et stderr, choix
  fait quand stdout était muet ; refermer le gap de la bannière lui a rendu la parole et elle a lu
  la ligne de repli documentée comme une fuite. Elle teste désormais le contrat réel, non-permissivité
  prouvée sur 4 mutants.
- **Trois faux verts et un faux rouge** dans `check-state-integrity.sh` (handler de rejet fail-open,
  test de vacuité avant le trim, borne de 80 caractères non-amont).
- **Un gate de pointeur** qui rendait « conforme » sur `..` et fabriquait un vert sur un nom qu'il
  avait lui-même réécrit.

Chacune fermée **par mutation, jamais par relecture**.

### Densité, gates et hygiène

- **`effort:` par rôle sur les 31 agents** — pas 25 : l'installeur copie aussi les
  `plugin/*/AGENT.md`, et la preuve d'exhaustivité par `comm` avait porté sur le mauvais univers.
  `check-agents.sh` durci de « valide si présent » à « **exige** ».
- **Marge de profondeur de dispatch écrite** dans `team-kernel.md` : `maxDepth: 5`, 3 consommés.
- **Gates neufs** : `check-capability-activation.sh` (relie une entrée de doc à l'activation de sa
  capability — la cause structurelle des trois routes inertes, et le vrai livrable de la zone),
  `check-machine-paths.sh` (bloquant, trois échappatoires, discriminance prouvée sur les trois
  organes), `check-workstream-pointer.sh`.
- **`24-VALIDATION.md`** porte `nyquist_compliant: false` **avec ses motifs** — le geste honnête
  plutôt qu'un verdict forgé, comme l'avait fait la Phase 23.

### Le fil rouge

**Quatre fois un décompte juste a porté sur le mauvais ensemble** : 25 agents annoncés pour **31**
réels, 47 suites pour **52**, 8 modules pour **10**, 1 gate troué pour **4**. D'où la règle que la
phase adopte : *tout chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture.* La
variante la plus nette est une régression causée puis fermée en cours de mission — le frontmatter de
`STATE.md` porté de 56 à 97 lignes, dépassant la garde `NR > 60` et **éteignant silencieusement la
bannière de démarrage** : écrire l'état pour un lecteur humain sans mesurer ce qu'une machine en lit.

**CI** : verte sur le runner Linux, où elle était **rouge depuis 5 runs** pendant que le local macOS
annonçait tout vert — divergence de plateforme, pas un flake. Modules : 10 bumpés. **52 suites**, 0 échec.

## [v2.47.1] — 2026-08-04

**L'index des skills cesse de mentir sur sa propre provenance, et l'historique reçoit l'entrée
qu'une release avait sautée.**

Origine : la mise à jour du moteur `@opengsd/gsd-core` de 1.9.0 vers **1.9.1**, et la question de
savoir si le couplage tenait encore. **Il tient sur toute sa surface, vérifié plutôt que déduit** :
le plafond `^1` de `ensure-deps.sh` couvre 1.9.1 ; les flags `--claude`, `--global`, `--local`
existent tous dans l'installeur 1.9.1 ; les commandes appelées (`loop render-hooks`, `state`,
`state record-session`, `roadmap analyze`) sortent toutes en 0 ; et les capabilities **déclarées**
sont identiques entre les deux versions — index régénéré depuis le registre de chacun des deux
tarballs, 12 points de hook, 35 étages, sortie identique à l'octet près. Le delta amont porte sur
les runtimes non-Claude (config Codex, `~/.gsd/defaults.json`) et un troisième registre de
découvrabilité, pas sur le contrat consommé ici.

**Le seul défaut actif**, trouvé en le vérifiant : l'en-tête de `gsd-skills-index.md` annonçait
`@opengsd/gsd-core@1.9.0` — un **littéral figé** dans `build-gsd-index.sh`. Un fichier auto-généré
ET versionné qui affirme une provenance fausse, et qui contredisait frontalement la doctrine que le
script voisin `build-gsd-capabilities-index.sh` énonce dans son propre en-tête (« aucune version de
moteur n'est figée dans la logique »). La version est désormais **lue** sur le moteur résolu, selon
une règle unique — le moteur est le dossier parent de la source de workflows que la cascade
dual-layout a déjà résolue —, si bien qu'elle décrit toujours l'arbre d'où sortent réellement les
entrées de l'index, sans seconde cascade à maintenir.

Trois conduites de bord, chacune tenue par un test : VERSION absente ou illisible → l'en-tête
**dit** « (version inconnue) » plutôt que d'affirmer un numéro ; VERSION non maîtrisée → lecture
bornée à 200 octets puis classe de caractères restreinte avant impression (port du garde de
`check-gsd-engine.sh`, T-19-01-04), une substitution de commande écrite dans le fichier est
neutralisée et jamais évaluée ; disposition **legacy** → l'index nomme `get-shit-done-cc`, il ne
maquille pas un moteur legacy en `@opengsd/gsd-core`. `T1e` est **DISCRIMINANT par construction**
(fixture `9.9.9-fixture`, qu'aucun littéral plausible ne contient), discriminance prouvée dans les
deux sens : 4 KO avec la version figée restaurée, 165 OK / 0 KO après. Suite du module 161 → **165
cas**.

**Dette d'historique soldée au passage** : la **v2.47.0** avait été taggée et publiée sur GitHub
sans jamais recevoir son entrée dans ce fichier, qui se présente pourtant comme le canon unique de
l'historique. L'entrée est rédigée ci-dessous, a posteriori et signalée comme telle. C'est la même
classe de défaut que la page Releases bloquée de v2.29.0 à v2.39.0 : un artefact publié qui affirme
une complétude qu'il n'a pas.

Module `dev-orchestrator` v2.11.1. **47 suites** vertes.

## [v2.47.0] — 2026-08-04

> Entrée rédigée a posteriori le 2026-08-04, en préparant la v2.47.1 : la v2.47.0 avait été
> taggée et publiée sur GitHub **sans jamais recevoir son entrée ici**. Le fichier se présente
> comme le « canon unique » de l'historique — un trou y vaut la page Releases bloquée que la
> discipline de release de `CLAUDE.md` interdit déjà par ailleurs.

**Le moteur de dev est explicitement couplé à GSD, et le lock de driver cesse de s'ouvrir pendant
qu'il se récupère.** Deux volets.

**(1) Phase 23 — couplage explicite** (10 exigences `GSDC-01..10`, 9 soldées). Le module raisonnait
comme si GSD était une liste de skills à appeler, alors que 1.9 est un **moteur à capabilities**
qui insère ses étages lui-même — `grep -r "capabilit\|render-hooks"` sur `dev-orchestrator/`
rendait **zéro**. Livrés : une **voie unique d'invocation** (la voie de l'agent nu désactivait en
silence research, pattern-mapper, plan-checker, gap-analysis, waves, verifier, code-review, nyquist
et secure-phase, tout en rendant `passed`) ; une **doctrine de flags en allowlist stricte**, qui
ferme par défaut au lieu d'ouvrir par omission ; une table capabilities/hooks **générée depuis le
moteur installé** au lieu d'être écrite à la main — elle ne peut plus dériver en silence ; un
**contrat de checkpoint relayé et jamais recalculé** ; et **un budget de tours par étape** au lieu
de deux boucles qui additionnaient les leurs. `GSDC-08` part en `[~]` : l'écart `D-22`
(`gsd-debugger` présent contre une décision « aucune exception » **et** exigé par le gate `T19`)
relève de l'arbitrage, pas du code. **Deux RCE fermées**, dont une réintroduite par un script neuf
via une prémisse de sécurité jamais propagée d'un plan à l'autre — prouvée close en rejouant
l'install complète depuis un dépôt piégé : le piège est prouvé **lu**, pas évité en silence. Suite
du module 102 → **161 cas**. (PR #30)

**(2) Une course de récupération dans `driver-lock.sh`.** Récupérer un claim périmé **déplaçait** le
dossier de lock avant de le recréer ; pendant ce déplacement le chemin n'existe pas, et le `mkdir`
de la voie normale — incapable de distinguer « libre » de « en cours de récupération » — y entrait.
Jusqu'à **5 gagnants simultanés** mesurés sur 24 acquisitions concurrentes, sur macOS comme sur
Linux. Ce n'était pas une fenêtre à rétrécir : deux correctifs de fenêtre ont été mesurés **pires**
que l'original (8 et 6). Le lock devient un **lien symbolique** remplacé par `rename(2)` — jamais
absent, donc jamais apparemment libre —, la génération est publiée complète, la récupération est
sérialisée par un mutex nommé d'après elle, et le verdict de péremption est relu après lui. Les
locks au format dossier restent lus et récupérables : une mise à jour ne gèle pas les sessions en
cours. `T13` passe de 6 concurrents en un tirage à **24 × 5 rounds**, les deux bornes gardées.
(PR #31)

Modules `dev-orchestrator` v2.11.0, `conductor` v1.19.1. **47 suites** vertes.

## [v2.46.0] — 2026-08-01

**Le suivi cesse de mentir, et deux sessions cessent de pouvoir se marcher dessus sans le savoir.**
Modules `conductor` **v1.19.0**, `dev-orchestrator` **v2.10.0**, `design-orchestrator` **v1.4.0**.

### Hygiène documentaire — la doctrine de sortie (Phase 22)

La doctrine documentaire avait une **entrée** (`ingestion-flow.md`) mais pas de **sortie**. Elle en
a désormais une, symétrique, et les deux managers de mission savent quand la déclencher.
`docs-flow.md` distingue les quatre familles que GSD maintient séparément et que nous avions fondues
en une seule ligne : doc **produit** (`gsd-docs-update`), doc **d'entrée** (`gsd-ingest-docs`), doc
**du code** (`gsd-map-codebase`), doc **de savoir** (`gsd-extract-learnings`). Les flags porteurs de
sens sont enfin exposés — `--verify-only` (auditer sans écrire) et `--force` (régénérer, écrase le
manuscrit) répondent à deux intentions que rien ne distinguait. `vf-design-manager` reçoit le même
nœud `docs` que son homologue dev, **par renvoi et jamais par copie** (ADR-057).

### Le ROADMAP reçoit la checklist que le moteur lit

Le chantier était annoncé comme « les ~20 SUMMARY manquants ». Le diagnostic a montré autre chose :
**le ROADMAP n'avait jamais porté la checklist de phases**, seule forme que `@opengsd/gsd-core` lit
pour établir qu'une phase est terminée. Le moteur voyait **zéro** phase finie sur 24 et rendait des
compteurs faux (`completed_phases: 10`, `current_phase: 19` alors que la Phase 22 était livrée). La
table `## Progress`, riche et tenue à jour, n'est lue par **aucun** outil : elle est écrite pour les
humains, et les deux s'étaient éloignées sans que rien ne le signale.

Checklist posée pour les 25 phases. Elle rattrape du même geste les **20 plans sans SUMMARY** des
Phases 11 à 14 : `roadmap.cjs` fait explicitement primer la case cochée sur le disque, « pour les
phases terminées avant le tracking GSD, qui n'ont pas les paires PLAN/SUMMARY ». Ces 4 phases sont
shippées, chacune avec sa release — **rien n'est inventé, aucun SUMMARY n'est fabriqué**. Les Phases
23 à 25, inscrites hors périmètre par une session concurrente, sont **régularisées** sous un jalon
`gsd-alignement` avec une note d'origine qui dit franchement d'où elles viennent.

**Deux signalements déposés en amont** : [#2956](https://github.com/open-gsd/gsd-core/issues/2956)
(`Phase` toujours non scopé — troisième génération de #2444/#2567, dont `Last Activity` avait reçu
un garde-fou que `Phase` n'a jamais eu) et
[#2957](https://github.com/open-gsd/gsd-core/issues/2957) (`buildStateFrontmatter` ignore la
checkbox que `roadmap.analyze` honore délibérément — la même fonction lit le ROADMAP pour le
dénominateur et refuse de le lire pour le numérateur).

### Un écrivain = un worktree (ADR-064)

Le 2026-07-31, **deux sessions ont écrit sur la même branche sans le savoir** : trois commits hors
périmètre dans la PR d'une mission qui ne les avait pas produits. Le constat de départ — « le verrou
protège l'étape, pas la branche » — était juste mais incomplet, et l'incomplétude changeait la
solution : **`driver-lock.sh` n'est consulté que par les managers**, et la session fautive n'en était
pas un. Durcir le verrou n'aurait rien changé ; un verrou que seule une catégorie d'acteurs
interroge documente une intention, il ne la fait pas respecter.

ADR-064 tranche ce qu'ADR-059 avait explicitement laissé ouvert : l'isolation devient **physique**
(`isolation: worktree`) au lieu de reposer sur la bonne volonté de celui qui écrit. `driver-lock.sh`
enregistre `branch=` et `worktree=` et les **préserve** au heartbeat. `check-branch-claim.sh`
(contrat à 4 codes, **advisory**, câblé au `SessionStart`) porte enfin le claim jusqu'aux sessions
ordinaires — le discriminant est l'**arbre**, pas l'owner. Emprunts assumés à
`shanraisshan/claude-code-best-practice` (le worktree de premier rang) et à `jcode`/ADR-053 (le
verrou, dont on élargit le claim au lieu de le remplacer).

Un faux positif réel a été trouvé dans le gate en le construisant : la comparaison **littérale** des
chemins d'arbre le faisait crier sur son **propre** arbre (`/tmp` → `/private/tmp` sur macOS).
Corrigé par comparaison normalisée, tenu par un cas de régression **et** un cas de discriminance,
mutant tué.

**46 suites** vertes, `check-agents --strict` vert sur les 6 dossiers d'agents.

## [v2.45.0] — 2026-07-31

**VibeFlow aligné sur `@opengsd/gsd-core` 1.9.0.** Modules `dev-orchestrator` **v2.9.0**,
`planning-core` **v2.5.3**, `conductor` **v1.18.0** (inchangé, vérifié cohérent).

**Origine.** La mise à jour du moteur GSD de 1.8.0 vers 1.9.0 sur un poste équipé le 2026-07-31.
Delta établi **sur pièce** (`npm pack` des deux versions, diff intégral des tarballs, vérification
de l'installation vivante — `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`). Vérifié avant
ouverture de la phase : le dispatch tient (aucun frontmatter d'agent modifié entre les deux
versions, 71 skills des deux côtés, 43 suites vertes) — cette release est de l'**alignement**, pas
du sauvetage, à l'exception du défaut actif ci-dessous.

**Le seul défaut actif : l'injection MCP était structurellement inopérante hors `.mcp.json`.**
`inject-mcp-tools.sh` ne dérivait la liste des serveurs MCP que de `./.mcp.json` (scope projet).
Sur tout poste où un serveur est déclaré uniquement en **scope global** (`~/.claude.json`, ex.
XcodeBuildMCP — le cas réel de ce dépôt), le serveur restait invisible et `--verify` sortait en
`3` INDÉTERMINÉ au lieu de signaler l'écart, alors qu'un `gsd-executor` dispatché en sous-agent
est structurellement aveugle au MCP de la session. Corrigé par une **union de deux sources**
(`./.mcp.json` ∪ `~/.claude.json` clé `mcpServers`, `--claude-json`/`VF_CLAUDE_JSON`),
dégradation indépendante par source, précédence projet > global sur collision de nom.

**Les 5 autres changements, tous instruits et écrits.**
- Le contrat amont `estimate:`/`actuals:` (ADR-2629, #2632) est relayé **verbatim** par
  `vf-coder`/`vf-dev-manager` — jamais une statistique auto-évaluée du cru de l'agent.
- **ADR-061** arbitre par écrit le recouvrement entre les lanes de revue cross-AI de plans amont
  (`review-lane-descriptor.cjs`) et l'étage de revue de code livré en Phase 20 (20-06) : deux
  objets distincts, gardés séparés, aucun câblage automatique construit par anticipation.
- L'hypothèse datée du **dispatch nommé** (`hostIntegration.dispatch.namedDispatch`, amont 1.9.0)
  est consignée dans `team-kernel.md`, recoupée avec `gsd-worktree-path-guard.js` (#1995 — namespace
  de branche élargi `agent-*`/`worktree-agent-*` — et #2608 — cas `staging_failed`/`staging_timeout`
  interne à `gsd-executor` — vérifiés conformes sur pièce).
- **Purge de la dette de version** 1.8.0 → 1.9.0 sur 6 fichiers (index régénéré, 3 scripts,
  `mission-contracts.md`). Piège de préservation tenu : le cas de test qui asserte la chaîne
  littérale de version (`test-check-gsd-engine.sh` cas 8) s'est déplacé avec le texte qu'il
  vérifie, jamais neutralisé — la leçon semver (le fork repart de zéro, 1.9.0 < 1.42.3) reste vraie.
- **ADR-062** arbitre les 2 hooks 1.9.0 non câblés (`gsd-ensure-canonical-path.js`,
  `gsd-update-banner.js`) : chaque hook confronté séparément à son propre contrat d'activation,
  absence correcte dans les deux cas — le câbler serait une régression, pas un correctif.

**Le point hérité : `check-state-integrity.sh` (ADR-063).** Une anomalie d'agrégation constatée
après la clôture de la Phase 20 — `completed_phases`/`total_plans`/`completed_plans` avaient
régressé silencieusement dans `.planning/STATE.md`, sans qu'aucun gate ne le détecte. Cause
identifiée sur pièce dans `@opengsd/gsd-core` 1.9.0 (dette d'artefact locale doublée d'un vrai bug
amont sur l'extraction du champ `Phase`, signalé à l'amont). Nouveau gate `check-state-integrity.sh`
(module `conductor`) : deux invariants — compteurs jamais régressés au sein du même jalon, une
seule ligne `^Phase:` dans le fichier — **câblé au job `gates` de la CI** dans cette même release
(il n'était auparavant dégainé que par sa propre suite, sur des dépôts synthétiques).

**Clôture de gouvernance.** Compteur de suites des 2 README recalé (44 → 45, une suite ajoutée par
cette phase), `.planning/ROADMAP.md` §Phase 21 recalé (5/5 plans, Requirements tranchés sans ID
`REQ-` inventé), ADR-063 §Code Impacté corrigée (23 → 25 cas), `team-kernel.md` porte désormais le
recoupement #1995/#2608, et `inject-mcp-tools.sh` nomme la cause fréquente (`--force` requis) sur
son rc=3 en mode fichier unique.

## [v2.44.0] — 2026-07-31

**La revue devient un étage de premier rang, piloté par le manager** (**ADR-060**). Modules
`conductor` **v1.17.0**, `dev-orchestrator` **v2.8.0**, `design-orchestrator` **v1.3.2**, les
3 bundles **v2.0.3**.

La revue sort du cycle interne de `vf-coder`, qui cesse d'être juge de son propre travail : le
manager dispatche `vf-reviewer` sur un nœud `revue-N` du plan de bataille et tient lui-même la
boucle correction → re-revue. La règle « pas de double revue » est **réécrite**, pas contournée.

**Origine.** Le **second rapport d'audit externe** du 2026-07-28 (lab tiers, tranche iOS en 5 lots
dont 2 parallélisés par worktrees, ~90 commits, suite passée de 177 à 331 tests). Ses 4 constats ont
été **vérifiés sur pièce avant l'ouverture de la phase** : 3 confirmés — dont 2 **plus solidement
que le rapport ne l'affirmait** — et 1 partiellement daté.

**ADR-051 révisée sur son seul point contesté.** La prémisse « les agents de revue ne compilent
jamais » confondait **produire** un verdict de compilation et **en vérifier** un. `vf-reviewer`
reçoit une allowlist MCP **nommée** (`vf-mcp-tools`, grammaire `<serveur>:<outil…>`) — jamais le
joker de serveur, moindre privilège préservé — et la révision porte **son prix écrit noir sur
blanc** : ~90 s de plus par revue, un slot de simulateur. `vf-reviewer` est le seul agent du dépôt à
porter cette clé ; `vf-auditer` et `vf-dev-manager` : zéro occurrence de `mcp`.

**La barrière d'écriture des 4 juges cesse d'être une fiction.** L'absence de `Write`/`Edit` dans
`tools:` était rouverte **silencieusement au runtime** par `memory: project` — prouvé par sonde. Les
juges portent désormais `disallowedTools: Write, Edit`, une contrainte réelle, sans qu'une ligne du
gate n'ait bougé. Le dépôt ne se contente pas de le *dire*, il l'**impose** à deux étages :
`check-agents.sh` avertit sur le couple `memory:` + `tools:` sans barrière, et `guard-agent-write.sh`
**dénie** l'écriture d'un juge non conforme — ce dernier appelait le checker sans `--strict`, donc
livré inerte, exactement le défaut de Phase 19 ; le correctif mord, vérifié par sonde discriminante.
`vf-design-judge`, seul à conserver `Bash`, **cesse d'affirmer une barrière qu'il n'a pas** et nomme
son angle mort : canal shell ouvert, retenue qui reste un engagement de prompt.

**Trois garde-fous non négociables** encadrent tout allègement, tirés des chiffres de l'audit :
jamais réduire le nombre de tests (mesuré : sur 90 s de build, les tests pèsent ~1 s — levier nul) ;
jamais alléger la revue sur le chemin critique produit (5 bloquants trouvés en une journée) ; aucun
allègement ne s'applique à un **diff de comblement** (9 puis 5 puis 4 défauts nés des correctifs de
revue eux-mêmes). Le troisième n'est pas une consigne de prompt : `dag.sh reopen` écrit
`review_regime_full` sur les descendants de revue et de jointure, et **rien** sur un dépendant
non-revue.

**Livrés aussi** : `--scope` et `review_regime` (périmètres gelés, rétro-compatibles sur les 4 DAG
suivis) ; `check-mission-invariants.sh` + `.planning/MISSION-INVARIANTS.md` (gate de zone morte,
contrat à 4 codes 0/3/4/64 où SAIN et INDÉTERMINÉ ne se confondent jamais) ; le périmètre explicite
des hooks tiers (`--third-party-prefix`), qui fait passer le hook d'agents de **0 ligne** à
**30 avertissements réels** sur un `~/.claude/agents` de 49 agents.

**Vérification — PASS partiel 5/7** (`20-VERIFICATION.md`), l'essentiel prouvé **par exécution** et
non par lecture. Les 2 réserves de SC5 ont été comblées avant la release : le gate d'invariants
n'avait **aucun appelant** — il devient le 4ᵉ geste non négociable de `vf-dev-manager`, après le
verrou de driver et avant le premier dispatch ; l'exclusion du seuil de tests (3ᵉ invariant)
passe d'une décision de planification à un **override humain daté**. **44 suites** vertes,
`check-agents --strict` vert sur les 6 dossiers d'agents.

## [v2.43.1] — 2026-07-28

**Une mission d'équipe travaille sur sa propre branche, jamais sur la branche par défaut**
(**ADR-059**). Modules `dev-orchestrator` **v2.7.1** et `design-orchestrator` **v1.3.1**.

Dès qu'un manager est dispatché (`vf-dev-manager`, `vf-design-manager`), il crée sa branche **avant
son premier commit**, y tient tous ses commits, et termine par une **PR laissée ouverte**. Le
manager ne merge jamais : le merge appartient à l'utilisateur — ADR-031 appliqué à l'intégration.

**Origine.** Constaté sur ce dépôt le 2026-07-28 : la mission Phase 19 a produit **32 commits
directement sur `main`**, poussés puis taggés. Aucun dégât — la mission était bonne — mais le recours
en cas de mission ratée était un `revert` en masse d'un historique déjà public et potentiellement
déjà cloné. Sur une branche, le recours est de **ne pas merger**. La PR fournit en prime le point de
relecture groupée qu'un rapport de fin de mission ne remplace pas : il est rédigé **par** l'agent qui
a fait le travail, et il est déjà trop tard quand on le lit. Le dépôt imposait une discipline stricte
en aval (« toute VERSION = un tag », gates de synchro, release GitHub) ; l'amont — comment le travail
arrive sur la branche par défaut — n'était pas gouverné du tout.

**Le déclencheur est le dispatch d'un manager**, pas la nature du travail : le travail
conversationnel direct (correctif, doc, cadrage mené dans le fil) reste hors de la règle — sinon
chaque échange créerait une branche.

**Cinq replis, pour qu'une mission n'échoue jamais faute d'appliquer la règle** : pas de dépôt git →
aucune branche, signalé dans le rapport ; dépôt sans remote → branche créée, pas de PR ; `gh` absent
ou non authentifié → branche poussée et URL de création de PR donnée ; **arbre sale au démarrage →
halt condition**, remontée à l'utilisateur, jamais un `stash` décidé seul ; `CLAUDE.md` du projet
cible imposant un autre flux → **le projet cible prime**, cohérent avec le contrat de brief où ses
conventions de livraison font déjà foi.

**Ne couvre pas** : l'isolation des vagues parallèles **à l'intérieur** d'une mission, qui partagent
le même arbre de travail. Une branche par mission ne les sépare pas entre elles — seul
`isolation: worktree` le ferait. Décision distincte, signalée par `vf-dev-manager` lors de la mission
Phase 19 et volontairement laissée ouverte.

**Risque assumé et écrit** : une mission livrée mais **non mergée** est un travail invisible pour la
suivante, qui repartira de la branche par défaut sans le voir. Le manager cite donc l'URL de la PR
dans son rapport, et le merge reste la responsabilité de l'utilisateur.

Le protocole vit en **un seul endroit** (`mission-contracts.md` §Isolation de branche) ; les deux
managers y renvoient sans le dupliquer.

## [v2.43.0] — 2026-07-28

**Le moteur GSD entre dans le périmètre de `/vf-update`** (Phase 19, livrée en mission d'équipe —
**ADR-058**). Modules `dev-orchestrator` **v2.7.0** et `conductor` **v1.16.0** (premier cas de deux
modules bumpés dans la même phase).

**Le trou fermé.** La migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0
n'atteignait **aucun poste déjà équipé** — seulement les installations neuves. Constaté sur un poste
tiers le 2026-07-28 : plugin à jour en **2.42.0**, cache rafraîchi le matin même, et moteur toujours
à **1.42.3** posé **12 jours** plus tôt, soit 2 jours après la livraison de la migration. Le poste
portait le *code* de la migration sans en porter l'*effet*, et rien dans l'interface ne le disait.
Le message final « Modules à jour sur disque » était **exact et trompeur à la fois**.

**Trois causes enchaînées, toutes fermées.** `detect_gsd()` renvoyait vrai sur le layout legacy via
un `||` écrit pour la tolérance dual-layout (Phase 10) et en faisait un `skip` : il devient un état
à **trois valeurs** — `absent` / `legacy` / `gsd-core` — où « legacy » est **actionnable**, pas
sauté. Aucun chemin de mise à jour n'appelait `ensure_gsd()` : le nouveau gate
`check-gsd-engine.sh` (contrat F13, exits 0/2/3, 15 cas de test) est sondé par `/vf-update`. Et
`log_legacy_cleanup_if_needed()` n'était joignable que par `/vf-init` et `/vf-calibrate` — un
garde-fou correct sur un chemin que le régime nominal n'emprunte jamais.

**La détection passe AVANT le stop « VibeFlow est à jour ».** Sans ce point, la correction n'aurait
rien corrigé : sur le poste constaté, le plugin était déjà à jour, donc `/vf-update` s'arrêtait à
l'étape 1 avant toute détection du moteur. L'étape 1 devient un **diagnostic à deux volets** —
version du plugin **et** état du moteur — et le message ne peut plus sortir seul quand le moteur est
legacy.

**Le piège de version, écrit noir sur blanc.** Le fork **repart de zéro** : `get-shit-done-cc` est
figé à 1.42.3 (déprécié sur npm) pendant que `@opengsd/gsd-core` vit à 1.8.0. Donc
**1.8.0 < 1.42.3 en semver**, et la doctrine « ne jamais downgrader » interdirait précisément le
geste à faire. La migration se décide sur le **nom du paquet et le layout du dossier**, jamais sur
la comparaison des numéros — un test fixe ce couple exact. Le plafond `@^1` reste inchangé, et le
repli legacy de la cascade à 4 niveaux est préservé pour les postes non migrés : c'est le **skip**
qui est corrigé, pas le repli.

**ADR-031 tenu de bout en bout.** Détecter et **proposer**, jamais installer sans accord : la
migration est une ligne de plus dans la confirmation existante, refusable sans effet de bord. Le
nettoyage legacy reste **affiché, jamais exécuté** — mais devient atteignable et **exact** :
`npm uninstall -g` n'est plus proposé que si le paquet est réellement installé en global (constaté
faux sur le poste audité — install `npx`, jamais globale, donc deux lignes sur trois étaient des
no-op), l'arborescence vide laissée debout par l'installeur est incluse, et l'état legacy est
**capturé avant l'install** — l'installeur amont supprimant lui-même le `VERSION` legacy, le message
ne pouvait sinon plus jamais sortir après coup.

**La ré-injection MCP devient une étape, pas une conséquence heureuse.** L'installeur `gsd-core`
réécrit `agents/gsd-executor.md`, classe l'injection ADR-051 en « local patch » et efface
`mcp__XcodeBuildMCP__*` du `tools:`. Sur un lab dont le `CLAUDE.md` interdit `xcodebuild` en shell,
l'exécutant ne peut alors plus builder du tout — ou le fait par le chemin interdit.
`ensure-deps.sh --migrate-engine` enchaîne donc sur `inject-mcp-tools.sh --force`, et le nouveau
mode `--verify` compare le `tools:` final aux serveurs déclarés dans le `.mcp.json` du lab.

**Le défaut que trois étages ont laissé passer — à retenir.** `--verify` a d'abord été livré
**inerte** : appelé sans `--force`, il écartait sa propre cible (`gsd-executor.md` ne porte pas le
flag `vf-mcp-consumer`) et sortait **toujours en 3** — jamais « conforme », jamais « serveur
manquant » — tout en crachant un `ERROR` à chaque bootstrap sur les labs sans `.mcp.json`. Revue de
code PASS, portabilité verte sur trois OS, audit sécurité 6/6 : aucun ne l'a vu. Seule la **mutation
du bloc livré** l'a révélé — sa suppression complète laissait la suite à 73 OK / 0 KO. Deux causes
nommables et réutilisables comme sondes : un compte rendu qui prouve une **présence**
(`grep -c 'verify' → 7`) au lieu d'un comportement, et des tests qui exercent une forme de commande
que la production n'émet jamais. Corrigé avec un contrat de relais explicite (seul `rc=1` alarme,
`rc=3` reste INDÉTERMINÉ informatif) et un cas de test qui exerce le chaînage réel.

**Reste ouvert, inscrit à `CONCERNS.md`** : la sonde cross-module `conductor` → `dev-orchestrator`
s'éteindrait **sans aucun signal** si l'engine cessait de matérialiser les scripts de tous les
modules à plat dans le même `.claude/scripts/`. Le silence sur script absent est voulu — un lab
content ou growth ne doit rien voir du moteur GSD — mais il rend le mode dégradé indiscernable du
nominal, même famille que le trou que cette version ferme.

## [Non versionné] — 2026-07-26

**Correctif `_internal/merge-hooks.sh`** (vague 11-04, Phase 11 — intégration migration GSD).
Le matching des scripts référencés dans un hook merge est désormais ancré aux frontières de
chemin réelles (fin du bug de sous-chaîne : un hook référençant `archive.sh` aurait pu, à tort,
matcher et donc détruire une entrée tierce `gsd-archive.sh`). Fin également de la réutilisation
de groupes mixtes lors du merge de hooks — un groupe qui mélange des scripts de provenances
différentes n'est plus recyclé, un nouveau groupe est créé à la place. Entrée non taggée : ne
déclenche pas de release, sera absorbée par le prochain bump de `VERSION` racine.

## [v2.42.0] — 2026-07-28

**Signaux de démarrage du moteur de dev** (Phase 17, livrée en mission d'équipe). `dev-orchestrator`
était le seul module structurant **sans aucun hook** — conséquence directe :
`discover-unintegrated-docs.sh`, livré en Phase 13 avec un contrat propre et testé, n'était jamais
appelé automatiquement. Le module reçoit son premier fragment `hooks/hooks.json`, câblé par l'engine
sans le modifier (`merge_module_hooks` gérait déjà le cas). Trois scripts constatent des **FAITS** au
`SessionStart` et injectent des lignes courtes et **auto-portantes** — chacune porte son propre geste,
sur le modèle de `[planning-debt]`. Module `dev-orchestrator` **v2.6.0**.

**`check-dev-bootstrap.sh` — le continuum de démarrage en un seul script.** Silence si ni code ni
`.planning/` ; signal `onboard` si du code sans `.planning/` ; signal `bootstrap` listant les items
manquants (`config.json`, `codebase/`, ROADMAP sans phase) ; signal d'orientation `gsd-engine` si
complet. Les signaux sont **prouvés mutuellement exclusifs par test**, pas par construction.

**Le signal `gsd-engine` ferme un trou de routage constaté sur ce dépôt le 2026-07-27** : une demande
de conception adressée au Claude principal est partie sur du brainstorming générique alors que le
projet tournait sous GSD avec une phase inscrite. Cause structurelle — `planning-core` se retire
quand GSD tient le projet (`--defer-to-gsd`) et aucun module ne prenait le relais ; le routage de
`vibeflow-dev` n'existe que si son `AGENT.md` est lu, donc seulement une fois l'agent invoqué. Le
signal lit le frontmatter réel de `STATE.md` (milestone, phase, statut) et **retombe en silence s'il
est illisible** — jamais d'état inventé. Arbitrage humain assumé : un projet sain coûte **1 ligne,
pas 0**, le critère d'acceptation initial ayant été amendé en ce sens (il contredisait la spec et les
deux critères voisins de la même feuille de route).

**Les deux autres signaux.** `discover-unintegrated-docs.sh --hook` agrège le compte en une ligne de
façon **additive**, sans toucher au contrat historique (`grain<TAB>chemin`, exits 0/3/64) consommé
par `ingestion-flow.md` ; `--hook` avec `--quiet` sort en 64. `check-doc-drift.sh` signale au-delà
d'un seuil de commits de code sans mise à jour de doc (défaut 20, réglable) et reste silencieux hors
dépôt git ou sans commit de doc.

**Contrat advisory vérifié par exécution.** Les trois scripts sont en lecture seule : aucune
écriture, aucun `exit 1`, aucun blocage de tour — la confirmation humaine reste devant chaque geste
proposé (ADR-031). Vérifié sur 5 frontmatter hostiles (injection shell, octet `0x01`, délimiteur
tronqué) qui rendent tous stdout vide et exit 3, et sur un `node_modules` de 20 000 fichiers traversé
en 0,007 s.

**Portabilité prouvée par exécution, pas déclarée.** Compteurs **identiques** sur macOS bash 3.2.57,
Debian 12 bash 5.2.15 et Ubuntu 24.04 — l'OS exact du runner. L'égalité des compteurs est le vrai
résultat : elle exclut le **test sauté silencieusement**, qui était le mode de panne dangereux (la
régression CI du 2026-07-27 avait coûté 6 fixes de portabilité). Aucun edit de `ci.yml` nécessaire,
les suites tombent dans son `find`. Suites du dépôt : 39 → **41**.

**Deux faux verts débusqués dans les tests** — aucun dans le code livré. Le cas 7 de
`test-discover-unintegrated-docs.sh` était **tautologique** : sa fixture ne citait que le glob, jamais
le basename, donc il passait avec ou sans le filtre qu'il prétendait verrouiller — prouvé par
mutation, et re-prouvé discriminant après correctif. Et la boucle T21, filet censé garantir les
invariants du contrat advisory, **omettait `discover-unintegrated-docs.sh`**, le seul des trois à
utiliser `mktemp` ; le comblement a lui-même révélé un défaut latent du helper
`t21_strip_awk_block`, aveugle à `awk -v x=… '`.

**Deux dettes inscrites au `CONCERNS.md`, non corrigées (hors périmètre).** Le **verrou de driver est
déclaratif, pas contraignant** (HIGH) : aucune garde en écriture ne refuse un commit à une session
sans verrou — constaté le 2026-07-27, deux missions ont commité en parallèle avec des horodatages
entrelacés, ce qui a produit une collision de numérotation de version. Le **gate ADR-044 est un faux
vert dans son invocation nue** (MEDIUM) : `check-agents.sh` sans argument sort `exit 0` sans rien
linter (`.claude/agents` absent du dépôt), et `AGENT.md` étant à la racine du module, il échappe
aussi à la boucle CI sur `plugin/*/agents` — seul `--file` prouve quelque chose.

## [v2.41.0] — 2026-07-27

**Cloisonnement complet des dispatches d'agents** (Phase 16, livrée en autonomie complète). Ferme
les deux trous escaladés par la mission de la Phase 15. `check-agents.sh` **lint désormais le
contenu** du champ `tools:` — syntaxe des allowlists (parenthèse fermée, séparateurs, charset) et
existence de chaque nom, sur `tools:` comme `disallowedTools:` : jusqu'ici, des noms d'agents
inventés, une parenthèse non fermée ou des outils inexistants passaient tous `--strict` en vert. La
suite `test-check-agents` passe de 38 à **58 axes**.

**Résolution graduée du piège natifs/externes.** La sévérité est indexée sur ce qui est vérifiable
indépendamment du périmètre installé : syntaxe → erreur dure (ne dépend d'aucun scope) ; nom d'outil
hors du set fermé documenté → warning, erreur en `--strict` ; **nom d'agent non résolu → warning même
en `--strict`**, erreur seulement sous le mode opt-in `--resolve-agents=strict`, réservé à la CI —
seul endroit où l'univers complet des agents du repo est connu. Mesure à l'appui : 22 entrées non
résolvables sur la baseline, dont **aucune n'est un bug** (types natifs comme `general-purpose`,
agents `gsd-*` de `@opengsd/gsd-core`, agents d'autres modules non installés). La doc officielle ne
fige pas la liste des types natifs : en faire une erreur serait parier sur une liste mouvante, pari
que le dépôt a déjà payé au prix de 66 faux positifs. L'option « manifeste externe » a été écartée
sur preuve de code (`copy_module_scripts()` ne globbe que `*.sh|*.mjs|*.js` — un fichier de données
ne serait jamais posé chez l'utilisateur) : tout est inline. Bonus, `--third-party-prefix` **ferme la
dette connexe** des 66 faux positifs du scope user.

**Allowlists posées sur les 3 workers dev** — `vf-coder` (22 noms), `vf-reviewer`
(`gsd-code-reviewer`), `vf-auditer` (`gsd-security-auditor`) — après **double recensement
indépendant en parallèle**, la seconde dérivation interdite de lire les rapports de mission, les
allowlists existantes et `CONCERNS.md`. Accord total sur deux workers ; écart de 5 noms sur
`vf-coder` (21 vs 18), union retenue au titre du coût d'erreur asymétrique. Fait discriminant :
`vf-coder` a le tool `Skill`, donc une expansion transitive que les deux autres n'ont pas.

**Correction de portée doctrinale — une allowlist n'est pas un sandbox runtime.** La doc officielle,
désormais citée verbatim dans l'en-tête du script, est explicite : dans la définition d'un
sous-agent, le runtime **ignore** la liste de noms entre parenthèses ; seule la présence de
`Agent`/`Task` dans `tools:` compte. Une allowlist `Agent(x, y)` est donc un **contrat documenté,
enforcé par ce lint et par lui seul** — elle ne redevient une restriction runtime que pour un agent
incarné en thread principal (`claude --agent`). Vaut rétroactivement pour les allowlists des deux
managers posées en v2.40.0.

**Ce que les juges ont rattrapé**, sur des classes disjointes : T19/T19e étaient **tautologiques**
(grep sur toute la ligne `tools:` — un nom retiré de l'allowlist mais replacé en `Bash(...)` laissait
la suite verte à 50/0 alors que le dispatch était perdu), deux faux-bloquants du lint neuf (champ
quoté ; ligne vide en liste bloc faisant perdre silencieusement les entrées suivantes), et
`--resolve-agents=<valeur inconnue>` qui **dégradait le gate en silence** — une typo YAML aurait
désactivé le monde fermé sans un mot.

40 suites vertes, 6/6 modules `--strict` exit 0, 6/6 en monde fermé. Deux entrées retirées de
`CONCERNS.md`. Modules : conductor v1.15.0, dev-orchestrator v2.5.0.

## [v2.40.0] — 2026-07-27

**Collaboration inter-équipes dev ↔ design : étages croisés sous un seul manager** (Phase 15,
option A validée par 7 tests empiriques). Les deux équipes de mission cessent d'être étanches sans
jamais s'imbriquer : un seul verrou de driver, un seul DAG, un seul rapport de mission. En mission
dev, `vf-dev-manager` insère des nœuds `craft:<écran>` (`vf-crafter`) avant l'exécution et
`critique:<écran>` (`vf-design-judge`) en parallèle de la revue code — décision de jugement au plan
de bataille, seuil design bloquant au même régime que l'équipe design, étage sauté et signalé si la
DA manque (next step DA-INIT, jamais de DA inventée). En mission design, `vf-design-manager` gagne
un étage d'implémentation opt-in (`livrable: specs|specs+implementation`) où `vf-coder` incarne les
specs du crafter, avec double juge en parallèle (re-critique DA **et** revue de diff) et budgets
anti-thrash séparés 3 + 3 par écran. Le brief de mission gagne les champs `design: auto|force|off`
et `livrable:` ; le digest croisé embarque la DA vers les workers design et les conventions code
vers les workers dev (≤ 30 lignes, le disque fait foi). `vf-auto` aiguille enfin les missions
entièrement design vers `vf-design-manager` (règle simple : design pur → design, tout le reste →
dev). Cloisonnement **structurel** : allowlists `Agent(...)` sur les deux managers (18 noms côté
dev, 6 côté design) — un manager ne peut pas dispatcher l'autre. Deux corrections de vérité en
cours de route : `check-agents.sh` ne lint **pas** le contenu du champ `tools:` (l'enforcement réel
passe par les tests de suite, prouvés rouges par mutation), et le recensement initial de l'allowlist
dev omettait 4 agents dispatchés via les skills du manager (fin de milestone, ingestion de cadrage,
re-validation de plan) — trouvés par audit indépendant. Nouvelle référence
`conductor/references/mission-cross-team.md` (Pattern D). Kernel intact : aucune modification de
`dag.sh` ni `driver-lock.sh`. Suites : 43 dev-orchestrator, 12 design-orchestrator, 36 dag,
26 driver-lock — 0 KO. Modules : dev-orchestrator v2.4.0, design-orchestrator v1.3.0,
conductor v1.14.6. Escaladé et non livré volontairement : le lint réel dans `check-agents.sh` et le
scoping `Agent` des workers (`vf-coder`/`vf-reviewer`/`vf-auditer`) — le chemin indirect
manager→worker→manager reste ouvert au dispatch, l'invariant tenant par le verrou de driver.

## [v2.39.0] — 2026-07-26

**Migration du moteur GSD : `get-shit-done-cc` → `@opengsd/gsd-core@^1`** (clôture du milestone
`gsd-migration`, VOC-02). L'original est déprécié et abandonné ; VibeFlow bascule sur le
successeur communautaire — à parité fonctionnelle prouvée sur install réelle sandbox — avec un
**plafond semver `^1`** (fraîcheur sans pin figé, saut de majeure = décision humaine, arbitrage
post-audit). Livré en mission d'équipe (6 vagues, 26 commits) : `ensure-deps.sh` migré (piège
`command -v gsd-sdk` neutralisé, layout dual `gsd-core`/legacy, étapes destructives affichées
jamais exécutées — ADR-031 prouvé par sentinelle), références SDK → **`gsd-tools`** (le paquet
`@opengsd/gsd-sdk` est lui-même déprécié ; parité des 3 requêtes prouvée), routage **`gsd-onboard`**
pour le brownfield (BOOT-04 conservé), canal « une seule voix » (`gsd-next` et `gsd-mempalace-*`
délibérément non routés, frontières machine dans `check-overlaps`), durcissement `merge-hooks.sh`
(matching ancré + fin de co-location, prouvé rouge→vert) + nouvelle suite `test-gsd-cohabitation`
sur le settings.json réel de l'installeur, `model_profile: balanced` explicite (doctrine
« planner=opus, workers=sonnet » machine-enforced côté moteur). 39 suites vertes, dry-run 3 scopes,
vérification goal-backward PASS, audit sécurité sans bloquant. Modules : dev-orchestrator v2.3.1,
planning-core v2.5.2, conductor v1.14.2. Dossier d'étude complet dans
`.planning/phases/10-etude-migration-gsd/`.

## [v2.38.0] — 2026-07-26

**Documentation niveau framework, module par module.** Le README de chaque module devient sa
documentation canonique — même structure partout : tagline, Type/Version/Dépendances, Quoi,
**Installation** (prérequis réels, ordre d'install explicite), **Démarrer** (premier usage
guidé en 5 min), **Usage**, **Référence** exhaustive vérifiée sur disque, **Limites**. 10
modules montés au standard (design-orchestrator, kpi-analyst, mobile-test, mobile-test-team,
skill-creator, audit-architecture, infrastructure-audit et les 3 bundles métier — qui
déclarent désormais leur en-tête Version, gaté 17/17). Pas de dossier de doc parallèle : une
seule source, zéro nouvelle surface de drift. Vitrine racine (FR+EN) : nouvelle section
« Au-delà du dev — un lab pour chaque métier » (pipeline `/vf-new-lab` en mermaid, design en
équipe avec juge frais /100, bundles métier, kpi-analyst) + hub de doc vers les README de
modules. Embarque aussi : lexique P3-P8 réaligné sur le Core v4.2 canonique (reference
v2.5.2, arbitrage 2026-07-26). Découverte tracée en Limites d'infrastructure-audit :
`known-versions.txt` n'est jamais posé par l'engine (fail-open, pose manuelle).

## [v2.37.0] — 2026-07-26

**Clôture du milestone `vf-routing` — le pont spec → feuille de route est livré** (Phase 13,
exécutée en mission d'équipe). Une spec ou un plan écrit devient des étapes de la feuille de
route **sans quitter le modèle agentique** : le fait est outillé par
`discover-unintegrated-docs.sh` (quels cadrages ne sont pas encore intégrés — 6 registres de
citation, détection du grain spec/plan, 16 cas de test, revue à coût d'erreur asymétrique :
2 bloquants trouvés et corrigés), et l'agent `vibeflow-dev` porte la doctrine
`references/ingestion-flow.md` (typage en prose, manifest YAML construit par l'agent,
délégation `gsd-ingest-docs --mode merge` / `gsd-import`, gate BLOCKER jamais contourné,
cap 50 signalé). **Aucun verbe-façade recréé** — la phase, écrite avant la bascule agentique
autour d'un `/vf-ingest`, a été redéfinie sans verbe. La confirmation humaine ADR-031 précède
tout appel d'ingestion, ancrée **nominativement** dans `vibeflow-dev` ET `vf-dev-manager`
(échappatoire trouvée par l'audit BRDG-03, fermée en v2.2.1 du module). `dev-orchestrator`
v2.2.1. Premier usage réel de l'outil : une citation canonique perdue à l'archivage du jalon
`vfdo-v1.0` retrouvée et restaurée. Les 3 phases du milestone (12, 13, 14) sont complètes.

## [v2.36.2] — 2026-07-26

**Remédiation de l'audit « périmé »** (planning + docs, 5 commits). Côté distribution :
README de modules réalignés sur l'état réel — `validator` (5 audits, dépendance
`audit-architecture` rétablie, chemin d'install corrigé, skills fantômes purgés, densité vraie
249/250 L), `conductor` (team-kernel enfin documenté : `dag.sh`, `driver-lock.sh`, rapports
typés ; skill `vf-update`, hooks, 13 scripts, dépendance `skill-creator`/ADR-047), `reference`
(12 patterns / 5 skills / 42 templates / Core v4.2 à 9 principes, contenu distribué inclus :
`VERSION.md`, `README-CLIENT.md`, `lexique.md` gagne P9), `consolidator` (5 piliers, arbre
complet, `/consolidate` → `/consolidator`, ADR-031 → ADR-056), `planning-core`,
`software-architecture`, `dev-orchestrator` (`gsd-sketch` → `vf-sketch`, kernel consommé depuis
`conductor`). Registre ADR : ADR-053 relocalisé (kernel → conductor, v2.34.0), ADR-052 remet
`plugin/reference/` en source, ADR-035 gagne sa définition canonique. Les 14 en-têtes
`**Version**` des README de modules réalignés et **gatés** : `check-version-sync.sh` gagne les
contrôles 8 (en-tête Version ↔ VERSION du module) et 9 (compte de suites ↔ découverte CI), et
son grep « N modules » mort depuis la v2.36.1 échoue désormais bruyamment au lieu d'être sauté
en silence. Divers : marqueur de conflit git purgé de `conductor/CHANGELOG.md`,
`/vibeflow-install` présenté comme skill dans les 2 README. Côté planning (non distribué) :
Phase 13 redéfinie **sans verbe** (ingestion portée par l'agent), socle `.planning/` remis à
l'heure, cartographie codebase régénérée, PROJECT.md rouvert.

## [v2.36.1] — 2026-07-26

**Refonte vitrine des README** (FR+EN), inspirée d'ECC (spécificité, tables) et GSD (accroche
par le problème) : dev-first, 3 diagrammes mermaid (cycle spec-driven, équipe de mission avec
rapports typés et nœud gelé, architecture kernel/orchestrateurs/gouvernance), efficience
chiffrée et mémoire en avant, tableau des 17 modules replié en `<details>`. Corrections :
note « bundles WIP » périmée, Hub kpi-analyst adouci, handle GitHub de Samuel. Gate :
`check-version-sync` invariant n°7 — l'historique README en tête doit être la VERSION
courante (c'est lui qui a exigé cette entrée).

## [v2.36.0] — 2026-07-26

**Recettes réelles (UAT) sur labs vierges + corrections** — deux labs sandbox installés par le
vrai engine et joués par des agents neufs (rapport : `reports/uat/2026-07-25-uat-express-et-dev.md`) :

- **Verdicts** : le mode express tient son contrat (~11 min 30 < 15 min, fabrication réelle
  d'un skill avec 2 évals PASS en tâche de fond, Gate C 3/3) ; le protocole de mission
  (lock → DAG → pipelining N/N+1 → rapports typés → reopen → release) est **exécutable par un
  agent qui ne l'a pas écrit**, scripts du kernel conformes à 100 % (mission pomodoro réelle,
  7 commits, app fonctionnelle démontrée).
- **16 frictions corrigées**, dont 3 bloquantes : un lab frais échouait son propre
  `check-agents --strict` (skills plugin déclarés, résolution par nom de dossier — corrigée
  par frontmatter `name:`) ; templates de registres absents de la baseline (embarqués dans
  consolidator v1.8.0) ; cascade `$S` qui préférait le scope user au lab courant. Doctrine
  `human_needed` en autonome tranchée : **geler le nœud porteur**, jamais « continuer ».
- **Dépendance team-kernel déclarée** : `requires: conductor` sur les 5 modules consommateurs
  (fermeture resolve-deps incomplète depuis l'extraction v2.34.0).
- **CI : job « lab frais »** — installe la baseline dans un lab vierge et exige qu'elle passe
  ses propres gates sans intervention (la CI testait le repo, pas l'expérience installée).
- 9 modules bumpés (conductor v1.14.1, consolidator v1.8.0, validator v1.3.1,
  dev-orchestrator v2.1.1, planning-core v2.5.1, design-orchestrator v1.2.1, bundles ×3 v2.0.1).

## [v2.35.0] — 2026-07-25

**La promesse multi-métier est tenue : les 3 bundles métier sont des modules réels** (fin du
doc-only), chacun avec une équipe complète sur le team-kernel, un juge read-only à rubric /100
avec critères éliminatoires, des Iron Laws machine-testées et une suite de tests dédiée :

- **growth-bundle v2.0.0 (`proposable: true`)** : `vf-growth-manager` (DAG stratégie →
  production → gate → humain → analyse par campagne) + channel-strategist / copywriter-sequences /
  campaign-analyst + `growth-quality-judge` (claims sourcés ET consentement/anti-spam
  éliminatoires). Tout envoi réel human-gated ; l'analyste refuse toute campagne sans preuve
  de lancement humain ; métriques sourcées ou `low` (Iron Law kpi-analyst). 12 tests.
- **business-pilot-bundle v2.0.0 (`proposable: true`)** : `vf-business-manager` (DAG
  commercial → delivery → gate → humain → finance par dossier client) + commercial / delivery /
  finance + **`quality-gate-client`** — le gate « à fabriquer » du finding F16 enfin livré
  (périmètre vendu et montants sourcés éliminatoires, seuil 80). Double Iron Law : aucun envoi
  client sans validation humaine, aucun chiffre financier inventé. 14 tests.
- Le catalogue d'install propose désormais les **3 bundles** ; messaging racine et tableaux
  README alignés sur le réel (équipes, versions, types).

## [v2.34.0] — 2026-07-25

**Vague 3 de l'audit croisé — universalisation** (clôt le programme d'audit du 2026-07-25) :

- **Team-kernel (conductor v1.14.0)** : `dag.sh` + `driver-lock.sh` extraits en socle
  transverse, `team-kernel.md` pose le contrat universel (invariants du kernel — lock, DAG,
  rapports typés, HALT, digest, cloisonnement — vs paramètres du métier : spécialistes,
  définition du « vert », gates). Le dev-orchestrator devient l'implémentation de référence.
- **Équipe design (design-orchestrator v1.2.0)** : première instanciation non-dev —
  `vf-design-manager` + `vf-crafter` + `vf-design-judge` (juge frais, rubric /100 : DA /40 +
  copy/hiérarchie/couleur/typo/spacing/accessibilité, seuil 70, 3 tours max).
- **Bundle content matérialisé (content-bundle v2.0.0, `proposable: true`)** : de doc-only à
  module installable — manager + strategist/writer/repurposer + juge de clarté (chiffres
  sourcés éliminatoires, seuil 80), publication toujours human-gated, 12 tests. Preuve
  d'universalité : le catalogue d'install le propose désormais.
- **Pipelining N/N+1 (dev-orchestrator v2.1.0)** : discuss/plan/execute modélisés par étape
  dans le DAG, cadrage+plan de N+1 pendant l'exécution de N, plan provisoire re-validé.
- **Lab express (conductor)** : opérationnel en ≤ 15 min — 3 questions, dérivations `[DÉRIVÉ]`
  assumées, Gate C intact (test anti-régression), fabrication en tâche de fond, dette
  d'express affichée. Scope d'install pré-sélectionné (installer).
- **ADR-057 — frontières outillées avec les briques tierces** : `check-overlaps.sh` (advisory,
  7 paires, doctrine F13), abandon du « sole authorized channel », frontières descriptives
  (debug, revues, skill-creator, mobile, brainstorm).

## [v2.33.0] — 2026-07-25

**Vague 2 de l'audit croisé — bascule agentique** (arbitrage Samuel, spec
`docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) :

- **dev-orchestrator v2.0.0 (breaking)** : les 29 verbes-façades `/vf-*` disparaissent — GSD
  redevient l'interface directe du quotidien. L'agent `vibeflow-dev` détecte l'intention et
  invoque les briques directement (carte d'intention **unique**, fin de la table ×4, de la rule
  de préséance et du reframe de vocabulaire). Survivent `vf-auto` (porte d'autonomie) et
  `vf-dev` (incarner l'agent). Tests refondus (26 OK), README et pipeline réécrits.
- **Manager agentique** : brief en langage naturel mappé par le manager, **digest de mission**
  ≤ 30 lignes par mandat (amortit ~100-200k tokens de relecture par étape), hygiène
  documentaire déclenchée aux bons moments (drift → nœud `gsd-docs-update`), next step ferme
  en fin de mission, rapports de workers réduits au bloc typé (détail sur disque).
- **ADR-045 en 1 saut (mobile-test-team v1.4.0)** : `vf-test-orchestrator` porte lui-même la
  recherche documentaire (WebSearch/context7) — fin de l'escalade à 3 étages.
- **Gouvernance proportionnée au profil** (planning-core v2.5.0, validator v1.3.0,
  consolidator v1.7.0, conductor v1.13.0) : Stop-hook `warn` en profil léger (lu dans
  `.planning/config.json`, machine-enforced, 4 tests), validator Phase 4 opt-in avec score
  renormalisé, EVALS créé à la première éval réelle en léger, cadences réalistes pour un solo.
- Références externes alignées (conductor, design-orchestrator, planning-core, commands) ;
  messaging racine basculé « modèle agentique ».

## [v2.32.0] — 2026-07-25

**Vague 1 de l'audit croisé du 2026-07-25** (5 audits parallèles, rapports dans `reports/`) —
le framework s'applique enfin sa propre doctrine d'enforcement :

- **CI GitHub Actions** : 31 suites de tests + `check-agents --strict` + gates de release,
  branchés sur push/PR. Fin du « vert non mérité » : 7 gates sortaient exit 0 sur cible
  absente → doctrine exit 3 = indéterminé (`--strict`/`--allow-empty`), engine d'install qui
  avorte si le merge des hooks de gouvernance échoue. Test rouge et test flaky corrigés
  (isolation HOME/cwd).
- **Équipe de mission optimisée** : workers et juges en sonnet (fin du tout-opus), dispatch
  **parallèle** de la frontière DAG et des juges (revue ∥ audit), fin de la double revue,
  cadrage non-interactif explicite de `vf-coder` (plus de checkpoint interactif mort).
- **Chasse aux fantômes** : les 3 skills inexistants du frontmatter validator (F3), la commande
  `/checkpoint` citée dans 13 fichiers (→ `/vf-audit`), les gates `human-validator` /
  `quality-gate-client` des bundles marqués « à fabriquer » (F16), le chemin `assets/` cassé du
  template skill-creator (F4, dédupliqué → pointeur).
- **ADR assainies** : définitions canoniques des 9 ADR héritées les plus citées ;
  **scission ADR-031/ADR-056** (validation humaine vs vigilance runtime — un même identifiant
  portait deux doctrines).
- **Versions honnêtes** : 13 versions fausses du tableau README corrigées, « 14 verbes » → 31,
  kpi-analyst ajouté, historique dédupliqué vers ce CHANGELOG, `scripts/bump.sh` (générateur
  idempotent), globs mobile discriminants (fin des faux positifs Next.js), messaging
  « dev + design + Lab Factory ». 14 modules patch-bumpés.

## [v2.31.1] — 2026-07-25

**Alignement des fichiers de version** : `software-architecture` et `kpi-analyst` ont livré leurs
correctifs de portabilité Windows en v2.29.0 (CHANGELOG et `module.json` bumpés tous les deux)
mais leurs fichiers `VERSION` étaient restés en arrière — or c'est `VERSION` que lit l'engine,
donc le registre annonçait un numéro périmé. Aucun utilisateur n'a été privé du correctif (les
changements sont dans `scripts/`, que le resync de gouvernance recopie), mais le registre de
versions dit désormais la vérité (software-architecture v1.5.1, kpi-analyst v1.0.1).

## [v2.31.0] — 2026-07-25

**Routage fin des intentions** : trois niveaux de routage (descriptions déclencheuses à
contre-exemples croisés, rule globale de préséance des verbes, doctrine exhaustive chargée
on-demand couvrant les 65 skills du moteur). 19 verbes `/vf-*` neufs — dev-orchestrator passe de
14 à 31, design-orchestrator gagne `/vf-sketch`. La table de l'agent ne cite plus aucune cible
interne : elle route vers un verbe, le verbe connaît sa cible. Aussi : purge des mentions d'un
projet tiers dans tout le dépôt, axes de test T5/T11 bornés à leur module, sémantique de
chargement des rules corrigée, gabarit de description sur les trois verbes du conductor
(dev-orchestrator v1.8.1, design-orchestrator v1.1.0, conductor v1.12.2).

## [v2.30.0] — 2026-07-25

Frontière d'altitude entre le planning VibeFlow et le moteur de planning de développement
(ADR-055) : planning-core **v2.4.0** — `vf-planning` ne pose plus le tronc d'un projet de code
(frontmatters `STATE.md` incompatibles, double injection `SessionStart`, concurrence au
matching), il tient l'altitude lab et redirige vers le bon verbe ; nouveau
`detect-gsd-engine.sh` (fait seul, 4 exits priorisés, marqueur borné au frontmatter), doctrine
`references/gsd-handoff.md`, flag opt-in `--defer-to-gsd` sur deux hooks (défaut inchangé),
guard Stop bloquant conservé en exception motivée ; `vf-new-lab` + routage conductor + 3 README
réalignés.

## [v2.29.0] — 2026-07-23

**Portabilité Windows (ADR-054)** : wrapper `jqx` normalisant le CRLF dans tout l'engine (le jq
Windows natif cassait l'install : `planning-core\r`, corruption silencieuse du catalogue),
préflight d'install (jq + sonde d'EXÉCUTION python3 vs stub Store + bash dans le PATH) avec
commandes par OS, `.gitattributes eol=lf`, chemins de scripts pleinement qualifiés, résolution
python dans `merge-hooks.sh` **et dans les hooks de garde runtime** (le stub Store passe
`command -v python3` : gardes inertes en silence), préfiltres mémoire compatibles antislashs
(les chemins Windows n'atteignaient jamais le python qui savait les traiter), signal
SessionStart quand les gardes sont inactives, gate de synchro des versions, droit de
réutilisation privée pour les élèves (licence) — causes racines remontées par deux rapports
terrain rejouables d'élèves sous Windows (conductor v1.12.1, consolidator v1.6.1,
software-architecture v1.5.1, planning-core v2.3.1, kpi-analyst v1.0.1).

## [v2.28.0] — 2026-07-22

R&D mémoire-swarm shippée (ADR-052/053) : consolidator **v1.6.0** pilier mémoire vivante (couche
`knowledge/` fichier-par-entrée, décroissance par demi-vie de catégorie + supersession non
destructive, `decay-pass.sh`) ; dev-orchestrator **v1.7.0** contrôle de flux swarm (lock de
driver unique + DAG ready/blocked avec rendu `tree` + rapports de worker typés, résolution de
scripts scope-robuste) ; conductor **v1.12.0** détection legacy scope-aware + nudge
SessionStart ; mobile-test-team **v1.3.0** rapports typés ; fix engine uninstall (skills
imbriqués + tests).

## [v2.27.1] — 2026-07-20

Gate agents fiabilisé (2e vague audit hooks conductor : parseur YAML, anti-trappe fail-closed,
portée lab, filet debug-research) (conductor v1.11.3).

## [v2.27.0] — 2026-07-20

Guard planning par attribution de session (ADR-050 amendée) + durcissement global des hooks du
harnais (29 findings corrigés, 282 checks verts) (planning-core, software-architecture,
conductor).

## [v2.26.0] — 2026-07-19

Allowlist MCP des agents exécutants dérivée du lab (ADR-051) : les sous-agents voient enfin les
serveurs MCP du projet (XcodeBuildMCP, mobile-mcp, DB métier…) via le flag `vf-mcp-consumer` +
injection idempotente à l'install depuis `.mcp.json` ; `gsd-executor` patché après l'install GSD
(dev-orchestrator v1.6.0, mobile-test-team v1.2.0, conductor v1.11.1).

## [v2.25.0] — 2026-07-16

Orchestrateur métier systématique + durcissement gouvernance (ADR-048/049/050) : `vf-new-lab`
pose un orchestrateur métier dès ≥2 agents métier + skill de boucle de mission ; backups mémoire
isolés avec rotation intégrée ; hooks planning (lecture index-first au start, mise à jour
bloquante au end) (conductor v1.11.0).

## [v2.24.0] — 2026-07-11

skill-creator ajouté à la baseline d'install du conductor (ADR-047) : le canal unique de
création de skills est désormais posé d'office via la fermeture transitive du conductor —
corrige le fan-out de `vf-new-lab` vers un sous-agent jamais installé (conductor v1.10.0).

## [v2.23.0] — 2026-07-09

Équipe manager de mission (ADR-046) : vf-dev-manager + workers spécialisés (arborescence à
contexte minimal), détection de mission par le router, bascule taille de vf-auto
(dev-orchestrator v1.5.0).

## [v2.22.0] — 2026-07-08

**Recherche-doc avant debug (ADR-045)** : phase de recherche documentaire obligatoire (context7
+ issues GitHub / release notes) **avant** tout debug empirique intensif, dès qu'un bug touche
une lib/framework/natif/version d'OS-SDK ou qu'un correctif a déjà échoué. Nouvelle règle
canonique path-scopée `doc-research-before-debug` (`software-architecture` **v1.4.0**),
**référencée** (non dupliquée) par `vf-debug` (pré-étape) + le routage `vibeflow-dev` + 6ᵉ
garde-fou autonome avec `maxResearchRoundsPerFlow` (`dev-orchestrator` **v1.4.0**), la boucle de
test mobile (gate `vf-test-orchestrator` + remontée `doc-research-required` de `vf-app-fixer`,
`mobile-test-team` **v1.1.0**), et la Phase 0 du template `debugger` (`reference` **v2.4.0**) ;
nouveau contrôle machine `check-debug-research.sh` branché en Phase 2 du validator (`conductor`
**v1.9.0**, `validator` **v1.2.0**).

## [v2.21.0] — 2026-07-08

+ **design-orchestrator** v1.0.0 : agent routeur `vibeflow-design` + verbe `/vf-design` (langage
naturel design → workflow), **générique multi-stack** (web/mobile/desktop), chaîne d'outils
design pilotée en coulisse avec dégradation gracieuse ; `dev-orchestrator` **v1.3.0** route les
phases de design vers `/vf-design` et installe `design-orchestrator` d'office (`requires`).

## [v2.20.0] — 2026-07-07

Milestone doctrine dev : `software-architecture` **v1.3.0** = foyer des philosophies de dev
(DRY/KISS/YAGNI ajoutés, Clean Architecture/Clean Code nommés, carte TDD, **gates Nyquist +
Decision Coverage absorbés**) ; module `feature-dev-gates` **supprimé** + nettoyage moteur des
modules retirés (rule orpheline nettoyée à `update --all`, test T7) ; `audit-architecture`
**v1.0.1** (Instance C dé-dupliquée, description legacy corrigée) ; `reference` source unique
des 3 axiomes d'enforcement.

## [v2.19.2] — 2026-07-07

Correctif : `/vf-update` fait désormais respecter le socle obligatoire — un module `mandatory`
publié après la config d'un lab (ex. `conductor` sur un lab antérieur à v2.13.0) était ignoré à
vie, ses scripts & hooks (le bandeau de mise à jour SessionStart) jamais câblés ; `update`
re-synchronise aussi la gouvernance des modules à jour (idempotent) (conductor v1.8.2).

## [v2.19.1] — 2026-07-07

Correctif : `vf-update` + docs utilisent l'identifiant complet `vibeflow@vibeflow-os` pour
`claude plugin update` (le nom nu peut échouer « Plugin not found » sur un cache de catalogue
périmé), avec note de dépannage (conductor v1.8.1).

## [v2.19.0] — 2026-07-07

Commande `/vf-update` + bandeau de mise à jour au démarrage : update deux couches en un geste
(cache marketplace du plugin + modules installés), dernière version détectée via les tags GitHub
(conductor v1.8.0).

## [v2.18.0] — 2026-07-07

Discipline de release (convention `vf-internal` : les workers internes n'ont plus de commande
d'incarnation ; conductor v1.7.0) + règle de tagging & guard du repo
(`scripts/check-release-tag.sh`, règle path-scopée).

## [v2.17.0] — 2026-07-07

+ mobile-test + mobile-test-team (boucle autonome test→fix mobile), dev-orchestrator v1.2.0
(vf-decide + garde-fous autonomes), reference v2.3.0 (Pattern 12), support engine multi-agents.

## [v2.16.0] — 2026-07-05

Agents natifs machine-enforced + doctrine de chargement contexte (ADR-044).

## [v2.15.1] — 2026-07-05

Guard Read : fenêtre bornée par VALEUR, pas par présence (BLK-007).

## [v2.15.0] — 2026-07-05

Guard Bash registres : fermeture du contournement shell (BLK-006).

## [v2.14.0] — 2026-07-04

Gouvernance scripturale : hooks auto-câblés + canon DECISIONS + guards registres (ADR-043).

## [v2.13.0] — 2026-06-29

Init : externalisation doc contextuelle + commandes d'incarnation native (ADR-042).

## [v2.12.0] — 2026-06-24

vf-new-lab v1.3.0 : Lab Factory, clarification-first.

## [v2.11.0] — 2026-06-23

planning-core v2.0.0 : topologie à compartiments + harmonisation branche main.

## [v2.10.0] — 2026-06-17

+ kpi-analyst (KPIs métier : déduits, déterministes, sourcés).

## [v2.9.0] — 2026-06-11

+ slash commands natives (`/vibeflow`, `/vf-new-lab`, `/vf-planning`, `/vf-calibrate`,
`/vf-audit`) — points d'entrée explicites des agents/skills méthodo.

## [v2.8.0] — 2026-06-11

+ 3 bundles métier (business-pilot / content / growth-par-canal) + conductor v1.1.0
(`vf-new-lab` bundle-aware, fix pointeur cassé).

## [v2.7.0] — 2026-06-11

+ conductor (orchestrateur méta/gardien) : bootstrap de lab universel (tout métier), propagation
update + migration, protocole d'escalade sous-agents.

## [v2.6.0] — 2026-06-11

planning-core v1.1.0 : garde-fou de fraîcheur (`check-planning-state.sh`) + détection métier +
bootstrap opt-in + exemple non-dev travaillé.

## [v2.5.0] — 2026-06-10

+ planning-core (socle `.planning/` universel, adaptatif par métier, 3 profils de rigueur) —
ADR-038.

## [v2.4.2] — 2026-06-06

Commande engine `uninstall --all` + flux de désinstallation dans `/vibeflow-install` + doc
désinstallation 2 couches.

## [v2.4.1] — 2026-06-06

`/vibeflow-install` 100 % manuel, distribuable isolé sous `plugin/`, clean reliquats.

## [v2.4.0] — 2026-06-05

Installation en 2 commandes : plugin Claude Code + `/vibeflow-install` à toggles.

## [v2.3.0] — 2026-06-04

+ dev-orchestrator (routeur NL → GSD + Superpowers, 13 verbes `/vf-*`).

## [v2.2.0] — 2026-06-03

+ audit-architecture, validator v1.1.0 (Phase 4 scan des process).

## [v2.1.0] — 2026-05-28

+ software-architecture, type `rules/` dans l'installer, Core v4.2 (P9).

## [v2.0.0] — 2026-05-24

+ skill-creator (multi-skills), + reference (doc-only), nouveau type de module.

## [v1.2.1] — 2026-05-24

Fix `vibeflow-update.sh` (handle `AGENT.md`).

## [v1.2.0] — 2026-05-24

+ validator (agent-only).

## [v1.1.0] — 2026-05-24

+ infrastructure-audit.

## [v1.0.0] — 2026-05-23

Release initiale : consolidator.
