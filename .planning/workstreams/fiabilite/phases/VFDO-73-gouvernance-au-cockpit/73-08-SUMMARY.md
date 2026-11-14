# 73-08 — retrait du canevas d'Équipe, côté serveur et côté page (REGI-03, REGI-14, REGI-16)

Trace du rouge : `73-08-RED-TRACE.md` (table des re-pointages : identifiant, ancien support, nouveau support). Base : 852e638e.

## Livré

- `vf-cockpit-equipe-carte.mjs` (41 lignes) : `buildEquipeGraph` rend l'enveloppe `cockpit-equipe@1` sans carte (`nodes` vide, meta conservée) ; `missionsEnCours` et la classe d'affichage (parité R4.1) gardées ; plus d'option `lancees`.
- `vf-cockpit-graphe.mjs` : l'enveloppe d'Équipe est construite une fois par génération du gabarit (ni `who` ni lancements dans le mémo) ; la garde d'émission `gardeWho` suit chaque `who`. Signature et ETag de la route stables.
- `vf-cockpit-server.mjs` : `startLive(..., { lancees: () => lancer.lancees() })` ; `majGraphes` ne passe plus les lancements aux graphes. 255 lignes (inchangé, F.1 de `test-cockpit-routes.sh` reste le rouge connu).
- `ui/72-vf-equipe.js` : réduit au libellé de la recherche (aucun rechargement, aucun rendu du moteur, aucun stockage, aucun panneau d'item). `vf-cockpit-interface.json` : description « coquille sans cartes depuis la Phase 73 ».
- `ui/72-vf-regie-source.js` : une ligne (UIFN-12) : le focus passe au titre du lecteur de repli ; sans elle le focus tombait sur `body` quand « Lire le rapport » quittait la ligne (révélé par EK1 re-pointé).
- Tests : `regie-rg-retrait.sh` (RG3.1 à RG3.7, M-GARDE-MEMO, RG14.3, RG14.30) ; `test-cockpit-equipe.sh`, `chrome-equipe-clavier.mjs` (299 lignes), `chrome-parcours-tab.mjs`, `chrome-moteur-carte.mjs`, `test-cockpit-moteur-carte.sh`, `test-cockpit-lancer-serveur.sh` (L3 re-pointé, L3b neuf) re-pointés sur la régie. `colonnes-baseline.txt` abaissée (deux entrées périmées).

## Écarts

- Écart : `pageEquipe` n'existe plus (coquille 79) : le mémo et la garde vivent dans `vf-cockpit-graphe.mjs` (hors de la liste de fichiers du plan) ; RG3.1 est joué sur `creerGraphes` (l'objet que sert la route), le serveur réel étant couvert par E23.3 à E23.5.
- Écart : `meta.vf.compte` et `sources` sont ceux de la première construction (comme prévu par le plan) ; rien de visible ne les lit.
- Écart : RG3.4 ne rejoue pas « V6.1 » (absent de `test-cockpit-vendor.sh`) : grep de traces de la régie dans `viewer.html` et `20-health.js`.
- Écart : un seul mutant neuf (M-GARDE-MEMO), régime allégé ; les mutants M-ENVELOPPE-CARTES, M-MEMO-WHO, M-RECHARGEMENT, M-LANCEES-PAGE du plan ne sont pas écrits (RG3.1, RG3.5, RG3.3 et L3b portent la propriété).
- Écart : L3b est joué sur `startLive` avec la même expression que le serveur (L3 prouve la ligne de câblage).
- Écart : EA1.5 et EA1.6 (descriptions des cartes), absents de l'inventaire du plan, re-pointés sur le modèle de la régie ; `chrome-parcours-tab.mjs` (arrêt « titre » dans `#vf-equipe-entete`) touché, il ne sert que `chrome-equipe-clavier.mjs`.
- Écart : EK18.2 re-pointé sur un mutant « lien dans l'en-tête de la régie » (la propriété du tabindex rendu à la fermeture de Git n'existe plus).

## Suites jouées (une fois sur la tête de travail, Chrome présent)

- `test-cockpit-regie.sh RG13 RG6 RG3 RG14 RG11` : 97 PASS / 1 FAIL (RG13.13, route « ailleurs » du plan 73-02 : le journal du faux git gagne une ligne, rouge aussi à la première passe complète, non causé par ce plan : aucun fichier de la route touché) ; passe complète précédente 261 PASS / 2 FAIL (RG13.13, RG6.20 vert au rejeu).
- `test-cockpit-moteur-carte.sh` : 73 PASS / 0 FAIL (K13.1 à K13.3 verts).
- `test-cockpit-lancer-serveur.sh` : 83 PASS / 0 FAIL (L3, L3b).
- `test-cockpit-equipe.sh` : 218 PASS / 0 FAIL.
- `test-cockpit-vendor.sh`, jouée seule : 252 PASS / 0 FAIL.
- `check-file-size`, `check-machine-paths`, `colonnes-cliquet verifier` : OK.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
