# 70-RECETTE-JUGES — recette de la Phase 70 jouée par des juges frais (UIFN-10)

Statut : recette jouée ; corrections faites ; **tri de goût en attente de Samuel** (12 questions, aucune réponse) ; un écart connu bloquant (R13.4).

## Méthode

P70-D-19 (arbitrage de méthode de Samuel, session principale Claude Code, 2026-11-04, mot pour mot) : « si c'est pour me demande ca ca sert a rien,
lance des juge qui prenne des screenshot pour les tests, appele moi seulement si tu ne peux pas faire (gout, avis humain indispensable) ».

- Juges frais : sous-agents neufs, chacun avec son brief seul (la grille tirée de `70-CONTEXT.md` et `DESIGN.md`), jamais le processus de correction ;
  chacun sur son propre Chromium headless piloté par la bibliothèque `playwright`, deux thèmes, 390 / 768 / 1 024 / 1 440 px ; ils ne corrigent rien.
- **Juge A** (Code et Projet, tête `779bee45`) : français, visite, tiroir, zoom, en-tête, couleurs de statut, rechargement. Matière : dossier `juge-A/p70/captures/` (107 PNG, 5 JSON).
- **Juge Équipe** (tête `cf6983ac`) : onglet Équipe, interactions, clavier. Matière : dossier `juge-equipe2/captures/` (79 PNG). **Un premier juge Équipe s'est figé**
  (script interrompu sur une couleur nulle, aucune mesure exploitable) et a été remplacé par `juge-equipe2` ; seul ce dernier compte.
- Un vérificateur frais (`70-VERIFICATION.md`, sur `779bee45`, `gaps_found`) a trouvé REG-70-01 (centrage de la visite, grandes cartes) ; corrigée depuis en `42ae27cb`. Ce fichier, périmé, n'est pas versionné.
- Les captures restent hors dépôt (P70-D-17) et sont citées par nom de fichier. L'exécuteur de ce plan n'a relancé ni capture ni juge ; les verdicts ci-dessous sont repris
  des SUMMARY et RED-TRACE du dossier de phase. Un verdict de juge n'est jamais un arbitrage (ADR-031).

## Verdicts par point

« conforme » après correction signifie : le juge a rendu `non conforme` avec sa mesure, un témoin rouge puis vert a corrigé le défaut (commits dans la section suivante).
Les corrections ultérieures aux têtes jugées n'ont pas été recapturées par un juge ; leur preuve est le témoin rouge puis vert.

