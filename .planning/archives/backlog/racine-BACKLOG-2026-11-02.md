## Installeur et tests `plugin/_internal` sans module dans la carte — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02)

**Origine :** lecture de la carte du cockpit (session principale, 2026-11-02, demande de Samuel). Constat de carte, pas d'audit du code : `n:unassigned` porte 43 fichiers (~18 000 lignes), dont `plugin/_internal/vibeflow-update.sh` (l'installeur) et ses suites de tests.
- **À faire :** poser des globs dans `architecture.json` pour que l'installeur et `plugin/_internal/tests/` aient un nœud propre, puis relire ce qui reste dans `unassigned`.

**Déclencheur de reprise :** la prochaine évolution de l'installeur ou de la carte du cockpit.

**Résultat (2026-11-02) :** corrigé dans le générateur, pas dans `architecture.json`, qui est généré et gitignoré. Commit `54b2d0fa` sur `feat/v2-cockpit` (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02). `vf-cockpit-code-vf.mjs` crée maintenant un nœud `infra` pour tout dossier de `plugin/` sans `module.json`, avec un enfant `tests`. La règle est générique, sans liste de noms. Trois dossiers étaient concernés : `_internal`, `commands` et `installer`.
- **Mesure** (`node plugin/cockpit/scripts/vf-cockpit-build.mjs . --quiet`) : `unassigned` passe de 43 fichiers (17 939 lignes) à 0, et le nœud disparaît du graphe.
- **Preuve** : cas C4 de `test-cockpit-onglet-code.sh`, 3 FAIL sur l'ancien générateur, 18 PASS / 0 FAIL après.
- **Reste ouvert hors de cette entrée** : `ci.yml` ne rejoue aucune suite du cockpit.

## `dev-orchestrator` : 26 500 lignes et responsabilités mêlées — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02)

**Origine :** même lecture de carte. 53 fichiers, surtout du shell : routage d'intention, gate de sortie de mission (`check-mission-exit.sh`), bootstrap des dépendances (`ensure-deps.sh`), index GSD. Recoupe l'étude d'extraction du 2026-08-05 (extraction possible en plugin natif).
- **À faire :** décider si l'on scinde (routage / gates / dépendances) ou si l'on extrait ; mesurer d'abord où vivent réellement les 26 500 lignes (tests compris).

**Déclencheur de reprise :** la reprise de l'étude d'extraction DevFlow, ou la prochaine phase qui touche à ce module.

**Résultat (2026-11-02) :** mesuré en `rtk proxy find plugin/dev-orchestrator/<dossier> -type f -exec cat {} + | wc -l`, sur 30 456 lignes en tout : `scripts/tests` 17 223 (15 suites), `scripts` hors tests ~7 076 (31 fichiers), `references` 3 346, `agents` 555, `skills` 116, `hooks` 18. Le volume vient surtout des tests, pas d'un code aux responsabilités mêlées. Décision : ni scinder ni extraire (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02). La reprise de l'étude d'extraction DevFlow repart de ces chiffres.

## Gates de `dev-orchestrator` à rejouer sur témoin rouge — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02)

**Origine :** même lecture, rapprochée de la leçon « une preuve doit pouvoir rendre rouge ». Candidats : `check-capability-activation.sh`, `check-mission-exit.sh`. Non vérifié : aucun gate n'a été muté dans cette session.
- **À faire :** pour chaque gate du module, muter l'entrée, constater le rouge, consigner le témoin. Un gate qui ne rougit jamais est retiré ou corrigé.

**Déclencheur de reprise :** la prochaine modification d'un gate de ce module, ou un vert suspect en CI.

**Résultat (2026-11-02) :** sonde jouée sur une copie jetable par gate (`git archive HEAD | tar -x`, `HOME` temporaire). Pour chacun des 8 `check-*.sh` du module, la suite dédiée `tests/test-check-<gate>.sh` a été jouée deux fois : copie intacte (témoin), puis gate neutralisé par un `exit 0` inséré en ligne 2.
- **Témoins verts** : capability-activation 60/60, dev-bootstrap 39/39, doc-drift 21/21, gsd-engine 15/15, hook-paths 17/17, mission-exit 135/135, requirements-survival 66/66. Pour gsd-config, 36/38 : les cas 20 et 26 refusent de passer au vert sans moteur gsd-core, absent du `HOME` temporaire. C'est le comportement voulu, pas un défaut.
- **Mutants rouges, tous** (rc=1) : KO 33, 32, 18, 32, 10, 10, 125, 50 respectivement.

Aucun gate ne reste vert une fois neutralisé : aucun n'est à retirer ni à corriger. Clos par arbitrage Samuel, AskUserQuestion session principale, 2026-11-02. Limite : la mutation testée est la plus grossière (neutralisation complète), pas l'inversion d'une condition ; des mutations plus fines n'ont pas été jugées nécessaires.

