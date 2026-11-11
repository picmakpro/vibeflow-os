# Mission — Phase 74 « L'équipe dans le temps », cadrage et plans (2026-11-11)

**Manager :** `vf-dev-manager`, dispatché par la session principale (vague des sept cadrages parallèles de l'audit du
cockpit, demande de Samuel, session principale Claude Code, 2026-11-11).
**Branche :** `feat/phase-74-equipe-dans-le-temps`, base `origin/integration/cockpit-audit` (`f763b556`), worktree
`.claude/worktrees/phase-74`. Verrou de phase `--ws fiabilite --phase 74`.
**Mode :** autonome, design `force`. Aucune exécution, aucun fichier de code, aucune suite.

## Résultat

- Cadrage : `74-CONTEXT.md`, P74-D-01 à P74-D-45, toutes décisions déléguées par Samuel (message session principale,
  2026-11-08), option recommandée ; aucun arbitrage neuf ; quatre points « À Samuel », non bloquants.
- Exigences : famille `TEMP`, TEMP-01 à TEMP-12 (préfixe vérifié libre le 2026-11-11).
- Spécification d'interface : `74-UI-SPEC.md` (409 lignes), critique fraîche `passed` 82/100 au second passage.
- Recherche : `74-RESEARCH.md`.
- Plans : neuf (74-01 à 74-09), cinq vagues ; vérification fraîche des plans : PASS au second passage (§ Preuves E6).
- Corps de la section `### Phase 74:` du ROADMAP réécrit (titre, checklist, `## Progress` intacts).

## Plan de bataille (DAG)

Scratchpad `phase-74/MISSION-74.dag.json`. Nœuds : éclaireurs code et arbitrages, trois panels (coût, relecture,
fiche) → cadrage (manager) → exigences et ROADMAP (manager) ∥ craft UI-SPEC (`vf-crafter`) → critique
(`vf-design-judge`) → recherche (`gsd-phase-researcher`) → plans (`vf-coder`) → vérification du cadrage (vérificateur
frais) ∥ vérification des plans (`gsd-plan-checker`) → PR et rapport.

Écart : les éclaireurs et les trois panels n'ont pas pu être lancés (plafond de 20 sous-agents simultanés de la
session atteint par la vague des sept cadrages, « Do not retry ») ; le manager a relevé les faits lui-même dans le code et
les annexes, et a tranché sur l'option recommandée, chaque décision citant sa source. La consigne du brief « les panels
tranchent » n'a donc pas été tenue à la lettre ; elle est compensée par deux juges frais (critique d'interface,
vérification du cadrage) et la vérification des plans.

Changement de consigne en cours de mission (session principale) : les contrats de la Phase 79 étant figés
(`3119d82a`), le second temps s'est enchaîné sans rendre la main.

## Décisions

Registre complet : `74-CONTEXT.md`. Les plus engageantes :

- P74-D-01 : la frise est bâtie sur `DESIGN.md` § 9 — le nœud s'écrit sur la voie, la couleur reste aux trois états —
  alors que le but arbitré dit « colorée par nœud de DAG » (À Samuel, point 1).
- P74-D-20, D-24 : coût en jetons et en durée seulement, ni montant en devise ni limites de 5 h et de 7 jours
  (À Samuel, points 2 et 3).
- P74-D-13 : la relecture dérive l'état des nœuds des voies ; le statut du DAG n'est pas rejoué (À Samuel, point 4).
- P74-D-22 : un seul calcul de jetons, celui de l'index de la Phase 79 (somme de `message.usage` dédoublonnée par
  identifiant de message) ; la Phase 52 le réutilise.
- P74-D-28 : retraits — la boîte de transcript du panneau et son bouton, la durée qui compte les veilles, et (avec la 73)
  la carte « Terminés depuis moins de 24 h » seule ; le groupe repliable du tiroir « Au travail » (P69-D-18) reste.
- P74-D-38 : le réducteur de transcript gagne trois champs facultatifs (échec d'outil, compaction, message de l'humain),
  sans texte, sans changement de version.
- P74-D-43 : rendu en modules neufs `ui/74-vf-*.js`, aucun fichier du moteur, aucun bump propre.