| Point | Largeur / thème | Verdict | Mesure ou capture |
|---|---|---|---|
| 1 En-tête mobile (une rangée, « ⋯ », 3 onglets lisibles à 13 px) | 390, deux thèmes | conforme | 56 px, 1 rangée, onglets 13 px / 3 px, aucun rogné : `code-sombre-390-menu.png`, `projet-clair-390-menu.png` |
| 1 bis Onglets aux valeurs de DESIGN.md | 768, 1 024, 1 440 ; deux thèmes | non conforme | 12 px / 2 px relevés (R13.4 : 6 FAIL) ; l'en-tête de Code ne tient pas à 1 024 px avec 13 px (il manque 24 px au plancher de padding 8 px, `70-04-RED-TRACE.md`) ; bloquant, question 1 |
| 2 Tiroir (tap de carte, titre, poignée, croix, Échap, vide) | 390, deux thèmes | conforme | R15.1 à R15.4c verts ; `code-sombre-390-tiroir-carte.png`, `-tiroir-titre.png`, `-tiroir-vide.png` |
| 3 Zoom, Code et Projet | 390 | conforme | pile 52 x 144 px à x 16, au-dessus de la barre de question (R14) |
| 3 bis Zoom, Code et Projet | 768, 1 024, 1 440 | conforme | inchangé (tablette) : x 308 y 108 à 768 px |
| 3 ter Zoom, Équipe | 390, 768, 1 024, 1 440 | conforme | 0 carte recouverte : rangée en bas à gauche dès 701 px (16, 956 à 768 ; 16, 710 à 1 024) ; avant : une carte recouverte à 768 px |
| 4 Visite, Code et Projet | 390 et 1 440, deux thèmes | conforme | quatre étapes mesurées une à une (cible, texte entier, « Passer », « n sur N », aucun anglais) ; `code-sombre-1440-visite1..4.png`, `projet-sombre-390-visite1..4.png` ; rechargement : `*-recharge1-visite1.png` |
| 4 bis Visite, grandes cartes | 1 440 | non conforme, corrigé | KO initial : centrage borné par la carte seule (REG-70-01) ; capture `projet-clair-1440-visite3.png` ; corrigé `42ae27cb`, témoin O6.10 |
| 5 Français : aucun anglais ni coquille dans le chrome | 1 440, deux thèmes | conforme | KO initiaux : « 2×click », « Inside {} », « Updated {} », fil d'Ariane doublé, textes de visite coupés ; corrigés (voir ci-dessous) ; reste en donnée, non traduit : constats de Santé, titres de fichiers (P67-D-20) |
| 6 Couleurs de statut, thème clair | 1 440 | conforme | `mesures-sondes.json` : pastilles 6,07 à 7,01:1 (clair), 4,59 à 8,69:1 (sombre) |
| 7 Finitions d'Équipe (badge, « non rattaché », boutons, champs, lien « Nœud ») | 390, 768, 1 024, 1 440 | conforme | KO initiaux : badge « En cours » hors de la carte à 1 440 px (droite -59 px, carte `Session dc083f35`), boutons du viewer restylés à tort ; corrigés `643bc7ac`, `94078aab` ; `equipe-sombre-1440-badge-sonde.png`, `equipe-*-lien-focus.png` |
| 8 Clavier : le focus reste sur « Lire le transcript » après Entrée | 390, 1 024, 1 440 | conforme | KO initial : focus perdu au redessin (`b.disabled`) ; corrigé `2ef9e1ea`, `0f01d442`, `643bc7ac` ; `equipe-*-transcript-clavier.png`, `-tiroir-commande-clavier.png` |
| 9 Titre et 1re carte d'Équipe sans recouvrement | 390, 768, 1 024, 1 440 | conforme | 22 752 / 17 408 / 17 400 px² avant, 0 après (`titreCarte1` à 0) ; `equipe-*-1024.png` |
| 10 Carte Session « en attente » avec badge « En cours » | Équipe | non conforme, hors périmètre | défaut de la Phase 69 révélé, pas créé par la 70 : voir « Écarts connus » |

## Corrections issues de la recette (témoin rouge puis vert)

| Plan | Défaut relevé par les juges | Commits |
|---|---|---|
| 70-03 | « 2×click » / « right-click », « Inside {} », « Updated {} » (ordre des gabarits), fil d'Ariane doublé, durée coupée, texte de visite et titre du travail récent tronqués, élision (« d'equipe-… ») | `bd9c8bd4` (rouge), `1321569c`, `16143669` (rouge), `3c8cf298` |
| 70-07 | rechargement : le centrage de la 1re étape dérivait de ~85 px ; REG-70-01 (grandes cartes) ; « Passer » ; contour de l'étape | `c60f0529` (rouge), `85f55133`, `a8e85ec7` (rouge), `73c5cb21` (rouge), `42ae27cb`, `779bee45` (docs) |
| 70-11 | focus perdu après redessin, badge hors de la carte, libellés anglais de la ligne des sources, jeton `--n-terminés` | `2f19b1d9`, `2ef9e1ea`, `0f01d442`, `643bc7ac` |
| 70-02 | sélecteur `.sec button` trop large (boutons du viewer restylés) resserré | `94078aab` |
| 70-12 | zoom d'Équipe sur une carte, titre superposé | `c555f584` (rouge), `c8f1d90d` |

## Écarts connus

1. **R13.4 à 1 024 et 1 440 px (bloquant)** : `test-cockpit-responsive.sh` reste à 255 PASS / 6 FAIL, les six lignes R13.4 (onglets à 12 px / 2 px au lieu de 13 px / 3 px
   à 1 024 et 1 440 px). Cause mesurée (`70-04-RED-TRACE.md`, recalcul P70-D-16) : à 1 024 px l'en-tête de Code ne tient pas avec 13 px et « Remonter » (il manque 24 px au plancher). Attend l'arbitrage de la question 1.
