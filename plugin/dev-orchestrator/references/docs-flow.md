# Docs-flow — doctrine de sortie documentaire (DOCF-01 → DOCF-04)

> Source de vérité de la sortie documentaire : comment `vibeflow-dev` distingue les quatre familles
> documentaires que GSD outille séparément, ce que chacune maintient, et sous quel régime de
> confirmation elle se déclenche — sans jamais réimplémenter ni contourner les gates natifs des
> moteurs `gsd-*` qu'elle délègue. Chargée **on-demand** par `vibeflow-dev`, comme `mission-flow.md`
> et `GSD-PIPELINE.md` — coût contexte nul le reste du temps. Le **fait outillé** sous-jacent
> (N commits de code sans commit de doc) est produit par `check-doc-drift.sh` : ce fichier ne le
> redéfinit pas, il documente comment l'interpréter et ce qu'on en fait.

---

## Discernement — quatre familles, quatre métiers

GSD outille **quatre** métiers documentaires distincts ; VibeFlow les routait jusqu'ici par **une**
seule ligne d'`intent-routing.md`. Ce tableau est le socle factuel du discernement — vérifiable dans
les workflows amont cités, pas une opinion. **Ce n'est pas une table de routage** : le routage reste
la seule affaire d'`intent-routing.md` (ADR-057).

| Famille | Brique | Ce qui est maintenu |
|---|---|---|
| **produit** | `gsd-docs-update` | 6 docs toujours-on (README, ARCHITECTURE, GETTING-STARTED, DEVELOPMENT, TESTING, CONFIGURATION) + 3 conditionnelles (API si routes, CONTRIBUTING si open source, DEPLOYMENT si config de déploiement), une review queue des docs manuscrites, la détection de trous. **CHANGELOG jamais régénéré.** |
| **code** | `gsd-map-codebase` | `.planning/codebase/` — 7 documents produits par 4 mappeurs parallèles. |
| **savoir** | `gsd-extract-learnings` ; `gsd-graphify` (refusée Phase 24 — voir §Famille savoir) | LEARNINGS.md d'étape et graphe de connaissance. |
| **entrée** | `gsd-ingest-docs`, `gsd-import` | specs/ADR/PRD → `.planning/` — doctrinée ailleurs, voir plus bas. |

## Famille produit — gsd-docs-update

`gsd-docs-update` maintient 6 docs toujours-on — README, ARCHITECTURE, GETTING-STARTED,
DEVELOPMENT, TESTING, CONFIGURATION — et 3 conditionnelles : API si le projet expose des routes,
CONTRIBUTING s'il est open source, DEPLOYMENT s'il porte une config de déploiement. Il tient aussi
une *review queue* des docs manuscrites vérifiées contre le code, et une détection de trous
(section attendue absente). **Le CHANGELOG n'est jamais régénéré** — c'est un journal humain, pas
un artefact dérivé du code.

Le régime `--verify-only` (D-03) : **read-only**, n'écrit aucun fichier, ne commite rien — donc
**libre**. Un agent peut le lancer seul pour constater avant de proposer.

## Famille code — gsd-map-codebase

