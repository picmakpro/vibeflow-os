# 80-20 — RED-TRACE (témoins rouges sur la base fusionnée)

Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant.
Base : tête 64fad93da de la branche, sans aucun changement de ce plan.

## Tâche 1 — la zone du titre (suite test-cockpit-entete.sh, EN1)

Rouges attendus : EN1.1, EN1.5, EN1.6. Témoins d'invariance verts sur la base : EN1.2, EN1.2b, EN1.3, EN1.4 (relevés AVANT recopiés dans la suite).

```
  ✅ PASS — EN0 — serveur du lab démarré (avec --terminal)
  ❌ FAIL — EN1.1 (code1440) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,24,32]]
  ❌ FAIL — EN1.1 (code800) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,24,32]]
  ❌ FAIL — EN1.1 (code390) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,24,24,32]]
  ❌ FAIL — EN1.1 (graphe1440) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,16,32]]
  ✅ PASS — EN1.2 — hauteur de la zone ≤ 130 px, le texte du titre et le flou (halo de #context::before) sont gardés
  ✅ PASS — EN1.2b — freeArea() et la transformation après « f » (Code à 1440, 800, 390 px, graphe de Projet) égales à la base fusionnée : la mise en page ne change pas
  ✅ PASS — EN1.3 — couloirs et liste : #svg sans découpe
  ✅ PASS — EN1.4 — zone basse (lab --terminal, feuille ouverte) à 390 et 800 px : rectangles de #ask, #zoom, de la pastille « Terminal », de la feuille et --vf-bas (au pa
  ❌ FAIL — EN1.5 — Code → Projet → Code par VF_ONGLETS.aller (même document : timeOrigin) : Projet sans découpe, Code de nouveau sans carte sous le titre, découpe reposée
     attendu: [[true,"none",0,32,true]]
     obtenu:  [[true,"none",32,32,false]]
  ❌ FAIL — EN1.6 — A51 (P80-D-59) : après Code → Projet → Code (deux fois), un seul ResizeObserver et un seul écouteur resize de 01-vf-ensemble.js, comme à froid ; 01-vf-
     attendu: [[true,true,true,true]]
     obtenu:  [[false,false,true,true]]
  ✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
  Résultats : 6 PASS / 6 FAIL
```

## Tâches 2 et 3 — rejeu sur la base fusionnée (copie de la tête 64fad93da du module, avec les seuls fichiers de test de ce plan)

Même mécanisme que EN_SCRIPTS / FI_SCRIPTS : les suites neuves tournent contre le module de la base. Rouges attendus : EN2.1, EN2.2b (l'ouvreur à 36 px), EN2.2c,
EN2.3, EN2.4, EN2.4b, EN3.1, FI2.3 et H4.1 (1 000, 1 100, 1 279 px). Témoins d'invariance verts sur la base : EN2.2 (ordre DOM sous 1 280 px), EN2.5 (Santé,
menu des parcours), EN3.2 (appui de 44 déjà tenu), EN3.4.

### test-cockpit-entete.sh sur la base (EN1 à EN3, rejeu seul)
```
  ✅ PASS — EN0 — serveur du lab démarré (avec --terminal)
  ❌ FAIL — EN1.1 (code1440) — après un glisser puis « + » : aucune .card ni g.node sous les 8 × 4 points de #context
  ❌ FAIL — EN1.1 (code800) — après un glisser puis « + » : aucune .card ni g.node sous les 8 × 4 points de #context
  ❌ FAIL — EN1.1 (code390) — après un glisser puis « + » : aucune .card ni g.node sous les 8 × 4 points de #context
  ❌ FAIL — EN1.1 (graphe1440) — après un glisser puis « + » : aucune .card ni g.node sous les 8 × 4 points de #context
  ✅ PASS — EN1.2 — hauteur de la zone ≤ 130 px, le texte du titre et le flou (halo de #context::before) sont gardés
  ✅ PASS — EN1.2b — freeArea() et la transformation après « f » égales à la base fusionnée (mise en page inchangée)
  ✅ PASS — EN1.3 — couloirs et liste : #svg sans découpe
  ✅ PASS — EN1.4 — zone basse à 390 et 800 px (lab --terminal, feuille ouverte) : rectangles et --vf-bas égaux à la base fusionnée
  ❌ FAIL — EN1.5 — Code → Projet → Code par VF_ONGLETS.aller (même document) : zone absente de Projet, reposée sur Code
  ❌ FAIL — EN1.6 — A51 : après deux allers-retours d'onglet, mêmes observateurs et écouteurs vivants qu'à froid, aucun cumul
  ❌ FAIL — EN2.1 (1440 px, code) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1440 px, codeClair) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1440 px, projet) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1440 px, equipe) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1600 px, code) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1600 px, codeClair) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1600 px, projet) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1 (1600 px, equipe) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement
  ❌ FAIL — EN2.1b — en français (?lang=fr) les libellés sont Lire, Suivre, Affichage (dictionnaire du chrome)
  ✅ PASS — EN2.2 (1279 px) — aucun groupe ni libellé, ordre DOM des boutons de .hr inchangé
  ✅ PASS — EN2.2 (1100 px) — aucun groupe ni libellé, ordre DOM des boutons de .hr inchangé
  ✅ PASS — EN2.2 (800 px) — aucun groupe ni libellé, ordre DOM des boutons de .hr inchangé
  ✅ PASS — EN2.2 (390 px) — aucun groupe ni libellé, ordre DOM des boutons de .hr inchangé
  ❌ FAIL — EN2.2b — rectangles des boutons de .hr égaux à la base de 1279 à 390 px (sauf l'ouvreur Git à 36 px : P80-D-56)
  ❌ FAIL — EN2.2c — de 1440 à 1100 px sans recharger : les groupes sont défaits, ordre et rectangles ceux d'un chargement à 1100 px (déplacés, jamais 
  ❌ FAIL — EN2.3 — fil d'Ariane : chaque .sep porte un svg aria-hidden et aucun « / » ; l'en-tête ne déborde pas
  ❌ FAIL — EN2.4 — Parcours n'a plus le triangle de lecture, Travail récent n'a plus l'air d'un chargement
  ❌ FAIL — EN2.4b — #vf-lock : glyphe de sessions de 701 à 1 639 px (libellé masqué), point et libellé au-delà ; troncature à 220 px gardée
  ✅ PASS — EN2.5 — à 1440 px : Santé s'ouvre, Échap la ferme et rend le focus à #btn-health ; le menu des parcours s'ouvre sous son bouton et Échap le
  ❌ FAIL — EN3.1 — boîte dessinée de l'ouvreur : 36 px au pointeur fin à partir de 1 000 px (comme ses voisins), 44 px en dessous et au toucher
  ✅ PASS — EN3.2 — zone d'appui : les points à 1 px d'un carré de 44 × 44 centré sur l'ouvreur tombent sur lui, en tête de .hr
  ✅ PASS — EN3.4 — mouvement réduit : aucune animation active après un glisser, un zoom puis le passage de 1 440 à 1 100 px
  ✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
  Résultats : 13 PASS / 21 FAIL
```

