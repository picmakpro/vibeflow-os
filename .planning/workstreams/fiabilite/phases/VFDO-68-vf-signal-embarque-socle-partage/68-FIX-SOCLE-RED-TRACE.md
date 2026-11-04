# 68-FIX-SOCLE — trace des témoins rouges, puis verts

Mandat de correction ciblée du socle cockpit (Phase 68). Un finding = un témoin rouge consigné ici (assertion, attendu, obtenu), un commit, puis le correctif et le vert.
Rouges obtenus sur `69060360` (code du socle inchangé), suite `test-cockpit-signal.sh`.

## F-02 — chaînes écrites par d'autres sorties sans nettoyage ni borne

Témoin : section S9 de `test-cockpit-signal.sh`, écrite en famille (fonction `FAM`, une assertion par champ, puis un balayage de TOUTES les chaînes de la sortie).
Quatre scénarios : (A) ROADMAP d'un autre worktree, (B) champ `ws` d'un DAG de 100 000 caractères, (C) nom de compartiment et `active-workstream`, (D) racine du lab.
Chaque champ est d'abord exigé présent et non vide (verdict `inaccessible` sinon) : un rouge « contrôle » est donc bien un contrôle lu dans le champ, pas une absence.

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| S9.A `arbres[1].phaseActive.nom` (borne 90) | ok | controle |
| S9.B `missions[0].ws` (borne 80) | ok | controle |
| S9.C `phases[0].ws`, `phases[0].key`, `jalons[0].ws`, `jalons[0].phases[0]`, `layout.actif`, `missions[0].ws`, `missions[0].phaseKey` | ok | controle (sept fois) |
| S9.D `root`, `equipe.root` | ok | controle (deux fois) |
| S9.A `*` / S9.B `*` / S9.C `*` / S9.D `*` (balayage global, borne 1024) | ok | controle:1 long:0 / controle:1 long:1 / controle:7 long:0 / controle:2 long:0 |

Non-rouge volontaire : `arbres[1].label` passe (déjà nettoyé) — témoin que la famille ne rougit pas à vide.
Total : 15 FAIL, 44 PASS (sortie : scratchpad `fix-socle-f02-rouge.out`).

