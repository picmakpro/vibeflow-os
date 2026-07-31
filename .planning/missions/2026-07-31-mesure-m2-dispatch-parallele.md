# Mesure M2 — le dispatch parallèle depuis un sous-agent (2026-07-31)

> **Objet** : trancher par la mesure, et non par lecture de descripteur, si les deux acquis de
> parallélisme du moteur de dev VibeFlow tiennent sur ce runtime. Demandé en ouverture de la
> Phase 24 (lot MESURE, constat M2), exécuté avant tout lot d'activation.

## Ce qui était en cause

Le descripteur du runtime `claude` dans `@opengsd/gsd-core@1.9.0`
(`bin/lib/capability-registry.cjs`, capability `claude`, clé `hostIntegration.dispatch`) déclare :

```
{ namedDispatch: true, nested: true, maxDepth: 5,
  background: true, backgroundDispatch: false,
  subagentToolkit: "full", isolation: "harness-worktree" }
```

`shouldFlattenDispatch()` (`bin/lib/host-integration.cjs:464`) renvoie `true` dès que
`background && backgroundDispatch` n'est pas vrai — donc **`true` pour Claude Code**. Le moteur
considère donc le dispatch parallèle indisponible ici et **aplatit** ses vagues. La capability
`claude-orchestration` (1.9.0, default-off, BETA) existe pour « *restoring the wave parallelism the
#853 backgrounded-agent nesting limitation forces inline on Claude Code* ».

Deux acquis VibeFlow reposent sur la capacité inverse :

| Acquis | Source | Ce qu'il présume |
|---|---|---|
| Fan-out de la frontière `ready` | `vf-dev-manager.md:90-96` — « dispatche-les dans **un seul message** (plusieurs Task) » | qu'un **sous-agent** peut faire tourner 2+ workers simultanément |
| Recherche doc non bloquante (ADR-045) | `vf-dev-manager.md:180-184` — « **Lance-le en background** quand un autre nœud peut avancer pendant ce temps » | qu'un **sous-agent** peut dispatcher puis **continuer à travailler** |

## Protocole

Sonde `m2-probe.sh <id> <secondes>` : horodate `start_ms`, occupe le CPU par busy-loop `node` la
durée demandée (pas de `sleep`, bloqué par le harness), horodate `end_ms`, écrit un JSON. Le temps
mesuré est donc du temps réel d'exécution, indépendant du modèle. Auto-test : 3,01 s pour 3 s
demandées. Poste : 12 cœurs — deux boucles simultanées ne se disputent pas le CPU.

Trois configurations, sondes de 20 s :

1. **CONTRÔLE** — la fenêtre principale dispatche 2 agents dans un seul message.
2. **TEST fan-out** — la fenêtre principale dispatche 1 agent, qui dispatche 2 agents dans un seul
   message (profondeur 1 → 2, la configuration `vf-dev-manager → workers`).
3. **TEST dispatch-and-continue** — un agent dispatche 1 enfant (20 s) puis, sans attendre sa
   réponse, exécute lui-même une sonde de 3 s.

## Résultats

| Configuration | Fenêtres mesurées | Décalage de démarrage | Recouvrement | Verdict |
|---|---|---|---|---|
| CONTRÔLE | B1 `[307464 → 327464]` · B2 `[309205 → 329205]` | 1741 ms | **18 259 ms / 20 000 (91 %)** | PARALLÈLE |
| TEST fan-out (depuis un sous-agent) | B1 `[368080 → 388080]` · B2 `[369620 → 389620]` | 1540 ms | **18 460 ms / 20 000 (92 %)** | PARALLÈLE |
| TEST dispatch-and-continue | enfant `[444735 → 464735]` · parent `[443717 → 446717]` | parent démarré **1018 ms avant** l'enfant, terminé 18 s avant lui | — | NON BLOQUANT |

(horodatages en ms Unix, préfixe `1785516` retiré pour la lisibilité ; PID distincts vérifiés)

## Conclusions

1. **Les deux acquis VibeFlow tiennent.** Le fan-out de frontière depuis un sous-agent est
   parallèle à 92 % — statistiquement indiscernable du contrôle (91 %). Et un sous-agent peut
   dispatcher puis continuer à travailler : le parent avait fini sa propre tâche 18 s avant son
   enfant. Le pipelining N/N+1 et la recherche doc non bloquante décrivent des gains **réels**.
2. **`backgroundDispatch: false` est conservateur, pas descriptif.** Les deux lectures possibles de
   ce champ sont démenties par la mesure sur ce poste. Le champ est *fail-closed* par conception
   (`host-integration.cjs`), ce qui est un choix prudent côté moteur — mais il ne décrit pas la
   capacité réelle du runtime.
3. **Le bridage vient donc du moteur, pas du runtime — et c'est là que se déplace le gap.**
   `gsd-execute-phase` lit `shouldFlattenDispatch()` et sérialise ses vagues **par décision**,
   alors que le runtime sait les paralléliser. Conséquence exacte : le parallélisme **intra-étape**
   (vagues de plans d'une même phase) est perdu, et seul subsiste le parallélisme **inter-nœuds**
   porté par `vf-dev-manager`. Notre couche d'orchestration ne duplique pas celle de GSD : sur ce
   runtime, **elle est la seule qui parallélise réellement**.

## Suites

- **Reformuler M2 en Phase 24** : le constat n'est plus « le parallélisme de VibeFlow est peut-être
  illusoire » (démenti) mais « GSD s'auto-bride sur ce runtime, donc le parallélisme intra-étape est
  perdu ». Trois voies non exclusives : signaler le descripteur en amont (mesure à l'appui) ·
  évaluer `claude_orchestration.enabled` (BETA, opt-in explicite, jamais par défaut) · acter que le
  parallélisme reste porté par le manager et le documenter comme tel.
- **Ce que la mesure ne couvre pas** : la profondeur 2 → 3 (`vf-coder → gsd-executor`) n'a pas été
  mesurée — elle est couverte en *déclaration* par `maxDepth: 5` (constat M1), pas par l'expérience.
  Et la mesure porte sur des agents `general-purpose` du harness, pas sur les workflows GSD
  eux-mêmes, qui aplatissent de toute façon par décision (conclusion 3).

Sonde et données brutes : scratchpad de session (`m2-probe.sh`, `m2-*.json`) — non versionnées,
les chiffres retenus sont dans le tableau ci-dessus.
