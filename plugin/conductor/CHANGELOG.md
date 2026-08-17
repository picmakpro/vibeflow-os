# Changelog — conductor

## [v1.27.0] — 2026-08-17 (Watchdog & notifications des missions — Phase 33, WTCH-01..04)

**Minor** (deux nouvelles capacités publiques, consommant sans y toucher le battement posé par la
Phase 32) :

- **`progress_epoch`, second champ additif au `meta` du lock** (même mécanisme que
  `heartbeat_epoch`/`session_ids`, ADR-064 — écrit à la création, préservé sauf appel explicite).
  `driver-lock.sh` expose le verbe **`mark-progress`**, qui avance `progress_epoch` **sans**
  toucher `heartbeat_epoch` — deux horloges sur le même battement : `heartbeat_epoch` pour la
  vivacité, `progress_epoch` pour le progrès. `dag.sh mark` l'appelle désormais à chaque
  transition (`record_progress()`). (WTCH-01, plans 33-01/33-02, `test-driver-lock.sh` 183 PASS.)
- **Sous-contrôle stall/abandon dans `check-guard-health.sh`** : détection par ABSENCE de progrès
  au-delà d'un seuil (lock vivant par ailleurs) — jamais par auto-déclaration, ne tue jamais
  (ADR-031). Canal **BRUYANT** (`vf_guard_unavailable`) sur dépendance indisponible, fail-open
  **silencieux** sur sortie imparsable — quatre issues, mutation rouge prouvée (QUAL-01). (WTCH-02,
  plan 33-03, `test-check-guard-health.sh` 78 PASS.)
- **`plugin/conductor/scripts/notify.sh` (neuf)** : notification OS native aux jalons de mission
  (`dag.sh mark --status=done|failed` uniquement — jamais à `running`, jamais à chaque tour),
  cascade macOS/Linux/Windows/WSL, **fail-open silencieux inconditionnel** (`exit 0`, jamais
  `vf_guard_unavailable` — une notification muette est le comportement nominal), détaché en
  arrière-plan. Canal Windows (WinRT `ToastNotificationManager` sous `powershell.exe` 5.1, AUMID
  PowerShell) **prouvé par shims d'argv en CI Linux uniquement** — **la chaîne réelle n'a jamais
  tourné sur un poste Windows** ; une recette de validation humaine existe
  (`33-CLOTURE-WINDOWS.md`, rattachée au fil testeurs Windows de l'issue #20) mais reste une
  condition de clôture de phase, pas une preuve. (WTCH-03, plans 33-04/33-05.)
- **Point de contrôle en lecture au geste `dag.sh mark`** (D-33-F) : après `record_progress()`,
  `mark` relaie best-effort le verdict `check-guard-health.sh --hook` sur stderr — un stall ne
  survit pas au prochain geste `mark` d'une session VF vivante (au lieu du seul `SessionStart`).
  **Défaut trouvé par la vérification, puis corrigé (D-33-G)** : dans le même bloc,
  `record_progress()` avançait `progress_epoch` **avant** que ce relais ne relise le statut du
  lock — le verdict STALL du lock courant était donc structurellement inatteignable par ce chemin,
  qui ne fonctionnait que pour ABANDON et les marqueurs de garde tiers. L'ordre est inversé : la
  lecture précède le rafraîchissement, les deux restent après `save(dag)`, `record_milestone()`
  reste dernier. Couvert par le cas de discriminance **T49** — sous l'ordre fautif T49.2 rougit
  alors que T41 et T48 restent verts, donc seul T49 mord. Vérifié `gaps_found`
  (`33-VERIFICATION.md`, 2026-08-17) puis **refermé** : les 4 critères de succès sont ATTEINTS
  (WTCH-03 en limite assumée sur la preuve Windows réelle).
- **Armement — aucune entrée `hooks.json` neuve, aucun settings local.** L'armement de `notify.sh`
  et du sous-contrôle de stall est prouvé par le gate CI **PORT-05** (établi Phase 32), pas par une
  édition de `check-capability-activation.sh` (règle 4, `ARM[]`/`OKID[]`) — ces tables ne
  modélisent pas les hooks et n'avaient pas à être touchées ici (D-33-D). (WTCH-04, plan 33-05.)
- **Zéro démon, détection aux moments d'activité seulement** (D-33-B, amendement ROADMAP
  approuvé) : aucune horloge de plateforme n'existe (spike hooks async, verdict PAS SÛR — les
  hooks Claude Code ne sont jamais périodiques). Limite assumée : une machine sans aucune session
  VF ouverte peut connaître un silence prolongé — non fermé par cette phase, contrepartie du
  « zéro démon, portable d'un seul geste ».

## [v1.26.0] — 2026-08-17 (Durcissement du driver-lock — Phase 32, LOCK-01..05/QUAL-01)

**Minor** (nouvelles capacités présentées à l'utilisateur, avec deux **ruptures de contrat**
explicites) :

- **Battement séparé de la lease.** `driver-lock.sh` expose désormais `session_ids` (liste
  préservée au heartbeat) et `generation` (jeton de fence) en JSON, plus `lease_seconds`
  (observabilité pure, calculée depuis `acquired_epoch`) — **jamais un facteur de péremption** :
  `lock_age()`/TTL/`stale` restent adossés au seul `heartbeat_epoch`. **Le TTL par défaut est
  inchangé (1800 s)** — un lock périmé n'a jamais été et n'est toujours pas une mission morte.
- **Rupture de contrat — `acquire` ne récupère plus JAMAIS un lock périmé.** L'auto-steal
  implicite au TTL est retiré : `acquire` sur un lock périmé refuse désormais en
  `stale-requires-takeover` (avec un champ `hint` nommant la commande de reprise). Deux verbes
  explicites le remplacent, tous deux tracés dans un journal append-only avec l'identité du
  repreneur : **`takeover`** (reprise déclarée d'un lock périmé) et **`reclaim`** (reprise d'un
  lock sans identité de session, seul geste qui la repeuple). Toute doctrine externe qui
  prescrivait l'ancien contrat implicite est désormais **fausse** — resynchronisée dans 5 agents
  managers de 4 modules tiers plus `mission-flow.md` (dev-orchestrator) et `team-kernel.md`.
- **Rupture de contrat — un guard `PreToolUse` qui REFUSE des commandes.**
  `scripts/guard-driver-lock.sh` (neuf) intercepte `Bash`/`Write`/`Edit` (matcher combiné) et
  refuse, par décision JSON (`permissionDecision: deny`), les gestes mutants (commit, checkout,
  switch, merge, rebase, cherry-pick, revert, reset, clean, push, tag, branch, stash, worktree
  remove, `gh pr`, `gh release`, ou une écriture sous `.planning/`) tentés par une session tierce
  sous un lock vivant — le détenteur (et ses sous-agents, même `session_id` parent) passe
  toujours. Le motif de refus nomme l'owner, l'étape, la branche, l'âge du lock, **et la commande
  de reprise**. **Limite de granularité connue** : le matching de commande est par sous-chaîne —
  passoire devant `eval`, `bash -c`, un alias, ou un wrapper indirect ; garde anti-accident, pas
  anti-adversaire. **Limite de matching connue** : un lock sans identité de session
  (`session_ids` vide, héritage pré-Phase-32) reste **non opposable** à ce guard jusqu'à un
  `reclaim` explicite — `heartbeat` ne le repeuple jamais.
- **Convention de jeton de fence** (`Fence: <generation>` en trailer de commit) posée dans
  `team-kernel.md` — **convention d'agent, jamais vérifiée par machine**, même tier que
  `Co-Authored-By:`/`Claude-Session:`. Aucun commit ne porte encore ce trailer à ce jour ; la
  convention entre en vigueur au prochain mandat qui commite sous cette doctrine.
- **Lecteur de marqueurs de santé** (`scripts/check-guard-health.sh`, neuf, `SessionStart`
  générique) — ferme la quatrième issue de QUAL-01 (garde indisponible → fail-open **bruyant**,
  jamais silencieux) pour `guard-driver-lock.sh` et pour tout autre garde du parc qui écrit un
  marqueur au même format.
