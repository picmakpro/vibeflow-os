---
name: vf-secure
description: >
  Utiliser quand l'utilisateur veut savoir si ce qui a été construit tient la route côté
  sécurité — « audite la sécu », « c'est safe ce truc ? », « vérifie les failles »,
  « on expose pas des secrets là ? », « check les vulnérabilités », « le threat model est
  respecté ? », « y a pas un trou de sécu ». Vérifie que les protections prévues pour une
  étape existent réellement dans le code livré, et remonte les manques par sévérité.
  ✘ pas pour la qualité générale d'un diff → /vf-review · ✘ pas pour les recettes en
  souffrance et la dette d'étape → /vf-gaps · ✘ pas pour un incident en cours → /vf-debug.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-secure — Audit de sécurité d'étape

Délègue à `gsd-secure-phase` : vérification **rétroactive** que les mitigations annoncées dans le
plan de l'étape sont bien présentes dans le code livré, avec rapport classé par sévérité.

Reframe toute sortie en vocabulaire VibeFlow : « secure-phase » → **audit de sécurité d'étape**,
« phase » → **étape/sprint**, « threat model » → **modèle de menaces**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-secure-phase` à l'utilisateur.

Aucune correction n'est appliquée sans validation humaine (ADR-031) : l'audit **constate**, les
correctifs repassent par `vf-execute` ou `vf-quick`.

Enchaînement typique : `vf-execute` → `vf-test` → `vf-secure` → `vf-ship`.
