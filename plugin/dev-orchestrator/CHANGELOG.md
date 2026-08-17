# CHANGELOG — dev-orchestrator

## [v2.17.3] — 2026-08-17 (Phase 32, doctrine du verrou resynchronisée)

**Patch** (doctrine d'agent corrigée pour rester exacte, aucune nouvelle capacité).

- `vf-dev-manager.md` et `references/mission-flow.md` (le fichier réellement lu par le manager,
  pas `team-kernel.md`, BL-5) : le couple `acquired:false`/`recovered:true` décrit comme chemin
  nominal d'`acquire` sur un lock périmé — obsolète depuis les plans 32-01/32-02 — est remplacé
  par la doctrine réelle post-Phase 32 : `acquire` REFUSE (`reason: stale-requires-takeover`,
  champ `hint`) et nomme les verbes explicites `takeover --owner=<id> --step=<étape>` (reprise
  d'un lock périmé) et `reclaim --owner=<id>` (rattachement de session sur un lock encore vivant,
  cas `/clear`/reprise de session).
- `mission-flow.md` écrit désormais la convention `Fence: <generation>` elle-même (LOCK-05) — le
  trailer de commit qui trace sous quelle génération du lock un commit est né, et sa commande
  d'audit — puisque c'est le seul fichier que `vf-dev-manager` lit réellement pour cette doctrine
  (`team-kernel.md`, plan 32-04, en reste la source canonique).

## [v2.17.2] — 2026-08-16 (hotfix escalade des gates humains)

**Patch** (fiabilité des missions, aucune nouvelle capacité).

- `vf-dev-manager` : `SendMessage` ajouté au `tools:` — le manager dispatché en sous-agent a
  désormais un canal vivant vers la session principale.
- Repli D-09 réécrit en cascade « escalade vivante » : (1) `SendMessage(to: "main")` avec
  contexte/options/recommandation, nœud du DAG bloqué en attendant le relais ; (2) sinon
  `human_needed` et relance par la session principale. Un gate humain n'est plus jamais franchi
  par fallback ni ne gèle la mission entière (incident du 2026-08-15 : `AskUserQuestion` non
  fournie aux sous-agents backgroundés).

## [v2.17.1] — 2026-08-16 (Phase 30, solde de revue du plan 30-09)

**Patch** (correctif + durcissement, aucune nouvelle capacité).

### Corrigé
- **`check-hook-paths.sh`** — BOM UTF-8 en tête d'un `settings.json` (écrit par défaut par
  `Set-Content`/`Out-File` PowerShell et Notepad « Enregistrer en UTF-8 » sur Windows, la plateforme
  ciblée par cette phase) faisait échouer le parsing JSON (`json.loads` lève `Unexpected UTF-8 BOM`)
  et transformait un `settings.json` parfaitement valide en `PARSE_ERROR` à chaque `SessionStart`.
  Lecture désormais en `encoding='utf-8-sig'` (absorbe le BOM s'il existe, comportement identique en
  son absence). Cas de test T13 ajouté (discriminance prouvée par mutation :
  `utf-8-sig` → `utf-8` fait rougir le cas exactement sur cette régression).
- **`check-hook-paths.sh`** — `--path ""` (valeur vide explicite) passait la garde d'argument et
  faisait pointer les candidats de balayage vers la racine du filesystem au lieu d'échouer en 64 ;
  la valeur vide est désormais rejetée au même titre que l'absence de valeur.

### Durci
- Commentaire de portée du `try/except` du bloc Python de `check-hook-paths.sh` resserré : il ne
  couvre que l'ouverture + le parsing d'un fichier, jamais la boucle de constat qui suit (protégée
  seulement par des gardes `isinstance`).
- `test-check-hook-paths.sh` — T9 aligné sur la garde de portabilité déjà appliquée par T12 dans le
  même fichier (SKIP nommé si `python3` est indisponible, plutôt qu'un échec par absence de
  commande). T3 (« code 2 jamais émis ») étend son agrégation aux codes de retour de T6/T6H, omis
  jusqu'ici.
- `test-vf-portable.sh` — T12 (identité du bloc localisateur `vf-portable:locator`) couvre désormais
  4 consommateurs réels (ajout de `check-hook-paths.sh`, jusqu'ici absent du décompte en dur).

### Documentation
- `docs/ADR.md` §ADR-071 — addendum daté et attribué (approbation humaine du 2026-08-15) documentant
  la dérogation de `check-hook-paths.sh` à sa propre règle (`command` en nom nu littéral, paradoxe
  d'amorçage), jusqu'ici motivée dans le code et le contrat de sortie mais absente de l'ADR elle-même.
- `docs/HOOKS-CONTRAT-SORTIE.md` — en-tête et pied de document corrigés pour créditer la mise à jour
  de l'inventaire par le plan 30-09 (26e entrée), en plus du plan 30-04 d'origine.
- Deux `SUMMARY.md` manquants comblés (`30-02`, `30-07`) — reliquat de reprise du moteur (DAG `done`
  sans `SUMMARY.md`), contenu dérivé des commits réels de chaque plan.

## [v2.17.0] — 2026-08-16 (Phase 30 plan 30-09 — le filet de péremption des chemins de hook, addendum)

**Minor** (nouvelle capacité : un 5e signal SessionStart, pas un simple correctif). Addendum
approuvé le 2026-08-15, hors périmètre du cadrage d'origine de la Phase 30 : D-01 fait écrire, à
l'install, un chemin absolu d'interpréteur `bash` dans le `command` des 4 entrées `SessionStart`
existantes (décision **one-way**, assumée) — un angle mort silencieux que rien ne surveillait :
quand ce chemin devient périmé (interpréteur mis à jour, Git Bash réinstallé, machine changée), le
hook cesse simplement de tourner, sans erreur ni message.

### Ajouté
- **`check-hook-paths.sh`** — 5e signal `SessionStart` advisory (ADR-031) : relit les réglages
  réellement posés (`.claude/settings.json` et `.claude/settings.local.json`, scope projet et scope
  utilisateur), vérifie que chaque chemin absolu d'une entrée en forme exec existe et est
  exécutable, et le dit — brièvement (7 lignes maximum) sur constat, **strictement rien** (zéro
  octet stdout) sur le chemin nominal. Trois issues (silence, constat, « verdict non rendu » —
  jamais un faux PASS sur réglages illisibles), jamais le code 2.
- **Entrée de hook n°26**, `SessionStart` · `startup` : seule entrée du parc dont le `command` est
  un **nom nu littéral** (`bash`), jamais le jeton d'interpréteur substitué à l'install — paradoxe
  d'amorçage assumé (un filet qui dépendrait du chemin figé mourrait dans le cas qu'il détecte).
  **Dérogation à ADR-071 §Décision 2** (qui exige l'inverse, sans clause d'exception), **autorisée
  par l'approbation humaine de l'addendum du 2026-08-15 — pas par ADR-071 elle-même**, qui ne
  documente pas encore ce cas (reliquat : un amendement d'ADR-071, ou une ADR dédiée, est dû).
  Gardée à la machine par le cas T9 de `test-check-hook-paths.sh` (discriminance prouvée par
  mutation).
- **`docs/HOOKS-CONTRAT-SORTIE.md`** — inventaire durable porté à 26 entrées (5 dev-orchestrator,
  21 advisory au total), avec le paragraphe de dérogation de l'entrée n°26.
- **`plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh`** — 61e suite du dépôt, 12 cas
  (silence, constat sur `command`/`args`, illisible bruyant, les deux fichiers de réglages projet
  lus indépendamment, absence totale de réglages, parité d'interface, garde anti-« réparation » de
  l'entrée n°26, identité du bloc localisateur, aller-retour dans `merge-hooks.sh`, accord
  doc/parc), 4 mutations tracées.

## [v2.16.0] — 2026-08-16 (Phase 30 tâche 07 — les 4 hooks SessionStart passent en forme exec, PORT-02)

**Minor** (changement de forme des hooks + contrat de sortie, pas un simple correctif). Les 4
entrées `SessionStart` du fragment (`check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`,
`check-doc-drift.sh`, `check-gsd-config.sh`) passent de la forme shell (`bash … || true`) à la
forme exec (`command` = jeton d'interpréteur résolu en chemin absolu à l'install, `args` = chemin
du script + `--hook` en élément séparé) — même gabarit que `software-architecture` (migré au plan
`30-01`). L'opérateur d'absorption shell disparaît **par construction** : les 4 scripts traduisent
désormais eux-mêmes leur silence interne (contrat posé au plan `30-04`, voir
`docs/HOOKS-CONTRAT-SORTIE.md`) — plus jamais un `|| true` aveugle.

### Ajouté
- **Forme exec** sur les 4 entrées `SessionStart`, classées explicitement advisory (ADR-031) dans
  la description du fragment, avec renvoi au document de contrat de sortie.
- **ADR-071** (`docs/ADR.md`) : la doctrine de la forme exec pour le périmètre dev — chemin absolu
  résolu et vérifié à l'install (conséquence assumée : `settings.json` devient spécifique à la
  machine), contrat de sortie normalisé dans chaque script sans lanceur intermédiaire.
- **Preuve d'install réelle** (`plugin/_internal/tests/test-vibeflow-update.sh`) : les 5 entrées du
  périmètre dev sont exec TELLES QU'INSTALLÉES dans un lab temporaire (command absolu, exécutable,
  aucun placeholder résiduel), et un lab qui portait l'ancienne forme shell converge sans doublon à
  l'update.

