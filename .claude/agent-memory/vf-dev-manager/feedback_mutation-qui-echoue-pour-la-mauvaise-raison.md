---
name: mutation-qui-echoue-pour-la-mauvaise-raison
description: Un test de mutation qui rougit peut rougir pour une autre cause que la mutation — exiger que le worker nomme la cause observée du rouge, pas seulement le rouge
metadata:
  type: feedback
---

Exiger, dans tout mandat qui demande de « prouver le rouge par mutation », que le worker **nomme la
cause observée du rouge** — l'assertion précise qui a basculé et la valeur obtenue — et pas seulement
qu'il déclare le mutant tué.

**Why:** mesuré en Phase 27 (2026-08-06) sur un test qui restreint `$PATH` pour épuiser une cascade
de résolution. Le fixture piège du test avait lui-même besoin de `bash`, puis de `cat`, sur ce `PATH`
restreint. Sans eux, il **échouait pour la mauvaise raison** et retombait accidentellement sur la
valeur attendue (`stages: null`) — masquant la mutation. Deux faux positifs successifs avant
d'obtenir un vrai rouge. Un test qui passe parce que tout est cassé ressemble exactement à un test
qui passe parce que le code est bon. Le symétrique du piège déjà connu ici : un vert tautologique
(cf. [[revue-obligatoire-cout-erreur-asymetrique]] et [[check-agents-vacuous-green]]).

**Variante jumelle, mesurée en Phase 30 (2026-08-16) — l'assertion vraie dans les DEUX états.**
Symétrique exact du cas ci-dessus, et bien plus discret : le cas rougit *aussi* sur le code **non
muté**, donc son rouge ne prouve rien. Vu deux fois dans la même phase : des cas `m2` attendant
`stdout empty` sur un chemin qui émet légitimement un message (le « rouge » était l'état nominal) ;
et une matrice annoncée « générique, 8 séquences » dont **6 restaient vertes sur du code
délibérément cassé** — sa conception (un paramètre constant aux deux appels) ne couvrait que la
diagonale sans le dire. Dans les deux cas le commentaire du test identifiait correctement le
mécanisme visé ; seul le câblage ne suivait pas.

**Le contrôle qui ferme les deux variantes, à exiger dans tout mandat** : pour chaque cas censé être
discriminant, vérifier qu'il **passe au vert sur le code NON muté** ET **rougit sur le code muté**.
Un cas vrai dans un seul état, quel qu'il soit, ne teste rien. Et quand un worker annonce une
« matrice » ou une « couverture générique », faire **nommer les cas qui mordent réellement** — sur
5 faux verts consécutifs dans cette phase, tous ont été trouvés par un **juge externe**, jamais par
l'auteur ni par la suite.

**How to apply:** dans le mandat, demander la **trace** (« assertion X, attendu Y, obtenu Z ») plutôt
qu'un verdict. Se méfier particulièrement des mutations sur des tests qui **manipulent
l'environnement** (`PATH`, `HOME`, `CLAUDE_CONFIG_DIR`, `cwd`) : ce sont ceux dont le fixture peut
mourir avant d'exercer ce qu'il teste. Corollaire pour les tests de non-régression d'un vecteur de
sécurité : exiger que le rouge vienne de la **réintroduction du comportement**, jamais de la présence
d'une chaîne de caractères dans le source — un renommage contournerait le second.

**Le manager n'y échappe pas — 3 fois en une mission (Phase 38, 2026-08-29).**
Vérifier un correctif est un test, donc soumis à la même règle. Mes trois ratés, tous « rouge pour
la mauvaise raison », tous démasqués par un TÉMOIN et non par relecture :
1. Garde `--target` : `status` sur cible non vide rendait `exit 1` — j'ai lu « refus de garde »,
   c'était `Cache introuvable` **en aval**. Le témoin (cible **vide**) rendait le MÊME code : c'est
   lui qui a montré que la garde laissait passer.
2. Sonde `kimi-code` : `detect` rendait vide — j'ai failli conclure « fix inopérant ». En réalité
   `env -i` avait **retiré `node` du PATH**, et `kimi` est un script Node (`env: node: No such
   file`).
3. Même sonde, 2ᵉ essai : j'ai rajouté `/opt/homebrew/bin` pour `node`… qui contient aussi
   `claude`, détecté **en premier** par la cascade. Le résultat (`claude`) était juste, ma fixture
   était fausse.

**How to apply (manager) :** quand une vérification rend un rouge, ne PAS le rapporter avant
d'avoir (a) lu le **message**, pas seulement le code de sortie — un refus attendu et un échec
fortuit sortent tous deux en `1` ; (b) fait tourner un **témoin** qui devrait passer ; (c) vérifié
que la fixture fournit **toutes** les dépendances du chemin testé (`env -i` est un piège :
il retire `node`, `python3`, tout). Et pour une cascade de détection, isoler à **un seul**
candidat — sinon on mesure la priorité, pas la détection.
