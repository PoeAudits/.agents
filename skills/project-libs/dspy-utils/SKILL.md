---
name: dspy-utils
description: Use when working with DSPy library, needing pre-configured language models, loading data into dspy.Example format, managing prompts in external files, or building DSPy modules with the prompt-as-files pattern
---

# dspy-utils

Opinionated utility library for DSPy that provides pre-configured LMs, data loading, evaluation framework, and prompt-as-files pattern.

## Quick Reference

| Task | Function | Example |
|------|----------|---------|
| Use GPT-5 | `gpt_5`, `gpt_5_mini`, `gpt_5_nano` | `from dspy_utils import gpt_5_mini` |
| Use GPT-4 | `gpt_4`, `gpt_4_mini`, `gpt_4_nano` | `from dspy_utils import gpt_4_mini` |
| Load CSV | `load_data(path, input_keys)` | `load_data("data.csv", input_keys=("question",))` |
| Load JSON | `load_data(path, input_keys)` | `load_data("data.json", input_keys=("question",))` |
| Load Parquet | `load_data(path, input_keys)` | `load_data("data.parquet", input_keys=("question",))` |
| Load HuggingFace | `load_data(name, fields, input_keys, split)` | `load_data("hotpot_qa", fields=("question", "answer"), input_keys=("question",), split="train")` |
| Load from dicts | `to_examples(data, inputs)` | `to_examples([{"q": "...", "a": "..."}], inputs=["q"])` |
| Save examples | `save_examples(examples, path)` | `save_examples(train_data, "output.csv")` |
| Prompt from file | `with_instructions_from_file(sig, path)` | `with_instructions_from_file(MySig, "prompts/task.md")` |
| Save program | `save_program(sig, lm, prompt_path, program_path)` | `save_program(MySig, gpt_4_mini, "prompts/task.md", "programs/Task")` |
| Get signature inputs | `get_signature_inputs(sig)` | `get_signature_inputs(QA)` |
| Get formatted prompt | `get_prompt(program, adapter)` | `get_prompt(optimized_program)` |
| Merge examples | `merge_examples(*lists)` | `merge_examples(batch1, batch2)` |
| Combine results | `combine_batch_results(examples, predictions)` | `combine_batch_results(examples, results)` |
| Exact match grader | `exact_match(field)` | `exact_match("answer")` |
| Fuzzy match grader | `fuzzy_match(field, threshold)` | `fuzzy_match("answer", 0.85)` |
| Custom grader | `custom(name, fn)` | `custom("my_check", check_fn)` |
| LLM judge | `create_judge(mode, criteria)` | `create_judge("binary", "Is correct?")` |
| Run evaluation | `EvalHarness(program, graders)` | See Evaluation Framework section |
| Generate feedback | `FeedbackGenerator(task_goal)` | See GEPA section |

## Key Defaults

- **XMLAdapter**: Configured globally (better structured outputs than ChatAdapter)
- **Caching**: Enabled on all LMs
- **Temperature**: 0.2 (balances determinism with flexibility)
- **Lazy loading**: LMs instantiated on first use, not at import
- **JSON preferred**: Program serialization prefers JSON for human readability

## Module Overview

```
dspy_utils/
├── lm.py         # Pre-configured language models
├── data.py       # Data loading utilities (CSV, JSON, Parquet, HuggingFace)
├── sig.py        # Signature and program utilities
├── examples.py   # Example manipulation utilities
├── evals.py      # Evaluation harness, graders, and LLM judges
├── gepa.py       # GEPA optimization helpers (FeedbackGenerator)
└── config/       # Environment configuration (.env loading)
```

## Common Patterns

### Quick Model Access
```python
from dspy_utils import gpt_5_mini
import dspy

# Direct call
result = gpt_5_mini("What is 2+2?")

# With DSPy programs
class QA(dspy.Signature):
    question: str = dspy.InputField()
    answer: str = dspy.OutputField()

qa = dspy.Predict(QA)
qa.set_lm(gpt_5_mini)
response = qa(question="What is the capital of France?")
```

