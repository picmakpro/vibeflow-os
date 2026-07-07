# Changelog — audit-architecture

## [v1.0.1] — 2026-07-07 (consolidation)

### Modifié
- `references/examples-cross-domain.md` (Instance C) : ne **re-spécifie** plus les mécaniques des
  autres modules (≤300L, check-file-size, tests, review, infra) — elle les **nomme et renvoie** au
  module propriétaire (`software-architecture`, `infrastructure-audit`). Le cadrage pédagogique
  porte/filet/agent/caméra est conservé. Supprime la duplication de contenu (audit CONS-02).
- `module.json` : description legacy erronée (« Audit d'architecture logicielle d'un codebase »)
  corrigée → méta-skill universel concepteur d'architectures d'audit (ADR-036).
- Renvoi vers la source unique des axiomes transverses (`reference/` → `AXIOMES-ENFORCEMENT.md`).

## v1.0.0 — 2026-06-03

Initial release (ADR-036).

- `SKILL.md` : méta-skill *concepteur d'architecture d'audit*. Dérive depuis un brief la structure d'audit multi-couches d'un process, puis la force. Universel (contenu / dossier / code / vente). Spécialise P8 (Évaluer) au niveau process.
- `references/audit-layer-primitive.md` : le primitif de couche (5 attributs : dimension × auditeur indépendant × rubric × verdict bloquant × anti-boucle).
- `references/decomposition-method.md` : méthode 4 temps pour dériver les couches d'un process (raisonnement, pas script).
- `references/enforcement-spectrum.md` : spectre déterministe↔jugement (script / test / checklist / rubric LLM-judge) — résout « les scripts sont trop déterministes ».
- `references/rubric-design.md` : concevoir une rubric robuste (critères observables, seuils, exemples-étalon, anti-complaisance).
- `references/examples-cross-domain.md` : 3 instances complètes (carrousel ContentFlow / dossier / code porte-agent-caméra-filet comme cas particulier).
- Origine : recadrage utilisateur Session 050 — généraliser le système d'audit multi-couches du ContentFlow Lab à tout process.
- Injecté dans l'agent `vibeflow-validator` (champ `skills:`) → mode scan de lab (repérer les process sans structure d'audit).
