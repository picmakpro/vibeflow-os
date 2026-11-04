# 68-FIX — index des passes de correction

Chaque passe est une correction ciblée (un finding, un témoin rouge, un commit, un vert), sans nouveau cycle complet. Les SUMMARY n'existent que pour les premières passes ; les autres sont lues dans leur trace.

| Passe | Objet | Trace | SUMMARY |
|-------|-------|-------|---------|
| socle | findings F-04 à F-08 du socle cockpit (échéance globale, lab plat, contrat de `mission.vie`) | `68-FIX-SOCLE-RED-TRACE.md` | `68-FIX-SOCLE-SUMMARY.md` |
| mod | ST-1, ST-3 à ST-7 du mod vf-signal | `68-FIX-MOD-RED-TRACE.md` | `68-FIX-MOD-SUMMARY.md` |
| q3 | P68-D-33 : cascade de vie prolongée au dépôt ; R13 `tsconfig` ignoré | `68-FIX-Q3-RED-TRACE.md` | `68-FIX-Q3-SUMMARY.md` |
| web | R5, R7, R12 de l'UI web (pastille « Abandonnée », portée « dépôt ») | `68-FIX-WEB-RED-TRACE.md` | `68-FIX-WEB-SUMMARY.md` |
| ma | lot A du mod : rien sous le lab (P68-D-34, P68-D-35) | `68-FIX-MA-RED-TRACE.md` | `68-FIX-MA-SUMMARY.md` |
| mb | lot B du mod : R1, R4, R6, R9, R10, R11 | `68-FIX-MB-RED-TRACE.md` | `68-FIX-MB-SUMMARY.md` |
| rv-mod | revue fraîche et recette v1/v2 côté mod : Q4, R2, R3, R11, N1, N2, N3, N8 (P68-D-37, P68-D-38) | `68-FIX-RV-MOD-RED-TRACE.md` | — |
| rv-web | revue fraîche côté web : R11 et N2 (P68-D-33 à P68-D-38) | `68-FIX-RV-WEB-RED-TRACE.md` | — |
| sc2 | seconde passe du socle : tags de lecture d'un arbre, H-1 | `68-FIX-SC2-RED-TRACE.md` | — |
| fin-mod | dernière passe du mod : rafraîchissement si pane ouverte, variable vidée, bidi, N2 de la vue Équipe, brief `seven_day` (P68-D-40, P68-D-41) ; commit `9aed38ea` | `68-FIX-FIN-RED-TRACE.md` | — |
| fin-web | dernière passe web et doc : âge du verrou par correspondance exacte, README et notes (M-3 à M-6, AD-1, AD-2) ; commit `b2fa4a90` | `68-FIX-FIN-WEB-RED-TRACE.md` | — |
