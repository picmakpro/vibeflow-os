# Phase 47: Moteur — baux générationnels et jeton monotone - Context

**Gathered:** 2026-10-12
**Status:** Ready for planning
**Compartiment :** `gouvernance` — toute commande GSD de cette phase passe `--ws gouvernance` ;
`gsd-tools` s'appelle par `node ~/.claude/gsd-core/bin/gsd-tools.cjs` (1.14.0). STATE et ROADMAP se
tiennent à la main.
**Décisions humaines :** Q1 à Q7 tranchées par Willy, AskUserQuestion session principale,
2026-10-12, relayées par la session principale au manager de mission (repli D-09, pas d'outil de
question en sous-agent). Willy a suivi la recommandation (a) sur les sept questions. Elles
deviennent P47-D-01 à P47-D-07 ; Q8 et Q9, posées en planification le même jour, deviennent
P47-D-18 et P47-D-19.
**Décisions du manager :** marquées « manager », annoncées à Willy avant l'écriture de ce fichier
(relais du 2026-10-12, « ne sont pas renversées ») et dérivées ici en P47-D-08 à P47-D-17. Les
sous-décisions `a`/`b` sont aussi du manager.
**Faits de départ :** `47-SCOUTING.md` (code livré 44-46, chemin:ligne, zone partagée avec la 46.1)
et `47-RECHERCHE-BAUX.md` (doc des hooks Claude Code 2.1.296, ADR-045). Le planificateur les lit
avant tout. Les relevés de la 46 (`46-RECHERCHE-HOOKS.md`, `46-SCOUTING.md`) et de la 46.1 restent
valables pour ce qu'ils établissent.
**Ordre d'exécution :** la 47 s'exécute **après la 46.1** (feu vert de Willy, message en session
principale, 2026-10-12). Les plans sont écrits contre le code de la 46 (`78808126`) ; ils se
**re-valident** contre le code livré par la 46.1 avant toute exécution (P47-D-10).

<domain>
## Phase Boundary

La phase livre, dans `plugin/planning-core/` (et `dag.sh` dans `plugin/conductor/`), **les baux
générationnels du moteur** et ce qu'il faut pour les croire :

1. **Un registre de baux par fichier** : un bail par fichier « réécrit en place » déclaré par le lab,
   numéroté par un entier monotone (la génération) qui n'est jamais effacé, seulement dépassé.
2. **Le gate de bail** (constante `BAIL`) : le hook refuse l'écriture par outil d'un fichier déclaré
   par un appelant qui ne détient pas la plus haute génération — session revenue, sous-agent frère,
   écrivain sans bail.
3. **L'outil côté écrivain** : prendre, vérifier et écrire atomiquement, pour les scripts et les
   crons que le hook ne voit pas.
4. **G2′** à l'écriture de `CLOTURE.md` : refus quand un fichier déclaré a bougé hors bail, sans
   amendement ; amendement = prise a posteriori, tracée.
5. **`dag.sh`** sans lost update ni lecture déchirée ; **recalculs** sérialisés.
6. L'armement en **étape 7**, en observation d'abord.

Chaque gate déclare son comportement fail-closed, se prouve en vie par un canary, mesure ses faux
refus dans les deux sens et s'arme dans l'ordre, comme en 45 et 46.

**Hors de cette phase :**
- `onFailure: "block"` (2.1.295) sur l'entrée `PreToolUse` du hook central : hors 47 (P47-D-07).
- `TaskCompleted` : non utilisé (absent par défaut, inchangé en 2.1.296).
- `driver-lock.sh` (`ln -sh` en premier, `acquire` sans relecture, uutils) : BACKLOG (P47-D-14).
- Les crons et scripts métier d'un lab (`PIPELINE_STATE.json`, `com.bfl.*`) : la 47 livre l'outil
  et sa doc, **jamais** une retouche du code d'un lab. La liste des fichiers déclarés d'un lab réel
  vient de la grille (Phase 50).
