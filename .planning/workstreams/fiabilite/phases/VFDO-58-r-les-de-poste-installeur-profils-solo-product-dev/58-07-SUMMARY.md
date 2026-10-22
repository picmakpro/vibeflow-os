---
phase: 58
plan: 07
status: complete
requirements: [RLPO-06, RLPO-10]
---
# 58-07 — prose du poste : skill installeur, glossaire, README conductor (P58-D-02, P58-D-12, P58-D-18, P58-PL-04, P58-PL-13)

- `plugin/installer/SKILL.md` : étape `2 bis.` entre 2 et 3 (project/local seulement, `VF_ROLE` posé = aucune question, user = `solo`), propagation `--role` au catalogue et `VF_ROLE=` à l'engine, ligne « Changement de poste » (verbe `role`), refus de l'engine montré tel quel. Repli presets-vides conditionné au catalogue filtré ; amorçage de dev « jamais en poste product » ; note des bundles corrigée ; 3e colonne dite « statut ». 209 lignes ; frontmatter identique à la base (`cmp -s`), `BOOTSTRAP` 2610 inchangé ; `resolve-preset.sh` et `presets.json` non touchés.
- `test-build-module-catalog-role.sh` : 24 ok / 0 ko (bash courant et 3.2). SKILL-1 à SKILL-7 tenus ; SKILL-TEMOIN (copies sans `2 bis.` et à phrase périmée rougissent SKILL-1 et SKILL-4) et SKILL-TEMOIN-2 (SKILL-2, 3, 5, 6, 7 rougissent chacune sur sa copie altérée).
- `docs/_transverse/REFERENCE.md` : entrée « poste / rôle d'agent / statut » (source, ADR-077). `plugin/conductor/README.md` : puce SessionStart, `check-role-consistency.sh`, `vf-role.sh`, paragraphe « Poste (Phase 58) » (`vf_roles` édité à la main), titre `Scripts (38)` re-dérivé (+2) ; ligne `**Version**` non touchée.
- Résultats : `check-skills.sh --skills-dir=plugin` rc 0, aucun warning sur l'installeur ; `check-machine-paths.sh` vert.

## Questions ouvertes (pour le manager)
- Filtre des presets par poste (`resolve-preset.sh list`) : reporté (P58-PL-04), en attente de Samuel (Q16).
- Manuel FR+EN (`manual/**`) : hors plan (P58-PL-12), décision à prendre avec Samuel.
