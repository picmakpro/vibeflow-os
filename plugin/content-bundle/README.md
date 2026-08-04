# content-bundle — L'équipe content de VibeFlow (ContentFlow)

> Produire du contenu en série — posts, newsletters, threads, déclinaisons — **sans slop, sans
> chiffre inventé et sans jamais publier tout seul** : ce module installe le studio éditorial
> complet qui tient cette promesse.

**Type** : `agents + skill + scripts` · **Version** : v2.0.4 · **Dépend de** : `conductor`,
`planning-core`, `consolidator`, `audit-architecture`, `validator`.

---

## Quoi

Le métier couvert est la chaîne éditoriale **brief → cadrage → rédaction → gate de clarté →
validation humaine → déclinaison/distribution**. Le module livre une **équipe complète sur le
team-kernel** du `conductor` (manager → workers → juge) — **première équipe métier non-dev**
matérialisée sur le kernel (v2.0.0, 2026-07-25), le modèle de référence dont business-pilot et
growth sont les transpositions : la preuve d'universalité du framework.

```
BRIEF ─▶ vf-content-strategist ─▶ vf-content-writer ─▶ content-clarity-judge (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ vf-content-repurposer ─▶ l'humain publie
```

**« Vert », pour ce métier** : une pièce n'est verte que si l'auto-contrôle du writer passe
(4 critères), que le juge `content-clarity-judge` la score ≥ 80/100 sans critère éliminatoire
(un chiffre non sourcé est **éliminatoire**), et que **l'humain l'a validée explicitement**. La
distribution est TOUJOURS human-gated (ADR-031) : en mode autonome, la mission s'arrête à
« prêt pour validation » — le « human-validator » n'est pas un agent, c'est l'humain, orchestré
par le manager (statut `human_needed`). Le repurposer ne décline qu'une pièce **verte** (refus
sinon), et ne publie jamais.

## Installation

```bash
bash plugin/_internal/vibeflow-update.sh --scope project install --with-deps content-bundle
```

`--with-deps` tire la fermeture transitive des `requires` dans l'ordre : `conductor` (socle
mandatory — il héberge le team-kernel et ses scripts `dag.sh`, `driver-lock.sh`,
`check-agents.sh`), `planning-core` (socle `.planning/` + extension `editorial/`), `consolidator`
(registres, promotion de décisions), `audit-architecture` (audit du process générateur, P8),
`validator` (filet de conformité). Alternative interactive : `/vibeflow-install` → cocher
« content-bundle ».

## Démarrer

Le lab type : un **créateur ou une marque qui tient une ligne éditoriale** (LinkedIn, newsletter,
blog) et veut produire à cadence régulière sans y laisser sa voix. À la création via
`/vf-new-lab` (métier content), le bundle est **proposé au catalogue** (`proposable: true`) et
le référentiel `editorial/` est posé d'office. Sur un lab existant, le skill a un **garde
first-use** : si `.planning/editorial/LIGNE-EDITORIALE.md` est absent, il propose de poser le
socle d'abord (`vf-planning`, profil standard + extension `editorial/`) — mode dégradé possible,
signalé.

Première mission à lui confier :

```
« Écris un post sur [sujet] pour [audience] »
```

Ce qu'on obtient : une fiche de cadrage (un angle unique justifié contre `AUDIENCE.md` et
`LIGNE-EDITORIALE.md`), un livrable avec 3 hooks au choix dans `pieces/<date>-<slug>/`, le
verdict du juge (/100, findings cités), puis la main — c'est toi qui valides et publies.

## Usage

