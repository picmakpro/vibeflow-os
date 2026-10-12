---
name: porte-decisions-gsd-ids-prefixes
description: check.decision-coverage-plan de gsd-core rend could-not-parse sur les ids préfixés P57-D-NN (ADR-075) ; 41.4 et 45 étaient déjà dans ce cas ; rejouer sur un miroir P57-D-NN → D57-NN
metadata:
  type: project
---

La porte 13a de plan-phase (`gsd_run query check.decision-coverage-plan`) n'accepte que les puces `- **D[chiffres]-NN…**`. La convention du dépôt (CLAUDE.md, ADR-075) impose `P57-D-NN`, donc la porte rend `passed:false, reason: could-not-parse` sans rien juger. Mesuré le 2026-10-10 sur 57, 41.4 et 45 ; seule la 41.2 (ids nus) passait.

**Why:** une porte qui ne parse pas n'a rien vérifié. L'escalader à chaque phase ne sert à rien, et la considérer comme passée fabrique un vert.

**How to apply:** rejouer la porte amont, sans la modifier, sur une copie au scratchpad où `P57-D-NN` devient `D57-NN`, dans CONTEXT et dans les PLAN, avec `cd` dans le dossier (sinon « path escapes its allowed directory »). Exiger que le miroir soit rouge avant les plans. Recouper par un `comm` maison des ids, qui inclut la section Discretion, que la porte ignore. Le dire dans la PR. Voir [[liste-de-cas-ne-ferme-pas-une-classe]].
