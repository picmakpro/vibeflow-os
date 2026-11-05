# Phase 78: Git dans le cockpit - Context

**Gathered:** 2026-11-05
**Status:** Cadrée (2026-11-05) — frontière de questions vide

Cadrage par le manager de la mission Phase 78 (`vf-dev-manager`, worktree `.claude/worktrees/phase-78`, branche
`feat/phase-78-git-cockpit`, base `aff9f260`). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Exécutée en parallèle des
Phases 72, 71.5 et de la PR de clôture de la 71. Sources : demande de Samuel recopiée au bloc Phase 78 du ROADMAP ;
`71-SECURITY.md` (modèle de menace des routes qui agissent sur le poste) ; `DESIGN.md` direction « Graphite » ;
`.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idée 13, Phase 73, branche `docs/jalon-v2-phases-73-77`).

**Exigences :** GITC-01 à GITC-12. Préfixe neuf, vérifié libre le 2026-11-05 sur `origin/main`,
`feat/phase-72-lancer-depuis-cartes` et `docs/jalon-v2-phases-73-77`.

<domain>
## Phase Boundary

L'en-tête du cockpit montre, sur les trois onglets, le nom du dossier du dépôt principal, avec la branche et le worktree
courants en petit sur une seconde ligne. Le bloc de vue dit ce que montre la vue au lieu de répéter le nom du projet. Un
tiroir vertical à gauche montre un graphe façon « gitgraph » des branches locales, des worktrees et des branches distantes
déjà connues, avec le détail d'un commit (sans diff), l'état de chaque worktree, les tags, les stash, les auteurs et
l'activité. Tout est en lecture seule : chaque action propose la commande exacte à copier, que l'utilisateur lance lui-même.

**Hors périmètre :** la revue de diff complète ; toute route qui agit sur le dépôt ; tout `fetch` ou lecture réseau ; les
verrous de driver, arbitrages en attente, watchdog et serveurs orphelins (Phase 73) ; hotspots et couplage de changement
(Phase 75) ; les jetons d'espacement, les paddings et la palette (Phase 71.5) ; un 4ᵉ onglet.
</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-05, relayés mot pour mot au manager)

- **P78-D-01 (A1, nom de l'en-tête).** « Dossier du dépôt principal (Recommandé) ». Le titre à droite du logo est le nom
  du dossier du dépôt principal (racine de `git rev-parse --git-common-dir`, et à défaut le dossier du lab), identique sur
  Code, Projet et Équipe. Dans un worktree, c'est « vibeflow-os », pas « phase-78 ».
- **P78-D-02 (A2, branche et worktree).** « Seconde ligne ». La branche et le worktree vont en petit sous le nom (pas de
  pastille). Le worktree n'apparaît que hors de l'arbre principal ; branche détachée lisible comme telle.
- **P78-D-03 (A3, bloc de vue).** « Dire ce que montre la vue (Recommandé) ». À la racine, le bloc ne répète plus le nom du
  projet : surtitre = nom de l'onglet ; titre = ce que montre la vue (Projet : le jalon en cours ; Code : le dépôt et sa
  branche ; Équipe : la mission en cours, ou un libellé neutre s'il n'y en a pas) ; sous-titre = résumé court. Sous-vues
  inchangées.
- **P78-D-04 (B1, emplacement).** Réponse libre, mot pour mot : « un panneau/tiroire vertical a gauche vertical (je trouve
  que trois onglet sont suffisant et git peut ne pas etre installé dans le projet) ». Pas de 4ᵉ onglet : un tiroir vertical
  à gauche, qui coexiste avec le tiroir Terminal (en bas) et les boutons de zoom et la pastille Terminal (en bas à gauche).
  Git absent ou lab hors dépôt : dégradation propre, sans casser le reste.
- **P78-D-05 (B2, portée).** « Locales, worktrees et distantes connues (Recommandé) ». Branches locales, worktrees,
  branches distantes déjà présentes sur le disque (`refs/remotes/*`) ; jamais de `fetch` (CKPT-03) ; N derniers commits
  bornés, branches mergées repliées.
- **P78-D-06 (C1, données).** Trois choix cochés : « Commit, état des worktrees, tags (Recommandé) », « Les stash »,
  « Auteurs et activité ». Détail d'un commit (auteur, date, message complet, fichiers touchés avec +/−, sans diff) ; état
  de chaque worktree (modifiés, non suivis, avance/retard sur la base) ; tags ; liste des stash ; auteurs et activité
  récente par branche.
- **P78-D-07 (D1, actions).** « Lecture seule + commande à copier (Recommandé) ». Aucune route qui agit sur le dépôt. Les
  vues proposent la commande exacte, à copier ; l'utilisateur la lance lui-même (terminal intégré ou autre). Audit de
  sécurité en lecture, recommandé et retenu.
- **P78-D-08 (E1, coexistence).** « La 78 prend l'affichage Git (Recommandé) ». Worktrees, branches et travail non commité :
  Phase 78. La Phase 73 garde verrous, arbitrages en attente, watchdog et serveurs orphelins ; la Phase 75 garde hotspots et
  couplage. Le retrait de la part Git de l'idée 13 dans la section de la 73 revient à la session du jalon 73-77 : la 78 n'y
  touche pas.
- **P78-D-09 (E2, retrait SOBR).** « Liste Repositories + suffixes du titre (Recommandé) ». La liste « Repositories » de
  l'onglet Code (« branche @ head7 ») et les suffixes « — Projet » / « — Équipe » du titre sont retirés.
- **P78-D-10 (G1, ouverture du tiroir).** « Clic sur la ligne branche + touche g (Recommandé) » (arbitrage Samuel,
  AskUserQuestion session principale, 2026-11-05, second tour). La seconde ligne de l'en-tête ouvre le tiroir au clic, avec
  un aspect cliquable au survol ; la touche « g » l'ouvre et le ferme. La sous-question de dégradation (P78-D-11) figurait
  dans l'énoncé de la question et n'a pas été contestée : elle est retenue.

### Décisions du manager (techniques, sur mesures ; aucune ne vaut arbitrage humain)

- **P78-D-11 (dégradation, retenue avec P78-D-10).** Git introuvable sur le PATH assaini, ou lab hors dépôt : la seconde ligne de l'en-tête et
  l'ouvreur du tiroir sont absents, aucune erreur dans le chrome, le reste du cockpit est identique à aujourd'hui (témoin).
  Une erreur ou un dépassement de borne d'une commande git rend un état « indisponible » local au tiroir, jamais une page
  cassée.
- **P78-D-12 (coexistence 71.5).** Uniquement des variables CSS existantes, aucune valeur de couleur, d'espacement ou de
  rayon en dur ; aucune valeur de padding ou de marge existante modifiée. La 71.5 refait la palette : elle doit s'appliquer
  d'elle-même au tiroir.
- **P78-D-13 (surface serveur).** Routes neuves en GET seul sous `/api/vf/` (la Phase 72 ajoute de son côté une route POST de lancement ; la 78 n'en ajoute aucune), derrière les contrôles existants (Host,
  Origin, jeton). Aucune route POST, aucune écriture dans le dépôt ni dans `.git`. Commandes git par `shBorne` avec
  `GIT_SUR`, options de neutralisation des programmes externes (diff externe, textconv, pager) selon `78-RESEARCH.md`,
  arguments validés (SHA par motif strict puis `rev-parse --verify`, jamais d'argument commençant par `-`), sorties
  bornées en nombre et en taille.
- **P78-D-14 (commandes à copier).** Toute commande proposée est construite côté serveur ou par une fonction unique, avec
  les noms de refs et les chemins cités pour le shell (guillemets simples, `'` échappé) : un nom de branche hostile
  (`$(…)`, `;`, `` ` ``, `|`) ne doit jamais produire une commande qui fait autre chose que celle affichée. Copie par
  l'API presse-papiers de la page P seule (jamais dans le cadre du terminal, T-71). Rendu de tout texte venu de git en
  `textContent`.
- **P78-D-15 (rafraîchissement).** Le tiroir se rafraîchit par le flux existant (SSE) sur une signature bon marché (HEAD et
  refs de chaque worktree), jamais par un polling qui relance `git log` à chaque tick.
- **P78-D-16 (étage design).** UI à dominante neuve (tiroir Git, en-tête) : `craft` par `vf-crafter` avant l'exécution de
  l'UI, `critique` par `vf-design-judge` en parallèle de la revue, seuil 70/100, contre `DESIGN.md` « Graphite ».
- **P78-D-17 (preuves).** Chaque exigence porte un témoin rouge joué avant le code ; mutants sur les gardes de sûreté
  (validation du SHA, citation shell, bornes, dégradation) ; dépôt git jetable fabriqué dans la suite (branches, merge,
  worktree, tag, stash, nom de branche hostile). Recette par juges en Chrome headless (CDP) avec captures, ports
  éphémères, un Chrome par juge.
- **P78-D-18 (version).** Bump du module `cockpit` au-dessus de `main` au rebase ; pas de release dans la phase.
- **P78-D-19 (largeur mobile).** Le tiroir et la seconde ligne tiennent en largeur mobile (héritage UIFN) ; la règle de
  masquage du nom sous 1000 px s'applique aussi à la seconde ligne, sauf avis contraire du juge de design.

- **P78-D-20 (ouvreur mobile).** Sous 1000 px, la seconde ligne est masquée (P78-D-19) ; un bouton icône 44×44 dans `.hr`
  devient l'ouvreur tactile (proposé par le craft, `78-UI-SPEC.md` §5, retenu par le manager, à confirmer par le juge de
  design) ; absent sans Git comme les autres ouvreurs (P78-D-11).

- **P78-D-21 (filtres du dépôt, question ouverte 1 de `78-RESEARCH.md`).** Sûreté d'abord : aucun filtre déclaré par le
  dépôt n'est exécuté (`-c filter.<x>.<clé>=` pour chaque filtre listé) ; `git diff` contre l'arbre de travail est proscrit.
  Quand un filtre est déclaré, le compte de fichiers modifiés du worktree porte la mention « approximatif : filtres du dépôt
  non exécutés ». Choix d'affichage du manager, révisable par Samuel.
- **P78-D-22 (environnement git).** Les appels git du tiroir retirent `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`,
  `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_CONFIG*` et voisines de l'environnement hérité ; préfixe
  `GIT_LECTURE = [...GIT_SUR, '--no-ext-diff', '--no-textconv']` là où il s'applique ; `maxBuffer` explicite et parseur qui
  vérifie l'alignement (une sortie tronquée rend « indisponible », jamais un graphe faux). Le vecteur identique de
  `vf-cockpit-who.mjs:116` est consigné, hors périmètre.
- **P78-D-23 (bornes et extraction).** Trois appels : `for-each-ref` (avance/retard, repli `rev-list --count` si
  `%(ahead-behind:)` est absent de la version de git), `log` de la ligne de base `-n 500`, `log` des non mergées
  `--not <base> -n 500` ; refs entièrement qualifiées ou `--end-of-options`. Base du retard : même règle que `retard()`
  (les deux comptes quand `main` local et `origin/main` divergent). Placement des couloirs maison en JS pur, rendu SVG,
  ELK écarté. `status` par worktree à l'ouverture du tiroir seulement ; signature de rafraîchissement dans le filet de 5 s.
- **P78-D-24 (auteurs).** Agrégés en JS sur `log --format=%an%x00%at`, jamais `shortlog` sans révision.

### Claude's Discretion

Algorithme de placement des couloirs, format d'échange serveur → page, découpage en fichiers sous `plugin/cockpit/`.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/ROADMAP.md` § Phase 78 (demande mot pour mot)
- `.planning/workstreams/fiabilite/phases/VFDO-71-terminal-integre-cockpit/71-SECURITY.md`
- `.planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-RESEARCH.md`
- `DESIGN.md`
- `plugin/cockpit/scripts/vf-cockpit-arbres.mjs`, `vf-cockpit-paths.mjs` (`shBorne`, `GIT_SUR`), `vf-cockpit-server.mjs`
- `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` (`#proj-name` l. 584, `renderContext` l. 1437), `ui/00-vibeflow.js`
</canonical_refs>

<deferred>
## Deferred Ideas

- Actions Git exécutées par le cockpit (fetch, branche, worktree…) : phase ultérieure, après recette (P78-D-07).
- Revue de diff complète.
</deferred>
