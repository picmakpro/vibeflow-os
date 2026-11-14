AVANT-18 0dc5afa44349576f3a2510f10240949bc0b6cfa6

# 79-18 — trace des rouges (SOCL-22)

## Références de départ (tête AVANT-18)
- viewer.html : 2606 lignes, 281 de plus de 160 colonnes ; `const elk = new ELK();` 1 occurrence ; `new Worker`, `importScripts`, `worker-src` : 0.
- serve.mjs : 675 lignes, 79 longues ; `worker-src` : 0. vf-cockpit-coquille-assets.mjs : 88 lignes, 1 longue.
- Clés de l'objet gelé du moteur (56, relevées à l'ouverture) : copiées dans W6.4.
- Compteur de suites : README = 230, réel = 231 une fois la suite ajoutée.
- `lireAssets` : entrées `entree(nom, classe, texte)` = { nom, classe, texte, octets, etag } ; `servirAsset(req, res, table)` ; la CSP de page est bâtie par `cspDe(hashes, source)`.

## Écart de fixture (mesuré)
Une fixture de 90 notes SANS arêtes se calcule en 30 ms (fenêtre trop courte : W0.4 rouge à juste titre). Quatre imports par module : 50 s de blocage (trop). Deux imports par module (voisin et voisin à 13) : fenêtre de 2,0 s en ligne.

## Rouges sur le code présent (suite jouée avant tout code, tête AVANT-18)
| assertion | attendu | obtenu | raison |
|---|---|---|---|
| W0.4 | fenêtre ≥ 400 ms en ligne puis en worker | ligne, worker aussi « ligne » (2,0 s) | aucun worker : le mode worker est en ligne |
| W1.1 | 200, ETag, no-cache | 404 | `/_vf/elk-fil.js` absent de la table |
| W1.2, W1.3 | CSP propre du worker | CSP de base (`default-src 'none'; frame-ancestors…`) | pas de CSP propre |
| W1.5 | octets égaux au fichier du module | différents | fichier absent |
| W2.1 | une directive `worker-src` par réponse (8) | 0 partout | directive absente |
| W2.2 | chaîne = formule de terminal-aux (8) | différente (8) | la formule a gagné `worker-src`, pas le serveur |
| W3.1, W3.2 | un Worker, une requête répondue | 0 Worker, 0 requête | calcul en ligne |
| W3.4 | 0 calcul en ligne | 2 | calcul sur le fil principal |
| W4.1, W4.2 | écart de pouls < 150 ms, tâche < 200 ms | ≈ 2,1 s, ≈ 2,06 s | fil principal bloqué pendant tout le calcul (durée du blocage mesurée : 2 066 ms pour 90 cartes) |
| W4.3 | clic traité pendant la fenêtre | aucun traitement dans la fenêtre | le clic attend la fin du calcul |
| W6.3 | positions = dernière réponse du worker | pas de réponse | pas de worker |
| W6.4 | clés égales à la liste relevée | (liste vide au moment de l'écriture, puis posée) | liste ajoutée après la première mesure |

Verts d'emblée (témoins) : W0.1 à W0.3, W1.4 (table fermée), W1.6, W2.3, W3.3, W4.0 (la mesure sait rougir : écart en ligne > 400 ms), W6.1, W6.2.
Consommateurs de la formule de CSP rouges aussi (terminal-activation T7/T8, lancer-serveur S3/U2, transcript T26, coquille K3.3) : même cause, la directive absente du serveur.
