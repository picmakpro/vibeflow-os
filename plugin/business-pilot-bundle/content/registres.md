# REGISTRES MÉMOIRE — lab `business-pilot`

> Spécification des **5 registres mémoire canon** posés dans `.claude/memory/` du lab à
> l'instanciation, de la **convention d'IDs**, de **ce que chaque agent y capitalise**, et du
> **pont planning↔mémoire**.
>
> **Convention canon — PAS de BDR custom.** On utilise les 5 registres standards de VibeFlow_CORE.
> Le vocabulaire métier est transposé (P7) dans `.planning/`, **pas** dans la convention de mémoire.

---

## 1. Les 5 registres canon

Chaque registre **commence par un index tableau** (lecture de l'index par défaut — pilier *Indexation*
du `consolidator`). Le détail (« body ») suit l'index.

| Registre | Fichier | Répond à | ID |
|---|---|---|---|
| **DECISIONS** | `.claude/memory/DECISIONS.md` | Qu'a-t-on **décidé** de structurant, et pourquoi ? | `DEC-XXX` |
| **LEARNINGS** | `.claude/memory/LEARNINGS.md` | Qu'a-t-on **appris** de réutilisable ? | `LRN-XXX` |
| **BLOCKERS** | `.claude/memory/BLOCKERS.md` | Qu'est-ce qui **bloque** durablement, hypothèses éliminées ? | `BLK-XXX` |
| **JOURNAL** | `.claude/memory/JOURNAL.md` | Que s'est-il passé, **session par session** ? | `JNL-XXX` *(ou date)* |
| **EVALS** | `.claude/memory/EVALS.md` | La décision **quantitative/cognitive** était-elle la bonne (P8) ? | `EVAL-XXX` |

### Forme de l'index (tableau en tête de chaque registre)

```markdown
## Index

| ID | Date | Résumé (1 ligne) | #Ligne |
|----|------|------------------|--------|
| DEC-001 | 2026-06-11 | Politique de remise plafonnée à 15 % | 24 |
```

> La colonne `#Ligne` pointe vers le body. **Lire = lire l'index par défaut**, ouvrir le body
> seulement quand nécessaire (Iron Law du `consolidator`).

## 2. Convention d'IDs

- Format : `PREFIXE-NNN` à 3 chiffres, incrémental, **jamais réutilisé**.
- Préfixes : `DEC` (décisions), `LRN` (learnings), `BLK` (blockers), `EVAL` (evals), `JNL` (journal).
- Dans `.planning/` les décisions courantes portent un ID **`D-NN`** (table *Key Decisions* de
  `PROJECT.md`) — distinct des `DEC-XXX` de la mémoire (voir pont §4).
- Les opportunités du pipeline portent `CLI-XXX` (extension de domaine, pas un registre mémoire).

## 3. Ce que chaque agent capitalise

| Registre | commercial | delivery | finance |
|---|---|---|---|
| **DECISIONS** (DEC) | Décisions tarifaires structurantes (grille, politique de remise). | Changements structurants de process de delivery. | Politique de marge, termes de paiement standard. |
| **LEARNINGS** (LRN) | Patterns de vente (objections, ce qui close/perd). | Patterns de delivery (drivers de NPS, frictions récurrentes). | Patterns de rentabilité (offres marginales, signaux d'impayé). |
| **BLOCKERS** (BLK) | Blocages commerciaux (canal qui ne convertit pas, ICP mal ciblé). | Blocages de delivery (SLA intenable, churn récurrent). | Blocages financiers (client déficitaire, tension de cash). |
| **EVALS** (EVAL) | *(occasionnel)* projection de conversion posée en prédiction. | *(rare)* | **Systématique** : pricing arbitré, prévisions, seuils (P8) + ré-éval J+30/J+60/J+90. |
| **JOURNAL** (JNL) | Alimenté par `STATE.md` à la clôture de session (pont §4) — pas écrit à la main par les agents en cours de travail. | | |

> **Propriétaire EVALS = finance** au premier chef (décisions quantitatives). Les autres n'y écrivent
> que s'ils posent une **prédiction chiffrée**.

## 4. Pont planning↔mémoire (un seul propriétaire par information)

Une information vit à **un seul** endroit. Les ponts sont des **flux**, pas des copies
(réf. `planning-core/references/bridge-memory.md`).

### Pont 1 — Décisions : `PROJECT.md` (D-NN) → `DECISIONS` (DEC-XXX)

- Les décisions **courantes** du business vivent dans la table *Key Decisions* de
  `.planning/PROJECT.md` (`D-1`, `D-2`…).
- Quand une décision devient **structurante et durable** (engage la stratégie, le pricing, le
  process), elle est **promue** en `DEC-XXX` dans `DECISIONS.md` (pilier *Promotion* du `consolidator`).
- Dans `PROJECT.md` on garde le `D-NN` avec un pointeur (« → DEC-0xx ») ; le **détail canonique** est
  dans la mémoire. **Jamais les deux en double.**

### Pont 2 — Avancement : `STATE.md` → `JOURNAL`

- `STATE.md` (clé de voûte) ne garde que le **courant** (position du business, focus, todos).
- À la **clôture de session**, le contexte accumulé part en `JOURNAL.md`. L'historique long n'encombre
  pas `STATE.md`.

### Pont 3 — Jalons : `MILESTONES.md` ↔ archivage

- À la clôture d'un jalon métier (Rollout livré), son snapshot va dans `.planning/milestones/` ;
  s'articule avec le pilier *Archivage* du `consolidator` (critères statut/âge/refs).

### Pont 4 — Apprentissages : `SUMMARY.md` → `LEARNINGS`

- Un `SUMMARY.md` d'étape (phase) qui révèle un **pattern réutilisable** est capitalisé en `LRN-XXX`,
  pas laissé dormant dans la trace de phase.

### Anti-doublons (interdits)

- ❌ Recopier un `DEC-XXX` dans `PROJECT.md` (ou l'inverse).
- ❌ Tenir un historique long dans `STATE.md` (rôle du `JOURNAL`).
- ❌ Dupliquer un blocage : *en cours* → `STATE.md`/dossier d'opportunité ; *capitalisé* → `BLOCKERS` —
  jamais les deux avec le même contenu.

## 5. Articulation avec les modules

- **`consolidator`** outille la tenue des 5 registres (index strict, archivage, fusion de doublons,
  promotion D-NN → DEC).
- **`audit-architecture`** (P8) pose le **verdict bloquant** sur les générateurs brief→output
  (pricing, propositions, prévisions) — son verdict peut alimenter un `EVAL-XXX`.
- **`vibeflow-validator`** audite la **cohérence** des registres (index présent, IDs non dupliqués,
  conventions respectées) et **escalade au `conductor`** toute dérive.
