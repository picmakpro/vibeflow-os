# Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention - Context

**Gathered:** 2026-07-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Cette phase délivre **la doctrine documentaire de sortie du moteur de dev, et la captation
d'intention en langage naturel qui la déclenche** — rien d'autre.

Concrètement, trois surfaces et une garantie machine :

1. une **référence de doctrine** (`docs-flow.md`) qui distingue les quatre familles documentaires
   que GSD outille séparément, et dit pour chacune : ce qu'elle maintient, quand la déclencher,
   sous quel régime de confirmation, et ce qu'elle ne fait jamais ;
2. la **carte d'intention** (`intent-routing.md`) enrichie des formulations réelles qui mènent à
   chacune de ces familles, et du protocole de désambiguïsation quand la formulation est creuse ;
3. les **deux managers** (`vf-dev-manager`, `vf-design-manager`) dotés d'une table de moments
   déclencheurs et de la forme DAG du nœud documentaire ;
4. l'extension du **test d'exhaustivité** existant, qui rend la doctrine non-régressable.

**Hors périmètre, explicitement** : aucune modification de `check-doc-drift.sh` (D-13), aucune
réimplémentation d'un moteur GSD, aucun verbe-façade `/vf-docs` (interdit permanent depuis
v2.33.0), aucune doctrine nouvelle sur l'**entrée** documentaire — `ingestion-flow.md` reste la
seule source sur ce point et n'est ni modifié ni dupliqué (D-02).

</domain>

<decisions>
## Implementation Decisions

### Le fait de départ — quatre familles, un seul routage

Établi sur pièce le 2026-07-31 par lecture des workflows amont (`$HOME/.claude/gsd-core/workflows/`)
confrontés à l'état du module. GSD outille **quatre** métiers documentaires distincts ; VibeFlow
les route par **une** ligne d'`intent-routing.md`. Ce tableau est le socle factuel de la phase et
doit être repris dans `docs-flow.md` — il n'est pas une opinion, il est vérifiable dans les
workflows cités :

| Famille | Brique | Maintient | Preuve |
|---|---|---|---|
| **produit** | `gsd-docs-update` | 6 docs toujours-on (README, ARCHITECTURE, GETTING-STARTED, DEVELOPMENT, TESTING, CONFIGURATION) + 3 conditionnelles (API si `has_api_routes`, CONTRIBUTING si `is_open_source`, DEPLOYMENT si `has_deploy_config`) ; **plus** une *review queue* des docs manuscrites vérifiées contre le code ; **plus** une détection de trous. **CHANGELOG jamais régénéré.** | `workflows/docs-update.md` steps `classify_project`, `build_doc_queue` |
| **entrée** | `gsd-ingest-docs`, `gsd-import` | specs/ADR/PRD/DOC → `.planning/` (PROJECT, REQUIREMENTS, ROADMAP, STATE). Précédence `ADR > SPEC > PRD > DOC`, gate BLOCKER, cap 50 docs | `workflows/ingest-docs.md` ; doctrine locale déjà écrite : `ingestion-flow.md` |
| **code** | `gsd-map-codebase` | `.planning/codebase/` — 7 documents par 4 mappeurs parallèles (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS). Modes `--fast [--focus]`, `--query {term\|status\|diff\|refresh}` | `skills/gsd-map-codebase/SKILL.md`, `workflows/map-codebase.md` |
| **savoir** | `gsd-extract-learnings`, `gsd-graphify` | LEARNINGS.md de phase (décisions, leçons, patterns, surprises) depuis PLAN/SUMMARY/VERIFICATION/UAT/STATE ; graphe de connaissance | `workflows/extract-learnings.md` |

- **D-00 [factuel] :** Ce cadrage a été produit **en conversation avec Samuel**, quatre zones grises
  posées et tranchées par lui (`22-DISCUSSION-LOG.md`). Aucune décision ci-dessous n'est une
  assumption auto-confirmée, sauf celles explicitement marquées `[assumption]`.

---

### Zone 1 — Hébergement et périmètre de la doctrine

