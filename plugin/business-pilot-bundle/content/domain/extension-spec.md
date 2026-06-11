# EXTENSION DE DOMAINE — `business/`

> Structure **exacte** du sous-dossier de domaine à scaffolder sous `.planning/` lors de
> l'instanciation du lab `business-pilot` (profil planning **standard**). Posée par `vf-new-lab` en
> déléguant à `vf-planning` (planning-core).
>
> **PAS `codebase/`** : le métier n'est pas le code. Le nom et le contenu suivent le métier (P7).

---

## Arborescence cible

```
.planning/
├── STATE.md                    # clé de voûte (planning-core, tronc commun — PAS dans business/)
├── PROJECT.md                  # quoi + valeur + Key Decisions D-NN (tronc commun)
├── ROADMAP.md                  # phases en « Sprints stratégiques » + « Initiatives » (tronc commun)
├── REQUIREMENTS.md             # exigences métier à IDs (profil standard, tronc commun)
├── MILESTONES.md               # archive des jalons livrés (tronc commun)
├── config.json                 # { "profile": "standard", ... } (tronc commun)
├── milestones/                 # snapshots de jalons (tronc commun)
├── phases/NN/                  # PLAN.md + SUMMARY.md par étape (tronc commun)
│
└── business/                   # ◀── EXTENSION DE DOMAINE (ce document)
    ├── STRATEGY.md
    ├── OFFERS.md
    ├── PRICING.md              # OPTIONNEL — uniquement si > 3 offres
    ├── PROCESSES.md
    ├── PIPELINE.md             # INDEX du pipeline — lu EN PREMIER par l'agent commercial
    ├── CLIENTS.md
    └── pipeline/
        ├── leads/              # opportunités non qualifiées
        ├── prospects/          # opportunités qualifiées en cours
        ├── clients/            # opportunités gagnées (avant/pendant contractualisation)
        ├── delivery/           # prestations en cours de livraison
        ├── completed/          # prestations terminées
        └── archive/            # opportunités perdues / dossiers clos (JAMAIS supprimés)
```

---

## Rôle de chaque fichier

### Fichiers de domaine (racine de `business/`)

| Fichier | Rôle | Propriétaire principal |
|---|---|---|
| `STRATEGY.md` | Cap commercial : positionnement, ICP (client idéal), canaux, priorités du business. | commercial |
| `OFFERS.md` | Catalogue des offres : libellé, périmètre, livrables, conditions. | commercial / finance |
| `PRICING.md` *(optionnel)* | Grille tarifaire détaillée, remises bornées, plancher de marge. **Créé uniquement si > 3 offres** ; sinon le pricing vit dans `OFFERS.md`. | finance |
| `PROCESSES.md` | Processus de delivery : étapes d'onboarding, jalons types, **SLA paramétrables**, critères d'acceptation. | delivery |
| `PIPELINE.md` | **INDEX du pipeline commercial** (table d'opportunités : ID, nom, étape, score, prochaine action, date). **Lu en premier** par l'agent commercial à chaque passage. | commercial |
| `CLIENTS.md` | Référentiel clients : contexte, termes de paiement, encours, historique, satisfaction/NPS. | delivery / finance |

### Dossiers de pipeline (`business/pipeline/`)

Chaque opportunité est **un fichier**, déplacé d'un dossier à l'autre selon son étape (jamais
dupliqué, **jamais supprimé**) :

| Dossier | Contient | Transition entrante |
|---|---|---|
| `leads/` | Leads bruts non qualifiés. | Création (entrée pipeline). |
| `prospects/` | Opportunités qualifiées (score posé). | leads → prospects (qualification commercial). |
| `clients/` | Opportunités gagnées, en contractualisation. | prospects → clients (closing). |
| `delivery/` | Prestations en cours de livraison. | clients → delivery (prestation lancée). |
| `completed/` | Prestations terminées et facturées (préparation). | delivery → completed (jalons clos). |
| `archive/` | Opportunités **perdues** ou dossiers clos. | depuis n'importe quelle étape (perte / clôture). |

### Convention de nommage des dossiers d'opportunité

```
YYYY-MM-DD-CLI-XXX-nom.md
```

- `YYYY-MM-DD` — date de création de l'opportunité.
- `CLI-XXX` — identifiant client/opportunité stable (incrémental, ne change jamais en avançant).
- `nom` — slug court lisible.

> **Règle dure** : un dossier d'opportunité n'est **jamais supprimé**. Une perte = déplacement vers
> `archive/` (traçabilité commerciale). Le même `CLI-XXX` suit l'opportunité tout au long du pipeline.

---

## Garde-fous de l'extension

- **Index d'abord** : tout agent lisant le pipeline lit **`PIPELINE.md`** avant d'ouvrir un dossier
  (progressive disclosure — on ne charge pas tout le pipeline en contexte).
- **`PRICING.md` conditionnel** : ne le créer que si le catalogue dépasse 3 offres ; sinon ne pas le
  poser (anti sur-documentation).
- **Pas de doublon avec la mémoire** : un blocage *en cours* se note dans `STATE.md`/le dossier
  d'opportunité ; un blocage *capitalisé* va en **BLOCKERS** — jamais les deux avec le même contenu
  (`content/registres.md`).
- **Gate qualité** : les chemins `business/pipeline/delivery/**` et les propositions sortantes sont
  couverts par la **rule path-scopée de gate qualité** (vérif avant envoi client, P5).
- **Exécution réelle hors Lab** : aucune facture/contrat/encaissement n'est *exécuté* dans
  `business/` — le dossier **documente et prépare**, l'acte se fait dans les outils via MCP (LRN-068).
