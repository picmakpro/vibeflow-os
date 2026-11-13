# 74-07 : SUMMARY (bandeau « Dépôt » de la frise et coût en jetons et durées)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré
- `ui/74-vf-frise-depot.js` (extension `depot` : lecture Git, états, dessin, clic) et `ui/74-vf-frise-depot-voies.js` (rangement par branche, fusion des commits proches, noms accessibles, feuille ; scission prévue par le plan), `ui/74-vf-cout.js` (extension `cout` : synthèse de l'en-tête, section, regroupements) et `ui/74-vf-cout-tableau.js` (tableau, feuille). `tests/test-cockpit-frise-cout.sh` (D0 à D14) ; trace du rouge : `74-07-RED-TRACE.md`.
- Inscription : `surOnglet(rappel, { cle: '74-vf-frise-depot.js' })` et `{ cle: '74-vf-cout.js' }` ; le rappel enregistre l'extension et rend son nettoyage (abonnement `git`, abonnement `etat`, minuterie). L'abonnement et la lecture Git partent au premier dessin de la frise (le montage du bandeau), pas au chargement du script. Aucun module marqué `vf-coquille: persistant`.
- Forme réelle relevée sur la tête : `window.VFGitTiroir.ouvrirSur(sha)` (77-vf-git-tiroir.js, 80-06) : valide le sha, ouvre le tiroir et le volet, rend une promesse booléenne, jamais d'exception ; région « Détail du commit <7 premiers caractères> ». La suite D4 joue contre ce tiroir RÉEL (aucun tiroir factice). `cockpit-git@1` inchangé (A9) : `at` en secondes, `rangees[{h, h7, p, at, s, refs[{type, nom}], teinte…}]`, `base.nom`, `bornes.tronque`. `VF_ETAT` clé `git` ne porte que `{ seq, at, sig }` : l'événement déclenche UNE relecture par `VF_ETAT.lireJson('/api/vf/git')`.
- Texte de l'annonce retenu quand `ouvrirSur` rend `false` (ou sha invalide) : « Ce commit n'est pas disponible dans le tiroir Git. » (dit par la région `aria-live` de la frise). Sans `ouvrirSur`, les commits sont des repères `role="img"` sans « Ouvrir dans le tiroir Git ».

## Écarts
- Précondition 79 (P74-D-56 / OK-PRECONDITION-79) remplacée par les prérequis réels, non jouée.
- Annonce : le plan disait « Commit introuvable dans les rangées lues », le contrat UI (§ 2, § 9) dit « Ce commit n'est pas disponible dans le tiroir Git. » : le contrat UI l'emporte.
- Mutants : plan non marqué audit, aucun des douze mutants n'est joué (régime allégé) ; la vérification `OK-MUTANTS` du plan ne s'applique donc pas. Témoin = suite rouge sur la base puis verte.
- « + N branches » est dans la colonne, donc avant les boutons de commit dans l'ordre du DOM (le contrat dit après) : la colonne et la piste sont deux cellules, le bouton de la colonne les précède.
- Les boutons de commit sont dans la cellule de piste de la rangée Dépôt (`position: relative`), pas dans la couche superposée partagée avec le curseur : même cadre, aucune interférence avec le repère du curseur (74-06).
- La synthèse REMPLACE le texte du paragraphe `.vf-frise-synthese` écrit par 74-04 (« N voies, N au travail ») au lieu d'ajouter un second paragraphe ; elle porte « Résultat incomplet (N voies non montrées) » quand la lecture est tronquée.
- Le coût s'abonne aussi à `VF_ETAT` clé `etat` (missions et phases arrivent du magasin, le tableau se redessine).
- Sonde D9 : la phrase « Rien n'est estimé. » (exigée par D7) est retirée du texte avant la recherche de « estimé ». Sonde D5 du plan « toutes les requêtes de frise portent des bornes » non reprise : la première inscription à `VF_ETAT.abonner('frise')` fait lire la route sans bornes (écart déjà noté par 74-04).
- Pas de contrôle visuel en navigateur (captures) : seules les sondes mesurées de la suite (alignement colonne et piste, tailles, couleurs résolues, absence de défilement horizontal à 390 px).

## Suites jouées (tête commitée 4db545d3, une fois chacune)
| Suite | Verdict | Secondes |
|---|---|---|
| test-cockpit-frise-cout.sh | 82 réussis, 0 échec (la mise au point avait joué la suite complète : 78 réussis puis D14 corrigée) | 40 |
| test-cockpit-frise-vue.sh | 95 réussis, 7 échecs : S6 (clic sur une voie), S17 (4) et S19 (2), tous des abonnés `frise` (2 au lieu de 1) ou l'espion `__vfFiche` écrasé : effet du module de la fiche (74-05, `74-vf-fiche.js` s'abonne à `frise` et pose `window.__vfFiche`), pas du Dépôt ni du coût (aucun des quatre modules ne s'abonne à `frise`, ni ne touche `__vfFiche`) | 173 |

Aucun fichier `77-vf-git-*` ni `74-vf-frise*.js` (74-04) modifié (diff par fichier depuis la base de `74-07-RED-TRACE.md`).

## Contrat consommé par d'autres phases
- 74-09 : ajouter les lignes `AJOUT` de `VENDORED.txt` et l'inscription au partage de `ci-shard-suites.sh` pour `74-vf-frise-depot.js`, `74-vf-frise-depot-voies.js`, `74-vf-cout.js`, `74-vf-cout-tableau.js` et la suite `test-cockpit-frise-cout.sh` (non posées ici).
- 74-04 / 74-05 : les sondes S6, S17 et S19 de `test-cockpit-frise-vue.sh` ne connaissent pas le second abonné `frise` ni le `__vfFiche` réel de la fiche ; à rapprocher dans le plan de la fiche.
- Les extensions `depot` et `cout` lisent `ctx.emplacement`, `ctx.nodes.lignes` (`.vf-frise-synthese`) et `ctx.nodes.sr` (liste `ul`) : toute refonte de ces nœuds par 74-04 ou 74-06 les touche.
