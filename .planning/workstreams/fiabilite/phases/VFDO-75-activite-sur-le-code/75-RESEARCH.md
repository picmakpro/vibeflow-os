# Phase 75: L'activité posée sur le code — Research

**Researched:** 2026-11-11 (temps 2, sur les contrats de la 79 amendés jusqu'à A28, commit `6f66d878`)
**Base lue :** worktree de la phase, `f763b556` (code) ; `75-CONTEXT.md` (`a62a9dfb`) ; ACTV-01..12.
**Domain:** socle Node du cockpit (git en lecture, route GET), moteur vendorisé (canevas, pied de carte), suites bash.
**Confidence:** HIGH sur le code présent et les algorithmes CI ; MEDIUM sur les points d'accroche de la 79 non encore livrés.

<user_constraints>
## User Constraints (from CONTEXT.md)

Les décisions **P75-D-01 à P75-D-21** de `75-CONTEXT.md` (§ `<decisions>`) sont verrouillées ; le CONTEXT fait foi, il n'est pas recopié en entier. Résumé opposable : lentilles exclusives Aucune / Points chauds / Couplage / Gardes / Empreinte dans l'entrée de menu qui portait « Travail récent » (D-02, D-20) ; glyphe à trois paliers neutre + mot dans l'emplacement droit du pied, seule teinte `--recent` pour l'écriture en cours (D-01) ; géométrie invariante, aucune relance du placement (D-03) ; palier maximal + compte aux ancêtres (D-04) ; canal de marquage unique sous `window.Floorplan`, partagé avec la 74 (D-05) ; points chauds 90 j / 5 000 commits × `loc`, `-M` (D-07) ; couplage aux seuils code-maat, à la sélection seulement (D-08) ; tâche asynchrone mono-vol sur la signature, route GET `vibeflow/cockpit-activite@1`, `envGit` / `lancerGitAsync`, aucun cache disque (D-09) ; collisions committées par paires de HEAD, ≤ 12 HEAD (D-10) ; dégradation (D-11) ; empreinte depuis `cibles` (C3), en mémoire (D-12, D-13) ; normalisation `{arbre, chemin}` (D-14) ; radar à trois sources (D-15) ; gardes = règle de
`ci-suites-perimetre.sh` sans la part module + suite d'équivalence (D-16, D-17) ; cartes prévues après la construction (D-18) ; constats de l'auditeur reportés (D-19) ; retrait du « Travail récent » dans le même lot (D-20) ; témoins rouges sur la base, mutants, preuve générative (D-21).
**Claude's Discretion :** découpage en modules sous `plugin/cockpit/scripts/` (≤ 300 lignes), nom de la route, glyphes (UI-SPEC), format interne des caches. **Deferred (hors périmètre) :** constats de l'auditeur sur les cartes ; `--numstat` ; cache disque ; `git status` périodique ; empreinte au-delà de 24 h (Q-75-2).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (abrégée) | Ce que la recherche fournit |
|----|----|----|
| ACTV-01 | Sélecteur à la place de « Travail récent », géométrie invariante | P3, Obstacle O-1, Piège 6 |
| ACTV-02 | Glyphe + mot dans le pied, contraste, nom accessible | P3 (emplacement `.mk`) |
| ACTV-03 | Canal de marquage unique `window.Floorplan` | P3, plan 75-06 |
| ACTV-04 | Tâche mono-vol, route GET gardée, schéma | P1, P2, schéma § Code |
| ACTV-05 | Points chauds 90 j / 5 000, `-M`, paliers | P1, Pièges 1-3 |
| ACTV-06 | Couplage code-maat, mutants par seuil | P1, Obstacle O-3 |
| ACTV-07 | Gardes + suite d'équivalence | § Gardes |
| ACTV-08 / 09 | Empreinte depuis `cibles` ; normalisation + preuve générative | P2, Obstacle O-2, Piège 4 |
| ACTV-10 | Radar trois sources | P1 (branches), P2 (agents, plans) |
| ACTV-11 | Cartes prévues | P4 |
| ACTV-12 | Retrait, non-régression, XSS, docs | § Retrait |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Français dans le code, les commits, les docs ; commits par pathspec ; décision humaine citée avec canal et date ; identifiants préfixés (`P75-D-xx`) ; jamais de fix sans validation humaine ; « ne pas supprimer pour verdir ».
- Fichier de code ≤ 300 lignes : `BLOCK="${VF_ARCH_BLOCK:-300}"` (`plugin/software-architecture/scripts/check-file-size.sh:26`) `[VERIFIED: lu]`.
- Un commit qui touche un gate, sa suite, `ci.yml`, un hook ou une fixture surveillée porte `Gate-Touche:` (G-2). La 75 ne touche ni `scripts/check-*.sh` ni `scripts/tests/` : ses suites vivent sous `plugin/cockpit/scripts/tests/` (hors surface).
- Compteur « N suites » des README racine gaté par `scripts/check-version-sync.sh:131-139` (`find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh'`) `[VERIFIED: lu]`. Pas de release pour du planning.

## Summary

La Phase 75 n'ajoute aucune dépendance : Node (déjà requis), git en lecture par l'exécuteur durci existant, le moteur vendorisé. Son cœur est un **calcul côté serveur**, en modules purs testables sans navigateur, qui produit un objet
`vibeflow/cockpit-activite@1` : points chauds et couplage (un seul `git log --name-status -M -z` par signature), collisions committées (merge-base par paire de HEAD), gardes (relecture des suites et de `ci.yml`), empreinte normalisée et collisions d'agents et de plans (projection de frise et graphe Projet en mémoire). La page ne fait qu'appliquer des marques déjà calculées par un **canal unique** posé dans `viewer.html`, qui patche le DOM en place sans relancer la mise en page.

Quatre frictions factuelles sont signalées en tête (Obstacles) : la réservation du pied (D-03) contre « carte identique octet pour octet » sans git (D-11) ; l'accès en processus à la projection de frise et au graphe Projet, que les contrats ne nomment pas ; un seuil de code-maat qui ne peut pas avoir de mutant tueur ; la forme de `VENDORED.txt` après 79-01.

**Primary recommendation :** tout calculer dans `vf-cockpit-activite*.mjs` (7 modules ≤ 300 lignes), servir par une ligne de la table des routes, et réduire la page à un sélecteur + un canal de marquage qui ne déclenche jamais `render()`.

## Obstacles (factuels, à trancher avant les plans)

- **O-1 — Pied réservé contre « octet pour octet ».** `cardExtraH` (`viewer.html:1000-1006`) n'ajoute `FOOT_H` que si `cardFoot(item)` (`:986-999`) rend quelque chose ; `const FOOT_H = 28;` (`:982`) `[VERIFIED: lu]`. Une carte de fichier sans taille ni statut n'a pas de pied : y poser une marque change sa hauteur et relance ELK (contraire à D-03). La seule parade fidèle à D-03 : **réserver le pied dès que le sélecteur existe**, quelle que soit la lentille. Sur un lab sans git, l'Empreinte reste offerte, donc la carte n'est plus identique à la base. Lecture recommandée de D-11 / P78-D-11 : « identique » porte sur les **données** (`graph.json`, aucune lentille ni mot git) ; le témoin compare la carte sans git à la carte avec git **sans lentille git active**. Décision d'exécution du manager, aucun arbitrage rouvert.
- **O-2 — Accès en processus à la frise et au graphe Projet.** C3 ne livre qu'une route ; aucun contrat n'expose au serveur la projection `voies[]` (`cibles`, `etatOfficiel`, `parent`, `arbre`, `fin`), et A27 suppose sans le nommer un accès au graphe Projet « déjà rafraîchi sur `structural` ». Modèle existant d'accesseur injecté : `lancer.sourceWho(() => (live ? live.snapshot().who : null))` (`vf-cockpit-server.mjs:76`) `[VERIFIED: lu]`. **Manques n° 8 (frise) et n° 9 (Projet) à relayer à la 79.** Repli si refus : la page lit `GET /api/vf/frise?champs=cibles` (A28) et normalise dans `ui/` (preuve par sondes Chrome seulement). Plans 75-03 et 75-04 **« à revalider »** sur ce seul point.
- **O-3 — Seuil « ≥ 5 révisions par fichier » sans mutant tueur.** Dans code-maat, `min-revs` s'applique à la **moyenne** (`(within-threshold-fn? average-revs shared-revs coupling)`), et `shared-revs ≥ 5` implique déjà ≥ 5 révisions par fichier `[CITED: github.com/adamtornhill/code-maat, logical_coupling.clj et coupling_algos.clj]`. Avec les défauts 5 / 5, retirer le contrôle par fichier ne change aucun résultat : mutant équivalent. Parade : seuils exportés (`SEUILS_COUPLAGE`) et options injectables par le test (ex. `{ minRevs: 6, minCommunes: 3 }`) pour que chaque contrôle ait un témoin qui le tue (ACTV-06).
- **O-4 — `VENDORED.txt` après 79-01.** C6 le réduit à « l'origine, la sentinelle du moteur et l'inventaire du plafond » ; D-20 demande une ligne `RETRAIT` par fichier retiré. Si la forme livrée n'a plus de lignes `RETRAIT`, le retrait se trace dans l'inventaire du plafond et dans le CHANGELOG du module. **À revalider** sur le fichier réel.

## Architectural Responsibility Map

| Capacité | Tier principal | Secondaire | Motif |
|---|---|---|---|
| Points chauds, couplage, collisions committées | API / socle (`vf-cockpit-activite-git*.mjs`) | — | git durci, testable sans navigateur, hors boucle de collecte |
| Gardes (suites, gates) | API / socle | — | lecture confinée du lab, rien d'exécuté (P68-D-34) |
| Empreinte, normalisation, collisions d'agents et de plans | API / socle | Navigateur (repli O-2) | données en mémoire du serveur (C3, A27) |
| Cartes prévues | Assemblage (annotateur A27) | — | le graphe Code s'écrit sur disque à l'assemblage |
| Marques, sélecteur, panneau | Navigateur (`viewer.html` + `ui/74-vf-activite.js`) | — | DOM en place, aucune relance du placement |

## Standard Stack

Aucun paquet externe. Poste : Node `v26.5.0`, git `2.50.1` `[VERIFIED: mesure]`.

| Brique réutilisée (fichier:ligne) | Usage dans la 75 |
|---|---|
| `lancerGitAsync(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git', fin } = {})` (`vf-cockpit-paths.mjs:249-261`) | tout git ; `binaire` « ne sert qu'aux tests » : espion d'argv `[VERIFIED: lu]` |
| `envGit` (`paths.mjs:135-143`), `DURCISSEMENT_CONFIG/ENV` (`vf-cockpit-git-durci.mjs:10-16`) | appliqués d'office par `lancerGitAsync` |
| `OPTIONS_LECTURE.log` = `['--no-ext-diff', '--no-textconv', '--no-show-signature']` (`paths.mjs:150`) | insérées d'office après la sous-commande |
| `finDans(ms)` (`paths.mjs:177`) | échéance globale de la tâche |
| `monoVol(cle, lire)` (`vf-cockpit-git.mjs:34-41`, non exporté) | à **exporter** tel quel (un vol + une suivante partagée) |
| `lireWorktrees`, `MOTIF_SHA = /^[0-9a-f]{40}$/` (`vf-cockpit-git-graphe.mjs:50-67`, `:6`) | HEAD des worktrees (D-10) |
| `worktreeVerifie(communReel, chemin)` (`vf-cockpit-git-details.mjs:107-122`) | seuls les worktrees vérifiés entrent dans les paires (P78-D-38) |
| `lireNumstat` (`git-details.mjs:27-43`) | modèle de parseur aligné NUL |
| `nettoie(s, max)` (`vf-cockpit-arbres.mjs`) | chaînes **affichées** seulement (Piège 4) |
| `compileGlob` (`skills/cockpit-moteur/scripts/lib/common.mjs:54-63`) | rattachement des cartes prévues |
| `lireConfine` / `read` (`vf-cockpit-planning.mjs`) | lecture des suites et de `ci.yml` du lab (A12) |
| `socle-serveur.sh` (A6, 79-02) : `cockpit_lancer`, `cockpit_get`, `attendre` | suites qui lancent le serveur |

**Seuils code-maat** `[CITED: github.com/adamtornhill/code-maat README + sources]` : `min-revs` 5, `min-shared-revs` 5,
`min-coupling` 30, `max-coupling` 100, `max-changeset-size` 30 ; degré = révisions communes ÷ moyenne des révisions des deux fichiers ; un ensemble est écarté si `(> (count change-set) max-size)` (31 fichiers et plus exclus, 30 gardés).

## Package Legitimacy Audit

Aucun paquet installé par la phase. **Removed :** none. **Flagged :** none.

## Architecture Patterns

### Flux

```
git (lab, worktrees) ──lancerGitAsync──▶ activite-git (log -M : chauds, couplage) ──┐
                     └─merge-base/diff-tree──▶ activite-branches (paires de HEAD) ──┤
suites + ci.yml du lab ──lireConfine──▶ activite-gardes (règle CI sans module) ─────┤ cache mémoire,
projection de frise (accesseur, O-2) ──▶ activite-chemins ──▶ activite-empreinte ───┤ clé = refs + HEAD
graphe Projet en mémoire (A27, O-2) ──▶ collisions « prévues » (même vague) ────────┘ mono-vol
                                                  │
        GET /api/vf/activite : 1 ligne de la table (A10/A26) + réponse gardée (A11, porteInterdit)
                                                  │
page : VF_ETAT.abonner('git' | 'frise' | 'planning') ──▶ relit la route ──▶ Floorplan.marques.poser(couche, table)
        └──▶ remplace le contenu de `.mk` de chaque carte via state.chipEls : jamais render() ni rerender()
assemblage : build du moteur ──▶ annotateur « prévues » (table de vf-cockpit-build.mjs, A27) ──▶ graph.json
```

### Modules neufs (`plugin/cockpit/scripts/`, chacun ≤ 300 lignes)

| Fichier | Rôle |
|---|---|
| `vf-cockpit-activite.mjs` | assemble l'objet, clé de cache, mono-vol, lecteur de la ligne de table (`routeActivite`) |
| `vf-cockpit-activite-git.mjs` | `lireLog` aligné (pur), renommages, `pointsChauds`, `couplage` ; constantes `FENETRE`, `SEUILS_COUPLAGE`, `BRUIT` |
| `vf-cockpit-activite-branches.mjs` | paires de HEAD vérifiés, `merge-base` + `diff-tree -r --no-renames --name-only -z`, cache par paire |
| `vf-cockpit-activite-gardes.mjs` | découverte des suites, gates de `ci.yml`, règle de citation, six classes « est une garde » (pur sur entrées) |
| `vf-cockpit-activite-chemins.mjs` | `normaliser({arbre, cible}, contexte)` → `{etat: carte | hors-carte | hors-lab, chemin}` ; garde de `files_modified` (pur) |
| `vf-cockpit-activite-empreinte.mjs` | degrés, noms affichés, collisions d'agents et de plans (pur) |
| `vf-cockpit-activite-prevues.mjs` | annotateur A27 : cartes `st: 'prevu'` rattachées par la règle du moteur (pur sur entrées) |

### P1 — Calcul git (ACTV-04, 05, 06, 10)

- **Clé de cache** : `sha256` de `for-each-ref --format=%(objectname) %(refname)` + `worktree list --porcelain -z`, calculée **à chaque requête** (~30 ms, P75-D-09). Ne pas appeler `signatureGit` : elle rend `null` quand le tick de 5 s est en vol (`vf-cockpit-git-signature.mjs:22`) et hache aussi les index (un `git add` relancerait tout).
- **Requête** : clé inchangée → cache. Clé changée → tâche lancée (mono-vol) et réponse immédiate avec l'objet précédent et `calcul: "en-cours"` (D-09 « une requête pendant le calcul répond ») ; tout premier calcul : `etat: "en-calcul"`. La page relit à l'événement `git` (C4) et, tant que `calcul` vaut `en-cours`, une fois par seconde au plus 15 fois (attente bornée).
- **Commande** (unique ; mesurée ici sur 90 j : 973 271 octets, 0,215 s, plus gros commit 339 fichiers) `[VERIFIED: mesure]` : `log --no-merges -M -l400 --name-status -z --format=%x00%H%x00%at --since=90.days -n 5000 HEAD --`, par `lancerGitAsync(lab, args, { fin, maxBuffer: 32 << 20 })`. Disposition des octets mesurée : `\0<H>\0<at>\0` puis `\n<St>\0<chemin>\0…`, commit suivant introduit par `\0` (parseur § Code Examples).
- **Incrémental** (D-09) : garder `[{h, at, chemins}]` (≤ 5 000) ; si l'ancien HEAD est ancêtre (`merge-base --is-ancestor`), ne lire que `ancien..HEAD`, préfixer, purger ce qui sort des 90 jours, recalculer les agrégats (millisecondes). Sinon relecture complète. Témoin : espion `binaire` qui journalise argv.
- **Renommages** : parcours du plus récent au plus ancien ; à `R<nn>\0ancien\0nouveau`, `alias[ancien] = alias[nouveau] ?? nouveau` ; les commits plus anciens qui citent `ancien` comptent pour le chemin actuel. Un chemin recréé après un renommage reste juste (l'alias n'agit que sous le renommage).
- **Points chauds** : score = commits × `loc` (de `graph.json`), servi en rang et palier. **Couplage** : commits ≤ 30 fichiers, bruit retiré avant comptage (`CHANGELOG.md`, `VERSION`, `plugin.json`, `marketplace.json`, `module.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Cargo.lock`, `go.sum`) `[ASSUMED : liste à figer au plan]` ; paire gardée si communes ≥ 5, chaque fichier ≥ 5, degré ≥ 30 % ; 5 voisins au plus, triés par degré puis chemin.
- **Collisions committées** (D-10) : HEAD distincts des worktrees **vérifiés**, plafond 12 ; `merge-base A B`, puis `diff-tree` de chaque côté, intersection ; cache par paire de sha triée ; 66 paires × 3 git sous l'échéance globale (15 s, comme `BORNES.echeanceMs` de la 78) : au-delà, « indisponible » sur la lentille seule. Chemins rendus relatifs au **lab** (préfixe `rev-parse --show-prefix` retiré).

### P2 — Route, schéma, empreinte (ACTV-04, 08, 09, 10)

- **Inscription** : une ligne de la table des routes (A10/A26 ; ordre alphabétique : `/api/vf/activite` vient en tête) et la réponse gardée commune (A11). À la base, la répartition est une suite de `if` (`vf-cockpit-server.mjs:80-119`) : la table n'existe qu'après 79-05.
- **Schéma** `vibeflow/cockpit-activite@1` dans le bloc `schemas` de `vf-cockpit-interface.json`, avec la liste recopiée `"interdits": ["doing", "mandat", "messages", "outils", "fil"]` (`vf-cockpit-interface.json:24`, `:37`) `[VERIFIED: lu]`. `porteInterdit` teste les **clés d'objet** à toute profondeur (`server.mjs:35`) : **jamais un chemin, une branche, un rôle ou un titre comme clé** (un fichier `fil` à la racine d'un lab ferait refuser toute la réponse en 503 ; `__proto__` corromprait l'objet). Tout est servi en **tableaux de tuples**.
- **Empreinte (serveur, sous O-2)** : A22 donne `cible` relative à la racine réelle de l'arbre de la voie, A23 la résolution physique, A24 `lectures` = `Read`, `ecritures` = `Write`, `Edit`, `MultiEdit`, `NotebookEdit` : la 75 ne rejuge aucun chemin. `normaliser` : libellé « un fichier hors du lab » → `horsLab` ; sinon chemin relatif au lab (préfixe du lab dans l'arbre retiré quand le lab n'est pas la racine du dépôt : **à revalider**, A22 est muet sur ce cas) ; carte connue → dessinée, sinon `horsCarte`. Degrés : voie `actif` et écriture la plus récente de la voie → `en-cours` ; voie non `termine` → `modifie` / `lu` ; `termine` dans les 24 h → `fini`. Nom : `role`, puis `· nœud X` si `rattachement.noeud`, puis l'arbre si deux voies vivantes partagent le rôle ; jamais `id`.
- **Collisions d'agents** : même chemin dans les `ecritures` de deux voies ; arbres différents → signal tant que les deux worktrees existent ; même arbre → si les deux sont vivantes et ni parent ni enfant l'une de l'autre ; `lectures` jamais ; `cibles.etat === "en-construction"` → `empreinte.etat: "en-construction"` et mot « radar incomplet ».
- **Collisions prévues** : plans non faits du graphe Projet groupés par (phase, vague), intersection des `touched`. La vague n'est que dans le texte du pied : `foot: \`vague ${meta.wave || '?'}…\`` (`vf-cockpit-project.mjs:131`) `[VERIFIED: lu]` → ajouter un champ facultatif `vague` à l'élément de plan (C0 l'autorise sans changer de version) plutôt que reparser le pied.
- **Fraîcheur** : la page relit au chargement, à `frise` (A21 : la signature couvre `cibles`), à `git`, à `planning` (A13).

### P3 — Canal de marquage et page (ACTV-01, 02, 03)

- **Patch `viewer.html`** (moteur ; après la vague 3 de la 79, qui le touche, A7) :
  - `cardFoot` réserve `<span class="mk"></span>` à droite sur toute carte de fichier et de nœud dès que `Floorplan.marques.reserver(true)` est appelé **avant le premier rendu** ; `cardExtraH` compte alors toujours `FOOT_H`. La réservation se décide au chargement (sélecteur présent), jamais par lentille (O-1).
  - `Floorplan.marques` : `poser(couche, table)` avec `table = [[id, palier, glyphe, mot, infobulle]]`, `retirer(couche)`, `active()`. Agrégat aux ancêtres par `chain(id)` (déjà exposé) : palier max + compte. Application **en place** par `state.chipEls` (rempli par `draw`, `:1201`) : contenu de `.mk` et `aria-label` de la carte, sans `render()` ni `rerender()` (ce dernier relance la mise en page, `:2564`). À l'événement `render` (navigation), réapplication de la couche active aux cartes nouvellement dessinées.
  - Pile de couches : `poser` d'une autre couche masque la précédente, `retirer` la rend (témoin ACTV-03). La 74 (relecture, AUDC-I06) pose sa couche par la même API ; si elle l'a déjà livrée, la 75 l'étend (**à revalider** à la jointure, D-05).
- **`ui/74-vf-activite.js`** (neuf ; les scripts `ui/` sont insérés par ordre de nom, `scripts/build.mjs:448`, donc après `70-vf-live.js` et avant les dictionnaires `78-80`) : bouton sélecteur à la place de `btn-recent` (même `addHeaderButton`, même passage dans le menu « ⋯ » par `02-vf-telephone.js`), légende des paliers, sections « Change souvent avec » et collisions par `addPanelSection('item', …)`, abonnements `VF_ETAT` au `ready`. Chaînes en français (convention `ui/*vf*`), rendues par `h()` ou `textContent`.

### P4 — Cartes prévues (ACTV-11)

- Annotateur d'une ligne dans la table de `vf-cockpit-build.mjs` (A27, 79-05 ; **signature à revalider** : il lui faut `project`, déjà calculé l. 69, et `architecture.json` de la sortie).
- « Par les globs du moteur » : la règle (profondeur, spécificité, `exclude` hérités) est **inline** dans le moteur (`scripts/build.mjs:116-145`) et les nœuds de `graph.json` ne portent pas `exclude`. Parade : l'extraire dans une fonction exportée de `scripts/lib/common.mjs` (à côté de `compileGlob`), appelée par `build.mjs` **et** par l'annotateur sur `architecture.json` ; sinon divergence silencieuse. Patch du moteur → après 79-01.
- Élément : `{ p, n, r, l: 'prevu', loc: 0, name, d: '', st: 'prevu' }`, seulement pour un plan non fait, chemin absent du scan et absent au `lstat`. Statut à ajouter : `const STATE_WORD = { done: 'Fait', active: 'En cours', recette: 'À recetter', todo: 'À faire', blocked: 'Bloqué' };` (`viewer.html:1630`) n'a pas `prevu` → `prevu: 'Prévu'`, et `--st-prevu` à côté de `--st-done … --st-recette` (`ui/00-vibeflow.js:40`) `[VERIFIED: lu]`. « Ouvrir dans l'éditeur » (`itemMenu`, `:1302-1303`) absent si `st === 'prevu'` ; la taille est déjà masquée quand un statut existe (`cardTip`, `:1057`).
- Santé : les `stats` de nœud viennent du moteur, avant l'annotateur (`statsOf`, `:848-853`) ; **mais** un dossier virtuel (`type 'dir'`) compte `i.d.files` côté page : y filtrer `st !== 'prevu'`.
- Export : l'export serveur retire déjà `vfTouch` et `vfGit` de `meta` (`serve.mjs`, `(({ vfTouch, vfGit, ...m }) => m)(g.meta)`) ; retirer aussi les fichiers `st: 'prevu'` (donnée de planning, même motif). Fichier du moteur que la 79 modifie : après elle.

### Anti-Patterns

`SC.rerender()` pour une mise à jour d'empreinte (relance ELK) ; un chemin comme clé d'objet ; une `RegExp` construite depuis un motif lu dans une suite (ReDoS) ; `git status` / `git diff` contre l'arbre (P78-D-21) ; `--follow` par chemin.

## Gardes (ACTV-07) — algorithme à reproduire en JS, sans rien exécuter du lab

**Découverte** (`scripts/ci-shard-suites.sh:257`, verbatim) : `discover() { find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort; }`
`[VERIFIED: lu]`. En JS : marche du système de fichiers sous `plugin/` et `scripts/` (`lstat`, liens symboliques ignorés comme
`-type f`, `.git` et `node_modules` sautés, plafond 20 000 entrées), motif sur le chemin relatif où `*` **traverse `/`** (sémantique de `find -path`) : `/^(plugin|scripts)\/.*\/tests\/test-.*\.sh$/` ; tri par points de code.

**Règle « citée »** (`scripts/ci-suites-perimetre.sh:51-54, 87-94, 175-188, 190-222`) :
1. `cite_files(m)` = suites dont le contenu **contient** `m` (`grep -lF` : sous-chaîne, pas un mot).
2. `ambigu(nom, chemin)` : nombre de fichiers suivis (`git ls-files`) de même nom, +1 si le chemin n'est pas suivi ; ambigu si ≥ 2.
3. Fichier `f` (nom `n`, dossier `d`) : suites citant `f` ∪ (non ambigu ? suites citant `n` : suites citant `n` **et** (citant `d` ou, sous `plugin/<m>/…`, citant `m`)).
4. Citation par motif : jetons d'une suite contenant `*` et `plugin` ; ``"'();|<>`,`` retirés ; préfixe ramené à `plugin/` (ou `${…PLUGIN…}/` → `plugin/`) ; motif finissant par `/` → `motif*` ; `f` retenu si `case "$f" in $m|$m/*)` (le `*` de `case` traverse `/`). **En JS : correspondance glob linéaire** (itérative, un point de reprise), jamais une `RegExp` construite.
5. **Hors témoin** : la part « module » (l. 170-173) et les classes `doc` / `partage` / `hors`.

**Gates** : la règle CI ne lit que les suites ; D-16 y ajoute « un gate appelé par `ci.yml` ». Jetons de `ci.yml` correspondant à
`[\w./-]*check-[\w.-]+\.sh`, `./` retiré, gardés s'ils sont des fichiers suivis du lab. Mesuré : `scripts/check-*.sh`,
`plugin/conductor/scripts/check-*.sh`, `plugin/dev-orchestrator/scripts/check-*.sh`, `manual/.tools/check-manual.sh` ;
`.claude/scripts/…` et `FIX/…` écartés (absents du dépôt) `[VERIFIED: grep de ci.yml]`. La sonde du panel (`(?:plugin\/conductor\/)?scripts\/check-…`) manquait `dev-orchestrator` et `manual`.

**« Est une garde »** : six classes de `scripts/check-gate-touche.sh:213-229` reproduites telles quelles —
`plugin/conductor/scripts/check-*.sh` et `scripts/check-*.sh` (un seul segment, reste > 9), `plugin/conductor/scripts/tests/test-*.sh` et `scripts/tests/test-*.sh` (reste > 8), `.github/workflows/ci.yml`, `scripts/hooks/*`, et `…/tests/fixtures/*` des deux préfixes `[VERIFIED: lu]`. Un seul tableau dans `activite-gardes.mjs`, confronté au script par la suite (ci-dessous).

**Zone sans témoin** : carte de code (ni doc, ni suite, ni fixture) non gardée → « aucune suite ne le nomme ». **Lab non VibeFlow** : lentille absente si `meta.vfCodeExtractor !== 'vibeflow'` (détection `plugin/*/module.json`,
`vf-cockpit-code.mjs:4-11`). Coût mesuré par le panel : < 1 s pour 213 suites `[CITED: mesure du panel, mesure-gardes.mjs]`.

**Protocole de la suite d'équivalence** (`test-cockpit-activite-gardes.sh`) : dépôt fixture dans `$WORK` (`git init`) avec copie de `scripts/ci-suites-perimetre.sh` et `scripts/ci-shard-suites.sh` du dépôt ; `plugin/a/module.json` **sans** suite (tout
`jouee` est alors une citation, jamais un motif `module`) ; `plugin/t/module.json` + suites témoins couvrant : (1) chemin complet, (2) nom unique, (3) nom ambigu cité avec son dossier, (4) nom ambigu cité avec le module seul, (5) motif
`plugin/a/*.mjs`, (6) fichier non cité, (7) nom ambigu cité sans dossier ni module. Pour chaque témoin `f` : un commit qui ne touche que `f`, `bash scripts/ci-suites-perimetre.sh --liste <base> <head>` → ensemble CI ; `suitesQuiNomment(f)` → ensemble socle ; égalité exigée sur les 7. Parité des six classes : un chemin témoin par commit fixture, `chemins_surface=1|0` lu sur la ligne `decouverte:` de `check-gate-touche.sh`, comparé à `estGarde` (à confirmer au plan : le script peut sortir en erreur faute de marqueur `Gate-Touche`, la ligne se lit quand même). Mutants : règle d'ambiguïté retirée (rougit 7), motif retiré (rougit 5), `includes` → égalité de nom (rougit 2). Les scripts ne s'exécutent que dans la suite, jamais par le cockpit.

## Retrait (P75-D-20, ACTV-12) — inventaire mesuré

Commande : `rtk proxy grep -rnI -E "recent-work|25-recent|recentTip|recent\.mjs|no-recent|Travail récent|Recent work|graph\.recent|\.recent-in|\.recent\b|'rw'|\.rw\b|Récent" plugin scripts .github DESIGN.md README.md README.fr.md` (hors CHANGELOG et hors `plugin/cockpit/amont/`, retiré par 79-01) `[VERIFIED: grep]`. M = `plugin/cockpit/skills/cockpit-moteur/`.

| Fichier : lignes | Devient |
|---|---|
| `plugin/cockpit/scripts/vf-cockpit-build.mjs:70-80` | écriture de `recent-work.json` retirée ; un `recent-work.json` hérité de la sortie supprimé (`rmSync force` après `verifierSortie`) |
| M`assets/ui/25-recent.js`, M`scripts/recent.mjs` | supprimés ; `btn-recent` remplacé par le sélecteur (`74-vf-activite.js`) |
| M`assets/viewer.html:203, 220-227, 795-805, 982, 985, 997-998, 1036-1037, 1059, 1062-1072, 1615-1619` | `.rw`, `.recent`, `.recent-in`, `no-recent`, `recentTip`, bascule de légende retirés ; pied réservé à `.mk` ; jeton `--recent` **gardé** |
| M`assets/viewer.html:2249` (`showChangeResult`) | lit `G.recent` en mode plan seulement ; `const PLAN = !!G.meta.blueprint;` (`:671`), jamais posé par VibeFlow → laissé, noté |
| M`scripts/build.mjs:258-291, 415, 472-474` | lecture de `recent-work.json` et ligne de rapport retirées (consommateur devenu mort) |
| M`assets/graph-query.js:101-102, 172` ; M`assets/ui/60-export.js:35` | `recentWork` et partie d'export « Recent work » retirés |
| M`assets/serve.mjs:62, 399, 445` ; M`scripts/refresh.mjs:137, 173` ; M`references/schema.md:5, 103` | mode « Change » du blueprint, inatteignable dans VibeFlow, et `serve.mjs` tenu par la 79 : laissés, signalés (O-4) |
| M`assets/ui/78-vf-fr-dict-a.js:19, 119` ; M`assets/ui/80-vf-fr.js:97` | entrées `Recent work`, `Highlight recent work`, `Recent work inside`, `.rw` → `Récent` retirées |
| M`assets/ui/01-vf-responsive.js:9` ; M`assets/ui/02-vf-telephone.js:2, 7` | commentaires mis à jour ; budget de largeur à 1 024 px tenu (Piège 7) |
| `plugin/cockpit/README.md:335` ; `DESIGN.md:173, 180` | « le récent se dit par la pastille `.rw` » → marques de lentille ; `DESIGN.md:68` (`--recent`) inchangé |

**Suites — adaptées, jamais supprimées :**
- `test-cockpit-ecrans-recent.sh` : E1-E4 intacts ; R1/R2 (badge = cartes, panneau = cartes) deviennent « compte du sélecteur = cartes (un fichier écrit par deux agents = une carte) » et « agrégat du nœud = cartes » sur le canal ; la fixture `fixtures/test-cockpit-ecrans-recent/recent-doublons.json` devient une table de marques.
- `test-cockpit-onglet-code.sh` C6.3 (lit `recent-work.json`) → « aucun `recent-work.json` écrit » + « un plan non fait dont `files_modified` vise un fichier absent donne une carte `st: prevu` » (fixture : ROADMAP non cochée).
- `chrome-moteur-carte.mjs:242-254` et `test-cockpit-moteur-carte.sh:167-169` (K17) : le badge devient la pastille du sélecteur ; K17.2/3 (`showBoard` coupé à 24) gardés avec un `kind` neutre (la coupe est générique).
- `test-cockpit-responsive.sh:88-90, 173, 571` : `btn-recent` injecté → identifiant du sélecteur ; « huit entrées » tenu.
- `test-cockpit-chrome-fr.sh:76, 80, 165` (F13.3 « Recent work: Recent work ») → un autre fil d'Ariane `X: X` encore servi.
- `test-cockpit-securite.sh:360` (Y, sonde M4) : le lien symbolique posé sur `recent-work.json` passe sur **`.gitignore`**, écrit par le socle (`vf-cockpit-build.mjs:82`) ; Y1/Y2 inchangés ; témoin rouge : `verifierSortie` neutralisé → `dehors.txt` réécrit.
- Sans changement : `test-cockpit-signal-mod.sh:164` (jeton `--recent`), `chrome-lancer.mjs:122`, `test-cockpit-lancer-suivi.sh:169` (« récent » au sens du lancement).

**Runtime State Inventory :** données stockées — `recent-work.json` dans la sortie des labs déjà assemblés (supprimé au prochain assemblage) et clé `recent-hl` du `localStorage` (inerte, laissée) ; config de service, état du système, secrets : aucun (même grep) ; artefacts — copies du moteur dans le cache du plugin, remplacées par la mise à jour du module.

## Don't Hand-Roll

| Problème | Ne pas écrire | Utiliser |
|---|---|---|
| lancer git | `execFile('git')` | `lancerGitAsync` (durci, échéance, filtres, `gitSortant`) |
| deux calculs concurrents | drapeau booléen | `monoVol` exporté de `vf-cockpit-git.mjs` |
| HEAD de worktree fiable | lecture de `.git/worktrees` | `lireWorktrees` + `worktreeVerifie` |
| contrôles d'accès | copie des contrôles | réponse gardée A11 |
| rattachement par glob | second moteur de globs | règle extraite du moteur + `compileGlob` |
| chemin physique d'une cible | `realpath` maison | A22/A23 (la 79) |
| serveur en test | `node serve.mjs &` + `sleep` | `socle-serveur.sh` (A6) |

## Common Pitfalls

1. **Sortie tronquée ou désalignée.** 0,97 Mo ici, mais un commit vendorisé de 10 000 fichiers dépasse le défaut de 4 Mo. Parade : `maxBuffer: 32 << 20` ; `tronque` → « indisponible », jamais partiel (P78-D-22) ; parseur positionnel exigeant `MOTIF_SHA`, `at` entier, statut `/^([AMDTUXB]|[RC]\d{1,3})$/` (R et C → deux chemins), dernier jeton vide ; un chemin peut contenir `\n`, U+2028, une tabulation : seul NUL sépare. Témoins : commit vide, renommage, nom avec `\n`.
2. **Renommages au-delà de `-l400`** : non suivis (git l'écrit sur stderr, ignoré) ; dit dans la limite de la lentille.
3. **Quantiles sur petit dépôt et clone superficiel.** Sur 6 fichiers modifiés, trois quantiles mettent un fichier touché une fois au palier haut. Parade `[ASSUMED : seuil à fixer au plan]` : paliers à partir de 12 fichiers à score non nul, égalités au même palier, sinon un seul palier et le mot chiffré. Ce dépôt rend `rev-parse --is-shallow-repository` = `true`, limite au 2026-06-03, avant la fenêtre `[VERIFIED: mesure]` : dire « historique partiel » **seulement** si la limite superficielle est plus récente que le début de la fenêtre, sinon la mention serait fausse ici en permanence.
4. **Chemins hostiles** (`\u2028`, `..`, NUL, contrôle, lien symbolique, `__proto__`). Tuples jamais clés ; comparaison sur le chemin **brut**, `nettoie` à l'affichage seulement ; `files_modified` : rejeter absolu, `..` après `path.posix.normalize`, caractère de contrôle, > 4 096 octets (compté « ignoré ») ; « existe » = `lstat` sous le lab. **Preuve générative N/2N** (mémoire du dépôt : trois tours de ReDoS sans preuve générative) : pour toute fonction qui lit un motif ou un chemin, entrées de taille N et 2N (`'*'.repeat(N) + 'a'`, `'../'.repeat(N)`, `'\u2028'.repeat(N)`), exiger `t(2N) ≤ 4·t(N) + 5 ms` ; le mutant « RegExp naïve » doit rougir.
5. **Clé interdite par accident** : témoin = un lab avec un fichier racine `fil` et une branche `messages` → 200.
6. **Géométrie** (O-1). Témoin : `state.layout.children` (x, y, w, h ; A4) sérialisé avant et après chaque bascule et après une mise à jour d'empreinte, identique ; compteur sur `VibeFlow.on('render', …)` à 0. Mise en page en worker (A4) : attendre la stabilité avant de mesurer.
7. **Largeur d'en-tête** : `01-vf-responsive.js` borne la barre à 1 024 px avec les boutons optionnels ; un libellé plus long que « Travail récent » peut faire sortir un bouton. Libellé court (UI-SPEC) et R13.3 rejoué.
8. **Reconstruction des cibles** : `cibles.etat: "en-construction"` → jamais « aucune collision » ; relecture à `frise`.
9. **Export autonome** : les marques vivent dans le DOM, l'export part de `graph.json` côté serveur ; témoin A25 : marqueur unique dans les `cibles` et dans `/api/vf/activite`, absent de l'export, présent quand placé dans une note de fichier exportée (témoin positif).
10. **Lab hors dépôt / git absent / `gitSortant`** : `lancerGitAsync` rend `refuse` ou `absent` → lentilles git **absentes** (pas « indisponible »). Lab non VibeFlow : gardes absentes, et le dit.
11. **Latence** : la 78 mesure 0,1-0,45 s d'attente par lancement sous charge (`vf-cockpit-git.mjs:30-31`) ; échéance 15 s, plafond écrit, mono-vol.

## Code Examples

```js
// Parseur positionnel de `log -z --name-status --format=%x00%H%x00%at` (disposition mesurée sur ce dépôt)
const STATUT = /^([AMDTUXB]|[RC]\d{1,3})$/;
export function lireLog(sortie) {
  if (typeof sortie !== 'string') return { ok: false, raison: 'sortie absente' };
  const j = sortie.split('\0'); if (j.pop() !== '') return { ok: false, raison: 'sortie coupée' };
  const commits = []; let i = 0;
  while (i < j.length) {
    if (j[i] !== '') return { ok: false, raison: 'entête attendu' };
    const h = j[i + 1], at = j[i + 2];
    if (!MOTIF_SHA.test(h) || !/^\d+$/.test(at)) return { ok: false, raison: 'entête mal formé' };
    const c = { h, at: Number(at), entrees: [] }; i += 3;
    while (i < j.length && j[i] !== '') {
      const st = j[i].replace(/^\n/, ''); if (!STATUT.test(st)) return { ok: false, raison: 'statut' };
      const n = /^[RC]/.test(st) ? 2 : 1; if (i + n >= j.length) return { ok: false, raison: 'chemin coupé' };
      c.entrees.push({ st: st[0], chemins: j.slice(i + 1, i + 1 + n) }); i += 1 + n;
    }
    commits.push(c);
  }
  return { ok: true, commits };
}
// [ASSUMED] forme d'un commit vide (aucune entrée) : à confirmer par la fixture avant de figer le parseur.
```

Forme proposée du schéma (aucune clé interdite, tableaux de tuples) :

```json
{ "schema": "vibeflow/cockpit-activite@1", "at": "<ISO>", "etat": "ok|en-calcul|indisponible|absent", "calcul": "pret|en-cours",
  "git": { "etat": "ok|vide|indisponible|absent", "fenetre": { "jours": 90, "commits": 0, "plafond": 5000, "plafondAtteint": false, "partiel": false },
           "chauds": [["<chemin>", 41, 210, 1, 3]], "couplage": [["<a>", "<b>", 7, 64]] },
  "branches": { "etat": "ok|indisponible", "tetes": 9, "plafondAtteint": false, "collisions": [["<chemin>", ["<branche>", "<branche>"]]] },
  "gardes": { "etat": "ok|non-lues", "gardes": [["<chemin>", 3, 1]], "estGarde": ["<chemin>"] },
  "empreinte": { "etat": "ok|en-construction|indisponible", "marques": [["<chemin>", "en-cours|modifie|lu|fini", ["<nom affiché>"]]],
                 "horsCarte": 0, "horsLab": 0, "limite": "ecritures-par-commande-non-vues" },
  "collisions": [["<chemin>", "agents|branches|plans", ["<nom>"], "<vague ou null>"]] }
```

## State of the Art

| Ancien | Actuel | Effet |
|---|---|---|
| couche « Travail récent » déclarative (`files_modified` des deux dernières phases) | empreinte observée + cartes prévues + frise de la 74 | une approximation retirée (un ajout, un retrait) |
| `amont/patches/*.diff` régénérés à chaque patch du moteur | fork assumé, `VENDORED.txt` réduit (79-01) | patchs du moteur sans diff (O-4) |
| `if` successifs dans `route()` | table des routes + réponse gardée (79-05) | une ligne pour `/api/vf/activite` |

## Assumptions Log

| # | Claim | Section | Risque |
|---|---|---|---|
| A1 | liste de bruit du couplage | P1 | paires parasites ou manquées (mesurable ici) |
| A2 | paliers à partir de 12 fichiers à score non nul | Piège 3 | paliers trompeurs sur petit lab |
| A3 | forme d'un commit vide dans la sortie `-z` | Code Examples | refus à tort → « indisponible » |
| A4 | l'annotateur (79-05) reçoit `project` et la sortie | P4 | plan 75-05 à réécrire |
| A5 | accesseurs en processus de la frise et du graphe Projet (manques 8, 9) | O-2 | repli côté page, preuve plus faible |
| A6 | `VENDORED.txt` post-79 sans lignes `RETRAIT` | O-4 | forme du traçage du retrait |
| A7 | cible A22 relative à la racine du worktree ; lab sous-dossier non traité | P2 | décalage de préfixe sur un lab non racine |

## Open Questions

1. **D-11 face au pied réservé (O-1)** — recommandé : « identique » = données ; à acter par le manager.
2. **Manques 8 et 9** — à relayer à la 79 par la session principale avant les plans 75-03 / 75-04.
3. **Lab sous-dossier du dépôt et A22** — demander si `cible` est relative au worktree ou au lab dans le worktree.
4. **Qui pose le canal (74 ou 75, D-05)** — à vérifier à l'exécution de 75-06 (`Floorplan.marques` déjà là ?).

## Environment Availability

| Dépendance | Requise par | Dispo | Version | Repli |
|---|---|---|---|---|
| Node | socle, suites | ✓ | v26.5.0 | — |
| git ≥ 2.15 (`--is-shallow-repository`) | P1 | ✓ | 2.50.1 local ; CI Ubuntu 26 | — |
| Chrome headless | sondes `chrome-*.mjs` | ✓ (macOS) | — | Chromium de la CI Linux, déjà employé |
| `socle-serveur.sh` (A6) | suites de route | ✗ avant 79-02 | — | aucun : plans après la 79 |

## Validation Architecture

| Propriété | Valeur |
|---|---|
| Framework | suites bash `assert_eq` + `node -e` ; sondes `chrome-*.mjs` via `chrome-cdp.mjs` ; mutants « copie du module, motif fixe » (modèle `test-cockpit-git-graphe.sh:248-266`) |
| Quick run | `bash plugin/cockpit/scripts/tests/test-cockpit-activite-<x>.sh` |
| Full suite | `bash scripts/ci-shard-suites.sh --all` puis chaque suite ; gates : rejouer les commandes du job `gates` de `ci.yml` (dont `scripts/check-version-sync.sh`) |

| Req | Témoin rouge sur `f763b556`, vert après | Suite (✚ neuve / ✎ adaptée) | Mutant qui le tue |
|---|---|---|---|
| ACTV-01 | `#btn-recent` présent, sélecteur absent ; layout identique avant/après bascule ; 0 `render` | ✚ `test-cockpit-activite-carte.sh` + `chrome-activite.mjs` ; ✎ responsive R13.3 | réservation du pied liée à la lentille active |
| ACTV-02 | aucune `.mk` ; `aria-label` sans le mot ; contraste du glyphe ≥ 3:1 (`css-jetons.mjs`) | ✚ carte | glyphe teinté `--recent` hors « en cours » |
| ACTV-03 | `Floorplan.marques` indéfini ; deux couches → seule la dernière visible, retrait rend la première | ✚ carte | `retirer` qui vide au lieu de dépiler |
| ACTV-04 | route → 404 ; HEAD inchangé → 0 `log` (espion `binaire`) ; requête pendant calcul → 200 `en-cours` ; Host / Origin / jeton → 403 ; POST → 405 ; clé interdite → 503 | ✚ `test-cockpit-activite-route.sh` (socle-serveur.sh) | cache par clé retiré ; mono-vol retiré |
| ACTV-05 | fixture : 5 001 commits → `plafondAtteint` ; commit à 91 j exclu ; renommage hérité ; merge exclu ; superficiel dans / hors fenêtre | ✚ `test-cockpit-activite-git.sh` | `--no-merges`, alias de renommage, `-n` retirés |
| ACTV-06 | paires aux bornes 4/5 communes, 29/30 %, ensembles de 30/31 fichiers, bruit | ✚ git | un mutant par seuil, options injectées (O-3) |
| ACTV-07 | 7 témoins d'équivalence + parité des six classes ; lab non VibeFlow → `non-lues` | ✚ `test-cockpit-activite-gardes.sh` | ambiguïté, motif, sous-chaîne (§ Gardes) |
| ACTV-08 | voies fixtures : en cours / modifié / lu / fini ; nom sans `id` ; `en-construction` → mot | ✚ `test-cockpit-activite-empreinte.sh` | `lectures` comptées en écritures |
| ACTV-09 | `..`, `\u2028`, hors lab, worktree, lien ; preuve N/2N | ✚ empreinte | normalisation par `RegExp` naïve |
| ACTV-10 | > 12 HEAD → plafond ; base unique `main` → aucune fausse collision ; même arbre parent/enfant exclu ; plans de même vague | ✚ git + empreinte | intersection contre `main` ; exclusion parent retirée |
| ACTV-11 | `files_modified` absent → carte `prevu` rattachée ; « ouvrir » absent ; Santé inchangée ; hors lab ignoré et compté | ✚ `test-cockpit-activite-prevues.sh` ; ✎ onglet-code C6.3 | annotateur sans `exclude` |
| ACTV-12 | grep du retrait vide ; Y/M4 sur `.gitignore` ; chemin, branche, rôle, titre hostiles ; sans git → aucune lentille git | ✎ ecrans-recent, moteur-carte, chrome-fr, securite, **chaine-xss** | `h()` retiré de la marque |

**Juges à captures (exécution)** : lisibilité des paliers dans les deux thèmes, légende, section « Change souvent avec », compte du radar sans lentille, téléphone (menu « ⋯ »). Les sondes mesurent, elles ne prouvent pas.
**Wave 0** : `socle-serveur.sh` (79-02) ; fixtures git générées par script dans chaque suite (aucun binaire versionné).

## Security Domain

| ASVS | S'applique | Contrôle |
|---|---|---|
| V4 Accès | oui | C0 par la réponse gardée A11 (Host, Origin, `x-vf-cockpit-token`, 405, `no-store`) |
| V5 Entrées | oui | `files_modified`, motifs des suites, sorties git : parseurs alignés, glob linéaire, bornes |
| V7 Erreurs | oui | « indisponible » sans détail ; ni argument ni sortie d'outil (P69-D-16, D-19) |
| V12 Fichiers | oui | lecture confinée (A12), `lstat`, `verifierSortie` avant écriture |
| V14 Config | oui | `envGit` / AUDC-A-04, aucun réseau |

| Menace | STRIDE | Parade |
|---|---|---|
| XSS par chemin, branche, rôle, titre | Tampering | `h()` / `textContent`, chaîne XSS étendue |
| ReDoS par motif de suite ou chemin | DoS | glob linéaire + preuve N/2N |
| clé interdite injectée par un nom de fichier | DoS (503) | tuples, aucune clé dynamique |
| programme du dépôt lancé par git | Elevation | `lancerGitAsync` (filtres vidés, hooks inertes) |
| fuite par l'export | Info disclosure | marques hors `graph.json`, prévues retirées de l'export, témoin A25 |

## Découpage conseillé (plans, vagues, `files_modified`)

Toute la phase s'exécute **après la 79** (dépendance de jalon) ; chaque plan écrit une suite ou touche le moteur, donc **aucun ne précède la vague 1 de la 79** (C6, A7). Préfixes : S = `plugin/cockpit/scripts/`, T = S`tests/`, M = `plugin/cockpit/skills/cockpit-moteur/`.

| Plan | Vague | `files_modified` | Note |
|---|---|---|---|
| 75-01 Calcul git | 1 | S`vf-cockpit-activite-git.mjs`, S`vf-cockpit-activite-branches.mjs`, S`vf-cockpit-git.mjs` (export de `monoVol`), T`test-cockpit-activite-git.sh` | écrit une suite |
| 75-02 Gardes | 1 | S`vf-cockpit-activite-gardes.mjs`, T`test-cockpit-activite-gardes.sh` | écrit une suite |
| 75-03 Chemins, empreinte, collisions | 1 | S`vf-cockpit-activite-chemins.mjs`, S`vf-cockpit-activite-empreinte.mjs`, T`test-cockpit-activite-empreinte.sh` | **à revalider** (O-2 : forme des voies de l'accesseur) |
| 75-04 Route et schéma | 2 | S`vf-cockpit-activite.mjs`, S`vf-cockpit-server.mjs` (1 ligne), S`vf-cockpit-interface.json`, S`vf-cockpit-project.mjs` (champ `vague`), T`test-cockpit-activite-route.sh` | après 79-05 ; **à revalider** (manques 8, 9) |
| 75-05 Cartes prévues | 2 | S`vf-cockpit-activite-prevues.mjs`, S`vf-cockpit-build.mjs` (1 ligne d'annotateur), M`scripts/build.mjs`, M`scripts/lib/common.mjs`, T`test-cockpit-activite-prevues.sh` | moteur ; **à revalider** (A4) |
| 75-06 Canal et page | 3 | M`assets/viewer.html`, M`assets/ui/74-vf-activite.js`, M`assets/ui/00-vibeflow.js`, M`assets/serve.mjs` (prévues hors export), T`test-cockpit-activite-carte.sh`, T`chrome-activite.mjs` | après la vague 3 de la 79 et la 74 (D-05) |
| 75-07 Retrait | 4 | S`vf-cockpit-build.mjs`, M`assets/ui/25-recent.js` (suppr.), M`scripts/recent.mjs` (suppr.), M`assets/viewer.html`, M`scripts/build.mjs`, M`assets/graph-query.js`, M`assets/ui/60-export.js`, M`assets/ui/78-vf-fr-dict-a.js`, M`assets/ui/80-vf-fr.js`, M`assets/ui/01-vf-responsive.js`, M`assets/ui/02-vf-telephone.js`, M`VENDORED.txt`, T`test-cockpit-ecrans-recent.sh` (+ fixture), T`test-cockpit-onglet-code.sh`, T`test-cockpit-moteur-carte.sh`, T`chrome-moteur-carte.mjs`, T`test-cockpit-responsive.sh`, T`test-cockpit-chrome-fr.sh`, T`test-cockpit-securite.sh` | même lot que 75-06 (D-20), jamais avant |
| 75-08 Non-régression et docs | 4 | T`test-cockpit-chaine-xss.sh`, `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md`, `DESIGN.md`, `README.md` + `README.fr.md` (compteur « N suites » : +6) | seul plan qui touche le compteur ; relecture SOBR-04 au rapport |

**Fichiers partagés et ordre anti-conflit.** Aucun fichier dans deux plans d'une même vague (`vf-cockpit-build.mjs` : 05 en vague 2, 07 en vague 4 ; `viewer.html` : 06 puis 07). Avec d'autres phases : `viewer.html` (79 vague 3, 74, 80) ; dictionnaires
`ui/78-vf-fr-dict-a.js`, `ui/80-vf-fr.js` (79, 80 ; `ui/79-vf-fr-dict-b.js` non touché par la 75 : aucune chaîne « récent ») ; table des routes de `vf-cockpit-server.mjs` (76, 77 : insertion alphabétique, A10) ; `vf-cockpit-interface.json` (73, 74, 77,
79 : bloc neuf, aucun bloc existant modifié) ; `vf-cockpit-project.mjs` (80 ajoute des champs de phase, A5) ; `VENDORED.txt` (79-01) ; `DESIGN.md` (74, 80) ; CHANGELOG du module (toutes : section « Non publié », entrées regroupées en 75-08) ; compteur des README racine (toute phase qui ajoute une suite : touché par 75-08 seul ; les vagues 1-3 laissent `check-version-sync.sh` rouge en local, attendu, rejoué à la porte de phase ; à la jointure, **recompter par la commande du gate**, jamais fusionner des chiffres). Ordre du jalon : 79 → 74 → 75 → 80 sur les fichiers communs.

## Sources

**Primary (HIGH)** : code lu dans le worktree (`f763b556`), fichiers et lignes cités en place ; `79-CONTEXT.md` `6f66d878` (C0-C6, A1-A28) ; code-maat, README (table des options) et `src/code_maat/analysis/logical_coupling.clj`,
`coupling_algos.clj` (github.com/adamtornhill/code-maat), lus le 2026-11-11.
**Secondary (MEDIUM)** : mesures du panel (`p-*.sh`, `p-stats*.py`, `mesure-gardes.mjs` du scratchpad de mission) et mesures locales de cette recherche (log 90 j, clone superficiel, `ci.yml`).

## Metadata

**Confidence :** stack HIGH (aucune dépendance) ; architecture MEDIUM (accroches de la 79 non livrées : O-2, A4) ; pièges HIGH (mesurés ou lus). **Research date :** 2026-11-11. **Valid until :** livraison de la 79 (revalider O-2, O-4, A4, A7).
