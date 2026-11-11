# Mission — cadrage et planification de la Phase 80, « Trois onglets, trois formes » (2026-11-11)

Manager : `vf-dev-manager`, mode autonome, design `force`. Compartiment `fiabilite`, jalon `vibeflow-v2.0`. Worktree
`.claude/worktrees/phase-80`, branche `feat/phase-80-trois-formes`, base `origin/integration/cockpit-audit` (`f763b556`).
Verrou de phase `--ws=fiabilite --phase=80`. Cadrée en même temps que les Phases 79, 73, 74, 75, 76 et 77 (demande de
Samuel, session principale Claude Code, 2026-11-11). Périmètre : cadrage et plans ; aucune exécution, aucun fichier de
code, aucune suite.

## Résultat

- **Verdict :** plans écrits et vérifiés à la tête finale de la branche, après la reprise du 2026-11-11 (arbitrages de
  Samuel rendus, contrats de la 79 jusqu'à A55) : vérificateurs frais en lots parallèles — 01-08, 06-14, 15-20 et
  ensemble, puis 09/10/21 et 03/08/17-20 avec le graphe des 21 plans — tous passés après correction (un bloquant
  corrigé : `colonnes-baseline.txt` partagé en vague 8). Exécution non commencée, par mandat.
- **Plans :** 21 plans en 11 vagues (`80-01` à `80-21`), tous autonomes. Vagues 1 à 3 (8 plans) sans la Phase 79 ;
  80-09 à 80-17, 80-19, 80-20, 80-21 après 79-01 à 79-18 fusionnés (79-21 et 79-22 non attendus) ; 80-18 (assemblage)
  après 79-20. Plans revalidés contre la tête `26019872` de la 79 (amendements jusqu'à A53), et `e34edec9` (A55) pour
  80-10 et 80-21.
- **Exigences :** famille `FORM`, 18 exigences (FORM-01 à FORM-18), toutes couvertes (FORM-18 : 80-14, 80-15, 80-19,
  80-20).
- **Décisions :** P80-D-01 à P80-D-60 ; P80-D-52 à P80-D-56 : arbitrage Samuel, AskUserQuestion session principale,
  2026-11-11 (P80-Q-01 à 05 tranchées, option (b)) ; les autres déléguées, option recommandée. Contrats P80-C76-1 à 6
  et contrats fournis aux Phases 73, 74, 75 (pile de surcouches, Échap consommé, `VFGitTiroir.ouvrirSur`,
  `VF_ONGLETS.aller` et fragment d'adresse).
- **Design :** deux UI-SPEC ; quatre critiques fraîches (70/71, 85/84, 85/86, puis 87/88 au rattrapage de P80-D-50) ;
  errata d'application ensuite (définitions feuille/panneau, P80-D-52 à 56, texte d'échec de la coquille).

## Plan de bataille (DAG)

`scout-projet`, `scout-canevas`, `scout-chrome` (éclaireurs en lecture seule, en parallèle) → `panel` (trois chercheurs
en parallèle : couloirs, clavier et surcouches, navigation et chrome) → `cadrage` (le manager, Pattern F) →
`craft:projet` ∥ `craft:navigation` ∥ `research` → `critique:projet` ∥ `critique:navigation` (puis deux reprises de
correction et deux contrôles frais) → `plan` (`vf-coder` → `gsd-plan-phase`) → `plancheck` (deux vérificateurs frais en
parallèle) → `plan` rouvert une fois (révision ciblée) → `plancheck` → `sortie`.

## Plans

| Plan | Vague | Dépend de | Exigences | Fichiers |
|---|---|---|---|---|
| 80-01 | 1 | [] | FORM-01 | 7 |
| 80-02 | 1 | [] | FORM-02 | 8 |
| 80-03 | 1 | [] | FORM-06, FORM-07 | 5 |
| 80-04 | 2 | [80-01, 80-02, 80-03] | FORM-05, FORM-07 | 9 |
| 80-05 | 2 | [80-01] | FORM-10, FORM-12 | 7 |
| 80-06 | 2 | [80-02] | FORM-13 | 10 |
| 80-07 | 3 | [80-04, 80-05] | FORM-09 | 8 |
| 80-08 | 3 | [80-04] | FORM-08 | 5 |
| 80-09 | 4 | [80-05, 80-06, 80-07, 80-08] | FORM-03, FORM-10 | 10 |
| 80-10 | 5 | [80-09] | FORM-16 | 5 |
| 80-11 | 5 | [80-07, 80-09] | FORM-08 | 7 |
| 80-12 | 5 | [80-09] | FORM-11 | 6 |
| 80-13 | 6 | [80-10, 80-11] | FORM-15 | 7 |
| 80-14 | 7 | [80-10, 80-12, 80-13] | FORM-02, FORM-04, FORM-15, FORM-18 | 9 |
| 80-15 | 8 | [80-14] | FORM-03, FORM-18 | 5 |
| 80-16 | 8 | [80-14] | FORM-14 | 9 |
| 80-17 | 9 | [80-14, 80-16] | FORM-14 | 11 |
| 80-18 | 11 | [80-01, 80-02, 80-03, 80-04, 80-05, 80-06, 80-07, 80-08, 80-09, 80-10, 80-11, 80-12, 80-13, 80-14, 80-15, 80-16, 80-17, 80-19, 80-20, 80-21] | FORM-17, FORM-18 | 5 |
| 80-19 | 8 | [80-14] | FORM-18 | 8 |
| 80-20 | 10 | [80-16, 80-17] | FORM-18 | 12 |
| 80-21 | 8 | [80-10, 80-14] | FORM-16 | 8 |

## Carte des fichiers

### Fichiers que la Phase 80 partage avec d'autres phases (en tête)

| Fichier | Plans de la 80 | Autres phases | Règle |
|---|---|---|---|
| `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` | 80-09, 80-11, 80-13, 80-14, 80-16, 80-20 — un seul à la fois | 79 (79-10, 79-16, 79-18, dernier en vague 9), possiblement 75 et 73 | après 79-01 à 79-18 fusionnés (P80-D-15) |
| `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` | 13 plans (lignes `AJOUT`) | 79 (réécrit le fichier en retirant `amont/`, C6-1) | union des lignes à la fusion (P80-D-48) ; après la 79, sa forme |
| `plugin/cockpit/scripts/vf-cockpit-planning.mjs` | 80-03 | 75 (`files_modified`) ; aucun plan de la 79 | la 80 pose `avancement`, `exigences`, `vague` (P80-D-44, A32) ; la 75 lit `vague` |
| `plugin/cockpit/scripts/vf-cockpit-project.mjs` | 80-03, 80-11 | 79 (A27 annotateurs côté Code seulement) | champs facultatifs, `cockpit-project@1` gardé |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` | 80-03 | 79 (79-08 : `cockpit-index@1` après `vibeflow/cockpit-transcript@2`, `claudeCode.index`) | ancre de la 80 : ligne `"statuts"` du bloc `vibeflow/cockpit-project@1` et champs facultatifs juste derrière (diff borné, PC3.3) |
| Suites existantes : `chrome-session.mjs` (`naviguer()`), `chrome-accessibilite.mjs`, `test-cockpit-git-tiroir.sh` (cas D2.1, D7, D8.1, D9.1), `test-cockpit-chrome-fr.sh` | 80-04, 80-01, 80-06, 80-14 | 79 (79-14/79-16, 79-18, 79-02 : ligne `source` et bloc de lancement seulement, 79-10/79-11) | 80-01, 80-04, 80-06 avant ces plans de la 79 (base sans la 79), 80-14 après ; retouches nommées |
| `40-tour.js` (80-09) ; sélecteurs `ui/terminal/q.css`, `ui/tiroir/lancer.css` (80-17) | 80-09, 80-17 | 79 (79-10 `40-tour.js` ; 79-11 range le terminal et le lancement) | après 79-01 à 79-18 |
| `77-vf-git-tiroir.js`, `77-vf-git-rendu.js`, `77-vf-git-vue-detail.js`, `76-vf-git-entete.js` | 80-02, 80-06, 80-13, 80-09, (80-19) | 73 possible (état des worktrees, recoupement noté au ROADMAP) | — |
| `plugin/cockpit/CHANGELOG.md`, `README.md`, `README.fr.md` (compteur de suites), `scripts/ci-shard-suites.sh` | 80-18 seul | toutes les phases (79-20 en dernier) | écrits une fois, au plan d'assemblage (P80-D-24) |
| `DESIGN.md` (racine) | 80-16 | 75 possible (couleur sur la carte Code) | deux lignes nommées (P80-D-31, P80-D-46) |
| `plugin/cockpit/skills/cockpit-moteur/scripts/lib/health.mjs` | 80-19 (Santé en français, P80-D-54) | 79 (79-21 range un module neuf dans `scripts/lib/`) | règle conditionnelle sur `colonnes-baseline.txt` dans 80-19 |
| Dictionnaires `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js` | aucun (dictionnaire neuf `79-vf-fr-dict-c.js`, 80-14) | 79 | P80-D-27, P80-D-35 |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js` (fonction `lireExigences(phaseId)`) | 80-07 | 76 (rebranche la fonction sur `meta.vf.trace.exigences` en retirant le nœud « Exigences », P76-D-25) | point de rebranchement unique, critère du plan 80-07 |
| `plugin/cockpit/scripts/tests/colonnes-baseline.txt` | 80-09, 80-13, 80-14, 80-16, 80-17, 80-20 (une vague chacun) | 79 (79-11 le crée) | abaissé au réel ; la baisse due à 80-02 est une tâche de la jointure |
| Jamais touchés par la 80 | `vf-cockpit-live.mjs`, `70-vf-live.js`, `75-vf-modele.js`, `serve.mjs` | 79 | P80-D-27 |

### Fichiers par plan

- **80-01** (vague 1) : `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/chrome-accessibilite.mjs`, `tests/test-cockpit-clavier-canevas.sh`, `tests/chrome-clavier-canevas.mjs`, `80-01-RED-TRACE.md`
- **80-02** (vague 1) : `ui/00-vf-surcouches.js`, `ui/02-vf-telephone.js`, `ui/73-vf-tiroir-travail.js`, `ui/77-vf-git-tiroir.js`, `VENDORED.txt`, `tests/test-cockpit-surcouches.sh`, `tests/chrome-surcouches.mjs`, `80-02-RED-TRACE.md`
- **80-03** (vague 1) : `scripts/vf-cockpit-planning.mjs`, `scripts/vf-cockpit-project.mjs`, `scripts/vf-cockpit-interface.json`, `tests/test-cockpit-projet-champs.sh`, `80-03-RED-TRACE.md`
- **80-04** (vague 2) : `ui/41-vf-projet-modele.js`, `ui/41-vf-projet-rendu.js`, `ui/41-vf-projet-vue.js`, `ui/41-vf-projet-clavier.js`, `VENDORED.txt`, `tests/chrome-session.mjs`, `tests/test-cockpit-couloirs.sh`, `tests/chrome-couloirs.mjs`, `80-04-RED-TRACE.md`
- **80-05** (vague 2) : `ui/02-vf-coin.js`, `ui/02-vf-ligne-etat.js`, `ui/02-vf-reperes.js`, `VENDORED.txt`, `tests/test-cockpit-coin.sh`, `tests/chrome-coin.mjs`, `80-05-RED-TRACE.md`
- **80-06** (vague 2) : `ui/77-vf-git-rendu.js`, `ui/77-vf-git-tiroir.js`, `ui/77-vf-git-vue-detail.js`, `ui/77-vf-git-volet.js`, `ui/77-vf-git-poignee.js`, `VENDORED.txt`, `tests/test-cockpit-git-tiroir.sh`, `tests/test-cockpit-git-pagination.sh`, `tests/chrome-git-pagination.mjs`, `80-06-RED-TRACE.md`
- **80-07** (vague 3) : `ui/41-vf-projet-liste.js`, `ui/41-vf-projet-phase.js`, `ui/41-vf-projet-vue.js`, `ui/41-vf-projet-formes.js  # seulement si la vue dépasse 299 lignes (tâche 3, P80-D-58 a)`, `VENDORED.txt`, `tests/test-cockpit-projet-liste.sh`, `tests/chrome-projet-liste.mjs`, `80-07-RED-TRACE.md`
- **80-08** (vague 3) : `ui/42-vf-panneau-retour.js`, `VENDORED.txt`, `tests/test-cockpit-panneau-retour.sh`, `tests/chrome-panneau-retour.mjs`, `80-08-RED-TRACE.md`
- **80-09** (vague 4) : `viewer.html`, `ui/76-vf-git-entete.js`, `ui/40-tour.js`, `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/colonnes-baseline.txt`, `tests/test-cockpit-zoom-garde.sh`, `tests/chrome-zoom-garde.mjs`, `80-09-RED-TRACE.md`
- **80-10** (vague 5) : `ui/00-vf-onglets.js`, `VENDORED.txt`, `tests/test-cockpit-onglets.sh`, `tests/chrome-onglets-routage.mjs`, `80-10-RED-TRACE.md`
- **80-11** (vague 5) : `viewer.html`, `scripts/vf-cockpit-project.mjs`, `ui/41-vf-projet-panneau.js`, `VENDORED.txt`, `tests/test-cockpit-projet-vocabulaire.sh`, `tests/chrome-projet-vocabulaire.mjs`, `80-11-RED-TRACE.md`
- **80-12** (vague 5) : `ui/04-vf-clavier-canevas.js`, `ui/04-vf-canevas-champ.js`, `VENDORED.txt`, `tests/test-cockpit-cadrer.sh`, `tests/chrome-cadrer.mjs`, `80-12-RED-TRACE.md`
- **80-13** (vague 6) : `viewer.html`, `ui/77-vf-git-tiroir.js`, `ui/73-vf-tiroir-travail.js`, `tests/colonnes-baseline.txt`, `tests/test-cockpit-lien-vue.sh`, `tests/chrome-lien-vue.mjs`, `80-13-RED-TRACE.md`
- **80-14** (vague 7) : `viewer.html`, `ui/07-vf-raccourcis.js`, `ui/79-vf-fr-dict-c.js`, `VENDORED.txt`, `tests/colonnes-baseline.txt`, `tests/test-cockpit-chrome-fr.sh`, `tests/test-cockpit-palette.sh`, `tests/chrome-palette.mjs`, `80-14-RED-TRACE.md`
- **80-15** (vague 8) : `ui/60-vf-aide.js`, `VENDORED.txt`, `tests/test-cockpit-aide.sh`, `tests/chrome-aide.mjs`, `80-15-RED-TRACE.md`
- **80-16** (vague 8) : `viewer.html`, `ui/00-vibeflow.js`, `ui/01-vf-ensemble.js`, `VENDORED.txt`, `tests/colonnes-baseline.txt`, `DESIGN.md`, `tests/test-cockpit-jetons.sh`, `tests/chrome-jetons.mjs`, `80-16-RED-TRACE.md`
- **80-17** (vague 9) : `ui/03-vf-charte.js`, `ui/05-theme.js`, `ui/01-vf-responsive.js`, `ui/02-vf-telephone.js`, `ui/terminal/q.css`, `ui/tiroir/lancer.css`, `VENDORED.txt`, `tests/colonnes-baseline.txt`, `tests/test-cockpit-finitions.sh`, `tests/chrome-finitions.mjs`, `80-17-RED-TRACE.md`
- **80-18** (vague 11) : `README.md`, `README.fr.md`, `scripts/ci-shard-suites.sh`, `CHANGELOG.md`, `80-18-RED-TRACE.md`
- **80-19** (vague 8) : `scripts/lib/health.mjs`, `tests/test-cockpit-sante.sh`, `tests/cockpit-sante/sonde.mjs`, `tests/test-cockpit-chrome-fr.sh`, `tests/chrome-fr-etats.mjs`, `tests/test-cockpit-sante-fr.sh`, `tests/chrome-sante-fr.mjs`, `80-19-RED-TRACE.md`
- **80-20** (vague 10) : `viewer.html`, `ui/01-vf-ensemble.js`, `ui/01-vf-responsive.js`, `ui/76-vf-git-entete.js`, `ui/03-vf-charte.js`, `tests/test-cockpit-entete.sh`, `tests/chrome-entete.mjs`, `tests/test-cockpit-finitions.sh`, `tests/chrome-finitions.mjs`, `tests/test-cockpit-git-entete.sh`, `tests/colonnes-baseline.txt`, `80-20-RED-TRACE.md`
- **80-21** (vague 8) : `ui/00-vf-onglets-echec.js`, `ui/00-vf-onglets.js`, `ui/02-vf-ligne-echec.js`, `ui/07-vf-reessayer.js`, `VENDORED.txt`, `tests/test-cockpit-echec-onglet.sh`, `tests/chrome-echec-onglet.mjs`, `80-21-RED-TRACE.md`

Chemins relatifs : `ui/` = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, `tests/` = `plugin/cockpit/scripts/tests/`, `scripts/` = `plugin/cockpit/scripts/`.

### Ordre des vagues

1 : 80-01, 80-02, 80-03 · 2 : 80-04, 80-05, 80-06 · 3 : 80-07, 80-08 · — 79-01 à 79-18 fusionnés — · 4 : 80-09 ·
5 : 80-10, 80-11, 80-12 · 6 : 80-13 · 7 : 80-14 · 8 : 80-15, 80-16, 80-19, 80-21 · 9 : 80-17 · 10 : 80-20 ·
— 79-20 fusionné — · 11 : 80-18 (assemblage). Un seul plan par vague sur `viewer.html` (09, 11, 13, 14, 16, 20) ; deux
plans d'une même vague ne partagent que `VENDORED.txt` (union des lignes `AJOUT`, P80-D-48).

### Ce que la 80 attend des autres phases

- **Phase 79** (contrats C0 à C6 et amendements A1 à A55 de `79-CONTEXT.md` sur `feat/phase-79-socle-cockpit`, têtes
  `26019872` et `e34edec9`), plan par plan : 79-01 (retrait de `amont/`, `VENDORED.txt` réduit) ; 79-02 et 79-06
  (`socle-serveur.sh`, `cockpit_module_copie`/`COCKPIT_MODULE` pour les mutants d'interface, A48) ; 79-05 (table des
  routes, ordre alphabétique) ; 79-11 (cliquet de 160 colonnes, terminal et lancement rangés sous `ui/terminal/` et
  `ui/tiroir/`) ; 79-14 (`EVENEMENTS`, repère `// vf-repere:phase-80`) ; 79-16 (coquille, `chargerOnglet`, `surOnglet`
  avec `cle`, réexécution des extensions, scripts persistants A53, signal `vf:coquille-echec` et `VF_COQUILLE.etat()`
  A55) ; 79-17 (`VF_ETAT`) ; 79-18 (worker de mise en page, dernier passage sur `viewer.html`) ; 79-20 (README,
  CHANGELOG) avant 80-18.

### Ce que la 80 fournit aux autres phases

- **Phase 76** : P80-C76-1 à 6 — `addPanelSection` inchangée, `setOverview` n'efface pas les sections, `select`/`reveal`,
  pile `window.VF_PANNEAU` (`retour()`, `empiler({titre, rouvrir})`), « x/y exigences » de `piedExigences`, une seule
  porte `window.VF_EXIGENCES.lireExigences(phaseId)` (80-07, témoin PL2.9 ; 80-11, témoin PV2.5 ; mutant M-PORTE) ;
  aucun témoin de la 80 ne dépend du nœud « Exigences » ni des liens « couvre » dans le graphe (P80-D-04).
- **Phases 73 et 74** : pile de surcouches `window.VF_SURCOUCHES` (persistante), Échap consommé lu par
  `event.defaultPrevented`, vues à l'écoute en remontée ; la fiche d'agent, le lecteur et la régie ne sont pas des
  surcouches ; `window.VFGitTiroir.ouvrirSur(sha)` (80-06) ; `VF_ONGLETS.aller(nom[, { fragment }])` (80-10 :
  promesse après le premier rendu, fragment courant non reporté).
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

1. **ROADMAP du compartiment, ligne de checklist de la Phase 80** : `- [ ] **Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation** — cadrée et planifiée le 2026-11-11 (21 plans, 11 vagues ; FORM-01..18)` (forme des lignes voisines).
2. **ROADMAP, table `## Progress`** : ligne de la Phase 80 → `0/21 | Planned | —`.
3. **REQUIREMENTS.md** : retirer le repère `<!-- vf-cadrage:phase-80 -->` et la ligne repère de traçabilité de la
   Phase 80 (les lignes FORM-01..18 restent) ; pied « Last updated » : `2026-11-11 — Phase 80 cadrée et planifiée : FORM-01..18 posées (famille neuve, préfixe vérifié libre) ; réouvertures tranchées (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11)`.
4. **STATE.md** : Phase 80 « planifiée, 21 plans en 11 vagues ; vagues 1 à 3 exécutables sans la 79 ; 80-09 à 80-17,
   80-19 à 80-21 après 79-01 à 79-18 ; 80-18 après 79-20 » ; décision sous `### Decisions` : `Phase 80 cadrée le 2026-11-11 (P80-D-01..60 ; P80-D-52..56 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; les autres : décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée).`
5. **Registre de l'audit** (`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`), colonne d'état :
   `planifié (Phase 80, plan 80-NN, 2026-11-11)` pour BL1 (80-04), BL2 (80-01), M1 (80-05, 80-09), M6 (80-02, 80-14),
   M12 (80-06), X1 (80-08, 80-11), X2 (80-03, 80-04), X3 (80-09, 80-15), X5 (80-16), X8 (80-05), F1, F3, F4, F5 (80-17),
   F7, le reste de X7 et I30 (80-10, 80-13, 80-21), I23 (80-04), I24 (80-14), I25 (80-07), I26 (80-05), I27 (80-12 ; mode
   focus recomposé en réserve), I29 (80-05), M2, M5 et l'ouvreur de F3 (80-20), M8 (80-19), pastille de M10 (80-14,
   80-15 : une ligne dans l'aide et la palette) ; table « Réouvertures » (§ 5.1) : M2, M5, M8, M10 (pastille) et
   `AUDC-F3 (en partie) | P78-D-34` tranchées, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, option (b).
6. **BACKLOG** : « Mode focus recomposé (AUDC-I27, sous-graphe par ELK) — en réserve après le worker de mise en page de la
   Phase 79 ; la Phase 80 livre seulement « cadrer la sélection et ses voisins » (80-12) ».
7. **Correction de source** (DESIGNS § 9, étude § 8.2, briefs) : la borne « un tiroir latéral ne pousse jamais la carte »
   a pour source PU-G-204, pas Q12.
8. **Gate `check.decision-coverage-plan`** : `could-not-parse` sur les identifiants préfixés `P80-D-NN` ; couverture
   P80-D-01..60 vérifiée à la main ; à suivre au BACKLOG s'il n'y est pas.
9. **Tâches de la jointure avec la 79** (écrites dans les plans des vagues 1 à 3) : reporter telles quelles les lignes
   `AJOUT <chemin>` de la 80 dans le `VENDORED.txt` réécrit par 79-01, à leur place alphabétique ; passer les mutants
   d'interface des vagues 1 à 3 à `cockpit_module_copie` (A48) et leurs suites à `socle-serveur.sh` ; passer leurs
   extensions à l'idiome A51 (`surOnglet` avec `cle`), sauf `00-vf-surcouches.js` déjà persistant ; abaisser
   `colonnes-baseline.txt` pour les lignes longues retirées par 80-02 ; rendre vert le témoin SU6.1 de 80-02 (en
   attente avant la 79) ; fichiers communs avec la 79 : `vf-cockpit-interface.json` (ancres distinctes),
   `test-cockpit-git-tiroir.sh` (cas D2.1, D7, D8.1, D9.1 contre bloc de lancement), `chrome-session.mjs`,
   `chrome-accessibilite.mjs`.

## Limites

- **Gate de sortie, contrôle E4** : manque ou indéterminé attendu — la mission s'arrête aux plans (aucun plan exécuté,
  STATE non marqué). Il n'a pas été verdi.
- **Design** : quatre critiques fraîches ; les derniers errata d'application (définitions feuille/panneau, P80-D-52 à
  56, texte d'échec de la coquille) n'ont pas eu de cinquième critique ; les plans citent les décisions comme
  prioritaires sur les specs. L'UI-SPEC garde « 96 caractères » pour les rangées de plans dans une phase (rangées plus
  larges que les cartes ; P80-D-50 f vise les cartes).
