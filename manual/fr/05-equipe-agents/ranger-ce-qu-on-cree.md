# Ce qu'on crée, on le range

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/tidying-up-after-yourself.md)
<!-- /vf-manual:lang -->

Une mission produit de la trace : un point d'état de plus dans `STATE.md`, un rapport, un
worktree, une branche, une mémoire d'agent. Rien ne la retire, et un lab qui n'est jamais rangé
finit illisible — un fichier d'état de près de 200 Ko qu'aucun agent ne relit en entier, quinze
worktrees dont la moitié sont déjà intégrés. Cette page dit ce que VibeFlow mesure, quand il
range, et ce qu'il ne fait jamais.

## Les budgets de méthode

Un script, `check-method-budget.sh`, compare ton lab à des seuils. Par défaut, il **constate
seulement** : il ne déplace ni ne supprime rien, et il rend le code `0` même dépassé (`--strict`
rend `1` si tu veux en faire un contrôle). Chaque seuil se règle par une variable d'environnement.

| Ce qui est mesuré | Seuil | Variable |
|---|---|---|
| Un `STATE.md` (et chaque `STATE.md` de sujet) | 8 Ko | `VF_STATE_BUDGET_KB` |
| Worktrees actifs par dépôt (arbre principal non compté) | 3 | `VF_WORKTREE_BUDGET` |
| Sujets ouverts au `BACKLOG.md` | 20 | `VF_BACKLOG_OPEN_BUDGET` |
| Lignes de l'index `MEMORY.md` | 200 | `VF_MEMORY_INDEX_BUDGET_LINES` |
| `ROADMAP.md` | 64 Ko | `VF_ROADMAP_BUDGET_KB` |
| Un paragraphe de note de `STATE.md` / une entrée de `BACKLOG.md` | 12 / 40 lignes | `VF_STATE_NOTE_MAX_LINES` / `VF_BACKLOG_ENTRY_MAX_LINES` |

Il repère aussi ce qui est **rangeable** : une branche locale déjà intégrée, un worktree dont la
branche est intégrée (une branche neuve ne l'est jamais), un worktree dont le dossier a disparu
(*orphelin*), un stash sans propriétaire, une mémoire d'agent hors git ou hors de son index. Les
branches distantes ne sont jamais rangées par la machine : c'est un geste humain.

## Le rangement en fin de mission et en fin de geste

**À la clôture d'une mission,** avant de relâcher le verrou de driver, le manager lance le script
en mode `--auto`. Le script archive ce qui déborde, sans jamais rien commiter ni supprimer ; c'est le
manager qui commite ensuite cet archivage, remplace la position courante du `STATE.md` plutôt que d'y
empiler un point de plus, retire sans `--force` les worktrees et les branches intégrés que **la
mission** a créés, et élague les orphelins. Ce qu'il n'a pas pu ranger
va dans la section `## Budgets` de son rapport. Un contrôle de sortie compare l'état de fin à un
instantané pris au début de la mission : ce qui existait avant n'est jamais imputé ni rangé par
elle, et un manque bloque la sortie jusqu'à ce que le head le tranche.

**À la fin de chaque tour, hors mission,** un hook d'arrêt joue le même rôle pour une session
ordinaire, et il est **opt-in** :

- il n'agit **que dans un dépôt armé** — dont la racine contient `.planning/.fin-de-geste-armed`.
  Aucune installation ne pose ce fichier : tu l'armes toi-même (`touch .planning/.fin-de-geste-armed`
  à la racine du dépôt). Ailleurs, il ne fait rien, ne dit rien, n'écrit rien ;
- au démarrage de la session, il photographie le rangement existant ; à chaque arrêt, il archive
  ce qu'un budget dépassé désigne puis **bloque l'arrêt** tant qu'il reste du rangement **apparu
  depuis ce cliché** — worktree ou branche intégrés, stash, mémoire non indexée. Il te dit quoi
  ranger, avec les gestes exacts ;
- ce qui ne dépend pas de la session (archivage refusé, budget dépassé, vérification impossible)
  t'est dit sans jamais bloquer ;
- **coupe-circuit** : après 3 blocages de suite sans progrès, il laisse sortir avec un message
  visible, puis se tait. Une écriture d'état ratée le relâche aussi, en le disant ;
- `VF_FIN_DE_GESTE=block` (défaut), `warn` (il le dit, ne déplace rien, ne bloque pas) ou `off`.

Une limite à connaître : deux sessions ouvertes en même temps sur le même dépôt ne se distinguent
pas l'une de l'autre. Le message te rappelle donc de ne pas supprimer un objet qui n'est pas de ta
main, et le coupe-circuit borne le coût d'une méprise.

## Archiver n'est pas supprimer

L'archivage automatique est un **déplacement tracé et réversible**, pas une correction : il ne
contredit pas la règle « jamais de réparation sans ton accord » (voir
[decisions-d-architecture.md](../07-sous-le-capot/decisions-d-architecture.md)). Il vise trois
choses : les sujets clos du `BACKLOG.md`, l'historique d'un `STATE.md` au-delà de son budget (jamais
ses sections d'état ouvert), les jalons livrés d'un `ROADMAP.md` au-delà du sien.

- Le bloc déplacé atterrit tel quel sous `.planning/archives/<type>/`, une ligne
  `<!-- vf-archive: … -->` reste à sa place, et une ligne s'ajoute à `.planning/archives/INDEX.tsv`
  (date, type, source, archive, version d'origine, motif).
- **L'outil ne commite jamais** : le déplacement se voit au `git status`, et tu le relis comme
  n'importe quel changement. À la clôture d'une mission, c'est le manager qui le commite ; le hook de
  fin de geste, lui, laisse l'archivage non commité. Un fichier modifié mais non commité est refusé, rien n'est écrit. Sur un dépôt
  partitionné, seul le sujet de la session est archivé ; sans sujet résolu, rien n'est tenté.
- **Retour arrière** : la colonne « version d'origine » de l'`INDEX.tsv` est une référence git, et
  `git cat-file blob <référence>` restitue le fichier d'avant l'archivage.

Dernier détail, côté création : l'installation pose un fichier `.worktreeinclude` à la racine d'un
lab installé pour un projet. Il ne fait recopier dans un worktree d'agent que ceux de
`.claude/hooks/` et `.claude/scripts/` que git ignore ; s'ils sont suivis par git, ils arrivent dans
le worktree par git, et il ne sert à rien.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/sujets-en-parallele.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/equipes-specialisees.md)
<!-- /vf-manual:nav -->
