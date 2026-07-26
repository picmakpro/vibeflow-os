# Phase 11: Intégration migration GSD - Context (6 vagues)

**Gathered:** 2026-07-26 (mode transcription — cadrage déjà fait en Phase 10, aucune question
posée ; délégué par `vf-dev-manager` à `vf-coder` sous mandat `plan-11`, `AskUserQuestion`
indisponible)
**Status:** Ready for planning
**Portée de ce cadrage** : les 6 vagues (11-01 → 11-06) du plan de Phase 11 tel qu'arbitré en
Phase 10 (`10-APPROFONDISSEMENT.md` §5, révision finale). Aucun arbitrage n'est rouvert ici —
ce document **transcrit** les décisions déjà prises et les rend actionnables par
`gsd-plan-phase`/`gsd-planner`.

<domain>
## Phase Boundary

Source : `.planning/ROADMAP.md` §Phase 11 + `.planning/REQUIREMENTS.md` GSDM-04/05/06 +
`.planning/phases/10-etude-migration-gsd/10-APPROFONDISSEMENT.md` §5 (squelette non négociable
des 6 vagues).

Phase 11 livre, dans cet ordre strict (chaîne linéaire, une vague dépend de la précédente) :

1. **11-01 Bascule mécanique** — `ensure-deps.sh`, `detect-gsd-engine.sh`, `build-gsd-index.sh`
   basculent sur `@opengsd/gsd-core`, dual-layout (nouveau `gsd-core` prioritaire, legacy
   `get-shit-done` en fallback détecté), piège n°1 neutralisé (`command -v gsd-sdk` retiré de
   `detect_gsd()`), garde Node ≥ 22, `detect_gsd_legacy()` affiche (jamais n'exécute) les 3
   étapes de nettoyage manuel.
2. **11-02 Références SDK → gsd-tools** — `vf-auto/SKILL.md`, `references/mission-contracts.md`,
   whitelist `test-dev-orchestrator.sh` migrent `gsd-sdk query X` → `gsd-tools X` (mapping
   prouvé Phase 10 §0).
3. **11-03 Routage & frontières** — `AGENT.md` FIRST-02 route `gsd-onboard` sur brownfield,
   `intent-routing.md` gagne la ligne onboard + le canal 4 (non routé, une seule voix),
   `check-overlaps.sh` gagne 3 paires exactes, `test-dev-orchestrator.sh` T14 whitelist les
   briques intentionnellement non routées, **régénération + commit de l'index factuel**
   `gsd-skills-index.md` en toute fin de cette vague (jamais en 11-01 — voir Risque R-01).
4. **11-04 Cohabitation settings.json** — correctif `merge-hooks.sh` (matching ancré + fin de la
   co-location de groupes mixtes) + suite `test-gsd-cohabitation.sh` (T1-T5) + fixture
   `gsd-core-settings.json`.
5. **11-05 Doctrine modèles** — assertion `model_profile: balanced` dans la hygiène documentaire
   de `AGENT.md` (nouveau lab) + recette `migration-playbook.md` (`vf-calibrate`, lab existant,
   validation humaine) + phrase de frontière dans `GSD-PIPELINE.md`.
6. **11-06 Non-régression + docs (GSDM-06)** — dry-run 3 scopes + idempotence en isolé (vrai
   `~/.claude` jamais touché), purge de la référence legacy vivante (`PROJECT.md:61`),
   VERSION/module.json/CHANGELOG/README des 3 modules touchés (dev-orchestrator, planning-core,
   conductor), correctif du compteur de suites dans les 2 README racine (38 → 39).

**Ne produit PAS** (hors périmètre explicite du mandat) :
- Aucun bump de la `VERSION` racine, aucune modification de `plugin/.claude-plugin/plugin.json`
  ni `.claude-plugin/marketplace.json`, aucun tag git. Le critère ROADMAP « release bumpée + tag
  annoté poussé » (GSDM-06, dernière clause) est un **reste-à-faire post-plans**, réservé à
  validation humaine — précédent direct : Phase 13 (`13-CONTEXT.md` §Deferred), Phase 14
  (bump fait, mais dans un plan dédié `autonomous: false`).
- Aucune exécution des 6 plans (mandat = planification uniquement).
- Aucune installation réelle sur la machine (`npx`, `npm install/uninstall`, appel installeur
  gsd-core) — les tâches d'exécution utiliseront exclusivement un `HOME`/`CLAUDE_CONFIG_DIR`
  isolé (sandbox), jamais le vrai `~/.claude`.
- Aucune réimplémentation de la logique de `merge-hooks.sh`/`ensure-deps.sh`/etc. au-delà des
  correctifs de chemins/noms de paquet spécifiés — le reste du comportement (idempotence,
  fallback manuel jamais silencieux) est un invariant à préserver, pas à récrire.
</domain>

<decisions>
## Implementation Decisions

### R-01 — Résolution du risque « 11-01 et 11-03 doivent shipper ensemble »

`10-APPROFONDISSEMENT.md` §5 note : *« l'index régénéré inclut onboard/next/mempalace, donc le
test d'exhaustivité T14 casse si les frontières ne sont pas livrées dans la même release »*.
Le fichier `references/gsd-skills-index.md` est **committé** (auto-généré, `NE PAS ÉDITER` à la
main, mais versionné dans le repo — confirmé par lecture directe) et **T14 le lit depuis le
disque** (`INDEX_DISK="$REFS_DIR/gsd-skills-index.md"`, `test-dev-orchestrator.sh:213`), pas
depuis une machine réelle. Donc : si la vague 11-01 régénère et committe cet index (avec
`gsd-onboard`/`gsd-next`/`gsd-mempalace-*` dedans, posés par gsd-core) **avant** que 11-03 ait
ajouté leur routage, un commit intermédiaire sur `main` casse T14/CI.

**Décision (transcrite, pas re-arbitrée — c'est la lecture la plus stricte de la contrainte
énoncée en Phase 10)** : la régénération + le commit de `gsd-skills-index.md` sont **déplacés
dans la vague 11-03**, à la toute fin (après que la ligne onboard et le canal 4 soient posés).
La vague 11-01 modifie uniquement les **scripts** (`ensure-deps.sh`, `detect-gsd-engine.sh`,
`build-gsd-index.sh`) — jamais le fichier `gsd-skills-index.md` committé. Ainsi aucun commit
intermédiaire sur `main` ne porte un index désaligné avec le routage. Ce déplacement ne viole
pas le squelette figé des 6 vagues (leur contenu fonctionnel, pas leur ordonnancement, est
transcrit tel quel) — GSDM-05 (« l'index est régénéré depuis le nouveau binaire ») reste couvert,
juste positionné dans la vague qui le rend safe.

### R-02 — Chaîne de dépendance strictement linéaire (pas de parallélisation inter-vagues)

`vf-coder` doit rendre à `vf-dev-manager` la liste exacte des fichiers par vague pour trancher le
dispatch parallèle. Constat sur les fichiers réels (lus intégralement) : **11-02 et 11-03 touchent
tous deux `test-dev-orchestrator.sh`** (11-02 : whitelist ligne ~260 ; 11-03 : whitelist T14,
lignes ~540-570 — même fichier, sections disjointes mais un dispatch PARALLÈLE de deux agents sur
le même fichier est un risque de conflit d'écriture réel, pas seulement théorique). Le mandat
interdit de toute façon de réordonner/fusionner/scinder les 6 vagues : chaque vague est un plan,
`depends_on: [vague précédente]`, `wave:` = son rang (1 à 6). **Aucune parallélisation proposée**
— la chaîne est linéaire par construction, ce qui évacue le risque de conflit sans qu'il soit
besoin de le documenter en garde-fou d'exécution.

### D-01 — Détection dual-layout : réimplémentation locale, pas de fonction partagée

`detect-gsd-engine.sh` (planning-core, `requires: []`) et `ensure-deps.sh`/`build-gsd-index.sh`
(dev-orchestrator) ne peuvent pas partager de code (modules indépendants, aucune dépendance
déclarée entre eux — cf. le commentaire existant dans `detect-gsd-engine.sh:51` : *« Réimplémenté
localement et non sourcé »*). Chaque script porte donc **sa propre** fonction de résolution
dual-path (nouveau `gsd-core` prioritaire, `get-shit-done` legacy en repli), sur le même schéma :
1. env var explicite (si fournie par l'appelant/les tests) → gagne toujours, aucune détection ;
2. sinon, `~/.claude/gsd-core/...` si présent ;
3. sinon, `~/.claude/get-shit-done/...` (legacy) si présent ;
4. sinon, défaut = le chemin `gsd-core` (nomme le futur, pas le passé, dans les messages d'erreur).

Cette règle s'applique à **3 sites** : `GSD_HOME` (detect-gsd-engine.sh), `GSD_VERSION_FILE`
(ensure-deps.sh, détection de présence), `WORKFLOWS_DIR` (build-gsd-index.sh, source secondaire
optionnelle).

### D-02 — Piège n°1 : suppression pure, pas remplacement par un autre `command -v`

`detect_gsd()` dans `ensure-deps.sh` teste aujourd'hui `command -v gsd-sdk`. Le shim legacy
(`@gsd-build/sdk` sur le PATH) resterait vrai après migration → gsd-core ne s'installerait
**jamais**. La correction n'est PAS de tester un autre binaire sur le PATH (même piège possible
avec `gsd-core`/`gsd-tools`/`gsd_run` un jour) : `detect_gsd()` devient une détection **par
fichier VERSION uniquement** (dual-layout, D-01). Aucun `command -v` ne doit subsister dans cette
fonction — vérifiable par `grep -c 'command -v gsd' ensure-deps.sh` → 0 après la vague 11-01.

### D-03 — `detect_gsd_legacy()` : affichage seul, jamais d'exécution (ADR-031)

Nouvelle fonction dans `ensure-deps.sh` : si le VERSION file **legacy** existe (que le nouveau
existe aussi ou non — la coexistence n'est pas garantie propre), logue (stderr, jamais stdout
exécuté) les 3 commandes de nettoyage manuel, dans cet ordre exact (Phase 10, séquence de
transition) :
```
npm uninstall -g get-shit-done-cc
npm uninstall -g @gsd-build/sdk
rm -rf ~/.claude/get-shit-done
```
Ces 3 lignes ne sont **jamais** passées à `run_cmd`/exécutées, même en mode non-dry-run — c'est
une garantie machine à tester explicitement (le test lance le script en mode normal avec un faux
legacy VERSION file présent et un mock `npm`, puis vérifie qu'aucune des 3 commandes n'a été
invoquée, seulement loguée).

### D-04 — Garde Node ≥ 22

Ajout d'un contrôle de version Node avant la tentative d'install npx (comme le contrôle `command
-v npm` existant). Si Node < 22, ne PAS tenter l'install (échouerait probablement côté gsd-core) —
basculer directement sur l'étape manuelle avec message explicite (« Node ≥ 22 requis pour
`@opengsd/gsd-core` — version détectée : X »). Portable BSD/GNU : extraction du major via `node
-e "process.stdout.write(String(process.versions.node.split('.')[0]))"` (pas de `cut`/`awk`
fragiles sur le format `vX.Y.Z` qui varie selon la commande).

### D-05 — Mapping SDK → gsd-tools (Phase 10 §0, repris tel quel)

| Site actuel | Nouveau | Fichier(s) |
|---|---|---|
| `gsd-sdk query init.progress` | `gsd-tools init progress` | (aucun site vivant trouvé, mapping de référence) |
| `gsd-sdk query roadmap.analyze` | `gsd-tools roadmap analyze` | `vf-auto/SKILL.md:18`, `mission-contracts.md:72` |
| `gsd-sdk query state-snapshot` | `gsd-tools state json` (court) / `state load` (complet) | (aucun site vivant trouvé) |

Invocation canonique complète (à utiliser dans les fichiers de doctrine, pas un alias supposé) :
`node "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs" <cmd>`. Le fallback
documenté dans `mission-contracts.md` (« si l'outil est absent, compter les cases non cochées
via `grep -c '^- \[ \]'` ») est **conservé**, seule sa condition de déclenchement change : au lieu
de tester `command -v gsd-sdk`, la doctrine teste l'existence du fichier
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs`.

### D-06 — Whitelist T4/T14 : renommage, pas ajout

`test-dev-orchestrator.sh:260` porte `gsd-sdk) : ;;` dans le `case` de T4 (cibles connues non
skills). Après la vague 11-02, plus aucun fichier vivant du module ne référence `gsd-sdk` (tout
est passé à `gsd-tools`) : cette entrée devient un renommage `gsd-sdk` → `gsd-tools`, pas un
ajout à côté (pas de résidu mort dans la whitelist).

### D-07 — Onboard : router, pas remplacer

Verdict Phase 10 (`10-SOLUTIONS.md` #3) : `/gsd:onboard` gagne le **brownfield** (code déjà
présent), notre séquence manuelle (map-codebase → new-project) devient le **fallback** si le
skill `gsd-onboard` est absent de l'index factuel (labs legacy pas encore sur gsd-core, ou tout
simplement skill non installé). Terrain vierge (aucun code détecté) → `gsd-new-project` reste la
cible directe, inchangée. `AGENT.md` FIRST-02 est reformulé (pas réécrit intégralement) pour
distinguer les deux cas ; le marqueur `gsd-map-codebase` doit rester textuellement présent (T7 le
vérifie par grep, `has_mapcb`).

### D-08 — Canal 4 : `gsd-next` et `gsd-mempalace-*`, exact double-inscription

Verdicts Phase 10 (`10-SOLUTIONS.md` #1 et #4) : ne **jamais** router `gsd-next` (empilerait deux
routeurs, `vibeflow-dev` est déjà la front door du lab) ni `gsd-mempalace-capture`/
`gsd-mempalace-recall` (le consolidator reste le canon mémoire de lab, ADR-052 — mempalace est
opt-in, hors périmètre, jamais activé/répliqué). La règle du fichier `intent-routing.md` (§Comment
router / §Couverture) exige que toute exception soit écrite dans CE fichier — donc :
1. `intent-routing.md` gagne un nouveau canal 4 « Non routé — une seule voix (ADR-057) »,
   nommant explicitement `gsd-next` et `gsd-mempalace-capture`/`gsd-mempalace-recall` (noms de
   skills exacts, pas un glob `gsd-mempalace-*` — la table `check-overlaps.sh` ne supporte pas
   les globs, cf. D-09, et T14 fait un match littéral).
2. `test-dev-orchestrator.sh` gagne une liste distincte de `DESIGN_DELEGATED` (qui, elle, MARQUE
   une brique comme routée-ailleurs) : une liste `INTENTIONALLY_UNROUTED` — ces skills sont
   **exemptés** de l'obligation T14, pas déclarés routés. Sémantique différente, ne pas fusionner
   les deux listes.
**Vérification des noms exacts** : le nom exact des skills mempalace posés par gsd-core
(`gsd-mempalace-capture`/`gsd-mempalace-recall`, confirmé par la lecture du tarball en Phase 10 —
`10-ETUDE.md` §4 : *« mempalace-capture/mempalace-recall + agent gsd-mempalace-curator »*) doit
être **re-confirmé contre l'index régénéré en fin de 11-03** (D-09bis) avant de committer — si le
nom diffère de ce qui est écrit ici, corriger le nom dans `intent-routing.md` ET la whitelist du
test, jamais l'un sans l'autre (contrainte explicite de Phase 10).

### D-09 — `check-overlaps.sh` : 3 paires exactes, pas de glob

Le format `KNOWN_PAIRS` du script est un heredoc `brique|brique|frontière`, comparé par égalité de
chaîne (`pair_known()`), aucun support de glob. Trois lignes exactes à ajouter :
```
consolidator|gsd-mempalace-capture|consolidator = canon mémoire de lab (in-repo, machine-enforced, ADR-052) ; mempalace = opt-in, exige MemPalace, mémorise des artefacts de phase GSD via le loop-bus interne — non activé, non répliqué
consolidator|gsd-mempalace-recall|consolidator = canon mémoire de lab (in-repo, machine-enforced, ADR-052) ; mempalace = opt-in, exige MemPalace, mémorise des artefacts de phase GSD via le loop-bus interne — non activé, non répliqué
vibeflow-dev|gsd-next|vibeflow-dev = front door unique du lab (agent routeur) ; gsd-next = front door de GSD pour qui n'a pas d'agent routeur — ne jamais router gsd-next (empilerait deux routeurs, ADR-057)
```
Deux nouveaux axes de test dans `test-check-overlaps.sh` (T14 = dernier pris, cf. lecture directe
du fichier) : **T15** (les 3 paires sont bien connues — `pair_known` retourne vrai) et **T16**
(présence simultanée détectée → frontière affichée, advisory).

### D-10 — Correctif `merge-hooks.sh` : matching ancré + fin de la co-location

Deux correctifs dans le bloc Python embarqué :
1. **Matching ancré** : `references(entry, basenames)` (ligne 117-118) fait aujourd'hui
   `b in entry.get("command", "")` — sous-chaîne non ancrée. `archive.sh` matcherait à tort
   `gsd-archive.sh`. Remplacer par une regex ancrée aux frontières de chemin/mot : un basename
   `b` ne doit matcher que précédé de `/`, début de chaîne, espace ou quote, et suivi de fin de
   chaîne, espace ou quote (mirroir de la logique `isManagedHookCommand` décrite en Phase 10,
   non copiée verbatim — le tarball gsd-core n'est pas dans ce repo, la spec est reformulée
   localement).
2. **Fin de la co-location** : dans le merge (mode `merge`, boucle sur `frag_hooks.items()`), la
   réutilisation d'un groupe existant de même `matcher` (lignes ~128-138) ne doit avoir lieu QUE
   si ce groupe est déjà entièrement possédé par VibeFlow (tous ses hooks référencent un script du
   fragment courant OU d'un fragment VF déjà connu) — sinon créer un **nouveau** groupe plutôt que
   d'ajouter dans un groupe mixte. Neutralise les 2 risques latents identifiés au dry-run Phase 10
   (migration de scope qui déplace un groupe entier, `cleanupOrphanedHooks` qui supprime un groupe
   entier).

### D-11 — Suite `test-gsd-cohabitation.sh` : fichier neuf, fixture neuve

`plugin/_internal/tests/test-gsd-cohabitation.sh` (nouveau) + fixture
`plugin/_internal/tests/fixtures/gsd-core-settings.json` (nouveau — snapshot représentatif d'un
`settings.json` post-install gsd-core : 15+ hooks, statusLine, bloc `permissions`, PAS de données
réelles de la machine de Samuel — fixture synthétique mais structurellement fidèle). 5 cas
(T1-T5, numérotation propre à ce nouveau fichier, indépendante de `test-merge-hooks.sh`) :
- **T1** merge sans perte : l'ensemble (event, commande) des entrées `gsd-*` de la fixture est un
  sous-ensemble du résultat après merge d'un fragment VF ; `statusLine`/`permissions` deep-equal.
- **T2** `remove` (uninstall VF) restaure un état deep-equal à la fixture d'origine.
- **T3** idempotence : deux `merge` consécutifs produisent un settings.json identique au premier.
- **T4** non-mixité post-correctif : après merge, aucun groupe (event, matcher) ne mélange des
  hooks `gsd-*` et des hooks VF dans la même entrée de groupe SAUF si ce groupe est déjà
  entièrement VF (cas légitime).
- **T5** anti-collision suffixe : un fragment VF portant un hook `consolidator-archive.sh` ne
  retire jamais une entrée tierce `gsd-archive.sh` de la fixture (le cas concret cité en Phase
  10 comme preuve du bug de matching non ancré).

### D-12 — `model_profile: balanced` : deux points d'ancrage, jamais de nouveau mécanisme

1. **Nouveau lab** : une ligne ajoutée à la section « Next steps & hygiène documentaire »
   d'`AGENT.md` (dev-orchestrator) — après `gsd-new-project`, asserter (pas juste documenter)
   `model_profile: balanced` dans `.planning/config.json` du lab. Réutilise le mécanisme
   générique existant (l.98-102), pas de nouvelle section (même pattern que D-08 de
   `13-CONTEXT.md`).
2. **Lab existant** : une nouvelle recette dans `plugin/conductor/references/migration-playbook.md`
   (sur le modèle de la recette « 2bis » déjà présente — migration planning v2) : `vf-calibrate`
   propose (jamais n'impose) de poser `model_profile: balanced` si absent, validation humaine
   avant écriture (ADR-031).
3. **Frontière model: (agents vf-*) vs model_profile (sous-agents gsd-*)** : une phrase ajoutée à
   `GSD-PIPELINE.md` (dev-orchestrator) — les deux couches sont indépendantes, la chaîne
   `vf-coder (sonnet) → gsd-plan-phase → gsd-planner (opus)` est le comportement voulu, pas un
   bug à corriger.

Aucun de ces 3 points ne touche `.planning/config.json` de **ce repo** (vibeflow-os n'est pas un
« lab » consommateur au sens de la doctrine — c'est la source du plugin). Rien à modifier dans
`.planning/` de ce repo pour cette vague.

### D-13 — Non-régression 11-06 : dry-run isolé, jamais le vrai `~/.claude`

Toute vérification d'install (`ensure-deps.sh` 3 scopes, idempotence) s'exécute avec
`HOME`/`CLAUDE_CONFIG_DIR` redirigés vers un répertoire `mktemp -d` dédié — jamais le
`$HOME/.claude` réel de la machine d'exécution, jamais le `gsd-sdk`/`get-shit-done-cc` du PATH
réel. `VF_ENSURE_DRY_RUN=1` est utilisé pour les 3 scopes (`user`/`project`/`local` via
`VF_SCOPE`), complété par une passe avec `HOME` redirigé pour vérifier que la détection dual-path
(D-01) ne lit ni n'écrit jamais hors du sandbox.

### D-14 — Purge de référence legacy vivante : `PROJECT.md:61` uniquement

Lecture directe : `PROJECT.md:43` (bullet « Milestone `gsd-migration` (en attente) ») décrit
l'historique de la migration elle-même (nomme les deux paquets à dessein) — **ne pas toucher**.
`PROJECT.md:61` (« Dépendances externes : GSD (`get-shit-done-cc`, npm) ... ») décrit l'état
**courant** — renommage simple en `@opengsd/gsd-core`. Aucune autre référence vivante trouvée
(CHANGELOG/specs/ADR/anciens plans de phase = archives, à leur place, non touchés — confirmé par
`grep -rln "gsd-sdk"` sur tout le repo en amont du cadrage).

### D-15 — Compteur de suites (38 → 39) : les DEUX occurrences par fichier

`README.md` et `README.fr.md` portent chacun **2 occurrences** de « 38 suites » (un diagramme
mermaid + une phrase de section « Auditable »). `check-version-sync.sh` ne vérifie que la
**première** occurrence (`grep -o ... | head -1`), mais les deux doivent être corrigées pour
rester cohérentes en lecture humaine — pas seulement celle que le gate regarde. Nouveau total
réel après 11-04 (ajout de `test-gsd-cohabitation.sh`) : **39** suites (`find plugin scripts -path
'*/tests/test-*.sh'` — vérifié : 38 avant la vague, +1).

### D-16 — Release-meta centralisée en 11-06, pas par vague

Aucune des vagues 11-01 à 11-05 ne touche `VERSION`/`module.json`/`CHANGELOG.md`/`README.md` d'un
module — ces bumps sont **centralisés dans la vague 11-06** (précédent direct : 14-06). Modules
et bumps :
- `dev-orchestrator` v2.2.1 → **v2.3.0** (minor — nouvelle capacité : routage `gsd-onboard`,
  package/SDK renommés).
- `planning-core` v2.5.1 → **v2.5.2** (patch — compat dual-layout, aucun comportement nouveau
  côté utilisateur).
- `conductor` v1.14.1 → **v1.14.2** (patch — 3 entrées `check-overlaps.sh`, pas de nouveau
  mécanisme).
- `plugin/_internal/merge-hooks.sh` (vague 11-04) : pas de module dédié — entrée dans le
  **CHANGELOG racine** (`CHANGELOG.md`), précédent direct trouvé par grep (l.222, fix Python déjà
  documenté là pour `_internal`).

### Claude's Discretion

- Formulation exacte des lignes ajoutées dans les tables `AGENT.md`/`intent-routing.md` (sous
  contrainte : verbes NL réels, cohérents avec le style des lignes voisines, garder
  `gsd-map-codebase` textuellement présent pour T7).
- Nom exact de la fonction anti-collision dans `merge-hooks.sh` (le mandat ne fige pas
  d'identifiant, seulement le comportement).
- Ordre interne des tâches à l'intérieur d'un plan (TDD test-d'abord recommandé, cohérent avec le
  reste du repo — cf. 14-01).

### Folded Todos

Aucun todo en attente identifié pour la Phase 11 dans cette session (pas d'accès `gsd-tools`/
`gsd-sdk` local vérifié ici — si un todo existe, il remontera au prochain `gsd-progress`).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` §Phase 11 (Goal, 3 Success Criteria, GATE Phase 10)
- `.planning/REQUIREMENTS.md` GSDM-04, GSDM-05, GSDM-06 (lignes 126-131)
- `.planning/phases/10-etude-migration-gsd/10-ETUDE.md` — surface d'usage (GSDM-01), caractérisation
  cible (GSDM-02), go/no-go (GSDM-03)
- `.planning/phases/10-etude-migration-gsd/10-SOLUTIONS.md` — carte d'adoption (5 verdicts), preuves
  du spike sandbox
- `.planning/phases/10-etude-migration-gsd/10-APPROFONDISSEMENT.md` — **squelette figé des 6
  vagues** (§5), arbitrage SDK (§0), correctif cohabitation (§1), piège n°1 (§2), model-profiles
  (§3), routage onboard (§4)
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` (263 lignes actuelles — piège n°1 l.99, package
  l.120/128, GSD_VERSION_FILE l.53)
- `plugin/planning-core/scripts/detect-gsd-engine.sh` (89 lignes — GSD_HOME l.24)
- `plugin/dev-orchestrator/scripts/build-gsd-index.sh` (117 lignes — WORKFLOWS_DIR l.27)
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` (gsd-sdk l.18)
- `plugin/dev-orchestrator/references/mission-contracts.md` (gsd-sdk l.72-73)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (whitelist T4 l.260, bloc T14
  l.519-574, numérotation T1-T17 prise — aucun numéro libre pour un 18e axe sans nécessité)
- `plugin/dev-orchestrator/AGENT.md` (158 lignes actuelles, plafond 250 — marge 92 ; FIRST-02
  l.35-37 ; table Amont & cadrage l.48-59 ; hygiène documentaire l.93-102 ; références l.152-157)
- `plugin/dev-orchestrator/references/intent-routing.md` (165 lignes — table Amont & cadrage
  l.41-53, §Couverture l.140-158)
- `plugin/conductor/scripts/check-overlaps.sh` (KNOWN_PAIRS l.57-64, T14 déjà pris dans le fichier
  de test — T15/T16 libres)
- `plugin/conductor/scripts/tests/test-check-overlaps.sh`
- `plugin/_internal/merge-hooks.sh` (188 lignes — `references()` l.117-118, merge l.122-154)
- `plugin/_internal/tests/test-merge-hooks.sh` (190 lignes, T1-T7 pris — nouveau fichier dédié
  `test-gsd-cohabitation.sh` pour ne pas coller à cette numérotation)
- `plugin/conductor/references/migration-playbook.md` (80 lignes — recette « 2bis » = gabarit de
  style pour la nouvelle recette model_profile)
- `plugin/dev-orchestrator/references/GSD-PIPELINE.md` (126 lignes)
- `README.md` (l.165, l.235 — « 38 suites »), `README.fr.md` (l.170, l.240 — idem)
- `scripts/check-version-sync.sh` (point 9, l.123-132 — gate du compteur de suites)
- `.planning/PROJECT.md` (l.43 intact, l.61 à renommer)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Gabarit de plan (frontmatter + sections) : `.planning/phases/14-frontiere-altitude-planning-gsd/
  14-01-PLAN.md` (plan fonctionnel, `autonomous: true`) et `14-06-PLAN.md` (plan de release,
  `autonomous: false`) — repris tels quels pour les 6 plans de cette phase.
- Pattern de détection dual-layout **déjà écrit** dans `detect-gsd-engine.sh` pour la distinction
  `gsd_state_version` (moteur GSD) / `planning_version` (planning-core) — même esprit de
  résolution en cascade à répliquer pour `gsd-core`/`get-shit-done` (D-01), mais nouveau code
  (l'existant distingue deux MOTEURS, pas deux CHEMINS d'un même moteur).
- `has_frontmatter_key()` (detect-gsd-engine.sh) et `extract_frontmatter_field()`
  (build-gsd-index.sh) : awk anti-hallucination — modèle si une future vague avait besoin
  d'extraire un champ frontmatter (pas nécessaire pour ces 6 vagues, mentionné pour mémoire).

### Established Patterns

- Tests bash : `pass=0; fail=0; ok()/ko()/skip()`, fixtures `mktemp -d` inline (jamais de
  fixtures committées sauf cas où une structure JSON réaliste est nécessaire — `test-merge-hooks.sh`
  n'en a pas, mais D-11 introduit `fixtures/gsd-core-settings.json` car un settings.json avec 15+
  hooks n'est pas raisonnablement inline).
- Convention de version (`CLAUDE.md` racine) : nouvelle capacité → minor ; correctif/durcissement
  → patch. Précédents : dev-orchestrator v2.1.0 (capacité) minor, v2.1.1 (fix) patch.
- `ADR-031` (jamais de fix sans validation humaine) : tout ce qui touche à des commandes
  destructibles (`npm uninstall`, `rm -rf`) doit être **affiché, jamais exécuté** — déjà
  l'invariant de `ensure_gsd()`/`ensure_superpowers()` existants (fallback manuel systématique
  sur échec, jamais de silent failure).

### Integration Points

- `ensure-deps.sh` est appelé par `vibeflow-update.sh` (installeur) — pas modifié par cette phase,
  aucun changement de signature/contrat d'appel (variables d'env identiques : `VF_SCOPE`,
  `VF_ENSURE_DRY_RUN`, `VF_ENSURE_AUTO_MAP`, `VF_ENSURE_FORCE`).
- `detect-gsd-engine.sh` est appelé par des hooks (`--defer-to-gsd`, Phase 14) — contrat de sortie
  (exits 0/1/2/3/64) inchangé, seule la résolution du chemin par défaut change.
- `build-gsd-index.sh` est appelé en post-install (D7) — signature de sortie (Markdown, table
  `| Skill | Description |`) inchangée, seule la source secondaire optionnelle change de chemin
  par défaut.
</code_context>

<specifics>
## Specific Ideas

Aucune idée hors du périmètre déjà cadré par le mandat et `10-APPROFONDISSEMENT.md` §5 — la
portée est entièrement dérivée des 6 vagues arbitrées et de GSDM-04/05/06.
</specifics>

<deferred>
## Deferred Ideas

- **Release racine (bump `VERSION` + tag annoté poussé)** — explicitement hors mandat, réservé à
  une validation humaine post-plans (précédent : Phase 13 §5, Phase 14 en plan dédié
  `autonomous: false`).
- **Runbook labs legacy complet** (au-delà de l'affichage `detect_gsd_legacy()`) — Phase 10
  mentionne une séquence à 5 étapes ; seule l'étape 3 (affichage des 3 commandes manuelles) est
  dans le périmètre mécanique de `ensure-deps.sh`. Les étapes 1/2/4/5 (poser le module migré,
  `patch_gsd_executor_mcp`, régénération de l'index) sont déjà couvertes par les vagues
  elles-mêmes — rien à différer, notée ici pour traçabilité de lecture.
- **`gsd-mcp-server`/ADR-051** — sans rapport avec cette phase (verdict Phase 10 #2 : entrant vs
  sortant), non planifié.
</deferred>
