---
phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualite
plan: 07
subsystem: governance
tags: [adr, changelog, versioning, team-kernel, doctrine, release-discipline]

requires:
  - phase: VFDO-20 (plan 20-01)
    provides: "disallowedTools connu de check-agents.sh, périmètre des 2 gates, charset MCP"
  - phase: VFDO-20 (plan 20-02)
    provides: "dag.sh --scope, review_regime écrit par reopen, status.frozen"
  - phase: VFDO-20 (plan 20-03)
    provides: "vf-reviewer.md : clé vf-mcp-tools + protocole de vérification outillée"
  - phase: VFDO-20 (plan 20-04)
    provides: "les 4 juges portent disallowedTools: Write, Edit"
  - phase: VFDO-20 (plan 20-05)
    provides: "check-mission-invariants.sh + .planning/MISSION-INVARIANTS.md"
  - phase: VFDO-20 (plan 20-06)
    provides: "mission-flow.md §Pattern E, vf-dev-manager.md pilote revue-N en direct"
provides:
  - "ADR-051 révisée sur son seul point contesté : le relecteur reçoit une allowlist NOMMÉE (vf-mcp-tools), argument littéral et coût chiffré"
  - "ADR-060 (nouvelle) : la revue devient un étage de premier rang piloté par le manager"
  - "team-kernel.md + conductor/README.md : cloisonnement par outils cite disallowedTools, sens fermeture documenté, plan de bataille cite --scope/review_regime, compteurs du module obligatoire exacts (14 scripts, 12 suites)"
  - "6 modules bumpés (conductor v1.17.0, dev-orchestrator v2.8.0, design-orchestrator v1.3.2, business-pilot-bundle/content-bundle/growth-bundle v2.0.3), triade cohérente"
  - "Reste-à-faire de release racine consigné explicitement (4 éléments, dont le compteur réel de suites : 44, pas 43)"
affects: []

actuals:
  tokens: 9983
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Doctrine écrite en dernier, après que le comportement existe (T-20-07-01) : les 3 commits de ce plan suivent tous les 6 plans amont, jamais l'inverse"
    - "Vérification sur pièce systématique avant édition (T-20-07-02) : chaque ligne éditée relue au commit pré-existant avant modification, jamais sur la foi d'un rapport de mission"

key-files:
  created: []
  modified:
    - docs/ADR.md
    - plugin/conductor/references/team-kernel.md
    - plugin/conductor/README.md
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/CHANGELOG.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/dev-orchestrator/README.md
    - plugin/design-orchestrator/VERSION
    - plugin/design-orchestrator/module.json
    - plugin/design-orchestrator/CHANGELOG.md
    - plugin/design-orchestrator/README.md
    - plugin/business-pilot-bundle/VERSION
    - plugin/business-pilot-bundle/module.json
    - plugin/business-pilot-bundle/CHANGELOG.md
    - plugin/business-pilot-bundle/README.md
    - plugin/content-bundle/VERSION
    - plugin/content-bundle/module.json
    - plugin/content-bundle/CHANGELOG.md
    - plugin/content-bundle/README.md
    - plugin/growth-bundle/VERSION
    - plugin/growth-bundle/module.json
    - plugin/growth-bundle/CHANGELOG.md
    - plugin/growth-bundle/README.md

