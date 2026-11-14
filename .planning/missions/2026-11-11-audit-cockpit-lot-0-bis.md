# Mission — lot 0 bis de l'audit du cockpit (2026-11-11)

> Mission hors phase du compartiment `fiabilite`, pilotée par vf-dev-manager, verrou `--ws=fiabilite --phase=72`
> (corrige du code livré par la Phase 72). Deux correctifs ajoutés à la PR #227 du lot 0, sur `fix/audit-cockpit-lot-0`
> (base 1f95d019). Décisions : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11. STATE, ROADMAP et
> REQUIREMENTS non touchés (mission hors phase).

## Résultat

| Ligne | Décision (mot pour mot) | Commit de code |
|---|---|---|
| AUDC-M11 | « Redescendre ensuite (Recommandé) » | 234c9b97 |
| AUDC-B-05 | « Le ranger hors du projet (Recommandé) » ; P72-D-20 amendée dans cette seule mesure | 9b58a6c6 |
| AUDC-Q1 | « Oui, garder ce mode (Recommandé) » : lecture de P72-D-02 confirmée, rien à coder | — |

Écritures de suivi : 5cd6d748 (REGISTRE, CHANGELOG du cockpit, README du cockpit, note d'amendement sous P72-D-20
dans 72-CONTEXT). Le § 5 du registre (AUDC-Q1) est laissé à une autre mission.

Chaque correctif est un commit isolé, révocable seul : prouvé par `git revert --no-commit` de chacun sur la tête
234c9b97, dans un arbre jetable, sans conflit (7 et 5 fichiers). Les deux touchent des fichiers disjoints.

## Comportement retenu

**AUDC-M11.** Le tiroir monte toujours pour montrer le bandeau (au moins 300 px, puis min(480 px, 60 % de la
fenêtre), jamais en plein écran), puis reprend la hauteur d'avant quand le bandeau disparaît de Q. Q le dit à P par
un message fixe de plus dans la liste fermée, `retrait`, émis au point unique où le bandeau est retiré :
« Annuler », lancement, proposition effacée côté serveur, expiration (la reprise a lieu quand le bandeau expiré
remplace le bandeau vivant ; « Fermer » sur le bandeau expiré n'émet rien de plus). `annulation` garde son sens.
Décisions de détail, toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option
recommandée » :
- une hauteur réglée par l'utilisateur pendant le bandeau (souris, clavier, double-clic, redimensionnement de la
  fenêtre) annule la reprise : sa hauteur reste ; un `retrait` reçu en plein glissement ne reprend rien ;
- une proposition qui en remplace une autre n'émet pas de `retrait` et ne fait pas oublier la hauteur d'origine ;
- tiroir déjà assez haut : ni rehaussé, ni repris ;
- plein écran basculé pendant le bandeau : la reprise vaut pour la hauteur interne ;
- fin du terminal avec un bandeau affiché : le bandeau reste dans Q, rien n'est émis, le tiroir reste rehaussé ;
- la hauteur mémorisée n'est jamais touchée ; l'ouverture du tiroir n'est pas défaite.

**AUDC-B-05.** Le dernier mode vit dans le dossier d'état du poste, par projet :
`${XDG_CACHE_HOME:-~/.cache}/vibeflow/cockpit-mode/<empreinte>/terminal-mode`. Convention reprise des états du poste
déjà en place dans le dépôt (contrôle de santé des gardes, vérification de mise à jour) ; le dépôt n'emploie nulle
part `XDG_STATE_HOME`. Un nettoyage de ce cache ramène seulement la présélection à `default`. Surcharge
`VF_COCKPIT_MODE_DIR` (chemin absolu) pour isoler les tests. Clé : sha256 tronqué du chemin réel de la racine du lab,
jamais servie, journalisée ni transmise ; deux worktrees d'un même dépôt sont deux projets (les fusionner exigerait de
lire un `.git` que le lab peut forger). Dossiers 0700 et fichier 0600 contrôlés (lien, propriétaire, droits) ;
lecture et écriture durcies comme avant ; aucun repli vers le lab. Le support n'est jamais accepté sous la racine du
lab : jugé par identité de dossier sur chaque ancêtre (forme textuelle et forme résolue par le système), avant toute
création puis à nouveau avant l'écriture (décision déléguée, option recommandée, après deux constats d'audit).
**Ancien fichier du lab** : n'est plus jamais lu, aucune migration (la lire rouvrirait la voie). Il est laissé en
place : aucun code ne le nomme plus, et le retirer au démarrage ajouterait une suppression dans un dossier que le lab
peut forger. Tout le reste de P72-D-02bis et P72-D-20 tient.

