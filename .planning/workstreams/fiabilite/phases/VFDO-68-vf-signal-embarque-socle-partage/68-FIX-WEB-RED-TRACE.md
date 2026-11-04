# 68-FIX-WEB — témoins rouges puis verts (écarts de recette R5, R7, R12 de l'UI web)

Arbitrage P68-D-35 : « Tout selon les recos (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-04). R8 reporté en Phase 70, non touché.
Tête de départ `a85f2664`. Mesure : Chrome headless, socle `chrome-session.mjs`, aide `chrome-mission.mjs` (lab à mission abandonnée, thèmes sombre puis clair, fenêtre 1440x900).

## R5 + R7 — carte Mission abandonnée (onglet Projet)

ROUGE (code non corrigé, mesure autonome, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-rouge.json`), sombre et clair identiques :

| assertion | attendu | obtenu |
|---|---|---|
| pastille (texte) | Abandonnée | À faire |
| classe de la pastille | vst vst-abandonnee | vst vst-todo |
| pastille dans la carte (droite <= 689) | true | false (droite 744,2 pour une carte finissant à 689) |
| texte du pied dans la carte | true | true (non rogné, mais il pousse la pastille dehors) |

Capture avant : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-avant/sombre-carte.png` (la pastille n'est plus visible : hors de la carte), `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-avant/clair-carte.png`.

VERT (`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-vert.json`) : pastille « Abandonnée », classe `vst vst-abandonnee` (jeton `--st-todo`, aucune couleur en dur), pied sur deux lignes
(meta 378,8..567,9 ; pastille 576,7..669,2 ; carte 359..689, bas 568,4 pour un pied finissant à 550,8), dedansTexte et dedansPastille true, dans les deux thèmes.
Captures après : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-apres/sombre-carte.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-apres/clair-carte.png`.

Correctif : `00-vibeflow.js` (feuille de style : `.vst-abandonnee`, `.foot .meta { white-space: normal }` ; observateur qui réécrit la pastille d'une carte dont le pied dit « abandonnée »,
libellé écrit par le socle, non modifié).

## R12 — badge de portée du verrou

ROUGE (suite `test-cockpit-responsive.sh` R7.5.2, code non corrigé, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-rouge-suite-sans-conductor.txt`, Code et Projet) :
attendu `true|Personne au travail · dépôt : vf-dev-manager-v2-cockpit (mis`, obtenu `true|Personne au travail · depot : vf-dev-manager-v2-cockpit (mis`.
VERT (`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-vert-suite.txt`) : 198 PASS / 0 FAIL. Correctif : `70-vf-live.js`, libellé seul (la valeur `scope` du JSON reste `depot`).

## Limites honnêtes

- Le rouge de la section R-M DANS la suite, joué sur une copie sans conductor voisin, a échoué pour une autre cause (carte « abandonnée » jamais trouvée, 90 s) : il ne vaut pas témoin. Un rejeu avec le conductor copié à côté
  était en cours (`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/web-fix-rouge-suite.txt`) à la remise ; le témoin rouge R5/R7 retenu est la mesure autonome ci-dessus, sur le code non corrigé.
- Non-régression Chrome complète (projet, chrome-fr, direct, equipe, onglet-code, chaine-xss, securite) NON rejouée ici : laissée au manager (demande de mgr68). Seules `test-cockpit-responsive.sh` (198/0) et `test-cockpit-vendor.sh` (77/0) ont tourné.
