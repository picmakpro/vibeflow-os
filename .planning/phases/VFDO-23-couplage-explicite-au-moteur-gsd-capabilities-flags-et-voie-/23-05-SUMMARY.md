---
phase: 23-couplage-explicite-au-moteur-gsd
plan: 05
noeud: exec-05
statut: passed
date: 2026-08-04
---

# 23-05 — Voie unique d'invocation + le manager porte le cadrage (Lacune 5, A-1ter geste 2) Summary

Une voie dégradée accessible sans garde-fou (dispatch direct des agents nus de cycle, à égalité
avec le skill) est fermée sur les deux workers du module, et le cadrage passe du worker (qui n'a
pas d'outil de question) au manager — fermant à la racine, et non en périphérie, le trou qui
faisait dérouler tout un cycle en autonome sans que rien ne le signale.

Suite du module : **133 OK / 0 KO / 0 SKIP** (`bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`),
contre **120 OK / 0 KO / 0 SKIP** avant travaux. `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict`
sort en `0`, 7 warnings — **identique à la baseline mesurée avant la mission** (aucun warning
nouveau introduit).

---

## 1. Constat de la Tâche 0 — décision déjà tranchée, aucune question posée

Référence : `23-ARBITRAGES.md` §**A-13**, datée **2026-08-04**. Voie retenue : **(a)** — le geste
d'A-1ter (le manager porte le cadrage) est **maintenu**, seul son **motif** a été substitué avant
l'exécution de ce plan. Le motif était **déjà corrigé à la source** : rien n'a été demandé à
Samuel par cette tâche, et rien n'aurait dû l'être — l'arbitrage était clos.

**Contre-épreuve par mutation** (sur copie temporaire de `23-ARBITRAGES.md`, `mktemp -d` + trap,
mutant privé de l'encadré « MOTIF SUBSTITUÉ le 2026-08-04 ») :
```bash
awk '/MOTIF SUBSTITUÉ le 2026-08-04/{s=1} /Motif de remplacement, en vigueur depuis le 2026-08-04/{r=1} /## A-13 —/{a=1} END{...}' <copie mutée>
```
- Fichier réel → `rc=0`, les trois marqueurs (substitution, remplacement, arbitrage) présents.
- Mutant (marqueur de substitution retiré, vérifié différent par `cmp -s`, `rc=1` de `cmp`) →
  `rc=1` (`KO : marqueur(s) A-13 absent(s) — substitution=0 remplacement=1 arbitrage=1`).

Aucun fichier de `plugin/` n'a été modifié par cette tâche : `git status --porcelain` sur les six
chemins de `files_modified` a été capturé **avant** toute écriture (`/tmp/vf2305-t0-before.txt`,
vide) — confirmation triviale puisqu'aucune tâche 1-5 n'avait encore tourné à ce moment.

**Le motif retiré par A-13** (« il a `AskUserQuestion`, donc `--auto` n'a plus lieu d'être ») **n'apparaît dans aucun texte livré** par ce plan : vérifié par balayage final (`awk`) sur `mission-flow.md`
Pattern F, `vf-dev-manager.md` (décision + note de la §9 fermée) — aucune occurrence.

---

## 2. Point de vigilance appliqué — consigne conservatrice (à valider par le manager)

**Le mandat d'exécution de cette mission portait une consigne qui PRIME sur la lettre du plan, sur
un point précis** : le plan (§« Coût en lignes » et geste 2 de la Tâche 1) prescrit littéralement
d'écrire dans `vf-dev-manager.md` une formule du type « le cadrage est son geste, il l'exécute
**avec `AskUserQuestion`** ». Cette formulation littérale n'a **pas** été écrite.

**Forme retenue à la place**, conservatrice, vraie quelle que soit une décision future non tranchée
sur l'outillage du manager en sous-agent :

> « **Cadrage** : c'est TON geste, tu le portes toi-même — tu ne passes JAMAIS de mode
> d'enchaînement à cette brique (allowlist stricte : `GSD-PIPELINE.md` §9) ; si l'outil de
> question ne t'est pas fourni (repli D-09, §Entrée), tu remontes `human_needed`, jamais un retour
> au mode d'enchaînement. »

Cette forme ne fonde JAMAIS le geste sur la possession de l'outil (elle dit « il le porte » et
« si l'outil manque, repli D-09 »), contrairement à la lettre du plan qui aurait fondé le geste sur
« il a l'outil ». **Signalé ici pour le manager de mission** : si le plan exigeait strictement la
formulation littérale (fondée sur la possession de l'outil), c'est un écart assumé et documenté —
pas une omission. Le Pattern F de `mission-flow.md` (motif A-13 lui-même, imposé par le plan) suit
la même discipline et interdit explicitement de fonder le geste sur la possession de l'outil — les
deux textes sont donc mutuellement cohérents, même s'ils divergent de la lettre exacte du plan.

---

## 3. Densité des deux agents — mesures avant/après chaque tâche qui les touche

| Fichier | Baseline (avant ce plan) | Après Tâche 1 | Après Tâche 3 | Après Tâche 4 | Plafond ADR-029 |
|---|---|---|---|---|---|
| `vf-dev-manager.md` | 235 | **240** (geste 2 : décision Cadrage + renvoi Pattern F ; geste 3 : promesse post-datée refermée à budget neutre) | — (non touché) | **240** (gsd-planner retiré de `tools:`, 1 ligne modifiée, 0 ligne nette) | 250 |
| `vf-coder.md` | 102 | **87** (bloc Cadrage retiré intégralement, renumérotation, escalade + renvoi relocalisés vers §Garanties) | **90** (2 mentions résiduelles `gsd-executor` reformulées vers « le skill `gsd-execute-phase` », 1 phrase de doctrine « Voie unique » ajoutée à §Garanties) | — (non touché) | 250 |

**Marge consommée (manager)** : 15 lignes de marge à 235 ; 10 lignes de marge restantes à 240.
**Décision de déport** : NON prise — le brouillon de la décision (geste 2 de la Tâche 1) tenait
dans la marge mesurée (15 lignes disponibles, ~4 lignes nettes consommées après le refermage
budget-neutre du geste 3). Aucun renvoi supplémentaire n'a dû être déporté vers `mission-flow.md`
au-delà du renvoi d'une ligne déjà prévu par le plan.

**`vf-coder.md` strictement < sa mesure d'avant tâche** (90 < 102) : le bloc Cadrage a bien quitté
le fichier sans recopie compensatoire.

---

## 4. Retrait de `T25b` (Tâche 1, geste 6) — preuve d'ENSEMBLE, jamais un compteur

`T25b` (adjacence textuelle sur la brique Cadrage, `A-1bis`) est **sans objet** depuis que le
cadrage est porté par le manager et retiré dans le même commit que le portage (geste 2 de la
Tâche 1). Retiré : le bloc entier (en-tête de commentaire → ligne de verdict incluse), ses six
fixtures, ses quatre mutants et ses quatre variables propres.

**Résidu mesuré, croisé par deux méthodes** (`rtk proxy find plugin -type f` → liste matérialisée
non vide de 431 fichiers, puis `awk '/T25b/{...}'` croisé avec `rtk proxy grep -rn 'T25b' plugin/`,
les deux ensembles triés identiques — `comm -23` et `comm -13` vides) : **exactement 6 occurrences**,
toutes des **données de test** (ensemble B), aucune n'est un renvoi (ensemble A, 7 sites, tous
réécrits) :

1. Commentaire énonçant les prémisses mortes (`T25b présentés comme la mitigation`) — inchangé
   caractère pour caractère (`cmp -s` avant/après : identique).
2. `T33_MORTE_RE='T25b?([^0-9]|$)|survi[tv][^.]*session|persist|config[.]json'` — inchangée
   caractère pour caractère (`cmp -s` : identique).
3-5. Trois occurrences réparties sur DEUX fixtures `t33_fx_transit` (« T25b présenté comme la
   borne » et « les DEUX à la fois ») — prose ET verdict **inchangés** (`diff` : identique).
6. Mention de prémisse morte du libellé `ok` de `T33` (« persistance config.json, T25b comme
   borne ») — inchangée dans ce segment précis.

**Preuve d'ensemble du retrait** (geste 9), sur les libellés `ok`/`ko` **exécutés** (`avant.txt`
120 lignes non vide, `apres.txt` 119 lignes, capturés respectivement avant la première édition et
après la Tâche 1) :

`comm -23 avant.txt apres.txt` (**7 libellés retirés**, nommément) :
- `T25 (DISCRIMINANT) : 3 formes interdites détectées (…, 3 rédactions LICITES épargnées (Cadrage, …))`
- `T25 : flag d'enchaînement désarmé au démarrage + fermé par gate (Plan/Exécution interdits, Cadrage licite), …`
- `T25 atteinte : 3 brique(s) Plan/Exécution effectivement VUE(S) …`
- `T25 fermeture : 14 fichier(s) de doctrine balayé(s), … sur une brique Plan/Exécution`
- `T25 présence (2 agents) : vf-dev-manager.md et vf-coder.md prescrivent tous deux gsd_run, …`
- `T25b (A-1bis, dégazé A-1ter — DISCRIMINANT) : ADJACENCE TEXTUELLE mesurée …` (le libellé de T25b
  lui-même)
- `T33 (Lacune 3, …) : … 42 formulation(s)/mutant(s) FAUTIFS font rougir les sondes, 17 …`

`comm -13 avant.txt apres.txt` (**6 libellés nouveaux**, nommément) :
- `T25 (DISCRIMINANT) : 4 formes interdites détectées (…, Cadrage armé RETOURNÉ), 2 rédactions LICITES …, sur fichier RÉEL (M-P6 rouge, L-P2 vert)`
- `T25 : flag d'enchaînement désarmé au démarrage + fermé par gate (Plan/Exécution/Cadrage interdits), …`
- `T25 atteinte : 4 brique(s) Plan/Exécution effectivement VUE(S) …`
- `T25 fermeture : 14 fichier(s) de doctrine balayé(s), … sur une brique Plan/Exécution/Cadrage`
- `T25 présence (ÉGALITÉ D'ENSEMBLE) : exactement l'ensemble attendu {vf-dev-manager.md} …`
- `T33 (Lacune 3, …) : … 42 formulation(s)/mutant(s) FAUTIFS …` (même compteur à cette capture,
  Tâche 1 seule — la Tâche 2 fera monter ce compteur à 43 par la suite)

Net : 120 → 119 (une garantie fusionnée dans la nouvelle égalité d'ensemble, pas une perte de
couverture — le bénéfice migre vers `T25 présence` qui teste maintenant une relation plus forte).

**`O-15` soldé par péremption** (voie 3, recommandée) : la fixture `k` qui portait encore le
mensonge d'A-5 disparaît avec le bloc `T25b` qu'elle testait — ne pas rouvrir.

---

## 5. Le Cadrage reste GATÉ après le retrait de `T25b` (geste 5bis, T-23-05-13)

Le balayage de fermeture de `T25` (`T25_BRICK_RE`) est **élargi** pour reconnaître aussi
`**Cadrage**`, au même titre que `Plan`/`Exécution` — sans cet élargissement, ce plan aurait
supprimé la seule garde du Cadrage en croyant la rendre inutile (le défaut exact que `T-23-05-13`
nomme). La fixture `d` (bloc Cadrage portant `--auto`), jusqu'ici LICITE sous A-1bis, est
**RETOURNÉE** : elle doit désormais être détectée.

**Preuve DANS LES DEUX SENS, sur une COPIE RÉELLE de `vf-coder.md`** (pas seulement la fixture
synthétique) :

- **M-P6 (rouge)** — commande :
  ```bash
  { cat vf-coder.md; printf '\n3. **Cadrage** : invoque `gsd-discuss-phase --auto`.\n'; } > mutant.md
  cmp -s vf-coder.md mutant.md   # rc=1 : différent (confirmé)
  ```
  Verdict : détecté (`t25_forbidden_chain_hits` remonte `--auto`).
- **L-P2 (vert)** — même littéral (`--auto`), sous négation dans la MÊME clause :
  ```bash
  { cat vf-coder.md; printf '\n3. **Cadrage** : invoque `gsd-discuss-phase`. JAMAIS avec `--auto` : le manager cadre.\n'; } > mutant.md
  cmp -s vf-coder.md mutant.md   # rc=1 : différent (confirmé)
  ```
  Verdict : NON détecté (reste vert) — la négation sur le MÊME token que M-P6 est correctement
  épargnée.

Les deux libellés `ok` de `T25` qui annonçaient l'exception « Cadrage licite » ont été corrigés
**sur ce seul segment** (« 3 rédactions LICITES épargnées (Cadrage, …) » → « 2 rédactions
LICITES … » ; « Plan/Exécution interdits, Cadrage licite » → « Plan/Exécution/Cadrage
interdits »).

---

## 6. `T33` assertion E — ré-ancrée sur DEUX foyers (Tâche 1, geste 7)

Foyer 1 (bloc **Plan** de `vf-coder.md`) et foyer 2 (nouveau bloc **Cadrage** de
`vf-dev-manager.md`, geste 6) doivent CHACUN porter le renvoi `GSD-PIPELINE.md` et leur notion
propre (recherche pour le foyer 1, discipline de flags pour le foyer 2). Compteur d'atteinte
exact = 2, jamais un `OU`.

- **M-P3 (rouge)** — renvoi `GSD-PIPELINE.md` déplacé HORS du bloc Plan de `vf-coder.md`, tokens
  conservés ailleurs dans le fichier : contre-épreuve **embarquée** dans le code de l'assertion
  (`T33_MUT_CODER`), exécutée à chaque run — `cmp -s` confirme le mutant différent de l'original,
  et la suite (0 KO) atteste que E foyer 1 rougit sur ce mutant sans jamais faire échouer le run
  réel.
- **M-P4 (rouge)** — même mutation sur le bloc Cadrage du manager (`T33_MUT_DEVMGR`), même
  mécanique embarquée, même verdict (E foyer 2 rougit sur le mutant).
- **M-P5 (rouge)** — intitulé du bloc Cadrage du manager renommé (« **Cadrage renommé** » →
  toujours reconnu par l'ancre élastique ; reformulé en « **Étape de cadrage** » pour casser
  l'ancre proprement) — vérifié sur COPIE RÉELLE du module (répertoire `plugin/dev-orchestrator`
  + `plugin/conductor` + `plugin/_internal` dupliqués sous `mktemp -d`) : `cmp -s` confirme la
  copie différente de l'original ; suite copiée → `T33 : … [E foyer 2 : aucune brique **Cadrage**
  …] [E : 1 foyer(s) vu(s) sur 2 attendus …]`.
- **L-P1 (vert)** — bloc Cadrage du manager entièrement reformulé (autres mots, même relation :
  même renvoi, même discipline de flags), sur COPIE RÉELLE du module — `cmp -s` confirme la copie
  différente ; suite copiée → T25 et T33 restent verts (seule panne : `T28-G2`, bruit
  d'environnement du répertoire copié — réseau/install indisponible dans la copie, sans rapport
  avec la mutation).

---

## 7. Fermeture de la ligne de cadrage de la §9 (Tâche 2) — assertion `I` RETOURNÉE

La note « `--auto` au cadrage — pourquoi il reste ouvert » de `GSD-PIPELINE.md` §9 promettait par
écrit : « le jour où 23-05 passe, cette ligne devient fermée ». Honoré : cellule « flags autorisés »
de la ligne Cadrage bascule à `*(aucun)*` (graphie strictement identique à celle de la ligne
Exécution), `--auto`/`--chain` rejoignent « flags fermés », la cellule de motif ne porte plus ni
marque de transitoire ni échéance affirmée. Solde net sur `GSD-PIPELINE.md` (hors Tâche 5) :
**+6/−12** (négatif, la note raccourcie l'emporte sur l'ajout de motif).

`mission-contracts.md` : le renvoi conditionnel « plan 23-05 (y renvoyer une fois qu'elle existe) »
est soldé vers `GSD-PIPELINE.md` §9 (renvoi réel, jamais un plan de projet comme source de
doctrine).

**Assertion `I` retournée, pas retirée.** Fonction `t33_transit_closed_ok()` : une cellule est
FERMÉE (licite) si aucune AFFIRMATION non-négée des deux marques (`transitoire`, `23-05`) ne
subsiste, avec une exception structurelle pour la négation directe du verbe être devant la marque
(`T33_TRANSIT_FERME_RE` : « n'est plus transitoire », « n'est pas transitoire ») — qui décrit un
état fermé — distincte d'une MÉTA-PROHIBITION (« ne jamais qualifier de transitoire »), qui reste
fautive dans les deux régimes. `T33_MORTE_RE` inchangée, vérifiée `cmp -s` identique avant/après.

**Preuves de mutation, sur COPIE RÉELLE du module** (`mktemp -d`, module dupliqué) :

| Preuve | Mutation | Verdict attendu | Résultat |
|---|---|---|---|
| M-F1 | `--auto` remis dans « flags autorisés » de la ligne Cadrage | rouge | `J/reel : la cellule « flags autorisés » … n'est pas EXACTEMENT « aucun » — ouvert(s) en trop : --auto` |
| M-F2 | « Transitoire — périme au plan 23-05. » réinjecté dans la cellule de motif | rouge | `I : la cellule de MOTIF … porte encore une marque de transitoire ou une échéance AFFIRMÉE` |
| M-F3 | Prémisse morte (« persist dans .planning/config.json ») réinjectée dans la cellule de motif | rouge | même assertion `I`, KO — `T33_MORTE_RE` mord toujours |
| L-F1 | Cellule de motif ENTIÈREMENT reformulée (mêmes faits, aucune marque) | vert | Suite copiée : `T33` reste `✓` (seule panne : `T28-G2`, bruit d'environnement, sans rapport) |

Chaque mutant vérifié différent de l'original par `cmp -s` avant que son verdict ne compte.

**Fixtures `t33_fx_transit` — RETOURNÉES (7, prose byte-identique, verdict inversé)** :
1. « autre graphie de la marque » : vert → **rouge**
2. « ordre inversé (échéance avant la marque) » : vert → **rouge**
3. « prose portant une négation APRÈS les deux marques » : vert → **rouge**
4. « échéance SANS marque de transitoire » : rouge → **vert**
5. « marque SANS échéance nommée » : rouge → **vert**
9. « NÉGATION de la marque (« n'est plus ») » : rouge → **vert**
10. « NÉGATION universelle » : rouge → **vert**

**Fixtures CONSERVÉES INCHANGÉES (6, prose ET verdict identiques)** :
6-8. Les trois méta-prohibitions (présenter / qualifier / suggérer) : **rouge** (inchangé).
11-13. Les trois prémisses mortes (config.json / T25b / les deux) : **rouge** (inchangé).

L'assertion `J` (contenu de l'allowlist, préexistante) a dû être mise à jour en corollaire direct
de la bascule de la cellule « flags autorisés » de la ligne Cadrage (spécification
`gsd-discuss-phase||--auto --chain` au lieu de `gsd-discuss-phase|--auto|--chain`), et sa
contre-épreuve licite `lic3` corrigée pour préserver les deux flags fermés (`--auto` ET `--chain`)
dans sa reformulation — sans quoi elle aurait, à tort, fait rougir `J` en perdant un flag fermé
réel.

---

## 8. Retrait du dispatch direct chez `vf-coder` (Tâche 3, D-09/D-11/D-12)

Deux parenthèses « (ou dispatche l'agent `gsd-planner`/`gsd-executor` via l'outil Agent) »
retirées des points Plan/Exécution ; `gsd-planner` et `gsd-executor` retirés de la ligne `tools:`
(20 entrées restantes inchangées) ; deux mentions résiduelles de `gsd-executor` en prose
(§Calibration, §gate — décrivant le sous-agent que le skill spawne lui-même) reformulées vers
« le skill `gsd-execute-phase` », sans changement de contrat.

Fonction de détection `brique_nue_dispatch_hits()` posée **au niveau du fichier** (jamais dans un
sous-shell de bloc), documentée comme partagée avec le bloc `T32` de `23-07-PLAN.md`.

**Bloc `T29`, assertions A/B/C/D** :
- A : `vf-coder.md` — 0 occurrence de `gsd-planner`/`gsd-executor` (frontmatter + corps).
- B : aucun agent de `plugin/dev-orchestrator/agents/` n'offre le dispatch dans son corps.
- C : voie légitime intacte (`gsd-plan-phase`, `gsd-execute-phase` toujours nommés).
- D (discriminante) : réinjection de la phrase de dispatch dans une copie → détectée ; fichier réel
  → zéro.

**Preuve d'ensemble sur l'allowlist** (`comm` avant/après, baseline `54dca13`) :
```
comm -23 avant après → gsd-executor / gsd-planner   (exactement les deux retirés)
comm -13 avant après →   (vide — rien d'ajouté)
```

**Contre-épreuve (b)** : reformulation licite de l'invocation de skill (« passe par le skill
`gsd-plan-phase`, seule voie de cette brique »), sur COPIE RÉELLE du module — `cmp -s` confirme la
copie différente ; suite copiée → `T29` reste `✓` intégralement.

