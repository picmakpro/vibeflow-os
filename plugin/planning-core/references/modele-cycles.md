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
détecteur rend 0/1/2/3/64, le recalcul les traduit en un verdict `gsd`/`non-gsd`/`non-concluante` :

| Code détecteur | Sens | Verdict `detection_gsd()` | Écriture |
|---|---|---|---|
| 0 | moteur GSD actif | `gsd` | refusée |
| 1 | improbable (voir ci-dessous) — fail-closed, jamais une réimplémentation de ses priorités | `non-concluante` | **refusée** |
| **2** | **signalement de MIGRATION** (socle planning-core + signal de code, ex. `package.json`) | `non-concluante` | **refusée** — jamais assimilée au code 3 (audit B, lot 2 L1, décision du head sous délégation technique de Willy, session principale, 2026-09-28) |
| 3 | aucun moteur en place, terrain libre | `non-gsd` | autorisée |
| tout autre code (ex. 64, détecteur défaillant) | non concluant | `non-concluante` | refusée |

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

**Garde de fidélité d'énumération (P44-D-02a, lot 6, correction ciblée)** — audit du 2026-09-28,
mesuré par exécution : `vf_ws_enumerate` (workstream-policy.sh) émet un chemin absolu par ligne
pour chaque compartiment de `<planning>/workstreams/` ; ce contrat suppose que ni le nom d'un
compartiment ni le chemin du dossier de planning lui-même ne peuvent faire disparaître ou scinder
une ligne. Deux classes mesurées le brisent, TOUTES DEUX SILENCIEUSES côté détecteur (code 3
« terrain libre » sans aucune ligne stderr qui les distingue du cas nominal) : un nom de
compartiment portant un saut de ligne (la ligne imprimée se scinde en deux, aucune des deux ne
pointant vers un chemin qui existe) ; un nom de compartiment commençant par un point (le glob
`"$root"/*/` de `vf_ws_enumerate`, sans `dotglob`, ne l'expand jamais). Une troisième, plus large,
casse TOUTE l'énumération d'un coup : le chemin du dossier de planning lui-même porteur d'un saut
de ligne (chaque ligne émise porte ce préfixe). `recalc-planning.sh` ferme cette classe **côté
appelant**, avant même d'invoquer le détecteur : une fonction structurelle
(`_enumeration_workstreams_fidele`) compare ce qui est réellement sur le disque à ce que
l'énumération ligne-par-ligne pourrait restituer, sans jamais relire un `STATE.md` ni chercher un
marqueur — P44-D-01b interdit toute modification de `detect-gsd-engine.sh` ou
`workstream-policy.sh`, la propriété est donc obtenue entièrement en aval. Une entrée en lien
symbolique reste, elle, une exclusion DÉCLARÉE du détecteur lui-même (avertissement sur stderr) —
non masquante au sens de cette garde, volontairement pas retenue ici (ne pas sur-refuser un cas déjà
connu et accepté du système). Reste hors de portée de ce lot, et transmis au BACKLOG pour Samuel
(propriétaire de `workstream-policy.sh`, Phase 41.1) : la même primitive d'énumération, avec la même
classe de trou, alimente aussi `check-planning-state.sh` (compteur, pas un gate d'écriture).

## Arborescence

```
<lab>/.planning/
  PROJECT.md · REQUIREMENTS.md · config.json
  INDEX.md              (généré)
  STATE.md              (généré)
  cloture.log           (généré, ajout seul)
  .recalc-cache.json    (généré)
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
`.recalc-cache.json`. `baux/` et `missions/` ne sont pas parcourus par le recalcul en Phase 44.

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

## Hors de cette phase

Ce que la Phase 44 **ne fait pas** :

- **Aucun hook ni gate câblé** : le recalcul est une commande, pas un mécanisme de refus. Où il
  tournera (`SessionStart`, clôture, écriture) se décide en Phases 45/48 (P44-D-15).
- **Fichiers générés non protégés contre l'écriture à la main** : `G6` (protection de `STATE.md`,
  `INDEX.md`, `cloture.log`) arrive en Phase 45 (P44-D-15).
- Le drapeau `"phases_trace": false` du `config.json` d'un lab **n'est pas lu** par cette phase ;
  l'arbitrage d'usage (que doit rendre le traçage pour valoir son prix, à quelle frontière on le
  limite) est renvoyé au cadrage de la Phase 45 (P44-D-05).
- **Le socle métier v2 existant n'est pas retiré** : le remplacement est **additif** — les labs qui
  adhèrent à `cycles-v1` passent au moteur, les autres restent sur l'existant. Tout retrait de
  code existant (`guard-planning-updated.sh`, prose « scaffoldeur » du `SKILL.md`) arrive **avec
  les gates**, sous validation humaine (ADR-031 : suppression de code) (P44-D-01e).
- Les **baux** (`.planning/baux/`) : Phase 47.
- L'**injection de l'index** et le **pont mémoire** : Phase 48.
- Les **cycles récurrents** (`recurrent: true`, cadence, `bloqué par un tiers`) : spec §8, hors
  Phase 44.
- La **migration** des plannings existants au nouveau modèle, les **labs imbriqués**, le
  **renommage** d'un cycle : spec §11.3, hors Phase 44.
