# Playbook de restructuration d'un projet existant (brownfield)

> Référence du skill `software-architecture`. Généralisation du plan 6 vagues validé sur le terrain.
> Principe transversal : **les gates doivent être machine-enforced** (CI bloque, lint en erreur,
> hook pre-commit), pas prescriptifs (règles écrites ignorables).

## Vague 0 — Stabilisation + fondations (AVANT tout le reste)
1. **Réparer le filet de tests d'abord.** Si la suite de tests ne s'exécute pas (versions
   runtime désalignées, config cassée), c'est la priorité absolue — sinon aucune migration n'est sûre.
2. Câbler un **Stop hook / gate** : typecheck global + détection de cycles + lint sur fichiers modifiés.
   Anti-boucle (lock-file), sortie bloquante (exit code / decision:block).
3. Écrire un CLAUDE.md court (< 100-150L) déclarant l'intention d'architecture + les garde-fous.
4. Établir une baseline (coverage chemins critiques, nombre de cycles, taille moyenne de fichier).
> Critère de sortie V0 : typecheck + lint + cycles VERTS, gate actif, baseline mesurée.

## Vague 1 — Filet de tests fonctionnel
1. Trier les tests en échec : régression de code réelle / test obsolète / test fragile.
2. Aligner les tests obsolètes sur le comportement réel (le code en place fait foi) ou les retirer/skip
   avec TODO daté.
3. Réparer les fragiles (mocks manquants, providers absents).
4. Traiter les **vraies régressions** une par une, avec soin.
5. Ajouter des E2E sur les **chemins critiques** (auth, paiement, persistance).
6. **Rebrancher les tests dans le gate** une fois la suite verte.

## Vague 2 — Cloisonnement par bounded context
1. Identifier les contextes métier (event storming / langage du domaine).
2. Créer `features/{contexte}/` et y déplacer les tranches.
3. Déclarer les frontières (eslint-plugin-boundaries) : qui importe quoi. Mode `warn` (grandfather temporaire).
4. Marquer la dette intérimaire `[DEBT:contexte]` — sert de gate pour la vague suivante.

## Vague 3 — Décomposition des god files (par priorité taille × churn)
Pour chaque god file, dans l'ordre de priorité :
1. Analyser les responsabilités.
2. Extraire chaque responsabilité dans un fichier dédié (cible < 300L, idéal 150-200L).
3. Écrire les tests des fonctions extraites AVANT de les retirer du god file.
4. Workflow sous-agents : un agent extrait + teste, un autre relit pour le risque de régression.
> Décomposer **tout, proactivement** — pas seulement quand ça fait mal.

## Vague 4 — Frontières en mode erreur
1. Passer eslint-plugin-boundaries de `warn` à `error`. Retirer le grandfather.
2. Fermer tous les marqueurs `[DEBT]` : chacun devient une règle ou une décision (DEC).

## Vague 5 — Outillage de navigation (optionnel, APRÈS décomposition)
1. Une fois le code découpé, ajouter un MCP de navigation par LSP (ex : Serena) si pertinent.
   (Inutile tant que les fichiers sont des god files.)

## Vague 6 — Gate complet + consolidation
1. Gate de taille automatisé (warn 250L / block 300-350L en CI).
2. Documenter les patterns par contexte (conventions, taille attendue, imports autorisés).
3. Suite de régression complète verte ; métriques baseline vs finale comparées.

## Protocole de reprise anti-hallucination (entre sessions)
- Un document vivant (plan + état d'avancement + verdicts verrouillés) est la source de vérité.
- Vérifier l'état RÉEL par commandes avant d'agir ; le code + git + la suite de tests font foi.
- Une vague par session pour ne pas saturer le contexte ; mettre à jour le plan en fin de session.
- Ne jamais affirmer « c'est fait » sans preuve d'exécution (exit code, fichier inspecté).
