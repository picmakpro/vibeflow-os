# Codebase Concerns

**Analysis Date:** 2026-07-26

> Réécriture complète — la version du 2026-06-04 est périmée. Sa dette majeure a été traitée par
> l'enforcement CI v2.32.0+ : **37 suites de tests** découvertes dynamiquement par
> `.github/workflows/ci.yml:32`, `check-agents.sh --strict` sur chaque `plugin/*/agents`
> (`ci.yml:66-76`), gate `scripts/check-version-sync.sh` (9 points de contrôle, ADR-054).
> `infrastructure-audit` a désormais sa suite (`plugin/infrastructure-audit/scripts/tests/test-audit-infra.sh`),
> le résolveur de dépendances existe et est testé (`plugin/_internal/resolve-deps.sh` +
> `plugin/_internal/tests/test-resolve-deps.sh`). Ne pas reporter l'ancienne liste.

## Tech Debt

**`update` ne converge pas le contenu — pas de manifeste des chemins posés** — Sévérité : **HIGH**
- Issue: `vibeflow-update.sh update` re-matérialise le contenu du module mais **ne supprime jamais**
  les fichiers que la nouvelle version ne livre plus. Vécu terrain (update machine 2.23.0 → 2.36.0) :
  les 12 verbes-façades de dev-orchestrator v1.x ont survécu dans `~/.claude/skills/` et ressuscité
  le double catalogue tué par la bascule agentique v2.33.0 — nettoyage manuel.
- Files: `plugin/_internal/vibeflow-update.sh` (fonction `install_module`, aucune écriture de
  manifeste) ; capturé dans `.planning/BACKLOG.md:3-12`
- Impact: chaque lab mis à jour peut garder des skills/scripts fantômes qui contredisent la version
  courante (régression de doctrine silencieuse).
- Fix approach: manifeste des chemins posés par module à l'install
  (`.claude/scripts/.vibeflow-manifest-<module>`) ; `update` supprime les chemins de l'ancien
  manifeste absents du nouveau (avec backup). Test : update d'un module dont une skill a disparu.

**Divergence de doctrine distribuée — lexique vs VIBEFLOW_CORE** — Sévérité : **HIGH**
- Issue: les intitulés des principes P3–P8 divergent entre les deux documents canoniques livrés aux
  labs. `lexique.md` : P3 Specialiser, P4 Orchestrer, P5 Verifier, P6 Iterer, P7 Transposer,
  P8 Evaluer. `VIBEFLOW_CORE.md` v4.2 : P3 Orchestrer et executer, P4 Clarifier avant d'executer,
  P5 Verifier en boucle, P6 Iterer par cycles courts, P7 Transposer pas copier, P8 Evaluer la
  qualite cognitive. Toute référence « P4 » pointe donc sur deux principes différents selon la source.
- Files: `plugin/reference/content/methodology/vocabulary/lexique.md:18-26` vs
  `plugin/reference/content/methodology/VIBEFLOW_CORE.md:90-144`
- Impact: agents et blueprints citent P-numéros (ex. `business-pilot-bundle` trace « EVAL-XXX (P8) ») —
  le sens dépend du document lu. Signalée le 2026-07-26, **non arbitrée**.
- Fix approach: arbitrer la numérotation canonique (CORE v4.2 probable), aligner `lexique.md`,
  puis greper tous les `P[1-9]` du repo pour vérifier la cohérence.

**`docs/reference/` doublon divergent de `plugin/reference/content/`** — Sévérité : **MEDIUM**
- Issue: 4 fichiers diffèrent entre les deux arborescences : `README-CLIENT.md`, `VERSION.md`,
  `methodology/patterns/README.md`, `methodology/vocabulary/lexique.md` (vérifié `diff -rq` le
  2026-07-26).
- Files: `docs/reference/` vs `plugin/reference/content/` ; flagué « poids mort » dans
  `reports/audit/2026-07-25-audit-complet.md:73` et `:143` (item 7) — toujours non traité.
- Impact: deux vérités pour la même doc méthodologique ; le module `reference` installe
  `plugin/reference/content/`, `docs/` est la copie qui dérive.
- Fix approach: supprimer `docs/reference/` ou le réduire à un pointeur vers le module ; sinon gate
  d'identité dans la CI.

