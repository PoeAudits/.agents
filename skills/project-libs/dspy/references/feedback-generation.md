# Feedback Generation for GEPA

Generate LLM feedback for gold examples to enrich GEPA optimization. Feedback explains *why* each label is correct (or incorrect), giving GEPA richer signal for prompt reflection.

**Pipeline:** Base predictions on gold inputs → Compare to ground truth → Generate feedback → Attach to gold examples → Save enriched CSV.

---

## 1. FeedbackSignature

The signature takes the task context, the input, expected output, actual model output, and correctness — then produces reasoning and feedback:

```python
import dspy


class FeedbackSignature(dspy.Signature):
    """Analyze how well the outputs match the expected results for the given inputs and task."""

    task_goal: str = dspy.InputField(desc="The goal or objective of the task")
    inputs: str = dspy.InputField(desc="The input data provided to the system")
    expected_output: str = dspy.InputField(desc="The expected/ground truth output")
    actual_output: str = dspy.InputField(desc="The actual output produced by the system")
    is_correct: bool = dspy.InputField(desc="Whether the output was marked as correct")

    reasoning: str = dspy.OutputField(
        desc="Analysis of why the outputs match or don't match the expected results"
    )
    feedback: str = dspy.OutputField(
        desc="Constructive feedback explaining the quality of the output and suggestions for improvement"
    )
```

## 2. FeedbackGenerator Module

Always wrap in a `dspy.Module`:

```python
class FeedbackGenerator(dspy.Module):
    def __init__(self):
        super().__init__()
        self.predict = dspy.Predict(FeedbackSignature)

    def forward(
        self,
        task_goal: str,
        inputs: str,
        expected_output: str,
        actual_output: str,
        is_correct: bool,
    ) -> dspy.Prediction:
        return self.predict(
            task_goal=task_goal,
            inputs=inputs,
            expected_output=expected_output,
            actual_output=actual_output,
            is_correct=is_correct,
        )
```

## 3. Generating Feedback

The full workflow: run the base classifier on gold inputs, compare predictions to ground truth, generate feedback in batch, attach to gold examples.

```python
import dspy


def generate_feedback(
    gold_examples: list[dspy.Example],
    classifier: dspy.Module,
    task_goal: str,
    input_field: str,
    label_field: str,
    num_threads: int = 4,
) -> list[dspy.Example]:
    """Generate feedback for gold examples by comparing classifier predictions to ground truth.

    Args:
        gold_examples: Labeled examples with ground truth.
        classifier: The base classifier module to generate predictions.
        task_goal: Description of the classification task.
        input_field: Name of the input field (e.g., "text", "message").
        label_field: Name of the label field (e.g., "label", "intent").
        num_threads: Threads for batch operations.

    Returns:
        Gold examples enriched with _feedback and _feedback_reasoning fields.
    """
    # Step 1: Get base predictions on gold inputs
    # return_failed_examples=True returns 3-tuple: (results, failed_examples, exceptions)
    # DSPy's type hints don't reflect this — suppress the type checker
    predictions, failed, exceptions = classifier.batch(  # type: ignore[misc]
        gold_examples,
        num_threads=num_threads,
        return_failed_examples=True,
    )

    if failed:
        print(f"Warning: {len(failed)} gold examples failed base prediction")

    # Step 2: Build feedback inputs — one per successful prediction
    feedback_inputs = []
    successful_gold = []
    for gold, pred in zip(gold_examples, predictions):
        expected = getattr(gold, label_field, "")
        actual = getattr(pred, label_field, "")
        is_correct = expected.strip().lower() == actual.strip().lower()

        fb_example = dspy.Example(
            task_goal=task_goal,
            inputs=str(getattr(gold, input_field, "")),
            expected_output=str(expected),
            actual_output=str(actual),
            is_correct=is_correct,
        ).with_inputs("task_goal", "inputs", "expected_output", "actual_output", "is_correct")

        feedback_inputs.append(fb_example)
        successful_gold.append(gold)

    # Step 3: Generate feedback in batch — not sequential loops
    generator = FeedbackGenerator()
    fb_results, fb_failed, fb_exceptions = generator.batch(
        feedback_inputs,
        num_threads=num_threads,
        return_failed_examples=True,
    )

    if fb_failed:
        print(f"Warning: {len(fb_failed)} feedback generations failed")

    # Step 4: Attach feedback to gold examples (dual format)
    enriched = []
    for gold, fb in zip(successful_gold, fb_results):
        gold_dict = gold.toDict()

        # Runtime fields (underscore prefix — accessed via gold._feedback in metrics)
        gold_dict["_feedback"] = getattr(fb, "feedback", "")
        gold_dict["_feedback_reasoning"] = getattr(fb, "reasoning", "")

        # CSV fields (no underscore — for serialization to CSV)
        gold_dict["feedback"] = getattr(fb, "feedback", "")
        gold_dict["feedback_reasoning"] = getattr(fb, "reasoning", "")

        input_keys = list(gold.inputs().keys())
        enriched.append(dspy.Example(**gold_dict).with_inputs(*input_keys))

    return enriched
```