Correctif : `assainir` (passe finale sur l'objet entier, borne 1024) + bornes serrées par champ connu (`ws` 80, `actif` 80, `phaseActive.nom` 90) dans `vf-cockpit-signal.mjs`.
Vert : `test-cockpit-signal.sh` 60 PASS / 0 FAIL sous bash ET zsh (scratchpad `fix-socle-f02-vert.out`, `fix-socle-f02-vert-zsh.out`).
Mutant S9.M (passe finale retirée, bornes serrées conservées) : le balayage global rougit (`*=controle:3`) — la passe finale est bien le filet.

## F-03 — `git status --porcelain` de who sans `core.fsmonitor=false`

Témoin : section W19 de `test-cockpit-who.sh` — lab jetable, `core.fsmonitor` pointant un script qui touche un fichier témoin dans son `.git/config`, DAG commité (suivi et propre) avec un nœud `running` frais.
Rouge sur `387df78b` (scratchpad `fix-socle-f03-rouge.out`) :

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| W19.2 collectWho : le script de fsmonitor n'a jamais été exécuté | intact | exécuté |
| W19.3 émetteur entier : `signal@1` produit, script jamais exécuté | `vibeflow/cockpit-signal@1\|intact` | `vibeflow/cockpit-signal@1\|exécuté` |

Témoins non rouges : W19.0 (le script s'exécute bien sur un `git status` nu : le rouge n'est pas un fichier témoin inatteignable), W19.1 (le nœud est lu : le chemin git est parcouru).

Correctif : `GIT_SUR` déplacé dans `vf-cockpit-paths.mjs` (ré-exporté par `vf-cockpit-arbres.mjs`) et appliqué aux cinq appels git du socle (who ×3, planning `for-each-ref`, paths `rev-parse`). Plus aucun `execFileSync('git'` ni `sh('git'` sans le préfixe.
Vert : `test-cockpit-who.sh` 91 PASS / 0 FAIL ; `test-cockpit-retard.sh` (R5.3 : chaque appel git journalisé porte `core.fsmonitor=false`) vert.

## F-04 — un `driver-lock.sh` d'avant `--all` rend `inconnu` à toute mission vivante

Témoin : section V11 de `test-cockpit-vie.sh`, faux script qui refuse `--all` (`Unknown arg: --all` sur stderr, exit 1, stdout vide — la forme d'avant `32438005`) et répond à `status` par l'objet plat réel d'un verrou (`json_status` de `driver-lock.sh`, sans `scope` ni `ws`).
Rouge sur le code de `95050bc3` (scratchpad `fix-socle-f04-rouge.out`) :

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| V11.1 lab plat, verrou tenu lu par `status` | running | inconnu |
| V11.2 lab plat, verrou absent lu par `status` | abandonnee | inconnu |

Gardes contre la sur-réparation (vertes avant et après) : V11.3 (lab partitionné, `status` au schéma de portée : jamais lu comme verrou plat, reste `inconnu`) ; V11.4 (script qui refuse tout verbe : `inconnu`). V11.0 : témoin que le faux script se comporte bien comme l'ancien.

Correctif : `lireVerrous` retombe sur `status` quand `status --all` rend une sortie vide (refus), et n'accepte la réponse que sans `scope` ni `locks`.
Vert : `test-cockpit-vie.sh` 35 PASS / 0 FAIL (scratchpad `fix-socle-f04-vert.out`).

## F-05 — lab plat : `verrous` lu une fois depuis `root`, appliqué à tous les arbres

Témoin : section S10 de `test-cockpit-signal.sh` — faux `driver-lock.sh` de forme réelle (`json_status` en lab plat : ni `scope` ni `ws`) qui répond selon le dossier courant (verrou tenu seulement là où `.planning/DRIVER.lock` existe) ; le même DAG `MISSION-2` (nœud running) est dans les deux checkouts. `phaseActive` d'un arbre sans branche `phase-N` est la dernière phase à mission running : elle dit si la mission de CET arbre est vivante. Deux sens (verrou dans l'arbre principal seulement, puis dans le worktree seulement).
Rouge sur `371dd2cd` (scratchpad `fix-socle-f05-rouge.out`) :

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| S10.1 verrou dans l'arbre principal seulement | `main:2#feat/x:aucune` | `main:2#feat/x:2` |
| S10.2 verrou dans le worktree seulement | `main:aucune#feat/x:2` | `main:aucune#feat/x:aucune` |

Témoin S10.0 (vert) : le faux script répond bien selon le dossier.

Choix : lecture par arbre en lab plat (la forme la plus simple qui tienne sans restreindre l'hypothèse). `collectSignal` passe `{ scriptsDir, home }` à `readPlanning` des arbres non courants quand `verrous.plat` ; `readPlanning` lit alors paresseusement le verrou de la racine de CET arbre, seulement s'il porte un nœud running. En lab partitionné la lecture unique reste (dossier git commun = même verrou pour tous les arbres : le commentaire est désormais écrit pour ce régime seulement).
Vert : `test-cockpit-signal.sh` 63 PASS / 0 FAIL (scratchpad `fix-socle-f05-vert.out`).

## F-06 — pas d'échéance globale : le total croît avec le nombre de worktrees

Témoin : section S11 de `test-cockpit-signal.sh` — lab à six arbres, `git` ralenti à 0,5 s par appel (emballage en tête du `PATH`), `collectSignal(root, { echeanceMs })` appelé en bibliothèque.
Contrôle (vert) : S11.1, échéance généreuse (600 000 ms) — six arbres, `retard.main` = `0,3,3,3,3,3`, durée ≥ 8 s : l'emballage ralentit bien, et le calcul complet est lent.
Rouge sur `6f5c8191` (scratchpad `fix-socle-f06-rouge.out`) — l'option `echeanceMs` est ignorée :

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| S11.2 échéance de 3 s : rend en moins de 6 s | true | false |
| S11.3 six arbres listés, au moins un `retard.main` null, aucun 0 pour un arbre en retard | `6\|true\|false` | `6\|false\|false` (aucun null : tout est calculé, lentement) |
