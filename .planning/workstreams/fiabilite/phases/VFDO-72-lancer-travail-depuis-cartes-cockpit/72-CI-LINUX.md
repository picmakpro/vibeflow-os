# 72-CI-LINUX — rouges Linux de la PR #214 (run 42162457120)

Reproduit sous Linux : conteneur ubuntu 26.04 (coreutils uutils), node 24, python3, Chromium (Playwright, arm64), compte non root.
Les faux binaires `claude` n'étaient PAS en cause : ils tournent sous uutils (mv, sort, env).

## Cause 1 — Ctrl-C et ligne dans la même écriture (processus Q5, bout-en-bout B2/B3/B5, pty L1.3 / M-ENTREE-AUTO / J2.2, xss LEG.6 / C0l.1)

`lancer_ligne` (vf-cockpit-pty.py) écrivait `Ctrl-C + ligne` en un seul `write` au maître du PTY. Sous Linux, bash (readline) perd le premier octet
qui suit le Ctrl-C quand il arrive dans la même écriture : la ligne s'affiche (donc « la ligne exacte est à l'invite »), mais sous la forme `laude --session-id …`,
et l'Entrée du client lance `bash: laude: command not found` ; le faux claude n'écrit jamais d'argv. Sous macOS l'ordre est tenu.

Preuve (script PTY minimal, bash --norc -i, ubuntu 26.04) :
- Ctrl-C + `echo MARQ$((1+1))` en une écriture, puis Entrée : `bash: cho: command not found`.
- Ctrl-C, attente, puis la ligne, puis Entrée : `MARQ2`. Ligne seule : `MARQ2`.
- Deux écritures consécutives sans attente : 39/40 sous charge (1 échec) — insuffisant. Ligne écrite après le retour de l'invite : 60/60 sous la même charge.

Correctif : Ctrl-C part seul ; la ligne n'est écrite qu'après la réaction du shell (sortie vue puis 30 ms de calme, ou 300 ms sans rien). La réponse `LANCE ok`
part avec la ligne, pour que « 204 = la ligne est à l'invite » reste vrai (les réponses suivent l'ordre des demandes : le serveur les apparie en FIFO).
Les mutants de pty.sh et de xss.sh (M-ENTREE-AUTO, M-FILE-NON-BORNEE) visent les nouvelles lignes ; L10 remet à zéro l'état différé entre ses cas.

Avant correctif, reproduit : processus 45 PASS / 1 FAIL (Q5). Après : 46 / 0 ; pty 47 / 0 ; xss 76 / 0 ; bout-en-bout 54 / 0 (Chromium).

## Cause 2 — LB.E2, clic « avant l'armement » devenu un vrai clic

Le bandeau d'e1 arme Lancer 1500 ms après son affichage ; e2 clique « avant l'armement » après e1 et ses lectures. Sous charge ce délai est déjà écoulé : le clic
passe (POST /lancer 204, bandeau retiré), puis `attendreArme` attend 4 s un bouton qui n'existe plus. Preuve : diagnostic injecté dans une copie, 4 suites en parallèle,
`DIAG b=false lancers=204` ; reproduit 4/4 sous charge, 0/1 au repos.
Correctif (test seul, assertion non affaiblie : le témoin `desarme` reste exigé) : e2 sert une proposition neuve (ID 35, armement 3000 ms) et attend son bandeau avant le clic ; `attendreArme(6000)`.
Après : 4 suites parallèles, LB.E2 vert 4/4.

## R1 (responsive) — flake antérieur à la 72

Même message sur `main` (merge-base 57e7957f, sans la 72) sous la même charge : « carte : sort de la zone libre (319..712 / libre 0..648) » (long / project / 1024 px),
et R1 court/index, court/project. Taux comparables avec et sans la 72 (3/5 contre 4/5 sous charge ; 0/2 au repos). Aucun lien avec la section Lancer
(sa règle ne s'applique que sous 1000 px ou en pointeur grossier). Non corrigé : hors périmètre.

## Non reproduit / environnement
- M-FOCUS-CLIENT/VUE/CARTE/BANDEAU (bandeau.sh) rougissent dans mon Chromium arm64 de conteneur, mais passent sur le Chrome de la CI et ne sont pas liés à ces causes.
