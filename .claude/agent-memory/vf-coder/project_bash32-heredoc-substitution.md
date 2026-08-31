---
name: bash32-heredoc-substitution
description: Sur bash 3.2 (macOS), une apostrophe française dans un here-doc imbriqué dans $( ) casse tout le script — ne jamais charger un programme embarqué par VAR=$(cat <<'EOF').
metadata:
  type: project
---

Pour embarquer un programme (node, python, awk) dans un script bash de ce dépôt, le charger par
`IFS= read -r -d '' VAR <<'EOF' … EOF || true`, **jamais** par `VAR=$(cat <<'EOF' … EOF )`.

**Why:** bash 3.2.57 (le bash par défaut de macOS, cible dure d'ADR-054) scanne le corps d'un
here-doc **imbriqué dans une substitution de commande** à la recherche de quotes. La moindre
apostrophe française dans un commentaire du programme embarqué (« l'exporte », « d'un », « qu'il »)
y ouvre une chaîne fantôme. Le here-doc étant pourtant quoté (`<<'EOF'`), rien ne devrait être
interprété — mais l'erreur tombe quand même, et elle est **trompeuse** : `bash -n` signale
« unexpected token » **des dizaines de lignes plus bas**, sur du code parfaitement valide (constaté
sur `check-gsd-config.sh`, plan 23-02 : erreur reportée ligne 288 pour une cause ligne ~180).

**How to apply:** dès qu'un script bash de `plugin/**/scripts/` embarque un programme d'un autre
langage, utiliser la forme `read -r -d ''`. Signal de diagnostic : si `bash -n` pointe une erreur
dans un `case`/`while` visiblement correct, bisecter en amont vers le premier `$(cat <<`, et vérifier
la version (`bash --version`) — le même fichier passe sur bash 5. Corollaire de mesure : isoler la
cause en extrayant le bloc suspect dans un fichier à part et en le testant seul ; s'il passe isolé,
la faute est **avant** lui, pas dedans. Voir [[recette-grep-c-litteral]].