## À Samuel (non bloquant)

Les quatre points de `74-CONTEXT.md` § « À Samuel » : couleur par nœud contre `DESIGN.md` § 9 ; pas de montant en
devise ; limites de 5 h et de 7 jours en réserve ; relecture « nœud par nœud » tenue par dérivation. Plus un point de
recette dans la spécification : le genre `silence` ne dessine rien (P74-D-36).

## Carte des fichiers

### Par plan (chemins sous `plugin/cockpit/` sauf mention ; chaque plan écrit aussi son `74-NN-RED-TRACE.md`)

| Plan | Vague | Dépend de | Fichiers créés ou modifiés |
|---|---|---|---|
| 74-01 | 1 | — | `skills/cockpit-moteur/assets/ui/74-vf-frise-modele.js`, `scripts/tests/test-cockpit-frise-modele.sh`, `scripts/tests/frise-fabrique.mjs` |
| 74-02 | 1 | — | `scripts/vf-cockpit-transcript.mjs`, `scripts/tests/test-cockpit-transcript.sh` |
| 74-03 | 2 | 74-02 | `ui/74-vf-fiche-texte.js`, `scripts/tests/test-cockpit-fiche-texte.sh` |
| 74-04 | 3 | 74-01 | `ui/74-vf-frise.js`, `ui/74-vf-frise-pistes.js`, `ui/74-vf-frise-style.js`, `scripts/tests/test-cockpit-frise.sh`, `scripts/tests/chrome-frise.mjs` |
| 74-05 | 3 | 74-01, 74-03 | `ui/74-vf-fiche.js`, `ui/74-vf-fiche-style.js`, `scripts/tests/test-cockpit-fiche.sh`, `scripts/tests/chrome-fiche.mjs` |
| 74-06 | 4 | 74-04 | `ui/74-vf-frise-curseur.js`, `ui/74-vf-frise-encart.js`, `ui/74-vf-frise-carte.js`, `scripts/tests/test-cockpit-frise-curseur.sh` |
| 74-07 | 4 | 74-04 | `ui/74-vf-frise-depot.js`, `ui/74-vf-cout.js`, `ui/77-vf-git-vue-detail.js` (une ligne d'export `ouvrir(sha)`), `scripts/tests/test-cockpit-frise-cout.sh` |
| 74-08 | 4 | 74-04, 74-05 | `ui/72-vf-equipe.js`, `ui/71-vf-equipe-rendu.js`, `ui/70-vf-live.js`, `scripts/vf-cockpit-equipe-carte.mjs` (si la 73 n'a pas retiré la carte), `scripts/tests/test-cockpit-equipe.sh`, `scripts/tests/test-cockpit-equipe-etats.sh`, `scripts/tests/test-cockpit-transcript.sh`, `scripts/tests/test-cockpit-lancer-suivi.sh`, `scripts/tests/chrome-equipe-clavier.mjs` ; conditionnel : une ligne dans le fichier de la régie de la 73 (R5b) |
| 74-09 | 5 | 74-04 à 74-08 | `scripts/tests/test-cockpit-frise-bornes.sh`, `scripts/tests/test-cockpit-chaine-xss.sh`, `README.md` du module, `CHANGELOG.md` du module, `README.md` et `README.fr.md` à la racine (compteur de suites) |

### Fichiers partagés avec d'autres phases

| Fichier | Autres phases | Plan de la 74 | Règle |
|---|---|---|---|
| `ui/70-vf-live.js` | 79 (A7) | 74-08 | après la vague de la 79 qui le modifie ; rebase sur elle |
| `ui/71-vf-equipe-rendu.js`, `ui/72-vf-equipe.js`, `test-cockpit-equipe.sh`, `chrome-equipe-clavier.mjs` | 73 (régie) | 74-08 seul, vague 4 | après la 73 ; retraits conditionnels à ce que la 73 a déjà retiré |
| `scripts/vf-cockpit-equipe-carte.mjs`, `test-cockpit-equipe-etats.sh` | 73 | 74-08 | seulement si la 73 n'a pas retiré la carte |
| `scripts/vf-cockpit-transcript.mjs`, `test-cockpit-transcript.sh` | 79 possible (lecture du transcript) | 74-02 puis 74-08, régions disjointes | à relever sur la 79 avant 74-02 |
| `ui/77-vf-git-vue-detail.js` | 78 (livrée), 80 possible | 74-07, une ligne | suites du tiroir Git rejouées sans modification |
| `test-cockpit-chaine-xss.sh` | 79, 73, 75, 80 possibles | 74-09 | un renvoi vers la suite de bornes de la 74 |
| `CHANGELOG.md` et `README.md` du module | toutes | 74-09 (dernier) | insertion en fin de section § Non publié |
| `README.md`, `README.fr.md` racine (compteur de suites, gate `check-version-sync.sh`) | toutes celles qui ajoutent une suite | 74-09 | recompté au dernier commit ; à refaire à la jointure |
| `VERSION`, manifestes | toutes | aucun | aucun bump dans la 74 : un seul pour la vague, à la jointure |
| `viewer.html`, `serve.mjs`, `scan.mjs`, `plugin/cockpit/amont/`, `VENDORED.txt` | 79, 80 | aucun | la 74 ne touche aucun fichier du moteur (P74-D-31) |
| `ui/80-vf-fr.js`, `78/79-vf-fr-dict-*.js` | 79 | aucun | données marquées pour ne pas être traduites (P74-D-43) |
| `vf-cockpit-interface.json` | 79 | aucun | la 79 déclare `cockpit-frise@1` et l'extension `usage` (C6) |

### Ordre des vagues

1. 74-01 et 74-02 (exécutables sans la 79 ni la 73 : fonctions pures sur fixtures `cockpit-frise@1`, réducteur).
2. 74-03.
3. 74-04 et 74-05 — après les vagues de la 79 qui livrent C3, C4, A13, A30 et la coquille, et après la 73.
4. 74-06, 74-07, 74-08 — 74-08 après le merge de la 73 ; 74-06 après le routage d'onglet de la 80.
5. 74-09.

### Ce que la 74 attend d'une autre phase

- **79** : route `GET /api/vf/frise` → `cockpit-frise@1` (C3) ; événement `frise` et magasin `VF_ETAT` (C4), `VF_ETAT.jeton()`
  et `lireJson()` (A13) ; `VF_COQUILLE.surOnglet` (A30) et `chargerOnglet` (A2) ; aide de suites `socle-serveur.sh` (A6) ;
  contrat de forme étendu (C6) ; `rattachement.dag` = `signal.missions[].fichier` (A8) ; `rattachement.source: "enfants"`
  (A14).
- **73** : point de montage dans l'onglet Équipe, bascule « Régie · Frise » (posée par la 73 si elle la livre, sinon par
  74-04), table unique de glyphes, ouverture de la fiche depuis une ligne de régie, sort de la carte « Terminés » et du
  tiroir « Au travail ».
- **80** : pile `window.VF_SURCOUCHES` (Échap de la fiche), routage d'onglet pour « Voir sur la carte ».
- **78** (livrée) : module de détail du tiroir Git, auquel la 74 ajoute `ouvrir(sha)`.

### Ce que la 74 fournit

- Aux Phases 77 et 52 : les agrégats de coût (jetons, durées) par agent, mission, phase et étage, sur le calcul unique de
  l'index de la 79 ; la règle des étages (P74-D-42).
- À la Phase 75 : la mise en évidence ponctuelle « Voir sur la carte » (la continue reste à la 75).
- À la 73 : la fiche d'agent, ouverte par une fonction unique depuis la régie (`window.__vfFiche`).

## À verser par la jointure

- **Registre de l'audit** (`REGISTRE.md`), colonne état, à la livraison : AUDC-I04, I05, I06 (part ponctuelle ; la
  continue à la 75), I07 (jetons et durée ; devise et limites en réserve, voir ci-dessous), I08 (part 74 ; la synthèse à la
  77), I21 (part 74), I28, M4, D8 (lecteur), D9 (affichage par segments). Texte proposé pour I07 à la livraison :
  « fait en partie (<date>, <PR>) : jetons, durées et attente humaine par agent ; coût en devise et limites de 5 h et de
  7 jours en réserve avec AUDC-I35 (P74-D-20, P74-D-24) ».