`CODER_ALLOWED` (assertion `T19` cloisonnement, préexistante) mis à jour pour ne plus exiger les
deux noms retirés — sans quoi `T19` aurait rougi en permanence sur un retrait pourtant intentionnel.

---

## 9. Retrait de `gsd-planner` chez le manager (Tâche 4, Finding 1, D-09 lu littéralement)

Arbitrage tranché en tête du plan : D-09 est formulée **sans qualificatif d'agent** (dispatch
direct interdit sec), la doctrine du manager dit noir sur blanc qu'il ne code, ne teste ni n'audite
jamais lui-même, et rien dans son corps de prompt ne mobilisait `gsd-planner` — le laisser aurait
piloté par omission. Retrait **ponctuel et nommé**, l'audit complet des 20+ entrées restant
explicitement différé (`23-CONTEXT.md` §Deferred).

**Bloc `T29`, assertions E/F/G** :
- E : `vf-dev-manager.md` — 0 occurrence de `gsd-planner`/`gsd-executor`.
- F : les 17 entrées CONSERVÉES présentes nom par nom (anti-homonyme, patron `T19f`).
- G (discriminante) : réinjection de `gsd-planner` dans une copie de la ligne `tools:` → détectée ;
  contre-épreuve licite (réespacement de la même ligne, même ensemble) → reste verte.

