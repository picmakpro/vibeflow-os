# 72-14 — Trace du rouge (valeur fixe `proposition` côté P)

## Contrôle d'entrée

- Base : `origin/main` = 57e7957f0e0e59d31eacd9562aa80ed0c12226d2 ; `git merge-base --is-ancestor 078e58da HEAD` : oui (clôture 71 présente). Module cockpit `VERSION` : v1.3.3. Tiroir : `vf-cockpit-terminal-tiroir.mjs`, ligne 51 et 56 posent `z.style.bottom` (inversion de la pastille, la pastille est sous `#zoom`). Le tiroir mesure 215 lignes.
- Émetteur de Q (72-08) : clé `K` = `proposition` dans la table `MESSAGES` du client (`vf-cockpit-terminal-client.mjs` ligne 10) ; appel `emettre('proposition')` ligne 73 (`if (nouveau) emettre('proposition'); // garde:emission`).
- Cas froid : le sondage `lire(); setInterval(lire, PROPOSITION_MS)` est posé ligne 91, AVANT `Promise.all([polices, visible()]).then(demarrer)` (ligne 278). Donc, une fois la page de Q chargée et son cadre encadré, le message PEUT partir même si le cadre est de taille nulle. Verdict : « froid : le message peut partir », sous la condition que le cadre de Q existe. Reste le cas où P n'a jamais créé le cadre (tiroir jamais ouvert, pas d'amorçage) : l'écouteur de P exige `cadre` non nul (`if (!cadre || !accepte(...))`), et sans cadre Q n'est pas chargée : aucune proposition ne peut s'annoncer. Remontée au manager : seul le cas « cadre pas encore créé » reste non couvert (le plan ne le contourne pas : aucun canal P vers Q).
