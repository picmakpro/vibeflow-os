# 26-06 — SUMMARY (vague 6 : thème `05-equipe-agents`)

**Statut** : livré, gate au vert, aucun commit (D-14 respecté). Les 3 tâches du plan sont
terminées.

## Ce qui a été produit

12 fichiers de pages (6 pages × 2 langues) sous `manual/{fr,en}/05-equipe-agents/`, toutes dans la
fourchette 100-300 lignes (D-04, aucune au-delà de 3 H2) :

`pourquoi-une-equipe.md` · `les-agents-livres.md` · `une-mission-longue.md` ·
`ce-qu-on-vous-demande.md` · `branches-et-worktrees.md` · `equipes-specialisees.md`

Plus : `manual/toc.yml` (thème `05-equipe-agents` ouvert, 6 entrées `pages:`) et le parcours guidé
« je lance une longue mission » / « I'm starting a long mission » ajouté aux deux README de langue
(`manual/fr/README.md`, `manual/en/README.md`).

Total du manuel après cette vague : **32 pages × 2 langues**, 5 thèmes ouverts.

Répartition des tâches :
- **Task 1** (pages déjà écrites en 26-05, validées) — câblage seul : ouverture du thème dans
  `toc.yml`, 2 entrées `pages:`, `build-nav.sh` + `check-manual.sh`. Les deux pages
  (`pourquoi-une-equipe.md`, `les-agents-livres.md`) portaient initialement 82 à 93 lignes une fois
  les bandeaux générés — sous le plancher de 100 lignes qu'impose le `<verify>` de la tâche. Complété
  par un ajout ciblé (jamais une réécriture) : le seuil de bascule équipe/boucle directe côté
  `pourquoi-une-equipe.md`, le décompte des agents et le rôle partagé des managers côté
  `les-agents-livres.md`. Toutes deux dans 100-102 lignes après ajout.
- **Task 2** — `une-mission-longue.md` et `ce-qu-on-vous-demande.md` écrites intégralement, FR+EN.
- **Task 3** — `branches-et-worktrees.md` et `equipes-specialisees.md` écrites intégralement,
  FR+EN, plus le parcours guidé dans les deux README.

## Agents effectivement listés depuis le disque (D-11)

Compte vérifié à l'exécution, jamais recopié d'une doc existante :

- `plugin/*/agents/*.md` (glob à un niveau, exclut `content/agents/` — des blueprints, pas des
  agents livrés) : **25 fichiers**.
- `plugin/*/AGENT.md` (les 6 « visages » routeurs de haut niveau : `vibeflow-conductor`,
  `vibeflow-dev`, `vibeflow-design`, `vibeflow-validator`, `vibeflow-kpi-analyst`,
  `skill-creator`) : **6 fichiers**.
- **Total : 31 agents.**

Répartition confirmée au sein des 25 : 6 managers de mission (`vf-dev-manager`,
`vf-design-manager`, `vf-content-manager`, `vf-business-manager`, `vf-growth-manager`,
`vf-test-orchestrator`) + 19 workers/juges — cohérent avec la formulation déjà présente dans
`les-agents-livres.md` (« une bonne vingtaine »). `les-agents-livres.md` (FR et EN) cite désormais
le chiffre total (31) explicitement, daté implicitement par la formule « à la date où cette page a
été écrite » plutôt qu'un numéro de version en dur (C5).

## Points de contenu notables

- **`une-mission-longue.md`** dit sans détour que le verrou de driver **coordonne sans
  contraindre** — fait constaté sur ce dépôt (`.planning/STATE.md` : la Phase 16 a continué à
  committer pendant que la Phase 17 tenait le verrou) — et que l'allowlist d'outils du
  cloisonnement (Pattern 12) est **un contrat linté, pas un bac à sable runtime** (amendement SC3,
  `.planning/STATE.md`). Les deux limites imposées par l'« invariant supplémentaire » du plan sont
  dites, dans les deux langues.
