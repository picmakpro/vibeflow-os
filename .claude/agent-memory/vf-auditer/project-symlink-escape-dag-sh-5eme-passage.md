---
name: project-symlink-escape-dag-sh-5eme-passage
description: RCE fermée (2026-08-06, audit Phase 27 reprise) — le candidat cwd-relatif de resolve_gsd_tools_cmd() a été RETIRÉ (pas ancré), fermeture vérifiée par exécution + régression T33 confirmée rouge sur réintroduction
metadata:
  type: project
---

**CLOS le 2026-08-06** — voir [[feedback-execute-dont-trust-green]] pour la méthode. Le 5ᵉ passage du
motif de confinement de chemin (`resolve_gsd_tools_cmd()` de `plugin/conductor/scripts/dag.sh`,
candidat `os.getcwd()/gsd-core/bin/gsd-tools.cjs` exécuté via `node` sans ancrage, trouvé 2026-08-05)
a été fermé par **retrait pur** du candidat (commit `4a532ec`), pas par un ancrage supplémentaire —
arbitrage Samuel documenté dans ADR-070 (`docs/ADR.md`). Une variante analogue (`_GSD_ROOT` dérivé de
`git rev-parse --show-toplevel || pwd` dans `plugin/dev-orchestrator/references/mission-contracts.md`
§Seuil de bascule) a aussi été retirée le même jour (commit `08ad030`).

**Vérifié par EXÉCUTION, pas par lecture** (2026-08-06) : PoC rejoué — `gsd-core/bin/gsd-tools.cjs`
planté au CWD, `dag.sh ready` invoqué avec PATH normal et sans résolution amont disponible → le
fichier planté n'est jamais exécuté, `stages` dégrade à `null`. Test de non-régression T33
(`plugin/conductor/scripts/tests/test-dag.sh:457-482`) confirmé comme un VRAI garde-fou comportemental
(pas un grep de source) : réintroduit le candidat retiré sur une copie jetable → T33.2/T33.3/T33.4
tournent rouges (3 FAIL, aucun autre test affecté), confirmant que la suite détecterait un 6ᵉ passage
identique. Recoupé indépendamment par délégation à `gsd-security-auditor` le même jour (verdict SECURED,
grep 0 occurrence cwd-derivation dans dag.sh, 0 dans le bloc code de mission-contracts.md).

**Dette résiduelle trouvée à cette occasion (toujours ouverte)** : trois documents de gouvernance
— `.planning/REQUIREMENTS.md` PAEX-11 (`[ ]` non coché, « NON TENU — finding CRITIQUE »),
`.planning/codebase/CONCERNS.md` (Update 2026-08-06 : « arbitrage humain gelé... non traité ici »),
et `docs/ADR.md` §ADR-070 « Ce que cette ADR ne tranche pas » — décrivent TOUS le vecteur CWD comme
non résolu / gelé, alors que le retrait a effectivement eu lieu dans le même diff (commits `4a532ec`
et `08ad030`, tous deux postérieurs à `0f5ba59` qui a écrit ces trois textes). Aucun des trois n'a
été mis à jour après le fix. Signalé comme finding (dette de traçabilité, pas un trou de sécurité)
à l'audit du 2026-08-06 — vérifier si comblé si un futur audit repasse ici.

**How to apply** : si un futur audit repasse sur `dag.sh` ou tout script qui résout un binaire/module
externe via un chemin dérivé du CWD, ce site précis est fermé — ne pas le re-signaler sans nouvelle
évidence de régression (repasser le PoC si doute). Voir aussi [[project-symlink-escape-gsd-scripts]]
(même famille, closed séparément).
