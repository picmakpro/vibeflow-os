# Phase 33: Watchdog & notifications des missions - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning. Décisions D-33-A/B/C tranchées par Samuel, consignées ici avec
motif. Un point de cadrage supplémentaire (D-33-D) corrige la prémisse de coût de WTCH-04 portée
par le mandat, sourcé sur `.planning/phases/VFDO-32.../32-CONTEXT.md` (D-32-07, déjà réglé).

<domain>
## Phase Boundary

Fermer WTCH-01..04 en consommant le battement posé par la Phase 32
(`plugin/conductor/scripts/driver-lock.sh`, `heartbeat_epoch`/`meta` additif), sans rouvrir son
protocole. Trois faits de terrain, déjà mesurés (`33-TERRAIN.md`), bornent le périmètre :

- **WTCH-01 part de zéro** : aucune notion de battement par nœud n'existe. Le seul battement
  aujourd'hui est per-mission (`driver-lock.sh`). `dag.sh` n'appelle jamais `driver-lock.sh` et
  n'horodate rien lui-même (zéro import `time`/`datetime`).
- **WTCH-02/03 n'ont aucune horloge de plateforme à s'accrocher** : le spike hooks async conclut
  PAS SÛR — les hooks Claude Code sont strictement événementiels, jamais périodiques
  (`33-SPIKE-hooks-async.md`). La détection ne peut être que déclenchée par un geste, jamais par
  un démon interne à l'app.
- **WTCH-04 a un poste de coût réel mais mal identifié par le mandat** — voir D-33-D : les tables
  `ARM[]`/`OKID[]` de `check-capability-activation.sh` sont littérales et closes, mais elles ne
  modélisent pas les hooks ; le gate qui vérifie réellement l'armement des hooks est **PORT-05**
  (CI), déjà établi et déjà générique depuis la Phase 32 (D-32-07 corollaire).

**Hors scope, explicitement** :
- Observateur externe (cron/launchd/Tâches planifiées Windows) — écarté par D-33-B, motif : install
  système par OS, non portable d'un seul geste, contraire à la sobriété Windows-first du milestone.
- Auto-kill / auto-fix sur stall — ADR-031, WTCH-02 l'interdit littéralement : le watchdog
  **signale et suggère**, jamais ne tue.
- Rouvrir le protocole d'acquisition symlink-generation ou la logique de péremption
  (`heartbeat_epoch`/TTL) du driver-lock — Phase 32 fermée, on **consomme** son battement, on n'y
  touche pas.
- Élargir `check-capability-activation.sh` (`ARM[]`/`OKID[]`) pour les hooks — hors périmètre
  `conductor`, doublonnerait PORT-05 (voir D-33-D). Réservé au seul cas où un manager de mission
  aurait besoin de déclarer un nouvel armement de frontmatter — non requis par ce périmètre.
- Toast Windows réel : preuve exécutée hors de portée (aucune machine Windows disponible pendant
  le cadrage) — recette humaine en condition de **clôture de phase**, jamais un gate dur (D-33-C).

**Depends on** : Phase 32 (même battement, conçues ensemble — `driver-lock.sh` L1-560, meta
additif `session_ids`/`generation`/`heartbeat_epoch`). Branche déjà active :
`feat/phase-33-watchdog-notifications` — pas de nouvelle branche, pas de bascule.

</domain>

<decisions>
## Implementation Decisions

### D-33-A — Définition de « progrès » : deux horloges sur le même battement (tranché par Samuel)

**Decision** : le `meta` du lock (déjà porteur de `heartbeat_epoch`, écrit dans `new_generation()`
`driver-lock.sh:206-223` et préservé dans `rewrite_meta()` `driver-lock.sh:235-254`) gagne un
**second champ additif**, `progress_epoch` — même fichier, même mécanisme d'écriture (le patron
ADR-064 déjà utilisé pour `session_ids`/`branch`/`worktree` : écrit à la création, préservé sauf
appel explicite qui le fait avancer). **Stall = vivant (heartbeat frais) mais progrès figé au-delà
du seuil** ; **abandon = les deux horloges mortes**.

