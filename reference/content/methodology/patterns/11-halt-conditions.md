# Pattern 11 — Halt conditions (NOUVEAU v4.1)

## Quoi

Une **halt condition** est un declencheur deterministe qui **stoppe immediatement** une execution autonome et remonte la decision a l'humain. Ce n'est pas un avertissement, ni une suggestion : c'est un arret dur, suivi d'un message d'escalation structure.

VibeFlow v4.1 definit **5 codes HALT universels** qui s'appliquent obligatoirement en mode `god-execution` (execution autonome multi-sprints) et de facon recommandee en `safe-execute` long.

## Pourquoi

En execution autonome, un agent peut continuer d'avancer alors que :
- Le plan ne converge plus apres plusieurs revisions
- L'execution tourne en rond sans progres
- Une action destructive est sur le point d'etre lancee
- Une ressource externe est manquante ou en panne
- Le scope reel diverge du scope planifie

Sans halt condition, l'agent **continue** : il essaie encore, il invente des contournements, il modifie des fichiers hors contrat. La derive s'accumule silencieusement et peut couter des heures de retouches.

Avec halt conditions, l'execution **s'arrete net** au premier signal :
- Pas de degats supplementaires
- Etat actuel preserve pour analyse
- Humain alerte avec contexte structure

Le but n'est **pas** d'eviter tous les arrets  -  c'est de transformer un dérapage silencieux en une question explicite a l'humain.

## Comment

### Les 5 halt conditions universelles

| Code | Declencheur | Action |
|------|-------------|--------|
| **HALT-1** | Plan-Review divergence > 3 iterations sans converger | Arret + escalation humaine pour arbitrage |
| **HALT-2** | Loop Execution-Verification > 3 cycles sans progres mesurable | Arret + rapport "stuck" + escalation |
| **HALT-3** | Action destructive non-reversible detectee (delete > 10 fichiers, force push, rollback prod, envoi email masse) | Arret + demande de confirmation humaine explicite |
| **HALT-4** | Ressource externe manquante ou non-deterministe (API down, fichier introuvable, quota epuise) | Arret + rapport de blocage + escalation |
| **HALT-5** | Drift de scope (fichiers modifies hors contrat de planification valide) | Arret + diff genere + demande de validation |

### Format de message d'escalation

Le message d'escalation doit etre **structure et factuel**  -  pas un cri d'alarme.

```markdown
## HALT-X declenche

**Contexte** : [ce qui etait en cours - 1 phrase]
**Declencheur** : [observation factuelle, sans interpretation]
**Etat actuel** :
- Fichiers modifies : [liste]
- Sprints completes : [N/Total]
- Commits faits : [liste hash + message]
- Dette accumulee : [si identifiable]

**Question pour l'humain** : [arbitrage explicite demande]

**Options** :
- A : [option] - consequence : [consequence]
- B : [option] - consequence : [consequence]
- C : Abandonner et rollback - consequence : [consequence]
```

L'humain peut alors arbitrer en **moins d'une minute** au lieu de devoir reconstruire le contexte.

### Granularite des halts

| Halt | Reversibilite | Granularite type |
|------|---------------|------------------|
| HALT-1 | Reversible (replanifier) | Apres review cycle |
| HALT-2 | Reversible (pivot strategique) | Apres verification cycle |
| HALT-3 | NON reversible (action destructive) | AVANT execution |
| HALT-4 | Reversible (attendre/contourner ressource) | Apres tentative d'acces |
| HALT-5 | Reversible (rollback du diff) | A chaque commit |

HALT-3 est le plus critique : il s'agit d'un **arret pre-execution** sur action non-reversible. Les 4 autres sont post-execution mais avant de boucler.

### Hard thresholds recommandes

