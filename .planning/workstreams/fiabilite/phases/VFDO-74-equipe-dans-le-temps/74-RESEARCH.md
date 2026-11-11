# Phase 74 : L'équipe dans le temps (swim-lanes, coût, replay) - Research

**Researched:** 2026-11-11
**Domain:** couche d'affichage du cockpit (modules `ui/*vf*` du moteur vendorisé), lecture des contrats de la Phase 79, suites shell + Node + Chrome headless
**Confidence:** MEDIUM. Le code présent est relevé et cité ligne à ligne (HIGH). Ce que la 79 et la 73 livreront n'existe pas encore (MEDIUM à LOW) : tout plan qui le consomme est marqué « à revalider sur la 79 » ou « à revalider sur la 73 ».

Recherche menée en lecture seule dans le worktree `phase-74` (base `f763b556` + cadrage `f87ae937`). Aucune suite lancée,
aucun serveur, aucun navigateur, aucune recherche web (rien à installer). Les numéros de ligne sont ceux de ce worktree.

<user_constraints>
## User Constraints (from CONTEXT.md)

Source : `74-CONTEXT.md` (P74-D-01 à P74-D-37). Le CONTEXT fait foi : ce qui suit en est un relevé fidèle, sans
reformulation des décisions ; en cas d'écart, relire le CONTEXT.

### Locked Decisions

Toutes « décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée » ; aucune n'est un
arbitrage de Samuel.

- **Arbitrages repris sans les rouvrir** : AUDC-Q2 (index borné à heures, durées, jetons, verbes ; fenêtre de 24 h ; « 7 j »
  hors périmètre), AUDC-Q4 (`claude agents --json` source de référence, transcripts en repli), AUDC-Q3 (aucune action sur
  une session), AUDC-Q5 (fork du moteur assumé) ; P67-D-02, P67-D-14, P69-D-15, P69-D-16, P69-D-19, P69-D-23, PU-G-162 ;
  Q9 et `DESIGN.md` § 9, P71.5-D-01 (grille 2, 4, 6, 8, 12, 16, 20, 24, 32), Q11, Q12, P78-D-04, Q8, P68-D-03.
- **P74-D-01** couleur aux trois états seulement, le nœud s'écrit sur la voie, jamais une couleur par nœud.
- **P74-D-02** bascule « Régie · Frise » dans l'en-tête de l'onglet Équipe, régie par défaut, position gardée pour la page,
  jamais dans un fichier du lab ; posée par la 73 si elle la livre d'abord, sinon par la 74.
- **P74-D-03** la fiche EST le lecteur plein cadre (zone de contenu de l'onglet Équipe, deux colonnes, une au téléphone),
  remplace la boîte de 320 px ; pas un tiroir ; Échap ou « Retour » ferme et rend le focus ; aucune adresse dans l'URL.
- **P74-D-04** ouverture depuis une voie de la frise et depuis une ligne de la régie (même fonction) ; pas d'intertitre
  « Mandat » pour une session.
- **P74-D-05 à D-11** (frise) : une voie par agent, enfant sous parent, trait au dispatch ; quatre sortes de segment
  lisibles sans couleur, « vous attend » hachuré **sans contour** ; événements compaction, erreur, message humain, rapport,
  dispatch ; commits sur un bandeau « Dépôt » par branche, jamais attribués à un agent, clic → tiroir Git ; fenêtres 1 h 30
  (défaut), 6 h, 24 h ; lectures Horloge (défaut) et Événements (silences > 2 min compressés) ; repli au-delà de douze
  voies, compte écrit, courbe des agents au travail ; direct par l'événement `frise` (signature) puis relecture
  authentifiée, aucune donnée de frise dans le flux.
- **P74-D-12 à D-14** (relecture) : curseur pointeur et flèches ; encart « À cet instant » ; état d'un nœud à t dérivé des
  voies (jamais `ready`/`blocked`) ; fichiers à t lus à la demande dans le fil réduit, jamais persistés ; « Voir sur la
  carte » = mise en évidence ponctuelle sur l'onglet Code.
- **P74-D-15 à D-19** (fiche) : faits (rattachement à trois liens, durées par segments, contexte en jetons, compactions
  comptées, appels et erreurs, jetons par catégorie, fichiers écrits et lus, « inconnu » jamais zéro) ; pourcentage de
  contexte seulement sur taille documentée ; fil daté, filtres cumulables, suivi en direct, coupe dite, mandat replié ;
  markdown par sous-ensemble fermé en nœuds DOM, liens non cliquables, CSP inchangée ; une erreur dit « échec » sans texte.
- **P74-D-20 à D-24** (coût) : jetons et durée, aucun montant en devise ; agrégats par agent, mission, phase, étage,
  « hors mission » à part, chaque agrégat porte sa fenêtre ; **un seul calcul de jetons**, celui de l'index de la 79 (la 74
  agrège, ne recompte jamais) ; temps perdu à attendre l'humain ; pas de limites de 5 h / 7 jours.
- **P74-D-25 à D-27** (données) : la 74 ne lit aucun transcript elle-même (route de frise, route d'état, route de
  transcript existante) ; tout champ affiché déclaré au contrat de forme, `schema` lu avant tout champ ; durée affichée =
  somme des segments, `dureeS` de `cockpit-who@2` reste émis ; routes GET derrière Host, Origin, jeton ; cinq clés
  refusées dans le flux ; export sans frise, fiche ni fil ; chaîne XSS étendue.
- **P74-D-28** retraits : boîte de transcript du panneau et « Lire le transcript » ; durée qui compte les veilles ; avec
  la 73, la carte « Terminés depuis moins de 24 h » (la 74 le fait si la 73 ne le fait pas).
- **P74-D-29 à D-31** : glyphes = table unique de la régie (ou `GLYPHE` de `71-vf-equipe-rendu.js` à défaut) ; choix de
  forme de l'UI-SPEC acceptés (trait neutre pour « attend ses agents », clic colonne = fiche, clic piste = curseur, faits
  sur 24 h, « autour de t » = ± 2 min, synthèse entrée/sortie, liens `#r=` redirigés vers la fiche, colonne collante au
  téléphone, `sessionStorage`) ; **aucun fichier du moteur modifié** (`viewer.html`, `serve.mjs`, `scan.mjs`), rendu dans
  des modules `ui/*vf*`, exécution après la première vague de la 79.
- **P74-D-32** jetons d'une voie = sa vie dans les 24 h (libellé « sur les dernières 24 h »), durées = fenêtre affichée.
- **P74-D-33** `rangees[].at` en secondes (× 1000) ; marche Git bornée : la 74 mesure la couverture et dit « incomplet ».
- **P74-D-34** `rattachement { dag, noeud: null, source: "enfants" }` rattache le manager à la mission ; aucun nœud écrit
  sur sa voie ; la fiche dit « rattaché par ses agents » ; `rattachement.dag` = `signal.missions[].fichier` ; mission →
  phase par `phaseKey`.
- **P74-D-35** un déplacement du curseur relit au plus six fils réduits (voies au travail à t), cache jusqu'au `frise`
  suivant ; au-delà ou hors plafond, « fichiers non lus ».
- **P74-D-36** `silence` ne dessine rien (blanc), distinct du repos ; à confirmer à la recette.
- **P74-D-37** toute lecture par la page passe par `VF_ETAT.jeton()` et `VF_ETAT.lireJson()` (A13) ; « Voir sur la carte »
  passe par l'onglet Code tel que la coquille l'expose (A2, routage 80) ; la 74 ne pose aucune route serveur.

### Claude's Discretion

Géométrie de la frise ; forme exacte de l'encart ; seuil de repli (confirmé à 12 par l'UI-SPEC) ; mécanisme de mise en
évidence sur la carte Code (P74-D-12) ; pagination du fil au-delà du plafond.

### Deferred Ideas (OUT OF SCOPE)

