# SPIKE-REPORT — Phase 37 : portabilité multi-runtime (Codex, OpenCode, Kimi)

Milestone `fiabilite-v1.0`. Base factuelle unique : `DISCUSS.md` (même dossier, commit `7c69d98`,
127 lignes, 6 questions ROADMAP mesurées). Ce rapport n'ajoute aucune donnée absente de ce
document — tout point non couvert y est marqué « non mesuré ».

## Verdict — en deux morceaux, pas un go/no-go sec

**1. Le runtime Codex est apte** à héberger la topologie du team-kernel. Mesuré en exécution
réelle (compte ChatGPT, Codex CLI 0.150.1) : profondeur **3 arêtes** (compteur natif
`session_meta`, `DEPTH=1/2/3`), dispatch nommé fonctionnel, `model` réglable par worker
(`fork_turns: "none"` + `model`, mesuré), rapport typé `{statut, findings, noeuds_debloques}`
reconstructible par convention (JSON en cwd partagé, ou `codex exec --output-schema`) et fiable
2/2 à la mesure.

**2. Le chemin d'artefacts de gsd-core ne l'est pas.** La surface visée (8 modules de conversion/
install/layout/skill) est déclarée **interne** par le contrat écrit de gsd-core lui-même
(`host-integration-sdk.cjs`, seule frontière publique documentée, 18 clés, filtre `convert|
artifact|layout|installPlan|Skill` → 0 résultat). Le pipeline d'install n'est pas générique (résolution
par remontée `__dirname`, pas par point d'entrée public). Le registre de capacités s'est trompé
**3 fois sur 3** vérifications en exécution dans cette seule mission (Q5, table dédiée ci-dessous).
La conversion mesurée (156 cas) dégrade silencieusement — 0 exception, 0 diagnostic — sur les
champs qui portent les garanties d'agent (`model`, `memory`, `tools`, allowlist).

**La conclusion qui en découle** : la doctrine posée au cadrage de la phase — « VibeFlow consomme
la surface multi-runtime de gsd-core, il ne la réimplémente pas » — désigne précisément la partie
qui **ne tient pas** (le chemin d'artefacts gsd-core), tandis que la partie qu'elle jugeait la plus
risquée (le runtime lui-même, l'équipe de mission hors Claude) **tient très bien**. C'est le
renversement central du spike : le risque était mal placé au cadrage.

## Finding autonome — fiabilité du registre `capability-registry.cjs`

Réutilisable au-delà de cette phase. Trois vérifications en exécution, trois erreurs :

| Champ vérifié | Valeur du registre | Réalité mesurée |
|---|---|---|
| `backgroundDispatch` (codex) | `false` d'après le cadrage | c'est la ligne de **claude** ; codex vaut `true` |
| descripteur `kimi-code` | `namedDispatch: false`, built-ins seulement | **périmé** — sous-agents nommés custom, `AgentSwarm` à rapport agrégé, pool de modèles |
| `maxDepth` (codex) | `1` | **3 mesuré**, compteur natif du runtime (`session_meta` : `DEPTH= 1/2/3`) |

**Leçon** : un descripteur gsd-core est une **bonne source, jamais une preuve**. La règle « aucun
vert auto-déclaré ne tient » (mémoire `milestone-fiabilite-v1`) vaut **aussi pour les rouges** — un
no-go structurel peut être aussi faux qu'un go optimiste. Le no-go structurel envisagé au cadrage
était **rédigé et argumenté**, et reposait entièrement sur `maxDepth: 1`. C'est le refus de le
prononcer sans vérification en exécution qui a évité l'erreur — la mesure a renversé la prémisse.

## Coût de portage résiduel

| Item | Mesure | Implication |
|---|---|---|
| Mapping de noms | `agent_name` doit matcher `[a-z0-9_]+` (erreur runtime verbatim) | les 31 identifiants `vf-*`/`gsd-*` à tirets rejetés tels quels — adaptateur de nommage requis |
| Largeur de concurrence | 4 slots disponibles → 3 workers concurrents max sous un manager | à confronter au dispatch parallèle de frontière du team-kernel (ex. crafts multi-écrans, corrections multi-fichiers) |
| Digest de mission | `fork_turns: "none"` (nécessaire pour choisir le modèle par worker) n'hérite d'aucun contexte | tout le digest de mission doit passer dans le task text, pas de raccourci par héritage |
| Rapport typé | reconstructible par convention (JSON en cwd partagé + `codex exec --output-schema`) | fiable 2/2 à la mesure — pas un point bloquant |
| Mode collaboration | `--ephemeral` casse le spawn (`collab spawn failed: no thread with id`) | le mode collaboration exige un thread persisté, contrainte d'architecture d'exécution |
| Placement manuel | 21 règles de placement (7 pour codex seul, deux homes distincts : `~/.agents/skills/` et `~/.codex/agents/`) | 6 fragments de hooks sans convertisseur utilisable (`buildCodexHookBlock` câblé en dur sur gsd-core) ; opencode `hooksSurface: 'none'` → 6 fragments perdus par construction |
| Couture engine | 1 site de calcul de `TARGET_ROOT` (l. 105-109 de `vibeflow-update.sh`, jamais réassigné) + 15 littéraux `.claude` (13 dans `gitignore_add_paths`, 2 dans `scripts_prefix_for_scope`) | couture minimale : rendre le site injectable + paramétrer les littéraux ; le reste hors engine via `merge-hooks.sh` (déjà externe) et `vf_place_file`/`vf_place_tree` |

## Fidélité de conversion — le chiffre le plus dur du spike

156 conversions mesurées (31 agents + 21 skills × 3 cibles) : **0 exception, 0 retour nul, 0
diagnostic** — et pourtant une dégradation massive et silencieuse : `model` perdu 31/31,
`memory` 31/31, `tools` 25/25, `disallowedTools` 6/6, `vf-internal` 19/19 sur codex, allowlist
`Agent(...)` diluée en prose (codex) ou purement supprimée (opencode — un juge conçu pour ne pas
écrire, `vf-design-judge`, y perd son interdiction). Le bloc adaptateur couvre 21/21 skills et
**0/31 agents**, alors que ce sont les agents qui portent les protocoles. Conséquence directe :
la garantie ADR-044 (« agents natifs machine-enforced ») ne survit à **aucune** des trois cibles
mesurées.

**Recommandation sur le gate de fidélité** : c'est le livrable le plus défendable d'une éventuelle
suite, précisément parce qu'aucun signal machine n'existe aujourd'hui pour distinguer « converti »
de « converti et mort ». Un tel gate devrait compter, au minimum : les champs perdus par
conversion (`model`/`memory`/`tools`/`disallowedTools`/`vf-internal`/allowlist) par agent et par
cible, les marqueurs dangling (chemins `.claude` morts — 46/52 sur opencode, 52/52 sur kimi-code ;
`Task(` non traduit 4/4 partout), et le périmètre réellement actif déclaré à l'install (ex. sur
kimi-code : 31 agents copiés à l'octet dans un runtime `namedDispatch: false` → 52 fichiers posés
dont 31 inertes, sans qu'aucun mécanisme ne le signale).

## Ce qui reste inconnu (non comblé par ce spike)

- Profondeur > 3 arêtes non testée.
- Saturation des 4 slots de concurrence non provoquée.
- Rôles custom `~/.codex/agents/*.toml` non utilisés (`agent_role` resté `null` dans les mesures).
- Acceptation réelle des artefacts convertis par OpenCode et Kimi — aucun des deux runtimes n'est
  installé sur le poste de mesure.
- Support d'élicitation OpenCode annoncé sur branches dev/v2 non vérifié en release stable.

## Recommandation — argumentée, non tranchée

**La décision go/no-go appartient à Samuel (ADR-031).** Ce qui suit distingue ce que la mesure
établit de ce que je recommande d'en faire.

Ce que la mesure établit : la partie « équipe de mission hors Claude » n'est plus le risque —
Codex la porte, mesuré en exécution. Le risque s'est déplacé entièrement sur le chemin d'artefacts
gsd-core, qui est interne par contrat écrit et dont le registre de capacités a été pris en défaut
3 fois sur 3.

Les 4 voies possibles, telles qu'exposées dans `DISCUSS.md` (§Décision à prendre), avec leurs
coûts : dépendre de l'interne tel quel (zéro garantie SemVer, rupture possible à chaque mise à
jour de gsd-core sans préavis), demander l'élargissement du SDK public en amont (délai hors
contrôle de VibeFlow), construire un adaptateur VibeFlow minimal (maintenance d'une couche de
conversion propre, mais garanties ADR-044 restaurées sous contrôle VibeFlow), ou renoncer (rester
Claude-only, zéro dette supplémentaire).

Ma recommandation : l'adaptateur VibeFlow minimal (voie 3), scoped au strict nécessaire mesuré
dans ce spike — préserver `model`/`memory`/`tools`/`disallowedTools`/`vf-internal`/allowlist sur
les 31 agents, corriger le nommage `name` ≠ dossier sur les 3 skills concernés (Q3), mapper les
noms d'agents vers `[a-z0-9_]+` sur codex (Q4) — combinée à la démarche amont (voie 2) en parallèle
et sans dépendance bloquante : une requête d'élargissement du SDK public ne coûte rien à lancer
tôt, même si son délai est hors contrôle de VibeFlow. Je ne recommande pas de dépendre de l'interne
tel quel (voie 1) sans au minimum les tests de contrat de dérive qu'elle nécessiterait — c'est la
voie la moins défendable après ce qui vient d'être mesuré sur la fiabilité du registre. Rien de
tout cela ne se lance sans l'arbitrage de Samuel, y compris le choix de ne pas donner suite
(voie 4).

## Rapport final

```json
{
  "statut": "gaps_found",
  "findings": [
    {
      "sujet": "Doctrine de cadrage vs mesure",
      "constat": "\"VibeFlow consomme la surface gsd-core, ne la réimplémente pas\" tient pour le runtime Codex (profondeur 3 mesurée, pas 1) mais pas pour le chemin d'artefacts gsd-core (interne par contrat écrit, pipeline d'install non générique, registre faux 3/3)",
      "action": "ask-user"
    },
    {
      "sujet": "Fiabilité capability-registry.cjs",
      "constat": "3 vérifications en exécution, 3 erreurs (backgroundDispatch codex, descripteur kimi-code périmé, maxDepth codex 1 vs 3 réel) — bonne source, jamais une preuve",
      "action": "no-op"
    },
    {
      "sujet": "Fidélité de conversion",
      "constat": "156 conversions mesurées, 0 erreur machine, dégradation massive et silencieuse (model/memory/tools/disallowedTools/vf-internal/allowlist) — aucun signal ne distingue converti de converti-et-mort",
      "action": "ask-user"
    },
    {
      "sujet": "Voie de suite (adaptateur / upstream / dépendance interne / renoncer)",
      "constat": "4 voies coûtées dans DISCUSS.md, aucune tranchée par ce spike ; recommandation formulée (adaptateur minimal + démarche amont en parallèle) sans autorité de décision",
      "action": "ask-user"
    }
  ],
  "noeuds_debloques": []
}
```

Commit : (voir sortie `git log -1 --format=%H` après commit du présent fichier).
