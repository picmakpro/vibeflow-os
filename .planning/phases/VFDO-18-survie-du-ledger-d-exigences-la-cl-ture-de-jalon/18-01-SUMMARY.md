# 18-01 — SUMMARY

**Requirement** : LEDG-02 (gate de survie du ledger d'exigences à la clôture d'un jalon)
**Statut** : livré, testé, silencieux sur ce dépôt

## Checkpoint T1 (tranché par Samuel, 2026-08-18)

Réponse : `option-a` (fichier-sentinelle versionné `.planning/.requirements-survival-armed`),
« noms OK » — aucun renommage des noms proposés par le plan (`requirements-survival-detect.sh`,
`vf_ledger_state`, tags `[ledger-absent]`/`[ledger-illisible]`/`[ledger-outil-absent]`/
`[ledger-exigences-disparues]`).

## Commits

- `6ae1eb3` — `feat(18-01): primitive et gate de survie du ledger d'exigences (LEDG-02)`.
- `65a4edd` — `feat(18-01): câblage hooks.json, inventaire durable et doctrine du marqueur d'armement`.
- `95c4956` — `docs(18-01): requalifie deux citations de précédent fausses dans le plan`.
- `de11f40` — `test(18-01): suite du gate de survie du ledger, 5 issues QUAL-01 discriminantes par mutation`.
- `942a3c5` — `test(18-01): ferme 5 trous de couverture réels (ratio QUAL-01, 1,30x → 1,48x)`.

## Ce qui a été livré

- `requirements-survival-detect.sh` — primitive sourcée (`vf_ledger_state`), détecte la clôture d'un
  jalon, l'absence du ledger vivant, et le diff d'IDs entre l'archive et le ledger vivant (contrat
  A-18-08, arbitrage Samuel du 2026-08-18).
- `check-requirements-survival.sh` — gate `SessionStart`, 5 issues QUAL-01 (silence /
  `[ledger-absent]` / `[ledger-exigences-disparues]` / `[ledger-illisible]` bruyant /
  `[ledger-outil-absent]` bruyant), jamais de FAIL sur le contenu (D-18-10).
- `hooks.json` — 6e entrée `SessionStart · startup`, forme exec, groupe unique existant.
- `docs/HOOKS-CONTRAT-SORTIE.md` — parc 28 → 29, inventaire et assertion mis à jour ensemble.
- `.planning/.requirements-survival-armed` — marqueur d'armement, premier fichier-sentinelle
  versionné par git dans `.planning/` de ce repo.
- `plugin/dev-orchestrator/AGENT.md` — table des signaux `[ledger-*]` + doctrine de l'objet
  inaugural (marqueur d'armement).
- `test-check-requirements-survival.sh` — 436 lignes, 41 assertions, 0 ko.
- `test-hook-exit-contract.sh` — étendu au 5e script (check-requirements-survival.sh), 40 OK/0 KO.

## Compteurs réels

```
$ bash plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh
== résultat : 41 ok, 0 ko ==

$ bash plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh
== résultat : 40 OK / 0 KO ==

$ bash plugin/dev-orchestrator/scripts/check-requirements-survival.sh --path .
(0 octet stdout, exit 3)
```

Mesuré sur l'archive réelle `agentique-v1.0-REQUIREMENTS.md` : 136 IDs de corps, 115 tracés, 114
requis (garantis/voyageurs non caduques), 0 manquant côté `.planning/REQUIREMENTS.md` vivant —
silence confirmé par exécution réelle sur ce dépôt.

## Déviations déclarées

1. **Détection de mention nue du jeton `carried-from:` en prose** (`.planning/REQUIREMENTS.md:932`,
   `` trace `carried-from:` `` — backtick immédiatement après les deux-points, sans valeur). Ce
   n'est pas une tentative de trace ; la flaguer aurait cassé le silence exigé sur ce dépôt (D-18-10 :
   lire une absence, jamais juger la prose qui la décrit). Exclusion ajoutée à la détection de trace
   malformée.
2. **Titre/frontmatter de `restore-requirements-ledger.sh` (bug trouvé en vague 2)** : n'affecte pas
   cette vague, documenté dans `18-02-SUMMARY.md`.
3. **Ratio QUAL-01** : 5 cas de couverture réels ajoutés (mention nue en prose, indépendance
   `VF_LEDGER_ARMED` du diff d'IDs, plusieurs IDs disparus, H2 ouvert avant le H2 clos, archive en
   lien symbolique T-18-02) — ratio 1,30× → 1,48×, dans la bande de convention du module par
   complétude de couverture, jamais par ajout de lignes pour atteindre un chiffre.

## Reliquat

Aucun. LEDG-02 est couvert dans son périmètre complet (détection d'absence de fichier ET diff d'IDs),
5 issues QUAL-01 discriminantes par mutation, parc de hooks à jour.
