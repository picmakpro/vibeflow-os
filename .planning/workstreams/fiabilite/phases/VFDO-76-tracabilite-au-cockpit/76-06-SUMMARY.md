---
phase: 76
plan: "06"
requirements-completed: [TRAC-01, TRAC-02, TRAC-03, TRAC-04, TRAC-09, TRAC-11]
---

# 76-06 : Page, section de phase, preuves, Jalon, panneau d'exigence : SUMMARY

## Livré

- Six fichiers `ui/74-vf-trace*.js` (≤ 191 lignes, ≤ 160 colonnes, aucun `innerHTML`, aucune lecture de jeton hors `VF_ETAT`) :
  `74-vf-trace.js` (lecture par `VF_ETAT.lireJson`, requête partagée, cache de page, zones : chargement après 150 ms, séquence, relance par `planning` des zones
  ouvertes seulement ; `VF_COQUILLE.surOnglet(…, { cle: '74-vf-trace.js' })` ; navigation `ouvrirSurMesure` / `allerNoeud` ; Échap ; `VT.ouvreurs` et `VT.ouvrir`
  pour 76-07), `-rendu` (glyphes, bande, ligne d'exigence, bilans, légende, états de § 9, `+ N autres`, preuve, ligne du Jalon), `-sections` (entrée haute,
  section de phase, preuves attachées, Jalon), `-style` (feuille `vf-trace-*`, cinq masques copiés tels quels), `-exigence`, `-liste`.
- Suite `test-cockpit-tracabilite-page.sh` (54 assertions : C0, C1.0 à C1.12, C2.1 à C2.10) et deux harnais `chrome-tracabilite.mjs`, `chrome-tracabilite-exigence.mjs`.
- Six lignes `AJOUT` dans `VENDORED.txt`, entre `73-vf-tiroir-travail.js` et `75-vf-modele.js` : `74-vf-trace-exigence.js`, `-liste.js`, `-rendu.js`, `-sections.js`,
  `-style.js`, `74-vf-trace.js`.
- Points d'extension pour 76-07 (noms exportés, contrat interne) : `VFTrace.ouvrirSurMesure({ html, bind, titre, clavier, depuis })`, `VFTrace.allerNoeud(id)`,
  `VFTrace.ouvreurs[sorte] = (cle, { clavier, depuis })` appelés par `VFTrace.ouvrir(sorte, cle)`, `VFTrace.ouvrirListe({ titre, sorte, elements, rendreLigne, visee, apres })`,
  `VFTrace.zone(conteneur, { cle, lire, rendre })`, `VFTrace.lire(vue, cle)`.

## Hauteurs mesurées (lab de page, phase 1 à 7 exigences)

Section `#vf-trace-phase` : 1440 px, repli fermé 640 px, ouvert 764 px (bornes de l'UI-SPEC § 2.3 : 888 et 1 306) ; 390 px, 483 px et 632 px (bornes 614 et 968).

## Revalidation des points de l'UI-SPEC § 15

- Le bouton Retour de l'en-tête reste au-dessus d'un panneau posé par `SC.showPanel` ; `titre` = titre du panneau quitté (texte). Constaté par C2.1 (suite des Retour :
  plan, exigence, phase, pile vide, Retour désactivé).
- Règle d'empilement : la 80 n'empile PAS un nœud quitté par `SC.showPanel` (la sélection reste la même, `surPanneau` ne voit pas de changement). La 76 empile donc
  elle-même la phase avant d'ouvrir l'exigence, puis l'exigence avant un plan, une décision ou une liste (`empiler` une fois par panneau quitté, jamais à l'arrivée).
  La vue d'ensemble n'est pas empilée quand la phase est ouverte par `select` hors panneau.
- `[data-vf-section]` actif : l'entrée haute défile jusqu'à la section (C1.7b, au clavier). Un `keydown` Entrée sur un bouton de `.vf-trace` est arrêté au `document` pour que
  l'Entrée globale du moteur (qui plonge dans la sélection) ne redessine pas le panneau.
