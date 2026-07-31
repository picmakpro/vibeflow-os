---
phase: 21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
plan: 02
status: complete
---

# 21-02 — Les trois contrats amont gsd-core 1.9.0 : estimate:/actuals:, arbitrage revue, dispatch nommé

## Performance

- **Durée** : session unique (cadrage inclus dans le digest de mission, pas de cycle
  discuss/plan séparé — rituel allégé sur arbitrage Samuel).
- **Tâches** : 3 changements du digest (estimate:/actuals:, arbitrage ADR-060/lanes de revue,
  runtime-aware-dispatch + confrontation guard).
- **Fichiers modifiés** : 5. **Commits** : 4 (+ ce commit PLAN/SUMMARY).

## Accomplissements

- **Changement 2 — contrat `estimate:`/`actuals:`** : `mission-contracts.md` porte désormais une
  section dédiée qui retranscrit fidèlement les 3 exigences amont (confidence dérivée du nombre
  d'échantillons jamais auto-évaluée, même échelle `chars/4` des deux côtés, aucun arrondi
  flatteur), plus la propagation retenue (deux champs optionnels frères du bloc typé de
  `vf-coder`, recopiés verbatim). Le gabarit « Rapport de mission » gagne une ligne
  « Calibration ». `vf-coder.md` (§Retour) et `vf-dev-manager.md` (§Rapport de mission) portent
  chacun l'instruction de relais verbatim — un contrat non reflété dans les agents qui produisent
  effectivement les retours n'aurait été qu'une intention écrite, jamais un comportement.
