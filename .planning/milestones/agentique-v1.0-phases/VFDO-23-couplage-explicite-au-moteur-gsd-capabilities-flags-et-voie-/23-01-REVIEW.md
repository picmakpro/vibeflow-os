# Phase 23 — Revue de code du plan 23-01 (nœud `revue-01`, régime plein)

**Diff relu** : `git diff 69ca0ec d4f7ba3` — 5 fichiers de périmètre
(`vf-coder.md` 91 L · `vf-dev-manager.md` 235 L · `mission-contracts.md` 300 L ·
`mission-flow.md` 288 L · `test-dev-orchestrator.sh` 3583 L, +1920/−63).
Les `.planning/**` sont hors périmètre de revue, lus comme source de vérité seulement.

**État de départ et d'arrivée** : `HEAD = d4f7ba3`, `git status --porcelain` **vide** avant et après
la revue. Toutes les mutations ont été appliquées puis annulées (`git checkout -- .`) avec
vérification d'arbre propre entre chaque.

**Baseline** : `99 OK / 0 KO / 0 SKIP`, `rc=0`.

---

## 1. Conformité doctrinale A-1bis..A-4 (texte réellement sur disque)

| Décision | Exigence écrite dans 23-ARBITRAGES.md | Constat sur disque | Verdict |
|---|---|---|---|
| **A-1bis** | `vf-coder` **garde** `--auto` sur le cadrage ET désarme le flag d'enchaînement **immédiatement après**, de façon **adjacente** | `vf-coder.md:27-28` — `--auto` puis, dans la même puce numérotée et la phrase suivante, `gsd_run config-set workflow._auto_chain_active false`. Adjacence **réelle** (≈ 75 caractères mesurés par la sonde), pas une co-présence de bloc. | **Conforme textuellement** — mais la prémisse d'A-1bis est démentie par l'amont, cf. **F1** |
| **A-2** | `workflow.auto_advance` désarmé, **dans la même forme** que A-1bis | `vf-dev-manager.md:69-70` — les deux `config-set … false` enchaînés par `**puis**` dans le même geste 5. Même forme (clé nommée + remise à faux explicite). | **Conforme** |
| **A-3** | le minimum de reprise transporte **la réponse humaine** ET **la table des tâches faites** ; le **distinguo** avec la garde ADR-030 est **écrit** | `mission-contracts.md:186-193` — `reponse_humaine` et `taches_faites` ajoutés à l'ensemble clos ; `:195-204` — paragraphe « **Distinguo à ne jamais réduire** » séparant explicitement recopie de **doctrine** amont (interdite) et transport d'un **état** de reprise (licite). | **Conforme** |
| **A-4** | chacune des **deux** branches (gel / question) porte un **qualificatif de mode explicite** | `mission-flow.md:168-181` — « en mode **superviser**, c'est le manager qui **répond aux attentes humaines** … » / « en mode **autonome**, il n'y répond JAMAIS … : **GELER le nœud porteur** ». Les deux branches qualifiées, chacune du bon mode. | **Conforme** |

**A-1 (ANNULÉE)** : aucune trace de la règle retranchée dans les fichiers de doctrine. Le gate qui
avait figé `--assumptions` comme forme licite (`e2b1bfe`) est bien défait — `T25` a retiré la
branche Cadrage de son périmètre (`test-dev-orchestrator.sh:2345-2361`) et l'a remplacée par
l'exigence de relation de `T25b`. **Aucune doctrine n'a été tordue pour plaire à un gate.**

---

## 2. Discriminance par mutation — tableau des mutations jouées

Protocole appliqué à chaque ligne : mutation du fichier **réel** → `bash test-dev-orchestrator.sh`
→ relevé de `rc` et des lignes `✗` → `git checkout -- .` → vérification `git status --porcelain`
vide avant la mutation suivante.

### 2.1 Mutations de violation (doivent ROUGIR)

