# 26-12 — SUMMARY (reliquat du renommage des slugs EN : libellés de lien français côté EN)

**Statut** : livré, gate au vert (`bash manual/.tools/check-manual.sh` exit 0, C0-C6 tous ✓).
Aucun commit produit sous `manual/` (hors git par construction, `.git/info/exclude` ligne 7).
Seul ce fichier est écrit sous `.planning/`, non commité par cet agent. `.planning/ROADMAP.md`
et `.planning/STATE.md` n'ont pas été touchés — la phase reste ouverte.

## Mandat

Le renommage des slugs EN (wave 26-10, H-1 levée) a bien mis à jour tous les `href` des liens
internes vers les nouveaux chemins anglais, mais a laissé le **libellé visible** de ces liens
inchangé — encore le nom de fichier français de l'ancien slug. Style maison du manuel (identique
FR/EN) : le libellé d'un lien interne est le nom de fichier de la page cible. Aucun lien mort
(C3 déjà vert avant cette vague), mais un lecteur anglophone voyait un nom de fichier français,
ce qui vidait de son sens le renommage.

## Méthode

Scan programmatique de tous les liens markdown inline (`[label](target)`) sous `manual/en/**`
(45 fichiers `.md`, 357 liens au total). Un lien est un candidat de correction si son libellé
se termine par `.md`, ne contient pas de `/` (exclut le style légitime du sommaire de
`README.md`, où le libellé est le chemin relatif complet, identique à l'`href`, cf. section
suivante), et diffère du **basename de la cible du lien** (`href` tronqué de tout fragment `#…`).
Le libellé correct a toujours été **dérivé de la cible**, jamais deviné ni traduit à la main.

Correction appliquée par substitution regex ciblée sur la syntaxe de lien uniquement (jamais un
remplacement de texte brut) : `[libellé](cible)` → `[basename(cible)](cible)`, cible identique
avant/après par construction — seul le libellé change.

## Cas exclus à raison — style légitime, pas un défaut

9 liens dans `manual/en/README.md` (section « Guided paths ») ont un libellé du type
`01-get-started/prerequisites.md` alors que le basename de la cible est `prerequisites.md`. Ce
n'est **pas** un défaut : le libellé y est le chemin relatif complet, exactement identique à
l'`href` résolu, et c'est le même style utilisé côté FR (`01-demarrer/prerequis.md`). Ces 9 liens
n'ont pas été touchés.

## Résultat

**73 libellés corrigés sur 26 pages EN** (sur 45 pages EN au total). Détail par fichier :

| Fichier | Corrections |
|---|---|
| `05-agent-team/specialized-teams.md` | 2 |
| `05-agent-team/why-a-team.md` | 5 |
| `05-agent-team/what-is-asked-of-you.md` | 7 |
| `05-agent-team/branches-and-worktrees.md` | 2 |
| `05-agent-team/a-long-mission.md` | 2 |
| `04-development-cycle/planning.md` | 1 |
| `04-development-cycle/executing.md` | 1 |
| `04-development-cycle/autonomous-mode.md` | 3 |
| `04-development-cycle/shipping-and-reviewing.md` | 1 |
| `04-development-cycle/the-cycle-at-a-glance.md` | 7 |
| `02-concepts/glossary.md` | 7 |
| `01-get-started/installation-troubleshooting.md` | 1 |
| `01-get-started/installation.md` | 2 |
| `01-get-started/your-first-lab.md` | 1 |
| `03-modules/choosing-your-modules.md` | 5 |
| `03-modules/business-bundles.md` | 2 |
| `03-modules/where-a-module-lives.md` | 1 |
| `03-modules/baseline-and-dependencies.md` | 3 |
| `03-modules/enabling-and-disabling.md` | 4 |
| `03-modules/catalog.md` | 5 |
| `07-under-the-hood/contributing-and-going-further.md` | 2 |
| `07-under-the-hood/architecture-decisions.md` | 3 |
| `07-under-the-hood/the-machine-gates.md` | 1 |
| `06-reference/troubleshooting.md` | 1 |
| `06-reference/skills.md` | 1 |
| `06-reference/agents.md` | 3 |
| **Total** | **73** |

Exemples représentatifs (libellé avant → après, cible inchangée) :

