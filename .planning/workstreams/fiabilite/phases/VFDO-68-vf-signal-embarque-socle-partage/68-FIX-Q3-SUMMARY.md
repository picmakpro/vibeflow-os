# 68-FIX-Q3 — résumé

- P68-D-33 : `vieDe` prolonge la cascade au verrou de dépôt (entrées `scope: depot`, ancien `.planning/DRIVER.lock` compris ; le vivant l'emporte sur le périmé), pour une mission de compartiment comme pour une mission sans compartiment.
- R13 : `plugin/tsconfig.json` ignoré.
- Audit F-9, F-6, F-5 (lecture seule), F-8 (bidi, âge négatif) corrigés.
- Formes : `signal@1` et `avancement@2` inchangées (clés identiques) ; seule la description de `avancement` dans `vf-cockpit-interface.json` documente la cascade.
- Hors périmètre déclaré, touché : `vf-cockpit-paths.mjs` (`GIT_SUR`), seul point commun à tous les appels git.
- Décision à confirmer (ask-user) : compartiment périmé + dépôt tenu. Conservé : `abandonnee`.
Preuves : `68-FIX-Q3-RED-TRACE.md`.
