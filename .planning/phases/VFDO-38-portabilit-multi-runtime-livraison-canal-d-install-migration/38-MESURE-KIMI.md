# Mesure kimi-code — ce que la mesure établit, pas plus

**Date** : 2026-08-30 · `@moonshot-ai/kimi-code` 0.39.1, `/opt/homebrew/bin/kimi` ·
**Tokens consommés : ZÉRO**

> kimi-code passait pour un **inconnu déclaré** (OAuth en échec côté serveur). Une clé API a été
> posée par Samuel. Ce document consigne **I-1, I-2 et I-3**, toutes mesurées.
> Coût total : **~0,018 $** (I-1 à coût nul, I-2/I-3 sur 19 appels).

## Régime credential — respecté intégralement

`~/.kimi-code/` **jamais ouvert, jamais copié**. Le `config.toml` du banc a été écrit à la main,
**sans aucune clé** (`base_url http://127.0.0.1:1/v1`). Toutes les sondes s'arrêtent **avant**
l'appel modèle — d'où le coût nul.

**Banc** : `KIMI_CODE_HOME=<scratchpad>/kimi-bench-i1/home`, isolation **vérifiée par mesure**
(`kimi doctor` pointe le `config.toml` du banc, jamais le home réel).

**Portée** : `vibeflow-update.sh` **n'a PAS été invoqué** (un worker le modifiait au même moment).
Pose manuelle par `cp`. ⇒ **Cette mesure ne valide PAS le canal d'install** — elle mesure la
découverte côté kimi. Ne pas la lire autrement.

## I-1 — atteignabilité des agents posés : **20/31**

| mesure | N | résultat |
|---|---|---|
| profils découverts vs posés | 3 | **écart = 11/31** — `comm -23` rend exactement 11 noms, `comm -13` rend le vide (aucun profil fantôme) |
| sweep `--agent-file` sur les 31 | 3 | `LOADED=21` (20 VF + témoin), `INVALID_FRONTMATTER=11`, `OTHER=0` — runs 1==2==3 |
| résolution nominative | 3 | `--agent vf-dev-manager` franchit la résolution (3/3) ; `--agent vf-coder` → `Unknown agent profile` (3/3) |

**Les 11 rejetés** : `campaign-analyst`, `growth-quality-judge`, `quality-gate-client`,
`skill-creator`, `vf-business-commercial`, `vf-business-delivery`, `vf-business-finance`,
`vf-business-manager`, `vf-coder`, `vf-design-judge`, `vibeflow-design`.

⇒ Le module dev est **amputé de son worker de code** (`vf-coder`), le design de son juge **et** de
sa façade, le bundle business en entier, growth de 2 workers. **Les managers chargent — et
dispatcheraient dans le vide.**

**Témoin positif** posé et découvert dans tous les runs ⇒ les absences sont des **rejets**, pas des
ratages de pose. Runs bit-identiques (`cmp`). `timeout`/`gtimeout` absents du poste ⇒ chien de garde
perl auto-testé, aucune boucle n'a rendu `0/N` par artefact.

### La cause — nommée par le parser, prouvée par mutation bidirectionnelle

Une **`description:` en scalaire YAML simple non quoté contenant `': '`** (deux-points + espace) —
du YAML authentiquement invalide. **11/11 des rejets, et rien d'autre.**

`Invalid frontmatter ...: bad indentation of a mapping entry (2:204)`, caret posé sur le `': '`,
ligne 2 = la description dans les 11 cas. Prédicat mécanique « description en scalaire simple
contenant `': '` » : **0 faux négatif, 0 faux positif sur 31**.

Mutation dans les deux sens : `vf-coder` avec le seul `': '` remplacé → **découvert** ;
`vf-reviewer` sain + injection d'un `' Note : '` → **disparaît**.

### 🔴 Piège de remédiation — ne PAS replier en `>`