2. **Carte Session « en attente » mais badge « En cours »** : dans `72-vf-equipe.js`, tout état autre que « terminé » devient actif. Défaut de la Phase 69 révélé par la 70, non corrigé ; part au BACKLOG.
3. **`scripts/check-machine-paths.sh`** : vert sur macOS, rouge en CI Linux sur des chemins `/Users/<user>/…` écrits dans les plans. Plans corrigés en `c7217940` ; la cause du vert local n'a pas été diagnostiquée.
4. Corrections postérieures aux têtes jugées non recapturées (voir plus haut).

## Tri de goût en attente de Samuel

Les 12 questions envoyées, sans réponse. Aucun agent ne coche ni ne remplit une réponse (T-70-14). Recommandation = ce que le manager a proposé, pas un arbitrage.

### 1. Onglets à 13 px à 1 024 px (R13.4, bloquant)
Captures : `code-clair-1024.png`, `projet-sombre-1024.png`. Options : (a) badge « au travail » réduit à un point entre 701 et 1 279 px (recommandé) ; (b) retirer « Remonter » ; (c) garder 12 px / 2 px entre 1 000 et 1 279 px ; (d) actions dans « ⋯ ».
Réponse de Samuel (mot pour mot, canal, date) :

### 2. « écrit à <id d'agent> » (`vf-cockpit-transcript.mjs:12`, hérité de la 69)
Capture : `equipe-clair-1024-transcript-clavier.png`. Options : (a) rôle, sinon « un agent » (recommandé) ; (b) rôle + 8 caractères ; (c) rien.
Réponse de Samuel (mot pour mot, canal, date) :

### 3. Ajustement d'Équipe à 45 %
Captures : `equipe-clair-1024-termines-ajuste.png`, `equipe-sombre-1440-termines-ajuste.png`. Options : (a) garder ; (b) plafond 0,75 cadré sur la 1re carte (recommandé) ; (c) une colonne sous 701 px.
Réponse de Samuel (mot pour mot, canal, date) :

### 4. Centrage borné de la visite
Captures : `projet-clair-1440-visite3.png`, `code-sombre-1440-visite2.png`. Options : (a) garder (recommandé) ; (b) toujours centrer.
Réponse de Samuel (mot pour mot, canal, date) :

### 5. La visite éclaire au lieu de sélectionner
Captures : `projet-clair-1440-visite1.png`, `code-sombre-390-visite1.png`. Options : (a) garder (recommandé) ; (b) sélectionner.
Réponse de Samuel (mot pour mot, canal, date) :

### 6. Plafond de zoom ×1,6 sur téléphone
Captures : `code-sombre-390-tiroir-vide.png`, `projet-clair-390.png`. Options : (a) garder ; (b) relever (recommandé).
Réponse de Samuel (mot pour mot, canal, date) :

### 7. Étape « 2 services extérieurs » de la visite
Captures : `code-sombre-1440-visite2.png`, `code-sombre-1440-visite3.png`. Options : (a) viser le titre ; (b) viser les cartes des services (recommandé).
Réponse de Samuel (mot pour mot, canal, date) :

### 8. Pastille du « ⋯ »
Captures : `code-clair-390-menu.png`, `code-sombre-390-menu.png`. Options : (a) somme ; (b) point (recommandé) ; (c) Santé seul.
Réponse de Samuel (mot pour mot, canal, date) :

### 9. « Par où commencer en haut » et bouton icône
Captures : `code-sombre-1440-fr-parcours-menu.png`, `projet-sombre-1440-fr-parcours-menu.png`. Options : (a) garder ; (b) « le bouton de visite (icône), en haut » (recommandé). Infobulle « de ce code » sur Projet : « de ce projet » sauf avis contraire.
Réponse de Samuel (mot pour mot, canal, date) :

### 10. « composant » / « prioritaire »
Captures : `code-sombre-1440-fr-sante.png`, `code-sombre-1440-fr-base.png`. Options : (a) garder (recommandé) ; (b) « module » / « important ».
Réponse de Samuel (mot pour mot, canal, date) :

### 11. Libellé du thème dans « ⋯ »
Captures : `code-clair-390-menu.png`, `code-sombre-390-menu.png`. Options : (a) garder ; (b) « Thème : Auto » (recommandé).
Réponse de Samuel (mot pour mot, canal, date) :

### 12. Lien « Nœud » décalé de 10 px
Captures : `equipe-clair-1024-lien-focus.png`, `equipe-sombre-390-lien-survol.png`. Options : (a) aligner (recommandé) ; (b) garder.
Réponse de Samuel (mot pour mot, canal, date) :
