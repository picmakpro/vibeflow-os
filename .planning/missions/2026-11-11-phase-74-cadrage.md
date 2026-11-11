# Mission — Phase 74 « L'équipe dans le temps », cadrage et plans (2026-11-11)

**Manager :** `vf-dev-manager`, dispatché par la session principale (vague des sept cadrages parallèles de l'audit du
cockpit, demande de Samuel, session principale Claude Code, 2026-11-11), puis repris le même jour (mandat de reprise de
la session principale : arbitrage de Samuel sur la couleur, contrôles à rattraper, revalidation sur les phases voisines).
**Branche :** `feat/phase-74-equipe-dans-le-temps`, base `origin/integration/cockpit-audit` (`f763b556`), worktree
`.claude/worktrees/phase-74`. Verrou de phase `--ws fiabilite --phase 74`.
**Mode :** autonome, design `force`. Aucune exécution, aucun fichier de code, aucune suite du cockpit.

## Résultat

- Cadrage : `74-CONTEXT.md`, P74-D-01 à P74-D-56. Un arbitrage de Samuel, P74-D-46 (AskUserQuestion session principale,
  2026-11-11 : « Suivre la règle de design (Recommandé) »). Toutes les autres décisions sont déléguées par Samuel
  (message session principale, 2026-11-08), option recommandée. Section « À Samuel » au format C76-Q1 de la Phase 76 :
  P74-Q-01 tranchée, P74-Q-02 à Q-05 appliquées, aucune ne bloque un plan.
- Exigences : famille `TEMP`, TEMP-01 à TEMP-12 (préfixe vérifié libre le 2026-11-11).
- Spécification d'interface : `74-UI-SPEC.md`, critiquée par quatre juges frais (voir § Preuves E6).
- Recherche : `74-RESEARCH.md` ; trois panels de reprise (fil réduit, relecture au curseur, Dépôt).
- Plans : dix (74-01 à 74-10), six vagues ; la phase s'exécute sur une base où la Phase 79 est fusionnée en entier
  (P74-D-56).
- Corps de la section `### Phase 74:` du ROADMAP réécrit (titre, checklist, `## Progress` intacts).
- PR : #228 vers `integration/cockpit-audit`, ouverte, non mergée (publications gelées).

## Plan de bataille (DAG)

Scratchpad `phase-74/MISSION-74.dag.json`. Premier passage : éclaireurs et panels (non lancés, plafond de sous-agents de la
session), cadrage par le manager, exigences et ROADMAP, craft et critique de la spécification, recherche, plans,
vérifications fraîches, PR. Reprise : arbitrage de Samuel consigné ; trois panels (fil, relecture, Dépôt) ; revalidation
contre les Phases 79, 73, 80 ; trois correcteurs de plans en parallèle par lots disjoints (01/06 ; 02/03/05 ;
04/07/08/09/10), plus le crafter ; vérifications fraîches de chaque retouche (plans, interface, cadrage).

Écarts et incidents :
- Premier passage : panels et éclaireurs non lancés (plafond de 20 sous-agents simultanés de la session atteint par la
  vague) ; compensés par des juges frais. Plafond porté à 100 à la reprise (demande de Samuel, session principale,
  2026-11-11) ; les panels ont alors tourné.
