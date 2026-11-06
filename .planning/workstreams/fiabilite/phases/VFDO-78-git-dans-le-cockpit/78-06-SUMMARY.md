---
phase: 78
plan: "06"
subsystem: cockpit
requirements-completed: [GITC-04, GITC-05, GITC-06, GITC-08, GITC-10, GITC-11]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/77-vf-git-rendu.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/77-vf-git-tiroir.js
    - plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh
    - plugin/cockpit/scripts/tests/temoins/git-tiroir.json
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-06-RED-TRACE.md
  modified:
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
---

# Phase 78 Plan 06 : tiroir Git de la page — Summary

Tiroir vertical à gauche (`aside#vf-git-tiroir.vf-git-tiroir.glass`), ouvert par `vf-git-basculer` (seconde ligne, ouvreur 701-999 px, entrée du menu « ⋯ » sous 701 px) et par la touche g ; coquille, graphe SVG en couloirs, sections Worktrees, Graphe, Tags, Stash, Auteurs et activité, mergées repliées, commandes à copier, états chargement, vide et indisponible. Lecture seule : un GET de même origine, aucun `postMessage`, aucun `innerHTML`. `viewer.html` et `00-vibeflow.js` intacts. Reprise après crash : le témoin `git-tiroir.json` du prédécesseur a été relu contre le schéma servi par 78-05 (toutes les clés requises y sont) et gardé.

