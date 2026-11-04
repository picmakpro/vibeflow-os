# 68-FIX-SC2 — trace rouge / vert (correction ciblée du socle)

## Point 1 — tags, H-1 (`lab` = racine du LAB, jamais celle d'un sous-arbre)

Témoin : `test-cockpit-path-enfants.sh`, cas `H-lab-absolu`. La tolérance `grep -v 'for-each-ref'` est retirée : le journal du piège `LAB2/bin` doit être vide.

ROUGE (code d'avant, 36 PASS / 1 FAIL) :

    attendu: []
    obtenu:  [git --no-optional-locks -c core.fsmonitor=false -C <lab2>/wt for-each-ref --sort=-creatordate --count=30 ... refs/tags/v*|]

Cause : `readPlanning(<arbre sous le lab>)` passait `lab = root` (l'arbre) à `shBorne` pour les tags : `LAB2/bin` restait dans le PATH.
Correctif : `readPlanning` accepte `opts.lab` (défaut `root`), passé à `shBorne` (tags) et à `lireVerrous` (nouvelle option `lab`) ; `collectSignal` passe `lab: root` pour chaque arbre.

VERT : 37 PASS / 0 FAIL. Mutant (`undefined, LAB` -> `undefined, root` sur la ligne des tags) : 36 PASS / 1 FAIL, `H-lab-absolu` rougit ; restauré.
Limite : le chemin `lireVerrous(lab)` (lab plat, arbre sous le lab, DAG running) n'est pas discriminé par la fixture H (le worktree n'a pas de DAG running).

## Point 2 — N2, âge du verrou (P68-D-38) : ARRÊT, ask-user

Mesuré sur un vrai `driver-lock.sh` (acquire, attente 3 s, heartbeat) :

    status --all : age_seconds 0, lease_seconds 3      collectWho : lock.ageS 1

- `age_seconds` = âge du dernier BATTEMENT (`lock_age()` : `heartbeat_epoch`), pas l'acquisition. L'acquisition est `lease_seconds` (`lease_age()`, `acquired_epoch`). La prémisse du mandat est inversée.
- `who.mjs:82` lit déjà `l.age_seconds`, comme l'en-tête (`70-vf-live.js` `lockText`). Les deux lisent donc la même source ; l'écart 1 s / 57 s vient de la fraîcheur : `whoSig` (`vf-cockpit-live.mjs:66`) exclut l'âge, donc le `who` n'est repoussé que si la liste change, alors que l'événement `lock` repousse `age_seconds` à chaque rafraîchissement.

### Décision du manager (P68-D-39) : lecture (A), fraîcheur seule

L'âge affiché reste `age_seconds` (battement) ; `who@2` et `signal@1` inchangés. Le tiroir lit l'âge d'un travailleur de type verrou dans le flux `lock` (propriétaire, puis portée), repli sur `ageS` du `who`.
Choix : côté client (`70-vf-live.js`, `ageDe`), sans toucher `whoSig` : y mettre l'âge repousserait un `who` complet chaque seconde (le filet de `vf-cockpit-live.mjs` est précisément fait pour l'éviter) ; `showLock` redessine déjà le tiroir à chaque événement `lock`.

Témoin `F10b` (`test-cockpit-chrome-fr.sh`, `chrome-verrou.mjs`, Chrome réel) : `who` figé à ageS 1, flux `lock` à age_seconds 57.
ROUGE : 29 PASS / 1 FAIL (ligne du tiroir « 1 s », en-tête « 57 s »). VERT : 30 PASS / 0 FAIL.
Première version du correctif (gabarit littéral « compartiment … ») rougie par la sonde de libellés d'equipe (E23.7/E23.8a) ; reformulée sans chaîne, 116 / 0.
