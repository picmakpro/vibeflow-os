# Phase 26 Plan 02: Portes d'entrée de langue + thème 01-demarrer complet (FR+EN) Summary

**Statut : DONE.**

Livré : les deux portes d'entrée de langue (`manual/fr/README.md`, `manual/en/README.md`) et les
7 pages du thème `01-demarrer`, chacune en français et en anglais (14 fichiers de contenu), soit
**16 fichiers produits** au total. `manual/toc.yml` porte les 7 entrées `pages:` dans l'ordre de
lecture. Aucun commit à aucun moment — `manual/` reste exclu de git de bout en bout (D-14).

## Fichiers livrés et nombre de lignes

| Fichier | Lignes |
|---|---:|
| `manual/fr/README.md` | 50 |
| `manual/en/README.md` | 50 |
| `manual/fr/01-demarrer/prerequis.md` | 109 |
| `manual/en/01-demarrer/prerequis.md` | 107 |
| `manual/fr/01-demarrer/installation.md` | 104 |
| `manual/en/01-demarrer/installation.md` | 101 |
| `manual/fr/01-demarrer/choisir-son-scope.md` | 100 |
| `manual/en/01-demarrer/choisir-son-scope.md` | 100 |
| `manual/fr/01-demarrer/premiere-session.md` | 100 |
| `manual/en/01-demarrer/premiere-session.md` | 102 |
| `manual/fr/01-demarrer/premier-lab.md` | 102 |
| `manual/en/01-demarrer/premier-lab.md` | 100 |
| `manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md` | 101 |
| `manual/en/01-demarrer/mettre-a-jour-et-desinstaller.md` | 100 |
| `manual/fr/01-demarrer/depannage-installation.md` | 100 |
| `manual/en/01-demarrer/depannage-installation.md` | 100 |

Les 14 pages de contenu (hors les 2 README, structurellement plus courts par design) sont toutes
dans la fourchette **100-300 lignes** (D-04) ; aucune ne dépasse 3 titres H2 de même rang.
`manual/toc.yml` porte exactement **7 entrées `- path:`**, une par page, dans l'ordre de lecture
(prérequis → installation → choisir son scope → première session → premier lab → mettre à jour et
désinstaller → dépannage installation).

## Verdict de `check-manual.sh`

Dernière exécution (sur `manual/` réel, sans argument) :

```
✓ C0 verdict non vide — 7 page(s) sur disque, 7 dans toc.yml.
✓ C1 isomorphisme fr/en — arbres identiques.
✓ C2 toc.yml <-> disque — bijection stricte vérifiée.
✓ C3 liens relatifs — aucun lien mort détecté.
✓ C4 bandeau <-> toc — bandeaux à jour.
✓ C5 zéro version en dur — aucune occurrence hors bloc de code.
✓ C6 format de page — aucune page au-delà de la bascule ferme (300 lignes / 3 H2).

✓ check-manual: tous les contrôles passent.
```

**Sortie : 0.** Zéro avertissement, zéro erreur — les 14 pages sont dans la fourchette recommandée
100-200 lignes (D-04), pas seulement sous le plafond dur de 300.

## Confirmation git (D-14)

`git status --porcelain -- manual` a été rejoué après **chaque** tâche (task 1, task 2, task 3) et
est sorti **vide** à chaque fois, y compris à la toute fin de ce plan. Aucun `git add` ni
`git commit` n'a été exécuté sur un chemin sous `manual/` à aucun moment. `.git/info/exclude`
n'a pas été modifié. Aucune entrée `.gitignore` créée.

Les fichiers gelés par l'amendement de mission (§3bis) sont restés inchangés tout du long :

```
git status --porcelain -- README.md README.fr.md INSTALL.md scripts .github
→ (vide)
```

## Déroulé par tâche

**Task 1** — `manual/fr/README.md`, `manual/en/README.md`, `prerequis.md` (FR+EN),
`installation.md` (FR+EN). Les deux README portent la carte mermaid `flowchart LR` décorative
(7 thèmes, ≤ 20 nœuds, sans lien/tooltip/emoji, D-06), immédiatement suivie du bloc généré
`vf-manual:sommaire`. `prerequis.md` couvre le cas Windows en entier (Git Bash, `winget install
jqlang.jq`, piège du raccourci Python du Store, neutralisation CRLF) et dit explicitement ce qui
est couvert par la CI (macOS, Debian, Ubuntu) et ce qui ne l'est pas (Windows, autres distros
Linux — M-12). `installation.md` fusionne en un seul endroit l'encadré « lancement toujours
manuel » et l'entrée de dépannage correspondante, qui étaient dupliqués à 110 lignes d'écart dans
`INSTALL.md` (D-9 résolu).

**Task 2** — `choisir-son-scope.md`, `premiere-session.md`, `premier-lab.md` (FR+EN). Comble M-6
(arbitrage des scopes, pas seulement leur liste) et M-1 (le premier quart d'heure après l'install).
`premier-lab.md` déroule `/vf-new-lab` en mode express sur un cas fictif non-dev (Karim, coach
sportif indépendant — distinct de `PetitsCoursFlow`, pas une copie, M-9) jusqu'à un lab
opérationnel.

