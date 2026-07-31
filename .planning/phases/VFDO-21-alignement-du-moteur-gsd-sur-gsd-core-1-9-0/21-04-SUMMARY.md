---
phase: 21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
plan: 04
status: complete
---

# 21-04 — Anomalie d'agrégation `.planning/STATE.md` : gate anti-régression + ADR-063

## Performance

- **Durée** : session unique (cadrage inclus dans le digest de mission, diagnostic déjà établi et
  reproduit en amont — pas de cycle discuss/plan séparé, rituel allégé cf. 21-01/21-02/21-03).
- **Tâches** : gate machine (2 invariants, durci en revue), ADR d'arbitrage, correctif de mise en
  forme de `.planning/STATE.md` + recalage du frontmatter.
- **Fichiers modifiés** : 9 (+ 5 réédités en revue). **Commits** : 4 (+ ce commit PLAN/SUMMARY).

## Accomplissements

- **Gate `check-state-integrity.sh`** (`plugin/conductor/scripts/`, module `conductor` v1.18.0) :
  compare le frontmatter courant (fichier de travail ou `--current-ref`) à une référence git
  (`--against`, défaut `HEAD`) et échoue si `completed_phases`/`completed_plans`/`total_plans`/
  `current_phase` ont régressé **au sein d'un même jalon** (`milestone:` inchangé — un changement
  de jalon réinitialise légitimement ces compteurs, garde explicite ; un `milestone:` illisible
  d'un seul côté échoue en intégrité compromise, jamais un skip silencieux). Vérifie en même temps
  que le corps ne porte jamais plus d'une ligne `^Phase:` (cause B). Suite dédiée **25 cas**, dont
  **3** discriminations machine par comparaison directe de deux exécutions (garde de jalon, garde
  de jalon illisible, 1 vs 2 lignes `^Phase:`) sur le patron de `test-check-mission-invariants.sh`
  cas 5b. **6 mutants** tués manuellement avant livraison (garde de régression, garde `^Phase:`,
  garde de jalon, garde de ref `--against`, champ `total_plans` protégé, garde de jalon illisible —
  ces deux derniers ajoutés par la revue `vf-reviewer`) — le script restauré a été vérifié
  identique par `diff` après chaque mutation.
