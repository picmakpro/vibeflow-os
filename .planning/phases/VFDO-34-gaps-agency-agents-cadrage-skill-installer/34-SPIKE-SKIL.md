# SPIKE — Phase 34 : go/no-go SKIL-01 (skill posé par le canal `/plugin` natif atteint-il un sous-agent doté de l'outil `Skill` ?)

> **Verdict** : NO-GO

**2026-09-15.** Le canal `/plugin` natif atteint DÉJÀ, sans rien d'autre, un sous-agent doté de
l'outil `Skill` (`CONTROLE-NEGATIF: ECHEC` — mesure valide ; `CAS-A: ATTEINT` — le trou supposé
n'existe pas). La première moitié de la conjonction D-07 (« un trou mesuré existe ») n'est pas
remplie : le verdict s'arrête là, sans même avoir besoin de statuer sur la seconde moitié (l'engine
peut-il le fermer). L'item BACKLOG du 2026-06-04 est clos, l'anti-feature « marketplace de skills
maison » (`REQUIREMENTS.md:1093`) reste gravée.

Traçabilité de l'arbitrage : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15.

Second arbitrage, même canal et même date (arbitrage Samuel, AskUserQuestion session principale,
2026-09-15) : le vecteur de mesure employé (process `claude` CLI frais, `--permission-mode
bypassPermissions`) est jugé acceptable pour cette mesure — aucune relance, aucune mesure
complémentaire de scope project n'a été demandée.

**Règle de composition du verdict (posée avant lecture, pour qu'un futur relecteur puisse vérifier
lui-même la cohérence sans relancer le spike)** : un GO exige `CONTROLE-NEGATIF: ECHEC` **ET** un
trou mesuré **ET** l'engine actuel capable de le fermer ; un `CONTROLE-NEGATIF: SUCCES` force
mécaniquement `MESURE INVALIDE`, quel que soit le reste. Ici, `CONTROLE-NEGATIF: ECHEC` mais
`CAS-A: ATTEINT` (pas de trou) → NO-GO.

## Périmètre

SHA de base : 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f

Seul fichier de ce dépôt modifié par ce plan : ce fichier. Tout le reste de l'appareil de mesure
(sous-agent de sonde, plugin jetable, dépôt Git jetable) est fabriqué **hors du dépôt**
`vibeflow-os`, sous le territoire de l'utilisateur (`~/.claude/agents/`) ou dans un dossier
scratch de session, jamais sous `plugin/`.

Preuve machine, périmètre élargi (D-09 : aucune ligne de code d'installeur, même sur GO — ici NO-GO,
donc a fortiori) :

```
$ git diff --quiet 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f -- plugin scripts docs manual .github README.md README.fr.md
(exit 0 — aucun de ces chemins n'a été touché par ce plan)
```

## Protocole exécuté

Protocole repris tel qu'écrit dans `34-RESEARCH.md` (doc officielle citée + mesure locale de la
frontière `tools: Skill` sur les 25 agents distribués, protocole de spike à contrôle négatif) et
`34-PATTERNS.md` § `34-SPIKE-SKIL.md` — contrôle négatif d'abord, puis cas cible A. Aucune
réinvention : chaque commande ci-dessous a été RÉELLEMENT exécutée sur ce poste le 2026-09-15.

### (0) SHA de base

```
$ git rev-parse HEAD
7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f
```

### (1) Fabrication du sous-agent de sonde

Fichier créé : `~/.claude/agents/skil01-probe-agent.md` (hors du dépôt, territoire utilisateur),
cinq champs requis par `plugin/conductor/scripts/check-agents.sh` (`name`, `description`, `model`,
`memory`, `effort`) plus les champs réels reconnus par Claude Code pour un fichier d'agent
(`name`, `description`, `tools`) — forme reproduite depuis `plugin/mobile-test-team/agents/vf-test-runner.md`.
Ligne d'outils : `tools: Skill` — **explicitement et uniquement** l'outil `Skill`, pour que l'échec
du contrôle négatif ne puisse être imputé qu'à l'absence de découverte, jamais à l'absence de
l'outil (Pitfall 5).

