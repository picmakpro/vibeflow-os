---
name: vf-update
description: "Utiliser quand l'utilisateur veut mettre à jour VibeFlow — « mets à jour vibeflow », « /vf-update », ou en réaction au bandeau « mise à jour disponible » au démarrage de session. Compare la version installée au dernier tag publié, montre le changelog, puis met à jour le plugin (cache marketplace) et les modules installés, sous validation humaine. Détecte aussi l'état du moteur GSD (legacy vs `@opengsd/gsd-core`) et le propose en migration, sous confirmation indépendante. ✘ pas pour réaligner la **structure** d'un lab sur une doctrine qui a évolué, une fois la nouvelle version posée → /vf-calibrate · ✘ pas pour ajouter, retirer ou re-choisir des modules → /vibeflow-install · ✘ pas pour mettre à jour la documentation d'un projet → gsd-docs-update. Invocable par l'utilisateur ET par `vibeflow-conductor`."
---

# vf-update — Mise à jour du plugin & des modules

Met à jour VibeFlow en **deux couches** : (1) le **plugin** via `claude plugin update vibeflow`
(rafraîchit le cache marketplace `~/.claude/plugins/cache/…`), puis (2) les **modules installés**
via l'engine `update --all` (re-matérialise `.claude/skills|agents|rules|scripts`). Jamais sans
confirmation (ADR-031).

## Résolution des scripts (conductor)

**0e étape (TGT-04, cible custom `--target`)** : avant de tester les trois positions littérales
ci-dessous, vérifie si `./.claude/scripts/.vibeflow-target` **ou** `$HOME/.claude/scripts/.vibeflow-target`
existe. Si l'un des deux existe ET que son contenu (un chemin absolu, une seule ligne) **diffère**
de la position candidate elle-même (`./.claude` ou `$HOME/.claude`), c'est que ce lab a été posé
sous `--target` : lis ce contenu et utilise-le comme `<S>`/`<S-moteur>` réel (`<contenu>/scripts/`)
au lieu de la position littérale. Si le marqueur est absent, ou présent mais identique à la
position candidate (cas normal, sans `--target`), continue directement à la cascade suivante —
aucune déviation.

Les scripts vivent dans le dossier `scripts/` de conductor. Localise-les dans cet ordre (prends le
premier existant) : `$HOME/.claude/scripts/` → `./.claude/scripts/` → `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`.
Note ce dossier `<S>` pour les étapes suivantes.

