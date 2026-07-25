# CHANGELOG — growth-bundle

## [v2.0.0] — 2026-07-25 — Matérialisation : de doc-only à module installable (team-kernel)

Bascule majeure : le bundle n'est plus un plan de fabrication (`doc-only`, `proposable: false`)
mais un **module installable** — la deuxième équipe métier non-dev complète sur le team-kernel,
transposée fidèlement du pattern `content-bundle` v2.0.0.

### Ajouté
- **`agents/vf-growth-manager.md`** (opus, memory: project) — manager de mission growth sur le
  kernel : brief en langage naturel, lecture de `ICP`/`OFFRES`/`FUNNEL`/`METRICS` + registres
  (index-first), plan de bataille en DAG (5 nœuds par campagne : stratégie → production →
  gate → humain → analyse) + verrou de driver (`$S`), dispatch **parallèle** des campagnes
  indépendantes (un dossier `campagnes/<slug>/` par campagne, périmètres disjoints par
  construction ; séquentialisation si canal partagé), digest ≤30L par mandat, contrôle de flux
  sur rapports typés, halt conditions (5 codes P11). **Iron Law growth** : tout envoi réel
  (email, publication, dépense publicitaire, outreach) est **HUMAN-GATED** — statut
  `human_needed`, jamais d'exécution d'acquisition en autonomie (ADR-031, cohérent avec la
  frontière Tier 2 de `kpi-analyst`). L'analyse ne tourne qu'après lancement humain effectif.
- **3 workers sonnet cloisonnés** (Pattern 12 : `vf-internal`, tools sans Task/Agent/Skill,
  périmètre d'écriture strict par étage) issus des blueprints, qui restent dans `content/`
  comme trace de conception :
  - `channel-strategist` (← channel-strategist.blueprint, **recadré de opus-orchestrateur en
    worker de stratégie**) — fiche de stratégie : canal confirmé (duplication `_TEMPLATE/` si
    absent), ICP local (delta), offre activée, hypothèse EXP scorée ICE, seuils rappelés.
    Écrit uniquement `campagnes/<slug>/strategie.md` (+ duplication de canal) + registres.
  - `copywriter-sequences` (← copywriter-sequences.blueprint) — séquences/créatives ancrées
    ICP local + offre, ≥ 2 variantes A/B à levier unique, zéro slop, zéro claim chiffré non
    sourcé, opt-out intégré, auto-contrôle 4 critères. N'envoie JAMAIS. Écrit uniquement
    `campagnes/<slug>/sequences.md` + index du canal + registres.
  - `campaign-analyst` (← campaign-analyst.blueprint) — analyse d'une campagne **lancée par
    l'humain uniquement** (refus sinon) : CAC/ROAS vs seuils, verdict GO/ITERATE/KILL,
    METRICS/EXPERIMENTS tenus. **Iron Law de la mesure** (même que `kpi-analyst`) : aucun
    chiffre inventé — chaque métrique sourcée ou « inconnue » (confiance low) ; collecte
    externe = Tier 2 human-gated lecture seule.
- **`agents/growth-quality-judge.md`** (sonnet, read-only : tools `Read, Glob, Grep`, sans
  Write/Edit) — les critères de qualité des blueprints matérialisés en **juge frais** :
  rubric /100 explicite (claims sourcés 25 — éliminatoire —, consentement/anti-spam/RGPD 20 —
  éliminatoire —, ancrage ICP+offre 15, A/B levier unique 10, anti-slop 10, CTA unique 10,
  fidélité à la stratégie 10), seuil 80, verdict typé avec findings cités.
- **`skills/vf-growth/SKILL.md`** — point d'entrée du métier (« lance une campagne cold
  email », « analyse les résultats », « arbitre mes canaux », « la vague du mois en
  autonomie ») : aiguillage geste simple (chaîne courte orchestrée depuis le skill) vs
  mission (`SEUIL_EQUIPE_GROWTH = 3` campagnes/séquences ou signal de durée →
  `vf-growth-manager`), garde first-use si `growth/` absent (→ `vf-planning`).
