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