Coût en devise, limites de 5 h et 7 jours, plafond de coût (AUDC-I35) ; fenêtre au-delà de 24 h et coût complet hors
fenêtre (Phases 52, 77) ; empreinte en direct sur la carte Code et radar (Phase 75) ; actions sur une session (Phase 81) ;
horodatage des transitions de DAG (`dag.sh`).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (abrégée, texte complet : `REQUIREMENTS.md:1690-1701`) | Research Support |
|----|-------------|------------------|
| TEMP-01 | Frise derrière la bascule, voies, fenêtres, session vivante au repos, troncature dite | § Points d'intégration UI ; Pattern 1 (modèle pur) ; Pattern 3 (montage) ; Pitfalls 1, 6 |
| TEMP-02 | Segments et événements sans couleur, bandeau Dépôt, clic → tiroir Git, trois teintes | § Données (Git) ; Pattern 5 (commit → branche) ; Pitfall 4 (tiroir Git sans API d'ouverture sur un sha) |
| TEMP-03 | Horloge et Événements | Pattern 1 (projection temps → x par tronçons) ; Pitfall 7 |
| TEMP-04 | Repli, courbe, direct par `frise` | Pattern 1 ; § Données (C4) ; Pitfall 2 (performance) |
| TEMP-05 | Curseur, encart, nœuds dérivés, fichiers à t, « Voir sur la carte » | § Jointures ; Pattern 6 (`showBoard`) ; Pitfall 9 (fil sans erreurs ni messages humains) |
| TEMP-06 | Fiche plein cadre, ouverture frise et régie, Échap, focus | § Points d'intégration UI ; Pitfall 5 (clavier du viewer) ; dépend de la 73 |
| TEMP-07 | Faits de la fiche, « inconnu », pourcentage seulement documenté | § Jointures ; § Données (C3) |
| TEMP-08 | Lecteur : fil, filtres, direct, coupe, markdown en DOM, « échec » | Pattern 4 (markdown fermé) ; Pitfall 9 ; Open Question 1 |
| TEMP-09 | Coût par agent, mission, phase, étage, « hors mission », fenêtre écrite | Pattern 1 (agrégats) ; § Jointures (étage) ; Assumption A3 |
| TEMP-10 | Un seul calcul de jetons, champs déclarés au contrat, témoin multi-lignes | Pattern 2 (`CHAMPS_LUS` ⊂ contrat) ; Validation |
| TEMP-11 | Bornes : GET, jeton, clés interdites, export, réseau, XSS étendue | § Security Domain ; § Tests (volet XSS) |
| TEMP-12 | Clavier, alternative textuelle, focus, mouvement, thèmes, grille, français ; retraits ; suites vertes ; bump | § Retraits ; Pitfalls 3, 8, 10 ; § Fichiers partagés |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Commits en français ; un commit qui invoque une décision humaine nomme le canal et la date ; identifiants de décision
  préfixés (`P74-D-xx`) [CITED: CLAUDE.md du dépôt § Conventions transverses].
- Jamais de fix sans validation humaine (ADR-031). Release = bump cohérent racine + tag annoté ; une PR de planning seul
  se merge sans release (ADR-073). La 74 ne fait pas de release : elle porte un bump de module à régler à la jointure.
- Tout commit qui touche un gate, sa suite, `.github/workflows/ci.yml` ou un hook porte un trailer `Gate-Touche:` ; les
  fixtures surveillées sont seulement `plugin/conductor/scripts/tests/fixtures/**` et `scripts/tests/fixtures/**`
  [VERIFIED: scripts/check-gate-touche.sh:31, :225-226, cité : `plugin/conductor/scripts/tests/fixtures/*) CLASS="fixtures" ;;` et
  `scripts/tests/fixtures/*) CLASS="fixtures" ;;`]. Les suites du cockpit et leurs fixtures ne sont pas dans ces classes ;
  la 74 n'a aucune raison de toucher `ci.yml` (découverte automatique, voir § Tests).
- Toute interface suit `DESIGN.md`, direction « Graphite ».
- Mémoire du dépôt : `git -C` et chemins absolus dans un worktree, jamais `cd` ; `rtk` fausse les comptes (mesurer en
  `rtk proxy`) ; une preuve doit pouvoir rougir (témoin rouge établi avant le vert) ; ne jamais supprimer un artefact
  pour verdir (le mettre en conformité).

## Summary

La 74 est une phase **de page** : tout son rendu tient dans de nouveaux modules `plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-*.js`.
Un module posé dans ce dossier est inclus automatiquement, dans l'ordre lexical, dans les trois pages (Code, Projet,
Équipe), en `<script>` en ligne, et sa somme SHA-256 entre d'elle-même dans la CSP au moment de servir la page : aucune
liste à tenir, aucune empreinte à écrire. Le moteur offre déjà les deux points d'appui dont la 74 a besoin sans le
patcher : `Floorplan.showBoard({ title, items })` (mise en évidence d'un ensemble de fichiers sur l'onglet Code) et
`Floorplan.addHeaderButton` / `addPanelSection` / `on('ready')`.

Le modèle de données se lit dans trois sources : la route de frise de la 79 (`cockpit-frise@1`, pas encore livrée),
`cockpit-who@2` (noms, titres, rôle, tâche) et `cockpit-signal@1` via la route d'état (missions, `phaseKey`, phases). Les
jointures sont toutes par identifiant exact : voie ↔ travailleur par `id`, `rattachement.dag` ↔ `signal.missions[].fichier`,
`missions[].phaseKey` ↔ `phases[].key`. Les commits viennent de `cockpit-git@1`, en secondes, par la marche bornée à 500 + 500
commits, sans branche par commit : la 74 doit attribuer chaque commit à une branche elle-même (marche par premier
parent depuis les étiquettes de branche) et mesurer la couverture de la fenêtre.

Trois écarts entre l'UI-SPEC et les données existent et doivent être tranchés au plan : (1) le fil réduit
(`cockpit-transcript@2`) ne contient ni les messages de l'humain, ni les compactions, ni l'issue d'un appel d'outil
(il ne lit que les lignes `assistant`) ; (2) un segment de C3 ne porte pas sa provenance (officiel ou déduit), donc le
suffixe « · déduit » par segment n'a pas de source ; (3) le tiroir Git n'expose aucune fonction « ouvrir sur ce commit ».