```
manual/en/05-agent-team/specialized-teams.md:10
[bundles-metier.md](../03-modules/business-bundles.md)
  → [business-bundles.md](../03-modules/business-bundles.md)

manual/en/05-agent-team/why-a-team.md:71
[planifier.md](../04-development-cycle/planning.md)
  → [planning.md](../04-development-cycle/planning.md)

manual/en/05-agent-team/branches-and-worktrees.md:29
[ce-qu-on-vous-demande.md](./what-is-asked-of-you.md)
  → [what-is-asked-of-you.md](./what-is-asked-of-you.md)
```

Les 19 pages EN restantes (dont `README.md`) n'avaient aucun libellé de fichier français —
aucune modification.

## Preuve — les cibles n'ont pas bougé

Extraction de la liste complète des 357 liens (`(fichier, ligne, label, href)`) avant et après
correction. Comparaison de la sous-liste `(fichier, ligne, href)` : **rigoureusement identique**
avant/après — seule la colonne `label` diffère, et uniquement sur les 73 lignes listées ci-dessus.
Le nombre total de liens est resté **357** avant et après (aucun lien ajouté, supprimé, ou dont la
cible a changé).

Re-scan post-correction : **0 mismatch réel restant** (seuls les 9 libellés-chemin légitimes de
`README.md` remontent encore, cf. section précédente — attendu, pas une anomalie).

## Sortie de `check-manual.sh` sur le manuel réel

```
$ bash manual/.tools/build-nav.sh
✓ build-nav: 44 page(s) × 2 langues, 7 thème(s) — arbre régénéré sous <racine du dépôt>/manual

$ bash manual/.tools/check-manual.sh
✓ C0 verdict non vide — 44 page(s) sur disque, 44 dans toc.yml.
✓ C1 isomorphisme fr/en — chaque id de toc.yml a sa paire fr+en complète sur disque.
✓ C2 toc.yml <-> disque — bijection stricte vérifiée pour les deux langues.
✓ C3 liens relatifs — aucun lien mort détecté.
✓ C4 bandeau <-> toc — bandeaux à jour.
✓ C5 zéro version en dur — aucune occurrence hors bloc de code.
✓ C6 format de page — aucune page au-delà de la bascule ferme (300 lignes / 3 H2).

✓ check-manual: tous les contrôles passent.
```

C3 (liens relatifs, aucun lien mort) reste vert — attendu : seuls des libellés ont changé, jamais
une cible.

`build-nav.sh` a été exécuté (régénération idempotente des bandeaux `vf-manual:lang`/`nav`/
`sommaire`) : vérifié par hash SHA-256 des 45 fichiers `manual/fr/**` avant/après son exécution —
**identiques bit à bit**, confirmant qu'aucune page FR n'a été altérée par cette régénération.

## `git status --porcelain -- manual`

```
(vide)
```

`manual/` reste hors git par construction (`.git/info/exclude`, non modifié par cette vague).
Branche `feat/phase-26-manuel-utilisateur` inchangée, aucun commit créé sous `manual/`.

## Confirmation — `manual/fr/**` intact

Aucun fichier de `manual/fr/**` n'a été ouvert en écriture par la correction de libellés (périmètre
strict `manual/en/**`). Vérifié par deux méthodes indépendantes :
- horodatage de modification (`find manual -name '*.md' -newermt …`) : seuls les 26 fichiers
  `manual/en/**` listés ci-dessus apparaissent modifiés, aucun fichier `manual/fr/**`.
- hash SHA-256 des 45 fichiers `manual/fr/**`, capturé avant toute intervention puis revérifié
  après correction des libellés **et** après exécution de `build-nav.sh` : identiques dans les
  deux cas.

## Ce qui n'a pas bougé

- `manual/fr/**`, `manual/toc.yml`, `manual/.tools/**` : jamais ouverts en écriture.
- `.planning/ROADMAP.md`, `.planning/STATE.md` : non touchés, cette vague ne clôt pas la phase.
- `README.md`, `README.fr.md`, `INSTALL.md`, `.gitignore`, `.github/**`, `scripts/**`,
  `plugin/**`, `docs/**`, `CHANGELOG.md`, `VERSION`, `.claude-plugin/**` : aucun de ces chemins
  interdits en écriture n'a été touché.
- `.git/info/exclude` : inchangé (ligne 7 : `manual/`). Aucune entrée `.gitignore` ajoutée.