| # | Assertion visée | Mutation exacte appliquée | Verdict observé | Conclusion |
|---|---|---|---|---|
| M01 | `T25b` (A-1bis, adjacence) | `vf-coder.md` : l'appel `gsd_run config-set workflow._auto_chain_active false` remplacé par « l'appel de fermeture du moteur » (`--auto` conservé) | `rc=1` · `T25b` — « **vf-coder.md RÉEL ne tient pas l'assertion (rc=1)** … AUCUN désarmement nommé ne le SUIT dans le bloc » + le balayage nomme le fichier | **discriminante** |
| M02 | `T25b` (relation pure) | le même appel **déplacé hors du bloc Cadrage**, en fin de fichier — aucun token perdu | `rc=1` · `T25b` idem | **discriminante** (mesure bien une relation, pas une présence) |
| M03 | `T25c` (A-2) | `**puis** gsd_run config-set workflow.auto_advance false` supprimé du geste 5 | `rc=1` · `T25c` ×2 — « second déclencheur … n'est pas désarmé dans le même geste » | **discriminante** |
| M04 | `T25c` (A-2, valeur) | `workflow.auto_advance false` → `… true` | `rc=1` · `T25c` ×2 | **discriminante** |
| M05 | `T27b` — **rejeu littéral de B5** | clause **AJOUTÉE** dans `mission-flow.md` : « En mode **autonome**, c'est toi qui réponds aux attentes humaines du moteur : tu tranches à la place de l'utilisateur et tu poursuis. » (rien retiré) | `rc=1` · `T27b` — « mission-flow.md : une clause rattache la RÉPONSE à l'attente humaine au mode AUTONOME … viole ADR-031 » | **discriminante — B5 est réellement fermé** |
| M06 | `T27b` — **B4, cible 2** | même clause injectée dans `mission-contracts.md` | `rc=1` · `T27b` nomme `mission-contracts.md` | **discriminante** |
| M07 | `T27b` — **B4, cible 3** | clause à modes échangés injectée dans `vf-dev-manager.md` | `rc=1` · `T27b` nomme `vf-dev-manager.md` | **discriminante** |
| M08 | `T27b` — **évasion O-1** | modes `superviser` ↔ `autonome` **échangés dans la paraphrase du renvoi** de `vf-dev-manager.md:164-165` (aucun token perdu) | `rc=1` · `T27b` nomme `vf-dev-manager.md` et cite la paraphrase | **discriminante — l'évasion décrite en O-1 (93 OK / 0 KO) est fermée** |
| M09 | `T27` (foyer) | modes échangés dans les deux branches de `mission-flow.md` | `rc=1` · `T27` (A-4) + `T27` DISCRIMINANT + `T27b` + `T27c` | **discriminante** |
| M21 | `T27` (a) | branche de GEL **démuselée** de son qualificatif de mode | `rc=1` · `T27` — « clause de contrôle de flux SANS qualificatif de mode » | **discriminante** |
| M10 | `T26 D` — **rejeu de B6** | « la table Completed\nTasks » recopiée dans `mission-contracts.md`, **coupée par un retour à la ligne** | `rc=1` · `T26 D` nomme le fichier | **discriminante — B6 fermé pour les intitulés multi-mots** |
| M11 | `T26 D` — B6, autre intitulé | « Checkpoint\nDetails … Current Task » coupé au pli dans `vf-dev-manager.md` | `rc=1` · `T26 D` | **discriminante** |
| **M12** | `T26 D` — **5ᵉ intitulé** | « **Awaiting** : la rubrique du contrat interne amont, recopiée telle quelle ici. » ajouté à `mission-contracts.md` | **`rc=0` · `99 OK / 0 KO`** | **VACUOUS — cf. finding F2** |
| M13 | `T26 A` / `T26 E'` (A-3) | `reponse_humaine` → `reponse_user` | `rc=1` ×3 — « l'ensemble mesuré … n'est pas EXACTEMENT celui de D-03 » | **discriminante** |
| M14 | `T26 A` / `T26 E'` (A-3) | `taches_faites` retiré de l'énumération close | `rc=1` ×3 | **discriminante** |
| M15 | `T26 F` (A-3) | paragraphe « **Distinguo à ne jamais réduire** … » effacé | `rc=1` · `T26 F` — « aucun bloc ne porte le distinguo » | **discriminante** |
| M16 | `T24 A` (D-01) | conséquent inversé : `⇒ statut: "human_needed"` → `⇒ statut: "passed"` | `rc=1` · `T24 A` — « un motif de la prémisse implique un AUTRE statut … conséquent mesuré : passed » | **discriminante** |
| M16b | `T24 A` (deux motifs) | le `**OU** précondition amont non satisfaite` supprimé | `rc=1` · `T24 A` — « la règle n'a plus ses DEUX motifs » | **discriminante** |
| M17 | `T24 B` | `vf-coder.md` : `statut: "human_needed"` → `"gaps_found"` | `rc=1` · `T24 B` | **discriminante** |
| M18 | `T24 C` | `mission-flow.md` : `human_needed` détaché des deux motifs amont | `rc=1` · `T24 C` + `T24 D` (rc=3 « rien n'a été mesuré » traité en KO) | **discriminante** |
| M19 | `T18` / `T18c` | un nom (`vf-design-judge`) **relocalisé hors des parenthèses** `Agent(...)` de la ligne `tools:` | `rc=1` · `T8c` + `T18` (« absent de l'allowlist, extraction bornée ») + `T18c` | **discriminante** ; révèle un garde no-op faible, cf. **F6** |
| M20 | `T23` / `T23b` | un des quatre déclencheurs du nœud docs **dispersé** hors de l'énumération (token conservé) | `rc=1` · `T23 managers` — « ne tiennent pas dans un MÊME bloc » | **discriminante** |
| M22 | `T21d atteinte` | tout `mktemp` renommé dans les 3 scripts balayés | `rc=1` · « **AUCUN mktemp** … la règle n'est exercée nulle part » | **compteur d'atteinte réel** |
| M23 | `T21d` | la ligne `trap … EXIT` supprimée du script qui a des `mktemp` | `rc=1` · « 3 mktemp sans trap … EXIT » | **discriminante** |
| M24 | `T17` / `T17b` | la ligne enrichie d'`AGENT.md` **scindée** juste avant `gsd-ingest-docs` (aucun token retiré) | `rc=1` · `T17 routage` | **discriminante** |
| **M25** | *(aucune)* | sous-titre `### Contrôle de flux du manager — table de pilotage (foyer UNIQUE)` **renommé** en `### Pilotage des verdicts (table)` | **`rc=0` · `99 OK / 0 KO`** | **citation pendante non gatée — cf. F4** |
| M26 | `T27` (volet renvoi) | le renvoi de l'agent pointe vers `mission-pilotage.md` §Pattern Z | `rc=1` ×2 — « ne nomme pas mission-flow.md » / « ne nomme pas la section (§Pattern C) » | **discriminante** |
| M27 | `T24 A` (ancre) | `## Contrat de checkpoint amont` renommé en `## Checkpoints amont` | `rc=1` · `T24 A` — « section absente » | **discriminante** |
| M29 | `T25` / `T25c` | geste 5 **entièrement supprimé** de `vf-dev-manager.md` | `rc=1` ×5 (`T25 présence` ×3, `T25c` ×2) | **discriminante** |
| M30 | `T25 fermeture` | `2. **Plan** : invoque gsd-plan-phase` → `… --auto` | `rc=1` · « forme interdite trouvée (mode d'enchaînement prescrit sur une brique Plan/Exécution) » | **discriminante** |

### 2.2 Contrôles de non-régression (réécritures LICITES — doivent rester VERTES)

| # | Réécriture licite appliquée | Verdict | Conclusion |
|---|---|---|---|
| L01 | reformulation du couple adjacent de `vf-coder` (« lance … et enchaîne aussitôt sur … sans rien intercaler ») | `rc=0` · `99 OK` | **pas de faux rouge** |
| L02 | réécriture en prose de la « Règle unique de mapping » avec contraste explicite (`⇒ human_needed — jamais gaps_found`) | `rc=0` · `99 OK` | **pas de faux rouge** |
| L03 | réécriture du bloc `gate` de `vf-coder` (2ᵉ personne, « dès que … puis tu rends ») | `rc=0` · `99 OK` | **pas de faux rouge** |
| **L04** | réécriture d'A-4 **dans la graphie que T27c déclare reconnaître** : attente au singulier (« répond à l'attente humaine »), gel nominal (« gel du nœud »), mode en tête de branche (« **superviser** : … ») | **`rc=1` · 2 KO** (`T26 C` + `T27 DISCRIMINANT`) | **FAUX ROUGE chiffré — cf. F5** |
| M28 | L04 **+ inversion des deux modes** (la violation, écrite dans la graphie du renvoi) | `rc=1` · `T27 (A-4)` nomme la faute correctement | **pas de faux vert** : la violation reste détectée quelle que soit la graphie |

---

## 3. Vert à vide

Tous les balayages **nouveaux** portent un compteur d'atteinte, et chacun a été vérifié falsifiable :

| Balayage | Compteur | Vérifié par |
|---|---|---|
| `T25 fermeture` | `t25_scanned` (13 fichiers) **+** `T25 atteinte` (`t25_bricks` = 3 briques Plan/Exécution réellement vues) | M30 (mord) |
| `T25b` | `t25b_scanned` (13) + assertion sur le fichier réel (rc=0 exigé, rc=3 « sans objet » traité en KO) | M01/M02 |
| `T26 D` | `t26_scanned` (13) | M10/M11 — **mais pas de contrôle positif sur la branche `^Awaiting$`**, cf. F2 |
| `T27b` | `t27b_scanned` + `seen_flow`/`seen_contracts`/`seen_devmgr` (les 3 cibles vérifiées PRÉSENTES) | M05/M06/M07 |
| `T27c` | `t27c_ask_seen` / `t27c_freeze_seen` (compteurs d'atteinte de motif) | M08 |
| `T21d` | `t21d_total_mktemp` | **M22** (retire les mktemp → KO explicite) |
| `T24` | 3 cibles nommées, `rc=3` = « forme non reconnaissable » traité en **KO** | M18 |

**Aucun autre balayage / boucle / grep de la suite ne peut rendre 0 correspondance et rester vert.**
Le seul vert-à-vide résiduel est la **branche `^Awaiting$` de `t26_internal_titles`** : elle n'est
jamais exercée par une fixture et n'est atteignable que par une ligne markdown strictement nue —
F2.

---

## 4. Aucune assertion retirée en douce

Base matérialisée (`git show 69ca0ec:… > base.sh`), exécutée depuis l'emplacement du module (le
script résout sa racine via `dirname "$0"`), puis comparaison des **ensembles** de libellés `ok`
en Python (`set(base) - set(head)`), pas un verdict binaire :

- base `69ca0ec` : **77** libellés `ok` · HEAD `d4f7ba3` : **99**
- **`base − head` = ∅** — aucun libellé disparu
- `head − base` = **22** nouveaux libellés (T17b, T18c, T21d atteinte, T23b, T24 ×2, T25 ×4,
  T25b, T25c, T26 ×6, T27, T27b, T27c)

À noter : la suite `69ca0ec` passe `77 OK / 0 KO` **sur les fichiers de doctrine réécrits** — elle
est donc indifférente à tout ce que le plan 23-01 a changé, ce qui confirme que les 22 nouvelles
assertions sont bien la seule couverture de ce plan.

---

## 5. Conventions

- **ADR-029** : `vf-coder.md` = **91/250** · `vf-dev-manager.md` = **235/250** (`wc -l`). La marge
  de **15 lignes** rendue par le déport du bloc A-4 vers `mission-flow.md` est **effectivement
  préservée** ; aucune reprise de gras sur l'agent. Le geste 5 ajouté (+8 L) est compensé par le
  déport (−9 L nettes sur le §Contrôle de flux).
- **ADR-030** : le foyer unique de la table de pilotage est bien `mission-flow.md` §Pattern C ;
  l'agent n'en garde qu'un renvoi. La paraphrase du renvoi
  (`vf-dev-manager.md:164-165`) reste **déjà consignée en O-1** — non re-signalée ici, mais le
  gate mord désormais dessus (M08).
- **ADR-031** : aucun chemin où un agent autonome répond lui-même à une attente humaine.
  `vf-coder.md:33-35`, `:84-85`, `:89-91` réitèrent l'escalade ; `mission-flow.md:176-181` porte
  l'interdiction explicite. Le rejeu littéral de B5 (M05) est capté.
- **Commits** : messages en français, cohérents.

---

## 6. Cohérence référence ↔ agents

| Renvoi | Foyer | Gaté ? |
|---|---|---|
| `vf-dev-manager.md:162` → `mission-flow.md` §Pattern C « Contrôle de flux du manager » | existe (`mission-flow.md:162`) | **partiellement** — fichier et §Pattern C gatés (M26 rouge) ; le **sous-titre cité** ne l'est pas (M25 vert) → **F4** |
| `vf-coder.md:81`, `:87` → `mission-contracts.md` §Contrat de checkpoint amont | existe (`:170`) | **oui** (M27 rouge) |
| `vf-dev-manager.md:72` → `mission-contracts.md` §Seuil de bascule | existe (`:257`) — c'est bien là que vit la cascade de résolution de `gsd_run` | oui, mais **placement ambigu** → **F8** |
| `mission-flow.md:171`, `:177` → `mission-contracts.md` §Contrat de checkpoint amont / §Minimum de reprise | existent | oui |

Aucun renvoi ne **contredit** son foyer.

---

## 7. Findings

### F1 — BLOQUANT · `action: ask-user` · `plugin/dev-orchestrator/agents/vf-coder.md:27-31`

**La prémisse d'A-1bis est démentie par le moteur amont : le désarmement « immédiatement, dans le
même geste » n'est pas exécutable, et la fenêtre armée n'est pas bornée au cadrage.**

Faits vérifiés contre `gsd-core@1.9.0` installé (`$HOME/.claude/gsd-core`) :

1. `skills/gsd-discuss-phase/SKILL.md:60-61` route `--auto` vers
   `gsd-core/workflows/discuss-phase.md`, à exécuter **end-to-end**.
2. `workflows/discuss-phase.md:488-491` — le step `auto_advance` lit et exécute
   `workflows/discuss-phase/modes/chain.md`.
3. `modes/chain.md:42` pose `workflow._auto_chain_active true`, puis **`chain.md:45-61`** :
   « **If `--auto` … : display banner and launch plan-phase** » via
   `Skill(skill="gsd-plan-phase", args="${PHASE} --auto ${GSD_WS}")`, et `chain.md:66-88` gère le
   retour de **plan-phase → execute-phase** (« Auto-advance pipeline finished: discuss → plan →
   execute »).

Conséquence : `vf-coder` ne reprend la main qu'**après** que la chaîne discuss → plan → execute
s'est déroulée. Son « puis **immédiatement, dans le même geste** » ne peut s'exécuter qu'à la fin
de tout le pipeline. Pendant toute cette durée `workflow._auto_chain_active` vaut `true`, donc
`gsd-core/references/checkpoints.md:11` s'applique : *« human-verify auto-approves, decision
auto-selects first option »* — c'est **exactement le risque D-02** qu'A-1bis prétend borner, sur
les deux étages les plus coûteux du cycle.

`T25b` certifie une **adjacence textuelle** — réelle, discriminante (M01/M02), et sans rapport avec
la fenêtre runtime. Le gate est vert pendant que la garantie est absente.

**Je ne tranche pas.** Cela remet en cause un arbitrage humain (A-1bis) sur ses faits, et rouvre la
3ᵉ voie qu'A-1bis avait écartée (« le manager porte le cadrage lui-même, il a `AskUserQuestion` »,
23-ARBITRAGES.md:66-69) ainsi que la voie `workflow.discuss_mode` (`config.cjs:259`). ADR-031 :
remontée à l'humain.

### F2 — MAJEUR · `action: auto-fix` · `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:3001`

**La garde anti-duplication ADR-030 ne couvre que 4 des 5 intitulés qu'elle annonce.**

`t26_internal_titles()` traite `Awaiting` par `grep -lE '^Awaiting$'` — une **ligne strictement
nue**. Toute recopie sous graphie markdown (`**Awaiting** :`, `- Awaiting :`, `### Awaiting`)
échappe : **M12 laisse la suite à `99 OK / 0 KO`** en recopiant littéralement la rubrique dans
`mission-contracts.md`. C'est la famille B6, non close pour ce motif. Le libellé d'`ok` promet
« aucun ne reproduit **les** intitulés du contrat interne » — il sur-déclare.

Le commentaire (`:2995-2996`) justifie de ne pas dégrader en `Awaiting` nu (faux rouges sur de la
prose anglaise) : la justification est bonne mais l'alternative bornée n'a pas été prise.

Correctif suggéré : sur le fichier **replié**, un motif borné du type
`(^|[^[:alnum:]])Awaiting[[:space:]]*[:*]` (l'intitulé suivi de son marqueur), **plus une fixture
positive dédiée** — la branche `^Awaiting$` n'est aujourd'hui exercée par **aucun** contrôle
positif (la fixture `T26_FIXTURE` n'exerce que la passe multi-mots).

### F3 — MAJEUR · `action: auto-fix` · `plugin/dev-orchestrator/agents/vf-coder.md:28`

**`vf-coder` prescrit `gsd_run` sans renvoi de résolution ni conduite d'indisponibilité.**

Le manager, lui, porte les deux : renvoi vers `mission-contracts.md` §Seuil de bascule (où vit la
cascade, `:261-274`) **et** « `gsd_run` introuvable → consigne au rapport, best-effort »
(`vf-dev-manager.md:74`). `T25 présence` (`test-…sh:2397`) gate d'ailleurs la présence de `gsd_run`
**sur le seul `$DEVMGR`**.

`vf-coder.md:28` introduit le même appel sans aucun des deux. Si `gsd_run` n'est pas résoluble
depuis le worker, le désarmement échoue **en silence** — et c'est précisément la garantie que
A-1bis fait reposer sur ce worker. Un `grep -rn gsd_run plugin/dev-orchestrator/` le confirme :
3 occurrences dans le manager, 1 dans `vf-coder`, aucune conduite associée.

Correctif suggéré : ajouter à `vf-coder.md` §Cadrage le renvoi (`mission-contracts.md` §Seuil de
bascule, DRY — jamais recopier la cascade) et la conduite (`gsd_run` introuvable → consigner au
rapport / `human_needed`, jamais un échec muet) ; étendre `T25 présence` à `$CODER_FILE`.
Coût : 2-3 lignes sur un agent à 91/250.

### F4 — MINEUR · `action: auto-fix` · `plugin/dev-orchestrator/references/mission-flow.md:162`

**Citation pendante possible : le sous-titre du foyer n'est pas gaté.**

Le renvoi de `vf-dev-manager.md:162-163` cite `§Pattern C, « Contrôle de flux du manager »`. `T27`
(volet renvoi) vérifie que l'agent nomme `mission-flow.md` **et** `Pattern C` (M26 → rouge), mais
**rien** ne vérifie que le titre cité existe côté foyer : **M25 renomme
`### Contrôle de flux du manager — table de pilotage (foyer UNIQUE)` et la suite reste à
`99 OK / 0 KO`**. Famille connue de ce dépôt (suppression/renommage de section → citations
pendantes).

Correctif suggéré : ajouter au volet renvoi de `T27` une vérification que la chaîne citée entre
guillemets par l'agent apparaît comme titre dans `$MFLOW`.

### F5 — MINEUR · `action: auto-fix` · `test-dev-orchestrator.sh:2975` et `:3336`

**Faux rouge chiffré : 2 KO sur une réécriture licite d'A-4 (L04).**

Deux causes distinctes, toutes deux internes à la suite (la doctrine réécrite est correcte) :

1. `T26_ANSWER_RE='répond(s)?[[:space:]]+aux[[:space:]]+attentes[[:space:]]+humaines'` (`:2975`)
   n'accepte que le **pluriel**, alors que `T27_ASK_RE` (`:3250`), ajouté par le **même** lot,
   accepte explicitement les deux nombres (« attente au singulier introduite par « à l' » »). Le
   KO produit — « le bloc ne nomme pas le manager comme répondant aux attentes humaines » —
   **accuse la doctrine** qui dit exactement cela, au singulier. Désalignement mécanique, correctif
   trivial : aligner `T26_ANSWER_RE` sur `T27_ASK_RE`.
2. Le mutant **M1 de `T27`** (`:3336`) est ancré sur `mode${MDSP}[*][*]superviser[*][*]` — la
   graphie **en incise du foyer**. Après une réécriture en tête de branche, ce `sed` mord des
   occurrences situées **hors du segment mesuré** (le bullet « Blocage » plus bas) : le fichier
   diffère, donc le garde `cmp -s` passe, le garde de multiset canonique passe, et l'assertion
   rend « **M1 … NON détecté** » — un message qui accuse l'assertion là où la mutation n'a rien
   mordu **dans le périmètre mesuré**.

   **Corollaire important** : l'affirmation d'O-5 — « *Le garde `cmp -s` le dit fort, donc pas de
   faux vert* » — **ne vaut pas pour M1**. `cmp -s` est un garde au niveau du **fichier**, pas au
   niveau du **segment mesuré** ; il ne peut pas distinguer « mutation hors périmètre » de
   « mutation non détectée ». À reverser à O-5.

**Aucun faux vert** en revanche : M28 prouve que la violation reste détectée après la réécriture
licite, avec le bon message. L'écart est fail-closed.

*Note* : le fait qu'une réécriture en prose du bloc Verdict produise des faux rouges est **déjà
consigné au point 5 réinstruit** (P1 → 4 KO · P2 → 2 KO · P3 → 1 KO). Ce qui est **nouveau** ici,
c'est la **cause racine chiffrée** des 2 KO et l'invalidation de la garantie écrite en O-5.

### F6 — MINEUR · `action: auto-fix` · `test-dev-orchestrator.sh:1584-1591`

**Garde no-op insuffisant sur le mutant µ2 de `T18c`.**

`t18c_mu2="$(printf '%s' "$dmt" | sed -e 's/)[[:space:]]*$//'), Bash(git:*)"` — le garde
`[ "$t18c_mu2" = "$dmt" ]` **ne peut jamais être vrai** puisque la concaténation ajoute toujours
`, Bash(git:*)`. Si le `sed` ne mord pas (ligne `tools:` ne se terminant pas par `)`), µ2 devient
un mutant **équilibré** et `T18c` rend « µ2 : NON détecté — une allowlist Agent(...) jamais
refermée passe encore », KO qui **accuse `T18`** alors que la mutation n'a pas eu lieu. Reproduit
sous M19. Correctif : garder sur le résultat du `sed` seul (`[ "$stripped" = "$dmt" ]`) avant
concaténation.

### F7 — MINEUR · `action: no-op` (consigné) · `test-dev-orchestrator.sh:3487`, `:3571`

**Les contrôles anti-faux-rouge de `T27b`/`T27c` (et `T23b`) ne sont pas indépendants du fichier
réel** : ils sont construits par `{ cat "$MFLOW"; printf '%s' "$LICITE"; }`. Dès que le foyer est
fautif, ils émettent un **second KO « FAUX ROUGE »** qui n'en est pas — bruit de diagnostic
reproduit sous M05, M09, M21 et M28. Ils restent **corrects en régime sain** (ils prouvent bien
que la clause licite n'est pas rejetée) ; le coût est purement diagnostique. Signalé, non bloquant.

### F8 — MINEUR · `action: auto-fix` · `plugin/dev-orchestrator/agents/vf-dev-manager.md:72`

**Renvoi ambigu.** « … désarmer le premier seul laisse le second armé (résolution :
`mission-contracts.md` §Seuil de bascule, DRY) ». Lu littéralement, le parenthétique annonce que la
**résolution de cette tension** vit en §Seuil de bascule — or cette section ne porte que la cascade
de résolution de `gsd_run`. Le renvoi est **valide** (la cible existe et contient bien la cascade)
mais mal placé. Correctif : rattacher le renvoi au premier `gsd_run` de la puce.

---

## 8. Points déjà consignés, non re-signalés

Conformément au mandat, les défauts suivants ont été retrouvés et **ne sont pas comptés comme
findings** : **O-1** (paraphrase d'A-4 par le renvoi — le gate mord désormais dessus, M08, mais la
question « pointeur nu vs paraphrase » reste à l'humain) · **O-2** (T25b impose l'ordre
armement → désarmement) · **O-3** (T27 (c) interdit de nommer les deux modes pour une même
disposition) · **O-4** (libellé d'`ok` de T27 sous-déclare : 3 mutants annoncés, 5 exécutés) ·
**O-5** (mutants M2/M3 ancrés sur une tournure de prose — voir toutefois le corollaire de F5) ·
**O-6** (écart d'attribution B2/B3/B7/M1) · **O-7** (assertions au libellé plus fort que la
mesure : `T10`, `T15`, `T7`, `T25 présence`, `T22 captation`) · **points 5, 6 et 7 réinstruits**.

## 9. Ce qui tient (à préserver)

- **B4 fermé** : l'exigence d'A-4 mord sur les **trois** cibles (M05/M06/M07).
- **B5 fermé** : le rejeu littéral de la clause ADR-031-violante rougit (M05).
- **B6 fermé pour les 4 intitulés multi-mots** : l'évasion par retour à la ligne est capturée
  (M10/M11) — reste `Awaiting`, F2.
- **B2/B3/B7/M1 (re-dérivés)** : `T17`, `T18`, `T21d`, `T23` mesurent tous une **relation** ou
  portent un **compteur d'atteinte**, chacun prouvé falsifiable (M24, M19, M22/M23, M20).
- **Aucune assertion retirée en douce** (§4), **aucune doctrine tordue pour plaire à un gate**
  (§1), **marge ADR-029 préservée** (§5).
- **Aucun faux vert constaté** en dehors de F2 et F4.

---

## Verdict

**Correctifs requis avant de continuer** — `gaps_found`, avec **une escalade humaine bloquante
(F1)** que ni le reviewer ni le manager n'ont le droit de trancher (ADR-031).

Les gates du plan 23-01 verrouillent réellement : le **départage gel/question par le mode sur les
trois cibles et dans les deux graphies** (A-4, B4, B5), l'**égalité d'ensemble du minimum de
reprise élargi** et le **distinguo ADR-030 écrit** (A-3), le **désarmement des deux déclencheurs
amont dans le même geste** (A-2), la **relation armement → désarmement adjacent** (A-1bis), et le
**mapping D-01 à deux motifs sur ses trois cibles** (D-01). Ce qu'ils **ne** verrouillent **pas** :
la recopie de l'intitulé `Awaiting` sous graphie markdown (F2), l'existence du titre de section
cité par le renvoi (F4), et — surtout — le fait que l'adjacence textuelle certifiée par `T25b` ne
correspond à **aucune** fenêtre runtime bornée (F1).

---

## Second tour — vérification du comblement (2026-08-02)

Le premier tour ci-dessus est **conservé tel quel** : il est commité et fait référence. Cette
section enregistre le second tour, qui a vérifié le comblement de F2..F8 entre `d4f7ba3` et
`cf3223a`.

**Ce qui est relayé et ce qui est re-mesuré.** Le tableau des mutations du second tour — **23
exécutions, dont 4 contre-épreuves rejouées sur le script `d4f7ba3` matérialisé** — est relayé du
rapport de revue ; il n'est pas re-joué ici, et aucune ligne de détail n'en est reconstituée de
mémoire. En revanche, **les trois mesures d'ensemble ci-dessous ont été re-jouées à l'identique**
au troisième tour, et leurs chiffres sont ceux réellement observés.

### Ensembles de libellés `ok` (méthode : `awk` → `sort -u` → `comm`, jamais `diff`)

L'arbre est tenu **constant** (celui de `cf3223a`) et seul le script change : c'est la seule façon
d'isoler l'effet du lot de correctifs de celui de la doctrine.

| Mesure | `d4f7ba3` | `cf3223a` | Verdict |
|---|---|---|---|
| Libellés `ok` **exécutés** (uniques) | 99 | 102 | **+3** |
| `d4f7ba3 − cf3223a` (`comm -23`) | — | — | **∅ — aucune assertion retirée ni réécrite** |
| Sites d'appel **statiques** `ok "` | **87** | **90** | **+3** |

Les trois libellés gagnés sont exactement les trois correctifs annoncés : `T25 présence
(2 agents)` (F3), `T26 D+ (CONTRÔLE POSITIF, branche Awaiting)` (F2), `T27 (A-4, renvoi, citation
non pendante)` (F4).

> **Correction d'un chiffre du rapport de second tour.** Ce rapport annonçait des sites d'appel
> statiques à **86 → 89**, en écartant le « 87 → 90 » du tour précédent comme ne correspondant « ni
> à l'un ni à l'autre ». Re-mesure : **87 → 90** est le bon compte, et « 86 → 89 » n'est
> reproductible sous aucune décomposition. Méthode, sur le fichier seul (aucun arbre requis) —
> trois formes **disjointes** dont la somme partitionne exactement le total :
> `^[[:space:]]*ok "` = 65 → 68 · `&&[[:space:]]+ok "` = 21 → 21 · `\)[[:space:]]+ok "` = 1 → 1,
> soit 87 → 90. Le « 87 → 90 » du tour précédent était donc **exact** pour le compte statique ; ce
> qui manquait n'était pas le chiffre mais la **distinction** entre sites statiques et exécutions
> (les boucles font diverger les deux : 90 sites pour 102 exécutions).

### Zone gelée F1 / O-8

Vérifiée **byte-identique** (`cmp -s` contre `cf3223a`, jamais `diff`) sur les quatre fichiers qui
portent la clause `--auto`, son désarmement adjacent et le contenu doctrinal d'A-1bis/A-2/A-3/A-4 :
`vf-coder.md`, `vf-dev-manager.md`, `mission-flow.md`, `mission-contracts.md`. L'assertion `T25b`
est de surcroît absente de l'ensemble des lignes modifiées du script (§ Troisième tour). **Rien de
gelé n'a bougé.**

### Findings du second tour

| # | Sévérité | Ref | Objet | Statut |
|---|---|---|---|---|
| **N1** | **majeur** | `test-dev-orchestrator.sh:3050` | **Régression introduite par F5** : `répond(s)?` élargi à `répond(s\|re)?`. L'infinitif étant la forme des interdictions en français, une **prohibition** satisfaisait une assertion qui exige une **affirmation**. Dernier motif de la suite qui refusait cette silhouette ⇒ l'ensemble cessait d'être fail-closed | **fermé** (troisième tour, `9e26660`) |
| **N2** | mineur | `test-dev-orchestrator.sh:2432` | `T25 présence` sélectionnait la **réunion** des blocs contenant `gsd_run` alors que son libellé promet « DANS le bloc qui le prescrit » — renvoi et conduite déportables arbitrairement loin | **fermé** (troisième tour, `271935e`) |
| **N3** | mineur | `test-dev-orchestrator.sh:2896` | `$T26_AWAITING_RE` couvrait `:` et `(` mais pas le tiret cadratin, séparateur dominant du dépôt | **fermé** (troisième tour, `a7f1a37`) |
| **N4** | — | — | — | **`no-op`** — non traité, par mandat |
| **N5** | — | `mission-contracts.md:275-278` | La conduite d'indisponibilité a déjà un foyer, et `T25_UNAVAIL_RE` impose de la recopier dans chaque agent — tension ADR-030 de la même famille qu'O-1 | **versé à l'arbitrage humain** (ADR-031), non tranché par un agent |

---

## Troisième tour — fermeture de N1, N2, N3 (2026-08-02)

Protocole inchangé : mutation du fichier **réel** → `bash test-dev-orchestrator.sh` → relevé des
lignes `✗` → `git checkout -- <fichier>` → `git status --porcelain` **vide** avant la mutation
suivante. Chaque mutant est prouvé **différent de son original** par `cmp -s` avant d'être mesuré
(un mutant identique ne mesure rien). Chaque regex touchée est prouvée **dans les deux sens** :
elle refuse toujours la forme fautive **et** accepte toujours la forme licite.

### 3.1 N1 — l'infinitif retiré de `$T26_ANSWER_RE`

Motif retenu, sans `|re` :
`répond(s)?[[:space:]]+(aux[[:space:]]+|à[[:space:]]+l['’][[:space:]]*)attentes?[[:space:]]+humaines?`

| # | Sens | Mutation exacte, sur `mission-flow.md` | Script | Verdict observé | Conclusion |
|---|---|---|---|---|---|
| **T01** | violation | « c'est le manager qui **n'a jamais à répondre aux attentes humaines** du moteur » | `cf3223a` | **`102 OK / 0 KO`** | **régression reproduite** — une prohibition passe |
| **T02** | violation | *(la même)* | corrigé | `rc=1` · `✗ T26 C : … ne nomme pas le manager comme répondant aux attentes humaines` | **discriminante** |
| **T03** | licite | singulier coupé au pli : `**répond à l'` / `attente humaine**` | corrigé | `102 OK / 0 KO` | **pas de faux rouge** — le faux rouge L04/F5 reste fermé |
| **T04** | licite | 2ᵉ personne : « c'est le manager qui **réponds aux attentes humaines** » | corrigé | `102 OK / 0 KO` | **pas de faux rouge** — la tolérance de personne est intacte |

T03 est la contre-épreuve décisive : elle rejoue **exactement** le faux rouge que F5 fermait
(nombre + « à l' »), et prouve que retirer `|re` ne le rouvre pas — la correction de F5 portait sur
le nombre, jamais sur l'infinitif.

**Borne assumée, fail-closed** : une tournure affirmative à l'infinitif (« c'est au manager de
répondre aux… ») est désormais **refusée elle aussi**. C'est délibéré et écrit dans le commentaire
du motif : une forme dont la garde ne peut pas lire la polarité se refuse, elle ne s'accepte pas au
bénéfice du doute. Un gate qui ne sait pas conclure rougit — il ne se replie pas.

### 3.2 N2 — `T25 présence` ancrée sur le geste, pas sur le token

Ancre : `T25_GESTE_RE='config-set[[:space:]]+workflow[.]_auto_chain_active'` — l'appel **réel** qui
ferme la fenêtre armée. Blancs élastiques (le wrap à 100 colonnes coupe `config-set` de sa clé dans
`vf-dev-manager.md`) ; point **entre crochets** et non échappé, l'ancre transitant par `awk -v` où
`\.` est un échappement indéfini.

| # | Sens | Mutation exacte, sur `vf-dev-manager.md` | Script | Verdict observé | Conclusion |
|---|---|---|---|---|---|
| **T05** | violation | renvoi (`§Seuil de bascule`) **et** conduite (`introuvable → …`) retirés du geste 5 et **déportés** dans une section `## Note d'outillage` en fin de fichier, qui mentionne `gsd_run` | `cf3223a` | **`102 OK / 0 KO`** | **trou reproduit** — la réunion des blocs suffisait |
| **T06** | violation | *(le même déport)* | corrigé | `rc=1` · `✗ T25 présence : vf-dev-manager.md prescrit gsd_run sans renvoyer, DANS le bloc qui le prescrit, à son foyer de résolution` | **discriminante** |
| **T07** | licite | geste replié sur **une seule ligne** — `gsd_run config-set workflow._auto_chain_active false` suivi du parenthétique de résolution —, renvoi et conduite restés dans le bloc | corrigé | `102 OK / 0 KO` | **pas de faux rouge** — les deux graphies (repliée et non repliée) sont tenues |
| **T08** | vert à vide | le geste **retiré** de l'agent (clé remplacée par `workflow.auto_advance`) | corrigé | `rc=1` ×5, dont `✗ T25 présence : 1 agent(s) sur 2 portent réellement le geste de désarmement` | **le compteur d'atteinte mord** — pas de vert à vide |

Le libellé d'`ok` de `T25 présence` est resté **byte-identique** : il ne sur-promet plus, parce que
c'est la **mesure** qui a été relevée à hauteur du libellé, jamais l'inverse. Seuls les deux
messages de **KO** ont été réalignés sur ce qui est désormais mesuré.

### 3.3 N3 — `$T26_AWAITING_RE` reconnaît le tiret

| # | Sens | Mutation exacte, sur `mission-contracts.md` | Script | Verdict observé | Conclusion |
|---|---|---|---|---|---|
| **T09** | violation | `- Awaiting — ce que le moteur attend de l'utilisateur avant de reprendre.` (cadratin) | `cf3223a` | **`102 OK / 0 KO`** | **échappement reproduit** |
| **T10** | violation | *(la même)* | corrigé | `rc=1` · `✗ T26 D (NÉGATIVE) : intitulé du contrat interne … reproduit dans — mission-contracts.md` | **discriminante** |
| **T11** | violation | variante au **demi-cadratin** (`- Awaiting – ce que …`) | corrigé | `rc=1` · `✗ T26 D (NÉGATIVE)` | **discriminante** |
| **T12** | licite | prose anglaise **et** composé ASCII : « Awaiting the human answer, et Awaiting-user reste un composé licite. » | corrigé | `102 OK / 0 KO` | **flanc tenu** — la fixture anti-faux-rouge de `T26 D+` reste verte |

Le tiret **ASCII** est délibérément **exclu** de la classe : sans blanc obligatoire il ferait rougir
`Awaiting-user`, c'est-à-dire un faux rouge sur le flanc même que `T26 D+` protège (T12 le mesure).
Cadratin et demi-cadratin sont ajoutés en **alternation**, jamais dans la classe entre crochets :
caractères multi-octets, qu'une classe découperait en octets isolés.

### 3.4 Non-régression du troisième tour

| Mesure | `cf3223a` | `a7f1a37` (HEAD) | Verdict |
|---|---|---|---|
| Libellés `ok` **exécutés** (uniques) | 102 | 102 | **égalité d'ensemble** |
| `cf3223a − HEAD` (`comm -23`) | — | — | **∅** |
| `HEAD − cf3223a` (`comm -13`) | — | — | **∅** — aucun libellé ajouté non plus |
| Sites d'appel statiques `ok "` | 90 | 90 | inchangé |
| Sites d'appel statiques `ko "` | 203 | 203 | inchangé |

**Écart exact du script**, par ensembles de lignes (`sort -u` + `comm`, jamais `diff`) : **3 lignes
de code** modifiées (l'ancre de `t25_gblk`, `$T26_ANSWER_RE`, `$T26_AWAITING_RE`), **2 messages de
KO** réalignés, le reste étant du commentaire ajouté. **Aucune ligne `ok "` ne figure dans
l'ensemble retiré** — c'est la preuve, indépendante de l'exécution, qu'aucune assertion n'a été
retirée ni réécrite en douce.

**Zone gelée F1 / O-8** : `vf-coder.md`, `vf-dev-manager.md`, `mission-flow.md` et
`mission-contracts.md` sont **byte-identiques** à `cf3223a` (`cmp -s`) — aucun fichier de doctrine
n'a été touché de tout le tour, seule la suite de test a changé. `T25b` n'apparaît pas dans
l'ensemble des lignes modifiées.

**ADR-029** : `vf-coder.md` **94**/250 et `vf-dev-manager.md` **235**/250, inchangés — la marge des
7 plans restants est intacte.

**Suite finale : `102 OK / 0 KO / 0 SKIP`.** Le compteur n'est pas le verdict — il a menti cinq
fois sur cette phase, dont trois fois documentées ici (T01, T05, T09, toutes à `102 OK` sur une
violation). Le verdict est le tableau de mutations ci-dessus.

### 3.5 Reste ouvert

- **F1 / O-8** (A-1bis démentie sur ses faits) : gelé, **en attente d'arbitrage de Samuel**.
- **N5** : tension ADR-030 entre le foyer de `mission-contracts.md:275-278` et l'exigence de
  `T25_UNAVAIL_RE` de recopier la conduite dans chaque agent. **Versé à l'arbitrage humain**, même
  famille qu'O-1 — aucun agent ne la tranche.