Suite `test-cockpit-git-tiroir.sh` : **60 réussis, 0 échoué, 0 sauté** (D1, D2, D3 dont D3.4 jouée sur un vrai Terminal `--terminal`, 5 mutants). Rouges avant le code et obtenus : `78-06-RED-TRACE.md` (écart d'honnêteté : le code de la tâche 1 est allé au-delà de la coquille ; le rouge des tâches 2 et 3 est joué sur des copies du module réduites à la coquille, chaque assertion étant en outre tuée par un mutant).

## API exacte

`window.VFGitTiroir = Object.freeze({ ouvrir, fermer, ouvert(): bool, recharger(): Promise, donnees(): réponse|null })` (consommé par 78-10).
`window.VFGitRendu = Object.freeze({ graphe(rangees, { couloirsMax, replies, tactile }), rangee(r, { tactile, colonne? }), sectionWorktrees(l, annonce), sectionTags(l), sectionStash(l, annonce), sectionAuteurs(auteurs, parBranche), mergees(l, annonce), commande(texte|null, annonce), etatChargement(), etatVide(cmd, annonce), etatIndisponible(cmd, reessayer, annonce), relatif(at, maintenant), section(titre, n, corps, ouvert, id), ico(d), el(tag, cls, txt, attrs) })`. Écarts à la liste du plan : paramètre `annonce` (région aria-live) passé aux fabriques qui rendent une commande ; `section`, `ico`, `el` exposés en plus (le tiroir compose la section Graphe) ; une section sans donnée rend `null`.

## Point d'extension pour 78-10 (registre paresseux, aucun ordre de chargement)

`window.VFGitExt` (objet, à créer par le fichier 77-vf-git-vue-detail.js) : si présent AU MOMENT DE L'APPEL, ses crochets sont appelés ; absent ou qui lève, rien ne se passe. Crochets : `rangee(li, r)` (rendu, après chaque rangée du graphe), `rendu(corps, donnees)` (tiroir, après chaque rendu complet), `etat(ouvert)` (ouverture et fermeture). 78-10 lit `window.VFGitTiroir.donnees()` et peut rappeler `recharger()`. Événements consommés par 78-10/78-09 : `vf-git:basculer`, `vf-git:signal` (non câblé ici : 78-10) ; émis ici : `vf-git:etat {ouvert}`, `vf-git:entete` (objet `entete` de chaque réponse conforme, même `indisponible`, ce qui fait dire « Branche indisponible » à la seconde ligne).

## Choix de construction

- **SVG** : une colonne SVG par rangée (`svg.vf-git-gcol`, `aria-hidden`, largeur = couloirs lus x 16 px, hauteur 40 ou 44), construite par `createElementNS`. L'état des couloirs est rejoué de haut en bas depuis les rangées servies (le champ `suite` du témoin n'est pas servi : il se déduit de `p[0]` absent de `sortants[].parent`). Quart de cercle par la commande d'arc `A16 16` (horizontale, arc, verticale). Couleurs par classes `vf-git-t0..t5` (couleur de la teinte servie, `stroke: currentColor`), tirets `3 3` pour une rangée dont les étiquettes ne sont que distantes ; HEAD = nœud plein `--text` + anneau `--ring` ; fusion = nœud creux `--surface`.
- **« +N »** : `replies` servi, sous la liste. **Étiquettes** : 2 pilules puis `+k` avec k = étiquettes en trop + `refsPlus` servi (témoin : +4), `title` = noms puis « et n autres ».
- **Schéma vérifié avant rendu** : types des champs requis et de chaque rangée ; sinon carte indisponible avec `git status`, aucune rangée.
- **Largeur sous `#panel`** : la règle `body:not(.no-panel) .vf-git-tiroir { width: max(240px, min(360px, calc(100vw - var(--panel-w, 360px) - 312px))) }` donne 328 px à 1000 px de large (360 px ensuite) : les 360 px fixes de l'UI-SPEC ne laissaient que 248 px de plan, le plan exige 280 (mesuré : D3.5, plan >= 280). Écart à l'UI-SPEC §3, justifié par la must_have.
- **Jetons de 71.5** (UI-SPEC §3 écarté sur ce point, arbitrages du 2026-11-05) : aucun fond teinté d'état ni liseré : la carte « Git est indisponible » est en `--raise` avec texte neutre (l'UI-SPEC disait `--warn-bg`), « Copiée » et « Copie impossible » en texte `--text-2` ; « ici » en `--on` / `--on-text` (inversion, pas une teinte d'état). Couleurs de couloirs en variables, sans halo.

## Valeurs d'espacement posées et jeton qui les remplacera au rebase (grille 2-4-6-8-12-16-20-24-32)

| Valeur | Où | Jeton |
|---|---|---|
| `left: 16px`, `bottom: calc(var(--vf-term-reserve) + 16px)` | bord de fenêtre du tiroir | `--edge` |
| `left/right/bottom: 8px` (< 1000 px) | tiroir mobile | `--edge` mobile (8) |
| `top: calc(var(--hh) + 4px)` | sous l'en-tête (comme `#panel`) | `--sp-4` |
| `padding: 0 8px 0 16px` ; `gap: 8px` | barre (36 px) | `--sp-8`, `--inset-panel` (16) |
| `padding: 8px 16px` | ligne d'aide | `--sp-8`, `--inset-panel` |
| `padding: 0 16px 16px` | corps | `--inset-panel` |
| `margin-top: 12px` | entre sections | `--sp-12` |
| `padding: 4px 0`, `gap: 8px` | titre de section, bouton des mergées | `--sp-4`, `--sp-8` |
| `gap: 8px` | rangée du graphe ; `gap: 4px` ligne 1 | `--sp-8`, `--sp-4` |
| `padding: 2px 8px` | pilules d'étiquette, « ici » | `--sp-2`, `--sp-8` |
| `gap: 4px` ; `padding: 8px 12px` | lignes worktree, stash, auteur | `--sp-4`, `--sp-8`, `--sp-12` |
| `padding: 6px 12px` ; `gap: 8px` | lignes tags et activité | `--sp-6`, `--sp-12`, `--sp-8` |
| `gap: 6px` ; `padding: 4px 4px 4px 12px` ; `min-height: 28px` | commande à copier | `--sp-6`, `--sp-4`, `--sp-12` |
| `padding: 12px 0` ; `gap: 8px` ; carte `padding: 12px` | états | `--sp-12`, `--sp-8` |
| `margin: 2px 0 0` ; `margin-top: 8px` | « +N », sous-liste | `--sp-2`, `--sp-8` |

L'UI-SPEC posait des 10 et des 14 (copie de `.vf-term-barre`) : ramenés à 12 et 16 pour rester sur la grille de la 71.5 (écart visuel de 2 px, sans effet sur les mesures de la suite).

## Contrastes mesurés (backstop, deux thèmes, fond = `--elev` fondu sur `--bg`)

Sombre : traits `--text-3` 5,21 ; `--k-http` 7,44 ; `--k-call` 7,73 ; `--k-data` 9,67 ; `--k-event` 8,61 ; `--k-queue` 10,76 (tous >= 3). Texte `--text` 15,03 ; `--text-2` 8,56 ; `--text-3` 5,21 ; `--text-4` 2,66 (sous 4,5 : réservé au « +N », aux absences de commande, texte non essentiel, comme le dit l'UI-SPEC §6). Clair : traits `--text-3` 6,95 ; `--k-http` 5,68 ; `--k-call` 6,06 ; `--k-data` 4,89 ; `--k-event` 4,85 ; `--k-queue` 4,14 (>= 3). Texte `--text-4` 5,69.

## Captures (scratchpad, pour le juge de design)

- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-06-tiroir-sombre-1440.png
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-06-tiroir-clair-1440.png
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-06-tiroir-sections-clair-1440.png (Tags, Stash, Auteurs, mergées dépliés)
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-06-tiroir-mobile-768.png

Constat visuel : un arc sombre très fin sur le bord haut du tiroir en thème clair apparaît aussi sur le coin de `#panel` : artefact de transition d'ombre juste après le changement de thème de la capture, non propre au tiroir.

## Écarts et points à décider

1. **Pas de capture à 375, 700, 1000 px** : seule la mise en page mesurée (D3.5, D3.6) les couvre ; 768 et 1440 ont une image.
2. **Section isolée en échec** (UI-SPEC §3 « une section isolée en échec dit Indisponible ») : non faite, le serveur sert tout ou rien (un échec = `etat: indisponible` pour tout le tiroir).
3. **44 px tactile** : la suite l'établit par la requête de largeur (< 1000 px) ; `pointer: coarse` n'est pas émulable par `chrome-session.mjs` (même constat qu'en 78-04). Le rendu suit le changement de requête (re-rendu du graphe) : D2.2 attend la colonne de 44 px, une première version mesurait avant le re-rendu.
4. **Pas de commande pour une branche distante mergée** : le serveur sert `null`, le tiroir dit « Aucune commande proposée » (UI-SPEC : l'UI montre l'absence).
5. **Le pied « n commits affichés. »** remplace « 60 derniers commits » (la fenêtre servie est de 500) ; « Historique tronqué » si `bornes.tronque`.
6. **Divergence de schéma 78-05 : aucune bloquante.** Le témoin du prédécesseur porte un champ `suite` non servi (inoffensif).
7. **Mutant ajouté non demandé** : M-HORS-DEPOT (le négatif « hors dépôt » ne pouvait pas rougir sans lui).

## Suites rejouées (rc)

`test-cockpit-git-tiroir.sh` 60/0/0 · `test-cockpit-vendor.sh` 117/0 · `test-cockpit-git-entete.sh` 0 · `responsive` 0 · `chrome-fr` 0 · `terminal-tiroir` 0 (62/0) · `assemblage` 0 · `marque-blanche` 0 · `onglet-code` 0 (les sept voisines rejouées avant les trois derniers réglages de feuille de 77, sans effet sur elles : le tiroir est fermé dans leurs scénarios). Gates : `css-jetons.mjs` 0 sur les deux fichiers, `check-file-size.sh` OK (171 et 180 lignes), aucun `postMessage` ni `innerHTML`.

## Correction T7.5 (2026-11-06)

Le tiroir Git ne nomme plus le Terminal (`--vf-term-reserve`, `.vf-term-*` retirés de `77-vf-git-tiroir.js`, `bottom: 16px` en CSS) : il suit le bas de `#stage` (ResizeObserver) et monte au-dessus des petits éléments fixed/absolute du coin bas (zoom, pastille, puce). T7.5 vert, D3.4 et terminal-tiroir verts, deux mutants rouges ; détail dans `78-06-RED-TRACE.md` §Correction T7.5. Jeton : `bottom: 16px` -> bord de fenêtre (jeton `--edge` après rebase 71.5).
