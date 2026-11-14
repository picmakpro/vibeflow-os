# Mission — Phase 73 « Gouvernance au cockpit » : exécution (2026-11-13 → 2026-11-14)

`vf-dev-manager`, mode autonome, régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par
la session principale). Base `faed809d` ; branche `feat/phase-73-gouvernance-regie` ; verrou `--ws=fiabilite --phase=73`.

## Livré (plan, sha)

- 73-01 `c4053a32` socle de `test-cockpit-regie.sh`, module de gouvernance (renommé `vf-cockpit-regie-donnees.mjs`, P4.8).
- 73-02 `5a62de79` route `GET /api/vf/ailleurs` ; 73-03 `388c2856` champs facultatifs de `who@2` ; 73-04 `15e2cbc6` modèle
  et feuille (`GLYPHE_ETAT`). PR #243 fusionnée.
- 73-05 `d380c6a0` page de la régie, accroches de la 74 ; 73-06 `26402979` titre « (N) vous attendent », « lu » ;
  73-07 `85ef2fbf` pied ; 73-08 `74683850` retrait du canevas d'Équipe ; 73-09 `ad26adbb` témoins re-pointés ;
  73-10 `313a7f0f` tiroir, CHANGELOG ; 73-11 `dfba4bd4` questions des cadrages (contrat C76-Q2). PR #248 (lot #249).
- Correctifs : audit 73-02/03/04 (4 constats, dont T-73-16 moyen) ; revue 1 (2 majeurs : gouvernance perdue à la relance du
  fil, route `ailleurs` nulle après 60 s) ; revue 2 (ancre à froid, focus de « Tout marquer ») ; liens morts de la régie ;
  missions du h1 (H6.2) ; six écarts majeurs du juge design (74/100, passed) ; règles mortes de `70-vf-live.js`.

## Écarts notables

- `vf-cockpit-live.mjs` n'était plus que le pilote de la collecte (79-09) : la gouvernance est lue dans le fil.
- Le mot « gouvernance » (nom d'un compartiment du dépôt) a dû sortir des sources du socle : modules renommés.
- La correction D3.8 d'`equipe-etats` est entrée dans le commit de fusion `b1993e8b` (mise en index pendant la fusion).
- RG1.12 (`VF_ONGLETS.aller`, 80-10) joué sur le repli ; reprise à l'arrivée de 80-10.

## Rouges de CI rencontrés et leur cause

- P4.8 (projet-graphe) : nom de compartiment dans les sources (à nous). C3.5 (coquille) : Équipe sans canevas (à nous,
  corrigé par la 79 sur le lot). SU1-SU7 (surcouches), CC5.1 (clavier-canevas), magasin C2/O1 : sondes qui attendaient
  les cartes d'Équipe (à nous, re-pointées). Magasin S2-S5 : `rtk` en dur (79, `3cc622df` cueilli). M-AILLEURS-FLUX :
  route extraite par la 75. W24.4 (who) : bruit sous la milliseconde, plancher de 20 ms (décision déléguée par Samuel,
  message session principale, 2026-11-08, prise par la session principale le 2026-11-14). V4 (vendor) : `chrome-coin.mjs`
  à 300 lignes dans la base (jointure). Intermittents : EK8, KC2, RG13.13, RG6.20.

## Mineurs versés au BACKLOG

Revue 1 (5), audit de la régie (5), revue 2 (2), juge design (6), durée des terminés (constat de la 74).

## Ce qu'une autre phase doit savoir

- 74 : `vf-agent:ouvrir`/`lu`, `__vfEquipeVues`, `__vfRegie`, `vf-regie:aller`, `cockpit-equipe@1` sans cartes, lien
  « N à relire dans Équipe », P73-C2 (la 74 retire `ouvrirRepli`). 76 : C76-Q2, texte d'attente « pas encore livrée ».
  80 : le compositeur du titre recompose sur `vf:onglet`. 79 : prêt d'Équipe = `body.vf-regie-montee`.
- Vérification de but : `human_needed` (23/24) — CI Linux, sonde réelle de `claude agents --json` (recette).

## Preuves E6

```json
{"preuves":[
 {"verdict":"gate:check-version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"7aa3e5f2feb5094e58d01d90200cd91d434179dd"},
 {"verdict":"gate:check-machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"7aa3e5f2feb5094e58d01d90200cd91d434179dd"},
 {"verdict":"gate:check-gate-touche","commande":"bash scripts/check-gate-touche.sh --base-ref origin/integration/cockpit-audit","exit_code":0,"sha":"7aa3e5f2feb5094e58d01d90200cd91d434179dd"},
 {"verdict":"gate:check-mission-invariants","commande":"bash plugin/conductor/scripts/check-mission-invariants.sh","exit_code":3,"sha":"faed809d83ed54114482da69875eea099155eba6"},
 {"verdict":"suite:test-cockpit-vendor","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh","exit_code":0,"sha":"7aa3e5f2feb5094e58d01d90200cd91d434179dd"},
 {"verdict":"ci:pr-248","commande":"gh pr checks 248 (run 43547039063)","exit_code":1,"sha":"7aa3e5f2feb5094e58d01d90200cd91d434179dd"}
]}
```

Lecture : le seul rouge du run 43547039063 est C3.5 (coquille), corrigé sur le lot #249 par la Phase 79.
