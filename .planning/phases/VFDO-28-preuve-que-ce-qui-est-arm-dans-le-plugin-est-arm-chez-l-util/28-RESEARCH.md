# Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur — Recherche

**Researched:** 2026-08-10
**Domain:** mécanique interne des gates bash de ce dépôt · frontière de corpus entre gardes · contrat
d'install (`vibeflow-update.sh`) · job CI `lab-frais` · moteur `@opengsd/gsd-core` 1.10.0
**Confidence:** HIGH sur tout ce qui est daté d'un `fichier:ligne` ou d'une commande rejouée ce jour ;
LOW là où c'est écrit « non mesuré ».

> **Ce document est un COMPLÉMENT, pas un état de l'art.** L'état de l'art marché existe déjà et
> n'est pas reproduit ici : `.planning/research/2026-08-10-agents-paralleles-etat-de-l-art.md`
> (patterns de gouvernance, *as-installed testing*, fait plateforme « clés de settings de plugin
> ignorées en silence », dossier du futur ré-armement). Le présent fichier n'apporte que de la
> **mécanique fine mesurée sur disque**.
>
> `.planning/research/2026-08-05-parallelisation-execution.md` a été produite sur **gsd-core 1.9.1**.
> Le poste est en **1.10.0**. Aucun de ses faits moteur n'est recopié ici ; le §10 les **re-mesure**,
> et il en contredit un.

---

<user_constraints>
## User Constraints (from 28-CONTEXT.md)

### Locked Decisions

- **D-01 — Déclaration par l'artefact, doublée d'une liste close.** Le gate vérifie **deux**
  ensembles : (1) **le déclaré** — l'artefact (agent, skill) nomme lui-même sa précondition externe
  en frontmatter, sur le patron éprouvé `vf-mcp-consumer` / `vf-mcp-tools` + `inject-mcp-tools.sh` ;
  (2) **la liste close** — un petit ensemble de clés **déjà connues comme dangereuses**, vérifié en
  plus du déclaré, que l'artefact ait déclaré ou non. Point de départ : `isolation:` et les outils
  `mcp__*`. La liste s'élargit ligne par ligne, jamais par heuristique. *Reversibility: costly.*
