# Mission — Phase 29 « Distiller les gains ICM (G1-G5) »

**Date :** 2026-08-15
**Branche :** `docs/phase-29-icm-gains` (aucun push, aucune PR, aucun merge)
**Mode :** autonome jusqu'aux gates
**Issue :** **phase COMPLÈTE, 13/13 tâches.** Arrêt au checkpoint humain bloquant **T-29-05-3**,
verdict rendu par Samuel le 2026-08-15, mission reprise et close sur ce verdict.
**Verrou de driver :** acquis au démarrage (`mission-phase-29`), battu entre les étapes, relâché en clôture.
**Invariants de mission :** `check-mission-invariants.sh` → exit **3 (SAIN)** avant le premier dispatch.

---

## Plan de bataille (DAG, 10 nœuds)

```
exec-01 → revue-01 → { fix-01 ∥ exec-02 ∥ exec-03 ∥ exec-04 } → { revue-w2 ∥ audit-w2 } → exec-05 → docs
```

Vague 2 dispatchée **en parallèle** (4 workers, un seul message) : périmètres de fichiers déclarés
disjoints au `dag.sh add`. Discipline de commit imposée à chaque worker (`git add <chemins>` puis
`git commit -- <chemins>`, jamais `git commit` nu ni `git add -A`) — aucune collision d'index
constatée sur 4 écrivains simultanés.

Le nœud `docs` (hygiène documentaire finale) reste **blocked** : il dépend d'`exec-05`, dont la
tâche 3 attend le verdict humain. C'est volontaire — documenter avant l'arbitrage produirait une
doc périmée le lendemain.

---

## État des 13 tâches

| Plan | Tâches | État |
|---|---|---|
| 29-01 (vague 1) | 2/2 | vert |
| 29-02 (vague 2, G3) | 3/3 | vert, après **4 tours de correction** |
| 29-03 (vague 2, G1+G5) | 3/3 | vert |
| 29-04 (vague 2, G2) | 3/3 | vert |
| 29-05 (vague 3) | 2/3 | tâches 1-2 vertes · **tâche 3 = checkpoint humain, NON exécutée** |

**12 tâches sur 13 livrées. 29 commits.**

---

## Livrables

- `reports/research/2026-08-15-investigation-dag-scope.md` — investigation `--scope` : historique,
  inventaire des consommateurs, classification INTOUCHABLE / EXTENSIBLE, verdict « la voie doctrine
  seule suffit ». C'est ce verdict, validé en revue, qui a autorisé G1 à se livrer **sans toucher
  `dag.sh`**.
- `.planning/REQUIREMENTS.md` — 12 exigences `ICMD-01..12` (couverture re-dérivée par `comm` :
  0 orphelin, 0 inventé).
- `plugin/conductor/scripts/check-map-drift.sh` (**G3**, neuf) + `tests/test-check-map-drift.sh`
  (neuve, **51 cas** dont une table générative de 45 combinaisons).