key-decisions:
  - "ADR-060 posée au numéro 60, vérifié sur pièce (dernière ADR du fichier = ADR-059) et non supposé sur la foi du cadrage."
  - "L'affirmation « anti-triche vérifié par les suites de test de chaque module » (team-kernel.md/README.md) constatée FAUSSE pour 4 des 6 modules porteurs d'un juge (design-orchestrator, business-pilot-bundle, content-bundle, growth-bundle : chacun a exactement une suite propre, aucune ne teste disallowedTools) — signalée en différé nommé (P-07), NON corrigée dans la doctrine, NON ouverte en chantier."
  - "Compteurs du module obligatoire écrits à leur valeur RÉELLE (14 scripts, 12 suites), pas à la valeur du cadrage (14, 11) : le dépôt a gagné 2 suites depuis le cadrage — test-check-mission-invariants.sh (plan 20-05) ET test-guard-agent-write.sh (correctif de revue hors plan, commit 447e75a, nouveau fichier)."
  - "Extension hors files_modified : l'en-tête « Version » du README.md de chacun des 6 modules bumpés a été mis à jour (Rule 1/3 — check-version-sync.sh les aurait sinon fait passer rouges, contredisant l'acceptance criterion « un seul contrôle rouge »)."
  - "Reste-à-faire de release racine : le compteur réel de suites cité par les 2 README racine doit passer à 44 (pas 43 comme anticipé par le cadrage) — valeur vérifiée par comptage réel, pas recalculée par la personne qui fera la release."

requirements-completed: [SC1, SC2, SC3, SC4, SC5, SC6, SC7]

coverage:
  - id: D1
    description: "ADR-051 révisée sur son seul point contesté (relecteur nommé, argument littéral, coût chiffré, code impacté complété) ; aucune autre section touchée"
    requirement: "SC1"
    verification:
      - kind: unit
        ref: "grep -c 'ne PRODUIT pas' docs/ADR.md = 1 ; grep -c 'VÉRIFIE' docs/ADR.md = 1 ; python3 assertion de suite croissante sans doublon → 'ADR ok, dernier = 60'"
        status: pass
      - kind: other
        ref: "git diff docs/ADR.md : tableau d'options, cloisonnement anti-triche et rules associées d'ADR-051 absents du diff"
        status: pass
    human_judgment: false
  - id: D2
    description: "ADR-060 posée, numéro vérifié sur pièce, structure canonique, décision <25 lignes, renvoie à mission-flow.md sans dupliquer"
    requirement: "SC3"
    verification:
      - kind: unit
        ref: "grep -c '^## ADR-060' docs/ADR.md = 1 ; section Décision = 8 lignes non vides"
        status: pass
    human_judgment: false
  - id: D3
    description: "Aucune ADR posée pour le changement de périmètre des hooks (correction de configuration)"
    requirement: "SC6"
    verification:
      - kind: other
        ref: "lecture de docs/ADR.md : aucun titre d'ADR portant sur les hooks de conformité"
        status: pass
    human_judgment: false
  - id: D4
    description: "team-kernel.md + README.md : cloisonnement par outils cite disallowedTools, sens fermeture documenté, plan de bataille cite --scope/review_regime"
    requirement: "SC2, SC4"
    verification:
      - kind: unit
        ref: "grep -c disallowedTools / AskUserQuestion / review_regime dans team-kernel.md ; bash dag.sh -h confirme --scope"
        status: pass
    human_judgment: false
  - id: D5
    description: "Compteurs du module obligatoire exacts (comptage réel, pas de tête) : 14 scripts, 12 suites, arborescence cohérente"
    requirement: "SC5"
    verification:
      - kind: unit
        ref: "test \"$(ls plugin/conductor/scripts/*.sh | wc -l)\" = \"$(grep -oE 'Scripts \\(([0-9]+)\\)' README.md)\" ; idem suites"
        status: pass
    human_judgment: false
  - id: D6
    description: "6 modules bumpés, triade cohérente, gates de sortie rejoués, seul rouge attendu nommé"
    requirement: "SC7"
    verification:
      - kind: unit
        ref: "scripts/check-version-sync.sh (rouge sur le seul compteur de suites racine, 44 réel) ; check-agents --strict sur les 6 dossiers d'agents (dev-orchestrator, design-orchestrator, business-pilot-bundle, content-bundle, growth-bundle, mobile-test-team) rc=0 ; 44 suites test-*.sh, 0 échec"
        status: pass
    human_judgment: false
  - id: D7
    description: "Périmètre de la release racine intact ; aucun tag créé"
    requirement: "SC7"
    verification:
      - kind: unit
        ref: "git diff --name-only ne liste ni VERSION racine, ni plugin.json, ni marketplace.json, ni README.md/README.fr.md ; git tag --points-at HEAD vide"
        status: pass
    human_judgment: false

