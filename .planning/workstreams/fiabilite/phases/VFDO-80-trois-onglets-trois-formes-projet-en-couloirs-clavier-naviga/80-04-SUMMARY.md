---
phase: 80
plan: "04"
subsystem: cockpit-projet-couloirs
requirements-completed: [FORM-05, FORM-07]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-modele.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-rendu.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-vue.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-clavier.js
    - plugin/cockpit/scripts/tests/test-cockpit-couloirs.sh
    - plugin/cockpit/scripts/tests/chrome-couloirs.mjs
    - plugin/cockpit/scripts/tests/chrome-couloirs-clavier.mjs
    - plugin/cockpit/scripts/tests/couloirs-commun.sh
  modified:
    - plugin/cockpit/scripts/tests/chrome-session.mjs
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
---

# 80-04 : Projet en couloirs

## Livré
- Vue DOM de Projet à la racine : un bloc par jalon (en cours d'abord, « Hors jalon » à la fin), quatre couloirs, cartes-boutons, ligne d'état lue dans `avancement` et `exigences`
  (jamais le pied), troncature 31 + « … » + 20 au-delà de 52 caractères, Historique et listes (Backlog, Graines, Releases, Missions hors phase) en `details` repliés. `?vue=graphe` montre le canevas.
- Clavier : un arrêt par collection, flèches par position à l'écran, Origine/Fin, Entrée plonge, Espace sélectionne, Échap désélectionne puis remonte, sélection qui suit le focus en panneau latéral.
- Panneau par-dessus (extrémité défilable de fin, tiroir Git en début, panneau latéral seulement), zone basse `--vf-bas` relue par `ResizeObserver`, visite jouée sur le graphe, redessin du direct avec restitution du focus (règle orphelin), `reveal` ramené à la racine.
- `naviguer(url, { brut })` : `vue=graphe` ajouté aux adresses `project.html`.
- Aucune requête réseau (`fetch` : 0), aucun `behavior: 'smooth'`, aucun patch du moteur (`viewer.html`, `40-tour.js`, `70-vf-live.js` intacts), tous les `innerHTML` reçoivent une chaîne passée par `h()` ou une constante.

## Commits
`3ebcd80b` amendement CL2.7 · `b745367c` témoins CL1 · `12f70581` feat (tâches 1 et 2 : modèle, rendu, vue livrés ensemble) · `e72631a4` témoins CL2/CL3 · `ade6f81c` feat clavier et reste de la vue · `23d6bc6c` bascule à gauche + amendements · commit final (flottant, SUMMARY).
Aucun de mes commits ne porte la ligne d'un autre plan. `9e60d903` (80-05) a emporté mes trois lignes `41-vf-projet-{modele,rendu,vue}` de VENDORED.txt (même contenu).

## Preuves
`test-cockpit-couloirs.sh` : 52 PASS / 0 FAIL (rouge sur la base : 6 PASS / 51 FAIL, voir RED-TRACE). Non-régression : vendor 137, clavier-canevas 32 (un rouge sous charge, 32/0 au rejeu seul), surcouches 45, accessibilite 35, moteur-carte 73,
flux-unique 7, chaine-xss 34, direct 76 (6 rouges sous charge, 76/0 seul), responsive 378 (2 rouges dont R15.5 : la bascule flottante recouvrait le titre, déplacée ; 378/0 au rejeu), chrome-fr 97, lancer-ui 63, projet-visite 115. Gabarit : OK (≤ 299 lignes, ≤ 160 colonnes, aucune lecture `.req`/« couvre »), css-jetons : 0.

## Mutants (copie maison `$WORK/mod-<nom>`, pas `cockpit_module_copie`)
M-FOOT (modele : ligne d'état lue dans `foot`) → CL2.3 · M-XSS (rendu : titre sans `h()`) → CL2.6 · M-POUSSE (vue : rail rétréci panneau ouvert) → CL3.5 · M-ORPHELIN (vue : règle orphelin retirée) → CL3.11 · M-EXTREMITE (vue : extrémité de fin à largeur 0) → CL3.12. Tous rougissent, témoin vert à côté.

## Écarts (amendements datés dans le PLAN)
Pilote du clavier et socle sourcé en fichiers neufs · CL1.3 sur la phase 3 · segments de bascule à 8 px · bordure 1,5 px lue sur la règle (Chrome la calcule à 1 px) · bascule et barre de jalon à gauche (le panneau les recouvrait) ·
de 701 à 999 px et au tactile à 1 100 px le panneau reste une colonne latérale : l'extrémité défilable vaut dès 701 px (correction de revue), la hauteur de feuille n'est comptée que s'il est posé en bas · à 390 px le tiroir du terminal est plein écran, non amarré · hypothèse 9 : sur le lab, faites = cases cochées (2 = 2), écart non éprouvé.

## Pour la jointure et les plans suivants
- Idiome A51, laissé à la jointure : `SC.on('render'|'panel')` posés sans retrait ; le disposer ne retire ni le `<style>`, ni les classes `body.vf-forme-couloirs`/`vf-forme-graphe`, ni `window.VF_PROJET` ; pas de clé `surOnglet`. Les observateurs et écouteurs DOM sont retirés par le disposer.
- API : `VF_PROJET { formes, forme, basculer(nom, { url }), carteDe }` ; `FORMES` et `LIBELLES` sont des constantes de `41-vf-projet-vue.js` (236 lignes, reste 63) : 80-07 y inscrit `liste`. `__vfProjetModele` (`etiquettePreuve` rend '' : à remplacer par la 76), `__vfProjetRendu`, `__vfProjetClavier { appliquer, poser, ramener, ordre, repli, memoire, cle }`.
- Sélecteurs : `section.vf-projet`, `.vp-jalon[data-jalon]`, `.vp-couloir[data-couloir]`, `.vp-carte[data-id]`, `.vp-rangee`, `.vp-details[data-cle]`, `.vp-status`, `#vf-projet-titre`, `#vf-projet-flottant` (bascule du graphe, haut centre ; bas au téléphone).
- `chrome-session.mjs` : 4 lignes ajoutées avant `naviguer` (ancre distincte d'`ouvrir`). Les pilotes de couloirs lisent comme posées les clés `floorplan:tour-seen:` et `vibeflow-cockpit:visite:`.
- Ligne de CHANGELOG pour 80-18 : « cockpit : Projet se lit en quatre couloirs par état, un bloc par jalon, le graphe reste à la demande ».
- Captures : dossier `png/` du scratchpad du mandat (non versionné) : couloirs-1440-sombre, -1440-clair, -390-sombre, -390-clair, -1440-focus-clavier.

## Correction de revue (2026-11-12)
Fantôme à 390 px : le pied `.foot .meta` d'une carte du canevas caché (carte « Historique »), que `00-vibeflow.js` force en `visibility: visible` (règles `lod-mid`/`lod-low`) malgré `#svg { visibility: hidden }` ;
vient de la couche existante, corrigé côté 41-* par `#svg *` en `visibility: hidden !important` (témoin CL1.5). Focus et annonce de la bascule (CL1.6), segment actif cerné (bordure `--hair-2`), extrémités dès 701 px (CL3.12, CL3.13),
bascule flottante centrée dans la zone libre, M-ORPHELIN resserré, lab hostile (nom de jalon clos, entrée de Backlog, graine au nom piégé) avec M-XSS-ID et M-XSS-HIST.
