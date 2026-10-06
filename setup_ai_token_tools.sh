#!/usr/bin/env bash

# AI Token-Reduction Tools Setup
# Installs user-level (~/) tooling that cuts Claude Code / GitHub Copilot token use:
#   graphify  - codebase knowledge graph the agent queries instead of reading files
#   ponytail  - "reuse before you write" ruleset (default level: lite)
#   links     - ~/.claude/CLAUDE.md and ~/.github / ~/.copilot instructions symlinks
# Copilot Chat in VS Code reads ~/.copilot/instructions, which "links" fills from
# global_env/copilot/*.instructions.md plus the work overlay's copilot/ folder if present.
# It also links the overlay's claude/skills/* into ~/.claude/skills and ~/.copilot/skills.
#
# Usage:
#   setup_ai_token_tools.sh [-o graphify|ponytail|links] [-u] [-y]
#
# Safe to re-run: every step skips what is already in place.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.sh
source "$SCRIPT_DIR/paths.sh"
# shellcheck source=setup_lib.sh
source "$SCRIPT_DIR/setup_lib.sh"

PONYTAIL_REPO="DietrichGebert/ponytail"
PONYTAIL_PLUGIN="ponytail@ponytail"
PONYTAIL_CONFIG="$HOME/.config/ponytail/config.json"
GRAPHIFY_PACKAGE="graphifyy==0.9.76"   # bump deliberately, then re-run -o graphify

usage() {
  cat <<EOF
Usage: $0 [-o graphify|ponytail|links] [-u] [-y]
  -o   Only set up one tool (default: all)
  -u   Uninstall instead of install
  -y   Don't prompt
  -h   Show this help
EOF
}

ONLY=""
UNINSTALL=false

if [[ $# -gt 0 ]] && _want_help "$1"; then
  usage
  exit 0
fi

while getopts ":o:uyh" opt; do
  case "$opt" in
    o) ONLY="$OPTARG" ;;
    u) UNINSTALL=true ;;
    y) export ASSUME_YES=1 ;;
    h) usage; exit 0 ;;
    :) die "Option -$OPTARG needs a value" ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$ONLY" in
  ""|graphify|ponytail|links) ;;
  *) die "Unknown tool for -o: $ONLY (expected graphify, ponytail or links)" ;;
esac

# True when this run should handle $1
_selected() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

_have() { command -v "$1" >/dev/null 2>&1; }

