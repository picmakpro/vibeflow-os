# 18-03 — SUMMARY

**Requirements** : critère 3 de la ROADMAP §Phase 18 (doctrine D-18-14) + cohérence de version du module
**Statut** : livré

## Commit

- `f728b4d` — `release(dev-orchestrator): v2.18.0 → v2.19.0 — clôture Phase 18 (LEDG-01/02, D-18-14)`.

## Ce qui a été livré

- `AGENT.md` — doctrine D-18-14, placée immédiatement après la table des signaux de démarrage
  (A-18-09), 205 lignes (≤ 250, ADR-029).
- `VERSION`, `module.json`, `README.md`, `CHANGELOG.md` — bump cohérent v2.18.0 → v2.19.0 (Minor,
  A-18-10), CHANGELOG récapitulant fidèlement les deux plans précédents (sur la base des SUMMARY
  réels, pas du cadrage), README étendu (Historique + Structure du module, 3 scripts + 2 suites
  neufs).

## Compteurs réels

```
$ grep -c 'D-18-14' plugin/dev-orchestrator/AGENT.md
1
$ wc -l plugin/dev-orchestrator/AGENT.md
205
$ bash plugin/conductor/scripts/check-agents.sh --agents-dir=plugin/dev-orchestrator/agents
  ⚠ vf-auditer.md : aucun skill cable — agent sans expertise injectee (recommande : skills:)
  ⚠ vf-coder.md : aucun skill cable — agent sans expertise injectee (recommande : skills:)
  ⚠ vf-dev-manager.md : aucun skill cable — agent sans expertise injectee (recommande : skills:)
  ⚠ vf-dev-manager.md : tools — nom d'agent non resolu 'vf-test-orchestrator' (ni type natif, ni fichier plugin/dev-orchestrator/agents/vf-test-orchestrator.md, ni registre)
  ⚠ vf-dev-manager.md : tools — nom d'agent non resolu 'vf-crafter' (ni type natif, ni fichier plugin/dev-orchestrator/agents/vf-crafter.md, ni registre)
  ⚠ vf-dev-manager.md : tools — nom d'agent non resolu 'vf-design-judge' (ni type natif, ni fichier plugin/dev-orchestrator/agents/vf-design-judge.md, ni registre)
  ⚠ vf-reviewer.md : aucun skill cable — agent sans expertise injectee (recommande : skills:)
[check-agents] 0 fichier(s) agent tiers non linte(s) · 30 entree(s) d'allowlist tierce(s) resolue(s) (prefixe(s) : gsd-)
[check-agents] ✓ agents conformes (natif + charte VibeFlow) · 7 warning(s)
(exit 0)
```

**Correction N7 (dégel de revue du 2026-08-18)** : la forme initiale (`check-agents.sh` sans
`--agents-dir`, câblée aux 3 mêmes emplacements dans `18-03-PLAN.md` par la correction N5
précédente) audite `.claude/agents/` du **lab courant** — absent sur ce dépôt de distribution
(« la source des modules, pas un lab »). Son exit 0 signifiait « rien trouvé à vérifier », pas
« agents conformes » : un vert outillé qui ne mordait sur rien. La forme scopée ci-dessus vérifie
réellement le contenu de `plugin/dev-orchestrator/agents/`.

**Les 7 avertissements sont PRÉ-EXISTANTS à cette phase**, prouvé (pas supposé) :
`git diff --stat main..HEAD -- plugin/dev-orchestrator/agents/` rend **vide** — aucun commit de
cette branche ne touche un fichier d'agent. Nature des 7 :
- 4× « aucun skill câblé » (`vf-auditer.md`, `vf-coder.md`, `vf-dev-manager.md`, `vf-reviewer.md`)
  — recommandation, pas une obligation ADR-044.
- 3× nom d'agent non résolu sur `vf-dev-manager.md` (`vf-test-orchestrator`, `vf-crafter`,
  `vf-design-judge`) — ces agents vivent dans **d'autres modules** ; un lint scopé à un seul
  répertoire ne peut structurellement pas les résoudre. Limite de la mesure scopée, pas un défaut
  des agents.

Découverte complète des 12 suites du module (pas un échantillon), toutes rejouées après le bump :

| Suite | Résultat |
|---|---|
| test-check-capability-activation.sh | 60 OK / 0 KO |
| test-check-dev-bootstrap.sh | 35 ok / 0 ko |
| test-check-doc-drift.sh | 21 ok / 0 ko |
| test-check-gsd-config.sh | 37 ok / 0 ko |
| test-check-gsd-engine.sh | 15 ok / 0 ko |
| test-check-hook-paths.sh | 17 OK / 0 KO / 0 SKIP |
| test-check-requirements-survival.sh | 41 ok / 0 ko |
| test-dev-orchestrator.sh | 184 OK / 0 KO / 0 SKIP |
| test-discover-unintegrated-docs.sh | 22 ok / 0 ko |
| test-hook-exit-contract.sh | 40 OK / 0 KO |
| test-inject-mcp-tools.sh | 26 OK / 0 KO |
| test-restore-requirements-ledger.sh | 28 ok / 0 ko |

`test-dev-orchestrator.sh` (T35, densité `AGENT.md`) confirme l'ajout de D-18-14 sans franchir le
plafond ADR-029.

## Périmètre déféré — vérifié non touché

```
$ git status --short VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json \
    README.md README.fr.md .github/workflows/ci.yml plugin/_internal/vibeflow-update.sh
(vide) → RELEASE-META-OK
```

Aucun tag, aucune release GitHub — gestes humains réservés (CLAUDE.md racine, ADR-031).

## Déviations déclarées

Aucune dans cette vague. Les déviations de fond de la phase (double correction de
`vf_ledger_classify`, structure `## Reportées`) sont documentées dans `18-02-SUMMARY.md`.

## Clôture de la Phase 18

Les 5 critères de succès de la ROADMAP §Phase 18 sont tenus : gate (18-01, LEDG-02), rattrapage
(18-02, LEDG-01), doctrine D-18-14 (ce plan), cohérence de version du module (ce plan),
`check-agents.sh` exit 0 (critère 4). Le module `dev-orchestrator` passe de v2.18.0 à v2.19.0.
