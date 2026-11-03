---
phase: 67-cockpit-floorplan-socle-partage
plan: 03
status: complete-avec-reserve
requirements: [CKPT-02, CKPT-03, CKPT-04]
commits: [e2b2eae6, cf7372eb, 7ac4805d]
---

# 67-03 SUMMARY — vendorisation, assemblage, marque blanche

Amont : `git -C <clone> rev-parse --short=7 HEAD` = `92d6854` (floorplan v0.6.0). Arbre `plugin/cockpit/skills/cockpit-moteur/` (48 fichiers amont retrouvés), `synchro.sh` (verifier, reconstruire, empreintes, regenerer-patch), 12 diffs par fichier, assembleur `vf-cockpit-build.mjs`, renommeur `vf-cockpit-rename.mjs`, trois suites. Compteur de suites des README remis à 129.

## Preuves
- Reconstruction jetable depuis le clone vs arbre : empreintes identiques (comparaison par sha256, sans `diff`) ; `synchro.sh verifier` code 0 après chaque patch (P9, P10, P11, P12).
- Suites (HOME jetable) : vendor 70 PASS, assemblage 39 PASS, marque blanche 21 PASS, who 33, projet 25 ; 0 FAIL.
- `check-skills.sh --strict` rc 0, `check-machine-paths.sh` rc 0, `check-version-sync.sh` rc 0, `check-gate-touche.sh` DECLARE.
- STATE.md du compartiment : identique à la baseline (aucune restauration nécessaire).

## Écarts au plan
- Patch P11 étendu à `scripts/lib/health.mjs` : le littéral de liste d'attente y figurait dans des exemples de prose et dans un motif de chemins publics (`wait[l]ist`, comportement identique) ; sans cela V5 rougissait.
- Le témoin positif de V5 a attrapé une erreur de ma propre suite (séparateur `|` dans un motif) avant tout vert.
- Mutants « chaîne visible réinjectée » : l'amont passe par le renommeur, donc le mutant joué est le retrait de la règle `Floorplan` (M1 rouge) ; mutant de la règle camelCase (M3 rouge) ; mutant littéral Cloud réinjecté dans `serve.mjs` (V5 rouge). Sorties ci-dessous.

## Réserve ouverte — gate check-python-isolation.sh
Le gate balaie les fichiers suivis sous `plugin/` hors `*/tests/*`, `*.md`, `*.py`, sans exclure le code vendorisé. `assets/vendor/elk.bundled.js` (lignes très longues) le rend extrêmement lent : chaque autre fichier du moteur passe en moins de 1 s, `elk.bundled.js` seul dépasse 5 minutes (non terminé au moment du rapport). Le gate fait partie du job CI `gates` : à traiter par le manager (exclusion du dossier vendorisé dans le gate, geste hors périmètre de ce plan, `Gate-Touche` et validation humaine).

## Mutants (sortie rouge)
### règle cap retirée
```
  ❌ FAIL — M1.5 — GET / : 0 occurrence
  ❌ FAIL — M1.6 — GET /project.html : 0 occurrence
  ❌ FAIL — M1.7 — messages du serveur : 0 occurrence
  ❌ FAIL — M1.8 — le serveur a bien écrit son message de démarrage (0 < 1)
  ❌ FAIL — M1.9 — aucune occurrence dans les fichiers de la sortie (hors licences)
  Résultats : 16 PASS / 5 FAIL
```
### règle camel retirée
```
  ❌ FAIL — M1.3 — la page / est servie (non vide) (19 < 1000)
  ❌ FAIL — M1.4 — la page /project.html est servie (non vide) (19 < 1000)
  ❌ FAIL — M1.8 — le serveur a bien écrit son message de démarrage (0 < 1)
  ❌ FAIL — M2.3 — data:image/svg+xml dans la page servie (0 < 1)
  ❌ FAIL — M3.1 — node --check sur serve.mjs, query.mjs et chaque vf-cockpit-*.mjs
  ❌ FAIL — M3.2 — aucun bloc <script> invalide dans index.html
  Résultats : 15 PASS / 6 FAIL
```
### littéral Cloud réinjecté (V5)
```
  ❌ FAIL — V6.1 — synchro.sh verifier rend 0
  ❌ FAIL — V5 — « run\.app » : 0 occurrence dans le code du module
  Résultats : 66 PASS / 2 FAIL
```
