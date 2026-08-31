---
name: non-regression-complete-est-un-geste-de-manager
description: Exiger la découverte complète des suites DANS un mandat de worker l'enlise — 4 workers bloqués sur le même écueil en une mission ; le manager la rejoue, le worker rejoue seulement les siennes
metadata:
  type: feedback
---

**Ne jamais exiger la découverte COMPLÈTE des suites dans un mandat de worker.** Le worker rejoue
**ses** suites (rapides, ciblées) ; **le manager rejoue la découverte complète** et compare à la
baseline qu'il a lui-même mesurée.

**Why:** mesuré Phase 38 (2026-08-28), **quatre workers enlisés sur le même écueil** — un
constructeur, deux relecteurs, un correcteur. Mécanique de l'enlisement, identique à chaque fois :
la découverte complète (70 suites) **dépasse le délai par défaut d'une commande** → le worker la
bascule en arrière-plan → il rend la main « en attente du job » → il ne rapporte rien → réveil →
il recommence. Un worker a consommé **245 000 tokens et trois tours** de cette façon **alors que
son travail était fait, correct et vert sur le disque** — il ne manquait que le commit.
Aggravant local : `timeout`/`gtimeout` sont **absents de ce poste**
([[timeout-absent-faux-zero]]), donc certaines de ces boucles rendaient en plus un `0/N` silencieux.

Ce n'est pas de la mauvaise volonté : mon mandat demandait littéralement « rejoue la découverte
complète, rapporte avant/après ». Ils obéissaient. **Le défaut était dans la consigne.**

**How to apply:**
1. Dans le mandat : « rejoue **tes** suites (nomme-les), donne leur résultat. **Ne lance pas** la
   découverte complète — je m'en charge. »
2. Le manager mesure la baseline **une fois** avant d'ouvrir une frontière, la **donne** aux
   workers comme un fait, et rejoue la découverte complète **après** chaque atterrissage. C'est
   un geste bon marché pour lui (une commande, `timeout` explicite jusqu'à 600 000 ms) et ruineux
   pour eux.
3. Corollaire : ajouter à chaque mandat **« ne rends jamais la main en attente d'un job
   d'arrière-plan — termine tes mesures, puis rapporte »**. Sans cette ligne, le worker croit
   qu'attendre est une conduite valide.
4. Quand un worker rend « en attente », **constater le disque avant de conclure quoi que ce soit**
   ([[relire-le-disque-avant-tout-rapport]]) : trois fois sur quatre le travail était là, entier.

Voir [[non-regression-sur-la-decouverte-complete]] — la découverte complète reste **obligatoire**,
c'est seulement **qui l'exécute** qui change.