**Primary recommendation:** six plans, dont deux (modèle pur et rendu du fil) démarrent tout de suite sans attendre la 79,
car ils ne consomment que des formes figées ; les quatre autres s'exécutent après les vagues de la 79 qui livrent C3, C4 et
A13, et après la 73 pour le point de montage et la fonction d'ouverture de la fiche.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Segments, événements, jetons, durées par voie | API / Backend (Phase 79, index + route de frise) | — | P74-D-22, D-25 : la 74 ne lit aucun transcript, ne recompte rien |
| Agrégats de coût (agent, mission, phase, étage) | Browser (module pur `74-vf-frise-modele.js`) | — | sommes de champs de C3 sur la fenêtre ; aucune persistance |
| Rendu de la frise, curseur, encart, bascule | Browser (`74-vf-frise.js`) | — | SVG `aria-hidden` + alternative textuelle |
| Fichiers écrits autour de t | API (`/api/vf/transcript`, existant) | Browser (cache jusqu'au `frise` suivant) | P74-D-14, D-35 |
| Fiche et lecteur | Browser (`74-vf-fiche.js`, `74-vf-fiche-texte.js`) | API (transcript à la demande) | P74-D-03, D-17 |
| Commits du bandeau Dépôt | API (`/api/vf/git`, existant) | Browser (attribution à une branche, couverture) | P74-D-07, D-33 |
| Ouverture du tiroir Git sur un commit | Browser (tiroir Git, Phase 78) | — | API publique absente : voir Pitfall 4 |
| Mise en évidence sur la carte Code | Browser (moteur, `showBoard`) | coquille 79 / routage 80 | P74-D-37 |
| Contrat de forme (champs déclarés) | API (`vf-cockpit-interface.json`, étendu par la 79) | tests 74 | P74-D-25 |

## Standard Stack

Aucune bibliothèque nouvelle. La phase se bâtit sur ce qui est dans le module.

### Core
| Élément | Version | Rôle | Pourquoi |
|---------|---------|------|----------|
| Modules `ui/*.js` du moteur vendorisé | module `cockpit` v1.4.0 [VERIFIED: plugin/cockpit/VERSION, cité : `v1.4.0`] | rendu de la page, sans framework | seule voie admise sans toucher le moteur (P74-D-31) |
| API `window.Floorplan` (servie `window.VibeFlow`) | `version: 1` [VERIFIED: viewer.html:2519-2520] | `showBoard`, `addHeaderButton`, `on`, `h`, `exists` | surface stable des extensions |
| SVG en ligne par `createElementNS` | navigateur | pistes de la frise | UI-SPEC § 2 ; CSP inchangée (aucun script, aucun style externe) |
| `Intl.DateTimeFormat('fr-FR', …)` | navigateur | heures et dates en français | précédent : `77-vf-git-vue-detail.js:47-51` |
| Node | v26.5.0 sur le poste [VERIFIED: `node --version`] | suites hors navigateur (`node:vm`) | précédent : `vm-rendu.mjs` de `test-cockpit-transcript.sh:166-199` |
| Chrome headless + `chrome-session.mjs` | présent sur le poste [VERIFIED: `ls "/Applications/Google Chrome.app/…"`] | suites navigateur | socle commun des suites du cockpit (`chrome-session.mjs:1-8`) |

**Installation :** aucune.

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase : audit sans objet.
**Packages removed due to [SLOP] verdict:** none. **Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
 transcripts du lab ──► [79] index incrémental (C1, privé) ──► GET /api/vf/frise (C3) ─┐
 claude agents --json ─► [79] collecte ──► GET /api/vf/state (C2: signal@1 + who@2) ───┤
                                    └──► flux /api/vf/events : `frise`/`etat` {seq,at,sig} (C4)
                                                         │ (signature seule, aucune donnée)
                                                         ▼
                              window.VF_ETAT (79) : abonner('frise'|'etat'|'who'|'git')
                                                         │  lireJson(chemin) + jeton()  (A13)
                                                         ▼
 ┌─────────────── page Équipe ─────────────────────────────────────────────────────────┐
 │ 74-vf-frise-modele.js (pur) : schéma ? → voies ordonnées, repli, projection temps→x,   │
 │   agrégats coût, état à t, nœuds portés, commits→branche, couverture                   │
 │        │                                                                               │
 │        ▼                                                                               │
 │ 74-vf-frise.js : bascule Régie·Frise ─► frise SVG + alternative .sr ─► curseur ─► encart│
 │        │  clic colonne / Entrée              │ « Voir sur la carte »    │ clic commit    │
 │        ▼                                     ▼                          ▼              │
 │ 74-vf-fiche.js (faits | fil) ◄── GET /api/vf/transcript?id= (fil@2, à la demande)     │
 │        └─ 74-vf-fiche-texte.js : fil + événements de la voie, markdown fermé en DOM    │
 └──────────────────────────────────────┬──────────────────────────┬─────────────────────┘
                                        ▼                          ▼
              onglet Code : Floorplan.showBoard({items:['f:<chemin>']})   tiroir Git (78) : détail du commit
              via VF_COQUILLE.chargerOnglet('code') (A2, routage 80)
```

### Recommended Project Structure
```
plugin/cockpit/skills/cockpit-moteur/assets/ui/
├── 74-vf-fiche-texte.js   # pur : modèle du fil (fil@2 + événements de C3), filtres, markdown fermé → nœuds DOM
├── 74-vf-fiche.js         # fiche plein cadre : faits, fil, direct, Échap/Retour, focus ; window.__vfFiche.ouvrir(id, origine)
├── 74-vf-frise-modele.js  # pur : normalisation de cockpit-frise@1, agrégats, projection, état à t, commits → branche
└── 74-vf-frise.js         # bascule, frise SVG, curseur, encart, Dépôt, section Coût, direct
plugin/cockpit/scripts/tests/
├── test-cockpit-frise-modele.sh   # node:vm, fixtures construites dans mktemp
├── test-cockpit-fiche-texte.sh    # node:vm, document factice avec createElementNS
├── test-cockpit-frise.sh          # Chrome : frise, curseur, encart, coût, bascule (route factice par VF_PRE)
├── test-cockpit-fiche.sh          # Chrome : fiche, focus, fil, filtres, direct
├── test-cockpit-frise-xss.sh      # volet frise/fiche de la chaîne XSS (précédent : test-cockpit-terminal-xss.sh)
└── chrome-frise.mjs               # actions navigateur partagées par les deux suites Chrome de la 74
```
Ordre de chargement (`.sort()` lexical, `build.mjs:448`) : `73-vf-tiroir-travail.js` < `74-vf-fiche-texte.js` <
`74-vf-fiche.js` < `74-vf-frise-modele.js` < `74-vf-frise.js` < `75-vf-modele.js`. Chaque module lit ses voisins **à
l'usage**, jamais au chargement (précédent : `70-vf-live.js:60` lit `window.__vfEquipeRendu` à l'appel).

### Pattern 1 : modèle pur, testable hors navigateur
**Quoi :** tout ce qui se calcule sans DOM vit dans `74-vf-frise-modele.js`, posé sur `window.__vfFriseModele`, sans
dépendance au viewer au chargement, comme `71-vf-equipe-rendu.js` (en-tête `:1-3`, export `:230`).
**Contenu :** `lire(frise)` (vérifie `schema === 'vibeflow/cockpit-frise@1'` avant tout champ, C0) ; `arbreDesVoies(voies, who)`
(ordre : heure du premier segment de l'arbre, enfants par `dispatchA`) ; `replier(arbre, 12)` ; `projection(depuis, jusqua,
largeur, lecture, segments)` (Horloge linéaire ; Événements : tronçons séparés par les silences > 120 s, repère de largeur
fixe) ; `coalescer(segments, msParPixel)` ; `etatA(voie, t)` ; `noeudsPortes(voies, t, missions)` ; `agreger(voies, par,
{ missions, phases })` ; `commitsParBranche(rangees)` et `couverture(rangees, depuis)` ; formats `jetons`, `duree`, `heure`.
**Constante exportée :** `CHAMPS_LUS` (liste des champs de C3 lus par la 74), comparée au contrat par la suite (Pattern 2).

### Pattern 2 : champs lus ⊂ contrat de forme
Le contrat est un JSON : `schemas` → par schéma, `requis` / `optionnels` [VERIFIED: vf-cockpit-interface.json:49-52, cité :
`"vibeflow/cockpit-transcript@2": { "requis": { "schema": "string", "id": "string" }, "optionnels": ["mandat", "fil", "tronque", "erreur"] }`].
La 79 y déclare `vibeflow/cockpit-frise@1` (C6). La suite du modèle charge le contrat et vérifie
`CHAMPS_LUS ⊆ champs déclarés` : témoin rouge si un champ lu n'est pas déclaré (TEMP-10, P74-D-25). La forme exacte du bloc
`cockpit-frise@1` dans le contrat n'existe pas encore : **à revalider sur la 79**.

### Pattern 3 : montage dans l'onglet Équipe sans toucher le moteur
- Garde de page : `SC.graph.meta.vfTab !== 'equipe'` → rien (précédent `72-vf-equipe.js:8-9`). Marqueur de corps
  `body.vf-tab-equipe` déjà posé par `00-vibeflow.js:11`.
- Aujourd'hui, la « zone de contenu » de l'onglet Équipe est le canevas `<main id="stage">` (`viewer.html:620-622`) ;
  la Phase 73 le remplace par la régie. La frise et la fiche se montent **dans le conteneur que la régie expose**, pas
  sur `#stage` : point d'intégration **à revalider sur la 73** (nom du conteneur, fonction d'ouverture de la fiche, place
  de la bascule, table de glyphes).
- La fiche n'utilise jamais `#panel` (UI-SPEC § 9 « `#panel` n'est pas utilisé ») : elle remplace la vue dans la zone de
  contenu, et un tiroir latéral continue de ne rien pousser (Q12).
- Fonction d'ouverture unique, posée par `74-vf-fiche.js` et appelée par la frise et la régie :
  `window.__vfFiche.ouvrir(idAgent, elementOrigine)`.