Le point d'entrée est le skill `vf-content`, qui aiguille **geste simple** (chaîne courte
cadrage → rédaction → juge → validation humaine) ou **mission** (≥ 3 pièces ou signal de durée —
« la semaine », « en autonomie » → `vf-content-manager` prend le pilotage : DAG à 5 nœuds par
pièce, verrou de driver, dispatch parallèle des pièces indépendantes — un dossier
`pieces/<slug>/` par pièce —, rapport de mission avec file d'attente de validation).

| Formulation | Ce qui se passe |
|---|---|
| « écris un post », « rédige la newsletter », « fais-moi un thread sur… » | chaîne courte complète : cadrage → rédaction → juge → validation |
| « cadre l'angle de… » | `vf-content-strategist` seul — fiche de cadrage, arrêt à cet étage |
| « décline cet article », « adapte cette pièce pour LinkedIn » | `vf-content-repurposer` — sur pièce verte uniquement ; une pièce externe passe d'abord le juge + la validation |
| « prépare le calendrier de la semaine » | `vf-content-repurposer` en mode calendrier (cadence, pas de variante) |
| « produis les pièces de la semaine », « lance la prod en autonomie » | mission — `vf-content-manager` |

Frontières : la copy marketing de page web (landing, pricing) n'est pas ce module → skills
copywriting dédiés ; poser/structurer le planning du lab → `vf-planning`.

## Référence

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `agents/vf-content-manager.md` | manager de mission : DAG + verrou de driver (5 nœuds par pièce : cadrage → rédaction → clarté → humain → déclinaison), dispatch parallèle, digest ≤ 30 lignes par mandat, contrôle de flux sur rapports typés, halt conditions | opus | exposé — **ne produit jamais** (aucune écriture de contenu) |
| `agents/vf-content-strategist.md` | fiche de cadrage : un angle unique justifié contre `AUDIENCE.md` et `LIGNE-EDITORIALE.md`, structure hook▸contexte▸mécanisme▸implication▸CTA, format | sonnet | `vf-internal`, écrit uniquement `pieces/<slug>/cadrage.md` |
| `agents/vf-content-writer.md` | 3 hooks + livrable complet, zéro chiffre non sourcé, auto-contrôle 4 critères | sonnet | `vf-internal`, écrit uniquement `pieces/<slug>/piece.md` |
| `agents/content-clarity-judge.md` | **gate de clarté** : juge frais, rubric /100 (chiffres sourcés 25 — éliminatoire —, jargon 15, take-away 15, ton 15, CTA unique 10, fidélité au cadrage 10, gabarit 10), seuil 80, verdict typé | sonnet | `vf-internal`, **read-only** (`Read, Glob, Grep` — sans Write/Edit) |
| `agents/vf-content-repurposer.md` | déclinaisons multi-plateformes d'une pièce **verte** uniquement, un CTA par variante, tient `editorial/CALENDRIER.md` | sonnet | `vf-internal`, écrit uniquement `variantes.md` + `CALENDRIER.md` |
| `skills/vf-content/SKILL.md` | point d'entrée métier : garde first-use, aiguillage geste simple vs mission (`SEUIL_EQUIPE_CONTENT = 3`), validation humaine en invariant | — | — |
| `scripts/tests/test-content-bundle.sh` | suite machine — **12 tests** : juge sans Write/Edit, manager sans production, Pattern 12, rapports typés + DIGEST, non-contournabilité de la validation humaine (manager + repurposer + skill), rubric du juge | — | — |
| `content/` | **trace de conception** (lisible par `vf-new-lab`) : `BUNDLE.md` (manifeste d'origine), `agents/*.blueprint.md` (3 blueprints), `domain/extension-spec.md` (structure exacte de `editorial/`), `registres.md` (5 registres canon + pont planning↔mémoire) | — | — |

Pas de `rules/` ni `references/` propres : le châssis doctrinal (verrou de driver, DAG, rapports
typés, digest, halt conditions, cloisonnement par tools) vit dans
`conductor/references/team-kernel.md` — référencé, jamais redupliqué. Densité ADR-029, agents
natifs ADR-044, validation humaine ADR-031. Vocabulaire métier (P7) : campagne · pièce · angle ·
pilier · cadence.

Vérification machine :

```bash
bash plugin/content-bundle/scripts/tests/test-content-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/content-bundle/agents
```

## Limites

- **Le lab ne publie jamais** : pas de post LinkedIn, d'envoi de newsletter ni de mise en ligne —
  il prépare des pièces « prêtes pour validation », la publication effective reste ton geste.
- **Pas de collecte de données externes** : pas de scraping de tendances ni d'analytics — les
  sources entrent par le brief et le référentiel `editorial/` (chiffre non sourcé = éliminatoire).
- **Pas la copy marketing** : landing pages, pricing, CTA de site → skills copywriting dédiés,
  hors périmètre de la chaîne éditoriale.
- **Le kernel est fait pour les missions** : sous le seuil (< 3 pièces, pas de signal de durée),
  la chaîne courte du skill suffit — pas de manager.
- **Référentiel requis** : sans `editorial/` posé, le module tourne en mode dégradé signalé —
  la valeur pleine (angle justifié contre l'audience, cadence tenue) suppose le socle
  `vf-planning`.
