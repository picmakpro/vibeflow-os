# 67 — Recette humaine de fin de phase (bloc `<human-check>` de 67-07, tâche 2)

**Statut : FAITE le 2026-11-02 — 7/7 réponses consignées (session principale).** Ce fichier prépare la recette ; il ne la remplit pas. Chaque point reste
décoché tant que Samuel n'a pas répondu ; sa réponse est ensuite consignée **mot pour mot, avec son canal et sa date**
(mémoire « arbitrage humain jamais inférable »). Le vérificateur de phase consolide ce fichier dans le fichier UAT.

Pré-requis : un vrai navigateur (Chrome, Safari ou Firefox), Node ≥ 22, la branche `feat/v2-cockpit` à son dernier commit.

## 1. Lancer le cockpit

Depuis la racine du dépôt (là où se trouve `plugin/`) :

```bash
# A. sur l'arbre réel (ce dépôt)
node plugin/cockpit/scripts/vf-cockpit.mjs open --rebuild
#    imprime : Cockpit : http://127.0.0.1:<port>/ (Code) · http://127.0.0.1:<port>/project.html (Projet)

# B. sur un lab GSD jetable (plat, deux phases, un DAG) — copier-coller tel quel
LAB="$(mktemp -d)"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-socle" "$LAB/.planning/phases/02-suite" "$LAB/.planning/missions"
printf 'export const u = () => 1;\n' > "$LAB/src/util.js"
printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - la suite\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-socle/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-socle/01-01-SUMMARY.md"
printf '<objective>Faire la suite</objective>\n' > "$LAB/.planning/phases/02-suite/02-01-PLAN.md"
printf '{"nodes":[{"id":"a","step":"première étape","stage":"","deps":[],"scope":["src/**"],"status":"done"},{"id":"b","step":"seconde étape","stage":"","deps":["a"],"scope":["src/**"],"status":"running"}]}\n' > "$LAB/.planning/missions/demo.dag.json"
git -C "$LAB" init -q
node plugin/cockpit/scripts/vf-cockpit.mjs open --lab "$LAB" --rebuild
echo "$LAB"   # à noter : c'est le lab jetable

# C. sur n'importe quel autre lab GSD (dossier portant .planning/)
node plugin/cockpit/scripts/vf-cockpit.mjs open --lab <dossier-du-lab> --rebuild
```

