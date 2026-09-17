---
name: registre-agents-resolu-au-demarrage
description: Le registre d'agents/skills est résolu au DÉMARRAGE de session, les workers contournent en `claude` CLI frais avec bypassPermissions, et `plugin uninstall` ne vide jamais le cache disque
metadata:
  type: project
---

Deux faits mesurés le 2026-09-15 (spike SKIL-01, Phase 34) qui gouvernent toute mission qui
POSE un agent ou un skill puis veut le VOIR :

1. **Le registre est résolu au démarrage de session.** Un fichier d'agent ou de skill créé en
   cours de mission n'est PAS vu par un dispatch interne à cette même session — c'est le
   registre de `subagent_type` connus qui est figé au démarrage, pas l'allowlist `Agent(...)` du
   frontmatter (celle-ci n'est **pas appliquée à l'appel**, mesure du 2026-09-17,
   `team-kernel.md` §Marge de profondeur de dispatch : un worker a lancé des types absents de sa
   liste, qui ont démarré). Donc **aucune mesure « l'artefact est-il atteignable ? » n'est
   jouable depuis la session courante** — elle mesurerait le registre d'il y a une heure, pas
   l'allowlist.

2. **Le contournement spontané des workers est un process `claude` CLI frais**, du type
   `claude --agent <nom> -p "…" --permission-mode bypassPermissions --allowedTools Skill`.
   C'est techniquement juste (session neuve = registre relu) et c'est ce qui a produit la mesure
   valide `CONTROLE-NEGATIF: ECHEC` / `CAS-A: ATTEINT`. Mais `--permission-mode bypassPermissions`
   est une **élévation de posture de permission décidée par un worker**, hors du système de
   permissions de la session qui l'a dispatché — le harness la signale d'ailleurs à la remontée
   (`subagent output matched instruction-shaped pattern(s): bypass-permissions`).

**Why:** la mesure du spike était impossible autrement, et la doctrine
[[preuve-incapable-de-rendre-rouge]] exigeait un contrôle négatif capable de discriminer. Le worker
a eu raison sur la technique ; ce qui pose question est qu'il a choisi seul le drapeau, sans que le
mandat l'ait prévu ni que l'humain l'ait vu passer.

3. **`claude plugin uninstall` + `marketplace remove` NE VIDENT PAS le cache disque.** Les registres
   actifs (`~/.claude/plugins/config.json` : `known_marketplaces.json`, `installed_plugins.json`)
   sont bien purgés, mais `~/.claude/plugins/cache/<marketplace>/` survit avec l'arbre complet du
   plugin (`SKILL.md` inclus). Deux autres résidus survivent aussi : une entrée de compteur d'usage
   dans `~/.claude.json` (`"<plugin>:<skill>": {usageCount, lastUsedAt}`) et les transcripts de
   session sous `~/.claude/projects/<cwd-slugifié>/`. Un désinstall « réussi » (exit 0) ne prouve
   donc RIEN sur l'état du disque — seul `find ~/.claude -iname "*<motif>*"` le dit.

**How to apply:** dès qu'un plan demande de mesurer l'atteignabilité d'un agent/skill/plugin,
inscris le vecteur DANS le mandat — process CLI frais, et dis explicitement quel mode de permission
est autorisé. Ne laisse pas le worker improviser le drapeau : un `bypassPermissions` non prévu est
un contournement du choix de permission de l'utilisateur, à relayer à l'humain comme finding même
quand la mesure est bonne. Corollaire : ne jamais conclure « l'artefact n'est pas atteignable » à
partir d'un dispatch INTERNE échoué — c'est le registre figé qui parle, pas l'artefact.

Voir aussi [[joignabilite-asymetrique-manager-worker]] et
[[dispatches-via-skills-non-forkees]].
