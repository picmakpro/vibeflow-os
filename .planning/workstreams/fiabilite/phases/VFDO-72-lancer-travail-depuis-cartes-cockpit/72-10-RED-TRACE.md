# 72-10 — RED-TRACE : processus de Q (proposition, armement, lancement, refus)

Date : 2026-11-05. Commit des tests (commit A) : `ea718f86` (`test(72-10): témoins rouges du processus de Q …`).
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-processus.sh > <fichier> 2>&1`, jouée sur la BASE (`vf-cockpit-terminal-processus.mjs` inchangé, aucune route de lancement).
Résultat : exit 1, `Résultats : 12 PASS, 30 FAIL`. Q0 : 4 PASS, 0 FAIL (le parent factice, l'amorçage, le flux, l'invite, le PID du shell sont sains).

## Lecture du rouge (pourquoi c'est la bonne raison)

- Route absente : `GET /proposition` rend 403 en navigateur simulé (la route n'est pas dans la liste des chemins sans Origin), 404 avec l'Origin de Q ; `POST /lancer` et `POST /annuler` rendent 404 (`!(p in routes)`) ; aucune proposition ne peut être exposée, donc les corps sont vides et les `id` vides.
- Les gardes de la suite évitent le vert à vide : un `id`, une ligne ou un UUID absents deviennent des marqueurs (`LIGNE-ABSENTE-DU-CORPS`, `UUID-ABSENT`) que le flux et la page ne peuvent pas contenir (un motif vide aurait trouvé tout). Première exécution : deux faux PASS de ce genre (Q5 « ligne à l'invite » et Q9 « page sans UUID ») ont été trouvés et corrigés avant le commit A.
- Les PASS de la base sont des propriétés vacuement vraies, chacune appariée à une assertion rouge de la même section : Q1 « sans Origin 403 » (le refus de Origin existe déjà), Q3 flux inchangé (rien n'a été proposé), Q5 « argv absent » (rien n'a été écrit), Q6 « fichier du récepteur vide » (le récepteur n'a rien reçu), Q9 « page servie », Q11 « aucun message lancee ».
- Chaque mutant : M-ORIGINE-LANCER s'applique (l'ancre existe) mais la route est absente : 404 au lieu de 204. M-ID-LIBRE, M-TEXTE-LIGNE et M-RETOUR-CHARIOT : « mutant sans effet » (ancres absentes, le code n'existe pas encore).

## Détail des 30 FAIL (libellé, attendu, obtenu)

- Q1 — sans proposition : 200 et {"etat":"aucune"}
  - attendu: [200 {"etat":"aucune"}]
  - obtenu : [403 ]
- Q1 — témoin positif (200 ci-dessus) puis : sans secret 401 ; Host localhost 403
  - attendu: [200 401 403]
  - obtenu : [403 403 403]
- Q1 — avec l'Origin de Q et le secret, sans Sec-Fetch-Site : 200 (comme GET /etat)
  - attendu: [200]
  - obtenu : [404]
- Q3 — quatre propositions hors liste (cible 72;touch M, cible absente, verbe hors verbes, compartiment a$(touch M)) : GET reste aucune
  - attendu: [ {"etat":"aucune"} {"etat":"aucune"} {"etat":"aucune"} {"etat":"aucune"}]
  - obtenu : [    ]
- Q2 — une clé en trop dans la proposition (ligne, intention hostiles) : refusée ou sans le texte injecté dans les lignes
  - attendu: [true]
  - obtenu : []
- Q2 — proposition valide : clés du contrat §4, quatre lignes dans l'alphabet, UUID commun, herite sans --permission-mode, trois autres avec leur mode
  - attendu: [ok]
  - obtenu : [corps non JSON]
- Q4 — arme_apres_ms lu : au moins 400 ms (sinon la sonde 425 est indécidable)
  - attendu: [oui]
  - obtenu : [non (vide)]
- Q4 — avant armement : POST /lancer rend 425, la proposition reste en attente, le flux est inchangé
  - attendu: [425 en-attente inchange]
  - obtenu : [404  inchange]
- Q7 — Origin de P (secret, onglet A, id valides, armée) : 403, la proposition reste en attente, le flux est inchangé
  - attendu: [403 en-attente inchange]
  - obtenu : [403  inchange]
- Q8 — secret erroné 401 · autre onglet 409 · Host localhost 403 · sans Origin 403 · id inconnu 404 · mode hors liste 400 · champ ligne 400 · corps de 600 octets 413
  - attendu: [401 409 403 403 404 400 400 413]
  - obtenu : [401 404 403 403 404 404 404 404]
- Q8 — aucun octet au PTY et la proposition armée reste en attente (le témoin positif suit : Q5)
  - attendu: [inchange en-attente true]
  - obtenu : [inchange ]
- Q5 — après armement : POST /lancer {id, mode:herite} rend 204 (témoin positif de Q7 et de Q8 : même appel, Origin de Q)
  - attendu: [204]
  - obtenu : [404]
- Q5 — la ligne herite EXACTE de GET /proposition apparaît à l'invite
  - attendu: [TROUVE]
  - obtenu : [ABSENT]
- Q11 — exactement un message « lancee » pour ce lancement, aux clés t, cible, verbe, session, at ; session = l'UUID de la ligne écrite
  - attendu: [1 at,cible,session,t,verbe true]
  - obtenu : [0  ]
- Q5 — le client tape Entrée : le faux claude a tourné, argv exact (UUID de la ligne, -n, intention, aucun --permission-mode)
  - attendu: [--session-id|UUID-ABSENT|-n|vf-phase-1-fiabilite|/vf-dev Cadre la Phase 1 du compartiment fiabilite|]
  - obtenu : [absent]
- Q9 — second POST /lancer du même id : 404 ; GET /proposition : aucune
  - attendu: [404 {"etat":"aucune"}]
  - obtenu : [404 ]
- Q9 — la page ne contient ni la ligne ni l'UUID de session ; GET /proposition rend encore aucune
  - attendu: [0 {"etat":"aucune"}]
  - obtenu : [0 ]
- Q12 — GET montre la seconde (verbe executer, autre id) ; l'ancien id rend 404 ; la seconde reste en attente
  - attendu: [executer autre 404 true]
  - obtenu : [  404 ]
- Q10 — Origin de P : 403 et la proposition reste en attente ; id inconnu : 404 (témoin : la proposition existe)
  - attendu: [403 en-attente 404]
  - obtenu : [403  404]
- Q10 — POST /annuler {id} : 204, puis GET rend aucune, puis le même id rend 404
  - attendu: [204 {"etat":"aucune"} 404]
  - obtenu : [404  404]
- Q6 — POST /lancer rend 409, le programme vit encore, la proposition est toujours en attente (même id), aucun message « lancee » de plus
  - attendu: [409 vivant true 1]
  - obtenu : [404 vivant  0]
- Q6 — après la fin du programme et le retour de l'invite : un nouveau POST /lancer rend 204 et la ligne paraît
  - attendu: [TROUVE 204 TROUVE 2]
  - obtenu : [TROUVE 404 ABSENT 0]
- Q13 — chat:true sans conversation : 400 ; chat non booléen : 400 ; flux inchangé (témoin : la proposition est en attente)
  - attendu: [en-attente 400 400 inchange]
  - obtenu : [ 404 404 inchange]
- Q13 — GET porte chat:true et lignes_chat (quatre modes : UUID de session commun, reprise -r et --fork-session) ; les lignes standard n'en portent aucun
  - attendu: [ok]
  - obtenu : [corps non JSON]
- Q13 — POST {id, mode:herite, chat:true} : 204 et la ligne de lignes_chat.herite figure à l'invite
  - attendu: [204 TROUVE]
  - obtenu : [404 ABSENT]
- Q11 — exactement un message « lancee » par lancement réussi (trois au total) et aucun sur les refus
  - attendu: [3]
  - obtenu : [0]
- M-ORIGINE-LANCER — sous le mutant, l'Origin de P est acceptée (204 au lieu de 403) : Q7 rougit
  - attendu: [204]
  - obtenu : [404]
- M-ID-LIBRE — mutant sans effet (ancre absente ou inchangée)
  - attendu: [effet]
  - obtenu : [sans effet]
- M-TEXTE-LIGNE — mutant sans effet (ancre absente ou inchangée)
  - attendu: [effet]
  - obtenu : [sans effet]
- M-RETOUR-CHARIOT — mutant sans effet (ancre absente ou inchangée)
  - attendu: [effet]
  - obtenu : [sans effet]
## Correction de la suite avant le code (commit `bea79843`)

Deux défauts de FIXTURE trouvés en jouant le code (aucun assertion affaiblie) : (1) les apostrophes du champ `ligne` hostile (Q2 clé en trop, Q8 champ `ligne`, M-TEXTE-LIGNE) fermaient la chaîne shell entre guillemets simples : le corps JSON envoyé n'était pas celui voulu, M-TEXTE-LIGNE donnait 400/ABSENT au lieu de 204/TROUVE ; les apostrophes sont désormais transmises en `'` (JSON valide), la ligne du client commence bien par `claude --session-id '` et ne se distingue de la bonne que par son texte. (2) Q1 « sans secret » : sans Origin ni secret valide, la route rend 403 comme `GET /etat` (même contrôle) ; la sonde « sans secret » passe désormais avec l'Origin de Q et rend 401.

## Vert sur le code livré

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-processus.sh`, HEAD `549d3bcc` : exit 0, `Résultats : 42 PASS, 0 FAIL` (Q0 à Q13, Q11 en trois mesures, quatre mutants, H0). Chaque mutant a son résultat fautif exact asserté :

