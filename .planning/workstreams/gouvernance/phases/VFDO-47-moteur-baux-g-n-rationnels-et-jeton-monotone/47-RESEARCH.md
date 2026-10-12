# Phase 47: Moteur — baux générationnels et jeton monotone - Research

**Researched:** 2026-10-12
**Domain:** moteur de planning métier (`plugin/planning-core/`, `dag.sh` dans `plugin/conductor/`) — registre de baux générationnels au fichier près, gate `BAIL`, G2′ à la clôture, outil côté écrivain, sérialisation de `dag.sh` et des recalculs, armement en étape 7
**Confidence:** HIGH sur les faits de code et la concurrence (relus et rejoués en prototype) ; MEDIUM sur la résolution de P47-D-04a (conception neuve, jamais exercée contre le vrai harnais) ; MEDIUM sur ce que le harnais fait du `PreToolUse` d'un sous-agent (limites nommées par la recherche documentaire, aucune sonde)
**Compartiment :** `gouvernance` — toute commande GSD passe `--ws gouvernance` ; `gsd-tools` = `node ~/.claude/gsd-core/bin/gsd-tools.cjs` ; jamais `state.*`, `roadmap.*`, `requirements.mark-complete`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- `onFailure: "block"` sur l'entrée `PreToolUse` (P47-D-07) : BACKLOG, phase dédiée.
- `driver-lock.sh` sous uutils (P47-D-14) : BACKLOG ; mesurer l'image `ubuntu-26.04` avant qu'elle
  devienne `ubuntu-latest`.
- Jeton sur la ressource « compteur d'identifiants » (spec §6.1 bis) : limite nommée.
- Hook git `pre-commit` comme filet de G2′ hors session : non retenu, mentionné en limite.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAIL-01 | registre de baux par fichier `.planning/baux/<clé>/gen-<n>/meta`, génération monotone jamais effacée, prise `mkdir` + relecture, N preneurs → un gagnant par génération, génération sans `meta` complet = détenue par personne | §R-3 (clé), §Concurrence (prototype 24 preneurs : 24 générations contiguës, 0 faux succès ; deux mutants rouges), §Code Examples (prise) |
| BAIL-02 | identité du détenteur (`agent_id`, sinon `session_id`) écrite par le moteur seul ; geste de prise reconnu par le hook ; `meta` protégé par G6 en profondeur | §R-2 (geste = fichier de demande unique sous `.planning/baux/demandes/`, effet après décision finale, identité du payload) |
| BAIL-03 | gate `BAIL` : deny si aucune génération / plus haute incomplète / détenteur ≠ appelant ; hors liste ou hors adhésion aucun effet | §Architecture (gate), banc B01-B24 (§Validation) |
| BAIL-04 | liste des fichiers sous bail dans `config.json`, au fichier près, protégée par G6 ; liste absente ou vide = rien jugé ; état du moteur et append-only hors bail | §R-2 (protection de la liste : `adhesion_conservee` étendue), §Pitfalls |
| BAIL-05 | outil côté écrivain : prendre, vérifier sous `flock` au moment d'écrire, temporaire + `os.replace`, repli code ≠ 0, doc cron | §Concurrence (section critique), §Code Examples, §Open Questions (identité d'un script de sous-agent) |
| BAIL-06 | G2′ deny à l'écriture de `CLOTURE.md` (garantie par outil), règle miroir au recalcul en détection au mieux (P47-D-19), amendement = prise a posteriori tracée | §R-1 (résolution de P47-D-04a : journal d'empreintes par fichier déclaré, repère d'ouverture, règle d'imputation, banc G01-G23) |
| BAIL-07 | `dag.sh` sans lost update ni lecture déchirée (`flock` + temporaire + `os.replace`), preuve rouge sous mutation, pourquoi le jeton ne le couvre pas, bump `conductor`, fiche BACKLOG close | §Concurrence (reproduction : 40 écrivains → 4 pertes, 108 lectures déchirées ; correctif prototype : 0/0), §Pitfalls (mode 0600, lien) |
| BAIL-08 | recalculs concurrents sérialisés, dédoublonnage de `cloture.log` sous verrou, colonne « Bail en cours » renseignée | §Concurrence (verrou sur le descripteur du dossier de planning), §Architecture (colonne) |
| BAIL-09 | armement étape 7 `("BAIL", "G2P")`, observation à la livraison, 0 faux refus / 0 faux accept banc puis rejeu, checkpoints humains, inarmable avant G4′ | §Armement (les lieux qui recopient la liste des gates), §Découpage (plans 7a/7b) |
| BAIL-10 | zéro régression hors adhésion et labs dev, canary BAIL/G2P, spec et `modele-cycles.md` amendés, fiches BACKLOG, `planning-core` v2.12.0 sans release, suites en CI Linux | §Validation Architecture, §Project Constraints, §Zone partagée avec la 46.1 |
</phase_requirements>

## Summary

La 47 ajoute un **registre de baux générationnels** au fichier près, un **gate `BAIL`** (le hook confronte l'identité du payload au détenteur de la plus haute génération), **G2′** (refus à l'écriture de `CLOTURE.md` d'un changement que personne n'a déclaré), un **outil côté écrivain** et deux corrections de concurrence (`dag.sh`, recalculs). Tout vit dans des blocs de code que le dépôt sait déjà dupliquer et comparer (copies ast-identiques, `_jeton_journal`, `consommer`, `decider`), sans nouvel événement de hook ni nouveau paquet. Le travail difficile n'est pas la prise (un prototype de 24 preneurs concurrents rend 24 générations contiguës, 0 faux succès), c'est **l'attribution d'un changement à une unité** pour G2′ : les trois sources du relevé R4 sont insuffisantes seules, et la solution retenue ci-dessous (journal d'empreintes par fichier déclaré, posé par le moteur sous `.planning/baux/<clé>/`, avec repère d'ouverture d'unité et prise = déclaration) est la plus petite qui tienne les cinq contraintes de P47-D-04a.

Les trois points ouverts sont résolus avec preuve lue dans le code : (1) **P47-D-04a** — la référence d'ouverture est une ligne `ouverture` que le moteur ajoute au journal d'empreintes de chaque fichier déclaré au premier contact du moteur avec l'unité, **après** avoir réconcilié ce fichier (un changement antérieur à l'ouverture n'est jamais imputé à l'unité) ; un changement est imputé à l'unité quand le journal porte un `contournement` après son ouverture et que l'unité n'a pris aucune génération du fichier depuis ; (2) **P47-D-01a** — le geste de prise est un `Write` d'un fichier de demande à nom unique sous `.planning/baux/demandes/`, transformé en prise par le hook **après** la décision finale (même emplacement que `inscrire_intentions`, `planning-hook.sh:3528`), faisable à cinq conditions dont une extension de G6 qui **n'existe pas aujourd'hui** (`.planning/baux/` n'est pas protégé : `fichier_protege` exige l'enfant direct de `.planning/`) ; (3) **P47-D-02a** — la clé est le `sha256` hexadécimal du chemin déclaré en forme NFC (64 caractères ASCII), avec vérification du chemin en clair du `meta` à chaque lecture : ni normalisation Unicode, ni casse, ni borne de 255 octets ne peuvent plus piéger un nom de dossier.

