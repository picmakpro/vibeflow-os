# Protocole de boucle test+fix autonome (mobile)

> Référence chargée on-demand par `vf-test-orchestrator` et par le mode autonome (`vf-auto`).
> Matérialise la **phase 7 (Vérification Visuelle/Réelle)** et la boucle de correction de
> `god-execution` (Pattern 09) pour un projet mobile, avec les **halt conditions** (Pattern 11)
> et le **cloisonnement anti-triche** (Pattern 12).

## Où ça s'insère dans le flux autonome

`vf-auto` (→ `gsd-autonomous`) enchaîne les phases : `discuss → plan → execute`, met à jour l'état,
marque *done*. Ses gates natifs sont **techniques** (lint / tsc / tests unitaires). Ce protocole
ajoute l'étape manquante : **la vérification réelle sur cible + la boucle de correction**, avant de
déclarer une phase mobile « faite ».

```
… → execute (code écrit, gates techniques verts)
     → vf-test-orchestrator (CE PROTOCOLE) :
         boucle [ vf-test-runner (Maestro sur simu) → si rouge → vf-app-fixer → re-test ]
         jusqu'au vert / plafond / abandon
     → phase done (seulement si les critères observables sont vérifiés réellement)
→ phase suivante
```

## Invariants de la boucle

1. **Baseline verte** : à chaque tour, mémoriser l'ensemble des flows verts + le SHA git.
2. **Anti-régression** : un changement qui refait échouer un flow vert est **reverté** (monotonie).
3. **Anti-thrash** : `maxAttemptsPerFlow` (défaut 3) tentatives par flow, puis abandon documenté.
4. **Arrêt** : tout vert **ou** plafond temps/tokens **ou** tous les restants abandonnés.
5. **Cloisonnement** : `vf-test-runner` écrit les tests (jamais le code) ; `vf-app-fixer` écrit le
   code (jamais les tests). Aucun assert n'est jamais affaibli. (Pattern 12.)
6. **Traçabilité** : un fix = un commit atomique (selon la politique du projet) + rapport final.

## Mapping halt conditions (Pattern 11)

| Situation dans la boucle | Halt |
|--------------------------|------|
| >3 cycles test+fix sans progrès mesurable sur un flow | **HALT-2** → abandon local + escalade si global |
| Le fix exigerait une action destructive (force-push, rollback prod) | **HALT-3** → stop, confirmation humaine |
| Un fix touche des fichiers hors périmètre du plan | **HALT-5** → stop, diff, validation |
| Ressource manquante (pas de cible bootée, build impossible) | **HALT-4** → stop, rapport de blocage |

## Options de projet (à lire, pas à présumer)

- **Politique de commit/push** : certains projets interdisent le push (repo client, livraison
  différée) et/ou les mentions d'IA dans les commits. Lis `CLAUDE.md` + les rules du projet.
- **Cible & config** : bundle id, AVD, dossier de flows, dossier de rapports → tout dans la config
  du module `mobile-test` (`.vibeflow/mobile-test.json`). Rien en dur.

## Voir aussi

- Doctrine des garde-fous : `dev-orchestrator` → `references/autonomous-guardrails.md`.
- Pipeline mécanique : module `mobile-test`, skill `vf-mobile-test`.
- Pattern 12 (cloisonnement), Pattern 11 (halt), Pattern 09 (god-execution) : module `reference`.
