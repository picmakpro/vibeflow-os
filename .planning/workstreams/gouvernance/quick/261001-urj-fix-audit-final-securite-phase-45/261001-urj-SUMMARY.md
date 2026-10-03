---
quick_id: 261001-urj
status: complete
date: 2026-10-01
commits:
  - 0f8f2946
---

# Quick 261001-urj — résumé

| Finding | Correction | Rouge avant | Mutants tués |
|---|---|---|---|
| F-01 | valeur de plus de 4096 caractères non parcourue par le repli, décision sur le cwd | R-BORNE-01 : libellé générique au lieu de « trop long » | BORNE-RETIREE, BORNE-LAB-DEV, BORNE-LIBELLE, BORNE-CWD-REL, BORNE-CWD-AGENT |
| F-02 | G6 exige aussi le motif du repli, constante partagée comparée à `hooks.json` | mutant ADH-REPLI-CONJONCTION (comportement d'avant) : admis par G6 mais non reconnu par le repli | ADH-REPLI-CONJONCTION, ADH-REPLI-ESPACES, ADH-REPLI-MOTIF |
| F-03 | échéance désarmée à l'émission et à la sortie | R-DEFS-06 : rc=73 et refus générique | ECHEANCE-FIGEE-EMISSION, ECHEANCE-FIGEE-SORTIE, ECHEANCE-FIGE-GARDE |
| F-04 à F-08 | limites (aa) à (ae), (z) réécrite, T-45-61, `--tentative`, CHANGELOG | — | REFERENCE-LIMITE-AE-MOTCLE, REFERENCE-LIMITE-AA-MOTCLE, REFERENCE-LIMITES (31 limites) |

Suites au premier plan : test-planning-gates 456 OK, test-planning-hook-registered 56 OK, test-rejeu-gates 91 OK, test-planning-hook-installed 23 OK, test-role-hook-vs-check-agents 6 OK, test-recalc-planning 358 OK, check-machine-paths vert, contrôle de marqueur sans-marqueur=0.

Rejeu réel post-audit (lecture seule) : 0 faux refus, 0 faux accept, empreintes identiques ; section « Rejeu post-audit » de `45-REJEU-FINAL.md`.
