# Mission — Phase 73 « Gouvernance au cockpit » : cadrage et plans (2026-11-11)

**Manager :** `vf-dev-manager`, mode autonome, design forcé. **Périmètre :** cadrage et planification seulement (aucune
exécution, aucun code, aucune suite lancée). **Base :** `origin/integration/cockpit-audit` = `f763b556` (release v2.77.0 +
lot 0 de l'audit + repères d'écriture). **Branche :** `feat/phase-73-gouvernance-regie`, worktree `.claude/worktrees/phase-73`.
**Verrou :** verrou de phase `--ws fiabilite --phase 73` (génération `DRIVER.lock.gen.1794393014.87366`), jamais le verrou
de compartiment. **Vague :** cadrée en même temps que les Phases 74, 75, 76, 77, 79 et 80.

## Verdict

**Plans écrits et vérifiés.** 11 plans en 8 vagues d'exécution (le onzième, 73-11, ajouté à la reprise : section
« Reprise du 2026-11-11 » plus bas) ; à l'origine 10 plans en 7 vagues (regroupées en trois temps : données pures, rendu,
retraits et témoins), famille d'exigences neuve `REGI` (17 exigences depuis la reprise), cadrage `73-CONTEXT.md` (décisions P73-D-01 à
P73-D-36), spec d'interface `73-UI-SPEC.md` passée à la critique (80/100 au second tour), vérification fraîche
indépendante `passed` (0 bloquant, 3 avertissements corrigés). Tous les plans sont marqués « à revalider » contre les
contrats des Phases 79 et 80 qu'ils lisent, chacun avec son repli sur la forme présente.

## Plan de bataille (DAG, tenu au scratchpad de la mission)

| Nœud | Porteur | Dépend de | Issue |
|---|---|---|---|
| scout-code | éclaireur (lecture seule) | — | fait : code présent de l'onglet Équipe, retraits, suites, accroches de la 74 |
| scout-sources | éclaireur | — | fait : sources de gouvernance (attentes, DAG, verrou, worktrees de la 78, watchdog, ailleurs, notifications) |
| scout-bornes | éclaireur | — | fait : arbitrages en vigueur (67-78, DESIGNS § 9, lot 0), famille `REGI` libre, repères |
| craft:regie | `vf-crafter` | — | fait en deux tours (correction ciblée après la critique) |
| panel-73 | 3 × `gsd-advisor-researcher` | les 3 éclaireurs | fait : « À vous » et impact ; architecture de la page ; état « relu », notifications, ailleurs |
| discuss-73 | le manager (Pattern F) | panel-73 | fait : CONTEXT, bloc REGI, corps du ROADMAP |
| critique:regie | `vf-design-judge` frais | craft, discuss | tour 1 : 69/100 → reopen du craft ; tour 2 (juge frais) : 80/100, passed |
| plan-73 | `vf-coder` → `gsd-plan-phase` | discuss, critique | fait : recherche, carte des motifs, 10 plans, checker interne 3 tours (1 bloquant → 0) |
| plancheck-73 | `gsd-plan-checker` frais | plan-73 | passed après complément C2/C3/C4 ; 3 avertissements corrigés par `vf-coder` (correction ciblée) |
| sortie-73 | le manager | plancheck-73 | ce rapport, PR |

