---
phase: 76
plan: "07"
requirements-completed: [TRAC-05, TRAC-06, TRAC-07, TRAC-08, TRAC-09, TRAC-11]
---

# 76-07 : Page : Décisions, Mémoire, panneaux d'ADR, de décision, d'entrée, commits : SUMMARY

## Livré

- `ui/74-vf-trace-decisions.js` (170 lignes) : section « Décisions » repliée de la vue d'ensemble (bilan fermé « 2 ADR · 3 décisions · 1 registre de phase », une ligne par ADR,
  sous-replis « Registres de phase » du plus récent au plus ancien, 30 puis « + N autres registres »), panneau d'une ADR, panneau d'une décision (phase en bouton, ADR citées dont
  une sans section en texte non interactif, décision nue sans commit), ligne de commit (`button.vf-trace-commit` si le tiroir Git existe, texte sinon), « Lecture bornée » au-dessus
  d'une liste de commits, briques partagées (`VT.ligneVoisin`, `VT.liste30`, `VT.panneauObjet`, `VT.sectionCommits`, `VT.pied`, `VT.jourFr`). Ouvreurs `adr` et `decision`
  (`VT.poseDecisions`).
- `ui/74-vf-trace-memoire.js` (161 lignes) : section « Mémoire des agents » (bilan de six emplacements repris de `memoire.compteurs`, ligne d'agent de trois lignes au plus),
  liste d'un agent (30 par page, borne dite, agent sans entrée dit), panneau d'une entrée (fiche en grille, état, liens sortants 52 px, entrants 34 px, chemins cités absents 66 px,
  pied de source), états « Pas de .claude/agent-memory/ », « .claude/ ignoré » (le nombre, jamais un nom), « Pas de git ». Ouvreurs `entree` et `agent` (`VT.poseMemoire`).
- Fichiers de 76-06 modifiés (diff minimal) : `74-vf-trace.js` (pose des ouvreurs et des deux sections après « Jalon » ; un mot de commentaire changé pour la recette « aucun
  verdict de péremption »), `74-vf-trace-liste.js` (option `avant()` : le message de borne se pose AU-DESSUS de la liste), `74-vf-trace-style.js` (commit, bilan à deux lignes, replis
  de registre, lignes d'agent et d'entrée, fiche, état, lien, chemin absent, « Lecture bornée » : jetons seulement, aucune valeur de couleur ni d'espacement en dur).
- Suite `test-cockpit-tracabilite-panneaux.sh` (54 assertions : C0, C3.1 à C3.9, C4.1 à C4.10 ; sept labs fabriqués) et deux harnais, `chrome-tracabilite-panneaux.mjs` (128 lignes) et
  `chrome-tracabilite-memoire.mjs` (163 lignes).
- `VENDORED.txt` : deux lignes `AJOUT` à leur place alphabétique, `assets/ui/74-vf-trace-decisions.js` (entre `73-vf-tiroir-travail.js` et `74-vf-trace-exigence.js`) et
  `assets/ui/74-vf-trace-memoire.js` (entre `74-vf-trace-liste.js` et `74-vf-trace-rendu.js`). La première est posée au commit de la tâche 1 (le fichier naît là), pas de la tâche 2.
- `README.md` et `README.fr.md` : compteur recalé à 238 suites (recompté sur l'arbre : `find */tests/test-*.sh`) ; `check-version-sync.sh` vert (237 avant ce plan).
  `scripts/ci-shard-suites.sh` découvre les suites par `find` : aucune déclaration à faire.

## Revalidations demandées par le plan

- Tiroir Git : `window.VFGitTiroir` expose `ouvrir`, `ouvert` et `ouvrirSur(sha)` (« entrée publique pour les autres phases (74) » de `77-vf-git-tiroir.js`), pas seulement le crochet
  `VFGitExt` du plan. Le clic appelle `ouvrirSur(h7)` quand il existe, et retombe sur `ouvrir()` si la sélection échoue ou si l'objet n'a pas `ouvrirSur` (l'espion de C3.7 n'a que `ouvrir`).
- Ordre des Retour constaté (C4.6, boutons et panneaux, jamais des appels comptés) : (a) Jalon, phase 90, REQ-01 : le Retour nomme la phase, puis la phase, pile vide (bouton désactivé) ;
  (b) Décisions, ADR-001, P90-D-01, phase 90 : le Retour nomme P90-D-01, puis rouvre P90-D-01 (Retour : ADR-001), puis ADR-001, puis la vue d'ensemble, pile vide ensuite, aucune vue répétée ;
  (c) entrée, entrée cible par un lien résolu : le Retour nomme l'entrée quittée ; Échap (focus sur le titre) rappelle le Retour commun et le Retour nomme alors « Entrées de vf-coder » ;
  (d) phase 90, REQ-01, décision citée : le Retour nomme REQ-01, puis REQ-01 rouvert (Retour : la phase), puis la phase 90.
- `VF_PANNEAU`, `VF_COQUILLE`, `VF_ETAT` lus à l'appel, jamais gardés ; C4.10 : après Projet, Code, Projet, ADR, décision et entrées s'ouvrent, s'empilent et reviennent comme à la première
  arrivée ; les clés `vf-coder%2Fa.md`, `P90-D-01%3Aph-90` et `ADR-001` passent la grammaire de `lireJson` (aucun refus, requêtes vues au réseau).

## Écarts

- Écart : le nom d'une entrée (`name`) titre le panneau ET la pile commune ; il n'est connu qu'après lecture, donc `VT.ouvrirEntree` lit l'entrée AVANT d'ouvrir (une requête de plus, mise en
  cache par la zone seulement après rendu) pour que le Retour nomme l'entrée quittée par son `name`.
- Écart : le bilan de la Mémoire a SIX emplacements (UI-SPEC § 4.3 et § 10.1, « chemins cités absents » compris), pas les cinq de la phrase de C4.1 du plan ; le compteur de la section est
  « N entrées » (§ 4), non « N agents ».
- Écart : la route ne sert pas `titreCoupe` (seul le titre coupé à 80 caractères, terminé par « … ») : la ligne « Titre coupé à 80 caractères. La définition entière est dans … » se
  déclenche sur le « … » final. Elle n'est pas exercée par un test (aucun titre de 80 caractères dans les labs).
- Écart : « Liste d'un agent sans entrée » est atteinte par un agent dont seul l'index est suivi (dossier `vide`, ajouté au lab L : le bilan dit donc 3 agents).
- Écart : C4.9 et M-EXCLUSION (passage au garde d'inventaire du français) non rejoués : comme en 76-06, les fichiers à marqueur `// VibeFlow (` sont hors inventaire et le garde F4 rougirait
  sur une exclusion absente de l'inventaire ; `vf-cockpit-fr-exclusions.json` n'est pas touché. `test-cockpit-chrome-fr.sh` est vert (141).
- Écart : C4.7 ne vérifie pas « trois onglets dans l'en-tête » (aucun marqueur d'onglet repérable dans la page, ni `role="tab"` ni `tablist`) ; le reste de C4.7 est joué.
- Écart : C4.8b contrôle le fichier exporté seulement (trois marqueurs absents ; le code de la 76 y figure, donc les chaînes `data-vf-trace-` aussi), pas une page autonome servie à part.
- Écart : la ligne de commit est sur deux lignes (sha et jour, puis le sujet en ellipsis) : l'UI-SPEC § 5.5 n'impose pas de gabarit de hauteur ; à juger sur captures en fin de phase.
- Écart : UI-SPEC § 11 (aucun défilement horizontal à 1440, 1024 et 390 px, cibles de 44 px au tactile) : règles écrites dans la feuille (min-height 44 px non étendu aux nouvelles lignes
  hors `.vf-trace-plus`, summary et `.vf-ref` déjà couverts), AUCUNE mesure de largeur faite pour ces panneaux (régime allégé) ; à reprendre par la passe de juge sur captures.
- Écart : le recul de pile est toujours celui de 76-06 (`ouvrirSurMesure` empile la vue d'ensemble quittée) : `courant` null au départ de la vue d'ensemble, qui est donc la dernière entrée
  de la pile (b) ; aucun appel direct à `empiler` dans les fichiers de ce plan.
- Aucun contrat consommé par une autre phase (73, 77, 79, 80) n'est changé ; pas de ligne ajoutée à `EVENEMENTS` de `ui/69-vf-flux.js`.

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : les neuf mutants du plan (M-NUE-PAGE, M-PLAFOND-30,
  M-ETAT-REPETE, M-CORAIL-NEUTRE, M-EXPORT-DM, M-PILE-DECISIONS, M-EXCLUSION, M-CLE-CRUE, M-REF-GARDEE), la triple passe, le rejeu suite par suite et le rejeu des cas sautés.
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : étage design `craft` et `critique` (aucun sous-agent
  lancé ; pas de juge de design sur ce plan, une passe de juge sur captures à la fin de la phase). Pas de `craft` ni de `critique` à consigner.
- Un commit par tâche (trois), au lieu de deux par tâche (test puis code) du plan : le test est vu rouge, son extrait est dans `76-07-RED-TRACE.md`, puis le code et le test partent ensemble.
- Le témoin rouge de chaque tâche est dans `76-07-RED-TRACE.md`. C3.6 et C3.7 étaient déjà verts à la tâche 2 (plafond et ligne de commit sont du code de la tâche 1) ; C4.6a, C4.6b, C4.4
  et C4.8b l'étaient à la tâche 3 (voir la trace).

## Suites jouées (une fois, sur la tête commitée `366d0080`)

| Suite | Verdict | Durée |
|---|---|---|
| `test-cockpit-tracabilite-panneaux.sh` | 54 PASS / 0 FAIL | 68 s |
| `test-cockpit-tracabilite-page.sh` (fichiers de 76-06 modifiés) | 54 PASS / 0 FAIL | 53 s |
| `test-cockpit-chrome-fr.sh` | 141 PASS / 0 FAIL | 44 s |
| `test-cockpit-vendor.sh` | 252 PASS / 0 FAIL (V4 et V4c.9a verts) | 172 s |
| `scripts/check-version-sync.sh` | exit 0, § 9 vert (238 suites) | 1 s |

Temps total des suites de la tête : environ 338 s (hors les rejeux de développement de la suite neuve).
