# Axiom-Scaffold Installer

> **Interactive installer for Axiom-Scaffold** — Add agentic skills to your favorite AI coding tools

## What Is This?

Axiom-Scaffold Installer is an interactive CLI that installs Axiom skills to your AI coding tools (Claude Code, Cursor, Windsurf, Kiro, etc.).

## Features

- 🎯 **Auto-detection**: Automatically detects installed AI coding tools
- 🏗️ **Interactive**: Beautiful TUI for selecting tools and skills
- 📦 **Smart**: Scans npm packages for Axiom skills
- 🔄 **Sync**: Keeps skills up-to-date across all tools
- 🧹 **Cleanup**: Removes stale skills automatically
- 🎨 **Branded**: Custom Axiom branding and colors

## Installation

### Global (Recommended)

```bash
npm install -g axiom-scaffold-installer
```

### Via npx (No Install)

```bash
npx axiom-scaffold-installer
```

### Local Development

```bash
git clone https://github.com/axiom-scaffold/axiom-installer.git
cd axiom-installer
pnpm install
pnpm build
node dist/cli.mjs
```

## Usage

### Interactive Mode

```bash
axiom-scaffold
```

or

```bash
axiom-install
```

This will:
1. Show the Axiom logo
2. Scan for Axiom skills in your project
3. Detect installed AI coding tools
4. Let you select which tools to install to
5. Create symlinks for all skills
6. Clean up stale skills
7. Update .gitignore

### Non-Interactive Mode

```bash
# Install to specific agents
axiom-scaffold --agents claude-code,cursor,windsurf

# Skip confirmation
axiom-scaffold --yes

# Dry run (show what would be done)
axiom-scaffold --dry-run

# Force reload (ignore cache)
axiom-scaffold --force

# Skip cleanup
axiom-scaffold --no-cleanup

# Skip gitignore update
axiom-scaffold --no-gitignore
```

## Supported AI Coding Tools

- **Claude Code** (CLI)
- **Cursor** (IDE)
- **Windsurf** (IDE)
- **Cline** (VS Code extension)
- **Kiro** (Amazon IDE)
- **Copilot** (GitHub)
- **Zed** (IDE)
- **Continue** (VS Code extension)
- **Cody** (Sourcegraph)
- **Roo Code** (VS Code extension)
- And many more...

## Axiom Skills

The installer discovers and installs these Axiom skills:

- **axiom-bootstrap**: Initialize Axiom on a project
- **axiom-memory**: Update universal memory (graph fusion)
- **axiom-visualize**: Generate interactive graph visualization
- **axiom-linear**: Sync with Linear project management
- **axiom-research**: Auto-research best technologies and MCPs
- **caveman-mode**: Activate token compression (65-75% savings)

## How It Works

1. **Scan**: Scans `node_modules` for packages with Axiom skills
2. **Detect**: Detects installed AI coding tools on your system
3. **Select**: Interactive selection of tools to install to
4. **Symlink**: Creates symlinks from skills to tool directories
5. **Cleanup**: Removes stale skills no longer in packages
6. **Gitignore**: Updates .gitignore to exclude npm-managed skills

## Configuration

Create `.axiom-installer.config.js` in your project root:

```javascript
export default {
  // Agents to install to (overrides detection)
  agents: ['claude-code', 'cursor', 'windsurf'],
  
  // Include only specific skills
  include: ['axiom-*'],
  
  // Exclude specific skills
  exclude: ['axiom-experimental'],
  
  // Skip confirmation prompts
  yes: false,
  
  // Dry run mode
  dryRun: false,
  
  // Force reload (ignore cache)
  force: false,
  
  // Clean up stale skills
  cleanup: true,
  
  // Update .gitignore
  gitignore: true,
}
```

## CLI Options

```
Options:
  --cwd <cwd>              Current working directory
  --agents, -a <agents>    Comma-separated list of agents to install to
  --source, -s <source>    Source used to discover skills (default: "package.json")
  --recursive, -r          Scan recursively for monorepo packages
  --gitignore              Skip updating .gitignore (default: true)
  --yes                    Skip confirmation prompts
  --dry-run                Show what would be done without making changes
  --force                  Force full reload, ignore cache
  --cleanup                Clean up stale npm-* skills from agent directories (default: true)
  -h, --help               Display this message
  -v, --version            Display version number
```

## Examples

### Install to all detected tools

```bash
axiom-scaffold
```

### Install to specific tools

```bash
axiom-scaffold --agents claude-code,cursor
```

### Dry run to see what would happen

```bash
axiom-scaffold --dry-run
```

### Force reload and skip confirmation

```bash
axiom-scaffold --force --yes
```

### Install in monorepo

```bash
axiom-scaffold --recursive
```

## Development

### Setup

```bash
git clone https://github.com/axiom-scaffold/axiom-installer.git
cd axiom-installer
pnpm install
```

### Build

```bash
pnpm build
```

### Test

```bash
pnpm test
```

### Run Locally

```bash
pnpm start
```

or

```bash
tsx src/cli.ts
```

## Architecture

```
axiom-installer/
├── src/
│   ├── cli.ts          # Main CLI entry point
│   ├── agents.ts       # Agent detection and configuration
│   ├── scan.ts         # Skill scanning logic
│   ├── symlink.ts      # Symlink creation and cleanup
│   ├── printer.ts      # TUI printing and formatting
│   ├── constants.ts    # Logo, colors, defaults
│   ├── config.ts       # Configuration resolution
│   ├── gitignore.ts    # Gitignore management
│   └── types.ts        # TypeScript types
├── test/               # Test files
├── vendor/             # Vendored skills (git submodule)
├── package.json
├── tsconfig.json
└── README.md
```

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## License

MIT © Axiom-Scaffold Team

## Credits

Based on [antfu/skills-npm](https://github.com/antfu/skills-npm) by Anthony Fu.

## Links

- **Homepage**: https://github.com/axiom-scaffold/axiom-installer
- **Issues**: https://github.com/axiom-scaffold/axiom-installer/issues
- **Axiom-Scaffold**: https://github.com/axiom-scaffold/axiom-scaffold
- **Documentation**: https://axiom-scaffold.dev

---

**Made with ❤️ by the Axiom-Scaffold Team**
