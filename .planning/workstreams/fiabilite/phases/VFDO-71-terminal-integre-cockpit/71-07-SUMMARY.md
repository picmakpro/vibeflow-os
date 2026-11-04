---
phase: 71
plan: 07
requirements: [TERM-01, TERM-05, TERM-07, TERM-12]
status: passed
---

# 71-07 — tiroir du terminal dans Projet et Code : résumé

Trace du rouge : `71-07-RED-TRACE.md` (même dossier).

## Commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `docs(71-07)` | `d4222468` | contrôle d'entrée : ligne P71-D-20 (O1, option B, datée) et T9.7 de 71-06 |
| `test(71-07)` | `93b5f595` | `test-cockpit-terminal-tiroir.sh` : 4 PASS / 30 FAIL sur l'amorce vide |
| `docs(71-07)` | `aa9e85ab` | trace du rouge (30 blocs attendu / obtenu) |
| `test(71-07)` | `7e8bd1b9` | TU.4 lit l'annonce d'ouverture dans l'historique des annonces (la barre l'écrase ensuite) |
| `feat(71-07)` | `5433db3d` | trois modules du tiroir (166 + 40 + 46 lignes) : 34 PASS / 0 FAIL |

## Valeur de `sandbox` retenue et mesure qui la fonde

`allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox`. Mesure O8 de 71-06 : `MESURE-O8 minimal=bloque popups=ouvert opener=nul` (sandbox minimal : `window.open` bloqué ; avec `allow-popups` : ouvert, et en `noopener` la fenêtre n'a pas accès à son opener ; T9.5 reste vert). Décision du manager : ces cinq jetons, aucun autre, parce que P71-D-16 veut des liens qui s'ouvrent sur clic. TU.3 compare la chaîne exacte et l'absence d'attribut `allow`. 71-09 n'a donc pas à écrire « les liens ne s'ouvrent pas depuis le tiroir ».

## Preuves

- Rouge puis vert : TU.0, TU.2 à TU.8, TU.10, TU.11, TU.12, T8.2, T8.3 (M-FRAMESRC), T17.1 à T17.6, TU.13 (avec ses gardes de vivacité), O6 (TU.9).
- Vert dès la base (témoins) : TU.1 sur `/` et `/project.html` (absence vraie, page vivante). TU.12, T17.2, T17.3, T17.6 sont rouges sur la base (au lieu de vertes) par garde de vivacité : aucune absence ne passe vert à vide.
- Mutants : M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-CONFIANCE (chacun accepte le cas qu'il doit laisser passer, table T17.4) ; M-MSG-DONNEE (client de Q qui joint le texte du shell à un message : T17.5 rougit) ; M-FRAMESRC (T8.3) ; injection de panne `port: 1` (TU.11). « Sans effet » sur la base, rouges sur le code.
- Navigateur : 34 PASS / 0 FAIL, environ 3 min. Gestes par `Input.dispatchMouseEvent` / `Input.dispatchKeyEvent` seulement ; amorçage joué dans Chrome, secret lu sans démarrer le shell (échange refusé sur Q, qui n'attache pas le flux), PID du shell lu dans `shell.pid` avant et après rechargement (grâce de 5 s) et après la bascule de thème.

## Écarts et constats

- **Origine de `window.VF_COCKPIT_SERVER` et jeton** : le script lit `window.VF_COCKPIT_SERVER.token` et pose l'en-tête `x-vf-cockpit-token` (noms de la sortie renommée) ; sur la page Projet le jeton est celui de la page (`inject.replace(token, ptoken)` de serve.mjs).
- **Le script est dans `<head>`** (point d'insertion `inject`) : il attend `DOMContentLoaded` avant de toucher `body`.
- **Contradiction de l'UI-SPEC** : §5 fait du double-clic sur la poignée l'état « plein », §8 le fait revenir à 320 px. Suivi : §8 (double-clic et Entrée = 320 px) ; l'état plein se prend par « Agrandir ».
- **Fermeture sans animation** : fondu et glissement à l'ouverture seulement (le `hidden` est posé tout de suite à la fermeture). Aucune animation sous `prefers-reduced-motion` ni pendant `html.theme-switching`.
- **Marge basse du contenu défilant de la page Projet (UI-SPEC §8)** non posée : la page Projet est la même vue que la carte (canvas), aucun conteneur défilant à cibler ; seul `#ask` monte de la hauteur du tiroir (`--vf-term-h`). À reprendre en recette si un bloc reste masqué.
- **Ombre `--shadow-card`** posée sur la pastille (la variable existe dans P) ; la remarque du manager sur F-05-1 ne concernait que la page de Q.
- **Plein à ≤ 700 px** : l'ouverture se fait en plein. Hauteur bornée à la fenêtre au chargement (`pleinMax`).
- **Plan, tâche 0** : la porte de vérification du plan ne sortait pas en non-zéro sur `ENTREE-NON-TENUE` ; rejouée avec `process.exit(1)` (remarque du plan-checker), texte du plan non modifié (hors liste de fichiers).
- **Suites voisines** : `test-cockpit-terminal-xterm.sh` et `tests/temoins/hostile.py` (non suivis) appartiennent au plan 71-08, non touchés.

## Branchements à recenser pour le merge

Aucun fichier existant touché (`serve.mjs`, `vf-cockpit-terminal.mjs`, la page et le client de Q inchangés ; rien sous `assets/ui/`). Le tiroir est déjà branché par le crochet B3 de `serve.mjs` (`inject` + `TERM.injection()`, posé par 71-01). Pour la Phase 69, qui modifie le cockpit en parallèle : si la 69 passe `inject` à sa page équipe, le tiroir s'en retire de lui-même (chemin hors `/`, `/index.html`, `/project.html` : rien n'est créé, assertion TU.12). Si la 69 renomme `#ask`, `#panel`, `--pw` ou `--hh`, la feuille `vf-cockpit-terminal-tiroir-style.mjs` (règles `body.vf-term-ouvert #ask`, `right: max(16px, var(--pw))`, `top: calc(var(--hh) + 12px)`) est le seul endroit à ajuster. Pas de trailer `Gate-Touche`.

## Décisions citées

P71-D-07, D-08, D-16, D-18, D-19, D-20, D-21 (O1 option B, O6, O8), D-24 (décisions du manager, `71-CONTEXT.md`) ; P71-D-01..08 et D-23 sont des arbitrages de Samuel (AskUserQuestion, session principale, 2026-11-03), non invoqués ici au-delà de leur lettre.
