---
quick_id: 261001-qq9
status: complete
---

# Quick 261001-qq9 : SUMMARY

## Cause racine (mesurée, poste 8 cœurs, 20 rejeux par cas)

| Cas | Charge | Durée min / méd / max | Verdicts |
|---|---|---|---|
| original, 3 × 30 000 | faible | 0,04 / 0,04 / 0,05 s | 20/20 passage |
| mutant CHAMP, 3 × 30 000 | faible | 3,46 / 3,49 / 3,59 s | 20/20 non coupé (un rc 142, voir ci-dessous) : tué uniquement par la borne 2 s |
| original, 3 × 30 000 | 16 `yes` | 0,12 / 0,17 / 0,24 s | 20/20 passage |
| mutant CHAMP, 3 × 30 000 | 16 `yes` | 8,14 / 8,23 / 8,42 s | 20/20 coupé par l'échéance (rc 73) |
| original, 30 × 32 000 | faible | 0,04 / 0,04 / 0,05 s | 20/20 passage |
| mutant CHAMP, 30 × 32 000 | faible | 8,05 / 8,11 / 10,47 s | 20/20 rc 73 |
| mutant FM, 30 × 32 000 | faible | 8,16 / 8,23 / 8,67 s | 20/20 rc 73 |
| original, 30 × 32 000 | 16 `yes` | 0,11 / 0,14 / 0,16 s | 20/20 passage |
| mutant CHAMP, 30 × 32 000 | 16 `yes` | 8,11 / 8,31 / 8,41 s | 20/20 rc 73 |

Hypothèse A confirmée : le tueur était la seule borne de 2 s ; le mutant coûte 3,5 s ici, 4,19 s sur le run push, moins
de 2 s sur le run pull_request. Hypothèse B écartée comme cause de la survie : l'échéance (z) ne fait que COUPER le mutant
sous charge (3 × 30 000 sous charge : 8,2 s, rc 73), jamais le masquer ; elle devient le tueur déterministe avec le correctif.

## Correctif

R-DEFS-02 : définition piégée de 30 puces de 32 000 espaces (960 Ko). Mutant ≈ 40 s non coupé, cinq fois l'échéance de 8 s.
Original inchangé et linéaire. Libellés `ok` inchangés.

## Preuves

Section `lota` + `PUCE-REGEX` rejouée : charge faible, FM et CHAMP TUÉS (`trap : deny [planning-core] hook central
indisponible ... en 8.24 s (attendu passage en moins de 2 s)`) ; sous charge, FM et CHAMP TUÉS, R-DEFS-02 vert.
Suite entière : 446 OK, 0 KO. test-planning-hook-registered.sh : 50 OK, 0 KO.

## Constats hors périmètre (non touchés)

- `rc 142` (SIGALRM non géré) observé 1 fois sur 20 sur le mutant 3 × 30 000 : le minuteur du cœur reste armé pendant la
  finalisation de l'interpréteur ; sans conséquence tant que le cœur original dure moins de 0,5 s.
- R-N1-01 rougit sous 16 `yes` (borne de 3 s sur l'ORIGINAL) : même famille, borne d'horloge sensible à la charge.