### Loading Data
```python
from dspy_utils import load_data, to_examples

# From CSV file
examples = load_data("train.csv", input_keys=("question",))

# From JSON file
examples = load_data("train.json", input_keys=("question",))

# From Parquet file
examples = load_data("train.parquet", input_keys=("question",))

# From HuggingFace
examples = load_data(
    "hotpot_qa",
    fields=("question", "answer"),
    input_keys=("question",),
    split="train"
)

# From list of dicts (with shuffle)
examples = to_examples(
    [{"question": "...", "answer": "..."}],
    inputs=["question"],
    shuffle=True,
    seed=42
)
```

### Saving Examples
```python
from dspy_utils import save_examples

# Save examples to CSV
save_examples(train_examples, "output/train.csv")
```

### Prompt-as-Files Module Pattern
```python
import os
import dspy
from dspy_utils import save_program, gpt_4_mini

class Filter(dspy.Signature):
    """Filter irrelevant content."""
    text: str = dspy.InputField()
    result: bool = dspy.OutputField()

class Oracle(dspy.Module):
    def __init__(self, refresh_programs: bool = False):
        programs_exist = os.path.exists("programs/Filter/program.pkl")

        if refresh_programs or not programs_exist:
            # Load prompt from markdown, save serialized program
            save_program(Filter, gpt_4_mini, "prompts/filter.md", "programs/Filter")

        # Load from disk
        self.filter = dspy.load("programs/Filter")
        
        # Also save JSON for inspection
        self.filter.save("programs/Filter/program.json")

    def forward(self, text):
        return self.filter(text=text)
```

**Directory structure:**
```
project/
  prompts/
    filter.md       # Edit prompts here
  programs/
    Filter/
      program.pkl   # Loaded by dspy.load()
      program.json  # Human-readable inspection
```

**Workflow:**
1. Edit prompts in `prompts/*.md`
2. Call module with `refresh_programs=True`
3. Programs serialize to `programs/*/program.pkl`
4. JSON files for debugging/inspection

### Combining Examples with Results
```python
from dspy_utils import load_data, combine_batch_results, merge_examples

# Run batch predictions
examples = load_data("data.csv", input_keys=("question",))
results = [qa(question=ex.question) for ex in examples]

# Merge into list of dicts
combined = combine_batch_results(examples, results)
# [{'question': '...', 'answer': '...'}, ...]

# Or merge example lists (for split processing)
merged = merge_examples(batch1_examples, batch2_examples)
```

### Extracting Signature Information
```python
from dspy_utils import get_signature_inputs, get_prompt

# Get input field names from a signature
inputs = get_signature_inputs(QA)  # Returns: ['question']

# Get formatted prompt from an optimized program
prompt_text = get_prompt(optimized_program)
```

## Evaluation Framework

The evaluation framework provides code-based graders, LLM-as-judge graders, and a harness for running multi-trial evaluations.

### Code-based Graders

```python
from dspy_utils import (
    exact_match,      # Exact string match
    fuzzy_match,      # Similarity >= threshold (SequenceMatcher)
    regex_match,      # Regex pattern matching
    contains,         # Substring check
    contains_all,     # All substrings present (partial credit)
    contains_any,     # Any substring present
    numeric_close,    # Numeric proximity check
    custom,           # Wrap any callable as grader
)

graders = [
    exact_match("answer"),
    fuzzy_match("answer", threshold=0.85),
    regex_match(r"\d{4}", "year"),
    contains("Paris", "answer"),
    contains_all(["name", "date"], "response"),
    contains_any(["yes", "no"], "decision"),
    numeric_close("value", tolerance=0.01),
]
```

### Custom Graders

```python
from dspy_utils import custom, GraderResult

# Simple: return float score
def check_length(expected: dict, pred) -> float:
    expected_len = len(expected.get("answer", ""))
    actual_len = len(getattr(pred, "answer", ""))
    return min(expected_len, actual_len) / max(expected_len, actual_len, 1)

# Advanced: return GraderResult for more control
def check_format(expected: dict, pred) -> GraderResult:
    answer = getattr(pred, "answer", "")
    has_period = answer.endswith(".")
    starts_capital = answer[0].isupper() if answer else False
    score = (0.5 if has_period else 0.0) + (0.5 if starts_capital else 0.0)
    
    return GraderResult(
        name="format_check",
        passed=score >= 0.5,
        score=score,
        message=f"Period: {has_period}, Capital: {starts_capital}",
    )

graders = [
    custom("length_check", check_length),
    custom("format_check", check_format),
]
```

