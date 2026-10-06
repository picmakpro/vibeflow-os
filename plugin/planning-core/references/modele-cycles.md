# Le modèle par cycles d'un lab métier

Cette référence décrit le second modèle de données de `planning-core`, **additif** au socle v2
existant (profils léger/standard/complet, `references/templates/*.template.*`) qui reste en place
et inchangé — le retrait de l'existant n'a pas lieu dans cette phase (P44-D-01e). Elle transcrit,
sans rien y ajouter ni retrancher, les choix que `44-CONTEXT.md` délègue au planificateur
(décisions P44-D-01 à P44-D-18, Willy, AskUserQuestion session principale, 2026-09-27) et sert de
**contrat** : le moteur (`recalc-planning.sh`, plans 44-01, 44-03, 44-04) l'implémente à
l'identique, et les Phases 45 à 50 le consomment. Source normative :
`docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` (ci-après « la spec »),
notamment §3 et §3.1.

## Frontière avec le moteur de développement

Le moteur par cycles vit dans `plugin/planning-core/` et remplace le socle **métier** du module —
il ne touche **pas** le moteur de développement (P44-D-01). Aucun fichier de `~/.claude/gsd-core/`,
`.claude/gsd-core/` ni de `plugin/dev-orchestrator/` n'est concerné par cette phase (P44-D-01a) :
un projet de code garde GSD comme **unique** moteur de planning, `planning-core` tient l'altitude
au-dessus et la couche à côté (voir `gsd-handoff.md` — Iron Law : « un projet de code a un seul
moteur de planning : GSD »).

Ce qui est commun entre les deux — la « même base » — se limite au **principe** d'état dérivé du
disque, jamais déclaré (spec §1.1), et au **vocabulaire** des états (§4, table des gestes :
cadrer, planifier, exécuter, vérifier, fermer) ; jamais au code : **aucune** dépendance de code
vers `gsd-core` (ni `require`, ni appel à `gsd-tools`, ni lecture de ses fichiers) (P44-D-01d).

L'altitude lab que `planning-core` sert aussi aux labs dev — `INDEX.md` du lab, typage des
compartiments, `workstream-policy.sh`, `detect-planning-debt.sh`, hooks existants — reste
**inchangée à l'identique**, prouvée par ses suites existantes
(`plugin/planning-core/scripts/tests/*.sh`) vertes sans modification de ces suites (P44-D-01b).
Un lab dev n'est **jamais** réécrit par ce moteur : garanti par l'adhésion explicite (§ Adhésion
ci-dessous) et par la détection d'un planning GSD, qui refuse l'écriture (P44-D-01c).

## Adhésion

Le recalcul n'**écrit** que si `.planning/config.json` déclare `"planning_version": "cycles-v1"` —
égalité **stricte** d'une chaîne (P44-D-02). Cette valeur n'est **jamais numérique** pour ne
pouvoir être confondue avec un incrément des schémas `1.0` et `2.0` déjà présents dans le corpus
(spec §11.3) : `cycles-v1` est un **troisième schéma documenté**, pas un remplacement des deux
premiers, et la réutilisation de la clé `planning_version` (plutôt qu'une seconde clé) est
elle-même un choix de la spec (D-10 tenue).

Sans cette déclaration exacte, le recalcul **refuse d'écrire** : code de sortie **2**, rien créé,
rien modifié, rien supprimé — cache compris.

**Mode lecture seule** (`--read-only`) : la dérivation est calculée et écrite sur la sortie
standard **uniquement**, quel que soit l'état d'adhésion du planning lu ; aucun fichier n'est
écrit, jamais de sous-processus lancé (P44-D-02a). C'est ce mode qui sert aux passages sur labs
réels (D-06a du contexte).

Un **planning GSD détecté** (ou une détection non concluante) est refusé en mode écriture, **même
s'il déclare `cycles-v1`** : code de sortie **3** (P44-D-02a).

**Codes du détecteur (`detect-gsd-engine.sh`) et leur traitement par `detection_gsd()`** — le
détecteur rend 0/1/2/3/64, le recalcul les traduit en un verdict `gsd`/`non-gsd`/`migration`/`non-concluante` :

| Code détecteur | Sens | Verdict `detection_gsd()` | Écriture |
|---|---|---|---|
| 0 | moteur GSD actif | `gsd` | refusée |
| 1 | improbable (voir ci-dessous) — fail-closed, jamais une réimplémentation de ses priorités | `non-concluante` | **refusée** |
| **2** | **signalement de MIGRATION** (socle planning-core + signal de code, ex. `package.json`) | `migration` | **autorisée sous adhésion `cycles-v1` seulement** (P45-D-02, Phase 45, Willy, AskUserQuestion session principale, 2026-09-29) ; sans adhésion : sortie 2 inchangée, rien écrit. Verdict propre, jamais assimilé au code 3 (audit B, lot 2 L1, décision du head sous délégation technique de Willy, session principale, 2026-09-28) |
| 3 | aucun moteur en place, terrain libre | `non-gsd` | autorisée |
| tout autre code (ex. 64, détecteur défaillant) | non concluant | `non-concluante` | refusée |

**Levée du code 2 sous adhésion (Phase 45, GATE-14, P45-D-02).** L'adhésion est testée **avant** la
détection : sans `cycles-v1`, un lab au socle v2 qui contient du code reste refusé en code **2**,
exactement comme en Phase 44 (message P44-D-02, rien écrit, cache compris). Avec l'adhésion, seule la
combinaison « détecteur à 2 » écrit ; le détecteur à 0 (moteur GSD actif) reste un refus en code 3,
et la garde de lecture, le code 1 et tout autre verdict non concluant aussi. `detect-gsd-engine.sh` et
`workstream-policy.sh` ne changent pas : la levée vit dans `recalc-planning.sh` seul (P45-D-02b).

**Archivage du socle v2 à la première écriture sous migration (F10, P45-D-02, Willy,
AskUserQuestion session principale, 2026-09-30).** La première écriture remplace le `STATE.md` et
l'`INDEX.md` du socle v2, rédigés à la main (ADR-031 : pas de perte de contenu sans validation
humaine). Avant de les remplacer, le recalcul les copie **octet pour octet** sous
`.planning/_archive/socle-v2/` (emplacement annexe, jamais lu par le recalcul). Une archive existante
n'est **jamais réécrite** : si elle porte déjà tous les fichiers à archiver aux mêmes octets, il n'y a
rien à faire ; sinon une nouvelle archive est posée sous un nom libre (`socle-v2`, puis `socle-v2.2`,
`socle-v2.3`…), en tout ou rien (dossier provisoire puis renommage d'un bloc : en cas d'échec le recalcul
ne remplace ni le `STATE.md` ni l'`INDEX.md`, sortie 1) — correction ciblée du lot B (décisions du manager
vf-dev-manager, 2026-10-01). Si `_archive` ou une archive nommée existe et n'est pas un dossier réel
(lien symbolique compris), le recalcul sort en code **1** sans rien écrire. Un `STATE.md` ou un `INDEX.md`
qui porte la marque de génération du recalcul se reproduit : il n'est pas archivé (limite déclarée, voir
(v) dans la section « Hook central et gates d'écriture (Phase 45) »). Le `STATE.md` généré ne porte plus
`planning_version` : le détecteur ne rend plus 2 au passage suivant, l'archivage ne se produit qu'une fois.

**Source UNIQUE de vérité — le VRAI détecteur, jamais une copie (correction de CLASSE, lot 4).**
Le code 2 a **longtemps** été traité comme le code 3 (même verdict `non-gsd`), laissant écrire sur
un socle planning-core que le détecteur signalait pourtant lui-même « migration à examiner » —
corrigé en lot 2. Le repli du code 1 (chaîne GSD absente) souffrait du même trou par un autre
chemin : la priorité 1 du détecteur (`detect-gsd-engine.sh`) sort **avant** d'avoir pu évaluer sa
priorité 3, donc un environnement qui neutralise `GSD_HOME` (forcé vers un chemin inexistant, ou
simplement hérité) contournait le refus « migration à examiner » — le lot 3 a tenté de fermer ce
trou en réimplémentant en Python pur les priorités 2/2bis/3 du détecteur (`_porte_marqueur_gsd`,
`_porte_marqueur_partition`, `_porte_planning_version`, `_a_signal_de_code`). Cette copie a divergé
mesurément de l'original sur trois cas (revue + audit, ca185e4) : un `package.json` en lien
symbolique (bash `[ -f ]` le suit, `os.lstat` de la copie non), un `*.xcodeproj` en lien symbolique
(même écart avec `[ -d ]`), et un `STATE.md` dont les octets UTF-8 sont invalides **après** le
frontmatter (le décodage UTF-8 strict de la copie échouait sur le fichier entier, awk — qui ne lit
que le frontmatter — trouvait le marqueur sans encombre). **Le lot 4 supprime cette réimplémentation
et appelle le VRAI détecteur**, dans un environnement MAÎTRISÉ où `GSD_HOME` est fixé explicitement
au dossier du détecteur lui-même — un dossier qui EXISTE TOUJOURS quand ce script tourne — plutôt
que laissé à la cascade par défaut (qui dépend de `GSD_HOME`/`CLAUDE_CONFIG_DIR`/`HOME` hérités).
Sous cet environnement, la priorité 1 du détecteur (`[ ! -d "$GSD_HOME" ]`) ne peut structurellement
plus matcher : le code 1 devient improbable, et s'il survient quand même (course, détecteur
remplacé après le contrôle de régularité), le moteur fait **fail-closed** — refus nommé, jamais une
retombée en écriture.

**Correction de classe F1/F44-07 (lot 5)** : au lot 4, l'environnement « maîtrisé » ci-dessus était
en réalité `dict(os.environ)` — une COPIE INTÉGRALE de l'environnement hérité, avec la seule
SURCHARGE de `GSD_HOME`. Ça neutralisait bien la priorité 1 du détecteur, mais laissait les
priorités 2/2bis/3 — qui appellent `awk`/`mktemp`/`wc`/`cat`/`basename` via le `PATH` — entièrement
soumises au `PATH` hérité de l'appelant : un `awk` factice en tête de PATH (ou `BASH_ENV`, ou une
fonction exportée `BASH_FUNC_awk%%`, ou `ENV`) faisait mentir `has_frontmatter_key` sur la présence
du marqueur `gsd_state_version`, sans jamais toucher au détecteur lui-même. Mesuré : sur un lab GSD
réel (`STATE.md` portant `gsd_state_version`), un simple `awk` factice en tête de PATH suffisait à
faire écrire (exit 0) le moteur et à **effacer le marqueur GSD**. L'environnement du sous-processus
détecteur est désormais construit DE ZÉRO (liste blanche) : un `PATH` fixe de dossiers système
(`/usr/bin:/bin:/usr/sbin:/sbin`) et `GSD_HOME` seul — aucune autre variable héritée (ni
`BASH_ENV`, ni `ENV`, ni une fonction exportée, ni `SHELLOPTS`/`BASHOPTS`/`CDPATH`/`TMPDIR`/`HOME`/
`GSD_WORKSTREAM`). De même, `bash` n'est plus résolu par `shutil.which("bash")` sur ce même `PATH`
hérité (un `bash` factice en tête de PATH aurait rendu le sous-processus entier contrôlé par
l'attaquant) mais par une liste FIXE de deux chemins absolus (`/bin/bash`, puis `/usr/bin/bash`),
chacun validé par `lstat` (fichier régulier direct, ou lien symbolique dont la cible résolue est un
fichier régulier appartenant à root) — aucun candidat valide : refus fail-closed nommé, jamais un
repli sur le `PATH`. Propriété résultante, désormais réellement vraie et prouvée (`R-MATRICE-ENV`,
`MUT-ENV-OS-ENVIRON`, `MUT-BASH-VIA-PATH`) : le verdict d'écriture est **indépendant** du `PATH`
hérité, de `BASH_ENV`/`ENV`/des fonctions exportées, de `GSD_HOME`/`CLAUDE_CONFIG_DIR`/`HOME`
hérités et du cwd, et correspond **toujours** à celui du vrai détecteur lancé dans cet environnement
fixe (P44-D-01b, P44-D-01d — aucun sourcing, aucune dépendance de code vers
`detect-gsd-engine.sh` : uniquement un sous-processus, sur son code de sortie seul). Ce que ce
verdict NE garantit PAS : le wrapper `recalc-planning.sh` lui-même (son propre `bash`, son propre
`python3`) reste résolu par l'appelant — il n'entre pas dans le domaine maîtrisé, qui ne couvre que
le sous-processus détecteur.

Détecteur absent (message distinct depuis lot 5 — `détecteur absent`, jamais confondu avec
`détecteur non régulier`), en lien symbolique, non régulier, illisible, ou dont le lancement échoue
(aucun candidat bash valide, exception, code hors de {0, 2, 3}) : refus fail-closed nommé, zéro
fichier écrit ou modifié — jamais une retombée en écriture. Un code 3 avec une sortie stderr
inattendue N'EST PAS traité comme non concluant (point envisagé et non retenu, lot 5) : mesuré, un
`.planning/workstreams/` présent mais VIDE fait légitimement écrire deux lignes sur stderr
(`vf_ws_enumerate`, priorité 2bis) tout en rendant le code 3 racine correct — gater dessus aurait
refusé l'écriture sur ce cas nominal. Ce qu'un lab métier qui contient DU CODE fait de ce refus (le
détecteur rend 2, le moteur refuse l'écriture) reste une question ouverte, à cadrer en Phase 45
(voir ROADMAP.md § Phase 45).

**Conséquence non documentée de `CANDIDATS_BASH` (WR-03, revue, lot 6)** : les deux candidats fixes
(`/bin/bash`, `/usr/bin/bash`) sont un fail-closed **total**, pas seulement local au sous-processus
détecteur. Sur un système sans AUCUN des deux à ces emplacements exacts (une image Alpine sans
`bash` installé — `sh` seul y est `ash`/`busybox` — une machine NixOS où les binaires système
vivent sous `/nix/store/...` et non `/bin`/`/usr/bin`, ou une image distroless), `_resoudre_bash()`
ne trouve jamais de candidat valide : `recalc-planning.sh` ne pourra alors **plus jamais écrire**
sur ce système, quel que soit l'état réel du planning — aucun repli sur un autre interpréteur, aucun
`shutil.which("bash")` (motif déjà justifié ci-dessus). Comportement VOULU (P44-D-01c/d, F1/F44-07)
et non modifié par cette note : elle documente une conséquence déjà en place, pour qu'un futur
lecteur qui déboguerait un « toujours refus, jamais d'écriture » sur un tel système trouve la
réponse ici plutôt qu'en relisant le code.

**Garde de lecture du détecteur (P44-D-02a, lot 7, correction de CLASSE)** — principe (décision du
head sous délégation technique de Willy, session principale, 2026-09-28) : **le moteur n'écrit que
s'il a pu LIRE, pour de vrai, tout ce que le détecteur devait lire**. Pas une liste de cas
particuliers — deux vérifications structurelles, appliquées AVANT tout appel réel au détecteur,
côté appelant, sans jamais relire un `STATE.md` pour son CONTENU ni chercher un marqueur (P44-D-01b
interdit toute modification de `detect-gsd-engine.sh` ou `workstream-policy.sh` ; ils restent
APPELABLES, jamais réimplémentés) :

1. **Fidélité PAR EXÉCUTION** : `vf_ws_enumerate` (workstream-policy.sh) est RELANCÉE, pour de
   vrai, dans le même bash et le même environnement maîtrisé que ceux qui serviront à l'appel réel
   du détecteur — jamais une réimplémentation Python de sa boucle. Son résultat est comparé à
   l'ensemble des compartiments RÉELS du disque, dérivé indépendamment (`os.scandir`, jamais un
   glob shell). Tout écart (ligne vide, ligne dupliquée, compartiment manquant) est un refus nommé.
2. **Lisibilité RÉELLE** : chaque compartiment retenu par cette exécution, le `STATE.md` racine
   s'il existe, et le `STATE.md` de chaque compartiment s'il existe, doivent être OUVRABLES pour de
   vrai (ouverture réelle, jamais `os.access`, qui peut mentir sous ACL POSIX ou montage réseau).

Constat qui motive ce lot (audit du 2026-09-28, mesuré par exécution, HEAD `32b5d59`) : la garde du
lot 6 (fidélité STRUCTURELLE — noms à saut de ligne, noms cachés, chemin de planning à risque) ne
couvrait pas la classe suivante, plus large. `vf_ws_enumerate` pose `found=1` **inconditionnellement
après chaque `printf`**, même quand `cd "$entry" && pwd` a ÉCHOUÉ (compartiment sans bit `x` —
mode `000`/`600`/`400`) : `cd` échoue, la substitution de commande capture une chaîne vide,
`printf` imprime une ligne vide, et `found=1` est posé quand même (`workstream-policy.sh:305-306`).
`detect-gsd-engine.sh` saute cette ligne vide en silence, la priorité 2bis retombe sur la priorité
3/4 et rend le code 3 « terrain libre » sans aucun diagnostic — exactement le code que
`detection_gsd` traduit en autorisation d'écrire. Mesuré : le moteur écrivait (exit 0) sur un
compartiment réellement tenu par GSD ; quand le marqueur porté est au `STATE.md` **racine**
lui-même rendu illisible (mode `000`), le moteur allait jusqu'à **écraser** ce `STATE.md` — le
marqueur `gsd_state_version` disparaissait.

Les classes structurelles du lot 6 (nom à saut de ligne, nom caché, chemin de planning à risque)
sont conservées comme diagnostic nommé, et sont FUSIONNÉES dans la même liste de décision que
l'égalité d'ensembles par exécution (point 1) et la lisibilité réelle (point 2) — n'importe
laquelle des trois, seule, suffit à refuser (correction de prose, lot 8 : la formulation
précédente laissait entendre qu'elles n'étaient que descriptives). L'égalité d'ensembles couvre le
trou ci-dessus SANS connaître son mécanisme exact, et couvrirait de la même façon une future
variante du même trou ailleurs dans `vf_ws_enumerate`. Une entrée en lien symbolique reste une
exclusion DÉCLARÉE du détecteur lui-même (avertissement sur stderr) — non masquante au sens de
cette garde, volontairement pas retenue ici (ne pas sur-refuser un cas déjà connu et accepté du
système).

**Lien cassé = absent, FIFO refusée sans blocage (P44-D-02a, lot 8, correction de CLASSE)** —
décision du head sous délégation technique de Willy, session principale, 2026-09-28. Deux
corrections indépendantes de la garde de lecture du lot 7, mesurées à l'audit du 2026-09-28 :

1. **Lien symbolique CASSÉ (cible absente) = ABSENT, comme pour le détecteur.** Le détecteur lit
   `STATE.md` via `[ -f ]` (`detect-gsd-engine.sh:96,184`) : ce test **suit** le lien et exige un
   fichier RÉGULIER à la cible ; sur une cible absente, `[ -f ]` est faux et **aucune lecture n'est
   tentée**. La garde de lecture du lot 7 confondait ce cas avec une vraie erreur de lecture
   (`os.path.lexists` — vrai même pour un lien cassé — suivi d'une tentative d'ouverture qui
   échouait en `ENOENT`, classée « illisible ») : sur-refus mesuré (le moteur refusait d'écrire sur
   un planning SANS AUCUN marqueur GSD nulle part, uniquement parce qu'un `STATE.md` de
   compartiment était un lien cassé). `os.path.isfile` (mirroir exact de `[ -f ]`) remplace
   désormais `os.path.lexists` pour le `STATE.md` racine ET de compartiment. Le `STATE.md` racine
   en lien cassé reste TOUJOURS refusé, mais PAR AILLEURS — la garde B de `appliquer_ecritures`
   (« emplacement occupé », `lstat` sans jamais suivre le lien, F4) — jamais un double refus, et la
   cible du lien n'est jamais créée.
2. **`STATE.md` en FIFO n'y bloque plus jamais.** `_ouvrable` ouvrait sans `O_NONBLOCK` : une FIFO
   à cet emplacement bloquait le processus INDÉFINIMENT tant qu'aucun autre processus n'en tenait
   l'extrémité écriture. `_ouvrable` ouvre désormais en `O_NONBLOCK` (sans effet sur un fichier
   régulier, dont la lecture nominale ailleurs — `_lire_frontmatter_fichier` — n'est pas affectée)
   et contrôle le type par `fstat` après ouverture : un type non régulier est un refus nommé,
   jamais un faux `True`. Note : `os.path.isfile` (point 1) suffit déjà, seul, à éviter d'appeler
   `_ouvrable` sur une FIFO depuis les deux sites d'appel actuels (`[ -f ]` est aussi faux pour une
   FIFO — traitée comme absente) ; le durcissement `O_NONBLOCK` reste une défense en profondeur de
   `_ouvrable` elle-même, exercée directement par la suite de tests, pour tout appel futur qui ne
   passerait pas par ce même filtre.

### Résidus acceptés (lot 8)

- **TOCTOU entre la garde et le détecteur** : deux lectures indépendantes du disque (la garde de
  lecture, puis le sous-processus détecteur relancé juste après) — mesuré : une écriture indue sur
  15 essais avec un `mv` concurrent LOCAL pendant la fenêtre entre les deux lectures
  (gsd-security-auditor, 2026-09-28). Exige un processus concurrent disposant du droit d'écriture
  sur l'arbre — aucun contenu versionné (un fichier du modèle, un nom de compartiment) ne peut
  produire cette fenêtre à lui seul. Résolution durable envisagée : une seule lecture partagée entre
  la garde et le détecteur, ce qui suppose que le détecteur EXPOSE son énumération plutôt que de la
  refaire en interne (P44-D-01b — hors périmètre de ce lot, transmis au BACKLOG).
- **Volume** : `vf_ws_enumerate` mesurée à environ 98 secondes à 3000 compartiments — au-delà du
  délai de 30 s (`timeout=30` de `_executer_vf_ws_enumerate`), l'exécution échoue et la garde refuse
  fail-closed (`enumeration-execution-en-echec`), jamais une écriture indue. Un lab à ce volume de
  compartiments ne peut donc plus jamais écrire par cette voie tant que le volume n'a pas baissé (ou
  que le délai n'a pas été révisé) — comportement voulu (fail-closed), documenté ici pour qu'un
  futur lecteur qui déboguerait un refus systématique sur un très gros lab partitionné trouve la
  réponse ici plutôt qu'en relisant le code.

