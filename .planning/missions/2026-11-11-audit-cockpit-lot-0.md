# Mission — lot 0 de l'audit du cockpit, « dire vrai » (2026-11-11)

> Mission hors phase du compartiment `fiabilite`, pilotée par vf-dev-manager. Contrat :
> `.planning/research/2026-11-10-audit-cockpit/LOT-0-MANDAT.md` (28 lignes) ; preuve des lignes : `REGISTRE.md` du même
> dossier. Base : `release/v2.77.0` à 437e8edd. Branche de mission : `fix/audit-cockpit-lot-0`. Sortie : une PR vers
> `release/v2.77.0`, non fusionnée. Autorisation : lecture par la session principale de la phrase de Samuel du
> 2026-11-10 comme validation ADR-031 du lot (choix AUDC-V11), intention confirmée par Samuel le 2026-11-11.

## Résultat

- **29 lignes traitées** : les 28 du mandat et une ligne ajoutée en cours de mission, AUDC-A-04.
- **Part « lot 0 » livrée pour 28 lignes**, **en partie pour 1** (AUDC-A-02, la classe restante part en Phase 79, première vague). Au REGISTRE, 17 lignes sont `fait` et 12 `fait en partie` : onze parce que leur reste appartient, par construction du mandat, à une phase ultérieure, plus AUDC-A-02.
- Aucune ligne sortie pour rencontre avec un arbitrage passé. Une rencontre possible (Q12 et le tiroir du terminal,
  AUDC-M11) a été remontée ; la session principale l'a levée en relisant Q12 dans son texte d'origine.
- Toutes les suites du cockpit vertes (79/79) et le job `gates` vert sur la tête intégrée ; recette par juge à
  captures faite.

## Plan de bataille (DAG)

1. Huit workers d'exécution en parallèle, un worktree chacun depuis 437e8edd, fichiers exclusifs déclarés et
   fichiers partagés nommés : A1 (D1 D2 D3 D4 M3), A2 (D5 D6 D7 D8), B1 (H2 H3 AM7), B2 (H1 M9 H4), Ca (A-02 B-01
   B-04), Cb (A-01 B-02 B-03 B-06), Da (M10 M11), Db (M7 X4 X6 X7).
2. Revue par sous-lot (vf-reviewer, en direct) et audit sécurité du sous-lot C (vf-auditer) ; corrections ciblées
   renvoyées au worker d'origine (reprise par message, contexte intact) ; chaque passe de correction revue par un juge
   frais.
3. Jointure par fusion sans rebase (les SHA des commits de ligne restent ceux du registre), patchs vendorisés
   régénérés, non-régression complète.
4. Recette par juge à captures (Playwright, un seul pilote), revue de jointure, re-revue et re-audit des derniers
   tours, corrections finales (journal du lanceur, règle git, A-04, recette), non-régression complète finale.
5. Hygiène documentaire (CHANGELOG « Non publié », REGISTRE, BACKLOG), rapport, PR.

Étage design croisé non posé : corrections d'écrans existants, ni nouvel écran ni refonte.

## Lignes

Voir le REGISTRE pour l'état ligne par ligne (`fait (2026-11-11, <sha>)`). Commits de ligne et de correction :

| Ligne | Commit de ligne | Corrections |
|---|---|---|
| D1 | 367d8c44 | — |
| D2 | 124e23a4 | 9134af16, 629ce61a, 6e0c6b49, e69e0858, 476f7158 |
| D3 | c280ee0c | 2e8e22e1, 629ce61a |
| D4 | 84de1f2b | — |
| D5 | d8b497b0 | — |
| D6 | 98c3064d | — |
| D7 | 0461c7ed | e560a0d3 |
| D8 | 659872bf | 6ae7f468, e560a0d3, 19ed67ca |
| M3 | 44263d7c | — |
| H1 | 0ca826cd | 31d118ff |
| H2 | 966c42be | — |
| H3 | 46f0c8a2 | e984fa6c, aead650c, 466fc1c8, 6963027e, f993b8b2 |
| H4 | 69588f12 | 2b673f8e, 3b2b91e9, a9e9bd13 |
| M9 | 6f451052 | ebd98a13 |
| AM7 | b2963105 | 74115473, aead650c, e99950d9 |
| A-01 | 39e8fd7a | — |
| A-02 (en partie) | 0332bac0 | ae726c7c, ebde61f4, fc233d36, 731ac3af, 7f3eda02, 28d434e1, f6adace0, 92a3d8fa, c6193bc4, dd3f1792, 268d1cca, 9928c35d, 84db769d |
| A-04 (ajout) | ccbc81e9 (commit isolé, fusion 864f8b89) | — |
| B-01 | 109240a6 | c25e4eb4 |
| B-02 | ea97328a | 4d915154, 4aee2979, a33d3fce, 69747ff4 |
| B-03 | 993d28a4 | — |
| B-04 | a589b43a | — |
| B-06 | 9d662c87 | dd73091e, 81d36966, 7911cfd1 |
| M7 | 1efeb147 | c77027fb |
| M10 | a5b075e2 | bea01a06, b5a65263, e025fbac, b27f3e94 |
| M11 | 64aafe3e | 2a0fefbf, 95eb0b9e |
| X4 | 5dd52f92 | 4f98824a |
| X6 | ae806fdc | 4f98824a |
| X7 | 90b76f03 | 6e9eafaf, 359d7bcd, 5e8a4c76 |

