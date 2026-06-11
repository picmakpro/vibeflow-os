# EXTENSION-SPEC — `editorial/` (extension de domaine du lab content)

> Structure **exacte** de l'extension de domaine à scaffolder par `vf-new-lab` lors de l'instanciation
> du bundle ContentFlow. Cette extension prend, dans `.planning/`, la place qu'aurait `codebase/` dans
> un lab dev — **le métier n'est pas le code**, donc pas de `codebase/`.
>
> Source du pattern : `planning-core` (`PROFILES.md`, `example-lab-contenu.md`). Profil **standard**.

---

## Emplacement

```
.planning/
  PROJECT.md
  STATE.md            ★ clé de voûte
  ROADMAP.md
  REQUIREMENTS.md
  MILESTONES.md
  config.json
  editorial/          ← CETTE extension (à la place de codebase/)
    LIGNE-EDITORIALE.md
    CALENDRIER.md
    AUDIENCE.md
    FORMATS.md
    PILIERS.md
  phases/
    NN-<campagne>/NN-NN-PLAN.md + NN-NN-SUMMARY.md
```

L'extension `editorial/` est posée **sous `.planning/`**, aux côtés du tronc commun planning. Elle
porte le savoir éditorial **stable** du studio (référentiel), là où `.planning/` porte l'avancement.

---

## Fichiers (rôle de chacun)

### `LIGNE-EDITORIALE.md` — la constitution éditoriale
Source de vérité du **ton / voix / piliers / do-don't** et des **règles de sourcing**. C'est le fichier
que le `strategist` et le `scriptwriter` consultent avant chaque pièce.

Doit contenir au minimum :
- **Ton & voix** : registre, personnalité, ce qu'on est / ce qu'on n'est pas.
- **Piliers** : pointeur vers `PILIERS.md` (détail) + rappel des thèmes porteurs.
- **Do / Don't** : règles d'écriture positives et interdits (ex. « une idée par phrase », « pas de
  superlatif gratuit », « ton non-alarmiste »).
- **Règles de sourcing** :
  - **sources-autorisées** : liste explicite des sources **tier-1** citables.
  - **sources-interdites** : liste des sources bannies.
  - règle : **toute citation chiffrée → source primaire** ; aucune affirmation chiffrée non sourcée.

### `CALENDRIER.md` — le planning de publication
Tenu par le `repurposer`. Porte la **cadence** (rythme de publication) et l'état de chaque pièce/variante.

Colonnes recommandées : `Date · Pièce · Plateforme · Format · Statut · CTA · Campagne`.
Statuts : `idée → cadré → rédigé → gate clarté → validé humain → planifié → publié`.

### `AUDIENCE.md` — la cible
Référentiel de l'**ICP** (profil de l'audience), de ses **douleurs** et de son **état émotionnel**.
C'est contre ce fichier que le `strategist` **justifie chaque angle** (« pourquoi ça résonne »).

Doit contenir : ICP (qui), douleurs/problèmes, désirs, état émotionnel dominant, objections, niveau
de connaissance (pour calibrer le jargon à expliquer).

### `FORMATS.md` — les gabarits par format
Bibliothèque des **gabarits** que le `scriptwriter` et le `repurposer` appliquent. Un gabarit par
format pris en charge, avec contraintes :
- **vidéo 60-90s** : structure de script, repères de durée.
- **thread 6-10** : 6 à 10 tweets, 1 idée par tweet.
- **LinkedIn 1200-1500c** : 1200-1500 caractères.
- **carrousel 7-10 slides** : 7 à 10 slides, **1 idée par slide**.
Chaque gabarit rappelle l'ossature commune : **hook ▸ contexte ▸ mécanisme ▸ implication ▸ CTA**.

### `PILIERS.md` — les thèmes porteurs
Liste des **piliers** éditoriaux (thèmes récurrents qui structurent la production) avec, pour chacun :
intitulé, promesse, exemples d'angles. Le `strategist` rattache chaque pièce à un pilier ; sert à
tenir la cohérence de la ligne et à équilibrer la production sur la durée.

---

## Règles de scaffolding (pour `vf-new-lab`)

- Poser les **5 fichiers** ci-dessus, même vides, avec leurs en-têtes de rôle (le studio les remplit).
- **Ne rien imposer du contenu** : ce sont les artefacts naturels d'un studio éditorial ; le lab les
  garnit avec son vrai ton, sa vraie audience, ses vrais piliers (P7 — vocabulaire métier natif).
- L'extension est **référentiel stable** : elle ne duplique pas l'avancement (qui vit dans
  `STATE.md`/`ROADMAP.md`) ni la mémoire (qui vit dans les registres). Pont : voir `registres.md`.
- Les **règles de sourcing** de `LIGNE-EDITORIALE.md` alimentent directement le **gate de clarté**
  (`audit-architecture`) — c'est là que sont définies les sources autorisées que le gate vérifie.