Le piège de livraison le plus coûteux est silencieux : **une quinzaine de lieux (une vingtaine de lignes) recopient la liste des gates** (sept suites, `rejeu-gates.sh`, `rejeu-reel.sh`, `check-gates-alive.sh`, `deroger-gate.sh`, la suite d'installation, la référence…) ; deux constantes de plus passent le compte de 8 à 10, et les expressions `re.subn(...)` des copies « découplées » trouveraient encore 8 correspondances et laisseraient `ARMEMENT_BAIL`/`ARMEMENT_G2P` à la valeur livrée — sans rougir tant que l'étape 7 n'est pas armée. Le plan d'armement doit tout étendre dans le commit qui ajoute les constantes.

**Primary recommendation :** livrer d'abord le bloc « registre + journal d'empreintes » en une seule implémentation copiée à l'identique dans le hook, l'outil écrivain et le recalcul (patron R-EMP-04), puis les gates `BAIL` et `G2P` en observation, puis le branchement de l'étape 7 dans tous les lieux qui recopient la liste des gates ; ne jamais armer sans le rejeu humain du moment d'agir.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Identité de l'appelant (`agent_id`, sinon `session_id`) | Hook central (`PreToolUse`) | Outil écrivain (variable `CLAUDE_CODE_SESSION_ID`) | seul le harnais connaît l'`agent_id` ; un script Bash ne le voit jamais `[CITED: 47-RECHERCHE-BAUX.md R1.5]` |
| Registre de baux, prise, relecture | Système de fichiers du lab (`.planning/baux/`) écrit par le moteur | — | `mkdir` exclusif + création exclusive du `meta` : l'atomicité est celle du noyau |
| Vérification « ma génération est la plus haute » à l'écriture par outil | Hook central | — | seul point qui voit `Write`/`Edit`/`NotebookEdit` avant l'écriture |
| Vérification au moment d'écrire pour scripts et crons | Outil côté écrivain (`planning-core`) | — | aucun hook ne voit un cron ni un `Bash` (P45-D-10) |
| Référence d'ouverture d'unité, journal d'empreintes | Moteur (hook + outil + recalcul, un seul bloc) | Disque sous `.planning/baux/` | posée par le moteur, jamais par l'agent ; protégée par G6 en profondeur |
| G2′ à la clôture par outil | Hook central (`PreToolUse` sur `CLOTURE.md`) | Recalcul (règle miroir pour la clôture par `Bash`) | même accroche que G3, pour l'écriture visible ; le recalcul voit tout ce qui est sur disque |
| Sérialisation de `dag.sh` et des recalculs | Script concerné (`fcntl.flock` + `os.replace`) | — | le jeton monotone ne sérialise pas deux détenteurs courants |
| Colonne « Bail en cours » de `INDEX.md` | Recalcul (lecture seule du registre) | — | fichier généré, protégé par G6 |
| Armement et preuve de vie | Hook (constantes), `check-gates-alive.sh`, `rejeu-*.sh` | Checkpoints humains | patron de la 45 et de la 46 |

## Valeurs relues dans le code (verbatim, session du 2026-10-12)

> Règle de provenance : seules les valeurs ci-dessous (ouvertes avec `Read` cette session) portent `[VERIFIED: chemin:lignes]`. Les noms, bornes et formats proposés plus bas pour les artefacts NEUFS sont des **propositions de conception** `[ASSUMED: nom proposé]` : le planificateur peut les renommer.

`[VERIFIED: plugin/planning-core/scripts/planning-hook.sh:133-144]`
```
ARMEMENT_G6 = "armed"  # etape-1
ARMEMENT_G5 = "armed"  # etape-1
ARMEMENT_G1 = "armed"  # etape-2
ARMEMENT_G7 = "armed"  # etape-3
ARMEMENT_ROLE = "armed"  # etape-4
ARMEMENT_G3 = "armed"  # etape-5
ARMEMENT_G4 = "observe"  # etape-5
ARMEMENT_G4P = "observe"  # etape-6
G2_MODE = "avertit"
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3", "G4"), ("G4P",))
TABLE_ARMEMENT = {"G6": ARMEMENT_G6, "G5": ARMEMENT_G5, "G1": ARMEMENT_G1, "G7": ARMEMENT_G7, "ROLE": ARMEMENT_ROLE,
                  "G3": ARMEMENT_G3, "G4": ARMEMENT_G4, "G4P": ARMEMENT_G4P}
```
`[VERIFIED: planning-hook.sh:2774]` `GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role), ("G3", evaluer_g3), ("G4", evaluer_g4), ("G4P", evaluer_g4p))  # gates-a-verdict`

`[VERIFIED: planning-hook.sh:1552-1557]`
```
GENERES_PAR_RECALC = ("STATE.md", "INDEX.md", "cloture.log", ".recalc-cache.json")  # g6-noms
NOM_CONFIG = "config.json"
PROTEGES_G6 = dict([(nom.casefold(), (nom, "recalc")) for nom in GENERES_PAR_RECALC]
```
`[VERIFIED: planning-hook.sh:1596-1597]` `    a_la_racine = _meme_dossier(parent, planning)  # g6-racine` puis `    if a_la_racine and nom.casefold() in PROTEGES_G6:  # id-casefold` — **G6 ne protège que l'enfant direct de `.planning/`** ; un fichier sous `.planning/baux/` n'est donc pas protégé aujourd'hui (`fichier_protege` rend `None`, `script_protege` rend `None`, `evaluer_g6` rend `[]`, lignes 1698-1719).

`[VERIFIED: planning-hook.sh:1476-1484]` le patron de consommation : `    if refus:  # decider-global` / `        return refus, citations` / `    for verdict, entree in couverts:` / `        if consommer(contexte["racine"], entree):`

`[VERIFIED: planning-hook.sh:3528]` `                inscrire_intentions(payload, cibles or [(ecrit, racine)])  # d1-intention : la décision finale est un passage, l'écriture par outil est tracée (D1)` — c'est l'emplacement où `main` agit **après** `evaluer_gates`, uniquement si `refus` est vide.

`[VERIFIED: planning-hook.sh:2625]` `    agent_id, agent_type = payload.get("agent_id"), payload.get("agent_type")` ; `grep -c "session_id" plugin/planning-core/scripts/planning-hook.sh` rend `0` (relevé de cette session) : le hook ne lit pas `session_id`.

`[VERIFIED: plugin/planning-core/hooks/hooks.json:41]` `"matcher": "Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback",` — le hook reçoit déjà `Bash`, `Write`, `Edit`, `NotebookEdit`.

`[VERIFIED: planning-hook.sh:2814-2816, 2889-2890]` `BORNE_WATCHPATHS = 128` ; `BORNE_LECTURE_SURVEILLANCE = 4194304` ; dans `chemin_relatif_surveille` : `    if composants[0] != NOM_PLANNING:` / `        return None` — D1 ne connaît que des formes sous `.planning/`, jamais un fichier déclaré hors de `.planning/`.

`[VERIFIED: plugin/planning-core/scripts/recalc-planning.sh:765]` `NOMS_MODELE_RACINE_DOSSIERS = ("cycles", "baux", "missions", "juges")` ; `[VERIFIED: recalc-planning.sh:2058]` `                + " | " + dernier + " | aucun |"` ; `[VERIFIED: recalc-planning.sh:2128,2131]` `    fd_tmp, chemin_tmp = tempfile.mkstemp(dir=dossier, prefix=".tmp-recalc-")` puis `        os.fchmod(fd_tmp, 0o644)` (le dépôt corrige déjà le mode 0600 de `mkstemp`).

`[VERIFIED: plugin/conductor/scripts/dag.sh:117-121]`
```
def save(dag):
    os.makedirs(os.path.dirname(file) or ".", exist_ok=True)
    with open(file, "w", encoding="utf-8") as fh:
        json.dump(dag, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
```
`[VERIFIED: plugin/planning-core/scripts/deroger-gate.sh:63]` `GATES = ("G1", "G3", "G4", "G4P", "G5", "G6", "G7", "ROLE", "PLAFOND")` ; `[VERIFIED: check-gates-alive.sh:195]` `GATES = ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P")` ; `[VERIFIED: rejeu-gates.sh:147-149]` `GATES = (…)`, `ORDRE_ETAPES = (…)` (copie), `ETAPE_DE = dict((g, i + 1) for i, lot in enumerate(ORDRE_ETAPES) for g in lot)`.

`[VERIFIED: .github/workflows/ci.yml:218]` `suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)` — toute suite nommée `test-*.sh` sous un dossier `tests/` est lancée par `bash "$t"` sur Linux.

`[VERIFIED: plugin/conductor/scripts/check-method-budget.sh:196-201]` `function isclosed(t,   n, p, w) {` … `  n = split(t, p, " — ")` … `  return (w == "CLOS" || w == "RÉSORBÉ" || w == "ADOPTÉ" || w == "ADOPTÉE")` : un sujet de BACKLOG est clos quand le dernier mot après ` — ` de son titre `## ` en fait partie ; `[VERIFIED: .planning/BACKLOG.md:169]` `## `save()` de `dag.sh` sans verrou ni écriture atomique — lost update silencieux — DIFFÉRÉ` (clore = remplacer `DIFFÉRÉ` par `CLOS`).

`[VERIFIED: plugin/planning-core/VERSION, plugin/conductor/VERSION, VERSION, cette branche]` `v2.10.0` ; `v1.46.0` ; `v2.68.0`. `[VERIFIED: sortie de git show origin/main:<fichier>, cette session]` sur `origin/main` : `plugin/conductor/VERSION` = `v1.48.2`, `plugin/planning-core/VERSION` = `v2.8.1`, `VERSION` = `v2.69.1`.

`[VERIFIED: sortie de scripts/check-version-sync.sh, 2026-10-12]` `README.md suites 109`, `README.fr.md suites 109`, `triade par module : 17 modules VERSION ↔ module.json alignés` — le compte « N suites » des deux README racine doit suivre chaque suite ajoutée (109 trouvées par `find` sur cette branche).

## Résolution des trois points ouverts

### R-1 — P47-D-04a : référence d'ouverture d'unité et attribution d'un changement (G2′)

**Pourquoi aucune des trois sources du relevé R4 ne suffit seule** `[CITED: 47-RECHERCHE-BAUX.md R4]` :

| Source | Ce qu'elle voit | Pourquoi elle ne tient pas seule (preuve) |
|--------|-----------------|--------------------------------------------|
| Empreintes prises à la prise du bail | `Bash` et cron | ne couvrent que les fichiers déjà pris ; ne disent ni qui ni pendant quelle unité ; une prise qui re-pose la référence **blanchit** un changement antérieur si elle ne réconcilie pas d'abord |
| `git diff --name-only <base>` | tout fichier suivi | « Git est hors jeu par D-02 » (spec §7.4) ; rate les fichiers ignorés par git ; `merge=union` lisse les collisions (spec §6.1 bis) ; un lab n'est pas toujours un dépôt git |
| Journal D1 (`surveillance.log`) | écritures sur des formes **sous `.planning/`** | `chemin_relatif_surveille` rend `None` dès que `composants[0] != NOM_PLANNING` (`planning-hook.sh:2889-2890`) : un fichier déclaré hors de `.planning/` n'y existe pas ; liste bornée à `BORNE_WATCHPATHS = 128` et fenêtre de lecture `BORNE_LECTURE_SURVEILLANCE = 4194304` (`:2814`, `:2816`) ; `FileChanged` sourd après un `cd` (#95440) ; et `reconcilier`, `decider_trace`, `chemins_surveilles` sont **réécrits par la 46.1** (N-5, A5) : bâtir G2′ dessus aggraverait la zone partagée de P47-D-10 |

**Solution retenue (une seule) : un journal d'empreintes par fichier déclaré, dans le registre, posé par le moteur.** Il réutilise la **règle d'explication de D1** (une intention explique un changement, l'écrivain du moteur pose sa propre référence) sans toucher aux fonctions de D1.

*Données* `[ASSUMED: noms proposés]` :
```
.planning/baux/
  .gitignore                 posé par le moteur à la 1re prise : « * » et « !.gitignore » (état local, jamais commité)
  demandes/<nom>.md          gestes de prise écrits par outil (trace lisible de qui a demandé quoi)
  .unites/<clé-unité>        repère d'ouverture d'unité (création exclusive), contient le chemin de l'unité en clair
  <clé>/                     clé = sha256 hex de NFC(chemin déclaré) (voir R-3)
    verrou                   fichier stable, jamais remplacé : cible du flock du registre de ce fichier
    empreintes.log           journal append-only de ce fichier déclaré, sous flock
    gen-<n>/meta             immuable : publié en création exclusive, complet ou absent
```
*Ligne du journal* (même grammaire que D1, valeurs par `_jeton_journal`, deux espaces entre champs) :
`<ISO UTC>  genre=<g>  gen=<n|->  sha256=<hex|absent|->  par=<identité>  unite=<chemin d'unité|->`
Genres : `reference` (état constaté ou posé par le moteur), `intention` (écriture par outil du détenteur, passée par le hook, sha inconnu), `contournement` (changement que rien n'explique), `ouverture` (repère d'unité), `prise` (génération prise, `origine` dans le `meta`).

*Règle d'explication* (fonction PURE `decider_baux(lignes, sha)`, patron de `decider_trace` `planning-hook.sh:2970-2987`, sans le genre `moteur` : l'outil écrivain pose directement un `reference`) : aucune référence → `["reference"]` ; sha égal à la dernière référence → `[]` (aucune ligne : une intention antérieure reste en attente, c'est ce qui rend la fenêtre `PreToolUse` → écriture inoffensive pour G2′) ; sinon, s'il existe une `intention` **après** la dernière référence → `["reference"]` (expliqué) ; sinon `["contournement", "reference"]`.

*Règle d'or* : **toute opération qui pose une référence (prise, ouverture d'unité, écriture par l'outil, constatation de G2′) réconcilie d'abord** : elle calcule le sha courant, applique `decider_baux` et ajoute les lignes demandées **avant** la sienne. Sans cela une prise ou une ouverture blanchirait un changement de `Bash` qui l'a précédée.

*Référence d'ouverture d'unité* — **posée par le moteur, hors des fichiers gardés, jamais par l'agent** : au **premier contact du moteur avec l'unité**, parmi (i) une prise dont la demande nomme `unite: U`, (ii) une écriture par outil, passée par la décision finale, sur un fichier situé sous le dossier d'une unité de forme modèle — typiquement le `CADRAGE.md` ou le `PLAN.md`; `unite_de_fichier` (`planning-hook.sh:1801-1815`) exige un NOM de fichier précis, il faut donc une fonction voisine `unite_de_chemin` qui applique la même validation des 5 ou 7 premiers composants sans exiger le nom `[ASSUMED: à écrire]` —, et seulement si la liste déclarée est non vide, le moteur : (a) réconcilie chaque fichier déclaré, (b) ajoute à son journal une ligne `ouverture  unite=U  sha256=<constaté>`, (c) crée le repère `.unites/<clé-unité>` en création exclusive (idempotence ; un repère absent après un échec fait recommencer, une seconde ligne `ouverture` ne fait que déplacer l'ouverture plus tard, jamais imputer davantage). Aucun événement nouveau (P47-D-11) : les deux déclencheurs sont des `PreToolUse` déjà câblés.

*Attribution à une unité U, à l'écriture de son `CLOTURE.md`* (`evaluer_g2p`, fonction pure, appelée comme `evaluer_g3` sur `unite_de_fichier(composants, "CLOTURE.md")`) : pour chaque fichier déclaré D, soit `L` son journal, `i` l'indice de la **dernière** ligne `ouverture` de U, `apres = L[i+1:]` et `sha` l'empreinte courante :
1. pas de ligne `ouverture` de U → **D n'est pas jugé** pour U (jamais un refus sur une référence que le moteur n'a pas posée ; une ligne d'observation `g2p-sans-reference` est journalisée) ;
2. `contournement(D)` ⇔ une ligne `contournement` dans `apres`, ou `"contournement" in decider_baux(L, sha)` (changement non encore constaté) ;
3. `couvert(D, U)` ⇔ une ligne `prise` dont `unite == U` dans `apres` (la prise **est** la déclaration : « baux détenus par l'unité » de P47-D-04, et l'amendement a posteriori de P47-D-04) ;
4. D est **imputé** à U ⇔ `contournement(D) et non couvert(D, U)`. Un seul D imputé → `Verdict("G2P", chemin_rel_du_CLOTURE, raison)` avec la liste des fichiers imputés et le geste à faire (demande de prise avec `unite: U` et une `raison`).

*Les deux clauses de P47-D-04a* : « couvert par la génération d'un autre détenteur → non imputé » = une écriture par outil d'un autre détenteur passe le gate `BAIL` donc laisse une `intention`, et celle de l'outil écrivain laisse une `reference` : aucun `contournement`, rien à imputer. « Personne n'a couvert (Bash, cron) → refusé » = une écriture qui n'a traversé ni le hook ni l'outil laisse le sha différent de la dernière référence sans intention : `contournement`, imputé à toute unité ouverte avant lui et qui n'a pas pris le fichier.

*Amendement* (P47-D-04) = une **prise** de D par l'unité, demandée avec `unite: U` et une `raison` réelle. Quand la prise tombe alors qu'un `contournement` non couvert pèse sur U, la demande **exige** la `raison` (même règle de non-placeholder que `deroger-gate.sh:282`, `raison_placeholder`) ; sans raison la demande est refusée (verdict `BAIL`). La prise supersède le détenteur courant (c'est le comportement voulu de P47-D-02, à ne pas atténuer). Le `meta` de la génération porte `origine=amendement` et la raison : tracé, durable, relisible.

*Règle miroir au recalcul* (détection au mieux d'une clôture écrite par `Bash`, **P47-D-19**, Willy, AskUserQuestion session principale, 2026-10-12) : dans `_r1_a_r8`, entre R4 (livrables présents) et R5, pour une unité qui a un `CLOTURE.md` (quel que soit `SUMMARY.md` : `CLOTURE.md`, `VERDICT.md` et `SUMMARY.md` peuvent tous être écrits par `Bash`) et une liste déclarée non vide : pour chaque fichier déclaré dont le journal porte une `ouverture` de l'unité, `imputer(lignes_de_periode(L, U, True) + les lignes que decider_baux(L, sha) écrirait, sha, U)` en LECTURE SEULE (le recalcul n'écrit jamais le journal : `decider_baux` est pure, c'est l'appelant qui ajoute) → état `indéterminé`, raison `bail-hors-perimetre:<chemin>` `[ASSUMED: libellé proposé]`. La garantie « jamais clos en silence » est celle de l'écriture par outil (G2′ en `PreToolUse` sur `CLOTURE.md`, période sans sceau) ; le miroir signale ce que le journal du moteur montre, sans prétention de complétude contre `Bash` : « clôture hors outil » est une limite nommée, régime P45-D-10. Le journal est lu sous les mêmes bornes que le hook (`lire_empreintes`, prise partagée non bloquante du verrou du fichier). La signature de cache (`signature_unite`) ne contient ni le journal ni le fichier déclaré : l'unité est exclue du cache quand la règle s'applique (le plus simple, à mesurer).

**Cas limites et limite d'attribution (à écrire dans la référence, une limite lettrée chacune) :**
1. *Le moteur attribue à une période, pas à un auteur* : un `Bash` ou un cron sans l'outil n'a pas d'identité ; son changement est imputé à **toutes** les unités ouvertes avant lui qui n'ont pas pris le fichier. Deux unités ouvertes se bloquent donc mutuellement sur le même changement jusqu'à l'amendement de chacune (faux refus assumé, levé par un geste tracé).
2. *La prise vaut déclaration pour toute la durée de l'unité* : une écriture `Bash` faite après la prise de U n'est pas imputée, même si un autre détenteur a pris le fichier entre-temps (« bail ≠ contrôle d'écriture de `Bash` », spec §6.4).
3. *Une intention explique un seul changement* (limite (ay) reprise) : un `Bash` qui s'intercale entre l'intention d'un détenteur et son observation est absorbé (faux accept nommé). Une intention dont l'écriture a échoué (refus de permission) explique à tort un `Bash` ultérieur.
4. *Journal forgeable par `Bash`* (limite (bn) reprise) : écrire une ligne `reference` à jour efface un contournement. `Write`/`Edit` y sont refusés (G6 en profondeur), `Bash` non ; la réconciliation du `SessionStart` de D1 ne voit pas ce fichier (il n'est pas dans sa liste).
5. *Aller-retour A → B → A* entre deux observations : invisible (empreintes égales).
6. *Unité jamais vue du moteur avant sa clôture* (aucun contact) : pas de référence, pas de verdict (observation `g2p-sans-reference`), au gate comme au recalcul. Pas de réouverture : une unité rouverte (`à corriger`) garde sa première ouverture. **Période et sceau (P47-D-04a, simplifié par P47-D-19)** : le sceau est une ligne `cloture` posée UNE fois par ouverture, au premier contact du moteur qui voit le triplet complet (`CLOTURE.md`, `VERDICT.md`, `SUMMARY.md`, trois `lstat`, aucune empreinte) ; il est la borne de la période pour le recalcul. La fonction `lignes_de_periode(lignes, unite, bornee_au_sceau)` retire du journal les lignes `cloture` de l'unité pour le gate de `CLOTURE.md` et la demande de prise (`bornee_au_sceau` faux) : un changement écrit pendant un cycle `à corriger`, après un sceau, est donc refusé à l'écriture par outil d'une nouvelle clôture. Le recalcul l'appelle avec `bornee_au_sceau` vrai : un changement écrit après le sceau, y compris pendant un retravail écrit par `Bash`, n'est pas vu (limite « clôture hors outil »). *Remplacé* : le sceau par clôture finale à empreinte de triplet (`par=cloture-<F16>`, tour 5) est retiré, il ne servait que la complétude contre `Bash`.
7. *Fichier déclaré après l'ouverture de l'unité* : pas de ligne `ouverture` pour lui ; le gate ne le juge pas pour cette unité (observation `g2p-sans-reference`) et le recalcul non plus (aucune raison : l'inventaire de départ et la raison `bail-sans-ouverture:` sont retirés par P47-D-19), limite « clôture hors outil ». *Fichier supprimé, créé, devenu lien* : `empreinte_fichier` rend `absent` pour un non-régulier (D1) → un changement ; *fichier au-delà de la borne d'octets* : pas de ligne, pas de verdict, observation.
8. *Opérations de VCS* (`git checkout`, `merge`) qui réécrivent un fichier déclaré pendant l'unité : `contournement` légitime, amendement requis (faux refus attendu, mesuré).
9. *Lecture du journal bornée* à `BORNE_LECTURE_FICHIER` (1 Mio) par fichier ; une ligne `ouverture` hors fenêtre = référence absente (cas 6).

**Banc de G2′ (faux refus ET faux accept, chaque cas a son jumeau `-dev` non adhérent qui doit se taire) :**

| Id | Scénario (unité U ouverte, D déclaré) | Attendu | Classe | Mutant qui doit le tuer |
|----|----------------------------------------|---------|--------|--------------------------|
| G01 | D inchangé | passe | doit-passer | — (témoin) |
| G02 | D réécrit par l'outil du détenteur U, deux écritures successives avec `Bash` absent | passe | doit-passer (faux refus si rouge) | `MUT-G2P-INTENTION` (intention non posée) |
| G03 | D réécrit par `Bash`, U n'a pas pris D | refuse | doit-refuser | `MUT-G2P-IMPUTATION` (jamais imputer) |
| G04 | G03 puis prise de D par U avec raison | passe | doit-passer | `MUT-G2P-PRISE` (prise de U ignorée) |
| G05 | D changé par `Bash` AVANT le premier contact de U, puis ouverture de U | passe | doit-passer | `MUT-G2P-RECONCILE-OUVERTURE` (ouverture sans réconciliation préalable) |
| G06 | D réécrit par l'outil écrivain d'un cron (`hors-session:x`) pendant U | passe | doit-passer | `MUT-G2P-REFERENCE-OUTIL` |
| G07 | D réécrit par l'outil d'un autre détenteur V (autre unité) pendant U | passe | doit-passer | idem G02 |
| G08 | `Bash` change D ; U1 prend D, U2 non | U1 passe, U2 refuse | doit-passer / doit-refuser | `MUT-G2P-UNITE` (la prise d'une autre unité couvre) |
| G09 | amendement avec raison `TODO`, vide, ellipse | demande refusée, aucune génération créée | doit-refuser | `MUT-G2P-RAISON` |
| G10 | `contournement` APRÈS la prise de U | passe (limite 2) | limite nommée, comptée à part | — |
| G11 | liste déclarée absente, `[]`, non-liste | silence | silence | `MUT-G2P-LISTE-VIDE` |
| G12 | aucune ligne `ouverture` pour U | passe + observation `g2p-sans-reference` | doit-passer | `MUT-G2P-REFERENCE-ABSENTE` (refuser) |
| G13 | `CLOTURE.md` de forme non modèle (niveau cycle, style GSD) | silence | silence | — |
| G14 | D créé / supprimé / remplacé par un lien par `Bash` | refuse | doit-refuser | `MUT-G2P-ABSENT` |
| G15 | aller-retour A → B → A | passe | limite nommée | — |
| G16 | `Bash` entre l'intention et l'observation | passe | limite nommée (ay) | — |
| G17 | journal forgé par `Bash` | passe | limite nommée (bn) | — |
| G18 | clôture écrite par `Bash`, contournement non couvert | recalcul : `indéterminé`, raison `bail-hors-perimetre:` | miroir | `MUT-G2P-MIROIR` |
| G19 | `recalc-planning.sh --read-only` sur G18 | arbre du lab octet pour octet identique avant/après | doit-passer | `MUT-G2P-RECALC-ECRIT` |
| G20 | dérogation nominative `G2P` sur le chemin de `CLOTURE.md` | passe une fois, consommée | doit-passer | patron `consommer` |
| G21 | fichier déclaré au-delà de la borne d'octets | passe + observation | doit-passer | — |
| G22 | lab non adhérent / sortie vide | silence, octet vide | silence | `MUT-ADHESION-IGNOREE` |
| G23 | `observe` : même contournement | passe + ligne d'observation | doit-passer | `MUT-G2P-ARMEMENT` |

### R-2 — P47-D-01a : le geste de prise reconnu par le hook

**Verdict : la recommandation du manager est faisable, à cinq conditions que le code ne remplit pas aujourd'hui.** Forme retenue : un `Write` (jamais `Edit` ni `NotebookEdit`) d'un fichier de demande **à nom unique** `.planning/baux/demandes/<nom>.md`, `<nom>` validé par `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$` `[ASSUMED: motif proposé]`, dont le frontmatter (lu par `lire_frontmatter`, déjà dans le hook) porte `fichier:` (obligatoire, doit être **égal** à une entrée déclarée, comparaison NFC), `unite:` (optionnel, chemin d'unité de forme modèle) et `raison:` (obligatoire pour un amendement). Le contenu est lu dans `tool_input.content` du payload (patron `adhesion_conservee`, `planning-hook.sh:1687-1695`), jamais sur le disque.

1. **G6 doit être étendu en profondeur — il ne l'est pas.** `fichier_protege` exige `a_la_racine` (`:1596`) et `PROTEGES_G6` ne nomme que cinq fichiers générés, deux journaux et `config.json` (`:1552-1557`). Aujourd'hui `Write` sur `.planning/baux/<clé>/gen-9/meta` **passe** `[VERIFIED: lecture de fichier_protege et evaluer_g6]`. Il faut une fonction de protection du sous-arbre `<planning>/baux/` (résolution `realpath`, comparaison `casefold` et NFC des composants, `samefile` pour un lien dur existant, patron de `_lien_dur_vers_verdict` borné) qui refuse `Write`/`Edit`/`NotebookEdit` sur tout le sous-arbre **sauf** le motif exact des demandes et, pour les demandes, `Write` seul. Corollaire de livraison : G6 est **armé** depuis l'étape 1, donc cette protection est armée dès la livraison alors que `BAIL` et `G2P` sont en observation (aucune régression attendue : personne n'écrit sous `baux/` aujourd'hui, il est réservé et non parcouru, `modele-cycles.md:279,296-303`).
2. **L'effet se produit après la décision finale, dans `main`, à côté de `inscrire_intentions` (`:3528`)**, jamais dans `evaluer_*` : un juge (`ROLE`), un chemin refusé par G7 ou une dérogation non consommable ne doit pas produire de prise. Patron : la dérogation n'est consommée que si la décision finale est un passage (`:1476-1484`). L'effet **re-dérive** la demande avec la même fonction de validation que le gate (une seule implémentation) ; les gates restent purs.
3. **Fail-closed en `armed`, fail-open en `observe`** : une prise qui échoue (E/S, saturation) refuse la demande en `armed` (l'agent ne doit pas croire qu'il détient) ; en `observe` l'erreur est journalisée (`observer`) et ne refuse jamais (une phase en observation ne peut pas produire un `deny`). L'état laissé par un échec partiel est sûr (génération sans `meta` complet = détenue par personne, P47-D-02b).
4. **Le hook doit lire `session_id`** (aujourd'hui 0 occurrence) et fabriquer l'identité `agent:<agent_id>` (non vide) sinon `session:<session_id>` ; sans l'un ni l'autre, le gate refuse (fail-closed) et l'effet n'a pas lieu. Le cœur ne lit toujours **aucune variable d'environnement** (R-ENV-02) : l'identité vient du payload seul. `[CITED: 47-RECHERCHE-BAUX.md R1.1, R1.4]` : sous-agent → `agent_id` présent ; `session_id` du sous-agent = celui du parent (non documenté) ; fil principal → `agent_id` absent.
5. **La réponse à l'agent passe par `additionalContext`** (`sortie_contexte`, `:1184-1188`, déjà utilisé par G2 et les citations de dérogation) : « bail de `<fichier>` pris : génération `<n>`, détenteur `<identité>` » ou « prise dépassée aussitôt par la génération `<m>` » ; le `Write` de la demande passe (allow). Constat de cette session : le `additionalContext` d'un `PreToolUse` est bien remis au modèle `[VERIFIED: observé cette session, les avis « WORKFLOW ADVISORY » d'un hook PreToolUse apparaissent dans les résultats d'outil]`.

*Pourquoi un nom unique par demande* : l'agent ne peut pas calculer la clé (un hachage) ; un chemin fixe écrasé à chaque demande retomberait sur la règle du harnais « lire avant d'écraser un fichier existant », assouplie seulement depuis 2.1.228 sur les modèles récents `[CITED: 47-RECHERCHE-BAUX.md R2]` ; des noms uniques sont toujours des créations. Les fichiers de demande s'accumulent (le dossier est ignoré par git et hors modèle) : borne et nettoyage à décider (Open Questions).

*Rejetés* : (b) un geste `Bash` reconnu par analyse de la commande — l'analyse d'un shell est le maillon faible (citations, composition, expansion), et `Bash` n'est de toute façon pas gardé (P45-D-10) ; (c) un refus « de succès » (le hook refuse la demande en rendant le résultat dans le motif) — un `deny` qui est un succès brouille le canary (qui distingue le mode dégradé d'un refus légitime) et les mesures de faux refus ; (d) `updatedInput` — exige `allow`/`ask` et réécrit l'appel (P47-D-01 l'a écarté). Une extension ultérieure peut ajouter la prise par `Bash` avec l'identité du payload (elle donnerait à un script de sous-agent sa vraie identité), hors périmètre.

*Protection de la liste de `config.json`* (BAIL-04) : `evaluer_g6` applique à `config.json` la seule règle `adhesion_conservee` (planning_version) ; elle doit devenir « l'adhésion **et** la liste déclarée sont conservées » (comparer la liste du contenu proposé à celle du contenu courant, lu par `lire_octets_bornes`). Un `Write`/`Edit` qui change la liste est refusé (dérogation nominative `G6` sur `.planning/config.json` possible, mécanisme existant) ; le premier remplissage de la liste est donc un geste humain ou de la Phase 50. Clé proposée : `fichiers_sous_bail` (liste de chaînes) `[ASSUMED: nom proposé]`, chaque entrée validée par `entree_ecrit_valide` (`planning-hook.sh:734-750`) plus : composants ≤ 255 octets UTF-8, pas un nom protégé de G6, pas un doublon après NFC et `casefold`, au plus 64 entrées ; une entrée invalide est ignorée avec une ligne d'observation (limite nommée), une structure invalide vaut liste vide.

### R-3 — P47-D-02a : clé du chemin, comparaison NFC, bornes de nom

**Clé = `sha256` hexadécimal de `NFC(chemin déclaré relatif à la racine du lab)` encodé UTF-8 (64 caractères `[0-9a-f]`).** Le chemin en clair, le nom brut tel que déclaré et la clé sont recopiés dans le `meta` ; **chaque lecture vérifie** `sha256(NFC(meta.chemin)) == nom du dossier` et `meta.chemin ==` le chemin demandé : un écart rend la génération incomplète (donc « détenue par personne »). L'injectivité est ainsi **vérifiée à la lecture**, pas supposée (une injection exacte est impossible sous 255 octets pour un chemin pouvant atteindre `BORNE_VALEUR = 4096`).

Preuves de ce que la clé évite (sondes de cette session, APFS, Darwin 25.5.0) `[VERIFIED: sondes locales, scratchpad de la session]` :
- *Normalisation* : un fichier créé sous la forme NFD (`e` + U+0301) est listé en NFD, et retrouvé sous le nom NFC (`os.path.exists` vrai, `samefile` vrai) — APFS préserve la forme et ignore la normalisation à la recherche. Un nom de dossier dérivé du chemin brut aurait donc deux formes pour un seul fichier ; une clé calculée **après** NFC n'en a qu'une et ne contient que de l'ASCII (aucune E/S ne dépend plus de la forme).
- *Casse* : APFS est insensible à la casse (`Abc.json` retrouvé sous `abc.json`) ; sous ext4 deux casses sont deux fichiers. La clé suit le chemin **déclaré** ; pour décider qu'un chemin écrit par un outil EST le fichier déclaré, comparer par `os.path.samefile` quand les deux existent, sinon composant par composant en NFC puis `casefold` (patron `fichier_protege`, `_meme_dossier`) — sur-protection assumée (faux refus rare) sur un système sensible à la casse, jamais un faux accept.
- *Longueur* : 255 octets acceptés, 256 → `ENAMETOOLONG` ; avec des caractères de 3 octets, 85 caractères (255 octets) passent **et 86 (258 octets) aussi** : la limite d'APFS compte des caractères, celle d'ext4 des octets `[ASSUMED: ext4 = 255 octets, non sondé ici]`. Borne portable à imposer aux entrées déclarées : chaque composant ≤ 255 **octets** UTF-8, chemin total ≤ 4096.
- *L'encodage pourcent existant ne convient pas tel quel* : `_jeton_journal` (`planning-hook.sh:1219-1266`) échappe `%`, `=`, les espaces et les caractères non imprimables, **pas `/`** ; son résultat contient donc un séparateur de chemin, et son expansion (jusqu'à `%XX` par octet) dépasse 255 sur un chemin moyen.

*Même fonction pour la clé d'unité* du repère `.unites/<clé-unité>`. *Nom de génération* : `gen-<n>`, `n` entier décimal, motif strict `^gen-([0-9]{1,12})$`, tout autre nom ignoré. *E/S sur les fichiers déclarés* : la chaîne déclarée telle que saisie, jointe à la racine du lab (sur APFS NFC et NFD désignent le même fichier ; sur ext4 la forme saisie fait foi : c'est le lab qui répond de sa déclaration).

## Standard Stack

### Core
| Brique | Version | Purpose | Why Standard |
|--------|---------|---------|--------------|
| Python 3, bibliothèque standard (`os`, `fcntl`, `hashlib`, `json`, `re`, `unicodedata`, `urllib.parse`, `tempfile`) | 3.9+ à tenir (le `python3` système du poste est 3.9.6, le poste de dev 3.14.5) | registre, journal, prise, verrou, hachage | déjà le moteur du hook, du recalcul, de `poser-verdict.sh`, de `dag.sh` ; `[VERIFIED: python3 --version → 3.14.5 ; /usr/bin/python3 --version → 3.9.6, cette session]` |
| bash 3.2 / POSIX `sh` | `/bin/bash` du poste (version non sondée : la garde d'isolation refuse `bash --version`) | lanceurs, suites | contrainte de la maison : ni `declare -A`, ni `mapfile`, ni `timeout`, ni `sed -i`, ni `diff` (proxifié), `cmp -s`/`comm` |
| `fcntl.flock` | stdlib | verrou consultatif libéré par le noyau à la mort du processus | seule primitive commune macOS / Linux : `flock(1)` est **absent de macOS** (`command -v flock` rend vide, `command -v lockf` rend `/usr/bin/lockf`, cette session) `[VERIFIED]` |
| `os.mkdir` / `os.link` / `os.replace` | stdlib | prise exclusive / publication exclusive / remplacement atomique | `os.replace` atomique sur POSIX `[CITED: docs.python.org/3.9/library/os.html]` ; `mkstemp` crée un fichier lisible et inscriptible par son créateur seul `[CITED: docs.python.org/3.9/library/tempfile.html]` |

### Supporting
Aucune. Aucun module partagé : l'installeur ne pose que des `*.sh` (en-tête de `planning-hook.sh`, bloc des empreintes), donc le code commun est **copié et comparé** (patron R-EMP-04), pas importé.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `fcntl.flock` | `flock(1)` / `lockf(1)` | absents ou divergents entre macOS et Linux ; l'outil écrivain serait deux scripts |
| prise `mkdir` + relecture | `ln -s` + `-h` (patron `driver-lock.sh`) | `ln -sh` tenté en premier (`driver-lock.sh:170-171`) est le piège uutils déjà documenté ; P47-D-14 le laisse hors 47 |
| journal d'empreintes dans le registre | D1 (`surveillance.log`) étendu aux fichiers déclarés | D1 est dans la zone réécrite par la 46.1 et ne connaît que `.planning/` (R-1) |
| clé = hachage | encodage pourcent | `/` non échappé, expansion > 255 octets (R-3) |

**Installation :** aucune (stdlib). **Version verification :** `python3 --version` (3.14.5), `/usr/bin/python3 --version` (3.9.6).

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase (bibliothèque standard Python, shell, `fcntl`). Rien à auditer ; aucun `npm`/`pip`/`cargo`. **Packages removed due to SLOP :** none. **Packages flagged SUS :** none.

## Architecture Patterns

### System Architecture Diagram

```
 Agent (fil principal ou sous-agent)                       Script / cron (hors session)
   │ Write / Edit / NotebookEdit                              │ baux.sh prendre | ecrire   (identité déclarée)
   ▼                                                          ▼
 PreToolUse ──► planning-hook.sh (cœur Python, 8 s)          flock(<clé>/verrou) ─► relire le registre
   payload : tool_name, file_path, content, cwd,              │ ma génération est la plus haute ?
             agent_id | session_id                            │   non → repli : rien écrit, trace, code ≠ 0
   │                                                          │   oui → réconcilier ─► temporaire + os.replace ─► ligne reference
   ├─ lab non adhérent cycles-v1 ? ─ oui → silence, code 0
   ├─ evaluer_gates  (gates purs : aucune écriture)
   │     G6   fichiers générés, config.json (adhésion ET liste déclarée), sous-arbre baux/ sauf demandes/*.md
   │     BAIL chemin ∈ liste déclarée ? ─► registre(clé) ─► (aucune génération | plus haute incomplète | détenteur ≠ appelant) ─► refus
   │     G2P  CLOTURE.md d'unité ─► journal(F) pour chaque F déclaré ─► imputation ─► refus
   │     (G1 G5 G7 ROLE G3 G4 G4P inchangés)  ─► decider : deny | observation | dérogation consommée
   ├─ refus ? ─► sortie_refus (JSON deny, code 0, jamais exit 2)
   └─ aucun refus ─► effets_baux  (armed : fail-closed ; observe : fail-open + observation)
          ├─ demande de prise ─► réconcilier ─► [ouvrir l'unité] ─► mkdir gen-<n+1> ─► meta (création exclusive) ─► relecture ─► ligne prise
          ├─ écriture d'un fichier déclaré par son détenteur ─► réconcilier ─► ligne intention
          └─ 1er contact d'une unité ─► réconcilier chaque F ─► ligne ouverture ─► repère .unites/<clé>
        puis inscrire_intentions (D1, inchangé), puis avis éventuel (additionalContext)

 recalc-planning.sh (écriture) ─ flock(descripteur de .planning/) ─ scanner ─► dériver (+ miroir G2′) ─► INDEX « Bail en cours », cloture.log, STATE
 dag.sh (add | mark | reopen | init) ─ flock(descripteur du dossier du DAG) ─ load ─► muter ─► mkstemp ─► os.replace ─► relâcher
```

### Recommended Project Structure (tout sous `plugin/planning-core/` sauf mention) `[ASSUMED: noms proposés]`
```
scripts/planning-hook.sh        # + bloc « Baux » (identité, liste, registre, journal, evaluer_bail, evaluer_g2p, effets_baux, protection de baux/)
scripts/baux.sh                 # NEUF : outil côté écrivain (prendre | verifier | ecrire | lister) — copie ast-identique du bloc registre
scripts/recalc-planning.sh      # + verrou d'écriture, colonne « Bail en cours », règle miroir de G2′ (lecture seule du bloc registre)
scripts/{check-gates-alive,rejeu-gates,rejeu-reel,deroger-gate}.sh   # étape 7, canaris BAIL et G2P, jeton de gate
scripts/tests/test-baux-registre.sh      # NEUF : clé, prise, concurrence 24 × 5, outil écrivain, copies ast-identiques, mutants
scripts/tests/test-bail-gate.sh          # NEUF : gate BAIL, geste de prise, G6 en profondeur, liste de config, banc B01-B24
scripts/tests/test-g2prime.sh            # NEUF : journal d'empreintes, ouverture, imputation, amendement, miroir, banc G01-G23
references/modele-cycles.md              # registre, gates, outil, usage cron, limites, tableau d'armement (étape 7)
plugin/conductor/scripts/dag.sh + tests/test-dag.sh      # BAIL-07 (T50 et suivants)
```

### Pattern 1 : prise générationnelle (BAIL-01, 02)
**What :** `n` = plus haute génération visible (`^gen-([0-9]{1,12})$`) ; `os.mkdir(gen-(n+1), 0o700)` ; `FileExistsError` → relire `n` et recommencer (borne 64, puis saturation = erreur bruyante) ; publier le `meta` **en création exclusive d'un contenu complet** (écrire `meta.tmp-<pid>`, puis `os.link` vers `meta` — `EEXIST` si un autre l'a posé —, retirer le temporaire ; repli `os.open(O_CREAT|O_EXCL)` si le système de fichiers refuse `link`) ; **relire le disque** : la génération gagnante doit être la nôtre ET son `meta` doit nous nommer ; sinon recommencer (jamais le seul code de sortie, spec §6.1). Un `meta` n'est « complet » que s'il se termine par `fin=1`, que `numero` égale le suffixe du dossier, que `cle` égale le nom du dossier parent et que `chemin` se re-hache vers `cle`.
**When :** toute prise (demande reconnue par le hook, `baux.sh prendre`, amendement).
**Pourquoi la publication exclusive** (prototype, voir « Concurrence ») : avec `os.replace` un second écrivain ÉCRASE le `meta` d'un premier et sa relecture passe ; avec `link` il échoue bruyamment.

### Pattern 2 : le gate `BAIL` (BAIL-03), fonction pure dans l'entonnoir
Entrée : outil dans `OUTILS_ECRITURE`, `contexte["ecrit"]` non vide. 1) liste déclarée (vide ou absente → `[]`) ; 2) le chemin écrit est-il un des fichiers déclarés (`samefile`, sinon NFC + `casefold` par composants) ? non → `[]` (au fichier près : un dossier parent, un préfixe, un glob ne déclenchent rien) ; 3) identité de l'appelant (`agent:<agent_id>` sinon `session:<session_id>`, sinon refus « identité absente ») ; 4) registre de la clé : aucune génération → refus ; plus haute incomplète → refus ; détenteur ≠ appelant → refus qui nomme le détenteur et sa génération ; 5) sinon `[]`. Messages sans chemin absolu ni « no such file » / « can't open » (`FRAGMENTS_INTERDITS_SORTIE`, `planning-hook.sh:127`). Verdict `BAIL` sur le chemin déclaré (dérogation nominative `--gate=BAIL`, usage unique, par `decider`). Fail-closed : `evaluer_protege` rend un verdict d'erreur sur toute exception.

### Pattern 3 : effets du hook après la décision finale
Une seule fonction `effets_baux(payload, cibles)` appelée dans `main` juste avant `inscrire_intentions` (`:3528`), jamais quand `refus` est non vide. Ordre : ouverture d'unité éventuelle → demande de prise → intention d'écriture sur fichier déclaré (pour **toute** écriture par outil d'un fichier déclaré qui traverse la décision finale : en `armed` seul le détenteur passe ; en `observe` un non-détenteur passe aussi et son écriture, vue du moteur, est tout de même « expliquée »). Sans liste déclarée, aucun de ces effets n'a lieu (aucun fichier créé dans un lab qui n'a rien déclaré). En `armed` toute exception remonte (le `except BaseException` de `main` rend un `deny`) ; en `observe` elle est capturée et journalisée par `observer`.

### Pattern 4 : un seul bloc, plusieurs copies ast-identiques
Le bloc « registre + journal » (clé, lecture/écriture du `meta`, `prendre`, journal, `decider_baux`, `reconcilier_fichier`, hachage borné d'un fichier déclaré, lecture de la liste) est écrit **une fois** et copié dans le hook, `baux.sh` et `recalc-planning.sh` (lecture seule côté recalcul si le planificateur le préfère : un sous-ensemble nommé). Une suite le compare par arbres de syntaxe (modèle : `NOMS_BLOC`, R-EMP-04, `test-cloture-empreintes.sh:963-968,1030-1058`) et rougit à la moindre divergence. Les fonctions qui lisent l'**environnement** (`CLAUDE_CODE_SESSION_ID`) restent hors du bloc : le cœur du hook n'en lit aucune (R-ENV-02, en-tête de `planning-hook.sh`).

### Pattern 5 : section critique de l'outil écrivain (BAIL-05)
Sous `flock(<clé>/verrou)` : (1) relire le registre : ma génération est-elle la plus haute et complète ? non → repli (rien écrit, ligne de trace, code propre ≠ 0) ; (2) réconcilier le journal ; (3) écrire le nouveau contenu dans un temporaire du **même dossier** que le fichier, droits copiés de l'existant (`mkstemp` crée en 0600), `os.replace` (refuser si la cible est un lien) ; (4) ajouter la ligne `reference` avec l'empreinte des octets écrits ; relâcher. La vérification est faite **au moment d'écrire**, sous le verrou, jamais au réveil (spec §6.3). Identité : `--identite=hors-session:<label>` pour un cron, sinon `session:$CLAUDE_CODE_SESSION_ID`, sinon refus. Codes proposés `[ASSUMED]` : 0 écrit ; 64 usage ; 73 dépassé (repli) ; 74 verrou indisponible (pas de `fcntl`) ; 1 échec d'E/S.

### Pattern 6 : `dag.sh` (BAIL-07)
`fcntl.flock` exclusif sur le **descripteur du dossier** du DAG (jamais remplacé, aucun fichier parasite à ignorer par git, `.planning/missions/` n'a pas à recevoir un `.lock`) pris avant `load()` pour `init`, `add`, `mark`, `reopen`, relâché après `save()` et **avant** les appels best-effort de `mark` (`check_stall_signal`, `record_progress`, `record_milestone`, jusqu'à 2 s chacun). `save()` : cible `os.path.realpath(file)` (ne pas remplacer un lien par un fichier), droits de l'existant (0644 par défaut, `mkstemp` donne 0600), temporaire `mkstemp` dans le même dossier, `os.replace`, suppression du temporaire en cas d'erreur. Lecteurs (`ready`, `status`, `tree`) : aucun verrou nécessaire, `os.replace` suffit à supprimer la lecture déchirée. Sans `fcntl` (Windows) : dégradation silencieuse nommée en limite.

### Pattern 7 : recalcul sérialisé (BAIL-08)
Dans `main` de `recalc-planning.sh`, **chemin d'écriture seulement** : après les refus d'adhésion et de détection GSD (`:2452-2471`), `flock(LOCK_EX)` sur le descripteur du dossier de planning (refusé s'il est un lien, comme `appliquer_ecritures`), puis seulement `scanner` et la dérivation. Aujourd'hui `scanner` s'exécute AVANT (`:2422`) : il faut le déplacer sous le verrou pour le chemin d'écriture (la lecture seule garde l'ordre actuel), sinon une dérivation périmée pourrait écraser `INDEX.md` d'un recalcul plus récent. Le dédoublonnage de `cloture.log` (`lire_journal` → `lignes_a_journaliser` → `ajouter_au_journal`) tombe ainsi sous le verrou. **Ordre des verrous** (écrit en référence) : verrou du dossier de planning, puis `surveillance.log` ; verrou de `<clé>/verrou`, puis `empreintes.log` ; jamais l'inverse. Colonne « Bail en cours » : pour chaque cycle ouvert, les fichiers déclarés dont la plus haute génération complète porte une `unite` sous ce cycle, rendus `<chemin>#<n>` triés, séparés par `, ` ; `aucun` sinon — **octet pour octet identique à aujourd'hui quand `baux/` est absent** (aucun horodatage dans la colonne : sinon `INDEX.md` serait réécrit à chaque recalcul).

### Anti-Patterns to Avoid
- **Jeton dans le contenu écrit ou dans un argument** (forgeable par recopie) : écarté par P47-D-01.
- **Poser une référence sans réconcilier d'abord** : blanchit un changement de `Bash` (prise, ouverture, outil, constatation).
- **Verrouiller un fichier que `os.replace` remplace** : le suivant verrouille un autre inode ; la 46.1 le relève pour son compteur (`46.1-PATTERNS.md` P-06, analogue 4). Verrouiller un descripteur de dossier ou un fichier `verrou` stable.
- **Mutant équivalent** : retirer la relecture après la prise ne change rien dans une tempête pure (voir « Concurrence ») ; le mutant doit être exercé avec une injection de défaut, sinon il survit.
- **Un `deny` qui sert de canal de succès** pour le geste de prise (brouille le canary et les mesures de faux refus).
- **Une écriture dans une fonction `evaluer_*`** (les gates sont rejoués par le recalcul, le rejeu et le banc : ils restent purs).
- **Étendre D1** pour les fichiers déclarés : zone de la 46.1, fenêtre de 4 Mio, hors `.planning/`.

## Concurrence : preuves rejouées pendant la recherche

Prototypes dans le scratchpad de la session (non versionnés ; le planificateur les réimplémente), exécutés sur macOS APFS, Python 3.14.5 `[VERIFIED: sorties ci-dessous, cette session]`.

| Expérience | Sortie (verbatim) | Lecture |
|------------|-------------------|---------|
| 24 preneurs concurrents, algorithme nominal (`mkdir` + `link` + relecture), délai aléatoire injecté entre la lecture de `n` et le `mkdir` | `N=24 succes=24 echecs_bruyants=0 gens=24 contigu=True retours_distincts=True FAUX_SUCCES=0 plus_haute=24 detenteur=id12` | 24 générations contiguës, chaque retour correspond au `meta` du disque |
| même tempête, mutant `os.makedirs(exist_ok=True)` | `N=24 succes=24 echecs_bruyants=0 gens=4 contigu=True retours_distincts=False FAUX_SUCCES=20 plus_haute=4 detenteur=id20` | **rouge** : 20 faux succès |
| même tempête, `mkdir` « fantôme » injecté (rend sans rien créer, une fois sur deux), algorithme nominal | `N=24 succes=12 echecs_bruyants=12 gens=12 contigu=True retours_distincts=True FAUX_SUCCES=0 plus_haute=12 detenteur=id10` | fail-closed : les preneurs fantômes échouent bruyamment |
| tempête pure, mutant « sans relecture » | `N=24 succes=24 echecs_bruyants=0 gens=24 contigu=True retours_distincts=True FAUX_SUCCES=0 …` | **mutant équivalent** : il survit sans injection de défaut |
| `mkdir` fantôme + mutant « sans relecture » | `N=24 succes=24 echecs_bruyants=0 gens=12 contigu=True retours_distincts=False FAUX_SUCCES=12 …` | **rouge** : la relecture est ce qui rend le fantôme visible |
| première version du prototype : `meta` publié par `os.replace` (pas `link`), `mkdir` fantôme, relecture présente | `N=24 succes=24 echecs_bruyants=0 gens=12 contigu=True retours_distincts=False FAUX_SUCCES=12 plus_haute=12 detenteur=id12` | publier par `replace` laisse un second preneur ÉCRASER le `meta` d'un premier ; sa relecture passe, la victime a déjà rendu « succès » → publication exclusive obligatoire |

Conséquences pour les plans : l'assertion de la tempête est **contiguïté (1..N sans trou), retours distincts, aucun faux succès, et un seul des N identités passe le gate à la fin** (la plus haute) — pas « un seul gagnant » au sens de `driver-lock.sh` (T13/T32 comptent des `acquired: true`, ce qui n'a pas de sens pour des générations). Patron de test : 24 processus × 5 rondes (T13/T32), lancés par `subprocess.Popen` ou `&`+`wait`, délai injecté dans une COPIE modifiée du code (patron de `R-VERDICT-08`, `test-planning-gates.sh:4568-4601` : `copie_modifiee` + `lota_mutant` avec marqueur de commentaire unique par branche).

**`dag.sh` : le défaut est reproduit, le correctif aussi.** Tempête de `dag.sh add` concurrents sur un DAG neuf, lecteur concurrent qui parse le fichier en boucle :

| Cible | Sortie (verbatim) |
|-------|-------------------|
| `dag.sh` actuel, 16 écrivains | `N=16 noeuds_finaux=14 perdus=2 codes_nonnuls=1 lectures=2209 lectures_dechirees=38` (une autre ronde : `perdus=0 … lectures_dechirees=48`) |
| `dag.sh` actuel, 40 écrivains | `N=40 noeuds_finaux=36 perdus=4 codes_nonnuls=1 lectures=1613 lectures_dechirees=108` |
| copie corrigée (flock sur le dossier, `mkstemp` + `os.replace`), 16 écrivains | `N=16 noeuds_finaux=16 perdus=0 codes_nonnuls=0 lectures=1893 lectures_dechirees=0` |
| copie corrigée, 40 écrivains | `N=40 noeuds_finaux=40 perdus=0 codes_nonnuls=0 lectures=1584 lectures_dechirees=0` |

La perte est probabiliste (une ronde de 16 en perd 0), la lecture déchirée presque certaine : le test T50 doit donc (a) rejouer plusieurs rondes ET (b) rendre la perte déterministe par une injection de délai entre `load()` et `save()` (graine de test inerte par défaut, patron `VF_DRIVER_TEST_DIE_AFTER_MUTEX` de `test-driver-lock.sh` T41b, ou copie modifiée) ; les mutants `# dag-verrou` (retrait du verrou) et `# dag-atomique` (retour à `open(file, "w")`) doivent rougir chacun pour sa raison. Baseline à ne pas régresser : `bash plugin/conductor/scripts/tests/test-dag.sh` → `Résultats : 161 PASS / 0 FAIL`.

**Verrou sur un descripteur de dossier** : `fcntl.flock` sur `os.open(dossier, O_RDONLY)` fonctionne sur macOS et rend `EAGAIN` en cas de contention non bloquante `[VERIFIED: sonde locale]` ; sur Linux, `flock(1)` « lock[s] a specified file or directory » `[CITED: man7.org/linux/man-pages/man1/flock.1.html]` ; le comportement du noyau Linux sous la CI n'est pas rejoué ici `[ASSUMED]` → c'est la CI de la PR qui le prouve (les suites tournent sur ubuntu).

**Fenêtres résiduelles, à écrire en limites** : `PreToolUse` → écriture (le processus du hook finit avant l'outil ; ni verrou tenu ni compare-and-swap natif de `Write`/`Edit` `[CITED: 47-RECHERCHE-BAUX.md R2]`) ; un script qui n'utilise pas l'outil ; Windows sans `fcntl` (le hook garde `fcntl = None`, `planning-hook.sh:100-103` : la prise par `mkdir` reste atomique, les journaux et verrous ne le sont plus) ; l'identité d'un script lancé par un sous-agent est celle de la session parente (`session:<id>`) : il ne peut pas écrire sous le bail pris par `agent:<id>` et inversement — ping-pong possible, jamais de faux accept.

## Zone partagée avec la 46.1 (P47-D-10) : fonctions, pas lignes

La 46.1 est planifiée (dix plans, dossier `VFDO-46.1-armement-de-g4-et-g4/`) et s'exécute **avant** la 47 ; ses plans ont été lus en lecture seule. Les numéros de ligne ci-dessous sont ceux de `78808126` et ne sont donnés que pour retrouver la fonction.

| Fonction / objet | La 47 y touche | La 46.1 la réécrit | Point d'insertion fragile |
|------------------|----------------|--------------------|----------------------------|
| bloc `ARMEMENT_*`, `ORDRE_ETAPES`, `TABLE_ARMEMENT` | + `ARMEMENT_BAIL`, `ARMEMENT_G2P`, étape 7 | passe `ARMEMENT_G4`, `ARMEMENT_G4P` à `armed` | mêmes lignes : conflit textuel certain, résolution triviale ; **relire les valeurs livrées** avant d'écrire `TABLE_ATTENDUE` |
| `armement_valide` | + `G2P armé ⇒ BAIL armé` (scission 7a/7b), étape 7 exige l'étape 6 entière | aucune | l'étape 7 est inarmable si G4′ ne l'est pas : si la porte humaine de la 46.1 refuse, la 47 livre en observation seulement |
| `evaluer_gates` | texte du refus de table incohérente (liste des étapes) | aucune | texte à étendre avec l'étape 7 |
| `GATES_A_VERDICT` | + `("BAIL", evaluer_bail)`, `("G2P", evaluer_g2p)` | aucune | une ligne : conflit mineur |
| `evaluer_g6`, `adhesion_conservee`, `fichier_protege` | protection du sous-arbre `baux/`, liste de `config.json` | ajoute une entrée à `PROTEGES_G6` et un genre à `raison_g6` pour le compteur G4′ | `PROTEGES_G6` (littéral à plusieurs lignes) et `raison_g6` : fusion à la main |
| `SCRIPTS_HOOK_G6` | + l'outil écrivain `baux.sh` | peut y ajouter son script de décision (`46.1-PATTERNS.md` P-09) | tuple d'une ligne |
| `main` (branche `PreToolUse`) | + appel de `effets_baux` avant `inscrire_intentions` | réécrit la sélection du lab (A3, `sys.argv[5]`), `cibles`, `depart_evenement` | **le plus fragile** : l'appel doit rester sur le chemin « aucun refus » et réutiliser les mêmes `cibles` ; le lanceur et les positions d'arguments changent |
| `inscrire_intentions`, `inscrire_surveillance`, `_jeton_journal`, bloc des empreintes, `decider`, `consommer`, `observer` | appelées ou imitées, **non modifiées** | `inscrire_surveillance` et `_jeton_journal` : non modifiées non plus (« toute retouche suit dans tous les fichiers ») | — |
| D1 : `reconcilier`, `decider_trace`, `tracer_changement`, `chemins_surveilles`, `FICHIERS_RACINE_SURVEILLES`, `mode_*` | **non touchées** (journal séparé sous `baux/`) | N-5 et A5 | c'est le bénéfice du choix de R-1 : la 47 sort de cette zone |
| `evaluer_g4`, `evaluer_g4p`, `mode_subagent_stop`, `resoudre_agent`, `evaluer_role` | non | oui | — |
| `recalc-planning.sh` : `NOMS_MODELE_RACINE_FICHIERS` | non (le verrou n'ajoute aucun fichier) | + le fichier du compteur | aucun conflit |
| `recalc-planning.sh` : `main`, `rendre_index`, `_r1_a_r8`, `signature_unite` | oui | non | cache : signature à étendre ou unité exclue du cache |
| `check-gates-alive.sh` : `GATES`, `CANARIS`, `lire_armement`, `Rejeu` | + deux gates, deux cas | + cas séquentiel A4, mode d'environnement `CLAUDE_PROJECT_DIR`, `COMMANDE_REFERENCE` | `CANARIS` et la répartition `attendu_de` ; la commande enregistrée n'est pas touchée par la 47 |
| `rejeu-gates.sh` : `GATES`, `ORDRE_ETAPES`, `ETAPE_DE`, `armer_copie`, bornes `--etape`, constructeurs | étape 7 et constructeurs `BAIL`/`G2P` | `construire_g4p`, `g4()`, planchers | constantes `ETAPE_G3G4, ETAPE_G4P = 5, 6` : ajouter une constante d'étape 7 |
| `rejeu-reel.sh` : liste `1..6` | → `1..7` (usage, message, en-tête) | non | — |
| suites : `TABLE_ATTENDUE`, `ORDRE_ATTENDU`, `LIMITES_REFERENCE`, expressions `ARMEMENT_(?:…)` | oui | oui (valeurs, limites) | voir « Armement » ; lettres de limites : attribuer après lecture de la référence livrée par la 46.1 (la dernière lettre de la 46 est (bu) ; `bc` et `bd` sont sautées par convention) |
| `modele-cycles.md`, spec §5, `VERSION`/`module.json`/`CHANGELOG.md`/README du module | oui (v2.12.0, §5 G2′, §5.1-2, §6.1, §6.2, §6.4) | oui (v2.11.0, §5 G4/G4′) | numéros de version à relire sur la branche livrée ; paragraphes de spec distincts |

**Points de re-validation avant exécution (plan-checker frais) :** valeurs `ARMEMENT_G4`/`ARMEMENT_G4P` livrées ; position de `main` et forme de `cibles` ; nom et protection du fichier d'état du compteur G4′ (`g4p-etat.log` dans `46.1-09-PLAN.md`, verrou pris sur `.planning/config.json` : **à ne pas copier** pour les baux, un `Write` sur `config.json` peut le remplacer) ; contenu de `COMMANDE_REFERENCE` ; lettres de limites ; version de `planning-core` ; compte de suites des README racine.

## Armement : les lieux qui recopient la liste des gates (à étendre dans le commit qui ajoute les constantes)

Deux constantes de plus font passer le compte des lignes `ARMEMENT_*` de 8 à 10. Les expressions des copies « découplées » (Q-ARM : les suites forcent tout à `observe` sur une copie) énumèrent les gates en dur ; **non étendues, elles retrouvent 8 correspondances, passent leur contrôle `n != 8`, et laissent `ARMEMENT_BAIL`/`ARMEMENT_G2P` à la valeur livrée** — la table ne devient incohérente qu'à l'armement de l'étape 7, où tout est alors refusé. Relevé de cette session `[VERIFIED: grep des suites]` :

| Lieu | Lignes à étendre |
|------|------------------|
| `planning-hook.sh` | constantes `:133-144`, `armement_valide` `:551-573`, texte de `evaluer_gates` `:2790-2792`, `GATES_A_VERDICT` `:2774` |
| `check-gates-alive.sh` | `GATES` `:195`, `CANARIS`, `lire_armement`, `lire_canaris` |
| `rejeu-gates.sh` / `rejeu-reel.sh` | `GATES`, `ORDRE_ETAPES`, `ETAPE_DE` `:147-149`, `armer_copie` `:386-393`, bornes `--etape` `rejeu-gates.sh:1583,1596` et `rejeu-reel.sh:11-13,214-215` |
| `deroger-gate.sh` | `GATES` `:63`, usage `:7,67`, message `:291` |
| `test-planning-gates.sh` | `TABLE_ATTENDUE` `:169`, `ORDRE_ATTENDU` `:170`, `:250`, `:329` (`n != 8`), `:604`, `:3234` (motif `# etape-[1-6]` → `[1-7]`), `:3370` (`n != 8`), `:5451` |
| `test-d1-surveillance.sh` | `:218`, `:300` (`!= 8`) |
| `test-cloture-gates.sh` | `:267`, `:349` (`n != 8`) |
| `test-g4p-sortie-brute.sh` | `:190`, `:268`, `:792-793` |
| `test-juges-canary.sh` | `:189`, `:271` |
| `test-planning-hook-registered.sh` | `:224-226` |
| `test-rejeu-gates.sh` | `:162-163`, `:1501-1502` (+ `ARMES`) |
| `plugin/_internal/tests/test-planning-hook-installed.sh` | `armer_copie` `:876-884` (liste de gates passée en paramètre), sondes `mort_de` |
| `modele-cycles.md`, spec §5 | tableau d'armement, listes de gates, `LIMITES_REFERENCE` |

**Test de recensement à ajouter (Wave 0)** : « toute constante `ARMEMENT_<X>` du hook figure dans chacune des sept expressions des suites et dans `GATES` de `check-gates-alive.sh`, `rejeu-gates.sh`, `deroger-gate.sh` » — rouge tant qu'un lieu manque. Commande de vérification rouge aujourd'hui : voir « Validation Architecture ».

**Étape 7 et scission 7a/7b (P47-D-06, P47-D-06a)** : `ORDRE_ETAPES` prend `("BAIL", "G2P")` en dernier ; `armement_valide` gagne `G2P armé ⇒ BAIL armé` sur le patron de `armement-g3-g4` (`:562-563`). Recommandation : **scinder dès la livraison** — 7a `BAIL` (gate d'écriture, banc B01-B24, lab sans liste = silence), 7b `G2P` (dépend du journal d'empreintes, plancher de couverture plus bas). Les labs réels n'ont aucun fichier déclaré avant la Phase 50 : le rejeu réel de l'étape 7 mesure surtout l'**absence d'effet** (empreintes d'arbre identiques, 0 faux refus) et des cas synthétiques injectés (liste simulée dans la copie, unités `7x-*`) ; le plancher `COUVERTURE-REJEU` pour `BAIL`/`G2P` est à fixer au plan (valeur `[ASSUMED]`). Rien n'est armé sans le checkpoint humain du moment d'agir.

## Découpage en plans et vagues (quatorze plans, régénéré depuis les `47-NN-PLAN.md` le 2026-10-12)

> Le découpage initial recommandé par ce document (douze plans) est remplacé : le plan de contrôle a scindé l'ancien 47-07 (G2′) en trois plans chaînés et renuméroté en continu. La source de vérité est le frontmatter des plans ; ce tableau en est dérivé.

| Vague | Plan | Contenu | Exigences |
|-------|------|---------|-----------|
| 1 | 47-01 | bloc « registre + journal » (clé, `meta`, prise, relecture, journal, `decider_baux`, `imputer`), outil côté écrivain `baux.sh`, suite `test-baux-registre.sh` (tempête de prise 24 × 5, tempête de l'écrivain, mutants tracés, ast-identité) ; scinder si l'exécution dérive | BAIL-01, BAIL-05 |
| 1 | 47-02 | `dag.sh` (un verrou par site, `os.replace`, droits, lien), T50 à T52, mutants par site, bump `conductor`, fiche BACKLOG close, texte « pourquoi le jeton ne le couvre pas » | BAIL-07 |
| 1 | 47-03 | étape 7 d'armement (`BAIL`, `G2P`) en observation, recensement par ensembles des lieux de recopie, scission 7a/7b | BAIL-09 |
| 2 | 47-04 | recalcul : verrou d'écriture, `scanner` sous verrou, tempête de 8 recalculs, colonne « Bail en cours » | BAIL-08 |
| 2 | 47-05 | hook : identité (`session_id`), demande de prise, liste de `config.json` + sa protection, G6 en profondeur sur `baux/`, `evaluer_bail` (branche demande), `effets_baux` ; scinder si l'exécution dérive | BAIL-02, BAIL-04 |
| 3 | 47-06 | hook : gate d'écriture de `evaluer_bail`, banc B01-B24, mutants | BAIL-03, BAIL-10 |
| 4 | 47-07 | G2′ de base : `evaluer_g2p`, ouverture d'unité idempotente posée par le moteur, intention | BAIL-06 |
| 5 | 47-08 | G2′ côté hook : amendement, budget de hachage cumulé, sceau du triplet complet posé une fois par ouverture, période du gate jusqu'à la clôture qui s'écrit, banc G01-G34, mutants du hook | BAIL-06 |
| 6 | 47-09 | G2′ au recalcul : règle miroir R4bis en détection au mieux (P47-D-19 ; indépendante de `SUMMARY.md`, période bornée au sceau), lecture du journal sous verrou partagé, budget du miroir, deux codes de raison, résidus affichés, mutants du recalcul | BAIL-06 |
| 7 | 47-10 | canaris `BAIL`/`G2P`, `rejeu-*` (borne 7, `LISTE-REELLE`), planchers ; tout en `observe` | BAIL-09, BAIL-10 |
| 8 | 47-11 | référence (`modele-cycles.md`), spec §5/§5.1-2/§6.1 à §6.4, limites lettrées, trio des copies du bloc, zéro régression | BAIL-10 |
| 8 | 47-12 | `planning-core` v2.12.0 sans release, fiches BACKLOG (`onFailure`, `driver-lock.sh`), ROADMAP vérifiée en lecture seule | BAIL-10 |
| 9 | 47-13 | **checkpoint humain** : rejeu réel en lecture seule étape 7a, puis armement de `BAIL` si 0/0 et liste réelle | BAIL-09 |
| 10 | 47-14 | **checkpoint humain** : rejeu 7b, armement de `G2P` | BAIL-09 |

47-01, 47-02 et 47-03 sont indépendants (47-01 et 47-03 sont couplés par lecture seulement : `coupling_justified` dans 47-01) ; 47-04 et 47-05 consomment le bloc de 47-01 ; 47-05, 47-06, 47-07 et 47-08 touchent le même fichier (`planning-hook.sh`) : séquencés par `depends_on`. Chaque plan qui touche la zone partagée la déclare (P47-D-10) et cite la **fonction**. Deux outils de contrôle partagés vivent dans le dossier de la phase : `47-LIGNES-REQUISES.sh` (lignes requises par identifiant entier) et `47-CONTROLE-MARQUEUR-CHEMIN.sh` (marqueur `Gate-Touche:` par chemin).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Refus / observation / dérogation / erreur interne | un second chemin de décision | `Verdict`, `evaluer_protege`, `decider` | consommation « seulement si la décision finale passe » (`planning-hook.sh:1476-1484`), observation journalisée, deny sur erreur : déjà prouvés |
| Encodage de valeurs dans une ligne de journal ou un `meta` | un échappement local | `_jeton_journal` (copie ast-identique) | pourcent injectif, anti-injection de ligne (mais **pas** pour un nom de dossier : `/` n'est pas échappé) |
| Lecture / réconciliation d'une empreinte | un hachage ad hoc | `empreinte_fichier` (D1 : `lstat`, non-régulier = `absent`, `O_NOFOLLOW`, borne d'octets) | fichier supprimé, lien, tube, énorme : cas déjà traités |
| Lecture bornée d'un fichier du lab | `open().read()` | `lire_octets_bornes` (1 Mio) | A11 : aucune lecture d'un fichier contrôlé par l'agent sans borne |
| Liste de chemins déclarés | un validateur local | `entree_ecrit_valide` (copie à 4 exemplaires) + bornes de composant | pas de `..`, `~`, glob, contrôle |
| Raison d'amendement | un contrôle ad hoc | la règle `raison_placeholder` de `deroger-gate.sh:282` (copie à comparer) | vide, TODO, xxx, ellipse refusés après NFKC |
| Identité d'un chemin | une comparaison de chaînes | `composants_nfc`, `_meme_dossier` / `samefile`, `casefold` | APFS insensible à la casse et à la normalisation |
| Tempête de concurrence, mutant, canary, rejeu | un script ponctuel | patron `R-VERDICT-08` (`copie_modifiee`, `lota_mutant`), `make_hook_mutant`, `check-gates-alive.sh`, `rejeu-gates.sh` | « un gate supposé est un gate absent » (spec §5.1-2) |

**Key insight :** chaque brique a déjà son patron dans la 45 ou la 46 ; le risque n'est pas la logique du bail, c'est un lieu de copie oublié (une quinzaine de lieux d'armement, trois copies du bloc, deux numéros de version).

## Runtime State Inventory

Phase additive : rien à renommer ni à migrer. Inventaire de l'état d'exécution **créé** :

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.planning/baux/` n'existe nulle part aujourd'hui (emplacement réservé et non parcouru : `NOMS_MODELE_RACINE_DOSSIERS`, `recalc-planning.sh:765`) ; la clé `fichiers_sous_bail` de `config.json` est nouvelle | aucune migration ; labs sans la clé : aucun effet |
| Live service config | crons et scripts métier d'un lab (`com.bfl.*`, `PIPELINE_STATE.json`) : **non touchés** (P47 hors-périmètre) ; la phase livre l'outil et sa doc | aucune |
| OS-registered state | aucun hook nouveau : la commande enregistrée n'est pas réécrite (P47-D-11) | aucune |
| Secrets/env vars | `CLAUDE_CODE_SESSION_ID` lu par l'outil écrivain seulement ; aucune variable ne change une décision du cœur du hook | aucune |
| Build artifacts | copies du hook et de l'outil sous `<lab>/.claude/scripts/` (installeur, glob `*.sh`) | `/vf-update` ; G6 protège ces copies ; ajouter l'outil à `SCRIPTS_HOOK_G6` |

## Common Pitfalls

### Pitfall 1 : dérive silencieuse du compte des constantes d'armement
**What goes wrong :** les suites « découplées » (Q-ARM) forcent `ARMEMENT_*` à `observe` sur une copie par une expression qui énumère huit gates. Avec dix constantes, `re.subn` en trouve toujours 8 : aucun contrôle ne rougit, `BAIL`/`G2P` restent à leur valeur livrée, et au premier armement de l'étape 7 la table devient incohérente (G4′ `observe`, étape 7 `armed`) : **tout** est refusé.
**How to avoid :** étendre les ~vingt lignes du tableau « Armement » dans le commit qui ajoute les constantes ; ajouter le test de recensement (toute constante `ARMEMENT_*` figure dans chaque expression et dans les `GATES` des trois scripts).
**Warning signs :** une suite verte alors que `grep -c '^ARMEMENT_'` rend 10 et que son expression en nomme 8.

### Pitfall 2 : `mkstemp` crée en 0600, `os.replace` change l'inode
**What goes wrong :** `dag.sh` corrigé naïvement passerait un DAG 0644 versionné en 0600, ou remplacerait un lien symbolique par un fichier. Le dépôt connaît déjà le premier piège (`os.fchmod(fd_tmp, 0o644)`, `recalc-planning.sh:2131`).
**How to avoid :** `realpath` de la cible, droits de l'existant, temporaire dans le même dossier, nettoyage du temporaire en cas d'erreur ; cas de test « DAG 0644 reste 0644 », « DAG lien reste un lien ».

### Pitfall 3 : verrou posé sur un fichier que l'on remplace
Voir « Anti-Patterns ». **How to avoid :** verrouiller un descripteur de dossier (`dag.sh`, recalcul) ou un fichier `verrou` qui n'est jamais remplacé (registre).

### Pitfall 4 : mutant équivalent (la relecture)
Voir « Concurrence ». **How to avoid :** le mutant « sans relecture » n'est tué que par l'injection de défaut `mkdir fantôme` ; sans elle il survit et la suite se croit complète.

### Pitfall 5 : poser une référence sans réconcilier
Une prise, une ouverture d'unité, une écriture de l'outil ou une constatation qui pose `reference` sans appliquer d'abord `decider_baux` blanchit un changement de `Bash` qui l'a précédée. **Warning signs :** cas G05 (changement avant l'ouverture) qui rougit seulement sous le mutant `MUT-G2P-RECONCILE-OUVERTURE`.

### Pitfall 6 : la réconciliation ne doit pas avancer la référence quand rien n'a changé
Si deux hooks se croisent (le détenteur A passe le gate, B prend le bail, l'écriture de A atterrit après), avancer la référence à l'unique réconciliation de B ferait perdre l'`intention` de A : l'écriture tardive deviendrait un faux `contournement`. La règle « sha égal à la dernière référence → aucune ligne » (R-1) l'évite ; test dédié.

### Pitfall 7 : coût de hachage dans l'échéance du cœur
`ECHEANCE_COEUR_S = 8.0` (`planning-hook.sh:116`) ; passé ce délai le cœur sort en code 73 et la couche shell **ferme** dans un lab adhérent. Hacher plusieurs gros fichiers déclarés à chaque ouverture d'unité et à chaque clôture peut faire refuser toutes les écritures. **How to avoid :** réutiliser les bornes de D1 (`BORNE_OCTETS_LIVRABLES`, lecture par blocs), ajouter un budget d'octets total par invocation (valeur à mesurer, patron `46-COUT-PREFILTRE.md` ; ordre de grandeur de départ 64 Mio `[ASSUMED]`), au-delà : pas de ligne, pas de verdict, observation.

### Pitfall 8 : recensements statiques qui rougissent sur du code neuf
`RECENSEMENT_LECTURE` et `RECENSEMENT_READDIR` (`test-planning-gates.sh`, `46.1-PATTERNS.md` SP-6) exigent que tout nouvel appel de lecture ou d'énumération de dossier du hook soit inscrit avec sa borne **dans le même commit** ; `R-ENV-02` interdit toute lecture d'environnement par le cœur (l'identité vient du payload).

### Pitfall 9 : `agent_id` constant dans les banc et canaris
Les suites et le canary rejouent plusieurs événements avec le même `agent_id` (`"agent-test"`, `"canary-agent"`, `"rejeu-agent"` : `46.1-PATTERNS.md` P-06). Les cas du gate `BAIL` dépendent de l'identité : chaque cas, chaque processus d'une tempête, reçoit une identité dérivée du cas ; sinon un `doit-refuser` devient un `doit-passer` en silence.

### Pitfall 10 : sous-arbre `baux/` contenant un lien
`.planning/baux` (ou un de ses sous-dossiers) en lien symbolique ferait sortir `realpath` du sous-arbre protégé. Le registre refuse tout composant lien (`lstat` à chaque niveau, patron `inscrire_surveillance` : planning en lien → rien) et la protection de G6 couvre la forme physique **et** la forme écrite.

### Pitfall 11 : surface de `check-gate-touche.sh`
Toucher `plugin/conductor/scripts/tests/test-dag.sh` est dans la surface (« leurs suites : `plugin/conductor/scripts/tests/test-*.sh` ET `scripts/tests/test-*.sh` ») `[VERIFIED: check-gate-touche.sh, en-tête]` : un trailer `Gate-Touche: <chemin> — <raison ≥ 10 caractères>`, un chemin par trailer, sans virgule. `plugin/planning-core/**` n'y est pas, mais P47-D-16 impose le trailer sur le hook et ses suites par convention.

### Pitfall 12 : compteurs et gates de dépôt
`README.md` et `README.fr.md` : « N suites » (109 aujourd'hui) doit suivre chaque suite ajoutée ; l'en-tête `Version` du README de `planning-core` et de `conductor` doit suivre `VERSION` ; `check-machine-paths.sh` interdit `/Users/<nom>/` dans tout fichier versionné ; `check-planning-consumers-registered.sh` recense les `*.sh` hors `tests/` qui citent `.planning/` et `STATE.md|ROADMAP.md|REQUIREMENTS.md` sur une même ligne (l'outil écrivain n'en cite pas). **Aucun** changement de `VERSION` racine, `plugin.json`, `marketplace.json`, badges ni historique des README (pas de release, ADR-073).

### Pitfall 13 : budgets d'instructions
`check-instruction-budget.sh` ne mesure que les agents, les `SKILL.md` et les lignes de bootstrap (`name`/`description`/`when_to_use`) : la documentation d'usage va dans `references/modele-cycles.md`, **sans toucher** le frontmatter de `skills/planning-core/SKILL.md`. Le budget de BACKLOG (`check-method-budget.sh`, 20 sujets, 40 lignes par entrée) n'est pas dans la CI (`grep` de `ci.yml` : aucune occurrence) mais les deux nouvelles fiches (`onFailure`, `driver-lock.sh`) restent sous 40 lignes.

### Pitfall 14 : `Write` d'un fichier existant
Voir R-2 (noms de demande uniques).

## Code Examples

> Squelettes de CONCEPTION (Python 3.9), `[ASSUMED]` dans leurs noms et bornes ; ils s'appuient sur des fonctions existantes citées (`_jeton_journal`, `composants_nfc`, `empreinte_fichier`, `Verdict`, `lire_octets_bornes`). Le planificateur les adapte.

### Clé et identité
```python
def cle_bail(chemin_declare):
    """Clé stable d'un fichier déclaré : sha256 de sa forme NFC (R-3). ASCII seulement."""
    return hashlib.sha256(unicodedata.normalize("NFC", chemin_declare).encode("utf-8")).hexdigest()

def identite_appelant(payload):
    """agent_id non vide, sinon session_id ; None si aucun des deux (le gate refuse). Aucune lecture d'environnement."""
    aid, sid = payload.get("agent_id"), payload.get("session_id")
    if isinstance(aid, str) and aid != "":
        return "agent:" + aid
    if isinstance(sid, str) and sid != "":
        return "session:" + sid
    return None
```

### Prise (validée par le prototype, 24 preneurs)
```python
GEN = re.compile(r"^gen-([0-9]{1,12})$")

def plus_haute(rep_cle):
    n = 0
    for nom in os.listdir(rep_cle):          # à inscrire dans RECENSEMENT_READDIR
        m = GEN.match(nom)
        if m:
            n = max(n, int(m.group(1)))
    return n

def prendre(rep_cle, champs, moi):
    os.makedirs(rep_cle, mode=0o700, exist_ok=True)
    for _ in range(64):
        n = plus_haute(rep_cle)
        rep = os.path.join(rep_cle, "gen-%d" % (n + 1))
        try:
            os.mkdir(rep, 0o700)                       # exclusif : jamais makedirs(exist_ok=True)
        except FileExistsError:
            continue
        try:
            publier_exclusif(rep, "meta", rendre_meta(champs, n + 1))   # link, repli O_EXCL ; complet ou absent
        except OSError:
            continue                                   # jamais « succès » sans l'avoir FAIT
        lu = lire_meta(rep)
        if lu is None or lu["detenteur"] != moi:       # relecture du disque
            continue
        return n + 1                                   # l'appelant relit aussi « suis-je la plus haute ? »
    raise RuntimeError("saturation")
```

### Règle d'explication et imputation (fonctions pures)
```python
def decider_baux(lignes, sha):
    derniere = None
    for rang, l in enumerate(lignes):
        if l["genre"] == "reference":
            derniere = rang
    if derniere is None:
        return ["reference"]
    if lignes[derniere]["sha"] == sha:
        return []                                      # une intention antérieure reste en attente
    if any(l["genre"] == "intention" for l in lignes[derniere + 1:]):
        return ["reference"]
    return ["contournement", "reference"]

def impute(lignes, sha, unite):
    ouv = [i for i, l in enumerate(lignes) if l["genre"] == "ouverture" and l["unite"] == unite]
    if not ouv:
        return None                                    # pas de référence : non jugé (observation)
    apres = lignes[ouv[-1] + 1:]
    contourne = any(l["genre"] == "contournement" for l in apres) or "contournement" in decider_baux(lignes, sha)
    couvert = any(l["genre"] == "prise" and l["unite"] == unite for l in apres)
    return contourne and not couvert
```

### Gesture de prise (fichier de demande)
```
Write  .planning/baux/demandes/20261012-pipeline-1.md
---
fichier: pipeline/PIPELINE_STATE.json
unite: .planning/cycles/03-diagnostic/phases/02-livraison
raison: "mise à jour de l'état après l'import du 12/10"
---
```
Réponse du hook : `additionalContext` « [planning-core] BAIL : bail de pipeline/PIPELINE_STATE.json pris — génération 4, détenteur agent:… ».

### Usage par un cron (hors session)
```
bash .claude/scripts/baux.sh ecrire --fichier=pipeline/PIPELINE_STATE.json --source=/tmp/etat-neuf.json --identite=hors-session:pipeline-sync
# code 0 : écrit ; code 73 : sa génération est dépassée, rien n'a été écrit (à journaliser, ne pas relancer en boucle)
```

### `dag.sh` : verrou et écriture atomique
```python
def verrouiller():
    if fcntl is None or _VERROU[0] is not None:
        return
    dossier = os.path.dirname(os.path.abspath(file)) or "."
    fd = os.open(dossier, os.O_RDONLY)
    fcntl.flock(fd, fcntl.LOCK_EX)                     # marqueur # dag-verrou
    _VERROU[0] = fd

def save(dag):
    cible = os.path.realpath(file)
    dossier = os.path.dirname(cible) or "."
    try:
        mode = os.stat(cible).st_mode & 0o7777
    except OSError:
        mode = 0o644
    fd, tmp = tempfile.mkstemp(dir=dossier, prefix=".dag-", suffix=".tmp")
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(dag, fh, indent=2, ensure_ascii=False); fh.write("\n")
        os.replace(tmp, cible)                         # marqueur # dag-atomique
    except BaseException:
        try: os.unlink(tmp)
        except OSError: pass
        raise
    deverrouiller()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bail `mkdir` + suppression pour récupérer (v1) | bail générationnel : `mkdir gen-<n+1>`, jamais effacé, dépassé (spec §6.1) | spec du 2026-09-22 | 5 gagnants simultanés mesurés sur l'ancien patron |
| Jeton présenté par l'agent | registre lu par le hook, lié à l'identité du payload | P47-D-01, 2026-10-12 | rien à recopier, rien à forger par `Write`/`Edit` |
| `TaskCompleted` pour G2′ | `PreToolUse` sur `CLOTURE.md` + règle miroir | P46-D-01 / P47-D-04 | `TaskCompleted` absent par défaut sur les modèles récents `[CITED: 47-RECHERCHE-BAUX.md R4]` |
| `PreToolUse` fail-open sans réglage (spec §5.1-2) | `onFailure: "block"` réglable depuis Claude Code 2.1.295 | 2026-10 | **hors 47** (P47-D-07) : fiche BACKLOG, spec annotée |
| `Edit`/`Write` sans garde de relecture | `Edit` applicable à un fichier modifié depuis sa lecture (2.1.208), `Write` sur un fichier jamais lu (2.1.228) | 2.1.208, 2.1.228 | aucun compare-and-swap natif : la fenêtre `PreToolUse` → écriture reste ouverte |

**Deprecated/outdated :** `.planning/BACKLOG.md:74` (référence de la ROADMAP, périmée : la fiche est à `:169`) ; la prémisse « même `TaskCompleted` que G3/G4 » de la ligne `Depends on` du ROADMAP §47.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `fcntl.flock` sur un descripteur de dossier se comporte comme sur macOS (verrou exclusif, `EAGAIN` en non bloquant) sous le noyau Linux de la CI | Concurrence, Pattern 6 et 7 | `dag.sh` et le recalcul retomberaient sur un verrou inopérant ; la CI de la PR le prouve (les suites de concurrence y tournent) ; repli : fichier `verrou` stable |
| A2 | Limite de nom ext4 = 255 **octets** (APFS compte des caractères : sondé) | R-3 | la clé de 64 caractères est sans risque ; seule la borne imposée aux composants déclarés serait à ajuster |
| A3 | `/bin/bash` du poste est 3.2 (non sondé : la garde d'isolation refuse `bash --version`) | Standard Stack | une syntaxe bash ≥ 4 passerait en CI et casserait sur le poste |
| A4 | `os.link` est disponible sur le système de fichiers du lab ; sinon `O_CREAT|O_EXCL` | Pattern 1 | publication du `meta` possible dans les deux cas ; un seul des deux chemins est testé si la CI n'a pas de FS sans `link` |
| A5 | Un budget de hachage de ~64 Mio par invocation tient dans l'échéance de 8 s | Pitfall 7 | refus de toutes les écritures (code 73) sur un lab à gros fichiers déclarés ; à mesurer (patron `46-COUT-PREFILTRE.md`) |
| A6 | Un `Write` vers un chemin neuf (nom unique) ne déclenche jamais la règle « lire avant d'écraser » | R-2 | geste de prise intermittent sur certains modèles ; repli : nom unique + `Read` d'un fichier vide |
| A7 | `session_id` d'un sous-agent = celui du parent (jamais documenté) | R-2, Pattern 5 | si le sous-agent avait son propre `session_id`, l'identité d'un script de sous-agent serait encore plus ambiguë ; la décision « agent_id d'abord » reste correcte |
| A8 | Noms proposés : `baux.sh`, `fichiers_sous_bail`, `empreintes.log`, `demandes/`, `.unites/`, `verrou`, libellés `bail-hors-perimetre:`, `g2p-sans-reference` | partout | aucun (renommage libre, une seule implémentation partagée) |
| A9 | Codes de sortie de l'outil écrivain : 0, 1, 64, 73, 74 | Pattern 5 | aucun (à figer au plan) |
| A10 | La CI utilise le `python3` système d'ubuntu (3.12) ; le code reste compatible 3.9 | Standard Stack | aucun si 3.9 tenu |
| A11 | `conductor` : bump de niveau **patch** (durcissement, `CLAUDE.md` « Numérotation »), numéro à recalculer sur `origin/main` au moment d'exécuter (v1.48.2 au 2026-10-12, contre v1.46.0 sur cette branche) | BAIL-07 | renumérotation à refaire à la fusion ; garde-fou du jalon déjà prévu |
| A12 | Planchers `COUVERTURE-REJEU` pour `BAIL` et `G2P` à fixer au plan (les labs réels n'ont aucun fichier déclaré) | Armement | armement sur une couverture trop faible |

## Open Questions (RESOLVED)

> Toutes tranchées au plan (décisions de plan renversables par le manager ou Willy) : Q1 -> 47-01/47-05 ; Q2 -> limite nommée (47-11) ; Q3 -> 47-07 à 47-09 ; Q4 -> 47-03/47-10/47-13/47-14 ; Q5 -> limite nommée (47-11) ; Q6 -> limite nommée + geste humain (47-11) ; Q7 -> 47-01 ; Q8 -> 47-04.

1. **Ignorer `baux/` par git ?**
   - Known : l'état est local (comme `surveillance.log`) ; `poser_gitignore_planning` ne pose qu'une ligne et `R-D1-20` l'exige (étendre casserait cette suite).
   - Unclear : commit ou non du registre dans un lab partagé.
   - Recommendation : un `.planning/baux/.gitignore` (`*` puis `!.gitignore`) écrit par le moteur à la première prise ; aucune retouche de `poser_gitignore_planning`.
2. **Borne et nettoyage de `demandes/`.**
   - Known : un nom unique par demande accumule des fichiers de quelques centaines d'octets.
   - Recommendation : pas de nettoyage automatique en 47 (jamais effacer, esprit du bail) ; le recalcul peut compter les demandes et en dire le nombre ; limite nommée.
3. **Unité sans ligne `ouverture` à sa clôture : silence + observation (recommandé) ou refus ?** Silence : on ne refuse pas sur une référence que le moteur n'a jamais posée (précédent : G1 sur état illisible, F5). Décision du manager à annoncer, renversable. **Arbitrage P47-D-19 (Willy, AskUserQuestion session principale, 2026-10-12)** : le gate reste silencieux (observation `g2p-sans-reference`) et le recalcul aussi ; la reconstruction de l'antériorité d'une unité sans ouverture (inventaire de départ, exemption par empreinte du triplet, raison `bail-sans-ouverture:`) a été essayée sur six tours de plan-check et retirée : chaque correction ouvrait une nouvelle brèche, parce que `Bash` peut réécrire l'historique (P45-D-10). Le résidu est une limite nommée, affichée par la suite (`LIMITE G2P-CLOTURE-HORS-OUTIL cas=sans-ouverture`, 47-09) et lettrée en 47-11.
4. **Scission 7a/7b dès la livraison.** Recommandé (BAIL puis G2P), P47-D-06a l'autorise.
5. **Identité d'un script lancé par un sous-agent.** Limite acceptée (P47-D-12) ; extension possible : geste de prise par `Bash` reconnu par le hook avec l'identité du payload, hors périmètre.
6. **Premier remplissage de `fichiers_sous_bail`.** G6 refuse qu'un outil change la liste ; geste humain ou dérogation nominative `G6` sur `.planning/config.json` ; remplissage systématique par la grille de la Phase 50.
7. **L'outil écrivain doit-il refuser quand le fichier a dérivé** (sha ≠ dernière référence) ? Recommandé : réconcilier et tracer (`contournement`), **ne pas refuser** (le refus appartient à G2′, pas à l'écrivain).
8. **Colonne « Bail en cours » : bails hors cycle** (unité `-`, cron) : non affichés par cycle ; une ligne de pied de tableau optionnelle. À trancher au plan 47-04.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | hook, outil, recalcul, suites | ✓ | 3.14.5 (poste) ; `/usr/bin/python3` 3.9.6 | `python` (ADR-054) |
| bash | suites, lanceurs | ✓ | `/bin/bash` (3.2 supposé, non sondé) | — |
| zsh | shell de l'outil Bash du poste | ✓ | 5.9 (relevé 46) | — |
| dash / sh | pré-filtre, propriété (C) | ✓ | `/bin/dash` | — |
| `flock(1)` | — (non utilisé) | ✗ sur macOS | — | `fcntl.flock` (Python) |
| `lockf(1)` | — (non utilisé) | ✓ `/usr/bin/lockf` | — | idem |
| `fcntl` | verrous | ✓ POSIX, ✗ Windows | — | dégradation nommée (limite) |
| Linux / conteneur | preuve de A1 | non disponible ici | — | la CI Linux de la PR (geste de Willy) |
| `claude -p` | — | **interdit** (P47-D-15) | — | aucune sonde |

**Missing dependencies with no fallback :** aucune. **Missing with fallback :** Linux local (la CI prouve).
**Contraintes de shell pour les exécuteurs :** `bash <suite>`, jamais sourcée sous zsh ; sous zsh `$var` n'est pas découpé (boucles `for x in a b c` littérales, ou `commande | while IFS= read -r x`) ; bash 3.2 : ni `declare -A`, ni `mapfile`, ni `[[ -v ]]` ; BSD/macOS : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f`, ni `grep -P`, `diff` proxifié (`cmp -s`, `comm`) ; CI : jamais de `commande && { … }` nu ; Python 3.9 (pas de `match`, pas de `X | Y`). La garde d'isolation du worktree refuse certaines formes de commande (`bash --version`, boucles à valeur calculée mêlées à du shell) : lancer des commandes simples depuis la racine du worktree.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash `*/tests/test-*.sh` du dépôt avec sections Python embarquées (`ok`/`ko`, assertion · attendu · obtenu, jumeaux négatifs, mutants à motif de commentaire unique tués pour LEUR raison) |
| Config file | aucune ; découverte CI par `find plugin scripts -type f -path '*/tests/test-*.sh'` puis `bash "$t"` `[VERIFIED: ci.yml:218]` |
| Quick run command | `bash plugin/planning-core/scripts/tests/test-baux-registre.sh` (suite neuve, visée < 120 s `[ASSUMED]`) ; sections ciblables par une variable `VF_BAUX_SECTIONS` (patron `VF_CLOT_SECTIONS`, `VF_D1_SECTIONS`) |
| Full suite command | le bloc « Découverte complète » ci-dessous (forme valable sous zsh ET bash ; `test-planning-prefilter.sh` dépasse 600 s sous charge : par sections) |
| Baselines (relevées cette session) | `bash plugin/conductor/scripts/tests/test-dag.sh` → `Résultats : 161 PASS / 0 FAIL` ; `VF_GATES_SECTIONS=table,reference bash plugin/planning-core/scripts/tests/test-planning-gates.sh` → `== Résultat : 22 OK · 0 KO ==` (2 s) ; `bash scripts/check-version-sync.sh` → `README.md suites 109` ; `bash scripts/check-machine-paths.sh` → `1963 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |

Découverte complète (reprend `ci.yml:218`, sans `$(…)` non guillemeté qui ne se découpe pas sous zsh) :
```
find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done
```

### Phase Requirements → Test Map
Toujours `bash <suite>` (le Bash outil du poste est zsh, la CI lance `bash "$t"`). « Peut rougir » = la preuve que la commande échoue quand la propriété est fausse.

| Req ID | Behavior | Test Type | Automated Command | Peut rougir (preuve) | File Exists? |
|--------|----------|-----------|-------------------|----------------------|-------------|
| BAIL-01 | clé NFC/NFD/casse, prise, tempête 24 × 5 (contiguïté, 0 faux succès, 1 identité passe), `meta` incomplet = personne, publication exclusive | unitaire + concurrence + mutation | `bash plugin/planning-core/scripts/tests/test-baux-registre.sh` | mutants `MUT-BAUX-MAKEDIRS` (observé : `FAUX_SUCCES=20`), `MUT-BAUX-RELECTURE` + injection `mkdir fantôme` (observé : `FAUX_SUCCES=12`), `MUT-BAUX-REPLACE` (écrasement du `meta`), `MUT-BAUX-CLE` (clé sans NFC) | ❌ Wave 0 |
| BAIL-02 | identité = `agent_id` sinon `session_id` ; prise seulement après décision finale ; `meta` hors de portée de `Write`/`Edit` | banc + intégration | `bash plugin/planning-core/scripts/tests/test-bail-gate.sh` | `MUT-BAIL-IDENTITE` (session seule), `MUT-BAIL-EFFET-AVANT-DECISION` (prise malgré un `deny` de ROLE), `MUT-G6-BAUX` (sous-arbre non protégé) | ❌ Wave 0 |
| BAIL-03 | gate `BAIL` : B01-B24 (aucune génération, détenteur ≠ appelant, sous-agent frère, session revenue **et** session non reprise, `meta` incomplet, fichier/préfixe/glob, alias de casse et NFD, Edit/NotebookEdit, Bash silence, `observe`, lab dev silence) | banc avec jumeaux `-dev` | idem | `MUT-BAIL-DETENTEUR`, `MUT-BAIL-INCOMPLET`, `MUT-BAIL-SAMEFILE`, `MUT-BAIL-PREFIXE`, `MUT-ADHESION-IGNOREE` | ❌ Wave 0 |
| BAIL-04 | liste dans `config.json` : exacte, protégée (Write/Edit qui la change → refus, qui la conserve → passe, dérogation), absente/vide/mal formée → rien jugé | unitaire + banc | idem | `MUT-LISTE-G6` (liste non protégée), `MUT-LISTE-PREFIXE` | ❌ Wave 0 |
| BAIL-05 | outil écrivain : section critique, repli du dépassé, droits, lien refusé, identité hors-session, cron simulé qui se réveille après une reprise | unitaire + concurrence | `bash plugin/planning-core/scripts/tests/test-baux-registre.sh` (section outil) | `MUT-OUTIL-VERIF-AU-REVEIL` (vérifie avant le verrou), `MUT-OUTIL-SANS-VERROU`, `MUT-OUTIL-TRUNCATION` | ❌ Wave 0 |
| BAIL-06 | G2′ : G01-G23, ouverture après réconciliation, amendement avec raison, miroir du recalcul (détection au mieux, résidus affichés), lecture seule sans écriture | banc + mutation | `bash plugin/planning-core/scripts/tests/test-g2prime.sh` ; `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | 11 mutants listés en R-1 (`MUT-G2P-*`) | ❌ Wave 0 / à étendre |
| BAIL-07 | `dag.sh` : T50 (perte déterministe par injection), T51 (lecture jamais déchirée), mutants, droits, lien, baseline 161 | concurrence + mutation | `bash plugin/conductor/scripts/tests/test-dag.sh` | `# dag-verrou` retiré → perte ; `# dag-atomique` → lectures déchirées (observé : 108 sur 1613) | ✅ à étendre |
| BAIL-08 | deux recalculs concurrents : `cloture.log` sans doublon, `INDEX.md` cohérent ; colonne identique à `aucun` sans `baux/` | concurrence + régression | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | `MUT-RECALC-SANS-VERROU` (doublons observables avec injection de délai) | ✅ à étendre |
| BAIL-09 | étape 7 : constantes, `ORDRE_ETAPES`, `armement_valide` (`G2P ⇒ BAIL`, étape 7 exige l'étape 6), canaris, rejeu `--etape=7`, recensement | croisé | `VF_GATES_SECTIONS=table,reference bash plugin/planning-core/scripts/tests/test-planning-gates.sh` ; `bash plugin/planning-core/scripts/tests/test-rejeu-gates.sh` ; commande de recensement ci-dessous | recensement **rouge aujourd'hui** (voir ci-dessous) | ✅ à étendre |
| BAIL-10 | zéro régression hors adhésion, mutation « ignorer l'adhésion », coût mesuré, spec/référence/limites, v2.12.0, README, `Gate-Touche:` | équivalence + gates de dépôt | `VF_PF_SECTIONS=evenements bash plugin/planning-core/scripts/tests/test-planning-prefilter.sh` ; `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` ; `bash plugin/_internal/tests/test-planning-hook-installed.sh` ; `bash scripts/check-version-sync.sh` ; `bash scripts/check-machine-paths.sh` | `check-version-sync` rougit si « N suites » ne suit pas | ✅ à étendre |

**Commande de recensement des constantes (rouge aujourd'hui, vérifiée valable sous zsh)** :
`python3 -c "import re; t=open('plugin/planning-core/scripts/planning-hook.sh').read(); n=len(re.findall(r'^ARMEMENT_[A-Z0-9]+ = \"(?:observe|armed)\"  # etape-[1-7]\$', t, re.M)); assert n==10, 'constantes ARMEMENT_* : %d (attendu 10)' % n"` → sortie relevée cette session : `AssertionError: constantes ARMEMENT_* : 8 (attendu 10)`, code 1. Devient verte quand les deux constantes sont posées ; le test de recensement de la suite vérifie en plus que chaque expression de suite les nomme.

### Sampling Rate
- **Per task commit :** la suite du plan (zsh ET bash 3.2, sous `HOME` temporaire pour les suites d'installation) ; sections par variable.
- **Per wave merge :** boucle des suites de `planning-core` + `bash plugin/conductor/scripts/tests/test-dag.sh` + `check-version-sync.sh` + `check-machine-paths.sh` + gates de planning rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md` (la CI ne vérifie que `fiabilite`, `CLAUDE.local.md`).
- **Phase gate :** toutes les suites vertes sous zsh et bash, puis CI Linux de la PR (geste de Willy) ; avant chaque commit d'armement : banc 0/0, canary vert, rejeu réel en lecture seule 0/0 avec couverture ≥ plancher et empreintes d'arbre identiques (le script de décision de la 46.1 valide le relevé).

### Wave 0 Gaps
- [ ] `plugin/planning-core/scripts/tests/test-baux-registre.sh` — BAIL-01, 05 (clé, prise, tempête, mutants, outil)
- [ ] `plugin/planning-core/scripts/tests/test-bail-gate.sh` + `fixtures/bail-banc.txt` — BAIL-02, 03, 04, 10 (banc B01-B24 avec jumeaux `-dev`)
- [ ] `plugin/planning-core/scripts/tests/test-g2prime.sh` — BAIL-06 (banc G01-G23, mutants)
- [ ] cas T50-T52 dans `plugin/conductor/scripts/tests/test-dag.sh` — BAIL-07
- [ ] cas de concurrence dans `test-recalc-planning.sh` — BAIL-08
- [ ] extension des expressions `ARMEMENT_(?:…)` (7 suites), `TABLE_ATTENDUE`, `ORDRE_ATTENDU`, `GATES_REFERENCE`, test de recensement — BAIL-09
- [ ] compteurs « N suites » des deux README racine (109 + 3 suites neuves + celles de la 46.1) — BAIL-10

Mutations à tracer pour chaque garde (assertion · attendu (original) · obtenu (mutant)) : jamais de mutant tué par une course ou une durée (il meurt par structure ou par verdict) ; chaque marqueur de commentaire est unique sur sa ligne (`make_hook_mutant` exige une seule ligne porteuse).

## Security Domain

`security_enforcement` est actif dans cette lignée de phases (niveau ASVS 1, blocage `high`, `46-RESEARCH.md`) `[CITED: 46-RESEARCH.md § Security Domain]` ; non relu dans `config.json` ici.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — (l'identité est celle du harnais, jamais une preuve cryptographique) |
| V3 Session Management | non | — |
| V4 Access Control | oui | gate `BAIL` (fencing par génération), G6 en profondeur sur `baux/` et sur la liste de `config.json`, dérogation nominative à usage unique |
| V5 Input Validation | oui | demande lue dans le payload (`lire_frontmatter`), `fichier:` égal à une entrée déclarée, nom de demande par motif strict, `entree_ecrit_valide` + bornes de composant pour les entrées déclarées, `_jeton_journal` pour tout champ écrit |
| V6 Cryptography | oui (intégrité seulement) | `hashlib.sha256` stdlib ; jamais d'implémentation maison |
| V7 Error handling and logging | oui | fail-closed déclaré par gate, journal `empreintes.log` append-only encodé, aucun chemin absolu ni « no such file » / « can't open » dans un message |
| V12 Files and Resources | oui | `lstat` par composant, `O_NOFOLLOW`, création exclusive (`mkdir`, `link`, `O_EXCL`), lecture bornée, aucun lien suivi, budget d'octets, échéance interne de 8 s |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `meta` forgé par `Bash` (détenteur falsifié) | Tampering / Spoofing | `Write`/`Edit` refusés (G6) ; `Bash` hors portée du hook (P45-D-10) : limite nommée ; relecture qui exige `cle`, `chemin`, `numero`, `fin=1` cohérents |
| Usurpation d'unité dans une demande (`unite:` d'une autre) | Spoofing | l'identité vient du payload, pas de la demande ; l'unité n'est qu'une déclaration tracée dans le `meta` ; un amendement exige une raison et reste relisible |
| Traversal / alias du chemin déclaré (`../`, lien, casse, NFD) | Tampering | égalité exacte à une entrée déclarée ; `samefile` puis NFC + `casefold` ; `entree_ecrit_valide` |
| Lien symbolique substitué à `baux/` ou à un fichier déclaré | Tampering | `lstat` par niveau, `O_NOFOLLOW`, outil qui refuse une cible lien |
| Déni de service par demandes en masse ou par fichier déclaré énorme | DoS | noms de demande bornés, budget d'octets, échéance du cœur, observation au-delà |
| Injection de ligne dans `empreintes.log` par un nom de fichier | Tampering | `_jeton_journal` (injectif) |
| Écrivain en retard qui écrase après une reprise | Tampering | vérification sous verrou au moment d'écrire (outil) ; gate du hook pour les outils ; fenêtre `PreToolUse` → écriture nommée |
| Fuite de chemin absolu dans un message de refus | Information disclosure | chemins relatifs au lab seulement ; test de contenu des messages |

## Project Constraints (from CLAUDE.md)

- **Aucune release pour cette phase** : doc, specs, planning et gates de moteur sans évolution fonctionnelle livrée ne déclenchent pas de release (`CLAUDE.md` « Quand publier », ADR-073) ; `CLAUDE.local.md` : aucune release gouvernance avant la clôture de `fiabilite-v1.0`. Donc : `planning-core` v2.10.0 → (v2.11.0 par la 46.1) → **v2.12.0** dans `VERSION`, `module.json`, `CHANGELOG.md`, en-tête `Version` du `README.md` du module ; `conductor` bumpé séparément ; **`VERSION` racine, `plugin.json`, `marketplace.json`, badges et historique des README racine ne bougent pas** (seul le compte « N suites » suit).
- **Jamais de fix sans validation humaine (ADR-031)** : les checkpoints d'armement sont humains, bornés au moment d'agir, jamais une autorisation gravée dans un plan.
- **Commits en français** ; **traçabilité des arbitrages** : canal et date (« Willy, AskUserQuestion session principale, 2026-10-12 ») ; **préfixage des décisions** (`P47-D-NN`, jamais `D-01` nu).
- **Marqueur `Gate-Touche: <chemin> — <raison ≥ 10 caractères>`**, un chemin par trailer, sur tout commit qui touche un gate, sa suite, le workflow CI ou un hook (G-2, P47-D-16) ; `test-dag.sh` est dans la surface de `check-gate-touche.sh`.
- **Densité (ADR-029)** : agents ≤ 300 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens — aucun agent ni skill n'est créé ; ne pas toucher le frontmatter de `SKILL.md`.
- **Protection serveur de `main`** : PR, quatre checks, revue code owner sur `.github/`, baseline du budget d'instructions, sentinelles d'armement, `scripts/hooks/` ; ne pas modifier `.github/workflows/ci.yml` (la CI découvre les suites).
- **Compartiment** : `--ws gouvernance` à chaque appel GSD ; `gsd-tools` par `node ~/.claude/gsd-core/bin/gsd-tools.cjs` ; **jamais `state.*`** (réécrit le frontmatter) ; `STATE.md` et `ROADMAP.md` à la main, frontmatter de `STATE.md` fermé avant la ligne 60 ; la CI ne vérifie que `fiabilite` : gates de planning rejoués avec `--file .planning/workstreams/gouvernance/STATE.md`.
- **Une session = un worktree** ; pas de `cd` vers un autre worktree ; aucun chemin de machine dans les fichiers livrés (`scripts/check-machine-paths.sh`) ; aucune sonde `claude -p` ; aucun lab externe lu.
- **Exécution après la 46.1** (feu vert de Willy, 2026-10-12) : plans écrits contre `78808126`, re-validés par un plan-checker frais contre le code livré par la 46.1.

## Sources

### Primary (HIGH confidence)
- Code lu cette session (worktree `agent-a27d54e8a8701d01e`, HEAD `a5107583`) : `plugin/planning-core/scripts/planning-hook.sh` (l.1-1880 par plages, 1879-2057, 2560-3558), `recalc-planning.sh` (l.740-960, 1360-1480, 2000-2515), `poser-verdict.sh` (l.900-1105), `deroger-gate.sh` (extraits), `check-gates-alive.sh` (l.150-300, 585-610), `rejeu-gates.sh` (l.140-170, 380-400, 1575-1600), `rejeu-reel.sh` (extraits), `plugin/conductor/scripts/dag.sh` (complet), `test-driver-lock.sh` (T11, T13, T32), `test-dag.sh` (en-tête, T1-T4, numérotation), `test-planning-gates.sh` (R-VERDICT-08 `:4540-4640`, `:160-176`), `check-version-sync.sh`, `check-gate-touche.sh`, `check-instruction-budget.sh`, `check-method-budget.sh`, `.github/workflows/ci.yml` (l.1-262, découverte des suites), `hooks/hooks.json`.
- `47-CONTEXT.md`, `47-SCOUTING.md`, `47-RECHERCHE-BAUX.md`, `47-DISCUSSION-LOG.md`, spec `2026-09-22-moteur-planning-metier-design.md` §5, §5.1, §6, §7.4, `46-RESEARCH.md`, `46-VALIDATION.md`, `46-NOTE-ROADMAP-47.md`, `ROADMAP.md` §46.1 et §47, `REQUIREMENTS.md` (BAIL), `CLAUDE.md`, `CLAUDE.local.md`.
- 46.1 en lecture seule (checkout `gouvernance-46-1`, plans écrits, non exécutés) : `46.1-CONTEXT.md`, `46.1-PATTERNS.md`, `46.1-01-PLAN.md`, `46.1-09-PLAN.md` (interfaces), en-têtes des dix plans.
- Documentation : Python 3.9 `os.replace`, `tempfile.mkstemp`, `fcntl.flock` (Context7, `/websites/python_3_9`) ; `flock(1)` « file | directory » (man7.org, lu le 2026-10-12).
- Sondes et prototypes rejoués cette session (scratchpad, non versionnés) : normalisation, casse et longueur de nom sur APFS, `flock` sur descripteur de dossier, tempête de prise (24 preneurs, trois mutants, injection de défaut), tempête de `dag.sh` avant et après correctif.

### Secondary (MEDIUM confidence)
- `47-RECHERCHE-BAUX.md` (documentation des hooks Claude Code 2.1.296, issues #76726, #84701, #90662, #95440, Kleppmann 2016, antirez) : relevés par un autre agent, non relus à la source ici.

### Tertiary (LOW confidence)
- Comportements de Linux et d'ext4 non rejoués (A1, A2), bash 3.2 non sondé (A3), tous marqués `[ASSUMED]`.

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — bibliothèque standard déjà employée par les trois scripts.
- Architecture : HIGH pour le registre, la prise, la concurrence, `dag.sh` et le recalcul (code lu, prototypes rejoués) ; MEDIUM pour G2′ (règle d'imputation neuve, jamais exercée par le vrai hook) et pour le geste de prise (comportement exact du harnais sur `additionalContext` d'un sous-agent non sondé).
- Pitfalls : HIGH pour ceux qui découlent du code (compte d'armement, `mkstemp`, verrou d'un inode remplacé, mutant équivalent) ; MEDIUM pour ceux qui dépendent du harnais ou de Linux.

**Limites de cette recherche :** aucune suite de la 46 n'a été rejouée (hors `test-dag.sh` : 161 PASS / 0 FAIL, et `check-version-sync.sh`) ; la garde d'isolation a refusé `bash --version` et les commandes composées ; aucune sonde `claude -p` ; le code de la 46.1 n'est pas exécuté (ses plans sont lus).

**Research date :** 2026-10-12
**Valid until :** 2026-10-26 (le harnais évolue vite : relire § PreToolUse, `agent_id` / `session_id`, `onFailure` si Claude Code quitte la 2.1.296 avant l'exécution ; et re-valider contre le code livré par la 46.1 avant tout plan exécutable)

