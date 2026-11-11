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
- `readPlanning` pose `ph.plans = [{ id, fichier, vague }]` triés par fichier, sur toute phase (`[]` sans dossier) ; `vague` = entier >= 1 du frontmatter `wave`, sinon `null`. L'élément de plan du graphe porte `vague`.
- Contrat `cockpit-project@1` : `statuts` = `["done","active","recette","todo","blocked"]` et ligne `"optionnels": { "noeud": ["avancement","exigences"], "element": ["vague"] }` juste derrière. Seules lignes touchées du fichier (1 retirée, 2 ajoutées) ; version du fichier et nom du schéma inchangés.
- Entrée du backlog : `foot: ''` (le statut n'est plus répété au pied) ; `st` et coupe de l'intertitre inchangés.

## Commits
1. `d9971544` amendement de la l.221 du plan (`-F` au `git rev-list`)
2. `4ce3004c` test : témoins rouges PC1 + RED-TRACE
3. `c4724bce` test : PC2 à PC4, mutants, rouges tracés (dont PC3.3)
4. `fa692d4b` feat : avancement et exigences sur la phase
5. `f2efd617` feat : vague, contrat, backlog sans statut au pied

## Preuves
- `test-cockpit-projet-champs.sh` : 12 PASS / 0 FAIL (PC1.1-4, PC2.1, PC3.1-3, PC4.1, M-VIE, M-STATUTS, M-AUTRE-LIGNE).
- Mutants : M-VIE rougit PC1.4 ; M-STATUTS rougit PC3.1 (`false|true|recette`) ; M-AUTRE-LIGNE rougit PC3.3 (`2-|3+|hors-ancre`). Sur la base : ancre absente et `1-|1+|hors-ancre`.
- Non-régression sans modification : projet-graphe 119 PASS (dont P10.4), projet-croissance 1, avancement 69, signal 76, lancer-cibles 51 ; 0 FAIL, 0 sautée.
- Gabarit : project 247 lignes / 68 lignes longues (base 68) ; planning 182 / 25 (base 25) ; suite neuve sans ligne > 160 points de code.
- `check-file-size.sh` absent du worktree : tailles mesurées à la main.

## Pour les plans suivants et la jointure avec la Phase 79
- Une seule ancre dans `vf-cockpit-interface.json` (ligne `statuts` de `cockpit-project@1` et `optionnels` derrière). Aucun autre fichier partagé touché (`VENDORED.txt`, `chrome-*`, `test-cockpit-git-tiroir.sh`).
- Mutants en node seul sur copies de modules : rien à porter pour `cockpit_module_copie`.
- Ces champs se rafraîchissent au rechargement ; la relecture en direct passera par l'événement `graphe` de la 79.
- Ligne de CHANGELOG : à fournir au plan d'assemblage 80-18 (P80-D-24).

## Écarts
Aucun sur le fond. L'amendement de la l.221 est une puce datée insérée avant la ligne citée.