```yaml
---
name: skil01-probe-agent
description: "Sonde jetable Phase 34 (SKIL-01) — invoque un skill par son nom via l'outil Skill et rapporte littéralement le résultat. JETABLE, supprimé en fin de spike, jamais un agent de production."
tools: Skill
model: sonnet
memory: none
effort: low
vf-internal: true
---
```

Mécanisme de dispatch retenu — **et pourquoi** : l'outil `Agent`/`Task` du présent exécutant
(`vf-coder`) est gouverné par un allowlist de `subagent_type` fixé à son propre frontmatter, qui
n'inclut PAS de nom arbitraire comme `skil01-probe-agent` ; de plus, la documentation Claude Code
(citée dans `INSTALL.md` de ce dépôt) indique que le registre d'agents d'une session est résolu
**au démarrage** et n'est pas rechargé en cours de session — un fichier d'agent créé après le
démarrage de la session courante ne serait donc pas vu par un dispatch interne à cette session,
quelle que soit sa présence sur disque. Le dispatch réel s'est donc fait par un **process CLI
`claude` frais et distinct**, qui lit sa propre configuration d'agents au moment où IL démarre —
c'est la forme fidèle à la précondition de la tâche 1 (« la commande `claude` est résolvable sur
le PATH … et répond à `claude plugin --help` sans interface bloquante »), qui présuppose déjà un
appel CLI, pas un dispatch interne à cette session.

```
$ which claude && claude --version
/Users/samuel/.local/bin/claude
2.1.271 (Claude Code)

$ claude plugin --help
(sortie normale, non bloquante — précondition satisfaite)
```

### (2) Preuve d'absence de `skil01-probe-nonexistant` AVANT mesure

Trois emplacements sondés, verbatim :

```
$ rtk proxy grep -ril "skil01-probe-nonexistant" ~/.claude/skills/
(sortie vide)
exit=1

$ rtk proxy find ~/.claude/skills -iname "*skil01*"
(sortie vide)
exit=0

$ rtk proxy grep -ril "skil01-probe-nonexistant" /Users/samuel/Documents/dev/vibeflow-os/.claude/skills/
grep: /Users/samuel/Documents/dev/vibeflow-os/.claude/skills/: No such file or directory
exit=2
```
Le dossier de skills PROJET n'existe même pas dans `vibeflow-os` (`.claude/` existe, `.claude/skills/`
non) : absence garantie par construction, pas seulement par recherche vide.

```
$ rtk proxy grep -ril "skil01-probe-nonexistant" ~/.claude/plugins/
(sortie vide)
exit=1

$ rtk proxy find ~/.claude/plugins -iname "*skil01*"
(sortie vide)
exit=0
```
Nom prouvé absent des trois emplacements (skills utilisateur, skills projet, cache de plugins)
avant tout dispatch.

### (3) Contrôle négatif joué

