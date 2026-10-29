# Phase 62: Décision sur l'approche plateforme, sur preuve - Context

**Gathered:** 2026-10-29
**Status:** Décidée — option A (2026-10-29)

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F), **sans humain joignable** : mandat Samuel,
/vf-auto session principale, 2026-10-29. La phase **prépare** la décision ; elle ne la prend pas. La
décision elle-même est un geste humain (ROADMAP 62 : « une décision écrite […] prise sur mesure »).

**Exigences :** famille `PLTF`, réservée le 2026-10-08, vérifiée libre le 2026-10-29 (`git grep 'PLTF-'`
rc=1 sur la branche et sur `main`, `git log --all -S'PLTF-'` vide). Deux exigences au plus :
le dossier de décision (cochable par cette phase) et la décision signée par Samuel (décochée tant
qu'elle n'est pas prise).

<domain>
## Phase Boundary

Un **dossier de décision** sur l'approche C de la spec (plateforme collaborative : hub, base centrale,
non-devs sans terminal), qui rassemble les mesures disponibles, pose les options et propose un
déclencheur daté de reprise. **Aucun code** (ROADMAP 62, hors périmètre : « toute implémentation de
plateforme »). Phase de documentation : aucune release (ADR-073).

</domain>

<decisions>
## Implementation Decisions

- **P62-D-01 (forme).** Source : précédent `27-DECISION-claude-orchestration.md` (Phase 27, archivé sous
  `.planning/milestones/agentique-v1.0-phases/VFDO-27-*`) : bandeau de statut, table de verdicts, critères
  écrits **avant** les observations, provenance, observations brutes, verdict proposé, déclencheur
  objectif de reprise, « ce que ce document ne fait pas », références. Statut du bandeau :
  **PROPOSÉ — en attente d'arbitrage de Samuel**, jamais « décidé ».
- **P62-D-02 (critères, écrits avant).** Source : spec §4 C (déclencheur : « au moins un lab réel avec
  deux humains de rôles différents a tourné trois semaines sur B, et le besoin non-dev est documenté ») ;
  spec §7 Q-05/Q-06 ; §10 (« le besoin non-dev est une projection » → « Q-06 tranchée sur mesure avant
  toute approche C »). Ces deux conditions sont les critères ; le dossier constate leur état.
- **P62-D-03 (mesures à rassembler, sans en fabriquer).** Source : éclaireur du 2026-10-29. Q-06 n'a
  jamais été mesuré dans le dépôt ; la preuve à deux humains de la Phase 61 n'a pas eu lieu (bloqueurs
  P61-B-01/02) ; `vibeflow-hub-v3-docs` existe hors dépôt (documentation fondatrice, 2 commits, dernier
  le 2026-07-25, aucun code) ; aucune issue ouverte ne porte le besoin. Le dossier cite chaque mesure avec
  sa commande et sa date ; une mesure absente est écrite « non mesuré », jamais déduite.
- **P62-D-04 (options).** Source : ROADMAP 62 (« À défaut de preuve, le jalon se clôt sur un déclencheur
  daté de reprise ») ; spec §4 C (« C différé avec un déclencheur explicite »). Options posées : (A) différer
  C avec déclencheur daté (option par défaut écrite dans la ROADMAP quand la preuve manque) ; (B) ouvrir
  une mesure ciblée du besoin non-dev (protocole, sans code) ; (C) cadrer C maintenant. Le dossier
  **recommande** (A) si les critères ne sont pas remplis, motif en une ligne, et laisse le choix à Samuel.
- **P62-D-05 (déclencheur proposé).** Une condition objective (les deux critères de P62-D-02 remplis :
  compte rendu de recette Phase 61 déposé + besoin non-dev documenté) **et** un plancher de date de
  réexamen proposé par le dossier, que Samuel confirme ou corrige. Le dossier n'arme aucune veille
  automatique.

### Bloqueur humain
- **P62-B-01 — LEVÉ le 2026-10-29.** La décision elle-même (choix A/B/C et date du déclencheur) : décision déléguée par Samuel, message session principale, 2026-10-29 : « décide pour moi les options A, B ou C. Choisis la meilleure option selon une étude de toi-même » ; option retenue par la session principale. Option A, approche C différée, plancher de réexamen 2027-01-31 ; voir `62-DECISION-plateforme.md` § Décision.

</decisions>

<canonical_refs>
## Canonical References

- `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` — §4 C, §7 Q-05/Q-06, §8 Phase E, §10
- `.planning/workstreams/fiabilite/ROADMAP.md` — Phase 62
- `.planning/milestones/agentique-v1.0-phases/VFDO-27-*/27-DECISION-claude-orchestration.md` — forme
- Phase 61 : `61-CONTEXT.md` (P61-B-01, P61-B-02) et sa procédure de recette

</canonical_refs>