### Compatibilité
- Un lab qui ne relance pas l'engine garde ses hooks en forme shell et ses anciens scripts :
  comportement attendu, pas une régression — la migration n'a d'effet qu'au prochain
  install/update.

Référence : `.planning/phases/VFDO-30-portabilit-windows-ii/30-07-PLAN.md`, PORT-02.

## [v2.15.0] — 2026-08-15 (Phase 28 — le gate d'activation ferme #38 et se prouve chez l'utilisateur)

**Minor** (nouvelle capacité, pas un simple correctif) : `check-capability-activation.sh` sait
désormais dire quand une **précondition écrite dans le plugin n'est pas armée chez
l'utilisateur** — la faille de fond de la régression #38, où la précondition
`worktree.baseRef: "head"` était identifiée, écrite, arbitrée et posée... dans le settings local du
dépôt de développement, jamais distribuée aux 13 agents qui en dépendaient. La question qui
n'avait jamais été posée n'était pas « la précondition existe-t-elle ? » mais **« qui l'écrit chez
l'utilisateur ? »**.

### Ajouté
- **Règle 4** — un armement de la liste close (`isolation`, `vf-mcp-consumer`, `vf-mcp-tools`)
  sans précondition distribuée rend le gate ROUGE, en nommant l'artefact, l'armement et
  `fichier:ligne`. Chaque armement d'un artefact est évalué **indépendamment** des autres
  (correction ciblée post-revue, Phase 28 : la fermeture initiale était mono-slot et ne
  confrontait à `vf-requires` que le premier armement rencontré par fichier).
- **Règle 4bis** — symétrique de la règle 4 : un `vf-requires` porté par un artefact **sans**
  armement de la liste close est halluciné, et rend rouge à son tour.
- **Jointure statique par identifiant** — `vf-requires:` côté artefact, `# vf-provides:` côté
  script (posé sur `inject-mcp-tools.sh`, `# vf-provides: mcp-servers`). Le gate confronte les
  deux littéraux, il n'exécute **jamais** le script cité.
- **5 déclarations `vf-requires: mcp-servers`** — `agents/vf-coder.md`, `agents/vf-reviewer.md`
  (ce module), plus les 3 agents de `mobile-test-team` (`vf-test-runner`, `vf-test-orchestrator`,
  `vf-app-fixer`).
- **Quatre planchers anti-vert-à-vide** (univers d'armement vide, corpus de preuve vide, index de
  capabilities vide, fermeture de modules dérivée sans le gate) — un gate qui ne peut rien balayer
  refuse de rendre un verdict conforme.
- **Cinq bornes déclarées** dans l'en-tête du gate (`-h`/`--help`) : ce que la liste close couvre
  et ne couvre pas, sans jamais introduire de seuil de nombre de lignes (interdit explicitement par
  le cadrage de la phase).
- **Job CI `lab-frais-arme`** (*as-installed testing*) — le gate tourne désormais **là où l'install
  le pose** (`.claude/scripts/`, fermeture `dev-orchestrator`, 9 modules), sur un univers
  d'armement non vide (`vf-coder.md` + `vf-reviewer.md`), jamais seulement sur l'arbre source. Sans
  ce job, la Phase 28 aurait prouvé la règle sur des fixtures et jamais sur ce que l'utilisateur
  reçoit.

Référence : issue #38.

## [v2.14.0] — 2026-08-15 (bullet contractuelle « NE charge PAS » + édition-à-la-source)

**Minor** (nouvelle capacité, pas un simple correctif) : le gabarit de digest de mission porte
désormais une bullet contractuelle que **tout mandat futur** émettra — c'est une extension du
contrat de dispatch entre manager et worker, pas une correction de comportement existant.

### Ajouté
- `references/mission-contracts.md` — bullet `- NE charge PAS : <périmètres gelés des autres
  nœuds en vol, dérivés de `dag.sh status --frozen`>` ajoutée au gabarit `DIGEST`, plus une
  sous-section « Composition du négatif (bullet « NE charge PAS », G1) » qui documente la source
  des données, l'opération (soustraction) et les deux cas dégénérés. Composée par le manager, en
  doctrine — zéro ligne touchée dans `plugin/conductor/scripts/dag.sh` (D-03).
- `references/team-kernel.md` §Règles d'instanciation — règle d'édition-à-la-source (G5) : seuil
  chiffré (deux occurrences du même verdict sur le même objet), sources légitimes énumérées
  (jamais le worker), comportement en mission autonome (consigner, pas amender), citant ADR-031.
- `references/mission-flow.md` — 1 ligne de renvoi vers la règle d'édition-à-la-source (Pattern E
  §2), sans reformulation.

`agents/vf-dev-manager.md` reste à 250/250 (ADR-029, non touché).

## [v2.13.1] — 2026-08-10 (correctif #38 — `isolation: worktree` retiré du frontmatter)

**Retrait d'`isolation: worktree` du frontmatter de `vf-coder`.** Livrée en v2.49.0
(Phase 27), la ligne rendait le worker de dev inutilisable dès qu'un manager mandatait une branche autre
que la branche par défaut : le worktree du harness fork depuis la **branche par défaut**, jamais
depuis le HEAD courant — il atterrissait sur une branche technique **sans aucun fichier du
mandat**, se déclarait bloqué sans produire, et le manager se rabattait silencieusement sur un
agent générique dépourvu de sa doctrine et de ses allowlists.

La précondition qui corrige le fork — `worktree.baseRef: "head"` — vit dans le settings du poste
et **n'est posée nulle part par l'engine** : elle avait été posée dans le settings local du repo
de développement, et les agents ont été distribués sans elle. Même corrigée, elle ne suffirait
pas : rien ne ramène les commits du worker vers la branche de mission (`open-gsd/gsd-core#3302`).

L'isolation redevient ce que la doctrine du kernel dit déjà qu'elle est — une **décision de
dispatch du manager**, jamais une propriété du worker. Désormais machine-enforced :
`check-agents.sh` refuse `isolation:` dans un agent distribué.

Référence : issue #38.

## [v2.13.0] — 2026-08-10 (les managers reçoivent la partition en étages, vf-coder passe en worktree)

### Ajouté
- **Doctrine `stages`** (`mission-flow.md`, Phase 27) — usage du champ `stages` de `dag.sh ready`
  par les managers : garantie (aucun recouvrement de `scope[]` intra-étage), non-garantie (les
  écritures non déclarées restent hors du contrat), dépendance dure (node + gsd-tools), repli
  (`stages: null` → frontière plate).
- **`vf-coder` armé `isolation: worktree`** — exécution isolée par worktree (groupe A, Phase 27) ;
  `worktree.baseRef: "head"` posé en précondition de sûreté avant l'armement.

### Modifié
- **`mission-contracts.md`** — fermeture du vecteur RCE par confinement de chemin (variante
  `toplevel`), propagation du fix ADR-070 de `dag.sh`.

## [v2.12.0] — 2026-08-04 (une entrée de doc ne promet plus un geste inerte)

### Ajouté
- **`check-capability-activation.sh`** (GSDA-09) — nouveau gate : la documentation du module pouvait
  annoncer une capability que rien n'activait, et le routage suffisait à la réputer vivante. Le gate
  relie chaque entrée de doc à l'**activation** réelle de la capability qu'elle promet. Il est
  **câblé au job `gates` de la CI** dès sa livraison — une garde que la chaîne d'intégration ne lance
  jamais est une garde absente, et ce gate existe précisément pour fermer ce mode d'échec ; le
  laisser invoqué par sa seule suite l'aurait reproduit sur lui-même. Aucune surcharge d'environnement
  en CI : la cascade de résolution est exercée telle qu'elle tourne chez l'utilisateur, et un exit 2
  (« non vérifiable ») échoue le job au même titre qu'un exit 1 — un gate qui ne peut pas se
  prononcer n'est pas un gate vert. Suite dédiée `test-check-capability-activation.sh`,
  discriminance prouvée dans les deux sens.
- **`references/workstreams.md`** — la voix unique du module sur le compartiment de planning
  (GSDA-10) : ce que GSD appelle un workstream, ce que le lab en fait, et **4 limites datées**. La
  couverture amont y est re-dérivée sous un critère **nommé** et une commande rejouable, pas sur un
  chiffre recopié.

### Modifié
- **`build-gsd-capabilities-index.sh`** — l'index porte enfin les capabilities **sans étage**
  (`graphify`, `profile-pipeline`), qu'il omettait purement et simplement. Il cesse aussi de
  **deviner** ses toggles et de sortir de son ancre. La table reste générée depuis le moteur installé,
  jamais écrite à la main.
- **`check-dev-bootstrap.sh`** voit un `.planning/` partitionné (GSDA-13) et consomme la politique de
  nom de workstream **partagée** (`planning-core/scripts/workstream-policy.sh`) au lieu d'en porter
  une copie ; son en-tête est réaligné sur ce qu'il fait réellement.
- **`references/GSD-PIPELINE.md` §10** — portée réelle du canal `agent_skills` (slot `PLANNER`
  câblé : la doctrine du lab atteint enfin `gsd-planner`) et **refus motivé de `tdd_mode`**.
