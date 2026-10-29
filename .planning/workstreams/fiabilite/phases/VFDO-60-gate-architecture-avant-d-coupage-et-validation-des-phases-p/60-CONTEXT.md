# Phase 60: Gate architecture avant découpage et validation des phases proposées - Context

**Gathered:** 2026-10-29
**Status:** Ready for planning

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F), **sans humain joignable** : mandat Samuel,
/vf-auto session principale, 2026-10-29 (« reprends le handoff et va jusqu'au bout […] Fini les phases
du jalon sans moi »). Ce mandat ne vaut pas arbitrage de fond : **aucune décision de ce fichier n'est
un arbitrage neuf.** Chacune est soit un défaut écrit dans une source citée (spec, SEED, ROADMAP,
CONTEXT d'une phase arbitrée), soit une hypothèse retenue faute de réponse, écrite comme telle
(`P60-H-xx`, Pattern F « rien d'assumé en silence »). Une question sans défaut documenté aurait été
un bloqueur ; le cadrage n'en a trouvé aucune qui empêche le plan.

- Faits établis d'abord par un éclaireur en lecture seule sur `5f449b12` (rapport du 2026-10-29,
  repris en `<code_context>`).
- **P60-D-01 à P60-D-14** : défauts documentés, source citée sur chaque ligne.
- **P60-H-01 à P60-H-04** : hypothèses retenues faute de réponse humaine, à faire confirmer par
  Samuel à son retour (liste en fin de fichier). Le plan les implémente telles quelles et les rend
  réversibles.

**Exigences :** famille `ARCG`, réservée le 2026-10-08 (`REQUIREMENTS.md`), vérifiée libre le
2026-10-29 (`git grep 'ARCG-'` rc=1, `git log --all -S'ARCG-'` vide). Posée à l'ouverture de la
planification, elle reformule P60-D-xx et P60-H-xx sans rien y ajouter.

<domain>
## Phase Boundary

Trois mécanismes, tous **advisory avec halte** (ADR-031, spec §7 Q-04), aucun hook bloquant (A-07) :

1. **Gate architecture avant découpage** (A-08) : un fichier décisionnel `.planning/ARCHITECTURE.md`,
   produit par un worker architecte qui assemble l'existant (`software-architecture` +
   `gsd-map-codebase`), validé par un dev, vérifié par un script déterministe. Tant qu'il n'est pas
   validé, le découpage en phases est refusé avec explication et override humain tracé.
2. **Phases proposées** (A-07) : une phase ajoutée hors poste `solo` naît « proposée » ; un dev la
   valide ; `check-phase-validation.sh` le constate ; l'équipe de dev refuse de planifier ou
   d'exécuter une phase proposée.
3. **Non-régression** : au poste `solo`, rien ne change (critère de succès 2 du jalon).

Hors de cette phase :
- tout hook bloquant ou contrôle d'accès (A-07 : « un rôle est une vue, pas un droit ») ;
- le champ `role:` des registres et la preuve à deux humains (Phase 61) ;
- la bascule `proposable:true` du bundle produit (P59-D-11 : PR tracée hors phase, après run réel) ;
- toute levée du refus de `gsd-graphify` (GSDA-08, Phase 24).

</domain>

<decisions>
## Implementation Decisions

### Qui refuse, et comment

