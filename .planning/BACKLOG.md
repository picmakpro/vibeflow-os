## Choisir la partition du planning AU DÉMARRAGE, pas après coup — demandé 2026-09-23

**Statut : besoin exprimé par Samuel (session principale, 2026-09-23), non cadré.** À passer par
`/gsd-discuss-phase` avant toute écriture de code — rien n'est décidé ici.

**Le besoin, dans ses mots** : « on devrait pouvoir choisir si on partitionne ou pas dès le début,
et proposer des skills et scripts pour ça. On doit faciliter le travail. »

**Ce qui le motive, mesuré le jour même.** La partition réelle de ce dépôt (D-02, PR #94) a coûté
**13 commits**. Le geste de partition lui-même tenait en une commande : `workstream create`. Tout
le reste — l'essentiel — a consisté à réparer ce qui **supposait un planning unique** : la CI qui
traitait la racine comme l'oracle de sa propre non-partition, le ledger d'exigences, `E4` de
`check-mission-exit.sh`, `check-state-integrity`. Partitionner au démarrage n'économise pas la
commande, il économise **cette réparation**, parce que rien n'a encore eu le temps de supposer le
contraire.

**Ce qui va dans le même sens** : ADR-069 interdit déjà de partitionner tant qu'une phase est en
vol. Le seul moment structurellement sûr est donc le démarrage — la doctrine pointe déjà vers ce
besoin sans le servir.

**La réserve, à trancher au cadrage.** Partitionner un lab que personne ne travaille à plusieurs
n'apporte rien et coûte : il faut passer `--ws` partout, ou vivre avec un pointeur qu'on oublie.
La valeur apparaît quand **deux flux avancent en parallèle sur des périmètres disjoints** — c'est
exactement le cas de ce dépôt avec Willy, et ce n'est pas le cas de la plupart des labs. Un
« partitionner par défaut » serait une sur-ingénierie ; un « choix éclairé posé au bon moment »
est le vrai besoin. La question à poser à l'initialisation n'est donc pas « veux-tu des
workstreams ? » (jargon) mais « plusieurs personnes ou agents vont-ils travailler en parallèle sur
des sujets séparés ? ».

**Le piège à ne pas multiplier.** La partition de ce dépôt a laissé un angle mort déjà consigné
plus bas dans ce fichier : un gate câblé en dur sur un compartiment laisse les autres **sans
garde** (`ci.yml` vise `fiabilite`, `gouvernance` n'est jamais vérifié). Si VibeFlow se met à
proposer la partition dès le départ, ce défaut se reproduira dans chaque lab qui accepte. Le
remède connu — itérer sur les compartiments présents sur le disque, jamais revenir à une
résolution par `GSD_WORKSTREAM` — devrait être livré **avec** la capacité, pas après elle.

**Pistes, non arbitrées :**
- Une question à l'initialisation d'un lab (`vibeflow-conductor`), formulée en langage d'usage et
  non en jargon de moteur.
- Des gabarits de gates et de CI **nés workstream-aware**, plutôt que réparés après coup.
- Un skill qui porte le geste de bascule pour un lab déjà démarré, avec la précondition d'ADR-069
  vérifiée par machine (aucune phase en vol) plutôt que rappelée en prose.
- La partie distribuable existe déjà : le moteur `@opengsd/gsd-core` fournit `workstream
  create/list` et `--ws` ; VibeFlow fournit déjà la doctrine (`workstreams.md`, ADR-069) et les
  gardes (`check-divergence.sh`, `check-workstream-pointer.sh`, `workstream-policy.sh`). Le
  manquant est **l'ergonomie du choix**, pas la mécanique.

**Preuve d'usage à exiger au cadrage** : un lab neuf initialisé en mode partitionné dont les gates
passent au vert sur **chaque** compartiment, sans réparation manuelle — sinon la capacité ne fait
que déplacer les 13 commits chez l'utilisateur.

## Traçabilité des arbitrages humains dans les messages de commit — ADOPTÉE 2026-09-10

**Statut : proposition soumise à validation humaine (ADR-031). Rien n'est appliqué.** Émise par
`vf-dev-manager` le 2026-09-10, en marge de la Phase 39.

**Le constat.** Le commit `8fc4b45` porte « (arbitrage Samuel) » dans son sujet. L'attribution était
**exacte** — vérifiée après coup : question posée par AskUserQuestion en session principale le
2026-09-09, trois options soumises, réponse (a). Mais elle n'était **pas vérifiable depuis le
commit** : le texte a exactement la même forme qu'il soit vrai ou fabriqué. C'est le lecteur
d'après qui paie — et ce lab a déjà connu un arbitrage fabriqué de cette façon (incident Phase 18).

**Le risque particulier** : quand le résultat coïncide avec ce que le relecteur recommandait
lui-même, la vérification d'origine est précisément ce qu'on omet.

**La forme proposée.** Un message de commit qui invoque un arbitrage humain nomme **le canal et la
date**, pas seulement la personne :

```
(arbitrage Samuel, AskUserQuestion session principale, 2026-09-09)
```

L'affirmation devient vérifiable au lieu d'être crue. Coût : quelques mots. Aucun outillage, aucun
gate — une convention de rédaction, applicable aux agents comme aux humains.

**TRANCHÉ le 2026-09-10** (arbitrage Samuel, AskUserQuestion session principale, 2026-09-10) :
**adoptée**, sans gate machine — la variante outillée est explicitement écartée, la forme écrite
suffit. Inscrite dans `plugin/dev-orchestrator/references/mission-contracts.md`.

**Reliquat, geste humain** : l'inscription d'une ligne dans le `CLAUDE.md` du dépôt (là où vivent les
conventions de commit) reste à faire **par Samuel**. Un agent ne modifie pas le `CLAUDE.md` d'un
dépôt sur instruction relayée par un autre agent — la décision est authentique, c'est le canal qui ne
convient pas pour ce fichier-là.

## Les juges d'un artefact de planning ne gardent pas ce qu'on croit — mesuré 2026-09-23

**Statut : constat mesuré, NON réparé. Différé volontairement** — réparer ici élargirait les Phases
41.1/41.2 au-delà de leur périmètre (consigne de la session principale, 2026-09-23). Matrice établie
sur fixtures jetables pendant la mission « généraliser le remède de partition »
(`.planning/missions/2026-09-23-generalisation-remede-partition.md`).

**1. `check-state-integrity.sh --file <chemin ABSOLU>` saute son invariant principal EN SILENCE.**
Le script interpole `FILE_REL` verbatim dans `git show "$AGAINST_REF:$FILE_REL"` (l.201). Un chemin
absolu fait échouer ce `git show` → `HAVE_BASELINE=0` → **l'invariant 1 (non-régression des
compteurs, le cœur d'ADR-063) n'est jamais armé**. Il ne reste que le comptage des lignes `^Phase:`.
Même fichier, même gate, deux verdicts :

```
--file /abs/…/switched/STATE.md                  → « aucune référence à HEAD … invariant ignoré »  rc=0
--file .planning/workstreams/switched/STATE.md   → « current_phase introuvable »                   rc=2
```

C'est un **fail-open silencieux** : le gate rend vert ce qu'il devrait refuser, sans rien signaler.
Découvert **deux fois indépendamment le même jour** — par la mesure de la matrice, et par un
plan-checker frais qui constatait qu'une fixture de mutation était verte des deux côtés. La gravité
tient au contexte : c'est le gate que la Phase 41.1 généralise à **tous** les compartiments.
Généraliser un gate qui sait se taire, c'est généraliser le silence.

**2. `check-dev-bootstrap.sh` est un ROUTEUR, pas un gate.** Son unique `exit 1` (l.241) est **à
l'intérieur du programme `awk`** de `extract_frontmatter` : c'est le code de sortie de l'awk, donc le
statut de retour de la fonction, jamais celui du script. Énumération des `exit` du script :
`{"0":[100,122,301,328], "1":[241], "64":[95,101,108]}`. Deux compartiments identiques sauf
`current_phase` rendent **le même rc=3** ; seul le stdout change (170 octets contre 0). Toute doctrine
ou tout plan qui le compte comme un juge capable de refuser se trompe. *Sémantique inversée à
connaître : pour ce script, `0` est le MAUVAIS état (démarrage incomplet).*

**3. `status` n'est exigé par aucun juge au sens du code de sortie.** Son absence ne coûte que le
signal `[gsd-engine]` (stdout 170 → 0 octet). Gardé par un signal, pas par un verdict.

**4. `REQUIREMENTS.md` dans un compartiment n'est lu par AUCUN juge.** Les cinq juges interrogés —
`check-state-integrity`, `check-dev-bootstrap`, `check-divergence`, `detect-gsd-engine`,
`check-requirements-survival` — rendent des sorties **identiques** avec et sans lui. Le seul script
qui le nomme vise `.planning/REQUIREMENTS.md` à la **racine**, exige un jalon clos, et plafonne à
`rc=3`.

> **Ne pas le retirer de la définition pour autant** (décision de la session principale, 2026-09-23) :
> une exigence sans juge est une **dette à nommer, pas un champ à supprimer**. Le supprimer ferait
> disparaître le besoin en même temps que le contrôle manquant. `REQUIREMENTS.md` reste dans WSAW-05 ;
> ce qui manque, c'est son juge.

**5. Aucune commande unique du moteur ne produit un compartiment pleinement conforme.**
`workstream create` rend un stub (rc=2, `milestone` introuvable) ; `state.milestone-switch --ws`
améliore mais ne suffit pas (rc=2, `current_phase` introuvable) ; `gsd-new-milestone --ws` n'est pas
scriptable (workflow de 719 lignes, 7 gates `AskUserQuestion`, aucun drapeau de bypass). L'état qui
satisfait tous les juges à la fois existe — il demande `state.milestone-switch` **plus** l'ajout à la
main de `current_phase`, `status`, `ROADMAP.md` et d'au moins un dossier de phase cohérent.

**Matrice mesurée** (fixture committée, chemins relatifs) :

| état du compartiment | `check-state-integrity` | `check-dev-bootstrap` | `detect-gsd-engine` | `check-divergence` |
|---|---|---|---|---|
| stub nu (`workstream create`) | **2** | 0 `[bootstrap]` | 3 | 0 |
| après `state.milestone-switch --ws` | **2** | 0 `[bootstrap]` | 0 | 0 |
| idem + ROADMAP + REQUIREMENTS | **2** | 3 (stdout vide) | 0 | 0 |
| conforme au sens WSAW-05 | **0** ✓ | 3 `[gsd-engine]` | 0 | 0 |
| corrompu | **2** | 0 `[bootstrap]` | 3 | 0 |

**TRANCHÉ le 2026-09-23** (décision de la session principale, sur remontée du manager) : le
fail-open du point 1 est **fermé dans la Phase 41.1**. Ce n'est pas un élargissement de périmètre mais
une **condition de validité de ce que la phase livre** — elle multiplie ce gate par N compartiments ;
s'il sait rendre vert en sautant son invariant principal, elle industrialise un faux vert. Fermeture
**au plus petit** : le chemin non résoluble est **rejeté** (code 64, erreur d'usage, message nommant
la cause), jamais converti ni replié ; tout invariant sauté est **annoncé**, quel qu'en soit le
motif ; et la fermeture se prouve par mutation — le même artefact fautif rend rouge en relatif et 64
en absolu, et la fixture de `41.1-06` redevient discriminante.

**Ce qui reste ouvert ici** : même une fois ce cas fermé, la **classe** « gate qui saute un invariant
en silence » reste à balayer sur les autres gates du dépôt. C'est cette classe, et non l'instance,
qui justifie cette entrée au backlog.

# Backlog — idées différées (hors milestone courant)

## Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` — DIFFÉRÉ

**Capturé :** 2026-08-18, hygiène documentaire de clôture de la Phase 18 (mandat vf-coder). Hors
périmètre de cette phase (aucun code de test n'est touché) — remonté sans corriger.

**Le défaut :** chaque suite de `plugin/dev-orchestrator/scripts/tests/` imprime son bilan dans un
format textuel différent. Mesuré en ré-exécutant les 12 suites (2026-08-18) :

- `== résultat : N ok, 0 ko ==` (minuscules) — **7 suites** : `test-check-dev-bootstrap.sh`,
  `test-check-doc-drift.sh`, `test-check-gsd-config.sh`, `test-check-gsd-engine.sh`,
  `test-check-requirements-survival.sh`, `test-discover-unintegrated-docs.sh`,
  `test-restore-requirements-ledger.sh`.
- `== résultat : N OK / 0 KO ==` — **1 suite** : `test-hook-exit-contract.sh`.
- `== résultat : N OK / 0 KO / 0 SKIP ==` — **1 suite** : `test-dev-orchestrator.sh` (sur-ensemble
  textuel du format précédent : un collecteur qui grep la sous-chaîne `OK / 0 KO` capte les DEUX
  formats à tort comme s'ils étaient identiques).
- `== Résultat : N OK, 0 KO, 0 SKIP ==` (majuscule `R`, virgules) — **1 suite** :
  `test-check-hook-paths.sh`.
- `== bilan : N cas — N OK / 0 KO ==` — **1 suite** : `test-check-capability-activation.sh`.
- `  Bilan : N OK, 0 KO` (indenté, majuscule `B`, sans délimiteurs `==`, virgule plutôt que `/`) —
  **1 suite** : `test-inject-mcp-tools.sh`. Correction d'un a priori du mandat de cadrage : ce
  script **imprime bien un compteur** (contrairement à l'hypothèse initiale « n'imprime aucun
  compteur, ne se vérifie qu'au code de sortie ») — mais dans un 6ᵉ format textuel qui ne
  correspond à aucun des cinq autres, donc tout aussi invisible à un collecteur calé sur l'un des
  cinq.

Soit **6 formats textuels distincts sur 12 suites**, toutes vertes à l'exécution directe
(`bash <suite>.sh`, exit 0 partout, re-vérifié le 2026-08-18). Tout script de collecte qui filtre
sur UN motif littéral (grep exact ou substring) classera à tort en échec — ou pire, en silence
absent des deux côtés — les suites qui n'emploient pas ce motif précis. Le risque est bidirectionnel :
faux KO sur une suite verte (motif absent) ET faux vert par sous-chaîne partagée (le cas `résultat :
N OK / 0 KO` capté par erreur dans `résultat : N OK / 0 KO / 0 SKIP`).

**Piste de fix :** un unique contrat de sortie machine-lisible (ex. une dernière ligne
`RESULT: pass=N fail=N skip=N` commune aux 12 suites, imprimée en plus — jamais à la place — du
libellé humain existant, cf. `feedback_libelles-ok-geles.md` : les libellés `ok` gelés s'ajoutent,
ne se réécrivent jamais). Un collecteur se cale alors sur ce contrat unique, jamais sur la prose.

## `save()` de `dag.sh` sans verrou ni écriture atomique — lost update silencieux — DIFFÉRÉ

**Capturé :** 2026-08-17, demande explicite de Samuel après le rapport d'exécution de la
Phase 33 (finding pré-existant remonté par la revue de mission, provenance vérifiée commit
par commit — hors périmètre 33, non corrigé).

**Le défaut :** `save()` dans `dag.sh` réécrit le fichier de DAG sans verrou ni écriture
atomique (pas de write-to-temp + rename, pas de lock). Deux writers concurrents produisent un
**lost update silencieux** : le dernier écrase le premier sans erreur ni trace. C'est le
finding pré-existant le plus sérieux de la revue Phase 33, précisément parce que `dag.sh` est
conçu pour le **dispatch parallèle** — les managers marquent des nœuds pendant que des vagues
tournent, et depuis la Phase 33 `mark` écrit aussi `progress_epoch` (D-33-A), ce qui multiplie
les écritures concurrentes sur le même fichier.

**Piste de fix :** écriture atomique (temp + `mv` sur le même filesystem) au minimum ;
verrouillage type mutex du driver-lock (mécanisme déjà éprouvé en Phase 32, `ln_atomic`) si la
mesure montre des collisions réelles. La preuve devra être un cas de concurrence réel rouge
sous mutation, pas un test d'API — même exigence que T46 (Phase 32).

**Findings voisins de la même revue, à considérer dans le même lot :** `sanitize_field()`
incomplet sur les caractères de contrôle · `vf_guard_unavailable()` sans validation d'argument
· TOCTOU sur le `takeover` legacy (tous tracés au rapport
`.planning/missions/2026-08-17-phase-33-watchdog-notifications.md`, §findings pré-existants).

## Gate machine sur l'observance de `mission-flow.md` (Phase 33, S1 option (c)) — DIFFÉRÉ

**Capturé :** 2026-08-17, pendant la correction de coordination de la Phase 33 (mandat vf-coder,
2ᵉ plancheck externe). Décision Samuel : l'option (b) — financer une preuve de protocole réel
(`driver-lock.sh heartbeat` réel, D25 en 33-03) — a été retenue et livrée pour fermer S1. L'option
(c) ci-dessous a été explicitement écartée pour la Phase 33, mais versée en reliquat plutôt que
laissée tomber.

**Ce qu'elle proposait :** armer une contrainte MACHINE sur la doctrine de `mission-flow.md`, à
l'image de `check-agents.sh` (module `conductor`) — un gate qui vérifierait que le protocole de
heartbeat amendé (D-33-E, cadence indépendante des transitions de nœud) est réellement OBSERVÉ par
les managers en usage réel, pas seulement écrit dans la doctrine.

**Motivation exacte pour la différer (pas juste « pas le temps ») :** un critère `grep -c 'D-33-E'
mission-flow.md >= 1` prouve qu'un paragraphe existe dans la doctrine, JAMAIS qu'il est observé —
l'émetteur du heartbeat est un agent LLM obéissant à un paragraphe de prose, pas un mécanisme
machine-vérifiable au sens où `check-agents.sh` vérifie une structure de fichier. Construire un
vrai gate d'observance demanderait d'instrumenter le comportement réel des managers en session (pas
seulement leur doctrine écrite) — un chantier distinct de la correction de coordination en cours,
qui mérite son propre cadrage plutôt qu'un geste improvisé en fin de mandat.

**Déclencheur de resurgence :** une régression constatée où le protocole D-33-E amendé n'est PAS
suivi en pratique (heartbeat toujours émis au même tour que `mark`, malgré la doctrine), ou une
décision explicite d'investir dans l'observabilité comportementale des managers.

## Alignement « AI Agents in Depth » (Bojie Li) — milestone candidat — INVESTIGUÉ
**Capturé :** 2026-08-15 · **Investigué :** 2026-08-15 (5 agents : 4 lecteurs couvrant les 10
chapitres + 1 inventaire VibeFlow) → **rapport : `reports/research/2026-08-15-ai-agent-book-alignement.md`**

**Verdict** : livre sérieux (retour Pine AI, ablations chiffrées) ; VibeFlow convergent sur ≥ 8
mécanismes majeurs (manager pattern, digest/handoff, veto de rubric, isolation worktree, knowledge
as code, seuil de proportionnalité multi-agents…) — le livre **valide** plusieurs refus (MemPalace,
compaction). **4 gaps actionnables**, par impact : (1) **juges à vision** — aucun juge ne voit un
rendu, le livre chiffre le feedback visuel à +17/+48 pts et 26→52 % ; (2) **calibration des juges**
(gold set, kappa > 0,7, Pass^k) ; (3) juge hétérogène cross-famille (anti-Goodhart, spike d'abord) ;
(4) lentille KV-cache dans le validator. Plus un volet doctrine : distiller la théorie nommée
(Constrain/Verify/Correct, échecs byzantins, MAST, evidence ≠ instructions) dans `plugin/reference/`.

**But exprimé (Samuel)** : améliorer les pratiques similaires au livre, ajouter théorie + pratique,
combler les gaps — **priorité aux juges design** (gap 1).

**Structure candidate** : milestone « alignement agent-book » en 3 phases + 1 spike (juges à
vision → calibration → doctrine augmentée ; spike juge hétérogène) — détail §5 du rapport.

**Déclencheur de resurgence :** clôture ou jalon de fiabilite-v1.0, ou décision explicite.

## Investiguer ICM (Interpretable Context Methodology) — « folder structure as agent architecture » — INVESTIGUÉ
**Capturé :** 2026-08-15 · **Investigué :** 2026-08-15 (deep-search 4 agents) →
**rapport : `reports/research/2026-08-15-icm-deep-search.md`**

**Verdict** : rien à adopter tel quel (pas de benchmark, traction dans l'orbite commerciale de
l'auteur, mono-agent linéaire — le team-kernel est structurellement au-dessus), mais **5
mécanismes à distiller**, priorisés dans le rapport : G1 tables « Load / Do NOT Load » (anti-
chargement déclaré), G2 CONTEXT.md par compartiment + `_index.md` de scaling, G3 sync anti-drift
carte↔disque (frappe la plaie documentée n°1 du repo), G4 lab-starters clonables à placeholders
pour `vf-new-lab` (recoupe les items `agency-agents` et « Template d'agent installable »), G5
Edit-Source Principle dans la doctrine des managers. Suites à arbitrer — voir §7 du rapport.

ICM remplace l'orchestration au niveau framework par la **structure du filesystem** : des dossiers
numérotés représentent les étapes d'un workflow, des fichiers markdown portent les prompts et le
contexte qui disent à UN agent quel rôle jouer à chaque étape. Deux fichiers racine (`IDENTITY.md`,
`CONTEXT.md`) éliminent les tours perdus en « let me explore your filesystem » ; chaque étape opère
sous un contrat strict (inputs / process / outputs) sur une hiérarchie de contexte à 5 couches ;
les artefacts intermédiaires inspectables SONT le canal de communication entre étapes.

**Sources :**
- Papier : [arXiv 2603.16021](https://arxiv.org/abs/2603.16021) — *Interpretable Context
  Methodology: Folder Structure as Agent Architecture* (Van Clief & McDermott, mars 2026, étendu
  du pattern « LLM knowledge base » de Karpathy)
- Repo de référence : [RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology)
- Template model-agnostic : [ktnCodes/icm-template](https://github.com/ktnCodes/icm-template)

**Angle VibeFlow à investiguer :** VibeFlow fait déjà du « filesystem as architecture » de fait
(`.planning/`, modules toggables, digests de mission, rapports typés sur disque) mais avec une
orchestration multi-agents par-dessus (team-kernel). Questions : que valide/invalide le papier de
notre approche ? Le contrat par étape (CONTEXT.md à 5 couches) a-t-il quelque chose à apprendre à
nos plans de bataille / mandats ? Le modèle mono-agent + dossiers numérotés est-il un concurrent,
un complément (labs non-dev simples ?), ou une source de patterns à distiller ?

**Reste ouvert :** l'arbitrage des 5 gains (G1-G5) — aucun n'est engagé ; le rapport les classe
par levier/coût. Déclencheur naturel : prochaine évolution de `vf-new-lab`, de `scaffold-docs.sh`,
du team-kernel ou de la chaîne validator.

## Notifications de progression des agents managers — CLOS
**Capturé :** 2026-08-11 · **Clos :** 2026-08-17 (Phase 33 puis son **annexe D-33-H**) ·
**Origine de la résurgence :** le déclencheur inscrit ci-dessous — « demande récurrente de suivi de
mission longue distance » — s'est produit tel quel

Les missions pilotées par les managers (`vf-dev-manager`, `vf-design-manager`,
`vf-test-orchestrator`) sont longues et l'utilisateur n'est pas devant l'écran. Idée : **envoyer
une notification quand un agent manager termine sa mission** — et, en extension, **des
notifications aux passages d'étapes importantes** du plan de bataille (fin d'un nœud du DAG,
verdict d'un juge/reviewer, halt condition déclenchée, checkpoint atteint).

**Pistes techniques :**
- Notification macOS native (`osascript -e 'display notification …'` ou `terminal-notifier`)
  déclenchée par le manager en fin de mission / à chaque jalon.
- S'appuyer sur l'existant : le skill `stop-notify` (hook Stop global → notification macOS) est
  un précédent dans l'écosystème — ici c'est l'inverse, une notification **émise par le manager
  lui-même** aux moments choisis, pas à chaque fin de tour.
- Granularité configurable (fin de mission seulement vs jalons intermédiaires) pour ne pas
  spammer ; vecteur = hook, script posé par l'engine, ou geste direct dans le protocole des
  managers (à trancher — attention : un réglage settings ne voyage pas, cf. régression #38).

**Pourquoi différé :** confort d'usage, pas bloquant ; à cadrer proprement (vecteur de
distribution, granularité, portabilité macOS/Linux) avant tout code.

**Déclencheur de resurgence :** prochaine évolution du team-kernel ou des protocoles managers,
ou demande récurrente de suivi de mission longue distance.

**Ce qui a fermé l'item (2026-08-17).** La **Phase 33** a livré le canal OS portable
(`notify.sh`, macOS / Linux / Windows / WSL, WTCH-03) émis aux fins de nœud du DAG ; son
**annexe D-33-H** a tranché les trois questions que cet item laissait ouvertes, et qui étaient
précisément le motif du report :

- **Granularité** — hiérarchie à deux étages : jalons GSD (fin de phase, fin de milestone) →
  push dans l'app Claude ; fins de nœud de DAG (`done`/`failed`) → toast OS. Jamais à chaque tour,
  jamais sur `running`.
- **Portabilité** — les 4 canaux couverts par `notify.sh`, avec détecteur WSL dans `vf-portable.sh`.
- **Vecteur de distribution, et la mise en garde « un réglage settings ne voyage pas, cf.
  régression #38 » écrite dans cet item** — elle a été *confirmée* et a dicté la solution :
  fichier-sentinelle **scope machine** (patron `stop-notify`), zéro clé de settings, zéro hook neuf,
  parce qu'aucun vecteur d'engine n'existe pour écrire une clé non-hook dans un settings. Défaut
  **OFF** (opt-in), toggle `/vf-notify` (`on`/`off`/`status`/`test`).
- **Le push « émis par le manager lui-même »** que cet item imaginait est **structurellement
  impossible** : `PushNotification` n'existe pas en sous-agent (erreur littérale mesurée). D'où le
  **Pattern H** — le manager émet un `SendMessage(main)`, la session principale pousse.

Modules : `conductor` v1.28.0, `dev-orchestrator` v2.18.0. Renvoi :
`.planning/phases/VFDO-33-watchdog-notifications-des-missions/33-CONTEXT.md` § **D-33-H**.
**Réserve** : livré sur la branche `feat/phase-33-annexe-notifications-opt-in`, **non mergée et non
poussée** au moment de cette clôture — l'item est traité au sens du travail fait, pas encore
distribué.

## Convergence de contenu à l'update de module (manifeste par module)
**Capturé :** 2026-07-26 · **Origine :** update réel de la machine 2.23.0 → 2.36.0

L'engine `update` re-matérialise le contenu du module mais **ne supprime pas** les fichiers que
la nouvelle version ne livre plus : les 12 verbes-façades de dev-orchestrator v1.x ont survécu
à l'update v2.1.1 dans `~/.claude/skills/` (nettoyés à la main), ressuscitant le double
catalogue que la bascule agentique a tué. Remède proposé : l'engine écrit un **manifeste des
chemins posés** par module à l'install (`.claude/scripts/.vibeflow-manifest-<module>`), et
`update` supprime les chemins de l'ancien manifeste absents du nouveau (avec backup). Tests :
update d'un module dont une skill a disparu → skill retirée du lab.

## check-agents : périmètre des agents tiers (gsd-*, autres chaînes) — CLOS
**Capturé :** 2026-07-26 · **Clos :** 2026-07-27 (Phase 16) · **Origine :** sanity check machine
post-update

`check-agents.sh --strict` sur `~/.claude/agents` remontait 66 non-conformités — toutes sur les
agents `gsd-*` (chaîne tierce qui ne suit pas la charte ADR-044). Fermé par le flag
`--third-party-prefix` (défaut `gsd-`, répétable ; `--no-third-party-prefix` pour le vider) posé
en Phase 16 dans `plugin/conductor/scripts/check-agents.sh` : un agent `gsd-*` n'est plus linté
pour la charte VibeFlow, et une entrée d'allowlist qui matche le préfixe est réputée résolvable.
**Vérifié empiriquement le 2026-07-27** : `check-agents.sh --strict --agents-dir="$HOME/.claude/agents"`
sort désormais en exit 0 (34 agents `gsd-*` exclus, 0 erreur, 26 warnings résiduels sur des agents
réels non-`gsd-*`, hors périmètre de cet item). Sans le flag (`--no-third-party-prefix`), les
erreurs `gsd-*` réapparaissent (169 lignes ✗/⚠) — confirme que c'est bien le flag qui ferme le
faux positif, pas une coïncidence de version.

## Skill-installer global (multi-agents) — CLOS

**Capturé :** 2026-06-04 · **Clos :** 2026-09-15 (Phase 34, spike SKIL-01, `34-SPIKE-SKIL.md`) ·
**Origine de la clôture :** déclencheur consommé le 2026-06-05, dormi 7 semaines, réduit à un
cadrage go/no-go par le milestone.

**Clos le 2026-09-15** (verdict NO-GO, arbitrage Samuel, AskUserQuestion session principale,
2026-09-15).

**Ce qui a fermé l'item (2026-09-15).** Spike mesuré par exécution (pas par lecture de doc) :
un sous-agent doté de l'outil `Skill` découvre déjà, sans rien d'autre, un skill posé par le
canal `/plugin` natif en scope user (`CAS-A: ATTEINT`, sentinelle obtenue littéralement ;
contrôle négatif `ECHEC`, appareil de mesure validé). Le différenciateur de F8 (« rendre les
skills disponibles à tous les agents ») n'existe plus techniquement au niveau du canal — voir
`34-SPIKE-SKIL.md` § « Canal vs architecture » pour la distinction complète avec la question,
distincte et hors périmètre, de savoir si tous les agents VF ont l'outil `Skill` (non, 18/25 ne
l'ont pas — dont 17 workers `vf-internal: true` cloisonnés Pattern 12 et 1 orchestrateur exposé
non cloisonné, `vf-test-orchestrator` — choix d'architecture, pas un trou de canal). Zéro ligne
de code
d'installeur écrite (D-09). Renvoi : `.planning/phases/VFDO-34-gaps-agency-agents-cadrage-skill-installer/34-SPIKE-SKIL.md`.

Historique d'origine (2026-06-04), pour mémoire : étendre l'approche d'install à toggles
(plugin + skill `/vibeflow-install`) à l'**installation de skills globaux disponibles pour tous
les agents** — un « skill-installer » générique. Clôturé sur mesure : le canal `/plugin` natif
atteint déjà cet objectif, sans second système à construire.

## Template d'agent installable s'appuyant sur dev-orchestrator
**Capturé :** 2026-06-06 · **À explorer :** quand un besoin réel d'agent de domaine apparaît

Fournir un **module « agent starter »** (type `agent-only`, ex. `dev-agent-starter`) qu'un
utilisateur coche dans `/vibeflow-install` pour poser un agent dev prêt à l'emploi qui pilote le
pipeline VibeFlow. Install « facile » assurée par `requires: ["dev-orchestrator"]` (fermeture
transitive). ⚠️ *Note 2026-07-26 : les « verbes `/vf-*` » cités dans cet item ont été supprimés en
v2.33.0 (bascule agentique) — la prémisse est à retraduire en « l'agent invoque directement les
skills gsd-* » avant toute reprise.*

**Contraintes techniques déjà établies (cette session) :**
- **Pas d'imbrication de sous-agents** en Claude Code : l'agent ne peut PAS déléguer à l'agent
  `vibeflow-dev`, et les `/vf-*` → GSD spawnent eux-mêmes des sous-agents. Donc l'agent template
  ne fonctionne pleinement que lancé comme **agent principal** (`claude --agent`).
- Le pont propre = l'agent **invoque les skills `/vf-*`** (il hérite du `Skill` tool), il ne
  délègue pas agent→agent.
- Mécanisme d'install natif déjà en place : `vibeflow-update.sh` pose `AGENT.md` →
  `.claude/agents/<mod>.md` + `references/` → `.claude/agents/<mod>-references/`.

**Question ouverte à trancher AVANT de construire :** qu'est-ce que cet agent fait **de plus** que
`vibeflow-dev` ? S'il ne fait que router à l'identique, il le duplique. → passer par un court
brainstorming (périmètre + valeur ajoutée + nom du module) avant tout code.

**Pourquoi différé :** pas de besoin concret aujourd'hui ; `dev-orchestrator` couvre déjà l'usage
direct (agent `vibeflow-dev` + `/vf-*`).

**Déclencheur de resurgence :** apparition d'un vrai cas d'agent spécialisé (de domaine) à
distribuer aux utilisateurs.

## Combler les gaps de couverture inspirés du catalogue `agency-agents`
**Capturé :** 2026-07-20 · **À explorer :** au prochain arbitrage d'extension de périmètre

> **Source :** [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) —
> catalogue MIT de 230+ agents-personas Claude Code (`.md` + frontmatter YAML natif), rangés en
> ~12 divisions. Companion app multi-outils :
> [`msitarzewski/agency-agents-app`](https://github.com/msitarzewski/agency-agents-app).
> Modèle « catalogue plat sans orchestration » — **à ne PAS importer tel quel** (densité
> incompatible ADR-029, aucune gouvernance `conductor`). Valeur = **source d'inspiration et de
> personas à distiller**, surtout pour élargir vers des labs non-dev.

**Cadrage.** Le cœur VibeFlow (Engineering, Design, Project Management, Marketing/Content) est
déjà couvert et **supérieur** (orchestration gouvernée vs catalogue). Rien à importer là. Ce qui
suit ne concerne que les gaps réels, distillés depuis leur taxonomie.

**Mapping divisions → modules (au 2026-07-20) :**

| Division agency-agents | Module VibeFlow | Statut |
|---|---|---|
| Engineering | `dev-orchestrator`, `software-architecture` | ✅ Couvert |
| Design | `design-orchestrator` | ✅ Couvert |
| Project Management | `planning-core`, `conductor`, `kpi-analyst`, `consolidator` | ✅ Couvert |
| Marketing / Content | `content-bundle`, `growth-bundle` | ✅ Couvert |
| Testing | `mobile-test`(-team) | 🟡 Mobile only, expérimental |
| Security | `infrastructure-audit`, `audit-architecture` (+ agent `vf-auditer` du dev-orchestrator) | 🟡 Audit oui ; pas incident/compliance |
| Sales | `business-pilot-bundle` (blueprint commercial) | 🟡 Granularité fine à dériver |
| Product | `planning-core` + `business-pilot-bundle` | 🟡 Pas de module product first-class |
| Paid Media | `growth-bundle` (crochet par canal) | 🟡 Crochet oui, blueprints non |
| Support | — | ❌ Manquant |
| Spatial / Game / Healthcare / GIS / Academic | `vf-new-lab` (dérivation) | ❌ Niche, pas de module |

**Pistes priorisées (valeur/effort décroissant) :**
1. **`web-test-team`** — test-team web/e2e (Playwright) calqué sur `mobile-test-team`
   (Pattern 12, workers cloisonnés). Comble un trou de **notre propre chaîne dev** (seul test réel
   = mobile). Usage interne immédiat → priorité #1.
2. **Extensions Sales + Paid Media** des bundles existants — crochets déjà présents
   (`business-pilot-bundle`, `growth-bundle/par-canal`), il ne manque que des blueprints. Leurs
   personas SDR/discovery/proposal et PPC/programmatic sont directement inspirants à distiller.
3. **`SupportFlow`** — nouveau bundle métier (customer service / analytics / legal) si l'on vise
   les labs non-dev. Aucun équivalent aujourd'hui.

**Ce qu'on n'en prend PAS :** le catalogue plat, la densité, tout copier-coller direct dans
`plugin/`. Chaque geste passe par `check-agents.sh` (ADR-044) + ADR-029 + le brainstorming de
périmètre avant tout code.

**Pourquoi différé :** aucun besoin bloquant aujourd'hui ; le cœur couvre l'usage courant. C'est
de l'élargissement de périmètre, à arbitrer selon la stratégie produit.

**Déclencheur de resurgence :** décision d'élargir VibeFlow (test web dans la chaîne dev, ou
ouverture à des labs non-dev Sales/Support/Paid) — six des onze divisions désormais `refuser`
faute de preuve D-02 (voir bloc du 2026-09-15 ci-dessous) : leur déclencheur précis est la
découverte d'un incident documenté, d'une demande externe ou d'un bug récurrent nommé sur l'une
d'elles, pas une simple décision d'élargir dans l'abstrait. `web-test-team` (Testing) reste
`reporter`, sur la dépendance AGTS-02 déjà suivie au ROADMAP (Phase 34).

**Verdict par gap — 2026-09-15 (Phase 34, audit AGTS-01, `34-AUDIT-AGTS.md`).** Matrice
re-mesurée contre le parc réel de `plugin/` (31 fichiers, corpus mesuré identique à la matrice
d'origine ci-dessus) : Engineering / Design / Project Management / Marketing-Content restent
`sans objet` (déjà couverts) ; Testing (`web-test-team`) est `reporter`, sur dépendance à
AGTS-02 déjà suivie au ROADMAP, pas re-arbitrée ici ; les six divisions restantes (Security,
Sales, Product, Paid Media, Support, Spatial/Game/Healthcare/GIS/Academic) sont `refuser` faute
de preuve au sens de la règle de preuve du milestone (D-02) — le ❌/🟡 du catalogue seul ne
suffit pas, il faut un incident documenté, une demande externe ou un bug récurrent, et aucun des
six n'en a un. Zéro agent créé, zéro persona importée (D-01). Détail des six refus, gap par gap,
et condition exacte de réouverture : `34-AUDIT-AGTS.md` §§ « Gaps refusés » et « Limite de la
recherche de preuve ». Aucun item BACKLOG distinct créé par cette note (zéro verdict `combler`,
`34-AUDIT-AGTS.md` § « Items backlog à créer »).

## AGTS-02 — sortie d'expérimental de `mobile-test`(-team) : REPORTÉE avec trace

**Capturé :** 2026-09-15 (Phase 34, run réel piloté par l'équipe, `34-RUN-MOBILE.md`) ·
**À explorer :** dès que le déclencheur de reprise ci-dessous est levé

**Cadrage.** Premier run réel joué le 2026-09-15 sur `Scroll-Off/frontend` (iOS, cible
`8BD53E84-B5BF-482A-8FE5-6A9980555951`) : chapeau `> **Statut** : ROUGE` (`PIPELINE: VERT` — la
mécanique du module fonctionne — mais `EQUIPE: ROUGE` — 6/10 flows restent en échec après un
cycle de fix réel, dont un signal d'alarme absolu sur `lot5_scrolls_scale_native_header` : écran
de login affiché au lieu de l'écran natif attendu, arrêt immédiat sans retentative, conformément
au mandat). La condition de sortie du statut expérimental (`plugin/mobile-test/README.md` §
Limites, `plugin/mobile-test-team/README.md` § Limites) n'est donc pas atteinte. AGTS-02 est
**reportée**, jamais abandonnée en silence (D-05) : sa case reste décochée au ledger des
exigences, et sa reprise est conditionnée au déclencheur ci-dessous.

**Pourquoi différé :** la règle absolue du mandat de ce run interdit toute retentative dès la
détection d'un écran de login inattendu. La cause (session authentifiée perdue vs bug de
robustesse de `fetchRenewToken`) est un sujet **du projet Scroll-Off**, pas de VibeFlow.

**Scroll-Off exclu du périmètre VibeFlow** (arbitrage Samuel, session principale, 2026-09-15 :
« ça n'a rien à voir ») : ce dépôt ne porte plus aucune vérification, aucun déclencheur ni
aucune action à faire sur Scroll-Off (Keychain du simulateur, backend, commit Metro). La trace
`34-RUN-MOBILE.md` reste une **archive** du run joué, non réécrite.

**Déclencheur de reprise :** un lab mobile Expo/React Native **désigné explicitement par Samuel,
hors Scroll-Off**, avec une session reproductible sans intervention humaine — ou Scroll-Off
re-désigné par un arbitrage explicite. Tant qu'aucun lab n'est désigné, AGTS-02 reste reportée
avec trace (D-05), sa case décochée au ledger, et `web-test-team` non construite. Le protocole
de sortie d'expérimental (`plugin/mobile-test/README.md` § Limites,
`plugin/mobile-test-team/README.md` § Limites) et la doctrine « prérequis manquant = arrêt
propre, jamais d'installation à la volée » (34-CONTEXT D-05) restent inchangés.

## check-agents.sh ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque
**Capturé :** 2026-09-15 (audit de la mission Phase 34, arbitrage Samuel, AskUserQuestion session
principale, 2026-09-15) · **À explorer :** prochain durcissement de gate touchant au nettoyage
d'un protocole jetable (spike, sonde, plugin de mesure)

**Constat.** Le gate automatisé de nettoyage du spike SKIL-01 (`34-02-PLAN.md:237`, bloc
`<automated>` de la tâche 2, référencé par `34-VALIDATION.md:55`) ne vérifie que les chemins
**auto-déclarés par le protocole lui-même** (la liste « chemin supprimé : … » construite au fur
et à mesure de la pose), jamais l'état réel du disque. Ce gate est passé **VERT** (commit
`81dcc03`) alors que **trois résidus** subsistaient après la clôture initiale du spike : le cache
disque du plugin sous `~/.claude/plugins/cache/`, une entrée orpheline dans `~/.claude.json`, et
les transcripts de session sous `~/.claude/projects/`. Ils n'ont été trouvés que par une
recherche élargie (`find ~/.claude -iname "*skil01*"`), hors protocole — détail complet et
preuve machine : `34-SPIKE-SKIL.md` §§ « Résidus trouvés après le premier passage » et
« Purge ».

**Pourquoi c'est une dette structurelle, pas un incident clos.** Le résidu de ce spike précis a
été purgé (deux gestes distincts, un troisième laissé intact sur arbitrage explicite de Samuel —
voir `34-SPIKE-SKIL.md` § « Purge »). Mais le **gate lui-même** reste le même patron qu'avant :
une liste auto-déclarée n'est pas une vérification, elle ne peut par construction jamais
constater ce qu'elle n'a pas elle-même énuméré (« une preuve incapable de rendre rouge »). Un
futur protocole du même patron (spike jetable, sonde, plugin de mesure) repasserait vert avec le
même trou.

**Forme attendue du correctif :** une vérification de nettoyage par **recherche élargie de
l'état réel du disque** (cache plugins, `~/.claude.json`, registres) — jamais une liste
auto-déclarée par le protocole qu'elle est censée vérifier — avec **mutation rouge prouvée** (un
résidu injecté hors de la liste auto-déclarée doit faire échouer le gate).

**Pourquoi différé :** le plan 34-02 reste une archive exécutée non modifiée (arbitrage explicite
de Samuel, même canal et date) — ce n'est pas ce plan-là qui se corrige, c'est le patron de gate
qui doit être durci au prochain protocole du même genre.

**Déclencheur de resurgence :** prochain plan qui pose un gate de nettoyage automatisé pour un
protocole jetable (spike, sonde, plugin de mesure, agent de sonde) — reprendre cet item avant
d'écrire ce gate, pas après.

## Budget des SKILL.md et du bootstrap — sans enforcement machine (différé de la Phase 25, 2026-09-15)

**Capturé :** 2026-09-15, clôture de la première PR de la Phase 25 (mandat vf-coder, plan 25-03).
Hors périmètre de BUDG-01 (D-03) — la phase a délibérément limité sa portée aux agents distribués.

**Le défaut :** ADR-029 borne aussi les `SKILL.md` à 500 lignes et le bootstrap à 2000 tokens, mais
aucun gate distribué ne mesure ni l'un ni l'autre — `plugin/conductor/scripts/check-instruction-budget.sh`
ne couvre que `plugin/*/agents/*.md` et `plugin/*/AGENT.md` (glob à un seul niveau, D-03).

**Déclencheur de reprise :** le gate `check-instruction-budget.sh` existe désormais et son contrat
de mesure (lignes du fichier entier + instructions du body, ratchet par sentinelle) est prouvé.
Étendre sa découverte à un second corpus (`SKILL.md`) est une **modification de portée**, pas une
reconstruction — reprendre ce script comme socle plutôt qu'en écrire un nouveau.

**Écarté, et non différé :** la métrique en tokens estimés pour le budget du bootstrap (piste F3,
`25-CONTEXT.md`) — à ne rouvrir que sur un incident lié à la **taille** du bootstrap plutôt qu'à son
adhérence à la charte de densité.

**Remédiation, pas ici :** l'abaissement des fichiers d'agents distribués les plus chargés (mesurés
`SANS-BASELINE` au rejeu du 2026-09-15, ex. `plugin/dev-orchestrator/agents/vf-dev-manager.md` à
250 lignes) est un geste ultérieur, par lot, chacun abaissant une baseline dans son propre commit —
jamais un livrable de cette phase, et jamais une réécriture « pour passer » le gate.

## Évasion de mesure du budget d'instructions par bloc de code fenced — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, audit de la mission d'exécution du plan 25-03 (mandat vf-coder), au-delà
du périmètre de ce plan (déviation déclarée minimale, non corrigée ici).

**Le défaut :** `count_instructions()` de `plugin/conductor/scripts/check-instruction-budget.sh`
exclut délibérément le contenu situé entre triples backticks (design assumé, documenté en tête de
fonction) — une instruction impérative citée à l'intérieur d'un bloc de code échappe donc au
ratchet. Hors registre STRIDE actuel de ce script.

**Déclencheur de reprise :** un incident constatant qu'une règle a été déplacée dans un bloc de
code pour échapper au comptage.

## Blocs `<verify><automated>` de plan qui écrasent un script réel sans `trap` — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, audit de la mission d'exécution du plan 25-03 (mandat vf-coder), au-delà
du périmètre de ce plan (déviation déclarée minimale, non corrigée ici).

**Le défaut :** le bloc `<verify><automated>` de la tâche 1 de `25-02-PLAN.md:154` fait
`cp`/écrasement/`mv` du gate réel `check-instruction-budget.sh` sans filet de restauration. Une
interruption entre l'écrasement et la restauration laisse un stub de 27 octets à la place du gate
réel — aucun `trap ... EXIT INT TERM` ne protège la séquence.

**Déclencheur de reprise :** prochaine révision des scripts de vérification de plan qui manipulent
un fichier réel par écrasement temporaire — durcir par `trap` à cette occasion, pas avant.

## Dérive documentaire et fragilité latente révélées par le gate de budget d'instructions — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, clôture documentaire de la Phase 25 (mandat vf-coder), quatre constats
remontés par les juges de cette mission — aucun corrigé ici, tous hors du périmètre déclaré de la
phase (`plugin/validator/`, `.planning/codebase/` et la doctrine de `CONVENTIONS.md` ne sont pas
dans les fichiers livrés par cette phase).

1. **`plugin/validator/README.md:10` affirme « `AGENT.md` = 249 lignes — à 1 ligne du plafond ».
   Mesure réelle : 250** (concordante par `awk 'END{print NR}'` et `wc -l`). La marge est **zéro**,
   pas une. Le `CHANGELOG.md` du même module dit juste (« reste à 250/250 »), seul le README ment.
   `.planning/codebase/CONCERNS.md:79-82` porte le même 249 mais explicitement daté du 2026-07-26 —
   honnête comme relevé d'époque, pas une erreur.
   **Échéance dure : avant l'armement du ratchet en Phase 40** — sans correction, une seule ligne
   ajoutée à `plugin/validator/AGENT.md` fera passer le gate au rouge alors que le README affirmera
   encore qu'il reste de la marge.
2. **`.planning/codebase/CONVENTIONS.md:56`** décrit des codes de sortie « normalisés » (`2` =
   erreur d'usage, `3` = INDÉTERMINÉ) que `check-instruction-budget.sh` inverse délibérément
   (`64` usage, `2` indéterminé, `3` = ratchet non armé — le script cite nommément cette ligne dans
   son en-tête comme la convention dont il s'écarte). C'est désormais le **troisième** gate à
   dévier de cette ligne : « normalisés » ne décrit plus le parc réel.
3. **`.planning/codebase/TESTING.md`** : ligne 98, « les gates suivent **tous** le contrat F13 »
   est faux (trois gates dévient, cf. point 2) ; lignes 29-32, la liste du job `gates` compte 3
   puces pour **10 étapes réelles** (sept manquaient déjà avant cette phase, `check-instruction-budget`
   en ajoute une dixième).
4. **Fragilité latente dans `.github/workflows/ci.yml`, étape `check-instruction-budget`, bloc 1**
   (preuve de discrimination sur fixture) : l'affectation `I="$(bash "$S" --path "$FIX" … | awk
   …)"` s'exécute avant que la baseline de la fixture existe, donc `rc=2` à ce point précis. Sous
   le shell réellement utilisé par GitHub Actions pour cette étape (`bash -e {0}`, **sans**
   `pipefail`), c'est inoffensif et l'étape reste verte — mesuré. Mais si une future édition ajoute
   `shell: bash` en tête d'étape (donc `-eo pipefail` par défaut de ce runtime), l'affectation
   hériterait de `rc=2`, `set -e` tuerait l'étape immédiatement : **exit 2, zéro ligne de sortie,
   aucun diagnostic**. Durcissement suggéré : capturer explicitement le code de retour de cette
   affectation. **Ne PAS ajouter `|| true`** — le plan de la Phase 25 l'interdit formellement sur
   une mesure (le gate doit pouvoir rendre rouge, jamais se replier en silence).

**Pourquoi non corrigé ici :** `CONVENTIONS.md` relève de la doctrine transverse du repo (pas d'un
gate d'une phase) ; `plugin/validator/` et `.planning/codebase/` sont hors du périmètre déclaré de
la Phase 25 (budget d'instructions), qui s'est délibérément limitée à `plugin/conductor/scripts/`,
`.github/workflows/ci.yml` et ses propres traces documentaires.

**Déclencheur de reprise :** le point 1 avant l'armement du ratchet en Phase 40 (dur) ; les points
2-3 à la prochaine révision de `CONVENTIONS.md`/`TESTING.md` ou dès qu'un quatrième gate dévie du
patron F13/codes normalisés ; le point 4 à la prochaine édition de l'étape CI concernée, ou plus
tôt si quelqu'un ajoute `shell: bash` à une étape du job `gates`.

**Statut partiel (2026-09-17, Phase 40.1) :**
- point 1 fermé par le plan 40.1-11 (README `plugin/validator/` réécrit, marge exacte sous le
  plafond révisé) ;
- point 4 fermé par le plan 40.1-03 (mesure de la fixture de l'étape CI à code capturé, sans
  `|| true`) ;
- points 2 et 3 inchangés, toujours différés.

## Protection de `main` côté GitHub — DIFFÉRÉ, en attente d'un accès admin (2026-09-17)

**Constat et arbitrage** : Samuel, AskUserQuestion session principale, 2026-09-17 — le compte
`picmakpro` est celui de **Willy, co-mainteneur du dépôt** : c'est lui qui détient l'admin, pas un
tiers anonyme. Mesure : `gh api repos/picmakpro/vibeflow-os --jq .permissions` →
`admin: false, maintain: false, push: true` sur le compte de Samuel (`samuel-neveugall`).
**Dans cette session, personne ne pouvait poser de ruleset**, ni de revue code owner requise, ni de
PR obligatoire côté serveur — Willy a depuis accepté de poser ce volet lui-même (WhatsApp,
2026-09-23).

**Correction du 2026-09-23** : la séquence écrite plus bas dans cette entrée (« une fois le jalon
`fiabilite-v1.0` clos ») était fausse et circulaire — **PROT-01 appartient à ce jalon**, il ne peut
donc pas se clore avant que les rulesets soient posés. La séquence réelle, demandée par Samuel à
Willy par WhatsApp le 2026-09-23 : Willy pose les rulesets → on prouve → on clôt le jalon → son
jalon à lui (Phase 42) démarre.

**Ce qui est différé, tel quel, sans réécriture** : rulesets de branche et de tags, bypass, revue
code owner requise, PR obligatoire, mesures M-1 à M-4, fermeture de la PR #29, rejeu du flux de
release sous la règle. Décisions D-01 à D-08 du `41-CONTEXT.md` : **suspendues**, pas annulées.
Plans concernés : 41-01 (Task 2 et 3), 41-04 à 41-09, et la partie « sous la règle » de 41-11 à
41-13. Travail conservé : `41-PREUVES.md` (`CONTEXTES-CHECKS` mesuré).

**Déclencheur de reprise** : un accès **admin** au dépôt (droit accordé à un compte de Samuel, ou
geste posé par Willy lui-même sur `picmakpro`). Ce jour-là, la posture visée est déjà écrite :
`41-CONTEXT.md` § Arbitrages, et les plans différés se rejouent dans l'ordre.

**Accord obtenu le 2026-09-23** : Willy a accepté de poser lui-même le volet rulesets sur
`picmakpro` (WhatsApp, 2026-09-23) — geste séquencé **avant** la clôture du jalon `fiabilite-v1.0`
(PROT-01 en fait partie), pas après (correction du 2026-09-23 de la formulation initialement écrite
ici, qui inversait la séquence). Séquence réelle : Willy pose les rulesets → preuve → clôture du
jalon → ouverture du jalon de Willy (cf. Phase 42 du ROADMAP). Le volet reste différé jusqu'à ce
geste ; d'ici là, aucune garde côté serveur n'existe.

**Ce qui reste faisable sans admin** (à arbitrer avec le nouveau périmètre de la Phase 41) : gardes
in-repo visibles et tracées — baseline du budget d'instructions, modification d'un gate ou de
`ci.yml`, détection après coup d'un push direct, durcissement du hook `pre-push`. **Limite de fond,
à écrire partout** : une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle juge ;
sans règle côté serveur, on ne ferme rien, on rend visible et tracé.

**Statut partiel (2026-09-18, Phase 41) :** le périmètre sans admin est livré par les plans 41-14 à
41-19 (trois gardes in-repo — G-1 baseline, G-2 surface de gate, G-3 push sans PR — et la doctrine
ADR-072). Le volet côté serveur ci-dessus reste différé tel quel, son déclencheur de reprise
inchangé ; les décisions D-01 à D-08 restent suspendues. Renvoi : `docs/ADR.md` § ADR-072.

**Rulesets posés — PROT-01 clos (2026-09-23/24).** Willy a posé les deux rulesets sur `picmakpro`
le 2026-09-23 19h56 (`refs/heads/main` id `23892920`, `refs/tags/v*` id `23892922`, tous deux
`enforcement: active`), re-mesurés le 2026-09-24 (session principale puis mandat de clôture,
`REQUIREMENTS.md` § PROT-01, `41-PREUVES.md` § « Clôture PROT-01 »). **Écart consigné, non
corrigé** : le champ `require_extra_approval_for_unattributed_changes: true` est présent côté
serveur sur les deux rulesets (mesuré `gh api repos/picmakpro/vibeflow-os/rulesets/<id>`) mais
absent des sources versionnées `.github/rulesets/main.json` et `.github/rulesets/tags-v.json` —
c'est un défaut posé par GitHub à la création du ruleset, jamais demandé dans les sources, sans
effet observé sur le comportement décrit par PROT-01 (revue code owner + 4 checks requis, refus de
merge hors bypass nommé). La divergence entre le fichier relu et l'état réel reste ouverte :
**déclencheur de reprise** — soit aligner les sources sur la valeur réelle du serveur, soit
demander à GitHub Support pourquoi ce défaut est appliqué sans qu'il figure dans le payload de
création envoyé.

## Ligne d'index absente pour ADR-071 dans `docs/ADR.md` — DIFFÉRÉ (2026-09-18)

**Constat mesuré le 2026-09-17**, en posant ADR-072 (Phase 41, plan 41-18) : la table d'index de
`docs/ADR.md` s'arrête à la ligne ADR-070, alors que la section `## ADR-071` existe plus bas dans
le fichier — aucune ligne d'index ne la référence. **Hors périmètre de la Phase 41**, non corrigé
au passage pour ne pas mêler une dérive non arbitrée au diff d'une phase dédiée à une autre
doctrine. **Déclencheur de reprise** : prochain passage sur `docs/ADR.md`.

## Posture de protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15)

**Décision** : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 — ouvrir une **phase
dédiée « posture de protection du dépôt »** (prochain numéro libre, 41). L'inscription au ROADMAP est
faite par la session principale **après le merge de la PR #67**, délibérément, pour ne pas créer de
conflit sur `ROADMAP.md` avec la branche de la Phase 25. Le présent item est la trace côté branche ;
il cesse d'être un `human_needed` et devient le cahier des charges de cette phase.

**Constat mesuré** (audit de la vague 3, Phase 25) : `gh api repos/picmakpro/vibeflow-os/rulesets`
rend `[]`, et l'endpoint de protection classique rend 404 avec des permissions `push:true,
admin:false` — cohérent avec « aucune protection configurée », pas avec un refus d'accès. `main`
n'est donc protégée par rien.

**Conséquence** : **tout gate in-repo de ce dépôt est neutralisable depuis la PR qu'il juge.** Une
même PR peut modifier un gate, sa suite de tests et l'étape CI qui l'invoque. Le cas est concret pour
la Phase 25 (`check-instruction-budget.sh` + `test-check-instruction-budget.sh` + l'étape du job
`gates`), mais le risque est **structurel et antérieur** : il vaut identiquement pour
`check-divergence.sh`, `check-agents.sh`, `check-version-sync.sh` et tous les autres. Aucun threat ID
du registre STRIDE de la Phase 25 ne le nomme — il dépasse le périmètre d'une phase de gate.

**Forme attendue** : un ruleset exigeant la **CI verte avant merge** sur `main`. À poser **dans une
phase à part, jamais au passage d'une mission** : changer les règles du merge pendant qu'une PR est
ouverte modifierait les conditions de cette PR en cours de route.

**Points à instruire dans la phase 41** : interaction avec la discipline de release du `CLAUDE.md`
(le gate `check-release-tag` est déjà `main`-only et échoue par construction au merge, rerun requis
après le tag) ; sort du hook `pre-push` optionnel (`scripts/hooks`) ; effet sur les hotfix urgents.

**Déclencheur de reprise** : inscription au ROADMAP par la session principale après le merge de
la PR #67.

**Statut partiel (2026-09-18, Phase 41) :** la phase a été ouverte et cadrée, sa prémisse s'est
renversée (accès admin absent, cf. l'item ci-dessus), et le cahier des charges est désormais
scindé — la partie in-repo est traitée par ADR-072 (`docs/ADR.md`), la partie côté serveur reste
au premier item de cette page. La forme attendue décrite ici (« un ruleset exigeant la CI verte
avant merge ») n'existe pas encore : cet item n'est pas marqué achevé.

## T-25-SC — journal de sécurité de la Phase 25 : TRANCHÉ, geste de clôture (2026-09-15)

**Décision** : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 — le `25-SECURITY.md`
est produit **à la clôture de la phase, après le plan 25-04**, par `/gsd-secure-phase` sur la phase
**complète**, une fois la calibration livrée (donc après la Phase 40). Ce n'est pas une dette
oubliée : c'est un geste de clôture daté et attendu.

**Pourquoi pas maintenant** : la Phase 25 n'est pas close — 3 plans sur 4 sont livrés, `25-04`
(calibration, gravure des baselines, armement de la sentinelle) reste un checkpoint bloquant-humain.
Un journal produit sur une phase à moitié livrée serait à refaire.

**Contexte** : T-25-SC (chaîne d'approvisionnement) est classé `accept` dans le registre STRIDE de la
phase. Le lab a `security_enforcement: true` / `security_block_on: "high"` ; T-25-SC est `low`, il ne
bloque donc pas `/gsd-ship` aujourd'hui. Le précédent d'un accept tracé est établi par
`24-SECURITY.md` et `27-SECURITY.md` (archivés sous `.planning/milestones/agentique-v1.0-phases/`).

**Déclencheur de reprise** : livraison du plan 25-04, avant la clôture de la Phase 25.

## `check-overlaps.sh` : `present()` aveugle à un agent local installé sous son nom de fichier canonique — DIFFÉRÉ

**Capturé :** 2026-09-15, hygiène documentaire de clôture de la Phase 40 (mandat vf-coder). Faiblesse
**préexistante** — non introduite par cette phase, non corrigée ici (« un garde ne se desserre
jamais dans le commit qu'il autorise »).

**Le défaut :** `present()` (`plugin/conductor/scripts/check-overlaps.sh:72-87`) résout un agent
local par correspondance de nom de fichier : `[ -f "$AGENTS_DIR/$ref.md" ] && return 0`. Sur un lab
**installé**, l'agent routeur du dev-orchestrator est posé sous `agents/dev-orchestrator.md` — un
nom de fichier stable, indépendant du nom sous lequel l'agent s'incarne (`vibeflow-head` depuis la
Phase 40, `vibeflow-dev` avant). La frontière ADR-057 entre deux front doors potentiellement
concurrentes (`vibeflow-head` et `gsd-next`, la front door GSD pour qui n'a pas d'agent routeur)
est donc **déjà muette en lab réel** : `present()` ne peut pas la détecter par ce chemin de
résolution.

**Piste de fix :** résoudre `present()` par le **nom** déclaré dans le frontmatter de l'agent
(`name:`), pas par le nom de fichier — même logique que la garde anti-alias T36 de la Phase 40
(motif assemblé, jamais un chemin en dur). La preuve devra être un cas où le nom de fichier et le
nom incarné divergent, rouge avant/vert après.

**Déclencheur de reprise :** un incident réel de recouvrement de front doors en lab installé, ou un
prochain audit `check-overlaps.sh`.

## `test-scaffold-docs.sh` cas 22 fige en dur le nombre de références d'un module — DIFFÉRÉ

**Capturé :** 2026-09-15, hygiène documentaire de clôture de la Phase 40 (mandat vf-coder).
Fragilité de conception à traiter, pas un bug de la Phase 40.

**Le défaut :** le cas 22 de `plugin/conductor/scripts/tests/test-scaffold-docs.sh` compare le
compte de références d'un module à une valeur numérique écrite en dur dans le test. Cette valeur
a dû être corrigée de 11 à 12 dans la PR de la Phase 40 (ajout du renvoi vers
`head-governance.md`). Le cas **cassera à chaque référence ajoutée** au module concerné — toute
future documentation qui enrichit ses renvois fera rougir ce cas sans rapport avec son objet réel
(vérifier qu'un scaffold de doc a des références, pas en compter un nombre exact figé).

**Piste de fix :** remplacer l'égalité stricte par une borne basse (« au moins N références »),
ou dériver N par une commande à l'exécution plutôt que par un littéral écrit dans le test — même
principe que les leçons `check-overlaps.sh` / `check-instruction-budget.sh` : un nombre transmis
se re-dérive, il ne se fige jamais dans le test qui le vérifie.

**Déclencheur de reprise :** le prochain cas où ce test casse sur un ajout légitime de référence.

## Un gate câblé sur un seul compartiment de workstream laisse les autres sans garde — DIFFÉRÉ (2026-09-23)

**Capturé :** 2026-09-23, mission « partition réelle du planning D-02 » (`.planning/missions/2026-09-23-partition-planning-d02.md`).

**Le défaut :** l'étape CI « check-state-integrity (anti-régression du frontmatter … ADR-063) »
(`.github/workflows/ci.yml:353`) cible explicitement `.planning/workstreams/fiabilite/STATE.md` —
en dur, pas résolu par `GSD_WORKSTREAM` ni par le pointeur partagé. C'est le bon remède contre le
détournement du gate par l'environnement (défense en profondeur ADR-063, déjà la doctrine avant
cette mission) — mais son effet de bord est que la CI ne vérifie QUE ce compartiment. Mesuré
concret : `.planning/workstreams/gouvernance/STATE.md` (compartiment tout juste créé, gabarit frais
du moteur, pas encore de champ `milestone:` ni de ligne `^Phase:`) rend `rc=2` (« milestone
introuvable ») si on le vérifie explicitement — et la CI ne le verra JAMAIS, ni pour le dire cassé
ni pour le dire bon. L'angle mort grandit mécaniquement avec chaque compartiment ajouté (aujourd'hui
2 : `fiabilite`/`gouvernance` ; demain N).

**Piste de fix :** ne pas revenir à une résolution par `GSD_WORKSTREAM`/pointeur (c'est précisément
le vecteur de détournement qu'ADR-063 a fermé). À la place, itérer sur les compartiments PRÉSENTS
SUR LE DISQUE (`.planning/workstreams/*/`) au moment du run CI et appeler
`check-state-integrity.sh --file .planning/workstreams/<nom>/STATE.md` pour chacun explicitement —
chemins toujours en dur, énumération dynamique. Même logique que `check-divergence.sh`, qui
inspecte déjà tous les compartiments présents sans se fier à un pointeur.

**Déclencheur de reprise :** l'ajout d'un troisième compartiment, ou le premier incident réel où un
compartiment autre que `fiabilite` régresse sans que la CI ne le voie.

## Mise en conformité du corpus de skills en dérive procédurale non déclarée (différé de la Phase 43, 2026-09-24)

**Capturé :** 2026-09-24, cadrage de la Phase 43 (compartiment `gouvernance`, `43-CONTEXT.md` D-Q5).

**Le défaut :** le futur `check-skills.sh` signalera les skills dont la forme est procédurale (gate
bloquant, livrable remis à un tiers, couche de qualité) sans que leur nature le déclare. Dans cette
phase, il ne fait qu'**avertir** : réponse de Willy (AskUserQuestion, session principale, 2026-09-24).
C'est un écart assumé par rapport à la doctrine D-11 de la Phase 42 (invariants armés en erreur,
corpus corrigé dans la même phase).

**Déclencheur de reprise :** le gate existe et a mesuré le corpus réel (25 `SKILL.md` sous `plugin/`
au 2026-09-24). Reprendre avec la liste des skills signalés, puis décider de l'armement en erreur.

## Pour Samuel — le mode large `vf-mcp-consumer` injecte les serveurs du scope global, dont context7 chez `vf-app-fixer` (constaté 2026-09-24)

**Capturé :** 2026-09-24, panel de décision sur la question MCP du cadrage de la Phase 43 (compartiment
`gouvernance`). Hors périmètre de la Phase 43 : sur décision de Willy (AskUserQuestion, session
principale, 2026-09-24), il est inscrit comme finding pour Samuel, **sans correctif dans cette mission**
(ADR-031). Polarité : `dev-orchestrator` et `mobile-test-team` (Samuel).

**Le défaut :** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` réunit les serveurs du scope
projet (`.mcp.json`) et ceux du scope global (`~/.claude.json`, clé `mcpServers`) pour tout agent qui
porte `vf-mcp-consumer: true` (l.26-31, l.222). Il en résulte un écart de doctrine :
- ADR-051 (« Cloisonnement », `docs/ADR.md:469`) garde à `vf-app-fixer` son interdiction ADR-045
  (pas de context7, pas de web) ;
- les conséquences négatives d'ADR-051 disent qu'un serveur déclaré au seul niveau utilisateur n'est
  pas injecté « par conception » ;
- le script justifie l'union par « ADR-051-B », un addendum **absent** de `docs/ADR.md`.

**Preuve rejouée** (2026-09-24, copie jetable de `vf-app-fixer.md` dans le scratchpad de session, sans
`.mcp.json` de projet) :
`inject-mcp-tools.sh --target <copie>/agents --mcp-json <absent> --dry-run` →
`vf-app-fixer.md : (dry-run) ajouterait mcp__context7__*, mcp__xpoz-mcp__*`. Ce sont exactement les
deux serveurs de `~/.claude.json` de ce poste.

**À trancher par Samuel :** filtrer le scope global pour les agents cloisonnés, ou revenir au seul
scope projet pour le mode large, ou écrire l'addendum ADR-051-B qui assume l'union et amende ADR-045.
Tant que rien n'est tranché, tout lab dont `~/.claude.json` déclare context7 donne context7 à
`vf-app-fixer` à l'installation.

## ADPT-06 — canal `hooks`/`plugins` du dépôt jugé jamais répété — RÉSORBÉ (2026-09-24)

**Capturé :** 2026-09-24, audit de clôture du jalon `fiabilite-v1.0` (compartiment `fiabilite`,
`.planning/workstreams/fiabilite/REQUIREMENTS.md`). **Résorbé :** 2026-09-24, preuve
`.planning/workstreams/fiabilite/phases/VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration/38-ADPT06-HOOKS-REPETITIONS.md`
(commit `78648ca`) — répétitions du canal `hooks`/`plugins` menées (5 runs, marqueur `0/5`), deux
gates indépendants vérifiés séparément (confiance par défaut du projet/des hooks ; les deux
drapeaux `features.hooks=false`/`features.plugins=false`). Limite déclarée dans ce même document :
dépôt jugé jamais trusté et sans `--dangerously-bypass-hook-trust`, un seul type de hook mesuré
(`SessionStart`), pas de plugin réel construit, non reproductible en suite automatisée (appel
réseau requis).

**Le défaut :** ADPT-06 exige la preuve de fermeture du canal d'injection en RÉPÉTITIONS (≥ 3 runs,
marqueur attendu 0/N), « jamais en un run » — livrée et cochée sur cette base. Mais la preuve
mesurée (`0/5`) ne couvre QUE le canal `skills`/`AGENTS.md` du dépôt jugé. **Le second canal
possible d'injection, `hooks`/`plugins` du même dépôt jugé, n'a jamais eu ses propres
répétitions** — voir le commit `3b7de24`, qui porte la preuve du premier canal sans toucher au
second. L'exigence est donc livrée pour un canal sur deux, pas les deux comme son intitulé («
fermeture du canal d'injection ») pourrait le laisser lire.

**Piste de fix :** reproduire le protocole de répétition déjà validé pour `skills`/`AGENTS.md`
(≥ 3 runs sur le banc témoin, marqueur attendu 0/N) pour le canal `hooks`/`plugins`. Même
discipline, même seuil de non-déterminisme (2/3 mesuré sur l'autre canal — un run propre ne prouve
rien).

**Déclencheur de reprise :** avant toute déclaration publique de fermeture COMPLÈTE du canal
d'injection du dépôt jugé (les deux canaux), ou la prochaine fois qu'ADPT-06 (ou son équivalent)
est rouvert pour un autre motif.

## Écart D-08(b) — digest du manager sans interdits du lab sur le chemin vf-dev-manager → vf-design-judge — DIFFÉRÉ (2026-09-25)

**Capturé :** 2026-09-25, nœud `fix-42-condition-samuel` (Phase 42, exécution de la condition
posée par Samuel en ratifiant D-08, `42-D19-MESURE.md` § Arbitrage D-08).

**Le défaut :** la condition (b) de Samuel (« le digest du manager porte les interdits du lab »)
est remplie côté `vf-design-manager` → `vf-design-judge` (sa section « Orchestration par écran »
le dit désormais explicitement). Mais en étage implémentation croisée d'une mission dev
(`livrable: specs+implementation`, documenté dans `vf-design-manager.md` § Étage implémentation
croisée), c'est `plugin/dev-orchestrator/agents/vf-dev-manager.md` qui compose et transmet le
digest vers `vf-design-judge` — pas `vf-design-manager`. `vf-dev-manager` relève de
`plugin/dev-orchestrator/`, de la polarité de Samuel (D-12) : aucun commit sur ce module n'est
autorisé dans ce nœud. La condition (b) reste donc non remplie sur ce chemin précis.

**Piste de fix :** soit `vf-dev-manager` porte lui-même la même consigne (commit sur
dev-orchestrator, mandat séparé, revue de Samuel) ; soit le digest transmis par `vf-dev-manager`
à `vf-design-judge` est composé par délégation à `vf-design-manager` (repli architectural
différent, à évaluer) ; soit l'écart est jugé sans conséquence pratique par Samuel (le
`CLAUDE.md` projet en contexte dev ne porte pas nécessairement d'interdits RGPD/design
distincts de ceux déjà couverts). Détail : `42-05-SUMMARY.md` § Écart non résolu,
`.planning/workstreams/gouvernance/STATE.md` § Dette.

**Déclencheur de reprise :** la revue code owner de Samuel sur `design-orchestrator` (déjà
requise par D-12), ou la prochaine mission dev qui exerce réellement l'étage implémentation
croisée avec `vf-design-judge`.

## A2 — collision de nom entre scripts de modules non détectée à l'installation — DIFFÉRÉ (2026-09-25)

**Capturé :** 2026-09-25, audit final de la Phase 42 (même famille que CR-01 côté agents,
jamais corrigée côté scripts installés).

**Le défaut :** `plugin/_internal/vibeflow-update.sh` pose les scripts (et fichiers `*.json`)
de TOUS les modules installés à plat dans un seul `.claude/scripts/` du lab cible — un même nom
de fichier `.sh` porté par deux modules différents écrase silencieusement l'un par l'autre, sans
aucun diagnostic. Dette **antérieure** à la Phase 42 (l'installeur est hors périmètre du nœud
`fix-42-juges` — décision déléguée par Willy au head, « tranche et avançons », session
principale, 2026-09-25 : correction reportée, pas traitée là non plus).

**Piste de fix :** détection de collision à l'installation (diagnostic explicite avant
écrasement silencieux), ou namespacing des scripts posés par module (préfixe ou sous-dossier par
module dans `.claude/scripts/`).

**Déclencheur de reprise :** le premier incident réel de collision entre deux modules installés
ensemble, ou une revue de fond de l'installeur.

## Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3, D-08) — DIFFÉRÉ (2026-09-25)

**Capturé :** 2026-09-25, audit final de la Phase 42.

**Le défaut :** la correction du nœud `fix-42-juges` (2026-09-25), puis celle du nœud
`fix-42-condition-samuel` (même jour), réparent l'omission/le mauvais emplacement de la citation
du `CLAUDE.md` du lab comme source à lire par `quality-gate-client` et `content-clarity-judge`.
Aucune des deux ne revisite le CONTENU des rubriques /100 elles-mêmes au regard du motif 3 de
l'arbitrage D-08 (« tout ce qu'un juge doit vérifier vit dans sa grille, jamais dans
`.claude/rules` ni dans `CLAUDE.md` ») : ni `quality-gate-client` ni `content-clarity-judge` ne
portent aujourd'hui de critère RGPD EXPLICITE dans leur tableau de rubrique (contrairement à
`growth-quality-judge`, critère 2 « Consentement / anti-spam / RGPD », éliminatoire) — la
lecture du `CLAUDE.md` comme source ne garantit pas, à elle seule, qu'un manquement RGPD fasse
baisser le score ou déclenche un éliminatoire.

**Piste de fix :** ajouter un critère RGPD explicite (avec pondération et statut éliminatoire le
cas échéant) au tableau de rubrique des deux juges, sur le modèle du critère 2 de
`growth-quality-judge`.

**Déclencheur de reprise :** la prochaine revue de fond des grilles des juges business/content,
ou un incident où un manquement RGPD n'a pas fait baisser le score d'un livrable jugé.
