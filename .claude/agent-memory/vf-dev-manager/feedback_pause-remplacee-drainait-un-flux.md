---
name: pause-remplacee-drainait-un-flux
description: Remplacer une pause fixe par l'attente du premier signe peut casser un test : la pause laissait aussi FINIR un flux en transit (R1.3, 2 runs CI rouges)
metadata:
  type: feedback
---

Avant d'accepter qu'une `pause(N)` devienne une attente positive, exiger du codeur qu'il dise si la pause laissait aussi
s'écouler un flux (réponses en transit, octets dans un PTY, un tube, des tampons Node). Si oui, l'attente doit porter sur la
FIN du flux (compte exact ou sentinelle par le même chemin), jamais sur son premier octet, ni sur une stabilisation (un
trou de transit dépasse le pas sur une machine lente).

**Why:** mission sondes-stables (2026-11-08) : e8a2d83e a remplacé la `pause(1200)` de R1.2 (terminal-xterm) par l'attente
du premier octet ; la queue des 60 000 réponses vives arrivait après la mesure → R1.3 rouge deux runs CI de suite, deux
hypothèses fausses (trou de 150 ms, xterm `handleUserInput`), un arbitrage Samuel pris sur la mauvaise prémisse. La
signature tranchait : flux commençant par `1R` (fin de réponse) = reliquat, pas fuite (une vraie fuite commence par la
frappe). Leçon versée dans l'en-tête de `chrome-session.mjs` (03d2c5cc).

**How to apply:** sur tout rouge CI d'une sonde que la mission vient de toucher, faire d'abord la bissection contre le SHA
de base (région + montage + ce qui précède dans la même session) avant toute hypothèse produit ; lire les premiers octets
de l'obtenu. Voir aussi [[preexistant-mesure-contre-la-mauvaise-ancre]].