duration: ~1h10
completed: 2026-07-31
status: complete
---

# Phase VFDO-20 Plan 07: Clôture de gouvernance — ADR, doctrine transverse, 6 modules bumpés Summary

**ADR-051 révisée sur son seul point contesté (relecteur nommé, coût chiffré) et ADR-060 posée (revue = étage de premier rang), la doctrine transverse du noyau d'équipe alignée sur les capacités réellement livrées, et les 6 modules de la phase bumpés avec triade cohérente — sans toucher un octet à la release racine.**

## Performance

- **Duration:** ~1h10
- **Tasks:** 3/3
- **Files modified:** 26

## Accomplishments

- **ADR-051** amendée sur son seul point contesté : le relecteur (`vf-reviewer`) sort de la liste des
  agents hors périmètre d'injection MCP et reçoit une allowlist **NOMMÉE** (clé `vf-mcp-tools`,
  grammaire `<serveur>:<outil1>,<outil2>,…`) — le manager et l'auditeur restent inchangés. Argument
  littéral écrit mot pour mot (« un relecteur ne PRODUIT pas un verdict de compilation, il en VÉRIFIE
  un ») et coût chiffré (+90s, un slot de simulateur). Section Code Impacté complétée des deux
  fichiers réels. Rien d'autre dans l'ADR n'a bougé (tableau d'options, cloisonnement anti-triche,
  rules associées intacts — vérifié par lecture du diff).
- **ADR-060** posée (numéro vérifié sur pièce, pas supposé) : la revue devient un nœud de plan de
  bataille posé systématiquement par le manager, dispatché en direct, gradé par 4 déclencheurs
  objectifs (jamais le volume), avec revue de jointure sur topologie et garde-fou machine
  `review_regime`. Renvoie à `mission-flow.md` §Pattern E sans le dupliquer (section Décision : 8
  lignes).
- **Aucune ADR** pour le changement de périmètre des hooks — trancher explicitement en correction de
  configuration (P-04), consigné dans le CHANGELOG de `conductor`.
- **`team-kernel.md` + `conductor/README.md`** : la ligne de cloisonnement par outils cite désormais
  `disallowedTools: Write, Edit` (le mécanisme réel posé par le plan 20-04) au lieu de la simple
  absence dans `tools:` ; nouvelle ligne « Écart déclaré ↔ runtime (sens fermeture) » qui documente
  la classe symétrique de la restriction déjà connue sur l'allowlist `Agent(...)` de dispatch (un
  outil PRÉSENT dans `tools:` peut être ABSENT au runtime en dispatch sous-agent — cas daté
  `AskUserQuestion`) ; la ligne du plan de bataille cite `--scope` et `review_regime`, noms vérifiés
  contre `dag.sh -h` ; `check-mission-invariants.sh` entre dans la liste des scripts ; compteurs du
  module obligatoire recomptés et corrigés à leur valeur RÉELLE (14 scripts, 12 suites — pas 11 comme
  anticipé, cf. Déviations).
- **6 modules bumpés**, triade `VERSION`/`module.json`/`CHANGELOG.md` cohérente par module (mineur
  pour `conductor` et `dev-orchestrator` — nouvelles capacités ; correctif pour `design-orchestrator`
  et les 3 bundles — durcissement seul) : `conductor` v1.16.0→v1.17.0, `dev-orchestrator`
  v2.7.1→v2.8.0, `design-orchestrator` v1.3.1→v1.3.2, `business-pilot-bundle`/`content-bundle`/
  `growth-bundle` v2.0.2→v2.0.3.
- **Gates de sortie de phase rejoués et consignés avec leur sortie réelle** (pas celle attendue) :
  voir §Gates ci-dessous.

