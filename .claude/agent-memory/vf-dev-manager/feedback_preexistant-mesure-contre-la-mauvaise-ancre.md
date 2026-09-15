---
name: preexistant-mesure-contre-la-mauvaise-ancre
description: « Pré-existant » d'un worker se mesure contre SON point d'entrée, pas contre la base de la mission — un gate cassé par la vague 1 est rapporté comme dette héritée par la vague 4
metadata:
  type: feedback
---

Quand un worker qualifie un gate rouge de « pré-existant », exiger **contre quelle ancre** il l'a
mesuré. Un worker de fin de mission prend naturellement son propre SHA d'entrée — qui est déjà au
milieu de la mission. Re-mesurer soi-même contre le SHA de base de la MISSION.

**Why:** Phase 34, 2026-09-15. Le worker du ledger (34-06) a rapporté `check-machine-paths.sh` à
exit 1 et l'a déclaré « pré-existant, confirmé en rejouant le gate sur un worktree détaché à
l'ancre `34-06-BASE.sha` ». La démarche était rigoureuse — worktree détaché, gate rejoué, même
compte d'occurrences — et la conclusion était fausse : cette ancre était le commit de sortie de la
vague 3, pas la base de la phase. Rejoué au SHA de base réel de la mission, le gate rendait
**exit 0** (« 1339 fichiers balayés, aucun chemin absolu de machine »). Les 16 occurrences avaient
été introduites par les plans 34-01 et 34-02, c'est-à-dire par la mission elle-même. Sans re-mesure,
la PR partait rouge sur un gate du job CI `gates`, avec une dette faussement imputée au dépôt.

Le piège est structurel, pas individuel : chaque worker ne connaît que son propre point d'entrée.
Seul le manager détient le SHA de base de la mission — donc seul lui peut trancher « hérité » contre
« introduit par nous », et c'est un geste qu'aucun worker ne peut déléguer vers le haut.

**How to apply:**
1. Tout verdict de worker contenant « pré-existant », « déjà là », « hors de mon périmètre » est
   re-mesuré par le manager contre le SHA de base de la mission, en worktree détaché. C'est trois
   commandes.
2. Rejouer le gate *à la base* est ce qui tranche, pas relire le diff : un gate repo-wide balaie des
   fichiers que le diff ne montre pas.
3. Corollaire de dispatch : redonner au worker correcteur l'ancre de mission explicitement, sinon il
   reproduira la même erreur d'imputation.
4. Ne jamais laisser un gate cassé par la mission se convertir en « dette datée » au ledger : c'est
   une exemption déguisée en constat.

Voir [[verifier-contre-le-commit-de-base]] (même famille, autre vecteur), [[base-de-diff-derivee-du-parent]]
et [[liste-de-gates-jamais-la-reference]] (le job CI `gates` fait autorité, jamais une liste recopiée).
