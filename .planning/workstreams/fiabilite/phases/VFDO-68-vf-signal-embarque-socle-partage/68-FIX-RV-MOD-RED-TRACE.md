# 68-FIX-RV-MOD — trace des témoins rouges et verts (correction ciblée du mod vf-signal, revue fraîche et recette)

Poste : Claude Code 2.1.318, `claude plugin test plugin`, tête de départ `a9f82605`. Identifiants `RV-…` (verdict.sh refuse un doublon).
Fichiers de test : `plugin/cockpit/signal/tests/rv-mod.test.tsx` (Q4-x, R2, R3, R11) et `rv-recette.test.tsx` (N1, N2, N3, N8).
Décisions : P68-D-34 (arbitrage de Samuel « Rien sous le lab (Recommandé) », AskUserQuestion, session principale Claude Code, 2026-11-04),
P68-D-37 (décision du manager), P68-D-35 (« Tout selon les recos (Recommandé) », même canal, même date), P68-D-38 (les quatre écarts N1, N2, N3, N8,
même citation de Samuel, relayée par le manager mgr68 le 2026-11-04).

## ROUGE (code non corrigé, 9 fail pour le premier lot ; 6 fail pour N)

| point | témoin | assertion | attendu | obtenu |
| --- | --- | --- | --- | --- |
| Q4-1 | RV-Q41a | lanceurs lancés, realpath du compte absent | `[<plugin>/cockpit/scripts/vf-cockpit.mjs]` | `["/home/user/.claude/scripts/vf-cockpit.mjs"]` |
| Q4-1 | RV-Q41b | bouton `elaguer`, realpath du compte absent | undefined | un Button `elaguer` |
| Q4-2 | RV-Q42 | /lab → /reel/lab, lanceur du compte sous /reel/lab | plugin | VERT sur la tête (le terme existe, aucun témoin ne le tenait) : voir mutant |
| Q4-4 | RV-Q44 | copies sans script résolu | `[]` | `["bash driver-lock.sh takeover --owner=<id> --ws=fiabilite"]` |
| Q4-5 | RV-Q45a | `cwd` du lanceur | racine du plugin | `/lab` |
| Q4-5 | RV-Q45b/c/d | `init.env.PATH` des trois lancements | `/usr/local/bin:/usr/bin`, `/usr/bin`, repli | `undefined` |
| R2-1 | RV-R2-failed, RV-R2-killed | gestes d'un agent fini en failed / killed | aucun | VERT sur la tête (aucun témoin ne tenait ces deux statuts) : voir mutants |
| R3-1 | RV-R3 | fantôme « aucun agent en cours » (compact, tout terminé) | défini | undefined |
| R11 | RV-R11a | ligne d'agent du brief | sans mot anglais | `- vf-coder · running · tache 0` |
| N1 | RV-N1 | texte `-\d+ s` | undefined | un Text `… · -4 s` |
| N2 | RV-N2a, RV-N2b | ligne de verrou de dépôt | `■ dépôt · juge-q3 [· revue-q3] · 15 s` | `■ dépôt · juge-q3 · depot · 15 s`, étape absente |
| N3 | RV-N3 | `verrou · revue`, `exécution · étape un` | définis | `lock`, `dag-node`, `exec` |
| N8 | RV-N8a, RV-N8c | couleur de « toi · nœud bloqué » et de la marque du bandeau | `#f28b8b` (st-blocked) | `#f0c36b` (st-active) |

## VERT : 153 pass / 0 fail (`claude plugin test plugin`), `claude plugin validate --strict plugin` passé

- Q4-1 : `reel()` rend `realPath` seul ; `admis` refuse quand il manque (le d.ts de `$.fs.stat` le dit) ; la racine du lab se rabat sur son écriture.
  `MA-D34d` réécrit par conception (sans realpath : refusé, le lanceur du plugin prend le relais). Les mocks de `labFix`, `actions.test`, `vf-signal.test`
  fournissent désormais un handler `fs.stat` (realPath = chemin).
