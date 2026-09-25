# Phase 41: Posture de protection du dépôt - Context

**Gathered:** 2026-09-17
**Status:** REPRISE le 2026-09-23 (accès admin constaté, D-02bis) — PRÉMISSE RENVERSÉE le 2026-09-17 — exécution ARRÊTÉE après 41-01 Task 1. Aucun droit admin dans cette session : D-01 à D-08 sont **suspendus**, les plans qui en dépendent sont **différés en attente d'accès** (§ Prémisse renversée). Un périmètre sans admin est à cadrer et à arbitrer — proposition relayée à la session principale le 2026-09-17.

<domain>
## Phase Boundary

La phase pose **une règle machine sur `main`** — côté GitHub, hors dépôt — pour qu'un gate in-repo
ne puisse plus être neutralisé depuis la PR qu'il juge, **sans casser** le flux de release du
`CLAUDE.md` (bump → PR → merge → tag annoté → release GitHub → `check-release-tag.sh --remote` ✓)
ni les hotfix urgents. Elle fait passer l'observation **O-3** du `25-SECURITY.md` (une hausse de
baseline du budget d'instructions n'est gardée que par la relecture) à « gardée par défaut + tracée » — **pas fermée**,
voir D-02.

Exigences candidates (préfixe `PROT-` libre au ledger : 0 occurrence dans `REQUIREMENTS.md`, mesuré
le 2026-09-17 en `rtk proxy grep -c`) : **PROT-01** ruleset posé et prouvé par un refus réel ;
**PROT-02** compatibilité avec la discipline de release ; **PROT-03** politique hotfix écrite ;
**PROT-04** O-3 « gardée par défaut + tracée » (CODEOWNERS + revue code owner, D-05). Transverse : **QUAL-01** si un gate naît.

**Hors périmètre** : partition du planning (Phase 39, dépôt non partitionné) ; toute réécriture des
gates existants pour « passer » ; la gestion des accès des collaborateurs (tranchée : `write` conservés, D-06) ; la protection des branches autres que `main` et des tags hors
`v*` ; le workflow `traffic-snapshot` (pousse sur `traffic-data`, jamais sur `main`).

**Nature de la phase** : l'essentiel du livrable est une **configuration GitHub externe**, posée par
un compte admin, difficilement réversible dans ses effets (une règle posée change les conditions de
toutes les PR ouvertes). Le dépôt n'en porte que la **source versionnée**, la **doctrine** et la
**preuve**. Aucun appel d'API en écriture n'a eu lieu au cadrage.
</domain>

<facts>
## REPRISE — 2026-09-23 (à lire AVANT la section du 2026-09-17, qu'elle amende)

Le **déclencheur de reprise** du `BACKLOG.md` (§ « Protection de `main` côté GitHub — DIFFÉRÉ ») est
**tombé** le 2026-09-23. Faits mesurés par la session principale (vibeflow-dev, Willy) ce jour :

1. **`picmakpro` est le compte de Willy, et il est admin du dépôt.** `gh api user` → `picmakpro`
   (id 203482067) ; `gh api repos/picmakpro/vibeflow-os --jq .permissions` → `admin: true,
   maintain: true, push: true`. Le « tiers » du 2026-09-17 est Willy, co-auteur du plugin.
2. **Collaborateurs mesurés** (`gh api repos/picmakpro/vibeflow-os/collaborators`) : `samuel-neveugall`
   (id 151974738, `write`) et `picmakpro` (id 203482067, `admin`). **`BatoEnLambo` et `Djeee8` ne sont
   plus collaborateurs** : D-06 est **sans objet**.
3. **Rulesets actuels** : `gh api repos/picmakpro/vibeflow-os/rulesets` → `[]` (longueur 0).
4. **Demande de reprise** : Samuel à Willy (WhatsApp, 2026-09-23) : « Vu que j'ai pas des droits
   admins pour clore la phase 41, tu pourrais le faire stp ? » — réponse de Willy : « Okok » ; même
   message : `check-release-tag` échoue toujours au moment du merge (le tag arrive après), **ne pas
   l'exiger avant un merge**.
5. **Feu vert d'exécution** : Willy, AskUserQuestion session principale, 2026-09-23 — « Oui,
   maintenant » (volet admin : plans différés 41-01 à 41-13).

### Arbitrage qui amende D-02 — contournement par deux utilisateurs nommés

