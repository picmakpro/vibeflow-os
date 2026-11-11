# Mission — cadrage et planification de la Phase 80, « Trois onglets, trois formes » (2026-11-11)

Manager : `vf-dev-manager`, mode autonome, design `force`. Compartiment `fiabilite`, jalon `vibeflow-v2.0`. Worktree
`.claude/worktrees/phase-80`, branche `feat/phase-80-trois-formes`, base `origin/integration/cockpit-audit` (`f763b556`).
Verrou de phase `--ws=fiabilite --phase=80`. Cadrée en même temps que les Phases 79, 73, 74, 75, 76 et 77 (demande de
Samuel, session principale Claude Code, 2026-11-11). Périmètre : cadrage et plans ; aucune exécution, aucun fichier de
code, aucune suite.

## Résultat

- **Verdict :** plans écrits et vérifiés (vérificateur du workflow PASSED ; vérificateur frais du manager : 12 points fermés sur 12, aucun bloquant). Mission de cadrage terminée ; exécution non commencée, par mandat.
- **Plans :** 19 plans en 10 vagues (`80-01` à `80-19`). Vagues 1 à 3 (8 plans) sans dépendance à la Phase 79 ; à partir
  de `80-09`, précondition : Phase 79 fusionnée en entier. `80-19` (FORM-18) n'est pas exécutable avant l'avis de Samuel.
- **Exigences :** famille `FORM`, 18 exigences (FORM-01 à FORM-18), toutes couvertes par au moins un plan.
- **Décisions :** P80-D-01 à P80-D-51 (déléguées, option recommandée), contrats P80-C76-1 à 5 (Phase 76), contrats
  fournis aux Phases 73, 74, 75. Cinq questions à Samuel (S80-1 à S80-5), non bloquantes.
- **Design :** deux UI-SPEC (`80-UI-SPEC.md`, `80-UI-SPEC-NAVIGATION.md`), trois tours de craft et de critique fraîche
  (70 et 71/100, puis 85 et 84, puis 85 et 86) ; le dernier majeur, sous 1 000 px, est tranché par le manager (P80-D-50)
  et reporté par erratum, sans quatrième critique (budget de trois tours atteint).

## Plan de bataille (DAG)

`scout-projet`, `scout-canevas`, `scout-chrome` (éclaireurs en lecture seule, en parallèle) → `panel` (trois chercheurs
en parallèle : couloirs, clavier et surcouches, navigation et chrome) → `cadrage` (le manager, Pattern F) →
`craft:projet` ∥ `craft:navigation` ∥ `research` → `critique:projet` ∥ `critique:navigation` (puis deux reprises de
correction et deux contrôles frais) → `plan` (`vf-coder` → `gsd-plan-phase`) → `plancheck` (deux vérificateurs frais en
parallèle) → `plan` rouvert une fois (révision ciblée) → `plancheck` → `sortie`.

## Plans

