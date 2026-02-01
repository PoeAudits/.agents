---
name: project-libs
description: Project-specific library skills for local dependencies and custom utilities. This skill should be used when working with "dspy", "offchain-lib", "sequence-classification-llm", or other project-specific libraries.
---

# Project Libraries Skills

A collection of skills for project-specific libraries and custom utilities. Each skill focuses on a specific library's patterns and usage.

## Activation Triggers

- Working with DSPy for prompt optimization or LLM workflows
- Using offchain-lib for Ethereum data gathering
- Training text classification models with HuggingFace
- Implementing batch inference or optimization
- Configuring language models or signatures
- Managing off-chain data with batching logic

## Quick Routing

**Working with DSPy?** → `dspy`

**Gathering Ethereum data?** → `offchain-lib`

**Training classification models?** → `sequence-classification-llm`

## Skill Map

| Skill | Covers |
|-------|--------|
| [dspy](references/dspy/SKILL.md) | DSPy patterns for LM setup, signatures, modules, batch inference, and GEPA optimization with inline code snippets |
| [offchain-lib](references/offchain-lib/SKILL.md) | Efficient off-chain Ethereum data gathering with automatic batching, typed results, caching, and multi-source pricing |
| [sequence-classification-llm](references/sequence-classification-llm/SKILL.md) | High-level API for training text classification and regression models with HuggingFace transformers |