Commits de jointure et d'intégration : e99950d9, 33004b97, 00ffe304, 15a90e09, cc2224fc, 7bac64bb, 5e8a4c76 ; fusions
3322e69c (Cb), 81200231 (B1), 7b5ad41d (B2), 89eaa16f (A1), 98a3cb93 (A2), 45f59234 (Da), ca1298e8 (Db),
3bf1d4f1 (Ca), 22abf4db et f7cd8c92 (recette), 864f8b89 (A-04).

## Lignes non livrées en entier, avec leur cause

- **AUDC-A-02 — fait en partie.** Fermé : les liens du lab vers l'extérieur ne sont plus suivis à l'assemblage ni à
  l'export ; lecteurs confinés ; en-tête et routes git ; un dépôt n'est lu que si ses dossiers git et commun réels
  sont dans le lab ou désignent le lab en retour ; aucun lien sortant sous ces dossiers ; ni dépôt alternatif, ni
  arbre de travail étranger ; inclusions de configuration confinées. Reste ouvert, au niveau de la classe : certains
  chemins sont jugés sur leur forme lexicale alors que git les résout physiquement, et un maillon interne au dossier
  git suffit à faire diverger les deux. Pourquoi la règle simple ne suffit pas : elle refuse les liens qui SORTENT du
  dossier, pas ceux dont la résolution physique sort après un rebond interne. Cinq tours sur la même famille ; le
  dernier passage était annoncé comme tel. Suite : Phase 79, première vague (la session principale le dit à Samuel).
- Parts hors lot, par construction du mandat (pas des manques) : D4 (régie, Phase 73), D5 (registre et nœud, Phase 79),
  D8 (lecteur, Phase 74), H1 (flux partagé, Phase 79), H2 (asynchrone, Phase 79), H4 (traduction à l'émission,
  Phase 79), M3 (régie, Phase 73), M7 (worker de mise en page, Phase 79), M10 (pastille sans `--terminal`, Phase 80),
  X7 (onglets sans rechargement, Phase 80), AM7 (socle de test, Phase 79).

## Décisions

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sauf mention.

- Workers sans gsd-quick : ses exécutants repartent de l'arbre principal (incident du 2026-11-08) ; vérification
  portée par la preuve rouge→vert par ligne et par des juges indépendants.
- D2 : « vous attend » et « close » viennent seulement de l'état officiel (enrichissement optionnel, AUDC-V8) ; une
  session absente d'une liste officielle lue avec succès est close (couverture des sessions vivantes établie sur le
  poste) ; une liste dont une entrée est illisible est illisible en entier ; un état vivant n'est jamais écrasé.
- D8 : le schéma du transcript passe à `cockpit-transcript@2` (politique de version du README).
- M3 : santé retirée de l'onglet Équipe ; titre « N agents actifs » seulement sans mission.
- M7 : indicateur immédiat seulement sur une navigation, jamais sur un redessin en direct.
- M9 : coupure sans fermeture de connexion hors ligne (Phase 79) ; libellé masqué entre 701 et 1639 px = P70-D-22,
  le point porte la coupure.
- M11 : rehaussement du tiroir du terminal à min(480 px, 60 % de la fenêtre) ; Q12 relue dans son texte d'origine,
  elle ne vise que les tiroirs latéraux (décision de la session principale, pas de Samuel) ; les deux propriétés de
  PU-G-136 prouvées.
