# 78-04 — Trace des témoins rouges

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh` (Chrome headless en CDP, port éphémère, jamais 4456).
Chaque rouge est joué sur la base, avant le code correspondant ; le vert suit dans la même tâche.

## Tâche 1 (tracer)

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H1.1 | `enteteGit(<wt-a>)` | `ok\|depot\|feat/x\|wt-a\|false` | `` (module `vf-cockpit-git-entete.mjs` absent, l'import échoue) | oui |
| H1.1b | `enteteGit(<depot>)` | `ok\|depot\|main\|null` | `` (module absent) | oui |
| H2.1 | `#proj-name` sur `index.html`, cockpit construit dans le worktree | `depot` | `wt-a` (le nom du moteur, dossier du worktree) | oui |
| H2.1b | `.vf-git-ligne` contient `feat/x` et `wt-a` | `oui` | `non` (aucune seconde ligne) | oui |

## Tâche 2

Rouge joué sur la base de la tâche 1 (module, build et 76 de la tâche 1 ; ni `vfGit` dans `ecrirePage`, ni dans la carte Équipe, ni événements, ni ouvreur).
Journal du rouge : 29 réussis, 22 échoués (`78-04-rouge2b.log` du scratchpad). Les témoins H3.1, H5.1, H5.2 et les mutants étaient déjà verts :
la tâche 1 écrivait déjà l'état détaché, `textContent` et la sortie sans git ; leur valeur tient aux mutants (M-TEXTE, M-ABSENT), qui eux rougissent la cible.

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H2.2 equipe | `#proj-name` de `/equipe.html` | `depot` | `wt-a` (la carte Équipe ne portait pas `meta.vfGit`) | oui |
| H2.2 equipe | seconde ligne de `/equipe.html` | contient `feat/x` | aucune seconde ligne | oui |
| H2.3a (témoin positif) | `project.html` réécrit par le direct après l'ajout d'un `01-02-PLAN.md` | 1 occurrence du texte du plan | 1 (vert : le direct réécrit bien la page) | oui |
| H2.3b | la page réécrite contient `"vfGit":{"etat":"ok"` | 1 | 0 (`ecrirePage` ne reprenait que `root` et `vfLogos`) | oui |
| H2.3c | `#proj-name` après réécriture | `depot` | `wt-a` | oui |
| H3.3 | ellipse, `title` complet, largeur sur la ligne (événement `vf-git:entete`) | `true` | `false` (l'événement n'était pas écouté) | oui, après passage de la fenêtre à 1440 px (la fenêtre headless par défaut est sous 1000 px et masque la ligne) |
| H3.4 | `vf-git:entete`, `vf-git:signal` (jeton, schéma) | `autre`, `1\|true`, `via-signal` | texte inchangé, aucun appel | oui |
| H3.2b | « Branche indisponible » + ouvreur | `Branche indisponible\|true` | texte inchangé, pas d'ouvreur | oui |
| H3.5 | `vf-git:basculer`, `aria-expanded`, `aria-controls` | `ligne,ouvreur` ; `true,true` ; `vf-git-tiroir` | listes vides, attributs `null` | oui |
| H4.1 (375, 700, 768, 999 px) | ligne masquée, ouvreur 44 × 44 en tête de `.hr` | `false\|true\|44\|44\|true` | `true\|false\|0\|0\|false` (la ligne restait visible sous 1000 px, aucune règle de masquage) | oui |

Note H4.1 : les largeurs 1000 et 1440 px étaient vertes d'emblée (ligne visible, pas d'ouvreur).
Largeur 1000 px : la requête media du viewer (`max-width: 999px`, ou tactile sous 1280 px) ne s'applique pas à 1000 px exactement en pointeur fin : à 1000 px la ligne est visible et l'ouvreur caché (frontière mesurée à 999 / 1000 px).
Le tactile à 1000 px n'est pas émulable avec `chrome-session.mjs` (aucune émulation de `pointer: coarse`).

### Mutants (tâche 2)