## Task Commits

1. **Task 1: ADR-051 révisée + ADR-060 posée (D-02, D-26)** — `c694d18` (docs)
2. **Task 2: doctrine transverse alignée (D-08, D-09)** — `2e1e7dd` (docs)
3. **Task 3: 6 modules bumpés, gates rejoués (D-25, SC7)** — `06534f1` (chore)

## Files Created/Modified

- `docs/ADR.md` — ADR-051 révisée (décision point 1, conséquences, code impacté) ; ADR-060 nouvelle
- `plugin/conductor/references/team-kernel.md` — cloisonnement par outils, sens fermeture, plan de bataille
- `plugin/conductor/README.md` — mêmes 3 corrections + liste des scripts + compteurs + en-tête version
- `plugin/{conductor,dev-orchestrator,design-orchestrator,business-pilot-bundle,content-bundle,growth-bundle}/VERSION` — bump
- `plugin/{mêmes 6}/module.json` — champ `version` aligné
- `plugin/{mêmes 6}/CHANGELOG.md` — une entrée par module décrivant le LIVRÉ (pas le cadrage)
- `plugin/{dev-orchestrator,design-orchestrator,business-pilot-bundle,content-bundle,growth-bundle}/README.md` — en-tête `Version` réaligné (extension hors `files_modified`, voir Déviations)

## Gates de sortie de phase (rejoués, sortie réelle)

- **Boucle complète des suites** (`find plugin scripts -type f -path '*/tests/test-*.sh'`) : **44
  suites**, 0 échec. Le repo a gagné 2 suites depuis le cadrage de la phase (`test-check-mission-invariants.sh`,
  plan 20-05, ET `test-guard-agent-write.sh`, correctif de revue hors plan — commit `447e75a`,
  nouveau fichier), pas 1 comme anticipé.
