# Issue amont `@opengsd/gsd-core` — BROUILLON, NON ENVOYÉ

> ⛔ **NE PAS POSTER.** Rédigée par la mission Phase 38 de `vibeflow-os` sur décision de Samuel
> (option C, 2026-08-29). **L'envoi vers l'extérieur est un geste humain de Samuel**, au même titre
> que la requête d'élargissement du SDK public (D-38-D). Ce fichier est un livrable de phase, pas
> une action.

**Version mesurée** : `@opengsd/gsd-core` 1.11.0 · **Poste** : macOS (APFS), Node via Homebrew.
**Runtimes réellement installés et mesurés** : `codex-cli 0.150.1`, `opencode-ai 1.18.25`,
`@moonshot-ai/kimi-code 0.39.1`.
**Méthode** : conversion réelle exécutée via les convertisseurs de gsd-core, artefacts posés sur
disque, runtimes interrogés. Chaque affirmation ci-dessous est **mesurée**, jamais dérivée d'un
descripteur — trois descripteurs consultés se sont révélés faux au cours de cette campagne.

---

## 1. 🔴 `Agent(a, b, c)` est déchiqueté par un `split(",")` — un défaut, deux dégâts OPPOSÉS

C'est le point principal de cette issue.

L'allowlist VibeFlow `tools: Read, Bash, Agent(vf-coder, vf-reviewer, vf-auditer, …)` est découpée
sur les virgules **sans tenir compte des parenthèses**. Sur `vf-dev-manager` (16 noms d'agents),
la conversion OpenCode produit :

```yaml
tools:
  agent(vf-coder: true      # ← parenthèse ouverte, jamais fermée
  vf-reviewer: true
  vf-auditer: true
  # … 13 autres …
  vf-design-judge): true    # ← parenthèse fermante orpheline
```

**Et OpenCode l'accepte sans un mot** (`RC=0`, stderr vide) :
```
gsd-vf-dev-manager (all)  *:allow | agent(vf-coder:allow | vf-reviewer:allow | … | vf-design-judge):allow
```

**Le même découpage frappe kimi-code, avec l'effet exactement inverse :**

| runtime | sémantique de `tools` | conséquence du déchiquetage |
|---|---|---|
| **OpenCode** | **additif** (`*:allow` couvre tout) | **16 permissions inventées** qui *ressemblent* à une allowlist et ne restreignent rien — **pire qu'une suppression**, parce que ça a l'air de marcher |
| **kimi-code** | **allowlist stricte** | `Agent(gsd-code-reviewer)` devient un `unknown-tool` → **l'agent perd son outil de dispatch**, et un manager perd **toute capacité d'orchestration** |

Un seul défaut de parsing produit donc **trop permissif** d'un côté et **trop restrictif** de
l'autre. C'est ce qui rend ce bug coûteux à diagnostiquer côté aval : le symptôme n'a pas la même
forme selon la cible.

**Confirmé en session réelle sur kimi-code (2026-08-30)** — le mécanisme est localisé dans la
source : `parseStringList` découpe sur `,` **sans conscience des parenthèses**, si bien que
`Agent(vf-reviewer, general-purpose)` devient les deux jetons `Agent(vf-reviewer` et
`general-purpose)`, tous deux **noms d'outils inexistants, ignorés SANS le moindre diagnostic**.
La perte est donc **silencieuse** : l'agent charge, il a l'air sain, et sa capacité de dispatch de
sous-agents n'existe plus.

⚠️ **Précision mesurée, pour éviter un contresens** : ce découpage n'affecte **pas**
`disallowedTools` (qui ne contient pas de parenthèses) — vérifié, le garde-fou d'écriture reste
appliqué (0/4 écritures contre 3/3 pour le contrôle positif). Le dégât porte **uniquement** sur la
capacité de dispatch. Nous l'avions d'abord soupçonné d'affaiblir les permissions : c'est faux, et
c'est précisément le genre de contresens que le caractère silencieux du défaut encourage.

**Correctif suggéré** : découper en respectant l'appariement des parenthèses, ou traiter
`Agent(...)` comme un jeton unique avant le `split`. **Et, indépendamment du découpage : émettre un
diagnostic sur tout nom d'outil inconnu** — c'est l'absence de signal, plus que le découpage
lui-même, qui rend ce défaut coûteux en aval.

---

## 2. OpenCode — `disallowedTools` est perdu alors qu'un équivalent EXISTE

`tools` est **additif** chez OpenCode : ne pas lister `write` ne l'interdit pas. Un agent VibeFlow
conçu **sans droit d'écriture** (`disallowedTools: Write, Edit`) arrive donc sur OpenCode **sans
aucun refus d'écriture**. Le champ est recopié verbatim dans le frontmatter et **ignoré**.

**Mesuré sur des agents témoins** — l'équivalent existe et fonctionne :

| frontmatter posé | permissions résolues par OpenCode |
|---|---|
| `tools: {read, bash}` | `*:allow \| bash:allow` — **aucun deny** |
| `tools: {read, bash, write:false, edit:false}` | `*:allow \| bash:allow \| **edit:deny**` |
| `tools: {write:false}` seul | `*:allow \| **edit:deny**` |
| `tools: {edit:false}` seul | `*:allow \| **edit:deny**` |

**Correctif suggéré** : quand la source porte `disallowedTools` contenant `Write` et/ou `Edit`,
émettre `tools: {write: false}` (ou `edit: false` — les deux se replient sur la même permission
`edit`). **Une ligne**, effet **mesuré**.

L'enjeu n'est pas cosmétique : les trois agents concernés côté VibeFlow sont des **juges**
(`vf-reviewer`, `vf-auditer`, `vf-design-judge`). Un juge qui peut écrire dans le dépôt qu'il juge
rend un verdict vert sur un arbre qu'il a pu modifier.

---

## 3. OpenCode — `mode` absent : tout agent converti devient primaire

Sans `mode` dans le frontmatter, OpenCode enregistre l'agent en **`(all)`** — donc **primaire ET
sous-agent**, directement sélectionnable par l'utilisateur. Mesuré : nos sondes portant
`mode: subagent` ressortent bien `(subagent)`, l'agent converti ressort `(all)`.

Côté VibeFlow, cela **perd** le marqueur `vf-internal: true` (un worker jamais incarnable
directement — un utilisateur peut désormais l'invoquer hors de sa chaîne).

**Correctif suggéré** : émettre `mode: subagent` quand la source porte `vf-internal: true` (ou tout
marqueur équivalent). **Une ligne**, effet **mesuré**.

---

## 4. Descripteur `kimi-code` périmé — `namedDispatch: false` est faux

`capability-registry.cjs` déclare kimi-code `namedDispatch: false`,
`subagentToolkit: "built-in-only"`, `namedSubagentsSupported: false`.

**Mesuré sur `@moonshot-ai/kimi-code@0.39.1`** (schéma extrait du bundle livré) :
```js
AgentProfileSnapshotSchema = object({
  name, description, whenToUse, tools,
  disallowedTools: array(string()).optional(),
  subagents: array(string()),          // ← sous-agents NOMMÉS
  modelPreference, prompt, source
});
delegatableSubagents(callerProfileName) { … }   // résolution PAR NOM
```
`load()` balaie `userRoots` / `extraRoots` / `projectRoots` / `pluginRoots`, fusionne les
agent-files **du disque** dans une Map clé=nom, avec priorités
`plugin:5 < user:10 < extra:20 < project:30 < explicit:40`. La boîte à outils par défaut contient
`Agent` **et** `AgentSwarm`.

→ **kimi-code enregistre bien des sous-agents nommés custom.** Le descripteur devrait être corrigé.

**Bonus mesuré, même famille** : kimi-code **a** `upgrade|update` (plus `doctor`,
`provider add|remove|list` non-interactif, `acp`, `migrate`, `export`) — là où plusieurs sources le
décrivent comme « TUI-only, sans `update` ».

**Nuance en faveur du registre** : sur l'identité des paquets, il est **juste** — il distingue bien
`kimi` (Python) de `kimi-code` (Node) et sait que **les deux exposent un binaire `kimi`**. C'est
une distinction que la documentation publique rend facile à rater. ⚠️ Piège associé, pour
quiconque écrit un installeur : **le paquet npm `kimi-code` n'est PAS le produit Moonshot** (c'est
un proxy tiers vers claude-code, non modifié depuis ~1 an) — le vrai est
**`@moonshot-ai/kimi-code`**.

---

## 5. `extractFrontmatterField` ne gère pas le scalaire replié YAML

`runtime-artifact-conversion.cjs` capture la frontmatter par une regex **mono-ligne**
`^description:\s*(.+)$`. Sur un scalaire replié (`description: >` suivi du texte indenté), elle ne
capture **que le littéral `>`** et jette le reste.

Mesuré en exécutant les **trois** convertisseurs de skill réels : tous trois écrivent
`description: >` verbatim, **sur les trois cibles**, sans exception ni diagnostic. Or la
`description` est ce qui rend un skill **déclenchable** : sa perte produit un skill installé et
**invocable par personne**.

Côté VibeFlow, 15 des 21 skills installables étaient concernés (corrigé chez nous en repliant les
descriptions sur une ligne — mais la regex amont reste à durcir).

---

## Ce que cette campagne suggère, au-delà des correctifs

Les cinq points ci-dessus partagent un trait : **la conversion réussit, ne lève rien, et perd une
garantie**. Sur 156 conversions mesurées en amont de cette phase : **0 exception, 0 retour nul,
0 diagnostic** — et pourtant `model`, `memory`, `tools`, `disallowedTools`, `vf-internal` et les
allowlists disparaissent selon la cible.

Un **signal machine** distinguant « converti » de « converti et mort » aurait une valeur qui
dépasse largement notre cas d'usage. C'est ce que nous avons dû construire de notre côté
(un gate de fidélité qui compare l'artefact source à sa forme convertie, champ par champ, et rend
`préservé / dégradé / perdu` par cible) faute d'équivalent amont.

**Artefacts de mesure** disponibles sur demande : sorties `opencode agent list` et
`opencode debug skill`, extraits de schéma du bundle kimi-code, frontmatters convertis avant/après,
et les commandes exactes de chaque relevé.