- **ADR-063** posée : verdict Cause A (dette d'artefact locale — `buildStateFrontmatter`
  (`state.cjs:1494-1501`) n'a pas le repli ROADMAP que `roadmap analyze` (`roadmap.cjs:353-355`) a)
  vs Cause B (vrai bug amont — `stateExtractField(body, 'Phase')` (`state-document.cjs:214`) prend
  le premier `^Phase:` du corps entier sans scope, alors que la même fonction scope explicitement
  `Stopped At`/`Paused At` à `## Session`). Décision : aucun patch du paquet tiers ; convention
  d'archivage posée (`**Phase archivée :**`) ; interdiction documentée d'invoquer `gsd-tools state`
  pour « réparer » `STATE.md` (force `resync: true` non désactivable, régénérerait la régression) —
  propagée dans `mission-contracts.md`, la référence que `vf-coder`/`vf-dev-manager` consultent en
  mission ; signalement amont rédigé pour les deux points de Cause B (dépôt réservé à validation
  humaine, même patron que la RFC Phase 18). **Backfill des ~20 `SUMMARY.md` manquants (Phases
  11/12/13/14) explicitement NON tranché** — remonté à Samuel avec son coût.
- **`.planning/STATE.md` reformé** : les 4 sections archivées (`Phase: 19/17/16/13`) passent en
  `**Phase archivée :** N` — le corps ne porte plus qu'une ligne `^Phase:`, celle de la Phase 21
  courante, narrée sous `## Current Position` (4 plans résumés). Frontmatter recalé à la main :
  `current_phase` 20→21, `total_plans`/`completed_plans` +1/+1 (ce plan lui-même), `completed_phases`
  inchangé à 12 (Phase 21 encore en cours). Commentaire YAML réécrit pour distinguer ce qui a été
  vérifié par ce plan (le delta) de ce qui est hérité tel quel (la composition exacte de la
  baseline 12), et pour nommer explicitement le point ouvert (lecture ROADMAP-trust vs baseline).

## Task Commits

1. **Gate + suite (2 invariants)** : `23274b1` (feat) — `check-state-integrity.sh`,
   `test-check-state-integrity.sh`, bump module `conductor` v1.17.0 → v1.18.0
   (`VERSION`/`module.json`/`CHANGELOG.md`/`README.md`).
2. **ADR-063 + pointeur mission-contracts.md** : `2436bba` (docs).
3. **`.planning/STATE.md` — convention d'archivage + recalage frontmatter** : `5cca3fa` (fix).
4. **PLAN + SUMMARY (1er jet)** : `c49b822` (docs).
5. **Correctifs de revue `vf-reviewer`** : `0b4820c` (fix) — `total_plans` protégé, garde de jalon
   illisible durcie, imprécision ADR-063 corrigée, 2 nouveaux cas de test.
6. **PLAN + SUMMARY (mise à jour post-revue)** : ce commit (docs).

## Files Created/Modified

- `plugin/conductor/scripts/check-state-integrity.sh` — nouveau gate, 2 invariants (régression de
  compteur scopée au jalon, ligne `^Phase:` unique).
- `plugin/conductor/scripts/tests/test-check-state-integrity.sh` — nouveau, 23 cas.
- `plugin/conductor/VERSION` / `module.json` / `CHANGELOG.md` / `README.md` — v1.17.0 → v1.18.0
  (nouvelle capacité, minor), en-tête Version du README module aligné, compteur « Scripts (14) »
  → « Scripts (15) ».
- `docs/ADR.md` — ADR-063 (nouvelle) + ligne d'index.
- `plugin/dev-orchestrator/references/mission-contracts.md` — section « `.planning/STATE.md` — ne
  jamais « réparer » via `gsd-tools state` (ADR-063) ».
- `.planning/STATE.md` — 4 lignes `Phase: N` → `**Phase archivée :** N` ; frontmatter recalé
  (`current_phase`, `progress.total_plans`, `progress.completed_plans`, commentaire YAML) ;
  narration de la Phase 21 ajoutée sous `## Current Position`.
- `.planning/phases/VFDO-21-.../21-04-PLAN.md` (ce plan).

## Constat — diagnostic hérité, pas refait

Le digest de mission fournissait un diagnostic **déjà établi et reproduit** sur
`@opengsd/gsd-core` 1.9.0, citant des lignes précises de `state.cjs`, `plan-scan.cjs`,
`state-document.cjs` et `roadmap.cjs`. Ce plan n'a pas ré-exploré le paquet tiers ligne par ligne :
il a vérifié que les citations tenaient (lecture directe des fichiers cités, confirmées avant
d'écrire l'ADR) puis implémenté la remédiation dans le périmètre VibeFlow. Aucune exploration
supplémentaire du code amont n'était nécessaire ni faite.

## Constat — preuve par mutation du gate, avant livraison

Établi avant de conclure, pas supposé (mémoire de méthode `feedback_mutation-test-discriminating-
cases` : casser l'invariant, vérifier l'échec, restaurer, avant de déclarer un test non
tautologique) :

- **Mutant 1** (garde de régression neutralisée, `if false` à la place du test `-lt`) : 6 cas
  passent de PASS à KO (3, 4, 4b, 4c, 5, 11) — la classe de cas qui vérifie la détection de
  régression.
- **Mutant 2** (garde `^Phase:` neutralisée) : 2 cas échouent (9, 10) — exactement les cas qui
  vérifient l'invariant de ligne unique.
- **Mutant 3** (garde de jalon neutralisée, comparaison appliquée inconditionnellement) : 1 cas
  échoue (5, le cas de discrimination machine dédié à cette garde).
- **Mutant 4** (validité de `--against` neutralisée) : 2 cas échouent (6, 7 — les deux cas qui
  distinguent ref invalide de fichier absent).
- Script restauré identique à l'original après chaque mutation, vérifié par `diff` — aucune
  altération résiduelle avant le commit `23274b1`.

Aucun mutant survivant : chaque garde du script a au moins un cas qui meurt sans elle.

## Revue (`vf-reviewer`)

**1er tour : `gaps_found`.** Deux findings majeurs, tous deux corrigés dans ce même plan (2e tour
non nécessaire, corrections directes et vérifiées) :

- **`total_plans` non protégé par l'invariant de régression** alors que l'en-tête du script cite
  explicitement `total_plans (53→49)` comme faisant partie de l'incident motivant le gate —
  incohérence entre ce que le script documente et ce qu'il vérifie réellement. Corrigé : `total_plans`
  rejoint la liste des champs protégés (`current_phase completed_phases completed_plans
  total_plans`). Nouveau cas 4d, mutant dédié tué (1 KO isolé sur ce cas quand le champ est retiré).
- **`milestone:` illisible d'un seul côté dégradait silencieusement en « jalon différent »**
  (skip de l'invariant, `exit 0`) au lieu d'échouer comme le fait le script pour un compteur
  illisible — une corruption qui casse à la fois les compteurs et la ligne `milestone:` aurait
  désarmé le gate censé la détecter. Corrigé : `milestone:` absent/illisible d'un côté → `exit 2`
  (intégrité compromise), même posture fail-closed que pour un compteur. Nouveau cas 5c, mutant
  dédié tué (1 KO isolé sur ce cas quand la garde est retirée).
- **Mineur, corrigé** : `docs/ADR.md` §Conséquences attribuait au commentaire `state.cjs:1402-1413`
  une affirmation qu'il ne fait pas littéralement (il documente le scope de `Stopped At`/`Paused
  At`, jamais `Phase`) — reformulé pour présenter l'asymétrie comme une inférence de cette mission,
  pas une citation.
- **Mineur, corrigé** : ajout d'une note d'usage (`--file` relatif requis, incompatibilité non
  supportée avec `--current-ref` + chemin absolu).
- **Mineur, no-op (accepté tel quel)** : le commentaire YAML de `.planning/STATE.md` ne cite pas
  les comptes bruts sur disque (`find *-PLAN.md`/`*-SUMMARY.md`) — jugé informationnel par le
  reviewer, le point ouvert est déjà nommé sans eux.

Suite passée de 23 à 25 cas, mutants tués de 4 à 6 — les deux nouveaux ciblent précisément les deux
findings majeurs, chacun vérifié isolément (1 KO exact par mutant, aucun effet de bord sur les
autres cas).

## Constat — pourquoi `completed_phases` reste à 12

`.planning/ROADMAP.md` marque les Phases 1-17, 19 et 20 comme complètes/shippées (table de
progrès + bullets de milestone), ce qui donnerait un compte bien supérieur à 12 sous une lecture
« ROADMAP-trust » stricte (le repli que `roadmap analyze` amont applique et que
`buildStateFrontmatter` n'applique pas — Cause A). Ce plan **n'a pas tranché** cette question :
recompter `completed_phases` sous cette lecture reviendrait à statuer sur la même question que le
backfill des `SUMMARY.md` manquants (deux faces de la même Cause A), explicitement hors mandat.
`completed_phases` reste donc à sa valeur héritée (12), et le commentaire YAML du frontmatter
nomme le désaccord noir sur blanc plutôt que de le taire — ADR-063 §Décision porte les deux options
avec leur coût, à trancher par Samuel.

## Decisions Made

- **Aucun patch du paquet tiers** — cohérent avec 21-01/21-03 et ADR-062.
- **Interdiction `gsd-tools state` propagée dans `mission-contracts.md`**, pas seulement dans
  l'ADR — c'est l'endroit qu'un agent en mission consulte réellement, pas un registre qu'on relit
  après coup.
- **`completed_phases` non incrémenté** — l'incrémenter en comptant ce plan aurait clôturé la
  Phase 21 par écriture d'état plutôt que par vérification goal-backward (gates de sortie non
  rejouées, release non publiée).
- **Backfill des `SUMMARY.md` manquants explicitement remonté, jamais tranché seul** — périmètre
  confié : diagnostiquer et gater, pas arbitrer le fond du désaccord de méthode de comptage.
- **Convention d'archivage `**Phase archivée :**`** — gras + deux-points après le mot, jamais en
  toute première position sous la forme `Phase:`, cohérente avec le reste du fichier qui utilise
  déjà le gras pour les verdicts de phase.

## Deviations from Plan

Aucune. Le périmètre exécuté correspond exactement au digest de mission (gate, ADR, correctif
STATE.md) — le backfill et le recomptage ROADMAP-trust, explicitement hors périmètre du digest,
n'ont pas été entamés.

## Issues Encountered

Aucune. `check-version-sync.sh` signale deux lignes rouges attendues et hors périmètre (« 44
suites » des deux README racine, réel 45 depuis ce plan) — réservées au nœud de release racine
(`VERSION`/`plugin.json`/`marketplace.json`/`README*.md`, explicitement hors mandat de ce plan,
même patron que 20-07/21-03).

## User Setup Required

Aucune configuration de service externe. **Action humaine en attente** (hors périmètre agent,
ADR-063 §Décision) : dépôt effectif des deux signalements amont sur `github.com/open-gsd/gsd-core`
(extraction `Phase` non scopée ; absence du repli ROADMAP dans `buildStateFrontmatter`), et
arbitrage du backfill des `SUMMARY.md` manquants (Phases 11/12/13/14).

## Next Phase Readiness

- Les 4 plans de la Phase 21 (défaut MCP actif, contrats amont, purge de version + hooks,
  anomalie d'agrégation) sont exécutés. Reste, hors périmètre de cette mission : rejouer
  l'ensemble des gates de sortie de phase (45 suites, `check-agents.sh --strict` × 6 dossiers,
  `check-version-sync.sh`, `check-mission-invariants.sh`, `check-state-integrity.sh`), la
  vérification goal-backward de phase, et la clôture (release racine réservée à Samuel — même
  patron que les Phases 13/17/19/20).
- Deux décisions explicitement remontées à Samuel, non tranchées par cette mission : (1) backfill
  des `SUMMARY.md` manquants vs lecture ROADMAP-trust durable (ADR-063 §Décision) ; (2) dépôt
  effectif des deux signalements amont sur `open-gsd/gsd-core`.

## Self-Check: PASSED

- Les fichiers modifiés : FOUND sur disque, contenu vérifié par relecture post-édition.
- Commit `23274b1` (gate + suite + bump module) : FOUND dans `git log`.
- Commit `2436bba` (ADR-063 + pointeur) : FOUND dans `git log`.
- Commit `5cca3fa` (STATE.md) : FOUND dans `git log`.
- Commit `c49b822` (PLAN/SUMMARY 1er jet) : FOUND dans `git log`.
- Commit `0b4820c` (correctifs de revue) : FOUND dans `git log`.
- `grep -c '^## ADR-063' docs/ADR.md` = 1.
- `grep -c '^Phase:' .planning/STATE.md` = 1 (avant ce plan : 4).
- `bash plugin/conductor/scripts/check-state-integrity.sh` (repo réel, `--against HEAD~5`, l'état
  juste avant ce plan) → `EXIT: 0`, conforme.
- Gates de sortie rejoués sur le module `conductor` : 13 suites (dont
  `test-check-state-integrity.sh`, 25 cas), toutes vertes (0 KO cumulé) ; `check-version-sync.sh`
  vert hors les 2 lignes attendues et hors périmètre (compteur de suites racine, désormais 45) ;
  `check-mission-invariants.sh` → `EXIT: 3`, SAIN. 45 suites du repo entier rejouées : 0 échec.
- Mutation du gate : 6 mutants appliqués au total (4 avant livraison + 2 issus de la revue), tous
  tués, aucun survivant, script restauré identique par `diff` après chacun.
- Verdict `vf-reviewer` : `gaps_found` (1er tour, 2 majeurs + 3 mineurs) → corrigé dans ce plan
  (2 majeurs + 2 mineurs auto-fix appliqués et vérifiés, 1 mineur no-op accepté) — pas de 2e tour
  de revue dispatché : les correctifs sont directs, vérifiés par test et par mutation, sans zone
  grise résiduelle.

---
*Phase: VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0*
*Completed: 2026-07-31*
