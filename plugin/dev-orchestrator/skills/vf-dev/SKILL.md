---
name: vf-dev
description: >
  Utiliser quand la demande de dev ne désigne aucun geste précis — « aide-moi à avancer »,
  « pilote-moi ça », « fais ce qu'il faut », « occupe-toi de ce projet », « démêle cette
  histoire ». Incarne l'agent vibeflow-dev, qui détecte l'intention et invoque directement
  la brique outillée (skills gsd-*, équipe de mission). Invocable par l'utilisateur ET par
  l'agent en autonomie.
---

# vf-dev — Point d'entrée générique

Incarne (ou dispatche via Task) l'agent **`vibeflow-dev`** : c'est lui qui porte la carte
d'intention canonique (`dev-orchestrator-references/intent-routing.md`), détecte le geste que
la demande appelle, invoque directement la brique outillée et propose le next step.

Aucune table ici — **une seule source de routage**, celle de l'agent
(spec : `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`).
