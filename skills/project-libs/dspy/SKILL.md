---
name: dspy
description: Use when working with DSPy library, dspy, signatures, modules, GEPA, optimization, prompt optimization, language model configuration, batch inference, dspy.Example, dspy.Predict, dspy.Module. Provides proven inline patterns for LM setup, data loading, signature management, batch processing, and GEPA optimization — all self-contained, no library imports needed.
---

# DSPy Patterns

Self-contained patterns for DSPy projects. All snippets are inline — regenerate them fresh in any project. Never import from `dspy_utils`.

**When creating a new DSPy project or adding DSPy functionality from scratch**, read [references/code-snippets.md](references/code-snippets.md) for the canonical code implementations. Copy them directly into your project.

**When implementing feedback generation for GEPA**, read [references/feedback-generation.md](references/feedback-generation.md) for the complete pattern — signature, module, batch generation, and data format.

## Section Overview

### 1. LM Setup & Configuration

Environment loading with `.env` fallback, direct `dspy.LM()` instantiation for model presets (GPT-5/GPT-4/Ollama), XMLAdapter configuration, and adapter overrides via `dspy.context`.

### 2. Data Loading & Saving

**Training utilities:** Load CSV/JSON/Parquet/HuggingFace into `dspy.Example` lists, convert dicts to examples, save examples to CSV, zip-merge example lists.

**Inference utilities:** Load CSV as raw dicts (preserving all columns), filter to signature input columns, run `module.batch()`, merge predictions with original data (prefixed `pred_`), save to CSV.

### 3. Signatures & Modules

Define typed signatures with `dspy.InputField`/`dspy.OutputField`. **Use `Literal` types on output fields** to constrain outputs to valid values (e.g., `Literal["positive", "negative", "neutral"]`). **Always wrap signatures in a `dspy.Module` subclass** — never use bare `dspy.Predict()`. Load prompt instructions from markdown files with `with_instructions_from_file`. Save/load program state as JSON. Advanced: prompt-as-files module pattern.

### 4. Batch Inference

Use `module.batch()` with threading for parallel inference. Use `return_failed_examples=True` to capture failures — returns a 3-tuple `(results, failed_examples, exceptions)`. Without the flag, returns `list[dspy.Example]`. **Note:** DSPy's type hints don't reflect the 3-tuple return — always add `# type: ignore[misc]` when unpacking.

### 5. GEPA Optimization

GEPA optimizes prompts with feedback-driven reflection. Metrics accept 5 parameters and return `float` (program-level) or `dspy.Prediction(score, feedback)` (predictor-level). Configure with `auto` budget presets, a high-temperature `reflection_lm`, and appropriate `reflection_minibatch_size`.

**Minibatch size:** The coarser your metric, the more minibatch examples you need.

| Metric Type | Recommended `reflection_minibatch_size` | Why |
|-------------|------------------------------|-----|
| Binary (0 or 1) | 20+ | With 3 samples, all-pass is discarded as trivial, 2/3 caps at 66% |
| Discrete (0, 0.5, 1) | 10-15 | More granularity but still needs enough for signal |
| Continuous (0.0-1.0) | 5-6 | Fine-grained scores give sufficient signal |

### 6. Storage Conventions

Standard directory layout under `~/Overlord/files/dspy/`:

```
~/Overlord/files/dspy/
├── datasets/       # CSV/JSON data files (input, output, train, val)
├── programs/       # Serialized DSPy programs (JSON state)
│   └── Classify/
│       └── program.json   # Saved via module.save(), loaded via module.load()
└── prompts/        # Markdown prompt files
    └── classify.md
```

### 7. Key Defaults & Tips

| Setting | Default | Rationale |
|---------|---------|-----------|
| Adapter | `XMLAdapter` | Better structured outputs than ChatAdapter |
| Temperature | `0.2` | Balances determinism with flexibility |
| Caching | `True` on all LMs | Avoid redundant API calls |
| GPT-5 max_tokens | `50000` | Reasoning models need more output space |
| GPT-4 max_tokens | `10000` | Non-reasoning models, fewer tokens |

**Tips:**
- Always call `.with_inputs()` on examples to mark input fields — required for DSPy optimization
- Always wrap signatures in a `dspy.Module` — enables `module.batch()`, composition, and GEPA
- Use `return_failed_examples=True` with `batch()` to capture and retry failures
- Use `dspy.context(lm=...)` for temporary LM overrides without changing global config
- Save programs as JSON via `module.save("program.json")` — load with `module.load(path="program.json")`
- GEPA's `reflection_lm` should use high temperature (1.0) for diverse prompt candidates
- Set `log_dir` on GEPA to enable checkpoint resumption on long optimization runs
- Set `reflection_minibatch_size` on GEPA based on metric granularity — default (3) is almost never sufficient

## Quick Reference

| Function | Section | Purpose |
|----------|---------|---------|
| `load_env_prefer_local` | 1 | Load `.env` with local-first fallback |
| `load_data` | 2 | Load CSV/JSON/Parquet/HuggingFace into examples |
| `to_examples` | 2 | Convert dicts or CSV to `dspy.Example` list |
| `save_examples` | 2 | Save examples to CSV |
| `load_csv_raw` | 2 | Load CSV as raw dicts (all columns) |
| `to_inference_examples` | 2 | Filter raw dicts to signature input columns |
| `combine_results` | 2 | Merge raw dicts + predictions (prefixed `pred_`) |
| `save_csv` | 2 | Save list of dicts to CSV |
| `merge_examples` | 2 | Zip-merge multiple example lists |
| `with_instructions_from_file` | 3 | Load prompt markdown into a signature |
| `save_program` | 3 | Save module state as JSON |
| `get_prompt` | 3 | Extract formatted prompt from optimized program |
| `get_signature_inputs` | 3 | Introspect input fields from a signature |

All implementations are in [references/code-snippets.md](references/code-snippets.md).

## GEPA Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `metric` | callable | 5-param function (see section 5) |
| `reflection_lm` | `dspy.LM` | LM for reflection (use high temperature, e.g. 1.0) |
| `auto` | `"light" \| "medium" \| "heavy"` | Preset budget (6/12/18 candidates) |
| `reflection_minibatch_size` | `int` | Examples per reflection batch — default 3 is too low for binary metrics, use 20+ |
| `max_metric_calls` | `int` | Explicit budget cap on metric invocations |
| `log_dir` | `str` | Directory for logs/checkpoints |
| `num_threads` | `int` | Parallel threads for evaluation |
| `track_stats` | `bool` | Return detailed results |

## References

- [references/code-snippets.md](references/code-snippets.md) — All implementation patterns (copy into projects)
- [references/feedback-generation.md](references/feedback-generation.md) — Feedback generation for GEPA optimization (enriching gold examples)
- [references/text-classification.md](references/text-classification.md) — Full end-to-end text classification pipeline example
