---
phase: 72
plan: 12
status: complete-with-transfer
requirements: [LANC-05, LANC-07, LANC-09, LANC-10, LANC-12]
commits: [217f1c81, d2b6bb01, 0c164b5f, fdcdde93]
---

# 72-12 — bout en bout du lancement avec un faux `claude`

Trace du rouge sur mutants, du vert, de Chromium et du jalon : `72-12-RED-TRACE.md`.

## Livré
- Tâche 1 : `test-cockpit-lancer-bout-en-bout.sh` (B0 à B9, variante sans navigateur) et `temoins/fauxbin-claude/claude`. Lab partitionné, titre de phase hostile, compartiments hostiles `a$(id)` et `a$(touch pwn-ws)`. argv comparé octet pour octet par `cmp -s`.
- Tâche 2 : `chrome-lancer.mjs` (132 lignes) et la section CH0 à CH9 (clic de confiance précoce ignoré, clic après armement sans Entrée, Entrée au clavier, présélection du mode, Annuler).
- Preuve verte : HEAD `84501819`, exit 0, 54 PASS / 0 FAIL / 0 non vérifiée (Chrome 156).

## Jalon LANC-12
- J2 vert : la découverte de la CI porte les 51 suites du dossier de tests du cockpit.
- J3 vert : 13 suites de la phase, aucune construction non portable.
- J1 (boucle de toutes les suites sur arbre propre) : transféré au nœud de non-régression complète du manager (décision du manager). Relevé partiel sur HEAD `217f1c81` : 9 suites vertes, puis `test-cockpit-lancer-bandeau.sh` rouge sur LB.S3 (client 282 lignes pour un plafond de 280). Ce rouge est attribué aux fichiers de 72-13 en cours d'édition (non commités à ce moment), pas à 72-12.

## Mutants
- M-RETOUR-CHARIOT : B2 attendu 204 / obtenu 400, ligne absente de l'invite, argv absent ; B3 rougit aussi (24 PASS / 18 FAIL).
- M-LISTE-PAGE : B6 attendu 409 409 / obtenu 202 202 ; B9 et B4 rougissent en conséquence (38 PASS / 4 FAIL). Q reste à `aucune` sous le mutant (deuxième barrière).

## Écarts au plan (le code livré fait foi)
1. `lancee` : objet `{ etat, verbe }` ou `false`, pas `true`.
2. Q jouée dans un cadre de P (P71-D-25), pas en premier niveau.
3. L'amorçage lu par la page exige 64 hexadécimaux : la suite génère 32 octets.
4. Le 504 de `POST /lancer` n'est pas joué (hors contrat §4, traité comme un refus par le client).

## Non vérifié
- J1 sur arbre propre (transféré).
- Exécution sous Linux : à lire sur le job de CI de la PR ; le témoin des leurres de B0 n'est mesuré que par `ps eww` sous macOS.
- Vrai `claude` : recette par juges, hors plan.
- Rattachement visible dans l'onglet Équipe : prouvé au niveau de la table par 72-07 et 72-09.
