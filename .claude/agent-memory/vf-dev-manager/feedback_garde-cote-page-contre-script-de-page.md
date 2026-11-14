---
name: garde-cote-page-contre-script-de-page
description: Contre un script qui s'exécute dans la page P, une garde posée dans P (activation, observateur fetch) ne ferme rien : il POSTe la route directement ; seule une autre origine ou le serveur est une frontière
metadata:
  type: feedback
---

Avant de proposer à l'humain une garde contre « un script dans la page », vérifier la ROUTE serveur que la page appelle : tout ce que la page envoie, le script peut l'envoyer lui-même avec le même jeton.

**Why:** Phase 72 (2026-11-06), F-1 « reprise forgée du chat ». J'ai recommandé « geste humain exigé » (navigator.userActivation dans l'observateur fetch de P), Samuel l'a choisie, le codeur l'a livrée avec témoin XSS… puis a constaté que POST /api/vf/lancer acceptait `chat:<uuid>` du corps : le script contournait l'observateur. Prémisse fausse, arbitrage à reposer (P72-D-21 remplacée par P72-D-22, résiduel accepté). Une itération humaine et un mandat perdus.

**How to apply:** pour toute menace « code dans P », lister d'abord les routes que P peut appeler et ce qu'elles acceptent ; une option de fermeture n'est honnête que si elle vit côté serveur ou dans une origine distincte (ici Q, le terminal). Une garde côté P se présente comme « honnêteté du chemin normal », jamais comme fermeture. Voir [[re-mesurer-la-premisse-d-un-arbitrage]].
