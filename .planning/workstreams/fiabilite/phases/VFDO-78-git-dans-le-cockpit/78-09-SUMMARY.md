---
phase: 78
plan: "09"
requirements: [GITC-11]
status: complete
---
# 78-09 — Signal Git dans le direct (GITC-11, P78-D-15, P78-D-23)

## Livré
- `plugin/cockpit/scripts/vf-cockpit-git-signature.mjs` : `signatureGit(lab, { commun })` (sha256 de `for-each-ref`, `worktree list --porcelain -z`, mtime+taille de l'index commun et de `worktrees/*/index`, par `fs.statSync`) ; `null` hors dépôt ou sur échec. Jamais `log`, `status`, `diff`.
- `vf-cockpit-live.mjs` : signature calculée dans le filet de 5 s existant (`NET_MS`), `emit('git', { seq, at, sig })` au seul changement.
- `70-vf-live.js` : une ligne dans `connecter`, écouteur `git` de l'EventSource existant (aucun nouvel `EventSource` ni intervalle) qui passe par `vu()`.
- `test-cockpit-git-signature.sh` : 27 assertions, 3 mutants. Preuves : `78-09-RED-TRACE.md`.

## Contrat de l'événement relayé à la page (pour 78-06 / 78-10)
- Flux SSE : `event: git`, `data: { seq, at, sig }` (`sig` = 16 hexadécimaux, aucun contenu du dépôt).
- DOM : `document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig } }))`, une fois par événement `git` reçu, sur toutes les pages (Code, Projet, Équipe) qui chargent 70-vf-live.js. La page ne se recharge pas. À l'écoute : relire ses routes ; le tiroir ne doit relire que s'il est ouvert.
- Pas de rejeu : à la reconnexion un `hello` seul, l'écouteur doit relire l'état à l'ouverture.

## Coût mesuré de `signatureGit` (médiane de 7 appels)
- fixture : 29 à 31 ms ; ce dépôt (`/Users/samuel/Documents/dev/vibeflow-os`, nombreux worktrees et refs, lecture seule) : 26 à 29 ms. Sous les 50 ms ; l'essentiel est le lancement des deux processus git (une fois par tick de 5 s).

## Limite assumée
Un fichier suivi modifié sans `git add` ne change aucun élément de la signature (refs, worktrees, index) : aucun événement (R2.1d). Le tiroir relit le status à l'ouverture. Un fichier neuf non ajouté non plus (R2.1b).

## Écarts
- R2.2c : la liste blanche de sous-commandes inclut `rev-parse` en plus de la liste du plan (appelé par les outils du dépôt) ; les options globales de `GIT_SUR` sont écartées avant lecture.
- Reprise : la Tâche 1 (commits 6dec8529, 74990289) rejouée verte avant la Tâche 2.
- `Gate-Touche` : non requis (plan).

## Branchements pour le merge
`vf-cockpit-live.mjs` (1 import, 1 variable, 2 lignes dans le filet, ligne d'en-tête) et `70-vf-live.js` (1 ligne dans `connecter`) : à garder au rebase (Phase 72).

## Valeurs d'espacement
Aucune posée (pas de CSS).
