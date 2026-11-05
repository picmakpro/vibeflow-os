# 72-06 — Trace du rouge (interface de lancement des cartes)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-ui.sh` (rejouée sous bash ; la commande de vérification `OK-ROUGE-ATTENDU` rejouée sous bash ET zsh).
Base : module `plugin/cockpit/scripts/vf-cockpit-lancer-ui.mjs` ABSENT. Suite commitée en `3bc04859`, parent `efabf467`.
Résumé : `Résultats : 2 PASS / 42 FAIL`, rc=1, 9 « mutant sans effet », 0 « SUITE SAUTÉE ». Verts : LU.15 (port du serveur factice) et H0 (hygiène, aucun survivant).

Pourquoi ces rouges sont de bons rouges : chaque mode navigateur charge d'abord la page factice (`page factice prête` passe : le serveur jetable répond, le faux viewer et `__selectionner` existent), puis attend la section
`#panel [data-vf-lancer]` et échoue sur l'attente NOMMÉE ci-dessous. Ce n'est ni une fixture morte ni un chemin faux : le seul élément manquant est le module. Les sondes négatives joignent leur témoin positif dans le même mode,
qui est justement l'étape en échec ; aucune n'est verte sur la base.

## LU.S (statique, sans navigateur)

| sonde | attendu | obtenu |
|-------|---------|--------|
| LU.S1 chaîne vide si indisponible | `true` | `ABSENT` |
| LU.S2 une balise nue, aucun `<style>`, en-tête | `1/1/true/0/// VibeFlow (72-06) : lancer du travail depuis les cartes` | `ABSENT` |
| LU.S3 aucune adresse web en entier | `adresses=0 temoin=1` | `ABSENT` |
| LU.S4 deux `fetch` exactement | `2|/api/vf/lancer,/api/vf/lancer/cibles` | `ABSENT` |
| LU.S5 aucun appel ni littéral interdit | `interdits=aucun temoin=13` | `ABSENT` |
| LU.S6 `LIBELLES_VERBES` | `cadrer,planifier,executer,verifier,reprendre|Cadrer,Planifier,Exécuter,Vérifier,Reprendre|true` | `ABSENT` |
| LU.S7 `MOTIFS` | `aucun` (aucun écart de code ou de texte) | `ABSENT` |

## LU.1 à LU.14 (page factice sous Chrome)

| sonde | attendu | obtenu |
|-------|---------|--------|
| LU.1 phase `n:ph-72` | `{} Lancer du travail|Planifier:btn primary|Autres actions|Cadrer:btn soft,Exécuter:btn soft|true` | `{"phase":"attente de « section de n:ph-72 » dépassée (6000 ms)"} section absente` |
| LU.1 mission `n:dag-m1` | `Lancer du travail|Reprendre:btn primary|0|1` | `section absente` (étape arrêtée avec la précédente) |
| LU.2 cibles non ouvrantes + témoin | `{} 0,0,0,0,0,0 posts=0 err=0 temoin=Planifier:btn primary` | `{"temoin":"attente de « section de n:ph-72 » dépassée (6000 ms)"} ? posts=undefined err=undefined temoin=undefined` |
| LU.3 envoi (en-têtes, corps exact) | `{} 1|application/json|true|http://127.0.0.1:<port>|{"cible":"ph-72","verbe":"planifier"}|cible,verbe` | `{"envoi":"attente de « section de n:ph-72 » dépassée (6000 ms)"} undefined|undefined|…` |
| LU.3 double clic, jeton, message `role=status` | `posts=1` · `gets=true getsKo=0 postsKo=0` · `p|Proposition envoyée au terminal : Planifier — Phase 72. Confirmez-la dans le terminal.` | `posts=undefined`, mesures absentes (même attente nommée) |
| LU.4 verbe du menu | `{} {"cible":"ph-72","verbe":"executer"}` | `{"envoi":…}` puis `menu` jamais joué (étape arrêtée) |
| LU.5 bloquants / avertissements | `Bloqué : La phase est terminée.|Bloqué : Le terminal est indisponible sur ce poste. dis=3/3 posts=0` · `… dis=0 posts=1` | `{"bloques":"attente de « section de n:ph-72 » dépassée (6000 ms)"} section absente posts=undefined` |
| LU.6 travail non commité | `{} sans=0/Planifier:btn primary avec=Attention : Du travail non commité existe dans l'arbre de travail./dis=0` | attente de la section nommée dans `erreurs`, relevés absents |
| LU.7 état lancée (quatre formes valides, huit invalides) | `Lancée depuis la carte.¤Lancée : Planifier, en attente de la session.¤… session en cours.¤… session terminée.` · `¤¤¤¤¤¤¤ temoin=oui` | `{"liste":"attente de « section de n:l-vrai » dépassée (6000 ms)"} ¤¤¤` |
| LU.8 rendu hostile (5 assertions) | `{} imgs=0 m72=undefined violations=0` · `[] posts=2` · messages mot pour mot · corps `{cible, verbe}` · `Planifier|Bloqué : Contrôle non reconnu.|…` | `{"hostile":"attente de « section de n:ph-h1 » dépassée (6000 ms)"} imgs=undefined m72=undefined violations=undefined` |
| LU.9 touche Entrée | `{} posts=1 redessine=0` | `{"entree":"attente de « section de n:ph-72 » dépassée (6000 ms)"} posts=undefined redessine=undefined` |
| LU.10 avant / après / jamais | `avant=Planifier:btn primary apres=Planifier:btn primary` · `zones=0 err=0 reqs=0 api=undefined` | `{"avant":"attente de « section de n:ph-72 » dépassée (6000 ms)"} avant=undefined apres=undefined` · `?` |
| LU.11 hors Projet + témoin | `{} 0/0/0 0/0/0 0/0/0 temoin=Planifier:btn primary` | `{"temoin":"attente de « section de n:ph-72 » dépassée (6000 ms)"} ? temoin=undefined` |
| LU.12 refus et pannes | neuf messages, `imgs=0` | `{"cas":"attente de « section de n:ph-72 » dépassée (6000 ms)"}  imgs=0` (aucun message) |
| LU.13 liste invalide + témoin | `{} 0,0,0,0,0 0/0,… posts=0 temoin=Planifier:btn primary` | `{"temoin":"attente de « section de n:ph-72 » dépassée (6000 ms)"}   posts=undefined temoin=undefined` |
| LU.14 verbes (2 assertions) | `{} Planifier:btn primary+Exécuter:btn soft Cadrer:btn primary+… Exécuter:btn primary+` · `Aucune action disponible./0 …` | `{"liste":"attente de « section de n:v-inconnu » dépassée (6000 ms)"}` · `? ?` |

## Mutants sur la base : « sans effet : module absent »

| mutant | sonde visée | obtenu |
|--------|-------------|--------|
| M-INNERHTML | LU.8 | sans effet : module absent |
| M-ENTREE-VIEWER | LU.9 | sans effet : module absent |
| M-BLOQUANT-IGNORE | LU.5 | sans effet : module absent |
| M-CHAT-ENVOYE | LU.3 | sans effet : module absent |
| M-VERBE-LIBRE | LU.8, LU.14 | sans effet : module absent |
| M-DOUBLE-ENVOI | LU.3 | sans effet : module absent |
| M-JETON-ABSENT | LU.3 | sans effet : module absent |
| M-HORS-PROJET | LU.11 | sans effet : module absent |
| M-CIBLE-LIBRE | LU.2 | sans effet : module absent |
