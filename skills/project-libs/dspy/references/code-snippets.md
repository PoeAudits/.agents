# DSPy Code Snippets

Canonical DSPy patterns to copy directly into projects. All snippets are self-contained — never import from `dspy_utils`. Organized by the same 7 sections as the main skill guide.

---

## 1. LM Setup & Configuration

### Environment Loading

Load `.env` preferring local project file over a fallback path:

```python
import os
from pathlib import Path
from dotenv import load_dotenv

_LOADED_ENV = False

def load_env_prefer_local() -> None:
    global _LOADED_ENV
    if _LOADED_ENV:
        return
    _LOADED_ENV = True
    local = Path.cwd() / ".env"
    if local.exists():
        load_dotenv(local, override=False)
        return
    fallback = Path(__file__).resolve().parents[3] / ".env"
    if fallback.exists():
        load_dotenv(fallback, override=False)

load_env_prefer_local()

OPEN_AI_API_KEY = os.getenv("OPEN_AI_API_KEY")
```

### Model Presets

Instantiate LMs directly with `dspy.LM()` — no wrapper needed:

```python
import dspy

# GPT-5 series (reasoning, 50k tokens)
gpt_5 = dspy.LM("openai/gpt-5", api_key=OPEN_AI_API_KEY, temperature=0.2, max_tokens=50000, cache=True)
gpt_5_mini = dspy.LM("openai/gpt-5-mini", api_key=OPEN_AI_API_KEY, temperature=0.2, max_tokens=50000, cache=True)

# GPT-4 series (non-reasoning, 10k tokens)
gpt_4 = dspy.LM("openai/gpt-4.1-2025-04-14", api_key=OPEN_AI_API_KEY, temperature=0.2, max_tokens=10000, cache=True)
gpt_4_mini = dspy.LM("openai/gpt-4.1-mini-2025-04-14", api_key=OPEN_AI_API_KEY, temperature=0.2, max_tokens=10000, cache=True)
gpt_4_nano = dspy.LM("openai/gpt-4.1-nano-2025-04-14", api_key=OPEN_AI_API_KEY, temperature=0.2, max_tokens=10000, cache=True)

# Ollama (local)
ollama_llama = dspy.LM("ollama_chat/llama3.2", api_base="http://localhost:11434", api_key="", cache=True)
ollama_gpt = dspy.LM("ollama_chat/gpt-oss:20b", api_base="http://localhost:11434", api_key="", cache=True)
```

### Configuring LM and Adapter

Call `dspy.configure()` once at pipeline start to set both the LM and adapter:

```python
import dspy
from dspy.adapters import XMLAdapter

def configure_lm(lm: dspy.LM) -> None:
    """Configure DSPy with the given LM and XMLAdapter. Call once at pipeline start."""
    dspy.configure(lm=lm, adapter=XMLAdapter())

# Usage
configure_lm(gpt_4_mini)
```

### Adapter Override with dspy.context

```python
from dspy.adapters import ChatAdapter

# Local override for a specific block — does not change global config
with dspy.context(adapter=ChatAdapter()):
    result = my_program(text="...")
```

---

## 2. Data Loading & Saving

### Training Utilities

Use these for optimization workflows: `load_data()` → `dspy.Example` → optimize/evaluate.

#### load_data — File or HuggingFace

```python
import os
from pathlib import Path
import dspy
from dspy.datasets import DataLoader

def load_data(
    data,
    fields: list[str] | tuple[str] | None = None,
    input_keys: tuple[str] = (),
    **kwargs,
) -> list[dspy.Example]:
    loader = DataLoader()
    if isinstance(data, (str, Path)):
        data_str = str(data)
        if os.path.exists(data_str):
            ext = Path(data_str).suffix.lower()
            if ext == ".csv":
                return loader.from_csv(data_str, fields=fields, input_keys=input_keys)
            elif ext == ".json":
                return loader.from_json(data_str, fields=fields, input_keys=input_keys)
            elif ext == ".parquet":
                return loader.from_parquet(data_str, fields=fields, input_keys=input_keys)
            else:
                raise ValueError(f"Unsupported file type: {ext}")
        fields_tuple = tuple(fields) if fields else None
        return loader.from_huggingface(data_str, fields=fields_tuple, input_keys=input_keys, **kwargs)
    if isinstance(data, list) and all(isinstance(item, dspy.Example) for item in data):
        return data
    raise TypeError(f"Unsupported data type: {type(data)}")
```

