---
name: vf-product
description: "Utiliser quand l'intention est produit — « écris le brief », « cadre ce produit », « rédige le PRD », « quelles exigences », « ajoute les critères d'acceptation », « est-ce prêt pour le dev ». Porte d'entrée du poste product : BRIEF (.planning/BRIEF.md) et PRD (PROJECT.md + REQUIREMENTS.md), jugés par prd-gate. ✘ pas pour coder ou découper en phases → vf-dev · ✘ pas pour poser le socle de planning d'un lab non-dev → vf-planning · ✘ pas pour la DA ou l'UI → vf-design. Invocable par l'utilisateur ET par l'agent en autonomie ET par le head au poste product."
vf-invocation: model
---

# vf-product — Point d'entrée produit

Lit l'intention produit de la demande, puis **incarne l'agent `vibeflow-product`** — jamais dispatché en
Task (profondeur 1 réservée au manager qu'il lance, `team-kernel.md` §Marge de profondeur de dispatch) — qui porte
la table de routage, l'aiguillage et le passage de main :

- écrire ou mettre à jour le brief → geste simple, BRIEF produit en session depuis son gabarit
- retoucher une exigence, ajouter un critère d'acceptation → geste simple, PRD produit en session
- rédiger le PRD, cadrer ce produit (brief et PRD) → mission : l'agent propose `Task(vf-product-manager)`
- rédiger la décision d'architecture avant le découpage → mission : l'agent propose `Task(vf-product-manager)` (livrable architecture), validée ensuite par un dev
- faire évaluer le PRD, « est-ce prêt pour le dev » → mission : verdict noté par un évaluateur frais, indépendant du rédacteur

Un geste simple touche un seul fichier du rôle et passe toujours par `check-prd.sh` avant d'être
annoncé : jamais déclaré vert sans lui. Une mission est proposée à l'humain, jamais lancée d'office.

Le poste lu par `vf-role.sh get` n'est qu'un avis : un poste est une vue, pas un droit. Au poste `dev`,
l'agent l'annonce en une phrase puis sert la demande.

**Ne réimplémente jamais** la logique d'un outil : route, délègue, fais juger.
