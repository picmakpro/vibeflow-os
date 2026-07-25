---
name: vf-content
description: >
  Utiliser quand l'intention est de produire ou décliner du contenu éditorial —
  « écris un post », « rédige la newsletter », « fais-moi un thread sur… », « décline cet
  article », « adapte cette pièce pour LinkedIn », « cadre l'angle de… », « prépare le
  calendrier de la semaine », « produis les pièces de la semaine », « lance la prod en
  autonomie ». Point d'entrée du métier content de VibeFlow : route un geste simple
  (une pièce → chaîne courte cadrage → rédaction → gate de clarté → validation humaine)
  ou une mission (≥ 3 pièces ou signal de durée → équipe via vf-content-manager).
  La validation humaine avant toute distribution est non négociable, quel que soit le mode.
  ✘ pas pour poser/structurer le planning du lab → vf-planning · ✘ pas pour configurer le
  lab ou installer des modules → vibeflow-conductor · ✘ pas pour de la copy marketing de
  page web (landing, pricing) → skills copywriting dédiés.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-content — Point d'entrée du métier content

Chaîne éditoriale : **brief → cadrage → rédaction → gate de clarté → validation humaine →
déclinaison/distribution**. Équipe : `vf-content-strategist` (angle), `vf-content-writer`
(livrable), `content-clarity-judge` (juge frais read-only, rubric /100),
`vf-content-repurposer` (variantes + calendrier), `vf-content-manager` (mission).

## Étape 0 — Garde first-use

Si le référentiel `editorial/` du lab est absent (`.planning/editorial/LIGNE-EDITORIALE.md`
introuvable) : propose d'abord de poser le socle (`vf-planning`, profil standard +
extension `editorial/` — ou `vf-new-lab` si le lab n'existe pas). En mode dégradé accepté
par l'utilisateur : recueille ton / audience / sources autorisées en 3 questions, consigne-les,
et signale dans chaque sortie que la pièce a été produite **sans référentiel stable**.

## Étape 1 — Aiguillage : geste simple ou mission

Détermine **N = nombre de pièces demandées** (une déclinaison multi-plateformes d'une même
pièce compte pour 1). Seuil : `SEUIL_EQUIPE_CONTENT = 3` (même logique que `vf-auto`).

- **N < 3 ET aucun signal de durée** → **geste simple** : déroule la chaîne courte
  ci-dessous depuis ce skill. Annonce : « pièce unique, chaîne directe ».
- **N ≥ 3 OU signal de durée** (« la semaine », « en autonomie », « la nuit »,
  « débrouille-toi », « rattrape le calendrier ») → **mission** : dispatche l'agent
  `vf-content-manager` (outil Task) avec le brief (périmètre, mode superviser|autonome,
  contraintes de session) puis NE poursuis PAS ce skill — le manager tient le DAG, le
  verrou de driver, le dispatch parallèle et le rapport de mission. Le signal de durée
  GAGNE en cas d'ambiguïté.

## Geste simple — la chaîne courte (une pièce, ou une déclinaison)

Chaque étape passe par un Task dédié ; chaque mandat embarque un mini-digest (pièce,
périmètre d'écriture, ton, sources autorisées). Ne saute JAMAIS un étage :

1. **Cadrage** — Task `vf-content-strategist` : fiche de cadrage dans
   `pieces/<AAAA-MM-JJ>-<slug>/cadrage.md`. (Si l'utilisateur ne demande QUE le cadrage ou
   le calendrier, arrête-toi à l'étage concerné.)
2. **Rédaction** — Task `vf-content-writer` : livrable `pieces/<slug>/piece.md` (3 hooks +
   texte final + auto-contrôle).
3. **Gate de clarté** — Task `content-clarity-judge` (toujours frais) : verdict typé /100.
   `gaps_found` → relance le writer avec les findings (max 2 relances, ensuite escalade à
   l'utilisateur).
4. **Validation humaine** — présente la pièce + le score à l'utilisateur et attends sa
   validation explicite. Cette étape n'est **jamais** auto-validée ni sautée : sans
   validation, la pièce reste en statut `human_needed` et rien n'est distribué.
5. **Déclinaison** (si demandée) — Task `vf-content-repurposer` : variantes + mise à jour
   de `editorial/CALENDRIER.md`. La publication effective reste à l'humain.

## Cas particuliers

- **« Décline cet article »** (pièce externe, jamais passée par la chaîne) : la pièce
  source passe d'abord le gate de clarté (étape 3) puis la validation humaine (étape 4)
  avant toute déclinaison — une source externe n'est pas exemptée.
- **« Prépare le calendrier de la semaine »** sans production : Task
  `vf-content-repurposer` en mode calendrier (ré-équilibrage de cadence, pas de variante) ;
  s'il faut produire des pièces pour tenir la cadence, c'est une mission (N ≥ 3 probable).

## Invariants (quel que soit le chemin)

- **Jamais de distribution sans validation humaine** (ADR-031) — y compris en autonomie :
  la mission s'arrête à « prêt pour validation », l'humain publie.
- **Le juge est toujours frais et read-only** ; l'auto-contrôle du writer ne remplace
  jamais son verdict.
- **Verdicts capitalisés** en `EVALS`, apprentissages en `LEARNINGS` (registres du lab).
- Les workers sont internes (Pattern 12) : n'expose jamais leur plomberie à l'utilisateur —
  parle en vocabulaire métier (pièce, angle, pilier, cadence, campagne).
