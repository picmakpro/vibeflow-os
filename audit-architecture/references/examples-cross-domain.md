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

La métaphore défensive « porte blindée / agent / caméra / filet » est **l'instance dev** du primitif. Chaque image = une couche :

| Métaphore | # | Couche (dimension) | Auditeur | Enforcement | Verdict |
|-----------|---|--------------------|----------|-------------|---------|
| 🚪 **Porte blindée** | 1 | **Forme / structure** (taille ≤300 L, frontières, pas de secret) | pre-commit / PreToolUse hook | **script** (check-file-size, protect-files) | exit 0/2 |
| 🪂 **Filet de sécurité** | 2 | **Véracité / non-régression** (le code marche, rien de cassé) | suite de tests | **test/lint/typecheck** (filet FONCTIONNEL) | vert/rouge |
| 👮 **Agent de sécurité** | 3 | **Fond / intention + sécurité** (la modif reflète la spec, pas de faille) | reviewer agent (PR) | **rubric LLM** (pr-review, security-review) | review verdict |
| 📹 **Caméras** | 4 | **Dérive / observabilité** (drift archi, dette, prod) | infrastructure-audit / observabilité | audit périodique + monitoring | snapshot diff |

- **Ordre** : porte (instantanée) → filet (rapide) → agent (PR) → caméras (continu).
- **Agent terminal** : la CI / l'agent de merge REFUSE de merger sans tests verts + review VALIDE.
- **Le filet AVANT tout** : un filet de tests cassé invalide la couche 2 → réparer le filet avant de continuer (cause racine Permis Clair, LRN-118).
- **Universel ↔ dev** : porte=script, filet=tests, agent=juge-LLM, caméras=audit périodique. Exactement les 4 mécanismes du spectre d'enforcement, mappés sur 4 dimensions de code.

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
