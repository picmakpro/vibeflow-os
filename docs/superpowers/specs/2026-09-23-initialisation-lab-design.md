# L'initialisation d'un lab

> **Statut** : conception cadrée, **pas encore inscrite à la feuille de route**. Cette note est
> l'entrée du cadrage, elle ne le remplace pas.
> **Arbitrages** : Willy, session principale, **2026-09-23** — AskUserQuestion pour l'interlocuteur,
> messages de validation pour le reste (§2). Après passe adversariale (§15) : plancher du mode express
> tranché par Willy (AskUserQuestion, 2026-09-23) ; trois arbitrages délégués par Willy (« à toi de
> trancher », même canal, même date) et tranchés par l'agent — C-07 précisée, C-15, C-16.
> **Origine** : l'initialisation actuelle (`/vf-new-lab`) doit devenir un moteur de cadrage « sans
> aucun trou », capable de partir de zéro comme d'un existant riche, et de préparer le branchement
> futur d'une base de connaissance interrogeable (FileFlow).
> **Dépend de** : `2026-09-22-moteur-planning-metier-design.md` (ce que l'initialisation doit
> produire) et `2026-09-22-fabrique-agents-skills-design.md` (comment elle le fabrique).

---

## 1. Diagnostic — ce que fait `vf-new-lab` v2.64.0

### 1.1 Ce qui existe déjà, et qui est bon

Une **grille** de huit sections canoniques — problème, métier, parties prenantes, périmètre,
processus et livrables récurrents, contraintes, définition de « fini », gates métier et evals —
chacune avec un critère de clôture. Un
**marqueur binaire** `[À CLARIFIER: …]`, choisi contre le score flottant par comparaison explicite
avec BMAD, spec-kit et Kiro. Un **menu de méthodes d'élicitation** emprunté à BMAD. Un **mode
express** à trois questions. Et un dernier gate, le Gate C, qui appelle de vrais scripts avec de
vrais codes de sortie — même si c'est encore l'agent qui les lance et lit leur verdict, et que sa
troisième vérification est un simple `grep`.

Les fondations sont justes. Ce qui manque, c'est qu'elles soient tenues.

### 1.2 Ce qui est de la prose déguisée

L'étiquette « machine-enforced » du **Gate A est fausse**, et le Gate B, qui ne la revendique pas,
repose sur le même mécanisme. Le gate est une commande `grep` que **l'agent tape, lit et interprète
lui-même** ; aucun harnais ne consomme son code de sortie — hors des `.md`, seule la suite de tests
mentionne ces marqueurs —, et c'est l'agent qui pose puis retire ses propres marqueurs. Deux trous
techniques, rejoués, aggravent le tableau : **un fichier absent sort `2` avec un stdout vide,
indiscernable d'un gate franchi** pour un agent qui compte les lignes de stdout (l'erreur part sur
stderr) ; et **un marqueur que la regex ancrée ne voit pas passe inaperçu** — item de liste `-`, `*`
ou numéroté, citation `>`, gras, espace avant les deux-points, `A` sans accent. Le schéma du
manifeste cumule les deux derniers défauts : son statut est en item de liste, en milieu de ligne et
sans deux-points, donc hors de portée de son propre `grep`, contrairement à la « même forme ancrée »
que promet la doctrine du gate. Le `SKILL.md` affirme enfin que le Gate A express détecte
`[DÉRIVÉ — à affiner]` : son `grep` ne cherche que `[À CLARIFIER:`.

S'y ajoutent : **aucun plafond de questions** en mode normal — le menu d'élicitation se ré-affiche jusqu'à la
sortie ; un scan brownfield et une critique de complétude délégués à des agents `explorer` et
`reviewer` **qu'aucun module n'installe** ; des auditeurs conçus à l'étape 6 que **l'étape 7 ne
matérialise jamais** ; et une promesse du mode express — `/vf-calibrate` reprendrait chaque case
`[DÉRIVÉ — à affiner]` — que `vf-calibrate` ne tient pas.

La suite de tests (`test-vf-new-lab.sh`, 21 assertions statiques, dont 19 de présence de phrase)
vérifie **le texte du `SKILL.md`**, jamais qu'un gate refuse ; elle ne couvre que le mode express.

### 1.3 Ce qui contredit les décisions déjà prises

L'étape 7.5bis fabrique, dès deux agents métier (sauf quand le métier est le code), **un
orchestrateur paramétré au métier** — contraire
à la règle qui réserve l'initialisation aux producteurs et aux juges. Le gabarit `business-agent`
qu'elle utilise est **pensé pour le développement** (« Spawn par le lead quand une decision
technique… », « TU NE CODES JAMAIS ») — en contradiction avec le « NE PRÉSUME JAMAIS dev » du skill
lui-même. Et la taxonomie savoir / compétence / procédure du manifeste
est proche des trois natures de skill, mais **aucune nature n'ouvre une phase de planning**.

