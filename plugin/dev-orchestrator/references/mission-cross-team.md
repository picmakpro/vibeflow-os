# Mission-cross-team — étages croisés dev ↔ design (Phase 15, étend ADR-053)

> Doctrine **business** des étages croisés entre `vf-dev-manager` et `vf-design-manager` — CE QUE
> chaque manager fait quand il croise l'autre métier. Le COMMENT (lock, DAG, rapports typés) reste
> entièrement dans `mission-flow.md` — inchangé, métier-agnostique, prouvé par
> `.planning/phases/VFDO-15-collaboration-inter-quipes-dev-design/15-ETUDE-collaboration-dev-design.md`
> (T3 : DAG mixte `craft:écran → exec → (critique:écran ∥ revue-code)` ; T4 : reopen cross-métier).
> Option A retenue : étages croisés **sous un seul manager** — un seul verrou de driver, un seul
> DAG, un seul rapport de mission. L'imbrication manager→manager reste **interdite** (Pattern A,
> T1 : `acquire` refusé). Depuis le nœud D-07, les cinq agents du module (2 managers + les 3
> workers `vf-coder`/`vf-reviewer`/`vf-auditer`) portent tous une allowlist `Agent(...)` recensée
> (Pattern 12, `test-dev-orchestrator.sh` T18/T19, `test-design-orchestrator.sh` T8) : elle ferme
> le chemin **direct** manager→manager **et** le chemin **indirect** manager→worker→manager, par
> déclaration et par lint — l'allowlist est un contrat documenté, désormais enforcé par le lint de
> `check-agents.sh` (recensement porté par ce nœud, lint écrit en parallèle par le nœud voisin), et
> non un bac à sable runtime dans le cas sous-agent : le runtime Claude Code n'applique la liste
> entre parenthèses que pour un agent incarné en fenêtre principale (`claude --agent`) — il
> l'ignore quand l'agent est dispatché en sous-agent. Le **verrou de driver** (T1, couvert en
> continu par `test-driver-lock.sh` T2) reste donc, dans tous les cas, la garantie machine de
> dernier ressort de l'invariant « un seul manager actif ».

---

## Étage design (mission dev)

`vf-dev-manager` peut insérer un étage design sur une étape à dominante UI.

- **Quand** : jugement du manager au plan de bataille — pas d'heuristique mécanique sur les
  fichiers, pas de marqueur humain obligatoire. Trois signaux : l'objectif de l'étape (ROADMAP),
  la présence d'un `DESIGN.md`/UI-SPEC, la nature des livrables attendus. Le brief PRIME
  (`mission-contracts.md` §Brief, champ `design:`) : `off` interdit l'étage même si le manager
  l'aurait jugé pertinent ; `force` l'impose.
- **Granularité** : nouvel écran ou refonte complète — **jamais** un fix UI mineur (typo,
  spacing ponctuel), qui reste dans le cycle `vf-coder` classique. Le kernel est fait pour les
  missions, pas pour le quotidien.
- **Forme DAG** (prouvée T3) — un nœud `craft:<écran>` avant l'exécution, un nœud
  `critique:<écran>` en PARALLÈLE de la revue code, même frontière (les deux dépendent de
  l'exécution, pas seulement du craft : le juge design note le rendu implémenté, pas seulement
  la spec) :
  ```bash
  "$S"/dag.sh add --file="$DAG" --id=craft:écran-X    --step="craft écran X"       --deps=plan-N
  "$S"/dag.sh add --file="$DAG" --id=exec-N           --step="exécution étape N"   --deps=craft:écran-X,plan-N
  "$S"/dag.sh add --file="$DAG" --id=critique:écran-X --step="critique écran X"    --deps=exec-N
  "$S"/dag.sh add --file="$DAG" --id=revue-N          --step="revue code étape N"  --deps=exec-N
  ```
- **Dispatch** : workers EN DIRECT — `vf-crafter` (craft), `vf-design-judge` (critique) —
  **jamais** `vf-design-manager` (Pattern A intact, pas d'imbrication).
- **Seuil bloquant** : même régime que l'équipe design — critique < seuil (défaut 70/100,
  `VF_DESIGN_SEUIL`) → `dag.sh reopen --id=craft:<écran>`, 3 tours max craft→critique, puis
  HALT/escalade humaine si toujours rouge (pas de raffinage infini).
