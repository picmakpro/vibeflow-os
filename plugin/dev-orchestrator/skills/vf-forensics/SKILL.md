---
name: vf-forensics
description: >
  Utiliser après coup, quand un cycle de travail a déraillé et qu'on veut comprendre
  pourquoi — « pourquoi ça a foiré ? », « post-mortem », « analyse l'échec de ce sprint »,
  « on comprend pas comment on en est arrivé là », « le mode autonome est parti en vrille »,
  « qu'est-ce qui s'est passé cette nuit ? ». Reconstitue la chronologie du cycle, isole le
  point de bascule et remonte les causes racines.
  ✘ pas pour un bug applicatif en cours → /vf-debug · ✘ pas pour tirer les enseignements
  d'un cycle réussi → /vf-learn · ✘ pas pour annuler le travail fautif → /vf-undo.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-forensics — Post-mortem de cycle

Délègue à `gsd-forensics` : investigation post-mortem d'un cycle de travail en échec — état des
artefacts, chronologie, point de bascule, causes racines et remédiation proposée.

Reframe toute sortie en vocabulaire VibeFlow : « forensics » → **post-mortem de cycle**,
« workflow » → **cycle de travail**, « phase » → **étape/sprint**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-forensics` à l'utilisateur.

Le post-mortem **constate** — il ne répare pas. Les correctifs repartent en `vf-plan` /
`vf-execute`, le retour arrière en `vf-undo`.

Enchaînement typique : `vf-auto` (cycle qui casse) → `vf-forensics` (comprendre) → `vf-undo` ou
`vf-plan` (repartir proprement) → `vf-learn` (capitaliser).