---

## 2. Décisions

- **C-01 — « 100 % » veut dire complétude interne : aucune case sans disposition.** La complétude
  d'une spécification vis-à-vis du monde réel n'est évaluable que **relativement à une connaissance du
  domaine, elle-même faite d'hypothèses sur le monde** (Zave & Jackson 1997 ; Zowghi & Gervasi 2003) ;
  seule la complétude interne se vérifie par machine. Chaque case porte donc une
  disposition parmi quatre : `RENSEIGNÉ`, `HORS-PÉRIMÈTRE`, `HYPOTHÈSE`, `DIFFÉRÉ`. Promettre
  davantage reproduirait le faux sentiment de complétude reproché au spec-driven development.
- **C-02 — La grille est déduite de ce qu'il faut fabriquer.** Aucune case sans usage, aucun élément
  du lab sans case d'origine (§5).
- **C-03 — Architecture hybride en trois temps** : calibrer, inventorier l'existant, remplir la
  grille depuis trois sources (§4).
- **C-04 — Le calibrage porte sur deux axes**, maîtrise du métier et maîtrise de l'IA, **déduits de
  questions factuelles**, jamais d'une auto-évaluation.
- **C-05 — Le contrat du « fait sourcé » est figé maintenant.** Son statut — constaté, inféré,
  déclaré — dépend de la provenance, jamais d'un score de confiance (§8).
- **C-06 — Le protocole d'interview suit la recherche** : récit d'abord, cas concrets pour les cases
  décisives, un seul pré-mortem, arrêt déterministe (§6).
- **C-07 — Aucune option « recommandée » pendant le recueil.** La recommandation vient après le
  choix de l'utilisateur, ou sur sa demande. C-07 vise le **choix entre plusieurs options** ; un fait
  cité ou une proposition unique restent permis, sous les conditions de §4 et de C-13.
- **C-08 — La frontière d'un lab est un objectif autonome** ; ce qui est lié sans être le même
  objectif devient un lab emboîté (§7).
- **C-09 — Le savoir volumineux va dans un cerveau interrogeable, pas dans les skills.**
- **C-10 — Le `CLAUDE.md` vit à la racine du lab**, `./CLAUDE.md` (§9).
- **C-11 — Au lancement, seulement ce qui vaut pour toute session.** Un `@import` ne décharge rien
  (§9).
- **C-12 — L'initialisation ne fabrique que des producteurs et des juges.** L'orchestrateur métier
  par lab est supprimé (§10).
- **C-13 — Les contrôles humains se déduisent des livrables** et sont présentés comme une
  proposition — un débutant ne sait pas encore ce qu'il voudra contrôler, mais il sait réagir à une
  proposition. Elle ne se valide **jamais d'un geste** : l'utilisateur dit, pour chaque contrôle, ce
  qu'il garde, retire ou change. C'est le profil le plus exposé à l'effet de défaut.
- **C-14 — Les gates de la grille sont exécutés par un script**, jamais par l'agent qui remplit la
  grille.
- **C-15 — La nature d'un skill suit B-03**, que l'initialisation ne redéfinit pas : elle pose les
  trois marqueurs de B-03 comme des questions factuelles, et « outil » reste la valeur par défaut.
- **C-16 — L'initialisation prépare la preuve de chaque juge, sans l'exécuter** : une sortie piégée
  tirée de l'exemple raté ; le canary du moteur la joue au premier cycle (B-01).

---

## 3. Ce que « sans aucun trou » veut dire

| Disposition | Sens | Exigence pour être valide |
|---|---|---|
| `RENSEIGNÉ` | la case est remplie | un critère d'acceptation, et sa source |
| `HORS-PÉRIMÈTRE` | exclue volontairement | le motif |
| `HYPOTHÈSE` | supposée — y compris une case déduite et pas encore validée | qui l'a posée, et comment la vérifier |
| `DIFFÉRÉ` | reportée | un responsable, et une condition de révision |

La famille 0, l'interlocuteur, règle le moteur et ne fabrique rien : ses cases portent une
disposition comme les autres, mais elle est **exemptée du gate 2** (§5.4).

Une case `HYPOTHÈSE` ou `DIFFÉRÉ` n'est pas un échec : c'est un **trou nommé**. Ce qui est interdit,
c'est le trou silencieux. La pratique confirme ce principe en dehors de ce dépôt : les meilleurs
outils tracent leurs hypothèses (section *Assumptions* de spec-kit, balises `[ASSUMPTION: …]` de
BMAD récapitulées dans un index), reportent explicitement (le *Waiting Room* de Volere, où chaque
exigence reportée porte sa version cible — le responsable est un ajout de cette spec) et déclarent
une absence plutôt que de l'inventer (`skip_specs` d'OpenSpec : *« Do not invent a requirement just
to satisfy validation. »*).

---

## 4. L'architecture en trois temps