- La « classe de collision qu'aucun bail ne voit » (compteur d'identifiants, spec §6.1 bis) :
  nommée en limite, non traitée (aucun fichier « compteur » n'existe dans le modèle).
- Toute release : aucune avant la clôture de `fiabilite-v1.0` (garde-fou du jalon).

</domain>

<decisions>
## Implementation Decisions

### Canal du jeton (Q1)

- **P47-D-01 :** **registre lu par le hook, lié à l'identité de l'appelant.** L'agent ne présente
  aucun jeton : rien n'est à recopier. L'identité de l'appelant est `agent_id` s'il est non vide,
  sinon `session_id` (fil principal) ; le hook lit désormais `session_id` (il ne le lisait jamais,
  `47-SCOUTING.md` §S1). L'identité du détenteur d'une génération n'est **jamais écrite par l'agent** :
  seul le moteur l'écrit — le hook depuis le payload pour un agent, l'outil côté écrivain pour un
  script (P47-D-12).
- **P47-D-01a (manager) :** le geste de prise d'un agent est un geste **reconnu par le hook** qui
  porte l'identité du payload. La forme exacte est au planificateur (recommandation du manager :
  écriture par outil d'un fichier de demande sous `.planning/baux/`, que le hook transforme en prise
  après que toutes les autres gates ont passé, sur le patron de la dérogation consommée seulement si
  la décision finale passe, `planning-hook.sh:1476-1484`). Contraintes : un `Bash` qui forge une prise
  n'est pas vu par le hook (P45-D-10) — il est tracé (D1, réconciliation) et nommé en limite ; le
  `meta` d'une génération est protégé de `Write`/`Edit` par G6 étendu en profondeur à `.planning/baux/`.

### Granularité et forme du bail (Q2)

- **P47-D-02 :** **un bail par fichier-ressource** : `.planning/baux/<clé du chemin>/gen-<n>/meta`
  (détenteur, unité, identité, origine, empreinte du fichier à la prise). Prise = `mkdir gen-<n+1>` où
  `n` est la plus haute génération observée, puis **relecture du disque** : la génération gagnante
  doit être la nôtre, jamais le seul code de sortie. Une génération n'est jamais effacée. **La prise
  réussit toujours et dépasse l'ancien détenteur** : aucun TTL de sûreté, le battement n'est
  qu'informatif. La spec §6.1 est amendée (forme du chemin, granularité, rôle du battement), avec date
  et canal.
- **P47-D-02a (manager) :** la clé du chemin est **injective** et stable (chemin relatif à la racine
  du lab, normalisé ; la forme comparée et la forme d'entrée/sortie se séparent comme en 46 : forme
  NFC pour comparer, nom brut pour les E/S — leçon de la 46, trois tours sur APFS). Le chemin en clair
  est recopié dans le `meta`. Le choix de l'encodage (hachage, encodage pourcent) est au planificateur.
- **P47-D-02b (manager) :** une génération sans `meta` complet (prise en cours, preneur mort) est lue
  comme **détenue par personne** : toute écriture par outil du fichier est refusée jusqu'à la prise
  suivante, qui la dépasse. Pas de récupération, pas de suppression (spec §6.1 : le défaut est
  « `mkdir` + suppression pour récupérer »).

### Fichiers sous bail (Q3)

