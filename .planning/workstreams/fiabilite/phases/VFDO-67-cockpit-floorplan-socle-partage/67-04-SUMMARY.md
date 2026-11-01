---
phase: 67-cockpit-floorplan-socle-partage
plan: 04
status: complete
requirements: [CKPT-05, CKPT-08, CKPT-03]
commits: [6fd4ec61, 0842de46, c7b105da]
actuals:
  tasks: 3
---

# 67-04 SUMMARY — mesure du confinement, serveur unique, dernière commande masquée

Exécution inline plan par plan (le hook d'isolation de `gsd-executor` exige un worktree, contradictoire avec l'arbre unique du mandat : non contourné).

## Mesure de claude -p (tâche 1) — Verdict : CONFINABLE
Claude Code 2.1.316, modèle haiku, 34 appels, détail dans `67-MESURE-claude-p.md`. Un Bash hors liste est refusé partout (tentative + refus observés). Les noms nus `Read`/`Grep`/`Glob` laissent lire un fichier hors racine (V0, V1, V2 : jeton lu) ; seule la liste bornée `(./**)` le refuse. Un `bypassPermissions` utilisateur défait toute la liste sans `--permission-mode` explicite (témoin V4w : fichier créé, secret lu) mais pas avec `dontAsk` (V4b). Combinaison retenue : `--permission-mode dontAsk`, `--tools Read,Grep,Glob,Bash`, `--allowedTools` des deux scripts de requête et `Read/Grep/Glob(./**)`.

## Serveur unique (tâches 2 et 3)
`vf-cockpit-live.mjs` (surveillance récursive, repli par scrutation 2 s, anti-rebond 300 ms, hystérésis 600 ms, filet 5 s), `vf-cockpit-server.mjs` (`attach`, routes `/api/vf/events|etat|doing`, garde interne contre toute clé `doing`), crochet `vibeflow P13` dans `serve.mjs` (10 lignes marquées, 0 marqueur `P7`), segments cachés refusés en 404, client `70-vf-live.js` à `EventSource` relatif, panneau « Au travail » à règle de fraîcheur nommée et bouton de révélation. `synchro.sh verifier` rend 0 ; le diff de `serve.mjs` a été régénéré depuis une version amont reconstruite par inversion du diff du commit précédent (la commande `regenerer-patch` seule échoue quand le fichier a déjà bougé).

## Écarts au plan
- D4 : la corruption dure 450 ms et non 200 (à 200 ms la rafale est absorbée par l'anti-rebond et l'hystérésis n'est jamais exercée) ; témoin D4.3 : une disparition durable est bien crue à la seconde lecture.
- Fixture des tests du direct : trois phases (une cochée, deux ouvertes) : cocher la dernière phase d'un jalon fait naître une carte « history » (donc un `structural`, pas un `patch`).
- S7 exempte `vf-cockpit-interface.json` (le contrat DÉCLARE le schéma de la révélation) ; S7.3 prouve qu'il est identique octet pour octet à celui du module.
- S8 : l'export ne lit que `index.html` (onglet Code) : le témoin de données est un fichier du lab, pas une phase.
- Entre ce plan et 67-05, les questions de l'onglet Projet passent par les arguments amont de `claudeRun` (P7 retiré) : le confinement mesuré n'est câblé que par 67-05.
- `check-python-isolation.sh` non lancé (consigne).

## Mutants (sortie rouge)
### D4 — hystérésis retirée
```
  ❌ FAIL — D4.1 — aucun structural pendant la corruption passagère (3,5 s)
     attendu: [0]
     obtenu:  [2]
  Résultats : 26 PASS / 1 FAIL
```
### D1 — CORS réinjecté sur le flux
```
  ❌ FAIL — D1.5 — aucune réponse (page, page Projet, état, flux) ne porte access-control-allow-origin
     attendu: [0]
     obtenu:  [1]
  Résultats : 26 PASS / 1 FAIL
```
### D5 — variable de scrutation ignorée / scrutation muette
```
  ❌ FAIL — D5.1 — /api/vf/etat rend mode poll
     obtenu:  [{"mode":"watch","seq":0,"derniereMaj":null,"clients":0}]
  Résultats : 26 PASS / 1 FAIL
  ❌ FAIL — D5.2 — en scrutation, le patch nomme la carte de la phase 2
  ❌ FAIL — D5.4 — en scrutation, un PLAN ajouté produit un structural
  Résultats : 24 PASS / 3 FAIL
```
### S5 — `doing` réinjecté dans la collecte, garde interne en place (la garde bloque le flux)
```
  ❌ FAIL — S5.1 — témoin positif : hello liste la session fraîche
  ❌ FAIL — S5.2 — témoin positif : l'événement who liste la seconde session
  Résultats : 33 PASS / 3 FAIL
```
### S5 — `doing` réinjecté ET garde interne retirée
```
  ❌ FAIL — S5.3 — aucune clé doing dans le flux (hello et who)
     attendu: [0]
     obtenu:  [2]
  ❌ FAIL — S5.4 — le texte de la dernière commande n'est pas dans le flux
     attendu: [0]
     obtenu:  [2]
  Résultats : 33 PASS / 3 FAIL
```
(S7.1 rougit aussi dans ces deux mutants, mais pour une raison parasite : le littéral du marqueur figure dans le source muté recopié en sortie. S7 n'est donc prouvé discriminant que par son témoin S7.2.)
### S3 — garde des segments à point retirée
```
  ❌ FAIL — S3.1 — /.cache/server.json : 404 (il porte le jeton)
     attendu: [404]
     obtenu:  [200]
  ❌ FAIL — S3.2 — /.gitignore : 404
  Résultats : 34 PASS / 2 FAIL
```
### R2 — fetch externe réinjecté dans 70-vf-live.js puis réassemblage
```
  ❌ FAIL — R2.1 — page-code : aucune URL hors liste blanche, aucune préconnexion, aucun script externe
     attendu: [0]
     obtenu:  [1]
  Résultats : 10 PASS / 3 FAIL
```
### R1 — https.get externe au démarrage de serve.mjs
```
  ❌ FAIL — R1.5 — page, page Projet, 3 s de flux et état : 0 connexion sortante enregistrée
     attendu: [0]
     obtenu:  [2]
  Résultats : 12 PASS / 1 FAIL
```

## Vert final (SHA c7b105da)
who 33, projet 25, vendor 71, assemblage 39, marque blanche 21, direct 27, serveur 36, réseau 13 : 0 FAIL partout. `synchro.sh verifier` 0, `check-version-sync.sh` ✓ (132 suites), `check-machine-paths.sh` ✓, `check-file-size.sh` ✓, `check-gate-touche.sh` DECLARE. STATE.md identique à la baseline (jamais touché).
