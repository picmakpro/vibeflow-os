---
name: nfc-forme-io-nom-brut
description: Correctif Unicode de chemins — test de forme en NFC, I/O toujours sur le nom brut du disque ; APFS masque le défaut, seul ext4 (CI) ou un shim sensible le montre
metadata:
  type: project
---

Phase 46 (2026-10-06) : l'audit a prouvé qu'un chemin NFD (`01-été` décomposé) contournait G1/G3/G4, parce qu'APFS résout les deux formes et que le hook testait la forme sur le nom brut. Le correctif NFC a pris TROIS tours : tour 1 sur les chemins du payload, tour 2 sur les noms lus par readdir, tour 3 sur un rouge CI Linux (journal D1 « 31 / 29 »). La cause du tour 3 était double : `poser-verdict.sh` faisait son I/O sur la clé NFC, introuvable sur ext4, et le test était aveugle au FS.

**Why:** macOS (APFS, insensible à la normalisation) rend vert un code qui joint racine + clé NFC puis ouvre le fichier ; ext4 non. Chaque tour local était vert, la CI seule a tranché.

**How to apply:** dans tout mandat qui touche une normalisation de chemin, exiger d'emblée la règle « forme et clé en NFC, I/O sur le nom du disque », le recensement de TOUTES les jonctions racine + chemin suivies d'I/O, et une preuve sous un shim de FS sensible (réutilisable : `vfc-ciemp-shim.py`, `fix46a-t3-nfd-*`). Ne pas clore avant la CI Linux. Voir [[liste-de-cas-ne-ferme-pas-une-classe]], [[correctif-de-securite-differentiel-a-n-versions]].