```
1. QUI ÊTES-VOUS ?        calibrage — maîtrise du métier × maîtrise de l'IA,
                          déduit de faits : « Vous utilisez déjà un assistant IA ? Pour quoi ? »

2. QU'AVEZ-VOUS DÉJÀ ?    inventaire de l'existant — quatre cas
      rien                  → le récit
      quelques documents    → lecture, en vérifiant avec l'utilisateur lesquels comptent
      un gros volume        → proposition de FileFlow
      FileFlow en place     → interrogation de la base

3. REMPLIR LA GRILLE      depuis trois sources, dans cet ordre
      l'existant            → cases « constaté » (citées) ou « inféré » (à confirmer)
      le récit              → « Racontez la dernière fois que vous avez… »
      les questions         → UNIQUEMENT sur ce que les deux premières n'ont pas couvert
```

**L'existant pré-remplit, il ne valide jamais seul.** Une case remplie par un document est présentée
avec sa citation et se valide d'un geste — la source est sous les yeux de l'utilisateur, ce n'est
pas une option recommandée (C-07) ; une case inférée est présentée comme hypothèse et doit être
confirmée explicitement. Le biais de défaut résiduel de la validation d'un geste est nommé en §12.

**Pourquoi le calibrage vient en premier.** L'*effet de renversement dû à l'expertise* est mesuré :
ce qui aide un novice gêne un expert, et inversement. Un expert métier novice en IA reçoit des
questions ouvertes sur son métier — il détient la vérité — et des options toutes faites sur l'IA —
il ne connaît pas l'espace des possibles. L'inverse pour le profil opposé. L'auto-évaluation
(« êtes-vous débutant ? ») est écartée : elle est notoirement peu fiable.

**Pourquoi l'existant vient avant le récit.** Une personne qui arrive avec ses offres, ses
transcriptions ou ses notes ne doit pas être interrogée comme si elle partait de zéro — c'est le
principe *« On ne demande JAMAIS ce que le projet dit déjà »* que `vf-new-lab` affiche déjà pour le
brownfield, sans le tenir.

---

## 5. La grille

### 5.1 Dix familles, chacune reliée à ce qu'elle fabrique

| # | Famille | Fabrique | Remplie d'abord par |
|---|---|---|---|
| 0 | **L'interlocuteur** | *rien dans le lab* — règle le moteur | deux questions factuelles |
| 1 | **La raison d'être** | `PROJECT.md`, le « pourquoi » du `CLAUDE.md`, **le nombre de labs** | le récit |
| 2 | **Les livrables** | les producteurs, leurs `ecrit:`, les procédures, la sortie piégée de chaque juge (C-16) | le récit, l'existant |
| 3 | **La qualité** | les juges et leurs rubriques | des cas concrets |
| 4 | **Le savoir du domaine** | les référentiels | l'existant |
| 5 | **L'organisation du travail** | les cycles et cycles récurrents | le récit |
| 6 | **Les contrôles humains** | les gates humains, le droit de dérogation | **déduite des livrables**, puis amendée case par case (C-13) |
| 7 | **Les contraintes** | les contraintes de `PROJECT.md`, des constats de juge | l'existant, des questions |
| 8 | **Les données** | la zone d'ingestion, le `.gitignore`, la sensibilité, l'aiguillage vers FileFlow | l'inventaire |
| 9 | **Les risques** | les critères d'échec | un pré-mortem |

### 5.2 Le détail qui compte

**Famille 1 — La raison d'être.** Le problème actuel avec un exemple ; l'objectif **mesurable** ;
pour qui ; **au moins trois exclusions**. Et elle porte le **test d'autonomie** de §7 : c'est elle
qui décide s'il faut un lab ou plusieurs.

**Famille 2 — Les livrables.** Elle se démultiplie : une sous-grille par livrable.

| Case | Fabrique |
|---|---|
| destinataire | le ton et le format du producteur |
| déclencheur | le point d'entrée de la procédure |
| **un exemple réussi et un exemple raté** | la rubrique du juge, et la sortie piégée qui la prouve (C-16) |
| fréquence | ponctuel → cycle · récurrent → cycle récurrent |
| lieu de vie — le dossier client, par exemple | le `ecrit:` |
| **les trois marqueurs de B-03** — un gate bloquant ? un livrable remis à un tiers ? une couche de qualité ? | au moins un → **procédure** · aucun → outil, la valeur par défaut |

La dernière case pose **en questions factuelles** les marqueurs que la spec de la fabrique utilise
pour détecter une procédure (C-15) : la réponse de l'utilisateur est du déclaré, pas une dérivation
automatique, et la détection de dérive de B-03 continue de veiller ensuite. Aucun plafond de livrables : un lab qui en a beaucoup n'est pas un problème s'ils servent
tous le même objectif (§7).

