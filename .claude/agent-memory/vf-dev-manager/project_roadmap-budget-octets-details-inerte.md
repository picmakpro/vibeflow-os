---
name: roadmap-budget-octets-details-inerte
description: Le budget ROADMAP de check-method-budget mesure des octets bruts ; replier en <details> ne fait rien gagner, seul l'archivage (bloqué par les dossiers de phase) réduit
metadata:
  type: project
---

Le budget ROADMAP (`VF_ROADMAP_BUDGET_KB`, 64 Ko) compte les octets bruts du fichier : un bloc `<details>` pèse autant
qu'un bloc déplié. Mesuré le 2026-10-12 sur `.planning/workstreams/fiabilite/ROADMAP.md` (170 Ko) : le seul jalon livré
(`fiabilite-v1.0`, 107 Ko) était DÉJÀ replié ; le reste pèse 63 Ko. Un ordre « replie les jalons livrés » y est un no-op.

**Why:** le message du script dit « replier (<details>) puis --archive roadmap » ; la première moitié seule ne bouge pas
le chiffre, et `--archive roadmap` refuse tout bloc dont les dossiers de phase existent (garde S4(a), PR #138).

**How to apply:** avant de dispatcher un repli, mesurer `wc -c` par section. Leviers réels : archiver les dossiers de
phase puis `--archive roadmap`, ou garder les en-têtes `### Phase N` et archiver les corps (marge ~600 octets mesurée),
ou lever le budget — tous trois sont des choix à soumettre à Samuel. Lié : [[archive-roadmap-casse-check-divergence]].
