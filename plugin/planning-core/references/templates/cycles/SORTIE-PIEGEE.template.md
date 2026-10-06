---
juge: "[nom du juge : le name de sa définition dans .claude/agents/, en minuscules, chiffres et tirets]"
critere_vise: "[le critère éliminatoire que cette sortie viole, écrit comme il sera porté dans les constats du verdict]"
provenance: "[d'où vient l'exemple raté : tiré de l'exemple raté de l'interview, d'un document réel, fabriqué à la main]"
---

# Sortie piégée — [nom du juge]

> Une **sortie piégée** est un **mauvais output connu** : un exemple qui viole, volontairement et
> sans ambiguïté, le critère que le juge est censé refuser (`critere_vise`). C'est la notion voisine
> du test de discrimination d'une rubrique (« rejette-t-elle un mauvais output connu ? », voir le skill
> `audit-architecture`, `rubric-design.md`) : un juge qui la laisse passer ne sait pas refuser, et un
> juge qui laisse tout passer est le mode d'échec le plus coûteux d'un système multi-agents (spec
> d'initialisation §10, C-16).

## L'exemple raté

[Le texte de l'exemple raté, tel que le juge le recevrait à juger. Il doit violer `critere_vise` et
**lui seul** : un exemple qui viole plusieurs critères à la fois ne prouve aucun d'eux.]

## Où elle vit

`.planning/juges/<juge>/SORTIE-PIEGEE.md`, un dossier par juge du lab (`<juge>` : le nom du juge en
minuscules, chiffres et tirets, 64 caractères au plus). Le dossier est un emplacement du modèle à la
racine de `.planning/` : jamais « Hors modèle » dans `INDEX.md`, jamais lu comme une unité de cycle.

## Qui la fabrique

L'initialisation d'un lab (Phase 50) la **tire de l'exemple raté** de l'interview, sans l'exécuter ;
dans un lab qui n'est pas initialisé de cette façon, elle s'écrit à la main. Le moteur ne la fabrique
pas (Phase 46).

## Comment son verdict se pose

Le premier passage du juge sur cette sortie est une **étape écrite du premier cycle** (voir
`CYCLE.template.md`) : le manager dispatche le juge sur ce fichier, puis pose son verdict par
`poser-verdict.sh --unite=.planning/juges/<juge> --juge=<juge> --tentative=<n> --score=<texte>
--constat=<critère>::<passé|échec>`. Le fichier `VERDICT.md` du dossier du juge ne s'écrit **jamais**
à la main : G5 refuse toute écriture par outil d'un `VERDICT.md`. La commande calcule le `hash` : le
sha256 des octets de **ce fichier** (il n'y a pas de `hash_livrables` pour un juge).

## Ce que le vérificateur exige

Au `SessionStart` (source `startup`) d'un lab adhérent, le moteur classe chaque juge du lab :

- **prouvé** : le verdict est valide, son `hash` est celui de ce fichier tel qu'il est, et le critère
  visé y est porté **en `échec`** ;
- **laxiste** : le verdict est valide et à jour, mais le critère visé n'est pas en `échec` (porté en
  `passé`, ou absent des constats) ;
- **sans preuve** : tout le reste — pas de dossier, pas de sortie piégée ou sans `critere_vise`, pas de
  verdict, verdict invalide, **périmé** (cette sortie a été modifiée après le verdict : l'affaiblir ne
  prouve rien), nom de juge hors forme. « Juge sans preuve » n'est **jamais** vert.

Le signal est une ligne de contexte ; il ne bloque jamais la session. Le seuil de juge n'est pas posé
ici (Phase 50).
