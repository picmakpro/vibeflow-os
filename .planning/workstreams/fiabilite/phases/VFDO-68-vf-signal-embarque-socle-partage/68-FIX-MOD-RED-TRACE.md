# 68-FIX-MOD — trace des témoins rouges et verts (correction ciblée du mod vf-signal)

Poste : Claude Code 2.1.318, `claude plugin test plugin`, tête de départ `69060360`. Sorties brutes dans le scratchpad (`fix-mod-*.out`).
Identifiants de témoins préfixés `FX-` (verdict.sh refuse un doublon). Un témoin rouge est joué sur le code NON corrigé.

## ST-1 — sans `cockpit=`, le mod travaille quand même (majeur)

Fichier : `plugin/cockpit/signal/tests/session-sans-registre.test.tsx`. Un lab sans ligne `cockpit=` joue un tour complet
(`session.start`, `turn.start`, `tool.call` Bash `driver-lock.sh`, `agent.spawn`, `turn.complete`, `command.run brief`) et espionne
`process.run`, `clock.every`, `ui.invalidate`, `state.set`, `agent.list`, `session.usage`. Le témoin positif FX-1d (registre
`cockpit=`) prouve que les espions voient bien le travail du mod.

ROUGE (tête non corrigée, `fix-mod-st1-rouge.out`) :

| témoin | assertion | attendu | obtenu |
| --- | --- | --- | --- |
| FX-1a | process.run lancés | `[]` | 2 × `node …/cockpit/scripts/vf-cockpit-signal.mjs /lab` |
| FX-1b | argv contenant `vf-cockpit-signal.mjs` (vrai nom) | `[]` | 2 lancements |
| FX-1e | minuteries posées | 0 | 1 |
| FX-1f | `ui.invalidate` | 0 | 1 |
| FX-1g | `state.set` | 0 | 13 |
| FX-1h | `[agent.list, session.usage]` | `[0, 0]` | `[2, 1]` |
| FX-1c | `/vf-signal brief` | `{ text: 'engine' }` | vert (le gating de `command.run` existe déjà ; sa mutation est jouée plus bas) |

