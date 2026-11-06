# 72-05 — trace du rouge

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-q.sh` (sur la base : le module `vf-cockpit-lancer-q.mjs` n'existe pas).
HEAD joué : `0f550702` (suite ajoutée par ce commit ; module absent). Résumé : `Résultats : 1 PASS / 68 FAIL`, rc=1 (sous bash et sous zsh).
Le seul PASS est l'hygiène (H0). Le harnais imprime `{"absent":true}` quand l'import échoue : toutes les sondes obtiennent `ABSENT` (LQ6 : `ABSENT`, LQ7.3 : rc 127 du contrôle de taille sur un fichier absent). Le rouge vient donc bien de l'absence du module, pas d'une fixture morte : le harnais est le même que celui qui rend le vert sur le code livré.

## LQ1 liste fermée
- sonde : LQ1.1 à LQ1.7c
- attendu : liste-absente|{"etat":"aucune"} ; false/liste-absente x5 ; true,1,7|ok|absente x7 ; absente,absente|aucune|0 ; absente x3 ; true,true ; aucune / absente / ok
- obtenu : `ABSENT` (sondes) — rouge

## LQ2 composition
- sonde : LQ2.1a à LQ2.6b
- attendu : appels=1 puis 2, onze clés exactes, compose x6, compose x9, forme x11, ok
- obtenu : `ABSENT` (sondes) — rouge

## LQ3 remplacement, armement
- sonde : LQ3.1 à LQ3.5
- attendu : nouveau=true;ancien=remplacee ; avant/apres/limite=pas-arme;arme=ok ; pas-arme,ok ; arme/e0/e1=true ; ok
- obtenu : `ABSENT` (sondes) — rouge

## LQ4 expiration
- sonde : LQ4.1, LQ4.2
- attendu : aucune|expiree|expiree|restauree=false|aucune ; ok
- obtenu : `ABSENT` (sondes) — rouge

## LQ5 consommation
- sonde : LQ5.1 à LQ5.9d
- attendu : ok;ligne=true... ; lancee ; consommee ; rejeu=consommee;seconde=occupee ; restauree=true... ; mode x5 ; bloquee ; chat x6 ; chat
- obtenu : `ABSENT` (sondes) — rouge

## LQ6 constantes
- sonde : LQ6.1 à LQ6.3
- attendu : 1000,120000 ; 250,120000 ; 1000,5000 ; défauts x10
- obtenu : `ABSENT` (sondes) — rouge

## LQ7 pureté
- sonde : LQ7.1 à LQ7.3
- attendu : imports=node:crypto;dyn=0 ; console=0;exit=0;io=0;env=...;alphabet=0;prefixe=0;noms=0 ; rc 0
- obtenu : `ABSENT` (sondes) — rouge

## Mutants sur la base

Les dix-neuf mutants sont rouges en « mutant sans effet (cible absente ou inchangée) » (19 lignes comptées) :

- M-LISTE-OUVERTE (doit rougir LQ1.4, LQ1.5) : sans effet : module absent
- M-LISTE-PERIMEE (doit rougir LQ1.7b) : sans effet : module absent
- M-LISTE-LIRE (doit rougir LQ1.7a) : sans effet : module absent
- M-ENTREE-NON-VALIDEE (doit rougir LQ1.3) : sans effet : module absent
- M-FORME-LIBRE (doit rougir LQ2.6a) : sans effet : module absent
- M-COMPOSE-IGNOREE (doit rougir LQ2.3) : sans effet : module absent
- M-LIGNE-NON-VALIDEE (doit rougir LQ2.4a) : sans effet : module absent
- M-SANS-CONFIRM-STATE (doit rougir LQ3.2) : sans effet : module absent
- M-ARME-DEPUIS-CREATION (doit rougir LQ3.3) : sans effet : module absent
- M-REJEU (doit rougir LQ5.3) : sans effet : module absent
- M-EXPIRE-IGNOREE (doit rougir LQ4.1) : sans effet : module absent
- M-MODE-LIBRE (doit rougir LQ5.7) : sans effet : module absent
- M-REMPLACE-PAS (doit rougir LQ3.1) : sans effet : module absent
- M-RESERVATION-MULTIPLE (doit rougir LQ5.4) : sans effet : module absent
- M-RENDRE-PERD (doit rougir LQ5.5a, LQ5.5b) : sans effet : module absent
- M-ENV-SANS-BORNE (doit rougir LQ6.3) : sans effet : module absent
- M-CHAT-TYPE-LIBRE (doit rougir LQ5.9c) : sans effet : module absent
- M-CHAT-SANS-LIGNES (doit rougir LQ5.9d) : sans effet : module absent
- M-CHAT-LIGNE-FAUSSE (doit rougir LQ5.9a) : sans effet : module absent
## Correction du témoin LQ7.3 (rouge pour une mauvaise raison, corrigé)

Le rouge de LQ7.3 plus haut (`rc 127`) venait d'un chemin faux vers `check-file-size.sh` (un `../` de trop dans la suite), pas de l'absence du module ; de plus `check-file-size.sh` rend exit 0 sur un fichier ABSENT (mesuré : `bash plugin/software-architecture/scripts/check-file-size.sh /nonexistent.mjs` -> rc 0), donc, le chemin corrigé, la sonde serait devenue verte à vide sans module. Commit `84c24e50` : la suite constate d'abord l'existence du module (`TREC=absent` si le fichier manque, obtenu `absent` contre l'attendu `0`), puis le code retour du contrôle de taille. Le motif des noms de compartiment est assemblé à l'exécution (la suite ne porte pas elle-même ces noms). Sonde LQ7 jouée sur un mutant (commentaire ajouté portant `console.`, `process.env[`, le littéral d'alphabet, le préfixe de ligne et un nom de compartiment) : `console=1`, `env=...+dyn`, `alphabet=1`, `prefixe=1`, `noms=1` : elle sait rougir.

## Mutants rejoués sur le code livré

Code livré : `9b37b072`. Suite : `Résultats : 69 PASS / 0 FAIL` (bash et zsh), aucun « mutant sans effet ». Chaque ligne : mutant / sonde rougie / obtenu (l'attendu sain est celui de `attendu()` dans la suite).

- M-LISTE-OUVERTE (`garde:liste-proposer` supprimée) / LQ1.4 : obtenu `compose,compose|{"etat":"aucune"}|2` (attendu `absente,absente|...|0` : le gabarit est appelé 2 fois pour des cibles hors liste) ; LQ1.5 : `compose,ok,ok` (attendu `absente,absente,absente`). TUÉ.
- M-LISTE-PERIMEE (`garde:liste-consommer`) / LQ1.7b : `ok` (attendu `absente`). TUÉ.
- M-LISTE-LIRE (`garde:liste-lire`) / LQ1.7a : `{"etat":"en-attente",...}` (attendu `{"etat":"aucune"}`). TUÉ.
- M-ENTREE-NON-VALIDEE (`garde:entree-forme`) / LQ1.3 : `true,8,0|ok|ok,ok,ok,ok,absente,ok,ok` (attendu `true,1,7|ok|absente x7`). TUÉ.
- M-FORME-LIBRE (`garde:forme`) / LQ2.6a : `ok,ok,ok,compose,compose,ok,ok,ok,ok,absente,ok` (attendu `forme` x11). TUÉ.
- M-COMPOSE-IGNOREE (`garde:compose`) / LQ2.3 : `ok/!exc:...` x6 (attendu `compose/{"etat":"aucune"}` x6 : la proposition est acceptée sans lignes). TUÉ.
- M-LIGNE-NON-VALIDEE (`garde:alphabet`) / LQ2.4a : `ok,ok,ok,ok,ok,ok,ok,ok,compose` (attendu `compose` x9 : seule la ligne non chaîne reste refusée, par `garde:compose`). TUÉ.
- M-SANS-CONFIRM-STATE (`garde:arme`) / LQ3.2 : `avant=ok;apres=consommee;limite=consommee;arme=consommee` (attendu `avant=pas-arme;...;arme=ok`). TUÉ.
- M-ARME-DEPUIS-CREATION (`vue_a: null` -> `vue_a: maintenant()`) / LQ3.3 : `ok,consommee` (attendu `pas-arme,ok`). TUÉ.
- M-REJEU (`garde:usage-unique`) / LQ5.3 : `ok;confirmerDeNouveau={"t":"lancee",...}` (attendu `consommee;confirmerDeNouveau=null`). TUÉ.
- M-EXPIRE-IGNOREE (les deux lignes `garde:expire`) / LQ4.1 : `{"etat":"en-attente",...}|...` (attendu `{"etat":"aucune"}|expiree|expiree|...`). TUÉ.
- M-MODE-LIBRE (`garde:mode`) / LQ5.7 : `invalides=ok,consommee,consommee,consommee,consommee;puis=consommee;...` (attendu `mode` x5 puis `puis=ok`). TUÉ.
- M-REMPLACE-PAS (`attente = nouvelle;` -> `if (!attente) attente = nouvelle;`) / LQ3.1 : `nouveau=false;ancien=pas-arme` (attendu `nouveau=true;ancien=remplacee`). TUÉ.
- M-RESERVATION-MULTIPLE (`garde:occupee`) / LQ5.4 : `rejeu=consommee;seconde=ok` (attendu `seconde=occupee`). TUÉ.
- M-RENDRE-PERD (`garde:rendre`) / LQ5.5a : `restauree=false;memeId=false;memeSession=false;ligne=false;reconsommable=remplacee` ; LQ5.5b : `false;{"etat":"aucune"};remplacee` (attendu `...;annulee`). TUÉ.
- M-ENV-SANS-BORNE (`n >= min && n <= max` -> `true`) / LQ6.3 : avec `VF_COCKPIT_LANCER_ARME_MS=0` obtenu `0,120000` (attendu `1000,120000`). TUÉ.
- M-CHAT-TYPE-LIBRE (`garde:chat-type`) / LQ5.9c : `ok,consommee,consommee,consommee,consommee,consommee|puis=consommee` (attendu `chat` x6 puis `puis=ok`). TUÉ.
- M-CHAT-SANS-LIGNES (`garde:chat-absent`) / LQ5.9d : `ok|puis=consommee` (attendu `chat|puis=ok`). TUÉ.
- M-CHAT-LIGNE-FAUSSE (`chat === true ?` -> `attente.lignes_chat ?`) / LQ5.9a : `x=avec;y=avec` (attendu `x=sans;y=sans`). TUÉ.