**Famille 3 — La qualité.** Les critères **objectifs** — ce qui se constate — deviennent les
constats **bloquants** du juge ; les critères de **jugement** — ton, style — un score **enregistré
mais non bloquant**. C'est D-02 du moteur, rangée parmi ses décisions amendées, remplie dès
l'initialisation. Plus : ce qui ne
doit **jamais** sortir, et le seuil d'acceptation.

**Famille 8 — Les données.** Ce qui existe ; où ; **quel volume** — c'est cette case qui déclenche la
proposition de FileFlow ; la sensibilité ; ce qui ne doit jamais être versionné.

### 5.3 L'ordre de passage

La fatigue d'un questionnaire est **positionnelle** : plus il avance, plus les réponses deviennent
courtes et uniformes, et plus les non-réponses se multiplient (Galesic & Bosnjak 2009). Parmi les cases de la grille, quatre passent donc
en tête — après le calibrage et l'inventaire, avant tout le reste : **l'objectif mesurable, la liste des livrables, le critère de réussite, le critère
d'échec.**

Le **mode express** en découle : ces quatre cases, **plus le plancher complet** du critère d'arrêt
(§6) — le récit d'ancrage, le pré-mortem, qui remplit le critère d'échec, et la validation du
récapitulatif. Tout le reste est écrit dans le lab en `HYPOTHÈSE` — visible, révisable — au lieu
d'être deviné en silence. Le mode express actuel, à trois questions, passe donc à quatre cases plus
le plancher (§11).

### 5.4 Les trois gates, exécutés par script (C-14)

1. **Aucune case sans disposition.**
2. **Aucune case sans usage** — chaque case remonte à un élément à fabriquer. La famille 0 en est
   exemptée par déclaration explicite dans le schéma de la grille, pas par le jugement du script.
3. **Aucun élément sans case** — chaque agent, skill ou cycle fabriqué remonte à au moins une case.
   Un agent sans case d'origine est un agent inventé.

Le script **ne compte pas les marqueurs dans les blocs de code** : c'est exactement le défaut qui
bloque à tort l'implémentation chez spec-kit, où des cases à cocher d'exemple dans un bloc de code
sont comptées comme des tâches ouvertes (issue #4272). Il traite **explicitement** le fichier
absent comme un refus, et il lit les dispositions **quel que soit leur format de ligne**, item de
liste compris.

---

## 6. Le protocole d'interview

**Ancrage — un récit, pas un questionnaire.** La première vraie question est : *« Racontez-moi la
dernière fois que vous avez [fait cette activité], du début à la fin. »* C'est la preuve la plus
solide du corpus : l'**entretien cognitif** obtient nettement plus de détails corrects que
l'interrogatoire classique (méta-analyse de 42 études, ~2 500 personnes, d = 0,87 ; Köhnken et al.
1999), au prix d'une légère hausse des erreurs mais à taux de précision inchangé (85 % contre 82 %)
— résultat répliqué par Memon et al. en 2010. Le récit pré-remplit la grille, et **rien de ce
qui a été dit n'est redemandé**.

**Relances — une question à la fois, sur la case vide la plus prioritaire.** Des « comment » et des
« dans votre cas », jamais des « pourquoi » — qui produisent des rationalisations — ni des « vous
utiliseriez… ? » — qui produisent des opinions sur le futur. Le chatbot à questions ouvertes produit
des réponses significativement plus informatives et spécifiques qu'un sondage en ligne classique
(Xiao et al. 2020).

**Cas concrets pour les cases décisives.** Un utilisateur peut **énoncer une règle, puis la
contredire face à un cas concret** : dans GATE (Li et al., ICLR 2025), un participant pose qu'une
adresse doit finir par .com ou .co.uk, puis accepte une adresse en .edu. C'est une anecdote
rapportée par l'étude, pas une mesure — elle illustre le risque plus qu'elle ne le chiffre. Pour le critère d'échec et l'autonomie tolérée, on ne demande donc pas la
règle : on montre un exemple, et on demande *« ça, vous l'acceptez ? »*.

**Arbitrages à options connues — un QCM, sans option recommandée en tête (C-07).** L'effet de
défaut est robuste : dans des choix risqués à quatre options équivalentes, 38 à 39 % des
participants retiennent l'option pré-sélectionnée, contre 25 % attendus au hasard (*Scientific
Reports*, 2025). Et un assistant qui recommande **déplace les opinions** de l'utilisateur, pas
seulement ses réponses (Jakesch et al., CHI 2023, N = 1 506). **La description de l'outil
`AskUserQuestion` recommande l'inverse** — *« make that the first option in the list and add
"(Recommended)" »* : c'est un endroit où VibeFlow doit s'écarter de son outil.

**Hypothèses explicites.** Tout ce que le moteur remplit sans réponse directe est affiché comme
hypothèse et **nommé** dans un récapitulatif unique à valider. La mesure qui l'impose : interrogés
explicitement, les modèles reconnaissent l'ambiguïté dans 60 à 80 % des cas, mais en usage normal ils
posent une question de clarification dans **0 à 5 %** des cas (Su & Cardie, arXiv:2605.25284,
2026). Laissé à lui-même,
le moteur devine.

