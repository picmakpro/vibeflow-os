# 80-01 — RED-TRACE : témoins rouges sur la base, puis mutants

Base = module sans `04-vf-clavier-canevas.js` (copie du moteur dans un dossier temporaire, `CC_SCRIPTS`), pilote et suite identiques à la version verte.
Commande : `CC_SCRIPTS=<copie sans le module> bash plugin/cockpit/scripts/tests/test-cockpit-clavier-canevas.sh` (Chrome sans tête, vraies touches).
Chaque rouge est pour la bonne raison : le pilote tourne jusqu'au bout (CC9 vert : aucune section en erreur) et rend des valeurs, jamais un fixture mort.
Résultat sur la base : 4 PASS (dont CC5.1, témoin de non-régression : Équipe n'a aucune carte focalisable, vert avant comme après) / les autres FAIL, trace ci-dessous (`attendu` / `obtenu`).
Les lignes « mutation impossible » de la fin sont normales sur la base (le fichier à muter n'existe pas).

## Trace du rouge (base)

```
  ❌ FAIL — CC1.1 — le parcours Tab complet ne s'arrête qu'UNE fois dans #svg, sur une carte (le reste de la page garde ses arrêts)
     attendu: [[1,true,true]]
     obtenu:  [[0,false,true]]
  ❌ FAIL — CC1.2 — → : la carte de droite ; ← : retour ; ↓ : la carte dessous (même colonne) ; ↑ : retour ; une seule carte à tabindex=0
     attendu: [[true,true,true,true,true]]
     obtenu:  [[false,true,false,true,false]]
  ❌ FAIL — CC1.3 — #svg est une listbox nommée « Carte : <niveau>, N cartes »
     attendu: [["listbox",true]]
     obtenu:  [[null,false]]
  ❌ FAIL — CC2.1a — chaque carte est une option, N = nombre de cartes, la listbox est nommée avec N, ses enfants sont des options
     attendu: [[true,true,true,true]]
     obtenu:  []
  ❌ FAIL — CC2.1b — posinset et setsize cohérents, nom = titre puis liaisons (« reliée à N carte(s) » ou « aucune liaison »), ordre de lecture
     attendu: [[true,true,true,true]]
     obtenu:  []
  ❌ FAIL — CC2.1c — liaisons exactes (D relié à B, C, E ; Util à B et C ; F à personne) ; arêtes, ports et fond cachés (aria-hidden)
     attendu: [true,true,true|true,true,true]
     obtenu:  [false,false,false|,,]
  ❌ FAIL — CC2.1d — T-80-01 : un titre « <img …onerror=… > » du lab est lu tel quel dans le nom, sans img créé ni code exécuté
     attendu: [[0,true,1]]
     obtenu:  [[0,true,0]]
  ❌ FAIL — CC2.1e — Projet : le mot d'état de la pastille se lit dans le nom (une carte au moins examinée, aucun écart)
     attendu: [[true,0]]
     obtenu:  [[true,1]]
  ❌ FAIL — CC2.2 — Fin : dernière carte en ordre de lecture ; Origine : première ; ↓ au bas, ↑ et ← au haut ne bougent pas (aucune boucle)
     attendu: [[true,true,true,1]]
     obtenu:  [[false,false,true,1]]
  ❌ FAIL — CC3.1 — panneau latéral : la sélection suit le focus ; Échap désélectionne (focus resté) ; Espace resélectionne
     attendu: [[[true,1],[null,true,0],[true,1]]]
     obtenu:  [[[false,0],["n:unassigned",true,0],[false,0]]]
  ❌ FAIL — CC3.2 — Entrée plonge, focus sur la première carte AU rendu du niveau ; Échap remonte, focus sur la carte quittée, jamais body
     attendu: [[true,true,true,"root",true,"g"]]
     obtenu:  [[true,false,false,"root",true,"body"]]
  ❌ FAIL — CC3.3 — un redessin recrée les cartes : le focus est sur la même carte, une seule à tabindex=0
     attendu: [[true,1]]
     obtenu:  [[false,0]]
  ❌ FAIL — CC3.4 — tiroir Git ouvert : la carte focalisée est ramenée hors de lui (rectangles disjoints), zoom inchangé
     attendu: [[true,true,true]]
     obtenu:  [[false,true,true]]
  ❌ FAIL — CC3.5 (Backspace) — niveau sans carte : focus sur #stage (tabindex=-1), jamais body, région live ; au retour, la carte quittée
     attendu: [["n:m-vide",true,"-1",true,"Nothing inside.",["root","n:m-vide","g"]]]
     obtenu:  [[null,false,null,false,"Nothing inside.",["root",null,"body"]]]
  ❌ FAIL — CC3.5 (Escape) — niveau sans carte : focus sur #stage (tabindex=-1), jamais body, région live ; au retour, la carte quittée
     attendu: [["n:m-vide",true,"-1",true,"Nothing inside.",["root","n:m-vide","g"]]]
     obtenu:  [[null,false,null,false,"Nothing inside.",["root",null,"body"]]]
  ❌ FAIL — CC4.1 (tactile) — la flèche ne sélectionne pas, Espace sélectionne et ouvre la feuille, Entrée plonge
     attendu: [[true,[true,null],[true,false],"n:m-mod"]]
     obtenu:  [[true,[false,null],[true,true],"root"]]
  ❌ FAIL — CC4.1 (moyen) — la flèche ne sélectionne pas, Espace sélectionne et ouvre la feuille, Entrée plonge
     attendu: [[true,[true,null],[true,false],"n:m-mod"]]
     obtenu:  [[true,[false,null],[true,true],"root"]]
  ✅ PASS — CC5.1 — equipe.html : des cartes (témoin), aucun tabindex (cartes, #svg, #stage), aucun role=option, pas de listbox
  ❌ FAIL — CC6.1 (sombre) — anneau de 2 px de la couleur de --ring sur la .card, pas sur le g, sans l'anneau doux de .sel
     attendu: [["2px","solid",true,"none",true]]
     obtenu:  [["3px","none",false,"none",true]]
  ❌ FAIL — CC6.1 (clair) — anneau de 2 px de la couleur de --ring sur la .card, pas sur le g, sans l'anneau doux de .sel
     attendu: [["2px","solid",true,"none",true]]
     obtenu:  [["3px","none",false,"none",true]]
  ❌ FAIL — CC6.1c — après un simple clic : focus sur la carte mais aucun contour (anneau réservé au clavier) ; les flèches marchent ensuite
     attendu: [[true,0,true]]
     obtenu:  [[false,0,false]]
  ❌ FAIL — CC6.2 — mouvement réduit : aucune animation active après flèche, plongée et remontée ; focus posé au rendu
     attendu: [[0,0,0,true,"root"]]
     obtenu:  [[0,0,0,false,"root"]]
     attendu: [[false,1]]
     obtenu:  []
     attendu: [[null,1]]
     obtenu:  []
     attendu: [[true,1]]
     obtenu:  []
     attendu: [[false,"root"]]
     obtenu:  []
```

Lecture : CC1.1 obtenu [0,false,true] (aucun arrêt de Tab sur une carte du canevas) ; CC1.2 aucune flèche ne change de carte ; CC1.3 aucun rôle ; CC2.1 aucun nom ;
CC3.2/CC3.5 focus sur `body` après la plongée, la remontée et le niveau sans carte ; CC3.3 focus perdu au redessin ; CC6.1 contour de 3 px de style `none` (aucun anneau sur la .card).

## Rouge intermédiaire X4 (tâche 3)

Sans l'extension de `ANNEAU` (mesure sur la .card), `test-cockpit-accessibilite.sh` : l'arrêt du canevas (un `g.node` focalisé) porte son anneau sur sa `.card`, jamais sur le `g` :
X4.1 (code) listait l'arrêt sans anneau. L'extension de `ANNEAU` (`a.matches('g.node')` : signature lue sur `.card`) le rend vert sans toucher une assertion.

## Mutants

Chaque mutant est une copie du module dans `$WORK` (jamais le module), un lab privé, un serveur privé ; une mutation impossible compte comme un échec.

- M-VOISIN-DOM : `voisin()` rend la carte suivante dans l'ordre du DOM. « le mutant rougit CC1.2 (témoin : CC1.1 reste vert) » — ↓ n'atterrit plus dans la même colonne.
- M-REPOSE : rôles et tabindex posés seulement au changement de niveau, pas à chaque `render`. « le mutant rougit CC3.3 (témoin : CC1.1 reste vert) » — après `VibeFlow.render()` aucune carte ne reprend le focus.
- M-EQUIPE : la garde `vfTab === 'equipe'` retirée. « le mutant rougit CC5.1 (témoin : CC1.1 reste vert) » — `#svg` d'Équipe reçoit un `tabindex`.
- M-REPLI-BODY : le repli sur `#stage` retiré. « le mutant rougit CC3.5 (témoin : CC3.2 reste vert) » — niveau sans carte : le focus n'est plus sur `#stage`.

Résultat de la suite finale : 29 PASS / 0 FAIL (dont les quatre mutants).
