# Mission — cadrage et plans de la Phase 76, « Traçabilité au cockpit » (2026-11-11)

Manager : `vf-dev-manager`, mode autonome, design `auto`. Compartiment `fiabilite`, jalon `vibeflow-v2.0`.
Worktree `.claude/worktrees/phase-76`, branche `feat/phase-76-tracabilite`, base `origin/integration/cockpit-audit`
(`f763b556`). Verrou de phase `--ws fiabilite --phase 76`. Demande : Samuel (session principale Claude Code,
2026-11-11), cadrer et planifier en parallèle les Phases 73 à 77, 79 et 80 ; cette mission porte la 76 et s'arrête aux
plans écrits et vérifiés. Aucune exécution, aucun code, aucune suite. Deux temps : un premier passage (PR #230), puis
une reprise le même jour sur mandat de la session principale (trois réponses de Samuel, un plan de plus, vérifications
complètes), coupée une fois par l'arrêt de la session (quota du compte, HTTP 429) et reprise sans perte.

## Résultat

- **Cadrée** : `76-CONTEXT.md`, décisions P76-D-01 à P76-D-39 (dont 15bis). P76-D-32 à P76-D-34 sont des arbitrages
  de Samuel (AskUserQuestion session principale, 2026-11-11) ; toutes les autres sont « décision déléguée par Samuel
  (message session principale, 2026-11-08), option recommandée ». Aucun arbitrage passé rouvert.
- **Exigences** : famille neuve `TRAC`, TRAC-01 à TRAC-13, derrière le repère de la Phase 76 du ledger.
- **Questions en attente** : format posé et possédé par la 76 (contrats C76-Q1 écriture, C76-Q2 lecture, champ
  facultatif `meta.vf.questions` de `cockpit-project@1`), quatre états (`en-attente`, `appliquee`, `tranchee`,
  `a-verifier`) plus `mal-formee` ; la régie de la 73 l'affiche. Plan 76-09.
- **Contrat de design** : `76-UI-SPEC.md`, six tours, statut `approved`. `gsd-ui-checker` VERIFIED (tour 4, trois FLAG
  fermés ensuite) ; juge de design frais à chaque tour : 75, 73, 84, 85, 87 puis **92/100 `passed`** (tour 6).
- **Plans** : 9 plans en 6 vagues (`76-01` à `76-09`), plus `76-RESEARCH.md`, `76-PATTERNS.md`, `76-VALIDATION.md`.
  Vérifications fraîches complètes : voir § Vérification.
- **Gate de sortie** : son contrôle E4 dit « manque » (plans non exécutés, STATE non marqué) : attendu pour une mission
  de cadrage, non verdi.

## Plan de bataille (DAG)

Premier passage : trois éclaireurs (code de l'onglet Projet ; sources mesurées ; phases voisines et antériorité) →
trois panels (forme ; chemin des données ; mémoire) → cadrage porté par le manager → UI-SPEC et RESEARCH en parallèle →
critique de design → plans → vérification fraîche → livraison. Reprise : arbitrages consignés et contrats C76-Q1/C76-Q2
poussés tôt pour la 73 → plan 76-09 et revalidation 79/80 → trois vérifications pour de bon (`gsd-ui-checker`, juge de
design sur chaque tour, contrôleurs de plans frais et complets) → quatre révisions des plans et six tours d'UI-SPEC →
livraison.

## Décisions structurantes (détail : `76-CONTEXT.md`)

- **Forme** (P76-D-01, confirmée par P76-D-33) : panneaux reliés de l'onglet Projet, voisinage seul ; ni canevas ni
  quatrième onglet. L'exigence ouvre son plan, ses décisions citées au ledger et ses preuves (P76-D-38).
- **Trous** (P76-D-04, P76-D-15bis, confirmés par P76-D-32) : absence en glyphe et mot neutres ; octogone au trait
  corail pour une contradiction lue seulement.
- **Navigation** (P76-D-03, P76-D-30) : `select`/`reveal`, Retour par la pile commune `window.VF_PANNEAU` de la Phase 80
  (`empiler` pour les panneaux sur mesure), aucun fil d'Ariane ; globales lues au moment de l'appel (P80-D-59/60).
- **Données** (P76-D-06, P76-D-31) : route à la demande `GET /api/vf/tracabilite` (`vibeflow/cockpit-trace@1`), ligne
  dans la table `ROUTES` de `vf-cockpit-server.mjs` (79-05) ; le planning se lit dans l'instantané de la collecte, ses
  manques en champs facultatifs de `cockpit-project@1` (A32) ; ADR, commits citants et mémoire en lecture confinée,
  bornée, en cache par `instantane().git.sig` (A47).
- **Mémoire** (P76-D-19 à D-23) : fichiers suivis seulement, structure seule (nom, agent, type, jour, comptes, chemin du
  fichier, chemins absents relatifs) ; pas de « périmée » devinée.
- **Questions en attente** (P76-D-34 à D-37) : format C76-Q1, lecture C76-Q2, état « appliquée » pour une option
  recommandée appliquée sous délégation (contestable, jamais mêlée à « À vous »).
- **Retrait sur preuve de comportement** (P76-D-39) : la condition d'arrêt de 76-08 est l'équivalence de la porte de la
  80, la couverture du panneau d'exigence, PL2.9 et PV2.5, le négatif de la 80 et toutes les suites vertes avant et
  après sous `CI=1` ; une sonde statique n'est jamais une porte.
- **Un ajout, un retrait** (P76-D-25) : le nœud « Exigences » et les liens « couvre » quittent le graphe Projet ; la
  porte `window.VF_EXIGENCES.lireExigences` de la 80 est rebranchée sur `meta.vf.trace.exigences`, le panneau
  d'exigence de la 76 remplace « Couverte par » avant le retrait.

## Vérification

- **UI-SPEC** : `gsd-ui-checker` VERIFIED au tour 4 (Copywriting, Visuals, Registry, Provenance PASS ; Color,
  Typography, Spacing FLAG, fermés aux tours 5 et 6). Juge de design frais à chaque tour ; deux classes de défaut
  fermées en tant que classes (lignes de longueur variable : gabarits à emplacements fixes ; une seule source du niveau
  par surface). Tour 6 : 92/100 `passed`, aucun majeur ; huit mineurs laissés au craft d'exécution (§ Limites).
- **Plans** : quatre contrôleurs `gsd-plan-checker` frais, lecture complète, plus un audit dédié aux témoins.
  - À `d4e1b8f2` : 2 bloquants (retrait sans rebranchement de la porte de la 80 ; condition d'arrêt en prose) ; audit
    des témoins : 5 bloquants (M-LOCAL, M-NUE-RELIEE, T10.8, identifiants `REQ-C`, code de sortie masqué).
  - À `0a6a3440` : 4 bloquants (`cible` de la porte ; lecteur générique de `viewer.html` ; M-GARDE sans ancre ; compte
    `muté` et archives de 76-09).
  - À `7116c87f` : 2 bloquants (`cible` brute non observable ; sonde aveugle aux lecteurs en expression régulière).
  - À `e99e6184` : 1 bloquant (sonde statique aveugle à `kind === 'exigences'`, exclusion qui masquait le jeton
    `couvre`). Troisième tour sur la même famille : P76-D-39 rend la condition d'arrêt du retrait comportementale, la
    sonde devient un inventaire.
  - À `239783d8` : 1 bloquant (une suite Chrome sautée comptait comme preuve) ; à `cc3591e0` : 3 bloquants
    (détection de Chrome absent sur « AM7 », `rc` d'après non vérifiés, négatif de la 80 affaibli). Les suites sont
    rejouées sous `CI=1`, lancées par un lanceur à codes 0/1/3/4 ; le manager a mesuré que 14 des 79 suites n'écrivent
    pas de ligne `Résultats`, et l'ensemble joué vient du journal du lanceur.
  - À `b2fd07bf` : **0 bloquant, 0 avertissement**, 3 infos (tête de la 80 à relire au rebase, négatif plus strict que
    celui de 80-07, ordre entre les codes 1 et 4 du lanceur à écrire).
- **Revalidation amont** : plans revalidés contre la 79 à `677d19fa` et la 80 à `47ab9fd3` (PL2.9 lu à 80-07
  `94f65905`, PV2.5 à 80-11 `63d908f6`) ; plans revalidés ensuite jusqu'à la 79 à `5eaa6c41` et la 80 à `c8207707` ; chaque diff relu par un contrôleur frais : aucun impact sur
  la 76. La 80 est à `9443e492` à la fin de la mission (seul `80-CONTEXT.md` a changé, 12 lignes, à relire au rebase).

## Carte des fichiers

Chemins relatifs à `plugin/cockpit/` sauf mention. Toutes les vagues s'exécutent **après** la Phase 79 (première vague
et plans cités) ; 76-06, 76-07 et 76-08 **après** la Phase 80.

| Plan | Vague | Exigences | Fichiers créés ou modifiés | Plans de la 79 et de la 80 cités |
|---|---|---|---|---|
| 76-01 Chaîne d'exigences (fonctions pures) | 1 | TRAC-01, 02, 03, 04, 11 | créés : `scripts/vf-cockpit-frontmatter.mjs`, `vf-cockpit-trace-ledger.mjs`, `vf-cockpit-trace-collecte.mjs`, `vf-cockpit-trace-chaine.mjs`, `vf-cockpit-trace-bilans.mjs`, `scripts/tests/test-cockpit-tracabilite-chaine.sh` ; modifié : `scripts/vf-cockpit-avancement.mjs` | 79-01, 79-07 |
| 76-02 Décisions | 1 | TRAC-05, 06 | créés : `scripts/vf-cockpit-registres.mjs` (sauf si la 73 l'a livré), `vf-cockpit-trace-git.mjs`, `scripts/tests/test-cockpit-tracabilite-decisions.sh` | 79-01, 79-07 |
| 76-03 Mémoire des agents | 2 | TRAC-07, 08 | créés : `scripts/vf-cockpit-trace-memoire.mjs`, `vf-cockpit-trace-memoire-git.mjs`, `scripts/tests/test-cockpit-tracabilite-memoire.sh` | 79-01, 79-07 |
| 76-04 Branchement dans la collecte | 2 | TRAC-10, 01, 03, 04, 05 | modifiés : `scripts/vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-trace-collecte.mjs`, `vf-cockpit-interface.json` ; créés : `scripts/vf-cockpit-trace-texte.mjs`, `scripts/tests/test-cockpit-tracabilite-collecte.sh` | 79-07, 79-09, 79-10, 79-11, 79-15 |
| 76-05 Route `GET /api/vf/tracabilite` | 3 | TRAC-10, 11, 05, 06, 07 | créés : `scripts/vf-cockpit-trace.mjs`, `vf-cockpit-trace-vues.mjs`, `scripts/tests/test-cockpit-tracabilite-route.sh` ; modifiés : `scripts/vf-cockpit-server.mjs` (une ligne de `ROUTES`), `vf-cockpit-interface.json`, `README.md`, `scripts/tests/test-cockpit-routes.sh` (RK.1, A54, `Gate-Touche:`) | 79-02, 79-05, 79-06, 79-07, 79-09 |
| 76-06 Page : phase, preuves, Jalon, exigence | 4 | TRAC-01, 02, 03, 04, 09, 11 | créés : `skills/cockpit-moteur/assets/ui/74-vf-trace.js`, `74-vf-trace-rendu.js`, `74-vf-trace-sections.js`, `74-vf-trace-style.js`, `74-vf-trace-exigence.js`, `74-vf-trace-liste.js`, `scripts/tests/test-cockpit-tracabilite-page.sh`, `chrome-tracabilite.mjs`, `chrome-tracabilite-exigence.mjs` ; modifiés : `skills/cockpit-moteur/VENDORED.txt` (lignes `AJOUT`), `scripts/vf-cockpit-fr-exclusions.json` | 79-02, 79-05, 79-06, 79-12, 79-14, 79-16, 79-17 ; 80 (P80-C76-1 à 5) |
| 76-07 Page : Décisions, Mémoire, panneaux | 5 | TRAC-05, 06, 07, 08, 09, 11 | créés : `ui/74-vf-trace-decisions.js`, `74-vf-trace-memoire.js`, `scripts/tests/test-cockpit-tracabilite-panneaux.sh`, `chrome-tracabilite-panneaux.mjs`, `chrome-tracabilite-memoire.mjs` ; modifiés : `ui/74-vf-trace.js`, `74-vf-trace-liste.js`, `74-vf-trace-style.js`, `VENDORED.txt`, `vf-cockpit-fr-exclusions.json` | 79-02, 79-06, 79-16, 79-17 ; 80 |
| 76-08 Retrait du nœud `.req`, clôture | 6 | TRAC-12 | modifiés : `scripts/vf-cockpit-project.mjs`, `vf-cockpit-types.mjs`, `vf-cockpit-ask.mjs`, `skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js` (région `porte-exigences` seulement), `scripts/tests/test-cockpit-projet-graphe.sh`, `test-cockpit-questions.sh` (`Gate-Touche:`), `CHANGELOG.md` ; créés : `scripts/tests/retrait-lecteurs.mjs` (inventaire), `rejouer-suites.sh` (lanceur à codes 0/1/3/4), `chrome-tracabilite-couverture.mjs` ; hors module : `README.md`, `README.fr.md` (compteur de suites), `scripts/ci-shard-suites.sh` | 79-01, 79-02, 79-05, 79-06, 79-10, 79-11, 79-15, 79-21 ; 80-07 (PL2.9), 80-11 (PV2.5) |
| 76-09 Questions en attente | 4 | TRAC-13 | créés : `scripts/vf-cockpit-questions-attente.mjs`, `scripts/tests/test-cockpit-questions-attente.sh` ; modifiés : `vf-cockpit-trace-collecte.mjs`, `vf-cockpit-interface.json` | 79-09, 79-15 |

Chaque plan écrit aussi sa trace rouge `76-0N-RED-TRACE.md` (76-08 : `76-08-PORTE-AVANT.json`,
`76-08-COUVERTE-AVANT.txt`) dans le dossier de phase.

**Fichiers partagés avec d'autres phases** (en tête de la jointure) :

| Fichier | Phases qui le touchent | Plan de la 76 |
|---|---|---|
| `scripts/vf-cockpit-server.mjs` (table `ROUTES`, une ligne alphabétique, A52) | 79 (79-05), 73, 75, 77 | 76-05 |
| `scripts/tests/test-cockpit-routes.sh` (liste RK.1, A54) | 79, 73, 75, 77 | 76-05 |
| `scripts/vf-cockpit-interface.json` | 73, 74, 75, 77, 79 | 76-04, 76-05, 76-09 |
| `scripts/vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs` (lecture du planning de la collecte) | 80, 75, 77 (aucun plan de la 79 ne les modifie) | 76-04, 76-08 |
| `skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js` (porte `lireExigences`) | 80 (80-07) | 76-08 |
| `scripts/vf-cockpit-ask.mjs`, `scripts/tests/test-cockpit-questions.sh` | 79 (79-01, 79-06) | 76-08 |
| `scripts/vf-cockpit-avancement.mjs` | 80 | 76-01 |
| `scripts/vf-cockpit-registres.mjs` | 73 | 76-02 |
| `skills/cockpit-moteur/VENDORED.txt` (lignes `AJOUT` alphabétiques) | 79, 80, 73, 74 | 76-06, 76-07 |
| `scripts/vf-cockpit-fr-exclusions.json` (dictionnaire du français) | toute phase qui affiche un littéral anglais | 76-06, 76-07 |
| `CHANGELOG.md` du module, `README.md` du module, README racine (compteur de suites), `scripts/ci-shard-suites.sh` | toutes les phases qui ajoutent une suite | 76-05, 76-08 |
| `viewer.html`, `ui/00-vibeflow.js`, `ui/69-vf-flux.js` (`EVENEMENTS`) | 79, 80 | non touchés (la 76 n'émet aucun événement de flux) |

**Ce que la 76 attend** : de la 79, les plans cités ci-dessus (table `ROUTES` et réponse gardée 79-05, instantané
79-09, coquille et `surOnglet` 79-16, magasin d'état 79-17, socle de test et `cockpit_module_*` 79-02/79-06, retrait
d'`amont/`) et les amendements A10 à A13, A30 à A32, A34, A44, A47, A48, A51, A52, A54 ; de la 80, P80-C76-1 à 6
(`addPanelSection`, `select`/`reveal`, `VF_PANNEAU.empiler`/`retour`, `piedExigences`, porte
`window.VF_EXIGENCES.lireExigences`) et ses témoins PL2.9 et PV2.5. **Ce qu'elle fournit** : à la 73, le format des
questions en attente et sa lecture (`meta.vf.questions`), et l'extracteur de définitions des registres ; à la 77, les
compteurs de la mémoire par la route ; à la 80, `meta.vf.trace.exigences`, source de sa porte après le retrait.

## À Samuel

- **P76-Q-01** et **P76-Q-02** (A-1 et A-2 de la première version) : tranchées le 2026-11-11 (P76-D-32, P76-D-33).
- **P76-Q-03 — poids ajouté à la page Projet** (environ 0,4 Mo de JSON de plus, conséquence de la règle A32 de la 79) :
  état « appliquée » (option (a), garder et mesurer à l'exécution, P76-D-31), contestable. Aucune question n'attend.

## À verser par la jointure

Texte exact à poser par la session principale.

1. **ROADMAP, checklist** : `- [ ] Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire (inscrite 2026-11-03, jalon vibeflow-v2.0 ; cadrée et planifiée 2026-11-11, 9 plans)`.
2. **ROADMAP, table `## Progress`** (si les phases planifiées y figurent) : `| 76. Traçabilité au cockpit | vibeflow-v2.0 | 0/9 | Planned — cadrée 2026-11-11, TRAC-01..13 |`.
3. **REQUIREMENTS** : retirer les deux repères de la Phase 76 ; compteurs de couverture du jalon : + 13 exigences `TRAC`.
4. **REGISTRE.md de l'audit**, ligne AUDC-I33 : `ouvert — planifié en Phase 76 (76-01, 76-04, 76-06), 2026-11-11`.
5. **REGISTRE.md § 3**, ligne à ajouter : `| Le nœud « Exigences » du graphe Projet, ses cartes et les liens « couvre » | la section « Traçabilité » et le panneau d'exigence | Phase 76 |`.
6. **BACKLOG**, sujet neuf : « `check-method-budget.sh` (`rangement_memoires`) juge une mémoire « hors index » par
   sous-chaîne (`grep -qF` du nom de fichier) : `a.md` est trouvé dans `xa.md`. Le cockpit (Phase 76) juge par égalité
   exacte. À aligner. »
7. **Six sections « À Samuel »** des autres cadrages (73, 74, 75, 77, 79, 80) : à réécrire au format C76-Q1 (la 73 l'a
   déjà fait). Mesure du 2026-11-11 sur leurs têtes : 75 : 5 puces, 77 : 2, 79 : 4, 74 : 0, 80 : pas de section.
8. **Phase 73** : si elle livre `scripts/vf-cockpit-registres.mjs` avant la 76, signature attendue
   `definitionsRegistre(txt, { phase, ws, fichier, couper })`, `phase` = identifiant de nœud (`ph-<N>`).
9. **Extension de C76-Q2 écrite par 76-09** : `phase: null` quand le dossier d'une question n'a pas de nœud de phase.

## Limites

- Les contrats de la 79 et de la 80 sont figés mais non exécutés : chaque plan marque « à revalider » ce qui en dépend.
  Avant exécution, les neuf plans repassent devant un vérificateur frais contre la base qui porte la 79 et la 80.
- Huit mineurs du dernier juge de design restent au craft d'exécution (`vf-crafter`, P76-D-26) : niveau dit deux fois
  dans le nom accessible d'une ligne ; une phrase d'empilement du § 5.1 ; hauteur réelle de `.vf-ref` dans le budget du
  repli de preuves ; surcharge `line-height` de `.tag` et écart de pagination ; gabarit des lignes du § 5.4 ; deux
  graisses pour `.vf-trace-plus` ; taille de « Lecture bornée » ; alignement des paires glyphe-mot sur deux lignes.
- 76-08 : la sonde statique n'est qu'un inventaire (P76-D-39) ; un lecteur hors des suites du cockpit et des témoins de
  la 80 ne serait vu que par la revue de la phase. Les sauts hors Chrome qui sortent 0 (par ex. « hors dépôt : SAUTÉ »)
  sont traités pareil avant et après. La 77 n'est pas exécutée : un lecteur de Projet qu'elle ajoutera est à
  revalider à son exécution (elle rejoue R76.3 et R76.4).
- 76-06 et 76-07 : le garde d'inventaire du français est supposé s'invoquer comme dans `test-cockpit-chrome-fr.sh`.
- Un fichier de mémoire modifié sur place, sans commit, n'invalide le cache de la route qu'au changement suivant.
- `check-version-sync.sh` § 9 (compteur des suites) rouge entre 76-01 et 76-08, écart assumé dans chaque plan.
- Mesures de volumes faites sur ce dépôt seul. Le plafond de sous-agents de la session (20) a fait sauter le
  `gsd-ui-checker` au premier passage ; levé à 100 à la reprise, toutes les vérifications ont été rejouées.
- Des agents du premier passage ont écrit à la racine du scratchpad partagé (`g.txt`, `79.md`, `80.md`), non supprimés.

## Coût

Premier passage : 12 lancements et 5 reprises, 2 144 605 jetons de sous-agents. Reprise : 7 lancements (un juge de
design par tour 3 à 6, quatre contrôleurs de plans dont un audit de témoins) et une dizaine de reprises de correction
par SendMessage (codeur des plans : quatre révisions et la reprise après coupure ; codeur de l'UI-SPEC : tours 4 à 6) ;
jetons de sous-agents reçus à la reprise (somme des blocs) : 8 346 024. Deux révisions de plus ont été
nécessaires pour la condition d'arrêt de 76-08 (révisions 5 à 8), après P76-D-39.

## Preuves E6

Format : verdict — commande — code de sortie — SHA. Mission de cadrage : aucune suite de tests n'est jouée (aucun code).

- Job `gates` de ci.yml, étapes 1 à 20 rejouées une à une sous `bash -e` (21 et 24 réservées au push sur main ; 23
  demande une installation npm réseau, non jouée) — rc 0 pour les 20 — `b2fd07bf` (rejeu précédent : `608db651`, rc 0).
- STATE intouché — `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` —
  rc 0 — tête de la branche.
- Couverture des exigences — union des `requirements:` du frontmatter des neuf plans = TRAC-01 à TRAC-13 ; texte du
  ledger recoupé par les contrôleurs frais — `b2fd07bf`.
- Plans : contrôleurs `gsd-plan-checker` frais, lecture complète — ISSUES FOUND à `d4e1b8f2`, `0a6a3440`, `7116c87f`,
  `e99e6184`, `239783d8`, `cc3591e0` ; **0 bloquant, 0 avertissement** à `b2fd07bf`.
- UI-SPEC : `gsd-ui-checker` VERIFIED (`a0468f32`) ; juge de design frais 92/100 `passed` (`4cc56286`).
- Suites sans ligne `Résultats` — `grep -q 'Résultats'` sur les 79 `test-cockpit-*.sh` — 14 sans — base de la branche.

```json
{
 "preuves": [
  {"verdict": "gate:ci-gates-1-20", "commande": "étapes 1 à 20 du job gates de .github/workflows/ci.yml, bash -e, une par une", "exit_code": 0, "sha": "b2fd07bf"},
  {"verdict": "state-intouche", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "b2fd07bf"},
  {"verdict": "plans-verifies", "commande": "gsd-plan-checker frais, fermeture de 76-08, 0 bloquant 0 avertissement", "exit_code": 0, "sha": "b2fd07bf"},
  {"verdict": "ui-spec-verifie", "commande": "gsd-ui-checker VERIFIED", "exit_code": 0, "sha": "a0468f32"},
  {"verdict": "ui-spec-critique", "commande": "vf-design-judge frais, 92/100 passed", "exit_code": 0, "sha": "4cc56286"}
 ]
}
```

## Prochaine étape

Exécuter la Phase 76 après la Phase 79 et la Phase 80 : d'abord une re-vérification fraîche des neuf plans contre cette
base, puis les vagues 1 à 6.
