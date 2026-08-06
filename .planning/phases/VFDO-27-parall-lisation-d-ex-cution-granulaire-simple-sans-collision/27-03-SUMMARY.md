---
phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 03
subsystem: conductor/agent-isolation
tags: [worktree, isolation, check-agents, frontmatter, baseRef]
status: complete
dependency-graph:
  requires: []
  provides:
    - "13 agents ecrivains non-managers declarent isolation: worktree (groupe A, D-05, ADR-064)"
    - ".worktreeinclude pose a la racine : allow-list du dossier de memoire persistante d'agent dans un worktree isole"
    - "27-ISOLATION-PORTEE.md : decision ecrite et citable (groupe B exclu, recette worktree.baseRef, 4 hypotheses ouvertes A1/A2/A4/A5, preuve de fuite de commit)"
  affects:
    - "27-04 (safe_resume_gate desormais leve — ce SUMMARY etait le manque bloquant)"
    - "27-05 (premiere occasion reelle d'observer les hypotheses A1/A2/A4/A5)"
tech-stack:
  added: []
  patterns:
    - "Precondition mecanique re-interrogee, jamais relue en prose : la tache 4 execute worktree base-check et n'arme rien si shouldDegrade != false ou reason != baseref-head (B2, correction de revue)."
    - "Lint check-agents.sh par --agents-dir= sur chacun des 6 repertoires de modules, jamais l'invocation nue (qui pointe vers .claude/agents, vide dans ce depot source — vert a vide, pas une preuve)."
key-files:
  created:
    - .worktreeinclude
    - .planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-ISOLATION-PORTEE.md
  modified:
    - .gitignore
    - plugin/business-pilot-bundle/agents/vf-business-commercial.md
    - plugin/business-pilot-bundle/agents/vf-business-delivery.md
    - plugin/business-pilot-bundle/agents/vf-business-finance.md
    - plugin/content-bundle/agents/vf-content-repurposer.md
    - plugin/content-bundle/agents/vf-content-strategist.md
    - plugin/content-bundle/agents/vf-content-writer.md
    - plugin/design-orchestrator/agents/vf-crafter.md
    - plugin/dev-orchestrator/agents/vf-coder.md
    - plugin/growth-bundle/agents/campaign-analyst.md
    - plugin/growth-bundle/agents/channel-strategist.md
    - plugin/growth-bundle/agents/copywriter-sequences.md
    - plugin/mobile-test-team/agents/vf-app-fixer.md
    - plugin/mobile-test-team/agents/vf-test-runner.md
decisions:
  - "Groupe B (6 managers/orchestrateurs) exclu de l'armement : P3 du team-kernel (un manager ne produit jamais) + re-derivation mesuree sur pièce (3 des 6 ecrivent effectivement STATE.md ou un artefact de pilotage, pas 1 seul comme l'affirmait 27-RESEARCH.md — le verdict s'en trouve renforce). Reserve A6 (agent incarne en entree de mission) ecrite, non tranchee."
  - "L'armement (tache 4) place strictement APRES le cran de surete worktree.baseRef=head — ordre restructure suite a revue (B2). La version initiale du plan armait avant ce basculement ; avec le defaut fresh reste en place, le prochain worker isole (dont vf-coder) aurait branche depuis main et perdu la branche de mission en cours, y compris celle de cette meme correction."
  - "Aucun outillage construit autour de .worktreeinclude (ni hook ni script) : poser le fichier de contenu n'est pas une reimplementation d'un mecanisme du harness (distinction ecrite dans le fichier lui-meme, cf. ADR-064)."
metrics:
  duration: "~3 sessions (interrompues), non chronometrees en continu"
  completed: "2026-08-06"
---

# Phase 27 Plan 03: Isolation worktree des agents ecrivains Summary

**13 agents ecrivains non-managers arment `isolation: worktree` apres confirmation humaine explicite
que `worktree.baseRef` resout a `"head"` — le prerequis de securite de la phase est pose, avec ses
deux manques materiels combles et sa portee ecrite.**

## Histoire reelle du plan — execution non lineaire sur plusieurs workers

Ce plan n'a **pas** ete execute par un seul worker en continu. L'ordre des evenements, tel que
reconstitue depuis les commits et le DAG de phase :