# Point $2 at $1, backing up a real file that is in the way.
_link() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [[ -L "$link" && "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
    info "$link already links to $target"
    return 0
  fi
  if [[ -d "$link" && ! -L "$link" ]]; then
    warn "$link is a real directory; move its contents into $target and re-run"
    return 0
  fi
  if [[ -e "$link" && ! -L "$link" ]]; then
    backup_file "$link"
  fi
  ln -sfn "$target" "$link"
  log_ok "Linked $link -> $target"
}

# Remove $1 only if it is a symlink into global_env or the work overlay (dangling ones too).
_unlink() {
  local link="$1" dest
  [[ -L "$link" ]] || return 0
  dest="$(readlink -m "$link")"
  if [[ "$dest" == "$GLOBAL_ENV_DIR"/* || "$dest" == "$GLOBAL_ENV_OVERLAY_DIR"/* ]]; then
    rm -f "$link"
    log_ok "Removed $link"
  fi
}

# Fill ~/.copilot/instructions with one link per *.instructions.md from global_env/copilot
# and, on work machines, $GLOBAL_ENV_OVERLAY_DIR/copilot (linked second, so it wins on a
# name clash). Links to files that no longer exist are pruned.
_link_instructions() {
  local dir="$HOME/.copilot/instructions" src f
  # Older runs linked the whole folder to global_env/copilot; replace that with a real dir
  _unlink "$dir"
  mkdir -p "$dir"
  for f in "$dir"/*.instructions.md; do
    [[ -L "$f" && ! -e "$f" ]] && _unlink "$f"
  done
  for src in "$GLOBAL_ENV_DIR/copilot" "$GLOBAL_ENV_OVERLAY_DIR/copilot"; do
    [[ -d "$src" ]] || continue
    for f in "$src"/*.instructions.md; do
      [[ -f "$f" ]] && _link "$f" "$dir/$(basename "$f")"
    done
  done
  return 0
}

# Link each skill folder in $GLOBAL_ENV_OVERLAY_DIR/claude/skills into ~/.claude/skills
# and ~/.copilot/skills (Copilot CLI and VS Code Copilot Chat read the latter).
_link_skills() {
  local src="$GLOBAL_ENV_OVERLAY_DIR/claude/skills" d dir
  [[ -d "$src" ]] || return 0
  for d in "$src"/*/; do
    [[ -f "$d/SKILL.md" ]] || continue
    for dir in "$HOME/.claude/skills" "$HOME/.copilot/skills"; do
      _link "${d%/}" "$dir/$(basename "$d")"
    done
  done
  return 0
}

setup_links() {
  section "Global instruction links"
  _link "$GLOBAL_ENV_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  _link "$GLOBAL_ENV_DIR/global-copilot-instructions.md" "$HOME/.github/copilot-instructions.md"
  # Copilot (VS Code agent host and CLI) reads user instructions from ~/.copilot;
  # chat.instructionsFilesLocations is deprecated and only used by the VS Code Local agent
  _link "$GLOBAL_ENV_DIR/global-copilot-instructions.md" "$HOME/.copilot/copilot-instructions.md"
  _link_instructions
  _link_skills
}

remove_links() {
  section "Global instruction links"
  _unlink "$HOME/.claude/CLAUDE.md"
  _unlink "$HOME/.github/copilot-instructions.md"
  _unlink "$HOME/.copilot/copilot-instructions.md"
  local f
  for f in "$HOME/.copilot/instructions"/*.instructions.md; do
    _unlink "$f"
  done
  rmdir "$HOME/.copilot/instructions" 2>/dev/null || true
  for f in "$HOME/.claude/skills"/* "$HOME/.copilot/skills"/*; do
    _unlink "$f"
  done
}

setup_graphify() {
  section "Graphify"
  _have uv || die "uv is required to install graphify (run environment_setup.sh first)"
  if _have graphify; then
    info "graphify already installed: $(graphify --version 2>/dev/null || echo unknown)"
  else
    uv tool install "$GRAPHIFY_PACKAGE"
  fi
  # Global /graphify skill only. Per-repo hooks (graphify claude install / hook install)
  # are opt-in for large repos, see README.
  graphify install
  # ~/.copilot/skills is read by both Copilot CLI and VS Code Copilot Chat, so install
  # it even when the CLI is absent.
  graphify copilot install
  log_ok "Graphify ready: run /graphify . inside a repo to build its graph"
  warn "Graphify sends docs, PDFs and images (not code) to Claude for extraction"
}

remove_graphify() {
  section "Graphify"
  if _have graphify; then
    uv tool uninstall "$GRAPHIFY_PACKAGE"
  fi
  rm -rf "$HOME/.claude/skills/graphify" "$HOME/.copilot/skills/graphify"
  log_ok "Graphify removed"
}

# Install the ponytail plugin into one agent CLI (claude or copilot).
_install_ponytail_plugin() {
  local cli="$1"
  if ! "$cli" plugin marketplace list 2>/dev/null | grep -q "ponytail"; then
    "$cli" plugin marketplace add "$PONYTAIL_REPO"
  fi
  if "$cli" plugin list 2>/dev/null | grep -q "ponytail"; then
    info "$cli: ponytail already installed"
  else
    "$cli" plugin install "$PONYTAIL_PLUGIN"
  fi
}

setup_ponytail() {
  section "Ponytail"
  _have claude || die "claude CLI is required to install the ponytail plugin"
  _install_ponytail_plugin claude
  if _have copilot; then
    _install_ponytail_plugin copilot
  else
    warn "Copilot CLI not found; skipping ponytail Copilot CLI plugin"
  fi
  if [[ -f "$PONYTAIL_CONFIG" ]]; then
    info "$PONYTAIL_CONFIG exists; leaving it alone"
  else
    mkdir -p "$(dirname "$PONYTAIL_CONFIG")"
    printf '{\n  "defaultMode": "%s"\n}\n' "${PONYTAIL_DEFAULT_MODE:-lite}" > "$PONYTAIL_CONFIG"
    log_ok "Wrote $PONYTAIL_CONFIG (defaultMode: ${PONYTAIL_DEFAULT_MODE:-lite})"
  fi
}

remove_ponytail() {
  section "Ponytail"
  local cli
  for cli in claude copilot; do
    _have "$cli" || continue
    "$cli" plugin uninstall "$PONYTAIL_PLUGIN" || true
    "$cli" plugin marketplace remove ponytail || true
  done
  rm -f "$PONYTAIL_CONFIG"
  log_ok "Ponytail removed"
}

main() {
  if [[ "$UNINSTALL" == true ]]; then
    confirm "Uninstall ${ONLY:-all AI token tools}?" || die "Aborted"
    _selected ponytail && remove_ponytail
    _selected graphify && remove_graphify
    _selected links && remove_links
  else
    _selected links && setup_links
    _selected ponytail && setup_ponytail
    _selected graphify && setup_graphify
  fi
  info "Done. Start a new Claude Code session to load plugin and skill changes."
  return 0
}

main