- X6 : zéro mouvement, repères utiles gardés en forme statique.
- X7 : format « <Onglet> · <nom> », nom tiré de l'en-tête.
- H3 : une relance dont le code a changé remplace le serveur ; le port n'est pas comparé.
- A-02 : un lien dont la cible reste dans le dossier git est permis (verrou de pilotage du dépôt).
- AUDC-A-04 : ajoutée à la PR en commit isolé — décision de la session principale par délégation (« décision
  déléguée par Samuel (message session principale, 2026-11-08), option recommandée »), signalée par elle à Samuel.

## Incidents

- Un juge a créé un instant un dossier `poc/` dans l'arbre principal (commande relative), supprimé aussitôt.
- Un worker a lancé un `pkill -f` sur des noms de suites ; des suites d'autres workers ont pu être interrompues
  (rejouées seules ensuite). Les mandats suivants l'interdisaient nommément.
- L'auditeur a écrit en mémoire versionnée des recettes de contournement ; réécrites au niveau de la classe par le
  manager à la demande de la session principale (l'auditeur n'a pas d'outil d'écriture), non indexées.
- Le registre d'agents a reçu au premier dispatch huit entrées mal formées, fermées puis réenregistrées.
- Une suite neuve verte en local et rouge en CI faute de `claude` sur le runner (terminal-fin) : corrigée dans le test.
- Régressions nées de la mission et fermées dans la mission : écriture du journal du lanceur à travers un lien
  (bloquant, AUDC-H3), arrêt sur inactivité dès la fermeture d'une page (croisement de deux sous-lots), traduction du
  repli du panneau d'un lien, titres d'onglet jugés par deux suites contre l'ancien nom.

## Limites (au BACKLOG ou au registre)

Coupure sans fermeture du flux ; métadonnées de dépôts imbriqués à l'export (clé amont) ; affichage d'un 429 et
session non purgée côté page ; `stop`/`status` et serveur orphelin ; lien vers une cible interne protégée du lab ;
empreinte de relance limitée à `serve.mjs` ; formes singulières du repli de lien sans gabarit (lacune préexistante) ;
A-04 : pilotes nommés fermés par liste de sous-commandes de lecture, un script shell du socle lance git hors du point
unique, version de git de la CI non mesurée (une protection redondante ferme le réseau si git < 2.44) ; un sixième
onglet ne charge plus (H1, Phase 79) ; tiroir du terminal qui reste rehaussé après « Annuler » (goût, pour Samuel).

## Fichiers par sous-lot

Liste exhaustive par branche de travail (diff depuis sa base), chemins relatifs à `plugin/cockpit/` quand ils y sont :

