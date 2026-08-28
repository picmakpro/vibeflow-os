---
name: feedback-verifier-arbre-apres-mutation
description: Après tout test de mutation sur "copie jetable" (cp -R vers scratchpad + patch + test), TOUJOURS cmp le fichier réel contre `git show HEAD:<path>` avant de conclure — un cas observé où le fichier du dépôt réel a montré la mutation censée être isolée en scratchpad
metadata:
  type: feedback
---

Le 2026-08-06 (audit Phase 27 reprise, vf-auditer), un test de mutation standard — `cp -R` du
répertoire source vers le scratchpad, patch Python de la copie pour réintroduire une vulnérabilité
retirée, exécution de la suite de tests sur la copie — a été suivi d'un `git status` sur le dépôt réel
qui a montré `plugin/conductor/scripts/dag.sh` MODIFIÉ, avec EXACTEMENT le patch appliqué à la copie
scratchpad. Cause racine non identifiée avec certitude (hypothèses : clonefile/COW APFS mal isolé
entre volumes, scratchpad partiellement partagé avec une session antérieure — le dossier contenait
déjà des artefacts `mut1/mut2/mutants/` d'une tentative d'audit précédente sur le MÊME vecteur,
suggérant peut-être un chevauchement de working dir plutôt qu'un vrai bug filesystem). Aucun processus
résiduel trouvé (`ps aux` propre) au moment de l'investigation. `git checkout --` a restauré le fichier
sans perte (aucun commit entre-temps).

**Why :** la consigne existante ([[feedback-execute-dont-trust-green]]) dit déjà de « restaurer et
vérifier l'arbre » après manipulation destructive — cet incident est la preuve concrète que cette
étape n'est pas cosmétique : sans le `cmp <(git show HEAD:<path>) <path>` fait immédiatement après,
une vraie corruption du dépôt de travail serait passée inaperçue dans un rapport d'audit qui se
termine par « je n'ai rien modifié ».

**How to apply :** pour tout test de mutation sur ce poste (vibeflow-os ou tout autre repo partagé
avec des sessions concurrentes/scratchpad persistant) :
1. Nommer les répertoires jetables avec un suffixe unique à la session (pas un nom générique type
   `repo-copy` réutilisable entre tentatives) pour réduire le risque de collision avec des artefacts
   d'une tentative précédente laissés dans le même scratchpad.
2. Après RESTAURATION (`git checkout --` ou équivalent), ne jamais se contenter de `git status`
   silencieux — faire un `cmp <(git show HEAD:<path>) <path>` explicite sur CHAQUE fichier touché
   par le test de mutation, et le montrer dans le rapport comme preuve, pas seulement l'affirmer.
3. Si un scratchpad contient déjà des artefacts d'une tentative antérieure (dossiers `mut*`, backups,
   diffs) au démarrage d'un audit, le noter — c'est un signal que la session précédente a pu laisser
   un état incomplet, pas nécessairement anodin.
