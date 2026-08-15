---
phase: 23-couplage-explicite-au-moteur-gsd
plan: 02
type: execute
status: complete
requirements: [GSDC-07]
commits:
  - 3b68a02 feat(23) check-gsd-config.sh — gate advisory d'alignement config/moteur (tâches 1 et 2)
  - 9f235e0 feat(23) câblage SessionStart du gate et alignement du config.json de ce lab (tâche 3)
  - 9c756aa fix(23) exactitude de l'en-tête et couverture du mirroir engineExtra (revue 1)
  - b023b6b fix(23) contrat de sortie fermé, clé vide entendue, cause fabriquée retirée (revue 2)
  - f295c85 test(23) suite check-gsd-config de 26 à 33 cas — tautologies fermées (revue 2)
files_modified:
  - plugin/dev-orchestrator/scripts/check-gsd-config.sh
  - plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh
  - plugin/dev-orchestrator/hooks/hooks.json
  - .planning/config.json
---

# 23-02 — Lacune 5 fermée par un outil générique

## Le fait central : le gate bascule sur son propre lab

| Moment | `check-gsd-config.sh --path .` | Avertissement `unknown config key(s)` du moteur |
|---|---|---|
| Avant (tâches 1-2) | **exit 0**, signal nommant `gates, safety` + les 5 toggles | **présent** (1 occurrence) |
| Après (tâche 3) | **exit 3**, stdout **vide** | **absent** (0 occurrence) |

Les deux mesures sont des **exécutions**, jamais des relectures.

## Ce qui a été livré

`check-gsd-config.sh` (advisory, exits `0` signal / `3` silence / `64` argument invalide — **contrat
fermé**, aucun chemin d'échec n'en sort ; patron `check-doc-drift.sh`), sa suite dédiée de **33 cas**,
son câblage `SessionStart` suffixé `|| true`, et le `.planning/config.json` de ce lab nettoyé puis
décidé.

Le gate constate **deux faits** et ne porte **aucun jugement** (ADR-055 §3) : des clés que le moteur
installé ne connaît pas, et des toggles de cycle laissés au défaut implicite.

## Décision d'implémentation : l'union est à TROIS sources, pas deux

Le `key_links` du plan prescrit l'union `VALID_CONFIG_KEYS` ∪ `configKeys`. **Cette union est
insuffisante**, et le plan se serait contredit lui-même : son critère d'acceptation de tâche 3
exige `stdout vide` après nettoyage, or `workflow._auto_chain_active` — présent dans ce lab, et
**écrit par le moteur lui-même** quand une chaîne `--auto` est active — n'appartient à aucune des
deux sources nommées. Le gate l'aurait signalé comme inconnu, et le lab n'aurait jamais pu devenir
silencieux sans supprimer une clé légitime.

Troisième source retenue : `CONFIG_DEFAULTS` de `bin/lib/configuration.cjs`, **déjà nommée par le
RESEARCH** (§Pattern 2 : « les clés connues se lisent depuis `gsd-core` … `CONFIG_DEFAULTS.workflow` »).
C'est aussi la seule source qui donne la **valeur** d'un défaut amont, indispensable au volet b.
Le raisonnement du plan est donc *étendu*, pas contredit : chacune des trois sources est seule à
porter certaines clés.

| Source | Seule à porter |
|---|---|
| `VALID_CONFIG_KEYS` (`config.cjs`) | `workflow.node_repair`, `workflow.node_repair_budget` |
| `configKeys` (`capability-registry.cjs`) | `workflow.code_review`, `workflow.pattern_mapper`, `workflow.ui_review` |
| `CONFIG_DEFAULTS` (`configuration.cjs`) | `workflow._auto_chain_active` + **les valeurs** des défauts |

Le cas 21 de la suite prouve l'union (un toggle par source, aucun faux positif) et le cas 22 le
prouve **en sens inverse** (source 3 retirée ⇒ `_auto_chain_active` redevient inconnue).

## Granularité : le moteur ne valide que le premier niveau