- **D-01b — Le gate écrit ses propres bornes** dans son en-tête (ce que la liste close couvre, ce
  qu'elle ne couvre pas, pourquoi la déclaration reste faillible). *Reversibility: reversible.*
- **D-02 — Il bloque, et un `ensure-*.sh` déclaré vaut preuve de distribution.** Rouge par défaut
  (exit non nul, message nommant l'artefact, l'armement, la précondition manquante **et**
  `fichier:ligne`) ; vert si un `ensure-*.sh` runtime déclaré vérifie la précondition **chez
  l'utilisateur au moment de l'usage**. Ce choix évite explicitement d'ouvrir un véhicule de
  distribution de settings dans l'engine. *Reversibility: reversible.*
- **D-02b — Le mécanisme de liaison artefact ↔ `ensure-*.sh` relève du plan.** Seule contrainte de
  cadrage : la liaison doit être **explicite et vérifiable par machine**, jamais inférée d'une
  proximité de nom. *Reversibility: reversible.*
- **D-03 — Extension de `plugin/dev-orchestrator/scripts/check-capability-activation.sh`, pas un
  sixième gate.** Si l'extension fait franchir le seuil de `check-file-size.sh`, le découpage est une
  décision de plan — jamais un prétexte à créer un gate parallèle. *Reversibility: costly.*
- **D-04 — Le gate doit voir ce que l'install pose, pas seulement ce que le repo contient.** Une
  seule implémentation (D-03), exécutée **aussi** depuis le job CI `lab-frais`. Pattern :
  *as-installed testing*. *Reversibility: reversible.*
- **D-05 — Le gate, plus UN cas de preuve. Le reste part en backlog.**
- **D-06 — Le cas de preuve est #38 lui-même, rejoué.** `isolation: worktree` remis sans précondition
  distribuée ⇒ **ROUGE** ; désarmé ou précondition prouvée ⇒ **VERT**. Discriminance vérifiée dans
  les deux sens. **Attention au recouvrement** avec `check-agents.sh:528-549`, à instruire au plan.
  *Reversibility: reversible.*

### Claude's Discretion

- Le mécanisme exact de liaison artefact ↔ `ensure-*.sh` (D-02b) : nommage, frontmatter ou registre.
- Le nom exact de la clé de frontmatter portant la précondition déclarée (D-01), et son ajout aux
  clés `KNOWN` de `check-agents.sh:160`.
- Le contenu initial exact de la liste close (`isolation:` et `mcp__*` sont le plancher).
- Le découpage éventuel de `check-capability-activation.sh` s'il franchit le seuil de
  `check-file-size.sh`.
- La forme du test de discriminance et son emplacement dans les suites (D-06).
- L'articulation exacte avec `check-agents.sh` sur le cas `isolation:`.
- La distinction **précondition dure** vs **tuning à défaut sûr** dans le verdict.
- Découpage en plans, numérotation, nommage des artefacts produits.

### Deferred Ideas (OUT OF SCOPE)

- **Ré-armer `isolation: worktree`** — fermé tant qu'`open-gsd/gsd-core#3302` n'est pas levée. Ne pas
  rouvrir depuis cette phase, même si le gate rend vert.
- **Ouvrir un véhicule de distribution de settings dans l'engine** (au-delà de `hooks`) — écarté par
  D-02. Évaluer `userConfig` de `plugin.json` avant de construire quoi que ce soit. Phase distincte.
- **Solder les findings du gate sur l'existant** — écarté par D-05.
- **WINDOWS #4** (`inject-mcp-tools.sh` ne valide pas qu'un serveur MCP cité existe) — déjà repris au
  périmètre de la Phase 21, ne pas re-instruire ici.
- **Recette humaine `mcp__*`** (WINDOWS #3) — infaisable dans ce dépôt, se recette sur un lab iOS.
</user_constraints>

## Phase Requirements

`.planning/ROADMAP.md:2017` porte **`**Requirements**: TBD`** — aucun ID d'exigence n'est rattaché à
la Phase 28 à ce jour. Le planner devra les créer (ou assumer l'absence par écrit) ; aucune table de
correspondance ne peut être produite ici sans en inventer.

---

## Summary

Trois faits mesurés retournent des morceaux entiers du cadrage, et le plan doit les intégrer avant
d'écrire une ligne.

**Premier — la contrainte de taille de D-03 n'existe pas.** `check-file-size.sh` ne couvre que
`ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php` `[VERIFIED: plugin/software-architecture/scripts/check-file-size.sh:27]`.
`.sh` en est absent, et `check_one()` sort en silence sur tout fichier non-code
`[VERIFIED: …/check-file-size.sh:43]`. Les 443 lignes du gate ne franchissent donc **aucun seuil**,
et N lignes de plus non plus. La discrétion « découpage éventuel s'il franchit le seuil » est **sans
objet** — et le coût du découpage, s'il devait quand même arriver, est de **3 appelants** exactement
(§7), pas d'une migration de rosters.

**Deuxième — la frontière de corpus entre les deux gates est VIDE, et le lab frais est vide
d'armements.** `check-agents.sh` lit des frontmatters d'agents et rien d'autre
`[VERIFIED: plugin/conductor/scripts/check-agents.sh:628]` ; `check-capability-activation.sh` lit
trois artefacts (index généré, `config.json`, corpus doc) et **aucun agent**
`[VERIFIED: plugin/dev-orchestrator/scripts/check-capability-activation.sh:189-193]`. Leur
intersection est nulle : le recouvrement de D-06 est **partiel par construction**, et étendre
capability-activation aux frontmatters le fait **entrer dans le corpus de check-agents.sh** — c'est
l'arbitrage que le plan doit poser. Pire pour D-04 : la fermeture transitive de `conductor` installée
par `lab-frais` vaut **7 modules**, `dev-orchestrator` et `design-orchestrator` **en sont absents**
`[VERIFIED: bash plugin/_internal/resolve-deps.sh conductor, rejoué ce jour]` — donc ni le gate ni un
seul agent armé n'y sont posés. Un gate branché là **rendrait vert à vide**.

**Troisième — le moteur 1.10.0 a changé le terrain sous #38.** `gsd-tools` expose une commande
`worktree` avec les sous-commandes `base-check` et `set-baseref`
`[VERIFIED: node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree, rejoué ce jour]`, adossées à
`worktree-base-ref.cjs` (394 l.) qui **dégrade en séquentiel avec message** quand la précondition
manque, au lieu de casser en silence `[VERIFIED: ~/.claude/gsd-core/bin/lib/worktree-base-ref.cjs:96-100]`.
Une sonde **lecture seule et bidirectionnellement discriminante** existe donc déjà chez
l'utilisateur : mesurée ce jour, elle rend `{"shouldDegrade":true,"reason":"fork-ref-unknown"}` sans
le réglage et `{"shouldDegrade":false,"reason":"baseref-head"}` avec. C'est le corps tout fait d'un
`ensure-*` au sens de D-02.

**Primary recommendation :** poser la nouvelle règle **dans le `END` de l'awk unique** de
`check-capability-activation.sh`, en lui donnant sa **propre famille de fichiers** avec un troisième
discriminant `FILENAME` (le bloc générique l.355 avale aujourd'hui tout ce qui n'est pas l'index) ;
faire de la preuve « vert » un **mode `--verify` à trois exits** copié sur `inject-mcp-tools.sh`
(0/1/**3 indéterminé**) plutôt qu'une simple présence de fichier ; et, pour D-04, installer dans
`lab-frais` la fermeture de **`dev-orchestrator`** (9 modules, mesurée) et y poser un
`.planning/config.json`, sans quoi le gate sort 2 avant même de regarder.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Déclarer une précondition externe | **Artefact distribué** (frontmatter agent/skill) | — | Précédent mesuré : `vf-mcp-consumer` / `vf-mcp-tools` sont lus depuis le contenu du fichier, jamais depuis un flag `[VERIFIED: plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:24-25]` |
| Distribuer les scripts | **Engine d'install** (`copy_module_scripts`) | — | Glob pur, aucun roster : `"$module_dir/scripts/"*.sh` `[VERIFIED: plugin/_internal/vibeflow-update.sh:342-343]` |
| Poser un réglage de `settings.json` | **Personne** (hors `hooks`) | — | Seul canal mesuré : `merge_module_hooks()` → `merge-hooks.sh merge` `[VERIFIED: plugin/_internal/vibeflow-update.sh:274-330]`. Fonde D-02. |
| Vérifier la précondition chez l'utilisateur | **Script `ensure-*` runtime** | Moteur GSD (`gsd-tools worktree base-check`) | Le moteur fournit déjà la sonde discriminante (§10) |
| Juger armement ↔ précondition sur l'arbre source | **Gate CI `gates`** | — | `check-capability-activation.sh` y est invoqué nu `[VERIFIED: .github/workflows/ci.yml:331-342]` |
| Juger armement ↔ précondition **tel qu'installé** | **Job CI `lab-frais`** | — | Seul endroit qui installe dans un lab vierge `[VERIFIED: .github/workflows/ci.yml:620-638]` |
| Interdire une valeur de frontmatter | **`check-agents.sh`** | — | Garde `isolation:` déjà en place `[VERIFIED: plugin/conductor/scripts/check-agents.sh:546-549]` |

---

## 1. Anatomie de `check-capability-activation.sh`

**443 lignes** `[VERIFIED: awk 'END{print NR}' plugin/dev-orchestrator/scripts/check-capability-activation.sh, rejoué ce jour]`.
Chemin : `plugin/dev-orchestrator/scripts/check-capability-activation.sh`.

### 1.1 Structure du fichier

| Bloc | Lignes | Contenu |
|---|---|---|
| Docstring | 1-105 | Rôle, périmètre borné, 3 ensembles (T/B/M), 4 règles, doctrine des 3 états, comparaison par frontière, usage, env `VF_CAPACT_*`, codes de sortie |
| `set -uo pipefail` | 106 | Pas de `-e` |
| Ancres | 108-109 | `SELF_DIR`, `MODULE_DIR` |
| Résolution de racine du lab | 111-151 | `vf_capact_bounded_walk()` (133-141) + cascade à 3 paliers (142-151) |
| Parsing CLI | 153-170 | **`--path <dir>` et `-h|--help` UNIQUEMENT** |
| Cascade `REF_DIR` | 172-187 | 3 candidats, premier portant l'index gagne |
| Entrées | 189-193 | `INDEX`, `CONFIG`, `CORPUS` + surcharges `VF_CAPACT_*` |
| Préconditions | 195-207 | index illisible / config illisible / `jq` absent → **exit 2** |
| Découpage du corpus | 209-232 | `IFS=\n` + `set -f` (globbing désarmé), chaque fichier doit être lisible sinon exit 2 |
| État de config | 234-244 | **UN SEUL** appel `jq` |
| Chemins relatifs | 246-249 | Aucun chemin absolu dans les verdicts |
| **L'awk unique** | 251-439 | Tout le calcul |
| Sortie | 440-443 | `rc=$?`, rapport routé sur **stderr**, `exit "$rc"` |

### 1.2 Contrats de fonctions

**Shell**

- `vf_capact_bounded_walk(<départ>, <borne haute>)` `[VERIFIED: :133-141]` — imprime la première
  racine portant `.planning/config.json` en remontant depuis `<départ>`, **s'arrête à `<borne>`**,
  rend 1 si rien. C'est le remède mesuré au défaut « le gate lisait la config du projet voisin »
  (motif écrit l.111-132). **Réutilisable tel quel.**
- Cascade de racine, 3 paliers dans cet ordre `[VERIFIED: :119-151]` : (1) `--path` explicite, rien
  d'autre n'est consulté ; (2) ancre d'**installation** — `.claude` en `MODULE_DIR` ⇒ lab installé,
  sinon `git rev-parse --show-toplevel` depuis `SELF_DIR` ; (3) seulement si le palier 2 ne porte pas
  de config : remontée bornée depuis `$PWD`.

**awk** (toutes définies l.266-292)

| Fonction | Ligne | Contrat |
|---|---|---|
| `isid(c)` | 266 | `c` appartient-il à `[A-Za-z0-9_.-]` |
| `occ(hay, needle)` | 271-284 | Comptage **littéral à frontière** par `index()`, jamais regex. Une occurrence ne compte que si ses deux voisins sortent de l'alphabet des identifiants. Motif écrit l.75-80 : `workflow.code_review` est sous-chaîne de `workflow.code_review_command`. **Réutilisable tel quel.** |
| `trimcell(s)` | 285 | Ôte backticks, tabs, espaces d'une cellule de table |
| `iskey(s)` | 286 | `s` a-t-il la forme `a.b[.c]` |
| `state(k)` | 288-292 | **3 états** : `1` actif, `0` inactif, `-1` **indéterminé** (ni présent en config, ni défaut déclaré par l'index) |

### 1.3 Sources de vérité lues

Trois artefacts, énumérés en docstring l.22-25 et câblés l.189-193 :

1. `gsd-capabilities-index.md` — index **généré**, jamais édité (`VF_CAPACT_INDEX`).
2. `.planning/config.json` — config effective du lab (`VF_CAPACT_CONFIG`).
3. Corpus documentaire = `intent-routing.md` + `docs-flow.md` (`VF_CAPACT_CORPUS`, **un chemin par
   ligne**, séparateur saut de ligne et jamais espace, motif écrit l.95-98 et 209-214).

**Aucun agent, aucun skill, aucun `settings.json` n'est lu.**

Le repérage des tables de l'index se fait **par section** et jamais par arité `[VERIFIED: :316-352]` —
les libellés `S_ORPHANS` / `S_TOGGLES` / `S_BRICKS` (l.303-305) sont un **CONTRAT** avec
`build-gsd-capabilities-index.sh`, dit des deux côtés (`build-gsd-capabilities-index.sh:95` et
`:218`). Le contrat porte sur le **préfixe strictement ASCII** du titre, jamais le titre entier
(motif : le non-ASCII ne se comporte pas pareil en awk BSD et en gawk, l.298-302).

### 1.4 La lecture à trois états

`[VERIFIED: :67-73 (doctrine) et :288-292 (implémentation)]`

- Clé **présente** en config : active si sa valeur n'est ni `false` ni `null`. Une chaîne, un `0`,
  un `""`, un objet restent **actifs**. `jq 'paths'` et non `paths(scalars)` — motif écrit l.234-239.
- Clé **absente** : retombe sur le **défaut amont** déclaré par l'index (colonne 5 de la table des
  toggles, `"oui"`/`"non"` l.333-337).
- Ni l'un ni l'autre : **INDÉTERMINÉ**. Aucune règle ne se prononce, le rapport les compte à part
  (`nUnknown`, l.393 et 436). *« Un gate ne se replie pas sur un verdict qu'il ne peut pas tenir. »*

### 1.5 Le plancher anti-vert-à-vide (règle 1)

`[VERIFIED: :48-51 (doctrine) et :376-388 (implémentation)]` — `nT == 0`, `nB == 0` **ou** `nM == 0`
⇒ message nommant lequel + **exit 2**. Jamais de repli faible vers 0 (patron
`check-state-integrity.sh`). Le message de `nB == 0` dit explicitement « la règle 2bis serait
INERTE » (l.382) : le plancher nomme la **règle** rendue inerte, pas seulement l'ensemble vide.

### 1.6 Format exact des messages `fichier:ligne`

Quatre gabarits, tous en une ligne, tous terminés par la localisation :

```
[check-capability-activation] ECART regle 2 : le toggle « <k> » est INACTIF sur ce lab (<RELCFG>) mais cite hors marqueur conditionnel — <SRC>:<LNO>
[check-capability-activation] ECART regle 2bis : la brique « <b> » est promise par une entree de table alors que son toggle « <k> » est INACTIF sur ce lab (<RELCFG>) — aucun marqueur « <marker> » sur cette ligne — <SRC>:<LNO>
[check-capability-activation] ECART regle 3 : marqueur conditionnel nommant « <k> », toggle ABSENT de <RELIDX> — <MWHERE>
[check-capability-activation] ECART regle 3 : marqueur conditionnel PERIME — « <k> » est ACTIF sur ce lab (<RELCFG>), le marqueur doit disparaitre — <MWHERE>
```
`[VERIFIED: :402, :420, :428, :431]`

Invariants du gabarit, à reprendre tels quels pour la nouvelle règle :
préfixe `[check-capability-activation] ` · le mot `ECART` + le **numéro de règle** · l'objet fautif
entre `« »` · la **source de vérité qui fonde le verdict** entre parenthèses (`RELCFG` / `RELIDX`) ·
le `fichier:ligne` **en dernier**, après un `—` · **chemins relatifs** à la racine du lab
(`REL_INDEX` / `REL_CONFIG` l.248-249, motif écrit l.246-247 : un chemin absolu porte le nom de
compte et finit dans des rapports versionnés) · **ASCII sans accents dans l'awk** (les messages
shell l.197-231 portent les accents, ceux de l'awk n'en portent aucun — écart délibéré, la partie awk
transite par des environnements dont l'encodage varie).

Le rapport conforme (l.436) **nomme l'univers balayé** : nombre de toggles, dont inactifs et
indéterminés, nombre de briques, nombre de marqueurs, nombre de fichiers et de lignes de corpus.
La suite l'assert (`*"univers balaye"*`, `test-check-capability-activation.sh:163`).

### 1.7 Discriminance bidirectionnelle

`[VERIFIED: :62-65]` — la règle 3 est **la** raison pour laquelle le gate voit les deux sens : les
règles 2 et 2bis attrapent « la doc promet un geste inerte », la règle 3 attrape la dérive INVERSE
« le marqueur survit à l'activation ». Sans elle, une seule direction serait couverte. Deux
sous-cas : marqueur nommant un toggle **absent de l'index** (l.427-429) et marqueur **périmé**
(l.430-433).

### 1.8 Codes de sortie et CLI

| Code | Sens | Ligne |
|---|---|---|
| 0 | conforme, rapport nommant l'univers balayé | 436-437 |
| 1 | écart règle 2 / 2bis / 3 | 435 |
| 2 | **NON VÉRIFIABLE** : index absent/illisible/sans toggle/sans brique, corpus absent/sans marqueur, config absente ou imparsable, `jq` introuvable | 197, 201, 205, 224, 229, 242, 378, 382, 386 |
| 64 | usage (argument inconnu, `--path` sans valeur) | 157, 167 |

**Modes/flags : il n'y en a que deux.** `--path <dir>` et `-h|--help` `[VERIFIED: :153-170]`. Tout
autre argument sort en 64. **Pas de `--hook`, pas de `--strict`, pas de `--allow-empty`, pas de
`--file`** — contrairement à `check-agents.sh` (§3). Toute surcharge passe par l'environnement
`VF_CAPACT_INDEX` / `VF_CAPACT_CONFIG` / `VF_CAPACT_CORPUS`, et ces trois-là sont documentés comme
canaux de **testabilité**, pas de production.

`-h` imprime la docstring **en awk et non en `grep | sed`** `[VERIFIED: :162-164]` — motif écrit sur
place : la docstring porte des lignes `#` nues qu'un motif `^# ` perdrait, et *« le `grep` de ce
poste est proxifié »*. (À noter : `check-agents.sh:108` fait encore `grep '^# ' "$0" | sed`, et
`ensure-deps.sh` / `ensure-design-deps.sh` aussi — l'awk n'est appliqué que dans ce gate-ci.)

### 1.9 Où une règle nouvelle s'insère

**Le point d'insertion du verdict** est le `END`, entre la règle 3 (fin l.434) et le
`if (bad > 0) exit 1` (l.435). Une règle 4 s'y écrit à l'identique : boucle sur son ensemble, `print`
au gabarit du §1.6, `bad++`.

**Le point de friction réel n'est pas là — il est en entrée.** L'awk est invoqué
`awk '…' "$INDEX" "$@"` (l.439) et discrimine **par `FILENAME == IDX`** (l.318) : le premier fichier
est l'index, **tout le reste tombe dans le bloc générique du corpus** (l.355-374, sans condition).
Ajouter une troisième famille de fichiers (les frontmatters d'agents) impose donc :

1. de passer ces fichiers dans la liste d'arguments **et** de les distinguer par un troisième
   discriminant (une variable `ENVIRON` portant la liste, ou un marqueur d'ordre) ;
2. sinon les frontmatters seraient parcourus comme du corpus documentaire, `nLines` gonflerait, et
   les règles 2/2bis chercheraient des marqueurs conditionnels dans des frontmatters — **faux
   positifs silencieux**.

**Factorisable tel quel** (aucune réécriture) : `vf_capact_bounded_walk()` + cascade de racine
(:133-151) · cascade `REF_DIR` (:176-187) · découpage `IFS`/`set -f` (:209-232) · `isid`/`occ`/
`trimcell`/`iskey` (:266-286) · le gabarit de message (§1.6) · le plancher règle 1 (:376-388) · la
route rapport→stderr + `exit "$rc"` (:440-443).

**NON factorisable** : `state()` (:288-292) et l'ensemble `cfg`/`DEF` dont il dépend — ils sont
adossés à l'index de capabilities et à `.planning/config.json`. Un armement de frontmatter **n'a pas
d'index équivalent** : sa source de vérité est le fichier lui-même. La nouvelle règle a donc besoin
de **sa propre notion d'état** (« déclaré / non déclaré / prouvé par un ensure-* »), pas d'un
emprunt à `state()`. C'est le point où le plan doit résister à la tentation de la réutilisation.

**Contrainte de dépendance à conserver en tête** : le gate exige `jq` (:204-207 → exit 2). ADR-054
prescrit « pas de `jq` obligatoire » `[CITED: .planning/PROJECT.md:74 ; docs/ADR.md:601]` — la dette
existe déjà et est assumée, mais **une règle nouvelle ne doit pas en ajouter une deuxième** : lire un
frontmatter YAML se fait en awk, jamais en `jq` ni en `yq`.

---

## 2. Seuil de `check-file-size.sh` — la contrainte n'existe pas

`plugin/software-architecture/scripts/check-file-size.sh` (109 lignes).

- Seuils : `WARN="${VF_ARCH_WARN:-250}"`, `BLOCK="${VF_ARCH_BLOCK:-300}"`
  `[VERIFIED: plugin/software-architecture/scripts/check-file-size.sh:25-26]`.
- **Périmètre** : `CODE_EXT_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php)$'`
  `[VERIFIED: …:27]` — citation verbatim. **`sh` n'y figure pas.**
- Application : `check_one()` fait `is_code_file "$f" || return 0` `[VERIFIED: …:43]`, et
  `is_code_file()` est `[[ "$1" =~ $CODE_EXT_RE ]]` `[VERIFIED: …:33]`. Un `.sh` est donc **ignoré
  silencieusement**, jamais compté, jamais averti.
- Le gate jumeau `guard-file-size.sh` déclare le **même périmètre** : *« Meme perimetre que
  check-file-size.sh : seuls les fichiers de code comptent »*
  `[VERIFIED: plugin/software-architecture/scripts/guard-file-size.sh:63]`, et *« Fichier non-code →
  allow »* `[VERIFIED: …guard-file-size.sh:19]`.
- ADR-029 borne **agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens**
  `[CITED: CLAUDE.md §Conventions transverses]` — **rien sur les scripts**.

**Conclusion mesurée :** 443 lignes ne franchissent aucun seuil, et 443 + N non plus, quel que soit
N. La discrétion « découpage éventuel si l'extension franchit le seuil de `check-file-size.sh` » est
**sans objet**. Si le plan veut découper, il devra le motiver par la lisibilité — pas par un gate.

---

## 3. `check-agents.sh` — garde `isolation:`, clés `KNOWN`, et la frontière de corpus

`plugin/conductor/scripts/check-agents.sh` — **680 lignes**
`[VERIFIED: awk 'END{print NR}', rejoué ce jour]`. Architecture : un wrapper bash (l.1-140) qui
exporte des `VF_*` et exécute un heredoc **Python** (l.140-680).

### 3.1 (a) La garde `isolation:`

`[VERIFIED: plugin/conductor/scripts/check-agents.sh:528-549]` — code verbatim :

```python
iso = fm.get("isolation")
# … 17 lignes de motif (l.529-545) …
if iso == "worktree":
    errors.append(f"{base} : isolation worktree interdite dans un agent distribue (issue #38) — le worktree fork depuis la branche par defaut, la precondition worktree.baseRef n'est pas distribuee, et rien ne ramene les commits. L'isolation est une decision de dispatch du manager.")
elif iso:
    errors.append(f"{base} : isolation invalide ({iso}) — aucune valeur n'est admise dans un agent distribue (voir issue #38)")
```

- **Ce qu'elle interdit exactement** : `worktree` **et toute autre valeur non vide**. La branche
  `elif iso:` (l.548) ferme le champ entièrement — pas seulement `worktree`. Un `isolation: none`
  serait aussi une erreur.
- **Corpus** : tout fichier passé à `check_file()`, c'est-à-dire `glob.glob(agents_dir + "/*.md")`
  moins `NOT_AGENTS = {"contracts.md", "README.md", "AGENTS.md"}`
  `[VERIFIED: :628-629 et :165]`, ou le fichier unique de `--file` `[VERIFIED: :622-626]`.
- **Code** : `errors` ⇒ `sys.exit(1)` `[VERIFIED: :673-677]`. **Bloquant en tous modes sauf
  `--hook`**, qui imprime et sort 0 `[VERIFIED: :655-666]`.
- **Condition de levée écrite sur place** (l.544-545) : *« Lever ce gate demande de distribuer la
  precondition ET de prouver le retour des commits — pas de supprimer ces lignes. »*
- État mesuré du corpus : **0 agent** ne porte `isolation:` aujourd'hui
  `[VERIFIED: balayage awk du frontmatter des 31 fichiers, rejoué ce jour]`.

### 3.2 (b) Les clés `KNOWN` — et une correction du cadrage

`[VERIFIED: plugin/conductor/scripts/check-agents.sh:158-160]` — liste verbatim, 20 clés :

```python
KNOWN = {"name", "description", "tools", "disallowedTools", "model", "permissionMode",
         "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "effort",
         "isolation", "color", "initialPrompt", "vf-internal", "vf-mcp-consumer", "vf-mcp-tools"}
```

(19 littéraux distincts + le commentaire l.153-157 qui documente les 3 conventions VibeFlow :
`vf-internal`, `vf-mcp-consumer`, `vf-mcp-tools`.)

**Mécanisme d'ajout** : éditer ce littéral, point. Aucun registre externe, aucun fichier de config.

**⚠ CORRECTION FACTUELLE DU CADRAGE.** `28-CONTEXT.md:63-64` affirme que la nouvelle clé *« devra
être admise dans ses clés `KNOWN`, sinon `--strict` la refusera »*. **Mesuré : c'est faux.**

```python
for k in fm:
    if k not in KNOWN:
        warnings.append(f"{base} : champ inconnu du runtime — {k} (typo ? champ invente ? verifier la doc)")
```
`[VERIFIED: :618-620]`

C'est un `warnings.append` **nu** — jamais le patron `(errors if strict else warnings)` utilisé
ailleurs pour les classes promues par `--strict` (skill introuvable :575 ; barrière `memory:` +
`tools:` :616). Et `--strict` ne promeut aucun warning en bloc : seul `n_err` déclenche `sys.exit(1)`
`[VERIFIED: :673-677]`, sinon `sys.exit(0)` avec le compte de warnings `[VERIFIED: :678-679]`.

**Effet réel d'une clé non déclarée**, donc : (1) une ligne `⚠` par agent porteur à chaque appel
explicite et à chaque run CI — **la CI reste VERTE** ; (2) une ligne compacte au SessionStart via
`--hook` `[VERIFIED: :661-665]`. C'est du bruit, pas un blocage. L'ajout à `KNOWN` reste **fortement
souhaitable** (D-21 : le hook parle dès qu'il y a un warning), mais ce n'est **pas** un prérequis
bloquant, et le plan ne doit pas le séquencer comme tel.

### 3.3 Le fait décisif : où passe la frontière de corpus

| | `check-agents.sh` | `check-capability-activation.sh` |
|---|---|---|
| Lit | frontmatters d'agents `*.md` d'un `agents_dir` `[:628]` | index généré + `.planning/config.json` + corpus doc `[:189-193]` |
| Ne lit **jamais** | `.planning/config.json`, l'index de capabilities, aucun `settings.json` | **aucun agent, aucun skill, aucun `settings.json`** |
| Granularité du verdict | par fichier agent | par toggle / par brique / par ligne de corpus |
| Modes | `--strict`, `--hook`, `--file`, `--allow-empty`, `--agents-dir=`, `--skills-dir=`, `--third-party-prefix=`, `--resolve-agents=`, `--agent-registry-dir=` `[:23-35]` | `--path`, `-h` `[:86]` |
| Exits | 0 / 1 / 3 (indéterminé) `[:74-76]` | 0 / 1 / 2 (non vérifiable) / 64 (usage) `[:100-105]` |
| Langage de calcul | Python en heredoc `[:140]` | awk `[:265]` |

**Intersection de corpus : VIDE.**

**Conséquences pour D-06 :**

1. Le recouvrement est **partiel par construction**, pas total. `check-agents.sh` porte la règle
   *« aucune valeur d'`isolation:` n'est admise »* — une règle **de forme**, sur un champ. Le nouveau
   gate porterait *« cet armement n'a pas de précondition distribuée »* — une règle **de relation**,
   entre un artefact et un dispositif de vérification. Les deux peuvent rougir sur le même fichier
   sans dire la même chose.
2. Mais la **population** se recouvrirait, elle, intégralement dès lors que le nouveau gate lit des
   frontmatters d'agents. Le test de discriminance de D-06 devra donc **isoler le nouveau gate** :
   fixture synthétique passée **au seul nouveau gate**, jamais un run croisé où l'exit 1 pourrait
   venir de `check-agents.sh`.
3. L'arbitrage que le plan doit écrire : `check-agents.sh:546-549` est aujourd'hui la garde
   **complète et suffisante** sur `isolation:`. Si le nouveau gate la re-porte, l'une des deux doit
   déclarer par écrit pourquoi l'autre subsiste (D-06 l'exige). Piste mesurée : `check-agents.sh`
   interdit **inconditionnellement** (levée = distribuer la précondition ET prouver le merge-back,
   l.544-545), le nouveau gate juge **conditionnellement** (levée = prouver la précondition). Ce sont
   deux paliers, pas un doublon — mais il faut l'écrire.

**Populations mesurées ce jour** : 25 fichiers dans `plugin/*/agents/*.md`, 6 `plugin/*/AGENT.md`
= **31 agents distribués** (`plugin/conductor`, `design-orchestrator`, `dev-orchestrator`,
`kpi-analyst`, `skill-creator`, `validator` pour les AGENT.md). 24 `SKILL.md`.
Modules avec dossier `agents/` : `business-pilot-bundle` (5), `content-bundle` (5),
`design-orchestrator` (3), `dev-orchestrator` (4), `growth-bundle` (5), `mobile-test-team` (3).
`[VERIFIED: ls + awk END{NR}, rejoué ce jour]`

**Câblage CI de `check-agents.sh` — trois étapes distinctes** `[VERIFIED: .github/workflows/ci.yml:242, :267, :288]` :
(1) boucle sur `plugin/*/agents` en `--strict` ; (2) boucle sur `plugin/*/AGENT.md` en
`--strict --file` — étape ajoutée précisément parce que *« la population réelle est de 31 fichiers,
pas 25 »* (commentaire l.267-278) ; (3) monde fermé `--resolve-agents=strict` sur l'union.
**Leçon directement applicable** : un gate nouveau qui balaierait `plugin/*/agents` seul **raterait 6
fichiers sur 31** — le défaut est documenté sur place, ne pas le rejouer.

**Asymétrie agent/skill à trancher** : aucun script du dépôt ne linte les **clés** de frontmatter
d'un `SKILL.md`. Les 5 scripts qui lisent des `SKILL.md`
(`check-agents.sh`, `check-debug-research.sh`, `check-overlaps.sh`, `build-gsd-index.sh`,
`check-capability-activation.sh` `[VERIFIED: grep -rln 'SKILL.md' sur plugin/*/scripts/*.sh, rejoué ce jour]`)
le font pour résoudre un `name:`, pas pour valider un jeu de clés. Donc, si D-01 fait porter la clé
de précondition à des **skills** aussi, elle ne sera contrôlée par **personne** — à écrire dans les
bornes du gate (D-01b) ou à couvrir par la nouvelle règle elle-même.

---

## 4. Le contrat « ensure-* »

### 4.1 `plugin/dev-orchestrator/scripts/ensure-deps.sh` (479 lignes)

| Propriété | Valeur | Preuve |
|---|---|---|
| Objet | auto-install non-interactif de GSD (`npx @opengsd/gsd-core`) + Superpowers (`claude plugin install`) | `:2-6` |
| `set` | `set -uo pipefail` — **pas de `-e`** (« certaines détections doivent pouvoir échouer sans tuer le script ») | `:50-51` |
| Signature CLI | `--migrate-engine`, `-h|--help`. **Tout argument inconnu est IGNORÉ avec une ligne log**, jamais un exit non-zéro (« un rejet strict casserait un appelant non recensé ») | `:41-46` |
| Env | `VF_ENSURE_DRY_RUN`, `VF_ENSURE_AUTO_MAP`, `VF_SCOPE` (user\|project\|local), `VF_ENSURE_FORCE`, `VF_ENSURE_MIGRATE_ENGINE` | `:19-40` |
| Ce qu'il vérifie | présence du moteur GSD via **le fichier `VERSION`** du layout (jamais le PATH — « piège n°1 ») + présence de Superpowers | `:6-9`, `:75-88` |
| En échec | **jamais d'échec silencieux** : prérequis absent ⇒ étapes manuelles affichées, **exit 0** | `:47-48` |
| Sortie | tout sur **stderr** (`log()`) | `:99-101` |
| Idempotence | 2e run consécutif = no-op (mode normal non forcé) | `:47` |

### 4.2 `plugin/design-orchestrator/scripts/ensure-design-deps.sh` (387 lignes)

| Propriété | Valeur | Preuve |
|---|---|---|
| Objet | **présence ET ACTIVATION** des 4 plugins de la chaîne design. Un plugin installé mais désactivé est traité comme manquant et reçoit un `claude plugin enable` scopé | `:5-11` |
| Trou fermé | *« `claude plugin list \| grep <nom>` (seule détection outillée précédente du repo, cf. `ensure-deps.sh`) est aveugle à l'état enabled/disabled — un plugin désactivé matche le grep et passe pour présent »* | `:8-11` |
| Autonomie | **ne source, n'appelle et ne suppose présent AUCUN artefact d'un autre module** — duplication délibérée assumée par écrit | `:13-18` |
| **Contrat de sortie** | **toujours exit 0, SAUF `VF_SCOPE` invalide (exit 1, avant tout effet de bord)** | `:59-61` |
| Sortie | **TOUT sur stderr**, jamais stdout ; l'appelant qui veut le silence passe `--quiet`, il ne doit **pas** rediriger stderr | `:63-66` |
| Env | `VF_DESIGN_ENSURE_DRY_RUN`, `VF_DESIGN_ENSURE_FORCE`, `VF_SCOPE` (validé **en tête**, avant toute définition de `main`) | `:34-45`, `:98-105` |
| Nommage | préfixe `VF_DESIGN_` délibérément **non partagé** avec `VF_ENSURE_*` : les scripts des deux modules atterrissent **à plat dans le même `scripts/`** chez l'utilisateur | `:46-50` |
| Jumelle documentaire | la table des 4 plugins est la jumelle de `references/design-toolchain.md` §Vérification de présence | `:20-23` |

### 4.3 Moment d'invocation — **la découverte qui compte pour D-02**

| Script | Appelant mesuré | Nature du câblage |
|---|---|---|
| `ensure-design-deps.sh` | `plugin/_internal/vibeflow-update.sh:581-586` — hook post-install du module, `--quiet`, best-effort | **MACHINE** (l'engine, à l'install) |
| `ensure-design-deps.sh` | `plugin/design-orchestrator/AGENT.md:59` (« au premier contact ») et `:193` (recensement) | **PROSE** (instruction d'agent) |
| `ensure-deps.sh` | `plugin/conductor/skills/vf-update/SKILL.md:113` (`--migrate-engine`, sous confirmation humaine), `:30`, `:115` | **PROSE** (instruction de skill) |
| `ensure-deps.sh` | `plugin/conductor/skills/vf-calibrate/SKILL.md:84` | **PROSE** |
| `ensure-deps.sh` | `plugin/dev-orchestrator/README.md:187` (« Au premier contact, l'agent lance `ensure-deps.sh` ») | **PROSE, et même pas une instruction — un README** |

`[VERIFIED: rtk proxy grep -rn 'ensure-deps.sh\|ensure-design-deps.sh' sur tout le dépôt, rejoué ce jour]`

**Contre-vérification : aucun des 6 fragments `hooks/hooks.json` ne lance un `ensure-*`.**
Fragments mesurés : `conductor`, `consolidator`, `dev-orchestrator`, `infrastructure-audit`,
`planning-core`, `software-architecture`. Celui de `dev-orchestrator` lance quatre scripts —
`check-dev-bootstrap.sh --hook`, `discover-unintegrated-docs.sh --hook`, `check-doc-drift.sh --hook`,
`check-gsd-config.sh --hook` — et **pas `ensure-deps.sh`**
`[VERIFIED: plugin/dev-orchestrator/hooks/hooks.json, lu ce jour]`.

**Conséquence directe pour D-02, et elle est structurante :** *« un `ensure-*.sh` runtime déclaré
vérifie la précondition chez l'utilisateur au moment de l'usage »* — mesuré, **un seul des deux le
fait par câblage machine**, et c'est **à l'install**, pas au moment de l'usage. L'autre repose sur de
la prose d'agent/skill. Un gate qui accepterait « un `ensure-*.sh` est déclaré » comme preuve
bénirait donc une **promesse en prose** — c'est-à-dire exactement le mode d'échec de #38, un cran
plus loin (la précondition était identifiée, écrite, arbitrée… et personne ne la posait).

**Le plan doit donc exiger un câblage, pas un nom.** Trois formes de câblage sont **vérifiables par
machine** dans ce dépôt, par ordre de force décroissante :

1. une entrée dans un `hooks/hooks.json` de module (grep-able, distribuée par `merge-hooks.sh`) ;
2. un appel dans `vibeflow-update.sh` (hook post-install, patron `:581-586`) ;
3. l'existence d'un mode `--verify` **à trois exits** dans le script lui-même, exerçable par le gate
   ou par la CI (patron `inject-mcp-tools.sh`, §5).

La forme (3) est la seule qui prouve quelque chose **au moment de l'usage** et qui soit exerçable
depuis le gate lui-même. C'est la recommandation.

### 4.4 Registre / roster — il n'y en a aucun

- `module.json` **ne liste aucun script**. Mesuré sur `dev-orchestrator`, `conductor`,
  `design-orchestrator` : les clés sont `name`, `version`, `type`, `description`, `requires`, plus
  `mandatory` pour `conductor` `[VERIFIED: cat plugin/*/module.json, rejoué ce jour]`.
- La distribution est un **glob** : `copy_module_scripts()` copie `"$module_dir/scripts/"*.sh`,
  `*.mjs`, `*.js` (l.342-343), les `*.txt` (l.351-352), et `scripts/tests/*.sh` +
  `scripts/tests/fixtures/*` (l.354-358), le tout vers `$TARGET_ROOT/scripts/`
  `[VERIFIED: plugin/_internal/vibeflow-update.sh:337-360]`. Le désinstall est le miroir exact
  (`:707-725`).
- **Poser un `.sh` dans `plugin/<module>/scripts/` suffit donc à le distribuer.** Aucune inscription
  nulle part. (C'est le pendant du diagnostic Phase 24 « un script neuf n'est dans aucun roster » :
  la distribution est automatique, c'est **l'invocation** qui n'a pas de roster.)
- **Convention de nommage observée** (préfixe = rôle), stable sur les 10 modules à scripts :
  `ensure-*` = bootstrap idempotent non-interactif · `check-*` = gate · `build-*` = générateur
  d'artefact · `guard-*` = hook `PreToolUse` · `discover-*` / `inject-*` = geste ponctuel.
  **C'est une convention, pas un contrat machine** — rien ne la vérifie.

---

## 5. Le patron de précondition déclarée : `inject-mcp-tools.sh`

`plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` — **541 lignes**
`[VERIFIED: awk 'END{print NR}', rejoué ce jour]`.

### 5.1 Comment la déclaration est écrite

Deux clés de frontmatter, deux grammaires :

- **`vf-mcp-consumer: true`** — sélecteur booléen, *« analogue à `mandatory:` / `vf-internal:` »*
  `[VERIFIED: inject-mcp-tools.sh:13-14]`. L'agent reçoit `mcp__<serveur>__*` pour chaque serveur
  déclaré par le lab.
  Porteurs mesurés (4) : `plugin/dev-orchestrator/agents/vf-coder.md:9`,
  `plugin/mobile-test-team/agents/vf-app-fixer.md:9`,
  `plugin/mobile-test-team/agents/vf-test-orchestrator.md:8`,
  `plugin/mobile-test-team/agents/vf-test-runner.md:9`.
- **`vf-mcp-tools: <serveur>:<outil1>,<outil2>,…`** — allowlist **nommée**, l'agent reçoit
  uniquement `mcp__<serveur>__<outil>`, **jamais le joker**
  `[VERIFIED: inject-mcp-tools.sh:16-25]`.
  Porteur mesuré (1, unique) : `plugin/dev-orchestrator/agents/vf-reviewer.md:10` —
  verbatim : `vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean`.

Cohabitation : un fichier portant les **deux** est traité en mode nommé (le plus restrictif
l'emporte, moindre privilège), avec une ligne de log qui le signale `[VERIFIED: :21-23]`.

### 5.2 Comment elle est lue

*« Ce mode est déclenché par le CONTENU du fichier cible, jamais par un flag — aucun appelant n'a
besoin d'être modifié »* `[VERIFIED: :24-25]`. Le balayage en mode dossier reste **filtré par le
flag** ; `--force` traite un fichier hors plugin `[VERIFIED: :63-64]`.

### 5.3 Ce qui la valide — et ce qui ne la valide pas

- **Validé** : le **nom du serveur** cité est confronté à l'**union** de deux sources — `.mcp.json`
  projet et la clé `mcpServers` de `~/.claude.json` (scope user) `[VERIFIED: :27-45]`. Serveur
  inconnu de toutes les sources ⇒ WARNING, **ERROR bloquante en `--strict`**
  `[VERIFIED: :72-79]`. Correspondance de nom **insensible à la casse, en égalité stricte** (jamais
  un motif ni une sous-chaîne), et le token injecté reprend l'orthographe du `.mcp.json` du lab, pas
  celle du frontmatter `[VERIFIED: :18-21]`.
- **NON validé, et dit sur place** (section « HONNÊTETÉ (D-03) », l.47-55) : les **noms d'outils**
  déclarés (`test_sim`, `build_sim`) ne sont **jamais** confrontés à un serveur vivant — aucune
  requête, aucun lancement de process. *« Un serveur CONNU peut encore porter des noms d'outils
  fantaisistes non détectés par ce script. »* C'est WINDOWS #3, laissé ouvert.
- **Le mode `--verify` est le patron à copier pour D-02** `[VERIFIED: :80-91]` : lecture seule
  stricte, *« Il RELIT, il COMPARE, il RAPPORTE — il ne réécrit JAMAIS rien, et ne rejoue JAMAIS
  `--force` à la place de l'appelant (réparer silencieusement détruirait exactement le signal que ce
  mode existe pour produire) »*. Exits dédiés : **0 conforme · 1 serveur manquant · 3 INDÉTERMINÉ**
  (pas de ligne `tools:`, aucun serveur déclaré par aucune source, aucune cible retenue, ou `python3`
  absent — *« ce dernier cas sort en succès best-effort dans les AUTRES modes, mais JAMAIS en
  `--verify` : un faux vert serait pire que l'absence de vérification »*).

### 5.4 Appelants

Déclarés en en-tête `[VERIFIED: :96-98]` : `vibeflow-update.sh` (hook post-install, agents flaggés) ·
`ensure-deps.sh` (gsd-executor, `--force` post-install GSD puis `--verify`) · `/vf-calibrate`.
Vérifié côté engine : résolution du script `plugin/_internal/vibeflow-update.sh:252-253`, log
« injection MCP best-effort » `:270`.

### 5.5 Le contre-fait à retenir

**Ce dépôt n'a pas de `.mcp.json`** `[VERIFIED: ls .mcp.json → No such file, rejoué ce jour]`. Donc,
sur CE repo, le déclaré `vf-mcp-tools: XcodeBuildMCP:…` de `vf-reviewer.md:10` **n'est prouvé par
rien** : `--verify` y sortirait 3 (INDÉTERMINÉ). C'est très exactement le finding que D-05 renvoie en
backlog — et c'est aussi le cas d'usage qui montre pourquoi la nouvelle règle a besoin d'un état
**indéterminé** distinct du rouge : « armé, non prouvé, non vérifiable ici » ≠ « armé sans
précondition ».

---

## 6. Job CI `lab-frais`

`.github/workflows/ci.yml` fait **652 lignes** et porte **3 jobs** : `tests:17`, `gates:234`,
`lab-frais:620` `[VERIFIED: awk sur ci.yml, rejoué ce jour]`. `lab-frais` est **le dernier job du
fichier**, il se termine l.652.

### 6.1 Ce qu'il installe, où, avec quoi

`[VERIFIED: .github/workflows/ci.yml:620-638]` :

```yaml
lab-frais:
  name: Lab frais (install baseline + Gate C — leçon UAT 2026-07-25, F2)
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Installer la baseline dans un lab vierge avec le vrai engine
      run: |
        set -eu
        LAB="$(mktemp -d)"
        echo "LAB=$LAB" >> "$GITHUB_ENV"
        cd "$LAB" && git init -q
        closure=$(cd "$GITHUB_WORKSPACE" && bash plugin/_internal/resolve-deps.sh conductor)
        for m in $closure; do
          VIBEFLOW_CACHE="$GITHUB_WORKSPACE/plugin" VF_SCOPE=project \
            bash "$GITHUB_WORKSPACE/plugin/_internal/vibeflow-update.sh" install "$m"
        done
```

- **Répertoire** : un `mktemp -d` frais, `git init -q`, exporté en `$LAB` via `$GITHUB_ENV`.
- **Environnement** : `ubuntu-latest`, `actions/checkout@v4` **seul**. Pas de `setup-node`, **pas
  d'assertion `jq` / `python3`** — contrairement au job `tests` qui les vérifie explicitement
  `[VERIFIED: ci.yml:23-27]`.
- **Scope** : `VF_SCOPE=project` ⇒ les artefacts atterrissent sous `$LAB/.claude/`.
- **Fermeture transitive mesurée ce jour** (`bash plugin/_internal/resolve-deps.sh conductor`, rc=0) :
  `audit-architecture conductor consolidator infrastructure-audit planning-core skill-creator validator`
  — **7 modules**.

### 6.2 Ce qu'est « Gate C »

`[VERIFIED: .github/workflows/ci.yml:640-652]` — une seule étape sous `set -eu`, `cd "$LAB"` :

1. `bash .claude/scripts/check-agents.sh --strict` ;
2. `bash .claude/scripts/check-registres.sh --strict --allow-empty`, avec **tolérance rc ∈ {0, 3}**
   et échec explicite sur toute autre valeur — commentaire l.647-648 : *« un lab tout juste installé
   n'a pas encore de `.planning` ; le gate doit rendre un verdict propre (0 ou 3+message), jamais un
   crash »* ;
3. `grep -q "guard" .claude/settings.json` — les hooks de gouvernance sont bien mergés.

### 6.3 Ce qui est disponible dans ce contexte — et les trois blocages

`$GITHUB_WORKSPACE` (l'arbre source) **reste accessible** pendant tout le job : Gate C ne fait que
`cd "$LAB"`, il ne détruit pas le checkout. Les deux mondes coexistent. Mais :

**Blocage 1 — le gate n'est pas installé dans le lab frais.**
`check-capability-activation.sh` vit dans `plugin/dev-orchestrator/scripts/`, et `dev-orchestrator`
**n'est pas dans la fermeture de `conductor`** (mesuré §6.1). Il n'atterrit donc pas dans
`$LAB/.claude/scripts/`. Deux voies :
- (a) installer aussi la fermeture de `dev-orchestrator` — **mesurée ce jour** :
  `audit-architecture conductor consolidator design-orchestrator dev-orchestrator infrastructure-audit planning-core skill-creator validator` (**9 modules**) ;
- (b) l'invoquer depuis `$GITHUB_WORKSPACE` en le pointant sur `$LAB` (`--path "$LAB"` + surcharges
  `VF_CAPACT_*`).
**(a) seule respecte *as-installed testing*** — (b) teste l'arbre source contre un lab, ce qui est
précisément le geste que le pattern condamne.

**Blocage 2 — le lab frais n'a aucun armement à juger.**
Aucun module de la fermeture `conductor` n'a de dossier `agents/` ; les seuls agents posés viennent
des `AGENT.md` de `conductor`, `skill-creator` et `validator` — **3 agents**
`[VERIFIED: recensement par module, rejoué ce jour]`. Et **aucun des 31 agents du dépôt ne porte
`isolation:`** ; les 5 seuls porteurs d'un armement `mcp__`/`vf-mcp-*` sont `vf-coder`,
`vf-reviewer` (dev-orchestrator) et les 3 de `mobile-test-team` — **tous hors fermeture `conductor`**.
Un gate branché là aujourd'hui **rendrait vert à vide**. Deux conséquences :
- le **plancher règle 1** (§1.5) est obligatoire sur la nouvelle règle : corpus d'artefacts vide ⇒
  exit 2 « NON VÉRIFIABLE », jamais 0 ;
- la fermeture `dev-orchestrator` (9 modules) est le **minimum** pour que le lab frais contienne
  2 des 5 agents armés (`vf-coder`, `vf-reviewer`). Les 3 de `mobile-test-team` resteraient hors
  champ (le module n'est dans aucune fermeture mesurée).

**Blocage 3 — pas de `.planning/config.json` dans le lab frais.**
Le commentaire de Gate C le dit (l.647-648), et `check-capability-activation.sh:200-203` sort **2
(NON VÉRIFIABLE)** sans configuration lisible. **Le gate, tel quel, ne peut pas tourner dans le lab
frais.** Le plan doit soit y poser un `.planning/config.json` minimal, soit rendre la nouvelle règle
indépendante de `CONFIG` — et dans ce cas déplacer la précondition `CONFIG` pour qu'elle ne bloque
que les règles qui en ont besoin (aujourd'hui elle est globale, l.200-203).

**Ce que l'install pose — disposition à connaître** `[VERIFIED: plugin/_internal/vibeflow-update.sh]` :
scripts **à plat** dans `$LAB/.claude/scripts/` (`:342-343`) · `AGENT.md` → `$LAB/.claude/agents/<mod>.md`
(`:477-480`) · références d'un module agent → `.claude/agents/<mod>-references/` (`:521-523`) ·
tests → `.claude/scripts/tests/` (`:354-358`) · hooks mergés dans `.claude/settings.json` (`:274-330`).
**C'est exactement la disposition que la cascade `REF_DIR` du gate connaît déjà**
(`check-capability-activation.sh:177-181`, candidat n°2), et que le cas T14d (e) de la suite exerce
sans surcharge (`test-dev-orchestrator.sh:1494-1503`).

### 6.4 Comment une étape s'y ajoute

Une entrée `- name: … / run: |` dans `steps:`, après Gate C. `$LAB` est disponible via `$GITHUB_ENV`.
Attention : Gate C tourne sous `set -eu` **dans son propre `run`** — une nouvelle étape a son propre
shell et doit redéclarer `set -eu` et son `cd "$LAB"`.

---

## 7. Rosters : les appelants de `check-capability-activation.sh`

Balayage exhaustif du dépôt hors `.git`
`[VERIFIED: rtk proxy grep -rn 'check-capability-activation' sur *.sh *.yml *.md *.json, rejoué ce jour]`.
**Trois appelants exécutables, pas un de plus :**

| # | Appelant | Ligne | Forme |
|---|---|---|---|
| 1 | `.github/workflows/ci.yml` — job `gates` | `:331-342` | `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` — **invocation nue**, aucune surcharge `VF_CAPACT_*` |
| 2 | `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — cas T14d (d) | `:1476-1492` | avec `VF_CAPACT_INDEX` + `VF_CAPACT_CORPUS` sur le corpus réel |
| 3 | idem — cas T14d (e) | `:1494-1503` | `env -u VF_CAPACT_*` — **la cascade complète, telle qu'elle tourne chez l'utilisateur** |
| (4) | `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | `:35`, `:131-146`, `:421-427` | sa suite dédiée (630 l.), fixtures synthétiques + un cas « lab installé » qui copie le script dans `$LAB/.claude/scripts/` |

**Aucun hook** — les 6 fragments `hooks/hooks.json` mesurés ne le citent pas.
**Aucun agent, aucun skill.** Toutes les autres occurrences sont documentaires (CHANGELOG racine et
module, README.md/README.fr.md, ROADMAP, `gsd-capabilities-index.md:190`,
`build-gsd-capabilities-index.sh:95` et `:218` qui déclarent le contrat de sections).

Le motif du câblage CI est écrit sur place et mérite d'être repris pour la nouvelle règle
`[VERIFIED: ci.yml:332-341]` : *« Le gate était livré, testé, distribué dans chaque lab — et
référencé par RIEN d'exécutable […] Une garde que la chaîne d'intégration ne lance jamais est une
garde absente : c'est exactement le mode d'échec (« routé, donc réputé vivant ») que ce gate existe
pour fermer, reproduit un étage plus haut sur lui-même. »* Et : *« Un exit 2 (NON VÉRIFIABLE) échoue
le job au même titre qu'un exit 1 — un gate qui ne peut pas se prononcer n'est pas un gate vert. »*

**Coût mesuré d'un découpage (D-03) :** 3 appelants exécutables, dont 2 dans le même fichier de test.
Faible — mais le §2 montre que **rien ne l'exige**.

---

## 8. Suites de tests de `plugin/dev-orchestrator/scripts/tests/`

### 8.1 Le roster **est** la convention de nommage

`[VERIFIED: .github/workflows/ci.yml:205-233]` :

```bash
suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)
count=$(printf '%s\n' "$suites" | grep -c . || true)
if [ "$count" -eq 0 ]; then
  echo "::error::aucune suite de tests découverte (pattern */tests/test-*.sh) — la CI refuse de rendre un verdict vide"
  exit 1
fi
```

**52 suites découvertes ce jour** `[VERIFIED: find plugin scripts -type f -path '*/tests/test-*.sh' | awk 'END{print NR}', rejoué ce jour]`.
Poser un fichier `test-*.sh` sous un `tests/` de `plugin/` ou `scripts/` suffit — **aucun roster à
mettre à jour.** Et la distribution suit (`copy_module_scripts` copie `scripts/tests/*.sh` et
`tests/fixtures/*`, `vibeflow-update.sh:354-358`).

Contenu de `plugin/dev-orchestrator/scripts/tests/` : `test-check-capability-activation.sh` (630 l.),
`test-check-dev-bootstrap.sh`, `test-check-doc-drift.sh`, `test-check-gsd-config.sh`,
`test-check-gsd-engine.sh`, `test-dev-orchestrator.sh`, `test-discover-unintegrated-docs.sh`,
`test-inject-mcp-tools.sh`.

### 8.2 Harness

Maison, zéro dépendance. Squelette canonique
`[VERIFIED: plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh:33-42]` :

```bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-capability-activation.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
```

Puis : fabriques de fixtures `mk_*()` en heredoc **quoté** (`<<'IDX'`, l.50-129) ; helpers
`run()` / `rc_of()` qui passent les surcharges `VF_*` et séparent stdout/stderr (l.131-146) ;
`mk_fixture()` qui monte un état conforme complet et **imprime son chemin** (l.148-155).

### 8.3 Fixtures : synthétiques, temporaires, jamais ancrées sur l'arbre réel

Motif écrit `[VERIFIED: test-check-capability-activation.sh:28-31]` : *« Toutes les fixtures sont
SYNTHÉTIQUES et vivent dans un `mktemp -d` nettoyé par `trap` : l'arbre réel bougera (l'index est
régénéré à chaque évolution du moteur), une suite ancrée dessus se périmerait. Le seul cas ancré sur
l'arbre réel est un contrôle final, explicitement NON discriminant, placé APRÈS les mutations et
jamais à leur place. »*

L'index synthétique reproduit **les quatre sections** de l'index réel (l.45-49) : *« Une fixture qui
n'en aurait qu'une partie laisserait autant de chemins du parseur non testés. »*

Un dossier `scripts/tests/fixtures/` existe et est distribué (`vibeflow-update.sh:355-357`).

### 8.4 Le test de discriminance rouge/vert — les deux exemples à copier

**(A) La doctrine** `[VERIFIED: test-check-capability-activation.sh:5-31]` :
- mutation dans les **deux sens** (retirer un marqueur ⇒ rouge ; activer un toggle marqué ⇒ rouge) ;
- *« une mutation doit avoir CHANGÉ le fichier, constaté par `cmp` et JAMAIS par `diff` (le `diff` de
  ce poste est proxifié et ment) »* (l.24-26) ;
- *« Un motif de mutation introuvable rend le mutant NON OPPOSABLE — un échec, jamais un succès
  silencieux »* ;
- la fixture conforme porte **deux** marqueurs et non un, délibérément (l.107-113) : avec un seul,
  retirer LE marqueur viderait `M` et ferait sortir le **plancher** (exit 2) avant que la règle visée
  puisse voir quoi que ce soit — *« un mutant qui rougit pour la mauvaise raison ne prouve rien »*.
  **C'est le piège n°1 pour D-06** : une fixture à un seul agent armé prouvera le plancher, pas la
  règle.

**(B) L'implémentation, squelette de D-06** `[VERIFIED: test-dev-orchestrator.sh:1454-1470]` :

```bash
T14D_TMPDIR="$(mktemp -d)"
T14D_MUT="$T14D_TMPDIR/carte-sans-marqueur-graphify.md"
awk '/gsd-graphify/ { sub(/\(conditionnelle : [A-Za-z0-9_.-]+\)/, "") } { print }' "$ROUTING" > "$T14D_MUT"
if cmp -s "$ROUTING" "$T14D_MUT"; then
  ko "… mutant IDENTIQUE … mutant NON OPPOSABLE (pas mutant satisfait)"; t14d_ok=0
else
  t14d_mut_nues="$(conditional_unmarked "$T14D_MUT")"
  if [ "$t14d_mut_nues" = " gsd-graphify" ]; then
    ok "… (DISCRIMINANT, par mutation) : marqueur retiré → rougit en nommant précisément gsd-graphify ; la carte réelle reste verte"
  else
    ko "… NON DISCRIMINANTE : … devrait produire exactement [ gsd-graphify] (obtenu : [$t14d_mut_nues])"
  fi
fi
rm -rf "$T14D_TMPDIR"
```

Trois invariants : mutation dans un `mktemp -d` privé · `cmp -s` réel vs mutant, identique ⇒ **ko** ·
le mutant doit rougir **en nommant précisément** l'objet muté, et le fichier réel rester vert.

**(C) Le plancher d'opposabilité, version CI** `[VERIFIED: .github/workflows/ci.yml:578-582]` :
*« deux stdout vides ne peuvent RIEN opposer. Le dire est un échec, jamais un succès — patron `NON
OPPOSABLE` de `test-check-capability-activation.sh`, qui refuse le même repli sur `cmp -s` »*.

### 8.5 Où atterrit le test D-06

Deux emplacements valides, la découverte les attrape tous deux :
- un cas neuf dans `test-check-capability-activation.sh` (cohérent : le gate étendu = sa suite) ;
- une suite `test-<nom>.sh` dédiée sous `plugin/dev-orchestrator/scripts/tests/`.

**Le fixture #38 rejoué est un fichier agent SYNTHÉTIQUE dans un `mktemp -d`**, portant
`isolation: worktree` — **jamais** un agent distribué. C'est conforme à l'interdit du cadrage, et
c'est aussi ce que la doctrine des fixtures impose de toute façon (§8.3).

---

## 9. Outillage plateforme (D-04) — mesuré, pas présumé

CLI `claude` **2.1.226**, `/Users/samuel/.local/bin/claude`
`[VERIFIED: command -v claude && claude --version, rejoué ce jour]`.

| Commande | Existe ? | Ce qu'elle fait exactement (verbatim du `--help`) |
|---|---|---|
| `claude plugin validate <path> [--strict]` | **OUI** | « Validate a plugin or marketplace manifest ». `--strict` : « Treat warnings as errors (exit 1). Use in CI to fail on unrecognized fields, missing metadata, and other issues that the runtime tolerates. » |
| `claude plugin install <plugin> --plugin-url …` | **NON** | L'option **n'existe pas** dans 2.1.226. Options réelles : `--config <key=value>`, `-h`, `-s|--scope <scope>` (user\|project\|local, défaut user) |
| `claude plugin install --config <key=value>` | **OUI** | « Set a userConfig option declared in the plugin's manifest (repeatable). Values are validated against the schema and stored via the same path as the interactive /plugin configure flow. » |
| `claude plugin details <name>` | OUI | « Show a plugin's component inventory and projected token cost » |
| `claude plugin tag [path]` | OUI | « Create a {name}--v{version} git tag for a plugin release, validating that plugin.json and any enclosing marketplace entry agree » |
| `claude plugin eval [target]` | OUI | Cases `evals/**/case.yaml` + `graders/*.md` contre un plugin |
| `claude plugin prune` | OUI | Retire les dépendances auto-installées devenues inutiles |

`[VERIFIED: claude plugin --help, claude plugin validate --help, claude plugin install --help, rejoués ce jour]`

**Verdicts pour le plan :**

1. **`--plugin-url` n'existe pas.** L'*as-installed testing* sur un artefact zip publié **n'est pas
   outillé par la plateforme** dans cette version. Le job `lab-frais` reste **le seul véhicule** de
   D-04. Le CONTEXT le mentionnait comme « à évaluer sans obligation » — c'est tranché : non
   disponible.
2. **`validate --strict` existe et est adoptable**, mais il valide un **manifeste** (`plugin.json` /
   `marketplace.json`), pas des frontmatters d'agents ni une précondition. **Hors sujet pour
   l'armement.** Il chevaucherait `scripts/check-version-sync.sh` (déjà câblé `ci.yml:319-320`) ;
   à traiter comme un ajout de confort, pas comme une brique de cette phase.
3. **`--config <key=value>` confirme machine l'existence de `userConfig`** — le véhicule officiel de
   la plateforme, consigné en `<deferred>`, et **settable non-interactivement en CI**. Le
   `plugin/.claude-plugin/plugin.json` de ce dépôt **ne déclare aucun `userConfig`** aujourd'hui
   (clés mesurées : `name`, `displayName`, `version`, `description`, `author`, `homepage`,
   `repository`, `license`, `keywords`, `skills`) `[VERIFIED: cat plugin/.claude-plugin/plugin.json, rejoué ce jour]`.
   **Ne pas l'ouvrir ici** (deferred) — mais le fait est désormais mesuré pour la phase qui le fera.

---

## 10. Faits moteur `@opengsd/gsd-core` 1.10.0 — re-mesurés, jamais recopiés

**Version installée : `1.10.0`** `[VERIFIED: cat ~/.claude/gsd-core/VERSION, rejoué ce jour]`
(la recherche Phase 27 tournait sur 1.9.1).
Arborescence : `bin/ contexts/ references/ templates/ workflows/ .gsd-runtime VERSION`.

### 10.1 Le moteur expose une commande `worktree`

`[VERIFIED: node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree, rejoué ce jour]` — sortie verbatim :

```
Error: Unknown worktree subcommand. Available: cleanup-wave, record-agent, reap-orphans, base-check, set-baseref, create
```

`worktree` figure bien dans la liste des commandes de `gsd-tools --help`, aux côtés de
`dispatch-isolation`, `record-dispatch-isolation`, `resolve-dispatch-type`, `resolve-execution`.

### 10.2 `worktree-base-ref.cjs` — 394 lignes

`~/.claude/gsd-core/bin/lib/worktree-base-ref.cjs`. En-tête verbatim
`[VERIFIED: :2-12]` : *« Worktree base-ref detection and degradation logic (issue #683). Determines
whether a worktree's HEAD has drifted from the fork base that the Claude Code harness would use to
create a 'fresh' parallel worktree. When drift is detected the caller should fall back to sequential
execution on the main working tree to avoid a base mismatch. »*

| Export | Ligne | Contrat |
|---|---|---|
| `readBaseRefFromSettings(settings)` | 127-137 | Extrait `settings.worktree.baseRef` si c'est une chaîne, sinon `null`. Défensif sur null/array/non-objet |
| `applyWorktreeBaseRef(settings)` | 147-168 | **No-clobber** : absent ⇒ pose `'head'` (`changed:true`) · déjà `'head'` ⇒ `skipped:'already-head'` · **toute autre chaîne ⇒ `skipped:'explicit-other'`, jamais écrasée** |
| `resolveEffectiveBaseRef(claudeDir, deps, userClaudeDir)` | 181-220 | **Cascade à 3 couches** : `<claudeDir>/settings.local.json` → `<claudeDir>/settings.json` → `<userClaudeDir>/settings.json` (user seulement si différent). JSONC toléré (`stripJsonComments` :34) |
| `cmdWorktreeBaseCheck(cwd, _args, deps)` | 231 | **Lecture seule** : lit la cascade, évalue, écrit un JSON sur stdout |
| `cmdWorktreeSetBaseRef(cwd, _args, deps)` | 254 | **Le moteur sait ÉCRIRE la précondition** |
| `evaluateWorktreeBaseDegrade(deps)` | 310 | Décide de la dégradation |

**Message constant verbatim** `[VERIFIED: :97 et :99]` : *« ⚠ Cannot determine the worktree fork base
(origin/HEAD unresolved). Running this phase sequentially on the main working tree to avoid a base
mismatch. To keep parallel worktrees, set worktree.baseRef:"head" in .claude/settings.local.json (or
run: gsd-tools worktree set-baseref). See #683. »* — le commentaire l.95 précise que ces messages
sont **verbatim, des docs et des tests aval en dépendent**.

### 10.3 Ce qui a changé depuis 1.9.1 — le fait qui compte

Les trois messages constants (l.96-100) disent tous *« Running this phase sequentially on the main
working tree »*. **Sur 1.10.0, l'absence de la précondition ne casse plus en silence : elle dégrade
en séquentiel avec un message.** C'est une **correction de la prémisse de #38**, et cela alimente
directement la discrétion « précondition dure vs tuning à défaut sûr » : `worktree.baseRef` est
désormais un **tuning à défaut sûr, avec dégradation gracieuse et message** — pas une précondition
dure.

⚠ **Cela ne rouvre PAS le ré-armement** : le second verrou (`open-gsd/gsd-core#3302`, rien ne ramène
les commits du worker) est intact et n'est pas touché par ce module. Le cadrage reste valide.

### 10.4 Discriminance de la sonde, mesurée sur pièce ce jour

Protocole : `mktemp -d`, `git init -q`, un commit vide, `.planning/config.json` = `{}`.
`[VERIFIED: séquence rejouée ce jour, sortie verbatim]`

| État | Sortie de `gsd-tools worktree base-check` |
|---|---|
| **sans** `worktree.baseRef` | `{"shouldDegrade": true, "reason": "fork-ref-unknown", "message": "⚠ Cannot determine the worktree fork base…", "headSha": "35396cf7…"}` |
| **avec** `.claude/settings.local.json` = `{"worktree":{"baseRef":"head"}}` | `{"shouldDegrade": false, "reason": "baseref-head", "message": null}` |
| sur **ce dépôt** (qui porte le réglage) | `{"shouldDegrade": false, "reason": "baseref-head", "message": null}` |

**C'est une sonde machine, lecture seule, bidirectionnellement discriminante, déjà présente chez tout
utilisateur qui a le moteur.** C'est le corps tout fait d'un `ensure-worktree-baseref.sh` au sens de
D-02 — et elle rend la « preuve verte » **exerçable**, pas seulement déclarative. (L'écriture reste
`set-baseref`, donc un geste gaté humain sous ADR-031 ; la **vérification**, elle, est gratuite.)

### 10.5 Deux faits annexes

- `gsd-tools dispatch-isolation` (sans argument) rend **`harness-worktree`**, identiquement dans
  `/tmp` et à la racine de ce dépôt `[VERIFIED: rejoué ce jour]`. Le moteur **prescrit** donc
  l'isolation harness-worktree comme mode de **dispatch** — à ne pas confondre avec un armement
  d'agent, que D-06 interdit de rejouer hors fixture.
- **`.claude/` est gitignoré dans ce dépôt** `[VERIFIED: .gitignore:12-21]`, avec un commentaire
  explicite : *« le repo est la SOURCE des modules, PAS un lab »*, et *« Worktrees d'agents isolés
  (isolation: worktree, Phase 27) : déjà couverts par cette règle englobante »*. Le
  `.claude/settings.local.json` qui porte `worktree.baseRef` (contenu mesuré :
  `{"worktree": {"baseRef": "head"}}`, **seule clé**) est donc **untracked** : **aucun gate lisant
  l'arbre versionné ne peut le voir.** C'est la moitié machine du diagnostic de #38 — et la raison
  pour laquelle D-02 a raison de refuser le verdict « le réglage est dans le repo ».

---

## Don't Hand-Roll

| Problème | Ne pas construire | Réutiliser | Pourquoi |
|---|---|---|---|
| Trouver la racine du lab | une remontée `while` maison | `vf_capact_bounded_walk()` + cascade 3 paliers `check-capability-activation.sh:133-151` | Une remontée libre lit la config du projet voisin — défaut mesuré et corrigé, motif écrit l.111-132 |
| Compter une occurrence de nom | `grep -c` / regex awk | `occ()` `check-capability-activation.sh:271-284` | Comparaison **par frontière**, jamais par sous-chaîne nue (`workflow.code_review` ⊂ `workflow.code_review_command`) |
| Compter des lignes | `grep \| wc -l` | `awk 'END{print NR}'` | Le `grep` proxifié de ce poste **tronque silencieusement** (31 lignes rendues sur 102), constat inscrit `check-capability-activation.sh:27-28` |
| Comparer deux fichiers dans un test | `diff` / `git diff` | `cmp -s` | *« le `diff` de ce poste est proxifié et ment »* `test-check-capability-activation.sh:24-26` |
| Un mode « lecture seule qui rapporte » | un `--check` maison à 2 exits | patron `--verify` de `inject-mcp-tools.sh:80-91` | Trois exits (0/1/**3 indéterminé**), refus explicite du faux vert et de la réparation silencieuse |
| Distribuer un script | une entrée dans `module.json` | rien : poser le `.sh` dans `plugin/<mod>/scripts/` | `copy_module_scripts()` est un glob `vibeflow-update.sh:342-343` |
| Inscrire une suite de tests | un roster | nommer le fichier `tests/test-*.sh` | Découverte CI `ci.yml:207` |
| Passer une valeur au bloc awk | `awk -v` | l'**environnement** + `ENVIRON[…]` | `-v` interprète les échappements (un `\` cassait `FILENAME == IDX`) et ne porte pas de saut de ligne — motif écrit `check-capability-activation.sh:253-258` |
| Découper une liste de chemins | `set -- $VAR` nu | `IFS=$'\n'` + `set -f` puis `set +f` | Le nu coupait aussi sur l'espace **et développait les globs** — deux défauts mesurés `check-capability-activation.sh:209-214` |
| Vérifier `worktree.baseRef` | relire `settings*.json` à la main | `gsd-tools worktree base-check` (§10.4) | Cascade 3 couches + JSONC déjà implémentées et discriminantes |

**Key insight :** ce dépôt a déjà payé le prix de chacune de ces primitives, et le **motif de chaque
correction est écrit sur place**. La règle de la Phase 24 (« un besoin = une implémentation ») ne dit
pas seulement « ne pas dupliquer » : elle dit **lire le commentaire avant de réécrire**.

---

## Common Pitfalls

### Pitfall 1 — Le gate rend vert à vide dans le lab frais
**Ce qui se passe :** la fermeture `conductor` (7 modules) ne pose ni le gate ni un seul agent armé
(§6.3). Une étape ajoutée naïvement sort 0 et prouve zéro.
**Comment l'éviter :** installer la fermeture `dev-orchestrator` (9 modules, mesurée) **et** poser le
plancher règle 1 sur la nouvelle règle (corpus d'artefacts vide ⇒ exit 2).
**Signe d'alerte :** le rapport conforme ne nomme aucun artefact dans l'univers balayé.

### Pitfall 2 — Le gate sort 2 avant de regarder, dans le lab frais
**Ce qui se passe :** pas de `.planning/config.json` dans un lab tout juste installé
(`ci.yml:647-648`) ; la précondition globale `check-capability-activation.sh:200-203` sort 2.
**Comment l'éviter :** poser un `.planning/config.json` minimal dans le lab frais, **ou** rendre la
précondition `CONFIG` locale aux règles qui en dépendent.

### Pitfall 3 — Croire que `--strict` bloque sur une clé de frontmatter inconnue
**Ce qui se passe :** `check-agents.sh:618-620` empile un `warnings` nu ; `--strict` ne le promeut
jamais ; la CI reste verte (§3.2). Le CONTEXT affirme l'inverse.
**Comment l'éviter :** ajouter la clé à `KNOWN:158-160` **pour le bruit**, pas pour le blocage — et
ne pas séquencer le plan comme si c'était un prérequis dur.

### Pitfall 4 — Le troisième discriminant de fichier manquant dans l'awk
**Ce qui se passe :** l'awk discrimine par `FILENAME == IDX` (l.318) et **tout le reste tombe dans le
bloc corpus** (l.355, sans condition). Passer des frontmatters d'agents sans troisième discriminant
les fait parcourir comme de la doc : `nLines` gonfle, les règles 2/2bis cherchent des marqueurs
conditionnels dans des frontmatters, faux positifs silencieux.
**Signe d'alerte :** le compteur « N ligne(s) » du rapport conforme explose sans raison.

### Pitfall 5 — Une fixture de discriminance à un seul objet armé
**Ce qui se passe :** retirer l'unique objet vide l'ensemble et déclenche le **plancher** (exit 2)
au lieu de la règle visée. *« Un mutant qui rougit pour la mauvaise raison ne prouve rien »*
`test-check-capability-activation.sh:107-113`.
**Comment l'éviter :** au moins deux artefacts armés dans la fixture conforme.

### Pitfall 6 — Découper le gate « pour le seuil »
**Ce qui se passe :** aucun seuil ne s'applique aux `.sh` (§2). Un découpage motivé par un gate
inexistant produirait le sixième gate que D-03 refuse, sous un autre nom.

### Pitfall 7 — Accepter un `ensure-*` déclaré comme preuve, sans exiger son câblage
**Ce qui se passe :** mesuré, un seul `ensure-*` est câblé machine, et c'est **à l'install** ;
l'autre est invoqué par de la prose d'agent/skill, et son « premier contact » est écrit dans un
**README** (§4.3). Bénir une promesse en prose = rejouer #38 un cran plus loin.
**Comment l'éviter :** exiger l'une des trois formes vérifiables du §4.3 — de préférence un mode
`--verify` à trois exits, exerçable par le gate.

### Pitfall 8 — Balayer `plugin/*/agents` seul
**Ce qui se passe :** 6 fichiers sur 31 sont des `plugin/*/AGENT.md` que l'installeur pose aussi.
Le défaut est documenté sur place (`ci.yml:267-278`, *« la population réelle est de 31 fichiers, pas
25 […] a donc laissé passer 5 modules non conformes jusqu'au Gate C »*).

### Pitfall 9 — Compter avec `grep`, comparer avec `diff`
**Ce qui se passe :** les deux sont proxifiés sur ce poste. `grep` tronque (31/102), `diff` ment.
**Comment l'éviter :** `awk` pour extraire et compter, `comm` pour comparer des ensembles, `cmp -s`
pour l'égalité de fichiers, `rtk proxy <cmd>` si l'outil brut est indispensable.

### Pitfall 10 — Ajouter une dépendance `jq` de plus
**Ce qui se passe :** le gate exige déjà `jq` (`:204-207`), contre ADR-054. Lire un frontmatter YAML
en `jq`/`yq` doublerait la dette, et **ni `gates` ni `lab-frais` n'assertent `jq`** (seul `tests` le
fait, `ci.yml:23-27`).
**Comment l'éviter :** frontmatter en awk, point.

---

## Code Examples

### Squelette d'une règle nouvelle dans le `END` (gabarit de message conservé)

```awk
    # --- Regle 4 : armement sans precondition distribuee.
    for (i = 1; i <= nA; i++) {
      a = AORDER[i]                       # artefact arme
      k = AKEY[a]                         # la cle d armement (isolation, mcp__, ...)
      if (PROVEN[a]) continue             # un ensure-* declare ET cable a prouve la precondition
      print "[check-capability-activation] ECART regle 4 : l artefact « " a " » est arme de « " k " » sans precondition distribuee (aucun ensure-* declare ne la verifie) — " ASRC[a] ":" ALNO[a]
      bad++
    }
```
*Source : gabarit dérivé verbatim de `check-capability-activation.sh:402, 420, 428, 431`.*

### Plancher anti-vert-à-vide à ajouter (patron règle 1)

```awk
    if (nA == 0) {
      print "[check-capability-activation] aucun artefact lisible dans l univers d armement (" nFiles " fichier(s)) — la regle 4 serait INERTE, activation NON VERIFIABLE"
      exit 2
    }
```
*Source : patron verbatim de `check-capability-activation.sh:381-384` (message de `nB == 0`).*

### Test de discriminance D-06 (squelette, dérivé de T14d (c))

```bash
MUT_DIR="$(mktemp -d)"
AG="$MUT_DIR/vf-faux-worker.md"
cat > "$AG" <<'EOF'
---
name: vf-faux-worker
description: fixture synthetique de discriminance — jamais un agent distribue
model: sonnet
memory: project
effort: low
isolation: worktree
---
EOF
rc_arme="$(rc_of_gate "$MUT_DIR")"        # attendu : 1 (ROUGE)
awk '!/^isolation:/ { print }' "$AG" > "$AG.tmp"
cmp -s "$AG" "$AG.tmp" && { ko "mutant NON OPPOSABLE : ligne isolation introuvable"; }
mv "$AG.tmp" "$AG"
rc_desarme="$(rc_of_gate "$MUT_DIR")"     # attendu : 0 (VERT)
rm -rf "$MUT_DIR"
```
*Sources : `test-dev-orchestrator.sh:1454-1470` (cmp/NON OPPOSABLE) ·
`test-check-capability-activation.sh:41-42, 131-155` (mktemp/trap/run/rc_of).*
**La ligne `isolation: worktree` vit ici et nulle part ailleurs — jamais dans un agent distribué.**

### Sonde de précondition, exerçable chez l'utilisateur (D-02, verdict vert)

```bash
# lecture seule, discriminante dans les deux sens — mesurée §10.4
out="$(node "$GSD_HOME/bin/gsd-tools.cjs" worktree base-check 2>/dev/null)" || out=""
case "$out" in
  *'"reason": "baseref-head"'*) : ;;                    # precondition posee
  '')  echo "[ensure-…] moteur GSD absent — precondition NON VERIFIABLE" >&2; exit 3 ;;
  *)   echo "[ensure-…] worktree.baseRef absent — corriger : gsd-tools worktree set-baseref" >&2 ;;
esac
```
*Source : sorties verbatim mesurées ce jour (§10.4) ; message de remédiation verbatim de
`~/.claude/gsd-core/bin/lib/worktree-base-ref.cjs:97`.*

---

## State of the Art (interne au dépôt)

| Approche antérieure | Approche courante | Quand | Impact sur cette phase |
|---|---|---|---|
| `worktree.baseRef` absent ⇒ le worker part de la branche par défaut **en silence** (diagnostic #38, gsd-core 1.9.1) | gsd-core **1.10.0** : détection de dérive + **dégradation en séquentiel avec message** + `gsd-tools worktree base-check`/`set-baseref` | mesuré 2026-08-10 | `baseRef` devient un **tuning à défaut sûr**, pas une précondition dure. Alimente la discrétion « dure vs défaut sûr ». **Ne rouvre pas** le ré-armement (verrou #3302 intact) |
| `claude plugin list \| grep <nom>` comme détection de présence | `ensure-design-deps.sh` : présence **ET activation**, `claude plugin enable` scopé | 2026-08-10 (quick `260810-fh3`) | Le patron « vérifier chez l'utilisateur » est mûr et récent |
| Gate livré + testé + distribué, mais lancé par **rien d'exécutable** | Câblage explicite au job `gates`, exit 2 = échec | Phase 24 | Toute règle nouvelle doit naître câblée |
| Comptage de population sur `plugin/*/agents` (25) | Population réelle **31** (les `AGENT.md` comptent) | Phase 24, `ci.yml:267-278` | Le corpus du nouveau gate doit être 31, pas 25 |

**Périmé / à ne pas reprendre :** tout fait moteur de
`.planning/research/2026-08-05-parallelisation-execution.md` (produit sur 1.9.1) ; en particulier
l.92-94 (« sinon il part de `main` et perd le contexte ») reste **vrai sur le fond** mais **incomplet
sur la forme** : 1.10.0 le détecte et dégrade au lieu de subir.

---

## Environment Availability

| Dépendance | Requise par | Disponible | Version | Repli |
|---|---|---|---|---|
| `bash` | tous les gates | ✓ | 3.2.57 (macOS, poste) / 5.x (runner) | patron compat bash 3.2 déjà pratiqué (`check-file-size.sh:75-85`) |
| `awk` | le gate, les tests | ✓ | BSD awk (poste), gawk (runner) | contrat ASCII déjà posé `check-capability-activation.sh:298-302` |
| `jq` | `check-capability-activation.sh:204-207` | ✓ poste ; ✓ job `tests` (asserté `ci.yml:25`) | — | **non mesuré** sur les jobs `gates` et `lab-frais` — aucune assertion |
| `python3` | `check-agents.sh:132-140`, `merge-hooks.sh`, `inject-mcp-tools.sh` | ✓ poste ; ✓ runner (Gate C passe aujourd'hui, preuve indirecte) | — | garde stub Microsoft Store déjà en place (ADR-054) |
| `node` ≥ 22 | moteur GSD | ✓ poste | gsd-core **1.10.0** | job `tests` épingle Node 22 (`ci.yml:31-34`) ; **absent** de `lab-frais` |
| CLI `claude` | `ensure-*`, sondes plateforme | ✓ poste | **2.1.226** | absente sur runner (non mesuré) — les `ensure-*` dégradent en étapes manuelles, exit 0 |
| `git` | résolution de racine, tests | ✓ | — | — |
| `rtk` | contournement des proxys `grep`/`diff` du poste | ✓ | — | **poste uniquement**, jamais dans un script distribué |

**Manquantes bloquantes :** aucune.
**Manquantes avec repli :** `jq` sur `gates`/`lab-frais` — présent de fait sur `ubuntu-latest`, mais
**non asserté**. Si la nouvelle règle en dépend, ajouter l'assertion (patron `ci.yml:23-27`) ou
s'en passer.

---

## Validation Architecture

`workflow.nyquist_validation: true` `[VERIFIED: .planning/config.json]`.

### Test Framework

| Propriété | Valeur |
|---|---|
| Framework | harness bash maison, zéro dépendance (`ok()`/`ko()`/`PASS`/`FAIL`) |
| Config | aucune — la **convention de nommage est le roster** : `*/tests/test-*.sh` sous `plugin/` ou `scripts/` |
| Découverte | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` `[ci.yml:207]`, plancher « 0 suite = échec » `[ci.yml:211-214]` |
| Quick run | `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` |
| Full suite | la boucle de découverte de `ci.yml:205-233` — **52 suites** mesurées ce jour |

### Exigences → tests

`.planning/ROADMAP.md:2017` porte `Requirements: TBD` — aucune correspondance REQ→test ne peut être
produite sans inventer d'ID. Le planner doit créer les exigences. Comportements à couvrir, dérivés
des décisions :

| Comportement (décision) | Type | Commande |
|---|---|---|
| Armement sans précondition ⇒ ROUGE (D-02) | unit, fixture synthétique | `bash …/tests/test-check-capability-activation.sh` |
| Désarmement ⇒ VERT, sur la même fixture (D-06) | unit, mutation `cmp`-vérifiée | idem |
| `ensure-*` déclaré + câblé ⇒ VERT (D-02) | unit | idem |
| Corpus d'artefacts vide ⇒ exit 2, jamais 0 (plancher) | unit | idem |
| Le gate tourne dans un lab **installé** (D-04) | intégration CI | étape neuve du job `lab-frais` |
| Le gate reste vert sur l'arbre réel | non discriminant, **après** les mutations | `bash …/tests/test-dev-orchestrator.sh` (T14d d/e) |

### Sampling

- **Par commit de tâche** : la suite du gate seule (~secondes).
- **Par merge de wave** : les 52 suites (boucle de découverte).
- **Porte de phase** : CI verte sur les 3 jobs, `lab-frais` inclus.

### Wave 0 — manques

- [ ] Aucun. L'infrastructure existe (harness, découverte, fixtures, distribution). **Rien à
      installer, rien à inscrire.**

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` `[VERIFIED: .planning/config.json]`.

### Catégories ASVS applicables

| Catégorie | S'applique | Contrôle standard de ce dépôt |
|---|---|---|
| V2 Authentication | non | aucun secret, aucune session |
| V3 Session Management | non | — |
| V4 Access Control | **oui, indirectement** | le gate lit des chemins fournis par l'environnement (`VF_CAPACT_*`, `--path`) — la cascade est **bornée** (`vf_capact_bounded_walk`) précisément pour ne pas sortir du lab |
| V5 Input Validation | **oui** | frontmatter d'agent = **entrée non fiable**. Le gate doit le parser en awk **sans jamais l'évaluer** : pas d'`eval`, pas de `sub()` avec le contenu en premier argument (motif déjà écrit `check-capability-activation.sh:358-359` : *« le premier argument de `sub()` est une EXPRESSION »*), comparaison par `index()` |
| V6 Cryptography | non | — |

### Menaces connues pour cette phase

| Motif | STRIDE | Mitigation standard, déjà pratiquée dans ce dépôt |
|---|---|---|
| Échappement par lien symbolique (`.planning/…` pointant hors du lab) | Information Disclosure | Quatrième passage du motif documenté en Phase 24 (README v2.48.0 : le `STATE.md` d'une cible externe était injecté au SessionStart à exit 0). **Toute nouvelle lecture de chemin doit être bornée** — patron `vf_capact_bounded_walk` |
| Frontmatter hostile interprété comme expression | Tampering / Elevation | `index()` + `occ()` littéraux, jamais de regex construite depuis le contenu ; jamais `eval` ; arguments toujours en mots argv séparés (patron `run_cmd()` `ensure-design-deps.sh:107-115`, menace T-Q-01) |
| Exécution de code par `require()` d'un artefact tiers | Elevation | Précédent fermé en Phase 23 : `build-gsd-capabilities-index.sh` a basculé en **lecture de texte** pour fermer T-23-04-07 (RCE). **Ne jamais réintroduire une lecture par exécution** |
| Faux vert (gate qui ne peut pas se prononcer et sort 0) | Repudiation | Plancher règle 1 + exit 2 traité comme un échec par la CI (`ci.yml:339-341`) |
| Valeur d'environnement détournant la cible du gate | Tampering | Patron déjà appliqué : `check-state-integrity.sh` reçoit `--file` **explicite** en CI, *« sans lui […] un simple `export` suffirait à détourner le gate »* `[ci.yml:322-329]` — à reprendre pour toute nouvelle surcharge |

---

## Assumptions Log

| # | Affirmation | Section | Risque si fausse |
|---|---|---|---|
| A1 | `jq` est présent sur `ubuntu-latest` pour les jobs `gates` et `lab-frais` (déduit du fait que `check-capability-activation.sh` y sort 0 aujourd'hui, pas d'une assertion) | Environment Availability, Pitfall 10 | Si faux, le gate sort déjà 2 en CI — donc l'hypothèse est corroborée par le vert actuel, mais **non mesurée directement** |
| A2 | `python3` est présent sur le runner de `lab-frais` (déduit du fait que Gate C exécute `check-agents.sh --strict` avec succès) | Environment Availability | Preuve indirecte ; aucune étape ne l'assert dans ce job |
| A3 | La convention de préfixe (`ensure-*` / `check-*` / `build-*` / `guard-*`) est stable — **rien ne la vérifie par machine** | §4.4 | Une liaison artefact ↔ script fondée sur le nom serait une inférence de proximité, que D-02b interdit |
| A4 | `mobile-test-team` n'est dans aucune fermeture transitive installable par `lab-frais` (mesuré pour `conductor` et `dev-orchestrator` uniquement) | §6.3 | Si un autre module le tire, 3 agents armés de plus entreraient dans le lab frais |
| A5 | Le comportement de `claude plugin` en 2.1.226 vaut pour les versions que les utilisateurs ont réellement — non mesuré ailleurs que sur ce poste | §9 | `--plugin-url` pourrait exister dans une version plus récente ; à re-sonder au moment du plan |

---

## Open Questions

1. **Qui porte la règle `isolation:` — `check-agents.sh` ou le gate étendu ?**
   - Ce qu'on sait : les corpus sont disjoints aujourd'hui (§3.3) ; `check-agents.sh:546-549`
     interdit **inconditionnellement** avec une condition de levée écrite (distribuer la précondition
     **ET** prouver le merge-back) ; le nouveau gate jugerait **conditionnellement**.
   - Ce qui reste flou : si les deux rougissent sur le même fichier, laquelle est la source de vérité
     pour l'utilisateur qui lit le message.
   - Recommandation : **garder les deux, écrire la hiérarchie** — `check-agents.sh` est le palier
     dur (interdiction), le nouveau gate le palier de relation (armement ↔ preuve). Le test D-06 doit
     isoler le nouveau gate pour prouver qu'il rougit **de son propre chef**.

2. **Précondition dure vs tuning à défaut sûr — `baseRef` a changé de camp.**
   - Ce qu'on sait : 1.10.0 dégrade en séquentiel **avec message** (§10.3) ; le natif a un défaut
     `'fresh'` et un fallback gracieux (état de l'art, pattern 1).
   - Ce qui reste flou : si un armement déclarant un défaut sûr documenté vaut **vert**, ou si seule
     la preuve `ensure-*` compte.
   - Recommandation : **trois verdicts, pas deux** — ROUGE (armé, aucune preuve, aucun défaut sûr) ·
     VERT (preuve `ensure-*` exerçable) · **INDÉTERMINÉ/JAUNE non bloquant** (défaut sûr documenté et
     dégradation gracieuse prouvée). Le gate a déjà la doctrine des trois états (§1.4) ; l'étendre
     est cohérent, l'écraser en binaire ne le serait pas.

3. **Comment prouver qu'un `ensure-*` est câblé, et pas seulement nommé ?**
   - Ce qu'on sait : trois formes vérifiables machine existent (§4.3), et une seule
     (`hooks/hooks.json`) est grep-able sans exécuter quoi que ce soit.
   - Recommandation : exiger un mode `--verify` à trois exits (patron `inject-mcp-tools.sh:80-91`) et
     **l'exercer depuis le gate** — c'est la seule forme qui prouve au moment de l'usage.

4. **Le lab frais doit-il installer 9 modules au lieu de 7 ?**
   - Ce qu'on sait : sans cela, ni le gate ni un armement ne sont posés (§6.3).
   - Risque : élargir la baseline installée en CI change ce que Gate C couvre aujourd'hui. À traiter
     comme un **second job** ou une **seconde étape** plutôt qu'en modifiant la baseline existante —
     le vert actuel de Gate C est un acquis à ne pas troubler.

---

## Sources

### Primaires (HIGH — lues sur disque ce jour, `fichier:ligne` cités)
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` (443 l., lu intégralement)
- `plugin/conductor/scripts/check-agents.sh` (680 l., l.1-200 et 480-680 lues)
- `plugin/software-architecture/scripts/check-file-size.sh` (109 l., lu intégralement)
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (541 l., en-tête l.1-130)
- `plugin/design-orchestrator/scripts/ensure-design-deps.sh` (387 l., en-tête l.1-120)
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` (479 l., en-tête l.1-100)
- `plugin/_internal/vibeflow-update.sh` (l.191-360, 476-600, 620-725)
- `plugin/_internal/merge-hooks.sh` (l.1-60)
- `.github/workflows/ci.yml` (652 l. ; l.17-120, 175-360, 545-652)
- `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` (l.1-175)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (l.1405-1504)
- `~/.claude/gsd-core/bin/lib/worktree-base-ref.cjs` (394 l. ; l.1-230)
- `.planning/phases/VFDO-28-…/28-CONTEXT.md`, `.planning/ROADMAP.md:2005-2076`, `.gitignore`,
  `plugin/.claude-plugin/plugin.json`, `plugin/*/module.json`, `.planning/config.json`

### Commandes rejouées ce jour (HIGH)
- `awk 'END{print NR}'` sur 6 scripts · `find plugin scripts -type f -path '*/tests/test-*.sh'`
- `bash plugin/_internal/resolve-deps.sh conductor` · `… dev-orchestrator`
- `cat ~/.claude/gsd-core/VERSION` · `node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree`
- `node … gsd-tools.cjs worktree base-check` (3 états : repo, lab neuf sans réglage, lab neuf avec)
- `node … gsd-tools.cjs dispatch-isolation` · `claude --version` · `claude plugin {--help,validate --help,install --help}`
- balayage awk du frontmatter des 31 agents (isolation / vf-mcp-* / mcp__)
- `rtk proxy grep -rn` (grep brut, hors proxy) pour tous les recensements d'appelants

### Secondaires (référencées, non reproduites)
- `.planning/research/2026-08-10-agents-paralleles-etat-de-l-art.md` — état de l'art marché
- `docs/ADR.md:601` (ADR-054) · `.planning/PROJECT.md:74` · `CLAUDE.md` (ADR-029, ADR-031, ADR-044)

### À ne pas reprendre (LOW / périmé)
- `.planning/research/2026-08-05-parallelisation-execution.md` — faits moteur sur **1.9.1** ;
  §10 les remplace.

---

## Metadata

**Répartition de confiance :**
- Anatomie du gate, seuils, corpus, rosters, CI : **HIGH** — lu ligne à ligne, chaque affirmation
  porte son `fichier:ligne`.
- Faits moteur 1.10.0 : **HIGH** — sondes rejouées, sorties verbatim, discriminance mesurée.
- Outillage plateforme : **HIGH sur ce poste** (2.1.226), **LOW en généralisation** (A5).
- Disponibilité `jq`/`python3` sur les runners `gates`/`lab-frais` : **LOW** (A1, A2 — preuves
  indirectes, aucune assertion CI).

**Research date:** 2026-08-10
**Valid until:** ~7 jours pour les faits moteur (gsd-core bouge vite : 1.9.1 → 1.10.0 en 5 jours) ;
~30 jours pour la mécanique interne du dépôt.