**`check-agents.sh --strict` sans périmètre tiers** — Sévérité : **MEDIUM**
- Issue: exécuté sur `~/.claude/agents` (scope user), le gate remonte 66 non-conformités — toutes
  sur des agents `gsd-*` (chaîne tierce hors charte ADR-044). Faux positifs massifs qui rendent le
  verdict inutilisable hors baseline repo.
- Files: `plugin/conductor/scripts/check-agents.sh` ; capturé dans `.planning/BACKLOG.md:14-21`
- Impact: le gate ne peut pas servir de sanity check post-install sur une machine réelle.
- Fix approach: exclusion de préfixes tiers (`--exclude-prefix=gsd-`) ou lecture d'un
  `.vibeflow-charter-scope` — cohérent avec la leçon UAT « baseline vs lab ».

**`validator/AGENT.md` à 249/250 lignes (plafond ADR-029)** — Sévérité : **MEDIUM**
- Issue: l'agent est à 1 ligne du plafond densité. Tout ajout (nouveau contrôle Phase 4, nouvelle
  escalade) exige d'abord un délestage vers `references/` ou une skill.
- Files: `plugin/validator/AGENT.md` (249 lignes, `wc -l` du 2026-07-26)
- Impact: chaque évolution du validator devient une opération de refactoring, pas un simple ajout.
- Fix approach: délester préventivement les sections les plus verbeuses vers
  `plugin/validator/references/` avant la prochaine évolution. Même famille :
  `plugin/skill-creator/skills/skill-creator/SKILL.md` à 485/500 lignes.

**Résolution des `requires[]` opt-in seulement** — Sévérité : **MEDIUM**
- Issue: la fermeture transitive existe (`plugin/_internal/resolve-deps.sh`, câblée et testée) mais
  uniquement via `install --with-deps <module>` (`vibeflow-update.sh:759-768`). Un
  `install <module>` nu n'installe **ni ne signale** les `requires[]` manquants (0 occurrence de
  `requires` dans l'engine). `uninstall` ne vérifie pas non plus les dépendances inverses : on peut
  désinstaller `consolidator` alors que `validator` installé le requiert.
- Files: `plugin/_internal/vibeflow-update.sh:755-771` (dispatch install), `:611` (`uninstall_module`) ;
  `requires[]` déclarés dans `plugin/*/module.json` (ex. `plugin/validator/module.json`)
- Impact: install partiel silencieux → module qui échoue au runtime ; désinstallation qui casse un
  module resté en place.
- Fix approach: au minimum un warning listant les `requires[]` non installés sur `install` nu ;
  refus (ou `--force`) sur `uninstall` d'un module requis par un module installé.

**Backlog avec déclencheur consommé, non ré-arbitré** — Sévérité : **LOW**
- Issue: l'item « Skill-installer global » avait pour déclencheur la clôture du milestone Install UX —
  atteinte le 2026-06-05 ; l'item a dormi 7 semaines déclencheur consommé.
- Files: `.planning/BACKLOG.md:36-38`
- Impact: le backlog perd sa valeur de radar si les déclencheurs ne sont pas honorés.
- Fix approach: ré-arbitrage explicite (reprendre / re-différer avec nouveau déclencheur / abandonner).

## Known Bugs

Aucun bug ouvert confirmé sur disque au 2026-07-26. Les comportements gênants connus (survie de
fichiers à l'update, faux positifs check-agents hors baseline) sont des limites de conception
capturées au backlog — voir Tech Debt.

## Security Considerations

**Nom de module non assaini dans l'engine** — Sévérité : **LOW**
- Risk: `install_module` valide seulement `[ -d "$CACHE_DIR/$mod" ]` — un nom contenant `../`
  résoudrait hors cache. Exposition faible : l'appelant prod est le skill `/vibeflow-install` qui
  passe des noms issus du catalogue, et le cache est local.
- Files: `plugin/_internal/vibeflow-update.sh` (`install_module`, garde `-d` uniquement)
- Current mitigation: `err` si le dossier n'existe pas ; noms fournis par le catalogue en prod.
- Recommendations: rejeter tout nom contenant `/`, `..` ou espace au parsing des positionnels.

**Pas de filtrage de secrets dans la copie d'install** — Sévérité : **LOW**
- Risk: l'engine copie des arborescences de modules vers `.claude/` sans filtre de motifs
  (`.env*`, clés). Exposition faible car la source est le cache du plugin packagé, pas le lab.
- Files: `plugin/_internal/vibeflow-update.sh` (copies `cp` dans `install_module`)
- Current mitigation: source contrôlée (cache = contenu du repo publié).
- Recommendations: garde ceinture-bretelles excluant `*.env*` / `*secret*` des copies.

## Performance Bottlenecks

Rien de bloquant identifié à l'échelle actuelle (registres de labs de quelques centaines
d'entrées ; scripts bash + python3 stdlib). Les anciens points (O(n²) de
`plugin/consolidator/scripts/detect-duplicates.sh`, chargement mémoire de `reindex.sh`) restent
vrais dans le code mais sans impact observé — sévérité **LOW**, ne pas prioriser.

