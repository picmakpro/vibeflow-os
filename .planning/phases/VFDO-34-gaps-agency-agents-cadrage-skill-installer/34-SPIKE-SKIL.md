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

## Nettoyage

Liste construite AU FUR ET À MESURE de la pose (dès la création de chaque artefact), pas
reconstituée en fin de plan. Le sous-agent de sonde ci-dessous reste EN PLACE jusqu'à la fin de la
tâche 2 (il est réutilisé tel quel pour le cas cible A — même type de sonde exigé par le protocole,
sans quoi le contrôle négatif ne contrôlerait rien) ; sa suppression effective et sa preuve
d'absence sont apportées par la tâche 2, § « Nettoyer et prouver ».

- chemin supprimé : /Users/samuel/.claude/agents/skil01-probe-agent.md
