---
phase: 58
plan: 12
status: complete
requirements: [RLPO-06]
---

# 58-12 — presets filtrés par poste (P58-D-21)

P58-D-21 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-20.

- `resolve-preset.sh list [--role <poste>]` (ou `VF_ROLE`, le drapeau l'emporte) : avec `product` ou `dev`, un preset est retiré dès que sa fermeture (`resolve-deps.sh`) contient un module que `module-roles.sh` déclare invisible. Prédicat et fermeture appelés, jamais recopiés ; résolution nommée inchangée. Commits `5dc9b6cc` (script, copie gelée, tracer) et `aae56c48` (suite complète, skill).
- Écart au plan : la liste filtrée est accumulée puis émise d'un bloc (PRE-FERMETURE a révélé une liste partielle sur stdout avant l'erreur nommant le preset).
- Dépôt réel, poste `product` : `comm -23` = `dev`, `dev-mobile`, `dev-audite` retirés (3 sur 3, tous racinés sur `dev-orchestrator`, `roles: ["dev"]`) ; liste vide, rc 0.
- Suite `test-resolve-preset-role.sh` : 21 OK / 0 KO, bash courant et `/bin/bash` 3.2 ; `test-resolve-preset.sh` 15/15 inchangée.
- PRE-INTEGRITE : empreinte `cksum` + sha256 épinglée dans la suite (la CI ne clone pas l'historique) ; en plus, identité à l'objet `a2ed5094` quand il est lisible (vert ici, pas de SKIP) ; témoin d'un octet altéré rouge.
- Mutants tués : PRE-MUT-1 filtre neutralisé, -2 filtre inversé, -3 `solo` filtré comme `product`, -4 priorité inversée.
- Skill installeur : 209 lignes avant et après ; `check-instruction-budget.sh` rc 0, baseline intacte.
- Attendu rouge jusqu'à 58-11 : `tools/check-livraison-58.sh` (`fichiers-intacts` : `resolve-preset.sh` encore dans sa liste) et `check-version-sync.sh` (compte de suites). `E2E-C2-AB` reste SKIP (non armé).
