---
phase: "73"
slug: gouvernance-au-cockpit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 73 — Stratégie de validation

> Contrat de validation par phase pour l'échantillonnage du retour pendant l'exécution.
> Source : 73-RESEARCH.md § Validation Architecture (carte exigence → témoin et mutants nommés).

---

## Infrastructure de test

| Propriété | Valeur |
|-----------|--------|
| **Cadre** | suites bash du module cockpit (`assert_eq`, `assert_has`, `assert_not`, compteurs PASS/FAIL, sortie 0/1) ; modules Node joués en `vm` ou importés ; Chrome headless par CDP brut (sauté hors CI sans navigateur, échec en CI) |
| **Fichier de config** | aucun ; hygiène `plugin/cockpit/scripts/tests/hygiene.sh` |
| **Commande rapide** | `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh` (sections nommables, ex. `RG4 RG5`) ; couche données : `bash plugin/cockpit/scripts/tests/test-cockpit-who.sh && bash plugin/cockpit/scripts/tests/test-cockpit-equipe-etats.sh` |
| **Commande complète** | `for s in plugin/cockpit/scripts/tests/test-cockpit-*.sh; do bash "$s" \|\| echo "ROUGE $s"; done` |
| **Gates de dépôt** | `bash scripts/check-version-sync.sh` ; `bash scripts/check-machine-paths.sh` ; `bash plugin/software-architecture/scripts/check-file-size.sh <fichiers>` ; `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh` |
| **Durée estimée** | rapide : < 60 s ; complète : plusieurs minutes (suites navigateur lourdes) |

---

## Taux d'échantillonnage

- **Après chaque commit de tâche :** la suite de la couche touchée (rapide) + taille des fichiers touchés.
- **Après chaque vague :** toutes les suites `test-cockpit-*.sh` + `test-cockpit-vendor.sh`.
- **Avant `/gsd-verify-work` :** suites cockpit vertes macOS et Linux, compteur de suites 214, chemins, tailles ≤ 300.
- **Latence maximale :** 60 s sur la commande rapide.

---

## Carte de vérification par exigence

| Exigence | Comportement | Type | Témoin | Rouge avant | Statut |
|----------|--------------|------|--------|-------------|--------|
| REGI-01 | quatre sections, compteurs, états vides, clé section+id | VM + CDP | RG1.* | sections absentes | pending |
| REGI-02 | même entrée, même DOM (VF_ETAT ou vf-who) | VM | RG2.1, M-ADAPTATEUR-DIVERGE | fonction absente | pending |
| REGI-03 | canevas vide, enveloppe @1 valide, 0 rechargement, moteur intact | serveur réel + VM | RG3.1-RG3.4, V6.1 | nodes non vide | pending |
| REGI-04 | « À vous » = attend + human_needed, rien d'autre | VM + fixture | RG4.0-RG4.3, M-HUMAN-NEEDED-COCHEE | ligne absente | pending |
| REGI-05 | impact, trois rangs, jamais deviné | VM pur | RG5.*, M-IMPACT-* | fonction absente | pending |
| REGI-06 | tenant du verrou, liste blanche, non-fuite | CDP + verrou réel | RG6.*, M-VERROU-* | verrou brut exposé | pending |
| REGI-07 | verrou abandonné, aucun nœud marqué, fenêtre à source unique | Node + VM | RG7.*, M-STALL-* | fenêtre absente | pending |
| REGI-08 | worktrees repliés, jointure, aucun git neuf | serveur + faux git | RG8.* | bloc absent | pending |
| REGI-09 | décroissance, commande longue, orphelin neutre | VM temps + CDP | RG9.*, M-CALME, M-LONGUE-EGALE-STALL | libellé de tiroir seul | pending |
| REGI-10 | attendAgents | Node + transcript | RG10.*, M-ATTEND-REMONTE | champ absent | pending |
| REGI-11 | « lu » à l'ouverture, purge 24 h, repli sans stockage | CDP | RG11.*, M-LU-* | état absent | pending |
| REGI-12 | compositeur unique du titre | CDP | RG12.*, M-TITRE-* | préfixe réécrit | pending |
| REGI-13 | « ailleurs » : nombre et nom seulement, non-fuite | serveur + faux claude | RG13.*, M-AILLEURS-* | route 404 | pending |
| REGI-14 | un style de bouton, nom une fois, santé | CDP + VM | RG14.*, M3.8 | 3 styles | pending |
| REGI-15 | registre, bascule, événements annulables | VM | RG15.* | registre indéfini | pending |
| REGI-16 | LE → LR, export, recherche, compteur, suites vertes | suites + gates | LR1-LR5, W23.*, RG16.* | `lancee` absent | pending |

*Les identifiants de tâche et la colonne « Fichier existe » sont renseignés par les plans (73-NN).*

---

## Exigences Wave 0

- [ ] `plugin/cockpit/scripts/tests/test-cockpit-regie.sh` — squelette de la suite unique neuve (P73-D-05)
- [ ] `plugin/cockpit/scripts/tests/vm-regie.mjs` — harnais VM de la régie (≤ 300 lignes)
- [ ] `plugin/cockpit/scripts/tests/chrome-regie.mjs` — harnais CDP (≤ 300 lignes)
- [ ] fixtures `tests/temoins/` — lab à VERIFICATION human_needed, DAG, verrou réel, faux `claude agents --json`, deux worktrees, transcript `turn_duration`
- [ ] valeur saine de LR.1 capturée avant toute modification de `who.mjs`

---

## Vérifications manuelles seules

| Comportement | Exigence | Pourquoi manuel | Instructions |
|--------------|----------|-----------------|--------------|
| Sonde réelle de `claude agents --json` (présence de `cwd`, lignes après `turn_duration`) | REGI-10, REGI-13 | demande une session vivante, hors de cette phase | jouer la sonde sur un poste avec une session ouverte, consigner la sortie réduite |

---

## Validation Sign-Off

- [ ] Toutes les tâches ont un `<automated>` ou une dépendance Wave 0
- [ ] Continuité : jamais 3 tâches consécutives sans vérification automatisée
- [ ] Wave 0 couvre toutes les références MISSING
- [ ] Aucun drapeau watch
- [ ] Latence < 60 s
- [ ] `nyquist_compliant: true` dans le frontmatter

**Approbation :** en attente
