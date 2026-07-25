# Phase 9 — Note go/no-go : transposition mémoire jcode → VibeFlow

**Date :** 2026-07-22
**Statut :** R&D — hors chaîne de release. Ne touche PAS le format mémoire officiel ni le socle `conductor`.
**Décide :** RND-01 (le geste fonctionne-t-il mécaniquement ?) + RND-02 (ADR ou archive ? + demi-vies recalibrées).
**Source primaire :** `.planning/research/jcode-memory-swarm-transposition-NOTE.md`.

---

## 1. Verdict — **GO** (écrire un ADR + toucher le format officiel)

Le critère binaire D-05 est **mécaniquement vrai sur les deux points**, sans édition humaine :

| Critère D-05 | Résultat | Preuve |
|---|---|---|
| Une passe `consolidator` **lit → recalcule → réécrit** les 3 champs (`trust`/`confidence`/`superseded_by`) sur **toutes** les entrées du lab témoin, sans édition humaine | ✅ | 5 entrées : 4 réécrites en place, 1 traitée par la voie supersession ; passe 2 **idempotente** (base `confidence` préservée, `effective_confidence` recalculée à l'identique, 0 archivage parasite) |
| Une entrée `superseded_by` est **archivée** (statut basculé, contenu conservé — pas supprimée) | ✅ | `projet-alpha-emplacement-obsolete.md` → `archive/`, `status: superseded`, corps intégralement conservé |

Évidence reproductible : `spike/run-output.txt` (rejouable via `seed-lab.py` + `decay-pass.py`).
Prototype : `spike/decay-pass.py` (passe isolée, **non** intégrée à `plugin/consolidator/`).

**Conclusion :** le geste a un coût de maintenance **nul côté humain** — la passe tient les 3 champs à jour
automatiquement et de façon idempotente. La crainte « les 5 champs pourrissent faute d'entretien automatique »
(risque §4 de la note) est **levée pour les 3 gestes minimaux**. → On peut écrire l'ADR et enrichir le format officiel.

### Portée du GO (ce que l'ADR doit couvrir, et pas plus)

Le GO porte **strictement** sur les 3 gestes prototypés. Restent hors périmètre (candidats ADR ultérieurs, pas
validés ici) : `reinforced[]` (breadcrumbs) et l'access-boost associé, arêtes typées `Contradicts`/`DerivedFrom`,
embeddings/RRF/sidecar (rejetés — pas de runtime Claude Code), pipeline par-tour (différé — pas de hook fiable).

---

## 2. Mapping catégories jcode → types VibeFlow (D-06, décision du spike)

Mapping **1:1** retenu — chaque catégorie jcode se projette proprement sur un type VibeFlow existant, et sa
demi-vie de nature s'y transpose sans distorsion :

| Catégorie jcode | Type VibeFlow | Justification du mapping |
|---|---|---|
| `Correction` | **`feedback`** | Guidance/corrections de l'utilisateur — la donnée la plus durable (le moat, LRN-060) |
| `Preference` | **`user`** | Qui est l'utilisateur, son rôle, ses préférences — évolue lentement |
| `Entity` | **`reference`** | Pointeurs vers systèmes externes (Linear, dashboards, outils) — bougent avec l'outillage |
| `Fact` | **`project`** | État/faits d'un projet (initiatives, deadlines) — périment vite |

`Custom` (jcode) → non transposé (pas de 5ᵉ type VibeFlow ; retomber sur `project` par défaut).

---

## 3. Demi-vies **recalibrées** pour VibeFlow multi-métiers (livrable D-04)

> **Mise à jour post-panel (2026-07-22)** : un panel adversarial de recalibration a corrigé `project`
> **45 → 30 j** (le rallongement inversait le sens pour de l'état volatil : deadlines/sprints/tendances
> périment en jours/semaines). Valeurs et raisonnement définitifs → **ADR-052** (`docs/ADR.md`), qui prime.
> Le tableau ci-dessous reflète la proposition initiale du spike (`project` à 45 j).

Les valeurs jcode sont calibrées pour un **harness de code** (« les faits de codebase périment vite »). VibeFlow
opère des **labs multi-métiers** (dev, iOS, marketing, contenu, business) : la cadence de péremption y est plus
lente pour tout ce qui n'est pas de l'état de code, et la capitalisation de feedback est la valeur cœur.

| Type VibeFlow | HL jcode brute | **HL VibeFlow recalibrée** | Raison de l'ajustement |
|---|---|---|---|
| `feedback` (Correction) | 365 j | **365 j** (inchangé) | Le feedback validé EST le moat VibeFlow (LRN-060) — durée maximale, on ne raccourcit pas |
| `user` (Preference) | 90 j | **180 j** | Le rôle/positionnement d'un freelance multi-projets est stable sur plusieurs mois, pas trimestriel |
| `reference` (Entity) | 60 j | **120 j** | Un pointeur vers un système externe reste valide tant que l'outillage ne change pas — plus lent que 60 j |
| `project` (Fact) | 30 j | **45 j** | L'état projet churne (garde une HL courte), mais les labs non-dev bougent plus lentement qu'une codebase |

Effet mesuré sur la fixture (age constant, `today=2026-07-22`) :

| Entrée | Type | age | eff. jcode | eff. **vibeflow** |
|---|---|---|---|---|
| commits-francais-scroll-off | feedback | 200 j | 0.6498 | 0.6498 |
| user-freelance-multi-metiers | user | 120 j | 0.3175 | **0.5040** |
| reference-rtk-proxy | reference | 90 j | 0.2475 | **0.4162** |
| projet-alpha-emplacement | project | 13 j | 0.6665 | **0.7367** |

→ La recalibration évite qu'une préférence utilisateur ou un pointeur de référence encore valides ne tombent
sous un seuil de rétrogradation trop tôt dans un lab non-dev à cadence lente.

**Formule minimale retenue** (sans access-boost — `reinforced[]`/`access_count` hors périmètre) :
`effective_confidence = confidence_base × 0.5 ^ (age_jours / demi_vie[type])`.
La composante `× (1 + 0,1·ln(access_count+1))` de jcode est **différée** avec `reinforced[]`.

---

## 4. Forme du frontmatter enrichi (proposition d'ADR, D-06)

Champs ajoutés au format `memory/*.md` existant (`name`/`description`/`metadata.type` + liens `[[slug]]`) :

```yaml
---
name: <slug>
description: "…"
metadata:
  node_type: memory
  type: user | feedback | project | reference
trust: high | medium | low        # NOUVEAU — qui affirme (high=dit / medium=observé / low=inféré)
confidence: 0.0–1.0               # NOUVEAU — base, posée à la création/renforcement
created: YYYY-MM-DD               # NOUVEAU — ancre de la décroissance par catégorie
status: active | superseded       # NOUVEAU — supersession non destructive
superseded_by: <slug>             # NOUVEAU — vide si active
effective_confidence: 0.0–1.0     # DÉRIVÉ — recalculé à chaque passe (non saisi à la main)
last_decay_pass: YYYY-MM-DD       # DÉRIVÉ — traçabilité de la dernière passe
---
```

**Choix de conception clés** (à verser dans l'ADR) :
- `confidence` reste la **base** (non lossy sur N passes) ; la décroissance vit dans `effective_confidence` **dérivé**.
  Alternative rejetée : écraser `confidence` à chaque passe → perte de la base, non idempotent.
- 5 champs saisis + 2 dérivés. Densité : frontmatter ≤ ~12 lignes/entrée → sous les seuils ADR-029.
- **Archivage = déplacement** vers `archive/` + `status: superseded` (aligne ADR-031 : jamais de destruction).

---

## 5. Où ça s'intègre (si l'ADR est accepté) — NON fait dans ce spike

- La décroissance devient une **règle du pilier Indexation** du skill `consolidator` (pas un nouveau composant) :
  une passe recalcule `effective_confidence` et **rétrograde/archive** au lieu de supprimer.
- Un **seuil de rétrogradation** (ex. `effective_confidence < 0.2` → flag « à revérifier », pas suppression) est à
  définir dans l'ADR — non prototypé ici (hors critère binaire).
- Le prototype `decay-pass.py` est un **artefact de spike jetable** : l'implémentation officielle réutiliserait les
  scripts existants du module (`reindex.sh`/`archive.sh`) plutôt que ce Python isolé.

---

## 6. Prochain pas (hors de cette phase)

Écrire l'ADR « frontmatter mémoire enrichi (trust/confidence/décroissance/supersession) » sous validation humaine
(ADR-031), reprenant : mapping §2, demi-vies recalibrées §3, frontmatter §4, seuil de rétrogradation §5. **Rien ne
touche `plugin/consolidator/` ni le format officiel avant cet ADR.**
