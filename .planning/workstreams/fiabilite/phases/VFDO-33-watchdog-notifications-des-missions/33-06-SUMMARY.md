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

> **Note d'explication ajoutée le 2026-08-17 (hygiène documentaire de fin de mission) — rien à
> investiguer.** La cause est connue et bénigne : **deux workers avaient été dispatchés en parallèle
> par erreur du manager** sur le même fichier `notify.sh`, chacun y appliquant sa propre mutation
> pour produire sa preuve de discriminance. Le passage ci-dessus est conservé tel quel — c'est un
> constat honnête écrit sans cette information —, mais ce n'était **pas** une anomalie
> d'environnement, ni un hook fantôme, ni une mutation d'origine inconnue. Aucun ticket, aucune
> investigation ouverte. La leçon utile est de coordination, pas d'outillage : deux mandats
> concurrents mutant le même fichier rendent toute mesure de mutation non attribuable — et l'état
> final n'était sain que parce que `HEAD` a été revérifié à chaque fois.
>
> **Le phénomène a été re-observé en direct pendant cette hygiène documentaire** (2026-08-17), ce
> qui confirme l'explication plutôt que l'infirme : `notify.sh` était identique à `HEAD`
> (sha256 `363dfab8…`) au début du mandat, puis portait vingt minutes plus tard une mutation non
> commitée — retrait du `>/dev/null 2>&1` sur la branche `osascript` de `_notify_darwin()`
> (sha256 `b4ca0fb1…`) —, une revue de code tournant en parallèle sur `plugin/`. **`HEAD` est resté
> correct** et cette mutation n'a **pas** été emportée dans le commit d'hygiène (forme pathspec,
> `plugin/` hors périmètre). Conséquence pratique à retenir : **ne jamais conclure « arbre propre »
> sur un `git status` seul pendant qu'un autre agent travaille** — ici `git status` a d'abord
> affiché le fichier propre, puis modifié, alors que seule la comparaison de sha256 contre le blob
> `HEAD` a tranché. À restaurer par qui l'a produite (`git checkout -- plugin/conductor/scripts/notify.sh`)
> avant tout push.

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

---

## Addendum — ce qui a changé APRÈS la rédaction de ce SUMMARY

> Ce SUMMARY a été écrit au commit `d269bfa`. Deux vagues de correction ont suivi ; les chiffres des
> sections ci-dessus (notamment « 55 PASS » pour `test-notify.sh`) sont donc **datés de leur
> rédaction** et ne sont pas repris ici — ils sont remplacés par les mesures finales.

### 1. Durcissement de N17 — l'assertion centrale ne discriminait pas (commit `60dc763`)

N17 lisait le compteur d'invocations après un **`sleep 0.3` fixe**, plus court que le délai réel du
**fork détaché** de `notify.sh` (`( … & ) &`) — mesuré à **0,32–0,42 s** avant écriture du `.count`
(15 runs). Conséquence directe : **sous mutation du gate par inversion, N17 restait VERT alors que
le canal émettait réellement**. La preuve centrale du défaut OFF ne discriminait donc pas contre
cette classe de régression — la mutation rouge documentée plus haut ne couvrait que la **suppression**
du gate, pas son **inversion**.

Correctif : `sleep 0.3` → **`wait_for_file … 2`** (le patron déjà employé par N2/N3/N18), budget
calibré ≈ 5× la borne haute mesurée du fork. Vérifié vert sur code sain, **rouge sous mutation par
inversion** (la régression que la version précédente manquait) **et** rouge sous mutation par
suppression (non-régression).

Chiffrage indépendant du vérificateur de l'annexe (`33-VERIFICATION-ANNEXE.md`, rejeu en bac à sable
hors dépôt, 30 itérations par configuration) : `notify.sh` réel **0/30** faux positif · mutant +
assertion actuelle **30/30** détectés (latence max 610 ms) · mutant + ancienne assertion `sleep 0.3`
**25/30** (5 ratés, soit ~17 % d'aveuglement) · mutant sans aucune attente **0/30**, totalement
aveugle. Le correctif est **mesuré, pas cosmétique**.

### 2. Correctifs post-revue (commit `401c903`)

- **B1, bloquant — le fail-open n'était plus inconditionnel.** `${XDG_CONFIG_HOME:-$HOME/.config}`
  déréférençait `$HOME` **sans garde sous `set -uo pipefail`** : `HOME`, `XDG_CONFIG_HOME` et
  `VF_NOTIFY_OPTIN_FILE` tous absents ⇒ `notify.sh` meurt en `exit 1` avec fuite sur stderr,
  falsifiant la garantie « FAIL-OPEN SILENCIEUX INCONDITIONNEL » capitalisée en tête de fichier.
  Le **défaut OFF n'était pas falsifié** pour autant (mort avant tout `command -v`). Garde
  **`${HOME:-}`** appliquée à l'identique aux emplacements qui doivent rester littéralement égaux :
  `notify.sh`, `SKILL.md` (4 occurrences) et le `SENTINEL_SUBSTRING` du test d'identité. Nouveau
  cas **N19** (`env -u HOME -u XDG_CONFIG_HOME -u VF_NOTIFY_OPTIN_FILE` → exit 0, stderr vide,
  zéro invocation), prouvé rouge sous mutation puis restauré vert.
- **B2, majeur — la classe « assertion de zéro invocation sans attendre un fork potentiellement
  détaché » survivait ailleurs.** **N9** durci avec `wait_for_file` (même patron, budget 2 s) —
  il était mesuré **aveugle à 100 %** (0/30). Mutation de l'aiguillage d'arguments prouvée rouge
  puis restaurée. **N12** durci par précaution, avec la réserve mesurée : `chmod -x` bloque
  l'exécution au niveau noyau indépendamment de toute mutation de `notify.sh`, donc aucune mutation
  crédible n'y produit de fork réel (cas structurellement déterministe, comme N16). N2/N5/N10/N14
  vérifiés déterministes par construction (`if`/`elif`, `case`, `grep` statique) — hors classe.
- **B3, majeur — piège `user_present` mal attribué.** `SKILL.md` imputait au **toast OS** de
  `/vf-notify test` le piège `user_present` du harness (`PushNotification`), alors que `notify.sh`
  n'a **aucune** détection de présence. Reformulé pour scoper le piège au **push relayé** (Pattern H,
  `mission-flow.md`) uniquement.
- **Mineurs** — `README.md` du module recompté à **21 suites** (`find` re-exécuté ; « 19 » était
  déjà faux **avant** cette annexe, aux deux emplacements : ligne « Tests » et arbre « Contenu du
  module ») ; `wc -l <` remis en forme non redirigée dans `test-vf-notify.sh` (garde
  anti-vert-à-vide).

### 3. Chiffres finaux (re-dérivés le 2026-08-17, après `401c903`)

| Mesure | Valeur |
|---|---|
| `test-notify.sh` | **59 PASS / 0 FAIL / 0 SKIP** (N1-N19) — 55 au moment de la rédaction initiale |
| `test-vf-notify.sh` | **18 PASS / 0 FAIL** (inchangé) |
| Parc complet | **66 suites découvertes / 66 OK / 0 KO** |
| `check-version-sync.sh` | exit 0 |
| `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents` | exit 0 |

Verdict de l'annexe : `33-VERIFICATION-ANNEXE.md` — **5/6 critères D-33-H ATTEINTS**, critère 1
`PARTIEL` au moment de la vérification, **fermé ensuite par `401c903`** (les deux `missing` qu'il
nommait — garde aux deux emplacements, cas N19 — sont livrés).
