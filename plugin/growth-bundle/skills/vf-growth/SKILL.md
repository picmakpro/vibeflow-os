---
name: vf-growth
description: >
  Utiliser quand l'intention est d'acquérir des clients via des campagnes par canal —
  « lance une campagne cold email », « prépare les séquences LinkedIn », « écris la
  séquence de relance », « active un nouveau canal », « analyse les résultats de la
  campagne », « arbitre mes canaux », « lance la vague du mois en autonomie ». Point
  d'entrée du métier growth de VibeFlow : route un geste simple (une campagne → chaîne
  courte stratégie → production → gate qualité → validation humaine → lancement humain →
  analyse) ou une mission (≥ 3 campagnes/séquences ou signal de durée → équipe via
  vf-growth-manager). L'envoi réel (email, publication, dépense publicitaire, outreach)
  est HUMAN-GATED — jamais exécuté en autonomie, quel que soit le mode.
  ✘ pas pour poser/structurer le planning du lab → vf-planning · ✘ pas pour configurer le
  lab ou installer des modules → vibeflow-conductor · ✘ pas pour du contenu éditorial
  (posts, threads, newsletters) → vf-content · ✘ pas pour de la copy de page web
  (landing, pricing) → skills copywriting dédiés.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-growth — Point d'entrée du métier growth

Chaîne d'acquisition : **brief → stratégie (canal/ICP) → production (séquences/créatives)
→ gate qualité → validation humaine → lancement HUMAIN → analyse (CAC/ROAS, verdict)**.
Équipe : `channel-strategist` (stratégie), `copywriter-sequences` (livrable),
`growth-quality-judge` (juge frais read-only, rubric /100), `campaign-analyst`
(mesure + verdict GO/ITERATE/KILL), `vf-growth-manager` (mission).

## Étape 0 — Garde first-use

Si le référentiel `growth/` du lab est absent (`growth/ICP.md` introuvable) : propose
d'abord de poser le socle (`vf-planning`, profil standard + extension `growth/` selon la
spec du bundle — ou `vf-new-lab` si le lab n'existe pas). En mode dégradé accepté par
l'utilisateur : recueille ICP / offre / canal en 3 questions, consigne-les, et signale
dans chaque sortie que la campagne a été produite **sans référentiel stable**.

## Étape 1 — Aiguillage : geste simple ou mission

Détermine **N = nombre de campagnes/séquences demandées** (les variantes A/B d'une même
campagne comptent pour 1). Seuil : `SEUIL_EQUIPE_GROWTH = 3` (même logique que `vf-auto`).

- **N < 3 ET aucun signal de durée** → **geste simple** : déroule la chaîne courte
  ci-dessous depuis ce skill. Annonce : « campagne unique, chaîne directe ».
- **N ≥ 3 OU signal de durée** (« la vague du mois », « en autonomie », « la nuit »,
  « débrouille-toi », « rattrape le backlog ») → **mission** : dispatche l'agent
  `vf-growth-manager` (outil Task) avec le brief (périmètre, mode superviser|autonome,
  contraintes de session) puis NE poursuis PAS ce skill — le manager tient le DAG, le
  verrou de driver, le dispatch parallèle et le rapport de mission. Le signal de durée
  GAGNE en cas d'ambiguïté.

## Geste simple — la chaîne courte (une campagne)

Chaque étape passe par un Task dédié ; chaque mandat embarque un mini-digest (campagne,
canal, périmètre d'écriture, seuils, garde-fous RGPD/anti-spam). Ne saute JAMAIS un
étage :

1. **Stratégie** — Task `channel-strategist` : fiche dans
   `campagnes/<AAAA-MM-JJ>-<slug>/strategie.md` (canal, ICP local, offre activée,
   hypothèse EXP, seuils). (Si l'utilisateur ne demande QUE la stratégie ou l'activation
   d'un canal, arrête-toi à cet étage.)
2. **Production** — Task `copywriter-sequences` : livrable
   `campagnes/<slug>/sequences.md` (variantes A/B + sources + auto-contrôle).
3. **Gate qualité** — Task `growth-quality-judge` (toujours frais) : verdict typé /100.
   `gaps_found` → relance le copywriter avec les findings (max 2 relances, ensuite
   escalade à l'utilisateur).
4. **Validation humaine + lancement** — présente la campagne + le score à l'utilisateur
   et attends sa validation explicite. Cette étape n'est **jamais** auto-validée ni
   sautée : sans validation, la campagne reste en statut `human_needed` et **rien n'est
   envoyé**. Le lancement effectif (envoi des emails, publication, activation de budget)
   est un geste HUMAIN — le lab prépare, l'humain lance.
5. **Analyse** (une fois la campagne lancée et des données disponibles) — Task
   `campaign-analyst` : `campagnes/<slug>/analyse.md`, mise à jour METRICS/EXPERIMENTS,
   verdict GO/ITERATE/KILL. Sans preuve de lancement, l'analyst refuse.

## Cas particuliers

- **« Analyse les résultats »** (campagne déjà lancée hors chaîne) : exige d'abord la
  trace du lancement (date, canal, données accessibles) puis Task `campaign-analyst`
  directement — une campagne externe n'est pas exemptée de preuve.
- **« Arbitre mes canaux »** : Task `campaign-analyst` (comparatif `growth/METRICS.md` à
  jour, valeurs sourcées ou « inconnues ») puis Task `channel-strategist` (recommandation
  d'arbitrage). La décision de kill/budget reste à l'humain — jamais tranchée en
  autonomie.
- **« Active un nouveau canal »** : Task `channel-strategist` seul (duplication de
  `channels/_TEMPLATE/`, delta ICP, seuils) ; produire les premières séquences est un
  geste suivant.

## Invariants (quel que soit le chemin)

- **Jamais d'envoi réel sans validation humaine** (ADR-031, frontière Tier 2 de
  kpi-analyst) — email, publication, dépense publicitaire, outreach : y compris en
  autonomie, la mission s'arrête à « prête au lancement », l'humain lance.
- **Aucun chiffre inventé** : un claim non sourcé est éliminatoire au gate ; une métrique
  non sourcée est « inconnue » (confiance low), jamais extrapolée.
- **Le juge est toujours frais et read-only** ; l'auto-contrôle du copywriter ne remplace
  jamais son verdict.
- **Verdicts capitalisés** en `EVALS`, apprentissages en `LEARNINGS` avec **tag-canal
  obligatoire** (zéro contamination inter-canaux).
- Les workers sont internes (Pattern 12) : n'expose jamais leur plomberie à
  l'utilisateur — parle en vocabulaire métier (canal, campagne, séquence, ICP, offre,
  expérience, CAC, ROAS).