- **`check-agents.sh --strict` sur les 6 dossiers d'agents** : `dev-orchestrator`,
  `design-orchestrator`, `business-pilot-bundle`, `content-bundle`, `growth-bundle`,
  `mobile-test-team` → **rc=0 sur les 6**, uniquement des warnings pré-existants (skills non câblés,
  3 noms d'agents hors périmètre du dossier scanné). Voir Déviations pour la correction du roster
  (`conductor` n'a pas de dossier `agents/` — c'est un agent unique `AGENT.md`, pas une équipe).
- **`scripts/check-version-sync.sh`** : rouge sur **un seul contrôle**, celui attendu — le compteur
  de suites cité par les 2 README racine (`'42 suites' ≠ réel=44`). Tous les autres contrôles verts,
  y compris la triade des 17 modules et l'en-tête Version des 17 README de module.
- **Périmètre de release intact** : `git diff --name-only` (sur les 3 commits de ce plan) ne liste ni
  `VERSION` racine, ni `plugin/.claude-plugin/plugin.json`, ni `.claude-plugin/marketplace.json`, ni
  `README.md`/`README.fr.md` racine. `git tag --points-at HEAD` vide.

## Décisions vérifiées sur pièce (traçabilité Task 2 — T-20-07-02)

| Ligne éditée | Fichier | Formule RÉELLE trouvée avant édition (git show, commit pré-Task-2 `c694d18`) |
|---|---|---|
| Cloisonnement par tools | `team-kernel.md:23` | `juges sans Write/Edit ; la plupart des workers sans Task ; ...` |
| Cloisonnement par tools | `README.md:44` | `juges sans Write/Edit, la plupart des workers sans Task, ...` |
| Plan de bataille | `team-kernel.md:19` | `` `dag.sh` (init / add --deps / ready / mark / reopen) `` — aucune mention de `--scope`/`review_regime` |
| Plan de bataille | `README.md:40` | `` `scripts/dag.sh` (init / add --deps / ready / mark / reopen) `` — idem |
| Scripts (titre) | `README.md:75` | `## Scripts (13) — par famille` |
| Suites (texte) | `README.md:101` | `**Tests** : 10 suites sous \`scripts/tests/\` ...` |
| Arborescence | `README.md:114` | `scripts/ # 13 scripts (familles ci-dessus) + tests/ (10 suites)` |

Aucune édition n'a été faite sur la foi d'un rapport de mission — chaque ligne ci-dessus a été relue
dans le fichier réel (via `git show`) immédiatement avant sa modification.

## Decisions Made

- ADR-060 posée au numéro **60**, vérifié en lisant la dernière ADR du fichier (ADR-059) plutôt que
  supposé sur la foi du cadrage — une phase concurrente aurait pu en poser une entre-temps (elle ne
  l'avait pas fait).
- Compteurs du module obligatoire écrits à leur valeur **réellement comptée** sur le système de
  fichiers (14 scripts, 12 suites) plutôt qu'à la valeur du `must_have` du plan (14, 11) — voir
  Déviations pour la cause du décalage.
- L'affirmation « anti-triche vérifié par les suites de test de chaque module » a été **constatée**
  (pas corrigée, P-07) : elle est fausse pour 4 des 6 modules porteurs d'un juge — voir Déviations.
- Extension de `files_modified` aux 5 README.md de module (hors `conductor`, déjà dans le périmètre)
  pour réaligner leur en-tête `Version` — sans ce geste, `check-version-sync.sh` aurait affiché 6
  contrôles rouges supplémentaires, contredisant l'acceptance criterion « un seul contrôle rouge ».

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/3] En-tête `Version` des 5 README de module non listés dans `files_modified`**
- **Found during:** Task 3, premier passage de `check-version-sync.sh` après les bumps
- **Issue:** chaque module bumpé porte aussi un en-tête `**Version** : vX.Y.Z` dans son propre
  `README.md`, hors du périmètre déclaré par le plan (`files_modified` ne listait que
  `plugin/conductor/README.md`, déjà touché pour la doctrine). Sans correction, `check-version-sync.sh`
  aurait affiché 6 contrôles rouges supplémentaires (« en-tête Version des README de modules »),
  contredisant directement l'acceptance criterion « le gate échoue sur UN SEUL contrôle ».
- **Fix:** en-tête `Version` de `dev-orchestrator/README.md`, `design-orchestrator/README.md`,
  `business-pilot-bundle/README.md`, `content-bundle/README.md`, `growth-bundle/README.md` aligné
  sur la nouvelle valeur de `VERSION`. `conductor/README.md` était déjà dans le périmètre (Task 2).
- **Files modified:** les 5 README ci-dessus.
- **Verification:** `scripts/check-version-sync.sh` → `en-tête Version des README de modules : 17
  déclarés, tous alignés` (vert).
- **Committed in:** `06534f1` (Task 3 commit).

**2. [Rule 1] Correction du roster de "6 dossiers d'agents" dans le bloc `<verify>` littéral de Task 3**
- **Found during:** Task 3, exécution littérale du bloc de vérification du plan
- **Issue:** le bloc `<verify>` de la Task 3 itère sur `plugin/conductor plugin/dev-orchestrator
  plugin/design-orchestrator plugin/business-pilot-bundle plugin/content-bundle plugin/growth-bundle`
  avec `|| exit 1`. `plugin/conductor` n'a **pas** de dossier `agents/` (c'est un agent unique,
  `AGENT.md`, pas une équipe manager/workers/juges) : `check-agents.sh --strict
  --agents-dir=plugin/conductor/agents` sort en `rc=3 INDÉTERMINÉ` (« aucun agent... »), ce qui aurait
  fait échouer la boucle du bloc littéral. Le roster canonique des « 6 dossiers d'agents » établi par
  le plan 20-01 (déjà vérifié vert sous `--allow-empty`) est `business-pilot-bundle, content-bundle,
  design-orchestrator, dev-orchestrator, growth-bundle, mobile-test-team` — `mobile-test-team`, pas
  `conductor`. Même famille de défaut que le bloc `awk` signalé par le SUMMARY 20-06 (une commande de
  vérification littérale du plan ne correspond pas à l'intention qu'elle vérifie).