- `surOnglet` : l'abonnement à `planning` est rendu sur Code et repris une fois au retour sur Projet, une seule section, une seule entrée, un seul Jalon (C2.4).
- Les fichiers `ui/74-vf-trace*.js` s'exécutent aussi sur l'onglet Code (la coquille charge tous les `ui/*.js`) : ils y posent `window.VFTrace` mais rien d'actif
  (la sortie anticipée de `74-vf-trace.js` et `VT.installe`).

## Écarts

- Écart : le bilan suit le gabarit de l'UI-SPEC (« Par exigence : 2 en contradiction · 3 avec un manque · 1 non lisible · 1 complète ») et non la phrase de C1.4 du plan.
- Écart : bornes de hauteur de C1.12 prises à l'UI-SPEC § 2.3 (888, 614, 1 306, 968), pas à celles du plan (792, 466, 1 148, 694) que le rendu mesuré dépasse à 390 px.
- Écart : « + N autres … » s'accorde au singulier pour N = 1 (« + 1 autre fichier de preuve »).
- Écart : aucune entrée ajoutée à `vf-cockpit-fr-exclusions.json` : les fichiers à marqueur `// VibeFlow (` sont hors inventaire, et le garde (F4) rougirait sur une exclusion
  dont le texte n'est pas dans l'inventaire. `test-cockpit-chrome-fr.sh` est vert (141). C1.13 du plan (passage du rendu au garde d'inventaire) n'est pas rejoué à part.
- Écart : états « pas de compartiment » et « Étape N » de C1.10 : copie écrite (`VT.etat`, `VT.etatDe`) mais non rejouée par un lab dédié (régime allégé).
- Écart : C2.5 rafraîchit sur une exigence retirée du registre : une réécriture sur place d'un SUMMARY, ou l'ajout d'une ligne de tableau, ne produit aucun événement
  `planning` côté page (mesuré : `VF_ETAT.lire('planning')` reste nul 25 s). La relance suit donc un changement de structure du graphe, comme le veut la 79 ; à porter au manager si
  l'on veut que les bilans suivent aussi un contenu modifié sur place.
- Écart : l'export n'embarque ni texte d'exigence ni critère (C2.6b) ; le code de la 76 y figure, inactif sans `FLOORPLAN_SERVER`.
- Aucun contrat consommé par une autre phase (73, 77, 79, 80) n'est changé.

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : mutants (M-MOT-VERIF, M-PLAFOND, M-RECOMPTE,
  M-CORAIL, M-EXCLUSION, M-INNERHTML, M-PREUVE-CORPS, M-NUE-EXIG, M-EMPILER, M-EMPILER-NOEUD, M-EXPORT, M-REF-GARDEE, M-CLE-CRUE), triple passe, rejeu des cas sautés.
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : étage design `craft` et `critique`
  (aucun sous-agent lancé ; une passe de juge sur captures à la fin de la phase).
- Le témoin rouge de chaque tâche est dans `76-06-RED-TRACE.md`.

## Suites jouées (une fois, sur la tête commitée `1e2bed01`)

| Suite | Verdict | Durée |
|---|---|---|
| `test-cockpit-tracabilite-page.sh` | 54 PASS / 0 FAIL | 64 s |
| `test-cockpit-chrome-fr.sh` | 141 PASS / 0 FAIL | 55 s |
| `test-cockpit-vendor.sh` | 251 PASS / 1 FAIL (V4, `check-file-size.sh`) ; la même commande rejouée seule sur l'arbre : exit 0, `✓ OK (0 avertissement)` : cause non établie (aucun fichier de 300 lignes n existe dans l arbre) | 175 s |
| `check-version-sync.sh` | rouge § 9 attendu (compteur « 236 suites », réel 237), jusqu'à 76-08 | 1 s |

Temps total des suites de la tête : environ 295 s.
