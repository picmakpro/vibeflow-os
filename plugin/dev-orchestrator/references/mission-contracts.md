# Référence — Contrats de mission (équipe manager)

> Source unique des contrats qui relient la conversation principale et les managers d'équipe
> (`vf-dev-manager`, `vf-design-manager`) au mode autonome (`vf-auto`). Consommée par :
> `AGENT.md` (router), `skills/vf-auto/SKILL.md`, `agents/vf-dev-manager.md`,
> `design-orchestrator/agents/vf-design-manager.md`. **DRY : ne dupliquer ces contrats nulle
> part — y renvoyer.** Spec d'origine : docs/superpowers/specs/2026-07-09-dev-manager-team-design.md
> (DM1-DM6) ; champs et digest croisés dev ↔ design : Phase 15 (`15-CONTEXT.md` D-01..D-11).

## Brief de mission (main → manager)

Le dispatcheur (router ou vf-auto) passe au manager un brief **minimal**. Le disque
(`.planning/`) reste la source de vérité : le brief ne porte QUE ce qui n'y est pas.

```
MISSION
- Périmètre : <phases ciblées (numéros) OU objectif libre>
- Mode : superviser (checkpoints humains) | autonome (les panels tranchent)
- Design : auto (défaut) | force | off
- Livrable : specs (défaut) | specs+implementation
- Contraintes session : <décisions déjà prises en conversation qui engagent la mission — 2-3 lignes max>
- Budget : <optionnel : temps / tentatives ; sinon défauts du manager>
```

### Champs croisés dev ↔ design (D-02, D-05)

- **`design: auto|force|off`** (défaut `auto`) — gouverne l'étage design croisé d'une **mission
  dev** (`vf-dev-manager`). `auto` = jugement du manager au plan de bataille (objectif de
  l'étape dans la ROADMAP, présence d'un `DESIGN.md`/UI-SPEC, nature des livrables) ; `force`
  impose les nœuds `craft:<écran>`/`critique:<écran>` même sur un cas limite ; `off` les
  interdit explicitement, quel que soit le jugement du manager. Produit par : le dispatcheur
  (routeur `vibeflow-dev`, `vf-auto`, ou mapping langage naturel). Consommé par : `vibeflow-dev`,
  `vf-auto`, `vf-dev-manager`. **Absent → `auto`** (comportement actuel, zéro surprise).
- **`livrable: specs|specs+implementation`** (défaut `specs`) — porté par le brief d'une
  **mission design** (`vf-design-manager`). `specs` = comportement actuel du module (aucun
  changement) ; `specs+implementation` = opt-in, le manager dispatche `vf-coder` pour incarner
  les specs du crafter, avec double juge parallèle (doctrine détaillée :
  `mission-cross-team.md` §Étage implémentation (mission design)). Produit par : le dispatcheur
  d'une mission design (`vibeflow-design` — le propose quand le projet a du code — ou
  l'utilisateur). Consommé par : `vf-design-manager` uniquement. **Absent → `specs`** (zéro
  surprise).

Le brief peut aussi être du **langage naturel brut** (« finis la milestone, la nuit ») : le
manager le mappe lui-même vers périmètre/mode/contraintes via la carte d'intention
(`intent-routing.md`) — il demande (AskUserQuestion) seulement si le périmètre reste
inexploitable. Le manager relit lui-même `.planning/ROADMAP.md`, `.planning/STATE.md`,
`.planning/PROJECT.md` — le brief ne les paraphrase jamais.

## Digest de mission (manager → workers)

Le disque reste la source de vérité, mais chaque mandat de worker **embarque un digest ≤ 30
lignes** qui amortit les relectures intégrales de `.planning/` à chaque étage (audit
2026-07-25 : 100-200k tokens de pure relecture par étape sans lui) :