Ouvrir les deux adresses imprimées (onglets **Code** et **Projet**). Pour arrêter : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab <dossier>`
(le serveur s'arrête aussi seul 60 minutes après la fermeture du dernier onglet).

## 2. Ce qu'il faut regarder

1. **Marque.** Titre de l'onglet du navigateur, logo et favicon VibeFlow ; aucune mention du produit d'origine nulle part
   (en-tête, panneaux, visite guidée, santé, glossaire, boîte d'export, infobulles).
2. **Français, deux onglets.** Racine, une phase, un tableau de réponse, « Par où commencer », « Santé », glossaire (survoler un
   terme souligné), « Exporter », « Parcours » ; en-tête lisible à 1 280 et à 1 440 px de large.
   *Limite déjà connue* : sur l'onglet **Code**, les messages du panneau « Santé » et les notes de couverture sont produits en
   anglais à l'assemblage (données du moteur, pas du chrome) ; à juger comme écart acceptable ou non.
3. **Onglet Projet.** « Où en est-on ? » répond tout de suite ; une question « pourquoi » répond en 15 à 30 s par l'agent ; le
   sélecteur de modèle montre Sonnet par défaut ; un passage à Haiku survit au rechargement de la page.
4. **« Au travail ».** Dans le lab où tourne une session Claude Code (la vôtre), le badge « au travail » la montre ; « Voir la
   dernière commande » la révèle dans la ligne ; un export téléchargé (« Exporter ») ne la contient pas.
5. **Réseau.** Outils réseau du navigateur (onglet Réseau, filtre « tout ») : aucune requête vers un autre hôte ni un autre port
   que celui du cockpit au chargement des deux onglets.
6. **Direct.** Dans le lab jetable : basculer le statut d'un nœud de DAG met la carte à jour en moins de 2 s, sans recharger la
   page ni perdre le zoom (cocher la dernière phase du seul jalon est une modification STRUCTURELLE : la page se recharge et le
   zoom est perdu, elle ne teste donc pas le direct) :
   ```bash
   # le nœud « b » du DAG passe de running à done : la carte de la mission se met à jour (résumé « 2 nœuds, 2 faits », pied 2/2)
   perl -pi -e 's/("id":"b"[^}]*"status":")running/${1}done/' "$LAB/.planning/missions/demo.dag.json"
   # pour recommencer : le remettre en cours
   perl -pi -e 's/("id":"b"[^}]*"status":")done/${1}running/' "$LAB/.planning/missions/demo.dag.json"
   ```
7. **Fenêtre ajustable (CKPT-12).** Sur les deux onglets, ouvrir le cockpit à 1 920 px puis réduire la fenêtre à la main
   jusqu'à 1 024 px, et la rouvrir : rien ne se superpose, rien n'est rogné (en-tête, panneau, barre de question), le nom de
   projet long se termine par une ellipse, la carte se recadre. Sous 1 024 px (tablette, fenêtre étroite) le rendu reste lisible.

## 3. Réponses de Samuel (à remplir par lui, jamais par un agent)

| Point | Réponse mot pour mot | Canal | Date |
|-------|----------------------|-------|------|
| 1. Marque | « Oui, je vois bien le logo dans l'onglet du navigateur. Le favicon marche bien. Je vois bien aussi le titre de l'onglet qui s'affiche, donc c'est bon, l'entête est bon aussi dans la page en elle-même. […] Seul point que je remarque, c'est du coup pour le point 3, pour la visite guidée. Alors la visite guidée est pas mal, je trouve qu'elle manque un chouïa de clarté, même si elle est bien, parce que du coup elle permet de deep dive dans un projet, de le comprendre assez facilement. Seul point que je remarque, et je te l'ai envoyé en photo, quand on arrive à la fin des étapes, il y a deux croix qui apparaissent, en fait le chevron qui va vers la droite disparaît et est remplacé par une croix, et du coup ce qui fait que la croix qui était déjà présente, en fait il y en a deux maintenant. Donc je t'ai envoyé ça en photo, c'est un petit bug d'affichage, une petite fonctionnalité pas fou. On enchaîne sur les autres tests. » — Relevé : D1 double croix en fin de Trajectoire (capture 2026-11-02 15:57) ; I1 clarté de la visite guidée ; recherche du nom d'origine non confirmée | Wispr Flow (dictée), session principale | 2026-11-02 |
| 2. Français (deux onglets, 1 280 et 1 440 px ; limite Santé du Code) | « Oui, tout est en français. Santé est bien marqué en français, dans le panneau. Et comme je disais, je pense que c'est pas un gros souci d'avoir de l'anglais. Oui, là, les différentes largeurs gardent l'en-tête visible, ça fonctionne bien. Le seul truc que je pourrais voir comme amélioration, c'est que quand on glisse les graphes en dessous de la headline, et donc par exemple de la vue d'ensemble en fait, je remarque que en fait il n'y a pas de fond transparent, et donc le texte se confond avec les graphes. Ce que je proposerais, ça serait de mettre un léger blur derrière le titre vue d'ensemble et le titre et le sous-titre. Donc mettre un léger blur en dessous, ça pourrait être pas mal. » — Relevé : limite anglais de Santé (Code) acceptée ; I2 léger flou derrière le titre et le sous-titre de la vue d'ensemble | Wispr Flow (dictée), session principale | 2026-11-02 |
| 3. Questions et modèle | « 1. c'est bon, il y a un temps de reflexion respectable 2. Temps de reponse, affichage et pertinence au top. 3. Oui ca marche » — Relevé : OK ; « Où en est-on ? » n'a pas paru instantané (attendu : réponse immédiate), à vérifier | saisie texte, session principale | 2026-11-02 |
| 4. « Au travail » et dernière commande | « Malheureusement le drawer a droite qui conteient "Au travail" n'est pas bien affichée voir photo. […] voir la commande. 3. Oui pas visible dans l'export 4. Oui c'est bon » — Relevé (captures 2026-11-02 20:41 et 20:42) : D2 tiroir « Au travail » sans marge intérieure (texte collé au bord gauche, titre rogné) et étiré sur toute la hauteur ; D3 « Voir la dernière commande » affiche le dernier message de l'assistant en markdown brut, pas une commande ; export sans la commande OK ; branche de session correcte (R-2 levé) | saisie texte + captures, session principale | 2026-11-02 |
| 5. Réseau | « Oui a tout » — Relevé : OK, aucune requête hors 127.0.0.1:4378 sur les deux onglets | saisie texte, session principale | 2026-11-02 |
| 6. Direct (bascule d'un nœud de DAG) | « ok refait » / « refait » / « On voit une legere anamiation de réaparition car je pense que c'est mis a jour, mais le zoom et le deplacement sont rester et la carte c'est mise a jour » — Relevé : OK sur trois bascules (20:53:18, 20:53:35, 20:53:43) ; carte à jour, zoom et déplacement conservés ; I3 légère animation de réapparition de la carte à chaque mise à jour (à adoucir ou supprimer) ; serveur du lab jetable arrêté entre-temps (arrêt d'inactivité prévu), relancé | saisie texte, session principale | 2026-11-02 |
| 7. Fenêtre ajustable (1 920 → 1 024 px, à chaud) | « tout est parfait en 1024, c'est quand on arrive en largeur mobile que ca coince, tout apparait bien mais la hierachisation de l'info est attroce, tout les boutons deviennent en ligne avec des petit icone, le zoom (boutons: - [] + ) se retouvent en haut a cote de la barre de recherche alors qu'ils pourrait devenir une stack vertical (meme design mais vertical) et a gauche au dessus du chat (text input). Le boutons pour ouvrir le drawer (sheet en mode mobile, ca c'est très bien) pourrait s'ouvrir seulement au click que une carte ou le titre ('src' pour l'exemple de démo actuel) en fonction du context. Le reste des boutons pourraient etre groupé. » — Relevé (capture 2026-11-02 20:59, lab jetable) : OK à 1 024 px sur macOS (l'échec CI Linux à 1 024 px n'est pas reproduit sur Mac) ; D4 hiérarchie de l'information en largeur mobile : rangée d'icônes sans libellé ; I4 zoom (− [] +) en pile verticale à gauche au-dessus de la barre de question ; I5 tiroir (sheet mobile, apprécié) ouvert au clic sur une carte ou le titre selon le contexte, sans bouton dédié ; I6 regrouper les autres boutons | saisie texte + capture, session principale | 2026-11-02 |

## 4. Arbitrage des suites (Samuel, AskUserQuestion session principale, 2026-11-02)

Dans la PR #187, avant merge :
- **D3** : « Voir la dernière commande » affiche le dernier message de l'assistant (markdown brut) au lieu de la dernière commande.
- **CI** : `test-cockpit-responsive.sh` rouge sous Linux à 1 024 px (en-tête : `div.brand` et `nav.vf-tabs` recouvrent `#search-btn`, `#btn-recent` et `#screens-btn` sortent de la fenêtre), alors que macOS est conforme.
- **D2** : tiroir « Au travail » sans marge intérieure, titre rogné, hauteur étirée sur tout l'écran.
- **D1** : double croix en fin de Trajectoire (le chevron « suivant » devient une croix).
- **V1** : vérifier que « Où en est-on ? » répond sans passer par l'agent (réponse jugée non instantanée).
- Libellé « Library » en anglais au-dessus d'un dossier (onglet Code).
- **I2** : léger flou derrière le titre et le sous-titre de la vue d'ensemble.
- **I3** : en direct, n'animer que ce qui change, pas la carte entière.