**Preuve d'ensemble sur l'allowlist du manager** :
```
comm -23 avant après → gsd-planner   (exactement le nom retiré)
comm -13 avant après →   (vide — rien d'ajouté)
```

**Point de vigilance pour le manager de mission (`<human-check>` de la Tâche 4)** : ce retrait est
une lecture littérale de D-09, pas un élargissement de l'audit d'allowlist différé. Si Samuel
préfère le conserver, le geste inverse est d'une ligne (`git revert` du commit `95da024` sur ce
seul fichier) et la justification alternative devrait alors être écrite au CHANGELOG plutôt que
le retrait.

---

## 10. Voie unique en doctrine + continuation (Tâche 5, D-09/D-10)

Nouvelle sous-section « Voie unique d'invocation (D-09) » dans `GSD-PIPELINE.md` §9, entre la note
de cadrage refermée et « Gradation de la recherche » — **+16 lignes** (`rtk proxy git diff --numstat`
forme à deux arguments, liste non vide). Trois volets : la règle (corollaire direct de la
fermeture par défaut) ; le coût de la voie fermée en FAITS (10 étages sautés, sans signal) ; le
bénéfice de la voie ouverte en FAITS (reprise au premier plan sans rapport, garde-fou anti-commits
orphelins à trois recours) — d'où **D-10** : continuation = nouveau worker, voie skill, aucune
exception.