- **`references/intent-routing.md`** — les trois routes conditionnelles sont marquées comme telles,
  et la frontière `codebase/` ↔ `intel/` est écrite. La capability `intel` est activée : la promesse
  de `--query` que notre doc publiait devient tenue.
- **`agents/vf-coder.md`, `agents/vf-dev-manager.md`** — les deux agents du chemin de dev savent dire
  sur quel chantier ils travaillent (câblage `--ws`, GSDA-08).
- **`references/docs-flow.md`**, `AGENT.md` et les 4 agents du module : `effort:` par rôle
  (pilotage et jugement `high`, exécution `medium`).
- **`test-dev-orchestrator.sh`** — le gate d'exhaustivité T14 interroge désormais l'**activation**,
  pas seulement le routage (+ T34, T35).

### Corrigé

- **`check-dev-bootstrap.sh` cesse de réimprimer le frontmatter d'une cible hors du lab**
  (`T-24-14-C1`, 4ᵉ passage du motif dans ce dépôt). `[ -d ]` **suit le lien symbolique** : un
  `.planning/workstreams/<nom>` versionné en mode `120000` vers un répertoire hors du lab faisait lire
  le compartiment de la **cible** et réimprimer son frontmatter — « milestone *valeur de
  l'attaquant* » — sur le **stdout d'un hook `SessionStart`**, donc sans aucune action de la victime.
  La résolution passe par les primitives partagées de `planning-core` (`vf_ws_dir_resolve` /
  `vf_ws_file_in_ws`), qui **refusent de traverser** au lieu de tenter de décider si la cible est
  « dans le lab ».

  **Rôle injecteur** (gradation déjà déclarée par la politique) : repli sur la racine, **jamais
  muet** — un exit non nul dégraderait toutes les sessions, un silence masquerait le refus — et la
  cible n'est ni lue ni nommée. Le garde `ws_readable` s'applique à `ROADMAP.md` **et** à `STATE.md`,
  et c'est sur ce dernier qu'il compte le plus puisque c'est lui qui alimente la réimpression.

  **Le chemin nominal reste inchangé à l'octet près** : `WS_SCOPED` n'est armé que lorsque la lecture
  a quitté la racine pour un compartiment — hors compartiment, aucune indirection n'a été introduite,
  donc rien à contrôler et aucun verdict qui bouge. Fermeture prouvée **par mutation sur les quatre
  gates à la fois** (`plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh`).

## [v2.11.1] — 2026-08-04 (l'index des skills cesse de mentir sur sa propre provenance)

### Corrigé
- **`build-gsd-index.sh`** — la version du moteur affichée en en-tête de `gsd-skills-index.md`
  était un **littéral figé** (`@opengsd/gsd-core@1.9.0`). Le moteur est passé à 1.9.1 sans que
  l'index le sache : un fichier auto-généré, versionné, qui affirme une provenance fausse. Deux
  torts distincts — le numéro est faux, et le figer contredisait frontalement la doctrine que le
  script voisin `build-gsd-capabilities-index.sh` énonce dans son propre en-tête (« aucune
  version de moteur n'est figée dans la logique »).

  La version est désormais **lue** sur le moteur résolu, selon une règle unique : le moteur est le
  dossier parent de la source de workflows déjà résolue par la cascade dual-layout — donc la
  version décrit toujours l'arbre d'où sortent réellement les entrées de l'index, y compris quand
  `VF_GSD_WORKFLOWS_DIR` le déplace. Aucune deuxième cascade à maintenir.

  Trois conduites de bord, toutes tenues par des tests : VERSION absente ou illisible → l'en-tête
  **dit** « (version inconnue) » au lieu d'affirmer un numéro ; VERSION non maîtrisée (lecture
  bornée à 200 octets + classe de caractères restreinte, port du garde de `check-gsd-engine.sh`,
  T-19-01-04) → neutralisée, jamais évaluée ; disposition **legacy** → l'index nomme
  `get-shit-done-cc`, il ne maquille pas un moteur legacy en `@opengsd/gsd-core`.

### Ajouté
- **`test-dev-orchestrator.sh` T1e/T1f** — 4 cas sur la provenance de l'en-tête. T1e est
  DISCRIMINANT par construction (fixture `9.9.9-fixture` : aucun littéral plausible ne la
  contient). Preuve de discrimination faite : 4 KO avec la version figée, 165 OK / 0 KO après.

### Vérifié (rien à changer)
- **Couplage `@opengsd/gsd-core` 1.9.1** — le plafond `^1` de `ensure-deps.sh` couvre 1.9.1 ;
  `--claude`, `--global`, `--local` existent tous dans l'installeur 1.9.1 ; les commandes
  appelées (`loop render-hooks`, `state`, `state record-session`, `roadmap analyze`) sortent en 0.
  Les capabilities **déclarées** sont identiques entre 1.9.0 et 1.9.1 (index régénéré depuis le
  registre de chacun des deux tarballs : 12 points de hook, 35 étages, sortie identique) — le
  delta amont porte sur les runtimes non-Claude et un troisième registre de découvrabilité, pas
  sur le contrat consommé ici.

## [v2.11.0] — 2026-08-04 (couplage explicite au moteur GSD — capabilities, flags, voie unique, Phase 23)

Couplage explicite du module au moteur `@opengsd/gsd-core` : un gate qui vérifie que ce que le lab
déclare correspond à ce que le moteur installé sait faire, une table de capabilities générée depuis
le moteur plutôt que recopiée à la main, une doctrine de flags de cycle qui ferme par défaut plutôt
que d'ouvrir par omission, et une voie unique d'invocation des briques Plan/Exécution.

### Ajouté
- **`check-gsd-config.sh`** — gate d'alignement de configuration entre `.planning/config.json` du
  lab et les capabilities réellement exposées par le moteur `@opengsd/gsd-core` installé. Contrat
  d'exit `0` (aligné) / `3` (INDÉTERMINÉ, silence attendu sur un lab conforme) / `64` (usage), avec
  sa suite dédiée `test-check-gsd-config.sh`.
- **`build-gsd-capabilities-index.sh`** et sa sortie auto-générée
  `references/gsd-capabilities-index.md` — table de capabilities dérivée du moteur installé plutôt
  que recopiée à la main, fermant la classe de dérive « le lab affirme une capacité que le moteur
  n'a plus ».
- **Doctrine de flags de cycle** — `GSD-PIPELINE.md` §9, allowlist stricte des flags de cycle avec
  clause de fermeture par défaut (un flag absent des trois sources amont n'a aucune valeur, il n'est
  jamais lu `false` par confort).
- **Doctrine de voie unique (D-09/D-10)** — nouvelle sous-section « Voie unique d'invocation » dans
  `GSD-PIPELINE.md` §9 : les briques Plan/Exécution ne sont atteintes que par le skill amont, jamais
  par dispatch direct d'un agent nu ; la reprise après checkpoint reste un nouveau worker par la voie
  skill, sans exception.
- **Table des moments déclencheurs des briques dormantes** — les quatre briques D-22/D-23/D-24 et
  leurs déclencheurs, câblée au contrat de checkpoint.
- **Quatre champs optionnels du bloc typé** — `gate`, `reprise`, `verdicts`, `decompte`, relayés par
  `vf-coder` et `vf-dev-manager` sans jamais devenir une statistique auto-évaluée.
- **Blocs de test neufs de `test-dev-orchestrator.sh`** — **dix blocs principaux, `T24` à `T33`**,
  étendus par **huit sous-blocs nommés** (`T25 ATTEINTE`, `T25c`, `T26 F`, `T26 E'`, `T27b`, `T27c`,
  `T28-H/I/J/K`, `T28 ATTEINTE`). Numérotation volontairement non monotone dans le fichier (`T33`
  vit entre `T27c` et `T28`, réservé par 23-03, choix consigné au SUMMARY de 23-07).

### Modifié
- **Contrat de checkpoint** — mapping unique vers l'escalade, une seule voix pour ce que fait un
  checkpoint plutôt qu'une déclinaison par brique.
- **Budget de tours** — devenu partagé **par étape** plutôt que par brique individuelle.
- **`mission-flow.md`** — ligne du cycle canonique sur la brique de livraison, Pattern E budget
  partagé, section briques dormantes.
- **`docs/ADR.md` ADR-061** — étendue d'un troisième objet revu.
- **`.planning/config.json` du lab** — `ui_review` explicitement écrit `false` (ce dépôt est un
  plugin de distribution bash + markdown, sans aucune surface d'interface ; le toggle n'ayant de
  valeur nulle part, l'étage `ui-review` était accidentellement inactif faute de valeur — pas
  délibérément fermé ; l'écrire transforme l'omission en décision).

