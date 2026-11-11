<!-- archive du tri de 2026-11-11 : texte d'origine retiré du ROADMAP du compartiment fiabilite, tel qu'il était au blob b6062d4f7e2cad572731bc3ae488a4af0ef5f8ef (restituable par git cat-file blob b6062d4f7e2cad572731bc3ae488a4af0ef5f8ef) ; chaque marqueur « archive : » donne la section d'origine et sa ligne dans ce blob -->

<!-- archive : checklist des Phases 68, 70, 71, 71.5, 72 et 78 (lignes d'origine) (source l.119) -->
- [x] Phase 68: Embarquer vf-signal sur le socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-04 : 13/13 plans, VFSG-01..13 cochées, PR #199 mergée le 2026-11-04T17:18:25Z (`3c73fc0c`), sans release (module `cockpit` v1.2.0, bump racine reporté à la release groupée, P68-D-31)
- [x] Phase 70: Finitions UI du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04 : 12/12 plans, recette par juges frais jouée et triée par Samuel (`70-RECETTE-JUGES.md`), PR #200 mergée le 2026-11-04T21:02:38Z (`503aa657`), sans release ; au ledger, UIFN-04, 06 et 07 cochées, les onze autres exigences restent décochées (REQUIREMENTS.md)
- [x] Phase 71: Terminal intégré au cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-05 : PR #203 (`d4171ded`) et correctif Safari PR #209, recette humaine jouée par Samuel le 2026-11-05 (Arc, Firefox, Safari, clavier AZERTY, `71-RECETTE-HUMAINE.md`), TERM-01..12 cochées, sans release
- [ ] Phase 71.5: Réexamen du design system du cockpit — couleurs d'abord, puis icônes, espacements, hiérarchie des vues (INSERTED, inscrite 2026-11-05, élargie le même jour, jalon vibeflow-v2.0) — part avec la release groupée après les Phases 72 et 78
- [ ] Phase 72: Lancer du travail depuis les cartes du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git (inscrite 2026-11-05, jalon vibeflow-v2.0)

<!-- archive : Phase 71.5 (corps) (source l.500) -->

> **Inscrite le 2026-11-05, phase décimale entre la 71 et la 72, élargie le même jour.** Demande initiale de Samuel, session principale Claude Code, 2026-11-05, mot pour mot : « Je veux aussi que tu lances un VFDesign Manager tout de suite. Le but, ça sera de unslop la les paddings, etc. Et ça, on le fait partir dans une microphase 71.5. » Élargissement, même canal, même date, mot pour mot : « Je pense qu'on pourrait aussi revoir le design system de manière générale, le challenger avec Claude Design. Le but, ça serait de reprendre l'existant et de modifier en particulier les couleurs, qui je trouve ne sont pas très parlantes et assez fades selon moi. Je pense qu'on pourrait avoir quelque chose de mieux. Challenger aussi éventuellement au niveau des icônes et voilà, des paddings, de la hiérarchie des vues, de la créativité qu'on pourrait en avoir et des informations à en tirer utiles finalement. Voilà, je pense qu'on pourrait unslope un peu tout ça avec Claude Design aussi. Donc demande au design manager de le faire. » Mission portée par `vf-design-manager` ; elle part avec la release groupée, après les Phases 72 et 78.

**Plans:** mission design, plan de bataille en DAG (`.planning/missions/2026-11-05-unslop-espacements.dag.json`).

<!-- archive : Phase 72 (corps) (source l.509) -->

> **Cadrée le 2026-11-05 (`72-CONTEXT.md`, P72-D-01..19, arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-05) et planifiée le 2026-11-05** : 15 plans en 4 vagues, puis un seizième (72-16) et une cinquième vague le 2026-11-06, `files_modified` disjoints deux à deux dans chaque vague, contrats inter-plans dans `72-CONTRATS.md`, branchements dans `72-BRANCHEMENTS-MERGE.md`. Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « Oui, 69 / 71 / 72 (Recommandé) »).

**Vision de Samuel** (AskUserQuestion session principale, 2026-11-03, mot pour mot) : « Je veux aussi anticiper à l'intégration prochaine terminale et de pouvoir travailler directement dans le cockpit, c'est-à-dire que on a déjà un chat qui est prévu enfin qui est actuellement dans l'application, ils permet de poser des questions mais pas forcément de lancer du travail, il faudrait qu'on puisse aussi lancer du travail éventuellement donc ça sera l'idée d'avoir une session Claude code qui tourne dans le code une session de terminale dans l'idéal, et ça permettrait de lancer par exemple depuis les cartes ou depuis le cockpit du travail soit en cliquant sur les cartes de phase ou de mission ou peu importe. Bien sûr, il faudrait qu'on anticipe les manque, les dépendances manquantes donc ça empêcherait l'exécution, il faudrait qu'on anticipe aussi et les impossibilité voilà qu'on qu'on fasse pas de but en blanc donc ça potentiellement le chat qui permet de poser des questions permet déjà d'avoir le contexte et puis ensuite on pourrait éventuellement lancer du travail depuis le cockpit donc c'est-à-dire avec la méthode Vilo avec le Fail système qui vit qui vit littéralement sur le PC et donc il peut travailler sur les work qui peut faire des poches qui peut écrire dans des fichiers qui s'ouvre avec déjà le contexte, projets, les skis etc. cetera » (lecture de la transcription vocale : « Vilo » = VibeFlow, « Fail système » = file system, « work » = worktrees, « poches » = PR, « skis » = skills).
**Sources:** `69-CONTEXT.md` P69-D-19 et P69-D-21.
**Plans:** 16/16 plans exécutés (72-16 ajouté le 2026-11-06, non prévu au départ : P72-D-20)

