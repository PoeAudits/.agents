---
name: sequence-classification-llm
description: Use when fine-tuning or training text classification/regression models with HuggingFace transformers. Triggers on tasks involving sentiment analysis, text categorization, scoring predictions, or any sequence-to-label modeling.
---

# sequence-classification-llm

## Overview

High-level API for sequence classification and regression built on HuggingFace transformers. Handles tokenization, dataset splitting, training, and prediction with minimal boilerplate.

## When to Use

- Training classification models (sentiment, categorization, multi-class)
- Training regression models (scoring, rating prediction)
- Fine-tuning transformer models on labeled text data
- Need interactive dataset splitting with distribution verification

**Don't use for:** Token classification (NER), question answering, text generation

## Quick Reference

| Task | Code |
|------|------|
| Import | `from sequence_classification_llm.flashnode import SequenceClassificationLLM` |
| Classification | `SequenceClassificationLLM(task="classification")` |
| Regression | `SequenceClassificationLLM(task="regression")` |
| Train | `model.train(dataset, save_path=Path("./model"))` |
| Load | `model.load("./model")` |
| Predict | `model.predict(dataset)` |
| Plot | `from sequence_classification_llm.plot import plot_training_history` |

## Core Pattern

```python
from pathlib import Path
from datasets import Dataset
from sequence_classification_llm.flashnode import SequenceClassificationLLM
from sequence_classification_llm.plot import plot_training_history

# Prepare data - requires 'text' and 'labels' columns by default
data = Dataset.from_dict({
    "text": ["Great product!", "Terrible service", ...],
    "labels": ["positive", "negative", ...]  # strings for classification, floats for regression
})

# Initialize - defaults to ModernBERT-base
model = SequenceClassificationLLM(
    task="classification",  # or "regression"
    text_column="text",     # customize if needed
    label_column="labels",
    max_length=512,
)

# Train - interactive split approval, saves to output path
metrics = model.train(
    data,
    save_path=Path("./trained_model"),
    test_size=0.15,
    early_stop=True,  # optional early stopping
)

# Visualize training
plot_training_history(model.get_training_logs(), show=True)

# Predict on new data
new_data = Dataset.from_dict({"text": ["New text to classify"]})
results = model.predict(new_data)  # adds 'prediction' column
```

## Key Parameters

**SequenceClassificationLLM.__init__:**
- `model`: Model name/path (default: `MODEL_NAME` from env or "answerdotai/ModernBERT-base")
- `task`: `"classification"` (F1 metric) or `"regression"` (MSE metric)
- `text_column`, `label_column`: Column names in dataset
- `max_length`: Max sequence length (default: 512)
- `use_tf32`: Enable TensorFloat32 on Ampere+ GPUs (default: True)

**train():**
- `dataset`: HuggingFace Dataset or DatasetDict (with train/test splits)
- `save_path`: Where to save model
- `test_size`: Eval split fraction (default: 0.15)
- `seed`: Random seed
- `early_stop`: Enable early stopping with patience=4
- `**kwargs`: Passed to TrainingArguments (e.g., `num_train_epochs`, `learning_rate`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong column names | Match `text_column` and `label_column` to your dataset |
| Classification with float labels | Use string/int labels for classification, floats for regression |
| Missing dependencies | Install with `pip install sequence-classification-llm[all]` |
| Skipping split approval | Interactive prompt shows label distribution - verify before training |

## Module Structure

```
sequence_classification_llm.flashnode  # SequenceClassificationLLM, test_train_split
sequence_classification_llm.model      # Model Protocol, default_training_args
sequence_classification_llm.plot       # plot_training_history, plot_training_combined_metrics
sequence_classification_llm.config     # MODEL_NAME, HF_TOKEN, API keys from .env
```

