# Pilier 5 — Mémoire vivante (décroissance + supersession)

> Référence détaillée. Vue d'ensemble dans `SKILL.md`. Source : **ADR-052** (frontmatter mémoire
> enrichi, validé 2026-07-22, issu du spike Phase 9 + panel de recalibration).

## 1. Pourquoi une couche distincte

VibeFlow a **deux mémoires** de nature opposée :

| | Registres d'audit (piliers 1-4) | Mémoire vivante (pilier 5) |
|---|---|---|
| Fichiers | `DECISIONS.md`, `LEARNINGS.md`, `BLOCKERS.md`… (tables) | `knowledge/<slug>.md` (un fichier = un fait) |
| Nature | **trace historique permanente** | **savoir vivant, fiabilité évolutive** |
| Décroissance | ❌ non — une décision datée reste vraie | ✅ oui — un fait projet périme |
| Géré par | `reindex.sh` / `archive.sh` | `decay-pass.sh` |

Appliquer la décroissance à un ADR ou un learning n'a aucun sens (il ne devient pas « moins fiable »
avec l'âge). Le modèle jcode (trust / confidence / décroissance / supersession) est fait pour le savoir
vivant : qui est l'utilisateur, ses préférences, l'état d'un projet, des pointeurs. D'où une **couche
séparée**, au format frontmatter natif Claude Code, versionnée dans le lab.

## 2. Arborescence

```
.claude/memory/knowledge/
  MEMORY.md      # index humain : - [Titre](slug.md) — accroche
  <slug>.md      # une entrée = un fait (frontmatter + corps)
  archive/       # entrées superseded (conservées)
  .backups/      # backups isolés ADR-049 (gitignorés, rotation)
```

## 3. Le frontmatter

Champs **saisis** : `name`, `description`, `metadata.type`, `trust`, `confidence`, `created`, `status`,
`superseded_by`. Champs **dérivés** (recalculés par la passe, ne pas saisir) : `effective_confidence`,
`last_decay_pass`, `needs_review`. Format complet et exemple :
`templates/memory/knowledge-entry-template.md`.

- **`trust`** = qui affirme : `high` (dit par l'user) / `medium` (observé) / `low` (inféré). Normalisé
  à chaque passe (valeur invalide → `medium`).
- **`confidence`** = base 0..1 posée à la création/renforcement. **Jamais écrasée** par la passe (design
  non lossy — sinon la décroissance serait cumulative et non idempotente).

## 4. Décroissance

```
effective_confidence = confidence × 0.5 ^ (age_jours / demi_vie[type])
```

`age_jours = today − created`. Demi-vies (jours), **recalibrées multi-métiers** par le panel (ADR-052) :

| `type` | jcode brut | VibeFlow | Raison |
|---|---|---|---|
| `feedback` | 365 | **365** | Le feedback validé est le moat (LRN-060) — durée max, inchangé |
| `user` | 90 | **180** | Rôle/positionnement stable sur plusieurs mois, pas trimestriel |
| `reference` | 60 | **120** | Un pointeur externe vit tant que l'outillage ne change pas |
| `project` | 30 | **30** | État volatil (deadlines, sprints) — HL courte (le rallongement à 45 j du spike inversait le sens, corrigé au panel) |

Type inconnu → fallback `project` (30 j, le plus prudent). La composante access-boost de jcode
(`× (1 + 0,1·ln(access_count+1))`) est **différée** avec `reinforced[]` (hors périmètre ADR-052).

**Seuil de rétrogradation** : `effective_confidence < VF_DECAY_REVIEW_THRESHOLD` (défaut `0.2`) →
`needs_review: true`. C'est un **flag**, pas une suppression (ADR-031). Recalculé à chaque passe
(repasse au-dessus du seuil = flag retiré → idempotent).

## 5. Supersession non destructive

Une entrée portant `superseded_by: <slug>` **ou** `status: superseded` est **déplacée** vers `archive/`
(contenu intégralement conservé, `status: superseded`). Jamais de `rm` de contenu (ADR-031). L'index
`MEMORY.md` doit alors retirer la ligne de l'entrée archivée (geste humain ou re-génération).

## 6. Idempotence (garantie testée)

Une 2ᵉ passe à date égale : base `confidence` préservée, `effective_confidence` recalculée à l'identique,
`0` archivage parasite, frontmatter réécrit dans un **ordre canonique stable** (les clés hors canon sont
préservées). Vérifié par `scripts/tests/test-decay.sh` (round-trip + supersession + trailing-whitespace).

## 7. Invocation

```bash
decay-pass.sh --dry-run                  # JSON, ne touche à rien (défaut)
decay-pass.sh --apply                    # réécrit les actifs + archive les superseded
decay-pass.sh --apply --today=2026-07-22 # date figée (tests déterministes)
```

Variables : `KNOWLEDGE_DIR` (défaut `.claude/memory/knowledge`), `VF_DECAY_REVIEW_THRESHOLD` (0.2),
`VF_BACKUP_KEEP` (3). Si le dossier `knowledge/` n'existe pas → no-op silencieux (JSON `present:false`).

**Batch, pas par-tour** : Claude Code n'expose pas de hook par-tour fiable ; la passe tourne au
`/consolidate` (le pipeline search→verify→inject→maintain par-tour de jcode est explicitement différé).

## 8. Limites reconnues (ADR-052, hors périmètre — candidats ultérieurs)

- `reference` et `project` restent des **buckets à deux vitesses** (ticket éphémère vs infra permanente ;
  deadline volatile vs insight durable). Le tuning des demi-vies ne résout pas ça.
- Extensions différées : sous-type volatil court `signal` (~14-21 j) ; champ `expires_at` (couperet dur
  pour devis/certificats) ; épinglage `pin` de la master-data ; reset d'âge au ré-accès (`reinforced[]`).
- Rejetés (pas de runtime Claude Code) : embeddings, RRF, sidecar de verify.
