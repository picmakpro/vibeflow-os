# Mission Phase 34 — Gaps agency-agents & cadrage skill-installer

**Date** : 2026-09-15 · **Manager** : `vf-dev-manager` · **Mode** : superviser
**Branche** : `feat/phase-34-gaps-agency-agents-skill-installer` (depuis `main@7e504ad`)
**Base de mission** : `7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f` · **HEAD** : `4791430`
**Verrou** : `mission-phase34`, generation `DRIVER.lock.gen.1789433045.48814`

---

## Plan de bataille

DAG à 11 nœuds (`.planning/MISSION-34.dag.json`), 4 vagues + vérification :

| Vague | Nœuds | Exécutant |
|---|---|---|
| 1 (parallèle, périmètres disjoints) | `exec-34-01`, `exec-34-02`, `exec-34-03` | `vf-test-orchestrator` (D-04), `vf-coder` ×2 |
| vérification | `revue-w1` + `audit-w1` (parallèle) | `vf-reviewer`, `vf-auditer` |
| 2 / 3 | `exec-34-04`, `exec-34-05` | `vf-coder` (no-op tracés) |
| 4 | `exec-34-06`, `revue-w4`, `docs` | `vf-coder`, `vf-reviewer` |

Choix de structure : `exec-34-04` placé derrière **revue-w1 ET audit-w1**, pas seulement derrière
`exec-34-01` — son checkpoint est one-way (la sortie d'expérimental devient une promesse distribuée
lue à l'installation), la trace du run devait donc être relue avant qu'on agisse sur son verdict.

## Les trois verdicts rendus

1. **AGTS-01 — rendue, cochée.** Note `34-AUDIT-AGTS.md` : matrice division → module re-mesurée
   (25 agents distribués + 6 `AGENT.md` = 31, recoupé avec `34-RESEARCH.md` du même jour, aucun
   écart), verdict par gap. Testing → **reporter** (adossé à AGTS-02, D-06 non révisé) ; tous les
   autres → **refuser**, avec la preuve manquante nommée au sens D-02. **Zéro agent créé** (D-01).
2. **SKIL-01 — NO-GO, cochée.** `CONTROLE-NEGATIF: ECHEC` (la sonde discrimine) et
   `CAS-A: ATTEINT` : le canal `/plugin` natif atteint déjà un sous-agent doté de `Skill`. Pas de
   trou mesuré → premier terme de D-07 non rempli, second sans objet. Item BACKLOG du 2026-06-04
   **clos**, anti-feature `REQUIREMENTS.md:1093` **maintenue gravée**. Décision **one-way**.
3. **AGTS-02 — REPORTÉE avec trace, non cochée.** Run réel joué sur `Scroll-Off/frontend`, iOS :
   `PIPELINE: VERT` / `EQUIPE: ROUGE` → chapeau **ROUGE**. Plans 34-04 et 34-05 clos en **no-op
   tracés**. `mobile-test`(-team) restent expérimentaux, `web-test-team` n'est pas construite.

**Verdicts par sprint** — 34-01 : ROUGE (reporté) · 34-02 : NO-GO · 34-03 : passed ·
34-04 / 34-05 : no-op tracés fondés · 34-06 : ledger posé · revue-w1, audit-w1, revue-w4 : passed.

## Gates humains (aucun franchi par repli ni par timeout)

`AskUserQuestion` indisponible en sous-agent → cascade D-09 : `SendMessage(main)` à chaque fois.
Quatre arbitrages rendus par Samuel, tous **AskUserQuestion session principale, 2026-09-15** :

1. Verdict SKIL-01 = **NO-GO**.
2. Vecteur de mesure (`claude` CLI frais en `--permission-mode bypassPermissions`) jugé
   **acceptable** pour cette mesure.
3. Sortie du statut expérimental = **NON** ; revert du commit Metro `4679f8d` dans Scroll-Off.
4. Purge des résidus (1) cache plugin et (2) entrée orpheline ; (3) transcripts **conservés**.
   Puis : angle mort du gate de nettoyage → item BACKLOG daté, plan 34-02 laissé en archive.

## Défauts trouvés et comblés (5 tours de correction)

| # | Trouvé par | Défaut | Portée |
|---|---|---|---|
| 1 | manager | Verdicts du run écrits en **gras** → invisibles aux sondes ancrées `^PIPELINE:` ; l'exit 1 était attribué au seul faux positif README alors qu'il avait **deux** causes | précondition machine de 34-04 illisible |
| 2 | revue-w1 | `34-01-SUMMARY.md` périmé : affirmait que le commit Metro existait encore après son revert | deux livrables de la même vague se contredisaient |
| 3 | revue-w1 | « les 18 agents sans `Skill` sont **tous** `vf-internal: true` » — faux (`vf-test-orchestrator`). Affirmation **prescrite mot pour mot par le plan** et recopiée sans recoupement | partait **verbatim dans le ledger** |
| 4 | audit-w1 | Nettoyage « prouvé » ne vérifiant que ses **propres** chemins : 3 résidus survivaient (`claude plugin uninstall` ne vide pas le cache disque) | preuve incapable de rendre rouge |
| 5 | audit-w1 | « diff à un seul hunk » : 2 clés diffèrent en réalité | 3ᵉ occurrence du même motif dans la note qui le raconte |
| 6 | manager | `check-machine-paths.sh` **cassé par la mission** (vert à la base, rouge à HEAD) — qualifié à tort de « pré-existant » par un worker qui l'avait mesuré contre **son** ancre d'entrée | la PR serait partie rouge |

## Gates CI rejoués (job `gates` de `ci.yml`, lu puis rejoué — jamais une liste recopiée)

`check-agents --strict` par dossier (6) · par `AGENT.md` (6) · monde fermé (6) ·
`check-version-sync` · `check-state-integrity` · `check-capability-activation` ·
`check-machine-paths` (1349 fichiers) · gates workstream-aware sur fixture (9 verdicts) ·
`check-divergence` avec **mutation rouge prouvée** (3 verdicts) → **tous exit 0**.
`check-release-tag --remote` non joué : main-only, ne se déclencherait pas sur cette PR.

## Périmètre

`git diff --quiet 7e504ade… -- plugin scripts docs manual .github README.md README.fr.md` → **exit 0**
du début à la fin. **Aucune ligne de code livré, aucun agent créé.** 21 commits, tous sous
`.planning/`. Aucun commit sur `main`.

**Hors dépôt** : `~/.claude` purgé de `skil01` (hors transcripts, conservés), sauvegarde
`~/.claude.json.bak-20260915-032715` laissée à la main de Samuel. `Scroll-Off/frontend` :
commit Metro défait (`reset --hard 56efc9e`, aucun push) ; `.vibeflow/mobile-test.json` et
`workflow.use_worktrees: false` **conservés** (préparation projet prévue par le plan).

## Allègements assumés (déclarés, pas silencieux)

- `revue-w23` non dispatchée à un juge : deux SUMMARY documentaires de no-op, préconditions
  re-mesurées par le manager ; couverture reprise par `revue-w4` (vagues 2-3-4) — pas de trou.
- Micro-correction « un seul hunk » vérifiée par le manager plutôt que par un 3ᵉ cycle de juges.
- `revue-w4` n'a pas délégué à `gsd-code-reviewer` : diff 100 % markdown de gouvernance.

## Réserves ouvertes (aucune bloquante)

- `34-RESEARCH.md:629` — confusion factuelle **préexistante** sur 3 agents, neutralisée en aval,
  hors périmètre de la phase. À surveiller si un futur mandat relit cette ligne directement.
- `34-06-SUMMARY.md:3-7` — statut `blocked` non retouché après résolution par des commits
  postérieurs et hors de son plan. Artefact historique honnête ; le ledger vivant est correct.
- `34-05-SUMMARY.md` ne porte pas l'attribution d'arbitrage (son no-op découle d'une précondition
  machine doublement fausse, indépendante de la décision humaine).

## Next step

**Recette manuelle par Samuel avant toute reprise d'AGTS-02** : vérifier le Keychain du simulateur
`8BD53E84-B5BF-482A-8FE5-6A9980555951` et la disponibilité du backend Scroll-Off, pour départager
(a) session réellement perdue et (b) bug de robustesse de `fetchRenewToken` sur échec réseau. C'est
le déclencheur de reprise inscrit au ledger, et la machine ne peut pas le trancher.

Ensuite seulement : `/gsd-plan-phase 25` (calibration ADR-029), débloquée par la clôture de la 34.