`gsd-map-codebase` maintient `.planning/codebase/` — sept documents (STACK, INTEGRATIONS,
ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS) produits par quatre mappeurs parallèles.
Deux modes : `--fast` (avec `--focus`, cartographie ciblée, rapide) et `--query` (`term`, `status`,
`diff`, `refresh` — interroger l'existant sans le régénérer). La rafraîchir quand le repo est
inconnu de la session ou que `.planning/codebase/` est absent ou daté ; la régénérer seulement
quand la structure du code a matériellement changé, jamais par réflexe.

**`--query` dépend de `intel.enabled`** — le skill amont l'exige littéralement
(`gsd-map-codebase/SKILL.md:29`). Ce lab l'a **activé en Phase 24**, précisément parce que ce
fichier publiait `--query` comme régime normal alors que le geste était inerte : la promesse est
désormais tenue. Un lab qui laisserait `intel.enabled` au défaut amont (`false`) perd ce mode
entier — `--fast` et la cartographie complète continuent, eux, de fonctionner sans lui.

## Famille savoir — gsd-extract-learnings, gsd-graphify

`gsd-extract-learnings` produit le LEARNINGS.md d'une étape — décisions, leçons, patterns,
surprises — dérivé de PLAN, SUMMARY, VERIFICATION, UAT et STATE. Cette famille se déclenche
**après** une vérification ou une clôture d'étape — jamais pendant, le matériau qu'elle synthétise
n'existe pas encore.

`gsd-graphify` (conditionnelle : graphify.enabled) — refusée en Phase 24 :
aucun consommateur prescrit dans le module ; poser ce toggle est ce qui la rendrait active.
Elle construirait et interrogerait le graphe de connaissance du projet dans `.planning/graphs/`.

## Famille entrée — renvoi, jamais de copie

La famille entrée (specs / ADR / PRD → `.planning/`) est déjà doctrinée : `ingestion-flow.md` en
est la **source unique** — découverte outillée par `discover-unintegrated-docs.sh`, construction du
manifest, garde-fous BRDG-03, gate BLOCKER, précédence `ADR > SPEC > PRD > DOC`, cap 50 documents.
Rien de tout cela n'est redit ici (D-02, ADR-057) : la valeur de ce fichier est le discernement
entre familles, pas la réécriture de ce qui existe déjà ailleurs.

## Frontière `.planning/codebase/` ↔ `.planning/intel/`

L'activation d'`intel` (Phase 24) fait cohabiter deux magasins qui parlent tous les deux du code.
Ils ne se remplacent pas, et **les formats le disent avant toute doctrine** — c'est un fait
constatable, pas une convention qu'on aurait décrétée ici.

**`.planning/codebase/`** — sept documents **markdown narratifs** portant du jugement humain daté :
dette technique, limites de montée en charge, fonctionnalités critiques manquantes
(`CONCERNS.md`), contraintes d'architecture (`ARCHITECTURE.md`). Ses lecteurs sont **prescrits
nommément**, pas opportunistes : `vf-dev-manager.md:32`, `vf-auditer.md:3,23`,
`check-dev-bootstrap.sh:27`, `gsd-planner.md:635-653`. Produit par `gsd-map-codebase`.

**`.planning/intel/`** — cinq **JSON machine** (`stack`, `file-roles`, `api-map`,
`dependency-graph`, `arch-decisions`) plus une surface d'API (`API-SURFACE.md`), horodatés et
hashés (`.last-refresh.json`). L'amont **interdit explicitement le temporel** dans ce qu'il y écrit
et n'y reconnaît **qu'un seul consommateur automatique**, auquel il appose lui-même la mention
« indice seulement, possiblement incomplet » (`HINT ONLY … MAY BE INCOMPLETE`). C'est un fait
dérivé, rafraîchissable à volonté et sans coût de jugement.

**La règle qui les sépare**, non négociable : un fait dérivé rafraîchissable ne se substitue
**jamais** à un jugement humain daté. `intel/` alimente une **recherche** — retrouver où quelque
chose vit, quelle surface bouge ; il n'est **jamais cité comme preuve** dans une décision, un
arbitrage ou un rapport d'audit, et il ne **dispense jamais** de rafraîchir `codebase/`. Une
carte qui se régénère toute seule ne peut pas, par construction, porter ce qu'un humain a constaté
et daté.

## Déclencheurs (le FAIT, jamais le jugement)

Le geste documentaire se pose quand **au moins un** de ces quatre déclencheurs tombe. Chacun reste
un **FAIT constatable** (ADR-055 §3), jamais un jugement au feeling :

| Déclencheur | Constat |
|---|---|
| **surface publique touchée** | le diff modifie une API, une CLI, une config ou un schéma — précisément ce que décrivent README / API.md / CONFIGURATION.md |
| **`[doc-drift]` actif** | `check-doc-drift.sh` sort en **exit 0** au démarrage de session (exit 3 = silence) — fait déjà produit par un script existant, coût nul |
| **fin de milestone** | la clôture enchaîne déjà `gsd-audit-milestone` → `gsd-complete-milestone` → `gsd-cleanup` ; le geste documentaire s'y insère |
| **nouveau module / nouvelle capacité** | un répertoire de module ou un point d'entrée apparaît — il n'a, par construction, aucune doc |

Aucun déclencheur qui ne tombe est un **état normal**, pas un manque. Règle ADR-055 §3 : le script
**CONSTATE**, l'agent **JUGE** — `check-doc-drift.sh` n'est pas enrichi pour nommer les docs
périmées, ce serait du jugement déguisé en fait. **Cette table est l'unique source des
déclencheurs** : les deux managers y renvoient au lieu de la recopier.

## Garde-fous

- **Génération standard sous confirmation (D-03)** : la génération standard (sans flag) exige une
  **confirmation humaine explicite** avant l'appel, au titre d'ADR-031, parce qu'elle écrit jusqu'à
  9 fichiers et **commite** (`commit_docs: true`), et parce que se fier aux gates internes du moteur
  ne tient pas : ils tombent quand le skill est invoqué depuis un sous-agent privé
  d'`AskUserQuestion` au runtime (défaut constaté en Phase 20, nœud `checkpoint-doctrine` gelé).
- **Mission autonome (D-04)** : `vf-auto`, « la nuit », absence de l'utilisateur → **constater et
  consigner, jamais écrire**. Le manager lance l'audit read-only, porte le constat au rapport de
  mission, et propose la génération en next step. La doc périmée est **tracée**, jamais corrigée en
  douce pendant que personne ne regarde.
- **`--force` autorisé sur intention explicite (D-05)** — décision tranchée, non rouvrable. Il
  régénère tout et écrase les docs manuscrites sans prompt de préservation.
- **Garde-fou de `--force` en trois temps (D-06)**, non négociable : l'agent reformule d'abord ce
  qui sera écrasé — nombre **et** liste des docs manuscrites concernées, dérivés du champ
  `existing_docs` de l'init JSON du moteur (paires `path` / `has_gsd_marker` : celles sans marqueur
  GSD sont le travail humain à risque) ; il attend ensuite un oui explicite ; et enfin :
  **`--force` est interdit en mission d'équipe et interdit en mode autonome** — le déclencheur vient toujours de l'utilisateur, en direct, jamais d'un manager.

## Interdits

- Aucun verbe-façade dédié à la doc n'existe ni ne doit être réintroduit — la façade des 29 verbes
  a été **supprimée en v2.33.0**, aucun retour arrière. La sortie documentaire se déclenche par
  langage naturel détecté et brique invoquée directement.
- **Ne jamais lancer `gsd-docs-update` sur `vibeflow-os` lui-même** : ce dépôt maintient un `CHANGELOG.md`, un `README.md` et un `VERSION` **par module**, sous gates machine (`check-version-sync.sh`, triades par module).
  Le moteur ne régénère jamais de CHANGELOG et ne connaît que les neuf types canoniques à la
  racine — deux modèles de doc incompatibles.
- Aucune réimplémentation des moteurs délégués : classification de projet, construction de la file
  de docs, contrôle de préservation, vérification, boucle de correction (deux itérations maximum,
  arrêt sur régression) et balayage de secrets appartiennent aux workflows amont, point. La fuite de
  secrets en particulier est **traitée en amont** — ne pas la doubler ici.
