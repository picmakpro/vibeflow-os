---
quick_id: 261002-3rx
status: complete
date: 2026-10-02
commits: [1d9425f7]
---

# Quick 261002-3rx — Summary

N3-01 (régression de l'aiguillage de N2-01) et N3-02 fermés dans le coeur de planning-core.

Choix (décision du manager vf-dev-manager, renversable, documentée) : le coeur lit une valeur de plus de 4096 caractères sous DEUX
formes obtenues en temps linéaire, la forme réduite lexicalement (`posixpath.normpath`) et la forme physique (`resoudre_lineaire`,
égale à `realpath` sur 20 000 chemins tirés au hasard). Chacune qui tient sous la borne est analysée comme une valeur courte, la valeur
est refusée dès que l'une des deux l'est. La forme réduite seule laissait passer `cyc/..` (7 régressions mesurées contre 24b58748) :
d'où la seconde forme. Seule une valeur qui reste trop longue part dans la décision dans le doute (nom, puis lab du cwd lu réduit et
ancêtre existant de ses formes). N3-02 : un chemin relatif sous un cwd de plus de 4096 caractères passe par le doute ; le cwd long est
réduit au lieu d'être remplacé par celui du processus.

- Fichiers : planning-hook.sh ; test-planning-hook-registered.sh (R-REDUC-01, R-DOUTE-02 et R-DOUTE-03 reformulés, sept mutants) ;
  test-planning-gates.sh (R-REFERENCE : mots-clés de (aa), limites (af) à (ak)) ; modele-cycles.md ; CHANGELOG v2.9.0.
  hooks.json et check-gates-alive.sh inchangés (couche de repli plus stricte, écart déclaré).
- Différentiel à trois versions (24b58748, 079e905f, nouveau) : aucun cas refusé par l'une des deux versions précédentes ne passe, hors
  faux refus de 079e905f levés et nommés. Sonde N=130000 : deny en 0,09 s.
- Suites : registered 82/0, gates 457/0, rejeu-gates 91/0, installed 23/0, role-hook 6/0, recalc 358/0 ; check-machine-paths vert ;
  contrôle de marqueur sans-marqueur=0.
- Zéro régression dev : 60 rejeux (six outils, cinq chemins, script présent puis absent) : rc 0, 0 octet.
- Rejeu réel : 0 faux refus, 0 faux accept, 202 refus conformes, empreintes identiques ; repos 0/0 avant et après ;
  section « Rejeu post-re-audit 3 » dans 45-REJEU-FINAL.md.
