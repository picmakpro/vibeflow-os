base: ad870d23c348be5fda25999ae37f01a0af35d4c0

# 74-07 : trace du rouge (suite du Dépôt et du coût, aucun module)

Suite : plugin/cockpit/scripts/tests/test-cockpit-frise-cout.sh, jouée sur la base ci-dessus avant tout module (74-vf-frise-depot*.js, 74-vf-cout*.js absents). Résultat : 13 réussis (témoins positifs : scénarios lus, serveur, absence de commit dans une voie, aucune requête de transcript), 40 échecs, exit 1.

Un FAIL au moins par section : D1:11 D2:1 D3:6 D4:1 D5:1 D5b:3 D6:3 D7:1 D8:2 D9:1 D10:1 D11:2 D12:2 D13:1 D14:4.

D4 : la vraie entrée de la 80 existe déjà sur cette base (`VFGitTiroir.ouvrirSur` dans ui/77-vf-git-tiroir.js, 80-06 fusionnée) : la suite joue contre le tiroir réel, aucun tiroir factice ; seul le bandeau « Dépôt » manque.

## Premières lignes rouges (verbatim)

  ❌ FAIL — D1 — colonne : « Dépôt » puis « 11 commits sur 1 h 30 » (fenêtre écrite)
     obtenu:  [obtenu [null,null] attendu ["Dépôt","11 commits sur 1 h 30"]]
  ❌ FAIL — D1 — une sous-voie par branche, la base d'abord : quatre visibles
     obtenu:  [obtenu [] attendu ["main","feat/a","feat/b","feat/c"]]
  ❌ FAIL — D1 — « + 3 branches » (aria-expanded faux, nom accessible qui commence par le texte visible)
     obtenu:  [obtenu null attendu ["+ 3 branches","false","+ 3 branches : afficher les autres branches du dépôt"]]
  ❌ FAIL — D1 — dernière ligne « Autres commits (branches fusionnées ou sans nom) » comptée, ses deux commits dessinés alors que les branches sont repliées
     obtenu:  [obtenu [null,0] attendu [["Autres commits (branches fusionnées ou sans nom)","2 commits"],2]]
  ❌ FAIL — D1 — chaque commit est un bouton d'au moins 24 x 24, aucune zone de saisie n'en recouvre une autre
     obtenu:  [obtenu [[],false,0] attendu [["BUTTON"],true,0]]
  ❌ FAIL — D1 — nom accessible d'un commit : « Commit 1111111, branche feat/a, 14 h 32. Ouvrir dans le tiroir Git »
     obtenu:  [[]]
  ❌ FAIL — D1 — deux commits proches : un seul bouton, le nombre « 2 », nom accessible qui LISTE les deux (le plus récent d'abord), title identique
     obtenu:  [[]]
  ❌ FAIL — D1 — la couleur résolue du losange est --text-2 et n'est jamais --recent
     obtenu:  [[null,"rgb(63, 63, 63)","rgb(0, 158, 90)"]]
  ❌ FAIL — D1 — « + 3 branches » déplié : sept branches, « Replier les branches », « Autres commits » toujours là
     obtenu:  [obtenu [0,null,null] attendu [7,["Replier les branches","true"],"2 commits"]]
  ❌ FAIL — D1 — ordre : la base, les locales, puis les distantes
     obtenu:  [obtenu [] attendu ["main","feat/a","feat/b","feat/c","feat/d","origin/feat/e","origin/feat/f"]]
  ❌ FAIL — D1 — pointeur grossier : chaque commit mesure au moins 44 x 44, sans recouvrement
     obtenu:  [[null,0]]
  ❌ FAIL — D4 — section interrompue
     obtenu:  [attente de « région du détail » dépassée (8000 ms)]
