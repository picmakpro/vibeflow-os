# SPIKE-REPORT — Phase 37 : portabilité multi-runtime (Codex, OpenCode, Kimi)

Milestone `fiabilite-v1.0`. Base factuelle unique : `DISCUSS.md` (même dossier, version courante
du fichier — 6 questions ROADMAP mesurées). Ce rapport n'ajoute aucune donnée absente de ce
document — tout point non couvert y est marqué « non mesuré ». **Note de méthode (B1)** : aucun SHA
n'est figé ici, y compris pour ce document lui-même — un commit qui introduit un fichier ne peut
jamais désigner sa propre version future ; git porte déjà l'historique.

## Verdict — en deux morceaux, pas un go/no-go sec

**1. Le runtime Codex est apte, sur la profondeur mesurée** à héberger la topologie du
team-kernel — 3 arêtes disponibles, 2 utilisées par la topologie actuelle ; la **largeur** n'a pas
été confrontée au dispatch parallèle de frontière (cf. §Ce qui reste inconnu). Mesuré en exécution
réelle (compte ChatGPT, Codex CLI 0.150.1) : profondeur **3 arêtes** (compteur natif
`session_meta`, `DEPTH=1/2/3`), dispatch nommé fonctionnel, `model` réglable par worker
(`fork_turns: "none"` + `model`, mesuré), rapport typé `{statut, findings, noeuds_debloques}`
reconstructible par convention (JSON en cwd partagé, ou `codex exec --output-schema`) et fiable
2/2 à la mesure.

