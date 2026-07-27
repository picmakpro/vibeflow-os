# Mission — Phase 16 : Cloisonnement complet des dispatches d'agents

**Date** : 2026-07-27 · **Manager** : `vf-dev-manager` · **Owner du lock** : `mission-phase16`
**Commit de base** : `69086d8` · **7 commits de mission** · **Mode** : autonome (cadrage + exécution de bout en bout)

> ⚠️ **Historique partagé** : une autre session a travaillé sur ce dépôt **pendant** la mission
> (Phases 17 et 18 — commits `1e263bd`, `fb80177`, `9d1828e`, `d937174`, plus des modifications non
> commitées sur `ROADMAP.md`/`STATE.md`). Ces commits sont **intercalés** dans l'historique et
> n'appartiennent pas à la Phase 16. Toute mesure de régression a été faite contre `69086d8`,
> jamais contre `HEAD~n`.

---

## Plan de bataille (DAG, 11 nœuds, 2 ré-entrées)

```
panel-lint ──────────────→ exec-lint ──┬→ mutation ─┐
recon-a ─┬→ reconcile → exec-allowlists┴→ review ───┴→ gates → hygiene → release-meta
recon-b ─┘
```

Trois frontières dispatchées **en parallèle** (périmètres de fichiers disjoints, déclarés dans
chaque mandat) : `panel-lint ∥ recon-a ∥ recon-b`, puis `exec-lint ∥ exec-allowlists`, puis
`mutation ∥ review`, puis `exec-lint(fix) ∥ hygiene`. **Deux ré-entrées** (`dag.sh reopen`)
déclenchées par les juges. Clôture : 9/9 nœuds effectifs `done`.

---

## Livrable A — le lint réel des allowlists `Agent(...)`

`plugin/conductor/scripts/check-agents.sh` ne lisait **jamais** le contenu du champ `tools:` : des
noms inventés, une parenthèse non fermée ou des outils inexistants passaient `--strict` en vert.

### Comment le piège des agents natifs/externes a été résolu

Le piège qui avait fait renoncer la Phase 15 : un lint exigeant `<agents-dir>/<nom>.md` rendrait
rouges des allowlists **correctes**. Trois familles de noms légitimes ne résolvent pas vers un
fichier : les types **natifs** sans `.md` (`general-purpose`, `Explore`, `Plan`…), les agents
**tiers** `gsd-*` du paquet `@opengsd/gsd-core`, et les agents d'un **autre module VibeFlow non
installé** (l'allowlist de `vf-dev-manager` cite `vf-crafter`/`vf-design-judge`, qui vivent dans
`design-orchestrator`).

**Résolution retenue — résolution graduée, auto-contenue dans le script.** Le principe : *la
sévérité dépend de ce qui est vérifiable indépendamment du périmètre installé.*

| Classe | Défaut | `--strict` | `--resolve-agents=strict` |
|---|---|---|---|
| Syntaxe (parenthèses, allowlist vide, entrée vide, charset, espace) | **ERREUR** | ERREUR | ERREUR |
| Nom d'outil hors set fermé documenté | WARNING | **ERREUR** | — |
| Nom d'agent non résolu | WARNING | **WARNING (inchangé)** | **ERREUR** |
| `Agent` nu (aucune allowlist) | WARNING | WARNING | — |

**Le point décisif : `--strict` ne durcit PAS « nom non résolu ».** Le monde fermé est **opt-in**,
réservé à la CI — seul endroit où l'univers des agents est réellement connu. Sinon la CI par module
virerait rouge sur **22 entrées parfaitement saines** (mesuré), rejouant le sinistre déjà tracé des
66 faux positifs sur le scope user.

**Justification documentaire** : la doc officielle **ne fige pas** la liste des types natifs
(marqueurs `min-version`, `output-style-setup` disparu, désactivation par variable d'environnement,
override possible par un agent utilisateur). Faire de « nom non résolu » une erreur serait un pari
sur une liste qui bougera. La rouille de la liste dégrade donc en **warning**, jamais en rouge.

**Option « manifeste externe » écartée sur preuve de code** : `copy_module_scripts()`
(`plugin/_internal/vibeflow-update.sh:337-352`) ne globbe que `*.sh|*.mjs|*.js` — un fichier de
données ne serait **jamais posé** chez l'utilisateur. C'est le mécanisme exact qui a fait manquer
`known-versions.txt`. Toutes les listes sont donc **inline dans le script**.

Flags livrés : `--third-party-prefix=PFX` (défaut `gsd-`, accumulatif) · `--no-third-party-prefix` ·
`--resolve-agents=lenient|strict` (valeur invalide **rejetée**) · `--agent-registry-dir=PATH`.
Alias `Task(...)` traité à l'identique de `Agent(...)`. Tokenizer générique (`Bash(git:*)`,
`mcp__*`…) à **profondeur de parenthèses**. Un run « monde fermé » ajouté dans `ci.yml`.

### Portée réelle — sans surestimation

