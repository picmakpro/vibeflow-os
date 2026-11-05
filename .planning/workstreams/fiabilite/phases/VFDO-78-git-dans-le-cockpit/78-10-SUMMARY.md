---
phase: 78
plan: "10"
subsystem: cockpit
requirements-completed: [GITC-07, GITC-08, GITC-10, GITC-11]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/77-vf-git-vue-detail.js
    - plugin/cockpit/scripts/tests/temoins/git-tiroir-details.json
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-10-RED-TRACE.md
  modified:
    - plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
---

# 78-10 : détail d'un commit, état des worktrees, clavier du graphe, rafraîchissement (GITC-07, 08, 10, 11 côté page)

Troisième fichier 77, `77-vf-git-vue-detail.js` (183 lignes, plafond 220), branché sur le registre `window.VFGitExt` de 78-06 (crochets `rangee`, `rendu`, `etat`). `77-vf-git-rendu.js` (171) et `77-vf-git-tiroir.js` (180) n'ont pas été touchés : les trois crochets suffisaient. Suite `test-cockpit-git-tiroir.sh` : **98 réussis, 0 échoué, 0 sauté** (D1 à D3 de 78-06 inchangées, D7 à D9 neuves, 8 mutants dont 3 neufs). Rouges avant le code : `78-10-RED-TRACE.md`.

## Comportement exact