### Pattern 4 : markdown fermé construit en nœuds DOM
Sous-ensemble : paragraphes, listes, code en ligne, blocs de code, emphase ; un lien s'écrit « libellé (adresse) » en
texte. Construction par `createElement` + `textContent` uniquement, jamais `innerHTML` (P74-D-18). Précédent de forme :
`transcript()` de `71-vf-equipe-rendu.js:152-170`, qui n'emploie que `createElement`/`textContent` et dont la suite compte
les affectations `innerHTML` (`test-cockpit-transcript.sh:421-423`). **Ne pas réutiliser `Floorplan.md`** : c'est le
rendu markdown du moteur, qui produit du HTML (la chaîne XSS en éprouve l'italique, `test-cockpit-chaine-xss.sh:216-222`).

### Pattern 5 : commits → branche et couverture
`cockpit-git@1` ne donne pas la branche d'un commit : seules les rangées d'une tête portent `refs` (`vf-cockpit-git.mjs:179-182`).
Attribution recommandée : pour chaque étiquette `locale` (puis `distante`), descendre par premier parent (`p[0]`) tant
que le commit n'est pas déjà attribué ; un commit atteint par aucune marche va à « autres ». C'est la même règle que la
teinte du serveur (`couleur.set(c.p[0], t)`, `vf-cockpit-git.mjs:177-178`). Couverture (P74-D-33) : `incomplet` si
`bornes.tronque` est vrai ET le plus ancien `at × 1000` lu est postérieur à `depuis` ; l'heure dite est ce plus ancien
instant.

### Pattern 6 : « Voir sur la carte »
Le moteur expose `showBoard({ title, items })` : filtre les identifiants inconnus (`Q.exists`), plafonne à 24 cartes et
ouvre un tableau de réponse (`q:answer`) [VERIFIED: viewer.html:2501-2509]. Un fichier de l'onglet Code a l'identifiant
`f:<chemin relatif au lab>` (`00-vibeflow.js:285`, cité : `const id = /^[nf]:/.test(r) ? r : 'f:' + r;`). Les cibles du fil
réduit sont déjà relatives au lab (`vf-cockpit-transcript.mjs:27-33`), ou « un fichier hors du lab » (à exclure).
Recommandé : `await VF_COQUILLE.chargerOnglet('code')` (A2) puis `VibeFlow.showBoard({ title: 'Fichiers écrits vers 14 h 32',
items: chemins.map((p) => 'f:' + p) })`. Repli tant que la coquille et le routage de la 80 n'existent pas : passage par
`sessionStorage` (clé neuve, consommée et effacée à la lecture) puis navigation vers `index.html` ; un module côté Code lit
la clé à `ready`. **À revalider sur la 79 (A2) et la 80.** Aucun patch du moteur dans les deux cas.

### Anti-Patterns à éviter
- **Lire `dureeS`** dans la frise ou la fiche : compte les veilles (P74-D-26) ; lire `durees.travailS` de C3.
- **Recompter des jetons** depuis `/api/vf/transcript` : interdit (P74-D-22), et le fil réduit n'a pas d'`usage`.
- **Écrire dans `#panel`** ou ouvrir la fiche par `showPanel` : c'est un tiroir latéral (Q12) ; la fiche est une vue.
- **`innerHTML` d'une chaîne de données** (nom, nœud, titre, message, cible) ; `h()` du moteur reste admis pour un
  gabarit, mais l'UI-SPEC impose `textContent`/`createElementNS` pour toute donnée.
- **Une couleur par nœud, par branche ou par agent** : trois teintes d'état seulement (P74-D-01). Le serveur Git fournit
  `teinte` par rangée (`vf-cockpit-git.mjs:177`) : la frise ne s'en sert pas.
- **Lire le jeton par `window.FLOORPLAN_SERVER.token`** dans un module neuf : seule voie admise après la 79,
  `VF_ETAT.jeton()` / `VF_ETAT.lireJson()` (A13, P74-D-37).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser | Pourquoi |
|---------|-------------|-------------|-----|
| Mettre en évidence des fichiers sur l'onglet Code | un surligneur dans la carte | `Floorplan.showBoard` (`viewer.html:2501`) | filtre, plafond et rendu déjà faits, aucun patch du moteur |
| Comptage des jetons | une somme sur le transcript | `jetons` de la voie (C3) | dédoublonnage par `message.id` fait par la 79 (C1) |
| Lecture authentifiée | `fetch` + en-tête de jeton à la main | `VF_ETAT.lireJson` (A13) | une seule voie, en-tête unique |
| Garde de l'émission | un filtre de clés côté page | `porteInterdit` du serveur (`vf-cockpit-server.mjs:33-35`) | fermé par défaut côté serveur |
| Formats de date français | concaténations | `Intl.DateTimeFormat('fr-FR', …)` + `formatToParts` | précédent `77-vf-git-vue-detail.js:47-51` |
| Lancement d'un serveur de test | un `demarrer` de plus | `socle-serveur.sh` (A6, plan 79-02) | **à revalider sur la 79** ; sinon le motif de `test-cockpit-transcript.sh` |
| Mise en page de l'arbre des voies | une bibliothèque de graphe | tri stable maison (quelques dizaines de voies) | ELK est réservé au canevas |

**Key insight :** le moteur et le socle portent déjà les parties dures (mise en évidence, garde d'émission, dédoublonnage,
CSP par empreintes) ; la 74 est une couche de lecture et de rendu.

## Points d'intégration UI (question 1)

| Fait | Preuve |
|---|---|
| Les modules `ui/*.js` sont lus par `fs.readdirSync(uiDir).filter((n) => n.endsWith('.js')).sort()` et inlinés en `<script>/* ui/<nom> */` | `skills/cockpit-moteur/scripts/build.mjs:447-448` |
| Ils sont posés à la place de `<!--__UI_EXTENSIONS__-->`, après le script du viewer | `build.mjs:446`, `viewer.html:2577` |
| La CSP est calculée au moment de servir : une empreinte `sha256` par `<script>` en ligne ; `style-src 'unsafe-inline'`, `connect-src 'self'` | `assets/serve.mjs:513-514` |
| Les pages Code et Projet sont épissées par `vf-cockpit-build.mjs` à partir du même `index.html` | `vf-cockpit-build.mjs:104-108` |
| La page Équipe est construite **en mémoire** depuis ce gabarit (jamais écrite), servie sur `/equipe.html` | `vf-cockpit-server.mjs:141-155`, `serve.mjs:593` |
| Le `vfTab` de la page Équipe vaut `'equipe'` | `vf-cockpit-equipe-carte.mjs:83` |
| Chaque module se garde lui-même par `vfTab` | `72-vf-equipe.js:9`, `00-vibeflow.js:10` |
| Les onglets sont trois liens `index.html`, `project.html`, `equipe.html` dans `nav.vf-tabs` | `00-vibeflow.js:138-144` |
| Les ui se chargent avant le premier rendu (`ready` attend `DOMContentLoaded`) | `viewer.html:2572-2574` |
| Les scripts d'extension doivent ouvrir par `// VibeFlow (` pour être exclus de l'inventaire des chaînes anglaises | `vf-cockpit-fr-inventaire.mjs:124`, cité : `const MARQUEURS_FR = /^\s*(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ (?:vibeflow:fr|vibeflow:allow-large-file|VibeFlow \()…/` |

**Numéros libres** (relevé de `assets/ui/`) : 04, 07-09, 11-19, 21-24, 26-29, 31-38, 41-59, 61-69, **74**, 81-99.
Recommandé : préfixe `74-vf-` (lisible, se charge après 71, 72, 73 et avant la traduction `80-vf-fr.js`). Les Phases 73,
75, 77 et 80 choisissent aussi des numéros : **réserver `74-vf-fiche*` et `74-vf-frise*` à la jointure**.

**Où brancher la bascule et la vue plein cadre sans modifier le moteur :** dans le conteneur de la régie (73). À défaut,
la bascule s'ajoute à l'en-tête de la vue par un module ui (jamais par `viewer.html`), et la vue se monte dans un élément
neuf placé sous l'en-tête (`top: calc(var(--hh, 64px) + …)`, même forme que `#panel`, `viewer.html:343`). Le canevas reste
la propriété de la 73.

## Données (question 2)

| Fait | Preuve |
|---|---|
| Lecture authentifiée aujourd'hui : `fetch('/api/vf/transcript?id=' + encodeURIComponent(id), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' })` | `72-vf-equipe.js:187` |
| L'en-tête `x-floorplan-token` devient `x-vf-cockpit-token` à l'assemblage (règle `floorplan` → `vf-cockpit`) ; C0 et A13 parlent de la forme servie | `vf-cockpit-rename.mjs:18`, cité : `{ motif: /floorplan/g, remplacement: 'vf-cockpit', raison: 'clés de stockage, en-tête de jeton, événements, clés de thème, chaînes' }` |
| Le serveur accepte le jeton en en-tête, `?token=` seulement sur les flux | `serve.mjs:533-534` |
| `/api/vf/transcript` : `id` validé par `ID_RE`, sinon 400 `{ erreur: 'id-invalide' }`, jamais journalisé | `vf-cockpit-server.mjs:104-110` |
| Fil réduit : `{ mandat, fil, tronque }`, fil = messages de l'agent et outils (`{ t, genre: 'outil', outil, verbe, cible, n? }`), plafonds `MAX_MESSAGES = 50`, `MAX_OUTILS = 200` | `vf-cockpit-transcript.mjs:3`, `:16` |
| Le réducteur **ne lit que les lignes `assistant`** : ni message de l'humain, ni `tool_result` (donc aucune issue d'outil), ni compaction | `vf-cockpit-transcript.mjs:83-84`, `:103-110` |
| L'heure d'une ligne est un ISO 8601 (`toISOString`) | `vf-cockpit-transcript.mjs:89` |
| Les cibles sont relatives au lab ou « un fichier hors du lab » | `vf-cockpit-transcript.mjs:15`, `:27-33` |
| `cockpit-git@1` : `rangees[].at` = `%at`, heure d'auteur en **secondes** Unix | `vf-cockpit-git-graphe.mjs:5`, cité : `export const FORMAT_JOURNAL = '%H%x00%P%x00%at%x00%an%x00%s';` et `:21` `commits.push({ h, p, at: Number(at), an, s });` |
| Marche bornée : `BORNES = { base: 500, nonMergees: 500, … }` ; `bornes.tronque` dit si une borne est atteinte | `vf-cockpit-git.mjs:19`, `:197` |
| Ouverture du tiroir Git : `window.VFGitTiroir = Object.freeze({ ouvrir, fermer, ouvert, recharger, donnees })` ; `recharger()` rend une promesse | `77-vf-git-tiroir.js:199`, `:147-159` |
| Sélection d'un commit : `VFGitDetail.selectionner(sha)` sélectionne sans ouvrir le détail ; l'ouverture (`ouvrirDetail`) est interne | `77-vf-git-vue-detail.js:54-61`, `:107-120`, `:216` |
| Le détail d'un commit refuse un sha hors `/^[0-9a-f]{40}$/` | `77-vf-git-vue-detail.js:8`, `:89` |
| Mise en évidence d'un ensemble de fichiers sur Code : `showBoard` (public) ; `highlightFlow` est interne au viewer (non exposé) | `viewer.html:2501-2509`, `:2033`, `:2519-2565` |

**Route de frise (C3)** : non livrée. Ses formes sont figées (79-CONTEXT C3 ; amendements A8, A9, A14) : instants des
segments et événements en ms ; `segments: [debutMs, finMs, genre][]` (≤ 500) avec `genre ∈ travail, attend-agents,
attend-humain, repos, silence` ; `evenements: [tMs, genre][]` (≤ 500) avec `genre ∈ compaction, erreur, humain, rapport,
dispatch` ; `cibles.ecritures` / `lectures` ≤ 200, sans heure par écriture ; `source.etat ∈ ok, en-construction,
partielle, forme-inconnue, indisponible`. [CITED: 79-CONTEXT-3119d82a.md § C3 ; 79-CONTEXT-2ae6607a.md § Amendement A8-A14]

## Jointures (question 3)

| Jointure | Clé | Preuve |
|---|---|---|
| Voie ↔ travailleur `who@2` | `id` égal (C3 : `sessionId` pour une session, identifiant d'agent pour un sous-agent ; `who@2` : même identifiant de carte `se-`/`ag-` + `id`) | `72-vf-equipe.js:35` ; C3 |
| Nom d'une voie | session : `titre` (`custom-title`) sinon « Session principale », désambiguïsé par arbre puis id court : `nomDeSession` ; sous-agent : `task`, sinon rôle + id court | `71-vf-equipe-rendu.js:69-76`, `:93`, `:230` |
| Champs de `who@2` utilisables | `["role", "task", "titre", "parent", "depth", "background", "branch", "treeBy", "cwd", "ageS", "lastAt", "stale", "orphan", "children", "dag", "etat", "dureeS", "finAt", "action", "rattachement", "enCours"]` | `vf-cockpit-interface.json:30` |
| Une voie hors de `who@2` (terminée depuis plus que la fenêtre de `who`, ou disparue) | C3 ne porte ni titre ni tâche (C1 : « jamais un titre ») : nom = `role` + 8 premiers caractères de `id` | C1, C3 ; `71-vf-equipe-rendu.js:93` (même repli) |
| Voie → mission | `rattachement.dag` === `signal.missions[].fichier` (A8) | `vf-cockpit-signal.mjs:71-72`, cité : `fichier: nettoie(d.file, 200), phaseKey: d.phaseKey` |
| Mission → phase | `missions[].phaseKey` === `phases[].key` ; `phaseKey` vaut `null` si la mission n'est rattachée à aucune phase | `vf-cockpit-signal.mjs:69`, `:72` ; `vf-cockpit-planning.mjs:155` |
| Liens de la fiche | nœud : `project.html#r=f:<dag>#<noeud>` ; mission : carte `n:dag-<nom>` ; phase : carte `n:ph-<n>` ou `n:ph-<n>@<ws>` | `71-vf-equipe-rendu.js:10-12` ; `vf-cockpit-project.mjs:76`, `:150` |
| Nœuds « aucun agent » de l'encart | `signal.missions[].noeuds`, présent seulement pour certains états de mission | `vf-cockpit-signal.mjs:73` |
| Rattachement de `who@2` (forme actuelle) | `{ etat, source, raison, dag, noeud }` ; états `["rattache", "non-rattache"]`, raisons `["sans-citation", "inconnu", "ambigu"]` | `vf-cockpit-who.mjs:168`, `vf-cockpit-interface.json:33-36` |
| Rôle → étage | tête = `kind: 'session'` ; manager / worker : voir Assumption A3 | P74-D-21 |