- **Rien n'a été mesuré dans un navigateur** (Playwright partagé) : contrastes, hauteurs de `#ask`, `#vf-coin` et de la
  feuille, focus d'un `g` SVG sous Safari, effet d'`inert` sur l'iframe du terminal restent à mesurer à l'exécution.
- **Phase 79 non exécutée** : ses plans peuvent encore bouger ; un amendement ultérieur peut demander une révision des
  plans 80-09 à 80-21.
- **80-19** s'arrête avant commit si `health.mjs` entre dans le cliquet de colonnes (contradiction entre 79-11 et 79-21
  signalée à la 79).
- **Retour arrière rejeté** (80-10) : `replaceState` rétablit l'adresse et écrase l'entrée de destination (Suivant n'y
  ramène plus), écrit comme limite.
- **Coupure de session** vers 15 h 33 (quota du compte) : brouillons retrouvés complets et commités, enfant arrêté fermé.

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
- Gate de sortie — `check-mission-exit.sh --ws fiabilite --report <ce rapport> --step 80` — rc 4 (indéterminé), attendu et non verdi : E4 « 21 cases de plan non cochées » (mission arrêtée aux plans, par mandat) ; E1 lit le registre du compartiment, où d'autres missions ont des agents vivants — le registre de la phase 80 compte 0 orphelin (`driver-lock.sh orphans --ws=fiabilite --phase=80` → `count: 0`) ; E2 et E3 (arbre non propre, pas de PR) levés par le commit de ce rapport et l'ouverture de la PR ; E7 signale une mémoire d'agent non suivie posée par une mission sœur, hors de cette branche — 0fbb92ad.

