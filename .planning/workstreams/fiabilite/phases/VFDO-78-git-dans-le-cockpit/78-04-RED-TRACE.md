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

## Debug O6.11 (mgr78-reprise, 2026-11-06)

Symptôme : `test-cockpit-projet.sh` O6.11 rouge à 1440 et 390 px depuis `c743e356` (y 244 après « Passer », 218 avant).

Constat : rejoué sur `c743e356` : rouge (`p1440` avant y 218, après y 244 ; `p390` avant y 314, après y 326). Rejoué sur `git archive de53d8b5` (copie hors worktree) : vert (244 / 244).

Cause (sondée par un crochet sur `state.t`, `freeArea()` et la hauteur de `#context` à chaque `setT`) : le rendu du viewer (`render`) cadre la vue avec le bloc de titre NATIF (`#context` = 142 px, donc `freeArea().y` = 202 : plafond de 130), puis émet `render` en microtâche ; `ecrireVue` (76) raccourcit alors le bloc à 77 px (`freeArea().y` = 149) SANS recadrer. Une fermeture de visite depuis un groupe (`SC.go('root')` : « Passer ») laisse donc la vue cadrée pour l'ancien bloc ; une fermeture depuis la racine (`SC.fit` seul, bloc déjà court) la cadre pour le nouveau : 26,5 px d'écart (53 / 2). Avant `c743e356`, le sous-titre long (résumé du projet) gardait le bloc au-dessus du plafond de 130 px dans les deux cas : l'écart était masqué. Ce n'est ni 40-tour.js ni le viewer qui changent : le défaut est le recadrage manquant après la réécriture du bloc.

Expérience 1 (rouge) : `c743e356`, sonde `78-debug-probe.mjs` : `fits` montre le fit de `render` à `ctx` 142 (`a.y` 202, y 244,2) puis le fit de fermeture depuis la racine à `ctx` 77 (`a.y` 149, y 217,7).
Expérience 2 (cause seule changée) : `c743e356`, aucune modification de code, seulement `#context{min-height:142px}` injecté (la hauteur du bloc ne change plus à la réécriture) : O6.11 vert, y 244 / 244.
Correctif (76) : `ecrireEtRecadrer` — si la vue était exactement le cadrage de l'ancienne zone libre et que le haut de la zone libre bouge, `SC.fit(false)`. Vert : y 218 / 218 à 1440 px, 314 / 314 à 390 px.

## Correction D-39 (mgr78-reprise, 2026-11-06) — plancher de la recherche à 152 px, de 1 000 à 1 279 px, avec Git seulement

P78-D-39 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 : « Recherche à 152 px (Recommandé) »), amende P70-D-16.

