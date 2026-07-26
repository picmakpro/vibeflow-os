# CHANGELOG — business-pilot-bundle

## [v2.0.2] — 2026-07-26

### Modifié
- `README.md` monté au standard de doc framework : tagline, en-tête `Type · Version · Dépend de`
  (l'en-tête **Version** est désormais déclaré — couvert par le gate `check-version-sync.sh`),
  sections Quoi / Installation / Démarrer / Usage / Référence / Limites.

## [v2.0.1] — 2026-07-26

### Corrigé
- `requires` += `conductor` (team-kernel, dépendance non déclarée).

## [v2.0.0] — 2026-07-25 — Matérialisation : de doc-only à module installable (team-kernel)

Bascule majeure : le bundle n'est plus un plan de fabrication (`doc-only`, `proposable: false`)
mais un **module installable** — la deuxième équipe métier non-dev complète sur le team-kernel
(après le content-bundle, modèle de référence de cette matérialisation).

### Ajouté
- **`agents/vf-business-manager.md`** (opus, memory: project) — manager de mission business sur
  le kernel : brief en langage naturel, lecture index-first de `PIPELINE.md`/`PROCESSES.md`/
  `CLIENTS.md`/registres, plan de bataille en DAG (chaîne canonique **par dossier client** :
  commercial → delivery → gate qualité → humain → finance ; tout nœud produisant un livrable
  client insère gate + humain avant l'étape suivante) + verrou de driver (`$S`), dispatch
  **parallèle** des dossiers clients indépendants (périmètres disjoints par construction),
  digest ≤30L par mandat, contrôle de flux sur rapports typés, halt conditions (5 codes P11).
  **Deux Iron Laws business** : (a) AUCUN envoi client (devis, livrable, relance, facture)
  sans validation humaine — nœud `humain(d)` en `human_needed` par construction, l'humain
  envoie (ADR-031 + LRN-068) ; (b) AUCUN chiffre financier inventé — chaque montant extrait
  d'une source citée (`OFFERS`/`PRICING`/dossier/`CLIENTS`/`KPIS.md` de kpi-analyst quand il
  est installé) ou marqué `low`.
- **3 workers sonnet cloisonnés** (Pattern 12 : `vf-internal`, tools sans Task/Agent/Skill,
  périmètres d'écriture stricts et disjoints) issus des blueprints, qui restent dans `content/`
  comme trace de conception :
  - `vf-business-commercial` (← business-pilot-commercial.blueprint) — qualification/scoring,
    propositions/devis/relances **rédigés, jamais envoyés**, montants sourcés uniquement, tient
    `PIPELINE.md`. Écrit uniquement `PIPELINE.md` + `pipeline/{leads,prospects,clients}/` + registres.
  - `vf-business-delivery` (← business-pilot-delivery.blueprint) — jalons/SLA, **préparation**
    des livrables (gate + validation humaine avant tout envoi), satisfaction, signaux
    upsell/churn remontés. Écrit uniquement `pipeline/{delivery,completed}/` + registres.
  - `vf-business-finance` (← business-pilot-finance.blueprint) — factures/relances/prévisions
    **préparées, jamais envoyées**, Iron Law « aucun chiffre inventé » alignée kpi-analyst,
    double filet avant facturation (gate vert + validation humaine du livrable facturé, sinon
    REFUS), EVAL systématique (P8, J+30/60/90). Écrit uniquement `business/finance/` +
    `CLIENTS.md` + registres.
- **`agents/quality-gate-client.md`** (sonnet, read-only : tools `Read, Glob, Grep`, sans
  Write/Edit) — LE gate des blueprints enfin matérialisé (marqué « à fabriquer via
  skill-creator » depuis l'audit F16) en **juge frais** : rubric /100 explicite (périmètre
  vendu 25 — éliminatoire —, montants sourcés/cohérents 25 — éliminatoire —, complétude 20,
  qualité prête-à-envoyer 15, conditions/engagements 15), seuil 80, verdict typé avec findings
  cités. Son vert n'autorise jamais l'envoi : il ouvre l'étape de validation humaine.
- **`skills/vf-business/SKILL.md`** — point d'entrée du métier (« qualifie ce lead »,
  « prépare le devis », « prépare la facture », « fais tourner le business de la semaine ») :
  aiguillage geste simple (chaîne courte worker → gate → validation humaine) vs mission
  (`SEUIL_EQUIPE_BUSINESS = 3` dossiers/actions ou signal de durée → `vf-business-manager`),
  garde first-use si `.planning/business/PIPELINE.md` absent (→ `vf-planning`, profil standard
  + extension `business/`), les deux Iron Laws en invariants.
- **`scripts/tests/test-business-pilot-bundle.sh`** — suite machine (14 tests) : les 12 tests
  transposés du content-bundle (agents + frontmatter, densité ADR-029, `check-agents.sh
  --strict`, gate sans Write/Edit, cloisonnement Pattern 12, manager sans production, DIGEST +
  rapports typés, validation humaine non contournable, aiguillage du skill, module.json/VERSION,
  encart de matérialisation, rubric du gate) + 2 spécifiques métier : **T13** human-gate
  d'envoi client non contournable (« jamais » + `human_needed` chez manager/commercial/finance,
  interdiction d'envoi explicite, invariant dans le skill) et **T14** zéro chiffre inventé
  (Iron Law chez finance + manager, « montant non sourcé » éliminatoire au gate, adossement
  kpi-analyst).

### Modifié
- `module.json` : type `doc-only` → `agents + skill + scripts` ; **`proposable: true`** (le
  module est réellement fini et vert — suite 14/14 + check-agents --strict).
- `content/BUNDLE.md` : encart de matérialisation en tête — le document reste la trace de
  conception ; le réel vit dans `agents/` et `skills/`.
- `content/agents/business-pilot-delivery.blueprint.md` : la mention historique
  « quality-gate-client à fabriquer au ficelage du lab via skill-creator » est mise à jour —
  le gate est désormais **LIVRÉ par le module** comme agent juge read-only.
- `README.md` : réécrit pour refléter le module réel (équipe, chaîne, Iron Laws, tests).

### Décisions de design
- Le « human-gate d'envoi » n'est **pas un agent** : c'est l'étape de validation humaine,
  orchestrée par le manager (statut `human_needed`) — le lab prépare, le gate juge, l'humain
  valide PUIS envoie dans ses outils (ADR-031 + LRN-068).
- Le gate qualité, décrit dans les blueprints comme un skill « à fabriquer », devient un
  **juge read-only du kernel** (P8 : évaluation scorée par juge frais, machine-cloisonnée par
  les tools) — même esprit, forme kernel — avec DEUX critères éliminatoires métier : montant
  non sourcé, promesse hors périmètre vendu.
- Périmètres d'écriture disjoints **par étape de pipeline** : commercial =
  `PIPELINE.md` + `leads|prospects|clients/`, delivery = `delivery|completed/`, finance =
  `business/finance/` + `CLIENTS.md` — dispatch parallèle sûr par construction entre dossiers
  clients ET entre étages. Le déplacement d'un dossier appartient au propriétaire de l'étape
  cible ; un dossier n'est jamais supprimé (perte → `archive/`).
- Le pilier finance **s'adosse à kpi-analyst** (module optionnel, pas une dépendance dure) :
  quand `KPIS.md` et ses extracteurs déterministes existent, ils sont la source à privilégier
  pour CA/encours/marge — même Iron Law des deux côtés.

## [v1.2.1] — 2026-07-25

### Corrigé
- Le gate `quality-gate-client` est explicitement marqué « à fabriquer au ficelage du lab » au lieu d'être invoqué comme existant (F16).

## [v1.2.0] — 2026-07-16 (ADR-048 — orchestrateur métier)

### Modifié
- Doctrine d'orchestration réconciliée : les 3 agents produisent, un **orchestrateur métier** (`business-pilot`,
  skill `metier-orchestration`) est posé d'office (≥2 spécialistes) pour planifier/déléguer/vérifier/réconcilier/
  mettre à jour `.planning/`. Le `conductor` redevient strictement méta (plus « l'orchestration »).

## [v1.1.0] — 2026-07-05 (ADR-044)

### Corrigé
- Les 3 blueprints (commercial/delivery/finance) reçoivent une `description:` dans le frontmatter
  cible — sans elle, les agents instanciés n'étaient JAMAIS auto-routés par le runtime.
- BUNDLE.md : l'énumération d'instanciation inclut `description` (obligatoire, gate check-agents).

Toutes les évolutions notables de ce bundle métier. Convention de versionnage : SemVer (`vMAJEUR.MINEUR.CORRECTIF`).

---

## v1.0.0 — 2026-06-11

### Ajouté

- **Création du bundle métier `business-pilot`** (module `doc-only` du plugin vibeflow-os).
- **Manifeste** `content/BUNDLE.md` : métier piloté, profil de rigueur planning (`standard`), extension de domaine (`business/`), vocabulaire métier (Sprint stratégique / Initiative / Obstacle / Rollout), liste des 3 agents, modules recommandés et **flux d'instanciation** consommé par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`), chacun prêt à instancier en agent natif ≤250 lignes (charte densité ADR-029) :
  - `business-pilot-commercial.blueprint.md` (sonnet) — pilotage du pipeline commercial, de la qualification au closing.
  - `business-pilot-delivery.blueprint.md` (sonnet) — exécution et suivi des prestations, satisfaction, détection d'upsell.
  - `business-pilot-finance.blueprint.md` (sonnet) — revenus, facturation, rentabilité, prévisions, évaluations quantitatives (P8).
- **Spécification d'extension de domaine** `content/domain/extension-spec.md` : structure exacte du dossier `business/` à scaffolder (fichiers + sous-dossiers de pipeline + rôle de chaque fichier).
- **Spécification des registres** `content/registres.md` : les 5 registres mémoire canon, la convention d'IDs, la répartition de capitalisation par agent et le pont planning↔mémoire (un seul propriétaire par information).
- **Câblage du filet d'audit** : déclaration des dépendances `validator` + `audit-architecture` (« pas de lab sans filet ») et de l'orchestration déléguée au module `conductor`.

### Notes

- Ce bundle **ne re-code aucun orchestrateur** : l'orchestration est portée par `conductor` (vibeflow-conductor). Les agents métier escaladent au conductor (contrat C4).
- Les `skills:` déclarés dans les blueprints sont à **matérialiser via `skill-creator`** au moment de l'instanciation — ils ne sont pas fournis dans ce bundle.
