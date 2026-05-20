# Axiom Installer — Quick Start

> **Interactive installer for Axiom-Scaffold**  
> **Location**: `Axiom-scaffold/installers/axiom-installer/`  
> **Status**: ✅ Customized, Ready for Build

## What Is It?

Interactive CLI that installs Axiom skills to AI coding tools (Claude Code, Cursor, Windsurf, Kiro, etc.).

## Installation

### Global

```bash
npm install -g axiom-scaffold-installer
axiom-scaffold
```

### Via npx

```bash
npx axiom-scaffold-installer
```

### Local Development

```bash
cd Axiom-scaffold/installers/axiom-installer
pnpm install
pnpm build
node dist/cli.mjs
```

## Usage

### Interactive

```bash
axiom-scaffold
```

Shows:
1. Axiom ASCII logo (blue-green gradient)
2. Scans for Axiom skills
3. Detects AI tools
4. Interactive selection
5. Installs skills
6. Cleans up stale skills
7. Updates .gitignore

### Non-Interactive

```bash
# Specific tools
axiom-scaffold --agents claude-code,cursor,windsurf

# Skip confirmation
axiom-scaffold --yes

# Dry run
axiom-scaffold --dry-run

# Force reload
axiom-scaffold --force
```

## Customizations

### Logo

```
 █████╗ ██╗  ██╗██╗ ██████╗ ███╗   ███╗    ███████╗ ██████╗ █████╗ ███████╗███████╗ ██████╗ ██╗     ██████╗ 
██╔══██╗╚██╗██╔╝██║██╔═══██╗████╗ ████║    ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝██╔═══██╗██║     ██╔══██╗
███████║ ╚███╔╝ ██║██║   ██║██╔████╔██║    ███████╗██║     ███████║█████╗  █████╗  ██║   ██║██║     ██║  ██║
██╔══██║ ██╔██╗ ██║██║   ██║██║╚██╔╝██║    ╚════██║██║     ██╔══██║██╔══╝  ██╔══╝  ██║   ██║██║     ██║  ██║
██║  ██║██╔╝ ██╗██║╚██████╔╝██║ ╚═╝ ██║    ███████║╚██████╗██║  ██║██║     ██║     ╚██████╔╝███████╗██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝      ╚═════╝ ╚══════╝╚═════╝ 
```

Colors: Blue (#39) → Cyan (#32) → Green (#29)

### Messages

- Intro: "Axiom-Scaffold Interactive Installer"
- Scan: "🔍 Scanning for Axiom skills..."
- Discovered: "📦 Discovered Axiom skills:"
- Confirm: "🏗️  Install X Axiom skills to Y agents?"
- Select: "🎯 Select AI coding tools to install Axiom skills:"

### Package

- Name: `axiom-scaffold-installer`
- Bins: `axiom-scaffold`, `axiom-install`
- Description: "Interactive installer for Axiom-Scaffold"
- Keywords: axiom, scaffold, skills, ai, cli, installer
- Author: Axiom-Scaffold Team

## Files Modified

| File               | Changes                                                    |
| ------------------ | ---------------------------------------------------------- |
| `package.json`     | Name, bins, description, keywords, author, repository      |
| `src/constants.ts` | Logo (Axiom ASCII), colors (blue-green), gitignore pattern |
| `src/cli.ts`       | Messages (scan, discovered, confirm, select, intro, outro) |
| `README.md`        | New file with full documentation                           |

## Supported Tools

- Claude Code (CLI)
- Cursor (IDE)
- Windsurf (IDE)
- Cline (VS Code)
- Kiro (Amazon)
- Copilot (GitHub)
- Zed (IDE)
- Continue (VS Code)
- Cody (Sourcegraph)
- Roo Code (VS Code)
- 14+ more...

## Axiom Skills

- **axiom-bootstrap**: Initialize Axiom
- **axiom-memory**: Update universal memory
- **axiom-visualize**: Generate interactive graph
- **axiom-linear**: Sync with Linear
- **axiom-research**: Auto-research technologies
- **caveman-mode**: Token compression (65-75%)

## Next Steps

### 1. Build

```bash
cd Axiom-scaffold/installers/axiom-installer
pnpm install
pnpm build
```

### 2. Test

```bash
node dist/cli.mjs
```

### 3. Publish

```bash
npm login
npm publish
```

### 4. Use

```bash
npx axiom-scaffold-installer
```

## Configuration

Create `.axiom-installer.config.js`:

```javascript
export default {
  agents: ['claude-code', 'cursor', 'windsurf'],
  include: ['axiom-*'],
  exclude: ['axiom-experimental'],
  yes: false,
  dryRun: false,
  force: false,
  cleanup: true,
  gitignore: true,
}
```

## CLI Options

```
--cwd <cwd>              Current working directory
--agents, -a <agents>    Comma-separated list of agents
--source, -s <source>    Source to discover skills (default: "package.json")
--recursive, -r          Scan recursively for monorepo
--gitignore              Skip updating .gitignore (default: true)
--yes                    Skip confirmation prompts
--dry-run                Show what would be done
--force                  Force full reload, ignore cache
--cleanup                Clean up stale skills (default: true)
-h, --help               Display help
-v, --version            Display version
```

## Workflow

```
1. Scan node_modules
   ↓
2. Detect AI tools
   ↓
3. Interactive selection (or --agents)
   ↓
4. Confirm (or --yes)
   ↓
5. Create symlinks
   ↓
6. Cleanup stale skills
   ↓
7. Update .gitignore
   ↓
8. Done!
```

## Architecture

```
axiom-installer/
├── src/
│   ├── cli.ts          # Main CLI (customized)
│   ├── constants.ts    # Logo, colors (customized)
│   ├── printer.ts      # TUI printing
│   ├── agents.ts       # Agent detection
│   ├── scan.ts         # Skill scanning
│   ├── symlink.ts      # Symlink management
│   ├── config.ts       # Config resolution
│   ├── gitignore.ts    # Gitignore management
│   └── types.ts        # TypeScript types
├── test/               # Tests
├── vendor/             # Vendored skills
├── package.json        # Customized
├── README.md           # New
└── tsconfig.json
```

## Credits

Based on [antfu/skills-npm](https://github.com/antfu/skills-npm) by Anthony Fu.

## Status

✅ Cloned from antfu/skills-npm  
✅ Package.json customized  
✅ Logo customized (Axiom ASCII)  
✅ Colors customized (blue-green)  
✅ Messages customized  
✅ README created  
⏳ Build pending  
⏳ Test pending  
⏳ Publish pending

## References

- **Base**: https://github.com/antfu/skills-npm
- **Location**: `Axiom-scaffold/installers/axiom-installer/`
- **Package**: `axiom-scaffold-installer`
- **Bins**: `axiom-scaffold`, `axiom-install`
- **Report**: `Axiom-scaffold/reports/AXIOM_INSTALLER_COMPLETE.md`

---

**Status**: ✅ Customized  
**Next**: Build & Test  
**Ready**: For local development
