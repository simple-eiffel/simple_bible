# 16 - NEEDLE: a tool-calling model and pure-Eiffel training (pointer, 2026-10-26)

**From:** the NEEDLE session (2026-10-25 to 2026-10-26), at Larry's request: "Check the NEEDLE session to see if what it is ultimately doing will be helpful or useful to this program."
**Status:** research input for a release after Release 1 (D-016: Release 1 has no run-time AI). Nothing in the spec changes.

## What exists

| Piece | What it is | State (2026-10-26) |
|---|---|---|
| Cactus Needle 3 | A tiny model (29M-121M parameters, an 8-29 MB file) for **tool calling** (pick a function and fill its arguments), **structured extraction**, and **embeddings**. CPU only. Released 2026-09-17 by Cactus Compute. License on the model card: **apache-2.0** (read through a summarizing fetch, P2-m: confirm the raw license file before anything ships, D-002/NFR-008). | Installed and measured in NEEDLE |
| `simple_needle` | Eiffel binding of `libneedle.dll` (one class, `NEEDLE_ENGINE`; `blocking` externals). Same answers as Python to six decimals; no network call; loads in 20 ms; 89.6 MB peak. | Built |
| `simple_tensor` | Pure-Eiffel tensors, autograd and training; Vulkan GPU backend (22 GLSL kernels; an MLP training step 56 ms on the RTX 5070 Ti vs 4.2 s on one CPU thread). Milestones: M2 RixGPT trained in Eiffel; M4 Needle forward pass; **M5 Needle LoRA fine-tune** exported to `.cact`. | M1 done, M3 GPU backend landing; M2 running |

## What NEEDLE measured that bears on simple_bible

- **Untrained tool calling on four Bible-study tools: 3.5 of 8 right** (66-107 ms each). It handled "word study on pistis" and "Genesis 1:3"; it failed "every use of hesed in the Psalms", "what does Romans 8:28 say" and "John 1:1 in the KJV", and answered "write me a poem about Easter" with a search call instead of declining.
- **Embeddings do not separate meaning:** "God's steadfast covenant love" vs "the loyal kindness of the LORD" 0.952; the same phrase vs "recipe for banana bread" 0.934.

## How it could serve simple_bible (to work out later, not decided)

1. **A plain-language front door** to the engine: a question becomes a call to the concordance's three lookups (word, English, verse; D-021), the query builder (GW-12) or the census. The engine still owns every fact (D-004); the model only routes, with its confidence shown. Fits D-003 (CPU-only machines, no setup), D-020 (no Python: simple_needle is Eiffel) and NFR-011 (no outbound connection).
2. **Needle fine-tuned on simple_bible's own tool set** (simple_tensor M5): the tool set is small and exact, and the engine can generate unlimited correctly labeled training questions from real headwords and references. This is the natural first real target for M5.
3. **Build-time work in Eiffel** (D-017 precompute; D-020's ports) on simple_tensor once it is proven.
4. **Not** for related passages or semantic search: the measured embeddings are too flat; D-013's embedding plan stands.

## Where it would land

- An AI edition after Release 1 (D-016), as a new run-time AI option beside D-013's mechanics; a fork for `/eiffel.debate` when that release is planned (Needle routing vs D-013's llama-server chat vs none).
- Prerequisites: simple_tensor M5 passes its gate (fine-tuned scores beat the untuned ones); the raw license confirmed; a routing accuracy gate on a held-out question set.

## Pointers

- simple_needle (binding, spike, parity tests), simple_tensor (README milestone table; `.eiffel-workflow/` plan), simple_rixgpt, simple_vulkan: fleet libraries beside simple_bible.
- NEEDLE session transcript (Scholars vault project), 2026-10-25 21:39 onward.
