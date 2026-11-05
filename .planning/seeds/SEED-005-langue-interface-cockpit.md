---
id: SEED-005
status: dormant
planted: 2026-11-05
planted_during: vibeflow-v2.0 (tri du BACKLOG, entrée « Choix de la langue de l'interface du cockpit » devenue graine)
trigger_when: "à la prochaine évolution de l'interface du cockpit, ou à la première demande d'un utilisateur anglophone"
scope: feature
source_spec: .planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md (P67-D-20) ; .planning/workstreams/fiabilite/phases/VFDO-70-finitions-ui-cockpit/70-CONTEXT.md (P70-D-03)
---

# SEED-005 : Choix de la langue de l'interface du cockpit (français / anglais)

Graine tirée du BACKLOG racine le 2026-11-05 : une fonctionnalité, pas un défaut. Arbitrage Samuel,
AskUserQuestion session principale, 2026-11-05 : « Transformer 28 et 29 ». L'entrée d'origine,
« Choix de la langue de l'interface du cockpit (français / anglais) — DIFFÉRÉ (2026-11-01) », est
archivée mot pour mot dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

## Origine

Phase 67, réponse E1 de Samuel (AskUserQuestion session principale, 2026-11-01), mot pour mot :
« on pourrait avoir des gens qui utilise l'anglais, donc en soit l'anglais n'est pas dérangeant et peut
etre un des langues autorisées » (`67-CONTEXT.md`, P67-D-20). L'interface du cockpit est en français par
défaut ; les textes du moteur (Santé, couverture de l'onglet Code) restent en anglais (CKPT-09 reformulé).

La Phase 70 l'a laissé ouvert exprès (P70-D-03, Q3-A) : elle ne nettoie que l'anglais résiduel en mode
français, et ne touche pas à `?lang=en`.

## À faire

- Un choix de langue (français / anglais) dans l'interface, gardé dans le navigateur ; l'anglais devient
  une langue autorisée et non plus un défaut à masquer.
- Point d'appui : le paramètre `?lang=en` existe déjà (`plugin/cockpit/skills/cockpit-moteur/assets/ui/80-vf-fr.js` :
  `?lang=en` désactive la traduction).
- Hors de ce choix, tant qu'il n'est pas arbitré : la traduction du panneau Santé et de la couverture
  de l'onglet Code.