Écart au DAG : `plan-73` a été lancé dès le commit de la spec corrigée, en parallèle du second tour de critique (le
CONTEXT fait foi en cas d'écart) ; son premier lancement a été refusé par le plafond de 20 sous-agents simultanés du
poste et repris quand des places se sont libérées. Pas de nœud `docs` : aucun des quatre déclencheurs (surface publique,
`[doc-drift]`, fin de jalon, nouveau module) ne tombe sur une mission de planification.

## Décisions

Registre complet : `.planning/workstreams/fiabilite/phases/VFDO-73-gouvernance-au-cockpit/73-CONTEXT.md`. Toutes les
décisions P73-D-xx sont des décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée.
Elles se bâtissent sur la direction « régie » retenue par Samuel le 2026-11-11 (registre § 5.1), qui amende P69-D-17.
Les plus structurantes :

- P73-D-02 : régie rendue côté page, fonction indépendante de la source (flux présent ou magasin `VF_ETAT` de la 79).
- P73-D-03 : `cockpit-equipe@1` gardé (nodes vide, meta conservée) pour la route C5 de la 79.
- P73-D-06/07 : « À vous » = sessions « vous attend » + phases en `human_needed` ; impact en aval sur les plans de mission
  publiés (A16 de la 79), « impact inconnu » sinon, jamais deviné.
- P73-D-08/09 : tenant du verrou par mission depuis la forme projetée A15 ; alerte du watchdog depuis `stale` et
  `progressAgeS`, fenêtre lue à une seule source.
- P73-D-14/15/16 : « lu » en stockage du navigateur par lab (24 h) ; titre « (N) vous attendent » par un compositeur
  unique ; « ailleurs sur ce poste » par sa propre route, le nom d'un autre lab ne vivant que dans la page servie.
- P73-D-20 : accroches de la 74 (registre de vues, bascule « Régie · Frise », événements `vf-agent:ouvrir` / `vf-agent:lu`).
- P73-D-23 : trois temps de vagues, fichiers partagés concentrés dans le dernier, joué après rebase.
- P73-D-28 à 35 : règles communes de la 79 (A10/A11, A13, A6, A15-A20, A30-A32) et de la 80 (pile de surcouches).
- P73-D-36 : pas d'extracteur des registres de décisions ; `vf-cockpit-registres.mjs` laissé à la Phase 76.

Coordination pendant la mission (relayée par la session principale) : six points envoyés à la Phase 79 le 2026-11-11,
tous retenus par son second amendement (`6f66d878`, A15 à A20) ; règles A30 (`74501bb0`) et A31/A32 (`e04c43e7`) ;
information de la Phase 80 (pile `VF_SURCOUCHES`, P80-D-33..41, SHA à vérifier) ; recoupement de la Phase 76 (P73-D-36).

## Questions à Samuel (non bloquantes ; l'arbitrage en vigueur tient)

Détail et options dans `73-CONTEXT.md` § « À Samuel », réécrite à la reprise au format C76-Q1 de la Phase 76 :
S-1 → P73-Q-01 (en attente, ne bloque rien), S-2 → P73-Q-02 (appliquée, P73-D-06), S-3 → P73-Q-03 (tranchée),
S-4 → P73-Q-04 (appliquée, P73-D-15).

- **S-1** Pastilles du tiroir Git de la Phase 78 sur fond d'avertissement, en tension avec Q9. Recommandation :
  les neutraliser dans un correctif du tiroir Git, hors de la 73.
- **S-2** Question de l'assistant en suspens lue au transcript : rouvrirait la décision D2 du lot 0. Recommandation :
  garder D2.
- **S-3** — **tranchée par Samuel** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11), autrement que
  la recommandation du manager : « Poser le format maintenant (Recommandé) ». Devient P73-Q-03 (« tranchée ») et
  P73-D-37 ; plan 73-11.
- **S-4** Notification du système : reportée. Recommandation : la reporter.

## Carte des fichiers

### Fichiers partagés avec d'autres phases (en tête)

