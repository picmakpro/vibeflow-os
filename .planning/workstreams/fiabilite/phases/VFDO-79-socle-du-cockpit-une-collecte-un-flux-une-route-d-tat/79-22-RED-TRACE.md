AVANT=898511f003a467b7f274d825b8d54ae74f4dac8b

# 79-22 — trace des rouges (SOCL-27, routes d'agent lues dans la table de la collecte)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Mesures de base (code de 79-13, tête 898511f0)
- `gather(` dans `revealDoing` : 1 ; `agentsConnus(` dans `reveler` : 1 ; `revealDoing`/`revealTranscript` dans `vf-cockpit-server.mjs` : 3 lignes (import, `lireDoing`, `lireTranscript`) ; `lireAgent` : 0 ; `vf-cockpit-agents-table` : 0.
- Lignes : `vf-cockpit-who.mjs` 247 (44 lignes de plus de 160 colonnes déjà là, aucune à moi), `vf-cockpit-server.mjs` 225, `vf-cockpit-collecte.mjs` 189, `-collecte-fil.mjs` 43, `-collecte-etapes.mjs` 58.
- Durée d'une lecture de transcript de 9 Mio (queue de 8 Mio lue) sur la boucle, ancien chemin : 166 ms (fixture réglée à 9 Mio : au moins 100 ms, jamais le seuil).
- Ordre de `gather` : l'ordre de liste des dossiers (pas la récence) ; la table trie donc par `ageS` croissant (les plus récents d'abord, stable) avant de couper à 2 000 ; sans `ageS` (travailleurs forgés de F7.2b) l'ordre reçu.
- H9 : `etapeTour` appelle `collectWho` une seule fois (puis `collectSignal` sur CETTE équipe) : l'option passe à cet appel. H10 : les lecteurs `lireDoing` et `lireTranscript` sont de niveau module, une promesse est permise. H11 : `cockpit_module_copie`, `cockpit_lancer`, `attendre`, `collecte-sonde.mjs` existent. H12 : `etapeTour` appelle `etapeFrise` et le fil poste `frise` avant `fini`. Toutes confirmées.

## Rouges sur le code de 79-13 (`seul-f7`, sections F7 seules ; commande : F7 extrait de `test-cockpit-frise.sh`, 8 PASS / 14 FAIL)
| Assertion | Attendu | Obtenu |
|---|---|---|
| F7.0 module neuf et options de `who` | cinq exports, `surAgents` appelé, `table` sans collecte | `absent` (module absent) |
| F7.2b borne de 2 000 | `1999,2000,2000,2000\|2000\|true,true\|true,true` | `illisible` (module absent) |
| F7.2 égalité avec l'ancien chemin | `true\|true\|true\|inconnu\|inconnu\|true\|true\|inconnu` | `illisible` (module absent) |
| F7.6 file, délai, relance | `24\|true\|40\|16\|0\|3\|true\|16\|1\|2\|true\|true` | `illisible` (module absent) |
| F7.9 chemin d'erreur en processus | `true,false,false,erreur,id,schema\|…\|oui` | `illisible` (module absent) |
| F7.1 cinquante requêtes | `50\|0` | `50\|50` (chaque requête collecte : 50 lignes `requete`) |
| F7.4 latence de boucle sous 30 lectures de 9 Mio | `1\|1\|0\|1\|30` | p99 269 ms, max 269 ms (`0\|0\|0\|1\|30`) : la lecture se fait sur la boucle |
Les mutants échouent à leur « .0 » (ancres `garde:agents-*` absentes : le module n'existe pas) ; ils se jouent après la tâche 2.

Verts d'emblée (garde-fous, chacun avec son témoin positif) : F7.3 (le marqueur de chemin ne sort déjà pas : l'ancien chemin ne porte pas le fichier ; témoins : marqueur dans un dossier de transcript du disque, balayage qui trouve un marqueur planté ; M-CHEMIN prouvera le témoin), F7.7 (trois tours, trois lignes `tour`, zéro `requete`), F7.10 (l'ancien chemin lève dans `reduireTranscript` puis rend `inconnu` par le `try` de `revealTranscript` : aucune fuite, la ligne `levee` est atteinte ; M-ERREUR-LECTURE prouvera le témoin).

## Écart de fixture
Le marqueur d'erreur `MARQ-ERREUR-79-22` ne vit pas dans le nom du fichier mais dans le message de l'erreur injectée (déclencheur : le fichier `agent-err1.jsonl`) : l'identifiant de l'agent est renvoyé par la route dans le corps, un nom marqué ferait « fuir » le marqueur par l'identifiant. En processus (F7.9) le nom forgé porte bien l'octet nul puis le marqueur.
