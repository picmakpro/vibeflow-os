---
name: replace-prescription-keep-its-mitigation
description: Quand un lot remplace une prescription (ex. heartbeat dans la boucle d'attente), verifier ce qu'elle mitigeait en cote (TTL du lock) ; lot B / #81, dev-orchestrator v2.28.5
metadata:
  type: feedback
---

Retirer « heartbeat a chaque iteration d'une boucle d'attente » (mission-flow.md, D-33-E) au profit de
« heartbeat a chaque reveil du manager » supprime le seul battement pendant l'attente d'un worker :
TTL 1800 s (driver-lock.sh:103) < mandat de worker courant, et poll canonique `deadline` = 1800 s sans
heartbeat. Le message de commit affirmait « motif D-33-E conserve » : faux, a recouper.

**Why:** le defaut (lock perime en pleine mission) est deja connu ([[driver-lock-ttl-trop-court]] cote memoire
principale) ; la boucle fautive de #81 etait aussi la seule chose qui le masquait.

**How to apply:** sur toute revue qui supprime une prescription, chercher quel risque elle couvrait
(grep des constantes TTL/STALL_WINDOW dans check-guard-health.sh) avant de valider le retrait. Un scanner
lexical de doctrine (T81) : muter la clause cle (ici `sleep 15 || exit 125`) et verifier qu'il rougit ;
il ne rougit pas (clause non testee, `echo TIMEOUT` suffit comme borne).
