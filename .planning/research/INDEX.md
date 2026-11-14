# Index des recherches tierces

Créé le 2026-11-05 au tri du BACKLOG racine (arbitrage Samuel, AskUserQuestion session principale,
2026-11-05 : « Recherches tierces à l'index »). Il porte les études de projets tiers déjà investiguées, **sans
rien d'engagé**, qui étaient trois entrées du BACKLOG (fusion F7). Une ligne par étude : le rapport, le
verdict, ce qui reste à arbitrer, le déclencheur de reprise. Le texte intégral des trois entrées d'origine
est archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

Ce fichier ne couvre que ces études tierces : les autres études du dossier (parallélisation, workstreams,
WKTR-02…) ne s'y trouvent pas.

## Qualité de code : Ponytail, pstack, thermo-nuclear review (investigué 2026-10-10)

- **Rapport :** `.planning/research/2026-10-10-qualite-code-tiers-etude.md` ; annexes A1 à A7 dans `.planning/research/2026-10-10-qualite-code-tiers/`.
- **Sources :** [Ponytail](https://github.com/DietrichGebert/ponytail) (prompt anti sur-ingénierie, seule source mesurée : −10 % de tokens de sortie, qualité non significative), [pstack](https://github.com/cursor/plugins/tree/main/pstack) et son [portage Claude Code](https://github.com/michael-denyer/pstack-claude), la grille « thermo-nuclear code quality review » de Cursor.
- **Verdict :** rien à installer. Le trou le mieux prouvé est l'honnêteté du vert (des `passed` sur un périmètre implicite) et le bruit de la grille (6 faux positifs sur 15), pas la sur-ingénierie.
- **Reste à arbitrer :** le lot A (un bloc « Hygiène » joint par `vf-reviewer` + champ `non_verifie` obligatoire ; QCT-01, 02, 03, 04, 08) : phase, numéro, arbitrage G-1 (marge d'instructions de `vf-reviewer` à 0). Lot B : QCT-05, lentille sobriété et code judo dans l'audit transverse. Lot C : QCT-06 (jamais juger de mémoire), QCT-07 (échelle de réutilisation de Ponytail, spike à arbitrer avec Willy). Réserve : QCT-09, QCT-10. Collisions : Phase 46 (format des verdicts, Willy) pour le lot A, Phase 45 pour QCT-07.
- **Constat du 2026-11-05 :** 0 occurrence de `QCT` ou `non_verifie` dans `plugin/dev-orchestrator/agents/vf-reviewer.md`, rien n'est engagé.
- **Déclencheur de reprise :** la prochaine retouche de `vf-reviewer` ou du contrat de revue, ou une décision explicite.

## « AI Agents in Depth » (Bojie Li), milestone candidat (investigué 2026-08-15)

- **Rapport :** `reports/research/2026-08-15-ai-agent-book-alignement.md` (5 agents : 4 lecteurs des 10 chapitres, 1 inventaire VibeFlow).
- **Verdict :** livre sérieux, VibeFlow convergent sur au moins 8 mécanismes majeurs ; il valide plusieurs refus (MemPalace, compaction). 4 gaps : (1) juges à vision (aucun juge ne voit un rendu) ; (2) calibration des juges (gold set, kappa > 0,7, Pass^k) ; (3) juge hétérogène cross-famille (spike d'abord) ; (4) lentille KV-cache dans le validator ; plus un volet doctrine (Constrain/Verify/Correct, échecs byzantins, MAST, evidence ≠ instructions dans `plugin/reference/`).
- **But exprimé par Samuel :** améliorer les pratiques similaires au livre, priorité aux juges design (gap 1).
- **Structure candidate :** milestone « alignement agent-book », 3 phases et 1 spike (juges à vision, calibration, doctrine augmentée ; spike juge hétérogène), détail au §5 du rapport.
- **Reste à arbitrer :** le milestone entier. Le gap 1 est en partie dépassé par les recettes de juges Playwright à captures (Phases 69 à 71, P70-D-19) ; les trois autres restent entiers.
- **Déclencheur de reprise :** d'origine, la clôture ou un jalon de `fiabilite-v1.0` (clos le 2026-10-08, jamais repris) ; à défaut, une décision explicite.

## ICM, Interpretable Context Methodology (investigué 2026-08-15)

- **Rapport :** `reports/research/2026-08-15-icm-deep-search.md` (deep-search, 4 agents). Papier : [arXiv 2603.16021](https://arxiv.org/abs/2603.16021) ; dépôts : [RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology), [ktnCodes/icm-template](https://github.com/ktnCodes/icm-template).
- **Verdict :** rien à adopter tel quel (pas de benchmark, mono-agent linéaire, le team-kernel est structurellement au-dessus), mais 5 mécanismes à distiller.
- **Reste à arbitrer (aucun engagé) :** G1 tables « Load / Do NOT Load » (anti-chargement déclaré) ; G2 `CONTEXT.md` par compartiment + `_index.md` de scaling ; G3 sync anti-drift carte↔disque ; G4 lab-starters clonables à placeholders pour `vf-new-lab` (recoupe les items `agency-agents` et « Template d'agent installable ») ; G5 Edit-Source Principle dans la doctrine des managers. Classement levier/coût au §7 du rapport.
- **Déclencheur de reprise :** la prochaine évolution de `vf-new-lab`, de `scaffold-docs.sh`, du team-kernel ou de la chaîne validator.

## Interfaces de pilotage d'agents de code : quinze outils (investigué 2026-11-10)

- **Rapport :** `.planning/research/2026-11-10-audit-cockpit/A5-veille-pilotage-agents.md` ; synthèse appliquée au § 6 de `.planning/research/2026-11-10-audit-cockpit-etude.md` (audit du cockpit).
- **Sources :** la vue d'agents et les Projects de Claude Code, Conductor, Cursor 3, Codex, GitHub Agent HQ, Warp Oz, Factory, Devin, Amp, Antigravity, Nimbalyst et Vibe Kanban, Langfuse, Braintrust, zoetrope, agents-observe (liens dans le rapport).
- **Verdict :** rien à installer. Tous convergent vers une liste d'agents groupée par état ; huit motifs relevés, six repris dans les formes proposées pour le cockpit (régie, frise, fiche d'agent). Cinq angles qu'aucun des quinze ne couvre (deux petits projets s'en approchent) : file d'attente classée par impact, frise du dépôt à horloge commune, radar de collisions, vivacité plutôt que statut, coût par phase et par étage.
- **Reste à arbitrer :** la revue de diff par agent (rouvre « détail de commit sans diff »), la réponse sur place à une permission (écartée pour l'instant), le plafond de coût par agent ; registre `AUDC-I16`, `AUDC-N1`, `AUDC-I35`.
- **Déclencheur de reprise :** le cadrage des Phases 73 et 74 du jalon `vibeflow-v2.0`.