- Q4-4 : sans script résolu, rien n'est copié, toast « takeover : driver-lock.sh introuvable hors du lab, rien copié ».
- Q4-5 : l'API le permet (`ProcessRunInit.env`, posé PAR-DESSUS l'environnement de l'hôte). `hooks/env-sain.ts` lit `$.env.get('PATH')`, écarte les
  entrées vides, relatives, sous le lab (écriture normalisée `.`/`..`, ou realpath de l'entrée), repli `/usr/bin:/bin:/usr/sbin:/sbin`, et ne passe QUE `PATH`.
  Appliqué à l'émetteur, au lanceur, à l'élagage. `ouvrirCockpit` part de la racine du plugin (`--lab` suffit). L'élagage garde `cwd: racine de session`
  (exigé par `driver-lock.sh`) : seul son PATH est assaini.
- R3-1 : le fantôme s'affiche quand aucune ligne vive (`rowsVifs.length === 0 && (compact || nReplies === 0)`).
- R11 : `statutAgent` (ds.ts, même approche que `statutNoeud`) : running → en cours, completed → terminé, failed → en échec, killed → arrêté,
  pending/queued → en attente, … ; hors table, tel quel. La vue Équipe n'affichait déjà aucun statut brut.
- N1 : `age()` borne à 0. N2 : `detailVerrou` (portée écrite une fois par l'appelant, puis propriétaire, phase, étape, âge) ; l'étape vient de `step` ou du
  travailleur `lock` du même propriétaire (le signal ne porte pas `step` dans `verrous.liste` : à noter côté socle). La portée brute `depot` et « sans portée »
  ne sont plus écrites : FX-7a et FX-7b (`reel.test.tsx`) réécrits en conséquence. N3 : `libelleType`. N8 : `actionBloquee` → `st-blocked` (jeton existant)
  pour la pane (dock, compact) et le bandeau.

## Mutants (un à la fois, suite rejouée ; script hors dépôt, sorties dans le scratchpad)

| mutant | témoins rouges |
| --- | --- |
| Q4-1 : repli sur le chemin écrit rétabli (deux formes) | MA-D34d, RV-Q41a, RV-Q41b |
| Q4-2 : terme `sous(c, base)` retiré | RV-Q42 |
| Q4-4 : copie sans script rétablie | RV-Q44 |
| Q4-5 : `cwd: root` | A1, RV-Q45a |
| Q4-5 : `env` retiré (ouvrir / élagage / émetteur) | RV-Q45b-d / RV-Q45b / RV-Q45b-d |
| Q4-5 : entrée relative gardée | RV-Q45b, RV-Q45d |
| Q4-5 : sous le lab par écriture / par realpath / realpath du lab / `..` non normalisé / repli vide | RV-Q45e / RV-Q45c / RV-Q45c / RV-Q45e / RV-Q45d |
| R2 : `failed` ou `killed` retiré de STATUTS_FINIS | RV-R2-failed / RV-R2-killed |
| R3 : ancienne condition du fantôme | RV-R3 |
| R11 : brief brut / `killed` sorti de la table | RV-R11a |
| N1, N2 (étape, portée), N3, N8 (pane, compact, bandeau) | RV-N1 ; RV-N2b, FX-7a, FX-7b / RV-N2a ; RV-N3 ; RV-N8a ; RV-N8a ; RV-N8c |

Mutant survivant : « entrée vide gardée » dans `pathSain` : équivalent, `absolu('')` est faux, le test `!absolu(el)` écarte déjà l'entrée vide ;
le test `!el.trim()` documente l'intention. Premier jeu de `RV-Q45e` : le mutant `..` survivait avec `/lab/../lab/x` (reste lexicalement sous `/lab`) ;
témoin refait avec `/usr/../lab/x`.

## Suites rejouées

`claude plugin validate --strict plugin` : passé · `claude plugin test plugin` : 153 pass / 0 fail · `test-cockpit-signal-mod.sh` bash et zsh : 40 ok / 0 ko
(M9 avait rougi sur un « #201 » en commentaire de `env-sain.ts` : écrit « PR 201 ») · `bash scripts/check-gate-touche.sh` : DECLARE (7 marqueurs conformes) ·
balayage `/(Users|home)/…` des fichiers touchés : seul `/home/user`.
