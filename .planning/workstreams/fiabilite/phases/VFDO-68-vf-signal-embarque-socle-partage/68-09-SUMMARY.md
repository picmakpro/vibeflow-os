---
phase: 68-vf-signal-embarque-socle-partage
plan: 09
requirements: [VFSG-08]
status: complete-hors-preuve-CI
commits:
  - cd8653f6 (partie 2, compte des suites)
  - 7b24cce4 (trace, porte de légitimité, sonde locale)
  - a4fc1ac4 (étape ci.yml, trailer Gate-Touche)
---

# 68-09 — étape CI `claude plugin validate/test` du mod vf-signal

Trace détaillée : `68-09-RED-TRACE.md` (porte, sonde, témoin rouge, rejeu).

## Livré

- **Porte de légitimité** : « Légitime, 2.1.318 (Recommandé) », Samuel, AskUserQuestion session principale, 2026-11-04 (P68-D-32). Version épinglée : `@anthropic-ai/claude-code@2.1.318`.
- **Compte des suites** des README racine réaligné (153), `check-version-sync.sh` exit 0 (revérifié après les commits).
- **Sonde** : Docker injoignable (démon absent) -> sonde Linux reportée au premier run CI de 68-13. Sonde jouée sous macOS, `HOME` vide, aucune authentification : `validate --strict plugin` 0, `test` sur l'arbre 0 (103 pass), `test` sur copie au test cassé 1 (témoin rouge).
- **Étape** `Mod vf-signal du module cockpit — claude plugin validate --strict et claude plugin test (VFSG-08)` dans le job `gates`, précédée de `actions/setup-node@v4` (Node 24), juste avant `check-release-tag`. Version exacte, préfixe `mktemp -d`, pas de `-g`, pas de flottant, aucun secret, `HOME` vide, témoin rouge intégré (rc nul = échec de l'étape), découverte non vide (10 fichiers).
- `continue-on-error` : 0 avant, 0 après.

## Vérifications
- Rejeu de l'étape seule : rc 0. `check-gate-touche.sh` 0 (5 marqueurs conformes), `check-planning-consumers-registered.sh` 0, `check-machine-paths.sh` 0, balayage awk des chemins `/Users|/home` : 0 ligne sur les fichiers touchés.
- Rejeu complet du job `gates` : 21 étapes rejouées, 4 sautées (checkout, setup-node (actions), deux étapes `main` uniquement), 0 en échec.

## Reste
- Revue `@picmakpro` requise (CODEOWNERS sur `.github/`).
- 68-13 : sonde Linux réelle, runs rouge puis vert de la PR.

estimate (plan) : tokens 45000, tasks 2, confidence low. actuals : non mesurés.
