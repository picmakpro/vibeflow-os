# BRIDGE — `.planning/` (forward) ↔ `.claude/memory/` (capitalisation)

> Référence du skill `vf-planning`. Définit comment la couche planning et les registres mémoire
> cohabitent **sans se dupliquer ni se cannibaliser**.

---

## Deux axes complémentaires

| | `.planning/` | `.claude/memory/` |
|---|---|---|
| **Regarde** | l'avant + le présent | le passé (capitalisation) |
| **Question** | « où va-t-on, où en est-on ? » | « qu'a-t-on décidé/appris/bloqué ? » |
| **Nature** | vivant, réécrit en continu | figé, append-only, indexé |
| **Exemples** | STATE, ROADMAP, PROJECT, phases | DECISIONS, LEARNINGS, BLOCKERS, JOURNAL, EVALS |
| **Durée de vie** | le projet en cours | transverse, cross-projet |

Ce ne sont **pas** deux copies du même contenu : ce sont deux fonctions différentes.

## Règle d'or : un seul propriétaire par information

Une info ne doit vivre qu'à **un** endroit. Les ponts ci-dessous sont des **flux**, pas des copies.

### Pont 1 — Décisions : `PROJECT.md` → DECISIONS

`PROJECT.md` porte une table **Key Decisions** (D1, D2…) = décisions *courantes du projet*, avec
rationale et statut. Quand une décision devient **structurante et durable** (elle dépasse le projet,
elle engage l'archi ou la méthodo), elle est **promue** en DECISIONS dans la mémoire.

- Dans `.planning/` : on garde le `D-NN` avec un pointeur (« → DEC-0xx »).
- Dans la mémoire : l'entrée DEC porte le détail canonique.
- Le module `consolidator` (pilier *Promotion*) outille cette remontée si présent.

### Pont 2 — Avancement : `STATE.md` → JOURNAL

L'`Accumulated Context` de `STATE.md` (décisions de la session, focus) alimente le **JOURNAL /
ITERATION_LOG** à la clôture de session. `STATE.md` ne garde que le **courant** ; l'historique long
part en JOURNAL.

### Pont 3 — Jalons : `MILESTONES.md` ↔ Archivage

À la clôture d'un jalon, son snapshot va dans `milestones/`. Cet archivage s'articule avec le pilier
*Archivage* du `consolidator` (mêmes critères statut/âge/refs) si le module est installé.

### Pont 4 — Apprentissages : `SUMMARY.md` → LEARNINGS

Un `SUMMARY.md` d'étape peut révéler un **pattern réutilisable** → il est capitalisé en LEARNINGS
(mémoire), pas laissé dormant dans la trace de phase.

## Anti-doublons (à ne jamais faire)

- ❌ Recopier les entrées DECISIONS dans `PROJECT.md` (ou l'inverse).
- ❌ Tenir un historique long dans `STATE.md` (c'est le rôle du JOURNAL).
- ❌ Dupliquer un BLOCKER dans `.planning/` : un blocage *en cours* se note dans `STATE.md` (todos),
  un blocage *capitalisé* va en BLOCKERS — pas les deux avec le même contenu.

## Labs à compartiments

Les 4 ponts s'appliquent **à l'identique au niveau compartiment** : le `STATE.md`/`BOARD.md` d'un
compartiment alimente le JOURNAL du lab à la clôture ; ses décisions structurantes remontent en
DECISIONS. Le plan d'un compartiment **référence** une décision (`→ DEC-XXX`), il ne la recopie jamais.
Le terrain montre souvent le problème **inverse** de la cannibalisation : faute de plan, l'état courant
squatte le JOURNAL et les statuts « À FAIRE » squattent le registre de décisions. Poser un plan fin
**désengorge** la mémoire. Détail : `compartments.md` § 4. Test : *« faux demain → plan ; survit à la
livraison → mémoire ».*

## Si le lab n'a pas (encore) de registres mémoire

Le socle `.planning/` fonctionne **seul**. Le pont est alors dormant : les décisions restent dans
`PROJECT.md`. Quand le lab adopte les registres (`reference`/`consolidator`), on active les flux
ci-dessus. **Aucune dépendance dure** — `planning-core` n'exige aucun autre module.