## Retraits (question 6)

| Retrait | Où il vit (lignes exactes) | Suites qui l'assertent |
|---|---|---|
| Bouton « Lire le transcript » du panneau | section `Activité` du panneau d'un agent : `72-vf-equipe.js:163-172` (bouton `:171`) | `test-cockpit-equipe.sh` EK1.0, EK1, EK1.1 (`:897-902`), EK1.2, EK1.3 (`:970-972`, ancre `EKANC1` sur `72-vf-equipe.js:176`), EK8 « focus-puis-who » (`:920-922`), EK8.2 ; `chrome-equipe-clavier.mjs` actions `focus-transcript`, `focus-puis-who` (en-tête `:4`, `:12`, corps `:35-84`, `:133`) |
| Boîte de transcript de 320 px | conteneur `zoneDe` `72-vf-equipe.js:55-61` ; mémoire et observateur `:113-132` ; garde d'Entrée `:173-177` ; lecture `:178-192` ; rendu `transcript()` `71-vf-equipe-rendu.js:151-170` et son export `:230` ; CSS `.vf-transcript` et bouton `70-vf-live.js:32-33`, `:44-47` ; focus des boutons `70-vf-live.js:153-156` | `test-cockpit-transcript.sh` T26.1 à T26.5 (`:409-429`, rendu vm de `transcript()`), T26.7 (`:441-451`, Chrome), T27.C1 et T27.C2 (`:515-540`, `:565-567`) ; `test-cockpit-equipe.sh` EK2.1, EK2.2 (clé `vf-equipe-ouvert`), EK3.1, EK3.2 |
| Pied du tiroir « Transcript : dans l'onglet Équipe » | `70-vf-live.js:113` | à relever au plan (texte) |
| Durée qui compte les veilles (`dureeS`) | calcul serveur `vf-cockpit-equipe.mjs:109` (reste émis, P74-D-26) ; affichage page : `quand()` `71-vf-equipe-rendu.js:22-26` (panneau `Activité` via `pied`, pied de carte via `piedCarte`), `temps()` `:82-86` et tri des enfants `:89` (tiroir « Au travail ») | `test-cockpit-equipe.sh`, `test-cockpit-equipe-etats.sh`, `test-cockpit-transcript.sh` (sc-a `:485-497`), `chrome-equipe-clavier.mjs` (fixtures `dureeS`) |
| Carte « Terminés depuis moins de 24 h » | serveur `vf-cockpit-equipe-carte.mjs:42-52`, `:71-76` ; vue d'ensemble `72-vf-equipe.js:24-25` ; tiroir `71-vf-equipe-rendu.js:137-142` | `test-cockpit-equipe.sh`, `test-cockpit-lancer-suivi.sh` |

Lecture : le **panneau** d'un agent (où vivent le bouton et la durée « au travail depuis ») disparaît de fait avec le
canevas que la 73 retire ; la 74 retire alors le reste (code mort de `72`, `transcript()` de `71`) et réécrit les témoins
EK et T26/T27 contre la fiche. Le tiroir « Au travail » reste inchangé (UI-SPEC § 8) : sa durée `temps()` n'est **pas**
retirée par la 74 (Open Question 3). `70-vf-live.js` est modifié par la 79 (A7) : les sélecteurs morts `.vf-transcript`
et `[data-vf-transcript]` y restent tant que la 79 n'a pas mergé ; leur retrait se fait après elle, ou par elle.

## Fichiers partagés avec la vague (question 5)

| Fichier | Ce que la 74 doit y toucher | Comment l'éviter ou l'ordonner |
|---|---|---|
| `plugin/cockpit/CHANGELOG.md` | une entrée sous `## Non publié` (en-tête `CHANGELOG.md:3`) | inévitable ; un seul commit en fin de phase, bloc « Phase 74 » propre, résolution de fusion par concaténation |
| `VERSION`, `module.json` (`"version": "v1.4.0"`), en-tête `**Version**` du README du module (`README.md:6`, gaté par `scripts/check-version-sync.sh:118-129`) | bump minor du module | **ne pas bumper dans la 74** : un seul bump pour la vague, à la jointure d'intégration (sinon six phases montent la même version) |
| `plugin/cockpit/README.md` § « Équipe au travail » (`:167-173`, décrit « Lire le transcript » et T24-T26) | réécrire le paragraphe (fiche, frise, coût) | un paragraphe à soi ; la 73 réécrit sans doute le même § : ordonner après la 73 |
| Compteur de suites `213 suites` (`README.md:65`, `README.fr.md:67`), gaté par `check-version-sync.sh:131-139` (`find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh'`) | + 5 suites (213 → 218 si rien d'autre ne bouge) | inévitable ; le recompter au dernier commit de la branche, jamais en dur au plan |
| Liste des suites (`ci.yml`) | rien : découverte par motif (`ci.yml:497`) | ne pas toucher `ci.yml` (classe surveillée par G-2) |
| `scripts/ci-shard-suites.sh` | rien sauf suite > 600 s | garder chaque suite courte (une suite navigateur, un Chrome) |
| `vf-cockpit-interface.json` | rien : la 79 déclare `cockpit-frise@1` (C6) | la 74 lit le contrat dans ses tests, ne l'écrit pas |
| `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js` | rien si les textes de la 74 sont écrits en français | modifiés par la 79 (A7) ; mais la traduction s'applique aux données de la 74 (Pitfall 3) |
| `71-vf-equipe-rendu.js`, `72-vf-equipe.js` | retraits (ci-dessus) | la 73 les réécrit aussi : retraits **après** la 73, plan à part |
| `70-vf-live.js` | aucun dans la 74 | modifié par la 79 (A7) : laisser les sélecteurs morts, retrait après la 79 |
| `77-vf-git-vue-detail.js` | `VFGitDetail.ouvrir(sha)` public (Pitfall 4) | fichier de la Phase 78, absent de la liste A7 de la 79 ; une ligne d'export ; nommer le partage si la 80 le touche |
| `test-cockpit-equipe.sh`, `test-cockpit-transcript.sh`, `chrome-equipe-clavier.mjs` | réécriture des témoins EK1-EK3, EK8, T26-T27 | la 73 y touche aussi : même plan que les retraits, après la 73 |
| `test-cockpit-chaine-xss.sh` | rien (volet séparé) | précédent : volet terminal dans une suite à part, cité dans l'en-tête `:15` ; la 74 crée `test-cockpit-frise-xss.sh` |

## Common Pitfalls

### Pitfall 1 : instants en trois unités
**What goes wrong :** commit placé 1 000 fois trop tôt, ou fil daté en UTC.
**Why :** C3 en ms, `cockpit-git@1` en secondes (`vf-cockpit-git-graphe.mjs:5`), fil réduit en ISO (`vf-cockpit-transcript.mjs:89`).
**How to avoid :** une seule fonction de normalisation par source dans le modèle ; test avec un commit à 1 s de `depuis`.

### Pitfall 2 : performance du rendu
**What goes wrong :** 24 h, plusieurs dizaines de voies × 500 segments × 500 événements = des dizaines de milliers de
nœuds SVG, redessinés à chaque `frise`, puis parcourus par l'observateur de traduction (`80-vf-fr.js:150-154`, qui
observe tout `document.body`).
**How to avoid :** coalescer les segments plus courts qu'un pixel (même genre, contigus) ; ne dessiner que les voies
visibles (repli à 12, défilement vertical) ; remplacer le contenu du `<svg>` en un seul `replaceChildren` ; limiter la
relecture à un `frise` par seconde ; budget mesuré dans la suite (nombre de nœuds SVG ≤ voies visibles × largeur en px).

