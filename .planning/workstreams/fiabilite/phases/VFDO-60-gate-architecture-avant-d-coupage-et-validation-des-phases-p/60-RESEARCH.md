# Phase 60: Gate architecture avant découpage et validation des phases proposées - Research

**Researched:** 2026-10-29
**Domain:** gates déterministes en bash portable (QUAL-01), doctrine de refus par l'équipe (ADR-031, advisory avec halte), marqueur de phase lisible par le moteur GSD, budget d'instructions ADR-029, livraison d'un worker interne dans un bundle
**Confidence:** HIGH (faits mesurés sur le dépôt et sur gsd-core 1.19.0 installé ; les points de conception ouverts à la recherche ont été tranchés à la planification du 2026-10-29, voir Open Questions (RESOLVED) et `60-PLANNING-REGISTRE.md`)

<user_constraints>
## User Constraints (from CONTEXT.md)

Source : `60-CONTEXT.md`, copiée sans reformulation des décisions ; aucune n'est un arbitrage neuf (mandat Samuel, /vf-auto session principale, 2026-10-29, ne valant pas arbitrage de fond).

### Locked Decisions

- **P60-D-01 (le refus vit dans l'équipe, pas dans un hook).** Source : SEED A-07 ; spec §11 ; spec §7 Q-04.
  - **Phase proposée** : le point de refus est le passage obligé de toute planification/exécution d'équipe, `vf-coder`, avant `gsd-plan-phase` et `gsd-execute-phase` → rapport typé `blocked`, `action: ask-user`. Le manager reçoit ce bloc et applique sa table de pilotage existante : aucun changement de `vf-dev-manager` n'est requis.
  - **Chemin direct `vf-auto`** (moteur `gsd-autonomous`, qui ne passe ni par le manager ni par `vf-coder`) : le skill `vf-auto` porte le même contrôle avant sa boucle.
  - **Découpage avant architecture** : le head, sur une intention de découpage (ajouter/insérer une phase, nouvelle milestone, découper une étape), consulte le gate architecture **via une référence chargée à la demande** (précédent : `product-routing.md`, `AGENT.md:33`) et s'arrête en disant pourquoi en une phrase ; il exécute sur demande explicite réitérée, override tracé au rapport — même sémantique que P59-D-08 (« un poste est une vue, pas un droit »).
- **P60-D-02 (non-régression solo).** Au poste `solo` (lu par `vf-role.sh get`, jamais relu à la main ; codes 1/5/64 jamais repliés sur `solo`, `product-routing.md:16-20`) : aucun marqueur posé, gate architecture non consulté. Une phase sans marqueur est validée — c'est l'état de toutes les phases existantes.
- **P60-D-03 (forme du marqueur).** Le planificateur choisit entre un champ gras additionnel et un tag entre parenthèses dans le titre, sous trois contraintes : (a) les lecteurs GSD rendent le même résultat avec et sans marqueur, prouvé sur fixture (`roadmap get-phase`, `roadmap analyze`, case de checklist) ; (b) **marqueur absent = validée** ; (c) la limite fail-open est écrite : le mode « Regenerate all » de `edit-phase` peut perdre un champ inconnu, la phase redevient alors validée — la doc le dit, le gate ne prétend pas le voir.
- **P60-D-04 (`check-phase-validation.sh`).** Lecture seule, forme exec, bash portable (ADR-054), workstream-aware (`--ws`), codes documentés sur le modèle de `check-prd.sh` (vert / rouge = proposée / indéterminé jamais vert à vide / illisible / usage), trois issues et mutation rouge prouvée, enregistré auprès de `check-planning-consumers-registered.sh` s'il entre dans son périmètre. Emplacement par défaut : `plugin/conductor/scripts/` — le planificateur peut en choisir un autre s'il le justifie par la résolution des deux postes consommateurs. Trailer `Gate-Touche` sur les commits qui le touchent (G-2).
- **P60-D-05 (`.planning/ARCHITECTURE.md`, décisionnel).** Fichier niveau produit, à côté de `PROJECT.md`, y compris en lab partitionné ; gabarit neuf dans `planning-core` (`references/templates/product/`) : fichiers neufs plus bump et changelog seulement. L'état de validation vit dans le fichier (statut proposé/validé, poste et date du validateur).
- **P60-D-06 (gate architecture séparé).** Un script déterministe, distinct de `check-phase-validation.sh`, même discipline : vert seulement si `ARCHITECTURE.md` existe, est marqué validé et porte ses rubriques minimales (fixées par le planificateur depuis le gabarit). Nom et emplacement au choix du planificateur, résolvable depuis le head.
- **P60-D-07 (worker `vf-product-architect`).** Source : P59-D-01, arbitrage Samuel, AskUserQuestion session principale, 2026-10-27. Worker **interne** du `product-team-bundle`, dispatché par `vf-product-manager` (allowlist `Agent(...)` étendue), ≤ 250 lignes, `check-agents.sh --strict`. Il produit `ARCHITECTURE.md` **proposée** en assemblant `software-architecture` et, quand du code existe, la carte `gsd-map-codebase` ; il ne la valide jamais lui-même. Nouvelle ligne de baseline du budget d'instructions (pas une hausse, G-1 non concerné).
- **P60-D-08 (`gsd-graphify` reste refusé).** GSDA-08 : le gate s'assemble sur `gsd-map-codebase` seul ; `gsd-graphify` n'est mentionné que comme complément si `graphify.enabled` est vrai dans le lab.
- **P60-D-09 (zéro hausse de baseline d'instructions).** Le plan n'augmente **aucune** valeur existante de `.planning/instruction-budget-baselines.tsv` : le câblage passe par les références chargées à la demande, par la marge de `vf-coder` et par le `SKILL.md` de `vf-auto`. Si le planificateur prouve que c'est impossible, il s'arrête et le rapporte (bloqueur humain), il ne cite jamais un arbitrage qui n'existe pas. `check-instruction-budget.sh` vert avant/après dans la porte.
- **P60-D-10 (aucun skill neuf).** Le geste de validation d'un dev passe par un outil existant ou un verbe de script, pas par un skill.
- **P60-D-11 (gates de jalon).** Agents neufs ≤ 250 lignes et `--strict` ; zéro nom de client ; chaque gate livré naît avec ses trois issues et sa mutation rouge.
- **P60-D-12 (manuel).** Pages FR et EN du manuel mises à jour pour l'architecture et la validation des phases (PRDT-11, `check-manual.sh`).
- **P60-D-13 (porte de phase).** Le dernier plan rejoue le job `gates` **depuis `ci.yml`** (`replay-ci-jobs.sh`) et les suites touchées, met le ledger à jour à la main, s'arrête avant PR/merge/tag/release.
- **P60-D-14 (release).** Minor racine décidée et faite par le manager après merge, hors plans ; les modules touchés reçoivent leur bump dans la phase.

Hypothèses retenues faute de réponse (à faire confirmer par Samuel ; le plan les implémente telles quelles et les rend réversibles) :

- **P60-H-01.** Le head ne consulte le gate architecture qu'au poste `product` ou `dev` **et** quand `.planning/BRIEF.md` existe.
- **P60-H-02.** Un dev (poste `dev`) valide l'architecture, comme pour les phases (A-07).
- **P60-H-03.** Toute phase ajoutée par l'équipe au poste `product` ou `dev` naît proposée ; au poste `solo`, aucune. Une phase ajoutée à la main par un humain hors de l'équipe n'a pas de marqueur : elle est validée.
- **P60-H-04.** Le gate ne lit que le marqueur, jamais le poste : une phase proposée est refusée à tout poste, `solo` compris, tant qu'elle n'est pas validée.

### Claude's Discretion

Forme exacte du marqueur (P60-D-03), noms et emplacements des scripts (P60-D-04, P60-D-06), rubriques minimales du gabarit ARCHITECTURE, répartition en vagues, bumps de modules (minor pour conductor, planning-core, product-team-bundle, dev-orchestrator s'ils reçoivent une capacité).

### Deferred Ideas (OUT OF SCOPE)

- Run réel du flux produit complet (BRIEF → PRD → architecture → refus) sur un lab désigné : geste humain, condition de `proposable:true`.
- Confirmation de P60-H-01 à P60-H-04 par Samuel.
- Hors phase (Phase Boundary) : tout hook bloquant ou contrôle d'accès (A-07), le champ `role:` des registres et la preuve à deux humains (Phase 61), la bascule `proposable:true` du bundle produit (P59-D-11), toute levée du refus de `gsd-graphify` (GSDA-08, Phase 24).
</user_constraints>

<phase_requirements>
## Phase Requirements

Famille `ARCG` réservée le 2026-10-08 et vérifiée libre le 2026-10-29 (`60-CONTEXT.md`) : **aucun ID n'est encore posé dans `REQUIREMENTS.md`**. Le planificateur les pose à l'ouverture de la planification en reformulant P60-D/H sans rien ajouter. Dérivation **proposée** (le planificateur en reste maître ; elle vaut grille de couverture) :

| ID proposé | Description (reformulation) | Source CONTEXT | Research Support |
|----|-------------|----------------|------------------|
| ARCG-01 | Marqueur de phase : champ gras `**Validation:**` dans la section de la phase, absent = validée, limite « Regenerate all » écrite | P60-D-02, D-03, H-03 | Mesure A/B/C : § Marqueur de phase |
| ARCG-02 | `check-phase-validation.sh` : lecture seule, `--ws`, codes 0/1/3/5/64, trois issues et mutation rouge, recensé, trailers `Gate-Touche` et `Ajout-Retrait` | P60-D-04, D-11, H-04 | § Modèle de gate ; § Validation Architecture |
| ARCG-03 | Refus d'une phase proposée par `vf-coder` avant `gsd-plan-phase` et `gsd-execute-phase` (bloc typé, `ask-user`) | P60-D-01 | § Points de refus ; budget mesuré neutre |
| ARCG-04 | Même contrôle porté par `vf-auto` avant sa boucle | P60-D-01 | § Points de refus |
| ARCG-05 | Le head consulte le gate architecture avant un découpage (référence à la demande, une phrase, override tracé), conditionné au poste et à `BRIEF.md` | P60-D-01, D-02, H-01 | § Points de refus ; § Pitfall 6 |
| ARCG-06 | Gabarit `ARCHITECTURE` décisionnel dans `planning-core/references/templates/product/`, statut proposé/validé dans le fichier | P60-D-05, H-02 | § Architecture Patterns |
| ARCG-07 | Gate architecture séparé et déterministe (existe, validé, rubriques) | P60-D-06 | § Modèle de gate |
| ARCG-08 | Worker interne `vf-product-architect`, allowlist du manager étendue, `--strict`, ≤ 250 lignes, une ligne de baseline neuve | P60-D-07, D-08, D-11, H-02 | § Livraison d'un agent |
| ARCG-09 | Aucune hausse de baseline d'instructions, aucun skill neuf, `gsd-graphify` non assemblé | P60-D-08, D-09, D-10 | § Budget d'instructions (mesuré) |
| ARCG-10 | Manuel FR et EN à jour, `check-manual.sh` vert | P60-D-12 | § Livraison d'un agent (empreinte) |
| ARCG-11 | Porte de phase rejouée depuis `ci.yml`, ledger à la main, bumps de modules sans release | P60-D-13, D-14 | § Précédent 59 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives actionnables extraites de `CLAUDE.md` (racine du worktree) et du contexte projet :

- **Release : toute version = un tag** ; la release racine est un geste du manager après merge (P60-D-14). Le plan n'ouvre ni PR, ni tag, ni release (`60-CONTEXT.md` P60-D-13).
- **Jamais de fix sans validation humaine** (ADR-031) : aucun worker ne valide lui-même ; le gate constate et ne corrige pas.
- **Densité (ADR-029)** : agents, avertissement dès 251 lignes, blocage au-delà de 300 ; skills ≤ 500 ; bootstrap ≤ 2000 tokens (déjà dépassé, 2610 mesuré, ligne de baseline 2610).
- **Agents natifs machine-enforced (ADR-044)** : description + model + memory requis ; un worker interne déclare `vf-internal: true`.
- **Commits en français**, cohérents avec l'historique ; un commit qui invoque une décision humaine nomme le **canal et la date** (jamais « arbitrage Samuel » nu) ; aucun arbitrage inventé.
- **Identifiants de décision préfixés** (`P60-D-xx`, `P60-H-xx`, et pour le planificateur `P60-PL-xx`).
- **Gardes G-1/G-2/G-3** : trailer `Gate-Touche: <chemin-ou-motif> — <raison>` sur tout commit qui touche un gate, sa suite, `ci.yml` ou un hook ; hausse de baseline = citation d'arbitrage (interdite ici, D-09).
- **SOBR-05** : tout ajout de gate / `SKILL.md` porte un trailer `Ajout-Retrait` à trois segments.
- Outillage local : `grep`, `ls`, `find`, `diff`, `git log` sont proxifiés par rtk (troncature silencieuse) : mesurer en `rtk proxy <cmd>` ; dans les scripts livrés, `awk` et jamais `grep | wc -l`.

## Summary

La phase tient dans les patrons déjà livrés : un gate `check-*.sh` sur le moule de `check-prd.sh` (Phase 59), un point de refus dans `vf-coder` et `vf-auto` câblé par texte chargé à la demande, un worker interne ajouté à un bundle existant. Cinq faits mesurés cadrent le plan. (1) Le marqueur en **champ gras** `**Validation:**` laisse les lecteurs GSD inchangés (sortie octet pour octet identique sur 19 commandes en lecture sur fixture et sur 8 sur une copie du vrai ROADMAP partitionné ; seul `section` de `roadmap get-phase` porte la ligne) et survit à `phase complete`, `phase insert`, `phase remove` ; le **tag en titre** `### Phase 60 (proposed):` est tolérée par le moteur mais **casse** `check-mission-exit.sh:564` (section introuvable, mesuré 0 ligne). (2) Placer les deux gates dans `plugin/conductor/scripts/` (défaut du CONTEXT) est correct et même nécessaire pour le gate architecture : `dev-orchestrator` est `roles:["dev"]`, donc invisible au poste `product` où le worker et le manager produit doivent pouvoir le lancer ; en contrepartie chaque fichier neuf entre dans la surface de G-2 (trailer `Gate-Touche`) et de SOBR-05 (trailer `Ajout-Retrait`). (3) **Zéro hausse de baseline est faisable** : un paragraphe de 6 lignes dans `vf-coder.md`, une section dans `vf-auto/SKILL.md`, un prolongement de la ligne-pointeur `AGENT.md:33` et une `§5` de `product-routing.md` laissent `check-instruction-budget.sh` à `code=0` et `test-dev-orchestrator.sh` au même ensemble de résultats que le témoin, mesuré sur copie jetable. (4) Deux décisions de conception n'ont pas de défaut dans le CONTEXT : **qui écrit le marqueur** (pose à la création, bascule à la validation) alors que les gates sont en lecture seule et qu'aucun changement de `vf-dev-manager` (46/46 instructions, 250 lignes) n'est prévu, et **comment l'architecte assemble `gsd-map-codebase`** (le skill lance quatre agents en parallèle, commite, et le plafond mémoire de la machine est à deux workers) — RESOLVED à la planification : P60-PL-05 et P60-PL-07 pour le premier, P60-PL-08 pour le second (voir Open Questions). (5) Le précédent 59 donne le découpage en quatre vagues et la liste des pièges de mise en œuvre (SANS-BASELINE, compteurs `check-version-sync`, trailers à trois segments, `bash` 3.2 et mawk, fixtures générées à l'exécution).

**Primary recommendation :** champ gras `**Validation:**` (valeurs ASCII fermées `proposed` / `validated`, absent = validée) ; `check-phase-validation.sh` et `check-architecture.sh` dans `plugin/conductor/scripts/` avec suites à mutants dans `plugin/conductor/scripts/tests/` ; câblage budget-neutre par références et `SKILL.md` ; worker `vf-product-architect` (sonnet, `skills: software-architecture`) ajouté avec l'allowlist du manager dans le même plan ; les deux questions ouvertes ont été tranchées avant l'écriture des plans (RESOLVED : P60-PL-05, P60-PL-07, P60-PL-08).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Marqueur « proposée » d'une phase | Fichier de planning du compartiment (`ROADMAP.md`) | — | Donnée, pas droit ; lue par le moteur GSD comme texte libre (champ non reconnu) |
| Constat du marqueur | Script de gate (`conductor/scripts`, lecture seule) | — | Déterministe, rouge prouvé par mutation (QUAL-01), aucun hook (A-07) |
| Refus de planifier/exécuter | Équipe (worker `vf-coder`, skill `vf-auto`) | Manager (table de pilotage existante) | Un agent n'intercepte pas un skill invoqué par l'humain (spec §11) ; le refus est du texte d'agent adossé au code de sortie du gate |
| Refus de découpage sans architecture validée | Head (`vibeflow-head`), référence à la demande | Humain (override explicite réitéré) | Advisory avec halte, ADR-031 ; même sémantique que P59-D-08 |
| Production de `ARCHITECTURE.md` (proposée) | Worker `vf-product-architect` (bundle produit) | Manager `vf-product-manager` | Pattern 12 : un worker cloisonné écrit, le manager distribue |
| Validation de `ARCHITECTURE.md` et des phases | Humain au poste `dev` | — | ADR-031 ; aucun agent ne valide (« ne la valide jamais lui-même ») |
| Constat de `ARCHITECTURE.md` validée | Script de gate (`conductor/scripts`) | — | Séparé du gate de phase (P60-D-06) ; installé à tous les postes (conductor `mandatory`) |
| Gabarit `ARCHITECTURE` | `planning-core/references/templates/product/` | — | Précédent 59 (PROJECT/REQUIREMENTS produit) |
| Résolution du compartiment | `workstream-policy.sh` (`vf_ws_dir_resolve`) ou chemin passé par l'appelant | — | Ne jamais coder un nom de compartiment (lint D-03) |

## Standard Stack

Aucun paquet externe n'est installé par cette phase. La « pile » est faite des briques internes déjà livrées.

### Core
| Brique | Version (mesurée) | Rôle | Pourquoi standard |
|--------|-------------------|------|-------------------|
| bash | 3.2.57 local, bash 5 en CI | langage des gates et suites | ADR-054 : portable macOS/Linux/Windows Git Bash [VERIFIED: `bash --version`] |
| awk | BWK 20200816 local, mawk en CI | analyse de texte des gates | précédent `check-prd.sh`, `check-planning-consumers-registered.sh` [VERIFIED: `awk --version`; CITED: `manual/.tools/check-manual.sh:24` « bash 3.2 (macOS) et bash 5 + mawk (ubuntu-latest) »] |
| `check-prd.sh` + `test-check-prd.sh` | Phase 59 | modèle de gate et de suite à mutants | codes 0/1/3/5/64, ordre 5 > 1 > 3 > 0, ligne `BILAN`, helper `mutant()` [VERIFIED: `plugin/product-team-bundle/scripts/check-prd.sh:41-50,335`] |
| `vf-role.sh get` | Phase 58 | lecteur unique du poste | codes 0/1/5/64 [VERIFIED: `plugin/conductor/scripts/vf-role.sh:11-15`] |
| `workstream-policy.sh` | planning-core | résolution de compartiment | `vf_ws_dir_resolve` rend 0 / 1 / 2 sans suivre de lien [VERIFIED: `plugin/planning-core/scripts/workstream-policy.sh:240-262`] |
| gsd-core | 1.19.0 installé = `latest` npm | moteur lu par la preuve de non-régression | [VERIFIED: `cat ~/.claude/gsd-core/VERSION` ; `npm view @opengsd/gsd-core dist-tags` → `latest: '1.19.0'`] |
| `replay-ci-jobs.sh` | Phase 40.1 | porte de phase rejouée depuis `ci.yml` | extrait les étapes du fichier, `--list` d'abord [VERIFIED: `.planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-*/tools/replay-ci-jobs.sh:1-12`] |

### Supporting
| Brique | Rôle | Quand l'utiliser |
|--------|------|------------------|
| `check-instruction-budget.sh` | budget d'instructions et de lignes | avant et après chaque plan qui touche un agent ou un `AGENT.md` |
| `check-agents.sh --strict --manifest-freshness=strict` | conformité des agents (3 appels CI) | à l'ajout de `vf-product-architect` |
| `check-ajout-retrait.sh --strict` | SOBR-05 | à l'ajout d'un `check-*.sh` |
| `check-gate-touche.sh` | G-2 | quand un fichier de la surface est touché (rc 0 attendu, plus rc 3) |
| `check-version-sync.sh` | compteurs de suites, modules, triade | après ajout de suites et à chaque bump |
| `check-manual.sh` | manuel FR+EN | dernier plan |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Champ gras `**Validation:**` | Tag `### Phase N (proposed):` dans le titre | Le moteur le tolère mais `check-mission-exit.sh:564` ne le lit pas ; deux sites à modifier (titre et case) pour valider |
| Scripts dans `conductor` | Script de phase dans `dev-orchestrator/scripts/` (hors surface G-2) | Évite `Gate-Touche`, mais `dev-orchestrator` est invisible au poste `product` ; le gate architecture doit rester dans `conductor` |
| Lecture awk directe du ROADMAP | `gsd-tools roadmap get-phase` | Dépend de node >= 24 et d'un moteur flottant `^1` (gate T28-F) ; la doctrine A-6 préfère la lecture de texte |

**Installation :** aucune (zéro dépendance nouvelle).

**Version verification :** gsd-core `1.19.0` [VERIFIED: npm registry, 2026-10-29] ; dépendance déjà établie du dépôt, pas un paquet neuf.

## Package Legitimacy Audit

Aucun paquet externe n'est installé ou recommandé par cette phase : le gate `gsd_run query package-legitimacy check` n'a pas d'objet. **Packages removed due to [SLOP] verdict:** none. **Packages flagged as suspicious [SUS]:** none. (`@opengsd/gsd-core` est la dépendance moteur du dépôt, déjà posée par `ensure-deps.sh` et par la CI ; sa version est seulement lue.)

## Architecture Patterns

### System Architecture Diagram

```
 Humain (poste product | dev | solo)
        |  intention de découpage ("ajoute une étape", "découpe", "ouvre une milestone")
        v
 vibeflow-head (session principale) --- lit le poste : "$S"/vf-role.sh get --------+
        | solo ? ──────────────────────────> routage normal (rien ne change, D-02)  |
        | product|dev ET .planning/BRIEF.md ?                                      |
        v                                                                          |
 product-routing.md §5 (référence à la demande) -> "$S"/check-architecture.sh      |
        | rc 0 : dispatch Task(vf-dev-manager) ; rc 1 : une phrase + halte ;       |
        |        autres codes : human_needed ; override = demande réitérée tracée  |
        v                                                                          |
 vf-dev-manager --(gsd-phase add)--> ROADMAP du compartiment                        |
        |   phase ajoutée à product|dev : marqueur "**Validation:** proposed"      |
        |   (QUI l'écrit ? -> Open Question O-1)                                    |
        v                                                                          |
 vf-coder (mandat d'étape N) ---- AVANT gsd-plan-phase / gsd-execute-phase ---------+
        | "$S"/check-phase-validation.sh --ws <nom> --phase N
        |   rc 0 validée -> poursuit        rc 1 proposée -> {statut: blocked, finding action: ask-user}
        |   rc 3/5/64 -> human_needed       (manager : table de pilotage inchangée)
        v
 gsd-plan-phase / gsd-execute-phase

 Chemin direct : /vf-auto (moteur gsd-autonomous) -> même contrôle par étape ciblée AVANT la boucle

 Production de l'architecture (poste product) :
 vibeflow-product -> vf-product-manager --Agent(...)--> vf-product-architect
        |  lit gabarit planning-core/references/templates/product/ARCHITECTURE.template.md
        |  skill software-architecture ; carte du code si présente (O-4)
        v  écrit .planning/ARCHITECTURE.md  **Statut :** proposée   (jamais validée par lui)
 Dev (poste dev) relit, passe le statut à validée (O-1) --> check-architecture.sh rc 0
```

### Recommended Project Structure

```
plugin/conductor/
├── scripts/check-phase-validation.sh          # gate de phase (lecture seule)           [D-04]
├── scripts/check-architecture.sh              # gate architecture (nom au choix)        [D-06]
├── scripts/tests/test-check-phase-validation.sh   # suite à mutants (surface G-2)
├── scripts/tests/test-check-architecture.sh       # suite à mutants (surface G-2)
├── references/workstream-planning-consumers.md    # +1 ligne si le script résout un compartiment
├── README.md, CHANGELOG.md, VERSION, module.json   # minor ; "Scripts (38)" -> 40
plugin/planning-core/references/templates/product/ARCHITECTURE.template.md   # fichier neuf [D-05]
plugin/dev-orchestrator/
├── agents/vf-coder.md          # + paragraphe « phase proposée » (0 instruction mesurée)
├── skills/vf-auto/SKILL.md     # + « Étape 0 bis »
├── AGENT.md                    # ligne-pointeur :33 prolongée (aucune ligne ajoutée)
├── references/product-routing.md   # + §5 (la §1 à §4 et T44 intacts)
└── references/intent-routing.md    # annotation de la ligne « ajoute une étape » (option)
plugin/product-team-bundle/
├── agents/vf-product-architect.md  # worker interne, sonnet, ≤ 250 lignes
├── agents/vf-product-manager.md    # allowlist + livrable `architecture` (24/24 conservé)
└── scripts/tests/test-product-team-bundle.sh   # AGENTS/CORPUS étendus + clauses à mutants
```

### Pattern 1 : gate sur le moule `check-prd.sh`
**What :** script `set -uo pipefail`, `LC_ALL=C`, arguments séparés (`--x v` et `--x=v`), refus AVANT lecture (lien symbolique, non régulier, illisible, taille non numérique, au-delà de 1 048 576 octets), analyse awk pure (jamais d'évaluation), contenu des entrées **jamais réimprimé**, ligne `BILAN … code=<rc>`, codes énumérés, ordre 5 > 1 > 3 > 0, code 2 jamais émis [VERIFIED: `check-prd.sh:41-50`].
**When :** les deux gates de la phase.
**Example (extrait vérifié de l'en-tête) :**
```
#   0 = conforme ...   1 = éliminatoire ...   3 = INDÉTERMINÉ ... Jamais un vert à vide.
#   5 = entrée illisible, BRUYANTE ...   64 = erreur d'usage ...
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
```
Transposition recommandée (discrétion du planificateur sur les libellés) : `check-phase-validation.sh` — 0 = phase validée (marqueur `validated` ou absent) ; 1 = proposée ; 3 = phase introuvable dans le ROADMAP, ROADMAP absent, ou valeur de marqueur inconnue ; 5 = entrée illisible ; 64 = usage. Une phase **absente du ROADMAP ne vaut jamais 0** (anti-vert-à-vide).

### Pattern 2 : suite à mutants (QUAL-01)
**What :** fixtures écrites à l'exécution sous `mktemp -d` (CRLF et BOM produits par `printf`), helper `run()` borné par `perl -e 'alarm 10; exec @ARGV'`, `case_ <id> <sonde>`, puis `mutant <id> <repère> <ancien> <nouveau> <sonde> <desc>` : une ligne du script est altérée, la copie doit différer (`cmp -s`), rester valide (`bash -n`), rougir pour la raison attendue (code attendu/obtenu imprimé), l'original est revérifié vert [VERIFIED: `test-check-prd.sh:14-15,376`]. Cas de couverture des codes : `CPRD-CODES` compare l'ensemble observé à `{0,1,3,5,64}`.
**When :** les deux suites neuves. Un mutant « identique à l'original » est NON OPPOSABLE et rougit la suite.

### Pattern 3 : câblage à la demande, budget-neutre
**What :** la doctrine vit dans une référence non budgétée (`references/*.md`) ; l'agent ne porte qu'un pointeur ou un paragraphe formulé **sans marqueur** (voir Pitfall 1). Précédent : `AGENT.md:33` + `product-routing.md` [VERIFIED: `AGENT.md:33`].

### Anti-Patterns to Avoid
- **Marqueur dans le titre** : casse `check-mission-exit.sh:564` (mesuré).
- **Gate qui lit le poste** : H-04, le gate ne lit que le marqueur ; le poste ne décide que de la pose.
- **Gate qui réimprime le contenu du ROADMAP ou de `ARCHITECTURE.md`** : la sortie entre dans le contexte de l'agent (injection) ; imprimer numéro de phase validé, noms de rubrique fixes, codes.
- **Gate qui corrige** : lecture seule sans exception (aucun fichier créé ni modifié).
- **Recopier une liste de gates dans le plan de porte** : rejouer le job depuis `ci.yml`.
- **Nom de compartiment en dur** (`fiabilite`) dans un script ou dans `ci.yml` : le lint le rougit.

## Marqueur de phase (axe 1 : mesures)

### Méthode
Fixtures `/tmp/p60fx/{A,B,C}` (trois phases, jalon `## Milestone v1.0`) et copie partitionnée du **vrai** ROADMAP `/tmp/p60real/{A,B,C}/.planning/workstreams/fiabilite/` : A = témoin sans marqueur ; B = ligne `**Validation:** proposed` insérée sous `**Goal:**` ; C = `### Phase N (proposed):` et `- [ ] Phase N (proposed): …` (titre et case). Moteur : `node ~/.claude/gsd-core/bin/gsd-tools.cjs <commande> --cwd <fixture> [--ws fiabilite]` (gsd-core 1.19.0). Comparaison `cmp -s` de la sortie, chemins normalisés. (`diff` local est proxifié par rtk et rend un faux « identique » : [VERIFIED] ; `rtk proxy cmp`/`rtk proxy diff` seuls font foi.)

### Résultats

| Commande (sur A, B, C) | B = A ? | C = A ? | Note |
|---|---|---|---|
| `roadmap analyze` | identique | identique | `phase_count`, `name`, `goal`, `depends_on` inchangés |
| `roadmap validate` | identique | identique | `warnings: []` |
| `find-phase 2` | identique | identique | |
| `init plan-phase 2`, `init execute-phase 2`, `init phase-op 3` | identique | identique | `phase_name` propre |
| `progress`, `progress json`, `state-snapshot`, `phases list`, `phase-plan-index 2`, `init progress`, `roadmap annotate-dependencies 2`, `roadmap milestone-scope`, `validate health`, `milestone list` | identique | identique | |
| `roadmap get-phase 2` (JSON) | seul `section` diffère (porte la ligne) | seul `section` diffère (porte le titre étiqueté) | `phase_name`, `goal`, `mode` identiques |
| `roadmap get-phase 60` sur copie du vrai ROADMAP, `--ws fiabilite` | idem : `phase_name` = « Gate architecture avant découpage et validation des phases proposées » | idem | 8 commandes comparées, 1 seule diffère (`section`) |
| `phase complete 2` (avec PLAN, SUMMARY, VERIFICATION passed) | ligne `**Validation:** proposed` conservée, `[x] … (completed 2026-10-29)` | `- [x] Phase 2 (proposed): … (completed 2026-10-29)` | la case se coche dans les deux formes |
| `phase insert 1`, `phase remove 1` (renumérotation 2 -> 1) | le champ suit sa section | le tag suit titre et case | aucun des deux n'est perdu |

**Témoins négatifs (la comparaison sait rougir)** : `### Phase 2 [proposed]:` (crochets) -> `roadmap get-phase 2` rend `{"found": false}` ; `### Phase 2: Titre (proposed)` (tag après les deux-points) -> `phase_name` devient « Deuxième phase (proposed) » dans `get-phase` et `analyze`.

**Lecteur du dépôt** : `check-mission-exit.sh:564` `$0 ~ ("^### Phase " step ":") { inside=1; next }` [VERIFIED: `plugin/dev-orchestrator/scripts/check-mission-exit.sh:563-567`], extrait rejoué sur les trois fixtures pour l'étape 2 : **A 6 lignes, B 7 lignes, C 0 ligne** -> en forme C le gate E4 dirait « section introuvable pour l'étape » (message `check-mission-exit.sh:569`). `check-divergence.sh:88` (`ROADMAP_HEADER_RE='^### Phase ([0-9]+(\.[0-9]+)?)'`) et `check-method-budget.sh:297` (`/^### Phase [0-9]+(\.[0-9]+)?/`) sont par préfixe : tolérants aux deux formes.

### Pourquoi le moteur tolère la forme C mais pas toujours le dépôt
`OPTIONAL_PHASE_TAG_SOURCE = '(?:\\s*\\([^)\\n]{0,200}\\))?'` [VERIFIED: `~/.claude/gsd-core/bin/lib/phase-id.cjs:50`], réutilisé par `buildPhaseHeadingRegex` [VERIFIED: `roadmap.cjs:140-142`]. Le champ non reconnu est ignoré par `extractPhaseFieldMultiline` (qui s'arrête à toute autre ligne `**Label**`) [VERIFIED: `roadmap-parser.cjs:2234-2275`] ; précédent explicite du champ conservé tel quel : « Mode: … unrecognized values are preserved verbatim for forward-compat » [VERIFIED: `roadmap.cjs:181-184`]. Le ROADMAP de ce dépôt porte déjà des champs gras propres (`**Sources:**`, `**Hors périmètre :**`) que le moteur laisse passer [VERIFIED: sortie de `roadmap get-phase 60 --ws fiabilite`].

### Limite fail-open (P60-D-03 c)
`edit-phase` est un workflow interprété par un LLM : « Edit specific fields » conserve le reste ; **« Regenerate all fields » reconstruit « the entire section from the new field values »** [CITED: `~/.claude/gsd-core/workflows/edit-phase.md:171-185, 209-218`] : un champ inconnu peut être perdu, la phase redevient alors validée. Les deux formes y sont exposées ; à écrire dans la doc et dans l'en-tête du script, sans prétendre le voir. Le moteur n'offre aucun drapeau pour poser un champ à `phase add` [VERIFIED: `phase-command-router.cjs` : seuls `--raw`, `--id`, `--descriptions`, `--sibling`, `--force`, `--dry-run`] : la pose est une édition de texte après coup (O-1).

### Recommandation
**Champ gras `**Validation:**`**, ligne sous `**Goal:**`, valeurs ASCII fermées (`proposed`, `validated`), absent = validée, valeur inconnue = 3 (jamais verte). Raisons mesurées : lecteurs GSD inchangés ; `check-mission-exit.sh` intact ; une validation = une ligne à changer (la forme C exige de modifier titre **et** case, deux sites). Éviter `**Status:**` : libellé déjà employé par les lecteurs d'état et d'UAT du moteur [VERIFIED: `grep` sur `state.cjs`, `uat.cjs`, `state-document.cjs`]. Le libellé `**Validation:**` n'est lu par aucun module du moteur [VERIFIED: grep négatif `\*\*Validation` sur `bin/lib/*.cjs` et `workflows/*.md`, sortie vide].

**Prototype de lecture mesuré (non livré)** — section de phase, fences et BOM ignorés, tag de titre toléré :
```awk
# /tmp/p60-poc.sh (extrait) : états rendus sur A,B,C et sur la copie du vrai ROADMAP
if (match(h, /^Phase [0-9]+(\.[0-9]+)?([ \t]*\([^)]*\))?[ \t]*:/)) { ... num == n -> inphase }
if (inphase && match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)) { v = tolower(trim(substr(line, RSTART+RLENGTH))) }
# sortie observée : A p2 sans_marqueur | B p2 proposed | B p3 sans_marqueur | B p9 absent_phase
#                  copie réelle B p60 proposed | A p60 sans_marqueur | valeur "validated (dev, 2026-10-29)" validated | valeur "propose" inconnu
```
Le tag exige ici une regex `^Phase N … :` avec le deux-points : le vrai ROADMAP contient `## Phase 41 — chaîne de mesures…` (tiret cadratin, sans deux-points) en plus de `### Phase 41:` [VERIFIED: `awk` sur `ROADMAP.md` : « Phase 41 2 »] ; sans le deux-points, la phase 41 serait comptée deux fois.

## Modèle de gate (axe 2)

- **Découverte CI** : le job `tests` lance toute suite `find plugin scripts -type f -path '*/tests/test-*.sh'` après assertion de découverte non vide [VERIFIED: `.github/workflows/ci.yml:215-242`] ; 113 suites mesurées aujourd'hui [VERIFIED: `find … | awk 'END{print NR}'` -> 113]. Une suite neuve **entre donc en CI sans toucher `ci.yml`** (comme `test-check-prd.sh`). `check-prd.sh` n'a aucune étape propre dans le job `gates` (seule sa suite le joue) : même régime pour les deux gates neufs, sauf décision contraire du planificateur (une étape `gates` toucherait la classe 4 de G-2).
- **Job `gates`** : 20 étapes rejouables, 3 sautées (une action, deux conditionnelles `main`) [VERIFIED: `replay-ci-jobs.sh --job gates --list`, sortie lue ; liste dans `59-08-SUMMARY.md`]. Étapes pertinentes pour la phase : `check-agents` (3 appels), `check-skills`, `check-version-sync`, `check-instruction-budget`, `check-planning-consumers-registered`, `check-baseline-arbitrage` (G-1), `check-gate-touche` (G-2), `check-ajout-retrait` (SOBR-05, consultatif), `check-manual`.
- **Compteur de suites** : `check-version-sync.sh` exige que « N suites » des deux README racine égale `find …/tests/test-*.sh` [VERIFIED: `scripts/check-version-sync.sh` bloc 9] ; 113 aujourd'hui, +1 par suite neuve : **recompter à la fin**, ne jamais figer le nombre dans un plan (leçon 59).
- **Surface G-2** (six classes) : `plugin/conductor/scripts/check-*.sh` (un niveau), `plugin/conductor/scripts/tests/test-*.sh`, `ci.yml`, `scripts/hooks/**`, fixtures [VERIFIED: `scripts/check-gate-touche.sh:24-35`]. Les deux scripts et leurs suites **dans conductor entrent dans la surface** -> `Gate-Touche: <chemin> — <raison ≥ 10 caractères>` (un trailer = un chemin, jamais de virgule) ; `check-gate-touche.sh` doit alors rendre rc 0 (et non rc 3) ; à l'inverse un script hors conductor (ex. `dev-orchestrator/scripts/`) est « HORS SURFACE par l'arbitrage du 2026-09-17 » [VERIFIED: même en-tête].
- **SOBR-05** : chaque `plugin/<module>/scripts/{check,guard}-*.sh` ajouté exige `Ajout-Retrait: <chemin> — <retrait | aucun : justification ≥ 10 caractères> — défaillance : <≥ 10 caractères + date ISO ou SHA>` (trois segments, sinon `MARQUEUR-MAL-FORME`) [VERIFIED: `check-ajout-retrait.sh:20-45` ; précédent réel `96a64378`]. Consultatif en CI (rc 0), `--strict` en suite.
- **Lint des consommateurs** : `check-planning-consumers-registered.sh` balaie les `*.sh` suivis hors segment `tests`, et ne retient qu'une **ligne** portant `.planning/workstreams`, ou `.planning/` suivi de `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md` ; les lignes de commentaire comptent [VERIFIED: `check-planning-consumers-registered.sh:22-28,158-171`]. `check-prd.sh` y échappe parce qu'il reçoit ses chemins en arguments (P59-PL-04). `check-phase-validation.sh` résout, lui, un compartiment : soit il reçoit `--roadmap <fichier>` (aucun littéral), soit il résout par `--ws` et se recense (catégorie a2, « exempté — résout le compartiment NOMMÉ », 1 ligne dans `plugin/conductor/references/workstream-planning-consumers.md`, qui est un sur-ensemble tolérant [VERIFIED: sa section « Ce recensement est un SUR-ENSEMBLE »]). Éviter de citer un chemin de ROADMAP en commentaire, ou le recenser. `.planning/ARCHITECTURE.md` et `BRIEF.md` ne déclenchent pas le lint.
- **Codes et convention** : 64 réservé à l'usage, 2 jamais émis par `check-prd.sh` ; les précédents `check-divergence.sh` et `check-planning-consumers-registered.sh` emploient 2 pour NON VÉRIFIABLE (exception documentée par `check-instruction-budget.sh` en-tête) : suivre `check-prd.sh` pour la famille produit (0/1/3/5/64).
- **QUAL-01** : « Tout nouveau gate du milestone naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée » [VERIFIED: `REQUIREMENTS.md:1305`].
- **ADR-071 « forme exec »** : vise les hooks ; P59-PL-05 la transpose en « appel en arguments séparés, code de sortie non masqué, sans `|| true` ni tube, sans hook » [VERIFIED: `59-PLANNING-REGISTRE.md`, ligne P59-PL-05, qui la marque hypothèse A1, réversible]. Même lecture ici.

## Résolution des scripts depuis les postes consommateurs (axe 3)

- **Cascade `$S`** : « premier existant » parmi `./.claude/scripts`, `$HOME/.claude/scripts`, `${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts`, `${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts`, testée sur `[ -f "$d/dag.sh" ]` ; « le lab courant PRIME » [VERIFIED: `plugin/dev-orchestrator/references/mission-flow.md:10-30`]. `vf-coder.md:85-86` cite déjà « `$S` résolu comme en `mission-flow.md` §Résolution » ; `product-routing.md:12-13` fait de même pour `vf-role.sh`. Les scripts de tous les modules sont copiés **à plat** dans `.claude/scripts/` (`copy_module_scripts`, y compris `tests/`) [VERIFIED: `plugin/_internal/vibeflow-update.sh:2254-2320`] : un script neuf de `conductor/scripts/` est résolu par la même cascade, sans autre câblage.
- **Visibilité par poste** (clé `roles` de `module.json`) : `conductor` est `mandatory` (jamais masqué) ; `dev-orchestrator` `roles:["dev"]` ; `product-team-bundle` `roles:["product"]` ; `solo` voit tout, `dev` ne voit pas le bundle produit [VERIFIED: `module.json` des trois modules ; `plugin/_internal/module-roles.sh:7-17`]. Conséquence : le **gate architecture** est consommé au poste `product` (worker, manager) **et** au poste `dev` (head) -> seul `conductor` (ou `planning-core`, sans `roles`) est visible aux deux. Le **gate de phase** n'est consommé que par des fichiers de `dev-orchestrator` (`vf-coder`, `vf-auto`, head) : `dev-orchestrator/scripts/` serait résolvable aussi, au prix de la symétrie ; le défaut du CONTEXT (`conductor`) reste le bon par défaut (une seule maison, une seule `Gate-Touche`, suites voisines).
- **Dépendances** : `product-team-bundle` `requires` déjà `conductor`, `planning-core`, `consolidator`, `audit-architecture`, `software-architecture` [VERIFIED: `module.json`]. `conductor` `requires` `planning-core` : le gabarit `ARCHITECTURE` y est donc toujours présent là où le script `conductor` tourne. Le script ne doit pas lire le gabarit à l'exécution : il embarque les noms de rubrique (comme `check-prd.sh` pour le BRIEF).
- **Compartiment** : en lab partitionné, le BRIEF (et, par P60-D-05, `ARCHITECTURE.md`) est à la **racine** `.planning/`, PROJECT/REQUIREMENTS/ROADMAP dans le compartiment nommé par `--ws` (`vf-product-manager.md` §Résolution des chemins : « BRIEF : toujours `.planning/BRIEF.md` à la racine du lab, y compris en lab partitionné »). Précédent de `--ws` explicite : DLWS-04 « le compartiment vient d'un `--ws` explicite, jamais de `GSD_WORKSTREAM` ni du pointeur actif » [VERIFIED: `REQUIREMENTS.md`, DLWS-04]. Lab partitionné sans `--ws` : décision de conception du script (3 ou 64) à trancher et à couvrir par mutant.

## Points de refus (axe 5)

- **`vf-coder.md:42` et `:45`** : `1. **Plan** : invoque le skill gsd-plan-phase …` et `2. **Exécution** : invoque le skill gsd-execute-phase.` [VERIFIED: `plugin/dev-orchestrator/agents/vf-coder.md:42,45`]. Insertion proposée **avant** `## Le cycle (délégation)` (donc avant 1 et 2) ; texte mesuré à **0 instruction** (voir § Budget). L'entrée de `vf-coder` est « une étape (numéro + objectif + critères) » ou « la spec du crafter » (étage implémentation design) ou une tâche courte `gsd-quick` : le contrôle ne vaut que si le mandat nomme une étape ROADMAP `N`.
- **`vf-auto/SKILL.md`** : le moteur direct est le skill `gsd-autonomous` (l. 56-57), après `N = étapes restantes ciblées (gsd-tools roadmap analyze …)` (l. 38) [VERIFIED: `SKILL.md:38,54-57`]. Une section « Étape 0 bis » avant « Moteur direct » contrôle chaque étape ciblée. **Limite à écrire** : une phase ajoutée *pendant* la boucle du moteur n'est pas interceptée (advisory).
- **`AGENT.md:33`** : ligne-pointeur « **Poste product** — la ligne « Poste : X » … décide de la porte … lire d'abord `…/product-routing.md`, qui prime sur la proposition d'init ci-dessous. » [VERIFIED: `AGENT.md:33`], dans `## Garde-fou premier usage (first-use)` (l. 31) ; `T44 (a)` impose le pointeur dans cette zone, avant `FIRST-02` [VERIFIED: `test-dev-orchestrator.sh:7322-7323,7356-7358`]. Prolonger **cette ligne** (aucune ligne ajoutée) : variante mesurée « … Devant une intention de découpage (ajouter, insérer ou découper une étape, ouvrir une milestone), lire aussi sa §5 : gate architecture, phases proposées. ».
- **`product-routing.md`** : §1 lire le poste, §2 poste product, §3 postes solo et dev, §4 ce que la page ne fait pas [VERIFIED: lecture, 61 lignes] ; `T44` pince §1/§2/§3 par les bornes `^## 1[.]` à `^## 4[.]` ; **une `## 5.` ajoutée à la fin ne touche aucune zone pincée** (mesuré). `product-routing.md:60-61` dit « Elle ne décide pas du découpage d'une mission, qui reste celui de la règle d'échelle de `head-governance.md` §1 » : la §5 ajoute un *préalable* au découpage, pas une règle d'échelle ; reformuler la phrase si la page doit rester cohérente.
- **`intent-routing.md`** : ligne 102 « ajoute une étape / supprime ce sprint / réordonne la feuille de route | `gsd-phase` » [VERIFIED: `intent-routing.md:102`]. Les rangées du head concernées par « découpage » dans `AGENT.md` : « planifie / découpe / cadre / prépare le sprint | `Task(vf-dev-manager)` » [VERIFIED: `AGENT.md`, Carte d'intention]. La table de pilotage du manager traite déjà `human_needed` **« ou par tout finding `action: ask-user` »** et `blocked` -> « laisser le nœud `blocked`, traiter la dépendance » [VERIFIED: `mission-flow.md:294-312`] : la combinaison `blocked` + finding `ask-user` de P60-D-01 est donc couverte par la clause « tout finding ask-user » (escalade départagée par le mode ; en autonome, gel du nœud) ; voir O-6 pour l'ambiguïté d'ordre.
- **Trou résiduel à écrire** : `gsd-discuss-phase` (cadrage) et `gsd-quick` ne sont pas gardés ; le refus ne concerne que plan et exécution (P60-D-01).

## Budget d'instructions (axe 4 : mesuré avant, calculé, prouvé sur copie)

### Avant (exécuté dans le worktree)
`bash plugin/conductor/scripts/check-instruction-budget.sh` -> **rc 0**, 36 fichiers, `BILAN : … 0 depassement(s), 0 avertissement(s) ADR-029, 0 non verifiable(s), arme=oui, code=0` ; skills : 23 `SKILL.md`, 0 dépassement ; `BOOTSTRAP : 2610 tokens … ligne 2610, verdict AU-DESSUS-PLAFOND-ADR029` (préexistant, non bloquant).

| Fichier | Lignes | Plafonds | Instr. mesurées | Baseline instr. | Marge instr. |
|---|---|---|---|---|---|
| `dev-orchestrator/AGENT.md` | 216 | avertit à 251, bloque à 300 | 33 | 33 (`@209` lignes) | **0** ; 35 lignes avant l'avertissement |
| `dev-orchestrator/agents/vf-dev-manager.md` | **250** | idem | 46 | 46 | **0** ; **+1 ligne = AVERTISSEMENT** (non bloquant, rc 0) |
| `dev-orchestrator/agents/vf-coder.md` | 146 | idem | **22** | 23 | **1** ; 105 lignes avant l'avertissement |
| `dev-orchestrator/skills/vf-auto/SKILL.md` | 79 | 500 (aucun ratchet) | — | — | 421 lignes ; la `description:` seule pèse au `BOOTSTRAP` |
| `product-team-bundle/agents/vf-product-manager.md` | 152 | idem | 24 | 24 | **0** |
| `product-team-bundle/AGENT.md` | 164 | idem | 36 | 36 | **0** |

Sources : table du script [VERIFIED: sortie exécutée] ; `.planning/instruction-budget-baselines.tsv` (`plugin/dev-orchestrator/AGENT.md 209 33`, `…/vf-coder.md 122 23`, `…/vf-dev-manager.md 250 46`, `plugin/product-team-bundle/agents/vf-product-manager.md 152 24`) [VERIFIED: lecture]. La colonne lignes de la baseline n'est jamais comparée [VERIFIED: en-tête de la baseline].

### Définition exacte d'une « instruction » (c'est le piège)
`MARKER_RE='jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire'` [VERIFIED: `check-instruction-budget.sh:133`] appliquée, en minuscules, à **toute ligne de corps** hors bloc fenced et hors titre ; plus toute puce `- `/`* `/`N. `/`❌` située sous un titre dont le libellé contient `règles|garde-fous|iron law|anti-pattern|lignes rouges|discipline` [VERIFIED: `:135` et `count_instructions`, l. 305-350]. `ne .* pas` est **une sous-chaîne** : « une phase … passe » matche (« ne » dans « une », « pas » dans « passe »). Mesurer chaque phrase ajoutée, jamais l'estimer.

### Faisabilité : OUI, zéro hausse, prouvée sur copie jetable
Méthode : copie de `plugin/` et de la baseline sous `/tmp/p60bud`, script réel lancé avec `--path`, témoin = copie non modifiée `/tmp/p60bud0` (`COPY-EQUALS-REAL` : sortie identique au dépôt réel). Éditions appliquées à la copie :

| Édition | Effet mesuré |
|---|---|
| `vf-coder.md` : section « Porte « phase proposée » (avant 1 et 2) » de 6 lignes (146 -> 152) | instr. **22 -> 22**, verdict `MARGE+LIGNES-EN-HAUSSE` |
| `AGENT.md:33` prolongée (pas de ligne ajoutée) | instr. **33 -> 33**, `OK+LIGNES-EN-HAUSSE` |
| `vf-auto/SKILL.md` : « Étape 0 bis » de 4 lignes (79 -> 85) | `BILAN-SKILLS : 23 SKILL.md, 0 depassement(s) du plafond 500` |
| `product-routing.md` : `## 5.` ajoutée | hors corpus budgété |
| `vf-product-manager.md` : allowlist + `architecture` + ligne de tableau + clause DAG | 1ʳᵉ rédaction **25** (la clause « jamais par toi » matche) -> reformulée « à son poste » -> **24/24** |

Résultat global sur la copie modifiée : `BILAN : 36 fichier(s), 0 depassement(s), 0 avertissement(s) ADR-029, 0 non verifiable(s), arme=oui, code=0` ; `BOOTSTRAP : 2610 … ligne 2610` inchangé ; `check-skills.sh --strict` -> `✓ skills conformes · 27 SKILL.md · 32 warning(s)` (les 32 préexistent) ; `test-dev-orchestrator.sh` sur la copie modifiée = ensemble de résultats **identique au témoin** (304 OK / 2 KO / 1 SKIP des deux côtés, les 2 KO étant un artefact de disposition de la copie, `T14d`, absents du dépôt réel : **308 OK / 0 KO / 0 SKIP**). Aucune hausse de baseline n'est donc requise pour les trois sites de refus du CONTEXT. `vf-dev-manager.md` n'est pas touché (250 lignes, 46/46) : toute édition y doit être à nombre de lignes constant (O-1).

### Nouveau fichier
`vf-product-architect.md` reçoit une **ligne de baseline neuve** (autorisée par P60-D-07) : sans elle `check-instruction-budget.sh` rend rc 2 `SANS-BASELINE` ; G-1 ne juge pas une ligne absente à la base [CITED: `59-RESEARCH.md`, Pitfall 1]. Valeurs lues dans la sortie du script (colonnes `LIGNES`, `INSTR`), jamais calculées à la main, fichier trié `LC_ALL=C`. Le fichier `.tsv` est sous revue code owner `@picmakpro` une fois les rulesets posés [CITED: mémoire projet « Pas d'accès admin » ; `CLAUDE.md`].

**Bloqueur ?** Non. Si une édition imprévue pousse un des fichiers à +1 instruction, la voie du CONTEXT est de s'arrêter (bloqueur humain) ; cette recherche ne l'a pas rencontrée.

## Livraison d'un agent et empreinte (axe 6)

**Frontmatter de référence** (`vf-product-pm`) : `tools: Read, Write, Edit, Glob, Grep` ; `model: sonnet` ; `effort: medium` ; `memory: project` ; `vf-internal: true` ; description « Worker interne — … dispatché uniquement par vf-product-manager, pas en usage direct » [VERIFIED: `agents/vf-product-pm.md:1-9`].

**Invariants du moteur `check-agents.sh`** : I1 `vf-internal: true` <=> « Worker interne » (sensible à la casse) dans `description:` ; I2 un worker interne doit être dispatché par une allowlist `Agent(...)` de l'univers connu (monde fermé, `--resolve-agents=strict`) ; I6 un manager (allowlist non vide, non interne) doit porter `SendMessage` [VERIFIED: `check-agents.sh:118-150,787-802,901-912,988-995`]. -> l'agent et l'allowlist du manager **s'ajoutent dans le même plan, le même commit** (leçon P59-PL-14). Le frontmatter doit rester un scalaire guillemeté mono-ligne sans `"` interne (`check-description-fidelity`). Câbler `skills: - software-architecture` supprime l'avertissement « aucun skill câblé » et réalise littéralement « assemble `software-architecture` » ; budget de préchargement 1200 lignes (`VF_PRELOAD_MAX`), le skill pèse 93 lignes [VERIFIED: `check-agents.sh:1094-1127` ; `wc` du `SKILL.md` via le tableau du budget]. Manifeste daté `check-agents-manifest.json` : `verifie_le 2026-10-22`, `valide_jours 30` -> **échéance 2026-11-21** [VERIFIED: manifeste]; sans effet tant que la CI passe avant.

**Empreinte d'un agent neuf dans le bundle** (fichiers qui nomment `vf-product-pm`, donc à auditer pour `vf-product-architect`) : `plugin/product-team-bundle/{AGENT.md, README.md, CHANGELOG.md, module.json, VERSION, agents/vf-product-manager.md, scripts/tests/test-product-team-bundle.sh}`, `plugin/planning-core/references/templates/product/*.template.md`, `CHANGELOG.md` racine, manuel FR et EN [VERIFIED: `grep -rIl vf-product-pm`]. `test-product-team-bundle.sh` fige `AGENTS="vf-product-manager vf-product-analyst vf-product-pm prd-gate"` et `CORPUS="AGENT.md agents/vf-product-manager.md …"` [VERIFIED: `test-product-team-bundle.sh:39-40`] : étendre les deux, plus les clauses à mutants (une ancre par clause).

**Manuel (PRDT-11, P60-D-12)** : comptes à jour dans les pages précédentes (aujourd'hui « 36 agents », « douze » opus, « vingt-quatre » sonnet) : FR `05-equipe-agents/les-agents-livres.md:13`, `02-concepts/agents-skills-commandes.md:14,69`, `06-reference/{agents.md:40,97-106, couts-et-modeles.md:14,18,23,35}` ; EN `05-agent-team/the-agents-that-ship.md:13`, `02-concepts/agents-skills-and-commands.md:14,67`, `06-reference/{agents.md:37,92-101, cost-and-models.md:14,18,22,34}` [VERIFIED: `grep` des nombres, sortie lue]. Ajouter un agent sonnet -> **37 agents, 25 sonnet** (à recompter par la commande de `agents.md`, pas à la main). `check-manual.sh` : sept contrôles (C0 non vide … C6 format de page ≤ 300 lignes, ≤ 3 H2), aucune version en dur (C5) [VERIFIED: `manual/.tools/check-manual.sh:1-26`]. Page « Ton poste » : `fr/01-demarrer/installation.md:105`, `en/01-get-started/installation.md:103`.

**Versions** (minor, à décider par le planificateur) : conductor `v1.50.2`, planning-core `v2.9.0`, dev-orchestrator `v2.29.0`, product-team-bundle `v1.0.0` [VERIFIED: `module.json`]. Un bump touche `module.json` `version`, `VERSION`, `CHANGELOG.md`, et `README.md` si l'en-tête `**Version**` existe (`check-version-sync` points 6 et 8). `plugin/conductor/README.md` porte « ## Scripts (38) » : 38 `*.sh` à `maxdepth 1` mesurés -> **40** après les deux gates [VERIFIED: `find … | awk 'END{print NR}'`]. Les versions racine (`VERSION`, `plugin.json`, `marketplace.json`, badges, historique des README) ne bougent pas : release du manager (P60-D-14).

## Précédent 59 (axe 7)

- **Découpage** : 8 plans en 4 vagues (W1 : gabarits planning-core, `check-prd.sh` + suite, redirection du head ; W2 : module + manager + workers + juge, front door ; W3 : suite de composition, baselines, compteurs README, manuel ; W4 : porte de phase) [VERIFIED: `ROADMAP.md` lignes 615-640 ; `59-VALIDATION.md`]. Transposition raisonnable pour 60 (suggestion, non contraignante) : W1 = marqueur + gate de phase + suite / gabarit ARCHITECTURE + gate architecture + suite ; W2 = câblage dev-orchestrator (vf-coder, vf-auto, pointeur, §5, test T45 à mutants) / worker + manager + suite du bundle ; W3 = manuel FR+EN, compteurs, baselines, bumps ; W4 = porte.
- **Registre du planificateur** `P59-PL-01..22` (conséquences, aucun choix neuf) : un seul propriétaire du fichier de baselines (P59-PL-15), compteurs de README racine dans un seul plan (P59-PL-13), états rouges intermédiaires nommés (SANS-BASELINE, compteurs `check-version-sync`) [VERIFIED: `59-PLANNING-REGISTRE.md`].
- **Porte** (`59-08-SUMMARY.md`) : `replay-ci-jobs.sh --job gates` (`--list` d'abord) -> « 20 rejouee(s), 3 sautee(s), 0 en echec » ; suites touchées **une à une** sous alarme 600 s ; liste blanche du diff ; `check-gate-touche` ; ledger (STATE, ROADMAP, REQUIREMENTS) mis à jour **à la main** ; arrêt avant PR, merge, tag, release. Déviations vécues : cases de ROADMAP restées décochées, compte d'agents du manuel périmé, ligne `## Progress` manquante.
- **Pièges de plateforme vécus** : le runner GitHub lance les étapes avec SIGPIPE ignoré et un plafond d'horloge de 60 s a sauté sous 52 matrices parallèles (suites `-ws` vertes macOS, rouges CI) ; une sonde se valide sur le commit d'avant le correctif (témoin rouge) ; chaque PR a deux runs et les suites durent 35-45 min [CITED: mémoires projet `phase-57-release-v2700`, `phase-58-et-hotfix-en-attente`]. **Plafond de 2 workers simultanés** sur cette machine (7 agents morts ensemble le 2026-10-22) [CITED: mémoire `parallelisme-agents-plafond-memoire`].
- **Trailers observés** : `Ajout-Retrait: plugin/product-team-bundle/scripts/check-prd.sh — aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) — défaillance : sans contrôle déterministe, l'éliminatoire du juge produit serait un vert auto-déclaré (motif de P59-D-06, arbitrage du 2026-10-27)` [VERIFIED: `git log` commit `96a64378`] ; `Gate-Touche: <chemin> — <raison>` [VERIFIED: commit `395dc4ed` et suivants]. Pour 60, `check-gate-touche.sh` doit rendre rc 0 (59 : rc 3 faute de fichier dans la surface).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser | Pourquoi |
|----------|-------------------|----------|----------|
| Lire le poste | un `cat .claude/vibeflow-role` | `"$S"/vf-role.sh get` | borne 64 octets, BOM, CRLF, lien refusé, codes 1/5/64 jamais repliés sur `solo` |
| Résoudre un compartiment | une concaténation `workstreams/$X` | `vf_ws_dir_resolve` / `vf_ws_name_valid` de `workstream-policy.sh` | refuse liens symboliques, valide l'alphabet du nom ; bornes de lecture 4096 octets, piège E2BIG sur Linux |
| Parser des blocs de code et commentaires HTML | un `grep` sur le ROADMAP | la bibliothèque awk de `check-prd.sh` (`strip_comments`, fences, BOM) | blocs non fermés = INDÉTERMINÉ, déjà éprouvé par 26 mutants |
| Prouver qu'un gate sait rougir | un seul cas rouge | helper `mutant()` de `test-check-prd.sh` + `cmp -s` + `bash -n` + original revérifié | « un vert à vide » est le mode de défaut dominant du dépôt |
| Rejouer la CI | une liste recopiée de commandes | `replay-ci-jobs.sh --job gates` | « liste de gates ≠ référence » (check-machine-paths oublié, PR #62) |
| Compter des instructions | une estimation | `check-instruction-budget.sh` (ou `/tmp/p60-countlines.sh` reprenant sa fonction) | la regex `ne .* pas` surprend |
| Cocher une case de phase / renuméroter | une édition de texte du ROADMAP | `gsd-tools phase complete / insert / remove` | le moteur gère case, date, dossiers, `Plans:` |

**Key insight :** tout ce que la phase construit est de la *composition* de gates, de références et d'un worker ; le seul code neuf est l'extraction d'un champ de section et d'un statut de fichier, en awk, sur le moule existant.

## Common Pitfalls

### Pitfall 1 : une phrase de refus « coûte » une instruction
**What goes wrong :** « ne lance aucune brique », « jamais par toi », « ne tranche pas » comptent chacune une instruction ; `vf-coder` n'a qu'une marge de 1, les autres fichiers 0.
**Why :** `MARKER_RE` est une sous-chaîne sur toute la ligne, hors titres (§ Budget).
**How to avoid :** rédiger sans `jamais|toujours|ne … pas|doit|must|never|always|interdit|obligatoire`, ne pas placer de puces sous un titre « Règles / Garde-fous / Anti-patterns », re-mesurer à chaque édition.
**Warning signs :** ligne `INSTR` d'un fichier > `BL-INSTR` ; verdict `DEPASSEMENT` ; rc 1.

### Pitfall 2 : `vf-dev-manager.md` est à 250 lignes
**What goes wrong :** +1 ligne -> `AVERTISSEMENT-ADR029` (rc 0 mais cran franchi) ; +1 instruction -> rc 1.
**How to avoid :** toute édition à nombre de lignes constant, ou ne pas y toucher (D-01 le permet).

### Pitfall 3 : SANS-BASELINE et ordre des lignes
**What goes wrong :** `vf-product-architect.md` sans ligne de baseline -> rc 2 ; une ligne mal triée -> contrat de baseline incohérent.
**How to avoid :** une ligne neuve, valeurs lues dans la sortie, tri `LC_ALL=C` (entre `plugin/mobile-test-team/…` et `plugin/product-team-bundle/AGENT.md`) ; un seul plan propriétaire du fichier ; nommer l'état rouge intermédiaire.

### Pitfall 4 : monde fermé des agents
**What goes wrong :** agent ajouté sans allowlist (I2) ou allowlist qui nomme un agent absent -> `check-agents --resolve-agents=strict` rouge.
**How to avoid :** même plan, même commit ; `Agent(vf-product-analyst, vf-product-pm, vf-product-architect, prd-gate)`.

### Pitfall 5 : le tag de titre casse `check-mission-exit.sh`
Mesuré (§ Marqueur). **How to avoid :** champ gras.

### Pitfall 6 : le head refuserait tous les labs existants
**What goes wrong :** sans la condition `BRIEF.md` présent (P60-H-01), un lab au poste `dev` (livré en v2.71.0) se verrait refuser tout découpage. **How to avoid :** tester la condition AVANT d'appeler le gate ; mutant « BRIEF absent -> gate non appelé ».

### Pitfall 7 : trois `ARCHITECTURE.md` homonymes
`.planning/codebase/ARCHITECTURE.md` (descriptif, produit par `gsd-map-codebase`), `docs/ARCHITECTURE.md` (document produit de `gsd-docs-update`), `.planning/ARCHITECTURE.md` (décisionnel, neuf) [VERIFIED: `map-codebase.md:141,217`; `docs-update.md:223`; aucune occurrence de `.planning/ARCHITECTURE` dans `plugin scripts docs .github`]. Le gabarit et la doc doivent le dire ; le gate ne lit que le troisième. Le moteur n'a aucun lecteur de `.planning/ARCHITECTURE.md` (pas de collision).

### Pitfall 8 : compteurs et vérités dérivées
`check-version-sync` : « 113 suites » (+1 par suite), « 18 modules » (inchangé), « Scripts (38) » du README conductor, comptes d'agents du manuel. **How to avoid :** tout recompter par `find`/`awk` dans le plan de porte, jamais figé.

### Pitfall 9 : portabilité bash 3.2 / mawk / zsh
Local : bash 3.2.57, awk BWK ; CI : bash 5 + mawk. Pas de `mapfile`, tableaux associatifs, `${v,,}`, `sed -i`, `grep -P`, intervalles `{n,m}` en awk, `match(s, re, arr)`. Les commandes de vérification se jouent sous zsh côté exécutant : toujours `bash <script>` / `bash -c '…'`, jamais un glob non guillemeté [CITED: `59-RESEARCH.md` Pitfall 12]. Mesuré ici : une boucle `for c in "…"; do node $G $c` ne découpe pas sous zsh -> utiliser un script bash.

### Pitfall 10 : suites dépendantes du moteur
**What goes wrong :** une preuve « lecteurs GSD inchangés » qui appelle `gsd-tools` rougit en CI quand `gsd-core@^1` publie (gate T28-F).
**How to avoid :** comparer des champs (`phase_name`, `goal`, `phase_count`), pas du texte brut ; `skip` (non bloquant) si `~/.claude/gsd-core/bin/gsd-tools.cjs` ou `node` est absent, comme `PTB-GSD` [VERIFIED: `test-product-team-bundle.sh:347,431-435`] ; la CI installe le moteur et y joue le cas.

### Pitfall 11 : sonde dépendante de SIGPIPE ou d'une horloge serrée
Voir § Précédent 59 : SIGPIPE ignoré par le runner, plafond d'horloge. Ne pas fonder un mutant sur un tube cassé ; alarmes généreuses.

### Pitfall 12 : le worker architecte et les quatre mappeurs
`gsd-map-codebase` lance **4 agents `gsd-codebase-mapper` en parallèle** (`run_in_background=true`) et commite les documents (`gsd_run query commit "docs: map existing codebase"`) [VERIFIED: `~/.claude/gsd-core/workflows/map-codebase.md:161-181,444`]. Un worker de profondeur 2 voit encore l'outil Agent ; le profondeur 3 ne le voit plus [CITED: mémoire `profondeur-de-spawn-limite-2`] ; l'allowlist `Agent(...)` n'est pas appliquée à l'appel (même source) ; la machine plafonne à 2 workers simultanés. Voir O-4.

### Pitfall 13 : verrou de driver et validation par un dev
La validation du marqueur est une édition de `.planning/` ; Write/Edit n'y est refusé que « sur ce qui est tenu par autrui » [VERIFIED: `REQUIREMENTS.md` DLWS-06]. Un dev qui valide pendant qu'un manager tient le verrou du compartiment est donc refusé jusqu'à la libération : à documenter (un marqueur n'est pas validable en pleine mission).

## Code Examples

### Lecture de l'état du moteur sur fixture (reproductible)
```bash
# bash, pas zsh. Source : mesure de cette recherche (gsd-core 1.19.0)
G="$HOME/.claude/gsd-core/bin/gsd-tools.cjs"
node "$G" roadmap get-phase 2 --cwd /tmp/p60fx/B          # JSON : phase_name/goal identiques à A, section porte la ligne
node "$G" roadmap analyze      --cwd /tmp/p60fx/B          # identique à A (cmp -s)
node "$G" roadmap get-phase 60 --ws fiabilite --cwd /tmp/p60real/B   # copie partitionnée du vrai ROADMAP
```

### Paragraphe de refus de `vf-coder` (0 instruction mesurée)
```markdown
## Porte « phase proposée » (avant 1 et 2)

Avant `gsd-plan-phase` puis avant `gsd-execute-phase`, constate le marqueur de la phase : `"$S"/check-phase-validation.sh --ws <nom> --phase <N>`
(`$S` résolu comme en `mission-flow.md` §Résolution des scripts). Code 0 : phase validée, poursuis. Code 1 : phase proposée, rends
`"statut": "blocked"` avec un finding `action: ask-user`, aucune brique lancée. Codes 3, 5 et 64 : rends `human_needed`.
```
(Mesuré : `vf-coder.md` 22 -> 22 instructions, 146 -> 152 lignes. Le mandat sans numéro d'étape ROADMAP — tâche courte, spec du crafter — n'appelle pas le script.)

### Ligne de rubrique de gabarit lue par un gate (modèle : `check-prd.sh` BRIEF)
```awk
# titres Markdown reconnus par préfixe ASCII, casse indifférente ; corps = au moins une ligne
# hors commentaire HTML, hors ligne commençant par `[`, hors TBD/TODO  (check-prd.sh:223-243)
```

## State of the Art

| Ancien | Actuel | Depuis | Impact |
|--------|--------|--------|--------|
| Aucun script ne rendait rouge une architecture non validée | gate à écrire (A-08, RQ-EP-04) | SEED-001 | Phase 60 |
| `.planning/codebase/ARCHITECTURE.md` descriptif seul | + `.planning/ARCHITECTURE.md` décisionnel | spec §11 | le premier n'est pas promu |
| Hook bloquant envisagé | refus d'équipe + gate constatif (advisory avec halte) | ADR-031, A-07 | aucun hook neuf |
| Gabarits produit PROJECT/REQUIREMENTS | + ARCHITECTURE | Phase 59 -> 60 | même dossier `templates/product/` |

**Dépréciés / écartés :** `gsd-graphify` (refus GSDA-08, Phase 24) ; marqueur de titre ; hook `pre-commit`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Le prototype awk de lecture du marqueur se comporte comme mesuré sous **mawk** (CI), seulement joué sous BWK awk 20200816 | Marqueur de phase | Un comportement divergent (ex. `match` + `RSTART`) ferait rougir la suite en CI seulement ; la suite doit être rejouée en conteneur Linux avant de conclure |
| A2 | Le moteur `gsd-core@^1` futur conservera `OPTIONAL_PHASE_TAG_SOURCE` et l'ignorance des champs gras inconnus | Marqueur de phase | Une version qui valide strictement les champs de phase casserait la non-régression ; atténué par la preuve par champs avec `skip` |
| A3 | La lecture « forme exec = arguments séparés, code non masqué, sans hook » d'ADR-071 (hypothèse A1 de P59-PL-05) tient pour les deux gates | Modèle de gate | Si ADR-071 visait strictement les hooks, la contrainte est plus faible (sans effet sur la conception) |
| A4 | Un worker de profondeur 2 peut lancer des mappeurs de profondeur 3 depuis un skill (inféré de la sonde 2026-09-17 et du cycle de `vf-coder`) | Pitfall 12, O-4 | Si faux, l'architecte ne peut pas assembler `gsd-map-codebase` lui-même |
| A5 | Un modèle `sonnet` / effort `medium` convient à l'architecte (suit les deux autres workers) | Livraison d'un agent | Qualité d'une décision structurante ; réglable sans impact sur les gates |
| A6 | `gsd-map-codebase` est installé aux postes où l'architecte tourne (GSD au scope user « reste visible », ADR-077 Limites) | O-4 | Skill absent : l'architecte doit rendre `blocked`/`human_needed` plutôt qu'improviser |
| A7 | Les rulesets du dépôt (`@picmakpro` sur `.github/` et sur la baseline) sont posés comme décrit | Budget | Sans revue @picmakpro la PR est BLOCKED ; geste du manager, hors plans |

## Open Questions (RESOLVED)

Toutes tranchées à la planification du 2026-10-29 (`60-PLANNING-REGISTRE.md`) ; chaque ligne « RESOLVED » nomme la décision
qui la ferme et dit si c'est un défaut documenté de `60-CONTEXT.md` ou une hypothèse du planificateur.

1. **O-1 — Qui écrit le marqueur : pose à la création (P60-H-03) et bascule à la validation ?**
   - Ce qu'on sait : `check-phase-validation.sh` est en lecture seule (D-04) ; le moteur ne pose pas de champ à `phase add` (vérifié) ; `vf-dev-manager` (46/46, 250 lignes) ne doit pas changer (D-01) ; D-10 interdit un skill neuf et réclame « un outil existant ou un verbe de script ». La bascule `proposed -> validated` est une édition d'une ligne par un humain dev, soumise au verrou de driver (Pitfall 13).
   - Ce qui manque : l'*acteur* de la pose. Options compatibles avec le CONTEXT : (a) édition manuelle par l'équipe selon une doctrine écrite dans `intent-routing.md:102` / `mission-contracts.md` (0 budget, mais le manager ne lit `intent-routing.md` que « quand une intention ne tombe pas manifestement dans un geste connu » : risque de pose oubliée = fail-open) ; (b) un petit script d'écriture séparé (verbe `mark`/`validate`, recensé comme consommateur, `Gate-Touche` non requis hors `check-*`) ; (c) un champ du brief de mission du head (`mission-contracts.md`) qui dit au manager de poser. Aucune n'est un défaut du CONTEXT.
   - Recommandation : (b) pour la **validation** (verbe qui lit `vf-role.sh get`, refuse hors poste `dev`/`solo` en le disant, écrit la ligne avec poste et date) et (a)+(c) pour la **pose** ; à trancher par le planificateur et à tracer `P60-PL-xx`. Ne pas laisser « un humain édite à la main » comme seule voie : c'est exactement un vert que rien ne peut faire rougir.
   - **RESOLVED : P60-PL-05** (écrivain `vf-validation.sh`, verbes `propose` et `validate` : conséquence de P60-D-04 « lecture seule » et de P60-D-10 « un verbe de script, pas un skill ») ; **hypothèse du planificateur P60-PL-07** pour l'acteur de la pose (champ de brief `Phases ajoutées` défini dans `mission-contracts.md`, consommé par `vf-dev-manager` inchangé, sur P60-H-03 et P60-D-01 — volet non prouvé mécaniquement, porté en dette par 60-08) ; **hypothèse du planificateur P60-PL-06** pour le refus au poste product (dépend de P60-H-02).

2. **O-2 — Grammaire de la valeur du marqueur et trace du validateur.** Discrétion du planificateur (conséquence de D-03). Recommandation : `**Validation:** proposed` puis `**Validation:** validated (dev, AAAA-MM-JJ)` ; jeton comparé repliés casse/accents ; valeur inconnue = code 3.
   - **RESOLVED : P60-PL-01** (discrétion de P60-D-03 : `proposed` / `validated (<poste>, <AAAA-MM-JJ>[, override])`, même grammaire pour `ARCHITECTURE.md`).

3. **O-3 — Codes du gate architecture quand `ARCHITECTURE.md` est absent ou incomplet.** D-06 impose « même discipline » sans fixer le mapping. `check-prd.sh` rend 3 pour une cible absente ; ici l'absence est le cas nominal à refuser. Recommandation : étiquettes distinctes sur un code rouge (absente / proposée / rubrique manquante : 1) et 3 réservé à l'indéterminé structurel (fence non fermée, statut illisible) ; le head traite 1 comme « refuser, expliquer ». À figer avant d'écrire la suite.
   - **RESOLVED : P60-PL-03** (discrétion de P60-D-06 : absente, proposée, rubrique manquante → 1 avec étiquettes distinctes ; statut absent, inconnu, multiple, bloc non fermé → 3).

4. **O-4 — Comment l'architecte « assemble » `gsd-map-codebase`.** D-07 : « quand du code existe, la carte `gsd-map-codebase` ». Faits : le skill lance 4 mappeurs en parallèle et commite (Pitfall 12) ; plafond machine 2 workers ; GSD peut être absent au poste product. Options : (a) l'architecte *lit* `.planning/codebase/*.md` s'ils existent et, sinon, rend un finding qui demande la cartographie à un poste dev (aucun Agent, aucun commit) ; (b) l'architecte invoque le skill (`Skill` + `Agent(gsd-codebase-mapper)`, sonde de profondeur comme `vf-coder.md:28-36`). Recommandation : (a) comme défaut, (b) seulement si Samuel le demande ; dans les deux cas `gsd-graphify` n'est cité que sous `graphify.enabled` (D-08). Non tranché ici.
   - **RESOLVED : hypothèse du planificateur P60-PL-08** — option (a) : l'architecte lit `.planning/codebase/*.md` s'ils existent, sinon finding `action: ask-user` ; aucun mappeur lancé, aucun commit. Appuis écrits : P60-D-07 (« quand du code existe, la carte `gsd-map-codebase` »), P60-D-08 (`gsd-graphify` seulement sous `graphify.enabled`) ; hypothèses A4/A6. L'option (b) n'est pas retenue sans demande de Samuel.

5. **O-5 — Le gate de phase en lab partitionné sans `--ws`.** Code 3 ou 64 ? Lab plat : `.planning/ROADMAP.md`. Discrétion du planificateur, à couvrir par mutant ; ne jamais retomber sur le pointeur actif (DLWS-04).
   - **RESOLVED : P60-PL-02** (discrétion de P60-D-04 : code 3 « lab partitionne sans --ws », mutant CPV-MUT-9).

6. **O-6 — `blocked` + finding `ask-user` ou `human_needed` ?** La table de pilotage traite les deux (clause « tout finding `action: ask-user` ») ; en mode autonome le nœud est gelé dans les deux cas. P60-D-01 écrit `blocked` : le suivre ; ajouter un cas T-test qui vérifie la formulation de `vf-coder` et le renvoi à `mission-contracts.md`.
   - **RESOLVED par défaut documenté P60-D-01** (`blocked` + finding `action: ask-user`) ; câblage P60-PL-13, preuve T45 (a) en 60-05.

7. **O-7 — Collision de version avec la Phase 45 (compartiment `gouvernance`, Willy).** Son plan 45-10 annonce « `planning-core` v2.9.0 sans release » alors que `module.json` porte déjà v2.9.0 (Phase 59) [VERIFIED: `gouvernance/ROADMAP.md:193`; `planning-core/CHANGELOG.md` v2.9.0]. Notre bump planning-core serait v2.10.0 ; l'ordre de merge décide qui rebase (P60-D-05 l'avait prévu). À signaler au manager.
   - **RESOLVED par défaut documenté P60-D-05** (collision prévue, aucune coordination dans la phase) : signal porté au manager dans `60-PLANNING-REGISTRE.md` (`signaux_au_manager`) et au SUMMARY de 60-08.

8. **O-8 — Friction au poste `dev` (P60-H-03).** Lue littéralement, toute phase ajoutée par l'équipe au poste `dev` naît proposée : le dev qui vient de demander la phase doit la valider lui-même. À faire confirmer par Samuel avec H-01 à H-04 (déjà dans « Deferred »).
   - **RESOLVED comme hypothèse P60-H-03** (implémentée littéralement, réversible) ; confirmation différée (`60-CONTEXT.md` « Deferred ») et inscrite dans `confirmations_attendues_de_samuel` du registre.

9. **O-9 — Route d'architecture dans la front door `vibeflow-product` (36/36).** Une ligne de la table de routage de `product-team-bundle/AGENT.md` suffit ; à mesurer (Pitfall 1) ; optionnel pour D-07.
   - **RESOLVED : P60-PL-11** (route `livrables: architecture`, appui spec §5.1 « Architecte → vibeflow-product mode architecture », à 36/36 instructions mesurées en 60-04).

## Environment Availability

| Dépendance | Requis par | Disponible | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | gates, suites | oui | 3.2.57 (local) / 5 (CI) | — |
| awk | gates | oui | BWK 20200816 (local) / mawk (CI, non rejoué ici : A1) | conteneur Debian pour la parité CI |
| node | preuve « lecteurs GSD » | oui | v26.5.0 (CI pin 24) | `skip` non bloquant si absent |
| gsd-core | preuve « lecteurs GSD » | oui | 1.19.0 = `latest` npm | `skip` si `gsd-tools.cjs` absent |
| jq | engine, `module-roles.sh` | oui | 1.7.1 | — |
| perl | `alarm` des suites | oui | 5.34.1 | — |
| python3 | gates existants (`-I` obligatoire) | oui | 3.14.6 | — |
| git, gh | G-2, SOBR-05, gestes du manager | oui | 2.50.1 / 2.87.3 | — |
| shellcheck | non requis par une étape CI lue | non | — | sans objet |
| rtk | mesures locales | oui (proxifie grep/ls/diff) | — | `rtk proxy <cmd>` |

**Missing dependencies with no fallback :** aucune.
**Missing dependencies with fallback :** parité mawk (A1) -> rejouer en conteneur avant la porte.

## Validation Architecture

`workflow.nyquist_validation` vaut `true` dans `.planning/config.json` [VERIFIED: lecture, ligne `"nyquist_validation": true`] : section requise.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash `*/tests/test-*.sh` (`ok()/ko()/skip()`, exit 1 si au moins un KO) |
| Config file | aucune — découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (`ci.yml`) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` (à créer) |
| Full suite command | les suites touchées **une à une** (jamais la découverte complète en parallèle ; ≤ 2 workers) ; porte : `replay-ci-jobs.sh --job gates` |

### Phase Requirements -> Test Map (IDs proposés)
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCG-01 | A=B=C sur lecteurs GSD (champs), marqueur survit à `phase complete/insert/remove` | preuve moteur (skip si absent) | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` (cas `CPV-GSD-*`) | Wave 0 |
| ARCG-02 | codes 0/1/3/5/64 et jamais 2, phase absente -> 3, fence/commentaire ignorés, BOM/CRLF, lien/FIFO/gros -> 5, contenu non réimprimé, lecture seule, mutants | suite à mutants | idem + `check-ajout-retrait.sh --root . --strict` + `check-gate-touche.sh` (rc 0) | Wave 0 |
| ARCG-03 | paragraphe de `vf-coder` : appel avant 1 et 2, codes 0/1/3/5/64 traités, bloc `blocked`+`ask-user`, mandat sans N non gardé | T-test à ablation (mutants) dans `test-dev-orchestrator.sh` (cas T45) | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | Wave 0 (cas à ajouter) |
| ARCG-04 | `vf-auto` : section « Étape 0 bis » avant « Moteur direct » | idem | idem | Wave 0 |
| ARCG-05 | pointeur `AGENT.md:33` prolongé, §5 : condition poste + `BRIEF.md`, solo inchangé, override réitéré | idem (ablation par clause) + garde `T44` intacte | idem | Wave 0 |
| ARCG-06 | gabarit : rubriques, statut `proposée`, aucun identifiant gras | structure | `bash -c '…'` du plan + suite de `check-architecture.sh` (gabarit brut rc 1, rempli+validé rc 0) | Wave 0 |
| ARCG-07 | gate architecture : absente / proposée / rubrique manquante / validée ; codes ; mutants | suite à mutants | `bash plugin/conductor/scripts/tests/test-check-architecture.sh` | Wave 0 |
| ARCG-08 | agent : frontmatter, `Worker interne`, I1/I2, ≤ 250 lignes, allowlist, clauses « ne la valide jamais lui-même » | suite de composition (étendre `AGENTS`, `CORPUS`) + `check-agents` ×3 (forme CI) | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | existe (à étendre) |
| ARCG-09 | budget : `check-instruction-budget.sh` rc 0 avant/après, aucune valeur de baseline en hausse, aucun `SKILL.md` neuf | gate | `bash plugin/conductor/scripts/check-instruction-budget.sh` ; `check-baseline-arbitrage.sh` (rc 0 ou 3) | existe |
| ARCG-10 | manuel FR+EN : comptes recomptés, C0-C6 | gate doc | `bash manual/.tools/check-manual.sh` | existe |
| ARCG-11 | porte : job `gates` rejoué, suites une à une, liste blanche du diff, ledger, release intacte | porte | `replay-ci-jobs.sh --job gates --list` puis sans `--list` ; `check-version-sync.sh` | existe |

### Sampling Rate
- **Par commit de tâche :** la suite du fichier touché + `check-instruction-budget.sh` si un agent, un `AGENT.md` ou un `SKILL.md` a bougé.
- **Par vague :** `check-agents.sh` (3 appels de forme CI), `check-skills.sh`, `check-version-sync.sh`, `check-planning-consumers-registered.sh`, `check-ajout-retrait.sh --root . --strict`.
- **Avant `/gsd-verify-work` :** porte de phase (dernier plan) verte ; latence visée < 160 s hors suites longues (`test-vibeflow-update.sh` ~150 s, `test-dev-orchestrator.sh` ~42 s mesuré ici, `test-roles-e2e.sh` ~35 s).

### Wave 0 Gaps
- [ ] `plugin/conductor/scripts/tests/test-check-phase-validation.sh` — ARCG-01, 02 (fixtures générées à l'exécution, aucun `fixtures/` versionné, P59-PL-07)
- [ ] `plugin/conductor/scripts/tests/test-check-architecture.sh` — ARCG-06, 07
- [ ] cas `T45` (nom libre) dans `test-dev-orchestrator.sh` — ARCG-03, 04, 05 : ablation de chaque clause (« preuve incapable de rougir = preuve nulle »), variables `*TMP*` préfixées comme T44
- [ ] extension de `AGENTS`, `CORPUS` et des mutants de `test-product-team-bundle.sh` — ARCG-08
- [ ] **témoin positif d'abord** pour chaque sonde de mutation (valider sur le commit d'avant le correctif, leçon 57) ; témoin positif d'un « canal fermé » établi avant de conclure (mémoire `negatif-aveugle-ne-prouve-rien`)

## Security Domain

`security_enforcement` n'est pas `false` (config : `security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high`) : section requise.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | aucune authentification : un poste est une vue, pas un droit (ADR-077) |
| V3 Session Management | non | — |
| V4 Access Control | non, **par doctrine** | aucun contrôle d'accès promis (A-07) ; le marqueur n'est pas une barrière — risque résiduel accepté et écrit |
| V5 Input Validation | oui | entrées = ROADMAP/`ARCHITECTURE.md` d'un lab (non fiables) : awk pur, jamais d'évaluation, contenu jamais réimprimé, numéro de phase validé par regex numérique, nom de compartiment par `vf_ws_name_valid` |
| V6 Cryptography | non | — |
| V12 Files and Resources | oui | refus lien symbolique, non régulier, illisible, taille > 1 048 576 octets AVANT lecture (modèle `check-prd.sh`) |
| V7 Error handling / logging | oui | codes énumérés, erreurs BRUYANTES (stderr), jamais un vert sur échec de lecture |

### Known Threat Patterns for bash + markdown gates
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injection de prompt par le contenu relu (la sortie du gate entre dans le contexte de l'agent) | Tampering / EoP | ne jamais réimprimer de contenu de fichier ; étiquettes ASCII fixes, ID capturés par motif |
| Chemin hostile (`--ws`, `--roadmap`, espace, `$(…)`) | Tampering | arguments séparés, aucune évaluation de chaîne ; cas `EXEC` de la suite (chemin hostile inerte) |
| Lien symbolique / FIFO / dossier substitué au ROADMAP | Tampering / DoS | refus bruyant code 5 avant lecture |
| Fichier démesuré | DoS | borne 1 Mio |
| Auto-validation par l'agent producteur (l'architecte écrit `validated`) | Repudiation / EoP | pas de mitigation technique (ADR-077) ; mitigations de texte : « ne la valide jamais lui-même », périmètre d'écriture du worker, validation par verbe/humain au poste dev ; **risque résiduel assumé** |
| Perte du marqueur par régénération (`edit-phase` « Regenerate all ») | Tampering | limite fail-open écrite (P60-D-03 c) |
| Fixture/trace d'un nom de client dans la doc | Information disclosure | critère 6 du jalon : zéro nom de client (grep dans les fichiers du diff) |

## Sources

### Primary (HIGH confidence : fichiers lus et commandes exécutées dans cette session)
- `60-CONTEXT.md` ; `REQUIREMENTS.md` (QUAL-01 l. 1305, DLWS-04/06, jalon l. 1333) ; `ROADMAP.md` (Phase 59 et 60, l. 615-653) ; `STATE.md` ; `CLAUDE.md`.
- `plugin/product-team-bundle/scripts/check-prd.sh` (336 l.) et `scripts/tests/test-check-prd.sh` ; `test-product-team-bundle.sh` ; agents `vf-product-{manager,pm,analyst}.md` ; `module.json`.
- `plugin/conductor/scripts/{vf-role.sh, check-planning-consumers-registered.sh, check-instruction-budget.sh, check-ajout-retrait.sh, check-agents.sh, check-divergence.sh}` ; `plugin/planning-core/scripts/workstream-policy.sh` ; `plugin/conductor/references/workstream-planning-consumers.md`.
- `plugin/dev-orchestrator/{AGENT.md, agents/vf-coder.md, agents/vf-dev-manager.md, skills/vf-auto/SKILL.md, references/{product-routing, intent-routing, mission-flow, mission-contracts, docs-flow, _index}.md, scripts/check-mission-exit.sh, scripts/tests/test-dev-orchestrator.sh}`.
- `scripts/{check-gate-touche.sh, check-version-sync.sh, check-affirmation-non-mesuree.sh}` ; `.github/workflows/ci.yml` ; `replay-ci-jobs.sh` ; `manual/.tools/check-manual.sh`.
- gsd-core 1.19.0 : `bin/lib/{roadmap.cjs, roadmap-parser.cjs, phase-id.cjs, roadmap-command-router.cjs, phase-command-router.cjs}`, `workflows/{edit-phase.md, map-codebase.md}` ; `npm view @opengsd/gsd-core dist-tags`.
- `59-RESEARCH.md`, `59-VALIDATION.md`, `59-PLANNING-REGISTRE.md`, `59-02-SUMMARY.md`, `59-08-SUMMARY.md` ; `docs/ADR.md` (ADR-077, ADR-031, ADR-071) ; `.planning/seeds/SEED-001-equipe-produit-v1.md` (A-07, A-08).
- Mesures exécutées : `check-instruction-budget.sh` (avant, copie, copie modifiée), `test-dev-orchestrator.sh` (réel 308/0/0 ; copie témoin et modifiée 304/2/1), `check-version-sync.sh`, `check-agents.sh` sur le bundle, fixtures `/tmp/p60fx`, `/tmp/p60real`, `/tmp/p60bud`, `/tmp/p60bud0`, prototype `/tmp/p60-poc.sh`, helper `/tmp/p60-countlines.sh` (jetables, non livrés).

### Secondary (MEDIUM confidence)
- Mémoires projet : `phase-57-release-v2700`, `phase-58-et-hotfix-en-attente`, `parallelisme-agents-plafond-memoire`, `profondeur-de-spawn-limite-2` (lues en entier pour les trois premières lignes citées).

### Tertiary (LOW confidence)
- Aucune. Les points non rejoués (mawk, profondeur d'un skill depuis un worker) sont dans l'Assumptions Log.

## Metadata

**Confidence breakdown :**
- Marqueur de phase : HIGH — mesuré sur fixture et sur copie du vrai ROADMAP, deux formes, témoins négatifs.
- Modèle de gate et CI : HIGH — scripts, suite et `ci.yml` lus ; comptes mesurés.
- Budget d'instructions : HIGH — mesuré avant et après sur copie jetable avec témoin ; trois sites de refus.
- Livraison d'un agent / manuel : HIGH sur l'empreinte, MEDIUM sur le détail rédactionnel.
- Architecte et `gsd-map-codebase` : MEDIUM — faits du skill vérifiés, comportement à profondeur 2 inféré (A4), O-4 RESOLVED à la planification (hypothèse du planificateur P60-PL-08 : la carte est lue, jamais lancée).

**Research date :** 2026-10-29
**Valid until :** 2026-11-21 (échéance du manifeste `check-agents-manifest.json`) ; la mesure « lecteurs GSD inchangés » est à rejouer à la première publication de `gsd-core@^1` au-delà de 1.19.0.