**2. Le chemin d'artefacts de gsd-core ne l'est pas.** La surface visée (8 modules de conversion/
install/layout/skill) est déclarée **interne** par le contrat écrit de gsd-core lui-même
(`host-integration-sdk.cjs`, seule frontière publique documentée, 18 clés, filtre `convert|
artifact|layout|installPlan|Skill` → 0 résultat). Le pipeline d'install n'est pas générique (résolution
par remontée `__dirname`, pas par point d'entrée public). Cette mission a produit **3 constats de
non-fiabilité autour des descripteurs consultés**, dont un seul est une erreur du registre
vérifiée en exécution (Q5, table dédiée ci-dessous).
La conversion mesurée (156 cas) dégrade silencieusement — 0 exception, 0 diagnostic — sur les
champs qui portent les garanties d'agent (`model`, `memory`, `tools`, allowlist).

**La conclusion qui en découle** : la doctrine posée au cadrage de la phase — « VibeFlow consomme
la surface multi-runtime de gsd-core, il ne la réimplémente pas » — désigne précisément la partie
qui **ne tient pas** (le chemin d'artefacts gsd-core), tandis que la partie qu'elle jugeait la plus
risquée (le runtime lui-même, l'équipe de mission hors Claude) **tient très bien**. C'est le
renversement central du spike : le risque était mal placé au cadrage.

## Finding autonome — fiabilité du registre `capability-registry.cjs`

Réutilisable au-delà de cette phase. Trois constats de non-fiabilité autour des descripteurs, de
nature différente — un seul est une erreur du registre vérifiée en exécution :

| Champ vérifié | Valeur du registre | Réalité mesurée | Nature du constat |
|---|---|---|---|
| `maxDepth` (codex) | `1` | **3 mesuré**, compteur natif du runtime (`session_meta` : `DEPTH= 1/2/3`) | **erreur du registre, vérifiée en exécution** |
| `backgroundDispatch` (codex) | `codex: true` / `claude: false` (le registre avait raison) | le cadrage avait lu la ligne de **claude** au lieu de celle de codex | **erreur de lecture du cadrage**, pas du registre |
| descripteur `kimi-code` | `namedDispatch: false`, built-ins seulement | **obsolescence documentaire** constatée par lecture de la doc kimi-code courante — sous-agents nommés custom, `AgentSwarm` à rapport agrégé, pool de modèles | **jamais vérifiée en runtime** (kimi-code non installé sur le poste de mesure) |

**Leçon** : un descripteur gsd-core est une **bonne source, jamais une preuve** — même quand,
comme ici, il n'est en tort que sur un seul champ des trois examinés. La règle « aucun vert
auto-déclaré ne tient » (mémoire `milestone-fiabilite-v1`) vaut **aussi pour les rouges** — un
no-go structurel peut être aussi faux qu'un go optimiste. Le no-go structurel envisagé au cadrage
était **rédigé et argumenté**, et reposait entièrement sur `maxDepth: 1` — l'unique erreur de
registre vérifiée en exécution était à elle seule porteuse de ce no-go erroné. C'est le refus de
le prononcer sans vérification en exécution qui a évité l'erreur — la mesure a renversé la
prémisse. Le cas `backgroundDispatch` ajoute un danger voisin mais distinct : celui de **mal
lire** un descripteur qui, lui, était juste.

## Coût de portage résiduel

| Item | Mesure | Implication |
|---|---|---|
| Mapping de noms | `agent_name` doit matcher `[a-z0-9_]+` (erreur runtime verbatim, **3 rejets mesurés verbatim**) | les 31 identifiants portent tous un tiret, donc tous concernés **par construction** — adaptateur de nommage requis |
| Largeur de concurrence | 4 slots disponibles (mesuré) | **dérivé** (soustraction, saturation jamais provoquée) : 3 workers concurrents max sous un manager, à confronter au dispatch parallèle de frontière du team-kernel (ex. crafts multi-écrans, corrections multi-fichiers) |
| Digest de mission | `fork_turns: "none"` (nécessaire pour choisir le modèle par worker) n'hérite d'aucun contexte | tout le digest de mission doit passer dans le task text, pas de raccourci par héritage |
| Rapport typé | reconstructible par convention (JSON en cwd partagé + `codex exec --output-schema`) | fiable 2/2 à la mesure — pas un point bloquant |
| Mode collaboration | `--ephemeral` casse le spawn (`collab spawn failed: no thread with id`) | le mode collaboration exige un thread persisté, contrainte d'architecture d'exécution |
| Placement manuel | **13 règles de placement** (codex 4, opencode 6, kimi-code 3 — relevé direct de `artifactLayout.global.length + artifactLayout.local.length` dans `capability-registry.cjs` pour chacun des 3 runtimes ; codex a deux homes distincts pour ses règles : `~/.agents/skills/` et `~/.codex/agents/`) | 6 fragments de hooks sans convertisseur utilisable (`buildCodexHookBlock` câblé en dur sur gsd-core) ; opencode `hooksSurface: 'none'` → 6 fragments perdus par construction **(dérivé du descripteur, non vérifié en runtime — opencode non installé sur le poste de mesure)** |
| Couture engine | 1 site de calcul de `TARGET_ROOT` (l. 105-109 de `vibeflow-update.sh`, jamais réassigné) + 16 sites portant un littéral `.claude` (14 dans `gitignore_add_paths`, 2 dans `scripts_prefix_for_scope`) — soit 15 littéraux distincts (`.claude/agents/${mod}-references/` apparaît deux fois) | couture minimale : rendre le site injectable + paramétrer les littéraux ; le reste hors engine via `merge-hooks.sh` (déjà externe) et `vf_place_file`/`vf_place_tree` |

## Fidélité de conversion — le chiffre le plus dur du spike

156 conversions mesurées (31 agents + 21 skills × 3 cibles) : **0 exception, 0 retour nul, 0
diagnostic** — et pourtant une dégradation massive et silencieuse : `model` perdu 31/31
**sur codex et opencode** (kimi-code copie les 31 agents à l'octet près, cf. plus bas — ce champ
n'y est pas perdu), et **par le même raisonnement** `memory` 31/31, `tools` 25/25,
`disallowedTools` 6/6 sont eux aussi des pertes **sur codex et opencode seulement**, `vf-internal`
19/19 sur codex, allowlist `Agent(...)` diluée en prose (codex) ou purement supprimée (opencode —
un juge conçu pour ne pas écrire, `vf-design-judge`, y perdrait son interdiction **selon le
descripteur, non vérifié en runtime : opencode n'est pas installé sur le poste de mesure**). Le
bloc adaptateur couvre 21/21 skills et
**0/31 agents**, alors que ce sont les agents qui portent les protocoles. Conséquence directe :
la garantie ADR-044 (« agents natifs machine-enforced ») ne survit **ni à codex ni à opencode**
(les deux cibles où le champ `agents` passe par un convertisseur qui la réécrit) — **elle survit
sur kimi-code**, dont le descripteur de registre déclare `converter: null` pour la kind `agents` :
copie à l'octet près, confirmée par lecture directe de `capability-registry.cjs`, cohérente avec
le constat plus haut sur `model`.

**Correction — la couverture skills n'est pas totale, et l'erreur est du même ordre que celle des
agents.** Le bloc précédent range « 21/21 skills couverts » comme si le côté skills était sain ;
il ne l'est pas. `extractFrontmatterField` (`runtime-artifact-conversion.cjs:924-930`) capture la
frontmatter par une regex mono-ligne `^description:\s*(.+)$` : sur un scalaire replié YAML
(`description: >`, suivi du texte sur les lignes indentées suivantes — la forme que 15 des 21
skills installables utilisent, ex. `plugin/planning-core/SKILL.md:3`), elle ne capture que le
littéral `>` et jette tout le reste. **Vérifié en exécutant les trois convertisseurs de skill réels
sur `plugin/planning-core/SKILL.md`** (`convertClaudeCommandToOpencodeSkill`,
`convertClaudeCommandToKimiCodeSkill`, `convertClaudeCommandToCodexSkill`) : les trois écrivent
`description: >` verbatim, sur **les trois cibles**, sans exception ni diagnostic — même mort
silencieuse que celle du côté agents. La description est ce qui rend un skill déclenchable ; sa
perte est un skill installé mais invocable par personne. Sur les 21 skills installables mesurés
(Q3), **15 sont concernés**, pas 0 — le côté que ce rapport présentait comme intact porte en
réalité la dégradation la plus large des deux (15/21 contre au plus 31/31 sur un sous-ensemble de
champs agents, mais touchant un champ dont dépend le déclenchement même du skill, pas seulement un
protocole interne). Le gate de fidélité recommandé plus bas doit donc couvrir aussi
`description:` côté skills, pas seulement les champs agents.

**Recommandation sur le gate de fidélité** : c'est le livrable le plus défendable d'une éventuelle
suite, précisément parce qu'aucun signal machine n'existe aujourd'hui pour distinguer « converti »
de « converti et mort ». Un tel gate devrait compter, au minimum : les champs perdus par
conversion (`model`/`memory`/`tools`/`disallowedTools`/`vf-internal`/allowlist) par agent et par
cible, les marqueurs dangling (**rejoué en exécutant les convertisseurs réels de gsd-core** —
`runtime-artifact-conversion.cjs` — sur les 52 artefacts source, opencode et kimi-code n'étant
toujours pas installés sur le poste de mesure) : chemins `.claude` morts dans **25/52 fichiers**
sur opencode (**150 occurrences**) et **26/52 fichiers** sur kimi-code (**163 occurrences**) —
« fichiers » et « occurrences » sont deux dénominateurs distincts, à ne pas confondre ; `Task(` non
traduit dans **3 fichiers / 5 occurrences** sur les deux cibles. Le plafond « 52/52 » est de toute
façon arithmétiquement impossible : seuls **26 des 52 fichiers source** contiennent la chaîne
`.claude` avant conversion. Et le périmètre réellement actif déclaré à l'install (ex. sur kimi-code :
31 agents copiés à l'octet dans un runtime dont le descripteur porte `namedDispatch: false` → 52
fichiers posés, dont potentiellement 31 inertes **selon ce descripteur — que ce même rapport
déclare par ailleurs périmé ; si kimi-code dispatche bien des sous-agents nommés custom comme la
doc courante le décrit, ces 31 agents ne sont pas inertes** ; aucun mécanisme ne signale l'un ou
l'autre cas).

## Q4b — l'escalade humaine

C'est le seul trou structurel que le ROADMAP désignait, et il mérite sa propre section : la
prémisse ROADMAP (« aucun équivalent hors Claude ») est **fausse** — les trois runtimes portent un
outil de forme AskUserQuestion (Codex : `request_user_input` ; OpenCode : `question` ; Kimi :
`AskUserQuestion`, quasi isomorphes). Le **vrai trou est le mode headless, et il est universel** :
sur Codex, `request_user_input` est barré deux fois en dur et rejeté sous `codex exec` ;
l'élicitation MCP y est auto-annulée (ni refus ni accord) ; sur OpenCode, l'outil `question`
**pendrait** en headless et le correctif en cours viserait à le faire **échouer**, pas à répondre —
**dérivé de la documentation et des issues amont, non vérifié en runtime : OpenCode n'est pas
installé sur le poste de mesure** (issue amont citée : OpenCode #35275, qui cite Codex en miroir —
suspendre l'horloge plutôt qu'arbitrer un timeout ; Codex a déprécié `autoResolutionMs` au profit
d'`isBlocking`) ; Kimi est le seul des trois à porter un contrat fail-loud écrit.

Conséquence de design : **ne jamais autoriser une question dans un worker headless**, mais la
relayer hors bande vers une session racine vivante — c'est le relais Pattern H / `SendMessage` que
VibeFlow **possède déjà**, ce qui en fait un actif portable plutôt qu'un mécanisme à construire.
Et une **interdiction formelle de `opencode run --auto`**, seul mécanisme identifié qui convertit
l'absence d'humain en consentement automatique.

Source : `DISCUSS.md` l. 44-46 (§Q4b).

## Ce qui reste inconnu (non comblé par ce spike)

- Profondeur > 3 arêtes non testée.
- Saturation des 4 slots de concurrence non provoquée.
- Rôles custom `~/.codex/agents/*.toml` non utilisés (`agent_role` resté `null` dans les mesures).
- Acceptation réelle des artefacts convertis par OpenCode et Kimi — aucun des deux runtimes n'est
  installé sur le poste de mesure.
- Support d'élicitation OpenCode annoncé sur branches dev/v2 non vérifié en release stable (cf.
  §Q4b ci-dessus pour ce que la mesure établit malgré tout sur le mode headless).
- L'échappatoire `.gsd-source` a deux consommateurs aux sémantiques incompatibles — constaté en Q1
  (`DISCUSS.md`), **non résolu par ce spike** (oubli du tour précédent : absent de ce rapport alors
  qu'il fait partie du morceau 2 du verdict, le chemin d'artefacts non générique).

## Recommandation — argumentée, non tranchée

**La décision go/no-go appartient à Samuel (ADR-031).** Ce qui suit distingue ce que la mesure
établit de ce que je recommande d'en faire.

Ce que la mesure établit : la partie « équipe de mission hors Claude » n'est plus le risque —
Codex la porte, mesuré en exécution. Le risque s'est déplacé entièrement sur le chemin d'artefacts
gsd-core, qui est interne par contrat écrit et dont le registre de capacités s'est montré, sur
cette seule mission, une source à vérifier en exécution avant usage — une erreur avérée
(`maxDepth`), une mauvaise lecture du cadrage qui l'accusait à tort (`backgroundDispatch`), et une
obsolescence documentaire jamais confrontée au runtime (`kimi-code`).

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
voie la moins défendable après ce qui vient d'être constaté sur les descripteurs consultés :
une erreur vérifiée en exécution suffit à faire basculer un no-go structurel, et deux autres
constats (mauvaise lecture du cadrage, obsolescence documentaire non confrontée au runtime)
montrent qu'aucune des deux directions — croire le registre ou le corriger de mémoire — n'est
sûre sans vérification. Rien de
tout cela ne se lance sans l'arbitrage de Samuel, y compris le choix de ne pas donner suite
(voie 4).

## Rapport final

```json
{
  "statut": "human_needed",
  "findings": [
    {
      "sujet": "Doctrine de cadrage vs mesure",
      "constat": "\"VibeFlow consomme la surface gsd-core, ne la réimplémente pas\" tient pour le runtime Codex (profondeur 3 mesurée, pas 1) mais pas pour le chemin d'artefacts gsd-core (interne par contrat écrit, pipeline d'install non générique)",
      "severity": "majeur",
      "action": "ask-user",
      "ref": "DISCUSS.md#décision-à-prendre-non-tranchée---adr-031"
    },
    {
      "sujet": "Fiabilité capability-registry.cjs",
      "constat": "3 constats de non-fiabilité autour des descripteurs, dont un seul est une erreur du registre vérifiée en exécution (maxDepth codex 1 vs 3 réel) ; un deuxième est une erreur de lecture du cadrage (backgroundDispatch — le registre avait raison) ; un troisième est une obsolescence documentaire non vérifiée en runtime (kimi-code) — bonne source, jamais une preuve",
      "severity": "mineur",
      "action": "no-op",
      "ref": "DISCUSS.md#q5--déclaration-de-capacité"
    },
    {
      "sujet": "Fidélité de conversion",
      "constat": "156 conversions mesurées, 0 erreur machine, dégradation massive et silencieuse côté agents (model/memory/tools/disallowedTools/vf-internal/allowlist, sur codex et opencode — kimi-code copie à l'octet près) ET côté skills (description: perdue en entier sur 15/21 skills installables, sur les trois cibles, extractFrontmatterField ne gère pas le scalaire replié YAML) — aucun signal ne distingue converti de converti-et-mort",
      "severity": "majeur",
      "action": "ask-user",
      "ref": "DISCUSS.md#fidélité-de-conversion--la-dégradation-silencieuse-chiffrée"
    },
    {
      "sujet": "Voie de suite (adaptateur / upstream / dépendance interne / renoncer)",
      "constat": "4 voies coûtées dans DISCUSS.md, aucune tranchée par ce spike ; recommandation formulée (adaptateur minimal + démarche amont en parallèle) sans autorité de décision",
      "severity": "bloquant",
      "action": "ask-user",
      "ref": "DISCUSS.md#décision-à-prendre-non-tranchée---adr-031"
    }
  ],
  "noeuds_debloques": []
}
```
