---
juge: "[auditeur indépendant — jamais l'auteur du livrable]"
hash: "[sha256 de l'artefact jugé]"
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

`tentative` compte les allers-retours créateur↔juge (anti-boucle). En Phase 44, `hash` et
`tentative` sont **lus et restitués, jamais vérifiés** — leur vérification (hash contre l'artefact
effectivement produit) relève de la Phase 46.

Tant que `resultat: "[passé | échec]"` n'est pas remplacé par une valeur réelle, ce fichier dérive
`indéterminé` (`verdict-invalide`) — jamais un faux `close`.
