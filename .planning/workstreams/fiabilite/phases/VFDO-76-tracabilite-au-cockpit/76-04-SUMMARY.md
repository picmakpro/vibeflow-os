---
phase: 76
plan: "04"
requirements-completed: [TRAC-10, TRAC-01, TRAC-03, TRAC-04, TRAC-05]
---

# 76-04 — Branchement dans la collecte : SUMMARY

## Livré

- `readPlanning(root, layout, { trace: true })` (opt-in) garde les textes des REQUIREMENTS des compartiments (`ledgers`, jamais l'archive `*`), appelle `lireTrace` sous le
  confinement déjà posé, dans un `try` (`catch` → `{ erreur: true }`), et rend `trace` (`null` sans l'option). Diff mesuré contre `BASE` : planning +9 −1, project +5 −2
  (14 ajoutées, 3 retirées : OK-DIFF-MINIMAL, seuil 24 / 8).
- `construireGraphe` lit le planning avec `{ trace: true }`, construit le graphe dans une constante et rend `projeterTrace(graphe, P.trace, { jalonActif: 'n:' + active.id,
  couper: clip, racine: root })`. Aucune autre ligne déplacée ni reformatée.
- `vf-cockpit-trace-texte.mjs` (neuf, 31 lignes) : `sansCheminPoste`, `servi` (masque des secrets avant la coupe, chemin du lab rendu relatif, autres chemins du poste
  remplacés par « un chemin hors du lab »).
- `lireTrace` garde le texte des `*-CONTEXT.md` de chaque dossier de phase (`contextes`) ; `projeterTrace` pose `meta.vf.registres` avec l'identifiant du nœud lu dans le graphe
  (clé `<ID>:<ph-id>`), compte `registresSansPhase`, passe tout texte projeté par `servi` (critères, statuts de VERIFICATION, de recette et de preuves, libellés, statuts du ledger,
  titres de définition) ; une exception de la projection rend `meta.vf.trace = { erreur: true }` sans nœud à moitié posé. Aucune règle d'identifiant de phase recopiée.
- `vf-cockpit-interface.json` : `optionnels.noeud` gagne `trace`, nouvelle clé `optionnels.metaVf` (`trace`, `registres`, `jalonActif`), `description` renvoyant à P76-D-31 ; la version ne monte pas.
- `tests/test-cockpit-tracabilite-collecte.sh` : T9.1 à T9.11, 31 assertions, garde anti-vert-à-vide.
- Contrat consommé par 76-05, 76-08, 76-09 et la Phase 80, inchangé : `meta.vf.trace.exigences[]` (`id`, `ws`, `phase`, `coche`, `libelle`, …) et `nodes[].trace.plans[]` (`fichier`, `exigences`).

## Mesures

`POIDS avant=1538945 apres=2824073 delta=1285128` (≈ 1,29 Mo brut, contre ≈ 0,4 Mo estimé au plan : trois fois plus). Détail sur ce dépôt : `nodes[].trace` 869 700 octets
(dont `plans` 819 552 : les références de plans et critères de 87 phases), `meta.vf.trace` 289 740 (585 exigences), `meta.vf.registres` 124 849 (779 définitions).
`DUREE sans=1650 avec=1775` (ms, `readPlanning` sans et avec `{ trace: true }`, poste chargé par d'autres missions).

## Écarts

- Écart : `nettoie` de `vf-cockpit-arbres.mjs` n'est pas importé, `servi` reprend `masque` et `MARGE_MASQUE` de `vf-cockpit-lecture.mjs` et la même suppression des caractères de contrôle : `arbres`
  importe `normNum` de `vf-cockpit-planning.mjs`, d'où un cycle `planning` → `trace-collecte` → `trace-texte` → `arbres` → `planning`. Aucun contrat touché.
- Écart : l'ancre de la panne injectée (T9.6) est `const traces = new Map(), vivantes = [];` et non la signature de `lireTrace` : bash 3.2 développe `{ a, b }` même entre guillemets dans `$(…)`,
  ce qui laissait la copie jetable non mutée alors que la sortie disait « muté » (corrigé avant le premier vert, noté dans le commentaire de `mutsub.mjs`).
- Écart : les trois tâches sont livrées en trois commits (test, trace rouge et branchements de la tâche 1 ; modules de la tâche 2 ; contrat de la tâche 3) et non en six : la suite complète a été
  écrite et vue rouge d'un seul bloc (22 rouges sur 31, `76-04-RED-TRACE.md`) avant le premier code.
- Écart : un ledger d'archive (clé `*`) n'est pas passé à `lireTrace` (consigne du plan) : une exigence archivée n'a pas de statut de table lu, `statut: null`.
- Le CONTEXT d'un dossier d'archive (`*|n`) se rattache au nœud de clé `|n` s'il existe, sinon il est compté `registresSansPhase`.

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — les trois mutants du plan (M-COUVERTURE, M-MAX-LECTURE, M-ABSOLU-PROJ) ne sont pas joués ; leurs cas restent en assertions simples (T9.11, T9.5, T9.9).
- rituel levé : régime allégé (même consigne) — pas de triple passe, pas de rejeu suite par suite ; plan non marqué pour audit de sécurité.

## Suites jouées (une fois, sur la tête commitée, 941 s au total, poste chargé)

| Suite | Verdict | Durée |
|-------|---------|-------|
| `test-cockpit-tracabilite-collecte.sh` | 31 passés, 0 échoués | 17 s |
| `test-cockpit-tracabilite-chaine.sh` | 66 passés, 0 échoués | 16 s |
| `test-cockpit-projet-graphe.sh` | 119 PASS / 0 FAIL | 459 s |
| `test-cockpit-questions.sh` | 133 PASS / 0 FAIL | 17 s |
| `test-cockpit-projet-croissance.sh` | 1 PASS / 0 FAIL | 307 s |
| `test-cockpit-confinement.sh` | 111 PASS / 0 FAIL | 49 s |
| `test-cockpit-vendor.sh` | 252 PASS / 0 FAIL (V4 de la base n'y rougit plus, V4c.9a verte) | 76 s |

## À verser par la jointure

Fichiers partagés : `vf-cockpit-planning.mjs` (80 : `avancement`, `exigences`, `vague` ; 75 ; ici l'import, `ledgers`, le bloc `trace`, le champ rendu), `vf-cockpit-project.mjs` (80, 75 ; la 77 retire
`lastDesc` du même `return` de `construireGraphe`, devenu `const graphe = { … }` suivi de `return projeterTrace(…)` : à reprendre dans cette forme), `vf-cockpit-interface.json` (73, 74, 75, 77, 79 :
clés ajoutées sous `cockpit-project@1`, rien réécrit). Poids du graphe Projet : voir Mesures (le plan estimait 0,4 Mo).
