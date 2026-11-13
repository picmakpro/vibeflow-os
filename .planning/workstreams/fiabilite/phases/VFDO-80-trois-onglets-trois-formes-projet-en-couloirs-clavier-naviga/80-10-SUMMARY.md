# 80-10 — changer d'onglet sans recharger la page (FORM-16) : SUMMARY

## Livré
- `ui/00-vf-onglets.js` (122 lignes, persistant A53, garde d'unicité) : clic d'onglet intercepté (dans un rappel `surOnglet`), `popstate`, `VF_ONGLETS.aller(nom, { fragment })`
  et `courant()` passent par une seule fonction : `chargerOnglet` d'abord, `pushState` après sa résolution seulement (jamais depuis `popstate`), vue mémorisée
  restituée (conteneur, sélection, zoom par `transformer`), titre, `vf:onglet { onglet, precedent }`, focus de repli (couloirs ou liste : élément sélectionné sinon `h1` ;
  Code et Graphe : carte sélectionnée ou itinérante sinon `#stage`), annonce. Chargement rejeté : ni adresse, ni onglet, ni focus, ni événement ; `aller` rejetée ;
  après un `popstate` rejeté, adresse ramenée par `replaceState`. Fragment : celui de l'onglet d'arrivée (mémorisé) ou explicite, jamais celui de l'onglet quitté.
- Ligne `AJOUT assets/ui/00-vf-onglets.js` de `VENDORED.txt`. Suite `test-cockpit-onglets.sh` + pilote `chrome-onglets-routage.mjs` : 27 PASS / 0 FAIL (OG1, OG2.1 à OG2.13,
  OG3, OG2.2 réduit). Rouge de base : `80-10-RED-TRACE.md` (3 PASS / 23 FAIL). `chrome-onglets.mjs` de 79-14 est resté intact.
- API remise au manager : `p10-livraison.txt` (commit 2736fe67).

## Écarts
- Écart : le tiroir Git se ferme avec son onglet (`77-vf-git-tiroir.js` : « l'état ouvert n'est pas mémorisé », son nettoyage passe avant celui du routeur). Le routeur lit
  `VFGitTiroir.ouvert()` avant tout chargement et le rouvre à l'arrivée (`ouvrir()`, relecture de `/api/vf/git` du tiroir lui-même, aucune lecture neuve du routeur).
- Écart : OG2.2 réduit. Le terminal est dans un cadre d'une autre origine (port propre) : le tampon xterm n'est pas lisible depuis la page. Preuve : le cadre est le même
  nœud, connecté, et n'a reçu aucun `load` après l'aller-retour. Écriture dans le tampon : à ajouter après un pilote qui s'attache à la cible du cadre. L'amorce à usage
  unique n'est pas touchée (suite terminal-activation verte).
- Écart : `window.VF_PANNEAU` n'existe que sur Projet : OG2.3 lit la pile Retour (0) sur Projet seulement.
- Écart : l'annonce passe par la zone status de Projet (`VF_PROJET.annoncer`) quand elle existe, sinon par `#ask-live` ; `#ask-live` sert la barre de question, pas le repli.
- Écart : un retour sur Projet par clic reprend le chemin `/project.html` seul : la forme demandée par `?vue=` n'est pas gardée (Précédent/Suivant la gardent, l'entrée
  porte la requête). Plan : « chemin seul ».
- Défaut hors périmètre (signalé par le nœud sf35) : `41-vf-projet-clavier.js`, `membres(h1)` lève (`closest('.vp-details')` nul) quand `repli` pose le focus sur le `h1`.
  À chaque arrivée sur Projet sans sélection, `aller` était rejetée ; `00-vf-onglets.js` protège désormais ses gestes d'arrivée (la promesse ne dit que le chargement) et
  consigne l'erreur. Correctif de la cause confié au nœud `fixclav`. OG2.13 (modale ouverte puis `aller`) en témoin, qui ignore cette seule erreur de console.
- Correction ciblée (constat du nœud p13) : le moteur d'arrivée lisait le fragment de l'onglet quitté (`z`, `s`, `v`) au premier rendu. `aller`, le clic et Précédent-Suivant retirent le fragment (replaceState, aucune entrée) pendant le chargement, le mémorisent, le remettent à l'entrée quittée après le chargement ou si le chargement est rejeté ; depuis `popstate` rien n'est touché. OG2.14 et OG2.14b (rouge d'abord : `z` appliqué à Projet sur la version d'avant). Premier essai sans remise de l'entrée quittée : OG2.4, OG2.4b, OG2.12 rouges (le replaceState effaçait son fragment), d'où la remise. Suites : onglets 29/0, lien-vue 14/0.
- Mutants M-RECHARGE … M-FRAGMENT-REPORTE : non écrits. Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Suites (sur la tête commitée)
- test-cockpit-onglets 27/0 (tête commitée 6515517f + témoin OG2.13).
- terminal-activation 54/0 ; panneau-retour 43/0 ; projet-liste 51/0 ; accessibilite 35/0.
- terminal-tiroir 137/1 : T21.7 seul, rouge connu de la 79 (non réparé).
- git-tiroir : 193/1 (mutant M-SELECTION, mesure du clavier du graphe) puis, rejoué une fois sous forte charge de poste, 177/18 (sections D3.5, D3.6, D12 du pilote rendues vides) : non
  attribué à ce plan (aucun changement d'onglet dans la suite) ; à rejouer à poste calme, CI en dernier recours.
- couloirs : non jouée (fichier en cours de modification par fixclav : erreur de syntaxe du .sh à la ligne 113, hors de ce plan).
- vendor 250/2 : V4 (un fichier de code d'un autre nœud au plafond au moment de la mesure ; sans blocage au rejeu direct de check-file-size) et V4c.9a (HAUSSE de colonnes sur
  `41-vf-projet-clavier.js`, edit non commité de fixclav). V4c et la ligne `AJOUT` de ce plan verts.

Ligne de CHANGELOG demandée par 80-18 : « Changer d'onglet ne recharge plus la page : Précédent et Suivant marchent, le focus, le titre, le zoom, la sélection et le tiroir Git
suivent ; `VF_ONGLETS.aller(nom)` offre aux autres écrans un changement d'onglet attendu jusqu'à son premier rendu. »
