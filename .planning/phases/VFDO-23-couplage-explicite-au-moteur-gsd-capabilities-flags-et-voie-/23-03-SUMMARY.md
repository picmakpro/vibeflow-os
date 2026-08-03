---
phase: 23-couplage-explicite-au-moteur-gsd
plan: 03
type: execute
status: exécuté — revue en vol (`23-03-REVIEW.md` non rendu à l'écriture de ce SUMMARY)
requirements: [GSDC-03]
commits:
  - 2f830ab feat(23) §9 doctrine de flags de cycle en allowlist stricte, et D-21 sur le cycle canonique (tâches 1 et 2)
files_modified:
  - plugin/dev-orchestrator/references/GSD-PIPELINE.md
  - plugin/dev-orchestrator/agents/vf-coder.md
  - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
---

# 23-03 — Lacune 3 fermée : les flags de cycle passent en allowlist stricte

## Le fait central : le défaut change de sens

| | Avant `2f830ab` | Après |
|---|---|---|
| Flags de cycle documentés | **aucun** — un seul flag employé dans tout le module, rien d'écrit | `GSD-PIPELINE.md` **§9**, allowlist nommée brique par brique |
| Statut d'un flag non nommé | indéterminé — décidé par omission au moment de l'appel | **fermé par défaut**, y compris ceux que `gsd-core` ajoutera demain |
| Ligne `gsd-ship` du cycle canonique | déclarée sans dire qu'elle n'est pas empruntée | dit **pourquoi** (ADR-059, ADR-064) et **où** vit le protocole |

La clause de fermeture par défaut est posée **AVANT** la table (D-08). C'est le seul ordre qui vaut :
une liste d'interdits seuls périmerait à la première montée de version de `gsd-core` et laisserait
gagner l'omission — exactement le pilotage que cette doctrine referme.

## Ce qui a été livré, mesuré

| Fichier | Avant | Après | Détail |
|---|---|---|---|
| `references/GSD-PIPELINE.md` | 140 L | **183 L** | +44 / −1 (`git diff --numstat`) |
| `agents/vf-coder.md` | 98 L | **100/250 L** | ADR-029 tenu ; +3 / −1 |
| `scripts/tests/test-dev-orchestrator.sh` | 3828 L | 4235 L | bloc **T33**, **+407 / −0** |

Ventilation de l'écriture dans `GSD-PIPELINE.md` : **§9 = 34 lignes ajoutées** (budget du plan :
≤ 60), note D-21 sous la table §1 = **6 lignes**, puce §6 = **3 lignes**.

> **Précision de mesure, à ne pas confondre.** Les 34 lignes sont le **bloc ajouté** — séparateur
> `---` et lignes vides de raccord compris. La §9 *proprement dite*, du titre `## 9.` à la fin de
> fichier, fait **31 lignes** (l. 153-183). Les deux comptes sont sous le budget ; c'est le premier
> que le plan borne (« lignes **ajoutées** »).

## La table d'allowlist retenue

Clause de fermeture par défaut **d'abord**, table ensuite :

| Brique de cycle | Flags autorisés | Flags fermés |
|---|---|---|
| Cadrage — `gsd-discuss-phase` | `--auto` | `--chain`, et tout autre |
| Plan — `gsd-plan-phase` | `--research`, `--skip-research` | `--auto`, `--chain`, et tout autre |
| Exécution — `gsd-execute-phase` | *(aucun)* | `--auto`, `--chain`, et tout autre |

Les motifs vivent **dans la table**, en clair, et sont reproduits ici en abrégé — la version qui
fait autorité est la §9 elle-même :

- **Cadrage** — autorisation écrite **transitoire et datée**, dans sa **propre cellule de motif**
  (A-1ter). Fait amont : sur cette brique, `--auto` ne pose pas un état, il déclenche le pipeline
  entier — cadrage → plan → exécution **dans le même appel** (`chain.md:45-61`, étape 5). La
  **règle 5** de `checkpoints.md:11` joue donc sur tout l'aval. Portée **bornée** par la **règle 6**
  (`checkpoints.md:12`) : les gates `blocking-human` ne sont jamais auto-approuvés. Reste ouvert
  parce que `vf-coder` n'a pas `AskUserQuestion` (impasse chiffrée en `23-ARBITRAGES-OUVERTS.md`
  §O-8, voie 2) ; **périme au plan 23-05**. `--chain` fermé pour le même fait, aggravé — il ouvre le
  mode interactif, que `vf-coder` ne peut pas tenir.
- **Plan** — la gradation de la recherche se décide **ici, et nulle part ailleurs** (voir l'écart
  ci-dessous). En l'absence des deux flags, `plan-phase.md` §5.1 **prompte**, et `vf-coder`, privé
  d'`AskUserQuestion`, y reste bloqué : le flag n'est jamais omis.
