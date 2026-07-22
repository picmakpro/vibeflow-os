# Mission-flow — discipline de pilotage swarm (ADR-053)

> Source de vérité des 3 patterns de sûreté du contrôle de flux de mission. Le `vf-dev-manager` s'y
> conforme ; les workers appliquent le **contrat de rapport typé** (Pattern C). Réalisé par **fichiers
> d'état + discipline** (pas de bus temps réel — hors runtime Claude Code). Scripts : `.claude/scripts/driver-lock.sh`,
> `.claude/scripts/dag.sh`.

---

## Pattern A — Lock de driver unique (anti-collision de pilotage)

Empêche deux missions/sessions de piloter la **même étape** en parallèle (corruption des backups isolés
ADR-048/049). Acquisition **atomique** (`mkdir`). Le manager est l'unique porteur du lock pour sa mission.

**Protocole (obligatoire) :**

1. **Acquérir AVANT de planifier/dispatcher** — dès que la mission est cadrée, avant le premier worker :
   ```bash
   .claude/scripts/driver-lock.sh acquire --owner="<session_id|task_id>" --step="<étape ou 'mission'>"
   ```
   - `acquired: true` → piloter. `acquired: false` (`held_by`) → **une autre mission pilote déjà** :
     ne pas dispatcher, remonter à l'humain (ou attendre). `recovered: true` → un lock périmé a été
     élagué (le porteur précédent est mort) ; consigner la reprise dans `STATE.md ### Decisions`.
2. **Heartbeat ENTRE les étapes** — à chaque relecture ROADMAP/STATE entre deux étapes :
   ```bash
   .claude/scripts/driver-lock.sh heartbeat --owner="<id>"
   ```
   Sans heartbeat frais, le lock est considéré périmé après `VF_DRIVER_TTL` (défaut 1800 s).
3. **Relâcher À LA CLÔTURE — succès, échec OU abandon** (release « RAII » porté par le prompt) :
   ```bash
   .claude/scripts/driver-lock.sh release --owner="<id>"
   ```
   Le release est un **geste de sortie garanti**, jamais conditionnel. C'est la dernière action avant le
   rapport de mission.

**Récupération de claim périmé (filet obligatoire)** : un agent LLM peut mourir sans release. Le TTL +
heartbeat est le seul filet — d'où `acquire` qui **élague et ré-acquiert** un lock dont le heartbeat
dépasse le TTL. Ne jamais forcer un `release` d'un owner tiers ; utiliser `recover` (qui refuse si le lock
est encore frais).

---

## Pattern B — DAG de tâches (frontière ready/blocked + ré-entrée)

Le plan de bataille n'est plus une liste ordonnée : c'est un **graphe persistant**
(`.planning/missions/<date>-<sujet>.dag.json`). Le manager **ne dispatche que la frontière `ready`**.

**Protocole :**

1. **Construire le graphe** au moment du plan de bataille (un nœud par étape/étage, `deps` explicites) :
   ```bash
   .claude/scripts/dag.sh init --file="$DAG"
   .claude/scripts/dag.sh add  --file="$DAG" --id=cadrage --step="cadrage étape 9"
   .claude/scripts/dag.sh add  --file="$DAG" --id=code --step="dev" --deps=cadrage
   .claude/scripts/dag.sh add  --file="$DAG" --id=revue --step="revue" --deps=code
   ```
   Collision d'id → remap déterministe `id::stage` (pas d'échec).
2. **Dispatcher la frontière** — au lieu de dérouler linéairement :
   ```bash
   .claude/scripts/dag.sh ready --file="$DAG"     # → liste des nœuds dispatchables MAINTENANT
   ```
   Marquer `running` au dispatch, `done`/`failed` au retour du worker :
   ```bash
   .claude/scripts/dag.sh mark --file="$DAG" --id=code --status=done   # promeut les blocked dont deps sont done
   ```
3. **Ré-entrée** — un correctif remonté par la revue/l'audit qui **rouvre** une étape :
   ```bash
   .claude/scripts/dag.sh reopen --file="$DAG" --id=code   # code + ses dépendants (revue…) repassent blocked/ready
   ```
   Le manager **ré-entre** alors dans la boucle `ready → dispatch` au lieu de continuer tout droit. C'est la
   boucle `fix → re-revue` de `vf-coder` rendue explicite et robuste.

---

## Pattern C — Contrat de rapport de worker typé

Les workers (`vf-coder`, `vf-reviewer`, `vf-auditer`, `vf-test-orchestrator`) **terminent leur retour** par
un bloc typé (en plus de leur prose), pour un contrôle de flux **déterministe** côté manager :

```json
{
  "statut": "passed | gaps_found | human_needed | blocked",
  "findings": [
    { "severity": "bloquant | majeur | mineur", "action": "auto-fix | no-op | ask-user", "ref": "fichier:ligne" }
  ],
  "noeuds_debloques": ["<id de nœud DAG à passer done, s'il y a lieu>"]
}
```

- **`statut`** s'aligne sur les verdicts de `*-VERIFICATION.md` : `passed` (feu vert), `gaps_found` (manques
  à combler → le manager relance un cycle), `human_needed` (escalade), `blocked` (dépendance non satisfaite).
- **`action`** par finding (taxonomie ADR-031 raffinée, note §6.2) : `auto-fix` (mécanique, le coder applique
  seul), `no-op` (informatif), `ask-user` (**défie l'intention/la logique/la sécurité → escalade obligatoire,
  jamais tranché seul**).
- **`noeuds_debloques`** : les nœuds DAG que ce retour permet de marquer `done` → le manager fait
  `dag.sh mark` puis re-dispatche la nouvelle frontière.

**Contrôle de flux du manager** (déterministe, plus d'interprétation de prose) :
`passed` → `mark done` + frontière suivante · `gaps_found` → `reopen`/relance de comblement ·
`human_needed` ou finding `ask-user` → **escalade humaine** · `blocked` → laisser `blocked`, traiter la dep.

---

## Lignes rouges (rappel ADR-053)

Pas de bus UDS / channels / `dm` temps réel (modèle `Task` = dispatch-and-join). Pas de RAII machine : le
release dépend du prompt → la **récupération de claim périmé est obligatoire**, pas optionnelle.