- **Absence de DA** (`DESIGN.md` manquant) : l'étage design est SAUTÉ, jamais inventé — l'étape
  suit le cycle `vf-coder` classique. Le rapport de mission consigne « étage design sauté, pas de
  DA » et propose **DA-INIT** (geste existant du module design) comme next step. Jamais de HALT
  bloquant pour ça.

## Étage implémentation (mission design)

`vf-design-manager` peut insérer un étage implémentation quand le brief l'autorise
(`livrable: specs+implementation`, défaut `specs` — opt-in).

- **Dispatch** : `vf-coder` (Task, direct) reçoit la spec du crafter comme **entrée du
  cadrage** — pas la ROADMAP. Sa chaîne interne (`gsd-discuss-phase` non-interactif →
  `gsd-plan-phase` → `gsd-execute-phase` → `vf-reviewer`) s'ancre sur ce fichier de spec, que le
  digest de mission pointe explicitement (chemin sur disque, cf. `mission-contracts.md` §Digest,
  variante croisée).
- **Double juge parallèle** (symétrique de l'étage vérification dev test ∥ audit) : une fois
  l'écran implémenté, `vf-design-judge` re-score le rendu contre la DA **ET** `vf-reviewer` relit
  le diff, **en parallèle**, même frontière DAG (juges read-only) :
  ```bash
  "$S"/dag.sh add --file="$DAG" --id=impl:écran-X           --step="implémentation écran X" --deps=critique:écran-X
  "$S"/dag.sh add --file="$DAG" --id=critique-rendu:écran-X --step="re-critique rendu X"     --deps=impl:écran-X
  "$S"/dag.sh add --file="$DAG" --id=revue:écran-X          --step="revue code écran X"      --deps=impl:écran-X
  ```
- **« Vert » complet** = `critique-rendu` ≥ seuil ET revue PASS — les deux, jamais l'un ou
  l'autre seul.
- **Budgets séparés, deux compteurs distincts** : 3 tours max craft→critique pour la spec (régime
  déjà en place, inchangé), PUIS 3 tours max implémentation→(re-critique ∥ revue) pour le rendu.
  Un correctif sur le rendu réouvre `impl:<écran>` (`dag.sh reopen`), jamais le craft original —
  sauf si le juge design signale explicitement une dérive de la spec elle-même.

## Invariants non négociables

- **Un seul manager par mission** — jamais deux managers actifs sur le même DAG.
- **Un seul verrou de driver**, tenu par le manager, jamais par un worker : `vf-crafter`,
  `vf-design-judge`, `vf-coder`, `vf-reviewer` n'acquièrent JAMAIS `driver-lock.sh` — le lock
  reste au niveau mission, y compris sur les étages croisés.
- **Un seul DAG**, métier-agnostique (nœuds `craft:x`/`critique:x` mélangés aux nœuds gsd, prouvé
  T3/T4) — jamais un second graphe parallèle par métier.
- **Un seul rapport de mission** — le manager qui pilote synthétise, quel que soit le nombre de
  métiers touchés dans la mission.
- **Jamais de manager qui en dispatche un autre** — l'imbrication manager→manager est bloquée
  par construction (Pattern A, T1). Depuis le nœud D-07, les allowlists `Agent(...)` des deux
  managers (Pattern 12, `test-dev-orchestrator.sh` T18, `test-design-orchestrator.sh` T8) ferment
  le chemin **direct** ; les allowlists des trois workers `vf-coder`/`vf-reviewer`/`vf-auditer`
  (`test-dev-orchestrator.sh` T19) ferment de la même façon le chemin **indirect**
  (`manager → worker → manager`) — par déclaration et par lint (`check-agents.sh`), pas par bac à
  sable runtime : le runtime Claude Code n'applique la liste entre parenthèses que pour un agent
  incarné en fenêtre principale (`claude --agent`), jamais pour un agent dispatché en sous-agent.
  C'est pourquoi le **verrou de driver** reste, dans tous les cas, la garantie machine de dernier
  ressort de l'invariant « un seul manager actif » : un second `acquire` est refusé tant que le
  premier manager pilote (T1, couvert en continu par `test-driver-lock.sh` T2), y compris si une
  allowlist était mal posée ou absente.

---

Doctrine mécanique (lock/DAG/rapports typés, inchangée) : `mission-flow.md`. Contrat de brief et
de digest (champs `design:`/`livrable:`, digest enrichi croisé) : `mission-contracts.md`.