| Fichier | Plans 73 (vague) | Partagé avec | Note |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-who.mjs` | 73-03 (2) | 79 (vagues 2 et 3) | champs facultatifs de `who@2` (A17 : ordre libre, fusion à la jointure) |
| `plugin/cockpit/scripts/vf-cockpit-live.mjs` | 73-03 (2) | 79 (A17, `whoSig`) | sans objet si A17 a fusionné avant ; témoin de jointure RG16.13 |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` | 73-03 (2), 73-08 (6) | 79 (A20 sur le bloc `who@2`), 74 | champs facultatifs, pas de bump |
| `plugin/cockpit/scripts/vf-cockpit-etat-officiel.mjs` | 73-02 (2) | 79 (vague 3, collecte) | fonction `ailleurs()` en fin de fichier (A18) |
| `plugin/cockpit/scripts/vf-cockpit-server.mjs` | 73-02 (2), 73-08 (6) | 79 (coquille C5, table des routes A10/A11) | route `ailleurs` ; `pageEquipe` sans cartes avant la coquille, constructeur de `?onglet=equipe` après |
| `plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs` | 73-08 (6) | 79 (C5) | réduit à la coquille et aux missions |
| `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | 73-04 (3), 73-05 (4), 73-06 (5) | 79 (C6 : réduit à l'origine) | lignes `AJOUT` à leur place dans le tri, ou rien après C6 |
| `ui/00-vibeflow.js` | 73-05 (4), 73-06 (5) | 80 (objet global gelé, clavier) | lignes existantes seulement, aucun ajout net (298/300) |
| `ui/70-vf-live.js` | 73-10 (7) | 80 (tiroirs) | lignes existantes seulement |
| `ui/71-vf-equipe-rendu.js` | 73-04 (3), 73-10 (7) | 74 | exports et pli des terminés |
| `ui/72-vf-equipe.js` | 73-08 (6) | 79 (coquille), 74 | canevas retiré |
| `ui/76-vf-git-entete.js` | 73-06 (5) | 78 (livrée), 80 | écrivain du titre remplacé par le compositeur |
| `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` | 73-08 (6), 73-10 (7) | 74, 79 (aide `socle-serveur.sh`, A6) | témoins re-pointés |
| `test-cockpit-lancer-suivi.sh`, `test-cockpit-who.sh`, `test-cockpit-equipe-etats.sh`, `test-cockpit-responsive.sh`, `test-cockpit-projet-visite.sh`, `test-cockpit-git-entete.sh`, `test-cockpit-accessibilite.sh`, `test-cockpit-transcript.sh`, `test-cockpit-moteur-carte.sh`, `test-cockpit-lancer-serveur.sh`, `chrome-equipe-clavier.mjs`, `chrome-moteur-carte.mjs`, `chrome-accessibilite.mjs` | 73-03, 73-08, 73-09, 73-10 | 79 (lanceur commun), 80 (clavier) | jamais supprimés pour verdir (LE → LR) |
| `README.md`, `README.fr.md` (compteur « 213 suites ») | 73-10 (7) | 74, 79, 80 | +1 suite (`test-cockpit-regie.sh`), recompté au rebase |
| `plugin/cockpit/CHANGELOG.md` § Non publié, `plugin/cockpit/README.md` | 73-10 (7) | 74, 79, 80 | une entrée en tête de section |
| Dictionnaire de traduction (`ui/78-`, `79-`, `80-vf-fr*`) | aucun | — | libellés neufs écrits en français ; inventaire FR vérifié par les gates de 73-04/73-06 |
| `viewer.html` et patchs du moteur | aucun | 79 (C6), 80 | jamais modifiés par la 73 (P73-D-24) |
| `plugin/cockpit/scripts/vf-cockpit-registres.mjs` | aucun | 76 | laissé à la 76 (P73-D-36) |

### Par plan (fichiers créés ou modifiés ; chaque plan ajoute aussi son `73-0N-RED-TRACE.md` dans le dossier de phase)

| Plan | Vague | Dépend de | Exigences | Fichiers |
|---|---|---|---|---|
| 73-01 Socle de la suite unique et module de gouvernance | 1 | — | REGI-04, 05, 07, 10, 16 | créés : `scripts/vf-cockpit-gouvernance.mjs`, `scripts/tests/test-cockpit-regie.sh`, `tests/regie-commun.sh`, `tests/regie-rg-gouvernance.sh` |
| 73-02 `ailleurs()` et `GET /api/vf/ailleurs` | 2 | 01 | REGI-13 | `vf-cockpit-etat-officiel.mjs`, `vf-cockpit-server.mjs` ; créé `tests/regie-rg-ailleurs.sh` |
| 73-03 Champs de gouvernance de `who@2`, LR.1-6 | 2 | 01 | REGI-04, 05, 06, 07, 09, 10, 16 | `vf-cockpit-who.mjs`, `vf-cockpit-live.mjs`, `vf-cockpit-interface.json`, `tests/test-cockpit-lancer-suivi.sh` ; créé `tests/regie-rg-collecte.sh` |
| 73-04 Modèle de la régie (sans DOM), feuille | 3 | 03 | REGI-01, 02, 04-07, 09-11, 14 | créés `ui/72-vf-regie-modele.js`, `ui/72-vf-regie-style.js`, `tests/vm-regie.mjs`, `tests/regie-rg-modele.sh` ; modifiés `ui/71-vf-equipe-rendu.js`, `VENDORED.txt` |
| 73-05 Page de la régie, accroches de la 74 | 4 | 04 | REGI-01-03, 06, 09, 11, 14-16 | créés `ui/72-vf-regie-source.js`, `ui/72-vf-regie-rendu.js`, `ui/72-vf-regie-pied.js`, `tests/vm-dom.mjs`, `tests/vm-regie-page.mjs`, `tests/regie-page-commun.sh`, `tests/chrome-regie.mjs`, `tests/regie-rg-page.sh` ; modifiés `ui/00-vibeflow.js`, `VENDORED.txt` |
| 73-06 Compositeur du titre, favicon, « lu » | 5 | 05 | REGI-11, 12 | créés `ui/90-vf-titre.js`, `tests/chrome-regie-titre.mjs`, `tests/regie-rg-titre.sh` ; modifiés `VENDORED.txt`, `ui/00-vibeflow.js`, `ui/76-vf-git-entete.js` |
| 73-07 Pied : arbres de travail, ailleurs, non-fuite | 5 | 05, 02 | REGI-08, 13, 14, 16 | `ui/72-vf-regie-pied.js` ; créés `tests/chrome-regie-pied.mjs`, `tests/chrome-regie-fuite.mjs`, `tests/regie-rg-pied.sh` |
| 73-08 Retrait du canevas d'Équipe | 6 | 06, 07 | REGI-03, 14, 16 | `vf-cockpit-server.mjs`, `vf-cockpit-equipe-carte.mjs`, `ui/72-vf-equipe.js`, `vf-cockpit-interface.json`, `tests/test-cockpit-equipe.sh`, `tests/chrome-equipe-clavier.mjs`, `tests/chrome-moteur-carte.mjs`, `tests/test-cockpit-moteur-carte.sh`, `tests/test-cockpit-lancer-serveur.sh` ; créé `tests/regie-rg-retrait.sh` |
| 73-09 LE → LR, témoins re-pointés | 6 | 06, 07 | REGI-01, 12, 14, 16 | `tests/test-cockpit-lancer-suivi.sh`, `test-cockpit-who.sh`, `test-cockpit-equipe-etats.sh`, `test-cockpit-responsive.sh`, `test-cockpit-projet-visite.sh`, `test-cockpit-git-entete.sh`, `test-cockpit-accessibilite.sh`, `chrome-accessibilite.mjs` |
| 73-10 Tiroir hors d'Équipe, README, CHANGELOG, toutes les suites | 7 | 08, 09 | REGI-11, 15, 16 | `ui/70-vf-live.js`, `ui/71-vf-equipe-rendu.js`, `tests/test-cockpit-equipe.sh`, `tests/test-cockpit-transcript.sh`, `README.md`, `README.fr.md`, `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md` ; créé `tests/regie-rg-tiroir.sh` (73-02 porte aussi `tests/test-cockpit-routes.sh`, A54 de la 79) |
| 73-11 Questions en attente des cadrages, décisions prises pour vous | 8 | 04, 05, 06, 10 | REGI-17, 01, 12, 14, 16 | créés `ui/72-vf-regie-questions-lecture.js`, `ui/72-vf-regie-questions-source.js`, `ui/72-vf-regie-questions-rendu.js`, `tests/vm-regie-questions.mjs`, `tests/chrome-regie-questions.mjs`, `tests/regie-rg-questions.sh` ; modifiés `ui/72-vf-regie-modele.js`, `ui/72-vf-regie-rendu.js`, `ui/72-vf-regie-source.js`, `ui/90-vf-titre.js`, `VENDORED.txt`, `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md`, `73-UI-SPEC.md` § 18 |

(Chemins relatifs à `plugin/cockpit/` pour `scripts/`, `tests/` = `plugin/cockpit/scripts/tests/`, `ui/` =
`plugin/cockpit/skills/cockpit-moteur/assets/ui/`.)

### Ordre des vagues et contrats entre phases

- **Ordre :** 1 (73-01) → 2 (73-02, 73-03) → 3 (73-04) → 4 (73-05) → 5 (73-06, 73-07) → 6 (73-08, 73-09) → 7 (73-10)
  → 8 (73-11). La 73 s'exécute avant la 76 ; 73-11 pose l'emplacement des questions, que 76-09 remplit.
  Les vagues 6 et 7 concentrent les fichiers partagés et se jouent après rebase sur la 79 ou la 80, selon celle qui
  fusionne la première.
- **Ce que la 73 attend :**
  - de la 79 : A15 (verrous projetés), A16 (résumé de plan publié, champ `dag`), A17 (signature de `who`), A18, A20
    (`sortisSilence`, `finMotif`), C4/C5 (`VF_ETAT`, coquille, `?onglet=equipe`), A10/A11 (table des routes, accès
    unique), A13, A6 (`socle-serveur.sh`), A30 (`VF_COQUILLE.surOnglet`), A31/A32 (`instantane`). Aucun n'est
    bloquant : chaque plan dit son repli sur la forme présente.
  - de la 80 : `VF_SURCOUCHES` pour le repli du lecteur ; objet global gelé respecté.
- **Ce que la 73 fournit :**
  - à la 74 : `section#vf-equipe`, `window.__vfEquipeVues.declarer(...)`, bascule « Régie · Frise » dessinée dès deux
    vues (P74-D-02), événements `vf-agent:ouvrir` (annulable) et `vf-agent:lu`, attributs `data-vf-agent` /
    `data-vf-noeud` / `data-vf-etat`, ancres `#r=` traitées par la régie, retrait de la carte « Terminés depuis moins
    de 24 h » ;
  - à la 74, depuis la reprise : contrats P73-C1 à C5 du CONTEXT (déclencheurs annulables `nom`, `ancre`, `rapport` ;
    retrait par la 74 de `ouvrirRepli` et de l'export `transcript`, témoins verts après retrait nommés ; émission de
    `vf-agent:lu` par qui ouvre ; bascule `role="tablist"` « Vue de l'équipe », position en `sessionStorage`) ;
  - à la 76 : l'affichage de `meta.vf.questions` (C76-Q2) dans « À vous » et en liste « Décisions prises pour vous,
    contestables (N) » ; la section « À Samuel » de la 73 au format C76-Q1, premier cas réel de sa lecture ;
  - à la 79 : les champs facultatifs de `who@2` (A32) ;
  - à la 81 : la régie comme surface où poseront « Répondre » et l'arrêt d'un orphelin.

## Reprise du 2026-11-11 (après-midi)

Mandat de reprise relayé par la session principale : Samuel a tranché S-3 autrement que la recommandation du manager
(arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 : « Poser le format maintenant (Recommandé) »), d'où
un plan de plus et la revalidation des dix plans contre les contrats voisins qui avaient bougé. Verrou de phase repris
(génération `DRIVER.lock.gen.1794406296.65763`). Une coupure de la session (quota du compte, HTTP 429, vers 15 h 33) a
arrêté net le manager et son worker : retouches non commitées relues et gardées (commit `153f77e7`), entrée du registre
fermée en `stopped`, reprise par deux workers neufs en parallèle (plafond de sous-agents relevé à 100 par Samuel).

- **Décisions ajoutées** : P73-D-37 (S-3, troisième source de « À vous ») ; P73-D-38 (compositeur du titre sans
  observateur, aucune baseline d'observateurs à relever) ; P73-D-39 à P73-D-42 (questions sur Équipe avant la coquille,
  module de lecture à part, tri dans un rang, libellés). Section « À Samuel » réécrite au format C76-Q1 (P73-Q-01 en
  attente, P73-Q-02 et 04 appliquées, P73-Q-03 tranchée). Contrats fournis à la 74 (P73-C1 à C5). REGI-17.
- **Plan 73-11** (vague 8) : questions en attente lues dans `meta.vf.questions` (contrat de la 76), « Décisions prises
  pour vous, contestables (N) » à part et jamais comptées, emplacement qui dit « pas encore livrée » tant que 76-09 n'est
  pas exécuté ; 36 mutants nommés.
- **Revalidation** : 73-01 à 73-10 contre 79@5eaa6c41 et 80@0f042552 ; 73-11 contre 76@98708342, 79@5eaa6c41,
  80@0f042552. Chaque dépendance cite le plan de la 79 qui la livre (dont 79-09, 79-16, 79-17, 79-22).
  Changements de fond : A54 (route `ailleurs` + `test-cockpit-routes.sh`, RK.1/RK.7) dans 73-02 ; Échap de la régie sur
  `defaultPrevented`, écoute en remontée, RG15.9 à trois cas ; montage par `surOnglet(…, { cle })`, RG15.10 (réexécution,
  aucune référence conservée) ; RG1.12 (fragment lu après `pushState`) ; fenêtre rouge 73-05 → 73-08/09/10 déclarée,
  L3 traité dans 73-08.
- **Vérifications fraîches de la reprise** : revalidation `ac173592` passed (1 avertissement, L3, fermé) ; delta
  73-01..10 : 3 bloquants (têtes de revalidation, A54, mutants d'Échap incapables de rougir) → corrigés en `a73960a0` ;
  73-11 : 1 bloquant (tri contraire à P73-D-41) → corrigé en `9982d088` ; contrôle final scopé au diff de ces deux
  corrections : voir Preuves E6.

## À verser par la jointure (texte exact à poser ; la mission n'a pas touché ces fichiers)

1. `.planning/workstreams/fiabilite/ROADMAP.md`, ligne de checklist de la Phase 73 (ligne ~127) : ajouter à la fin
   « — cadrée et planifiée le 2026-11-11 (11 plans, REGI-01..17) ». Table `## Progress` : Phase 73 → `0/11 | Planned`.
2. `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`, colonne d'état des lignes `AUDC-I01`, `I02`, `I03`,
   `I09`, `I10`, `I21`, `I34`, `I38`, `D4`, `M3`, `F2` : « planifié — Phase 73 (73-01..73-11) » ; pour `AUDC-I09` :
   « planifié en partie — Phase 73 (titre et pastille) ; notification du système reportée ».
3. `.planning/workstreams/fiabilite/BACKLOG.md`, deux sujets :
   - « Notification du système pour le cockpit (AUDC-I09, part reportée par P73-D-15) : en option éteinte par défaut,
     trois motifs, texte borné au motif et au nombre ; examen des bornes à faire (texte hors de la page). »
   - « Pastilles « modifiés » du tiroir Git sur fond d'avertissement, en tension avec Q9 (S-1 de la Phase 73). »
4. `.planning/workstreams/fiabilite/STATE.md` : aucune écriture par la mission ; la jointure marque la Phase 73
   « planifiée, 11 plans » à sa convenance.
5. Plus de question ouverte vers la 79 : `priseS` est résolu par A36/A39 (`leaseS`, `ageS`), repris dans 73-04.

## Limites

- Le gate de sortie dira son contrôle E4 en manque ou indéterminé : plans non exécutés, STATE non marqué. C'est attendu
  pour une mission de planification ; non verdi. Mesuré avant la relâche du verrou : E4 « étape 73 : 10 case(s) de plan
  non cochée(s) » ; E1 lit le registre du compartiment, où des agents des six autres missions de la vague sont encore
  en cours (le registre de la phase 73 est à 0 orphelin) ; E7 : le snapshot de budget, partagé par le répertoire git
  commun, est sans identité de mission.
- Les contrats de la 79 et de la 80 sont lus sur des branches non fusionnées ; tous les plans sont marqués « à
  revalider ». La 80 n'a pas encore poussé le commit de P80-D-33..41 au moment du cadrage.
- La forme réelle de `claude agents --json` n'est pas sondée par un plan : couverte par le contrat de forme du lot 0
  (AUDC-Q4), la sonde sur poste vivant reste dans les vérifications manuelles de `73-VALIDATION.md`.
- Les témoins de navigateur qui lisent le canevas d'Équipe rougissent entre 73-05 et 73-08/09 (liste dans 73-05) ;
  hors CI sans Chrome, une preuve navigateur sort « NON VÉRIFIÉ », jamais verte.
- Le registre des agents du verrou de phase a reçu trois entrées malformées au premier enregistrement (identifiant
  collé au nœud, nœud vide : découpage de mots sous zsh) ; fermées en `failed` et réenregistrées aussitôt.
- Le plafond de 20 sous-agents simultanés du poste a refusé trois lancements (le craft deux fois, la planification
  une fois) ; reprises après libération, sans perte.
- Les commandes du moteur GSD n'ont pas d'option de répertoire : elles ont tourné en `cd <worktree> && …` dans une seule
  ligne ; tout git en `git -C`.

## Décompte de mission

Agents dispatchés : 11 distincts — 3 éclaireurs, 1 `vf-crafter` (2 tours), 3 `gsd-advisor-researcher`, 2
`vf-design-judge` (frais à chaque tour), 1 `vf-coder` (planification puis correction ciblée ; il a lancé 1 chercheur, 1
cartographe, 1 planificateur et 3 tours de checker), 1 `gsd-plan-checker` frais (repris une fois pour compléter C2-C4).
Lancements refusés par le plafond : 3. Tours de critique : 2. Tours de correction des plans : 1.
Reprise (après-midi) : 2 `vf-coder` neufs (plan 73-11 avec 1 `gsd-planner` ; retouches de 73-01..10, repris 7 fois en
correction ciblée), 1 `vf-coder` arrêté net par la coupure de quota (repris sur disque), 4 `gsd-plan-checker` frais
(révision `ac173592` ; delta 73-01..10 ; 73-11 ; contrôle final scopé au diff des corrections). Lancements refusés : 0
(plafond relevé à 100). La dernière passe (`24e2d6f3`) n'est que du texte (marquage « à revalider », libellés, coquille,
un mutant nommé ajouté) : relue par son auteur avec `verify plan-structure`, `bash -n` et `zsh -n`, sans checker de plus.

## Preuves E6

```json
{
  "preuves": [
    { "verdict": "gate:state-intact", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "24e2d6f32475b16c5a96fe769830d4dee9c8cf45" },
    { "verdict": "gate:check-machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "24e2d6f32475b16c5a96fe769830d4dee9c8cf45" },
    { "verdict": "gate:check-mission-invariants", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "24e2d6f32475b16c5a96fe769830d4dee9c8cf45" },
    { "verdict": "revue", "preuve": "amont" },
    { "verdict": "gate:plan-checker-interne", "preuve": "amont" },
    { "verdict": "gate:critique-design", "preuve": "amont" }
  ]
}
```

Lecture : `revue` = vérification fraîche indépendante des plans (`gsd-plan-checker`, `passed`, 0 bloquant) ;
`gate:plan-checker-interne` = boucle du checker de `gsd-plan-phase` (3 tours) ; `gate:critique-design` = juge frais,
80/100. Ces trois verdicts sont relayés tels que rendus, sans commande rejouable. `check-mission-invariants` : 3 = SAIN.

```
$ git -C <worktree> diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md; echo $?
0
$ bash plugin/conductor/scripts/check-mission-invariants.sh
[check-mission-invariants] SAIN — tous les globs de ./.planning/MISSION-INVARIANTS.md matchent encore au moins un fichier suivi.
$ bash plugin/dev-orchestrator/scripts/gsd-run.sh config-get workflow._auto_chain_active --ws fiabilite
false
$ bash plugin/dev-orchestrator/scripts/gsd-run.sh config-get workflow.auto_advance --ws fiabilite
false
$ git -C <worktree> diff -U0 origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/ROADMAP.md | grep '^@@'
@@ -531 +531 @@            (ligne de statut du corps de « ### Phase 73: », titre en 529 intact)
@@ -533,5 +533,15 @@     (corps de la section)
@@ -541 +551,10 @@        (liste des plans)
$ git -C <worktree> diff -U0 origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/REQUIREMENTS.md | grep '^@@'
@@ -1043,0 +1044,16 @@    (16 lignes de traçabilité juste sous le repère de la Phase 73)
@@ -1669,0 +1686,20 @@    (bloc REGI juste sous <!-- vf-cadrage:phase-73 -->)
```

- Critique de la spec : tour 1 `gaps_found` 69/100 ; tour 2 (juge frais) `passed` 80/100, aucun écart majeur au CONTEXT
  ni violation de borne.
- Checker interne de `gsd-plan-phase` : 3 tours, 1 bloquant au premier, 0 au troisième.
- Vérification fraîche indépendante : `passed`, 0 bloquant ; C2 vérifié contre `f763b556` sur trois témoins (73-01
  RG7.2 : module absent, import en échec ; 73-03 RG16.13 : `whoSig` de `vf-cockpit-live.mjs:51` sans `attendAgents`,
  deux `who` qui ne diffèrent que par ce champ donnent la même signature ; 73-07 RG13.34 : aucune occurrence
  d'`ailleurs` dans `vf-cockpit-server.mjs`) ; mutants nommés présents pour chaque garde (non-fuite d'`ailleurs`, liste
  blanche du verrou, ligne source de la fenêtre de stall, compositeur du titre, nettoyage par onglet) ; P73-D-01..36
  tenues ; recherche ciblée des bornes sans violation.
- Famille `REGI` vérifiée libre dans tous les ledgers, le dépôt et les branches des Phases 7x/8x, d'intégration et `main`
  (témoin positif du même contrôle : `REG-D-01` trouvé).

## Next step

Exécuter la Phase 73 vague par vague, en commençant par 73-01 (socle de la suite et module de gouvernance), une fois la
jointure de la vague de cadrage faite ; revalider les plans marqués contre les branches 79 et 80 fusionnées avant les
vagues 6 et 7.
