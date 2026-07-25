---
name: vf-dev
description: >
  Utiliser **en dernier recours**, quand la demande de dev ne désigne aucun geste précis —
  « aide-moi à avancer », « pilote-moi ça », « je sais pas quel geste il faut », « fais ce
  qu'il faut », « occupe-toi de ce projet », « démêle cette histoire ». Point d'entrée
  générique : analyse l'intention, puis délègue au verbe qui la porte réellement.
  ✘ pas quand le geste est identifiable — passer directement par le verbe : /vf-plan,
  /vf-execute, /vf-debug, /vf-test… · ✘ pas pour enchaîner tout le reste sans supervision →
  /vf-auto · ✘ pas pour un simple point d'avancement → /vf-progress.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-dev — Point d'entrée générique

Analyse l'intention de la demande, puis **délègue à l'agent `vibeflow-dev`** (qui porte la table
de routage canonique) ou directement au verbe `/vf-*` adéquat. Aiguillage par famille :

- **Amont & cadrage** — idée déjà formulée à concevoir → `/vf-brainstorm` ; idée encore floue à
  débroussailler → `/vf-explore` ; question technique à trancher par du code jetable →
  `/vf-spike` ; figer le QUOI → `/vf-spec` ; trancher entre options → `/vf-decide` ; cadrer et
  découper le travail → `/vf-plan` ; démarrer le projet → `/vf-init`.
- **Construction** — feature structurante → `/vf-execute` (ou `/vf-quick` si trivial) ; tout
  enchaîner sans supervision → `/vf-auto` ; livrer / PR → `/vf-ship`.
- **Qualité & audits** — recette → `/vf-test` ; écrire les tests manquants → `/vf-testgen` ;
  relire un diff → `/vf-review` ; dette et recettes en souffrance → `/vf-gaps` ; failles →
  `/vf-secure` ; ça plante → `/vf-debug` ; post-mortem de cycle → `/vf-forensics` ; issues et PR
  entrantes → `/vf-inbox`.
- **Cycle de vie projet** — jalons → `/vf-milestone` ; éditer la feuille de route → `/vf-phase` ;
  revenir en arrière → `/vf-undo` ; idées en attente → `/vf-backlog` ; ménage → `/vf-cleanup`.
- **Contexte & session** — où on en est → `/vf-progress` ; recharger une session → `/vf-resume` ;
  s'arrêter proprement → `/vf-pause` ; comprendre le code → `/vf-map` ; doc du projet →
  `/vf-docs` ; décisions et enseignements → `/vf-learn`.
- **Design** — DA, UI, « c'est moche », refonte visuelle → `/vf-design` ; maquette jetable →
  `/vf-sketch`.
- **Mission multi-étapes** (plusieurs étapes, la nuit, étages combinés) → proposer l'équipe,
  puis `Task(vf-dev-manager)`.

Intention hors dev : conformité du lab / ses agents → `/vf-audit` ; socle de planning du lab →
`/vf-planning`. Aucun verbe ne colle ? L'agent `vibeflow-dev` consulte la doctrine exhaustive
(`intent-routing.md`, chargée on-demand) et délègue depuis là — jamais d'appel direct « en
passant » (`rules/vf-verb-precedence.md`).

**Ne réimplémente jamais** la logique d'un outil : route et délègue.
**Reframe toute sortie en vocabulaire VibeFlow** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni Superpowers.