## 4. Usage Example

```python
from pathlib import Path
import dspy
from dspy.adapters import XMLAdapter

# Configure LM
lm = dspy.LM("openai/gpt-4.1-mini-2025-04-14", temperature=0.2, max_tokens=10000, cache=True)
dspy.configure(lm=lm, adapter=XMLAdapter())

# Load gold examples
gold = to_examples("datasets/gold.csv", inputs=["text"])

# Create base classifier
classifier = MessageClassifier()

# Generate feedback
enriched_gold = generate_feedback(
    gold_examples=gold,
    classifier=classifier,
    task_goal="Classify crypto/web3 messages as relevant or irrelevant",
    input_field="text",
    label_field="label",
    num_threads=4,
)

# Save enriched gold
save_examples(enriched_gold, "datasets/gold_with_feedback.csv")
print(f"Saved {len(enriched_gold)} enriched examples")
```

## 5. Data Format

After feedback generation, each gold example has these additional fields:

| Field | Purpose | Access Pattern |
|-------|---------|----------------|
| `_feedback` | Runtime access in GEPA metric | `gold._feedback` or `getattr(gold, "_feedback", "")` |
| `_feedback_reasoning` | Runtime access to reasoning | `gold._feedback_reasoning` |
| `feedback` | CSV serialization | Column in `gold_with_feedback.csv` |
| `feedback_reasoning` | CSV serialization | Column in `gold_with_feedback.csv` |

The dual format exists because:
- **Underscore-prefixed fields** (`_feedback`) are the canonical runtime access pattern in DSPy examples
- **Plain fields** (`feedback`) ensure the data survives CSV round-trips (CSV column names can't start with `_` reliably)

When loading feedback-enriched gold from CSV, both formats are available since `dspy.Example(**row)` accepts all column names.

## 6. Loading Enriched Gold

```python
from csv import DictReader
from pathlib import Path

import dspy


def load_gold_with_feedback(
    path: str | Path,
    input_keys: list[str],
    label_field: str = "label",
    label_map: dict[str, str] | None = None,
) -> list[dspy.Example]:
    """Load gold CSV that includes feedback columns."""
    examples = []
    with open(path, encoding="utf-8") as f:
        for row in DictReader(f):
            if label_map and label_field in row:
                raw_label = row[label_field].strip().lower()
                row[label_field] = label_map.get(raw_label, row[label_field])
            ex = dspy.Example(**row).with_inputs(*input_keys)
            examples.append(ex)
    return examples
```

Access feedback in the GEPA metric:

```python
def metric(gold, pred, trace=None, pred_name=None, pred_trace=None):
    score = 1.0 if gold.label.lower() == pred.label.lower() else 0.0

    if pred_name is None:
        return score

    # Use pre-generated feedback if available
    feedback = getattr(gold, "_feedback", "") or getattr(gold, "feedback", "")
    if not feedback:
        feedback = f"Expected '{gold.label}', got '{pred.label}'."

    return dspy.Prediction(score=score, feedback=feedback)
```