- **D-01 [tranché, Samuel] :** La doctrine vit dans **`plugin/dev-orchestrator/references/docs-flow.md`**,
  strictement symétrique d'`ingestion-flow.md` (même module, même chargement on-demand, même chemin
  d'install D7 : `.claude/agents/dev-orchestrator-references/docs-flow.md`). Le module `design-orchestrator`
  y **renvoie**, comme il renvoie déjà à `mission-cross-team.md` — il n'en héberge aucune copie.
  Écartés : le team-kernel du conductor (il hébergerait une doctrine parlant d'outils `gsd-*` absents
  de son propre module) et l'éclatement par métier (deux sources de vérité sur le même geste, ce
  qu'ADR-057 interdit).
  — **Reversibility:** costly — déplacer le fichier après coup casse les renvois posés dans
  `AGENT.md`, les deux managers, le test d'exhaustivité et le chemin d'install D7 des labs déjà
  déployés ; le choix se prend maintenant, pas après.

- **D-02 [tranché, Samuel] :** `docs-flow.md` couvre **les quatre familles** — mais traite en propre
  seulement **produit / code / savoir**, et se contente d'un **RENVOI** vers `ingestion-flow.md` pour
  l'entrée. Jamais de duplication : `ingestion-flow.md` reste la source unique sur la découverte, le
  manifest, les garde-fous BRDG-03 et le gate BLOCKER. La valeur ajoutée du fichier est le
  **discernement entre familles**, pas la réécriture de ce qui existe.

### Zone 2 — Régime d'autonomie et de confirmation

- **D-03 [tranché, Samuel] :** **Gradation par le risque réel, pas par le volume** — même axe que la
  revue graduée livrée en Phase 20 (`mission-flow.md` §Pattern E §3) :
  - `gsd-docs-update --verify-only` est **libre** : read-only, n'écrit aucun fichier, ne commite
    rien. Un agent peut le lancer seul pour **constater** avant de proposer.
  - la **génération standard** (sans flag) exige une **confirmation humaine explicite** avant
    l'appel, au même titre que l'ingestion (ADR-031) : le geste écrit jusqu'à 9 fichiers et
    **commite** (`commit_docs: true` dans `.planning/config.json` de ce lab).
  Écarté : se fier aux gates internes du moteur (`preservation_check`, `AskUserQuestion` de queue) —
  ils **tombent** quand le skill est invoqué depuis un sous-agent qui n'a pas `AskUserQuestion` au
  runtime, défaut exact déjà constaté en Phase 20 (D-09, nœud `checkpoint-doctrine` gelé).

- **D-04 [tranché, Samuel] :** **En mission autonome** (`vf-auto`, « la nuit », absence de
  l'utilisateur) : **constater et consigner, jamais écrire**. Le manager lance `--verify-only`,
  porte le constat au rapport de mission, et propose la génération en next step. La doc périmée est
  **tracée**, jamais corrigée en douce pendant que personne ne regarde.

- **D-05 [tranché, Samuel — CONTRE la recommandation] :** Le flag `--force` (régénère tout, écrase
  les docs manuscrites sans prompt de préservation) est **autorisé sur intention explicite** de
  l'utilisateur. La recommandation était de l'interdire aux agents ; Samuel a tranché l'inverse et
  ce choix tient. Il est borné par D-06.
  — **Reversibility:** reversible — une ligne de doctrine et une branche de routage.

- **D-06 [tranché, Samuel] :** Garde-fou de `--force`, non négociable, en trois temps :
  1. l'agent **reformule ce qui sera écrasé** — nombre et **liste** des docs manuscrites concernées,
     dérivée du champ `existing_docs` de l'init JSON du moteur (`{path, has_gsd_marker}` : celles
     sans marqueur GSD sont le travail humain à risque) ;
  2. il **attend un oui** explicite ;
  3. `--force` est **interdit en mission d'équipe et en mode autonome** — le déclencheur vient de
     l'utilisateur, en direct, jamais d'un manager.

### Zone 3 — Moments déclencheurs et forme DAG