La correction spontanée (passer en bloc replié `description: >`) **rouvrirait mot pour mot** le
défaut documenté à `38-UPSTREAM-GSD-CORE-ISSUE.md` §5 : `extractFrontmatterField` de gsd-core capture
la frontmatter par une regex **mono-ligne** `^description:\s*(.+)$` et, sur un scalaire replié, ne
récupère que le littéral `>` en jetant le reste — le skill devient **invocable par personne**, sur
les trois cibles, sans diagnostic. VibeFlow a corrigé ça en **repliant les descriptions sur une
ligne** (15 skills sur 21).

**Contrainte en ciseaux.** Une seule forme satisfait les deux lames :

```yaml
description: "texte mono-ligne, avec: des deux-points, entre guillemets"
```

Valide YAML pour kimi **et** capturée par la regex de gsd-core. Le motif existe déjà dans le dépôt
(13 fichiers en guillemets, contre 68 nus et 12 repliés).

**Rien n'a été corrigé** : ces descriptions préexistent à la Phase 38, la remédiation touche 11
fichiers sur plusieurs modules, et le mandat de mesure disait « pas plus ». **Décision humaine.**

## Ce qui se perd à la conversion

**Mappés** (mêmes clés) : `name`, `description`, `tools`, `disallowedTools`.

**Perdus en silence** — tolérés au chargement, sans effet : `model` (31/31 — kimi n'a que
`model_preference: primary|secondary`), `effort` (31/31), `memory` (31/31), **`vf-internal` (19/31)**,
`vf-requires` (5/31), `skills` (4/31), `vf-mcp-consumer` (4/31), `vf-mcp-tools` (1/31).

⇒ **Conséquence doctrinale : `vf-internal: true` perdu = le Pattern 12 ne tient plus.** Un worker
interne devient **publiquement invocable** par `kimi --agent vf-coder`. À déclarer par le gate de
fidélité au même titre que la mémoire per-projet.

**Bonne nouvelle** : aucun champ VibeFlow étranger n'empêche le chargement. **Pas de convertisseur
de frontmatter nécessaire pour ATTEINDRE les rôles.**

**NON ÉTABLI** : l'effet **runtime** de `tools`/`disallowedTools` (le CSV de kimi découpe
`Agent(vf-reviewer, general-purpose)` en fragments). Le vérifier exige un appel modèle → c'est I-2.

## Ordre de résolution — la découverte n'est pas post-modèle

Établi par 3 états d'erreur distincts : **(1)** bootstrap « un modèle est-il configuré » → **(2)**
scan + résolution d'agent → **(3)** validation de l'alias `-m` → **(4)** résolution du credential →
**(5)** réseau.

Sans `config.toml`, `--agent __absent__` rend `No model configured` et **la liste des profils n'est
jamais imprimée** (3/3). Avec config sans clé : `Unknown agent profile ... Available profiles: <25>`
(3/3). Et `-m nope/nope --agent __absent__` : c'est l'erreur d'**agent** qui gagne (3/3).

⇒ **Une énumération à coût nul est possible, mais exige un `default_model` configuré.** Sur une
machine non configurée, aucun diagnostic d'install ne peut se contenter de poser les fichiers.

## Noms — aucun rejet sur ce motif

**0/31** rejet lié au nom ; les 31 `name` matchent `^[a-z0-9]+(-[a-z0-9]+)*$`. Divergence
`name` vs nom de fichier : **6/31**, toutes structurelles (les `AGENT.md`, dont le nom de fichier ne
porte aucune identité).

⚠️ Un poseur qui conserverait le nom `AGENT.md` ferait entrer **6 fichiers homonymes** dans le même
répertoire — kimi ne retient qu'un `*.md` par chemin et applique « premier nom gagne ». La pose de
cette mesure s'est faite **par le `name` du frontmatter**, ce qui évite la collision ; le
comportement du **canal d'install** n'a pas été mesuré.

## Aucune surface de diagnostic (découvert en mesure, non demandé)

