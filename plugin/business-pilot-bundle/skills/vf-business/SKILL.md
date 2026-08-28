---
name: vf-business
description: "Utiliser quand l'intention est de piloter le business — « qualifie ce lead », « prépare le devis / la proposition pour X », « relance ce prospect », « où en est le pipeline », « suis le jalon du client Y », « prépare le livrable du jalon », « prépare la facture », « relance les impayés », « fais une prévision de CA », « fais tourner le business de la semaine », « traite les dossiers clients en autonomie ». Point d'entrée du métier business de VibeFlow : route un geste simple (un dossier/une action → chaîne courte worker → gate qualité → validation humaine) ou une mission (≥ 3 dossiers/actions ou signal de durée → équipe via vf-business-manager). Deux Iron Laws non négociables quel que soit le mode : aucun envoi client (devis, livrable, relance, facture) sans validation humaine — l'humain envoie — et aucun chiffre financier inventé — chaque montant est sourcé ou marqué à confirmer. ✘ pas pour poser/structurer le planning du lab → vf-planning · ✘ pas pour configurer le lab ou installer des modules → vibeflow-conductor · ✘ pas pour calculer/publier les KPIs → kpi-analyst (le pilier finance s'y adosse, il ne le remplace pas). Invocable par l'utilisateur ET par l'agent en autonomie."
---

# vf-business — Point d'entrée du métier business

Chaîne de pilotage : **brief → commercial (qualif/proposition) → delivery (jalons/livrable)
→ gate qualité → validation humaine → finance (facture/encaissement préparés)**. Équipe :
`vf-business-commercial` (pipeline, propositions, relances — rédige, n'envoie jamais),
`vf-business-delivery` (jalons, SLA, préparation des livrables), `quality-gate-client`
(juge frais read-only, rubric /100), `vf-business-finance` (factures/relances/prévisions —
chiffres sourcés uniquement), `vf-business-manager` (mission).

## Les deux Iron Laws (quel que soit le chemin)

1. **Jamais d'envoi client sans validation humaine** (ADR-031, LRN-068) : devis,
   proposition, livrable, relance, facture — le lab PRÉPARE, le gate JUGE, l'humain
   VALIDE puis ENVOIE dans ses outils. Y compris en autonomie : la mission s'arrête à
   « prêt pour validation ».
2. **Jamais de chiffre financier inventé** : chaque montant est extrait d'une source
   citée (`OFFERS.md`/`PRICING.md`, dossier client, `CLIENTS.md`, registre `KPIS.md` du
   module kpi-analyst quand il est installé) ou marqué `confidence: low` « à confirmer »
   — et un montant non sourcé est éliminatoire au gate.

## Étape 0 — Garde first-use

Si le référentiel `business/` du lab est absent (`.planning/business/PIPELINE.md`
introuvable) : propose d'abord de poser le socle (`vf-planning`, profil standard +
extension `business/` selon `content/domain/extension-spec.md` du module — ou
`vf-new-lab` si le lab n'existe pas). En mode dégradé accepté par l'utilisateur :
recueille offre / clients en cours / termes de paiement en 3 questions, consigne-les,
et signale dans chaque sortie que le travail a été produit **sans référentiel stable**.

## Étape 1 — Aiguillage : geste simple ou mission

Détermine **N = nombre de dossiers clients ou d'actions business distinctes** demandés
(qualifier un lead = 1 ; préparer proposition + facture du même dossier = 2 actions).
Seuil : `SEUIL_EQUIPE_BUSINESS = 3` (même logique que `vf-auto`).

- **N < 3 ET aucun signal de durée** → **geste simple** : déroule la chaîne courte
  ci-dessous depuis ce skill. Annonce : « dossier unique, chaîne directe ».
- **N ≥ 3 OU signal de durée** (« la semaine », « en autonomie », « la nuit »,
  « débrouille-toi », « rattrape le pipeline ») → **mission** : dispatche l'agent
  `vf-business-manager` (outil Task) avec le brief (périmètre, mode superviser|autonome,
  contraintes de session) puis NE poursuis PAS ce skill — le manager tient le DAG, le
  verrou de driver, le dispatch parallèle des dossiers indépendants et le rapport de
  mission. Le signal de durée GAGNE en cas d'ambiguïté.

## Geste simple — la chaîne courte (un dossier, ou une action)

Chaque étape passe par un Task dédié ; chaque mandat embarque un mini-digest (dossier
CLI-XXX, périmètre d'écriture, périmètre vendu, sources de montants autorisées). Ne
saute JAMAIS un étage :

1. **Étage producteur** — route sur l'action :
   - qualification / proposition / devis / relance commerciale → Task
     `vf-business-commercial` (livrable rédigé dans le dossier d'opportunité) ;
   - suivi de jalon / préparation d'un livrable / satisfaction → Task
     `vf-business-delivery` (dossier `business/pipeline/delivery/`) ;
   - facture / relance de paiement / prévision / revue → Task `vf-business-finance`
     (documents sous `business/finance/`, montants sourcés uniquement).
   (Si l'utilisateur ne demande QUE la qualification ou la revue de pipeline — aucun
   livrable client — arrête-toi à cet étage.)
2. **Gate qualité** — dès qu'un livrable est destiné au client : Task
   `quality-gate-client` (toujours frais) : verdict typé /100, seuil 80, montant non
   sourcé et hors-périmètre-vendu éliminatoires. `gaps_found` → relance le worker
   producteur avec les findings (max 2 relances, ensuite escalade à l'utilisateur).
3. **Validation humaine** — présente le livrable + le score à l'utilisateur et attends
   sa validation explicite. Cette étape n'est **jamais** auto-validée ni sautée : sans
   validation, le livrable reste en statut `human_needed` et rien n'est envoyé.
4. **Envoi** — par l'humain, dans ses outils (CRM, mail, compta — via MCP le cas
   échéant). Le lab marque « prêt à envoyer », il n'envoie pas.

## Cas particuliers

- **Facturer un jalon** : le finance exige les preuves amont (gate vert + validation
  humaine du livrable facturé) — preuves absentes → il refuse, fais d'abord passer le
  livrable par les étapes 2-3.
- **Signal d'upsell / churn** remonté par le delivery : nouvelle action commerciale →
  Task `vf-business-commercial` (nouvelle opportunité) ; si ça fait franchir le seuil,
  bascule en mission.
- **« Où en est le pipeline ? »** : lecture seule de `business/PIPELINE.md` (index) +
  synthèse — pas de dispatch, pas de gate.
- **KPIs / CA / MRR** (« mets à jour les chiffres ») : ce n'est pas ce skill → module
  `kpi-analyst` (le finance CONSOMME `KPIS.md`, il ne le produit pas).

## Invariants (quel que soit le chemin)

- **Jamais d'envoi sans validation humaine** (Iron Law 1) — y compris en autonomie.
- **Jamais de chiffre inventé** (Iron Law 2) — le gate le rend éliminatoire.
- **Le gate est toujours frais et read-only** ; l'auto-contrôle du worker ne remplace
  jamais son verdict.
- **Un dossier client n'est jamais supprimé** (perte → `archive/`).
- **Verdicts capitalisés** en `EVALS`, patterns en `LEARNINGS`, décisions structurantes
  promues en `DECISIONS` (registres du lab).
- Les workers sont internes (Pattern 12) : n'expose jamais leur plomberie à
  l'utilisateur — parle en vocabulaire métier (dossier, pipeline, jalon, Sprint
  stratégique, Initiative, Rollout).
