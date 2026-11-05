# 78-09 — traces rouge / vert (GITC-11, P78-D-15, P78-D-23)

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-signature.sh`

## Tâche 1 — témoin rouge du signal Git (avant tout code de production)

Tête : sans `vf-cockpit-git-signature.mjs`, `vf-cockpit-live.mjs` inchangé.

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| R1.0 témoin : serveur, jeton, git emballé | oui | oui (PASS) |
| R1.0b témoin : le client reçoit le `hello` | 1 | 1 (PASS) |
| R1.1 11 s sans changement : 0 événement git | 0 | 0 (PASS, non vacuité garantie par R1.0b) |
| R1.2a un commit : au moins un événement git | oui | non (FAIL) |
| R1.2b charge `at,seq,sig` + sig de 16 hexadécimaux | at,seq,sig\|true | null (FAIL) |
| R1.2c événement en moins de 8 s | oui | non (FAIL) |

Résultat : 4 PASS / 3 FAIL. Rouge sur R1.2, comme annoncé par le plan.
Défaut trouvé au premier jeu : R1.2c passait à vide (aucun événement : latence négative < 8000). Garde ajoutée (événement présent ET latence >= 0).