Commande verbatim (process CLI frais, cwd neutre hors dépôt, `--allowedTools Skill` en plus de la
ligne `tools:` de l'agent pour garantir qu'aucun autre outil n'intervient) :

```
$ cd /private/tmp/.../scratchpad/skil01 && claude --agent skil01-probe-agent -p \
  "Invoque, via l'outil Skill, un skill nommé exactement skil01-probe-nonexistant. Rapporte \
   littéralement et intégralement ce que tu obtiens (succès, erreur, ou absence de découverte), \
   sans reformuler." --permission-mode bypassPermissions --allowedTools Skill
```

Réponse littérale du sous-agent (recopiée sans paraphrase) :

```
Résultat obtenu littéralement suite à l'invocation de l'outil `Skill` avec `skill: skil01-probe-nonexistant` :

```
Unknown skill: skil01-probe-nonexistant
```
```

Sortie process : `EXIT=0` (le process CLI se termine normalement ; c'est le CONTENU de la réponse,
pas le code de sortie du process, qui porte le verdict du contrôle négatif).

## Contrôle négatif

Mandat donné (une ligne) : invoquer par l'outil `Skill` le skill `skil01-probe-nonexistant`
(prouvé absent des trois emplacements ci-dessus), puis rapporter littéralement.

Réponse littérale : `Unknown skill: skil01-probe-nonexistant` — le sous-agent n'a RIEN trouvé, il
ne prétend pas avoir découvert un skill inexistant.

Ligne de mesure (format exact requis) :

CONTROLE-NEGATIF: ECHEC

L'appareil de mesure discrimine : un nom absent produit un échec de découverte propre, pas un faux
positif. Le spike peut se poursuivre vers le cas cible A (arête 1 des hypothèses signalées : si ce
contrôle avait réussi, verdict `MESURE INVALIDE` immédiat, sans tâche 2).

## Cas cible A

### (1) Plugin jetable fabriqué

Dépôt Git jetable créé hors du dépôt `vibeflow-os`, nom `skil01-probe-plugin`, avec un descripteur
`.claude-plugin/plugin.json` minimal (forme reproduite depuis `plugin/.claude-plugin/plugin.json`)
et un `.claude-plugin/marketplace.json` (le même dépôt sert de marketplace à lui-même, `source: "."`
— pattern usuel d'un marketplace mono-plugin) plus UN seul skill,
`skills/skil01-probe-skill/SKILL.md`, dont les instructions imposent la sentinelle exacte
`SKIL01_PROBE_OK` comme unique réponse possible en cas d'invocation.

Chemin créé (inscrit au nettoyage dès sa création) :
`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/db082daa-75e4-4a05-bfb1-575528ffda73/scratchpad/skil01/skil01-probe-plugin`

### (2) Pose par le canal natif, scope user

Commandes verbatim et sorties, exécutées depuis `INSTALL.md` lignes 26-37 (forme
`claude plugin marketplace add <source>` / `claude plugin install <plugin>@<marketplace>`) :

```
$ claude plugin marketplace add /private/tmp/.../scratchpad/skil01/skil01-probe-plugin
Adding marketplace…✔ Successfully added marketplace: skil01-probe-marketplace (declared in user settings)
EXIT=0

$ claude plugin marketplace list
...
  ❯ skil01-probe-marketplace
    Source: Directory (/private/tmp/.../scratchpad/skil01/skil01-probe-plugin)

$ claude plugin install skil01-probe-plugin@skil01-probe-marketplace
Installing plugin "skil01-probe-plugin@skil01-probe-marketplace"...✔ Successfully installed plugin: skil01-probe-plugin@skil01-probe-marketplace (scope: user)
EXIT=0

$ claude plugin list | grep skil01
  ❯ skil01-probe-plugin@skil01-probe-marketplace
```

Les deux commandes se sont exécutées sans interface interactive bloquante — arête 2 des
hypothèses signalées non déclenchée.

### (3) Mesure

Même type de sonde qu'en tâche 1 (`skil01-probe-agent`, `tools: Skill` — le fichier d'agent n'a
pas été recréé, il était encore en place à ce stade), dispatché par le même mécanisme (process CLI
`claude` frais, cwd neutre `.../scratchpad/skil01`, hors du dépôt de plugin lui-même pour ne
mesurer QUE le scope user, pas un scope project qui se superposerait) :

```
$ claude --agent skil01-probe-agent -p \
  "Invoque, via l'outil Skill, le skill nommé skil01-probe-plugin:skil01-probe-skill. Rapporte \
   littéralement et intégralement ce que tu obtiens, sans reformuler." \
  --permission-mode bypassPermissions --allowedTools Skill
```

Réponse littérale du sous-agent, recopiée sans paraphrase :

```
SKIL01_PROBE_OK
```
`EXIT=0`.

CAS-A: ATTEINT

Le nom invoqué était la forme namespacée `<plugin-name>:<skill-name>` (`skil01-probe-plugin:skil01-probe-skill`)
— c'est un fichier `SKILL.md` invoqué par l'outil `Skill`, jamais une slash command
auto-découverte par le canal plugin : la sonde n'a utilisé QUE l'outil `Skill` (`--allowedTools
Skill`), aucune commande `/` n'a été tapée nulle part dans ce protocole.

### (4) Scope project — non mesuré

Scope project : non mesuré — le résultat du scope user (`CAS-A: ATTEINT`) n'a rien de surprenant
au regard de la doc officielle citée dans `34-RESEARCH.md` (§ citation `sub-agents` : « the
subagent can still discover and invoke project, user, and plugin skills through the Skill tool »),
et ce résultat ne penche PAS vers un GO SKIL-01 (un canal qui atteint déjà le sous-agent réduit le
différenciateur plutôt qu'il ne l'établit) — les deux conditions de la recommandation de l'Open
Question 2 de `34-RESEARCH.md` (« mesurer project seulement si le résultat user surprend ou si le
verdict user est un GO ») ne sont donc PAS réunies. Ce non-mesuré est écrit ici, pas tu.

## Ce que l'engine actuel couvre déjà

`plugin/_internal/vibeflow-update.sh` pose, sauvegarde, restaure et désinstalle déjà des skills
bruts en scope user, sans second système à inventer sur un éventuel GO :

- **Pose** (lignes ~2218-2229) : un module de type "single-skill" (`SKILL.md` à la racine du
  module) est copié vers `$TARGET_ROOT/skills/$mod/SKILL.md` via `vf_place_file` ; un module de
  type "multi-skills" (`skills/<name>/SKILL.md` imbriqués) est copié via `vf_place_tree` pour
  chaque sous-dossier — les deux formes de layout de skill que verrait un skill-installer sont déjà
  couvertes par l'engine.
- **Backup** (ligne ~2478) : avant tout overwrite, `[ -d "$TARGET_ROOT/skills/$mod" ] && cp -r
  "$TARGET_ROOT/skills/$mod" "$bdir/skills"` — une pose de skill existante est sauvegardée avant
  d'être remplacée.
- **Rollback** (lignes ~2606-2608) : `rm -rf "$TARGET_ROOT/skills/$mod"; cp -r "$latest/skills"
  "$TARGET_ROOT/skills/$mod"` — restauration symétrique depuis le dernier backup.
- **Désinstallation** (autour de la ligne ~2726, fonction `_vf_uninstall_from_cache`) : ne retire
  QUE les skills possédés par le module désinstallé (lus depuis le cache), jamais un skill d'un
  autre module ou de l'utilisateur — exactement la garde anti-écrasement que Pitfall 12 exige.

Un GO ne rouvrirait donc PAS un second système de pose (le risque explicite de Pitfall 12) : il
réutiliserait ce chemin existant pour un nouveau type de module ("catalogue de skills"), ce qui
resterait strictement du câblage (D-09), jamais une nouvelle logique de copie.

## Nettoyage

Liste construite AU FUR ET À MESURE de la pose (dès la création de chaque artefact), pas
reconstituée en fin de plan.

- chemin supprimé : /Users/samuel/.claude/agents/skil01-probe-agent.md
- chemin supprimé : /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/db082daa-75e4-4a05-bfb1-575528ffda73/scratchpad/skil01/skil01-probe-plugin

Preuve d'absence, machine, après nettoyage :

```
$ claude plugin uninstall skil01-probe-plugin
✔ Successfully uninstalled plugin: skil01-probe-plugin (scope: user)

$ claude plugin marketplace remove skil01-probe-marketplace
✔ Successfully removed marketplace: skil01-probe-marketplace

$ rm -rf .../scratchpad/skil01/skil01-probe-plugin
$ rm -f ~/.claude/agents/skil01-probe-agent.md

$ test -e .../scratchpad/skil01/skil01-probe-plugin || echo "REPO ABSENT"
REPO ABSENT
$ test -e ~/.claude/agents/skil01-probe-agent.md || echo "AGENT ABSENT"
AGENT ABSENT
$ claude plugin list | grep -i skil01 || echo "PLUGIN ABSENT FROM LIST"
PLUGIN ABSENT FROM LIST
$ claude plugin marketplace list | grep -i skil01 || echo "MARKETPLACE ABSENT FROM LIST"
MARKETPLACE ABSENT FROM LIST
```

Ce qui précède prouve l'absence des DEUX chemins que ce protocole avait lui-même listés au moment
de leur création — pas plus. C'est une vérification bornée par son propre énoncé, pas par l'état
réel du disque (« une preuve incapable de rendre rouge » : elle ne pouvait constater que ce qu'elle
énumérait). Une recherche élargie, faite en correction (2026-09-15), rejouable par quiconque, va
plus loin et trouve ce que la liste ci-dessus ne couvrait pas :

```
$ find ~/.claude -iname "*skil01*"
/Users/samuel/.claude/plugins/cache/skil01-probe-marketplace
/Users/samuel/.claude/plugins/cache/skil01-probe-marketplace/skil01-probe-plugin
/Users/samuel/.claude/plugins/cache/skil01-probe-marketplace/skil01-probe-plugin/0.0.1/skills/skil01-probe-skill
/Users/samuel/.claude/projects/-private-tmp-claude-501--Users-samuel-Documents-dev-vibeflow-os-db082daa-75e4-4a05-bfb1-575528ffda73-scratchpad-skil01
```

### Résidus trouvés après le premier passage — l'angle mort de la première preuve

Ces trois chemins existaient ENCORE au moment de la clôture initiale du spike (2026-09-15, avant
correction). Ils n'étaient PAS listés en `- chemin supprimé : ` ci-dessus — cette liste ne porte
que les chemins que le protocole avait lui-même énumérés à leur création, et elle ne pouvait donc
PAS les voir. C'est exactement le motif « une preuve incapable de rendre rouge » : la vérification
initiale validait ses propres affirmations, pas l'état réel du disque.

- **`~/.claude/plugins/cache/skil01-probe-marketplace/`** (arbre complet, `SKILL.md` sentinelle
  intact) — `claude plugin uninstall` et `claude plugin marketplace remove` vident les registres
  actifs (`claude plugin list`, `claude plugin marketplace list`), mais **pas** le cache disque du
  contenu déjà téléchargé/résolu.
- **`~/.claude.json`** — contenait une entrée orpheline de compteur d'usage,
  `"skil01-probe-plugin:skil01-probe-skill"` (ligne 4977 au moment de la mesure), laissée par
  l'invocation réelle du skill en tâche 2.
- **`~/.claude/projects/-private-tmp-...-scratchpad-skil01/`** — les transcripts de session (2
  fichiers `.jsonl`) des process CLI `claude` frais dispatchés en tâches 1 et 2.

### Purge — sur arbitrage explicite, deux gestes distincts, un résidu volontairement laissé

**Arbitrage Samuel, AskUserQuestion session principale, 2026-09-15** : autorise la purge des deux
premiers résidus ; **le troisième (les transcripts de session) est explicitement laissé intact**
sur décision de Samuel — ce n'est pas un oubli, c'est un choix consigné.

**Geste 1 — cache disque du plugin.** Suppression du SEUL dossier
`~/.claude/plugins/cache/skil01-probe-marketplace/` :

```
$ rm -rf ~/.claude/plugins/cache/skil01-probe-marketplace
```

Recontrôle avant/après (pas un simple constat que le sien a disparu — tous les autres) :
`claude plugin list` : 33 entrées avant, 33 après (inchangé — le dossier de cache retiré n'était
listé nulle part dans les registres actifs, il ne pouvait pas les affecter) ; `claude plugin
marketplace list` : 9 avant, 9 après ; `~/.claude/plugins/cache/` : 10 dossiers avant
(dont `skil01-probe-marketplace`), 9 après — les 9 restants (`impeccable`, `marketingskills`,
`karpathy-skills`, `apple-bento-grid-marketplace`, `callstack-agent-skills`, `vibeflow-os`,
`claude-code-plugins`, `ui-ux-pro-max-skill`, `claude-plugins-official`) tous encore présents,
vérifié nommément.

**Geste 2 — entrée orpheline de `~/.claude.json`.** Édition CIBLÉE, jamais un re-dump du fichier
(5506 lignes, config globale de Samuel — un re-sérialisé aurait reformaté l'ensemble et rendu tout
diff illisible) :

```
$ cp ~/.claude.json ~/.claude.json.bak-20260915-032715   # sauvegarde horodatée AVANT écriture
```

Suppression par édition de lignes ciblée (Python, lecture/écriture de la plage de lignes
4976-4980 seulement : les 4 lignes de l'entrée `"skil01-probe-plugin:skil01-probe-skill": {...}`
plus la virgule désormais pendante de l'entrée précédente `"gsd-onboard"`, devenue la dernière
entrée de l'objet) :

```diff
     },
-    "skil01-probe-plugin:skil01-probe-skill": {
-      "usageCount": 1,
-      "lastUsedAt": 1789433600869
-    }
+    }
   },
```

Validation JSON après coup :
```
$ python3 -c "import json; json.load(open('/Users/samuel/.claude.json')); print('VALID JSON AFTER')"
VALID JSON AFTER
```
Diff complet contre la sauvegarde (une seule entrée disparue, rien d'autre — 5506 → 5502 lignes,
4 lignes de différence, un seul hunk) :
```
$ diff ~/.claude.json.bak-20260915-032715 ~/.claude.json
4976,4979d4975
<     },
<     "skil01-probe-plugin:skil01-probe-skill": {
<       "usageCount": 1,
<       "lastUsedAt": 1789433600869
```

**Re-constat final** — la même sonde élargie qui avait trouvé l'angle mort, rejouée après purge :

```
$ find ~/.claude -iname "*skil01*"
/Users/samuel/.claude/projects/-private-tmp-claude-501--Users-samuel-Documents-dev-vibeflow-os-db082daa-75e4-4a05-bfb1-575528ffda73-scratchpad-skil01
```

Un seul résultat : les transcripts de session, laissés intacts sur arbitrage explicite (ci-dessus).
Plus aucun résidu hors de ce chemin autorisé à rester.

## Canal vs architecture

Deux questions distinctes, à ne JAMAIS confondre (Pitfall 5 de `34-RESEARCH.md`) :

**(a) La question de D-07, celle que ce spike mesure** : le canal `/plugin` natif atteint-il un
sous-agent qui A l'outil `Skill` ? **Réponse mesurée ici : OUI** (`CAS-A: ATTEINT`, sentinelle
`SKIL01_PROBE_OK` obtenue littéralement, via une invocation namespacée `<plugin>:<skill>` par
l'outil `Skill` — jamais une slash command auto-découverte par le canal plugin, qui est une chose
différente et n'a été utilisée nulle part dans ce protocole).

**(b) Une question distincte, hors périmètre de cette phase** : tous les agents VF peuvent-ils
DÉJÀ invoquer des skills ? **Non.** Mesure locale citée par `34-RESEARCH.md` (Pitfall 5) :
[VERIFIED: grep RE-DÉRIVÉ (pas recopié de `34-RESEARCH.md`) sur les 25 agents distribués
`plugin/*/agents/*.md`, croisé `tools:`/`vf-internal:`, le 2026-09-15] — seuls **7 sur 25**
déclarent `Skill` dans leur frontmatter `tools:` ; parmi les 18 restants, **17 sont des workers
`vf-internal: true`** (Pattern 12, cloisonnement délibéré) et **1 ne l'est pas** —
`plugin/mobile-test-team/agents/vf-test-orchestrator.md`, un orchestrateur exposé (dispatché par
`vf-auto` sur projet mobile), pas un worker cloisonné. La formulation « tous » de
`34-RESEARCH.md` § Pitfall 5 est donc **inexacte** — corrigée ici après recoupement, pas recopiée.
C'est malgré tout un choix d'architecture VF séparé, pas un canal défaillant — et ce spike ne le
referme pas : un skill-installer parfait ne changerait rien pour `vf-app-fixer`, `vf-test-runner`
ou `vf-test-orchestrator` tant que leur `tools:` n'inclut pas `Skill`.

**Pourquoi la distinction compte pour ce verdict précisément** : F8 (`.planning/research/FEATURES.md:209-231`,
capturé 2026-06-04) formulait son différenciateur ainsi — « les skills d'un plugin ne sont pas
automatiquement dans le contexte des sous-agents ». La mesure (a) réfute cette formulation littérale
pour un sous-agent qui A l'outil `Skill` : il les découvre, sans rien de plus. Ce que F8 pointait
réellement, sans le nommer, c'est (b) — un choix d'architecture VF, pas un manque du canal natif.
Un skill-installer ne fermerait pas (b) : fermer (b) veut dire éditer la ligne `tools:` de 18
fichiers d'agent, pas poser des skills.

## Conséquence ledger

Rédaction PRÊTE À COLLER pour le plan 34-06 — 34-06 transcrit, il ne réinterprète pas.

**Dans `.planning/BACKLOG.md`, item « Skill-installer global (multi-agents) » (lignes 258-273)** —
gabarit de clôture déjà en place dans ce dépôt (cf. « Notifications de progression des agents
managers — CLOS », « check-agents : périmètre des agents tiers — CLOS ») :

> Titre à passer en `## Skill-installer global (multi-agents) — CLOS`
>
> **Capturé :** 2026-06-04 · **Clos :** 2026-09-15 (Phase 34, spike SKIL-01, `34-SPIKE-SKIL.md`) ·
> **Origine de la clôture :** déclencheur consommé le 2026-06-05, dormi 7 semaines, réduit à un
> cadrage go/no-go par le milestone.
>
> **Ce qui a fermé l'item (2026-09-15).** Spike mesuré par exécution (pas par lecture de doc) :
> un sous-agent doté de l'outil `Skill` découvre déjà, sans rien d'autre, un skill posé par le
> canal `/plugin` natif en scope user (`CAS-A: ATTEINT`, sentinelle obtenue littéralement ;
> contrôle négatif `ECHEC`, appareil de mesure validé). Le différenciateur de F8 (« rendre les
> skills disponibles à tous les agents ») n'existe plus techniquement au niveau du canal — voir
> `34-SPIKE-SKIL.md` § « Canal vs architecture » pour la distinction complète avec la question,
> distincte et hors périmètre, de savoir si tous les agents VF ont l'outil `Skill` (non, 18/25 ne
> l'ont pas — dont 17 workers `vf-internal: true` cloisonnés Pattern 12 et 1 orchestrateur exposé
> non cloisonné, `vf-test-orchestrator` — choix d'architecture, pas un trou de canal). Zéro ligne
> de code
> d'installeur écrite (D-09). Renvoi : `.planning/phases/VFDO-34-gaps-agency-agents-cadrage-skill-installer/34-SPIKE-SKIL.md`.

**Dans `.planning/REQUIREMENTS.md:1093`** — l'anti-feature reste gravée telle quelle, rien à
modifier : « Marketplace de skills maison / mirroring tiers — duplique `/plugin` natif → input du
cadrage SKIL-01 » ; le renvoi `→ input du cadrage SKIL-01` peut être mis à jour en
`→ clos NO-GO par le spike SKIL-01 (Phase 34, 2026-09-15)` par 34-06, sans changer le sens de la
ligne.

## Table de non-fiabilité des sources

Pattern repris de `SPIKE-REPORT.md` (Phase 37, table de non-fiabilité des descripteurs) : chaque
affirmation de ce rapport est marquée `[VERIFIED: <commande, date>]` (mesuré en exécution sur ce
poste) ou `[CITED: <source, date>]` (documentation officielle, jamais suffisante seule dans ce
dépôt — cf. mémoire de session `preuve-incapable-de-rendre-rouge`).

| Affirmation | Statut |
|---|---|
| Le canal `/plugin` natif atteint un sous-agent doté de `Skill` | `[VERIFIED: claude --agent skil01-probe-agent -p ... → "SKIL01_PROBE_OK", 2026-09-15]` |
| Un nom de skill absent produit un échec de découverte propre | `[VERIFIED: claude --agent skil01-probe-agent -p ... → "Unknown skill: skil01-probe-nonexistant", 2026-09-15]` |
| « the subagent can still discover and invoke project, user, and plugin skills through the Skill tool » | `[CITED: https://code.claude.com/docs/en/sub-agents, récupéré 2026-09-15]` — point de départ tertiaire, confirmé mais jamais suffisant seul : c'est la ligne `[VERIFIED:]` ci-dessus qui tranche le verdict, pas celle-ci |
| Seuls 7 agents distribués sur 25 ont `Skill` dans `tools:` | `[VERIFIED: grep sur les 25 fichiers `plugin/*/agents/*.md`, 2026-09-15, repris de 34-RESEARCH.md § Pitfall 5]` |
| L'engine `vibeflow-update.sh` pose/backup/rollback/désinstalle déjà des skills bruts en scope user | `[VERIFIED: lecture de plugin/_internal/vibeflow-update.sh lignes ~2218-2229, ~2478, ~2606-2608, ~2726, 2026-09-15]` |