> « `Agent(agent_type)` applies only to an agent running as the main thread with `claude --agent`.
> In a subagent definition […] **any type list inside the parentheses is ignored.** »
> — https://code.claude.com/docs/en/sub-agents

Une allowlist sur un agent **dispatché en sous-agent** n'est donc **pas un bac à sable runtime** :
c'est un **contrat documenté, désormais enforcé par ce lint**. Le **verrou de driver** reste le
garant machine de « un seul manager actif ». Corrigé en conséquence dans `conductor/README.md`,
`team-kernel.md`, `mission-cross-team.md` et l'en-tête du script.

---

## Livrable B — le recensement consolidé des trois allowlists

### Protocole (non négociable, appliqué à la lettre)

**Deux dérivations indépendantes menées EN PARALLÈLE** — l'indépendance est structurelle, pas
promise : ni l'une ni l'autre ne pouvait lire la sortie de sa jumelle.
- **Recensement A** — bottom-up : corps de l'agent → `references/` → agents nommés par chaque skill
  invoquée.
- **Recensement B** — top-down « quel geste, quelle machinerie, qu'est-ce qui casse ? » + balayage
  **inverse** de tous les agents du système. Explicitement **interdit** de lire
  `.planning/missions/*`, `CONCERNS.md`, les allowlists des managers et `.claude/agent-memory/`.

**Le fait structurant qui justifie ce protocole** : **aucune skill ne déclare `context:`** (vérifié
`grep -rl "^context:"` → vide). Aucune n'est forkée : les `Task(...)` d'une skill s'exécutent sous
l'allowlist de **l'agent qui l'invoque**. C'est la couche qu'un recensement naïf rate — elle avait
produit 4 omissions en Phase 15.

**Fait discriminant vérifié** : `vf-coder` possède le tool `Skill` (expansion transitive → 22 noms) ;
`vf-reviewer` et `vf-auditer` **ne l'ont pas** (un seul dispatch direct chacun).

### Réconciliation des écarts

| Worker | Recensement A | Recensement B | Écart | Décision |
|---|---|---|---|---|
| `vf-reviewer` | 1 | 1 | **aucun** | 1 nom |
| `vf-auditer` | 1 | 1 | **aucun** | 1 nom |
| `vf-coder` | 21 | 18 | **5 noms** | **union = 22** |

Écarts tranchés (règle : coût d'erreur asymétrique — un nom en trop = fuite mineure ; un nom
manquant = **dispatch refusé sans erreur visible**) :
- **A seul** — `gsd-debugger`, `gsd-integration-checker`, `gsd-nyquist-auditor`, `gsd-ui-auditor` :
  **retenus**. Preuve : le bloc `<available_agent_types>` d'`execute-phase.md:43-58`, workflow
  **chargé dans le contexte de `vf-coder`**, les lui énumère nommément comme spawnables.
- **B seul** — `gsd-code-fixer` : **retenu**. A l'avait lui-même qualifié de « candidat n°1 pour une
  marge de sécurité, coût du faux positif quasi nul ».

Écarté à l'unanimité : `gsd-advisor-researcher` — le workflow `advisor.md:104` dispatche littéralement
`subagent_type="general-purpose"` et fait seulement *lire* ce fichier. **Aucun manager** dans aucune
des trois listes (objet même de la phase).

### Les trois allowlists, en clair

**`vf-coder` — 22 noms** :
```
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent(vf-reviewer, general-purpose,
gsd-assumptions-analyzer, gsd-phase-researcher, gsd-pattern-mapper, gsd-planner, gsd-plan-checker,
gsd-executor, gsd-codebase-mapper, gsd-verifier, gsd-code-reviewer, gsd-code-fixer, gsd-debugger,
gsd-integration-checker, gsd-nyquist-auditor, gsd-ui-researcher, gsd-ui-checker, gsd-ui-auditor,
gsd-framework-selector, gsd-ai-researcher, gsd-domain-researcher, gsd-eval-planner)
```

**`vf-reviewer` — 1 nom** : `Agent(gsd-code-reviewer)`
**`vf-auditer` — 1 nom** : `Agent(gsd-security-auditor)`

> ⚠️ **`general-purpose` est le nom le plus fragile de tout l'ensemble** : c'est le seul introuvable
> par un inventaire des fichiers `*.md` d'agents. Son omission casserait **en silence** le cadrage
> non-interactif de `vf-coder`. Il est testé **nommément** par l'axe T19e.

---

## Étages de vérification — verdicts

| Étage | Verdict | Effet |
|---|---|---|
| `panel-lint` (advisor, doc officielle + mesure baseline) | tranché | Option « résolution graduée » retenue sur 4 |
| `recon-a` / `recon-b` (parallèles, indépendants) | convergents | Écart de 5 noms sur `vf-coder`, réconcilié |
| `mutation` (juge indépendant, 13 mutants) | **`gaps_found`** | **T19/T19e tautologiques** → reopen |
| `review` (`vf-reviewer` sur le diff complet) | **`gaps_found`** | **2 faux-bloquants du lint** → reopen |
| `gates` (40 suites + baseline worktree) | `gaps_found` (non bloquant) | 3 écarts en-tête ↔ comportement → reopen |
| Suites finales | **40/40 vertes** | `test-check-agents` 58 OK · `test-dev-orchestrator` 51 OK |
| `check-agents --strict` × 6 modules | exit 0 | + monde fermé exit 0 + `check-version-sync` ✓ |

