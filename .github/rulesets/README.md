# Sources des rulesets `main` et `tags v*`

Ce dossier contient les deux sources versionnées des rulesets GitHub posés côté serveur sur ce
dépôt (Phase 41, volet admin — ADR-072, sous-section « Amendement du 2026-09-23 — posture côté
serveur »).

## Rôle des deux fichiers

- `main.json` — ruleset de branche appliqué à `refs/heads/main` : PR obligatoire à 0 approbation
  requise côté GitHub, les quatre jobs requis épinglés sur l'intégration CI, branche à jour avant
  merge, revue code owner exigée, suppression et force push interdits hors liste de contournement,
  méthodes de merge non restreintes.
- `tags-v.json` — ruleset appliqué à `refs/tags/v*` : création libre pour tout acteur, réécriture,
  suppression et force push refusés hors liste de contournement.

Chacun de ces deux fichiers est le corps exact envoyé à `POST /repos/{owner}/{repo}/rulesets`
lors de la pose — la source versionnée ici EST ce qui a été posé, octet pour octet, jamais un
résumé ou une reconstruction a posteriori.

## Pose (admin uniquement)

Depuis la source mergée sur `origin/main`, par l'admin du dépôt :

```
git show origin/main:.github/rulesets/main.json | gh api -X POST repos/picmakpro/vibeflow-os/rulesets --input -
git show origin/main:.github/rulesets/tags-v.json | gh api -X POST repos/picmakpro/vibeflow-os/rulesets --input -
```

## Relecture

```
gh api repos/picmakpro/vibeflow-os/rulesets
gh api repos/picmakpro/vibeflow-os/rulesets/<id>
gh api repos/picmakpro/vibeflow-os/rules/branches/main
```

## Retour arrière

L'admin repasse chaque ruleset en `disabled`, sans le supprimer :

```
gh api -X PUT repos/picmakpro/vibeflow-os/rulesets/<id> -f enforcement=disabled
```

Témoin : `gh api repos/picmakpro/vibeflow-os/rules/branches/main` rend `[]` pour le ruleset de
branche une fois désactivé.

## Modifier ces fichiers

Toute modification de `main.json`, `tags-v.json` ou de ce README passe soit par la revue du
propriétaire CODEOWNERS déclaré sur `.github/` (`@picmakpro`), soit par un contournement explicite
et tracé — réservé à Samuel et Willy, en mode `always` (D-02bis, arbitrage Willy, AskUserQuestion
session principale, 2026-09-23 ; D-05, arbitrage Samuel, AskUserQuestion session principale,
2026-09-17). Aucun autre acteur ne peut faire atterrir un changement sur ce chemin.

## Référence

Détail complet de la décision, de la liste de contournement et des conséquences : `docs/ADR.md`,
ADR-072, sous-section « Amendement du 2026-09-23 — posture côté serveur (volet admin) ».
