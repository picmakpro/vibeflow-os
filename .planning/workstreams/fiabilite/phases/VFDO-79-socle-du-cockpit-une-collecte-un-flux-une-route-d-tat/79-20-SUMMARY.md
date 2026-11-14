# 79-20 — SUMMARY : documentation et version du module cockpit (SOCL-25, P79-D-27)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Livré
- AVANT-20 `fc102a6a2` ; verdict de la sonde S0 : OUI ; `plugin/cockpit/hooks/hooks.json` : absent. Le journal des attentes n'est ni livré ni décrit (README et CHANGELOG, V12.5 le garde), le CHANGELOG dit en Limites qu'il n'y a pas de journal par hook.
- Gate de cohérence : aide `plugin/cockpit/scripts/tests/doc-chiffres.sh` (142 lignes, aucune ligne de plus de 160 colonnes, aucun `eval`, pas un `test-*.sh`) et section V12 de `test-cockpit-vendor.sh` : 33 assertions (V12.0a, 0b, 1a, 1b, 2a à 2h, 3a à 3c, 4, 5, 15 témoins sur copie mutée V12.6, V12.7). Aucune suite ajoutée.
- Version du module : v1.4.0 devient v1.5.0 (`VERSION`, `module.json`, en-tête du README, titre `## v1.5.0 — 2026-11-14 — non publié`) ; type « skill + scripts + moteur (fork de floorplan) ». `VERSION` racine, `plugin.json` et `marketplace.json` intacts, aucun tag, aucun push (ADR-073).
- README du module (389 à 436 lignes) : R1 à R16 appliqués (code jamais lu depuis la sortie avec la limite de la pose projet dans le même paragraphe, politique de contenu au préfixe `/_vf/` avec `worker-src`, section « Le socle », tableau des huit chiffres, `vf-signal` par la route d'état, § Code tiers sans appareil de patchs, limites du socle, phrase J1-D04 sur le second onglet).
- CHANGELOG : section v1.5.0, cinq titres `### … — Phase 79`, 16 retraits nommés, AUDC-Q2, Q4 et Q5 avec leur canal et leur date ; `module.json` : description complétée d'une phrase.
- Compteur des README racine : 244 avant, 244 après, 244 au gate : relu, non touché.

## Écarts
- Écart : `FENETRE_S` (nom du plan) est une réexportation ; l'extracteur lit l'affectation littérale `fenetreS` de `scripts/vf-cockpit-index-voie.mjs`.
- Écart : les témoins V12.6 mutent des documents synthétiques (mêmes extracteurs, sources réelles) et non le README réel, qui n'a pas de tableau sur la base ; V12.7 prouve la copie.
- Écart : baseline V12.4 : 10 lignes (non 11), l'en-tête ayant été corrigé à la tâche 1 avec le type.
- Écart : les cinq cas du corps `inconnu` suivent le SUMMARY de 79-22 (un identifiant mal formé reste un 400 `id-invalide`).
- Écart : le contrôle `<verify>` du plan, qui borne `AVANT-20..HEAD` à la liste fermée, n'a pas pu être rejoué à la lettre : la branche porte aussi les commits des autres nœuds (79-18, coquille, mise en page) ; mes commits ne touchent que `plugin/cockpit/{README.md,CHANGELOG.md,VERSION,module.json}`, `scripts/tests/{doc-chiffres.sh,test-cockpit-vendor.sh}` et la trace.
- Écart : trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` (ma configuration), le mandat commun cite Opus 5.5.

## Suites jouées (une fois, sur la tête commitée `1d251c716`, charge du poste variable)
| suite | verdict | durée |
|---|---|---|
| `test-cockpit-vendor.sh` | 286 PASS / 0 FAIL (V12 : 33) | 90 s |
| `test-vibeflow-update-cockpit.sh` | rc 0 | 40 s |
| `test-vibeflow-update-nouveaux-modules.sh` | rc 0 | 19 s |
| `test-cockpit-accessibilite.sh` | 37 PASS / 0 FAIL | 11 s |
| `test-cockpit-questions.sh` | 133 PASS / 0 FAIL | 21 s |
| `test-cockpit-robustesse.sh` | 25 PASS / 0 FAIL | 9 s |
| `test-cockpit-git-entete.sh` | 136 réussis, 0 échoué | 216 s |
| `test-cockpit-marque-blanche.sh` | 36 PASS / 0 FAIL | 8 s |
| `test-cockpit-reseau.sh` | 15 PASS / 0 FAIL | 7 s |
| `test-cockpit-coquille.sh` | 114 PASS / 0 FAIL | 221 s |
| `check-version-sync.sh`, `check-machine-paths.sh` | exit 0 | |
Un rejeu de la suite vendor avant celui-ci (V11.Q6b, V11.P5 rouges) portait la modification en cours du voisin 79-18 (`vf-cockpit-module.mjs` et copies jetables de V11) : vert une fois ce correctif posé. V4 (`chrome-coin.mjs` à 300 lignes) : vert sur cet arbre.

## Gates de la CI
Lus et rejoués : `check-version-sync`, `check-machine-paths`. Lus et écartés : `check-ajout-retrait` (aucun gate, aucune baseline, aucun fichier de leur surface : l'aide est une aide de test), `check-gate-touche` et `check-baseline-arbitrage` (même raison, aucun trailer dû), `check-instruction-budget` (aucun agent, skill ni règle touché), `check-affirmation-non-mesuree` (rejoué : avertissements qualifiés de `CLAUDE.md` et de `docs/ADR.md`, aucun de mes fichiers).

## À reprendre par le manager
- BACKLOG : renommage complet des pages et retrait de `vf-cockpit-rename.mjs` ; composition de l'export depuis le module ; schéma `@2` pour masquer les chemins absolus ; retrait de la forme transitoire d'identité d'un serveur (branche « ancienne » de `estNotre`, T-79-603) à la version suivante ; paquet de mise en page chargé deux fois (79-18-c).
- `plugin/cockpit/skills/vf-cockpit/SKILL.md` : la ligne du code 3 (« moteur absent ») est restée plus courte que celle du README (« ou module refusé ») ; un SKILL.md compte au budget d'instructions, non touché.
- `scripts/ci-shard-suites.sh` : entrées de durées des suites ajoutées par 79-16 à 79-19 (coquille ~100 s, magasin ~10 s, mise en page, etc.).
- Cochages ROADMAP, STATE et REQUIREMENTS (SOCL-25) : au manager.

## Retiré
README : « à rejouer à chaque synchro amont », les deux commandes de vérification et de resynchronisation, les renvois à des patchs numérotés, les mentions d'un « moteur vendorisé », le renvoi à la politique de contenu de la première version, l'affirmation sans limite que le lab n'est jamais source de code, les nombres en lettres. CHANGELOG : le titre `## Non publié` (renommé) et la phrase « aucun bump de version à ce stade ». `module.json` : le type « moteur vendorisé ».