- **P60-D-01 (le refus vit dans l'équipe, pas dans un hook).** Source : SEED A-07 (« refus des managers
  de planifier/exécuter une phase non validée. Pas de hook bloquant ») ; spec §11, corrections de la
  revue à froid (« le head refuse `gsd-phase add` » est infaisable tel quel : un agent n'intercepte pas
  un skill invoqué par l'humain) ; spec §7 Q-04 (« ADR-031 penche pour advisory avec halt condition »).
  - **Phase proposée** : le point de refus est le passage obligé de toute planification/exécution
    d'équipe, `vf-coder`, avant `gsd-plan-phase` et `gsd-execute-phase` → rapport typé `blocked`,
    `action: ask-user`. Le manager reçoit ce bloc et applique sa table de pilotage existante : aucun
    changement de `vf-dev-manager` n'est requis.
  - **Chemin direct `vf-auto`** (moteur `gsd-autonomous`, qui ne passe ni par le manager ni par
    `vf-coder`, éclaireur §4) : le skill `vf-auto` porte le même contrôle avant sa boucle.
  - **Découpage avant architecture** : le head, sur une intention de découpage (ajouter/insérer une
    phase, nouvelle milestone, découper une étape), consulte le gate architecture **via une référence
    chargée à la demande** (précédent : `product-routing.md`, `AGENT.md:33`) et s'arrête en disant
    pourquoi en une phrase ; il exécute sur demande explicite réitérée, override tracé au rapport —
    même sémantique que P59-D-08 (« un poste est une vue, pas un droit »).
- **P60-D-02 (non-régression solo).** Source : critère de succès 2 du jalon (ROADMAP §equipe-produit,
  « une install sans rôle reste identique à aujourd'hui ») ; A-07 (« en solo, auto-validée »). Au poste
  `solo` (lu par `vf-role.sh get`, jamais relu à la main ; codes 1/5/64 jamais repliés sur `solo`,
  `product-routing.md:16-20`) : aucun marqueur posé, gate architecture non consulté. Une phase sans
  marqueur est validée — c'est l'état de toutes les phases existantes.

### Marqueur de phase et script

- **P60-D-03 (forme du marqueur).** Source : A-07 (« marqueur sur la phase ») ; éclaireur §3 (parseur
  gsd-core 1.19.0 : un champ gras additionnel est toléré, précédent `**Mode:**` « preserved verbatim for
  forward-compat » ; un tag entre parenthèses est toléré dans le titre `Phase N (tag):`). Le planificateur
  choisit entre ces deux formes, sous trois contraintes : (a) les lecteurs GSD rendent le même résultat
  avec et sans marqueur, prouvé sur fixture (`roadmap get-phase`, `roadmap analyze`, case de checklist) ;
  (b) **marqueur absent = validée** (P60-D-02) ; (c) la limite fail-open est écrite : le mode
  « Regenerate all » de `edit-phase` peut perdre un champ inconnu, la phase redevient alors validée — la
  doc le dit, le gate ne prétend pas le voir.
- **P60-D-04 (`check-phase-validation.sh`).** Source : A-07 (nom du script) ; QUAL-01 et ADR-071 (critère
  transverse du jalon) ; modèle `check-prd.sh` (éclaireur §7). Lecture seule, forme exec, bash portable
  (ADR-054), workstream-aware (`--ws`), codes documentés sur le modèle de `check-prd.sh` (vert / rouge =
  proposée / indéterminé jamais vert à vide / illisible / usage), trois issues et mutation rouge prouvée,
  enregistré auprès de `check-planning-consumers-registered.sh` s'il entre dans son périmètre.
  Emplacement par défaut : `plugin/conductor/scripts/` (socle installé à tous les postes, le bundle produit
  le `requires`) — le planificateur peut en choisir un autre s'il le justifie par la résolution des deux
  postes consommateurs. Trailer `Gate-Touche` sur les commits qui le touchent (G-2).

### Architecture

- **P60-D-05 (`.planning/ARCHITECTURE.md`, décisionnel).** Source : spec §5.2 (« décisions structurantes
  **avant** le découpage ») ; spec §11 correction (« `.planning/codebase/ARCHITECTURE.md` est descriptif
  (as-is), pas décisionnel → A-08 ne le promeut pas ») ; P59-D-04 (niveau produit, à côté de
  `PROJECT.md`, y compris en lab partitionné). Gabarit neuf dans `planning-core`
  (`references/templates/product/`), à côté des gabarits PROJECT et REQUIREMENTS produit : fichiers neufs
  plus bump et changelog seulement (même règle que 59, collision possible avec la Phase 45 de Willy).
  L'état de validation vit dans le fichier (statut proposé/validé, poste et date du validateur).
- **P60-D-06 (gate architecture séparé).** Source : A-08 (« Gate séparé, qui assemble l'existant […]
  aucun script existant ne rend rouge : le gate est à écrire ») ; éclaireur §1 (RQ-EP-04 confirmée :
  aucun script ne rougit aujourd'hui). Un script déterministe, distinct de `check-phase-validation.sh`,
  même discipline que P60-D-04 : vert seulement si `ARCHITECTURE.md` existe, est marqué validé et porte
  ses rubriques minimales (fixées par le planificateur depuis le gabarit). Nom et emplacement au choix du
  planificateur, résolvable depuis le head.
- **P60-D-07 (worker `vf-product-architect`).** Source : **P59-D-01, arbitrage Samuel, AskUserQuestion
  session principale, 2026-10-27** (« Bundle complet (Recommandé) » : « architect en 60 ») ;
  `59-CONTEXT.md:61`. Worker **interne** du `product-team-bundle`, dispatché par `vf-product-manager`
  (allowlist `Agent(...)` étendue), ≤ 250 lignes (critère 5 du jalon), `check-agents.sh --strict`. Il
  produit `ARCHITECTURE.md` **proposée** en assemblant le skill `software-architecture` (expertise) et,
  quand du code existe, la carte `gsd-map-codebase` ; il ne la valide jamais lui-même. Nouvelle ligne de
  baseline du budget d'instructions pour ce fichier neuf (pas une hausse, G-1 non concerné ; le fichier
  `.tsv` reste sous revue code owner).
- **P60-D-08 (`gsd-graphify` reste refusé).** Source : GSDA-08 (`REQUIREMENTS.md:406-409`, refus Phase 24) ;
  éclaireur §6. A-08 le cite, mais le refus antérieur tient : le gate s'assemble sur `gsd-map-codebase`
  seul ; `gsd-graphify` n'est mentionné que comme complément si `graphify.enabled` est vrai dans le lab.

### Budget, exposition, livraison

- **P60-D-09 (zéro hausse de baseline d'instructions).** Source : mandat du 2026-10-29 (aucun arbitrage
  de fond inventé) + G-1 (`scripts/check-baseline-arbitrage.sh` : toute hausse exige une citation
  d'arbitrage dans le commit) ; éclaireur §4 (`dev-orchestrator/AGENT.md` 33/33, `vf-dev-manager.md`
  46/46 et 250 lignes, `vf-coder.md` 22/23). Le plan n'augmente **aucune** valeur existante de
  `.planning/instruction-budget-baselines.tsv` : le câblage passe par les références chargées à la
  demande, par la marge de `vf-coder` et par le `SKILL.md` de `vf-auto` (sans ratchet). Si le
  planificateur prouve que c'est impossible, il s'arrête et le rapporte (bloqueur humain), il ne cite
  jamais un arbitrage qui n'existe pas. `check-instruction-budget.sh` vert avant/après dans la porte.
- **P60-D-10 (aucun skill neuf).** Source : éclaireur §4 (BOOTSTRAP à 2610 tokens, au-dessus du plafond
  ADR-029 de 2000 : une description de skill neuve l'aggrave) ; SOBR-05 (un ajout dit ce qu'il retire).
  Le geste de validation d'un dev passe par un outil existant ou un verbe de script, pas par un skill.
- **P60-D-11 (gates de jalon).** Source : critères 5 et 6 du jalon, QUAL-01. Agents neufs ≤ 250 lignes et
  `--strict` ; zéro nom de client ; chaque gate livré naît avec ses trois issues et sa mutation rouge.
- **P60-D-12 (manuel).** Source : PRDT-11 (précédent 59), `check-manual.sh` dans le job `gates`. Pages FR
  et EN du manuel mises à jour pour l'architecture et la validation des phases.
- **P60-D-13 (porte de phase).** Source : 59-08 (précédent) ; mémoire « liste de gates ≠ référence ». Le
  dernier plan rejoue le job `gates` **depuis `ci.yml`** (`replay-ci-jobs.sh`) et les suites touchées, met
  le ledger à jour à la main, s'arrête avant PR/merge/tag/release (gestes du manager).
- **P60-D-14 (release).** Source : CLAUDE.md du dépôt (« nouvelle capacité → minor ») et ADR-073
  (évolution fonctionnelle → release). Minor racine décidée et faite par le manager après merge, hors
  plans ; les modules touchés reçoivent leur bump dans la phase.

### Hypothèses retenues faute de réponse (à faire confirmer par Samuel)

- **P60-H-01 (quand le gate architecture s'applique).** Le head ne consulte le gate qu'au poste `product`
  ou `dev` **et** quand le lab est entré dans le flux produit, c'est-à-dire quand `.planning/BRIEF.md`
  existe. Motif : la spec §9 critère 3 décrit la séquence « BRIEF + PRD jugés ≥ seuil, **puis** le head
  refuse le découpage tant que l'architecture n'est pas validée » ; sans cette condition, un lab existant
  au poste `dev` (postes livrés en v2.71.0) se verrait refuser tout découpage du jour au lendemain.
- **P60-H-02 (qui valide l'architecture).** Un dev (poste `dev`), comme pour les phases (A-07). La spec
  §5.2 disait « le rôle Architecte » (H-05), mais A-02 exclut l'architecte des rôles humains du 1er jalon.
- **P60-H-03 (qui pose « proposée »).** Toute phase ajoutée par l'équipe au poste `product` ou `dev`
  naît proposée (lecture littérale d'A-07 : « ajoutée par product ou head ») ; au poste `solo`, aucune.
  Une phase ajoutée à la main par un humain hors de l'équipe n'a pas de marqueur : elle est validée
  (limite écrite, pas un trou : « une vue, pas un droit »).
- **P60-H-04 (marqueur lu comme état du lab).** Le gate ne lit que le marqueur, jamais le poste : une
  phase proposée est refusée à tout poste, `solo` compris, tant qu'elle n'est pas validée. Le poste ne
  décide que de la **pose** du marqueur à la création.

### Ratification (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29)

Réponse à la proposition des défauts pour les Phases 60 et 61 : « Oui aux propositions par défaut pour 60 et 61 ».
Les hypothèses ci-dessus cessent d'être des hypothèses ; chacune est une décision RATIFIÉE, implémentée telle quelle :

- **P60-H-01 : RATIFIÉE.** Le contrôle d'architecture ne s'applique que si `.planning/BRIEF.md` existe (`product-routing.md` §5 ; T45 (e)).
- **P60-H-02 : RATIFIÉE.** C'est un dev qui valide l'architecture (`vf-validation.sh validate --architecture`, refus au poste `product`
  sauf `--override` tracé : `VFV-POSTE-*`). Sa conséquence P60-PL-06 (refus au poste product) suit cette ratification, sans avoir été
  nommée dans la réponse ; elle reste à confirmer nommément avec O-8.
- **P60-H-03 : RATIFIÉE.** Toute phase ajoutée hors du poste `solo` (donc aux postes `product` et `dev`, les seuls autres, `vf-role.sh`)
  naît « proposée » ; au poste `solo`, aucun marqueur (champ de brief `Phases ajoutées`, `mission-contracts.md`).
- **P60-H-04 : RATIFIÉE.** Le marqueur est un état du lab : le gate ne lit jamais le poste (`CPV-POSTE`).
- **P60-H-05 : RATIFIÉE (précision de la portée de H-04).** L'option `--architecture` se lit depuis le RÉPERTOIRE COURANT, pas depuis la
  racine du dépôt git : `vf-validation.sh` refuse (5) tout fichier hors du répertoire courant physique, même à l'intérieur du dépôt
  (`VFV-ARCHI-BORNE`, `VFV-ARCHI-CWD`, mutant VFV-MUT-27).
- **P60-D-15 : DÉCIDÉE (conduite sur résultat indéterminé du contrôle de phase).** SEUL « phase introuvable » (code 3 dont la ligne `BILAN`
  porte `marqueur=introuvable`, sans autre défaut) laisse continuer `vf-coder` et `vf-auto` ; tout autre résultat indéterminé (code 3
  sans cette valeur : ROADMAP absent, lab partitionné sans `--ws`, sections ou marqueurs multiples, valeur inconnue, ligne qui
  ressemble à un marqueur, bloc ou commentaire non fermé ; code 64 ; code 5) ARRÊTE. Elle remplace la conduite des tours 2 et 3 de la revue
  (« les codes 3 et 64 continuent sauf marqueur illisible »), qui laissait passer une phase proposée dès que le contrôle se trompait
  de compartiment ou d'identifiant.

### Claude's Discretion (conséquences, aucun choix neuf)

- Forme exacte du marqueur (P60-D-03), noms et emplacements des scripts (P60-D-04, P60-D-06), rubriques
  minimales du gabarit ARCHITECTURE, répartition en vagues, bumps de modules (minor pour conductor,
  planning-core, product-team-bundle, dev-orchestrator s'ils reçoivent une capacité).

</decisions>

<canonical_refs>
## Canonical References

### Doctrine et cahier des charges
- `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` — §5.2, §7 Q-04, §9 critères 2-3-5-6, §11 (A-07, A-08, corrections de la revue à froid)
- `.planning/seeds/SEED-001-equipe-produit-v1.md` — A-02, A-07, A-08
- `.planning/workstreams/fiabilite/ROADMAP.md` — section `equipe-produit-v1.0`, Phase 60
- `.planning/workstreams/fiabilite/phases/VFDO-59-*/59-CONTEXT.md` — P59-D-01 (architect en 60), P59-D-04, P59-D-07, P59-D-08
- `docs/ADR.md` — ADR-031, ADR-054, ADR-071 ; `REQUIREMENTS.md` QUAL-01, GSDA-08

### Code
- `plugin/product-team-bundle/` (scripts/check-prd.sh et sa suite = modèle de gate) ; `plugin/planning-core/references/templates/product/`
- `plugin/dev-orchestrator/AGENT.md`, `references/product-routing.md`, `references/intent-routing.md`, `agents/vf-coder.md`, `skills/vf-auto/SKILL.md`
- `plugin/conductor/scripts/vf-role.sh`, `check-planning-consumers-registered.sh`, `check-instruction-budget.sh`
- `plugin/software-architecture/` (skill, références), `plugin/audit-architecture/` (méta-skill, aucun script)
- gsd-core 1.19.0 : `roadmap-parser.cjs` (`getRoadmapPhaseInternal`, `extractPhaseFieldMultiline`), `roadmap.cjs` (`searchPhaseInContent`, case de checklist), `phase-id.cjs` (`OPTIONAL_PHASE_TAG_SOURCE`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `check-prd.sh` : codes 0/1/3/5/64, ordre 5 > 1 > 3 > 0, entrées non fiables jamais réimprimées, ligne `BILAN` ; suite à 26 mutants avec helper `mutant()`.
- `vf-role.sh get` : `solo|product|dev`, priorité `VF_ROLE` > `.claude/vibeflow-role` > `solo`.
- `product-routing.md` : référence chargée à la demande par le head au poste product (`AGENT.md:33`).

### Established Patterns
- Juge/worker interne : `vf-internal: true`, marqueur « Worker interne », allowlist du manager en monde fermé (`check-agents --resolve-agents=strict`).
- Gates : forme exec, trois issues, mutation rouge, suite découverte par la CI (`*/tests/test-*.sh`).

### Integration Points
- `vf-coder.md:42` (`gsd-plan-phase`) et `:45` (`gsd-execute-phase`) : points de refus d'une phase proposée.
- `vf-auto/SKILL.md:9,54-57` : chemin direct `gsd-autonomous`.
- Budget : `AGENT.md` 33/33, `vf-dev-manager.md` 46/46 (250 lignes), `vf-coder.md` 22/23.
- CODEOWNERS : `.planning/instruction-budget-baselines.tsv` (ligne neuve pour `vf-product-architect`).

</code_context>

<specifics>
## Specific Ideas

- Écart relevé par l'éclaireur, à corriger seulement si la phase touche la ligne : `docs-flow.md:90` cite `vf-dev-manager.md:32` comme lecteur de `codebase/`, la ligne réelle (31) ne nomme pas `ARCHITECTURE.md`.
- La preuve « depuis un lab vide, le rôle product produit BRIEF + PRD ≥ seuil, puis le head refuse » (critère 3 du jalon) se fait ici **mécaniquement** (scripts, fixtures, suites). Le run réel d'agents sur un lab désigné par Samuel reste le geste humain de P59-D-11.

</specifics>

<deferred>
## Deferred Ideas

- Run réel du flux produit complet (BRIEF → PRD → architecture → refus) sur un lab désigné : geste humain, condition de `proposable:true`.
- ~~Confirmation de P60-H-01 à P60-H-04 par Samuel.~~ Faite le 2026-10-29 (§ Ratification) ; restent P60-PL-06 et O-8, à confirmer nommément.

</deferred>
