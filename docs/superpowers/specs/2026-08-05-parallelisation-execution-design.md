# Design — Parallélisation d'exécution : ce qui dort, ce qui ment, et ce qui n'est pas outillé

> **▶ STATUT : PRÊTE À CADRER — Phase 27.** Établie le 2026-08-05 à la demande de Samuel, à la
> clôture de la Phase 24 : « parallélisation complète, simple et granulaire. Le but est de gagner du
> temps d'exécution sans que les agents se marchent dessus. »
>
> **Date** : 2026-08-05
> **Modules visés** : `conductor` (doctrine `team-kernel.md`, `dag.sh`), `dev-orchestrator`,
> tous les modules portant des agents (frontmatter `isolation:`)
> **Antécédents** : ADR-064 (un écrivain = un worktree, amendée en Phase 24), ADR-069 (adoption des
> workstreams, Iron Law 2 révisée), ADR-031 (jamais de fix sans validation humaine)
> **Recherche source** : `.planning/research/2026-08-05-parallelisation-execution.md` (497 lignes)
> **Version du moteur au moment de l'établissement** : `@opengsd/gsd-core` 1.9.1

---

## 0. Résumé pour décideur

Trois faits, dont deux inattendus :

1. **Le parallélisme intra-étape n'est pas perdu, il est éteint.** La Phase 24 a mesuré juste et
   conclu faux. La doctrine livrée dans `team-kernel.md:64-65` affirme « perdu » — c'est **faux**, et
   cette fausseté est aujourd'hui distribuée à chaque lab.
2. **Le gain est déjà là et non pris.** Le partitionneur amont appliqué aux 12 plans réels de la
   Phase 24 rend **4 étages au lieu de 12 exécutions sérielles — plafond 3,00× — avec zéro collision
   de fichier** sur les quatre vagues.
3. **La sécurité du parallélisme n'est tenue par aucune machine.** `dag.sh` déclare un `scope[]` par
   nœud et **ne calcule jamais** la disjonction : deux nœuds déclarant le même fichier sortent tous
   deux `ready`.

Et un quatrième, qui invalide la piste que Samuel proposait : **les workstreams ne sont pas l'outil**
(`grep -c "workstream" execute-phase.md` → **0**). Le mécanisme qui répond au besoin est
`isolation: worktree`.

---

## 1. La correction de prémisse

### 1.1 Ce que la Phase 24 a établi, et qui reste vrai

`shouldFlattenDispatch()` rend bien `true` sous Claude Code — **re-vérifié le 2026-08-05** par appel
direct : `shouldFlattenDispatch('claude') === true`. Le descripteur d'hôte porte
`backgroundDispatch: false`, et `gsd-execute-phase` sérialise ses vagues **par décision**.

### 1.2 Ce que la Phase 24 en a conclu, et qui est faux

`plugin/conductor/references/team-kernel.md:64-65` :