- **Registre § 3 (retraits)** : ligne « La carte « Terminés depuis moins de 24 h » » — préciser « la carte seule ; le groupe
  repliable du tiroir « Au travail » reste (P69-D-18) ».
- **BACKLOG / réserve** : « Coût en devise au tarif public et limites d'abonnement de 5 h et de 7 jours (relais par la
  ligne d'état) — écartés de la Phase 74 (P74-D-20, P74-D-24), à décider par Samuel ».
- **Phase 52** (section ROADMAP, à son cadrage) : « Le calcul des jetons est celui de l'index de la Phase 79 (somme de
  `message.usage` dédoublonnée par identifiant de message) ; la 52 le réutilise au lieu d'en écrire un second
  (P74-D-22). »
- **ROADMAP** : ligne de checklist de la Phase 74 et table `## Progress` (« 0/9 plans, planifiée ») ; retrait des repères
  `vf-cadrage:phase-74` et de la ligne repère de la table Traceability.
- **Compteurs** : pied « Last updated » de `REQUIREMENTS.md` (TEMP-01..12 posées au cadrage, 2026-11-11).

## Limites

- Les plans 74-04 à 74-09 sont « à revalider » sur les livraisons des Phases 79, 73 et 80 : leurs fichiers de la 73 et de
  la 80 n'existaient pas à l'écriture.