- M-ORIGINE-LANCER : 204 (au lieu de 403 de Q7)
- M-ID-LIBRE : 204 (au lieu de 404 de Q8)
- M-TEXTE-LIGNE : 204 et la ligne hostile du client à l'invite (au lieu de 400 de Q8)
- M-RETOUR-CHARIOT : 400 et la ligne absente de l'invite (au lieu de 204 et ligne présente de Q5)

Suites voisines, HEAD `549d3bcc` : `test-cockpit-terminal-{activation 40, client 71, lanceur 111, page 49, pty-plantage 21, pty 63, serveur 208, session 58, tiroir 75, xss 17, xterm 80}.sh` : toutes exit 0, 0 FAIL.

Un défaut réel a été trouvé et corrigé ICI (commit `549d3bcc`) : la première version admettait `/proposition` dans la ligne `const navigateur = …`, ce qui cassait le mutant NAV-POST de `test-cockpit-terminal-serveur.sh` (« mutant sans effet », 207 PASS / 1 FAIL) ; `controle()` est maintenant inchangé et `traiter` fait passer `GET /proposition` par `controle(req, <url de /etat>)` : exactement les contrôles de `GET /etat`, sans ligne dupliquée (le compteur `egal=2` de la sonde TC reste exact).

## Écarts de nom