## Fragile Areas

**Modules `mobile-test` / `mobile-test-team` expérimentaux — « run réel vert » jamais tracé** — Sévérité : **HIGH**
- Files: `plugin/mobile-test/module.json:5` et `plugin/mobile-test-team/module.json:5` (« Statut
  expérimental jusqu'au premier run réel vert ») ; `plugin/mobile-test/README.md:10`,
  `plugin/mobile-test-team/README.md:11` (bandeaux ⚠️)
- Why fragile: le pipeline (`plugin/mobile-test/scripts/mobile-test-run.mjs`, 409 lignes, Node) et
  l'orchestration de sous-agents imbriqués (Pattern 12, `plugin/mobile-test-team/agents/`) n'ont
  jamais été prouvés par un run réel documenté depuis leur import. Aucun rapport horodaté dans
  `reports/`.
- Safe modification: ne pas étendre ces modules avant un run réel vert tracé (rapport commis) ;
  toute release qui les touche doit le mentionner comme non-validé.
- Test coverage: **zéro** — voir Test Coverage Gaps.

**Chiffres en prose non gatés — la famille de dérive n'est pas éteinte** — Sévérité : **MEDIUM**
- Files: `README.md:169-182` et `README.fr.md:171-187` (tableau des modules, colonne version) —
  actuellement alignés (vérifié 2026-07-26) mais **hors périmètre** de
  `scripts/check-version-sync.sh` (ses 9 points couvrent badges, phrase « N modules », triade
  VERSION↔module.json, en-têtes Version des README de modules, historique en tête, compte de
  suites — pas la colonne version du tableau racine).
- Why fragile: c'est exactement la dérive F1 (13 modules mensongers) qui a motivé le gate ; l'audit
  du 2026-07-26 a encore trouvé 14/14 en-têtes Version faux avant que le point 8 du gate ne les
  couvre. Tout compteur en prose hors gate finit par mentir.
- Safe modification: à chaque nouveau chiffre en prose dans un README, soit le gater dans
  `check-version-sync.sh`, soit le remplacer par un renvoi vers la source machine.
- Test coverage: le gate lui-même n'a pas de suite (voir Test Coverage Gaps).

**Greps du gate sensibles aux reformulations README** — Sévérité : **LOW**
- Files: `scripts/check-version-sync.sh:60-71` (phrases « N modules, each versioned » /
  « N modules, chacun versionné » cherchées littéralement)
- Why fragile: une refonte éditoriale des README casse le grep ; le gate signale désormais la cible
  introuvable (ko explicite, leçon du contrôle sauté en silence) mais chaque refonte impose de
  réaligner les motifs.
- Safe modification: après toute refonte README, lancer `bash scripts/check-version-sync.sh` en local.

## Scaling Limits

**Découverte de suites CI limitée au motif `*/tests/test-*.sh`** — Sévérité : **MEDIUM**
- Current capacity: 37 suites bash découvertes (`.github/workflows/ci.yml:32`).
- Limit: tout test non-bash est invisible — `plugin/mobile-test/scripts/mobile-test-run.mjs` (Node)
  ne peut structurellement pas être couvert par ce pipeline.
- Scaling path: soit un wrapper bash `tests/test-mobile-test-run.sh` qui invoque le `.mjs` en mode
  dry-run, soit élargir la découverte CI.

## Dependencies at Risk

**`python3` et `jq` supposés présents, non vérifiés à l'install** — Sévérité : **LOW**
- Risk: plusieurs scripts consomment `python3` (consolidator, check-agents) et `jq`
  (resolve-deps a un fallback sed, mais pas tous les consommateurs) sans check de présence à
  l'install d'un module.
- Impact: échec runtime tardif sur machine minimale. Atténué : la CI « fresh lab » (`ci.yml:116+`)
  valide le parcours complet sur runner standard, et `check-version-sync.sh` évite volontairement jq.
- Migration plan: `verify_dependencies()` dans l'engine ou dans `plugin/installer/scripts/preflight.sh`
  (qui existe déjà — vérifier son périmètre et le câbler systématiquement).

## Missing Critical Features

**Phase 13 en suspens — plan écrit, rien d'exécuté** — Sévérité : **MEDIUM** (dette de process, pas de code)
- Problem: le plan 13-01 (`discover-unintegrated-docs.sh`, BRDG-02) est écrit et committé mais
  **non exécuté** (0 SUMMARY) ; le plan 13-02 (câblage de l'ingestion dans l'agent `vibeflow-dev`)
  reste à planifier.
- Files: `.planning/phases/13-pont-spec-feuille-de-route/13-01-PLAN.md` ; `.planning/STATE.md:6-8`
  et `:30-36` (stopped_at + Current Position)
- Blocks: la promesse « pont spec → feuille de route » du milestone vf-routing (dernière phase du
  milestone, 2/3 complétées). Prochaine action documentée : `/gsd:execute-phase 13`.

**Milestone `gsd-migration` ouvert et en attente** — Sévérité : **LOW**
- Problem: Phases 10-11 (étude + intégration migration GSD) créées le 2026-07-25, chantier
  indépendant jamais démarré.
- Files: `.planning/MILESTONES.md:41` ; `.planning/phases/10-etude-migration-gsd/`,
  `.planning/phases/11-integration-migration-gsd/`
- Blocks: rien de bloquant (explicitement non bloquant dans STATE.md) — mais à arbitrer pour que le
  milestone ne devienne pas un item de backlog fantôme.

## Test Coverage Gaps

**Les gates de release eux-mêmes n'ont aucune suite** — Priority: **HIGH**
- What's not tested: `scripts/check-version-sync.sh` (9 points, parsing grep/sed volontairement
  sans jq), `scripts/check-release-tag.sh`, `scripts/bump.sh`. Le dossier `scripts/` n'a pas de
  `tests/` — la découverte CI (`find plugin scripts -path '*/tests/test-*.sh'`) n'y trouve donc rien.
