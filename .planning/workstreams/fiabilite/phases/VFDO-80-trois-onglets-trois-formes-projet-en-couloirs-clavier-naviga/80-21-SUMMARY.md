# 80-21 — dire l'échec d'un chargement d'onglet (FORM-16) : SUMMARY

## Livré
- `ui/00-vf-onglets-echec.js` (59 lignes, persistant A53, garde d'unicité) : une écoute de `vf:coquille-echec`, `preventDefault()` (jamais deux messages), annonce
  « Lecture impossible : les données de cet onglet n'ont pas pu être lues. L'onglet <nom> reste affiché. » quand un onglet reste affiché ; au premier chargement, boîte
  `#vf-onglets-echec` (`role=status`, `--warn-bg` sur `--surface`, sans animation) dans `#stage` (zone du canevas du gabarit, sélecteur relevé), bouton « Réessayer » qui prend le
  focus, retire la boîte puis relance ; un nouvel échec la remet avec le focus. Objet gelé `VF_ONGLETS_ECHEC = { montrer, retirer }`, rien gardé (l'échec se lit dans `VF_COQUILLE.etat()`).
- `ui/00-vf-onglets.js` (140 -> 150 lignes) : `VF_ONGLETS.echec()` (`null` ou `{ onglet, affiche }`, dérivé de `etat()` à chaque appel), `reessayer()`, `annoncer(texte)` ;
  pas de `pushState` quand la relance d'un premier chargement en échec vise l'adresse déjà affichée (aucune entrée d'historique de plus).
- `ui/07-vf-reessayer.js` (17 lignes) : source de palette « Réessayer » (groupe actions, détail = onglet visé, champ vide, saisie, mode `>`), seulement pendant un échec ; hors du
  registre `VF_RACCOURCIS` (pas dans l'aide `?`). `07-vf-raccourcis.js` et `viewer.html` non touchés.
- `ui/02-vf-ligne-echec.js` (44 lignes) : rangée « Lecture impossible · Réessayer » ajoutée à l'emplacement `#vf-coin-etat`, zone d'appui 44 par pseudo-élément, `surOnglet` à clé.
- `VENDORED.txt` : trois lignes `AJOUT`. Suite `test-cockpit-echec-onglet.sh` + pilote `chrome-echec-onglet.mjs` : 17 PASS / 0 FAIL (rouge de base : `80-21-RED-TRACE.md`, 2/15).
- Texte de 80-UI-SPEC.md § 5 pour Projet remplacé par celui de la coquille : erratum à porter à l'UI-SPEC (manager).

## Écarts
- Écart : la source de palette rend `groupe: 'actions'` (minuscule, API réelle de 80-14) et non « Actions ».
- Écart : la rangée d'état est posée dans `#vf-coin-etat` (le bloc se recalcule sur ses enfants) ; si 02-vf-ligne-etat.js cache cet emplacement (ni branche ni direct), la rangée l'est aussi.
- Écart : `echec()` suit la phase `echec` seule (motif de lecture ou non), comme le plan ; seul le motif de lecture émet l'évènement.
- Constat de la revue (la coquille ne relance pas son lot après un chargement échoué, clics suivants = rechargement de page) : hors objet. Il concerne un échec de DÉMARRAGE
  (motif null, après démontage), dans `vf-coquille.js` (79-16) ; l'échec de lecture traité ici laisse l'onglet intact et l'écouteur du routeur posé (EC1.2b, EC3.1b le prouvent).
- Cliquet de colonnes : la ligne d'en-tête de 00-vf-onglets.js dépassait 160 points de code, repliée (commit `(80-21)`), `colonnes-cliquet.mjs verifier` : OK, baseline inchangée.
- Mutants M-PREVENT-OMIS, M-ECHEC-SILENCE, M-PERSISTANT-ECHEC, M-PALETTE-FIXE, M-RANGEE-FIXE : non joués. Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Suites (sur la tête commitée)
- test-cockpit-echec-onglet 17/0 ; onglets 32/0 ; palette 25/0 ; vendor 252/0.
- coin 44/0 ; accessibilite 35/0 ; chrome-fr 141/0 ; panneau-retour 42/1 (PR2.6c, feuille de détail, sous charge) puis 43/0 au rejeu seul.
- colonnes-cliquet verifier : OK.

Ligne de CHANGELOG demandée par 80-18 : « Quand un onglet ne se charge pas, le cockpit le dit (« Lecture impossible ») et propose « Réessayer » : au premier chargement dans une vue
dédiée, ensuite par une annonce, la palette de commandes et la ligne d'état ; l'onglet affiché ne bouge pas. »

## Correctifs ciblés de revue (commit 62ab1e173)
- Majeur établi en rejouant : test-cockpit-coquille.sh 97/7 sur la tête précédente (la feuille de style du persistant restait dans la tête, `#vf-coquille-echec` annulé, mesures « intact » touchées par l'annonce et la rangée). Corrigé : le persistant retire boîte et feuille à toute arrivée (`surOnglet`) ; C8 joue sans lui (retiré des copies de module) ; les mesures « intact » de C3.3 et C8 ignorent les zones d'annonce et la rangée d'échec. Suite de la 79 touchée : 4 lignes, trailer Gate-Touche. Après : 104/0 (jeton Chrome, poste calme) ; trois rejeux sous charge de 200 à 290 ont rougi des contrôles de document différents à chaque fois (flake de charge, non attribué).
- Échec de démarrage : aller et le clic rechargent l'onglet d'origine (`etat()` en échec, motif nul, n'est plus « rien à charger »), sans entrée d'historique en plus ; EC4.1 (rouge d'abord, 16/5 avec EC2.3). Le clic lui-même n'est pas prouvé (l'écouteur du routeur est défait par la coquille sans le correctif 73f7ad5f de la 79).
- Mineur : le repli `#ask-live` se remet à zéro avant d'écrire. La rangée d'état rend à `#vf-coin-etat` son état caché en partant.
- Suites : coquille 104/0, echec-onglet 21/0, onglets 32/0. Écart connu : un Réessayer par le routeur après un premier échec laisse le bouton Retour de Projet (focus de repli), différence avec un chargement à froid propre à ce chemin.
