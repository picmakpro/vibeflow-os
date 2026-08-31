---
name: transcript-fige-ne-prouve-pas-worker-mort
description: Une trace de worker figée + un artefact manquant ne prouvent PAS qu'il est mort — dispatcher un remplaçant crée deux workers concurrents sur le même périmètre
metadata:
  type: feedback
---

Ne jamais conclure qu'un worker est mort à partir d'une **trace figée** et d'un **artefact
manquant**. Réveiller (`SendMessage` sur son agentId) est le seul geste sûr ; dispatcher un
mandat de complétion sur le même périmètre crée **deux workers concurrents** qui se marchent
dessus.

**Why:** le 2026-08-17, annexe Phase 33, la machine s'est mise en veille. Au réveil, la trace du
worker 33-06 était figée depuis plusieurs minutes et son `33-06-SUMMARY.md` était absent — j'en ai
conclu « tué en vol » et dispatché une complétion ciblée. Le worker était **vivant** : il a fini 20
minutes plus tard. Les deux ont alors muté `notify.sh` en parallèle pour leurs preuves de mutation,
et chacun a rapporté comme **anomalie inexplicable** le travail de l'autre (« fichier muté hors de
mes actions », « commit apparu que je n'ai pas produit », soupçon de hook local fantôme). Deux
rapports `ask-user` ont été brûlés à enquêter sur un fantôme qui était mon propre dispatch.
L'issue a été bénigne (commits empilés proprement, état final vert) mais c'était de la chance :
deux `git checkout --` concurrents sur le même fichier pouvaient détruire une preuve en cours.

**How to apply:** avant tout mandat de complétion/remplacement, exiger **une preuve positive de
mort**, jamais une absence. Une trace qui ne grossit plus peut être un `sleep`, un long appel
d'outil, ou une veille machine — l'agent reprend là où il en était. Ordre correct :
(1) `SendMessage` sur son agentId pour un point de situation ; (2) attendre sa réponse ;
(3) seulement s'il ne répond pas, redispatcher — et alors **nommer explicitement dans le mandat
qu'un travail concurrent a pu exister**, pour que le nouveau worker n'interprète pas les traces de
l'ancien comme une anomalie système. Corollaire pour les mandats : quand je crois être seul, écrire
« un seul agent travaille sur ce dépôt : toi » — et ne l'écrire que si je l'ai vérifié.
Voir [[relire-le-disque-avant-tout-rapport]] : le disque fait foi pour ce qui *a été écrit*, jamais
pour savoir *qui écrit encore*.
