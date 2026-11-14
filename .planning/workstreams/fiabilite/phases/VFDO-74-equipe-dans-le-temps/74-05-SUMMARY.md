# 74-05 : SUMMARY, la fiche d'agent plein cadre

## Livré
- `ui/74-vf-fiche-faits.js` (112 lignes) : `window.__vfFicheFaits` = faits, rattachement, nomDe, dom (colonne des faits en nœuds de texte). « inconnu » pour toute valeur absente, arbre nul = « arbre principal », fichiers comptés par couple (arbre, cible), « 200 ou plus » au plafond ou sur `cibles.tronque`.
- `ui/74-vf-fiche-style.js` (82 lignes) : feuille à jetons, une seule règle de police mono, fondu de 200 ms coupé sous `prefers-reduced-motion`.
- `ui/74-vf-fiche.js` (278 lignes) : `window.__vfFiche = { ouvrir(id, origine), fermer(), ouverte() }` ; inscription `VF_COQUILLE.surOnglet(rappel, { cle: '74-vf-fiche.js' })`, non persistant ; Échap sur `document` en remontée, ignoré si `defaultPrevented` ; `vf-agent:ouvrir` annulé pour nom, ancre, rapport ; `vf-agent:lu { id }` à l'ouverture d'un agent terminé ; frise lue sur 24 h et fil par `VF_ETAT.lireJson`, relus sur `frise` (une fois par seconde au plus).
- `tests/test-cockpit-fiche.sh` (P1 à P18) et `tests/chrome-fiche.mjs` ; trace du rouge : `74-05-RED-TRACE.md`.

## Témoins de la 73 rougis (P74-D-54)
Aucun. Le lanceur `test-cockpit-regie.sh` joué sur la tête (après la fusion de 73-05 final) : 234 PASS, 0 FAIL, aucun saut. `74-05-ROUGES-73.txt` est donc vide (la commande « seuls les rouges attendus » du plan compare deux ensembles vides ; son test `-s` est caduc). Aucune suite de la 73 modifiée. Rappel : ne pas pousser avant 74-10.

## Relevé des contrats
- 73 (tête 97029657) : `vf-agent:ouvrir { id, kind, declencheur }` annulable ; nom = `.vf-rg-tog` de la ligne `li[data-vf-agent]`, rapport = bouton « Lire le rapport » de `.vf-rg-act`, ancre = la ligne (tabindex -1 posé au besoin) ; bascule = `[role=tablist]` « Vue de l'équipe » (n'existe qu'avec au moins deux vues) ; conteneur `section#vf-equipe`, vues `.vf-vue[data-vf-vue]`.
- 80 : geste d'Échap simulé par la suite (preventDefault puis stopPropagation en capture sur window) ; non relevé sur la branche de la 80.
- Signature : `ouvrir(id, element|null)`.

## Écarts
- Écart : précondition P74-D-56 non jouée, remplacée par les prérequis réels (régime allégé).
- Écart : le modèle de la frise n'a pas de compte de fichiers par voie (`fichiersA` est celui du curseur) : le compte par couple est fait dans `74-vf-fiche-faits.js`.
- Écart : le lien « carte de mission » (`n:dag-<nom>`) est porté par « rattaché par ses agents » d'un manager ; pour un worker, les trois liens sont parent, nœud (`f:<dag>#<noeud>`), phase.
- Écart : glyphes du fil pris dans la table unique de la régie (message : attente, humain : actif, compaction : orphelin, outil : repli, échec : bloque) ; aucun tracé neuf, donc formes proches de la spec seulement.
- Écart : un clic sur la bascule ferme la fiche (non prévu au plan). La fiche d'un agent terminé marque l'agent lu : son bouton « Lire le rapport » disparaît, le focus retombe alors sur la ligne, la voie ou la bascule.
- Écart : un Échap déjà pris par la régie (détail déplié dans la vue masquée) ne ferme pas la fiche, il faut un second appui.
- Écart : l'inscription `surOnglet` de la fiche est appelée plus de trois fois sur deux allers-retours (les scripts de l'onglet sont rejoués plus d'une fois par arrivée) ; la clé la remplace, aucun écouteur doublé : P18.b exige au moins trois appels, tous avec la clé.
- Écart : `surOnglet` espionné, `h.monter` vide aussi `localStorage` (l'état « lu » de la régie y persiste d'une section à l'autre).

## Rituels levés
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Pas de mutants (plan non marqué audit), pas de relecteur.

## Suites jouées (tête commitée)
| Suite | Verdict | Secondes |
|---|---|---|
| `test-cockpit-fiche.sh` | exit 0, 74 PASS, 0 FAIL, aucun SAUTÉ | 32 |
| `test-cockpit-regie.sh` (73) | exit 0, 234 PASS, 0 FAIL | 144 |
| `test-cockpit-fiche-texte.sh` | 34 PASS, 0 FAIL | 20 |
| `css-jetons.mjs`, `check-file-size.sh` | 0 écart ; 74-vf-fiche.js à 278 lignes (avertissement ≥ 250) | < 1 |

## Correction après revue (point de fusion, une passe)
- Bascule de vue : la fermeture provoquée par un clic sur la bascule ne touche plus `hidden` de la vue d'origine (la régie l'a déjà réglé), elle lève seulement `inert`. Sonde P19 (régie vers frise, frise vers régie, vue déjà choisie) lit `hidden` et `inert` de toutes les `.vf-vue` ; vue rouge avant le correctif (régie restée visible à côté de la frise), verte après.
- Écart : l'abonnement VF_ETAT « frise » de la fiche n'existe que fiche ouverte (posé à l'ouverture, retiré à la fermeture et au départ d'onglet) : décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par le manager de la Phase 74 le 2026-11-14. P15 et P18 ajustées (0 abonnement au repos, 1 fiche ouverte, 0 après fermeture).
- Suite de la frise (`test-cockpit-frise-vue.sh`) : l'espion `window.__vfFiche` est un accesseur (lecture figée, écriture ignorée) qui survit au chargement du vrai module ; S17 et S19 comptent les abonnements frise attribués par la pile d'appel (`74-vf-frise*.js`), via un enrobage de `VF_ETAT.abonner`. Le mutant SANS-NETTOYAGE (S17, S19) reste rouge.
- Suites jouées sur la tête commitée : `test-cockpit-fiche.sh` 78 PASS, 0 FAIL (47 s) ; `test-cockpit-frise-cout.sh` 82 PASS, 0 FAIL (43 s) ; `test-cockpit-frise-vue.sh` 102 PASS, 0 FAIL, 12 mutants rouges (169 s) au troisième passage : les deux premiers ont rougi une sonde différente chaque fois (S6 survol, puis S16 scrollLeft de la piste, `load average` 46 à 73 sur le poste), jamais une sonde touchée par la correction.

## Correction après revue 2
Le clic sur le fond de la bascule (conteneur `[role=tablist]`, hors d'un `[role=tab]`) ne ferme plus la fiche : seul un clic dans un onglet le fait. Sonde P19.c (fiche toujours ouverte, puis exactement une `.vf-vue` visible et aucune inert après « Retour »), rouge avant le correctif (fiche fermée, zéro vue visible) ; P19 prouve le défaut de `hidden` (rouge avant 8f655e9b), P19.c celui du fond. `test-cockpit-fiche.sh` : 79 PASS, 0 FAIL, aucun SAUTÉ (38 s) sur la tête commitée.