| Plan | Titre | Vague | Dépend de | Exigences | Fichiers | Autonome |
|---|---|---|---|---|---|---|
| 80-01 | Clavier du canevas | 1 | [] | FORM-01 | 7 | true |
| 80-02 | Pile de surcouches, panneau fermé hors tabulation | 1 | [] | FORM-02 | 8 | true |
| 80-03 | Données de Projet (avancement, exigences, vague, recette ; DIFFÉRÉ retiré du pied) | 1 | [] | FORM-06, FORM-07 | 5 | true |
| 80-04 | Projet en couloirs, ?vue=, visite, contrats C76 | 2 | [80-01, 80-02, 80-03] | FORM-05, FORM-07 | 9 | true |
| 80-05 | Coin bas-droit : minicarte, repères, ligne d'état, zone basse du téléphone | 2 | [80-01] | FORM-10, FORM-12 | 7 | true |
| 80-06 | Tiroir Git : pagination, worktrees repliés, volet bas, poignée | 2 | [80-02] | FORM-13 | 10 | true |
| 80-07 | Forme Liste, intérieur de phase, touche v, mémoire par lab | 3 | [80-04, 80-05] | FORM-09 | 7 | true |
| 80-08 | Pile Retour du panneau VF_PANNEAU | 3 | [80-04] | FORM-08 | 5 | true |
| 80-09 | Lot moteur A1 : cadrage unique, champ de lecture, zoom réversible, garde de saisie | 4 | [80-05, 80-06, 80-07, 80-08] | FORM-03, FORM-10 | 9 | true |
| 80-10 | Onglets sans rechargement | 5 | [80-09] | FORM-16 | 6 | true |
| 80-11 | Lot moteur A2 : vocabulaire du panneau de Projet | 5 | [80-09] | FORM-08 | 7 | true |
| 80-12 | Cadrer la sélection et ses voisins (touche C) | 5 | [80-09] | FORM-11 | 6 | true |
| 80-13 | Lot moteur A3 : lien de vue, mémoire des tiroirs | 6 | [80-11] | FORM-15 | 6 | true |
| 80-14 | Lot moteur B : palette, registre des raccourcis, ARIA de la palette | 7 | [80-10, 80-12, 80-13] | FORM-04, FORM-02, FORM-15 | 8 | true |
| 80-15 | Aide ? | 8 | [80-14] | FORM-03 | 5 | true |
| 80-16 | Jetons X5, DESIGN.md, découpe de 00-vibeflow.js | 8 | [80-14] | FORM-14 | 8 | true |
| 80-17 | Finitions F1, F3, F4, F5 | 8 | [80-14] | FORM-14 | 9 | true |
| 80-18 | Assemblage (README, ci-shard-suites.sh, CHANGELOG) | 9 | [80-01, 80-02, 80-03, 80-04, 80-05, 80-06, 80-07, 80-08, 80-09, 80-10, 80-11, 80-12, 80-13, 80-14, 80-15, 80-16, 80-17] | FORM-17 | 5 | true |
| 80-19 | Après avis de Samuel (S80-1 à S80-5), non exécutable en l'état | 10 | [80-18] | FORM-18 | 13 | false |

## Carte des fichiers

### Fichiers que la Phase 80 partage avec d'autres phases (en tête)

