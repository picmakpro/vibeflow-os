---
phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
plan: 05
type: execute
status: terminé — tâche 3 (checkpoint humain bloquant) RENDUE et APPROUVÉE par Samuel le 2026-08-15
---

# 29-05 SUMMARY — Câblage du gate + clôture de distribution (tâches 1-2-3)

**Tâche 3 (`checkpoint:human-verify`, gate=`blocking`) RENDUE et APPROUVÉE.** Samuel a tranché le
2026-08-15 (checkpoint T-29-05-3) :

1. **Le gate `check-map-drift.sh` est UTILE**, à condition de resserrer 2 bornes : (a) une ligne de
   commande citée en exemple dans un `CLAUDE.md` n'est pas un chemin déclaré (P1 sens 1) ; (b)
   `plugin/reference/content/examples/` (cartes volontairement fictives d'un exemple pédagogique)
   est exclu du balayage. Les deux bornes ont été appliquées (commits `8cf5198`, `423671f`) — le
   gate rend désormais **exactement 3 findings** sur ce dépôt (`docs`, `manual`, `reports` non
   cités par `./CLAUDE.md`), tenus pour **légitimes et assumés**, non corrigés (ADR-031).
2. **`docs/_transverse/` supprimé** : vibeflow-os est le repo de distribution, pas un lab —
   ADR-042 (qui régit ce dossier) ne s'y applique pas.
3. **`.planning/config.json` → `parallelization.skip_checkpoints: false`** (commit `8cbf71b`) —
   3e vecteur d'auto-approbation de checkpoint neutralisé.

Le registre STRIDE a été enrichi de `T-29-02-08` (oracle d'existence par traversée `../` en
`p2_sens_a`, mitigation `../` initial appliquée, résidu non-initial accepté en risque `low`).

**Aucun finding du gate n'a été corrigé automatiquement à aucun moment de ce cycle — ADR-031 tenu
de bout en bout** : les 3 findings restants sont présentés tels quels, jamais soldés en silence.

Sortie finale du gate, preuve du verdict rendu :

```
$ bash plugin/conductor/scripts/check-map-drift.sh --path .
[map-drift] 3 divergence(s) sur 2 carte(s) balayée(s).
  - ./CLAUDE.md : élément suivi non cité — docs
  - ./CLAUDE.md : élément suivi non cité — manual
  - ./CLAUDE.md : élément suivi non cité — reports
            → propose de mettre à jour la carte, ou de créer/retirer l'élément manquant.
$ echo "code de sortie : $?"
code de sortie : 0
```

`.planning/ROADMAP.md` et le statut de phase relèvent du manager — non touchés par ce nœud
d'exécution.

## Ce qui a été livré

**Tâche 1 (tracer)** — `plugin/validator/AGENT.md` :
- Item 4 ajouté à la délégation séquentielle de la Phase 3 (dette documentaire) : drift
  carte↔disque (9e signal), invocation réelle `bash .claude/scripts/check-map-drift.sh --path .`
  (advisory), remontée en dette consolidée, jamais de correctif (ADR-031).
- Ligne ajoutée à la table « Délégations strictes ».
- Coût de densité **nul** : retrait compensatoire pris exclusivement sur le rapport d'exemple de
  la §Output standard (fusion de bullets Phase 1/Phase 4, commentaire HTML sur une ligne, ligne
  « Prochaine session » compactée) — aucun signal, aucune Iron Law, aucune ligne de table de
  délégation retirée. Pré-requis installation : demi-phrase remplacée, pas de ligne ajoutée.
- `wc -l` : 250 avant, 250 après.
- Commit `04149f3`.

**Tâche 2 (auto)** — 4 triades de module + compteurs re-dérivés :
- **validator** v1.3.2 → **v1.3.3** (patch — câblage d'un signal dans une procédure existante).
- **conductor** v1.21.1 → **v1.22.0** (minor — `check-map-drift.sh` neuf + extension
  `scaffold-docs.sh` : CONTEXT.md de compartiment, `--index`).
- **dev-orchestrator** v2.13.1 → **v2.14.0** (minor — bullet contractuelle « NE charge PAS »
  portée par tout mandat désormais, doctrine d'édition-à-la-source référencée).
- **reference** v2.5.2 → **v2.5.3** (patch — addition doctrinale dans un pattern existant, pas un
  nouveau pattern).
- Chaque triade (`VERSION`/`module.json`/en-tête `README.md`) porte la même valeur ; une entrée
  CHANGELOG neuve par module, datée du jour, dit le fait et sa borne (celle du gate cite
  explicitement « advisory » et ADR-031).
- Compteur « N suites » de `README.md` et `README.fr.md` re-dérivé par
  `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` → **54** (52 → 54, exactement
  les deux suites neuves de 29-02 `test-check-map-drift.sh` et 29-04 `test-scaffold-docs.sh`) —
  jamais recopié ni incrémenté à la main. Seule cette ligne touchée dans les deux README ;
  l'historique de release (tableau des versions) reste inchangé.
- Commit `6897d59`.

## Vérifications rejouées (réelles)

| Commande | Résultat |
|---|---|
| `wc -l plugin/validator/AGENT.md` | **250** |
| `wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md` | **250** (non touché) |
| `bash plugin/conductor/scripts/check-agents.sh --strict --file plugin/validator/AGENT.md` | rc=**0**, 2 warnings préexistants (nom de fichier, tools absent — non liés à cet exec) |
| `grep -c "check-map-drift" plugin/validator/AGENT.md` | **3** |
| Invocation rejouée (`check-map-drift.sh --path .`) | rc=**0** (divergences réelles constatées, jamais 64) |
| `bash scripts/check-version-sync.sh` | rc=**0**, 17 modules, 9 points de gate verts |
| `find plugin scripts -path '*/tests/test-*.sh' \| wc -l` vs README.md vs README.fr.md | **54 == 54 == 54** |
| `git diff --name-only -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json` | **vide** |
| `git diff --name-only -- plugin/conductor/scripts/dag.sh plugin/conductor/scripts/tests/test-dag.sh` | **vide** |
| `grep -rn "Interpretable Context Methodology\|méthodologie ICM\|label ICM" plugin/ docs/` | **0 ligne** |
| `git diff --name-only HEAD~2 HEAD` (mes 2 commits seuls) | 18 fichiers, tous dans le `files_modified` du plan — aucun `.planning/` |

Note sur `.planning/` : un `git diff --name-only main...HEAD -- .planning/` plus large (hors filtre)
remonte des fichiers de la Phase 28 — c'est l'historique préexistant de la branche
`docs/phase-29-icm-gains`, pas une modification de ce mandat. Vérifié isolément sur mes 2 commits
(`HEAD~2 HEAD`) : zéro fichier `.planning/` touché.

## Collecte read-only pour le checkpoint humain (tâche 3, EN ATTENTE)

Sortie brute intégrale de `bash plugin/conductor/scripts/check-map-drift.sh --path .` — **aucun
finding corrigé, présentée telle quelle (ADR-031)** :

```
[map-drift] 13 divergence(s) sur 3 carte(s) balayée(s).
  - ./CLAUDE.md : entrée déclarée sans contrepartie — bash scripts/check-release-tag.sh --remote
  - ./CLAUDE.md : entrée déclarée sans contrepartie — git config core.hooksPath scripts/hooks
  - ./CLAUDE.md : élément suivi non cité — docs
  - ./CLAUDE.md : élément suivi non cité — manual
  - ./CLAUDE.md : élément suivi non cité — reports
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : entrée déclarée sans contrepartie — content/CONCEPTS.md
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : entrée déclarée sans contrepartie — content/IDEAS.md
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : entrée déclarée sans contrepartie — eleves/factures
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : élément suivi non cité — docs
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : élément suivi non cité — manual
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : élément suivi non cité — plugin
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : élément suivi non cité — reports
  - ./plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md : élément suivi non cité — scripts
            → propose de mettre à jour la carte, ou de créer/retirer l'élément manquant.
```

Code de sortie : **0**.

## Zones grises / point pour le manager

- Aucun `checkpoint:decision` déclenché en tâches 1-2 — les deux tâches se sont dérivées
  directement des instructions du plan.
- La tâche 3 reste intégralement à faire : présenter cette collecte à Samuel, obtenir son verdict
  « approuvé » ou ses ajustements de bornes, sans jamais corriger un finding en exécution.
- Aucun `estimate:`/`actuals:` à recopier : ce mandat a exécuté directement les `<task>` du plan
  (mandat de correction/exécution ciblée), sans passer par le protocole outillé
  `gsd-execute-phase` — aucun `actuals:` n'a donc été produit.
