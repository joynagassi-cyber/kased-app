import type { CommandOptions } from './types'
import process from 'node:process'

export const isTTY = process.stdout.isTTY

export const isCI = Boolean(process.env.CI)

export const DEFAULT_OPTIONS: CommandOptions = {
  source: 'node_modules',
  recursive: false,
  gitignore: true,
  yes: false,
  dryRun: false,
  exclude: [],
  force: false,
  cleanup: true,
}

export const LOGO_LINES = [
  ' █████╗ ██╗  ██╗██╗ ██████╗ ███╗   ███╗    ███████╗ ██████╗ █████╗ ███████╗███████╗ ██████╗ ██╗     ██████╗ ',
  '██╔══██╗╚██╗██╔╝██║██╔═══██╗████╗ ████║    ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝██╔═══██╗██║     ██╔══██╗',
  '███████║ ╚███╔╝ ██║██║   ██║██╔████╔██║    ███████╗██║     ███████║█████╗  █████╗  ██║   ██║██║     ██║  ██║',
  '██╔══██║ ██╔██╗ ██║██║   ██║██║╚██╔╝██║    ╚════██║██║     ██╔══██║██╔══╝  ██╔══╝  ██║   ██║██║     ██║  ██║',
  '██║  ██║██╔╝ ██╗██║╚██████╔╝██║ ╚═╝ ██║    ███████║╚██████╗██║  ██║██║     ██║     ╚██████╔╝███████╗██████╔╝',
  '╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝      ╚═════╝ ╚══════╝╚═════╝ ',
]

export const GRAYS = [
  '\x1B[38;5;39m',  // Bright blue
  '\x1B[38;5;38m',  // Blue
  '\x1B[38;5;32m',  // Cyan-blue
  '\x1B[38;5;36m',  // Cyan
  '\x1B[38;5;35m',  // Green-cyan
  '\x1B[38;5;29m',  // Green
]
export const RESET = '\x1B[0m'

export const GITIGNORE_PATTERN = '**/Axiom-scaffold/skills/npm-*'
export const LEGACY_GITIGNORE_PATTERN = 'Axiom-scaffold/skills/npm-*'
export const GITIGNORE_COMMENT = '# Axiom skills from npm packages (managed by axiom-scaffold-installer)'

/**
 * Lock files for different package managers.
 * Order matters: first match wins. Binary files (bun.lockb) are handled separately.
 */
export const LOCK_FILES = {
  /** Binary lock files that need Buffer reading */
  binary: ['bun.lockb'] as const,
  /** Text lock files that can be read as UTF-8 */
  text: ['pnpm-lock.yaml', 'yarn.lock', 'package-lock.json'] as const,
  /** All lock files in priority order (binary first for faster hashing) */
  all: ['bun.lockb', 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json'] as const,
}
