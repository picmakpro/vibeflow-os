---
phase: 76
plan: "02"
requirements: [TRAC-05, TRAC-06]
status: executed
---

# 76-02 — Décisions : résumé

## Livré

- `plugin/cockpit/scripts/vf-cockpit-registres.mjs` (module pur, seul import `vf-cockpit-formats.mjs`) : `sectionsAdr`, `definitionsRegistre(txt, { phase, ws, fichier, couper })`, `citations`, `relier`, plus la constante `PREFIXE` (classe de préfixe partagée par définitions, citations et `--grep` git, point admis).
- `plugin/cockpit/scripts/vf-cockpit-trace-git.mjs` : `BORNES_TRACE`, `teteSha`, `commitsCitants`, par `lancerGitAsync` seul ; sha de 40 caractères, `--end-of-options` et `--`, jamais `--all`, `--max-count=2000`, tampon de 8 Mio, corps jeté, délai et borne en `tronque: true`, lab sans git en `absent: true`.
- `plugin/cockpit/scripts/tests/test-cockpit-tracabilite-decisions.sh` : T5.1 à T5.7 et T6.1 à T6.6 (git emballé qui journalise l'argv, git qui dort 30 s, corps de 300 Kio, sujet hostile), 21 PASS.
- Mesure sur le corpus réel : 36 définitions `P71.5-D-` extraites de `71.5-CONTEXT.md` (les 36 lignes du fichier).

Commits : `1bd5c85a` (rouge T5.1), `4f6e416f` (tâche 1), `b3c603c9` (rouge T5.3-T5.7), `3153d517` (définitions et arêtes), `6e6d26ca` (T6), `91a5aed4` (lignes à 160 colonnes).

## À verser par la jointure

`vf-cockpit-registres.mjs` est l'extracteur unique des définitions de registres (P76-D-18), à importer par la Phase 73 pour sa file des arbitrages en attente. Exports : `sectionsAdr(txt) -> [{ id, titre, ligne }]`, `definitionsRegistre(txt, { phase, ws, fichier, couper }) -> [{ id, cle, nue, titre, adr, amendee, ligne }]`, `citations(message) -> { adr, decisions }`, `relier({ adrs, definitions, commits }) -> { parAdr, parDecision, adrSansSection }`. Clé de décision : `<ID>:<ph-id>` (`P90-D-01:ph-90`, `D-04:ph-90`, `P90.5-D-01:ph-90.5`), `ph-id` reçu de l'appelant. `ws` et `fichier` sont acceptés pour la signature, non lus.

## Écarts

- Écart : `definitionsRegistre` a été posée en coque à la tâche 1 (signature de contrat pour la 73, commit `4f6e416f`), son corps livré à la tâche 2 après son rouge.
- Écart : le durcissement de `trace-git` vivait déjà dans le commit de la tâche 1 ; le rouge de la tâche 3 est pris sur une copie jetable au passage naïf (3 FAIL : T6.1, T6.2, T6.4), consigné dans `76-02-RED-TRACE.md`. Pas de commit `feat` séparé pour la tâche 3.
- Écart : un module neuf ne tolère aucune ligne au-delà de 160 points de code (cliquet V4c) ; lignes recoupées (`91a5aed4`), aucune hausse de `colonnes-baseline.txt`.
- Les T5.4 portent trois assertions du même nom d'identifiant ; `✅ PASS — T5.4` figure bien dans la sortie.

## Rituels levés

- Sept mutants du plan (M-NUE-RELIEE, M-DOUBLON, M-PREFIXE-POINT, M-ALL, M-BORNE, M-CORPS-SERVI, M-NOREF) : rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
- Rejeu suite par suite et rejeu des cas sautés en CI : rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Suites jouées (tête `91a5aed4` pour les fichiers de ce plan)

| Suite | Verdict | Durée |
|-------|---------|-------|
| `test-cockpit-tracabilite-decisions.sh` | 21 PASS / 0 FAIL, exit 0 | 4 s |
| `test-cockpit-vendor.sh` | 250 PASS / 2 FAIL (voir ci-dessous) | 83 s |

`test-cockpit-vendor.sh` : V4c.9a rougit sur 4 fichiers du nœud voisin 76-01 (`vf-cockpit-trace-bilans/chaine/collecte/ledger.mjs`, lignes au-delà de 160 colonnes, baseline 0) ; aucun fichier de ce plan n'y figure plus. V4 (`check-file-size.sh`) rougit sur `tests/chrome-coin.mjs` (300 lignes), fichier de la base `faed809d` que ce plan ne touche pas.
