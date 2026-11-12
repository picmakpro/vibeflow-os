# 79-11 — trace des rouges, relevés AVANT et APRÈS

Plan 79-11 (SOCL-15, AUDC-AM5, P79-D-19). Chaque ligne préfixée `AVANT ` est relue par une vérification du plan.

## AVANT (relevé le 2026-11-12, base du plan)

BASE-11: ccece3d8
AVANT périmètre (scripts/*.mjs, lignes AJOUT .js .mjs .css de VENDORED.txt) : fichiers=99 avec-longues=86 total=1719 plus-de-285=3
AVANT mesure par un script jetable hors du dépôt (mesure-jetable.mjs : points de code, CR final retiré) ; remplacé par colonnes-cliquet.mjs dès qu'il existe
AVANT modules vf-cockpit-*.mjs dans scripts/ : 76
AVANT neuf modules (lignes, lignes longues) : lancer-ui 254/47 · terminal-tiroir 262/52 · terminal-tiroir-ui 44/10 · terminal-client 289/51 · terminal-vue 299/84 · lancer-style 12/3 · terminal-style 120/22 · terminal-tiroir-style 66/26 · terminal-page 79/10
AVANT lignes contenant la conversion de fonction en chaîne : terminal-page 1 · terminal-tiroir 2 · lancer-ui 3
AVANT lecteurs de VARIABLES_RECOPIEES hors de son module : 0
AVANT lignes AJOUT .css dans VENDORED.txt : 1 (xterm.css, vendeur tiers)

TOTAL-AVANT: 1719

### Pages (releve-pages-terminal.mjs, base)

AVANT q-sombre-html 766513 1cf1ea396fea9a4ae570135ad14ef506afa78f3503fa39f98f7143bcf5b73bdb
AVANT q-sombre-csp 419 66ce5b3b67d12c1065ee035b69ddfba720c9e8395807b38b7adfe9e5c9b0c2b7
AVANT q-clair-html 766534 473a821e29e153c8b60202d89a598e57d423d00a9a545dd8e1fa2b0bdd5aefe8
AVANT q-clair-csp 419 48a6f508293a4391213e679d0c487384790d550055bf32756c0d205516771d70
AVANT p-tiroir 35542 8651b809086579f82873d9b30724cbe2366609836917cf38af8b1e774c88d219
AVANT p-tiroir-indispo 35541 603e3566257f74ce37a5ca520da2178b6be47fb51d742a0af74590a42501e599
AVANT p-lancer 17717 00a33e2cf126cd56422e822f59c1cc2f999270853fecaf1680cb05e4a2368903
AVANT p-lancer-indispo 0 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
AVANT p-lancer-expire 17715 2d362645a6fcf56b4ca223b510445e9ebd72ae0aa40c82d146e1c94709db657f

## Tâche 1 — le cliquet de colonnes

### Rouges sur la base (témoins V4c écrits avant l'aide ; col_juger ne connaît que le plafond de 300 lignes de V4)

Rejeu de test-cockpit-vendor.sh : 96 PASS / 30 FAIL, les 30 sont des témoins V4c, V1 à V10 restent verts. Chaque rouge : libellé, attendu, obtenu.

- V4c.1a — une ligne de 161 points de code, baseline vide : rouge HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.1c' — 161 lettres accentuées : rouge HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.1d' — 161 caractères suivis d'un CR : rouge HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.1e — le rouge nomme le fichier fautif | attendu: [1] | obtenu:  [0]
- V4c.2a' — baseline à 2, réel 3 : HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.2a'' — baseline à 2, réel 1 : PERIMEE (la baseline doit suivre la baisse) | attendu: [rouge PERIMEE] | obtenu:  [ok]
- V4c.2a3 — abaisser réécrit la baseline au réel (code 0) puis le verdict est ok | attendu: [0 ok 1] | obtenu:  [1 ok 0]
- V4c.2b — une entrée pour un fichier hors du périmètre : ORPHELINE | attendu: [rouge ORPHELINE] | obtenu:  [ok]
- V4c.2b' — nombre non entier : FORME | attendu: [rouge FORME] | obtenu:  [ok]
- V4c.2b'' — zéro : FORME (le fichier ne liste que les fichiers à plus de 0) | attendu: [rouge FORME] | obtenu:  [ok]
- V4c.2b3 — chemin absolu : FORME | attendu: [rouge FORME] | obtenu:  [ok]
- V4c.2b4 — segment .. : FORME | attendu: [rouge FORME] | obtenu:  [ok]
- V4c.2b5 — un champ de trop : FORME | attendu: [rouge FORME] | obtenu:  [ok]
- V4c.3 — le marqueur vibeflow:allow-large-file dans les cinq premières lignes n'exempte pas une ligne de 161 : HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.4a — le périmètre de l'aide (sans feuilles) égale la liste de la boucle des 300 lignes (écart en lignes) | attendu: [0] | obtenu:  [98]
- V4c.4b — une ligne AJOUT .css est mesurée : HAUSSE | attendu: [rouge HAUSSE] | obtenu:  [ok]
- V4c.5a — une baisse est acceptée (code 0) | attendu: [0 ] | obtenu:  [1 ]
- V4c.5b — une hausse sans citation : code 1 et HAUSSE-SANS-ARBITRAGE | attendu: [1 HAUSSE-SANS-ARBITRAGE] | obtenu:  [1 ]
- V4c.5b' — la sortie de la hausse nomme le fichier | attendu: [1] | obtenu:  [0]
- V4c.5c — une hausse avec une citation conforme : code 0 | attendu: [0 ] | obtenu:  [1 ]
- V4c.5d — une nouvelle entrée à plus de 0 sans citation : code 1 | attendu: [1 HAUSSE-SANS-ARBITRAGE] | obtenu:  [1 ]
- V4c.5e — une citation sans date : code 1 | attendu: [1 HAUSSE-SANS-ARBITRAGE] | obtenu:  [1 ]
- V4c.5e' — une citation à une seule virgule : code 1 | attendu: [1 HAUSSE-SANS-ARBITRAGE] | obtenu:  [1 ]
- V4c.5f — une citation conforme sans hausse : code 0 | attendu: [0 ] | obtenu:  [1 ]
- V4c.5g — la ligne de délégation ne vaut pas citation d'une hausse : code 1 et HAUSSE-SANS-ARBITRAGE | attendu: [1 HAUSSE-SANS-ARBITRAGE] | obtenu:  [1 ]
- V4c.5g' — la délégation et un arbitrage direct sur deux lignes : code 0 | attendu: [0 ] | obtenu:  [1 ]
- V4c.6a — création, hausse sans citation, baisse : code 1 et le commit de la hausse est nommé | attendu: [1 1] | obtenu:  [1 0]
- V4c.6b — le même historique avec une hausse citée : code 0, trois commits examinés | attendu: [0 commits=3] | obtenu:  [1 commits=3]
- V4c.6c — création seule : code 0, un commit examiné, rien à comparer | attendu: [0 commits=1] | obtenu:  [1 commits=1]
- V4c.6d — une hausse non commitée de la copie de travail est rouge | attendu: [1 1] | obtenu:  [1 0]

### État vert (aide colonnes-cliquet.mjs posée) et mutants de l'aide

Rejeu de test-cockpit-vendor.sh : 141 PASS / 0 FAIL, dont 54 témoins V4c. La baseline du vrai module n'existe pas (créée à la tâche 3) ; V4c.7 examine 0 commit.
Mutants de l'aide (V4c.8, copies jetables, substitution par sed) : chacun a son assertion .0 (la copie change), rougit le témoin qui le vise (verdict inverse de l'attendu sain) et laisse un témoin voisin juste.
- M-OCTETS : 150 lettres accentuées (V4c.1c) : attendu sain ok, obtenu mutant rouge HAUSSE ; voisin V4c.1b ok.
- M-SEUIL : 161 points de code (V4c.1a) : attendu sain rouge HAUSSE, obtenu mutant ok ; voisin 160 ok.
- M-MARQUEUR : 161 sous marqueur (V4c.3) : attendu sain rouge HAUSSE, obtenu mutant ok ; voisin 161 sans marqueur rouge HAUSSE.
- M-CR : 160 plus CR (V4c.1d) : attendu sain ok, obtenu mutant rouge HAUSSE ; voisin 160 ok.
- M-ORPHELINE : entrée orpheline (V4c.2b) : attendu sain rouge ORPHELINE, obtenu mutant ok ; voisin 160 ok.
Fichiers écrits par la tâche (colonnes-cliquet.mjs 113 lignes, releve-pages-terminal.mjs) : 0 ligne longue.

## Tâche 2 — page de Q rangée en fichiers

### Rouges sur la base (V11.Q1 à Q6 ; fichiers et export absents)

Rejeu de test-cockpit-vendor.sh : 142 PASS / 20 FAIL, tous les FAIL sont des témoins V11.Q.

- V11.Q1a — FICHIERS_NAVIGATEUR : les noms du dossier terminal | attendu: [client.js q.css vue.js] | obtenu:  [absent]
- V11.Q1b — les fichiers présents du dossier assets/ui/terminal | attendu: [client.js q.css vue.js] | obtenu:  []
- V11.Q1c — les lignes AJOUT de VENDORED.txt pour le dossier terminal | attendu: [client.js q.css vue.js] | obtenu:  []
- V11.Q2 — pageTerminal (sombre et clair) : feuille q.css, puis vue.js et client.js dans leurs <script> sans attribut, dans l'ordre | attendu: [dark ordre-ok vue=true client=true/light ordre-ok vue=true client=true/] | obtenu:  [node:fs:539/    return binding.readFileUtf8(path, stringToFlags(options.flag));/                   ^//E
- V11.Q3 — client.js muté dans une copie : la page change, la CSP change, la page porte la mutation, la CSP porte l'empreinte du script muté | attendu: [true true true true] | obtenu:  [Node.js v26.5.0]
- V11.Q4a — témoin positif : le fichier intact est lu | attendu: [1] | obtenu:  [0]
- V11.Q4b — une seule fin de ligne est retirée | attendu: [1] | obtenu:  [0]
- V11.Q4c — un nom hors liste est refusé, en nommant le fichier | attendu: [1] | obtenu:  [0]
- V11.Q4d — un dossier hors liste est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4e — un lien symbolique à la place du fichier est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4f — un chemin dont la résolution sort du dossier est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4g — un fichier de 256 Kio plus un octet est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4h — un octet nul est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4i — une fermeture de script dans une fonction est refusée (casse ignorée) | attendu: [1] | obtenu:  [0]
- V11.Q4j — une fermeture de feuille dans une feuille est refusée | attendu: [1] | obtenu:  [0]
- V11.Q4k — un fichier absent est refusé | attendu: [1] | obtenu:  [0]
- V11.Q4l — une feuille intacte est rendue telle quelle | attendu: [1] | obtenu:  [0]
- V11.Q5a — le lecteur et la page de Q : aucune conversion de fonction en chaîne, aucune évaluation dynamique | attendu: [0] | obtenu:  [-99]
- V11.Q6a — fichiersCodeEvalue liste les trois fichiers de Q | attendu: [liste=true] | obtenu:  [liste=false]
- V11.Q6b — l'empreinte est calculée, change d'un octet dans client.js d'une copie, et devient nulle quand client.js manque | attendu: [stable=true octet=true supprime=true] | obtenu:  [node:fs:697]

### Vert de la tâche 2 (2026-11-12) : relevé APRÈS des quatre unités q-*, suites rejouées seules

APRES q-sombre-html 766513 1cf1ea396fea9a4ae570135ad14ef506afa78f3503fa39f98f7143bcf5b73bdb
APRES q-sombre-csp 419 66ce5b3b67d12c1065ee035b69ddfba720c9e8395807b38b7adfe9e5c9b0c2b7
APRES q-clair-html 766534 473a821e29e153c8b60202d89a598e57d423d00a9a545dd8e1fa2b0bdd5aefe8
APRES q-clair-csp 419 48a6f508293a4391213e679d0c487384790d550055bf32756c0d205516771d70

Les quatre lignes APRES q-* sont égales aux quatre lignes AVANT q-* (longueur et sha256). Rejeu de test-cockpit-vendor.sh : 162 PASS / 0 FAIL (V11.Q1 à Q6 verts).

Règle 9 (grep de toutes les suites qui nomment un fichier retiré, chacune rejouée seule, sous TMPDIR du nœud ; aucun « mutant sans effet »).

Fichiers sources retirés cherchés : vf-cockpit-terminal-client, vf-cockpit-terminal-vue, vf-cockpit-terminal-style, vueTerminal, clientTerminal, STYLE_Q, VARIABLES_RECOPIEES. Suites nommant l'un d'eux : terminal-page, terminal-client, terminal-xterm, terminal-tiroir, lancer-chat, lancer-mode, lancer-xss, lancer-bandeau, chrome-fr (plus ci-shard-suites.sh et vf-cockpit-lancer-q.mjs, qui ne citent le client que dans un commentaire).

| suite | code | durée | résultat |
|---|---|---|---|
| terminal-page | 0 | 36 s | 51 PASS / 0 FAIL |
| chrome-fr | 0 | 26s | Résultats : 129 PASS / 0 FAIL |
| lancer-xss | 0 | 197s | Résultats : 76 PASS / 0 FAIL (0 non vérifiées sans navigateur) |
| lancer-chat | 0 | 62s | Résultats : 38 PASS / 0 FAIL |
| lancer-mode | 0 | 193s | Résultats : 113 PASS, 0 FAIL (0 non jouées, dites) |
| terminal-client | 0 | 262s | Résultats : 76 PASS / 0 FAIL |
| lancer-bandeau | 0 | 556s | Résultats : 161 PASS / 0 FAIL |
| terminal-xterm | 0 | 941s | Résultats : 81 PASS / 0 FAIL |
| terminal-tiroir | 0 | 1126s | Résultats : 138 PASS / 0 FAIL |

Mutants des suites visant le code déplacé : retargetés vers client.js, vue.js, q.css (copie du module par cockpit_module_muter, ou copie du moteur réduit passée à pagegen / faux dans lancer-bandeau) ; noms, expressions sed et valeurs attendues inchangés.

### Mesure d'instabilité demandée par la session principale (rejeu isolé, machine chargée par d'autres exécuteurs)

- test-cockpit-terminal-tiroir.sh : 1126 s en un rejeu isolé, 138 PASS (le scénario avec --terminal dépasse 600 s ; CI : 1184 s pour 493 cas).
- test-cockpit-lancer-bandeau.sh : 556 s, 161 PASS, LB.E11 à LB.E14 verts en rejeu isolé (non reproduit ici). Où passe le temps : fixe pause(3500) de LB.E11, attendreValeur à 10 s, et un sondage client dont la décision d'annuler une proposition ancienne ne se prend qu'au PREMIER sondage de la page (client.js, gardes visite/pret : l'annulation n'est envoyée que si le terminal est déjà prêt à ce moment-là). Hypothèse de la forme [true/0/false/false] : sur un poste lent, le premier sondage précède l'état prêt, l'annulation n'est jamais émise et le scénario suivant n'est plus à l'état attendu. Non corrigé (hors plan), aucune sonde affaiblie.