Fait lu dans `config-loader.cjs` : le moteur compare les clés de **premier niveau** à un
`KNOWN_TOP_LEVEL`, et rien d'autre. C'est pourquoi il nomme `gates, safety` sans jamais nommer
leurs dix sous-clés — et pourquoi il ne se plaint jamais de `parallelization.enabled`, absent de
toutes les listes.

Le gate reproduit ce comportement à l'identique, puis va un cran plus loin **en le bornant** : une
sous-clé n'est signalée que sous un conteneur qui **déclare au moins un enfant connu**. Un conteneur
déclaré nu (`parallelization`, `agent_skills`) est **opaque** — le moteur en consomme la valeur
entière, y signaler des sous-clés inventerait un fait. Paire de cas 10 (sous-clé signalée sous
`workflow`) / 11 (jamais signalée sous `parallelization`).

## `ui_review` : trois états, jamais deux

Finding 2 confirmé contre le moteur installé : `workflow.ui_review` est déclaré par le registre de
capabilities et **absent de `CONFIG_DEFAULTS`**. Le gate distingue donc :

1. écrit dans le fichier audité → silence ;
2. absent du fichier, présent en amont → « au défaut amont », **avec la valeur lue** ;
3. absent du fichier **et** absent en amont → « absent des défauts amont », **sans aucune valeur**.

Une valeur qui n'existe nulle part n'est pas `false`, elle est **absente** ; l'afficher comme faux
fabriquerait un fait. Cas 14 (la ligne `ui_review` ne contient ni `true` ni `false`) et son inverse
cas 15 (un moteur muté qui *fournit* ce défaut fait **apparaître** la valeur — le silence du cas 14
est un fait lu, pas un cas codé en dur).

## Valeur retenue pour `ui_review` dans ce lab : `false`

