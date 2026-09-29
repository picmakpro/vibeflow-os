---
quick_id: 260928-ccz
status: passed
date: 2026-09-28
---

# Verification — correction ciblée lot 3, Phase 44

Vérifiée par `gsd-verifier` (dispatché directement par vf-coder, agent enregistré au registre
`.planning/DRIVER.lock.children.jsonl`, rôle `gsd-verifier`, nœud `exec-44`).

## Vérification — quick 260928-ccz (lot 3, Phase 44, mode --validate)

Racine : racine du worktree de mission (`gouvernance/phase-44-moteur`).
Commits vérifiés : `dab3f62` (fix), `89270fa` (tests), `22381c1` (docs).

### Truths (PLAN.md must_haves.truths)

1. **Dédoublonnage sur valeur assainie des deux côtés** — COVERED. `recalc-planning.sh:1233-1235` :
   `chemin_jeton = _jeton_journal(chemin, "-")`, `couple_jeton = (_jeton_journal(verdict,"-"),
   _jeton_journal(tentative,"-"))`, comparaison `dernier_couple.get(chemin_jeton) != couple_jeton`
   — assainissement des deux côtés confirmé en lisant le code, pas seulement affirmé au SUMMARY.
2. **Test round-trip réel (2 exécutions, pas d'appel isolé)** — COVERED. `R-DEDOUBLONNAGE-ASSAINI`
   dans la sortie de suite : "deux exécutions réelles réussies (rc=0 chacune)", "une seule
   ligne… après le 2e recalcul", "cloture_ajouts=0 au 2e recalcul" ; `MUT-DEDOUBLONNAGE-BRUT` tué.
   Test exécuté réellement par le vérificateur (`bash test-recalc-planning.sh`), pas seulement lu.
3. **Refus « migration à examiner » indépendant de GSD_HOME** — COVERED. `detection_gsd()`
   l.405-406 : `_porte_planning_version(...) and _a_signal_de_code(racine_lab)` → `non-concluante`
   dans le repli code 1, avant `non-gsd`. `R-GSD-HOME-SIGNAL (a)` et `(b)` verts (code 3
   identique, empreinte inchangée), `MUT-CODE1-SOCLE-SIGNAL` tué.
4. **detect-gsd-engine.sh inchangé + aucune dépendance gsd-core** — COVERED.
   `git diff dab3f62~1..HEAD -- .../detect-gsd-engine.sh` vide ; `grep "gsd-core\|gsd-tools"
   recalc-planning.sh` vide.
5. **Cas légitimes (terrain libre, code 3, sans signal) continuent d'écrire** — COVERED.
   `R13 (a)/(b)/(c)` verts dans la suite exécutée (rc=3 attendus, rc=0 jumeau négatif correctement
   détecté par les mutants).
6. **modele-cycles.md aligné** — COVERED. Table des codes du détecteur (l.60-66) distingue
   explicitement le cas « code 1, aucun marqueur, socle+signal » (refusé, non-concluante) du cas
   « code 1, aucun marqueur, aucun signal » (autorisé, non-gsd).
7. **Aucune régression : 8 suites sœurs vertes et non modifiées, sonde PY39 verte bash+zsh,
   ≥180 OK** — COVERED. `bash test-recalc-planning.sh` → **180 OK / 0 KO** (exécuté par le
   vérificateur). 8 autres suites exécutées une à une, toutes 0 KO/FAIL (check-planning-state
   19/0, detect-gsd-engine 26/0, detect-planning-debt 10/0, planning-context-hardening 38/0,
   planning-core 14/0, planning-hooks 42/0, workstream-policy 22/0, workstream-symlink-escape
   10/0). `git diff HEAD~3..HEAD --stat -- .../tests/` ne montre que `test-recalc-planning.sh`.
   Sonde PY39 (reprise depuis `44-01-PLAN.md`) rejouée sous `/bin/bash` et `/bin/zsh` :
   `PY39-SYNTAXE-OK` (exit 0) dans les deux cas.

### Artefacts

- `recalc-planning.sh` : contient bien `motif-code-1-socle-et-signal` — COVERED.
- `test-recalc-planning.sh` : contient bien `R-GSD-HOME-SIGNAL` — COVERED.

### Hygiène

- Version : `plugin/planning-core/VERSION` = `v2.8.0` (inchangée) ; `bash
  scripts/check-version-sync.sh` → exit 0.
- Périmètre : `git diff HEAD~3..HEAD --stat` ne touche QUE les 4 fichiers déclarés
  (`recalc-planning.sh`, `test-recalc-planning.sh`, `modele-cycles.md`, `CHANGELOG.md`).
- CHANGELOG : paragraphe lot 3 présent sous l'entrée v2.8.0 (non publiée).

## Verdict global : **PASSED**

7/7 truths COVERED, 2/2 artefacts COVERED, aucun gap, aucune régression, périmètre respecté.
Aucun override nécessaire.