> « le parallélisme **intra-étape** (les vagues de plans d'une même étape, côté moteur) est
> **perdu** »

Le mot est trop fort et la conclusion ne suit pas de la mesure. **Le chemin qui restaure ce
parallélisme ne passe pas par `shouldFlattenDispatch()`.**

### 1.3 Le chemin réel — vérifié sur pièces

La capability `claude_orchestration` s'appuie sur l'outil **Workflow** de Claude Code. Son gate n° 4
(`claude-orchestration.cjs:198-202`) lit :

```js
const nested = dispatch['nested'];
const background = dispatch['background'];
if (nested !== true || background !== true) {
    return inline('workflow_tool_unavailable');
}
```

**Il ne lit jamais `backgroundDispatch`.** Le commentaire qui précède (`:186-192`) est explicite :

> *« Note: this is NOT the canonical `shouldFlattenDispatch` rule (which keys on
> `backgroundDispatch`); the Workflow backend works precisely because a single tool-call orchestrates
> internally, **sidestepping the backgroundDispatch:false limitation**. »*

Or le descripteur Claude porte `nested: true` **et** `background: true` (mesuré Phase 24). **Le gate
n° 4 passe.**

### 1.4 Le verrou réel — gate n° 5

```js
// 5. an unknown agentSdkVersion cannot be trusted to meet the floor.
if (!isValidSemver(input.agentSdkVersion)) {
    return inline('agent_sdk_version_unknown');
}
```

Claude Code embarque son SDK **dans un binaire** au lieu de l'exposer en paquet npm : le routeur, qui
cherche `@anthropic-ai/claude-agent-sdk/package.json` en remontant `node_modules`, ne trouve rien.
Contournement documenté en amont (`claude-orchestration-command-router.cjs:157`) :
`GSD_AGENT_SDK_VERSION`, ou `--agent-sdk-version <ver>` pour épingler.

**Conséquence de cadrage** : ce n'est pas une limite de capacité, c'est un **problème de détection de
version**. À traiter comme tel — et non comme un chantier d'architecture.

---

## 2. Le gain disponible, mesuré

Le partitionneur amont (`partitionStages`) appliqué aux **12 `*PLAN.md` réels de la Phase 24** :

| Vague | Plans | Étages après partition | Paires en collision de fichier |
|---|---|---|---|
| 1 | 5 | 1 | **0** |
| 2 | 4 | 1 | **0** |
| 3 | 2 | 1 | **0** |
| 4 | 1 | 1 | 0 |

**12 → 4 étages, plafond 3,00×.** Le planificateur produit déjà des vagues parfaitement disjointes :
le parallélisme est **sûr et gratuit** sur le corpus réel.

> ⚠️ **Un plafond d'étages n'est pas un gain d'horloge.** 3,00× borne ce que la parallélisation peut
> rendre si chaque plan coûtait le même temps ; le gain réel dépend de la distribution des durées et
> du plan le plus lent de chaque étage. **Toute citation de ce chiffre doit porter la distinction.**
> L'estimation d'horloge de l'option 2 (§4) est de **1,8–2,5×**, et elle est dite estimée.

---

## 3. Le trou de granularité

### 3.1 Le fait

`dag.sh` déclare un champ `scope[]` par nœud mais **ne calcule jamais** la disjonction. Testé :
trois nœuds dont **deux déclarent le même `src/x.md`** → `ready: ["a","b","c"]`.

**Les deux écrivains du même fichier sortent en parallèle.** La sécurité du parallélisme inter-nœuds
— le seul effectif aujourd'hui — ne repose donc sur **aucune machine**, seulement sur le jugement du
manager à chaque dispatch. Il a bien tenu en Phase 24 (zéro collision sur 4 vagues) ; rien ne garantit
qu'il tienne la prochaine fois.

### 3.2 Le piège de nommage à ne pas répéter

`check-overlaps.sh`, **malgré son nom**, traite du routage entre briques tierces (ADR-057), **pas des
périmètres d'écriture**. Un lecteur pressé le prendrait pour le gate manquant. Toute brique produite
par la Phase 27 doit porter un nom qui dit son objet.

### 3.3 Ce que l'amont fait déjà

`partitionStages()` calcule exactement cette disjonction, sur `files_modified`. **Le refaire
localement serait une réimplémentation** — précisément ce que l'Iron Law 2 révisée (ADR-069)
proscrit : *« Router, jamais forker — une capacité amont partiellement couverte se câble en écrivant
ses limites, elle ne se réimplémente pas. »*

---

## 4. Les trois options

| | Option | Coût | Gain | Nature |
|---|---|---|---|---|
| **1** | **`isolation: worktree` en frontmatter d'agent** | frontmatters ; `.claude/worktrees/` **absent du `.gitignore`** ; `.worktreeinclude` **absent** | **aucun gain de vitesse** | **prérequis de sécurité** |
| **2** | **Activer `claude_orchestration`** | **zéro ligne de logique**, repli fail-closed intégral | **1,8–2,5× d'horloge (estimé)** | active une capacité amont écrite |
| **3** | **Porter le partitionneur dans `dag.sh`** | réimplémentation locale | — | **à ne pas faire maintenant** (§3.3) |

### 4.1 Option 1 — le prérequis

`check-agents.sh` liste **déjà** `isolation` dans ses clés `KNOWN` et n'admet que la valeur
`worktree`. **Zéro agent sur 25 la déclare.** L'outillage de validation existe donc avant l'usage —
situation exactement symétrique des capacités dormantes de la Phase 24.

Deux manques matériels à combler avec : `.claude/worktrees/` n'est pas dans le `.gitignore`, et il
n'existe aucun `.worktreeinclude`.

### 4.2 Option 2 — le gain

Zéro logique à écrire. Le repli est **fail-closed de bout en bout** : capability désactivée, runtime
non-Claude, descripteur incapable, version SDK inconnue ou sous le plancher, manifeste malformé — tout
manquement dégrade vers le dispatch inline **identique à l'octet près** au comportement actuel.

### 4.3 Chemin proposé

**1 → spike de 2 → 2.** L'option 1 d'abord parce qu'elle ne fait rien gagner mais rend le reste sûr.
Le spike parce que l'option 2 change le **mode de dispatch de toute exécution** — ce n'est pas un
réglage qu'on bascule sans l'avoir vu tourner.

---

## 5. Les deux points qui appellent un arbitrage humain

### 5.1 Le mur ADR-031

Un workflow **n'accepte aucune entrée utilisateur en cours de run**, et ses sous-agents tournent
**toujours en `acceptEdits`** — éditions auto-approuvées quel que soit le mode de session.

ADR-031 (« jamais de fix sans validation humaine ») est un socle du lab. Le team-kernel a déjà vu une
mission **gelée** par un `AskUserQuestion` indisponible en dispatch sous-agent — c'est arrivé dans
cette mission même, au premier tour du manager de la Phase 24.

Le repli documenté (« un étage = un workflow », l'humain arbitre entre deux étages) existe, mais il
doit être **re-prouvé sous Workflow**, pas supposé.

### 5.2 `worktree.baseRef`

Le défaut `"fresh"` branche depuis `main` et **ferait perdre le travail en cours** d'une mission.
`"head"` semble requis — mais c'est un **réglage global**, donc un choix qui engage au-delà de la
Phase 27.

---

## 6. Ce que la phase doit livrer

1. **Corriger la doctrine fausse** de `team-kernel.md:64-65`. Une doctrine livrée qui affirme
   « perdu » là où c'est « éteint » induit en erreur chaque lecteur, dans chaque lab.
2. **Poser `isolation: worktree`** là où c'est juste, avec les deux manques matériels comblés.
3. **Fermer le trou de `dag.sh`** — en câblant la disjonction amont, jamais en la réimplémentant.
4. **Instruire `claude_orchestration`** : spike, puis décision écrite (activation ou refus motivé),
   sur le patron des capacités dormantes de la Phase 24.
5. **Mesurer le gain réel** : baseline d'horloge avant, mesure après, méthode écrite. Une phase sur
   la vitesse qui ne mesure pas la vitesse n'a rien démontré.

---

## 7. Chiffres à re-dériver avant citation

La recherche diverge de la Phase 24 sur deux comptages, et **l'écart n'est pas tranché** :

| Objet | Phase 24 / ADR-069 | Recherche 2026-08-05 |
|---|---|---|
| Fichiers amont mentionnant `workstream` | **7 / 91** (critère K2) | **6** |
| Fichiers codant `.planning/` en dur | **45** | **73** |

L'écart 45 → 73 est trop large pour du bruit. **ADR-069 fait foi jusqu'à re-dérivation avec un
critère nommé.** Cette divergence est la **cinquième occurrence** du fil rouge de la Phase 24 — *un
décompte juste portant sur le mauvais ensemble* — après les 31 agents, les 52 suites, les 10 modules
et les 4 gates troués.

**Règle applicable à toute la Phase 27** : tout chiffre gravé porte sa méthode et se re-dérive au
moment de l'écriture.