- Coupure de la session (quota d'API du compte, HTTP 429) vers 15 h 33 : quatre workers arrêtés net, aucune correction de
  plan écrite ; repris par message avec leur contexte après changement de compte, rien perdu sur disque.
- Les contrats des Phases 79, 73, 75 et 80 ont été amendés une quinzaine de fois pendant la mission ; chaque amendement a
  été porté dans le registre et relayé aux workers en cours.

## Décisions

Registre complet : `74-CONTEXT.md`. Les plus engageantes :

- P74-D-01 et P74-D-46 : la frise est bâtie sur `DESIGN.md` § 9 — le nœud s'écrit sur la voie, la couleur reste aux
  états — confirmé par Samuel (arbitrage du 2026-11-11).
- P74-D-20, D-24 : coût en jetons et en durée seulement, ni montant en devise ni limites de 5 h et de 7 jours.
- P74-D-22 : un seul calcul de jetons, celui de l'index de la Phase 79 ; la Phase 52 le réutilise.
- P74-D-47 : la Phase 75 pose le canal de marquage ; « Voir sur la carte » passe par `showBoard` à titre provisoire, et
  74-06 écrit le contrat de branchement (la 75 l'a adopté tel quel).
- P74-D-48 : le réducteur de transcript ne gagne que `echec` ; compactions et messages de l'humain fusionnés côté page.
- P74-D-49 : relecture au curseur ± δ, filtrée par la dernière écriture de chaque cible, lectures bornées et liste
  partielle.
- P74-D-50 : Dépôt « peut-être incomplet » par la frontière des parents non lus, ligne « Autres commits ».
- P74-D-51 : la frise est une vue de la régie (bascule de la 73) ; la fiche s'ouvre en annulant `vf-agent:ouvrir`.
- P74-D-53 : Échap lu sur `defaultPrevented` en remontée ; commit ouvert par `VFGitTiroir.ouvrirSur` ; retrait du lecteur
  de repli de la 73 par 74-10 (P73-C2).
- P74-D-54 : rouge intermédiaire des suites de la 73 entre 74-05 et 74-10, nommé et jamais poussé.
- P74-D-55 : aller-retour d'onglet — seules la fenêtre et la lecture de la frise survivent (`sessionStorage`).
- P74-D-56 : la 74 part après la Phase 79 entière (22 plans).

Gray areas jugées assez couvertes sans panel de reprise : la place de la fiche et de la frise (P74-D-02, D-03), tranchée
ensuite par les contrats de la 73 et de la 80 et jugée par quatre critiques d'interface ; l'unité du coût (P74-D-20,
D-24), qui suit le texte du but arbitré et la règle « jamais estimé » de la Phase 52, et reste visible à Samuel
(P74-Q-02, Q-03) ; les étages (P74-D-42), règle simple et mesurable ; le calcul partagé (P74-D-22), confirmé par la 79.

## À Samuel (non bloquant)

`74-CONTEXT.md` § « À Samuel », format C76-Q1 : P74-Q-01 couleur (tranchée), P74-Q-02 devise, P74-Q-03 limites de 5 h et
de 7 jours, P74-Q-04 relecture par dérivation, P74-Q-05 genre `silence` (appliquées sous délégation, contestables).

## Carte des fichiers

### Par plan (chemins sous `plugin/cockpit/` sauf mention ; chaque plan écrit aussi sa trace rouge dans le dossier de phase)

| Plan | Vague | Dépend de | Fichiers créés ou modifiés |
|---|---|---|---|
| 74-01 | 1 | — | `ui/74-vf-frise-calculs.js`, `ui/74-vf-frise-modele.js`, `scripts/tests/test-cockpit-frise-modele.sh`, `scripts/tests/frise-fabrique.mjs` |
| 74-02 | 1 | — | `scripts/vf-cockpit-transcript.mjs`, `scripts/tests/test-cockpit-transcript.sh` |
| 74-03 | 2 | 74-02 | `ui/74-vf-fiche-md.js`, `ui/74-vf-fiche-texte.js`, `scripts/tests/test-cockpit-fiche-texte.sh` |
| 74-04 | 3 | 74-01 | `ui/74-vf-frise.js`, `ui/74-vf-frise-colonne.js`, `ui/74-vf-frise-pistes.js`, `ui/74-vf-frise-source.js`, `ui/74-vf-frise-style.js`, `scripts/tests/test-cockpit-frise-vue.sh`, `scripts/tests/chrome-frise.mjs` |
| 74-05 | 3 | 74-01, 74-03 | `ui/74-vf-fiche-faits.js`, `ui/74-vf-fiche-style.js`, `ui/74-vf-fiche.js`, `scripts/tests/test-cockpit-fiche.sh`, `scripts/tests/chrome-fiche.mjs`, liste `74-05-ROUGES-73.txt` (dossier de phase) |
| 74-06 | 4 | 74-04 | `ui/74-vf-frise-curseur.js`, `ui/74-vf-frise-encart.js`, `ui/74-vf-frise-fichiers.js`, `ui/74-vf-frise-carte.js`, `scripts/tests/test-cockpit-frise-curseur.sh` |
| 74-07 | 4 | 74-04 | `ui/74-vf-frise-depot.js`, `ui/74-vf-cout.js`, `ui/74-vf-cout-tableau.js`, `scripts/tests/test-cockpit-frise-cout.sh` |
| 74-08 | 4 | 74-04, 74-05 | `scripts/tests/test-cockpit-equipe-retraits.sh`, `scripts/tests/test-cockpit-equipe.sh`, `scripts/tests/test-cockpit-transcript.sh`, `scripts/tests/chrome-equipe-clavier.mjs` |
| 74-10 | 5 | 74-05, 74-08 | `ui/72-vf-regie-source.js` (retrait d'`ouvrirRepli`), `ui/71-vf-equipe-rendu.js` (retrait de l'export `transcript`), `scripts/tests/regie-rg-page.sh` (trois clauses sans objet), `scripts/tests/test-cockpit-repli-retrait.sh`, `scripts/tests/test-cockpit-equipe-retraits.sh`, `scripts/tests/test-cockpit-equipe.sh`, `scripts/tests/test-cockpit-transcript.sh` |
| 74-09 | 6 | 74-04 à 74-08, 74-10 | `scripts/tests/test-cockpit-frise-bornes.sh`, `scripts/tests/test-cockpit-chaine-xss.sh`, `skills/cockpit-moteur/VENDORED.txt` (lignes AJOUT), `README.md` et `CHANGELOG.md` du module, `README.md` et `README.fr.md` à la racine (compteur de suites) |

(`ui/…` = `skills/cockpit-moteur/assets/ui/…`.) Dix-neuf modules neufs `ui/74-vf-*.js`, aucun fichier du moteur hors des
lignes AJOUT de `VENDORED.txt`, aucun bump de version.

### Fichiers partagés avec d'autres phases (en tête)

| Fichier | Autres phases | Plan de la 74 | Règle |
|---|---|---|---|
| `scripts/vf-cockpit-transcript.mjs` | 79 (79-13 : `reduireCible`) | 74-02 | après la 79 entière (P74-D-56) |
| `scripts/tests/test-cockpit-transcript.sh` | 79 (79-13, 79-22), 73 | 74-02, 74-08, 74-10 | régions disjointes, la 74 part après la 79 entière |
| `ui/72-vf-regie-source.js`, `ui/71-vf-equipe-rendu.js`, `scripts/tests/regie-rg-page.sh` | 73 | 74-10 seul | retrait seulement, P73-C2 (seule exception à P73-D-20), après la preuve de l'annulation des trois déclencheurs |
| `scripts/tests/test-cockpit-equipe.sh`, `scripts/tests/chrome-equipe-clavier.mjs` | 73 | 74-08, 74-10 | après la 73 ; rouge intermédiaire des suites `regie-rg-*` entre 74-05 et 74-10, jamais poussé (P74-D-54) |
| `skills/cockpit-moteur/VENDORED.txt` | 73 (73-04, 73-05), 80 (16 plans) | 74-09 seul | lignes AJOUT à leur place alphabétique (A52 de la 79), deux champs |
| `CHANGELOG.md` et `README.md` du module | toutes | 74-09 (dernier) | insertion en fin de section § Non publié |
| `README.md`, `README.fr.md` racine (compteur de suites) | toutes celles qui ajoutent une suite | 74-09 | mesuré par `find` au dernier commit ; à refaire à la jointure |
| `ui/74-vf-frise-carte.js` | 75 (75-07 rebranche « Voir sur la carte » sur son canal) | 74-06 | contrat figé dans 74-06 ; la 75 touche `voirSurLaCarte` et `finirRelecture` |
| `VERSION`, manifestes | toutes | aucun | aucun bump dans la 74 |
| `viewer.html`, `serve.mjs`, `scan.mjs`, `ui/70-vf-live.js`, `ui/77-vf-git-*.js`, `ui/80-vf-fr.js` | 79, 80, 78 | aucun | la 74 n'y touche pas (P74-D-31, D-50, D-53) |

### Ordre des vagues

Précondition de toute la phase : la Phase 79 fusionnée en entier (79-01 à 79-22), la 73 et la 80 aux plans cités par
chaque plan. Puis : 1 (74-01, 74-02) → 2 (74-03) → 3 (74-04, 74-05) → 4 (74-06, 74-07, 74-08) → 5 (74-10) → 6 (74-09).
Aucune poussée vers la PR entre 74-05 et 74-10.

### Ce que la 74 attend d'une autre phase

- **79** : 79-13 (route de frise `cockpit-frise@1`, `reduireCible`), 79-22 (`/api/vf/transcript` par la table en mémoire,
  `vf-cockpit-agents-table.mjs`), 79-16 (`surOnglet(rappel, { cle })`, A51 ; coquille, `/_vf/`), 79-17 (`VF_ETAT`), 79-02
  et 79-06 (`cockpit_module_copie`, `COCKPIT_MODULE`), 79-08 (`claudeCode.index`), 79-09 (`registry`) ; A43 à A53.
- **73** : `__vfEquipeVues.declarer`, `section#vf-equipe`, bascule `tablist` « Vue de l'équipe », `GLYPHE_ETAT`,
  `vf-agent:ouvrir` (`nom`, `ancre`, `rapport`) et `vf-agent:lu`, P73-C1 à C5.
- **80** : `VFGitTiroir.ouvrirSur` (80-06, commit `42664afc`), `VF_ONGLETS.aller` (80-10), contrat d'Échap des vues
  d'Équipe (`95ab6578`), P80-D-59 et D-60 (`ecc855b4`).
- **75** : 75-07 rebranche « Voir sur la carte » sur `VF_MARQUES.poser('relecture', VF_MARQUES.tableRelecture(fichiers),
  { exclusif: true })` et `retirer('relecture')`.

### Ce que la 74 fournit

- À la 75 : `window.__vfFrise.voirSurLaCarte(fichiers, titre)` et `finirRelecture()`, entrées `{ arbre, cible }` (74-06).
- À la 73 : la fiche d'agent ouverte par l'annulation de `vf-agent:ouvrir`, `vf-agent:lu` émis par la 74, et le retrait
  du lecteur de repli (74-10).
- Aux Phases 77 et 52 : les agrégats de coût par agent, mission, phase et étage, sur le calcul unique de la 79.

## À verser par la jointure

- **Registre de l'audit** (`REGISTRE.md`), colonne état, à la livraison : AUDC-I04, I05, I06 (part ponctuelle ; la
  continue à la 75), I07 (jetons et durée ; devise et limites en réserve), I08 (part 74 ; la synthèse à la 77), I21
  (part 74), I28, M4, D8 (lecteur), D9 (affichage par segments). Texte proposé pour I07 : « fait en partie (<date>,
  <PR>) : jetons, durées et attente humaine par agent ; coût en devise et limites de 5 h et de 7 jours en réserve avec
  AUDC-I35 (P74-D-20, P74-D-24) ».
- **Registre § 3 (retraits)** : ligne « La carte « Terminés depuis moins de 24 h » » — « la carte du canevas, si elle
  existe encore ; le pli du tiroir « Au travail » est retiré par la Phase 73 (P73-D-14) ».
- **BACKLOG / réserve** : « Coût en devise au tarif public et limites d'abonnement de 5 h et de 7 jours (relais par la
  ligne d'état) — écartés de la Phase 74 (P74-D-20, P74-D-24 ; questions P74-Q-02, P74-Q-03) ».
- **Phase 52** (section ROADMAP, à son cadrage) : « Le calcul des jetons est celui de l'index de la Phase 79 (somme de
  `message.usage` dédoublonnée par identifiant de message) ; la 52 le réutilise au lieu d'en écrire un second
  (P74-D-22). »