- **D-07 [tranché, Samuel] :** En mission d'équipe, le geste documentaire est **UN nœud agrégé en
  fin de mission**, `deps` = tous les nœuds `exec-*` de la mission :
  ```bash
  "$S"/dag.sh add --file="$DAG" --id=docs --step="hygiène documentaire" --deps=exec-9,exec-10,…
  ```
  Le coût réel du moteur (jusqu'à 9 `gsd-doc-writer` + vérificateurs, en waves) est payé **une fois,
  sur l'état final**. Écarté : un nœud par étape — il documenterait des états intermédiaires déjà
  périmés à l'étape suivante, et re-traiterait les mêmes fichiers à chaque tour.

- **D-08 [tranché, Samuel] :** Le nœud est posé quand **au moins un** de ces quatre déclencheurs
  tombe. Chacun doit rester un **FAIT constatable** (ADR-055 §3), jamais un jugement au feeling :
  | Déclencheur | Constat |
  |---|---|
  | **surface publique touchée** | le diff de mission modifie une API, une CLI, une config, un schéma — précisément ce que décrivent README / API.md / CONFIGURATION.md |
  | **`[doc-drift]` actif** | `check-doc-drift.sh` sort en **exit 0** au démarrage de session (exit 3 = silence). Fait déjà produit par un script existant, coût nul |
  | **fin de milestone** | la clôture enchaîne déjà `gsd-audit-milestone` → `gsd-complete-milestone` → `gsd-cleanup` ; le geste documentaire s'y insère |
  | **nouveau module / capacité** | un répertoire de module ou un point d'entrée apparaît — il n'a, par construction, aucune doc |

  Aucun déclencheur ne tombe → **pas de nœud**, et c'est un état normal, pas un manque.

- **D-09 [assumption, Likely] :** Le nœud `docs` respecte le régime D-03/D-04 : en mode superviser il
  peut proposer la génération au checkpoint ; en mode autonome il se limite à `--verify-only` + constat.
  Le rapport typé du nœud suit le contrat existant (`mission-flow.md` Pattern C) — `passed` si la doc
  est jugée à jour, `gaps_found` avec les docs périmées en `findings`, `action: ask-user` sur toute
  génération à confirmer. **Aucun nouveau format de rapport n'est introduit.**

### Zone 4 — Désambiguïsation d'intention et périmètre design

- **D-10 [tranché, Samuel] :** « Mets à jour la doc » vise quatre familles. Routage **au jugement du
  contexte**, une question courte seulement si la formulation est vraiment creuse — c'est
  l'heuristique 5 déjà en vigueur (`AGENT.md` §Heuristiques). Ancrages contextuels attendus :
  | Ce qui vient de se fermer | Famille visée par défaut |
  |---|---|
  | une étape a été exécutée, du code a bougé | **produit** (`gsd-docs-update`) |
  | le repo est inconnu / `.planning/codebase/` absent ou daté | **code** (`gsd-map-codebase`) |
  | une phase vient d'être vérifiée / clôturée | **savoir** (`gsd-extract-learnings`) |
  | un document de cadrage traîne hors de la feuille de route | **entrée** (renvoi `ingestion-flow.md`) |
  | rien de tout cela — formulation creuse en début de session | **une question courte**, jamais une devinette |

- **D-11 [tranché, Samuel] :** `vf-design-manager` adopte **la même doctrine et les mêmes
  déclencheurs** que `vf-dev-manager` : il pose le même nœud `docs` agrégé en fin de mission design
  quand D-08 tombe (une refonte complète modifie la surface visible et périme ARCHITECTURE/README
  aussi sûrement qu'un refactor). Son gate `DESIGN.md` reste **inchangé et distinct** — la bible
  visuelle n'est pas de la doc produit. **Aucun changement de frontmatter** : il porte déjà `Skill`
  dans ses `tools:` (vérifié — `plugin/design-orchestrator/agents/vf-design-manager.md:4`).

- **D-12 [tranché, Samuel] :** Les formulations réelles à capter, par famille, entrent dans
  `intent-routing.md`. Les lacunes actuelles nommément visées — aucune ne tombe aujourd'hui de façon
  fiable : « la doc est fausse » · « ça correspond plus au code » · « documente ce module » · « il
  manque la doc d'API » · « vérifie que la doc dit encore vrai » (→ `--verify-only`, **jamais exposé
  à ce jour**) · « on a changé l'archi » · « refais toute la doc » (→ `--force` + D-06) ·
  « qu'est-ce qu'on a appris ». La liste finale est du ressort du plan, mais **`--verify-only` et
  `--force` doivent chacun avoir leur formulation déclencheuse** — c'est ce qui distingue auditer
  de régénérer, aujourd'hui indiscernables.

- **D-13 [tranché, Samuel] :** `check-doc-drift.sh` reste **inchangé**. Il continue de constater le
  seul fait qu'il sait produire (N commits de code sans commit de doc) ; c'est la doctrine qui
  gradue la réponse. Respecte ADR-055 §3, zéro code nouveau, zéro suite à réécrire. Écarté :
  l'enrichir pour nommer les docs périmées — ce serait du **jugement déguisé en fait** (une doc peut
  légitimement ne pas avoir bougé) et cela doublerait le périmètre de la phase.