**Point d'écriture** : le point d'entrée unique des transitions explicites de `dag.sh` est
`mark` (`dag.sh:241-250`, `idx[nid]["status"] = status`). `dag.sh` importe déjà `subprocess`
(`33-TERRAIN.md` §2) — c'est l'accroche naturelle : à `mark`, `dag.sh` shelle un appel à
`driver-lock.sh` (verbe/flag indicatif à fixer au plan — `heartbeat --progress` ou nouveau verbe
`mark-progress`, cf. §Specific Ideas) qui écrit `progress_epoch` **sans** toucher
`heartbeat_epoch`. Aucun second fichier, aucun second script — c'est la lecture littérale de
« même battement, deux consommateurs, aucun second mécanisme » qu'exige le critère de succès n°1.

**Motif du choix, à consigner explicitement (exigé par le mandat)** : c'est la SEULE option qui
satisfait à la lettre le critère de succès n°2 (« le cas vivant mais bouclant est couvert par
test »). Une horloge de vivacité seule (`heartbeat_epoch` déjà présent) déclarerait un worker
bouclant sain — il continue de battre. Une horloge de progrès seule ne distinguerait pas un stall
d'un worker légitimement long sans jamais écrire de battement intermédiaire (un plan à une seule
tâche longue, par exemple) — elle confondrait les deux, produisant soit des faux positifs, soit un
seuil si lâche qu'il ne détecte plus rien. Les deux horloges ensemble, sur le même `meta`,
distinguent les trois cas réels : mort (les deux figées), bouclant (heartbeat frais, progrès
figé), sain (les deux fraîches).

**À prouver par mutation, patron Phase 32 (`age_stale()` de `test-driver-lock.sh:27-39`, epochs
forgés, jamais de `sleep`)** : un cas où `heartbeat_epoch` est frais et `progress_epoch` dépasse le
seuil doit rougir en stall ; un cas où les deux sont frais doit rester vert ; un cas où les deux
sont morts doit rougir en abandon — trois issues distinctes, pas deux.

### D-33-B — Détection aux moments d'activité, zéro démon (tranché par Samuel, amendement ROADMAP approuvé)

**Decision** : aucune horloge n'existe côté plateforme (`33-SPIKE-hooks-async.md`, verdict PAS
SÛR — les hooks ne sont **jamais** périodiques, un `asyncRewake` ne réveille qu'une session déjà
active, ne réveille jamais une session inactive). La détection s'appuie sur **le hook doctor
`SessionStart` né en Phase 32** (`check-guard-health.sh`, `plugin/conductor/scripts/`, déjà posé,
déjà générique tout le parc) **plus un point de contrôle sur les gestes de DAG** — un geste
d'observation déclenché quand une session VF vivante appelle `dag.sh` (le point d'entrée `mark`
lui-même est le candidat le plus proche : il connaît déjà le nœud et son statut).

**Amendement ROADMAP APPROUVÉ (2026-08-17)** — appliqué ci-dessous : la promesse initiale
(« un stall de mission ne reste plus jamais silencieux 18h ») est remplacée par **« un stall ne
survit pas au prochain geste d'une session VF vivante »**. **Limite assumée, écrite noir sur
blanc, pas glissée sous silence** : une machine laissée sans AUCUNE session VF ouverte peut
connaître un silence prolongé — cette phase ne le ferme pas, elle l'accepte explicitement comme
la contrepartie de « zéro démon, portable d'un seul geste ».

