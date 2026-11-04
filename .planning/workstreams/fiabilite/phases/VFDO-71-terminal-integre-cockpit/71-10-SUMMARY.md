---
phase: 71
plan: 10
status: passed
requirements: [TERM-01, TERM-03, TERM-04, TERM-07]
commits:
  tests: 26dd20d6
  trace: 24431ed8
  tests-correction: b9d39df8
  trace-finale: ed13e6a8
  code: f52f3269
---

# 71-10 — lanceur `vf-cockpit.mjs --terminal` : résumé

`vf-cockpit.mjs open --terminal` démarre le serveur unique avec le drapeau, écrit l'amorçage dans `<sortie>/.cache/terminal-amorce`
(0600, suppression préalable puis création exclusive, après `verifierSortie`), et ouvre `http://127.0.0.1:<Q>/#t=<amorçage>` une seule fois
(le serveur est lancé avec `--no-open`). Cockpit déjà vivant (O2) : sans terminal -> relancé avec le drapeau ; avec terminal -> même serveur,
nouvel amorçage, l'ancien refusé. Sous `win32` : « Terminal indisponible sous Windows. », drapeau transmis au serveur, aucun amorçage, aucune
ouverture de Q. Sans le drapeau : comportement de v2.75.0. `stop` arrête serveur, assistant et shell (L9). Aucun code de sortie nouveau.

Trace du rouge : `71-10-RED-TRACE.md` (27 rouges nommés sur le lanceur de la base, rc=1, `7 PASS / 27 FAIL` ; tous : `argument inconnu : --terminal`).
Vert : `Résultats : 35 PASS / 0 FAIL`.

## Preuves

- TERM-01 : L1 (sortie 0, base 64), L2 (`terminal.url`), L7 (O2 a, PID changé), L8 (O2 c, même PID), L9 (`stop`).
- TERM-03 : L3 (mode 600), L4 (lien préplacé jamais suivi), L5 (valeur absente de la sortie, du journal, de `server.json`, de la ligne de commande et de l'environnement du serveur ; témoin positif sur le fichier) ; mutants M-MODE, M-SUIT-LIEN, M-IMPRIME rouges attendus, « mutant sans effet » sur la base.
- TERM-04 : L6 (une ouverture, adresse de Q avec 64 hexadécimaux, Q ≠ P, égale à celle de `terminal.url`) ; M-OUVRE-P. Aucun vrai navigateur : `open` et `xdg-open` factices en tête du PATH.
- TERM-07 : L10 (plateforme simulée par préchargement), L11 / L11b (PID leurre jamais arrêté, sortie 5, aucun amorçage).
- Non-régression : `test-cockpit-serveur.sh` 64/0, `test-cockpit-terminal-activation.sh` 40/0. `check-machine-paths`, `check-file-size --all`, `check-python-isolation` : 0. `check-gate-touche` : surface non touchée, aucun trailer.

## Comportement observé de L4 (refus nommé ou remplacement sûr)

Refus nommé, dans les deux cas : un lien préplacé dans la sortie est refusé par la garde existante avant `ecrireAmorce` — « lien symbolique
refusé dans la sortie du cockpit » (sortie 4) — par l'assemblage quand le serveur est arrêté, par `verifierSortie` (appelé par `amorcer`) quand
un serveur avec terminal est vivant. La cible est intacte dans les deux scénarios.

## Écarts et constats

- **L11 scindé** : le plan exige un L11 vert sur la base et un `open --terminal` ; sortie 64 sur la base l'interdit. L11 = `--rebuild` (garde existante, vert), L11b = `--terminal` (rouge sur la base).
- **Deuxième couche de O3 prouvée seulement avec la première** (finding) : la suppression préalable et la création exclusive de `ecrireAmorce` ne sont atteignables que si un lien apparaît APRÈS les gardes (course). Aucun test déterministe ne l'isole : M-SUIT-LIEN retire les trois protections ensemble (unlink, `wx`, `verifierSortie` d'`amorcer`). Défense en profondeur, non un défaut.
- Première passe de la suite corrigée (arguments du client `flux`, couche de garde de L4) en commit séparé `b9d39df8`, trace régénérée.
- L5 environnement : `ps -Eww` lit l'environnement sur ce poste (témoin : il montre `VF_COCKPIT_SCRIPTS_DIR`) ; sur un poste où il ne le montre pas, l'assertion est annoncée SKIP, jamais comptée verte.
- `vf-cockpit.mjs` : 169 lignes (limite 250). Codes de l'en-tête inchangés. Fichiers hors liste : aucun.
- Terminal non démarré dans les 10 s : amorçage effacé, message du plan, P ouverte, sortie 0 (non couvert par une assertion : aucun moyen déterministe de faire échouer le démarrage de Q sans toucher au module de 71-01).

## Branchements à recenser pour le merge

| Fichier existant | Changement | Conflit avec la 69 |
|------------------|------------|--------------------|
| `plugin/cockpit/scripts/vf-cockpit.mjs` (B1) | import `node:crypto` ; `lireArgs` (`terminal`), `AIDE`, en-tête ; fonctions `ecrireAmorce`, `amorcer`, `ouvrir`, `ouvrirQ`, `attendreTerminal` insérées avant `assemblerLab` ; `demarrer` (`--no-open` si `avecQ`, `--terminal`) ; `main` (bloc « open » et fin) | faible (si la 69 touche `main`, fusion à la main du bloc `open`) |

## Décisions citées

P71-D-02, D-05, D-07, D-11, D-12 (décisions du manager, `71-CONTEXT.md`) ; O2/O3 : P71-D-21 (décision du manager, 2026-11-03). Aucun arbitrage de Samuel invoqué.
