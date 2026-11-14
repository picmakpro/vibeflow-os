---
phase: 80
plan: "19"
requirements: [FORM-18]
status: executed-partiel
---

# 80-19 — constats de Santé en français à la source

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

SF3.5 : à ajouter après 80-10 (VF_ONGLETS) — non écrit ici, `VF_ONGLETS.aller` n'existe pas encore dans la branche.

## Livré

- `health.mjs` : les 14 genres de constats (title, detail, notes, fix) sont en français ; libellés des secrets (`what`, `hint`, `svc`),
  dates Firebase (`fr-FR`) et nombres de lignes (`nl`, singulier géré) aussi ; noms propres, commandes et fragments de code inchangés ;
  détection, sévérités, identifiants et valeurs insérées inchangés. Lignes de plus de 160 points de code : 126 -> 73 (OK-COLONNES-HEALTH).
- `test-cockpit-sante-fr.sh` + `chrome-sante-fr.mjs` (36 lignes) : lab jetable à deux dépôts servi par `socle-serveur.sh`, panneau lu dans
  la page servie. SF1.1/1.2 (clé en fichier de test, titre, détail, invite), SF2.1 (les 14 genres du source tous déclenchés, comptés sur le
  source), SF2.1b/c (aucun mot témoin anglais, collecteur et page servie), SF2.2/2.2b/2.2c (noms propres), SF2.3 (nom de fichier hostile),
  SF3.1 (un constat français traverse `t.constat` inchangé), SF3.2 (introduction), SF3.4 (dépôt jamais muté), trois mutants sur copie du
  module avec serveur lancé sur la copie : M-RESTE-ANGLAIS, M-NOM-PROPRE-TRADUIT, M-ECHAPPE (rougissent ; `cockpit_lancer` 5 = échec).
- `test-cockpit-sante.sh` S2.3 réécrite en français (égalité exacte), S2.4/S2.5 sur le français, `sonde.mjs` regex ramenées au français :
  34 lignes `assert_eq`/`assert_ne` avant et après, aucune relâchée.
- Rien touché : `20-health.js`, `80-vf-fr.js` (R et P gardés), `chrome-fr-etats.mjs`, `test-cockpit-chrome-fr.sh` (F23 vient d'une fixture
  anglaise injectée, pas du collecteur : intacte, M-AFFICHAGE la rougit toujours, F23.1 FAIL sous `VF_FR_F23_MUTANT=affichage`).
- Cliquet : condition FAUSSE relevée avant le premier commit (trace), OK-CLIQUET-HORS ; aucun commit `(80-19)` sur `colonnes-baseline.txt`,
  les README, `ci-shard-suites.sh` ni le CHANGELOG du module.

## Écarts

- Écart : les `title:` sont 13 mais les genres 14 (le titre Firebase est porté par une variable) ; SF2.1 compte les `id:` du source.
- Écart : un seul commit `feat` pour `health.mjs` (secret et autres genres traduits d'un bloc), au lieu de deux.
- Écart : SF3.1 vérifie la moitié française (le constat anglais d'un graphe ancien reste gardé par F23, existant) ; SF3.2 compare le texte
  rendu du lab à trois services à la valeur relevée avant le code, les cas « sans service » et « Supabase seul » restent portés par S4.
- Écart : la précondition « 79-01 à 79-18 fusionnés, 80-14 fait » levée par la consigne ; la coquille (79-16) absente, page servie par
  `socle-serveur.sh` lue telle quelle.
- Écart : le genre `localhost-url` n'est atteignable que pour un nœud de type `ui` (déclaré par l'architecture) : SF2.1 relance `buildHealth`
  sur le graphe et l'analyse du lab avec le nœud de l'app déclaré `ui` ; la page servie n'a donc pas ce genre.

## Suites (sur la tête commitée `12b753e4`)

| Suite | Verdict | Secondes |
|---|---|---|
| test-cockpit-sante.sh | 50/0 | 1 |
| test-cockpit-sante-fr.sh | 24/0 | 16 |
| test-cockpit-chrome-fr.sh | 141/0 | 27 |
| test-cockpit-chrome-fr.sh avec `VF_FR_F23_MUTANT=affichage` (témoin) | F23.1 rouge | 27 |

## Constat hors périmètre

`NOT_GUARD` de `health.mjs` contient `log\w*` : il exclut `login_required` (et tout nom commençant par `log`) de la reconnaissance des
vérifications de connexion Flask. Non corrigé ici (détection hors périmètre), à décider.

## Ligne de CHANGELOG demandée au plan d'assemblage 80-18

- Santé : les constats du panneau (titres, détails, notes, invites de correction) sont écrits en français dans le collecteur, noms propres
  gardés, introduction inchangée (P80-D-54, FORM-18 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Sous `?lang=en`
  les constats restent en français.
