# Mandat d'origine — Cockpit : parseurs tolérants + diagnostic (vf-dev-manager)

Lancé le 2026-11-05T20:25:46.608Z (UTC) par la session pilote, interrompu par le crash machine du 2026-11-05 à 21 h 58.

## Brief d'origine (verbatim)

Mission de dev sur le dépôt ~/Documents/dev/vibeflow-os, module cockpit (plugin/cockpit/). Tu es dispatché par vibeflow-head (session principale vibeflow-os-e2).

Arbitrage : Samuel, via AskUserQuestion en session principale, le 2026-11-05. Il choisit de traiter le hotfix et le chantier de fond ensemble, en release minor.

## Bug à l'origine (reproduit en session principale)
- `plugin/cockpit/scripts/vf-cockpit-planning.mjs:49` : la regex `/\*\*(?:Depends on|Dépend de)(?::\*\*|\*\*\s*:)\s*(.*)/` n'accepte que « **Depends on:** » et « **Depends on** : ».
- `plugin/cockpit/scripts/vf-cockpit-drift.mjs:16` : la constante `DEP` a le même motif. À noter : ce fichier a déjà une constante `ESP` qui tolère les espaces, y compris insécables, avant « : » dans les titres de phase.
- Le ROADMAP de ~/Documents/dev/portfolio écrit « **Depends on :** Phase 02 (…) » (lignes 82, 115, 148). `exec` renvoie null, donc depends = [] et le graphe de l'onglet Projet n'a aucun lien.
- Le même code est dans la v2.75.1 installée et sur main (57e7957f).

## Périmètre
1. **Hotfix.** Rendre les regex de dépendances tolérantes : espace ou espace insécable ( ,  ) avant « : », que les deux-points soient dans le gras ou dehors ; gras ou non ; FR et EN ; casse ; synonymes (Depends on, Dépend de, Dépendances, Dépendance) ; puces « - Depends on: … ». Ajouter un test de non-régression qui couvre toutes ces variantes, dans la suite de tests existante du cockpit.
2. **Chantier de fond, demande de Samuel.** Le premier lancement du cockpit doit absorber les formats inattendus des plannings écrits par les IA des utilisateurs. Sinon l'installation paraît cassée.
   - Parseurs tolérants avec normalisation partagée, sur tous les champs que le cockpit lit dans .planning/ : titres de phase (« ### Phase 01: x », « ## Phase 1 — x », numérotation 01 ou 1, décimales), Goal/Objectif, dépendances, cases à cocher, statut. Faire l'inventaire des regex de plugin/cockpit/scripts/ avant de coder. Factoriser si possible plutôt que dupliquer, sans réécriture gratuite.
   - **Diagnostic** au premier assemblage, et à chaque `build --rebuild` : signaler ce qui n'a pas été reconnu (« N lignes non comprises : … », avec fichier et ligne), dans la sortie CLI et/ou dans l'interface, au lieu d'un graphe vide et muet. L'UI suit DESIGN.md, direction « Graphite ».
   - Le cockpit n'écrit **jamais** dans .planning/. Une éventuelle normalisation du planning se limite à une proposition qui demande l'accord explicite de l'utilisateur, jamais un geste automatique. Si tu juges que cette proposition de normalisation déborde la mission, rapporte-le plutôt que de l'implémenter.
3. **Recette réelle** sur ~/Documents/dev/portfolio : lancer le build cockpit depuis le code de ta branche (pas la copie installée dans ~/.claude/scripts) avec `--rebuild`, puis vérifier dans project.html (Playwright ou lecture des données générées) que les liens de dépendance 01→05 apparaissent. Ne rien écrire dans le dépôt portfolio.

## Contraintes
- Avant tout : `bash plugin/conductor/scripts/driver-lock.sh status` (il était libre au moment du dispatch), puis travailler en **worktree** sur une branche dédiée (ex. `fix/cockpit-parseurs-tolerants`). D'autres sessions travaillent sur le cockpit dans les worktrees `.claude/worktrees/phase-71-5`, `phase-72` et `phase-78` : compare les fichiers que tu touches avec leurs diffs vs main et **signale les collisions** dans ton rapport.
- Doctrine : densité ADR-029, commits en français, trailer `Gate-Touche:` si tu touches un gate, une suite surveillée ou leurs fixtures. Une preuve doit pouvoir rendre rouge : fais échouer le test de non-régression sur l'ancien code avant de le déclarer vert. Rejoue les commandes du job `gates` de `.github/workflows/ci.yml`, pas une liste de mémoire.
- Bump : VERSION du module cockpit + son CHANGELOG. Bump de la VERSION racine en minor (les trois fichiers et les deux README), avec le verrou de dépôt le temps du bump.
- **Release gatée humain** : pousse la branche et ouvre la PR. Pas de merge, pas de tag, pas de release GitHub : ces gestes reviennent à Samuel. Prépare la relecture adverse SOBR-04 (diff plus une sonde exécutée, avec commande et sortie) pour les notes de release.
- Quand le correctif est prêt à recetter, préviens la session `portfolio-a4` par SendMessage : nom de branche, commande de rebuild depuis la branche, ce qu'elle doit vérifier.
- À la fin, balaye les workers orphelins.

## Rapport attendu (compact)
Branche et PR, fichiers touchés, collisions éventuelles avec les autres worktrees, résultats des tests et des gates (commandes et sorties), recette portfolio (avant/après), points à décider par Samuel.
