---
quick_id: 261001-wtd
status: complete
date: 2026-10-02
commits:
  - a4afbe3f
---

# Quick 261001-wtd — résumé

| Finding | Correction | Rouge avant | Mutants tués |
|---|---|---|---|
| N-01 | repli : valeur trop longue qui nomme `.planning` ou `.claude` refusée, tout cwd ; cœur : chemin non analysable décidé dans le doute (nomme : refus, sinon cwd), jamais le code 3 | sonde r3 : PASS (ancien code) ; mutant COEUR-REVERT : rc=3 | DOUTE-GUARD-RETIRE, DOUTE-GUARD-CLAUDE, DOUTE-GUARD-CASSE, DOUTE-COEUR-REVERT, DOUTE-COEUR-NOMME, DOUTE-COEUR-CLAUDE, DOUTE-COEUR-ADHESION, DOUTE-COEUR-CWD |
| N-03 | `~` et `~/…` développés en HOME dans les deux couches ; `~utilisateur` dans le doute | ancien code : `~/lab/.planning/STATE.md` joint au cwd, PASS | DOUTE-TILDE-SHELL, DOUTE-TILDE-USER, DOUTE-COEUR-TILDE |
| N-05 | raison de G6 : contrainte de mise en forme du repli | mutant ADH-REPLI-RAISON : « changer ou retirer l'adhésion » | ADH-REPLI-RAISON |
| N-02, N-04, N-06 | limites (aa), (ab), (a), CHANGELOG, `poser-verdict.sh` | — | mots-clés des limites (a), (aa), (ab) dans R-REFERENCE |

Suites au premier plan : test-planning-gates 457 OK, test-planning-hook-registered 69 OK, test-rejeu-gates 91 OK, test-planning-hook-installed 23 OK, test-role-hook-vs-check-agents 6 OK, test-recalc-planning 358 OK, check-machine-paths vert, contrôle de marqueur sans-marqueur=0.

Zéro régression dev : la commande enregistrée hors lab adhérent, six outils, script présent et absent : rc=0, 0 octet en stdout et en stderr.

Rejeu réel (lecture seule) : 0 faux refus, 0 faux accept, empreintes identiques ; section « Rejeu post-re-audit » de `45-REJEU-FINAL.md`.
