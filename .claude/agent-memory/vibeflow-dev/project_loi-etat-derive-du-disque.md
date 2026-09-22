---
name: loi-etat-derive-du-disque
description: Pourquoi le planning dev tient et le planning métier non — l'état dérivé du disque contre l'état déclaré en prose, mesuré sur gsd-core 1.14.0 et planning-core v2.7.0
metadata:
  type: project
---

**Le moteur GSD ne se contente pas d'écrire l'état à la place de l'agent : il refuse d'écrire un
état que les artefacts ne justifient pas.** Mesuré le 2026-09-22 dans le code de gsd-core 1.14.0 :
`phase.complete` renvoie `PHASE_PLAN_COVERAGE_INCOMPLETE` s'il manque un `SUMMARY.md` par plan, et
`PHASE_VERIFICATION_INCOMPLETE` sans `VERIFICATION: passed` ; `roadmap update-plan-progress` ne
coche pas la case avant vérification ; `state advance-plan` rend `STATE.md` **byte-identique**
plutôt que d'écrire un état dérivé d'un disque incohérent ; un `commits:` déclaré est réconcilié
avec `git rev-list` et devient un BLOCKER en cas d'écart. **L'état est dérivé du disque, jamais
déclaré** : la barre d'avancement est recalculée en comptant les SUMMARY présents.

**Why:** chaque gate cite son incident fondateur dans le code — un livrable entier perdu
silencieusement par une phase close avec des plans non exécutés, 14 plans déclarant `commits: 1`
avec zéro activité git. La discipline dev n'est pas uniforme : elle est verrouillée **exactement là
où un oubli ferait perdre du travail déjà fait**, et volontairement souple ailleurs (deux gates
d'entrée que la doctrine promet et que le code ne tient pas). C'est une architecture de gates
délibérée, pas de la rigueur tous azimuts — ne pas la présenter comme un modèle de verrouillage
total.

**En face, `planning-core` v2.7.0 est déclaratif de bout en bout.** Aucun script n'ouvre `phases/`,
ne compare PLAN ↔ SUMMARY, ne lit `progress` ni `status` ; le seul champ lu par une machine dans
tout le module est `last_updated:`. Cinq de ses six hooks sont câblés `|| true`. Le sixième,
`guard-planning-updated.sh` (Stop), bloque vraiment mais **mesure un `mtime`** : vérifié en
fixture, `touch .planning/STATE.md` ou `echo x > .planning/NOTES-BIDON.md` suffit à le satisfaire,
avec un `STATE.md` de 2020. Le module possède le script qui sait dire que le STATE est mort
(`check-planning-state.sh`, seuil 7 j) et le garde ne le consulte jamais.

**La cause première est écrite en commentaire** dans `check-planning-state.sh` : « Le wiring du
hook est DOCUMENTÉ, jamais auto-injecté dans settings.json. » Le mécanisme de survie est livré
**opt-in**. AVMA l'a branché (14 hooks SessionStart), BusinessFlow-Lab jamais — et y mesure 0
projet sur 21 avec un plan frais, zéro commit en septembre 2026, ses deux dossiers les plus actifs
(`partenariat-ey`, `wa-connector`) jamais versionnés.

**How to apply:** toute proposition de gouvernance documentaire se juge sur une seule question —
*de quel artefact sur disque la machine dérive-t-elle son verdict, et que refuse-t-elle ?* Une
règle qui ne se dérive de rien est de la prose, quel que soit le module qui la porte. Corollaire
retenu avec Willy le 2026-09-22 : la preuve métier sera **le livrable sur disque + un verdict de
juge scoré** (les juges existent déjà : `quality-gate-client`, `content-clarity-judge`,
`growth-quality-judge`), le git étant hors jeu côté métier.

Voir [[collision-planning-gouvernance]] et [[mecanismes-deterministes]].
