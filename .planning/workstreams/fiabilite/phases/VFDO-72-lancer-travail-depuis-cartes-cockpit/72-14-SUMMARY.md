# 72-14 — SUMMARY (valeur fixe `proposition`, côté P)

Statut : exécuté. Trace du rouge : `72-14-RED-TRACE.md`.

## Commits
- 6ad1bc0b — docs(72-14) : contrôle d'entrée (base v1.3.3)
- f9607584 — test(72-14) : groupe TP (TP.1 à TP.12, quatre mutants)
- 011483c1 — docs(72-14) : trace du rouge
- 11ba668f — feat(72-14) : tiroir, valeur fixe `proposition`

## Relevés de la tâche 0
- Clé `K` = `proposition`, table `MESSAGES` du client de Q (ligne 10), émission `emettre('proposition')` ligne 73.
- Cas froid : le sondage de proposition est posé (ligne 91) AVANT `Promise.all([polices, visible()])` (ligne 278) : le message peut partir même cadre de taille nulle. Cas remonté au manager (voir `72-14-RED-TRACE.md`, § Contrôle d'entrée) : cadre de Q absent après un rechargement sans fragment `#t=`, donc proposition invisible. Il sera corrigé par un mandat ciblé du manager (décision du manager du 2026-11-06 : un POST accepté rend la proposition visible).

## Réalisé
- `LISTE_MESSAGES` : neuf valeurs, `proposition` en neuvième ; `TEXTES.annonceProposition` ; fonction `proposer` (`ouvrir(false)` puis annonce) ; branche `e.data === 'proposition'` avant la branche des états.
- `accepteMessage` identique à `origin/main` (cksum égal), fichier de style sans diff, script servi `0/1/0/vivant`.
- Suite du tiroir : 75 PASS / 0 FAIL, mutants TP.9 à TP.12 rouges pour la bonne raison.