- **P47-D-03 :** **liste déclarée par le lab** dans `.planning/config.json` (clé dédiée, chemins
  relatifs exacts, **au fichier près, jamais au préfixe ni au glob**), protégée par G6 comme
  l'adhésion. Les fichiers d'état du moteur (`STATE.md`, `INDEX.md`, `.recalc-cache.json`, le compteur
  G4′ de la 46.1) restent **hors bail** : gardés par G6 et écrits sous verrou du moteur. Les fichiers
  append-only restent hors bail (spec §6.2). Liste absente ou vide : le gate de bail et G2′ ne jugent
  rien (aucun faux refus sur un lab qui n'a rien déclaré). La grille de la Phase 50 remplira la liste.

### G2′ : accroche et amendement (Q4)

- **P47-D-04 :** G2′ est porté par le hook central en **`PreToolUse` sur l'écriture de `CLOTURE.md`**
  (à côté de G3, même `unite_de_fichier`), refus par deny ; une **règle miroir au recalcul** traite la
  clôture écrite par `Bash` (que le hook ne voit pas). « Ce qui a bougé » = fichiers déclarés (P47-D-03)
  dont l'empreinte a changé depuis l'ouverture de l'unité, hors baux détenus par l'unité. **Amendement =
  prise de bail a posteriori par l'unité, avec raison, tracée** : G2′ force la déclaration, il
  n'interdit pas.
- **P47-D-04a (manager) :** la référence « ouverture de l'unité » et l'attribution d'un changement à
  une unité sont **le point de conception ouvert** de la phase (`47-RECHERCHE-BAUX.md` §R4 : aucune
  source seule ne suffit — empreintes, diff git, journal D1). Le planificateur le résout en RESEARCH et
  l'écrit dans la référence, avec ces contraintes : la référence est posée **par le moteur**, jamais
  par l'agent ; elle vit hors des fichiers gardés ; un changement couvert par la génération d'un autre
  détenteur n'est pas imputé à l'unité ; un changement que personne n'a couvert (Bash, cron) est
  refusé à la clôture tant que l'unité ne l'a pas amendé ; la limite d'attribution est nommée.

### `dag.sh` (Q5)

- **P47-D-05 :** **corrigé dans la 47** : `fcntl.flock` autour de load → save, écriture dans un
  temporaire du même dossier puis `os.replace`. Preuve : cas de concurrence réel, rouge sous mutation
  (retrait du verrou, retour à la troncature), sur le patron T13/T32 de `test-driver-lock.sh`. La phase
  écrit **pourquoi le jeton monotone ne le couvre pas** : les écrivains du DAG tiennent le même mandat,
  donc le même jeton, et le fencing ne rejette que les détenteurs périmés. `conductor` reçoit son bump
  propre (VERSION, CHANGELOG, module.json), **renuméroté après les merges de `fiabilite`** (garde-fou
  du jalon : une PR de ce jalon qui bumpe un module partagé se rebase et se renumérote, jamais
  l'inverse). La fiche BACKLOG (`.planning/BACKLOG.md:169`) est close par la 47.

### Armement (Q6)

- **P47-D-06 :** **étape 7** de l'ordre d'armement, `("BAIL", "G2P")` ; constantes en observation à la
  livraison. Le rejeu réel en lecture seule et l'armement sont des **checkpoints humains bornés au
  moment d'agir** (patron 46-11/46-12), jamais une autorisation gravée dans un plan. L'étape 7 est
  inarmable tant que G4′ (étape 6, 46.1) ne l'est pas (`armement_valide`). Chaque armement à 0 faux
  refus et 0 faux accept sur le banc puis sur le rejeu.
- **P47-D-06a (manager) :** scission 7a/7b permise sur le patron 5a/5b (`G2P` armé ⇒ `BAIL` armé).

### `onFailure: "block"` (Q7)

- **P47-D-07 :** **hors 47.** Fiche BACKLOG, limite nommée dans `modele-cycles.md`, spec §5.1-2
  annotée (« réglable depuis 2.1.295 », date et source). Motif : le réglage touche tous les gates et la
  commande enregistrée que la 46.1 réécrit (P461-D-03b).

### Décisions du manager (renversables par Willy)

- **P47-D-08 :** famille d'exigences **`BAIL`** (vérifiée libre le 2026-10-12 sur HEAD, `8519c402`,
  `origin/main` et le disque ; `LOCK` est pris par `fiabilite`).
- **P47-D-09 :** `planning-core` passe en **mineure v2.12.0** (la 46.1 l'aura passé en v2.11.0), à
  confirmer au moment d'exécuter ; CHANGELOG et module.json suivent ; **aucune release**.
- **P47-D-10 :** **zone partagée avec la 46.1**, déclarée dans chaque plan qui la touche : bloc
  d'armement et `armement_valide` (`planning-hook.sh:133-144`, `:551-573`), `GATES_A_VERDICT`
  (`:2774`), `PROTEGES_G6` et `fichier_protege` (`:1552-1643`), D1 (`reconcilier`,
  `FICHIERS_RACINE_SURVEILLES`), commande enregistrée (`hooks.json`, P461-D-03b), `check-gates-alive.sh`,
  `rejeu-gates.sh`, `rejeu-reel.sh`, `NOMS_MODELE_RACINE_*` du recalcul, suites `test-planning-gates.sh`,
  `test-cloture-gates.sh`, `test-d1-surveillance.sh`, `test-rejeu-gates.sh`, `modele-cycles.md`, spec §5,
  `VERSION`/`module.json`/`CHANGELOG.md`. Les numéros de ligne sont ceux de `78808126` : chaque plan
  cite la **fonction**, pas la ligne, et se re-valide (plan-checker frais) contre le code livré par la
  46.1 avant exécution.
- **P47-D-11 :** **aucun nouvel événement de hook** : le gate de bail et G2′ vivent dans `PreToolUse`
  (`Write|Edit|NotebookEdit`), déjà câblé. La commande enregistrée n'est pas réécrite par la 47.
- **P47-D-12 :** **outil côté écrivain** dans `planning-core` (prendre, vérifier, écrire atomiquement
  sous `fcntl.flock`, temporaire du même dossier + `os.replace`) ; la vérification « ma génération est
  la plus haute » se fait **au moment d'écrire**, sous le verrou, jamais au réveil ; un écrivain dépassé
  **se replie** (n'écrit pas, journalise, code ≠ 0). Identité : dans une session, `session:<CLAUDE_CODE_SESSION_ID>`
  (un sous-agent voit l'identifiant du parent : faux refus possible, jamais faux accept) ; hors session,
  `hors-session:<label>` déclaré. Doc d'usage pour un cron (launchd, cron) dans la référence.
- **P47-D-13 :** **recalculs concurrents sérialisés** par `fcntl.flock` (relevé F7 du scouting :
  `cloture.log` dédoublonné hors verrou puis ajouté sans `flock`). Le recalcul renseigne la colonne
  « Bail en cours » de `INDEX.md` (codée `aucun` aujourd'hui, `recalc-planning.sh:2051`).
- **P47-D-14 :** `driver-lock.sh` (`ln -sh` tenté en premier, `acquire` sans relecture du disque,
  piège uutils) : fiche BACKLOG, hors 47 (module `conductor`, sans rapport au bail du moteur).
- **P47-D-15 :** **aucune sonde `claude -p`** (P46-D-08 reconduit). Limites nommées : #90662
  (`PreToolUse` d'un sous-agent reçu sous un autre `agent_id` : faux refus possible), `session_id` du
  sous-agent = parent (non documenté), Windows (`fcntl` absent : aucun verrou), `Bash` invisible au
  hook (prise forgée, écriture directe), fenêtre `PreToolUse` → écriture (aucun compare-and-swap natif
  de `Write`/`Edit`), compteur d'identifiants non couvert.
- **P47-D-16 :** **marqueur `Gate-Touche:`**, un chemin par trailer, sur tout commit qui touche un gate,
  sa suite, le workflow CI ou un hook (convention du dépôt).
- **P47-D-17 :** ROADMAP §47 : la ligne `Depends on` reçoit le texte prêt de `46-NOTE-ROADMAP-47.md`
  (b) ; la référence `BACKLOG.md:74` est corrigée en `:169`.

### Décisions de planification tranchées par Willy (Q8, Q9)

> Arbitrages Willy, AskUserQuestion session principale, 2026-10-12, relayés verbatim par la session
> principale à la reprise de la mission. Posées après six tours de plan-check frais (Q9) et une
> condition d'armement ajoutée par le planificateur (Q8).

- **P47-D-18 (Q8 → « (a) Attendre une liste réelle (Recommandé) ») :** la condition `LISTE-REELLE
  n ≥ 1` est **gardée**. `BAIL` et G2′ sont livrés en observation ; leur armement attend une liste
  réelle de fichiers déclarés (Phase 50, ou liste posée à la main sur un lab) ; les checkpoints de
  47-13 et 47-14 se rejouent à ce moment-là. Précise P47-D-06 sans le renverser.
- **P47-D-19 (Q9 → « (a) Détection au mieux (Recommandé) ») :** la garantie « jamais clos en silence »
  de G2′ est **bornée aux clôtures par outil** (`PreToolUse` sur `CLOTURE.md`). Au recalcul, la règle
  miroir est une **détection au mieux** d'une clôture hors outil : elle signale ce que le journal du
  moteur montre (changement non couvert d'un fichier déclaré), **sans prétention de complétude**.
  « Clôture hors outil » devient une **limite nommée**, même régime que P45-D-10 (`Bash` invisible au
  hook). Précise P47-D-04 (« règle miroir au recalcul ») sans le renverser : le miroir reste, sa
  garantie est retirée. Conséquence de planification : les mécanismes ajoutés au seul service de la
  complétude du miroir (inventaire de départ, exemption par empreinte du triplet, preuve générative à
  équivalence) sortent de 47-09 sauf s'ils servent la détection au mieux à faible coût ; aucun
  plan-check n'exige plus qu'une clôture hors outil ne finisse jamais `close` en silence.

### Claude's Discretion

Laissés au planificateur :
- Le geste exact de prise d'un agent (P47-D-01a), dans ses contraintes.
- L'encodage de la clé du chemin (P47-D-02a), dans ses contraintes.
- La résolution de la référence d'ouverture d'unité et de l'attribution des changements (P47-D-04a),
  écrite en RESEARCH puis dans la référence.
- Le nom de la clé de `config.json` et le format du `meta` (lignes `clé: valeur` ou JSON), pourvu que le
  recalcul, le hook et l'outil côté écrivain lisent **une seule** implémentation (patron des copies
  ast-identiques de la 46, `modele-cycles.md:461-468`).
- Le découpage en plans et en vagues.

</decisions>

<requirements_proposed>
## Exigences proposées (famille BAIL)

> Chaque exigence dérive d'une décision ci-dessus (préfixe `P47-D-NN`, ADR-075) et ne pose aucune
> décision nouvelle.

- **BAIL-01** : un registre de baux par fichier, `.planning/baux/<clé>/gen-<n>/meta`, génération
  entière monotone jamais effacée ; prise par `mkdir gen-<n+1>` puis relecture du disque ; N preneurs
  concurrents → exactement un gagnant par génération, prouvé par un cas de concurrence réel rouge sous
  mutation ; génération sans `meta` complet = détenue par personne (P47-D-02, 02a, 02b).
- **BAIL-02** : l'identité du détenteur (`agent_id`, sinon `session_id`) n'est écrite que par le moteur ;
  le geste de prise d'un agent est reconnu par le hook ; le `meta` est protégé de `Write`/`Edit` par G6
  étendu à `.planning/baux/` (P47-D-01, 01a).
- **BAIL-03** : le gate `BAIL` refuse par deny l'écriture par outil d'un fichier déclaré quand aucune
  génération n'existe, quand la plus haute est incomplète, ou quand son détenteur n'est pas l'appelant
  (session revenue, sous-agent frère, détenteur dépassé) ; hors liste ou hors adhésion, aucun effet
  (P47-D-01, P47-D-03).
- **BAIL-04** : la liste des fichiers sous bail est déclarée dans `.planning/config.json`, au fichier
  près, protégée par G6 ; liste absente ou vide = rien jugé ; fichiers d'état du moteur et append-only
  hors bail (P47-D-03).
- **BAIL-05** : un outil côté écrivain prend, vérifie au moment d'écrire sous `fcntl.flock` et écrit par
  temporaire + `os.replace` ; un écrivain dépassé se replie avec un code ≠ 0 et une trace ; l'usage par
  un cron est documenté (P47-D-12).
- **BAIL-06** : G2′ refuse par deny l'écriture par outil d'un `CLOTURE.md` d'unité quand un fichier
  déclaré a bougé depuis l'ouverture de l'unité hors des baux qui le couvrent, sans amendement ; une règle
  miroir au recalcul traite la clôture par `Bash` ; l'amendement est une prise a posteriori avec raison,
  tracée (P47-D-04, 04a).
- **BAIL-07** : `dag.sh` ne perd plus de mise à jour ni ne se lit tronqué (`flock` + temporaire +
  `os.replace`), prouvé par un cas concurrent réel rouge sous mutation ; la phase écrit pourquoi le jeton
  ne le couvre pas ; `conductor` bumpé, renuméroté après `fiabilite`, sans release ; fiche BACKLOG close
  (P47-D-05).
- **BAIL-08** : deux recalculs concurrents se sérialisent (`flock`), le dédoublonnage de `cloture.log`
  se fait sous verrou ; `INDEX.md` renseigne la colonne « Bail en cours » (P47-D-13).
- **BAIL-09** : l'armement suit l'étape 7 `("BAIL", "G2P")`, en observation à la livraison, chaque
  armement à 0 faux refus et 0 faux accept sur le banc puis sur le rejeu en lecture seule, rejeu réel et
  armement sous checkpoint humain au moment d'agir ; inarmable tant que G4′ ne l'est pas (P47-D-06, 06a).
- **BAIL-10** : zéro régression hors adhésion et sur les labs dev (aucun nouvel événement, mutation
  « ignorer l'adhésion » rouge) ; le canary couvre `BAIL` et `G2P` ; la spec moteur est amendée (§5,
  §5.1-2 annotée, §6.1, §6.2, §6.4) avec date et canal ; `modele-cycles.md` porte le registre, les gates,
  l'outil et les limites nommées ; fiches BACKLOG `onFailure` et `driver-lock.sh` posées ;
  `planning-core` en v2.12.0 sans release ; suites en CI Linux (P47-D-07, 09, 11, 14, 15, 16).

</requirements_proposed>

<canonical_refs>
## Canonical References

### Faits de départ
- `47-SCOUTING.md` — code livré 44-46, points d'insertion, zone partagée 46.1, preuves, espace de noms.
- `47-RECHERCHE-BAUX.md` — identité en fan-out, présentation du jeton, atomicité macOS/Linux, accroche de
  G2′, écrivains hors session (Claude Code 2.1.296).
- `../VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-RECHERCHE-HOOKS.md`, `46-SCOUTING.md`.

### Spec source
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5 (table, G2′ l.343, amendement
  l.359), §5.1-2 (fail-open), §6 (6.1, 6.1 bis, 6.2, 6.3, 6.4), D-04 (l.135).

### Planning du compartiment
- `.planning/workstreams/gouvernance/ROADMAP.md` §Phase 47 ; `REQUIREMENTS.md` (famille BAIL) ;
  `../VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-CONTEXT.md` (P46-D-01, D-11, D-19) ;
  `46-NOTE-ROADMAP-47.md` ; `46-VERIFICATION.md`.
- Phase 46.1 : `46.1-CONTEXT.md` (P461-D-01..15, ARMG-01..10) — commit local `8519c402` de la branche
  `gouvernance/phase-46.1-cadrage` au moment du cadrage ; à relire sur la branche livrée avant exécution.
- `.planning/BACKLOG.md:169` (fiche `dag.sh`).

### Module cible et voisins
- `plugin/planning-core/scripts/planning-hook.sh`, `recalc-planning.sh`, `poser-verdict.sh`,
  `check-gates-alive.sh`, `rejeu-gates.sh`, `rejeu-reel.sh`, `deroger-gate.sh` ; `references/modele-cycles.md` ;
  `hooks/hooks.json` (non réécrit, P47-D-11).
- `plugin/conductor/scripts/dag.sh`, `tests/test-dag.sh` ; patron concurrent `tests/test-driver-lock.sh`
  T13/T32.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `consommer` (`planning-hook.sh`, lecture + ajout sous `flock`) et la dérogation consommée seulement si
  la décision finale passe — patron du geste de prise reconnu par le hook.
- `ecrire_si_different` (`recalc-planning.sh`), `ecrire_atomique` et `ouvrir_verrou` (`poser-verdict.sh`)
  — écriture atomique et verrou existants.
- `controle_tentative` (`poser-verdict.sh`) — jeton monotone déjà livré à l'échelle d'un fichier, mais
  stocké **dans** le fichier gardé (forgeable) : le « dernier jeton vu » de la 47 vit hors du fichier.
- `ln_atomic`, `mv_link`, mutex par génération observée et relecture après acquisition
  (`driver-lock.sh`) ; tests concurrents T13/T32.

### Established Patterns
- Constante d'armement par gate, `ORDRE_ETAPES` et sa copie dans `rejeu-gates.sh`, `armement_valide`,
  canary par gate, banc à faux refus / faux accept mesurés dans les deux sens, mutation d'armement.
- Une seule implémentation partagée par le hook, le recalcul et l'outil, ou des copies prouvées
  ast-identiques.
- Fail-closed sous adhésion, silence hors adhésion, contrat de sortie P46-D-10 (jamais exit 2).

### Integration Points
- `evaluer_gates` / `GATES_A_VERDICT` (gate `BAIL` et `G2P`), `evaluer_g3` / `unite_de_fichier` (G2′),
  `fichier_protege` (profondeur `.planning/baux/`), `deriver_feuille` du recalcul (règle miroir de G2′),
  `appliquer_ecritures` du recalcul (verrou), `NOMS_MODELE_RACINE_DOSSIERS` (`baux` déjà réservé, non
  parcouru).

</code_context>

<specifics>
## Specific Ideas

- Le fan-out est le cas décisif (spec §6.1 bis) : deux sous-agents frères qui prennent le même fichier se
  dépassent l'un l'autre ; le second rend le premier périmé — conflit rendu visible, au prix d'un
  ping-pong entre écrivains légitimes. Le banc doit le montrer.
- La session revenue : même `session_id`, génération dépassée entre-temps → refus ; même `session_id`,
  personne n'a repris → passage. Le banc couvre les deux.
- Le cron : l'outil côté écrivain relit au moment d'écrire, pas au réveil (spec §6.3, recherche R5).

</specifics>

<deferred>
## Deferred Ideas

- `onFailure: "block"` sur l'entrée `PreToolUse` (P47-D-07) : BACKLOG, phase dédiée.
- `driver-lock.sh` sous uutils (P47-D-14) : BACKLOG ; mesurer l'image `ubuntu-26.04` avant qu'elle
  devienne `ubuntu-latest`.
- Jeton sur la ressource « compteur d'identifiants » (spec §6.1 bis) : limite nommée.
- Hook git `pre-commit` comme filet de G2′ hors session : non retenu, mentionné en limite.

</deferred>

---

*Phase: 47-moteur-baux-generationnels-et-jeton-monotone*
*Context gathered: 2026-10-12*
