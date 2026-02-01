# Text Classification Pipeline with DSPy + GEPA

End-to-end reference for binary text classification using DSPy and GEPA optimization.

**Pipeline overview:**
1. **Data Preparation** — Load raw dataset, curate gold examples, handle label remapping
2. **Feedback Generation** — Enrich gold examples with LLM-generated feedback (external project)
3. **GEPA Optimization** — Optimize classification prompt using feedback-enriched gold set
4. **Batch Inference** — Score full dataset with optimized program, recombine with original columns

**Concrete example:** Classify crypto/web3 messages as `relevant` or `irrelevant`.

**Utility functions:** This guide uses utilities from [code-snippets.md Section 2](code-snippets.md#2-data-loading--saving). Copy the implementations from there — they are not redefined here.

**Storage conventions:**
```
~/Overlord/files/dspy/
├── datasets/           # Raw and curated datasets
│   ├── messages.csv            # Full dataset (~5000 rows)
│   ├── gold.csv                # Curated gold set (30-40 rows)
│   └── gold_with_feedback.csv  # Gold set enriched with feedback
├── programs/           # Serialized DSPy programs
│   └── Classifier/
│       └── program.json        # Saved/loaded via module.save() / module.load()
└── prompts/            # Prompt markdown files
    └── classifier.md           # Editable prompt instructions
```

---

## Stage 1: Data Preparation

### 1.1 Load the raw dataset

```python
import dspy
from pathlib import Path
from csv import DictReader, DictWriter

BASE = Path.home() / "Overlord/files/dspy"
DATASETS = BASE / "datasets"

# Load raw CSV into dspy.Example list
def load_csv(path: str | Path, input_keys: list[str]) -> list[dspy.Example]:
    examples = []
    with open(path, encoding="utf-8") as f:
        for row in DictReader(f):
            ex = dspy.Example(**row).with_inputs(*input_keys)
            examples.append(ex)
    return examples

all_data = load_csv(DATASETS / "messages.csv", input_keys=["text"])
print(f"Loaded {len(all_data)} examples")
# Loaded 5000 examples
```

### 1.2 Curate gold examples

Manually select 30-40 representative examples covering both classes and edge cases.

```python
import random

# Option A: Hand-pick by index or content review
# Export a sample for manual labeling
def export_sample_for_labeling(
    examples: list[dspy.Example],
    output_path: str | Path,
    sample_count: int = 100,
    seed: int = 42,
) -> None:
    random.seed(seed)
    sample = random.sample(examples, min(sample_count, len(examples)))
    data = [ex.toDict() for ex in sample]
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)

export_sample_for_labeling(all_data, DATASETS / "sample_for_labeling.csv")
# → Manually review, label 30-40 as gold, save as gold.csv
```

### 1.3 Load gold set with label remapping

Datasets often have inconsistent labels. Remap before creating examples.

```python
# Label remapping — normalize labels before creating examples
LABEL_MAP: dict[str, str] = {
    "yes": "relevant",
    "no": "irrelevant",
    "1": "relevant",
    "0": "irrelevant",
    "true": "relevant",
    "false": "irrelevant",
    "relevant": "relevant",
    "irrelevant": "irrelevant",
}

def load_gold(
    path: str | Path,
    input_keys: list[str],
    label_field: str = "label",
    label_map: dict[str, str] | None = None,
) -> list[dspy.Example]:
    examples = []
    with open(path, encoding="utf-8") as f:
        for row in DictReader(f):
            if label_map and label_field in row:
                raw_label = row[label_field].strip().lower()
                row[label_field] = label_map.get(raw_label, row[label_field])
            ex = dspy.Example(**row).with_inputs(*input_keys)
            examples.append(ex)
    return examples

gold = load_gold(
    DATASETS / "gold.csv",
    input_keys=["text"],
    label_field="label",
    label_map=LABEL_MAP,
)
print(f"Gold set: {len(gold)} examples")
# Gold set: 35 examples
```

### 1.4 Mark input fields correctly

DSPy requires explicit input field marking. Everything not marked as input is treated as an output (ground truth during optimization).

```python
# CRITICAL: with_inputs() tells DSPy which fields are inputs vs outputs
# Only input fields are passed to the program during optimization
# Output fields are used as ground truth for the metric

# For classification: text is input, label is output (ground truth)
example = dspy.Example(text="BTC just hit 100k!", label="relevant")
example = example.with_inputs("text")

# example.inputs() → {"text": "BTC just hit 100k!"}
# example.labels() → {"label": "relevant"}
```

---

## Stage 2: Feedback Generation

Feedback generation enriches gold examples with LLM-generated analysis explaining *why* each label is correct. This gives GEPA richer signal for prompt optimization.

> **Full implementation details:** See [feedback-generation.md](feedback-generation.md) for the complete feedback generation reference — signature, module, batch generation, and data format. The code below documents the data format for quick reference.

### 2.1 What feedback-enriched data looks like

After feedback generation, each gold example gains two private fields:

```python
# Before feedback generation:
# {"text": "BTC just hit 100k!", "label": "relevant"}

# After feedback generation:
# {
#     "text": "BTC just hit 100k!",
#     "label": "relevant",
#     "_feedback": "This message directly discusses Bitcoin price action...",
#     "_feedback_reasoning": "The message contains a specific cryptocurrency mention..."
# }
```

The `_feedback` field is accessed in the GEPA metric via `gold._feedback` or `getattr(gold, "_feedback", "")`.

### 2.2 FeedbackSignature pattern

The signature used by the feedback generation project:

```python
import dspy


class FeedbackSignature(dspy.Signature):
    """Analyze how well the outputs match the expected results for the given inputs and task."""

    task_goal: str = dspy.InputField(desc="The goal or objective of the task")
    inputs: str = dspy.InputField(desc="The input data provided to the system")
    expected_output: str = dspy.InputField(desc="The expected/ground truth output")
    actual_output: str = dspy.InputField(
        desc="The actual output produced by the system"
    )
    is_correct: bool = dspy.InputField(
        desc="Whether the output was marked as correct"
    )

    reasoning: str = dspy.OutputField(
        desc="Analysis of why the outputs match or don't match the expected results"
    )
    feedback: str = dspy.OutputField(
        desc="Constructive feedback explaining the quality of the output and suggestions for improvement"
    )
```

The feedback project calls this signature for each gold example, comparing the expected label against an actual model prediction, then attaches `_feedback` and `_feedback_reasoning` to the example.

### 2.3 Loading feedback-enriched gold set

```python
def load_gold_with_feedback(
    path: str | Path,
    input_keys: list[str],
    label_field: str = "label",
    label_map: dict[str, str] | None = None,
) -> list[dspy.Example]:
    """Load gold CSV that includes _feedback and _feedback_reasoning columns."""
    examples = []
    with open(path, encoding="utf-8") as f:
        for row in DictReader(f):
            if label_map and label_field in row:
                raw_label = row[label_field].strip().lower()
                row[label_field] = label_map.get(raw_label, row[label_field])
            ex = dspy.Example(**row).with_inputs(*input_keys)
            examples.append(ex)
    return examples

gold = load_gold_with_feedback(
    DATASETS / "gold_with_feedback.csv",
    input_keys=["text"],
    label_field="label",
    label_map=LABEL_MAP,
)

# Verify feedback is present
sample = gold[0]
print(f"Has feedback: {hasattr(sample, '_feedback')}")
print(f"Feedback: {sample._feedback[:100]}...")
```

---

## Stage 3: GEPA Optimization

### 3.1 Define the classification signature and module

```python
import dspy


class Classify(dspy.Signature):
    """Classify a crypto/web3 message as relevant or irrelevant."""

    text: str = dspy.InputField(desc="The message text to classify")
    label: str = dspy.OutputField(desc="Classification: 'relevant' or 'irrelevant'")


class MessageClassifier(dspy.Module):
    def __init__(self):
        self.predict = dspy.Predict(Classify)

    def forward(self, text: str):
        return self.predict(text=text)
```

### 3.2 Define the GEPA metric

The metric must accept 5 parameters. Return `dspy.Prediction(score=float, feedback=str)` when `pred_name` is provided (GEPA requesting predictor-level feedback), or just a `float` otherwise.

```python
import dspy


def classification_metric(
    gold: dspy.Example,
    pred: dspy.Prediction,
    trace=None,
    pred_name: str | None = None,
    pred_trace=None,
) -> float | dspy.Prediction:
    expected = gold.label.strip().lower()
    predicted = pred.label.strip().lower()
    score = 1.0 if expected == predicted else 0.0

    # Program-level: just return the score
    if pred_name is None:
        return score

    # Predictor-level: return score + feedback for GEPA reflection
    # Use pre-generated feedback if available, otherwise construct inline
    feedback = getattr(gold, "_feedback", "")
    if not feedback:
        if score == 1.0:
            feedback = f"Correct. The message is '{expected}'."
        else:
            feedback = (
                f"Incorrect. Expected '{expected}' but got '{predicted}'. "
                f"Re-examine the message content and classification criteria."
            )

    return dspy.Prediction(score=score, feedback=feedback)
```

**Key points about the metric:**
- `pred_name is None` → GEPA is evaluating the full program → return `float`
- `pred_name is not None` → GEPA wants predictor-specific feedback → return `dspy.Prediction(score=float, feedback=str)`
- `gold._feedback` contains pre-generated feedback from Stage 2 (if available)
- Always normalize labels before comparison (`.strip().lower()`)

### 3.3 Split gold set for optimization

```python
import random

random.seed(42)
random.shuffle(gold)

# GEPA needs trainset and valset
split_idx = int(len(gold) * 0.7)
train_set = gold[:split_idx]
val_set = gold[split_idx:]

print(f"Train: {len(train_set)}, Val: {len(val_set)}")
# Train: 24, Val: 11
```

### 3.4 Configure and run GEPA

```python
import dspy
from pathlib import Path

BASE = Path.home() / "Overlord/files/dspy"
PROGRAMS = BASE / "programs"

# Configure the LM for the student program
lm = dspy.LM("openai/gpt-4.1-mini-2025-04-14", temperature=0.2, max_tokens=10000)
dspy.configure(lm=lm)

# Create student module
student = MessageClassifier()

# Configure GEPA
gepa = dspy.GEPA(
    metric=classification_metric,
    reflection_lm=dspy.LM("openai/gpt-5", temperature=1.0, max_tokens=32000),
    auto="medium",                          # 12 candidates (light=6, heavy=18)
    reflection_minibatch_size=20,           # Binary metric (0/1) needs large batches — default 3 is insufficient
    log_dir=str(BASE / "gepa_logs"),        # Enables checkpointing/resumption
    num_threads=8,
    track_stats=True,
)

# Run optimization
optimized = gepa.compile(student, trainset=train_set, valset=val_set)

# Save optimized program (JSON state — human-readable, no pickle)
program_dir = PROGRAMS / "Classifier"
program_dir.mkdir(parents=True, exist_ok=True)
optimized.save(str(program_dir / "program.json"))

print(f"Saved optimized program to {program_dir}")
```

### 3.5 Evaluate optimized program

```python
import dspy

evaluate = dspy.Evaluate(
    devset=val_set,
    metric=classification_metric,
    num_threads=8,
    display_progress=True,
    display_table=True,
)

result = evaluate(optimized)
print(f"Validation score: {result.score:.1f}%")
```

---

## Stage 4: Batch Inference

Score the full dataset (~5000 examples) with the optimized program. The critical pattern here is **filtering to input columns before inference, then recombining with original data after**.

> **Utility functions** (`load_csv_raw`, `to_inference_examples`, `combine_results`, `save_csv`) are defined in [code-snippets.md Section 2](code-snippets.md#2-data-loading--saving). Copy them into your project.

### 4.1 Why column filtering matters

DSPy is fragile with data shapes. If your CSV has columns like `source`, `timestamp`, `author` that aren't in the signature, DSPy may error or produce unexpected behavior. The solution:

1. Load full dataset (all columns) with `load_csv_raw()`
2. Filter to only signature input columns with `to_inference_examples()`
3. Run `module.batch()` on filtered examples
4. Recombine predictions with original data using `combine_results()`

### 4.2 Load optimized program

```python
import dspy
from pathlib import Path

BASE = Path.home() / "Overlord/files/dspy"
PROGRAMS = BASE / "programs"
DATASETS = BASE / "datasets"

# Configure the same LM used during optimization
lm = dspy.LM("openai/gpt-4.1-mini-2025-04-14", temperature=0.2, max_tokens=10000)
dspy.configure(lm=lm)

# Load optimized state into a fresh module instance
program = MessageClassifier()
program.load(path=str(PROGRAMS / "Classifier" / "program.json"))
```

### 4.3 Load full dataset and filter columns

```python
# Load full dataset as raw dicts (preserving ALL columns)
full_data_raw = load_csv_raw(DATASETS / "messages.csv")
print(f"Full dataset: {len(full_data_raw)} rows, columns: {list(full_data_raw[0].keys())}")
# Full dataset: 5000 rows, columns: ['text', 'source', 'timestamp', 'author', 'channel']

# Create inference-ready examples with ONLY input columns
INPUT_COLUMNS: list[str] = ["text"]
inference_examples = to_inference_examples(full_data_raw, INPUT_COLUMNS)
print(f"Inference examples: {len(inference_examples)}, fields: {list(inference_examples[0].toDict().keys())}")
# Inference examples: 5000, fields: ['text']
```

### 4.4 Run batch inference

```python
# Use module.batch() for parallel inference — no sequential loops
# return_failed_examples=True returns a 3-tuple: (results, failed_examples, exceptions)
# DSPy's type hints don't reflect this — suppress the type checker
results, failed_examples, exceptions = program.batch(  # type: ignore[misc]
    inference_examples,
    num_threads=8,
    return_failed_examples=True,
)

print(f"Completed: {len(results)} predictions, {len(failed_examples)} failures")
if failed_examples:
    for ex, err in zip(failed_examples, exceptions):
        print(f"  - {err}")
```

### 4.5 Combine predictions with original data

```python
# Combine — original columns + predicted label (prefixed with pred_)
OUTPUT_FIELDS: list[str] = ["label"]
combined = combine_results(full_data_raw, results, OUTPUT_FIELDS)

# Verify: all original columns preserved + new prediction column
print(f"Output columns: {list(combined[0].keys())}")
# Output columns: ['text', 'source', 'timestamp', 'author', 'channel', 'pred_label']
```

### 4.6 Save scored dataset

```python
save_csv(combined, DATASETS / "messages_scored.csv")
print(f"Saved {len(combined)} scored examples to {DATASETS / 'messages_scored.csv'}")
```

---

## Complete End-to-End Example

Putting it all together — a single script that runs Stages 1, 3, and 4 (Stage 2 is handled externally).

> **Utility functions** (`load_csv_raw`, `to_inference_examples`, `combine_results`, `save_csv`) are defined in [code-snippets.md Section 2](code-snippets.md#2-data-loading--saving). Copy them into your project alongside this script.

```python
"""
End-to-end text classification pipeline with DSPy + GEPA.

Usage:
    python classify.py

Expects:
    ~/Overlord/files/dspy/datasets/gold_with_feedback.csv  (30-40 labeled + feedback)
    ~/Overlord/files/dspy/datasets/messages.csv             (full dataset ~5000)

Produces:
    ~/Overlord/files/dspy/programs/Classifier/program.json   (optimized program state)
    ~/Overlord/files/dspy/datasets/messages_scored.csv       (full dataset + predictions)
"""

import random
from csv import DictReader, DictWriter
from pathlib import Path

import dspy

# =============================================================================
# Configuration
# =============================================================================

BASE = Path.home() / "Overlord/files/dspy"
DATASETS = BASE / "datasets"
PROGRAMS = BASE / "programs"

INPUT_COLUMNS: list[str] = ["text"]
OUTPUT_FIELDS: list[str] = ["label"]
LABEL_FIELD: str = "label"

LABEL_MAP: dict[str, str] = {
    "yes": "relevant",
    "no": "irrelevant",
    "1": "relevant",
    "0": "irrelevant",
    "true": "relevant",
    "false": "irrelevant",
    "relevant": "relevant",
    "irrelevant": "irrelevant",
}


# =============================================================================
# Signature & Module
# =============================================================================


class Classify(dspy.Signature):
    """Classify a crypto/web3 message as relevant or irrelevant."""

    text: str = dspy.InputField(desc="The message text to classify")
    label: str = dspy.OutputField(desc="Classification: 'relevant' or 'irrelevant'")


class MessageClassifier(dspy.Module):
    def __init__(self):
        self.predict = dspy.Predict(Classify)

    def forward(self, text: str):
        return self.predict(text=text)


# =============================================================================
# Metric
# =============================================================================


def classification_metric(
    gold: dspy.Example,
    pred: dspy.Prediction,
    trace=None,
    pred_name: str | None = None,
    pred_trace=None,
) -> float | dspy.Prediction:
    expected = gold.label.strip().lower()
    predicted = pred.label.strip().lower()
    score = 1.0 if expected == predicted else 0.0

    if pred_name is None:
        return score

    feedback = getattr(gold, "_feedback", "")
    if not feedback:
        if score == 1.0:
            feedback = f"Correct. The message is '{expected}'."
        else:
            feedback = (
                f"Incorrect. Expected '{expected}' but got '{predicted}'. "
                f"Re-examine the message content and classification criteria."
            )

    return dspy.Prediction(score=score, feedback=feedback)


# =============================================================================
# Data Loading (see code-snippets.md Section 2 for inference utilities)
# =============================================================================


def load_gold(
    path: str | Path,
    input_keys: list[str],
    label_field: str,
    label_map: dict[str, str],
) -> list[dspy.Example]:
    examples = []
    with open(path, encoding="utf-8") as f:
        for row in DictReader(f):
            if label_field in row:
                raw_label = row[label_field].strip().lower()
                row[label_field] = label_map.get(raw_label, row[label_field])
            ex = dspy.Example(**row).with_inputs(*input_keys)
            examples.append(ex)
    return examples


# =============================================================================
# Main Pipeline
# =============================================================================


def main() -> None:
    # --- LM setup ---
    lm = dspy.LM(
        "openai/gpt-4.1-mini-2025-04-14", temperature=0.2, max_tokens=10000
    )
    dspy.configure(lm=lm)

    # --- Stage 1: Load gold set (with feedback from Stage 2) ---
    gold = load_gold(
        DATASETS / "gold_with_feedback.csv",
        input_keys=INPUT_COLUMNS,
        label_field=LABEL_FIELD,
        label_map=LABEL_MAP,
    )
    print(f"Gold set: {len(gold)} examples")

    random.seed(42)
    random.shuffle(gold)
    split_idx = int(len(gold) * 0.7)
    train_set = gold[:split_idx]
    val_set = gold[split_idx:]
    print(f"Train: {len(train_set)}, Val: {len(val_set)}")

    # --- Stage 3: GEPA optimization ---
    student = MessageClassifier()

    gepa = dspy.GEPA(
        metric=classification_metric,
        reflection_lm=dspy.LM("openai/gpt-5", temperature=1.0, max_tokens=32000),
        auto="medium",
        reflection_minibatch_size=20,           # Binary metric — default 3 is insufficient
        log_dir=str(BASE / "gepa_logs"),
        num_threads=8,
        track_stats=True,
    )

    optimized = gepa.compile(student, trainset=train_set, valset=val_set)

    # Save optimized program (JSON state — no pickle)
    program_dir = PROGRAMS / "Classifier"
    program_dir.mkdir(parents=True, exist_ok=True)
    optimized.save(str(program_dir / "program.json"))
    print(f"Saved optimized program to {program_dir}")

    # Evaluate
    evaluate = dspy.Evaluate(
        devset=val_set,
        metric=classification_metric,
        num_threads=8,
        display_progress=True,
    )
    result = evaluate(optimized)
    print(f"Validation score: {result.score:.1f}%")

    # --- Stage 4: Batch inference on full dataset ---
    full_data_raw = load_csv_raw(DATASETS / "messages.csv")
    print(f"Full dataset: {len(full_data_raw)} rows")

    inference_examples = to_inference_examples(full_data_raw, INPUT_COLUMNS)

    # Use module.batch() for parallel inference
    # return_failed_examples=True returns 3-tuple: (results, failed_examples, exceptions)
    # DSPy's type hints don't reflect this — suppress the type checker
    results, failed_examples, exceptions = optimized.batch(  # type: ignore[misc]
        inference_examples,
        num_threads=8,
        return_failed_examples=True,
    )
    print(f"Completed: {len(results)} predictions, {len(failed_examples)} failures")

    combined = combine_results(full_data_raw, results, OUTPUT_FIELDS)
    save_csv(combined, DATASETS / "messages_scored.csv")
    print(f"Saved {len(combined)} scored examples")


if __name__ == "__main__":
    main()
```

---

## Key Patterns Reference

### Data recombination (extra columns)

DSPy breaks when examples have columns not in the signature. Always filter before inference:

```python
# WRONG — will break or produce unexpected behavior
all_data = load_csv("messages.csv", input_keys=["text"])
# all_data[0] has: text, source, timestamp, author, channel
pred = program(**all_data[0].inputs())  # May include extra fields

# RIGHT — filter to signature inputs only
inference_ex = dspy.Example(text=row["text"]).with_inputs("text")
pred = program(**inference_ex.inputs())  # Only passes {"text": "..."}
```

### GEPA metric return types

```python
# Program-level evaluation (pred_name is None):
return 1.0  # Just a float

# Predictor-level feedback (pred_name is provided):
return dspy.Prediction(score=1.0, feedback="Correct classification.")

# With pre-generated feedback from Stage 2:
feedback = getattr(gold, "_feedback", "")
return dspy.Prediction(score=score, feedback=feedback)
```

### Loading vs creating programs

```python
# After optimization — load saved state into a fresh module
program = MessageClassifier()
program.load(path="programs/Classifier/program.json")

# From prompt file — create program from markdown instructions
from pathlib import Path
import re

def load_prompt(path: str | Path) -> str:
    text = Path(path).read_text(encoding="utf-8")
    text = re.sub(r"[ \t]+$", "", text, flags=re.MULTILINE)
    text = re.sub(r"\n\s*\n+", "\n\n", text.strip())
    return text

ClassifyWithPrompt = Classify.with_instructions(load_prompt("prompts/classifier.md"))
module = MessageClassifier()
module.predict = dspy.Predict(ClassifyWithPrompt)
module.predict.set_lm(lm)
```

### Train a smaller model (Stage 5 — downstream)

After batch scoring all 5000 examples, use the scored dataset to fine-tune a smaller model:

```python
# The scored dataset (messages_scored.csv) contains:
# text, source, timestamp, author, channel, pred_label
#
# Use this as training data for a smaller model:
# - Filter to high-confidence predictions
# - Format for HuggingFace Trainer / sequence classification
# - Fine-tune a smaller model (e.g., distilbert, deberta)
#
# This is handled by a separate training pipeline (e.g., sequence-classification-llm skill)
```
