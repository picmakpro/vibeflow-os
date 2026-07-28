# Prompt — la mise à jour VibeFlow ne migre jamais le moteur GSD vers `@opengsd/gsd-core`

> À coller tel quel dans une session VibeFlow (scope mainteneur).
> Écrit le 28/07/2026, à partir d'un constat fait sur le lab `ExploreSomfy`,
> migration jouée à la main le jour même et instrumentée pour ce rapport.

---

Tu interviens sur VibeFlow, dont je suis le mainteneur. Il y a un trou dans la chaîne
de mise à jour, et il est silencieux : **la migration `get-shit-done-cc` →
`@opengsd/gsd-core` livrée en v2.39.0 (26/07) ne s'applique à aucun poste déjà
équipé.** Elle ne profite qu'aux installations neuves. Sur mon lab, elle n'avait
toujours pas eu lieu **12 jours après** l'install initiale et **2 jours après** la
livraison de la migration, alors que le plugin, lui, était bien à jour.

Les constats ci-dessous sont vérifiés sur pièce le 28/07, pas supposés. Chacun porte
la commande ou le fichier qui l'établit.

## Le constat, en une phrase

`/vf-update` met à jour **le plugin et les modules**, jamais **le moteur** ; et le
seul script qui saurait migrer le moteur (`ensure-deps.sh`) n'est appelé par aucun
chemin de mise à jour — et, même appelé, il aurait sauté la migration à cause d'un
early-return.

## Preuve — état du poste avant intervention

