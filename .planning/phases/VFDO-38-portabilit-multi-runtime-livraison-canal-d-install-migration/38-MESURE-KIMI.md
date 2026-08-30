# Mesure kimi-code — ce que la mesure établit, pas plus

**Date** : 2026-08-30 · `@moonshot-ai/kimi-code` 0.39.1, `/opt/homebrew/bin/kimi` ·
**Tokens consommés : ZÉRO**

> kimi-code passait pour un **inconnu déclaré** (OAuth en échec côté serveur). Une clé API a été
> posée par Samuel. Ce document consigne **I-1 uniquement**. **I-2 et I-3 restent NON MESURÉES** —
> voir « Ce qui bloque » en fin de document.

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

## Ce qui bloque I-2 et I-3

`KIMI_CODE_HOME` isole intégralement — **pas besoin de rediriger `HOME`**. Mais :

- **`KIMI_REGISTRY_API_KEY` n'est PAS la clé d'inférence** (elle ne sert qu'au registre de
  providers). La clé d'inférence est **inline dans `config.toml`** (`[providers.moonshotai].api_key`).
- **Aucune variable d'environnement de processus n'est lue** : zéro interpolation `${ENV}` dans le
  bundle, vérifié par mesure (`OPENAI_API_KEY` injecté → `no credential configured`).

⇒ La voie « clé par variable d'environnement, jamais par copie de fichier » **n'existe pas**.
I-2 (`disallowedTools` bloque-t-il une écriture réelle) et I-3 (firing des `[[hooks]]`) exigent des
sessions réelles, donc la clé. **Trois options, décision de Samuel** :

- **A** — mesurer dans le home réel, sans copier aucune clé ; pollution limitée aux agents posés et
  aux sessions, réversible avec preuve arbre-à-arbre. Écrit dans l'environnement de Samuel.
- **B** — banc isolé avec copie de `config.toml` (qui **porte la clé en clair**), sous le régime
  exact déjà validé pour `auth.json` : scratchpad seul, jamais lue ni journalisée, écrasée puis
  supprimée, déclarée. N'écrit rien chez Samuel. **Recommandée.**
- **C** — s'arrêter à I-1 ; I-2 et I-3 restent **inconnus déclarés**.

## Autres notes de portabilité

- `-m` n'accepte qu'un **alias déclaré dans `config.toml`**, pas un id de modèle libre.
- **Aucun équivalent de `--output-schema`** (`--output-format stream-json` est du JSONL de chat).
  Si un runtime VibeFlow attend un rapport typé, c'est une contrainte à déclarer.
- `node-pty` (scripts postinstall bloqués par `allow-scripts`) **n'affecte pas** le chemin `-p` :
  prebuild `darwin-arm64` présent, import dynamique réservé au backend terminal.
- `--agent-file <path>` contourne entièrement la découverte par répertoire et rend l'erreur
  complète : bon vecteur de recette post-install, et **plan B de dispatch**.

**Artefacts** : 87 fichiers, banc `kimi-bench-i1/artefacts/` (synthèse en `99-SYNTHESE.md`).
