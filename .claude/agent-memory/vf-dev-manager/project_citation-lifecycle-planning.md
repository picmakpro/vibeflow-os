---
name: citation-lifecycle-planning
description: Dans .planning/, la citation du chemin d'une spec migre puis disparaît avec le temps — « absent de ROADMAP.md » ne veut pas dire « non intégré »
metadata:
  type: project
---

Le chemin d'une spec/plan (`docs/superpowers/{specs,plans}/*.md`) n'est **pas** cité de façon
stable dans `.planning/ROADMAP.md`. Trois dérives observées, chacune vérifiée sur le corpus de
juillet 2026 (6 documents sur 8 mal classés par un test naïf) :

1. Le chemin canonique vit souvent dans `REQUIREMENTS.md` et **pas** dans le ROADMAP (cas de la
   spec d'ADR-055 : citée en `REQUIREMENTS.md`, le ROADMAP ne cite que son *plan*).
2. **L'archivage d'un jalon efface la citation** du ROADMAP vivant : la section détaillée est
   compactée en `Snapshots : ...`. Une spec devient donc « non intégrée » par le seul fait
   d'avoir été livrée. Survit dans `PROJECT.md` et `.planning/milestones/*-ROADMAP.md`.
3. Certains chantiers ont été livrés **hors chaîne GSD** (couple `dev-manager-team`, ADR-046) :
   cités uniquement dans `docs/ADR.md`, jamais dans un registre `.planning/`.

**Why:** un test « le chemin est-il dans ROADMAP.md ? » proposerait à la ré-ingestion 4 specs
déjà taggées et livrées — écriture en `--mode merge` dans un `.planning/` vivant, donc
duplication silencieuse d'étapes et d'exigences.

**How to apply:** toute question « ce document est-il déjà intégré ? » balaie l'ensemble
`{ROADMAP, REQUIREMENTS, MILESTONES, PROJECT, milestones/*}.md` **+** `docs/ADR.md`, jamais le
seul ROADMAP. Deux pièges de matching en prime : le stem d'un plan est **préfixe strict** du nom
de sa spec (`X.md` ⊂ `X-design.md` → borner à droite, extension incluse), et les lignes de
critères d'acceptation contiennent les globs `docs/superpowers/specs/*.md` — un match par
préfixe de dossier marque tout le corpus comme cité. Exclure `.planning/phases/**` : ce sont des
sorties du moteur, pas des entrées. Voir [[recette-test-module-lab-standard]].