**Option écartée, avec motif** : observateur externe (cron/launchd/Tâche planifiée Windows) —
détection continue, mais dépendance système à installer par OS, non portable d'un seul geste
(contredit la sobriété d'install du plugin), et contraire à la doctrine Windows-first du
milestone (une tâche planifiée Windows n'est pas le même mécanisme qu'un cron Unix — deux
implémentations à maintenir pour un gain que la phase n'exige pas).

**Réserve héritée du spike, à lever en planification, pas ici** : la liste des événements de hooks
citée par le spike vient d'une lecture de doc, pas d'une exécution. Toute accroche retenue doit
être **prouvée par une sonde exécutée** sur la version installée avant d'être câblée — jamais sur
la foi de la doc seule (même réserve que le spike, non levée par ce cadrage).

### D-33-C — Preuve Windows : shims CI + recette humaine en condition de clôture (tranché par Samuel)

**Decision** : la chaîne de notification Windows (WinRT `ToastNotificationManager` sous
`powershell.exe` 5.1 System32 — **PAS** `pwsh`, les assemblies WinRT n'y sont pas incluses — AUMID
emprunté à PowerShell, `{1AC14E77-...}\WindowsPowerShell\v1.0\powershell.exe`) est livrée
**testée par shims d'argv en CI Linux** (`33-SPIKE-canal-notification.md` §Testabilité — trois
points d'injection : `VF_NOTIFY_FORCE_CHANNEL`, shims de binaires préfixés au PATH, shim
`uname`/`/proc/version` pour le vrai code de détection WSL). Le design du spike permet cette
preuve **entièrement sans toast réel**.

**Condition de clôture, pas un gate dur** : une recette de validation humaine sur Win10/11 est
**vérifiée nécessaire mais non exécutable pendant ce cadrage** (aucune machine Windows
disponible) — inscrite comme condition de clôture de phase.

**Rattachement au fil testeurs Windows de l'issue #20** — **vérifié, pas supposé** : le fil existe
(`gh issue view 20`, section « 7. Le fil testeurs Windows », confirmé au moment de ce cadrage,
2026-08-17) — mêmes testeurs, même terrain que le geste `--dry-run` de l'issue #20. La recette de
clôture Phase 33 s'y rattache.

**Trois zones NON PROUVÉES, écrites comme telles (spike §NON PROUVÉ)**, à ne pas combler par
supposition au plan : (1) la chaîne Windows complète n'a jamais tourné réellement ; (2) AUMID
arbitraire vs AUMID PowerShell — contradiction non tranchée dans les sources, l'AUMID PowerShell
est retenu comme strictement plus sûr, pas comme prouvé unique ; (3) latence
`powershell.exe` non mesurée en conditions réelles (rapports biaisés vers le pathologique).

### D-33-D — WTCH-04 : correction de la prémisse de coût portée par le mandat

**Le mandat (contrainte #5) présente `ARM[]`/`OKID[]` de `check-capability-activation.sh` comme le
poste de coût de WTCH-04 — cette prémisse ne tient pas pour le périmètre réel de cette phase, et
je le signale au lieu de l'exécuter telle quelle** (posture « corrige-moi plutôt que m'obéir »).

**Fait déjà établi par la Phase 32, retrouvé identique ici** (`32-CONTEXT.md`, D-32-07
corollaire) : la règle 4 de `check-capability-activation.sh` **ne connaît pas les hooks** — son
corpus est fait de frontmatters d'agents/skills portant une clé d'armement (`isolation`,
`vf-mcp-consumer`, `vf-mcp-tools`), pas d'entrées `hooks.json`. Le gate qui vérifie réellement
qu'un hook distribué est armé (posé par `merge-hooks.sh`, pas oublié) est **PORT-05**
(`.github/workflows/ci.yml` L800-901), déjà générique, déjà capable de voir une entrée neuve sans
être modifié.

**Conséquence pour WTCH-04** : l'armement de `notify.sh` et du point de contrôle de stall (hooks
`hooks.json` sous `conductor`) est prouvé par **PORT-05**, exactement comme le guard du driver-lock
en Phase 32 — **pas** par une édition de `ARM[]`/`OKID[]`. Éditer ces tables ne devient nécessaire
que si un agent/skill de mission a besoin de déclarer un **nouvel armement de frontmatter**
(`vf-requires:`) — ce que le périmètre actuel (hooks + script de notification, aucune nouvelle
clé de frontmatter) ne demande pas. Si le plan découvre un besoin réel de ce type, il devra
budgéter le coût réel documenté par le terrain (édition du gate L508-509 **+** cas de test dans
sa suite de 60) — mais ce cadrage ne le prévoit pas comme nécessaire.

