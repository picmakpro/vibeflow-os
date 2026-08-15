# Phase 28 : Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur — Carte des patrons

**Cartographié :** 2026-08-10
**Livrables classés :** 6
**Analogues trouvés :** 5 / 6 (1 livrable sans analogue — voir §Sans analogue)

> Méthode : tous les relevés ci-dessous sont **mesurés sur disque** ce jour, en `awk` (jamais
> `grep | wc -l`). Chaque excerpt porte son chemin et ses lignes.

---

## Classification des livrables

| Livrable | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| L1 — règle « armement sans précondition distribuée ⇒ ROUGE » | gate (extension) | transform (3 artefacts → verdict) | `plugin/dev-orchestrator/scripts/check-capability-activation.sh` (règles 2/2bis/3, l. 389-434) | **exact** — même fichier, même moteur `awk` |
| L2 — clé de frontmatter « précondition externe déclarée » | contrat de frontmatter + admission `KNOWN` | déclaratif | `vf-mcp-tools` / `vf-mcp-consumer` (`check-agents.sh:153-160` + `inject-mcp-tools.sh:243-290`) | **exact** |
| L3 — liaison artefact ↔ `ensure-*.sh` vérifiable machine | contrat + résolution de fichier | déclaratif → file-I/O | partiel : `vf-mcp-tools` (grammaire `<serveur>:<outils>`) + hook `vibeflow-update.sh:581-587` | **partiel** — voir §Sans analogue |
| L4 — test de discriminance rouge/vert sur fixture #38 | test | mutation de fixture | `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` (l. 1-90, fabriques `mk_*`) ; discriminance : `test-dev-orchestrator.sh:1454-1470` | **exact** |
| L5 — étape CI dans `lab-frais` | config CI | as-installed | `.github/workflows/ci.yml:640-652` (Gate C) ; forme d'étape de gate : `ci.yml:331-342` | **exact** |
| L6 — découpage éventuel du gate | refactor | — | seuil : `plugin/software-architecture/scripts/check-file-size.sh:12-13,25-26` | **role-match** |

---

## L1 — La règle nouvelle dans `check-capability-activation.sh`

**Analogue :** le fichier lui-même (443 l.), à **étendre**.

### Ce qui se copie tel quel

**Cascade de résolution de racine + dispositions doubles** (l. 111-193) — ne pas y toucher, elle
porte deux corrections vécues (lab installé à plat, remontée bornée). Le nouveau code réutilise
`$ROOT`, `$REF_DIR`, `$CONFIG` sans les recalculer.