- **`scripts/tests/test-growth-bundle.sh`** — suite machine (12 tests) : agents présents +
  frontmatter, densité ADR-029, `check-agents.sh --strict` vert, juge sans Write/Edit,
  cloisonnement Pattern 12 (allowlist du manager fermée sur l'équipe), manager sans périmètre
  de production, DIGEST + rapports typés, **human-gate d'acquisition non contournable**
  (manager + copywriter + analyst + skill), aiguillage du skill, cohérence module.json/VERSION,
  encart de matérialisation, rubric du juge (éliminatoires sourcing + consentement/RGPD).

### Modifié
- `module.json` : type `doc-only` → `agents + skill + scripts` ; **`proposable: true`** (le
  module est réellement fini et vert — suite 12/12 + check-agents --strict).
- `content/BUNDLE.md` : encart de matérialisation en tête — le document reste la trace de
  conception ; le réel vit dans `agents/` et `skills/`.
- `README.md` : réécrit pour refléter le module réel (équipe, chaîne, tests).

### Décisions de design
- Le `channel-strategist` des blueprints était l'**orchestrateur métier** (opus, ADR-048) ;
  sur le team-kernel, l'orchestration revient au manager — il devient un **worker sonnet**
  de stratégie canal/ICP. Les décisions d'allocation/kill qu'il portait deviennent des
  **recommandations à arbitrage humain** (finding `ask-user`), cohérent avec le human-gate
  de la dépense.
- Ordre du DAG : `stratégie → production → gate → humain → analyse` — le gate (juge frais)
  score la production AVANT la validation humaine, et l'**analyse ferme la boucle** après le
  lancement humain (pas de données réelles avant l'envoi ; un « analyse » avant gate serait
  un faux nœud).
- Le gate anti-slop `audit-architecture` des blueprints devient un **juge read-only du
  kernel** (P8 : évaluation scorée par juge frais, machine-cloisonnée par les tools), enrichi
  des garde-fous métier (consentement/RGPD éliminatoire) — même esprit, forme kernel.
- Convention de production : une campagne = un dossier `campagnes/<AAAA-MM-JJ>-<slug>/`
  (`strategie.md` / `sequences.md` / `analyse.md`), périmètres disjoints par étage ET par
  campagne → dispatch parallèle sûr ; les fichiers de canal (`METRICS`, index `SEQUENCES`)
  restent au canal, séquentialisés quand deux campagnes partagent un canal.

## [v1.1.1] — 2026-07-25

### Corrigé
- Référence `/checkpoint` → `/vf-audit` dans les registres.

## [v1.1.0] — 2026-07-16 (ADR-048 — orchestrateur métier)

### Modifié
- Contradiction levée : `channel-strategist` est déclaré explicitement comme l'**orchestrateur métier** du
  bundle (instance du pattern ADR-048, câblé au skill `metier-orchestration`) — plus de « aucun orchestrateur
  re-codé » qui contredisait son rôle. Le `conductor` reste méta.

## [v1.0.1] — 2026-07-05 (ADR-044)

### Corrigé
- BUNDLE.md : l'énumération d'instanciation inclut `description` (idem content-bundle).

Toutes les évolutions notables de ce bundle métier sont consignées ici.
Format : [SemVer]. Dates : YYYY-MM-DD.

---

## v1.0.0 — 2026-06-11

### Ajouté

- **Manifeste de bundle** (`content/BUNDLE.md`) : métier growth/acquisition (GrowthFlow), profil de
  rigueur planning **standard**, extension de domaine **`growth/` organisée PAR CANAL D'ACQUISITION**,
  vocabulaire métier (canal / séquence / ICP / offre / expérience / CAC / ROAS), liste des 3 agents,
  modules recommandés, et le **flux d'instanciation** consommé par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`) prêts à instancier en agents natifs ≤250L (ADR-029) :
  - `channel-strategist.blueprint.md` (opus) — orchestrateur growth, décide activation/kill de canal,
    alloue budget, priorise les expériences. NE RÉDIGE NI N'ANALYSE lui-même.
  - `copywriter-sequences.blueprint.md` (sonnet) — rédige/itère séquences & créatives PAR CANAL.
  - `campaign-analyst.blueprint.md` (sonnet) — renseigne METRICS, calcule CAC/ROAS, tient EXPERIMENTS.
- **Spécification d'extension de domaine** (`content/domain/extension-spec.md`) : structure exacte de
  `growth/` (niveau global + niveau canal à 5 fichiers identiques + `channels/_TEMPLATE/`).
- **Spécification des registres** (`content/registres.md`) : 5 registres canon (DECISIONS / LEARNINGS /
  BLOCKERS / JOURNAL / EVALS), convention d'IDs, répartition par agent, pont planning↔mémoire.
- **Garde-fous métier** : RGPD prospects (interdits CLAUDE.md), seuils CAC/ROAS CIBLE vs ALERTE
  rouge(kill)/orange(itérer) par canal, tag-canal obligatoire en LEARNINGS, gate `audit-architecture`
  (verdict bloquant anti-slop avant lancement de campagne), nommage kebab-case.

### Châssis doctrine ré-embarqué

- Principes Core P1/P3/P4/P5/P7/P8/P9 référencés (jamais redupliqués).
- Wiring `planning-core` (socle `.planning/` + profil standard + extension nommée selon le métier).
- Wiring `conductor` (orchestration méta déléguée — le bundle ne re-code aucun orchestrateur).
- Auditeurs câblés : agent `vibeflow-validator` + skill `audit-architecture`.
- Pont planning↔mémoire à propriétaire unique (D-NN en `PROJECT.md` → promotion DECISIONS).
