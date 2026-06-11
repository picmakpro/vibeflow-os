---
description: Met en place ou tient à jour le socle de planning et de documentation du lab (.planning/), adapté à son métier. Réponds aussi à « où en est-on ? ».
argument-hint: "[optionnel : mets en place le planning / où en est-on / rafraîchis l'état]"
---

Invoque le skill **`vf-planning`** (socle de planning & documentation universel) : $ARGUMENTS

Le skill lit le métier du lab, choisit un profil de rigueur (léger/standard/complet), et pose ou
maintient le tronc commun `.planning/` (PROJECT, STATE ★ clé de voûte, ROADMAP, etc.), adapté au
métier — jamais une forme dev imposée. En maintenance, il rafraîchit `STATE.md` et trace les étapes.

Si le module `planning-core` n'est pas installé, lance d'abord `vibeflow-install`.