```
DIGEST (cache — le disque fait foi)
- Mission : <objectif en 1 ligne> · Mode : <superviser|autonome>
- Étape courante : <n° + objectif + critères de succès>
- Périmètre de fichiers du nœud : <déclaré au dag add>
- Décisions actives : <2-5 lignes — panels tranchés, contraintes session>
- Verdicts amont utiles : <revue/audit/test pertinents pour ce mandat>
- Conventions cibles : <2-3 lignes du CLAUDE.md projet qui engagent ce mandat>
```

**Variantes croisées (D-10)** — le format ne change pas, seul le contenu des bullets
`Conventions cibles` / `Verdicts amont utiles` s'adapte à la direction du mandat :
- mandat dev → `vf-crafter`/`vf-design-judge` (étage design en mission dev) : `Conventions
  cibles` embarque la DA en 3-5 lignes (tokens clés, personnalité — même format que le digest
  design existant, cf. `vf-design-manager.md` §Orchestration par écran), en plus du CLAUDE.md.
- mandat design → `vf-coder`/`vf-reviewer` (étage implémentation en mission design) :
  `Conventions cibles` embarque les conventions code cibles (CLAUDE.md du projet, conventions de
  commit, périmètre de fichiers du nœud) ET pointe la spec du crafter (chemin sur disque) comme
  **source du cadrage** — l'entrée de `vf-coder` devient cette spec, pas la ROADMAP (sa chaîne
  `gsd-discuss-phase` s'y ancre).

Le worker lit le digest D'ABORD, et ne relit du disque que ce que son mandat exige
(index-first). Un digest contredit par le disque → le disque gagne, et le worker le signale.

## Isolation de branche (ADR-059) — toute mission d'équipe

**Une mission d'équipe ne commite jamais sur la branche par défaut.** Dès qu'un manager est
dispatché (`vf-dev-manager`, `vf-design-manager`), il crée **d'abord** une branche dédiée, y tient
tous ses commits, et termine par une **PR laissée ouverte** — le merge appartient à l'utilisateur
(ADR-031). Le travail conversationnel direct (un correctif, une doc, un cadrage mené dans le fil)
**reste hors de cette règle** : sans elle, chaque échange créerait une branche.

**Pourquoi** : une mission autonome produit des dizaines de commits sans supervision. Sur la
branche par défaut, le seul recours après coup est un `revert` en masse d'un historique déjà
poussé et potentiellement déjà consommé par d'autres. Sur une branche, le recours est de ne pas
merger. La PR donne en prime le point de relecture groupée qu'un rapport de fin de mission ne
remplace pas.

**Protocole, dans l'ordre :**

1. **Avant le premier commit** — vérifier que l'arbre est propre, puis créer la branche depuis la
   branche par défaut à jour. Convention de nom : `feat/<périmètre-en-kebab>` (précédents du dépôt
   VibeFlow : `feat/phase-13-pont-vf-ingest`, `feat/v3-team-kernel`). Une mission = une branche,
   même quand elle couvre plusieurs étapes.
2. **Pendant** — tous les commits de la mission et de ses workers y vont. Le manager ne bascule
   jamais de branche en cours de route et ne merge jamais lui-même.
3. **À la fin** — pousser la branche et ouvrir la PR (`gh pr create`), titre et corps dérivés du
   rapport de mission. **Ne jamais merger, ne jamais fermer.** Le rapport rendu à la conversation
   principale cite l'URL de la PR.

**Replis, dans cet ordre — une mission n'échoue JAMAIS pour cette règle :**

| Situation | Comportement |
|---|---|
| Pas un dépôt git | Aucune branche. Le manager le **dit** dans son rapport et travaille en place. |
| Dépôt git, aucun remote | Branche créée quand même, **pas de PR**. Le rapport donne le nom de la branche et la commande de merge. |
| Remote présent, `gh` absent ou non authentifié | Branche créée et **poussée**, PR impossible. Le rapport donne l'URL de création de PR. |
| Arbre sale au démarrage | **Ne rien stasher.** Le manager remonte à l'utilisateur avant de créer la branche — c'est une halt condition, pas une décision d'autonomie. |
| `CLAUDE.md` du projet cible impose un autre flux | Le projet cible **prime** (contrat de brief : ses conventions de livraison font foi). |

