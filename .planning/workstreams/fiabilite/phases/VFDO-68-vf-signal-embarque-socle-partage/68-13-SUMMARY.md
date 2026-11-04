---
phase: 68-vf-signal-embarque-socle-partage
plan: 13
requirements: [VFSG-08]
status: complete
runs:
  rouge: 41857935466
  vert: 41859018567
---

# 68-13 — runs CI rouge puis vert sous Linux (VFSG-08)

Trace : `68-13-RED-TRACE.md` (identifiants, liens, étapes du job « Gates de qualité (mode strict) », image du runner).

## Livré
- PR #199 (brouillon) ouverte par le manager sur consigne de mission (session principale Claude Code, 2026-11-04) ; checkpoint levé à ce titre.
- Push n°1 `a9948a74` (E1 cassé, `embarque.test.tsx:83`) : run `41857935466`, étape « Mod vf-signal… » en `failure`, 0 étape antérieure en `failure`.
- Push n°2 `eb89e98f` (revert, arbre identique à `0d4f8ae0`) : run `41859018567`, même étape en `success`.
- `<verify>` : `OK-RUNS` (failure / success / 0).
- Image du runner : `ubuntu-26.04`. La sonde Linux reportée par 68-09 est jouée par ces runs.
- Durée ajoutée (T-68-27) : job `gates` 56 s / 62 s ; étape du mod environ 40 s.

## Points à connaître
- Le run rouge est `cancelled` au niveau du run (concurrence au push n°2, shards non terminés) ; le verdict de l'étape se lit au niveau du job, qui était terminé.
- Revue `@picmakpro` toujours requise pour le merge (hors preuve).
- Poussés : exactement deux. Trace et SUMMARY commités en local, non poussés.