Plans:

**Vague 1** (parallèle, aucun fichier commun)
- [x] 72-01-PLAN.md — Gabarit de commande, alphabet fermé, motifs, forme du prompt (LANC-05, LANC-09)
- [x] 72-02-PLAN.md — Assistant PTY : premier plan, revalidation de la ligne, écriture sans retour chariot (LANC-06, LANC-07)
- [x] 72-03-PLAN.md — Cibles lançables et pré-vols (LANC-04, LANC-08)
- [x] 72-04-PLAN.md — Mécanisme POST de P : Host, Origin exacte, jeton, schéma fermé (LANC-03)
- [x] 72-05-PLAN.md — État de Q : liste fermée, proposition unique, armement, consommation (LANC-04, LANC-07, LANC-10)
- [x] 72-06-PLAN.md — Interface des cartes servie à la volée avec `--terminal` (LANC-01, LANC-02)
- [x] 72-07-PLAN.md — Registre de suivi et rattachement à l'onglet Équipe (LANC-10)
- [x] 72-08-PLAN.md — Bandeau de proposition dans la page Q, mode retenu dans le stockage de Q (LANC-07, LANC-09)

**Vague 2**
- [x] 72-09-PLAN.md — Assemblage côté P : canal, orchestration, branchements serveur et terminal (LANC-01..04, LANC-08, LANC-10)
- [x] 72-10-PLAN.md — Assemblage côté Q : routes `/proposition`, `/lancer`, `/annuler`, IPC (LANC-04..07, LANC-09, LANC-10)

**Vague 3**
- [x] 72-11-PLAN.md — Chaîne XSS étendue jusqu'au lancement (LANC-04, LANC-05, LANC-07, LANC-09)
- [x] 72-12-PLAN.md — Bout en bout avec faux `claude` dans Chromium (LANC-05, LANC-09, LANC-10, LANC-12)
- [x] 72-13-PLAN.md — « Continuer le chat » : porte de décision sur la sonde A5, puis option (LANC-11)
- [x] 72-14-PLAN.md — Tiroir : ouvrir à l'arrivée d'une proposition (LANC-01, LANC-07)

**Vague 4**
- [x] 72-16-PLAN.md — Mode de permission retenu dans un fichier du lab tenu par Q, survit aux relances (LANC-09, P72-D-20)

**Vague 5**
- [x] 72-15-PLAN.md — Documentation et bump unique du module cockpit (LANC-12)

<!-- archive : Phase 78 (corps) (source l.618) -->

> **Cadrée le 2026-11-05** (`78-CONTEXT.md`, P78-D-01..26 ; arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-05 ). Inscrite le 2026-11-05 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Nouvelle Phase 73 « Git », en parallèle de la 72 (Recommandé) », libellé de l'option : « La numérotation se cale sur ce qu'il a déjà pris »). Les numéros 73 à 77 étant déjà réservés par la branche `docs/jalon-v2-phases-73-77` (non mergée), la phase prend le numéro 78. Exécutée en parallèle de la 72 (demande de Samuel, session principale, 2026-11-05 : « Ensuite on enchaîne […] avec un maximum de parallélisation. On enlève la restriction d'un seul manager »).

**Demande de Samuel** (session principale Claude Code, 2026-11-05, mot pour mot) : « dernier point, je remarque que le titre dans le header a droite du logo vibeflow change en fonction de si c'est Code Projet Equipe. Il faut reprend la version Code qui montre le nom du dossier, mais on doit aussi pouvoir voir le nom de la branche/worktree, mais plus habilement. Je pense qu'on revoit la partie "Vue d'ensemble / Titre / Sous titre" et le nom du projet a cote du logo. Ensuite on réflechi a une feature pour afficher un graph facon "gitgraph" pour voir ou on en est exactement dans les wt/branch. On reflechira aussi a afficher des actions et data Git du projet. Facon GitKraken. On laisse de côté la review de diff compelte pour le moment. »
**Plans:** 11 plans

Plans:

- [x] 78-01-PLAN.md — Environnement git durci (shBorne, lancerGit) et attribution des sous-agents (vague 1)
- [x] 78-02-PLAN.md — Parseurs alignés et placement des couloirs (JS pur) (vague 1)
- [x] 78-03-PLAN.md — Citation shell et commandes à copier (vague 1)
- [x] 78-04-PLAN.md — En-tête, bloc de vue, retrait de « Repositories » (vague 1)
- [x] 78-05-PLAN.md — Routes GET /api/vf/git et /entete (vague 2)
- [x] 78-06-PLAN.md — Tiroir : coquille, graphe, listes, commandes, coexistence, mobile (vague 2)
- [x] 78-07-PLAN.md — Moteur vendorisé durci (patch P27) (vague 3)
- [x] 78-08-PLAN.md — Détail de commit et état des worktrees (routes) (vague 3)
- [x] 78-09-PLAN.md — Signature Git dans le filet de 5 s, relais SSE (vague 3)
- [x] 78-10-PLAN.md — Tiroir : détail, états des worktrees, clavier, rafraîchissement (vague 3)
- [x] 78-11-PLAN.md — Bout en bout réel, chaîne XSS git, toutes les suites, bump du module (vague 4)