- **Sélection** : clic, Entrée ou Espace sur une rangée la sélectionne et ouvre le détail sous elle ; second clic ou Entrée sur la même rangée le replie ; un seul détail à la fois. Le détail est un `li[role=none]` frère de la rangée (la liste garde des options seules), contenant un `div[role=region]` nommé « Détail du commit <sha7> ».
- **Clavier du graphe** (tabindex itinérant) : une seule rangée à `tabindex=0` (la sélectionnée, sinon la première) ; ↓ ↑ déplacent focus ET sélection (sans ouvrir le détail), Début et Fin vont aux bouts ; `aria-selected` sur la seule rangée active ; Entrée ou Espace ouvre ou ferme le détail ; Échap replie le détail et laisse le focus sur la rangée (le tiroir reste ouvert ; sans détail ouvert, Échap ferme le tiroir comme avant ; Échap depuis l'intérieur du détail le replie aussi). Ctrl, Alt, Méta laissent la touche passer. `aria-label` de rangée : « <sha7>, <message>, branche <b>, il y a <t> » (branche locale puis distante, omise sinon).
- **Détail** : message entier en `pre-wrap` (sujet en 600), auteur et date longue « 5 nov. 2026, 14 h 32 » (heure locale du navigateur), sha complet sélectionnable, « Fichiers (total) », **30 fichiers puis « et k autres »** (k = total - 30, le serveur en sert jusqu'à 500), `+n` en `--ok-text` et `−n` en `--err-text` (signe dans le texte), « binaire » pour un binaire, « ancien → nouveau » pour un renommage, deux commandes à copier (`git show --stat …`, `git switch --detach …`). Aucun diff. Un commit étant immuable, la réponse est gardée par sha (une relecture du tiroir ne la redemande pas).
- **Erreurs locales** : sha hors `^[0-9a-f]{40}$` refusé par la page avant toute requête ; réponse non 200, hors schéma ou `h` différent du sha demandé : « Indisponible » + « Réessayer » dans le détail seul, le reste du tiroir continue.
- **États des worktrees** : `GET /api/vf/git/worktrees` à l'ouverture du tiroir (une requête) et à chaque rafale de signal ; pastilles par worktree : « propre », « n modifiés », « n non suivis » (« 200+ » si `plus`), « ↑a ↓r » en mono, « état illisible » si le dossier a disparu, « état indisponible » si la route échoue ; mention `approximatif : filtres du dépôt non exécutés` sous la liste quand `approximatif`. Chaque pastille porte son texte.
- **Rafraîchissement** : `vf-git:signal` (sur `document`), tiroir ouvert : regroupement de 300 ms (trailing), puis UNE relecture de `/api/vf/git` et UNE de `/api/vf/git/worktrees`, contenu remplacé sans fondu, sélection retrouvée par sha, détail rouvert depuis le cache (0 requête), position de la rangée sélectionnée conservée (ancre calculée avant la relecture, corrigée après : ± 2 px mesuré), focus rendu à la rangée s'il y était, annonce `aria-live` « Historique mis à jour » une fois par rafale. Sha disparue : détail replié, aucune sélection, première rangée tabulable. Tiroir fermé : aucune requête ; le signal manqué est mémorisé et la lecture refaite à la réouverture.

## Mesures

Tailles finales : vue-detail 183, rendu 171 (inchangé), tiroir 180 (inchangé). `css-jetons.mjs` rend 0 sur les trois fichiers 77. `test-cockpit-vendor.sh` 0, `test-cockpit-git-entete.sh` 0, `test-cockpit-chrome-fr.sh` 0.
Captures (1440 px, scratchpad, pour le juge de design) :
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-detail-clair-1440.png
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-detail-sombre-1440.png
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-worktrees-clair-1440.png
- /private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-worktrees-sombre-1440.png

## Valeurs d'espacement posées (grille 2-4-6-8-12-16-20-24-32) et jeton de remplacement au rebase de la 71.5

| Valeur | Où | Jeton |
|---|---|---|
| `margin: 0 0 8px` | sous le détail | `--sp-8` |
| `gap: 8px`, `padding: 12px` | carte du détail (une seule élévation, `--raise`) | `--sp-8`, `--sp-12` |
| `gap: 4px` | liste des fichiers, pastilles d'état | `--sp-4` |
| `gap: 8px` | ligne de fichier | `--sp-8` |
| `padding: 2px 8px` | pastille d'état | `--sp-2`, `--sp-8` |
| `margin-top: 8px` | mention « approximatif » | `--sp-8` |
| `min-height: 44px` | bouton « Réessayer » en tactile | cible tactile |

## Déviations

1. **Troisième fichier 77 (`77-vf-git-vue-detail.js`)**, hors `files_modified` du plan : décision du manager d'origine ; ligne `AJOUT` posée dans `VENDORED.txt` (posée seulement une fois `git diff --quiet` vrai, dans la même commande que le commit). Le plan interdisait un fichier ui neuf par prudence sur `VENDORED.txt` ; l'interdit est levé par le mandat.
2. **`VFGitRendu.detail`, `pastillesWorktree`, `dateLongue` et `VFGitTiroir.selection()/selectionner()` du plan** : ces fonctions vivent dans le troisième fichier ; la sélection est exposée par `window.VFGitDetail = { selection, selectionner, detailOuvert }` (le tiroir est gelé et n'a pas été rouvert).
3. **Pastilles sans fond teinté** : le plan posait `--warn-text` sur `--warn-bg` et `--ok-text` sur `--ok-bg`. Sur cette branche ces fonds sont encore teintés ; les jetons figés de la 71.5 (jamais de fond teinté d'état) l'emportent : fond neutre `rgba(var(--ink), .06)` (celui des pilules d'étiquette), texte `--warn-text` ou `--ok-text`, mot toujours présent.
4. **Une relecture de `/api/vf/git/worktrees` par rafale de signal** (D9.1 du plan), alors que le mandat dit de ne pas l'appeler « à chaque signal » : le signal n'est émis que sur changement réel des refs, de la liste des worktrees ou des index, regroupé en rafales de 300 ms ; mais la route est synchrone côté serveur (~1,2 s sur un gros dépôt), voir finding.
5. **Réouverture après signal manqué** : non prévu au plan, ajouté (D9.3) : sans lui, un signal reçu tiroir fermé laissait le tiroir rouvrir sur des données périmées.
6. **Message du détail** : le premier paragraphe-sujet et le corps sont deux `span` ; la mutation M-DETAIL-HTML cible le corps.
7. **Jeton lu par la suite** : la page enrobe `fetch` et réécrit `x-floorplan-token` en `x-vf-cockpit-token` ; D7 lit donc l'en-tête tel que le serveur le voit (comme D1.2).

## Mutants (trace : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-trace-<nom>.json`)

- **M-DETAIL-HTML** (le corps du message devient `innerHTML`) : rougit D7.2 : `balises: 1` (un `<script>` naît dans le détail), `msgLit: false`, alors que le détail est là (`nb: 1`, 30 fichiers).
- **M-SELECTION** (le détail précédent n'est plus refermé) : rougit D8.1 : `details: 2` ; le clavier marche (rangée 1 après ↓ ↓ ↑, Entrée ouvre 1 détail).
- **M-RAFALE** (une relecture par signal, sans regroupement) : rougit D9.1 : `git: 3, wt: 3` au lieu de 1 et 1 ; la sélection est conservée (la cause du rouge est le compte, pas la perte de sélection).

## Findings

- `/api/vf/git/worktrees` bloque la boucle du serveur ~1,2 s par appel (78-08) : une relecture par rafale de signal sur un gros dépôt gèle brièvement le cockpit. Hors périmètre (route de 78-08), à arbitrer par le manager (rendre la route asynchrone ou ne la relire que sur changement de la liste des worktrees).
- Parcours lecteur d'écran réel (UI-SPEC §8.8) : non joué, backstop (le plan le classe ainsi) ; D8 en couvre le clavier, les rôles et les noms.
- Vérification de lisibilité du détail à 375 px : mesurée (D9.4, pas de débordement, le tiroir défile seul), pas de capture à cette largeur.

## Suites rejouées

`test-cockpit-git-tiroir.sh` 98/0/0 · `test-cockpit-vendor.sh` rc 0 · `test-cockpit-git-entete.sh` rc 0 · `test-cockpit-chrome-fr.sh` rc 0 · `css-jetons.mjs` rc 0.