- `plugin/conductor/scripts/scaffold-docs.sh` (**G2**, étendu 89 → 186 L) +
  `tests/test-scaffold-docs.sh` (neuve, **26 cas** — le scaffolder n'avait aucune suite).
- `plugin/dev-orchestrator/references/mission-contracts.md` (bullet « NE charge PAS »),
  `mission-flow.md` (renvoi), `_index.md` (neuf, 11 entrées) ;
  `plugin/conductor/references/team-kernel.md` (règle Édition-à-la-source, **G5**) ;
  `plugin/reference/content/methodology/patterns/03-agents.md` + miroir `docs/` (**G1** doctrine).
- `plugin/validator/AGENT.md` — 9e signal de la grille de dette documentaire, **à coût de densité
  nul** (250 → 250 lignes, retrait pris sur le texte d'exemple, aucun signal sacrifié).
- 4 triades de module bumpées : validator v1.3.3, conductor v1.22.0, dev-orchestrator v2.14.0,
  reference v2.5.3. Compteur « N suites » **re-dérivé** 52 → 54 dans les deux README.

---

## Prohibitions de phase — vérifiées, pas affirmées

| Prohibition | Preuve |
|---|---|
| D-03 — zéro régression `dag.sh --scope` | `dag.sh` et `test-dag.sh` **absents du diff de toute la branche** ; `test-dag.sh` **99/99** rejoué à chaque étage |
| Jamais de release racine | `VERSION`, `plugin.json`, `marketplace.json` hors diff ; `check-version-sync.sh` rc=0 |
| ADR-029 densité | `vf-dev-manager.md` **250** · `validator/AGENT.md` **250** |
| ADR-031 — le gate constate, ne corrige jamais | aucun mode `--update/--fix/--write` ; **aucun des 13 findings du gate n'a été corrigé** |
| ADR-055 — `.planning/` non restructuré | ajouts seuls ; aucune écriture des scripts sous `.planning/` |
| ADR-054 — bash portable | ni `jq`, ni `grep -P`, ni `sed -i`, ni `stat -f`, ni `readlink -f` |
| Label de méthodologie externe | 0 occurrence sous `plugin/` et `docs/` |
| D-01 / D-02 — G4 et gains secondaires | aucun inscrit au ledger ni livré |

**Suites finales** : `test-check-map-drift.sh` 51/51 · `test-scaffold-docs.sh` 26/26 ·
`test-dag.sh` 99/99 · `test-check-doc-drift.sh` 21/21 · `test-check-agents.sh` 81/81 ·
`test-dev-orchestrator.sh` 184/184.

---

## Le fait marquant de la mission : 4 défauts de la même famille sur `normalize_path()`

`p2_sens_b` de `check-map-drift.sh` a produit quatre défauts successifs de la même classe, **chacun
trouvé par un juge externe, jamais par sa propre suite** :

| Tour | Correctif | Défaut suivant |
|---|---|---|
| 0 | comparaison par suffixe de basename | faux **négatif** (`refs/orphan.md` masqué par `refs/sub/orphan.md`) |
| 1 | comparaison stricte de chemins résolus | faux **positif** sur `./a.md` |
| 2 | strip d'un `./` de tête | faux **positif** sur `.//a.md` |
| 3 | `normalize_path()`, deux passes indépendantes | faux **positif** sur les formes combinées `//./a.md` |
| 4 | **point fixe** + preuve **générative** | classe fermée : 10/45 rouges avant, 0/45 après |

**Décision de méthode, prise en mission et assumée** : le budget de 3 tours a été **dépassé
délibérément** au tour 4, parce que le correctif y devenait précisément spécifié (ce n'était plus
de l'exploration) et parce que la **méthode de preuve** changeait. Les trois premiers tours
prouvaient la couverture par une **liste de formes énumérées** — et trois fois, le défaut vivait
dans une forme absente de la liste. Le tour 4 prouve par **génération** (produit cartésien
9 préfixes × 5 corps, propriété d'idempotence `f(f(x)) == f(x)`).

**Leçon durable** : une liste de cas ne ferme jamais une classe d'équivalence. Quand un correctif
remplace une comparaison tolérante par une comparaison stricte, il faut énumérer ce que la version
tolérante acceptait *par accident* — ou mieux, prouver la propriété par génération.

---

## Reprise sur verdict humain (2026-08-15) — les 3 points, tranchés et appliqués

| Point | Verdict de Samuel | Livré |
|---|---|---|
| Gate | **UTILE**, resserrer 2 bornes | `8cf5198` + `423671f` — gate de **13 → 3 findings** |
| `docs/_transverse/` | **SUPPRIMER** (repo de distribution, pas un lab) | supprimé, aucun `git rm` nécessaire |
| `skip_checkpoints` | **`false` maintenant** | `8cbf71b` — 3e vecteur neutralisé |

**Borne (a)** — « une ligne de commande n'est pas un chemin déclaré » : implémentée comme **classe**
(`is_command_invocation()`), pas comme liste noire des deux chaînes observées — une liste noire
aurait été un filtre de sortie déguisé, contraire à l'instruction.
**Borne (b)** — `plugin/reference/content/examples/` exclu **avant** toute production de finding, sur
les deux collectes (P1 et P2) ; contre-épreuve posée : `examples-reels/` reste balayé.
**Les 3 findings restants (`docs`, `manual`, `reports`) n'ont PAS été corrigés** dans les cartes :
signal assumé, conformément au verdict. Aucun `CLAUDE.md` touché de toute la mission.
**STRIDE `T-29-02-08`** ajouté : `../` initial mitigé dans `p2_sens_a` ; résidu non-initial
(`sub/../../x.md`) accepté **`low`** — fermeture complète non triviale sous ADR-054 (qui interdit
`realpath`), un rétrécissement partiel (`../*` → `*../*`) reste possible pour un futur tour.

### Deux défauts trouvés pendant la clôture — la vérification a payé

1. **Suite rouge en permanence** (`test-check-map-drift.sh`) : le cas « Borne (a) sens 1 » attestait
   son rouge contre `git show HEAD:…`. **`HEAD` est mutable** — dès que le commit du correctif est
   devenu HEAD, le test comparait le script à lui-même et sortait `ko` pour toujours (56 ok / 1 ko).
   Le worker avait rapporté « 57/57 » en toute bonne foi : il avait rejoué la suite **avant** son
   propre commit. Corrigé en figeant le SHA (`0f8fa3a`), avec balayage de la classe — aucune autre
   référence mutable dans le fichier.
2. **Doc périmée par sa propre phase** : `plugin/conductor/CHANGELOG.md` décrivait `v1.22.0` avec
   « 51 cas », état intermédiaire figé **avant** les tours 5-6. Rattrapé par le nœud `docs` (57 cas
   re-dérivés, les deux bornes, la mitigation STRIDE) — sans re-bump, `v1.22.0` n'étant pas publiée.

**Leçon transverse** : rejouer une suite **avant** le commit qui la modifie ne prouve rien. Toute
attestation doit référencer un SHA **figé**, et toute mesure doit être prise **après** le commit.

---

## Bilan de la vérification : 6 passes de juge, 6 défauts réels

Sur `check-map-drift.sh`, **chaque passe de juge a trouvé un défaut réel — 6 sur 6**, aucun n'ayant
été trouvé par la suite du worker. Aucune de ces passes n'était superflue. C'est l'argument le plus
net de cette mission en faveur de la revue systématique sur coût d'erreur asymétrique : le fichier
est distribué à tous les labs, et son mode d'échec est le **silence** (un gate qui se tait passe
pour vert).

---

## Historique du checkpoint (état au moment de l'arrêt)

1. **Verdict « utile ou bavard »** sur les **13 divergences réelles** rendues par
   `check-map-drift.sh --path .` (code 0), sur 3 cartes balayées :
   - `./CLAUDE.md` : 2 entrées déclarées sans contrepartie (`bash scripts/check-release-tag.sh --remote`,
     `git config core.hooksPath scripts/hooks` — des **commandes**, pas des chemins : piste de borne à
     resserrer côté extraction) ; éléments suivis non cités : `docs`, `manual`, `reports`.
   - `plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md` : 3 entrées sans contrepartie ;
     5 éléments suivis non cités.
   Le réglage, s'il en faut un, se fait dans les **bornes** du gate — jamais en filtrant sa sortie.
2. **Sort de `docs/_transverse/`** (untracked : `INDEX.md`, `REFERENCE.md`, `CONTEXT.md`). Origine
   tranchée par reproduction : ce n'est **pas** une évasion de bac à sable de la suite (innocentée
   sur clone frais) mais une exécution manuelle non sandboxée de `scaffold-docs.sh` à la racine
   pendant la vague 2. Le défaut d'atomicité qui l'a rendue possible **a été corrigé** (`--index`
   valide ses arguments avant toute écriture). Reste à décider : supprimer, ou adopter le pattern
   ADR-042 pour vibeflow-os lui-même. Non supprimé en autonomie.
3. **Oracle d'existence par traversée** dans `p2_sens_a` (`check-map-drift.sh`) : une citation
   d'index contenant `../` est testée par `[ ! -e "$target" ]`, révélant l'existence d'un chemin
   hors `$ROOT`. Sévérité **low**, absent du registre STRIDE des plans 29-02/29-04, reproduit par
   l'audit. Non corrigé en autonomie (ADR-031) — c'est un ajout au threat model, pas un bug de
   plan.

---

## Observation d'outillage — tranchée

`.planning/config.json` portait `parallelization.skip_checkpoints: true`, **troisième vecteur**
d'auto-approbation de checkpoint à côté des deux drapeaux de mon protocole
(`workflow._auto_chain_active`, `workflow.auto_advance`, déjà à `false`). L'arrêt avant T-29-05-3
avait été garanti par la **borne explicite du mandat** (« tâches 1 et 2 seulement »), pas par la
configuration — une garantie de rédaction, pas de machine. Sur verdict de Samuel, le drapeau est
passé à **`false`** (`8cbf71b`) : **les trois vecteurs sont désormais neutralisés**, et la doctrine
« checkpoint toujours gaté humain » est enfin tenue par la configuration elle-même.

---

## État final et gestes humains restants

**34 commits**, arbre propre (seuls `.gsd/` et les fichiers de verrou restent untracked).
Gates finaux rejoués **après** le dernier commit : `check-version-sync.sh` rc=0 (17 modules,
54/54 suites) · `check-agents.sh --strict` 12/12 verts · `check-map-drift.sh --path .` 3 findings
légitimes, rc=0 · 6 suites : **57 / 26 / 99 / 21 / 81 / 184, zéro échec**.

**Réservé à Samuel** (gestes humains gatés, non exécutés) :
1. `git push` de la branche `docs/phase-29-icm-gains` ;
2. ouverture de la PR ;
3. **release racine** — `VERSION`, `plugin.json`, `marketplace.json` intouchés par la phase. Quatre
   modules attendent leur distribution : validator **v1.3.3**, conductor **v1.22.0**,
   dev-orchestrator **v2.14.0**, reference **v2.5.3**. Rappel du `CLAUDE.md` : toute release = un
   tag annoté **plus** une release GitHub, gate `check-release-tag.sh --remote`.
