---
quick_id: 260801-17w
slug: isolation-multi-session
date: 2026-08-01
status: complete
---

# Quick 260801-17w — Résumé

## Ce qui a été livré

**Doctrine — ADR-064 : un écrivain = un worktree.** ADR-059 avait vu ce trou et l'avait
explicitement laissé ouvert (« seul `isolation: worktree` le ferait. Décision distincte,
volontairement laissée ouverte »). Elle est tranchée. La branche reste nécessaire mais ne suffit
pas : deux acteurs peuvent la partager depuis un même arbre, et c'est exactement ce qui s'est
produit. `mission-contracts.md` porte la règle opérationnelle, en tête de la section d'isolation.

**`driver-lock.sh` — le claim dit sur quoi il porte.** Champs `branch=` et `worktree=` écrits à
l'acquisition, **préservés** au heartbeat : un heartbeat émis après un `git checkout` ne doit pas
revendiquer silencieusement une branche que personne n'a décidé de piloter. Champs additifs, le
contrat JSON ne bouge pas.

**`check-branch-claim.sh` — le signal atteint enfin les sessions ordinaires.** C'est le geste qui
ferme réellement le trou. Contrat à 4 codes (`0` signal · `3` SAIN · `4` INDÉTERMINÉ · `64`
usage), câblé au `SessionStart` du module `conductor`, advisory et silencieux en nominal.

## Le point que le diagnostic initial manquait

Le constat de départ — *« le verrou protège l'étape, pas la branche »* — était juste mais
incomplet. Durcir le verrou n'aurait rien changé au cas réel : **`driver-lock.sh` n'est consulté
que par les managers**, et la session qui est passée par-dessus n'en était pas un. Un verrou que
seule une catégorie d'acteurs interroge documente une intention, il ne la fait pas respecter.
D'où le choix du `SessionStart` plutôt que d'un durcissement du verrou : le signal devait sortir
du cercle des managers.

## Ce qui a été emprunté

- **`shanraisshan/claude-code-best-practice`** (indiqué par Samuel) — le worktree comme mécanisme
  d'isolation de premier rang. L'idée retenue tient en un mot : l'isolation y est **physique**,
  pas conventionnelle.
- **`1jehuang/jcode`** (étude Phase 9, ADR-053) — le verrou de driver existant, dont on a élargi
  le claim au lieu de le remplacer.

## Un défaut réel trouvé en route

Le gate comparait les chemins d'arbre **littéralement**. Sur macOS `/tmp` est un lien vers
`/private/tmp` : le même arbre se présente sous deux écritures selon qui l'interroge, et le gate
criait à la collision **sur son propre arbre** — le faux positif exact qu'il devait éviter.
Débusqué par le cas 2 de sa propre suite, corrigé par comparaison normalisée (`pwd -P`), tenu par
un cas de régression (3b) doublé d'un cas de discriminance (3c, un arbre réellement tiers doit
toujours être signalé). **Mutant tué** : la comparaison littérale réintroduite fait échouer 3b et
laisse 3c vert.

## Vérification — par exécution

| Sonde | Résultat |
|---|---|
| Les 4 codes du gate, sur cas discriminants | 18 cas, 0 KO |
| Faux positif de symlink | régression tenue, mutation tuée |
| Discriminance du TTL (même lock, TTL large → signal) | prouvée (cas 5b) |
| Silence nominal de `--hook` | stdout **strictement vide** |
| `--quiet` | totalement muet, stdout et stderr |
| Capture + préservation `branch`/`worktree` au heartbeat | prouvée sur lock réel |
| Gate sur ce dépôt, en conditions réelles | exit 3 (SAIN) |
| Suites du dépôt | **46 suites, 0 KO** |
| `check-agents --strict` × 6 dossiers · invariants · state-integrity · version-sync | tous verts |

## Deux cas de test se sont révélés faux avant le code

Le cas 5b passait un TTL (`999999999`) plus petit que l'âge forgé — un heartbeat à l'epoch 1 a
l'âge du temps Unix. Et le cas 3b se **sautait** au lieu de tester, faute de dépendre de la
topologie de l'hôte. Les deux sont corrigés : le second fabrique désormais son propre lien
symbolique, donc il s'exécute partout.

## Limite assumée

Deux sessions dans le **même** arbre sur la **même** branche ne sont pas couvertes. Elles
partagent un arbre, elles se voient — mais rien ne les empêche de committer l'une par-dessus
l'autre. C'est le cas que l'utilisateur crée délibérément ; le fermer demanderait un verrou
d'écriture dur, écarté (ADR-031 : constater et prévenir, pas arbitrer à la place de l'humain).

Module `conductor` v1.18.0 → **v1.19.0**.