| Fichier | Plans de la 80 | Autres phases | Règle |
|---|---|---|---|
| `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` | 80-09, 80-11, 80-13, 80-14, 80-16, (80-19) — un seul à la fois | 79 (à partir de sa vague 3), probablement 75 et 73 | tous les plans 80 qui y touchent passent après la fusion de la 79 entière (P80-D-15) |
| `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | 13 plans (lignes `AJOUT`) | 79 (réécrit le fichier en retirant `amont/`, C6-1) | union des lignes à la fusion (P80-D-48) ; après la 79, sa forme |
| `plugin/cockpit/scripts/vf-cockpit-planning.mjs` | 80-03 | 79 (collecte), 75 (`files_modified`) | la 80 pose `avancement`, `exigences`, `vague` (P80-D-44, A32) ; la 75 lit `vague` |
| `plugin/cockpit/scripts/vf-cockpit-project.mjs` | 80-03, 80-11 | 79 (A27 annotateurs côté Code seulement) | champs facultatifs, `cockpit-project@1` gardé |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` | 80-03 | 79 (bloc de l'index, C6-3) | ajout de `recette` aux statuts et des champs facultatifs |
| Suites existantes : `chrome-session.mjs` (`naviguer()`), `chrome-accessibilite.mjs`, `test-cockpit-git-tiroir.sh`, `test-cockpit-chrome-fr.sh` | 80-04, 80-01, 80-06, 80-14 | 79 (toutes les suites passent par `socle-serveur.sh`, C6-2) | retouches minimales et nommées (P80-D-02, P80-D-37) |
| `40-tour.js`, `05-theme.js` (fichiers du moteur) | 80-09, 80-17 | 79 (« peut-être », A7) | après la fusion de la 79 |
| `77-vf-git-tiroir.js`, `77-vf-git-rendu.js`, `77-vf-git-vue-detail.js`, `76-vf-git-entete.js` | 80-02, 80-06, 80-13, 80-09, (80-19) | 73 possible (état des worktrees, recoupement noté au ROADMAP) | — |
| `plugin/cockpit/CHANGELOG.md`, `README.md`, `README.fr.md` (compteur de suites), `scripts/ci-shard-suites.sh` | 80-18 seul (80-19 sa ligne de CHANGELOG) | toutes les phases | écrits une fois, au plan d'assemblage (P80-D-24) |
| `DESIGN.md` (racine) | 80-16 | 75 possible (couleur sur la carte Code) | deux lignes nommées (P80-D-31, P80-D-46) |
| `plugin/cockpit/skills/cockpit-moteur/scripts/lib/health.mjs` | 80-19 seul (après avis) | 79 (collecteur vendorisé, `scripts/lib/*` modifiés) | — |
| Dictionnaires `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js` | aucun (dictionnaire neuf `79-vf-fr-dict-c.js`, 80-14) | 79 | P80-D-27, P80-D-35 |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js` (fonction `lireExigences(phaseId)`) | 80-07 | 76 (rebranche la fonction sur `meta.vf.trace.exigences` en retirant le nœud « Exigences », P76-D-25) | point de rebranchement unique, critère du plan 80-07 |
| Jamais touchés par la 80 | `vf-cockpit-live.mjs`, `70-vf-live.js`, `75-vf-modele.js`, `serve.mjs` | 79 | P80-D-27 |

### Fichiers par plan

- **80-01** (vague 1) : `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/chrome-accessibilite.mjs`, `tests/test-cockpit-clavier-canevas.sh`, `tests/chrome-clavier-canevas.mjs`, `80-01-RED-TRACE.md`
- **80-02** (vague 1) : `ui/00-vf-surcouches.js`, `ui/02-vf-telephone.js`, `ui/73-vf-tiroir-travail.js`, `ui/77-vf-git-tiroir.js`, `VENDORED.txt`, `tests/test-cockpit-surcouches.sh`, `tests/chrome-surcouches.mjs`, `80-02-RED-TRACE.md`
- **80-03** (vague 1) : `scripts/vf-cockpit-planning.mjs`, `scripts/vf-cockpit-project.mjs`, `scripts/vf-cockpit-interface.json`, `tests/test-cockpit-projet-champs.sh`, `80-03-RED-TRACE.md`
- **80-04** (vague 2) : `ui/41-vf-projet-modele.js`, `ui/41-vf-projet-rendu.js`, `ui/41-vf-projet-vue.js`, `ui/41-vf-projet-clavier.js`, `VENDORED.txt`, `tests/chrome-session.mjs`, `tests/test-cockpit-couloirs.sh`, `tests/chrome-couloirs.mjs`, `80-04-RED-TRACE.md`
- **80-05** (vague 2) : `ui/02-vf-coin.js`, `ui/02-vf-ligne-etat.js`, `ui/02-vf-reperes.js`, `VENDORED.txt`, `tests/test-cockpit-coin.sh`, `tests/chrome-coin.mjs`, `80-05-RED-TRACE.md`
- **80-06** (vague 2) : `ui/77-vf-git-rendu.js`, `ui/77-vf-git-tiroir.js`, `ui/77-vf-git-vue-detail.js`, `ui/77-vf-git-volet.js`, `ui/77-vf-git-poignee.js`, `VENDORED.txt`, `tests/test-cockpit-git-tiroir.sh`, `tests/test-cockpit-git-pagination.sh`, `tests/chrome-git-pagination.mjs`, `80-06-RED-TRACE.md`
- **80-07** (vague 3) : `ui/41-vf-projet-liste.js`, `ui/41-vf-projet-phase.js`, `ui/41-vf-projet-vue.js`, `VENDORED.txt`, `tests/test-cockpit-projet-liste.sh`, `tests/chrome-projet-liste.mjs`, `80-07-RED-TRACE.md`
- **80-08** (vague 3) : `ui/42-vf-panneau-retour.js`, `VENDORED.txt`, `tests/test-cockpit-panneau-retour.sh`, `tests/chrome-panneau-retour.mjs`, `80-08-RED-TRACE.md`
- **80-09** (vague 4) : `viewer.html`, `ui/76-vf-git-entete.js`, `ui/40-tour.js`, `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/test-cockpit-zoom-garde.sh`, `tests/chrome-zoom-garde.mjs`, `80-09-RED-TRACE.md`
- **80-10** (vague 5) : `ui/00-vf-onglets.js`, `ui/41-vf-projet-vue.js`, `VENDORED.txt`, `tests/test-cockpit-onglets.sh`, `tests/chrome-onglets.mjs`, `80-10-RED-TRACE.md`
- **80-11** (vague 5) : `viewer.html`, `scripts/vf-cockpit-project.mjs`, `ui/41-vf-projet-panneau.js`, `VENDORED.txt`, `tests/test-cockpit-projet-vocabulaire.sh`, `tests/chrome-projet-vocabulaire.mjs`, `80-11-RED-TRACE.md`
- **80-12** (vague 5) : `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/test-cockpit-cadrer.sh`, `tests/chrome-cadrer.mjs`, `80-12-RED-TRACE.md`
- **80-13** (vague 6) : `viewer.html`, `ui/77-vf-git-tiroir.js`, `ui/73-vf-tiroir-travail.js`, `tests/test-cockpit-lien-vue.sh`, `tests/chrome-lien-vue.mjs`, `80-13-RED-TRACE.md`
- **80-14** (vague 7) : `viewer.html`, `ui/07-vf-raccourcis.js`, `ui/79-vf-fr-dict-c.js`, `VENDORED.txt`, `tests/test-cockpit-chrome-fr.sh`, `tests/test-cockpit-palette.sh`, `tests/chrome-palette.mjs`, `80-14-RED-TRACE.md`
- **80-15** (vague 8) : `ui/60-vf-aide.js`, `VENDORED.txt`, `tests/test-cockpit-aide.sh`, `tests/chrome-aide.mjs`, `80-15-RED-TRACE.md`
- **80-16** (vague 8) : `viewer.html`, `ui/00-vibeflow.js`, `ui/01-vf-ensemble.js`, `VENDORED.txt`, `DESIGN.md`, `tests/test-cockpit-jetons.sh`, `tests/chrome-jetons.mjs`, `80-16-RED-TRACE.md`
- **80-17** (vague 8) : `ui/03-vf-charte.js`, `ui/05-theme.js`, `ui/01-vf-responsive.js`, `ui/02-vf-telephone.js`, `scripts/vf-cockpit-terminal-vue.mjs`, `VENDORED.txt`, `tests/test-cockpit-finitions.sh`, `tests/chrome-finitions.mjs`, `80-17-RED-TRACE.md`
- **80-18** (vague 9) : `README.md`, `README.fr.md`, `scripts/ci-shard-suites.sh`, `CHANGELOG.md`, `80-18-RED-TRACE.md`
- **80-19** (vague 10) : `viewer.html`, `ui/01-vf-ensemble.js`, `ui/01-vf-responsive.js`, `ui/03-vf-charte.js`, `ui/76-vf-git-entete.js`, `ui/07-vf-raccourcis.js`, `ui/60-vf-aide.js`, `scripts/lib/health.mjs`, `tests/test-cockpit-finitions.sh`, `tests/test-cockpit-aide.sh`, `tests/test-cockpit-sante.sh`, `CHANGELOG.md`, `80-19-RED-TRACE.md`

Chemins relatifs : `ui/` = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, `tests/` = `plugin/cockpit/scripts/tests/`, `scripts/` = `plugin/cockpit/scripts/`, `VENDORED.txt` = `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` ; les `RED-TRACE` vivent dans le dossier de phase. `04-vf-canevas-champ.js` n'est créé que si le budget de 300 lignes de `04-vf-clavier-canevas.js` est dépassé.

### Ordre des vagues

1 : 80-01, 80-02, 80-03 · 2 : 80-04, 80-05, 80-06 · 3 : 80-07, 80-08 · — fusion de la Phase 79 entière — · 4 : 80-09 ·
5 : 80-10, 80-11, 80-12 · 6 : 80-13 · 7 : 80-14 · 8 : 80-15, 80-16, 80-17 · 9 : 80-18 (assemblage) · 10 : 80-19 (après
avis de Samuel).

### Ce que la 80 attend des autres phases

- **Phase 79** (contrats C0 à C6 et amendements A1 à A32, `79-CONTEXT.md` sur `feat/phase-79-socle-cockpit`, commits
  `3119d82a`, `2ae6607a`, `6f66d878`, `74501bb0`, `e04c43e7`) : retrait de `amont/` (vague 1 de la 79) ; aide
  `socle-serveur.sh` (plan 79-02) ; coquille, `VF_COQUILLE.chargerOnglet` et `surOnglet` ; événement `graphe` et relecture
  `GET /api/vf/graphe?onglet=projet` ; `on('render')`, `state.layout.children`, `freeArea()` gardés après le worker ;
  URL des trois onglets gardées.

### Ce que la 80 fournit aux autres phases

- **Phase 76** : P80-C76-1 à 5 — `addPanelSection` inchangée, `setOverview` n'efface pas les sections, `select`/`reveal`,
  pile `window.VF_PANNEAU` (`retour()`, `empiler({titre, rouvrir})`), « x/y exigences » de `piedExigences`.
  Branchement sur Projet : la section du panneau d'une phase (carte de couloir ou rangée de liste → `select(ph-<N>)`) et
  un mot au plus sur la ligne d'état de la carte.
- **Phases 73 et 74** : pile de surcouches `window.VF_SURCOUCHES` (`ouvrir`, `dessus`, `ouverte`).
- **Phase 75** : la 80 rend la carte Code navigable (attributs reposés à chaque rendu, nom accessible par une fonction
  unique enrichissable) ; la 75 la colore par ses annotateurs (A27) ; la 80 pose `vague`, la 75 lit.

## Décisions

Registre complet : `80-CONTEXT.md`. Toutes « décision déléguée par Samuel (message session principale, 2026-11-08),
option recommandée » ; aucune ne vaut arbitrage de Samuel. Les plus engageantes : couloirs en vue DOM de la couche VF
(P80-D-01) ; champs ajoutés à `cockpit-project@1` sans montée de version (P80-D-06) ; tabulation itinérante par voisin
spatial (P80-D-10) ; pile de surcouches unique (P80-D-11) ; tout `viewer.html` après la fusion de la 79 (P80-D-15) ;
panneau par-dessus, sans réserve (P80-D-29 révisée) ; Entrée plonge et Espace sélectionne à toute largeur (P80-D-51).

## Questions à Samuel — tranchées

Les cinq questions du cadrage (S80-1 à S80-5, devenues P80-Q-01 à P80-Q-05 au format C76-Q1 de la Phase 76) ont été
tranchées : **arbitrage Samuel, AskUserQuestion session principale, 2026-11-11**, option (b) pour chacune — « Zone
réservée (Recommandé) », « Trois groupes libellés (Recommandé) », « Traduire les constats (Recommandé) », « Une ligne
dans l'aide (Recommandé) », « 36 visibles, 44 d'appui (Recommandé) ». Décisions P80-D-52 à P80-D-56 ; Q10, PU-G-001 (en
partie), P70-D-04, P71-D-02 et P78-D-34 amendés dans la mesure exacte de l'option retenue. L'ancien plan « après avis »
est redécoupé en plans exécutables (P80-D-57). AUDC-M11 est tranché hors de cette phase (lot de correctifs à part).

## Reprise du 2026-11-11 (après les arbitrages)

- Section « À Samuel » remise au format C76-Q1 (P80-Q-01 à 05, `État : tranchée`).
- Contrats ajoutés ou corrigés à la demande des phases voisines : P80-C76-6 (une seule porte `lireExigences` pour les
  exigences et la couverture, retrait du nœud « Exigences » par la 76 sans effet sur les témoins de la 80, P80-D-04) ;
  pour la 74 : la fiche d'agent, le lecteur et la régie ne sont pas des surcouches, `VFGitTiroir.ouvrirSur(sha)`
  (80-06), promesse de `VF_ONGLETS.aller` (80-10).
- Règles de la 79 à sa tête (amendements A34 à A48) portées par P80-D-58 : 299 lignes, 160 colonnes, code du terminal
  et du lancement sous `assets/ui/terminal/` et `assets/ui/tiroir/`, aucun script en ligne, fichiers sous `/_vf/`,
  compteur de suites au nombre réel, mutants d'interface par `cockpit_module_copie` après la 79.
- Design : quatrième critique fraîche (rattrapage de P80-D-50) — passed, 87 et 88/100, majeur sous 1 000 px fermé ;
  mineurs corrigés (définitions « feuille de détail » et « panneau latéral »).
- Coupure de session vers 15 h 33 (quota du compte) : brouillons de 80-19 et 80-20 retrouvés complets et commités,
  enfant arrêté fermé au registre, travail repris en deux lots parallèles.

## À verser par la jointure

Texte exact à poser par la session principale à la jointure ; rien de cela n'a été écrit par cette mission.

1. **ROADMAP du compartiment, ligne de checklist de la Phase 80** (section du jalon) : passer de « non cadrée » à
   `- [ ] **Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation** — cadrée et planifiée le 2026-11-11 (19 plans, 10 vagues ; FORM-01..18 ; 80-19 après avis de Samuel)`
   (garder la forme exacte des lignes voisines).
2. **ROADMAP, table `## Progress`** : ligne de la Phase 80 → `0/19 | Planned | —`.
3. **REQUIREMENTS.md** : retirer le repère `<!-- vf-cadrage:phase-80 -->` et la ligne repère de traçabilité de la Phase 80
   (les lignes FORM-01..18 restent) ; pied « Last updated » : `2026-11-11 — Phase 80 cadrée et planifiée : FORM-01..18 posées (famille neuve, préfixe vérifié libre), FORM-18 après avis de Samuel`.
4. **STATE.md** : Phase 80 « planifiée, 19 plans, prête à exécuter les vagues 1 à 3 (sans la 79) ; vagues 4 et suivantes après la fusion de la Phase 79 entière » ; décision à consigner sous `### Decisions` :
   `Phase 80 cadrée en autonomie le 2026-11-11 (P80-D-01..51, décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée) ; cinq questions ouvertes à Samuel (S80-1..5), non bloquantes.`
5. **Registre de l'audit (`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`)**, colonne d'état des lignes de la
   phase : `planifié (Phase 80, plan 80-NN, 2026-11-11)` pour BL1 (80-04), BL2 (80-01), M1 (80-05, 80-09), M6 (80-02,
   80-14), M12 (80-06), X1 (80-08, 80-11), X2 (80-03, 80-04), X3 (80-09, 80-15), X5 (80-16), X8 (80-05), F1, F3, F4, F5
   (80-17), F7 (80-10), I23 (80-04), I24 (80-14), I25 (80-07), I26 (80-05), I27 (80-12 ; le mode focus recomposé reste
   en réserve), I29 (80-05), I30 et le reste de X7 (80-10, 80-13) ; `après avis de Samuel (80-19, S80-1..4)` pour M2, M5,
   M8 et la pastille de M10. Table « Réouvertures » (§ 5.1) : ajouter `AUDC-F3 (en partie) | P78-D-34, ouvreur Git à 44 px (S80-5)`.
6. **BACKLOG** : une entrée « Mode focus recomposé (AUDC-I27, sous-graphe par ELK) — en réserve après le worker de mise
   en page de la Phase 79 ; la Phase 80 livre seulement « cadrer la sélection et ses voisins » (80-12) ».
7. **Correction de source à porter là où la borne est citée** (DESIGNS § 9, étude § 8.2, briefs) : la borne « un tiroir
   latéral ne pousse jamais la carte » a pour source PU-G-204 (`plugin/cockpit/CHANGELOG.md` § Non publié), pas Q12, dont
   la réponse est « Un seul latéral sous 1280 px » puis « Non, lecture étroite ».
8. **Gate `check.decision-coverage-plan`** : il rend `could-not-parse` sur les identifiants préfixés `P80-D-NN` (même
   constat qu'en Phase 57) ; la couverture P80-D-01..51 a été vérifiée à la main par le vérificateur. À suivre au BACKLOG
   s'il n'y est pas déjà.

## Limites

- **Gate de sortie, contrôle E4** : manque ou indéterminé attendu — la mission s'arrête aux plans (aucun plan exécuté,
  STATE non marqué, par construction du mandat). Il n'a pas été verdi.
- **Design** : trois tours de craft et de critique fraîche ; le troisième contrôle (85 et 86/100) a laissé un majeur sous
  1 000 px, tranché par le manager (P80-D-50) et reporté par erratum sans quatrième critique. L'UI-SPEC garde « 96
  caractères » pour les rangées de plans à l'intérieur d'une phase (§ 2.3, rangées plus larges que les cartes) : P80-D-50
  (f) vise les cartes de phase ; les plans citent P80-D-50 et P80-D-51 comme prioritaires sur les specs.
- **Rien n'a été mesuré dans un navigateur** (Playwright partagé, consigne) : contrastes, hauteurs de `#ask`, de
  `#vf-coin` et de la feuille, focus d'un `g` SVG sous Safari, effet d'`inert` sur l'iframe du terminal restent à mesurer
  à l'exécution ; les plans portent ces mesures dans leurs témoins.
- **Phase 79 non livrée** : les vagues 4 et suivantes dépendent de ses contrats (C0 à C6, A1 à A32), figés mais pas
  encore exécutés ; un amendement ultérieur de la 79 peut demander une révision des plans 80-09 à 80-18.
- **`VENDORED.txt`** : la forme que la 79 laissera à ce fichier n'est pas connue ; les vagues 1 à 3 écrivent dans la
  forme actuelle, la fusion avec la 79 garde la suppression de `amont/` et les lignes de la 80 se réinscrivent dans la
  nouvelle forme (P80-D-48).
- **Saturation des sous-agents** : la limite de 20 sous-agents concurrents du poste, partagée par les sept missions, a
  bloqué une fois le lancement de la recherche et deux fois celui du planificateur ; reprise par attente, sans jouer
  un rôle à la place d'un agent.
- **`80-RESEARCH.md`** est antérieur aux derniers amendements du CONTEXT (avertissement de dérive non bloquant) ; ses
  questions ouvertes sont marquées résolues avec le plan porteur.

## Preuves E6

Format : verdict — commande — code de sortie — SHA. Cadrage et plans seulement : aucune suite n'a été jouée, par
mandat ; les témoins rouge→vert sont écrits dans les plans, à produire à l'exécution.

- Verrou de phase pris — `driver-lock.sh acquire --owner=mgr-phase-80 --step=cadrage-80 --ws=fiabilite --phase=80` —
  `acquired: true` — f763b556.
- Invariants de mission SAINS — `check-mission-invariants.sh` — signal « SAIN » — f763b556.
- Drapeaux d'enchaînement désarmés, lus et non écrits — `gsd-run.sh config-get workflow._auto_chain_active --ws fiabilite`
  et `… workflow.auto_advance …` — sortie exacte `false` pour les deux — f763b556.
- Préfixe `FORM` libre — `grep -rc '\bFORM-[0-9]' .planning plugin` — total 0 — f763b556.
- Porte « phase proposée » — `check-phase-validation.sh --phase 80 --ws fiabilite` — rc 0 (marqueur absent) — 72cbe7a9.
- Vérification des plans par le workflow — `gsd-plan-checker` (dans `gsd-plan-phase`) — VERIFICATION PASSED, 1 tour —
  894b9b6c ; vérification fraîche du manager, deux vérificateurs en parallèle — issues_found (4 bloquants, 8
  avertissements) — 894b9b6c ; révision ciblée puis vérificateur du workflow — PASSED, 0 avertissement — 0fbb92ad ;
  vérificateur frais du manager, scopé au diff 894b9b6c..0fbb92ad — 12 points fermés sur 12, un avertissement levé à la
  lecture de 80-09 (PR2.9 exigée vert) — 0fbb92ad.
- Critique de design fraîche, seuil 70 — `vf-design-judge` — 70 (projet) et 71 (navigation) au premier tour ; 85 et 84
  au contrôle du deuxième tour ; 85 et 86 au contrôle du troisième — 0b5b0d27, f568b257, 399732d1.
- STATE intact — `git -C <worktree> diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md`
  — rc 0 — 0fbb92ad.
- Périmètre d'écriture — `git diff --name-only origin/integration/cockpit-audit` hors dossier de phase — `ROADMAP.md`
  (corps de la section 80 seulement, trois hunks) et `REQUIREMENTS.md` (deux hunks d'insertion, juste après les
  repères de la Phase 80) + ce rapport — 0fbb92ad.
- Aucun chemin du poste ni identifiant de session — `bash scripts/check-machine-paths.sh` — rc 0  ; et une recherche, sur les lignes ajoutées du diff complet contre la base, des chemins du dossier personnel, du dossier temporaire du poste et du dossier de captures — 0 — 0fbb92ad.
- Gate de sortie — `check-mission-exit.sh --ws fiabilite --report <ce rapport> --step 80` — rc 4 (indéterminé), attendu et non verdi : E4 « 19 cases de plan non cochées » (mission arrêtée aux plans, par mandat) ; E1 lit le registre du compartiment, où d'autres missions ont des agents vivants — le registre de la phase 80 compte 0 orphelin (`driver-lock.sh orphans --ws=fiabilite --phase=80` → `count: 0`) ; E2 et E3 (arbre non propre, pas de PR) levés par le commit de ce rapport et l'ouverture de la PR ; E7 signale une mémoire d'agent non suivie posée par une mission sœur, hors de cette branche — 0fbb92ad.

```json
{
 "preuves": [
  {"verdict": "gate:driver-lock-phase", "commande": "bash plugin/conductor/scripts/driver-lock.sh acquire --owner=mgr-phase-80 --step=cadrage-80 --ws=fiabilite --phase=80", "exit_code": 0, "sha": "f763b556"},
  {"verdict": "gate:mission-invariants", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "f763b556"},
  {"verdict": "gate:phase-validation", "commande": "bash plugin/conductor/scripts/check-phase-validation.sh --phase 80 --ws fiabilite", "exit_code": 0, "sha": "72cbe7a9"},
  {"verdict": "gate:state-intact", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "0fbb92ad"},
  {"verdict": "gate:machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "0fbb92ad"}
 ]
}
```

## Prochaine étape

Exécuter les vagues 1 à 3 de la Phase 80 (80-01 à 80-08), qui ne dépendent pas de la Phase 79, dès la fusion de cette
branche dans `integration/cockpit-audit` ; les vagues 4 et suivantes attendent la fusion de la 79 entière ; 80-19
attend la réponse de Samuel à S80-1..5.