## Plan de bataille (DAG)

1. `exec-m11` et `exec-b05` en parallèle (vf-coder, un worktree chacun depuis 1f95d019, fichiers déclarés disjoints).
2. `revue-b05` (vf-reviewer) et `audit-b05` (vf-auditer) en parallèle ; `revue-m11` (vf-reviewer). Chaque passe de
   correction revue par un juge frais scopé au diff de la passe.
3. `jointure` : réduction de chaque branche de travail en un commit sur `fix/audit-cockpit-lot-0`, preuve de
   révocabilité, rejeu du job `gates`, rejeu des suites `lancer-*` et `terminal-*` sur la tête intégrée.
4. `recette` : juge à captures, Playwright, 1280 × 720.
5. `docs` puis `livraison` (push, corps de la PR, CI).

Étage design croisé non posé : réglage d'un écran existant.

## Témoins (rouge avant, vert après)

Rejoués sur le code de 1f95d019 avec les tests neufs, puis sur le code corrigé. Traces complètes dans les blocs typés
des workers.

AUDC-M11 — `test-cockpit-lancer-bandeau.sh` et `test-cockpit-terminal-tiroir.sh` :
- LB.R1 (Annuler) : attendu `160/420/1/1/160/160/160>160/true`, obtenu avant `160/420/0/0/420/420/160>160/true`.
- LB.R2 (lancement) : attendu `304/420/1/1/304/304/304>304/true`, obtenu avant `304/420/0/0/420/420/304>304/true`.
- LB.R3 (expiration) : attendu `160/420/1/1/160/160/160>160/true`, obtenu avant `160/420/0/0/420/420/160>160/true`.
- LB.R7 (hauteur par défaut), LB.R6 et TH.23 (remplacement), TH.20 : rouges avant de la même façon (420 ou 480 au
  lieu de la hauteur d'origine).
- TH.24 (plein écran) : la première forme était tautologique sous le bash 3.2 de macOS (une expression à accolades
  dans l'argument d'`assert_eq` faisait comparer deux copies de la mesure). Réécrite ; rouge sous le comportement
  d'origine : attendu `160/480/160/true/160>160 160/160/false/160`, obtenu `160/480/480/true/160>160 480/480/false/160`.
  `assert_eq` des deux suites refuse désormais un appel qui ne reçoit pas exactement trois arguments (261 appels
  comptés, tous à trois).
- LB.R4, LB.R5, TH.21, TH.22, TH.22c, TH.27 : propriétés déjà vraies avant (rien à reprendre) ; prouvées par leurs
  mutants. Mutants rouges : reprise retirée (bandeau et tiroir), reprise qui écrase le réglage (usager, clavier,
  souris, glissement, fenêtre), reprise qui touche la hauteur mémorisée, `retrait` non émis, remplacement qui émet,
  hauteur d'origine oubliée au remplacement.

AUDC-B-05 — `test-cockpit-lancer-mode.sh` (64 PASS / 29 FAIL sur le code d'origine, 113 PASS / 0 FAIL après) :
- (a) ancien fichier du lab préréglé : `LM.Q10(a)` attendu `default 204 herite plan`, obtenu avant
  `herite 204 plan absent` ; variante `acceptEdits` : attendu `default default`, obtenu avant `acceptEdits herite`.
- (b) survie à une relance : `LM.Q3` (autre port) et `LM.Q4` (arrêt brutal de Q).
- (c) deux projets : `LM.Q10(c)` attendu `default plan acceptEdits fichiers-distincts`, obtenu avant
  `plan acceptEdits acceptEdits`.
- (d) valeur forgée : `LM.Q5` (mot inconnu, texte long, lien, droits 0644, dossier 0755, dossier en lien) attendu
  `default` ×7 puis `acceptEdits`, obtenu avant `acceptEdits` ×8.
- (e) page Projet : `LM.S2` (frontière statique), `LM.P1` à `LM.P4`, `LM.Q10(e)` ; vrais avant et après, comme voulu.
- Confinement : `LM.U13`, `LM.Q10(f)` (vrai Q, surcharge pointée sous le lab : attendu `default 204 herite 3`, obtenu
  avant `herite 204 plan 3`), `LM.U15` (casse et NFD : attendu `default,false,0`, obtenu au tour précédent
  `plan,true,0`), `LM.U16` (deux jugements), `LM.U17` (preuve générative, graine 20261111, 60 cas : 0 écart).
- Mutants rouges : lecture de l'ancien fichier rétablie, clé commune, droits 0644, droits et propriétaire des
  dossiers, garde de confinement retirée, garde par chaîne seule, premier jugement retiré, second jugement retiré.
- Rejoué aussi sur un volume sensible à la casse (cas de la CI Linux) : 113 PASS / 0 FAIL après correction d'un
  attendu de mutant qui y rougissait à tort.
- L'état réel du poste n'a reçu aucun fichier pendant les suites (liste avant/après identique).

## Juges

- Revue B-05 : `passed` ; trois mineurs corrigés (base acceptée sous le lab, clause propriétaire sans témoin, README).
- Audit sécurité B-05 (vf-auditer, délégation à l'audit outillé) : `passed`, aucun bloquant ni majeur. Les cinq
  questions (influence d'un lab reçu, résolution du dossier, fuite, frontière P/Q, isolation des suites) tiennent ;
  un mineur de classe « base pilotée par l'environnement hérité, sans confinement » corrigé.
- Ré-audit du tour 1 : `passed`, un mineur de classe « confinement jugé sur une résolution qui ne canonise ni la
  casse ni la normalisation Unicode » ; fermé au tour 2 par l'identité de dossier et la preuve générative.
- Ré-audit du tour 2 : classe fermée ; deux défauts de preuve (faux rouge sous système sensible à la casse, premier
  jugement sans témoin) corrigés au tour 3 ; revue du tour 3 `passed`, une phrase de limite trop rassurante corrigée
  au tour 4.
- Revue M11 : `passed` ; deux mineurs corrigés (TH.24 tautologique, fenêtre sans témoin) ; revue de la passe
  `passed`.
- Recette par juge à captures (Playwright, 1280 × 720, tête 234c9b97) : `passed`. Tiroir 259 px avant, 432 px à la
  proposition (phrase « écrit cette ligne dans le terminal sans la lancer » visible), 259 px après « Annuler », 259 px
  après le lancement (ligne écrite à l'invite sans retour chariot) ; réglé à la main à 332 px pendant le bandeau :
  332 px après « Annuler ». Captures dans le dossier non suivi `.playwright-mcp/audc-recette-bis/` de l'arbre principal.

## Limites et points ouverts

- Fenêtre résiduelle B-05 : un renommage concurrent par le même compte entre le dernier contrôle et l'écriture peut
  placer le support sous le lab ; le lab ne relit jamais ce support. Acceptée et dite dans l'en-tête du module
  (décision déléguée, option recommandée), au rang de la limite « poste mono-utilisateur ».
- Rien n'oblige par machine une future suite qui lance un vrai terminal à isoler le dossier d'état.
- `72-SECURITY.md` (T-72-127, T-72-128, I3) et `72-16-PLAN.md` décrivent encore le support « fichier du lab » au
  présent : documents de phase non réécrits, la note d'amendement de 72-CONTEXT fait foi.
- M11 : à la fin du terminal, un bandeau affiché garde le tiroir rehaussé.
- Constat de la recette, sans lien avec M11 : le bloc défilant du bandeau dépasse de 7 px sous son pied collant.
- Après « Lancer », le panneau de P garde « Confirmez-la dans le terminal » environ 1 s avant « Commande préparée ».

## Incidents

- Coupure à 15 h 33 (quota du compte) : les deux premiers codeurs arrêtés en plein travail, diffs non commités
  sauvegardés hors dépôt par la session principale ; deux codeurs relancés avec relecture ligne à ligne du diff
  hérité (verdict : rien de coupé en plein fichier ; des témoins qui ne rougissaient pas, un mutant devenu sans effet),
  commits à chaque étape qui tient, réduits à un commit par correctif à la jointure.
- Le juge de recette a d'abord vu une capture tomber à la racine de l'arbre principal (l'outil refusait le
  scratchpad) ; déplacée aussitôt sous `.playwright-mcp/`, dossier supprimé.
- Le premier auditeur a écrit une note de mémoire d'agent (au niveau de la classe, sans recette) dans l'arbre
  principal, hors de la branche de mission.

## Coût

12 agents dispatchés : 4 vf-coder (2 coupés par le quota, 2 relancés), 4 vf-reviewer, 3 vf-auditer, 1 juge à captures ;
5 reprises par message (4 tours de correction B-05, 1 M11). Jetons relevés sur les blocs reçus (dernier relevé par
agent) : 1 671 206 ; les deux codeurs coupés n'ont pas rendu de bloc. Tours de correction : 4 pour B-05, 1 pour M11.

## Preuves E6

Format : verdict — commande — code de sortie — SHA. Les SHA 68c65a88, 380eca77 et eac3e4de sont ceux des branches
de travail locales, jamais poussées et supprimées après la jointure ; leur contenu est celui de 9b58a6c6 (au
commentaire d'en-tête près, tour 4) et de 234c9b97.

- Revue B-05 — `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh` — 0 — 68c65a88 (branche de travail).
- Audit B-05 — les cinq suites `test-cockpit-lancer-{mode,processus,xss,chat,bout-en-bout}.sh` — 0 — 68c65a88.
- Revue du tour 3 B-05 — `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh` — 0 — 380eca77.
- Revue M11 et passe — `test-cockpit-terminal-tiroir.sh` (138 PASS) et `test-cockpit-lancer-bandeau.sh` (161 PASS) —
  0 — eac3e4de.
- Révocabilité — `git revert --no-commit 9b58a6c6`, puis `234c9b97`, chacun seul sur 234c9b97 — sans conflit.
- Job `gates` de ci.yml rejoué par l'outil de rejeu de la Phase 40.1 — 21 étapes rejouées, 4 sautées
  (conditionnelles au push sur `main`), 0 en échec — 5cd6d748.
- Recette par captures — 5 points, tous tenus — 234c9b97.
- Rejeu des suites `lancer-*` et `terminal-*` sur la tête intégrée et CI de la PR #227 : voir la PR.

```json
{
 "preuves": [
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh",
   "exit_code": 0,
   "sha": "380eca77"
  },
  {
   "verdict": "audit",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh",
   "exit_code": 0,
   "sha": "68c65a88"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh",
   "exit_code": 0,
   "sha": "eac3e4de"
  },
  {
   "verdict": "revue",
   "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh",
   "exit_code": 0,
   "sha": "eac3e4de"
  },
  {
   "verdict": "gate:ci-gates",
   "commande": "replay-ci-jobs.sh --job gates",
   "exit_code": 0,
   "sha": "5cd6d748"
  },
  {
   "verdict": "recette",
   "preuve": "amont"
  }
 ]
}
```

## Clôture (2026-11-12)

Mandat de clôture de la session principale après la CI de la PR #227 et une seconde recette par juge à captures.

- **CI rouge du shard 6 (`test-cockpit-lancer-bandeau.sh`, LB.E11, LB.E12, LB.E14)** : instabilité de sonde
  préexistante, pas une régression d'AUDC-M11. La même famille de rouge (moitié témoin « Entrée fraîche = 1 » à 0,
  diagnostic « Entrée fraîche perdue ») existait sur 312d9637, avant le code du lot 0 bis (première tentative rouge,
  seconde verte) ; la propriété protégée (répétitions = 0 octet) n'a jamais rougi ; le code M11 côté Q se borne à un
  évènement de document et un message vers le parent, que le faux P de ces cas ignore. Une relance des jobs en échec,
  une fois : verte. Sonde non modifiée faute de mesure qui localise la lecture prématurée (limite pour le socle de test
  de la Phase 79).
- **AUDC-H4, trois restes (b16c57fc)** : nom accessible d'une carte, mot du glossaire dans une description, gabarit
  « N files in <chemin>/ » d'une carte dossier. Trois tours de revue ; le deuxième a trouvé une régression sondée
  (panneau d'un dossier ouvert sans sélection), corrigée en jugeant l'item que le panneau décrit.
- **AUDC-B-03 contre l'ouverture du terminal (017dd0b5)** : défaut confirmé dans le vrai Chrome (la page de
  redirection locale du lanceur partait en inter-sites, 403, clé non échangée ; mesuré aussi dans Firefox sur les
  en-têtes). Correctif : une seule exception, liée à un secret d'ouverture à usage unique distinct de la clé et à une
  clé armée ; une lecture sûre unique partagée par l'échange, l'armement et le secret. Audit, revue, puis regard frais
  de sécurité : `passed`, aucun bloquant ni majeur. Restent ouverts : une page du même site passe la porte sans secret
  (réserve héritée D-M6, à arbitrer) ; le secret reste dans l'adresse après usage ; le retrait du secret à l'échange
  et au balayage n'a pas de témoin ; Safari non mesuré.
- Décisions de la session principale (« décision déléguée par Samuel (message session principale, 2026-11-11 :
  « tranche pour chacun de ces points »), prise par la session principale ») : le nom lisible des cartes de fichiers
  est gardé ; le second onglet du même navigateur qui ouvre le terminal sans nouvelle clé est voulu, la phrase du
  README part au plan de documentation de la Phase 79.

## Prochaine étape

Relecture de la PR #227 par Samuel (lot 0 et lot 0 bis), puis la Phase 79 en première vague.
