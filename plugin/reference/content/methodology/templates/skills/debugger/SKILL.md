---
name: debugger
description: Debugging systematique en 4 phases (Reproduire, Identifier cause racine, Fixer, Verifier). Iron Law "ALWAYS FIND ROOT CAUSE BEFORE ATTEMPTING FIXES" — interdit les correctifs aleatoires. Utiliser pour tout bug, erreur, comportement inattendu, ou regression. Trigger quand un test echoue de maniere inexpliquee, quand l'utilisateur signale un comportement bizarre, ou quand un agent doit comprendre pourquoi quelque chose ne marche pas. Documente la chaine d'hypotheses eliminees dans BLOCKERS.md.
---

# Skill : Debugger

## Role

Resoudre systematiquement les bugs, erreurs et comportements inattendus en identifiant la cause racine AVANT toute tentative de correction. Documenter le processus pour capitalisation.

## Regle Fondamentale

**JAMAIS de correction sans investigation de la cause racine.**

Les correctifs aleatoires :
- Masquent les problemes sous-jacents
- Creent de nouveaux bugs
- Font perdre du temps
- Empechent l'apprentissage

## Quand l'utiliser

- Echec de test (unitaire, integration, E2E)
- Bug en production ou en developpement
- Comportement inattendu d'une feature
- Probleme de performance inexplique
- Echec de build ou d'integration
- **Specialement critique** : sous pression temporelle, apres 2+ tentatives ratees, quand "la solution semble evidente"

## Protocole de Travail

### Phase 0 : Recherche Documentaire (préalable obligatoire conditionnel)

**Objectif** : trouver une cause CONNUE avant de tâtonner. Un bug de lib/framework/natif/version a
souvent une issue GitHub ou une note de version qui le documente — la chercher coûte quelques
minutes, la deviner coûte des cycles (ADR-045, prolonge LRN-106 « Audit avant fix »).

