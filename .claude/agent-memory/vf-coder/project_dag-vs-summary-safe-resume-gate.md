---
name: dag-vs-summary-safe-resume-gate
description: Un nœud DAG marqué done sans que gsd-execute-phase ait écrit de SUMMARY.md déclenche le garde-fou de reprise sûre (safe_resume_gate) pour tout plan dispatché après, même hors de sa vague.
metadata:
  type: project
---

Sur les missions pilotées par DAG (`dag-phase*.json`, doctrine `mission-flow.md` Pattern B), un
nœud `exec-XX` peut passer `done` sans que le plan `XX` correspondant porte de `XX-SUMMARY.md`.
Constaté sur `27-03` (Phase 27, `dag-phase27.json` : `exec-27-03` marqué `done`, `revue-v1` et
`audit-v1` en dépendent et sont eux-mêmes `done`, mais aucun `27-03-SUMMARY.md` n'existe alors
que 4 commits de production réels existent sous ce préfixe — `02138e5`, `1ec1f63`, `da8ad8a`,
`807db3d`).

**Why:** `gsd-execute-phase` (`execute-phase.md`, étape `initialize` → `safe_resume_gate`)
dérive `CURRENT_PLAN_ID` du **premier plan incomplet de toute la phase**, avant même
d'appliquer un filtre `--wave`. Un plan orphelin (commits sans SUMMARY) n'importe où en amont
bloque donc le dispatch de **tout** plan postérieur de la même phase — même si le plan visé a
son propre `depends_on` satisfait au niveau du contenu (git log). Constaté en tentant de
dispatcher `27-04` (mandat vf-coder ciblé, wave 2) alors que `27-03` (wave 1, antérieur) porte
ce trou : le garde-fou stoppe avant tout dispatch d'exécuteur, avec trois recours (« close out
manually », « re-execute from scratch », « mark-and-skip »).

**How to apply:** avant de dispatcher `gsd-execute-phase <phase> --wave N` sur un mandat
mono-plan issu d'un DAG, vérifier `git log --oneline --grep="<plan-id>"` ET l'existence de
`<plan-id>-SUMMARY.md` pour **tous** les plans de vagues inférieures, pas seulement celui visé
— `gsd_run query phase-plan-index <phase>` donne `has_summary` par plan en un appel. Un écart
(commits réels, pas de SUMMARY) n'est pas forcément un manque de travail — souvent un plan
`autonomous: false` exécuté via un chemin interactif/manuel qui n'a jamais écrit le SUMMARY
formel — mais reste un arrêt légitime du garde-fou de reprise sûre, hors périmètre d'un mandat
étroit (ne pas fabriquer/écrire ce SUMMARY soi-même si le mandat ne le couvre pas) →
`statut: human_needed` + `reprise`, jamais tranché seul. Voir aussi
[[project_human-check-en-verify-ne-gate-rien]] pour un autre angle du même motif
(`autonomous: false` qui ne se traduit pas proprement en artefact machine-lisible).
