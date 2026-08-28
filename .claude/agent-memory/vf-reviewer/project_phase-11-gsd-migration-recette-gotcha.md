---
name: phase-11-gsd-migration-recette-gotcha
description: Les recettes grep « chemin littéral » des plans de la Phase 11 (migration gsd-sdk → gsd-tools) peuvent échouer sur le candidat CLAUDE_CONFIG_DIR de la cascade, sans que ce soit un vrai bug
metadata:
  type: project
---

Phase `11-integration-migration-gsd` (plans 11-01 à 11-06). Vague 11-06 (dernière du plan, revue
le 2026-07-26) a clos la phase proprement : triade VERSION/module.json/README/CHANGELOG alignée
sur les 3 modules touchés (dev-orchestrator v2.3.0, planning-core v2.5.2, conductor v1.14.2),
`check-version-sync.sh` entièrement vert, aucun bump racine (conforme au mandat hors-release),
`PROJECT.md` ligne 43 intacte / ligne 61 renommée comme prescrit. Voir aussi
[[project_index-regen-ephemeral-path]] (le défaut de provenance signalé y a été corrigé dans
cette même vague).
Plusieurs plans documentent une doctrine d'invocation `gsd-tools` en cascade de résolution de
chemin (D1 : jamais un chemin unique en dur), avec une recette de vérification du type
`grep -c '\.claude/gsd-core/bin/gsd-tools\.cjs"' <fichier> → ≥ 2`.

**Why:** repéré en revue du plan 11-02 (`mission-contracts.md`) : l'implémentation suit la
convention établie ailleurs dans le repo (`detect-gsd-engine.sh`, `build-gsd-index.sh`) —
`"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"`. Le `}` de fermeture du
paramètre shell s'intercale entre `.claude` et `/gsd-core`, donc le pattern littéral
`\.claude/gsd-core/bin/gsd-tools\.cjs"` ne matche qu'une seule fois (le chemin projet-local
`$_GSD_ROOT/.claude/...`), jamais le candidat `CLAUDE_CONFIG_DIR`. Résultat : la recette du plan
attend ≥2 et obtient 1, alors que la cascade est fonctionnellement correcte et conforme à la
convention du repo (confirmé par le snippet amont officiel `_runtime-launcher.snippet.sh`,
gsd-core 1.8.0, qui utilise le même motif `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`).

**How to apply:** en revue des plans 11-03 à 11-06 (ou de tout futur amendement de la doctrine
`mission-contracts.md`), si la recette grep littéral échoue sur ce pattern précis, ne pas conclure
au réflexe qu'il manque un chemin dans la cascade — vérifier d'abord si le candidat manquant passe
par `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (ou motif équivalent). Dans ce cas, la substance de D1 est
respectée ; c'est la recette du plan elle-même qui est mal calibrée pour ce style d'écriture — à
signaler en finding « majeur / ask-user » plutôt que « bloquant », et proposer au demandeur de
corriger la recette (ex. matcher séparément `CLAUDE_CONFIG_DIR.*gsd-core/bin` et le chemin
projet-local) plutôt que de forcer le code à une forme moins conventionnelle juste pour satisfaire
un grep littéral.
