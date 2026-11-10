# Sondes de l'audit du cockpit (2026-11-10)

Scripts de mesure écrits par les agents d'audit, versés tels quels à deux lignes près (un préfixe de dossier et une
adresse par défaut remplacés par un argument), pour rejouer une mesure avant et après un correctif. Ils n'affirment
rien et sortent toujours 0. Lecture seule : aucun n'écrit dans le dépôt ni dans `~/.claude` ; ceux qui parlent au serveur ne font
que des requêtes de lecture. Ils ne sont ni testés ni maintenus : ce sont des instruments de mesure, pas de l'outillage ni des tests.

| Script | Mesure | Arguments | Constats |
|---|---|---|---|
| `sonde-visibilite.mjs` | Ce que rend le collecteur réel pour une session et un sous-agent muets depuis N secondes, sur un dossier personnel factice ; témoin positif à 60 s. | racine du dépôt, dossier jetable | AUDC-D1, D2, D4 |
| `index-proto.mjs` | Prototype d'index de frise : un passage sur les transcripts, agrégats seulement (horodatages, usage, noms d'outils), aucun texte de conversation. | préfixe du dossier du lab sous `~/.claude/projects` | AUDC-I20, D9 |
| `mesure-page.mjs` | Coût de chargement, mise en page, traduction, redessin et saturation des flux d'une page servie, dans un Chrome sans tête propre à la mesure. | adresse du cockpit, dossier jetable | AUDC-H1, H4, AM2, AM3 |
| `mesure-2.mjs` | Fuites après N redessins, saturation des flux et reprise. | adresse du cockpit, dossier jetable | AUDC-H1 |
| `sonde-boucle.mjs` | Latence d'une requête légère toutes les 100 ms pendant 32 s : les pics périodiques montrent la boucle bloquée. | adresse du cockpit | AUDC-H2 |
| `cout-direct.mjs` | Coût d'un tour de collecte et d'une régénération du graphe Projet : sous-processus et lectures comptés. | dossier des scripts du cockpit, racine du lab | AUDC-H2 |

`mesure-page.mjs` et `mesure-2.mjs` attendent Google Chrome à son emplacement par défaut sous macOS.
