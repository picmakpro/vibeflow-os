# Mission-flow — discipline de pilotage swarm (ADR-053)

> Source de vérité des 3 patterns de sûreté du contrôle de flux de mission. Le `vf-dev-manager` s'y
> conforme ; les workers appliquent le **contrat de rapport typé** (Pattern C). Réalisé par **fichiers
> d'état + discipline** (pas de bus temps réel — hors runtime Claude Code). Scripts : `"$S"/driver-lock.sh`,
> `"$S"/dag.sh`.

---

## Résolution des scripts (`$S`) — scope-robuste (user OU projet)

Un lab est installé sous **un seul** scope (ID4 : user → `$HOME/.claude`, project/local → `./.claude`).
Les scripts vivent donc là où le module a été posé — **jamais présumer `./.claude`**. Au tout début de
mission, résous le dossier une fois et note-le `$S` (premier existant) :

```bash
S="$( for d in "$HOME/.claude/scripts" "./.claude/scripts" "${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts" "${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts"; do
        [ -f "$d/dag.sh" ] && { printf '%s' "$d"; break; }; done )"
```

> Depuis la v2.34.0, `dag.sh` et `driver-lock.sh` vivent dans le **team-kernel** hébergé par le
> conductor (`conductor-references/team-kernel.md`) — transverse à tous les métiers. Le fallback
> dev-orchestrator reste pour les caches antérieurs.

Toutes les commandes ci-dessous utilisent `"$S"/…`. (Sans cette cascade, un lab installé en scope
**user** chercherait à tort dans `./.claude/scripts` — script introuvable.)

---

## Pattern A — Lock de driver unique (anti-collision de pilotage)

Empêche deux missions/sessions de piloter la **même étape** en parallèle (corruption des backups isolés
ADR-048/049). Acquisition **atomique** (`mkdir`). Le manager est l'unique porteur du lock pour sa mission.

**Protocole (obligatoire) :**

1. **Acquérir AVANT de planifier/dispatcher** — dès que la mission est cadrée, avant le premier worker :
   ```bash
   "$S"/driver-lock.sh acquire --owner="<session_id|task_id>" --step="<étape ou 'mission'>"
   ```
   - `acquired: true` → piloter. `acquired: false` (`held_by`) → **une autre mission pilote déjà** :
     ne pas dispatcher, remonter à l'humain (ou attendre). `recovered: true` → un lock périmé a été
     élagué (le porteur précédent est mort) ; consigner la reprise dans `STATE.md ### Decisions`.
2. **Heartbeat ENTRE les étapes** — à chaque relecture ROADMAP/STATE entre deux étapes :
   ```bash
   "$S"/driver-lock.sh heartbeat --owner="<id>"
   ```
   Sans heartbeat frais, le lock est considéré périmé après `VF_DRIVER_TTL` (défaut 1800 s).
3. **Relâcher À LA CLÔTURE — succès, échec OU abandon** (release « RAII » porté par le prompt) :
   ```bash
   "$S"/driver-lock.sh release --owner="<id>"
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
   "$S"/dag.sh init --file="$DAG"
   "$S"/dag.sh add  --file="$DAG" --id=cadrage --step="cadrage étape 9"
   "$S"/dag.sh add  --file="$DAG" --id=code --step="dev" --deps=cadrage
   "$S"/dag.sh add  --file="$DAG" --id=revue --step="revue" --deps=code
   ```
   Collision d'id → remap déterministe `id::stage` (pas d'échec).
2. **Dispatcher la frontière** — au lieu de dérouler linéairement :
   ```bash
   "$S"/dag.sh ready --file="$DAG"     # → liste des nœuds dispatchables MAINTENANT
   ```
   Marquer `running` au dispatch, `done`/`failed` au retour du worker :
   ```bash
   "$S"/dag.sh mark --file="$DAG" --id=code --status=done   # promeut les blocked dont deps sont done
   ```
3. **Ré-entrée** — un correctif remonté par la revue/l'audit qui **rouvre** une étape :
   ```bash
   "$S"/dag.sh reopen --file="$DAG" --id=code   # code + ses dépendants (revue…) repassent blocked/ready
   ```
   Le manager **ré-entre** alors dans la boucle `ready → dispatch` au lieu de continuer tout droit. C'est la
   boucle `fix → re-revue` de `vf-coder` rendue explicite et robuste.

### Modélisation fine — pipelining N/N+1 (audit 2026-07-25)

Un nœud unique par étape est **trop gros** : il sérialise tout, alors que le cadrage + plan de
l'étape N+1 ne dépendent le plus souvent que de la **ROADMAP**, pas de l'exécution de N. Modéliser
**3 nœuds par étape** — `discuss(N) → plan(N) → execute(N)` — plus les nœuds de vérification
(`test(N)`, `audit(N)`), et laisser la frontière `ready` exposer le parallélisme.

**Dépendances canoniques :**

| Nœud | deps | Conséquence |
|---|---|---|
| `discuss(N+1)` | — (la ROADMAP seule) | dispatchable dès que le manager a son plan de bataille |
| `plan(N+1)` | `discuss(N+1)` | peut être produit **pendant** `execute(N)` → marqué provisoire |
| `execute(N+1)` | `plan(N+1)` **ET** `execute(N)` | périmètres de code potentiellement chevauchants |
| `test(N)` ∥ `audit(N)` | `execute(N)` | juges read-only, dispatchés en parallèle |

Exception : si les périmètres de fichiers de N et N+1 sont **déclarés disjoints** au plan de
bataille, `execute(N+1)` peut s'affranchir de la dep sur `execute(N)` (exécutions chevauchantes).

```bash
"$S"/dag.sh add --file="$DAG" --id=discuss-10 --step="cadrage étape 10"                    # aucune dep : ready immédiat
"$S"/dag.sh add --file="$DAG" --id=plan-10    --step="plan étape 10"      --deps=discuss-10
"$S"/dag.sh add --file="$DAG" --id=exec-10    --step="exécution étape 10" --deps=plan-10,exec-9
```

**Règle de provisoire (non négociable)** : un `plan(N+1)` produit pendant qu'`execute(N)` tourne
est marqué **« provisoire »** (plan de bataille + STATE). Au moment de dispatcher `execute(N+1)`,
si `execute(N)` a modifié les hypothèses — fichiers touchés hors du périmètre prévu, décisions
structurantes au rapport typé — le manager **re-valide** le plan via le plan-checker existant
(`gsd-plan-phase` re-vérifie) avant dispatch. **Jamais d'exécution sur un plan provisoire non
re-validé.** Si les hypothèses n'ont pas bougé, le plan est promu tel quel (constat consigné).

**Garde-fou coût** : le pipelining N/N+1 ne s'active que si la mission compte **≥ 2 étapes
restantes** ET que le mode le permet — jamais en mode superviser étape-par-étape (le checkpoint
humain de N barre tout dispatch anticipé de N+1).

---

## Pattern C — Contrat de rapport de worker typé

Les workers (`vf-coder`, `vf-reviewer`, `vf-auditer`, `vf-test-orchestrator`) **rendent le bloc
typé + le strict nécessaire** : le détail (analyse, findings développés) va **sur disque**
(`.planning/missions/`, rapports d'étape), pas dans le retour de conversation — le manager
a consigne de ne piloter que sur le bloc typé, la prose libre est du volume mort (audit
2026-07-25). Contrôle de flux **déterministe** côté manager :

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