**Un seul pré-mortem, en fin de parcours** : *« Dans trois mois, ce lab a échoué. Pourquoi ? »* C'est
la méthode d'élicitation la mieux étayée : imaginer l'issue comme **certaine** fait produire environ
30 % de raisons en plus (Mitchell et al. 1989) — d'où la formulation au passé, « a échoué », et non
« pourrait échouer » —, et le pré-mortem réduit la surconfiance davantage que la critique classique
(Veinott et al. 2010). Pas de menu d'angles au choix : pour les autres méthodes du menu BMAD, aucune
évaluation publiée n'a été trouvée au 2026-09-23, et un menu ajoute une charge de décision.

**Critère d'arrêt — déterministe, combiné.** Arrêter dès que **(A) ou (B)**, jamais avant **(C)** :

- **(A) Couverture** : toutes les cases prioritaires sont `RENSEIGNÉ` ou `HYPOTHÈSE` validée.
- **(B) Saturation ou budget** : les deux dernières réponses n'ont changé aucune case, ou le budget
  maximal est atteint.
- **(C) Plancher** : l'ancrage, le pré-mortem et la validation du récapitulatif sont faits.

C'est un **choix de conception** : ce critère est déterministe, alors que les alternatives
reposent sur une confiance auto-déclarée par le modèle, et les LLM sont mesurés surconfiants quand
ils verbalisent leur confiance (Xiong et al., ICLR 2024). Structurer l'incertitude en cases paie
aussi : SAGE-Agent (ACL 2026) atteint son résultat avec **1,5 à 2,7 fois moins de questions** que
des baselines par prompting ou par incertitude — mesuré sur des paramètres d'outils, pas sur un
cadrage métier.

**Les salves successives ont une limite.** Une quatrième ou cinquième salve ne ferme pas les trous :
elle les remplit de bruit, parce que l'utilisateur fatigué répond pour en finir. À l'arrêt, les cases
restantes passent en `HYPOTHÈSE` ou `DIFFÉRÉ`, visibles.

---

## 7. La frontière d'un lab : un objectif

**Un nouveau lab, c'est un nouvel objectif — pas un nouveau métier, ni un nombre de livrables.**
BusinessFlow contient un commercial, un juriste, un financier : plusieurs métiers, **un seul
objectif**, faire tourner le business. Ils forment un tout. Ses erreurs de structure — son
compartiment de formation, par exemple — ne sont pas des erreurs de taille : ce sont **des objectifs
différents** logés au même endroit.

**Le test d'autonomie**, posé dès que le récit fait apparaître plusieurs finalités :

> *« Si l'objectif principal disparaissait, ce sous-objectif aurait-il encore un sens ? »*
> Non → même lab. Le juridique de BusinessFlow n'existe que pour le business.
> Oui → lab à part. Une formation a un sens pour son auteur seul, ou décorrélée de tout business.

**Ce qui est lié sans être le même objectif devient un lab emboîté** : un sous-dossier qui porte son
propre `.claude/`, sa mémoire, son planning et son objectif, à l'intérieur du lab parent. C'est le
modèle de Jarvis Keystone — une racine et des sous-labs, chacun avec son `.claude/` et son
`.planning/` — et ce que la décision D-05 du moteur autorise déjà.

**Un lab trop gros est un lab mal architecturé.** Répartir des milliers de pages de données dans des
skills confond le savoir et le savoir-faire. La recherche le mesure : des skills ciblés sur deux ou
trois modules battent des lots plus larges ou exhaustifs (SkillsBench, arXiv:2602.12670, 2026) ;
au-delà d'une certaine taille de bibliothèque, **la précision de sélection des skills s'effondre** —
une transition de phase où la confusabilité sémantique pèse plus que la taille seule (Li et al.,
arXiv:2601.04748, 2026) ; et **une seule phrase distractrice** sémantiquement proche suffit à
dégrader un modèle (Chroma, *Context Rot*, 2025). Le savoir
volumineux va donc dans un cerveau qu'on interroge (C-09).

---

## 8. L'existant et le pont FileFlow

### 8.1 Le fait sourcé

L'unité échangée entre l'initialisation et toute source de connaissance :

```
{ id, schema_version,
  sujet, predicat, valeur,
  statut: "constate" | "infere" | "declare",
  sources: [{ uri, localisateur, citation, sha256, date_document }],
  derive_de: [id],          # obligatoire si « infere »
  affirme_par: "utilisateur" | "agent:<nom>" | "import:<outil>",
  observe_le, valide_du?, valide_au?,
  remplace?: id, en_conflit_avec?: [id],
  sensibilite: "public" | "interne" | "personnel" }
```

Trois règles, toutes vérifiables par machine :

