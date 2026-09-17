# Mission 2026-09-17 — cadrage de la Phase 41 (posture de protection du dépôt)

**Manager** : vf-dev-manager · **Branche** : `feat/phase-41-protection-depot` (depuis `origin/main`
`ade5054`, worktree isolé) · **Lancement** : feu vert Samuel, AskUserQuestion session principale,
2026-09-17 (« Oui, cadrage via vf-dev-manager »).

## Plan de bataille (DAG `dag-phase41-cadrage.json`)

`recherche-doc` → `escalade` → `context` → `revue-context`. Aucun nœud d'exécution : la mission
cadre, ne planifie pas, n'applique rien chez GitHub.

Gates de démarrage : verrou de driver acquis dans le worktree (`.planning/DRIVER.lock`, ignoré par
git, distinct du verrou de l'arbre principal) ; `check-mission-invariants.sh` → 3 (SAIN) ;
`workflow._auto_chain_active` et `workflow.auto_advance` à `false` constatés par lecture de
`.planning/config.json` (pas de `gsd_run`).

## Constats GitHub (lecture seule, `gh api` GET, 2026-09-17)

Consignés dans `41-CONTEXT.md` § Constats. Points saillants : dépôt public du compte utilisateur
`picmakpro` (seul admin) ; le compte qui merge (`samuel-neveugall`) est `write` ; deux autres
comptes `write` ; aucun ruleset ni protection ; commits directs sur `main` dont un (`892f89a`) a
rougi la CI ; `check-release-tag` est une étape sautée hors push sur `main` ; check runs sous
`github-actions` app 15368.

## Recherche documentaire (agent général, web, 2026-09-17)

Source : docs.github.com (préfixe `https://docs.github.com/en/`), RS =
`repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/`, API =
`rest/repos/rules`. Certitude : E = doc explicite, D = déduit, NT = non trouvé.

1. Rulesets branche/tag disponibles en public Free (RS about-rulesets, E). Push rulesets : Team,
   privés/internes (RS about-rulesets, E). Evaluate : Enterprise (API, E).
2. Bypass : `Integration, OrganizationAdmin, RepositoryRole, Team, DeployKey, User`,
   OrganizationAdmin non applicable aux dépôts personnels (API, E) ; `User` précis sur dépôt
   personnel : NT ; bypass write = les trois collaborateurs (permission-levels-for-a-personal-account-repository, D).
   Modes `always` / `pull_request` / `exempt` (sans audit) (RS creating-rulesets, API, E). Création :
   admin ou rôle « edit repository rules » (E). Classique : bypass réservé aux organisations
   (about-protected-branches, E).
3. Checks requis : nom de job, sans workflow/événement (RS troubleshooting-rules, E) ;
   `integration_id` optionnel, sinon tout write peut poser le statut (RS available-rules, E) ; job
   sauté = succès (`pull-requests/reference/status-checks`, E) ; workflow sauté par filtre =
   Pending bloquant (troubleshooting-required-status-checks, E) ; strict par défaut (E) ; SHA de tête
   (E) ; push direct accepté seulement si déjà vert sur une autre ref (API, E) ; doublon push +
   pull_request même SHA : lequel l'emporte NT.
4. PR obligatoire 0-10 approbations (E) ; `allowed_merge_methods` (E) ; relecteurs par chemin non
   disponibles sur dépôt utilisateur (RS available-rules, E).
5. CODEOWNERS : auteur ne s'approuve pas (E) ; owner write (about-code-owners, E) ; version de la
   base (E) ; `.github/`, racine, `docs/` (E).
6. Historique linéaire incompatible merge commits (RS available-rules, E).
7. Commits signés : plage entière de la branche de tête vérifiée (E) ; merge via API/`gh` signé : NT.
8. Tags : restrict updates/deletions + block force push, création libre si restrict creations
   décoché (E par règle, D pour la combinaison).
9. Sémantique restrict/force push (RS available-rules, E).
10. `gh pr merge --admin` : périmètre exact sous ruleset NT (cli.github.com/manual/gh_pr_merge) ;
    merge queue : organisations seulement (managing-a-merge-queue, E).
11. `POST /repos/{owner}/{repo}/rulesets` (fine-grained « Administration: write ») ; import JSON UI ;
    `GET rules/branches/{branch}` ; `bypass_actors` invisible sans droit d'écriture sur le ruleset
    (API, E/D) ; `GET rulesets/rule-suites` (`rest/repos/rule-suites`, E).
12. Protection native par fichier ici : CODEOWNERS + revue code owner seulement ; aucune protection
    dédiée aux workflows trouvée (NT).

## Escalade

Un seul message SendMessage à la session principale le 2026-09-17 : Q-0 (qui opère `picmakpro`) et
Q-1 à Q-7, options, recommandation et conséquences, plus les décisions techniques du manager.

Réponse relayée par la session principale (SendMessage), arbitrages Samuel, AskUserQuestion session
principale, 2026-09-17 : Q-0 Samuel en personne ; Q-1 bypass rôle `write` (confirmé après exposé de
la conséquence) ; Q-2 (a) ; Q-3 (a) + branche à jour oui ; Q-4 (b) ; Q-5 (a) ; Q-6 (a) ; Q-7 #78
déjà mergée, fermer #29 avant la pose. Consignés en D-01 à D-08 du CONTEXT. Le manager a tranché le
mode du bypass (`pull_request` pour la branche, `always` pour les tags — D-M12, D-M13).

**Rétractation** : le message initial annonçait « méthode de merge limitée à `merge` » comme
décision technique. Le juge frais a montré la prémisse fausse (#71 et #72 entrées par rebase) ; la
restriction est retirée (D-M2) et devient le point ouvert P-2.

## Revue

Juge frais (general-purpose, lecture seule) sur le CONTEXT avant arbitrages : `gaps_found`, 6
findings — D-M2 faux (prémisse 8/8 merge commits), #78 périmée, « se rejoue » imprécis, D-M5 non
borné + NT du doublon push/pull_request omis, D-M6 dépendant de Q-0, deux certitudes « déduit »
présentées comme explicites. Tous corrigés sur le CONTEXT (un tour). Le reste des constats vérifiés
exacts sur disque et API.

## Décompte

Mandats émis : 2 (1 chercheur, 1 juge frais). Tours de correction : 1 (manager, sur le CONTEXT).

## Suite — planification (même jour)

Relais de la session principale (SendMessage), arbitrages Samuel, AskUserQuestion session
principale, 2026-09-17 : P-1 reformuler le critère 2 (D-09), P-2 ne rien restreindre (D-10), puis
planifier. Verrou repris (`vf-dev-manager-41-plan`), DAG `dag-phase41-plan.json`.

- `gsd-planner` : 11 plans en 9 vagues, puis 13 plans en 13 vagues séquentielles après révisions.
- Vérificateur de plans frais, un agent neuf par tour :
  - tour 1 : ISSUES_FOUND, 1 bloquant (M-2/M-3 sans checkpoint de décision), 9 avertissements ;
  - tour 2 : ISSUES_FOUND, 1 bloquant de fond (force push et suppression de `main` non arbitrés),
    3 avertissements ;
  - tour 3 : ISSUES_FOUND, 0 bloquant, 3 avertissements (faux vert du ledger sur coupure de ligne,
    consigne 41-05 dépendante d'une variante, traçabilité d'arbitrage non couverte) — corrigés de
    façon ciblée, **non re-vérifiés** (budget de 3 tours atteint).
- Décisions du manager en cours de planification : `dismiss_stale_reviews_on_push` au défaut
  `false` (aucun arbitrage ne couvre `true`) ; sonde `actor_id` désactivée avant le merge de la PR
  de la phase, troisième PR de clôture, amendement d'ADR-059 limité à ce dépôt, contournement réel
  porté sur des checks en cours : validés comme techniques.
- Escalade : question force push / suppression de `main` relayée par SendMessage le 2026-09-17,
  sans réponse à la clôture de la mission → `REGLES_MAIN_FORCE_PUSH_SUPPRESSION:
  EN_ATTENTE_ARBITRAGE` dans 41-01, vérifications rouges par construction tant qu'elle n'est pas
  fixée avec canal et date.
- Remontée hors zone : `plugin/dev-orchestrator/references/mission-contracts.md:116` exempte le
  « travail conversationnel direct » de la règle de branche, contraire à D-03 sur ce dépôt mais
  couvert par la primauté du `CLAUDE.md` (l.145) ; rien planifié (hotfix v2.63.2 en cours).
- Constat annexe : ADR-071 n'a pas de ligne dans l'index de `docs/ADR.md`.

Mandats émis (planification) : 1 planificateur (1 création + 3 révisions par réveil), 3
vérificateurs frais.
