# Phase 39: Workstreams — Pattern Map

**Mapped:** 2026-09-09
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/hooks/post-merge` (D-11/D-12, filet de divergence) | config/hook | event-driven | `scripts/hooks/pre-push` | exact (même contrat d'activation opt-in) |
| `plugin/conductor/scripts/check-divergence.sh` (ou nom équivalent, S2+S4+S5) | utility/gate | batch (lecture ROADMAP+phases+STATE) | `plugin/conductor/scripts/check-state-integrity.sh` (structure) + `check-workstream-pointer.sh` (contrat de sortie/politique) | role-match fort |
| `plugin/conductor/scripts/tests/test-check-divergence.sh` | test | batch | `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` | exact (même méthodologie mutation) |
| `plugin/dev-orchestrator/agents/vf-coder.md` (amendement observance `--ws`) | agent-doc | request-response | fichier lui-même (section existante `## Compartiment de planning`) | exact — modification in-place |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md:34` (amendement observance `--ws`) | agent-doc | request-response | fichier lui-même (section existante ligne 31-34) | exact — modification in-place |
| `docs/ADR.md` § amendement daté d'ADR-069 | doc/config | transform | `docs/ADR.md:350` `### Amendement 2026-07-20 — attribution de session` | exact |
| Issue GSDA-19 re-rédigée (draft, non postée) | doc | transform | `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` | exact |

## Pattern Assignments

### `scripts/hooks/post-merge` (hook, event-driven)

**Analog:** `scripts/hooks/pre-push` (21 lignes, lu en entier)

**Structure complète à décliner** :
```bash
#!/usr/bin/env bash
# post-merge — Filet de divergence : après une fusion, détecte le split-brain de workstream
# (signature S2+S4+S5, D-11/D-12). Opt-in, non installé par défaut. Activation :
#   git config core.hooksPath scripts/hooks
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
bash "$root/plugin/conductor/scripts/check-divergence.sh" --path "$root" || {
  echo "[post-merge] divergence de workstream détectée après fusion (voir ci-dessus)." >&2
  exit 1
}
exit 0
```