**Rouge avant (code de `c743e356`, 76 non modifié).**
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh` avec la suite AVANT correction (`git show HEAD:…/test-cockpit-responsive.sh`). Assertion : `viol.mjs` à 1 024 px, onglet Code, attendu `aucune`. Obtenu, 7 rouges sur 291 : `recherche : 174 px, minimum 200` pour R1 (court et long, 1 024 px), R2 (court et long, 1 920 -> 1 024), R8 (court et long, 1 024 px sans pointeur), R9 (long, 1 024 px, texte élargi). Journal : `78-d39-resp-ancien-rouge.log`.
- Suite NOUVELLE sur le code de `c743e356` : 313 PASS / 5 FAIL. D39.2 rouge aux trois largeurs (1 000, 1 024, 1 279 px, avec Git) : attendu `"Chercher…"/false`, obtenu `none/true` (l'invite d'origine reste affichée) ; D39m1 et D39m2 « mutant non construit : chaîne introuvable » (le code n'a pas encore la clé `header[data-vf-git]`). Les témoins D39.1, D39.3, D39.4, D39.5, D39.6 sont déjà verts : le plancher de 152 px existait (`c743e356`), ce que la correction ajoute est sa clé sur l'ouvreur, l'invite courte et la borne conditionnelle des tests. Journal : `78-d39-resp-rouge.log`.

**Vert après.** `78-d39-resp-vert2.log` : 320 PASS / 0 FAIL. R1, R2, R8, R9 : borne de 152 px SEULEMENT via le drapeau `git` de `viol.mjs` (lab avec dépôt, largeur de 1 000 à 1 279 px) ; l'assertion à 200 px est conservée à l'identique partout ailleurs (1 280 px et plus, R3, labs sans drapeau) et D39.5, D39.6 l'exigent explicitement pour un lab SANS Git à 1 000, 1 024, 1 279 et 1 280 px (plancher calculé `200px`, recherche mesurée ≥ 200, aucune violation de R1 à 1 024 et 1 280 px, onglets Code et Projet).

**Mutants (chacun avec la trace de SON rouge).**
- M1 « plancher de 152 px aussi sans Git » : dans une copie du lab sans Git, une règle `header .hc { min-width: 152px; }` posée avant la sortie « pas de dépôt » de 76 (le défaut de `c743e356`). D39m1a : plancher calculé `152px` (le mutant est vivant) ; D39m1 : le témoin D39.5 (sans Git, 1 024 px, attendu `false/200px/none/true`) rougit. Note de mesure : la recherche d'un lab sans Git est naturellement plus large que 200 px à 1 024 px (pas d'icône), donc la mesure de largeur seule ne rougit pas ; le témoin qui rougit est le plancher calculé.
- M2 « plancher de 152 px aussi à 1 280 px » : dans une copie du lab avec Git, la borne haute de la requête passe de 1 279 à 1 280 px. D39m2a : plancher calculé `152px` à 1 280 px ; D39m2 : le témoin D39.4 (attendu `200px/none/true`) rougit.
- Une première version de M1 (remplacer `header[data-vf-git] .hc` par `header .hc` dans le sous-arbre sans Git) restait verte : la règle n'est jamais injectée sans dépôt (76 sort avant le style). Elle ne comptait pas ; remplacée par la forme ci-dessus.

Captures : `78-d39-entete-1024-git.png` (« Chercher… », icône Git, aucun bouton hors fenêtre) et `78-d39-entete-1024-sansgit.png` (invite d'origine, 200 px).

## Correction revue page (mgr78-reprise, 2026-11-06) — S2 : `vf-git:signal` écouté sur document

Finding S2 / P1 de la revue de code (SHA jugé `8edb0bf7`, GITC-11, P78-D-15) : `70-vf-live.js:223` émet `vf-git:signal` par `document.dispatchEvent(new CustomEvent(...))`, sans `bubbles` ; `76-vf-git-entete.js` l'écoutait sur `window`, que cet événement n'atteint jamais.

**Pourquoi l'ancienne forme des tests était fausse.** H3.3/H3.4b de `test-cockpit-git-entete.sh` émettaient `window.dispatchEvent(new CustomEvent('vf-git:signal'))` : un événement émis sur window atteint un écouteur de window, donc le test était vert alors que le vrai émetteur (sur document, sans bubbles) n'atteint aucun écouteur de window. Le test verrouillait le défaut. Réécrit pour émettre exactement comme 70 (`document.dispatchEvent`, sans bubbles, `detail: { sig }`). B3 de `test-cockpit-git-e2e.sh` ne voyait pas non plus le défaut : tiroir OUVERT, la seconde ligne suit par l'événement `vf-git:entete` du tiroir, pas par l'écouteur de 76.

**Rouge avant (76 de `0a8a9b63`).** Journaux `78-rv-rouge-git-entete.log` et `78-rv-rouge-git-e2e.log`.
- `test-cockpit-git-entete.sh` : scénario H3 interrompu à l'attente « relecture sur signal » (aucun appel de `/api/vf/git/entete` sur un signal émis comme 70) : 85 réussis, 13 échoués (H3.3 à H3.5 et H3.x, par interruption du scénario ; H3.4 « relit l'en-tête avec le jeton » attendu `1|true`, obtenu vide).
- `test-cockpit-git-e2e.sh` B3b (nouveau : tiroir fermé par la touche g, puis `git switch -q -c troisieme` dans le lab, la seconde ligne doit dire « troisieme » en moins de 10 s) : B3.1 rouge, `seconde ligne inchangée, tiroir fermé : autre · worktree wt-ag` ; 33 réussis, 2 échoués (l'autre : M-ECOUTEUR « mutation impossible », l'ancre `document.addEventListener(...)` n'existe pas encore).

**Vert après.** `78-rv-vert-git-entete.log` rc 0 (H3.4b vert, signal émis comme 70) ; `78-rv-vert-git-e2e.log` rc 0 : B3b vert, B3.1 vert.

**Mutant M-ECOUTEUR** (copie de la sortie construite, l'écouteur de 76 remis sur `window`) : rouge sur B3b seulement, pour la bonne raison : `ligne-fermee` faux ET `rangee-neuve`, `ligne-autre` (tiroir ouvert) toujours vrais, B2 vert (assertion `true|true|true|`).

## Correction revue page — P78-D-40 : libellé « Par branche — avance sur la base »

Rouge avant : `D10.5` de `test-cockpit-git-tiroir.sh` (1440 et 390 px), attendu `Par branche — avance sur la base`, obtenu `Par branche (30 jours)` (`78-rv-rouge2-git-tiroir.log`). Vert après : `78-rv-dbg-git-tiroir.log`, rc 0. `78-UI-SPEC.md` ligne 121 mise à jour (référence P78-D-40).


## Correction delta et recette (mgr78-reprise, 2026-11-06) — F6a, G1, G2, G3 (en-tête)

Journaux dans `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/` : rouge `78-delta-fix-r-git-entete.log`, vert `78-delta-fix-m-git-entete.log`.

**G1 (MAJEUR) — branche périmée à chaque chargement.** Témoin H8 (`test-cockpit-git-entete.sh`) : lab jetable avec un vrai worktree, assemblé sur `feat/x`, puis `git switch -c feat/y` SANS réassemblage ; chaque onglet est chargé.
- Rouge avant : H8.1 `/` attendu `feat/y`, obtenu `feat/x` ; lectures de `/api/vf/git/entete` attendu 1, obtenu 0 ; idem `/equipe.html`. (`/project.html` était vert d'emblée : le signal émis au chargement relisait déjà l'en-tête.)
- Correction : `76-vf-git-entete.js` relit l'en-tête une fois au chargement (`relire()`), et `V` est remplacé par chaque lecture.
- Vert après : trois onglets, `feat/y` en moins de 2 s, exactement une lecture par chargement (y compris sur Projet, où le signal de chargement et la lecture se confondent en une seule).
- Mutant M-CHARGEMENT (appel `relire()` du chargement retiré) : H8.1 rougit `feat/x|0|true` (l'écart du point médian, lui, reste bon).

**G2 — bloc de vue Code.** H8.2 : rouge avant `Le code, branche feat/x` (attendu `feat/y`) ; au signal, `Le code, branche feat/x|feat/z` (attendu `Le code, branche feat/z|feat/z`). Correction : `lire()` réécrit le bloc de vue Code quand la lecture change. Vert après. Mutant M-BLOC-VUE (réécriture retirée) : `feat/y|Le code, branche feat/x`.

**G3 — écart avant le point médian.** H8.3 (bord droit de `.vf-git-branche`, point et mot suivant mesurés par `Range`) : rouge avant `false|false` sur les trois onglets. Correction : `white-space: pre` sur `.vf-git-wt` (l'espace de tête n'est plus effondré ; le texte du DOM est inchangé, aucune marge nouvelle). Vert après. Mutant M-ECART (règle retirée) : `false|feat/y`.

**F6a — retour à `absent`.** `test-cockpit-responsive.sh` D39.7 : à 1 024 px, Git présent (drapeau, 152 px, invite « Chercher… »), puis un signal dont la relecture de l'en-tête rend `absent` : drapeau retiré, 200 px, invite d'origine, ouvreur et seconde ligne cachés. Comportement déjà correct, témoin ajouté. Mutant D39m3 (`setAttribute` inconditionnel) rougit D39.7b : `true|152px|true|152px|true`.
Conséquence sur le témoin D39m2 : la page relisant l'en-tête au chargement, la copie du lab du mutant doit rester un dépôt (`git init`), sinon « absent » retire le drapeau avant la mesure (le défaut vient du lab de la copie, plus du mutant).