**Ce qui reste vrai et à respecter** : WTCH-04 exige explicitement « jamais un settings local »
(leçon #38, régression #38 rejouée si contournée) — la commande d'un hook peut rester locale
(chemin machine-spécifique, D-32-C), mais son **entrée** dans `hooks.json` doit toujours naître
de `merge-hooks`, jamais posée à la main.

### D-33-H — Notifications opt-in par défaut + jalons via l'app Claude (amendement daté 2026-08-17, tranché par Samuel)

**Amendement, pas réécriture.** La Phase 33 a livré WTCH-03 avec un défaut d'émission dès qu'un
canal OS est détecté. Ce défaut devient **opt-in — OFF par défaut**. Fenêtre décisive : la release
**v2.56.0 a été retirée de la distribution** (tag supprimé, `VERSION` revertée à v2.55.1, revert
`07ff554`, le code Phase 33 restant mergé sur `main`) — **aucun lab n'a donc jamais reçu le
comportement d'émission par défaut**. Le flip est une **correction pré-distribution**, sans aucune
migration de parc à financer.

**Q1 — Vecteur du push : le relais, parce que l'outil n'existe pas en sous-agent.** Au jalon, le
manager émet un `SendMessage(main)` portant la ligne prête à pousser ; c'est **la session
principale** qui appelle `PushNotification`. Mesure, pas supposition — erreur littérale obtenue à
l'appel réel : « No such tool available: PushNotification. PushNotification is disabled for this
session, in subagents as well as here. » Ce n'est **pas** un réglage (la config est déjà ON). Tous
les managers et workers étant des sous-agents, **aucun ne peut pousser directement**.
**Limite à documenter explicitement** : le relais exige une session principale pilote — une mission
lancée sans session principale ne poussera pas.

**Q2 — On s'appuie sur le harness, on ne le contourne pas.** `user_present` (aucune émission quand
l'humain est actif au terminal) est un comportement **assumé et documenté du design**, pas un
défaut : ne pousser que lorsque l'utilisateur est absent EST précisément l'intention d'un jalon de
mission longue. VibeFlow n'ajoute donc que ce que le harness ne fait pas : **le défaut opt-in et le
toggle**.

**Q4 — Contrat du push.** Un seul champ `message`, **< 200 caractères, sans markdown**, pas de
`title` — l'aplatissement `TITLE` + `BODY` en une seule ligne est un point de conception, pas un
oubli. L'outil **ne lève jamais d'erreur** : il rend toujours un succès porteur d'un
`disabledReason` (`config_off` / `user_present` / `no_transport`). « requested » n'est jamais
« delivered » : **aucun accusé de réception n'existe**, donc aucun contrôle de flux ne doit
l'attendre.

**Q5 — Persistance : fichier-sentinelle, patron `stop-notify`** (`touch` / `rm -f`). Zéro JSON,
zéro hook neuf, donc **exposition nulle** au bug d'idempotence cross-matcher de `merge-hooks.sh`
(toujours ouvert, cf. contrainte transverse ci-dessous). **Contradiction du brief levée** : la
préférence est **PAR MACHINE** (scope user) — ce que le fichier-sentinelle incarne exactement — et
non « settings local » (per-lab), formule écartée. Motif supplémentaire, décisif : **aucun vecteur
d'engine n'existe pour écrire une clé non-hook dans un settings**.

**Q6 — Les DEUX jalons, portés par la doctrine du manager** (fin de phase ET fin de milestone).
Raison : c'est le **seul vecteur symétrique** disponible. `gsd-ship` offre `ship:pre`/`ship:post`,
mais `gsd-complete-milestone` n'offre **aucun** point d'extension (0 `render-hooks` sur 815 lignes,
aucun `milestone:*` parmi les 12 points de hook de gsd-core) ; et `ship:post` dispatche lui-même un
**sous-agent**, donc structurellement incapable d'émettre le push. Conséquence : **pas de wrapper
des skills amont, pas de dépendance à un hook inexistant**.

**Hiérarchie retenue** :
- jalons GSD (fin de phase, fin de milestone) → **push app Claude** via le relais `SendMessage(main)` ;
- fins de nœud de DAG (`done` / `failed`) → **toast OS** via `notify.sh`, comme aujourd'hui, mais
  **seulement si l'opt-in est actif**.

Aucun spam : la doctrine WTCH-03 sur la granularité (jamais à chaque tour, `running` jamais) reste
inchangée.

**Ligne rouge nommée — le signal de stall (D-33-F) n'est PAS une notification de confort.** Il
reste actif **quel que soit le toggle** et ne doit **JAMAIS** être gaté. Fait vérifié qui le
protège structurellement : il ne passe pas par `notify.sh` — `dag.sh:223-246` écrit sur stderr,
`record_milestone()` (`:248-268`) est une fonction disjointe, et les deux sont appelées séparément
(`:377` et `:380`). **Interdiction explicite** : ne jamais placer le gate d'opt-in dans `dag.sh` en
amont de ce bloc.

**Correction d'une prémisse du brief, à consigner** : `VF_NOTIFY_FORCE_CHANNEL=none` **n'est pas un
kill-switch**. Aucune valeur `none` n'existe dans le code — le `case` (`notify.sh:155-160`) ne
connaît que `windows|darwin|linux`, toute autre valeur tombant sur `*) : ;;`. `none`, `off` et
`xyzzy` silencient donc **identiquement, par accident**, sans aucun test qui l'atteste. Le nouveau
gate d'opt-in n'a par conséquent **rien avec quoi « composer »** : il est le **premier** mécanisme
d'extinction délibéré du canal.

### Contrainte transverse — merge-hooks, jamais deux entrées pour le même script sur le même événement

Bug d'idempotence cross-matcher NON CORRIGÉ (`CONCERNS.md`, sévérité HIGH, confirmé par
`33-TERRAIN.md` §4) : deux entrées référençant le même script sous le même événement se purgent
silencieusement à l'installation. **Règle opérationnelle pour cette phase** : si le point de
contrôle de stall étend `check-guard-health.sh` (script déjà existant, déjà câblé sur
`SessionStart`/`startup`), **aucune nouvelle entrée `hooks.json` n'est nécessaire** — c'est le
chemin à privilégier au plan. S'il faut malgré tout un nouveau script distinct, une seule entrée à
matcher combiné, le script dispatchant lui-même sur `tool_name`/l'événement — jamais deux entrées
séparées.

