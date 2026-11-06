# 72-CORRECTIFS-D — reprise du chat : geste humain exigé (F-1) et motif d'UUID strict (S3)

Mandat du manager (2026-11-06). Décision : P72-D-21 (72-CONTEXT.md). Périmètre : `vf-cockpit-lancer-ui.mjs`, `test-cockpit-lancer-chat.sh`, `test-cockpit-lancer-xss.sh`, `temoins/lancer-xss.mjs`. Aucun plafond relevé (lancer-ui : 199 lignes).

## F-1 — l'UUID n'est retenu que pour une requête émise pendant une activation utilisateur réelle
- Code : `installerObservateurChat` lit `navigator.userActivation.isActive` AU MOMENT de l'appel (ligne `garde:activation`, avant l'appel natif), jamais à la réponse. Les accesseurs natifs (`Navigator.prototype.userActivation`, `UserActivation.prototype.isActive`) sont saisis à l'installation : une propriété d'instance posée ensuite par une charge ne les masque pas. Sans activation : la requête part, sa réponse est rendue intacte, rien n'est lu ni retenu.
- Pourquoi c'est infalsifiable par un script : l'activation transitoire n'est posée que par une entrée réelle (souris, clavier, toucher) ; aucun appel de script (`click()`, `dispatchEvent`, `fetch`, `Runtime.evaluate` sans geste) ne la pose. Mesuré : ACT.0 (avant geste : faux), ACT.1 (la charge, même par `click()` programmatique : rien).
- Limites : (1) le résiduel accepté par Samuel : pendant la fenêtre d'activation que laisse un geste réel (quelques secondes, tout clic ou touche de la page), une requête de la charge est retenue (mesuré en ACT, ligne ℹ). (2) Une charge qui s'exécute AVANT l'installation peut remplacer les accesseurs natifs saisis ou la fonction de requête elle-même ; hors hypothèse de la suite (la charge s'exécute après le script d'interface). (3) Un script de P peut aussi POSTER directement `/api/vf/lancer` avec `chat:<uuid de sa conversation>` et le jeton de la page, sans passer par la mémoire de la page : la route de P (vf-cockpit-lancer.mjs, l.77-81) ne vérifie que la FORME de l'UUID. Mesuré par TC.7 (le corps porte `chat` fourni par l'appelant, 202, case dans le bandeau). Cette garde client ne ferme donc que le chemin par l'interface ; voir finding `ask-user` du rapport.
- Échec fermé : API absente, `navigator` absent, `isActive` non booléen vrai : rien n'est retenu (TC.2).
- Une requête sans activation n'efface ni ne remplace un UUID déjà retenu par un geste humain. Choix : ne rien toucher. Effacer donnerait à la charge un levier pour détruire la reprise légitime de l'humain (déni), sans gain de sécurité (l'UUID retenu venait d'un geste réel). Testé : TC.2 (retenus restent `[U]`) et ACT.3 (inchangé après expiration).

### Témoins
- TC.2 (suite chat, fenêtre factice) : cas ajoutés : `isActive` faux, API absente, `navigator` sans `userActivation`, `isActive` truthy non booléen (rien) ; active à l'appel puis éteinte à la réponse (retenu) ; éteinte à l'appel puis active à la réponse (rien) ; requête sans activation après un geste (UUID conservé). Les cas existants jouent avec `isActive: true` : leurs déclencheurs sont inchangés, seule la fenêtre factice porte une activation (aucun attendu affaibli). TC.7 (e2e) pose `chat` dans le corps du POST de P, il ne dépend pas de l'observateur : inchangé.
- ACT.0 à ACT.3 (suite XSS, Chrome réel) : page hôte jetable (`hote.mjs`, écrit par la suite) qui installe l'observateur de la SORTIE sur la vraie fenêtre ; FAUX `/api/ask` (le vrai exige `claude`), SSE, un UUID neuf par requête. Charge sans geste : 0 retenu (ACT.1). Témoin positif : VRAI clic `Input.dispatchMouseEvent` : 1 retenu, activation active (ACT.2). Après expiration : inchangé (ACT.3).
- ROUGE avant (code de HEAD acb032e1, harnais TC.2 rejoué dessus) : 6 échecs (activation absente, API absente, navigator sans userActivation, truthy, éteinte à l'appel, UUID remplacé par une requête sans activation).
- VERT après : TC.2 `ok`.
- Mutant M-ACTIVATION-RETIREE (`const humain = actif();` -> `const humain = true;`) : rougit TC.2 (suite chat) et ACT.1 (suite XSS : `true/true`, la charge fait retenir l'UUID de sa conversation).

## S3 — motif d'UUID strict, minuscule
- Défaut : la page retenait `/^[0-9a-f-]{36}$/i` (deux sites : extracteur et constructeur de corps). Un 36 caractères non-UUID était retenu puis refusé en 422 `chat-invalide` à chaque lancement jusqu'au rechargement ; un UUID majuscule rendait 202 puis aucun bandeau (le gabarit n'accepte que les minuscules).
- Code : motif strict `8-4-4-4-12` hexadécimal minuscule aux deux sites. Un identifiant rejeté n'est jamais retenu : le dernier valide reste, et `corpsProposition` retombe sur `{ cible, verbe }` (les lancements suivants partent).
- Changement de contrat de test voulu, pas un affaiblissement : TC.1 attendait « UUID majuscule retenu » ; il attend maintenant `null`. Le mutant M-CHAT-NON-VALIDE-UI cible le nouveau motif.
- ROUGE avant (HEAD) : TC.1 (majuscule, 36 non-UUID, rejeté après valide) et TC.3 (identifiants forgés) en ECHECS.
- VERT après : TC.1 `ok`, TC.3 `ok`.
- Mutant M-MOTIF-LACHE (ancien motif remis, avec `i`) : rougit TC.1 ET TC.3 (`rouge/rouge`).

## Preuves de la livraison
Voir le rapport typé (commandes, codes de sortie, SHA).

## Résiduel accepté P72-D-22 — manche RES (caractérisation, jamais une protection)

Décision : P72-D-22 (72-CONTEXT.md), qui remplace P72-D-21 comme arbitrage sur le résiduel (limite 3 ci-dessus). Suite : `test-cockpit-lancer-xss.sh`, manche RES ; pilote : mode `residuel` de `temoins/lancer-xss.mjs` ; faux `claude -p` du chat : `temoins/lancer-fauxbin/claude-ask` (posé dans le PATH du SERVEUR seulement : la vraie route `/api/ask`, aucun faux serveur ; le shell du terminal garde `lancer-fauxbin/claude`).
- Ce que la manche exécute : Chrome réel, tiroir ouvert par le clavier, activation expirée (mesurée : `false` avant et pendant), puis un script de la page Projet pose sa question (200), lit l'UUID de la réponse, POSTe `/api/vf/lancer {cible, verbe, chat}` avec le jeton de la page : 202 ; la case « Continuer la conversation du chat » apparaît dans Q, DÉCOCHÉE.
- Mesure à connaître : la ligne affichée avec la case décochée ne porte PAS l'identifiant (ni `-r`, ni `--fork-session`) ; il apparaît une fois la case cochée (RES.2b, cochée par script dans Q seulement, rien n'est envoyé). Le README doit donc dire « l'identifiant est affiché quand la case est cochée », non « toujours affiché ».
- Barrière réelle : aucun octet au shell (terminal de Q lu, invite lue en témoin), aucun argv du faux claude du shell, tant qu'il n'y a ni clic ni Entrée dans Q.

### Mutants (chacun posé sur une copie de la sortie construite, « sans effet » = FAIL nommé)
| Mutant | Sonde | Résultat mesuré |
|---|---|---|
| M-CASE-COCHEE (`caseChat.checked = true` dans la vue de Q) | RES.1 case décochée | ROUGE : `coche:true`, ligne avec `-r '<uuid>' --fork-session` |
| M-SANS-CONFIRM (Q confirme seul) | RES.3 aucun octet | ROUGE : le terminal montre `claude --session-id` ; l'argv reste absent (sonde d'argv séparée, verte, faute d'Entrée) |
| M-SANS-CONFIRM + M-ENTREE-AUTO (retour chariot ajouté) | RES.4 aucun argv | ROUGE : argv présent sans clic ni Entrée dans Q |

Sonde RES.4 et assertions de mutants : chacune exige aussi la charge faite (`false/false/200/<uuid>/202`), pour qu'une absence ne soit jamais une absence de tentative.

### Preuves
- Rejeu complet de `test-cockpit-lancer-xss.sh` sur export `git archive` de HEAD 86d6a4b9 (fichiers du plan 72-16 non commités dans l'arbre) : `76 PASS / 0 FAIL`, code de sortie 0.
- `bash scripts/check-machine-paths.sh` : ✓.

## Correction ciblée F (suite XSS rouge depuis 72-16, contrat `ecriture`, docstring du PTY)

- Suite XSS : 72-16 a retiré la constante `CLE_MODE` du client de Q ; la suite relevait cette clé et rendait « clé du mode introuvable » (75 PASS / 1 FAIL). Le littéral `vf.terminal.mode` n'étant plus lu ni écrit par Q, une sonde sur cette seule clé testerait une clé morte (elle resterait verte même si P lisait le stockage de Q). La charge sonde maintenant `CLE_SECRET` (`vf.terminal.secret`), clé VIVANTE de `localStorage` de Q et la plus sensible, relevée dans le client par la même méthode. Variable renommée `CLE_STOCK`, constante de la charge `__CLE_STOCK__`. Le mode n'est plus dans le stockage : il n'y a rien d'autre à sonder de ce côté.
- Mutant (posé sur `temoins/lancer-charge.js`, puis restauré) : le cadre de Q devient `f.srcdoc` (même origine que P). ROUGE : C1l.4a `obtenu [lisible/inscrit/lisible]` au lieu de `SecurityError/SecurityError/lisible`, et C1l.4b ; 74 PASS / 2 FAIL. Un premier mutant (`f.src` vers l'origine de P) restait vert : la page P refuse le cadrage, le mutant n'en était pas un.
- Contrat : motif `ecriture` ajouté à `72-CONTRATS.md` §4 (HTTP 410, proposition restituée) et §5 (réponse `LANCE ecriture`, motifs de `sessions.lancer`).
- `vf-cockpit-pty.py` : commentaires seulement. `ok` = ligne mise en file, écriture tentée ; sur `BlockingIOError` la ligne reste en file et la réponse est `ok` ; `ecriture` ajouté à la liste des réponses.
- Preuves : `test-cockpit-lancer-xss.sh` 76 PASS / 0 FAIL (rc 0) ; `test-cockpit-lancer-pty.sh` 63 PASS / 0 FAIL (rc 0).
