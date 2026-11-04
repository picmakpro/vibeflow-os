# 71-FIX-E — témoin M-CONTREPRESSION indépendant de la charge

Cause : la sonde `sonde_contrepression` laissait au mutant 3,5 s pour produire 40 Mo. Sous charge
(moyenne 20 à 200 sur 12 cœurs), le mutant n'avait pas fini dans la fenêtre, donc `pendant=absent`
comme le code sain : « identique ». CP.1 (code sain) est resté vert à chaque rejeu : aucun défaut de code.

Correctif (témoin seul) : la sonde prend une fenêtre en paramètre.
- CP.1 (sain) : fenêtre 8 s, l'absence du drapeau pendant que le lecteur ne lit pas ; puis le lecteur reprend, attente jusqu'à 60 s.
- M-CONTREPRESSION : fenêtre 90 s, le lecteur reste à l'arrêt ; sortie dès que le drapeau paraît (`pendant=present`), donc rouge sans dépendre de la vitesse.
- `lent.mjs` : garde de sortie portée à pause + 60 s (arrêté par PID de toute façon).

Preuves : avant, 3 rouges sur 5 sous charge (M-CONTREPRESSION identique) ; après, 5/5 verts sous 12 `yes`,
5/5 sous ambiance, M-CONTREPRESSION PASS à chaque fois. Hors périmètre : sous charge extrême (>200),
T12.5 et T12.3 ont échoué une fois chacun (autres sondes à fenêtre fixe), non traités ici.
