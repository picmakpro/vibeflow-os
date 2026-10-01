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
```

Une phase porte `CADRAGE.md`, et **soit** un plan direct (`PLAN.md`, `CLOTURE.md`, `VERDICT.md`,
`SUMMARY.md` directement sous la phase), **soit** `plans/<NN-nom>/{PLAN.md, CLOTURE.md, VERDICT.md,
SUMMARY.md}` ; phase et plan peuvent l'un et l'autre porter `DEROGATION.md`.

**Nom d'unité** (cycle, phase, plan) : `^[0-9]{2,}-[\w.-]+$` — lettres accentuées admises, ni
espace ni caractère de contrôle.

**Le livrable vit à sa place métier**, hors de `.planning/`, déclaré par `ecrit:` (voir § Fichiers
du modèle, `PLAN.md`, et spec §3).

**Emplacements du modèle** à la racine de `.planning/` : dossiers `cycles`, `baux`, `missions` ;
fichiers `PROJECT.md`, `REQUIREMENTS.md`, `config.json`, `INDEX.md`, `STATE.md`, `cloture.log`,
`.recalc-cache.json`, `derogations-gates.log` (journal de dérogation des gates, Phase 45 : F7a, P45-D-13 —
Willy, AskUserQuestion session principale, 2026-09-30 ; jamais « Hors modèle »). `baux/` et `missions/`
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
consommeront les verdicts hachés de la Phase 46 (P44-D-03).

**Limite connue et acceptée** (aucun contrôle supplémentaire en Phase 44) : un segment
**intermédiaire** en lien symbolique sous la racine du lab (par exemple `cycles` lui-même
remplacé par un lien) peut faire constater par `os.path.lexists` une existence qui pointe, via ce
segment, hors de la racine du lab. Le contrôle porte sur la **forme** de l'entrée (pas de `..`,
pas de `~`/`/` initial), jamais sur une résolution des segments intermédiaires du disque —
documentée ici plutôt que corrigée, jusqu'à la protection des fichiers générés (G6, Phase 45).

### `CLOTURE.md`

Le **marqueur de clôture** du plan : un fichier **à côté** de `PLAN.md`, jamais un champ dedans.
Frontmatter : `cloture_par`, `cloture_le`. Le recalcul ne lit que **sa présence**. `à exécuter` =
`PLAN.md` présent, `CLOTURE.md` absent (spec §3.1).

### `VERDICT.md`

Frontmatter : `juge` (auditeur indépendant, **jamais** l'auteur du livrable), `hash` (sha256 de
l'artefact jugé), `tentative` (entier, compteur anti-boucle), `score` (jugement non bloquant,
spec D-02 amendée), `constats` = liste **non vide** de mappings {`critere`, `resultat`
(`passé`|`échec`)}.

`VERDICT.md` incarne, au sens de la couche d'audit générique (`audit-architecture`), ses cinq
attributs : **dimension** = un constat par critère éliminatoire objectivement vérifiable ;
**auditeur indépendant** = `juge`, jamais l'auteur du livrable ; **rubric** = les `constats` ;
**verdict bloquant** = un `échec` empêche `close` (§ Règles de dérivation, R7) ; **anti-boucle** =
`tentative`, qui compte les allers-retours.

En Phase 44, `hash` et `tentative` sont **lus et restitués, jamais vérifiés** — leur vérification
(hash contre l'artefact effectivement produit) relève de la Phase 46 (P44-D-09).

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

## Les huit états et les dérogations

| État | Ce que la machine constate |
|---|---|
| `à cadrer` | dossier présent, pas de `CADRAGE.md` |
| `en cadrage` | registre avec au moins une ligne structurante sans statut |
| `à planifier` | registre clos, pas de `PLAN.md` |
| `à exécuter` | `PLAN.md` présent, marqueur de clôture (`CLOTURE.md`) absent |
| `à juger` | marqueur présent, livrables présents, pas de `VERDICT.md` |
| `à corriger` | constats du verdict en échec |
| `close` | constats passés **et** `SUMMARY.md` présent |
| `indéterminé` | les signaux se contredisent |

Plus trois **dérogations non dérivables** : `abandonné`, `remplacé`, `gelé` — posées par
dérogation nominative, lues dans un champ `statut:` qui **doit nommer son auteur**. Ces huit états
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

Un plan applique Φ0 et Φ1 puis R1 à R8.

- **R1** — pas de `PLAN.md` : SUMMARY présent → `SUMMARY.md-sans-PLAN.md` ; CLOTURE présent →
  `CLOTURE.md-sans-PLAN.md` ; VERDICT présent → `VERDICT.md-sans-PLAN.md` ; sinon `à planifier`.
- **R2** — frontmatter de `PLAN.md` illisible → `frontmatter-invalide:PLAN.md` ; `ecrit:` absent,
  vide ou avec une entrée invalide → `ecrit-invalide`.
- **R3** — pas de `CLOTURE.md` : VERDICT présent → `VERDICT.md-sans-CLOTURE.md` ; SUMMARY présent
  → `SUMMARY.md-sans-CLOTURE.md` ; sinon `à exécuter`.
- **R4** — un livrable d'`ecrit:` absent sous la racine du lab → `livrable-absent:<entrée>`.
- **R5** — pas de `VERDICT.md` : SUMMARY présent → `SUMMARY.md-sans-VERDICT.md` ; sinon `à juger`.
- **R6** — frontmatter de `VERDICT.md` illisible → `frontmatter-invalide:VERDICT.md` ; `constats`
  absent, vide ou avec un `resultat` hors `passé`/`échec` → `verdict-invalide`.
- **R7** — un constat `échec` : SUMMARY présent → `SUMMARY.md-avec-verdict-en-echec` ; sinon
  `à corriger`.
- **R8** — constats tous `passé` : SUMMARY présent → `close` ; sinon `indéterminé`
  (`verdict-passe-sans-SUMMARY.md`).
- **Défaut défensif** : `combinaison-non-prevue` — clause de garde-fou pour une évolution
  future des règles R1-R8/Φ0-Φ5 ; R1-R8 tel que codé aujourd'hui épuise déjà toute combinaison
  possible de plan/cloture/verdict/summary/constats, ce libellé n'est donc produit par AUCUN
  chemin du code actuel (F6, 2026-09-28).

### Le cas « verdict passé sans SUMMARY.md »

R8 rend `indéterminé` (`verdict-passe-sans-SUMMARY.md`) — la table du §3.1 de la spec **ne nomme
pas** cet état de transition, et P44-D-08 interdit au moteur de le **supposer**. C'est un état de
transition **normal**, pas une anomalie : entre un verdict aux constats tous `passé` et l'écriture
de `SUMMARY.md`, le disque ne permet pas de trancher seul entre « close » et « en cours de
clôture », donc le moteur avoue plutôt que de deviner.

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
| `livrable-absent:<entrée>` | R4 | un chemin d'`ecrit:` n'existe pas sur le disque |
| `SUMMARY.md-sans-VERDICT.md` | R5 | résumé avant jugement |
| `verdict-invalide` | R6 | `constats` absent, vide, ou `resultat` hors `passé`/`échec` |
| `SUMMARY.md-avec-verdict-en-echec` | R7 | contradiction P44-D-08 |
| `verdict-passe-sans-SUMMARY.md` | R8 | état de transition non nommé par le §3.1 |
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

**`.recalc-cache.json`** : JSON, `cache_schema_version` = `1`, `moteur` = `"recalc-planning"`,
signature sha256 du contenu des fichiers lus par unité. Absent, illisible, lien, ou d'un autre
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
| `verdict-passe-sans-SUMMARY.md` | verdict passé, SUMMARY absent |
| `SUMMARY.md-sans-PLAN.md` | SUMMARY.md sans PLAN.md |
| `CLOTURE.md-sans-PLAN.md` | CLOTURE.md sans PLAN.md |
| `VERDICT.md-sans-CLOTURE.md` | VERDICT.md sans CLOTURE.md (marqueur) |
| `SUMMARY.md-avec-verdict-en-echec` | SUMMARY.md avec un verdict en échec |
| `derogation-sans-auteur` | dérogation sans auteur nommé |
| `derogation-invalide` | dérogation invalide |
| `CYCLE.md-absent` | CYCLE.md absent |

Un code **suffixé** `:<x>` (ex. `phase-indeterminee:<phase>`, `plan-indetermine:<plan>`,
`livrable-absent:<entrée>`) se sépare sur le **premier** `:` : le libellé de la partie fixe
s'applique et `<x>` s'y insère littéralement — `phase-indeterminee:<phase>` → «`` phase `<phase>`
indéterminée ``» ; `plan-indetermine:<plan>` → «`` plan `<plan>` indéterminé ``» ;
`livrable-absent:<entrée>` → « livrable absent : `<entrée>` ».

Tout code **absent** de la table (`fichier-non-regulier:<nom>`, `erreur-de-lecture:<nom>`,
`frontmatter-invalide:<nom>`, `hors-cadrage:<nom>`, `registre-invalide`,
`avant-cadrage-clos:<nom>`, `plan-direct-et-plans`, `fichier-de-plan-au-niveau-phase:<nom>`,
`ecrit-invalide`, `verdict-invalide`, `SUMMARY.md-sans-CLOTURE.md`, `SUMMARY.md-sans-VERDICT.md`,
`VERDICT.md-sans-PLAN.md` compris) retombe sur **lui-même** avec `-` et `:` remplacés par des
espaces — jamais un `KeyError`.

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

Huit gabarits sous `plugin/planning-core/references/templates/cycles/`, un par fichier du modèle,
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
| `config.template.json` | déclaration d'adhésion (`cycles-v1`) |

**Un gabarit recopié tel quel (sans être rempli) ne fait jamais passer une unité en `close`** :

| Gabarit recopié tel quel | État dérivé |
|---|---|
| `CADRAGE.md` | `en cadrage` |
| `PLAN.md` (entrée `ecrit:` à crochets) | `indéterminé` (`ecrit-invalide`) |
| `VERDICT.md` (résultat à crochets) | `indéterminé` (`verdict-invalide`) |
| `DEROGATION.md` (statut à crochets) | `indéterminé` (`derogation-invalide`) |
| `CYCLE.md` seul | cycle `à cadrer` |
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

L'entrée `PreToolUse` de `hooks.json` (matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`, `timeout`
de 20 s) est une commande **de forme shell**, jamais la forme exec `{{VF_BASH}}` (qui part dans
`settings.local.json` et n'a pas de shell pour porter le test de présence) : l'installeur la pose
dans `settings.json`. Elle lance le script en fils et **reprend tout code non nul** (script absent,
`python3` absent, plantage, échéance interne : code 73). Dans ce cas elle décide elle-même, **sans
`python3`**, si le lab est adhérent — extraction shell du chemin écrit ou du `cwd`, remontée jusqu'au
plus proche `.planning`, lecture de `config.json` — et :

- dans un lab adhérent (ou dans le doute, voir (u)), elle émet un refus JSON statique avec un message
  de réparation (mettre à jour VibeFlow, ou installer `python3`, puis relancer la session) ;
- hors d'un lab adhérent, elle se tait : un lab dev sans `python3` n'est jamais refusé (P45-D-06a) ;
- le **timeout** du harnais reste un fail-open sans réglage possible : le canary est obligatoire de
  toute façon (P45-D-06, P45-D-20).

- **Outils refusés en mode dégradé** : `Write`, `Edit`, `NotebookEdit`, `Agent`, `Task`.
- **Outil laissé ouvert en mode dégradé** : `Bash` (P45-D-06b).

Limites déclarées de la couche shell, puis des gates, chacune sur sa propre ligne (la lettre, puis la
source). Les lettres (a) à (l) sont celles du plan ; (m) et suivantes sont les limites que les
corrections ciblées et les relectures de la phase ont ajoutées (décisions du manager vf-dev-manager,
2026-10-01, renversables par Willy).

- **limite (a)** — la commande ne reconnaît le filtre d'outil qu'en JSON **compact** : un `"tool_name" : "Write"` espacé échappe au filtre dégradé (les clés de chemin tolèrent les blancs). Source : recherche du plan 45-01, vérifié sur le harnais 2.1.284.
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
- **limite (m)** — F2 (re-audit, inverse de (k)) : un `config.json` adhérent pour Python mais à clé ou valeur échappée (par exemple `_` ou `-` écrits en `\u…`) ou réparti sur plusieurs lignes est lu comme non adhérent par le repli shell, donc silence si le cœur tombe ; exploitation conditionnée à une panne du cœur.
- **limite (n)** — T-45-42 reformulée : F6 (`config.json` protégé par G6 contre un changement ou un retrait de l'adhésion, Willy, AskUserQuestion session principale, 2026-09-30) ferme le désarmement « par outil » ; Bash reste ouvert (P45-D-10) : un `sed` ou une redirection qui retire l'adhésion désarme les gates.
- **limite (o)** — amendement de P45-D-01a (décision du manager vf-dev-manager, 2026-10-01) : un `.planning` situé dans (ou sous) un composant `.planning` n'est jamais une racine de lab ; limite : un lab situé sous un ancêtre nommé `.planning` n'est plus une racine gardée.
- **limite (p)** — R1 (re-audit) : un `.planning/` sans `config.json` sous un sous-dossier ordinaire rend ce sous-dossier non adhérent (« le plus proche gagne ») ; G7 n'interdit que sa création par outil, pas son existence.
- **limite (q)** — m1 (revue) : un worker qui dispatche sans `subagent_type`, ou avec `fork`, est refusé (le hook ne traite pas `fork` à part : absent de l'allowlist) ; la sémantique du harnais pour ces dispatchs n'est pas mesurée.
- **limite (r)** — m6 (revue) : le journal d'observation (`~/.cache/vibeflow/gates-observation/`) n'a ni borne ni rotation.
- **limite (s)** — coût et échéance : la résolution d'un agent de plugin a été mesurée à environ 0,05 s à vide (0,11 s au plus avec mille fichiers dans le dossier d'agents, huit définitions candidates de 1 Mio comprises ; 0,12 à 0,40 s avant la correction du lot A) ; la borne n'est pas ce coût mais l'échéance interne de 8 s du cœur (code 73), qui ferme sous adhésion : sur une machine lente ou chargée, un dépassement refuse des écritures légitimes (risque de déni de service).
- **limite (t)** — F3 (re-revue) : sans `installed_plugins.json` exploitable, la « plus haute version » d'un plugin est extraite des chiffres du nom de dossier (un SHA ou `unknown` peut la fausser), tous scopes confondus.
- **limite (u)** — F4 (re-revue ; décision du manager vf-dev-manager, 2026-10-01) : cœur tombé, un chemin portant un échappement JSON non géré (`\b`, `\f`, `\r`, `\uXXXX`) est refusé même hors de tout lab adhérent, le doute tombant du côté du refus ; le message dit « doute d'adhésion du lab » et non qu'un lab adhérent est en cause.
- **limite (v)** — F5 (lot B) : un `STATE.md` qui porte la marque de génération en tête, puis édité à la main, est remplacé sans archive (la marque seule le fait tenir pour généré).
- **limite (w)** — N1 résiduelle : un `name:` masqué par un échappement YAML dans l'en-tête de la définition n'est pas candidat à l'indexation des agents.
- **limite (x)** — rejeu : le volume n'est pas optimisé (25 000 fichiers en plus de 300 s) ; un `.planning` qui est un lien vers un dossier du lab n'est pas suivi par la copie et rend désormais MESURE-VIDE (code 1), jamais un vert.
- **limite (y)** — réglages `.claude/settings*.json` non protégés (Willy, AskUserQuestion session principale, 2026-10-01, Q-G6 = b) : un `Write` qui retire le hook de `settings.json` désarme les gates ; scripts du hook (`.claude/scripts/planning-hook.sh` et celui du canary, `check-gates-alive.sh`) protégés par G6 en scope projet (`<lab>/.claude/scripts/`, Write, Edit et NotebookEdit ; Bash reste ouvert, P45-D-10) ; scope compte (`~/.claude/scripts/`) non protégé : la racine du lab se dérive du chemin écrit et ces scripts ne sont sous aucun lab adhérent (sauf un HOME qui serait lui-même un lab adhérent), mesuré par `test-planning-hook-installed.sh`. Le canary de session signale un script sans constantes d'armement ; il n'empêche rien.

### Table d'armement livrée

L'état de chaque gate vit **dans le code livré** (une constante `ARMEMENT_<gate>` par gate dans
`planning-hook.sh`), jamais dans un fichier du lab ni dans une variable d'environnement (P45-D-03a).
`observe` : le gate calcule, **journalise** ce qu'il aurait refusé, laisse passer ; `armed` : le gate
refuse (`deny`, **fermé**) ; sur erreur interne, un gate `armed` refuse et un gate `observe`
journalise. G2 avertit toujours et ne refuse jamais (**ouvert**). Armement par étapes dans un ordre
fixe (P45-D-03), une étape suivante n'étant jamais armée avant la précédente ; chaque étape exige son
canary, puis 0 faux refus et 0 faux accept sur le banc synthétique et sur le rejeu réel (P45-D-03b).

| Gate | Étape | État | Comportement sur défaillance | Cas de canary | Relevé |
|---|---|---|---|---|---|
| G6 | 1 | observe | armé : fermé (deny) ; observe : journalise | G6-principal, G6-plugin | 45-REJEU-ETAPE-1 |
| G5 | 1 | observe | armé : fermé (deny) ; observe : journalise | G5-verdict, G5-imbrique | 45-REJEU-ETAPE-1 |
| G1 | 2 | observe | armé : fermé (deny) ; observe : journalise | G1-sans-cadrage | 45-REJEU-ETAPE-2 |
| G7 | 3 | observe | armé : fermé (deny) ; observe : journalise | G7-orphelin | 45-REJEU-ETAPE-3 |
| ROLE | 4 | observe | armé : fermé (deny) ; observe : journalise | ROLE-juge, ROLE-worker-Agent, ROLE-worker-Task | 45-REJEU-ETAPE-4 |
| G2 | - | avertit | ouvert : n'avertit pas, ne refuse jamais | aucun | aucun |

**État d'armement livré, tel que mesuré (v2.9.0).**

- Les cinq constantes `ARMEMENT_*` valent `observe` ; `G2_MODE` vaut `avertit`.
- Les rejeux réels des étapes 1 à 4 ont tous rendu 0 faux refus et 0 faux accept, avec des empreintes d'arbre identiques (relevés de phase `45-REJEU-ETAPE-1` à `45-REJEU-ETAPE-4`). Mais ils ont été mesurés sur le hook **avant** les lots de correction A, B et C.
- L'armement exige donc un NOUVEAU rejeu réel, sur des labs au repos, **et** un arbitrage de Willy, en attente, pour adapter deux suites couplées à « tout en observe » (modification refusée par le classifieur « Security Test Removal »).
- La phase se ferme **en observation**, mesurée à zéro. Aucun gate n'est armé : ce document ne dit jamais qu'un gate est armé tant qu'une constante vaut `observe`.

Quatre listes que R-REFERENCE compare au code, chacune sur une seule ligne :

- **Noms protégés par G6** : `STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`, `config.json`.
- **Journal de dérogation** : `derogations-gates.log`.
- **Marqueurs de projet de code (G7)** : `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `build.gradle`, `build.gradle.kts`, `composer.json`, `Gemfile`, `tsconfig.json`, `Package.swift`, `*.xcodeproj`.
- **Ordre de résolution des agents (P45-D-05b)** : lab, compte, plugin

### G2 — avertit, ne refuse jamais (GATE-08)

Sur une écriture (`Write`, `Edit`, `NotebookEdit`) ou une commande `Bash` qui vise un chemin du lab
adhérent hors de `.planning/` et de `.claude/` et hors du `ecrit:` de tout plan ouvert, G2 ajoute un
`additionalContext` (jamais un `permissionDecision`) ; il est fail-open (spec §5.1). Le
référentiel est l'**union** des `ecrit:` des plans ouverts, pour tout écrivain, fil principal compris ;
un plan clos ou dérogé ne couvre rien ; un frontmatter illisible fait ignorer le plan. Pour Bash, un
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
même canal, même date). Le motif d'un refus nomme `recalc-planning.sh` (ou `deroger-gate.sh`) : le
`Stop` de la 44 invite à mettre à jour l'état, le refus ne le contredit pas. G6 est un refus de
l'outil, pas du disque : `Bash` et `recalc-planning.sh` écrivent ces fichiers (P45-D-10).

### G5 — le verdict par commande (GATE-05)

G5 refuse toute écriture par outil d'un fichier nommé `VERDICT.md` (casse ignorée) sous le `.planning/`
d'un lab adhérent, quel que soit le rôle ; un lien dur vers un verdict est ce verdict ; un `VERDICT.md`
hors de `.planning/` n'est pas visé. Le motif nomme `poser-verdict.sh`.

### G1 — pas de plan sans cadrage (GATE-06)

G1 refuse l'écriture (`Write`, `Edit`) d'un `PLAN.md` de forme modèle — direct sous la phase, ou
`plans/<plan>/PLAN.md` — dans une phase sans `CADRAGE.md`, ou dont le registre porte une ligne
structurante sans statut (le refus cite les identifiants ouverts). Il lit l'état que le modèle dérive
par des copies ast-identiques du parseur de frontmatter et du registre, contrôlées phase par phase
contre le vrai `recalc-planning.sh --read-only` (CROISE-G1). La valeur d'un statut n'est jamais jugée.
Un `PLAN.md` du socle v2 ou sous un nom d'unité invalide n'est jamais visé. Bord : limite (j).

### G7 — pas de planning orphelin (GATE-07)

G7 refuse la **création**, par `Write` ou `NotebookEdit`, d'un dossier `.planning/` dans un dossier X
sous un lab adhérent, sauf si X porte un marqueur de projet de code (la liste ci-dessus, tenue égale à
celle de `detect-gsd-engine.sh` par un contrôle qui extrait le texte du détecteur) ou un `.claude/`
**habité**. Prédicat littéral de « habité » (P45-D-14, F4 = f4-litteral) : au moins un fichier
**régulier** `X/.claude/agents/*.md` ET au moins un fichier **régulier** sous `X/.claude/memory/` (lstat :
jamais un lien, jamais un dossier). Un `.claude/` qui ne porte pas les deux — un `agent-memory/` sans
fichier, des agents sans mémoire, une mémoire sans agent, un dossier vide — n'est pas habité. Le
parcours de la mémoire est borné : au-delà de la borne le prédicat est indéterminé et G7 ne refuse pas.
La table D-05 de la spec est corrigée en conséquence (P45-D-14a, Willy, AskUserQuestion session
principale, 2026-09-29) : un dossier dont le `.claude/` n'a ni agent ni mémoire non vide n'est pas un
lab. La création d'un `.planning/` par Bash n'est pas couverte (P45-D-10).

### Le hook par rôle (GATE-09)

Le rôle se **dérive** de la définition de l'agent écrivain (`agent_type` du payload), par les
prédicats de `check-agents.sh` réimplémentés dans le hook (choix motivé : `planning-core` ne dépend
d'aucun module) : **juge** = I5 (`disallowedTools` retire `Write` et `Edit`, aucune allowlist
`Agent(...)` non vide) ; **manager** = I6 (allowlist non vide, pas `vf-internal`) ; **worker** =
`vf-internal: true` ; **producteur** = tout autre agent résolu (P45-D-05). Un contrôle croisé
(`scripts/tests/test-role-hook-vs-check-agents.sh`) compare la dérivation à `check-agents.sh` sur tout
le corpus d'agents du dépôt et sur des fixtures adverses, et peut rougir (P45-D-05a).

La **résolution** `agent_type` → définition suit l'ordre écrit plus haut (P45-D-05b) : agents du lab
(`.claude/agents/`), puis du compte (`<HOME>/.claude/agents/`), puis, pour `<plugin>:<agent>`, ceux de
la version active du plugin sous `<HOME>/.claude/plugins/` ; le premier niveau qui trouve gagne ; deux
définitions de rôles contradictoires au même niveau valent **inconnu** ; un agent en lien symbolique
n'est jamais une définition. Le nom est indexé par `name:` (repli : nom de fichier) et comparé après
normalisation (casefold, `_` et espace unifiés en `-`).

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

La commande `deroger-gate.sh --lab=… --gate=<G1|G5|G6|G7|ROLE> --chemin=… --qui=… --canal=…
--date=… --raison=…` inscrit une dérogation **nominative** (qui, canal, date, gate, chemin(s), raison)
dans le journal append-only `.planning/derogations-gates.log`, une ligne par chemin, champs en
encodage pourcent injectif (P45-D-13). Une raison vide, `TODO`, `xxx`, une ellipse ou `<…>` est
refusée après normalisation Unicode. Elle n'est **jamais conditionnée à l'urgence** : aucune option,
aucune horloge ne conditionne l'acceptation (spec §5.2). Durée de vie : **usage unique** par
(gate, chemin) ; le hook qui laisse passer une action grâce à elle ajoute une ligne `consommee` et la
**cite** dans la sortie de l'action (numéro, gate, chemin, auteur, canal, date, raison) ; sans effet
sur un gate en observation. Le journal doit être un fichier régulier : un lien annule toute
dérogation. Limite : l'identité déclarée (`--qui`) n'est pas vérifiée, la commande ne peut pas savoir
qui la lance (T-45-34).

### La commande de verdict (GATE-05)

`poser-verdict.sh --unite=… --juge=… --tentative=… --score=… --constat=<critère>::<passé|échec>` est le
**seul** chemin légitime vers `VERDICT.md` (lancée par Bash, elle n'est jamais vue par G5). Le hash
(sha256 des octets du `PLAN.md` de l'unité, A3 = a3-plan) et la tentative (1 à la création, ancienne
tentative + 1 pour remplacer) sont calculés **par la commande**, jamais fournis par l'agent ;
l'écriture est atomique et ne traverse jamais un lien. Elle est agnostique de l'appelant (F8 =
f8-agnostique, Willy, AskUserQuestion session principale, 2026-09-30) : un juge qui a `Bash` la lance
lui-même, les autres livrent leur rapport au manager qui la lance. Artefact haché : le plan, pas le
livrable ; la vérification du hash à la clôture est la Phase 46 (limite : `--juge` est déclaratif).

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
`Agent`, fil principal, agent `plugin:`. Il rend visible la limite (i).

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