### Ce que les juges ont rattrapé — et qui n'aurait été trouvé par personne d'autre

Les deux juges ont trouvé des **classes de défaut disjointes** : le juge de mutation a cassé les
**tests**, la revue a cassé le **code**. Aucun n'a trouvé ce que l'autre a trouvé.

1. **T19/T19e étaient tautologiques** (bloquant). `check_worker_allowlist` faisait `grep -qF` sur
   **toute la ligne `tools:`**, jamais à l'intérieur de `Agent(...)`. Prouvé empiriquement :
   `gsd-verifier` retiré de l'allowlist mais replacé ailleurs sur la ligne en `Bash(gsd-verifier)`
   → **suite 50 OK / 0 KO, totalement verte**, alors que le dispatch était réellement perdu. C'est
   le sinistre exact que ce nœud cherchait. Corrigé : extraction bornée aux parenthèses + égalité de
   token exacte + garde **anti-homonyme** (T19f) sur les paires préfixes
   (`gsd-ui-checker`/`gsd-ui-researcher`, `gsd-code-reviewer`/`gsd-code-fixer`).
2. **Deux faux-bloquants du lint neuf** (majeurs) : un champ `tools:` entièrement quoté produisait
   2 erreurs sur du YAML valide ; une **ligne vide** dans une liste bloc faisait **perdre
   silencieusement** toutes les entrées suivantes — invisibles même sous `--resolve-agents=strict`.
3. **`--resolve-agents=bogus` dégradait silencieusement en `lenient`**, exit 0 sans un mot : une
   typo dans le YAML aurait **désactivé le gate monde fermé en silence**. Désormais rejeté.

Couverture de test portée de 38 → **58 axes** sur le lint, chacun prouvé discriminant par mutation.

---

## Laissé de côté, et pourquoi

1. **`ROADMAP.md` et `STATE.md` non mis à jour** — **escalade délibérée**. Une autre session
   détenait des modifications **non commitées** sur ces deux fichiers pendant toute la mission.
   Y écrire aurait détruit du travail concurrent non sauvegardé. La case Phase 16 et la ligne de
   statut restent à poser **par l'humain ou par la session qui détient ces fichiers**.
2. **Release racine + tag + release GitHub** — hors périmètre par le brief. `VERSION` racine,
   `marketplace.json`, `plugin.json` et les README racines sont **intouchés** (v2.40.0).
3. **`--skills-dir=PATH` absent du bloc Usage** — préexistant en `69086d8`, hors périmètre, signalé.
4. **Séparateur `:` pour l'accumulation des flags répétables** — fragile si un chemin contient un
   `:`. Classé `no-op` par la revue (chemins relatifs Unix), documenté.
5. **Copies installées non resynchronisées** — `~/.claude/agents/` porte encore les versions à
   `Agent` nu. Normal : elles ne prendront les allowlists qu'après un `/vf-update`.

---

## Bumps par module

`conductor` v1.14.6 → **v1.15.0** (minor — nouvelle capacité : lint du contenu de `tools:`)
`dev-orchestrator` v2.4.0 → **v2.5.0** (minor — allowlists sur les 3 workers)
`VERSION` racine, `marketplace.json`, `plugin.json`, README racines : **intouchés**.

---

## Critères de succès de la Phase 16

| # | Critère | État |
|---|---|---|
| 1 | Lint du contenu des allowlists, sans faux positifs sur natifs/externes | ✅ résolution graduée, 22 entrées non résolvables restent vertes |
| 2 | Allowlists posées après le **même recensement exhaustif** | ✅ double dérivation parallèle + réconciliation de 5 écarts |
| 3 | Chemin indirect fermé, dette sortie de `CONCERNS.md` | ✅ dettes A **et** B retirées (B vérifiée empiriquement) |
| 4 | Suites existantes vertes + nouveau lint discriminant par mutation | ✅ 40/40 suites, 58 + 51 axes, mutation cas par cas |

---

## Next step

**Publier la release racine.** Les deux modules sont bumpés et cohérents (`check-version-sync` ✓),
les 40 suites sont vertes. Il reste à trancher le numéro racine (v2.40.0 → **v2.41.0**, nouvelle
capacité), puis à appliquer la discipline du `CLAUDE.md` : bump des trois fichiers + historique des
deux README, tag annoté, release GitHub, et `check-release-tag.sh --remote` → ✓.

**Avant cela, un geste court** : poser la case Phase 16 dans `ROADMAP.md` et la ligne de statut dans
`STATE.md`, une fois la session Phases 17/18 terminée et ses modifications commitées.
