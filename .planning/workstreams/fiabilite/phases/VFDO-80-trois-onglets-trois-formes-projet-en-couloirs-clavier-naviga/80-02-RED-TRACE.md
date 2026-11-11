# 80-02 — trace du rouge (P80-D-25)

Base : `680364f1` (sans `00-vf-surcouches.js`). Suite : `bash plugin/cockpit/scripts/tests/test-cockpit-surcouches.sh`
(mesure brute : `SONDE=1`). Résultat sur la base : 6 PASS / 20 FAIL. Chaque rouge a sa cause lisible dans la mesure du pilote.

| Cas | Attendu | Obtenu sur la base | Cause |
|---|---|---|---|
| SU1.1 palette, Tab hors du champ, Échap | fermée, focus rendu à `#btn-export` | `ferme:false, retour:""` | rien n'écoute Échap quand la palette est ouverte hors du champ |
| SU1.3 garde d'unicité | `VF_SURCOUCHES` objet, même identité, 0 écouteur de plus | `api:"undefined", identite:false` | aucune pile |
| SU2.1 export, 15 Tab | 15 arrêts dans `#modal .box` | arrêts 5 à 15 hors de la boîte (`[true,true,true,true,false,…]`) | aucun piège à Tab |
| SU2.2 inert + focus | `true,true,true` puis rien | `pendant:"false,false,false"` | aucun inert posé |
| SU2.4 palette, 30 Tab | 30 arrêts dans `#palette .box` | un seul arrêt dans la boîte (le 21e) | aucun piège |
| SU3.1 panneau fermé | 0 focalisable visible | `ouvert:6, ferme:true, focalisables:6` | `visibility` reste `visible` |
| SU3.2 focus rendu | `#btn-panel` | `focus:""` | le focus reste dans le panneau qui se ferme |
| SU3.3 mouvement réduit | `hidden` | `ouvert` (visible) | pas de règle `visibility` |
| SU4.1 tiroir Git, Échap sur `body` | tiroir fermé, sélection gardée | `tiroirFerme:false` | seul l'Échap du moteur parle : il désélectionne |
| SU4.2 palette sur tiroir | palette fermée, tiroir resté | `palFerme:false` | idem SU1.1 |
| SU4.3 `dessus()` | tiroir, puis `#palette` | `false, false` | aucune API |
| SU4.4 Échap consommé (Code, Équipe) | palette fermée, témoin `defaultPrevented` vrai, vue non appelée | `ferme:false, temoin:[false], vue:1` | palette laissée ouverte, l'appui arrive à la vue |
| SU4.6 ordre des écouteurs | 1 écouteur de la pile avant les extensions | `pile:0, avantTout:false` | aucun écouteur de la pile |
| SU5.1 listes recopiées | aucun fichier | `02-vf-telephone.js, 73-vf-tiroir-travail.js, 77-vf-git-tiroir.js` | les trois listes existent |

Témoins verts sur la base, notés tels : SU1.2 (l'Échap du champ de recherche : comportement du moteur conservé), SU2.3 (l'inert d'un témoin n'est jamais levé : rien ne pose d'inert), SU4.5 et SU4.5b
(Échap arrive intact à la vue sans surcouche, Terminal compris : non-régression que M-ECHAP-VIDE doit faire rougir), A0.
Mutants : sans objet sur la base (le module n'existe pas) ; rejoués après la pile, voir le SUMMARY.

Reste à faire par la mission de jointure (non fait ici) : SU6.1 et M-PERSISTANT (coquille de la 79 : la suite imprime `⏳ ATTENTE`),
passage des mutants à `cockpit_module_copie`, idiome A51, baisse de `colonnes-baseline.txt` pour les lignes longues retirées.