### Réécritures sur le contrat 36/44 (P80-D-56) : ancien et nouveau libellé, même force (mesures exactes, mêmes largeurs)

- FI2.3 (test-cockpit-finitions.sh) — ancien : « de 701 à 1279 px, l'ouvreur Git reste à 44 × 44 (P78-D-34 ; P80-D-56 est porté par 80-20) », attendu `[[44,44],[44,44]]`.
  Nouveau : « de 701 à 1279 px, l'ouvreur Git est dessiné à --hdr-btn (36 px au pointeur fin dès 1 000 px, 44 en dessous et au toucher) et sa zone d'appui mesure 44 × 44
  au moins », attendu `[[44,44,true],[36,36,true]]|[44,44,true]` (800 px et 1 100 px souris, plus 1 100 px au toucher). Une seule assertion, comme avant ; la mesure gagne
  l'appui (quatre points à 1 px dans un carré de 44 centré) et un cas tactile.
- H4.1 (test-cockpit-git-entete.sh) — ancien : « ${w} px : ligne masquée, ouvreur 44 × 44 en tête de .hr (P78-D-34, icône de 701 à 1279 px) », attendu `false|true|44|44|true`
  pour 768, 999, 1000, 1100, 1279. Nouveau : « ouvreur dessiné à ${T} × ${T} (--hdr-btn, comme ses voisins), zone d'appui de 44 × 44 au moins, en tête de .hr », attendu
  `false|true|36|36|true|true` de 1 000 à 1 279 px et `false|true|44|44|true|true` à 768 et 999 px. Cinq assertions, comme avant ; seconde ligne dès 1 280 px, absence de
  l'ouvreur au téléphone, débordement et rangée unique : inchangés.
- M-OUVREUR : non écrit par 80-17 (régime allégé) ; aucun mutant dans ce plan (rituel levé).

### test-cockpit-finitions.sh sur la base
```
  ❌ FAIL — FI2.3 — de 701 à 1279 px, l'ouvreur Git est dessiné à --hdr-btn (36 px au pointeur fin dès 1 000 px, 44 en dessous et au toucher) et sa zon
  Résultats : 22 PASS / 1 FAIL
```

### test-cockpit-git-entete.sh sur la base : H4.1 rouges
```
  ❌ FAIL — H4.1 — 1000 px : ligne masquée, ouvreur dessiné à 36 × 36 (--hdr-btn, comme ses voisins), zone d'appui de 44 × 44 au moins, en tête de .hr 
  ❌ FAIL — H4.1 — 1100 px : ligne masquée, ouvreur dessiné à 36 × 36 (--hdr-btn, comme ses voisins), zone d'appui de 44 × 44 au moins, en tête de .hr 
  ❌ FAIL — H4.1 — 1279 px : ligne masquée, ouvreur dessiné à 36 × 36 (--hdr-btn, comme ses voisins), zone d'appui de 44 × 44 au moins, en tête de .hr 
Résultats : 116 réussis, 20 échoués, 0 sautés
```

Les 17 rouges hérités de 79-16, relevés AVANT le premier commit de ce plan sur la tête de départ (test-cockpit-git-entete.sh : 119 / 17) : H2.3a, H2.3b, M-COUPURE, H9.2,
M-TABINDEX-DEFINITION, M-ARRIVER, M-TEXTE, M-ABSENT, M-MEMOIRE, M-MASQUE, M-REPOS, M-CHARGEMENT, M-DOUBLE-LECTURE, M-BLOC-VUE (trois cas), M-ECART. Rejeu de la même suite
(avec mes tests) sur la base : les mêmes 17 plus H4.1 à 1 000, 1 100 et 1 279 px (comparés par `comm` sur les libellés). Aucun des cas que ce plan réécrit (H4.1) ne fait partie des 17.
