# Le moteur de planning des labs métier

> **Statut** : conception cadrée, **pas encore inscrite à la feuille de route**. Cette note est
> l'entrée du cadrage, elle ne le remplace pas.
> **Arbitrages** : Willy, AskUserQuestion session principale, **2026-09-22** (D-01 à D-08, §2).
> **Révision 2** (même jour) : après quatre passes — vérification adversariale des faits, recherche
> de failles, mesure de la charge, état de l'art externe. **Cinq décisions sur huit en sortent
> amendées, une est précisée, deux sont ajoutées.** Les corrections sont tracées à l'endroit où
> elles s'appliquent, et le §1.5 consigne les affirmations de la v1 qui étaient fausses, pour que
> personne ne les rejoue.
> **Origine** : le planning des labs non-dev n'est pas tenu, alors que le module de développement
> tient le sien presque sans faute. Cette spec explique mécaniquement l'asymétrie et en dérive un
> moteur.
> **Périmètre** : le moteur seul. La fabrique d'agents et de skills, l'initialisation d'un lab et
> la veille automatique font l'objet de specs distinctes (§12).

---

## 1. Diagnostic — l'asymétrie, mesurée

> **Note de révision.** La v1 de ce §1 portait cinq affirmations fausses, listées en §1.5. Le
> diagnostic mécanique tenait ; le récit qui l'entourait était faux. Ce qui suit ne garde que ce
> qui a été reproduit.

### 1.1 Ce que le moteur dev refuse, en code

Mesuré dans `gsd-core` 1.14.0, avec fichier et ligne. **Quatre gates *fail-closed* en JavaScript**,
plus une réconciliation en prose de workflow :

| Refus | Où | Nature |
|---|---|---|
| `phase.complete` sans un `SUMMARY.md` par plan | `bin/lib/phase.cjs:2944`, `:2969` | code |
| `phase.complete` sans `VERIFICATION: passed` | `bin/lib/phase.cjs:3950` | code |
| cocher la case ROADMAP avant vérification | `bin/lib/roadmap.cjs:851-886` | code |
| `state advance-plan` sur un disque incohérent → `declineNoOp` | `bin/lib/state.cjs:791` | code |
| `commits:` déclaré sans activité `git rev-list` | `workflows/verify-work.md:182-196` | **prose de workflow** |