- **`ce-qu-on-vous-demande.md`** (M-8) couvre les six points explicitement : quand on sollicite ·
  ce qui arrête (halt conditions + conflit de coordination propre à l'équipe) · mettre en pause ·
  reprendre depuis une session vierge · où atterrissent les artefacts (`.planning/`, branche, PR
  ADR-059) · ce qu'on relit avant d'accepter (renvoi à `livrer-et-relire.md` + pièce propre à la
  mission : le rapport). Renvoie vers `04-cycle-de-dev/mode-autonome.md` sans le redire.
- **`branches-et-worktrees.md`** couvre la règle ADR-059 (branche + PR laissée ouverte, jamais
  fusionnée par le manager) et la règle ADR-064 (« un écrivain = un worktree ») : ce que voit une
  session qui ouvre une seconde fenêtre sur une branche déjà pilotée (signal advisory de
  `check-branch-claim.sh`), la distinction entre ce signal advisory et le refus dur d'acquisition
  du verrou de driver entre deux managers, les gestes `git worktree add`/`remove`, et le geste de
  nettoyage après mission.
- **`equipes-specialisees.md`** couvre l'équipe design (stable, posée d'office avec
  `dev-orchestrator`), l'équipe de recette mobile (`mobile-test` + `mobile-test-team`, statut
  **explicitement expérimental**, cité verbatim depuis les deux README de module et leurs
  `module.json`) et les trois bundles métier (stables). Renvoie à
  `03-modules/bundles-metier.md` pour le catalogue sans le dupliquer — cette page traite du
  fonctionnement en équipe, l'autre du contenu du paquet.

## Dérivation depuis le disque

- Les faits ADR-053, ADR-059, ADR-060, ADR-064 viennent de `docs/ADR.md`, lus intégralement pour
  cette vague.
- Le comportement du script `check-branch-claim.sh` (codes 0/3/4/64, discriminant = arbre pas
  owner) vient de sa lecture directe (`plugin/conductor/scripts/check-branch-claim.sh`), pas d'une
  paraphrase de commentaire.
- Le comportement de refus d'acquisition du verrou de driver (`{"acquired": false, "reason":
  "held", ...}`) vient de `plugin/conductor/scripts/driver-lock.sh`.
- Les statuts « expérimental » de `mobile-test` et `mobile-test-team` sont cités depuis leurs
  README (`## Limites`) et confirmés dans leurs `module.json` respectifs — le statut mature de
  `design-orchestrator` et des trois bundles métier est confirmé par l'absence de toute mention
  équivalente dans leurs README/`module.json`.
- Le protocole de branche/PR (repli sans remote, repli sans `gh`, arbre sale = halte) vient de
  `plugin/dev-orchestrator/references/mission-contracts.md` §Isolation de branche.

## Lien désormais résolu

`04-cycle-de-dev/livrer-et-relire.md` (écrit en 26-05) renvoyait en prose, sans lien, vers « le
thème suivant » pour le détail branche/worktree, faute de page cible existante à ce moment-là.
`05-equipe-agents/branches-et-worktrees.md` existe désormais ; le lien relatif resterait à poser
dans une passe ultérieure sur `livrer-et-relire.md` si souhaité — non fait ici, hors périmètre de
ce plan (fichiers modifiés déclarés : uniquement le thème `05-equipe-agents` et les deux README).

## Vérification

- Les 3 `<verify><automated>` du plan rejoués littéralement après la dernière tâche : **tous
  passent**, y compris rétroactivement Task 1 et Task 2 (leurs liens vers des pages écrites dans
  des tâches suivantes se résolvent maintenant que le thème est complet).
- `bash manual/.tools/check-manual.sh` → **exit 0**, C0 à C6 tous ✓, **zéro avertissement** (les 4
  pages qui portaient un avertissement de fourchette 100-200 lignes en sont sorties après l'ajout
  ciblé de Task 1).
- `git status --porcelain -- manual` : **resté vide de bout en bout**, vérifié après chaque édition
  de fichier et après chaque exécution de `build-nav.sh` (qui réécrit les bandeaux langue/nav sur
  disque sans jamais toucher à l'index git, puisque `manual/` est exclu via
  `.git/info/exclude:7`).
- `git status --porcelain -- plugin docs README.md README.fr.md INSTALL.md scripts .github` :
  vide — aucune des sources lues (ADR.md, mission-contracts.md, les README de module, les scripts
  `driver-lock.sh`/`check-branch-claim.sh`) n'a été modifiée.
- `git status --porcelain` (racine, sans filtre) : vide — aucun fichier suivi par git n'a bougé,
  toute la session.
- `.git/info/exclude` non modifié (ligne 7 toujours `manual/`).
- Branche `feat/phase-26-manuel-utilisateur` inchangée du début à la fin, aucun commit créé.