`kimi doctor` sur un banc peuplé de 11 agents cassés rend **« All checked config files are valid »**
— il ne regarde pas les agents. Le seul signal est un WARN dans `<home>/logs/kimi-code.log`,
lui-même **tronqué nativement à 233 octets** (vérifié à l'`od -c`, la raison est coupée) et plafonné
à 5 lignes (`Suppressed 6 further agent-discovery skip warnings`).

⇒ **Seul `--agent-file <chemin>` rend le message complet.** Toute recette de vérification
post-install doit passer par lui, jamais par `doctor` ni par le log.

## I-2 — `disallowedTools` bloque réellement l'écriture : **0/4 vs 3/3**

**Mesuré le 2026-08-30, coût ~0,018 $** (19 appels), régime credential option B (voir plus bas).

| sonde | N | témoin écrit ? |
|---|---|---|
| agent avec `disallowedTools: Write, Edit` | 4 | **0/4** — jamais |
| **contrôle positif** : mêmes `tools`, SANS `disallowedTools` | 3 | **3/3** — toujours |

Écart net et reproductible. **Le verdict est lu sur le fichier témoin, au `ls`/`cat`** — jamais dans
la prose du modèle.

**Mécanisme identifié en source** (`dist/main.mjs:163078`) :
`this.tools.setActiveTools(profile.tools, profile.disallowedTools)` — l'outil est **retiré du
toolset**, il n'est pas refusé à l'appel. Le modèle le formule lui-même : « L'outil Write n'est pas
disponible dans mon environnement actuel. »

⇒ **`disallowedTools` est portable sur kimi.** C'est mieux que Codex, où tout ce qui est restrictif
dans un rôle s'est révélé décoratif.

### ⚠️ Réserve — le trou Bash reste ouvert, comme sur Claude

`vf-reviewer` verbatim (Bash autorisé, `Write`/`Edit` interdits) **n'a pas écrit** (0/1) — mais **par
refus de rôle**, sans jamais tenter Bash. Et sur un autre run, le modèle a **spontanément suggéré**
`echo "MARQUEUR-OK" > temoin.txt`.

⇒ **Ne pas traiter `disallowedTools` comme une barrière d'écriture tant que `Bash` est dans `tools`.**
La garantie reste ce qu'elle a toujours été : **« pas d'outil d'édition directe »**, pas
« ne peut pas écrire ». C'est la doctrine déjà arbitrée pour Claude ; elle vaut identiquement ici.
1 run seulement ⇒ conformité **comportementale observée, pas garantie**.

## I-3 — les `[[hooks]]` se déclenchent : **3/3, positif**

Contrairement à Codex (où l'exécution est restée un inconnu déclaré faute de contrôle positif
montable), **la mesure kimi est intrinsèquement positive** : marqueur fichier appendé par la commande
du hook, remis à zéro avant chaque run.

`SessionStart`, `UserPromptSubmit` et `PreToolUse` déclenchés **à chaque run** ; `Stop` 2/3 (run 3
interrompu) ; `PreToolUse` ×2 au run 2 = deux appels d'outil.

**Schéma source** : `HookDefSchema = {event, matcher?, command, timeout?}` en `.strict()`, **20
événements** supportés — `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`,
`PermissionResult`, `UserPromptSubmit`, `UserPromptQueued`, `TurnStarted`, `Stop`, `StopFailure`,
`Interrupt`, `SessionStart`, `SessionEnd`, `SessionHeartbeat`, `SubagentStart`, `SubagentStop`,
`TaskStarted`, `PreCompact`, `PostCompact`, `Notification`.

⇒ **Canal hooks OUVERT sur kimi**, via `[[hooks]]` dans `config.toml`. Vocabulaire d'événements
**plus riche que Claude Code**.

## `vf-internal` — aucun équivalent, et le Pattern 12 tombe

**Absence établie sur quatre sources convergentes**, jamais sur une seule commande :

1. le parser de frontmatter agent-core (`dist/main.mjs:117540-117585`) n'accepte que `name`,
   `description`, `whenToUse`, `override`, `tools`, `disallowedTools`, `subagents`,
   `model_preference` — **aucun champ de mode ou de visibilité** ;
2. `vf-internal` : **0 occurrence** dans les 23 Mo du bundle (`hidden`/`visibility`/`isInternal`
   existent, mais sur la state-machine et le filtrage de messages, jamais sur les agents) ;
3. `buildSubagentDescriptions()` (`dist/main.mjs:151905`) énumère **tous** les subagents sans filtre ;
4. **MESURE** : `vf-reviewer`, qui porte `vf-internal: true`, a été **invoqué directement** en session
   réelle et **a répondu** — 1/1.

⇒ **Les 19 workers internes sont publiquement invocables sur kimi.** Le cloisonnement du Pattern 12
est une garantie **de frontmatter**, pas de runtime : elle ne survit pas à la conversion.

**Palliatif partiel, à ne pas confondre avec une solution** : le champ `subagents` de kimi (liste
blanche de qui un parent peut dispatcher) restreint **le dispatch**, mais **PAS l'invocation directe
par l'utilisateur**.

## Requalification d'une note connue — le découpage CSV

Le `split(",")` de `parseStringList` (sans conscience des parenthèses) **n'affecte PAS**
`disallowedTools`, qui ne contient pas de parenthèses : le garde-fou reste appliqué (sonde dédiée,
**0/2** écritures). Ce qu'il casse, c'est `Agent(vf-reviewer, general-purpose)` → deux noms d'outils
inexistants, **ignorés sans le moindre diagnostic**.

⇒ **La capacité de dispatch de sous-agents est perdue en silence — pas le garde-fou.** Nous avions
d'abord soupçonné l'inverse ; c'est faux, et `38-UPSTREAM-GSD-CORE-ISSUE.md` §1 porte la correction.

## Régime credential — option B, exécutée et vérifiée

Copie de `~/.kimi-code/config.toml` **uniquement** vers le `KIMI_CODE_HOME` de banc, **jamais
ouverte, jamais affichée, jamais journalisée, jamais commitée**. Écrasée `dd if=/dev/zero` **3
passes** puis `rm -f`. Les 17 `wire.jsonl` de session (qui portaient des en-têtes d'autorisation) ont
été shreddés après extraction des seuls compteurs d'usage.

**Vérifications finales** : `kimi doctor` du banc → `SKIP config.toml — File does not exist` ·
`find $BENCH -name config.toml` → **0** · home réel de Samuel **intact** (2730 octets, mtime
inchangé).

**Portée du snapshot** : mesure prise sur `plugin/` au HEAD `0f510f62` (SHA256 en
`00-snapshot-sha256.txt`). Le dépôt a bougé pendant la campagne (`c05edc01`), mais les quatre agents
mesurés sont **byte-identiques** entre snapshot et état courant — le verdict vaut pour les deux.

## Trois pièges de poste rencontrés

1. `-p` refuse de se combiner avec `--auto` comme avec `-y` (le mode prompt gère sa propre
   approbation et auto-approuve).
2. **Le compte est plafonné à 3 RPM.** Une première boucle en rafale a produit deux `429`, **écartés
   au lieu d'être comptés** — dont un `control-3` qui serait sorti en faux « n'a pas écrit ».
   Espacer de 25-30 s. *Un `429` compté comme un résultat est exactement le faux rouge que cette
   phase passe son temps à éviter.*
3. `stream-json` ne remonte **aucune** donnée d'usage : les tokens se lisent dans
   `home/sessions/*/agents/main/wire.jsonl`, où chaque entrée est **dupliquée** (diviser par 2).

## Autres notes de portabilité

- `-m` n'accepte qu'un **alias déclaré dans `config.toml`**, pas un id de modèle libre.
- **Aucun équivalent de `--output-schema`** (`--output-format stream-json` est du JSONL de chat).
  Si un runtime VibeFlow attend un rapport typé, c'est une contrainte à déclarer.
- `node-pty` (scripts postinstall bloqués par `allow-scripts`) **n'affecte pas** le chemin `-p` :
  prebuild `darwin-arm64` présent, import dynamique réservé au backend terminal.
- `--agent-file <path>` contourne entièrement la découverte par répertoire et rend l'erreur
  complète : bon vecteur de recette post-install, et **plan B de dispatch**.

**Artefacts** : 87 fichiers, banc `kimi-bench-i1/artefacts/` (synthèse en `99-SYNTHESE.md`).
