# Mission — correctifs de la recette du 2026-11-08 (cockpit)

Manager : vf-dev-manager, dispatché par la session principale le 2026-11-08. Branche `feat/recette-correctifs`
(partie de 274497a9), PR #222 vers `feat/cockpit-retours-utilisateurs`, **sans merge** (gel des publications,
décision de Samuel du 2026-11-08). Pas de verrou de mission, pas de gsd-quick, ni STATE.md ni ROADMAP.md
(consignes du mandat).

## Arbitrages et délégation

- Mandat : arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « Les 3 régressions + PU-G-137 »
  (lot A), « Les partiels qui te concernaient » (lot B), « La zone basse sous 1 280 px » (lot C).
- Ajout de périmètre par la session principale après le juge « responsable de lab » (da77d315) : lot B2
  (PU-G-147, 150, 163).
- Arbitrages ultérieurs, tous consignés mot pour mot au § 10 du rapport GLOBAL de la recette :
  3da818fe (libellés L1-L3 du Projet), 1e718a4f (ellipse « Sur ce tableau » dans la promesse), 574c8b6f
  (zone basse Q1 « Garder » et Q2 « Deux rangées »), 70bf5046 (barre à droite de la colonne dès 1 280 px),
  3f67e7aa (article aux missions ; dossier à point sur Code corrigé dans cette PR), 599a42a5 (délégation des
  détails : « Ne m'interroge plus et répond toi même par ta solution recommandée »).
- Décisions déléguées prises en mission (« décision déléguée par Samuel (message session principale,
  2026-11-08), option recommandée : … ») — le § 10 ne consigne que la délégation générale ; la liste
  complète vit ici et dans le CHANGELOG du cockpit :
  - A : Entrée et Retour arrière restent actifs sur Équipe (navigation de nœud, pas de caméra ; Q8 ne vise que
    la frappe qui déclenche le canevas).
  - B : titre de la vue Git atteignable au focus (D18.4) ; pied du bandeau Lancer collé ; garde
    `Terminal.strings` ; S6 (titre hors Tab quand Git couvre), S8 (branche morte retirée), P1 (seul « Détail »
    écrit la préférence), P2 (focus dans le panneau après la palette), P3 (réouverture seulement sur vrai
    choix), P4 et P4 bis (de 701 à 999 px, la dernière surface ouverte l'emporte), P5 (consigne « Appuyez sur
    Entrée » maintenue), F3 (réserve du pied 40 px, 52 au toucher), F6c (plafond LB.S3 au plus juste, 302).
  - B2 : M4 (la commande de correction reçoit la réponse « Format », « lignes de code » part au modèle) ;
    M7 (bloc « Maintenant », parcours et `sentence()` du build coupés au mot entier).
  - C : C-R3 (centre commun pastille/barre), C-R6 (le zoom se replie plutôt que de recouvrir titre ou visite).
  - Intégration : I-2 (zoom relevé au-dessus de la feuille de détail), I-3 et J1 (côté « colonne » puis
    « titre » pour la carte de visite, côté « titre » réservé aux fenêtres basses), sans moteur la carte
    recouvre l'avis plutôt que le titre, `tipOver` retiré (garde redondante), D7.16 (l'infobulle ne dépend
    plus de `:hover`), H7.1 (titre du panneau réécrit quand les extensions passent après le premier rendu).

## Plan de bataille (DAG, scratchpad)

base (fusions sondes-stables + ci-selective) → exec-A / exec-B / exec-C / exec-B2 en parallèle, chacun dans
son worktree (recette-correctifs-a, -b, -b2, -c) → revue de chaque lot (+ critique design du lot C) → boucles
de correction ciblée → intégration (fusions + reliquats) → revue de jointure → passe de suivi → push, PR,
CI → passes K1-K4 sur les rouges CI.

## Verdicts

