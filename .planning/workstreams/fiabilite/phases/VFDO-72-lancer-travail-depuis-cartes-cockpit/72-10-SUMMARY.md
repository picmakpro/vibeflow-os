---
phase: 72
plan: 10
status: complete
requirements: [LANC-04, LANC-05, LANC-06, LANC-07, LANC-09, LANC-10]
commits: [ea718f86, 83f24575, bea79843, 3d3f825b, 549d3bcc]
---

# 72-10 — processus de Q : proposition, armement, lancement

Trace du rouge, du vert, des écarts de nom et des ancres : `72-10-RED-TRACE.md`.

## Commits

- `ea718f86` test : suite `test-cockpit-lancer-processus.sh` (Q0 à Q13, quatre mutants), jouée rouge sur la base (12 PASS / 30 FAIL, Q0 vert)
- `83f24575` docs : trace du rouge
- `bea79843` test : correction de deux défauts de fixture (apostrophes du champ `ligne` en JSON, sonde Q1 sans secret) — aucune assertion affaiblie
- `3d3f825b` feat : `vf-cockpit-terminal-processus.mjs` branché (états de Q, routes, message `lancee`, relais chat)
- `549d3bcc` fix : `GET /proposition` emprunte le contrôle de `GET /etat` (la ligne `navigateur` de la 71 redevient intacte)

## Livrables

- Suite neuve : 42 verdicts (Q0 à Q13, M-ORIGINE-LANCER, M-ID-LIBRE, M-TEXTE-LIGNE, M-RETOUR-CHARIOT, hygiène H0), exit 0 ; parent factice, client et faux `claude` écrits dans la suite.
- Branchement B3 : `vf-cockpit-terminal-processus.mjs` 147 -> 199 lignes (gate de taille : < 300). Imports de l'état de Q et du gabarit ; `lireDemande` (schéma fermé `{ id, mode, chat? }`, `chat` booléen strict) ; `lancer()` (410 sans session, 409 autre onglet, `consommer` -> `sessions.lancer` -> `confirmer` ou `rendre`) ; routes `GET /proposition`, `POST /lancer`, `POST /annuler` dans la table fermée ; `/flux` retient l'onglet propriétaire ; routeur IPC +`cibles` +`proposition` ; objet rendu par `demarrerQ` +2 ; en-tête (contrat IPC, ligne jamais fournie par le client).
- Les trois lignes de contrôle de la 71 (`else if (o !== origineQ())`, `if (!page && !navigateur)`, le 401 `secret`) et la ligne `const navigateur = …` sont inchangées ; `GET /proposition` est contrôlé par le code de `GET /etat` (un seul code).

## Points à retenir pour la suite

- Statuts de `POST /lancer` : 413, 400, 410, 409 (onglet), table de `consommer` (404 / 425 / 409 / 400), table de `sessions.lancer` (409 premier plan, 410, 400, 504), 204. `504` (délai de l'assistant) n'est pas au contrat §4 : le client de 72-08 le traite comme un refus.
- `lancee` n'est émis que par `confirmer`, après `{ ok:true }` de l'écriture ; un 409 « premier plan » restitue la proposition (même `id`), vérifié par Q6.
- Une proposition armée est lue par ce processus UNIQUEMENT par `GET /proposition` ; la page de Q ne porte ni ligne ni UUID (Q9).
- L'armement est réglable par `VF_COCKPIT_LANCER_ARME_MS` (la suite le pose à 2000 ms sur le parent factice, jamais en dur côté assertions : elle lit `arme_apres_ms`).
- Aucun fichier de la vague 1 ni de 72-09 n'est touché ; dépendance non tenue : aucune (la suite ne consomme rien de 72-09, son parent est factice).
- Durée de la suite : environ 2 min 30 s (vrais shells, 5 manches, une attente d'armement par manche).