- **Un fait « constaté » sans citation retrouvable dans sa source est rétrogradé en « inféré ».** Le
  statut est structurel : il dépend de qui a produit l'affirmation et de la présence d'une citation,
  **jamais d'un pourcentage donné par le modèle** — les LLM sont mesurés surconfiants quand ils
  verbalisent leur confiance.
- **Seul l'utilisateur produit du « déclaré ».**
- **Une contradiction n'est jamais tranchée automatiquement** : elle produit un conflit ouvert, que
  seul un humain ferme.

La date du document est obligatoire. Aucun des outils d'ingestion étudiés ne lit la date **du
document** — au mieux, LlamaIndex et Unstructured posent la date du fichier sur le disque, qui n'en
dit rien ; sans elle, la plaquette de 2023 et l'offre de 2026 pèsent le même poids — et
l'information périmée est l'une des causes identifiées des conflits entre sources (Xu et al.,
EMNLP 2024).

### 8.2 Deux adaptateurs derrière le même contrat

- **Aujourd'hui** : l'initialisation lit elle-même les dossiers que l'utilisateur lui désigne, et
  produit des faits sourcés.
- **Demain** : elle pose la même question à FileFlow, qui renvoie des faits sourcés.

Le reste du moteur ne voit pas la différence. Le jour où FileFlow expose sa couche interrogeable, on
change la source, pas le moteur.

### 8.3 Ce que FileFlow est, et ce qu'il deviendra

FileFlow est aujourd'hui **un moteur de capture documentaire** — sur sa branche de travail, pas
encore publiée sur `main`, qui en est à la Phase 1 : chaque document extractible est extrait,
empreint, tracé jusqu'à sa source, filtré de ses secrets, marqué quand il contient des données
personnelles ; les autres sont comptés avec leur raison. Il ne dispose pas encore de couche
interrogeable. Sa **Phase 5** la prévoit dans les termes qu'exige ce contrat :

> *« L'utilisateur interroge sa base depuis Claude Code et reçoit des réponses citées, ou l'aveu
> honnête qu'aucune réponse pertinente n'existe […] »*

Chaque affirmation cite sa source ; l'absence est avouée plutôt que comblée. FileFlow porte déjà la
bonne doctrine.

**Point de compatibilité à préserver.** FileFlow interdit au modèle de lire le contenu d'un document
**en Phase 2, celle du stock brut** (décision `P2-D-12`) : c'est une frontière de la phase
d'ingestion, pas une interdiction de consulter la base. Le pont passe par la couche interrogeable de
la Phase 5, jamais par une lecture du stock brut. Et FileFlow retient la voie « skills + scripts +
binaires » plutôt qu'un serveur MCP (INV-06) : le branchement passera par un skill ou un script,
que FileFlow n'a pas encore spécifié.

### 8.4 Quand proposer FileFlow

La case « volume » de la famille 8 le décide. Quelques documents : lecture directe. Un catalogue, une
base documentaire, des centaines ou des milliers de pages : proposition de FileFlow, local ou Drive.
Une base FileFlow déjà en place : interrogation.

### 8.5 Les données sensibles dès le premier geste

L'initialisation crée elle-même une zone brute **gitignorée par défaut**. Une donnée commitée dans
git est très difficile à retirer : selon la documentation de GitHub, elle reste accessible dans les
clones et les forks, dans les vues en cache par empreinte, et par les pull requests qui la
référencent. Dans
les documents versionnés, des références plutôt que des identités. Le champ `sensibilite` du fait
sourcé est obligatoire.

---

## 9. La cartographie du contexte

### 9.1 Le `CLAUDE.md` vit à la racine (C-10)

La documentation officielle de Claude Code : *« A project CLAUDE.md can be stored in either
`./CLAUDE.md` or `./.claude/CLAUDE.md`. »* Les deux sont équivalents. **La racine est retenue** :
tous les labs existants l'utilisent déjà — BusinessFlow, Keystone, AVMA, et ce dépôt ; elle est
lisible hors de Claude Code ; et elle sépare la constitution, lue par un humain, de la machinerie
exécutée par le harnais dans `.claude/`.

**Conséquence pour les labs emboîtés** : *« CLAUDE.md and CLAUDE.local.md files in the directory
hierarchy above the working directory are loaded at launch. Files in subdirectories load on demand
when Claude reads files in those directories. »* Depuis un lab
enfant, le `CLAUDE.md` du parent est donc **toujours** chargé : il doit rester court et ne porter que
ce qui vaut pour tous ses enfants.

### 9.2 `@import` range, il ne décharge pas (C-11)

`vf-new-lab` pose aujourd'hui un `CLAUDE.md` court qui pointe vers la doc par `@docs/…`, dans
l'intention de soulager le contexte. La documentation officielle :

> *« Imported files are expanded and loaded into context at launch alongside the CLAUDE.md that
> references them. »*
> *« You can also split content into imports for organization, though imported files still load and
> enter the context window at launch. »*