| Lot | Tours de revue | Verdict final |
|---|---|---|
| A | 2 (+ revue des passes) | passed |
| B | 4 (majeur au tour 1 : pied masquant la case du chat ; au tour 2 : drapeau de geste armé) | passed |
| B2 | 3 (majeur au tour 1 : 315 coupes en plein mot par `clip()`) | passed |
| C | 2 (+ critique design 84/100, passed) | passed |
| Intégration | jointure passed ; passe de suivi gaps_found (M-A, M-B, M-C) puis corrigée | voir CI |
| Passe CI K1-K3 | gaps_found (R3.23 non corrigé) puis K4 | voir CI |

Juge de design (vf-design-judge, frais, contre DESIGN.md) : **84/100, passed** (seuil 70) ; findings
d'exécution repris en C-R1 à C-R4.

## Causes des rouges CI (PR #222)

- Absence de `claude` sur le runner : avis « Nécessite le CLI Claude Code » dans la barre de question
  (92 → 148 px à 768 px), qui relève le zoom (sonde corrigée, R25 ajouté) et faisait recouvrir le titre par la
  carte de visite (correctif produit 86ec392f) ; R3.23 sans réponse du moteur (faux claude sur le PATH).
- Copie figée de lancer-suivi non régénérée après PU-G-163 (e2502ac0) ; table de test-ci-shard-suites qui
  nommait encore `test-cockpit-projet.sh` découpée (ab3d5153) ; garde `:hover` de l'infobulle (baa48299).
- Mutant M-PASTILLE-SANS-RAPPEL trop étroit après les nouveaux rappels (959f7264, recensement T21.7r).
- Parcours de Tab d'EK18 qui partait de l'ancien focus (d7b12bcd) ; titre du panneau rendu avant les
  extensions sous Linux (a1275048, H7.1b).
- Leçon : les suites lancer-suivi, direct et test-ci-shard-suites n'étaient pas dans la liste de rejeu de
  l'intégration ; elles étaient rouges en local aussi. Le rejeu complet est celui de la découverte, pas
  une liste.

## Preuves E6

| Lot | Commande | rc | SHA |
|---|---|---|---|
| A | `bash plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh` | 0 | 06e8ac34 |
| B | `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh` | 0 | 8c5baa21 |
| B2 | `bash plugin/cockpit/scripts/tests/test-cockpit-questions.sh` | 0 | 851d5125 |
| C | `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh` | 0 | 4b8f1aad |
| Intégration | `bash plugin/cockpit/amont/synchro.sh verifier` | 0 | a1275048 |
| Intégration | `bash scripts/check-machine-paths.sh` | 0 | a1275048 |

## Captures

Hors dépôt, dans le scratchpad de la session (`recette-correctifs/captures/{A,B,C,I}/`) : avant/après par
lot, zone basse aux six largeurs (390, 700, 1 000, 1 279, 1 280, 1 440 px) en clair et sombre.

## À montrer à Samuel (goût)

- Feuille de détail ouverte au téléphone avec un titre long : le zoom se replie (+, − et f au clavier ;
  Ctrl+molette ou pincement).
- Fenêtre basse (844 × 390) : carte de visite resserrée, titre entier, description qui défile.
- Sans moteur, en fenêtre basse : la carte de visite recouvre l'avis le temps de la visite.

## Décompte

26 agents dispatchés : 13 vf-coder (lots A, B, B2, C ; corrections B ×2 ; intégration ×2 ; CI K1-K5),
12 vf-reviewer, 1 vf-design-judge.

## Next step

Run sur a1275048 : 8 shards verts sur 9 ; shard 8 rouge (V4 taille de chrome-equipe-clavier.mjs, D18.4).
Passe K5 en cours au moment du rapport (extraction du parcours de Tab, premier rendu après les extensions
dans viewer.html) : à pousser, puis CI à relire. La fusion dans `feat/cockpit-retours-utilisateurs` reste un
geste de Samuel une fois le gel levé.
