# Phase 42 : Fabrique — manifeste daté et invariants de doctrine du gate des agents - Carte des patrons

**Mappé le :** 2026-09-23
**Fichiers analysés :** 8 (1 script gate, 1 suite de tests, 1 installeur, 1 manifeste JSON nouveau, 5 fichiers de corpus représentatifs sur les 9 à corriger)
**Analogues trouvés :** 8/8 (patron existant pour chaque catégorie — cette phase ne crée aucun rôle inédit dans le dépôt)

## File Classification

| Fichier nouveau/modifié | Rôle | Flux de données | Analogue le plus proche | Qualité du match |
|---|---|---|---|---|
| `plugin/conductor/scripts/check-agents-manifest.json` (NOUVEAU, D-01) | config (données statiques versionnées) | file-I/O (lu, jamais écrit au runtime) | *(aucun JSON co-localisé existant)* — patron structurel emprunté à `plugin/conductor/scripts/known-versions.txt` (co-localisé avec `audit-infra.sh`, même rôle : liste de référence datée, lue par le script voisin) | role-match |
| `plugin/conductor/scripts/check-agents.sh` (MODIFIÉ : chargement manifeste, fraîcheur, I1-I7, découverte récursive) | CLI/gate (lint) | request-response (invocation CLI → exit code + diagnostic stdout/stderr) | lui-même (patron interne déjà en place : contrat F13, `--resolve-agents=lenient|strict`, `resolve_agent_name()`) — pas de fichier externe à copier, extension in situ | exact |
| `plugin/conductor/scripts/tests/test-check-agents.sh` (MODIFIÉ : cas T77+) | test | request-response (assertions sur exit code + grep du stdout) | lui-même — patron `ok`/`ko` déjà répété 76 fois, patron de mutation T75/T76 déjà écrit | exact |
| `plugin/_internal/vibeflow-update.sh::copy_module_scripts()` (MODIFIÉ : glob `*.json`) | utility (installeur, file-I/O) | file-I/O (copie de fichiers de données) | lui-même — boucle `*.txt` déjà écrite juste au-dessus (Site #3, 31-03), même patron exact à dupliquer pour `*.json` | exact |
| `plugin/mobile-test-team/agents/vf-test-orchestrator.md` (frontmatter : `vf-internal: true` + marqueur `Worker interne`) | agent (frontmatter déclaratif) | CRUD (édition d'un champ) | `plugin/business-pilot-bundle/agents/quality-gate-client.md` (déjà `vf-internal: true` + marqueur `Worker interne` dans `description:` — le patron exact à reproduire) | exact |
| `plugin/business-pilot-bundle/agents/quality-gate-client.md` + 3 autres juges (frontmatter : `omitClaudeMd: true`) | agent (frontmatter déclaratif) | CRUD (ajout d'un champ) | patron déjà documenté dans le schéma des champs `KNOWN` du gate lui-même (`check-agents.sh` l.176-179) — aucun agent du corpus ne porte encore `omitClaudeMd`, le champ existe déjà côté lint | role-match |
| `plugin/business-pilot-bundle/agents/vf-business-manager.md` + 3 autres managers (frontmatter : ajout `SendMessage` à `tools:`) | agent (frontmatter déclaratif) | CRUD (édition d'une liste existante) | `plugin/mobile-test-team/agents/vf-dev-manager.md` (cité en RESEARCH.md comme portant déjà `SendMessage` — manager conforme de référence) | exact |

## Pattern Assignments

### `plugin/conductor/scripts/check-agents-manifest.json` (config, file-I/O)

**Analogue :** aucun fichier JSON co-localisé n'existe dans le dépôt ; le patron structurel le plus proche est `known-versions.txt` (liste de référence datée, lue par le script bash/Python voisin) — mais **le schéma exact est déjà entièrement spécifié par RESEARCH.md** (§Code Examples, "Schéma JSON proposé du manifeste (D-01)"), à recopier tel quel comme point de départ :

```json
{
  "valide_jours": 30,
  "listes": {
    "outils": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/tools-reference",
      "valeurs": ["Agent", "Artifact", "AskUserQuestion", "Bash", "CronCreate", "CronDelete",
        "CronList", "Edit", "EndConversation", "EnterPlanMode", "EnterWorktree", "ExitPlanMode",
        "ExitWorktree", "Glob", "Grep", "ListAgents", "ListMcpResourcesTool", "LSP", "Monitor",
        "NotebookEdit", "PowerShell", "PushNotification", "Read", "ReadMcpResourceTool",
        "RemoteTrigger", "ReportFindings", "ScheduleWakeup", "SendFeedback", "SendMessage",
        "SendUserFile", "ShareOnboardingGuide", "Skill", "SubagentHandback", "TaskCreate",
        "TaskGet", "TaskList", "TaskOutput", "TaskStop", "TaskUpdate", "TodoWrite", "ToolSearch",
        "WaitForMcpServers", "WebFetch", "WebSearch", "Workflow", "Write"]
    },
    "champs_frontmatter": { "verifie_le": "2026-09-23", "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["name", "description", "tools", "disallowedTools", "model", "permissionMode",
        "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "omitClaudeMd",
        "effort", "isolation", "color", "initialPrompt", "experimental"] },
    "types_natifs": { "verifie_le": "2026-09-23", "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["explore", "plan", "general-purpose", "statusline-setup", "claude-code-guide", "fork"] },
    "modeles": { "verifie_le": "2026-09-23", "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["sonnet", "opus", "haiku", "fable", "inherit"] },
    "modes_permission": { "verifie_le": "2026-09-23", "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["default", "acceptEdits", "auto", "dontAsk", "bypassPermissions", "plan", "manual"] },
    "niveaux_effort": { "verifie_le": "2026-09-23", "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["low", "medium", "high", "xhigh", "max"] }
  }
}
```

**Note importante (Discretion) :** RESEARCH.md recommande de nommer le fichier `check-agents-manifest.json` pour éviter la collision de vocabulaire avec `vf_manifest_*` (l'installeur a déjà un concept « manifeste » distinct — `scripts/.vibeflow-manifest-<mod>`). À confirmer/verrouiller au plan (Claude's Discretion explicite en CONTEXT.md).

**Les champs VibeFlow (`vf-internal`, `vf-mcp-consumer`, `vf-mcp-tools`, `vf-requires`) restent codés en dur dans le script** — ils ne migrent PAS dans ce manifeste (ce sont des conventions internes, pas des identifiants Anthropic sujets à péremption externe).

---

### `plugin/conductor/scripts/check-agents.sh` (gate CLI, request-response)

**Analogue :** lui-même — extension in situ, aucun fichier externe à copier. Quatre zones précises à modifier.

**1. Les listes en dur à extraire (lignes 176-206 lues sur pièce)** :
```python
KNOWN = {"name", "description", "tools", "disallowedTools", "model", "permissionMode",
         "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "effort",
         "isolation", "color", "initialPrompt", "vf-internal", "vf-mcp-consumer", "vf-mcp-tools",
         "vf-requires"}
MODELS = {"sonnet", "opus", "haiku", "fable", "inherit"}
MEMORY = {"user", "project", "local"}
EFFORT = {"low", "medium", "high", "xhigh", "max"}
PERM = {"default", "acceptEdits", "auto", "dontAsk", "bypassPermissions", "plan", "manual"}
NOT_AGENTS = {"contracts.md", "README.md", "AGENTS.md"}
NATIVE_TYPES = {"explore", "plan", "general-purpose", "statusline-setup", "claude-code-guide", "fork"}
TOOL_NAMES = {
    "Agent", "Artifact", "AskUserQuestion", "Bash", "CronCreate", "CronDelete", "CronList",
    "Edit", "EndConversation", "EnterPlanMode", "EnterWorktree", "ExitPlanMode", "ExitWorktree",
    "Glob", "Grep", "ListMcpResourcesTool", "LSP", "Monitor", "NotebookEdit", "PowerShell",
    "PushNotification", "Read", "ReadMcpResourceTool", "RemoteTrigger", "ReportFindings",
    "ScheduleWakeup", "SendMessage", "SendUserFile", "ShareOnboardingGuide", "Skill", "TaskCreate",
    "TaskGet", "TaskList", "TaskOutput", "TaskStop", "TaskUpdate", "TodoWrite", "ToolSearch",
    "WaitForMcpServers", "WebFetch", "WebSearch", "Workflow", "Write",
}
AGENT_TOOL_NAMES = {"Agent", "Task"}
```
Ces sept assignations Python (`KNOWN`, `MODELS`, `MEMORY`, `EFFORT`, `PERM`, `NATIVE_TYPES`,
`TOOL_NAMES`) sont à remplacer par une lecture du manifeste (`KNOWN = set(manifest["listes"]["champs_frontmatter"]["valeurs"]) | VIBEFLOW_FIELDS`, `VIBEFLOW_FIELDS` restant en dur pour les 4 champs `vf-*`). `NOT_AGENTS` et `AGENT_TOOL_NAMES` restent en dur (pas dans le périmètre des 6 listes D-01).

**2. Chargement fail-closed (D-01/D-03) — à insérer avant `check_file()` (patron déjà donné intégralement par RESEARCH.md Pattern 1)** :
```python
try:
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)
except (OSError, json.JSONDecodeError) as e:
    print(f"[check-agents] ✗ manifeste illisible ({manifest_path}: {e}) — AUCUN verdict rendu (D-03)")
    sys.exit(1)
```
Style d'erreur cohérent avec les erreurs de contexte existantes du script (`errors.append(...)` puis rapport en fin d'exécution) — mais D-03 exige un refus IMMÉDIAT et explicite, pas un `errors.append` noyé parmi d'autres ; suivre le patron `print(...) ; sys.exit(1)` déjà utilisé pour `fichier introuvable : {single}` (variante synchrone, hors boucle `errors`).

**3. Résolution en monde fermé (I2/I3, D-09) — réutilise `resolve_agent_name()` déjà présent (l.399, lu sur pièce)** :
```python
def resolve_agent_name(name, agents_dir_local, registry_dirs_local, prefixes):
    low = name.lower()
    if low in NATIVE_TYPES:
        return "native"
    for pfx in prefixes:
        if pfx and name.startswith(pfx):
            return "thirdparty"
    if os.path.isfile(os.path.join(agents_dir_local, name + ".md")):
        return "resolved"
    for rd in registry_dirs_local:
        if rd and os.path.isfile(os.path.join(rd, name + ".md")):
            return "resolved"
    return "unresolved"
```
I2/I3 doivent appeler CETTE fonction (jamais une seconde résolution parallèle — cf. RESEARCH.md §Don't Hand-Roll).

**4. Découverte à un seul niveau à étendre (l.650, lue sur pièce)** :
```python
files = sorted(glob.glob(os.path.join(agents_dir, "*.md")))
files = [f for f in files if os.path.basename(f) not in NOT_AGENTS]
```
→ à remplacer par le glob récursif + exclusion `-references`/`_reference` donné intégralement par RESEARCH.md Pattern 5.

**Erreur/warning — patron de bascule déjà en place, à réutiliser pour D-05 (rétrogradation)** :
```python
if name not in TOOL_NAMES and not is_agent_tool and not name.startswith("mcp__"):
    msg = f"{base} : {field} — outil hors du set connu '{name}' (typo ? nouvel outil non encore reference ?)"
    (errors if strict else warnings).append(msg)
```
Le patron `(errors if strict else warnings).append(msg)` est LE mécanisme déjà en place pour moduler la sévérité selon un booléen — à réutiliser identiquement pour `(errors if strict and not perime else warnings).append(msg)` sur les 3 classes nommées par D-05 (outil inconnu, champ inconnu, type natif inconnu) SEULEMENT. `model`/`memory`/`effort` invalides restent dans `errors.append(...)` sans condition de fraîcheur (Pitfall 3 de RESEARCH.md).

**Champ inconnu (l.641-643, lu sur pièce) — à moduler par la fraîcheur de la même façon :**
```python
for k in fm:
    if k not in KNOWN:
        warnings.append(f"{base} : champ inconnu du runtime — {k} (typo ? champ invente ? verifier la doc)")
```

---

### `plugin/conductor/scripts/tests/test-check-agents.sh` (test, request-response)

**Analogue :** lui-même — patron `ok`/`ko` répété 76 fois, plus le patron de mutation discriminante T76 (le plus récent et le plus proche du besoin FABR-03 : mutation prouvée rouge, factorisée en fonction).

**En-tête catalogue (l.1-40, lu sur pièce)** — chaque nouveau cas (T77+) doit s'ajouter à cette table de sommaire avant son bloc de test :
```bash
# check-agents.sh :
#   T1 — agent complet (name/description/model/memory/skills existants) → exit 0
#   ...
#   T76 — team-kernel.md : lecture 2026-08-04 PERIMEE (hotfix v2.63.2, deja correct — AUCUNE action requise cette phase)
```

**Patron de mutation discriminante (T76, l.1393-1460, lu sur pièce) — à reproduire pour I1-I7 :**
```bash
t76_detect() { # <file> -> imprime les litteraux/champs manquants entre crochets (vide = complet)
  local f="$1" manquants="" lit
  for lit in "PÉRIMÉE" "2026-09-17" "profondeur 3" ...; do
    grep -qF "$lit" "$f" || manquants="$manquants [$lit]"
  done
  printf '%s' "$manquants"
}
if [ ! -f "$T76_KERNEL" ]; then
  ko "..."
else
  T76_MANQUANTS="$(t76_detect "$T76_KERNEL")"
  if [ -z "$T76_MANQUANTS" ]; then ok "..."; else ko "... $T76_MANQUANTS"; fi
  # DISCRIMINANT par mutation : t76_detect() ELLE-MEME (pas un grep parallele independant) doit
  # rougir quand "profondeur 3" disparait du fichier sonde
fi
```
Principe à reproduire pour chaque invariant I1-I7 : **la même fonction de détection sert au contrôle positif ET à la preuve de mutation** — jamais un second grep indépendant qui n'exerce pas le code réel (évite la tautologie dénoncée par le commentaire de revue hotfix v2.63.2).

**Fixture de découverte récursive (D-10) — donnée intégralement par RESEARCH.md, à recopier telle quelle :**
```bash
MUT_AG="$WORK/t-recursive"; mkdir -p "$MUT_AG/sub-references"
cp "$SK_VALID_AGENT" "$MUT_AG/valid.md"
echo "pas un agent" > "$MUT_AG/sub-references/lead-knowledge.md"
OUT="$(bash "$CHECK" --agents-dir="$MUT_AG" --skills-dir="$SK" 2>&1)"; RC=$?
# attendu : rc=0 (valid.md conforme), AUCUNE mention de sub-references/lead-knowledge.md dans $OUT
```

**Aucun cas T76 à modifier** (D-13/Pitfall 1 : déjà correct, ne pas y toucher).

---

### `plugin/_internal/vibeflow-update.sh::copy_module_scripts()` (utility, file-I/O)

**Analogue :** lui-même — la boucle `*.txt` (Site #3, 31-03, lue sur pièce l.1996-2005) est le patron EXACT à dupliquer pour `*.json`, y compris son commentaire de contexte (référence explicite au précédent `known-versions.txt`) :
```bash
  # Site #3 (31-03), même motif de garde que #2. Fichiers de DONNEES accompagnant les scripts
  # (*.txt). Sans cette boucle, un module pouvait referencer un fichier que l'engine ne posait
  # JAMAIS chez l'utilisateur : c'est exactement ce qui est arrive a `known-versions.txt`...
  for f in "$module_dir/scripts/"*.txt; do
    [ -f "$f" ] && vf_place_file "$f" "$TARGET_ROOT/scripts/$(basename "$f")"
  done
```
**Extension requise (D-16, Pitfall 2)** — même patron, glob `*.json` ajouté, sans mode `exec` (fichier de données, pas un exécutable) :
```bash
  for f in "$module_dir/scripts/"*.json; do
    [ -f "$f" ] && vf_place_file "$f" "$TARGET_ROOT/scripts/$(basename "$f")"
  done
```
**Contrainte de vague :** cette extension DOIT être posée dans la même vague que le fichier manifeste lui-même (jamais dans un plan séparé qui s'exécuterait après) — sinon D-03 refuse le gate sur tout lab installé depuis le plugin. Les témoins de non-régression sont les jobs CI `lab-frais` et `lab-frais-arme` (RESEARCH.md, Pitfall 2).

---

### `plugin/mobile-test-team/agents/vf-test-orchestrator.md` (agent, frontmatter, I3)

**Analogue :** `plugin/business-pilot-bundle/agents/quality-gate-client.md` — DÉJÀ conforme I1, patron exact à reproduire (frontmatter lu sur pièce, lignes 1-10) :
```yaml
---
name: quality-gate-client
description: "... Worker interne — dispatché UNIQUEMENT par vf-business-manager ou le skill vf-business, toujours frais, pas en usage direct."
tools: Read, Glob, Grep
disallowedTools: Write, Edit
...
vf-internal: true
---
```
**Correction à appliquer sur `vf-test-orchestrator.md`** (frontmatter pur, aucune ligne de corps touchée — Pitfall 5) : ajouter `vf-internal: true` en frontmatter ET la sous-chaîne littérale `Worker interne` dans `description:`. Cette correction unique résout SIMULTANÉMENT I2 (dispatché par `vf-dev-manager`, plus orphelin), I3 (marqué interne) et exempte de I6 par la définition même de D-07 (« manager = `Agent(...)` non vide ET **non** `vf-internal` ») — recommandation RESEARCH.md Open Question 1, à confirmer/verrouiller par le planificateur.

---

### `quality-gate-client.md` + `content-clarity-judge.md` + `growth-quality-judge.md` + `vf-design-judge.md` (agent, frontmatter, I5)

**Analogue :** `quality-gate-client.md` lui-même (déjà porteur de `disallowedTools: Write, Edit` sans `Agent(...)` — classification « juge » D-08 déjà correcte, seul `omitClaudeMd` manque). Frontmatter actuel (lu sur pièce) :
```yaml
tools: Read, Glob, Grep
disallowedTools: Write, Edit
vf-internal: true
```
**Correction à appliquer sur les 4 fichiers** (une ligne de frontmatter par fichier, patron identique répété 4 fois) :
```yaml
omitClaudeMd: true
```
Placer la ligne dans le bloc frontmatter existant, cohérent avec l'ordre déjà utilisé par le script (`KNOWN` liste `omitClaudeMd` après `background`). Ne touche à aucune ligne après le second `---` (Pitfall 5).

---

### `vf-business-manager.md` + `vf-content-manager.md` + `vf-growth-manager.md` + `vf-design-manager.md` (agent, frontmatter, I6)

**Analogue :** `plugin/mobile-test-team/agents/vf-dev-manager.md` (cité par RESEARCH.md comme manager déjà conforme, porteur de `SendMessage`). Frontmatter observé sur un manager du même patron structurel (`vf-business-manager.md`, lu sur pièce) :
```yaml
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent(vf-business-commercial, vf-business-delivery, vf-business-finance, quality-gate-client)
```
**Correction à appliquer sur les 4 fichiers managers** : ajouter le token `SendMessage` à la liste `tools:` existante (ligne déjà présente, pas une ligne nouvelle) :
```yaml
tools: Read, Write, Bash, Glob, Grep, Skill, SendMessage, AskUserQuestion, Agent(vf-business-commercial, vf-business-delivery, vf-business-finance, quality-gate-client)
```
`SendMessage` est déjà un identifiant valide dans `TOOL_NAMES` (aucun ajout au manifeste requis pour ce token). Correction de frontmatter pur — n'affecte pas la colonne INSTR du ratchet (Pitfall 5).

---

## Shared Patterns

### Contrat de sortie fail-closed (0/1/3, silence de code sous `--hook`)
**Source :** en-tête de `plugin/conductor/scripts/check-agents.sh` (commentaire « BLOQUANT »/« WARNING », contrat F13) + `hook_exit()` de `check-blueprints.sh` :
```bash
hook_exit() { [ "$HOOK" -eq 1 ] && exit 0; exit "$1"; }
```
**S'applique à :** tout nouveau chemin de sortie ajouté par cette phase (manifeste absent → exit 1 ; manifeste périmé + `--manifest-freshness=strict` → exit 3 ; jamais de silence de message même sous `--hook`, seul le CODE est traduit vers 0).

### Bascule erreur/warning conditionnée par un booléen (`strict`)
**Source :** `plugin/conductor/scripts/check-agents.sh`, patron répété plusieurs fois dans le fichier :
```python
(errors if strict else warnings).append(msg)
```
**S'applique à :** D-05 — même patron, étendu d'une seconde condition (`strict and not perime`) pour les 3 classes nommées (outil/champ/type natif inconnu) seulement.

### Délégation sans réimplémentation (« une seule vérité »)
**Source :** `check-blueprints.sh` (PR #85) — shell-out complet vers `check-agents.sh --file`, aucune règle de lint réimplémentée :
```bash
GATE="$SCRIPT_DIR/check-agents.sh"
...
args=(--file "$agent")
[ "$STRICT" -eq 1 ] && args+=(--strict)
```
**S'applique à :** le principe D-01 lui-même (« le script ne garde AUCUNE copie de repli des listes ») — même discipline architecturale, verbalisée explicitement dans le commentaire d'en-tête de `check-blueprints.sh` : « un seul référentiel, donc aucune seconde vérité à tenir ».

### Trailer `Gate-Touche:` (G-2) — table de vérité exacte
**Source :** RESEARCH.md Pitfall 6, dérivée de la lecture de `scripts/check-gate-touche.sh`.
**S'applique à :** tout commit qui touche `check-agents.sh`, `test-check-agents.sh` ou `.github/workflows/ci.yml` (classes 1/3/4) — PAS `hooks.json`, PAS `guard-agent-write.sh`, PAS les 9 fichiers du corpus, PAS le manifeste JSON lui-même (aucun ne commence par `check-*.sh` ni n'est sous `scripts/hooks/`).

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| `plugin/conductor/scripts/check-agents-manifest.json` | config | file-I/O | Aucun fichier JSON de données n'existe encore co-localisé avec un gate du dépôt — le schéma vient entièrement de RESEARCH.md (spec dérivée des docs officielles), pas d'un fichier analogue sur disque. Structurellement le plus proche reste `known-versions.txt` (texte, pas JSON). |

## Metadata

**Périmètre de recherche d'analogues :** `plugin/conductor/scripts/`, `plugin/conductor/scripts/tests/`, `plugin/_internal/`, `plugin/business-pilot-bundle/agents/`, `plugin/mobile-test-team/agents/`, PR #85 (`origin/fix/blueprints-conformite-gate`).
**Fichiers scannés :** 8 fichiers lus intégralement ou par plages ciblées (check-agents.sh 708 lignes, test-check-agents.sh 1504 lignes, vibeflow-update.sh plage 1960-2030, check-blueprints.sh intégral via `git show`, 3 fichiers agents de corpus).
**Date d'extraction :** 2026-09-23
