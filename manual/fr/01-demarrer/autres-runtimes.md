# Installer hors Claude Code

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/other-runtimes.md)
<!-- /vf-manual:lang -->

VibeFlow est né comme plugin Claude Code, mais il ne s'y limite plus : l'install et l'usage ont
été **mesurés de bout en bout** sur **Codex** et sur **kimi-code**. Cette page dit exactement ce
qui a été prouvé sur chaque runtime, avec quelles commandes, et **ce qui se perd** — parce qu'une
portabilité qui tait ses pertes n'est pas une portabilité, c'est une promesse.

## Ce qui est prouvé, runtime par runtime

| Runtime | Canal d'install | Ce qui a été constaté |
|---|---|---|
| **Claude Code** | `claude plugin` | Runtime de référence : tout le périmètre, hooks de gouvernance compris. |
| **Codex** | `codex plugin` (natif) | Install **et** usage réels : une délégation manager → worker a produit du code. |
| **kimi-code** | *aucun* — chargement par fichier | Un agent VibeFlow chargé par `--agent-file` a produit du code **et** son rapport typé. |
| **OpenCode, autres** | non mesuré | L'engine ne devine rien : il affiche l'**étape manuelle** à faire et sort proprement. |

Deux conséquences pratiques à retenir avant d'aller plus loin.

**La détection de runtime est une cascade, et le premier trouvé gagne** — dans l'ordre `claude`,
`codex`, `opencode`, puis kimi-code (sondé à part, par capacité, parce que son binaire s'appelle
`kimi` et qu'un autre produit porte le même nom). Sur un poste qui a **aussi** Claude Code
installé, l'engine choisira donc Claude Code. Pour forcer une cible, pose la variable
d'environnement `VF_RUNTIME` :

```bash
VF_RUNTIME=codex …
```

Sans elle, tu mesures une install Claude en croyant mesurer Codex — c'est le piège n°1 de cette
page.

**Les hooks ne sont portés sur aucun runtime autre que Claude Code.** VibeFlow pose ses hooks de
gouvernance dans `settings.json`, que les autres runtimes n'exécutent pas. Le gate de fidélité te
le **dit** à l'install et au statut (`[fidelity-coexistence]`) plutôt que de te laisser croire que
les protections tournent. Tout le reste — agents, skills, planning sur disque — fonctionne.

## Codex

Deux commandes, la même logique que sous Claude Code (nom du verbe près : c'est `add`, pas
`install`) :

```bash
codex plugin marketplace add picmakpro/vibeflow-os
codex plugin add vibeflow@vibeflow-os
```

Puis lance la configuration comme ailleurs : demande à VibeFlow de s'installer (`/vibeflow-install`
sous Claude Code, la même skill en langage naturel sous Codex). Le dépôt embarque un manifeste
Codex natif en plus du manifeste Claude Code — le support est explicite, il ne dépend plus d'un
repli non documenté.

### Trois préconditions d'environnement

Elles ne sont pas optionnelles, et deux d'entre elles échouent **en silence** :

1. **`multi_agent_v2` doit être actif.** Sans cette option, **aucun outil de spawn n'existe** côté
   Codex : l'équipe de mission ne peut pas se déployer. L'engine tente de l'activer pour toi
   (`codex features enable multi_agent_v2`) et te dit ce qu'il a trouvé.
2. **Le dépôt cible doit être « trusted ».** Tant qu'un lancement interactif de `codex` dans le
   dossier n'a pas répondu au prompt de confiance, `.codex/agents/` **n'est jamais parsé** : zéro
   rôle VibeFlow chargé — pendant que `codex doctor` continue d'annoncer que tout va bien. Cette
   confiance est un geste humain ; aucun script de VibeFlow ne l'écrit à ta place.
3. **`VF_RUNTIME=codex`** si `claude` est présent sur le même poste (voir la cascade ci-dessus).

### Ce qui se perd, déclaré

- **Les hooks de gouvernance ne s'exécutent pas** (voir plus haut). Codex a bien sa propre surface
  de hooks, mais VibeFlow ne l'a pas encore visée — ce n'est pas promis avant d'être livré.
- **Le confinement par rôle est inerte.** `sandbox_mode`, `approval_policy` et `[permissions]`
  déclarés dans un fichier de rôle sont acceptés puis ignorés — mesuré en session réelle, un rôle
  déclaré en lecture seule a réellement écrit sur disque. Un juge VibeFlow n'est confiné que par
  une **session `codex exec -s read-only` séparée**, jamais par son fichier de rôle.
- **La mémoire d'agent n'est pas portée**, et les modèles sont **remappés** vers des modèles Codex
  (les noms Claude n'existent pas côté Codex et feraient échouer tout spawn).

Le retrait est symétrique : désinstaller un module retire aussi les rôles Codex qu'il avait posés.

## kimi-code

kimi-code n'a **pas** de canal d'install : rien n'est converti, rien n'est enregistré. Son parseur
lit directement le fichier d'agent VibeFlow, que tu lui désignes :

```bash
kimi --agent-file <chemin>/vf-coder.md
```

Passe toujours par `--agent-file` plutôt que par la découverte de répertoire : c'est la seule forme
qui rend un message d'erreur complet quand un agent est refusé, et elle contourne la règle
« premier nom gagne » qui peut masquer un agent en silence.

**Ce qui traverse** : `name`, `description`, `tools`, `disallowedTools` — ce dernier retire
réellement l'outil du toolset, ce n'est pas décoratif.

**Ce qui est ignoré sans le moindre diagnostic** : `model`, `memory`, `vf-internal`, `effort`,
`skills`, `vf-requires`, `vf-mcp-consumer`, `vf-mcp-tools`. Le parseur les tolère et les jette.

**La conséquence la plus importante de cette liste** : `vf-internal` étant perdu, un worker conçu
pour n'être **dispatché que par un orchestrateur** devient invocable **directement** par toi
(`kimi --agent <nom>`). Le cloisonnement ne tient plus sur cette cible — mesuré, pas déduit. Le
champ `subagents` de kimi restreint le dispatch par un parent, jamais l'invocation directe : c'est
un palliatif partiel, pas une solution.

**Étape suivante.** Les prérequis système (`bash`, `jq`, `python3`) sont les mêmes sur tous les
runtimes — voir [prerequis.md](./prerequis.md). Pour la procédure de référence sous Claude Code,
voir [installation.md](./installation.md).

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/installation.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/choisir-son-scope.md)
<!-- /vf-manual:nav -->
