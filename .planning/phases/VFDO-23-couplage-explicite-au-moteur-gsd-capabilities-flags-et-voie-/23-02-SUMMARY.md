---
phase: 23-couplage-explicite-au-moteur-gsd
plan: 02
type: execute
status: complete
requirements: [GSDC-07]
commits:
  - 3b68a02 feat(23) check-gsd-config.sh — gate advisory d'alignement config/moteur (tâches 1 et 2)
  - 9f235e0 feat(23) câblage SessionStart du gate et alignement du config.json de ce lab (tâche 3)
  - 9c756aa fix(23) exactitude de l'en-tête et couverture du mirroir engineExtra (revue)
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

`check-gsd-config.sh` (advisory, exits `0` signal / `3` silence / `64` argument invalide, patron
`check-doc-drift.sh`), sa suite dédiée de 26 cas, son câblage `SessionStart` suffixé `|| true`, et
le `.planning/config.json` de ce lab nettoyé puis décidé.

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

Le compteur « 26 ok / 0 ko » **ne vaut rien** en soi. Ce qui vaut verdict : la suite a été rejouée
contre **six mutations du script**, chacune tuée par le cas prévu, puis le script restauré est
repassé au vert à chaque fois.

| Mutation du script | Cas qui vire au rouge |
|---|---|
| Union amputée de la source 3 | 3, 16, **21** |
| Toggle sans défaut amont présenté comme `false` | **14** |
| Borne des conteneurs opaques supprimée | 3, **11**, 16 |
| `gates`/`safety` codés en dur au lieu de comparer | **2**, 18, **20** |
| Mirroir `engineExtra` vidé | **26** (1re moitié) |
| `KNOWN_TOP` rendu universel | 1, 17, 18, 20, **26** (2e moitié) |

Anti-« vert à vide » : le cas 20 tourne contre le moteur **réellement installé** et exige les deux
sens dans un même fichier — un bloc bidon **signalé** ET les cinq toggles légitimes **épargnés**. Un
jeu de clés connues vide échouerait sur le second, un jeu universel sur le premier.

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

## Revue — un tour, aucun bloquant, deux majeurs traités

| Finding | Traitement |
|---|---|
| En-tête affirmant « aucune liste de clés en dur » alors qu'`engineExtra` en est une | **Corrigé** — exception nommée en en-tête et au site du code |
| `engineExtra` exercé par aucun cas : dérive future silencieuse | **Corrigé** — cas 26, contre le moteur réel, dans les deux sens |
| Overlay **fédéré** du moteur (capabilities tierces) non lu par le gate | **Documenté, NON tranché** — voir ci-dessous |
| `--path --quiet` consommerait un flag comme valeur | **no-op** — hérité du patron imposé (`check-doc-drift.sh`), pas une régression de ce plan ; à traiter au niveau du patron commun |
| Élaguer les redondances d'`engineExtra` | **Rejeté, motivé** — la couverture par les sources dynamiques dépend de la version du moteur ; un mirroir fidèle reste juste si une version future retire une clé de ses listes exportées. Élaguer rouvrirait un faux positif différé. |

### Question ouverte remontée (ADR-031, non tranchée)

Le moteur complète son `KNOWN_TOP_LEVEL` avec un **overlay fédéré** résolu pour le lab audité — les
clés de config déclarées par des **capabilities tierces installées dans ce lab**. `check-gsd-config.sh`
ne lit que les trois modules statiques. Sur un lab portant de telles capabilities, il peut donc
signaler comme inconnue une clé que le moteur accepte : **faux positif possible, jamais faux
négatif**, et le gate reste advisory (il ne bloque rien).

Vérifié sur ce lab-ci : aucune dérive actuelle (le schéma fédéré y rend exactement les mêmes clés
que le registre statique). La limite est **documentée en en-tête du script**. Élargir la portée à une
quatrième source est **hors périmètre du plan 23-02**, dont le RESEARCH ne mentionne pas cette
source — d'où l'escalade plutôt que l'implémentation silencieuse.

## Attendu, non corrigé ici

`scripts/check-version-sync.sh` est **rouge sur un seul contrôle** : les deux README annoncent
« 46 suites » alors que le réel est désormais **47**. Les 12 autres contrôles passent. Remise à
l'équerre au **plan 23-08**, conformément au plan — ne pas « corriger » ici.
