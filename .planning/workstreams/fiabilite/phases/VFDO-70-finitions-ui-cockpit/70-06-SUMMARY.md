---
phase: 70-finitions-ui-cockpit
plan: 06
requirements: [UIFN-08, UIFN-06]
estimate:
  tokens: 55000
  tasks: 2
---
# 70-06 — « Où en est-on ? » sans STATE, statuts lisibles

## Fait
- Tâche 1 : Q15 à Q17 jouées rouges (57 PASS / 8 FAIL), trace dans `70-06-RED-TRACE.md`.
- Tâche 2 : `STATUTS` et `statutLisible` exportés par `vf-cockpit-project.mjs` (12 valeurs de `status:` relevées dans gsd-core) ; sous-titre sans statut brut ; `vf-cockpit-ask.mjs` importe `statutLisible` et assemble la réponse des seuls champs présents ; `STATUT` de `00-vibeflow.js` aligné sur les mêmes clés, `statut()` rend vide pour l'inconnu (badge « Maintenant » omis).

## Réponse sur le lab sans STATE.md
Avant :
```
Jalon en cours : non reconnu. Dernière phase :  · , le ?.

À finir dans le jalon :
```
Après :
```
Pas de STATE.md dans ce lab : le jalon et la phase courants ne sont pas suivis.

Phases à finir (d'après le ROADMAP) :
- [[n:ph-2]] · à faire · pas de plan
```

## Vérification (exit 0)
questions 65/0, projet 56/0, chrome-fr 59/0 (F12.2 vert, F12 non sautée), avancement 61/0.

## Écarts
- `test-cockpit-responsive.sh` non lancé (consigne du manager) : à rejouer à l'intégration.
- Le `<verify>` de la tâche 1 filtre `Q1[234]` : coquille du plan (les témoins sont Q15 à Q17) ; contrôle fait à la main (seuls Q15, Q16, Q17 rouges).
- Q15.3 corrigée en insensible à la casse (« Pas de STATE.md » en début de phrase), après son rouge établi.