**Un import est chargé à chaque session**, comme s'il était écrit dans le `CLAUDE.md`. L'externali-
sation actuelle est de l'organisation, pas de l'économie de contexte.

### 9.3 La carte

| Mécanisme | Chargé | Réservé à |
|---|---|---|
| `CLAUDE.md` du lab | **toujours** | ce qui vaut pour toute session — moins de 200 lignes |
| `CLAUDE.md` des labs parents | **toujours** | ce qui vaut pour tous les enfants |
| `@import` | **toujours** | l'organisation, jamais l'économie |
| `.claude/rules/` sans `paths` | **toujours** | les règles impératives transverses |
| `.claude/rules/` avec `paths` | à la demande, à la lecture d'un fichier correspondant | les règles d'un dossier ou d'un type de fichier |
| `CLAUDE.md` d'un sous-dossier | à la demande | le contexte d'un compartiment |
| skills | description toujours, corps à la demande | le savoir-faire |
| doc mentionnée **sans** `@` | à la demande, si l'agent la lit | le savoir détaillé |
| index du planning | injecté par hook | la carte des cycles |
| cycle, phase | injection sélective | le travail en cours |
| FileFlow | par requête | le savoir volumineux |

**La règle : ce qui est chargé au lancement doit valoir pour toutes les sessions ; tout le reste passe
à la demande.** La recherche la conforte : les fichiers de contexte augmentent le coût d'inférence de
plus de 20 % sans gain de réussite ; leurs **instructions** sont bien suivies, mais leurs **vues
d'ensemble du dépôt** n'aident pas (Gloaguen et al., ETH, arXiv:2602.11988, 2026). Au lancement, des
règles ; le savoir, à la demande.

La documentation officielle le dit aussi : *« target under 200 lines per CLAUDE.md file. Longer files
consume more context and reduce adherence. »* Le plafond de 150 lignes que `vf-new-lab` prescrit —
en prose seulement, aucun script ne le compte — est donc cohérent, mais il ne sert à rien si le
reste est importé.

---

## 10. Ce que l'initialisation fabrique

**Elle ne fabrique que des producteurs et des juges** (C-12). Les agents qui cadrent, planifient,
contrôlent un plan ou orchestrent une phase sont génériques et livrés par le plugin. L'étape 7.5bis
actuelle, qui fabrique un orchestrateur paramétré au métier dès deux agents, est **supprimée**.

La recherche soutient ce partage. Toutes les fabriques qui revendiquent un gain mesuré **génèrent
contre un score** ; les autres laissent la validation au lint. Et les skills générés par le modèle
sans matière réelle **n'apportent aucun gain en moyenne** — contre +16,2 à +16,6 points selon la
version du papier pour des skills curés par des humains (SkillsBench, 2026), qui en conclut que les
modèles ne savent pas écrire de façon fiable le savoir procédural dont ils profitent. D'où la
règle :

- **Remplir** : la structure de chaque agent — frontmatter, sections, contrat de sortie, format de
  verdict — depuis un gabarit. Seul le **frontmatter** est testé par un contrôleur, et seulement
  quand la PR #85 (ouverte au 2026-09-23) sera fusionnée ; les sections restent hors contrôle,
  conformément à B-01, qui écarte la validation de la structure du prompt.
- **Générer** : le contenu des référentiels — critères, rubrique, exemples, glossaire, cas d'échec —
  **extrait de l'interview et des documents réels**, jamais écrit « de tête ».
- **Préparer la preuve** (C-16) : pour chaque juge, l'initialisation fabrique une sortie
  volontairement mauvaise, tirée de l'exemple raté de la famille 2. Elle ne l'exécute pas — B-01 a
  écarté la validation par exécution — ; le canary du moteur la joue au premier cycle, et un juge qui
  ne la refuse pas est signalé. Un juge qui laisse tout passer est le mode d'échec le plus coûteux
  d'un système multi-agents.

Le gabarit `business-agent`, pensé pour le développement, est remplacé par un gabarit métier.

---

## 11. Correctifs du `vf-new-lab` actuel

| Défaut | Correction |
|---|---|
| Gates A et B exécutés par l'agent | un script qui sort un code, conformément à C-14 |
| fichier absent indiscernable d'un gate franchi | le fichier absent est un refus explicite |
| marqueur en item de liste non détecté | lecture des dispositions quel que soit le format de ligne |
| schéma du manifeste hors de portée de son gate | schéma aligné sur le script |
| aucun plafond de questions | budget + saturation + plancher (§6) |
| mode express à trois questions | quatre cases + le plancher complet (§5.3) |
| marqueur `[DÉRIVÉ]` que le Gate A ne voit pas | dispositions lues par le script (C-14) |
| agents `explorer` et `reviewer` inexistants | l'agent natif `Explore`, ou un agent livré par le plugin |
| auditeurs conçus mais jamais matérialisés | une étape de matérialisation, vérifiée par le gate 3 |
| promesse express non tenue par `vf-calibrate` | `vf-calibrate` reprend les cases `HYPOTHÈSE` et `DIFFÉRÉ` |
| orchestrateur métier par lab | supprimé (C-12) |
| gabarit `business-agent` pensé pour le développement | gabarit métier |
| tests qui vérifient des phrases, en mode express seulement | tests qui prouvent qu'un gate refuse, dans les deux modes |
| externalisation par `@import` | cartographie du contexte (§9) |

