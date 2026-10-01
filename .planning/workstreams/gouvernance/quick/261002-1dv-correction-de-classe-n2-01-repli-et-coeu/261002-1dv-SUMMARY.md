---
quick_id: 261002-1dv
status: complete
date: 2026-10-02
commits: [19d9c32d]
---

# Quick 261002-1dv — Summary

Classe N2-01 fermée : une valeur de plus de 4096 caractères n'est plus jamais tranchée sur le cwd dans le repli si elle nomme
`.planning`/`.claude` ou porte un antislash ; le cœur la juge d'emblée par la décision dans le doute (pas de realpath ni racine_lab).

- Fichiers : hooks.json, check-gates-alive.sh (copie identique), planning-hook.sh, test-planning-hook-registered.sh (R-DOUTE-01..04,
  trois mutants), test-planning-gates.sh (mots-clés R-REFERENCE), modele-cycles.md (limites aa, ab ; N2-02..04), CHANGELOG v2.9.0.
- Preuve générative : 2 000 valeurs, graine 20261002 : deny complet 2000/2000, deny repli 2000/2000, témoins PASS 500/500, t_max 0,45 s.
  Avant correction (300 valeurs) : 7/300 et 138/300. Sonde N=130000 : deny, 0,19 s (avant : 8,17 s).
- Suites : registered 74/0, gates 457/0, rejeu-gates 91/0, installed 23/0, role-hook 6/0, recalc 358/0 ; check-machine-paths vert.
- Rejeu réel : 0 faux refus, 0 faux accept, 202 refus conformes, empreintes identiques ; repos 0/0.
