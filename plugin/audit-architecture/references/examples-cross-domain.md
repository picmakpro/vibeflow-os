# Référence — 3 instances cross-domaines

> La preuve que le primitif est universel : la MÊME méthode produit des structures d'audit radicalement différentes selon le domaine. Le porte/agent/caméra/filet du dev n'est qu'UNE instance parmi d'autres.

---

## Instance A — Génération de contenu (carrousel / script vidéo)

**Brief** : un sujet de post. **Output** : un contenu publié (carrousel + caption + script oral). **Point de non-retour** : la publication publique.

| # | Couche (dimension) | Auditeur | Enforcement | Verdict |
|---|--------------------|----------|-------------|---------|
| 1 | **Forme mécanique** (≤95 s, densité, pas de filler, 1 seul 4e mur) | créateur (auto-audit A1-A10) | checklist quasi-déterministe | OK/KO |
| 2 | **Fond / clarté** (sujet en 5 s, métaphore unique, anti-parenthèses, niveau vulgarisé) | clarity-auditor (lecteur frais) | **rubric LLM** 9 principes, 4 bloquants + 2 cond. | CLA-XXX |
| 3 | **Naturalité** (oral FR / écrit EN, zéro marqueur IA, accents) | human-validator | **rubric scorée /100**, seuil ≥70 | HUM-XXX |
| 4 | **Cohérence visuelle** (lisibilité 46px, hiérarchie, slides) | visual-qa | **checklist LLM** par slide | VIS-XXX |
| 5 | **Dérive du corpus** (drift éditorial, périodique 2-4 sem) | auditor | rubric 5 dimensions /10 | REV-XXX |

- **Ordre** : fond AVANT visuel (inutile d'illustrer un message rejeté).
- **Agent terminal** : le publisher REFUSE de publier sans CLA-XXX VALIDE + HUM-XXX VALIDE.
- **Anti-boucle** : max 2 A/R ig-creator↔clarity-auditor → 3e FAIL = escalade stratège.
- **C'est le système réel du ContentFlow Lab.** Le skill ne fait que le nommer et le généraliser.

---

## Instance B — Montage de dossier (ex : dossier administratif / juridique)

**Brief** : une demande client + ses pièces. **Output** : un dossier déposé. **Point de non-retour** : le dépôt officiel (rejet = délai + coût pour le client).

| # | Couche (dimension) | Auditeur | Enforcement | Verdict |
|---|--------------------|----------|-------------|---------|
| 1 | **Complétude** (toutes les pièces obligatoires présentes) | script/checklist | déterministe (liste de pièces) | OK/KO |
| 2 | **Factualité** (montants, dates, identités exacts vs pièces source) | data-checker | test (recoupement) | FACT-XXX |
| 3 | **Conformité réglementaire** (le dossier respecte la norme en vigueur) | compliance-auditor | **rubric LLM** + base réglementaire | CONF-XXX |
| 4 | **Cohérence inter-pièces** (pas de contradiction entre documents) | coherence-auditor | rubric LLM | COH-XXX |
| 5 | **Dérive réglementaire** (jurisprudence/norme obsolète, périodique) | reg-watch | rubric périodique | — |

- **Ordre** : complétude (pas cher, bloquant net) d'abord ; conformité (coûteuse) ensuite.
- **Agent terminal** : le déposeur REFUSE de déposer sans CONF-XXX VALIDE.
- **Note** : ici la couche 2 est un **test** (recoupement de faits), pas un juge-LLM — la dimension est vérifiable.

---

## Instance C — Feature de code (le porte/agent/caméra/filet — cas particulier)

**Brief** : une user story. **Output** : du code en production. **Point de non-retour** : le merge / le déploiement.

La métaphore défensive « porte / filet / agent / caméra » est **l'instance dev** du primitif : 4 couches,
chacune **possédée par un module dédié**. Ce tableau les NOMME et RENVOIE au module propriétaire — il ne
re-spécifie pas leur mécanique (elle vit, à jour, dans le module).

| Métaphore | # | Couche (dimension) | Module propriétaire de la mécanique |
|-----------|---|--------------------|-------------------------------------|
| 🚪 **Porte blindée** | 1 | Forme / structure | `software-architecture` — rule `production-code-architecture` + gate de taille |
| 🪂 **Filet de sécurité** | 2 | Véracité / non-régression (filet FONCTIONNEL) | `software-architecture` — Gate Nyquist ; skills `tdd` + `verification-before-completion` |
| 👮 **Agent de sécurité** | 3 | Fond / intention + sécurité | revue de code / sécurité (`pr-review`, `security-review`) |
| 📹 **Caméras** | 4 | Dérive / observabilité | `infrastructure-audit` |

- **Ordre** : porte (instantanée) → filet (rapide) → agent (PR) → caméras (continu).
- **Les 4 = les 4 mécanismes du spectre d'enforcement** (script ↔ test ↔ rubric LLM ↔ audit périodique),
  mappés sur 4 dimensions de code. Les **axiomes transverses** (enforcement > prose, filet avant tout,
  preuve avant *done*) ont leur formulation canonique dans `reference/` → `methodology/AXIOMES-ENFORCEMENT.md`.
- **But de l'exemple** : montrer que le primitif d'audit *dérive* aussi l'instance code — pas re-documenter
  chaque module. Pour la spec exacte d'une couche, ouvrir son module propriétaire.

---

## Ce que les 3 instances ont en commun (l'invariant universel)

| Invariant | A (contenu) | B (dossier) | C (code) |
|-----------|-------------|-------------|----------|
| Couches = dimensions indépendantes | 5 | 5 | 4 |
| Auditeur indépendant du créateur | clarity/human/visual | compliance/coherence | reviewer |
| Verdict bloquant typé | CLA/HUM/VIS | CONF/COH/FACT | tests/review |
| Agent terminal qui REFUSE | publisher | déposeur | CI/merge |
| Enforcement épouse la dimension | mix checklist+rubric | mix test+rubric | mix script+test+rubric |
| Anti-boucle + escalade | 2 A/R → stratège | — | — |

**Conclusion** : changez le domaine, les couches et les mécanismes changent — **mais le primitif et la méthode de dérivation ne changent pas**. C'est ça, l'universel.