**Points de convention à respecter (précédent #38, cf. CONTEXT.md canonical_refs)** :
- jamais armé par défaut — aucune écriture dans un `settings` local ; seule voie d'activation :
  `git config core.hooksPath scripts/hooks` (geste explicite de l'utilisateur).
- ne bloque QUE le cas visé (ici : divergence détectée), jamais un échec d'outillage générique.
- `post-merge` reçoit ses arguments de git nativement (pas de boucle `while read` comme `pre-push`
  qui lit refs sur stdin) — plus proche d'un appel direct au script de garde.

---

### `plugin/conductor/scripts/check-divergence.sh` (gate, batch)

**Analogs combinés** : structure générale + parsing d'arguments + codes de sortie documentés dans
l'en-tête depuis `check-state-integrity.sh` ; contrat de politique de nom / `--hook` translation
depuis `check-workstream-pointer.sh`.

**En-tête / docstring pattern** (`check-state-integrity.sh:1-74`) — reprendre le même gabarit :
docstring narratif qui nomme (a) l'incident mesuré qui motive le gate, (b) les invariants vérifiés
un par un et numérotés, (c) Usage/Defaults, (d) table exhaustive des codes de sortie sans aucun
implicite.

**Parsing d'arguments** (`check-state-integrity.sh:75-100`, identique dans les deux analogs) :
```bash
set -uo pipefail
ROOT="."
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-divergence] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-divergence] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```

**git_safe pattern** (identique dans les deux analogs, `check-state-integrity.sh:102-105`,
`check-workstream-pointer.sh:121-124`) — à reprendre tel quel :
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```

**Sourcing de la politique partagée** (`check-state-integrity.sh:118-132`, identique dans
`check-workstream-pointer.sh:154-162`) — si le gate a besoin de résoudre un compartiment de
workstream pour cibler quel ROADMAP/STATE/dossiers de phase inspecter :
```bash
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
[ -n "$WS_POLICY" ] || { echo "[check-divergence] workstream-policy.sh introuvable" >&2; exit 2; }
. "$WS_POLICY"
```

**Signature S2+S4+S5 — logique métier neuve, aucun analog existant ne la couvre** (cf.
`code_context` du CONTEXT.md : « aucun script existant ne le fait »). À construire à partir de :
- S2 : compter les numéros de dossiers de phase par compartiment (`ls .planning/[workstreams/*/]phases/`
  → extraire préfixe numérique → détecter doublon).
- S4 : comparer `#dossiers de phase` au `#entrées de ROADMAP.md` du même compartiment, et
  `progress:`/`completed_phases:` du STATE.md du compartiment (mêmes champs frontmatter que
  `check-state-integrity.sh` sait déjà extraire via `extract_int`/`extract_str`, lignes 217-222 —
  réutilisables telles quelles).
- S5 : grep les libellés de phases de workstream dans le `ROADMAP.md` RACINE (fuite de niveau).

**Codes de sortie à documenter explicitement** (suivre le gabarit à 4 états de
`check-state-integrity.sh:65-74` : 0 conforme / 1 divergence détectée / 2 non vérifiable / 64
usage) — jamais de code implicite, jamais de « vert par absence » (cf. leçon D-13 : mutation
rouge prouvée obligatoire).

---

### `plugin/conductor/scripts/tests/test-check-divergence.sh` (test, batch)

**Analog:** `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` (méthodologie lue
lignes 1-40)

**Pattern à reprendre tel quel** :
- Un cas par état du contrat, chaque cas construit sa fixture dans son propre `mktemp -d`, jamais
  sur le dépôt réel.
- **Mutation rouge prouvée obligatoire (D-13)** — exactement le motif `MUT-1`/`MUT-2` de l'analog :
  1. construire une fixture split-brain réelle (orphan / rootonly / roadmap, cf. recherche §8) et
     prouver que le gate neuf sort en rouge (1) ;
  2. construire le cas nominal non divergé et prouver le silence (0) ;
  3. muter le SCRIPT lui-même en copie temporaire pour neutraliser la détection, prouver que le
     mutant fait rougir la suite (mutant non opposable sinon).
- Env d'invocation toujours explicite (`env -u GSD_WORKSTREAM ...`), jamais d'héritage du shell
  qui lance la suite.
- Comparaison de fixtures **par `cmp`, jamais par `diff`** (outillage `diff` proxifié et mesuré
  menteur sur ce poste — cf. mémoire `project_diff-proxifie-utiliser-comm.md`, et
  `Established Patterns` du CONTEXT.md : `awk`+`comm`, jamais `grep | sort -u` ni `diff`).

---

### `plugin/dev-orchestrator/agents/vf-coder.md` / `vf-dev-manager.md` (amendement, request-response)

**Analog:** section existante elle-même (`vf-coder.md:43-51`, `vf-dev-manager.md:31-34`) — ces
fichiers DÉCLARENT déjà l'intention `--ws`, ce que D-08 exige c'est qu'elle devienne **observée par
exécution**. Le pattern n'est donc pas d'écrire une nouvelle section mais de vérifier/durcir la
section existante pour qu'aucun appel `gsd_run` de ces agents n'omette `--ws` sur un dépôt
partitionné — pas de nouvelle prose, une preuve d'exécution (le run de preuve sur clone jetable,
D-01/D-08) doit démontrer 100 % de couverture, zéro exception.

```markdown
## Compartiment de planning — passer `--ws`, ne jamais présumer

`.planning/workstreams/` existe → le dépôt est partitionné :
**passe `--ws <nom>` aux commandes du moteur** que tu invoques,
et **n'invente jamais le nom** — il vient de ton mandat ou de
`GSD_WORKSTREAM` déjà exportée. [...]
```

---

### `docs/ADR.md` § amendement daté d'ADR-069 (doc, transform)

**Analog:** `docs/ADR.md:350` `### Amendement 2026-07-20 — attribution de session (fix faux
positifs terrain)` — précédent direct de forme « amendement daté d'une ADR existante », exactement
ce que D-09/discretion exige (« Tout amendement produit par cette phase est un amendement DATÉ de
cette entrée, jamais une ADR neuve »).

**Gabarit à reprendre** (titre + sous-titre `###`, daté, sous l'ADR concernée, jamais un nouveau
numéro `ADR-0NN`) :
```markdown
### Amendement 2026-09-09 — risque (b) migré au niveau commit (`pr-branch`)

[Décrire le défaut mesuré D-09 : `.planning/workstreams/<nom>/ROADMAP.md` non matché par
STRUCTURAL_RE, exclu dans les deux modes de pr_strict, disparition silencieuse du commit de
feuille de route de workstream. Choix explicite entre correctif VF ou coût assumé daté — jamais
laissé implicite (cf. CONTEXT.md discretion).]
```

**Table de synthèse ADR** (`docs/ADR.md:36-42`, ligne 40 `| ADR-069 | 2026-08-04 | ... | Validée |`)
— si l'amendement change la portée décisionnelle, ajouter une mention « amendée le 2026-09-09 »
dans la colonne Statut, au même patron que la ligne ADR-064 (`Validée — amendée par ADR-069`).

---

### Draft issue GSDA-19 re-rédigée (doc, transform)

**Analog:** `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` (lu en entier,
extraits ci-dessous)

**Bandeau de statut obligatoire** (lignes 1-11, à répliquer verbatim dans sa structure, adapté au
nouveau contenu D-04 — angle bug de comportement, pas descripteur non descriptif) :
```markdown
> ## ⛔ BANDEAU DE STATUT — pour nos agents, PAS pour l'amont
>
> **Ce texte est rédigé et prêt à poster. Il n'a PAS été posté.** Son **dépôt est réservé à
> validation humaine** (**ADR-031**) : aucun agent ne l'ouvre en issue, aucun appel d'API de forge
> n'est exécuté. Le corps ci-dessous commence à la ligne « --- » et est **en anglais**, langue du
> dépôt amont ; ce bandeau est le seul passage en français et **ne fait pas partie du texte à
> poster**.
```

**Corps en anglais après le séparateur `---`** — titre descriptif du défaut mesuré, section
`## Summary`, table de mesures avec `fichier:ligne`, jamais un chiffre sans son critère nommé (cf.
`gsd_run query init.progress --ws default` → `project_exists: false` alors que `.planning/
PROJECT.md` existe, recherche §5 — c'est le défaut exact à documenter pour la re-rédaction D-04).

**Emplacement de fichier** : `.planning/upstream/YYYY-MM-DD-<slug>.md`, même convention.

---

## Shared Patterns

### git_safe / hooks git opt-in
**Source:** `scripts/hooks/pre-push`, `plugin/conductor/scripts/check-workstream-pointer.sh:121-124`,
`plugin/conductor/scripts/check-state-integrity.sh:102-105`
**Apply to:** le hook `post-merge` et le gate `check-divergence.sh`
- Jamais armé par défaut, activation uniquement via `git config core.hooksPath scripts/hooks`.
- `git_safe()` wrapper systématique (`-c core.fsmonitor= -c core.hooksPath=/dev/null
  --no-optional-locks`) pour toute invocation git depuis un script de garde.

### Politique de nom de workstream partagée
**Source:** `plugin/planning-core/scripts/workstream-policy.sh` (fichier SOURCÉ, jamais copié)
**Apply to:** `check-divergence.sh` — sourcer, ne jamais recopier `vf_ws_resolve`/`vf_ws_dir_resolve`.
Leçon explicite du fichier : quatre copies avaient déjà divergé une fois en un seul lot de travail
parallèle — ne pas répéter l'erreur pour le 5e gate.

### Codes de sortie exhaustifs et documentés
**Source:** `check-workstream-pointer.sh:59-72`, `check-state-integrity.sh:65-74`
**Apply to:** tout nouveau script de garde de cette phase
- Chaque code de sortie possible listé explicitement dans le docstring, jamais un code implicite.
- Distinction stricte entre « conforme » (0), « signal constaté » (1), « non vérifiable » (2) et
  « erreur d'usage » (64) — jamais de repli fail-open silencieux sur « conforme ».

### Mutation rouge obligatoire pour tout gate neuf
**Source:** `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` (motif MUT-1/MUT-2)
**Apply to:** `test-check-divergence.sh` (D-13) — fixture de split-brain construite et EXÉCUTÉE
(pas décrite), preuve que le gate détecte + reste silencieux sur le cas nominal.

### awk+comm, jamais grep|sort -u ni diff
**Source:** `docs/ADR.md:1922` § ADR-069 « Méthode, avant les chiffres » (commande bash reproduite
lignes finales de la section lue) ; confirmé par CONTEXT.md `Established Patterns`.
**Apply to:** tout comptage/couverture produit par cette phase (mesures S2/S4, comparaison de
namespace `PART` vs préfixes existants).

## No Analog Found

Aucun fichier de la liste n'est sans analog — la logique métier S2+S4+S5 elle-même (détection de
divergence) est neuve (aucun script existant ne lit ROADMAP+phases+STATE en corrélation, cf.
recherche §9), mais sa **forme** (docstring, parsing, codes de sortie, sourcing de politique) est
entièrement dérivable des trois gates `conductor`/`planning-core` existants ci-dessus.

## Metadata

**Analog search scope:** `scripts/hooks/`, `plugin/conductor/scripts/`,
`plugin/conductor/scripts/tests/`, `plugin/planning-core/scripts/`,
`plugin/dev-orchestrator/agents/`, `docs/ADR.md`, `.planning/upstream/`
**Files scanned:** 9 (lus intégralement ou par grep ciblé)
**Pattern extraction date:** 2026-09-09