---

## 12. Ce qui reste une conjecture

La recherche a été honnête sur ses limites ; cette spec doit l'être aussi.

1. **La taxonomie de la grille et ses priorités.** Aucune étude ne la fournit pour des labs métier —
   le terrain est quasi vide : les rares déclinaisons non logicielles des outils de spécification
   portent sur l'écriture créative. Elle est **déduite** des deux specs précédentes, et doit être
   calibrée sur les labs existants.
2. **Les seuils du critère d'arrêt** — deux réponses sans changement, la valeur du budget — sont des
   transpositions d'études menées sur des sessions de cinq à quinze minutes.
3. **Le mode express ne garantit aucune qualité minimale.** Il garantit seulement la **traçabilité**
   de ce qui n'a pas été validé.
4. **Les chiffres des études d'élicitation par LLM** sont pour la plupart obtenus avec des
   utilisateurs **simulés par LLM**, dont une étude de 2026 mesure qu'ils sont de mauvais proxys des
   vrais. Ce sont des ordres de grandeur, pas des garanties.
5. **Supprimer l'option recommandée** est déduit de la littérature sur l'effet de défaut ; son effet
   sur `AskUserQuestion` n'est pas mesuré. Un A/B interne serait la mesure à faire.
6. **Le pré-mortem** réduit la surconfiance et fait émerger plus de raisons ; qu'il découvre plus de
   *vrais* trous dans un cadrage de lab n'est pas mesuré.
7. **La validation d'un geste d'une case citée** garde un biais de défaut résiduel : C-07 l'écarte
   pour les choix entre options, pas pour un fait sourcé présenté seul. Le même A/B que pour le point 5
   le mesurerait.

---

## 13. Hors périmètre

La couche interrogeable de FileFlow elle-même, qui relève de sa propre feuille de route (Phase 5). La
veille automatique, qui aura sa spec. La restructuration de BusinessFlow-Lab — l'extraction de ses
compartiments produits et formation en labs emboîtés ou séparés —, qui sera le premier cycle cadré
par ce moteur plutôt qu'une partie de sa conception.

---

## 14. Next step

Relecture humaine, puis plan d'implémentation, en commençant par C-14 : le script des trois gates de
la grille — c'est lui qui transforme l'actuelle prose déguisée en garantie, et c'est la condition de
tout le reste.

---

## 15. Passe adversariale — 2026-09-23

Quatre auditeurs indépendants ont rejoué les 72 affirmations de la version 1, avec la consigne
« infirmer ; pas de preuve reproductible = infirmé » : le code de `vf-new-lab` sur `main` v2.64.0
(20 affirmations), les citations académiques (19), les citations de documentation et d'outils (16),
les labs réels, FileFlow et la cohérence avec A et B (17). **Aucune thèse de fond n'est renversée** ;
les corrections portent sur la précision.

- **Infirmées** : deux affirmations sans source — le « seul critère d'arrêt déterministe », devenu un
  choix de conception, et le décalage temporel « cause principale » des conflits, devenu « une des
  causes » ; une citation de FileFlow tronquée sans ellipse ; le contrôleur des gabarits présenté
  comme en service alors que la PR #85 est ouverte et ne teste que le frontmatter.
- **Nuancées** : l'entretien cognitif (les erreurs augmentent aussi, le taux de précision reste
  stable) ; GATE (un seul participant) ; Chroma (une phrase, pas un document) ; Gloaguen (les +20 %
  portent sur les fichiers de contexte en général) ; Zave & Jackson (complétude relative, pas
  invérifiable) ; le Waiting Room de Volere (pas de responsable) ; l'étiquette « machine-enforced »
  (Gate A seulement) ; le plafond de 150 lignes (prescrit, non imposé).
- **Contradictions structurelles levées** : la famille 0 contre le gate 2 (exemption déclarée) ; le
  mode express contre le plancher d'arrêt (plancher complet, arbitrage Willy) ; la case « qui en
  répond » qui déformait D-07 et contredisait B-03 (C-15) ; la preuve des juges contre B-01 (C-16) ;
  la validation d'une proposition contre C-07 (C-07 précisée, C-13 durcie).
- **Laissés ouverts, à confirmer par Willy** : le nombre de sous-labs de Keystone — `00-doctrine` n'a
  aucun agent et `_gabarit` est un gabarit — et le compartiment « création de produits » de
  BusinessFlow, qu'aucun dossier ne porte. La spec les cite désormais sans chiffre ni nom contestable.