| Ce qui était à jour | Ce qui ne l'était pas |
|---|---|
| Plugin VibeFlow **2.42.0**, cache rafraîchi le 28/07 à 09:35 | Moteur GSD : `~/.claude/get-shit-done/VERSION` = **1.42.3**, posé le **16/07** |
| `ensure-deps.sh` matérialisé en version migrée (installe bien `@opengsd/gsd-core@^1`) | `~/.claude/gsd-core/` **absent** ; cache npx sans aucune trace d'`@opengsd` — seulement `get-shit-done-cc@1.42.3` |
| Node v26.5.0 (la garde Node ≥ 22 n'a jamais été un obstacle) | `get-shit-done-cc` est **déprécié sur npm** (« Package no longer supported »), figé, pendant que `@opengsd/gsd-core` est en **1.8.0** |

Autrement dit : le poste portait le *code* de la migration sans en porter l'*effet*,
et rien dans l'interface ne le disait.

---

## Trou 1 — `/vf-update` ne touche pas au moteur, et ne prétend pas le contraire

**Constat.** Le skill `vf-update` fait trois choses : `check-plugin-update.sh`,
`claude plugin update vibeflow@vibeflow-os`, puis `vf-update-run.sh` → engine
`update --all`. Ce dernier re-matérialise `skills/agents/rules/scripts`. **Aucune de
ces étapes n'appelle `ensure_gsd()`.** Vérifié : `grep -rl "ensure-deps"` sur
`~/.claude` ne remonte que `vf-init/SKILL.md`, `vf-calibrate/SKILL.md`,
`inject-mcp-tools.sh` (commentaire) et le script lui-même. Ni hook, ni engine.

**Pourquoi c'est un trou et pas un choix.** Le moteur GSD est une **dépendance
déclarée** de VibeFlow, installée par VibeFlow, dont la version est décidée par
VibeFlow (`@^1`, arbitrage post-audit Phase 11). Une dépendance qu'on choisit mais
qu'on ne met jamais à jour n'est pas une dépendance, c'est un legs. Le message final
de `/vf-update` — « Modules à jour sur disque » — est donc **exact et trompeur à la
fois** : l'utilisateur en déduit que son installation est à jour.

---

## Trou 2 — `detect_gsd()` fait un early-return sur le layout legacy

**Constat.** `~/.claude/scripts/ensure-deps.sh`, ligne 120 :

```sh
detect_gsd() { [ -f "$GSD_VERSION_FILE_NEW" ] || [ -f "$GSD_VERSION_FILE_LEGACY" ]; }
```

et ligne 130, dans `ensure_gsd()` :

```sh
if detect_gsd && ! { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; }; then
  log "GSD déjà présent (skip)."
```

Un poste legacy satisfait la condition par `~/.claude/get-shit-done/VERSION`. Donc
**même si `/vf-update` appelait `ensure-deps.sh`, la migration ne se déclencherait
pas.** Le `||` a été écrit pour la tolérance au dual-layout (le nouveau peut coexister
ou non, Phase 10) ; il produit ici l'effet inverse de celui recherché — il **protège
le legacy** au lieu de le remplacer.

La détection par fichier VERSION est le bon choix (le piège n°1 du `command -v` est
correctement neutralisé, et documenté). Le défaut n'est pas la méthode, c'est
l'absence de distinction entre « GSD est présent » et « **le bon** GSD est présent ».

---

## Trou 3 — le seul signal existant vit sur un chemin que personne n'emprunte

**Constat.** `log_legacy_cleanup_if_needed()` affiche bien les étapes de nettoyage
manuel quand le legacy est détecté (ADR-031 respecté : affiché, jamais exécuté). Mais
il n'est appelé que depuis `ensure_gsd()` — donc uniquement via `/vf-init` ou
`/vf-calibrate`. Sur un poste en régime nominal, qui met à jour et travaille, **ce
message n'a aucune occasion d'être imprimé**. Le garde-fou est correct et inatteignable.

Effet de bord à corriger au passage : après une install `gsd-core` réussie,
l'installeur amont **supprime lui-même le `VERSION` legacy**. `detect_gsd_legacy()`
devient donc faux immédiatement, et le message de nettoyage **ne peut plus jamais
sortir après coup**. Les 3 étapes qu'il propose sont d'ailleurs partiellement
périmées : sur mon poste, `npm ls -g` ne contenait **ni** `get-shit-done-cc` **ni**
`@gsd-build/sdk` (l'install s'était faite en `npx`, jamais en global), donc deux
lignes sur trois auraient été des no-op ; la seule utile — `rm -rf
~/.claude/get-shit-done` — porte sur une arborescence que l'installeur a **vidée de
ses 200+ fichiers mais laissée debout**, dossiers vides compris.

---

## Trou 4 — le numéro de version du successeur est INFÉRIEUR à celui du legacy

**Constat, et c'est le piège le plus vicieux du lot.** Le fork repart de zéro :

```
get-shit-done-cc   1.42.3   (déprécié, figé)
@opengsd/gsd-core   1.8.0   (vivant)
```

**1.8.0 < 1.42.3 en semver.** Tout comparateur naïf — et `check-plugin-update.sh`
compare bien des versions — conclura « installé ≥ dernier, rien à faire », voire
« downgrade refusé ». La doctrine « ne jamais downgrader » du skill `vf-update`, qui
est saine partout ailleurs, **interdit précisément le geste qu'il faut faire ici**.

À écrire noir sur blanc dans le détecteur : **la migration se décide sur le nom du
paquet et le layout du dossier, jamais sur la comparaison des numéros.** Un test de
non-régression sur ce couple exact (1.42.3 → 1.8.0 doit être classé « à migrer »)
vaut la peine d'exister.

À vérifier de ton côté, je n'ai pas pu le mesurer : le hook `gsd-check-update` du
moteur **legacy** interrogeait selon toute vraisemblance `get-shit-done-cc` — un
paquet déprécié et figé — et annonçait donc « à jour » à perpétuité. La version
`gsd-core` du worker, elle, source correctement `PACKAGE_NAME` depuis
`gsd-core/bin/lib/package-identity.cjs`. Je ne peux pas le prouver : j'ai écrasé le
hook legacy en migrant.

---

## Trou 5 — l'install de `gsd-core` défait l'injection MCP de VibeFlow (ADR-051)

**Constat, mesuré pendant la migration.** L'installeur `gsd-core` réécrit
`agents/gsd-executor.md` et a détecté une « local patch » qu'il a mise de côté dans
`~/.claude/gsd-local-patches/` :

```
avant (patché)  tools: Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*, mcp__XcodeBuildMCP__*
après (neuf)    tools: Read, Write, Edit, Bash, Grep, Glob, Skill, mcp__context7__*, mcp__plugin_context7_context7__*
```

`mcp__XcodeBuildMCP__*` **a disparu**. Or ce n'est pas une modification personnelle :
c'est l'injection ADR-051 posée par `inject-mcp-tools.sh --force` depuis
`ensure-deps.sh`. L'installeur amont, qui ne connaît pas VibeFlow, la classe en patch
utilisateur et propose `/gsd-update --reapply` — **le mauvais instrument** : le bon
est le ré-affirmation idempotente de `ensure-deps.sh`, qui a effectivement restauré la
ligne quand je l'ai relancé.

**Ce que ça implique pour l'automatisation que je te demande** : toute migration
automatique du moteur **doit** enchaîner sur la ré-injection, sans quoi
`gsd-executor` perd silencieusement son accès MCP. Sur ce lab précis, la conséquence
serait franche : le `CLAUDE.md` interdit `xcodebuild` en shell, donc un exécutant
privé de XcodeBuildMCP ne peut plus builder du tout — ou le fait par le chemin
interdit.

**Et ce n'est pas couvert par le chemin d'update actuel** : `vibeflow-update.sh`
n'injecte que dans `$TARGET_ROOT/agents` sur les agents flaggés
`vf-mcp-consumer: true` — chez moi, `vf-coder` seul. `gsd-executor`, qui n'a pas le
flag et exige `--force`, n'est servi que par `ensure-deps.sh`. Deux chemins, une seule
couverture.

---

## Ce que je veux

1. **Un détecteur de moteur qui distingue « présent » de « bon ».** Remplacer le
   `||` de `detect_gsd()` par un état à trois valeurs — absent / legacy / gsd-core —
   et faire de « legacy » un cas **actionnable**, pas un skip. Décidé sur le layout et
   le nom du paquet, **jamais** sur les numéros de version (trou 4).
2. **Brancher la vérification du moteur sur `/vf-update`.** Au minimum : la
   **détecter** et la **dire**, dans le même récapitulatif que le plugin et les
   modules. Au mieux : la proposer dans la confirmation ADR-031 existante, comme une
   ligne de plus (« moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` 1.8.0 ») que je
   peux accepter ou refuser. **Pas d'exécution sans validation humaine** — ce point
   n'est pas négociable, voir plus bas.
3. **Faire de la ré-injection MCP une étape de la migration, pas une conséquence
   heureuse.** Toute installation ou réinstallation du moteur enchaîne sur
   `inject-mcp-tools.sh --force` pour `gsd-executor`. Idéalement avec une
   **vérification après coup** : si le `tools:` final ne contient pas les serveurs du
   `.mcp.json` du lab, le dire fort.
4. **Rendre le message de nettoyage atteignable**, et le corriger : ne proposer
   `npm uninstall -g` que si le paquet est effectivement installé en global, et
   inclure le retrait de l'arborescence vide laissée par l'installeur.
5. **Un test de cohabitation qui couvre le cas réel** : poste legacy 1.42.3 déjà
   installé + plugin à jour → la migration doit être **détectée**. La suite
   `test-gsd-cohabitation` livrée en v2.39.0 teste le settings.json de l'installeur ;
   elle ne teste pas ce scénario-là, sinon il aurait été vu.

## Non-négociables

1. **Aucune migration silencieuse.** ADR-031 tient : détecter et proposer, jamais
   installer sans mon accord. Le moteur GSD porte les skills qui portent le planning
   de mes projets — une bascule non annoncée en pleine phase de livraison est
   exactement ce qu'il ne faut pas.
2. **Ne pas résoudre ça en pinant une version.** Le plafond `@^1` est le bon
   arbitrage et je n'y touche pas.
3. **Ne pas supprimer le layout legacy en repli** de `detect-gsd-engine.sh` /
   `build-gsd-index.sh` : la cascade à 4 niveaux doit continuer à fonctionner pour les
   postes qui n'ont pas encore migré. C'est le **skip** qu'il faut corriger, pas le
   repli.

---

## Annexe — le déroulé exact de la migration manuelle (reproductible)

Joué le 28/07 sur `ExploreSomfy`, scope user, à titre de référence pour
l'automatisation. Durée totale : environ 4 minutes.

```sh
# 0. Sauvegarde préalable (1,2 Mo) — l'installeur écrase skills, agents et hooks
tar czf gsd-legacy-backup.tgz -C ~/.claude get-shit-done gsd-file-manifest.json \
    gsd-install-state.json .gsd-profile settings.json skills/gsd-* agents/gsd-*

# 1. Install (non interactif, scope user → --global)
npx -y "@opengsd/gsd-core@^1" --claude --global

# 2. Ré-affirmer l'injection MCP effacée par l'install (trou 5)
VF_SCOPE=user bash ~/.claude/scripts/ensure-deps.sh

# 3. Nettoyage de l'arborescence vide laissée derrière
rm -rf ~/.claude/get-shit-done
```

**Résultat mesuré :**

| Avant | Après |
|---|---|
| `get-shit-done` 1.42.3 | `gsd-core` **1.8.0**, marqueur `.gsd-runtime: claude` |
| 67 skills `gsd-*`, 33 agents | **71** skills, **34** agents |
| — | 6 hooks ajoutés (`gsd-config-reload`, `gsd-worktree-path-guard`, `gsd-graphify-update`, context-monitor sur `Stop`/`SubagentStop`/`PreCompact`) |
| — | **aucun hook VibeFlow supprimé** (diff des `hooks` de `settings.json` : 6 ajouts, 0 retrait) |
| — | `gsd-tools.cjs` opérationnel, lit bien le `.planning/` du projet (8 phases listées) |
| — | dépôt du projet **inchangé** (7 entrées `git status`, identiques avant/après) |

Deux avertissements de l'installeur à connaître, tous deux bénins ici :
« Skipping statusline (already configured) » (VibeFlow garde la sienne) et la
détection de la « local patch » du trou 5.

## Annexe — ce que ce trou dit du reste

Le schéma est le même que pour `check-agents.sh` (voir le prompt du 28/07 sur la
fluidité) : **un garde-fou correctement écrit, branché sur un chemin que le régime
nominal n'emprunte jamais.** Là c'était le scope du dossier `agents`, ici c'est le
chemin d'appel de `ensure-deps.sh`. Ça vaut peut-être une passe transverse : pour
chaque script de `scripts/`, **qui l'appelle en régime nominal ?** Ceux dont la
réponse est « personne, sauf `/vf-init` » sont des garde-fous décoratifs.

Et si tu constates qu'un de ces cinq constats est faux ou daté, dis-le : ils viennent
d'un seul poste, un seul lab, un seul scope (user).
