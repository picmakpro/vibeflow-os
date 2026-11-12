# 79-10 — SUMMARY

Traduction au point d'émission (SOCL-14, P79-D-16, P79-D-24) : `t` dans `80-vf-fr.js`, table complétée, viewer et sept extensions enveloppés, serveur en français à la source, observateur global retiré, `?lang=en` gardé. Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée.

## Commits par fichier du moteur (règle de résolution : toute chaîne neuve des phases 73, 74, 80 s'écrit `t('texte anglais')` avec son entrée dans `79-vf-fr-dict-b.js` ; contrôle `node plugin/cockpit/scripts/vf-cockpit-fr-sources.mjs <fichier>` ; en cas de conflit garder la suppression d'`amont/` de 79-01 et rejouer la porte sur le fichier fusionné)
build.mjs b6f4fa84 · inventaire 746ad990 7aea54c7 · sources 5d8a0dd1 · 80 (ajout) bf97dcaa, surcharge 0bebb990, final cb6eeb43 · table 60ed21b8 · viewer 37e07a7c fe0ad967 c870c684 · 60-export b2ddc840 · 05-theme 7f13aca9 · 30-screens 6a197134 · 25-recent 09f2d58c · 20-health 29668ba7 73894528 · 10-glossary d314ad8f · 40-tour e02f779f · serve.mjs 73f1a0a6 837cf52d · exclusions 36787340 2ecdbaa2 e6bfa8f6. Tests : e553d3a5 c60ee140 5eaa430b f5330b77 b396af84 0f66728c. Trace/relevé : 71ba0179 20a6e781 3640cb99 229a4f50.
Écart au plan : la table est commitée AVANT les fichiers qui l'utilisent (parité verte à chaque commit) ; sept fichiers ont un commit de correction après le premier (oublis constatés par la parité).

## Preuves
- chrome-fr : 131 PASS / 0 FAIL avec parité F22 (31 écarts admis, tous des corrections : anglais laissé par l'ancien mécanisme, « 1 étapes »). fr-donnees 31/0 (témoins D7.1-D7.4, D7.7-D7.9 de b16c57fc verts), robustesse, vendor, moteur-carte, accessibilite, assemblage, marque-blanche, equipe (215/0), equipe-etats, chaine-xss, securite, serveur, projet-graphe, lancer-ui, avancement, ecrans-recent, sante (50/0), responsive (378/0), les onze terminal-* (activation, client, fin, lanceur, page, pty-plantage, pty, serveur, session, tiroir, xss, xterm : tous verts) : verts, chacune jouée seule, dans un worktree détaché.
- git-entete : 135 / 1 FAIL (H5.1b « PATH sans git ») ; identique sur la base 954618bd : préexistant, hors périmètre.
- Mutants rouges pour la bonne raison : M-OBS (F20.1, F20.2), M-LANG (F19.11, F21.2 ; plus large que le plan), M-CLE (F16.2 nomme « Answer: {} »), M-LIBRE (F17.1 nomme le littéral ; F2 et F3 aussi), M-ORDRE (F18.1), M-BUILD (F18.2), M-AFFICHAGE (F23.1 : détail resté anglais), M-RETRAIT-SEUL (F23.1, F23.3), mutant de R6.3 (entrée « Thinking… » retirée de la table : R6.3 obtient « Thinking… »).
- check-version-sync, check-machine-paths : verts. Aucune suite ajoutée.

## Pour la jointure
- `check-machine-paths.sh` ne voit pas un chemin découpé en chaînes séparées (le relevé versé en 71ba0179 portait des segments de dossier du poste, retirés ensuite). Limite du gate, à inscrire au registre, sans correctif dans ce segment. 71ba0179 n'est pas réécrit (décision de la session principale) ; contrôle ajouté : `79-10-CONTROLE-CHEMINS.mjs` (témoin rouge prouvé).
- Suites hors `files_modified` modifiées par amendement daté : responsive (R6.3 réécrit sur `__vfFrT`, ancien texte cité au plan), ecrans-recent (harnais vm), sante (sonde et trois ancres de mutants).
- Mutant qui rougit le nouveau R6.3 : entrée « Thinking… » retirée de `78-vf-fr-dict-a.js` dans une copie.
- Angles morts de la porte : lignes qui portent un appel de journal, littéraux commençant par une parenthèse (deux sites en ont découlé, corrigés).
- Limite A43 : les messages de `serve.mjs` restent français sous `?lang=en` (le serveur ne lit pas la langue).

## Liste pour 79-20
README du module : § chrome en français (traduction au point d'émission), `?lang=en`, outil d'inventaire et porte `vf-cockpit-fr-sources.mjs`, ordre des blocs `vibeflow:fr` (emplacement `<!--__UI_I18N__-->`) ; CHANGELOG « Non publié » ; limite des messages du serveur.

## Points à signaler
(a) texte d'aide `node …/serve.mjs` : enveloppé tel quel (viewer, `60-export.js`, une entrée de 78), à réécrire par 79-16 ; (b) 51 entrées de table sans site d'émission, listées dans la trace, non supprimées ; (c) aucun texte d'assemblage autre que les constats de Santé n'apparaît en anglais à la parité ; 19 motifs R : dispositions dans la trace.
