# Caveman Mode — Quick Reference

> **Source**: https://github.com/JuliusBrussee/caveman  
> **Licence**: MIT  
> **Token Savings**: 65-75%

## What Is Caveman?

Compression mode for agent output. Removes filler, keeps precision. Code intact, errors exact, technical terms preserved.

## Activation

```
/caveman full
```

or simply:

```
caveman
```

## Levels

| Level      | Style                            | Example                                                                        |
| ---------- | -------------------------------- | ------------------------------------------------------------------------------ |
| **lite**   | Professional, keep articles      | "The bug is in the auth middleware. The token check uses `<` instead of `<=`." |
| **full**   | Fragments, no articles (default) | "Bug in auth middleware. Token check use `<` not `<=`."                        |
| **ultra**  | Telegraphic, abbreviations       | "Auth bug → token check `<` → `<=`"                                            |
| **wenyan** | Classical Chinese                | "認證中間件誤。令牌檢查用 `<` 非 `<=`。"                                       |

## Commands

```bash
/caveman lite    # Professional mode
/caveman full    # Default mode (fragments)
/caveman ultra   # Telegraphic mode
stop caveman     # Deactivate
normal mode      # Deactivate
```

## Output Rules

### Chat Response (full)
- Max 6 lines
- Format: `[constat] [cause] [action]. [next step].`
- Forbidden: "Sure!", "I'd be happy to help", "Let me explain"

**Example:**
```
Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:

// middleware/auth.js:42
- if (token.exp < now) throw new Error('expired');
+ if (token.exp <= now) throw new Error('expired');

Test: npm test auth
```

### Documentation (lite)
- Keep sections: overview, usage, install, config, api, security
- Max 15 lines per section
- Drop sections: acknowledgments, philosophy, background_story

### Walkthrough (full)
- Format: `Step N: [action]. [result].`
- Max 8 steps

**Example:**
```
Step 1: Create user schema. Zod validation for email + password.
Step 2: Hash password. Use bcrypt, salt rounds = 10.
Step 3: Store in DB. Prepared statement, no SQL injection.
```

### Task File (ultra)
- Format: `TASK {id}: {goal} | File: {file} | Deps: {dep} | Status: {status}`
- Fields: id, goal, file, dep, status only

**Example:**
```
TASK 001: Create user schema | File: src/schemas/user.schema.ts | Deps: none | Status: ✅ done
TASK 002: Hash password service | File: src/services/auth.service.ts | Deps: 001 | Status: ✅ done
```

### Implementation Plan (full)
- Sections: Goal, Files, Deps, Tests
- Max 25 lines total

**Example:**
```
## Goal
Secure auth system: registration, login, JWT, middleware.

## Files
- src/schemas/user.schema.ts - Zod validation
- src/services/auth.service.ts - Hash + verify
- src/middleware/auth.middleware.ts - Route protection

## Deps
user.schema.ts → auth.service.ts → auth.middleware.ts

## Tests
Unit: 100% coverage. E2E: registration, login, protected routes.
```

### Commit Message (ultra)
- Format: `{type}({scope}): {action} - {reason}`
- Max 72 characters

**Example:**
```
fix(auth): change token check to <= - prevent race condition
```

### Code Review (full)
- Format: `{file}:{line} - {severity_emoji} {finding}`
- Emojis: 🔴 critical, 🟡 warning, 🔵 info

**Example:**
```
middleware/auth.js:42 - 🔴 Token expiry check use `<` not `<=`. Race condition.
services/auth.js:15 - 🟡 Salt rounds = 8. Recommend 10+.
schemas/user.js:5 - 🔵 Consider adding phone validation.
```

## Invariants (Never Compressed)

✅ **Always Preserved:**
- Code blocks (full syntax, no compression)
- Error messages (quoted exactly, no paraphrasing)
- Technical terms (function names, API names, file paths)
- Stack traces (preserved exactly)
- URLs and paths (never shortened)
- Version numbers (never abbreviated)
- Regex patterns (never modified)
- SQL queries (never compressed)
- JSON/YAML structure (preserved)

❌ **Never Compressed:**
```typescript
// ✅ Good: code block intact
const user = await db.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ❌ Bad: code compressed
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

## Auto-Deactivation

Caveman mode automatically deactivates for:
- 🔒 Security warnings
- ⚠️ Irreversible action confirmations
- 📜 Legal notices
- 📄 License texts

## Persistence

Caveman mode stays active for **every response** until:
- `stop caveman`
- `normal mode`
- Security alert
- Irreversible action confirmation

## Anti-Patterns

### Chat
❌ Write more than 8 lines  
❌ Start with politeness ("Sure!", "I'd be happy to help")  
❌ Explain obvious context  
❌ Use hedging words ("just", "really", "basically", "actually")

### Files
❌ Exceed max lines per section  
❌ Add sections not listed in rules  
❌ Include acknowledgments or philosophy sections

### Code
❌ Compress code blocks  
❌ Paraphrase error messages  
❌ Abbreviate technical terms

## Configuration

### Main Config
`Axiom-scaffold/config/caveman-rules.yaml`

Contains:
- Levels (lite, full, ultra, wenyan)
- Output rules (chat, docs, walkthrough, task, plan, commit, review)
- Invariants (code, errors, technical terms)
- Persistence (stop triggers, switch triggers)
- Output structure (reports directory)
- Anti-patterns (forbidden behaviors)

### IDE Mapping
`Axiom-scaffold/config/ide-mapping.yaml`

Maps 24 IDE/CLI tools:
- Context file paths
- Skills directories
- MCP config locations
- Caveman install commands

### Detection Script
`Axiom-scaffold/scripts/detect-ide.sh`

Auto-detects active IDE/CLI:
- Priority: Claude Code > Gemini > Cursor > Windsurf > Cline > generic
- Outputs YAML with tool name + config paths

## Validation

```bash
# Validate config
npm run caveman:validate

