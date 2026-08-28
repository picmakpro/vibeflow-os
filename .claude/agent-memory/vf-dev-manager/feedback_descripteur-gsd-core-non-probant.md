---
name: descripteur-gsd-core-non-probant
description: Un descripteur de capacité gsd-core ne prouve ni un vert ni un ROUGE — vérifier en exécution avant d'en tirer un no-go, et se méfier autant de le MAL LIRE que de le croire
metadata:
  type: feedback
---

La valeur d'un champ du registre `capability-registry.cjs` de gsd-core **constate ce que gsd-core
croit du runtime**, pas ce que le runtime fait. Ne jamais en tirer une conclusion de portabilité,
dans un sens **ni dans l'autre**, sans exécution réelle.

**Why:** en Phase 37 (2026-08-28), un no-go structurel entièrement rédigé et argumenté reposait sur
`codex maxDepth: 1` lu dans ce registre — il aurait tué le portage du team-kernel (19 des 31 agents
déclarés morts). Vérifié en exécution : **la profondeur réelle est 3**, prouvée par le compteur
natif du runtime (`session_meta` : `DEPTH= 1/2/3`). Le champ était faux, et c'est le refus de
prononcer le no-go sans mesure qui a évité l'erreur.

Le piège est **symétrique**, et c'est le point non évident : la doctrine « aucun vert auto-déclaré
ne tient » se retient sans effort pour les verts et s'oublie pour les **rouges**. Un no-go fondé sur
un descripteur a exactement la même fragilité qu'un go.

**Deuxième danger, distinct et tout aussi réel : MAL LIRE le descripteur.** Dans la même mission,
le cadrage attribuait `backgroundDispatch: false` à codex. Vérification : **le registre avait
raison** — il déclare `codex: true` et `claude: false`. L'erreur était dans la lecture, pas dans la
source. Un rapport a d'abord agrégé ces cas en « 3 vérifications, 3 erreurs du registre » : faux, et
c'était un **rouge auto-déclaré** dans le document même qui dénonçait les verts auto-déclarés. La
ventilation exacte : **1 erreur du registre vérifiée en exécution** (`maxDepth`), **1 erreur de
lecture du cadrage** (`backgroundDispatch`, registre juste), **1 obsolescence documentaire non
vérifiée en runtime** (descripteur `kimi-code`, runtime jamais installé).

**How to apply:** quand une décision majeure repose sur un champ de descripteur, promeus sa
vérification en **tête** du mandat d'exécution suivant, formulée comme une question falsifiable sur
le runtime réel (« un subagent peut-il lui-même spawner ? »), jamais comme une relecture du
registre. Et quand tu agrèges plusieurs constats en un décompte (« N fois sur N »), **ventile-les
par nature de preuve avant de les additionner** — mesuré en exécution, lu dans un doc, mal lu :
ce ne sont pas les mêmes objets. Voir [[gsd-core-porte-le-modele-de-capacite]] (le registre reste la
bonne SOURCE, il n'est pas une PREUVE) et [[artefacts-descriptifs-non-testes]].