**D-02bis** (Willy, AskUserQuestion session principale, 2026-09-23) : le contournement des deux
rulesets est accordé à **Samuel et Willy, nommément** — deux entrées `bypass_actors` de type
`User` : `samuel-neveugall` (151974738) et `picmakpro` (203482067), mode `always`. **Plus aucun
contournement par rôle** : le `RepositoryRole` `write` de D-02 est abandonné, la sonde de son
`actor_id` (41-01 Task 2) devient sans objet. Faisabilité vérifiée le 2026-09-23 dans la doc REST
des rulesets : `User` est un `actor_type` accepté, sans restriction pour les dépôts personnels
(seul `OrganizationAdmin` l'est). **À mesurer à la pose, jamais supposé** : que les deux entrées
soient bien relues depuis `GET /rulesets/{id}`.

Conséquence : la doctrine de D-02 (« garde-fou par défaut + trace, personne bloqué en urgence »)
**tient** pour Samuel et Willy ; elle ne vaut plus pour un compte `write` quelconque — il n'y en a
plus d'autre aujourd'hui. D-01 reste faux comme fait daté ; **D-03, D-04, D-05, D-07, D-08, D-09,
D-10 reprennent vie tels quels** ; D-06 sans objet ; D-04 à lire avec le point 4 ci-dessus
(`check-release-tag` n'est pas un des 4 jobs requis — à vérifier contre `CONTEXTES-CHECKS` de
`41-PREUVES.md`).

### Constat d'observabilité et révision de 41-07 / 41-08 — 2026-09-24

**Fait mesuré (41-06, `CO-VERDICT: ECART`)** : sur les trois PR de preuve (#101, #102, #103),
`mergeStateStatus=CLEAN` et `reviewDecision` vide, alors que le ruleset 23892920 exige la revue code
owner et les checks. Seule variable : `current_user_can_bypass=always`. Les deux seuls
collaborateurs du dépôt ont ce contournement (D-02bis) : **aucun acteur réel n'observe le refus par
défaut ni la revue code owner exigée.** Écart accepté et documenté (arbitrage Willy, AskUserQuestion
session principale, 2026-09-24 ; `WINDOWS.md` #9).

**Conséquence** : la précondition de 41-07 (`merge_sans_contournement=refuse`) est structurellement
inatteignable — une tentative de merge n'est permise qu'en `BLOCKED`, état qu'aucun compte ne voit.

**D-02ter** (arbitrage Willy, AskUserQuestion session principale, 2026-09-24) : **41-07 et 41-08
sont révisés pour ne prouver que le prouvable**, puis la phase continue (41-09 à 41-13) :
- ce que la machine peut établir sans observer de refus : quel run jumeau (push, pull_request)
  compte pour un check requis ; qu'une PR rouge porte bien des checks requis en échec ; la **trace**
  d'un contournement explicite dans les rule suites (merge de la #101 inoffensive, seule PR
  autorisée à atterrir) ;
- ce qui reste hors d'atteinte avec les acteurs actuels, dit tel quel : le refus par défaut vu
  depuis un compte de la liste de contournement. La preuve qu'une règle mord un acteur hors liste
  appartient à 41-09 (clé de déploiement temporaire).
Aucune tentative de merge sur une PR rouge, jamais. Le critère 2 du ROADMAP n'est pas tenu tel que
formulé ; la phase le dit, sans le réécrire.

**Correction de la prémisse — 2026-09-24** (arbitrage Willy, AskUserQuestion session principale,
2026-09-24 : « Garder, en corrigeant la prémisse ») : les phrases ci-dessus « Seule variable :
`current_user_can_bypass=always` », « aucun acteur réel n'observe le refus par défaut ni la revue
code owner exigée » et « état qu'aucun compte ne voit » sont **fausses** et ne doivent plus être
citées. Mesure de lecture seule du 2026-09-24, compte `picmakpro` (en contournement `always`) :

| PR | Auteur | Chemin CODEOWNERS touché | `mergeStateStatus` vu par `picmakpro` |
|---|---|---|---|
| #100 | `samuel-neveugall` | `.github/workflows/ci.yml` | `BLOCKED`, revue demandée à `picmakpro` |
| #101 | `picmakpro` | `.github/rulesets/README.md` | `CLEAN` |
| #102 | `picmakpro` | baseline du budget d'instructions | `CLEAN` |
| #103 | `picmakpro` | sentinelle d'armement | `CLEAN` |

Le contournement ne masque donc pas l'état bloqué. La variable discriminante observée est **l'auteur
de la PR, lui-même seul code owner** (`@picmakpro`), et non le contournement. Cette explication est
une lecture des mesures, **pas une règle documentée par GitHub** vérifiée ici. Le refus observé sur
la #100 est consigné comme **observation**, sans valeur de preuve du critère 2. Les plans révisés
41-07 à 41-13 sont conservés tels quels (D-02ter maintenu) ; 41-08 remesure ce fait au checkpoint qui
précède le merge de la #101.

## Prémisse renversée — 2026-09-17 (historique — amendée par la section REPRISE ci-dessus)

Arbitrage et constat Samuel, AskUserQuestion session principale, 2026-09-17, relayés au manager par
SendMessage le même jour :

1. **`picmakpro` n'est pas un compte de Samuel** : c'est le compte d'un **tiers**. La réponse
   consignée en **D-01** (« opéré par Samuel en personne », même canal, 2026-09-17) était **fausse**.
   **Personne, dans cette session, ne peut poser un ruleset** : `gh api repos/picmakpro/vibeflow-os
   --jq .permissions` rend `admin: false, maintain: false, push: true` (mesuré le 2026-09-17, deux
   fois, par la session principale puis par le manager).
2. **Conséquence sur les décisions** : **D-01 à D-08 sont SUSPENDUS** — non annulés, non rouverts :
   ils décrivent une posture qui exige un accès **admin** que personne n'a ici. Ils reprennent vie
   **tel quels** le jour où cet accès existe. **D-09** (libellé du critère 2) et **D-10** (méthodes de
   merge libres) ne dépendent pas de l'admin et **restent valides**.
3. **Décision de recadrage** (même canal, même date) : la phase garde ce qui est faisable avec le
   seul droit `push` ; tout ce qui exige l'admin est **différé dans une phase séparée, en attente
   d'accès**, sans rien perdre.
4. **Correction d'un fait faux, mesuré le 2026-09-17** : l'identité gh de la machine a été rapportée
   comme `Samuel-Learnity` par `gh auth status` (libellé local du compte dans la configuration gh)
   et comme `samuel-neveugall` par `gh api user`. **La source autoritative est l'API** :
   `gh api user` rend `login: samuel-neveugall`, `id: 151974738` — le même identifiant que le
   collaborateur `write` du dépôt ; `gh api users/Samuel-Learnity` rend **404**, ce nom n'existe pas
   sur GitHub (libellé périmé, compte renommé). La Task 1 de 41-01 ne s'était donc **pas** trompée
   d'identité ; c'est le libellé de `gh auth status` qui ment. Toute vérification d'identité doit
   passer par `gh api user`, jamais par `gh auth status`.

### Plans différés (accès admin requis) — rien n'est perdu

Différés tels quels, à reprendre sans réécriture le jour d'un accès admin : **41-01 Task 2 et
Task 3** (fermeture de #29, sonde d'`actor_id`, sources JSON), **41-04** (merge de la PR de la
phase sous la nouvelle règle), **41-05** (pose des rulesets, M-2), **41-06** (revue code owner),
**41-07** (M-1), **41-08** (contournement tracé, M-3), **41-09** (push direct refusé, M-4),
**41-11 à 41-13** dans leur partie « rejeu du flux de release sous la règle ». Le travail déjà
fait et commité : `41-PREUVES.md` avec `CONTEXTES-CHECKS` (les 4 contextes de checks relevés sur
les check runs 15368 d'`origin/main` 5238cba, égaux à `ci.yml`).

**Critères de succès 1, 2 et 3 du ROADMAP : inatteignables sans admin.** Ils ne sont pas réécrits
ici : leur sort est arbitré avec le nouveau périmètre.

## Constats mesurés au cadrage (2026-09-17, lecture seule)

Tous par `gh api` GET / `gh run` depuis le compte `samuel-neveugall`, sauf mention.

- **Aucune protection** : `repos/picmakpro/vibeflow-os/rulesets` → `[]` ; `rules/branches/main` →
  `[]` ; `branches/main` → `protected: false`, `required_status_checks.enforcement_level: off`. Le
  404 de l'endpoint de protection classique n'est PAS une preuve (il exige l'admin) — les deux
  lectures précédentes le sont.
- **Propriété du dépôt** : dépôt **public** d'un compte **utilisateur** `picmakpro` (pas une
  organisation). Collaborateurs : `picmakpro` **admin** ; `samuel-neveugall`, `BatoEnLambo`,
  `Djeee8` **write**. Le compte qui merge les PR (`samuel-neveugall`, 8/8 des dernières PR mergées,
  #70 à #77) **n'a pas le droit de créer un ruleset** : la pose est un geste du compte `picmakpro`.
- **Le brief « Samuel seul contributeur humain » est contredit par la liste des accès** : deux
  autres comptes ont `write` et peuvent aujourd'hui pousser sur `main`. Conservés (D-06).
- **`picmakpro`** a pour nom affiché « Le_Gouverneur_Ai » et est l'auteur de la PR **#29**
  (« Contrat de portabilité — interface de vf-portable.sh », ouverte le 2026-08-02, toujours
  ouverte). Établi depuis : opéré par Samuel en personne (D-01).
- **PR ouvertes au début du cadrage** : #78 (`chore/agent-memory-versionnee`, mission concurrente)
  et #29. **#78 a été mergée pendant le cadrage** (`7cb542e`, 2026-09-17T10:04:09Z, par
  `samuel-neveugall`) ; seule #29 reste ouverte. Toute pose de règle ferait changer les conditions
  d'une PR en vol (D-08).
- **Méthodes de merge réellement utilisées** : sur les PR #70 à #77, 6 entrées par merge commit (#70,
  #73 à #77) et **2 par rebase** (#71 `72259f4`, #72 `306e25d`) ; le tag `v2.63.0` pointe sur le
  commit rebasé `72259f4`. Constat du juge frais, 2026-09-17.
- **Source des checks** : les quatre jobs publient leurs check runs sous l'application
  `github-actions`, **`app.id` 15368** (mesuré sur les check runs de `3bedee0`). Une application
  tierce (`socket-security`, 156372) publie aussi un check sur les mêmes commits.
- **Réglages de merge** : merge commit, squash et rebase tous autorisés ; auto-merge désactivé ;
  suppression de branche au merge désactivée.
- **Des commits arrivent sur `main` sans PR** : `9331015` et `892f89a` (2026-09-16, `docs(explore)`)
  sont sur la première lignée de `main` sans être des merges. **Le run CI de `892f89a` est rouge**
  (job « Suites de tests (découverte non vide) ») — un push direct a déjà cassé `main` sans que rien
  ne l'arrête. ADR-059 (§ Options) avait **explicitement écarté** « branche pour tout travail de
  phase » : les commits directs de documentation étaient une pratique admise — D-03 y met fin.
- **CI** : un seul workflow porteur, `.github/workflows/ci.yml`, déclenché sur `push` (toutes
  branches sauf `traffic-data`) **et** `pull_request`, sans filtre de chemins ni `concurrency`.
  Quatre jobs, dont les **noms** sont les contextes de check candidats :
  1. `Suites de tests (découverte non vide)`
  2. `Gates de qualité (mode strict)`
  3. `Lab frais (install baseline + Gate C — leçon UAT 2026-07-25, F2)`
  4. `Lab frais arme (as-installed testing — le gate installe, sur un univers non vide, #38)`
- **`check-release-tag` est une ÉTAPE du job `gates`**, pas un job (`ci.yml:866-872`), gardée par
  `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`. Sur une PR ou une branche de
  feature elle est sautée ; le job reste vert. Elle rougit le job `gates` du **push de merge sur
  `main`** tant que le tag n'existe pas (mesuré : run du merge de la PR #59, `2ea1e19`, job `gates`
  en échec à l'étape check-release-tag, les trois autres verts) ; une relance après le tag est
  possible, pas systématique (ce run-là n'a jamais été relancé).
- **Surface de gate** : 30 scripts `check-*.sh` hors `tests/` sous `plugin/` et `scripts/`, 79
  suites `tests/test-*.sh` (`rtk proxy find | wc -l`), une étape CI par gate, plus les fichiers
  d'armement `.planning/.instruction-budget-armed`, `.planning/.requirements-survival-armed` et la
  baseline `.planning/instruction-budget-baselines.tsv`. Aucun `CODEOWNERS`.
- **Hooks locaux** : `scripts/hooks/pre-push` (opt-in, bloque un push vers `main` si la `VERSION`
  n'est pas taggée — résolution ancrée `--git-common-dir` après RCE démontrée) et
  `scripts/hooks/post-merge` (Phase 39). Tous deux côté client, contournables par construction.
</facts>

<decisions>
## Implementation Decisions

### Contraintes de plateforme (doc GitHub lue le 2026-09-17, docs.github.com)

Ce qui borne l'espace des options — détail et URL dans le rapport de recherche de la mission
(`.planning/missions/2026-09-17-phase41-cadrage.md`, section Recherche) :

- Rulesets de **branche et de tag** disponibles (dépôt public, GitHub Free). **Push rulesets**
  (chemins, extensions, taille) : **non** — plan Team, dépôts privés/internes. Mode **Evaluate** :
  **non** (Enterprise). **Merge queue** : **non** (organisations). Relecteurs requis par chemin
  dans un ruleset : **non** (dépôts utilisateur, pas d'équipes).
- **Bypass par rôle** (`RepositoryRole`) : sur un dépôt personnel tous les collaborateurs ont le
  même rôle `write`, donc bypasser « write » bypasse les trois. Bypass d'un `User` précis sur un
  dépôt personnel : **non documenté**. Modes : `always`, `pull_request` (PR obligatoire puis merge
  en passant outre), `exempt` (**aucune entrée d'audit**). Branch protection classique : bypass
  réservé aux organisations. « Bypasser `write` bypasse les trois collaborateurs » est **déduit**
  (tous les collaborateurs d'un dépôt personnel ont le même rôle), pas écrit tel quel dans la doc.
- **Création/modification d'un ruleset** : admin (ou rôle personnalisé) — `picmakpro` seul ici.
  Un compte `write` voit les rulesets mais **pas** `bypass_actors`.
- **Checks requis** : matchés par **nom de job**, sans tenir compte de l'événement ni du workflow ;
  évalués sur le SHA de tête de la PR ; un job **sauté vaut succès** ; un workflow sauté par filtre
  reste « Pending » et bloque ; sans `integration_id`, **tout compte write peut poser un statut
  vert** ; « branche à jour » (strict) est le défaut ; un push direct n'est accepté que si le commit
  est déjà vert sur une autre ref.
- **PR obligatoire** : 0 approbation possible ; `allowed_merge_methods` restreint merge/squash/rebase.
- **CODEOWNERS** : seul ciblage par fichier disponible ; code owner = `write` minimum ; la version
  lue est celle de la **branche de base** (une modification dans la PR ne vaut qu'après merge) ;
  l'auteur d'une PR ne peut pas l'approuver.
- **Historique linéaire** : interdit les merge commits → incompatible avec `gh pr merge --merge`.
- **Commits signés** : toute la plage de la branche de tête est vérifiée, commits d'agents non
  signés compris → bloque le merge.
- **Tags** : restrict updates / deletions + block force pushes protègent `refs/tags/v*` en laissant
  la création libre tant que « restrict creations » n'est pas coché (chaque règle est documentée,
  leur **combinaison est déduite** — à prouver à la pose par création d'un tag de test) ; mode
  `pull_request` sans objet pour les tags.
- Même job lancé deux fois sur le même SHA (`push` + `pull_request`) : la doc déconseille les noms
  ambigus mais ne dit pas **lequel des deux runs compte** pour le check requis (NT).
- `gh pr merge --admin` : ce qu'il contourne exactement sous un ruleset n'est **pas documenté** —
  à mesurer, jamais à supposer.

### Arbitrages D-01 à D-08 — SUSPENDUS depuis le 2026-09-17 (voir § Prémisse renversée)

Ils restent écrits tels quels ci-dessous : ils sont la posture visée, applicable dès qu'un accès
admin existe. Ils ne gouvernent **aucun** travail dans le périmètre sans admin. **D-09 et D-10
restent actifs.** D-01 est en outre **factuellement faux** (`picmakpro` est un tiers) : ne plus le
citer comme fait, seulement comme décision historique datée.

### Arbitrages verrouillés — NE PAS ROUVRIR (suspendus pour D-01 à D-08)

Arbitrages Samuel, **AskUserQuestion session principale, 2026-09-17**, relayés au manager par
SendMessage le même jour, consignés tels quels. Questions posées par le manager en un seul message
(options, recommandation, conséquences) le 2026-09-17.

- **D-01 (Q-0, fait)** — `picmakpro` est **opéré par Samuel en personne**. La revue code owner
  `@picmakpro` est donc une seconde main humaine, pas un agent.
- **D-02 (Q-1)** — Le bypass des rulesets est accordé au **rôle `write`**. La session principale a
  détaillé la conséquence à Samuel avant confirmation : `samuel-neveugall`, les agents qui utilisent
  ce compte, `BatoEnLambo` et `Djeee8` peuvent **tous** contourner. Réponse : « Oui, write peut
  contourner ». Doctrine retenue : **les règles sont un garde-fou par défaut et une trace, pas un
  verrou ; personne n'est bloqué en urgence.** (La recommandation du manager était le rôle admin
  seul ; elle n'a pas été retenue.)
- **D-03 (Q-2 a)** — **PR obligatoire, 0 approbation** pour toute mise à jour de `main`. Fin des
  commits directs de type `docs(explore)` ou ouverture de phase. **Amendement d'ADR-059 à
  consigner** : l'option « branche pour tout travail de phase », écartée le 2026-07-28, devient la
  règle par défaut.
- **D-04 (Q-3 a)** — **Les 4 jobs** sont requis, **épinglés sur GitHub Actions**, avec **branche à
  jour avant merge : OUI**.
- **D-05 (Q-4 b)** — **CODEOWNERS `@picmakpro`** + **revue code owner requise**, périmètre étroit :
  `.github/`, `.planning/instruction-budget-baselines.tsv`, `.planning/.*-armed`, `scripts/hooks/`.
- **D-06 (Q-5 a)** — `BatoEnLambo` et `Djeee8` **conservent `write`**.
- **D-07 (Q-6 a)** — **Ruleset de tags `v*`** : pas de réécriture, pas de suppression, pas de force
  push ; **création libre**.
- **D-08 (Q-7)** — **#78 est déjà mergée** (`7cb542e`, constat de la session principale). **Fermer
  #29 avant la pose, puis poser.**

### Conséquences de D-02 — écrites telles quelles, ne pas les adoucir (suspendues avec D-02)

- **Rien n'est « fermé » par cette phase, tout est « gardé par défaut + tracé ».** Le bypass `write`
  s'applique à **toutes** les règles du ruleset de branche, **revue code owner comprise**. Un compte
  `write` (humain ou agent) peut merger une PR rouge, non à jour, ou touchant la baseline sans
  l'approbation de `@picmakpro`, en contournant explicitement.
- **O-3 (`25-SECURITY.md`) change de statut sans se fermer** : de « procédurale, gardée par la seule
  relecture » à **« gardée par défaut + tracée »** — une hausse de baseline exige soit l'approbation
  de `@picmakpro`, soit un contournement explicite qui laisse une entrée dans les rule suites. Le
  SUMMARY et tout rapport de sécurité ultérieur doivent l'écrire ainsi, jamais « O-3 fermée ».
- **Le critère de succès 2 du ROADMAP (« une PR dont la CI est rouge ne peut pas être mergée ») est
  inatteignable au sens littéral** : tout compte qui merge aujourd'hui est `write`, donc bypass. La
  lecture compatible avec D-02 est : **refusée sans contournement explicite ; mergeable avec
  contournement explicite, et ce contournement est tracé**. Reformulation proposée à ratifier par
  Samuel (point ouvert P-1 ci-dessous) — la planification vise cette lecture et la preuve couvre les
  deux branches (D-M7).
- Le compte `picmakpro` a le rôle **admin**, pas `write` : qu'un bypass accordé au rôle `write`
  couvre aussi l'admin **n'est pas documenté** (recherche du 2026-09-17) — à **mesurer** à la pose,
  jamais supposé. Sans effet sur la sûreté : l'admin peut de toute façon désactiver un ruleset.

### Points P-1 et P-2 — RATIFIÉS

Arbitrages Samuel, AskUserQuestion session principale, 2026-09-17 (second relais SendMessage) :

- **D-09 (P-1)** — Critère de succès 2 reformulé au ROADMAP : « une PR rouge est refusée par
  défaut ; la contourner demande un geste explicite et laisse une trace dans GitHub ». Preuve en
  deux temps, comme prévu par D-M7.
- **D-10 (P-2)** — **Ne rien restreindre** : merge, squash et rebase restent autorisés
  (`allowed_merge_methods` aux trois méthodes).

Libellés d'origine des deux points, conservés pour trace :

- **P-1** — Reformulation du critère de succès 2 de la Phase 41 au ROADMAP, conséquence mécanique
  de D-02 (ci-dessus). Le manager ne modifie pas les critères de succès sans feu vert ; la
  planification prend la lecture « refus par défaut + contournement tracé ».
- **P-2** — Restreindre ou non les méthodes de merge (`allowed_merge_methods`). Par défaut la phase
  **ne restreint pas** (D-M2) ; une restriction à `merge` seul serait un changement de pratique (#71
  et #72 sont entrées par rebase) et demande un arbitrage.

### Décisions du manager (vf-dev-manager, 2026-09-17 — techniques, contestables par Samuel)

**Portée après la prémisse renversée** : D-M1, D-M4 à D-M8, D-M12, D-M13 concernent la pose d'un
ruleset — **suspendues** avec D-01..D-08. D-M2, D-M3, D-M9 (hook `pre-push`), D-M10 (ADR-072 et
`CLAUDE.md`), D-M11 (aucun gate créé) et D-M14 (gestes externes = checkpoints humains) restent
utilisables par un périmètre sans admin.

Prises sur pièce (constats et doc ci-dessus). D-M1 à D-M11 ont été transmises à la session
principale avec les questions le 2026-09-17 ; D-M7, D-M9 révisées et D-M12 à D-M14 ajoutées après
réception des arbitrages.

- **D-M1 — Rulesets, pas la branch protection classique.** Seuls les rulesets offrent une liste de
  bypass sur un dépôt personnel, sont lisibles par tout lecteur (`rules/branches/main`) et
  exportables en JSON.
- **D-M2 (corrigée par le juge frais, 2026-09-17) — Pas d'historique linéaire ; méthodes de merge
  NON restreintes.** L'historique linéaire interdirait les merge commits (6 des 8 dernières PR, #70,
  #73 à #77). La restriction à `merge` seul, d'abord retenue sur la prémisse « 8/8 en merge commit »,
  est **retirée** : la prémisse était fausse (#71 et #72 sont entrées par rebase, et `v2.63.0` pointe
  sur `72259f4`, un commit rebasé), et un tag posé après merge vise le commit qui atterrit quelle que
  soit la méthode. Restreindre changerait une pratique en usage — hors du champ technique du
  manager, voir P-2. `allowed_merge_methods` reste aux trois méthodes.
- **D-M3 — Pas de commits signés.** Aucune clé de signature n'existe côté agents ; la règle
  bloquerait toute PR produite par une mission.
- **D-M4 — Checks requis épinglés sur `integration_id` 15368** (GitHub Actions, mesuré), noms de
  job recopiés à l'identique depuis les check runs, jamais retapés. Sans épinglage, un compte write
  peut poser un statut vert du même nom. **Inconnu à mesurer avant la pose** : chaque branche de PR
  déclenche les 4 jobs deux fois sur le même SHA (`push` + `pull_request`) ; lequel des deux runs
  compte pour le check requis n'est pas documenté (NT) — le plan prévoit une mesure, ou la
  suppression du doublon dans `ci.yml` si elle s'impose (alors QUAL-01 s'applique à ce changement).
- **D-M5 — `check-release-tag` reste inchangé.** Pour une PR **mergée via GitHub** il ne bloque
  rien : l'étape est sautée sur `push` de branche comme sur `pull_request` (job vert), aucun job n'a
  de `needs:` ni de `if:` au niveau job, les checks requis sont évalués sur le SHA de tête de la PR,
  et le commit de merge a un SHA neuf. Le rouge du push de merge sur `main` reste le signal « tag à
  poser » ; le relancer après le tag est **possible, pas systématique** (le run du merge de la PR
  #59, `2ea1e19`, n'a jamais été relancé : `main` garde une croix sur ce commit). **Borne** : le
  raisonnement suppose qu'aucun SHA n'atteint `main` par push direct — tenu par D-03 et D-M12 ; un
  `git push <sha-vert>:main` d'un compte qui contournerait donnerait à ce SHA un run Gates rouge,
  qui deviendrait le plus récent pour toute PR dont la tête est ce SHA.
- **D-M6 — Source versionnée, pose humaine.** Le JSON de chaque ruleset vit dans le dépôt (chemin
  exact au plan, sous `.github/`, donc sous CODEOWNERS par D-05) ; la pose est un **checkpoint
  humain** exécuté par `picmakpro`, opéré par Samuel en personne (D-01)
  (import UI ou `gh api` POST avec son jeton) — aucun agent de la phase n'a ce droit, et aucun ne
  doit l'avoir. Pas de mode Evaluate : actif d'emblée ; **retour arrière = repasser le ruleset en
  `disabled`**, écrit dans le plan avant la pose.
- **D-M7 (révisée après D-02) — Preuve à deux branches** (critère 2, lecture P-1) sur une PR jetable
  dont la CI est volontairement rouge : **(i) refus par défaut** — `gh pr merge --merge` **sans**
  option de contournement par `samuel-neveugall` est refusé, message capturé ; **(ii) contournement
  tracé** — le même merge **avec** contournement explicite n'est **pas** exécuté sur la PR jetable
  (elle ne doit jamais atterrir sur `main`) : la preuve de trace se fait par lecture des rule suites
  (`GET /repos/{owner}/{repo}/rulesets/rule-suites`) sur un contournement réel. La PR de la phase
  ne peut pas servir : elle est mergée **avant** la pose (D-M14). Le plan choisit le support (par
  exemple une PR de preuve au contenu inoffensif, mergée en contournant sous checkpoint humain) ;
  à défaut, la trace reste déclarée **non prouvée**, jamais supposée.
  PR jetable fermée sans merge, branche supprimée, références au SUMMARY. Ce que contourne
  `gh pr merge --admin` pour un compte bypass est **mesuré**, pas supposé. Même preuve à deux
  branches pour la revue code owner (PR jetable touchant `.github/`).
- **D-M8 — Rejeu du flux de release sur la propre release de la phase** (patch : durcissement) —
  critère 3. Le ship reste un geste gaté par Samuel.
- **D-M9 (révisée après D-02) — Hook `pre-push` conservé tel quel.** Sous D-03 le serveur refuse le
  push direct sur `main` sans contournement ; le hook reste la seule garde de discipline de release
  côté client pour un compte qui contournerait en poussant directement — il n'est donc pas
  redondant et n'est pas retiré.
- **D-M10 — Politique hotfix** écrite dans un **ADR-072** (numéro libre, ADR-071 est le dernier) et
  résumée dans `CLAUDE.md` § Discipline de release ; l'item BACKLOG « Posture de protection de
  `main` » est fermé par renvoi.
- **D-M11 — QUAL-01** : la phase ne crée **aucun** gate script (CODEOWNERS et rulesets sont de la
  configuration, pas des gates) et le dit au SUMMARY. À revoir si Samuel retient un contrôle de
  dérive (voir Deferred).
- **D-M12 — Mode du bypass de branche : `pull_request` (« For pull requests only »), jamais
  `always` ni `exempt`.** Motif : c'est la seule lecture qui tient D-02 **et** D-03 ensemble. Tous
  les comptes qui poussent sont `write` : en `always`, chacun pourrait pousser directement sur
  `main` et D-03 (PR obligatoire) serait vide de sens ; en `exempt`, aucune trace — contraire à la
  doctrine « trace » de D-02. `pull_request` ne bloque personne en urgence (une PR s'ouvre et se
  merge en contournant dans la minute) et garantit que chaque contournement porte une PR et une
  entrée de rule suite. Ne va pas au-delà de D-02 : le droit de contourner est entier, seule sa
  forme est fixée.
- **D-M13 — Mode du bypass du ruleset de tags : `always`, rôle `write`.** Le mode `pull_request` n'existe
  pas pour les tags (doc API) ; `exempt` supprimerait la trace. Application uniforme de D-02 : un
  tag `v*` erroné se corrige par contournement explicite et tracé. **Contestable** : l'autre lecture
  (aucun bypass sur les tags, correction par désactivation du ruleset par `picmakpro`) est plus
  stricte que D-02 ne le demande — non retenue.
- **D-M14 — Gestes externes = checkpoints humains à l'exécution, pas au cadrage** : fermeture de
  la PR #29, pose des deux rulesets (branche, tags), pose effective de `CODEOWNERS` sur `main` (qui
  passe par la PR de la phase — CODEOWNERS n'agit qu'une fois sur la branche de base), essais de la
  PR jetable. Ordre imposé : #29 fermée → PR de la phase (CODEOWNERS, JSON, doctrine) mergée →
  rulesets posés → preuves → release. Poser les rulesets **avant** le merge de la PR de la phase
  la ferait passer sous ses propres règles en vol (motif même de la séquence de la Phase 41).

### Claude's Discretion

- Découpage en plans et vagues ; forme exacte des JSON de rulesets (`~DEFAULT_BRANCH` ou
  `refs/heads/main`).
- Rédaction de l'ADR-072 et du résumé `CLAUDE.md`, dans les limites des arbitrages.
- Contenu exact de la PR jetable de preuve (la CI doit rougir pour une raison triviale et
  réversible, jamais en modifiant un gate).
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` § Phase 41 — objectif, critères de succès 1-4.
- `.planning/BACKLOG.md` § « Posture de protection de `main` — TRANCHÉ » — cahier des charges.
- `.planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-SECURITY.md` — O-3
  (T-25-16 procédurale), renvoyée à la 41.
- `CLAUDE.md` § Discipline de release — flux bump → merge → tag → release → `check-release-tag`.
- `docs/ADR.md` § ADR-059 — mission sur branche + PR, merge humain ; commits directs de phase
  explicitement non couverts.
- `.github/workflows/ci.yml` — les quatre jobs, l'étape `check-release-tag` (l. 866-872).
- `scripts/check-release-tag.sh`, `scripts/hooks/pre-push`, `scripts/hooks/post-merge`.
- `.planning/missions/2026-09-17-phase41-cadrage.md` — rapport de mission, recherche documentaire
  sourcée (URL par affirmation).
- Doc GitHub (lue le 2026-09-17) : `repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/`
  (about-rulesets, available-rules-for-rulesets, creating-rulesets-for-a-repository,
  troubleshooting-rules) ; `rest/repos/rules` ; `rest/repos/rule-suites` ;
  `pull-requests/reference/status-checks` ; about-code-owners ; `https://cli.github.com/manual/gh_pr_merge`.
</canonical_refs>

<deferred>
## Deferred Ideas

- **Contrôle de dérive ruleset réel ↔ JSON versionné en CI** : un `GET` est possible, mais un jeton
  `write` ne voit pas `bypass_actors` — le contrôle serait vert à vide sur la partie la plus
  sensible. À rouvrir seulement avec un jeton lecture-admin dédié, et alors sous QUAL-01.
- **Garde machine d'une hausse de baseline indépendante de GitHub** (commit-trailer d'arbitrage
  exigé par un gate) : neutralisable par la même PR tant que le workflow n'est pas lui-même sous
  CODEOWNERS — ne vaudrait que combinée à D-05, et resterait contournable par D-02.
- **Signature des commits** (agents compris) : exige une infrastructure de clés, hors phase.
- **Passage en organisation** (merge queue, bypass par équipe, relecteurs par chemin, push rulesets
  en plan Team) : changement de propriété du dépôt, hors phase.
- **Sort de la PR #29** au-delà de sa fermeture avant la pose (D-08) : contenu non instruit ici.
</deferred>