Aucun : `creerEtatLancer({ gabarit })`, `definirCibles`, `proposer`, `lire`, `consommer`, `confirmer`, `rendre`, `annuler` (72-05), l'espace de noms du gabarit (72-01) et `sessions.lancer(ligne, onglet)` (72-02) existent sous ces noms. Le message `proposition` est passé tel quel avec sa clé `t` : l'état de Q l'accepte (`formeOk` ne ferme pas les clés), aucun retrait de `t` n'a été nécessaire. Statuts : tableau `motif` -> statut du `72-05-SUMMARY.md` repris à l'identique ; `STATUT_LANCER` : premier-plan 409, absente 410, alphabet 400, invalide 400, delai 504.

## Ancres (texte réel)

Fichier `plugin/cockpit/scripts/vf-cockpit-terminal-processus.mjs` (198 lignes avant le correctif de contrôle, 199 après), une occurrence chacune :

- contrôle Origin (existante, NON touchée) : `    if (o === undefined) { if (!page && !navigateur) return { statut: 403, raison: 'Origin absente' }; } else if (o !== origineQ()) return { statut: 403, raison: 'Origin' };` (l. 93)
- onglet : `    if (onglet !== proprietaire) return 409;` (première instruction de `lancer()` après son test de session) ; `/annuler` : `      if (onglet !== proprietaire) return refus(res, 409);`
- identifiant : `    const idDemande = demande.id;`
- schéma fermé : `  if (!o || typeof o !== 'object' || Array.isArray(o) || !Object.keys(o).every((k) => cles.includes(k))) return null;` (dans `lireDemande(brut, cles, requises)`)
- source de la ligne : `    const ligneQ = r.ligne;`
- écriture : `    const w = await sessions.lancer(ligneQ, onglet);`
- réception : `  const recevoirCibles = (l) => lq.definirCibles(l);` · `  const recevoirProposition = (m) => lq.proposer(m);` · `  const lireProposition = () => lq.lire();`
- gabarit : `  const gabaritQ = gabarit;` puis `  const lq = creerEtatLancer({ gabarit: gabaritQ });` (avec `import * as gabarit from './vf-cockpit-lancer-gabarit.mjs';`)
- propriétaire : `  let proprietaire = null;` et, dans la branche `/flux`, `      if (r === 200) proprietaire = onglet;`
- écrivain : `  async function lancer(demande, onglet) {` (rend un statut entier ; seule fonction qui appelle `sessions.lancer`)
- contrôle des nouvelles routes : `    const c = controle(req, url.pathname === '/proposition' ? new URL('/etat', origineQ()) : url); if (c) return refus(res, c.statut, c.raison);`