- **A1 (437e8edd..fix/audit-cockpit-lot-0-a1)** (16) : `scripts/tests/test-cockpit-equipe-etats.sh`, `scripts/tests/test-cockpit-equipe.sh`, `scripts/vf-cockpit-equipe-carte.mjs`, `scripts/vf-cockpit-equipe-etat.mjs`, `scripts/vf-cockpit-equipe.mjs`, `scripts/vf-cockpit-etat-officiel.mjs`, `scripts/vf-cockpit-interface.json`, `scripts/vf-cockpit-live.mjs`, `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit-who.mjs`, `signal/hooks/views/equipe.tsx`, `skills/cockpit-moteur/assets/ui/00-vibeflow.js`, `skills/cockpit-moteur/assets/ui/70-vf-live.js`, `skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js`, `skills/cockpit-moteur/assets/ui/72-vf-equipe.js`, `skills/cockpit-moteur/assets/ui/76-vf-git-entete.js`
- **A2 (437e8edd..fix/audit-cockpit-lot-0-a2)** (12) : `README.md`, `scripts/tests/test-cockpit-equipe.sh`, `scripts/tests/test-cockpit-lecture-fil.sh`, `scripts/tests/test-cockpit-signal.sh`, `scripts/tests/test-cockpit-transcript.sh`, `scripts/vf-cockpit-interface.json`, `scripts/vf-cockpit-lecture.mjs`, `scripts/vf-cockpit-planning.mjs`, `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit-transcript.mjs`, `scripts/vf-cockpit-who.mjs`, `skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js`
- **B1 (437e8edd..fix/audit-cockpit-lot-0-b1)** (19) : `amont/patches/assets__serve.mjs.diff`, `scripts/tests/chrome-saut.sh`, `scripts/tests/hygiene.sh`, `scripts/tests/test-cockpit-chrome-fr.sh`, `scripts/tests/test-cockpit-cycle-serveur.sh`, `scripts/tests/test-cockpit-moteur-carte.sh`, `scripts/tests/test-cockpit-projet-visite.sh`, `scripts/tests/test-cockpit-reconnexion.sh`, `scripts/tests/test-cockpit-responsive.sh`, `scripts/tests/test-cockpit-visite-retours.sh`, `scripts/vf-cockpit-drift.mjs`, `scripts/vf-cockpit-lanceur-verrou.mjs`, `scripts/vf-cockpit-live.mjs`, `scripts/vf-cockpit-project.mjs`, `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit-who.mjs`, `scripts/vf-cockpit.mjs`, `skills/cockpit-moteur/VENDORED.txt`, `skills/cockpit-moteur/assets/serve.mjs`
- **B2 (437e8edd..fix/audit-cockpit-lot-0-b2)** (14) : `amont/patches/assets__serve.mjs.diff`, `amont/patches/assets__viewer.html.diff`, `scripts/tests/chrome-direct-coupe.mjs`, `scripts/tests/chrome-flux-unique.mjs`, `scripts/tests/chrome-fr-donnees.mjs`, `scripts/tests/test-cockpit-direct-coupe.sh`, `scripts/tests/test-cockpit-flux-unique.sh`, `scripts/tests/test-cockpit-fr-donnees.sh`, `scripts/tests/test-cockpit-reconnexion.sh`, `scripts/vf-cockpit-server.mjs`, `skills/cockpit-moteur/assets/serve.mjs`, `skills/cockpit-moteur/assets/ui/70-vf-live.js`, `skills/cockpit-moteur/assets/ui/80-vf-fr.js`, `skills/cockpit-moteur/assets/viewer.html`
- **Ca (437e8edd..fix/audit-cockpit-lot-0-ca)** (20) : `amont/patches/assets__serve.mjs.diff`, `amont/patches/scripts__lib__common.mjs.diff`, `amont/patches/scripts__scan.mjs.diff`, `scripts/tests/test-cockpit-avancement.sh`, `scripts/tests/test-cockpit-confinement.sh`, `scripts/vf-cockpit-arbres.mjs`, `scripts/vf-cockpit-build.mjs`, `scripts/vf-cockpit-code.mjs`, `scripts/vf-cockpit-git-entete.mjs`, `scripts/vf-cockpit-git-sortant.mjs`, `scripts/vf-cockpit-git.mjs`, `scripts/vf-cockpit-lancer.mjs`, `scripts/vf-cockpit-paths.mjs`, `scripts/vf-cockpit-planning.mjs`, `scripts/vf-cockpit-project.mjs`, `scripts/vf-cockpit-who.mjs`, `skills/cockpit-moteur/VENDORED.txt`, `skills/cockpit-moteur/assets/serve.mjs`, `skills/cockpit-moteur/scripts/lib/common.mjs`, `skills/cockpit-moteur/scripts/scan.mjs`
- **Cb (437e8edd..fix/audit-cockpit-lot-0-cb)** (12) : `amont/patches/assets__serve.mjs.diff`, `scripts/tests/test-cockpit-demander-bornes.sh`, `scripts/tests/test-cockpit-git-commandes.sh`, `scripts/tests/test-cockpit-securite.sh`, `scripts/vf-cockpit-build.mjs`, `scripts/vf-cockpit-drift.mjs`, `scripts/vf-cockpit-git-commandes.mjs`, `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit-terminal-env.mjs`, `scripts/vf-cockpit.mjs`, `skills/cockpit-moteur/VENDORED.txt`, `skills/cockpit-moteur/assets/serve.mjs`
- **Da (437e8edd..fix/audit-cockpit-lot-0-da)** (15) : `scripts/tests/chrome-fin.mjs`, `scripts/tests/test-cockpit-lancer-bandeau.sh`, `scripts/tests/test-cockpit-terminal-client.sh`, `scripts/tests/test-cockpit-terminal-fin.sh`, `scripts/tests/test-cockpit-terminal-tiroir.sh`, `scripts/vf-cockpit-lancer-post.mjs`, `scripts/vf-cockpit-lancer-ui.mjs`, `scripts/vf-cockpit-lancer.mjs`, `scripts/vf-cockpit-terminal-client.mjs`, `scripts/vf-cockpit-terminal-processus.mjs`, `scripts/vf-cockpit-terminal-session.mjs`, `scripts/vf-cockpit-terminal-tiroir-style.mjs`, `scripts/vf-cockpit-terminal-tiroir-ui.mjs`, `scripts/vf-cockpit-terminal-tiroir.mjs`, `scripts/vf-cockpit-terminal-vue.mjs`
- **Db (437e8edd..fix/audit-cockpit-lot-0-db)** (9) : `amont/patches/assets__viewer.html.diff`, `scripts/tests/chrome-accessibilite.mjs`, `scripts/tests/test-cockpit-accessibilite.sh`, `scripts/tests/test-cockpit-git-entete.sh`, `scripts/tests/test-cockpit-responsive.sh`, `skills/cockpit-moteur/VENDORED.txt`, `skills/cockpit-moteur/assets/ui/00-vibeflow.js`, `skills/cockpit-moteur/assets/ui/03-vf-accessibilite.js`, `skills/cockpit-moteur/assets/viewer.html`
- **fin (cc2224fc..fix/audit-cockpit-lot-0-fin)** (16) : `amont/patches/assets__serve.mjs.diff`, `amont/patches/scripts__lib__common.mjs.diff`, `scripts/tests/test-cockpit-confinement.sh`, `scripts/tests/test-cockpit-cycle-serveur.sh`, `scripts/tests/test-cockpit-equipe-etats.sh`, `scripts/tests/test-cockpit-git-details.sh`, `scripts/tests/test-cockpit-git-signature.sh`, `scripts/vf-cockpit-etat-officiel.mjs`, `scripts/vf-cockpit-git-sortant.mjs`, `scripts/vf-cockpit-lanceur-verrou.mjs`, `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit.mjs`, `skills/cockpit-moteur/VENDORED.txt`, `skills/cockpit-moteur/assets/serve.mjs`, `skills/cockpit-moteur/scripts/lib/common.mjs`, `skills/cockpit-moteur/scripts/lib/vf-git-sortant.mjs`
- **rec (dd3f1792..fix/audit-cockpit-lot-0-rec)** (12) : `scripts/tests/chrome-fin.mjs`, `scripts/tests/chrome-fr-donnees.mjs`, `scripts/tests/test-cockpit-accessibilite.sh`, `scripts/tests/test-cockpit-equipe-etats.sh`, `scripts/tests/test-cockpit-fr-donnees.sh`, `scripts/tests/test-cockpit-terminal-fin.sh`, `scripts/vf-cockpit-terminal-tiroir-style.mjs`, `scripts/vf-cockpit-terminal-vue.mjs`, `skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js`, `skills/cockpit-moteur/assets/ui/72-vf-equipe.js`, `skills/cockpit-moteur/assets/ui/76-vf-git-entete.js`, `skills/cockpit-moteur/assets/ui/80-vf-fr.js`
- **A-04 (dd3f1792..fix/audit-cockpit-lot-0-a04)** (4) : `scripts/tests/test-cockpit-git-config-depot.sh`, `scripts/tests/test-cockpit-git-env.sh`, `scripts/vf-cockpit-git-durci.mjs`, `scripts/vf-cockpit-paths.mjs`