1. **Taches 1 et 2 executees** par un premier worker : `.worktreeinclude` pose (`1ec1f63`), puis
   `27-ISOLATION-PORTEE.md` ecrit avec ses 3 parties — verdict groupe B, recette `baseRef`, les 4
   hypotheses ouvertes (`da8ad8a`).
2. **Coupure reseau** — ce premier worker s'est interrompu sans avoir pu poursuivre. Son travail
   commite (taches 1-2) est reste acquis ; rien n'a ete perdu a ce stade precisement parce que
   chaque unite avait ete commitee des sa fin (discipline de commit de la mission).
3. **Reprise par un second worker**, qui a complete `27-ISOLATION-PORTEE.md` avec la preuve
   empirique de la fuite de commit decrite ci-dessous (`807db3d`), puis s'est arrete au checkpoint
   bloquant de la tache 3 (`checkpoint:human-verify`) — conformement au plan, l'armement des 13
   frontmatters ne pouvait pas s'executer avant confirmation humaine.
4. **Ratification humaine** par Samuel : `worktree.baseRef` bascule a `"head"`, et sa condition
   suspensive est remplie — le fix RCE de `dag.sh` livre (`4a532ec`) et la suite de tests verte
   (99 PASS / 0 FAIL). La tache 3 est levee par decision humaine explicite.
5. **Tache 4 executee par ce worker** (present rapport) : precondition mecanique re-verifiee
   (`worktree base-check` -> `shouldDegrade: false`, `reason: "baseref-head"`), les 13 fichiers
   armes, gate + suite verifies, commit `0e80db9`.

## Trou de procedure a consigner, pas a taire

Au moment ou le second worker a atteint le checkpoint de la tache 3, l'etat machine de
`worktree.baseRef` **etait deja** a `"head"` sur ce poste — pose par effet de bord d'un worker
anterieur, hors du perimetre de ce plan. Le gate mecanique (`worktree base-check`) etait donc deja
vert **avant toute ratification humaine pour ce plan precis**. C'est un trou reel : un reglage
global de session avait anticipe une decision que seule la tache 3 de ce plan devait faire
prononcer. `27-ISOLATION-PORTEE.md` (Partie 2) documente ce piège nommement : un gate machine vert
ne vaut pas ratification humaine pour la decision qu'il gate. La confirmation explicite de Samuel,
obtenue ensuite (evenement 4 ci-dessus), a couvert ce manque — mais la sequence aurait pu, dans un
scenario legerement different, laisser un armement s'executer sur la seule foi d'un etat machine
deja vert par accident plutot que par decision. A garder en tete pour tout futur checkpoint dont la
precondition mecanique peut etre satisfaite par un effet de bord externe au plan qui la gate.

## Fuite de commit — ce qu'elle demontre

`da8ad8a` (tache 2, ecriture de `27-ISOLATION-PORTEE.md`) porte **deux fichiers** dans son diff :
`27-ISOLATION-PORTEE.md` (attendu) et `plugin/conductor/references/team-kernel.md` (14 lignes,
propriete du plan concurrent `27-02`, pas de ce plan). Mecanisme reconstitue et verifie
(`git show da8ad8a`, contenu intact, historique non reecrit) : un `git add` isole par le worker de
`27-02` a laisse le fichier dans l'index git partage, et le `git commit` sans pathspec explicite du
worker de `27-03` l'a embarque avec lui.

Ce que ca prouve, et que `27-ISOLATION-PORTEE.md` (Partie 4) consigne : la **disjonction de
fichiers declaree** en tete d'un PLAN.md protege l'**intention** de chaque plan — quel plan a le
droit d'ecrire quel chemin — mais ne protege **rien** de ce qu'un commit reel transporte quand
plusieurs workers partagent le meme arbre de travail et le meme index git sans isolation. C'est
exactement le vecteur que ce plan lui-meme neutralise pour les 13 agents ecrivains via
`isolation: worktree` — la fuite observee ici est une demonstration en conditions reelles du
probleme que la phase entiere resout structurellement pour les dispatches futurs, pas un incident
isole sans rapport.

## Ce qui a ete livre (recapitulatif des 4 taches)

- **Tache 1** — `.worktreeinclude` pose a la racine, une entree (`.claude/agent-memory/`), en-tete
  motive (role, exclusions decidees, hypothese de syntaxe A1). Statut de `.claude/worktrees/` dans
  `.gitignore` tranche sur piece via `git check-ignore -v` : deja couvert par la regle englobante
  `.claude/`, verdict ecrit en commentaire plutot qu'une ligne d'ignore inoperante ajoutee.
