# 68 — Relecture adverse SOBR-04 (plan 68-11, tâche 2)

- **Relecteur** : agent frais (Claude, sous-agent dépêché par la session principale). Il n'a écrit aucun commit de la Phase 68.
- **Date** : 2026-11-04.
- **Arbre relu** : branche `feat/phase-68-rel`, tête `0d4f8ae0`, base `main` à `19393cc3` (merge-base).
- **Cadre** : CLAUDE.md § Discipline de release, étape 2. Le périmètre de release est fixé par P68-D-31 (arbitrage Samuel,
  AskUserQuestion session principale Claude Code, 2026-11-04, « Module seul, racine groupée (Recommandé) »). Ni bump racine, ni tag, ni
  release : cette relecture alimente les notes de la **release groupée** à venir.
- **Verdict** : **aucun constat bloquant, trois constats à décider** (AD-1 à AD-3), à montrer à Samuel avant le merge.

## 1. Périmètre

Diff mesuré : `rtk proxy git diff v2.75.1..HEAD --stat -- plugin/` donne 123 fichiers, +10 525 / −392. Il se découpe en deux parts :

| Part | Commande | Volume |
|---|---|---|
| Phase 68 (relue) | `git diff 19393cc3..HEAD -- plugin/` | 71 fichiers, +6 079 / −70 ; 85 commits sans merge qui touchent `plugin/` |
| Mergé sur `main` depuis v2.75.1 (non jugé) | `git diff v2.75.1..19393cc3 -- plugin/` | 69 fichiers, +4 490 / −366 |

**Relu (Phase 68)** :
- le mod : `plugin/cockpit/signal/**`, soit `hooks/*.ts{,x}`, `views/*`, `types/index.d.ts`, `tsconfig.json`, `hooks.json` et les tests ;
- le socle : `vf-cockpit-signal.mjs` (nouveau), `vf-cockpit-arbres.mjs` (nouveau), `vf-cockpit-vie.mjs` (nouveau), ainsi que les changements de
  `vf-cockpit-who.mjs`, `vf-cockpit-planning.mjs`, `vf-cockpit-paths.mjs`, `vf-cockpit-avancement.mjs`, `vf-cockpit-project.mjs` et `vf-cockpit-interface.json` ;
- l'UI web : `00-vibeflow.js`, `70-vf-live.js` et `80-vf-fr.js` ;
- le manifeste `plugin/.claude-plugin/plugin.json`, qui gagne les clés `hooks` et `types` sans changer de version ;
- le test d'engine `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` (I9) ;
- la triade du module (`VERSION`, `module.json`, README et CHANGELOG, v1.1.2 → v1.2.0).

**Listé à part, non jugé** (mergé sur `main` entre v2.75.1 et `19393cc3`) :
- PR #195 : mémoire d'agents (audit 67), sans `plugin/` ;
- PR #196 : `DESIGN.md`, sans `plugin/` ;
- PR #197 : `driver-lock.sh` par phase. `conductor` passe de v1.52.1 à v1.53.0 (`driver-lock.sh`, `guard-driver-lock.sh`, `dag.sh`,
  `check-branch-claim.sh`, `check-guard-health.sh`, `team-kernel.md` et quatre suites) ; `dev-orchestrator` passe de v2.30.0 à v2.31.0 (`head-governance.md`,
  `mission-flow.md`, `mission-cross-team.md`, `check-mission-exit.sh` et `vf-dev-manager.md`) ;
- PR #198 : Phase 69, suivi du travail. `cockpit` passe de v1.0.1 à v1.1.1 : équipe, transcript, `avancement@1`, conductor voisin dans `driverLockScript` et UI ;
- PR #201 : H-1. `cockpit` passe à v1.1.2 avec `vf-cockpit-env.mjs` et `test-cockpit-path-enfants.sh`.

