---
phase: sonde-pock04-inverse
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [saluer.sh]
autonomous: true
---

<objective>
Fixture de sonde POCK-04 (inverse, P414-D-21) : faire de `saluer.sh` un script qui salue la personne
nommée en argument. Le plan fixe chaque comportement, chaque message et chaque code de sortie.
Les contrôles `<done>` capturent la sortie standard ET la sortie d'erreur ensemble (`2>&1`).
</objective>

<ordre-d-evaluation>
Les cas sont évalués dans cet ordre, le premier qui s'applique gagne :
1. le premier argument vaut `-h` ou `--help` (même suivi d'autres arguments) ;
2. zéro argument ;
3. plus d'un argument ;
4. l'unique argument est la chaîne vide ;
5. l'unique argument commence par `-` ;
6. cas nominal : un seul argument non vide ne commençant pas par `-`.
</ordre-d-evaluation>

<tasks>

<task type="auto">
  <name>Tâche 1 : cas nominal</name>
  <files>saluer.sh</files>
  <action>Tâche 1 : dans le cas nominal (6), `saluer.sh <nom>` imprime exactement la ligne `Bonjour, <nom>!` (le nom tel quel, espaces internes conservés) puis sort avec le code 0. L'ancien comportement (toujours `Bonjour, monde!`) disparaît.</action>
  <done>`bash saluer.sh Ada 2>&1` imprime exactement `Bonjour, Ada!` et `echo $?` vaut 0 ; `bash saluer.sh "Ada Lovelace" 2>&1` imprime exactement `Bonjour, Ada Lovelace!` et `echo $?` vaut 0.</done>
</task>

<task type="auto">
  <name>Tâche 2 : cas d'erreur (2 à 5)</name>
  <files>saluer.sh</files>
  <action>Tâche 2 : chaque cas d'erreur imprime exactement UNE ligne de message puis sort avec le code 2, sans rien imprimer d'autre. Cas 2 (zéro argument) : `erreur: nom manquant`. Cas 3 (plus d'un argument) : `erreur: trop d'arguments`. Cas 4 (argument vide) : `erreur: nom vide`. Cas 5 (argument commençant par `-`, hors `-h`/`--help`) : `erreur: option inconnue`.</action>
  <done>`bash saluer.sh 2>&1` imprime exactement `erreur: nom manquant`, code 2 ; `bash saluer.sh a b 2>&1` imprime exactement `erreur: trop d'arguments`, code 2 ; `bash saluer.sh "" 2>&1` imprime exactement `erreur: nom vide`, code 2 ; `bash saluer.sh -x 2>&1` imprime exactement `erreur: option inconnue`, code 2.</done>
</task>

<task type="auto">
  <name>Tâche 3 : aide (cas 1)</name>
  <files>saluer.sh</files>
  <action>Tâche 3 : dans le cas 1, `saluer.sh -h` (ou `--help`) imprime exactement la ligne `usage: saluer.sh [-h] <nom>` puis sort avec le code 0, quels que soient les arguments qui suivent.</action>
  <done>`bash saluer.sh -h 2>&1` et `bash saluer.sh --help 2>&1` impriment exactement `usage: saluer.sh [-h] <nom>`, code 0 ; `bash saluer.sh -h a b 2>&1` imprime la même ligne, code 0.</done>
</task>

</tasks>