### LLM-as-Judge Graders

```python
from dspy_utils import create_judge, BinaryJudge, CriteriaJudge, ComparativeJudge

# Binary judge (pass/fail, score 0 or 1)
binary_judge = create_judge(
    mode="binary",
    criteria="The answer is factually correct and addresses the question",
)

# Criteria judge (percentage of criteria passed)
criteria_judge = CriteriaJudge(criteria=[
    "Answer is factually correct",
    "Answer is well-structured",
    "Answer provides sufficient detail",
])

# Comparative judge (ordinal: much_worse to much_better)
comparative_judge = create_judge(
    mode="comparative",
    criteria="Answer quality and completeness",
)

# Use as grader in EvalHarness
grader = binary_judge.as_grader(expected_field="answer")
```

### Running Evaluations

```python
from dspy_utils import (
    EvalTask,
    EvalSuite,
    EvalHarness,
    exact_match,
    fuzzy_match,
    gpt_4_mini,
)
import dspy

# 1. Define your program
class QA(dspy.Signature):
    question: str = dspy.InputField()
    answer: str = dspy.OutputField()

qa = dspy.Predict(QA)
qa.set_lm(gpt_4_mini)

# 2. Create tasks manually
tasks = [
    EvalTask(
        id="capital_1",
        inputs={"question": "What is the capital of France?"},
        expected={"answer": "Paris"},
    ),
    EvalTask(
        id="capital_2",
        inputs={"question": "What is the capital of Japan?"},
        expected={"answer": "Tokyo"},
    ),
]

# Or create from existing examples
from dspy_utils import load_data
examples = load_data("test.csv", input_keys=("question",))
suite = EvalSuite.from_examples(
    name="QA Test Suite",
    examples=examples,
    expected_fields=["answer"],
)

# 3. Configure harness with graders
harness = EvalHarness(
    program=qa,
    graders=[
        exact_match("answer"),
        fuzzy_match("answer", threshold=0.85),
    ],
    num_trials=5,      # Run each task 5 times
    num_threads=4,     # Parallel execution
)

# Optional: weight graders differently
harness = EvalHarness(
    program=qa,
    graders=[exact_match("answer"), fuzzy_match("answer", 0.85)],
    grader_weights={
        "exact_match:answer": 0.7,
        "fuzzy_match:answer": 0.3,
    },
)

# 4. Run evaluation
results = harness.run(tasks)  # or harness.run(suite)

# 5. Analyze results
print(f"Mean score: {results.mean_score():.2%}")
print(f"pass@1: {results.pass_at_k(1):.2%}")   # Prob of success in 1 attempt
print(f"pass@5: {results.pass_at_k(5):.2%}")   # Prob of at least 1 success in 5
print(f"pass^5: {results.pass_pow_k(5):.2%}")  # Prob of ALL 5 succeeding
print(results.summary())

# 6. Save results
results.save_json("eval_results/qa_test.json")
```

### Key Metrics

| Metric | Description |
|--------|-------------|
| `mean_score()` | Average score across all trials |
| `pass_at_k(k)` | Probability of at least 1 success in k attempts (from Codex paper) |
| `pass_pow_k(k)` | Probability of ALL k attempts succeeding (pass^k) |

## GEPA Optimization

GEPA (Genetic-Pareto) is DSPy's recommended optimizer for prompt optimization with feedback-driven reflection.

### Key Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `metric` | `GEPAFeedbackMetric` | 5-param function returning score + optional feedback |
| `reflection_lm` | `dspy.LM` | LM for reflection (use high temperature, e.g., 1.0) |
| `auto` | `"light" \| "medium" \| "heavy"` | Preset budget (6/12/18 candidates) |
| `max_metric_calls` | `int` | Explicit budget cap on metric invocations |
| `log_dir` | `str` | Directory for logs/checkpoints (enables resumption) |
| `num_threads` | `int` | Parallel threads for evaluation |
| `track_stats` | `bool` | Return detailed results in `detailed_results` attribute |

