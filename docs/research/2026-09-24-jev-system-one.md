# Jev (TypeSafe AI) et les modèles de décision typée — ce que dev-orchestrator en retient

> Note de recherche, 2026-09-24, session principale (Samuel). Sources en fin de document. Ce
> n'est **pas** une décision : les points § « Ce qu'on retient » sont livrés dans la même PR
> (contrats, head-governance), le spike § « Ce qui reste à mesurer » attend un arbitrage.

## Ce qu'est Jev

Modèle de **décision typée** publié le 15 septembre 2026 par TypeSafe AI (accès anticipé sur
liste d'attente, levée de 40 M$). Pas un LLM : il ne génère rien. Entrée = un état (texte ou
JSON) + des questions typées ; sortie = des réponses **dans le schéma déclaré**, chacune avec
une **distribution de probabilités**. Trois primitives : `Choice` (une option parmi N), `Score`
(échelle ordonnée), `Noul` (probabilité qu'une affirmation soit vraie). 70–500 ms, 0,042 $/M
tokens d'entrée, sortie gratuite.

**Pas open source** : poids fermés, architecture non publiée, méthode de calibration (RLCD) sans
papier. TypeSafe n'ouvre que ses SDK (Python, JS), une skill d'agent et un **adaptateur** qui pose
les mêmes questions à des modèles OpenAI/Anthropic.

**Reproductions ouvertes** : AnyJev (Nokia, Apache-2.0, 23 septembre — couche sans entraînement
sur n'importe quel LLM ouvert, même API ; sur Qwen3-8B/BANKING77 : précision 74,7 → 80,7 %, ECE
0,24 → 0,095, ~0,25 s/décision sur H100), Bosun v3.1 (Qwen3 0,6B/1,7B natif), open-jev,
open-alternative-jev, Laya (ModernBERT 421M, ~35 ms, local).

## Points forts / points faibles (tests indépendants)

| | |
|---|---|
| **Forts** | schéma garanti (zéro réponse hors options) ; latence et coût d'un ou deux ordres de grandeur sous un LLM ; calibration native correcte (ECE médian 0,071) ; doctrine saine — « *Questions describe judgments; code owns composition, thresholds, and side effects* » |
| **Faibles** | précision 72,5 % multi-tâches, 6,5–11,5 pts derrière la frontière (niveau modèles milieu de gamme) ; inverser l'ordre des étiquettes change ~32,5 % des réponses ; **-11 pts hors anglais** (russe) — nos artefacts sont en français ; mauvais quand la réponse n'est pas dans le texte d'entrée ; Opus 5 en effort élevé est mieux calibré (Jev est sous-confiant) |

**Résultats sur projets** : tous auto-déclarés et petits — QA mobile Callstack (un test, 14 s,
0,0023 $), jev-superpowers (hallucination de paquets ~14 % → ~0 %, 24 tests hors ligne),
jev-for-all (routage de skills 85,9 % sur 64 requêtes), jev-agentic-ops (parité 6/6 avec un LLM,
23× moins cher, seuil relevé 0,45 → 0,6 après mesure). **Aucune mesure à l'échelle d'un projet
de dev piloté par agents.**

## Ce qu'on retient (livré dans la PR qui porte cette note)

1. **La confiance comme branche à part entière** — champ optionnel `confiance` sur les rapports
   typés, `SEUIL_CONFIANCE`, requalification d'un `passed` de jugement sous le seuil en
   `gaps_found` + `ask-user`, journal verbatim dans le rapport de mission
   (`mission-contracts.md` §Confiance d'un jugement ; `team-kernel.md` Pattern C). Ne s'applique
   **jamais** à une preuve machine.
2. **Décomposer l'allocation du head** — trois questions indépendantes (coordination,
   incertitude, conséquence), max des deux premières, seuil abaissé d'un cran si la conséquence
   est forte (`head-governance.md` §1 « Trois questions avant l'échelle »). Emprunté au routeur
   OpenCode lite/build.
3. **Surface d'injection réduite par un espace de réponse fermé** — un juge qui ne peut répondre
   que dans un enum ne peut, au pire, que choisir une mauvaise option valide (mémoire : « le dépôt
   jugé pilote le juge », Codex 2/3). Retenu comme argument pour formaliser les verdicts en enum,
   pas comme mécanisme livré.

## Ce qu'on ne fait pas

- Remplacer un **gate machine** par un juge probabiliste — contredit « une preuve doit pouvoir
  rendre rouge ».
- Dépendre en dur d'un modèle propriétaire de neuf jours, en liste d'attente. Le précédent GSD
  (dépôt archivé après rug pull) s'applique.

## Ce qui reste à mesurer — spike proposé (non planifié, arbitrage humain requis)

`/gsd-spike` sur nos propres données, **en français** : rejouer N décisions passées du head
(allocation) et N verdicts de revue/audit tirés des rapports de mission archivés, avec trois juges
typés — Haiku via l'adaptateur ouvert de TypeSafe, AnyJev + Qwen3 local, Jev si accès obtenu.
Vérité terrain = les arbitrages humains réellement rendus. Sorties attendues : précision par juge,
ECE, et la position du `SEUIL_CONFIANCE` qui sépare le mieux les verdicts confirmés des verdicts
renversés. Sans cette mesure, `SEUIL_CONFIANCE = 0.6` reste une valeur empruntée, pas mesurée.

Voie de branchement si le spike est positif : une capacité **optionnelle** `vf-decide` — backend
configurable (Jev / AnyJev local / repli Claude), servie en HTTP donc indifférente au runtime
(Claude Code, Codex, kimi-code), candidats naturels : hook `Stop` (garde anti-vert prématuré),
`PreToolUse` (commandes destructives), boucle `vf-test-orchestrator` (choix de l'action suivante
sur arbre d'accessibilité, comme Callstack).

## Sources

- TypeSafe — Introducing System One Models & Jev : <https://typesafe.ai/blog/introducing-system-one-models-and-jev>
- Jev, Clearly Explained : <https://blog.dailydoseofds.com/p/jev-clearly-explained>
- Is Jev open source? : <https://jevmodel.org/is-jev-open-source/>
- Nokia AnyJev (MarkTechPost, 2026-09-23) : <https://www.marktechpost.com/2026/09/23/nokia-open-sources-anyjev-a-training-free-layer-that-turns-any-open-llm-into-a-calibrated-decision-model/>
- open-alternative-jev : <https://github.com/ikermoel/open-alternative-jev> · open-jev : <https://github.com/kyegomez/open-jev>
- awesome-jev-by-typesafe : <https://github.com/Anil-matcha/awesome-jev-by-typesafe>
- jev-superpowers : <https://github.com/AkashPriyadarshii/jev-superpowers>
- jev-for-all : <https://github.com/emirbartu/jev-for-all>
- jev-agentic-ops : <https://github.com/obekt/jev-agentic-ops>
- Routing OpenCode Tasks with Jev : <https://dev.to/lbobylev/routing-opencode-tasks-with-jev-2c4n>
- Callstack — Jev for mobile QA : <https://www.callstack.com/blog/exploring-jev-for-mobile-qa-with-agent-device>
- Jevals : <https://jevals.com/> · Jev after eight days of independent tests : <https://dev.to/gde/jev-after-eight-days-of-independent-tests-level-with-mid-price-llms-behind-the-frontier-1kln>
- Arize — Jev vs LLM-as-a-Judge : <https://arize.com/blog/jev-llm-judge-benchmark/>
