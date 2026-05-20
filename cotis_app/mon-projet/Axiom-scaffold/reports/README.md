# Axiom Reports Directory

> **Purpose**: All agent-generated reports, walkthroughs, tasks, plans, and reviews  
> **Format**: Caveman compression (65-75% token savings)  
> **Structure**: Organized by feature

## Directory Structure

```
reports/
├── README.md                              # This file
├── CHANGELOG.md                           # Project changelog
├── CAVEMAN_IMPLEMENTATION_COMPLETE.md     # Caveman implementation report
├── CAVEMAN_SUMMARY.md                     # Caveman summary (caveman format)
├── {feature}/                             # Feature-specific reports
│   ├── walkthrough.md                     # Step-by-step guide (caveman full)
│   ├── tasks.md                           # Task list (caveman ultra)
│   ├── plan.md                            # Implementation plan (caveman full)
│   └── reviews.md                         # Code reviews (caveman full)
└── ...
```

## Report Types

### Walkthrough (Caveman Full)
- **Format**: `Step N: [action]. [result].`
- **Max**: 8 steps
- **Purpose**: Document implementation process
- **Example**: `reports/authentication/walkthrough.md`

### Tasks (Caveman Ultra)
- **Format**: `TASK {id}: {goal} | File: {file} | Deps: {dep} | Status: {status}`
- **Max**: 1 line per task
- **Purpose**: Track micro-tasks
- **Example**: `reports/authentication/tasks.md`

### Plan (Caveman Full)
- **Sections**: Goal, Files, Deps, Tests
- **Max**: 25 lines total
- **Purpose**: Implementation planning
- **Example**: `reports/authentication/plan.md`

### Reviews (Caveman Full)
- **Format**: `{file}:{line} - {severity_emoji} {finding}`
- **Emojis**: 🔴 critical, 🟡 warning, 🔵 info
- **Purpose**: Code review findings
- **Example**: `reports/authentication/reviews.md`

## Caveman Mode

All reports use **Caveman compression** by default:
- **No filler**: "Sure!", "I'd be happy to help" removed
- **No hedging**: "just", "really", "basically" removed
- **Direct format**: [constat] [cause] [action]
- **Token savings**: 65-75%

### Invariants (Never Compressed)
- Code blocks (full syntax)
- Error messages (exact quotes)
- Technical terms (function names, APIs, paths)
- Stack traces
- URLs and paths
- Version numbers

## Creating Reports

### Manual Creation
```bash
# Create feature directory
mkdir -p Axiom-scaffold/reports/{feature-name}

# Create report files
touch Axiom-scaffold/reports/{feature-name}/walkthrough.md
touch Axiom-scaffold/reports/{feature-name}/tasks.md
touch Axiom-scaffold/reports/{feature-name}/plan.md
touch Axiom-scaffold/reports/{feature-name}/reviews.md
```

### Agent Creation
Agent automatically creates reports in caveman format when:
- Implementing a feature
- Documenting a process
- Reviewing code
- Planning tasks

## Examples

### Authentication Feature
```
reports/authentication/
├── walkthrough.md  # 8 steps, caveman full
├── tasks.md        # 8 tasks, caveman ultra
├── plan.md         # Goal, Files, Deps, Tests
└── reviews.md      # Code review findings
```

### Payment Feature
```
reports/payment/
├── walkthrough.md
├── tasks.md
├── plan.md
└── reviews.md
```

## Configuration

Reports follow rules defined in:
- **Config**: `Axiom-scaffold/config/caveman-rules.yaml`
- **Skill**: `Axiom-scaffold/skills/built-in/caveman-mode.md`
- **Docs**: `Axiom-scaffold/docs/CAVEMAN.md`

## Validation

```bash
# Validate caveman config
npm run caveman:validate

# Check report format
# (manual review against caveman-rules.yaml)
```

## Best Practices

1. **One feature per directory**: Keep reports organized by feature
2. **Use caveman format**: Follow compression rules for consistency
3. **Preserve invariants**: Never compress code, errors, or technical terms
4. **Update regularly**: Keep reports in sync with implementation
5. **Link to code**: Reference specific files and line numbers

## Token Savings

| Report Type | Normal       | Caveman     | Savings |
| ----------- | ------------ | ----------- | ------- |
| Walkthrough | ~800 tokens  | ~300 tokens | 62%     |
| Tasks       | ~400 tokens  | ~140 tokens | 65%     |
| Plan        | ~600 tokens  | ~220 tokens | 63%     |
| Reviews     | ~500 tokens  | ~180 tokens | 64%     |
| **Total**   | ~2300 tokens | ~840 tokens | **63%** |

## References

- **Caveman Source**: https://github.com/JuliusBrussee/caveman
- **Config**: `../config/caveman-rules.yaml`
- **Docs**: `../docs/CAVEMAN.md`
- **Skill**: `../skills/built-in/caveman-mode.md`

---

**Format**: Caveman compression  
**Savings**: 65-75% tokens  
**Structure**: By feature  
**Status**: Active
