base: 74683850a006d6e5926230626c5bc6e27ebc2c73

# 73-10 — trace du rouge (régime allégé)

Commandes, sur la tête de départ (tiroir encore ouvert sur Équipe, pli des terminés en place) :
`bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG11_tiroir`, `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh`, `bash plugin/cockpit/scripts/tests/test-cockpit-transcript.sh`.
Chrome présent : la preuve navigateur (RG11.22) est jouée.

## Rouges (chacun avec sa ligne `❌ FAIL — <id> —`)

| id | obtenu | motif |
|----|--------|-------|
| RG11.20a | `1\|BODY\|-` | forme A (page Équipe chargée comme page) : le bouton ouvre le tiroir, le focus ne bouge pas |
| RG11.20b | `1\|1\|BODY\|-\|1` | forme B (coquille, Code puis Équipe par `surOnglet`) : idem |
| RG11.21 (×3) | `aucun lien\|pli` | le pli `details.vf-termines` est là, aucun lien « N à relire dans Équipe » |
| RG11.22 | délai dépassé | le lien n'existe pas, Équipe n'est jamais ouverte depuis le tiroir |
| RG11.23 | `0\|0\|ok` | la ligne du bouton ne porte pas la garde ni l'événement |
| M-TIROIR-EQUIPE, M-GARDE-ONGLET-FIGE | ancre absente | la garde n'existe pas encore (les mutants rougissent à leur ancre) |
| EUI.3 | `-\|1\|` | le terminé est dans un pli, aucun lien |
| EUI2.20 | `lien des terminés (P73-D-14)` | le libellé du lien n'existe pas |
| T27.A | `C1 hors du tiroir=false \| lien=lien absent \| plis=1` | le terminé est encore dans le pli du tiroir |

Verts dès la base (témoin positif de la forme A sur Projet et Code : le tiroir s'ouvre comme avant).

## Re-pointages (P73-D-04) : ancien support, rouge observé, nouveau support

Rouge observé : les assertions d'origine rejouées sur la tête de départ, avant tout re-pointage (7 rouges sur la suite de transcript, dont T26.7 et T27.F3, hors de la liste du plan mais de la même famille).

| id | ancien support | rouge sur la tête de départ | nouveau support (même propriété) |
|----|----------------|-----------------------------|----------------------------------|
| T26.7 | carte de l'agent, bouton « Lire le transcript » | `bouton Lire le transcript absent` | « Lire le rapport » depuis « Terminé, à relire » : transcript en texte (0 `img`, source lisible) |
| T26.8 | `state.selected` du moteur après `#r=n:ag-ximg` | idem | focus donné à la ligne de régie de l'agent (`au-travail:ximg`) |
| T27.B2 | sélection de la carte sans rechargement | `cible inconnue du viewer` | focus sur la ligne de régie par un lien de la même page, sans rechargement |
| T27.C1 | transcript et dernière commande demandés depuis la carte | `panneau absent` | rapport ouvert depuis « Terminé, à relire » reste affiché après quatre `who` ; rien du transcript en stockage |
| T27.C2 | transcript redemandé après rechargement | `panneau absent ;; panneau absent` | rien d'affiché après rechargement, rapport redemandé à la lecture |
| T27.F1 | badge égal aux actifs de `.vf-stats` | `badge=badge=6 actifs=` | badge égal aux lignes `au-travail` actives de la régie |
| T27.F3 | résultats de recherche du moteur (`#results .r`) | `trouves=false` | lignes de régie visibles après filtre de `#search` |
| T27.A | pli des terminés du tiroir, ouvert et gardé ouvert | (vert sur le support d'origine) | terminé hors du tiroir, compté par le lien « N à relire dans Équipe », aucun pli |
| EUI.3 | `details.vf-termines` fermé | (vert) | agent absent du tiroir, lien « 1 à relire dans Équipe » vers `equipe.html#vf-a-relire` |
| EUI2.20 | bloc « Terminés depuis moins de 24 h (1) » | (vert) | lien « 1 à relire dans Équipe » |

Après re-pointage (avant le code), T26.7, T26.8, T27.B2, T27.C1, T27.C2, T27.F1 et T27.F3 sont verts : la régie et le plan 73-08 sont en place. Un premier jet de la sonde « rien gardé » de T27.C2 était trop large (le panneau d'ensemble porte un titre `.pt`) : elle lit maintenant les intertitres du lecteur (« Mandat », « Fil des échanges »).
