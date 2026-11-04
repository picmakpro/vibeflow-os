---
phase: 69-suivi-travail-en-cours-cockpit
plan: 04
status: complete
requirements: [CKPT-19, CKPT-20, CKPT-21, CKPT-22, CKPT-23, CKPT-24, CKPT-25, CKPT-26]
commits: [3b364ad1, 443277bb, d0e294b3]
estimate:
  tokens: 115000
  raw_tokens: 115000
  tasks: 3
  confidence: low
---

# 69-04 — Témoins rouges du transcript et de la vue Équipe

Suites écrites et jouées rouges avant tout code : `test-cockpit-transcript.sh` (créée : T0, T24, T25 avec les mutants M-JETON et M-PORTE, T26)
et `test-cockpit-equipe.sh` (sections E23 et EUI ajoutées, aucune ligne retirée). Trace : `69-04-RED-TRACE.md`.

Commits : `3b364ad1` (équipe, E23 et EUI), `443277bb` (transcript), `d0e294b3` (trace). Aucun fichier de code touché.

État à la sortie : transcript 25 PASS / 35 FAIL ; E23 et EUI 4 PASS / 14 FAIL. Chaque rouge échoue parce que la règle visée manque (module, route,
page, couche d'affichage inexistants), à côté d'un contrôle positif vert sur la même fixture. T26.7 (Chrome) est jouée, non sautée.

Points à connaître pour 69-05 à 69-08 : voir la fin de la trace (surfaces fixées, en-tête de jeton `x-vf-cockpit-token` sur la sortie assemblée,
mutation de garde qui vise une constante `porte*` sur une ligne, sonde de libellés comparée au passif de v2.75.0).
