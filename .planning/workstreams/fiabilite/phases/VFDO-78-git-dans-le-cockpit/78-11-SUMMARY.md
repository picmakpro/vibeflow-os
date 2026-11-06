---
phase: 78
plan: "11"
subsystem: cockpit
requirements-completed: [GITC-01, GITC-02, GITC-04, GITC-05, GITC-06, GITC-07, GITC-09, GITC-11, GITC-12, GITC-13]
key-files:
  created:
    - plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh
  modified:
    - plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh
    - plugin/cockpit/VERSION
    - plugin/cockpit/module.json
    - plugin/cockpit/CHANGELOG.md
    - plugin/cockpit/README.md
    - README.md
    - README.fr.md
---

# 78-11 — la phase de bout en bout, chaîne XSS git, version v1.4.0 (GITC-12)

Traces de rouge et de vert : `78-11-RED-TRACE.md`.

## Ce qui est livré

- **`test-cockpit-git-e2e.sh`** (34 assertions, 0 échec, 0 sauté) : un lab fabriqué depuis un worktree (`depot` principal, `wt-a` = le lab sur `feat/x`, `wt-b` sale, un merge, un tag, un stash, deux auteurs), le vrai serveur, la page en Chrome CDP, aucun `fetch` remplacé. B1 nom `depot` sur les trois onglets et seconde ligne ; B2 clic et touche `g`, rangées = celles de `GET /api/vf/git` (même nombre, même premier sha), détail = route `/commit`, pastilles des worktrees = `git status` (1 modifié, 2 non suivis, propre) ; B3 un commit puis un `git switch -c` faits pendant la séance (rangée neuve et sélection conservée, seconde ligne `autre`, en moins de 10 s) ; B4 hors dépôt (ni ligne, ni ouvreur, ni tiroir, routes `absent`, 0 erreur, 0 violation) ; B5 lab piégé sous `GIT_DIR` leurre exporté (témoin positif : git brut pose les marqueurs ; aucun marqueur côté cockpit, empreinte de `.git` identique par `cmp -s`, témoin d'écriture qui la change). Les assertions visent des propriétés (routes, identifiants `#vf-git-ligne`/`#vf-git-tiroir`, rôles ARIA, flux), pas des largeurs ni des classes.
- **Mutants de jonction** (M-ROUTE, M-SIGNAL, M-OUVREUR), chacun rouge pour la bonne raison : voir la trace.
- **Volet git de `test-cockpit-chaine-xss.sh`** (C0g à C4g) : dépôt hostile (branche `<svg/onload=eval(atob(…))>`, message de commit et de stash `<img onerror=…>`, auteur), C0g aboutit (marqueur créé), C1g code livré rien, C2g textContent seul, C3g CSP seule, C4g garde seule. 34 PASS, volet existant C0 à C5 inchangé.
- **Version `v1.4.0`** : lue au moment de l'exécution, `origin/main` porte `v1.3.3`, mineure suivante = nouvelle capacité. VERSION, `module.json` (version et description « tiroir Git en lecture seule »), CHANGELOG.md, README.md du module alignés ; VERSION racine, `plugin.json`, `marketplace.json` inchangés (pas de release).
- **README du module** : section « Git dans le cockpit » (ouverture, contenu, commandes à copier, lecture seule et routes, dégradation, rafraîchissement, environnement git durci), et les limites : moteur vendorisé lancé hors assemblage sans liste git (fermé par défaut, P78-D-25), `status` relu à l'ouverture et au signal, modification sans `add` non signalée.

## Captures pour le juge de design (P78-D-16)

31 PNG sous `${TMPDIR:-/tmp}/78-captures/` (jamais commitées) : `<clair|sombre>-<375|700|768|1000|1440>-<1-ferme|2-ouvert|3-detail>.png` (30) et `sombre-1440-4-terminal-ouvert.png` (le serveur `--terminal` s'est lancé). Rejouer : `E2E_SECTIONS="CAPT" bash plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh`. Les largeurs sont émulées en CSS (`mobile: false`) : le tactile n'est pas émulable avec `chrome-session.mjs`.

## Suites rejouées (sur ce que je crée et ce que mon plan nomme ; la découverte complète est celle du manager)

| Suite ou commande | rc |
|---|---|
| `test-cockpit-git-e2e.sh` | 0 (34/0/0) |
| `test-cockpit-chaine-xss.sh` | 0 (34 PASS) |
| `test-cockpit-terminal-xss.sh` (critère d'acceptation) | 0 |
| `test-cockpit-chrome-fr.sh` | **1** : F9.2 « sous-titre et pastille en français », attendu `Jalon v1 · phase 1 (Socle) · prête à planifier.`, obtenu `null`. Voir findings : cause hors de ce plan |
| `css-jetons.mjs` sur 76 et les trois 77 | 0 |
| `check-version-sync.sh` (job `gates`) | 1 puis 0 après recalage du décompte de suites des README racine |
| `check-python-isolation.sh --min-sites 40` | 0 |
| `check-capability-activation.sh` | 0 |
| `manual/.tools/check-manual.sh` | 0 |
| `plugin/conductor/scripts/check-instruction-budget.sh` | 0 |
| `check-machine-paths.sh` | **1** : un chemin de compte dans `78-09-SUMMARY.md` (fichier d'un autre plan). Voir findings |
| OK-VERSION, OK-GARDES | verts |

Les autres commandes du job `gates` (`check-agents`, `check-skills`, `check-blueprints`, workstream-aware, divergence, baselines, gate-touche, push-sans-pr, mod vf-signal, release-tag) ne lisent aucun fichier de ce plan et sont laissées à la passe du manager.

## Déviations

1. **README racine (`README.md`, `README.fr.md`)** hors `files_modified` : le gate `check-version-sync.sh` exige que « 167 suites » égale le décompte réel ; les suites de la phase portent 167 à 176. Recalé à 176 (deux phrases). À recaler au rebase si une autre phase ajoute des suites.
2. **Version lue sur `origin/main`**, le `main` local pointant au même commit (mandat).
3. **M-SIGNAL et M-OUVREUR posés sur la sortie assemblée** (copie `<lab>/.vibeflow/mut-<nom>/`, racine du lab = deux niveaux au-dessus) et non sur une copie du module : la page inline 70-vf-live.js et 76 ; même effet, sans reconstruction.
4. **C0g retire aussi la garde du moteur (M-GARDE)** : sans elle `/api/plan/undo` n'exécute pas le faux moteur et le marqueur ne peut pas naître. C4g (garde seule) ajouté en plus de C0g à C3g.
5. **Auteur hostile** : git retire `<` et `>` d'un nom d'auteur ; la charge d'auteur est donc de la forme attribut (`x"/onfocus=…`).
6. **Défaut de la suite corrigé en cours de route** : B2.3 et B5.1 lisaient le détail pendant « Lecture du détail » (rouge, cause : le test) ; les captures « ouvert » montraient le détail resté ouvert d'une itération à l'autre (repliées avant la vue « ouvert »).

## Findings

- **chrome-fr F9.2 rouge sous l'état courant de l'arbre** : le sous-titre de la page Projet est réécrit par `76-vf-git-entete.js` (P78-D-03 : « le sous-titre résume la vue ») dans l'état non commité de l'autre worker (en-tête et tiroir). 78-04 avait rendu cette suite verte sur son commit. À régler par ce worker ou par le manager (ajuster F9.2 au sous-titre voulu, ou le sous-titre) ; aucun libellé neuf identique dans les deux langues relevé : `vf-cockpit-fr-exclusions.json` intact.
- **check-machine-paths rouge** : `78-09-SUMMARY.md` ligne 21 cite le chemin de compte du dépôt ; un fichier d'un autre plan, non corrigé ici (interdit du plan). Correctif : `~/Documents/dev/vibeflow-os` ou `<racine du dépôt>`.
- Rouge connu, hors phase : `test-cockpit-securite.sh` FB3.5 (plafond d'horloge, cité en 78-05) non rejoué ici.

## Valeurs d'espacement posées

Aucune (aucune feuille de style touchée).
