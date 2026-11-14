---
phase: 79
plan: "17"
requirements: [SOCL-21]
---

# 79-17 — le magasin d'état de la page, window.VF_ETAT (SOCL-21)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de mutant (X du magasin, EKR, aide du cliquet),
pas de preuve générative (P1 à P6), un seul rejeu de chaque suite nommée. Trace : `79-17-RED-TRACE.md`.

## Livré
- `ui/70-vf-etat.js` (persistant, ~150 lignes) : `window.VF_ETAT` gelé = `CLES`, `lire(cle)`, `abonner(cle, rappel)` (rend la désinscription), `jeton()`, `lireJson(chemin)`, `abonnes()`.
  Huit clés : connexion, etat, frise, git, graphe, lock, planning, who. Alimenté par `window.VF_FLUX.ecouter` et `surConnexion` (porte retenue de `ui/69-vf-flux.js`), jamais par une connexion propre.
  `etat` lu par `/api/vf/state` (une lecture en vol, un rattrapage), `frise` lue à la demande ; `lireJson` n'envoie le jeton qu'à une route `/api/vf/*` de la même origine.
- `ui/70-vf-live.js` : who, lock et connexion lus dans le magasin une fois l'onglet rendu (`surOnglet`), abonnés, désinscription rendue à la coquille ; `vf-who` toujours émis.
- Observateurs retirés : panneau de 70 et de 72 (événement `panel` du moteur : `SC.on('panel', …)`), classe du corps de 76 (`vf-git:etat`). Conservés (aucun événement source) : 00-vf-surcouches, 00-vibeflow, 01, 02-vf-telephone, 03, 05, 41-vf-projet-vue, 42, garde de cadrage de 72, 73, 77-vf-git-tiroir.
- Cliquet `observateurs-cliquet.mjs` + `observateurs-baseline.txt` (25 mesurés, 22 après) ; suite `test-cockpit-magasin.sh` (A, F, L, J, S, K, C, O, R : 90 assertions) ; `magasin-vm.mjs`, `magasin-chrome.mjs`, `reposer-chrome.mjs` ; EKR1, EKR2 (vertes avant et après), EK8.2 et EK9.2 ré-ancrées ; compteur de suites des README : 230 ; `colonnes-baseline.txt` abaissée (70 : 59, 72 : 28).

## Écarts
- Le plan comptait 21 observateurs dans `ui/*.js` ; le relevé réel en trouve 25 (41-vf-projet-vue 2, 42 : 1, 00-vf-surcouches : 1 non listés), 22 après ce plan.
- 71-vf-equipe-rendu.js se charge après 70 : la lecture du magasin se fait dans le rappel de `surOnglet` (pas au chargement du script) ; hors coquille, immédiatement.
- La portée d'onglet de 79-16 retire les propriétés posées sur `window` et sur `<html>` : la preuve d'absence de rechargement de la suite est `performance.timeOrigin`.
- L'onglet Équipe recharge la page si le `who` porte un agent inconnu de ses cartes (comportement de 72) : la sonde C pose la clé de sessionStorage dans l'avenir.
- Première ligne du magasin `// VibeFlow (79-17 …` (marqueur d'inventaire des extensions) : le contrôle « zéro occurrence de VibeFlow » du plan ne s'applique pas.
- Aides de test : lignes de plus de 160 colonnes non réduites (magasin-vm 22, magasin-chrome 15, reposer-chrome 9, suite 36 ; hors périmètre du cliquet des colonnes) ; mutants X, EKR, O3 et preuve P non écrits (rituel levé).
- Un seul commit pour les tâches 1 et 2 (455da5e8) ; correctifs 1e6df69a (70 sous 299 lignes, `on` des faux moteurs, suite git-entete : le titre est recalculé par `vf-git:etat`).
- Rouges de base, non à moi : V4 (chrome-coin.mjs), `robustesse` W1/W1b/W2 (mêmes 3 rouges sur d4595a5c), `git-entete` (mêmes 17 rouges sur d4595a5c) ; colonnes-baseline : hausses de x22 et fx16 (collecte, routes, tiroir.js).

## Suites jouées (une fois, sur la tête commitée)
magasin 90/0 (~11 s) ; equipe 217/0 (245 s, tête finale) ; equipe-etats 86/0 ; vendor 251/1 (V4 chrome-coin, base) ; reseau 15/0 (R3.4 réécrite, fermée par le commit suivant 1e6df69a) ; git-signature 47/0 ; direct-coupe 35/0 ; reconnexion 20/0 ; flux-unique 34/0 ; transcript 111/0 ; git-tiroir 0 rouge ; git-e2e 35/0 ; chrome-fr 141/0 ; projet-visite 114/1 (R3.18, presse-papiers, hors de mes fichiers, rouge sous charge : non rejoué, 721 s) ; robustesse 22/3 et git-entete 119/17 : mêmes rouges sur d4595a5c (base).

## Pour 79-20 (documents du module, non touchés ici)
API du magasin et clés ; cycle de vie (persistant, s'abonner une fois l'onglet rendu, rendre la désinscription à `surOnglet`) ; pattern `SC.on('panel', rappel)` ; cliquet des observateurs et sa limite (la citation d'arbitrage d'un relèvement n'est pas gardée par machine) ; lecteurs de `vf-who`, `vf-git:signal` et du jeton non convertis ; durée de `test-cockpit-magasin.sh` (~10 s) à inscrire dans `scripts/ci-shard-suites.sh`.

## Amendements à inscrire au CONTEXT : 79-17-a à 79-17-e (huit clés dont `lock` et `graphe` ; porte du flux ; persistance ; `lireJson` ; cliquet).
