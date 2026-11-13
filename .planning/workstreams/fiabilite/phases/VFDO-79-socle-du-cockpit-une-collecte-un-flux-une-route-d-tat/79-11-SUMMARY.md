# 79-11 — SUMMARY

Plan 79-11 (SOCL-15, AUDC-AM5, P79-D-19) : exécuté, baseline armée. Commits : e805f128, 05c06792, d64163b9, 05c873ef, f2055684, 2dcff44c, c9a30219, 4345971d, cfaa7105, puis le commit d'armement (baseline + V4c.9).

## Relevés

- AVANT (ccece3d8) : TOTAL-AVANT 1719 (99 fichiers du périmètre, 86 avec lignes longues) ; neuf unités de pages dans la trace (79-11-RED-TRACE.md).
- Après rangement, sur la tête du plan seule : 1706 (écart -13, en-têtes retirés et préfixes « export » ôtés, aucun repli).
- À l'armement (instantané de HEAD 4b2b6d08, aucun fichier non suivi ni modification non commitée) : 93 fichiers à plus de 0, total 1679 lignes longues, dont 2 de code tiers (assets/vendor/xterm : xterm.js 1, addon-fit.js 1). Le total a bougé depuis le rangement parce que d'autres plans (79-06, 79-09, 79-10, 79-12) ont écrit dans le périmètre ; la baseline est l'état trouvé, pas une hausse.

## Dette de colonnes : vingt fichiers du lab les plus chargés (hors vendeurs tiers)

- skills/cockpit-moteur/assets/ui/00-vibeflow.js 91
- skills/cockpit-moteur/assets/ui/terminal/vue.js 82
- scripts/vf-cockpit-project.mjs 68
- skills/cockpit-moteur/assets/ui/01-vf-responsive.js 63
- skills/cockpit-moteur/assets/ui/70-vf-live.js 60
- skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js 59
- skills/cockpit-moteur/assets/ui/02-vf-telephone.js 56
- skills/cockpit-moteur/assets/ui/terminal/client.js 50
- skills/cockpit-moteur/assets/ui/79-vf-fr-dict-b.js 45
- skills/cockpit-moteur/assets/ui/78-vf-fr-dict-a.js 43
- scripts/vf-cockpit-who.mjs 43
- skills/cockpit-moteur/assets/ui/tiroir/tiroir.js 42
- scripts/vf-cockpit-git.mjs 40
- skills/cockpit-moteur/assets/ui/77-vf-git-tiroir.js 39
- skills/cockpit-moteur/assets/ui/76-vf-git-entete.js 38
- scripts/vf-cockpit-ask.mjs 37
- scripts/vf-cockpit.mjs 36
- skills/cockpit-moteur/assets/ui/77-vf-git-rendu.js 29
- skills/cockpit-moteur/assets/ui/72-vf-equipe.js 29
- skills/cockpit-moteur/assets/ui/77-vf-git-vue-detail.js 26

Faire baisser : `node plugin/cockpit/scripts/tests/colonnes-cliquet.mjs abaisser plugin/cockpit plugin/cockpit/scripts/tests/colonnes-baseline.txt`. Rebasage (79-09, 79-10, 79-12, 79-06) : `verifier` doit rendre OK ; une baisse se suit par `abaisser`, une hausse se replie, jamais de relèvement. Une hausse de colonnes-baseline.txt remonte au manager (une ligne « déléguée » ne la couvre pas).

## À surveiller après l'armement

Tout fichier `scripts/*.mjs` NEUF commité après l'armement entre dans le périmètre (le cliquet le voit : 0 ligne longue attendue). Un correcteur de 79-06 (fix2-x06) travaillait sur serve.mjs, vf-cockpit-terminal.mjs et peut-être un module neuf vf-cockpit-etat-ecrire.mjs non suivi à l'armement : s'il le commite avec des lignes longues ou si un compte baisse, V4c.9a rougit ; le manager fait suivre (abaisser ou repli).

## Règle 9 : grep des fichiers déplacés ou créés, suites ET aides de copie, chaque suite rejouée seule

Fichiers cherchés : vf-cockpit-navigateur, navigateur-charger, vue.js, client.js, q.css, tiroir*.js, lancer*.js, tiroir.css, lancer.css, et les noms retirés (terminal-client, terminal-vue, terminal-style, terminal-tiroir-ui, terminal-tiroir-style, lancer-style, vueTerminal, clientTerminal, STYLE_Q, STYLE_TIROIR, STYLE_LANCER, accepteMessage, corpsProposition, extraireSessionChat, installerObservateurChat). Aides de copie : socle-serveur.sh (cockpit_module_copie copie scripts et skills en entier ; cockpit_module_muter : table de noms étendue ; cockpit_module_muter_p neuf) ; tables mod_de et MODS_TABLE des suites (visent des racines de module : inchangées) ; copies de modules à la main : test-cockpit-questions.sh (Q11.7, corrigée), lancer-ui et lancer-bandeau (copies réduites).

Verdicts, chacune seule (durées et comptes complets dans 79-11-RED-TRACE.md) : vendor 181/0 (V4c.9 inclus, sur instantané de HEAD), terminal-page 51/0, terminal-client 76/0, terminal-xterm 81/0, terminal-tiroir 138/0, lancer-chat 38/0, lancer-mode 113/0, lancer-xss 76/0, lancer-bandeau 161/0, lancer-ui 63/0, lancer-serveur 82/0, chrome-fr 129/0, git-env 135/0, terminal-activation vert (T7.5b/c, T8.2b), questions, assemblage, collecte, cycle-serveur 91/0 : tous verts.

## Écarts, listes pour d'autres plans

- Écart à P79-D-19 : sous-dossier assets/ui/tiroir/ (build.mjs inline tout ui/*.js de premier niveau) ; fichiers rangés non repliés (dette ci-dessus). Proposition : un travail séparé de repli des lignes longues.
- 79-16 : le script du tiroir est assets/ui/tiroir/tiroir.js ; client et vue de Q : assets/ui/terminal/. Toute phase qui ajoute du code navigateur l'inscrit dans FICHIERS_NAVIGATEUR et en VENDORED.txt (AJOUT, ordre alphabétique), 0 ligne > 160 colonnes.
- 79-20 : README et CHANGELOG du module : aucun nom retiré cité (à revérifier) ; règle « un fichier plat de ui/ est dans la page de tous » ; liste close FICHIERS_NAVIGATEUR (douze fichiers).
- Commentaires résiduels hors plan : ui/02-vf-telephone.js (nomme vf-cockpit-terminal-tiroir-style.mjs), ui/01-vf-responsive.js (nomme le tiroir) : laissés (fichiers chauds de la Phase 80).
- Mesures d'instabilité demandées : voir le retour typé et la trace (tiroir 1138 s en isolé ; bandeau LB.E11 non reproduit, hypothèse sur le premier sondage de client.js).