**Le patron de surcharge `VF_CAPACT_*`** (l. 92-98, 189-193) — toute nouvelle entrée du gate
(l'univers des artefacts armés, la liste close) doit avoir sa variable d'environnement de
surcharge, **séparateur saut de ligne obligatoire** :

```bash
CORPUS="${VF_CAPACT_CORPUS:-$CORPUS_DEFAULT}"
```

et le découpage désarmé (l. 209-222) avec `set -f` + `IFS=$'\n'` — motif documenté sur place
(globbing + chemins à espaces).

**Le plancher anti-vert-à-vide, règle 1** (l. 376-388) — le patron exact à répliquer pour le
nouvel ensemble : un univers d'artefacts vide ⇒ **exit 2 NON VÉRIFIABLE**, jamais 0.

```awk
if (nB == 0) {
  print "[check-capability-activation] aucune brique routee lisible dans " RELIDX " (section « " S_BRICKS " ») — la regle 2bis serait INERTE, activation NON VERIFIABLE"
  exit 2
}
```

**Le format de message d'écart** (l. 402, 420, 428, 431) — nomme la règle, l'objet, l'état, et
finit par `SRC[j] ":" LNO[j]`. À reproduire mot pour mot dans sa structure :
`ECART regle N : <objet> « X » ... — fichier:ligne`.

**La comparaison par frontière** `occ()` / `isid()` (l. 266-286) — réutilisable telle quelle si la
nouvelle règle compare des noms (nom d'agent, nom de script `ensure-*`).

**Les chemins relatifs dans les verdicts** (l. 246-249, `REL_*`) — obligatoire, `check-machine-paths.sh`
est bloquant sur les chemins absolus de machine.

**L'awk unique multi-fichiers avec dispatch `FILENAME == IDX`** (l. 265, 318, 355) — le patron
d'ajout d'une **troisième famille** de fichiers d'entrée : ajouter une variable
`ENVIRON["VF_CAPACT_ARMED"]` et un bloc `FILENAME == ARMED_LIST { ... }`.

### Ce qui doit diverger, et pourquoi

1. **Le corpus n'est plus documentaire.** Les entrées actuelles sont `intent-routing.md` /
   `docs-flow.md` — de la prose en tables. Le nouvel univers est **des frontmatters d'agents/skills
   distribués** (`plugin/*/agents/*.md`, `plugin/*/AGENT.md`, `plugin/*/skills/**/SKILL.md`). Le
   parseur de lignes de table (`ROW[]`, l. 363) ne s'applique pas : il faut un parseur de
   frontmatter borné (`---` ouvrant/fermant, clé en début de ligne), sur le modèle des regex ancrées
   `^vf-mcp-tools:\s*(.*)$` de `inject-mcp-tools.sh:245`.

2. **La découverte de l'univers.** Actuellement l'univers vient d'un **index généré**
   (`gsd-capabilities-index.md`, contrat avec `build-gsd-capabilities-index.sh:95,218`). Pour L1 il
   n'y a **aucun index généré des artefacts armés** — l'univers se découvre par parcours de
   `plugin/*/agents/` (et disposition lab : `.claude/agents/`). Deux options pour le plan, à
   trancher : (a) parcours direct + plancher « au moins N artefacts lus, sinon exit 2 » ;
   (b) génération d'un index à la `build-gsd-capabilities-index.sh`. **(a) est cohérent avec D-03**
   (pas d'artefact neuf) et suffit ; (b) rouvrirait un contrat générateur↔gate.

3. **`jq` reste requis pour le config du lab** (l. 204-207) mais **ADR-054 interdit d'en dépendre
   pour le nouveau chemin** si celui-ci ne lit que des frontmatters. Le plan doit décider si la
   nouvelle règle est évaluable **sans** `jq` : si oui, sortir son évaluation du garde-fou l. 204
   (aujourd'hui `jq` absent ⇒ exit 2 global, donc la règle nouvelle deviendrait inévaluable pour un
   motif qui ne la concerne pas).

4. **Les trois états.** La doctrine « actif / inactif / **indéterminé** » (l. 67-73, fonction
   `state()` l. 288-292) se transpose directement : précondition **prouvée** / **non posée** /
   **indéterminable** (ex. `ensure-*.sh` déclaré mais illisible). Ne pas replier l'indéterminé sur
   « non posée » — ce serait fabriquer des rouges, symétrique exact du défaut déjà corrigé l. 70-73.

### Emplacement / nommage proposé

- Fichier : **`plugin/dev-orchestrator/scripts/check-capability-activation.sh`** (inchangé, D-03).
- Nouvelles règles numérotées **4** (armement déclaré sans preuve) et **4bis** (liste close), à
  documenter dans l'en-tête l. 46-65 sur la même forme « Règle N — <titre> ».
- Nouvelles surcharges : `VF_CAPACT_ARMED` (liste des artefacts à balayer, un par ligne) et
  `VF_CAPACT_ENSURE_DIR` (dossier de résolution des `ensure-*.sh`).
- Codes de sortie inchangés (0/1/2/64) — la nouvelle règle sort **1**.

---

## L2 — La clé de frontmatter « précondition externe déclarée »

**Analogue exact :** `vf-mcp-tools` — le seul précédent d'une clé VibeFlow **portée par un artefact
distribué** et **traitée par un script**.

### Ce qui se copie tel quel

**Admission dans `KNOWN`** — `plugin/conductor/scripts/check-agents.sh:153-160`. Noter que le
commentaire au-dessus **documente chaque clé VibeFlow, une ligne par clé** ; c'est le geste attendu :

```python
# + conventions VibeFlow : vf-internal (worker interne — pas de commande d'incarnation, cf. Pattern 12) ;
#   vf-mcp-consumer (agent exécutant recevant l'allowlist MCP dérivée du lab à l'install, ADR-051) ;
#   vf-mcp-tools (allowlist MCP NOMMÉE — un serveur, une liste d'outils explicites — consommée par
#   le script d'injection du module dev-orchestrator ; coexiste avec vf-mcp-consumer sans le remplacer).
KNOWN = {"name", "description", ..., "vf-internal", "vf-mcp-consumer", "vf-mcp-tools"}
```

**Attention :** `check-agents.sh` est du **Python embarqué dans une heredoc bash échappée** (les
guillemets sont `\"` — voir l. 145-165). Toute édition doit préserver l'échappement, et
`bash -n` ne le vérifie pas. Le plan doit prévoir une vérification d'exécution réelle.

**Grammaire de valeur + parsing ancré** — `inject-mcp-tools.sh:243-290` :

```python
NAMED_FLAG_RE = re.compile(r"^vf-mcp-tools:\s*(.*)$", re.M)
# grammaire <serveur>:<outil1>,<outil2>,…
```

La leçon à reprendre : une clé VibeFlow porte une **grammaire close** et **une valeur malformée
n'est jamais un no-op silencieux** — `inject-mcp-tools.sh:413,501` loguent explicitement
« malformée … aucune comparaison possible / no-op », et `:420` produit un verdict **INDÉTERMINÉ**
distinct du manquant.

### Ce qui doit diverger

- **`vf-mcp-tools` est traité par un script d'injection (écriture), pas par un gate.** Ici la clé
  n'est lue que par un gate en lecture seule (l. 82-83 du gate : « n'écrit AUCUN fichier »). Donc
  pas de contrepartie `inject-*`.
- **Malformée ⇒ ROUGE, pas no-op.** Divergence assumée à écrire dans le plan : `inject-mcp-tools.sh`
  dégrade en no-op parce qu'il *modifie* des fichiers ; un gate qui dégrade en no-op sur une clé
  malformée rejouerait #38 (armé, personne ne le voit).

### Nommage proposé

`vf-requires:` (grammaire `<précondition>` ou `<précondition>@<preuve>`) ou, plus explicite et plus
proche du précédent à deux clés, **le couple** :

| Clé | Rôle | Modèle |
|---|---|---|
| `vf-requires` | nomme la précondition externe | `vf-mcp-consumer` (marqueur) |
| `vf-requires-proof` | nomme le `ensure-*.sh` qui la prouve | `vf-mcp-tools` (grammaire nommée) |

Le plan tranche ; les deux formes tiennent dans `KNOWN` et dans le parseur ancré.

---

## L3 — La liaison artefact ↔ `ensure-*.sh`

**Analogues, aucun n'étant complet :**

| Fragment | Source | Ce qu'il fournit |
|---|---|---|
| Déclaration nommée dans le frontmatter | `inject-mcp-tools.sh:245,257` | la grammaire et le parsing ancré d'un **nom** cité par un artefact |
| Invocation d'un `ensure-*.sh` par chemin résolu | `plugin/_internal/vibeflow-update.sh:581-587` | le patron « le fichier existe des DEUX côtés (module source **et** `$TARGET_ROOT/scripts/`) avant d'être invoqué » |
| Contrat d'un `ensure-*` | `plugin/design-orchestrator/scripts/ensure-design-deps.sh:1-68` | l'en-tête déclarant objet, autonomie (aucun `source` cross-module), contrat de sortie, idempotence |

**Excerpt structurant** (`vibeflow-update.sh:581-587`) — la double présence est la garde à copier :

```bash
if [ -f "$module_dir/scripts/ensure-design-deps.sh" ] && [ -f "$TARGET_ROOT/scripts/ensure-design-deps.sh" ]; then
```

**Excerpt de contrat** (`ensure-design-deps.sh:59-66`) :

```
# Contrat de sortie : toujours exit 0, SAUF `VF_SCOPE` invalide (exit 1, avant tout effet de
# bord). Jamais d'échec silencieux : CLI `claude` absente → 4 étapes manuelles affichées, exit 0.
# Idempotent : un 2e run consécutif en dry-run est un no-op stable (sortie identique).
```

> **Divergence critique à instruire au plan.** `ensure-design-deps.sh` **sort toujours 0** — même
> quand la précondition n'est pas satisfaite (dégradation best-effort, voulue par D-03a de son
> quick). Un gate qui prend « un `ensure-*.sh` existe » pour preuve de distribution **bénirait donc
> un script qui ne prouve rien**. Deux sorties possibles, à trancher : (a) le gate exige que le
> script déclaré porte un **marqueur de contrat** dans son en-tête (ex. `# vf-proves: <précondition>`),
> vérifié littéralement — cohérent avec « explicite et vérifiable par machine » (D-02b) et sans
> exécution ; (b) le gate **exécute** le script — écarté : le gate est en lecture seule stricte
> (`check-capability-activation.sh:82-83`) et un `ensure-*` installe des plugins.
> **Recommandation : (a).**

**Nommage/emplacement proposé :** marqueur `# vf-proves: <précondition>` en en-tête des deux
`ensure-*.sh` existants + résolution du script déclaré dans les **deux dispositions** (module source
`plugin/<mod>/scripts/`, lab installé `.claude/scripts/` à plat), sur le patron de la cascade
`REF_DIR` du gate (l. 176-187).

---

## L4 — Le test de discriminance rouge/vert sur fixture #38

**Analogue exact :** `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh`
(630 l.) — c'est la suite du gate à étendre, donc **le test s'y ajoute** (pas de fichier neuf).

### Ce qui se copie tel quel

**L'en-tête doctrinal** (l. 5-31) — en particulier la règle absolue :

```
# Règle absolue héritée de `test-check-gsd-config.sh` : une mutation doit avoir CHANGÉ le fichier,
# constaté par `cmp` et JAMAIS par `diff` (le `diff` de ce poste est proxifié et ment). Un motif de
# mutation introuvable rend le mutant NON OPPOSABLE — un échec, jamais un succès silencieux.
```

**Le squelette** (l. 33-42) : `set -uo pipefail`, `SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/…"`,
compteurs `PASS/FAIL` + `ok()`/`ko()`, `TMP="$(mktemp -d)"` + `trap 'rm -rf "$TMP"' EXIT`.

**Les fabriques de fixtures synthétiques** (l. 50-88, `mk_index()` via heredoc `<<'IDX'`) — patron
exact pour un `mk_agent_arme()` / `mk_agent_desarme()`.

**Le couple mutation ↔ contre-preuve** — `test-dev-orchestrator.sh:1454-1470` est le modèle le plus
serré, avec l'assertion `cmp -s` de non-opposabilité :

```bash
if cmp -s "$ROUTING" "$T14D_MUT"; then
  ko "… mutant IDENTIQUE … mutant NON OPPOSABLE (pas mutant satisfait)"; t14d_ok=0
```

### Ce qui doit diverger

- **La mutation reproduit #38 :** poser `isolation: worktree` dans le frontmatter d'un **agent de
  fixture** (jamais dans un agent distribué — interdit absolu) sans précondition prouvée ⇒ exit 1 ;
  retirer la ligne **ou** déclarer une preuve ⇒ exit 0. Deux sens, comme l. 10-14.
- **Le recouvrement avec `check-agents.sh:546-549` doit être neutralisé dans le test.** La fixture
  n'est jamais soumise à `check-agents.sh` : le test doit établir que **ce gate-ci** rougit seul.
  Rendre cela explicite dans le commentaire du cas, sinon la preuve est ambiguë (D-06).

### Câblage : rien à faire

**Découverte automatique** — `.github/workflows/ci.yml:205-229` :

```
suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)
… echo "::error::aucune suite de tests découverte (pattern */tests/test-*.sh) — la CI refuse de rendre un verdict vide"
```

Toute suite `*/tests/test-*.sh` est ramassée. **Aucun roster de tests à éditer.**

---

## L5 — L'étape CI dans `lab-frais`

**Analogue de l'environnement :** `.github/workflows/ci.yml:620-652` — le job installe la fermeture
transitive de `conductor` dans un `mktemp -d` git-initialisé, exporte `LAB` via `$GITHUB_ENV`, puis
Gate C invoque les scripts **depuis `.claude/scripts/`** (disposition à plat) :

```bash
cd "$LAB"
bash .claude/scripts/check-agents.sh --strict
bash .claude/scripts/check-registres.sh --strict --allow-empty || rc=$?; rc=${rc:-0}
```

**Analogue de la forme d'étape de gate :** `ci.yml:331-342` — l'étape de
`check-capability-activation.sh` au job `gates`, avec son commentaire qui dit **pourquoi le câblage
existe** et **qu'un exit 2 échoue au même titre qu'un exit 1**. À reprendre mot pour mot dans
l'esprit.

### Ce qui doit diverger

1. **Le lab frais n'a pas de `.planning/config.json`** — la ligne 647-650 le dit explicitement
   (« un lab tout juste installé n'a pas encore de `.planning` »). Or le gate sort **2 NON
   VÉRIFIABLE** sans config (l. 200-203). **Trou réel :** invoquer le gate tel quel dans `lab-frais`
   le fera sortir 2, donc échouer le job. Le plan doit trancher entre : poser un `.planning/config.json`
   minimal dans le lab de test (le plus honnête — c'est ce que fait un vrai lab), ou permettre à la
   nouvelle règle d'être évaluée **sans** config (elle ne lit que des frontmatters, donc
   techniquement possible — mais ça fragmente les préconditions du gate).
2. **`grep -q "guard" .claude/settings.json`** (l. 652) est la dernière ligne du fichier : la nouvelle
   étape s'ajoute **après**, en fin de `ci.yml`. Note ADR-054/doctrine locale : le repo proscrit
   `grep` piped dans les *gates* ; en CI (runner Linux, grep GNU) l'usage existant reste toléré, mais
   la nouvelle étape doit **invoquer le gate**, pas re-implémenter sa règle.

**Nommage proposé de l'étape :**
`- name: "Gate D du lab frais : aucun artefact installé n'est armé sans précondition distribuée (#38)"`
— la numérotation `Gate C`/`Gate D` est la convention en place du job.

---

## L6 — Le découpage éventuel du gate

**Seuil mesuré** — `plugin/software-architecture/scripts/check-file-size.sh:12-13,25-26` :

```bash
#   VF_ARCH_WARN  (défaut 250)  — avertissement
#   VF_ARCH_BLOCK (défaut 300)  — blocage (exit 2)
WARN="${VF_ARCH_WARN:-250}"
BLOCK="${VF_ARCH_BLOCK:-300}"
```

**Constat pour le planificateur :** `check-capability-activation.sh` fait **443 lignes** — il est
**déjà au-delà du seuil bloquant de 300**. Le gate de taille ne le rougit pas aujourd'hui : vérifier
au plan quel univers `check-file-size.sh` balaye réellement (il n'est câblé nulle part dans `ci.yml`
d'après le relevé). **Conclusion : le découpage n'est pas déclenché par un franchissement de seuil —
le seuil est franchi depuis la Phase 24.** Le plan doit soit assumer explicitement la dérogation
(en-tête, comme les autres bornes déclarées du gate), soit découper de son propre chef. Ne pas
justifier un découpage par un seuil qui n'arme rien.

**Aucun analogue de découpage de gate en sous-scripts n'existe dans ce dépôt.** Le seul patron voisin
est la **duplication délibérée documentée** (`ensure-design-deps.sh:13-18`, `check-gsd-engine.sh:68-70`)
— c'est-à-dire l'inverse d'une factorisation. Si découpage il y a, il inventera sa forme.

---

## Patrons transverses (à appliquer à tout le livrable)

### `awk`, jamais `grep` piped
**Source :** `check-capability-activation.sh:27-28`, et l'impression de la docstring l. 162-165 :
```bash
awk 'NR == 1 && /^#!/ { next } /^#/ { sub(/^#[ ]?/, ""); print; next } { exit }' "$0"
```

### Tout passe par l'ENVIRONNEMENT, jamais par `awk -v`
**Source :** `check-capability-activation.sh:253-258` — motif : `-v` interprète les échappements et
ne porte pas de saut de ligne (awk BSD).

### Un gate déclare ses bornes dans son en-tête
**Source :** `check-capability-activation.sh:11-20` (« Le gate ne juge donc PAS la prose, et le dire
vaut mieux que le laisser croire ») et l. 41-44. **À appliquer :** D-01b, plus le nom du pattern
*as-installed testing* (D-04).

### Chemins relatifs dans tout verdict
**Source :** `check-capability-activation.sh:246-249`. Un chemin absolu porte le nom de compte et
`scripts/check-machine-paths.sh` est **bloquant**.

### Bump de module obligatoire
Toute modification de `plugin/dev-orchestrator/` implique `VERSION` + `module.json` + `CHANGELOG.md`
du module, et `check-version-sync.sh` (`ci.yml:319-320`) vérifie la triade par module.

---

## Sans analogue — là où le plan devra inventer

| Point | Rôle | Pourquoi aucun analogue |
|---|---|---|
| **Découverte de l'univers des artefacts armés** | source de données du gate | Toutes les entrées actuelles du gate viennent d'un **index généré** ou d'un **corpus nommé**. Il n'existe **aucun index des agents/skills distribués** ni aucun gate du repo qui balaye `plugin/*/agents/*.md` en tant qu'univers (`check-agents.sh` prend un `--agents-dir` à la fois, fourni par l'appelant). Le plancher anti-vert-à-vide devra donc être inventé sur un univers découvert, pas lu. |
| **Preuve statique qu'un `ensure-*.sh` prouve une précondition** | contrat | Aucun `ensure-*.sh` ne déclare ce qu'il prouve, et **les deux sortent 0 même en échec**. Le marqueur de contrat (`# vf-proves:`) n'existe nulle part — à créer, et à poser rétroactivement sur `ensure-deps.sh` et `ensure-design-deps.sh`. |
| **La « liste close » d'armements dangereux** | donnée | Le plus proche est `ROUTED_CONDITIONAL` (`test-dev-orchestrator.sh:1411-1415`, liste blanche nommée + `case`) — mais c'est dans un **test**, pas dans un gate, et sa sémantique est l'inverse (exemption). La forme (`case " $LISTE " in *" $1 "*)`) est reprenable ; la place dans un gate est neuve. |
| **Le lab frais avec un `.planning/config.json`** | fixture CI | `lab-frais` documente explicitement l'absence de `.planning` comme état normal (`ci.yml:647-648`). Aucun job n'installe un lab **puis** le dote d'une configuration. |
| **Découpage d'un gate en sous-scripts** | refactor | Aucun précédent ; le dépôt documente la duplication délibérée, pas la factorisation. |

---

## Métadonnées

**Périmètre de recherche :** `plugin/dev-orchestrator/scripts/` (+ `tests/`), `plugin/conductor/scripts/`,
`plugin/design-orchestrator/scripts/`, `plugin/software-architecture/scripts/`, `plugin/_internal/`,
`.github/workflows/ci.yml`, `scripts/`.
**Fichiers lus intégralement :** 1 (`check-capability-activation.sh`, 443 l.).
**Fichiers lus par sections ciblées :** 7.
**Date d'extraction :** 2026-08-10.