## Coût

32 agents dispatchés : 14 vf-coder (8 workers repris en correction, jointure, corrections finales, recette, A-04,
non-régression, docs), 11 vf-reviewer, 6 vf-auditer, 1 juge de recette. Jetons de sous-agents relevés sur les blocs
reçus : 8 159 686 (dont 190 783 pour le nœud docs). Tours de correction : 1 à 3 par sous-lot ; 5 sur la famille A-02 (plafond
annoncé atteint).

## Preuves E6

Format : verdict — commande — code de sortie — SHA.

- Rouge sur la base, par ligne : chaque suite de ligne jouée sur une extraction de 437e8edd (ou de la tête précédente
  pour une correction) — `bash plugin/cockpit/scripts/tests/<suite>` — rc 1, assertion de la ligne en échec — 437e8edd.
  Détail (attendu, obtenu) dans les blocs typés des workers ; suites : test-cockpit-equipe-etats.sh (D1-D4, M3),
  test-cockpit-lecture-fil.sh (D5-D8), test-cockpit-cycle-serveur.sh (H2, H3, AM7), test-cockpit-flux-unique.sh (H1),
  test-cockpit-direct-coupe.sh (M9), test-cockpit-fr-donnees.sh (H4), test-cockpit-confinement.sh (A-02, B-01, B-04,
  H3 journal), test-cockpit-demander-bornes.sh (A-01, B-02, B-03, B-06), test-cockpit-git-config-depot.sh (A-04 :
  14 PASS / 23 FAIL sur la base), test-cockpit-terminal-fin.sh (M10, M11), test-cockpit-accessibilite.sh (M7, X4, X6, X7).