- **Exécution** — aucun flag. Même fait qu'au cadrage, plus le pipelining de `mission-flow.md` : le
  manager tient le DAG, l'exécution ne le déborde pas.

**Ce qui n'est PAS dans les motifs, et c'est délibéré** : aucun motif n'est adossé à `T25`/`T25b`
(dégazés le 2026-08-03 — ils ne certifient plus qu'une adjacence textuelle), et aucun n'est fondé
sur la persistance de l'état. Vérifié : la §9 livrée ne contient **aucune** occurrence de `T25`.

S'ajoutent, sous la table : la gradation de la recherche sur **critère factuel** (D-05, ADR-055 §3),
la distinction explicite **toggle `workflow.research` ≠ flag** (capability vs réponse au prompt), et
le renvoi croisé vers `docs-flow.md` **sans duplication** (D-06, ADR-057).

## Écart au plan — la ligne de cadrage ne pouvait pas porter la gradation (⚠️ ratification en attente)

Le plan prescrivait, **pour la ligne de cadrage** (l. 205), que « la gradation de la recherche est
autorisée dans ses deux formes ». **C'est faux contre le moteur installé.**

| Sonde amont | Constat |
|---|---|
| Table `<progressive_disclosure>` de `~/.claude/gsd-core/workflows/discuss-phase.md` (l. 20-40) | ne connaît que `--power`, `--all`, `--auto`, `--chain`, `--text`, `--batch`, `--analyze` — **aucun flag de recherche** |
| Seule occurrence de `--skip-research` dans ce fichier (l. 447) | une **suggestion d'appel** de `/gsd-plan-phase`, pas un flag consommé par la brique de cadrage |

Fait vérifié **trois fois** : par l'exécutant, indépendamment par le manager, puis à nouveau à
l'écriture de ce SUMMARY. La gradation a donc été portée par la **ligne de plan**, et le fait est
inscrit dans le motif de cette ligne (« `gsd-discuss-phase` ne consomme aucun flag de recherche »).
Écrire l'inverse aurait posé un **motif faux** — précisément ce que cette phase existe pour
empêcher.

> **La ratification humaine est en attente.** Registre : `23-ARBITRAGES-OUVERTS.md` **§O-16**.

## Un seul commit et non deux, assumé

Les tâches 1 et 2 sont livrées ensemble. Les découper aurait posé la doctrine D-21 **sans son
gate** : les assertions **G** (le motif ADR est attaché à la ligne de `gsd-ship`) et **H** (son
discriminant par mutation) vivent dans le **même bloc T33** que le reste. Un commit intermédiaire
aurait donc publié une doctrine non verrouillée — exactement ce que cette phase reproche par
ailleurs. L'état final est celui prescrit ; seul le découpage diffère.

## Les preuves de mutation

### Compteurs de suite, avant / après

| | Suite complète |
|---|---|
| Baseline (`aa43b1d`) | **102 OK / 0 KO / 0 SKIP**, rc=0 |
| Après T33 (`2f830ab`) | **103 OK / 0 KO / 0 SKIP**, rc=0 |

Ensembles de **libellés** comparés en `comm` **dans les deux sens** : **0 disparu, 1 ajouté, 102
communs**. Le compteur seul ne vaudrait rien — il a menti plusieurs fois sur cette phase ; c'est la
comparaison d'ensembles qui écarte le libellé muté en silence. Corroboration structurelle lisible
sur le diff : le fichier de test est en **addition pure** (`+407 / −0`) et le bloc T33 n'ouvre
**qu'un seul** couple `ok`/`ko` (l. 4228 et 4230) — aucun libellé antérieur ne pouvait disparaître.

### Mutants externes, joués sur les fichiers réels

**11 exécutions** : **9 rouges** (`M1`, `M2`, `M3`, `M3b`, `M4`, `M5`, `M6`, `M7`, `M8`) et **2
vertes** (`L1`, `L2`).

Le mutant qui porte la démonstration est **`M8` : la clause de fermeture déplacée APRÈS la table,
à contenu strictement identique**. Il rougit. C'est la preuve que la sonde mesure une **relation**
(l'ordre clause → table) et non une **présence** — une assertion existentielle serait restée verte,
puisque pas un caractère n'a changé.

Les deux verts sont là pour l'autre moitié de la preuve : `L1` (clause **reformulée**) et `L2`
(clause **re-wrappée**) restent vertes, donc la sonde ne punit pas une rédaction licite. Une regex
fixturée dans un seul sens n'est pas prouvée.

### Fixtures internes au bloc T33

**11 fautives** et **5 licites**, jouées dans le bloc lui-même (comptage des sites d'incrément
`t33_fx_fautives` / `t33_fx_licites` sur le fichier livré). Deux d'entre elles ferment le piège
français de cette phase :

- la **méta-prohibition à l'infinitif** — « Ne jamais écrire que tout le reste est interdit par
  défaut » : même vocabulaire, portée inverse ⇒ **rejetée** ;
- l'**inversion par négation** — « Tout flag non nommé n'est pas fermé par défaut » ⇒ **rejetée**.

L'infinitif est en français la forme des **interdictions** : une regex élargie à l'infinitif laisse
une prohibition satisfaire une assertion qui exigeait une **affirmation**. Le garde partagé
`T33_PROHIB_RE` est appliqué aux trois sondes concernées (clause, marque transitoire, motif).

### Discriminants internes, dans le livrable et rejouables

| Assertion | Ce qu'elle mesure | Son mutant |
|---|---|---|
| **B** | la clause de fermeture **gouverne** la table (strictement antérieure au premier `^\| `) | **F** — paragraphe de la clause retiré, **table intacte** (même nombre de lignes `^\| `, `cmp -s` différent), plus un **contrôle négatif** sur le fichier réel |
| **G** | l'ADR est portée par **la ligne de table** de `gsd-ship`, pas par la section | **H** — `ADR-059`/`ADR-064` remplacées par `ADR-XXX` **sur cette seule ligne** |
| **D** | non-duplication documentaire par **intersection de listes** (`comm -12`) + garde de non-vacuité (≥ 3 flags extraits) | duplication réelle d'un flag documentaire injectée dans le fichier |
| **E** | le renvoi de `vf-coder.md` vit **dans le bloc Cadrage** | renvoi **déplacé** hors du bloc, rien retiré du fichier |

Chaque mutant est gardé par un `cmp -s` : si le mutant est identique à l'original, le bloc sort en
`ko` en disant que **la sonde est à réancrer** — jamais en vert.

## Le bug attrapé par l'exécutant dans son propre gate

L'assertion **G** est partie **rouge** sur un fichier pourtant correct. Cause : l'extracteur de ligne
de table cherchait la brique en **1ʳᵉ cellule**, or dans la table §1 la brique est en **2ᵉ** (colonne
« Brique gsd », la 1ʳᵉ étant « Étape »).

Le geste compte autant que le bug : l'**extracteur** a été corrigé (index de cellule **explicite**,
`t33_row "$1" 'gsd-ship' 3`, avec le motif écrit en commentaire au-dessus) — **pas** l'assertion.
Assouplir G aurait rendu verte une sonde qui ne prouvait plus que la présence d'un nom de brique
déjà là avant la Phase 23, ce que son message de KO dit désormais mot pour mot.

## Recettes du plan périmées ou incapables d'échouer — à ne pas rejouer

À consigner pour les plans suivants ; aucune n'a été employée telle quelle.

| Recette du plan | Défaut constaté |
|---|---|
| `check-agents.sh --agents-dir <val>` (forme **espacée**, l. 356) | **non supportée** — `check-agents.sh` l. 96 ne reconnaît que `--agents-dir=<val>`. La forme espacée retombe **silencieusement** sur le défaut `.claude/agents`, absent ici ⇒ rc=3. Recette **structurellement incapable de sortir 0**. |
| `<verify>` en `… 2>&1 \| tail -5` (l. 339, 395) | **avale le code de retour** : c'est celui de `tail` qui remonte. Un `1 KO` passerait pour un succès. |
| Snippet d'extraction de la §9 (l. 343) — `awk '/^## 9\./{f=1;next} …'` | le `next` **jette le titre**, alors que le critère d'acceptation voisin (l. 347) exige que la **première ligne** de `s9.txt` soit ce titre. Les deux se contredisent. |
| `read_first` : `vf-coder.md` annoncé **74 lignes** (l. 261) | réel : **98** au démarrage, **100** après. |
| `read_first` : `GSD-PIPELINE.md` annoncé **141 lignes** (l. 172) | réel : **140**. |

## Ce que ce SUMMARY ne dit pas

- **La revue est en vol.** `23-03-REVIEW.md` n'existait pas à l'écriture de ce fichier. Ce SUMMARY
  **constate** ce qui a été fait et mesuré ; il ne vaut pas verdict.
- **Les compteurs de suite et les 11 mutants externes ne sont pas re-mesurés ici.** Ils sont repris
  du rapport d'exécution et du corps de `2f830ab`. Deux nœuds voisins mesuraient les suites au même
  moment ; les rejouer aurait pollué leurs relevés. Ce qui est vérifiable sur disque — comptes de
  lignes, contenu de la table, sites de fixtures, forme des assertions, sources amont de l'écart —
  l'a été, et concorde.
