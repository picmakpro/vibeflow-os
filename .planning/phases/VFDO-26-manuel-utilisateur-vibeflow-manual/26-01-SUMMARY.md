# 26-01 — Summary

**Statut : DONE** (repris tel quel — l'infrastructure avait déjà été posée par le mandat coupé,
vérifiée ici par exécution, pas par lecture).

## Artefacts

- `manual/toc.yml` — amorcé, `themes:` et `pages:` vides, en-tête conforme (ordre des 7 thèmes D-05,
  disposition 2 niveaux D-02, invariant H-1/H-2).
- `manual/README.md` — seul fichier bilingue, 8 lignes, exactement 2 liens (`./fr/README.md`,
  `./en/README.md`), aucun numéro de version.
- `manual/.tools/build-nav.sh` — exécutable, `bash -n` OK, portable bash 3.2/5.
- `manual/.tools/check-manual.sh` — exécutable, `bash -n` OK, 7 contrôles C0-C6.
- `manual/fr/`, `manual/en/`, `manual/.tools/` créés.

## Vérifications automatisées (task 1 + task 2), rejouées intégralement

- Task 1 : tous les tests du bloc `<verify>` passent (`OK`) — fichiers présents, `toc.yml` à 0 entrée,
  2 liens dans `manual/README.md`, `git status --porcelain -- manual` vide.
- Task 2 : `build-nav.sh` sur fixture 2 pages × 2 langues — idempotence prouvée (`diff -r` vide après
  2 passes), première page sans « Précédent », dernière sans « Suivant », sélecteur de langue au 2ᵉ
  segment, sommaire des README de langue peuplé.

## Task 3 — les six verdicts de fixture (prouvés par mutation, pas par lecture)

Fixture nominale : 2 thèmes × 2 pages × 2 langues, régénérée par `build-nav.sh`.

| Scénario | Verdict attendu | Verdict obtenu |
|---|---|---|
| Nominal (arbre valide, régénéré) | 0 | **0** — les 7 contrôles ✓ |
| Mutation 1 — page `en` supprimée | 1, C1 (isomorphisme) | **1** — C1 ✗ (cascade attendue en C2/C3/C4, même défaut sous-jacent) ; restauré → nominal repasse à 0 |
| Mutation 2 — page orpheline sur disque, absente de `toc.yml` | 1, C2 | **1** — C2 ✗ seul, message nommant `orphan.md` ; restauré → nominal repasse à 0 |
| Mutation 3 — lien relatif mort injecté | 1, C3 | **1** — C3 ✗ seul, message nommant le lien mort |
| Mutation 4 — deux entrées `toc.yml` permutées sans régénérer | 1, C4 | **1** — C4 ✗ seul (diff détecté par rejeu) |
| Arbre totalement vide (`fr/`, `en/` vides, `toc.yml` sans pages) | 1, C0 | **1** — C0 ✗, verdict vide refusé explicitement |

Chaque mutation a été isolée (une seule à la fois), vérifiée en échec, puis restaurée avant la
suivante — les scénarios discriminent réellement leur contrôle cible, pas de faux vert.

## État du gate sur le manuel réel à la fin de ce plan

`bash manual/.tools/check-manual.sh` (sans argument, donc sur `manual/` réel) sort en **1**, avec
deux motifs actifs à ce stade (et non un seul comme anticipé par H-3) :
- **C0** (attendu, H-3) : aucune page n'existe encore.
- **C3** (transitoire, pas un défaut de l'outillage) : `manual/README.md` référence
  `./fr/README.md` et `./en/README.md`, qui n'existent pas encore — ils sont produits par la
  task 1 du plan 26-02. Ce deuxième motif disparaît mécaniquement dès l'exécution de 26-02 et n'est
  pas une régression de ce plan : le README racine bilingue est un artefact volontaire de 26-01
  (D-01), ses cibles sont du ressort de 26-02.

Ceci sera revérifié en vert (motif disparu) à l'issue de 26-02.

## Contrainte git (D-14)

`git status --porcelain -- manual` vide à chaque point de contrôle des 3 tâches, y compris à la fin.
Aucun `git add`/`git commit` exécuté sur un chemin `manual/`. `.git/info/exclude:7` contient toujours
`manual/`, inchangé. Aucune entrée `.gitignore` créée. Aucune référence à `check-manual.sh` ou
`build-nav.sh` dans `.github/workflows/`.

## Écart au plan

Aucun. Toutes les acceptance criteria de 26-01 sont remplies, à la nuance C3-transitoire ci-dessus
qui est un effet d'ordre attendu entre plans, pas un défaut.