- **Tache 2** — `27-ISOLATION-PORTEE.md` : verdict EXCLUSION pour le groupe B (6 managers), recette
  outillee de `worktree.baseRef` (`gsd-tools.cjs worktree set-baseref` / `base-check`), les 4
  hypotheses ouvertes A1/A2/A4/A5 chacune avec confiance et sonde d'une ligne, puis la preuve de
  fuite de commit (ci-dessus).
- **Tache 3** (checkpoint bloquant) — `worktree.baseRef` confirme a `"head"` par Samuel, condition
  suspensive (fix RCE `dag.sh` + suite verte) remplie.
- **Tache 4** — `isolation: worktree` pose sur les 13 agents du groupe A, une ligne de frontmatter
  chacun, juste apres `memory: project`. Verifie apres coup (D-13) plutot que recopie : liste
  re-derivee par lecture directe des `tools:` de chaque agent, retombant exactement sur les 13
  fichiers nommes par le plan.

## Commits

1. **Tache 1** — `1ec1f63` chore(27-03): pose .worktreeinclude et tranche le statut de .claude/worktrees/
2. **Tache 2** — `da8ad8a` docs(27-03): écrit la portée de l'isolation worktree (groupe B, baseRef, hypothèses) — *porte aussi `team-kernel.md`, fuite documentee ci-dessus*
3. **Tache 2 (complement)** — `807db3d` docs(27-03): ajoute la preuve empirique de fuite de commit (Partie 4)
4. **Tache 3** — checkpoint humain, aucun commit de fichier suivi (reglage `settings.local.json`, deja gitignore par la regle `.claude/`)
5. **Tache 4** — `0e80db9` fix(27-03): arme isolation: worktree sur les 13 agents ecrivains non-managers

## Verification

- `node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree base-check` -> `{"shouldDegrade": false, "reason": "baseref-head", ...}`.
- `grep -rl '^isolation: worktree' plugin/*/agents/*.md | wc -l` -> `13`, exactement les 13 fichiers
  nommes par le plan ; aucun des 6 managers ne porte la cle (`BAD=0`).
- `bash plugin/conductor/scripts/check-agents.sh --agents-dir=<chacun des 6 repertoires de module>`
  -> `exit 0` sur les 6, chacun listant nommement les fichiers qu'il a lintes (non-vacuite prouvee) :
  business-pilot-bundle (5), content-bundle (5), design-orchestrator (3), dev-orchestrator (4),
  growth-bundle (5), mobile-test-team (3) — total 25 fichiers lintes.
- `bash plugin/conductor/scripts/tests/test-check-agents.sh` -> 81 OK / 0 KO.
- `git diff --stat` sur le commit d'armement -> exactement 13 fichiers, une ligne ajoutee chacun.
- Invocation nue de `check-agents.sh` (sans `--agents-dir`) ecartee comme preuve : elle pointe vers
  `.claude/agents/`, vide dans ce depot source, et rend un vert a vide qui ne verifie rien des 25
  agents reels — piege identifie et documente par le mandat, confirme a l'execution.

## Deviations vs plan

- Ordre des taches restructure **avant** l'execution de ce worker, deja acte dans le PLAN.md
  lui-meme suite a une revue anterieure (B2) : le cran de surete (tache 3) precede l'armement
  (tache 4), jamais l'inverse. Ce worker n'a fait qu'executer cet ordre deja corrige.
- Aucune deviation de perimetre : les 16 fichiers declares par le plan (hors la fuite involontaire
  de `team-kernel.md`, propriete de `27-02` et non de ce plan) sont exactement ceux touches.

## Next Phase Readiness

Le `safe_resume_gate` de `27-04` etait bloque par l'absence de ce `27-03-SUMMARY.md` malgre des
commits de production existants sous le prefixe `27-03` — ce document leve ce blocage. Les 4
hypotheses ouvertes (A1/A2/A4/A5) restent a observer au premier run Workflow reel du plan `27-05`,
premiere occasion ou ce depot source cesse d'etre aveugle a un worktree d'agent effectivement
materialise.

---
*Phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Plan: 03*
*Completed: 2026-08-06*
