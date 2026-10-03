---
juge: "[auditeur indépendant — jamais l'auteur du livrable]"
hash: "[sha256 de l'artefact jugé]"
hash_livrables: ""
tentative: 1
score: ""
constats:
  - critere: "[critère éliminatoire objectivement vérifiable]"
    resultat: "[passé | échec]"
---

# Verdict

> Une couche d'audit = un **constat par dimension** (voir le skill `audit-architecture`) : le
> `juge` n'est **jamais** l'auteur du livrable ; seuls les critères objectivement vérifiables
> (`constats`) bloquent — le `score` est affiché et **non bloquant** (spec D-02 amendée). Un
> `constat` en `échec` dérive `à corriger` ; `constats` tous `passé` (avec `SUMMARY.md`) dérive
> `close` (voir `references/modele-cycles.md` § Règles de dérivation).

Le fichier ne s'écrit pas à la main : la commande `poser-verdict.sh` le pose. Elle calcule les
**deux empreintes**, jamais l'agent : `hash` (sha256 des octets du `PLAN.md` de l'unité) et
`hash_livrables` (empreinte composée des entrées `ecrit:` du `PLAN.md` : fichiers et dossiers, aucun
lien suivi, parcours borné). Elle refuse de poser un verdict quand un livrable déclaré est absent,
vide ou un lien. Un verdict dont l'une des deux empreintes ne correspond plus au plan ou aux
livrables est **périmé** : il se refait (voir `references/modele-cycles.md` § `VERDICT.md`).

`tentative` compte les allers-retours créateur↔juge (anti-boucle) : la commande la vérifie (1 à la
création, ancienne + 1 pour un remplacement) et refuse une quatrième tentative sans dérogation
nominative.

Tant que `resultat: "[passé | échec]"` n'est pas remplacé par une valeur réelle, ce fichier dérive
`indéterminé` (`verdict-invalide`) — jamais un faux `close`.