### Pitfall 3 : la traduction réécrit les données
**What goes wrong :** un message d'agent, un nom de nœud ou une cible dont le texte entier égale une phrase du
dictionnaire (« Close », « Search »…) est traduit.
**Why :** `80-vf-fr.js` traduit tout nœud de texte hors `SKIP` (`80-vf-fr.js:128`, cité :
`const SKIP = 'script,style,code,pre,textarea,.mono,.rp,.pp,.card .title,.card .desc:not(.empty),#panel .pt,.row .rn,.row:not(.vf-rep) .rd,#results .rn,#results .rd';`), précédent AUDC-H4.
**How to avoid :** poser toute donnée (nom, nœud, message, cible, branche) dans un élément qui correspond déjà à `SKIP`
(`code`, `pre` ou classe `.mono`) sans modifier `80-vf-fr.js` (fichier de la 79) ; témoin : un message « Close » reste
« Close ». La 79 prévoit « la traduction au point d'émission » (H4) : **à revalider sur la 79**.

### Pitfall 4 : pas d'ouverture du tiroir Git sur un commit
**What goes wrong :** le clic sur un commit ouvre le tiroir sans le commit, ou le sha n'est pas parmi les rangées lues.
**Why :** `VFGitTiroir` n'expose que `ouvrir, fermer, ouvert, recharger, donnees` (`77-vf-git-tiroir.js:199`) ;
`VFGitDetail.selectionner` sélectionne sans ouvrir (`77-vf-git-vue-detail.js:216`).
**How to avoid :** ajouter à `77-vf-git-vue-detail.js` une fonction publique `ouvrir(sha)` = `T.ouvrir()` puis, après
`T.recharger()`, `ouvrirDetail(sha)` ; sha absent des rangées : le tiroir s'ouvre et l'annonce le dit. Alternative sans
toucher un fichier de la 78 : `ouvrir()`, attendre `recharger()`, puis `click()` sur `#vf-git-tiroir li[role=option][data-h="<sha>"]`
(fragile, dépend du DOM du tiroir). Recommandé : la fonction publique (une ligne d'export, testée).

### Pitfall 5 : le clavier du viewer passe avant la frise
**What goes wrong :** Entrée sur une voie ouvre la carte sélectionnée du viewer ; Retour arrière remonte d'un niveau ;
`/` ouvre la palette ; Échap remonte le canevas.
**Why :** écouteur global sur `window` (`viewer.html:2447-2465`) : `Backspace` → `up()`, `Enter` → `open(state.selected)`,
`Escape` → `select(null)`/`up()`.
**How to avoid :** arrêter la propagation au niveau du document pour les touches gérées par la frise, le curseur et la
fiche (précédent `72-vf-equipe.js:173-177`, `73-vf-tiroir-travail.js:29-36`) ; respecter les surcouches ouvertes
(`73-vf-tiroir-travail.js:28`).

### Pitfall 6 : fenêtre, fuseau et changement d'heure
**What goes wrong :** graduations décalées d'une heure, « 02:00 » deux fois, minuit mal étiqueté.
**How to avoid :** calculer en ms Unix, aligner les graduations sur l'heure locale par `Date` (`setMinutes(0,0,0)` puis pas
fixe en ms), étiqueter par `Intl.DateTimeFormat('fr-FR', { hour: '2-digit', minute: '2-digit', hourCycle: 'h23' })` ; date
au passage de minuit par `{ day: 'numeric', month: 'short' }`. Test avec `TZ=Europe/Paris` et une fenêtre qui traverse le
dernier dimanche d'octobre.

### Pitfall 7 : la lecture Événements ment sur les durées
**How to avoid :** projection par tronçons dans le modèle, `title` des segments toujours calculé sur les instants vrais ;
témoin : deux silences de durées différentes ont la même largeur (UI-SPEC § 9).

### Pitfall 8 : jetons de rayon et grille hors de la garde
**What goes wrong :** l'UI-SPEC donne des rayons de 9 et 12 px (copiés de `.vf-tabs`, `00-vibeflow.js:41-44`), refusés par la garde.
**Why :** `css-jetons.mjs` n'admet en rayon que `{999px, 8px}` ou `var(--r-…)` et en espacement la grille fermée
(`css-jetons.mjs:9-11`, cité : `const ESPACEMENTS = new Set([2, 4, 6, 8, 12, 16, 20, 24, 32]);` et `const RAYONS = new Set(['999px', '8px']);`).
**How to avoid :** rayons par `var(--r-ctl)` / `var(--r-card)` / `999px` ; passer chaque nouveau fichier ui dans
`node css-jetons.mjs` depuis les suites de la 74. Les jetons nommés par l'UI-SPEC existent tous dans `viewer.html`
(`--sp-2`…`--sp-32`, `--recent`, `--sev-high`, `--hair`, `--hair-2`, `--well`, `--r-card`, `--r-ctl`, `--shadow-card`,
`--inset-*`, `--gap-section`, `--on`, `--on-text`, `--warn-bg`, `--warn-text`, `--ring`, `--raise-2`, `--text-4`,
`--panel-w`, `--ease`) [VERIFIED: grep `-- <jeton>:` dans viewer.html, un ou deux par jeton] ; `--st-active` est posé par
`00-vibeflow.js:40`.

### Pitfall 9 : le fil réduit n'a ni messages de l'humain, ni compactions, ni « échec »
**Why :** le réducteur ne lit que les lignes `assistant` (`vf-cockpit-transcript.mjs:83-84`, `:103-110`).
**How to avoid :** fusionner dans le fil, par l'heure, les `evenements` de la voie (C3 : `humain`, `compaction`,
`erreur`, `rapport`) comme **lignes à part** (« Message de l'humain », « Compaction du contexte », « Échec d'un outil »),
sans les apparier à un appel d'outil (apparier par l'heure serait deviner, P69-D-15). Écart à l'UI-SPEC § 4 (qui pose
« échec » à la fin de la ligne de l'outil) : Open Question 1.

### Pitfall 10 : une suite verte qui ne peut pas rougir
**How to avoid :** chaque assertion a son témoin rouge établi sur le code de la base (module absent, ou mutant d'une copie
de la sortie, jamais du module), comme `test-cockpit-transcript.sh:395-405` (mutant `M-PORTE`) et
`test-cockpit-chaine-xss.sh` (C0 : maillons retirés, la chaîne aboutit).

## Tests (question 4)

| Fait | Preuve |
|---|---|
| Une suite = `plugin/cockpit/scripts/tests/test-*.sh`, `set -uo pipefail`, `assert_eq` / `assert_has`, `PASS`/`FAIL`, exit 0 ou 1 | `test-cockpit-transcript.sh:13-28` |
| Hygiène commune sourcée : `hygiene.sh`, `vf_hyg_init` / `vf_hyg_fin` | `test-cockpit-transcript.sh:21-22` |
| Outils Node écrits par la suite dans `mktemp` (jamais de long `node -e`) | `test-cockpit-transcript.sh:30-31` |
| Harnais pur : `vm-rendu.mjs` (document factice qui journalise balises, textes, affectations `innerHTML`) ; **sans `createElementNS`** : à étendre dans la suite neuve | `test-cockpit-transcript.sh:166-199` |
| Navigateur : `chrome-session.mjs` (une instance, attentes bornées, aides « mesurer une fois posé ») | `chrome-session.mjs:1-24` |
| Route factice : script injecté avant la page par `VF_PRE`, `window.fetch` remplacé pour une route donnée, journal des requêtes | `test-cockpit-git-tiroir.sh:91-118` |
| Flux factice : `EventSource` enveloppé, le scénario émet lui-même les événements aux écouteurs réels | `test-cockpit-transcript.sh:455-476` |
| Découverte des suites par la CI : motif `*/tests/test-*.sh` | `ci.yml:497` ; `check-version-sync.sh:134` |
| Compteur : `README.md:65` et `README.fr.md:67` (« 213 suites ») ; 213 suites réelles mesurées | `rtk proxy find … -path '*/tests/test-*.sh' | wc -l` → `213` |
| Aide commune de lancement du serveur : `socle-serveur.sh` (A6, plan 79-02, pas encore livrée) | 79-CONTEXT-2ae6607a.md A6 |