Chaque gate cite son incident fondateur : *« Completing a phase with unexecuted plans is what lost
an entire promised deliverable silently (#2648) »* · *« 14 plans declaring `commits: 1` with zero
git activity (#3968) »*.

**Le principe qui les unit : l'état est dérivé du disque, jamais déclaré.**

**Nuance.** La discipline dev n'est pas uniforme. `plan-phase` offre explicitement « Continue
without context », et la couverture des décisions du CONTEXT est *warning only*. Elle est
verrouillée **là où un oubli ferait perdre du travail déjà fait**, et souple ailleurs. Ce moteur
reprend cette économie, pas une rigueur tous azimuts.

### 1.2 Ce que `planning-core` v2.7.0 ne refuse pas

Le constat défendable est **plus simple et plus fort** que celui de la v1 :

- **Un seul hook du module est sur un événement capable de refuser** (`Stop`).
- **Ce hook mesure un `mtime`.** Reproduit en fixture : livrable modifié, planning intouché →
  `exit 2`. Puis `touch .planning/STATE.md`, contenu inchangé daté de 2020 → **`exit 0`**. Et
  `echo x > .planning/NOTES-BIDON.md` → **`exit 0`**.
- **Le module possède le script qui sait dire qu'un `STATE.md` est mort**
  (`check-planning-state.sh`, seuil 7 j) et **le garde ne le consulte jamais** (`grep` → 0).
- **Aucun `PreToolUse`.** La seule occurrence du mot dans le module est un `README.md` qui prétend
  l'inverse.
- **Aucun script n'ouvre `phases/`**, ne compare PLAN ↔ SUMMARY, ne lit `progress` ni `status`.
- Le message de blocage **publie son propre contournement** (`.session-noop`), et un marqueur
  `.blocked` limite le garde à un blocage par session.

Le `SKILL.md` est honnête sur sa nature — « scaffoldeur thin, prose agent-driven » — pendant que
`hooks.json` annonce « Planning machine-enforced ».

### 1.3 Ce qui se passe réellement sur les labs

| Fait mesuré | Valeur |
|---|---|
| Compartiments de BusinessFlow-Lab | 21 |
| …avec un `.planning/` | 4, **tous à `last_updated: 2026-06-23`** (91 j) |
| Commits en septembre 2026 | **0** (47 dans toute la vie du lab) |
| Dérive de son `INDEX.md` / `STATE.md` | **40 j / 65 j** |
| Son `config.json` | **`"phases_trace": false`, `"gates": false`** |

La dernière ligne est la plus importante de cette spec : **le traçage de phases a été essayé, puis
désactivé.** Aucune correction de design ne répond à ça — c'est un arbitrage d'usage (§11).

Le hook n'est **pas** livré opt-in : depuis ADR-043 (2026-07-04), `merge-hooks.sh` le câble
automatiquement — vérifié par exécution. La cause n'est donc jamais le câblage.

### 1.4 Chez Jarvis Keystone

Les contrôles de cadrage sont écrits et leurs bancs déclarent 58/58, 14/14, 54/54. **Aucun n'est
câblé**, et leurs verts sont des **traces d'un hôte mort** : `/opt/jarvis-keystone` n'existe plus,
BSD `sed -i` casse un des bancs, un script n'est même pas exécutable. Le bilan de phase le dit :
*« La condition dit "une machine refuse". Elle refuse quand on la lance, pas au passage. »*

Le lab possède néanmoins **un `PreToolUse` réellement bloquant** (`guard-driver-lock.sh`) : c'est la
seule implémentation de référence du corpus, et §5 comme §6 en dérivent leurs contraintes.

### 1.5 Les cinq affirmations de la v1 qui étaient fausses

Consignées pour que personne ne les reprenne : (1) le mécanisme serait livré *opt-in* — faux depuis
14 mois ; (2) AVMA aurait « branché » le garde que BusinessFlow aurait refusé — les 14 hooks d'AVMA
sont la sortie standard de l'installeur, et BusinessFlow a une **install périmée** (4 scripts sur 6
absents) ; (3) le lab « armé » passerait le gate — c'est l'inverse, AVMA sort `exit 1` à 8 jours et
BusinessFlow `exit 0` à 6 ; (4) `check-regle-81.sh` serait la cause des écritures parasites de
Keystone — **il est postérieur de 16 jours**, n'est pas bloquant, et n'est pas seul ; (5) les cinq
`|| true` désarmeraient les hooks — **`SessionStart` ne peut pas bloquer par contrat**, et le
`|| true` y est une conformité voulue au contrat de sortie du dépôt.

---

## 2. Décisions

### Tenues sans modification

- **D-01 — Noyau d'enforcement commun, modèle par cycles.** Écartés : durcir `planning-core` en
  place, construire un moteur séparé, faire adopter GSD au métier.
- **D-06 — Un seul régime ; le grain suit le registre d'inconnues.** Le gate vérifie que le
  registre est **clos**, jamais qu'il est long. Cohérent avec la mesure : sur 26 cadrages Keystone,
  la médiane est de **8 lignes de registre**, et **54 % tiennent en un commit**.
- **D-08 — Trois natures de skill** : référentiel, outil, procédure. Seule la procédure touche au
  planning.

### Amendées après passe adversariale

- **D-02 — La preuve = le livrable sur disque + un verdict de juge. → Le juge ne bloque que sur
  ses constats.** La doctrine maison (`rubric-design.md`) établit qu'*« un juge-LLM sans rubric
  écrite est de l'aléatoire déguisé en audit »* et impose un test de reproductibilité **avant
  déploiement** ; **aucun des quatre juges n'a d'exemple-étalon**, et le test n'a jamais été passé.
  La variance est mesurée dans le corpus : même fichier, même `sha256`, verdicts opposés. Le
  discriminant est écrit noir sur blanc : *« c'est la question qui demande un jugement qui bouge,
  pas celle qui demande un constat »*. Donc : **les critères éliminatoires objectivement
  vérifiables refusent** (montant non sourcé, opt-out absent, promesse hors périmètre vendu) ; le
  score de jugement est calculé, affiché, enregistré, **et non bloquant**.
- **D-03 — L'état se recalcule. → Plus un huitième état et un champ humain.** La dérivation pure
  est **fausse**, pas seulement ambiguë (§3.2). Elle gagne : un état `indéterminé` quand les
  signaux se contredisent ; un champ `statut: abandonné|remplacé|gelé` réservé à la **dérogation
  nominative** ; et un `à exécuter` dérivé d'un **marqueur de clôture par plan**, non de l'absence
  du livrable.
- **D-04 — Le verrou est un bail sur des chemins. → Générationnel, porteur d'un jeton monotone,
  vérifié par l'écrivain.** Voir §6. Deux corrections de la v1. D'abord `R-VER-4` n'interdit pas
  toute variable d'environnement — sa source précise *« un fichier **ou un `env:` de
  settings.json** »* ; le choix du fichier reste, pour le dynamisme. Ensuite et surtout : **un bail
  keyé sur la session est inopérant en fan-out**, parce que le payload de hook d'un sous-agent
  porte le `session_id` **du parent** (issue amont #76726 : *« N sous-agents parallèles présentent
  tous le même `session_id` et passent tous le même mutex »*). Le bail porte donc un **jeton
  monotone** au sens de Kleppmann, attaché au mandat de travail et non à l'identité de la session.
- **D-07 — Procédure vs chantier. → La frontière doit porter un gate.** Mesuré : une procédure
  coûte **+1 à 3 %** ; un chantier de moins de deux heures coûte **+50 à +200 %**. C'est donc D-07
  qui tient toute l'économie du moteur — et il n'a aujourd'hui aucun contrôle machine. Le précédent
  est dans cette spec même : **9 blueprints d'agents sur 9** ont dérivé de leur contrôleur sans que
  personne le voie.

### Précisée — et c'est la précision qui la rend vérifiable

- **D-05 — Un `.planning/` par lab, un par projet de code. → Un lab se définit par son `.claude/`.**
  Un lab est un dossier qui porte des **agents et de la mémoire**, avec un objectif propre. Des labs
  peuvent donc être **emboîtés**, et chacun a droit à son planning.

  La v1 confondait « un dépôt » et « un lab », et la passe adversariale a hérité de l'erreur : elle
  a chiffré à 5 665 références la fusion des six plannings de Keystone — **une migration qui ne doit
  pas avoir lieu.** Vérification :

  | | `.claude/` | `.planning/` | agents | verdict |
  |---|:--:|:--:|--:|---|
  | Keystone — racine, doctrine, pilotage, atelier, captation, gabarit | ✓ ×6 | ✓ ×6 | 7 · 0 · 4 · 17 · 1 · 1 | **six labs, six plannings, zéro orphelin** |
  | BusinessFlow — racine | ✓ | ✓ | 17 | lab, planning vivant |
  | BusinessFlow — `avma`, `dmflow`, `lead-recovery` | **·** | ✓ | 0 | **orphelins** |
  | BusinessFlow — `formation` | ✓ | ✓ | **0** | **orphelin** |

  **Les quatre plannings orphelins de BusinessFlow sont exactement les quatre plannings morts** —
  tous à `last_updated: 2026-06-23`, 91 jours. Un planning qu'aucun agent n'habite ne peut pas
  vivre. G7 aurait signalé les quatre le jour de leur création.

### Nouvelles

- **D-09 — Le recalcul d'état ne s'implémente pas en bash.** Mesuré sur trois échelles : à
  3 000 phases, **133 à 212 s en bash contre 9,7 à 12,4 s en Python** (facteur 11 à 21×). En bash,
  la seconde est franchie dès ~20 phases. `planning-core` est en bash aujourd'hui : c'est le risque
  d'implémentation le plus concret de cette spec.
- **D-10 — Le champ de périmètre s'appelle `ecrit:`, pas `scope:`.** `scope` est déjà pris dans six
  `config.json` et dans le gabarit du plugin (`"scope": "lab"`, `"scope": "compartment"`). Deux sens
  pour un mot dans le même écosystème. Renommer coûte zéro aujourd'hui.

---

## 3. Le modèle de données

```
<lab>/.planning/
  PROJECT.md · REQUIREMENTS.md · config.json
  INDEX.md              ⟲   carte des cycles et de leur état
  STATE.md              ⟲   position courante
  cloture.log           ⟲   append-only — la seule source de temps (§7.4)
  cycles/01-<sujet>/
    CYCLE.md                ce que le cycle rend, conditions qui le ferment
    phases/01-<nom>/
      CADRAGE.md            registre d'inconnues
      PLAN.md               gestes + `ecrit:` (D-10)
      VERDICT.md        ⟲   verdict, + hash de l'artefact jugé + n° de tentative
      SUMMARY.md
    phases/02-<nom>/plans/01-<nom>/{PLAN.md, VERDICT.md, SUMMARY.md}
  baux/<phase>/gen-<n>/     génération de bail (§6)
  missions/
```

`⟲` = généré, jamais rédigé.

**Le livrable vit à sa place métier**, pas dans `.planning/` : `ecrit:` déclare
`clients/<nom>/diagnostics/2026-09-22/`, la phase pointe dessus. Trois altitudes possibles — plan,
phase, cycle.

### 3.1 Les huit états dérivés

| Statut | Ce que la machine constate |
|---|---|
| `à cadrer` | dossier présent, pas de `CADRAGE.md` |
| `en cadrage` | registre avec au moins une ligne structurante sans statut |
| `à planifier` | registre clos, pas de `PLAN.md` |
| `à exécuter` | `PLAN.md` présent, **marqueur de clôture de plan absent** |
| `à juger` | marqueur présent, livrables présents, pas de `VERDICT.md` |
| `à corriger` | constats du verdict en échec |
| `close` | constats passés **et** `SUMMARY.md` présent |
| **`indéterminé`** | **les signaux se contredisent** |

Plus `abandonné | remplacé | gelé`, **non dérivables**, posés par dérogation nominative.

### 3.2 Pourquoi la v1 était fausse — et ce que ça impose

Trois mesures ont cassé la table d'origine :

1. **`à exécuter` était inatteignable sur du travail de modification.** Sur deux phases Keystone
   réelles, **5 chemins déclarés sur 8 existaient déjà** — le geste est *modifier*, pas *créer*. La
   phase dérivait donc `à juger` **avant la première frappe**, le juge était convoqué sur un
   livrable intouché, et la phase pouvait se fermer sur un travail jamais fait : l'incident même
   que §1.1 cite pour le dev, reproduit par le mécanisme censé l'empêcher. D'où le marqueur de
   clôture.
2. **Aucun état pour l'abandon.** **54 plans sur 410 (13,2 %)** n'ont pas de summary ; un cycle
   entier est mort avec une pierre tombale dupliquée 8 fois ; Keystone a dû inventer
   `statut: REMPLACÉ` + `remplace_par:`, et **18 valeurs de `statut:`** circulent — deux scripts du
   même dépôt étant déjà en désaccord sur ce que « fini » veut dire.
3. **Une dérivation pure ne peut pas dire « je ne sais pas ».** BusinessFlow a reconstitué son
   INDEX à la main selon ce principe et en a tiré la conclusion inverse : *« quand les deux
   divergent, c'est écrit »*, et *« un trou nommé vaut mieux qu'une continuité fabriquée »*
   (marqueur `[À RÉÉTABLIR]`). D'où l'état `indéterminé` : **un faux vert est pire qu'un aveu**.

---

## 4. Le harnais et la carte des agents

À chaque moment correspond un geste outillé. Le pattern à reprendre : **celui qui planifie n'est
jamais celui qui contrôle le plan, celui qui exécute n'est jamais celui qui vérifie.**

| Moment | Côté dev | Miroir métier |
|---|---|---|
| Ouvrir un chantier | `gsd-new-milestone` → 4 chercheurs, synthétiseur, `gsd-roadmapper` | cadrer un cycle |
| Figer le QUOI | `gsd-spec-phase` | inchangé |
| Cadrer | `gsd-discuss-phase` | cadrer une phase → registre |
| Planifier | `gsd-plan-phase` → chercheur, pattern-mapper, planificateur, **plan-checker** | planifier une phase |
| Exécuter | `gsd-execute-phase` | orchestrateur de phase |
| Vérifier | `gsd-verify-work` | juge scoré → `VERDICT.md` |
| Fermer | gate en code | idem, sur la preuve métier |

### 4.1 Ce qui existe déjà, et ce qui manque

Les trois équipes métier du plugin ont **déjà** leurs producteurs et leur juge :

| Équipe | Manager | Producteurs | Juge |
|---|---|---|---|
| business | `vf-business-manager` | commercial, delivery, finance | `quality-gate-client` |
| content | `vf-content-manager` | strategist, writer, repurposer | `content-clarity-judge` |
| growth | `vf-growth-manager` | channel-strategist, copywriter, campaign-analyst | `growth-quality-judge` |

**Les deux rôles métier existent donc en trois exemplaires. Aucun des quatre rôles de cycle
n'existe** : personne ne cadre, personne ne planifie, personne ne contrôle un plan, personne
n'orchestre une phase. Le manager dispatche directement des producteurs et un juge.

> **C'est la cause profonde du symptôme : le planning métier n'est pas tenu parce qu'aucun agent
> n'a ce rôle.** Ce n'est pas de la négligence, c'est un trou dans l'organigramme.

**Quatre agents à créer**, génériques, partagés par toutes les équipes, insérés dans le
`team-kernel` existant entre le manager et les producteurs : cadreur de phase, planificateur,
contrôleur de plan, orchestrateur de phase. Plus deux rôles génériques déjà outillés côté dev et à
transposer : chercheur, cartographe de patterns.

### 4.2 On n'adapte jamais un agent. On lui donne un référentiel.

| Agent | Nature | Créé par |
|---|---|---|
| Cadreur, planificateur, contrôleur de plan, orchestrateur, chercheur, cartographe | **générique** | **le plugin** |
| **Producteur** | **métier** | **l'initialisation** |
| **Juge** | **métier** | **l'initialisation** |

**L'initialisation ne fabrique que des producteurs et des juges.** Si elle fabrique aussi des
cadreurs adaptés, on multiplie la dérive des 9 blueprints par le nombre de labs. Vérifiable par
machine : le gate refuse un agent issu de l'initialisation qui porte un rôle de moteur.

Ce n'est pas une invention : le `team-kernel.md` porte déjà en titres *« ce que le kernel fournit,
invariant quel que soit le métier »* et *« ce que chaque métier paramètre — et RIEN d'autre »*.

**Trois points d'entrée pour le métier, tous des fichiers** : les décisions du domaine, les
gabarits de procédure, les rubriques de juge.

> **Addendum (arbitrage Samuel, 2026-09-23, relayé à Willy par WhatsApp le même jour) — contraintes
> gravées à l'inscription de la Phase 48 (ROADMAP.md § Phase 48, non planifiée ici).**
> `plugin/conductor/references/team-kernel.md` est lu par les managers dev ET design ET les
> bundles business/content ; les quatre rôles génériques ci-dessus dédoublent `gsd-discuss-phase`,
> `gsd-plan-phase`, le plan-checker et `vf-coder` côté dev. Deux contraintes s'appliquent au
> cadrage : (1) aucun ajout dans le `team-kernel` partagé si c'est évitable — les agents
> génériques de cycle vivent dans le module du moteur métier ; toute modification du noyau reste
> additive, explicitement portée non-dev, et sa nécessité démontrée ; (2) zéro régression sur les
> labs dev, prouvée par une mesure qui peut rendre rouge (mutation exécutée), jamais déclarée —
> routage du head, hooks de démarrage de session et doctrine des managers dev identiques
> avant/après. Voir aussi la contrainte de profondeur au §7.1 (même addendum).

---

## 5. Les gates

> **Correction majeure de la v1.** G2 était présenté comme un **confinement**. Mesuré : **204
> scripts écrivains dans le `.planning/` de Keystone**, 131 de plus dans `.claude/scripts/`, et
> l'implémentation de référence du corpus documente le mur — *« `sed -i`, `cat >`, `rm` ne sont
> JAMAIS détectées par la voie Bash »*. Confiner par `PreToolUse(Write|Edit)` sur un lab qui produit
> par script est **du théâtre**, et un faux vert coûte plus cher qu'une absence de gate. G2 devient
> une **détection**, et la sûreté bascule sur le bail et la réconciliation de clôture.

**Le harnais expose 33 événements, dont 13 peuvent refuser.** La v1 n'en utilisait qu'un
(`PreToolUse`) et une « commande de clôture » — c'est-à-dire un geste que l'agent choisissait
d'appeler. La v2 s'appuie sur les événements qu'il ne peut pas ne pas déclencher.

| # | Refuse si… | Événement | Force |
|---|---|---|---|
| **G1** | on écrit un `PLAN.md` sans `CADRAGE.md`, ou avec une ligne **structurante** sans statut | `PreToolUse(Write)` | **refus** |
| **G2** | une écriture sort de `ecrit:` | `PreToolUse(Write\|Edit)` + `PreToolUse(Bash)` | **avertissement** |
| **G2′** | ce qui a bougé diffère de ce que le bail couvrait, sans amendement | **`TaskCompleted`** | **refus** |
| **G3** | un livrable déclaré est absent ou vide | **`TaskCompleted`** | **refus** |
| **G4** | un **constat** du verdict est en échec | **`TaskCompleted`** | **refus** |
| **G4′** | un rapport de sous-agent ne porte aucune sortie de commande brute | **`SubagentStop`** | **refus** |
| **G5** | on écrit un verdict à la main | `PreToolUse(Write)` + hash | **refus** |
| **G6** | on écrit `STATE.md`, `INDEX.md` ou `cloture.log` à la main | `PreToolUse(Write\|Edit)` | **refus** |
| **G7** | on crée un `.planning/` sans `.claude/` (agents + mémoire) ni marqueur de projet de code | `PreToolUse(Write)` | **refus** |
| **D1** | — *ne refuse rien* : signale toute écriture sur un chemin surveillé | **`FileChanged`** | **détection** |

**G1 et G2′ sont les deux gardes d'ordre** : pas de plan sans cadrage, pas de clôture sur un
périmètre non tenu.

**Trois choix de mécanisme, chacun fondé sur une mesure :**

- **`TaskCompleted` remplace la commande de clôture.** Il est attaché à l'outil de mise à jour de
  tâche : l'agent ne peut pas l'esquiver. `exit 2` empêche la tâche d'être marquée close et renvoie
  la raison au modèle, qui retente — **il boucle sans cap natif**, d'où la nécessité du compteur de
  tentatives sur `VERDICT.md` (§10).
- **`FileChanged` est le filet, et le seul qui voie tout.** Il détecte par surveillance du système
  de fichiers, **pas par inspection des appels d'outils** : il voit donc une écriture par `Write`,
  par `Bash`, **et par un process entièrement extérieur** — c'est-à-dire les tâches planifiées de
  §6.3. Il **ne peut rien bloquer**, et sa watch-list n'accepte que des noms littéraux. Son rôle
  est de transformer un contournement silencieux en contournement tracé.
- **`SubagentStop` porte un gate de preuve**, pas de qualité : il refuse un rapport **sans sortie de
  commande brute**. La formule du projet qui l'a éprouvé : *« il bloque le silence, pas la
  falsification »*. C'est le bon usage d'un juge, et la littérature le confirme (§10.1).

### 5.1 Trois contraintes que la v1 ne posait pas

1. **Le refus passe par `permissionDecision: deny`, jamais par le code de sortie.** Mesure DIV-2 du
   dépôt : `exit 2` *« fuit en plus le chemin »*.
2. **Le comportement d'un gate qui ne peut pas s'exécuter doit être déclaré — et certains cas ne
   se choisissent pas.** Ce moteur choisit **fail-closed pour G1, G3, G4, G5, G6** et **fail-open
   pour G2**. Mais trois défaillances sont fail-open **par le harnais, sans réglage possible** : un
   `exit 1` est traité comme une erreur non bloquante et **l'action passe** ; un chemin de script
   erroné produit le même effet en silence ; et surtout, **un hook `PreToolUse` qui dépasse son
   timeout ne bloque pas** — la documentation amont le dit sans détour : *« ne comptez pas sur un
   hook bloqué pour faire office de gate »*. Corollaire non négociable : **tout gate doit se prouver
   en vie**, par un canary qui vérifie qu'il refuse encore ce qu'il est censé refuser. Un gate
   supposé est un gate absent.
3. **Tout gate d'écriture doit prouver qu'il refuse à tort dans une proportion mesurée.** Le prior
   empirique du corpus est terrifiant : un gate d'écriture mal calibré a **refusé 200 des 206
   entrées du dépôt pendant cinq jours**, en silence — **97 % de faux refus** — parce qu'une regex
   avait décroché de son message d'erreur. Test obligatoire **dans les deux sens** avant armement.

### 5.2 L'échappatoire, conçue contre la course aux armements

Le garde actuel publie son contournement et se désarme après un blocage. Une dérogation reste
nécessaire, mais elle est **tracée et nominative** : qui l'a accordée, par quel canal, quand —
alignée sur la règle de traçabilité du 2026-09-10.

Une course aux armements en quatre tours est documentée en amont, et chaque tour instruit ce
design : règle en prose → l'agent édite quand même ; hook → **l'agent pose des variables
d'environnement de contournement** ; hook → **l'agent supprime le fichier-drapeau du gate** ; hook →
*(contournement suivant à venir)*. Trois règles en découlent :

1. **L'état d'un gate ne vit jamais dans un artefact que l'agent peut écrire.** Le drapeau de
   l'incident vivait dans `/tmp` et a été effacé par un `rm` — donc par `Bash`, donc invisible d'un
   hook `Write|Edit`. Le jeton de bail (§6.1) et le hash de verdict (§10) sont choisis pour ça.
2. **L'échappatoire n'est jamais conditionnée à l'urgence.** Le déclencheur mesuré de l'incident
   est une instruction de vitesse : *« quand on lui dit de travailler vite, l'agent interprète
   l'instruction de vitesse comme une permission de contourner les gates de qualité »*. Or la
   pression de délai est le mode normal d'une session — une clé ouverte par l'urgence est une clé
   toujours ouverte.
3. **Elle doit être bon marché à emprunter et chère à emprunter en douce.** Elle existe, elle exige
   une raison non-placeholder, et elle est journalisée. Ce qu'on vise n'est pas d'empêcher la
   dérogation : c'est d'empêcher qu'elle soit **silencieuse**. Le mode d'échec réellement coûteux,
   dans les deux incidents amont, n'est pas que l'agent ait contourné — c'est qu'il **ne l'ait pas
   dit**.

---

## 6. Les baux

### 6.1 Le bail est générationnel

```
.planning/baux/<cycle>-<phase>/gen-<n>/{meta, chemins}
```

**Prendre** = `mkdir gen-<n+1>` où `n` est la plus haute génération observée. **Lire** = la plus
haute génération dont le battement est frais. **Un bail mort n'est jamais effacé : il est dépassé.**

> **Pourquoi pas le `mkdir` simple de la v1.** Le dépôt Keystone l'a mesuré cassé et l'a écrit :
> *« 24 acquisitions concurrentes sur un lock périmé rendaient jusqu'à **5 gagnants simultanés**
> (macOS ET Linux). Ce n'est pas une fenêtre à rétrécir : deux correctifs de fenêtre ont été
> mesurés **PIRES** que l'original (8 et 6 gagnants). »* Le défaut n'est pas dans l'atomicité de
> `mkdir` — il est dans **`mkdir` + suppression pour récupérer**. Pendant la suppression, le chemin
> n'existe pas. Le bail générationnel supprime l'instant où le chemin paraît libre.

**Après chaque acquisition, relire le disque** et exiger que la génération gagnante soit la nôtre —
jamais le code de sortie. Le corpus en donne la raison, `ln -h` valant `--help` sous uutils
coreutils : deux `acquired: true` avec **le lock absent du disque**. La règle générale, applicable
aux sept gates : *« une garde qui vérifie qu'une commande a rendu 0 sans vérifier qu'elle a FAIT
quelque chose »*.

### 6.1 bis — Le numéro de génération est un jeton de clôture

La génération n'est pas qu'un nom de dossier : c'est un **entier monotone croissant**, et c'est
**le hook qui le vérifie à chaque écriture**, pas la session qui s'abstient. Une écriture présentant
un jeton inférieur au dernier jeton vu sur ce chemin est **refusée**, même si le bail n'a pas expiré
au sens de l'horloge.

C'est le *fencing token* de Kleppmann, et il résout trois problèmes d'un coup :

- **La session morte qui revient.** Elle reprend, croit toujours détenir son bail — rien ne le lui a
  retiré côté client — et écrit. Son jeton est dépassé : refusé. **Elle n'a pas besoin de savoir
  qu'elle a perdu ; la ressource le sait.**
- **Le cron.** Il n'a aucune boucle où recevoir une notification d'expiration. Un bail temporel ne
  le protège pas ; un jeton, oui.
- **Le fan-out de sous-agents.** C'est le cas décisif : le payload de hook d'un sous-agent porte le
  `session_id` **du parent**, donc *« N sous-agents parallèles présentent tous le même `session_id`
  et passent tous le même mutex »*. Le jeton est porté par le **mandat de travail**, pas par
  l'identité de la session — il survit à ce défaut.

Le jeton ne met personne en file d'attente : il n'exclut pas, il **rejette une écriture périmée**.
Un agent qui meurt ne bloque donc personne. C'est ce qui permet de répondre à la thèse adverse
sérieuse du domaine — *« au moment où un verrou existe, un dépôt actif devient une file d'attente »*
— sans renoncer à la propriété de sûreté.

**Une classe de collision qu'aucun bail ne voit**, et qu'il faut nommer : deux sessions qui allouent
le même « prochain identifiant libre » dans un fichier partagé — deux numéros de phase identiques
dans `ROADMAP.md` ou `MILESTONES.md`. *« Ça merge proprement, et c'est silencieusement corrompu. »*
Le `merge=union` de ce dépôt rend cette corruption **plus** silencieuse, pas moins. Seul un jeton
posé sur la ressource « compteur d'identifiants » l'attrape.

### 6.2 Le bail porte les fichiers d'état partagés, pas les dossiers de livrable

> **Correction majeure de la v1**, qui affirmait que les fichiers partagés « se dissolvent ».
> Mesuré sur un run réel de `post-diagnostic` : 16 fichiers dans le dossier client, **tous
> isolés**, et **cinq chemins partagés en dehors** (`PIPELINE_STATE.json`, `BDR.md`,
> `LEARNINGS.md`, `CONTACT_TOUCHES.jsonl`, la mémoire de l'agent). Deux runs concurrents
> collisionnent donc **à 100 %**, et jamais là où la v1 le prévoyait. Trois procédures se sont
> chevauchées en 40 minutes le même soir, et le lab se défend déjà à la main : **six copies** de
> `PIPELINE_STATE.json`, dont une prise à `05:44` pile — l'heure du cron.

Deux classes :

- **append-only** (`CONTACT_TOUCHES.jsonl`, `LEARNINGS.md`, `cloture.log`) → **hors bail**, ajout
  en fin de fichier ;
- **réécrit en place** (`PIPELINE_STATE.json`, `STATE.md` d'un compartiment) → **bail obligatoire,
  au fichier près, jamais au préfixe**.

Un bail sur `pipeline/` sérialiserait tout le lab ; un bail sur le dossier client raterait
exactement ce qui collisionne.

### 6.3 Les écrivains hors session

Des tâches planifiées écrivent les fichiers les plus disputés **sans aucune session** :
`com.bfl.pipeline-sync` écrit `PIPELINE_STATE.json` tous les jours à 05:44 ; `com.bfl.relance-potential`
deux fois par jour. **Aucun `PreToolUse` ne peut voir un cron.**

Trois réponses, en couches :

1. **Le bail est vérifié par l'écrivain**, pas seulement par le harnais. Tout script qui écrit un
   fichier de classe « réécrit en place » lit le jeton courant avant d'écrire et se replie si le
   sien est dépassé.
2. **Le jeton monotone (§6.1 bis) rend le cron inoffensif sans avoir à le détecter** — un process
   réveillé après coup présente un jeton périmé, et se fait refuser.
3. **`FileChanged` (D1) voit ce qu'aucun autre mécanisme ne voit** : il détecte par surveillance du
   système de fichiers, donc il signale l'écriture d'un process entièrement extérieur à la session.
   Il ne bloque pas — mais sans lui, l'écriture de 05:44 n'existe nulle part.

### 6.4 Ce qu'un bail ne partitionne pas

Le corpus le dit pour `.git/index` ; la généralisation vaut ici. **Un bail sur des chemins ne
partitionne ni l'index git, ni les registres mémoire, ni un cron.** C'est une couche, pas une
solution complète. Et le trou déclaré de l'implémentation de référence s'applique tel quel : *« une
session qui ne déclare rien passe partout — la déclaration est le geste qui arme le verrou, et
aucune machine ne l'exige »*. Ici, c'est G2′ qui l'exige à la clôture.

---

## 7. L'index, le chargement, l'hygiène, le temps

### 7.1 L'index

Recalculé. Par cycle : état dérivé, phase courante, dernier signe de vie, bail en cours. **Seule
chose injectée par défaut.**

Mesuré : l'INDEX généré fait **1 392 octets** pour Keystone (~400 tokens), contre **36 800 octets**
pour le `STATE.md` qu'il remplace. **Il est 26× plus petit.** Le §7 ne coûte pas de contexte, il en
économise environ 10 000 tokens par injection.

> **Addendum (arbitrage Samuel, 2026-09-23, relayé à Willy par WhatsApp le même jour) — contraintes
> gravées à l'inscription de la Phase 48 (ROADMAP.md § Phase 48, non planifiée ici).** L'injection
> d'index est **réservée aux labs pilotés par le moteur métier** : un lab dev garde ses messages
> GSD — jamais deux moteurs qui injectent un état, donc jamais deux vérités sur la phase courante.
> Contrainte de profondeur associée, mesurée en v2.63.2 le 2026-09-17 : tout agent générique de
> cycle (cadreur, planificateur, contrôleur de plan, orchestrateur, §4) qui en dispatche un autre
> vérifie la chaîne complète — l'outil Agent est absent à la profondeur 3.

### 7.2 Trois défauts corrigés

L'injection se déclenche sur **toutes les sources** — démarrage, reprise, `clear`, `compact` — et
non sur le seul `startup`. L'ambiguïté n'est **jamais du silence** : elle injecte l'INDEX et nomme
les candidats. Aucune sortie muette : un injecteur peut échouer, jamais mentir par omission.

Coût mesuré : auto-compact à **0,22 par session**, soit **+1,25 %** de contexte sur une session
longue.

### 7.3 L'hygiène

Les 20 fichiers ad hoc à la racine du planning d'un atelier ne sont pas de la négligence :
**aucune place n'était prévue pour ce que le travail produit**. Une commande dédiée les dépose au
bon endroit. **On ne refuse jamais sans offrir une porte.** Un cycle clos sort de l'index.

**Réserve ouverte** : `_bancs/` représente **904 fichiers, 45 %** du planning racine Keystone, et
un atelier porte 18 fichiers hors modèle sur 23. Le modèle ne nomme que huit emplacements. Où vont
`_bancs/`, `recherches/`, `intel/`, `sketches/`, `_archive/`, `registres/` ? À trancher au cadrage.

### 7.4 Le temps

> **Correction majeure.** La v1 dérivait le temps du disque. Mesuré : **les 2020 fichiers du
> `.planning/` racine de Keystone partagent un seul `mtime`** — tout clone ou checkout remet les
> dates à plat. Et l'inverse est vrai : un `INDEX.md` porte un mtime du 16 septembre pour un
> `last_updated: 2026-08-27`. Le mtime ment dans les deux sens. Git est **hors jeu par D-02**, et
> `last_updated:` est **aboli par D-03**. La v1 supprimait la seule source de temps qui fonctionne.

```
.planning/cloture.log        append-only, généré, jamais rédigé, hors bail
2026-09-22T14:31:07+02:00  cycles/03-.../phases/02-...  willy  verdict=86
```

Généré → conforme à D-03, protégé par G6. Contenu de fichier → **survit au checkout**. Il alimente
à lui seul la cadence (§8), le « dernier signe de vie » (§7.1) et la péremption des baux (§6).

### 7.5 Le pont mémoire

Une ligne `ARBITRÉ` du registre **est** une décision : elle porte qui a tranché, quand, où. À la
clôture, ces lignes deviennent des entrées de `DECISIONS`, les apprentissages du `SUMMARY` des
`LEARNINGS`. Le registre gagne une colonne **structurante (oui/non)** : seules ces lignes sont
promues, et seules elles ferment le cadrage (G1).

**Réserve ouverte** : un lab peut avoir plusieurs jeux de registres (Keystone en a quatre, avec
quatre réglages distincts) et BusinessFlow n'a ni `DECISIONS.md` ni `JOURNAL.md` — ses registres
s'appellent `BDR.md` et `ITERATION_LOG.md`. Dans quel registre écrit une clôture ? À trancher.

---

## 8. Les cycles sans fin

Un cycle à fin a des conditions ; un cycle récurrent a une **cadence**.

```yaml
recurrent: true
cadence: 14j
wip: 2
```

Chaque itération est une phase. Le cycle ne ferme jamais ; ses phases, si. Le retard se dérive de
`cloture.log`, le `wip` en comptant les phases ouvertes.

**Réserve ouverte** : un blocage peut être **externe** — un atelier réel attend un lien Drive d'un
tiers. Une cadence de 14 jours le marquerait en retard toutes les deux semaines pour un motif que
personne dans le lab ne peut lever. Il faut soit un état `bloqué par un tiers` non compté dans le
retard, soit une cadence suspendue sur dérogation.

---

## 9. Les trois natures de skill

| Nature | Effet sur le planning | Exemples |
|---|---|---|
| **Référentiel** | aucun | `vercel`, `sentry`, `dify-patterns` |
| **Outil** | aucun — hérite du périmètre courant | génération d'image, `pdf-contract` |
| **Procédure** | **ouvre une phase** | `post-diagnostic`, `post-session-recap` |

**Discrimination** : ce skill produit-il quelque chose ? Non → référentiel. Quelqu'un répond-il de
ce qui est produit ? Non → outil. Oui → procédure. **Le défaut est « outil ».**

### 9.1 La frontière doit être écrite, et gardée

Mesuré : **9 skills sur 142** portent un gate bloquant *et* un livrable externe — mais **32 sur 142
(23 %)** sont de forme procédurale. Cette frontière décide entre **~178 et ~420 phases par an**,
soit entre 712 et 2 100 fichiers de planning. Elle n'est écrite nulle part, et **D-07 n'a aucun
gate**. Le mode de panne est déjà documenté dans cette spec : neuf blueprints sur neuf ont dérivé
de leur contrôleur sans que personne le voie.

### 9.2 Ce qu'une procédure coûte réellement

| | Actuel | Sous le moteur |
|---|---|---|
| Fichiers écrits | 12 (médiane réelle) | 19 |
| Contexte | ~48 400 tokens | +3,3 % |
| Temps mur | 15-20 min | **+15 à 30 s** (+1,3 à 3,3 %) |
| Questions posées | 0 | **0** |

**Trou à combler** : G1 refuse un `PLAN.md` sans `CADRAGE.md`, mais une procédure n'est pas
re-cadrée. **L'exemption n'est écrite nulle part.**

---

## 10. Contraintes d'implémentation

- **D-09 — pas de bash pour le recalcul.** 133-212 s contre 9,7-12,4 s à 3 000 phases.
- **Incrémentalité par hash, jamais par mtime.** Mesuré : une signature sur les quatre fichiers
  réellement lus coûte ~66 ms à 3 000 phases, **86× moins** que le recalcul complet. Mais une
  signature par *mtime* reproduirait exactement le défaut reproché à `guard-planning-updated.sh`.
  **Hacher le contenu, pas les dates.**
- **Dire où le recalcul tourne.** Le volume n'est pas le problème (0,26 s pour 3 762 fichiers en
  cache chaud) ; la **fréquence** l'est. Un gate sur le chemin chaud de chaque écriture n'est pas
  du même ordre qu'un recalcul au SessionStart.
- **`VERDICT.md` porte le hash de l'artefact jugé et un numéro de tentative.** Sans quoi le budget
  de tours vit dans le contexte d'un manager et **un compact le perd** — le corpus contient déjà
  l'incident : *« je lui ai renvoyé deux fois des pièces qu'il avait rejetées »*, *« un verdict qui
  n'est pas écrit sera refait »*.
- **Le seuil de juge vit dans `config.json`** ; le modifier est un refus de classe G5 sauf
  dérogation nominative.

### 10.1 Ce que l'état de l'art dit de ces choix

**Dériver l'état est un espace quasi vide** : sur une trentaine de frameworks d'agents et d'outils
de spec-driven development, **trois** traitent l'état comme une projection recalculée. Le schéma
dominant est que l'agent LLM coche lui-même la case dans un Markdown. Pas de dette
d'interopérabilité à craindre, donc — mais pas de format éprouvé à reprendre non plus : **aucun
organisme ne normalise l'état d'avancement d'un projet.** Le seul dépôt formel en ce sens a été
fermé sept heures après son ouverture.

**Notre amont a déjà fait un saut que cette spec refuse.** `gsd-pi` (ADR-046) a rendu une base de
données autoritaire et les Markdown de simples projections : *« une édition de projection n'est pas
un changement d'état ; c'est du drift que le prochain rendu écarte silencieusement »*. Garder des
fichiers texte préserve la lisibilité et la diffabilité git, mais laisse entier le problème que la
base élimine : **si le Markdown est à la fois la source et la vue, rien ne distingue « ça s'est
passé » de « ça a été réécrit »**. Ce refus mérite son propre ADR.

**Quatre mesures fondent le choix du gate contre la prose :**

| Mesure | Ce qu'elle établit |
|---|---|
| **49,5 %** de violations d'une contrainte **explicite** en CLI (20 574 sessions) | Une consigne fraîche, explicite, dans la fenêtre courante échoue une fois sur deux. Une règle en prose chargée au démarrage ne peut pas faire mieux |
| **26,7 %** d'auto-rapports inexacts en CLI | D'où G4′ : le rapport d'un sous-agent sans preuve brute est refusé |
| **−5,6 % de conformité par fonction générée** (1 650 sessions, plan factoriel) | **Aucune** variable de structure du fichier de règles — taille, position, conflit, architecture — ne produit d'effet détectable. Réécrire, raccourcir ou mettre en gras ne change rien de mesurable ; **seul l'avancement dans la session dégrade la conformité** |
| **> 20 % de coût** sans gain de réussite pour les fichiers de contexte | Nuance à ne pas écraser : les *instructions* sont bien suivies ; ce sont les *vues d'ensemble* qui ne servent à rien. C'est une attaque contre le fichier-encyclopédie, pas contre la règle impérative courte |

**Et une grille à adopter** : un projet du domaine note chaque règle `advisory` (prose),
`enforced-at-commit` (git hook ou CI) ou `enforced` (contrôle natif in-agent qui *fail closed*),
en ne créditant un niveau **que là où un mécanisme installé est constaté**. Appliquée à ce dépôt :
`check-release-tag.sh` et `check-agents.sh` sont `enforced-at-commit`, la discipline de release en
prose est `advisory`, et **aucune règle n'est aujourd'hui `enforced`**. Ce moteur est la première
tentative d'en produire.

---

## 11. Ce qui reste ouvert

### 11.1 D-05 — refermée

Elle a été rouverte à tort pendant la révision, sur une migration chiffrée à 5 665 références. La
prémisse était fausse : Keystone n'est pas un lab à six plannings, **c'est six labs emboîtés**. Voir
§2, D-05. Aucune migration n'est due. Ce qui reste, c'est d'écrire G7 avec le bon critère — la
présence d'un `.claude/` habité — et de traiter les quatre orphelins de BusinessFlow.

### 11.2 L'arbitrage d'usage

`"phases_trace": false` et `"gates": false` dans le `config.json` de BusinessFlow-Lab. **Le traçage
a été essayé puis désactivé.** Aucune correction de design ne répond à ça. La question est : que
doit rendre le traçage pour valoir son prix, et à quelle frontière on le limite.

### 11.3 Trous nommés

Labs imbriqués (BusinessFlow porte 10 `.planning/`, dont 9 ni lab ni projet de code) · découverte
des plannings déjà cassée à `maxdepth 4` · renommage d'un cycle (un seul a touché 158 fichiers) ·
deux schémas `planning_version` (1.0 et 2.0) sans chemin de migration · frontmatter et chemin déjà
contradictoires dans le corpus · migration : **0 des 141 `PLAN.md` ne porte de périmètre, 0
`VERDICT.md`, 0 `CYCLE.md`**.

---

## 12. Hors périmètre

La fabrique d'agents et de skills · l'initialisation d'un lab · la veille automatique. Chacune aura
sa spec. Le cas d'usage qui les relie : **un diagnostic de lab parallélisé qui produit un cycle
d'architecture cadré et planifié**, au lieu d'un rapport qu'on lit et qu'on oublie.

---

## 13. Next step

Relecture humaine de cette révision, arbitrage sur D-05 et sur §11.2, puis plan d'implémentation.
Premier banc d'essai à choisir parmi les quatre retenus.
