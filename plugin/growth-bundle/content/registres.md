# Registres mémoire — lab GrowthFlow

> Spécification des 5 registres canon posés par `vf-new-lab` (étape 5 du flux d'instanciation), de la
> convention d'IDs, de ce que chaque agent y capitalise, et du **pont planning↔mémoire** (propriétaire
> unique). Templates canoniques : module `reference` / `consolidator`.
>
> **Référence Core** : P1 Capitaliser (aucune connaissance perdue). Indexation/archivage/fusion/promotion
> outillés par le module `consolidator`.

---

## 1. Les 5 registres canon

Tous vivent dans `.claude/memory/` du lab. **Chaque registre commence par un index tableau** (lu en
premier — Iron Law consolidator : « lecture d'un registre = lecture de l'index par défaut »).

| Registre | Fichier | Rôle | Nature |
|---|---|---|---|
| **DECISIONS** | `.claude/memory/DECISIONS.md` | Décisions structurantes & durables (allocation/kill de canal érigés en doctrine, conventions de mesure). | append-only, indexé |
| **LEARNINGS** | `.claude/memory/LEARNINGS.md` | Apprentissages réutilisables **PAR CANAL** (tag-canal obligatoire). | append-only, indexé |
| **BLOCKERS** | `.claude/memory/BLOCKERS.md` | Obstacles > 30 min + hypothèses éliminées. | append-only, indexé |
| **JOURNAL** | `.claude/memory/JOURNAL.md` | Trace chronologique des sessions (alimenté par `STATE.md` à la clôture). | append-only, indexé |
| **EVALS** | `.claude/memory/EVALS.md` | Évaluation de la qualité cognitive des outputs (fiabilité d'une mesure, qualité d'un arbitrage, slop évité). | append-only, indexé |

### En-tête d'index (chaque registre démarre ainsi)

```
| ID | Date | Titre | Tag-canal | #Ligne |
|----|------|-------|-----------|--------|
```

> `Tag-canal` est **obligatoire dans LEARNINGS** ; pour les autres registres il vaut `global` quand la
> décision/le blocage n'est pas spécifique à un canal. `#Ligne` est tenu par le pilier *Indexation* du
> `consolidator`.

## 2. Convention d'IDs

| Préfixe | Registre | Exemple |
|---|---|---|
| `DEC-NN` | DECISIONS | `DEC-007 — Kill du canal seo (ROAS < ALERTE-rouge 3 mois)` |
| `LRN-NN` | LEARNINGS | `LRN-012 [canal:cold-email] — accroche question > accroche bénéfice` |
| `BLK-NN` | BLOCKERS | `BLK-003 — source Mixpanel non câblée (MCP)` |
| `JNL-NN` | JOURNAL | `JNL-021 — session arbitrage canaux 2026-06-11` |
| `EVAL-NN` | EVALS | `EVAL-005 — fiabilité mesure linkedin-ads (30% inconnue)` |

- IDs **séquentiels, jamais réutilisés** (append-only).
- Dates **YYYY-MM-DD**. Tout en **français**, nommage **kebab-case** pour les canaux.
- **Tag-canal** : `[canal:<nom>]` ou `[canal:global]`. Format imposé, contrôlé au /vf-audit.

## 3. Ce que chaque agent capitalise

| Agent | DECISIONS | LEARNINGS | BLOCKERS | EVALS |
|---|---|---|---|---|
| **channel-strategist** | ★ allocations / activations / kills de canal (cœur de son rôle) | patterns d'arbitrage (tag-canal) | blocage d'arbitrage (données manquantes) | qualité d'une décision a posteriori |
| **copywriter-sequences** | rare (règle de marque durable) | patterns de copy gagnants (**tag-canal obligatoire**) | ICP local/offre introuvable | slop évité ? ancrage réel ? |
| **campaign-analyst** | conventions de mesure (fenêtre d'attribution…) | insights quantifiés (**tag-canal obligatoire**) | source MCP indisponible, données contradictoires | fiabilité mesure/verdict (part « inconnue ») |

> **Zéro contamination** : un LEARNING porte toujours SON canal. Un copy gagnant sur `cold-email`
> n'est pas réputé gagnant sur `linkedin-ads` tant qu'il n'a pas été prouvé sur ce canal.

## 4. Pont planning ↔ mémoire (propriétaire unique)

Une information ne vit qu'à **un** endroit. Les ponts sont des **flux**, pas des copies (cf.
`planning-core` → `bridge-memory.md`).

| Pont | De (`.planning/`) | Vers (`.claude/memory/`) | Règle |
|---|---|---|---|
| **Décisions** | `PROJECT.md` table Key Decisions (`D-NN`) | `DECISIONS.md` (`DEC-NN`) | Une décision growth **courante** (ex. « on teste linkedin-ads ce mois ») reste `D-NN` dans `PROJECT.md`. Quand elle devient **structurante/durable** (ex. « on tue tout canal sous ALERTE-rouge 3 mois »), elle est **promue** en `DEC-NN` ; `PROJECT.md` garde le `D-NN` avec pointeur `→ DEC-NN`. Promotion outillée par le pilier *Promotion* du `consolidator`. |
| **Avancement** | `STATE.md` (Contexte accumulé) | `JOURNAL.md` | À la clôture de session, l'historique long part au JOURNAL. `STATE.md` ne garde que le **courant**. |
| **Jalons** | `MILESTONES.md` / `milestones/` | Archivage `consolidator` | Snapshot de campagne archivé à la clôture du jalon. |
| **Apprentissages** | `SUMMARY.md` de phase | `LEARNINGS.md` | Un pattern révélé dans un SUMMARY est promu en LEARNING (avec tag-canal), pas laissé dormant. |

### Anti-doublons (interdits)

- ❌ Recopier une DEC dans `PROJECT.md` (ou l'inverse) — seul le pointeur `D-NN → DEC-NN` est permis.
- ❌ Tenir un historique long dans `STATE.md` (c'est le JOURNAL).
- ❌ Dupliquer un blocage : un blocage **en cours** se note dans les todos de `STATE.md` ; un blocage
  **capitalisé** va en `BLOCKERS.md` — jamais les deux avec le même contenu.

## 5. Si le lab démarre sans `consolidator`

Le socle `.planning/` fonctionne seul ; les registres peuvent être posés depuis `reference`. Le pont
est alors **dormant** (les décisions restent dans `PROJECT.md`). Dès que `consolidator` est installé
(il l'est dans ce bundle — `requires`), les flux d'indexation/archivage/fusion/promotion s'activent.
