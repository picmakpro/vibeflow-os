---
phase: 67-cockpit-floorplan-socle-partage
plan: 05
status: complete
requirements: [CKPT-07, CKPT-06]
commits: [5a09548d, 233c05ad]
actuals:
  tasks: 3
---

# 67-05 SUMMARY — questions, modèle de l'agent, onglet Code

Exécution inline. Les tâches 1 et 2 (questions, modèle) partagent `serve.mjs`, `vf-cockpit-server.mjs` et la suite : un seul commit (5a09548d) ; la tâche 3 (onglet Code) a le sien (233c05ad).

## Livré
- `vf-cockpit-agent.mjs` : `ARGS_CONFINEMENT` = la « Combinaison retenue » de 67-MESURE-claude-p.md, `resoudreModele` (sélecteur > `VF_COCKPIT_MODEL` > `sonnet`, liste fermée), `argsAgent` (retire `--tools`, `--allowedTools`, `--permission-mode`, `--model` de l'amont, garde les arguments de sortie et de schéma, ajoute la combinaison puis `--model`).
- `vf-cockpit-ask.mjs` / `vf-cockpit-query.mjs` (promus du spike 005) ; « phase N » résolue par le champ `num` : deux compartiments à « Phase 1 » → réponse locale qui les liste avec leur compartiment ; un compartiment nommé dans la question lève l'ambiguïté.
- Crochets `vibeflow P14` dans `serve.mjs` (5 lignes : moteur fixé à Claude Code, `avantQuestion`, `modes`, `argsAgent`), `GET /api/vf/modeles`, `75-vf-modele.js` (sélecteur, clé `vibeflow-cockpit:modele:<lab>`, enveloppe de `fetch` limitée à `/api/ask`).
- Onglet Code : `vf-cockpit-code-vf.mjs` choisi sur présence de `plugin/*/module.json`, nature d'un module lue dans son `type` (aucune table de noms).
- Contrôle visuel (playwright) sur l'arbre réel : sélecteur « sonnet (défaut) » présent, 0 erreur console, panneau « Au travail » à règle de fraîcheur nommée, révélation à la demande dans la ligne cliquée (0 révélée avant le clic).

## argv consigné par le faux claude (Q2), comparé à la mesure
```
["-p","--output-format","stream-json","--verbose","--json-schema","{…","--append-system-prompt","Tu réponds à des questions sur l'ava…","--permission-mode","dontAsk","--tools","Read,Grep,Glob,Bash","--allowedTools","Bash(node .vibeflow/cockpit/query.mjs:*)","Bash(node .vibeflow/cockpit/vf-cockpit-…","Read(./**)","Grep(./**)","Glob(./**)","--model","sonnet"]
```
Sous-suite contiguë identique, élément par élément, aux 10 éléments de la section `## Combinaison retenue` (Q2.2, Q11.2 : `cmp -s` sur deux fichiers).

## Écarts au plan
- Le sélecteur de modèle n'est pas stocké tant que la personne n'a rien choisi ; l'export est identique avant et après un choix, hors horodatage `exported.at` (Q6.2 neutralise cet horodatage avec un `sed`).
- Le hook `avantQuestion` passe avant le contrôle « CLI absente » : une forme courante de l'onglet Projet reste répondue sans `claude`.
- Le message d'avertissement de variable hors liste passe par le `log` de P13 (cat `warn`), imprimé une fois au démarrage.
- Q9 : `vf-cockpit-query.mjs` lancé depuis la racine du lab, comme le fait l'agent.

## Mutants (sortie rouge)
### `--permission-mode` retiré de ARGS_CONFINEMENT
```
  ❌ FAIL — Q2.2 — l'argv contient la combinaison attendue, contiguë et dans l'ordre
  ❌ FAIL — Q2.3 — mode de permission explicite, aucun Bash nu
  ❌ FAIL — Q3.2 — même combinaison de confinement
  ❌ FAIL — Q11.2 — ARGS_CONFINEMENT = Combinaison retenue, élément par élément et dans l'ordre
  Résultats : 39 PASS / 4 FAIL
```
### deux éléments permutés (`Read(./**)` / `Grep(./**)`)
```
  ❌ FAIL — Q2.2 ...   ❌ FAIL — Q3.2 ...   ❌ FAIL — Q11.2 ...
  Résultats : 40 PASS / 3 FAIL
```
### préséance inversée (variable avant sélecteur)
```
  ❌ FAIL — Q4.3 — sélecteur opus > variable haiku : --model opus
     attendu: [--model opus]
     obtenu:  [--model haiku]
  ❌ FAIL — Q4.4 — hors liste : failure modele_refuse
  ❌ FAIL — Q4.5 — le faux claude n'a pas été lancé pour le refus
  Résultats : 40 PASS / 3 FAIL
```
### validation de liste retirée
```
  ❌ FAIL — Q4.4 — hors liste : failure modele_refuse
     attendu: [modele_refuse]
     obtenu:  []
  ❌ FAIL — Q4.5 — le faux claude n'a pas été lancé pour le refus
     attendu: [2]
     obtenu:  [3]
  Résultats : 41 PASS / 2 FAIL
```
### question passée à un shell (copie de `serve.mjs`)
```
  ❌ FAIL — Q5.2 — aucun fichier PWNED* (lab, dossier de travail, suite)
     attendu: [0]
     obtenu:  [6]
  Résultats : 37 PASS / 6 FAIL
```
### moteur non fixé (repli sur les autres CLI)
```
  ❌ FAIL — Q7.1 — sans claude : failure nommé cli_missing
     attendu: [cli_missing]
     obtenu:  [cli_error]
  ❌ FAIL — Q7.2 — le faux codex n'a jamais été lancé par le serveur (1 appel : le témoin)
     attendu: [1]
     obtenu:  [3]
  Résultats : 41 PASS / 2 FAIL
```

## Onglet Code sur l'arbre réel (tâche 3)
`node plugin/cockpit/scripts/vf-cockpit-build.mjs .` : 2,8 s, `meta.vfCodeExtractor` = `vibeflow`, **1 301 liens** (1 241 `call`, 60 `import`), 80 nœuds, 600 fichiers (repère du spike : 1 244 avec l'extracteur, 7 sans). `git status --porcelain --untracked-files=all` avant et après : identique (comparé par `comm -3`). Discrimination : C1.8, même lab assemblé en `vibeflow` (3 liens) puis en `brut` (0).

## Vert final
Suites : who 33, projet 25, vendor 72, assemblage 39, marque blanche 21, direct 27, serveur 36, réseau 13, questions 43, onglet Code 12 ; 0 FAIL. `synchro.sh verifier` 0, `check-version-sync.sh` ✓ (134 suites), `check-machine-paths.sh` ✓, `check-file-size.sh` ✓. STATE.md identique à la baseline.
