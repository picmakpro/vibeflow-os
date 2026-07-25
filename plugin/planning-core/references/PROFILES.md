# PROFILES — Les 3 niveaux de rigueur du socle planning

> Référence du skill `vf-planning`. Le profil se choisit selon la **logique métier** du lab et se
> **propose** à l'utilisateur (jamais imposé). On prend le minimum qui sert.

---

## Vue d'ensemble

| Artefact | Léger | Standard | Complet |
|---|:---:|:---:|:---:|
| `STATE.md` (clé de voûte) | ✅ | ✅ | ✅ |
| `PROJECT.md` | ✅ (court) | ✅ | ✅ |
| `ROADMAP.md` | ✅ (simple) | ✅ | ✅ |
| `config.json` | ✅ | ✅ | ✅ |
| `REQUIREMENTS.md` (IDs + traçabilité) | — | ✅ | ✅ |
| `MILESTONES.md` + `milestones/` | — | ✅ | ✅ |
| `phases/NN/PLAN.md` + `SUMMARY.md` | optionnel | ✅ | ✅ |
| `phases/NN/VERIFICATION.md` | — | optionnel | ✅ |
| Extension de domaine (`codebase/`, `editorial/`…) | — | optionnel | ✅ |
| Gates (Nyquist, Decision Coverage…) | — | — | ✅ (cf. module `software-architecture`) |
| Hook Stop « planning à jour » (`guard-planning-updated.sh`) | `warn` (advisory) | `block` | `block` |
| `INDEX.md` (lab à compartiments) | ⚑ selon topologie | ⚑ selon topologie | ⚑ selon topologie |
| `BOARD.md` (compartiment `continuous`) | ⚑ selon type | ⚑ selon type | ⚑ selon type |

> **Où vit le profil, qui le lit** : la source canonique est la clé `"profile"` de
> `.planning/config.json` (posée à l'init, miroir informatif dans le frontmatter de `STATE.md`).
> Les garde-fous machine la lisent directement — le hook Stop `guard-planning-updated.sh` passe en
> `warn` quand tous les `.planning/` du lab sont en profil `leger`, et reste en `block` sinon
> (config absente ou illisible → `block`, fallback sûr). `VF_PLANNING_STOP=block|warn|off` prime
> toujours (override manuel). La gouvernance est **proportionnée** : un lab solo/léger est averti,
> jamais bloqué (audit 2026-07-25).

> ⚑ **Axe orthogonal au profil : la topologie** (cf. `compartments.md`). `INDEX.md` apparaît dès que le
> lab a plusieurs compartiments (steering lab). `BOARD.md` remplace `ROADMAP.md`+`MILESTONES` pour un
> compartiment typé `continuous`. Le profil règle la *rigueur* ; la topologie règle *où vivent les plans*.

---

## Profil **Léger**

**Pour qui** : labs créatifs, exploratoires ou ponctuels — peu d'étapes, faible coût de
coordination. Ex. : un lab d'idéation, un petit projet design, une veille.

**Ce qu'il pose** : `STATE.md` + `PROJECT.md` (court) + `ROADMAP.md` (liste de jalons) + `config.json`.

**Esprit** : juste assez pour ne pas perdre le fil. Zéro cérémonie. On peut monter en rigueur plus
tard sans rien casser (les artefacts s'ajoutent).

## Profil **Standard**

**Pour qui** : la majorité des labs opérationnels — contenu, vente, ops, growth, montage de dossier.
Travail réellement découpé en étapes, avec des exigences et des livrables à tracer.

**Ce qu'il ajoute au léger** : `REQUIREMENTS.md` (exigences à IDs + matrice de traçabilité),
`MILESTONES.md` + `milestones/`, et l'arbo `phases/NN/` avec `PLAN.md` + `SUMMARY.md` par étape.

**Esprit** : traçabilité exigence → étape → livraison. L'extension de domaine est **optionnelle** et
prend la forme du métier.

## Profil **Complet**

**Pour qui** : dev et projets critiques — fort enjeu de qualité, architecture, vérification.

**Ce qu'il ajoute au standard** : extension de domaine systématique (`codebase/` pour le dev),
`VERIFICATION.md` de fin de phase, et l'activation des **gates** machine-enforced (Nyquist Layer,
Decision Coverage) — qui vivent dans le module `software-architecture` (rule `production-code-architecture`).

**Esprit** : rien ne passe sans être vérifié et tracé. Réservé aux contextes qui le justifient.

---

## Mapping métier → profil (proposition par défaut, ajustable)

| Métier détecté du lab | Profil proposé |
|---|---|
| Dev / code / produit technique | **Complet** |
| Contenu, éditorial, growth, vente, ops | **Standard** |
| Montage de dossier, conformité | **Standard** |
| Idéation, veille, design ponctuel, exploration | **Léger** |
| Indéterminé | **Léger** + une question de clarification |

> Le mapping est un **point de départ**, pas une règle dure. Le skill propose, l'utilisateur tranche.
> Un lab peut démarrer léger et passer en standard quand son volume de travail le justifie.
