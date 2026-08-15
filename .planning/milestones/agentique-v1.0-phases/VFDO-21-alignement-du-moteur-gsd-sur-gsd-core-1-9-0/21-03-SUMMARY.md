---
phase: 21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
plan: 03
status: complete
---

# 21-03 — Purge de la dette de version 1.8.0 et arbitrage des hooks 1.9.0 non câblés

## Performance

- **Durée** : session unique (cadrage inclus dans le digest de mission, pas de cycle
  discuss/plan séparé — rituel allégé, cf. 21-01/21-02).
- **Tâches** : 2 changements du digest (purge de version figée, arbitrage hooks non câblés) — les
  2 derniers reliquats de la Phase 21, explicitement signalés par 21-02 §Next Phase Readiness.
- **Fichiers modifiés** : 9. **Commits** : 3 (+ ce commit PLAN/SUMMARY).

## Accomplissements

- **Changement 5 — purge de la dette de version 1.8.0 → 1.9.0** : `build-gsd-index.sh` (défaut
  `GSD_CORE_PACKAGE`) corrigé puis `gsd-skills-index.md` régénéré (jamais édité à la main — le
  script a été ré-exécuté contre les 71 skills réellement installés sur ce poste) ;
  `mission-contracts.md` (2 occurrences, D4 « dist-tag stable »), `check-gsd-engine.sh` (en-tête
  D-05), `detect-gsd-engine.sh` et `ensure-deps.sh` (occurrence supplémentaire trouvée sur pièce,
  non listée par le digest) mis à jour. `test-check-gsd-engine.sh` cas 8 déplacé dans le même
  commit que le texte qu'il vérifie, prouvé discriminant par mutation.
- **Changement 6 — arbitrage des 2 hooks 1.9.0 non câblés** : posé ADR-062, qui confronte
  séparément `gsd-ensure-canonical-path.js` et `gsd-update-banner.js` à leur propre contrat
  d'activation documenté et à l'état réel du poste — conclusion : les deux absences sont
  **correctes**, aucune extension de `merge-hooks.sh`. `README.md` du module gagne un pointeur
  bref vers l'ADR. Index `docs/ADR.md` corrigé au passage (ADR-060/061 y manquaient malgré leur
  validation antérieure en Phase 20/21-02).

## Task Commits

1. **Purge de version — bloc non couplé à un test (Changement 5)** : `dfb3ee6` (fix) —
   `build-gsd-index.sh`, `gsd-skills-index.md` (régénéré), `mission-contracts.md`,
   `detect-gsd-engine.sh`, `ensure-deps.sh`.
2. **Purge de version — bloc couplé au test (Changement 5)** : `243d2c8` (fix) —
   `check-gsd-engine.sh` + `test-check-gsd-engine.sh` cas 8, dans le même commit (le texte
   documentaire et son assertion littérale ne peuvent pas être séparés sans fenêtre rouge).
3. **ADR-062 + pointeur README (Changement 6)** : `64c8371` (docs).
4. **PLAN + SUMMARY** : ce commit (docs).

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/build-gsd-index.sh` — défaut `GSD_CORE_PACKAGE`
  `@opengsd/gsd-core@1.8.0` → `@opengsd/gsd-core@1.9.0`.
- `plugin/dev-orchestrator/references/gsd-skills-index.md` — régénéré (auto-généré, jamais édité
  à la main). En-tête daté du jour, package 1.9.0. 3 entrées nouvelles dans la section secondaire
  « Workflows GSD » (`list-seeds`, `onboard`, `smart-entry`) — la précédente génération datait du
  2026-07-26, antérieure à la migration 1.9.0 de ce poste ; la section « Skill » (frontmatter,
  source primaire) reste à 71 entrées, inchangée.
- `plugin/dev-orchestrator/references/mission-contracts.md` — 2 occurrences (§Seuil de bascule
  vf-auto : forme reprise du snippet amont ; §D4 dist-tag stable) mises à jour vers 1.9.0.
- `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` — en-tête D-05 (:25, 2 occurrences sur la
  même ligne) réécrit sur 1.9.0, la leçon du piège semver reformulée avec le nouveau numéro (le
  fork repart de zéro : 1.9.0 < 1.42.3 en semver).
- `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` — cas 8 : variable renommée
  `c_180`→`c_190`, pattern `1\.8\.0`→`1\.9\.0`, commentaire de tête ajouté rappelant que ce cas
  doit bouger avec le texte à chaque migration future.
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` (:73) — occurrence trouvée sur pièce, hors
  énumération du digest de mission (même famille documentaire que `detect-gsd-engine.sh:30`,
  aucun test ne l'assertait littéralement).
- `plugin/planning-core/scripts/detect-gsd-engine.sh` (:30) — commentaire de cascade mis à jour.
- `docs/ADR.md` — ADR-062 (nouvelle) + correction de l'index (ajout des lignes ADR-060/061/062,
  absentes du tableau malgré leur validation en Phase 20/21-02).
