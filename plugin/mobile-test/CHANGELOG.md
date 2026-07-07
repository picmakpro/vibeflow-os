# Changelog — mobile-test

## v1.0.0 — 2026-07-07

Création du module. Pipeline de test mobile réel (iOS simulateur / Android émulateur),
extrait et généralisé depuis le track « équipe d'agents » (revizapp).

- **Script** `scripts/mobile-test-run.mjs` : sous-commandes `detect` et `run`. Détection de
  cible, build-if-absent (`expo run:` détaché + polling), régression Maestro, parsing JUnit,
  scaffolding du rapport, nettoyage des process démarrés.
- **Skill** `vf-mobile-test` : couche jugement (choix de cible, diagnostic visuel mobile-mcp,
  rédaction du rapport).
- **Config** `config/mobile-test.example.json` : template projet. Résolution en cascade
  (`--config` > `$VF_MOBILE_TEST_CONFIG` > `./.vibeflow/mobile-test.json` > `./mobile-test.json`).
- **Références** `references/portability-notes.md` : apprentissages durs de portabilité.

### Dé-spécification vs source revizapp

- Chemin de config `.agent/config/mobile-test.json` codé en dur → **résolution en cascade portable**.
- Défaut `reportsDir` `docs/_mission/test-runs` → `test-runs` (générique).
- Suppression des références au suffixe `.dev` trompeur et des noms de flows revizapp ; le
  bundle id réel est désormais `bundleIdBase + debugSuffix`, à **vérifier sur la cible**.
- Suppression de la section « parité `.agent/` » (hors périmètre VibeFlow) → renvoi vers
  `references/portability-notes.md`.

### Statut

Expérimental jusqu'au premier run réel vert dans un contexte VibeFlow.
