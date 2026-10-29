---
name: feedback-silencing-output-breaks-sibling-witness-suite
description: Rendre silencieux un chemin (P61-D-04) casse la suite soeur qui prenait cette sortie pour temoin « le hook a joue » ; rejouer TOUTES les suites qui citent le script, pas seulement la sienne (Phase 61, tour 2)
metadata:
  type: feedback
---

Quand un correctif supprime une sortie (silence sur 0/3 du hook de divergence), les suites SOEURS qui utilisaient cette sortie comme temoin de declenchement tombent : `test-divergence-deux-clones.sh` (D2C-CONFORME l.404, D2C-TEMOIN-CD-MUTE l.544) passait 16/16 au tour 1 et 14/16 au tour 2, alors que le commit du tour 2 ne touchait que la suite du script. La CI les decouvre par `find plugin scripts -path '*/tests/test-*.sh'`.

**Why:** le correcteur a rejoue sa suite (84 ok) et celle de l'installeur (29 ok) mais pas la suite a deux clones ; le temoin « le hook a joue » disparait aussi des chemins silencieux (detecteur mute = silence = indistinguable d'un hook jamais declenche).

**How to apply:** `git grep -l <script>` sur tests/, rejouer chaque suite citee, et exiger un nouveau temoin de declenchement quand la sortie qui en servait disparait. Voir aussi [[feedback_mutant-sibling-dependency-masks-vacuity]].