**Limite assumée** : cette garde ferme la classe pour tout ce qui **voyage par git** (le disque, au
moment de l'appel). Un résidu strictement local à un poste — un état de permissions qui ne
survivrait pas à un `git clone` frais, ou une divergence propre à un montage réseau spécifique non
reproduite dans les tests — n'est pas dans son périmètre de preuve ; s'il en subsiste un après ce
lot, il est nommé précisément dans le rapport de mission plutôt que supposé couvert.

Le trou source (`vf_ws_enumerate` pose `found=1` même quand `cd` échoue) reste hors de portée de ce
lot (P44-D-01b) et est transmis au BACKLOG pour Samuel (propriétaire de `workstream-policy.sh`,
Phase 41.1) : la correction à la source évite qu'une future consommatrice de cette primitive
(`check-planning-state.sh`, un compteur, pas un gate d'écriture) hérite du même trou sans une garde
équivalente.

## Arborescence

```
<lab>/.planning/
  PROJECT.md · REQUIREMENTS.md · config.json
  INDEX.md              (généré)
  STATE.md              (généré)
  cloture.log           (généré, ajout seul)
  .recalc-cache.json    (généré)
  derogations-gates.log (journal de dérogation des gates, ajout seul — Phase 45, P45-D-13)
  surveillance.log      (journal de D1, ajout seul, jamais surveillé — Phase 46, P46-D-07a)
  _archive/socle-v2/    (STATE.md et INDEX.md du socle v2, archivés à la migration — annexe)
  cycles/01-<sujet>/
    CYCLE.md
    phases/01-<nom>/
      CADRAGE.md
      PLAN.md            (ou plans/01-<nom>/{PLAN.md, CLOTURE.md, VERDICT.md, SUMMARY.md})
      CLOTURE.md
      VERDICT.md
      SUMMARY.md
      DEROGATION.md      (optionnel — phase ou plan)
  baux/<phase>/gen-<n>/  (Phase 47)
  missions/
  juges/<juge>/          (canary de juge, C-16 — Phase 46, P46-D-06a)
    SORTIE-PIEGEE.md     (la sortie piégée du juge)
    VERDICT.md           (le verdict de canary, posé par poser-verdict.sh)
```

Une phase porte `CADRAGE.md`, et **soit** un plan direct (`PLAN.md`, `CLOTURE.md`, `VERDICT.md`,
`SUMMARY.md` directement sous la phase), **soit** `plans/<NN-nom>/{PLAN.md, CLOTURE.md, VERDICT.md,
SUMMARY.md}` ; phase et plan peuvent l'un et l'autre porter `DEROGATION.md`.

**Nom d'unité** (cycle, phase, plan) : `^[0-9]{2,}-[\w.-]+$` — lettres accentuées admises, ni
espace ni caractère de contrôle.

**Le livrable vit à sa place métier**, hors de `.planning/`, déclaré par `ecrit:` (voir § Fichiers
du modèle, `PLAN.md`, et spec §3).

**Emplacements du modèle** à la racine de `.planning/` : dossiers `cycles`, `baux`, `missions`, `juges` (le canary de juge, Phase 46 :
P46-D-06a ; jamais « Hors modèle », jamais dérivé comme une unité de cycle : seul `cycles/` porte des unités) ;
fichiers `PROJECT.md`, `REQUIREMENTS.md`, `config.json`, `INDEX.md`, `STATE.md`, `cloture.log`,
`.recalc-cache.json`, `derogations-gates.log` (journal de dérogation des gates, Phase 45 : F7a, P45-D-13 —
Willy, AskUserQuestion session principale, 2026-09-30 ; jamais « Hors modèle »), `surveillance.log` (journal de D1,
Phase 46, P46-D-07a ; jamais « Hors modèle »). `baux/` et `missions/`
ne sont pas parcourus par le recalcul en Phase 44.

## Emplacements annexes et hors modèle

**Liste fermée** des emplacements annexes, ignorés par le recalcul, **jamais lus** (P44-D-04) :

| Emplacement annexe | Nature |
|---|---|
| `_bancs` | dossier |
| `recherches` | dossier |
| `intel` | dossier |
| `sketches` | dossier |
| `_archive` | dossier |
| `registres` | dossier |

**Tout le reste** — à la racine de `.planning/`, et dans l'arbre `cycles/` toute entrée qui n'est
ni un emplacement du modèle, ni un nom d'unité valide, ni un emplacement du modèle du bon type
(ex. un `PLAN.md` qui serait en réalité un dossier), tout lien symbolique — est signalé **« hors
modèle »** dans `INDEX.md` : **jamais refusé, jamais déplacé, jamais suivi**, et ne change **aucun**
état dérivé.

La liste des six emplacements annexes vit dans le **code du moteur et dans cette référence**, pas
dans `config.json` — option explicitement écartée par Willy (P44-D-04).

**Rendu dans `INDEX.md`** (44-04) : `## Hors modèle` puis une ligne `` - `<chemin échappé>`
(<type>) `` par entrée, triée, `<type>` valant `fichier`, `dossier`, `lien` ou `autre`. Le chemin
est échappé par `echapper_nom` : tout caractère de catégorie Unicode C* (contrôle, format,
private-use, substitut) devient `\uXXXX` (quatre chiffres hexadécimaux en minuscules, complétés de
zéros à gauche) pour un point de code du plan de base (<= U+FFFF), ou `\UXXXXXXXX` (huit chiffres
hexadécimaux en minuscules, convention littérale Python) au-delà — un private-use de plan
supplémentaire (ex. U+100000) ne serait sinon ni représentable ni tronqué en silence. L'accent
grave devient `` \` ``. Aucune autre transformation : un nom d'unité invalide reste lisible tel
quel, seuls les caractères qui casseraient le format une-entrée-par-ligne ou le délimiteur
`` ` `` sont touchés.

## Fichiers du modèle

Un gabarit correspond à chaque fichier ci-dessous, sous
`plugin/planning-core/references/templates/cycles/` (voir § Gabarits).

### `CYCLE.md`

Frontmatter : `titre`, `rend` (ce que le cycle rend), `ferme_quand` (liste des conditions
observables qui ferment le cycle). **Seule sa présence** compte pour le recalcul — l'état d'un
cycle est l'**agrégation** de ses phases (§ Agrégation), jamais une lecture de son contenu.

### `CADRAGE.md`

Frontmatter : `titre`, `inconnues` = **liste de mappings** {`id`, `question`, `structurante`
(`oui`|`non`), `statut` (chaîne libre, vide ou non), `par`, `le`, `ou`}.

Lecture **littérale** de la spec (§3.1, l.213) : « en cadrage » = au moins une ligne structurante
**sans** statut ; **toute** valeur non vide ferme la ligne, quelle qu'elle soit — le recalcul ne
juge **jamais** la valeur du `statut`, seulement sa **présence**. Il n'existe **pas** de liste
fermée de statuts, et **jamais** d'`indéterminé` pour un statut inconnu : un statut libre est
exactement ce que le §3.1 prévoit. `ARBITRÉ` (qui porte `par`, `le`, `ou`, pour le pont mémoire,
spec §7.5) reste l'**exemple recommandé**, sans être la seule valeur qui ferme une ligne.

Registre **clos** ⇔ aucune ligne `structurante: oui` à `statut` vide ; `inconnues: []` est **clos**
(spec D-06 tenue : on vérifie que le registre est clos, jamais qu'il est long). Le registre est une
**liste en frontmatter**, jamais un tableau Markdown (44-RESEARCH.md A2).

### `PLAN.md`

Frontmatter : `titre`, `ecrit` (scalaire ou liste). Une entrée `ecrit:` valide est un **chemin
concret relatif à la racine du lab**, non vide, sans `/` ni `~` initial, sans segment `..`, sans
caractère de contrôle ni `\`, sans métacaractère `*?[]{}<>`. Le champ s'appelle `ecrit:` et **non**
`scope:` (spec D-10 — `scope` est déjà pris ailleurs dans le corpus).

`PLAN.md` n'est **jamais** modifié pour marquer une clôture : son hash reste **stable**, ce que
vérifient les verdicts hachés (P44-D-03, Phase 46 : champ `hash` de `VERDICT.md`, règle E).

**Un livrable déclaré est « absent ou vide »** (R4, P46-D-12). Le recalcul ne se contente plus de
constater qu'un chemin existe : il appelle le prédicat unique « livrable présent » d'un `PLAN.md` entier,
`livrables_presents` (voir § `VERDICT.md`), le même que G3 et que la commande de pose, sur les entrées
lues par la même chaîne `entrees_du_plan`. Le prédicat est **borné PAR `PLAN.md`** : un **budget commun**
à toutes ses entrées (2000 entrées, 128 Mio) ; dès qu'une borne est franchie, cette entrée et toutes les
suivantes valent `borne`, jamais `present` — le coût d'un `PLAN.md` ne croît pas avec le nombre d'entrées
qui se recouvrent (`a`, `a/a`, … : une seule traversée de l'arbre, puis la borne). Avant le prédicat, une
entrée qui est ou contient le dossier de l'unité rend `ecrit-contient-unite:<entrée>` (§ `VERDICT.md`,
point fixe). Chaque entrée `ecrit:` est parcourue composant par
composant par `lstat`, **jamais en suivant un lien** : un lien, **terminal ou intermédiaire** (par
exemple `cycles` lui-même remplacé par un lien), rend le livrable **absent** (`livrable-absent:<entrée>`).
Cette règle **remplace** la limite connue de la Phase 44, qui acceptait qu'`os.path.lexists` constate,
par un segment intermédiaire en lien, une existence pointant hors de la racine du lab. Un fichier
régulier de 0 octet, ou un dossier sans aucun fichier régulier non vide, est **vide**
(`livrable-vide:<entrée>`) ; les noms `.DS_Store`, `Thumbs.db` et `desktop.ini` sont **exclus** partout
(motif : ouvrir un dossier livrable dans le Finder ou l'Explorateur ne doit ni le rendre non vide ni
périmer un verdict) ; un parcours qui dépasse la borne (2000 entrées, 128 Mio) rend le livrable **hors
borne** (`livrable-hors-borne:<entrée>`), jamais un livrable accepté sur un parcours partiel. Un livrable
illisible n'est pas établi présent : il rend `livrable-absent:<entrée>` ; un nom d'entrée de dossier non
UTF-8 ou porteur d'un caractère de contrôle (tabulation, saut de ligne, DEL) rend le livrable **illisible**,
jamais une empreinte (le texte canonique serait ambigu). Les raisons nomment l'entrée telle que déclarée
dans `ecrit:`.

**La lecture ne suit aucun lien, à aucun composant.** Le contenu d'un livrable est lu par des ouvertures
**chaînées par descripteur de dossier** (`openat` : chaque composant ouvert relativement au précédent),
`O_NOFOLLOW` à chaque pas et `O_NONBLOCK` (un FIFO substitué à un fichier n'en bloque pas l'ouverture),
puis `fstat` régulier avant la lecture ; un dossier est ouvert une fois pour tous ses fichiers. **Limite
déclarée Windows** : sans descripteur de dossier, l'ouverture se fait par chemin (`O_NOFOLLOW` y protège
le seul dernier composant) ; le repli rend la même empreinte (R-EMP-12). **Fenêtre résiduelle** : le
parcours (`lstat` par chemin) précède la lecture ; un lien ou un fichier spécial substitué entre les deux
n'est jamais lu (la lecture le refuse : `illisible`), mais le parcours a pu compter l'objet d'origine.

### `CLOTURE.md`

Le **marqueur de clôture** du plan : un fichier **à côté** de `PLAN.md`, jamais un champ dedans.
Frontmatter : `cloture_par`, `cloture_le`. Le recalcul ne lit que **sa présence**. `à exécuter` =
`PLAN.md` présent, `CLOTURE.md` absent (spec §3.1).

### `VERDICT.md`

Frontmatter, dans cet ordre : `juge` (auditeur indépendant, **jamais** l'auteur du livrable), `hash`
(sha256 de l'artefact jugé : les octets du `PLAN.md` de l'unité), `hash_livrables` (empreinte composée
des livrables que le `PLAN.md` déclare par `ecrit:`, voir ci-dessous), `tentative` (entier, compteur
anti-boucle), `score` (jugement non bloquant, spec D-02 amendée), `constats` = liste **non vide** de
mappings {`critere`, `resultat` (`passé`|`échec`)}. Le verdict d'un juge de canary (unité
`.planning/juges/<juge>`, ci-dessous) n'a pas `hash_livrables`.

`VERDICT.md` incarne, au sens de la couche d'audit générique (`audit-architecture`), ses cinq
attributs : **dimension** = un constat par critère éliminatoire objectivement vérifiable ;
**auditeur indépendant** = `juge`, jamais l'auteur du livrable ; **rubric** = les `constats` ;
**verdict bloquant** = un `échec` empêche `close` (§ Règles de dérivation, R7) ; **anti-boucle** =
`tentative`, qui compte les allers-retours.

**Deux empreintes** (Phase 46, P46-D-03 : Willy, AskUserQuestion session principale, 2026-10-03,
Q3 = a). Les deux sont calculées par la commande `poser-verdict.sh`, **jamais par l'agent**, sous le
verrou du `PLAN.md`, et relues identiques par le parseur avant l'écriture. Un verdict dont l'une des
deux ne correspond plus est **périmé** : il se refait. Le recalcul le vérifie (règle E, § Règles de
feuille, P46-D-03b) ; G4 le vérifie à l'écriture de `SUMMARY.md` (plan 46-05). En Phase 44, `hash` et
`tentative` étaient lus et restitués sans être vérifiés (P44-D-09) ; ce n'est plus vrai de `hash` ni de
`hash_livrables`.

- `hash` : sha256 des octets du `PLAN.md` de l'unité (A3, conservé).
- `hash_livrables` (P46-D-03a, P46-D-12) : empreinte des entrées `ecrit:` du `PLAN.md`. **Texte
  canonique** : entrées normalisées (barre finale retirée, `.` retiré), dédoublonnées et triées ; pour
  une entrée fichier, une ligne `fichier<TAB><chemin relatif au lab><TAB><sha256>` ; pour une entrée
  dossier, une ligne `dossier<TAB><entrée>` puis une ligne `fichier…` par fichier régulier du
  sous-arbre, triées par chemin relatif ; lignes jointes par `\n` avec un saut final, hachées en UTF-8.
  L'ordre du texte **ne dépend pas de l'ordre d'énumération** du système de fichiers (tri final par chemin
  relatif, prouvé sous trois ordres provoqués, R-EMP-11).
  **Aucun lien n'est suivi** : le chemin est parcouru composant par composant par `lstat`, et un lien,
  terminal ou intermédiaire, rend le livrable **absent** ; un lien ou un fichier spécial **interne** à un
  dossier n'est ni suivi ni haché. Les noms `.DS_Store`, `Thumbs.db` et `desktop.ini` sont ignorés
  partout, dans le prédicat « vide » comme dans l'empreinte (écart de précision assumé par rapport à
  « tous les fichiers réguliers » de P46-D-03a : sans cette exclusion, ouvrir un dossier livrable dans le
  Finder ou l'Explorateur périmerait le verdict). Le parcours est **borné** à 2000 entrées (fichiers et
  sous-dossiers) et 128 Mio (octets annoncés par `lstat` comme octets **lus** : chacun seul déclenche la
  borne), budget commun à toutes les entrées d'un même `PLAN.md` : un dépassement est un **refus
  explicite** qui nomme la borne, jamais une empreinte partielle. La lecture ne suit aucun lien à aucun
  composant (ouvertures chaînées par descripteur de dossier, `O_NOFOLLOW`, `O_NONBLOCK`, § `PLAN.md`).
- **« Vide »** (P46-D-12) : un fichier régulier de 0 octet, ou un dossier sans aucun fichier régulier non
  vide (hors noms exclus).
- **Chaîne unique** (P46-D-12) : `entrees_du_plan` (octets du `PLAN.md` → entrées `ecrit:` → validation,
  refus du point fixe), puis `livrables_presents` (le prédicat « livrable présent » d'un `PLAN.md` entier :
  `absent`, `lien`, `vide`, `present`, plus `borne` et `illisible`, budget commun) et `empreinte_livrables`.
  Cette chaîne existe en **trois copies ast-identiques** (`poser-verdict.sh`, `planning-hook.sh`,
  `recalc-planning.sh`), avec ses entrées — le parseur de frontmatter, `entree_ecrit_valide`,
  `_valeurs_ecrit` et `SANS_SUIVI_DE_LIEN` — prouvées identiques par comparaison d'arbres de syntaxe et
  par les mêmes verdicts de `entrees_du_plan` (suite `test-cloture-empreintes.sh`, R-EMP-04). La commande
  de pose, R4 du recalcul et son cache l'appellent ; G3 et G4 l'appellent (plan 46-05) ; aucun ne la
  réécrit.
- **Point fixe** : une entrée `ecrit:` qui **est ou contient le dossier de l'unité** (l'unité elle-même,
  `.planning` ou un autre ancêtre, comparés par composants, en forme NFC puis sans égard à la casse) est **refusée à la
  pose** (code 64, message distinct « … est ou contient le dossier de l'unité … »), jamais posée : le
  verdict s'écrit dans ce dossier, `hash_livrables` y serait périmé dès la pose. Le refus précède toute
  lecture de `VERDICT.md`, tout temporaire et toute consommation de dérogation. Étiquette :
  décision du manager (vf-dev-manager, mandat de correction ciblée du 2026-10-03, revue anticipée du socle), renversable.
  G3 et G4 (plan 46-05) l'appliquent par `entrees_du_plan` (même chaîne) ; R4 du recalcul rend
  `ecrit-contient-unite:<entrée>` pour une unité à `CLOTURE.md`. Une entrée **dans** l'unité (un fichier
  qu'elle contient) ou une unité voisine reste posable. **Limite déclarée (h)** : une entrée qui nomme un
  fichier que le moteur réécrit lui-même (le journal `.planning/derogations-gates.log`,
  `.planning/INDEX.md`, `STATE.md`, le cache) n'est pas protégée par cette règle.
- **Refus de pose** : la commande refuse (code 64) de poser un verdict quand un livrable déclaré est
  absent, vide ou un lien, quand `ecrit:` est absent, vide ou invalide, quand une entrée est ou contient
  le dossier de l'unité, ou quand une borne est dépassée (R4 précède R5 : un tel verdict serait de toute
  façon `indéterminé`). Les messages ne nomment que l'entrée déclarée ou la borne, jamais un chemin
  absolu ni le texte d'une `OSError` (P46-D-10).

**Plafond de tentatives** (P46-D-05, Q5 = a, même canal) : `PLAFOND_TENTATIVES = 3` est une constante de
la commande, jamais lue dans un fichier du lab ni dans l'environnement. La quatrième tentative est
refusée avec le code **65** et un message distinct (`plafond de 3 tentatives atteint … arbitrage humain
requis`), `VERDICT.md` inchangé, sauf **dérogation nominative** `deroger-gate.sh --gate=PLAFOND` dont le
chemin est le dossier de l'unité relatif au lab : elle est à **usage unique**, consommée par la commande
(même code que le hook, verrou exclusif du journal) sous le verrou du `PLAN.md` et **avant** l'écriture ;
si l'écriture échoue après la consommation, la dérogation est perdue (fail-closed, visible au journal).
Limite déclarée (g) (libellé mesuré par sonde, quick 261003-ps1) : supprimer `VERDICT.md`, ou le remplacer
par un lien ou un FIFO, remet le compteur à 1 (la tentative 1 est acceptée, code 0 ; le lien est remplacé,
jamais suivi) ; le remplacer par un dossier remet le contrôle à 1 mais l'écriture échoue (code 1, aucun
verdict posé tant que le dossier reste) ; y éditer `tentative:` à une valeur plus basse remet le compteur à
cette valeur + 1 (à `0`, la tentative 1 est acceptée). Les écritures par Bash restent ouvertes. Précisions
(libellé mesuré par sonde, quick 261006-23m) : un agent qui a `Bash` peut s'accorder lui-même la dérogation
`PLAFOND` (`deroger-gate.sh --gate=PLAFOND`, `--qui` déclaratif, T-45-34 ; mesuré : la quatrième pose rend 65
sans elle, 0 avec) — dérogation journalisée et citée à la pose, et, pour D1, deux écritures du moteur (lignes
`moteur`), jamais un contournement ; la disparition de `VERDICT.md` n'est tracée que si `FileChanged` la voit en
séance (ligne `contournement` à `sha256=absent`, quand une référence du fichier existe) : supprimé puis reposé
avant le `SessionStart` suivant, le verdict reposé est une écriture du moteur et la réconciliation ne trace
rien (mesuré : aucun contournement, `tentative: 1`).

**Verdict d'un juge** (P46-D-06a, Q6 = a, même canal) : la commande admet une seconde forme d'unité,
`.planning/juges/<juge>` (nom en minuscules, chiffres et tirets, 64 caractères au plus), dont
l'artefact haché est `SORTIE-PIEGEE.md` (fichier régulier, jamais un lien) au lieu du `PLAN.md` ; ce
verdict ne porte pas `hash_livrables`, et le plafond s'y applique comme à toute unité. Toute autre
forme d'unité reste refusée. Le contrat détaillé de la sortie piégée est livré par le plan 46-09.

### `SUMMARY.md`

Frontmatter : `auteur`, `titre`. S'écrit **après** un verdict passé : un `SUMMARY.md` face à un
verdict en échec est une **contradiction** (P44-D-08, § Règles de dérivation).

### `DEROGATION.md`

Frontmatter : `statut` = `<abandonné|remplacé|gelé> par <auteur>` — le champ **nomme son auteur**
(dérogation nominative, P44-D-07) — `remplace_par` (pour `remplacé`), `le`, `motif`.

**Fichier dédié** plutôt qu'un champ dans `PLAN.md` : une dérogation ne change **jamais** le hash
du plan, et une phase abandonnée avant tout plan a quand même où la porter. **Choix du
planificateur** (comblement de l'espace entre D-03 de la spec — marqueur de clôture séparé de
`PLAN.md` — et P44-D-07 — champ `statut:` nommant l'auteur) : ni l'un ni l'autre ne nomme un
fichier dédié pour la dérogation ; cette référence pose `DEROGATION.md` à côté de
`CADRAGE.md`/`PLAN.md` plutôt que dans l'un d'eux, pour la même raison que `CLOTURE.md` (hash du
plan stable).

## Grammaire du frontmatter

Parseur **minimal** (P44-D-12) : première ligne `---`, fermeture `---` ; lignes vides et
commentaires pleine ligne ignorés ; `clé: valeur` (valeur entre guillemets simples ou doubles
dé-quotée sans échappement, `[]`, `[a, b]`) ; `clé:` vide suivie de `- scalaire` ou de `- k: v` +
`k2: v2` plus indentés.

**Échecs de lecture** : clé dupliquée, bloc `|`/`>`, imbrication plus profonde, ligne orpheline,
frontmatter non fermé → lecture en échec → la raison `frontmatter-invalide:<nom>` quand ce fichier
conditionne l'état. Pas de commentaire en fin de ligne (`#` fait partie de la valeur, qui devient
alors invalide pour un champ fermé).

## Les neuf états et les dérogations

| État | Ce que la machine constate |
|---|---|
| `à cadrer` | dossier présent, pas de `CADRAGE.md` |
| `en cadrage` | registre avec au moins une ligne structurante sans statut |
| `à planifier` | registre clos, pas de `PLAN.md` |
| `à exécuter` | `PLAN.md` présent, marqueur de clôture (`CLOTURE.md`) absent |
| `à juger` | marqueur présent, livrables présents (ni absents ni vides), pas de `VERDICT.md` — **ou** un verdict périmé sans `SUMMARY.md` (règle E, motif `verdict-perime`) |
| `à corriger` | constats du verdict en échec, les deux empreintes conformes |
| `à clore` | constats tous `passé`, les deux empreintes conformes, `SUMMARY.md` absent — **non terminal** (P46-D-04) |
| `close` | constats passés, les deux empreintes conformes **et** `SUMMARY.md` présent |
| `indéterminé` | les signaux se contredisent |

Plus trois **dérogations non dérivables** : `abandonné`, `remplacé`, `gelé` — posées par
dérogation nominative, lues dans un champ `statut:` qui **doit nommer son auteur**. Ces neuf états
plus les trois dérogations s'appliquent **aux phases et aux plans** (P44-D-07).

## Règles de dérivation

Appliquées **dans cet ordre** — la première règle qui s'applique gagne.

### Phase

- **Φ0** — `DEROGATION.md` présent : statut valide → la dérogation ; statut exactement
  `abandonné`, `remplacé` ou `gelé` **sans** « par `<auteur>` » → `indéterminé`
  (`derogation-sans-auteur`) ; tout autre cas → `indéterminé` (`derogation-invalide`).
- **Φ1** — un fichier du modèle présent n'est **pas** un fichier régulier (lien, dossier) →
  `indéterminé` (`fichier-non-regulier:<nom>`) ; illisible ou non UTF-8 →
  `erreur-de-lecture:<nom>`.
- **Φ2** — pas de `CADRAGE.md` : un de PLAN/CLOTURE/VERDICT/SUMMARY ou `plans/` présent →
  `indéterminé` (`hors-cadrage:<nom>`) ; sinon `à cadrer`.
- **Φ3** — frontmatter de `CADRAGE.md` illisible → `frontmatter-invalide:CADRAGE.md` ; registre
  absent ou mal formé (`structurante` hors `oui`/`non`, ligne qui n'est pas un mapping) →
  `registre-invalide`. Le `statut` n'a **pas** de forme invalide : une chaîne libre, vide ou non —
  sa seule présence ferme la ligne (voir Φ4), sa valeur n'est jamais jugée.
- **Φ4** — registre ouvert : un de PLAN/CLOTURE/VERDICT/SUMMARY ou `plans/` présent →
  `indéterminé` (`avant-cadrage-clos:<nom>`) ; sinon `en cadrage`.
- **Φ5** — registre clos : `PLAN.md` et `plans/` ensemble → `plan-direct-et-plans` ; `plans/` avec
  CLOTURE/VERDICT/SUMMARY au niveau de la phase → `fichier-de-plan-au-niveau-phase:<nom>` ;
  `plans/` → agrégation des plans (§ Agrégation) ; sinon règles de feuille R1 à R8 sur les
  fichiers de la phase.

### Règles de feuille (phase à plan direct, ou plan)

Un plan applique Φ0 et Φ1 puis R1 à R8, dont la règle E entre R6 et R7.

- **R1** — pas de `PLAN.md` : SUMMARY présent → `SUMMARY.md-sans-PLAN.md` ; CLOTURE présent →
  `CLOTURE.md-sans-PLAN.md` ; VERDICT présent → `VERDICT.md-sans-PLAN.md` ; sinon `à planifier`.
- **R2** — frontmatter de `PLAN.md` illisible → `frontmatter-invalide:PLAN.md` ; `ecrit:` absent,
  vide ou avec une entrée invalide → `ecrit-invalide`.
- **R3** — pas de `CLOTURE.md` : VERDICT présent → `VERDICT.md-sans-CLOTURE.md` ; SUMMARY présent
  → `SUMMARY.md-sans-CLOTURE.md` ; sinon `à exécuter`.
- **R4** — avant le prédicat, une entrée d'`ecrit:` qui est ou contient le dossier de l'unité (point fixe,
  § `VERDICT.md`) → `ecrit-contient-unite:<entrée>` ; sinon un livrable d'`ecrit:` **absent ou vide**
  (prédicat partagé `livrables_presents`, budget commun au `PLAN.md`, voir § `PLAN.md`) →
  `livrable-absent:<entrée>` (absent, lien ou illisible), `livrable-vide:<entrée>` ou
  `livrable-hors-borne:<entrée>` (borne franchie par cette entrée ou par le cumul des précédentes) ; la
  première entrée fautive dans l'ordre déclaré donne la raison.
- **R5** — pas de `VERDICT.md` : SUMMARY présent → `SUMMARY.md-sans-VERDICT.md` ; sinon `à juger`.
- **R6** — frontmatter de `VERDICT.md` illisible → `frontmatter-invalide:VERDICT.md` ; `constats`
  absent, vide ou avec un `resultat` hors `passé`/`échec` → `verdict-invalide`.
- **E** (empreintes, P46-D-03b) — après un `VERDICT.md` lisible aux constats valides, le recalcul
  compare les **deux empreintes** : `hash` au sha256 des octets du `PLAN.md`, `hash_livrables` à
  l'empreinte des entrées `ecrit:` calculée par la copie partagée du bloc de `poser-verdict.sh`. Un
  écart, ou un `hash_livrables` **absent** (un verdict sans cette clé est traité comme périmé), rend
  `à juger` (`verdict-perime`) quand `SUMMARY.md` est absent, `indéterminé`
  (`livrable-modifie-apres-cloture`) quand il est présent — y compris pour un `PLAN.md` modifié, un
  troisième motif propre au plan n'étant pas requis. Un dépassement de borne pendant le calcul rend
  `indéterminé` (`empreinte-hors-borne`). **R7 et R8 ne s'appliquent qu'à un verdict conforme.**
- **R7** — un constat `échec` : SUMMARY présent → `SUMMARY.md-avec-verdict-en-echec` ; sinon
  `à corriger`.
- **R8** — constats tous `passé` : SUMMARY présent → `close` ; sinon `à clore`.
- **Défaut défensif** : `combinaison-non-prevue` — clause de garde-fou pour une évolution
  future des règles R1-R8/Φ0-Φ5 ; R1-R8 tel que codé aujourd'hui épuise déjà toute combinaison
  possible de plan/cloture/verdict/summary/constats, ce libellé n'est donc produit par AUCUN
  chemin du code actuel (F6, 2026-09-28).

### L'état `à clore`

Entre un verdict aux constats tous `passé`, dont les deux empreintes sont conformes, et l'écriture de
`SUMMARY.md`, l'unité est **`à clore`** (P46-D-04 : Willy, AskUserQuestion session principale,
2026-10-03, Q4 = a). Ce cas rendait jusque-là `indéterminé` (`verdict-passe-sans-SUMMARY.md`), parce que
la table du §3.1 de la spec ne nommait pas cet état de transition et que P44-D-08 interdisait au moteur
de le supposer ; **P44-D-08 est levée sur ce point** et ce code disparaît. `à clore` est un état
**normal et non terminal** : il n'entre pas dans `TERMINAUX`, l'agrégat d'un cycle le rend tel quel (et
non plus `indéterminé`), l'index le liste, et aucune ligne de `cloture.log` n'est écrite tant que
l'unité n'est pas `close`.

**Conséquence voulue de la règle E** : le verdict couvre un artefact, plus un état. Un verdict en
`échec` suivi d'une **correction du livrable** (ou du plan) repasse en `à juger` (`verdict-perime`) dès
la première modification : l'état ne reste pas `à corriger` pendant la correction, il redemande un
jugement (tentative suivante, plafond de trois). De même un livrable réécrit après un verdict `passé`
sans `SUMMARY.md` renvoie de `à clore` à `à juger`, et après `SUMMARY.md` de `close` à `indéterminé`
(`livrable-modifie-apres-cloture`) : jamais un `close` qui survit au contenu qu'il ne couvre plus.

### Les quatre contradictions de P44-D-08

| Contradiction | Règle | Code |
|---|---|---|
| `SUMMARY.md` sans `PLAN.md` | R1 | `SUMMARY.md-sans-PLAN.md` |
| `VERDICT.md` sans marqueur (`CLOTURE.md`) | R3 | `VERDICT.md-sans-CLOTURE.md` |
| `SUMMARY.md` avec un verdict en échec | R7 | `SUMMARY.md-avec-verdict-en-echec` |
| marqueur (`CLOTURE.md`) sans `PLAN.md` | R1 | `CLOTURE.md-sans-PLAN.md` |

### Table de tous les codes de raison

| Code | Règle | Sens |
|---|---|---|
| `derogation-sans-auteur` | Φ0 | dérogation sans « par `<auteur>` » |
| `derogation-invalide` | Φ0 | statut de dérogation ni valide ni identifiable |
| `fichier-non-regulier:<nom>` | Φ1 | un fichier du modèle est un lien ou un dossier |
| `erreur-de-lecture:<nom>` | Φ1 | fichier illisible ou non UTF-8 |
| `hors-cadrage:<nom>` | Φ2 | fichier d'exécution présent sans `CADRAGE.md` |
| `frontmatter-invalide:<nom>` | Φ3, R2, R6 | frontmatter illisible pour ce fichier |
| `registre-invalide` | Φ3 | registre d'inconnues absent ou mal formé |
| `avant-cadrage-clos:<nom>` | Φ4 | fichier d'exécution présent, registre encore ouvert |
| `plan-direct-et-plans` | Φ5 | `PLAN.md` et `plans/` coexistent au niveau phase |
| `fichier-de-plan-au-niveau-phase:<nom>` | Φ5 | CLOTURE/VERDICT/SUMMARY au niveau phase avec `plans/` |
| `SUMMARY.md-sans-PLAN.md` | R1 | contradiction P44-D-08 |
| `CLOTURE.md-sans-PLAN.md` | R1 | contradiction P44-D-08 |
| `VERDICT.md-sans-PLAN.md` | R1 | marqueur ou verdict sans plan |
| `ecrit-invalide` | R2 | `ecrit:` absent, vide, ou entrée invalide |
| `VERDICT.md-sans-CLOTURE.md` | R3 | contradiction P44-D-08 |
| `SUMMARY.md-sans-CLOTURE.md` | R3 | résumé avant l'exécution marquée close |
| `ecrit-contient-unite:<entrée>` | R4 | une entrée d'`ecrit:` est ou contient le dossier de l'unité (unité à `CLOTURE.md`) : la pose d'un verdict y est refusée |
| `livrable-absent:<entrée>` | R4 | un chemin d'`ecrit:` est absent, est un lien (jamais suivi) ou est illisible |
| `livrable-vide:<entrée>` | R4 | un chemin d'`ecrit:` est un fichier de 0 octet ou un dossier sans fichier non vide |
| `livrable-hors-borne:<entrée>` | R4 | le parcours d'un livrable dépasse la borne (2000 entrées, 128 Mio), seul ou cumulé aux entrées précédentes du même `PLAN.md` |
| `SUMMARY.md-sans-VERDICT.md` | R5 | résumé avant jugement |
| `verdict-invalide` | R6 | `constats` absent, vide, ou `resultat` hors `passé`/`échec` |
| `verdict-perime` | E | `hash` ou `hash_livrables` ne correspond plus (ou est absent), `SUMMARY.md` absent : état `à juger`, pas `indéterminé` |
| `livrable-modifie-apres-cloture` | E | même écart avec `SUMMARY.md` présent |
| `empreinte-hors-borne` | E | la borne est dépassée pendant le calcul de l'empreinte des livrables d'un verdict |
| `SUMMARY.md-avec-verdict-en-echec` | R7 | contradiction P44-D-08 |
| `combinaison-non-prevue` | défaut | aucune règle ne s'applique |
| `plan-indetermine:<plan>` | Agrégation phase | un plan de `plans/` est `indéterminé` |
| `phase-indeterminee:<phase>` | Agrégation cycle | une phase du cycle est `indéterminé` |
| `CYCLE.md-absent` | Agrégation cycle | `CYCLE.md` absent ou non régulier |

## Agrégation

Choix délégué (P44-D-07). **Terminal** = `close`, `abandonné`, `remplacé` (`gelé` **n'est pas**
terminal).

**Phase à plans** : `plans/` sans aucun plan → `à planifier` ; un plan `indéterminé` →
`indéterminé` (`plan-indetermine:<plan>`) ; sinon l'état du **premier plan trié non terminal** ;
si tous sont terminaux → `close` s'il en existe au moins un `close`, `abandonné` sinon.

**Cycle** : `CYCLE.md` absent ou non régulier → `indéterminé` (`CYCLE.md-absent`) ; aucune phase →
`à cadrer` ; une phase `indéterminé` → `indéterminé` (`phase-indeterminee:<phase>`) ; sinon l'état
de la **phase courante** (première phase triée non terminale) ; si toutes sont terminales →
`close` s'il en existe au moins une `close`, `abandonné` sinon.

**Cycle courant** (pour `STATE.md`) : le **premier cycle trié** qui n'est ni `close` ni
`abandonné`.

## Sorties générées

**`INDEX.md`** : par cycle ouvert — état, phase courante, dernier signe de vie lu dans
`cloture.log`, bail en cours (« aucun » en Phase 44, les baux arrivent en Phase 47). Les cycles
`close` ou `abandonné` sortent de l'index et sont nommés sur une seule ligne (spec §7.3). Une
section « Hors modèle » liste les entrées signalées par § Emplacements annexes et hors modèle.

**`STATE.md`** : position courante — clés `genere_par`, `cycle_courant`, `phase_courante`, `etat`.
**Jamais** `last_updated:` (aboli par la dérivation pure — spec §7.4).

**`cloture.log`** : **append-only** (P44-D-11). Ligne :

```
<horodatage ISO avec fuseau>  <chemin>  <auteur>  verdict=<v>  tentative=<n|->  date=observation
```

`verdict` vaut `passé` pour une feuille `close`, `plans-clos` pour une phase à plans `close`,
`plans-abandonnes` pour une phase à plans `abandonné`, ou le nom de la dérogation (`abandonné`,
`remplacé`, `gelé`) sinon. `auteur` = le champ `auteur:` de `SUMMARY.md` pour une feuille `close`,
l'auteur nommé par `statut:` pour une dérogation, `inconnu` sinon — **jamais git** (P44-D-11). Une
ligne s'ajoute quand le couple verdict/tentative d'une unité **diffère** de sa dernière ligne
journalisée ; une ré-entrée au même couple n'est **pas** re-journalisée (dédoublonnage).

**Assainissement structurel INJECTIF de chaque champ** (`_jeton_journal`, lot 4 de la correction
ciblée de la Phase 44 — remplace l'assainissement par `_` du lot 2 L2) : `chemin`, `auteur`,
`verdict` et `tentative` sont chacun encodés en **pourcent** avant l'écriture — tout caractère
considéré comme un espace par Python (`str.isspace()`, qui couvre U+2028 LIGNE SÉPARATRICE, U+0085
NEL et tout espace Unicode, pas seulement l'ASCII), tout caractère NON IMPRIMABLE (`not
str.isprintable()`, alphabet étendu F44-05/F7, lot 5 — couvre NUL et les contrôles C0/C1 qui
restaient laissés bruts jusque-là, en plus des séparateurs Unicode déjà couverts par `isspace()`),
tout `=` (qui ouvrirait une séquence `clé=` lisible par `LIGNE_JOURNAL_RE`) et le caractère
d'échappement `%` lui-même deviennent `%XX` — deux chiffres hexadécimaux majuscules par OCTET de
l'encodage UTF-8 du caractère. Ces champs viennent de valeurs lues sans contrôle de SENS (P44-D-09 :
`tentative:` par exemple est recopié tel quel depuis `VERDICT.md`, jamais interprété). L'ancien
assainissement par `_` n'était **pas injectif** : `"3 4"` et `"3_4"` s'écrasaient sur le même jeton
`"3_4"`, ce qui pouvait faire **manquer** au dédoublonnage une clôture réellement nouvelle (deux
valeurs distinctes du même champ, au même chemin, confondues) — violation de P44-D-11 (préserver
toute clôture réellement nouvelle), mesurée par une preuve générative (2000 paires aléatoires, zéro
collision) et un round-trip réel à deux exécutions successives (`test-recalc-planning.sh`,
R-INJECTIF-GENERATIF/R-INJECTIF-ROUNDTRIP). Toujours **aucun contrôle de sens** : la valeur
assainie reste lue telle quelle, jamais validée. Un jeton ne peut **jamais** rester vide (F5, lot
5) : le paramètre de repli (toujours un littéral non vide chez tous les appelants) est un contrat
interne vérifié par une erreur bruyante (`ValueError`) plutôt qu'une ligne de journal illisible
produite en silence.

**`.recalc-cache.json`** : JSON, `cache_schema_version` = `2`, `moteur` = `"recalc-planning"`,
signature sha256 du contenu des fichiers lus par unité, et par unité l'**état des livrables** `ecrit:`
(`empreinte_livrables`, P46-D-03b) : `["ok", <empreinte>]` quand tous sont présents, `["statuts", {…}]`
quand l'un d'eux est absent, vide, lien ou hors borne (statuts rendus par `livrables_presents`, budget
commun ; la dérivation ne dépend alors que de ces statuts). Les entrées surveillées sont lues par la même
chaîne `entrees_du_plan` que R2 (aucune quand une entrée couvre le dossier de l'unité). Une entrée
n'est reprise que si la signature **et** cet état, **recalculé à chaque passage** par la copie partagée
(bornée), sont égaux ; un livrable réécrit, même à taille égale, fait donc recalculer l'unité — un `close`
en cache ne survit jamais à la réécriture d'un livrable (les schémas 1, qui ne retenaient que l'existence
des livrables, sont relus comme `autre-format`). Une empreinte non calculable alors que tous les
livrables sont présents (borne, lecture impossible) n'est jamais reprise. **Coût déclaré** : chaque
passage hache le contenu des livrables de chaque unité qui déclare un `ecrit:` valide, dans la borne de
2000 entrées et 128 Mio par unité — la spec §10 impose le hachage du contenu, jamais une signature par
date. Absent, illisible, lien, ou d'un autre
`cache_schema_version` → recalcul complet, **jamais** une confiance aveugle. Le cache est
**incrémental par hash du contenu**, **jamais par `mtime`** (P44-D-13) — un `touch` sans
changement de contenu ne change rien, un changement de contenu à `mtime` restauré est vu. Le
cache n'est **jamais** lu ni écrit en mode `--read-only` (T-44-21).

**Limite connue et acceptée du cache** (registre des menaces T-44-20, 44-04) : une entrée de cache
**forgée au bon format et à la bonne signature** est reprise sans être rejugée — le cache n'est
pas un fichier protégé contre l'écriture à la main. Ceci exige déjà un accès en écriture à
`.planning/`, qui permet tout autant de réécrire n'importe quel fichier du modèle ; ce n'est donc
pas une surface nouvelle. La protection du cache contre l'écriture à la main est **G6** (Phase 45,
P44-D-15) — comme pour les autres fichiers générés, elle n'existe pas encore en Phase 44. La
lecture seule n'est, elle, jamais affectée : elle ne consulte jamais le cache (voir ci-dessus).

**Déterminisme** : deux recalculs sur le même disque rendent des fichiers identiques **octet pour
octet** (P44-D-10).

### Lisibilité des causes indéterminées

Décision (a), head sous délégation technique de Willy, session principale, 2026-09-28 : toute
ligne `indéterminé` rendue dans `INDEX.md` (ligne d'un cycle) **et** toute valeur `indéterminé` de
`etat` dans `STATE.md` portent un libellé lisible par un humain, jamais le seul code brut :

```
indéterminé — <libelle_raison(code)> (<chemin>)
```

Espace avant la parenthèse ; `libelle_raison(code)` est le nom exact de la fonction du moteur —
forme **identique** au contrat de 44-01, jamais un `<libellé>` générique. Cette forme s'applique
**à la fois** à `INDEX.md` et à `STATE.md`.

**Exception nommée à cette forme** (correction de classe, revue de plan tour 4) : quand `code` vaut
`phase-indeterminee:<phase>` (le cycle est indéterminé **parce qu'**une de ses phases l'est), le
libellé s'étend à la **cause propre** de cette phase :

```
indéterminé — phase `<phase>` indéterminée : <libelle_raison(raison_propre_de_la_phase)> (<chemin>)
```

Jamais le seul nom de la phase seule, pour que deux phases indéterminées pour des causes
différentes rendent deux libellés différents (cross-vérifié par 44-03 R27 et 44-04 R53). **Repli
défensif** sur la forme **sans** le deux-points (`` phase `<phase>` indéterminée `` seule) si la
phase nommée n'est pas retrouvée, n'est pas elle-même `indéterminé`, ou n'a pas de `raison`.

Le libellé vient d'une table `LIBELLES` (code → gabarit de phrase) tenue par le moteur, reproduite
ici :

| Code | Libellé |
|---|---|
| `combinaison-non-prevue` | combinaison de signaux non prévue |
| `verdict-perime` | verdict périmé : re-juger (tentative n+1) |
| `livrable-modifie-apres-cloture` | livrable ou plan modifié après la clôture |
| `empreinte-hors-borne` | empreinte des livrables hors borne |
| `SUMMARY.md-sans-PLAN.md` | SUMMARY.md sans PLAN.md |
| `CLOTURE.md-sans-PLAN.md` | CLOTURE.md sans PLAN.md |
| `VERDICT.md-sans-CLOTURE.md` | VERDICT.md sans CLOTURE.md (marqueur) |
| `SUMMARY.md-avec-verdict-en-echec` | SUMMARY.md avec un verdict en échec |
| `derogation-sans-auteur` | dérogation sans auteur nommé |
| `derogation-invalide` | dérogation invalide |
| `CYCLE.md-absent` | CYCLE.md absent |
| `livrable-absent:<entrée>` | livrable absent : `<entrée>` |
| `livrable-vide:<entrée>` | livrable vide : `<entrée>` |
| `livrable-hors-borne:<entrée>` | livrable hors borne : `<entrée>` |
| `ecrit-contient-unite:<entrée>` | ecrit: couvre le dossier de l'unité : `<entrée>` |

Un code **suffixé** `:<x>` (ex. `phase-indeterminee:<phase>`, `plan-indetermine:<plan>`,
`livrable-absent:<entrée>`) se sépare sur le **premier** `:` : le libellé de la partie fixe
s'applique et `<x>` s'y insère littéralement — `phase-indeterminee:<phase>` → «`` phase `<phase>`
indéterminée ``» ; `plan-indetermine:<plan>` → «`` plan `<plan>` indéterminé ``» ;
`livrable-absent:<entrée>` → « livrable absent : `<entrée>` » ; `livrable-vide:<entrée>` → « livrable vide :
`<entrée>` » ; `livrable-hors-borne:<entrée>` → « livrable hors borne : `<entrée>` » ;
`ecrit-contient-unite:<entrée>` → « ecrit: couvre le dossier de l'unité : `<entrée>` ».

Tout code **absent** de la table (`fichier-non-regulier:<nom>`, `erreur-de-lecture:<nom>`,
`frontmatter-invalide:<nom>`, `hors-cadrage:<nom>`, `registre-invalide`,
`avant-cadrage-clos:<nom>`, `plan-direct-et-plans`, `fichier-de-plan-au-niveau-phase:<nom>`,
`ecrit-invalide`, `verdict-invalide`, `SUMMARY.md-sans-CLOTURE.md`, `SUMMARY.md-sans-VERDICT.md`,
`VERDICT.md-sans-PLAN.md` compris) retombe sur **lui-même** avec `-` et `:` remplacés par des
espaces — jamais un `KeyError`.

**La raison d'un `à juger` périmé** (P46-D-03b) se lit aussi : une unité `à juger` dont la raison vaut
`verdict-perime` rend, dans `INDEX.md` (ligne du cycle) et dans `STATE.md` (`etat`),
`à juger — verdict périmé : re-juger (tentative n+1)` ; un `à juger` ordinaire (sans verdict) reste `à juger`
tout court. Le cycle et la phase à plans remontent la raison de leur unité courante.

Le JSON, lui, garde **toujours** le code brut dans `raison` : la forme lisible n'habille que
`INDEX.md` et `STATE.md`.

## La commande recalc-planning.sh

```
recalc-planning.sh [--planning=<dossier>] [--read-only] [-h|--help]
```

Posée dans `.claude/scripts/` par l'installeur. Codes de sortie : **0** succès, **1** erreur
d'exécution, **2** refus d'adhésion, **3** refus GSD, **64** usage. Python 3.9+, bibliothèque
standard seule.

## Gabarits

Neuf gabarits sous `plugin/planning-core/references/templates/cycles/`, un par fichier du modèle (plus la sortie piégée d'un juge, Phase 46),
**à côté** des gabarits v2 (inchangés) :

| Gabarit | Fichier du modèle |
|---|---|
| `CYCLE.template.md` | `CYCLE.md` |
| `CADRAGE.template.md` | `CADRAGE.md` |
| `PLAN.template.md` | `PLAN.md` |
| `CLOTURE.template.md` | `CLOTURE.md` |
| `VERDICT.template.md` | `VERDICT.md` |
| `SUMMARY.template.md` | `SUMMARY.md` |
| `DEROGATION.template.md` | `DEROGATION.md` |
| `SORTIE-PIEGEE.template.md` | `SORTIE-PIEGEE.md` d'un juge (`.planning/juges/<juge>/`, voir « Canary de juge ») |
| `config.template.json` | déclaration d'adhésion (`cycles-v1`) |

**Un gabarit recopié tel quel (sans être rempli) ne fait jamais passer une unité en `close`** :

| Gabarit recopié tel quel | État dérivé |
|---|---|
| `CADRAGE.md` | `en cadrage` |
| `PLAN.md` (entrée `ecrit:` à crochets) | `indéterminé` (`ecrit-invalide`) |
| `VERDICT.md` (résultat à crochets) | `indéterminé` (`verdict-invalide`) |
| `DEROGATION.md` (statut à crochets) | `indéterminé` (`derogation-invalide`) |
| `CYCLE.md` seul | cycle `à cadrer` |
| `SORTIE-PIEGEE.md` (sans verdict de canary) | aucun état dérivé ; le juge est signalé « sans preuve », jamais vert |
| `config.json` | adhérent (`cycles-v1`) |

## Hook central et gates d'écriture (Phase 45)

Cette section décrit ce que la Phase 45 **livre**, tel que le code livré le fait. Elle est tenue
identique au code par un contrôle croisé (R-REFERENCE, `scripts/tests/test-planning-gates.sh`) qui
compare la table d'armement, les noms protégés par G6, le nom du journal de dérogation, la liste des
marqueurs de code, l'ordre de résolution des agents, les outils refusés en mode dégradé et la présence
des limites déclarées aux constantes du hook et à la commande de `hooks.json` : un écart rougit la
suite (MUT-REFERENCE le prouve). Chaque décision citée porte le préfixe `P45-D-NN` (`45-CONTEXT.md`) ;
chaque arbitrage humain nomme son canal et sa date.

### Principe

- **Une mécanique, deux chantiers.** Un seul script, `scripts/planning-hook.sh` (lanceur bash et cœur
  Python embarqué, P45-D-15), porte les gates d'écriture du moteur (G1, G2, G5, G6, G7) et le
  cloisonnement par rôle de la fabrique d'agents (ROLE). Il est déclaré par une seule entrée
  `PreToolUse` de `hooks.json`.
- **Adhérents seuls** (P45-D-01, P45-D-01a, P45-D-04). Il n'agit que dans un lab dont
  `.planning/config.json` déclare `"planning_version": "cycles-v1"` (même lecture que l'adhésion du
  recalcul). Hors d'un lab adhérent — labs dev, ce dépôt compris — il ne sort rien (octet vide) et
  rend 0 : un lab dev n'est jamais refusé, et la mutation « ignorer l'adhésion » rend la preuve rouge.
  Les drapeaux `phases_trace` et `options.gates` de `config.json` restent **sans effet** : les gates
  s'arment avec l'adhésion, et un gate ne se désarme que par une dérogation nominative, jamais par un
  drapeau qu'un agent peut écrire (P45-D-01).
- **Racine dérivée du chemin écrit** (P45-D-12), jamais de `$CLAUDE_PROJECT_DIR`, qui ne suit pas
  `EnterWorktree` : la racine du lab est le plus proche ancêtre du chemin écrit (à défaut, du `cwd` du
  payload pour un dispatch) qui contient un dossier `.planning` ; le plus proche gagne.
- **Forme normale NFC sous la racine** (fix-46-a, A1, correction de classe). Tout test de forme d'un gate (`NOM_UNITE`, noms
  fixes comparés en casefold, `.planning`) et toute lecture de l'unité passent par `composants_nfc` : le chemin résolu
  physiquement, rendu relatif à la racine du lab, chaque composant en forme normale NFC. Un nom d'unité saisi en NFD — qu'APFS et
  HFS+ résolvent vers le dossier de sa forme NFC, où `NOM_UNITE` ne reconnaissait plus rien, d'où un passage de G1, G3 et G4 — rend la
  MÊME décision que sa forme NFC, sur tout système de fichiers : le hook lit l'unité sous la forme NFC de ses composants. Voies couvertes :
  `file_path` et `notebook_path` (G1, G3, G4, G5, G6, G7, ROLE), chemins tirés d'une commande Bash (G2), `cwd` (un chemin relatif est
  joint au `cwd` puis normalisé ; `cible_de` ne normalise rien), `file_path` de FileChanged et intentions de D1
  (`chemin_relatif_surveille`), clés de la réconciliation. Les écrivains normalisent aux mêmes endroits : `poser-verdict.sh` (`--unite`,
  clé de la dérogation PLAFOND et du journal de D1), `deroger-gate.sh` (`--chemin`), `_couvre_unite` (bloc partagé, trois copies
  ast-identiques) ; `recalc-planning.sh` ne change que `_couvre_unite` (il dérive les unités des noms du disque, jamais d'un chemin
  fourni par un agent). Les noms LUS par énumération de dossiers (readdir) passent aussi en NFC avant leur test de forme
  (A1-readdir, fix-46-a tour 2) : `_sous_dossiers` (les unités que D1 surveille et que G2 lit) et `_verdicts_du_planning` (G5) ; le nom du
  disque reste celui qui construit le chemin d'accès, et `cle_recence` départage sur la forme NFC du nom. Les dix énumérations de dossiers du
  cœur sont recensées avec leur décision (deux en NFC, cinq neutres, une brute — le bloc d'empreinte partagé —, deux hors lab). Preuves :
  R-BANC-NFD (banc de clôture ; D1 et G3/G4 aussi sur un disque dont les noms sont en NFD), R-NFD-GATES (banc des gates ; G2 aussi sur un disque
  NFD), R-READDIR-RECENSEMENT, R-NFD-02, R-EMP-13, R-D1-15 et leurs mutants ; limite (bf).
- **Un refus est un JSON `permissionDecision: "deny"` rendu avec le code 0** (P45-D-08), jamais un
  exit 2 ; toute erreur interne du script, dans le périmètre adhérent, est piégée et rendue en `deny`.
- **Périmètre d'environnement** (P45-D-12a ; amendement de R-ENV-02, décisions du manager
  vf-dev-manager, 2026-09-30). Aucune variable d'environnement ne change l'armement ni l'adhésion.
  Le lanceur lit `TMPDIR` (où poser le fichier de transport du payload), `XDG_CACHE_HOME` puis `HOME`
  (le seul chemin du journal d'observation) ; `HOME` est aussi l'entrée déclarée de la seule résolution
  des définitions d'agent du compte et des plugins (P45-D-05b). Ces lectures sont celles du
  **lanceur**, qui les passe en arguments au cœur Python : le cœur ne lit aucune variable
  d'environnement, `os.path.expanduser` compris. Un `HOME` différent change la résolution d'un agent
  du compte, jamais l'adhésion ni l'état d'armement.

### La commande enregistrée (fail-closed dans un lab adhérent)

L'entrée `PreToolUse` de `hooks.json` (matcher `Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback`,
élargi par la Phase 46 ; `timeout` de 20 s) est une commande **de forme shell**, jamais la forme exec `{{VF_BASH}}` (qui part dans
`settings.local.json` et n'a pas de shell pour porter le test de présence) : l'installeur la pose
dans `settings.json`. Elle lance le script en fils et **reprend tout code non nul** (script absent,
`python3` absent, plantage, échéance interne : code 73). Dans ce cas elle décide elle-même, **sans
`python3`**, si le lab est adhérent — extraction shell du chemin écrit ou du `cwd`, remontée jusqu'au
plus proche `.planning`, lecture de `config.json` — et :

- dans un lab adhérent (ou dans le doute, voir (u)), elle émet un refus JSON statique avec un message
  de réparation (mettre à jour VibeFlow, ou installer `python3`, puis relancer la session) ;
- hors d'un lab adhérent, elle se tait : un lab dev sans `python3` n'est jamais refusé (P45-D-06a) ;
- un `config.json` de plus de 1 Mio (`BORNE_LECTURE_FICHIER`, A11-classe) rend l'adhésion **indéterminée** : sous `PreToolUse` le cœur sort en code 3 sans
  rien décider et cette couche tranche par son `grep` (refus dans un lab qu'elle dit adhérent, silence dans un lab dev et sur `Bash`) ; sur les autres
  événements le cœur se tait (limite (bj)) ;
- le **timeout** du harnais reste un fail-open sans réglage possible : le canary est obligatoire de
  toute façon (P45-D-06, P45-D-20). La couche shell ne s'y expose plus par la longueur d'une valeur du
  payload : au-delà de 4096 caractères elle ne parcourt pas la valeur, la refuse si elle nomme `.planning` ou `.claude` ou porte un antislash et la tranche sinon sur le cwd ; le cœur la lit sous deux formes en temps linéaire (réduite lexicalement, physique) et n'en décide dans le doute que si elle reste trop longue (F-01, N-01, N2-01, N3-01, limite (aa)).

Un **pré-filtre hors adhésion** ouvre la commande (revue de Samuel sur la PR #124, 2026-10-01 : « un hook ne paie son coût que
là où il a un effet » ; arbitrage de Willy, AskUserQuestion session principale, 2026-10-02 : le pré-filtre seul, `Bash` reste dans
le matcher). Avant tout lancement du script, de `mktemp` ou de `python3`, la fonction `vf_pre` rend « court-circuit » (`exit 0`
immédiat) UNIQUEMENT quand le lab est CERTAINEMENT non adhérent ; dans tous les autres cas rien ne change dans le chemin d'avant,
octet pour octet (adhérent, doute, valeur non analysable). Règle : elle lit TOUTES les occurrences des valeurs `file_path`,
`notebook_path` et `cwd` du payload, plus `$PWD` et le cwd physique du processus ; chacune doit être absolue, de 1024 caractères
(PATH_MAX sous macOS) et 64 composants au plus, propre (ni `//`, ni `.` ou `..`, ni `/` final, ni `/.vol`) et sans antislash, le payload tenant sur une seule ligne et ne portant
aucun échappement `\u00xx` ASCII (une clé écrite `\u0066ile_path` n'est pas lue : le payload est alors différé) ; puis, pour CHAQUE
ancêtre de chacune (forme lexicale ET forme physique, `cd -P` et `pwd -P` de la partie existante dès qu'un lien intervient), un
dossier `.planning` doit avoir un `config.json` absent ou régulier, lisible, sans `cycles-v1` (casse ignorée, `grep -F`) ni antislash ;
un lien pendant ou en boucle, une config illisible ou non régulière, un `.planning` imbriqué ou sous `.claude` qui porterait
`cycles-v1` renvoient au chemin complet. Le coût d'une exécution est **borné par construction, et ne dépend d'aucun contenu du système de fichiers que l'agent contrôle** (re-audit du pré-filtre, 2026-10-02, F-P1, F-P2, F-P3 et F-P4 ; arbitrage de Willy, AskUserQuestion
session principale, 2026-10-02 : le pré-filtre seul, `Bash` reste dans le matcher) : une valeur de plus de 1024 caractères ou de plus
de 64 composants, une correspondance brute (clé, blancs et valeur) de plus de 2048 caractères, ou plus de 16 valeurs dans le payload
renvoient au chemin complet. Les composants sont comptés sur la valeur elle-même,
avant tout parcours. Le parcours des ancêtres ne retient qu'UN seul préfixe déjà vérifié (la dernière valeur parcourue : un ancêtre
lexical de ce préfixe, à la frontière d'un composant, est vérifié d'avance) : la chaîne de dédoublonnage de la première version,
accumulée puis balayée à chaque ancêtre, rendait le coût cubique en la profondeur (un `cwd` propre de 1 548 caractères dépassait le
`timeout` de 20 s, que le harnais traite en laissant passer : un fail-open, le `cwd` précédant `tool_input` dans le payload). Sans
aucune mémoire le coût serait borné mais doublerait dans un dépôt qui porte deux `.planning` sur sa chaîne (un `grep` par config et par
valeur, mesuré le 2026-10-02 : 40 ms contre 24 ms par appel de Write) ; la mémoire d'un seul préfixe garde le gain d'origine. Deux bornes ferment F-P3 (haute : une `config.json` creuse de 2 Gio sur la chaîne du `cwd`, lue par `grep` sans borne, dépassait le `timeout` de 20 s, soit un fail-open de tous les gates ; 16 valeurs sur 16 arbres de configs, 18 s sous charge) : une `config.json` de plus de 64 Kio (`find -L … -size +128`, mesure sans lecture du contenu, lien suivi : une config qui est un lien vers un fichier creux est mesurée sur sa cible) fait différer AVANT toute lecture, et un budget de 64 lectures de config par exécution (compteur remis à 0 au début de `vf_pre`) fait différer au-delà. Le pré-filtre ne lit donc jamais plus de 64 fois 64 Kio, quels que soient le nombre de valeurs, la profondeur et le contenu des arbres ; tout dépassement renvoie à DEFER, c'est-à-dire au chemin complet, qui paie alors le coût d'avant plus celui, borné, du parcours déjà fait (au plus 64 `find` et `grep` sur des configs de 64 Kio ou moins, soit moins d'une demi-seconde mesurée au pire sur les sondes de l'audit : 0,26 s). Le coût du CŒUR (`planning-hook.sh`, qui lit une config de 2 Gio en 1,5 à 2,5 s) est celui d'avant, inchangé, hors du périmètre du pré-filtre. F-P4 (basse) : `_pa` et le compteur sont initialisés au début de `vf_pre`, jamais lus de l'environnement du processus (un `_pa` hérité, égal à un ancêtre adhérent, rendait SHORT). Limite déclarée F-P5 (basse, re-audit du 2026-10-03, vérification SECURED) : la borne de taille suppose `find` présent dans le PATH du hook ; sans lui, `$(find …)` est vide et la borne se perd en silence (une config creuse de 2 Gio redevient lue en entier). Non exploitable sans contrôle du PATH du hook, qui n'appartient pas au modèle ; `find` est POSIX. Correctif possible, non fait : prouver positivement la petite taille (`-size -129`) pour différer quand `find` manque. La même borne de longueur règle F-P2 : sous 2048 caractères de correspondance le repli
de l'ancienne commande ne bascule pas dans son régime « valeur de plus de 4096 caractères » et refuse comme le pré-filtre se tait, soit
exactement la même sortie. Le pré-filtre est volontairement PLUS conservateur que le cœur : il ne réimplémente ni « le
plus proche gagne », ni `.claude/worktrees`, ni `.planning/.planning`, il renvoie au chemin complet dès qu'un ancêtre, quel qu'il
soit, peut être adhérent. Sens fail-closed : il ne peut que court-circuiter un « non adhérent », jamais créer un passage dans un lab
adhérent ; toute erreur (grep, `cd`, valeur inattendue) renvoie au chemin complet. Il tourne sous sh, dash, bash et zsh et n'ajoute
aucune dépendance. Garde : `test-planning-prefilter.sh` (équivalence sur le banc, les arbres adverses, le générateur de valeurs
longues et un générateur d'arbres de labs ; mutants).

- **Pré-filtre hors adhésion** : `vf_pre`, appelé par `vf_pre && exit 0` avant le lancement du script ; hors lab adhérent il sort aussitôt, sans script, sans mktemp, sans python3 ; dans le doute il ne change rien (fail-closed).
- **Outils refusés en mode dégradé** : `Write`, `Edit`, `NotebookEdit`, `SubagentHandback`, `Agent`, `Task`.
- **Outil laissé ouvert en mode dégradé** : `Bash` (P45-D-06b).

Limites déclarées de la couche shell, puis des gates, chacune sur sa propre ligne (la lettre, puis la
source). Les lettres (a) à (l) sont celles du plan ; (m) et suivantes sont les limites que les
corrections ciblées et les relectures de la phase ont ajoutées (décisions du manager vf-dev-manager,
2026-10-01, renversables par Willy).

- **limite (a)** — la commande ne reconnaît le filtre d'outil qu'en JSON **compact** : un `"tool_name" : "Write"` espacé, ou même une seule espace après les deux-points (`"tool_name": "Write"`, N-06 du re-audit du 2026-10-01), échappe au filtre dégradé (les clés de chemin tolèrent les blancs). Antérieur au lot et lié à la sérialisation du harnais (compacte, vérifié sur le harnais 2.1.284, plan 45-01) ; non exploitable par `Write` seul : il faut d'abord une panne du cœur, qui lui décode le JSON quelle que soit la mise en forme.
- **limite (b)** — la couche shell ne reconnaît `cycles-v1` qu'en forme littérale sur **une ligne** : une valeur échappée, ou une clé et une valeur sur deux lignes, ne sont pas reconnues ; le script Python, lui, décide exactement quand il tourne (la conséquence de l'écart est la limite (m)).
- **limite (c)** — un `config.json` en lien symbolique est adhérent côté shell et non adhérent côté Python (`O_NOFOLLOW`, comme le recalcul).
- **limite (d)** — fermée : un chemin à échappement JSON non géré (`\b`, `\f`, `\r`, `\uXXXX`) ferme sans condition quand le cœur est tombé (lot A, décision du manager vf-dev-manager, 2026-10-01) ; le coût de cette fermeture est la limite (u).
- **limite (e)** — une charge utile qui n'est pas du JSON n'est jamais refusée en mode dégradé (outil inconnu).
- **limite (f)** — `bash` absent (une image sans `bash`) : code 127, donc chemin dégradé (refus dans un lab adhérent), même politique fail-closed que le recalcul sans `bash`.
- **limite (g)** — **Bash reste ouvert en mode dégradé** (P45-D-06b) : quand le script ou `python3` manque dans un lab adhérent, `Write`, `Edit`, `NotebookEdit`, `Agent` et `Task` sont refusés mais `Bash` passe, pour que la réparation (poser le script, installer `python3`) reste possible ; cohérent avec P45-D-10 (Bash n'est jamais couvert par les refus).
- **limite (h)** — un chemin écrit relatif est joint au `cwd` du payload par les deux couches (le harnais l'émet toujours absolu, P45-D-12) ; `..` n'est résolu que par la résolution physique du plus proche ancêtre existant.
- **limite (i)** — en scope projet, `$CLAUDE_PROJECT_DIR` choisit QUELLE copie de `planning-hook.sh` s'exécute, donc quelle table d'armement (une copie périmée d'un autre worktree peut s'exécuter à la place de la bonne) : le hook ne peut pas le tester de l'intérieur, le canary de session le rend visible en rejouant la commande telle qu'elle est posée (P45-D-21b, P45-D-12a).
- **limite (j)** — G1 laisse passer l'écriture d'un `PLAN.md` quand `CADRAGE.md` est non régulier (dossier ou lien), a un frontmatter invalide ou est au format hérité, parce que le modèle de la 44 rend alors `indéterminé`, qui n'est pas « interdit » ; contournement connu (transformer `CADRAGE.md` en dossier ou en lien pour passer G1), limite acceptée ; F5 = f5-etats (choix du plan 45-06, rattaché à P45-D-21a ; renversable par Willy ; l'alternative stricte élargirait GATE-06) ; menace T-45-55.
- **limite (k)** — m2 (décisions du manager vf-dev-manager, 2026-09-30) : en mode panne (script ou `python3` absent), la couche shell tient pour adhérent un `config.json` à virgule finale, clé dupliquée, valeur imbriquée ou BOM UTF-8 que le cœur Python tient pour non adhérent : le lab est refusé en panne, cohérent avec P45-D-06a.
- **limite (l)** — F9 (Willy, AskUserQuestion session principale, 2026-09-30) : l'allowlist que le hook applique à un worker vit dans une définition d'agent que G6 ne protège pas — un agent qui édite sa propre allowlist étend ce qu'il peut dispatcher ; écart déclaré avec la ligne « Worker : tout dispatch refusé » de la table §5 de la spec fabrique.
- **limite (m)** — F2 (re-audit, inverse de (k)) : un `config.json` adhérent pour Python mais à clé ou valeur échappée (par exemple `_` ou `-` écrits en `\u…`) ou réparti sur plusieurs lignes est lu comme non adhérent par le repli shell, donc silence si le cœur tombe ; exploitation conditionnée à une panne du cœur. Fermée en partie par F-02 (audit de sécurité final, 2026-10-01) : G6 n'admet plus l'écriture PAR OUTIL d'un `config.json` qui ne satisfait pas le motif du repli (constante partagée `MOTIF_ADHESION_REPLI` du cœur, comparée par une suite au `grep` de `hooks.json`, jamais une seconde copie) ; reste un `config.json` déjà écrit sous cette forme, ou écrit hors outil (`Bash`).
- **limite (n)** — T-45-42 reformulée : F6 (`config.json` protégé par G6 contre un changement ou un retrait de l'adhésion, Willy, AskUserQuestion session principale, 2026-09-30) ferme le désarmement « par outil » ; Bash reste ouvert (P45-D-10) : un `sed` ou une redirection qui retire l'adhésion désarme les gates.
- **limite (o)** — amendement de P45-D-01a (décision du manager vf-dev-manager, 2026-10-01) : un `.planning` situé dans (ou sous) un composant `.planning` n'est jamais une racine de lab ; limite : un lab situé sous un ancêtre nommé `.planning` n'est plus une racine gardée. Second amendement (même classe, lot E, décision du manager vf-dev-manager, 2026-10-01, renversable) : un `.planning` situé sous un composant `.claude` (par exemple `<lab>/.claude/.planning` ou `<lab>/.claude/scripts/.planning`) n'est jamais une racine de lab non plus — sans lui, trois écritures par outil (un marqueur de code, un fichier sous `.claude/scripts/.planning/`, puis le script du hook) désarmaient la protection des scripts du hook. Seul le DERNIER composant `.claude` du chemin compte, et `.claude/worktrees/<nom>` (là où Claude Code pose les worktrees d'un lab) reste une racine possible ; limite : un lab dont le dossier est LUI-MÊME nommé `.claude` ou placé sous `.claude/<autre chose que worktrees/nom>` n'est pas une racine gardée. Les quatre implémentations de la règle (cœur du hook, `poser-verdict.sh`, canary, commande enregistrée de `hooks.json`) s'accordent. Exception à cet accord, mesurée (lot F) : les replis Unicode de « worktrees » — U+212A (KELVIN SIGN) pour le k, U+017F (LONG S) pour le s — sont ramenés à `worktrees` par le cœur Python (casefold) mais pas par la commande enregistrée de `hooks.json` (motif `[Ww][Oo][Rr][Kk][Tt][Rr][Ee][Ee][Ss]`), qui tient alors le chemin pour un `.claude` ordinaire et reconnaît donc moins de racines que le cœur : en panne du cœur seulement, elle refuse dans une poche ainsi nommée d'un lab adhérent (où le cœur se tait) et se tait pour un lab adhérent posé lui-même sous `.claude/<ce nom>/<nom>` (que le cœur juge : sur copie armée, G6 y refuse `STATE.md` et le script du hook).
- **limite (p)** — R1 (re-audit) : un `.planning/` sans `config.json` sous un sous-dossier ordinaire rend ce sous-dossier non adhérent (« le plus proche gagne ») ; G7 n'interdit que sa création par outil, pas son existence.
- **limite (q)** — m1 (revue) : un worker qui dispatche sans `subagent_type`, ou avec `fork`, est refusé (le hook ne traite pas `fork` à part : absent de l'allowlist) ; la sémantique du harnais pour ces dispatchs n'est pas mesurée.
- **limite (r)** — m6 (revue) : le journal d'observation (`~/.cache/vibeflow/gates-observation/`) n'a ni borne ni rotation.
- **limite (s)** — coût et échéance : la résolution d'un agent de plugin a été mesurée à environ 0,05 s à vide (0,11 s au plus avec mille fichiers dans le dossier d'agents, huit définitions candidates de 1 Mio comprises ; 0,12 à 0,40 s avant la correction du lot A) ; la borne n'est pas ce coût mais l'échéance interne de 8 s du cœur (code 73), qui ferme sous adhésion : sur une machine lente ou chargée, un dépassement refuse des écritures légitimes (risque de déni de service).
- **limite (t)** — F3 (re-revue) : sans `installed_plugins.json` exploitable, la « plus haute version » d'un plugin est extraite des chiffres du nom de dossier (un SHA ou `unknown` peut la fausser), tous scopes confondus.
- **limite (u)** — F4 (re-revue ; décision du manager vf-dev-manager, 2026-10-01) : cœur tombé, un chemin portant un échappement JSON non géré (`\b`, `\f`, `\r`, `\uXXXX`) est refusé même hors de tout lab adhérent, le doute tombant du côté du refus ; le message dit « doute d'adhésion du lab » et non qu'un lab adhérent est en cause.
- **limite (v)** — F5 (lot B) : un `STATE.md` qui porte la marque de génération en tête, puis édité à la main, est remplacé sans archive (la marque seule le fait tenir pour généré).
- **limite (w)** — N1 résiduelle : un `name:` masqué par un échappement YAML dans l'en-tête de la définition n'est pas candidat à l'indexation des agents.
- **limite (x)** — rejeu : le volume n'est pas optimisé (25 000 fichiers en plus de 300 s) ; un `.planning` qui est un lien vers un dossier du lab n'est pas suivi par la copie et rend désormais MESURE-VIDE (code 1), jamais un vert.
- **limite (y)** — réglages `.claude/settings*.json` non protégés (Willy, AskUserQuestion session principale, 2026-10-01, Q-G6 = b) : un `Write` qui retire le hook de `settings.json` désarme les gates ; scripts du hook (`.claude/scripts/planning-hook.sh` et celui du canary, `check-gates-alive.sh`) protégés par G6 en scope projet (`<lab>/.claude/scripts/`, Write, Edit et NotebookEdit ; Bash reste ouvert, P45-D-10) ; scope compte (`~/.claude/scripts/`) non protégé : la racine du lab se dérive du chemin écrit et ces scripts ne sont sous aucun lab adhérent (sauf un HOME qui serait lui-même un lab adhérent), mesuré par `test-planning-hook-installed.sh`. Deux silences mesurés : (a) un lien préexistant — `.claude`, `.claude/scripts` ou le script lui-même — dont le chemin physique ne porte aucun composant `.claude`, qu'il pointe HORS du lab ou DANS le lab (par exemple `.claude` -> `cfg/`, `.claude/scripts` -> `tools/`) : la racine se dérive du chemin physique ; hors du lab, la création ou l'écriture par ce lien n'est pas gardée (comme un `.planning` lié hors du lab, limite (c)) ; dans le lab, elle est d'abord gardée (refus G6 sur copie armée), puis deux écritures par outil (un marqueur de code, puis un fichier sous `.claude/scripts/.planning/`) font du dossier physique qui porte ce `.planning` (`cfg/scripts`, `tools`) la racine retenue, non adhérente, et l'écriture suivante du script du hook passe en silence (mesuré, lot F) ; précondition : le lien préexiste — `Write` seul n'en crée pas, et `Bash`, qui le peut, reste ouvert (P45-D-10) ; (b) un dossier de projet de session différent du parent de `.planning` (lab à la racine du dépôt, session lancée dans un sous-dossier) : le `sub/.claude/scripts/` de ce sous-dossier n'est pas gardé (seul G2 avertit). Le canary de session signale un script sans constantes d'armement ; il n'empêche rien.
- **limite (z)** — faux refus sous forte charge machine, point de surveillance après l'armement : sous forte charge (observé en suites à charge 20 à 35, jamais en rejeu réel), le cœur Python peut dépasser son échéance interne de 8 s (SIGALRM, code 73, voir la limite (s)) AVANT d'avoir imprimé sa décision ; la commande enregistrée ferme alors en `deny` (raison du fail-closed). Depuis F-03 (audit de sécurité final, 2026-10-01) l'échéance est désarmée dès que le cœur imprime sa décision et à sa sortie : une décision imprimée avec le code 0 est livrée telle quelle, et le code 142 (« Alarm clock », signal tardif qui tuait le cœur après l'impression et faisait jeter la décision) n'existe plus. C'est un faux refus fail-closed d'une écriture légitime, qui se corrige en relançant l'écriture une fois la charge retombée (`Bash` reste ouvert, P45-D-10) ; ce n'est PAS une promesse contre un faux accept : le repli shell ferme dans le doute, mais ses angles morts sont déclarés ((b), (k), (m), (aa)).
- **limite (aa)** — F-01, N-01, N2-01 puis N3-01 et N3-02 (audit de sécurité final puis trois re-audits, décisions du manager vf-dev-manager, 2026-10-01 et 2026-10-02, renversables) : la CLASSE « une valeur longue que le hook ne sait pas analyser ne tait jamais les gates ». La couche shell de repli était quadratique en la longueur du chemin (23,27 s pour 40 165 octets, au-delà du `timeout` de 20 s du harnais, qui laissait alors passer). Elle ne parcourt plus une valeur de plus de 4096 caractères (PATH_MAX de Linux ; quatre fois plus d'octets au pire en UTF-8) ; la valeur est alors refusée dès qu'elle contient `.planning` ou `.claude` (casse ignorée) OU un antislash (tout échappement JSON), quel que soit le `cwd` (« chemin trop long pour etre analyse, il nomme .planning ou .claude, ou porte un echappement JSON »). Le repli cherche le nom dans l'extrait BRUT, avant tout décodage : `\u002eplanning` ou `.pl\u0061nning` y échappent, d'où la règle de l'antislash (aucun chemin légitime de plus de 4096 caractères n'en porte). Une valeur qui ne nomme rien et sans antislash est tranchée sur le `cwd` — un `cwd` adhérent refuse (« chemin trop long pour etre analyse »), un `cwd` non adhérent se tait (GATE-03 : un lab non adhérent n'est jamais refusé). Le cœur, lui, a décodé le JSON, et son traitement a été corrigé par N3-01 (re-audit 3 du 2026-10-02) : la première rédaction (N2-01) jugeait toute valeur longue sur son seul nom et laissait passer, derrière un rembourrage de 4 200 caractères, un lien dur, un lien symbolique ou l'écriture d'un juge, que l'analyse exacte refusait. Désormais une valeur de plus de 4096 caractères est lue sous DEUX formes obtenues en temps linéaire : la forme réduite lexicalement (`posixpath.normpath` : `.`, `..` et `//` retirés, sans toucher au disque) et la forme physique (une résolution qui suit les liens sur la partie existante et remonte un lien sur un `..`, comme `realpath` mais sans son coût quadratique ; elle n'interroge le disque que pour un composant dont tous les ancêtres existent, et rend la même chose que `realpath`, hors boucles de liens, sur 20 000 chemins tirés au hasard). Chaque forme qui tient sous 4096 caractères est analysée EXACTEMENT comme une valeur courte, et la valeur est refusée dès que l'UNE des deux l'est : la forme réduite ferme pour les valeurs longues le cas F2 (`ext/../..`, limite (af)), la forme physique le cas inverse (`cyc/..`). Seule une valeur qui reste trop longue après réduction est décidée dans le doute : elle nomme `.planning` ou `.claude` : refus ; sinon refus si son `cwd` (lu sous sa forme réduite) OU l'ancêtre existant de l'une de ses formes tombe dans un lab adhérent, silence sinon ; un `cwd` inanalysable refuse. Conséquence assumée, faux refus levé : une valeur longue qui se réduit vers un lab non adhérent, même en nommant `.planning`, est silencieuse (elle était refusée sur son seul nom). N3-02 : un chemin RELATIF sous un `cwd` de plus de 4096 caractères n'est plus résolu contre le `cwd` physique du processus : décision dans le doute (le `cwd` y est lu réduit lexicalement, refus s'il reste trop long) ; avec un chemin absolu ou sans chemin, un `cwd` long est remplacé par sa forme réduite (à défaut, par le `cwd` du processus). La même décision tient pour tout chemin que le cœur ne sait pas analyser (surrogate isolé, NUL, `~utilisateur`, erreur de `realpath`) : le cœur ne sort plus en code non nul. N2-03 : écart VOLONTAIRE à ce principe, borné à ce cas — un chemin non analysable (ou trop long) qui nomme `.planning` ou `.claude` est refusé même en `cwd` dev ou neutre. N2-04 : un `cwd` vide (`""`) rend le silence (aucun lab ne se déduit d'un `cwd` vide), et un chemin non analysable sans nom, en `cwd` non adhérent, tait aussi le gate ROLE-juge ; le `cwd` est fourni par le harnais, l'attaquant ne le contrôle pas. Preuve : R-DOUTE-01 à R-DOUTE-04 (dont 2 000 valeurs générées de graine 20261002 : celles que la réduction laisse trop longues sont refusées sur leur nom, les autres reçoivent exactement le verdict de leur jumeau court ; la sonde N=130000, en moins de 2 s) et R-REDUC-01 (lien dur, lien symbolique, écriture d'un juge, `..` sous un lien dans les deux sens, boucle de liens, sonde de 130 000 composantes vers un lien dur), plus un différentiel à trois versions rejoué dans la quick 261002-3rx. Résidu : la couche de repli ne réduit pas (écart déclaré, elle est plus stricte sur le nom et l'antislash) : une valeur de plus de 4096 caractères qui ne nomme NI `.planning` NI `.claude`, sans antislash, en `cwd` non adhérent, et qui traverse un lien symbolique OU un lien dur préexistant vers un actif gardé, reste silencieuse dans la couche de repli seule (cœur absent ou en panne) ; le cœur, lui, la refuse. Exploitation conditionnée à un lien que `Write` seul ne crée pas (`Bash` reste ouvert, P45-D-10). Précisions du re-audit final (tour 4, 2026-10-02, verdict SECURED) : N4-01 (basse) — un chemin RELATIF sous un `cwd` de payload de plus de 4096 caractères, réductible, qui traverse un lien non nommé, rend le silence ; le `cwd` vient du harnais, il est physique et ne porte pas de `..`, ce cas est inatteignable en pratique. N4-04 (basse) — le seuil des deux formes porte sur la valeur BRUTE : un relatif court sous un `cwd` de 4096 caractères au plus, dont la forme jointe dépasse 4096, reste jugé sous une seule forme (même classe que (af)). Le gate ROLE-juge derrière un long remplissage sans nom fait aussi partie du résidu de la couche de repli seule.
- **limite (ab)** — F-04, N-03 puis N2-02 (re-audits du 2026-10-01 et du 2026-10-02) : un chemin qui commence par `~` n'est JAMAIS lu comme relatif au `cwd`. `~` et `~/…` sont développés en HOME par les deux couches (le lanceur passe HOME au cœur en argument, le cœur ne lit pas l'environnement, R-ENV-02 ; la couche shell lit `$HOME`), avec une différence : avec HOME=`/`, la couche shell tombe dans le doute et refuse, elle est plus stricte que le cœur, qui développe `~/x` en `/x`. `~utilisateur/…`, ou un HOME absent ou non absolu, sont non analysables et tranchés dans le doute (cœur : refus s'il nomme `.planning` ou `.claude`, sinon décision sur le `cwd` ; couche shell : refus). N2-02 : un chemin RELATIF `~xxx` (nom de fichier qui commence par `~`) dans un lab adhérent est donc refusé, là où il était laissé passer avec un avertissement ; c'est un faux refus rare, le harnais donne des chemins absolus. Un chemin relatif sans `~` reste joint au `cwd` (limite (h)). La limite ne repose plus sur « l'outil `Write` exige un chemin absolu », que le `Read` du harnais contredit ; elle porte sur le développement de `~` par le harnais lui-même : mesuré pour `Read`, non mesuré de première main pour `Write`. Si `Write` traitait `~/x` comme un littéral relatif au `cwd`, le hook lirait HOME alors que l'écriture tomberait dans la poche `<cwd>/~/…`, qui n'est pas un actif du lab (écart non protégé, jamais un actif gardé).
- **limite (ac)** — F-05 : la racine d'un dispatch `Agent` ou `Task` est dérivée de `tool_input.file_path` ou `notebook_path` s'ils sont présents. Précondition : que le harnais transmette des clés inconnues à ces outils (non établi).
- **limite (ad)** — F-06 : une poche `.claude/worktrees/<nom>` non adhérente est créable par `Write` seul ; le script d'un futur worktree lancé dedans n'est pas gardé. Les actifs du lab englobant restent gardés.
- **limite (ae)** — F-07 : seuls les outils du matcher (`Write`, `Edit`, `NotebookEdit`, `Agent`, `Task`, et depuis la Phase 46 `SubagentHandback` ; `Bash` est ouvert) sont vus. `MultiEdit`, les outils d'écriture fournis par des serveurs MCP et tout outil hors matcher échappent aux gates.
- **limite (af)** — constat F2 du recoupement du re-audit 3 (2026-10-02), préexistant, non corrigé dans cette phase : un `..` qui suit un lien symbolique est résolu PHYSIQUEMENT par le hook (le lien est remonté), alors que le harnais (Node) le réduit probablement LEXICALEMENT avant l'appel système ; les deux lectures divergent et le hook n'en juge qu'une pour une valeur d'au plus 4096 caractères. Exemple : `<lab>/src/ext/../../.planning/STATE.md` avec `ext` vers un dossier hors lab rend silence (lecture physique : hors lab), alors que la lecture lexicale vise `<lab>/.planning/STATE.md`. Pour les valeurs de plus de 4096 caractères (N3-01), les DEUX formes sont jugées et le cas est fermé dans les deux sens (R-REDUC-01). Non corrigé pour les valeurs courtes (dernier tour de correction de code de la phase) : le comportement du harnais n'est pas mesuré, et la correction consisterait à juger les deux formes de toute valeur, ce que la phase ne fait pas ; précondition : un lien préexistant (`Write` seul n'en crée pas, `Bash` reste ouvert, P45-D-10). Précision N4-04 (re-audit final, tour 4) : le seuil de 4096 caractères porte sur la valeur BRUTE ; un chemin relatif court sous un `cwd` de 4096 caractères au plus, dont la forme jointe dépasse 4096, reste jugé sous une seule forme.
- **limite (ag)** — constat F3 du recoupement du re-audit 3, préexistant, non corrigé : cœur absent ou en panne, la couche de repli ne suit pas un lien symbolique vers un FICHIER (elle normalise les composants qui sont des dossiers, par `cd -P`, jamais un lien terminal) : une écriture par un lien vers un actif gardé, hors de tout lab adhérent par son chemin, y passe. Le cœur le suit (`realpath`). Précondition : le lien préexiste.
- **limite (ah)** — constat F4 du recoupement du re-audit 3, préexistant, non corrigé : l'adhésion n'est pas lue de la même façon par le cœur (JSON analysé) et par la couche de repli (`grep` d'une ligne `"planning_version": "cycles-v1"`) : un `config.json` DÉJÀ en place dont la clé est suivie d'un saut de ligne, ou écrite avec un échappement, est adhérent pour le cœur et non adhérent pour le repli, qui se tait après une panne du cœur. G6 interdit d'écrire un tel contenu depuis F-02 (R-ADH-REPLI) ; un fichier antérieur à G6 n'est pas relu.
- **limite (ai)** — constat F5 du recoupement du re-audit 3, préexistant, non corrigé : une clé de leurre (`file_path` en double, ou une clé inconnue qui porte un chemin) combinée à une panne du cœur (un entier de 5 000 chiffres, une imbrication profonde du JSON) fait lire à la couche de repli le chemin du leurre, pas le vrai. Précondition : que le harnais transmette des clés libres dans `tool_input` (non établi). Précision (re-audit final, tour 4) : sur un `file_path` en double, le cœur lit lui aussi la première clé (`_premier_gagne`), pas seulement la couche de repli ; le harnais n'envoie pas de doublon.
- **limite (aj)** — constat F6 du recoupement du re-audit 3, préexistant, non corrigé : sur `NotebookEdit`, un `file_path` de leurre accompagné d'un `notebook_path` réel passe : les deux couches lisent `file_path` d'abord, puis `notebook_path`. Précondition : que le harnais transmette `file_path` à `NotebookEdit` (non établi), même précondition que la limite (ac).
- **limite (ak)** — non évalué (re-audit 3) : Windows (noms courts 8.3, qui désignent un même fichier par deux noms) et les versions de Python antérieures à 3.14 (la réduction lexicale et la résolution physique ont été mesurées avec Python 3.14.5 sous macOS ; `posixpath.normpath` est linéaire sur toutes les versions, mais le comportement de `realpath` face aux boucles de liens a varié). Aucun test ne couvre ces plateformes. Précision (re-audit final, tour 4) : Python 3.9.6 a aussi été mesuré par l'auditeur (mêmes verdicts sur 7 cas ciblés et 32 000 chemins aléatoires) ; Linux et Windows ne sont pas évalués.
- **limite (al)** — N4-02 (moyenne, re-audit final tour 4, 2026-10-02), préexistant, non corrigé dans cette phase : sous macOS, `/.vol/<dev>/<inode>/…` atteint un actif gardé (`STATE.md`, `config.json`, `cycles/…`, ou un fichier gardé par ROLE-juge) sans nommer `.planning` ni `.claude` ; `racine_lab` remonte à `/.vol`, ne trouve aucun lab et le hook se tait, dans le cœur comme dans la couche de repli. Préconditions : connaître l'inode (`Bash`, qui reste ouvert, P45-D-10, par `stat` ou `ls -i`) et que le harnais accepte un chemin `/.vol` en `Write` (non mesuré). Correctif possible, non fait dans la phase : traiter `/.vol/` comme non analysable.
- **limite (am)** — N4-03 (basse, re-audit final tour 4) : quand les deux formes d'une valeur longue (réduite et physique) diffèrent et tombent dans le même lab adhérent, la première évaluation consomme la dérogation et la seconde refuse. La dérogation est brûlée et l'écriture refusée : le comportement est fail-closed, jamais un contournement.
- **limite (an)** — N4-05 (basse, re-audit final tour 4) : une course entre `lstat` et `readlink` dans `resoudre_lineaire` lève `OSError`, et la décision dans le doute ne reçoit alors pas les ancêtres. Silence seulement si la valeur ne nomme rien, que le `cwd` n'est pas adhérent et qu'une exécution concurrente gagne la course (lien préexistant, `Bash` ouvert).
- **limite (ao)** — P46-D-08 (Phase 46, 46-04) : la racine d'un `CwdChanged` est lue dans `cwd` ; `new_cwd`, que le harnais devrait porter égal à `cwd`, n'est pas lu (non mesuré : aucune sonde en direct de la version 2.1.288 n'a été permise, P46-D-08) ; si les deux divergeaient, la racine jugée serait celle de `cwd`, comme pour le pré-filtre qui lit le même champ.
- **limite (ap)** — P46-D-10, P46-D-10a (Phase 46, 46-04) : en mode dégradé (script ou `python3` absent) dans un lab adhérent, `SubagentHandback` est refusé pour tout sous-agent, juges compris (fail-closed voulu : la couche shell ne dérive aucun rôle), et les quatre autres événements restent muets, `SubagentStop` compris (fail-open : sans rôle dérivable, un blocage statique arrêterait chaque sous-agent huit fois de suite). **Conséquence : hors mode auto et en mode dégradé, G4′ est ouvert** (hors mode auto, `SubagentHandback` n'est pas l'événement porteur : seul le repli `SubagentStop` porte G4′, et il sort sans refus) ; décision du manager P46-D-10a, renversable, listée au checkpoint d'armement de l'étape 6 (46-12).
- **limite (aq)** — Phase 46, 46-04 : un événement que le hook ne connaît pas (`hook_event_name` inconnu, d'une autre casse, vide ou qui n'est pas une chaîne) sort en silence, code 0, sans rien évaluer ni journaliser ; seule une clé absente est lue comme `PreToolUse` (compatibilité des payloads d'avant la 46).
- **limite (ar)** — P46-D-01 (Phase 46, 46-05) : `CLOTURE.md` et `SUMMARY.md` restent écrivables par `Bash` (limite (g) : le hook ne voit pas les écritures par `Bash`) ; le recalcul les voit (R4, règle E) et D1 les trace.
- **limite (as)** — P46-D-12 (Phase 46, 46-05) : G3 refuse sur un `PLAN.md` absent ou illisible (refus conforme au modèle : l'unité est `indéterminé`, R1 et R2) ; c'est un écart assumé avec G1, qui se tait sur un état illisible (F5) ; le rejeu le mesure comme « refus conforme au modèle ».
- **limite (at)** — P46-D-03a (Phase 46, 46-01) : les noms `.DS_Store`, `Thumbs.db` et `desktop.ini` sont exclus du prédicat « livrable présent » et de l'empreinte des livrables (métadonnées de système fixes : un dossier rouvert dans le Finder ne périme pas un verdict).
- **limite (au)** — P46-D-02a (Phase 46, 46-06) : G4′ « bloque le silence, pas la falsification » (spec §5) : une sortie de commande inventée, collée dans un bloc conforme, passe ; le prédicat est structurel, il ne rejoue ni ne vérifie la commande. La preuve de fond reste celle du juge (G4) et du recalcul.
- **limite (av)** — P46-D-02b (Phase 46, 46-06 ; Willy, AskUserQuestion session principale, 2026-10-03, Q9 = a) : G4′ ne vise que les workers et producteurs qui ont `Bash` ; un agent dont `tools:` ne nomme pas `Bash` (ou dont `disallowedTools` le retire), un juge, un manager, un agent inconnu, ambigu ou illisible n'est pas jugé : pour un agent sans `Bash`, le verdict du juge (G4) tient la preuve. Un agent sans champ `tools:` hérite des outils de la session, `Bash` compris, et reste dans le périmètre (c'est la lecture du champ, non une hypothèse).
- **limite (aw)** — P46-D-02, P46-D-08, P46-D-10 (Phase 46, 46-06) : un fork en mode auto n'est vu ni par `SubagentHandback` ni par `SubagentStop` ; le `permission_mode` de `SubagentStop` est supposé valoir `auto` quand `SubagentHandback` était fourni (A4, non mesuré : aucune sonde en direct n'a été permise, P46-D-08) ; aucun plafond natif n'est documenté pour un refus `PreToolUse` répété (A6) : la boucle d'un agent qui ne pourrait pas produire de sortie est évitée par le périmètre aux agents dotés de `Bash` et par la dérogation nominative.
- **limite (ax)** — P46-D-07a, P46-D-08 (Phase 46, 46-07) : #95440 — après n'importe quel `cd` dans la session, le harnais ne déclenche plus `FileChanged`, ni pour un `matcher` ni pour un `watchPaths` renvoyé par `CwdChanged`, et rien ne l'annonce (issue ouverte, non mesurée sur la version 2.1.288 : aucune sonde en direct n'a été permise, P46-D-08) ; D1 est alors sourd en séance, et la réconciliation par hash du `SessionStart` suivant le rattrape.
- **limite (ay)** — P46-D-07a (Phase 46, 46-07) : le payload de `FileChanged` ne porte aucun auteur (ni pid, ni outil) : D1 ne sait pas qui a écrit. Une ligne `intention` (écriture par outil que le hook a laissée passer) explique UN changement du chemin, jamais deux ; une écriture par `Bash` qui tombe dans le même intervalle qu'une intention d'outil sur le même chemin est donc masquée par elle (au plus une écriture masquée par intention). D1 trace, il n'attribue pas.
- **limite (az)** — P46-D-07a, P46-D-08 (Phase 46, 46-07) : `watchPaths` **remplace** la liste dynamique du harnais : un autre hook qui en renvoie la remplace, et la liste de D1 disparaît pour la session ; la forme de `watchPaths` hors `SessionStart` (A2 : `CwdChanged` renvoie les deux formes, premier niveau et sous `hookSpecificOutput`, sans mesure) et la surveillance d'un chemin encore inexistant (A3 : `SUMMARY.md` absent, créé plus tard) ne sont pas mesurées ; la réconciliation du `SessionStart` rattrape ce que le watcher ne voit pas.
- **limite (ba)** — P46-D-07, P46-D-10 (Phase 46, 46-07) : la première observation d'un fichier surveillé pose sa référence sans contournement (un fichier déjà modifié avant le premier `SessionStart` d'un lab n'est pas tracé) ; le journal est lu sur ses 4 Mio de fin (`BORNE_LECTURE_SURVEILLANCE`) : une référence plus ancienne est inconnue et se repose en première observation ; D1 est fail-open (toute erreur sort en silence, code 0) : une trace perdue en séance est rattrapée au `SessionStart` suivant.
- **limite (bb)** — P46-D-06, P46-D-13 (Phase 46, 46-09) : aucun dispatch de juge en Phase 46 — le premier passage d'un juge sur sa sortie piégée est une étape écrite du premier cycle, portée par le manager jusqu'à l'orchestrateur générique de la Phase 48 ; les sorties piégées sont fabriquées par l'initialisation en Phase 50 (à la main sinon) : « juge sans preuve » est donc attendu sur tout lab existant, et ce n'est jamais vert ; la qualité d'une sortie piégée (trop facile à refuser) relève de la Phase 50 ; le seuil de juge n'est ni lu ni posé dans `config.json` (P46-D-13, Phase 50).
- **limite (be)** — A11 (Phase 46, fix-46-a) : G3, G4 et G2 ne lisent pas plus de 1 Mio d'un `PLAN.md` (`BORNE_LECTURE_PLAN`, 1 048 576 octets LUS, jamais la taille annoncée) : au-delà, le `PLAN.md` est tenu pour illisible, la clôture et le `SUMMARY.md` sont refusés par un message qui nomme la borne, et G2 (fail-open, spec §5.1) ignore ce plan comme tout `PLAN.md` au frontmatter illisible (`lire_frontmatter_fichier(chemin, borne)` : `invalide:hors-borne`) ; le recalcul et `poser-verdict.sh` le lisent sans cette borne (le recalcul peut rendre un état, la commande poser un verdict, là où le hook refuse : un refus de plus, jamais un passage).
- **limite (bf)** — A1 (Phase 46, fix-46-a ; tour 2, A1-readdir) : la normalisation NFC porte sur les composants SOUS la racine du lab, jamais sur la racine (préfixe tel que la résolution physique le rend) ; les noms LUS par énumération de dossiers (readdir : `_sous_dossiers` pour D1 et G2, `_verdicts_du_planning` pour G5) passent en NFC avant leur test de forme, le nom du disque construisant seul le chemin d'accès ; sur APFS et HFS+, insensibles à la normalisation, les formes NFC et NFD d'un nom désignent le même dossier, et une unité au nom de disque NFD est vue de D1 (liste surveillée, rang `cle_recence` sur la forme NFC, clés du journal en NFC) et de G2 (plans ouverts) comme son jumeau NFC ; sur un système sensible à la normalisation (ext4), G1, G3 et G4 lisent l'unité sous sa forme NFC : une unité dont le nom de disque n'est pas en NFC (le recalcul la range « Hors modèle », sauf un nom qui reste conforme à `NOM_UNITE` une fois décomposé — jamo hangûl, idéogrammes de compatibilité CJK) y est lue absente, d'où un refus de G1, G3 ou G4, jamais un passage, tandis que D1 la surveille et que G2 lit son plan par son nom de disque (la détection la voit, les gates la refusent) ; une jumelle NFC posée à côté serait lue à sa place par G1, G3 et G4, le recalcul gardant la vue du disque ; deux dossiers jumeaux NFC et NFD (possibles sur ext4 seulement) sont deux unités pour D1 et G2 mais partagent la même clé du journal de D1 (contournements tracés à tort, jamais un refus ; raisonné sur le code, non mesuré : APFS refuse les deux formes côte à côte).
- **limite (bg)** — D1 (Phase 46, fix-46-a ; critère et plafond : choix du planificateur du quick 261006-23m, renversables) : la liste surveillée garde les unités non closes les plus récentes d'abord — ordre DÉCLARÉ par le nom (préfixe numérique décroissant comparé comme un entier, puis le nom), jamais par une date du disque — et se tronque à `BORNE_WATCHPATHS` chemins ; la réconciliation ne hache pas au-delà de `BORNE_OCTETS_RECONCILIATION` octets cumulés (256 Mio) ni un fichier de plus de 128 Mio : un fichier écarté n'est ni surveillé en séance (s'il est hors liste) ni réconcilié ; la borne est tracée (`genre=borne`, `sha256` = empreinte de la liste) et le signal ne la répète pas tant que la liste tronquée ne change pas.
- **limite (bh)** — P46-D-06a (Phase 46, fix-46-a, revue P4) : le `VERDICT.md` d'un juge n'est protégé par G5 que contre l'écriture par OUTIL : un agent qui a `Bash` peut écrire sous `.planning/juges/<juge>/` un verdict qui porte le `hash` de la sortie piégée et le critère visé en `échec`, et le vérificateur range alors le juge « prouvé » ; D1 ne surveille pas `.planning/juges/` (hors de la liste surveillée) : cette écriture n'est ni tracée ni signalée (mesuré par sonde, quick 261006-23m : juge compté prouvé, aucune ligne du journal de D1, aucun chemin de `.planning/juges/` dans `watchPaths`).
- **limite (bi)** — P46-D-11 (Phase 46, fix-46-a, audit A15) : le canary de session (`CANARIS`) rejoue `PreToolUse` (dont `SubagentHandback`), `SubagentStop` et `FileChanged` ; il ne rejoue ni `SessionStart` (liste surveillée et réconciliation de D1), ni `CwdChanged`, ni le vérificateur de juges (`verifier_juges`) — il vérifie seulement que la commande de référence est câblée sous les cinq événements : leur panne n'est pas signalée au démarrage de session ; seules les suites (`test-d1-surveillance.sh`, `test-juges-canary.sh`) la voient.
- **limite (bj)** — A11, classe (Phase 46, fix-46-a tour 2) : toute lecture par le hook d'un fichier du lab que l'agent contrôle est bornée — `BORNE_LECTURE_FICHIER` (1 048 576 octets LUS, jamais la taille annoncée, défaut de `lire_octets_bornes` et de `lire_frontmatter_fichier`) pour `CADRAGE.md`, `VERDICT.md` (G4 et vérificateur de juges), `config.json` (adhésion et G6) et le journal des dérogations ; `BORNE_LECTURE_PLAN` pour `PLAN.md` (limite (be)) ; `BORNE_OCTETS_LIVRABLES` octets lus pour les livrables et les fichiers surveillés de D1 ; fenêtre de fin pour le journal de D1 (limite (ba)). Au-delà : G1 refuse la planification — un `CADRAGE.md` hors borne n'est pas l'état indéterminé de F5 (limite (j)), le recalcul le lit : un refus de plus, jamais un passage —, G4 refuse le `SUMMARY.md`, le vérificateur range le juge sans preuve (`verdict-hors-borne`), un `config.json` hors borne rend l'adhésion indéterminée — `PreToolUse` sort en code 3 et la couche de repli tranche par son `grep` (refus dans un lab qu'il dit adhérent, silence dans un lab dev et sur `Bash` ; ce `grep` lit le fichier entier, et un `config.json` invisible au `grep`, limite (ah), s'y tait), les autres événements se taisent —, aucune dérogation n'est lue (le refus est maintenu), D1 ne réconcilie pas le fichier ; le recalcul et `poser-verdict.sh` lisent sans ces bornes (limite (be)), à une seule exception : le journal des dérogations — `derogation_active`, `consommer` et `BORNE_LECTURE_FICHIER` sont le même code, copie ast-identique, chez le hook central et chez `poser-verdict.sh` (R-EMP-04, R-PLAF-04), de sorte qu'un journal de plus de 1 Mio ne porte plus la dérogation `PLAFOND` : le plafond de trois tentatives est maintenu (code 65, `VERDICT.md` et journal inchangés), un refus de plus, jamais un passage (R-PLAF-05) ; `recalc-planning.sh` et `deroger-gate.sh` ne portent pas ce code (seulement `_jeton_journal`, inchangé) ; le fichier de transport du payload (`lire_payload`) n'est pas borné : ce n'est pas un fichier du lab, et le borner changerait un refus (point remonté au manager, quick 261006-638).

### Contrat de sortie par événement (Phase 46)

Depuis la Phase 46 (P46-D-09, P46-D-10) la MÊME commande enregistrée, au texte identique octet pour octet, est câblée sous **cinq
événements** ; le champ `hook_event_name` du payload aiguille le cœur, qui traite chaque événement par son mode. L'événement de
mise à jour de tâche n'est pas câblé (P46-D-01). Chaque décision citée porte le préfixe `P46-D-NN` (`46-CONTEXT.md`).

- **`PreToolUse`** — un seul groupe, matcher `Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback` (jamais un second groupe
  qui citerait `planning-hook.sh` : la purge de `merge-hooks.sh` retire toute entrée citant le même script dans les groupes du même
  événement). Mode : les gates G1 à G7 et le rôle, inchangés, plus G3 (`CLOTURE.md` d'une unité) et G4 (`SUMMARY.md` d'une unité), Phase 46, 46-05 ; `SubagentHandback`
  (le rapport d'un sous-agent, `tool_input.message`, fourni en mode auto seulement) est jugé par G4′ (Phase 46, 46-06). Refus : JSON `permissionDecision: "deny"`, code 0. Erreur interne dans le
  périmètre adhérent : `deny` (fail-closed, P45-D-08).
- **`SubagentStop`** — aucun matcher. Mode : repli de G4′ hors mode auto (`permission_mode` différent de `auto` ; en mode auto, aucune
  évaluation : le rapport a déjà passé le `PreToolUse` de `SubagentHandback`), qui juge `last_assistant_message` par le même prédicat. Blocage : JSON
  `decision: "block"` avec `reason`, code 0, **jamais le code 2** (#60490). Erreur interne : `block` si `ARMEMENT_G4P` vaut `armed`, ligne d'observation sinon
  (P46-D-10) ; en mode dégradé, silence, code 0 (limite (ap)).
- **`SessionStart`** — l'entrée vit dans le groupe SANS matcher (à côté du cliché de session), donc sur `startup`, `resume`, `clear`
  et `compact`. Mode : D1 (46-07) — la liste surveillée en `watchPaths` et la réconciliation par hash ; sortie
  `{"hookSpecificOutput":{"hookEventName":"SessionStart","watchPaths":[…],"additionalContext":"…"}}` (chaque clé seulement si non vide) ;
  à la source `startup` seulement, une ligne agrégée de plus dans `additionalContext` : le canary de juge (46-09, « Canary de juge » ci-dessous).
  Ne refuse jamais ; toute erreur : silence, code 0.
- **`CwdChanged`** — aucun matcher ; racine lue dans `cwd` (limite (ao)). Mode : D1 — la même liste, `watchPaths` au PREMIER niveau ET sous
  `hookSpecificOutput` (`hookEventName: "CwdChanged"` ; la forme n'est pas mesurée, limite (az)). Ne refuse jamais ; toute erreur : silence, code 0.
- **`FileChanged`** — aucun matcher (un `*` y serait un nom de fichier littéral, jamais un joker). Racine lue dans le `file_path` de
  PREMIER niveau du payload (chaîne absolue sous la borne de longueur du cœur, sinon silence). Mode : D1 — la trace ; il ne sort JAMAIS de
  `watchPaths`. Ne refuse jamais ; toute erreur : silence, code 0.

**Fail-open déclaré** des trois événements qui ne refusent jamais : une trace perdue en séance est rattrapée par la réconciliation de
D1 (P46-D-10) ; la décision dans le doute (N-01) ne vaut que pour `PreToolUse`, tout autre événement en doute sort en silence.
**Hors adhésion** (lab dev, ce dépôt compris), chaque événement et le nouvel outil du matcher traversent le pré-filtre : octet vide,
code 0, avant le lancement du script et avant tout `python3` (P46-D-16 ; R-EVT-01 et R-EVT-01b, mutants MUT-EVT-PREFILTRE et
MUT-EVT-ADHESION). **Repli shell** (script ou `python3` absent, lab adhérent) : `SubagentHandback` est refusé par un `deny` statique
dont la raison dit que le rapport du sous-agent est refusé tant que le hook central est indisponible et comment réparer ; tout autre
événement sort en code 0 sans sortie (limite (ap)). Aucun message ne porte de chemin absolu hors du lab, ni « no such file », ni
« can't open ». Le canary de session retrouve la commande de référence sous les cinq événements et signale, sans jamais bloquer, un
événement non câblé ; ses cas DEGRADE `D09` et `D10` prouvent le refus de `SubagentHandback` en mode dégradé.

### Table d'armement livrée

L'état de chaque gate vit **dans le code livré** (une constante `ARMEMENT_<gate>` par gate dans
`planning-hook.sh`), jamais dans un fichier du lab ni dans une variable d'environnement (P45-D-03a).
`observe` : le gate calcule, **journalise** ce qu'il aurait refusé, laisse passer ; `armed` : le gate
refuse (`deny`, **fermé**) ; sur erreur interne, un gate `armed` refuse et un gate `observe`
journalise. G2 avertit toujours et ne refuse jamais (**ouvert**). Armement par étapes dans un ordre
fixe (P45-D-03), une étape suivante n'étant jamais armée avant la précédente ; chaque étape exige son
canary, puis 0 faux refus et 0 faux accept sur le banc synthétique et sur le rejeu réel (P45-D-03b).

**Ordre d'évaluation.** Dans un lab adhérent, le cœur vérifie d'abord la cohérence de la table
d'armement (`armement_valide`, ordre `ORDRE_ETAPES`) : une table qui la viole (une étape armée avant
la précédente, G6 et G5 de valeurs différentes, G3 et G4 de valeurs différentes, ou une valeur autre que
`observe` et `armed`) refuse tout, c'est-à-dire chaque action que le hook examine, `Bash` compris, avant tout
gate. Sinon G2 avertit, puis les gates à verdict sont évalués dans l'ordre de `GATES_A_VERDICT` (G6, G5, G1,
G7, ROLE, G3, G4, G4P) et leurs verdicts sont tranchés ensemble par `decider`. L'ordre des étapes de `ORDRE_ETAPES`
(Phase 46, P46-D-11) est : G6 et G5, puis G1, puis G7, puis le rôle, puis G3 et G4 (étape 5, un seul geste), puis
G4′ (étape 6) ; G4′ a sa fonction d'évaluation (`evaluer_g4p`, Phase 46, 46-06) dans `GATES_A_VERDICT` et son repli
au mode `SubagentStop` : sa constante vaut `observe`.

| Gate | Étape | État | Comportement sur défaillance | Cas de canary | Relevé |
|---|---|---|---|---|---|
| G6 | 1 | armed | armé : fermé (deny) ; observe : journalise | G6-principal, G6-plugin | 45-REJEU-ETAPE-1 |
| G5 | 1 | armed | armé : fermé (deny) ; observe : journalise | G5-verdict, G5-imbrique | 45-REJEU-ETAPE-1 |
| G1 | 2 | armed | armé : fermé (deny) ; observe : journalise | G1-sans-cadrage | 45-REJEU-ETAPE-2 |
| G7 | 3 | armed | armé : fermé (deny) ; observe : journalise | G7-orphelin | 45-REJEU-ETAPE-3 |
| ROLE | 4 | armed | armé : fermé (deny) ; observe : journalise | ROLE-juge, ROLE-worker-Agent, ROLE-worker-Task | 45-REJEU-ETAPE-4 |
| G3 | 5 | observe | armé : fermé (deny) ; observe : journalise | G3-livrable-absent | 46-REJEU-ETAPE-5 |
| G4 | 5 | observe | armé : fermé (deny) ; observe : journalise | G4-sans-verdict | 46-REJEU-ETAPE-5 |
| G4P | 6 | observe | armé : fermé (deny en PreToolUse, block en SubagentStop) ; observe : journalise | G4P-handback, G4P-stop | 46-REJEU-ETAPE-6 |
| G2 | - | avertit | ouvert : n'avertit pas, ne refuse jamais | aucun | aucun |

**État d'armement livré, tel que mesuré (v2.9.0).**

- Armés à la livraison v2.9.0 : les quatre étapes (`ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7` et `ARMEMENT_ROLE` valent `armed`). `G2_MODE` vaut `avertit` : G2 avertit toujours et ne refuse jamais.
- Les rejeux réels des étapes 1 à 4 ont tous rendu 0 faux refus et 0 faux accept, avec des empreintes d'arbre identiques (relevés de phase `45-REJEU-ETAPE-1` à `45-REJEU-ETAPE-4`). Mais ils ont été mesurés sur le hook **avant** les lots de correction A, B et C.
- L'armement exigeait un NOUVEAU rejeu réel, sur des labs au repos, du hook livré après les lots de correction : il est fait (relevé de phase `45-REJEU-FINAL.md`, commit `708debcb`), avec 0 faux refus, 0 faux accept et des empreintes d'arbre identiques pour les deux labs. L'arbitrage qui attendait pour adapter deux suites couplées à « tout en observe » est rendu et appliqué (Q-ARM, Willy, AskUserQuestion session principale, 2026-09-30, oui pour les quatre étapes d'armement) : les suites ne dépendent plus de l'état d'armement, seuls la table de cette référence et `TABLE_ATTENDUE` le suivent. La protection des scripts du hook par G6 est elle aussi tranchée et appliquée (Q-G6 = b, Willy, AskUserQuestion session principale, 2026-10-01, limite (y)).
- L'armement se fait par étapes dans l'ordre fixe (P45-D-03), un commit par étape : cet état est celui de l'étape 4, la dernière de la Phase 45. Ce document ne dit jamais qu'un gate est armé tant que sa constante vaut `observe`.
- Phase 46 (46-05) : G3 et G4 (étape 5) et G4′ (étape 6) sont livrés en `observe` (`ARMEMENT_G3`, `ARMEMENT_G4` et `ARMEMENT_G4P` valent `observe`) ; l'armement réel de l'étape 5 puis de l'étape 6 est un commit de constantes distinct, après canary vert et 0 faux refus, 0 faux accept (P46-D-11). Les relevés attendus sont `46-REJEU-ETAPE-5` et `46-REJEU-ETAPE-6` (ceux des étapes 1 à 4 restent `45-REJEU-ETAPE-<n>`). Dans la colonne des cas de canary, `aucun` n'est admis que pour G2 et pour un gate en `observe` qui n'a pas encore de cas dans `CANARIS` ; un gate armé sans cas reste un écart.

Cinq listes que R-REFERENCE compare au code, chacune sur une seule ligne :

- **Noms protégés par G6** : `STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`, `surveillance.log`, `config.json`.
- **Scripts du hook protégés par G6** : `planning-hook.sh`, `check-gates-alive.sh`.
- **Journal de dérogation** : `derogations-gates.log`.
- **Marqueurs de projet de code (G7)** : `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `build.gradle`, `build.gradle.kts`, `composer.json`, `Gemfile`, `tsconfig.json`, `Package.swift`, `*.xcodeproj`.
- **Ordre de résolution des agents (P45-D-05b)** : lab, compte, plugin

### G2 — avertit, ne refuse jamais (GATE-08)

Sur une écriture (`Write`, `Edit`, `NotebookEdit`) ou une commande `Bash` qui vise un chemin du lab
adhérent hors de `.planning/` et de `.claude/` et hors du `ecrit:` de tout plan ouvert, G2 ajoute un
`additionalContext` (jamais un `permissionDecision`) ; il est fail-open (spec §5.1). Le
référentiel est l'**union** des `ecrit:` des plans ouverts, pour tout écrivain, fil principal compris ;
un plan clos ou dérogé ne couvre rien ; un frontmatter illisible fait ignorer le plan, comme un `PLAN.md` de
plus de 1 Mio (`BORNE_LECTURE_PLAN`, lecture bornée : jamais plus de 1 048 577 octets lus, A11). Les plans ouverts sont trouvés par readdir et le nom
d'unité est testé sous sa forme NFC : une unité dont le nom de disque est en NFD couvre ses livrables comme sa jumelle NFC (A1-readdir). Pour Bash, un
jeton de la commande n'est retenu que s'il ressemble à un chemin du lab. **Bash n'est pas couvert par
les refus** : G2 sur Bash est une **détection**, jamais une promesse (P45-D-10), et le message le dit.

### G6 — les fichiers générés (GATE-04)

G6 refuse toute écriture par outil (`Write`, `Edit`, `NotebookEdit`), quel que soit le rôle, d'un nom
protégé (ci-dessus) enfant direct du dossier de planning d'un lab adhérent ; les `STATE.md` de
`workstreams/` et `compartments/` ne sont pas visés. L'**identité** prime sur la chaîne : une cible
existante est comparée par identité de fichier (lien dur, casse du disque, alias du dossier), une
création par le dossier parent résolu et le nom en casefold. `config.json` n'est protégé que pour
l'**adhésion** (F6 = f6-oui, Willy, AskUserQuestion session principale, 2026-09-30) : une écriture qui
change ou retire `planning_version` est refusée, les autres clés restent libres ; le cache du recalcul
l'est aussi (F7b = f7b-oui, même canal, même date), et le journal de dérogation (F7a = f7a-racine,
même canal, même date) ; le journal de D1, `surveillance.log` (Phase 46, 46-07, P46-D-07a), l'est aussi : il est inscrit par le
moteur et le hook, jamais rédigé. Le motif d'un refus nomme `recalc-planning.sh` (ou `deroger-gate.sh`) : le
`Stop` de la 44 invite à mettre à jour l'état, le refus ne le contredit pas. G6 est un refus de
l'outil, pas du disque : `Bash` et `recalc-planning.sh` écrivent ces fichiers (P45-D-10).

### G5 — le verdict par commande (GATE-05)

G5 refuse toute écriture par outil d'un fichier nommé `VERDICT.md` (casse ignorée) sous le `.planning/`
d'un lab adhérent, quel que soit le rôle ; un lien dur vers un verdict est ce verdict ; un `VERDICT.md`
hors de `.planning/` n'est pas visé. Le motif nomme `poser-verdict.sh`. La recherche d'un lien dur
parcourt au plus 20 000 fichiers du `.planning/` (`BORNE_PARCOURS_VERDICTS`) : au-delà, un verdict
non encore vu n'est pas reconnu par ce lien.

### G1 — pas de plan sans cadrage (GATE-06)

G1 refuse l'écriture (`Write`, `Edit`) d'un `PLAN.md` de forme modèle — direct sous la phase, ou
`plans/<plan>/PLAN.md` — dans une phase sans `CADRAGE.md`, ou dont le registre porte une ligne
structurante sans statut (le refus cite les identifiants ouverts). Il lit l'état que le modèle dérive
par des copies ast-identiques du parseur de frontmatter et du registre, contrôlées phase par phase
contre le vrai `recalc-planning.sh --read-only` (CROISE-G1). La valeur d'un statut n'est jamais jugée.
Un `PLAN.md` du socle v2 ou sous un nom d'unité invalide n'est jamais visé. Bord : limite (j). Un `CADRAGE.md` de plus de 1 Mio
(`BORNE_LECTURE_FICHIER`, A11-classe) n'est pas l'état indéterminé de F5 (le recalcul le lit) : il est **refusé** par un message qui nomme la borne
(`le CADRAGE.md de la phase <phase> dépasse 1048576 octets (BORNE_LECTURE_FICHIER) : non lu`), limite (bj).

### G7 — pas de planning orphelin (GATE-07)

G7 refuse la **création**, par `Write` ou `NotebookEdit`, d'un dossier `.planning/` dans un dossier X
sous un lab adhérent, sauf si X porte un marqueur de projet de code (la liste ci-dessus, tenue égale à
celle de `detect-gsd-engine.sh` par un contrôle qui extrait le texte du détecteur) ou un `.claude/`
**habité**. Prédicat littéral de « habité » (P45-D-14, F4 = f4-litteral) : au moins un fichier
**régulier** `X/.claude/agents/*.md` ET au moins un fichier **régulier** sous `X/.claude/memory/` (lstat :
jamais un lien, jamais un dossier). Un `.claude/` qui ne porte pas les deux — un `agent-memory/` sans
fichier, des agents sans mémoire, une mémoire sans agent, un dossier vide — n'est pas habité. Le
parcours de la mémoire est borné à 20 000 fichiers (`BORNE_PARCOURS_HABITE`) : au-delà de la borne le
prédicat est indéterminé et G7 ne refuse pas.
La table D-05 de la spec est corrigée en conséquence (P45-D-14a, Willy, AskUserQuestion session
principale, 2026-09-29) : un dossier dont le `.claude/` n'a ni agent ni mémoire non vide n'est pas un
lab. La création d'un `.planning/` par Bash n'est pas couverte (P45-D-10).

Limite T-45-61 (acceptée, sévérité basse) : un `.claude/` garni d'un faux agent et d'un fichier de mémoire passe G7 ; G7 rend visible un planning nu, il ne certifie pas un lab.

### G3 — pas de clôture sans livrable (Phase 46)

G3 refuse, en `PreToolUse`, l'écriture par `Write`, `Edit` ou `NotebookEdit` d'un `CLOTURE.md` d'**unité de forme modèle**
(`.planning/cycles/<cycle>/phases/<phase>[/plans/<plan>]/CLOTURE.md`, noms d'unité conformes à `NOM_UNITE`, noms fixes comparés
sans égard à la casse, chemin résolu physiquement) quand un livrable déclaré par `ecrit:` du `PLAN.md` voisin est absent, vide,
lien ou hors borne, ou quand ce `PLAN.md` est absent, illisible, de plus de 1 Mio (`BORNE_LECTURE_PLAN`, 1 048 576 octets lus,
jamais la taille annoncée : A11, fix-46-a) ou sans `ecrit:` valide (P46-D-01, P46-D-12). Il appelle la MÊME
chaîne que la règle R4 du recalcul (`entrees_du_plan`, puis `livrables_presents`, budget commun par `PLAN.md`) : G3 refuse
exactement quand R4 rend `indéterminé` pour la même unité (preuve croisée R-CROISE-01, 46-05). Un `CLOTURE.md` de toute autre
forme (planning de style GSD sous `.planning/phases/`, niveau cycle, `CLOTURE.md.bak`, un livrable nommé `CLOTURE.md` hors de
`.planning/`) n'est jamais jugé. Le verdict porte le chemin relatif du `CLOTURE.md` écrit : c'est le chemin d'une dérogation
nominative (`deroger-gate.sh --gate=G3`, usage unique). Messages, relatifs au lab : `livrable déclaré <statut> : <entrée> —
produisez-le (non vide, sans lien) avant de clore (spec §5)` (le statut est `absent`, `vide`, `lien` ou `illisible` : le livrable est à
produire ou à corriger) ; `livrable déclaré hors borne : <entrée> — <libellé de la borne> (budget commun aux entrées ecrit: du
PLAN.md) : la clôture ne peut pas être vérifiée au-delà de cette borne, qui ne se lève pas — allégez le livrable ou découpez l'unité
(spec §5)` (A13, fix-46-a : le libellé nomme la borne franchie, `BORNE_FICHIERS_LIVRABLES` ou `BORNE_OCTETS_LIVRABLES`, et le message
ne demande plus de « produire » un livrable qui existe) ; `PLAN.md de l'unité absent, illisible ou sans ecrit: valide —
l'unité est indéterminée au modèle, la clôture est refusée` ; `PLAN.md de l'unité au-delà de 1048576 octets (BORNE_LECTURE_PLAN) :
non lu — l'unité est indéterminée au hook, la clôture est refusée`. Entré en `PreToolUse` par l'entonnoir existant : en `observe` il
journalise, armé il refuse (deny), une erreur interne refuse quand il est armé.

### G4 — pas de SUMMARY.md sans verdict qui tienne (Phase 46)

G4 refuse, en `PreToolUse`, l'écriture par `Write`, `Edit` ou `NotebookEdit` d'un `SUMMARY.md` d'**unité de forme modèle** (même
forme que G3, même résolution du chemin) quand le `VERDICT.md` voisin est **absent**, **invalide** (règle R6 : constats vides ou
hors `passé`/`échec`, frontmatter illisible), **périmé** — `hash` différent du sha256 du `PLAN.md`, ou `hash_livrables` absent ou
différent de l'empreinte des livrables, relue par la copie partagée du bloc — ou **portant un constat `échec`** (P46-D-01,
P46-D-03). Ordre du recalcul : R6, puis E (empreintes), puis R7 (échec) : un verdict périmé se re-juge avant qu'on lise ses
constats. Le prédicat est réévalué à **chaque** écriture : retoucher le `SUMMARY.md` d'une unité close reste permis tant que le
verdict tient. Un `PLAN.md` absent, illisible, de plus de 1 Mio (`BORNE_LECTURE_PLAN`, A11), sans `ecrit:` valide ou dont `ecrit:`
contient l'unité rend l'unité indéterminée au modèle : refus. Un `SUMMARY.md` de toute autre forme n'est jamais jugé. Le verdict porte le chemin relatif du `SUMMARY.md` écrit
(dérogation nominative : `deroger-gate.sh --gate=G4`, usage unique). Messages, relatifs au lab : `aucun VERDICT.md : faites juger
l'unité (poser-verdict.sh)` ; `VERDICT.md invalide (règle R6)` ; `constat en échec : <critère> — corrigez puis re-jugez
(tentative n+1)` ; `verdict périmé : re-juger (tentative n+1)` (n lu dans `tentative` du verdict, sans numéro si elle est
illisible) ; `livrables hors borne : <libellé>` ; `PLAN.md de l'unité au-delà de 1048576 octets (BORNE_LECTURE_PLAN) : non lu — le
verdict ne peut pas être vérifié` ; `VERDICT.md de l'unité au-delà de 1048576 octets (BORNE_LECTURE_FICHIER) : non lu — le verdict ne peut pas être
vérifié, faites re-juger l'unité (poser-verdict.sh)` (un `VERDICT.md` de plus de 1 Mio refuse aussi : A11-classe, limite (bj)). Entonnoir existant : en `observe` il journalise, armé il refuse (deny), une erreur
interne refuse quand il est armé.

### G4′ — pas de rapport sans sortie brute (Phase 46)

G4′ juge le **rapport** d'un sous-agent là où il est rendu : au `PreToolUse` de `SubagentHandback` (le rapport est
`tool_input.message`, une chaîne seulement ; tout autre type, ou son absence, n'est aucune preuve), et, **hors mode auto**
(`permission_mode` différent de `auto`), au repli `SubagentStop` (`last_assistant_message`, même prédicat). En mode auto,
`SubagentStop` n'évalue rien : le rapport a déjà passé le `PreToolUse`, et un second jugement refuserait deux fois le même
rapport. Un rapport sans sortie de commande brute reçoit le verdict `G4P` (P46-D-02).

**Grammaire de la sortie de commande brute** (fonction `sortie_brute_presente`, P46-D-02a, jamais plus permissive que celle-ci).
Le rapport contient au moins UN bloc de code délimité qui remplit toutes ces conditions : (1) **ouverture** : une ligne dont le
texte, blancs de tête retirés, commence par trois caractères ``` ou ~~~ (ou plus), une étiquette de langage étant admise
après (pour ```, l'étiquette ne porte pas d'accent grave) ; (2) **fermeture** : une ligne faite du même caractère, au moins aussi
longue que l'ouverture, blancs autour admis — un bloc non fermé ne compte pas, et une ligne d'un autre caractère ou plus courte
n'est pas une fermeture ; (3) la **première ligne non vide** du bloc commence par `$ ` suivi d'un caractère non blanc ; (4) la
**ligne non vide suivante**, dans le bloc, existe et n'est ni une fermeture ni une ligne `$ ` (c'est la sortie). Les lignes vides
sont ignorées ; un seul bloc conforme suffit. Le parcours est linéaire, ligne à ligne, sans aucune expression à retour arrière : la
taille du rapport n'est bornée que par l'échéance du cœur.

**Périmètre.** Un sous-agent de rôle **worker** ou **producteur** d'un lab adhérent, rôle dérivé comme pour le hook par rôle
(même `resoudre_agent`), **qui a `Bash`**. Exclus : les juges, les managers, le fil principal (`agent_id` ou `agent_type` absent ou
vide), l'agent inconnu, ambigu ou illisible, et un agent sans `Bash`. La **capacité** se lit dans la définition : `tools:` absent
(l'agent hérite des outils de la session, `Bash` compris : il reste dans le périmètre), ou `tools:` qui nomme `Bash` ou une forme
`Bash(…)`, et `Bash` absent de `disallowedTools` ; une allowlist illisible exclut l'agent. Motif (P46-D-02b ; Willy,
AskUserQuestion session principale, 2026-10-03, Q9 = a) : sans `Bash`, aucune sortie de commande brute n'est possible, le refus ne
pourrait pas être levé ; le verdict du juge (G4) tient alors la preuve (limite (av)).

**Entonnoir et message.** Par `decider`, comme les autres gates : en `observe` il journalise (une ligne `gate=G4P`, chemin
`agents/<agent_type>`), armé il refuse (`deny` en `PreToolUse`, `decision: "block"` en code 0 en `SubagentStop`, jamais le code 2),
une erreur interne refuse quand il est armé (`block` en `SubagentStop` aussi, P46-D-10) et se journalise en `observe`. Dérogation
nominative `G4P` sur le chemin `agents/<agent_type>`, à usage unique (`deroger-gate.sh --gate=G4P --chemin=agents/<agent_type>`).
Message : `[planning-core] G4P : rapport de <agent_type> sans sortie de commande brute — rejouez la commande qui prouve le travail
et collez-la avec sa sortie dans un bloc (première ligne « $ <commande> », puis la sortie) ; dérogation nominative : deroger-gate.sh
--gate=G4P --chemin=agents/<agent_type>`. Le gate « bloque le silence, pas la falsification » (limite (au)). Cas de canary :
`G4P-handback` et `G4P-stop`, rejoués sur un producteur synthétique doté de `Bash` (`canary-producteur`). Limites : (au), (av), (aw).

### D1 — écritures surveillées (Phase 46)

D1 est la **détection** des écritures sur les fichiers que le moteur tient pour siens : toute écriture sur un fichier surveillé d'un lab
adhérent est **expliquée** par le moteur, ou **tracée comme contournement**. Elle ne refuse jamais (P46-D-07 ; Willy, AskUserQuestion
session principale, 2026-10-03, Q7 = b) et n'a pas de constante d'armement : une détection ne s'arme pas (P46-D-11).

**Liste surveillée** (P46-D-07a). Fichier par fichier, jamais un dossier (#91634 : un `watchPaths` pointé sur un dossier est enregistré
récursivement et a bloqué le fil principal de 20 à 45 s sur 137 000 fichiers), chemins absolus, **au plus 128** (`BORNE_WATCHPATHS`) :
`STATE.md`, `INDEX.md`, `cloture.log`, le journal de dérogation et `config.json` à la racine du dossier de planning, puis `PLAN.md`,
`CLOTURE.md`, `VERDICT.md` et `SUMMARY.md` de chaque **unité de forme modèle dont `SUMMARY.md` est absent** (approximation déterministe
d'« unité non close », sans recalcul : une unité close voit ses écarts par la règle E du recalcul ; `SUMMARY.md` encore absent est dans la
liste, pour voir sa création). Les unités sont parcourues **la plus récente d'abord** (D1, fix-46-a ; critère : choix du planificateur du quick
261006-23m, renversable) : cycles, puis phases de chaque cycle, par `cle_recence` décroissante — le préfixe numérique du nom comparé comme un
entier (longueur des chiffres significatifs, puis les chiffres), puis le nom entier en forme NFC (l'unité au nom de disque NFD a le même rang que sa
jumelle NFC) ; la phase, puis ses plans dans le même ordre. L'ordre est
**déclaré par le nom**, jamais par une date du disque. La liste se tronque donc en gardant les unités les plus récentes (l'unité active reste
surveillée) ; la troncature est tracée (une ligne `genre=borne`, `sha256` = empreinte de la liste) **et signalée** dans `additionalContext` (voir la
réconciliation). Le journal de D1 n'en fait jamais partie : un watcher sur le fichier que sa propre trace réécrit bouclerait.

**Sorties par événement.** `SessionStart` : `{"hookSpecificOutput":{"hookEventName":"SessionStart","watchPaths":[…],"additionalContext":"…"}}`
(les clés `watchPaths` et `additionalContext` ne sont présentes que si elles sont non vides) ; `CwdChanged` : la même liste, `watchPaths` au premier
niveau ET sous `{"hookSpecificOutput":{"hookEventName":"CwdChanged","watchPaths":[…]}}` (forme non mesurée, P46-D-08) ; `FileChanged` ne renvoie
jamais de `watchPaths` (P46-D-07) : il trace, stdout vide. **Hors adhésion**, rien n'est renvoyé et le watcher ne démarre pas : le coût de D1 est
**nul par construction** (aucune liste, aucun fichier lu, aucune ligne au journal), prouvé par R-D1-03 et par la mutation « adhésion ignorée ».
**Fail-open** (P46-D-10) : toute erreur d'un mode de D1 sort en silence, code 0, jamais un `deny` ni un `block` ; aucune sortie de D1 n'en contient.

**Journal.** `.planning/surveillance.log`, un seul fichier, ajout seul (`O_APPEND`, `O_NOFOLLOW`, 0600, verrou exclusif), protégé par G6 (l'écriture
par outil est refusée) et connu du recalcul (jamais « Hors modèle »). Une ligne par fait, `<horodatage ISO UTC>  genre=<g>  chemin=<jeton>
sha256=<hex|absent|->  par=<jeton>  source=<seance|reconciliation|->` (deux espaces entre champs), chaque valeur par l'encodeur injectif du journal
(un nom de fichier qui porte un saut de ligne reste UNE ligne). Genres : `reference` (dernier état connu d'un chemin), `moteur` (écriture d'un
écrivain du moteur, sha256 du fichier après écriture), `intention` (écriture par outil laissée passer par le hook), `contournement` (changement
que rien n'explique), `borne` (liste tronquée), `signal` (contournements signalés au SessionStart). La fonction qui inscrit,
`inscrire_surveillance`, est copiée ast-identique dans `planning-hook.sh`, `recalc-planning.sh`, `poser-verdict.sh` et `deroger-gate.sh` ;
toute erreur d'inscription est silencieuse (D1 est fail-open).

**Règle d'explication** (déterministe). Pour un chemin P de sha256 courant S (`absent` s'il n'existe pas, ou s'il n'est pas un fichier régulier — un lien
n'est jamais suivi) : sans ligne `reference` antérieure, la **première observation** pose la référence (P, S) sans contournement (limite (ba)) ; un S égal
à celui de la dernière référence n'est pas un changement, rien n'est inscrit ; sinon le changement est **expliqué** s'il existe, **après** la dernière
`reference` de P, une ligne `moteur` de P de sha256 S, ou une ligne `intention` de P ; expliqué, D1 ajoute une `reference` (P, S) ; non expliqué, il
ajoute une ligne `contournement` puis cette `reference`. Une intention n'explique donc qu'**un** changement (la référence qui suit la dépasse ; limite (ay)).

**Écrivains.** `recalc-planning.sh` après chaque écriture effective de `STATE.md`, `INDEX.md` et `cloture.log` (jamais en lecture seule) ;
`poser-verdict.sh` après l'écriture atomique d'un `VERDICT.md` d'unité et après la consommation d'une dérogation `PLAFOND` ; `deroger-gate.sh` après
l'ajout au journal de dérogation ; le hook central après une ligne `consommee` et, en `PreToolUse`, quand la décision **finale** laisse passer une
écriture par `Write`, `Edit` ou `NotebookEdit` sur un chemin de la liste (ligne `intention`, outil nommé, sans sha256 : le contenu n'est pas encore
écrit). Une écriture refusée n'est jamais une intention. Une erreur d'inscription ne change jamais le code de sortie de l'écrivain.

**Réconciliation au `SessionStart`.** Les empreintes des fichiers de la liste sont comparées au dernier état connu du journal (lu sur les 4 Mio de fin,
`BORNE_LECTURE_SURVEILLANCE` ; un fichier de la liste est lu une seule fois) : un changement que rien n'explique est tracé (`contournement`,
`source=reconciliation`), puis la référence est mise à jour. Les contournements tracés depuis la séance précédente — depuis la dernière ligne `signal` —
sont signalés en **une ligne** de `additionalContext`, sans jamais bloquer : `[planning-core] D1 : <n> écriture(s) non expliquée(s) de fichiers
surveillés depuis la séance précédente (<trois premiers chemins relatifs>…) — tracées dans .planning/surveillance.log` ; la ligne `signal` posée
ensuite empêche qu'un `SessionStart` sans nouveau contournement le répète. La réconciliation rattrape aussi ce que le watcher ne voit pas (limite (ax)).
**Plafond d'octets** (D1, fix-46-a) : la réconciliation ne hache pas plus de `BORNE_OCTETS_RECONCILIATION` octets cumulés (256 Mio, tailles annoncées par
`lstat`) et aucun fichier de plus de `BORNE_OCTETS_LIVRABLES` (128 Mio) ; un fichier écarté n'est pas réconcilié à ce `SessionStart` (aucune ligne) ;
l'empreinte d'un fichier est elle-même bornée en octets **lus** (`BORNE_OCTETS_LIVRABLES`), même si le fichier grandit après le `lstat` (A11-classe, limite (bj)). Coût
mesuré (sonde p13 après correction) : 0,2 s au premier comme au second `SessionStart` pour 96 fichiers creux de 127 Mio (deux seulement sont hachés), l'échéance
du cœur étant de 8 s (avant la correction : 8,1 s mesurés au départ de ce quick, 5,9 s à l'audit ; au-delà de l'échéance le `SessionStart` sort en silence, la
liste n'est pas rendue). **Signal de borne** : une borne — liste tronquée ou fichiers écartés —
est tracée par une ligne `borne` dont le `sha256` est l'empreinte de la liste surveillée et des fichiers écartés, posée seulement quand cette empreinte change ;
elle est signalée en une ligne de `additionalContext` (`[planning-core] D1 : surveillance bornée — liste surveillée tronquée à 128 chemins
(BORNE_WATCHPATHS) : … ; <n> fichier(s) surveillé(s) non réconcilié(s) au-delà de <octets> octets hachés (BORNE_OCTETS_RECONCILIATION) ou de <octets>
octets par fichier (<trois premiers chemins relatifs>) — tracé dans .planning/surveillance.log (genre=borne)`) si une ligne `borne` est arrivée depuis la
dernière ligne `signal` : même règle anti-répétition que les contournements, une troncature identique à la dernière tracée n'est pas re-signalée.

**Canary.** D1 n'a pas de constante d'armement mais a son canary : le cas `D1-trace` (catégorie `D1` de `CANARIS`) rejoue un `FileChanged` synthétique
sur un fichier surveillé du lab synthétique, d'abord sur son état initial (la référence), puis modifié hors du moteur : la commande doit se taire ET
ajouter une ligne `contournement` au journal du lab synthétique ; l'attendu est `trace`, jamais dérivé de la table d'armement. Limites : (ax) à (ba), (bg).

### Canary de juge (C-16, Phase 46)

Un juge qui laisse tout passer est le mode d'échec le plus coûteux d'un système multi-agents (spec d'initialisation §10, C-16). La Phase 46 livre
le **contrat** et le **vérificateur** du canary de juge — jamais le dispatch (Phase 48) ni la fabrication des sorties piégées (Phase 50) — et
signale, sans jamais bloquer, chaque juge qui n'a pas prouvé qu'il sait refuser (P46-D-06 ; Willy, AskUserQuestion session principale, 2026-10-03,
Q6 = a ; P46-D-06a).

**Contrat.** Un dossier par juge du lab, `.planning/juges/<juge>/` (`<juge>` : `^[a-z0-9][a-z0-9-]{0,63}$`, le nom normalisé de la définition) :
`SORTIE-PIEGEE.md` (frontmatter `juge`, `critere_vise`, `provenance` ; corps : l'**exemple raté** qui viole le critère visé, un mauvais output connu,
notion voisine du test de discrimination de `rubric-design.md`) et `VERDICT.md`, le **verdict de canary**, posé par `poser-verdict.sh
--unite=.planning/juges/<juge>` (forme de juge de 46-01 : l'artefact haché est `SORTIE-PIEGEE.md`, `hash` en est le sha256, pas de `hash_livrables`) et
protégé par **G5** comme tout verdict (l'écriture par outil d'un `VERDICT.md` est refusée, R-JUGE-08). Gabarit : `SORTIE-PIEGEE.template.md`.
`juges` est un **emplacement du modèle** à la racine de `.planning/` (jamais « Hors modèle », jamais dérivé comme une unité de cycle).

**Vérificateur** (`verifier_juges`, dans `planning-hook.sh` : une copie de moins du parseur et de l'indexation des agents). Les **juges du lab** sont les
définitions de `.claude/agents/` du lab dont le rôle dérivé est `juge` (jamais celles du compte ni d'un plugin). Trois classes, déterministes :

| Classe | Condition |
|---|---|
| **prouvé** | verdict valide (règle R6 : constats non vides, chaque résultat `passé` ou `échec`), `hash` égal au sha256 de `SORTIE-PIEGEE.md`, le critère visé porté en `échec` et seulement en `échec` |
| **laxiste** | verdict valide et à jour dont le critère visé n'est pas en `échec` : absent des constats, ou porté en `passé` ne serait-ce qu'une fois |
| **sans preuve** | tout le reste, avec un motif : `nom-hors-forme`, `dossier-absent` (ou lien), `sortie-piegee-absente`, `sortie-piegee-invalide` (lien, non régulière), `sortie-piegee-hors-borne` (plus de 1 Mio), `sortie-piegee-illisible`, `critere-vise-absent`, `verdict-absent`, `verdict-hors-borne` (plus de 1 Mio, `BORNE_LECTURE_FICHIER`), `verdict-invalide`, `verdict-perime` (la sortie piégée a changé depuis le verdict), `erreur-<type>` |

**« Juge sans preuve » n'est jamais vert** : toute erreur de lecture range le juge sans preuve, jamais prouvé. Aucun seuil de juge n'est lu ni posé dans
`config.json` (P46-D-13) ; `config.json` n'est lu que pour l'adhésion.

**Signal.** Au `SessionStart` de source `startup` d'un lab adhérent, UNE ligne agrégée dans l'`additionalContext` (le même objet que la liste surveillée de
D1), sans jamais bloquer : `[planning-core] juges (C-16) : <p> prouvé(s) ; <l> laxiste(s) : <noms> ; <s> sans preuve : <noms> — faire passer chaque juge sur
.planning/juges/<juge>/SORTIE-PIEGEE.md et poser son verdict par poser-verdict.sh --unite=.planning/juges/<juge>` — au plus trois noms par classe, suivis
du reste compté ; la marche à suivre n'est ajoutée que s'il reste un juge à prouver. Aucun juge : aucune ligne ; `resume`, `clear`, `compact` : aucune ligne ;
hors adhésion : rien (pré-filtre, octet vide). Fail-open : une erreur du vérificateur la tait.

**Diagnostic.** `planning-hook.sh --juges <racine du lab>` (patron de `--classer` : premier argument du lanceur, racine en second, sans lire stdin) imprime UNE
ligne JSON `{"prouves": […], "laxistes": […], "sans_preuve": [{"juge": …, "motif": …}]}` et rend 0 ; il ne vérifie pas l'adhésion.

**Étape du premier cycle.** Le premier passage de chaque juge sur sa sortie piégée est une étape **écrite** du premier cycle (`CYCLE.template.md`, « Premier
cycle — canary de juge ») : le manager dispatche le juge sur `.planning/juges/<juge>/SORTIE-PIEGEE.md`, puis pose le verdict par `poser-verdict.sh`. Tant que ce
n'est pas fait, le `SessionStart` signale « juge sans preuve ». Limites : (bb), (bh).

### Le hook par rôle (GATE-09)

Le rôle se **dérive** de la définition de l'agent écrivain (`agent_type` du payload), par les
prédicats de `check-agents.sh` réimplémentés dans le hook (choix motivé : `planning-core` ne dépend
d'aucun module) : **juge** = I5 (`disallowedTools` retire `Write` et `Edit`, aucune allowlist
`Agent(...)` non vide) ; **manager** = I6 (allowlist non vide, pas `vf-internal`) ; **worker** =
`vf-internal: true` ; **producteur** = tout autre agent résolu (P45-D-05). Un contrôle croisé
(`scripts/tests/test-role-hook-vs-check-agents.sh`, chemin pris depuis la racine du dépôt et non
depuis le module) compare la dérivation à `check-agents.sh` sur tout
le corpus d'agents du dépôt et sur des fixtures adverses, et peut rougir (P45-D-05a).

La **résolution** `agent_type` → définition suit l'ordre écrit plus haut (P45-D-05b) : agents du lab
(`.claude/agents/`), puis du compte (`<HOME>/.claude/agents/`), puis, pour `<plugin>:<agent>`, ceux de
la version active du plugin sous `<HOME>/.claude/plugins/` ; le premier niveau qui trouve gagne ; deux
définitions de rôles contradictoires au même niveau valent **inconnu** ; un agent en lien symbolique
n'est jamais une définition. Le nom est indexé par `name:` (repli : nom de fichier) et comparé après
normalisation (casefold, `_` et espace unifiés en `-`). La résolution est bornée : 1 000 entrées
lues par dossier d'agents (`BORNE_AGENTS_PAR_DOSSIER`), 8 Mio lus au total pour indexer un dossier
(`BORNE_OCTETS_INDEX`), 4 096 octets d'en-tête pour reconnaître un candidat
(`BORNE_ENTETE_DEFINITION`) ; une définition de plus de 1 Mio (`BORNE_LECTURE_DEFINITION`) ou portant
une ligne de plus de 32 768 caractères (`BORNE_LIGNE_DEFINITION`) est illisible, jamais un verdict de
rôle ; côté plugins, 64 installations au plus par plugin (`BORNE_ENTREES_PLUGINS`) et 20 000 dossiers
parcourus au plus par version (`BORNE_PARCOURS_PLUGINS`).

Lignes appliquées (la table §5 de la spec fabrique, sans règle en double dans le code) : **juge** —
toute écriture par outil est refusée (le verdict se pose par `poser-verdict.sh`) ; **worker** — un
dispatch (`tool_name` `Agent` **ou** `Task`, P45-D-09) dont le `subagent_type` normalisé n'égale aucun
nom de **sa propre** allowlist `Agent(...)` / `Task(...)` est refusé, allowlist vide : tout refusé
(F9 = f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30 ; limite (l)) ; **producteur
et manager** — aucune ligne propre, G5 couvre l'écriture d'un verdict (P45-D-07). **Fil principal**
(`agent_id` absent) et **agent inconnu, ambigu, illisible ou de plugin non résolu** ne reçoivent que la
ligne « Tous » et les gates G1, G5, G6 et G7 : un juge dont la définition n'est pas trouvée n'est pas
traité en juge (limite déclarée, P45-D-11 ; le canary la compte). Le rôle ne s'applique qu'aux labs
adhérents : la ligne « Worker : tout dispatch refusé », appliquée à un lab dev, casserait la chaîne
`vf-coder` vers les briques de développement (P45-D-04).

### La dérogation (GATE-11)

La commande `deroger-gate.sh --lab=… --gate=<G1|G3|G4|G4P|G5|G6|G7|ROLE|PLAFOND> --chemin=… --qui=… --canal=…
--date=… --raison=…` inscrit une dérogation **nominative** (qui, canal, date, gate, chemin(s), raison)
dans le journal append-only `.planning/derogations-gates.log`, une ligne par chemin, champs en
encodage pourcent injectif (P45-D-13). Une raison vide, `TODO`, `TBD`, `FIXME`, `n/a`, `xxx` (toute
suite de `x`), une ellipse ou `<…>` est refusée avec le code 64, après normalisation Unicode (NFKC,
caractères de contrôle et de format retirés, blancs de bord retirés, casse repliée par `casefold`) :
`tbd`, `Fixme` ou `N/A`, quelle que soit leur casse et même écrits en pleine chasse, sont refusés.
Elle n'est **jamais conditionnée à l'urgence** : aucune option,
aucune horloge ne conditionne l'acceptation (spec §5.2). Durée de vie : **usage unique** par
(gate, chemin) ; le hook qui laisse passer une action grâce à elle ajoute une ligne `consommee` et la
**cite** dans la sortie de l'action (numéro, gate, chemin, auteur, canal, date, raison) ; sans effet
sur un gate en observation. Le journal doit être un fichier régulier : un lien annule toute
dérogation ; un journal de plus de 1 Mio (`BORNE_LECTURE_FICHIER`) n'est pas lu : aucune dérogation, le refus est maintenu, au hook comme à `poser-verdict.sh` qui porte la même lecture bornée (limite (bj)). Limite : l'identité déclarée (`--qui`) n'est pas vérifiée, la commande ne peut pas savoir
qui la lance (T-45-34). Le jeton `PLAFOND` (P46-D-05) lève le plafond de trois tentatives de la commande de
verdict : son chemin est le dossier de l'unité, et c'est `poser-verdict.sh`, non le hook, qui la consomme — avec le même code borné que le hook : sur un journal de plus de 1 Mio la dérogation `PLAFOND` n'est ni lue ni consommée, la quatrième tentative reste refusée (65).

### La commande de verdict (GATE-05)

`poser-verdict.sh --unite=… --juge=… --tentative=… --score=… --constat=<critère>::<passé|échec>` est le
**seul** chemin légitime vers `VERDICT.md` (lancée par Bash, elle n'est jamais vue par G5). Le hash
(sha256 des octets du `PLAN.md` de l'unité, A3 = a3-plan) est calculé **par la commande**, jamais
fourni par l'agent ; `--tentative` est une option **obligatoire que la commande vérifie** (1 à la
création, ancienne tentative + 1 pour remplacer ; toute autre valeur : code 64, fichier inchangé) ;
l'écriture est atomique et ne traverse jamais un lien. Codes de sortie : 0 verdict écrit, 1 erreur de
lecture ou d'écriture, 2 lab non adhérent, 64 usage ou valeur refusée. Elle est agnostique de l'appelant (F8 =
f8-agnostique, Willy, AskUserQuestion session principale, 2026-09-30) : un juge qui a `Bash` la lance
lui-même, les autres livrent leur rapport au manager qui la lance. Limite : `--juge` est déclaratif.

Depuis la Phase 46 (P46-D-03, P46-D-03a, P46-D-05, P46-D-06a, P46-D-12) la commande pose **deux
empreintes** : `hash` (le plan) et `hash_livrables` (les entrées `ecrit:`, voir § `VERDICT.md`), refuse de
poser un verdict quand un livrable déclaré est absent, vide ou un lien, applique le **plafond de 3
tentatives** (code 65, dérogation `PLAFOND` à usage unique) et admet la forme d'unité
`.planning/juges/<juge>`. Codes de sortie complets : 0 verdict écrit, 1 erreur de lecture ou d'écriture,
2 lab non adhérent, 64 usage ou valeur refusée (dont `ecrit:` invalide, entrée `ecrit:` qui est ou contient
le dossier de l'unité — point fixe, § `VERDICT.md` —, livrable absent, vide ou lien, borne dépassée), 65
plafond de tentatives atteint sans dérogation.

### Le journal d'observation

Un gate en observation écrit une ligne par refus évité dans
`${XDG_CACHE_HOME}/vibeflow/gates-observation/observation.log` (à défaut `${HOME}/.cache/…`), ajout
seul, fichier 0600 : horodatage, gate, lab, chemin, outil, raison — **jamais** le contenu écrit ni la
commande. Un journal impossible à écrire ne devient jamais un refus. Limite (r).

### Le canary (GATE-12)

Un canary rejoue la **commande enregistrée telle quelle** (celle des réglages, jamais un appel direct
au script) sur des payloads qui doivent être refusés. En **CI**, il est bloquant : la suite
`plugin/_internal/tests/test-planning-hook-installed.sh` installe `planning-core` par l'installeur
inchangé et rejoue la commande posée (script absent, `python3` absent, script qui sort 1 puis 2).
Au **démarrage de session** d'un lab adhérent (`check-gates-alive.sh`, `SessionStart` `startup`), il
signale sans jamais bloquer, par une seule ligne : hook central non enregistré, commande enregistrée
non reconnue (le canary n'exécute que la commande de référence), mode dégradé, constantes
d'armement absentes ou illisibles, gate armé sans cas de canary, cas en échec. L'attendu de chaque cas
est **dérivé** de la table d'armement du script frère : observation (stdout vide et une ligne au
journal jetable) tant que le gate est `observe`, refus de gate dès qu'il est `armed`. Couverture
minimale déclarée et vérifiée cas par cas (P45-D-20) : script absent, `python3` absent, `Task` et
`Agent`, fil principal, agent `plugin:`. Il rend visible la limite (i). Les cas de G4′ (`G4P-handback`, `G4P-stop`, Phase 46)
rejouent le rapport sans sortie brute d'un producteur synthétique doté de `Bash` ; l'attendu armé d'un cas `SubagentStop` est
l'objet `decision: "block"` en code 0, celui d'un cas `SubagentHandback` un `deny`. Le cas `D1-trace` (Phase 46, 46-07) est d'une autre catégorie : D1 ne
s'arme pas, son attendu est une trace (une ligne `contournement` de plus au journal du lab synthétique, stdout vide), et sa défaillance est signalée comme celle d'un gate. Limite : (bi).

### Le rejeu (GATE-13)

`rejeu-gates.sh` mesure ce qu'un gate armé refuserait, sur une **copie** du lab (adhésion et armement
simulés, aucune commande git) : un attendu par écriture, un relevé `gate | lab | chemin | attendu |
obtenu | raison`, des comptes par gate (faux refus, faux accept, refus conformes au modèle).
`rejeu-reel.sh` est le geste de rejeu sur un lab réel : il prend l'empreinte de **tout** l'arbre
avant et après, par un geste extérieur à l'outil mesuré, comparée octet pour octet. Règles
(P45-D-21) : hors CI, en lecture seule, chemins affichés sous la forme `~/…`, aucun chemin de machine
dans le code livré. Pour un lab réel **non migré**, **le modèle fait référence** (P45-D-21a) : une
écriture que le modèle interdit — le `PLAN.md` d'une phase sans `CADRAGE.md`, un `.planning/` orphelin
de la table D-05 — est un **refus conforme au modèle, lab non migré** ; il est compté à part, jamais en
faux refus ni en faux accept ; le seuil d'armement porte sur les faux refus et les faux accepts. La
classification est **totale** (P45-D-21c) : l'état dérivé par `recalc-planning.sh --read-only` fait
référence quand il existe, sinon la règle écrite du modèle s'applique avec le code propre de l'outil,
dans un sous-compte distinct. Limite (x).

### Coût de migration d'un lab

Un lab non migré qui adhère à `cycles-v1` découvre, au premier jour des gates armés, ce que le modèle
lui interdit. Ce qu'il faut écrire : **un `CADRAGE.md` par phase de forme modèle qui n'en a pas**, ou
une **dérogation nominative** (`deroger-gate.sh`) par écriture à laisser passer. Comment le mesurer :
`rejeu-reel.sh --lab=<chemin> --etape=2` rend, par motif, le nombre de refus conformes au modèle de G1
(phases sans cadrage), et `--etape=3` ajoute ceux de G7 (planning orphelin, avec un fichier d'attendus
`--attendus=<fichier>`). Les nombres relevés sur les labs réels du poste vivent dans l'artefact de phase
`45-COUT-MIGRATION.md`, jamais dans le code livré ni dans cette référence (P45-D-21, P45-D-21a).

## Hors de cette phase

Ce que les Phases 44 et 45 **ne font pas** :

- **G2′, G3, G4, G4′ et D1** (`TaskCompleted`, `SubagentStop`, `FileChanged`) : Phases 46 et 47. La
  **vérification du hash** de `VERDICT.md` à la clôture : Phase 46.
- **Le hook managed** (seul à résister à `disableAllHooks`) : hors périmètre ; le gate détecte et
  trace, il ne verrouille pas.
- **`guard-planning-updated.sh` n'est pas retiré** et reste en exit 2 (entrée `Stop` de `hooks.json`
  inchangée, P45-D-19, ADR-031 : suppression de code sous validation humaine).
- Les drapeaux `"phases_trace"` et `options.gates` du `config.json` d'un lab **ne sont lus par aucune
  phase** et restent sans effet : les gates s'arment avec l'adhésion (P45-D-01).
- **Le socle métier v2 existant n'est pas retiré** : le remplacement est **additif** — les labs qui
  adhèrent à `cycles-v1` passent au moteur, les autres restent sur l'existant. Tout retrait de
  code existant (prose « scaffoldeur » du `SKILL.md`) se fait sous validation humaine (ADR-031 :
  suppression de code) (P44-D-01e).
- Les **baux** (`.planning/baux/`) : Phase 47.
- L'**injection de l'index** et le **pont mémoire** : Phase 48.
- Les **cycles récurrents** (`recurrent: true`, cadence, `bloqué par un tiers`) : spec §8, hors
  Phase 44.
- La **migration** des plannings existants au nouveau modèle, les **labs imbriqués**, le
  **renommage** d'un cycle : spec §11.3, hors Phase 44.
