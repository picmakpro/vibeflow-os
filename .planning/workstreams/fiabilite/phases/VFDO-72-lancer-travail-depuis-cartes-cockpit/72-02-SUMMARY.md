---
phase: 72
plan: 02
status: complete
requirements: [LANC-06, LANC-07]
---

# 72-02 — lancement d'une ligne au shell par l'assistant PTY et la session

Livré : assistant PTY (ligne `L <hex>`, revalidation, test du premier plan, Ctrl-C puis ligne sans retour chariot) et `sessions.lancer(ligne, onglet)` (file FIFO d'attentes, délai de 2 s, lecture de `LANCE …`).

Commits : 442c3e1d, 8ab573e7 (témoins rouges et trace), 07daa864 (assistant), f643946b, a94d9cb7 (trace mutants assistant), ffbaa971 (session), 9ac5e282 (trace mutants session).

Reprise après crash du 2026-11-05 : le travail non commité de la session a été jugé conforme au plan et à la suite, gardé tel quel.

Preuves : `test-cockpit-lancer-pty.sh pty` 45/0, `session` 15/0 ; `test-cockpit-terminal-{session,pty,pty-plantage,serveur,activation}.sh` 58, 63, 21, 208, 40 PASS, 0 FAIL.
Dette : `vf-cockpit-pty.py` porte le marqueur `vibeflow:allow-large-file` (lancé en `python3 -I`).
