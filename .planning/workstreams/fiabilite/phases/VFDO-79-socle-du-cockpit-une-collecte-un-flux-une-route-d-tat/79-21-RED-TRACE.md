AVANT f5c2e9eb2a0b68cf7fe2ae80dc22a843f28b1be3

# 79-21 — trace du rouge (coût borné de la correspondance de motifs, P79-D-32, SOCL-26)

Ni motif exact ni taille de famille ici : ils vivent dans le banc de la section GLOB de test-cockpit-confinement.sh (dépôt public).

## Tâche 1 — rouges constatés sur la base (AVANT ci-dessus), suite jouée en entier

Graine fixe de la suite : graine=79210101 (rejeu : VF_GLOB_GRAINE=79210101 VF_GLOB_N=4000 bash test-cockpit-confinement.sh). 66 PASS d'avant intacts (sections A à H), 74 PASS / 15 FAIL au total.

Verts voulus sur la base (témoins) : GLOB.E0 (complète : 13 classes, chacune au moins 150 motifs, 20 correspondances, 20 non-correspondances), E1, E2, E3a, E3c (équivalence de la copie gelée à la base : témoin d'oracle), P0, P3 (banc : linéaire laissé passer, quadratique vu, rapports 1,98 et 3,97), C4.

Rouges voulus, un par identifiant (assertion, attendu, obtenu) :
- GLOB.E3b — attendu : `identique` (le motif malformé à alternative de niveau supérieur ne correspond plus à rien) ; obtenu : exemple fixe `a[{/*.js,/` et chemin `zz/` : verdict attendu false, obtenu true.
- GLOB.P1.F1 — attendu `ok` (t(2N) <= 2,5 x t(N) + 1 ms) ; obtenu rouge t1=53,2 ms t2=416,7 ms rapport 7,83.
- GLOB.P1.F2 — obtenu rouge t1=60,4 ms t2=968,5 ms rapport 16,04.
- GLOB.P1.F3 — obtenu rouge t1=67,1 ms t2=1 029,0 ms rapport 15,33.
- GLOB.P1.F4 — obtenu rouge t1=70,6 ms t2=552,7 ms rapport 7,83.
- GLOB.P1.F5 — obtenu rouge t1=36,3 ms t2=468,6 ms rapport 12,90.
- GLOB.P2.F1 à F5 — attendu `ok` (t(2N) <= 250 ms) ; obtenu rouge t2 = 416,7 / 968,5 / 1 029,0 / 552,7 / 468,6 ms.
- GLOB.C0, C1, C3 — attendu `ok` ; obtenu : « échec : module de correspondance absent ou illisible (ERR_MODULE_NOT_FOUND) » (le module neuf n'existe pas sur la base).
- GLOB.C2 — attendu `ok / 1 ligne / court` ; obtenu : même échec d'import.

Rejeu à la main de la mesure de la Phase 75 sur la base (un appel par taille, processus fils à délai de 20 s, motif à trois `**` non adjacents, chemin répétitif de 20 000 puis 40 000 unités) : 830,1 ms puis 3 939,3 ms (la note de la Phase 75 relevait 855,0 puis 3 444,6 ms : même classe, quadratique).
