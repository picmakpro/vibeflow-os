---
phase: 80
plan: "08"
subsystem: cockpit-panneau-retour
requirements-completed: [FORM-08]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/42-vf-panneau-retour.js
    - plugin/cockpit/scripts/tests/test-cockpit-panneau-retour.sh
    - plugin/cockpit/scripts/tests/chrome-panneau-retour.mjs
    - .planning/workstreams/fiabilite/phases/VFDO-80-trois-onglets-trois-formes-projet-en-couloirs-clavier-naviga/80-08-RED-TRACE.md
  modified:
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
---

# 80-08 : pile Retour du panneau de Projet (part Retour de FORM-08)

## Livré
- `window.VF_PANNEAU = { retour(), empiler({ titre, rouvrir }), taille() }` (gelé, 104 lignes), posé seulement sur l'onglet Projet, retiré au départ (indéfini sur
  Équipe et Code, PR2.8). Pile bornée à 32 ; une entrée dont `rouvrir` lève est retirée et la suivante est rouverte dans le même clic.
- Bouton `.vf-retour` : dans la barre de la feuille de détail avant la croix quand elle existe, sinon dans une barre en tête du panneau ; « Retour : <titre> » coupé au milieu
  (24 points de code), nom accessible complet, `aria-describedby` « Revenir à la sélection précédente » ; pile vide : `aria-disabled="true"`, « Retour, indisponible », `--text-4`
  (4,62:1 en sombre, 5,69:1 en clair, mesuré PR2.7 : le repli `--text-3` n'a pas été nécessaire). 36 px au pointeur fin, 44 px au tactile.
- Origine d'un geste : un clic dans `#panel` marque le prochain changement de sélection (fenêtre de 3 s) comme venu du panneau et empile le panneau courant ; tout geste venu
  d'ailleurs (carte, rangée, canevas, touche, remontée) vide ; `retour()` ouvre une fenêtre de 3 s où rien n'est ni empilé ni vidé (reveal passe par le jalon puis la racine :
  deux évènements `panel`). Vidage aussi à `vf:onglet` et à la fermeture du panneau (touche p, bouton), avec un délai de 400 ms car un `go()` referme et rouvre la feuille.
  Échap n'est jamais intercepté ; Échap de la feuille ferme sans vider (horodatage de la touche).
- `empiler` explicite : le panneau courant n'est alors pas empilé une seconde fois par le changement de sélection qui suit (fenêtre de 3 s).

## Commits
`3ce09447` amendement du 2026-11-12 · `3ac6cef3` témoins rouges + RED-TRACE · `d455327b` module + ligne `AJOUT` de VENDORED.txt (index temporaire : seule ma ligne) · commit final (SUMMARY).

## Preuves
- `test-cockpit-panneau-retour.sh` : 26 PASS / 0 FAIL, PR2.9 en `⏳ ATTENTE` (41-vf-projet-liste.js absent : couplage avec 80-07, exigé vert par 80-09). Rouge sur la base (copie sans le
  module) : 5 PASS / 25 FAIL (RED-TRACE).
- Mutants (copie du module dans `$WORK`, copie maison de couloirs-commun.sh, pas `cockpit_module_copie`), tous dans `42-vf-panneau-retour.js` : M-REEMPILE -> PR1.3, M-HTML -> PR2.4,
  M-BORNE -> PR2.3, M-GLOBALE -> PR2.8.
- Non-régression : vendor 139/0, lancer-ui 63/0, moteur-carte 73/0, accessibilite 35/0, couloirs 57/0. Gabarit : OK-GABARIT (≤ 299 lignes, ≤ 160 points de code, aucune lecture `.req`), css-jetons rc 0.
- `innerHTML` : une occurrence, `icone.innerHTML = SC.iconI('left')` (icône constante du moteur).
- Captures (scratchpad de 80-08, dossier png) : retour-1440-sombre, retour-1440-clair, retour-1440-focus-clavier.

## Écarts au plan (amendement du 2026-11-12 dans le PLAN)
- `69-vf-flux.js` est absent de la base (Phase 79). Le lab de couloirs n'avait pas de dépendances : la suite pose son lab (`mklabdep`). Pas de bouton « Fermer » sur le panneau latéral.
- PR2.2 : l'entrée défaillante est retirée et la suivante rouverte dans le même clic (le bouton montre alors l'entrée d'avant).
- Le fond de `#panel` du contraste est approché (rgba mélangé au fond de page, repli 18/18/18 en sombre).

## Pour la jointure et les plans suivants
- Idiome A51, `cockpit_module_copie`, `socle-serveur.sh` : non appliqués (pas dans la base). VENDORED.txt : ligne `AJOUT assets/ui/42-vf-panneau-retour.js` après `41-vf-projet-vue.js`.
- PR2.9 : la branche cherche, dans `section.vf-projet`, un `[data-id^="n:ph-"]` qui n'est pas `.vp-carte` (sélecteur à ajuster à la liste de 80-07).
- Ligne de CHANGELOG pour 80-18 : « cockpit : le panneau de Projet a un seul Retour, qui dit où il ramène (pile de 32 sélections, nœuds et panneaux sur mesure) ».