**Ce que cette règle ne couvre pas** : l'isolation des **vagues parallèles à l'intérieur** d'une
mission, qui partagent le même arbre de travail. Une branche par mission ne les sépare pas entre
elles — seul `isolation: worktree` le ferait, et c'est une décision distincte, non tranchée ici.

## Contrat `estimate:`/`actuals:` (calibration amont, gsd-core 1.9.0)

`gsd-planner` (1.9.0) écrit un bloc `estimate:` dans le frontmatter du `PLAN.md` qu'il produit
(`tokens`, `raw_tokens`, `tasks`, `confidence`) ; `gsd-executor`, **quand le plan portait un
`estimate:`**, écrit en retour un bloc `actuals:` dans le frontmatter du `SUMMARY.md` (`tokens`,
`tasks`, `commits`). Trois règles amont, non négociables, à ne jamais affaiblir en les
retranscrivant :

- **`confidence` est DÉRIVÉE du nombre d'échantillons, jamais auto-évaluée** — un agent ne « se
  sent » pas confiant, il compte ses échantillons.
- **Même échelle des deux côtés** : `actuals.tokens` se mesure en `chars/4` sur les fichiers
  réellement changés, **jamais** un compteur du harness — sinon on mesure les méthodes de mesure,
  pas l'écart.
- **Aucun arrondi flatteur** — un nombre flatté corrompt toute projection ultérieure.

Ces deux blocs sont produits **directement sur disque** par `gsd-planner`/`gsd-executor` — rien à
faire côté VibeFlow pour qu'ils existent. Le risque n'est pas leur absence, c'est leur **perte
silencieuse** au passage `vf-coder` → `vf-dev-manager` → conversation principale : ni le bloc typé
de `vf-coder` (Pattern C, `mission-flow.md`) ni le gabarit « Rapport de mission » ci-dessous ne les
mentionnaient avant cette entrée.

**Propagation retenue** — le disque reste la source de vérité, mais le bloc typé de `vf-coder`
gagne deux champs **optionnels**, frères de `statut`/`findings`/`noeuds_debloques` :

```
"estimate": { "tokens": …, "raw_tokens": …, "tasks": …, "confidence": "low|med|high" },
"actuals":  { "tokens": …, "tasks": …, "commits": … }
```