**Task 3** — `mettre-a-jour-et-desinstaller.md`, `depannage-installation.md` (FR+EN), finalisation
des « Parcours guidés » des deux README. Présente la désinstallation à deux couches dans l'ordre
(modules puis plugin), et les quatre pannes documentées d'installation, sans redire l'encadré
« lancement manuel » déjà traité en task 1 (D-9 résolu, pas déplacé). Les deux pages renvoient en
**prose sans lien** vers `06-reference/depannage.md` (M-7, plan 26-07, pas encore écrit à ce
stade) — l'invariant 2 interdit un lien vers une page non écrite.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `manual/.tools/build-nav.sh` n'était pas idempotent**
- **Found during:** Task 1, en cherchant à faire passer le contrôle C4 (`bandeau <-> toc`) de
  `check-manual.sh`.
- **Issue:** Chaque exécution de `build-nav.sh` ajoutait une ligne vide supplémentaire entre le
  bloc `<!-- vf-manual:lang -->` et le corps de la page (et, dans une moindre mesure, dans les
  README). La cause : `write_page`/`write_readme` calculaient `rest` en ne retirant que les lignes
  vides de **fin** de flux (`rtrim_blank`), jamais celles de **début** — la ligne vide insérée
  explicitement par le template entre le h1 et le bloc de langue se réagrégeait au corps à chaque
  passage, et se recomposait indéfiniment. `check-manual.sh` (contrôle C4) reproduit exactement ce
  scénario : il copie l'arbre déjà généré puis relance `build-nav.sh` dessus, ce qui révélait
  systématiquement la dérive — le gate échouait à chaque tentative, même sur du contenu par
  ailleurs conforme. C'est un bug avéré de l'infrastructure posée par 26-01 (dont la SUMMARY
  affirmait l'idempotence, vérifiée par une fixture qui ne rejouait le script qu'une seule fois —
  la régression n'apparaît qu'à partir de la deuxième exécution).
- **Fix:** Ajout d'une fonction `ltrim_blank` (symétrique de `rtrim_blank`, déjà présente) et
  application aux deux calculs de `rest` (`write_page` et `write_readme`), avec un blanc explicite
  et unique réinjecté par le template plutôt que hérité du contenu source. Idempotence revérifiée
  par deux exécutions consécutives comparées par `md5` sur l'arbre entier : identique.
- **Files modified:** `manual/.tools/build-nav.sh`
- **Commit:** aucun — fichier sous `manual/`, hors git (D-14). Le fichier existe sur disque, vérifié
  par `bash -n` (syntaxe) et par le test d'idempotence ci-dessus.

Aucune autre déviation. Le reste du plan a été exécuté tel qu'écrit — les gonflements de longueur
de page (task 2 et task 3) pour atteindre le plancher de 100 lignes de l'acceptance criteria
n'étaient pas des déviations mais des itérations normales d'écriture pour respecter D-04.

### Note sur la vérification de niveau plan (non-bloquante)

Le bloc `<verification>` du plan (point 3) prescrit littéralement
`grep -c '^- path:' manual/toc.yml` (ancré en tout début de ligne, sans tolérance d'indentation),
qui renvoie **0** — parce que `manual/toc.yml`, posé par 26-01 et documenté dans son propre
en-tête (« indentation à 2 espaces »), écrit chaque entrée `  - path:` avec une indentation de 2
espaces. Les trois blocs `<verify automated>` des tâches de **ce** plan (26-02), eux, utilisent
tous la forme tolérante à l'indentation (`grep -c '^[[:space:]]*- path: 01-demarrer/'`), cohérente
avec `check-manual.sh` (contrôle C2, même motif). Cette dernière forme est celle qui fait autorité
— elle a été appliquée aux trois tâches et confirme **7** à chaque fois. Le motif littéral non
indenté du bloc `<verification>` de synthèse du plan est signalé ici pour mémoire, sans impact sur
le résultat : le gate réel (`check-manual.sh`, C2) valide la bijection stricte toc.yml ↔ disque.

## Known Stubs

Aucun. Les « Parcours guidés » des deux README, laissés vides et annotés à la fin de la task 1
(comme prescrit par l'invariant 2), ont été remplis en task 3 une fois les pages cibles écrites —
ce n'était pas un stub mais une séquence attendue du plan.

## Self-Check

- `manual/fr/README.md` : FOUND
- `manual/en/README.md` : FOUND
- `manual/fr/01-demarrer/{prerequis,installation,choisir-son-scope,premiere-session,premier-lab,mettre-a-jour-et-desinstaller,depannage-installation}.md` : FOUND (7/7)
- `manual/en/01-demarrer/{prerequis,installation,choisir-son-scope,premiere-session,premier-lab,mettre-a-jour-et-desinstaller,depannage-installation}.md` : FOUND (7/7)
- `manual/toc.yml` contient 7 entrées `pages:` : CONFIRMÉ
- `bash manual/.tools/check-manual.sh` sort en 0 : CONFIRMÉ
- `git status --porcelain -- manual` vide : CONFIRMÉ
- `git status --porcelain -- README.md README.fr.md INSTALL.md scripts .github` vide : CONFIRMÉ

## Self-Check: PASSED