### Metric Protocol

GEPA metrics must accept 5 parameters:

```python
def metric(
    gold: dspy.Example,           # Ground truth example
    pred: dspy.Prediction,        # Model prediction
    trace=None,                   # Full execution trace
    pred_name: str = None,        # Current predictor being optimized
    pred_trace=None,              # Trace for specific predictor
) -> float | dict:
    """
    Return either:
    - float: Score only (GEPA generates default feedback)
    - dict: {"score": float, "feedback": str} for custom feedback
    """
    correct = gold.answer.lower() == pred.answer.lower()
    score = 1.0 if correct else 0.0
    feedback = "Correct!" if correct else f"Expected '{gold.answer}', got '{pred.answer}'"
    return {"score": score, "feedback": feedback}
```

### FeedbackGenerator

Pre-generate textual feedback for training examples:

```python
from dspy_utils import FeedbackGenerator, gpt_4_mini

generator = FeedbackGenerator(
    task_goal="Extract named entities from the text",
    lm=gpt_4_mini,  # Optional, defaults to globally configured LM
)

# Generate feedback for training examples
train_with_feedback = generator.generate_feedback(
    examples=train_examples,
    output_field="entities",
    correctness_fn=lambda ex: ex.score >= 0.8,
)

# Access in metric via gold._feedback
def metric(gold, pred, trace=None, pred_name=None, pred_trace=None):
    score = compute_score(gold, pred)
    feedback = getattr(gold, "_feedback", f"Score: {score}")
    return {"score": score, "feedback": feedback}
```

### Using LLM Judges as GEPA Metrics

```python
from dspy_utils import create_judge, gpt_5

# Create judge
judge = create_judge(
    mode="binary",
    criteria="The answer correctly addresses the question",
    lm=gpt_4_mini,
)

# Convert to GEPA metric
metric = judge.as_metric(expected_field="answer")

# Use with GEPA
gepa = dspy.GEPA(
    metric=metric,
    reflection_lm=dspy.LM("openai/gpt-5", temperature=1.0, max_tokens=32000),
    auto="medium",
)
optimized = gepa.compile(student, trainset=train, valset=val)
```

### Basic GEPA Pattern

```python
import dspy
from dspy_utils import gpt_5, gpt_4_mini

# Define metric
def metric(gold, pred, trace=None, pred_name=None, pred_trace=None):
    correct = gold.answer.lower() == pred.answer.lower()
    return {
        "score": 1.0 if correct else 0.0,
        "feedback": f"Expected '{gold.answer}', got '{pred.answer}'"
    }

# Configure GEPA
gepa = dspy.GEPA(
    metric=metric,
    reflection_lm=dspy.LM("openai/gpt-5", temperature=1.0, max_tokens=32000),
    auto="medium",
    log_dir="./gepa_logs",  # Enable checkpointing/resumption
)

# Run optimization
optimized = gepa.compile(student, trainset=train, valset=val)

# Save optimized program
optimized.save("programs/Optimized/program.pkl")
optimized.save("programs/Optimized/program.json")
```

## Available Models

| Model | Use Case | Max Tokens |
|-------|----------|------------|
| `gpt_5_1`, `gpt_5`, `gpt_5_mini`, `gpt_5_nano` | Reasoning tasks | 50k |
| `gpt_4`, `gpt_4_mini`, `gpt_4_nano` | Non-reasoning, fewer output tokens | 10k |
| `ollama_gpt`, `ollama_llama` | Local models | - |
| `cloud_gpt` | Cloud-hosted gpt-oss:120b | - |
| `hugging_face` | Kimi-K2-Instruct | - |

## Overriding Defaults

```python
import dspy
from dspy.adapters import ChatAdapter
from dspy_utils import gpt_5

# Global override
dspy.configure(adapter=ChatAdapter())

# Local override
with dspy.context(adapter=ChatAdapter()):
    result = gpt_5("Generate creative story...")
```

## Environment Setup

Requires `.env` file with API keys:
```
OPEN_AI_API_KEY=sk-...
OLLAMA_API_KEY=...
HUGGING_FACE_TOKEN=hf_...
```

Library prefers local `.env` over package root.
