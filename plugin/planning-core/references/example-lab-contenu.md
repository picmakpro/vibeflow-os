# EXEMPLE — Socle `.planning/` adapté à un lab NON-DEV (contenu)

> Référence du skill `vf-planning`. **Preuve d'universalité** : le même tronc commun, instancié pour
> un lab éditorial (profil *standard*), avec une extension `editorial/` — **aucune forme dev**. Sert
> de modèle d'adaptation : le vocabulaire et l'extension épousent le métier.

Lab fictif : **« LigneClaire »** — production de contenu éditorial B2B (newsletter + LinkedIn).
Profil retenu : **standard** (travail découpé en campagnes, livrables à tracer, pas de code).

```
.planning/
  PROJECT.md
  STATE.md            ★ clé de voûte
  ROADMAP.md
  REQUIREMENTS.md
  MILESTONES.md
  config.json
  editorial/          ← extension de domaine (à la place de codebase/)
    LIGNE-EDITORIALE.md
    CALENDRIER.md
    AUDIENCE.md
  phases/
    01-campagne-lancement/01-01-PLAN.md + 01-01-SUMMARY.md
```

---

## PROJECT.md (extrait)

```markdown
# LigneClaire (LC)

## Ce que c'est
Studio éditorial qui produit une newsletter hebdo + 3 posts LinkedIn/sem pour des fondateurs B2B.

## Valeur cœur
Transformer l'expertise d'un fondateur en autorité éditoriale régulière, sans qu'il écrive lui-même.

## Décisions clés
| ID | Décision | Pourquoi | Statut | → Mémoire |
| D1 | Ton "expert accessible", pas corporate | Aligne avec l'audience founder | Validée | → ADR-002 |
```

## STATE.md (extrait — la clé de voûte, en vocabulaire métier)

```markdown
---
planning_version: 1.0
profile: standard
milestone: "campagne-lancement"
status: "en cours"
stopped_at: "Newsletter S1 publiée ; posts S1 en relecture"
last_updated: "2026-06-11"
progress: { total_steps: 4, completed_steps: 1, percent: 25 }
---
# État du projet — LigneClaire
**Focus courant :** finaliser les 3 posts LinkedIn de la semaine 1.
## Position courante
- Étape : 1 sur 4 — Campagne de lancement
- Dernière activité : 2026-06-11
## Todos
- [ ] Valider l'angle du post #3 (cas client)
```

## ROADMAP.md (extrait — "étapes" = campagnes, "critères de succès" = métier)

```markdown
### Étape 1 : Campagne de lancement
**But** : poser la présence éditoriale (1 newsletter + 3 posts).
**Exigences couvertes** : REQ-01 (ton), REQ-02 (cadence), REQ-03 (CTA)
**Critères de succès** (ce qui doit être VRAI) :
  1. Newsletter S1 envoyée, taux d'ouverture mesuré.
  2. 3 posts publiés, cohérents avec la ligne éditoriale.
```

## REQUIREMENTS.md (extrait — exigences exprimées dans le métier, pas en technique)

```markdown
### Ligne & cadence
- [x] REQ-01 : Chaque pièce respecte le ton "expert accessible" (cf. editorial/LIGNE-EDITORIALE.md).
- [ ] REQ-02 : Cadence tenue = 1 newsletter + 3 posts par semaine.
- [ ] REQ-03 : Chaque post se termine par un CTA unique et mesurable.
```

## editorial/ (l'extension — propre au métier, là où un lab dev aurait codebase/)

`LIGNE-EDITORIALE.md` (ton, piliers, formats), `CALENDRIER.md` (planning de publication),
`AUDIENCE.md` (ICP, douleurs, sujets). **Rien de tout ça n'est imposé** : ce sont les artefacts
naturels d'un studio éditorial. Un lab de vente aurait `pipeline/`, un lab de dossier `dossiers/`.

---

## Ce que cet exemple prouve

- Le **tronc commun** (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases) marche **tel quel** hors
  dev — il porte la *logique* de discipline, pas une forme de code.
- L'**adaptation** se joue dans le vocabulaire (« campagne » au lieu de « sprint », « pièce » au lieu
  de « commit ») et dans l'**extension de domaine** (`editorial/` au lieu de `codebase/`).
- `STATE.md` reste la clé de voûte, identique dans sa fonction : « où en est-on, là, maintenant ».
