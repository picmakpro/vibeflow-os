---
name: messages-clients-simples
description: Tout message destiné à un client/élève doit être court et non technique — Willy écrit lui-même ses réponses et veut du bref
metadata:
  type: feedback
---

**Règle : un message destiné à un client ou un élève est COURT et NON TECHNIQUE.** Trois à cinq
phrases, l'action à faire, rien d'autre. Pas de tableau de statut, pas de nom de fichier, pas de
référence à un identifiant de finding.

**Why:** le 2026-07-30, Willy a demandé une réponse pour un client bloqué (Florian, Windows).
J'ai produit un message long et détaillé — statut point par point, noms de scripts, doctrine.
Il l'a écarté et a envoyé lui-même « une réponse très simple pour le débloquer », en précisant :
« c'est pas un développeur ». Mon erreur de calibrage : ce client lit du bash, diagnostique au
`od -c` et au `bash -x`, et produit des rapports de bug d'excellente qualité — j'en ai déduit un
profil de développeur. C'est un opérateur e-commerce rigoureux, pas un dev. **La rigueur technique
d'un utilisateur ne dit rien du registre de langue à employer avec lui.**

**How to apply:** quand Willy demande « une réponse pour X », produire d'emblée la version courte :
le geste à faire, en langage courant, sans jargon. Garder le détail technique pour LUI, séparément,
s'il est utile. Ne jamais mélanger les deux registres dans un même bloc. Si un point technique est
indispensable au client (une commande à taper), le donner nu, sans l'expliquer.

Corollaire : Willy écrit lui-même ses réponses clients et a déjà un historique avec eux — proposer
un brouillon, jamais un pavé qu'il devrait élaguer. Voir [[willy-perimetre-gouvernance]].
