# 73-07 — pied de la régie : arbres de travail, « ailleurs sur ce poste », non-fuite de bout en bout

Exigences : REGI-08, REGI-13 (page), REGI-14 (données non traduites), REGI-16 (export). Trace du rouge : `73-07-RED-TRACE.md`.

## Livré

- `ui/72-vf-regie-pied.js` (180 lignes) :
  - bloc `details` replié « Arbres de travail », lu à l'ouverture et à l'événement git (`VF_ETAT` clé `git`) par `GET /api/vf/git` et `GET /api/vf/git/worktrees`, jointure par chemin tenue en mémoire de fonction (jamais dans le DOM), pastilles neutres, « non vérifié » jamais « propre », « nom partagé : aucune cible rattachable » sur chaque arbre au nom en doublon, « Git est indisponible » avec « Réessayer », « Un seul arbre de travail. », aucune minuterie ;
  - règle de jointure retenue : un agent reçoit « N modifiés » en ligne 2 seulement si sa branche désigne UN seul arbre et que l'état de cet arbre est lu (jamais deviné) ; la carte branche → nombre est rendue à la source (`nonCommite`) et un `vf-regie:redessiner` est émis ;
  - ligne « Ailleurs sur ce poste : N sessions vous attendent, dans « lab »… » (trois noms, puis « et N autres »), nom posé en `textContent` dans un `<code>`, réponse tenue dans une variable du module, aucune écriture de stockage, aucune requête autre que GET.
- Tests : `chrome-regie-pied.mjs`, `chrome-regie-fuite.mjs`, `regie-rg-pied.sh` (RG8.1 à RG8.6, RG13.30 à RG13.35, RG14.20, RG14.21, RG16.20 ; mutants M-AILLEURS-PAGE-STOCKAGE et M-AILLEURS-FLUX).
- Supports couverts par la non-fuite (positif d'abord : la page affiche la ligne et le nom) : export, chaque fichier neuf ou modifié sous le lab (témoin : `server.json` parcouru), toutes les trames du flux (par le protocole, dont le `hello` d'une seconde connexion ouverte après la lecture), `__vfLive.who`, `/api/vf/etat`, `/api/vf/journal`, `localStorage`, `sessionStorage`, titre ; `/api/vf/transcript` sur l'identifiant sentinelle ne rend aucun transcript ; clés de la réponse comparées au bloc `cockpit-ailleurs@1` du contrat.

## Écarts

- Écart : aucun `vf-git:signal` n'existe plus dans la page (79-17) ; l'événement git du pied est `VF_ETAT.abonner('git')` (repli : événement de document `vf-git:signal`).
- Écart : le nombre N n'est pas connu replié (aucun appel git avant l'ouverture, RG8.2) : le titre dit « Arbres de travail » replié et « Arbres de travail (N) » dès la première lecture ; RG8.1 le prouve ouvert.
- Écart : deux lignes de `72-vf-regie-source.js` (hors `files_modified`) : la jointure `nonCommite` passée au modèle, et l'avertissement du pied à chaque `who` (un seul abonnement au `who` dans la page : RG15.10 l'exige).
- Écart : `vm-regie-page.mjs` (banc de 73-05) ne journalise plus les lectures `/api/vf/ailleurs` et `/api/vf/git` : RG15.6 comptait « aucune requête » au sens des requêtes d'ouverture d'agent, que la lecture d'« ailleurs » au montage n'a pas à rougir.
- Écart : RG16.20 cherche le balisage de la régie (`id="vf-equipe"`, classes `vf-rg-`, `data-vf-cle="`) et non les jetons nus : l'export est la page de la sortie, scripts compris, qui NOMMENT `vf-equipe` ; témoin positif : les mêmes motifs trouvent le DOM vivant.
- Écart : RG8.5 coupe `fetch` côté page (routes en échec) au lieu de rendre le dépôt illisible.
- Le mutant de collecte M-AILLEURS-DANS-WHO n'est pas écrit (régime allégé : un mutant par support de fuite, page et flux).
- Contrat voisin : la Phase 75 qui déplace la route dans `vf-cockpit-route-ailleurs.mjs` et ses mutants hors de `regie-rg-ailleurs.sh` n'est pas touchée (aucune retouche du serveur ni de ce fragment).

## Suites jouées et verdict (une fois, sur la tête commitée)

- `test-cockpit-regie.sh` complet (avant le reformatage du pied) : 263 PASS / 0 FAIL ; sections RG8_pied, RG13_page, RG14_fr, RG16_export, RG1_page, RG15_page, RG11_lu rejouées sur la tête finale : 54 PASS / 0 FAIL.
- `test-cockpit-chrome-fr.sh` 141 PASS / 0 FAIL ; `test-cockpit-fr-donnees.sh` 31 / 0 ; `test-cockpit-git-e2e.sh` 35 / 0 ; `test-cockpit-reseau.sh` 15 / 0 (aucune connexion sortante).
- `check-file-size.sh` (pied, source, deux harnais) ✓ ; `css-jetons.mjs` sur le pied ✓ ; `check-machine-paths.sh` ✓ ; `check-version-sync.sh` : seul écart, la ligne « suites » (230 ≠ 231).
- `test-cockpit-vendor.sh` jouée SEULE : rouge V4c.9a et V4c.9b (cliquet des colonnes, 250 PASS / 2 FAIL) : la HAUSSE du pied est corrigée (reformatage, e9cbf0f88) ; restent, hors de ce plan, `vf-cockpit-graphe.mjs` (réel 3, baseline 0), la ligne 56 de `72-vf-regie-source.js` (73-08, UIFN-12) et deux entrées PÉRIMÉES (`vf-cockpit-equipe-carte.mjs`, `72-vf-equipe.js`) que le retrait du canevas de 73-08 abaisse.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
