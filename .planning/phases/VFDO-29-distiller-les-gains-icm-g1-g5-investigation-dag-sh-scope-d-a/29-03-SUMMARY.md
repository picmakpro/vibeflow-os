---
phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
plan: 03
type: execute
status: done
---

# 29-03 SUMMARY — G1 (anti-chargement déclaré) + G5 (édition-à-la-source)

## Ce qui a été livré

**Tâche 1 (tracer)** — `plugin/dev-orchestrator/references/mission-contracts.md` :
- Bullet `- NE charge PAS : <périmètres gelés des autres nœuds en vol, dérivés de `dag.sh status
  --frozen`>` ajoutée au gabarit `DIGEST`, immédiatement après la bullet de périmètre positif.
- Sous-section « Composition du négatif (bullet « NE charge PAS », G1) », 14 lignes, avant la
  clause de clôture existante (inchangée, toujours dernière du bloc digest) : source des données
  (périmètre du nœud + `dag.sh status --frozen`), opération (soustraction), qui compose (le
  manager, en doctrine, aucun code neuf), deux cas dégénérés (aucun nœud gelé / table
  indisponible), statut de cache assumé.
- **Zéro ligne touchée dans `plugin/conductor/scripts/dag.sh` ni sa suite** (D-03) — voie
  doctrine-seule établie par 29-01, confirmée suffisante.
- Commit `0c1e2d0`.

**Tâche 2 (auto)** — `plugin/reference/content/methodology/patterns/03-agents.md` (+ miroir
`docs/reference/methodology/patterns/03-agents.md`) :
- Sous-section « Ce que l'agent ne charge pas » avec table `| Tache | Charge | NE charge PAS |`
  (3 exemples fictifs, exclusions nommées précisément — jamais de catégorie vague).
- 1 puce ajoutée à « Regles d'or » (5e), 1 anti-pattern ajouté à « Anti-patterns » (5e).
- Convention non accentuée du fichier respectée ; non-ASCII passé de 14 à 15 lignes (+1, sous le
  plafond de +2).
- Miroir `docs/` mis à jour à l'octet (`cmp -s` → identique). Ce fichier `docs/reference/` est
  **gitignore** (`.gitignore:21`) — hors suivi git, donc absent du diff `git`, mais bien tenu
  identique sur disque, vérifié après commit.
- `plugin/reference/content/methodology/patterns/README.md` résume `03-agents.md` en une phrase
  générique (« Specialistes a mandat clair, jamais "couteau ... ») qui reste valide sans
  modification — non touché, hors périmètre de ce plan, constat consigné ici comme prévu.
- Commit `8fb618d`.

**Tâche 3 (auto)** — G5 :
- `plugin/conductor/references/team-kernel.md` §Règles d'instanciation : 1 puce (9 lignes) —
  seuil chiffré (deux occurrences du même verdict sur le même objet), énumération des sources
  légitimes (`CLAUDE.md`, référence de doctrine, gabarit du digest, mandat — jamais le worker),
  citation ADR-031 + comportement en mission autonome (consigner, pas amender en silence), lien
  vers les registres de learnings existants.
- `plugin/dev-orchestrator/references/mission-flow.md` — 1 ligne de renvoi ajoutée dans la boucle
  de correction de la revue (Pattern E §2), sans reformuler la règle.
- Aucun agent au plafond touché : `vf-dev-manager.md` et `plugin/validator/AGENT.md` restent à
  250/250.
- Commit `c27fc49`.

## Vérifications rejouées (réelles, en fin de mandat)

| Commande | Résultat |
|---|---|
| `bash plugin/conductor/scripts/tests/test-dag.sh` | rc=0, **99 PASS / 0 FAIL** |
| `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | rc=0, **184 OK / 0 KO / 0 SKIP** |
| `git diff --name-only main...HEAD -- plugin/conductor/scripts/dag.sh plugin/conductor/scripts/tests/test-dag.sh` | **vide** (0 ligne) |
| `cmp -s plugin/.../03-agents.md docs/.../03-agents.md` | **identique** |
| `wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md plugin/validator/AGENT.md` | **250 et 250** |
| `grep -c '^- NE charge PAS' mission-contracts.md` | **1** |
| `grep -rn "Interpretable Context Methodology\|méthodologie ICM\|label ICM" plugin/ docs/` | **0 ligne** |

## Zones grises / points pour le manager

- Aucune (aucun `checkpoint:decision` déclenché — la voie doctrine-seule a suffi de bout en
  bout, comme établi par le rapport d'investigation 29-01).
- Note factuelle sans action requise : `docs/reference/` est gitignoré dans ce dépôt (une
  vérification `cmp -s` future ne se voit donc jamais dans `git diff`/`git status` — normal, pas
  un défaut introduit par ce plan).
- Aucun `estimate:`/`actuals:` — le `PLAN.md` 29-03 ne portait qu'un `estimate:` initial
  (`tokens: 60000, tasks: 3, confidence: low`) sans que le protocole d'exécution outillé
  (`gsd-execute-phase`) ait été invoqué pour ce mandat (exécution directe des `<task>` du plan,
  conformément au mandat reçu) — aucun `actuals:` n'a donc été produit à recopier.
