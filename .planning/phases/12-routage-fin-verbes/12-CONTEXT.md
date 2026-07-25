# Phase 12: Routage fin & couverture complète des verbes `/vf-*` — Context

**Gathered:** 2026-07-25
**Status:** Ready for planning
**Mode:** cadrage **allégé** — le QUOI est figé par la spec, aucune zone grise rouverte.

## Source de vérité du QUOI

`docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md` (spec validée et commitée).
Elle tient lieu de contexte d'étape : problème, architecture à trois niveaux, tableau des verbes,
collisions arbitrées, fichiers touchés, plan de vérification. **Aucune question de périmètre déjà
tranchée par la spec n'est rouverte ici.**

<domain>
## Phase Boundary

Livre les **trois niveaux de routage** de la spec §2 et **18 verbes** neufs :

1. **Niveau 1 — descriptions déclencheuses** : 18 `SKILL.md` neufs + réécriture des 15
   descriptions existantes (14 `dev-orchestrator` + `vf-design`) sur un gabarit unique.
2. **Niveau 2 — préséance** : `plugin/dev-orchestrator/rules/vf-verb-precedence.md`, rule globale
   Tier 1 (≤ 40 L, sans `paths:`).
3. **Niveau 3 — doctrine exhaustive** : `plugin/dev-orchestrator/references/intent-routing.md`,
   couvrant 100 % des skills de `gsd-skills-index.md`, chargé on-demand ; `AGENT.md` refondu pour
   router vers des verbes `/vf-*` et non plus vers des cibles `gsd-*`.

**Ne produit PAS** :

- Le verbe `/vf-ingest` — cœur de la **Phase 13**. Sa place est réservée (`intent-routing.md` route
  `gsd-ingest-docs` et `gsd-import` vers lui, la fixture de test le connaît), mais son `SKILL.md`
  n'est pas écrit ici.
- Aucune release : **pas de bump de la `VERSION` racine, pas de tag git**, pas de modification de
  `plugin/.claude-plugin/plugin.json` ni de `.claude-plugin/marketplace.json`. La release est
  portée par la Phase 13 qui clôt le milestone.
- Aucun hook `UserPromptSubmit` de routage (YAGNI, spec §8).
- Aucune refonte de `build-gsd-index.sh` — l'index reste auto-généré et **non éditable**.
</domain>

<decisions>
## Décisions arbitrées avant planification

### D-01 — `vf-audit` est renommé `vf-gaps` (fait du repo contre la spec)
La spec §3 nomme `vf-audit` le verbe des audits UAT / validation / dette. Or
`plugin/commands/vf-audit.md` **existe déjà** et délègue à l'agent `vibeflow-validator` (audit de
conformité méthodologique du lab, pas du produit).

**Décision** : le nouveau verbe s'appelle **`vf-gaps`**. `plugin/commands/vf-audit.md` n'est pas
touché. Conséquences :

- La description de `vf-gaps` porte un contre-exemple explicite : *« ✘ pas pour auditer la
  conformité du lab / les agents → `/vf-audit` »*.
- Réciproquement, **aucune** description de verbe `/vf-*` ne capte l'intention « audite le lab / la
  conformité / les agents ».
- C'est une **6ᵉ paire de collision**, couverte par le test anti-collision au même titre que les 5
  de la spec §4.

### D-02 — `vf-ingest` est livré en Phase 13, pas ici
Phase 12 livre donc **18 verbes** : 17 dans `dev-orchestrator` + `vf-sketch` dans
`design-orchestrator`. `VERB-02` est **partiellement couvert** en Phase 12 (17/18 verbes
`dev-orchestrator`), soldé en Phase 13.

### D-03 — Numérotation des tests
Le `T11` du script existant est **déjà pris** (généricité / anti-résidu Reviz, DM5) et n'est pas
renuméroté. Les nouveaux tests sont **T12** (anti-collision), **T13** (préséance), **T14**
(exhaustivité), avec en commentaire d'en-tête la correspondance vers les noms de la spec
(T11/T12/T13).

### D-04 — Versions
`plugin/dev-orchestrator` → **v1.8.0**, `plugin/design-orchestrator` → bump **mineur**. Pour chaque
module : `VERSION`, `module.json`, `CHANGELOG.md`, `README.md`. Rien à la racine.

### D-05 — Le gabarit de description est un artefact de planification
Le gabarit de la spec §2.1 est écrit dans `12-DESCRIPTION-TEMPLATE.md` (ce dossier) et **n'est pas
livré dans le module**. C'est le contrat que les vagues 2 et 3 appliquent mot pour mot.

