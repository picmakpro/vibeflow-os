# Changelog — cockpit

## v1.0.0 — 2026-11-01

Première version du module (non publiée : aucune release n'est coupée pour l'instant). Décisions : arbitrages Samuel,
AskUserQuestion session principale, 2026-11-01.

### Ajouté
- **Socle partagé à interface versionnée** (P67-D-12) — collecteur « au travail », lecture de la planification, verrou et
  chemins du lab ; schémas `vibeflow/cockpit-*@1` consignés dans `scripts/vf-cockpit-interface.json`, destinés à `vf-signal`.
- **Moteur d'affichage vendorisé et rejouable** (P67-D-07, P67-D-11) — copie du moteur floorplan v0.6.0 @ 92d6854 (MIT)
  sous `skills/cockpit-moteur/`, patchs listés dans `VENDORED.txt`, procédure de synchro hors réseau (`amont/SYNCHRO.md`).
- **Marque blanche par renommage de la sortie** (P67-D-03, P67-D-04) — aucune mention du produit amont dans ce que voit
  l'utilisateur ; logo et favicon VibeFlow.
- **Cloud retiré, aucun appel sortant hors l'agent** (P67-D-02) — la fonction Cloud du moteur est retirée, le test réseau
  enregistre 0 connexion sortante.
- **Serveur unique avec direct et repli** (P67-D-13, P67-D-16) — flux d'événements, surveillance récursive de `.planning/`
  avec repli par scrutation, anti-rebond et hystérésis.
- **Dernière commande masquée** (P67-D-14) — jamais diffusée ; révélée à la demande dans la page.
- **Questions locales et agent confiné, modèle réglable** (P67-D-08, P67-D-15) — réponses calculées sur place pour les
  formes courantes, sinon `claude -p` confiné (mesure `67-MESURE-claude-p.md`) ; `sonnet` par défaut, liste fermée,
  `VF_COCKPIT_MODEL` et sélecteur de la page.
- **Onglet Code conditionnel** (P67-D-17) — extracteur VibeFlow sur un lab à modules, architecture brute ailleurs.
- **Verbe `/vf-cockpit`** (P67-D-05) — skill de classe utilisateur (`open`, `build`, `stop`, `status`), pour tous les
  postes (P67-D-01) ; aucun fichier sous `plugin/commands/`.
- **Sortie sous `.vibeflow/cockpit/`** (P67-D-06) — ignorée par git, ce dossier compris.
- **Chrome en français, test d'inventaire qui rougit** (CKPT-09, P67-D-03, P67-D-18) — dictionnaire (deux fichiers `assets/ui/78` et `79`), gabarits à variables, motifs et fonction pure `window.__vfFrTraduire` (`80-vf-fr.js`) ; inventaire déterministe des chaînes anglaises du rendu servi (`vf-cockpit-fr-inventaire.mjs`) comparé au dictionnaire, aux gabarits, aux motifs et aux exclusions justifiées (`vf-cockpit-fr-exclusions.json`) ; statuts de STATE affichés en français ; direction artistique du moteur conservée.

### Sécurité et robustesse (correction A de la Phase 67, avant toute publication)
- **Chaîne lab piégé -> XSS -> jeton -> exécution de code rompue à trois endroits** — échappement de tout champ du graphe (patch P16), Content-Security-Policy
  par empreintes avec `connect-src 'self'` et en-têtes `nosniff`/`DENY` (P17), « modifier le plan » durci : seuls `plan.mjs` et `build.mjs` du moteur du module
  s'exécutent, jamais un script désigné par un `.cache/` du lab (P15). Suite `test-cockpit-chaine-xss.sh` (navigateur headless, mutants).
- **Aucun script du lab exécuté** — plus de `driver-lock.sh` pris sous le lab, arrêt du serveur par signal sur un PID vérifié, aucune écriture ni lecture à travers un lien symbolique.
- **`claude -p` confiné aussi côté réglages** — `--setting-sources ""` (ni hooks du lab ou de l'utilisateur, ni règle `allow`) et `--strict-mcp-config`, mesurés.
- **Robustesse** — une question courante ne fait plus tomber le serveur, la page rechargée est à jour après un patch, verrou tenu visible en lab plat,
  lab sans code assemblé, masque des secrets étendu, corps JSON non objet refusé, `<!--` neutralisé, timeouts partout.
