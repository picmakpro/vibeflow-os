# Cockpit — suivre le travail en cours dans une phase (note de conception, 2026-11-03)

**Statut :** option A retenue, à implémenter dans la phase qui suit la 67, avec la refonte mobile (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Rien d'implémenté. Demande de Samuel (session principale, 2026-11-03).
Constat : sur la carte Projet, le jalon `vibeflow-v2.0` affiche « 0/2 phases · 0 % · à faire », et la
Phase 67 « à faire · 11/7 plans · 0/12 exigences », alors que ses 7 plans sont exécutés et que la
PR #187 est ouverte.

## 1. Causes, mesurées dans le code (`plugin/cockpit/scripts/`, branche `feat/v2-cockpit`)

| # | Symptôme | Cause exacte |
|---|---|---|
| C1 | Phase 67 « à faire » | `phaseStatus` (`vf-cockpit-project.mjs:36`) ne connaît que 3 cas : `ph.done` (case de ROADMAP cochée) → fait ; `ph.n === curPhase` (le `current_phase` du STATE) → en cours ; sinon → à faire. Le STATE pointe sur la 62 : les plans et la mission ne sont jamais lus pour le statut. |
| C2 | « 11/7 plans » | `sums` (`:63`) compte **tous** les `*-SUMMARY.md` du dossier. Les 4 `67-FIX-{A..D}-SUMMARY.md` (les correctifs de mission, sans PLAN) s'ajoutent aux 7 du plan : 7 + 4 = 11. Ce ne sont pas les nœuds du DAG. |
| C3 | Jalon à 0 % | Le pied (`:56`) ne compte que les phases dont la case de ROADMAP est cochée ; le statut du jalon (`:47`) vient de l'icône (`📋` → à faire) ou d'au moins une phase close. |
| C4 | La mission n'est pas rattachée à la 67 | Une mission est rattachée à une phase seulement si son DAG s'appelle `MISSION-<n>` (`:90`). Celui de la 67 s'appelle `2026-11-01-v2-cockpit.dag.json` : il tombe dans « Missions hors phase ». La règle « jalon actif dès qu'une phase a une mission active » serait donc aveugle aujourd'hui. |
| C5 | Exigences 0/12 | Elles ne sont cochées qu'à la clôture de la phase : c'est voulu, et c'est la seule vérité d'exigence. |

**Contrainte de fond :** le cockpit ne fait aucun appel réseau (recette 67, point 5). L'état d'une PR
ou de la CI n'est donc **pas lisible** : « PR ouverte » ne peut venir que d'une trace locale.

## 2. Option A : un statut de phase dérivé, dans la lib de lecture (recommandée)

Le calcul passe dans `readPlanning` (`vf-cockpit-planning.mjs`), qui sera aussi le socle de vf-signal
(Phase 68). Il expose par phase un objet versionné, `avancement` :

```json
{ "version": 1, "etat": "a-recetter", "plans": { "faits": 7, "total": 7 },
  "correctifs": 4, "mission": { "nom": "2026-11-01-v2-cockpit", "etat": "done" },
  "reste": ["recette humaine", "clôture"] }
```

- **Quatre états, chacun avec sa preuve locale :**
  - `a-faire` : aucun SUMMARY de plan ;
  - `en-cours` : au moins un plan fait, ou une mission rattachée avec un nœud `running` ;
  - `a-recetter` : tous les plans faits, phase non cochée ;
  - `fait` : case de ROADMAP cochée.
- **Décompte des plans (C2) :** un plan est fait s'il a un `*-PLAN.md` **et** son `*-SUMMARY.md`. Les SUMMARY sans PLAN deviennent une ligne à part, « 4 correctifs ».
- **Rattachement des missions (C4) :** dans l'ordre, (1) un champ `phase` du DAG s'il existe, (2) le nom `MISSION-<n>`, (3) un DAG qui se trouve dans le dossier de la phase. Le cas de la 67 se règle par (1) : une ligne dans son DAG.
- **Pied du jalon :** « 0 clos · 1 à recetter · 1 à faire · 0 % ». Le pourcentage reste strict (phases closes seulement) et n'est jamais pondéré.
- **Jalon :** il est `en-cours` dès qu'une de ses phases est `en-cours` ou `a-recetter`, quel que soit le STATE.
- **`reste` :** la liste des étapes restantes, déduite de traces locales seulement :
  - recette humaine : un `*-RECETTE-HUMAINE.md` dont le statut n'est pas « FAITE » ;
  - vérification : pas de `*-VERIFICATION.md` ;
  - clôture : case de ROADMAP non cochée.

  CI, merge et release ne sont **pas** affichés (aucune lecture réseau) ; au mieux, la release se lit depuis un tag local, à voir plus tard.
- **Retrait (un ajout = un retrait) :** on supprime la règle `ph.n === curPhase` du STATE, la seule source qui ment ici. Le STATE ne pilote plus le statut d'une phase sur la carte.
- **Témoins rouges, un par règle.** Fixtures de lab : (a) 7 PLAN, 7 SUMMARY et 4 SUMMARY de correctif → `7/7 plans · 4 correctifs` (rouge aujourd'hui : 11/7) ; (b) STATE sur une autre phase et plans faits → `a-recetter` (rouge aujourd'hui : à faire) ; (c) DAG avec `phase: 67` → rattaché à la 67 (rouge aujourd'hui : hors phase) ; (d) jalon `📋` avec une phase `a-recetter` → jalon `en-cours` (rouge aujourd'hui : à faire).

**Coût :** une vingtaine de lignes dans la lib, l'affichage existant réutilisé, 4 cas de test.

## 3. Option B : progression pondérée et exigences à trois états

A, plus :
- un pourcentage de jalon pondéré (phases closes + fraction des plans faits des phases en cours) ;
- un état d'exigence intermédiaire, « livré, non vérifié », entre « non cochée » et « cochée » : il faudrait un nouveau marqueur dans `REQUIREMENTS.md` (par exemple `- [~]`), que GSD ne connaît pas ;
- une liste d'étapes déclarée par la phase (frontmatter `etapes:` avec recette, CI, merge, release) et cochée à la main.

**Pourquoi je ne la recommande pas :**
- Le pourcentage pondéré donne une précision fausse : un plan n'est pas une unité de travail constante, et 7/7 plans ne valent pas « 95 % » d'une phase qui attend sa recette.
- `[~]` crée un second vocabulaire d'exigence, hors du moteur GSD, que `check-requirements-survival` et le moteur ignoreraient : c'est la couche de synonymes à éviter.
- Une liste d'étapes cochée à la main dérive : c'est un vert déclaré, pas lu (« aucun vert auto-déclaré ne tient »).

## 3 bis. Écarts avec la version collée par Samuel (2026-11-03)

Une version courte de cette analyse, collée par Samuel, converge sur A et sur le pourcentage strict. Mesurer le code a corrigé deux de ses points :
- **« 11/7 plans mêle plans et nœuds de mission » : faux.** Ce sont les 4 `67-FIX-*-SUMMARY.md` (C2). Un témoin « décompte faussé par un nœud DAG » serait vert dès aujourd'hui : il ne prouverait rien. Le bon témoin rouge est un SUMMARY sans PLAN.
- **« à recetter = PR ouverte » et étapes « CI, merge, release » sur la carte : non lisibles.** Le cockpit ne fait aucun appel réseau. « À recetter » se déduit donc de « tous les plans faits et phase non close », et les étapes restantes se limitent aux traces locales (recette, vérification, clôture).

## 4. Recommandation

**Option A.** Elle répond aux quatre symptômes à partir de traces que le dépôt porte déjà, elle retire la seule règle fausse (STATE → statut) et elle ne prétend jamais savoir ce qu'elle ne peut pas lire (CI, merge). B pourra revenir pièce par pièce si un besoin réel apparaît après la Phase 68.

**À trancher par Samuel avant tout code :**
1. A ou B.
2. Le lieu : un correctif rapide dans la PR #187 (avant merge), ou le cadrage de la phase qui suit la 67, avec la refonte mobile.
3. Le DAG de la 67 : ajouter `"phase": "67"` (une ligne) ou le renommer `MISSION-67`.