Phase suivante : refonte mobile (D4, I4, I5, I6) et clarté de la visite guidée (I1) — `BACKLOG.md`.
Backlog : commande `/vf-recette` ; le MCP Wispr Flow n'est pas retenu.

Le commit local `54b2d0fa` (autre session du 2026-11-02) et ses entrées de `BACKLOG.md` partent avec cette PR (Samuel, AskUserQuestion session principale, 2026-11-02).

## 5. Suites traitées (mission du 2026-11-02, rédigé par vf-dev-manager)

Rapport détaillé : `.planning/missions/2026-11-02-67-recette-fix.md`. Chaque correctif a un témoin rouge sur l'ancien code.

| Point | Statut | Commit(s) |
|-------|--------|-----------|
| D3 dernière commande | corrigé : dernière commande Bash, masquée puis coupée à 120 car. ; masque élargi après revue | `a9355579`, `8a72c600` |
| CI 1 024 px Linux | corrigé : cause = `(pointer: fine)` faux sous Chrome headless Linux (aucun pointeur), pas les polices | `e20e7959` |
| D2 tiroir « Au travail » | corrigé : marge des panneaux, hauteur au contenu, plafond et défilement | `a9355579` |
| D1 double croix | corrigé : chevron « suivant » inactif à la dernière étape | `7434afd8` |
| V1 « Où en est-on ? » | corrigé : la voie locale ne dépendait que de l'absence de session d'agent | `8207eb31` |
| Libellé « Library » | corrigé : type de carte = chrome, traduit | `a9985d63` |
| I2 flou | corrigé | `bc31d88d` |
| I3 animation en direct | corrigé : seules les cartes basculées clignotent | `84e683f4` |

V1 — effet de bord arbitré : une relance qui dépend du fil et contient un mot de la voie locale reçoit la réponse
locale (Samuel, « A : garder le correctif (Recommandé) », AskUserQuestion session principale, 2026-11-02).