- Les numéros de ligne cités par les plans valent pour la base `f763b556` ; les vagues de la 79 et de la 73 les déplaceront.
- Contrôle E4 du gate de sortie : en manque ou indéterminé, attendu (plans non exécutés, STATE non marqué).
- Le snapshot de budget de début de mission (`--budget-snapshot`) est un fichier unique du dépôt commun, partagé par les
  sept missions : il a pu être réécrit par une autre.

## Coût

Agents dispatchés (comptés sur les mandats émis) : 1 `vf-crafter` (5 passes par reprise), 2 `vf-design-judge`,
1 `gsd-phase-researcher`, 1 `vf-coder` (planification + 4 corrections ciblées par reprise), 1 vérificateur
(`general-purpose`, deux mandats : cadrage, puis plans), 1 `gsd-plan-checker`. Dispatches refusés par le plafond de la
session : 5 au premier tour, puis 4 sur la vérification des plans. Jetons relevés sur les blocs reçus (verbatim, `subagent_tokens`) : crafter 174 473, 200 836,
242 137, 253 239, 270 940, 273 566 ; juges 87 670 et 110 042 ; recherche 354 377 ; planification 360 383, 367 387, 407 114,
413 877 ; vérificateur 177 659 puis 322 178 ; vérificateur de plans 101 467.

## Preuves E6

- Périmètre d'écriture : `git -C <worktree> diff --name-only origin/integration/cockpit-audit` → ROADMAP.md,
  REQUIREMENTS.md, le dossier de phase, ce rapport (vérificateur frais, contrôle A1 à A3 `passed`).
- STATE : `git -C <worktree> diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md`
  → rc 0, relevé avant chaque commit.
- Critique d'interface : premier juge `gaps_found` 74/100 (6 majeurs), second juge frais `passed` 82/100 (0 majeur, 13
  mineurs appliqués).
- Vérification du cadrage : `gaps_found` (F1 à F6, mineurs), corrigés au commit `98c57d10`.
- Vérification des plans : premier passage (vérificateur frais du cadrage, repris en second mandat faute de place pour
  le vérificateur dédié) `gaps_found`, 4 bloquants (B1 74-08, B2 74-03, B3 74-07, B4 74-04/05) et 10 avertissements,
  corrigés au commit `d8bbf0da` ; second passage par un `gsd-plan-checker` frais : **PASS**, 0 bloquant, 3 avertissements
  (W1 à W3) corrigés au commit final de la mission. Le dernier passage (W1 à W3, et le retrait par le manager d'un chemin
  fictif du frontmatter de 74-08) n'a pas été rejugé.
- Gate de sortie : voir § Gate de sortie.
