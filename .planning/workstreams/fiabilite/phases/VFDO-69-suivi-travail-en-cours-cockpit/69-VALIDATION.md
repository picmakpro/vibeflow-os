---
phase: "69"
slug: "suivi-travail-en-cours-cockpit"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-11-03"
---

# Phase 69 — Validation Strategy

> Contrat de validation par phase. Source : `69-RESEARCH.md` § Validation Architecture. Le tableau par tâche est complété par le planificateur.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`assert_eq`/`assert_has`/`assert_ge`), sondes node écrites par la suite, `hygiene.sh` |
| **Config file** | aucun ; découverte par `find plugin scripts -path '*/tests/test-*.sh'` |
| **Quick run command** | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite>.sh` |
| **Full suite command** | découverte complète des suites du module cockpit (liste produite par `scripts/ci-shard-suites.sh --all`, filtrée sur `plugin/cockpit/`), séquentielle, plus `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` |
| **Estimated runtime** | 20 à 60 s par suite |

## Sampling Rate

- **After every task commit:** la suite de l'exigence touchée
- **After every plan wave:** toutes les suites du cockpit (au plus 2 en parallèle)
- **Before `/gsd-verify-work`:** porte de phase rejouée depuis `ci.yml`, job `gates`, découverte complète
- **Max feedback latency:** 60 secondes

## Per-Task Verification Map

Rempli par le planificateur le 2026-11-03. Chaque commande se lance depuis la racine du dépôt, sortie redirigée vers un
fichier (jamais un tube vers `head`/`tail`), sous bash 3.2 comme sous zsh ; les commandes exactes et leur `<fails_when>`
sont dans les plans. « Témoin rouge » = l'assertion jouée rouge AVANT le code, trace conservée. Colonne « Statut »
remplie par 69-09.

| Plan | Tâche | Exigences | Commande automatisée (suite, sections) | Direction d'échec | Témoin rouge avant le code | Statut |
|------|-------|-----------|----------------------------------------|-------------------|----------------------------|--------|
| 69-01 | T1 (tracer) | CKPT-13..18 (témoins), CKPT-14 | `test-cockpit-avancement.sh` A0, A1 ; ordre des commits | FAIL A0/A1, suite interrompue, suite et code dans un même commit | (a) `11/7 plans`, (b) `todo`, (c) `missions`, (d) `0/2 phases · 0 %`, A18.1 `active` — `69-01-RED-TRACE.md` | |
| 69-01 | T2 | CKPT-13, 15, 16, 17, 18 | `test-cockpit-avancement.sh` A2-A6, A8, A18 ; `test-cockpit-projet.sh` ; `-direct.sh` ; `-questions.sh` | FAIL A2..A18 ; P1.5 resté à `1/2 phases` | témoins (b), (c), (d), règles 2-3, mutation A18 | |
| 69-01 | T3 | CKPT-13 (contrat), CKPT-17 | `test-cockpit-avancement.sh` A7 ; `-who.sh`, `-assemblage.sh`, `-vendor.sh`, `-reseau.sh`, `-chrome-fr.sh` | A7 « clé avancement absente » ; R1.5 ; V4 | A7 rouge tracé | |
| 69-02 | T1 (tracer) | CKPT-19 | `test-cockpit-equipe.sh` E0, E19.1 | E0 en FAIL (fixture) ; E19.1 vert avant le code | E19.1 `parent` = session | |
| 69-02 | T2 | CKPT-20, 21, 22, 28 | `test-cockpit-equipe.sh` E20, E21, E22, E28, EP | contrôles positifs en FAIL ; E28.1/E21.2/E22.8 verts avant le code | `fin2h` absent, aucun `rattachement`, aucune `action`, `who@1` — `69-02-RED-TRACE.md` | |
| 69-02 | T3 | CKPT-27 | `test-cockpit-forme-claude.sh` F0-F16 ; trace | F0.2/F13/F14.1-2/F15.3-4/F16.2/F16.4 en FAIL ; F1.b/F11/F14.3/F16.1 verts avant le code | F1.b..F12 `lue` au lieu de `forme-inconnue` ; F14.3 parent = session ; F15.1 forme arrêtée absente ; F16.1 lecture de vieux meta.json — `69-02-RED-TRACE.md` | |
| 69-03 | T1 (tracer) | CKPT-19, 27, 28 | `test-cockpit-equipe.sh` E19.1-3, E28.1 ; `-who.sh` | FAIL ; W5-W7/W13 rouges (lecteurs déplacés) | (69-02) | |
| 69-03 | T2 | CKPT-19, 20, 27 | `test-cockpit-forme-claude.sh` (dont F14-F16 : fenêtre, forme arrêtée, zéro lecture hors fenêtre) ; `-equipe.sh` E19, E20, E28, EP ; `-who.sh`, `-robustesse.sh`, `-securite.sh` ; mutation de la fenêtre sur copie | FAIL ; écart de mesure nommé = blocage, jamais contournement ; mutant vert = fenêtre non tenue | (69-02) | |
| 69-03 | T3 | CKPT-28 | `-serveur.sh`, `-direct.sh`, `-reseau.sh`, `-vendor.sh` ; F14-F16 ; collecte sur le poste réel < 3 000 ms | S5, D1-D5, R1.5, V4 ; F16.1 absent des PASS ; plafond dépassé | (69-02 E28, F16.1) | |
| 69-04 | T1 (tracer) | CKPT-24 | `test-cockpit-transcript.sh` T0, T24.1 | T0 en FAIL (marqueur absent de la fixture) ; T24.1 vert avant le code | « module absent » | |
| 69-04 | T2 | CKPT-25, 26 | `test-cockpit-transcript.sh` T25, T26 (mutants M-JETON, M-PORTE) | contrôles positifs (403, 405, leurre, CSP de /project.html) en FAIL ; T25.1/T25.16/T26.5 verts avant le code | 404, `mandat` émis, « fichier absent » — `69-04-RED-TRACE.md` | |
| 69-04 | T3 | CKPT-19..23 (interface) | `test-cockpit-equipe.sh` E23, EUI ; trace | E23.8 (témoin de la sonde) en FAIL ; E23.1/EUI.4 verts avant le code | 404, « fichier absent : 71-vf-equipe-rendu.js » | |
| 69-05 | T1 (tracer) | CKPT-23, 26 (CSP) | `-equipe.sh` E23.1-5, E23.9 ; `-transcript.sh` T26.0, T26.5, T26.6 ; `synchro.sh verifier` ; `-vendor.sh` | FAIL ; `verifier` exit 1/2 | (69-04) | |
| 69-05 | T2 | CKPT-23 | `-equipe.sh` E23.6, E23.8 ; `-vendor.sh` ; `-chrome-fr.sh` | FAIL ; V7 ; F2 | (69-04) | |
| 69-05 | T3 | CKPT-23, 28 | `-securite.sh` (H1, H4bis), `-reseau.sh` (R1.4, R2.1), `-serveur.sh`, `-marque-blanche.sh`, `-chaine-xss.sh`, `-assemblage.sh`, `-direct.sh`, `-onglet-code.sh` | code non nul | — | |
| 69-06 | T1 (tracer) | CKPT-22 | `-equipe.sh` E22 | secret dans `who` ou dans le hello | (69-02) | |
| 69-06 | T2 | CKPT-21 | `-equipe.sh` E21 ; `-who.sh` W12 | lien deviné ou manqué ; W12 | (69-02) | |
| 69-06 | T3 | CKPT-24 | `-transcript.sh` T0, T24 ; `-who.sh`, `-securite.sh`, `-reseau.sh` | marqueur de sortie dans la réponse ; T24.14 > 2 s | (69-04) | |
| 69-07 | T1 (tracer) | CKPT-24, 25 | `-transcript.sh` T25 ; `-serveur.sh` F3, F4 | 200 sans jeton ; marqueur dans flux/fichiers/journal/export ; mutant non vu ; F4 | (69-04) | |
| 69-07 | T2 | CKPT-25, 28 | `-securite.sh`, `-reseau.sh`, `-direct.sh`, `-questions.sh`, `-robustesse.sh`, `-chaine-xss.sh` | H1 transcript ; R1.5 | — | |
| 69-08 | T1 (tracer) | CKPT-19, 20 | `-equipe.sh` EUI.1-3, EUI.7 ; `-who.sh` W16 ; `-vendor.sh` | imbrication ; terminés dépliés ; bouton perdu ; V4/V7 | (69-04) | |
| 69-08 | T2 | CKPT-21, 22, 23, 26 | `-equipe.sh` (tout) ; `-transcript.sh` (tout) ; `-chrome-fr.sh`, `-chaine-xss.sh`, `-who.sh` | EUI.4-6, E23.7, T26.0-6 (T25 et T26.7 dépendent de 69-07 : exigées par 69-09) | (69-04) | |
| 69-09 | T1 | CKPT-13..28 (doc), bump P69-D-26 | `scripts/check-version-sync.sh` (points 6 et 8) ; `scripts/check-affirmation-non-mesuree.sh` ; triade du module à `v1.1.0` | « N suites » ≠ réel ; affirmation non mesurée ; module encore à `v1.0.0` | module à `v1.0.0` à la planification | |
| 69-09 | T2 | CKPT-13..28 | rejeu du job `gates` depuis `ci.yml` ; 21 suites du module une à une + `test-vibeflow-update-cockpit.sh` ; T26.7 exigée verte si Chrome ; `fichiersExecution` ; périmètre du diff (`awk` + témoin) ; ordre suite -> trace -> code (`merge-base --is-ancestor` + témoin) | étape ou suite à code non nul ; < 21 suites ; T26.7 absente ou rouge ; module neuf non recopié ; chemin hors périmètre ; `VERSION` racine touchée ; ordre inversé | témoins de périmètre et d'ordre | |

## Wave 0 Requirements

Les témoins rouges sont écrits avant le code de leur chantier : dans le plan 69-01 pour l'avancement (commit de tests,
puis commit de trace, puis code), dans les plans de tests seuls 69-02 (vague 1) et 69-04 (vague 2) pour l'équipe.

- [ ] `plugin/cockpit/scripts/tests/test-cockpit-avancement.sh` — CKPT-13..18 (fixtures a-d, règles de rattachement, reste, réseau, mutation A18) — 69-01
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` — CKPT-19..22, 28 (69-02) ; CKPT-23 et volets d'interface (69-04)
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh` — CKPT-27 — 69-02
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-transcript.sh` — CKPT-24..26 — 69-04
- [ ] `69-01-RED-TRACE.md`, `69-02-RED-TRACE.md`, `69-04-RED-TRACE.md` — sortie rouge (assertion, attendu, obtenu, empreinte du commit de tests) de chaque suite avant le code

## Manual-Only Verifications

Aucune comportement de la phase n'est laissé sans vérification automatisée ; la recette humaine de la phase relève de `gsd-verify-work`.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (24 tâches, chacune avec au moins une commande et son `<fails_when>` ; planification 2026-11-03)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (quatre suites neuves et trois traces, plans 69-01, 69-02, 69-04)
- [x] No watch-mode flags
- [ ] Feedback latency < 60s — tenu par suite (20 à 60 s) ; la porte de 69-09 (rejeu du job `gates`, alarme de 1 800 s) le dépasse par nature : dérogation à consigner au SUMMARY de 69-09
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
