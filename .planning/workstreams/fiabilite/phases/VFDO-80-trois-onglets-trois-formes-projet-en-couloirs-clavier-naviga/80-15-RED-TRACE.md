# 80-15 — trace rouge (P80-D-25)

Base : `60-vf-aide.js` absent (fichier écarté le temps de la mesure). `test-cockpit-aide.sh` : 3 PASS / 15 FAIL.

```
  ✅ PASS — AI0 — serveur du lab démarré
  ❌ FAIL — AI1.1 — Code : dialog modal nommé, titre « Raccourcis clavier » (tabindex -1, focus dessus), « Vue : Code », groupes Partout et La carte seuls
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI1.2 — chaque rangée est une entrée du registre (Code, Projet), rien de plus ; Entrée et Espace ; C ; ni « bureau » ni « téléphone »
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI1.3 — Échap ferme l'aide, le focus revient à l'élément d'avant, aucune entrée dans la pile, même fenêtre
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI1.4 — sans --terminal, Code, Projet, Équipe : une rangée « Partout » au texte du registre, sans kbd ; 0 requête, aucun nœud du terminal créé
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI1.5 — /_vf/ui/60-vf-aide.js rend 200 avec VF_AIDE, la page l'a chargé, window.VF_AIDE est un objet
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.1 — la palette (« > ») liste « Afficher les raccourcis » ; Entrée ouvre l'aide (focus sur le titre) ; chaque action de la palette est une rangée
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.2 — « ? » dans un TEXTAREA : tapé, aide fermée ; ⌘? et Ctrl+? : rien
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.3 — 30 Tab : focus toujours dans la boîte ; header et #stage inertes pendant, plus après
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.4 — 1024 × 768 : pas de débordement, hauteur ≤ 80 %, défilement interne, deux colonnes ; 390 px : une colonne, pas de débordement
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.5 — chaque touche du registre de Code produit son effet (+, -, F, C, P, G, Retour arrière, ?)
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.6 — mouvement réduit : aucune animation active à l'ouverture ni à la fermeture
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI2.7 — deux allers-retours : un écouteur, une aide, « Vue : Projet » ; sur Équipe Échap ferme l'aide puis revient à la page (pile vide, non pris)
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ❌ FAIL — AI9 — témoin : aucune section du pilote n'a échoué
     obtenu:  [mesure indisponible : échéance globale dépassée (600000 ms)]
  ✅ PASS — AI0t — serveur du lab --terminal démarré
  ❌ FAIL — AI1.4t — avec --terminal : même rangée au même texte, sans kbd, 0 requête, aucun nœud créé par l'aide
     obtenu:  []
  ❌ FAIL — AI9t — témoin : aucune section du pilote n'a échoué (--terminal)
     obtenu:  [ai14t attente de « aide ouverte » dépassée (90000 ms)]
  ✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
  Résultats : 3 PASS / 15 FAIL
```

AI1.1 à AI1.5 et AI2.1 à AI2.7 rouges : le pilote n'obtient jamais l'aide (« ? » ne fait rien), échéance globale du pilote dépassée en mode base, attente de l'aide dépassée en mode --terminal.
