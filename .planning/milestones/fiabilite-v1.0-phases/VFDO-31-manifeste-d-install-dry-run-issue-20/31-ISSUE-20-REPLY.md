# Réponse à l'issue #20 — BROUILLON, NON POSTÉ

> Poster ce message sur l'issue #20 et fermer l'issue sont des gestes humains : c'est Samuel qui
> décide, lui-même, si et quand publier. Ce fichier vit sur disque en attendant sa décision.

---

Merci pour le retour terrain — précis et concret, avec le format exact que vous attendiez en plus
du besoin. Ça a rendu le travail plus facile à cadrer. Réponse point par point.

## 1. Réponse directe à la question posée

> « Est-ce que `/vf-calibrate` présente ce qu'il va poser avant de le poser ? »

Oui, désormais. Un flag `--dry-run` a été ajouté sur les verbes `install` et `update` de
l'engine (`plugin/_internal/vibeflow-update.sh`) : il rend le plan fichier-par-fichier sur
`stdout` et **n'écrit rien du tout** — ni fichier, ni registre, ni `.gitignore`, ni backup, ni
manifeste. `/vf-calibrate`, à son étape 4, invoque désormais `update <module> --dry-run` et vous
montre cette sortie **avant** le feu vert d'application qui existait déjà. `/vibeflow-install`,
à son étape 5, fait de même avant la pose réelle.

## 2. Ce qui est livré

- **Le flag `--dry-run`** sur `install` et `update`, parsé dans le même pré-parse que `--scope` —
  donc validé avant même que la commande ne s'exécute.
- **Le plan fichier-par-fichier sur `stdout`**, séparé des diagnostics (qui restent sur `stderr`,
  comme le reste du moteur) : capturable proprement par un script ou un skill.
- **Le manifeste `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`**, écrit à chaque pose réelle
  — un chemin par ligne, relatif à la racine du scope, trié, sans en-tête.
- **Le point le plus important à vos yeux, je pense** : le plan et la pose sortent du **même
  appel de code**. Il n'existe pas un « simulateur » séparé qui pourrait un jour dire autre chose
  que ce que la pose fait réellement — la dérive plan/pose est rendue **structurellement
  impossible**, pas seulement testée après coup. C'est prouvé par un test d'égalité totale entre
  l'annonce du dry-run et le diff disque réel de la pose (`T10` dans `test-manifest.sh`).
- **La convergence à l'update** : si un module change de contenu d'une version à l'autre, les
  fichiers disparus de la nouvelle version sont retirés **avec sauvegarde préalable** et liste
  affichée (`T17`-`T22`).

## 3. Le format — celui que vous avez proposé, repris tel quel

```
[plan] + .claude/scripts/guard-read-registres.sh          (consolidator v1.5.0)
[plan] ~ .claude/settings.json  hooks.PreToolUse += guard-read-registres (matcher: Read)
[plan] - .claude/rules/feature-dev-gates.md               (disparu du module, sauvegardé)
```

Les verbes `+` (créer) et `~` (modifier/fusionner) sont les vôtres, tels que proposés dans
l'issue. Le verbe `-` (supprimer) est neuf — votre exemple ne couvrait pas la convergence à
l'update, il lui fallait sa propre forme.

Le chemin affiché porte le **préfixe de scope**, tel que vous le verriez sur disque : ça donne
exactement `.claude/scripts/…` en scope projet (conforme à votre exemple) et le chemin complet en
scope compte utilisateur, où un chemin nu serait ambigu. Le manifeste lui-même reste relatif à la
racine du scope — affichage et stockage sont deux contrats séparés, délibérément.

## 4. Le merge de hooks — le cœur de votre demande

Vous l'avez dit clairement : un hook s'exécute hors de la couche de permissions, et tourne sur la
machine de votre associé dès qu'il est poussé. C'est le point où une prévisualisation compte le
plus, et c'est celui qu'on a traité en priorité.

`merge-hooks.sh` — le script qui fusionne réellement les entrées de hooks dans `settings.json` —
a appris un mode `plan` neuf. C'est lui, et lui seul, qui rend la ligne
`[plan] ~ settings.json hooks.X += …`, relayée telle quelle par l'engine. On a délibérément refusé
de réimplémenter la logique de fusion côté engine pour produire cette prévisualisation : ça aurait
créé un second chemin de code capable de dire une chose différente de ce que le merge réel ferait
— exactement le risque que vous signalez. Le mode `plan` de `merge-hooks.sh` est couvert par
7 cas de suite dédiés (`Tp1` à `Tp7` dans `test-merge-hooks.sh`), dont un qui vérifie que le
répertoire cible est **bit-à-bit inchangé** après un `plan` (`Tp3`).

## 5. Les limites — nommées sans les enrober

Trois choses ne sont pas couvertes, et il vaut mieux vous le dire plutôt que de laisser deviner.

