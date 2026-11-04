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