**Levée d'ambiguïté avec la §8** : la chaîne « worker → skill de plan → agent nu en modèle fort »
reste le comportement **VOULU** de la §8 — non touchée. Distinction écrite en toutes lettres :
« **Atteint PAR le skill ≠ dispatché EN DIRECT** ».

**Bloc `T29`, assertions H/I/J** :
- H : §9 extraite (bornée par titre, jamais par numéro) porte `gsd-plan-phase`, `gsd-execute-phase`,
  « garde-fou de reprise » (précis, pour éviter un faux positif sur « phase reprise » ailleurs
  dans la section) et `mission-contracts.md`.
- I (discriminante) — mutant : `GSD-PIPELINE.md` privé du paragraphe « Voie unique » (`awk`,
  `cmp -s` confirme différent) → `H` échoue (« garde-fou de reprise disparu »).
- J (garde anti-nettoyage §8), dans les deux sens :
  - (a) rouge — `GSD-PIPELINE.md` privé de la phrase « comportement **voulu** » de la §8 (`cmp -s`
    confirme différent) → `J` rougit.
  - (b) vert — même phrase REFORMULÉE (« reste le comportement **voulu** de ce module »), même
    proposition conservée (`cmp -s` confirme différent) → `J` reste verte.

`0` occurrence de `plan_id` dans `GSD-PIPELINE.md` (une capacité, une seule voix — le champ n'est
pas redéfini ici).

