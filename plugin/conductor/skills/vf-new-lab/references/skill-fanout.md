# Fan-out skill-creator — fabriquer les capacités en parallèle (T3 du Lab Factory)

> Référence de `vf-new-lab` (phase Fan-out). Transforme le manifeste de capacités validé en **skills
> réels**, en parallélisant des agents `skill-creator`. C'est le cœur du « compilateur de lab » : le lab
> démarre **peuplé**, pas vide. **Prérequis : gate B franchi** (manifeste sans `[À CLARIFIER]`).

---

## Principe : un skill-creator par capacité, en parallèle

L'agent `skill-creator` est **« UN skill par invocation » (non-négociable)** et déploie déjà sa propre
recherche parallèle en interne. Donc on **ne lui passe jamais plusieurs skills** : on lance **N
invocations parallèles**, une par capacité P0 du manifeste.

```
manifeste P0 (N capacités)  ──fan-out──►  N agents skill-creator (//)
   CAP-01 → skill-creator(CAP-01) ─┐
   CAP-02 → skill-creator(CAP-02) ─┤
   …                               ├─► chacun : recherche → draft SKILL.md → eval → itère
   CAP-N → skill-creator(CAP-N)  ─┘     puis ESCALADE l'attribution au conductor
```

**Mise en œuvre** : spawn des sous-agents `skill-creator` via l'outil **`Task`** (`subagent_type:
skill-creator`), **dans un seul message à plusieurs tool-uses** pour qu'ils tournent en concurrence.
Chaque invocation reçoit **une** entrée du manifeste (nature + justification + critère de succès + nom cible).

**Le prompt d'invocation DOIT injecter** (le template skill-creator n'est pas personnalisé à la volée) :
- **destination forcée** `.claude/skills/<nom>/` — nature META, **ignorer la distinction LIVRABLE**
  (Règle 4 du template skill-creator, sans objet dans un lab métier neuf) ;
- **instruction d'escalade explicite** : « retourne dans ton message final à `vf-new-lab` la liste
  `skill créé → agents suggérés` » — **ne pas** compter sur le placeholder `[ORCHESTRATING_AGENT]`, qui
  n'est résolu qu'à l'installation d'un lab, pas à l'exécution.

> **Disponibilité** : si l'agent porteur n'a pas l'outil `Task` ou si `skill-creator` n'est pas
> enregistré comme `subagent_type` → **fallback séquentiel** (invoquer skill-creator l'un après l'autre).
> Pour un gros manifeste, lancer par **vagues** (5-6) plutôt que 20 d'un coup — voir Proportionnalité.

---

## Anti-slop (3 garde-fous — sinon 20 skills médiocres)

1. **Gate de capacité + orthogonalité en amont** (déjà fait, gate B) : on ne fabrique que des capacités
   justifiées par le brief ET non-redondantes entre elles (deux capacités quasi-doublons sont fusionnées
   AVANT de paralléliser — sinon chaque skill-creator, isolé, ne voit pas les autres et on fabrique des
   jumeaux). Pas de skill « tant qu'à faire ».
2. **Eval par skill, bornée** : chaque `skill-creator` déroule sa boucle officielle (draft → grade →
   itère). **Plafond : 3 passes.** Un skill qui ne passe pas au bout de 3 passes **n'est pas livré** : il
   remonte en `[À RETRAVAILLER]` + backlog, **et on continue le reste du fan-out** (une capacité retorse
   ne bloque jamais l'init).
3. **Critique de complétude final** (après le fan-out), **déléguée à un sous-agent frais** (reviewer ou
   explorer — jamais l'orchestrateur qui s'auto-juge, anti-pattern audit-architecture), avec une
   mini-rubric : *« quelle capacité du brief n'a pas de skill ? lequel est redondant / hors-sujet ? »*.
   Ce qu'il trouve → micro-vague de correction ou suppression. Filet contre « volume ≠ valeur ».

---

## Proportionnalité (rappel)

Le fan-out ne traite que les **P0** du manifeste (plafond par profil : léger 1-3 / standard 4-8 /
complet 9-20, cf. `capability-manifest.md`). Les P1/P2 restent en backlog, créés **à la demande** plus
tard (escape hatch : invoquer `skill-creator` seul quand le besoin se présente). **Loguer ce qui est
mis en backlog** — ne jamais tronquer en silence.

---

## Attribution (ne jamais faire à la place du skill-creator)

`skill-creator` **n'attribue pas** les skills aux agents (sa Règle 1) : il produit le skill et
**escalade**. C'est `vf-new-lab` (le conductor) qui, à la phase Assemblage, câble chaque skill créé
dans le frontmatter `skills:` des agents métier pertinents. Donc :
1. fan-out → N skills créés dans `.claude/skills/` ;
2. conductor collecte les escalades d'attribution ;
3. conductor câble `skills: [...]` dans les agents (phase Assemblage du SKILL.md).

---

## Sortie de la phase

- N skills réels dans `.claude/skills/<nom>/SKILL.md` (chacun ayant passé son eval).
- Manifeste mis à jour : P0 = ✅ créé / `[À RETRAVAILLER]` ; P1/P2 = backlog.
- Liste d'attributions à câbler (consommée par l'Assemblage).
- Les **procédures génératives** du manifeste → passent ensuite par le ficelage auditeurs
  (`procedure-audit-wiring.md`) avant l'assemblage.
