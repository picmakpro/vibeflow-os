---
name: vf-dev
description: "Utiliser quand la demande de dev ne désigne aucun geste précis — « aide-moi à avancer », « pilote-moi ça », « fais ce qu'il faut », « occupe-toi de ce projet », « démêle cette histoire ». Incarne l'agent vibeflow-head, qui détecte l'intention, gouverne et lance l'équipe (vf-dev-manager, vf-coder) qui porte le geste. Invocable par l'utilisateur ET par l'agent en autonomie."
---

# vf-dev — Point d'entrée générique

Incarne (ou dispatche via Task) l'agent **`vibeflow-head`** : c'est lui qui porte la carte
d'intention canonique (`dev-orchestrator-references/intent-routing.md`), détecte le geste que
la demande appelle, **gouverne et lance l'équipe** qui le porte (`Task(vf-coder)` pour une tâche
courte, `Task(vf-dev-manager)` au-delà — jamais un skill `gsd-*` en direct, A1) et propose le
next step.

Aucune table ici — **une seule source de routage**, celle de l'agent
(spec : `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`).

L'agent incarné porte aussi la règle d'échelle et la gouvernance de sortie, définies dans
`dev-orchestrator-references/head-governance.md` §1 et §3.
