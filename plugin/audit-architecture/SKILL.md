---
name: audit-architecture
description: Concevoir et forcer une structure d'audit multi-couches pour N'IMPORTE QUEL process qui transforme un brief en output (génération de contenu/carrousel/script, montage de dossier, feature de code, séquence de vente, design...). Invoquer dès qu'on crée un process générateur, qu'on sent qu'un output sort "sans contrôle", qu'on veut fiabiliser une chaîne de production, ou qu'on audite un lab pour repérer les process sans garde-fou. Dérive depuis le brief les couches à auditer (dimension + auditeur indépendant + rubric + verdict bloquant + anti-boucle), choisit le mécanisme d'enforcement le long du spectre déterministe↔jugement, puis matérialise la structure. Universel, pas dev-spécifique. Opérationnalise le principe Core P8 (Évaluer) au niveau process.
---

# Skill : Audit Architecture — Concevoir des structures d'audit multi-couches

> **Iron Law** : *"Un process générateur sans structure d'audit multi-couches produit de la dérive silencieuse. Un audit qui n'est pas FORCÉ (verdict bloquant) n'est pas un audit — c'est un avis."*
>
> **Specialise** : Core P8 (Évaluer la qualité cognitive) appliqué *par process*, pas seulement par sprint.
> **Complémentaire** : `software-architecture` (structure du CODE) ↔ `audit-architecture` (structure des AUDITS).

---

## Pourquoi ce skill

Tout lab finit par avoir des **process générateurs** : « générer un carrousel », « monter un dossier », « écrire une feature », « produire une séquence de vente ». Chacun transforme un **brief** en **output**. Et chacun peut dériver silencieusement : le carrousel devient illisible, le dossier incomplet, le code cassé, la séquence générique.

La parade n'est PAS un script de validation. C'est une **structure d'audit multi-couches** : une chaîne d'auditeurs indépendants, chacun contrôlant UNE dimension de l'output, chacun rendant un **verdict bloquant**.

Ce skill ne fait pas l'audit lui-même. Il **conçoit l'architecture d'audit** d'un process, puis la **force** dans le lab. C'est un méta-skill : un *concepteur d'architecture d'audit*.

> **Preuve terrain** : le ContentFlow Lab impose déjà 5 couches successives pour publier un contenu (forme mécanique → clarté/fond → naturalité → cohérence visuelle → dérive corpus), chacune avec un auditeur dédié et un verdict bloquant (CLA-XXX / HUM-XXX / REV-XXX). Ce skill généralise ce pattern à tout process.

---

## Le primitif universel : la couche d'audit

Toute couche d'audit, quel que soit le domaine, se décrit par **5 attributs** :

```
COUCHE = (Dimension) × (Auditeur indépendant) × (Rubric) × (Verdict bloquant) × (Anti-boucle)
```

| Attribut | Définition | Question à se poser |
|----------|------------|---------------------|
| **Dimension** | UNE seule chose contrôlée (forme, fond, visuel, factualité, ton, complétude...) | *Quelle propriété de l'output peut échouer indépendamment des autres ?* |
| **Auditeur indépendant** | Un agent/personne **distinct du créateur** (le « lecteur frais ») | *Qui peut juger sans être juge et partie ?* |
| **Rubric** | Critères explicites + seuils (binaire PASS/FAIL ou scoré /100) | *Sur quoi, précisément, le verdict se fonde-t-il ?* |
| **Verdict bloquant** | `VALIDE` / `AJUSTE` / `REJETE` qui **empêche l'étape suivante** | *Que bloque un échec ? Qui refuse de continuer ?* |
| **Anti-boucle** | Limite d'allers-retours avant escalade | *Après combien d'échecs on escalade au lieu de boucler ?* |

> **Une dimension = une couche.** Si un auditeur contrôle deux choses non corrélées (ex : la grammaire ET la cohérence de marque), scinde en deux couches. Le mélange de dimensions est l'anti-pattern n°1.

**Structure d'audit** = une **chaîne séquencée** de couches, ordonnée du moins cher / plus bloquant au plus coûteux (on ne lance pas l'audit visuel d'un carrousel dont le fond est REJETE).

---

## La méthode de décomposition (le cœur — du raisonnement, pas un script)

C'est ici que vit l'universalité. La machine ne *décide* pas les couches ; elle les **dérive par raisonnement** depuis le brief. Procédure en 4 temps.

### Temps 1 — Identifier le process et son contrat

- **Brief en entrée** : qu'est-ce qui déclenche le process ? (un sujet, une demande client, une user story…)
- **Output en sortie** : quel artefact concret ? (un carrousel publié, un dossier déposé, un PR mergé…)
- **Point de non-retour** : à partir de quand l'erreur coûte cher / devient publique ? (la publication, le dépôt, le merge, l'envoi). **C'est ce point que les couches protègent.**