Usage:

```python
examples = load_data("train.csv", input_keys=("question",))
examples = load_data("train.json", input_keys=("question",))
examples = load_data("hotpot_qa", fields=("question", "answer"), input_keys=("question",), split="train")
```

#### to_examples — Dicts or CSV to dspy.Example

```python
import os
import random
from csv import DictReader
import dspy

def to_examples(
    data: list[dict] | str,
    inputs: list[str] | None = None,
    shuffle: bool = False,
    seed: int | None = None,
) -> list[dspy.Example]:
    examples = []
    if isinstance(data, str):
        if not os.path.exists(data):
            raise FileNotFoundError(f"CSV file not found: {data}")
        with open(data, mode="r", newline="", encoding="utf-8") as f:
            for row in DictReader(f):
                ex = dspy.Example(**row)
                if inputs:
                    ex = ex.with_inputs(*inputs)
                examples.append(ex)
    elif isinstance(data, list) and all(isinstance(row, dict) for row in data):
        for row in data:
            ex = dspy.Example(**row)
            if inputs:
                ex = ex.with_inputs(*inputs)
            examples.append(ex)
    else:
        raise TypeError("Data must be a list of dicts or a CSV filepath string.")
    if shuffle:
        if seed is not None:
            random.seed(seed)
        random.shuffle(examples)
    return examples
```

#### save_examples — Examples to CSV

```python
from csv import DictWriter
import dspy

def save_examples(examples: list[dspy.Example], save_path: str) -> None:
    data = [ex.toDict() for ex in examples]
    with open(save_path, mode="w", newline="", encoding="utf-8") as f:
        writer = DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
```

#### merge_examples — Zip-merge Multiple Example Lists

```python
import dspy

def merge_examples(*example_lists: list[dspy.Example]) -> list[dspy.Example]:
    inputs = list(example_lists[0][0].inputs().keys())
    all_dicts = [[item.toDict() for item in ex_list] for ex_list in example_lists]
    merged = []
    for items in zip(*all_dicts):
        combined = {}
        for d in items:
            combined.update(d)
        merged.append(combined)
    return to_examples(data=merged, inputs=inputs)
```

### Inference Utilities

Use these for batch scoring workflows: `load_csv_raw()` → `to_inference_examples()` → `module.batch()` → `combine_results()` → `save_csv()`.

#### load_csv_raw — Load CSV as Raw Dicts

```python
from csv import DictReader
from pathlib import Path

def load_csv_raw(path: str | Path) -> list[dict[str, str]]:
    """Load CSV preserving all columns as raw dicts."""
    with open(path, encoding="utf-8") as f:
        return list(DictReader(f))
```

#### to_inference_examples — Filter to Signature Input Columns

```python
import dspy

def to_inference_examples(
    data: list[dict],
    input_columns: list[str],
) -> list[dspy.Example]:
    """Create dspy.Example objects with only the input columns needed for inference."""
    examples = []
    for row in data:
        filtered = {col: row[col] for col in input_columns if col in row}
        ex = dspy.Example(**filtered).with_inputs(*input_columns)
        examples.append(ex)
    return examples
```

#### combine_results — Merge Raw Dicts + Predictions

```python
import dspy

def combine_results(
    original_data: list[dict],
    predictions: list[dspy.Example],
    output_fields: list[str],
) -> list[dict]:
    """Combine original data with predictions, prefixing output fields with 'pred_'.

    Note: module.batch() returns list[dspy.Example], not list[dspy.Prediction].
    """
    if len(original_data) != len(predictions):
        raise ValueError(
            f"Length mismatch: {len(original_data)} originals vs {len(predictions)} predictions"
        )
    combined = []
    for original, pred in zip(original_data, predictions):
        row = dict(original)
        for field in output_fields:
            row[f"pred_{field}"] = getattr(pred, field, "")
        combined.append(row)
    return combined
```