### Contrainte transverse — QUAL-01, quatre issues, canal déjà existant

Le signal « progrès illisible » doit être **BRUYANT**, jamais un vert de complaisance : réutiliser
`vf_guard_unavailable` (`plugin/_internal/lib/vf-portable.sh:145-158`) — marqueur atomique +
stderr préfixé + `exit 17` — dont le seul consommateur existant est déjà `check-guard-health.sh`
(`SessionStart`, générique tout le parc). Un producteur Phase 33 (`progress_epoch` illisible) n'a
**rien à câbler côté lecture** : il appelle `vf_guard_unavailable`, le doctor l'affiche déjà.
**`notify.sh` est l'exception documentée** (spike §Fail-open silencieux, règle 3) : il ne doit PAS
utiliser `vf_guard_unavailable` — une notification muette est le comportement nominal, `exit 0`
inconditionnel, détaché en arrière-plan.

Mutation rouge exigée pour le nouveau signal de stall, même standard que Phase 32 : assertion,
attendu, obtenu, tracé en SUMMARY — pas dans la suite elle-même (exigence de process, pas de test).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning.**

### Recherche de phase (déjà produite, à citer, pas à rejouer)
- `.planning/phases/VFDO-33-watchdog-notifications-des-missions/33-TERRAIN.md` — battement
  per-mission seul (§1), points de transition de `dag.sh` (§2), gate d'armement et son coût réel
  (§3), pose par l'engine + bug merge-hooks (§4), canal bruyant réutilisable (§5), facture de
  référence 80 assertions (§6), découverte CI 64 suites (§7).
- `33-SPIKE-hooks-async.md` — verdict PAS SÛR, événements en sous-agent vs session-globaux,
  aucune périodicité native.
- `33-SPIKE-canal-notification.md` — cascade de détection par OS, WSL piège, testabilité par
  shims, cinq règles fail-open silencieux, zones NON PROUVÉES.
