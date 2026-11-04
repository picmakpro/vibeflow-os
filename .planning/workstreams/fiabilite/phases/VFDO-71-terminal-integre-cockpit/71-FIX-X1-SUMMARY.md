---
phase: 71
plan: FIX-X1
status: passed
requirements: [TERM-02, TERM-08, TERM-10]
---

# 71-FIX-X1 — correction ciblée (lot X1, page du terminal, côté Q)

Arbitrages : P71-D-36 « Tout, R5 après sonde (Recommandé) » et P71-D-37 « G4 hauteur proportionnelle, G5 curseur plus visible »
(AskUserQuestion, session principale Claude Code, 2026-11-04 ; texte dans `71-CONTEXT.md`). Ce lot porte R1, R2 et G5 ; R5 et G4 sont hors lot (X2, X3).

## Constats de comportement

| Constat | Témoin rouge (code d'avant) | Correction | Vert |
|---|---|---|---|
| R1 (créé par la phase, sécurité) : le tampon de reprise rejoué à chaque rechargement du cadre fait répondre xterm aux questions qui y sont restées (`ESC[c`, `ESC[>c`, `ESC[6n`, DECRQM, DSR) ; ces réponses entrent dans la saisie du shell ou de `claude` | mutant M-REJEU-SANS-GARDE (= le code d'avant) : le PTY reçoit des réponses après 5 rechargements | `vf-cockpit-terminal-client.mjs` : pendant le rejeu, `onData` et `onBinary` ne partent que s'ils viennent d'une action de l'utilisateur (frappe, saisie, souris, collage). Le rejeu s'ouvre à la connexion du flux, se clôt au premier silence de 150 ms (borné à 3 s), une fois tout ce qui a été reçu analysé (écriture vide à rappel) ; une frappe le clôt aussitôt (un programme lancé tout de suite après l'invite n'est pas rejoué) | R1.0 à R1.2 |
| R2 (créé par E3) : bande noire `rgb(0,0,0)` sous la dernière ligne, fond de `.xterm-viewport` hors thème | M-FOND-NOIR (= le code d'avant) : fond de la zone de défilement noir, R2.1 rouge | `vf-cockpit-terminal-style.mjs` : `#terminal .xterm .xterm-viewport { background-color: var(--surface) }` | R2.1, R2.2 (5 hauteurs, 2 thèmes) |
| G5 : curseur de la barre à 10 % | M-CURSEUR-PALE (= le code d'avant) : contraste environ 1,3 | `vf-cockpit-terminal-vue.mjs` : curseur, survol et actif à 40, 55 et 70 % de `--ink` (lue sur la feuille, repli sur la teinte du thème) ; la barre reste cachée hors survol (G3 inchangé) | G5.1 : contraste mesuré >= 2 (sombre environ 3,8, clair environ 2,8) |

Mesures de R1 : le témoin positif est dans la même scène. Le récepteur (`rejeu.py`, posé par la suite dans son dossier temporaire) relève les réponses vives aux questions
de son démarrage (DA1 reçue), puis 5 rechargements du cadre en thèmes alternés rejouent le tampon : 0 octet de réponse ; une question neuve (`ESC[c` après une frappe) reçoit sa réponse.
Le mutant M-REJEU-JAMAIS-CLOS (rejeu jamais clos) rougit ce témoin positif : la garde ne coupe pas les réponses en général.

Cas découvert en cours de route : un premier jet de la garde (fenêtre close au seul silence) supprimait la réponse DA1 d'un programme lancé dans les 150 ms suivant l'invite
(T14.1a rouge). Corrigé par la clôture à la première frappe ; T14.1a et T14.1 sont verts.

## Suites

- `test-cockpit-terminal-xterm.sh` : 76 PASS / 0 FAIL. Nouvelles : R2.1, R2.2, G5.1, T23 (R1.0 à R1.2), M-REJEU-SANS-GARDE, M-REJEU-JAMAIS-CLOS, M-FOND-NOIR, M-CURSEUR-PALE.
- `test-cockpit-terminal-client.sh` : 67 PASS / 0 FAIL.
- `test-cockpit-terminal-page.sh` : 49 PASS / 0 FAIL (la palette est lue sous Node sans DOM : le repli de `theme()` le tient).
- `test-cockpit-terminal-xss.sh` : 17 PASS / 0 FAIL.
- Gates : check-machine-paths, check-python-isolation, check-file-size --all verts.

## Phrases de doc

- Au rechargement du cadre (changement de thème, rechargement de la page), le terminal ne répond plus aux questions d'identification ou d'état restées dans l'historique rejoué : plus de « 1;2c » dans la saisie du shell ni de `claude`. Les questions nouvelles d'un programme sont répondues normalement.
- Tout l'espace du cadre du terminal suit la couleur de fond du thème, sombre et clair : plus de bande noire sous la dernière ligne.
- La barre de défilement du terminal n'apparaît qu'au survol ou pendant un défilement, et son curseur est nettement visible (contraste d'au moins 2 contre le fond).

## Limites assumées

- Pendant le rejeu (jusqu'à 3 s si la sortie ne se tait pas), une question émise par un programme qui écrit en continu n'est pas répondue. Après le rejeu, rien n'est coupé.
