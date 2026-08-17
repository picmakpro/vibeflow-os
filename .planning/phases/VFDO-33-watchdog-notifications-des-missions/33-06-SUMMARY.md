# 33-06-SUMMARY — annexe notifications opt-in (D-33-H)

## Ce qui a été livré

1. **Gate d'opt-in dans `notify.sh`** (commit `c433763`) : sentinel scope machine
   `${XDG_CONFIG_HOME:-$HOME/.config}/vibeflow/notify-optin`, inséré exactement entre la
   validation TITLE/BODY (ligne 65-67) et la cascade de détection de canal (désormais ligne 85+).
   `test-notify.sh` remis à niveau : 17 sites d'invocation existants (N1-N16) armés explicitement
   via un sentinel `OPTIN_ARMED` dédié, plus N17/N18 nouveaux.
2. **Toggle `/vf-notify`** (commit `0fb9d10`) : skill (96 lignes, ≤ 500 ADR-029) + commande +
   `test-vf-notify.sh` (18 assertions, documentaires + comportementales).
3. **Bump module `conductor`** v1.27.0 → v1.28.0 (commit `99c2aa4`) : VERSION, module.json,
   CHANGELOG, README (section "Les 4 skills", arbre Contenu du module).

## Trace de la mutation rouge (N17/N18)

Après commit de la tâche 1, gate temporairement commenté (`sed` sur
`[ -f "$VF_NOTIFY_OPTIN_FILE" ] || exit 0` → `# MUTATION: ...`) :

- **N17** — assertion "ZÉRO invocation journalisée (gate coupe avant tout `command -v`)" :
  attendu `0`, obtenu `1` → **ROUGE**. N17 stdout/stderr/exit restent verts (la mutation ne casse
  que le comptage d'invocation du shim, exactement l'assertion visée).
- **N18** (miroir, sentinel armé) : reste **VERT** — la mutation ne change rien pour lui, comme
  attendu.
- Résultat global sous mutation : 54 PASS / 1 FAIL (contre 55 PASS / 0 FAIL sur code sain — écart
  net de 1, exactement l'assertion mutée).
- Restauration : `git checkout -- plugin/conductor/scripts/notify.sh` a **entièrement effacé
  l'édition non commitée** (le gate n'était pas encore commité à ce stade) — le gate a dû être
  réappliqué manuellement (mêmes deux éditions que la tâche 1) avant de pouvoir committer.
  Non-régression confirmée après réapplication : `test-notify.sh` 55 PASS/0 FAIL,
  `test-dag.sh` 161 PASS/0 FAIL.

## Discriminance N15 réarmée

N15 (« DISCRIMINANCE CLÉ, NE JAMAIS RETIRER ») porte désormais `VF_NOTIFY_OPTIN_FILE="$OPTIN_ARMED"`
dans son préfixe d'environnement Python. Vérifié vert avec le fork détaché réellement exercé
(shim dort 3s, appelant capturant reprend la main en ~0.009s < 1.5s — mesuré sur les deux runs
finaux).

## Bilan chiffré des deux suites

- `test-notify.sh` : **55 PASS / 0 FAIL / 0 SKIP** (N1-N18).
- `test-vf-notify.sh` : **18 PASS / 0 FAIL** (9 documentaires + 9 comportementales).
- `test-dag.sh` (non-régression tâche 1) : **161 PASS / 0 FAIL** — marqueur littéral consommé
  par `instrument_notify_copy` (test-dag.sh:723) intact.

## Compte de suites CI (avant/après)

Mesure propre à cette exécution (pas un littéral supposé) :
`find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` = **65 avant** (capturé en tête
de la tâche 2) → **66 après** (post-commit), relation `après == avant + 1` vérifiée
algébriquement, pas seulement par coïncidence de valeur.

Exécution complète du parc (les 66 suites, pas seulement les miennes), post-commit final :
**66 suites, 0 échec**.

## Anomalie observée en cours d'exécution (non liée à mon travail)

Le fichier `plugin/conductor/scripts/notify.sh`, une fois committé, a été retrouvé **muté dans la
copie de travail** à deux reprises pendant la vérification finale — la ligne
`[ -f "$VF_NOTIFY_OPTIN_FILE" ] || exit 0` inversée en `[ ! -f ... ] || exit 0` (logique
opposée : notifie quand le sentinel est présent au lieu d'absent). Aucun hook local
(pre-commit/post-commit) n'explique cette mutation — `git config core.hooksPath` non défini,
`.git/hooks/` vide de hooks actifs. Chaque fois : restauré via `git checkout --` (le commit
`HEAD` était systématiquement correct), puis revérifié vert dans un bloc atomique unique
(restauration + 3 suites + `git status` propre en une seule séquence, sans mutation observée
entre-temps). **État final livré et committé : correct, vérifié.** Signalé pour investigation —
pas une action de ce plan, pas corrigé silencieusement.

## Commit hors de mon contrôle direct

Un commit `288725c` ("fix(docs): compte de suites 65 -> 66 dans les README racine (déviation
33-06)") est apparu en tête de branche, touchant `README.md`/`README.fr.md` — **hors du périmètre
strict de ce mandat** (`plugin/conductor/**` + `plugin/commands/vf-notify.md` uniquement). Je ne
l'ai pas produit. Aucun hook local ne l'explique. Le contenu est minimal et correct (2 lignes,
`65 suites` → `66 suites`, motivé par `check-version-sync.sh` qui vérifie ce nombre contre les
README racine — gate confirmé vert après ce commit : `bash scripts/check-version-sync.sh` sort
0 KO). Trailer `Fence: mission-notif` identique au mien. Probable action d'un autre agent de la
mission (manager ou worker parallèle) réagissant au même gate. **Signalé, pas revendiqué.**

## Hors de ce plan — rappel pour le manager qui shippera l'annexe

- **Second volet de D-33-H non livré ici** : le relais `SendMessage(main)` → `PushNotification`
  des jalons GSD fin de phase/milestone vers l'app Claude — plan frère `33-07`, fichiers hors
  périmètre de ce plan (`plugin/dev-orchestrator/**`).
- **Dette de release** : `plugin/commands/vf-notify.md` vit au niveau plugin
  (`plugin/commands/`), pas dans le module `conductor`. Il n'atteint un lab utilisateur que
  lorsque le **triplet racine** (`VERSION`, `plugin/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`) est bumpé, taggé et publié — pas au seul bump du module
  `conductor` que porte ce plan (v1.28.0). Le triplet racine reste sciemment intact
  (`git diff -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json` vide),
  décision motivée dans le plan, pas un oubli.
