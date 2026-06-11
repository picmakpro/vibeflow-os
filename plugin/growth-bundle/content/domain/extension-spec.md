# Extension de domaine — `growth/` (organisée PAR CANAL)

> Spécification de l'extension de domaine scaffoldée par `vf-new-lab` (étape 4 du flux d'instanciation).
> Nom imposé : **`growth/`** (PAS `codebase/` — le métier n'est pas le code). Posée à la racine du lab,
> à côté de `.planning/` et `.claude/`.
>
> **Innovation centrale** : tout est dédoublé entre un **niveau GLOBAL** (vérité maître) et un
> **niveau CANAL** (delta local), pour comparer les canaux **sans contaminer** leurs apprentissages.

---

## Arborescence cible

```
growth/
├── ICP.md                        # GLOBAL — ICP maître
├── OFFRES.md                     # GLOBAL — catalogue d'offres
├── FUNNEL.md                     # GLOBAL — AARRR + North Star + mapping canal→étape
├── METRICS.md                    # GLOBAL — comparatif inter-canaux (1 canal = 1 colonne)
└── channels/
    ├── _TEMPLATE/                # SQUELETTE — 5 fichiers vides à dupliquer pour ajouter un canal
    │   ├── ICP.md
    │   ├── SEQUENCES.md          # (ou CREATIVES.md selon le canal)
    │   ├── OFFRES.md
    │   ├── METRICS.md
    │   └── EXPERIMENTS.md
    ├── cold-email/               # CANAL — mêmes 5 fichiers
    │   ├── ICP.md
    │   ├── SEQUENCES.md
    │   ├── OFFRES.md
    │   ├── METRICS.md
    │   └── EXPERIMENTS.md
    ├── linkedin-ads/             # CANAL — CREATIVES.md au lieu de SEQUENCES.md
    │   ├── ICP.md
    │   ├── CREATIVES.md
    │   ├── OFFRES.md
    │   ├── METRICS.md
    │   └── EXPERIMENTS.md
    ├── seo/                      # CANAL (exemple — créé à la demande)
    └── partenariats/             # CANAL (exemple — créé à la demande)
```

> **Nommage** : tous les dossiers de canaux en **kebab-case** (`cold-email`, `linkedin-ads`) ; le nom
> affiché dans la doc doit être cohérent avec le nom de dossier. Ajouter un canal = **dupliquer
> `_TEMPLATE/`** (jamais recréer les fichiers à la main → évite les régressions de structure).

---

## Niveau GLOBAL — 4 fichiers

### `growth/ICP.md` — ICP maître
Rôle : la cible idéale **de référence** pour tout le lab (segments, douleurs, déclencheurs, critères
d'exclusion). Chaque canal n'en porte que le **delta**. Propriétaire : `channel-strategist`.
**RGPD** : profils/segments uniquement, aucune personne nominative.

### `growth/OFFRES.md` — catalogue d'offres
Rôle : l'ensemble des offres disponibles (proposition de valeur, prix/format, preuve). Les canaux
référencent les offres **activées** chez eux. Propriétaire : `channel-strategist`.

### `growth/FUNNEL.md` — funnel AARRR + North Star
Rôle : le funnel global (Acquisition / Activation / Rétention / Revenu / Recommandation), la **North
Star metric** du lab, et le **mapping canal → étape** (quel canal nourrit quelle étape). Propriétaire :
`channel-strategist`.

### `growth/METRICS.md` — comparatif inter-canaux
Rôle : **table de comparaison où 1 canal = 1 colonne**. Agrège les CAC/ROAS de chaque canal pour
l'arbitrage. Renseigné par `campaign-analyst` (qui reporte les colonnes depuis chaque canal), lu par
`channel-strategist`. Forme :

```
| Métrique          | cold-email | linkedin-ads | seo | ... |
|-------------------|-----------|--------------|-----|-----|
| CAC               |           |              |     |     |
| ROAS              |           |              |     |     |
| Leads / RDV       |           |              |     |     |
| Statut (vs seuil) | CIBLE     | ORANGE       | …   |     |
```

---

## Niveau CANAL — `growth/channels/<canal>/` (5 fichiers IDENTIQUES par canal)

Chaque canal porte **exactement les 5 mêmes fichiers** (structure homogène = comparaison possible) :

| Fichier | Rôle | Propriétaire (écriture) |
|---|---|---|
| `ICP.md` | **Delta vs ICP maître** : ce qui change pour CE canal (niveau de maturité, message d'entrée, exclusions spécifiques). Référence l'ICP maître, ne le recopie pas. | channel-strategist (cadre) |
| `SEQUENCES.md` *(ou `CREATIVES.md`)* | Les séquences (cold-email, partenariats) ou créatives (ads) du canal, avec variantes A/B. **C'est ici, jamais à la racine.** | copywriter-sequences |
| `OFFRES.md` | **Delta vs catalogue** : les offres activées sur CE canal + leur angle local. | channel-strategist |
| `METRICS.md` | CAC/ROAS du canal + **seuils déclarés** : `CIBLE`, `ALERTE-rouge (kill)`, `ALERTE-orange (itérer)`. Renseigné par mesure. | campaign-analyst |
| `EXPERIMENTS.md` | Journal d'expériences **ICE/PXL** : hypothèse → variante → résultat → verdict GO/ITERATE/KILL. | campaign-analyst (verdict) |

> Le nom du fichier de production est **`SEQUENCES.md`** par défaut ; pour les canaux paid (ads), on
> emploie **`CREATIVES.md`**. Le `_TEMPLATE/` porte `SEQUENCES.md` ; on le renomme à la duplication
> pour un canal paid.

### En-têtes attendus (au scaffolding)

- `METRICS.md` d'un canal commence par un bloc **Seuils** :
  ```
  ## Seuils — canal:[<canal>]
  - CAC      : CIBLE [valeur] | ALERTE-orange [valeur] | ALERTE-rouge [valeur]
  - ROAS     : CIBLE [valeur] | ALERTE-orange [valeur] | ALERTE-rouge [valeur]
  ```
- `EXPERIMENTS.md` commence par un **index tableau** :
  ```
  | EXP-ID | Date | Hypothèse | Score ICE | Verdict |
  |--------|------|-----------|-----------|---------|
  ```

---

## Règle d'or de l'extension

- **Global = vérité maître ; canal = delta.** On ne recopie jamais l'ICP maître dans un canal ; on n'y
  écrit que ce qui diffère.
- **Tout livrable de canal vit dans son canal.** Aucune séquence/créative/métrique à la racine de `growth/`.
- **Ajout d'un canal = duplication de `_TEMPLATE/`** (kebab-case), pas de création manuelle.
- **Zéro contamination** : un apprentissage prouvé sur un canal n'est pas réputé valable ailleurs
  (cf. tag-canal des LEARNINGS dans `content/registres.md`).
