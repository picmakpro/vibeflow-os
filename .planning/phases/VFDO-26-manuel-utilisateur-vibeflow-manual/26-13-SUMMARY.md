# 26-13 — SUMMARY (renversement : `manual/` public — mention README + vérification des liens sortants)

**Statut** : livré. Périmètre écrit : `README.md`, `README.fr.md`, ce fichier. Aucun fichier sous
`manual/**` touché (recherche seule). `.planning/ROADMAP.md` et `.planning/STATE.md` non touchés
(hors mandat de cette vague).

## Contexte du renversement

Le commit `6fcbf1d` (« feat(manual): publie le manuel utilisateur bilingue dans le dépôt »,
préalable à cette vague, hors de son périmètre) a levé la contrainte fondatrice de la mission :
`manual/` était local et hors git (`.git/info/exclude:7`) depuis l'amendement §3bis du
26-CONTEXT.md ; il est maintenant commité (94 fichiers) et l'exclusion locale est retirée. Ce
mandat reprend le volet D-7 gelé (« les README pointent vers le manuel »), réduit à une simple
mention — **pas** le dégraissage complet des deux README, qui reste hors périmètre.

## Tâche 1 — Mention du manuel dans les deux README

Ajoutée comme un paragraphe autonome (pas un nouveau `## `), juste après le bloc titre/pitch/nav
centré et son premier `---`, avant la première section de contenu — l'endroit le plus visible de
la page, immédiatement sous le pitch.

| Fichier | Ligne | Section précédente | Section suivante |
|---|---|---|---|
| `README.md` | 24 | (bloc titre centré, avant tout `##`) | `## The problem` (désormais ligne 29) |
| `README.fr.md` | 24 | (bloc titre centré, avant tout `##`) | `## Le problème` (désormais ligne 29) |

Même ligne (24) dans les deux fichiers, même décalage (+5 lignes) appliqué aux sections
existantes des deux côtés — **parité de position strictement conservée**. Nombre de sections `##`
inchangé : **12 de chaque côté** (recompté après édition), donc pas de nouvelle unité structurelle
introduite, seulement un paragraphe inséré dans l'espace inter-sections déjà présent (`---`).

Contenu (chaque fichier dans sa langue, ton propre à chacun, aucun numéro de version en dur) :

- `README.md` : `📖 **New here?** The [User Manual](./manual/README.md) walks a human through installing, understanding and running VibeFlow — no `.planning/` or `docs/` required.`
- `README.fr.md` : `📖 **Nouveau ici ?** Le [manuel utilisateur](./manual/README.md) t'accompagne pour installer, comprendre et faire tourner VibeFlow — sans jamais ouvrir `.planning/` ni `docs/`.`

Le lien `./manual/README.md` a été vérifié sur pièce : le fichier existe (`manual/README.md`,
303 octets) et route bien vers `manual/fr/README.md` et `manual/en/README.md`. Aucune autre
section des deux README n'a été touchée — aucun allègement, aucun déplacement, aucune suppression.

## Tâche 2 — Liens sortants du manuel, maintenant que `manual/` est publié

Recensement programmatique de **tous** les liens markdown inline (`[label](cible)`) sous
`manual/**` (88 pages de contenu + 3 index), cible résolue depuis le répertoire du fichier source,
en excluant les URLs `http(s)/mailto` et les ancres intra-page (`#...`). Un lien est « sortant »
si sa cible résolue quitte l'arborescence `manual/`.

**Liste complète des liens sortants trouvés — 2 au total, tous les deux résolvent :**

| Fichier source | Lien (tel qu'écrit) | Cible résolue | État |
|---|---|---|---|
| `manual/fr/07-sous-le-capot/decisions-d-architecture.md:14` | `../../../docs/ADR.md` | `docs/ADR.md` | **résolu** (existe, 103,2 Ko) |
| `manual/en/07-under-the-hood/architecture-decisions.md:14` | `../../../docs/ADR.md` | `docs/ADR.md` | **résolu** (existe, 103,2 Ko) |

Aucun autre lien sortant nulle part ailleurs dans les 91 fichiers du manuel — tout le reste des
liens relatifs reste intra-`manual/` (déjà couvert par C3 du gate). Ces deux liens, notés
« théoriquement morts » par une revue antérieure tant que `manual/` vivait hors dépôt (isolable),
**résolvent désormais réellement** depuis la racine du dépôt : confirmé sur pièce, pas seulement
déduit.

**Recherche de chemins absolus machine** (`/Users/samuel/…`) dans tout `manual/**` : **aucune
occurrence**, ni dans un lien markdown ni dans le texte des pages.

Aucun lien mort trouvé — rien à signaler en finding sur ce point, donc rien à faire remonter en
dehors de cette confirmation. Le manuel n'est pas strictement autoportant (ces deux liens quittent
`manual/`), mais c'est une sortie délibérée et documentée (D-9/canonical_refs du 26-CONTEXT.md
citent `docs/ADR.md` comme source à citer, jamais à dupliquer) — un choix de conception, pas un
défaut, maintenant que la cible résout réellement.

## Gate

```
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

Exit 0, gate non cassé par cette vague (aucun fichier sous `manual/` n'a été modifié).

## `.git/info/exclude` et `.gitignore`

Aucune entrée recréée pour `manual/` dans l'un ou l'autre fichier — vérifié : `.git/info/exclude`
ne contient plus de ligne `manual/` (déjà retirée par le commit `6fcbf1d`, préalable à cette
vague), et `.gitignore` n'a pas été ouvert en écriture.

## Ce qui n'a pas bougé

- `manual/**` : recherche et lecture seules (91 fichiers scannés programmatiquement), aucune
  écriture.
- `INSTALL.md`, `.gitignore`, `.github/**`, `scripts/**`, `plugin/**`, `docs/**`,
  `CHANGELOG.md`, `VERSION`, `.claude-plugin/**`, `.planning/ROADMAP.md`, `.planning/STATE.md` :
  aucun de ces chemins interdits en écriture n'a été touché.
- `.planning/missions/dag-phase26.json` : apparaît modifié dans `git status` à la racine mais
  préexistant à cette session (même constat que 26-11-SUMMARY) — non touché par ce mandat, non
  ajouté au commit.
- Aucun bump de version, aucun tag créé.

## Fichiers touchés (à committer par chemin explicite)

```
README.md
README.fr.md
.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-13-SUMMARY.md
```