### Zone 5 — Garantie machine

- **D-14 [tranché, Samuel] :** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` est
  **étendu** (jamais dupliqué en suite séparée — le compteur racine « N suites » des deux README est
  gaté par `check-version-sync.sh`, une suite nouvelle obligerait à le rattraper). Assertions
  attendues, à préciser au plan :
  - `docs-flow.md` existe et est **référencé** par `AGENT.md`, `vf-dev-manager.md` et
    `vf-design-manager.md` (la même mécanique que la boucle existante ligne ~923, qui vérifie déjà
    `GSD-PIPELINE.md`, `gsd-skills-index.md`, `intent-routing.md`, `mission-contracts.md`) ;
  - les **quatre familles** y sont traitées (produit / code / savoir + renvoi entrée) ;
  - la **ligne rouge `--force`** (D-06 : jamais en mission, jamais en autonome) y est écrite ;
  - le test d'exhaustivité de routage existant **reste vert** — les briques ajoutées à
    `intent-routing.md` sont déjà dans l'index, aucune whitelist nouvelle n'est requise.
  — **Reversibility:** reversible.

### Claude's Discretion

- La **structure interne** de `docs-flow.md` (ordre des sections, forme des tables) — contrainte par
  ADR-029 et par la symétrie avec `ingestion-flow.md` (94 lignes), pas par une préférence exprimée.
- La **liste exacte** des formulations de D-12, tant que `--verify-only` et `--force` ont chacune
  la leur.
- La **forme exacte** des assertions de D-14, tant que les quatre points sont couverts.
- Le découpage en plans.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Doctrine locale à étendre ou à respecter (repo courant)

- `plugin/dev-orchestrator/references/ingestion-flow.md` — **le patron à imiter** : structure,
  ton, granularité des garde-fous, chargement on-demand. `docs-flow.md` en est le symétrique et y
  renvoie pour toute la famille « entrée » (D-02).
- `plugin/dev-orchestrator/references/intent-routing.md` — **seul fichier du module qui décide du
  routage**. La ligne à enrichir : §Contexte & session, « mets à jour la doc / génère le README /
  la doc est périmée ». Sa §Couverture explique le contrat d'exhaustivité vérifié par le test.
- `plugin/dev-orchestrator/references/mission-flow.md` §Pattern B (DAG, `dag.sh add --deps`),
  §Pattern C (contrat de rapport typé), §Pattern E (gradation par le risque — **l'axe repris par
  D-03**), §Résolution des scripts (`$S`, scope-robuste).
- `plugin/dev-orchestrator/references/mission-contracts.md` — brief, digest de mission, rapport.
- `plugin/dev-orchestrator/AGENT.md` — agent `vibeflow-dev` : carte d'intention raccourcie,
  §Next steps & hygiène documentaire (rôle actif), §Signaux de démarrage (table `[doc-drift]`),
  §Références (chemin d'install D7 — **y ajouter `docs-flow.md`**).
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` §Hygiène documentaire & next steps (les 3
  puces actuelles à remplacer par la table de D-08) et §Orchestration par étape (pose du nœud).
- `plugin/design-orchestrator/agents/vf-design-manager.md` — cible de D-11. Vérifié : `Skill` déjà
  présent dans `tools:` (ligne 4), aucun changement de frontmatter requis.
- `plugin/dev-orchestrator/references/mission-cross-team.md` — précédent de renvoi dev→design qui
  fonde D-01.

### Faits outillés existants (ne pas réimplémenter — D-13)

- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — signal `[doc-drift]`. Contrat : exit 0 =
  seuil atteint (défaut 20 commits de code sans commit de doc), exit 3 = silence, exit 64 =
  argument invalide. Câblé en `SessionStart` (`plugin/dev-orchestrator/hooks/hooks.json`).
- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` — famille « entrée », déjà
  doctrinée par `ingestion-flow.md`.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — suite à étendre (D-14).
  Voir sa boucle de vérification des références (~ligne 923) et son test d'exhaustivité de routage
  (~lignes 762-877, dont la whitelist `gsd-tools` et son assertion T4c).
- `plugin/dev-orchestrator/references/gsd-skills-index.md` — **auto-généré**, ne jamais éditer à la
  main ; `build-gsd-index.sh` le régénère. C'est `intent-routing.md` qui s'aligne sur lui.

### Workflows amont — la source de vérité sur ce que font réellement les briques

*(chemins de la machine, hors repo : `$HOME/.claude/gsd-core/`)*

- `workflows/docs-update.md` — 1177 lignes, 17 steps. À lire au minimum : `classify_project`
  (table de classification), `build_doc_queue` (6 + 3 docs, review queue, détection de trous,
  **CHANGELOG jamais queué**), `preservation_check`, `verify_docs`, `fix_loop` (**2 itérations
  max, halt sur régression**), `scan_for_secrets`, `commit_docs`.
- `skills/gsd-docs-update/SKILL.md` — sémantique exacte des flags : `--force` prend le pas sur
  `--verify-only` si les deux sont présents ; un flag n'est actif **que** si son token littéral est
  dans `$ARGUMENTS`.
- `workflows/ingest-docs.md`, `skills/gsd-import/SKILL.md` — famille entrée.
- `skills/gsd-map-codebase/SKILL.md` + `workflows/map-codebase.md` — famille code, §`<when_to_use>`
  (quand rafraîchir, quand sauter).
- `workflows/extract-learnings.md` — famille savoir.

### Doctrine transverse du repo

- `docs/ADR.md` — **ADR-029** (densité : agents ≤ 250 lignes, skills ≤ 500), **ADR-031** (jamais
  d'écriture structurante sans validation humaine — fonde D-03/D-04/D-06), **ADR-055 §3** (le
  script constate le FAIT, l'agent porte le JUGEMENT — fonde D-08 et D-13), **ADR-057** (une
  capacité, une seule voix — fonde D-01 et D-02), **ADR-053** (lock + DAG + rapports typés).
- `CLAUDE.md` racine — discipline de release (toute version = un tag), conventions de commit
  (français), densité.
- `.planning/codebase/CONVENTIONS.md` — nommage, portabilité bash, `jqx()`, préfixe `VF_`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ingestion-flow.md` (94 lignes)** — le gabarit complet : titre avec l'ID d'exigence d'origine,
  encadré de rôle + chargement on-demand + chemin d'install D7, puis Découverte → Construction →
  Délégation → Garde-fous → Interdits. `docs-flow.md` reprend cette ossature, ce qui rend les deux
  fichiers lisibles ensemble sans effort de traduction.
- **Le signal `[doc-drift]` est déjà produit et déjà câblé** — hook `SessionStart`, contrat d'exit
  stable, suite `test-check-doc-drift.sh` existante. D-08 le **consomme** sans le toucher : le
  déclencheur le moins cher des quatre.
- **Le champ `existing_docs` de l'init JSON du moteur** (`{path, has_gsd_marker}`) donne
  gratuitement la liste des docs manuscrites à risque — c'est la matière première de la
  reformulation exigée par D-06, aucun script à écrire.
- **La table de signaux d'`AGENT.md`** (§Signaux de démarrage) a déjà une ligne `[doc-drift]` →
  `gsd-docs-update`, confirmation requise. Elle se gradue plutôt qu'elle ne se crée.
- **`mission-cross-team.md`** est le précédent exact du renvoi dev→design que D-01 institue.

### Established Patterns

- **Une capacité, une seule voix (ADR-057)** — `intent-routing.md` est le SEUL fichier qui décide
  du routage ; `docs-flow.md` porte la doctrine (le pourquoi, le quand, les garde-fous) et ne
  double jamais une table de routage.
- **Test d'exhaustivité** — ajouter une brique interne sans la router fait échouer la suite. Les
  briques doc visées sont déjà routées : aucune whitelist nouvelle, mais toute exception éventuelle
  doit être écrite **dans `intent-routing.md` §Couverture**, pas seulement dans le test.
- **Chargement on-demand** — `GSD-PIPELINE.md`, `intent-routing.md`, `mission-contracts.md`,
  `ingestion-flow.md` ne sont **jamais** chargés en session normale. `docs-flow.md` suit la même
  règle : coût contexte nul tant que l'intention documentaire n'apparaît pas.
