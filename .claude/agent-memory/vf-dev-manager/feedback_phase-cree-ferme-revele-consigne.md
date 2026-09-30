---
name: phase-cree-ferme-revele-consigne
description: Arbitrer « élargir ou consigner » un défaut trouvé en exécution — si la phase a créé l'incohérence elle la ferme, si elle l'a seulement révélée elle la consigne
metadata:
  type: feedback
---

Un défaut découvert pendant l'exécution d'une phase : **si la phase a CRÉÉ l'incohérence, elle la
ferme ; si elle l'a seulement RÉVÉLÉE, elle la consigne** (BACKLOG).

**Why:** la consigne « ne pas élargir le périmètre » (qui est réelle — élargir une phase déjà
longue est le plus sûr moyen d'y introduire un défaut neuf) ne couvre QUE les défauts
**pré-existants**. Je l'ai appliquée à tort, le 2026-09-23, à un cas où le plan 41.1-09 venait
d'ajouter le code de sortie `3` au contrat de `check-state-integrity.sh` en laissant, **dans la
même suite et par le même plan**, un cas 23 affirmant « aucun code hors {0, 1, 2, 64} ». Deux
vérités sur le même contrat, dans le même fichier. Arbitrage de la session principale : « laisser
ça, ce n'est pas se retenir d'élargir — c'est livrer la phase à moitié ».

**How to apply:** à chaque finding d'exécution, poser une seule question — cette incohérence
existait-elle avant que la phase touche le fichier ? Si non → fermeture obligatoire, même hors du
`files_modified` du plan courant, même si un plan déjà clos « possédait » le fichier. Si oui →
consigne, et ne pas élargir. Le fail-open général de `check-state-integrity.sh` et la contradiction
entre `check-divergence.sh` et la primitive sur le cas « `workstreams` en fichier régulier » sont
du second type (révélés) : consignés à raison. Corollaire pour les mandats de worker : une consigne
« ne rien changer d'autre que le cas X » est juste pour les cas pré-existants, mais elle empêche un
worker de fermer une incohérence que son propre plan vient de créer — le worker a raison de la
remonter plutôt que de corriger en vol, et c'est au manager de trancher avec cette règle.

Voir aussi [[feedback_cas-vert-des-deux-cotes-ne-garde-rien]].
