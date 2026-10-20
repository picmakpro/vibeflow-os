---
phase: 58
plan: 11
status: complete
requirements: [RLPO-11, RLPO-12]
commits: [0fd710e2 (PRE-MUT-5), 41e65558 (manuel + outil), 22d60b1c (compte de suites)]
---

# 58-11 — porte de phase, manuel Poste, ledger (P58-D-14, P58-D-19, P58-D-20)

Arbitrages : P58-D-01..14, arbitrage Samuel, AskUserQuestion session principale, 2026-10-16 ; Q15 et Q17 : même canal, 2026-10-16.

- Étape 0 (correction ciblée de `revue-58c`) : `PRE-MUT-5` dans `test-resolve-preset-role.sh` (module caché `dev`, module visible `dev-x`) tue le mutant `grep -qxF` -> `grep -qF` : original = `p-devx` seul, mutant = `p-dev` et `p-devx` (85 octets), suite 22 OK / 0 KO.
- Manuel : H3 « Ton poste » / « Your role » (FR+EN), entrées de glossaire Poste et Statut / Role and Status ; `check-manual.sh` vert, `toc.yml` inchangé.
- Outil de livraison : liste de clients lue dans `VF_CLIENT_NAMES_FILE`, défaut dans le dossier de configuration de VibeFlow ; `resolve-preset.sh` sort de `is_forbidden` (témoins : liste avec `resolve-preset.sh` 0, avec `presets.json` 1).
- Compte de suites des README racine : 102 -> 109 (mesuré par la commande de la CI), `check-version-sync.sh` exit 0.

## Porte de phase

Rejouée sous `HOME` temporaire, `PYTHONUSERBASE` conservé, moteur gsd-core lié ; branche `feat/phase-58-roles-de-poste`.

| Commande | Code | Durée |
|---|---|---|
| `replay-ci-jobs.sh --job gates` (19 rejouées, 3 sautées, 0 échec ; `check-agents --strict` des trois étapes verts) | 0 | 22 s |
| `replay-ci-jobs.sh --job tests` (109 suites, 0 échec ; 5 étapes d'infra du runner sautées) | 0 | 3 440 s |
| `test-vibeflow-update.sh` (alarme 600 s) | 0 — 93 OK / 0 KO / 0 SKIP | 559 s |
| `VF_ROLE_E2E_LIVRAISON=1 test-roles-e2e.sh` (alarme 900 s) | 0 — 14 OK / 0 KO / 0 SKIP, `E2E-C2-AB` exécuté (472 fichiers) | 415 s |
| `lab-frais` (2 étapes lues dans `ci.yml`) | 0 | 4 s |
| `lab-frais-arme` (6 étapes lues dans `ci.yml`) | 0 | 15 s |
| `check-livraison-58.sh gitignore-intact` / `fichiers-intacts` (78 chemins) | 0 / 0 | < 1 s |
| `check-gate-touche.sh` / `check-baseline-arbitrage.sh` / `check-planning-consumers-registered.sh` | 0 / 0 / 0 | ~1 s |
| `check-ajout-retrait.sh --strict` | 1 — voir déviation | 1 s |

Déviation nommée : `--strict` signale `AJOUT-NON-COUVERT` pour `.claude/agent-memory/vf-dev-manager/feedback_orphelins-de-test-bloquent-les-juges.md`, une mémoire d'agent ajoutée hors de ce plan ; la CI joue ce gate en `--ci`, consultatif. Non corrigé ici (commit antérieur, hors périmètre).

## Critère 6

`check-livraison-58.sh clients` : code 2, « en attente de la liste » (fichier absent, mesuré). Jamais coché ; ce n'est pas un échec de phase (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16). Aucune liste créée, aucun nom lu ni inscrit. À rejouer quand Samuel dépose la liste : `diff=<n> chemins=<n> messages=<n>` attendu à zéro.

## Exigences

Cochées avec preuve verte (SUMMARY 58-01..58-12 et porte ci-dessus) : RLPO-01..10 et RLPO-12. RLPO-11 reste décochée : critères 1, 2 et 5 verts (58-09, porte), critère 6 seul en attente.

## Signalements

- Phase 48 du compartiment `gouvernance` : son module neuf demandera une décision `roles` (à signaler à Willy ; rien n'est écrit dans son compartiment).
- Les deux questions ouvertes de 58-07 sont closes (presets : 58-12, P58-D-21 ; manuel : tâche 1 de ce plan).
- Après le rebase sur main (geste du manager), recompter l'entrée de hook n°32 et le compte de suites sur la base mergée.
