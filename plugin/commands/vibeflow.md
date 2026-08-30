---
description: "Point d'entrée VibeFlow — configurer, vérifier, mettre à jour ou migrer le lab via l'orchestrateur méta (vibeflow-conductor). Tape /vibeflow puis ta demande."
argument-hint: "[ce que tu veux faire — ex. crée un lab d'acquisition, vérifie le lab, mets à jour]"
---

Tu dois déléguer à l'agent **`vibeflow-conductor`** (orchestrateur méta et gardien du lab).

Demande de l'utilisateur : $ARGUMENTS

Lance l'agent `vibeflow-conductor` via l'outil Task en lui transmettant cette demande verbatim. Il
route vers la bonne action (créer un lab, installer/désinstaller un module, vérifier la conformité,
mettre à jour / migrer, traiter une escalade de cohérence) et délègue aux briques outillées. Il ne
fait jamais le travail métier — il configure et garde le lab.

Si la demande est vide, demande en une phrase ce que l'utilisateur veut faire (créer un lab, vérifier,
mettre à jour…) puis délègue.

**Garde-fou d'installation** : si l'agent `vibeflow-conductor` n'est pas disponible dans ce lab
(absent de `.claude/agents/`), c'est que les modules VibeFlow ne sont pas encore posés. Invoque
alors le skill `vibeflow-install` (ou indique à l'utilisateur de lancer `/vibeflow-install`) pour
installer le module `conductor`, puis relance la délégation.
