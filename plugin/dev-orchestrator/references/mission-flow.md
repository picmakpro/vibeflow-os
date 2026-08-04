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
S="$( for d in "./.claude/scripts" "$HOME/.claude/scripts" "${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts" "${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts"; do
        [ -f "$d/dag.sh" ] && { printf '%s' "$d"; break; }; done )"
```

> **Le lab courant PRIME** : `./.claude/scripts` d'abord — sur une machine bi-scope
> (user + projet), préférer le scope user ferait tourner la mission avec des scripts d'une
> autre version que celle du lab, silencieusement. Un lab en scope user n'a pas de
> `./.claude/scripts` : la cascade retombe naturellement sur `$HOME`.

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

### Contrôle de flux du manager — table de pilotage (foyer UNIQUE)

Déterministe, plus d'interprétation de prose. Cette table est l'énoncé **faisant autorité** : le
`vf-dev-manager` y RENVOIE et ne la reformule pas (ADR-030, une seule voix). Elle a été déportée
ici depuis l'agent (arbitrage A-4) — l'agent tenait 249/250 lignes du plafond ADR-029, une marge
d'une ligne que huit plans restants auraient crevée ; rien de son sens n'a bougé au passage.

- **Verdict d'étape (rapport typé, ADR-053)** : le `statut` du rapport de worker — recoupé au
  `*-VERIFICATION.md` — pilote le flux de façon déterministe : `passed` → `dag.sh mark done` +
  frontière suivante · `human_needed` — déclenché par `gate="blocking-human"` amont OU par une
  précondition amont non satisfaite (`mission-contracts.md` §Contrat de checkpoint amont : une
  règle, deux motifs), ou par tout finding `action: ask-user` — → **escalade départagée par le
  MODE**, jamais tranchée seule : en mode **superviser**, c'est le manager qui **répond aux
  attentes humaines** du moteur (checkpoint, garde-fou de reprise sûre) : il pose la question, il
  attend, puis il redispatche `vf-coder` avec le champ `reprise` — qui transporte la réponse ET
  les tâches faites, sans quoi le worker neuf retombe sur le même checkpoint
  (`mission-contracts.md` §Minimum de reprise) —, avec le même filet de repli qu'au §Entrée de
  l'agent si l'outil de question est indisponible au runtime ; en mode **autonome**, il n'y répond
  JAMAIS à la place de l'utilisateur, absent par définition (ADR-031) : **GELER le nœud porteur,
  halte de nœud, jamais de mission**, le laisser `blocked`/`failed`, ne poursuivre QUE les nœuds
  indépendants, consigner la question au rapport · `gaps_found` → `dag.sh reopen` + UNE relance de
  comblement via `vf-coder`, puis si les manques persistent : consigner et arbitrer · `blocked` →
  laisser le nœud `blocked`, traiter la dépendance. Findings `action: auto-fix` → repartent à
  `vf-coder` (jamais corrigés par le manager) ; `no-op` ignorés.
- **Blocage** (étage en échec répété) : 3 options — réessayer l'étage · sauter l'étape (documenté)
  · arrêter la mission (rapport partiel). En mode **autonome** : trancher via panel ; en mode
  **superviser** : demander (AskUserQuestion) — même filet de repli si l'outil est indisponible au
  runtime : `human_needed` au rapport, jamais d'auto-réponse.

---

## Pattern E — Étage revue de premier rang (D-10 → D-14)

> Généralise le patron déjà écrit pour l'étage design croisé (`mission-cross-team.md` §Étage design,
> nœud `revue-N` deps=`exec-N`) : la revue cesse d'être un cas particulier de la collaboration
> dev↔design pour devenir LE patron de l'étage revue de toute mission dev. `mission-cross-team.md`
> continue de le SPÉCIALISER (formule de « vert » complet du double juge) — il n'est ni dupliqué ni
> modifié ici.

### 1. Pose du nœud

Pour chaque étape, le manager pose un nœud `revue-N` dépendant du nœud d'exécution de la même
étape, **systématiquement** — au même titre que test/audit sont posés quand ils s'appliquent, mais
sans condition : la revue n'est jamais sautée.

```bash
"$S"/dag.sh add --file="$DAG" --id=revue-N --step="revue code étape N" --deps=exec-N --scope=<globs>
```

Le périmètre (`--scope`) est déclaré à la pose : c'est ce qui rend calculable le critère (b) de la
§3 ci-dessous (fichier partagé avec une mission parallèle en vol) — sans déclaration, ce critère
reste aveugle. `dag.sh status` dérive la table des fichiers gelés depuis ces périmètres déclarés,
jamais depuis une copie figée (cf. `.planning/MISSION-INVARIANTS.md` §2).

### 2. Dispatch et boucle de correction

`vf-reviewer` est dispatché **EN DIRECT** par le manager, jamais via `vf-coder` — un seul pilote de
la revue, cohérent avec les allowlists `Agent(...)` des deux agents (ni dispatch direct ni indirect
manager↔worker↔worker de revue). Sur un rapport typé `gaps_found` :

1. `dag.sh reopen --id=revue-N` — force `review_regime=full` sur le nœud et ses dépendants transitifs
   (mécanisme machine, cf. §5).
2. Dispatch `vf-coder` en mandat de **correction CIBLÉE** : les findings remontés, rien d'autre —
   jamais un cycle cadrage → plan → exécution complet.
3. Re-dispatch `vf-reviewer` sur le diff corrigé.

Budget **3 tours**, au grain **étape** et **partagé** avec les autres boucles de correction de la
même étape (§6 ci-dessous) — un budget séparé par boucle se contournerait mécaniquement, par
renommage du problème, ce que ce Pattern dit précisément vouloir empêcher. La valeur ne bouge pas
(D-25) : elle reste celle mesurée à son rendement actuel, on ne plafonne pas avant d'avoir des
chiffres réels. Au-delà, escalade humaine — cette boucle s'articule sur la MÊME table de pilotage
déterministe que le reste du contrôle de flux (Pattern C), une seule règle : `passed` → `mark done`
+ frontière suivante · `gaps_found` → la boucle ci-dessus · `human_needed`/finding `ask-user` →
escalade.

### 3. Gradation par risque, jamais par volume

Déclencheurs de revue **renforcée**, non négociables — chacun un FAIT constatable sur le diff ou le
plan de bataille, jamais un jugement au feeling :

(a) un adaptateur d'infrastructure non couvert par les tests ;
(b) un fichier partagé avec une mission parallèle en vol (table dérivée par `dag.sh status`) ;
(c) du code que la mutation ne couvre pas ;
(d) un geste utilisateur ou une géométrie de vue.

Allègement réservé — et seulement — au Domain pur à mutation verte, à la documentation, aux
catalogues sans ajout de clé. **Défaut sûr : dans le doute, revue pleine** — le classement du lot
est un point de décision, donc un point d'erreur, et le défaut doit être le sûr. Axe abandonné
explicitement : la seule gradation d'avant indexait sur le VOLUME (`SEUIL_EQUIPE`, nombre d'étapes
restantes) — mauvais axe, trois lignes sur un chemin partagé sont minuscules et à très haut risque,
quatre cents lignes de Domain pur prouvées par mutation sont grosses et à bas risque.

### 4. Revue de jointure

Dès que deux nœuds `exec-*` **incomparables** (aucun lien de dépendance entre eux) partagent un
descendant, un nœud `join-<N>` séparé est posé, et il lit **l'union** des deux diffs :

```bash
"$S"/dag.sh add --file="$DAG" --id=join-N --step="revue de jointure" --deps=exec-A,exec-B
```

Déclencheur = la **TOPOLOGIE** du DAG, jamais l'intersection des périmètres de fichiers : cette
intersection est vide par construction en parallélisation nominale — on parallélise précisément
quand les périmètres sont disjoints, un déclencheur fondé dessus ne se déclencherait donc jamais.
C'est l'étage au meilleur rendement mesuré sur la tranche source de la Phase 20 : 4 bloquants + 9
majeurs, qu'aucun relecteur cadré sur un seul lot n'aurait vus.

### 5. Garde-fou de comblement

**Aucun allègement ne s'applique jamais à un diff de comblement. Une re-revue reste pleine, quelle
que soit la nature du lot d'origine.** Garant MACHINE, pas une consigne : `dag.sh reopen` écrit
lui-même `review_regime=full` sur tout nœud `revue-*`/`join-*` rouvert (et ses dépendants
transitifs) — une consigne se contourne par interprétation, un champ écrit par l'outil ne se
contourne pas.

### 6. Épuisement du budget (D-26, D-27, D-28)

Budget épuisé (§2) ⇒ statut de rapport typé `blocked`, assorti d'un **décompte complet** de ce qui
a été tenté : tours de revue consommés, tours de comblement consommés, findings restés non
résolus. **Le décompte EST la livraison** : sans lui, un budget partagé ne serait qu'un chiffre
plus petit, pas une information. Champ porteur : `decompte` (`mission-contracts.md` §Décompte de
budget épuisé).

**L'invisibilité amont, nommée (D-26).** Le décompte porte les tours d'ÉQUIPE — ceux que VibeFlow
pilote et compte lui-même. Le nombre de réparations `node_repair` consommées **à l'intérieur d'un
plan** par le moteur est **invisible** sans parser la prose libre de chaque rapport de plan, format
non contractuel — fait daté et sourcé : le journal amont est de la prose dans une section markdown,
aucun gabarit de rapport amont ne porte de champ de comptage. Ne **jamais** fabriquer un total
agrégé qui laisserait croire à une mesure exhaustive : un manque nommé vaut mieux qu'un chiffre
inventé.

Aucune proposition de next step n'accompagne le décompte : elle serait produite par l'agent qui
vient d'échouer plusieurs fois sur le sujet, donc la partie la moins fiable du rapport.

---

## Pattern F — Étage cadrage porté par le manager (A-1ter geste 2, motif A-13)

**Qui exécute** : le manager, lui-même, dans sa propre fenêtre — seule exception à « il ne produit
rien lui-même » : le cadrage n'est ni du code, ni un test, ni un audit, c'est une conversation de
décision, et le manager est le nœud de l'équipe où les décisions de mission se prennent.

**Pourquoi, en FAIT (motif A-13, le seul autorisé ici)** : sur `gsd-core@1.9.0`, le seul mode non
interactif de la brique de cadrage enchaîne cadrage → plan → exécution dans le même appel — le
porteur ne reprend la main qu'à la fin du pipeline entier, et pendant ce temps la **règle 5** de
`checkpoints.md` auto-approuve les `human-verify` et auto-sélectionne la première option des
`decision`. Le cadrage porté par le manager, **plus aucun mode d'enchaînement n'est passé à cette
brique** : la règle 5 cesse de s'appliquer au plan et à l'exécution qui suivent — le problème
disparaît, il n'est pas borné.

**Discipline de flags** : `GSD-PIPELINE.md` §9 porte la table (ne pas la recopier ici, ADR-030).

**Modélisation du nœud** : sous-section de pipelining N/N+1 du Pattern B ci-dessus, qui pose déjà
le nœud de cadrage et ses dépendances — seul change qui exécute le nœud, pas le graphe.

**Outil de question indisponible** : cas réel, déjà documenté au filet de repli D-09 du manager
(§Entrée) — `human_needed` remonté, jamais un retour au mode d'enchaînement.

**Ce que le worker ne fait plus** : `vf-coder` n'invoque plus jamais le cadrage lui-même.

---

## Pattern D — Étages croisés dev ↔ design (renvoi)

Doctrine complète (quand insérer l'étage de l'autre métier, forme DAG, budgets, invariants) :
`dev-orchestrator-references/mission-cross-team.md` (§Étage design (mission dev) / §Étage
implémentation (mission design) / §Invariants non négociables). Les Patterns A/B/C/E ci-dessus
s'appliquent tels quels aux nœuds croisés (`craft:<écran>`, `critique:<écran>`, `revue-N`, étage
implémentation) — le DAG reste métier-agnostique (prouvé T3/T4, `15-ETUDE-collaboration-dev-design.md`) ;
le nœud `revue-N` du cross-team EST une instance de Pattern E, pas un cas séparé ; le lock reste au
seul manager de la mission, jamais imbriqué (Pattern A).

## Lignes rouges (rappel ADR-053)

Pas de bus UDS / channels / `dm` temps réel (modèle `Task` = dispatch-and-join). Pas de RAII machine : le
release dépend du prompt → la **récupération de claim périmé est obligatoire**, pas optionnelle.
