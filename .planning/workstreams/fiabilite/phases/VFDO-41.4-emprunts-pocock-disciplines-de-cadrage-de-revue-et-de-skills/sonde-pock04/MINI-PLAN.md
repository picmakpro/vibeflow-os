---
phase: sonde-pock04
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [compte.sh]
autonomous: true
---

<objective>
Fixture de sonde POCK-04 : étendre `compte.sh` (compte les lignes non vides d'un fichier) de deux options.
</objective>

<tasks>

<task type="auto">
  <name>Tâche 1 : option -q</name>
  <files>compte.sh</files>
  <action>Tâche 1 : ajouter l'option `-q` (silencieux : aucune sortie, code 0 si au moins une ligne non vide, 1 sinon). Le message d'usage cite l'option.</action>
  <done>`compte.sh -q f` n'imprime rien et sort en 0 si `f` a une ligne non vide, en 1 sinon.</done>
</task>

<task type="auto">
  <name>Tâche 2 : option --version</name>
  <files>compte.sh</files>
  <action>Tâche 2 : ajouter l'option `--version` qui imprime `compte 1.0` et sort en 0.</action>
  <done>`compte.sh --version` imprime `compte 1.0` et sort en 0.</done>
</task>

</tasks>
