# 74-08 — résumé

rituel levé : régie allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Plan non marqué audit : pas de mutants au-delà des cinq que le plan demande (joués).

## Livré
- `test-cockpit-equipe-retraits.sh` (suite neuve) : R1 (aucun `[data-vf-transcript]`, aucun « Lire le transcript », aucune boîte de 320 px, régie montée en témoin positif), R2 (rendu en texte contre la fiche : 0 img, 0 attribut `on*`, source lisible, aucun script exécuté), R3 (aucun « 101 » dans fiche, coût, frise ; « Au travail » = 2 h 14), R4 (T26.8, T27.B2, T27.C1, T27.C2 contre la fiche), R5 (ancre, annulée puis ouverte par la fiche, sans défilement ni dépli), R5b (nom au clic, à Entrée, à Espace, « Lire le rapport » : `defaultPrevented`, fiche ouverte, repli non ouvert, `vf-agent:lu`, focus rendu), R6 (aucun nœud `~termines`, l'agent terminé est compté), R7 (l'export `transcript` vit encore). Cinq mutants, tous `MUTANT-ROUGE`. Mode `RETRAITS_SANS_FICHE=1` : rouge établi (`74-08-RED-TRACE.md`).
- `test-cockpit-equipe.sh` : `EKC_REPLI` joue EK1, EK1.1, EK2.1, EK3.1, EKR2 sur une copie du module sans `ui/74-vf-fiche*.js` ; les mutants `ek_muter` (EK1.2, EK1.3, EK2.2, EK3.2) et EK6 aussi.
- `test-cockpit-transcript.sh` : T26.7, T26.8, T27.B2, T27.C1, T27.C2 sur une copie sans fiche (serveur relancé avant et après).
- `chrome-equipe-clavier.mjs` : inchangé (aucune de ses sondes ne rougissait sur la page complète).

## Sort des témoins
Conservés (page complète) : EK0, EK1.0, EK5, EK10, EK13 à EK17, EK18.x, T26.1 à T26.6, T27.A, T27.B1, T27.F1 à F3. Rejoués sans fiche (repli vivant jusqu'à 74-10) : EK1, EK1.1, EK2.1, EK3.1, EKR2, EK1.2, EK1.3, EK2.2, EK3.2, EK6, T26.7, T26.8, T27.B2, T27.C1, T27.C2. Réécrits contre la fiche : R2 (T26.7), R4 (T26.8, T27.B2, T27.C1, T27.C2), R5b (EK1 : focus rendu à l'ouvreur). Aucun assert supprimé ni affaibli (les deux suites ne gagnent que des lignes).

## Constat des cinq points de la 73 et de la 79
1. Déclencheurs : `nom`, `ancre`, `rapport` émis par `72-vf-regie-source.js` ; ligne `li[data-vf-agent]`, nom `.vf-rg-tog`, bouton `.vf-rg-act button`.
2. 73-08 a retiré le panneau d'item (aucun `[data-vf-transcript]` dans le DOM) et la carte du canevas (`nodes` vide). **Subsistent, non retirées ici (code d'interface, hors périmètre du mandat)** : dans `70-vf-live.js`, les règles mortes `.sec button[data-vf-transcript]` (lignes 32-33), `.vf-transcript` avec `max-height: 320px` (lignes 44-47) et la constante `BTN` qui cite `[data-vf-transcript]` (ligne 156). R1 n'en garde que l'absence dans la page.
3. 73-10 : plus de pli `vf-termines` dans le tiroir (lien « N à relire dans Équipe »).
4. Les identifiants EK, T26, T27 sont inchangés.
5. La régie lit `dureeS` pour sa durée (`72-vf-regie-modele.js`, calcul de `tenue`) : constat pour la 73, aucune modification ici.
Phase 79 : `cockpit_module_copie`, `cockpit_module_muter`, `cockpit_lancer` utilisés tels quels.

## Écarts
- Précondition P74-D-56 (Phase 79 entière) non jouée, remplacée par les prérequis réels (consigne du mandat).
- Fusion (A) : 3159c6bb au lieu de 313a7f0f (le correctif de colonnes de la 73 y est) ; conflits README du module, `colonnes-baseline.txt`, import du serveur.
- R5 ne peut pas espionner `window.__vfFiche.ouvrir` : le gestionnaire de `vf-agent:ouvrir` appelle la fonction interne, pas l'objet gelé. R5 prouve l'effet (annulation, une seule fiche, titre, ni défilement ni dépli).
- R1 : l'assert sur les feuilles de `70-vf-live.js` (règles `.vf-transcript`) n'est pas posé, il rougirait sur du code non retiré par la 73 ; voir constat 2.
- R3.1 sans fiche : sonde « sans objet » (la fiche est absente).
- L'ancre au chargement (`equipe.html#r=n:ag-ximg`) : T26.8 reste rouge, défaut connu de la 73 (`__vfRegie.arriver` rend faux avant le montage), corrigé par 73-11. Rouge attendu jusqu'à 73-11.

## Suites jouées (une fois sur la tête commitée)
| Suite | Verdict | Secondes |
|-------|---------|----------|
| test-cockpit-equipe-retraits.sh | 25 PASS / 0 FAIL, 5 mutants rouges | 46 |
| test-cockpit-equipe.sh | 217 PASS / 1 FAIL (EK18, rouge dès la base fusionnée, avant mes changements) | 325 |
| test-cockpit-transcript.sh | 124 PASS / 1 FAIL (T26.8, attendu jusqu'à 73-11) ; T24F4.1 vert cette fois | 61 |
| test-cockpit-accessibilite.sh | 39 PASS / 0 FAIL | 34 |
| test-cockpit-chrome-fr.sh | 141 PASS / 0 FAIL | 42 |
| test-cockpit-vendor.sh (après fusion) | 253 PASS / 0 FAIL | 308 |
Rouges de base non touchés : EK18 (titre de la régie arrêt de Tab sur la page complète, présent avant ce plan).
