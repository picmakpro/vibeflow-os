---
description: "Lance l'audit de conformité complet du lab (densité agents, dette mémoire, infrastructure, architecture des process) via l'agent vibeflow-validator."
argument-hint: "[optionnel : focus de l'audit]"
---

Tu dois déléguer à l'agent **`vibeflow-validator`** (auditeur de conformité méthodologique, 5 phases).

Focus éventuel : $ARGUMENTS

Lance l'agent `vibeflow-validator` via l'outil Task. Il orchestre les 5 audits (infrastructure,
densité agents ADR-029, dette documentaire + mémoire, architecture d'audit des process P8/ADR-036,
synthèse) et produit un rapport `reports/validator/YYYY-MM-DD-validator.md` avec score et
recommandations. **Il détecte et propose, il ne corrige jamais sans validation humaine** (ADR-031).

Si l'agent `vibeflow-validator` n'est pas installé dans ce lab, lance d'abord `vibeflow-install`
(ou indique `/vibeflow-install`) pour installer le module `validator`.