# Detect IDE
npm run caveman:detect
```

## Output Structure

All generated files go to:
```
Axiom-scaffold/reports/
├── {feature}/
│   ├── walkthrough.md  (caveman full)
│   ├── tasks.md        (caveman ultra)
│   ├── plan.md         (caveman full)
│   └── reviews.md      (caveman full)
```

## Token Savings

| Type      | Before      | After       | Savings    |
| --------- | ----------- | ----------- | ---------- |
| Chat      | ~150 tokens | ~50 tokens  | 65-70%     |
| Docs      | ~500 tokens | ~250 tokens | 50%        |
| Tasks     | ~200 tokens | ~70 tokens  | 65%        |
| **Total** | -           | -           | **65-75%** |

## IDE Support

24 tools supported:
- **CLI**: Claude Code, Codex, Gemini CLI, Aider, Warp
- **IDE**: Cursor, Windsurf, Cline, Kiro, Zed, Antigravity, Trae, Codeium, Continue, Cody, Roo Code, JetBrains Junie
- **Cloud**: Devin, Replit Agent, Amazon Q Developer
- **Other**: Copilot, Mistral Vibe, Qwen Code, OpenCode

Each has:
- Context file path
- Skills directory
- MCP config location
- Caveman install command

## Examples

### Before Caveman (Normal Mode)
```
I'd be happy to help you with that! The issue you're experiencing is 
actually quite common. Basically, what's happening is that the 
authentication middleware is using the wrong comparison operator. 
I recommend that you change the `<` to `<=` in the token expiry check. 
This should resolve the problem. Let me know if you need any further 
assistance!
```

**Tokens**: ~150

### After Caveman (Full Mode)
```
Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:

// middleware/auth.js:42
- if (token.exp < now) throw new Error('expired');
+ if (token.exp <= now) throw new Error('expired');

Test: npm test auth
```

**Tokens**: ~50  
**Savings**: 65%

### Ultra Mode
```
Auth bug → token check `<` → `<=`
Fix: middleware/auth.js:42
Test: npm test auth
```

**Tokens**: ~25  
**Savings**: 83%

## Best Practices

### When to Use Each Level

**Lite**: 
- Documentation for external users
- Public-facing content
- When clarity > brevity

**Full** (default):
- Internal communication
- Code reviews
- Implementation plans
- Most agent responses

**Ultra**:
- Task lists
- Commit messages
- Quick status updates
- When token budget is critical

**Wenyan**:
- Experimental
- Maximum compression needed
- Chinese-speaking teams

### Combining with Other Tools

Caveman works with:
- GitNexus (graph analysis)
- Graphify (semantic clustering)
- GraphRAG (document extraction)
- Linear (project management)
- MCP servers (context providers)

### Tips

1. **Read config first**: Agent MUST read `caveman-rules.yaml` before any output
2. **Respect invariants**: Never compress code, errors, or technical terms
3. **Use appropriate level**: Match level to audience and context
4. **Validate regularly**: Run `npm run caveman:validate` after config changes
5. **Monitor savings**: Track token usage to verify compression effectiveness

## Troubleshooting

### Config Not Loading
```bash
# Check file exists
ls -la Axiom-scaffold/config/caveman-rules.yaml

# Validate YAML
npm run caveman:validate
```

### Wrong Level Active
```bash
# Check current level
echo "What caveman level active?"

# Switch level
/caveman full
```

### Code Getting Compressed
Check invariants in config. Code blocks should never be compressed. If happening, file a bug.

### IDE Not Detected
```bash
# Run detection
npm run caveman:detect

# Check output
# If "generic", add your IDE to ide-mapping.yaml
```

## References

- **Source**: https://github.com/JuliusBrussee/caveman
- **Licence**: MIT
- **Config**: `Axiom-scaffold/config/caveman-rules.yaml`
- **Skill**: `Axiom-scaffold/skills/built-in/caveman-mode.md`
- **Mapping**: `Axiom-scaffold/config/ide-mapping.yaml`
- **Examples**: `Axiom-scaffold/reports/authentication/`

---

**Quick Start**: `/caveman full`  
**Stop**: `stop caveman`  
**Validate**: `npm run caveman:validate`  
**Savings**: 65-75% tokens
