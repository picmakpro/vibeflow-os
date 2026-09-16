---
name: scrolloff-lot-failures-not-auth-loss
description: Sur Scroll-Off/frontend, échecs lot2/lot3/lot4/lot5 en session authentifiée réelle ne signifient pas forcément perte de session
metadata:
  type: project
---

Cycle 1 de la boucle de test autonome (Phase 34, 2026-09-15) sur le lab
`~/Documents/dev/Scroll-Off/frontend`, cible simulateur iOS
`8BD53E84-B5BF-482A-8FE5-6A9980555951` (session JWT authentifiée réelle, non
reproductible). Run `mobile-test-run.mjs run` : 6/10 flows FAIL
(lot2_profil_no_layout_gap, lot3_logout_alert_cancel,
lot3_daily_target_formsheet_and_giveup_alert, lot3_app_selection_formsheet,
lot4_challenges_smoke, lot5_scrolls_scale_native_header).

Screenshots (`~/.maestro/tests/<run>/screenshot-❌-*.png`) montrent DEUX causes
distinctes, ni l'une ni l'autre n'étant le signal d'alarme "retour à
l'écran de login" (session intacte, JWT toujours valide — écran "Mes
réglages" bien affiché avec les données de session) :

1. **Réseau/backend** : toast "error in fetchCurrentUser: AxiosError:
   Net…" visible sur l'écran authentifié → `fetchCurrentUser` échoue,
   contenu dépendant (profil, cibles, challenges) reste vide → asserts
   texte échouent. Cause externe au dépôt (backend indisponible ou pas
   d'accès réseau depuis le simulateur), pas un bug app ni un bug de flow.
2. **Overlay Metro rouge "Uncaught Error: Property 'jest' doesn't exist"**
   pointant vers des fichiers `*.test.tsx` différents à chaque capture
   (`ios_index.test.tsx`, `index.test.tsx`) avec `jest.mock(...)` en cause
   — le bundler Metro semble embarquer des fichiers de test dans le bundle
   app runtime. Recouvre l'écran, cache le contenu attendu. Symptôme côté
   app/Metro config (probable watchman/fast-refresh qui inclut des
   `*.test.tsx`), à signaler à vf-app-fixer, pas un problème de flow
   Maestro.

Avant de conclure "session perdue" sur ce lab, toujours ouvrir les
screenshots d'échec (`~/.maestro/tests/<timestamp>/screenshot-❌-*.png`)
plutôt que de se fier au seul message d'assertion Maestro — un texte
absent peut venir d'un overlay d'erreur JS ou d'un appel réseau en échec,
pas seulement d'un écran de login.

Voir aussi [[ship-toujours-gate-humain]] pour le protocole de remontée
sans auto-réparation.
