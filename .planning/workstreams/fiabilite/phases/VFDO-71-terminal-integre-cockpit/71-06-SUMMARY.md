---
phase: 71
plan: 06
requirements: [TERM-04, TERM-05, TERM-10, TERM-12]
status: passed
---

# 71-06 — client de la page Q : résumé

Trace du rouge : `71-06-RED-TRACE.md` (même dossier).

## Commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `test(71-06)` | `f7e1f7d0` | `test-cockpit-terminal-client.sh` : 8 PASS / 27 FAIL sur les amorces vides |
| `docs(71-06)` | `7b214305` | trace du rouge, mesure O8 de la base |
| `feat(71-06)` | `ac5dc453` | client (138 lignes), vue (61 lignes), correctif de la suite (secret masqué : `secretOk`) |

## Preuves

- Rouge puis vert : T6.1, T6.1b, T6.2, T6.3, T6.4, T6.6, T6.7, T9.5, T9.7, T14.S1-S4, T17.Q1-Q4 (+ TQ.1 saisie -> shell -> sortie, T17.Q5 liste fermée, O4.1 reprise, O4.2 autre onglet = carte « Terminal déjà ouvert »).
- Verts dès la base (témoins) : T6.5, T9.6 ; leurs mutants M-SETCOOKIE et M-ANCETRES rougissent.
- Mutants : M-COOKIE, M-FRAGMENT, M-STOCKAGE, M-ETOILE, M-ECOUTE + M-CLIP, M-ANCETRES, M-SETCOOKIE : « sans effet » sur la base, rouges sur le code.
- Suites : `test-cockpit-terminal-client.sh` 35 PASS / 0 FAIL ; `-page` 39/0 ; `-session` 29/0 ; `-activation` 40/0. `check-machine-paths.sh`, `check-file-size.sh --all`, `check-python-isolation.sh` : rc 0.

## Dépendance : P71-D-24 (défaut serveur trouvé par ce plan)

Chrome n'envoie pas `Origin` sur un `fetch` GET de même origine ; `controle()` refusait donc GET /flux et GET /etat. Le client ne pose jamais `Origin` à la main. Décision du manager : P71-D-24 (`5008fa17`). Le correctif est dans l'arbre de travail (`vf-cockpit-terminal.mjs`, exécuteur de la correction ciblée) mais n'était pas commité à la fin de ce plan : **T9.5, T9.7, T17.Q4, TQ.1, O4.1 dépendent de son commit `fix(71)`**. Mesure : verts sur une copie du module avec le correctif, puis sur l'arbre de travail.

## Mesure O8 (pour 71-07) : `sandbox` du cadre

`MESURE-O8 minimal=bloque popups=ouvert opener=nul` (base et après la tâche 2, identique).

- `sandbox="allow-scripts allow-same-origin"` : `window.open` est BLOQUÉ (liens OSC 8 non ouvrables).
- `sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"` : ouvert, et avec `'noopener'` la fenêtre n'a pas accès à son opener (`canAccessOpener` faux). L'ouverture se fait sur geste utilisateur (le clic dans le cadre).
- Application par 71-07 : si les liens cliquables sont voulus, poser les cinq jetons ci-dessus ; sinon garder le sandbox minimal. A1 : sous le sandbox minimal, la page Q lit son secret, ouvre son flux et signale `ready` puis `etat:connecte` (T9.5 vert) ; l'identifiant d'onglet est partagé entre Q en premier niveau et Q dans le cadre (O4.1 vert). Les deux configurations se reconnectent.

## Écarts et constats

- T14.S3 et T17.Q1 (absences) portent un garde de vivacité (scripts propres non vides) : rouges sur la base au lieu de vertes, pour éviter un vert à vide.
- Ombre des cartes (`--shadow-card`, F de 71-05) non reprise : filet `--hair-2` conservé.
- Le client ne stylise pas l'identifiant de l'onglet côté serveur : le serveur de 71-04 accepte 1-64 caractères `[A-Za-z0-9_-]` ; le client envoie 32 hexadécimaux.
- Attente de Chrome : environ 3 à 4 min pour la suite complète (8 mutants dont 4 en navigateur) ; `VF_CLIENT_MS` règle l'échéance des attentes.

## Branchements à recenser pour le merge

Aucun. Fichiers hors liste : aucun. Pas de trailer `Gate-Touche`.

## Décisions citées

P71-D-12, D-13, D-15, D-16, D-18, D-21 (O4), D-24 (décisions du manager, `71-CONTEXT.md`). Aucun arbitrage de Samuel invoqué.
