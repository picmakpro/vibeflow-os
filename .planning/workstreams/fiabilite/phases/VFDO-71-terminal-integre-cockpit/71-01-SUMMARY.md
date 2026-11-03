---
phase: 71
plan: 01
status: passed
requirements: [TERM-01, TERM-05, TERM-07]
commits:
  tests: 41bf8b95
  trace: 017b54ca
  code: 3bcbfebd
---

# 71-01 — tranche traçante `serve.mjs --terminal` : résumé

`serve.mjs --terminal` charge le module du terminal, ouvre un second écouteur sur 127.0.0.1 (origine Q d'un port éphémère distinct de P),
échange l'amorçage contre un secret de session, lance l'assistant PTY Python à la première attache du flux, renvoie dans `GET /flux` une
commande envoyée par `POST /entree`, et ne laisse aucun processus à l'arrêt. Sans le drapeau : aucune route, aucun écouteur, aucune clé
`terminal` dans `server.json`, CSP de v2.75.0 inchangée.

## Ordre des commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `test(71-01)` | `41bf8b95` | `test-cockpit-terminal-activation.sh` et `terminal-aux.mjs` (aucun module) |
| `docs(71-01)` | `017b54ca` | `71-01-RED-TRACE.md` : 21 rouges nommés (attendu, obtenu), 19 contrôles positifs verts |
| `feat(71-01)` | `3bcbfebd` | patch `vibeflow P25` de `serve.mjs` + son diff amont, sept modules neufs |

Trace du rouge : `71-01-RED-TRACE.md` (même dossier). Vert : `Résultats : 40 PASS / 0 FAIL`.

## Preuves

- Rouge puis vert pour TERM-01 (T7.7, T7.8, T8.1, P5.1), E2E.1 à E2E.6, T11.4, POSE.1 à POSE.3 ; T7.0 à T7.5 verts dès la base (TERM-01 sans drapeau était déjà vrai).
- Mutants M-ACTIF, M-ECOUTE0, M-FRAMESRC, M-WIN, M-HORS-MOTEUR : « mutant sans effet » sur la base, rouges attendus sur le code.
- Pose réelle : l'engine pose `skills/cockpit-moteur/terminal/vf-cockpit-pty.py` dans les scopes project, user et local, identique à la source (`cksum`) ; un serveur INSTALLÉ lance l'assistant posé ; le vrai `~/.claude` est inchangé (POSE.4).
- `synchro.sh verifier` : vert sur une copie du moteur privée de `terminal/` (« amont retrouvé à l'octet », 48 fichiers).

## Écarts et constats

- **Fenêtre documentée (P71-PL-20, PL-21)** : `synchro.sh verifier` sur l'arbre réel et V6.1 de `test-cockpit-vendor.sh` rougissent sur le seul fichier `terminal/vf-cockpit-pty.py` (mesuré : 74 PASS / 1 FAIL) jusqu'à ce que 71-11 pose la ligne `AJOUT`. `VENDORED.txt` n'est pas touché ici.
- **Diff amont régénéré sans clone** : `regenerer-patch` sans clone inverse le diff existant sur le fichier courant, ce qui échoue dès que `serve.mjs` a changé. Voie suivie : amont reconstruit en inversant le diff sur la version du HEAD (sha256 égal au manifeste `amont-92d6854.sha256`), posé comme faux clone `skills/floorplan/assets/serve.mjs`, puis `regenerer-patch assets/serve.mjs <faux-clone>`. À reproduire par 71-11 et la 69 (B7a).
- `vf-cockpit.mjs build` n'accepte pas `--quiet` (argument inconnu) : les suites l'appellent sans.
- `scripts/check-file-size.sh` n'existe pas à la racine : le gate est `plugin/software-architecture/scripts/check-file-size.sh` (`--all` vert, aucun avertissement).
- `check-python-isolation.sh` lit aussi les commentaires des `.mjs` suivis : un commentaire qui contient `python3 -I <chemin>` rougit (corrigé dans le commit de code).
- Extensions du client de test, hors liste du plan mais dans le même fichier : `--corps-vers` (corps complet d'une page de 2 Mo) et `ligne-csp-v275` (copie figée de la ligne).
- bash 3.2 : une apostrophe dans un `${var:-…}` à l'intérieur de `$(…)` casse l'analyse du script à une ligne très éloignée.

## Mesures

- `serve.mjs` après le patch : **614 lignes** (610 avant ; à reprendre par 71-11 pour la `TAILLE`). `grep -c 'vibeflow P25'` : 7.
- Modules neufs : `vf-cockpit-terminal.mjs` 112, `-session` 86, `-amorce` 31, `-env` 17, `-page` 11, `-tiroir` 5 lignes ; `vf-cockpit-pty.py` 168 lignes.
- Fichiers hors liste : aucun. `vf-cockpit-server.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit.mjs`, `VENDORED.txt` non touchés. Pas de trailer `Gate-Touche` (aucun fichier de la surface de `check-gate-touche.sh`).

## Branchements à recenser pour le merge

| # | Fichier existant | Plan | Changement | Conflit avec la 69 |
|---|------------------|------|------------|--------------------|
| B1 | `plugin/cockpit/scripts/vf-cockpit.mjs` | 71-10 | `--terminal`, `ecrireAmorce`, ouverture de Q (O2) | faible (non touché par la 69) |
| B2 | `assets/serve.mjs`, `sendPage` | 71-01 (fait) | `pageCsp(html) + (TERM ? TERM.frameSrc() : '')` ; la ligne `const csp = ` intacte | faible |
| B3 | `assets/serve.mjs`, `const inject` | 71-01 (fait) | `+ (TERM ? TERM.injection() : '')` | faible ; la 69 passe `inject` à sa page équipe : le tiroir s'y retire de lui-même (P71-PL-15) |
| B4 | `assets/serve.mjs`, garde d'inactivité | 71-01 (fait) | `&& !TERM?.occupe()` | faible |
| B5 | `assets/serve.mjs`, routage `/api/` | 71-01 (fait) | `GET /api/vf/terminal` -> `TERM.routeP` avant `VF.route` | faible |
| B6 | `assets/serve.mjs`, `listening` et import | 71-01 (fait) | `let TERM` sous `has('terminal')`, `TERM?.demarrer(port)` | faible |
| B7a | `amont/patches/assets__serve.mjs.diff` | 71-01 (fait) | diff régénéré dans le commit du patch | **certain** : la 69 régénère le même diff ; à refaire APRÈS la fusion de `serve.mjs` |
| B7b | `skills/cockpit-moteur/VENDORED.txt` (`PATCH assets/serve.mjs`, `TAILLE assets/serve.mjs`, 7 `AJOUT`) | 71-11 | `P25` ajouté, TAILLE recalculée (614 avant fusion), ajouts du vendor et de l'assistant | **certain** : la 69 ajoute `P24` et passe TAILLE à 611 ; fusion à la main |
| B9 | `scripts/tests/test-cockpit-vendor.sh` | 71-11 | V2 « quatre composants » -> « six composants » ; section V9 | faible |
| B10 | `skills/cockpit-moteur/LICENCES-TIERCES.txt` | 71-11 | deux lignes (xterm, addon-fit) | faible |
| B11 | `README.md`, `README.fr.md` (racine) | 71-09 | le seul nombre de la phrase « N suites » | **certain** : recompter après la fusion |

## Décisions citées

P71-D-02, D-07, D-09 à D-11, D-17 (décisions du manager, `71-CONTEXT.md`) ; O9 : P71-D-21 (décision du manager, vf-dev-manager, 2026-11-03). Aucun arbitrage de Samuel invoqué.
