# Handoff — Phase 71 (terminal intégré au cockpit), 2026-11-04

Écrit par le manager `vf-dev-manager` (`mgr71`) à la relève de contexte demandée par le coordinateur. Rapport complet de la mission :
`.planning/missions/2026-11-04-phase-71-terminal.md`. Cadrage et arbitrages : `phases/VFDO-71-terminal-integre-cockpit/71-CONTEXT.md`
(P71-D-01 à D-37) dans le compartiment `fiabilite`.

## État au moment du handoff

- **Branche** : `feat/phase-71-terminal`, worktree `.claude/worktrees/phase-71`.
- **Tête** : `cb26e059` avant ce commit de handoff (ce commit et celui de la mémoire du manager s'ajoutent par-dessus ; relire `git rev-parse
  origin/feat/phase-71-terminal`).
- **Rebase** : TERMINÉ sur `origin/main` `503aa657` (merge de la PR #200, Phase 70 ; contient 68, 69, 70, H-1 #201, #202). Aucun rebase à moitié
  fait. Rejeu local après rebase : 38 suites cockpit sur 38 à 0, `synchro.sh verifier` 0, job `gates` (replay-ci-jobs.sh) 21 rejouées, 0 échec.
- **PR** : #203, **brouillon**, `https://github.com/picmakpro/vibeflow-os/pull/203`. Corps avec section « Merge-danger call » (Porte : double sens).
- **CI** : run `41924154907` en cours sur `cb26e059` au moment de l'écriture (6 pass, 7 pending, 1 skipping). Le run `41923876542` sur `0a78edd7` a été
  annulé : son job `gates` avait rougi sur `check-machine-paths` (un `/Users/<compte>` dans `71-01-RED-TRACE.md`), corrigé en `cb26e059`.
  **Le push de ce handoff relance la CI** (la concurrence du workflow annule le run précédent de la PR) : relire `gh run list --branch
  feat/phase-71-terminal`.
- **Verrou de phase** `--ws=fiabilite --phase=71` : RELÂCHÉ par le manager en sortant (génération `DRIVER.lock.gen.1793797926.57506`). Le
  successeur reprend un verrou neuf (`acquire --ws=fiabilite --phase=71`) ; le trailer `Fence:` de ses commits portera la nouvelle génération.
- **Workers** : aucun worker de la mission vivant (registre de phase : 0 ouvert). Le worker de la 70 qui tournait `test-cockpit-responsive.sh`
  n'appartenait pas à la 71 (arrêté par le coordinateur).
- **Cockpit de test de Samuel** : port 4456, PID 21222 à l'écriture, servi depuis le worktree détaché `.claude/worktrees/phase-71-test4456` à
  `a9493e4a`, lab = arbre principal (sortie `.vibeflow/cockpit`, ignorée). À relancer sur la tête finale si Samuel reteste (`node
  plugin/cockpit/scripts/vf-cockpit.mjs open --terminal --lab <arbre principal> --port 4456 --rebuild` depuis ce worktree après `checkout --detach`).
- **Worktrees d'essai** (références, jetables) : `phase-71-essai-rebase` (`bd56e227`, base 19393cc3), `phase-71-essai2` (`89da7edd`, base 3c73fc0c),
  `phase-71-essai3` (`e4302c3c`, base a6912f25). Ils peuvent être supprimés après le merge.

## Étapes restantes, dans l'ordre

1. Attendre la CI de la PR #203 jusqu'au vert (environ 55 min). Sur un rouge : lire le journal du job (`gh api
   repos/picmakpro/vibeflow-os/actions/jobs/<id>/logs`), distinguer un flake connu d'un vrai rouge, corriger en commit ciblé avec témoin.
2. Une fois la CI verte : sortir la PR du brouillon (`gh pr ready 203`) et prévenir le coordinateur. **Ni merge ni release** (consigne de mission).
3. Si `main` bouge encore avant le merge : rebase léger (`git -c rerere.enabled=true rebase origin/main`), rejeu des suites cockpit et du job
   `gates`, `git push --force-with-lease`, nouvelle CI.
4. Après le merge (geste humain) : supprimer les worktrees d'essai et `phase-71-test4456`, et la release éventuelle suit la doctrine du
   `CLAUDE.md` (VERSION racine, tag, relecture adverse SOBR-04) — hors de cette mission.
5. Recette humaine : Samuel a donné deux retours (consignés dans `71-RECETTE-HUMAINE.md`) ; la recette a été jouée par des juges (P71-D-32).
   Rien à cocher à sa place.

## Pièges connus

- **rerere** : le cache est PARTAGÉ par tous les worktrees (`$(git rev-parse --git-common-dir)/rr-cache/`). Les résolutions des README racine
  (compteur de suites) dépendent de la base : celles des essais sur 19393cc3 et a6912f25 ont été supprimées ; à tout nouveau rebase, résoudre ces
  deux fichiers À LA MAIN (une seule ligne, historique intact) et ne jamais se fier à une résolution rerere du compteur.
- **Compteur de suites** : 165 aux README racine sur 503aa657 (`check-version-sync` ✓). Toujours recompter par la méthode du gate, jamais additionner.
- **Version du cockpit** : v1.3.0 (main v1.2.2 par la 70). Toute nouvelle phase cockpit mergée avant la 71 impose la mineure suivante et le
  ré-ordonnancement du CHANGELOG.
- **Patch amont** : le terminal est P26 dans `serve.mjs` (P25 est pris sur main) ; renuméroter ses seules lignes, régénérer le diff, `synchro.sh
  verifier`.
- **Flake KC2** (method-budget) : rouge intermittent connu de la CI ; le rejouer avant de le classer. Autres sondes sensibles à la charge, déjà
  connues : FB3.5 (`-securite`), T12.5 (`-session`), M-NOEOF (`-pty`) — rejouer seules avant de classer.
- **check-machine-paths** : vert en local, rouge en CI sur un `/Users/<compte local>` (le gate local ne voit pas le compte qui le lance). Avant chaque
  push vers la PR : `grep -rn "/Users/$(whoami)"` sur le diff.
- **rtk** : masque les commits de merge dans `git log` et peut tronquer `grep`/`ls` ; vérifier les têtes par `git rev-parse`, mesurer en `rtk proxy`.
- **Tests navigateur** : le harnais `chrome-session.mjs` tronque à 64 Ko ; borner les relevés (cause d'un aveuglement de R1.1, lot Y).

## Choix techniques du manager (non soumis à Samuel, signalés au coordinateur)

- Les rapports de souris émis pendant la fenêtre de rejeu du tampon (au plus 3 s après un rechargement, close au premier silence de 150 ms ou à
  la première frappe) sont perdus ; clavier, collage et glisser-déposer ne le sont pas.
- Le PATH d'origine n'arrive au shell que par le lanceur (`VF_COCKPIT_PATH_ORIGINE`) ; un serveur lancé hors du lanceur donne au shell le PATH
  assaini de H-1.
- `resoudreBinaire` se replie sur `/usr/bin:/bin` quand aucun élément absolu ne reste ; `gitCommonDir` suit le PATH assaini de H-1.

## Goût résiduel (non bloquant, pour Samuel)

- En 1280×720, tiroir ouvert à sa hauteur par défaut (36 % de la fenêtre), le texte des cartes reste petit (échelle 0,29).
- La barre du tiroir dit « Terminé » face à la carte « Python 3 introuvable ».
- Variante de R4 (serveur vivant avec terminal, `python3` disparu) : le message « s'ouvre sans terminal » est approximatif, le comportement est juste.

## Hors phase

- **H1-b, hérité de `main`** (PR #201, H-1) : `sous()` de `plugin/cockpit/scripts/vf-cockpit-env.mjs` traite `<lab>/..bin` comme extérieur au lab
  (`path.relative` rend `..bin`), donc `assainirPath` le garde. Correctif proposé : `r === '..' || r.startsWith('..' + path.sep)`. À traiter dans le
  mandat H-1 sur `main`, pas dans la 71.
- **Non joué** (consigné, P71-D-32) : le raccourci Ctrl+Maj+Espace dans Safari.app et Firefox.app réels, et un vrai clavier AZERTY avec Option.