Racine : `git diff --name-only 19393cc3..HEAD -- VERSION plugin/.claude-plugin plugin/.codex-plugin .claude-plugin README.md README.fr.md CHANGELOG.md`
rend trois fichiers :
- `README.md` et `README.fr.md` : compte de suites 150 → 154 et un paragraphe sur la pane, sans badge ni historique ;
- `plugin/.claude-plugin/plugin.json` : clés `hooks` et `types` (commit `834e7b8c`, 68-04), sans version.

`VERSION` reste `v2.75.1`. `bash scripts/check-version-sync.sh` rend `✓ sources synchronisées (v2.75.1, 19 modules)`.

## 2. Constats

### Bloquant

Aucun.

### À décider (à montrer à Samuel avant le merge)

**AD-1 — Coût du rafraîchissement du mod, y compris hors session interactive.**
`plugin/cockpit/signal/hooks/register.tsx:60-62` et `:131`, `refresh.ts:69-71`.
- Une fois actif, le mod lance l'émetteur toutes les 10 s (`$.clock.every(10000, …)`), à chaque tour principal terminé et après tout `Bash`
  qui correspond à `/driver-lock|dag\.sh|git (commit|checkout|switch|merge)|gsd|vf-/`.
- Le minuteur tourne aussi quand la pane est fermée et en session **non interactive** (`claude -p`). Seule l'ouverture de la pane est
  conditionnée par `e.isInteractive`.
- `session.start` attend l'émetteur avant de rendre la main.
- Mesures (sondes S3 et S5) :
  - sur ce dépôt, chaque appel coûte environ **2,0 s de CPU** (user 0,98 + sys 1,09) et **120 Ko** de sortie, soit **environ 20 % d'un cœur
    en continu par session ouverte**, même au repos ;
  - en `claude -p` hors lab, `session.start` du mod a « settled in 290.8ms », puis l'émetteur est relancé toutes les 10 s jusqu'à la fin du processus.
- Avec le module installé en scope user, cela s'applique à **toute session de tout dossier**, y compris les `claude -p` enfants, par
  exemple l'agent confiné du cockpit.
- Options :
  - (a) accepter et dire le coût dans les notes ;
  - (b) n'armer le minuteur qu'en session interactive et ne pas attendre `refreshAll` dans `session.start` ;
  - (c) suspendre le minuteur quand la pane n'est pas affichée, ou l'espacer.
- Aucune correction faite (ADR-031).

**AD-2 — Plancher de version de Claude Code non annoncé, alors qu'il existe.**
`plugin/.claude-plugin/plugin.json:21`, clé `"hooks": "./cockpit/signal/hooks/hooks.json"`, fichier réduit à `modules`.
- Sous Claude Code **2.1.181**, le plugin VibeFlow entier journalise `[ERROR] Failed to load hooks from ./cockpit/signal/hooks/hooks.json for vibeflow`
  puis `Plugin loading errors: Hook load failed` à chaque session (sonde S5). Skills et commandes se chargent quand même : 0 hook enregistré,
  `types` ignoré.
- Sous **2.1.318**, le module de hooks se charge.
- Le README du module écrit « aucune version minimale ». C'est vrai de l'API, mais pas de l'effet : avant la 68, `plugin.json` ne déclarait aucun hook.
- Le plancher exact entre 2.1.181 et 2.1.318 n'est pas mesuré : seules ces deux versions sont présentes sur le poste.
- Options :
  - (a) dire dans les notes de release qu'une version ancienne de Claude Code journalise une erreur de chargement de hooks pour VibeFlow,
    et recommander 2.1.318 ou plus récent ;
  - (b) mesurer le plancher exact avant la release ;
  - (c) accepter sans le dire.

