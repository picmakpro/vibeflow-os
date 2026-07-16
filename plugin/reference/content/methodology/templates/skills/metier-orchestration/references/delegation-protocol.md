# delegation-protocol — format de mandat sous-agent + réconciliation

> Référence on-demand du skill `metier-orchestration`. Comment l'orchestrateur délègue (Phase 4) et
> réconcilie les retours, sans jamais produire lui-même.

---

## Format de mandat (un par agent délégué)

Claude Code n'a **aucun contrat natif** agent↔sous-agent : le seul canal est le **prompt d'invocation**
et le **texte de retour**. Le mandat est donc une convention de prompt, à injecter dans chaque `Task` :

```
MANDAT — [nom de la tâche]
- Objectif      : [résultat attendu, en une phrase]
- Entrées       : [contexte, fichiers, décisions applicables (DEC-XXX)]
- Sortie attendue : [livrable précis + emplacement]
- Scope         : [ce qui est DANS le périmètre / ce qui n'y est PAS]
- Critère de succès : [comment on jugera que c'est atteint]
- Escalade      : [quand t'arrêter et remonter à l'orchestrateur plutôt que d'étendre le scope]
- Format de retour : Statut (FAIT|PARTIEL|BLOQUÉ) · Livrable · Décisions · Reste/risques
```

## Parallélisme

- Tâches **indépendantes** → plusieurs `Task` dans **un seul message** (elles tournent en concurrence).
- Tâches **dépendantes** → séquentiel, la sortie de l'une alimente le mandat de la suivante.
- Ne jamais paralléliser deux agents qui écrivent le même livrable (collision).

## Réconciliation des retours

L'orchestrateur **lit les retours et les met en cohérence** — c'est son cœur de métier :
1. Collecter les Statuts. Un `BLOQUÉ` → traiter (clarifier, re-mander, ou escalader) avant d'avancer.
2. Détecter les **conflits** entre livrables (deux agents qui se contredisent) → arbitrer ; si le choix
   est structurant → DEC-XXX.
3. Vérifier la **complétude** : chaque tâche du plan a-t-elle son livrable ? Sinon, re-déléguer.
4. Ne jamais « recoller » soi-même en produisant le morceau manquant — re-déléguer à l'agent compétent.

## Anti-substitution (le piège numéro 1)

Quand l'orchestrateur est tenté d'écrire/coder/rédiger « juste ce petit bout » : **STOP**. C'est le signe
qu'il manque un agent ou un skill. Deux issues légitimes :
- La capacité existe → déléguer à l'agent qui la porte.
- La capacité manque → la **fabriquer** (skill via `skill-creator`, canal unique) puis déléguer.

Se substituer aux spécialistes détruit la traçabilité, la vérifiabilité et la scalabilité du lab (P3).

## Escalade vers la gouvernance (C4)

Hors périmètre métier (sécurité, budget, décision business, incohérence structurelle du lab) →
l'orchestrateur **escalade au `conductor`** via le protocole C4 (`conductor-references/contracts.md`),
plutôt que de trancher hors de sa compétence. L'orchestrateur pilote le **métier** ; le conductor garde
la **structure** du lab.
