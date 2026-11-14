base: 3f6e95066f602d4c7d5239731adb0bdd99982924
# 74-08 — trace du rouge

Commande : `RETRAITS_SANS_FICHE=1 bash plugin/cockpit/scripts/tests/test-cockpit-equipe-retraits.sh` (serveur lancé depuis une copie du module privée de ses `ui/74-vf-fiche*.js`, la base de la 73 seule).

| Sonde | Sans la fiche | Raison |
|-------|---------------|--------|
| R2 (rendu en texte contre la fiche, T26.7 / T27.C1 / T27.C2) | FAIL | aucune fiche à lire, section interrompue |
| R4 (T26.8, T27.B2, T27.C1, T27.C2 contre la fiche) | FAIL | aucune fiche, section interrompue |
| R5 (ancre `#r=n:ag-<id>`) | FAIL | rien n'annule `vf-agent:ouvrir` : le lecteur de la 73 déplie la ligne, aucune fiche |
| R5b (nom clic / Entrée / Espace, rapport) | FAIL | aucune fiche, section interrompue |
| R1 (ni bouton, ni texte, ni boîte de 320 px) | PASS, garde verte dès le départ | la 73 (73-08) a retiré le panneau d'item ; le mutant M-BOUTON-REVENU la rougit |
| R3 (aucun « 101 » dans les surfaces de la 74) | PASS, garde verte dès le départ | mutant M-DUREE-VEILLES-REVENUE |
| R6 (aucun nœud `~termines`, agent terminé compté) | PASS, garde verte dès le départ | la 73 (73-08) a retiré la carte ; mutant M-CARTE-REVENUE |
| R7 (export `transcript` encore posé) | PASS, garde verte dès le départ | mutant M-EXPORT-PREMATURE |

Résultat sans la fiche : 7 PASS, 4 FAIL (R2, R4, R5, R5b). Avec la fiche : tout vert, cinq mutants rouges (`MUTANT-ROUGE`).

Constat noté, jamais un FAIL (fichier de la 73) : la régie affiche sa durée depuis `dureeS` (`72-vf-regie-modele.js`, ligne de `tenue`), donc la durée des veilles pour un agent terminé ; à la charge de la 73.
