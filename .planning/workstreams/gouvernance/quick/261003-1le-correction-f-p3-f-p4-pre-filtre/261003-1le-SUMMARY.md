---
quick_id: 261003-1le
workstream: gouvernance
phase: 45
type: quick
status: complete
commits: [ea887d27]
---

# Quick 261003-1le — SUMMARY

Code : `ea887d27` (hooks.json, check-gates-alive.sh, test-planning-prefilter.sh, modele-cycles.md, HOOKS-CONTRAT-SORTIE.md, CHANGELOG v2.9.0).

## Fait

- **F-P3** : config de plus de 64 Kio (`find -L … -size +128`) : DEFER avant toute lecture ; budget de 64 lectures de config par exécution.
- **F-P4** : `_pa=; _pb=0;` initialisés en tête de `vf_pre`.
- **PF-CREUX-01** rouge sur le code d'avant (TIMEOUT à 5 s sur la config creuse de 2 Gio ; SHORT au lieu de DEFER sur 1 Mio et 65 537 octets),
  vert après. Six mutants V-* tués structurellement (nombre de lectures compté dans une copie instrumentée, ou verdict), jamais par l'horloge seule.
- Les 17 mutants d'avant restent tués. Suites vertes : prefilter (table, bornes, corpus, 23 mutants), hook-registered 90, gates 461, hook-installed 23 ;
  check-machine-paths et check-version-sync verts ; contrôle de marqueur sans-marqueur=0.

## Mesure (40 rejeux entrelacés, /bin/sh, ce dépôt, médiane / p90)

Write 43,4 / 45,8 → 15,1 / 16,1 ms ; Bash 43,2 / 45,8 → 14,8 / 15,8 ; Agent 43,2 / 48,5 → 14,8 / 16,5. Le tour 1 : 12,1, 11,5, 11,5 ms : le `find`
par config coûte 3 ms (deux configs sur la chaîne).

## Constats hors périmètre

- Le CŒUR (`planning-hook.sh`) lit une config de 2 Gio en 1,5 à 2,5 s (avant comme après) et répond « laisse passer » (stdout vide) sur la
  config creuse de zéros : ce n'est pas un refus. Coût identique à l'ancienne chaîne, hors de `vf_pre`.
- Le mandat citait des arbres de 60 niveaux : sous la borne de 64 composants par valeur, la suite utilise 32 niveaux (33 pour la limite).
