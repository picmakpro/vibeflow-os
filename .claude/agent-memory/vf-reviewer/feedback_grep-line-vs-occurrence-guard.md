---
name: grep-line-vs-occurrence-guard
description: grep -F | grep -vF exemption filters over source lines operate at line granularity, not occurrence — a single physical line carrying both the legit exempted substring and an illegitimate second occurrence defeats them
metadata:
  type: feedback
---

A guard shaped `grep -F '<pattern>' | grep -vF '<exact exempted substring>'` removes the WHOLE
line once it contains the exempted substring anywhere on it — even if the same line also carries a
second, illegitimate occurrence of the pattern being guarded against. Confirmed live on the T9e
autonomy guard (D-04) in `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh`
(Phase 38, commit `40c8f0f`): `c="$(dirname "$0")/runtime-cli-dispatch.sh";
d="$(dirname "$0")/../conductor/scripts/foo.sh"` passes the guard clean because the line contains
the exempted substring, hiding the second `$(dirname "$0")/...` resolution on the same line.

**Why:** this was the THIRD narrowing of the same guard within Phase 38 — each fix closed one
bypass class and revealed a finer one (substring-anywhere-on-line → cross-module-disguised-as-
same-filename → line-granularity-with-multiple-occurrences). A guard repeatedly tightened without
changing its fundamental matching unit (line vs occurrence) tends to keep leaking at the same
granularity. See [[multicondition-guard-mutate-each]] and [[mirror-gate-superset-drift]] for
related guard-mutation patterns.

**How to apply:** when reviewing or mutation-testing any `grep pattern | grep -v exemption`-shaped
guard, don't stop at one mutant per physical line. Construct a mutant that packs the legitimate
exempted pattern AND the violation on the SAME line (via `;` or `&&`) — that's the next bypass
class an exact-substring fix doesn't close. The durable fix is occurrence-level extraction (e.g.
`grep -oE` to emit one occurrence per output line, then filter each occurrence independently)
rather than line-level filtering.