- `plugin/dev-orchestrator/README.md` — pointeur bref dans §Structure du module (`hooks/hooks.json`)
  vers ADR-062, précisant que le fragment VibeFlow ne couvre pas les hooks `gsd-core` amont.
- `.planning/phases/VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0/21-03-PLAN.md` (ce plan).

## Constat — Changement 5 : occurrence supplémentaire hors digest

Le digest de mission énumérait 5 cibles (`gsd-skills-index.md`, `build-gsd-index.sh`,
`mission-contracts.md` ×2, `check-gsd-engine.sh`, `detect-gsd-engine.sh`). Un grep exhaustif sur
`plugin/dev-orchestrator` et `plugin/planning-core/scripts` (hors `CHANGELOG.md`) a fait remonter
une 6e occurrence non listée : `ensure-deps.sh:73` (« scope --local de gsd-core 1.8.0 »), même
famille documentaire que `detect-gsd-engine.sh:30`. Traitée par cohérence avec l'intention du
Changement 5 (« purger la dette de version figée » — exhaustif dans le périmètre, pas limité à
l'énumération du digest, qui documentait un état « relevé sur pièce » avec l'avertissement
explicite de re-constater avant d'éditer). Aucun test ne l'assertait littéralement — pas de couplage
test à gérer, contrairement au cas 8.

## Constat — Changement 5 : `test-check-gsd-engine.sh` cas 8, preuve par mutation

Établi avant de conclure, pas supposé :

- Mutation appliquée sur `check-gsd-engine.sh:25` (ses 2 occurrences de `1.9.0` → `1.9.9`, la
  même ligne) : cas 8 passe **rouge** (`142=3 190=0 semver=2`), confirmant que le test discrimine
  réellement le texte et n'est pas tautologique.
- Restauration vérifiée par `diff` nul contre la sauvegarde pré-mutation, suite relancée :
  `15 ok, 0 ko`.
- `vf-reviewer` a reproduit indépendamment cette mutation (toutes occurrences ramenées à `1.8.0`)
  pendant sa revue et obtenu le même résultat rouge (`14 ok, 1 ko`) — double confirmation.

## Constat — Changement 6 : arbitrage ADR-062, preuves ligne par ligne

Chaque affirmation de l'ADR vérifiée sur pièce avant d'être écrite (pas supposée) :

- **`gsd-update-banner.js`** (`~/.claude/hooks/gsd-update-banner.js:6-9`) : en-tête confirmé mot
  pour mot — enregistrement opt-in par l'installeur amont, actif seulement si la statusline GSD
  est déclinée. `~/.claude/settings.json` câble déjà `gsd-statusline.js` (bloc `statusLine`,
  ligne 339-341) : la statusline EST installée sur ce poste, donc la non-registration du banner
  est le comportement voulu par gsd-core, pas un gap.
- **`gsd-ensure-canonical-path.js`** (`~/.claude/hooks/gsd-ensure-canonical-path.js:4-14`) :
  en-tête confirmé — répare un problème d'install qui n'existe que sous une install `gsd-core` en
  plugin marketplace Claude Code (`CLAUDE_PLUGIN_ROOT`). `ensure-deps.sh:263` bootstrappe
  `gsd-core` via `npx -y "@opengsd/gsd-core@^1" --claude <scope>` — l'installeur npm classique que
  le hook cite lui-même comme n'ayant pas besoin de sa correction. Vérifié : `~/.claude/gsd-core/`
  est un répertoire réel sur ce poste (`[ -L ... ]` négatif), pas un lien posé par ce hook.
- **`merge-hooks.sh`** (`plugin/_internal/merge-hooks.sh:145-150`) : commentaire existant
  (« hooks tiers/gsd-core ») confirmé sur pièce — script non modifié, l'ADR confirme l'intention
  déjà écrite avec des preuves plutôt que de la dupliquer.
- **Limite assumée, écrite dans l'ADR** : la conclusion est vérifiée sur CE poste (statusline
  installée, install npm classique). Un lab qui installerait `gsd-core` en plugin marketplace, ou
  déclinerait la statusline, changerait la conclusion — l'ADR ne prétend pas couvrir ce cas
  hypothétique.

## Decisions Made

- **`gsd-skills-index.md` jamais édité à la main** : seul son générateur est corrigé, puis
  ré-exécuté — cohérent avec D4 (anti-hallucination) déjà établi pour ce fichier.
