# 15-ETUDE — Collaboration inter-équipes dev ↔ design (2026-07-27)

> Étude préalable à la Phase 15. Question de départ (Samuel) : « Ça serait possible que le
> dev-orchestrator et le design-orchestrator s'appellent entre eux ? Actuellement ils ne sont pas
> vraiment liés et très séparés alors qu'ils pourraient collaborer. »
> Verdict : **oui — option A retenue** (étages croisés sous un seul manager). Tests : 7/7 verts.

## 1. État des lieux — les ponts existants (et leurs limites)

| Pont | Où | Nature | Limite |
|---|---|---|---|
| Routage conversationnel | `dev-orchestrator/references/intent-routing.md:108`, `AGENT.md:89` | `vibeflow-dev` route « design / UI / c'est moche » → skill `vf-design` → agent `vibeflow-design` | Sens unique, hors mission — aucun lien au niveau des managers |
| Team-kernel commun | `conductor/references/team-kernel.md` | Les deux équipes tournent sur `driver-lock.sh`, `dag.sh`, rapports typés, digest ; `vf-design-manager` référence `mission-contracts.md` et `mission-flow.md` du dev | Protocole partagé mais **jamais exploité** entre équipes |
| `gsd-ui-phase` / `gsd-ui-review` | routés par la chaîne design uniquement | — | `vf-coder` ne les voit pas en mission dev |

**Trous constatés :**

1. `vf-dev-manager` ne connaît ni `vf-design-manager`, ni `vf-crafter`, ni `vf-design-judge` —
   une étape UI en mission dev part chez `vf-coder` → `gsd-execute-phase` sans jamais toucher la
   chaîne design.
2. `vf-crafter` produit des **specs + tokens** que personne n'implémente : aucun handoff documenté
   vers l'équipe dev.
3. **Chemin de dispatch mort** : la description publiée de `vf-design-manager` affirme « dispatché
   par vf-auto (mission longue à dominante design) », mais `vf-auto/SKILL.md` ne route QUE vers
   `vf-dev-manager` (aucune mention design).

## 2. Tests empiriques (script : `test-collab-orchestrateurs.sh`, ce dossier)

Baseline avant étude : 4 suites existantes vertes (driver-lock 26, dag 29, design-orchestrator 10,
dev-orchestrator 41 = 106 PASS / 0 FAIL).

| Test | Scénario | Résultat |
|---|---|---|
| T1 | `vf-dev-manager` tient le lock, dispatche `vf-design-manager` qui tente `acquire` | **REFUSÉ** (`acquired:false`, `held_by`) — l'imbrication manager→manager est bloquée par le Pattern A, et c'est voulu |
| T2 | Handoff séquentiel : release dev → acquire design | **OK** — la collaboration en relais marche déjà |
| T3 | DAG mixte `discuss → plan → craft:écran → exec → (critique:écran ∥ revue-code)` | **OK** — `dag.sh` est métier-agnostique ; les deux juges sortent en parallèle dans la même frontière |
| T4 | Critique < seuil → `reopen craft:écran` | **OK** — l'exécution dépendante rebloque (ré-entrée cross-métier) |

## 3. Options étudiées

- **A (retenue) — étages croisés sous UN manager.** `vf-dev-manager` gagne un étage design
  (`craft:<écran>` avant exec, `critique:<écran>` ∥ revue) ; `vf-design-manager` gagne un étage
  implémentation (`vf-coder` incarne les specs). Un lock, un DAG, un rapport. Prouvé faisable par
  T3/T4 ; aucun changement kernel requis.
- **B — handoff séquentiel entre missions** (T2). Marche sans rien changer mais perd le contexte
  entre missions, deux rapports.
- **C (rejetée) — managers imbriqués.** Exigerait un lock réentrant/hiérarchique → affaiblirait
  l'anti-collision durcie en v1.14.4/v1.14.5.

## 4. Périmètre proposé pour la phase (repris dans les Success Criteria de la ROADMAP)

1. Doctrine `vf-dev-manager` : étage design sur étape à dominante UI (workers design en direct,
   JAMAIS le manager design).
2. Doctrine `vf-design-manager` : étage implémentation via `vf-coder`, « vert » design inchangé
   (critique scorée ≥ seuil).
3. Fix `vf-auto` : aiguillage dominante design → `Task(vf-design-manager)`.
4. Cloisonnement intact : `check-agents.sh` vert, juges sans Write/Edit effectif, workers
   `vf-internal: true`. Attention aux allowlists `Agent(...)` si on en pose.
5. Tests croisés intégrés aux suites des deux modules (DAG mixte, reopen cross-métier,
   interdiction d'imbrication) ; release + tag (`check-release-tag.sh --remote` → ✓).

**Points ouverts pour le cadrage** : critère de détection « étape à dominante UI » côté
dev-manager (signal ROADMAP ? heuristique fichiers ?) ; digest de mission cross-métier (la DA en
3-5 lignes doit-elle entrer dans le digest dev ?) ; comportement sans DA (`DESIGN.md` absent →
l'étage design se dégrade ou se saute ?) ; bump de version par module (minor ×2 + conductor ?).
