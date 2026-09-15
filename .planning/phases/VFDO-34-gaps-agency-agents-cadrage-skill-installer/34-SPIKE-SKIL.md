# SPIKE — Phase 34 : go/no-go SKIL-01 (skill posé par le canal `/plugin` natif atteint-il un sous-agent doté de l'outil `Skill` ?)

> **Verdict** : (provisoire — posé par la tâche 3, après le checkpoint bloquant-humain)

## Périmètre

SHA de base : 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f

Seul fichier de ce dépôt modifié par ce plan : ce fichier. Tout le reste de l'appareil de mesure
(sous-agent de sonde, plugin jetable, dépôt Git jetable) est fabriqué **hors du dépôt**
`vibeflow-os`, sous le territoire de l'utilisateur (`~/.claude/agents/`) ou dans un dossier
scratch de session, jamais sous `plugin/`.

## Protocole exécuté

Protocole repris tel qu'écrit dans `34-RESEARCH.md` (doc officielle citée + mesure locale de la
frontière `tools: Skill` sur les 25 agents distribués, protocole de spike à contrôle négatif) et
`34-PATTERNS.md` § `34-SPIKE-SKIL.md` — contrôle négatif d'abord, puis cas cible A. Aucune
réinvention : chaque commande ci-dessous a été RÉELLEMENT exécutée sur ce poste le 2026-09-15.

### (0) SHA de base

```
$ git rev-parse HEAD
7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f
```

### (1) Fabrication du sous-agent de sonde

Fichier créé : `~/.claude/agents/skil01-probe-agent.md` (hors du dépôt, territoire utilisateur),
cinq champs requis par `plugin/conductor/scripts/check-agents.sh` (`name`, `description`, `model`,
`memory`, `effort`) plus les champs réels reconnus par Claude Code pour un fichier d'agent
(`name`, `description`, `tools`) — forme reproduite depuis `plugin/mobile-test-team/agents/vf-test-runner.md`.
Ligne d'outils : `tools: Skill` — **explicitement et uniquement** l'outil `Skill`, pour que l'échec
du contrôle négatif ne puisse être imputé qu'à l'absence de découverte, jamais à l'absence de
l'outil (Pitfall 5).

```yaml
---
name: skil01-probe-agent
description: "Sonde jetable Phase 34 (SKIL-01) — invoque un skill par son nom via l'outil Skill et rapporte littéralement le résultat. JETABLE, supprimé en fin de spike, jamais un agent de production."
tools: Skill
model: sonnet
memory: none
effort: low
vf-internal: true
---
```

Mécanisme de dispatch retenu — **et pourquoi** : l'outil `Agent`/`Task` du présent exécutant
(`vf-coder`) est gouverné par un allowlist de `subagent_type` fixé à son propre frontmatter, qui
n'inclut PAS de nom arbitraire comme `skil01-probe-agent` ; de plus, la documentation Claude Code
(citée dans `INSTALL.md` de ce dépôt) indique que le registre d'agents d'une session est résolu
**au démarrage** et n'est pas rechargé en cours de session — un fichier d'agent créé après le
démarrage de la session courante ne serait donc pas vu par un dispatch interne à cette session,
quelle que soit sa présence sur disque. Le dispatch réel s'est donc fait par un **process CLI
`claude` frais et distinct**, qui lit sa propre configuration d'agents au moment où IL démarre —
c'est la forme fidèle à la précondition de la tâche 1 (« la commande `claude` est résolvable sur
le PATH … et répond à `claude plugin --help` sans interface bloquante »), qui présuppose déjà un
appel CLI, pas un dispatch interne à cette session.

```
$ which claude && claude --version
/Users/samuel/.local/bin/claude
2.1.271 (Claude Code)

$ claude plugin --help
(sortie normale, non bloquante — précondition satisfaite)
```

### (2) Preuve d'absence de `skil01-probe-nonexistant` AVANT mesure

Trois emplacements sondés, verbatim :

```
$ rtk proxy grep -ril "skil01-probe-nonexistant" ~/.claude/skills/
(sortie vide)
exit=1

$ rtk proxy find ~/.claude/skills -iname "*skil01*"
(sortie vide)
exit=0

$ rtk proxy grep -ril "skil01-probe-nonexistant" /Users/samuel/Documents/dev/vibeflow-os/.claude/skills/
grep: /Users/samuel/Documents/dev/vibeflow-os/.claude/skills/: No such file or directory
exit=2
```
Le dossier de skills PROJET n'existe même pas dans `vibeflow-os` (`.claude/` existe, `.claude/skills/`
non) : absence garantie par construction, pas seulement par recherche vide.

```
$ rtk proxy grep -ril "skil01-probe-nonexistant" ~/.claude/plugins/
(sortie vide)
exit=1

$ rtk proxy find ~/.claude/plugins -iname "*skil01*"
(sortie vide)
exit=0
```
Nom prouvé absent des trois emplacements (skills utilisateur, skills projet, cache de plugins)
avant tout dispatch.

