---
titre: "[titre du cycle]"
rend: "[ce que le cycle rend]"
ferme_quand:
  - "[condition observable qui ferme le cycle]"
---

# Cycle — [titre]

> Le recalcul ne lit que la **présence** de ce fichier. L'état du cycle n'est **jamais** lu ici :
> il est l'**agrégation** de ses phases (voir `references/modele-cycles.md` § Agrégation).

## Ce que le cycle rend

[Une ligne : le livrable ou le résultat auquel ce cycle mène.]

## Conditions qui le ferment

[Une ou plusieurs conditions observables, listées en `ferme_quand:`. Une condition observable se
constate sur le disque ou dans le métier — pas un jugement d'humeur.]

## Premier cycle — canary de juge

> À ne garder que dans le **premier** cycle du lab, et seulement si le lab a des juges (des définitions
> de rôle `juge` sous `.claude/agents/`). Cette section n'est pas lue par le recalcul.

Pour **chaque juge du lab**, avant de se fier à son verdict :

1. le manager dispatche le juge sur `.planning/juges/<juge>/SORTIE-PIEGEE.md` (la sortie piégée : un
   mauvais output connu qui viole le critère visé, voir `SORTIE-PIEGEE.template.md`) ;
2. le manager pose le verdict du juge par `poser-verdict.sh --unite=.planning/juges/<juge> --juge=<juge>
   --tentative=1 --score=<texte> --constat=<critère visé>::<échec ou passé>` : `échec` si le juge a
   refusé la sortie piégée, `passé` s'il l'a laissée passer — il est alors **laxiste**, et son prompt se
   corrige avant qu'on s'y fie.

Tant que ce n'est pas fait, le `SessionStart` du lab signale **« juge sans preuve »** : ce n'est jamais
vert. Le manager porte cette étape jusqu'à ce que l'orchestrateur générique (Phase 48) l'automatise ;
le moteur ne dispatche aucun juge.
