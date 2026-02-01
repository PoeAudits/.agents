#!/bin/bash
# Opencode Agent File Validator
# Validates Opencode agent markdown files for correct structure and content

set -euo pipefail

# Usage
if [ $# -eq 0 ]; then
  echo "Usage: $0 <path/to/agent.md>"
  echo ""
  echo "Validates Opencode agent file for:"
  echo "  - YAML frontmatter structure"
  echo "  - Required fields (description)"
  echo "  - Field formats and constraints"
  echo "  - System prompt presence and length"
  echo "  - Optional fields (tools, mode, permission)"
  exit 1
fi

AGENT_FILE="$1"

echo "🔍 Validating agent file: $AGENT_FILE"
echo ""

# Check 1: File exists
if [ ! -f "$AGENT_FILE" ]; then
  echo "❌ File not found: $AGENT_FILE"
  exit 1
fi
echo "✅ File exists"

# Extract filename (agent name)
AGENT_NAME=$(basename "$AGENT_FILE" .md)
echo "📛 Agent name (from filename): $AGENT_NAME"

# Check filename format
if ! [[ "$AGENT_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "❌ Agent name must match pattern ^[a-z0-9]+(-[a-z0-9]+)*$ (lowercase, no consecutive hyphens)"
  exit 1
fi

name_length=${#AGENT_NAME}
if [ $name_length -lt 1 ]; then
  echo "❌ Agent name too short (minimum 1 character)"
  exit 1
elif [ $name_length -gt 64 ]; then
  echo "❌ Agent name too long (maximum 64 characters)"
  exit 1
fi

# Check for generic names
if [[ "$AGENT_NAME" =~ ^(helper|assistant|agent|tool)$ ]]; then
  echo "⚠️  Agent name is too generic: $AGENT_NAME"
fi

echo "✅ Agent name format valid"

# Check 2: Starts with ---
FIRST_LINE=$(head -1 "$AGENT_FILE")
if [ "$FIRST_LINE" != "---" ]; then
  echo "❌ File must start with YAML frontmatter (---)"
  exit 1
fi
echo "✅ Starts with frontmatter"

# Check 3: Has closing ---
if ! tail -n +2 "$AGENT_FILE" | grep -q '^---$'; then
  echo "❌ Frontmatter not closed (missing second ---)"
  exit 1
fi
echo "✅ Frontmatter properly closed"

# Extract frontmatter and system prompt
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$AGENT_FILE")
SYSTEM_PROMPT=$(awk '/^---$/{i++; next} i>=2' "$AGENT_FILE")

# Check 4: Required fields
echo ""
echo "Checking required fields..."

error_count=0
warning_count=0

# Check description field (required)
DESCRIPTION=$(echo "$FRONTMATTER" | grep '^description:' | sed 's/description: *//')

if [ -z "$DESCRIPTION" ]; then
  echo "❌ Missing required field: description"
  ((error_count++))
else
  desc_length=${#DESCRIPTION}
  echo "✅ description: ${desc_length} characters"

  if [ $desc_length -lt 10 ]; then
    echo "⚠️  description too short (minimum 10 characters recommended)"
    ((warning_count++))
  elif [ $desc_length -gt 5000 ]; then
    echo "⚠️  description very long (over 5000 characters)"
    ((warning_count++))
  fi

  # Check for XML tags in description (not allowed)
  if echo "$DESCRIPTION" | grep -qE '<[a-zA-Z]+>'; then
    echo "⚠️  description contains XML tags - should be plain text only"
    ((warning_count++))
  fi
fi

# Check model field (optional)
MODEL=$(echo "$FRONTMATTER" | grep '^model:' | sed 's/model: *//')

if [ -n "$MODEL" ]; then
  echo "✅ model: $MODEL"

  # Validate model format
  if [[ "$MODEL" == "inherit" ]]; then
    echo "⚠️  model: inherit is not recommended (set an explicit model for subagents)"
    ((warning_count++))
  elif [[ "$MODEL" =~ ^[a-z]+/[a-z0-9-]+-[0-9]{4,8}$ ]]; then
    # Valid model format like provider/model-id-version
    :
  else
    echo "⚠️  Unusual model format: $MODEL (expected format: provider/model-id-version)"
    ((warning_count++))
  fi
else
  echo "💡 model: not specified"
fi

# Check mode field (optional but recommended)
MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//')

if [ -n "$MODE" ]; then
  echo "✅ mode: $MODE"
  
  case "$MODE" in
    primary|subagent)
      # Valid mode
      ;;
    *)
      echo "⚠️  Unknown mode: $MODE (valid: primary, subagent)"
      ((warning_count++))
      ;;
  esac
else
  echo "💡 mode: not specified"
fi

# Additional guidance: model + mode relationship
if [ -n "$MODE" ]; then
  if [ "$MODE" = "subagent" ] && [ -z "$MODEL" ]; then
    echo "⚠️  mode is subagent but model is not set (recommended: set model explicitly)"
    ((warning_count++))
  fi
  if [ "$MODE" = "primary" ] && [ -n "$MODEL" ]; then
    echo "⚠️  mode is primary but model is set (recommended: omit model for primary)"
    ((warning_count++))
  fi
fi

## tools field
# NOTE: The legacy `tools:` frontmatter key is deprecated in favor of `permission:`.
# We warn if present for backwards compatibility.
if echo "$FRONTMATTER" | grep -q '^tools:'; then
  echo "⚠️  tools: defined (deprecated - use permission:)"
  ((warning_count++))
fi

# Check permission field (optional)
if echo "$FRONTMATTER" | grep -q '^permission:'; then
  echo "✅ permission: defined"
  
  # Extract permission settings
  PERM_SECTION=$(echo "$FRONTMATTER" | sed -n '/^permission:/,/^[^[:space:]]/p' | tail -n +2)
  if [ -n "$PERM_SECTION" ]; then
    echo "   Permission settings:"
    echo "$PERM_SECTION" | grep -E '^[[:space:]]+' | sed 's/^[[:space:]]*/     /'
  fi
else
  echo "💡 permission: not specified (all tools default to 'allow')"
fi

# Check other optional fields
OPTIONAL_FIELDS=("temperature" "steps" "top_p" "hidden" "color" "disable")
for field in "${OPTIONAL_FIELDS[@]}"; do
  VALUE=$(echo "$FRONTMATTER" | grep "^${field}:" | sed "s/${field}: *//")
  if [ -n "$VALUE" ]; then
    echo "✅ ${field}: ${VALUE}"
  fi
done

# Check for deprecated maxSteps field
if echo "$FRONTMATTER" | grep -q '^maxSteps:'; then
  echo "⚠️  'maxSteps' is deprecated, use 'steps' instead"
  ((warning_count++))
fi

# Check 5: System prompt
echo ""
echo "Checking system prompt..."

if [ -z "$SYSTEM_PROMPT" ]; then
  echo "❌ System prompt is empty"
  ((error_count++))
else
  prompt_length=${#SYSTEM_PROMPT}
  echo "✅ System prompt: $prompt_length characters"

  if [ $prompt_length -lt 20 ]; then
    echo "❌ System prompt too short (minimum 20 characters)"
    ((error_count++))
  elif [ $prompt_length -gt 10000 ]; then
    echo "⚠️  System prompt very long (over 10,000 characters)"
    ((warning_count++))
  fi

  # Check for second person
  if ! echo "$SYSTEM_PROMPT" | grep -q "You are\|You will\|Your"; then
    echo "⚠️  System prompt should use second person (You are..., You will...)"
    ((warning_count++))
  fi

  # Check for structure
  if ! echo "$SYSTEM_PROMPT" | grep -qi "responsibilities\|process\|steps"; then
    echo "💡 Consider adding clear responsibilities or process steps"
  fi

  if ! echo "$SYSTEM_PROMPT" | grep -qi "output"; then
    echo "💡 Consider defining output format expectations"
  fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
elif [ $error_count -eq 0 ]; then
  echo "⚠️  Validation passed with $warning_count warning(s)"
  exit 0
else
  echo "❌ Validation failed with $error_count error(s) and $warning_count warning(s)"
  exit 1
fi