- **Changement 3 — arbitrage lanes de revue cross-AI vs ADR-060** : posé ADR-061, qui tranche
  noir sur blanc que les deux mécanismes sont **disjoints** sur 3 axes vérifiés (objet revu,
  moment du cycle, déclencheur — détail ci-dessous §Constat). Aucune fusion, aucun câblage
  automatique de `gsd-review` dans le DAG de mission. `mission-contracts.md` pointe vers l'ADR
  sans dupliquer son contenu (même patron qu'ADR-060 lui-même envers `mission-flow.md`).
- **Changement 4 — dispatch nommé et isolation exécuteur** : `team-kernel.md` nomme l'hypothèse
  « le dispatch nommé marche toujours » et sa limite (runtimes built-in-only comme kimi-code),
  datée et vérifiée sur ce poste (`.gsd-runtime = claude`). Confrontation du namespace de branche
  élargi (#1995, `agent-<id>` OU `worktree-agent-<id>`) à `gsd-worktree-path-guard.js` : **vérifié
  conforme**, aucun défaut, aucune correction nécessaire — détail §Constat.

## Task Commits

1. **ADR-061 (changement 3)** : `064e94a` (docs) — arbitrage revue cross-AI de plans vs revue de
   code.
2. **Contrat estimate:/actuals: dans mission-contracts.md (changement 2)** : `6adc690` (docs).
3. **Relais verbatim dans vf-coder.md/vf-dev-manager.md (changement 2)** : `a610a9b` (docs).
4. **Hypothèse dispatch nommé dans team-kernel.md (changement 4)** : `6b17dbf` (docs).
5. **PLAN + SUMMARY** : ce commit (docs).

## Files Created/Modified

- `docs/ADR.md` — ADR-061 (nouvelle, numéro vérifié sur pièce, structure canonique du dépôt).
- `plugin/dev-orchestrator/references/mission-contracts.md` — section « Contrat
  `estimate:`/`actuals:` », section « Étage revue — deux objets disjoints (ADR-060 / ADR-061) »,
  gabarit « Rapport de mission » étendu d'une ligne Calibration.
- `plugin/dev-orchestrator/agents/vf-coder.md` — §Retour étendu (relais verbatim
  `estimate`/`actuals`, absents si absents en amont). 67 → 74 lignes (limite ADR-029 : 250).
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — §Rapport de mission étendu (relais
  verbatim, aucun recalcul). 217 → 222 lignes (limite ADR-029 : 250).
- `plugin/conductor/references/team-kernel.md` — nouvelle ligne de table §Ce que le kernel
  fournit (hypothèse de dispatch nommé, datée, vérifiée). 79 → 80 lignes.
- `.planning/phases/VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0/21-02-PLAN.md` (ce plan).

## Constat — changement 3 : l'arbitrage retenu et sa justification

**C'est le livrable le plus important de ce plan.** Établi avant de trancher (jamais supposé) :

- **Objet revu** — lu `docs/ADR.md` ADR-060 (§Décision) : `vf-reviewer` → `gsd-code-reviewer`
  relit un **diff de code déjà exécuté et commité**. Lu `~/.claude/gsd-core/bin/lib/review-lane-descriptor.cjs`
  (en-tête, 42.7K) et `~/.claude/gsd-core/workflows/review.md` (`<purpose>`) : les lanes cross-AI
  relisent le **texte d'un `PLAN.md`**, avant toute exécution, avec le prompt « PROJECT.md context,
  phase plans, requirements ».
- **Moment du cycle** — ADR-060 : nœud `revue-N`, `deps=exec-N` (`mission-flow.md` §Pattern E, déjà
  vérifié dans le fichier). `gsd-review` : consommé par `gsd-planner` via un flag `--reviews`
  (`review.md` `<process>` : « produces structured feedback… for the planner to incorporate via
  --reviews flag ») — donc avant `execute-N`, à l'intérieur même de `plan-N`.
  Ces deux moments ne se recouvrent jamais dans le même DAG.
- **Qui déclenche et qui relit** — ADR-060 : posé **systématiquement**, sans condition, par
  `vf-dev-manager` (vérifié : `vf-dev-manager.md:113-119`, point 2 « Revue »). `gsd-review` :
  grep exhaustif de `plugin/dev-orchestrator/references/{gsd-skills-index,intent-routing}.md`
  et du cycle de `vf-coder.md` — **aucune occurrence** d'un appel automatique à `gsd-review` ou
  d'un flag `--reviews` passé par `gsd-plan-phase` tel qu'invoqué par `vf-coder`. C'est un skill
  strictement **opt-in**, listé dans l'index mais jamais orchestré par l'équipe. Les relecteurs
  eux-mêmes diffèrent : CLIs IA tierces (`gemini`, `codex`, `coderabbit`…) détectées par
  `command -v` contre `vf-reviewer`/`gsd-code-reviewer`, internes à la stack Claude.

**Décision** : disjoints, documentés dans ADR-061, aucune fusion. Explicitement écarté : poser un
nœud `plan-review-N` dans le DAG de mission — l'amont lui-même ne livre que la couche déclarative
(`review-lane-descriptor.cjs` DÉCLARE, `invoke_reviewers` reste écrit à la main jusqu'à sa Phase 5b
amont, #2799) ; câbler une intégration automatique maintenant reviendrait à intégrer une brique que
l'amont lui-même n'a pas stabilisée.

## Constat — changement 4 : `gsd-worktree-path-guard.js` face au namespace élargi

Vérifié sur pièce, pas supposé :

- Le hook installé (`~/.claude/hooks/gsd-worktree-path-guard.js`, en-tête `gsd-hook-version: 1.9.0`)
  porte déjà, ligne 176, le motif `^(worktree-)?agent-[A-Za-z0-9._/-]+$` — exactement le motif élargi
  par #1995 cité dans le digest de mission. **Aucun défaut** : le hook a été mis à jour par
  l'installation 1.9.0 en même temps que le reste du moteur.
- Cas réel confronté (ce worktree de mission lui-même) : `git rev-parse --git-dir` renvoie
  `/Users/samuel/Documents/dev/vibeflow-os/.git/worktrees/vibeflow-os-p21` (donc bien un worktree
  lié) ; `git symbolic-ref --short HEAD` renvoie `feat/phase-21-alignement-gsd-core-190`, qui ne
  matche PAS le motif `agent-*`. Comportement attendu : le hook est un **no-op** ici, car cette
  branche n'est pas un worktree géré par `gsd-executor` (`isolation="worktree"`) mais un worktree
  de mission créé manuellement — exactement le cas que le commentaire du hook (ligne 169-173)
  documente comme devant rester non enforcé.
- Le cas d'échec `{committed: false, reason: 'staging_failed' | 'staging_timeout', ...}` (#2608)
  est entièrement interne à `gsd-executor` (upstream, pas un fichier VibeFlow). Vérifié : aucune
  logique de retry côté VibeFlow ne l'enveloppe — le seul retry documenté chez nous porte sur
  l'ÉTAGE entier (`vf-dev-manager.md` §Contrôle de flux, « Blocage… 3 options »), jamais sur un
  `git add` individuel. Rien à corriger, rien à câbler : signalé ici comme vérifié, pas ignoré.

## Decisions Made

- **Deux points de câblage pour estimate:/actuals:**, pas un seul (mission-contracts.md ET les
  deux agents) : un contrat non reflété dans les fichiers qui produisent réellement les retours
  reste une intention écrite, jamais un comportement observable.
- **ADR dédiée pour le changement 3**, pas une simple section : l'arbitrage est structurant (il
  ferme une question qui reviendrait sinon à chaque lecture du delta 1.9.0) et suit le patron déjà
  validé par ADR-060 elle-même.
- **Aucun mécanisme de repli construit pour le changement 4** : VibeFlow est Claude-Code-exclusif
  aujourd'hui (`mission-contracts.md` D5(a)), donc l'hypothèse de dispatch nommé tient par
  construction du périmètre du plugin, pas par un garde-fou machine. Documenter la limite suffit ;
  bâtir un mapping vers des built-ins qu'aucun lab ne cible aurait été de la sur-ingénierie.

## Deviations from Plan

Aucune. Le digest de mission listait déjà les 3 changements avec leurs exigences précises ; ce
plan les a traités dans l'ordre 2 → 3 → 4 sans écart de périmètre. Le point « dette de version
1.8.0 → 1.9.0 » du diagnostic amont (`mission-contracts.md:148,172` entre autres) est resté hors
périmètre — il n'est listé sous aucun des changements 2/3/4, et le digest ne l'assigne pas à ce
plan.

## Issues Encountered

Aucune. Les quatre gates de sortie (suites de tests, `check-agents.sh --strict` sur les 6
dossiers d'agents, `check-version-sync.sh`, `check-mission-invariants.sh`) sont tous verts —
respectivement aucun `KO`, aucun `KO`, `EXIT: 0`, et `EXIT: 3` (SAIN, le seul code attendu comme
« vérifié conforme » pour ce script).

## User Setup Required

Aucune configuration de service externe.

## Next Phase Readiness

- Les changements 2, 3 et 4 du delta gsd-core 1.9.0 sont instruits. Combinés au plan 21-01
  (défaut MCP actif corrigé), les 4 nouveautés du delta identifiées par le diagnostic de mission
  sont closes.
- Reste non couvert par la Phase 21 (hors périmètre des deux plans, signalé dans le diagnostic
  amont sous « Dette de version » et « Observation annexe ») : les références figées à « gsd-core
  1.8.0 » dans `gsd-skills-index.md` (auto-généré), `mission-contracts.md` (:148/:172 avant cette
  entrée — non touchées par ce plan, hors périmètre des changements 2/3/4), `check-gsd-engine.sh`
  et son test, `detect-gsd-engine.sh` ; et les deux hooks 1.9.0 non câblés dans `settings.json`
  (`gsd-ensure-canonical-path.js`, `gsd-update-banner.js`) — signalés par le diagnostic comme
  sujet `gsd-core`, pas VibeFlow. À reprendre sur un nœud dédié si le manager le décide.

## Self-Check: PASSED

- `docs/ADR.md`, `plugin/dev-orchestrator/references/mission-contracts.md`,
  `plugin/dev-orchestrator/agents/vf-coder.md`, `plugin/dev-orchestrator/agents/vf-dev-manager.md`,
  `plugin/conductor/references/team-kernel.md` : FOUND, contenu vérifié par relecture post-édition.
- Commit `064e94a` (ADR-061) : FOUND dans `git log`.
- Commit `6adc690` (mission-contracts.md) : FOUND dans `git log`.
- Commit `a610a9b` (vf-coder.md / vf-dev-manager.md) : FOUND dans `git log`.
- Commit `6b17dbf` (team-kernel.md) : FOUND dans `git log`.
- `grep -c '^## ADR-061' docs/ADR.md` = 1 ; script de contiguïté/unicité des numéros d'ADR : `ADR
  ok, dernier = 61`.
- Gates de sortie : suites de tests (aucun `KO`), `check-agents.sh --strict` × 6 dossiers (aucun
  `KO`), `check-version-sync.sh` (`EXIT: 0`), `check-mission-invariants.sh` (`EXIT: 3`, SAIN).
- Lignes ADR-029 : `vf-coder.md` 74/250, `vf-dev-manager.md` 222/250 — vérifiées par `wc -l` après
  édition, pas supposées.

---
*Phase: VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0*
*Completed: 2026-07-31*
