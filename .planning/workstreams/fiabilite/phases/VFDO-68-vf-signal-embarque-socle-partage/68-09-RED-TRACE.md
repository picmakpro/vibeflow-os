# 68-09 — trace rouge

## Tâche 1 — porte de légitimité (T-68-SC ; P68-D-32)

- **Réponse de Samuel, mot pour mot** : « Légitime, 2.1.318 (Recommandé) ».
- **Canal et date** : AskUserQuestion, session principale Claude Code, 2026-11-04, relayée à l'exécuteur par la session principale via le mandat du manager `mgr68`.
- **Version épinglée** : `@anthropic-ai/claude-code@2.1.318`. Image de sonde prévue : `node:24-bookworm` (officielle `library/node`).
- OK-PORTE : paquet légitime, version exacte confirmée par un humain avant toute installation.

Parties 1 et 3 de la tâche 2 : traitées ci-dessous.

## Partie 2 — compte des suites

- **Commande** : `bash scripts/check-version-sync.sh` (compte = `find plugin scripts -path '*/tests/test-*.sh' | grep -c .`, première mention `N suites` de chaque README racine).
- **Attendu (rouge)** : seule la ligne « suites » rougit, `README.md` et `README.fr.md` à `149 suites` pour 153 réelles.
- **Obtenu (rouge)**, exit 1 :
  - `✗ README.md : '149 suites' ≠ réel=153 (find */tests/test-*.sh)`
  - `✗ README.fr.md : '149 suites' ≠ réel=153 (find */tests/test-*.sh)`
  - toutes les autres lignes `✓`.
- **Correctif** : `README.md:65` et `README.fr.md:67`, `149 suites` → `153 suites` (première mention seulement ; badge et historique intacts).
- **Obtenu (vert)** : `check-version-sync.sh` exit 0 ; `check-machine-paths.sh` exit 0.

## Partie 1 — sonde Linux et témoin rouge

- **Sonde Linux : NON JOUÉE.** `docker info` échoue sur ce poste (client 29.2.1 présent, démon injoignable : `failed to connect to the docker API ... docker.sock ... no such file`). La sonde Linux (conteneur `node:24-bookworm`) se fera au premier run CI de 68-13, comme le prévoit le plan.
- **Sonde locale, sous macOS (Darwin 25.4.0, Node v26.5.0)**, les cinq gestes de « Forme de l'étape » : installation de `@anthropic-ai/claude-code@2.1.318` dans un préfixe `mktemp -d` (`npm install --prefix`, `--no-audit --no-fund`) ; `env -i` avec `PATH` minimal et `HOME` pointé sur un dossier vide, aucune variable d'authentification ; binaire appelé par son chemin dans le préfixe.
  1. `claude --version` -> `2.1.318 (Claude Code)`.
  2. Découverte : 10 fichiers `*.test.tsx` sous `plugin/cockpit/signal/`.
  3. `claude plugin validate --strict plugin` -> exit 0 ; dernières lignes : `The directory also runs a safety scan and a policy review that this command does not.` / `✔ Validation passed`. Aucun « Not logged in » sous `HOME` vide.
  4. `claude plugin test plugin` (arbre réel) -> exit 0 ; `103 pass`, `0 fail`, `Ran 103 tests across 10 files`.
  5. Témoin rouge : copie de `plugin/` avec `cockpit/signal/tests/temoin-rouge.test.tsx` (`expect(1).toBe(2)`), `claude plugin test plugin` lancé dans la copie -> **exit 1** ; `103 pass`, `1 fail`, `Ran 104 tests across 11 files`. Le test cassé est bien découvert et fait échouer la commande.
- Aucune étape n'a échoué pour une raison étrangère au mod : pas de repli, `ci.yml` écrit.

## Partie 3 — l'étape (rejeu local)

- Commande : `bash .planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-.../tools/replay-ci-jobs.sh --job gates --step "Mod vf-signal"` -> exit 0, `BILAN REJEU gates : 1 rejouee(s), 24 sautee(s), 0 en echec`.
- Lignes de l'étape : `== découverte : 10 fichier(s) *.test.tsx ... ==`, `✔ Validation passed`, `== témoin rouge : claude plugin test sort rc=1 sur la copie au test cassé (attendu non nul) ==`, puis `103 pass / 0 fail`.
- Le rejeu utilise un préfixe et un HOME temporaires : rien d'installé globalement, rien écrit dans le `~/.claude` du poste.