- **Limite connue, non résolue par cette phase** : sans privilège de lien symbolique (Git Bash
  Windows par défaut), `ln -s` copie au lieu de lier — `[ -L ]` rend faux, `[ -d ]` rend vrai, et
  le protocole d'acquisition retombe sur son chemin **legacy**, où le trou de double-détenteur est
  désormais fermé (garde d'existence), mais sans le durcissement neuf de cette phase. Le milestone
  est Windows-first et aucun runner Windows n'existe dans la CI de ce dépôt : fait écrit comme
  limite connue, pas résolu ici.

## [v1.25.0] — 2026-08-16 (Câblage `--dry-run` dans `/vf-calibrate`, MANI-02/D-31-10)

**Minor** (nouvelle capacité présentée à l'utilisateur) : l'étape 4 point 2 de
`skills/vf-calibrate/SKILL.md` présente désormais le plan `--dry-run` de l'engine
(`vibeflow-update.sh --dry-run update <module>`) **avant** de rafraîchir réellement un module —
la sortie fichier-par-fichier est montrée à l'utilisateur, en contenu du plan de migration déjà
soumis au feu vert de l'étape 3 (ADR-031), sans nouveau point de décision. Édition minimale,
répondant à la demande terrain de l'issue #20.

## [v1.24.0] — 2026-08-16 (Portabilité Windows II — codes de sortie, PORT-03/D-07)

**Minor** (nouveau contrat de sortie) : `check-agents.sh`, `check-branch-claim.sh` et
`check-workstream-pointer.sh` traduisent désormais leur silence interne vers 0 à la frontière du
harness, sous leur drapeau `--hook` — même fonction (`hook_exit`), même contrat que le périmètre
dev normalisé au plan `VFDO-30-04`. Sans `--hook` (CLI, suites de tests), aucun code ne change.

- **`check-agents.sh`** : le point de traduction est posé au SHELL, à la sortie du bloc Python
  embarqué (le contrat interne du bloc Python — `sys.exit(3)` pour INDÉTERMINÉ — ne change pas ;
  seule sa dépendance à `not hook` disparaît du déclenchement de l'exit, jamais de l'affichage).
- **`check-branch-claim.sh`** : les DEUX codes silencieux (3 = SAIN, 4 = INDÉTERMINÉ) sont
  traduits ; le signal (0) et l'erreur d'usage (64) ne le sont jamais.
- **`check-workstream-pointer.sh`** : le code 2 (NON VÉRIFIABLE) est traduit — il ne doit jamais
  collision­ner avec le code 2 réservé au blocage délibéré du harness
  (`docs/HOOKS-CONTRAT-SORTIE.md` §1) — ainsi que le code 3 (SILENCE). L'en-tête, qui affirmait
  « --hook ne change AUCUN code de sortie », est corrigé dans ce même commit.

Voir `docs/HOOKS-CONTRAT-SORTIE.md` pour le contrat complet et l'inventaire recompté des 25
entrées du parc.

## [v1.23.0] — 2026-08-15 (Phase 28 — `check-agents.sh` admet `vf-requires`)

**Minor** (nouvelle capacité) : `vf-requires` (identifiant de précondition externe déclarée par
l'artefact, cf. `dev-orchestrator` v2.15.0) rejoint l'ensemble `KNOWN` des champs de frontmatter
reconnus. Même origine que la Phase 28 côté `dev-orchestrator` (issue #38) : la question n'était
jamais « la précondition existe-t-elle ? » mais **« qui l'écrit chez l'utilisateur ? »** —
`vf-requires` en est la déclaration lisible, et `check-agents.sh` doit la reconnaître au lieu de la
signaler comme un champ inventé.

**Précision mesurée, pour éviter de répéter une erreur de prémisse** : un champ inconnu de `KNOWN`
n'a **jamais** été bloquant, même en `--strict` — c'est un `warnings.append` nu (`:621-623`), pas
une entrée dans `errors`. L'admission de `vf-requires` ne lève donc aucun blocage : elle traite le
**bruit** que le hook de démarrage aurait fait remonter sur les 5 agents qui portent désormais ce
champ légitimement (`agents/vf-coder.md`, `agents/vf-reviewer.md`, et les 3 agents de
`mobile-test-team`), pas une régression de gate.

**Hiérarchie avec la garde dure voisine** : la garde `isolation: worktree` interdite dans un agent
distribué (`:546-549`, issue #38) reste une **erreur** (`errors.append`, bloquante en `--strict`) —
elle porte sur une précondition qui ne peut structurellement pas être distribuée par le harness. Le
palier de relation du gate d'activation (`vf-requires` ↔ `# vf-provides`, `dev-orchestrator`) porte
sur une précondition qui **peut** l'être, et dont la Phase 28 arme la vérification côté
`check-capability-activation.sh`, pas côté `check-agents.sh`. Les deux gardes subsistent : elles
ferment deux classes de préconditions distinctes, l'une catégoriquement interdite, l'autre
admissible sous couverture prouvée ailleurs.

Référence : issue #38.

## [v1.22.0] — 2026-08-15 (gate anti-drift carte↔disque + contrat de routage par dossier)

**`scripts/check-map-drift.sh` (nouveau)** : gate lint-only qui constate deux paires carte↔disque
bidirectionnelles — P1 (`CLAUDE.md` vs sous-dossiers de premier niveau suivis par git) et P2
(`_index.md`/`INDEX.md` vs contenu `.md` direct, non récursif, de leur dossier). Wrapper
`git_safe()` durci (dépôt cloné hostile), grammaire d'exit `0`/`3`/`64` partagée avec
`check-doc-drift.sh`/`check-agents.sh`, plancher `NON VÉRIFIABLE` sur 0 carte balayée. Aucun mode
correctif (ADR-031) ; aucun `jq`/`grep -P`/`sed -i` (ADR-054). **Deux bornes resserrées sur
verdict humain (checkpoint T-29-05-3, 2026-08-15)** : (a) une ligne de commande citée en exemple
dans un `CLAUDE.md` n'est plus prise pour un chemin déclaré (P1 sens 1) ; (b)
`plugin/reference/content/examples/` — cartes volontairement fictives d'un exemple pédagogique —
est exclu du balayage des deux paires. Mitigation STRIDE `T-29-02-08` : citation `../` de tête
ignorée en P2 sens A, résidu non-initial accepté en risque `low`. Sur ce dépôt, le gate rend
désormais **exactement 3 findings légitimes** (`docs`, `manual`, `reports` non cités par
`./CLAUDE.md`) — signal assumé, non corrigé (ADR-031). Suite dédiée
`scripts/tests/test-check-map-drift.sh` (**57 cas**), discriminance des deux paires prouvée par
mutation (`cmp -s`), table générative de 45 combinaisons pour la classe des formes de chemin
équivalentes.

**`scripts/scaffold-docs.sh` (étendu)** : pose désormais un `CONTEXT.md` de routage (table
Tâche/Charge/NE charge PAS, ≤ 80 lignes) par compartiment de documentation, et un flag `--index
<dossier>` posant un `_index.md` de contenu pour tout dossier de références. Première application
réelle sur `plugin/dev-orchestrator/references/` (11 fichiers). Première suite de tests du
scaffolder (`scripts/tests/test-scaffold-docs.sh`, 26 cas), couvrant l'extension et le
comportement préexistant.

`scripts/dag.sh` (socle `--scope`, D-03) hors diff des deux livrables — vérifié à chaque étape.

## [v1.21.1] — 2026-08-10 (correctif #38 — le garde-fou machine contre `isolation: worktree`)

**`check-agents.sh` refuse désormais `isolation:` dans le frontmatter d'un agent distribué, et
`team-kernel.md` écrit pourquoi.** Le lint validait jusqu'ici la *forme* de la clé (« seul
`worktree` est admis ») sans jamais interroger sa *légitimité* — il a donc laissé passer
l'armement de 13 agents en v2.49.0.

Motif, mesuré et non théorique (issue #38) : le worktree du harness fork depuis la **branche par
défaut**, pas depuis le HEAD courant. Un worker mandaté sur une branche de mission atterrit sur
une branche technique **sans aucun fichier du mandat**, se déclare bloqué sans produire, et le
manager se rabat silencieusement sur un agent générique. La précondition `worktree.baseRef:
"head"` vit dans le settings du poste et **n'est posée nulle part par l'engine** — vérifié : zéro
occurrence de `baseRef` dans `vibeflow-update.sh`, `merge-hooks.sh` et l'installeur. Même
corrigée, elle ne suffirait pas : rien ne ramène les commits du worker vers la branche de mission
(`open-gsd/gsd-core#3302` — déjà le motif du refus écrit de `claude_orchestration` en Phase 27).

`team-kernel.md` §Règles d'instanciation porte la règle en clair : **l'isolation est une décision
de dispatch du manager, jamais une propriété du worker** — portée par le frontmatter elle devient
inconditionnelle et retire au manager l'arbitrage que la doctrine lui confie. Lever le gate
demandera de distribuer la précondition **et** de prouver le retour des commits.

Référence : issue #38.

## [v1.21.0] — 2026-08-10 (la frontière ready apprend les étages, et l'isolation dit enfin ce qu'elle ne transmet pas)

### Ajouté
- **Champ `stages` sur `dag.sh ready`** (PAEX-04/05/06, Phase 27) — partition machine de la
  frontière `ready` en étages sans recouvrement de `scope[]` entre nœuds d'un même étage, calculée
  en câblant `partitionStages()` amont via un sous-processus `gsd-tools claude-orchestration
  emit-workflow` (jamais réimplémentée, ADR-069). Additif : `ready`/`count` intacts pour les 5
  consommateurs. Repli fail-closed `stages: null` si node/gsd-tools indisponible — prouvé en
  exécution (T29), jamais un crash. Cas T25-T33, suite `test-dag.sh` 99 PASS.
- **Doctrine `GSD_WORKSTREAM` sous isolation** (`team-kernel.md`) — fait observé au run réel de la
  Phase 27 (sonde A4) : un worker `isolation: worktree` ne résout PAS son `GSD_WORKSTREAM` ; le
  manager passe le workstream explicitement dans le mandat. Registre : T-27-03-06.

### Modifié
- **`team-kernel.md`** — le parallélisme intra-étape n'est plus dit « perdu » mais « éteint par
  défaut » ; le vrai chemin est nommé (capability `claude_orchestration`, gate n°4
  `dispatch.nested && dispatch.background`, verrou pratique gate n°5 `GSD_AGENT_SDK_VERSION`).
  Spike conduit en Phase 27 : refus motivé (run réel divergent du chemin inline), déclencheur de
  reprise = open-gsd/gsd-core#3302.

## [v1.20.0] — 2026-08-04 (le workstream cesse d'être un silence, et `effort:` cesse d'être facultatif)

### Ajouté
- **`check-workstream-pointer.sh`** (GSDA-16) — nouveau gate : quand un `.planning/` est
  **partitionné** en workstreams et qu'aucun canal ne résout de compartiment actif, le moteur ne
  disait rien du tout. Le silence devient audible, en **advisory strict** : le gate signale, il ne
  bloque pas. Il refuse le lien symbolique et intègre la politique de nom amont dans son intégralité
  plutôt que d'en réimplémenter une variante. Câblé au `SessionStart` de `hooks.json`, en `|| true`
  comme ses voisins — un gate advisory ne peut pas faire échouer l'ouverture d'une session.
  Suite dédiée `test-check-workstream-pointer.sh`, discriminance prouvée par mutation.

### Modifié
- **`check-agents.sh` EXIGE désormais `effort:`** (GSDA-21) au lieu de se contenter de le valider
  quand il est présent. Un champ validé-s'il-est-là n'est pas un champ requis : les agents qui ne le
  déclaraient pas passaient le gate en silence. La population réellement gatée est de **31 fichiers
  d'agents** — `plugin/*/agents/<nom>.md` **et** `plugin/*/AGENT.md` à la racine des modules
  mono-agent, les deux familles que l'installeur pose dans `.claude/agents/` — et non 25 : le
  durcissement appliqué aux seuls 25 aurait laissé 5 modules non conformes jusqu'au Gate C d'un lab
  frais. `AGENT.md` du module porte `effort: high`.
- **`check-state-integrity.sh` suit le workstream actif** (GSDA-13) sans jamais écraser `--file`,
  qui reste prioritaire sur toute résolution de compartiment — c'est ce qui permet à la CI de figer
  la cible du gate ADR-063 sur le `STATE.md` de la racine. Trois faux verts et un faux rouge fermés
  au passage, chacun tenu par un cas de test (`.`/`..`, lien symbolique, et les tests qui encodaient
  le défaut au lieu de le révéler).
- **`guard-agent-write.sh`** — le message d'erreur annonçait `effort: <optionnel>` alors que le gate
  l'exige : il énonce désormais les valeurs admises (`low|medium|high|xhigh|max`). Un message qui
  décrit une contrainte périmée est faux même quand le code, lui, est juste.
- **`references/team-kernel.md`** — la marge de profondeur de dispatch est écrite (GSDA-22).
- **`AGENT.md`** — Iron Law 2 révisée (ADR-069, adoption des workstreams GSD).

### Corrigé

- **Les deux gates de compartiment cessent de traverser un lien symbolique** (`T-24-14-C1`, 4ᵉ
  passage du motif dans ce dépôt). `[ -d ]` **suit le lien** : un `.planning/workstreams/<nom>`
  versionné en mode `120000` vers un répertoire hors du lab suffisait à leur faire quitter l'arbre du
  lab. La résolution est déléguée aux primitives partagées de `planning-core`
  (`vf_ws_dir_resolve` / `vf_ws_file_in_ws`) plutôt que réimplémentée une cinquième fois.

  - **`check-state-integrity.sh`** rendait un verdict de conformité sur un `STATE.md` qui **n'est pas
    celui que l'appelant croit vérifier** — exactement le fail-open qui avait motivé ce gate. **Rôle
    de vérification → exit 2, « non vérifiable »** : le refus est audible, la cible n'est ni lue ni
    nommée, seule la raison sort. Le `STATE.md` est contrôlé **au même titre** que le répertoire,
    sinon la fuite se rejoue un cran plus bas.
  - **`check-workstream-pointer.sh`** **bénissait la partition** (« dossier présent », exit 0) — le
    vert sur lequel les trois autres gates s'appuient pour lire le compartiment. Il rend désormais
    **exit 2** (il n'a **pas pu** regarder le compartiment) et non l'état 3 « signal », qui constate
    une absence qu'il **a** pu voir. Trois raisons distinctes, énumération fermée, chacune expliquant
    ce que la traversée aurait ouvert.

  Cas licite **inchangé à l'octet près** : un vrai répertoire reste vert. Fermeture prouvée **par
  mutation sur les quatre gates à la fois** (`planning-core/scripts/tests/test-workstream-symlink-escape.sh`) ;
  `test-check-workstream-pointer.sh` reçoit son cas de non-régression.

## [v1.19.2] — 2026-08-04 (le bandeau cesse de mentir après /vf-update)

### Corrigé
- **`vf-update-run.sh`** — le bandeau « mise à jour disponible » ne se taisait qu'au SECOND
  redémarrage après un `/vf-update` réussi. Cause : `update-banner.sh` (hook SessionStart) lit un
  cache écrit **en tâche de fond par la session précédente**, et `/vf-update` ne le touchait
  jamais — le faux positif d'avant la mise à jour survivait donc intact au premier redémarrage, le
  rafraîchissement de fond de ce démarrage-là ne corrigeant l'état que pour le démarrage
  **suivant**.

  Le correctif invalide le cache **avant** de le régénérer, jamais l'inverse : le vérificateur
  (`check-plugin-update.sh`) garde délibérément l'ancien cache quand le réseau est KO, si bien
  qu'une régénération seule serait aveugle exactement là où elle est nécessaire — un cache absent
  est un état de repli correct, il n'affiche rien et se reconstruit au démarrage suivant. La
  relecture est synchrone et donne la version **post-mise-à-jour** parce que l'étape 4a du skill
  (`claude plugin update`) tourne avant ce script et a déjà réécrit `installed_plugins.json`. Le
  vérificateur est pris dans la copie la plus fraîche du cache plugin (`$NEW/conductor/scripts/`),
  pas dans l'ancienne copie voisine du script — sans quoi la version relue resterait celle d'avant
  la mise à jour. Toute la séquence est best-effort : le script sort toujours 0 après cette étape,
  une mise à jour réussie ne peut jamais être signalée en échec à cause du bandeau.

### Tests
- 3 cas nouveaux dans `test-vf-update.sh`, discriminance prouvée par mutation (pas affirmée) :
  retirer l'appel en queue de script fait virer les cas régénération et invalidation au rouge ;
  garder l'appel mais retirer le `rm -f` préalable (régénération seule) fait virer **seulement**
  le cas d'invalidation au rouge — c'est la mutation qui sépare l'invalidation de la régénération,
  celle qui prouve que l'ordre des deux opérations compte réellement ; inverser l'ordre de
  résolution du vérificateur fait virer le cas de régénération au rouge sur la version relue.
  Fixtures durcies au passage : le cas préexistant de sélection du cache le plus récent stube
  désormais `check-plugin-update.sh`, éliminant le seul accès réseau resté dans la suite.

## [v1.19.1] — 2026-08-04 (course de récupération du lock de driver)

### Corrigé
- **`driver-lock.sh`** — le lock ne s'ouvre plus pendant qu'il se récupère. Récupérer un claim
  périmé **déplaçait** le dossier de lock avant de le recréer ; pendant ce déplacement le chemin
  n'existe pas, et le `mkdir` de la voie normale — qui ne sait pas distinguer « libre » de « en
  cours de récupération » — y entrait. Mesure sur 24 acquisitions concurrentes d'un lock périmé :
  **jusqu'à 5 gagnants simultanés**, sur macOS comme sur Linux. Le `T13.1` rouge du runner CI n'en
  voyait que la pointe (6 concurrents, un seul tirage).

  Ce n'était pas une fenêtre à rétrécir : deux correctifs de fenêtre ont été écrits et **mesurés
  pires que l'original** (14 et 16 rounds hors contrat sur 25, contre 10 ; pires cas 8 et 6 contre
  5). Le protocole lui-même prenait la **présence d'un dossier** pour un lock, alors que le
  récupérer impose de le faire disparaître.

  Le chemin du lock devient un **lien symbolique** vers un dossier de génération : un lien se
  remplace par `rename(2)`, il n'est donc **jamais absent** et il n'y a plus d'instant où le lock
  paraît libre. La génération est écrite **complète avant d'être publiée** (plus de lock « présent
  mais vide »), la récupération est **sérialisée par un mutex** nommé d'après la génération
  observée, et le verdict de péremption est **relu après** l'obtention du mutex — sans quoi un
  retardataire lisant l'âge avant le remplacement et la génération après récupérait un lock
  redevenu frais.

  Deux pièges de shell levés au passage, identiques dans leur forme : sans option, `ln -s A B` et
  `mv A B` **suivent** un lien vers un dossier et opèrent **dedans en rendant 0**. Le lock
  paraissait alors libre à chaque acquisition (8 gagnants sur 8). D'où `ln -sh`/`-sn` et
  `mv -h`/`-T`, qui couvrent BSD et GNU.

### Inchangé (vérifié)
- **`check-branch-claim.sh`** — aucune modification : `[ -d ]` et `"$LOCK/meta"` traversent le
  lien, `branch=` et `worktree=` (ADR-064) restent lus tels quels. Les locks au **format dossier**
  posés par v1.19.0 restent lus et récupérables — une mise à jour ne gèle pas les sessions en
  cours ; vérifié sur un lock réel périmé de 41 964 s.

### Tests
- `T13` passe de 6 concurrents en un tirage à **24 concurrents sur 5 rounds**, égalité stricte
  exigée à chaque round et **les deux bornes gardées** : 0 gagnant est un échec au même titre que
  2. L'antidatage passe par un helper qui ne présume pas de la forme interne du lock, pour qu'un
  prochain changement de protocole ne puisse pas rendre le test vert à vide. Suite `27/27` sur
  trois exécutions ; 20 rounds × 48 concurrents sans un seul écart.

## [v1.19.0] — 2026-08-01 (isolation multi-session, ADR-064, quick 260801-17w)

### Ajouté
- **`check-branch-claim.sh`** — constate qu'un lock de driver **actif** revendique la branche git
  courante **depuis un autre arbre de travail**, et le dit au `SessionStart` (fragment de hooks,
  advisory, lecture seule, silencieux en nominal). Ferme le trou constaté le 2026-07-31 : deux
  sessions ont écrit sur `feat/phase-22-hygiene-doc` sans le savoir, parce que `driver-lock.sh`
  revendiquait une **étape** et n'était consulté **que par les managers** — la session qui est
  passée par-dessus n'en était pas un. Contrat à 4 codes (`0` signal · `3` SAIN · `4` INDÉTERMINÉ
  · `64` usage), où SAIN et INDÉTERMINÉ ne se confondent jamais. Le discriminant est l'**arbre**,
  pas l'owner : deux sessions du même arbre se voient déjà. Comparaison de chemins **normalisée**
  (`pwd -P`) — un faux positif de symlink (`/tmp` → `/private/tmp`) faisait crier le gate sur son
  propre arbre ; débusqué par sa suite, tenu par un cas de régression, discriminance prouvée par
  mutation. Suite dédiée : 18 cas.

### Modifié
- **`driver-lock.sh`** enregistre `branch=` et `worktree=` dans son `meta` à l'acquisition, et les
  **préserve** au heartbeat (même patron que `acquired_epoch`) : un heartbeat émis après un
  `git checkout` ne doit pas revendiquer silencieusement une branche que personne n'a décidé de
  piloter. Champs **additifs** — le contrat JSON de sortie et les consommateurs existants ne
  bougent pas. Un lock posé par une version antérieure (sans ces champs) rend `4` INDÉTERMINÉ
  côté gate, jamais un SAIN de complaisance.

Référence : `docs/ADR.md` ADR-064 (un écrivain = un worktree), `.planning/quick/260801-17w-isolation-multi-session/`.

## [v1.18.0] — 2026-07-31 (alignement gsd-core 1.9.0, Phase 21 plan 21-04)

### Ajouté
- **`check-state-integrity.sh`** — gate anti-régression du frontmatter de `.planning/STATE.md`.
  Compare l'état courant (fichier de travail ou `--current-ref`) à une référence git (`--against`,
  défaut `HEAD`) et échoue si `completed_phases`, `completed_plans`, `total_plans` ou
  `current_phase` ont décru **au sein d'un même jalon** (`milestone:` inchangé — un changement de
  jalon réinitialise légitimement ces compteurs ; un `milestone:` absent/illisible d'un seul côté
  est traité comme une intégrité compromise, jamais comme un skip silencieux). Vérifie en même
  temps que le corps du fichier ne porte **qu'une seule** ligne `^Phase:` (ADR-063) — la même
  fonction amont qui régresse les compteurs (`buildStateFrontmatter`, `gsd-core` 1.9.0) prend aussi
  le premier `^Phase:` du corps sans scope si plusieurs sections en portent une. Transforme en
  échec bruyant l'anomalie d'agrégation constatée le 2026-07-31 (clôture 20-07 :
  `completed_phases` 11→10, `total_plans` 53→49, `completed_plans` 37→29 après une écriture
  d'état, silencieusement). Suite dédiée, 25 cas, dont 3 discriminations machine par comparaison
  directe (garde de jalon, garde de jalon illisible, 1 vs 2 lignes `^Phase:`) — 6 mutants tués
  (garde de régression, garde `^Phase:`, garde de jalon, garde de ref `--against`, champ
  `total_plans` protégé, garde de jalon illisible — ces deux derniers ajoutés par revue
  `vf-reviewer`, PASS après correctif).

## [v1.17.0] — 2026-07-31 (fluidité du flux de dev sans perte de qualité, Phase 20)

### Ajouté
- **`check-agents.sh` / `check-debug-research.sh` — le chemin PAR DÉFAUT (sans `--agents-dir`/
  `--skills-dir`) est enfin exercé par un test.** Fin du faux vert qui en découlait : sur cible
  absente, le défaut sort désormais en 3 INDÉTERMINÉ (jamais un vert silencieux) ; sur cible
  présente non conforme sans flag, il détecte réellement l'anomalie.
- **`hooks.json` : périmètre explicite** — les 2 commandes `SessionStart` de conformité reçoivent
  `--agents-dir`/`--skills-dir`, condition de possibilité du point précédent.
- **`check-agents.sh --hook` : avertissements affichés dès qu'il y en a un**, silence total
  inchangé en régime 0 erreur / 0 avertissement — jusqu'ici le mode hook cachait les warnings.
- **Charset d'un token MCP élargi à `mcp__<serveur>__*`** (joker terminal uniquement), ce que
  produit l'injecteur ADR-051 depuis sa livraison — le gate contredisait son propre injecteur.
- **`check-debug-research.sh --third-party-prefix`** : mécanisme d'exclusion des briques tierces
  porté à l'identique de `check-agents.sh` (même flag, même défaut `gsd-`), pas réinventé.
- **Règle anti-régression** : un agent `memory:` dont le `tools:` omet Write ET Edit doit fermer
  le canal via `disallowedTools` — sinon `memory: project` le rouvre silencieusement au runtime.
  Warning par défaut, erreur en `--strict`.
- **`dag.sh` : `--scope` sur `add`** (périmètre déclaré d'un nœud, rétro-compatible) et `reopen` qui
  force `review_regime=full` sur tout nœud de revue/jointure rouvert — enforcement machine du
  garde-fou « aucun allègement ne s'applique jamais à un diff de comblement ». `status` expose la
  table des fichiers gelés dérivée à la demande (jamais une copie figée).
- **`check-mission-invariants.sh`** (nouveau, gate advisory patronné sur `check-doc-drift.sh`) :
  constate qu'un glob de zone de risque de `.planning/MISSION-INVARIANTS.md` ne matche plus aucun
  fichier suivi. Lecture seule, ne juge jamais.
- **Doctrine du noyau d'équipe mise en conformité** (`references/team-kernel.md` + `README.md`) :
  la ligne de cloisonnement par outils cite désormais le mécanisme réel (`disallowedTools:
  Write, Edit`) qui rend la barrière des 4 juges effective ; nouvelle ligne documentant la classe
  symétrique « un outil déclaré peut être absent au runtime » (filet de repli : le besoin humain
  remonte dans le rapport typé) ; la ligne du plan de bataille cite `--scope` et `review_regime`.

### Corrigé
- **Le changement de périmètre des hooks ci-dessus est une correction de configuration, pas un
  changement de doctrine** — aucune ADR dédiée, cf. `docs/ADR.md`.

Référence : `docs/ADR.md` ADR-051 (révisée), ADR-060 (nouvelle),
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v1.16.0] — 2026-07-28 (moteur GSD dans le récapitulatif de /vf-update, Phase 19)

### Ajouté
- **`skills/vf-update/SKILL.md` : diagnostic à deux volets.** L'étape 1 consultait uniquement le
  plugin et s'arrêtait net sur « VibeFlow est à jour » — un poste dont le plugin est à jour mais
  dont le moteur GSD est resté legacy ne voyait donc jamais la proposition de migration (trou
  audité le 2026-07-28). La sonde best-effort `check-gsd-engine.sh` (module `dev-orchestrator`) est
  désormais consultée **avant** ce stop ; script introuvable → silence total, aucune dégradation
  pour un lab non-dev qui n'installe pas `dev-orchestrator`.
- **Ligne de confirmation indépendante** : quand un moteur legacy est détecté, l'étape 3
  (`AskUserQuestion`) gagne une ligne dédiée à la migration, acceptable ou refusable
  **indépendamment** de la ligne plugin et de la ligne modules — refus sans effet de bord ni
  relance (ADR-031).
- **Bornes des deux flags existants explicitées, aucun flag nouveau créé** (densité ADR-029) :
  `--check` affiche l'état du moteur comme le reste du diagnostic sans jamais demander ;
  `--modules-only` ne propose pas la migration du moteur.
- **Étape 4 : sous-étape « couche moteur »** — invoque `ensure-deps.sh --migrate-engine` et relaie
  sa sortie ; le skill n'invoque jamais l'installeur amont directement (Iron Law 2).
- **§Garde-fous réécrit** : la phrase plaçant la chaîne d'outils interne hors périmètre était
  devenue fausse pour le moteur GSD (sa version est un plafond décidé par VibeFlow dans
  `ensure-deps.sh:166`) — remplacée par une frontière qui couvre le plugin, ses modules et l'état
  du moteur GSD (détecté et proposé, jamais installé sans accord), Superpowers restant
  explicitement hors périmètre. Renvoi vers `docs/ADR.md` ADR-058, qui acte ce changement de
  doctrine.

Référence : `docs/ADR.md` ADR-058, `.planning/phases/VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update/`.

## [v1.15.0] — 2026-07-27 (lint du contenu de `tools:`, Phase 16)

### Ajouté
- **`check-agents.sh` lint désormais le contenu du champ `tools:`** (et `disallowedTools:`),
  jusqu'ici jamais lu au-delà du frontmatter :
  - **syntaxe** des spécificateurs `Outil(...)` — parenthèses équilibrées (non fermée **et**
    fermante en trop, libellés distincts), allowlist vide `Agent()`, entrée vide (`a,,b` et
    `Agent(a,,b)`), charset, espace avant la parenthèse — pour `Agent(` comme pour l'alias legacy
    `Task(` et pour `Bash(` ;
  - **noms d'outils** validés contre le set fermé documenté : warning par défaut, **erreur en
    `--strict`** ;
  - **existence des noms d'agents** en allowlist, par **résolution graduée** anti-faux-positif :
    types natifs et préfixes tiers reconnus (défaut `gsd-`), noms non résolus en **warning même
    sous `--strict`**, erreur **seulement** sous le mode opt-in `--resolve-agents=strict` ;
  - nouveaux flags : `--third-party-prefix=PFX` (accumulatif), `--no-third-party-prefix`,
    `--resolve-agents=lenient|strict` (valeur invalide rejetée, pas de dégradation silencieuse),
    `--agent-registry-dir=PATH` (répétable) ;
  - **ferme la dette** « `--strict` sans périmètre tiers » (66 faux positifs constatés sur un
    scope user) : un fichier agent dont le `name` matche un préfixe tiers n'est plus linté pour la
    charte VibeFlow.
- Tokenizer robuste : split à **profondeur de parenthèses** (plus de coupure naïve sur `,`), 
  dé-quotage des scalaires, tolérance des lignes vides dans une liste bloc YAML (deux
  faux-bloquants corrigés en cours de phase).
- **Limite de portée documentée** : la liste de noms entre parenthèses est **ignorée par le
  runtime** pour un agent dispatché en sous-agent — elle n'est appliquée qu'en incarnation
  fenêtre principale (`claude --agent`). Ce lint fait donc de l'allowlist un **contrat
  documenté désormais enforcé**, pas un bac à sable runtime ; le garant machine de « un seul
  manager actif » reste le verrou de driver (`references/team-kernel.md`).

### Tests
- `test-check-agents.sh` **38 → 58 axes**.

## [v1.14.6] — 2026-07-27

### Corrigé
- `references/team-kernel.md` et `README.md` : formulation du cloisonnement manager→manager
  rendue exacte — la garantie qu'un seul manager pilote une mission est portée par le **verrou
  de driver** (refus de seconde acquisition), pas par une lecture du contenu du champ `tools:`
  des agents que `check-agents.sh` ne valide pas (il ne linte que le frontmatter). Table
  « Implémentations » du team-kernel mise à jour pour refléter les étages croisés dev ↔ design
  livrés en Phase 15 (dev-orchestrator v2.4.0, design-orchestrator v1.3.0).

### Ajouté
- `scripts/tests/test-dag.sh` : T12 — DAG hétérogène cross-métier (nœud design dans une
  frontière dev, ids namespacés, deux juges en parallèle dans la même frontière). Aucun script
  du kernel (`dag.sh`, `driver-lock.sh`) modifié.

## [v1.14.5] — 2026-07-27

### Corrigé
- `driver-lock.sh` : course ABA dans la récupération de lock périmé (violation de l'invariant H1, T13.1 rouge en CI avec 2 « recovered »). Entre le verdict « périmé » d'un concurrent et son `mv`, un autre pouvait récupérer PUIS recréer un lock frais — le `mv` réussissait alors sur ce lock vivant et le volait. Le récupérateur re-vérifie désormais le heartbeat du méta DÉPLACÉ : frais → remise en place + `race-during-recovery`. Fenêtre résiduelle théorique documentée (détectée par le heartbeat du propriétaire déposédé).

## [v1.14.4] — 2026-07-27

### Corrigé
- `driver-lock.sh` : le fallback mtime testait `stat -f %m` (BSD) avant `stat -c %Y` (GNU). Sur Linux, `stat -f` = mode *filesystem* : il imprime un bloc multi-lignes puis échoue, la substitution capturait bloc + fallback → heartbeat non numérique → un lock au meta vide restait « frais éternel » (T12.1/T12.2/T13.1 rouges en CI). Ordre inversé : GNU d'abord, BSD échoue proprement sur `-c`. Reproduit sous ubuntu:24.04.

## [v1.14.3] — 2026-07-27

### Corrigé
- `guard-agent-write.sh` : sous Linux (TMPDIR non défini + `set -u`), un `$TMPDIR` non échappé dans un commentaire du bloc python — chaîne bash double-quotée — avortait TOUTE la commande : le guard devenait muet (fail-open) et ne déniait plus jamais un agent non conforme. Reproduit sous ubuntu:24.04 (T11 de test-check-agents), commentaire reformulé sans dollar nu.

## [v1.14.2] — 2026-07-26

### Ajouté
- `check-overlaps.sh` (ADR-057) : 3 nouvelles paires documentées dans la table des
  recouvrements connus — `consolidator × gsd-mempalace-capture`, `consolidator ×
  gsd-mempalace-recall` (consolidator = canon mémoire de lab, in-repo) et `vibeflow-dev ×
  gsd-next` (vibeflow-dev = front door unique du lab, agent routeur). Tests T15/T16 ajoutés en
  couverture (Phase 11, vague 11-03).

## [v1.14.1] — 2026-07-26

### Corrigé
- Recettes UAT sur labs vierges : `vibeflow-install` retiré du frontmatter (commande plugin, pas skill de lab) ; `check-agents.sh` résout les skills déclarés aussi par leur frontmatter `name:` ; `framework-version.sh stamp` retombe sur `.vibeflow-installed` en lab isolé ; vf-new-lab — cascade de résolution des scripts prescrite, Phase 7 express explicite, chemin `.claude/memory/` écrit, ordonnancement Gate C ↔ fabrication de fond spécifié, marqueur `[DÉRIVÉ — à affiner]` verbatim.

## [v1.14.0] — 2026-07-25

### Ajouté
- Team-kernel : `dag.sh` + `driver-lock.sh` extraits du dev-orchestrator en socle transverse (`references/team-kernel.md`, contrat universel manager/workers/juges). Mode **lab express** ≤ 15 min dans vf-new-lab (3 questions, [DÉRIVÉ] assumé, Gate C intact, dette d'express). ADR-057 : détecteur `check-overlaps.sh` des recouvrements avec les briques tierces (advisory, 7 paires, 14 tests).

## [v1.13.0] — 2026-07-25

### Ajouté
- Gouvernance proportionnée au profil : en profil léger, le registre EVALS n'est plus posé à l'init (créé à la première éval réelle) — gates A/B/C intacts. Références basculées sur le modèle agentique (gsd-progress, gsd-new-project…).

## [v1.12.3] — 2026-07-25

### Corrigé
- Gates `check-agents.sh` / `check-debug-research.sh` : mode `--strict` — cible vide → exit 3 (indéterminé ≠ conforme, F13), opt-out `--allow-empty` ; défauts et câblages hook inchangés.

## [v1.12.2] — 2026-07-25 (gabarit de description sur les trois verbes)

### Corrigé
- **`vf-calibrate` / `vf-update` / `vf-new-lab`** alignés sur le gabarit de description issu de
  l'étape 12 (contre-exemples nommant les verbes voisins + portée d'invocation). Sans eux, ces
  trois verbes restaient hors du dispositif de démarcation : `vf-calibrate` et `vf-update`
  revendiquaient tous deux littéralement « mets à jour VibeFlow », sans rien pour les départager
  au déclenchement. La frontière est désormais explicite — `vf-update` **installe** la nouvelle
  version, `vf-calibrate` **réaligne la structure du lab** une fois celle-ci posée.
- Collisions également démarquées vers l'extérieur du module : `/vf-new-lab` ↔ `/vf-init`
  (dossier de code) et `/vf-new-lab` ↔ `/vf-planning` (socle documentaire).

## [v1.12.1] — 2026-07-23 (portabilité Windows — ADR-054)

### Corrigé
- **`check-plugin-update.sh`** : strip du `\r` sur la capture de version installée (python/claude
  natifs Windows émettent du CRLF) — un CR brut non échappé aurait produit un cache JSON invalide
  et tué le bandeau update SessionStart sur les postes Windows.
- **`framework-version.sh`** : `norm()` retire tout `\r` résiduel + wrapper `jqx` sur le call site —
  sous un jq Windows natif (sorties CRLF en mode texte), `drift` comparait `"2.27.1\r"` à `"2.27.1"`
  et signalait un écart en continu (faux RETARD structurel).
- **`vf-calibrate` / `vf-new-lab` (SKILL.md)** : mentions de scripts au nom nu ou au préfixe
  incohérent (3 formes différentes pour `framework-version.sh` dans le même document) → chemins
  qualifiés au point d'usage (`.claude/scripts/…`, `${CLAUDE_PLUGIN_ROOT}/_internal/…`). Un nom nu
  force l'exécutant à deviner parmi ~10 dossiers `scripts/` (bug d'install vécu, ADR-054).
- **Hooks python3 (2e rapport terrain Windows)** : résolution d'interpréteur par CHEMIN (rejet du
  stub Microsoft Store `WindowsApps`, repli `python`, zéro spawn ajouté) dans `guard-agent-write.sh`,
  `check-agents.sh`, `check-debug-research.sh`, `update-banner.sh`, `check-plugin-update.sh` — le
  stub passe `command -v python3` : les gardes étaient inertes en paraissant installées (ADR-054).

## [v1.12.0] — 2026-07-22 (détection de migration legacy, scope-aware)

### Ajouté
- **`check-legacy.sh`** : préflight scope-aware qui détecte si un lab est sur l'ANCIENNE méthode
  (pré ADR-052/053). Inspecte **les deux** racines (`$HOME/.claude` = user, `./.claude` = projet/local,
  ID4) et, par module concerné installé, signale `legacy` (version < minimum : dev-orchestrator v1.7.0,
  consolidator v1.5.0) ou `drift` (version OK mais artefacts manquants). Sortie humaine (nudge) ou
  `--print` JSON. Exit 0 toujours (informatif). 8 tests.
- **`update-banner.sh`** (hook SessionStart) étendu : fusionne en **un seul** `systemMessage` le nudge de
  mise à jour du plugin ET le nudge de méthode legacy (via `check-legacy.sh`). Un lab déjà à la bonne
  version de plugin mais aux modules non migrés est désormais détecté au démarrage. Boucle fermée : un
  `drift` détecté est réparé par `/vf-update` (`sync_module_governance` re-copie les artefacts).

## [v1.11.3] — 2026-07-20 (audit robustesse hooks — 2e vague, gate agents fiabilisé)

### Corrigé
- **`check-agents.sh` (parseur YAML minimal → 2 faux positifs bloquants + 1 contournement)** :
  scalaires quotés (`name: "x"`, parfois OBLIGATOIRES en YAML) rejetés « invalide » → déquotage ;
  `description:` en plain scalar multi-ligne perdue (« champ requis manquant ») → typage différé ;
  `skills:` en chaîne plate (`skills: a, b`) sautait silencieusement TOUT le gate anti-hallucination
  même en `--strict` → normalisation en liste. BOM UTF-8 toléré (`utf-8-sig`).
- **`guard-agent-write.sh`** : anti-trappe fail-closed — un crash interne du checker (rc≠0 SANS
  diagnostic ✗) produisait un deny générique sur un agent conforme → désormais fail-open ;
  portée restreinte au LAB COURANT (en install user-scope, un agent perso `~/.claude/agents` ou
  un autre projet n'est plus soumis à la doctrine du lab) avec `realpath` des deux côtés
  (piège symlink macOS /var→/private/var) ; `--skills-dir` dérivé du lab CIBLE du file_path
  (verdict indépendant du CWD du hook) ; limites assumées documentées en tête.
- **`check-debug-research.sh`** : filet de signature resserré — `crash-free` (KPI mobile) et
  `diagnos` isolé (« Diagnostique la santé du funnel », « pass/fail + diagnostic ») ne sont plus
  du dépannage (`diagnos` exige une co-occurrence bug/erreur/panne) ; la brique livrée
  `vf-test-runner` (mobile-test-team) n'est plus flaguée à chaque SessionStart.
- `check-plugin-update.sh` : verrou mkdir (stale 300s) contre les instances parallèles, bornes
  réseau `http.lowSpeedLimit/Time` (TCP qui rampe > 1 min sinon), écriture du cache atomique.

### Tests
- `test-check-agents.sh` 14 → 20 (quotes, multi-ligne, skills chaîne + --strict, BOM, crash
  checker → fail-open, hors-lab → allow) ; `test-check-debug-research.sh` 9 → 12 (crash-free,
  diagnostic métier, dogfood briques mobile-test-team contre le linter livré).

## [v1.11.2] — 2026-07-20 (audit robustesse hooks)

### Corrigé
- **`update-banner.sh` : le rafraîchissement du cache était MORT sur macOS** — `setsid` n'existe
  pas sur macOS et son échec (127) en arrière-plan est asynchrone : le pattern
  `( setsid … & ) || fallback` sortait toujours 0 → le fallback ne se déclenchait jamais → cache
  jamais rafraîchi (démontré : cache local figé au 12/07). Désormais : `command -v setsid` testé
  AVANT, stdin fermé (`</dev/null`). Vérifié e2e : cache réécrit avec données fraîches.
- `check-plugin-update.sh` : `GIT_TERMINAL_PROMPT=0` sur le `ls-remote` — un repo privé sans
  credential helper échoue proprement au lieu de pendre sur un prompt en tâche de fond.
- `guard-agent-write.sh` : préfiltre pur-bash avant python3 (~6ms vs ~90ms sur tout Write sans
  rapport avec `.claude/` — le hook tourne sur CHAQUE Write du lab ; surensemble strict justifié
  en commentaire) ; frontière de chemin exacte (`my.claude/agents` ne matche plus — même classe
  de faux positif que consolidator CSL-12) + `normpath`.

## [v1.11.1] — 2026-07-19 (ADR-051)

### Ajouté
- **`check-agents.sh`** : `vf-mcp-consumer` ajouté au set `KNOWN` des champs frontmatter reconnus —
  le flag qui marque un agent exécutant recevant l'allowlist MCP dérivée du lab (ADR-051) n'est plus
  signalé « champ inconnu ». Le sélecteur `vf-mcp-consumer` EST le point d'enforcement de l'injection
  (data-driven, aucun nom d'agent en dur).
- **`skills/vf-calibrate`** : étape « ré-affirmer l'allowlist MCP » — quand le `./.mcp.json` du lab
  gagne/perd un serveur **sans** bump de module, re-jouer `inject-mcp-tools.sh` (agents flaggés +
  `gsd-executor`). Rappel du redémarrage de session requis.

## [v1.11.0] — 2026-07-16 (ADR-048 — orchestrateur métier systématique)

### Ajouté
- `vf-new-lab` Phase 7 **point 5bis** : dès **≥2 agents métier**, pose d'office un **orchestrateur métier**
  (copie verbatim du skill `metier-orchestration` + instanciation de `orchestrator-template.md` parametré
  au métier). Seuil < 2 → pas d'orchestrateur ; métier = code → rôle tenu par `dev-orchestrator` (pas de doublon).
- `references/bootstrap-method.md` : règle de dérivation « ≥2 agents → orchestrateur métier » + exemple mis à jour.

### Corrigé
- Renvoi circulaire : les bundles pointaient « l'orchestration » vers le conductor, qui ne fait pas le travail
  métier. L'orchestration métier est désormais portée par l'orchestrateur métier posé ; le conductor reste méta.

## [v1.10.0] — 2026-07-11 (ADR-047 — skill-creator dans la baseline)

### Ajouté
- `module.json` : **`skill-creator` ajouté aux `requires`**. C'est l'outil que `vf-new-lab` invoque
  en Phase 5 (fan-out `subagent_type: skill-creator`) et que le Gate C exige pour créer un skill
  manquant. Il est le **canal unique de création de skills** (« Sole authorized channel for skill
  creation ») — donc une **dépendance dure** du conductor, au même titre que `validator`. Comme le
  conductor est `mandatory`, `skill-creator` est désormais **posé d'office à chaque install** (sa
  fermeture transitive est tirée par `--with-deps`), avant toute création de lab.

### Corrigé
- Régression silencieuse : `vf-new-lab` fanned out vers un `subagent_type: skill-creator` **jamais
  installé** (absent de `requires` ET de la liste « Typiquement » de la Phase 7). Les skills du lab
  étaient donc soit non fabriqués, soit rédigés à la main hors pipeline (perte de l'eval/qualité).
- `vf-new-lab` Phase 7 (point 2) : `skill-creator` ajouté à la liste des modules typiques + garde-fou
  explicite « jamais rédiger un skill à la main — canal unique skill-creator, même pour une procédure
  interne ». `installer/SKILL.md` : récap d'exemple de la fermeture du conductor mis à jour.

## [v1.9.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Lint `scripts/check-debug-research.sh`** : gate déterministe de la présence d'une phase de
  recherche documentaire avant debug dans les briques de dépannage d'un lab (ADR-045). Même contrat
  que `check-agents.sh` : `--strict` / `--hook` / `--file`, symboles `✓ ✗ ⚠`, exit 0/1, fail-open
  si `python3` absent. Consommé par le `vibeflow-validator` en Phase 2 et branché en advisory
  SessionStart (`--hook || true`) dans `hooks/hooks.json`.
- Suite de tests `scripts/tests/test-check-debug-research.sh` (9 cas, tous verts).

## [v1.8.2] — 2026-07-07

### Corrigé
- Engine d'update (`vibeflow-update.sh`) : `update --all` (donc `/vf-update`) **garantit
  désormais la baseline obligatoire** (INST-02a). Un module `mandatory` publié après la
  configuration d'un lab — typiquement `conductor` lui-même sur un lab antérieur à v2.13.0 —
  était **ignoré à vie** : `update --all` n'itérait que sur le registre `.vibeflow-installed`,
  donc ni les scripts ni les hooks du module manquant n'étaient posés. Conséquence directe :
  le **bandeau de mise à jour** (`update-banner.sh`, SessionStart) ne pouvait jamais s'afficher.
  Nouvelle fonction `ensure_mandatory_baseline` : installe la fermeture transitive des modules
  `mandatory` absents (data-driven via `module.json`, **aucun nom de module en dur**).

### Durci
- `update <module>` sur un module **déjà à jour** re-synchronise désormais sa gouvernance
  (re-pose les scripts + re-merge les hooks, idempotent) au lieu de sortir tôt (`return 0`) —
  `/vf-update` devient auto-réparateur si un `hooks.json` a dérivé sans bump de `VERSION`.
- Tests : `test-vf-update.sh` couvre la baseline `mandatory` (module absent rattrapé + closure)
  et la resync gouvernance (hook re-mergé à version inchangée). Extraction DRY de
  `copy_module_scripts` (partagée entre install et resync).

## [v1.8.1] — 2026-07-07

### Corrigé
- Skill `vf-update` : la couche plugin utilise désormais l'**identifiant complet**
  `claude plugin update vibeflow@vibeflow-os` (le nom nu peut échouer par « Plugin not found »
  quand le cache de catalogue est périmé) + parade documentée (`marketplace update` / purge du
  `plugin-catalog-cache.json`). Constaté en conditions réelles lors du premier update 2.4.1 → 2.19.0.

## [v1.8.0] — 2026-07-07

### Ajouté
- **Mise à jour du plugin en un geste** — commande `/vf-update` + skill `vf-update`.
  - `check-plugin-update.sh` — compare la version installée (`installed_plugins.json`) au **dernier
    tag GitHub** (`git ls-remote --tags`, source de vérité depuis la discipline de tags), écrit un
    cache `~/.cache/vibeflow/update-check.json`.
  - `update-banner.sh` — hook **SessionStart** : signale « mise à jour disponible X → Y, lance
    /vf-update » depuis le cache, puis rafraîchit le cache en tâche de fond. Câblé dans `hooks.json`.
  - `vf-update-run.sh` — re-matérialise les modules installés depuis le **cache le plus récent**
    (localisé lui-même, car la session courante garde l'ancien `${CLAUDE_PLUGIN_ROOT}`).
  - Le skill orchestre les **deux couches** sous confirmation (ADR-031) : `claude plugin update
    vibeflow` (marketplace) puis engine `update --all` (modules), + rappel de redémarrage.
  - Tests : `test-vf-update.sh` (bandeau + sélection semver du cache) — 4/4.

## [v1.7.0] — 2026-07-07

### Ajouté
- Convention **`vf-internal: true`** (Pattern 12) : un worker interne le déclare dans son frontmatter.
  - `generate-agent-commands.sh` — le sweep **saute** ces agents : aucune commande d'incarnation
    `/<worker>` exposée à l'utilisateur (un worker dispatché uniquement par un orchestrateur n'a
    pas à être invocable en direct). Le mode `--agent` explicite reste inchangé.
  - `check-agents.sh` — `vf-internal` ajouté aux champs connus (plus de warning « champ inconnu »).

## [v1.6.0] — 2026-07-05 (ADR-044 — agents natifs machine-enforced)

### Ajouté
- `check-agents.sh` — lint machine de la conformité NATIVE des agents (.claude/agents/*.md) :
  frontmatter présent, name/description/model/memory requis, enums valides (référentiel doc
  officielle 2026-07-05), skills déclarés EXISTANTS (--strict), champs inconnus signalés (typos),
  BUDGET DE PRÉCHARGEMENT (skills: injecte le SKILL.md entier au startup — warn > 200L/skill,
  erreur > 1200L cumulées VF_PRELOAD_MAX, erreur si disable-model-invocation, warn si context:fork).
- `guard-agent-write.sh` — hook PreToolUse(Write) : un agent non natif ne peut plus être ÉCRIT
  dans .claude/agents/ (deny avec erreurs précises + squelette canonique).
- `hooks/hooks.json` — guard Write + check-agents SessionStart posés automatiquement à l'install.
- vf-new-lab Phase 7 : squelette frontmatter canonique OBLIGATOIRE (point 5) + règle de chargement
  du contexte (précharger ≤ 200L systématiques, on-demand sinon) + format de retour standard et
  pont d'escalade C4 dans le body de chaque agent + **Gate C étendu** (check-agents --strict).

### Décision
- contracts.md n'est PAS posé à l'init (pas un mécanisme runtime — sa valeur, format de retour +
  escalade, vit dans le body des agents et pointe vers conductor-references/contracts.md).

### Tests
- `test-check-agents.sh` (14 : lint 10 + guard 4).


## [v1.5.0] — 2026-07-04 (ADR-043)

### Ajouté
- vf-new-lab Phase 7 **GATE C — Conformité machine (BLOQUANT)** : l'init ne se conclut pas sans
  `check-registres.sh --strict` exit 0 + hooks de gouvernance présents dans settings.json.
- Phase 7 point 4 : après pose des registres, indexation par la machine
  (`reindex.sh --all --apply`) — jamais d'index rédigé à la main.

### Modifié
- Canon DECISIONS.md/DEC-XXX (references/contracts.md).

## v1.3.0 — 2026-06-24

`vf-new-lab` évolue en **Lab Factory clarification-first** (pipeline 7 phases). L'init ne pose plus un
squelette : elle clarifie en profondeur (gate machine-enforced), dérive un manifeste de capacités, et
**fabrique** les skills + auditeurs. Rétrocompatible (toujours invocable « crée un lab »), profondeur
adaptative au profil.

### Ajouté
- **Clarification-first** : Phase Triage (greenfield/brownfield + profil adaptatif) → Scan brownfield
  (explorer) → élicitation section par section avec **menu numéroté** (pattern BMAD) → **Gate A**
  (`[À CLARIFIER]` bloquant sur `LAB_BRIEF.md`). Refs `elicitation-methods.md` + `completeness-gate.md`.
- **T2 — Manifeste de capacités** : dérive les capacités (savoir/compétence/procédure), **Gate B**
  (justification obligatoire), proportionnalité au profil. Ref `capability-manifest.md` +
  `scripts/proportion-capabilities.sh` (tests 9/9).
- **T3 — Fan-out skill-creator** : fabrication parallèle (N × skill-creator, un par capacité P0) +
  anti-slop (gate capacité + eval par skill + critique de complétude). Ref `skill-fanout.md`.
- **T4 — Ficelage auditeurs** : un auditeur par procédure générative via `audit-architecture` (verdict
  bloquant). Ref `procedure-audit-wiring.md`.
- **T5 — Assemblage** : agents câblés sur les skills fabriqués, planning v2 compartiments, 5 registres
  (dont EVALS), garde-fous, stamp. Récap adaptatif (pédagogique en mode découverte).

## v1.2.0 — 2026-06-23

Câblage de la **topologie à compartiments** (planning-core v2.0.0) dans l'init, l'update et le pipeline.

### Ajouté / Modifié
- `vf-new-lab` : étape de dérivation « topologie du lab » (mono-objectif vs compartiments) + typage
  `deliverable`/`continuous`/infra + seuil d'autonomie ; scaffolding *steering lab + INDEX + plan par
  compartiment qualifié*. Garde-fou « jamais un `.planning/` par compartiment systématique ».
- `vf-calibrate` : cas **planning v2** (breaking-doctrine) routé vers la recette de migration sans perte.
- `references/migration-playbook.md` : recette **§2bis migration planning v2 sans perte de données**
  (détection de dette → typage → récupération de l'existant en `_archive/` → désengorgement mémoire → INDEX).
- `references/conductor-pipeline.md` : étape compartiments + garde-fou transverse.

## v1.1.0 — 2026-06-11

`vf-new-lab` rendu **bundle-aware** + correction d'un pointeur cassé.

### Corrigé
- Pointeur cassé : `vf-new-lab` référençait `references/bootstrap-method.md` (introuvable au runtime
  car le skill et les references s'installent à des emplacements distincts) → pointe désormais vers
  `.claude/agents/conductor-references/bootstrap-method.md` (emplacement réel d'install).

### Ajouté
- Mode bundle métier : si un bundle est installé (`docs/<metier>-bundle/`), `vf-new-lab` lit son
  `content/BUNDLE.md` et **instancie** les blueprints `content/agents/*.blueprint.md` au lieu de
  dériver de zéro — le châssis conforme est déjà porté par le bundle. Compatible business-pilot /
  content / growth.

## v1.0.0 — 2026-06-11

Release initiale. Agent méta orchestrateur central + gardien du framework, distribué dans chaque lab.
Comble 4 trous identifiés à l'audit du plugin (cf. README).

### Ajouté
- **Agent `vibeflow-conductor`** (AGENT.md, ≤250L) — porte d'entrée méta pour configurer/vérifier/
  mettre à jour/migrer un lab. Route et délègue (installeur, validator, planning-core, consolidator).
  4 rôles : configurateur / vérificateur / calibreur / gardien. N'est pas appelé en continu.
- **C2 — `vf-new-lab`** : bootstrap de lab **universel** (non-dev en première classe). Cadrage 5
  questions (ce que l'utilisateur sait déjà) → dérivation → scaffolding adapté au métier. Exemple
  « acquisition » de bout en bout. Ne présume jamais dev.
- **C3 — `vf-calibrate`** + `scripts/framework-version.sh` : propagation d'update façon GSD.
  Détection de drift framework ↔ lab (current/recorded/stamp/drift, sémver portable), migration sous
  validation humaine, surfaçage SessionStart **opt-in**. + tests (8/8 PASS).
- **C4 — `references/contracts.md`** : protocole d'escalade sous-agents → conductor (gardien central).
- Références on-demand : `conductor-pipeline.md`, `migration-playbook.md`, `bootstrap-method.md`.

### Notes
- `type: agent + skills + scripts + references`. `requires: [planning-core, validator]`.
- Respecte ADR-031 (détecter/proposer, jamais corriger/migrer sans validation humaine), ADR-029
  (densité), ADR-030 (skills natifs, déléguer sans réimplémenter).
- Ne fait JAMAIS le travail métier — il configure et garde le lab.