- **ROADMAP** : ligne de checklist de la Phase 74 et table `## Progress` (« 0/10 plans, planifiée ») ; retrait des
  repères `vf-cadrage:phase-74` et de la ligne repère de la table Traceability.
- **Compteurs** : pied « Last updated » de `REQUIREMENTS.md` (TEMP-01..12 posées au cadrage, 2026-11-11).

## Limites

- Les plans portent « à revalider » sur ce qui dépend d'un livrable des Phases 79, 73 et 80 non encore écrit (forme exacte
  du corps `inconnu`, noms de libellés des suites `regie-rg-*`, forme réelle de M-LU-SI-ANNULE, etc.) ; chaque plan dit
  quoi relever.
- Les numéros de ligne cités par les plans valent pour la base `f763b556` ; les phases voisines les déplaceront.
- Le rouge « sur le code actuel » de chaque témoin est affirmé par construction ; il est mesuré par la tâche 1 de chaque
  plan à l'exécution.
- Contrôle E4 du gate de sortie : en manque ou indéterminé, attendu (plans non exécutés, STATE non marqué).
- Le snapshot de budget de début de mission (`--budget-snapshot`) est un fichier unique du dépôt commun, partagé par les
  sept missions : il a pu être réécrit par une autre.

## Coût

Agents dispatchés (comptés sur les mandats émis), premier passage : 1 `vf-crafter`, 2 `vf-design-judge`,
1 `gsd-phase-researcher`, 1 `vf-coder` (planification puis corrections), 1 `general-purpose` (vérification du cadrage,
puis des plans), 1 `gsd-plan-checker`. Reprise : 3 `gsd-advisor-researcher` (panels), 3 `gsd-plan-checker`, 2
`vf-design-judge`, 1 `general-purpose` (cadrage), 4 `vf-coder` (un contrat 74-06, trois correcteurs repris sur trois
tours), le `vf-crafter` repris. Dispatches refusés par le plafond : 5 au premier tour, 4 sur la vérification des plans ;
aucun à la reprise. Arrêt par quota : 4 workers, repris par message.