### (3) Contrôle négatif joué

Commande verbatim (process CLI frais, cwd neutre hors dépôt, `--allowedTools Skill` en plus de la
ligne `tools:` de l'agent pour garantir qu'aucun autre outil n'intervient) :

```
$ cd /private/tmp/.../scratchpad/skil01 && claude --agent skil01-probe-agent -p \
  "Invoque, via l'outil Skill, un skill nommé exactement skil01-probe-nonexistant. Rapporte \
   littéralement et intégralement ce que tu obtiens (succès, erreur, ou absence de découverte), \
   sans reformuler." --permission-mode bypassPermissions --allowedTools Skill
```

Réponse littérale du sous-agent (recopiée sans paraphrase) :

```
Résultat obtenu littéralement suite à l'invocation de l'outil `Skill` avec `skill: skil01-probe-nonexistant` :

```
Unknown skill: skil01-probe-nonexistant
```
```

Sortie process : `EXIT=0` (le process CLI se termine normalement ; c'est le CONTENU de la réponse,
pas le code de sortie du process, qui porte le verdict du contrôle négatif).

## Contrôle négatif

Mandat donné (une ligne) : invoquer par l'outil `Skill` le skill `skil01-probe-nonexistant`
(prouvé absent des trois emplacements ci-dessus), puis rapporter littéralement.

Réponse littérale : `Unknown skill: skil01-probe-nonexistant` — le sous-agent n'a RIEN trouvé, il
ne prétend pas avoir découvert un skill inexistant.

Ligne de mesure (format exact requis) :

CONTROLE-NEGATIF: ECHEC

L'appareil de mesure discrimine : un nom absent produit un échec de découverte propre, pas un faux
positif. Le spike peut se poursuivre vers le cas cible A (arête 1 des hypothèses signalées : si ce
contrôle avait réussi, verdict `MESURE INVALIDE` immédiat, sans tâche 2).

## Cas cible A

### (1) Plugin jetable fabriqué

Dépôt Git jetable créé hors du dépôt `vibeflow-os`, nom `skil01-probe-plugin`, avec un descripteur
`.claude-plugin/plugin.json` minimal (forme reproduite depuis `plugin/.claude-plugin/plugin.json`)
et un `.claude-plugin/marketplace.json` (le même dépôt sert de marketplace à lui-même, `source: "."`
— pattern usuel d'un marketplace mono-plugin) plus UN seul skill,
`skills/skil01-probe-skill/SKILL.md`, dont les instructions imposent la sentinelle exacte
`SKIL01_PROBE_OK` comme unique réponse possible en cas d'invocation.

Chemin créé (inscrit au nettoyage dès sa création) :
`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/db082daa-75e4-4a05-bfb1-575528ffda73/scratchpad/skil01/skil01-probe-plugin`

### (2) Pose par le canal natif, scope user

Commandes verbatim et sorties, exécutées depuis `INSTALL.md` lignes 26-37 (forme
`claude plugin marketplace add <source>` / `claude plugin install <plugin>@<marketplace>`) :

```
$ claude plugin marketplace add /private/tmp/.../scratchpad/skil01/skil01-probe-plugin
Adding marketplace…✔ Successfully added marketplace: skil01-probe-marketplace (declared in user settings)
EXIT=0

$ claude plugin marketplace list
...
  ❯ skil01-probe-marketplace
    Source: Directory (/private/tmp/.../scratchpad/skil01/skil01-probe-plugin)

$ claude plugin install skil01-probe-plugin@skil01-probe-marketplace
Installing plugin "skil01-probe-plugin@skil01-probe-marketplace"...✔ Successfully installed plugin: skil01-probe-plugin@skil01-probe-marketplace (scope: user)
EXIT=0

$ claude plugin list | grep skil01
  ❯ skil01-probe-plugin@skil01-probe-marketplace
```

Les deux commandes se sont exécutées sans interface interactive bloquante — arête 2 des
hypothèses signalées non déclenchée.

### (3) Mesure

Même type de sonde qu'en tâche 1 (`skil01-probe-agent`, `tools: Skill` — le fichier d'agent n'a
pas été recréé, il était encore en place à ce stade), dispatché par le même mécanisme (process CLI
`claude` frais, cwd neutre `.../scratchpad/skil01`, hors du dépôt de plugin lui-même pour ne
mesurer QUE le scope user, pas un scope project qui se superposerait) :

```
$ claude --agent skil01-probe-agent -p \
  "Invoque, via l'outil Skill, le skill nommé skil01-probe-plugin:skil01-probe-skill. Rapporte \
   littéralement et intégralement ce que tu obtiens, sans reformuler." \
  --permission-mode bypassPermissions --allowedTools Skill
```

Réponse littérale du sous-agent, recopiée sans paraphrase :

```
SKIL01_PROBE_OK
```
`EXIT=0`.

CAS-A: ATTEINT

Le nom invoqué était la forme namespacée `<plugin-name>:<skill-name>` (`skil01-probe-plugin:skil01-probe-skill`)
— c'est un fichier `SKILL.md` invoqué par l'outil `Skill`, jamais une slash command
auto-découverte par le canal plugin : la sonde n'a utilisé QUE l'outil `Skill` (`--allowedTools
Skill`), aucune commande `/` n'a été tapée nulle part dans ce protocole.

### (4) Scope project — non mesuré

Scope project : non mesuré — le résultat du scope user (`CAS-A: ATTEINT`) n'a rien de surprenant
au regard de la doc officielle citée dans `34-RESEARCH.md` (§ citation `sub-agents` : « the
subagent can still discover and invoke project, user, and plugin skills through the Skill tool »),
et ce résultat ne penche PAS vers un GO SKIL-01 (un canal qui atteint déjà le sous-agent réduit le
différenciateur plutôt qu'il ne l'établit) — les deux conditions de la recommandation de l'Open
Question 2 de `34-RESEARCH.md` (« mesurer project seulement si le résultat user surprend ou si le
verdict user est un GO ») ne sont donc PAS réunies. Ce non-mesuré est écrit ici, pas tu.

## Ce que l'engine actuel couvre déjà

`plugin/_internal/vibeflow-update.sh` pose, sauvegarde, restaure et désinstalle déjà des skills
bruts en scope user, sans second système à inventer sur un éventuel GO :

- **Pose** (lignes ~2218-2229) : un module de type "single-skill" (`SKILL.md` à la racine du
  module) est copié vers `$TARGET_ROOT/skills/$mod/SKILL.md` via `vf_place_file` ; un module de
  type "multi-skills" (`skills/<name>/SKILL.md` imbriqués) est copié via `vf_place_tree` pour
  chaque sous-dossier — les deux formes de layout de skill que verrait un skill-installer sont déjà
  couvertes par l'engine.
- **Backup** (ligne ~2478) : avant tout overwrite, `[ -d "$TARGET_ROOT/skills/$mod" ] && cp -r
  "$TARGET_ROOT/skills/$mod" "$bdir/skills"` — une pose de skill existante est sauvegardée avant
  d'être remplacée.
- **Rollback** (lignes ~2606-2608) : `rm -rf "$TARGET_ROOT/skills/$mod"; cp -r "$latest/skills"
  "$TARGET_ROOT/skills/$mod"` — restauration symétrique depuis le dernier backup.
- **Désinstallation** (autour de la ligne ~2726, fonction `_vf_uninstall_from_cache`) : ne retire
  QUE les skills possédés par le module désinstallé (lus depuis le cache), jamais un skill d'un
  autre module ou de l'utilisateur — exactement la garde anti-écrasement que Pitfall 12 exige.

Un GO ne rouvrirait donc PAS un second système de pose (le risque explicite de Pitfall 12) : il
réutiliserait ce chemin existant pour un nouveau type de module ("catalogue de skills"), ce qui
resterait strictement du câblage (D-09), jamais une nouvelle logique de copie.

## Nettoyage

Liste construite AU FUR ET À MESURE de la pose (dès la création de chaque artefact), pas
reconstituée en fin de plan.

- chemin supprimé : /Users/samuel/.claude/agents/skil01-probe-agent.md
- chemin supprimé : /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/db082daa-75e4-4a05-bfb1-575528ffda73/scratchpad/skil01/skil01-probe-plugin

Preuve d'absence, machine, après nettoyage :

```
$ claude plugin uninstall skil01-probe-plugin
✔ Successfully uninstalled plugin: skil01-probe-plugin (scope: user)

$ claude plugin marketplace remove skil01-probe-marketplace
✔ Successfully removed marketplace: skil01-probe-marketplace

$ rm -rf .../scratchpad/skil01/skil01-probe-plugin
$ rm -f ~/.claude/agents/skil01-probe-agent.md

$ test -e .../scratchpad/skil01/skil01-probe-plugin || echo "REPO ABSENT"
REPO ABSENT
$ test -e ~/.claude/agents/skil01-probe-agent.md || echo "AGENT ABSENT"
AGENT ABSENT
$ claude plugin list | grep -i skil01 || echo "PLUGIN ABSENT FROM LIST"
PLUGIN ABSENT FROM LIST
$ claude plugin marketplace list | grep -i skil01 || echo "MARKETPLACE ABSENT FROM LIST"
MARKETPLACE ABSENT FROM LIST
```

Aucun chemin sous les préfixes `skil01-probe` ne subsiste ; rien d'autre n'a été supprimé (aucun
skill préexistant de l'utilisateur, aucun autre marketplace ou plugin, n'a été touché).