### Temps 2 — Dériver les dimensions auditables

Liste les façons **indépendantes** dont l'output peut être mauvais *tout en étant "fini"*. Heuristique : pour chaque dimension, demande *« un output peut-il être parfait sur tout le reste et échouer SEULEMENT là-dessus ? »* Si oui → c'est une dimension. Familles récurrentes (à adapter, pas à appliquer aveuglément) :

| Famille de dimension | Exemple contenu | Exemple dossier | Exemple code |
|---|---|---|---|
| **Forme / structure** | longueur, rythme, format | sections obligatoires présentes | taille fichier, frontières |
| **Fond / substance** | clarté, valeur, delta de savoir | complétude juridique, cohérence des pièces | la modif reflète la spec |
| **Surface / rendu** | cohérence visuelle, lisibilité | mise en forme, signatures | lint, types |
| **Factualité / véracité** | sources réelles, chiffres exacts | montants/dates exacts | tests verts (pas de régression) |
| **Voix / conformité** | ton, marque, zéro marqueur IA | langage réglementaire | conventions du repo |
| **Dérive (méta, périodique)** | drift éditorial du corpus | jurisprudence obsolète | dette accumulée |

### Temps 3 — Ordonner en chaîne + nommer l'auditeur

- Ordre = **bloquant-pas-cher d'abord, coûteux-en-dernier**. Un REJETE précoce économise les couches suivantes.
- Pour chaque couche, nomme un **auditeur indépendant**. Règle d'or : *le créateur ne s'auto-valide jamais sur le fond*. (L'auto-audit de forme mécanique par le créateur est tolérable ; le fond exige un lecteur frais.)

### Temps 4 — Choisir l'enforcement par couche (voir spectre ci-dessous)

Chaque couche reçoit le mécanisme adapté à **sa nature** : déterministe si mesurable, jugement à rubric si qualitatif. Voir `references/enforcement-spectrum.md`.

> Détail complet + grille de questions : `references/decomposition-method.md`.

---

## Le spectre d'enforcement (résout « les scripts sont trop déterministes »)

Le forçage n'est PAS réservé au code. Il existe le long d'un spectre — et **les deux extrémités sont également bloquantes** :

```
DÉTERMINISTE  ←───────────────────────────────────────────→  JUGEMENT
   script           test/lint        checklist          rubric LLM-judge
 (taille, durée,   (faits, types,   (cases binaires    (clarté, visuel,
  présence)         régressions)     à cocher)           ton, pertinence)
        \________________ TOUS produisent un verdict bloquant ________________/
```

- **Couche mesurable** (≤95 s, ≤300 lignes, accents présents, montant > 0) → **script / test**. Verdict = exit code.
- **Couche qualitative** (le carrousel est-il lisible ? le hook accroche-t-il ? le ton sonne-t-il humain ?) → **sous-agent juge avec rubric**. Verdict = `VALIDE/AJUSTE/REJETE` rendu par un auditeur LLM indépendant, sur critères explicites + seuils.

> **Point clé (LRN-118 tient)** : un verdict de juge-LLM exécuté par un auditeur indépendant, sur une rubric écrite, dans une chaîne où l'étape suivante **refuse** sans `VALIDE`, est aussi *machine-enforced* qu'un `exit 2`. Le forçage vient de **l'architecture de refus**, pas de la nature déterministe du check.
>
> **Le juge-LLM à rubric, c'est P8 EVALS** rendu systématique et par-process. On n'invente pas de philosophie — on opérationnalise un principe Core existant.

Comment trancher script vs juge : `references/enforcement-spectrum.md`. Comment écrire une bonne rubric scorée : `references/rubric-design.md`.

> Les 3 axiomes transverses (enforcement > prose / filet fonctionnel / preuve avant done) ont leur **formulation canonique** dans `reference/` → `methodology/AXIOMES-ENFORCEMENT.md`. Ce module les applique au niveau *conception d'audits* ; il ne les redéfinit pas.

---

## La matérialisation — forcer la structure dans le lab

Concevoir ne suffit pas. Le skill produit des **artefacts qui rendent l'audit non-contournable** :

1. **Les auditeurs** — un agent par couche qualitative (`.claude/agents/<dimension>-auditor.md`), ou un script par couche déterministe (`.claude/scripts/`). Chaque auditeur ≤ 250 L (ADR-029) ; sa rubric détaillée part en `references/`.
2. **Les formats de verdict** — un ID traçable par couche (ex : `CLA-XXX`, `HUM-XXX`, `VIS-XXX`) avec en-tête obligatoire + table de critères, déclaré dans `contracts.md`.
3. **Les règles de refus** — la règle bloquante non-négociable, écrite là où elle est *exécutée* : *« l'agent publisher/deployer/déposeur REFUSE de finaliser sans verdict VALIDE de la couche X »*. Inscrite dans `CLAUDE.md` ou une rule, et **incarnée par l'agent terminal** (celui qui franchit le point de non-retour).
4. **L'anti-boucle** — max N allers-retours créateur↔auditeur, puis escalade (ex : « 3e REJETE → escalade au stratège/humain »).

> **Le forçage réel = l'agent terminal qui REFUSE.** Une règle dans un CLAUDE.md que personne n'exécute est de la prose (LRN-118). Le verrou, c'est que l'agent qui publie/déploie/dépose a, dans son propre prompt, l'instruction de refuser sans les verdicts — et la liste des verdicts requis.

---

## Quand m'invoquer (1% Rule)

Si une situation correspond MÊME à 1 % à l'un de ces cas :

- Création/conception d'un **process générateur** (un pipeline brief → output, quel que soit le domaine).
- Sensation qu'un output « sort sans contrôle », ou qu'une chaîne de production manque de garde-fous.
- Un output récurrent dérive (qualité en baisse, incohérences, marqueurs IA, incomplétude).
- **Audit d'un lab** : repérer les process qui n'ont PAS de structure d'audit suffisante (mode scan, via `vibeflow-validator`).
- Volonté de fiabiliser / industrialiser une production (passer d'artisanal à systématique).
- Mise en place d'un nouveau lab : poser d'emblée les structures d'audit des process clés.

---

## Intégration `vibeflow-validator` (mode scan de lab)

Ce skill est injecté dans l'agent `vibeflow-validator` (champ `skills:`). Il ajoute une phase d'audit :

1. **Énumérer les process** du lab (lire CLAUDE.md, agents, triggers/commands, workflows → repérer chaque pipeline brief→output).
2. **Pour chaque process, reconstituer sa structure d'audit actuelle** (quelles couches existent déjà ? quels verdicts ? quel agent terminal refuse ?).
3. **Dériver la structure cible** (méthode 4 temps) et **differ** : couches manquantes, dimensions non couvertes, verdicts non bloquants, créateur qui s'auto-valide.
4. **Reporter les trous** par sévérité, et **proposer** la structure cible — sans la matérialiser.

> **Respect de l'Iron Law du validator (ADR-031)** : le skill *conçoit et propose*. La **matérialisation** (générer les auditeurs + règles) est un acte humain-déclenché, séparé du scan. Détecter ≠ corriger.

---

## Anti-patterns

- ❌ **Mélanger deux dimensions dans une couche** (grammaire + marque) → verdict illisible. Une dimension = une couche.
- ❌ **Le créateur s'auto-valide sur le fond** → biais juge-et-partie. Le fond exige un auditeur frais.
- ❌ **Verdict non bloquant** (« note : à améliorer ») → c'est un avis, pas un audit. Pas de verdict → pas de couche.
- ❌ **Tout vouloir déterministe** → impossible pour le qualitatif ; on n'audite alors plus rien. Utilise le juge-LLM à rubric.
- ❌ **Règle de refus écrite mais incarnée par personne** → prose. L'agent terminal DOIT porter l'instruction de refus.
- ❌ **Boucler à l'infini créateur↔auditeur** → toujours une limite + escalade.
- ❌ **Sur-architecturer un process à faible enjeu** → calibre le nombre de couches sur le coût de l'erreur au point de non-retour.

---

## Iron Laws

1. **Une dimension = une couche = un auditeur indépendant.**
2. **Pas de verdict bloquant → pas d'audit.** (Un avis n'arrête rien.)
3. **Le forçage vit dans l'agent terminal qui refuse**, pas dans la prose d'un CLAUDE.md.
4. **L'enforcement épouse la nature de la couche** (script si mesurable, juge à rubric si qualitatif) — jamais l'inverse.
5. **Concevoir et proposer ≠ matérialiser.** La matérialisation est humain-validée (ADR-031).

---

## Références (chargement à la demande)

- `references/audit-layer-primitive.md` — le primitif de couche en détail (les 5 attributs + exemples annotés).
- `references/decomposition-method.md` — la méthode 4 temps + grille de questions pour dériver les couches d'un process.
- `references/enforcement-spectrum.md` — choisir script ↔ test ↔ checklist ↔ juge-LLM ; quand chacun.
- `references/rubric-design.md` — écrire une rubric scorée robuste (critères, seuils, format de verdict, anti-complaisance).
- `references/examples-cross-domain.md` — 3 instances complètes : audit contenu (carrousel), audit dossier, audit code (porte/agent/caméra/filet comme cas particulier).
