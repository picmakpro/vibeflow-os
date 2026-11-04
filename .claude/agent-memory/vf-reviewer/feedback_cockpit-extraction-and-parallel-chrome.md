---
name: cockpit-extraction-and-parallel-chrome
description: Rejouer les 21 suites du cockpit sur un git archive exige plugin/cockpit + conductor + planning-core ; ne jamais lancer ma sonde Chrome en meme temps que les suites (processus disparus)
metadata:
  type: feedback
---

Extraction figee pour rejouer `plugin/cockpit/scripts/tests/test-cockpit-*.sh` : `git archive <sha> plugin/cockpit plugin/conductor plugin/planning-core`. Avec cockpit seul, `test-cockpit-who.sh` W17 echoue (7 FAIL) : `driver-lock.sh` source `vf_ws_name_valid` depuis `plugin/planning-core/scripts/workstream-policy.sh`, donc aucun verrou de phase n'est pose.

**Why:** verif-fix-69-recette (Phase 69, e0680560) : W17.0 rouge (0 au lieu de 2), faux positif d'extraction, pas un defaut du diff. 83 PASS / 0 FAIL une fois planning-core ajoute.

**How to apply:** avant de conclure sur un FAIL de suite en extraction, verifier que les dependances sœurs (conductor, planning-core) sont dans l'archive. Ne pas lancer une sonde CDP perso pendant que des suites Chrome tournent : mes jobs perso (CPU) sont morts sans message (hygiene.sh des suites suspecte, non prouve). Lancer les sondes Chrome seules, apres les suites. `timeout` n'existe pas sous macOS : `perl -e 'alarm N; exec @ARGV'`. Suites lentes (securite, transcript, responsive : plusieurs minutes) : runner en arriere-plan, un log par suite, `rc=` final.

Lie : [[feedback_mutant-anchor-outside-measured-scope]] (W17.9 echoue sur l'ancre quand on mute la clause `!ws.includes('..')`, pas sur le comportement).