#### save_csv — Save List of Dicts to CSV

```python
from csv import DictWriter
from pathlib import Path

def save_csv(data: list[dict], path: str | Path) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
```

---

## 3. Signatures & Modules

### Defining Signatures

```python
import dspy
from typing import Literal

class Classify(dspy.Signature):
    """Classify the message sentiment."""
    message: str = dspy.InputField()
    sentiment: Literal["positive", "negative", "neutral"] = dspy.OutputField(
        desc="The classified sentiment"
    )
```

> **Tip:** Use `Literal` types on output fields to constrain model outputs to valid values.
> This helps DSPy enforce structured outputs and reduces post-processing.
> Use `str` only when the output is truly free-form.

### Custom Module (always use this)

Never use bare `dspy.Predict()` — always wrap in a module. This enables `module.batch()`, composition, and is the pattern GEPA expects.

```python
class SentimentClassifier(dspy.Module):
    def __init__(self):
        self.predict = dspy.Predict(Classify)

    def forward(self, message: str):
        return self.predict(message=message)
```

### with_instructions_from_file

Load prompt text from a markdown file and apply to a signature:

```python
import re
from pathlib import Path
import dspy

def with_instructions_from_file(
    signature: type[dspy.Signature],
    prompt_file: str,
) -> type[dspy.Signature]:
    prompt_path = Path(prompt_file)
    if not prompt_path.exists():
        raise FileNotFoundError(f"Prompt file not found: {prompt_file}")
    with prompt_path.open("r", encoding="utf-8") as f:
        content = f.read()
        clean_text = re.sub(r"[ \t]+$", "", content, flags=re.MULTILINE)
        clean_text = re.sub(r"\n\s*\n+", "\n\n", clean_text.strip())
        return signature.with_instructions(clean_text)
```

### Saving Programs

Save optimized module state as JSON (preferred — human-readable, portable, no pickle):

```python
from pathlib import Path

def save_program(module: dspy.Module, save_dir: str | Path) -> None:
    """Save module state as JSON."""
    save_dir = Path(save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)
    module.save(str(save_dir / "program.json"))
```

> **Preferred format: JSON.** `module.save("path/program.json")` saves the module state
> (demos, instructions, signature) as human-readable JSON. Do NOT use `save_program=True`
> — that creates pickle files via cloudpickle. Do NOT save to `.pkl` extension.

### get_prompt — Extract Formatted Prompt

```python
import dspy
from dspy.adapters import XMLAdapter

def get_prompt(optimized_program, adapter: dspy.Adapter | None = None) -> str:
    if adapter is None:
        adapter = XMLAdapter()
    prompt = {
        name: adapter.format(
            p.signature,
            demos=p.demos,
            inputs={k: f"{{{k}}}" for k in p.signature.input_fields},
        )
        for name, p in optimized_program.named_predictors()
    }["self"]
    return prompt
```

### get_signature_inputs

```python
import dspy

def get_signature_inputs(signature: type[dspy.Signature]) -> set[str]:
    inputs = set()
    for k, v in signature.model_fields.items():
        extra = v.json_schema_extra
        if isinstance(extra, dict) and extra.get("__dspy_field_type") == "input":
            inputs.add(k)
    return inputs
```

### Advanced: Prompt-as-Files Module

```python
from pathlib import Path
import dspy

class MyPipeline(dspy.Module):
    def __init__(self, refresh_programs: bool = False):
        program_path = Path("programs/program.json")
        if refresh_programs or not program_path.exists():
            # Build from prompt file and save
            sig = with_instructions_from_file(Classify, "prompts/classify.md")
            module = SentimentClassifier()
            module.predict = dspy.Predict(sig)
            save_program(module, "programs")
        self.classify = SentimentClassifier()
        self.classify.load(path=str(program_path))

    def forward(self, message: str):
        return self.classify(message=message)
```

### Loading Saved Programs

Load a JSON state file into a fresh module instance:

```python
# Create a fresh module instance, then load state from JSON
program = SentimentClassifier()
program.load(path="programs/program.json")
```

> **Always instantiate the module class first**, then call `.load()` to restore state.
> Do NOT use `dspy.load()` — that loads cloudpickle programs.