### Retiré
- **La voie dégradée de dispatch d'agent nu dans le worker** — deux entrées d'allowlist retirées :
  - `gsd-planner`/`gsd-executor` de l'allowlist `tools:` de `vf-coder` : dispatch direct des agents
    nus de cycle fermé (D-09/D-11/D-12) — la voie unique d'invocation des briques Plan/Exécution est
    désormais le skill, seul, avec ses dix étages de contrôle.
  - `gsd-planner` de l'allowlist `tools:` de `vf-dev-manager` : lecture littérale de D-09
    (interdiction sans qualificatif d'agent) + Finding 1 du RESEARCH — le manager ne code, ne teste
    ni n'audite jamais lui-même, et rien dans son prompt ne mobilisait cette entrée.

  Arbitrage tranché en tête du plan 23-05 : D-09 est formulée sans qualificatif d'agent, la doctrine
  du manager dit noir sur blanc qu'il ne code/teste/audite jamais lui-même. Retrait ponctuel et
  nommé, l'audit complet des 20+ entrées restant explicitement différé.

⚠️ **Écart ouvert, non couvert par ce retrait** : `gsd-debugger` reste dans l'allowlist `tools:` de
`vf-coder.md` et reste exigé par le gate `CODER_ALLOWED` (`T19`) — `D-22` (« aucun `gsd-debugger` en
allowlist, aucune exception ») n'est donc pas vraie en machine sur ce point. Arbitrage reporté à
Samuel, voir le SUMMARY 23-08.

Référence : `.planning/phases/VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-/`.

## [v2.10.0] — 2026-07-31 (alignement gsd-core 1.9.0, Phase 21)

### Ajouté
- **`inject-mcp-tools.sh` découvre les serveurs MCP en UNION de deux scopes** : `./.mcp.json`
  (projet) **et** `~/.claude.json` clé top-level `mcpServers` (utilisateur/global, `--claude-json`
  ou `VF_CLAUDE_JSON`). Corrige le défaut actif ADR-051 sur tout poste sans `.mcp.json` — un
  serveur déclaré uniquement en scope global (ex. XcodeBuildMCP) était jusqu'ici invisible,
  `--verify` sortait en `3` INDÉTERMINÉ au lieu de signaler l'écart. Dégradation indépendante par
  source, précédence projet > global sur collision, `--strict` signale un nom de serveur cité mais
  inconnu de toutes les sources découvertes (WINDOWS #4 clos).
- **`vf-coder` et `vf-dev-manager` relaient verbatim le contrat `estimate:`/`actuals:` amont**
  (ADR-2629, #2632) : deux champs optionnels frères du bloc typé ADR-053, jamais une statistique
  agrégée du cru de l'agent, absents du rapport si absents en amont.
- **Purge de la dette de version 1.8.0 → 1.9.0** : `gsd-skills-index.md` régénéré,
  `mission-contracts.md`, `check-gsd-engine.sh`, `build-gsd-index.sh` citent désormais 1.9.0. Le
  piège de préservation (cas 8 de `test-check-gsd-engine.sh`, qui asserte la chaîne littérale de
  version dans l'en-tête) a été déplacé avec le texte qu'il vérifie, jamais neutralisé.
- **`team-kernel.md`** documente l'hypothèse datée du dispatch nommé (`hostIntegration.dispatch.namedDispatch`,
  amont 1.9.0) et le recoupement vérifié conforme avec `gsd-worktree-path-guard.js` (#1995, #2608).

Référence : `docs/ADR.md` ADR-061 (recouvrement lanes de revue amont vs étage 20-06), ADR-062
(hooks 1.9.0 non câblés), `.planning/phases/VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0/`.
## [v2.9.0] — 2026-07-31 (hygiène documentaire — doctrine de sortie et captation d'intention, Phase 22)

**La doctrine documentaire avait une entrée (`ingestion-flow.md`) mais pas de sortie. Elle en a
désormais une, symétrique, et les deux managers de mission savent quand la déclencher.**

### Ajouté
- **`references/docs-flow.md`** (111 lignes) — la doctrine de sortie documentaire, strictement
  symétrique d'`ingestion-flow.md` : table de discernement des **quatre familles** documentaires
  que GSD outille séparément (produit / code / savoir / entrée par renvoi), une section par
  famille traitée en propre, et un **renvoi** — jamais une copie — vers `ingestion-flow.md` pour
  la famille entrée (ADR-057).
- **Trois régimes de confirmation gradés par le risque réel** : `--verify-only` libre (read-only,
  ne rien écrire ne demande rien), génération sous confirmation (elle commite), et `--force`
  autorisé sur intention explicite mais borné par l'annonce en trois temps de ce qui sera écrasé
  — les trois notions tiennent sur une seule ligne rouge, jamais dispersées.
- **La captation d'intention distingue désormais auditer / générer / régénérer** en langage
  naturel, avec un protocole de désambiguïsation à quatre ancrages contextuels quand la
  formulation est creuse (`AGENT.md` + `references/intent-routing.md`), et le flag
  `--verify-only` — qui répondait déjà à une intention distincte — est exposé pour la première
  fois comme geste par défaut sur signal `[doc-drift]`.
- **Le nœud `docs` agrégé** posé en fin de mission par `vf-dev-manager` (et son homologue
  `vf-design-manager` côté `design-orchestrator`, par renvoi cross-module) sur quatre
  déclencheurs factuels nommés : surface publique touchée, signal `[doc-drift]` actif, nouveau
  module ou nouvelle capacité — jamais un nœud par commit.
- **Bloc T22/T23** de `test-dev-orchestrator.sh` — la doctrine et son routage machine sont
  gardés (T22), le câblage des deux managers est non-régressable, discriminant par mutation, avec
  `SKIP` si le module design est hors du périmètre scanné (T23). Aucune suite nouvelle : le
  compteur « N suites » des deux README racine reste à 44.

### Non modifié (volontaire)
- **`scripts/check-doc-drift.sh` n'a pas bougé** (D-13) : le script constate le **fait** (N
  commits de code sans commit de doc), la nouvelle doctrine porte le **jugement** sur ce qu'on en
  fait. Les deux responsabilités restent séparées (ADR-055 §3).

Référence : `.planning/phases/VFDO-22-hygi-ne-documentaire-doctrine-de-sortie-et-captation-d-inten/`.

## [v2.8.0] — 2026-07-31 (fluidité du flux de dev sans perte de qualité, Phase 20)

**Changement de contrat pour quiconque dispatche `vf-coder` : son cycle passe de 4 à 3 étapes,
il ne dispatche plus `vf-reviewer`.**

### Ajouté
- **Mode d'injection MCP nommé** dans `inject-mcp-tools.sh`, déclenché par la clé de frontmatter
  `vf-mcp-tools` (grammaire `<serveur>:<outil1>,<outil2>,…`) : injecte UNIQUEMENT les tokens
  nommés d'un serveur, jamais le joker `mcp__<serveur>__*` du mode existant — les deux modes
  coexistent par fichier (le nommé l'emporte, moindre privilège). `--verify` réutilise le même
  calcul et rend un 3e verdict INDÉTERMINÉ quand le serveur nommé n'est pas résolu.
- **`vf-reviewer` porte l'accès MCP nommé** (`XcodeBuildMCP:test_sim,build_sim,clean`) et son
  protocole de vérification outillée : nettoyage avant toute compilation de vérification,
  paramètres de projet explicites à chaque appel (le serveur maintient un état de session global
  partagé), honnêteté quand le serveur est absent. Coût assumé : ~90s et un slot de simulateur.
  Voir `docs/ADR.md` ADR-051 (révisée), qui documente ce mécanisme.
- **L'étage revue devient un nœud de plan de bataille de premier rang, posé systématiquement par
  le manager et dispatché en direct** (`mission-flow.md` §Pattern E, `docs/ADR.md` ADR-060) : la
  boucle de correction migre vers le manager (mandat ciblé) ; gradation sur 4 déclencheurs
  objectifs (jamais le volume) avec défaut sûr ; revue de jointure obligatoire déclenchée par la
  topologie du DAG ; garde-fou de comblement adossé au champ machine `review_regime` (`dag.sh
  reopen`). La règle `vf-dev-manager.md:108` (« Pas de double revue ») est réécrite en place, pas
  contournée par une exception.
- **`vf-coder` : cycle réduit à 3 étapes** (cadrage → plan → exécution), ne dispatche plus
  `vf-reviewer` et ne reçoit plus de verdict de revue en retour ; allowlist `tools:` inchangée
  caractère pour caractère.
- **`vf-dev-manager` lit `.planning/MISSION-INVARIANTS.md`** au même rang que l'état du projet, et
  porte le filet de repli sur `AskUserQuestion` absent au runtime en dispatch sous-agent (le
  besoin humain remonte dans le rapport typé, jamais auto-répondu en silence).

Référence : `docs/ADR.md` ADR-051 (révisée), ADR-060 (nouvelle),
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v2.7.1] — 2026-07-28 (isolation de branche des missions d'équipe, ADR-059)

**Une mission d'équipe ne commite plus jamais sur la branche par défaut.** Dès qu'un manager est
dispatché, il crée sa branche **avant son premier commit**, y tient tous ses commits, et termine par
une **PR laissée ouverte** — le merge appartient à l'utilisateur (ADR-031). Le travail
conversationnel direct (correctif, doc, cadrage mené dans le fil) reste hors de la règle.

**Origine** : constaté sur le dépôt VibeFlow le 2026-07-28 — la mission Phase 19 a produit **32
commits directement sur `main`**, poussés puis taggés. Aucun dégât, mais le recours en cas de mission
ratée était un `revert` en masse d'un historique déjà public. Sur une branche, le recours est de ne
pas merger. La PR fournit en prime le point de relecture groupée qu'un rapport de fin de mission — 
rédigé **par** l'agent qui a fait le travail, et lu trop tard — ne remplace pas.

**Cinq replis, pour qu'une mission n'échoue jamais faute d'appliquer la règle** : pas de dépôt git →
aucune branche, signalé ; pas de remote → branche sans PR ; `gh` absent → branche poussée et URL de
création de PR donnée ; **arbre sale au démarrage → halt condition**, jamais un `stash` décidé seul ;
`CLAUDE.md` du projet cible imposant un autre flux → le projet cible **prime**.

**Ne couvre pas** : l'isolation des vagues parallèles **à l'intérieur** d'une mission, qui partagent
le même arbre de travail — seul `isolation: worktree` le ferait. Décision distincte, laissée ouverte.

Fichiers : `references/mission-contracts.md` (§Isolation de branche — protocole, conventions de nom,
table des replis) · `agents/vf-dev-manager.md` §Garanties.

## [v2.7.0] — 2026-07-28 (migration du moteur GSD pilotée par /vf-update, Phase 19)

### Ajouté
- **`scripts/check-gsd-engine.sh`** (nouveau) : gate de constat à 3 états
  (absent/legacy/gsd-core), lecture seule, exits `0`/`2`/`3` — classement décidé exclusivement sur
  la présence des fichiers `VERSION` du poste, jamais sur leur numéro (le legacy `get-shit-done-cc`
  figé à `1.42.3` reste actionnable même face à un `@opengsd/gsd-core` `1.8.0`, malgré
  `1.8.0 < 1.42.3` en semver). Signal `[gsd-migrate]` pour l'état actionnable, `[gsd-leftover]`
  pour le cas dual gsd-core + reliquat legacy (rupture assumée de « exit 3 == silence »).
- **`scripts/tests/test-check-gsd-engine.sh`** (nouveau) : suite dédiée, 15 cas en boîte noire,
  verte macOS et Linux (`ubuntu:24.04`).
- **`ensure-deps.sh` : `detect_gsd()` cesse de skipper le legacy**. `detect_gsd_state()` rend un
  état à 3 valeurs ; un moteur legacy est désormais **signalé** (jamais migré sans autorisation) au
  lieu d'être silencieusement sauté. Nouveau chemin **`--migrate-engine`**
  (+ `VF_ENSURE_MIGRATE_ENGINE=1`) qui enchaîne, dans le même run, l'install `npx` existante
  (plafond `@opengsd/gsd-core@^1` intouché) puis `patch_gsd_executor_mcp()` — la ré-injection MCP
  ne peut donc plus être oubliée après une migration.
- **Message de nettoyage legacy corrigé** : l'état legacy est capturé **avant** toute install
  (l'installeur amont supprime lui-même son propre témoin `VERSION` à l'install réussie — le
  message survit désormais à cette suppression) ; les deux lignes `npm uninstall -g` ne sont
  proposées que si `npm ls -g` confirme réellement le paquet installé en global ; le retrait de
  l'arborescence vide laissée debout est ajouté à la proposition (toujours affiché, jamais exécuté
  — ADR-031).
- **`scripts/inject-mcp-tools.sh` : mode `--verify`** (nouveau) — relit le `tools:` final de la
  cible et le compare aux serveurs dérivés du `.mcp.json` du lab, exits `0`/`1`/`3` (jamais un faux
  vert si python3 est absent) ; dit fort un serveur manquant, ne répare jamais. Branché en
  best-effort dans `patch_gsd_executor_mcp()`, après l'injection, hors dry-run uniquement.

### Corrigé
- **`patch_gsd_executor_mcp()` : `--verify` portait sur une cible différente de l'injection.**
  L'appel d'injection (ligne ~394) passait `--force` (requis : `gsd-executor.md` ne porte pas le
  flag `vf-mcp-consumer`, fichier hors plugin) mais l'appel `--verify` (ligne ~409) en était
  dépourvu — `inject-mcp-tools.sh` écartait alors systématiquement la cible en mode fichier unique
  (`single and not force and not has_flag(text)`), rendant le verdict **toujours** `3`
  (INDÉTERMINÉ), jamais `0` (conforme) ni `1` (écart réel) : un garde-fou qui ne pouvait jamais
  rendre de verdict. `--force` ajouté sur l'appel `--verify`, même cible que l'injection.
- **Contrat de relais F13** : seul `rc=1` (écart réel, serveur manquant) est désormais relayé en
  `ERROR` sur stderr. `rc=3` (INDÉTERMINÉ — `.mcp.json` absent, aucun serveur déclaré, rien à
  comparer) n'est **plus** une alarme bruyante à chaque bootstrap ; il passe en `log` informatif.
  `rc=0` (conforme) ne logue plus rien. Preuve de létalité : suppression du bloc `--verify` →
  1 KO nouveau (`test-dev-orchestrator.sh` T2m) contre 0 KO avant, sur une mutation qui survivait
  jusqu'ici silencieusement (les cas T10/T11 de `test-inject-mcp-tools.sh` exerçaient
  `--force --verify` directement, une forme que la production n'émettait jamais).
- **`test-dev-orchestrator.sh` T2m (nouveau)** : exerce le chaînage réel de
  `patch_gsd_executor_mcp()` (jamais un appel manuel à `inject-mcp-tools.sh --force --verify`) —
  stub d'injection silencieusement no-op + vrai injecteur en `--verify`, pour produire un écart
  réel (`rc=1`) déterministe et portable (root Docker Linux contourne les permissions fichier,
  écarté comme moyen de test).
- **`test-dev-orchestrator.sh` T2n (nouveau)** : couvre l'autre moitié du contrat F13 — `rc=3`
  (rien à comparer) ne lève jamais d'alarme `[ensure-deps] ERROR:`, dans le même chaînage réel que
  T2m. Comblait une mutation survivante (`rc=3` re-alarmé, `log` → `err`) qui passait sur les trois
  suites du gate.

### Fait mesuré
- Audit externe du 2026-07-28 : sur un poste où le plugin VibeFlow était déjà à jour, le moteur GSD
  était resté sur `get-shit-done-cc` (paquet déprécié, figé à `1.42.3`) sans qu'aucun signal ne le
  dise — le chemin de mise à jour nominal (`/vf-update`) ne consultait jamais l'état du moteur.
- Vérification goal-backward Phase 19 (mandat n2-bis, 2026-07-28) : gap sur la 2e clause du
  critère de succès SC3 — voir « Corrigé » ci-dessus.

Référence : `docs/ADR.md` ADR-058, `.planning/phases/VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update/`.

## [v2.6.0] — 2026-07-27 (signaux de démarrage du moteur de dev, Phase 17)

### Ajouté
- **Premier fragment `hooks/hooks.json` du module** : `SessionStart:startup`, 3 commandes
  tolérantes à l'échec (`|| true`) — `dev-orchestrator` était le seul module structurant sans
  hooks, `discover-unintegrated-docs.sh` (livré Phase 13) n'était donc jamais appelé
  automatiquement.
- **`scripts/check-dev-bootstrap.sh`** (nouveau) : continuum à 4 états mutuellement exclusifs
  (silence / `[onboard]` / `[bootstrap]` / `[gsd-engine]`), premier qui matche gagne — brownfield
  non initialisé, bootstrap incomplet (items `config`/`codebase`/`roadmap` restitués en ordre
  figé), et orientation moteur GSD lue depuis le frontmatter assaini de `.planning/STATE.md`
  (liste blanche stricte, soupape de sûreté D-04). Contrat de sortie 0/3/64, lecture seule.
- **`scripts/check-doc-drift.sh`** (nouveau) : dérive documentaire — commits de code depuis le
  dernier commit ayant touché `docs/**` ou un `README*` racine, seuil réglable `--threshold`
  (défaut 20). Premier script du module à shell-out vers git, durci systématiquement
  (`core.fsmonitor=`, `core.hooksPath=/dev/null`, `--no-optional-locks`, variables
  `GIT_CONFIG_NOSYSTEM`/`GIT_TERMINAL_PROMPT`/`GIT_OPTIONAL_LOCKS`).
- **`scripts/discover-unintegrated-docs.sh --hook`** (extension additive) : ligne agrégée
  `[docs-ingest] N documents…` au lieu de la liste — le contrat historique (`grain<TAB>chemin`,
  exits 0/3/64, sans `--hook`) reste strictement inchangé, prouvé non-régressif octet pour octet.
- **3 nouvelles suites de test** : `test-check-dev-bootstrap.sh` (23 assertions),
  `test-check-doc-drift.sh` (21 assertions, fixtures git réelles), extension de
  `test-discover-unintegrated-docs.sh` (16 cas historiques + 6 cas `--hook`, 22 au total).
- **`AGENT.md`** : section « Signaux de démarrage » (4 lignes : `[bootstrap]`, `[onboard]`,
  `[gsd-engine]`, `[doc-drift]` → geste proposé, confirmation ADR-031) — `[docs-ingest]` reste
  couvert par la table « Amont & cadrage » existante, pas de doctrine parallèle.
- **`test-dev-orchestrator.sh` : axes T20/T21**, fermant le gate ADR-044 (T20, `check-agents.sh
  --file` sur `AGENT.md`, triple assertion exit/compte-warnings/types) et les invariants SC5
  (T21, grep structurel sur les 2 nouveaux scripts — aucun `exit 1`, aucune écriture hors
  `/dev/null`/descripteur/variable `*TMP*`, tout `mktemp` apparié à un `trap ... EXIT`). Suite
  portée à **60 axes** (0 KO), ramassés par la découverte générique de `ci.yml:32` sans édition.
- Portabilité prouvée en conteneur `ubuntu:24.04` (bash 5.2, git 2.43, python3 3.12) avant push,
  en plus de macOS.

Référence : `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`.

## [v2.5.0] — 2026-07-27 (allowlists `Agent(...)` sur les 3 workers internes, Phase 16)

### Ajouté
- **Allowlists `Agent(...)` posées sur les 3 workers internes**, fermant le chemin indirect
  manager → worker → manager : `vf-coder` (**22 noms**), `vf-reviewer` (**1** — `gsd-code-reviewer`),
  `vf-auditer` (**1** — `gsd-security-auditor`). Aucun manager (`vf-dev-manager`,
  `vf-design-manager`) ne figure dans aucune des trois listes. Recensement obtenu par **deux
  dérivations indépendantes** réconciliées : la couche décisive est celle des agents dispatchés
  par les **skills** que ces workers invoquent — aucune skill ne déclarant `context:`, ses
  `Task(...)` internes s'exécutent sous l'allowlist de l'agent appelant.
- `references/mission-cross-team.md` : les passages qui décrivaient ces workers comme gardant un
  `Agent` non scopé sont corrigés pour refléter le cloisonnement désormais posé.
- `agents/vf-coder.md` : l'échappatoire « dispatche l'agent équivalent via Task » devient
  « parmi les agents listés dans ton champ `tools:` ; sinon remonte `blocked` » — sans cette
  précision, une allowlist fermée transformait silencieusement une permission documentée en refus
  muet.

### Tests
- Axes **T19 → T19f** : allowlist nom par nom (extraction bornée à l'intérieur d'`Agent(...)`),
  absence de manager, aucun `Agent` nu, parenthèses correctement refermées (comptage de
  profondeur), `general-purpose` nommément testé (cadrage non-interactif de `vf-coder`), garde
  anti-homonyme (un nom préfixe littéral d'un autre ne le valide jamais). Suite **50 → 51 axes**.

## [v2.4.0] — 2026-07-27 (étages croisés dev ↔ design, Phase 15)

### Ajouté
- **Étage design croisé** : `vf-dev-manager` peut désormais dispatcher `vf-crafter` (nœuds
  `craft:<écran>`) avant l'exécution d'une étape à dominante UI, et `vf-design-judge` (nœuds
  `critique:<écran>`) en parallèle de la revue code — sans jamais dispatcher
  `vf-design-manager` (cloisonnement manager→manager porté par le verrou de driver). Nouvelle
  référence `references/mission-cross-team.md` (doctrine des étages croisés) et « Pattern D »
  documenté dans `mission-flow.md`.
- `references/mission-contracts.md` : deux nouveaux champs de brief — `design: auto|force|off`
  (défaut `auto`) et `livrable: specs|specs+implementation` (défaut `specs`) — et digest de
  mission enrichi pour les mandats croisés.
- `skills/vf-auto/SKILL.md` : aiguillage corrigé — une mission entièrement design part vers
  `Task(vf-design-manager)`, toute mission mixte ou dev vers `Task(vf-dev-manager)` (corrige un
  chemin de dispatch mort : la description publiée de `vf-design-manager` annonçait déjà ce
  routage).
- Allowlist `Agent(...)` de `vf-dev-manager` portée à 18 noms (cloisonnement Pattern 12) ;
  descriptions de `vf-coder`/`vf-reviewer` élargies au dispatch par les deux managers.
- Suite de tests : T18/T18b (cloisonnement par allowlist `Agent(...)`, doctrine d'étage design,
  routage `vf-auto`).

## [v2.3.2] — 2026-07-27

### Corrigé
- `tests/test-dev-orchestrator.sh` T2b : stub CLI `claude` posé en tête de PATH pour les invocations dry-run — le test observait les commandes loguées mais dépendait de l'outillage réel de l'hôte : sur une machine sans `claude` (runner CI), `ensure_superpowers` basculait en « étape manuelle » sans loguer `--scope <scope>` et les 4 assertions échouaient à tort. Reproduit sous ubuntu:24.04.

## [v2.3.1] — 2026-07-26

### Sécurité
- Plafond semver sur l'install GSD : `@opengsd/gsd-core@^1` au lieu de `@latest` (arbitrage
  post-audit Phase 11) — fraîcheur conservée dans la majeure 1.x, mais un saut de majeure
  (breaking ou compromission d'un fork jeune) ne s'installe jamais sans décision humaine.

## [v2.3.0] — 2026-07-26

### Ajouté
- **Bascule `@opengsd/gsd-core`** (Phase 11, intégration migration GSD) : `ensure-deps.sh`
  installe désormais le paquet npm `@opengsd/gsd-core` (dual-layout — `gsd-core` prioritaire,
  `get-shit-done` legacy en repli, jamais de test PATH pour la détection — piège n°1
  neutralisé), garde Node ≥ 22 (`@opengsd/gsd-core` cible Node 22+, message d'erreur explicite
  sinon), nettoyage des artefacts legacy **affiché mais jamais exécuté** (ADR-031) quand
  `~/.claude/get-shit-done/` est détecté au prochain run.
- Migration des références internes `gsd-sdk` → `gsd-tools` (cascade de résolution documentée
  dans `references/mission-contracts.md`, jamais un chemin en dur).
- Routage `gsd-onboard` sur brownfield (FIRST-02) avec fallback si l'engine n'est pas encore
  posé.
- Canal 4 de la carte d'intention : `gsd-next`, `gsd-mempalace-*` explicitement **non routés**
  (documentés pour mémoire, pas d'invocation directe depuis l'agent).
- Index factuel `gsd-skills` régénéré (gsd-core 1.8.0).

**Note de transition (labs existants)** : un lab encore sur l'ancien layout `get-shit-done`
verra `ensure-deps.sh` **afficher** (jamais exécuter) 3 commandes de nettoyage manuel au
prochain run — aucune action automatique sur les artefacts legacy, confirmation humaine requise.

**Note de veille (décision D5, amendement recherche documentaire vague 11-02)** : à chaque bump
de `gsd-core`, re-différer l'ordre de la cascade de résolution `gsd-tools` documentée dans
`mission-contracts.md` contre `gsd-core/workflows/_runtime-launcher.snippet.sh` amont — le
mapping peut évoluer entre versions du paquet.

## [v2.2.1] — 2026-07-26

### Corrigé
- Échappatoire ADR-031 fermée sur l'ingestion (finding de l'audit BRDG-03) : `vf-dev-manager`
  porte désormais une ligne **nominative** dans ses exceptions d'autonomie — l'ingestion d'un
  cadrage (`gsd-ingest-docs` / `gsd-import`, doctrine `ingestion-flow.md`) remonte TOUJOURS à
  l'utilisateur, jamais déclenchée depuis une mission sans confirmation humaine explicite.
  La protection n'était jusqu'ici ancrée textuellement qu'à `vibeflow-dev`.

## [v2.2.0] — 2026-07-26

### Ajouté
- Câblage de l'ingestion (BRDG-01/BRDG-03) dans `vibeflow-dev` — doctrine
  `references/ingestion-flow.md` (découverte via `discover-unintegrated-docs.sh` livré par la
  phase 13/plan 13-01, construction du manifest, délégation `gsd-ingest-docs --mode merge` /
  `gsd-import --from`, garde-fous BLOCKER/ADR-031/mode merge/cap 50), next step proposé en fin de
  cadrage (spec/plan écrit(e) non encore dans la feuille de route), axes de test T16/T17.

## [v2.1.1] — 2026-07-26

### Corrigé
- Recette dev en lab sandbox : cascade `$S` — le lab courant prime sur le scope user (divergence de version silencieuse) et les deux énoncés sont alignés ; doctrine `human_needed` en autonome tranchée (geler le nœud porteur, jamais « continuer ») ; fallback documenté si `gsd-sdk` absent ; les 3 exceptions de routage écrites dans la carte ; `requires` += `conductor` (team-kernel).

## [v2.1.0] — 2026-07-25

### Ajouté
- Pipelining N/N+1 : modélisation fine du DAG (discuss/plan/execute par étape), cadrage+plan de l'étape suivante pendant l'exécution de la courante, règle du plan provisoire re-validé par le plan-checker, garde-fou coût (≥ 2 étapes, jamais en mode superviser). dag.sh/driver-lock.sh consommés depuis le team-kernel du conductor (fallback conservé).

## [v2.0.0] — 2026-07-25

**BREAKING — bascule vers le modèle agentique** (spec
`2026-07-25-suppression-facade-vf-design.md`, arbitrage direct après l'audit croisé vague 2 :
la façade de verbes doublait un catalogue gsd-* qui reste exposé en session — la concurrence
de routage qu'elle prétendait résoudre était celle qu'elle créait).

### Supprimé
- **Les 29 verbes-façades `/vf-*`** (tout `skills/` sauf `vf-auto`, et `vf-dev` réduit à
  l'incarnation de l'agent) : les briques gsd-* redeviennent l'interface directe du quotidien,
  leurs descriptions déclenchent nativement, sans couche de synonymes.
- **La rule de préséance** (`rules/vf-verb-precedence.md`) et les matrices de renvois négatifs
  croisés entre descriptions — n'ont plus d'objet sans la façade.
- **Le reframe** (`vocabulary-map.md` et le boilerplate « Ne nomme jamais GSD » ×30) : le
  vocabulaire GSD peut apparaître, la clarté prime sur la traduction.
- Les tests de collision/préséance/synchro de table (anciens T3-verbes, T12, T13) — remplacés
  par les tests du modèle agentique (voir README §Tests).

### Ajouté / Modifié
- **Carte d'intention unique** : `references/intent-routing.md` refondu de « table des 31
  verbes » en « carte intention → brique gsd / équipe » — seule source de routage, consommée
  on-demand par les 2 agents.
- **Manager agentique** (`vf-dev-manager`) : détection d'intention (brief en langage naturel
  brut mappé via la carte), **next steps** proposés depuis ROADMAP/STATE en fin d'étape et de
  mission, **hygiène documentaire** à critères explicites (fin d'étape, décision structurante,
  drift détecté — jamais au fil de l'eau), **digest de mission** ≤ 30 lignes par mandat
  (amortit les relectures intégrales de `.planning/` par étage).
- **`AGENT.md` (vibeflow-dev)** refondu : intention → brique gsd directe, raccourcis dominants
  + carte exhaustive on-demand, garde-fou first-use conservé (FIRST-01/02, BOOT-04).
- **ADR-045 côté mobile en 1 saut** : les workers cloisonnés remontent
  `doc-research-required` directement à l'orchestrateur qui porte le web — plus de relais en
  cascade.
- **Rapports allégés** : les workers rendent le bloc typé + le strict nécessaire, le détail va
  sur disque (`.planning/missions/`) — le manager pilote sur le bloc typé seul.
- `module.json` / README / tests réécrits pour le modèle agentique (2 skills survivants,
  équipe de mission, carte unique).

## [v1.8.2] — 2026-07-25

### Modifié
- Audit 2026-07-25 vague 1 : workers et juges en sonnet (doctrine model-profiles), cadrage non-interactif explicite de vf-coder (`--auto`, plus de checkpoint mort), dispatch parallèle de la frontière DAG et des juges (revue ∥ audit, fusion des findings, un seul reopen), fin de la double revue ; exception panel en mission documentée (vf-decide).

## [v1.8.1] — 2026-07-25 (soldes de l'étape 12)

### Corrigé
- **Frontière d'altitude (ADR-055)** portée par les descriptions : `vf-milestone`, `vf-phase`,
  `vf-backlog`, `vf-resume` et `vf-pause` opèrent sur le `.planning/` d'un **projet de code** —
  ils renvoient désormais vers `/vf-planning` pour l'altitude **lab** et les labs non-dev.
  `/vf-plan`, `/vf-init`, `/vf-progress`, `/vf-docs`, `/vf-cleanup` et `/vf-dev` le faisaient
  déjà ; les cinq manquants fermaient mal la frontière que l'ADR-055 venait de poser.
- **T5 et T11 bornés au module.** Les deux axes balayaient tout `skills/` et `agents/`, plats et
  partagés entre modules en lab installé : un fichier d'un module voisin pouvait faire rougir la
  suite du `dev-orchestrator`. T5 réutilise `owned_verb()` ; T11 est borné à l'agent, ses
  references et ses quatre agents d'équipe.
- **T11 dé-nommé et recentré sur la cause réelle** : il traque un renvoi vers `.planning/research/`
  ou `docs/_mission/` — dossiers du dépôt de développement, jamais installés, donc liens morts en
  lab — au lieu du nom d'un projet tiers.
- **Résidu de projet tiers** retiré de `references/autonomous-guardrails.md` (le dépôt est public).

## [v1.8.0] — 2026-07-25 (routage fin : 31 verbes, préséance, doctrine exhaustive)

Le module ne couvrait que 14 intentions sur les ~65 gestes de la chaîne interne : tout le reste
n'avait pas de porte d'entrée et se jouait au hasard du matching sémantique. Cette version pose
les **trois niveaux de routage** de la spec `2026-07-25-routage-fin-verbes-vf-design.md`.

### Ajouté

- **17 verbes** neufs (le module en compte **31**), chacun un délégateur mince vers sa cible :
  - *amont & cadrage* — `/vf-explore` (idée floue), `/vf-spike` (code jetable), `/vf-spec` (le QUOI) ;
  - *qualité & audits* — `/vf-testgen`, `/vf-gaps` (dette et recettes en souffrance), `/vf-secure`,
    `/vf-forensics` (post-mortem de cycle), `/vf-inbox` (issues et PR entrantes) ;
  - *cycle de vie projet* — `/vf-milestone`, `/vf-phase`, `/vf-undo`, `/vf-backlog`, `/vf-cleanup` ;
  - *contexte & session* — `/vf-resume`, `/vf-pause`, `/vf-docs`, `/vf-learn`.
- **`rules/vf-verb-precedence.md`** — rule **globale (Tier 1)**, 40 L : une intention de dev entre
  dans la chaîne **par un verbe**, jamais par un skill interne appelé en direct. Échappatoire
  cadrée + pièges connus. Volontairement **sans `paths:`** (voir *Prérequis* ci-dessous).
- **`references/intent-routing.md`** — doctrine de routage exhaustive (intention → verbe → cible),
  couvrant **100 %** des skills de l'index factuel, y compris les gestes d'outillage sans verbe
  dédié. Chargée **on-demand** : coût contexte nul le reste du temps.
- **Tests** : `T12` anti-collision (réciprocité stricte sur les groupes de collision, chasse gardée
  de `/vf-audit`, les deux modules lus), `T13` préséance (rule conforme, référencée, table de
  routage sans cible interne), `T14` exhaustivité (index entièrement routé + toute cible promise
  par la doctrine est bien citée par le verbe qui la porte).

### Modifié

- **Descriptions des 14 verbes existants** réécrites sur un gabarit unique : formulations FR
  réelles, contre-exemples nommant les voisins (`✘ … → /vf-…`), portée d'invocation. C'est la
  description qui départage deux gestes proches — elle est le code du routeur, pas de la doc.
- **`AGENT.md` refondu** : la table de routage associe une intention à un **verbe**, plus jamais à
  une cible interne (218 L, groupée par famille). L'idée floue part désormais vers `/vf-explore` et
  non plus vers la conception d'une solution. Renvois ajoutés vers la rule de préséance et vers
  `intent-routing.md`.
- **`vf-dev`** (point d'entrée générique) : sa mini-table ne connaissait que les 14 anciens verbes ;
  elle aiguille désormais par famille vers les 31.
- **`T3`** compte maintenant les **verbes** distincts de la table de routage (seuil inchangé, ≥ 11).
  Il comptait des cibles `gsd-*` — ce que le nouveau contrat interdit précisément dans la table.
- **Fixture `FIXTURE_TARGETS` (T4)** étendue à **toutes** les cibles portées par un verbe. Sans
  cela, chaque verbe ajouté sortait « orphelin » sur un poste sans chaîne interne installée : le
  test passait en local et échouait en CI.

### Prérequis

- **Claude Code ≥ v2.1.198** — c'est la version qui apporte le mécanisme natif `.claude/rules/`,
  sans lequel le niveau 2 (préséance) n'est pas opérant.
- Une rule **sans** frontmatter `paths:` est chargée **inconditionnellement au lancement**, à la
  même priorité que `CLAUDE.md` ; une rule **avec** `paths:` n'est chargée qu'à la lecture d'un
  fichier correspondant. `vf-verb-precedence.md` doit donc rester **sans `paths:`** : une intention
  n'a pas de chemin de fichier, elle est inscopable par construction. (`paths` est le seul champ
  documenté — source : documentation officielle Claude Code, `memory.md`.)

### Non compris

- `/vf-ingest` (intégration de specs et de plans existants) arrive à l'**étape suivante** : sa
  place est réservée dans la doctrine et dans la fixture de test, son verbe n'est pas encore écrit.
- Aucun bump de la version racine ni tag : la release est portée par la clôture du jalon.

## [v1.7.0] — 2026-07-22 (ADR-053 — volet swarm : lock de driver + DAG + rapports typés)

### Ajouté
- **Pattern A — Lock de driver unique** : `scripts/driver-lock.sh` (acquisition atomique par `mkdir`,
  heartbeat, release, **récupération de claim périmé** via TTL). Empêche deux missions de piloter la même
  étape en parallèle (protège les backups isolés ADR-048/049). `vf-dev-manager` l'acquiert avant tout
  dispatch, rafraîchit le heartbeat entre étapes, le relâche à la clôture. 26 tests (dont concurrence réelle).
- **Pattern B — DAG de tâches** : `scripts/dag.sh` (nœuds `ready`/`blocked`, frontière dispatchable,
  `reopen` = ré-entrée avec reset transitif des dépendants, remap `id::stage` sur collision, commande
  `tree` = rendu arbre du plan de bataille avec passe orpheline pour composants cycliques). Le plan de
  bataille du manager devient un graphe persistant. 29 tests.
- **Pattern C — Rapports de worker typés** : `vf-coder`/`vf-reviewer`/`vf-auditer` (+ `vf-test-orchestrator`
  du module mobile-test-team) terminent par `{statut, findings[{action: auto-fix|no-op|ask-user}],
  noeuds_debloques}` → contrôle de flux déterministe côté manager (raffine ADR-031).
- `references/mission-flow.md` : protocole complet A/B/C (source de vérité).
- **Résolution de scripts scope-robuste** : le manager résout `$S` (cascade `$HOME/.claude/scripts` →
  `./.claude/scripts` → plugin root) au lieu de présumer `./.claude` — le swarm fonctionne quel que soit
  le scope d'install du lab (user OU projet, ID4). Sans ça, un lab en scope user ne trouvait pas les scripts.

### Note
- Pas de RAII machine (un agent LLM peut mourir sans release) → la récupération de claim périmé
  (heartbeat + TTL) est **obligatoire**, pas optionnelle. Réalisé par fichiers d'état, sans bus temps réel.

## [v1.6.0] — 2026-07-19 (ADR-051)

Allowlist MCP des agents exécutants dérivée du lab — les sous-agents voient enfin les serveurs MCP
du projet (XcodeBuildMCP, mobile-mcp, DB métier…).

### Ajouté
- **`scripts/inject-mcp-tools.sh`** : injecteur idempotent. Lit les serveurs du `./.mcp.json` du lab
  et injecte `mcp__<serveur>__*` dans le `tools:` des agents flaggés `vf-mcp-consumer: true` (ou d'un
  fichier `--force`). Aucun nom de serveur ni d'agent en dur ; best-effort (python3/`.mcp.json`
  absents → no-op) ; `--dry-run`. Le glob `mcp__*` étant **refusé** en allowlist `tools:` (seul
  `disallowedTools` l'accepte), l'injection par-serveur est la seule voie générique.
- **`scripts/tests/test-inject-mcp-tools.sh`** : 10 cas (dossier, idempotence, `--force`, refus sans
  flag, no-op sans `.mcp.json`, hérite-tout, `--servers`, tri déterministe) — tous verts.
- **`agents/vf-coder.md`** : flag `vf-mcp-consumer: true` (exécutant : build/test).
- **`scripts/ensure-deps.sh`** : `patch_gsd_executor_mcp` — après l'install GSD, injecte les serveurs
  du lab dans `~/.claude/agents/gsd-executor.md` (`--force`, hors plugin). Re-jouable → auto-réparateur
  après une réinstall GSD.

### Note
- Le `tools:` d'un agent est lu au **démarrage de session** : **redémarrer Claude Code** après
  (ré)install pour que la nouvelle allowlist prenne effet.

## [v1.5.0] — 2026-07-09

Équipe manager de mission (pattern généralisé — spec 2026-07-09, ADR-046).

- **4 agents natifs** (`agents/`) : `vf-dev-manager` (sommet — planifie, décide via panels,
  distribue, contrôle de flux entre étages) + workers internes `vf-coder` (cycle d'étape),
  `vf-reviewer` (revue sans écriture), `vf-auditer` (audit sécu/dette sans écriture).
  Conformes ADR-044 ; workers `vf-internal: true` (Pattern 12).
- **Contrats de mission** (`references/mission-contracts.md`) : brief main→manager, rapport
  manager→main, signaux « mission », seuil `SEUIL_EQUIPE` — source unique (DRY).
- **Router** : détection de mission + proposition de l'équipe (heuristique 7, jamais d'office).
- **vf-auto** : aiguillage taille — court → boucle autonome inline, long → équipe.
- **Tests** : T8-T11 (conformité agents, contrats, routage, généricité).

## [v1.4.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Recherche documentaire avant debug** (ADR-045), câblée dans trois briques :
  - `skills/vf-debug/SKILL.md` : **pré-étape obligatoire** avant la délégation à `gsd-debug` — si
    déclencheur (lib/framework/natif/version, ou fix déjà échoué), recherche context7 + issues
    GitHub d'abord, pistes priorisées et sourcées.
  - `AGENT.md` (`vibeflow-dev`) : la route « débugge » passe par le gate recherche-doc ; nouvelle
    heuristique de routage n°6 (le pilote a l'héritage web, il porte la recherche que les workers
    cloisonnés remontent via `doc-research-required`).
  - `references/autonomous-guardrails.md` : **6ᵉ garde-fou** « recherche doc avant debug empirique »
    + champ `maxResearchRoundsPerFlow` (défaut 2) au schéma `night-run.json` — la recherche précède
    les tentatives, ne consomme pas de slot `maxAttemptsPerFlow`, mais compte dans le budget global.
- Règle canonique référencée : `doc-research-before-debug` (module `software-architecture`).

## [v1.3.0] — 2026-07-08

### Ajouté
- **Routage des phases de design → `/vf-design`.** Nouvelle ligne dans la table de routage de
  `vibeflow-dev` (« design / UI / c'est moche / la DA / le style / refais l'écran / la typo /
  le spacing » → verbe `vf-design`, agent `vibeflow-design`) et dans le point d'entrée `vf-dev`.
  Un cycle de développement couvre désormais explicitement la phase de design sans quitter le
  vocabulaire VibeFlow.
- **Dépendance `design-orchestrator`** (`requires`) : le module design est **installé d'office**
  avec `dev-orchestrator`. Tout lab de développement dispose de `/vf-design` sans action
  supplémentaire (résolveur de deps transitif → `install --with-deps`).

## [v1.2.0] — 2026-07-07

### Ajouté
- **Verbe `/vf-decide`** — panel de décision pour trancher une zone grise technique (compare
  des options, produit un tableau comparatif sourcé + reco). Délègue au **mode advisor de
  `gsd-discuss-phase`** (qui orchestre le panel de recherche décisionnelle) — on route vers le
  skill canonique, jamais vers un agent en direct. Porte le total à **14 verbes `/vf-*`**. Ajouté
  à la table de routage de `vibeflow-dev` et à `vocabulary-map.md` (« advisor » → panel de décision).
- **Référence `references/autonomous-guardrails.md`** — doctrine des 5 garde-fous de boucle
  autonome (anti-thrash N=3, anti-régression revert, arrêt vert/plafond, séparation anti-triche,
  rapport de synthèse). Branchée sur `vf-auto` (section « Garde-fous (non supervisé) »). Extraite
  et généralisée depuis le track « équipe d'agents » (couche B).

### Note
- La séparation anti-triche s'appuie sur le **Pattern 12 — Cloisonnement par outils**
  (module `reference`).

## [v1.1.0] — 2026-06-04

### Ajouté
- **Verbe `/vf-map`** — cartographie d'un code existant (délègue à `gsd-map-codebase`),
  construit selon la discipline `writing-skills`. Complète `vf-init` (bootstrap + démarrage
  projet) pour couvrir explicitement le parcours « projet existant ». Porte le total à
  **13 verbes `/vf-*`**.
- README : section Usage enrichie — routage NL init/map, parcours types (premier contact,
  projet existant, tâche rapide, autonomie), verbe `vf-map`.

### Corrigé
- `test-dev-orchestrator.sh` portable : détecte la disposition source (`AGENT.md` + `references/`
  à la racine) vs lab installé (`agents/dev-orchestrator.md` + `agents/<mod>-references/`, D7).
  Le test shippé ne produit plus de faux échecs quand il est lancé depuis un lab.

## [v1.0.0] — 2026-06-04

### Module initial complet (5 plans, phase 01-dev-orchestrator)

**Squelette du module**
- Structure conforme aux modules vibeflow-os (`VERSION`, `CHANGELOG.md`, `README.md`, `references/`, `scripts/`)
- Type : agent + multi-skills + scripts (orchestrateur de développement)

**Index auto-généré (D4 — anti-hallucination)**
- Script `build-gsd-index.sh` qui génère `references/gsd-skills-index.md` à partir des skills GSD réellement installés (`~/.claude/skills/gsd-*`)
- Aucun nom de skill écrit en dur : extraction factuelle du frontmatter (`name` + `description`)
- Contrat de sortie `VF_INDEX_OUT` surchargeable (consommé par le hook post-install, D7)
- Idempotent : ré-exécution = régénération complète (IDX-02)

**Agent routeur (Plan 03)**
- `AGENT.md` (`vibeflow-dev`, ≤250L) : routage langage naturel → action, 14 cibles distinctes
- Doctrine pipeline déportée `references/GSD-PIPELINE.md` (chargée on-demand)
- Ne nomme jamais GSD/Superpowers ; reframe en vocabulaire VibeFlow

**Couche d'abstraction (Plan 04)**
- 12 verbes `/vf-*` thin delegators (construits via `writing-skills`)
- `references/vocabulary-map.md` (traduction GSD → VibeFlow)

**Bootstrap + intégration (Plan 02 & 05)**
- `ensure-deps.sh` : auto-install non-interactif idempotent de GSD + Superpowers, fallback manuel
- `vibeflow-update.sh` étendu : copie des references d'un module agent sous `.claude/agents/<mod>-references/` (D7) + hook post-install régénérant l'index (IDX-02)
- Suite `test-dev-orchestrator.sh` (4 axes VERIF-01 + densité `wc -l` VERIF-02)