- **Densité ADR-029** — `vf-dev-manager.md` est à **217 lignes** sur 250. La table de D-08 doit
  **remplacer** les 3 puces de §Hygiène documentaire, pas s'y ajouter. `AGENT.md` est à 181 lignes.
  C'est la contrainte dimensionnante de la phase, à traiter au plan, pas à découvrir à l'exécution.
- **Français partout** — docs, commentaires, commits, messages d'erreur.

### Integration Points

1. `plugin/dev-orchestrator/references/docs-flow.md` — **création**.
2. `plugin/dev-orchestrator/references/intent-routing.md` — §Contexte & session enrichie (D-10,
   D-12), renvoi vers `docs-flow.md` en §Voir aussi.
3. `plugin/dev-orchestrator/AGENT.md` — §Next steps & hygiène documentaire graduée, §Signaux
   (ligne `[doc-drift]`), §Références (ajout du chemin D7).
4. `plugin/dev-orchestrator/agents/vf-dev-manager.md` — §Hygiène documentaire remplacée par la
   table D-08 + pose du nœud `docs` (D-07) en §Orchestration.
5. `plugin/design-orchestrator/agents/vf-design-manager.md` — renvoi + mêmes déclencheurs (D-11).
6. `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — assertions D-14.
7. `plugin/dev-orchestrator/VERSION` + `CHANGELOG.md` + `README.md` (et le pendant
   `design-orchestrator` si D-11 le modifie) — bump de module, **minor** (nouvelle capacité).
8. Release racine : `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
   les deux README + tag annoté + release GitHub (`CLAUDE.md`, règle non négociable).

</code_context>

<specifics>
## Specific Ideas

- **Le modèle explicitement cité par Samuel** : « comme pour les autres commandes type "on en est
  où ?" qui invoque GSD update ». La cible de qualité est donc `gsd-progress` — une intention
  formulée en langage courant qui tombe **sans friction** sur la bonne brique. La doc doit atteindre
  ce niveau-là, pas un niveau « documenté quelque part ».

- **Le geste doit être explicite quand un manager est nommé** — Samuel : « le but est que dev
  manager / design manager puisse avoir ce workflow explicite quand il est nommé, MAIS AUSSI que
  l'on capte les intentions de l'user ». Les deux voies comptent également : la voie **mission**
  (nœud DAG, D-07/D-08) et la voie **conversation** (captation, D-10/D-12). Une phase qui ne
  livrerait que l'une des deux ne répondrait qu'à la moitié de la demande.

- **Sur `--force`, Samuel a tranché contre la recommandation** (D-05). À ne pas rouvrir en
  planification ni en exécution : le débat a eu lieu, la décision est prise, le garde-fou D-06 est
  la contrepartie négociée.

- **La doc de ce repo-ci n'est pas gérée par `gsd-docs-update`.** `vibeflow-os` maintient un
  `CHANGELOG.md`, un `README.md` et un `VERSION` **par module**, sous gates machine
  (`check-version-sync.sh`, triades par module). Le moteur, lui, ne régénère jamais de CHANGELOG et
  ne connaît que les 9 types canoniques à la racine. `docs-flow.md` doit dire cette frontière noir
  sur blanc, sans quoi un futur agent lancera `gsd-docs-update` sur ce repo et écrasera les README
  de modules. — *Contrainte relevée pendant le cadrage, non discutée : elle découle du fait, pas
  d'une préférence.*

</specifics>

<deferred>
## Deferred Ideas

- **Enrichir `check-doc-drift.sh` pour nommer les docs périmées** (quel fichier de doc n'a pas suivi
  quels fichiers de code). Signal bien plus actionnable, mais c'est du jugement déguisé en fait
  (ADR-055 §3) et cela doublerait le périmètre. Écarté explicitement par Samuel en zone 4 — à
  reconsidérer dans une phase dédiée si le signal binaire actuel s'avère trop grossier à l'usage.

- **Assertion de non-duplication `docs-flow.md` ↔ `ingestion-flow.md`** (le test vérifierait que la
  doctrine d'entrée n'est redéfinie nulle part ailleurs). Proposée en zone 5, non retenue : Samuel
  a choisi l'extension simple du test existant. Le renvoi de D-02 porte l'intention ; la garantie
  machine reste à écrire si le fichier dérive.

</deferred>

---

*Phase: 22-Hygiène documentaire — doctrine de sortie et captation d'intention*
*Context gathered: 2026-07-31*
