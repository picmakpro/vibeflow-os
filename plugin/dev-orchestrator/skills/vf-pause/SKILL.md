---
name: vf-pause
description: >
  Utiliser quand on s'arrête en cours de route et qu'on veut que rien ne se perde — « je
  m'arrête là », « note où on en est », « je coupe, garde le contexte », « on reprendra
  demain », « handoff », « faut que je parte, sauvegarde l'état ». Fige une passation
  lisible : ce qui était en cours, ce qui bloque, la prochaine action.
  ✘ pas pour reprendre le fil à la session suivante → /vf-resume · ✘ pas pour continuer à
  avancer pendant l'absence → /vf-auto · ✘ pas pour livrer un travail terminé → /vf-ship ·
  ✘ pas pour un point d'avancement → /vf-progress.
  ✘ pas pour consigner l'état d'un **lab** non-dev, hors projet de code → /vf-planning.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-pause — Passation de fin de session

Délègue à `gsd-pause-work` : création d'une passation de contexte en cours d'étape — état du
travail, blocages, prochaine action, décisions en suspens.

Reframe toute sortie en vocabulaire VibeFlow : « pause-work / handoff » → **passation**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-pause-work` à
l'utilisateur.

C'est le pendant exact de `/vf-resume` : ce qui est écrit ici est ce qui sera rechargé là-bas. Une
passation qui n'énonce pas la **prochaine action** ne sert à rien.

Enchaînement typique : (travail en cours) → `vf-pause` → *(coupure)* → `vf-resume`.
