---
trigger: glob
globs: ALWAYS read this file before any action. It contains mandatory rules for all agents. No exceptions.
---

# AGENTS.md — Axiom-Scaffold Agent Rules

**RULES FOR ALL AI AGENTS (Claude Code, Cursor, Windsurf, Codex, etc.)**

## Confinement
- Write ALL files inside `Axiom-scaffold/`.
- NEVER create files at project root (except `src/`, `tests/`).

## Templates
- Use `Axiom-scaffold/templates/` for every artifact.
  - Plan: `plan-template.md`
  - Task: `task-template.md`
  - Walkthrough: `walkthrough-template.md`

## Mode (Focus/Flex)
Defined in `axiom.config.yaml`:
- **Flex** (default): Ask approval before critical actions.
- **Focus**: Full autonomy.

**Auto-approve always**: lint, test, format, build, validate.
**Approval required always**: constitution edit, public API change, DB delete, infra change, Linear project creation.

## Constitution
Before coding, read:
- `specs/rules/constitution.md`
- `specs/domain/`
- `specs/architecture/decisions/`

## Large Projects (>100k lines)
1. Run `scripts/quick-scan.sh` → section map.
2. Ask human which section.
3. Load only that subgraph.

## Caveman Mode (mandatory)
Read `config/caveman-rules.yaml` before any output.
- Default: full caveman (≤6 lines, [constat][cause][action]).
- Commands: `/caveman lite|full|ultra`, `stop caveman`.
- Saves 65–75% tokens.

## Navigation
- Architecture: `docs/ARCHITECTURE.md`
- Memory: `docs/MEMORY.md`
- Determinism: `docs/DETERMINISM.md`
- Specs & Skills: `docs/SPECS-AND-SKILLS.md`
- Context minimizer: `docs/CONTEXT-MINIMIZER.md`
- Design UI: `docs/DESIGN.md`
- Zero-Trust Exec: `docs/EXECUTION-ZERO-TRUST.md`
- Visualization: `docs/VISUALIZATION.md`
- Learning: `docs/LEARNING.md`
- Security: `docs/SECURITY.md`
- Style Guide: `docs/STYLE_GUIDE.md`

## Axiom Workflow
1. **Bootstrap** (once): `npm run bootstrap`
   - Installs GitNexus, GraphRAG, Playwright.
   - Scans project, builds section map.
2. **Research**: Analyze section → `tools/tech-stack.md`, `tools/mcp-registry.yaml`.
3. **Cycle**:
   - Context → Specs → Plan → Linear tickets → Design → Implementation (≤100 lines/task) → Tests → Validation → Git (auto) → Learning.

## Skills
Activate via triggers or natural language:
- `/axiom-bootstrap` → `bootstrap.sh`
- `/axiom-scan` → `quick-scan.sh`
- `/axiom-memory` → `index-memory.sh`
- `/axiom-visualize` → `build-visualizer.sh`
- `/axiom-research` → `stack-research.sh`
- `/axiom-linear` → `linear-sync.sh`
- `/axiom-focus` → `focus-mode.sh`
- `/axiom-flex` → `focus-mode.sh --flex`
- `/axiom-plan` → template
- `/axiom-task` → template
- `/axiom-walkthrough` → template

Full registry: `skills/registry.json`.

External skills (auto-loaded by task keywords):
- Design: `web-design`, `design-system`, `huashu-review`
- Security: `cybersecurity`, `prodsec`, `hack-skills`
- Architecture: `sysdesign`, `agentic-patterns`
- Code: `claude-code-skills`, `code-toolkit`
- General: `garden-skills`, `ok-skills`, `debugging`

Import external: `./scripts/import-skills.sh <url>`.
Create custom: add `skills/custom/<name>.md` + registry entry.

## Commands
- **Setup**: `script/bootstrap.sh`, `script/setup.sh`
- **Tests**: `npm test`, `npm run test:mutation`, `npm run test:e2e`
- **Lint**: `npm run lint`, `npm run lint:fix`
- **Security**: `./scripts/security-scan.sh`, `npm audit`
- **Memory**: `./scripts/index-memory.sh`
- **Visualize**: `./scripts/build-visualizer.sh`
- **Experiment**: `script/start-experiment.sh <name>`
- **Specs validate**: `npm run validate:specs`
- **Design pipeline**: `./scripts/design-pipeline.sh --framework <X> --style <Y> --screen <Z>`
- **Execute task**: `./scripts/execute-task.sh <task.yaml>`
- **Learn**: `./scripts/learn.sh learning/events`

## Quality Gates
- Test coverage ≥ 80%
- Mutation score ≥ 70%
- Cyclomatic complexity ≤ 10 per function
- File size ≤ 300 lines (exceptions must be documented)

## Security
- Never commit secrets.
- Validate all inputs.
- Principle of least privilege.
- Regular dependency audit.
- Zero-Trust: always verify.

Policies: `security/policies/owasp-top10-web.md`, `owasp-api-security.md`, `owasp-top10-mobile.md`, `owasp-agentic-top10.md`, `masvs-android.md`, `windows-hardening.md`.

Tools: Semgrep, npm audit, detect-secrets, Strix, Pathfinder-AI, MCP Shield, Agent Governance.

Security skills: `api-security`, `web-security` (soon), `mobile-security` (soon), `cloud-security` (soon), `agent-security` (soon).

## Documentation
- Code: JSDoc/docstrings.
- Architecture: diagrams in `docs/`.
- API: OpenAPI in `specs/technical/api-contracts/`.
- Decisions: ADR in `specs/architecture/decisions/`.
- Rules: constitution in `specs/rules/`.
- Domain: glossary in `specs/domain/`.

Use Markdown, code examples, Mermaid diagrams, maintain CHANGELOG.

## Troubleshooting
1. Check `logs/`.
2. Check `on-error.sh` output.
3. Consult docs.
4. Query GitNexus graph.

**Version**: 1.0.0 | **Last update**: 2026-05-09 | **Maintainer**: Axiom-Scaffold Team