---

## 4. Batch Inference

### module.batch() — Load, Filter, Batch, Combine, Save

**Return type depends on `return_failed_examples`:**
- `return_failed_examples=False` (default): returns `list[dspy.Example]`
- `return_failed_examples=True`: returns `tuple[list[dspy.Example], list[dspy.Example], list[Exception]]`

The 3-tuple contains `(results, failed_examples, exceptions)`.

> **⚠️ DSPy type hint mismatch:** `batch()` is typed as returning `Example | list[Example]`,
> but with `return_failed_examples=True` it actually returns a 3-tuple at runtime.
> Always add `# type: ignore[misc]` on the unpacking line. Do NOT work around this
> by indexing into the result — use direct tuple unpacking.

```python
# 1. Load raw data (preserving all columns)
raw_data = load_csv_raw("datasets/input.csv")

# 2. Filter to signature input columns
inference_examples = to_inference_examples(raw_data, input_columns=["message"])

# 3. Batch inference with custom module
module = SentimentClassifier()
configure_lm(my_lm)

# return_failed_examples=True returns a 3-tuple: (results, failed_examples, exceptions)
# DSPy's type hints don't reflect this — suppress the type checker
results, failed_examples, exceptions = module.batch(  # type: ignore[misc]
    inference_examples,
    num_threads=8,
    return_failed_examples=True,
)

if failed_examples:
    print(f"Warning: {len(failed_examples)} failures")
    for ex, err in zip(failed_examples, exceptions):
        print(f"  - {err}")

# 4. Combine predictions with original data
combined = combine_results(raw_data, results, output_fields=["sentiment"])

# 5. Save
save_csv(combined, "datasets/output.csv")
```

---

## 5. GEPA Optimization

### Metric Function

GEPA metrics accept 5 parameters. Return behavior depends on `pred_name`:

```python
import dspy

def metric(
    gold: dspy.Example,
    pred: dspy.Prediction,
    trace=None,
    pred_name: str | None = None,
    pred_trace=None,
) -> float | dspy.Prediction:
    correct = gold.answer.lower() == pred.answer.lower()
    score = 1.0 if correct else 0.0

    # When pred_name is provided: return dspy.Prediction with score + feedback
    if pred_name is not None:
        feedback = "Correct!" if correct else f"Expected '{gold.answer}', got '{pred.answer}'"
        return dspy.Prediction(score=score, feedback=feedback)

    # When pred_name is None: return just the float score
    return score
```

### GEPA Configuration & Compile

```python
import dspy
from pathlib import Path

student = SentimentClassifier()

gepa = dspy.GEPA(
    metric=metric,
    reflection_lm=dspy.LM("openai/gpt-5", temperature=1.0, max_tokens=32000),
    auto="medium",                    # "light" (6), "medium" (12), "heavy" (18) candidates
    reflection_minibatch_size=20,     # Binary metric (0/1) needs large batches — default 3 is insufficient
    log_dir="./gepa_logs",            # Enables checkpointing/resumption
    num_threads=8,
    track_stats=True,
)

optimized = gepa.compile(student, trainset=train, valset=val)

# Save optimized program (JSON state)
Path("programs/Optimized").mkdir(parents=True, exist_ok=True)
optimized.save("programs/Optimized/program.json")
```

### Minibatch Size Selection

GEPA's `reflection_minibatch_size` controls how many examples are evaluated per reflection batch. The default (3) is almost never sufficient.

| Metric Type | Recommended reflection_minibatch_size | Why |
|-------------|---------------------------|-----|
| Binary (0 or 1) | 20+ | With 3 samples, all-pass is treated as trivial (discarded), and 2/3 caps you at 66% — the metric space is too coarse |
| Discrete (0, 0.5, 1) | 10-15 | More granularity but still needs enough samples for meaningful signal |
| Continuous (0.0-1.0) | 5-6 | Fine-grained scores give sufficient signal with fewer samples |

**Rule of thumb:** The coarser your metric, the more minibatch examples you need.

---

## 6. Storage Conventions

No code snippets — see the directory layout in the main skill guide.

---

## 7. Key Defaults & Tips

No code snippets — see the tables in the main skill guide.
