---
phase: 73
plan: "06"
requirements: [REGI-11, REGI-12]
---

# 73-06 — compositeur du titre, pastille de favicon, état « lu »

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré

- `assets/ui/90-vf-titre.js` (113 lignes, aucune ligne de plus de 160 points de code) :
  - `window.__vfTitre = { composer }` : titre « (N) vous attendent · <Onglet> · <nom> » (« (1) vous attend · … » au singulier), N = `__vfRegieModele.aVous(who)` ; à zéro, « <Onglet> · <nom> ». N'écrit que si le titre diffère. Aucun observateur (P73-D-38). Appelé au chargement, à chaque `who` (`VF_ETAT.abonner('who')`, sinon `vf-who`), à `vf-git:signal`, au changement de thème, à chaque arrivée d'onglet ; `ready` seulement sans coquille.
  - Pastille : `link[rel~=icon]` (créé s'il manque), href d'origine gardé dans `data-vf-icone-origine`, point plein `data:image/svg+xml` de la couleur du texte du thème quand N > 0, href d'origine rendu à zéro et au nettoyage. Aucun chiffre, aucune requête.
  - `window.__vfRegieLu = { lus() → Set | null, marquer(id), toutMarquer(ids) }` (`toutMarquer` n'existe qu'une fois le stockage lisible). Clé `vf-regie-lus:<lab>` (étiquette de `GET /api/vf/modeles`, une lecture par arrivée), valeur `{ <id>: <heure ms> }`, 200 entrées au plus, purge au-delà de 24 h au chargement, identifiant `[A-Za-z0-9_-]{1,128}` et heure finie ≤ maintenant revalidés. « Lu » = écoute de `vf-agent:lu` (clic sur « Lire le rapport », jamais le survol). Stockage refusé : `lus()` rend null, tout est à relire, pas de bouton. Après chaque écriture ou chargement : `vf-regie:redessiner`.
  - Inscription par `VF_COQUILLE.surOnglet(monter, { cle: '90-vf-titre.js' })` ; le nettoyage retire écouteurs, abonnement et icône.
- `00-vibeflow.js` ligne 13 et `76-vf-git-entete.js` ligne 19 : une ligne remplacée chacune (aucune ajoutée, 298 et 205 lignes inchangées) ; elles posent `window.__vfTitreBase` ({ onglet, nom }, puis `nom` du dépôt) au lieu d'écrire le titre. `80-vf-fr.js` et `viewer.html` non modifiés.
- `VENDORED.txt` : `AJOUT assets/ui/90-vf-titre.js` après `80-vf-fr.js`.
- Tests : `regie-rg-titre.sh` (RG0_ordre_titre, RG11_lu, RG12_titre), `chrome-regie-titre.mjs` (126 lignes), `73-06-RED-TRACE.md`.

## Écarts

- Écart : `90-vf-titre.js` est rejoué par onglet (pas de marqueur persistant, A53), comme le plan le supposait ; la mémoire entre deux arrivées est le `localStorage` « lu ».
- Écart : `80-vf-fr.js` (classe i18n) se charge avant le moteur ; le compositeur est le dernier fichier de la classe « onglet » et le dernier repère de la page assemblée (RG0.13 vert).
- Écart : avec la coquille, le rappel de `surOnglet` arrive après `ready` ; l'écriture « <nom> map » du moteur précède déjà le compositeur au chargement. Sans écrivain concurrent du titre après lui, le mutant « pas appelé à ready » n'a pas de scénario qui le fasse rougir ; les mutants gardés sont ceux du régime allégé (voir ci-dessous).
- Écart : mutants — un par garde : M-TITRE-SANS-WHO (compositeur non abonné au `who`, RG12.1) et M-TITRE-NETTOIE (nettoyage sans désabonnement, RG12.2), tous deux vus rouges. M-ORDRE-TITRE, M-TITRE-ECRIVAIN, M-TITRE-OBSERVE, M-TITRE-SANS-READY, M-TITRE-ZERO, M-TITRE-PLURIEL, M-LU-SURVOL, M-LU-SANS-PURGE non écrits (régime allégé).
- Banc : le harnais neutralise le `who` et le `reload` du serveur (le `hello` remplaçait la poussée) et tient en repos, par la clé de session `vf-equipe-rechargement`, le rechargement de l'ancien canevas d'Équipe (`72-vf-equipe.js`) qui recharge la page dès qu'un agent du `who` manque à la carte. Information pour les plans 73-08 à 73-10, qui retirent ce canevas.

## Suites jouées (une fois, sur la tête commitée)

| suite | verdict |
|-------|---------|
| `test-cockpit-regie.sh RG0_ordre_titre RG11_lu RG12_titre` | vert : 18 PASS / 0 FAIL (rouge vu sur la tête de départ : 5 PASS / 13 FAIL, voir la trace) |
| `test-cockpit-accessibilite.sh` | vert : 35 PASS / 0 FAIL |
| `test-cockpit-chrome-fr.sh` | vert : 141 PASS / 0 FAIL |
| `test-cockpit-git-entete.sh` | 119 PASS / 17 FAIL, les mêmes 17 sur la tête de départ (comparaison des deux listes de FAIL : aucune différence) : H2.3a, H2.3b, H9.2 et quinze mutants M-… ; aucun rouge nouveau |
| `test-cockpit-vendor.sh` (jouée seule, deux fois) | 251 PASS / 1 FAIL : V4 « check-file-size.sh sur tout le code du module » (sortie 2). Rouge déjà présent sur la tête de départ (la même commande rend 2 sur une copie de cette tête, `70-vf-live.js` fait 300 lignes) ; aucun fichier de ce plan n'atteint 300 lignes ; les lignes V4 « notre code sous 300 lignes », V4c (cliquet de colonnes) et l'inventaire `AJOUT` passent |
| `check-file-size.sh` (4 fichiers) | vert (00-vibeflow.js : 298, avertissement ≥ 250) |
| `check-machine-paths.sh` | vert |
| `check-version-sync.sh` | seul écart : la ligne « suites » (230 ≠ 231) |
| cliquet des colonnes (`colonnes-cliquet.mjs verifier`) | OK, baseline inchangée |

Rouges de la tête qui ne sont pas à ce plan : F.1 de `test-cockpit-routes.sh`, la ligne « suites » de `check-version-sync`, les témoins de la fenêtre rouge P73-D-39 (canevas d'Équipe) ; non rejoués ici.

Trace du rouge : `73-06-RED-TRACE.md`.