Jetons relevés sur les blocs reçus (verbatim, `subagent_tokens`), premier passage : crafter 174 473, 200 836, 242 137,
253 239, 270 940, 273 566 ; juges 87 670 et 110 042 ; recherche 354 377 ; planification 360 383, 367 387, 407 114,
413 877 ; vérificateur 177 659 puis 322 178 ; vérificateur de plans 101 467. Reprise : vérification ciblée 77 703 ;
panels 131 487, 149 970, 131 094 ; revalidation 270 056 ; contrat 74-06 160 524 ; crafter 130 808, 134 780, 171 428 ;
juges 118 986 ; vérificateur du cadrage 166 343 ; vérificateur des plans 198 155 ; correcteurs 251 276, 281 712 (01/06),
299 027, 341 383 (02/03/05), 349 143, 402 412 (04/07/08/09/10).

## Preuves E6

```json
{
  "preuves": [
    { "verdict": "gate:check-machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "83d39524" },
    { "verdict": "gate:state-inchange", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "83d39524" },
    { "verdict": "revue", "preuve": "amont" }
  ]
}
```

La ligne `revue` désigne les juges et vérificateurs frais de la mission, relayés sans commande rejouable :

- Périmètre d'écriture : `git diff --name-only origin/integration/cockpit-audit` → dossier de phase VFDO-74, ROADMAP.md,
  REQUIREMENTS.md, ce rapport ; ROADMAP dans le corps de `### Phase 74:` seul, REQUIREMENTS en insertions derrière les
  repères de la Phase 74 (vérificateur frais du cadrage, contrôle A `OK` à deux reprises).
