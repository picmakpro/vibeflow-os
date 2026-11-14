BASE=ebbbde11a59a066ab4e1af4411ad29b06c13699b

# 76-09 — témoin rouge (module `vf-cockpit-questions-attente.mjs` absent, 2026-11-14)

Rejeu de `test-cockpit-questions-attente.sh` avant tout code : 5 passés, 29 échoués (exit 1). Les assertions rouges disent « obtenu : absent » (champ et module absents, W7). Les lignes vertes sont les témoins négatifs (champ absent sans section, archive contenant bien l entrée, clé de version).

```
❌ FAIL — T13.1a la question en attente est dans meta.vf.questions du vrai graphe — attendu: [P90-Q-01|ph-90|en-attente|a] obtenu: [absent]
❌ FAIL — T13.1b bloque, défauts, ligne et bilan — attendu: [[[{"type":"plan","id":"90-02"},{"type":"phase","n":"91"}],[],5,1,1,false]] obtenu: [absent]
❌ FAIL — T13.2a la question tranchée porte canal, date, option et citation — attendu: [{"canal":"AskUserQuestion session principale","date":"2026-11-11","option":"b","citation":"Texte exact."}|tranchee|1] obtenu: [absent]
❌ FAIL — T13.2b témoin positif : la même entrée en attente redevient en attente — attendu: [en-attente] obtenu: [absent]
❌ FAIL — T13.3b section vide : champ présent, liste vide, registre compté — attendu: [0|1] obtenu: [absent]
❌ FAIL — T13.4 chaque valeur fermée de defauts, mal formée, réduite à id/phase/fichier/ligne/defauts — attendu: [] obtenu: [absent]
❌ FAIL — T13.5 identifiant double : toutes les occurrences mal formées — attendu: [] obtenu: [absent]
❌ FAIL — T13.6 citation incohérente : a-verifier avec ses champs, témoins positifs — attendu: [] obtenu: [absent]
❌ FAIL — T13.7 puce d'un autre format, prose, puce imbriquée : jamais une question — attendu: [] obtenu: [absent]
❌ FAIL — T13.8 section vide, absente, illisible, répétée, bloc de code — attendu: [] obtenu: [absent]
❌ FAIL — T13.9 plus de 200 entrées : coupe, drapeau, frontières — attendu: [] obtenu: [absent]
❌ FAIL — T13.10 aucun chemin du poste, longueurs coupées, témoin positif — attendu: [] obtenu: [absent]
❌ FAIL — T13.11 un titre balisé ressort tel quel, jamais interprété — attendu: [] obtenu: [absent]
❌ FAIL — T13.11b le module ne construit aucun balisage — attendu: [0] obtenu: []
❌ FAIL — T13.17 appliquée : forme canonique, hors recommandation, décision introuvable, défauts univoques — attendu: [] obtenu: [absent]
❌ FAIL — T13.18a archives écartées par la clé joker — attendu: [] obtenu: [absent]
❌ FAIL — T13.18b dans le lab : seule la question du dossier vivant est lue, l'archive est bien présente dans les contextes de la collecte — attendu: [|90,*|80|P90-Q-01|1] obtenu: [|90,*|80|absent|absent]
❌ FAIL — T13.19 l'ordre des champs n'est pas contrôlé — attendu: [] obtenu: [absent]
❌ FAIL — T13.8b registre illisible (chmod 000) : sans erreur, non compté ; le voisin lisible est lu — attendu: [1|1] obtenu: [absent]
❌ FAIL — T13.12a panne injectée dans la copie jetable — attendu: [panne posée] obtenu: [absent]
❌ FAIL — T13.12c témoin positif : sans panne le champ est présent — attendu: [false] obtenu: [true]
❌ FAIL — T13.13a le graphe réel valide ses clés requises et la déclaration de meta.vf.questions — attendu: [OK] obtenu: [KO meta.vf.questions non déclaré | champ absent]
❌ FAIL — T13.13b témoin positif : la même validation rougit sur une clé interdite injectée — attendu: [KO] obtenu: [No]
❌ FAIL — T13.14a P76-Q-01 et P76-Q-02 tranchées (option a), P76-Q-03 appliquée (a, P76-D-31), jamais en attente — attendu: [[["tranchee",{"canal":"AskUserQuestion session principale","date":"2026-11-11","option":"a","citation":"
❌ FAIL — T13.14b bilan : appliquées 1, tranchées 2, en attente 0, non structurées 0 — attendu: [1,2,0,0] obtenu: [absent]
❌ FAIL — T13.14c témoins positifs : sans la ligne Bloque, mal formée ; avec l'état remplacé, en attente — attendu: [[["mal-formee",["champ-manquant"]],"en-attente"]] obtenu: [[null,null]]
❌ FAIL — T13.15a chaque puce de premier niveau est une entrée ou comptée non structurée ; aucune puce hors grammaire en attente — attendu: [] obtenu: [absent]
❌ FAIL — T13.15b le corpus lu atteint au moins 2 fichiers (jamais un vert à vide) — attendu: [oui] obtenu: [non (absent)]
❌ FAIL — anti-vert-à-vide : 34 assertions jouées, 42 attendues
```

T13.1c (libellé de témoin positif mal découpé dans la première écriture) corrigé avant le premier commit ; régime allégé : pas de mutant (rituel levé : régime allégé, consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
