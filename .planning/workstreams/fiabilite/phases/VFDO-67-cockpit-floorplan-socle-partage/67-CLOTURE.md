# 67 — Clôture de la Phase 67 (Cockpit floorplan sur socle partagé)

Clôturée le 2026-11-03, compartiment `fiabilite`, jalon `vibeflow-v2.0`. Décision : « Clore la 67 + release minor » (arbitrage Samuel,
AskUserQuestion session principale, 2026-11-02). Recette humaine validée : « Ouais, parfait. » (saisie texte, session principale,
2026-11-03, `67-RECETTE-HUMAINE.md` § 8.2). Mise à jour à la main de ROADMAP, REQUIREMENTS et STATE (aucune commande `state.*`).

Preuve rejouée à la clôture sur `bcd2e55a` : les 17 suites `plugin/cockpit/scripts/tests/test-cockpit-*.sh`, plus
`plugin/conductor/scripts/tests/test-dag-atomic-save.sh` et `plugin/_internal/tests/test-vibeflow-update-cockpit.sh`, une par une :
19 sur 19 vertes, exit 0 (assemblage 40, chaine-xss 22, chrome-fr 26, direct 75, marque-blanche 22, onglet-code 18, projet 35, questions 51, reconnexion 10, réseau 14, responsive 186, robustesse 25, sécurité 88, serveur 54, vendor 75, who 68, dag-atomic-save 6, update-cockpit 11 ok ; hygiène exit 0 sans décompte) ; `bash scripts/check-machine-paths.sh` ✓. Revue (`67-REVIEW.md`, `revue-p3b` passed) et audit (`67-SECURITY.md`, B1 et B2 fermés par `c5868a5d`) : verdicts
du 2026-11-01 et du 2026-11-03, correctifs rejoués ci-dessous.

| Exigence | Statut | Preuve (suite : cas, ou fichier) | Commit |
|----------|--------|----------------------------------|--------|
| CKPT-01 | livrée, prouvée | `test-cockpit-who.sh` (W1-W4 : collecteur, graphe, validateur du contrat) ; `test-cockpit-projet.sh` ; `67-02-SUMMARY.md` | `f40ce17c`, `7420670d`, `78eeee91` |
| CKPT-02 | livrée, prouvée | `test-cockpit-vendor.sh` (V1 licence, V2 licences tierces, V4 marqueurs, V6 amont à l'octet, V7 patchs) ; `67-03-SUMMARY.md` | `e2b2eae6`, `cf7372eb`, `7ac4805d` |
| CKPT-03 | livrée, prouvée | `test-cockpit-reseau.sh` (R1 sonde sortante, R2 liste blanche d'URL, R3 un seul port) ; `test-cockpit-assemblage.sh` ; `test-cockpit-vendor.sh` | `6fd4ec61`, `0842de46`, `c7b105da` |
| CKPT-04 | livrée, prouvée | `test-cockpit-marque-blanche.sh` (rouge si « Floorplan » réapparaît hors licence) ; `67-REVIEW.md` (grep insensible à la casse : 1 occurrence, la licence) | `e2b2eae6`, `cf7372eb`, `7ac4805d` |
| CKPT-05 | livrée, prouvée | `test-cockpit-direct.sh` (D1-D5, SSE sans CORS, repli poll) ; `test-cockpit-serveur.sh` (S1 jetons, S2 Host) ; `test-cockpit-reconnexion.sh` | `6fd4ec61`, `0842de46`, `45dfb75f` |
| CKPT-06 | livrée, prouvée | `test-cockpit-projet.sh` (lab plat et partitionné) ; `test-cockpit-onglet-code.sh` (extracteur VibeFlow ou scan brut) | `78eeee91`, `5a09548d`, `233c05ad`, `54b2d0fa` |
| CKPT-07 | livrée, prouvée | `test-cockpit-questions.sh` (formes locales, modèle) ; `test-cockpit-robustesse.sh` ; `test-cockpit-securite.sh` (agent confiné) ; `67-SECURITY.md` | `5a09548d`, `233c05ad`, `324986c2` |
| CKPT-08 | livrée, prouvée | `test-cockpit-serveur.sh` (S5 flux, S7 fichiers générés, S8 export, avec témoin positif) | `0842de46`, `c7b105da`, `8a72c600` |
| CKPT-09 | livrée, prouvée | `test-cockpit-chrome-fr.sh` (F2 : chaînes non traduites = vide, mutant rouge) ; `67-07-SUMMARY.md` ; texte de l'exigence reformulé sur la réponse E1 de Samuel | `e3e86895`, `bae638a6` |
| CKPT-10 | livrée, prouvée | `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` (pose par l'engine, binaires, `.gitignore`) ; `67-06-SUMMARY.md` | `7f5f5421`, `ebc63e98` |
| CKPT-11 | livrée, prouvée | `plugin/conductor/scripts/tests/test-dag-atomic-save.sh` (A1 aucune lecture tronquée, A3 mode conservé, témoin rouge sur l'ancien `save()`) ; `67-01-SUMMARY.md` | `0ac4e7f1`, `5d535143`, `3c30769b` |
| CKPT-12 | livrée, prouvée | `test-cockpit-responsive.sh` (R1/R2 boîtes à 1 024, 1 280, 1 440, 1 920 px ; R4 témoin rouge) ; `67-FIX-B-SUMMARY.md`, `67-FIX-C-SUMMARY.md` | `a253d713`, `ce63c0b1` |

## Écart assumé : CKPT-10 et la release

CKPT-10 dit « aucun bump de la `VERSION` racine (P67-D-05) ». C'était une contrainte de la phase : elle tient, la phase n'a bumpé que
le module (`plugin/cockpit`, `conductor` 1.52.1). La release racine `v2.75.0` est décidée APRÈS la phase (arbitrage Samuel, AskUserQuestion
session principale, 2026-11-02) ; son bump est un geste distinct, porté par le nœud `bump-2750`. Le texte de l'exigence n'est pas réécrit.
Tag et release GitHub : après le merge de la PR #187, geste de Samuel.

## Exigences ouvertes

Aucune : les douze sont livrées et prouvées par une suite rejouée verte.

## Points à retenir (hors exigences)

- Réserve de 67-03 (`check-python-isolation.sh` lent sur `elk.bundled.js`) : levée, le gate exclut `*/assets/vendor/*` (D1, 2026-11-01).
- Réserve de 67-07 (textes anglais du moteur : Santé, couverture de l'onglet Code) : acceptée, devenue le texte de CKPT-09 (P67-D-20).
- Au BACKLOG, pour la phase de suite du cockpit : refonte mobile (D4, I4, I5, I6), visite guidée (I1), O5, choix de langue,
  suivi du travail en cours (note `.planning/notes/2026-11-03-cockpit-progression-en-cours.md`, option A).
- `67-FIX-D` : 86 serveurs `tmp.*/serve.mjs` orphelins antérieurs à la phase restent à arrêter par leur propriétaire.