- STATE : identique à la base, relevé avant chaque commit.
- Format C76-Q1 de « À Samuel » : 5 entrées, 0 défaut (lecteur indépendant, témoins positif et négatif).
- Arbitrage P74-D-46 : recoupé avec la question et la réponse de la session principale (2026-11-11).
- Spécification d'interface : quatre critiques fraîches — 74/100 `gaps_found` (6 majeurs), 82/100 `passed`, puis à la
  reprise 79/100 `gaps_found` (3 majeurs), 86/100 `passed` (0 majeur, 14 mineurs appliqués). Les deux avertissements
  restants (`surOnglet` sans `cle`, `python3 -I`) ont été appliqués par le manager après ce passage, sans nouveau jugement.
- Cadrage : vérificateur frais `gaps_found` (F1 à F6) au premier passage, corrigé ; vérificateur frais de reprise
  `gaps_found` (texte TEMP, ROADMAP, registre en retard), corrigé au commit `520a7c1c`.
- Plans : premier passage (4 bloquants, 10 avertissements, corrigés), `PASS` (3 avertissements, corrigés), puis à la
  reprise une revalidation contre les Phases 79, 73, 80 (9 bloquants, 11 avertissements), une vérification complète
  (1 bloquant P74-D-54 non porté, 6 avertissements), une vérification après correction (1 bloquant : vérification D-54
  sur des fragments ; 1 avertissement : colonnes en octets), enfin une vérification ciblée `PASS` à la tête `fd7347bb`
  (2 avertissements, 2 infos). Ses avertissements ont été appliqués ensuite : W-2 et I-a par le manager, W-1 par le
  correcteur de 74-05 (commit `83d39524`), avec un banc rejoué sous bash et zsh (11 cas), sans nouveau passage de
  vérificateur.
- Têtes des phases voisines contre lesquelles les plans ont été jugés au dernier passage : 79 `677d19fa`, 73 `7834c73c`,
  80 `a4709f6e` ; depuis, ces branches n'ont avancé que par des commits de documentation (ancêtres vérifiés). Les plans
  qui dépendent d'un livrable non écrit (lanceur `test-cockpit-regie.sh` de 73-01, forme du corps `inconnu` de 79-22,
  libellé du saut de Chrome) portent « à revalider » et disent quoi relever.
- Gate de sortie (`check-mission-exit.sh --ws fiabilite --phase 74 --step 74 --report <ce fichier>`) : INDÉTERMINÉ,
  attendu — E4 (plans non exécutés, STATE non marqué), E7 (snapshot de budget du dépôt commun réécrit par une autre
  mission). Aucun contrôle n'a été forcé au vert.