**Route factice `cockpit-frise@1`** : tant que la 79 n'est pas mergée, la suite injecte par `VF_PRE` une réponse
`cockpit-frise@1` construite dans `mktemp` (jamais une fixture versionnée réelle), interceptée dans `window.fetch` ; si
`VF_ETAT` n'existe pas encore, la suite ne peut pas jouer la page réelle : la suite navigateur de la 74 est **à revalider
sur la 79** (elle dépend de `VF_ETAT.lireJson`, qui passe par `fetch` : l'interception reste valable).

## Code Examples

### Lire une heure française (précédent du module)
```javascript
// Source : plugin/cockpit/skills/cockpit-moteur/assets/ui/77-vf-git-vue-detail.js:47-51
const dateLongue = (iso) => { // « 5 nov. 2026, 14 h 32 »
  const d = new Date(iso); if (isNaN(d)) return '';
  const p = {}; for (const x of new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit', hourCycle: 'h23' }).formatToParts(d)) p[x.type] = x.value;
  return `${p.day} ${p.month} ${p.year}, ${p.hour} h ${p.minute}`;
};
```

### Rendu en texte seulement (précédent du module)
```javascript
// Source : plugin/cockpit/skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js:152-155
const transcript = (d, doc) => {
  const f = doc.createDocumentFragment();
  const el = (tag, texte) => { const e = doc.createElement(tag); if (texte != null) e.textContent = String(texte); return e; };
```

### Mise en évidence sur l'onglet Code (API publique du moteur)
```javascript
// Source : plugin/cockpit/skills/cockpit-moteur/assets/viewer.html:2501-2508 (showBoard), :2529 (exposition)
// Forme d'appel recommandée (identifiants de fichier : 'f:' + chemin relatif au lab, 00-vibeflow.js:285)
window.VibeFlow.showBoard({ title: 'Fichiers écrits vers 14 h 32', items: chemins.map((p) => 'f:' + p) });
```

## State of the Art

| Ancienne approche | Approche de la 74 | Impact |
|---|---|---|
| Transcript dans une boîte de 320 px du panneau (`70-vf-live.js:44`) | Fiche plein cadre, fil daté + faits | retraits et réécriture de témoins EK, T26, T27 |
| Durée « au travail depuis » = `dureeS` (veilles comprises) | `durees.travailS` (somme des segments) | `dureeS` reste émis pour ses autres lecteurs |
| Lecture par `window.FLOORPLAN_SERVER.token` | `VF_ETAT.jeton()` / `lireJson()` (A13) | modules neufs seulement |
| Carte « Terminés depuis moins de 24 h » | frise sur 24 h | retrait partagé avec la 73 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | La 73 expose un conteneur de vue et appelle `window.__vfFiche.ouvrir(id, origine)` depuis ses lignes | Pattern 3 | montage à refaire ; plans 74-03/04 bloqués jusqu'à la jointure |
| A2 | Le bloc `cockpit-frise@1` du contrat déclare chaque champ de la voie de C3 sous une forme lisible par un test (liste) | Pattern 2 | le test `CHAMPS_LUS ⊆ contrat` doit lire une autre forme |
| A3 | Étage : session = tête ; sous-agent qui a au moins une voie enfant dans la fenêtre = manager ; autre sous-agent = worker | Jointures | un `vf-coder` lancé directement par la tête est un worker de profondeur 1 : la profondeur seule le classerait manager. À confirmer au plan (P74-D-21 dit « rôle et profondeur ») |
| A4 | L'interception de `window.fetch` par `VF_PRE` reste valable quand la page lit par `VF_ETAT.lireJson` | Tests | si la coquille lit par un worker ou un autre canal, la route factice doit passer par le serveur de test |
| A5 | Un projet contient au plus quelques dizaines de voies sur 24 h | Pitfall 2 | au-delà de ~200 voies, prévoir une virtualisation verticale réelle |
| A6 | `VF_COQUILLE.chargerOnglet('code')` rend le moteur prêt à recevoir `showBoard` à la résolution de sa promesse (A2 le dit « après le premier rendu ») | Pattern 6 | il faudrait attendre `ready` en plus |

## Open Questions

1. **« échec » sur la ligne de l'outil.** Le fil réduit n'a pas l'issue d'un appel. Options : (a) lignes d'événement à part
   (Pitfall 9), aucun changement serveur ; (b) étendre `reduireTranscript` d'un champ facultatif `echec: true` apparié par
   `tool_use_id` (C0 : un champ facultatif ne change pas la version), ce qui touche `vf-cockpit-transcript.mjs` et sa suite
   (P74-D-25 dit que la 74 ne lit aucun transcript elle-même). Recommandation : (a), et dire l'écart à l'UI-SPEC.
2. **« · déduit » par segment.** C3 ne dit pas si un segment vient de l'état officiel ou du transcript. Recommandation :
   « · déduit » pour tout segment antérieur à maintenant (l'index ne stocke que du déduit), l'état présent étant officiel
   (`etatOfficiel`) ; ou demander à la 79 un drapeau par segment (amendement de C3).
3. **Durée du tiroir « Au travail ».** `temps()` (`71-vf-equipe-rendu.js:82-86`) lit `dureeS`. L'UI-SPEC § 8 garde le tiroir
   inchangé ; P74-D-28 (2) retire « la durée qui compte les veilles » sans dire où. Recommandation : la 74 retire `dureeS`
   de ses surfaces et du panneau (qui disparaît) ; le tiroir reste à la décision du manager ou de la 73.
4. **Bascule et glyphes.** Qui pose la bascule et la table de glyphes (73 ou 74) : jointure des plans (P74-D-02, D-29).
5. **Numéros de fichiers ui** : réservation `74-vf-*` à confirmer avec 73, 75, 77, 80.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node | suites, `node:vm` | ✓ | v26.5.0 | — |
| Chrome / Chromium | suites navigateur | ✓ (macOS) | non relevé | volet navigateur « SAUTÉ, non compté comme réussi » (précédent `test-cockpit-transcript.sh:438-439`) |
| Route `/api/vf/frise`, `VF_ETAT`, `VF_COQUILLE`, `socle-serveur.sh` | plans 74-03 à 74-06 | ✗ (Phase 79 non exécutée) | — | plans 74-01 et 74-02 seulement ; route factice par `VF_PRE` |
| Régie de la 73 | plans 74-03 à 74-05 | ✗ | — | montage provisoire sous l'en-tête, à reprendre |

**Missing dependencies with no fallback :** aucune pour 74-01 et 74-02 ; pour le reste, l'exécution attend la 79 et la 73.

## Proposition de découpage (question 8)

Vague A = indépendante de la 79 à l'exécution. Vague B = après les vagues de la 79 qui livrent C3, C4, A13 (et A6 pour les
suites) et après la 73 (conteneur, ouverture). Vague C = après le merge de la 73 et de la 79 sur la branche d'intégration.

| Plan | Fichiers créés / modifiés | Exigences | Dépend de | Vague | À revalider |
|---|---|---|---|---|---|
| **74-01** Modèle pur de la frise et du coût | crée `ui/74-vf-frise-modele.js`, `tests/test-cockpit-frise-modele.sh` | TEMP-03, TEMP-04 (repli, courbe), TEMP-09, TEMP-10, part de TEMP-01 (ordre, fenêtres, troncature), TEMP-05 (état à t, nœuds portés), TEMP-02 (commits → branche, couverture) | contrats C0, C3, A8, A9, A14 (figés) | A | sur la 79 : bloc `cockpit-frise@1` du contrat (test `CHAMPS_LUS`) |
| **74-02** Fil et markdown fermé | crée `ui/74-vf-fiche-texte.js`, `tests/test-cockpit-fiche-texte.sh` | TEMP-08 (fil, filtres, coupe, markdown, « échec »), part de TEMP-11 (XSS unitaire) | `cockpit-transcript@2` (existant) ; C3 `evenements` | A | — |
| **74-03** Frise dans l'onglet Équipe | crée `ui/74-vf-frise.js`, `tests/test-cockpit-frise.sh`, `tests/chrome-frise.mjs` | TEMP-01, TEMP-02, TEMP-03, TEMP-04 (direct), TEMP-05 (curseur, encart), TEMP-09 (section Coût), TEMP-12 (forme) | 74-01 ; 79 (C3, C4, A13, A6) ; 73 (conteneur, bascule, glyphes) | B | sur la 79 et sur la 73 |
| **74-04** Fiche plein cadre | crée `ui/74-vf-fiche.js`, `tests/test-cockpit-fiche.sh` ; complète `chrome-frise.mjs` | TEMP-06, TEMP-07, TEMP-08 (direct, mandat), TEMP-12 (clavier, focus) | 74-02 ; 79 (A13) ; 73 (ouverture depuis la régie) | B (parallèle à 74-03 : fichiers disjoints sauf `chrome-frise.mjs`, à attribuer à un seul plan) | sur la 79 et sur la 73 |
| **74-05** Retraits et témoins réécrits | modifie `ui/72-vf-equipe.js`, `ui/71-vf-equipe-rendu.js`, `tests/test-cockpit-equipe.sh`, `tests/test-cockpit-transcript.sh`, `tests/chrome-equipe-clavier.mjs` | TEMP-12 (retraits), TEMP-06 (liens `#r=` → fiche) | 74-04 ; **merge de la 73** (mêmes fichiers) | C | sur la 73 ; `70-vf-live.js` hors périmètre tant que la 79 n'a pas mergé |
| **74-06** Passerelles, bornes, docs | crée `tests/test-cockpit-frise-xss.sh` ; modifie `ui/77-vf-git-vue-detail.js` (export `ouvrir(sha)`) ; crée le module côté Code pour « Voir sur la carte » si le repli `sessionStorage` est retenu ; modifie `plugin/cockpit/README.md`, `CHANGELOG.md`, `README.md` et `README.fr.md` (compteur) | TEMP-02 (clic commit), TEMP-05 (« Voir sur la carte »), TEMP-11, TEMP-12 (suites vertes) | 74-03, 74-04, 74-05 ; 79 (A2) ; 80 (routage) | C | sur la 79 (A2) et la 80 |

**Inévitable :** `CHANGELOG.md`, compteur des README racine, § « Équipe au travail » du README du module, les trois suites
et `71`/`72` partagées avec la 73 (d'où la vague C) ; `77-vf-git-vue-detail.js` (une ligne d'export, Phase 78). **Évité :**
tout fichier du moteur, `70-vf-live.js`, `80-vf-fr.js` et les dictionnaires (79), `ci.yml`, `vf-cockpit-interface.json`, le
bump de version (à la jointure de la vague).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash maison (`assert_eq`), Node `node:vm`, Chrome headless par `chrome-session.mjs` |
| Config file | aucun |
| Quick run command | `bash plugin/cockpit/scripts/tests/test-cockpit-frise-modele.sh` et `test-cockpit-fiche-texte.sh` (sans navigateur) |
| Full suite command | les suites du cockpit touchées (cinq neuves + `test-cockpit-equipe.sh`, `test-cockpit-transcript.sh`, `test-cockpit-chaine-xss.sh`), puis les commandes du job `gates` de `ci.yml` (jamais une liste de rapport) |

### Phase Requirements → Test Map

Chaque témoin rougit sur le code actuel (module absent, ou comportement présent) et verdit après.

| Req | Behavior | Type | Témoin rouge aujourd'hui → vert après | Fichier |
|---|---|---|---|---|
| TEMP-01 | bascule, voies, fenêtres, session au repos, troncature dite | Chrome + vm | `[role=tablist]` « Vue de l'équipe : régie ou frise » absent (rouge) ; 3 fenêtres exactes, aucun « 7 j » ; voie au repos listée ; « 1 voie commencée avant la fenêtre » | ❌ Wave 0 `test-cockpit-frise.sh`, `test-cockpit-frise-modele.sh` |
| TEMP-02 | 4 formes sans couleur, événements dans le rail, commits seulement sur Dépôt, clic → détail du commit | Chrome | `rect[data-etat="attend"]` absent ; avec : `fill="url(#…)"`, `stroke="none"` ; aucun losange dans une voie ; clic → `#vf-git-detail-<sha7>` présent (rouge tant que `ouvrir(sha)` n'existe pas) | ❌ `test-cockpit-frise.sh` |
| TEMP-03 | Horloge linéaire, Événements compressés | vm | rapport largeur/durée constant en Horloge ; deux silences de 3 et 40 min de même largeur en Événements ; libellé d'axe | ❌ `test-cockpit-frise-modele.sh` |
| TEMP-04 | repli > 12, compte écrit, direct sans donnée dans le flux | vm + Chrome | 13 voies → 12 visibles + « + N agents » ; un `frise` émis par l'`EventSource` enveloppé → une relecture GET, flux sans clé de frise | ❌ |
| TEMP-05 | curseur clavier, encart, nœuds dérivés, fichiers à t, « Voir sur la carte » | Chrome + vm | `[role=slider]` absent ; → augmente `aria-valuenow` d'1/90 ; aucun `ready`/`blocked` dans l'encart ; ≤ 6 lectures de fil par instant ; « Voir sur la carte » → `VibeFlow.state.container === 'q:answer'` sur Code | ❌ |
| TEMP-06 | fiche plein cadre, Échap rend le focus | Chrome | `role=region` « Fiche de … » absent ; après Échap `activeElement` = élément d'origine ; `#panel` inchangé | ❌ `test-cockpit-fiche.sh` |
| TEMP-07 | faits, « inconnu », pas de % sans source | vm + Chrome | champ absent → « inconnu », jamais « 0 » ; « Au travail » = somme des segments ≠ `dureeS` (fixture `dureeS` = 101 h) | ❌ |
| TEMP-08 | fil, filtres, markdown en DOM, « échec » sans texte | vm | `innerHTML` compté = 0 ; message `<img onerror>` → 0 `img` ; `[x](javascript:…)` → aucun `a` ; filtres cumulés exacts ; coupe dite au-delà de 50 / 200 | ❌ `test-cockpit-fiche-texte.sh` |
| TEMP-09 | agrégats, hors mission, fenêtre écrite, aucune devise | vm + Chrome | somme des missions + « Hors mission » = total ; manager `source: "enfants"` compté dans sa mission ; aucun `€`, `$`, « tarif » ; libellés « dernières 24 h » (jetons) et fenêtre affichée (durées) | ❌ |
| TEMP-10 | un seul calcul, champs déclarés | vm | `CHAMPS_LUS ⊆ contrat` (rouge tant que la 79 n'a pas déclaré `cockpit-frise@1`) ; mutant : une lecture de `/api/vf/transcript` pour compter des jetons → détectée par l'absence de toute requête transcript hors fiche et encart ; le témoin « message sur plusieurs lignes compté une fois » appartient à la suite de l'index de la 79 et est **relu** par la 74 sur une fixture de voie | ❌ ; à revalider sur la 79 |
| TEMP-11 | GET seul, jeton, clés interdites, export, réseau, XSS | Chrome + serveur | volet de chaîne XSS : C0f (rendu en `innerHTML` dans une copie de la sortie + CSP neutralisée + garde retirée) aboutit ; C1f code livré n'aboutit pas ; export sans `vf-frise`/`vf-fiche` ; aucune requête hors `127.0.0.1` | ❌ `test-cockpit-frise-xss.sh` |
| TEMP-12 | clavier, `.sr`, focus, mouvement réduit, thèmes, grille, français ; retraits | Chrome + statique | `node css-jetons.mjs ui/74-vf-*.js` → 0 ; inventaire des chaînes anglaises vide pour les fichiers 74 ; `[data-vf-transcript]` présent aujourd'hui (rouge) → absent ; `transcript` absent de `__vfEquipeRendu` ; contrastes ≥ 4,5:1 / 3:1 dans les deux thèmes | modifie `test-cockpit-equipe.sh`, `test-cockpit-transcript.sh` |

### Sampling Rate
- **Par commit de tâche :** la ou les suites du plan.
- **Par vague :** toutes les suites du cockpit touchées par la vague.
- **Gate de phase :** commandes du job `gates` de `ci.yml` rejouées telles quelles, puis toutes les suites du cockpit.

### Wave 0 Gaps
- [ ] `test-cockpit-frise-modele.sh` — TEMP-01, 03, 04, 05, 09, 10
- [ ] `test-cockpit-fiche-texte.sh` — TEMP-08, 11 (harnais vm étendu à `createElementNS`)
- [ ] `test-cockpit-frise.sh` + `chrome-frise.mjs` — TEMP-01 à 05, 09, 12
- [ ] `test-cockpit-fiche.sh` — TEMP-06, 07, 08, 12
- [ ] `test-cockpit-frise-xss.sh` — TEMP-11
- [ ] Fabrique de fixtures `cockpit-frise@1` dans `mktemp` (voies, segments, événements, un manager `source: "enfants"`, une voie hors `who`, une voie tronquée à gauche)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — |
| V3 Session Management | non | — |
| V4 Access Control | oui | jeton en en-tête, Host et Origin contrôlés par le serveur (`serve.mjs:533-534`) ; la 74 lit par `VF_ETAT.lireJson` |
| V5 Validation, Sanitization, Encoding | oui | `textContent` / `createElementNS`, aucun `innerHTML` de donnée ; sha validé avant requête (`77-vf-git-vue-detail.js:89`) ; identifiant d'agent validé par le serveur (`vf-cockpit-server.mjs:106`) |
| V6 Cryptography | non | — |
| V8 Data Protection | oui | fil jamais gardé hors mémoire de page, jamais exporté, `sessionStorage` limité à la position de la bascule (et, en repli, à la liste de chemins consommée une fois) |
| V14 Configuration | oui | CSP par empreintes inchangée (`serve.mjs:513-514`) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Nom d'agent, nœud, titre, message, cible hostile (donnée du lab ou du transcript) | Tampering / Elevation | rendu en texte ; volet XSS dédié avec témoin C0f |
| Lien `javascript:` dans un message | Elevation | lien rendu en texte, jamais un `a` |
| Fuite du fil dans le flux, l'export ou le stockage | Information disclosure | garde `porteInterdit` serveur ; aucune clé `fil` émise par la 74 ; test d'export |
| Dernière commande ou argument affichés | Information disclosure | la fiche n'appelle jamais `/api/vf/doing` ; le fil n'a que verbe et cible réduite |
| Données traduites (altération) | Tampering | Pitfall 3 |

## Sources

### Primary (HIGH confidence)
- Code du worktree `phase-74` : `build.mjs`, `viewer.html`, `serve.mjs`, `ui/00`, `70`, `71`, `72`, `73`, `77-*`, `80-vf-fr.js`,
  `vf-cockpit-build.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-transcript.mjs`, `vf-cockpit-git*.mjs`, `vf-cockpit-who.mjs`,
  `vf-cockpit-signal.mjs`, `vf-cockpit-interface.json`, `vf-cockpit-rename.mjs`, `vf-cockpit-fr-inventaire.mjs`, suites citées.
- `74-CONTEXT.md` (P74-D-01 à D-37), `74-UI-SPEC.md`, `REQUIREMENTS.md:1690-1701`.

### Secondary (MEDIUM confidence)
- `79-CONTEXT-3119d82a.md` (C0 à C6) et `79-CONTEXT-2ae6607a.md` (amendement A1 à A14) : contrats figés, code non écrit.

### Tertiary (LOW confidence)
- Comportement de la 73 (régie) : aucun artefact lu (hors de ce worktree), seulement ce qu'en disent 74-CONTEXT et l'UI-SPEC.

## Metadata

**Confidence breakdown :**
- Stack : HIGH, rien de neuf, tout relevé dans le module.
- Architecture : MEDIUM, montage et API de page dépendent de la 73 et de la 79.
- Pitfalls : HIGH pour ceux qui citent le code ; MEDIUM pour la performance (volumes réels non mesurés).

**Research date :** 2026-11-11
**Valid until :** jusqu'au merge de la 79 ou de la 73 (le premier des deux), puis relire § Points d'intégration et § Données.