- Files: `scripts/bump.sh`, `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh`
- Risk: une régression dans un gate (grep qui ne matche plus, faux vert) neutralise silencieusement
  la protection anti-dérive — la classe de bug la plus coûteuse de l'historique du repo (divergence
  main juillet 2026). Ironique : tout le reste est gaté par eux.
- Priority: **HIGH** — suite `scripts/tests/test-check-version-sync.sh` sur fixtures (README/VERSION
  synthétiques désalignés → le gate doit ko).

**`mobile-test-run.mjs` — 409 lignes Node, zéro test** — Priority: **HIGH**
- What's not tested: détection de cible, build-if-absent, rapport horodaté, diagnostic sur échec.
- Files: `plugin/mobile-test/scripts/mobile-test-run.mjs` (aucun `tests/` dans le module)
- Risk: module déjà expérimental + script central non testé = régression invisible garantie ; hors
  motif de découverte CI (voir Scaling Limits).
- Priority: **HIGH** — préalable au « premier run réel vert » qui lèverait le statut expérimental.

**`plugin/installer/scripts/preflight.sh` non couvert** — Priority: **MEDIUM**
- What's not tested: le preflight d'install (la suite du module, `test-build-module-catalog.sh`, ne
  le référence pas ; aucune mention dans `plugin/_internal/tests/`).
- Files: `plugin/installer/scripts/preflight.sh`
- Risk: un preflight cassé laisse passer des installs sur environnement non conforme.

**`mobile-test-team` — orchestration Pattern 12 jamais éprouvée** — Priority: **MEDIUM**
- What's not tested: la boucle test → corrige → re-test (vf-test-orchestrator + workers
  vf-test-runner / vf-app-fixer). Les agents passent `check-agents.sh --strict` (conformité de
  forme) mais aucun run d'orchestration n'est tracé.
- Files: `plugin/mobile-test-team/agents/`, `plugin/mobile-test-team/README.md:11`
- Risk: le module vend une capacité autonome non démontrée.

---

*Concerns audit: 2026-07-26 — v2.36.1, 17 modules, 37 suites CI*
