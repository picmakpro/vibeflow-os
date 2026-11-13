# 80-19 — trace des témoins rouges (P80-D-25), régime allégé

Base : tête de départ `d487f372` de la branche de la phase 80.

cliquet-condition: FAUSSE
Sortie de la commande de la précondition (en `rtk proxy`) : `CLIQUET-CONDITION-FAUSSE`.

health-longues-avant 126
assert-avant-test-cockpit-sante 34 lignes `assert_eq`/`assert_ne` (relevé `grep -c`, définitions comprises)
genres-avant : 13 `title:` + le genre Firebase (titre porté par une variable `title`) = 14 genres de constats ; 7 lignes de `health.mjs` portent les quatre gabarits anglais visés.

## Rouges sur la base (avant tout code de `health.mjs`)

### test-cockpit-sante-fr.sh sur la base (collecteur anglais) — 7 passés, 5 en échec
- ❌ FAIL — SF2.1b — aucun mot témoin anglais dans title, detail, notes et fix d'aucun constat (hors code et noms propres)
- ❌ FAIL — SF1.1 — le titre affiché est celui du collecteur, en français, et nomme aws.test.js
- ❌ FAIL — SF1.1b — le titre est exactement la forme attendue
- ❌ FAIL — SF1.2 — le détail affiché et l'invite (<pre>) sont ceux du collecteur et ne portent aucun mot témoin anglais
- ❌ FAIL — SF3.1 — chaque constat français du collecteur traverse t.constat sans changement (titres et détails égaux, jamais vide)

Verts sur la base, notés comme témoins : SF2.0, SF2.1 (14 genres déclenchés), SF2.2 et SF2.2b (noms propres cités tels quels), SF2.3 (le panneau échappait déjà le titre : témoin d invariance), SF3.2 (introduction).

### test-cockpit-sante.sh sur la base avec S2.3 réécrite en français — 47 passés, 3 en échec
- ❌ FAIL — S2.3 — le titre dit que la clé est probablement factice
- ❌ FAIL — S2.4 — le détail dit « probablement factice »
- ❌ FAIL — S2.7 — témoin : et garde le ton d'alarme

S2.5 reste verte à vide sur la base (le détail anglais ne porte pas la phrase française) : elle garde sa force après la traduction (la phrase d alarme ne doit pas apparaître dans le détail de test).