Présents **uniquement** quand le `PLAN.md`/`SUMMARY.md` du mandat les portait — absents sinon
(aucune valeur inventée, même conditionnalité que l'amont). `vf-coder` les **recopie verbatim**
depuis le frontmatter qu'il a produit ou lu : il ne recalcule, n'arrondit ni ne réinterprète jamais
ces nombres — ce serait précisément l'arrondi flatteur que l'amont proscrit. `vf-dev-manager` fait
de même en les relayant dans son « Rapport de mission » : simple concaténation par sprint, aucune
statistique agrégée de son cru — la boucle de calibration reste amont, notre seul devoir est de ne
pas couper le fil.

## Étage revue — deux objets disjoints (ADR-060 / ADR-061)

La revue de **diff de code** (`vf-reviewer` → `gsd-code-reviewer`, nœud `revue-N` posé
systématiquement par le manager, ADR-060) et la revue **cross-AI de plans** amont (`gsd-review`,
lanes déclarées par `review-lane-descriptor.cjs`, ADR-2782 Phase 1, opt-in utilisateur via
`--reviews`) sont deux étages **disjoints** — objet revu, moment du cycle et déclencheur diffèrent
sur les trois axes. Arbitrage complet, avec le critère écrit : `docs/ADR.md` ADR-061. Aucun
câblage automatique de `gsd-review` dans le DAG de mission — décision distincte, non prise ici.

## Rapport de mission (manager → main)

Retour **compact**. Le détail vit sur disque, pas dans la conversation.

```
RAPPORT DE MISSION
- Verdict global : ✅ | partiel | bloqué
- Par sprint : fait / verdicts (recette, revue, audit) / commits (SHA)
- Calibration (si portée) : estimate vs actuals par sprint — recopiés verbatim, jamais recalculés
- Décisions prises en autonomie (et par quel panel)
- Blocages & points nécessitant l'utilisateur
- Rapport détaillé : <chemin du fichier écrit sur disque>
```

## Signaux « mission » (détection côté router)

≥ 1 signal déclenche la **PROPOSITION** du manager — jamais le dispatch d'office :

- **multi-phases explicite** : « phases 3 à 5 », « toute la milestone », « enchaîne les sprints » ;
- **durée / absence** : « la nuit », « pendant que je suis pas là », « demain matin je veux… » ;
- **étages multiples combinés** : la demande couvre build + test + revue/audit d'un coup ;
- **longue haleine estimée** : la demande couvre plus d'une étape de la feuille de route.

Tâche simple sans signal → routage direct **sans question** (zéro friction sur le quotidien).

## Seuil de bascule (vf-auto)

`SEUIL_EQUIPE = 3` — N = étapes restantes ciblées, comptées via `gsd-tools roadmap analyze`.

Résolution — cascade de résolution, jamais un chemin en dur (D1 ; forme reprise, variante
Claude-only, de `gsd-core/workflows/_runtime-launcher.snippet.sh`, gsd-core 1.8.0) :
```sh
_GSD_ROOT="${RUNTIME_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
GSD_TOOLS=""
for _c in "$_GSD_ROOT/gsd-core/bin/gsd-tools.cjs" \
          "$_GSD_ROOT/.claude/gsd-core/bin/gsd-tools.cjs" \
          "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"; do
  [ -f "$_c" ] && { GSD_TOOLS="$_c"; break; }
done
if   [ -n "$GSD_TOOLS" ];                  then gsd_run() { node "$GSD_TOOLS" "$@"; }
elif command -v gsd-tools >/dev/null 2>&1; then GSD_TOOLS="$(command -v gsd-tools)"; gsd_run() { "$GSD_TOOLS" "$@"; }
else echo "ERROR: gsd-tools.cjs introuvable. Installer : npx -y "@opengsd/gsd-core@^1" --claude --global" >&2; exit 1; fi
```
`gsd_run roadmap analyze` remplace l'ancien appel direct. **Prérequis non garanti** : si
`gsd_run` ne peut pas se résoudre (bloc `else` ci-dessus), fallback documenté — compter les cases
non cochées du périmètre dans `.planning/ROADMAP.md` : `grep -c '^- \[ \]'` ou équivalent ; jamais
de blocage silencieux sur l'outil manquant.

**Test du succès sur le JSON, jamais sur `$?` (D2)** : `gsd-tools` sort exit 0 même en erreur
métier. Le fallback grep ci-dessus se déclenche donc aussi si la sortie JSON de `gsd_run roadmap
analyze` contient un champ `.error` — pas seulement si le binaire est introuvable. Ne jamais tester
uniquement le code de sortie du processus.

**Rester sur le dist-tag stable, jamais le canal de pré-version amont (D4)** : le canal de
pré-version est périmé (1.7.0-rc.6, antérieur au tag stable = 1.8.0) — n'utiliser que `@latest`
dans le message d'erreur ci-dessus et partout ailleurs dans ce document.

Écarts assumés vs le snippet officiel amont (D5) : (a) les runtimes non-Claude du snippet sont
retirés (VibeFlow est un plugin Claude Code) ; (b) `command -v gsd-tools` est placé après les
chemins fichiers (le payload installé prime sur un bin npm global potentiellement d'une autre
version) ; (c) ce document n'écrit jamais dans `CLAUDE_ENV_FILE`.

Application du seuil :

- **N < SEUIL_EQUIPE ET aucun signal de durée** → moteur direct (boucle autonome inline, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → équipe (`Task(vf-dev-manager)` avec le brief ci-dessus).

Le signal de durée **GAGNE** en cas d'ambiguïté (N=2 mais « la nuit » → équipe). Seuil ajustable
ici et ici seulement.
