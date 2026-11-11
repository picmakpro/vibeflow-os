# Mission — cadrage et plans de la Phase 76, « Traçabilité au cockpit » (2026-11-11)

Manager : `vf-dev-manager`, mode autonome, design `auto`. Compartiment `fiabilite`, jalon `vibeflow-v2.0`.
Worktree `.claude/worktrees/phase-76`, branche `feat/phase-76-tracabilite`, base `origin/integration/cockpit-audit`
(`f763b556`). Verrou de phase `--ws fiabilite --phase 76`. Demande : Samuel (session principale Claude Code,
2026-11-11), cadrer et planifier en parallèle les Phases 73 à 77, 79 et 80 ; cette mission porte la 76 et s'arrête aux
plans écrits et vérifiés. Aucune exécution, aucun code, aucune suite.

## Résultat

- **Cadrée** : `76-CONTEXT.md`, décisions P76-D-01 à P76-D-31 (dont 15bis), toutes « décision déléguée par Samuel
  (message session principale, 2026-11-08), option recommandée » ; deux confirmations non bloquantes « À Samuel »
  (A-1, A-2). Aucun arbitrage de Samuel rouvert.
- **Exigences** : famille neuve `TRAC`, TRAC-01 à TRAC-12, insérées derrière le repère de la Phase 76 du ledger.
- **Contrat de design** : `76-UI-SPEC.md`, trois passes ; critique fraîche `vf-design-judge` 75/100 `gaps_found`, puis
  73/100 `passed` (cinq majeurs fermés au tour 3).
- **Plans** : 8 plans en 6 vagues (`76-01` à `76-08`), plus `76-RESEARCH.md`, `76-PATTERNS.md`, `76-VALIDATION.md`.
  Vérification fraîche complète (`gsd-plan-checker`) : voir § Vérification.
- **Gate de sortie** : son contrôle E4 dira « manque » ou « indéterminé » (plans non exécutés, STATE non marqué) :
  attendu pour une mission de cadrage, non verdi.

## Plan de bataille (DAG)

`dag.sh` (scratchpad de la mission) : trois éclaireurs en parallèle (code de l'onglet Projet ; sources mesurées ;
phases voisines et antériorité) → trois panels en parallèle (forme ; chemin des données ; mémoire) → cadrage porté par
le manager → UI-SPEC et RESEARCH en parallèle → critique de l'UI-SPEC (rouverte deux fois) → plans → vérification
fraîche (rouverte une fois) → livraison. Saturation de la session (20 sous-agents partagés par sept missions) : six
dispatches refusés, repris après attente ; le `gsd-ui-checker` n'a jamais pu tourner (voir Limites).

## Décisions structurantes (détail : `76-CONTEXT.md`)

- **Forme** (P76-D-01, panel) : panneaux reliés de l'onglet Projet, voisinage seul ; ni canevas ni quatrième onglet.
- **Emplacement** (P76-D-02) : `addPanelSection('item')` sur le panneau de phase, `addPanelSection('overview')` pour
  Jalon, Décisions, Mémoire ; `showPanel` pour exigence, ADR, décision, entrée de mémoire ; `viewer.html` intact.
- **Navigation** (P76-D-03, P76-D-30) : `select`/`reveal` ; Retour par la pile commune de la Phase 80
  (`window.VF_PANNEAU`, `empiler` pour les panneaux sur mesure) ; aucun fil d'Ariane.
