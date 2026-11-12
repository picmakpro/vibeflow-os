---
phase: 80
plan: "07"
subsystem: cockpit-projet-liste
requirements-completed: [FORM-09]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-formes.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-liste.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js
    - plugin/cockpit/scripts/tests/test-cockpit-projet-liste.sh
    - plugin/cockpit/scripts/tests/chrome-projet-liste.mjs
  modified:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-vue.js
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
---

# 80-07 : Projet en liste

## Livré
- Forme Liste à la racine : un `table` par jalon, tri État puis numéro (stable, non mémorisé), `th scope=col` + bouton « Trier par … », `aria-sort`, annonce « Trié par Plans, croissant », donnée absente triée en dernier avec texte masqué, rôles explicites et grille ≤ 700 px.
- Intérieur de phase : `h1` « Phase N », ligne d'état, plans groupés par vague (« Sans vague » en dernier), un arrêt de tabulation, exigences en `ul` à lecture seule ; « N exigences couvertes » par rangée de plan.
- Porte unique `lireExigences(phaseId)` (corps entre `// porte-exigences:début` et `:fin`), globale `window.VF_EXIGENCES` (objet simple, relu à chaque appel).
- Touche `v` (garde de saisie), rotation par niveau (couloirs, liste, graphe ; liste, graphe dans une phase), mémoire `localStorage` `vf-projet-forme:<lab>:<classe>`, défaut liste à ≤ 700 px, `?vue=` prioritaire non mémorisé.
- Bascule à trois segments égaux pleine largeur sous le `h1` à ≤ 700 px, segments ≥ 44 px (mesuré, PL3.5), demande du juge de design.

## Commits
`729506e8` amendement (étape 0) · test rouge (3 PASS / 39 FAIL sur la base) · `5c040807` feat · SUMMARY.

## Preuves
`test-cockpit-projet-liste.sh` : 37 PASS / 0 FAIL, cinq mutants rouges chacun avec son témoin. Non-régression : couloirs 57, vendor 143, chrome-fr 97, panneau-retour 41 (PR2.9 joué et vert). Gabarit : ≤ 299 lignes (vue 287), ≤ 160 octets par ligne, css-jetons 0, critères de la porte unique tenus.

## Mutants (copie maison `$WORK/mod-<nom>`, pas `cockpit_module_copie`)
M-CLE (formes.js : clé sans le nom du lab) → PL3.3 · M-TRI (liste.js : tri par défaut sur le numéro) → PL1.1 · M-SAISIE (formes.js : garde de saisie retirée) → PL3.2 · M-ORPHELIN-TRI (vue.js : restitution du focus d'en-tête et de summary) → PL3.7 · M-PORTE (phase.js : lecture directe du graphe, sur le lab sans exigence) → PL2.9.

## Écarts (amendement daté dans le PLAN)
Critère négatif de la porte : « couvre » en mot entier (« recouvre » d'un commentaire de 80-04 le faisait rougir) · ordre de chargement alphabétique : registre `window.__vfProjetRegistre`, `inscrireForme` écrit dedans · repli `41-vf-projet-formes.js` pris · rangées en `.vp-ligne` (le clavier de 80-04 suppose `.vp-jalon`/`.vp-details`) · PL3.5 à 800 px : colonne latérale par construction, feuille testée à 390 et 600 px · PL2.9 joue sur le lab sans exigence, PL2.1/PL2.2 « restent verts » sous M-PORTE non prouvé (autre lab) · PL3.8 : racine, feuille, terminal, intérieur de phase ; le tiroir Git n'est pas rejoué ici (80-06 en cours).

## Pour la jointure et les plans suivants
- API : `VF_PROJET { formes, forme (affichée), basculer(nom, { url, memoriser, equivalent }), carteDe, inscrireForme, niveau, redessiner, annoncer }` ; `__vfProjetListe`, `__vfProjetMemoire`, `__vfProjetRegistre['liste:racine'|'liste:phase']`.
- Sélecteurs : `.vp-ligne[data-id]` (racine : `n:ph-N` ; plans : `f:<chemin>`), `table.vp-table[data-coll]`, `th [data-tri]`, `.vp-pid`, `.vp-cov`, `ul.vp-exig`. PR2.9 : `section.vf-projet [data-id^="n:ph-"]:not(.vp-carte)` est satisfait.
- Idiome A51 (jointure) : liste.js, phase.js, formes.js posent leurs écouteurs `document`/`window` et leur `<style>` dans `init`, retirés par la fonction rendue ; clés `surOnglet` : `41-vf-projet-liste.js`, `-phase.js`, `-formes.js`. `window.VF_EXIGENCES` est recréé à chaque exécution de phase.js. vue.js garde ses `SC.on` sans retrait (idem 80-04). Tâche de jointure : passage à `cockpit_module_copie`, `socle-serveur.sh`.
- Ligne de CHANGELOG pour 80-18 : « cockpit : Projet se lit aussi en liste triable ; dans une phase, plans par vague et exigences ; touche v, forme retenue par lab et par largeur ».
- VENDORED.txt : trois lignes AJOUT (formes, liste, phase) entre `-clavier` et `-rendu`, alphabétiques ; aucune ligne d'un autre plan emportée.
- Captures (non versionnées) : liste-1440-sombre, liste-1440-clair, liste-390-sombre, liste-390-clair, liste-1440-focus-clavier, phase-1440-sombre.