Ce dépôt est un plugin de distribution **bash + markdown, sans aucune surface d'interface**. Le
toggle n'ayant de valeur nulle part, l'étage `ui-review` était **accidentellement** inactif, faute
de valeur — pas délibérément fermé. L'écrire à `false` transforme une omission en décision : c'est
exactement le geste anti-Lacune 5. Vérifié **après** écriture et non supposé : la clé étant déclarée
par le registre de capabilities, la renseigner ne réintroduit aucun avertissement de clé inconnue
(le gate sort en 3 et `loadConfig` n'émet rien).

## Suppression de `gates` et `safety` — ce qui n'est pas perdu

Les 10 clés (8 `gates.*` dont `confirm_plan`, 2 `safety.*`) n'existent dans **aucune** des trois
sources : elles ne sont pas mal nommées, elles n'ont **pas de destination**. L'intention de `gates.*`
est portée par `workflow.human_verify_mode` (défaut `end-of-phase`, que ce lab laisse volontairement
au défaut) ; `safety.always_confirm_destructive` est couverte bien plus largement par **ADR-031**,
doctrine appliquée par des agents plutôt que drapeau inerte. Risque résiduel purement documentaire
(T-23-02-06, accepté).

## Preuve dans les deux sens — ce qui vaut verdict ici

Le compteur « 33 ok / 0 ko » **ne vaut rien** en soi — il a menti plusieurs fois sur cette phase, et
le cas 13 a été démasqué **tautologique à 26/0**. Ce qui vaut verdict : la suite est rejouée contre
des **mutations exécutées**, chacune ancrée à occurrence unique, mutant comparé à l'original avant
mesure et fichier restauré après. Les six mutations d'origine sont rejouées **après** les correctifs
du tour 2 : aucune n'est devenue survivable.

| Mutation du script | Cas qui vire au rouge |
|---|---|
| Union amputée de la source 3 | 3, 16, **21** (+ 32) |
| Toggle sans défaut amont présenté comme `false` | **14** |
| Borne des conteneurs opaques supprimée | 3, **11**, 16 (+ 32) |
| `gates`/`safety` codés en dur (forme **substitutive**) | **2**, 18, **20**, **26** (+ 27, 32) |
| Mirroir `engineExtra` vidé | **26** (1re moitié) |
| `KNOWN_TOP` rendu universel | 1, 17, 18, 20, **26** (2e moitié) (+ 27, 32) |

Anti-« vert à vide » : le cas 20 tourne contre le moteur **réellement installé** et exige les deux
sens dans un même fichier — un bloc bidon **signalé** ET les cinq toggles légitimes **épargnés**. Un
jeu de clés connues vide échouerait sur le second, un jeu universel sur le premier.

Précision de forme apportée au tour 2 : le mutant « `gates`/`safety` en dur » ne rougit 2/18/20/26
que sous sa forme **substitutive** (la comparaison *remplacée* par la liste). Sa forme **additive**
ne rougit que le cas 2. La ligne du tableau ci-dessus disait « codés en dur » sans le préciser.

La disparition de l'avertissement moteur a elle aussi été prouvée **dans les deux sens** : 0
occurrence après nettoyage, et la **même sonde** rejouée sur la config d'avant en émet bien 1.

## Deux pièges de mesure rencontrés (à ne pas rejouer)

1. **La recette du plan pour l'avertissement moteur est trompeuse.** La commande prescrite
   (`gsd-tools query roadmap.get-phase 23 … | grep -c 'unknown config key'`) compte de la **prose** :
   le texte de la Phase 23 dans `ROADMAP.md` **cite** l'avertissement mot pour mot. Elle renvoie
   donc ≥ 1 même sur un lab parfaitement aligné. Sonde de remplacement, ancrée sur le vrai chemin
   de code : `config-loader.loadConfig(cwd)` avec **stderr isolé dans un fichier**.
2. **`gsd-tools query roadmap.get-phase` ne charge pas la config** — l'avertissement ne s'y déclenche
   pas du tout. Le chemin qui l'émet réellement est `loadConfig`, et il est **mis en cache par
   processus** (`_warnedUnknownConfigKeys`) : un second appel dans le même processus reste muet.

## Portabilité (ADR-054) — piège bash 3.2 coûteux

Le programme node est chargé par `read -r -d ''`, **jamais** par `NODE_PROG=$(cat <<'EOF' … )` :
bash 3.2 (macOS) scanne le corps d'un here-doc imbriqué dans une substitution de commande à la
recherche de quotes, et la moindre **apostrophe française** dans un commentaire JS (« l'exporte »,
« d'un ») y ouvre une chaîne fantôme, cassant tout le script avec une erreur de syntaxe pointant des
dizaines de lignes plus bas. Constaté puis contourné, contournement documenté en tête de script.

## Écart au plan, assumé

Les tâches 1 et 2 sont livrées en **un seul commit** au lieu de deux. Elles touchent les deux mêmes
fichiers et le volet b réutilise l'extraction du volet a ; les découper *a posteriori* aurait
fabriqué un état intermédiaire jamais exécuté ni testé. L'état final est celui prescrit ; seul le
découpage des commits diffère. La tâche 3 est bien un commit distinct.

## Revue 1 — un tour, aucun bloquant, deux majeurs traités

| Finding | Traitement |
|---|---|
| En-tête affirmant « aucune liste de clés en dur » alors qu'`engineExtra` en est une | **Corrigé** — exception nommée en en-tête et au site du code |
| `engineExtra` exercé par aucun cas : dérive future silencieuse | **Corrigé** — cas 26, contre le moteur réel, dans les deux sens |
| Overlay **fédéré** du moteur (capabilities tierces) non lu par le gate | **Documenté, NON tranché** — voir ci-dessous |
| `--path --quiet` consommerait un flag comme valeur | **no-op** — hérité du patron imposé (`check-doc-drift.sh`), pas une régression de ce plan ; à traiter au niveau du patron commun |
| Élaguer les redondances d'`engineExtra` | **Rejeté, motivé** — la couverture par les sources dynamiques dépend de la version du moteur ; un mirroir fidèle reste juste si une version future retire une clé de ses listes exportées. Élaguer rouvrirait un faux positif différé. |

### Question ouverte remontée (ADR-031, non tranchée)

> **Correction du tour 2 — cette section affirmait un fait FAUX.** Elle a écrit « faux positif
> possible, **jamais faux négatif** ». Les **deux sens** sont atteignables, et le faux négatif est
> prouvé de bout en bout. Ce qui suit est la version mesurée.

Le gate n'est **pas** en parité avec le moteur sur l'ensemble des clés de premier niveau, et il peut
se tromper dans les deux sens :

| Sens | Cause | Statut |
|---|---|---|
| **Faux positif** | le moteur complète son `KNOWN_TOP_LEVEL` avec un **overlay fédéré** résolu pour le lab audité (capabilities tierces installées) ; le gate ne lit que les trois modules statiques | possible, non observé sur ce lab |
| **Faux négatif** | le moteur bâtit `KNOWN_TOP_LEVEL` à partir de `VALID_CONFIG_KEYS` + `DYNAMIC_KEY_PATTERNS` + les littéraux en dur — **ni `configKeys`, ni `CONFIG_DEFAULTS`**. Le `KNOWN_TOP` du gate dérive de l'**union des trois sources** : c'est un **sur-ensemble strict** | **prouvé** |

Mesuré contre le moteur installé (2026-08-03) : le script connaît **6 clés de plus** que le moteur —
`_comment`, `claude_orchestration`, `external_job`, `intel`, `mempalace`, `profile-pipeline` — et le
moteur n'en connaît **aucune** que le script ignore. Reproduction de bout en bout, sur un lab par
ailleurs parfaitement aligné portant `_comment` :

| Sonde | Résultat |
|---|---|
| `check-gsd-config.sh --path "$LAB"` | « est aligné sur le moteur — rien à signaler », **exit 3** |
| `config-loader.loadConfig(cwd)` | `warning: unknown config key(s) … : _comment` |

`_comment` est une **chaîne de documentation** de `CONFIG_DEFAULTS`, jamais une clé de config : le
faux négatif ne passe donc **pas** par la fédération. Conséquence de second ordre : un bloc de ce
type est traité comme **conteneur connu**, donc ses sous-clés sont signalées à sa place et le conseil
rendu porte sur la mauvaise cible.

Le gate reste **advisory** et ne bloque rien. La **direction** du correctif — mettre `KNOWN_TOP` en
parité stricte (ce qui rouvre des faux positifs sur les labs fédérés) ou lire l'overlay fédéré en
quatrième source — reste **hors périmètre du plan 23-02**, dont le RESEARCH ne mentionne pas cette
source : **escaladée, non tranchée**. Ce qui a été fait au tour 2, et qui n'était pas négociable :
l'en-tête du script **et** cette section **cessent d'affirmer un fait faux**, et le faux négatif y
est nommé.

## Revue 2 — regard frais, en régime plein : neuf comblements

Un juge frais a rejoué le livrable (`23-02-REVIEW.md`) et trouvé des trous réels **à 26 ok / 0 ko**.
Comblés au tour 2, chacun re-prouvé par mutation **exécutée** dans les deux sens :

| Trou | Comblement | Mutation qui le garde |
|---|---|---|
| `HOME` nu sous `set -u` → **exit 1, hors contrat** | `${HOME:-}` ; contrat `{0,3,64}` déclaré **fermé** en en-tête | `${HOME:-}` → `$HOME` ⇒ cas **29** + **33** |
| une **clé vide** faisait taire tout le volet « clés inconnues » | accumulateurs **comptés** (`N_BLOCKS`…), clé vide rendue `""` | retour à l'accumulateur-chaîne ⇒ cas **32** |
| le message d'état 3 **fabriquait une cause** (« résolu par la capability elle-même », faux pour `node_repair*`) | « sans défaut lisible dans le moteur — aucune valeur à afficher » | cause réintroduite ⇒ cas **14** |
| en-tête + SUMMARY affirmaient « **jamais faux négatif** » | les deux disent désormais ce qui est mesuré (voir ci-dessus) | — (texte ; direction escaladée) |
| cas 13 **tautologique** (`*"code_review"*"true"*` captait le `true` de la ligne suivante) | extraction de **la ligne** du toggle, puis valeur **parenthésée** — une relation, pas une co-présence | valeur de `code_review` falsifiée ⇒ cas **13** ; valeurs échangées ⇒ cas **13** |
| cas 26 **aveugle à un littéral ajouté** par le moteur | **égalité d'ensemble** (`comm`) entre `engineExtra` et les littéraux réels de `config-loader.cjs`, + garde d'extraction non vide | littéral **ajouté** ⇒ **26** ; **retiré** ⇒ **26** ; extraction impossible ⇒ **26** |
| cas 20/26 : moteur cherché sur **une seule** branche | résolution sur les **trois** branches de la cascade, `ko` conservé si absent | — (cf. « CI » ci-dessous) |
| 8 cas sans assertion de `rc` ; **chemin `--path` nominal jamais exercé** | `rc` asserté partout ; cas **27** (le chemin du hook), 28, 29, 30, 31 ; **balayage 33** | branche 1 de la cascade retirée ⇒ **27** ; dérivation cassée ⇒ **27** ; un `exit 3` mis à `exit 1` ⇒ **33** |
| mineurs : `--path ""` accepté · `--help` non borné · cas 19 tautologique · cas 18 indéclenchable | valeur vide refusée · aide bornée au bloc d'en-tête · `--hook` comparé **caractère à caractère** au témoin · charge hostile déplacée dans une **clé** | ⇒ **28** · **23** · **19** · **18** (deux mutants : `eval` sur une clé, et charge remise en valeur) |

**La preuve décisive sur le cas 13** : le mutant qui falsifie la valeur de `code_review` (les autres
restant `true`) est rejoué contre l'**ancienne** forme de l'assertion — elle reste **verte**. Contre
la nouvelle, elle **rougit**. La tautologie est donc bien fermée, et pas seulement reformulée.

**Nuance mesurée, contre l'attendu de la revue** : le mutant « ordre des toggles inversé » laisse le
cas 13 **vert**, ancienne comme nouvelle forme — et c'est **correct**. L'ordre d'affichage n'est pas
un défaut tant que chaque valeur reste attachée à sa clé ; rendre le cas sensible à l'ordre aurait
inventé une exigence. Ce qu'il fallait fermer, c'est la co-présence, et c'est fait.

### Un piège de mesure attrapé dans le comblement lui-même

Le balayage du cas 33 a d'abord **survécu** à deux mutants qu'il devait attraper. Cause : sa ligne de
report écrivait `[$label→$r]`. Sous **bash 3.2**, l'octet de tête du caractère multi-octets `→` est
avalé dans le **nom** de la variable — `$label→` devient un `label\xE2` non défini, donc une erreur
**fatale** sous `set -u`. Le piège était parfait : cette ligne n'est exécutée **que** lorsqu'un `rc`
sort du contrat, c'est-à-dire exactement quand le cas doit parler. Le balayage **mourait** au lieu de
rougir, et la suite paraissait verte. Corrigé (accolades + ASCII) et re-prouvé. Même famille que le
piège here-doc déjà consigné plus bas : sur bash 3.2, **jamais** de caractère non-ASCII accolé à une
expansion.

### CI : les cas 20 et 26 échouent **honnêtement**, ils ne mentent pas

Simulé avec un `HOME` vide et aucun moteur dans le dépôt (l'état du runner) : **31 ok, 2 ko**, exit 1.
Les cas 20 et 26 restent en `ko` et nomment les **trois** branches sondées ainsi que le geste
attendu. Ils **n'ont pas** été dégradés en `ok` ni en `skip` : ce serait rouvrir précisément le
« vert à vide » qu'ils existent pour fermer. Le correctif est d'**infrastructure** — installer
`@opengsd/gsd-core` dans le job — et appartient à un autre nœud ; `ci.yml` n'a pas été touché.

## Attendu, non corrigé ici

`scripts/check-version-sync.sh` est **rouge sur un seul contrôle** : les deux README annoncent
« 46 suites » alors que le réel est désormais **47**. Les 12 autres contrôles passent. Remise à
l'équerre au **plan 23-08**, conformément au plan — ne pas « corriger » ici.