- `.planning/phases/VFDO-32-durcissement-du-driver-lock/32-CONTEXT.md` — D-32-01 (heartbeat vs
  lease, patron additif réutilisé ici pour `progress_epoch`), D-32-03 (patron ADR-064 additif),
  D-32-07 corollaire (PORT-05 est le vrai gate d'armement des hooks, pas la règle 4).

### Code au cœur de la phase
- `plugin/conductor/scripts/driver-lock.sh` — `new_generation()` L206-223, `rewrite_meta()`
  L235-254, verbe `heartbeat` L497-509. Point d'ajout de `progress_epoch`.
- `plugin/conductor/scripts/dag.sh` — action `mark` L241-250 (`idx[nid]["status"] = status`,
  import `subprocess` déjà présent), `save(dag)` L?? réécriture complète NON atomique (risque
  lecteur concurrent, à noter, pas à corriger dans cette phase sauf débordement de risque).
- `plugin/conductor/scripts/check-guard-health.sh` (185 l.) — hook doctor `SessionStart`,
  générique, contrat à 4 codes, à étendre en priorité plutôt que dupliquer.
- `plugin/_internal/lib/vf-portable.sh:145-158` — `vf_guard_unavailable`, canal bruyant à
  réutiliser tel quel ; `IS_WINDOWS` (calcul `uname -s`) à étendre d'un détecteur WSL — **dans
  cette lib**, jamais dans `notify.sh`, sous peine de rouvrir le défaut fermé en Phase 30.
- `plugin/_internal/tests/test-vf-portable.sh` — test T12, checksum du bloc
  `vf-portable:locator`, liste aujourd'hui 5 consommateurs ; `notify.sh` en sera le 6ᵉ → **T12 à
  mettre à jour**, sinon la suite casse.
- `plugin/_internal/vibeflow-update.sh:1204-1247` — pose par glob, aucune liste blanche à amender
  pour `notify.sh` ni sa suite de tests.
- `.github/workflows/ci.yml` L210-236 (découverte CI, 64 suites, assertion F13 anti-vert-à-vide),
  L800-901 (gate PORT-05, le vrai gate d'armement des hooks).
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` L494-509 (`ARM[]`/`OKID[]`
  littérales et closes) — à ne PAS éditer sauf besoin de frontmatter avéré (D-33-D).

### Doctrine
- ADR-031 — advisory par défaut, jamais de fix/kill sans validation humaine ; fonde le « signale
  et suggère, ne tue jamais » de WTCH-02.
- ADR-064 — claim additif au meta (branch/worktree/session_ids) ; patron réutilisé pour
  `progress_epoch`.
- Leçon #38 — armement via settings local ; fonde WTCH-04 et le refus documenté ici.

</canonical_refs>

<code_context>
## Existing Code Insights

### Patrons établis à réutiliser (jamais réinventer)
- Champ additif au `meta` : écrit dans `new_generation()` **et** préservé dans `rewrite_meta()`,
  jamais l'un sans l'autre (patron `branch`/`worktree`/`session_ids`, ADR-064).
- Epochs **forgés**, jamais de `sleep` dans les tests (`age_stale()` de
  `test-driver-lock.sh:27-39`) — tout cas touchant `progress_epoch`/stall doit suivre ce patron.
- Gates à quatre issues + mutation rouge prouvée par sa trace (QUAL-01 transverse, déjà standard
  du dossier depuis Phase 32).
- Canal bruyant : produire via `vf_guard_unavailable`, jamais un second lecteur — le doctor
  `SessionStart` est déjà générique tout le parc.

### Fragilités identifiées, à traiter au plan (pas à découvrir en exécution)
1. `dag.sh save()` réécrit tout le fichier sans `tmp+rename` — un lecteur watchdog concurrent
   pourrait lire un JSON partiel pendant l'écriture. À évaluer au plan : gravité réelle (fenêtre
   très courte, lecture depuis un hook déclenché par un AUTRE process) vs coût d'une correction
   (hors du texte littéral des exigences WTCH — à ne pas engager sans decision explicite).
2. Le détecteur WSL manquant dans `vf-portable.sh` (`IS_WINDOWS` vaut 0 sous WSL) est un vrai
   trou pour `notify.sh` — mesuré, pas supposé (spike §Art antérieur).
3. Latence `powershell.exe` (0,3s à 4-7s pathologique, non mesuré en réel) impose détachement en
   arrière-plan systématique — jamais un manager qui attend une notification best-effort.

### Integration Points
- Le battement consommé ici (`heartbeat_epoch`) est celui posé par la Phase 32 sans modification
  de son calcul de péremption (TTL) — la phase 33 n'y touche pas.
- `check-guard-health.sh` (Phase 32) est le point d'extension naturel pour le signal de stall — à
  confirmer/infirmer au plan selon la faisabilité technique de lui faire lire aussi le lock/DAG.

</code_context>

<specifics>
## Specific Ideas

- Nom de champ retenu : `progress_epoch` (décision D-33-A) — additif au `meta` du lock.
- Nom de verbe/flag indicatif, **à fixer au plan** : `driver-lock.sh heartbeat --progress` (flag
  sur le verbe existant, ne crée pas de sixième verbe) ou nouveau verbe `mark-progress` — les deux
  options respectent « même battement, même fichier » ; le plan tranche sur la base du coût réel
  d'implémentation dans `driver-lock.sh` (569 l., cinq verbes déjà).
- Nom de script indicatif pour le canal de notification : `plugin/conductor/scripts/notify.sh`
  (repris tel quel du spike, posé par glob, aucune liste blanche à amender).
- Découpage en plans proposé (dépendances, pas des plans figés) :
  - **33-01** — `driver-lock.sh` : champ `progress_epoch` (D-33-A), verbe/flag de mise à jour,
    suite `test-driver-lock.sh` étendue (3 cas minimum : sain / stall / abandon, epochs forgés).
    Fichiers : `plugin/conductor/scripts/driver-lock.sh`,
    `plugin/conductor/scripts/tests/test-driver-lock.sh`.
  - **33-02** — `dag.sh` : appel à `driver-lock.sh` au point `mark` (subprocess déjà importé),
    dépend de 33-01. Fichiers : `plugin/conductor/scripts/dag.sh`,
    `plugin/conductor/scripts/tests/test-dag.sh`.
  - **33-03** — détection de stall : extension de `check-guard-health.sh` (ou script neuf, une
    seule entrée `hooks.json` si neuf — contrainte merge-hooks), canal BRUYANT via
    `vf_guard_unavailable`, mutation rouge prouvée. Dépend de 33-01. Fichiers :
    `plugin/conductor/scripts/check-guard-health.sh` (ou script neuf),
    `plugin/conductor/scripts/tests/test-check-guard-health.sh` (ou suite neuve),
    `plugin/conductor/hooks/hooks.json` si nouvelle entrée.
  - **33-04** — `notify.sh` : cascade macOS/Linux/Windows/WSL (spike), détecteur WSL ajouté dans
    `vf-portable.sh`, checksum T12 mis à jour, suite testée par shims d'argv, fail-open silencieux
    (règles du spike). Indépendant de 33-01/02/03 (peut démarrer en parallèle). Fichiers :
    `plugin/conductor/scripts/notify.sh` (neuf),
    `plugin/conductor/scripts/tests/test-notify.sh` (neuf),
    `plugin/_internal/lib/vf-portable.sh` (détecteur WSL),
    `plugin/_internal/tests/test-vf-portable.sh` (T12, 6ᵉ consommateur).
  - **33-05** — jalons de notification : câblage `notify.sh` aux points « fin de nœud » (mark
    terminal) et « halt condition », vérification PORT-05 (D-33-D, pas d'édition
    `check-capability-activation.sh`), recette de clôture Windows rattachée au fil testeurs de
    l'issue #20 (D-33-C). Dépend de 33-02 et 33-04. Fichiers : `plugin/conductor/scripts/dag.sh`
    (câblage), points de halt condition à identifier au plan (potentiellement hors `conductor` —
    à vérifier, pourrait rouvrir la question du périmètre d'écriture comme en Phase 32/D-32-07).

</specifics>

<deferred>
## Deferred Ideas — remontées à Samuel, non tranchées ici

1. **Correction de `dag.sh save()` en écriture atomique (tmp+rename)** — fragilité réelle pour un
   lecteur watchdog concurrent (§code_context), mais hors du texte littéral de WTCH-01..04. À
   arbitrer au plan si le risque mesuré (pas supposé) le justifie.
2. **Points de halt condition hors `conductor`** — si le câblage de 33-05 découvre que des halt
   conditions vivent dans des modules tiers (`dev-orchestrator` notamment, cf. mission-flow.md),
   le même arbitrage que D-32-07/amendement (synchronisation multi-modules) pourrait se reposer.
   Non tranché ici, faute de terrain suffisant sur ce point précis.
3. **Verbe vs flag pour `progress_epoch`** — décision de coût d'implémentation, déléguée au plan
   (§Specific Ideas).

</deferred>

---

*Phase: 33-Watchdog & notifications des missions*
*Context gathered: 2026-08-17*