- **Occurrence `ensure-deps.sh:73` traitée malgré son absence du digest** : la lettre du digest
  énumère 5 cibles « relevées sur pièce, à re-constater avant d'éditer » — pas une liste fermée ;
  l'intention du Changement 5 (purge exhaustive) prime sur une énumération connue incomplète par
  construction.
- **Cas 8 traité comme un seul changement avec le texte qu'il vérifie** : commit dédié couplant
  `check-gsd-engine.sh` et son test, pour ne jamais laisser une fenêtre où l'un des deux est faux
  par rapport à l'autre.
- **ADR-062 plutôt qu'une simple ligne dans un README** : l'arbitrage est structurant (le
  diagnostic de mission le formule explicitement comme « à trancher »), suit le patron déjà
  validé par ADR-060/061, et les deux hooks ont des causes disjointes qui méritent chacune sa
  preuve écrite séparée plutôt qu'une conclusion générique.
- **Aucune ligne de `merge-hooks.sh` modifiée** : le script reste hors périmètre du fichier
  scope de ce plan (`plugin/_internal/**` n'y figure pas) — l'ADR cite son commentaire existant
  sans le dupliquer, exactement le patron qu'ADR-060 applique déjà à `mission-flow.md`.
- **Index `docs/ADR.md` corrigé au passage** : ajouter ma propre entrée (ADR-062) sans corriger
  les deux lignes manquantes juste au-dessus (ADR-060/061, déjà validées en Phase 20/21-02)
  aurait rendu le tableau plus trompeur qu'avant ce plan — correction additive uniquement, aucun
  contenu d'ADR existante modifié.

## Deviations from Plan

Une seule, documentée ci-dessus : occurrence `ensure-deps.sh:73` traitée en plus des 5 cibles du
digest de mission, sans changement de périmètre de fichiers (le fichier est déjà sous
`plugin/dev-orchestrator/scripts/**`).

## Issues Encountered

Aucune. Les gates de sortie (44 suites de tests, `check-agents.sh --strict` sur les 6 dossiers
d'agents avec `--allow-empty` sur `conductor` — structurellement sans sous-dossier `agents/`, état
préexistant et non lié à ce plan —, `check-version-sync.sh`, `check-mission-invariants.sh`) sont
tous verts. Revue `vf-reviewer` : **PASS**, aucun finding.

## User Setup Required

Aucune configuration de service externe.

## Next Phase Readiness

- Les 6 changements du delta gsd-core 1.9.0 identifiés par le diagnostic de mission sont
  maintenant tous instruits : Changement 1 (défaut MCP actif) par 21-01, Changements 2/3/4 par
  21-02, Changements 5/6 par ce plan.
- Reste explicitement hors périmètre des trois plans (par choix, pas par oubli) : la publication
  de la release racine (tag annoté + release GitHub, `VERSION`/`plugin.json`/`marketplace.json`/
  `README*.md`), pilotée par Samuel sur un nœud dédié, et le bump `module.json`/`CHANGELOG.md` de
  `dev-orchestrator`/`planning-core` — suit le même patron que 20-07 (bump groupé au moment de la
  clôture de gouvernance de la phase, pas par plan individuel).

## Self-Check: PASSED

- Les 9 fichiers modifiés : FOUND sur disque, contenu vérifié par relecture post-édition.
- Commit `dfb3ee6` (purge non couplée) : FOUND dans `git log`.
- Commit `243d2c8` (check-gsd-engine.sh + test) : FOUND dans `git log`.
- Commit `64c8371` (ADR-062 + README) : FOUND dans `git log`.
- `grep -c '^## ADR-062' docs/ADR.md` = 1.
- `grep -rn '1\.8\.0' plugin/dev-orchestrator plugin/planning-core/scripts --include=*.sh
  --include=*.md | grep -v CHANGELOG` : seules les fixtures de test hors périmètre subsistent
  (vérifié ligne par ligne).
- Gates de sortie : 44 suites de tests (aucun `KO`), `check-agents.sh --strict` × 6 dossiers
  (aucun `KO` ; `conductor` en `--allow-empty`, état structurel préexistant), `check-version-sync.sh`
  (`EXIT: 0`), `check-mission-invariants.sh` (`EXIT: 3`, SAIN).
- Mutation cas 8 : rouge confirmé (`142=3 190=0 semver=2`) puis restauration vérifiée par diff nul,
  reproduite indépendamment par `vf-reviewer`.
- Revue `vf-reviewer` : verdict PASS, périmètre de fichiers confirmé exact (9/9), aucun finding.

---
*Phase: VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0*
*Completed: 2026-07-31*