| Threshold | Valeur par defaut | Pourquoi |
|-----------|------------------|----------|
| Max fichiers touches sans validation | 10 | Au-dela, scope probablement derive |
| Max temps continu autonome | 8h | Au-dela, fatigue cognitive du systeme (context rot) |
| Max tokens consommes par sprint | 200K | Au-dela, signal de surconsommation, voir 1% Rule |
| Max cycles execution-verification | 3 | Au-dela, on s'acharne |
| Max iterations Plan-Review | 3 | Au-dela, probleme de cadrage |

Ces valeurs sont **par defaut**. Chaque projet peut les ajuster (par BDR), mais elles ne disparaissent pas.

## Exemple fictif

> **Maxime R., consultant solo**, lance une session `god-execution` pour rediger 8 propositions commerciales differenciees a partir d'un brief client. Il part dormir.

Pendant la nuit, l'agent execute :

```
Sprint 1 (proposition 1) : OK, validation P-Review, commit atomique.
Sprint 2 (proposition 2) : OK.
Sprint 3 (proposition 3) : 1er cycle verification echoue (texte trop generique).
Sprint 3 (proposition 3) : 2e cycle, plus precis mais hors brief.
Sprint 3 (proposition 3) : 3e cycle, retour au generique.
→ HALT-2 declenche
```

Au reveil, Maxime trouve :

```markdown
## HALT-2 declenche

**Contexte** : Sprint 3 / 8 (proposition n°3) - persona cible "DAF de scale-up"
**Declencheur** : 3 cycles execution-verification sans progres mesurable. Score qualitatif oscille entre 4/10 et 6/10 sans tendance.

**Etat actuel** :
- Propositions completees : 2 / 8 (sprints 1-2 OK et commitees)
- Sprint en cours : 3 (en echec)
- Dette : aucune (rollback automatique du sprint 3)
- Commits : 2 atomic commits propres (sprints 1, 2)

**Question pour l'humain** : Le critere de succes pour la persona "DAF de scale-up" semble mal calibre. Veux-tu :

**Options** :
- A : Reclarifier la persona (revenir en phase 1 `safe-execute`)
- B : Skipper cette persona et reprendre les sprints 4-8
- C : Abandonner le batch nocturne, refaire en synchrone
```

Maxime arbitre en 30 secondes : option A. Il re-clarifie la persona, relance `safe-execute` sur le sprint 3, puis relance `god-execution` sur les 5 derniers.

**Resultat** : 2h de derive evitee (les sprints 4-8 auraient herite du critere mal calibre).

## Anti-patterns

- **Halt mou** : "essaie encore 5 fois si ca echoue" → l'execution tourne en rond, dette s'accumule
- **Halt sans contexte** : "STOP, ca marche pas" → l'humain doit tout reconstruire avant d'arbitrer
- **Skip halt en autonomie** : "je sais mieux que la regle" → ignorer une halt condition revient a desactiver le garde-fou
- **Halt sans options** : "que veux-tu faire ?" sans propositions → l'humain perd 10 minutes a re-imaginer les options
- **Pas de threshold numerique** : "j'essaie tant que ca peut marcher" → drift sans limite

## Quand utiliser

Les 5 halt conditions s'appliquent obligatoirement en :
- `god-execution` (toute execution autonome multi-sprints)
- Tout workflow autonome > 30 min sans humain dans la boucle

Elles sont recommandees en :
- `safe-execute` long (> 1h de travail)
- Workflow batch (traitement de 5+ items similaires en serie)

Elles sont **optionnelles** en :
- Workflow standard avec humain a chaque etape (l'humain joue le role de halt naturellement)
- Tache triviale (< 15 min)

## Reference

Voir aussi :
- Pattern 09 (Meta-procedures) : ou les halts s'integrent dans `god-execution`
- Pattern 10 (Adversarial Plan-Review) : alimente HALT-1
- Pattern 06 (Capitalisation) : les 7 anti-drift mechanisms qui reduisent la probabilite de halt
- `VIBEFLOW_CORE.md` section 13 : definition canonique des halt conditions