- **Trous** (P76-D-04, P76-D-15bis) : glyphe et mot ; trait corail réservé à une liste fermée de contradictions lues.
- **Données** (P76-D-06, P76-D-31, panel) : route à la demande `GET /api/vf/tracabilite`, schéma
  `vibeflow/cockpit-trace@1` ; le planning se lit dans l'instantané de la collecte (manques ajoutés en champs facultatifs
  de `cockpit-project@1`, règle A32 de la 79) ; ADR, commits citants et mémoire en lecture confinée, bornée, mise en
  cache par empreinte (sha de HEAD + `seq` de l'instantané + dates de `docs/ADR.md` et de la mémoire).
- **Mémoire** (P76-D-19 à D-23, panel) : fichiers suivis seulement ; structure seule (`name`, agent, type, jour,
  comptes, chemins absents relatifs) ; pas de « périmée » devinée.
- **Décisions** (P76-D-16 à D-18) : ADR + registres de phase ; une décision nue n'est reliée à aucun commit ;
  extracteur `vf-cockpit-registres.mjs` partagé avec la 73.
- **Un ajout, un retrait** (P76-D-25) : le nœud « Exigences » et ses cartes quittent le graphe Projet.

## Vérification des plans

- Boucle interne du planificateur : itération 1, un bloquant (préfixe à point `P71.5-D-nn` non extrait), levé ;
  itération 2 `VERIFICATION PASSED`, mais re-vérification ciblée de 16 s, sans relecture complète.
- Vérification fraîche complète par le manager : `ISSUES FOUND`, 1 bloquant (sémantique de `VF_PANNEAU.empiler`
  contraire au contrat P80-C76-5), 5 avertissements (diffs mesurés sans base fixée, signature de `definitionsRegistre`
  divergente entre 76-02 et 76-04, témoin T9.5 vert des deux côtés, champs projetés dans `cockpit-project@1` sans
  témoin de chemin du poste, 11 fichiers en 76-06), 6 infos. Révision ciblée confiée au planificateur, puis
  vérificateur frais scopé aux plans modifiés : `VERIFICATION PASSED`, 0 bloquant, 0 avertissement (commit `1742ed24`). Ce
  second passage a relu surtout par grep et frontmatter ; la couverture TRAC-01 à TRAC-12 a été recoupée par le
  manager sur le frontmatter des huit plans (douze identifiants présents). Corrections : pile `VF_PANNEAU` constatée
  par son état (76-06, 76-07), lignes `BASE=` (76-04, 76-05), signature unique de `definitionsRegistre` (76-01, 76-02,
  76-04), T9.5 rendu rougissable (M-MAX-LECTURE), module de nettoyage `vf-cockpit-trace-texte.mjs` déplacé en 76-04
  avec témoin T9.9 sur le graphe Projet, dépassement de fichiers de 76-06 accepté, infos fermées.

## Carte des fichiers

Chemins relatifs à `plugin/cockpit/` sauf mention. Toutes les vagues s'exécutent **après** la première vague de la
Phase 79 ; les vagues 4 et 5 **après** la Phase 80 exécutée.

| Plan | Vague | Exigences | Fichiers créés ou modifiés | Prérequis inter-phases |
|---|---|---|---|---|
| 76-01 Chaîne d'exigences (fonctions pures) | 1 | TRAC-01, 02, 03, 04, 11 | créés : `scripts/vf-cockpit-frontmatter.mjs`, `vf-cockpit-trace-ledger.mjs`, `vf-cockpit-trace-collecte.mjs`, `vf-cockpit-trace-chaine.mjs`, `vf-cockpit-trace-bilans.mjs`, `scripts/tests/test-cockpit-tracabilite-chaine.sh` ; modifié : `scripts/vf-cockpit-avancement.mjs` | aucun |
| 76-02 Décisions | 1 | TRAC-05, 06 | créés : `scripts/vf-cockpit-registres.mjs` (sauf si la 73 l'a livré), `vf-cockpit-trace-git.mjs`, `scripts/tests/test-cockpit-tracabilite-decisions.sh` | aucun |
| 76-03 Mémoire des agents | 2 | TRAC-07, 08 | créés : `scripts/vf-cockpit-trace-memoire.mjs`, `vf-cockpit-trace-memoire-git.mjs`, `scripts/tests/test-cockpit-tracabilite-memoire.sh` | aucun |
| 76-04 Branchement dans la collecte | 2 | TRAC-10, 01, 03, 04, 05 | modifiés : `scripts/vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-trace-collecte.mjs`, `vf-cockpit-interface.json` ; créés : `scripts/vf-cockpit-trace-texte.mjs`, `scripts/tests/test-cockpit-tracabilite-collecte.sh` | 79 première vague, plan 79-09 (instantané, A31, A32) |
| 76-05 Route `GET /api/vf/tracabilite` | 3 | TRAC-10, 11, 05, 06, 07 | créés : `scripts/vf-cockpit-trace.mjs`, `vf-cockpit-trace-vues.mjs`, `scripts/tests/test-cockpit-tracabilite-route.sh` ; modifiés : `scripts/vf-cockpit-server.mjs` (une ligne de table), `vf-cockpit-interface.json`, `README.md` | 79 première vague (A10, A11, aide de lancement 79-02) |
| 76-06 Page : phase, preuves, Jalon, exigence | 4 | TRAC-01, 02, 03, 04, 09, 11 | créés : `skills/cockpit-moteur/assets/ui/74-vf-trace.js`, `74-vf-trace-rendu.js`, `74-vf-trace-sections.js`, `74-vf-trace-style.js`, `74-vf-trace-exigence.js`, `74-vf-trace-liste.js`, `scripts/tests/test-cockpit-tracabilite-page.sh`, `chrome-tracabilite.mjs`, `chrome-tracabilite-exigence.mjs` ; modifié : `skills/cockpit-moteur/VENDORED.txt` | Phase 80 exécutée (P80-C76-1 à 5), 79 entière (A30 `surOnglet`, A13) |
| 76-07 Page : Décisions, Mémoire, panneaux | 5 | TRAC-05, 06, 07, 08, 09, 11 | créés : `ui/74-vf-trace-decisions.js`, `74-vf-trace-memoire.js`, `scripts/tests/test-cockpit-tracabilite-panneaux.sh`, `chrome-tracabilite-panneaux.mjs`, `chrome-tracabilite-memoire.mjs` ; modifiés : `ui/74-vf-trace.js`, `74-vf-trace-liste.js`, `74-vf-trace-style.js`, `VENDORED.txt` | idem 76-06 |
| 76-08 Retrait du nœud `.req`, clôture | 6 | TRAC-12 | modifiés : `scripts/vf-cockpit-project.mjs`, `vf-cockpit-types.mjs`, `vf-cockpit-ask.mjs`, `scripts/tests/test-cockpit-projet-graphe.sh`, `test-cockpit-questions.sh`, `CHANGELOG.md` ; hors module : `README.md`, `README.fr.md` (compteur de suites), `scripts/ci-shard-suites.sh` | 79 première vague (C6, `amont/` retiré) |

Chaque plan écrit aussi sa trace rouge `76-0N-RED-TRACE.md` dans le dossier de phase.

**Fichiers partagés avec d'autres phases** (en tête de la jointure) :

| Fichier | Phases qui le touchent | Plan de la 76 |
|---|---|---|
| `scripts/vf-cockpit-planning.mjs` (lecture du planning de la collecte) | 79, 80, 75 | 76-04 |
| `scripts/vf-cockpit-project.mjs` | 80, 75, 77 | 76-04, 76-08 |
| `scripts/vf-cockpit-interface.json` (contrat de forme) | 73, 74, 75, 77, 79 | 76-04, 76-05 |
| `scripts/vf-cockpit-server.mjs` (table des routes, une ligne alphabétique ; voisines `/api/vf/activite` de la 75, `/api/vf/methode` de la 77) | 79, 73, 75, 77 | 76-05 |
| `scripts/vf-cockpit-avancement.mjs` (extraction de `ligneStatutRecette`, `recetteFaite`) | 80 | 76-01 |
| `scripts/vf-cockpit-ask.mjs`, `test-cockpit-questions.sh` | 79 (79-01) | 76-08 |
| `scripts/vf-cockpit-registres.mjs` | 73 (file des arbitrages) | 76-02 |
| `skills/cockpit-moteur/VENDORED.txt` | 79 (C6), 80, 73, 74 | 76-06, 76-07 |
| `CHANGELOG.md` du module, `README.md` du module, README racine (compteur de suites), `scripts/ci-shard-suites.sh` | toutes les phases qui ajoutent une suite | 76-05, 76-08 |
| Dictionnaire de traduction (`ui/78-…`, `79-…`, `80-vf-fr.js`) | — | non touché (libellés écrits en français) |
| `viewer.html`, `ui/00-vibeflow.js` | 79, 80 | non touchés |

**Ce que la 76 attend** : de la 79, première vague (table des routes A10, réponse gardée A11, `amont/` retiré, aide de
lancement des suites), plan 79-09 (`vf-cockpit-instantane.mjs`), A12, A13, A30, A31, A32 ; de la 80, P80-C76-1 à 5
(`addPanelSection`, `select`/`reveal`, `VF_PANNEAU.retour`/`empiler`, `piedExigences` et `exigences {faits,total}`).
**Ce qu'elle fournit** : à la 73, l'extracteur de définitions des registres ; à la 77, les compteurs de la mémoire par
la route (P76-D-23) ; à la 80, rien de neuf sur la carte de phase (le compte reste `piedExigences`).

## À Samuel

Questions qui ne bloquent rien ; l'arbitrage en vigueur tient et les plans sont bâtis dessus (texte complet :
`76-CONTEXT.md` § À Samuel).

- **A-1 — « Les trous en rouge » (but du 2026-11-03) face à Q9 (ni couleur d'alerte).** Recommandation : absence en
  glyphe et mot neutres, trait corail (octogone au trait, non plein) pour les seules contradictions lues.
- **A-2 — « Graphe navigable » réalisé sans dessin.** Recommandation : panneaux reliés, voisinage seul.
- **A-3 — Poids ajouté à la page Projet.** La règle A32 de la 79 impose que les manques du planning (maillons,
  définitions de décisions, preuves) entrent dans `cockpit-project@1` ; le planificateur estime environ 0,4 Mo de JSON
  de plus. En vigueur : A32. Options : (a) garder et mesurer à l'exécution ; (b) une exception à A32 pour les
  définitions de décisions, lues par la route. Recommandation : (a), mesure écrite dans la trace de 76-04.

## À verser par la jointure

Texte exact à poser par la session principale.

1. **ROADMAP, checklist (ligne de la Phase 76)** : `- [ ] Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire (inscrite 2026-11-03, jalon vibeflow-v2.0 ; cadrée et planifiée 2026-11-11, 8 plans)`.
2. **ROADMAP, table `## Progress`** (si les phases planifiées y figurent) : `| 76. Traçabilité au cockpit | vibeflow-v2.0 | 0/8 | Planned — cadrée 2026-11-11, TRAC-01..12 |`.
3. **REQUIREMENTS** : retirer les deux repères de la Phase 76 ; compteurs de couverture du jalon : + 12 exigences `TRAC`.
4. **REGISTRE.md de l'audit**, ligne AUDC-I33 : état `ouvert — planifié en Phase 76 (76-01, 76-04, 76-06), 2026-11-11`.
5. **REGISTRE.md § 3**, ligne à ajouter : `| Le nœud « Exigences » du graphe Projet et ses cartes d'exigence | la section « Traçabilité » du panneau de phase | Phase 76 |`.
6. **BACKLOG**, sujet neuf : « `check-method-budget.sh` (`rangement_memoires`) juge une mémoire « hors index » par
   sous-chaîne (`grep -qF` du nom de fichier) : `a.md` est trouvé dans `xa.md`. Le cockpit (Phase 76) juge par égalité
   exacte. À aligner. »
7. **Phase 80** (pour sa jointure) : recoupement entre le retrait du nœud « Exigences » (P76-D-25) et AUDC-I25 (bascule
   liste où « les exigences se lisent comme une liste à cocher ») : la liste à cocher de la 80 lit le champ
   `meta.vf.trace.exigences` posé par la 76, pas le nœud retiré.
8. **Phase 73** : si elle livre `scripts/vf-cockpit-registres.mjs` avant la 76, la signature attendue est
   `definitionsRegistre(txt, { phase, ws, fichier, couper })`, `phase` étant l'identifiant de nœud (`ph-<N>`).

## Limites

- `gsd-ui-checker` jamais lancé (limite de sous-agents simultanés, trois refus) : l'UI-SPEC n'a été jugée que par
  deux `vf-design-judge` frais.
- Les contrats de la 79 et de la 80 sont figés mais non exécutés : chaque plan marque « à revalider » ce qui en dépend ;
  avant exécution, les huit plans repassent devant un vérificateur frais contre la base qui porte la 79 et la 80
  (P76-D-28).
- Les mesures de volumes (exigences, décisions, mémoire) viennent de ce dépôt seul.
- `check-version-sync.sh` § 9 (compteur des suites) restera rouge entre les plans 76-01 et 76-08 : écart assumé dans
  chaque plan.
- Trois agents ont écrit à la racine du scratchpad partagé (`g.txt`, `79.md`, `80.md`) au lieu de `phase-76/` ; non
  supprimés, faute de pouvoir les distinguer des fichiers d'une autre mission.
- Un fichier de mémoire modifié sur place, sans commit, ne change ni HEAD ni la date de son dossier : le cache de la
  route ne le voit qu'au changement suivant (écrit dans l'encart de 76-05, décision P76-D-06 non rouverte).

## Coût

Dispatches : 12 lancements (3 éclaireurs, 3 panels, 3 vf-coder, 2 vf-design-judge, 1 gsd-plan-checker) et 5 reprises de
correction par SendMessage (UI-SPEC ×2, plans ×1, plus 3 messages d'information) ; 6 lancements refusés pour
saturation. Jetons des sous-agents (somme des blocs reçus, sans le manager) : 2 144 605 — éclaireurs 385 362, panels 169 299,
UI-SPEC 470 333 (trois passes), recherche 154 207, critiques 194 271, plans 498 601 (écriture et révision),
vérification fraîche 272 532.

## Preuves E6

Format : verdict — commande — code de sortie — SHA. Mission de cadrage : aucune suite de tests n'est jouée (aucun code).

- Job `gates` de ci.yml, étapes 1 à 20 rejouées une à une sous `bash -e` (étapes 21 et 24 réservées au push sur main,
  23 demande une installation npm réseau, non jouée) — rc 0 pour les 20 — `608db651`.
- STATE intouché — `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` —
  rc 0 — `608db651`.
- Couverture des exigences — union des `requirements:` du frontmatter des huit plans = TRAC-01 à TRAC-12 — `1742ed24`.
- Vérification fraîche complète des plans (`gsd-plan-checker`) — ISSUES FOUND (1 bloquant, 5 avertissements) sur
  `1b77b255` ; après révision, vérificateur frais scopé — VERIFICATION PASSED — `1742ed24`.
- Critique de design de l'UI-SPEC (`vf-design-judge`, frais à chaque tour) — 75/100 gaps_found sur `2baf53e6`,
  73/100 passed sur `d0117b6b`, majeurs fermés en `7301d271`.
- Famille `TRAC` libre — `rtk proxy grep -rIl 'TRAC-[0-9]' .planning plugin docs` — rc 1 (aucune occurrence) — `f763b556`.

```json
{
 "preuves": [
  {"verdict": "gate:ci-gates-1-20", "commande": "étapes 1 à 20 du job gates de .github/workflows/ci.yml, bash -e, une par une", "exit_code": 0, "sha": "608db651"},
  {"verdict": "state-intouche", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "608db651"},
  {"verdict": "plans-verifies", "commande": "gsd-plan-checker frais (complet puis scopé à la révision)", "exit_code": 0, "sha": "1742ed24"},
  {"verdict": "ui-spec-critique", "commande": "vf-design-judge frais, 73/100 passed", "exit_code": 0, "sha": "d0117b6b"},
  {"verdict": "famille-trac-libre", "commande": "grep -rIl 'TRAC-[0-9]' .planning plugin docs", "exit_code": 1, "sha": "f763b556"}
 ]
}
```

## Prochaine étape

Exécuter la Phase 76 après la Phase 79 (première vague et 79-09) et la Phase 80, en commençant par une
re-vérification fraîche des huit plans contre cette base, puis les vagues 1 à 6.
