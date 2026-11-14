# 74-04 : SUMMARY (la vue Frise de l'équipe : voies, colonne, pistes, source, style)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré
- `ui/74-vf-frise.js` (déclaration, barre d'outils, registre d'extensions, montage), `-source.js` (lecture, états, direct, textes), `-colonne.js`, `-pistes.js`, `-style.js` ; `tests/test-cockpit-frise-vue.sh` (S0 à S19, douze mutants) et `tests/chrome-frise.mjs`. Trace du rouge : `74-04-RED-TRACE.md`.
- Forme réelle relevée sur la tête : `window.__vfEquipeVues.declarer({ id, libelle, monter(el), demonter() })` (72-vf-regie-source.js) ne rend ni désinscription ni `retirer` ; la régie appelle `demonter()` de la vue choisie à son propre nettoyage et au changement de vue. Le rappel de `surOnglet` déclare la vue et rend `() => demonter()` (idempotent). Conteneur : `.vf-vue[data-vf-vue="frise"]` de `section#vf-equipe`. Nom accessible du tablist lu dans le DOM : « Vue de l'équipe » (dessiné par la régie, un seul `[role=tablist]`).
- `cle` : `74-vf-frise.js` (seul module qui s'inscrit) ; aucun module marqué `vf-coquille: persistant`. Seule clé de stockage écrite : `vibeflow-cockpit:frise-reglages` (`{ fenetre, lecture }`, écrite au montage et à chaque choix).
- Registre d'extensions tel que livré : `__vfFrise.enregistrer(nom, { rendre(ctx) })`, nom dans `curseur`, `encart`, `depot`, `cout` ; `ctx` = frise normalisée, modele, fenetre, lecture, libFenetre, depuis, jusqua, incomplet, voiesOmises, x(ms), proj, courbe, rangs, lignes, dim, curseurMs, annoncer, ouvrirFiche, nodes, plus `emplacement` et `couche` propres à chaque module. `emplacement` de `depot` = la RANGÉE `.vf-frise-rang-depot` (deux cellules `.vf-frise-c` colonne et `.vf-frise-p` piste, vides) ; de `encart` et `cout` = un `div` sous la légende ; `curseur` = la couche superposée. Aucune extension n'est appelée quand la frise n'a aucune voie. `__vfFrise.donnees()` rend `{ frise, depuis, jusqua, fenetre, lecture, curseurMs, ctx }`.
- Convention de traduction : noms d'agent, nœuds, arbres dans `.mono` (`.vf-donnee` rétablit la police sans) ; « Close » reste « Close » (S12).

## Écarts
- Précondition 79 (P74-D-56 / OK-PRECONDITION-79) remplacée par les prérequis réels, non jouée.
- `VF_ETAT.abonner('frise')` fait lire la route (sans bornes) par le magasin à la première inscription : cette notification (dans les 3 s) est ignorée, la lecture du montage la couvre ; ensuite une relecture bornée par événement, au plus une par seconde.
- Changer de lecture (Horloge, Événements) ne relit pas la route, il redessine ; changer de fenêtre relit.
- Pas posé : fil vertical et coude entre parent et enfants dans la colonne (retrait seul) ; défilement vertical du corps des voies (le repli seul borne la hauteur) ; suffixe « · déduit » (§ 2 ne le demande pas, à voir avec l'encart 74-06) ; voies fantômes du chargement sans animation, trois.
- Budget de nœuds : sur la fixture adversariale de 40 voies de 500 segments à 24 h, 40 092 nœuds SVG (chaque segment porte un `title`) pour un plafond écrit de 26 240 ; rendu mesuré 79 ms (limite 150). Non tenu pour les nœuds, tenu pour le temps.
- Inventaire des chaînes anglaises (`vf-cockpit-fr-inventaire.mjs`) : non rejoué (sortie illisible via rtk, tous les textes sont en français).
- Mutant M-FETCH-DIRECT : la sonde est S13 rejouée sur la copie du module.

## Suites jouées (tête commitée 5ce72481, deux jeux successifs identiques)
| Suite | Verdict | Secondes |
|---|---|---|
| test-cockpit-frise-vue.sh | 102 réussis, 0 échec, douze lignes MUTANT-ROUGE | 130 à 147 |
| test-cockpit-vendor.sh | 252 PASS, 0 FAIL (l'inventaire AJOUT de VENDORED.txt n'a pas rougi) | 95 |

## Contrat consommé par d'autres phases
74-06 (curseur, encart) et 74-07 (Dépôt, coût) se branchent par `__vfFrise.enregistrer` ; la fiche (74-05) est appelée par `window.__vfFiche.ouvrir(id, bouton)` s'il existe. Les modules ne sont pas encore inscrits dans VENDORED.txt ni dans ci-shard-suites.sh (travail à part).
