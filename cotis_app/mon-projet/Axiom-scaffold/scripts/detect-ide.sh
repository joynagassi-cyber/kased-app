#!/usr/bin/env bash
# Axiom-scaffold/scripts/detect-ide.sh
# Détecte l'IDE/CLI actif en vérifiant les fichiers de configuration

set -euo pipefail

# Priorité de détection
detect_ide() {
  # Claude Code
  if [[ -f "CLAUDE.md" ]] || [[ -d "$HOME/.claude" ]]; then
    echo "tool: claude_code"
    echo "context_file: CLAUDE.md"
    echo "skills_dir: .claude/skills/"
    echo "mcp_config: ~/.claude/mcp/"
    return 0
  fi
  
  # Gemini CLI
  if [[ -f "GEMINI.md" ]] || [[ -d "$HOME/.gemini" ]]; then
    echo "tool: gemini"
    echo "context_file: GEMINI.md"
    echo "settings: ~/.gemini/settings.json"
    return 0
  fi
  
  # Cursor
  if [[ -d ".cursor" ]]; then
    echo "tool: cursor"
    echo "context_file: .cursor/rules/axiom.mdc"
    echo "rules_dir: .cursor/rules/"
    echo "mcp_config: .cursor/mcp.json"
    return 0
  fi
  
  # Windsurf
  if [[ -f ".windsurfrules" ]] || [[ -d ".windsurf" ]]; then
    echo "tool: windsurf"
    echo "context_file: .windsurfrules"
    echo "rules_dir: .windsurf/rules/"
    return 0
  fi
  
  # Cline
  if [[ -d ".clinerules" ]]; then
    echo "tool: cline"
    echo "context_file: .clinerules/axiom.md"
    return 0
  fi
  
  # Copilot
  if [[ -f ".github/copilot-instructions.md" ]]; then
    echo "tool: copilot"
    echo "context_file: .github/copilot-instructions.md"
    return 0
  fi
  
  # Kiro
  if [[ -d ".kiro" ]]; then
    echo "tool: kiro"
    echo "context_file: .kiro/AGENTS.md"
    echo "config_dir: .kiro/"
    return 0
  fi
  
  # Codex
  if [[ -f "$HOME/.codex/config.toml" ]]; then
    echo "tool: codex"
    echo "context_file: AGENTS.md"
    echo "config: ~/.codex/config.toml"
    return 0
  fi
  
  # Fallback: AGENTS.md générique
  echo "tool: generic"
  echo "context_file: AGENTS.md"
  return 0
}

detect_ide
