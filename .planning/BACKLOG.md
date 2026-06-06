# Backlog — idées différées (hors milestone courant)

## Skill-installer global (multi-agents)
**Capturé :** 2026-06-04 · **À explorer :** après le milestone « Install UX »

Étendre l'approche d'install à toggles (plugin + skill `/vibeflow-install`) à l'**installation
de skills globaux disponibles pour tous les agents** — un « skill-installer » générique :
choisir des skills (pas seulement des modules VibeFlow) et les rendre disponibles globalement à
l'ensemble des agents, via la même UX à toggles + scope.

**Pourquoi différé :** chantier distinct du milestone Install UX (qui cible la distribution des
modules VibeFlow). À reprendre une fois l'engine scope-aware + le skill `/vibeflow-install` livrés
(ils en seront la fondation réutilisable).

**Déclencheur de resurgence :** clôture du milestone « Install UX ».

## Template d'agent installable s'appuyant sur dev-orchestrator
**Capturé :** 2026-06-06 · **À explorer :** quand un besoin réel d'agent de domaine apparaît

Fournir un **module « agent starter »** (type `agent-only`, ex. `dev-agent-starter`) qu'un
utilisateur coche dans `/vibeflow-install` pour poser un agent dev prêt à l'emploi qui pilote le
pipeline VibeFlow. Install « facile » assurée par `requires: ["dev-orchestrator"]` (fermeture
transitive → dev-orchestrator + ses verbes `/vf-*` tirés automatiquement).

**Contraintes techniques déjà établies (cette session) :**
- **Pas d'imbrication de sous-agents** en Claude Code : l'agent ne peut PAS déléguer à l'agent
  `vibeflow-dev`, et les `/vf-*` → GSD spawnent eux-mêmes des sous-agents. Donc l'agent template
  ne fonctionne pleinement que lancé comme **agent principal** (`claude --agent`).
- Le pont propre = l'agent **invoque les skills `/vf-*`** (il hérite du `Skill` tool), il ne
  délègue pas agent→agent.
- Mécanisme d'install natif déjà en place : `vibeflow-update.sh` pose `AGENT.md` →
  `.claude/agents/<mod>.md` + `references/` → `.claude/agents/<mod>-references/`.

**Question ouverte à trancher AVANT de construire :** qu'est-ce que cet agent fait **de plus** que
`vibeflow-dev` ? S'il ne fait que router à l'identique, il le duplique. → passer par un court
brainstorming (périmètre + valeur ajoutée + nom du module) avant tout code.

**Pourquoi différé :** pas de besoin concret aujourd'hui ; `dev-orchestrator` couvre déjà l'usage
direct (agent `vibeflow-dev` + `/vf-*`).

**Déclencheur de resurgence :** apparition d'un vrai cas d'agent spécialisé (de domaine) à
distribuer aux utilisateurs.