**AD-3 — `VF_COCKPIT_SCRIPTS_DIR` hérité par l'émetteur lancé par le mod.**
`socle.ts:54`, `env-sain.ts:46-48`, `vf-cockpit-paths.mjs:56-61` et `:72`.
- `$.process.run` pose `init.env` *par-dessus* l'environnement de l'hôte. Le mod ne fixe que `PATH`, donc `VF_COCKPIT_SCRIPTS_DIR` passe.
- Le socle prend cette variable comme dossier de scripts du module. Son `driver-lock.sh` est un candidat `module: true`, refusé seulement sous
  `<lab>/.vibeflow`, jamais sous le lab.
- La sonde S2b le montre : la variable pointée sur `<lab>/.claude/scripts` fait exécuter le `driver-lock.sh` planté dans le lab (témoin écrit
  4 fois en un appel).
- Vecteurs :
  - l'environnement de la personne ;
  - **hypothèse non mesurée** : le bloc `env` d'un `.claude/settings.json` de projet. Ce fichier peut déjà déclarer des hooks après la confiance
    accordée au dossier, donc il n'y aurait pas d'élévation nette.
- Le cas contredit pourtant la lettre de la garantie écrite (« le mod n'exécute jamais un fichier […] sous le lab »), qui ne couvre que
  les recherches propres du mod.
- Correctif minimal possible, non appliqué : le mod pose `VF_COCKPIT_SCRIPTS_DIR: ''` dans `init.env` (`trustedScriptsDir` exige un chemin absolu).
- Décision attendue : ce vecteur est-il dans le modèle de menace H-1 ?

### Mineur

- **M-1** — `signal/hooks/ds.ts:47` : `CONTROLES` ne retire pas les contrôles bidirectionnels (U+202A–U+202E, U+2066–U+2069), que le
  `nettoie` du socle retire (`vf-cockpit-arbres.mjs:54`). Le signal est couvert, puisqu'il passe par l'émetteur. Les descriptions d'agents
  (`$.agent.list`) et les raisons de refus des gardes ne passent que par `sansControle`. Risque : un affichage trompeur dans la pane.
- **M-2** — `register.tsx:164` : à chaque appel d'outil, la signature de boucle sérialise tous les arguments (`JSON.stringify(args)`),
  et les huit dernières sont gardées. Un `Write` de plusieurs Mo est donc copié et retenu. Coût marginal.
- **M-3** — `assets/ui/70-vf-live.js`, `ageDe` : `String(w.tree).includes(y.ws)` compare par sous-chaîne. Un compartiment dont le nom est
  contenu dans un autre peut prendre l'âge du mauvais verrou. Effet cosmétique.
- **M-4** — `plugin/cockpit/README.md`, § « D'où viennent les données » : la mesure citée (« 3 s, 14 worktrees, 108 338 octets ») est à
  remesurer (S3 : 1,8–2,1 s, 8 arbres, 120 757 octets). Le paragraphe ne dit ni le coût CPU ni que le minuteur tourne hors session interactive (lié à AD-1).
- **M-5** — Procédure. L'étape 3 de la tâche 2 du plan 68-11 demande de consigner les trois points de procédure « avec leur canal
  (AskUserQuestion, session principale Claude Code) ». Or `68-CONTEXT.md` les classe « documentés, sans arbitrage — consigne de la session
  principale, 2026-11-03 ». Ils sont consignés plus bas **tels que le CONTEXT**, et aucun arbitrage n'est inventé. Le libellé du plan est à corriger
  à la clôture.
- **M-6** — `cockpit/module.json` déclare `"requires": []`. Sans aucun `driver-lock.sh` trouvable (cockpit posé sans conductor, scope projet
  ou user), une mission dont un nœud est `running` sort « état inconnu » (S6), et non plus « en cours » comme avant la 68. C'est conforme
  à P68-D-23, mais à dire dans les notes.
- **M-7** — `claude plugin validate` signale `gating hook without .catch: command.run{command=vf-signal}`. Une exception dans
  `refreshAll` ferait échouer `/vf-signal` au lieu de passer la main. Informatif.

### Sans suite

- **Codex** : `plugin/.codex-plugin/plugin.json` est inchangé (`"hooks": {}`), donc la 68 n'a aucun effet sur ce runtime.
- **Mod chargé chez tout utilisateur du plugin** : sans `cockpit=` au registre, le mod reste inerte (P68-D-18, ST-1). Son coût se limite à
  deux lectures de fichier à `session.start`.
- **Registre `.vibeflow-installed` planté dans le lab** : il active l'affichage, rien de plus (P68-D-34). S2a le confirme : ni le script du lab,
  ni le lien du compte vers le lab, ni le `PATH` piégé, ni `core.fsmonitor` ne sont exécutés.
- **`driver-lock.sh` ancien installé chez l'utilisateur** :
  - dans le mod, le socle lit le `driver-lock.sh` du **cache du plugin**, via la règle du conductor voisin de la 69 : la copie installée n'est
    pas consultée ;
  - côté web, le repli F-04 (script d'avant `--all`) fonctionne (S6) ;
  - l'ancien `.planning/DRIVER.lock` compte comme verrou de dépôt (P68-D-33).
- **`avancement@1` → `@2`** : le sens de `running` change. Le changement est documenté dans le contrat (`vf-cockpit-interface.json`, `vieNulle`)
  et dans le CHANGELOG du module. Les consommateurs sont tous internes au module : mod, page Projet et vue Équipe.
- **Dépendance nouvelle** : aucune. Le mod n'importe que `claude-code`, et le socle n'utilise que `node:*`.
- **Fuite** : `signal@1` exclut `doing`, `mandat`, `messages` et `outils` (`interdits` du contrat). Toute chaîne passe par `nettoie`
  (masque des secrets, bornes) puis par `assainir`.
- **Contrats `who@2` et `signal@1`** : `who@2` est inchangé en forme. Il lit les arbres via `arbresGit` et neutralise `core.fsmonitor`
  sur ses `git` (`GIT_SUR`). `signal@1` est un schéma neuf, déclaré au contrat.

## 3. Arbitrés et documentés

Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, **2026-11-03**, relayés par SendMessage), réponses mot pour mot
recopiées de `68-CONTEXT.md` :

- **P68-D-22** (deux DAG d'un même compartiment, verrou de phase) : « Oui, par le verrou de phase (Recommandé) ».
- **P68-D-23** (source des verrous illisible) : « « État inconnu » ».
- **P68-D-24** (bloc backlog de la vue macro) : « Le retirer (Recommandé) ».
- **P68-D-25** (ordre du lanceur du cockpit) : « Le module posé dans le projet (Recommandé) ». Amendé ensuite par P68-D-34 (2026-11-04),
  « Rien sous le lab (Recommandé) » : compte, puis plugin, jamais le lab.

Arbitrage de Samuel (AskUserQuestion, session principale Claude Code, **2026-11-04**) :

- **P68-D-31** (périmètre de 68-11) : « Module seul, racine groupée (Recommandé) ». Le bump racine, le tag et la release GitHub sont
  reportés à la release groupée.

Points de procédure, **documentés sans arbitrage** : consigne de la session principale, 2026-11-03 (`68-CONTEXT.md` ; voir M-5) :

- **Version minimale de Claude Code** : aucun champ de version minimale n'est documenté pour les mods. La version de recette et de CI
  (2.1.318) est consignée. AD-2 ajoute un fait mesuré : 2.1.181 ne charge pas les hooks du plugin.
- **Délai de revue de Willy** : une PR qui touche `.github/` attend la revue `@picmakpro`. Ce délai est hors de la main de la mission.
- **Croisement des identifiants `who@2` et `$.agent.list()`** : constaté à la recette (68-10), pas tranché d'avance.

## 4. Sondes exécutées

Chaque commande est bornée par `perl -e 'alarm 300; exec @ARGV'`, et les mesures passent par `rtk proxy`. Les chemins de machine sont neutralisés :
`<arbre>` désigne le worktree relu, `$S` un dossier de travail jetable.

### S1 — Validation stricte du plugin (Claude Code 2.1.318)

```
$ perl -e 'alarm 300; exec @ARGV' claude plugin validate --strict plugin; echo "exit=$?"
  ❯ ./register.tsx hooks: session.start, session.end, command.run{command=vf-signal}, turn.start, turn.complete, agent.spawn, skill.prompt, tool.call, classic.PreToolUse, ui.render{component=AbovePrompt}, ui.render{component=Pane, requestId=?}
  ❯ ./register.tsx gating hook without .catch: command.run{command=vf-signal}
  ❯ ./register.tsx env writes: nothing
  ❯ ./register.tsx env reads: HOME, PATH
  ⚠ .claude-plugin/plugin.json icon: No icon (ICON_MISSING)   [avertissement d'annuaire, sans effet sur le résultat]
✔ Validation passed
exit=0
```

### S2 — Émetteur sur un lab jetable piégé : rien du lab n'est exécuté (témoins positifs établis)

Lab construit sous `$S/p2/lab` :
- un dépôt git avec `.planning/` plat ;
- un registre `.claude/scripts/.vibeflow-installed` (`cockpit=v1.2.0`) ;
- des scripts témoins qui écrivent leur nom dans `$S/p2/TEMOIN` : `.claude/scripts/driver-lock.sh`, `.claude/scripts/vf-cockpit.mjs`,
  `plugin/conductor/scripts/driver-lock.sh`, `bin/{git,bash,node}`, `./git` et `fsmon.sh`, ce dernier posé en `core.fsmonitor` du `.git/config` ;
- un `HOME` jetable dont `~/.claude/scripts/driver-lock.sh` est un lien vers le script du lab.

```
# S2a — négatif : PATH piégé (lab/bin, « . », lab), HOME au lien, fsmonitor piégé ; node appelé par chemin absolu
$ cd "$L" && env -u VF_COCKPIT_SCRIPTS_DIR HOME="$H" PATH="$L/bin:.:$L:<dir de node>:/usr/bin:/bin" \
    perl -e 'alarm 300; exec @ARGV' "$NODE" <arbre>/plugin/cockpit/scripts/vf-cockpit-signal.mjs "$L" > sortie-a.json; echo "exit=$?"
exit=0
témoin: ABSENT
{"schema":"vibeflow/cockpit-signal@1","layout":{"forme":"plat","actif":null},"phases":1,"verrous":{"etat":"lue","plat":true,"liste":[]},
 "arbres":[{"b":"main","r":{"base":"main","main":0,"origin":null,"fetchAgeS":null}}],"equipe":["schema","at","root","trees","fresh","fenetre","busy","workers","sources"]}

# S2b — témoin positif (et constat AD-3) : la même chose avec VF_COCKPIT_SCRIPTS_DIR=<lab>/.claude/scripts
$ cd "$L" && HOME="$H" VF_COCKPIT_SCRIPTS_DIR="$L/.claude/scripts" PATH="<dir de node>:/usr/bin:/bin" \
    perl -e 'alarm 300; exec @ARGV' "$NODE" <arbre>/plugin/cockpit/scripts/vf-cockpit-signal.mjs "$L" > /dev/null; echo "exit=$?"
exit=0
témoin: .claude/scripts/driver-lock.sh   (×4)

# S2c — témoins du piège lui-même : le PATH piégé résout bien le faux git, git brut déclenche bien fsmonitor
$ cd "$L" && env PATH="$L/bin:/usr/bin:/bin" /bin/sh -c 'command -v git; g=git; $g --version'
<lab>/bin/git
témoin: bin/git
$ /usr/bin/git status   →   témoin: fsmon.sh
```

S2a rejoué après S6, sans script trouvable (`VF_COCKPIT_SCRIPTS_DIR` vide, lien du compte refusé) : `exit=0`, `témoin: ABSENT`,
`verrous.etat = "absente"`.

### S3 — Taille et durée de la sortie

```
$ for i in 1 2 3; do /usr/bin/time -p perl -e 'alarm 300; exec @ARGV' node <arbre>/plugin/cockpit/scripts/vf-cockpit-signal.mjs <racine> > out.json; done
vibeflow-os (arbre principal)   exit=0  120 757–120 790 octets  real 1,78–1,95 s
vibeflow-os (worktree relu)     exit=0  128 148–128 152 octets  real 1,87–2,13 s
lab jetable S2                  exit=0  1 024 octets            real 0,25–0,33 s
CPU sur l'arbre principal (×3) : real 2.05 user 0.99 sys 1.09 · real 1.98 user 0.98 sys 1.10 · real 1.99 user 0.98 sys 1.08
Dépôt : arbres 8, phases 77, missions 27, verrous lue 3, workers 209 ; taille par clé : equipe 84 345, phases 19 345, missions 9 283, jalons 4 736
```

La sortie reste loin du plafond de `$.process.run` (4 Mio de stdout, typage de l'engine).

### S4 — Suite du mod (`claude plugin test`)

```
$ perl -e 'alarm 300; exec @ARGV' claude plugin test plugin; echo "exit=$?"
(pass) A1 — lanceur posé dans le lab : jamais lancé (P68-D-34) …
…
 153 pass
 0 fail
Ran 153 tests across 14 files. [4.67s]
exit=0
```

### S5 — Chargement réel, Claude Code ancien contre récent (AD-1, AD-2)

Configuration jetable (`CLAUDE_CONFIG_DIR=$S/cfg-<v>`), clé invalide et `ANTHROPIC_BASE_URL` vers un port fermé : aucun appel au modèle n'aboutit.

```
$ CLAUDE_CONFIG_DIR=$S/cfg-$v ANTHROPIC_API_KEY=sk-ant-invalide ANTHROPIC_BASE_URL=http://127.0.0.1:9 \
    perl -e 'alarm 90; exec @ARGV' <claude $v> --plugin-dir <arbre>/plugin --debug -p bonjour
# 2.1.181 (journal de debug)
[ERROR] Failed to load hooks from ./cockpit/signal/hooks/hooks.json for vibeflow: [ "hooks" …
[DEBUG] Plugin loading errors: Hook load failed: [ "hooks" …
[DEBUG] Registered 0 hooks from 1 plugins
[DEBUG] Loaded 1 skills from plugin vibeflow … · Total plugin commands loaded: 8
# (claude plugin validate sous 2.1.181 : « types: Unknown field 'types'. Claude Code ignores it at load time. » — passed with warnings)
# 2.1.318 (journal de debug)
[DEBUG] hooks module vibeflow@inline loaded (worker, environment 1, tier user); events: session.start,session.end,command.run,…
[DEBUG] session.start: raised (surface none, not interactive)
[DEBUG] hooks module vibeflow@inline session.start settled in 290.8ms (worker hop, next() included)
[DEBUG] $.process.run (vibeflow): node exited 0 in 259ms, 1024 + 0 chars      (15:28:56)
[DEBUG] $.process.run (vibeflow): node exited 0 in 321ms, 1024 + 0 chars      (15:29:06)
[DEBUG] $.process.run (vibeflow): node exited 0 in 243ms, 1024 + 0 chars      (15:29:16)
… toutes les 10 s jusqu'à la fin du processus
```

Le mod est actif ici parce que le vrai `~/.claude/scripts/.vibeflow-installed` du poste porte `cockpit=` (scope user). C'est le cas
d'un utilisateur réel.

### S6 — Compatibilité avec un `driver-lock.sh` d'avant `--all`

Imitation d'un `driver-lock.sh` ancien : `status --all` répond `Unknown arg: --all` sur stderr, `status` répond un verrou périmé. Le DAG
`MISSION-1` porte un nœud `running`.

```
$ VF_COCKPIT_SCRIPTS_DIR=$S/vieux HOME=$S/p2/home perl -e 'alarm 300; exec @ARGV' node <arbre>/plugin/cockpit/scripts/vf-cockpit-signal.mjs "$L"
vieux  {"verrous":{"etat":"lue","plat":true,"liste":[{"ws":"","scope":null,"phase":null,"tenu":true,"stale":true,"ageS":4000,"ttl":1800,"progressAgeS":3900,"owner":"vieux-manager"}]},
        "missions":[{"nom":"MISSION-1","etat":"abandonnee","libelle":"abandonnée, nœuds non refermés","vie":{"tenu":true,"stale":true,"progressAgeS":3900,"ttl":1800}}]}
absent {"verrous":{"etat":"absente","plat":false,"liste":[]},"missions":[{"nom":"MISSION-1","etat":"inconnu","libelle":"état inconnu","vie":null}]}
```

### S7 — Suites bash de la phase et synchronisation des versions

```
$ perl -e 'alarm 300; exec @ARGV' bash plugin/cockpit/scripts/tests/<suite>.sh
test-cockpit-signal      exit=0  77 PASS, 0 FAIL
test-cockpit-vie         exit=0  65 PASS, 0 FAIL
test-cockpit-signal-mod  exit=0  40 PASS, 0 FAIL
$ perl -e 'alarm 120; exec @ARGV' bash scripts/check-version-sync.sh | tail -1
[check-version-sync] ✓ sources synchronisées (v2.75.1, 19 modules)
```

## 5. Brouillon des notes de la release groupée — partie « Phase 68 »

> À compléter par le geste de release : numéro racine, liste finale des commits, et la mention « publiée dans VibeFlow vX.Y.Z » du CHANGELOG
> du module `cockpit`. AD-1 et AD-2 sont arbitrés (P68-D-41, 2026-11-04) et leurs phrases ci-dessous les reprennent ; AD-3 reste à trancher avant le merge.

**Cockpit v1.2.0 — vf-signal embarqué, socle partagé (Phase 68)**

- **Pane terminal `/vf-signal`, embarquée dans le plugin.** Elle est déclarée par `plugin/.claude-plugin/plugin.json` (clés `hooks` et `types`)
  et lue depuis le cache du plugin, jamais copiée chez l'utilisateur. Elle ne s'affiche que si le module `cockpit` est installé
  (registre projet, puis user). Vues mission, équipe et macro, plus un brief Markdown. Elle porte un bouton « Ouvrir le cockpit » et des gestes
  humains bornés : élaguer un verrou périmé, demander l'arrêt d'un agent, compacter, copier une commande.
- **Émetteur `vibeflow/cockpit-signal@1`.** Une seule source pour la pane : phases et leur avancement, jalons, missions et leur vie,
  verrous, worktrees avec leur retard sur la base (sans réseau), et l'équipe `who@2`. Toutes les chaînes sont nettoyées et bornées.
  L'échéance globale est de 15 s. Tous les `git` neutralisent `core.fsmonitor`.
- **Mission vivante (contrat `avancement@2`).** Une mission n'est « en cours » que si le verrou qui la couvre est tenu ou a progressé
  récemment. Le verrou se cherche dans l'ordre phase, compartiment, dépôt. Sinon la mission est « abandonnée, nœuds non refermés » ;
  si la source des verrous est illisible, elle est « état inconnu ». La page Projet du cockpit web partage cette règle.
- **Sécurité.** Le mod n'exécute aucun fichier dont le chemin réel tombe sous le lab. Ses lancements partent hors du lab, avec un PATH
  assaini (même classe que H-1). Un registre planté dans le lab ne fait qu'activer l'affichage.
- **Retiré** : la lecture maison du planning par le mod, les couleurs « Signal » (la pane passe en tokens Graphite) et le bloc backlog de la vue macro.
- **Ancien mod `~/.claude/mods/vf-signal`** : il est détecté et signalé (deux panes possibles). Son retrait reste un geste humain, décrit
  dans le README du module.
- **À savoir** :
  - la pane exige `node` dans le PATH de Claude Code ;
  - pane vf-signal vérifiée sous Claude Code 2.1.318 ; non chargée sous 2.1.181 (plancher exact non mesuré) (P68-D-41, arbitrage Samuel,
    AskUserQuestion session principale Claude Code, 2026-11-04, « L'écrire sans mesurer (Recommandé) ») ;
  - le rafraîchissement du mod est continu seulement pane ouverte et session interactive ; pane fermée, après un tour et au plus une fois par
    minute ; le mod n'attend jamais l'émetteur au démarrage (P68-D-41, « Rafraîchir si pane ouverte (Recommandé) », même canal, même date) ;
    coût remesuré (S3, 2026-11-04) : environ 1,8 à 2,1 s et environ 2 s de CPU par appel, 8 arbres, environ 120 Ko de sortie ;
  - cockpit installé sans `conductor` : pas de `driver-lock.sh` trouvable, donc une mission en cours s'affiche « état inconnu » (M-6, P68-D-23).

Commits depuis `v2.75.1` (`git log --oneline v2.75.1..<tête>`) : 270 au total. Ils comprennent les merges des PR #195, #196, #197, #198
et #201, déjà sur `main`, et 147 commits de la Phase 68 (`19393cc3..0d4f8ae0`, dont 85 touchent `plugin/`). Commits de code de la Phase 68,
du plus récent au plus ancien :
`9a433aea`, `93b61fd3`, `73c7557f`, `002a8b97`, `60cfc20b`, `8a7ff9d8`, `a3a09bb4` (bump du module v1.2.0), `a82e2ca0`, `e91b438a`, `aa5e803a`,
`f0673530`, `37c75dd0`, `7cef223d`, `6cebfdca`, `f90d58ce`, `d4342928`, `4c3702ad`, `f708d28e`, `828c0e7d`, `94fc249e`, `403074eb`,
`24ee4a76`, `f0912396`, `0db75d4a`, `c277f7fa`, `44963b25`, `3dcd6ee9`, `e327b284`, `1a7ccbb9`, `6a4d4a83`, `df6fff48`, `561d7903`,
`fce5c6f2`, `746ccc3c`, `b1baf598`, `0abcb95f`, `b1fe1915`, `4896a314`, `bad29f87`, `df5cc9b4`, `95ab2a30`, `fd1b2b1a`, `834e7b8c`.

Relecture adverse SOBR-04 : agent frais, 2026-11-04. Sonde représentative à recopier dans les notes (S2a et S2b, détail au § 4) :

```
$ cd <lab piégé> && env -u VF_COCKPIT_SCRIPTS_DIR HOME=<home au lien> PATH="<lab>/bin:.:<lab>:<node>:/usr/bin:/bin" \
    node plugin/cockpit/scripts/vf-cockpit-signal.mjs <lab>
exit=0 · témoin: ABSENT   (témoin positif : avec VF_COCKPIT_SCRIPTS_DIR=<lab>/.claude/scripts → témoin écrit, voir AD-3)
$ claude plugin test plugin → 153 pass, 0 fail · claude plugin validate --strict plugin → ✔ Validation passed
```

**Gestes humains restants, hors phase (release groupée)** :
1. Bump racine cohérent sous verrou de dépôt : `scripts/bump.sh`, historique des deux README et `CHANGELOG.md` racine.
2. Tag annoté, puis `git push origin vX.Y.Z`.
3. `gh release create --verify-tag`.
4. `scripts/check-release-tag.sh --remote`.
5. Compléter « publiée dans VibeFlow vX.Y.Z » dans `plugin/cockpit/CHANGELOG.md`.