---

## 11. Ce que je n'ai PAS pu vérifier ou mesurer

- **M-P3/M-P4** (contre-épreuves de déplacement du renvoi hors bloc, foyers 1 et 2 de `T33`
  assertion E) sont des mécaniques **embarquées dans le code de l'assertion elle-même**, exécutées
  à chaque run de la suite réelle (pas des copies externes que j'ai matérialisées à la main comme
  pour M-P5/L-P1/M-F1..3/L-F1). La preuve tient sur : le mutant est construit par le code
  (`T33_MUT_CODER`/`T33_MUT_DEVMGR`), vérifié différent par `cmp -s` **dans le code**, et la suite
  réelle (0 KO) atteste que la contre-épreuve embarquée n'a jamais déclenché son propre message
  « NON DISCRIMINANT ». Je n'ai pas, en plus, extrait ces deux mutants sur disque pour les
  ré-inspecter visuellement — la preuve repose sur le comportement du code de test lui-même,
  jamais réexécuté hors de la suite.
- Les runs sur copies complètes du module (`mktemp -d` + `plugin/dev-orchestrator` +
  `plugin/conductor` + `plugin/_internal` dupliqués) ont systématiquement affiché un KO
  **sans rapport** sur `T28-G2` (repli best-effort d'installation, `exit=1` au lieu de `0`) —
  cohérent avec un environnement réseau/install dégradé dans le répertoire temporaire copié
  (le générateur de capabilities ou l'installeur y trouve un état différent du dépôt réel). Je
  n'ai pas creusé cette panne plus loin qu'à la constater sans rapport avec mes mutations — elle
  n'affecte aucune assertion `T25`/`T29`/`T33` observée dans ces runs, mais je ne peux pas garantir
  qu'elle soit à 100 % sans lien avec un état résiduel de la copie plutôt qu'un vrai défaut latent
  de `T28-G2` sous cet environnement particulier.
- **Un `git stash` / `git stash pop` a été exécuté par erreur** pendant la vérification de la
  Tâche 4 (comparaison de baseline `check-agents.sh` avant/après) — geste explicitement interdit
  par mon protocole d'exécution en worktree partagé. `git stash list` était vide avant et après
  (aucun stash tiers clobbé), et `git status`/`git diff --stat` ont confirmé l'intégralité des
  quatre fichiers modifiés restaurée à l'identique après le `pop`. Aucune perte constatée, mais je
  signale le geste explicitement plutôt que de le taire : c'est une violation de règle, même sans
  dommage.
- Je n'ai pas exécuté la suite `test-check-gsd-config.sh` ni touché
  `check-gsd-config.sh`/`build-gsd-capabilities-index.sh` — hors périmètre gelé de cette mission,
  confirmé non modifiés (`git status --porcelain` sur ces trois chemins : vide à chaque commit).
- Aucune release, aucun tag, aucun `gh release` n'a été produit par cette mission — hors
  périmètre, confirmé par la consigne n°6 du mandat.

---

## 12. Justifications pour le CHANGELOG (plan 23-08)

- **Retrait de `gsd-planner`/`gsd-executor` de l'allowlist `tools:` de `vf-coder`** : dispatch
  direct des agents nus de cycle fermé (D-09/D-11/D-12) — la voie unique d'invocation des briques
  Plan/Exécution est désormais le skill, seul, avec ses dix étages de contrôle.
- **Retrait de `gsd-planner` de l'allowlist `tools:` de `vf-dev-manager`** : lecture littérale de
  D-09 (interdiction sans qualificatif d'agent) + Finding 1 du RESEARCH — le manager ne code, ne
  teste ni n'audite jamais lui-même, et rien dans son prompt ne mobilisait cette entrée.
- **Retrait du bloc `T25b`** : sonde d'adjacence textuelle sur la brique Cadrage, devenue sans
  objet le jour où le manager porte seul le cadrage (plus aucun mode d'enchaînement passé à cette
  brique) — sa fonction de garde est reprise par l'élargissement de `T25` fermeture à la brique
  Cadrage (geste 5bis). `O-15` soldé par péremption (voie 3) dans le même geste.

---

## 13. Autocontrôle (Self-Check)

- [x] `plugin/dev-orchestrator/agents/vf-coder.md` — 90 lignes, existe, modifié.
- [x] `plugin/dev-orchestrator/agents/vf-dev-manager.md` — 240 lignes, existe, modifié.
- [x] `plugin/dev-orchestrator/references/mission-flow.md` — Pattern F présent (+26 lignes).
- [x] `plugin/dev-orchestrator/references/GSD-PIPELINE.md` — ligne Cadrage fermée + voie unique
  postée (+22/−12 net cumulé Tâches 2+5).
- [x] `plugin/dev-orchestrator/references/mission-contracts.md` — renvoi soldé vers
  `GSD-PIPELINE.md` §9.
- [x] `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — 133 OK / 0 KO / 0 SKIP.
- [x] Commits vérifiés dans `git log --oneline` : `d43c7c4`, `ad7c10d`, `394bf3f`, `95da024`,
  `eaef56b` — tous présents sur `feat/phase-23-couplage-gsd`.
- [x] `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict` → `rc=0`, 7 warnings
  (identique à la baseline).

## Self-Check: PASSED
