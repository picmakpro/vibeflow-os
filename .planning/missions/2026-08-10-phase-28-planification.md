# Mission — Planification de la Phase 28

**Date :** 2026-08-10
**Périmètre :** produire les PLAN.md de la Phase 28 « Preuve que ce qui est armé dans le plugin est
armé chez l'utilisateur ». Plan uniquement — aucune exécution, aucun ship, aucune release.
**Branche :** `docs/phase-28-cadrage` (jamais quittée)
**Base de mission :** `a9d32f0`
**Issue :** mise en pause par l'utilisateur en cours de tour 3 de correction.

---

## Plan de bataille (DAG)

| Nœud | Étage | Deps | Statut à la pause |
|---|---|---|---|
| `research` | `gsd-phase-researcher` | — | done |
| `patterns` | `gsd-pattern-mapper` | — | done |
| `panel` | `gsd-advisor-researcher` | — | done |
| `plan` | `vf-coder` (mandat plan, puis 2 corrections ciblées) | research, patterns, panel | **running** (tour 3 en vol) |
| `plancheck` | `gsd-plan-checker` (2 passes indépendantes) | plan | blocked (rouvert) |
| `docs` | hygiène ROADMAP/STATE | plancheck | blocked |

Les trois nœuds amont ont été dispatchés **en parallèle** (périmètres d'écriture disjoints).

---

## État à la pause

**Commits produits** (tous `docs(28)`, tous sous `.planning/` — vérifié, zéro fichier hors périmètre) :

```
960f354  fermer la famille « ecrit en dur pour second-job-9-modules » hors clause de primaute
70538b1  correction ciblée des plans — branchement du checkpoint D-04 et codes de sortie exacts
ad03fc6  arbitrages A-1..A-9, exigences ARMD-01..10 et socle de validation
95aaf30  hygiène de garde — le comptage du comparateur proscrit filtre les commentaires
3b54c49  plan de phase — 3 plans, tranche traçante puis as-installed testing
2767528  etat de l'art agents paralleles + cadrage recoupe marche
3184272  cadrage de la phase 28 — 6 decisions, perimetre du gate verrouille
```

**Artefacts sur disque** (`.planning/phases/VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util/`) :
`28-01-PLAN.md`, `28-02-PLAN.md`, `28-03-PLAN.md`, `28-ARBITRAGES.md`, `28-VALIDATION.md`,
`28-RESEARCH.md`, `28-PATTERNS.md` (+ le cadrage préexistant `28-CONTEXT.md`, `28-DISCUSSION-LOG.md`).
Exigences `ARMD-01…ARMD-10` créées dans `.planning/REQUIREMENTS.md`.

**Les trois plans :**

| Plan | Objet | Autonome |
|---|---|---|
| `28-01` | tranche traçante — règle de bout en bout sur `isolation:` seul, registre-vocabulaire, 3ᵉ discriminant, planchers, cas #38 rejoué en fixture | oui |
| `28-02` | expansion MCP, déclarations `vf-requires:` réelles, admission dans `KNOWN`, bornes d'en-tête | oui |
| `28-03` | *as-installed testing* + clôture | **non** — `checkpoint:decision` bloquant |

---

## Arbitrages du manager (consignés en détail dans `28-ARBITRAGES.md`)

- **A-1** — Liaison artefact ↔ preuve **par identifiant**, jamais par nom de fichier :
  `vf-requires: <id>` côté artefact, `# vf-provides: <id>` côté script, registre = **vocabulaire seul**.
  Modèle Debian `Depends:`/`Provides:`. Motif décisif : toute liaison à un *fichier* rend vert le cas
  « le script existe encore mais ne prouve plus rien » — #38 rejoué d'un cran. Un registre d'artefacts
  est disqualifié : un agent d'un autre module jamais inscrit reproduit #38 littéralement.
- **A-2** — `# vf-provides:` retenu (et non `# vf-proves:` proposé par `28-PATTERNS.md`).
- **A-3** — Le ROUGE ne dépend **jamais** d'une déclaration : la liste close rougit sur l'armement seul ;
  `vf-requires` ne fait que *lever*. Sinon le gate serait inerte sur le mode d'échec exact de #38.
- **A-4** — Le gate reste en **lecture seule** (il n'exécute aucun `ensure-*.sh`), MAIS une tâche prouve
  en suite de tests que le `ensure-*` cité sait réellement rendre non-zéro. Mesuré :
  `ensure-design-deps.sh` **sort toujours 0**, et son seul câblage machine le traite en best-effort à
  l'install — un marqueur statique seul n'aurait rien prouvé.
- **A-5** — Découpage du gate : **clos, aucun seuil ne s'applique**. Vérifié deux fois :
  `plugin/software-architecture/scripts/check-file-size.sh:27` n'inclut pas `.sh`, `check_one()` sort en
  silence sur tout non-code (`:43`), `SCAN_DIRS=(src app lib features)` ne couvre pas `plugin/*/scripts/`.
- **A-6** — **Correction de prémisse.** `28-CONTEXT.md` (D-01 l. 63-64 et §Canonical References) affirme
  qu'une clé de frontmatter inconnue échouerait en `--strict`. **Faux** : `check-agents.sh:618-620` fait
  un `warnings.append` **nu**, sans le patron `(errors if strict else warnings)` des l. 575/616 ; seul
  `n_err` sort en 1 (`:673-677`). Vérifié directement sur disque. L'admission dans `KNOWN` est **hors
  chemin critique**.
- **A-7** — `claude plugin install --plugin-url` n'existe pas en 2.1.226 : écarté. `lab-frais` est le
  **seul** véhicule de D-04.
- **A-8** — D-04 doit voir un univers **non vide**. Mesuré : fermeture `conductor` = 7 modules,
  `dev-orchestrator` absent (le gate n'y est pas installé), 3 agents posés, **0 armement**, et pas de
  `.planning/config.json` dans un lab neuf alors que le gate sort 2 sans config. Un plancher
  anti-vert-à-vide est obligatoire.
- **A-9** — La dégradation gracieuse de gsd-core 1.10.0 **ne rouvre rien**. Interdiction de s'en servir
  pour ré-armer ; le verrou `#3302` porte sur le retour des commits, que la dégradation ne résout pas.

---

## Ce que la chaîne de vérification a produit

**Tour 1 — `gsd-plan-checker` indépendant : 1 bloquant, 4 avertissements, 1 info.**
Fond validé : A-3 tranché littéralement, A-4 en deux moitiés, D-06/recouvrement écrit
(`add-alongside`, le test asserte le **message** `ECART regle 4` et non le code de sortie — sinon
l'ancienne garde fournirait le rouge à sa place), A-9 sans cas de preuve creux, planchers présents,
interdits durs respectés avec **confinement des fixtures vérifié réel** (profondeur 2, hors des deux
corpus, au dépôt comme en lab à plat), ADR-054 tenu, couverture 10/10 ARMD et 9/9 arbitrages,
chaînage acyclique.
Bloquant : le `checkpoint:decision` de `28-03` portait trois options mais **une seule branche planifiée**.

**Tour 2 — correction (`70538b1`) puis re-vérification indépendante : 1 bloquant, 3 avertissements, 2 info.**
Closes et re-mesurées par le juge : W-1 (les deux routes vers `exit 1` sont réelles), W-2, W-3,
W-4 (8 + 12 = 20 `SKILL.md`, corpus 51, glob élargi `rc=0`), les info, et le **débordement assumé** du
correcteur — jugé *exact et non-affaiblissant*, `rc ∈ {0,3}` ayant été **ajouté** au contrat.
Bloquant restant : le défaut B-1 avait été **déplacé**, pas clos — la clause de primauté du branchement
ne couvre que `<action>`, `<verify>`, `<acceptance_criteria>` du corps, laissant quatre affirmations
écrites en dur pour l'option 1 hors de portée, dont un `<verify>` **garanti rouge par construction**.

**Tour 3 — correction dispatchée, EN VOL au moment de la pause.** Six correctifs nommés (F1 bloquant,
F2-F4 avertissements, F5-F6 info) + consigne de fermer la **famille** de défaut plutôt que les lignes.

---

## Points restés pour l'humain

1. **Dépassement de cadrage sur D-04.** `28-03` propose un second job CI (`lab-frais-arme`) et une
   fermeture installée de 9 modules, là où D-04 disait « ajout d'une étape au job ». Forcé par les faits
   mesurés d'A-8. **Non tranché en plan** — porté par un `checkpoint:decision` bloquant à trois options.
2. **`28-CONTEXT.md` fait rougir un gate bloquant pour un défaut de FORME.**
   `check.decision-coverage-plan` rend `passed:false / reason:"could-not-parse"` : l. 75 et 100 portent
   un `*` littéral dans `` `ensure-*.sh` `` **à l'intérieur du gras**, l. 107-108 ont un gras courant sur
   deux lignes. La couverture réelle est bonne (vérifiée indépendamment). **Volontairement non corrigé** :
   le fichier est le support d'un arbitrage humain, et une mission de fond ne l'édite pas seule. Correctif :
   3 lignes de markdown.
3. **Débordement assumé du correcteur** (tour 2) sur la 4ᵉ `truth` du frontmatter de `28-03` et un
   `success_criteria` — signalé, puis jugé exact et minimal par le juge indépendant. Rien à faire, tracé
   pour mémoire.

---

## Reprise

- **Le tour 3 a abouti APRÈS la demande de pause** : commit `960f354`, périmètre vérifié strictement
  `28-02-PLAN.md` + `28-03-PLAN.md`, **arbre propre**. Le correcteur rapporte les six correctifs
  F1-F6 appliqués, plus un **septième de la même famille trouvé à son propre balayage** (la
  vérification de bout en bout exigeait « les trois jobs verts, plus le nouveau », insatisfaisable
  sous `etape-dans-lab-frais` — reformulée « tous les jobs verts », déclinée par option). Il déclare
  avoir balayé la famille en entier et énumère les zones vérifiées génériques ou déjà bi-options.
- **CE TOUR 3 N'A PAS ÉTÉ VÉRIFIÉ.** C'est le seul trou de la chaîne : les tours 1 et 2 ont chacun eu
  leur passe `gsd-plan-checker` indépendante, celui-ci n'a que l'auto-déclaration `passed` de son
  auteur — et l'auto-déclaration s'est trompée aux deux tours précédents (le tour 2 se disait `passed`
  alors qu'il avait *déplacé* le bloquant). **Ne pas traiter les plans comme vérifiés sur cette base.**

**Premier geste à la reprise :** dispatcher une **troisième passe `gsd-plan-checker` indépendante** sur
le delta `70538b1..960f354`, avec deux questions — (a) les sept correctifs sont-ils réellement clos, et
(b) le balayage de famille annoncé est-il exhaustif ? Le juge a déjà démontré deux fois qu'il trouvait
ce que l'auteur ne voyait pas.
- **Budget de correction épuisé** (3 tours). Si une re-vérification du tour 3 remonte encore un défaut de
  la même famille (affirmation écrite en dur pour `second-job-9-modules` hors portée de la clause de
  primauté), la conduite prévue est **l'escalade à l'humain**, pas un quatrième tour.
- Reste ensuite : une dernière passe `gsd-plan-checker` indépendante, puis le nœud `docs`
  (ROADMAP/STATE).
- **La mission s'arrête au plan vérifié.** Exécution, ship et release restent des gestes humains.

## Notes d'hygiène

- Verrou de driver acquis en début de mission, battu à chaque étape, **relâché à la pause**.
- Invariants de mission : **SAIN** (exit 0) au démarrage.
- Flags d'enchaînement vérifiés déjà à `false` dans `.planning/config.json` (`gsd_run` non résoluble en
  shell non interactif — constaté, best-effort).
- Un dossier `.gsd/` non suivi est apparu pendant la mission (outillage amont) — non commité, à trier.
