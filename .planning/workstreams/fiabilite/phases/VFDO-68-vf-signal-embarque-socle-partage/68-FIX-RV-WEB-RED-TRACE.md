# 68-FIX-RV-WEB — traces rouge puis vert (mandat de correction ciblée, 2026-11-04)

Décisions : P68-D-33 à P68-D-38 (R11 et N2 : arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « Tout selon les recos (Recommandé) »).

## T-1 — le 4e argument `lab` de `shBorne` est discriminé (section H de test-cockpit-path-enfants.sh)
- Cas : arbre git posé sous le lab (cwd de l'enfant = l'arbre) et DAG running dans le dossier git commun (cwd = ce dossier), PATH piégé `LAB2/bin` ; piège journalisé.
- Réel : 37 PASS / 0 FAIL.
- ROUGE sur copie mutée (scratchpad) : `vf-cockpit-signal.mjs` sans `lab: root` -> H-lab-absolu FAIL (36/1) ; `vf-cockpit-who.mjs` sans `root` (appels git du DAG) -> FAIL (36/1).
- Premier essai de la mutation signal : VERT à tort, parce que la fixture était sur `master` (base nulle, aucun appel rev-list). Corrigé par `git init -b main` ; le témoin H-témoin vérifie 2 arbres et 1 nœud DAG.
- Écart de socle découvert, non corrigé (hors périmètre, `ask-user`) : `vf-cockpit-planning.mjs:159` lit les tags avec `lab` = la racine de l'arbre lu (`readPlanning(<arbre>)`) ; un arbre sous le lab laisse donc `LAB/bin` dans le PATH de ce `git for-each-ref`. La section H tolère cet unique appel (commentaire dans la suite) ; à retirer avec le correctif.

## S-1, S-2 — documentation
- ROUGE (grep) : README.md « sans verrou vivant, la mission est » = 1 ; CHANGELOG.md « sinon `abandonnee` » = 1 ; interface.json « sinon abandonnee » = 1 ; README « n'exécute jamais un fichier dont le » (fin de ligne) = 1 ; CHANGELOG « n'exécute aucun fichier dont le realpath » = 1.
- VERT : README « Un verrou **présent** » = 1 ; « arrête la cascade » = 1 dans CHANGELOG et interface.json ; l'ancienne phrase README = 0 ; interface.json parse en JSON.

## R11 (web) — statut STATE brut
- Origine : le sous-titre (`resume()` de vf-cockpit-project.mjs, socle) porte `state.status` brut ; la pastille « Maintenant » (00-vibeflow.js) l'affiche via `STATUT`. Correctif côté UI seul : `STATUT` étendu, motif de dernier segment dans 80-vf-fr.js (statuts connus uniquement). Le socle n'est pas touché.
- ROUGE (Chromium propre, copie avec les 3 fichiers UI au HEAD) : F9.1 obtenu `["Jalon v1 · phase 1 (Socle) · ready_to_plan.","ready_to_plan"]`.
- VERT : F9.1 et F9.2 PASS (« … · prête à planifier. », pastille « prête à planifier »), test-cockpit-chrome-fr.sh 29/0.

## N2 (web) — « Verrou depot · 1 s »
- Libellé : ROUGE F10 obtenu `Verrou depot` ; VERT `Verrou dépôt` (70-vf-live.js, libellé seul ; la valeur `tree` reste `depot`).
- Âge (1 s contre 57 s dans l'en-tête) : non corrigé, `ask-user`. Le tiroir lit `ageS` du travailleur `lock` (who.mjs, socle) alors que l'en-tête lit `age_seconds` de la sonde de verrou ; la divergence vient de la source côté socle.