**Déclencheurs (l'un suffit)** :
- Le bug implique une **dépendance tierce**, une **API de framework**, du **code natif**, ou son
  apparition **dépend d'une version d'OS / de SDK**.
- Un **correctif a déjà échoué** sur le même symptôme (≥ 1 tentative infructueuse).

**Action** :
1. **context7** — `resolve-library-id` puis `query-docs` sur la/les lib(s) : comportement documenté,
   breaking changes, correctifs postérieurs.
2. **WebSearch / WebFetch** — issues GitHub (numéro, statut, **versions affectées ET corrigées**),
   release notes, compatibilité OS/SDK. Chercher l'erreur exacte entre guillemets.

**Si tu n'as PAS d'outil web** (`WebSearch`/`WebFetch`/context7 absents de ton contexte) : ne devine
pas. **Remonte `doc-research-required`** avec la question précise à l'orchestrateur qui, lui, a le
web, et arrête-toi (miroir de la règle anti-triche « rien committé, explique »).

**Anti-thrash** : cette phase **précède** les tentatives et ne consomme pas une des « 3+ tentatives »
de fix (Phase 4), mais compte dans le budget global temps/tokens. On ne passe en empirique
(Phase 1) que si la recherche ne donne rien.

**Sortie Phase 0** : pistes **priorisées et sourcées** (fix robuste → contournement → hack fragile,
tout hack à faire arbitrer avant application, ADR-031), OU « rien de documenté → passage en
investigation empirique ».

---

### Phase 1 : Investigation de la Cause Racine

**Objectif** : Comprendre le QUOI et le POURQUOI avant d'agir.

1. **Lire les messages d'erreur completement**
   - Ne jamais survoler — chaque detail compte
   - Noter : numero de ligne, fichier exact, code d'erreur, stack trace

2. **Reproduire de maniere consistante**
   - Etapes exactes pour declencher le bug
   - Si non reproductible → rassembler plus de donnees (logs, metriques)

3. **Verifier les changements recents**
   - `git log --oneline -10` + `git diff HEAD~3..HEAD`
   - Qu'est-ce qui a change qui pourrait causer cela ?

4. **Rassembler les evidences (systemes multi-composants)**
   - Logger les donnees a l'entree/sortie de chaque frontiere de composant
   - Executer une fois pour identifier OU ca casse
   - Puis isoler le composant defaillant

5. **Tracer le flux de donnees**
   - Ou la mauvaise valeur apparait-elle ?
   - Remonter la stack jusqu'a la source originale

**Sortie Phase 1** : Une description factuelle du probleme avec evidence (logs, fichier:ligne, donnees observees).

---

### Phase 2 : Analyse de Patterns

**Objectif** : Identifier les differences entre ce qui marche et ce qui ne marche pas.

1. **Trouver des exemples fonctionnels**
   - Chercher du code similaire dans la meme codebase qui fonctionne
   - Quelles sont les differences ?

2. **Comparer avec des implementations de reference**
   - Lire la doc officielle completement (pas en diagonale)
   - Verifier les exemples canoniques

3. **Lister toutes les differences**
   - Chaque difference est une hypothese potentielle

4. **Comprendre les dependances**
   - Quels composants, settings, assumptions sont requis ?
   - Lesquels sont absents ou mal configures ?

**Sortie Phase 2** : Liste de differences identifiees entre etat fonctionnel et etat casse.

---

### Phase 3 : Hypothese et Test

**Objectif** : Tester une hypothese claire avec un changement minimal.

1. **Formuler UNE hypothese**
   - Format : "Je pense que X est la cause racine parce que Y"
   - Etre explicite : si incertain, dire "Je ne comprends pas X" plutot que deviner

2. **Tester minimalement**
   - UN SEUL changement a la fois
   - Pas de bundle de correctifs "au cas ou"

3. **Verifier avant de continuer**
   - Si ca marche → passer a Phase 4
   - Si ca ne marche pas → formuler nouvelle hypothese et retester
   - **Ne pas ajouter d'autres correctifs par-dessus un echec**

4. **Strategie quand bloque**
   - Revenir a Phase 1 avec plus de logging
   - Demander de l'aide (pair programming, escalation)
   - Admettre l'ignorance plutot que pretendre comprendre

**Sortie Phase 3** : Hypothese confirmee OU nouvelle hypothese a tester.

---

### Phase 4 : Implementation

**Objectif** : Corriger proprement avec verification complete.

1. **Creer un test case qui echoue**
   - Reproduction la plus simple possible
   - Automatisee si possible (sinon, steps manuels clairs)

2. **Implementer UN SEUL correctif**
   - Adresser la cause racine uniquement
   - Pas d'ameliorations bundlees ("tant qu'a faire...")

3. **Verifier le correctif**
   - Le nouveau test passe
   - Aucun autre test ne casse (regression)
   - Le comportement attendu est retabli

4. **Pattern critique : Regle des 3+ echecs**
   - Si 3 correctifs ou plus echouent consecutivement → **STOP**
   - Cela indique un probleme architectural, pas un bug de code
   - Escalader : discuter avec l'equipe, revoir le design

**Sortie Phase 4** : Bug resolu, tests au vert, cause racine documentee.

---

## Red Flags — Retour Immediat a Phase 0/1

Si l'une de ces pensees apparait, STOP et revenir a la phase adequate :

- "Correctif rapide pour l'instant, j'investiguerai plus tard"
- "Je vais juste essayer de changer X et voir si ca marche"
- "Je vais sauter le test, je verifierai manuellement"
- "Encore une tentative" (apres 2+ echecs deja)
- "C'est surement un bug de version, je vais contourner" **sans avoir lu l'issue / la note de
  version** → retour **Phase 0** (recherche documentaire d'abord)
- Chaque correctif revele de nouveaux problemes ailleurs → probleme architectural

Ces signaux indiquent qu'on a saute l'investigation. Le debug aleatoire est TOUJOURS plus lent que le debug systematique.

---

## Integration avec le Projet

### Documentation obligatoire

Apres resolution, creer ou mettre a jour :

#### `.claude/memory/BLOCKERS.md`

Si le bug a pris > 30 min ou etait bloquant :

```markdown
## BLK-XXX : [Titre Court du Bug]

**Date** : YYYY-MM-DD
**Statut** : Resolu
**Temps Passe** : [Xh]
**Severite** : Critique | Haute | Moyenne

### Symptome
[Ce qu'on observait]

### Contexte
[Ce qu'on faisait quand c'est arrive]

### Cause Racine
[Pourquoi ca s'est produit — Phase 1 + 2]

### Solution
[Le correctif applique — Phase 4]

### Prevention
[Comment eviter que ca revienne]
```

#### `.claude/memory/LEARNINGS.md`

Si le bug a revele un pattern reutilisable :

```markdown
## LRN-XXX : [Pattern Identifie]

**Date** : YYYY-MM-DD
**Categorie** : Debug | Architecture | Tooling
**Decouvert lors de** : Resolution bug [reference BLK-XXX]

### Situation
[Contexte du bug]

### Apprentissage
[Ce qu'on a appris qui change notre facon de faire]

### Application
[Comment on l'applique desormais]

### Impact
[Effet concret]
```

---

## Techniques Avancees

### Root Cause Tracing

Remonter la stack trace jusqu'au declencheur original :
1. Noter ou l'erreur apparait (effet)
2. Identifier l'appel qui a cause cette erreur
3. Remonter d'un cran : qu'est-ce qui a appele ca ?
4. Continuer jusqu'a la source originale (ex: input utilisateur, config, data externe)

### Defense in Depth

Apres avoir corrige la cause racine, ajouter des validations multi-couches :
- Validation a l'entree (input sanitization)
- Assertions au milieu (invariants respectes)
- Gestion d'erreur a la sortie (fail gracefully)

### Condition-Based Waiting

Remplacer les `setTimeout()` arbitraires par du polling de conditions :
```javascript
// Mauvais
await sleep(5000) // espere que ca sera pret

// Bon
await waitForCondition(() => element.isReady(), { timeout: 5000 })
```

---

## Sortie Attendue

```markdown
## Debug Session : [Titre Bug]

**Date** : YYYY-MM-DD
**Duree** : [Xh]
**Statut** : Resolu | En cours | Escalade

### Phase 1 : Cause Racine
- **Symptome** : [Description factuelle]
- **Evidence** : [Logs, fichier:ligne, data observee]
- **Hypothese initiale** : [Ce qu'on pense]

### Phase 2 : Patterns
- **Exemple fonctionnel** : [Reference qui marche]
- **Differences identifiees** : [Liste]

### Phase 3 : Tests
- **Hypothese testee** : [X est la cause parce que Y]
- **Resultat** : [Confirme | Infirme]
- **Iterations** : [Nombre de tentatives]

### Phase 4 : Resolution
- **Correctif applique** : [Description + commit SHA]
- **Tests** : [Statut tests]
- **Prevention** : [Ce qui a ete ajoute pour eviter recurrence]

### Documentation
- [ ] BLOCKERS.md mis a jour (si > 30 min)
- [ ] LEARNINGS.md enrichi (si pattern reutilisable)
- [ ] Tests ajoutes ou renforces
```

---

## Regles

- **Jamais de correctif sans cause racine** — Regle fondamentale inviolable
- **Un seul changement a la fois** — Impossible d'isoler ce qui a marche sinon
- **Tests obligatoires** — Phase 4 ne se termine pas sans verification
- **Capitalisation obligatoire** — Un bug resolu sans documentation est un bug qui reviendra
- **Strategie d'escalation claire** — Apres 3+ echecs, c'est l'architecture qu'il faut questionner
- **Admission d'ignorance > pretendre comprendre** — "Je ne sais pas" est une reponse valide

---

## Metriques d'Impact (obra/superpowers)

| Metrique | Approche aleatoire | Approche systematique |
|----------|--------------------|-----------------------|
| Temps moyen de resolution | 2-3 heures | 15-30 minutes |
| Taux de succes au 1er essai | 40% | 95% |
| Nouveaux bugs introduits | Frequent | Quasi-zero |

Le debug systematique est **4-8x plus rapide** que le guess-and-check thrashing.
