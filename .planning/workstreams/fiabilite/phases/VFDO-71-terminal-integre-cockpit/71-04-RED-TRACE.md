# 71-04 — trace du rouge de la session du terminal

- date : 2026-11-03
- empreinte du commit de tests : `fa74371e` (`test(71-04): témoins rouges de la session du terminal …`)
- base : HEAD `03518b44` + les commits des voisins de la vague 2 ; `vf-cockpit-terminal-session.mjs` tel que livré par 71-01 (propriétaire d'onglet et lecture de `FIN`/`SIG` déjà présents ; ni grâce, ni tampon, ni échéance)
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh > 71-04-t1.out 2>&1` — rc=1, `Résultats : 22 PASS / 7 FAIL`, 65 s

## Témoins rouges (7)

### FAIL — T12.2 — A revient après 1 s : même shell, /etat vivante, le marqueur tapé avant la fermeture est rejoué
- attendu : `[memeshell=oui etat=vivante rejeu=TROUVE]`
- obtenu : `[memeshell=oui etat=vivante rejeu=ABSENT]`
- raison : la session survit (aucune échéance), mais aucun tampon : la sortie est perdue sans flux attaché.

### FAIL — T12.3 — grâce + 2 s : assistant et shell disparus (attente bornée), /etat = absente
- attendu : `[morts / absente]`
- obtenu : `[survivants / detachee]`
- raison : une session détachée n'a pas d'échéance.

### FAIL — T12.3 — un nouveau flux crée un nouveau shell (PID différent)
- attendu : `[oui]`
- obtenu : `[non (ancien=96349 nouveau=96349)]`

### FAIL — T12.7 — témoin : la production a eu lieu pendant le détachement et le rejeu atteint le plafond (≥ 262144 octets)
- attendu : `[TROUVE plein]`
- obtenu : `[TROUVE court:16]`
- raison : le rejeu ne contient que les 16 octets écrits après le rattachement.

### FAIL — T12.7 — la fin de la production est présente dans le rejeu
- attendu : `[TROUVE]`
- obtenu : `[ABSENT]`

### FAIL — M-GRACE0 — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`
- raison : `GRACE_MS` n'existe pas encore dans le module de 71-01.

### FAIL — M-TAMPON — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`
- raison : la fonction `vider` n'existe pas encore.

## Verts sur la base, avec leur preuve par mutant (écart au plan)

Le plan annonçait T12.1, T12.8 et T15.2 rouges sur la base. Mesuré : ils sont VERTS, parce que 71-01 livrait déjà le propriétaire d'onglet
(409 sur `/flux`, `/entree`, `/taille`) et la lecture de `FIN <code>` (état `terminee` et code). Ils ne sont donc pas des témoins rouges de ce
plan ; leur capacité à rougir est établie par les mutants, joués sur la base :

- T12.1 — vert (`B=409 assistants=1 A=TROUVE`) ; M-UNIQUE le rougit : PASS « le mutant rougit T12.1 ».
- T12.6 — vert ; M-PROPRIO le rougit : PASS « le fichier de B est créé ».
- T12.8 — vert (`{"session":"terminee","code":3,"signal":null}`, 410 sans session).
- T15.1 — vert, témoin positif présent (`temoin=oui export=200 sse=STATUT 200 fuites=0`) ; M-JOURNAL le rougit : PASS.
- T15.2 — vert sur la base parce que la base n'a aucun tampon ; M-TAMPON (cible absente) ne peut rougir qu'après la tâche 2.
- T12.5 — vert sur la base (`occupe()` existait) ; M-IDLE le rougit : le serveur du mutant sort, celui du code reste vivant.
