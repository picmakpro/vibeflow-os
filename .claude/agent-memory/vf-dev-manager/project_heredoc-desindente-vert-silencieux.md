---
name: heredoc-desindente-vert-silencieux
description: Rejouer un bloc `run: |` de ci.yml sans dé-indenter casse le heredoc — bash avale le reste du script, n'exécute rien et sort en exit 0 SANS sortie : un vert parfaitement crédible
metadata:
  type: project
---

Pour rejouer les gates de `.github/workflows/ci.yml` hors CI, les blocs `run: |` doivent être
**dé-indentés** (10 espaces d'indentation YAML) avant exécution. Sinon le heredoc du bloc à fixture
(`<<'STATEEOF'`) n'est jamais terminé : bash consomme tout le reste du script comme contenu du
heredoc, n'exécute AUCUNE commande, et **sort en exit 0 avec zéro ligne de sortie** — sans le
moindre avertissement sur le bash de ce poste.

**Why:** mesuré le 2026-09-15 (Phase 34, revue finale). Le juge a fait l'erreur, l'a détectée et l'a
signalée de lui-même. Le symptôme est le pire possible : `exit 0`, aucune sortie. À la relecture d'un
rapport, ça ressemble trait pour trait à un gate qui passe sans rien à dire — et c'est exactement la
forme d'un gate qui n'a jamais tourné. C'est la famille [[preuve-incapable-de-rendre-rouge]] appliquée
non pas à la sonde, mais à la **procédure de rejeu** de la sonde.

**How to apply:**
1. Dé-indenter avant d'exécuter, et exiger du rapport le **nombre de lignes de sortie** en plus du
   code de retour. Un gate à fixture qui rend `exit 0` **et** zéro ligne n'a pas tourné : les gates de
   ce dépôt impriment tous une ligne de verdict (`✓ N fichier(s) balayé(s)`, « N verdicts », …).
2. Corollaire général, au-delà du heredoc : sur ce dépôt, **`exit 0` + sortie vide = artefact**
   jusqu'à preuve du contraire, comme [[timeout-absent-faux-zero]] pour les `0/N`.
3. Capturer le code de retour **hors pipe** : `cmd > f 2>&1; echo $?` — un `| head` rend le code de
   `head`, piège dans lequel je suis tombé au démarrage de cette même mission sur
   `check-mission-invariants.sh` (lu 0 au lieu de 3).

Voir [[liste-de-gates-jamais-la-reference]] (rejouer le job `gates`, jamais une liste recopiée) et
[[grep-proxifie-tronque]].
