---
name: gate-partial-read-warning-only
description: Un gate qui compte des lignes non lues sans effet sur son code rend vert sur lecture partielle ; verifier que le juge aval traite le compteur (check-prd.sh, Phase 59)
metadata:
  type: feedback
---

Un gate deterministe dont le compteur de lignes "non reconnues" n'a aucun effet sur le code de sortie rend 0 sur un fichier lu a 1/6 (`* [ ] **PRD-02**` ou `prd-05` ignores, exigences=1 non_reconnues=5, rc=0).

**Why:** Phase 59 (check-prd.sh, revue SOBR-04 2026-10-29) : l'en-tete assume "effet nul sur le code", mais prd-gate.md ne mentionne ni `non_reconnues` ni `AVERTISSEMENT ligne`, et le front door dit "conforme aux eliminatoires" sur code 0. Personne en aval ne consomme le compteur.

**How to apply:** sur tout gate "lecture seule + BILAN", sonder un fichier melange forme reconnue / forme voisine non reconnue, puis grep le consommateur (juge, front door) pour le nom du compteur. Meme revue : un livrable de mission dont le juge exige un fichier absent (brief seul -> `--requirements` absent -> rc 3) est une impasse structurelle, pas un cas limite. Voir [[feedback_strict-branch-fallback-audit]].