- Non-régression complète — 79 suites `test-cockpit-*.sh` une par une, ensemble joué = ensemble présent (`comm`) — rc 0
  pour les 79 — 5e8a4c76.
- Job `gates` de ci.yml, étapes 1 à 20 et 23 — rc 0 — 5e8a4c76 (étapes 21 et 24 réservées au push sur main).
- `bash plugin/cockpit/amont/synchro.sh verifier` — rc 0 — 5e8a4c76.
- Revue finale (vf-reviewer) — suites git-config-depot, git-env, confinement, fr-donnees, terminal-fin, accessibilite,
  chrome-fr, equipe-etats sur extraction — rc 0 — 864f8b89.
- Audit final (vf-auditer) — test-cockpit-git-config-depot.sh (37 PASS) et synchro.sh verifier — rc 0 — 864f8b89 ;
  verdict AUDC-A-04 tient, AUDC-A-02 partielle.
- Correction H4 tour 3 — test-cockpit-fr-donnees.sh (22 PASS) et test-cockpit-chrome-fr.sh (97 PASS) — rc 0 — a9e9bd13 ;
  trois mutants rouges.
- Recette par captures — 9 points, 8 tenus à la première passe, H4 corrigé ensuite — cc2224fc. Captures dans le dossier
  non suivi `.playwright-mcp/audc-recette/` de l'arbre principal ; pour Samuel : bandeau de lancement à 1280×720 avant
  et après proposition, et après « Annuler ».
- CI de la PR #227, premier passage (tête 95cf88a0) : job `gates` vert, 8 shards sur 9 verts ; shard 4 rouge sur test-cockpit-terminal-fin.sh (FIN.3 à FIN.5 : le runner n'a pas `claude`, le pré-vol du lancement refusait la proposition ; suite verte à tort en local où `claude` est sur le PATH). Corrigé dans le test (faux `claude` du dépôt sur le PATH du serveur, comme test-cockpit-lancer-bout-en-bout.sh) — 22f83ba4 ; rouge reproduit en local sans `claude` (18 PASS / 17 FAIL, rc 1), vert après (35 PASS, rc 0). Second passage de la CI : voir la PR.
- Docs (CHANGELOG 35c51756, REGISTRE 30bb9307, BACKLOG e71f969b) — check-machine-paths, check-version-sync, check-divergence, check-planning-consumers-registered, check-dev-bootstrap, check-workstream-pointer, check-state-integrity, check-instruction-budget, check-gate-touche, check-baseline-arbitrage, check-python-isolation, test-cockpit-fr-donnees.sh (22 PASS), test-cockpit-chrome-fr.sh (97 PASS) — rc 0 — e71f969b.

```json
{
 "preuves": [
  {
   "verdict": "gate:test-cockpit-suites",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-*.sh (79 suites, une par une)",
   "exit_code": 0,
   "sha": "5e8a4c76"
  },
  {
   "verdict": "gate:synchro-vendor",
   "commande": "bash plugin/cockpit/amont/synchro.sh verifier",
   "exit_code": 0,
   "sha": "5e8a4c76"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-git-config-depot.sh",
   "exit_code": 0,
   "sha": "864f8b89"
  },
  {
   "verdict": "audit",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-confinement.sh",
   "exit_code": 0,
   "sha": "864f8b89"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-fr-donnees.sh",
   "exit_code": 0,
   "sha": "a9e9bd13"
  },
  {
   "verdict": "gate:test-cockpit-chrome-fr",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh",
   "exit_code": 0,
   "sha": "e71f969b"
  },
  {
   "verdict": "gate:check-machine-paths",
   "commande": "bash scripts/check-machine-paths.sh",
   "exit_code": 0,
   "sha": "e71f969b"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-fin.sh",
   "exit_code": 0,
   "sha": "22f83ba4"
  },
  {
   "verdict": "recette",
   "preuve": "amont"
  }
 ]
}
```

## Prochaine étape

Relecture de la PR par Samuel, puis la Phase 79 en première vague avec la classe restante d'AUDC-A-02 et AUDC-A-03.
