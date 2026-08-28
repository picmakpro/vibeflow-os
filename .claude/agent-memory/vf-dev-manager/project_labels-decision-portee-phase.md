---
name: labels-decision-portee-phase
description: Les identifiants de décision `D-NN` sont propres à une PHASE, pas globaux — une « collision » entre phases est la convention, pas un défaut
metadata:
  type: project
---

Les labels `D-NN` (décisions de cadrage) sont **propres au registre de leur phase**
(`.planning/phases/VFDO-NN-*/NN-CONTEXT.md`), **jamais globaux au dépôt**. Le même `D-14` désigne
légitimement une décision en Phase 20, une autre en Phase 22, une autre en Phase 23.

**Convention de citation, déjà établie et mesurée** : quand un document cite un `D-NN` **hors de sa
phase**, il le **qualifie** — `docs/ADR.md:1068` écrit « (D-14, plan 20-02) », et
`23-CONTEXT.md:164` écrit « D-14 de la Phase 22 ». Un `D-NN` nu se lit dans le registre de la phase
courante.

**Why:** en Phase 23, une revue en régime plein a signalé en **majeur** une « collision
d'identifiants » entre le `D-14` introduit par l'étape et le `D-14` d'ADR-060 — et j'ai prescrit un
renommage vers `D-16/17/18` après avoir vérifié qu'ils étaient « libres »… en ne balayant que deux
fichiers. **`D-16`, `D-17` et `D-18` étaient déjà des décisions de la Phase 23 elle-même**
(extension d'ADR-061, gate `check-gsd-config.sh`, suppression des blocs `gates`/`safety`), dont deux
référencées par des fichiers gelés. Le renommage aurait **corrompu le registre de cadrage** et créé
des collisions pires que celle qu'il prétendait fermer. C'est le worker qui a refusé le geste et
escaladé `human_needed` qui l'a évité.

**How to apply:** avant de déclarer une collision de `D-NN` — ou d'accepter celle d'un juge —
**mesurer le registre `NN-CONTEXT.md` de la phase concernée**, pas seulement les fichiers où le
label apparaît. Un label « libre » ne l'est que si le registre de phase le dit. Le défaut réel, quand
il existe, est **l'absence de qualificatif** sur une citation inter-phase — le geste est d'ajouter
« , Phase NN », jamais de renuméroter. Même famille que la réutilisation assumée du label `D-09`,
qu'une revue avait correctement classée `no-op` : plusieurs juges de cette phase ont su distinguer la
convention du défaut, et deux ne l'ont pas su.

Voir aussi [[re-mesurer-la-premisse-d-un-arbitrage]], [[verifier-contre-le-commit-de-base]] et
[[grep-proxifie-tronque]] (un balayage tronqué fabrique exactement ce faux « libre »).