| Mutant | Altération | Rouge obtenu |
|---|---|---|
| M-DEPOT | `racine` pris de `rev-parse --show-toplevel` dans une copie du module | H1.1 : `depot` = `wt-a` ; H2.2 : `#proj-name` = `wt-m` (cockpit construit avec la copie) |
| M-TEXTE | `spBranche.innerHTML = texteBranche` dans une copie de 76, branche `<svg/onload=alert(1)>` | `svgEntete > 0` et texte de la ligne différent de la branche (un `svg` neuf dans l'en-tête) |
| M-ABSENT | `V.etat === 'absent' \|\|` retiré dans une copie de 76, lab hors dépôt | `.vf-git-ligne` et `.vf-nom` présents sans git |

## Tâche 3

Rouge joué sur la base de la tâche 2 (bloc de vue du viewer inchangé, `css-jetons.mjs` absent) : sections H6 seules, copie temporaire de la suite (effacée ensuite) ; 5 réussis, 17 échoués (`78-04-rouge3.log` du scratchpad).

| Témoin | Assertion | Attendu | Obtenu sur la base (rouge) | Vert après |
|---|---|---|---|---|
| H6.1 Code | surtitre, titre, sous-titre | `Code`, `Le code, branche feat/x`, `N … lus dans le dépôt.` | `Vue d'ensemble`, `wt-a` (nom du projet du moteur), « Carte du code construite sans modèle… » | oui |
| H6.3 Code | titre sans nom du projet ni `depot`, classe `vf-ctx-titre` | `false\|false\|true` | `true\|false\|false` (titre = nom du projet, pas de classe) | oui |
| H6.2 Projet | surtitre, titre, sous-titre = résumé | `Projet\|Jalon vibeflow-test\|true` | `Vue d'ensemble`, `wt-a — Projet`, résumé | oui |
| H6.3 Projet | titre sans nom du projet, classe | `false\|true` | `true\|false` | oui |
| H6.2 Équipe | sans mission, une mission, deux missions | `Aucune mission en cours` + `L'équipe est au repos.` ; `Mission : x` ; `2 missions en cours` | `Vue d'ensemble`, `wt-a — Équipe`, « 0 actifs · 0 en attente… » | oui |
| H6.4 retour | après `go(nœud)` puis `go('root')` : bloc réécrit | `Projet\|true\|true` | bloc d'origine (`Vue d'ensemble\|true\|false`) | oui |
| H6.1 sans git | « Le code du projet », « … lus dans le dossier. » | `Code\|Le code du projet\|true` | `Vue d'ensemble`, `hors-depot` (nom du moteur), description du moteur | oui |
| H6.6 | `css-jetons.mjs` sur 76 ; cinq copies fautives (`padding: 5px`, `#123456`, `border-radius: 50%`, `rgba(1, 2, 3, .5)`, `margin-left: -7px`) | `0` ; `1 1` chacune | `node` ne trouve pas `css-jetons.mjs` : code 1, `1 0` (aucun écart nommé) | oui |

Vert d'emblée (la tâche 1 avait déjà posé `repos: []` dans la page d'index) : H6.5 (aucun titre « Repositories » / « Dépôts », aucune ligne `branche @ sha`) et H6.4 (dans un nœud, le bloc reste celui du viewer).
Ces deux témoins ne sont pas aveugles : leurs témoins positifs sont joués (`graph.json` garde `meta.repos`, le panneau d'ensemble est rendu), et le mutant M-REPOS ci-dessous les fait rougir.

### Mutant (tâche 3)

| Mutant | Altération | Rouge obtenu |
|---|---|---|
| M-REPOS | `insererGraphe(html, g)` au lieu de `{ ...g, meta: { ...g.meta, repos: [] } }` dans une copie du build | H6.5 : le panneau de l'index liste de nouveau les dépôts (titre « Dépôts » ou lignes `.rp`) |

## Non-régression : `test-cockpit-responsive.sh` (rouge puis vert, après la tâche 3)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh` sur le code des tâches 1 à 3 (l'ouvreur 44 × 44 visible sous 1000 px, y compris à 390 px).
Obtenu (rouge, 285 PASS / 6 FAIL, `78-04-responsive-rouge.log` du scratchpad) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| R3 index / 390 px, R3 project / 390 px, R20 Équipe / 390 px (aucune superposition d'en-tête) | `aucune` | `nav.vf-tabs recouvre #search-btn` |
| R13.2 index / project / equipe à 390 px (aucune action dans la rangée, « ⋯ » visible) | `\|true` | `vf-git-ouvreur\|true` |

Cause : le téléphone (≤ 700 px, `02-vf-telephone.js`, P70-D-01) tient l'en-tête sur une rangée et range toute action de `.hr` dans le menu « ⋯ » ; le bouton de 44 px s'y ajoutait.
Correction : sous 700 px le bouton est masqué (`display: none !important`) ; le menu « ⋯ » le reprend sous le libellé « Historique Git » (span `.bl`), son clic relaie `vf-git:basculer` ; entre 701 et 999 px il reste l'icône de 44 px en tête de `.hr`.
Vert : `test-cockpit-responsive.sh` rc 0 ; H4.1 réécrit (768 et 999 px : ouvreur visible ; 375 et 700 px : absent de la rangée ; entrée « Historique Git » du menu, clic -> `vf-git:basculer` source `ouvreur`) : 74 réussis, 0 échoué.


## Correction design (critique fraîche du 2026-11-06 : F1, F3, F5, F6, F8, F9, F11, F13 ; P78-D-34, P78-D-35)

Mandat de correction ciblée de `mgr78-reprise`. Chaque propriété est MESURÉE dans Chrome (style calculé, boîtes, texte, rangées) par la suite `test-cockpit-git-entete.sh` (sections H4 et H7). Rouge joué AVANT le code, sur le code d'avant la correction (`78-design-entete-rouge.log` du scratchpad : 84 PASS / 14 FAIL), puis vert (`78-design-entete-vert2.log`, 98 PASS / 0 FAIL).
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh` ; labs : `depot` + worktree `wt-a` (F1, F5, F6, F8, F11), worktree `wt-long` à branche longue (F13), lab sans git, lab à `current_phase: 2` (F9).

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| H4.1 — 1000 px : ligne masquée, ouvreur 44 × 44 en tête de .hr (P78-D-34, icône de 701 à 1279 px) | `false\|true\|44\|44\|true` | `true\|false\|0\|0\|true` |
| H4.1 — 1100 px : ligne masquée, ouvreur 44 × 44 en tête de .hr (P78-D-34, icône de 701 à 1279 px) | `false\|true\|44\|44\|true` | `true\|false\|0\|0\|true` |
| H4.1 — 1279 px : ligne masquée, ouvreur 44 × 44 en tête de .hr (P78-D-34, icône de 701 à 1279 px) | `false\|true\|44\|44\|true` | `true\|false\|0\|0\|true` |
| H6.2 — Projet : surtitre, titre « Jalon <jalon> », sous-titre = phases faites (le titre n'y est plus répété, voir H7.9) | `Projet\|Jalon vibeflow-test\|1 phase faite sur 2.` | `Projet\|Jalon vibeflow-test\|Jalon vibeflow-test · en exécution.` |
| H7.1 — / (lab dans un worktree wt-a) : le panneau dit « depot », sans « wt-a » ni suffixe « — Projet » / « — Équipe » | `depot\|depot\|false\|false` | `depot\|wt-a\|true\|false` |
| H7.1 — /project.html (lab dans un worktree wt-a) : le panneau dit « depot », sans « wt-a » ni suffixe « — Projet » / « — Équipe » | `depot\|depot\|false\|false` | `depot\|wt-a — Projet\|true\|true` |
| H7.1 — /equipe.html (lab dans un worktree wt-a) : le panneau dit « depot », sans « wt-a » ni suffixe « — Projet » / « — Équipe » | `depot\|depot\|false\|false` | `depot\|wt-a — Équipe\|true\|true` |
| H7.6 — « Branche indisponible » : contraste ≥ 4,5:1 dans les deux thèmes (fond du corps opaque) | `true\|true\|true` | `false\|true\|true` |
| H7.11 — HEAD détaché : texte neutre (même couleur que var(--text-3)) dans les deux thèmes | `true\|true` | `false\|false` |
| H7.8 — anneau de focus de la seconde ligne : aucune intersection avec la boîte du nom (aire en px²) | `0` | `279.6875` |
| H7.5 — de 700 à 1000 px, l'en-tête passe sur deux rangées aux mêmes largeurs avec et sans git | `700:1 710:2 720:2 730:2 740:2 750:2 760:2 770:2 780:2 790:2 800:2 810:2 820:2 830:2 840:2 850:2 860:2 870:1 880:1 890:1 900:1 910:1 920:1 930:1 940:1 950:1 960:1 970:1 98…` | `700:1 710:2 720:2 730:2 740:2 750:2 760:2 770:2 780:2 790:2 800:2 810:2 820:2 830:2 840:2 850:2 860:2 870:2 880:2 890:2 900:2 910:2 920:2 930:2 940:1 950:1 960:1 970:1 98…` |
| H7.13 — aucune coupure en plein mot dans le titre du bloc de vue (coupures hors « / », « - », espace) | `` | `k\|p,i\|t` |
| H7.9 — Projet : le sous-titre ne contient ni le titre ni le nom du jalon | `false\|false` | `true\|true` |
| H7.9 — Projet : le sous-titre résume la vue (« Phase N en cours, k phases faites sur n. ») | `Phase 2 en cours, 1 phase faite sur 2.` | `Jalon vibeflow-test · phase 2 · en exécution.` |

Lecture : F1 (H7.1, trois onglets) — le panneau disait `wt-a`, `wt-a — Projet`, `wt-a — Équipe` pendant que l'en-tête disait `depot` ; F3 (H4.1 à 1000, 1100, 1279 px) — seconde ligne visible et ouvreur absent ; F5 (H7.5) — l'en-tête repasse sur une rangée à 940 px avec git contre 870 px sans (la base flex de `.hc` fait le saut de ligne, pas la largeur de la recherche : une première tentative sur `#search-btn` laissait le seuil à 940, constaté en injectant le CSS dans la page avant d'écrire le correctif) ; F6 (H7.6) — contraste sous 4,5:1 ; F8 (H7.8) — l'anneau de focus (décalage +2 px) recouvre 279,7 px² du nom ; F9 (H7.9, H6.2) — le sous-titre répétait le titre ; F11 (H7.11) — couleur d'avertissement ; F13 (H7.13) — coupure `k|p`, `i|t` en plein mot.
Témoins verts d'emblée, preuves que la mesure n'est pas vide : H7.5 « deux régimes » (le lab sans git passe bien de deux rangées à une) et H7.13 « le titre passe sur deux lignes » ; H7.8 pose `:focus-visible` vrai et contour `solid`.
Vert : H4 (1000, 1100, 1279 px : icône 44 × 44 en tête de `.hr` ; 1280 et 1440 px : seconde ligne, ouvreur caché ; une rangée, aucun bouton hors fenêtre ni superposé), H6.2, H7.1 à H7.13, toutes PASS.