### D-06 — Déviations tracées, pas silencieuses
D-01 et D-02 sont reportées dans la spec et dans `REQUIREMENTS.md` (VERB-02) : le document de
design reste la source de vérité, il n'est pas laissé en contradiction avec le livré.

### D-07 — Réciprocité stricte sur les groupes canoniques, unilatérale ailleurs
Le gabarit pose la réciprocité comme inconditionnelle (« si A repousse vers B, B repousse vers A »)
avec une seule exception déclarée (`/vf-audit`, D-01). L'application littérale à l'état final
demanderait ~30 arêtes supplémentaires, donc ~30 descriptions alourdies — chargées en permanence —
pour un gain de routage nul sur des paires sans recouvrement lexical réel.

**Décision** (prise en vague 2, sur constat de revue) :

- **Réciprocité obligatoire** sur les **6 groupes de collision canoniques** de la matrice, plus les
  démarcations additionnelles à recouvrement lexical avéré (`debug`↔`forensics`, `plan`↔`phase`,
  `ship`↔`inbox`, `sketch`↔`design`↔`spike`, `test`↔`spike`, `progress`↔`gaps`). C'est le périmètre
  que T12 contrôle.
- **Unilatérale admise ailleurs**, par économie de description : le contre-exemple n'existe que du
  côté où le recouvrement se produit réellement.
- **Cibles hors module non croisables par construction** : `/vf-audit` (module `validator`) et
  `/vf-planning` (module `planning-core`) reçoivent des renvois sans en émettre. Ces deux modules
  ne sont pas touchés par l'étape 12.

Conséquence pour 12-06 : T12 assert la réciprocité **sur la liste des groupes ci-dessus**, pas sur
toutes les paires citées. Un contrôle universel produirait des faux positifs, notamment sur les
renvois génériques de `vf-dev`.
</decisions>

<constraints>
## Contraintes dures

- **Densité (ADR-029)** : `AGENT.md` ≤ 250 L (aujourd'hui 160), chaque `SKILL.md` ≤ 500 L, rule
  ≤ 40 L.
- **Router, jamais réimplémenter** : chaque verbe **délègue** à sa cible GSD. Aucune logique
  d'outil recodée.
- **Zéro fuite de plomberie** : aucun « GSD », « Superpowers » ni nom de skill brut côté
  utilisateur. Reframe systématique via `references/vocabulary-map.md`.
- **ADR-044** : `bash plugin/conductor/scripts/check-agents.sh` doit passer.
- **Tests verts en fin d'étape** : `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`.
- **Commits en français**, atomiques, cohérents avec l'historique du repo.
- Branche de travail : `feat/phase-12-routage-fin`. Pas de push, pas de merge, pas de PR depuis
  l'exécution — la livraison est pilotée en fin d'étape.
</constraints>

<pitfalls>
## Pièges connus de ce chantier

1. **Fixture T4 (piège n° 1)** — `test-dev-orchestrator.sh` l. 175 embarque `FIXTURE_TARGETS`, une
   liste de 13 cibles en dur utilisée **quand l'index disque est absent** (CI, machine sans GSD
   installé). Sans extension, **tous les nouveaux verbes sortent orphelins hors poste de dev**.
   L'extension est un livrable explicite du plan 12-06.
2. **Tension T3 ↔ VERB-01** — T3 compte ≥ 11 cibles canoniques `gsd-*` **distinctes dans
   `AGENT.md`**, alors que VERB-01 exige une table de routage sans aucune cible `gsd-*`. Le plan
   12-05 tranche et justifie ; le plan 12-06 ajoute l'assertion complémentaire (la *table* est
   propre) sans casser T3.
3. **Densité de `AGENT.md`** — il gagne 18 intentions tout en restant ≤ 250 L : table **groupée par
   famille** pointant des verbes, doctrine exhaustive déportée dans `intent-routing.md`.
4. **`gsd-skills-index.md` est auto-généré** — ne jamais l'éditer. `intent-routing.md` est son
   pendant **écrit à la main** : inventaire factuel d'un côté, doctrine de routage de l'autre.
</pitfalls>

<notes>
## Écart de comptage relevé (à confirmer par le manager, non bloquant)

La spec §2.3 parle des « 70 skills de `gsd-skills-index.md` ». Le décompte réel de l'index sur
disque est de **65 skills `gsd-*`** (`grep -c '^| gsd-'`). Le chiffre de 67 obtenu par extraction
de tokens inclut deux faux positifs : `gsd-index` (venu de `build-gsd-index.sh`) et `gsd-sdk`.
La cible retenue pour VERB-05 est donc **65/65 = 100 %**, mesurée par le test T14 contre l'index
lui-même (et non contre un nombre figé) — ce qui rend le critère robuste à l'évolution de GSD.
</notes>
