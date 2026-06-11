# REGISTRES — Mémoire canon du lab content + pont planning↔mémoire

> Définit les **5 registres mémoire canon** que `vf-new-lab` pose dans `.claude/memory/` du lab
> content, la **convention d'IDs**, **ce que chaque agent y capitalise**, et le **pont
> planning↔mémoire** à propriétaire unique.
>
> Source canonique des registres : module `reference` (`VIBEFLOW_CORE.md`, registres standards).
> Pont : `planning-core/bridge-memory.md`. Ce fichier **applique** ces sources au métier *content*,
> sans les redupliquer.

---

## 1. Les 5 registres canon

Posés dans `.claude/memory/` du lab. **Chacun commence par un index tableau** (P1 Capitaliser ;
convention `consolidator` : lecture = lecture de l'index par défaut).

| Registre | Fichier | Rôle | Nature |
|---|---|---|---|
| **DECISIONS** | `DECISIONS.md` | décisions structurantes et durables (angle de campagne, choix éditoriaux engageants) | append-only, indexé |
| **LEARNINGS** | `LEARNINGS.md` | patterns réutilisables (hooks/structures/formats qui performent) | append-only, indexé |
| **BLOCKERS** | `BLOCKERS.md` | obstacles > 30 min + hypothèses éliminées | append-only, indexé |
| **JOURNAL** | `JOURNAL.md` | trace chronologique des sessions (alimenté depuis `STATE.md`) | append-only, indexé |
| **EVALS** | `EVALS.md` | évaluation qualité des outputs (verdicts du gate de clarté, perf des pièces) | append-only, indexé |

### Format d'index (en tête de chaque registre)

```markdown
# DECISIONS — Lab content

| ID | Date | Titre | Statut | #Ligne |
|---|---|---|---|---|
| DEC-001 | 2026-06-11 | Condensation 6 rôles → 3 agents + gate clarté = couche audit | Validée | — |
```

> La colonne `#Ligne` pointe vers le corps détaillé (convention `consolidator`, pilier *Indexation*).

## 2. Convention d'IDs

| Préfixe | Registre | Exemple |
|---|---|---|
| `DEC-NNN` | DECISIONS | `DEC-001` |
| `LRN-NNN` | LEARNINGS | `LRN-001` |
| `BLK-NNN` | BLOCKERS | `BLK-001` |
| `EVAL-NNN` | EVALS | `EVAL-001` |
| `D-NN` | planning (`PROJECT.md`) | `D-1` (décision courante, peut être promue → `DEC-NNN`) |

Format dates : `YYYY-MM-DD`. Langue : français.

## 3. Ce que chaque agent capitalise

| Agent | DECISIONS | LEARNINGS | BLOCKERS | EVALS |
|---|---|---|---|---|
| **strategist** | décisions d'angle/structure structurantes | schémas d'angle qui marchent/échouent | cadrage bloqué (brief insuffisant, source indispo) | défaut d'angle remonté par le gate de clarté |
| **scriptwriter** | choix rédactionnel réutilisable (gabarit de hook adopté) | tournures/structures qui performent | rédaction bloquée (source manquante, cadrage incohérent) | résultat auto-contrôle + verdict gate de clarté reçu |
| **repurposer** | choix de distribution durable (abandon d'une plateforme) | **formats/plateformes qui performent** (cœur) | distribution bloquée (gabarit manquant, cadence intenable) | perf mesurée d'une déclinaison vs critères/objectif |

> Le **gate de clarté** (`audit-architecture`) produit des **verdicts bloquants** ; chaque verdict
> (passé/échoué + cause) est capitalisé en **EVALS** (`EVAL-NNN`) — c'est la matérialisation de P8
> au niveau du process générateur brief→output.

## 4. Pont planning ↔ mémoire (un seul propriétaire)

Règle d'or (`bridge-memory.md`) : **une info ne vit qu'à UN endroit**. Les ponts sont des **flux**,
jamais des copies.

| Pont | De (`.planning/`) | Vers (`.claude/memory/`) | Quand |
|---|---|---|---|
| **Décisions** | `PROJECT.md` table Key Decisions (`D-NN`) | `DECISIONS` (`DEC-NNN`) | quand une décision devient structurante/durable → **promue** (outillée par `consolidator`, pilier *Promotion*). Le `D-NN` garde un pointeur « → DEC-NNN ». |
| **Avancement** | `STATE.md` (focus, décisions de session) | `JOURNAL` | à la clôture de session : l'historique long part en JOURNAL ; `STATE.md` ne garde que le courant. |
| **Jalons** | `MILESTONES.md` | archivage `milestones/` | à la clôture d'une campagne (critères statut/âge/refs du `consolidator`). |
| **Apprentissages** | `phases/NN/SUMMARY.md` | `LEARNINGS` | quand un SUMMARY révèle un pattern réutilisable → capitalisé. |

### Anti-doublons (interdits)
- ❌ Recopier une `DECISION` dans `PROJECT.md` (ou l'inverse) — seul le pointeur `D-NN → DEC-NNN`.
- ❌ Tenir un historique long dans `STATE.md` (c'est le rôle du JOURNAL).
- ❌ Dupliquer un blocage : *en cours* = todo dans `STATE.md` ; *capitalisé* = `BLOCKERS`. Jamais les
  deux avec le même contenu.

### Si le lab n'a pas encore tous les registres
Le socle `.planning/` fonctionne seul ; le pont est **dormant** (les décisions restent en
`PROJECT.md`). Il s'active quand `reference`/`consolidator` sont installés. **Aucune dépendance dure.**

## 5. Décision fondatrice à inscrire à l'instanciation

`vf-new-lab` inscrit en `DECISIONS` (`DEC-001`) la décision de design du bundle :

> **DEC-001 — Condensation 6 rôles éditoriaux → 3 agents + gate de clarté matérialisé comme couche
> `audit-architecture` (pas un agent).** Justification : densité (ADR-029, agents ≤250L, une
> responsabilité par agent) ; le contrôle de clarté est une **évaluation** (P8) — donc une couche
> d'audit à verdict bloquant, pas un acteur. Statut : Validée.
