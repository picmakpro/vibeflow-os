---
name: symlink-ancestor-bypasses-target-root-check
description: quand realpath est banni (ADR-054), une normalisation textuelle de chemin ne détecte pas un répertoire ANCÊTRE remplacé par un symlien sortant de TARGET_ROOT
metadata:
  type: project
---

Découvert en revue live du lot 31-05 (convergence à l'update, MANI-03, vibeflow-os) le 2026-08-16,
reproduit par exécution réelle dans un lab jetable.

**Le mécanisme** : `vf_rel_to_target` (plugin/_internal/vibeflow-update.sh) normalise le chemin
PUREMENT TEXTUELLEMENT (`_vf_normalize_path`, sans `realpath`, interdit par ADR-054 pour la
portabilité). Si un répertoire INTERMÉDIAIRE du chemin (ex. `.claude/rules`) a été remplacé par un
lien symbolique pointant HORS de `TARGET_ROOT`, `vf_rel_to_target("$TARGET_ROOT/rules/x.md")`
résout quand même sous TARGET_ROOT (textuellement vrai), alors que le fichier physique réel est
ailleurs sur le disque. Le contrôle "fichier régulier, jamais un lien" (`[ -f ] && [ ! -L ]`) ne
protège QUE si la FEUILLE elle-même est un lien — un ancêtre symlinké passe au travers des deux
gardes.

**Preuve** : `.claude/rules` remplacé par un symlink vers un répertoire externe contenant un
fichier de même basename qu'un candidat légitime à la suppression → `rm -f` de la convergence a
réellement supprimé le fichier HORS TARGET_ROOT. `install_module`'s propre `cp -r` suit aussi le
symlink au passage (pollution du répertoire externe), confirmant que ce n'est pas spécifique à la
convergence : c'est un point aveugle structurel de tout le pipeline de pose de ce moteur, que la
convergence (le seul geste `rm`) rend dangereux plutôt que juste sale.

**Why** : ADR-054 bannit `realpath` (portabilité Windows/macOS/Linux sans dépendance), ce qui est
un compromis délibéré — mais aucune parade de repli n'a été posée (ex. `cd -P && pwd -P`, portable
POSIX, ne nécessite pas le binaire `realpath`, pour comparer le chemin PHYSIQUEMENT résolu plutôt
que texte).

**How to apply** : sur tout moteur qui bannit `realpath` par contrainte de portabilité et qui
effectue des opérations destructives (`rm`) sur des chemins reconstruits, tester explicitement le
cas "répertoire ancêtre remplacé par un symlien sortant du périmètre" — pas seulement "le chemin
final est un lien". Voir aussi [[feedback_multicondition-guard-mutate-each]].
