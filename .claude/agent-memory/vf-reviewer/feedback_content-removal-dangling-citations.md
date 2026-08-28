---
name: content-removal-dangling-citations
description: quand un diff supprime une section de doc (README, page de manuel...), grep le reste du repo pour des citations de cette section avant de dire PASS
metadata:
  type: feedback
---

Un diff qui supprime une section entière (table, paragraphe daté) d'un fichier "source" doit être
recoupé avec le reste du dépôt : une autre page peut la citer nommément comme source de vérité
vivante ("si tu veux vérifier ce chiffrage toi-même, README.md, section X, est la source").
Supprimer X sans mettre à jour ces citations rend l'affirmation fausse — un lecteur qui suit le
renvoi ne trouve plus rien.

**Comment détecter** : après avoir identifié le titre exact de chaque section/table supprimée,
`grep -rn "<titre section>"` (et sa variante FR/EN) sur tout le repo (pas seulement le diff) —
en particulier les dossiers doc/manuel écrits *avant* ce diff (`git log --oneline -- <fichier
manuel>` pour dater sa dernière modification par rapport au commit de suppression).

**Cas réel** : Phase 26 comblement README (commit `4b450bd`, 2026-08-02) — la suppression de la
section « Efficiency, quantified » et du tableau des 17 modules dans `README.md`/`README.fr.md`
a laissé 6 pages du manuel (`06-reference/cost-and-models.md` + `couts-et-modeles.md`,
`commands.md` + `commandes.md`, `skills.md` FR/EN) citer une section ou un tableau qui n'existe
plus. Les pages du manuel avaient été publiées au commit précédent (`6fcbf1d`), donc c'est bien
*ce* diff qui a cassé le contrat, pas un défaut préexistant.

**Why** : un dégraissage README→manuel qui *réduit* le README casse silencieusement les pages du
manuel qui pointaient vers le contenu déplacé/supprimé — la direction du renvoi (manuel → README)
n'est pas la même que celle testée par défaut (README → manuel), donc facile à rater si on ne
grep que dans un sens.

**How to apply** : sur toute review de dégraissage/déplacement de contenu doc, toujours grepper
le titre de chaque section supprimée dans l'ensemble du repo avant de conclure à un PASS sur le
critère "pas de perte d'info non couverte".
