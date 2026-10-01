# Changelog — planning-core

## [v2.9.0] — 2026-10-01 (moteur de planning métier — hook central par rôle et gates d'écriture, Phase 45)

**Minor** (nouvelle capacité) :

- **État d'armement livré** : les cinq gates sont ARMÉS (`ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`,
  `ARMEMENT_G7` et `ARMEMENT_ROLE` valent `armed`) et refusent, fermés sur défaillance ; `G2_MODE` vaut `avertit`
  (G2 avertit, ne refuse jamais). Les rejeux réels des étapes 1 à 4 avaient été mesurés sur le hook AVANT les lots de
  correction A, B et C du 2026-10-01 ; l'armement a donc attendu un NOUVEAU rejeu réel, sur des labs au repos, du hook
  livré : il est fait (relevé de phase `45-REJEU-FINAL.md`, commit `708debcb`, 0 faux refus, 0 faux accept,
  empreintes d'arbre identiques). L'arbitrage de Willy est rendu et appliqué (Q-ARM, AskUserQuestion session
  principale, 2026-09-30 : oui pour les quatre étapes d'armement, découplage des suites autorisé sans supprimer aucun
  cas ni aucun mutant) ; l'armement s'est fait en cascade le 2026-10-01, un commit par étape (`3d06e503` G6 et G5,
  `bf6cfa87` G1, `b6609fa6` G7, `239df76d` ROLE). Aucune release : le module reste en v2.9.0 (ADR-073).
- **`scripts/planning-hook.sh` et sa commande enregistrée fail-closed** — une seule entrée `PreToolUse` de
  `hooks.json` (forme shell, matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`) : lanceur bash et cœur Python
  embarqué (aucun `.py` posé par l'installeur). Dans un lab adhérent `cycles-v1` seulement, quand le script ou
  `python3` manque ou plante, la commande refuse `Write`, `Edit`, `NotebookEdit`, `Agent` et `Task` avec un
  message de réparation ; partout ailleurs (labs de développement, ce dépôt compris) il ne sort rien. Un refus est
  un `deny` JSON en code 0, jamais un exit 2. Échéance interne du cœur de 8 s (code 73, lot A).
- **G2 en avertissement** : avertit (`additionalContext`) sur une écriture hors du `ecrit:` des plans ouverts,
  Bash compris (détection, jamais une promesse, P45-D-10) ; il ne refuse jamais.
- **G6, G5, G1, G7 et le hook par rôle, chacun ARMÉ à sa propre étape** (ils refusent ; un gate armé qui rencontre
  une erreur interne refuse aussi) : G6 (fichiers générés, cache, journal de dérogation, adhésion de `config.json`) et G5 (`VERDICT.md`
  par outil) — étape 1, relevé `45-REJEU-ETAPE-1` ; G1 (pas de plan sans cadrage) — étape 2, relevé
  `45-REJEU-ETAPE-2` ; G7 (pas de planning orphelin, prédicat « habité » littéral) — étape 3, relevé
  `45-REJEU-ETAPE-3` ; ROLE (juge : aucune écriture par outil ; worker : dispatch limité à sa propre allowlist,
  F9) — étape 4, relevé `45-REJEU-ETAPE-4`. Chacun à 0 faux refus et 0 faux accept sur le banc et sur le rejeu
  réel ; les refus conformes au modèle (lab non migré) sont comptés à part (P45-D-21a).
- **Canary de CI et de session** : `plugin/_internal/tests/test-planning-hook-installed.sh` rejoue la commande
  telle que l'installeur la pose (bloquant en CI) ; `scripts/check-gates-alive.sh` (`SessionStart`, advisory)
  la rejoue sur un lab synthétique et signale, sans bloquer, un hook non enregistré, une commande non reconnue,
  un mode dégradé, des constantes d'armement absentes, un gate armé sans cas, une couverture incomplète, un cas
  en échec.
- **Outil de rejeu et geste de rejeu réel** : `scripts/rejeu-gates.sh` (copie du lab, un attendu par écriture,
  faux refus, faux accepts, refus conformes au modèle) et `scripts/rejeu-reel.sh` (empreinte de TOUT l'arbre
  avant et après, extérieure à l'outil mesuré ; `MESURE-VIDE` si rien n'a été mesuré).
- **Limite déclarée « Bash reste ouvert quand le hook ne peut pas tourner »** (P45-D-06b) : un lab adhérent dont
  le script ou `python3` manque refuse les écritures et les dispatchs mais laisse passer `Bash`, pour que la
  réparation reste possible.
- **Limites déclarées (k) et (l)** : (k) m2 — en mode panne, la couche shell tient pour adhérent un `config.json`
  que le cœur Python tient pour non adhérent (virgule finale, clé dupliquée, valeur imbriquée, BOM) : refus en
  panne ; (l) F9 — l'allowlist d'un worker vit dans une définition d'agent que G6 ne protège pas. Les limites
  (a) à (z), dont (y) — les réglages `.claude/settings*.json` ne sont pas protégés, les scripts du hook le sont
  (Q-G6 = b, ci-dessous), deux silences mesurés y sont écrits — sont écrites, chacune sur sa ligne, dans
  `references/modele-cycles.md` et tenues identiques au code par un contrôle croisé de la CI (R-REFERENCE, dont la
  liste des scripts du hook protégés).
- **Limite déclarée (z) — faux refus sous forte charge machine** : sous forte charge (observé en suites à charge 20 à
  35, jamais en rejeu réel), le cœur Python dépasse son échéance interne de 8 s (SIGALRM, « Alarm clock », code 73,
  limite (s)) ; la commande enregistrée ferme alors en `deny`, faux refus fail-closed d'une écriture légitime, jamais
  un faux accept. Point de surveillance après l'armement, non traité dans la Phase 45.
- **G6 protège les scripts du hook** (Q-G6 = b, Willy, AskUserQuestion session principale, 2026-10-01) : `Write`,
  `Edit` et `NotebookEdit` de `<lab>/.claude/scripts/planning-hook.sh` et `check-gates-alive.sh` (scope projet d'un
  lab adhérent) sont refusés par G6 (armé) ; dérogation nominative possible ;
  scope compte non protégé, Bash ouvert (P45-D-10). Un `.planning` situé sous un composant `.claude` n'est jamais
  une racine de lab (amendement de P45-D-01a, décision du manager vf-dev-manager, 2026-10-01 ; exception
  `.claude/worktrees/<nom>`), pour que cette protection ne se désarme pas par la création d'un tel dossier.
- **`scripts/poser-verdict.sh` et `scripts/deroger-gate.sh`** : le premier pose `VERDICT.md` (hash sha256 du
  `PLAN.md` et tentative calculés par la commande, seul chemin légitime une fois G5 armé) ; le second inscrit
  une dérogation nominative (qui, canal, date, gate, chemin, raison non placeholder, jamais liée à l'urgence)
  dans `.planning/derogations-gates.log`, append-only, à usage unique et citée par le hook.
- **Levée du code 2 de `recalc-planning.sh` sous adhésion (GATE-14)** : un lab adhérent qui contient du code
  (détecteur à 2, signalement de migration) est désormais écrit ; sans adhésion le refus est inchangé. Sort du
  socle v2 (F10 = f10-archive, Willy, AskUserQuestion session principale, 2026-09-30) : `STATE.md` et `INDEX.md`
  rédigés à la main sont archivés octet pour octet sous `.planning/_archive/socle-v2/` avant d'être remplacés.
- **Corrections ciblées du 2026-10-01** (revue de phase, audit de sécurité, re-revue et re-audit ; décisions du
  manager vf-dev-manager) : lot A (hook central : un `.planning` imbriqué n'est jamais une racine de lab, parseur
  d'agents linéaire et borné, échéance interne, version active d'un plugin, commandes de verdict et de dérogation
  durcies), lot B (rejeu : garde de lien, relevés anonymisés ; archivage du socle v2 en tout ou rien), lot C
  (budget d'indexation des agents, libellé du doute d'adhésion, `.planning` en lien refusé au rejeu).
- **`guard-planning-updated.sh` est conservé** (P45-D-19) : son entrée `Stop` de `hooks.json` est inchangée et il
  reste en exit 2.
- **Escalades vers Willy** : (1) l'armement — le nouveau rejeu réel sur des labs au repos est fait (relevé
  `45-REJEU-FINAL.md`, `708debcb`) et l'armement s'est fait en cascade (Q-ARM, Willy, AskUserQuestion session
  principale, 2026-09-30), la dernière étape étant ROLE (`239df76d`) : plus rien n'est ouvert ; (2) la protection du
  script du hook est tranchée et appliquée (Q-G6 = b, Willy, AskUserQuestion session principale, 2026-10-01, limite
  (y)) ; les réglages `.claude/settings*.json` restent non protégés (limite (y)) ; (3) G1 face à une phase dérogée
  sans cadrage (constat de 45-06 : zéro occurrence sur les deux labs réels mesurés, la règle de gate reste
  inchangée).
- **Ce qui n'est PAS livré** : G2′, G3, G4, G4′ et D1 (Phases 46 et 47), la vérification du hash à la clôture
  (Phase 46), le hook managed (hors périmètre) ; les drapeaux `phases_trace` et `options.gates` restent sans
  effet (P45-D-01). Bump de module seul (P45-D-18) : la version racine, `plugin.json` et le marketplace ne
  bougent pas, aucun tag, avant la clôture de `fiabilite-v1.0` (ADR-073).

## [v2.8.0] — 2026-09-28 (moteur de planning métier — modèle par cycles et recalcul d'état dérivé du disque, Phase 44)

**Minor** (nouvelle capacité) :

- **`scripts/recalc-planning.sh`** — point d'entrée bash mince + moteur Python embarqué (motif
  déjà en place dans `plugin/conductor/scripts/dag.sh`, aucun changement d'installeur : la voie
  par défaut de P44-D-14 évite l'extension de `vibeflow-update.sh` à `*.py`). Dérive du disque
  huit états (dont `indéterminé`) pour les cycles, phases et plans d'un lab métier — jamais un
  état déclaré. Un lab n'obtient l'écriture qu'après adhésion explicite (`"planning_version":
  "cycles-v1"` dans `.planning/config.json`) ; sans adhésion, ou sur un planning détecté comme
  tenu par GSD, le recalcul refuse d'écrire, cache compris. Mode `--read-only` : dérive n'importe
  quel planning, adhérent ou non, JSON sur la sortie standard uniquement, aucun fichier touché.
- **`references/modele-cycles.md`** et **`references/templates/cycles/*`** (huit gabarits) —
  le modèle : `cycles/`, `phases/`, `CYCLE.md`, `CADRAGE.md` (registre d'inconnues), `PLAN.md`
  (champ de périmètre `ecrit:`), fichier marqueur de clôture de plan (jamais `PLAN.md` lui-même,
  dont le hash reste stable), `VERDICT.md`, `SUMMARY.md`, liste fermée des six emplacements
  annexes.
- **Huit états dont `indéterminé`** : toute combinaison de signaux non prévue rend `indéterminé`,
  jamais une supposition (« un faux vert est pire qu'un aveu »). Dérogations nominatives
  (`abandonné | remplacé | gelé`, auteur obligatoire) ; une dérogation sans auteur rend
  `indéterminé`.
- **`INDEX.md`, `STATE.md`, `cloture.log`** régénérés à chaque passage — sortie déterministe
  (deux recalculs sur le même disque produisent des fichiers identiques octet pour octet) ;
  `cloture.log` en **ajout seul**, jamais une ligne réécrite ou supprimée.
- **Incrémental par hash du contenu** (`.planning/.recalc-cache.json`, `cache_schema_version`),
  jamais par `mtime` : un cache absent, illisible, en lien symbolique, ou d'un autre schéma/moteur
  provoque un recalcul complet, jamais une confiance aveugle ; jamais chargé ni écrit en mode
  `--read-only`.
- **Hors modèle** : tout ce qui n'est ni le modèle ni l'une des six annexes est signalé « hors
  modèle » dans `INDEX.md` — signalé, jamais refusé, jamais déplacé, jamais suivi (liens
  symboliques de dossier ou de fichier compris) ; noms piégés (saut de ligne, catégorie Unicode
  C*) échappés au rendu.
- **Lecture seule** prouvée sans écriture sur deux labs réels du poste (empreinte sha256 de
  l'arbre complet avant/après, identique) : voir `44-PASSAGE-LABS.md`.
- **Banc synthétique versionné** (`scripts/tests/test-recalc-planning.sh`,
  `scripts/tests/fixtures/recalc-planning-banc.txt`) — seul à gater en CI ; chaque garde prouvée
  par une mutation rouge tracée.
- **Ce qui n'est PAS livré dans cette phase** : aucun hook ni gate câblé (le recalcul est une
  commande, pas encore branchée à un déclencheur — arrive en 45/48) ; les fichiers générés
  (`INDEX.md`, `STATE.md`, `cloture.log`, cache) ne sont pas encore protégés contre l'écriture à
  la main (G6, Phase 45) ; le socle métier existant de `planning-core` (`guard-planning-updated.sh`
  et sa mesure par `mtime`) n'est **pas retiré** — le remplacement est additif, les labs qui
  n'adhèrent pas restent sur l'existant.
- **Correctifs de revue et d'audit (correction ciblée, lot 1 puis 2 puis 3)** : consommation de
  `os.scandir` ramenée entièrement dans son `try` (`_lister_entrees`) ; un lien symbolique (ou
  tout emplacement non régulier au sens `lstat`) à la place d'`INDEX.md`, `STATE.md`,
  `cloture.log` ou `.recalc-cache.json` refuse désormais toute l'écriture au lieu d'être remplacé
  en silence ; fuite de descripteur comblée dans `ecrire_si_different` sur le chemin d'échec de
  `fchmod` ; six marqueurs de `detection_gsd()` reçoivent leur premier mutant de couverture ; le
  code 2 du détecteur GSD (signalement de migration) n'est plus assimilé au code 3 (terrain
  libre) — il refuse désormais l'écriture comme un moteur GSD détecté ou une détection non
  concluante ; assainissement structurel de tout champ recopié dans `cloture.log`
  (`_jeton_journal`, pas seulement `tentative`) contre l'injection d'un faux enregistrement.
- **Lot 3** : `lignes_a_journaliser` comparait la valeur BRUTE de l'unité courante au jeton déjà
  assaini relu dans `cloture.log` — une `tentative` contenant un espace ou un `=` (lue telle
  quelle depuis `VERDICT.md`, jamais validée, P44-D-09) se rejournalisait à chaque exécution ; la
  comparaison porte désormais sur la valeur assainie des deux côtés (revue, `260928-b4c-VERIFICATION.md`
  truth #10, jamais éprouvée par un aller-retour réel). `detection_gsd()` : quand la chaîne GSD
  est absente de la machine (`GSD_HOME` introuvable, forcé ou hérité de l'environnement), le
  détecteur sortait en code 1 **avant** d'avoir pu évaluer sa priorité 3 (socle planning-core +
  signal de code → migration à examiner) — le repli du code 1 ne rejouait que les priorités 2/2bis
  (marqueurs GSD), laissant écrire sur un planning que l'environnement normal aurait refusé ; la
  combinaison socle+signal est désormais reproduite en Python pur, indépendamment de toute valeur
  d'environnement (aucune dépendance de code vers `detect-gsd-engine.sh`, P44-D-01b/P44-D-01d).
  Accessoirement : le sous-processus du détecteur résout `bash` par `shutil.which` — **corrigé au
  lot 5** : `shutil.which` résout toujours sur le `PATH` hérité de l'appelant, pas indépendamment
  de lui ; voir l'entrée lot 5 ci-dessous.
- **Lot 4 (correction de CLASSE)** : la réimplémentation Python des priorités 2/2bis/3 du
  détecteur, ajoutée au lot 3 pour fermer le repli du code 1, a elle-même divergé mesurément de
  l'original sur trois cas (revue + audit) : un `package.json` en lien symbolique (bash `[ -f ]`
  le suit, `os.lstat` non), un `*.xcodeproj` en lien symbolique (même écart avec `[ -d ]`), et un
  `STATE.md` aux octets UTF-8 invalides **après** le frontmatter (le décodage UTF-8 strict du
  fichier entier échouait, awk — qui ne lit que le frontmatter — trouvait le marqueur sans
  encombre). Dans les trois cas, avec `GSD_HOME` inexistant, le moteur écrivait (exit 0) sur un
  planning que le détecteur réel classe en code 2, et effaçait le marqueur `planning_version`.
  `detection_gsd()` appelle désormais le VRAI détecteur bash — plus aucune réimplémentation — dans
  un environnement MAÎTRISÉ (`GSD_HOME` fixé explicitement au dossier du détecteur, qui existe
  toujours), neutralisant structurellement la priorité 1 du détecteur au lieu de la contourner ;
  écriture autorisée SEULEMENT si le détecteur rend 3 ; détecteur absent, en lien symbolique, non
  régulier, illisible, ou dont le lancement échoue → refus fail-closed nommé, jamais une retombée
  en écriture. `_jeton_journal` (P44-D-11) passe d'un assainissement par `_` (non injectif — `"3
  4"` et `"3_4"` s'écrasaient sur le même jeton, pouvant faire manquer une clôture réellement
  nouvelle au dédoublonnage) à un encodage pourcent INJECTIF (preuve générative 2000 paires,
  round-trip réel à deux exécutions).
- **Lot 5 (F1/F44-07, correction de CLASSE — audit + revue)** : l'environnement « maîtrisé » du
  lot 4 était en réalité `dict(os.environ)` avec la seule surcharge de `GSD_HOME` — une COPIE
  INTÉGRALE du `PATH` hérité, qui laissait les priorités 2/2bis/3 du détecteur (`awk`/`mktemp`/
  `wc`/`cat`/`basename`) entièrement soumises à ce `PATH`. Mesuré : un `awk` factice en tête de
  PATH suffisait à faire écrire (exit 0) le moteur sur un lab GSD réel et à **effacer le marqueur**
  `gsd_state_version`. L'environnement du sous-processus détecteur est désormais construit DE ZÉRO
  (liste blanche PATH fixe + GSD_HOME, aucune autre variable héritée — ni `BASH_ENV`, ni `ENV`, ni
  une fonction exportée `BASH_FUNC_*%%`) ; `bash` n'est plus résolu par `shutil.which` sur ce même
  PATH mais par une liste fixe de deux chemins absolus (`/bin/bash`, `/usr/bin/bash`), chacun
  validé par `lstat` — aucun candidat valide : refus fail-closed nommé. Prouvé par cinq nouvelles
  colonnes de `R-MATRICE-ENV` (PATH empoisonné par un faux `awk`/`bash`, `BASH_ENV`, fonction
  exportée, `ENV`) et deux mutants dédiés (`MUT-ENV-OS-ENVIRON`, `MUT-BASH-VIA-PATH`) tués sur le
  scénario même qui a établi la trace rouge d'origine. Correctifs voisins de la même correction
  ciblée : `_jeton_journal` échappe désormais aussi tout caractère non imprimable (NUL, contrôles
  C0/C1), jamais laissé brut ; un jeton vide (repli vide) est une `ValueError` bruyante, jamais une
  ligne de journal illisible écrite en silence ; « détecteur absent » et « détecteur non régulier »
  portent deux messages stderr distincts ; `ecrire_si_different` lit l'existant par `O_NOFOLLOW`
  (alignée sur le reste des lectures du modèle) au lieu d'un `open()` nu.
- **Lot 6 (correction ciblée, audit du 2026-09-28)** : `vf_ws_enumerate` (`workstream-policy.sh`,
  hors périmètre de cette phase, P44-D-01b) émet un chemin absolu par ligne pour chaque
  compartiment de `workstreams/` — un contrat que deux classes RÉELLES brisent SILENCIEUSEMENT (le
  détecteur rend le code 3 « terrain libre » sans aucun diagnostic distinct du cas nominal) : un
  nom de compartiment portant un saut de ligne (la ligne imprimée se scinde en deux, invisible à la
  lecture) et un nom de compartiment commençant par un point (invisible au glob sans `dotglob`) —
  une troisième, le chemin du dossier de planning lui-même porteur d'un saut de ligne, casse
  l'énumération entière d'un coup. Mesuré par exécution dans l'environnement maîtrisé exact du
  moteur : un compartiment réellement porteur de `gsd_state_version`, masqué par l'une de ces
  classes, faisait écrire (exit 0) `INDEX.md`/`STATE.md`/`.recalc-cache.json` sur un planning tenu
  par GSD — violation directe de P44-D-02a. `recalc-planning.sh` ferme la conséquence entièrement
  côté appelant (`_enumeration_workstreams_fidele`, AVANT tout appel au détecteur, jamais une
  relecture de `STATE.md` ni une réimplémentation des priorités 2/2bis/3) : un compartiment réel
  que l'énumération ne restituerait pas fidèlement rend le verdict du détecteur non vérifiable,
  refus nommé, zéro octet écrit — `detect-gsd-engine.sh` et `workstream-policy.sh` restent
  INCHANGÉS (P44-D-01b), le trou racine reste ouvert pour Samuel (BACKLOG.md, propriétaire de
  `workstream-policy.sh`, Phase 41.1). Une entrée en lien symbolique reste une exclusion DÉCLARÉE
  du détecteur lui-même (avertissement stderr), volontairement pas traitée comme masquante ici.
  Correctifs de revue voisins (comportement inchangé) : commentaire corrigé sur `--noprofile
  --norc` (n'affectent pas `BASH_ENV`/`ENV` en non-interactif — la protection vient exclusivement
  de l'environnement maîtrisé construit de zéro) ; conséquence fail-closed totale de
  `CANDIDATS_BASH` sur un système sans `/bin/bash` ni `/usr/bin/bash` documentée
  (`references/modele-cycles.md`) et message stderr explicité ; l'invariant final de
  `_jeton_journal` (P44-D-11) passe d'un `assert` nu (désactivable par `python -O`) à une exception
  explicite toujours active.
- **Lot 7 (correction de CLASSE, audit du 2026-09-28)** : la garde du lot 6 fermait deux classes
  structurelles (noms piégés) mais pas la classe plus large mesurée ensuite — `vf_ws_enumerate`
  (`workstream-policy.sh:305-306`, hors périmètre P44-D-01b) pose `found=1` inconditionnellement
  après chaque `printf`, même quand `cd "$entry" && pwd` a ÉCHOUÉ (compartiment sans bit `x`,
  mode `000`/`600`/`400`) : ligne vide silencieusement sautée par `detect-gsd-engine.sh`, priorité
  2bis retombe sur le code 3 « terrain libre » sans aucun diagnostic. Mesuré : le moteur écrivait
  (exit 0) sur un compartiment réellement tenu par GSD ; et, quand le marqueur porté est au
  `STATE.md` **racine** lui-même rendu illisible (mode `000`), le moteur allait jusqu'à
  **écraser** ce `STATE.md`, effaçant `gsd_state_version`. Principe retenu, plus large que le lot
  6 (`_enumeration_workstreams_fidele` remplacée par `_lecture_detecteur_fidele`) : *le moteur
  n'écrit que s'il a pu LIRE, pour de vrai, tout ce que le détecteur devait lire* — fidélité PAR
  EXÉCUTION de `vf_ws_enumerate` (relancée dans le MÊME bash et le MÊME environnement maîtrisé que
  le détecteur, comparée à l'ensemble réel du disque dérivé par `os.scandir`) et lisibilité RÉELLE
  (ouverture effective, jamais `os.access`) de chaque compartiment retenu et de chaque `STATE.md`
  (racine et compartiments). `detect-gsd-engine.sh` et `workstream-policy.sh` restent INCHANGÉS
  (P44-D-01b) — appelés, jamais réimplémentés ni modifiés. Toute `OSError` rencontrée par la garde
  est désormais un refus nommé (F2, revue du lot 6 : un `continue` silencieux sur `is_symlink()`/
  `is_dir()` sous exception était un fail-open). F3 (revue) : le docstring de la garde distinguait
  mal « absent » (code 3, silence nominal) de « lien/non-répertoire/illisible » (code 2) — corrigé.
  Le trou source dans `vf_ws_enumerate` reste hors de portée (P44-D-01b), transmis au BACKLOG pour
  Samuel (propriétaire de `workstream-policy.sh`, Phase 41.1).
- **Lot 8 (correction de CLASSE, audit du 2026-09-28)** : deux corrections indépendantes de la
  garde de lecture du lot 7. (1) Un lien symbolique CASSÉ (cible absente) à l'emplacement d'un
  `STATE.md`, racine ou de compartiment, est désormais traité comme ABSENT — exactement comme le
  détecteur, dont le `[ -f ]` (`detect-gsd-engine.sh:96,184`) suit le lien et n'y tente aucune
  lecture sur une cible manquante. `os.path.isfile` (mirroir exact de `[ -f ]`) remplace
  `os.path.lexists`, dont l'usage confondait un lien cassé (`ENOENT`, aucune lecture possible) avec
  une vraie erreur de lecture : sur-refus mesuré (écriture refusée sur un planning SANS AUCUN
  marqueur GSD, uniquement parce qu'un `STATE.md` de compartiment était un lien cassé). Le
  `STATE.md` racine en lien cassé reste TOUJOURS refusé, mais par la garde B de
  `appliquer_ecritures` (« emplacement occupé », F4) — jamais un double refus, jamais une écriture
  à travers le lien. (2) `_ouvrable` ouvre désormais en `O_NONBLOCK` et contrôle le type par
  `fstat` : un `STATE.md` en FIFO n'y bloque plus jamais (mesuré, blocage indéfini sur HEAD
  345303e faute de tout processus tenant l'extrémité écriture). Correction de prose associée : le
  commentaire de la garde de lecture laissait entendre que les classes structurelles du lot 6 « ne
  décident jamais seules » — elles sont en réalité fusionnées dans la même liste de décision que
  l'égalité d'ensembles et la lisibilité réelle, n'importe laquelle des trois suffisant seule à
  refuser. `detect-gsd-engine.sh` et `workstream-policy.sh` restent INCHANGÉS (P44-D-01b).
- **Lot 9 (correction de portabilité GNU/BSD)** : le banc `scripts/tests/test-recalc-planning.sh`
  rendait `✗ R14 permissions` sur le runner CI Linux (ubuntu-latest, run 36430707398) alors que
  vert sous macOS — trois sites identiques `MODE=$(stat -f "%Lp" f 2>/dev/null || stat -c "%a" f
  2>/dev/null)` (R14, MUT-CHMOD, MUT-CHMOD-JOURNAL) : sous GNU coreutils, `stat -f` désigne le
  système de fichiers, pas le format de sortie — la commande échoue mais imprime déjà un bloc
  `File:`/`ID:`/`Type:` sur stdout avant d'échouer, puis le repli `stat -c` s'exécute dans la MÊME
  substitution de commande et ajoute `644` à la suite, produisant une chaîne multi-ligne jamais
  égale à `"644"`. Remplacé par `mode_octal()`, une seule fonction lisant `os.stat(...).st_mode &
  0o777` via `$PYBIN` (déjà une dépendance du banc) — une seule sémantique, indépendante du binaire
  `stat` du PATH. Reste du banc balayé pour d'autres constructions GNU/BSD divergentes : aucune
  autre correction nécessaire.

Décisions P44-D-01 à P44-D-18 — Willy, AskUserQuestion session principale, 2026-09-27. Correctifs
lot 1 : vf-coder, mandat de correction ciblée, 2026-09-28. Lot 2 (code 2 du détecteur,
assainissement du journal), lot 3 (dédoublonnage assaini, repli code 1 sur socle+signal), lot 4
(source unique de vérité pour la détection GSD, encodage injectif du journal), lot 5
(environnement maîtrisé du sous-processus détecteur construit de zéro, alphabet du journal étendu
aux contrôles C0/C1), lot 6 (garde de fidélité d'énumération des compartiments de workstream,
correctifs de revue), lot 7 (garde de lecture du détecteur, correction de classe — fidélité par
exécution + lisibilité réelle), lot 8 (lien cassé traité comme absent, FIFO non bloquante,
correction de prose) et lot 9 (portabilité GNU/BSD du lecteur de mode du banc) : décision du head
sous délégation technique de Willy, session principale, 2026-09-28.

## [v2.7.2] — 2026-09-28 (seuil mesurable du STATE)

**Patch** (doctrine) :

- **`references/bridge-memory.md` §Pont 2** : « STATE ne garde que le courant » reçoit un seuil
  (8 Ko, mesuré par `conductor/scripts/check-method-budget.sh`) et une règle de tenue : un nouveau
  point remplace la position courante, l'ancien part dans `.planning/archives/state/`.

## [v2.7.1] — 2026-09-24 (gates de planning workstream-aware, Phase 41.1)

**Patch** (durcissement de gates workstream-aware, Phase 41.1) :

- **`scripts/workstream-policy.sh`** : `vf_ws_enumerate` (neuve) — primitive **unique**
  d'énumération disque des compartiments `.planning/workstreams/<nom>/`, contrat de sortie
  `0` (au moins un compartiment) / `2` (dépôt non partitionné) / `3` (indéterminé), filtrée
  anti-lien symbolique. Les gates cessent de réimplémenter chacun leur propre balayage.
- **`scripts/detect-gsd-engine.sh`** et **`scripts/check-planning-state.sh`** : cessent d'être faux
  sur un dépôt partitionné — ils balaient les compartiments au lieu de résoudre littéralement la
  racine de `.planning/`, et sans jamais dégrader en silence quand le balayage est indéterminé.

## [v2.7.0] — 2026-08-16 (Portabilité Windows II — codes de sortie, PORT-03/D-07)

### Changé
- **`check-planning-state.sh` et `detect-planning-debt.sh` gagnent le drapeau `--hook`** (parité
  d'interface avec le reste du parc), pas encore passé par leur fragment `hooks.json` — ce
  câblage appartient à la migration en forme exec de la polarité gouvernance, hors périmètre de
  ce plan. Sous `--hook`, TOUS leurs codes advisory deviennent 0 à la frontière du harness (1/2/3
  pour `check-planning-state.sh`, 1/3 pour `detect-planning-debt.sh`) — contrairement au reste du
  parc, ni l'un ni l'autre n'avait de code « signal » déjà à 0 : leurs diagnostics vivent tous
  hors de 0, donc les trois (ou deux) migrent ensemble pour continuer à injecter leur message
  dans le contexte de session sous le nouveau contrat. `--hook` et `--quiet` ensemble → exit 64
  (même code d'erreur d'argument que le reste du script). Sans `--hook` (CLI, suites de tests),
  aucun code ne change. `guard-planning-updated.sh` — dont le blocage EST son code de sortie
  (exit 2) — n'est PAS touché : c'est le comportement voulu, jamais un défaut de normalisation.

Voir `docs/HOOKS-CONTRAT-SORTIE.md` pour le contrat complet.

## [v2.6.1] — 2026-08-15

### Changé
- **`memory_bridge.enabled` passe à `true` dans le gabarit de configuration.** Le pont
  `.planning/` (l'avant) ↔ `.claude/memory/` (le passé) était éteint par défaut, ce qui contredisait
  la doctrine du socle : la capitalisation est le principe 1 de VibeFlow. Cohérent avec le passage
  de `consolidator` en module `mandatory` (v1.9.0) — les registres existent maintenant dans tout
  lab, le pont peut donc être ouvert d'emblée.
- **Portée réelle, dite sans détour** : aucun script ne lit cette clé aujourd'hui (`grep` sur tout
  `plugin/` : la seule occurrence est le gabarit lui-même). Le pont est appliqué par le SKILL
  `planning-core` — donc par jugement d'agent, pas par une garde machine. Ce basculement est
  **déclaratif** : il aligne le défaut sur la doctrine et rend l'intention lisible pour l'agent qui
  lit la config, il n'ajoute aucune contrainte exécutable. Si le pont doit devenir opposable, c'est
  une garde à construire, pas ce flag à retourner.

## [v2.6.0] — 2026-08-04 (une politique de nom de workstream, UNE seule, sourcée par les gates)

### Ajouté
- **`scripts/workstream-policy.sh`** — la politique de nom de workstream devient **unique** et
  partagée. Quatre gates la validaient chacun à leur façon : quatre variantes divergentes d'une même
  règle, donc quatre occasions d'accepter ce que le voisin refuse. Ils la **sourcent** désormais tous
  (`check-workstream-pointer.sh`, `check-state-integrity.sh`, `check-dev-bootstrap.sh`,
  `planning-context.sh`) et l'appliquent à l'identique. La politique est conforme à l'amont, et sa
  suite `test-workstream-policy.sh` le vérifie — angles morts compris (`.`, `..`, lien symbolique).

  Le module hôte est `planning-core` parce que sa fermeture de dépendances est réduite à lui-même :
  les quatre consommateurs peuvent le sourcer sans tirer de module supplémentaire.

### Modifié
- **`planning-context.sh` injecte le `STATE.md` du compartiment actif et le nomme** (GSDA-14) : sur
  un `.planning/` partitionné, le contexte servi provenait de la racine quel que soit le workstream
  résolu — il décrivait donc un autre chantier que celui en cours, sans jamais le dire.
- **`planning-context.sh --max-lines`** cesse d'injecter une erreur d'outil dans le contexte produit :
  un message d'erreur passé pour du contenu est pire qu'une troncature annoncée.

### Corrigé

- **`vf_ws_trim` ne forke plus `awk`** — la borne de longueur du canal nominal était **inerte sur
  Linux**. `vf_ws_trim` pipait sa valeur vers `awk` ; pendant cet appel `GSD_WORKSTREAM` reste
  exportée, `execve()` en hérite, et le noyau Linux borne **chaque chaîne** d'`argv`/`envp` à
  `MAX_ARG_STRLEN` (128 KiO) — une limite indépendante d'`ARG_MAX`, **absente sur macOS/BSD**. Au-delà,
  `execve` échoue en `E2BIG`, le pipeline ne tourne jamais, la valeur revient vide et la borne
  `VF_WS_VALUE_MAX_BYTES` qui suit n'a plus rien à refuser : une valeur de 200 000 octets passait.
  Réécrite en bash pur (`[[ =~ ]]` + découpage par indices), sans aucun `execve()`, avec une classe
  de blancs explicite plutôt que `[[:space:]]` dépendant de la locale. Le défaut n'était **pas
  reproductible en local sur macOS** — il n'a été attrapé que sur le runner Linux de la CI.

- **Échappement du répertoire de compartiment par lien symbolique** (`T-24-14-C1`, **4ᵉ passage du
  motif dans ce dépôt**). La politique contraignait le **nom** du workstream et refusait un
  pointeur-**fichier** en lien symbolique ; le **chemin** du compartiment, lui, n'était contraint par
  rien. Les gates construisaient `<planning>/workstreams/<nom>` puis testaient `[ -d ]` — et `[ -d ]`
  **suit le lien**. Un `.planning/workstreams/dev` versionné en mode `120000` vers un répertoire hors
  du lab suffisait à faire **injecter le `STATE.md` de la cible dans le contexte de session**, en
  exit 0 et **sans aucune action de la victime** au-delà de l'ouverture de session (hook
  `SessionStart`). Reproduit sur dépôt piégé le 2026-08-04.

  Deux primitives neuves dans **`workstream-policy.sh`** : `vf_ws_dir_resolve` (résout le
  compartiment sans jamais traverser un lien — les **deux** segments sont contraints, `workstreams`
  lui-même puis `workstreams/<nom>`, car détourner le premier détourne tous les compartiments d'un
  coup) et `vf_ws_file_in_ws` (même contrôle sur les **fichiers** du compartiment : fermer le
  répertoire en laissant le `STATE.md` ouvert verrouillerait la porte en laissant la fenêtre —
  `[ -f ]` suit le lien exactement comme `[ -d ]`).

  **Posture : on refuse de suivre**, on ne tente pas de décider si la cible est « dans le lab ». Un
  tel test se réécrit avec `..`, dépend d'un `readlink -f` absent de macOS et ne survit pas à un
  remontage. La cible n'est **jamais lue, jamais nommée** ; seule la raison sort, prise dans une
  **énumération fermée** (`workstreams-lien-symbolique`, `compartiment-lien-symbolique`,
  `fichier-compartiment-lien-symbolique`).

  **`planning-context.sh`** consomme ces primitives selon la gradation par rôle déjà déclarée dans la
  politique : **rôle injecteur** → repli sur la racine **plus une ligne qui nomme le refus**, jamais
  un silence (un exit non nul dégraderait toutes les sessions). Le **cas licite est inchangé à
  l'octet près** : un vrai répertoire reste vert. Nouvelle suite dédiée
  `test-workstream-symlink-escape.sh` — la fermeture est prouvée **par mutation, sur les quatre
  gates à la fois** (garde retirée → les quatre refuient).

## [v2.5.3] — 2026-07-31

### Corrigé
- `detect-gsd-engine.sh` cite désormais `@opengsd/gsd-core@1.9.0` au lieu de `1.8.0` (purge de
  dette de version, Phase 21, alignement gsd-core 1.9.0). Aucun changement de contrat de sortie :
  les codes d'exit restent inchangés.

## [v2.5.2] — 2026-07-26

### Corrigé
- `detect-gsd-engine.sh` résout désormais `GSD_HOME` en dual-layout (`gsd-core` prioritaire,
  `get-shit-done` legacy en repli) — Phase 11, intégration migration GSD. Aucun changement de
  contrat de sortie : les codes d'exit `0`/`1`/`2`/`3`/`64` restent inchangés.

## [v2.5.1] — 2026-07-26

### Corrigé
- `gsd-handoff.md` : renvoi vers le chemin d'install D7 réel de la carte d'intention (au lieu du chemin du repo source).

## [v2.5.0] — 2026-07-25

### Ajouté
- Stop-hook proportionné au profil : `warn` par défaut en profil léger (lu dans `.planning/config.json`), `block` sinon ; `VF_PLANNING_STOP` prime toujours, fallback sûr. 4 tests de garde ajoutés. Renvois dev basculés sur les briques gsd (modèle agentique).

## [v2.4.1] — 2026-07-25

### Corrigé
- Références `/checkpoint` (commande inexistante) → `/vf-audit` dans SKILL, README et domain-detection.

## [v2.4.0] — 2026-07-25 (ADR-055 — frontière d'altitude avec le moteur de planning de développement)

**Le conflit** : `vf-planning` et la chaîne de développement produisaient **les mêmes fichiers** dans
**le même dossier** avec des frontmatters **incompatibles** (`planning_version` + `progress.total_steps`
d'un côté, `gsd_state_version` + `progress.total_phases/total_plans` de l'autre). Le premier moteur qui
écrivait rendait l'autre aveugle. S'y ajoutaient une double injection `SessionStart` et une concurrence
au matching sémantique : la description revendiquait « fais-moi une feuille de route » et « où en est-on ? ».

**La règle** : un projet de code a **un seul** moteur de planning. `planning-core` tient désormais
l'altitude **lab** (index des projets, compartiments typés, seuil d'autonomie, dette), la couche **à
côté** (pont mémoire, enforcement), et le **socle complet des labs non-dev**.

### Ajouté
- **`scripts/detect-gsd-engine.sh`** — répond au **fait** « un moteur de planning est-il en place ? »,
  4 exits évalués par ordre de priorité. **N'infère aucun métier** : le métier reste du jugement
  (`domain-detection.md`), les signaux de code déclenchent un examen, jamais un verdict. Le marqueur lu
  est une clé du **frontmatter** de `STATE.md`, jamais une chaîne trouvée ailleurs dans le fichier.
- **`references/gsd-handoff.md`** — test unique (« projet, ou lab ? »), table de partage, table de
  redirection intention → verbe, périmètre résiduel sur lab dev, protocole de migration.
- **Flag `--defer-to-gsd`** sur `check-planning-state.sh` et `planning-context.sh`, câblé dans
  `hooks/hooks.json` : fin de la double injection au démarrage. L'`INDEX.md` du lab **reste injecté** —
  c'est de l'altitude lab, le moteur de dev ne le produit pas.

### Changé
- **`SKILL.md`** — description rescopée : les intentions de projet dev partent, avec contre-exemples
  nommant `/vf-init`, `/vf-progress`, `/vf-plan`, `/vf-map`. Étape 0 de branchement (un fait + un
  jugement), puis séquence A (socle universel non-dev) ou séquence B (couche lab).
- **`references/domain-detection.md`** — la première ligne de grille (code → dev) ne conduit plus à
  scaffolder un tronc ; le principe anti-détecteur est réaffirmé, pas renié.
- **Périphérie** — commande `/vf-planning`, `vf-new-lab` (qualification du métier + route `/vf-init`),
  table de routage du `conductor`, et les 3 README alignés.

### Inchangé (délibérément)
- **`guard-planning-updated.sh` reste bloquant** sur tous les labs. Exception motivée : il ne génère
  rien, il vérifie une propriété du *résultat* quel qu'en soit l'auteur — et le moteur de dev n'offre
  aucun équivalent bloquant.
- **Comportement par défaut** des scripts : `--defer-to-gsd` est opt-in, l'usage manuel et le
  `/checkpoint` sont intacts. Un cas de test dédié verrouille cette non-régression.
- **Les 4 bundles non-dev** (`content`, `business-pilot`, `growth`, `kpi-analyst`) : tous en séquence A.

### Limite connue
- **Pas de migration automatique** d'un `.planning/` existant : `gsd-import --from` n'importe qu'un plan
  isolé, pas un socle entier. L'exit 2 signale, le skill avertit et propose — l'utilisateur décide
  (ADR-031). Les compteurs `progress.total_steps` et le champ `profile` n'ont pas d'équivalent.

### Tests
94 assertions vertes, 0 échec (`detect-gsd-engine` 12, `detect-planning-debt` 10,
`planning-context-hardening` 20, `planning-core` 14, `planning-hooks` 38).
## [v2.3.1] — 2026-07-23 (portabilité Windows — ADR-054)

### Corrigé
- **`planning-task-context.sh`** : le stub Microsoft Store `python3` (présent dans le PATH mais
  inerte) rendait le contexte de tâche muet sous Windows sans jamais déclencher son repli
  fail-open. Résolution d'interpréteur par CHEMIN (zéro spawn ajouté, rejet `WindowsApps`,
  repli `python`). Le hook Stop (`guard-planning-updated.sh`) n'est pas concerné : zéro
  dépendance python/jq par construction.

## [v2.3.0] — 2026-07-20 (ADR-050 amendée — attribution de session : fix faux positifs du guard Stop)

### Corrigé (retour terrain Samuel : « faux positifs quasi systématiques » du guard Stop)
- **`guard-planning-updated.sh` v2 — raisonne en « changé pendant CETTE session »**, plus en état
  du working tree. La v1 ne regardait que `git status --porcelain` alors que Stop se déclenche à
  CHAQUE fin de tour (et `stop_hook_active` retombe après chaque message utilisateur) → deux faux
  positifs systématiques : un `STATE.md` mis à jour **puis committé** (flow GSD/dev-orchestrator)
  devenait invisible → blocage à tort à chaque tour ; du **dirt préexistant** au démarrage était
  attribué à la session. Désormais :
  - Signaux « planning mis à jour » LARGES (un seul suffit) : committé pendant la session
    (`git log --since=début`, commits tiers d'un pull/merge exclus par committer-date) ∪ sale
    (porcelain) ∪ mtime strictement postérieur au début (couvre `.planning/` gitignoré, GSD).
  - Attribution « livrable changé » STRICTE : committé dans la fenêtre de session ∪ dirt absent
    de la baseline ou au statut/hash blob modifié. Le dirt préexistant n'est JAMAIS attribué.
  - **Au pire UN blocage par session** (marqueur `.blocked` + anti-boucle `stop_hook_active`) ;
    baseline absente/périmée (>48h), arbre >400 entrées sales → fail-open ; le motif cite les
    livrables attribués et annonce le one-shot.
  - Latence par tour maîtrisée : boucle bash sans spawn + UN awk (join baseline↔porcelain) +
    UN `git hash-object` batch + `find -newer` sur la baseline (zéro stat par fichier).
- **`detect-planning-debt.sh`** (PLN-01) : find non bornés sans exclusion `node_modules`/`.venv`/
  `vendor` + un stat PAR fichier → minutes de gel au SessionStart sur repo dev réel, hook tué au
  timeout. Désormais : prunes systématiques, volume en early-exit (`head -n MIN | wc -l`),
  activité en O(1) (`-mtime -N | head -1`), plus aucun stat par fichier.
- **`planning-task-context.sh`** (PLN-02/03) : glob récursif `**` du repo entier à CHAQUE prompt
  (0,7-3,8s mesurés) → globs bornés dédupliqués ; matching par sous-chaîne nue (« les
  inFORMATIONs » injectait le compartiment `formation`, « pARTage » injectait `art` — le mauvais
  STATE présenté comme celui de la tâche) → frontières de mot, scoring de tous les candidats,
  tie-break déterministe, ambiguïté parfaite → silence.
- **`planning-context.sh`** (PLN-04/05) : `--path`/`--max-lines` sans valeur → boucle infinie
  jusqu'au timeout → `"${2:?}"` ; INDEX > 80 lignes tronqué sans le signaler → mention explicite.
- **`check-planning-state.sh`** (PLN-06) : date non paddée (`2026-7-5`) → extraction robuste +
  normalisation (piège octal évité), message d'erreur ne citant que la valeur.

### Ajouté
- **`planning-session-snapshot.sh`** (**SessionStart, toutes sources**, first-wins au compact) :
  baseline de session (epoch + HEAD de départ + porcelain hashé, cap 200 hash / 2000 entrées)
  dans `$TMPDIR/vibeflow-planning-guard/` (rotation 7 jours). Fondation de l'attribution du guard.
- `hooks/hooks.json` : nouveau groupe SessionStart sans matcher pour la baseline (merge vérifié
  idempotent).

### Tests
- `test-planning-hooks.sh` : section guard réécrite (9 → 21 scénarios, 33 checks au total) —
  couvre les 2 faux positifs v1, l'attribution par hash, le one-shot `.blocked`, le first-wins
  compact, la baseline périmée, `.planning` gitignoré (mtime), le fail-open sans baseline.
  Variable `BASH_BIN` pour exécution forcée /bin/bash 3.2.
- `test-planning-context-hardening.sh` créé (20 checks PLN-02/03/04/05) ; `test-planning-core.sh`
  6 → 14 ; `test-detect-planning-debt.sh` 7 → 10 (garde anti-gel 3000 fichiers).

## [v2.2.0] — 2026-07-16 (ADR-050 — hooks planning : lecture au start + maj bloquante au end)

### Ajouté
- `planning-context.sh` (**SessionStart**) : injecte un **digest index-first** — lab à compartiments →
  `INDEX.md` (+ directive « lis le STATE du compartiment ciblé ») ; lab mono → `STATE.md` borné. Comble
  le gap : `check-planning-state.sh` ne faisait que signaler la fraîcheur, sans injecter de contexte.
- `planning-task-context.sh` (**UserPromptSubmit**) : une fois la tâche connue, injecte le `STATE.md`
  **du compartiment que la tâche vise** (borné) — jamais tous les compartiments (anti-saturation).
- `guard-planning-updated.sh` (**Stop, BLOQUANT**) : bloque la fin de session (exit 2) si des livrables
  ont changé sans mise à jour du `.planning/`. Garde-fous anti-piège : anti-boucle (`stop_hook_active`),
  échappatoire `.planning/.session-noop` (one-shot), toggle `VF_PLANNING_STOP=block|warn|off`, fail-open
  hors git / sans `.planning/`. Premier hook `Stop` du plugin.
- `hooks/hooks.json` : SessionStart enrichi (+ `detect-planning-debt.sh`, 8e signal désormais surfacé
  automatiquement) + UserPromptSubmit + Stop.

### Tests
- `test-planning-hooks.sh` (20 : Stop 9 scénarios + injection contexte 8 + task-context 3).

## [v2.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `hooks/hooks.json` — SessionStart → `check-planning-state.sh || true` posé AUTOMATIQUEMENT
  à l'install (advisory, jamais bloquant). Fin du « wiring documenté, jamais auto-injecté ».

### Modifié
- Canon DECISIONS/DEC-XXX dans les références (bridge-memory, GUIDE, compartments, templates).

## v2.0.0 — 2026-06-23

Topologie à **compartiments** : un lab multi-projets a un *steering* au niveau lab + un plan
**conditionnel et typé** par compartiment. Corrige l'angle mort « tout linéaire » de la v1 et la
question « faut-il un planning partout ? ». Fondé sur RES-127 (GSD, Kiro, Cline Memory Bank, SAFe) +
terrain BusinessFlow (OBS-014). **Rétrocompatible** : un lab mono-objectif garde son `.planning/` unique.

### Ajouté
- **`references/compartments.md`** — doctrine : steering lab + `INDEX.md` (jamais de ROADMAP global) ;
  plan conditionnel au **seuil d'autonomie** (machine-vérifiable) ; typage **`deliverable`** (roadmap+
  phases) vs **`continuous`** (board+cadence, pas de roadmap) ; cas hybride ; loi de non-cannibalisation
  (« faux demain → plan ; survit à la livraison → mémoire ») ; migration sans perte.
- **`templates/INDEX.template.md`** (tableau de bord lab) + **`templates/BOARD.template.md`** (compartiment
  `continuous`).
- **`scripts/detect-planning-debt.sh`** (+ tests 7/7 PASS) — 8e signal de dette : compartiment **actif +
  sans plan + au-dessus du seuil**. Advisory, jamais bloquant. Câblé dans `vibeflow-validator` (Phase 3).
- `config.template.json` v2.0 : champs `scope`, `type`, `compartments.autonomy_threshold`.

### Modifié
- `SKILL.md` : section « lab mono-objectif vs à compartiments » + étape 3bis + références.
- `PROFILES.md` : axe orthogonal topologie (INDEX/BOARD). `bridge-memory.md` : ponts au niveau compartiment.

## v1.1.0 — 2026-06-11

Phases 3-5 (moteur léger universel + auto-infusion + preuve d'universalité). **Sans toucher
`dev-orchestrator`.**

### Ajouté
- **Moteur léger (Phase 3)** : `scripts/check-planning-state.sh` — garde-fou de fraîcheur de la
  clé de voûte `STATE.md` (advisory, portable macOS/Linux, exit codes pour hook). Détecte
  `.planning/` absent (lab non amorcé), STATE absent, STATE périmé. + `scripts/tests/` (6/6 PASS).
- **Auto-infusion + détection métier (Phase 4)** : `references/domain-detection.md` — heuristiques
  de *jugement* (jamais déterministes) pour inférer le métier → profil + extension, et amorcer un
  lab fraîchement installé **sans rien imposer** (le garde-fou surface l'absence de socle, le skill
  pose un socle adapté). Wiring d'un hook SessionStart opt-in documenté (jamais auto-injecté).
- **Preuve d'universalité (Phase 5)** : `references/example-lab-contenu.md` — exemple complet d'un
  socle `.planning/` adapté à un lab NON-dev (éditorial, profil standard, extension `editorial/`).
- Skill `vf-planning` câblé sur ces 3 références + le script.

### Notes
- Type module : `skill + references` → `skill + references + scripts`.
- La maintenance reste **assistée** (advisory), pas automatique forcée — cohérent « structure d'abord ».

## v1.0.0 — 2026-06-10

Release initiale. Socle de planning & gestion documentaire **universel** extrait de la logique
GSD `.planning/`, débarrassé du couplage dev et rendu adaptatif par métier.

### Ajouté
- Skill `vf-planning` — scaffoldeur/maintaineur thin, prose agent-driven : lit le métier du lab,
  choisit un profil de rigueur, instancie le tronc commun en l'adaptant, établit le pont mémoire.
- Tronc commun = 7 artefacts (`PROJECT`, `STATE` ★, `ROADMAP`, `REQUIREMENTS`, `MILESTONES` +
  `milestones/`, `phases/NN/PLAN`+`SUMMARY`, `config.json`).
- 3 profils de rigueur (léger / standard / complet) + mapping métier → profil (`references/PROFILES.md`).
- Doctrine anti-biais (`references/GUIDE.md`) : tronc invariant, extension de domaine adaptée au
  métier (jamais imposée), STATE comme clé de voûte.
- Pont `.planning/` ↔ `.claude/memory/` sans duplication (`references/bridge-memory.md`).
- 8 gabarits universels neutres-métier (`references/templates/`).

### Notes
- `type: skill + references`. Aucune dépendance (`requires: []`) — fonctionne seul.
- v1 = **structure + discipline manuelle**. L'automatisation de la maintenance de STATE (hook
  SessionEnd, mise à jour auto) est un incrément ultérieur (« moteur »).
- Origine : ADR-038 (candidate). Complémentaire du module dev `dev-orchestrator` (qui produit un
  `.planning/` dev via GSD) — `planning-core` est l'étage universel en dessous.