**(a) Trois sous-processus annoncent leur effet sans énumérer leur contenu.**
`seed-registres.sh`, `inject-mcp-tools.sh` et `ensure-design-deps.sh` écrivent du contenu qui
dépend de l'état vivant de votre lab (registres de mémoire, dépendances MCP…). Le plan rend une
ligne du type `[plan] ~ <cible> (effet de <script>, contenu non énuméré)` — honnête sur sa propre
limite plutôt que de prétendre à une exactitude qu'il ne peut pas tenir. Couvert par `T12` et
`T13` dans `test-manifest.sh` (le test vérifie la présence de la ligne d'annonce, pas un contenu
qu'on ne peut pas prédire).

**(b) `--dry-run` est refusé sur `uninstall`, `rollback`, `status` et `sync` — bruyamment.**
C'est délibéré, et c'est aussi une vraie limite : le verbe le plus dangereux est précisément celui
où une prévisualisation vaudrait le plus. Un `--dry-run` accepté puis silencieusement ignoré sur
`uninstall` aurait été le pire échec possible — il aurait fait croire à une simulation et
supprimé pour de vrai. Le refus est explicite, `exit 1`, jamais un flag avalé en silence
(`T14`). L'extension du flag à `uninstall` est consignée comme candidat pour une phase suivante,
pas tranchée ici.

**(c) `docs/<module>/` apparaît au plan mais n'entre pas dans le manifeste.**
Ce chemin est écrit relativement au répertoire courant de la commande, pas à la racine du scope —
une incohérence pré-existante du moteur, non corrigée dans cette phase (le corriger aurait changé
un comportement hors du périmètre décidé). Le plan `--dry-run` l'annonce quand même, parce qu'une
écriture réelle qu'un dry-run cache serait un mensonge. Mais comme ce chemin n'est pas
représentable proprement en relatif-au-scope à travers tous les scopes possibles, il n'entre pas
au manifeste et n'est donc jamais candidat à la convergence de suppression décrite au point 2.
Cette asymétrie (présent au plan, absent du manifeste) est figée par un cas de suite dédié plutôt
que d'être un oubli silencieux.

Deux limites supplémentaires, plus mineures, découvertes en construisant tout ça et qui méritent
d'être dites aussi : le manifeste n'est pas garanti strictement à jour immédiatement après un
`update` qui ne change pas de version (fenêtre bornée, le prochain vrai changement de version le
recapture) ; et les fichiers cachés (dotfiles) d'un sous-dossier de module ne sont, aujourd'hui,
jamais copiés par la pose — comportement pré-existant du moteur, gelé par un cas de suite plutôt
que corrigé, pour rester dans le périmètre de cette phase.

## 6. Ce qu'on peut affirmer avec preuve

- La pose est tracée fichier par fichier, jamais par répertoire (`T1`, `T6`).
- Le dry-run n'écrit strictement rien, prouvé au grain du contenu disque, pas seulement au grain
  du code de retour (`T10`).
- Aucun des sept sous-processus écrivains recensés ne tourne réellement en `--dry-run`.
- La convergence à l'update sauvegarde systématiquement avant de supprimer (`T17`).
- Elle refuse d'agir sur un manifeste douteux plutôt que de « supprimer au mieux » — ligne vide,
  chemin absolu, `..`, manifeste illisible : abstention totale, bruyante (`T19`).
- Elle ne supprime jamais un chemin qui résout, une fois normalisé, hors de la racine du scope —
  y compris quand un répertoire ancêtre est un lien symbolique pointant ailleurs (`T18`, garde
  physique testée sous mutation).
- La désinstallation lit le même manifeste et applique les mêmes garde-fous que la convergence
  (`T29`-`T35`), et ne désenregistre jamais un module dont elle n'a pas su retirer les fichiers.

## 7. Le fil testeurs Windows

Vous mentionnez que les mêmes testeurs qui ont signalé le besoin seraient partants pour valider le
mode. C'est une excellente prochaine étape, qu'on propose explicitement : le mode `--dry-run` et
le mode `plan` de `merge-hooks.sh` sont exactement le terrain à faire rejouer en conditions
réelles — équipe à deux, revue croisée avant push, sur Windows. On serait preneurs du retour, en
particulier sur le format d'affichage en scope utilisateur (le préfixe complet, point 3
ci-dessus), qui n'a pour l'instant été vérifié qu'en scope projet et compte.

## 8. Ce qui a été livré, ce qui ne l'a pas été

Sur pièce, dans le dossier de la phase : les deux vagues qui consomment ce plan côté skills ont
été livrées. `31-06-SUMMARY.md` atteste le câblage de l'étape 5 de `/vibeflow-install` et de
l'étape 4 de `/vf-calibrate` pour appeler `--dry-run` avant la pose réelle. `31-07-SUMMARY.md`
atteste que `uninstall` lit désormais le manifeste avec les mêmes garde-fous que la convergence
d'update, plutôt que de continuer à s'appuyer uniquement sur l'énumération de cache historique.
Les deux étaient désignées comme sacrifiables au cadrage de la phase (pour tenir le périmètre) —
elles ont finalement été livrées toutes les deux, pas abandonnées.

---

*Brouillon rédigé le 2026-08-16. Chaque capacité citée ci-dessus renvoie à un cas de suite
vérifiable dans `plugin/_internal/tests/test-manifest.sh` ou `test-merge-hooks.sh` — rien n'est
affirmé ici qui ne soit adossé à un test qui passe sur l'arbre commité.*
