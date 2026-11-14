# 80-13 — trace du rouge (P80-D-25), base 2736fe67 (tête de la branche avant ce plan)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lien-vue.sh` (7 PASS / 7 FAIL).

## Rouges (attendus)

- LV1.1 : obtenu `[true,true,false,true,true,false,false,false]` — le fragment `#v=…&s=…` n'a pas de `z` ; rouvert, la carte est recadrée
  (`k` 1.1 au lieu de 1.375).
- LV1.2 : obtenu `[true,false,true]` — `setHash` réécrit le fragment avec les seules clés `v` et `s`, aucun `z`.
- LV2.1 : obtenu `[false,true,false,false,false,false]` — ouvrir le tiroir Git n'écrit pas `git=1` ; le lien `#git=1` ne l'ouvre pas.
- LV2.2 : obtenu `["project",false,0,false,false,false,false]` — aucune clé `vf-tiroirs:` en `sessionStorage`, tiroirs fermés après rechargement.
- LV2.3 : obtenu `[false,false,false,false,true]` — la mémoire de session et le lien `git=1` n'ouvrent rien.
- LV2.4b : obtenu `[true,"ok",false,false,false,0]` — « Au travail » ne survit pas à `aller('projet')`.
- LV3.1b : témoin positif, `#z=1.5,10.5,20.25` n'est pas lu (le zoom reste celui du cadrage).

## Verts sur la base (écart au plan, dit sans détour)

- LV1.3 : `?vue=couloirs` survit déjà (P80-D-02).
- LV2.4 (tiroir Git d'un onglet à l'autre sans rechargement) : déjà vert, 80-10 rouvre le tiroir (`rouvrirGit`) ; ce plan garde la preuve.
- LV3.1 (liens forgés) : vert à vide sur la base, faute de lecture de `z` ; LV3.1b est le témoin qui le rend discriminant une fois `z` lu.
- LV3.2 (Précédent, `#r=`) : non-régression, vert avant et après.

Mutants M-ZHORS, M-EFFACE, M-FOCUS-TIROIR : levés (régime allégé, consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