VERT (`fix-mod-st1-vert.out`, 71 pass / 0 fail) : `register.tsx` porte `if (!actif) return next(e)` en tête de `turn.start`,
`turn.complete`, `agent.spawn`, `skill.prompt`, `tool.call` et `classic.PreToolUse` (les autres hooks l'avaient déjà).

Mutants tués (un gate retiré à la fois, suite rejouée) :

| mutant | témoins rouges |
| --- | --- |
| gate de `command.run` retiré | FX-1a, FX-1g, FX-1h, FX-1b, FX-1c |
| gate de `tool.call` retiré | FX-1a, FX-1g, FX-1b |
| gate de `turn.start` retiré | FX-1e, FX-1f, FX-1g |
| gate de `agent.spawn` retiré | FX-1g, FX-1h |

## ST-3, ST-4, ST-5, ST-6 — témoins rouges (tête avec le correctif ST-1, sortie `fix-mod-st346-rouge.out` : 18 fail, tous des FX-, les autres suites vertes)

Fichiers : `tests/lab-fix.ts` (faux lab pilotable : émetteur, bash, lanceur, toasts, copies), `tests/socle-fix.test.tsx` (ST-5, ST-6a/b),
`tests/citation-controles.test.tsx` (ST-3, ST-4, ST-6c/d).

| témoin | assertion | attendu | obtenu (tête non corrigée) |
| --- | --- | --- | --- |
| FX-5a0..FX-5a6 | signal sans `verrous.liste`, `jalons`, `layout`, `equipe`, `n` numérique, `avancement.plans`, `arbres[].label` : texte « sortie de l'émetteur illisible » | texte trouvé | `$.ui.mount: no implementation for ui.render` (le rendu lève) pour a0..a3 ; texte absent pour a4..a6 |
| FX-5b | émetteur rejeté `EACCES` : `/émetteur non lancé \(EACCES/` et pas `/délai dépassé/` | trouvé / absent | texte absent (la pane dit « délai dépassé ») |
| FX-5c | lanceur rejeté `EACCES` : idem `lanceur non lancé` | idem | idem |
| FX-6a | lanceur rejeté `timed out after 60000 ms` : « lanceur sans réponse (délai dépassé) » | trouvé | vert (garde contre le sur-correctif : tout rejet dit « non lancé ») |
| FX-6b | lecture réussie, puis `exit 1` : plus de « phase 68 », « émetteur en échec (code 1) » dit ; puis relecture réussie : tout revient | idem | vert : la propriété réelle du code est « l'échec remet `signal` à `null` et pose l'erreur » (refresh.ts) ; le mutant est joué plus bas |
| FX-6c | toast `recover · exit 3 · <120 x>` (sortie de 200 bornée) ; `recover · exit 0 · verrou élagué` | toasts contenant | vert (le contenu n'était asserté nulle part ; mutants plus bas) |
| FX-6d | script qui ne démarre pas : « recover : driver-lock.sh ne démarre pas » | idem | vert (idem) |
| FX-3b | chemin `/lab dir/...` et `ws` = `a b';touch /tmp/pwn;`id`$(id) #` : la commande copiée se découpe (découpeur POSIX du témoin, FX-3a prouve qu'il sait rougir) en `bash`, script, `takeover`, `--owner=ID`, `--ws=<ws>` | découpe exacte | `Error: guillemet simple non fermé : bash /lab dir/.../driver-lock.sh takeover --owner=<id> --ws=a b';touch /tmp/pwn;...` |
| FX-3c | sans caractère spécial, la commande reste `bash <script> takeover --owner=<id> --ws=fiabilite` (aucun guillemet inutile) | motif | vert (garde contre le sur-correctif) |
| FX-4a0 | toast d'élagage portant `ESC[31m`, `ESC]0;`, BEL, C1, un saut de ligne : aucun contrôle, aucune ligne forgée | pas de `[\x00-\x1f\x7f-\x9f]` | `recover · exit 0 · rouge\u001b[31m fin\u001b]0;titre\u0007 c1\u009b31m bel\u0007- faux verrou : intrus` |
| FX-4a1..a4 | brief : `agent.description`, raison de refus, `projet`, `owner` du verrou | idem | contrôles et ligne `- faux verrou` forgée dans le Markdown |
| FX-4a5 | bandeau : `owner` du verrou périmé | idem | contrôles dans le texte |
| FX-4a6, FX-4a7 | pane : `owner` du verrou (`cut`, sans `oneLine`), nom de phase (`oneLine` identité sur les contrôles) | pane dessinée | `$.ui.mount: vibeflow drew nothing … a text child holds a control character (an escape sequence)` : l'engine refuse la pane entière |

Rectification du rouge de FX-4a2 : le témoin avait d'abord échoué pour une mauvaise raison (le refus n'était pas enregistré : le hook
du faux engine rendait `{ result: { deny } }` au lieu de `{ deny }`). Corrigé dans le test, puis rejoué sur le code non corrigé
(`fix-mod-st346-rouge2.out`, 77 pass / 18 fail) : FX-4a2 rougit alors sur la ligne `Expected: not /[\u0000-\u001f\u007f-\u009f]/`.

## Correctifs et VERT (`fix-mod-st346-vert.out`, 95 pass / 0 fail)

- ST-4 : `ds.ts` — `sansControle` (C0, DEL, C1, U+2028/2029 → espace), `oneLine` s'appuie dessus, `nettoyer` (copie profonde). Le signal
  (`refresh.ts`), la liste des agents et les refus y passent à l'entrée ; le toast d'élagage passe par `oneLine` (`actions.ts`).
  Le brief n'a pas besoin de sa propre passe : un mutant qui l'ajoutait ne tuait aucun témoin, il n'a pas été gardé.
- ST-3 : `shell.ts` (`cite`), `boutons.tsx` cite le chemin du script et le mot `--ws=<ws>`. `--owner=<id>` reste un gabarit nu : collé
  tel quel, le shell lit `<id>` comme une redirection et refuse, c'est voulu (la personne doit nommer le propriétaire).
- ST-5 : `socle.ts` — `complet()` contrôle la forme que les vues lisent sans garde ; `classerEchec` (partagé avec le lanceur) distingue
  node absent, vrai délai (`timed out`/`timeout`/`délai`) et « non lancé (<cause bornée à 60>) », en retirant le préfixe `<plugin>: $.process.run:`.
- ST-6 : la propriété réelle de `refresh.ts` est « un échec remet `signal` à `null` et dit l'erreur » (FX-6b).
- ST-7 : commentaire de `resoudreLanceur` aligné (« la fonction rend toujours un chemin »).

Mutants (un seul changement à la fois, suite complète rejouée, `hooks/` restauré après chaque) :

| mutant | témoins rouges |
| --- | --- |
| `oneLine` redevient l'identité | FX-4a0, FX-5b, FX-5c, FX-6c |
| `sansControle` redevient l'identité | FX-4a0 à FX-4a7 |
| `cite` redevient l'identité | FX-3b |
| `complet()` retiré | FX-5a0 à FX-5a6 |
| `n` n'est plus exigé en chaîne | FX-5a4 |
| `classerEchec` rend toujours « délai dépassé » | FX-5b, FX-5c |
| `classerEchec` ne reconnaît plus le délai | FX-6a, K13 |
| `signal` n'est plus remis à `null` après un échec | FX-6b |
| toast sans borne de 120 / sans code de sortie | FX-6c |
| `nettoyer` retiré à l'entrée du signal | FX-4a5, FX-4a6 |

Non-régression : `claude plugin validate --strict plugin` ✔ (`fix-mod-validate.out`) ; `test-cockpit-signal-mod.sh` bash et zsh 40 ok / 0 ko
(`fix-mod-static-bash.out`, `fix-mod-static-zsh.out`) ; `check-machine-paths.sh` ✓ 2481 fichiers (`fix-mod-machine-paths.out`).
La suite statique n'a pas été touchée : pas de trailer `Gate-Touche:`.

# Passe 2 (RV-1, RV-2, RV-3) — après `git merge --ff-only feat/phase-68-vf-signal` (6b76c42c)

Fichiers : `tests/fixture-plat.ts` (sortie RÉELLE de l'émetteur sur un lab plat, capturée par la re-revue ; seules `root` et `equipe.root` ramenées à `/lab`,
aucun chemin de machine), `tests/reel.test.tsx` (FX-7, FX-8), `tests/session-sans-registre.test.tsx` (FX-1i, FX-1j).

## Rouge (hooks de la passe 1, `fix-mod-p2-rouge.out`, `fix-mod-p2-rouge2.out`)

| témoin | assertion | attendu | obtenu |
| --- | --- | --- | --- |
| FX-7a | sortie réelle d'un lab plat : pas de « sortie de l'émetteur illisible », « phase 1 Un » affichée, trois vues, « sans portée » | texte illisible absent | « sortie de l'émetteur illisible » présent (`complet()` rejette `scope: null` et `retard.base: null`) |
| FX-7b | idem : bandeau, compact, brief | pas de levée, « verrou dépôt : t · sans portée » | compact sans « phase 1 Un » |
| FX-7c | SIGNAL de référence, `scope: null` seul | accepté | illisible |
| FX-7d | `retard.base: null` seul | accepté, aucun « en retard » | illisible |
| FX-7e | `scope: 7` | reste illisible | vert (la tolérance est bornée) |
| FX-8a | `projet` avec U+2028 et U+2029 : brief `- projet : avant - faux apres`, aucune ligne forgée | idem | vert (témoin d'une entrée de `CONTROLES` qui n'en avait pas) |
| FX-1i / FX-1j | sans `cockpit=`, `skill.prompt` + `tool.call` refusé par le garde classique : 0 écriture ; avec `cockpit=` : plus d'une | idem | vert (les gates existaient ; témoins ajoutés, mutants plus bas) |

Le rouge initial de FX-7b a d'abord été « no implementation for ui.render » (le montage du bandeau demandait un moteur) : stub `ui.render` ajouté, puis rejoué.
Note : `classic.PreToolUse` n'est pas appelable en `$.classic` ; il passe par `$.tool.call` (doc du moteur de test).

## Correctifs et vert (`fix-mod-p2-vert.out`)

- `socle.ts` : `scope` et `retard.base` acceptent chaîne ou null (`textOuNull`) ; tout autre type reste illisible.
- `types/index.d.ts` : `scope: string | null`, `base: string | null`, avec leur raison.
- `en-tete.tsx` : sans base, aucun retard n'est dit ; `mission.tsx` et `derive.ts` : un verrou sans portée s'écrit « sans portée » (jamais « null »).

## Mutants (suite complète rejouée, `hooks/` restauré après chaque)

| mutant | témoins rouges |
| --- | --- |
| gate de `skill.prompt` retiré | FX-1g, FX-1i |
| gate de `classic.PreToolUse` retiré | FX-1g, FX-1i |
| U+2028/U+2029 retirés de `CONTROLES` | FX-8a |
| `scope` redevient chaîne stricte | FX-7a, FX-7b, FX-7c |
| `retard.base` redevient chaîne stricte | FX-7a, FX-7b, FX-7d |
| garde `base === null` de `retardDe` retirée | FX-7a, FX-7d |
| « sans portée » retiré de `derive.ts` / de `mission.tsx` | FX-7b / FX-7a |