- **Reprise du 2026-11-11** (après les arbitrages de Samuel et la coupure de session) :
  - verrou de phase repris — `driver-lock.sh acquire --owner=mgr-phase-80 --step=reprise-80 --ws=fiabilite --phase=80`
    — `acquired: true` — 2910934a ; enfant arrêté par la coupure fermé `--status=stopped` avant toute relance ;
  - critique de design de rattrapage (P80-D-50) — `vf-design-judge` — passed, 87 et 88/100, majeur sous 1 000 px fermé — c9ec8756 ;
  - vérificateurs frais `gsd-plan-checker`, en parallèle : 80-01..05, 08 — 1 avertissement (80-03) corrigé ; 80-06, 07,
    11..14 — passed ; 80-15..20 + ensemble — 1 bloquant (`colonnes-baseline.txt` partagé en vague 8) corrigé par
    re-vagage — e1f4b73d..abc74c31 ; puis 80-09, 10, 21 — 2 avertissements corrigés ; 80-03, 08, 17..20 + graphe des 21
    plans — passed — 401fa614 ; puis diff 99527c8e — 1 avertissement (critère 279 en prose) corrigé et testé sous bash
    et zsh — cce55af8 ;
  - plans revalidés contre la tête `26019872` de la 79 (A1 à A53), `e34edec9` (A55) pour 80-10 et 80-21 ;
  - STATE intact — `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` — rc 0 — cce55af8 ;
  - chemins du poste — `bash scripts/check-machine-paths.sh` — rc 0 ; lignes ajoutées du diff complet sans chemin du
    poste ni identifiant de session — 0 — cce55af8.

```json
{
 "preuves": [
  {"verdict": "gate:driver-lock-phase", "commande": "bash plugin/conductor/scripts/driver-lock.sh acquire --owner=mgr-phase-80 --step=cadrage-80 --ws=fiabilite --phase=80", "exit_code": 0, "sha": "f763b556"},
  {"verdict": "gate:mission-invariants", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "f763b556"},
  {"verdict": "gate:phase-validation", "commande": "bash plugin/conductor/scripts/check-phase-validation.sh --phase 80 --ws fiabilite", "exit_code": 0, "sha": "72cbe7a9"},
  {"verdict": "gate:state-intact", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "cce55af8"},
  {"verdict": "gate:machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "cce55af8"}
 ]
}
```

## Prochaine étape

Exécuter les vagues 1 à 3 de la Phase 80 (80-01 à 80-08), qui ne dépendent pas de la Phase 79, dès la fusion de cette
branche dans `integration/cockpit-audit` ; 80-09 à 80-17 et 80-19 à 80-21 après 79-01 à 79-18 fusionnés ; 80-18
(assemblage) après 79-20.
