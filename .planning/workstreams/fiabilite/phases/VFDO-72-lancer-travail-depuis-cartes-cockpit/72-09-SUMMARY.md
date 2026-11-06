---
phase: 72
plan: 09
status: complete
requirements: [LANC-01, LANC-02, LANC-03, LANC-04, LANC-08, LANC-10]
commits: [9c84608e, 20de383e, 6fde1538]
---

# 72-09 — assemblage du lancement côté serveur P

Livré : `vf-cockpit-lancer-canal.mjs` (registre du canal P vers Q), `vf-cockpit-lancer.mjs` (cibles, POST, messages `cibles` puis `proposition`, retour `lancee`), branchements B1 (`vf-cockpit-server.mjs`) et B2 (`vf-cockpit-terminal.mjs`). `serve.mjs`, le moteur vendoré, l'amont et les modules de la vague 1 sont inchangés (blob de `serve.mjs` identique).

Reprise après crash du 2026-11-05 : le travail non commité du codeur précédent a été jugé contre la suite rouge `test-cockpit-lancer-serveur.sh` (73 PASS / 0 FAIL, quatre mutants rouges pour la bonne raison) puis gardé tel quel ; aucune assertion de la suite n'a été touchée.

Écarts avec le plan (consignés dans `72-09-RED-TRACE.md`) : `lancee` rendu en forme riche `{ etat, verbe }` ou `false` ; un point d'entrée `lancer.sourceWho(fn)` (une ligne de B1 en plus) alimente les états du suivi ; clé de refus `refus`.
