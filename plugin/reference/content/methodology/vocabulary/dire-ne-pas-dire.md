# Dire / Ne pas dire — VibeFlow

> Le vocabulaire VibeFlow est volontairement strict. Chaque mot a ete choisi parce qu'il evite une ambiguite, une derive ou une confusion frequente.

## Concepts

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| Systeme agentique | Bot / chatbot | "Bot" reduit a la conversation. VibeFlow, c'est l'execution structuree. |
| Constitution | Prompt initial | "Prompt" est volatil. Constitution = contrat stable. |
| Capitaliser | Documenter | Capitaliser implique reutilisation future. Documenter peut etre passif. |
| Forker (verbe) | Customiser | Forker = transposition methodique avec lignee. Customiser = bricolage. |
| Agent | Assistant | Assistant = aide a la demande. Agent = mandat structure et persistant. |
| Skill | Base de connaissance | Skill au sens Anthropic = format standard, injectable, traceable. |
| Registre | Note | Registre implique structure + index + revision. Note = volatil. |
| Revision (J+90) | Update / mise a jour | Revision implique relecture critique de la decision, pas juste edition. |

## Decisions

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| Decision structurante | Choix important | "Structurante" = qui change la structure du systeme. Plus precis. |
| BDR / ADR | Note de decision | Format standard, sigle reconnu, indexable. |
| Statut Active / Revisee / Abandonnee | Ouvert / Ferme | Cycle de vie clair, pas binaire. |
| Revision prevue J+90 | TBD / a confirmer | Date explicite force le retour. |

## Cycle de travail

| Fork | Mot a privilegier | Mot a eviter |
|------|-------------------|--------------|
| DevFlow | Sprint | "iteration" (trop vague) |
| BusinessFlow | Sprint strategique | "trimestre" (trop long) |
| ContentFlow | Edition | "campagne" (deja utilise par GrowthFlow) |
| GrowthFlow | Experiment | "test" (trop generique) |
| DesignFlow | Iteration | "phase" (trop vague) |

## Production / livrable

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| Initiative (BusinessFlow) | "Projet" | Projet = container global. Initiative = unite d'execution. |
| Feature (DevFlow) | Fonctionnalite (sauf doc grand public) | "Feature" est devenu standard meme en francais. |
| Script (ContentFlow) | Contenu | Script = format structure, contenu = generique. |
| Campaign (GrowthFlow) | Action marketing | Campaign = unite executable mesurable. |

## Qualite

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| Verifier | Tester | Tester = approche logicielle. Verifier = couvre tous domaines. |
| Audit qualite cognitive | Audit IA | "Cognitive" pointe explicitement le risque d'hallucination. |
| Hallucination | "L'IA s'est trompee" | Hallucination = terme technique precis, decrit le phenomene. |
| Cas piegeux | Edge case | "Edge case" est dev-centric. "Piegeux" couvre tous les cas. |
| EVAL | Audit | EVAL = registre canonique. Audit = action ponctuelle. |

## Vocabulaire commercial / business

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| ICP (Ideal Customer Profile) | Cible / persona | ICP = critere binaire (in/out). Persona = portrait, plus flou. |
| Format de mission | Type de prestation | Format = structure repetable. Type = categorie. |
| Pipeline | Liste de prospects | Pipeline = flux avec etapes. Liste = inventaire. |
| Rollout | Lancement / mise en marche | Rollout = deploiement progressif et controle. |

## Mots a eviter universellement

| Mot | Pourquoi |
|-----|----------|
| **"Magique"** | Aucune dimension technique n'est magique. Si c'est magique, c'est qu'on n'a pas compris. |
| **"Solution miracle"** | Pareil. Toute solution a des conditions d'application. |
| **"Disrupter"** | Mot vide en 2026. Si on disrupte vraiment, on le decrit factuellement. |
| **"Synergique"** | Vague. Decrire l'interaction concretement. |
| **"Game-changer"** | Cliche corporate. Decrire le changement reel. |
| **"Best practices"** sans source | Si c'est best, citer la source. Sinon, c'est une opinion. |
| **"AI-powered"** dans des contextes ou ce n'est pas pertinent | Si c'est AI-powered, dire ce que ca change pour l'utilisateur. |
| **"Automatiser"** quand on parle d'agents | Agent != automatisation. Un agent decide ; une automation execute. |

## Vocabulaire v4.1 (rigueur execution)

| A privilegier | A eviter | Pourquoi |
|---------------|----------|----------|
| Verification fresh-evidence | "Presque OK" / "Ca a l'air bon" | Fresh-evidence = preuve produite dans la session courante. "Presque OK" est narratif, non decidable. |
| Exit code 0 | "Ca marche" | Exit code = critere binaire deterministe. "Ca marche" est interpretable. |
| Critere de succes binaire | Critere "qualitatif" implicite | Binaire = decidable. Qualitatif sans rubrique = source de derive. |
| Bootstrap-skill preloade | "Skill auto" / "Skill par defaut" | Bootstrap = charge au SessionStart via `bootstrap.md`. "Auto" est ambigu (declenchement runtime ou prechargement ?). |
| On-demand skill | "Skill optionnel" | On-demand = invoque selon situation (frontmatter ou match description). "Optionnel" sous-entend qu'on peut s'en passer  -  contre la 1% Rule. |
| Adversarial Plan-Review | "Review du plan" | "Review du plan" peut etre auto-review (echo chamber). Adversarial = explicitement 2 agents distincts en sessions fraiches. |
| HALT-X declenche | "Echec" / "Bug" | HALT = arret structure avec escalation. Echec/bug = sans protocole de reprise. |
| Convention fantome | "Convention deprecated" | Fantome = jamais executee (illusion). Deprecated = a existe puis abandonnee. |
| Charte de densite | "Limite de taille" | Charte = trio de seuils universels (250/500/2000) justifies par context rot. "Limite" sans justification empirique = arbitraire. |
| Context rot | "Le modele oublie" | Context rot = phenomene empirique mesure (Chroma 2025). "Oublier" est anthropomorphique. |
| Garde-fou meta runtime | "Best practice" frontmatter | Garde-fou = discipline de verification avant invention. "Best practice" sans test = opinion. |
| Iteration cap | "Boucle infinie" | Cap = limite explicite (typiquement 3). Boucle infinie = absence de limite = anti-pattern. |

## Em-dash et tirets longs

VibeFlow proscrit l'usage de l'em-dash (`—`) en redaction de documents methodologiques publics. Raison : l'em-dash est devenu un marqueur visuel d'IA generative, et il fragilise la perception de qualite humaine du contenu.

A privilegier :
- Tiret simple court : `-`
- Parenthese : `(...)` pour les apartes
- Deux-points : `:` pour les enumerations
- Phrase complete suivie d'une autre

## Note sur le francais

VibeFlow est nee en francais. Garder une orthographe correcte (accents, cedilles) est une regle de qualite — mais selon ton contexte technique (terminal sans support UTF-8, contraintes systeme), une version sans accents peut etre acceptable. Choisir une convention par fork et la documenter en BDR.
