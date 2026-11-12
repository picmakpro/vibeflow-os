---
phase: 80
plan: "03"
subsystem: cockpit-projet
requirements-completed: [FORM-06, FORM-07]
key-files:
  modified:
    - plugin/cockpit/scripts/vf-cockpit-planning.mjs
    - plugin/cockpit/scripts/vf-cockpit-project.mjs
    - plugin/cockpit/scripts/vf-cockpit-interface.json
  created:
    - plugin/cockpit/scripts/tests/test-cockpit-projet-champs.sh
    - .planning/workstreams/fiabilite/phases/VFDO-80-trois-onglets-trois-formes-projet-en-couloirs-clavier-naviga/80-03-RED-TRACE.md
duration: non mesurée
---

# 80-03 — champs structurés du graphe Projet

## Livré
- `compteExigences(reqs) -> { faits, total }` : une seule fonction, utilisée par `piedExigences` (texte inchangé) et par le champ `exigences`.
- Nœud de phase : `avancement { version, etat, plans {faits,total}, correctifs, reste, mission }` avec `mission` réduite à `{ nom, etat }` (A25 : aucune clé de verrou dans `cockpit-project@1`) ; `exigences { faits, total }` (`{0,0}` sans exigence). `foot` et `st` inchangés.
- `readPlanning` pose `ph.plans = [{ id, fichier, vague }]` triés par fichier, sur toute phase (`[]` sans dossier) ; `vague` = chiffres décimaux >= 1 du frontmatter `wave` (ni `0x10` ni `1e1`), sinon `null`. L'élément de plan du graphe porte `vague`.
- Contrat `cockpit-project@1` : `statuts` = `["done","active","recette","todo","blocked"]` et ligne `"optionnels": { "noeud": ["avancement","exigences"], "element": ["vague"] }` juste derrière. Seules lignes touchées du fichier (1 retirée, 2 ajoutées) ; version du fichier et nom du schéma inchangés.
- Une seule règle de plans faits : `avancement.plans.faits` et le pied d'une phase cochée comptent comme le statut de l'élément de plan (« 3/3 plans » sur une phase cochée avec un plan sans SUMMARY). Exception assumée à « foot inchangé » (amendement du 2026-11-12) ; `avancement.mjs` non touché.
- Entrée du backlog : `foot: ''` (le statut n'est plus répété au pied) ; `st` et coupe de l'intertitre inchangés.

## Commits
1. `d9971544` amendement de la l.221 du plan (`-F` au `git rev-list`)
2. `4ce3004c` test : témoins rouges PC1 + RED-TRACE
3. `c4724bce` test : PC2 à PC4, mutants, rouges tracés (dont PC3.3)
4. `fa692d4b` feat : avancement et exigences sur la phase
5. `f2efd617` feat : vague, contrat, backlog sans statut au pied
6. `393cb27e` test (correction de revue) : PC1.5 sur fixture asymétrique, PC1.1 à 2 sur 3, PC2.2, six mutants ; PC2.2 et M-VAGUE rouges à ce commit
7. `86084b1c` fix : `vague` exige `/^\d+$/` puis >= 1
8. `77f329ba` test + amendement du 2026-11-12 au plan : PC6.1 rouge avant (obtenu `{faits:2,total:3}|3|2/3 plans`)
9. `856bf6fd` fix : une seule règle de plans faits (`plansFaits`, prédicat du statut de l'élément : SUMMARY ou phase cochée), reprise par `avancement.plans.faits` et le pied « N/M plans » ; constat du témoin PL2.10 de 80-07 (`1857a51d`)

## Preuves
- `test-cockpit-projet-champs.sh` : 21 PASS / 0 FAIL (PC1.1-5, PC2.1-2, PC3.1-3, PC4.1, PC6.1 et neuf mutants ; M-PLANS repointé sur `plansFaits`).
- Mutants de la correction de revue : M-PLANS, M-CORR, M-VERS, M-ETAT rougissent PC1.5 (phase 1 plan sur 3, un correctif, version 2) ; M-EXIG (`!r.done`) rougit PC1.1 (exigences 2 sur 3) ; M-VAGUE (`Number(w)`) rougit PC2.2 (`[16,10,null,3]`).
- Mutants initiaux : M-VIE rougit PC1.4 ; M-STATUTS rougit PC3.1 (`false|true|recette`) ; M-AUTRE-LIGNE rougit PC3.3 (`2-|3+|hors-ancre`). Sur la base : ancre absente et `1-|1+|hors-ancre`.
- Non-régression sans modification : projet-graphe 119 PASS (dont P10.4), projet-croissance 1, avancement 69, signal 76, lancer-cibles 51 ; 0 FAIL, 0 sautée. Rejoués après les corrections : projet-graphe 119, signal 76, projet-liste 46 (PL2.10 vert).
- Gabarit : project 250 lignes / 68 lignes longues (base 68) ; planning 184 / 25 (base 25) ; suite neuve (255 lignes) sans ligne > 160 points de code.
- `check-file-size.sh` absent du worktree : tailles mesurées à la main.

## Pour les plans suivants et la jointure avec la Phase 79
- Une seule ancre dans `vf-cockpit-interface.json` (ligne `statuts` de `cockpit-project@1` et `optionnels` derrière). Aucun autre fichier partagé touché (`VENDORED.txt`, `chrome-*`, `test-cockpit-git-tiroir.sh`).
- Mutants en node seul sur copies de modules : rien à porter pour `cockpit_module_copie`.
- Ces champs se rafraîchissent au rechargement ; la relecture en direct passera par l'événement `graphe` de la 79.
- Ligne de CHANGELOG : à fournir au plan d'assemblage 80-18 (P80-D-24).

## Écarts
Aucun sur le fond. L'amendement de la l.221 est une puce datée insérée avant la ligne citée.