**Sonde moteur GSD (best-effort, `<S-moteur>`)** : `check-gsd-engine.sh` et `ensure-deps.sh` sont
des scripts de **dev-orchestrator**, pas de conductor (D-00 : conductor est mandatory, dev-
orchestrator ne l'est pas — un lab non-dev installe le premier sans le second). Ils se cherchent
dans la même cascade que `<S>`, sauf en 3e position — plugin non installé — où le chemin est
`${CLAUDE_PLUGIN_ROOT}/dev-orchestrator/scripts/`, **jamais** `conductor/scripts/` : les deux
premières positions matérialisent tous les scripts à plat dans un même `.claude/scripts/` d'un lab
installé, mais la 3e position doit pointer vers le module qui porte réellement ces fichiers avant
toute install. Note ce dossier `<S-moteur>`. **Absent aux trois positions → silence total** (voir
étape 1) : la sonde ne doit jamais dégrader le reste du diagnostic.

## Étapes

### 1 — Diagnostic (plugin + moteur GSD, deux volets)

**Volet plugin** (inchangé) : lance `bash <S>/check-plugin-update.sh --print`. Parse le JSON
`{update_available, installed, latest}`. `latest` vaut `unknown` (réseau KO) → dis-le, propose de
réessayer plus tard, **stop**.

**Volet moteur GSD** — sonde best-effort `<S-moteur>`, exécutée **avant tout arrêt** sur absence de
mise à jour du plugin (c'est le point de couture de la phase, D-07) : lance
`bash <S-moteur>/check-gsd-engine.sh --quiet`. Trois branches, exactement :

- **Script introuvable** (aux trois positions de `<S-moteur>`) → SILENCE TOTAL : aucune ligne,
  aucune mention, aucune dégradation du reste du diagnostic. Un lab non-dev (content, growth,
  business) installe `conductor` sans `dev-orchestrator` et ne doit rien voir. Une erreur d'usage
  du gate (exit `2`) est traitée comme une absence : silence.
- **Exit `0`** (état legacy, seul cas actionnable) → compose la ligne moteur à partir de la sortie
  réelle du gate (jamais une valeur recopiée depuis la doctrine) : « moteur GSD legacy A.B.C →
  `@opengsd/gsd-core` à migrer ».
- **Exit `3`** (INDÉTERMINÉ) → si le gate a imprimé une ligne (sous-cas reliquat `[gsd-leftover]` :
  gsd-core à jour + reliquat legacy détecté), l'affiche dans le diagnostic **sans jamais proposer
  de migration** ; s'il n'a rien imprimé (état absent, ou gsd-core propre), ne dit rien.

**Arrêt combiné** : « VibeFlow est à jour (v<installed>) » ne peut sortir seul, suivi du **stop**,
que si le volet moteur n'a produit aucune ligne (silence ou signal non actionnable) **et** que
`update_available = false`. Dès que le volet moteur a produit la ligne legacy, le message combine
les deux volets et le flux **continue** — même si le plugin est déjà à jour : « plugin à jour
(v<installed>), moteur GSD legacy A.B.C → `@opengsd/gsd-core` à migrer ». Les numéros viennent
toujours des sorties réelles de `check-plugin-update.sh --print` et de `check-gsd-engine.sh`,
jamais de valeurs recopiées depuis la doctrine. Sinon (mise à jour plugin disponible, avec ou sans
ligne moteur), continue vers l'étape 2.

### 2 — Changelog (ce qui a changé)

Montre les changements entre `installed` et `latest`, résumés **par version** en distinguant
*nouvelle capacité* / *correctif* / *changement de doctrine*. Source, dans l'ordre de préférence :
la table d'historique du `README.md` du plugin (`${CLAUDE_PLUGIN_ROOT}/README.md` ou le clone
marketplace `~/.claude/plugins/marketplaces/vibeflow-os/README.md`), sinon les `CHANGELOG.md` des
modules. Reste factuel, pas de survente.

### 3 — Confirmation (ADR-031 — jamais d'update sans validation humaine)

Récapitule via **AskUserQuestion** : « Plugin v<installed> → v<latest> + les modules installés
seront mis à jour. Continuer ? ». Si le volet moteur (étape 1) a produit une ligne, ajoute **une
ligne de plus** au récapitulatif : « Moteur GSD legacy A.B.C → `@opengsd/gsd-core` à migrer.
Continuer ? ». Cette ligne moteur est acceptable ou refusable **indépendamment** de la ligne plugin
et de la ligne modules — un refus n'a **aucun effet de bord**, et elle n'est **jamais** ni relancée
ni reformulée dans la même session (ADR-031, P-07).

Gère les flags **existants** de `$ARGUMENTS` (aucun flag nouveau créé — densité ADR-029) :

- `--check` → affiche seulement les étapes 1–2, **y compris l'état du moteur GSD** comme le reste
  du diagnostic, **ne demande rien**, **stop**.
- `--modules-only` → saute l'étape 4a (ne touche pas au plugin) et **ne propose pas** la migration
  du moteur — son nom borne son périmètre aux modules.

### 4 — Exécution (après OK)

a. **Couche plugin** : `claude plugin update vibeflow@vibeflow-os`. **Toujours l'identifiant
   complet `<plugin>@<marketplace>`** : le nom nu (`claude plugin update vibeflow`) peut échouer par
   « Plugin not found » quand le cache de catalogue est périmé. Si le CLI `claude` est absent ou
   échoue, signale-le, donne la commande manuelle, et — en cas de « not found » persistant — la
   parade : `claude plugin marketplace update vibeflow-os` (ou supprimer le cache
   `~/.claude/plugins/plugin-catalog-cache.json`, régénéré au prochain appel). Puis continue en 4b
   (les modules peuvent quand même être re-matérialisés depuis le cache le plus récent).

b. **Couche modules** : `bash <S>/vf-update-run.sh`. Le script localise **lui-même** le cache le
   plus récent (indispensable : la session courante garde encore l'ancien `${CLAUDE_PLUGIN_ROOT}`)
   et relance l'engine `update --all` pour chaque scope ayant un registre. Il rafraîchit aussi le
   cache du bandeau de mise à jour, ce qui évite qu'il réclame au redémarrage une mise à jour déjà
   faite. Relaie son résumé.

c. **Couche moteur** (seulement si la ligne moteur de l'étape 3 a été acceptée) : invoque
   `bash <S-moteur>/ensure-deps.sh --migrate-engine` et relaie son résumé. S'exécute **même si** la
   couche plugin (4a) a échoué — les confirmations sont indépendantes. Le skill n'invoque **jamais**
   l'installeur amont directement : il route vers `ensure-deps.sh`, point de vérité unique du scope
   et du plafond de version (Iron Law 2, `plugin/conductor/AGENT.md:114`).

### 5 — Rappel de redémarrage

Termine par : « Modules à jour sur disque. **Redémarre Claude Code** pour recharger le plugin
(commandes, agents) dans sa nouvelle version. » Le plugin lui-même n'est pris en compte qu'au
prochain démarrage de session. Si la couche moteur (4c) a tourné, ajoute : une migration du moteur
pose de nouveaux agents et skills, eux aussi pris en compte seulement au prochain démarrage.

## Garde-fous

- **Aucune mise à jour sans confirmation explicite** (sauf `--modules-only`/`--check` qui restent
  cadrés). ADR-031.
- **Best-effort réseau** : une détection impossible n'est jamais une erreur bloquante.
- **Ne jamais downgrader** : l'engine saute les modules déjà à jour (comparaison de version).
- Périmètre : le **plugin VibeFlow**, ses modules, **et l'état du moteur GSD** — détecté et
  proposé dans ce périmètre, **jamais installé sans accord explicite** (ADR-031, ADR-058).
  Superpowers reste hors périmètre : la phase qui a posé cette capacité ne touche qu'au moteur GSD.
