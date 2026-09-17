---
name: mandat-perimetre-strict-contredit-gsd-quick
description: Depuis B2, un mandat vf-coder qui interdit « tout autre fichier » ou prescrit un commit direct pousse le worker à sauter gsd-quick --validate ; autoriser explicitement ses artefacts
metadata:
  type: feedback
---

Sur 4 mandats vf-coder du hotfix v2.63.2 (2026-09-17), 2 seulement ont réellement déroulé `gsd-quick --validate`, pourtant obligatoire depuis B2 :
- le lot tests l'a amorcé puis a édité en direct ;
- la correction ciblée l'a écarté, parce que le mandat interdisait « tout autre fichier » et prescrivait un commit par pathspec, deux consignes que les artefacts `.planning/quick/` et STATE.md contredisaient ;
- le lot release a été bloqué par le harness en worktree imbriqué.

**Why:** un mandat qui interdit tout sauf N fichiers ne laisse aucune place aux artefacts du moteur (PLAN, SUMMARY, ligne STATE). Le worker résout la contradiction en sacrifiant la voie obligatoire.

**How to apply:** dans chaque mandat vf-coder, écrire noir sur blanc que les artefacts `gsd-quick` (`.planning/quick/<id>/`, ligne STATE) font partie du périmètre autorisé, et que le périmètre interdit ne vise que le code et la doctrine. Exiger dans le retour la preuve que le pipeline a tourné (quick_id, verdict `gsd-verifier`), sinon statut `gaps_found`. Voir [[mandat-cumulatif-jamais-exclusif]].