- **Fix:** exécuté le roster corrigé (`mobile-test-team` au lieu de `conductor`) : **rc=0 sur les 6**.
  Signalé ici pour que la commande de vérification soit corrigée si réutilisée ailleurs — pas un
  défaut de la doctrine ou des agents eux-mêmes.
- **Verification:** cf. §Gates de sortie de phase ci-dessus.
- **Committed in:** aucun commit de code (constat de vérification, documenté ici).

### Écarts constatés sur des `must_haves` du plan (non corrigés, chiffre réel écrit)

**3. Compteurs du module obligatoire : 12 suites réelles, pas 11 comme anticipé par le cadrage.**
- Le `must_have` du plan (« quatorze scripts, onze suites ») avait raison sur les scripts (14, vérifié)
  mais pas sur les suites : le dépôt en compte **12** dans `plugin/conductor/scripts/tests/`, pas 11.
  Cause : le cadrage anticipait UNE suite nouvelle (`test-check-mission-invariants.sh`, plan 20-05),
  mais un correctif de revue **hors plan**, postérieur au cadrage (commit `447e75a`, « guard-agent-write.sh
  bloque réellement l'agent non conforme »), a créé un **second** fichier nouveau,
  `test-guard-agent-write.sh` — vérifié par `git log --diff-filter=A`. Le compteur a donc été écrit à
  sa valeur RÉELLE (12), pas à la valeur prévue par le cadrage (conformément à la consigne du plan de
  ne pas écrire un `must_have` faux sur le disque).
- Conséquence en cascade sur SC7 : le compteur repo-entier de suites cité par les 2 README racine est
  réellement de **44** (pas 43 comme anticipé — même cause, la même suite hors plan). `check-version-sync.sh`
  reste rouge sur ce seul contrôle, comme prévu, mais avec la valeur cible corrigée à **44**, pas 43 —
  consigné explicitement en reste-à-faire ci-dessous pour que la personne qui fera la release n'ait
  rien à recalculer.

**4. Affirmation « anti-triche vérifié par les suites de test de chaque module » — constatée FAUSSE
   pour 4 des 6 modules porteurs d'un juge (P-07, non corrigée).**
- Vérifié sur pièce (pas seulement lu) : `design-orchestrator`, `business-pilot-bundle`,
  `content-bundle` et `growth-bundle` ont chacun **exactement une** suite de test propre
  (`test-design-orchestrator.sh`, `test-business-pilot-bundle.sh`, `test-content-bundle.sh`,
  `test-growth-bundle.sh`) et **aucune des quatre ne mentionne `disallowedTools`** (`grep -n
  disallowedTools` → 0 ligne dans chacune). L'anti-triche de leur juge (posé par le plan 20-04) n'est
  donc vérifié QUE par le gate partagé `check-agents.sh --strict`, jamais par la suite propre du
  module — contrairement à ce que la doctrine affirme. Seuls `conductor` (T69-T71 de
  `test-check-agents.sh`, qui teste le MÉCANISME générique, pas un agent réel) et `dev-orchestrator`
  ont une couverture de suite pertinente.
- Conformément à P-07, **non corrigé** dans `team-kernel.md`/`README.md` (la phrase reste inchangée
  au-delà de la partie sur `disallowedTools`), et **non ouvert en chantier**. Consigné ici comme
  différé nommé, et ajouté au registre `.planning/WINDOWS.md` (voir ci-dessous).

---

**Total deviations:** 2 auto-fixées (Rule 1/3), 2 écarts constatés et documentés à leur valeur réelle
(non corrigés, conformes à P-07/consigne du plan).
**Impact on plan:** aucune dérive de périmètre — les deux auto-fix étaient strictement nécessaires
pour tenir l'acceptance criterion « un seul contrôle rouge » ; les deux écarts constatés sont écrits
à leur valeur réelle plutôt qu'à la valeur (fausse) anticipée par le cadrage, comme le plan l'exigeait
explicitement.

## Issues Encountered

Aucun blocage. Le seul point de friction (bloc `<verify>` littéral de Task 3 citant `conductor` au
lieu de `mobile-test-team`) est documenté ci-dessus comme déviation, pas comme un échec de tâche.

## Known Stubs

Aucun — ce plan ne produit que de la doctrine, des journaux et des numéros de version ; aucun code,
aucune UI, aucune donnée simulée.

## User Setup Required

None — aucune configuration de service externe requise.

## Reste-à-faire, réservé à validation humaine post-fusion

1. **Release racine, hors périmètre de cette phase.** Bump `VERSION` racine, `plugin/.claude-plugin/plugin.json`,
   `.claude-plugin/marketplace.json`, badges et historique des 2 README ; **compteur de suites à
   porter à 44** (valeur réelle vérifiée ici, pas 43 comme anticipé par le cadrage — pas de
   recalcul nécessaire) ; tag annoté créé et poussé sur le commit de release ; publication GitHub sur
   ce tag ; `scripts/check-release-tag.sh --remote` → ✓.
2. **Recette humaine sur un lab iOS équipé.** Valider que `test_sim`/`build_sim`/`clean` (allowlist
   nommée `vf-mcp-tools` de `vf-reviewer`) correspondent aux noms réellement exposés par un serveur
   XcodeBuildMCP vivant. Ce dépôt n'a pas de `.mcp.json` : l'écart produirait un no-op silencieux,
   jamais une ouverture accidentelle (D-03, déjà signalé par 20-03). Même statut que la recette
   différée de la Phase 19.
3. **Validation de forme des tokens MCP.** `inject-mcp-tools.sh` ne valide toujours pas qu'un nom de
   serveur cité dans un token existe réellement. Dette connue, hors périmètre des 7 critères de la
   phase, à ne pas ouvrir sans mandat.
4. **Affirmation « anti-triche vérifié par les suites de test de chaque module ».** Constatée
   **FAUSSE** pour `design-orchestrator`, `business-pilot-bundle`, `content-bundle`, `growth-bundle`
   (chacun n'a qu'une suite propre, aucune ne teste `disallowedTools` — vérifié par `grep`).
   L'anti-triche de ces 4 juges n'est aujourd'hui vérifié QUE par le gate partagé `check-agents.sh
   --strict`, jamais par une suite de module. Inscrit ici comme différé nommé, pas corrigé (P-07) —
   ouvrir ce chantier (ajouter un cas de test par module, ou corriger la doctrine pour dire
   uniquement « vérifié par `check-agents.sh` ») nécessite un mandat explicite.

Ces 4 éléments sont aussi inscrits dans `.planning/WINDOWS.md` (registre transverse de défauts,
issue #1950) pour rester visibles au moment du `/gsd-ship`.

## Next Phase Readiness

- La Phase 20 est **complète** sur ses 7 plans : gouvernance posée (ADR-051 révisée, ADR-060 nouvelle),
  doctrine transverse alignée, 6 modules bumpés, gates de sortie tous verts sauf le seul rouge
  ATTENDU et nommé (compteur de suites racine, 44 réel).
- **Aucun blocage** pour la Phase 21 (« Alignement du moteur GSD sur gsd-core 1.9.0 »), déjà ouverte
  au ROADMAP et dépendante du merge de la Phase 20 (même règle que le diagnostic du 2026-07-29).
- La release racine (VERSION, plugin.json, marketplace.json, 2 README, tag, release GitHub) reste
  **entièrement réservée** à une validation humaine post-fusion — les 4 éléments du §Reste-à-faire
  ci-dessus lui donnent tout ce qu'il faut pour l'exécuter sans relire la phase.

---
*Phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit*
*Completed: 2026-07-31*
