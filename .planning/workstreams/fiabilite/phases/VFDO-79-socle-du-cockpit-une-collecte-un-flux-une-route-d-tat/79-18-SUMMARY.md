# 79-18 — SUMMARY (SOCL-22 : la mise en page du canevas dans un worker)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré
- `assets/elk-fil.js` (worker, 25 lignes), servi sous `/_vf/` par la table fermée de 79-16 avec sa CSP propre (`default-src 'none'; script-src` à l'URL exacte du paquet ELK).
- `scripts/vf-cockpit-mise-en-page.mjs` : `NOM_FIL`, `ENTREE_FIL` (classe `fil`, jamais insérée par la coquille), `directiveWorker(hote)`, `cspFil(hote)` ; une ligne dans `lireAssets`, la CSP propre posée par `servirAsset` (200 et 304).
- `serve.mjs` : `cspDe(hashes, source, worker)` ; la ligne `const csp =` gagne `; ${worker}` après `script-src` (deuxième et dernière extension de la CSP de page).
- `viewer.html` : fabrique d'adaptateur à la place de `const elk = new ELK()` (worker construit en avance, `VF_COQUILLE.surOnglet` pour la terminaison, repli en ligne, un seul avertissement fixe si un `Worker` existe et échoue). `render()` non touché.
- Suite `test-cockpit-mise-en-page.sh` (60 assertions : W0 à W9, X mutants), trois aides (`mise-en-page-sonde/chrome/propriete.mjs`), M7 d'accessibilité alignée (sonde sur l'envoi au worker ET le calcul en ligne), formule de CSP à deux insertions exactes (terminal-aux, K3.3, T26), README racine à 231 suites, `VENDORED.txt` (AJOUT elk-fil.js), entrée de dictionnaire `Invalid layout reply`.

## Écarts
- **Hypothèse A2 fausse** : `elk.bundled.js` chargé dans un worker ne s'exporte pas (il pose son propre calcul sur `self.onmessage`, `new ELK()` échoue avec « _Worker is not a constructor »). `elk-fil.js` provoque cette pose (échec attendu ignoré, effet vérifié), enveloppe `self.onmessage`/`self.postMessage` et traduit le protocole interne vers `{ id, graphe }` / `{ id, resultat | erreur }`. Protocole, CSP et fichier servi inchangés. R1 « construit une instance d'ELK » devient « enveloppe le calcul posé par le paquet ».
- Fixture : 90 notes sans arêtes se calculent en 30 ms ; 90 modules à imports de voisins (1, 2, et 3 pour un module sur trois) donnent plus de 400 ms. Les imports sont dans la fixture, pas dans le moteur.
- Nom du worker écrit en deux morceaux dans `viewer.html` et préfixe lu dans le manifeste de la coquille : l'export autonome embarque ce script et le témoin W7.2 exige zéro trace (`elk-fil`, `worker-src`, `/_vf/`).
- W8.1 : l'oracle « chargement à froid » du plan est remplacé par « le même moteur en mode en ligne après la même suite » : un chargement à froid d'un onglet atteint par `chargerOnglet` diffère par l'état interne de l'onglet (hash, mode de vue), sans rapport avec le worker (constaté : `#v=n:history`, 4 cartes à froid, 1 en direct).
- X-CSP-ORIGINE et X-CSP-OBJET rougissent W2.1 ET W2.2 (la chaîne entière change), W2.3 et W1.x restent verts. X-RESULTAT rougit W5.1 et W5.2 mais pas W6.3 (la sonde lit la réponse déjà arrondie). X-FIL-404 : W3.1 reste vert (le Worker est construit), W3.2 à W3.4 et W4.1 rouges, W7.3 vert.
- X-FUITE / X-INTERROMPU : classe cible rouge, l'autre classe verte (la classe « froid » peut s'y ajouter selon la charge ; non exigée).
- `vf-cockpit-module.mjs` (empreinte du module) ne couvre pas `elk-fil.js` : interdit par le plan (modules du serveur), à proposer : ajouter `^elk-fil\.js$` à `MOTIFS_MOTEUR`.
- Gate-Touche : non requis (rien sous plugin/conductor, scripts/check-*.sh, ci.yml, hook, fixtures surveillées).

## Mesures (poste chargé, load average 20 à 140)
- Calcul de 90 cartes : en ligne ~2 s (0,7 à 2,6 s), dans le worker de 2 s à 35 s sous forte charge (thread de worker moins prioritaire). Écart de pouls en mode worker : 1,7 s sous load 100 avec tâche longue < 110 ms (W4.1 rouge sous charge extrême, vert sous load 20) : jouer W4 sur un poste calme.
- Suite : 361 s sous load 20 à 100 (4 graines de graphes et de suites, 8 mutants, X-M7 qui rejoue l'accessibilité deux fois) ; à inscrire dans `scripts/ci-shard-suites.sh` après la première mesure CI.

## Limites
- Aucun garde-temps du calcul ; avertissement de repli visible en console seulement ; paquet ELK chargé deux fois (fil principal pour le repli, worker pour le calcul : proposition 79-18-c, charge à la demande, BACKLOG) ; fixture dépendante de la vitesse du poste (fenêtre mesurée, témoin W0.4) ; un démarrage d'onglet en échec avant `ready` laisse le worker de cet onglet vivant jusqu'au prochain changement réussi (le rappel de `surOnglet` ne part qu'à `pret`).

## Pour 79-20 (README, CHANGELOG du module)
CSP : `worker-src` au préfixe du module et CSP propre du worker (README l. 36) ; fichier `elk-fil.js` ; repli en ligne et avertissement ; paquet ELK chargé deux fois ; export sans worker ; compteur 231.
## Pour la Phase 80
Un worker par onglet affiché, créé en avance et terminé par `surOnglet` : rien à connaître. Contrat inchangé : `window.VibeFlow` (mêmes 56 clés), `render` émis après la pose de `state.layout`.

## Suites jouées
Voir le rapport de mission ; rouges de base ou sans rapport relevés : T24F4.1 de transcript (2074 ms pour 2000, charge), M-ECOUTEURS et M-HEAD de coquille (classe `balises` en plus, à relire), V4 et V4c.9a de vendor (transitoires : fichiers d autres nœuds en chantier pendant le rejeu, verts au contrôle direct).
