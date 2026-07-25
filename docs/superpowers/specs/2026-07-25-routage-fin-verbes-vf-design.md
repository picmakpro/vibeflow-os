# Design — Routage fin des intentions & couverture complète des verbes `/vf-*`

> **Date** : 2026-07-25
> **Modules** : `dev-orchestrator` (v1.7.0 → v1.8.0), `design-orchestrator` (+1 verbe)
> **Problème** : l'orchestrateur route grossièrement et ~50 des 65 skills GSD n'ont aucune
> porte d'entrée VibeFlow.

---

## 1. Problème

### 1.1 Le routage de l'agent court-circuite les verbes

La table de routage de `plugin/dev-orchestrator/AGENT.md` (l. 51-67) mappe l'intention
directement sur la cible GSD :

```
| comprends ce code / cartographie / c'est quoi ce repo | gsd-map-codebase |
```

Alors qu'il existe un verbe `/vf-map` qui fait exactement cette délégation. Conséquences :

- **Deux sources de vérité par intention** — la table de l'agent et le `SKILL.md` du verbe
  peuvent diverger (elles ont déjà divergé : `vf-decide` et `vf-init` n'existent que côté skill).
- L'agent **n'est consulté que s'il est incarné** — il ne protège pas le cas courant, où
  l'utilisateur tape une phrase dans une session sans agent actif.

### 1.2 Aucune préséance des verbes VibeFlow sur les skills GSD

Les 65 skills `gsd-*` sont chargés **en même temps** que les 14 `/vf-*` dans une session d'un
lab installé. Sur « map ma codebase », Claude arbitre entre `vf-map` et `gsd-map-codebase` sur
la seule base des descriptions. Rien ne garantit que VibeFlow gagne — et quand GSD gagne, la
promesse structurante du produit tombe : la plomberie fuite, le vocabulaire n'est pas reframé.

### 1.3 ~50 skills GSD sans porte d'entrée

Les 14 verbes couvrent 12 cibles. Restent sans aucune porte d'entrée : `secure-phase`,
`add-tests`, `audit-uat`, `audit-fix`, `validate-phase`, `forensics`, `inbox`, `new-milestone`,
`complete-milestone`, `milestone-summary`, `phase`, `undo`, `review-backlog`, `capture`,
`cleanup`, `resume-work`, `pause-work`, `docs-update`, `ingest-docs`, `extract-learnings`,
`graphify`, `explore`, `spike`, `spec-phase`, `sketch`, et ~25 méta (`health`, `stats`,
`config`, `workspace`, `workstreams`, `thread`, `manager`, `import`, `pr-branch`,
`profile-user`, `ultraplan-phase`, `plan-review-convergence`, `eval-review`,
`ai-integration-phase`, `ui-phase`, `ui-review`…).

---

## 2. Architecture — trois niveaux de routage

| Niveau | Mécanisme | Portée | Quand il joue |
|---|---|---|---|
| **1. Déclenchement natif** | descriptions `/vf-*` denses | 33 verbes | cas courant — l'utilisateur formule une intention en session |
| **2. Règle de préséance** | `rules/vf-verb-precedence.md` → `.claude/rules/` | globale | filet : interdit l'invocation directe d'un `gsd-*` |
| **3. Agent `vibeflow-dev`** | table courte `AGENT.md` → verbes `/vf-*` + `references/intent-routing.md` on-demand | 100 % GSD | intention non couverte par un verbe, ou orchestration multi-étages |

**Principe directeur** : un verbe `/vf-*` est la **seule** source de vérité d'une intention.
L'agent ne mappe plus vers `gsd-*`, il mappe vers le verbe. `intent-routing.md` est le seul
endroit du module qui connaît la totalité des noms `gsd-*`, et il n'est chargé qu'à la demande.

### 2.1 Niveau 1 — descriptions déclencheuses

Chaque `SKILL.md` porte une description construite sur trois blocs :

1. **Formulations FR réelles** — verbes conjugués et tournures que Samuel tape vraiment
   (« map ma codebase », « c'est quoi ce repo », « fais l'état des lieux »), pas des étiquettes
   abstraites.
2. **Contre-exemples nommant les voisins** — `✘ pas pour <geste voisin> → <verbe voisin>`.
   C'est le seul mécanisme qui départage deux skills proches au matching.
3. **Portée d'invocation** — « par l'utilisateur ET par l'agent en autonomie » (conservé).

Les 14 descriptions existantes sont réécrites sur ce gabarit ; les 18 nouvelles le suivent.

### 2.2 Niveau 2 — `rules/vf-verb-precedence.md`

Nouveau dossier `plugin/dev-orchestrator/rules/`. L'installeur le prend en charge sans
modification (`vibeflow-update.sh` Type 5, l. 490-494 : `rules/*.md` → `$TARGET_ROOT/rules/`,
désinstallation symétrique l. 677-681).

Rule **globale (Tier 1, pas de frontmatter `paths:`)** — contrairement à
`doc-research-before-debug.md` qui ne s'arme que sur du code applicatif, la préséance doit
valoir sur tout prompt de dev, et une intention n'a pas de chemin de fichier : elle est
inscopable par construction. Elle relève donc du Tier 1 du Pattern 05 (« globale ET
universelle »). Contrepartie assumée de l'anti-pattern « règle globale qui pollue le
contexte » : la rule est tenue **≤ 40 lignes**, sans redite de la table de routage.

Contenu :

- **Iron Law** : toute intention de développement se route vers un verbe `/vf-*`. Les skills
  `gsd-*` et `superpowers:*` sont de la plomberie interne — jamais invoqués directement,
  jamais nommés à l'utilisateur.
- **Échappatoire cadrée** : intention non couverte par un verbe → incarner `vibeflow-dev`, qui
  consulte `intent-routing.md` et délègue. Jamais d'appel `gsd-*` « en passant ».
- **Exception explicite** : un verbe `/vf-*` invoque évidemment sa cible `gsd-*` — c'est son
  rôle. L'interdit porte sur l'invocation **en entrée de chaîne**.

### 2.3 Niveau 3 — `references/intent-routing.md`

Table exhaustive `intention → verbe /vf-* → cible GSD` couvrant **les 65 skills de
`gsd-skills-index.md`**. Les ~35 sans verbe dédié y sont routés directement par l'agent.
Chargé on-demand, comme `GSD-PIPELINE.md` et `mission-contracts.md` — coût contexte nul en
session normale.

Distinction avec `gsd-skills-index.md` (auto-généré par `build-gsd-index.sh`, NE PAS ÉDITER) :
celui-ci est un **inventaire factuel** des skills présents sur la machine ;
`intent-routing.md` est la **doctrine de routage**, écrite à la main, versionnée.

---

## 3. Les 19 nouveaux verbes

### dev-orchestrator (18) — 14 existants → 32

**Qualité & audits**

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-secure` | `gsd-secure-phase` | « audite la sécu », « vérifie les failles », « threat model » |
| `vf-testgen` | `gsd-add-tests` | « écris les tests », « il manque des tests », « couvre cette étape » |
| `vf-gaps` | `gsd-audit-uat`, `gsd-audit-fix`, `gsd-validate-phase` | « qu'est-ce qui traîne », « comble les trous », « ce qui reste à vérifier » |
| `vf-forensics` | `gsd-forensics` | « pourquoi ça a foiré », « post-mortem », « analyse l'échec » |
| `vf-inbox` | `gsd-inbox` | « trie les issues », « les PR en attente », « la inbox GitHub » |

**Cycle de vie projet**

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-milestone` | `gsd-new-milestone`, `gsd-complete-milestone`, `gsd-milestone-summary` | « nouvelle milestone », « archive la milestone », « bilan de version » |
| `vf-phase` | `gsd-phase` | « ajoute une étape », « supprime ce sprint », « réordonne la feuille de route » |
| `vf-undo` | `gsd-undo` | « annule », « reviens en arrière », « rollback le sprint » |
| `vf-backlog` | `gsd-review-backlog`, `gsd-capture` | « note cette idée », « le backlog », « promeus cet item » |
| `vf-cleanup` | `gsd-cleanup` | « fais le ménage », « archive les vieux dossiers » |

**Contexte & session**

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-resume` | `gsd-resume-work` | « reprends où on en était », « on reprend », « recharge le contexte » |
| `vf-pause` | `gsd-pause-work` | « je m'arrête là », « note où on en est », « handoff » |
| `vf-docs` | `gsd-docs-update` | « mets à jour la doc », « génère le README », « la doc est périmée » |
| `vf-learn` | `gsd-extract-learnings`, `gsd-graphify` | « qu'est-ce qu'on a appris », « extrais les décisions » |

**Amont & exploration**

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-explore` | `gsd-explore` | « explore cette idée », « je sais pas encore ce que je veux » |
| `vf-spike` | `gsd-spike` | « teste cette approche », « prototype jetable », « spike » |
| `vf-spec` | `gsd-spec-phase` | « qu'est-ce que ça doit faire exactement », « fige le périmètre » |

**Pont spec → feuille de route** (détail § 8)

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-ingest` | `gsd-ingest-docs --mode merge`, `gsd-import --from` | « intègre cette spec à la feuille de route », « transforme ce cadrage en étapes », « importe ce plan » |

### design-orchestrator (1)

| Verbe | Cible GSD | Intentions |
|---|---|---|
| `vf-sketch` | `gsd-sketch` | « maquette-moi ça », « une idée d'écran », « mockup jetable » |

Placé dans `design-orchestrator` et non `dev-orchestrator` : le geste est un geste de design.
`gsd-ui-phase` et `gsd-ui-review` restent couverts par `/vf-design` (déjà en place, routage
interne de l'agent `vibeflow-design`) — pas de verbe supplémentaire.

---

## 4. Collisions arbitrées

| Collision | Décision |
|---|---|
| `vf-test` (recette UAT) vs génération de tests | Le second s'appelle **`vf-testgen`**. `vf-tests` à un `s` près est une collision garantie — à la frappe pour l'humain, au matching pour le modèle. |
| `vf-review` (revue de code d'un diff) vs `vf-audit` (audits UAT / validation / dette) | Contre-exemples croisés explicites dans les deux descriptions. |
| `vf-brainstorm` / `vf-explore` / `vf-spike` / `vf-spec` | 4 verbes conservés, démarcation par contre-exemples croisés : **brainstorm** = concevoir une solution (idée déjà formulée) · **explore** = idéation socratique (idée floue) · **spike** = expérimenter avec du code jetable · **spec** = figer le QUOI (vs `vf-plan` = le COMMENT). Test T11 : chacun des 4 doit citer ses voisins. |
| `vf-map` (cartographie du code) vs `vf-learn` (graphe de connaissance) | Contre-exemples croisés. |
| `vf-progress` (où on en est) vs `vf-resume` (recharger le contexte d'une session passée) | Contre-exemples croisés. |
| `vf-ingest` (un cadrage écrit → étapes) vs `vf-docs` (le code → la doc) vs `vf-phase` (édition manuelle d'étapes) | Contre-exemples croisés : `vf-ingest` part **d'un document existant**, `vf-docs` part **du code**, `vf-phase` part **d'une intention directe sans document**. |
| **`vf-gaps` (trous de vérification du projet) vs `/vf-audit` (conformité méthodologique du lab)** | Collision découverte en exécution : `plugin/commands/vf-audit.md` existe déjà et délègue à `vibeflow-validator`. Le nom initialement prévu au design (`vf-audit`) est abandonné au profit de **`vf-gaps`** ; `/vf-audit` garde sa chasse gardée « conformité du lab ». Démarcation **unilatérale** (`vf-gaps` renvoie vers `/vf-audit`, l'inverse n'est pas exigé — `/vf-audit` est une commande, pas un verbe du gabarit). |

---

## 5. Fichiers touchés

**Créés**
- `plugin/dev-orchestrator/skills/vf-{secure,testgen,audit,forensics,inbox,milestone,phase,undo,backlog,cleanup,resume,pause,docs,learn,explore,spike,spec,ingest}/SKILL.md` (18)
- `plugin/dev-orchestrator/rules/vf-verb-precedence.md`
- `plugin/dev-orchestrator/references/intent-routing.md`
- `plugin/design-orchestrator/skills/vf-sketch/SKILL.md`

**Modifiés**
- `plugin/dev-orchestrator/AGENT.md` — table de routage vers les verbes `/vf-*`, renvoi vers
  `intent-routing.md`, garde-fou de préséance. Contrainte : **≤ 250 L** (actuellement 160).
- Les 14 `SKILL.md` existants — descriptions réécrites sur le gabarit § 2.1. `vf-brainstorm`
  gagne en plus l'enchaînement vers `/vf-ingest` (§ 7).
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — fixture T4 étendue,
  nouveau T11 (voir § 6).
- `plugin/dev-orchestrator/{module.json,VERSION,CHANGELOG.md,README.md}` → **v1.8.0**
- `plugin/design-orchestrator/{module.json,VERSION,CHANGELOG.md,README.md}` → bump mineur
- Racine : `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `README.md`, `README.fr.md` (badges + historique) → **v2.29.0**

---

## 6. Vérification

**Tests machine étendus** (`test-dev-orchestrator.sh`) :

- **T4 (mapping non orphelin)** — la fonction `target_known()` retombe sur une fixture de 13
  cibles canoniques quand l'index disque est absent (CI, machine sans GSD installé). Les ~24
  nouvelles cibles y sont **ajoutées** (dont `gsd-ingest-docs` et `gsd-import` pour le pont),
  sinon chaque nouveau verbe sortirait orphelin hors poste de dev. *C'est le piège n°1 de ce
  chantier.*
- **T5 (densité)** — inchangé, mais `AGENT.md` doit rester ≤ 250 L malgré 18 intentions de
  plus : d'où le déport vers `intent-routing.md`.
- **T11 (nouveau — anti-collision)** — pour chaque groupe de verbes déclaré proche (§ 4),
  vérifie que chaque description contient au moins un contre-exemple citant un voisin.
- **T12 (nouveau — préséance)** — `rules/vf-verb-precedence.md` existe, ne déclare pas de
  `paths:`, et est référencé par `AGENT.md`.
- **T13 (nouveau — exhaustivité)** — chaque `gsd-*` de `gsd-skills-index.md` apparaît dans
  `intent-routing.md`. SKIP si l'index est vide (pas de GSD sur la machine).

**Contrôles existants** : `plugin/conductor/scripts/check-agents.sh` (ADR-044),
`scripts/check-release-tag.sh --remote` après le tag.

**Vérification manuelle** : install e2e dans un lab jetable, puis formuler « map ma codebase »,
« audite la sécu », « reprends où on en était » et vérifier que le verbe `/vf-*` est retenu.

---

## 7. Pont spec → feuille de route (`/vf-ingest`)

### 7.1 Le trou fonctionnel

VibeFlow fait cohabiter **deux systèmes de planification qui ne se parlent pas** :

- **Superpowers** — `brainstorming` produit une spec dans `docs/superpowers/specs/`, puis
  `writing-plans` produit un plan dans `docs/superpowers/plans/`.
- **GSD** — la feuille de route (`.planning/ROADMAP.md`), les exigences
  (`.planning/REQUIREMENTS.md`), les étapes (`.planning/phases/NN-*/`) et leurs `PLAN.md`.

Aujourd'hui la jonction est **manuelle** : après un cadrage, quelqu'un recopie à la main la
spec en étapes de feuille de route. C'est le seul maillon non outillé du cycle, et c'est là que
le périmètre se perd entre ce qui a été décidé et ce qui sera exécuté.

### 7.2 Ce que fait le verbe

`/vf-ingest` ne réimplémente rien : les deux moteurs existent côté GSD.

| Grain | Source | Moteur | Résultat |
|---|---|---|---|
| **Spec → étapes** | `docs/superpowers/specs/*.md` | `gsd-ingest-docs --mode merge --manifest <f>` | nouvelles étapes dans `ROADMAP.md` + exigences dans `REQUIREMENTS.md`, conflits arbitrés |
| **Plan → PLAN.md** | `docs/superpowers/plans/*.md` | `gsd-import --from <f>` | `PLAN.md` d'une étape existante, validé par `gsd-plan-checker` |

La valeur ajoutée VibeFlow, au-delà de l'alias :

1. **Découverte** — liste les specs/plans de `docs/superpowers/` non encore intégrés (une spec
   est considérée intégrée si son chemin est cité dans `ROADMAP.md`, convention déjà en usage :
   « Spec : `docs/superpowers/specs/2026-06-04-install-ux-design.md` »).
2. **Détection du grain** — spec ou plan, d'après le dossier source et la structure du document ;
   en cas d'ambiguïté, une question courte plutôt qu'un pari.
3. **Construction du manifest** — génère le YAML `{path, type: SPEC, precedence}` attendu par
   `gsd-ingest-docs`, que l'utilisateur n'a pas à connaître.
4. **Reframe** — « phases » → **étapes**, « requirements » → **exigences**,
   `INGEST-CONFLICTS.md` → **rapport d'arbitrage**.

### 7.3 Garde-fous

- **Gate BLOCKER préservé** — le moteur GSD n'écrit aucun fichier de destination tant qu'une
  contradiction non résolue subsiste avec une décision verrouillée. Le verbe ne contourne
  jamais ce gate ni les portes d'approbation (découverte, rapport de conflit, routage).
- **Jamais en autonomie silencieuse** — modifier la feuille de route engage le projet :
  l'intégration est présentée puis confirmée (ADR-031, matérialisation = acte humain).
- **`--mode merge` par défaut** sur un projet ayant déjà un `.planning/`. Le mode `new`
  (bootstrap complet) reste réservé à `/vf-init`, qui porte déjà cette responsabilité.
- **Cap de 50 documents** par invocation (contrainte v1 du moteur) — signalé, pas contourné.

### 7.4 Bouclage du cycle

`vf-brainstorm` gagne un enchaînement explicite en fin de cadrage : une fois la spec écrite,
**proposer `/vf-ingest`** plutôt que de laisser l'utilisateur devant un document orphelin. Le
cycle complet devient :

```
vf-brainstorm → (spec écrite) → vf-ingest → (étapes + exigences) → vf-plan → vf-execute
```

---

## 8. Hors périmètre (YAGNI)

- **Hook `UserPromptSubmit` de routage** — écarté : matching par mots-clés fragile sur du
  langage naturel, coût à chaque prompt, et le repo sort de deux vagues de durcissement de
  hooks (ADR-050).
- **Verbe dédié pour les ~35 skills méta** (`health`, `stats`, `config`, `workspace`,
  `workstreams`, `thread`, `manager`, `import`, `pr-branch`, `profile-user`,
  `ultraplan-phase`, `plan-review-convergence`, `eval-review`, `ai-integration-phase`) —
  couverts par `intent-routing.md`. Ce sont des gestes d'outillage, pas des intentions
  formulées spontanément.
- **Refonte de `build-gsd-index.sh`** — l'index auto-généré reste tel quel.
- **Écriture directe de `ROADMAP.md`/`REQUIREMENTS.md` par `/vf-ingest`** — le verbe délègue
  aux moteurs GSD et à leurs gates. Aucun parseur de spec maison : ce serait une seconde
  implémentation à maintenir en parallèle de `gsd-ingest-docs`.
- **Remplacement de `writing-plans` (Superpowers)** — le pont rend les deux systèmes
  interopérables, il n'en supprime aucun.

---

## 9. Découpage en étapes de la feuille de route

Deux étapes, milestone **`vf-routing`**. La seconde dépend de la première (le pont est un verbe
de plus, il suppose le gabarit de description et la rule de préséance en place).

| Étape | Périmètre | Exigences |
|---|---|---|
| **Phase 12 — Routage fin & couverture des verbes** | §§ 2-6 : 3 niveaux de routage, 18 verbes (17 dev dont `vf-gaps` + `vf-sketch` en design ; `vf-ingest` exclu et sa place réservée), rule de préséance, `intent-routing.md`, réécriture des 14 descriptions, tests T4 + T12/T13/T14 (T11 étant déjà pris par la généricité anti-résidu Reviz) | `VERB-01..05` |
| **Phase 13 — Pont spec → feuille de route** | § 7 : verbe `/vf-ingest` (2 grains), découverte des specs non intégrées, manifest, garde-fous, enchaînement depuis `vf-brainstorm` | `BRDG-01..03` |

La release (bump racine + tag) est portée par la Phase 13, qui clôt le milestone.
