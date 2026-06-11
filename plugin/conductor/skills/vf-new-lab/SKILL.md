---
name: vf-new-lab
description: >
  Utiliser pour créer/initialiser un NOUVEAU lab VibeFlow dans n'importe quel métier — « crée un lab
  d'acquisition », « monte un lab de contenu », « initialise un lab pour mon agence », « je veux un
  espace VibeFlow pour [métier] ». Pilote un cadrage court (ce que l'utilisateur sait déjà : métier,
  process, objectifs, contraintes, vocabulaire) puis dérive et pose le lab adapté. NE PRÉSUME JAMAIS
  « dev ». Invocable par l'utilisateur ET par l'agent `vibeflow-conductor`.
---

# vf-new-lab — Bootstrap de lab universel

> **Mission** : transformer ce que l'utilisateur **sait déjà de son métier** en un lab VibeFlow propre,
> configuré, avec ses garde-fous — sans qu'il ait à connaître la plomberie du framework.
>
> **Iron Law** : *« Le lab épouse le métier de l'utilisateur. On ne plaque aucune forme (dev ou autre).
> On ne demande que ce qu'il sait déjà. »*

Skill **prose agent-driven**. Il ne code pas le métier : il **dérive une structure** et délègue aux
modules outillés (planning-core, installeur, reference). Cadrage court, scaffolding adapté.

---

## Principe : install chirurgicale

L'utilisateur connaît son métier mieux que nous. On ne lui impose pas un gabarit : on lui pose
**5 questions qu'il sait déjà répondre**, puis le lab se construit autour. Tout le reste est dérivé.

## Séquence

### 1. Cadrage (5 questions max — ce que l'utilisateur sait déjà)

Poser de façon resserrée (une passe, pas un interrogatoire). Détail dans la référence `bootstrap-method.md`
(installée en `.claude/agents/conductor-references/bootstrap-method.md`).

1. **Métier / domaine du lab** — « C'est un lab pour quoi ? » (ex. acquisition, contenu, vente, dossier…)
2. **Process & livrables récurrents** — « Qu'est-ce que tu produis/fais de façon répétée ? »
   (ex. séquences cold email, campagnes ads, landing pages…)
3. **Objectif** — « Qu'est-ce que ce lab doit rendre possible ? » (la valeur cœur)
4. **Contraintes** — outils, cibles, ton, réglementaire, délais.
5. **Vocabulaire métier** — les 3-5 termes que le lab doit parler (pour ne pas plaquer un jargon importé).

> Si l'utilisateur a déjà tout dit en langage naturel, NE PAS re-questionner : extraire les réponses
> de ce qu'il a écrit et confirmer en une ligne.

### 2. Dérivation (sans rien imposer)

Depuis les réponses, déduire :
- **Profil de rigueur** (léger / standard / complet) — via `planning-core` (`PROFILES.md`).
- **Extension de domaine** — le sous-dossier propre au métier (`acquisition/`, `editorial/`,
  `pipeline/`, `dossiers/`…), nommé d'après le vocabulaire réel.
- **Agents métier** à créer (2-3 max) — paramétrés sur les process cités (ex. un agent
  « copywriter-acquisition », un agent « analyste-campagne »). Pattern : business-agent générique.
- **Modules VibeFlow pertinents** — typiquement `planning-core` + `consolidator` + `audit-architecture`
  + `validator`. **Pas `dev-orchestrator`** sauf si le métier est le code.

> **Mode bundle métier (raccourci recommandé)** : si un bundle métier est installé (présence de
> `docs/<metier>-bundle/` — ex. `business-pilot-bundle`, `content-bundle`, `growth-bundle`), NE PAS
> dériver de zéro. Lire `docs/<metier>-bundle/content/BUNDLE.md` (profil, extension, vocabulaire,
> liste d'agents, flux d'instanciation) + `content/domain/extension-spec.md` + `content/registres.md`,
> et utiliser les blueprints `content/agents/*.blueprint.md` comme base des agents métier. Le bundle
> porte déjà le châssis conforme (P1-P9, registres, auditeurs câblés) — **on instancie, on n'invente pas**.

### 3. Scaffolding (déléguer, ne pas réinventer)

Poser, dans l'ordre :
1. **`CLAUDE.md` du lab** — constitution métier (WHY/WHAT/HOW) en vocabulaire de l'utilisateur.
2. **Modules** — déléguer à `vibeflow-install` (sélection dérivée à l'étape 2, scope au choix).
3. **Socle planning** — déléguer à `vf-planning` (profil + extension de domaine).
4. **Registres mémoire** — DECISIONS / LEARNINGS / BLOCKERS / JOURNAL (depuis `reference` si installé).
5. **Agents métier** — si un bundle est présent : **instancier** chaque `content/agents/*.blueprint.md`
   en agent natif réel dans `.claude/agents/` (≤250L, adapté au cadrage). Sinon : créer 2-3 agents
   dérivés (pattern business-agent). Dans les deux cas, créer les skills déclarés en frontmatter
   `skills:` qui manquent via `skill-creator`.
6. **Garde-fous** — câbler `vibeflow-validator` + `audit-architecture` (auditeurs toujours présents).
7. **Stamp framework** — enregistrer la version du framework dans le lab (`framework-version.sh stamp`)
   pour la détection d'update ultérieure.

### 4. Récap

Montrer l'arbo posée, le métier capté, les agents créés, et **la première action métier** proposée
en vocabulaire du lab (ex. « lance ta première séquence d'acquisition »).

---

## Exemple — lab « acquisition »

Réponses : *acquisition B2B · séquences cold email + campagnes LinkedIn Ads · générer des RDV
qualifiés · ton direct, cible CTO · vocabulaire : séquence, ICP, RDV, offre.*
→ Profil **standard** · extension **`acquisition/`** (ICP.md, SEQUENCES.md, OFFRES.md) · agents
**copywriter-sequences** + **analyste-campagnes** · modules planning-core + consolidator + validator
· `.planning/` avec ROADMAP en « campagnes » et REQUIREMENTS en objectifs d'acquisition.
**Zéro fichier dev, zéro sprint de code.**

---

## Garde-fous

- **Ne jamais présumer dev.** Lire le métier, choisir l'extension d'après le vocabulaire réel.
- **Ne jamais sur-configurer.** Un lab léger reste léger ; on n'ajoute que ce qui sert au métier.
- **Ne jamais demander ce qu'on peut dériver.** 5 questions max ; le reste se déduit.
- **Toujours câbler les auditeurs** — pas de lab sans filet de cohérence.
- **Toujours stamper la version framework** — sinon pas de détection d'update plus tard.

## Références (on-demand)

- `bootstrap-method.md` (installé en `.claude/agents/conductor-references/`) — méthode de cadrage + dérivation détaillée.
- planning-core `PROFILES.md` / `domain-detection.md` / `example-lab-contenu.md` — adaptation par métier.
- Bundles métier installés (`docs/<metier>-bundle/content/BUNDLE.md`) — châssis prêt à instancier (business-pilot / content / growth).
