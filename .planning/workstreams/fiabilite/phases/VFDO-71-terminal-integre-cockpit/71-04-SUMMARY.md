---
phase: 71
plan: 04
status: passed
requirements: [TERM-08, TERM-11]
commits:
  tests: fa74371e
  trace: 48c6a3b3
  code: c3eb9be0
---

# 71-04 — session du terminal : une seule, grâce, tampon, inactivité, rien sur disque

`vf-cockpit-terminal-session.mjs` (119 lignes) porte le cycle de vie complet : propriétaire d'onglet (409 sur `/flux`, `/entree`, `/taille`),
grâce de 30 s au flux fermé (`GRACE_MS`, réglage de test `VF_COCKPIT_TERM_GRACE_MS` de 100 à 30000), tampon de reprise de 256 Kio en mémoire
(`TAMPON_MAX`) rejoué avant le direct, échéance = EOF à l'assistant (SIGHUP au groupe), fin du shell rapportée (`/etat`), tampon vidé à la fin,
`occupe()` lu par la garde d'inactivité de `serve.mjs`. Aucun octet du terminal n'est écrit ni journalisé.

Trace du rouge : `71-04-RED-TRACE.md`. Vert : `test-cockpit-terminal-session.sh` `Résultats : 29 PASS / 0 FAIL` (65 s) ;
`test-cockpit-terminal-activation.sh` `40 PASS / 0 FAIL`.

## Preuves

- Rouge puis vert : T12.2, T12.3 (x2), T12.7 (x2), M-GRACE0, M-TAMPON (sept témoins rouges de la trace).
- Verts dès la base de 71-01, prouvés par mutant : T12.1/M-UNIQUE, T12.6/M-PROPRIO, T15.1/M-JOURNAL, T12.5/M-IDLE ; T12.8 et T15.2 verts sur la base
  (T15.2 n'est discriminant qu'avec M-TAMPON, rouge après la tâche 2).
- Les six mutants rougissent sur le code (aucun « mutant sans effet »).
- Gates : `check-machine-paths.sh`, `check-file-size.sh --all`, `check-python-isolation.sh` : exit 0.

## Écarts et constats

- **Rouges annoncés par le plan non obtenus** : T12.1, T12.8 (et T15.2) sont verts sur la base, car 71-01 livrait déjà propriétaire d'onglet et lecture
  de `FIN`. La commande `verify` de la tâche 1 (T12.1 et T12.8 en FAIL) ne peut donc pas répondre `OK-ROUGE-ATTENDU` ; les sept rouges réels sont tracés.
- **Validation de l'onglet laissée à `[A-Za-z0-9_-]{1,64}`** (plan : 32 hexadécimaux -> 400) : `test-cockpit-terminal-activation.sh` (71-01, hors liste)
  utilise `onglet-test-1` et `onglet-pose` et doit rester verte. Le client de 71-05/71-06 génère 32 hexadécimaux ; durcir est un mandat d'un plan
  qui touche aussi la suite d'activation.
- **Identifiant d'onglet dans le `sessionStorage` de Q (P71-D-21 / O4 côté client)** : hors de ce plan (aucun fichier client dans `files_modified`) ;
  ce plan ne livre que le côté serveur.
- La fin d'une session attend la fermeture de stdout ET stderr de l'assistant (le code est lu avant), avec un filet de 2 s après `exit` : sans cela
  les deux tubes pouvaient se départager et rapporter `code: null`.
- Suites : `test-cockpit-terminal-session.sh` annonce ~90 s, mesuré 65 s (T12.5 mené en parallèle des autres sondes).

## Branchements à recenser pour le merge

Aucun (module de la phase). `Gate-Touche` non requis.
